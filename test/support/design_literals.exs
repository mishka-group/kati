defmodule Kati.DesignLiterals do
  @moduledoc """
  What a drawing says, in a form a rendered tree can be asked about.

  `test/design/screens/NN.html` is the design for screen NN: an exported
  frame of inline-styled `div`s, followed by the caption the designer wrote
  *about* the screen. This module pulls two lists out of the frame —

    * every **text literal** it draws, and
    * every **Material Symbol** it draws, by name —

  and supplies the other half of the comparison: `rendered/1`, which reads the
  same two things off a rendered view tree.

  This module exists so `Kati.ScreenDesignLiteralTest` can ask the **rendered
  tree** for these two lists, rather than grepping the screen's **source file**
  for them the way the deleted capture tooling did — `docs/DESIGN-ASSETS.md`
  records which script that was and why it went. The short of it is that the
  tree is the stronger question in two ways. It survives markup moving between
  functions or into a component, and it fails on a literal that is built
  somewhere in the module but never actually mounted into the tree.

  ## Three decisions about how a drawing is read

    * **Long lines are kept.** A length rule is a tempting thing to add — the
      deleted source-grepping script dropped every line over 90 characters as
      "probably the caption" — and it should stay out. The caption is already
      gone by then; it is the `max-width:380px` block this splits the file at.
      So the only lines such a rule takes are real ones: the long body
      paragraphs, which sit at the BOTTOM of the long screens and are exactly
      the copy no captured frame has ever shown.

    * **Comparison is case-insensitive.** The drawing says
      `text-transform:uppercase` in CSS and writes the label in sentence case;
      `Kati.UI.eyebrow/2` calls `String.upcase/1`. Both are the same label.

    * **`★` and `☆` are read as the `star` symbol.** The drawings print every
      rating as U+2605/U+2606 characters. No typeface Kati ships has those
      glyphs — Jakarta Sans has no star, which is the defect screen 08 shipped —
      so all seven rating screens draw Material Symbols `star` instead, on
      purpose and at length in `Kati.Screens.Rating`'s own moduledoc. Comparing
      the character against the glyph would report nine false absences, so both
      sides are mapped to the glyph before comparing.

  ## Matching is tiered, and the tier is part of the answer

  `locate/2` answers *where* a literal was found, not just *whether*:

    * `:node` — inside one `Text`'s own string. The strict reading.
    * `:flow` — spanning two adjacent `Text`s. `Kati.Screens.Search` draws its
      note as two nodes where the drawing writes one line; the words are all
      there, in order, and the drawing's line break is not a defect.
    * `:squashed` — same, ignoring whitespace. This exists for the rating rows:
      the drawing writes `★★★★☆` as one run and the app draws five separate
      `Text` nodes, which the flow join separates with spaces the drawing does
      not have.

  The weakest tier is the loosest claim, so `Kati.ScreenDesignLiteralTest` caps
  how much of the app is allowed to rest on it. Today it carries 7 of the 1575
  literals the 62 drawings hold; `:flow` carries 2 and `:node` the other 1562.
  """

  @screens_dir Path.expand("../../test/design/screens", __DIR__)

  # The export follows each frame with the designer's commentary in a
  # `max-width:380px` block, and then the NEXT screen's header. Everything from
  # that block onwards is about the screen rather than in it. Each design file
  # holds exactly one — `Kati.ScreenDesignLiteralTest` asserts that, because a
  # second one appearing earlier would silently truncate a screen to nothing and
  # the check would then pass on the empty remainder.
  @caption_marker ~r/<div[^>]*max-width:380px/

  # THE PLATFORM KEYBOARD IS NOT KATI'S TO DRAW.
  #
  # Screen 86 is the search field with the keyboard already up, and the artboard
  # draws the keyboard — twenty-six letter keys, a globe and a magnifier — as
  # context for the state it is documenting. Mob has no text input at all (#45),
  # and even when it does the keyboard will be the OS's: an app that drew its
  # own would be drawing a control the user cannot type on.
  #
  # So the block is cut before literals are taken, the same way the caption is.
  # The alternative was twenty-eight allow-list entries, one per key, which
  # would say nothing except that a sweep had been talked out of twenty-eight
  # assertions.
  #
  # Keyed on the tray's own fill and stacking — `#D6D2CB` at `z-index:20` — which
  # appears on exactly one artboard and nowhere else in the app's palette.
  @keyboard_marker ~r/<div[^>]*background:#D6D2CB[^>]*z-index:20/

  # Material Symbols are drawn as a ligature: the glyph NAME is the span's text
  # content. Both the name (for the icon list) and the removal of the span (so
  # the name is not counted a second time as copy) key off the font family.
  @icon_span ~r/<span[^>]*Material Symbols Rounded[^>]*>([a-z0-9_]+)<\/span>/
  @any_icon_span ~r/<span[^>]*Material Symbols Rounded.*?<\/span>/s

  # A line of nothing but digits and punctuation. Held out because `3` or
  # `23:00 – 08:00` matches somewhere in almost any tree — asserting on one is a
  # rubber stamp, not a check. The class includes the Persian and Arabic-Indic
  # digits, which are what screens 55-62 draw and which `\d` does not cover.
  @numeric_only ~r/^[\d\s.,:%·—–\-\x{06F0}-\x{06F9}\x{0660}-\x{0669}]+$/u

  # The next screen's own "NN — Name" header, in case an export ever puts it
  # before the caption block rather than after it.
  @next_header ~r/^\d\d\s+—/

  # Every entity the 62 drawings use, from
  # `grep -ohE '&[a-zA-Z#0-9]+;' test/design/screens/*.html`. Numeric
  # references (`&#1776;`, the Persian zero) are handled separately.
  @entities %{
    "&middot;" => "·",
    "&mdash;" => "—",
    "&ndash;" => "–",
    "&amp;" => "&",
    "&lt;" => "<",
    "&gt;" => ">",
    "&quot;" => "\"",
    "&nbsp;" => " ",
    "&starf;" => "★",
    "&star;" => "☆",
    "&pound;" => "£",
    "&rsquo;" => "’",
    "&lsquo;" => "‘",
    "&rdquo;" => "”",
    "&ldquo;" => "“",
    "&times;" => "×",
    "&hellip;" => "…",
    "&rarr;" => "→",
    "&deg;" => "°",
    # Added with the second wave of drawings: the money screens carry two more
    # currency symbols, and screen 122's pace arithmetic is written with a
    # division sign.
    "&euro;" => "€",
    "&divide;" => "÷",
    # Screen 109's delta column sets a true minus sign rather than a hyphen: the
    # column is numeric and U+2212 aligns with the digits where U+002D does not.
    "&minus;" => "−",
    # Board 188's note about the Times stepper: `a row of common times plus
    # &plusmn;5 minutes`. The first entity the 5-September export brought that
    # the earlier boards had not — and the failure mode if it is missing is not
    # a crash: the literal keeps the raw `&plusmn;` and no screen can ever
    # match it, so the sweep reports copy the screen draws correctly as absent.
    "&plusmn;" => "±"
  }

  @doc "Absolute path of screen `number`'s drawing. `number` is zero-padded."
  @spec path(String.t()) :: String.t()
  def path(number), do: Path.join(@screens_dir, number <> ".html")

  @doc """
  Every drawing on disk, as its zero-padded number.

  `test/design/screens/` is tracked, so this is not an optional input — an
  empty answer means the checkout is broken, not that there is nothing to
  check, and the test asserts the count rather than skipping.
  """
  @spec numbers_on_disk() :: [String.t()]
  def numbers_on_disk do
    @screens_dir
    |> Path.join("*.html")
    |> Path.wildcard()
    |> Enum.map(&Path.basename(&1, ".html"))
    |> Enum.sort()
  end

  @doc "How many caption blocks screen `number`'s drawing contains. Expected: 1."
  @spec caption_blocks(String.t()) :: non_neg_integer()
  def caption_blocks(number) do
    number |> path() |> File.read!() |> then(&Regex.scan(@caption_marker, &1)) |> length()
  end

  @doc """
  The frame of screen `number`, as `%{text: [...], icons: [...]}`.

  `text` is in the order the drawing lays it out, de-duplicated, already in
  comparison form (see `normalise/1`). `icons` is the Material Symbol names,
  sorted.
  """
  @spec read!(String.t()) :: %{text: [String.t()], icons: [String.t()]}
  def read!(number) do
    frame = number |> path() |> File.read!() |> frame()

    %{text: text_literals(frame), icons: icon_names(frame)}
  end

  @doc """
  One labelled band of a drawing, in the same shape `read!/1` answers.

  ## Why a drawing sometimes has to be read in parts

  Most drawings are one screen. A few are **reference sheets**: 27 (*States*)
  draws four specimens — empty, loading, offline, undo — and 101 (*Year cards*)
  draws five, each under its own uppercase eyebrow. A screen whose empty state
  the design draws on such a sheet is drawn by ONE of those bands, and comparing
  it with the whole file would demand it also render the other three specimens
  and the commentary beside them. That is not a fidelity check; it is a
  guaranteed failure that would end in the comparison being dropped.

  So a band is named by the two eyebrows that bound it, and everything between
  them is compared in full. Nothing is hand-listed: the design file is still the
  only source, and a re-export that adds a line to the band adds it here too.

  `from` and `to` are the drawing's own labels, **exactly as it writes them**
  (the em dash included). A missing anchor raises rather than answering with an
  empty band — a band nobody can find would otherwise turn into a comparison
  against nothing, which is the failure mode every count assertion in
  `Kati.ScreenDesignLiteralTest` exists to catch. `to` may be `nil` for the last
  band in a file.
  """
  @spec band(String.t(), String.t(), String.t() | nil) :: %{
          text: [String.t()],
          icons: [String.t()]
        }
  def band(number, from, to) do
    frame = number |> path() |> File.read!() |> frame() |> unescape()

    start = anchor!(frame, number, from) + byte_size(from)
    stop = if to, do: anchor!(frame, number, to), else: byte_size(frame)

    if stop <= start do
      raise ArgumentError,
            "screen #{number}'s drawing puts #{inspect(to)} before #{inspect(from)}, " <>
              "so the band between them is empty or inverted"
    end

    slice = binary_part(frame, start, stop - start)

    %{text: text_literals(slice), icons: icon_names(slice)}
  end

  defp anchor!(frame, number, label) do
    case :binary.match(frame, label) do
      {at, _length} ->
        at

      :nomatch ->
        raise ArgumentError,
              "screen #{number}'s drawing does not contain the band label #{inspect(label)}. " <>
                "The frame is a fixed artefact, so this is a re-export or a typo rather than " <>
                "a reason to compare against less"
    end
  end

  defp frame(html) do
    html
    |> then(&(@caption_marker |> Regex.split(&1, parts: 2) |> hd()))
    |> then(&(@keyboard_marker |> Regex.split(&1, parts: 2) |> hd()))
  end

  defp icon_names(frame) do
    @icon_span
    |> Regex.scan(frame)
    |> Enum.map(fn [_, name] -> name end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp text_literals(frame) do
    frame
    |> String.replace(@any_icon_span, " ")
    # Every tag becomes a line break, so a `<b>` inside a paragraph splits the
    # paragraph into its runs — which is what `Kati.UI.rich_text/1` is handed
    # and what a screen that does not use it draws as separate nodes.
    |> String.replace(~r/<[^>]+>/, "\n")
    |> unescape()
    |> String.split("\n")
    |> Enum.map(&normalise/1)
    |> Enum.reject(&drop?/1)
    |> Enum.uniq()
  end

  defp drop?(""), do: true

  defp drop?(line) do
    # `{{ x }}` is a data placeholder: the drawing is showing where a value goes,
    # not what it says.
    String.contains?(line, "{{") or String.starts_with?(line, "!--") or
      Regex.match?(@numeric_only, line) or Regex.match?(@next_header, line)
  end

  @doc """
  The comparison form: entities resolved, stars mapped to the `star` glyph,
  whitespace collapsed, case folded.

  Applied to both sides — a drawing's line and a rendered `Text`'s `text` — so
  that the only differences left are differences of content.
  """
  @spec normalise(String.t()) :: String.t()
  def normalise(string) do
    string
    |> String.replace(["★", "☆"], Kati.Icons.glyph!("star"))
    |> String.replace(~r/\s+/u, " ")
    |> String.trim()
    |> String.downcase()
  end

  defp unescape(string) do
    @entities
    |> Enum.reduce(string, fn {entity, char}, acc -> String.replace(acc, entity, char) end)
    |> String.replace(~r/&#(\d+);/, fn reference ->
      [_, digits] = Regex.run(~r/&#(\d+);/, reference)
      <<String.to_integer(digits)::utf8>>
    end)
  end

  # ── The other side of the comparison ────────────────────────────────────────

  @doc """
  Props a rendered node can carry copy in.

  Only `:text` is used by any screen today — `Kati.ScreenDesignLiteralTest`
  asserts that, off the trees themselves — but a `<TextField placeholder={…}>`
  or a `<Button text={…} label={…}>` would put copy in one of the others, and a
  harvester that read `:text` alone would not see it and would report the
  literal absent.
  """
  @spec content_props() :: [atom()]
  def content_props, do: [:text, :placeholder, :label, :value, :hint, :content_description]

  @doc """
  String props that are styling rather than copy: colours, families, alignments,
  the `src` of an image.

  Named so the test can assert that every string a tree carries is one or the
  other. A new string prop that is neither is the signal that copy has moved
  somewhere `content_props/0` does not look.
  """
  @spec styling_props() :: [atom()]
  def styling_props do
    [
      :align,
      :font_family,
      :font_weight,
      :shadow,
      :content_mode,
      :src,
      :text_align,
      :layout_direction,
      :gradient,
      :axis,
      # An identifier, never copy. `Mob.Renderer` emits it for every atom-tagged
      # control and `K-35 test-tag` turns it into a Compose `testTag` so a device
      # test can address the control by the name Elixir gave it. It is
      # deliberately NOT a `contentDescription`: TalkBack speaks that one, and a
      # screen reader announcing "choose en" over the visible label would be an
      # accessibility regression traded for a testing convenience.
      :accessibility_id,
      # A `<TextField>`'s behaviour, not its words. `keyboard` picks which
      # keyboard the OS raises — `decimal` for an amount, `number`, `email` —
      # and `return_key` names the action key. Neither is ever read by a person:
      # the copy in a field is its `placeholder`, which `content_props/0`
      # already covers.
      :keyboard,
      :return_key
    ]
  end

  @doc """
  Every string a rendered tree draws, in draw order, in comparison form.
  """
  @spec rendered(map()) :: [String.t()]
  def rendered(tree) do
    for node <- Mob.ScreenCase.flatten(tree),
        {key, value} <- Map.get(node, :props) || %{},
        key in content_props(),
        is_binary(value),
        do: normalise(value)
  end

  @doc "Every string prop key a rendered tree carries, whatever its meaning."
  @spec string_prop_keys(map()) :: [atom()]
  def string_prop_keys(tree) do
    for node <- Mob.ScreenCase.flatten(tree),
        {key, value} <- Map.get(node, :props) || %{},
        is_binary(value),
        uniq: true,
        do: key
  end

  @doc """
  Every icon glyph a rendered tree draws.

  `Kati.UI.symbol/2` puts the codepoint in a `Text`, so an icon is a one-glyph
  string in the private-use area — the only characters in the app that live
  there.
  """
  @spec rendered_glyphs(map()) :: MapSet.t(String.t())
  def rendered_glyphs(tree) do
    for node <- Mob.ScreenCase.flatten(tree),
        text = (Map.get(node, :props) || %{})[:text],
        is_binary(text),
        <<codepoint::utf8>> <- String.graphemes(text),
        codepoint in 0xE000..0xF8FF,
        into: MapSet.new(),
        do: <<codepoint::utf8>>
  end

  @doc """
  Where `literal` sits in `haystacks`: `:node`, `:flow`, `:squashed` or
  `:missing`. See the module doc for what each tier claims.
  """
  @spec locate(String.t(), %{nodes: [String.t()], flow: String.t(), squashed: String.t()}) ::
          :node | :flow | :squashed | :missing
  def locate(literal, %{nodes: nodes, flow: flow, squashed: squashed}) do
    cond do
      Enum.any?(nodes, &String.contains?(&1, literal)) -> :node
      String.contains?(flow, literal) -> :flow
      String.contains?(squashed, String.replace(literal, " ", "")) -> :squashed
      true -> :missing
    end
  end

  @doc "The three forms `locate/2` searches, built from `rendered/1`'s output."
  @spec haystacks([String.t()]) :: %{nodes: [String.t()], flow: String.t(), squashed: String.t()}
  def haystacks(texts) do
    flow = Enum.join(texts, " ")

    %{nodes: texts, flow: flow, squashed: String.replace(flow, " ", "")}
  end
end
