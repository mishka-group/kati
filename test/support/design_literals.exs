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

  `bin/check_screen.py` extracts the same two lists and greps the screen's
  **source file** for them. This module exists so `Kati.ScreenDesignLiteralTest`
  can ask the **rendered tree** instead, which is a stronger question in two
  ways: it survives markup moving between functions or into a component, and it
  fails on a literal that is built somewhere in the module but never actually
  mounted into the tree.

  ## Where this deliberately differs from `bin/check_screen.py`

    * **Long lines are kept.** `check_screen.py` drops any line over 90
      characters as "probably the caption". The caption is already gone by then
      — it is the `max-width:380px` block this splits the file at — so the only
      lines that rule removed were real ones: the long body paragraphs, which
      sit at the BOTTOM of the long screens and are exactly the copy no captured
      frame has ever shown.

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
    "&minus;" => "−"
  }

  @doc "Absolute path of screen `number`'s drawing. `number` is zero-padded."
  @spec path(String.t()) :: String.t()
  def path(number), do: Path.join(@screens_dir, number <> ".html")

  @doc """
  Every drawing on disk, as its zero-padded number.

  `.scratch/design/` is tracked (see `.gitignore`), so this is not an optional
  input — an empty answer means the checkout is broken, not that there is
  nothing to check, and the test asserts the count rather than skipping.
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
      :axis
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
