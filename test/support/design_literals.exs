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

  @doc """
  Lines a screen deliberately does not draw, because what carried them is gone
  and its absence is the decision.

  Here rather than in either sweep, because both ask the same question of the
  same screens — `Kati.ScreenDesignLiteralTest` against a populated render and
  `Kati.ScreenEmptyDatabaseTest` against an empty one — and two lists would
  drift the first time somebody retired a line and updated one of them.

  Screen 80's pairing card printed a six-character code, the address
  `listenbrainz.org/link`, and `Expires in 9:48`. All three were invented
  (MOVIES-AND-TV.md #71). Kati talks to none of the three providers it offers,
  so `Kati.Screens.DataSources.pairing_code/1` derived the code from the
  provider id; the address was ListenBrainz's under every one of them, so a
  Hardcover reader was sent to somebody else's site; and the clock never
  started, because nothing had. A reader who took the card at face value went
  to a URL that was not theirs and typed a code nobody had issued.

  The card names the site the token actually comes from now — `:site` on
  `Kati.Sources`, one per provider — says what connecting would bring, and
  says Kati cannot complete it yet. The slot is still there:
  `Kati.Screens.DataSources.ready?/1` answers `false` for all three today and
  the code comes back from the provider the day one answers `true`.

  82 is 80 in Persian and lost the same three lines for the same reason. en
  and fa are one app.
  """
  @spec retired_lines() :: [{String.t(), String.t()}]
  def retired_lines do
    [
      {"80", "enter this code"},
      {"80", "k4q9b2"},
      {"80", "listenbrainz.org/link"},
      {"80", "expires in 9:48"},
      {"82", "کد را وارد کنید"},
      {"82", "listenbrainz.org/link"},
      {"82", "تا ۹:۴۸ دیگر معتبر است"},
      # Board 314 replaced both of board 25's two lies, and it says so on its
      # own face: *"A TIME IT NEVER CHECKED, AND A CADENCE THAT NEVER RUNS."*
      #
      # `checked 18:02` was a wall-clock time from a column that did not exist
      # — the same defect 260 fixed on this page's sibling. The line is
      # relative now, from a real timestamp, and reads `never checked` on every
      # fresh install.
      #
      # `Manual` was one of four cadence segments and it meant NEVER: nothing
      # schedules a manual run, so picking it switched the watcher off in
      # silence. 314 makes it what it always was — a **Check now** button, which
      # runs the sweep once and stamps the line above it.
      # Board 308 replaced the label. `Can't find it? Add it by hand` asks the
      # reader to retype what they have just typed; the row NAMES the query now
      # — `Add "vellichor" by hand` — and is absent before a keystroke, because
      # it has nothing to name. 06 draws it mid-query and could not have drawn
      # the absent state.
      # Board 320 retires Hardcover, so 80's row no longer says what it supplies —
      # it says why it is not here. *"A row that vanishes reads as a bug and
      # gives the reader nothing to tap"*, so the row keeps its place and takes
      # 114's treatment: dimmed tile, dimmed label, `NOT IN V1`, and a tap that
      # opens the reason.
      # Board 83 draws two of its five notices as ONE sentence each, with a
      # clause of Kati's own welded onto the end — *… — this link is the licence
      # condition* and *…, both community-maintained*. mishka-group/kati#103
      # separates them, because they are different kinds of writing: the notice
      # is a quotation a licence requires and must not be translated, and the
      # clause is Kati talking and must be. A page cannot translate half a
      # string, which is why `Kati.Screens.AttributionFa` expressed the Persian
      # version by SHORTENING the notice — and so the mirror and the page it
      # mirrored disagreed about what the licence says.
      #
      # Every word the board draws is still drawn, in the same order, in the
      # same place: `notice` then `gloss`, two `Text` nodes instead of one. What
      # is retired is the joining punctuation.
      {"83",
       "schedule data from tvmaze, used under cc by-sa 4.0 — this link is the licence condition."},
      {"83",
       "music metadata from musicbrainz and cover art from the cover art archive, both community-maintained."},
      # Board 115 is the one board in the app that draws TWO screens on one
      # page: screen 109's weight half above screen 112's medication half. It
      # was `Kati.Screens.HealthFa`, and mishka-group/kati#103's ruling is that
      # a Persian reader gets the same screens an English one does — so the
      # board is registered against the half it leads with, and these are the
      # medication half's lines. Screen 112 draws every one of them, in Persian,
      # under `:fa`; what is retired is the claim that ONE page draws both.
      #
      # The last two are the direction note's second sentence, which is the
      # mirror talking about itself — `u+066b` and a clause about column
      # alignment. The note survives as `Kati.Screens.Weight.direction_note/0`;
      # the typography lecture inside it does not.
      {"115", "یکشنبه ۲۵ مرداد"},
      {"115", "داروهای امروز"},
      {"115", "لووتیروکسین"},
      {"115", "۵۰ میکروگرم"},
      {"115", "آهن"},
      {"115", "۶۵ میلی\u200Cگرم · جا افتاد"},
      {"115", "منیزیم"},
      {"115", "۲۰۰ میلی\u200Cگرم"},
      {"115", "خوردم"},
      {"115", "رد کن"},
      {"115", "u+066b"},
      {"115", "می\u200Cمانند تا ستون هم\u200Cتراز بماند."},
      # Board 97's mirror drew a *Show all 47* row over a catalogue it could not
      # read. Screen 92 draws a LIVE catalogue row instead — `catalogue_line/1`,
      # counting what this device actually knows about — and board 93 is where
      # the frozen `Show all 47` still belongs, over an empty one.
      # mishka-group/kati#103.
      {"97", "نمایش همه ۴۷"},
      {"80", "community book ratings"},
      {"06", "can’t find it? add it by hand"},
      {"25", "checked 18:02"},
      {"25", "manual"},
      # Board 141's sentence names the file it was captured from — a nine-column
      # Goodreads export written with ten-point ratings and slashed dates — and
      # every number and format in it is the reader's file's now
      # (MOVIES-AND-TV.md #101). `Kati.Screens.ImportRecognised.date_line/1`
      # still draws `YYYY/MM/DD` for a file written that way; the fixture's is
      # written `2026/03/14`, so what the board keeps is the SHAPE of the
      # sentence rather than its values.
      #
      # Two of the three are the values. The third, *Two columns are skipped*,
      # is a clause that is dropped entirely when nothing was skipped, which is
      # the same decision one clause smaller: a sentence counting columns that
      # do not exist is what this whole finding was.
      # Board 140's *Five more sources* names `Simkl · TV Time · Libib · Last.fm
      # · AniList`, and AniList is already one of the six tiles above it. The
      # drawing's own closing note counts eleven sources — six tiles, four new
      # names, the Kati backup row — so the board contradicts itself and the
      # arithmetic is the half that is right. It draws four now, and the two
      # lines it stopped drawing are the two the repeat was in.
      # MOVIES-AND-TV.md #126.
      # Board 12's *Kept automatically* card lists four rules and two of them
      # are assertions nothing stores: `Wishlist` and `Owned on disc` are
      # things a reader says about a title and no column holds. They were drawn
      # frozen at the drawing's `12` and `22` on every device, beside two rows
      # that CAN be counted — `Rewatches` and `Abandoned` are one query each —
      # and a card where two rows are the reader's library and two are somebody
      # else's reads as fully real. So they are not drawn rather than drawn
      # frozen, which is the call #75 made one screen over.
      # MOVIES-AND-TV.md #106.
      # Board 07's *More numbers* card froze four figures. Two of them are the
      # reader's own now — `Kati.Goals.Goal` and `Kati.Money.Expense` are real
      # resources — and are asserted by pattern in `device_values/0` instead.
      # The other two have no resource to count: `Kati.Habits` is a Sample
      # module and nothing else, and `Nutrition`'s `Cutting v3 · 86%` is a diet
      # plan no column holds, so those rows draw no second line rather than
      # somebody else's numbers. MOVIES-AND-TV.md #45.
      {"07", "4 active · 12-day best"},
      {"07", "cutting v3 · 86%"},
      {"12", "wishlist"},
      {"12", "owned on disc"},
      {"140", "five more sources"},
      {"140", "simkl · tv time · libib · last.fm · anilist"},
      {"141", "10pt → 5★"},
      {"141", "yyyy/mm/dd"},
      {"141", ". two columns are skipped."},
      # Board 323 makes screen 93's rules group screen 92's group, live — *"a
      # specimen switch is a dead control with a costume"*, and *"93 is 92 with
      # nothing configured, not a second screen with its own memory."* The
      # third row therefore carries 92's sentence, the one board 310 counted,
      # and this one goes.
      #
      # What it said is still true and is still the reason `hide_unavailable`
      # defaults to off — 323 calls that *"93's own reasoning, unchanged"* —
      # but it is a fact about `Kati.Services.default_rules/0` now rather than
      # a line of copy under a switch.
      {"93", "off by default — with no services set it would hide everything."},
      # Board 316 rewords screen 50's QR card. `Scan to import this plan`
      # promised an import and the mono line under it has said `SETTINGS ONLY`
      # since `Kati.Meals.SampleShare.qr_scope/0` was written — the two halves
      # of one card disagreeing. 316's ruling: *"Two ways out: widen the
      # encode, or reword the card. Reword. A QR holds about 2,900 bytes and 35
      # meals with ingredients is tens of kilobytes — widening it is not a
      # decision, it is a physical impossibility."* The card says `Scan to set
      # up this plan` now, over a sentence naming what does and does not
      # travel.
      {"50", "scan to import this plan"},
      # Board 98's badge under `Share…` named a fence that had already landed.
      # `K-20 file-transport` is `ACTION_SEND` behind a FileProvider URI and
      # `native/LEDGER.md` has carried the row since `Kati.Backup` needed a way
      # off the phone; `K-45 capture-screen` supplied the bytes. Both halves
      # existed and nothing joined them, so `Kati.Native.Files.share/2` had no
      # caller in `lib/` at all and the badge went on naming a wait that had
      # ended. `share_screen/1` is the join, and the badge is not reworded —
      # a marker naming no fence is a marker the next reader believes.
      {"98", "when file sharing lands"}
    ]
  end
end
