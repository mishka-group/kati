defmodule Kati.Sync.ICalendar do
  @moduledoc """
  A **patcher**, not a parser-and-regenerator.

  RFC 5545 §3.8.8.1 says compliant applications *"can ignore"* IANA-registered
  properties they do not model, and §3.8.8.2 says the same for `X-` properties.
  That is permission not to *understand* them. It is not permission to destroy
  them, and destroying them is exactly what a parse-into-columns-then-serialise
  pipeline does. The properties this costs are not hypothetical:
  `X-APPLE-STRUCTURED-LOCATION` is the geofence behind Apple's travel-time
  alerts, `X-MOZ-LASTACK` is Thunderbird's snooze state,
  `X-MICROSOFT-CDO-BUSYSTATUS` is how Outlook decides whether you look busy.
  Drop them on write-back and Kati has silently broken another app the user
  relies on.

  So this module never rebuilds a document. Every content line is kept as the
  **original bytes**, the sender's folding and line endings included, and only
  the lines Kati was asked to change are replaced. A property nobody touched
  comes out the far side byte-identical — which the tests assert rather than
  this doc claiming it.

  ## What a "property" is here

  The unit of comparison and replacement is the whole **unfolded content
  line** — `SUMMARY;LANGUAGE=en:Team sync`, not `Team sync`. Parameters are
  part of what changed if they changed, and a merge comparing values only
  would silently drop an `ALTREP` or a `LANGUAGE` the other side added.

  ## Components

  Patching is confined to the direct children of the first `VEVENT`. A
  `VALARM` nested inside it has its own `SUMMARY` and `DESCRIPTION`, and a
  whole-document replace would rewrite the alarm's text with the event's
  title. `VTIMEZONE` is likewise never touched: servers normalise it
  server-side and Kati has no business rewriting it.
  """

  @typedoc """
  Property name to its content lines, unfolded, in document order.

  A list because `EXDATE`, `RDATE`, `ATTENDEE` and `ATTACH` legitimately repeat.
  """
  @type properties :: %{String.t() => [String.t()]}

  @typep line :: %{raw: String.t(), text: String.t(), eol: String.t(), name: String.t() | nil}

  # RFC 5545 §3.3.11 TEXT-valued properties Kati actually writes. Everything
  # else passes through verbatim, because escaping a DATE-TIME or a URI is
  # corruption, not safety.
  @text_properties ~w(SUMMARY DESCRIPTION LOCATION COMMENT CONTACT)

  @fold_limit 75

  # ── Reading ────────────────────────────────────────────────────────────────

  @doc """
  The direct properties of the first `VEVENT`, unfolded, keyed by name.

  `{:error, :no_vevent}` for a document with no event in it — a real thing a
  server sends (a `VCALENDAR` holding only `VTIMEZONE`) and not the same as an
  empty event.
  """
  @spec properties(String.t()) :: {:ok, properties()} | {:error, :no_vevent}
  def properties(raw) when is_binary(raw) do
    with {:ok, lines, span} <- vevent(raw) do
      props =
        lines
        |> children(span)
        |> Enum.reduce(%{}, fn {_index, line}, acc ->
          Map.update(acc, line.name, [line.text], &(&1 ++ [line.text]))
        end)

      {:ok, props}
    end
  end

  @doc """
  The value half of a content line — everything after the first colon that is
  not inside a quoted parameter.

  `ATTENDEE;CN="Smith, J:r":mailto:j@example.com` is why the quoting matters.
  """
  @spec line_value(String.t()) :: String.t()
  def line_value(line) when is_binary(line) do
    case split_on_colon(line, false, "") do
      {_head, value} -> value
      :none -> ""
    end
  end

  @doc "The first content line for `name`, or `nil`."
  @spec property(properties(), String.t()) :: String.t() | nil
  def property(props, name) do
    case Map.get(props, name) do
      [first | _] -> first
      _ -> nil
    end
  end

  # ── Writing ────────────────────────────────────────────────────────────────

  @doc """
  Replace, add or remove properties of the first `VEVENT`.

  `changes` maps a property name to the content lines it should have — a
  binary or a list of binaries — or to `nil`, which removes it. Anything not
  named keeps the exact bytes it arrived as.

  Replacements keep the position of the line they replace, so a document does
  not reshuffle itself on every push. Additions go immediately before
  `END:VEVENT`, folded at 75 octets on grapheme boundaries.
  """
  @spec apply_lines(String.t(), %{String.t() => String.t() | [String.t()] | nil}) ::
          {:ok, String.t()} | {:error, :no_vevent}
  def apply_lines(raw, changes) when is_binary(raw) and is_map(changes) do
    with {:ok, lines, span} <- vevent(raw) do
      {:ok, render(lines, span, normalise(changes), eol_of(lines))}
    end
  end

  @doc """
  Apply a projection patch: `%{"SUMMARY" => "New title", "LOCATION" => nil}`.

  This is the write path the outbox uses. It carries **only the properties
  Kati actually changed** — never a regenerated document — which is what lets
  a title edit survive contact with a `VEVENT` full of vendor extensions.
  """
  @spec patch(String.t(), %{String.t() => String.t() | nil}) ::
          {:ok, String.t()} | {:error, :no_vevent}
  def patch(raw, values) when is_map(values) do
    apply_lines(raw, Map.new(values, fn {name, value} -> {name, content_line(name, value)} end))
  end

  @doc "Set one property from a plain value, escaping it if the property is TEXT."
  @spec put(String.t(), String.t(), String.t() | nil) :: {:ok, String.t()} | {:error, :no_vevent}
  def put(raw, name, value), do: patch(raw, %{name => value})

  @doc """
  Build one content line from a bare value.

  Escapes only where RFC 5545 §3.3.11 says the value type is TEXT — escaping a
  DATE-TIME or a URI is corruption, not safety. `nil` in, `nil` out, which is
  how a removal travels through `Kati.Sync.Compose` unchanged.
  """
  @spec content_line(String.t(), String.t() | nil) :: String.t() | nil
  def content_line(_name, nil), do: nil

  def content_line(name, value) when is_binary(value) do
    if name in @text_properties do
      name <> ":" <> escape_text(value)
    else
      name <> ":" <> value
    end
  end

  @doc """
  Increment `SEQUENCE`.

  RFC 5545 requires it to move on any change to a **scheduled** event, and
  attendees' clients use it to decide whether an update supersedes what they
  already hold. An absent `SEQUENCE` means 0, so the first bump writes 1.
  """
  @spec bump_sequence(String.t()) :: {:ok, String.t()} | {:error, :no_vevent}
  def bump_sequence(raw) do
    with {:ok, props} <- properties(raw) do
      current =
        case property(props, "SEQUENCE") do
          nil -> 0
          line -> line |> line_value() |> String.trim() |> to_integer(0)
        end

      apply_lines(raw, %{"SEQUENCE" => "SEQUENCE:#{current + 1}"})
    end
  end

  @doc """
  A minimal `VEVENT` document.

  Only for the case where Kati is the author and there are no server bytes to
  preserve yet — an `origin: :kati` event on its very first push. From the
  second push onwards the base is whatever the server last sent back.
  """
  @spec skeleton(String.t(), [String.t()]) :: String.t()
  def skeleton(uid, extra_lines \\ []) do
    body = Enum.map_join(["UID:" <> uid | extra_lines], "\r\n", & &1)

    "BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//Kati//EN\r\nBEGIN:VEVENT\r\n" <>
      body <> "\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n"
  end

  # ── Internals ──────────────────────────────────────────────────────────────

  defp normalise(changes) do
    Map.new(changes, fn
      {name, nil} -> {name, []}
      {name, value} when is_binary(value) -> {name, [value]}
      {name, values} when is_list(values) -> {name, values}
    end)
  end

  defp to_integer(text, default) do
    case Integer.parse(text) do
      {n, _} -> n
      :error -> default
    end
  end

  defp escape_text(value) do
    value
    |> String.replace("\\", "\\\\")
    |> String.replace(";", "\\;")
    |> String.replace(",", "\\,")
    |> String.replace("\r\n", "\\n")
    |> String.replace("\n", "\\n")
  end

  # ── Line model ─────────────────────────────────────────────────────────────
  #
  # A logical line keeps `raw` — the original bytes, folding and terminator
  # included — so an untouched line reproduces exactly. `text` is the unfolded
  # form used for comparison; `name` is the property name.

  @spec logical_lines(String.t()) :: [line()]
  defp logical_lines(raw) do
    ~r/(\r\n|\n|\r)/
    |> Regex.split(raw, include_captures: true)
    |> pair()
    |> Enum.reduce([], fn {content, sep}, acc ->
      continuation? = String.starts_with?(content, " ") or String.starts_with?(content, "\t")

      case {continuation?, acc} do
        {true, [prev | rest]} ->
          unfolded = binary_part(content, 1, byte_size(content) - 1)
          [%{prev | raw: prev.raw <> content <> sep, text: prev.text <> unfolded} | rest]

        _ ->
          [%{raw: content <> sep, text: content, eol: sep, name: name_of(content)} | acc]
      end
    end)
    |> Enum.reverse()
  end

  defp pair([content, sep | rest]), do: [{content, sep} | pair(rest)]
  defp pair([""]), do: []
  defp pair([content]), do: [{content, ""}]
  defp pair([]), do: []

  defp name_of(content) do
    case split_on_name(content, "") do
      {name, _rest} -> String.upcase(name)
      :none -> nil
    end
  end

  # The property name runs to the first ";" (parameters) or ":" (value).
  defp split_on_name(<<";", _::binary>> = rest, acc), do: {acc, rest}
  defp split_on_name(<<":", _::binary>> = rest, acc), do: {acc, rest}
  defp split_on_name(<<c, rest::binary>>, acc), do: split_on_name(rest, acc <> <<c>>)
  defp split_on_name(<<>>, _acc), do: :none

  defp split_on_colon(<<"\"", rest::binary>>, quoted?, acc),
    do: split_on_colon(rest, not quoted?, acc <> "\"")

  defp split_on_colon(<<":", rest::binary>>, false, acc), do: {acc, rest}

  defp split_on_colon(<<c, rest::binary>>, quoted?, acc),
    do: split_on_colon(rest, quoted?, acc <> <<c>>)

  defp split_on_colon(<<>>, _quoted?, _acc), do: :none

  defp vevent(raw) do
    lines = logical_lines(raw)
    open = index_of(lines, "BEGIN")
    close = index_of(lines, "END")

    if is_integer(open) and is_integer(close) and close > open do
      {:ok, lines, {open, close}}
    else
      {:error, :no_vevent}
    end
  end

  defp index_of(lines, marker) do
    Enum.find_index(lines, fn line ->
      line.name == marker and String.upcase(String.trim(line_value(line.text))) == "VEVENT"
    end)
  end

  # Direct children only: anything between a nested BEGIN and its END belongs
  # to that component, not to the event.
  defp children(lines, {open, close}) do
    lines
    |> Enum.with_index()
    |> Enum.slice(open + 1, max(close - open - 1, 0))
    |> Enum.reduce({[], 0}, fn {line, index}, {kept, depth} ->
      cond do
        line.name == "BEGIN" -> {kept, depth + 1}
        line.name == "END" -> {kept, max(depth - 1, 0)}
        depth == 0 and is_binary(line.name) -> {[{index, line} | kept], depth}
        true -> {kept, depth}
      end
    end)
    |> elem(0)
    |> Enum.reverse()
  end

  defp eol_of(lines) do
    Enum.find_value(lines, "\r\n", fn line -> if line.eol != "", do: line.eol end)
  end

  defp render(lines, {_open, close} = span, changes, eol) do
    kids = children(lines, span)
    touched = for {index, line} <- kids, Map.has_key?(changes, line.name), do: {index, line.name}
    replace_at = Map.new(touched)
    present = MapSet.new(kids, fn {_index, line} -> line.name end)

    # Only the first occurrence of a repeated property emits the replacement
    # list; later ones collapse to nothing, so `EXDATE` does not multiply.
    first_at = touched |> Enum.reverse() |> Map.new(fn {index, name} -> {name, index} end)

    added =
      changes
      |> Map.keys()
      |> Enum.reject(&MapSet.member?(present, &1))
      |> Enum.sort()
      |> Enum.map_join("", fn name -> emit(changes[name], eol) end)

    lines
    |> Enum.with_index()
    |> Enum.map_join("", fn {line, index} ->
      rendered = one(line, index, replace_at, first_at, changes, eol)
      if index == close, do: added <> rendered, else: rendered
    end)
  end

  # An untouched line keeps its original bytes; a touched one is emitted once,
  # at the position of its first occurrence.
  defp one(line, index, replace_at, first_at, changes, eol) do
    case Map.fetch(replace_at, index) do
      {:ok, name} -> if first_at[name] == index, do: emit(changes[name], eol), else: ""
      :error -> line.raw
    end
  end

  defp emit(values, eol) do
    Enum.map_join(values, "", fn value -> fold(value, eol) <> eol end)
  end

  # RFC 5545 §3.1: no content line longer than 75 octets, continuations begin
  # with a single space which counts toward the limit. Split on graphemes so a
  # multi-byte character is never cut in half.
  defp fold(line, eol) do
    line
    |> String.graphemes()
    |> Enum.reduce({[], ""}, fn grapheme, {done, current} ->
      if byte_size(current) + byte_size(grapheme) > @fold_limit do
        {[current | done], " " <> grapheme}
      else
        {done, current <> grapheme}
      end
    end)
    |> then(fn {done, current} -> Enum.reverse([current | done]) end)
    |> Enum.join(eol)
  end
end
