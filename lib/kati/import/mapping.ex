defmodule Kati.Import.Mapping do
  @moduledoc """
  Which column of somebody's export is which field of a watch.

  Screen 37 draws this — one row per column, the sampled value from the first
  data row, an arrow, and the field it maps to — and until now it drew a
  fixture. Every one of those rows is now a real column of the file the reader
  picked, mapped by its header.

  ## Matched by header, and never by position

  Trakt, Letterboxd, IMDb and Goodreads all put the title first and agree on
  nothing after it, and every one of them lets you re-order the columns before
  export. A mapping by position would be right for one file and silently wrong
  for the next; a mapping by header is right or it says it does not know.

  `@known` is the header vocabulary, lower-cased and stripped of spaces and
  punctuation so `My Rating`, `my_rating` and `Rating` are one key. A header
  that matches nothing is **skipped**, which is a real answer and what screen
  37's `skipped?` flag draws: an export carries columns Kati has no use for —
  Goodreads alone ships thirty — and skipping them is not a failure to
  understand the file.

  ## The fields, and why these

  Only what `Kati.Media` can hold about a watch: the title, the kind, when it
  was watched, the rating, the review, where, and the tags. `Kati.Media.Watch`
  is the destination for all but the first two, and the first two decide which
  `Kati.Media.TrackedTitle` the watch hangs off.

  ## The rating scale is read off the COLUMN, not the header

  A rating arrives on every scale there is — Letterboxd writes 0.5–5, Trakt and
  IMDb write 1–10, Goodreads writes 1–5 — and the header does not say which:
  Trakt and Letterboxd both call it `Rating`. That was the first version of
  this and it turned a Letterboxd `4.5` into five points out of ten.

  So `scale_of/2` reads the column itself, over every row, and it can be sure
  of the answer more often than it looks:

    * **a value above 5** can only be a ten-point scale;
    * **a half** below that can only be a five-star one, because no ten-point
      exporter writes `4.5`;
    * **whole numbers, none above 5** is genuinely ambiguous, and is read as
      five. A ten-point rater who happened never to rate anything above 5 is a
      rarer person than a Letterboxd export.

  Read once for the file rather than per row, so one outlying `9` settles the
  whole column rather than only its own line.
  """

  # Header → {field, scale}. The scale is only meaningful for `:rating`.
  @known %{
    "title" => {:title, nil},
    "name" => {:title, nil},
    "movietitle" => {:title, nil},
    "showtitle" => {:title, nil},
    "type" => {:kind, nil},
    "mediatype" => {:kind, nil},
    "watchedat" => {:watched_on, nil},
    "watcheddate" => {:watched_on, nil},
    "lastwatched" => {:watched_on, nil},
    "date" => {:watched_on, nil},
    "dateread" => {:watched_on, nil},
    "daterated" => {:watched_on, nil},
    # The scale here is only a HINT, and only for the two headers that name
    # one outright. `scale_of/2` reads the column and overrules it — see the
    # moduledoc.
    "rating" => {:rating, nil},
    "yourrating" => {:rating, :ten},
    "rating10" => {:rating, :ten},
    "myrating" => {:rating, nil},
    "rating5" => {:rating, :five},
    "review" => {:review, nil},
    "myreview" => {:review, nil},
    "notes" => {:review, nil},
    "service" => {:service, nil},
    "watchedon" => {:service, nil},
    "tags" => {:tags, nil},
    "bookshelves" => {:tags, nil}
  }

  # What screen 37 prints on the right of the arrow.
  @labels %{
    title: "Title",
    kind: "Kind",
    watched_on: "Watched on",
    rating: "Rating",
    review: "Review",
    service: "Where",
    tags: "Tags"
  }

  @doc """
  One row of screen 37's mapping card per column of the file.

  The sample is the first data row's value for that column, which is what makes
  the card worth reading: a reader checking a mapping is checking it against
  something they recognise.
  """
  @spec columns([String.t()], [[String.t()]]) :: [map()]
  def columns(headers, rows) do
    first = List.first(rows) || []

    headers
    |> Enum.with_index()
    |> Enum.map(fn {header, i} ->
      field = Kati.Import.Mapping.field_for(header)

      %{
        column: header,
        sample: Enum.at(first, i, ""),
        icon: if(field, do: "arrow_forward", else: "close"),
        field: if(field, do: Map.fetch!(@labels, field), else: "Skipped"),
        note: nil,
        skipped?: is_nil(field)
      }
    end)
  end

  @doc """
  The field a header names, or `nil`.

      iex> Kati.Import.Mapping.field_for("My Rating")
      :rating

      iex> Kati.Import.Mapping.field_for("Watched Date")
      :watched_on

      iex> Kati.Import.Mapping.field_for("Publisher")
      nil
  """
  @spec field_for(String.t()) :: atom() | nil
  def field_for(header) do
    case Map.get(@known, Kati.Import.Mapping.key(header)) do
      {field, _scale} -> field
      nil -> nil
    end
  end

  @doc """
  A header reduced to its comparable form: letters and digits, lower case.

      iex> Kati.Import.Mapping.key("  My Rating ")
      "myrating"

      iex> Kati.Import.Mapping.key("Rating (10)")
      "rating10"
  """
  @spec key(String.t()) :: String.t()
  def key(header) do
    header
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]/u, "")
  end

  @doc """
  Every row of the file as a record, with only the fields Kati understands.

  A row whose title is blank is dropped: a watch with no title is a watch of
  nothing, and every export has trailing blank lines.
  """
  @spec records([String.t()], [[String.t()]]) :: [map()]
  def records(headers, rows) do
    fields =
      headers
      |> Enum.with_index()
      |> Enum.flat_map(fn {header, i} ->
        case Map.get(@known, Kati.Import.Mapping.key(header)) do
          nil -> []
          {field, scale} -> [{i, field, scale}]
        end
      end)

    fields =
      Enum.map(fields, fn
        {i, :rating, hinted} -> {i, :rating, hinted || Kati.Import.Mapping.scale_of(rows, i)}
        other -> other
      end)

    rows
    |> Enum.map(&Kati.Import.Mapping.record(&1, fields))
    |> Enum.reject(&(Map.get(&1, :title, "") == ""))
  end

  @doc """
  Which scale a rating column is written on, read off the column.

  See the moduledoc for why the header cannot answer this.

      iex> Kati.Import.Mapping.scale_of([["4.5"], ["3"]], 0)
      :five

      iex> Kati.Import.Mapping.scale_of([["9"], ["4"]], 0)
      :ten

      iex> Kati.Import.Mapping.scale_of([["4"], ["3"]], 0)
      :five
  """
  @spec scale_of([[String.t()]], non_neg_integer()) :: :five | :ten
  def scale_of(rows, index) do
    numbers =
      rows
      |> Enum.map(&Enum.at(&1, index, ""))
      |> Enum.flat_map(fn cell ->
        case Float.parse(String.trim(cell)) do
          {number, _rest} -> [number]
          :error -> []
        end
      end)

    if Enum.any?(numbers, &(&1 > 5.0)), do: :ten, else: :five
  end

  @doc false
  @spec record([String.t()], [{non_neg_integer(), atom(), atom() | nil}]) :: map()
  def record(row, fields) do
    Enum.reduce(fields, %{}, fn {i, field, scale}, acc ->
      case Kati.Import.Mapping.value(field, Enum.at(row, i, ""), scale) do
        nil -> acc
        value -> Map.put(acc, field, value)
      end
    end)
  end

  @doc """
  One cell, read as the field it maps to.

      iex> Kati.Import.Mapping.value(:rating, "4", :five)
      8

      iex> Kati.Import.Mapping.value(:rating, "4", :ten)
      4

      iex> Kati.Import.Mapping.value(:watched_on, "2026/03/14", nil)
      ~D[2026-03-14]

      iex> Kati.Import.Mapping.value(:kind, "TV Show", nil)
      :tv

      iex> Kati.Import.Mapping.value(:tags, "read, coastal", nil)
      "read, coastal"
  """
  @spec value(atom(), String.t(), atom() | nil) :: term() | nil
  def value(_field, "", _scale), do: nil

  def value(:rating, raw, scale) do
    case Float.parse(String.trim(raw)) do
      {number, _rest} -> Kati.Import.Mapping.ten_point(number, scale)
      :error -> nil
    end
  end

  def value(:watched_on, raw, _scale), do: Kati.Import.Mapping.date(raw)

  def value(:kind, raw, _scale) do
    case Kati.Import.Mapping.key(raw) do
      "movie" -> :movie
      "film" -> :movie
      "tvshow" -> :tv
      "show" -> :tv
      "series" -> :tv
      "episode" -> :tv
      "tv" -> :tv
      _unknown -> nil
    end
  end

  def value(_field, raw, _scale), do: String.trim(raw)

  @doc """
  A rating on the scale it was written on, as the ten-point integer stored.

  Clamped rather than refused: an export with a `12` in a five-point column is
  a file somebody edited, and a ten is a truer reading of it than nothing.

      iex> Kati.Import.Mapping.ten_point(4.5, :five)
      9

      iex> Kati.Import.Mapping.ten_point(0.0, :ten)
      nil
  """
  @spec ten_point(number(), atom() | nil) :: 1..10 | nil
  def ten_point(number, scale) do
    points = if scale == :five, do: round(number * 2), else: round(number)

    cond do
      points < 1 -> nil
      points > 10 -> 10
      true -> points
    end
  end

  @doc """
  A date in any of the shapes an export writes, or `nil`.

  ISO first because it is what most of them write, then the two slash forms,
  then an ISO datetime — Trakt writes `2026-08-12T21:40:00.000Z` and the day
  is the part a watch keeps.

      iex> Kati.Import.Mapping.date("2026-08-12T21:40:00.000Z")
      ~D[2026-08-12]

      iex> Kati.Import.Mapping.date("14/03/2026")
      ~D[2026-03-14]

      iex> Kati.Import.Mapping.date("not a date")
      nil
  """
  @spec date(String.t()) :: Date.t() | nil
  def date(raw) do
    trimmed = raw |> String.trim() |> String.slice(0, 24)

    with :error <- iso(trimmed),
         :error <- iso(String.slice(trimmed, 0, 10)),
         :error <- slashed(trimmed) do
      nil
    else
      %Date{} = date -> date
    end
  end

  defp iso(text) do
    case Date.from_iso8601(text) do
      {:ok, date} -> date
      {:error, _why} -> :error
    end
  end

  # `2026/03/14` and `14/03/2026`. Which is which is decided by where the
  # four-digit part is, never by the values: `03/04/2026` is ambiguous in
  # exactly the way this cannot resolve, and it is read day-first because every
  # source that writes slashes with the year last writes it that way.
  defp slashed(text) do
    case String.split(text, ~r{[/.]}) do
      [<<_::binary-size(4)>> = year, month, day] -> build(year, month, day)
      [day, month, <<_::binary-size(4)>> = year] -> build(year, month, day)
      _other -> :error
    end
  end

  defp build(year, month, day) do
    with {y, ""} <- Integer.parse(year),
         {m, ""} <- Integer.parse(month),
         {d, ""} <- Integer.parse(day),
         {:ok, date} <- Date.new(y, m, d) do
      date
    else
      _bad -> :error
    end
  end
end
