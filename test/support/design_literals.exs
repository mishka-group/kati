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
  `listenbrainz.org/link`, and `Expires in 9:48`. All three were invented.
  Kati talks to none of the three providers it offers,
  so `Kati.Screens.DataSources.pairing_code/1` derived the code from the
  provider id; the address was ListenBrainz's under every one of them, so a
  Hardcover reader was sent to somebody else's site; and the clock never
  started, because nothing had. A reader who took the card at face value went
  to a URL that was not theirs and typed a code nobody had issued.

  The card itself is gone now, with the whole group it sat in (N41): no code
  in `lib/` calls ListenBrainz, Hardcover or TheTVDB, so screen 80 offers to
  connect none of them. The site each token comes from stays on
  `Kati.Sources.tier2/0` for the day a client lands.

  82 is 80 in Persian and lost the same three lines for the same reason. en
  and fa are one app.
  """
  @spec retired_lines() :: [{String.t(), String.t()}]
  def retired_lines do
    [
      # N52-B: board 13's `Tomorrow` pill deferred a film to a day nothing
      # records, and board 36's Apple TV, Chromecast and browser-extension
      # rows, and its *Ask before ticking* and *Ignore trailers* rules, are
      # sources Kati cannot detect through and settings nothing stores. The
      # screens draw none of them on any device.
      {"13", "tomorrow"},
      {"36", "connected · 28 ticks"},
      {"36", "chromecast"},
      {"36", "on this network · 13 ticks"},
      {"36", "browser extension"},
      {"36", "not installed"},
      {"36", "get"},
      {"36", "ask before ticking"},
      {"36", "only when the match is unsure"},
      {"36", "ignore"},
      {"36", "trailers, anything under 5 min"},
      # Board 11: the match percentages, the corpus size, the people card, the
      # leaving-soon rail and the chip row that chose between them. Nothing
      # scores a title against a history, Kati has no person, nothing stores
      # when a title leaves a service, and with one section there is nothing
      # for a chip to choose — so `Kati.Screens.Discover` draws none of them on
      # any device. The glyph is `@retired_symbols`' in
      # `Kati.ScreenDesignLiteralTest`.
      {"11", "tuned to 128 titles"},
      {"11", "for you"},
      {"11", "people"},
      {"11", "leaving"},
      {"11", "awards"},
      {"11", "94% match"},
      {"11", "89% match"},
      {"11", "81% match"},
      {"11", "people you follow"},
      {"11", "ines karvel"},
      {"11", "director · 2 new projects"},
      {"11", "tomas rhee"},
      {"11", "writer · 1 in production"},
      {"11", "ada vance"},
      {"11", "actor · nothing new"},
      {"11", "leaving lumen+ in 7 days"},
      {"11", "nightbirds"},
      {"11", "on your wishlist"},
      {"11", "schedule"},
      {"11", "a quieter place to land"},
      {"11", "never started"},
      # Board 25: the switches with nothing behind them — leaving soon (no
      # availability data), people you follow (no person), price drops (no
      # prices), renewals (a subscriptions reminder, not a release) and the
      # weekly digest (no weekly job). The rows that stay say what they do now:
      # *New episodes* is episodes of shows you follow, and the badge is the dot
      # on Home's bell rather than a count. The glyphs are `@retired_symbols`'.
      {"25", "shows you are watching"},
      {"25", "leaving soon"},
      {"25", "7 days’ notice"},
      {"25", "people you follow"},
      {"25", "announcements, not just releases"},
      {"25", "price drops"},
      {"25", "titles on your wishlist"},
      {"25", "renewals"},
      {"25", "2 days before"},
      {"25", "unread count on the bell"},
      {"25", "weekly digest"},
      {"25", "sundays at 18:00"},
      # Screen 80's two key chips are drawn only on a build that carries Kati's
      # own key (`Kati.Media.Tmdb.bundled?/0`) — a development and testing
      # convenience, never present in a public build and never under test. The
      # reader's own token is the default now, so where there is nothing to
      # choose between there are no chips. `Kati.DataSourcesKeyTest` draws them
      # both ways.
      # N41: board 80 lists six providers beside TMDB — *Working out of the
      # box* (TVmaze, Open Library, MusicBrainz) and *Connect an account*
      # (ListenBrainz, Hardcover, TheTVDB, with ListenBrainz's pairing card
      # open and a connected row reading *ines.k · 412 listens*). Kati calls
      # none of the six — `Kati.SecureStore`'s inventory says so — so the page
      # advertised sources the app never touches. Both groups are gone, and
      # `Kati.Sources` keeps the lists for the day a client lands. The glyphs
      # are `@retired_symbols`' in `Kati.ScreenDesignLiteralTest`; 82 is 80 in
      # Persian.
      {"80", "working out of the box"},
      {"80", "tv & film · tvmaze"},
      {"80", "air dates, episode lists"},
      {"80", "books · open library"},
      {"80", "covers, editions, isbns"},
      {"80", "music · musicbrainz"},
      {"80", "albums, artists, cover art"},
      {"80", "connect an account"},
      {"80", "listenbrainz"},
      {"80", "scrobbles, listening history"},
      {"80", "hardcover"},
      {"80", "thetvdb"},
      {"80", "artwork, absolute ordering"},
      {"80", "pairing — expanded"},
      {"80", "connected as ines.k · 412 listens"},
      {"80",
       "listenbrainz needs your own token because it writes to your account, not kati’s. nothing is shared between users."},
      {"82", "بدون تنظیم کار می‌کند"},
      {"82", "فیلم و سریال · tvmaze"},
      {"82", "تاریخ پخش، فهرست قسمت‌ها"},
      {"82", "کتاب · open library"},
      {"82", "جلد، نسخه‌ها، شماره شابک"},
      {"82", "موسیقی · musicbrainz"},
      {"82", "آلبوم، هنرمند، تصویر جلد"},
      {"82", "اتصال حساب"},
      {"82", "listenbrainz"},
      {"82", "در حال جفت‌شدن"},
      {"82", "listenbrainz به توکن خودتان نیاز دارد، چون روی حساب شما می‌نویسد نه حساب کاتی."},
      {"80", "use kati’s key"},
      {"80", "use my own key"},
      {"82", "کلید کاتی"},
      {"82", "کلید خودم"},
      # And the paragraph under them argued against the owner's decision —
      # *paste your own only if you want your own limits* — where the reader
      # now brings their own token. It says how to get one instead.
      {"80",
       "kati’s key is public, because kati is open source. that costs you nothing — tmdb counts requests per ip address, not per key. paste your own only if you want your own limits."},
      {"82",
       "کلید کاتی عمومی است، چون کاتی متن‌باز است. این برای شما هزینه‌ای ندارد — tmdb درخواست‌ها را بر اساس نشانی ip می‌شمارد، نه بر اساس کلید."},
      # Board 141's summary ends *still editable* and nothing on 141 or 37 edits
      # anything: the rows describe a match, they do not offer one. The screen
      # drops the two words rather than keep a promise the app does not meet —
      # see `Kati.Screens.ImportRecognised`'s moduledoc for why the editor is a
      # feature and not a fix.
      {"141", "7 matched · 2 skipped · still editable"},
      # N43. Board 141 draws its mapping card twice — `Mapping — collapsed`
      # and `Mapping — expanded`, each under a mono label, captioned *expanded
      # below so both states are comparable*. The labels are a note to the
      # builder, and a reader importing a MyAnimeList list was shown the same
      # mapping twice under two design-review eyebrows. The screen draws the
      # collapsed card only, under screen 37's plain `Match columns`, and its
      # chevron opens screen 37 — where these nine rows are drawn with a
      # sampled value beside each. So the two labels and the expanded frame's
      # rows (the file's column names, the field each maps to, and the two
      # row notes) are this board's and not this screen's.
      {"141", "mapping — collapsed"},
      {"141", "mapping — expanded"},
      {"141", "title"},
      {"141", "author"},
      {"141", "my rating"},
      {"141", "converts 10pt → 5"},
      {"141", "rating"},
      {"141", "date read"},
      {"141", "finished on"},
      {"141", "bookshelves"},
      {"141", "to-read → wishlist"},
      {"141", "status"},
      {"141", "my review"},
      {"141", "review"},
      {"141", "number of pages"},
      {"141", "length"},
      {"141", "publisher"},
      {"141", "binding"},
      # Boards 24 and 62's account card and Data/About rows described an
      # account, a sync and a build Kati does not have: `Synced 2 min ago`, the
      # *Synced* pill, `1,204 ENTRIES`, `iCloud · this device + iPad`, a source
      # count nothing measured, and `0.1 · mock build`. THE RULE: print no
      # figure rather than the board's. The card keeps the section tally, Data
      # sources says whether TMDB has a token, Version is `mix.exs`'s (N1–N4).
      # Board 40's *Storage used* figure is the drawing's; the row reads the
      # database file and the shelf now (A4).
      {"40", "214 mb · 1,206 titles"},
      # Board 41 drew a specimen Up next card (*The Long Hollow · Season 2,
      # episode 6 · 18 minutes left*, Resume / Mark watched), a VoiceOver
      # sentence about *The Undertow*, 235% Dynamic Type, and an Increase
      # contrast switch that only restyled that page. The card and sentence are
      # the reader's own now and absent when nothing is on the go; the rest were
      # claims the app does not keep (A5). Settings' Text size row made the same
      # 235% claim.
      {"41", "dynamic type at 235%"},
      {"41", "up next"},
      {"41", "the long hollow"},
      {"41", "season 2, episode 6"},
      {"41", "18 minutes left"},
      {"41", "resume"},
      {"41", "mark watched"},
      {"41", "up to 235% · no truncation"},
      {"41", "increase contrast"},
      {"41", "hairlines darken, shadows drop"},
      {"41", "voiceover reads"},
      {"41", "episode row"},
      {"41",
       "“episode 6, the undertow. 55 minutes. airs 20 august. not watched. double-tap to mark watched.”"},
      {"24", "follows system · up to 235%"},
      {"24", "synced 2 min ago"},
      {"24", "1,204 entries · 4 sections"},
      {"24", "synced"},
      {"24", "tvmaze, open library, musicbrainz · 3 reachable"},
      {"24", "icloud · this device + ipad"},
      {"24", "0.1 · mock build"},
      {"62", "۲ دقیقه پیش همگام‌سازی شد"},
      {"62", "۱,۲۰۴ مورد · ۴ بخش"},
      {"62", "tvmaze، open library، musicbrainz"},
      {"62", "آی‌کلاد · این دستگاه و آی‌پد"},
      # Board 24's *Reorder sections* row opened nothing, and there is nothing
      # it could open: `Kati.Sections` keeps which sections are on and not their
      # order, and no surface reads one. The row is gone rather than a
      # chevron promising a page — `Kati.Settings.Sample.sections/0` has the
      # argument. Its Privacy line, *Nothing leaves the device*, is false the
      # moment a film is searched on TMDB; the row now says *No account, no
      # server, no analytics* and opens `Kati.Screens.Privacy`, which says what
      # does leave and where it goes.
      {"24", "reorder sections"},
      {"24", "drag to change home order"},
      {"24", "nothing leaves the device"},
      # Board 54's *Follows the language* rows were frozen sentences, the same
      # at every locale. Each now states what the current locale does, from the
      # function the app acts on — `Kati.Locale.calendar/0`, `numerals/0`,
      # `week_start/0` — and names the language that set it, the way the
      # writing-direction row always did: *Gregorian · set by English*, *Latin
      # 1234 · set by English*, *Monday · set by English*. The other language's
      # behaviour is one tap away on the picker above, and a line describing it
      # was a line nothing kept true. `Kati.LanguageFollowsTest` holds all four.
      {"54", "gregorian · shamsi available"},
      {"54", "latin 1234 · or persian ۰۱۲۳"},
      {"54", "monday · saturday in فارسی"},
      # Board 86's note promises a 180 ms debounce and seven counted queries per
      # pause. The search that page opens runs on every keystroke over the
      # reader's own library, so it says so — `Kati.Search.local_note/0`, which
      # screen 19 already draws for the same reason.
      {"86",
       "counts stay off the chips until a query exists — eight zeroes on open would read as an empty app. searching starts at"},
      {"86",
       "for persian, arabic and cjk, where one character is a word. keystrokes debounce at"},
      {"86", "180 ms"},
      {"86", ", so one pause costs seven counted queries, not seven per letter."},
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
      # ── Board 58's three dates, and why the fold writes them differently.
      #
      # **The Shamsi year.** `Kati.Locale.date/2`'s `:long` carries the year in
      # Persian and not in English, and its own doc gives the reason: *the
      # difference between a calendar whose year the reader knows by heart and
      # one whose year they do not.* Board 58 was drawn without it, and the
      # ruling is newer than the board — so the next-air line reads
      # **پنج‌شنبه ۲۹ مرداد ۱۴۰۵** and the two unaired episodes carry their year
      # too.
      #
      # **Episode six.** Board 58 draws it unaired and board 04 draws it aired,
      # at `55 min · 20 Aug`. One fixture cannot be both, and the English board
      # is the one `Kati.Library.Sample.series/0` was captured from — the
      # counter on both boards reads *5 of 7*, which only works with six aired.
      {"58", "قسمت بعد پنجشنبه ۲۹ مرداد، ساعت ۲۰:۰۰"},
      {"58", "پخش ۲۹ مرداد"},
      {"58", "پخش ۵ شهریور"},
      # ── Board 176's annotation, seven runs of it.
      #
      # `Kati.Screens.BooksFa` drew the board's own caption ON THE SCREEN — a
      # dashed aside reading *the same page 57 with three substitutions from
      # page 20: the Reading-now card instead of three tiles…*, with *radius 6*
      # and *fills from the right* in bold. That is the drawing describing how
      # it was built, addressed to somebody reading the drawing, and it is not
      # copy a person opening their shelf has any use for. Board 115's
      # direction note set the rule: what is a fact for the reader survives the
      # fold and the typography lecture does not.
      #
      # mishka-group/kati#103 folded that mirror into screen 20, whose own
      # board draws no such aside, and the aside went with it.
      {"176",
       "همان صفحه ۵۷ با سه جایگزینی صفحه ۲۰: کارت «در حال خواندن» به جای سه کاشی، چیپ‌های کتاب، و شبکه سه‌تایی با جلدهای"},
      {"176", "شعاع ۶"},
      {"176", ". نوار پیشرفت"},
      {"176", "از راست پر می‌شود"},
      {"176", "، جلدها هرگز آینه نمی‌شوند، و ترتیب عمودی برعکس نمی‌شود."},
      {"176", "همان واژه‌ای است که ۱۵۶ به کار می‌برد — یک ثبت، در هر دو جا."},
      # ── Board 55's air-date sub-line.
      #
      # *امشب پخش می‌شود · لومن‌پلاس* transliterates the SERVICE, and board 127
      # — the Persian Money page, where service names are the subject — draws
      # the same name as `Lumen+`. A service's name is the provider's name for
      # itself: a real one comes off `Kati.Services.Service` and no msgid
      # reaches it, so a fixture that transliterated would be the drawing
      # spelling something one way that every real row spells another. The
      # words around it are translated; the name is not.
      {"55", "امشب پخش می‌شود · لومن‌پلاس"},
      # ── Board 57's Wishlist chip and its four grid sub-lines.
      #
      # **آرزو and فهرست آرزو.** Board 57's fourth chip is *wish list* where
      # board 03's is *Not started*, and the tile under it says فهرست آرزو
      # where 03's says `not started`. They are the same state given a
      # different name, and the name board 57 gives it is the one
      # retired app-wide: board 12's *Wishlist* row went
      # with `bookmark` and `inventory_2` because a wish is an assertion a
      # reader makes about a title and no column in Kati holds it. A chip that
      # counts *not started* and calls it *wished for* would put the retired
      # claim back, one screen along.
      {"57", "آرزو"},
      {"57", "فهرست آرزو"},
      #
      # **فصل ۲ · ۵ از ۷, فصل ۱ · ۳ از ۸, فصل ۳ · ۱ از ۶, فیلم · ۲۰۲۵.** The
      # grid's sub-line is templated on board 03 — `{{ it.meta }}` in the export
      # — and board 57 fills it in with a season and an episode fraction, and
      # for the film with a kind and a year. `Kati.Screens.Library.tile_meta/1`
      # derives its line from the two facts a shelf row actually knows: the
      # status the user set, and how far in they are. A season NUMBER and an
      # episode TOTAL live on `Kati.Media.CachedTitle` and a release year on the
      # cache row beside them; the shelf carries a fraction, and the tile that
      # printed a season would be printing one it had inferred from a
      # percentage. Board 146's own grid makes the same trade and says so.
      {"57", "فصل ۲ · ۵ از ۷"},
      {"57", "فصل ۱ · ۳ از ۸"},
      {"57", "فصل ۳ · ۱ از ۶"},
      {"57", "فیلم · ۲۰۲۵"},
      # ── Board 56's annotation aside.
      #
      # *هفته از شنبه آغاز می‌شود* — *the week starts on Saturday.* The board's
      # own caption says the same thing at length: *"The Persian week begins on
      # شنبه, so the day strip reorders — a change no amount of CSS mirroring
      # would produce."* That is the drawing telling a builder what to build,
      # and the build was told: `Kati.Screens.Stats.week_start_on/1` answers the
      # reader's own first day and `day_strip/1` generates forward from it, so
      # the strip a Persian reader sees runs ش ی د س چ پ ج without a caption
      # saying that it does. Boards 176, 90 and 61 retired their asides on the
      # same reading — what is a fact for the reader survives, the note to the
      # builder does not.
      {"56", "هفته از شنبه آغاز می‌شود"},
      # ── Board 56's money row, and its airing group's two lines.
      #
      # **۸٫۹۹ پوند.** Three Persian boards write a price and they write it
      # three ways; 97 writes ۱۰٫۰۰ £ and is the one the money screens follow,
      # because `Kati.Services.Service.format/2` is a symbol-and-figure
      # formatter over `monthly_pence` and a currency code — it has no word for
      # a currency and would need a vocabulary for every code the user can type.
      # A price written پوند on the calendar and £ on the subscriptions page
      # would be the app saying one thing two ways, which is what this ticket is
      # about one level up.
      {"56", "۸٫۹۹ پوند"},
      #
      # **فصل ۲ · قسمت ۶ · پس‌کشند and ویژه · لومن‌پلاس.** Board 02 templates
      # this group's lines ({{ airingSub }}, {{ a.ep }} in the export) and board
      # 56 fills them in — with a different day's airing: one special episode,
      # named پس‌کشند, rather than 02's group of three. Both lines name
      # something a calendar row does not carry. `Kati.Calendars.Event` holds a
      # summary, a location and a kind; an air date's episode TITLE lives on
      # `Kati.Media.CachedEpisode` and nothing joins the two here, and *ویژه* is
      # a classification no column holds at all. So the group draws what it can
      # answer — the season, the episode number, the service and the hour, which
      # is `airing_meta/4` — and says nothing it would have to invent.
      {"56", "فصل ۲ · قسمت ۶ · پس‌کشند"},
      {"56", "ویژه · لومن‌پلاس"},
      # ── Board 61's annotation aside, and its four genre bars.
      #
      # **The aside.** *نمودارها هم برعکس می‌شوند: محور زمان از راست به چپ
      # خوانده می‌شود و میله‌ها از راست پر می‌شوند* — *charts flip too: the time
      # axis reads right to left and the bars fill from the right.* That is the
      # drawing telling a builder how to build it, and the build was told: the
      # container declares `rtl`, so the axis reads from the right and each
      # bar's fill is simply the first child of its track. Board 176's aside set
      # the rule and board 90's pair followed it — what is a fact for the reader
      # survives the fold, and the note to the builder does not.
      {"61",
       "نمودارها هم برعکس می‌شوند: محور زمان از راست به چپ خوانده می‌شود و میله‌ها از راست پر می‌شوند."},
      # **درام، هیجان‌انگیز، مستند، کمدی.** The genre bars are the genres TMDB
      # gave, split out of `Kati.Media.CachedTitle.genres` — a provider's own
      # vocabulary, stored as the provider wrote it. `Kati.Stats.Sample.year/0`
      # translates the FIXTURE's five, and those five are Drama, Documentary,
      # Comedy, Thriller and Everything else, which is board 07's set and not
      # board 61's: 61 draws four, in a different order, with هیجان‌انگیز where
      # 07 has Thriller. Board 07 asserts no genre name at all for the same
      # reason — what the bars say belongs to whatever the reader has watched.
      {"61", "درام"},
      {"61", "هیجان‌انگیز"},
      {"61", "مستند"},
      {"61", "کمدی"},
      # **پول.** Board 61's Money row and board 62's Money section are one
      # `gettext("Money")`, and the two boards write it differently: 62 says
      # مالی and 61 says پول. One msgid is one word, and the word that stands
      # is 62's — it labels a whole section of the app rather than one row into
      # it, and screen 24 has drawn it since that fold. A row that said پول
      # under a section called مالی would be the app calling one thing two
      # names, which is the defect this ticket is about one level up.
      {"61", "پول"},
      # ── Board 90's two annotations, its two counted group headings and its
      # two mis-converted dates.
      #
      # **The annotations.** Board 90's own caption rules them out of the
      # screen: *"The two normalisation promises are carried as on-screen
      # annotations, because they are the part a build has to be told rather
      # than shown."* They are addressed to whoever builds the search, and the
      # build was told — `Kati.Search.fold/1` does the folding and screen 88
      # draws the whole table plus the sentence about ي and ی under it. Board
      # 176's aside set the rule one fold earlier: what is a fact for the
      # reader survives and the note to the builder does not. The second aside
      # even links out to screen 54, which is a drawing cross-reference rather
      # than a control.
      {"90", "نوشتن"},
      {"90", "ي"},
      {"90", "واژه‌های با"},
      {"90", "را پیدا می‌کند، و"},
      {"90", "ك"},
      {"90", "را. نیم‌فاصله و اعراب نادیده گرفته می‌شوند و ارقام عربی و فارسی یکی شمرده می‌شوند."},
      {"90",
       "جست‌وجوی لاتین عنوان فارسی آوانویسی‌شده را پیدا می‌کند و برعکس — همان چیزی که گزینه «نمایش عنوان اصلی» در"},
      {"90", "روشن می‌کند."},
      #
      # **نمایش · ۳ and یادداشت‌ها · ۲.** Board 90 counts each group in its own
      # heading and then draws fewer rows than the count — three over two, two
      # over one. That gap is precisely the defect that was closed:
      # every group used to be cut to `Kati.Search.rows_per_group/0` BEFORE
      # `Kati.Search.Query.chip_counts/1` counted it, so the chip said three
      # over a list of two and the third row was unreachable from this page.
      # The cut is gone and a group now draws every row it counts, which makes
      # the heading's number the length of the list directly under it — and
      # board 19, the English capture of the same page, heads its groups with
      # the bare word. The count is on the chip, where both boards put it.
      {"90", "نمایش · ۳"},
      {"90", "یادداشت‌ها · ۲"},
      #
      # **۲۵ مرداد and ۶ مرداد.** Both are the board translating a Gregorian
      # date by swapping the month's name and keeping the Gregorian day.
      # 12 August 2026 is ۲۱ مرداد and 6 August is ۱۵ مرداد;
      # `Kati.Locale.date/2` converts rather than renames, so the episode line
      # reads **قسمت ۵ فصل ۲ · ۲۱ مرداد دیده شد** and the note's eyebrow
      # **یادداشت · ۱۵ مرداد · گودال بلند**. The episode line also carries its
      # season and episode back: board 90 dropped **S2E5** where board 19 draws
      # it, and a hit a reader cannot place is a hit they have to open to
      # identify.
      {"90", "قسمت · ۲۵ مرداد دیده شد"},
      {"90", "یادداشت · ۶ مرداد"},
      # ── Boards 74, 75 and 76's listen field, and board 76's art tile.
      #
      # **MAY / اردیبهشت.** The field is ninety-one days ending TODAY and the
      # month under it was a literal, so every device drew May whatever month
      # it actually was — the frozen-figure defect on a one-word label.
      # `Kati.Screens.AlbumDetail.field_month/0` reads the device clock and the
      # reader's calendar, so a Persian reader in Shahrivar sees شهریور.
      {"74", "may"},
      #
      # **75 held a SECOND copy of that literal**, which is why it is listed
      # separately rather than covered by the line above: closing the defect on
      # 74 left the states sheet drawing `MAY` on every device in every month,
      # and the two boards are the same card. It now calls the same helper, so
      # the fix cannot come apart again the way two copies of one answer do.
      # Its *Zero plays keeps the field, drawn and empty* eyebrow is what makes
      # the month read correctly rather than contradicting it — the window
      # belongs to the calendar, not to the album, and naming the reader's
      # current month claims nothing about when the record was played.
      {"75", "may"},
      {"76", "اردیبهشت"},
      # **T / Art.** The paper square's letter is the album title's own first
      # character — board 76 draws **ک**, because the album is کارهای جزر و مد
      # there — and the placeholder under it is a word, so it translates:
      # **هنر**. The board's Latin pair belongs to the English drawing, which
      # is board 74 and still draws both.
      {"76", "t"},
      {"76", "art"},
      # ── Board 69, folded into screen 66 by mishka-group/kati#103.
      #
      # **۱۴۰۳.** The board writes the publication year in Shamsi and the fold
      # writes **۲۰۲۴**, because a publication year is printed on the book: it
      # is on the copyright page, it is what a search for the edition matches,
      # and rendering it as ۱۴۰۳ makes the app disagree with the object in the
      # reader's hands. `Kati.Locale.year/1` is where that is ruled, and board
      # 69's own test has always asserted ۲۰۲۴ for a real book — the mirror's
      # FIXTURE said ۱۴۰۳ and its own test knew better.
      {"69", "۱۴۰۳ · ۳۸۰ صفحه"},
      #
      # **ISBN.** The board writes the Latin acronym on the Persian page and
      # screen 66 now writes **شابک**, which is the settled spelling everywhere
      # else in the app: `Kati.Screens.AddByHandBook`, 67's states row, 68's
      # dark row, the `Add ISBN` affordance and `Kati.Sources`' own
      # `شماره شابک` all say it. An Iranian book prints شابک on its copyright
      # page, so this is the same test the year above is decided by — what the
      # object in the reader's hands says — and it lands the other way, because
      # the year is a number printed once and this is a word with a standard
      # translation. 66 was the LAST page still drawing the acronym; 67's own
      # source carried a note saying so and that wrapping it belonged to that
      # file. This is that file having done it.
      {"69", "isbn"},
      # **تعداد صفحه** — *number of pages* — captioned the Length row, and the
      # moment the format chip could say صوتی that row presented a duration as
      # a page count. `Kati.Screens.BookDetailFa`'s answer was to draw no row
      # at all for a recording; screen 66 calls the row **Length**, which is
      # unit-neutral, and the fold gives board 69 **طول** rather than the
      # absence. The row is better than the hole.
      {"69", "تعداد صفحه"},
      # ── Boards 70 and 72's insight card, both halves of one sentence.
      #
      # It read *That's 46 pages **in 38 minutes** · your fastest this week*,
      # and the last two clauses were literals: nothing in the app had ever
      # timed a session, so `38 minutes` was the drawing's figure printed over
      # every book on every device and *your fastest this week* was a
      # comparison against a week of sittings nobody had read. Board 20's rule
      # — *either every value on the page is this reader's or every value is
      # the drawing's* — broken inside one sentence.
      #
      # `Kati.Screens.LogProgressFa` had already refused to draw them, which is
      # `D-59`'s ruling, and mishka-group/kati#103 folds that mirror into screen
      # 70. A fold that handed a Persian reader back a lie their own page had
      # stopped telling would be the worst possible outcome of tidying two
      # files into one, so both boards lose the clause together and
      # `Kati.Screens.LogProgress.duration_runs/2` is where it comes back.
      {"70", "38 minutes"},
      {"70", "· your fastest this week"},
      {"72", "۳۸ دقیقه"},
      {"72", "— سریع‌ترین این هفته"},
      # Board 72 is drawn with its timer RUNNING — `۰۰:۳۸:۱۲` on the face,
      # توقف on the button, and a commit that says *save and stop* because
      # there is something to stop. Screen 70 opens untimed: it offers
      # **شروع**, and its commit says ذخیره نشست. The running face is a state
      # this sheet can be in and not the state it opens in, which is exactly
      # board 156's arrangement one screen over.
      {"72", "توقف"},
      {"72", "ذخیره و توقف"},
      # ── Board 62, folded into screen 24 by mishka-group/kati#103.
      #
      # **The زبان و منطقه group.** Board 62 opens with four rows the English
      # settings page has never had: زبان over «فارسی · راست به چپ» with a
      # تغییر button, then تقویم/شمسی, اعداد/فارسی ۱۲۳۴ and شروع هفته/شنبه.
      # Every one of those four facts is on screen **53**, under its own
      # `FOLLOWS THE LANGUAGE` group — writing direction, calendar, numerals,
      # week start — and screen 24's Appearance group has one **Language** row
      # that opens it. So the group is not a feature this fold removes; it is
      # the same four settings, one tap further in, on the page that owns them.
      # A settings screen that edited the calendar in two places would be the
      # defect. `Kati.FaShellRoutesTest` holds the door.
      {"62", "زبان و منطقه"},
      {"62", "فارسی · راست به چپ"},
      {"62", "تغییر"},
      {"62", "شمسی"},
      {"62", "اعداد"},
      {"62", "فارسی ۱۲۳۴"},
      {"62", "شروع هفته"},
      {"62", "شنبه"},
      # **وعده‌ها in the Sections group.** Board 62 draws Meals as the third
      # section and board 24 draws Music. `Kati.Sections.all/0` is the
      # arbiter — `screen books music habits money notes`, and no `meals` — so
      # the Persian board is naming a section this app does not keep. A switch
      # for one would write nothing: `Kati.Screens.Settings.flip_switch/2`
      # falls through to a local flip for an id `Kati.Sections` has never heard
      # of, which is a toggle that moves and decides nothing. The fold keeps
      # the live list.
      {"62", "وعده‌ها"},
      # **ایران · ۳ سرویس.** Board 97's defect, on the row that opens it: a
      # country nobody chose and a count nobody has. Screen 24's own row was
      # frozen the same way — `United Kingdom · 3 subscribed`, retired by
      # pattern in `device_values/0` — and this is that entry's Persian twin,
      # which is why it is a pattern there rather than a retirement here.
      {"80", "community book ratings"},
      {"06", "can’t find it? add it by hand"},
      {"25", "checked 18:02"},
      {"25", "manual"},
      # Board 141's sentence names the file it was captured from — a nine-column
      # Goodreads export written with ten-point ratings and slashed dates — and
      # every number and format in it is the reader's file's now.
      # `Kati.Screens.ImportRecognised.date_line/1`
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
      # Board 12's *Kept automatically* card lists four rules and two of them
      # are assertions nothing stores: `Wishlist` and `Owned on disc` are
      # things a reader says about a title and no column holds. They were drawn
      # frozen at the drawing's `12` and `22` on every device, beside two rows
      # that CAN be counted — `Rewatches` and `Abandoned` are one query each —
      # and a card where two rows are the reader's library and two are somebody
      # else's reads as fully real. So they are not drawn rather than drawn
      # frozen, which is the call #75 made one screen over.
      # Board 07's *More numbers* card froze four figures. Two of them are the
      # reader's own now — `Kati.Goals.Goal` and `Kati.Money.Expense` are real
      # resources — and are asserted by pattern in `device_values/0` instead.
      # The other two have no resource to count: `Kati.Habits` is a Sample
      # module and nothing else, and `Nutrition`'s `Cutting v3 · 86%` is a diet
      # plan no column holds, so those rows draw no second line rather than
      # somebody else's numbers.
      {"07", "4 active · 12-day best"},
      {"07", "cutting v3 · 86%"},
      {"12", "wishlist"},
      {"12", "owned on disc"},
      # Board 153 drew the numbering feature rather than one show's numbering:
      # both states at once, design-note eyebrows, and a MyAnimeList import
      # tile. The page is one show's now (`Kati.Media.TrackedTitle.numbering`):
      #   * the subtitle is the show's name, not the board's thesis line, and
      #     the two notes that argued the design to its reader are replaced by
      #     one that states the rule;
      #   * a show is inherited OR overridden, so the overridden row, its sub
      #     and its Reset pill are drawn only when the column is set —
      #     `Kati.NumberingTest` draws them — and its eyebrow is a plain
      #     *Overridden*;
      #   * the scheme words are screen 34's tiles (*Aired*, *Absolute*), so
      #     *Seasons* is not a second name for Aired, and a season-and-episode
      #     is spelled `S2 · E6` as everywhere else in Kati;
      #   * the MyAnimeList tile described an XML importer, scores and watched
      #     counts coming across — Kati imports CSV and maps none of those from
      #     a MyAnimeList export, so the tile is not drawn. Its glyphs are
      #     `@retired_symbols`' in `Kati.ScreenDesignLiteralTest`.
      {"153", "a default that announces its own reason"},
      {"153", "that phrasing is the point. an inherited default that says"},
      {"153", "why"},
      {"153",
       "is the difference between a helpful guess and a confusing one — and numbering is the single most common thing anime trackers get wrong."},
      {"153", "overridden — the override announces itself"},
      {"153", "seasons"},
      {"153", "you set this · anime default was absolute"},
      {"153", "reset"},
      {"153", "s2 e6"},
      {"153",
       "showing both is clutter; showing the wrong one is a bug. storage is one scheme, display is a preference."},
      {"153", "the myanimelist tile — sole integration those users get"},
      {"153", "myanimelist"},
      {"153", "animelist.xml"},
      {"153", "comes across"},
      {"153", "titles, scores, watched counts, status, dates"},
      {"153", "set to absolute — mal exports are absolute"},
      {"153", "does not"},
      {"153", "reviews, tags and your mal friends"},
      {"153",
       "xml is importer-only — there is no mal sync. this tile is the whole of a mal user’s onboarding, so it states both halves."},
      {"152", "marram"},
      {"152", "tagged anime from a mal import — it is live action"},
      {"152", "not anime"},
      {"167", "showing 15 of 15"},
      {"145", "older"},
      {"145", "4 and up"},
      {"145", "3 and up"},
      {"145", "unrated"},
      {"145", "lumen+"},
      {"145", "orbit"},
      {"145", "dropped"},
      {"145", "gone cold"},
      # 144's rewatch SWATCH, deleted rather than kept. It drew
      # `Sample.reference_verdict/0` as "what you said last time" on the branch
      # where `rewatch?` is FALSE — a first watch, which has no last time — so
      # the card could only ever be somebody else's review in the reader's own
      # sheet. The real previous verdict is still drawn, by `rewatch_block/2`,
      # off the reader's own second-newest Watch.
      {"144", "rewatch \u2014 your last verdict, above the input"},
      {"144", "you, 3 mar 2024 \u00b7 \uF09A4"},
      {"144",
       "the estuary scenes land completely differently once you know what mara is looking for."},
      # Board 39's three phantom widgets and its voice shortcuts, all deleted.
      # The board drew four tiles at four sizes; exactly one of them exists as a
      # widget a reader can add, and it is UP NEXT, which the page now previews
      # from `Kati.Screens.UpNext.queue/0` — the same hero the shipped Glance
      # widget reads. TONIGHT, STREAK and the wide variant were pictures of
      # widgets nobody can put on a home screen.
      #
      # The shortcuts went for a blunter reason: they are Siri phrases, in an
      # Android app, and there is no voice layer anywhere in `lib/`. Their
      # switches stored nothing and armed nothing.
      {"39", "sizes"},
      {"39", "up next"},
      {"39", "long hollow"},
      {"39", "s2e6"},
      {"39", "tonight"},
      {"39", "episodes airing"},
      {"39", "streak"},
      {"39", "nights"},
      {"39", "today · wide"},
      {"39", "6 episodes air"},
      {"39", "call mum"},
      {"39", "shortcuts"},
      {"39", "“hey siri, what’s next?”"},
      {"39", "reads your next episode"},
      {"39", "“mark it watched”"},
      {"39", "ticks whatever is in progress"},
      {"39", "“add to my list”"},
      {"39", "adds a title by name"},
      {"39", "automations"},
      {"39", "run a shortcut when a season ends"},
      {"145", "showing 41 of 418"},
      # 146's own copy of the same figures. The line still renders — it is
      # `<shown> of <total> · <sort>` off the reader's shelf and their stored
      # sort — but 41 and 418 were the board showing a filter narrowing a big
      # library, and no real shelf answers them. Board 145 retired the same
      # numbers one line above.
      {"146", "41 of 418 \u00b7 recently added"},
      {"145", "ranges are"},
      {"145", "chip buckets"},
      {"145",
       ", not sliders — the app has no slider in its component table, and a bucket carries a count while a slider cannot. count badges exist so a chip that would empty the shelf says so"},
      {"145", "before"},
      {"145", "it is tapped: comedy reads 0 in hairline grey."},
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
      {"98", "when file sharing lands"},
      # Board 129 is drawn mid-preview over a file on the designer's desk, and
      # every figure on it is a claim about somebody's data: the filename, the
      # `384 / 28 / 6` dry run, the `Blue Hour` conflict at `1 of 6`, `Merge
      # 384`, and the `418 titles` Replace would delete. Kati has no dry run
      # and no per-row conflict — `Kati.Backup.Restore` merges insert-only and
      # reports skips afterwards — so the conflict card, its eyebrow and the
      # `New` / `Conflicts` labels are gone, and the merge note's *until you
      # finish the last conflict* went with them. The filename row, the button
      # and the Replace card draw the picked file's name and count and
      # `Kati.Backup.occupied/0`'s count instead, and say so plainly when there
      # is none; `Kati.BackupRestoreRealTest` asserts both branches. 132 is 129
      # in Persian and lost the same lines for the same reason.
      {"129", "kati-backup-2026-08-14.json"},
      {"129", "new"},
      {"129", "conflicts"},
      {"129", "into it. nothing is written until you finish the last conflict."},
      {"129", "conflicts · keep which?"},
      {"129", "blue hour"},
      {"129", "yours 4 · file says 5"},
      {"129", "keep mine"},
      {"129", "take file"},
      {"129", "keep both"},
      {"129", "1 of 6 · apply to all"},
      {"129", "merge 384 into this device"},
      {"129",
       "deletes all 418 titles, every note and every session, then writes the file in their place. there is no undo once it finishes."},
      {"132", "kati-backup-2026-08-14.json"},
      {"132", "تازه"},
      {"132", "تعارض"},
      {"132", "می‌شود. تا پایان آخرین تعارض چیزی نوشته نمی‌شود."},
      {"132", "تعارض‌ها · کدام بماند؟"},
      {"132", "ساعت آبی"},
      {"132", "شما ۴ · فایل می‌گوید ۵"},
      {"132", "مال من"},
      {"132", "هر دو"},
      {"132", "۱ از ۶ · برای همه"},
      {"132", "ادغام ۳۸۴ مورد"},
      {"132",
       "هر ۴۱۸ عنوان، همه یادداشت‌ها و جلسه‌ها حذف می‌شوند و فایل جای آن‌ها نوشته می‌شود. بعد از پایان، بازگشتی نیست."},
      # Board 151 is a specimen sheet: four states of notification access stacked
      # at once. The screen draws the ONE state `Kati.Media.Detect.access/0` and
      # the detected-tick count read (N22), and a host has no bridge, so the
      # compared render is the *Not on this build* state — its retired row.
      #
      # Gone for good: the three eyebrows that annotate the design rather than
      # label a state (*purpose, then scope, then the action*; *different
      # wording*; *what actually ships*), each replaced by the state's plain
      # name; the footnote explaining that the states above are a design
      # record; the revoked card's four fragments around the board's `128
      # tracks`, which are one sentence with the real count of detected ticks
      # now (detection ticks films and episodes, so it does not say tracks);
      # *music apps … every track*, which described a detector Kati does not
      # have; and *row on 40*, which named a board number to a reader.
      {"151", "not granted — purpose, then scope, then the action"},
      {"151", "revoked after being granted — different wording"},
      {"151", "what actually ships — retired"},
      {"151", "play protect blocks sideloaded apks declaring"},
      {"151", "notification_listener"},
      {"151", ", and kati installs directly. so the three states above are the"},
      {"151", "design record"},
      {"151", ", and the live row wears"},
      {"151",
       "’s retired treatment — it keeps its place and explains itself rather than vanishing."},
      {"151", "kati logged"},
      {"151", "128 tracks"},
      {"151", "while it was on and"},
      {"151", "keeps all of them"},
      {"151",
       "to see what your music apps are playing, so you do not have to log every track by hand."},
      {"151", "folded into the ordinary notifications row on"},
      # Drawn, but only in a state a host cannot be in: the not-granted card, the
      # turned-off card and the granted row. A device draws whichever one its
      # grant is in; `Kati.NotificationAccessStatesTest` draws all three and
      # asserts each carries its own lines and none of the others'.
      {"151", "why kati wants it"},
      {"151", "what it can see."},
      {"151", "android grants this as access to"},
      {"151", "every notification on the device, messages included"},
      {"151", ". kati reads only media notifications and never stores anything else."},
      {"151", "open system settings"},
      {"151", "special access · no dialog to raise"},
      {"151", "it is"},
      {"151",
       ". a permission that can read every message in a person’s life does not belong in a list next to “show me notifications”."},
      {"151", "turned off in system settings"},
      {"151", ". nothing new is detected until it is turned back on."},
      {"151", "log by hand instead"},
      {"151", "granted"},
      {"151", "on · media notifications only"},
      {"151", "live"},
      # Boards 163 and 166's poster wall: four films that do not exist, in both
      # scripts, and the note's sentence about their artwork. Shelving one put a
      # title nobody can look up on the shelf with a design seed as its poster,
      # which Home, the Library and Up next then drew as the reader's own film
      # (N46). Step 5 is screen 06's TMDB search now, so there is no wall, no
      # artwork to mirror and no tick on a tile; `Kati.OnboardingFirstTitleTest`
      # adds a real title through it.
      {"163", "the long hollow"},
      {"163", "ashfall"},
      {"163", "marram"},
      {"163", "nightbirds"},
      {"163", ". artwork never mirrors; only the tick moves to the leading corner."},
      {"166", "گودال بلند"},
      {"166", "بارش خاکستر"},
      {"166", "مرام"},
      {"166", "پرندگان شب"},
      {"166", "در انگلیسی. پوسترها هرگز آینه نمی‌شوند؛ فقط تیک به گوشه پیشرو می‌رود."},
      # N50: screen 86's note argued the design ("a row of zeroes on open
      # would read as an empty app") to the reader; it now says where search
      # looks and how much to type. `Kati.SearchGroupsTest` asserts it.
      {"86", "2 characters"},
      {"86", ", or"},
      # N49: the first run read its designers' notes aloud — board 161's
      # restore note, 162's "band drawn on 136", 163's "Skipping lands on
      # empty Home — 139" and their Persian twins — and offered a Weekly
      # digest nothing sends. Board 136 redrew step 4's question with
      # Quietly ticked over the permission it asked for; the screen now
      # draws only the permission. `Kati.OnboardingHonestTest` asserts it.
      {"136", "how should we"},
      {"136", "tell you?"},
      {"136", "kati checks for new episodes on its own. you choose how loudly it mentions them."},
      {"136", "quietly"},
      {"136", "a card on home. nothing buzzes."},
      {"136", "notify me"},
      {"136", "a push when something lands."},
      {"136", "weekly digest"},
      {"136", "one summary, sundays at 18:00."},
      {"136", "won’t ask"},
      {"136", "for notification permission. everything arrives in your inbox."},
      {"136", "if notify me or weekly digest is chosen"},
      {"136",
       "kati asks the system for permission on the next screen. it is used for new episodes and the meal reminders you switch on — nothing else."},
      {"136",
       ". android does not allow a second prompt — the only route back is the system settings app, which is where this screen would send you."},
      {"136", "back to sections"},
      {"161", "restore stays beneath the button"},
      {"161",
       "in both scripts. rtl mirrors the grid, not the vertical order — primary above, quiet alternative below."},
      {"162", "weekly digest"},
      {"162", "one summary, sundays at 18:00."},
      {"162",
       "choosing notify me or weekly digest raises the os prompt on the next step — the band drawn on"},
      {"163", "skipping lands on"},
      {"163", "empty home"},
      {"164", "بازگردانی زیر دکمه می‌ماند"},
      {"164",
       "— جایش عوض نمی‌شود. در rtl همه‌چیز آینه می‌شود جز ترتیب عمودی: عمل اصلی بالا، جایگزین آرام پایین، در هر دو زبان."},
      {"165", "خلاصه هفتگی"},
      {"165", "یک خلاصه، جمعه‌ها ساعت ۱۸:۰۰."},
      {"165", "اگر «خبرم کن» را انتخاب کنید، گام بعد اجازه سیستم را می‌گیرد — همان بندی که در"},
      {"165", "کشیده شده."},
      {"166", "رد کردن این گام به"},
      {"166", "خانه خالی"},
      {"166", "می‌رسد —"},
      {"166", "در فارسی،"},
      # N51: boards 16, 17 and 30 were drawn from `Kati.Calendar.SampleMonth`,
      # `SampleWeek` and `SampleAgenda` — August 2026, a Thursday of fourteen
      # items and two clashes, and titles nobody stored. The three views read
      # the reader's calendar now and an empty store draws *Nothing
      # scheduled*. The legend's section names and a real row's words appear
      # over a month with items in it, which `Kati.CalendarViewsRealTest`
      # asserts; *Habits* is no section the calendar has.
      {"16", "august 2026"},
      {"16", "screen"},
      {"16", "personal"},
      {"16", "habits"},
      {"16", "thu 20 · 14 items · 2 clashes"},
      {"16", "2 at once — standup, design review"},
      {"16", "3 at once — lunch, plumber, +1"},
      {"16", "6 episodes air"},
      {"17", "10 – 16 aug"},
      {"17", "thu 13 · 9 items"},
      {"17", "standup"},
      {"17", "15m"},
      {"17", "design review"},
      {"17", "1h"},
      {"17", "lunch — jo"},
      {"17", "6 episodes air"},
      {"17", "to 23:00"},
      {"17", "thursday is carrying"},
      {"17", "9 items"},
      {"17", ". two things could move to friday."},
      {"30", "today"},
      {"30", "sun 16 aug"},
      {"30", "the long hollow s2e6"},
      {"30", "lumen+"},
      {"30", "call mum"},
      {"30", "repeats weekly"},
      {"30", "tomorrow"},
      {"30", "mon 17 aug"},
      {"30", "morning run"},
      {"30", "habit · 12-day streak"},
      {"30", "lumen+ renews"},
      {"30", "£8.99"},
      {"30", "thu"},
      {"30", "20 aug · 14 items · 2 clashes"},
      {"30", "2 at once — standup, design review"},
      {"30", "clash"},
      {"30", "6 episodes air"},
      {"30", "lumen+, orbit, kino"},
      {"30", "sep"},
      {"30", "04 sep"},
      {"30", "vellum in cinemas"},
      {"30", "wishlisted"},
      {"30", "nothing else until 12 sep"},
      # N51: board 09's all-day band, its merged renewals row and its
      # fourteen-item headline were `Kati.Calendar.SampleDay`'s, drawn for an
      # empty calendar. None can be computed from a stored event — the day
      # screen's moduledoc says why — so a real day draws its cards alone.
      {"09", "14 items · 2 clashes"},
      {"09", "day"},
      {"09", "vellum — in cinemas"},
      {"09", "release · wishlisted"},
      {"09", "2 renewals"},
      {"09", "£22.98"},
      # N52-A: board 14's Trailer button and the synopsis's *more* — there is
      # no trailer link and no expander, so screen 14 draws neither on any face.
      {"14", "more"},
      {"14", "trailer"},
      # N52-A: board 35's rows with nothing behind them — two switches nothing
      # reads, two with no column, the board's own region and service figures,
      # and the whole *This show* group. Screen 35 no longer falls back to the
      # board, so no face of it draws them; a real show's status tiles, season
      # pass and region rows are what the board is compared against.
      {"35", "auto-add new seasons"},
      {"35", "s4 will appear when announced"},
      {"35", "put air dates on calendar"},
      {"35", "personal · orange"},
      {"35", "lumen+, orbit, kino · 3 of 12"},
      {"35", "watch for price drops"},
      {"35", "wishlist titles under £8"},
      {"35", "preferred quality"},
      {"35", "4k hdr where offered"},
      {"35", "this show"},
      {"35", "reset progress"},
      {"35", "currently 5 of 7 in s2"},
      {"35", "archive"},
      {"35", "keeps history, hides from shelf"},
      {"35", "remove from library"},
      # N52-A: board 143 was a specimen sheet — three bands captioned for the
      # designer, a hint about a long press Mob cannot perform and a memo about
      # a gesture no screen has. Screen 143 reads the reader's season now, and
      # its header counts ratings rather than restating 04's watched line.
      {"143", "season 2 · 5 of 7 watched"},
      {"143", "some rated — the normal case"},
      {"143", "a numeral plus"},
      {"143", "one"},
      {"143",
       "star, in dm mono, so the column aligns — nobody reads five small stars, they read a shape. an unrated watched episode shows"},
      {"143", "nothing at all"},
      {"143", ", not five hollow stars, which is what lets the ratings stand out."},
      {"143", "none rated — no column at all"},
      {"143", "the long-press hint — shown once"},
      {"143", "hold a row to rate it"},
      {"143",
       "the only long press in the app besides selecting on a shelf. shown once, then dismissed for good."},
      {"143", "got it"},
      {"143", "the gesture rule, recorded:"},
      {"143", "long press on a"},
      {"143", "shelf tile"},
      {"143", "selects; long press on an"},
      {"143", "episode row"},
      {"143",
       "rates. two meanings, two unmistakably different surfaces — a grid of artwork against a list of rows. also on"},
      # N52-D: board 139's dashed footnote was the design's reasoning read to
      # the reader. 158 and 159 are the same page in Persian and in dark.
      {"139",
       "home is a page of section cards, so with no sections there is nothing for it to show. the calendar and quick-add are section-agnostic and stay live —"},
      {"139", "the app is usable before it is configured"},
      {"158", "خانه صفحه‌ای از کارت‌های بخش‌هاست، پس بدون بخش چیزی برای نشان‌دادن ندارد."},
      {"158", "تقویم و افزودن سریع به بخش وابسته نیستند"},
      {"158", "و همیشه زنده می‌مانند — پیش از آنکه برنامه تنظیم شود هم می‌شود از آن استفاده کرد."},
      {"159", "خانه صفحه‌ای از کارت‌های بخش‌هاست، پس بدون بخش چیزی برای نشان‌دادن ندارد."},
      {"159", "تقویم و افزودن سریع به بخش وابسته نیستند"},
      {"159", "و همیشه زنده می‌مانند — پیش از آنکه برنامه تنظیم شود هم می‌شود از آن استفاده کرد."},
      # N52-C: board 05's Mark all is drawn only when an Out now row can be
      # ticked, and the board's rows have no episode behind them. Board 92's
      # credit named its page by board number, *credited on 83*; it names it
      # by title now.
      {"05", "mark all"},
      {"92",
       "which service carries what comes from justwatch, through tmdb. both are credited on"},
      # N52-E: board 31's Invitees card. `Kati.Calendars.Event` has no attendee
      # table, so the card was drawn empty over every real event and ended in
      # an `Add someone` row that looked like a control and had no tap — there
      # is nobody to add and nowhere to keep them. The heading, the two guests
      # and their replies went with it.
      {"31", "invitees"},
      {"31", "jo mercer"},
      {"31", "accepted"},
      {"31", "tomas rhee"},
      {"31", "no reply yet"},
      {"31", "add someone"}
    ]
  end

  @doc """
  Board 11's feed, as the drawing shows it: its heading and its three posters.

  The screen keeps no copy of it — a fresh install draws `empty_feed/0`, and a
  real one draws TMDB's picks — so the board's state lives here, with the
  tests that install it. The match line, the people, the leaving rail and the
  chips are not in it: the screen no longer draws them, and
  `retired_lines/0` holds their words.
  """
  def discover_board_feed do
    %{
      Kati.Screens.Discover.empty_feed()
      | because: "Because you watched The Long Hollow",
        empty_shelf?: false,
        picks: [
          %{title: "Vellum", seed: "vellum97"},
          %{title: "Quietus", seed: "quietus39"},
          %{title: "Quiet Harbour", seed: "harbour86"}
        ]
    }
  end

  @doc """
  Board 31's event, *Design review*, in the shape `Kati.Screens.EventDetail`
  draws: its two section chips, its five field rows and its clash.

  The screen keeps no copy of it (N51) — a push naming no stored event draws
  `Kati.Screens.EventDetail.missing/0` — so the board's state lives here, with
  the tests that install it. The id is a stand-in, so the page draws the Save
  pill and Delete the way it does over a stored event.

  N52-E: the three chevron rows draw no chevron and the invitees are not drawn
  at all — no screen exists for a row to open, and there is no attendee table
  for the card to read — so neither is in the shape any more; `retired_lines/0`
  holds their words.
  """
  def event_board do
    %{
      id: "board-31",
      title: "Design review",
      sections: [{"Personal", false}, {"Work", true}],
      fields: [
        %{
          icon: "schedule",
          title: "Thu 20 Aug",
          sub: "09:30 – 10:30",
          trailing: {:value, "1h"}
        },
        %{
          icon: "public",
          title: "Timezone",
          sub: "Europe/London · follows travel",
          trailing: {:switch, true}
        },
        %{icon: "repeat", title: "Repeats", sub: "Every 2 weeks on Thursday", trailing: nil},
        %{
          icon: "notifications",
          title: "Alerts",
          sub: "1 hour before · at start",
          trailing: nil
        },
        %{icon: "place", title: "Location", sub: "Studio B, or a link", trailing: nil}
      ],
      clash: %{
        line: "Overlaps Standup by 15 min",
        actions: [
          {"Shift 15m later", :primary},
          {"Shorten to 45m", :primary},
          {"Keep both", :quiet}
        ]
      }
    }
  end

  @doc """
  Board 25's banner, `Watching 24 titles · 3 FOUND THIS WEEK`, said through
  the screen's own two sentences. The screen counts the reader's library and
  keeps no copy of the board's figures.
  """
  def watcher_board_banner do
    %{
      title: Kati.Screens.ReleaseWatcher.watching_line(%{followed: 24}),
      meta: Kati.Screens.ReleaseWatcher.found_line(%{out_now: [%{}, %{}, %{}]}),
      on: true
    }
  end

  @doc """
  Board 33's watch, *Blue Hour*, in the shape `Kati.Screens.Rating` draws.

  The screen keeps no copy of it (N52-B) — a push naming no title draws
  `Kati.Screens.Rating.nothing_to_log/0` — so the board lives here, with the
  test that installs it. No `live?`, so its controls stay pictures: nobody
  owns the watch. `characters` is the drawing's own 184, which
  disagrees with the body beside it; the drawing is what is being compared.
  """
  def rating_board do
    %{
      title: "Blue Hour",
      seed: "bluehour58",
      meta: "2025 · 1H 52M",
      rewatch: "2nd rewatch",
      rating: 4.5,
      rating_note: "HALF STARS ON · TAP LEFT OR RIGHT OF CENTRE",
      spoilers: "Spoilers hidden",
      review:
        "Second time through and the estuary scenes land completely differently once you know what Mara is looking for. The score does most of the work in the last reel.",
      characters: "184 characters",
      context: [
        %{icon: "event", title: "Watched on", sub: "Sun 16 Aug · 21:40"},
        %{icon: "tv", title: "Where", sub: "Lumen+ · living room"},
        %{icon: "group", title: "With", sub: "Jo"}
      ],
      tags: ["slow burn", "coastal", "rewatchable"]
    }
  end

  @doc """
  Board 144's live sheet, *S2 E6 · The Undertow* of *The Long Hollow*.

  The screen keeps no copy of it (N52-B) — a push naming no episode, over a
  store with none logged, draws `Kati.Screens.RateEpisode.empty_sheet/0`.
  """
  def rate_episode_board do
    %{
      headline: "S2 E6 · The Undertow",
      masked_headline: "S2 E6 · Episode 6",
      show_title: "The Long Hollow",
      spoiler_safe?: false,
      rewatch?: false,
      rating: 4.5,
      review: "",
      context: [
        %{
          key: :watched_on,
          icon: "event",
          title: "Watched on",
          sub: "Tonight · 21:40",
          trailing: "now"
        },
        %{key: :where, icon: "tv", title: "Where", sub: "Lumen+ · living room", trailing: nil},
        %{key: :with, icon: "group", title: "With", sub: "Jo", trailing: nil}
      ],
      previous: nil
    }
  end

  @doc """
  Board 149's show, *The Quiet Ones*, gone cold at S1 E3.

  The screen keeps no copy of it (N52-B) — a push naming no row draws
  `Kati.Screens.DropSheet.empty_sheet/0`. `tracked: nil` because nobody owns
  it, so the sheet's writes refuse over it.
  """
  def drop_board do
    %{
      tracked: nil,
      title: "The Quiet Ones",
      seed: "quietones12",
      cold_label: "GONE COLD · 4 MONTHS",
      kind: :tv,
      season: 1,
      episode: 3
    }
  end

  @doc """
  Board 36 as far as the screen can draw it: `3 sources`, `41 EPISODES TICKED
  FOR YOU`, *The Long Hollow* playing at 74%, the permission row, the
  threshold row and the Marram question.

  The screen keeps no copy of it (N52-B), and the board's rows no device can
  have — Apple TV, Chromecast, the browser extension, *Ask before ticking*,
  *Ignore* — are retired in `retired_lines/0` rather than installed.
  `access: :unavailable`, so none of it answers a tap.
  """
  def detect_board do
    %{
      sources_line: "3 sources",
      banner: %{
        title: "Detect what you play",
        meta: "41 EPISODES TICKED FOR YOU",
        on: true
      },
      now_playing: %{
        seed: "hollow71",
        title: "The Long Hollow",
        meta: "S2E6 · LUMEN+ · APPLE TV",
        status: "Live",
        progress: 0.74,
        elapsed: "41:02 / 55:00",
        rule: "ticks at 90%"
      },
      sources: [
        %{
          icon: "phone_iphone",
          title: "This phone",
          sub: "Detects audio from any app",
          control: :chevron,
          tap: :open_media_access
        }
      ],
      rules: [
        %{
          icon: "percent",
          title: "Tick at",
          sub: "90% watched",
          control: :chevron,
          tap: :cycle_threshold
        }
      ],
      decision: %{
        seed: "marram15",
        question: "“Marram E3” or “Marram Grass”?",
        sub: "Played 43m on Orbit, 21:10",
        options: [
          {"The series", :answer_the_series},
          {"The film", :answer_the_film},
          {"Neither", :answer_neither}
        ],
        chosen: "The series"
      },
      access: :unavailable
    }
  end
end
