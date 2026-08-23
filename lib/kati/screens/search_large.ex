defmodule Kati.Screens.SearchLarge do
  @moduledoc """
  Screen 91 — search at 235% Dynamic Type, a reference sheet pushed under
  Settings.

  Screen 86 is the field before you type and screen 19 is the field mid-query.
  This is that second screen at the largest text size Android offers, drawn once
  so the claim *nothing on a result clips* can be checked by looking rather than
  asserted — a sheet in screen 27's manner, and a specimen in screen 41's.

  ## The row becomes a card, and `max_lines` is what it costs to stay a row

  `Kati.Screens.Search.title_row/1` is a `Row`: thumbnail, then a `Column`
  holding the title and its meta line, then a chevron — with `max_lines={1}` on
  both text nodes. That pair of ones **is** the row. A horizontal band of fixed
  height can only hold a title that outgrows it by cutting the title, so at 235%
  the row does not survive; it just stops showing the words.

  So the hit stacks: thumbnail above, title under it, meta line under that, and
  the chevron on an action line of its own behind a rule. Nothing in
  `hit/1` carries a `max_lines` at all — the title takes as many lines as it
  needs, the card grows downward, and a `Scroll` absorbs the growth that a row
  could not. It is the same trade screen 41 makes for the Up next card, applied
  to the one place it matters most: a search result is the answer to a question
  the user typed.

  ## What is 86's, and the one builder of 86's this board exists to contradict

  Everything the two screens draw the same way is 86's call, made here:
  `Kati.UI.SettingsList.chrome/2` for the strip the back pill floats in,
  `Kati.Search.chip_labels/0` for the scopes and their fixed order,
  `Kati.UI.eyebrow/2`, `Kati.UI.symbol/2` for all four glyphs, and
  `Kati.UI.SettingsList.note/2` for the footnote — which is exactly what
  `Kati.Screens.SearchIdle.counts_note/0` is, one sentence further down.

  The exception is `Kati.Screens.SearchIdle.chips/1`, a `<Scroll
  axis="horizontal">`. That is the builder this board exists to contradict, so
  it is the one thing 86 has that is not called here. At this size a horizontal
  scroll hides half the scopes behind a gesture, and a scope you cannot see is a
  scope you do not know you can search.

  ## The chips wrap, and the wrap is declared rather than measured

  A `Row` does not wrap, so the wrap is chunked in Elixir at three chips a row
  (`chips/0`), which is what the drawing's `flex-wrap` produces at these widths.
  A declared chunk is only safe while the chips cannot outgrow the width the
  chunk assumed — which is the other half of this screen, below.

  ## What K-29 caps here, and what it deliberately does not

  `max_font_scale` (fence `K-29`, `MobBridge.kt`) provides a subtree a
  `LocalDensity` whose `fontScale` is clamped, leaving `density` untouched, so a
  capped label keeps its own padding and corner radii. `dp` does not move; only
  `sp` does. The rule for where it goes is
  `Kati.Screens.Calendar.day_strip/1`'s, and this board is the search-shaped
  instance of it:

    * **Content grows.** The two hits and the footnote carry no cap. They are
      what the sheet is demonstrating, they hold no fixed height and no
      `max_lines`, and every extra line they take is a line the scroll can
      absorb.
    * **Chrome whose size carries structure caps instead.** The field is a 62pt
      stadium and the chips are 40pt pills; growing either does not make them
      more readable, it makes the field stop being one line and the chip rows
      stop fitting across 360pt. `Row` clips what it cannot fit, so an uncapped
      chip label is the only thing on this page that can actually be lost.

  `cap/0` is **1.0**, and it means *this subtree has already been scaled once*.
  Every size on this screen is the drawing's 235% size, typed out — a specimen
  has to render at the size it documents or there is nothing to look at, which
  is the choice screen 41 made and defends. A device that is itself at 235%
  would otherwise apply the factor a second time and land at 552%. At an
  ordinary 100% the cap costs nothing: the bridge overrides `LocalDensity` only
  when `density.fontScale > cap`.

  ## Eight chips, where the board draws six

  The drawing wraps `All · Screen · Books` over `Music · Calendar · Notes` and
  leaves **Meals** and **Money** out. Screens 89 and 90 draw all eight of
  `Kati.Search.chip_labels/0` for this same query with these same counts, so the
  two absentees are the board running out of room and not a scope being
  withdrawn. They are drawn here, on a third row.

  Cutting two scopes at 235% would be the board's own objection to the
  horizontal scroll made worse: a gesture at least gets you to a hidden scope,
  and this reader is the one least able to go looking for it.

  ## Nothing here reads a store, and nothing here taps

  Screen 67's paragraph applies unchanged, and `Kati.Screens.Search`'s own
  blocker is the reason: **there is no index**. No action anywhere matches a
  title, an episode or a note by substring, so `the long hollow estuary`, the
  eight counts and the two hits are typed. They are typed *here* rather than in
  a `Sample` module because they are this sheet's specimen — one query at one
  text size — and not a stand-in for data that is nearly ready.

  So no control carries a tap:

    * **The chips are labels rather than controls**, which is a state
      `Kati.UI.chip/2` already names — a chip with no `on_toggle`. Narrowing is
      the one thing they could honestly do and there is nothing to narrow: the
      counts say Books 1 and Notes 2, this sheet draws neither group, and a tap
      on Books that left `SCREEN · 3` standing would be a page contradicting its
      own chip.
    * **`Open` and the `cancel` disc are drawn rather than wired.** Kati has no
      episode screen for the second hit to open, and the field has nothing to
      clear — Mob has no text input (#45), so the query is a string in this file
      and the disc would be a button that empties nothing.

  `Kati.Screens.Pushed` defines no `handle_tap/2` on purpose, so none of them
  reports a dead tag.

  ## Two things the board draws that this file cannot

    * **`Hollow` and `Estuary` are one weight step above their titles.**
      `Kati.UI.rich_text/1` records why that is not drawable: `MobText` reads
      `text` as a plain `String` and hands it to Compose with one `fontWeight`,
      and there is no `AnnotatedString` anywhere in the bridge. Screen 19 buys
      its highlight by splitting the sentence across a `Row` of runs, which
      works on one line and is exactly what a three-line title cannot do. The
      board's own sentence settles which half to keep: *a search result that
      clips the searched word has failed at its one job*. The runs still go in
      as runs, so the emphasis appears the day `MobText` takes a `runs` prop and
      no call site here changes.
    * **The back pill.** The drawing grows it to 56pt with a 19pt label;
      `Kati.Screens.Pushed.back_pill/1` is 44 with a 13.5 and no cap, and at a
      real 235% that label wants 31.7sp inside a fixed 44pt pill. That is the
      one clipping this board documents and this file must not fix: the pill is
      shared by some sixty screens and the answer is one number in
      `Kati.Screens.Pushed`, once. `SettingsList.chrome(nil, 44)` — 86's own
      call — reserves what the pill actually occupies rather than what the
      drawing wishes it did.

  The pill says **Home**, which is what the board says, and that is deliberate
  rather than inherited: this is a picture of the screen a user reaches from
  Home, at a system text size — so the pill names where the *screen* came from
  rather than where the *board* is filed. Screen 67 makes the opposite choice
  because it is a states sheet about a pushed page; this one is the page.

  No dock, so the frame closes at 40 rather than 132.
  """

  use Kati.Screens.Pushed, back: "Home"

  alias Kati.Components.MishkaSeparator
  alias Kati.Search
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  # The query the drawing is mid-way through, and the eight counts it produced.
  # Screen 90 — the Persian twin of this board — carries the same eight, which
  # is how the two chips this board omits were recovered. `All` is the sum of
  # the seven, and the sum is checked by eye rather than derived, for the reason
  # `Kati.Screens.Search.Sample.chips/0` gives: a chip counts what the query
  # matched across the whole result set, not what the page has room to draw.
  @query "the long hollow estuary"

  @counts [
    {"All", 6},
    {"Screen", 3},
    {"Books", 1},
    {"Music", 0},
    {"Calendar", 0},
    {"Meals", 0},
    {"Money", 0},
    {"Notes", 2}
  ]

  # `lead`/`match`/`tail` follows `Kati.Screens.Search.Sample.note/0`: the
  # matched word is carried apart from the words either side of it so the
  # emphasis is recorded even while the bridge cannot paint it. See `title/1`.
  @hits [
    %{
      lead: "The Long ",
      match: "Hollow",
      tail: "",
      sub: "Series · Season 2 · watching",
      seed: "hollow71"
    },
    %{
      lead: "What the Tide Left in the ",
      match: "Estuary",
      tail: " at Low Water",
      sub: "Episode · S2E4 · watched 30 Jul",
      seed: "hollow71"
    }
  ]

  @footnote "Rows become stacks, the chip row wraps rather than scrolls, and the long title " <>
              "wraps to three lines with Estuary still emphasised. A search result that clips " <>
              "the searched word has failed at its one job."

  @doc """
  The sheet, top to bottom: field, chips, one group, footnote.

  The eyebrow's number is read from the same `@counts` the chips are built from,
  so the heading and the Screen chip cannot drift apart — `SCREEN · 3` over two
  drawn cards is the drawing's own arithmetic, and screen 19 explains it: a chip
  counts the result set, a group shows what fits.
  """
  @spec content(map()) :: map()
  def content(_assigns) do
    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {SettingsList.chrome(nil, 44)}
        {Kati.Screens.SearchLarge.field()}
        {Kati.Screens.SearchLarge.chips()}
        {Kati.UI.eyebrow(Kati.Screens.SearchLarge.group_label())}
        {Kati.Screens.SearchLarge.hits()}
        {Kati.Screens.SearchLarge.footnote()}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The ceiling on how far the chrome may grow, as a `fontScale`.

  1.0, because every `sp` on this screen is already the drawing's 235% size —
  see the moduledoc. It reads as "do not scale this twice" rather than "do not
  scale this", and it is inert on a device at ordinary size: fence K-29
  overrides `LocalDensity` only where `density.fontScale > cap`.
  """
  @spec cap() :: float()
  def cap, do: 1.0

  @doc """
  The heading over the one group this sheet draws.

  Built from `@counts` rather than typed, so the chip and the eyebrow are one
  number in two places and a change to the specimen cannot leave them
  disagreeing about how much the query matched.
  """
  @spec group_label() :: String.t()
  def group_label, do: "Screen · " <> Integer.to_string(count("Screen"))

  @doc """
  The field mid-query: ink ring, the query, the caret, the clear disc.

  Capped, and this is the loosest cap on the page to argue for, because the
  query is the user's own words sitting in a control. It is capped anyway: the
  field is a 62pt stadium holding one line, so growth does not wrap it, it
  clips it — and the drawing keeps the field a row even while it turns the
  results into cards.

  The 2pt ring is a `border`, not a shadow layer, and the remaining
  `0 8 18 -14 #991A1917` is written out rather than taken from
  `Kati.Theme.shadow_search/0`: the focused field is darker than the resting one
  and carries no near-layer. It is the string `Kati.Screens.Search.field/1`
  writes, so the two focused fields in this app stay one field.
  """
  @spec field() :: map()
  def field do
    ~MOB"""
    <Column fill_width={true} max_font_scale={Kati.Screens.SearchLarge.cap()}>
      <Row
        fill_width={true}
        height={62}
        corner_radius={26}
        background={Palette.card()}
        border_width={2}
        border_color={Palette.ink()}
        shadow="0 8 18 -14 #991A1917"
        padding_left={18}
        padding_right={18}
        align="center"
      >
        {UI.symbol("search", size: 24)}
        <Spacer size={11} />
        <Text
          text={Kati.Screens.SearchLarge.query()}
          text_size={20}
          font_weight="medium"
          text_color={:on_surface}
          max_lines={1}
        />
        <Spacer size={3} />
        <Box width={2} height={24} background={Palette.accent()} />
        <Spacer weight={1.0} />
        {UI.symbol("cancel", size: 19, color: Palette.rail_idle(), fill: true)}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc "The query the sheet is drawn mid-way through. Typed — there is no index."
  @spec query() :: String.t()
  def query, do: @query

  @doc """
  All eight scopes, three to a row, capped.

  `Kati.Search.chip_labels/0` gives the order and it is not this screen's to
  change — the board's own rule is that a user learns where to look. So the
  chunk is positional and the rows fall out as three, three and two.

  Three is measured rather than chosen: the widest row is
  `Music · Calendar · Meals` at about 330 of the 360pt the frame leaves, and
  that measurement only holds because `cap/0` stops the labels growing past the
  size it was taken at. Chunking and capping are one decision here, not two.
  """
  @spec chips() :: map()
  def chips do
    rows =
      Search.chip_labels()
      |> Enum.chunk_every(3)
      |> Enum.map(&Kati.Screens.SearchLarge.chip_row/1)
      |> Enum.intersperse(~MOB"<Spacer size={8} />")

    ~MOB"""
    <Column fill_width={true} max_font_scale={Kati.Screens.SearchLarge.cap()}>
      {rows}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc "One row of the wrapped chip block, at the drawing's 8pt gap."
  @spec chip_row([String.t()]) :: map()
  def chip_row(labels) do
    chips =
      labels
      |> Enum.map(&Kati.Screens.SearchLarge.chip/1)
      |> Enum.intersperse(~MOB"<Spacer size={8} />")

    ~MOB"""
    <Row fill_width={true} align="center">
      {chips}
    </Row>
    """
  end

  @doc """
  One counted scope chip, hand-rolled rather than `Kati.UI.chip/2`.

  Two things rule the shared pill out and both are geometry the drawing has at
  this size and not at any other:

    * `Kati.UI.chip/2` pins `height: 32`, `corner_radius: 16`, `padding_x: 15`
      and `text_size: 12`, and sets its count in 11pt **sans**. This board is a
      40pt pill with a 17pt label and a 14pt **mono** count.
    * `Kati.Components.MishkaChip` takes every one of those as a prop and still
      cannot draw this chip: it has no `shadow`, and an unselected chip here
      floats on `Kati.Theme.shadow_card_soft/0` like every other surface on the
      page. A chip row that was the one flat thing on a page of lifted cards
      would read as a rendering fault rather than as a control.

  The selected pill carries no shadow, which is the drawing's own: an ink fill
  is the page's darkest surface and does not need lifting off it.

  A zero count is `rail_idle` where a real one is `muted` — the drawing quiets a
  scope that matched nothing without hiding it, which is the same argument as
  drawing Meals and Money at all.
  """
  @spec chip(String.t()) :: map()
  def chip(label) do
    count = count(label)
    on? = label == "All"

    background = if on?, do: Palette.ink_fill(), else: Palette.card()
    ink = if on?, do: Palette.on_ink(), else: Palette.ink_soft()
    # `nil` rather than a zeroed shadow string. The key survives on the node and
    # reaches the bridge as the serialised `"nil"`, where `shadowLayers/1`
    # splits it on `|`, gets one field where five are required, drops it in
    # `mapNotNull` and returns null from `layers.ifEmpty` — the same nothing an
    # absent key paints. `Kati.Screens.Accessibility.disc/2` documents both
    # paths; the component form that omits the key outright is not open to a
    # hand-rolled Row.
    shadow = if on?, do: nil, else: Kati.Theme.shadow_card_soft()

    count_ink =
      cond do
        # `on_ink_count_soft` is the palette's `#FBFAF8` at 65%, which is the
        # alpha the drawing writes on the filled chip. `on_ink_count` is 60%.
        on? -> Palette.on_ink_count_soft()
        count == 0 -> Palette.rail_idle()
        true -> Palette.muted()
      end

    ~MOB"""
    <Row
      height={40}
      corner_radius={20}
      background={background}
      shadow={shadow}
      padding_left={17}
      padding_right={17}
      align="center"
    >
      <Text text={label} text_size={17} font_weight="semibold" text_color={ink} max_lines={1} />
      <Spacer size={8} />
      <Text
        text={Integer.to_string(count)}
        font_family="mono"
        text_size={14}
        text_color={count_ink}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc "The two Screen hits, at the drawing's 12pt gap."
  @spec hits() :: map()
  def hits do
    cards =
      @hits
      |> Enum.map(&Kati.Screens.SearchLarge.hit/1)
      |> Enum.intersperse(~MOB"<Spacer size={12} />")

    ~MOB"""
    <Column fill_width={true}>
      {cards}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  One hit as a card: poster, title, meta, then an action line behind a rule.

  There is no `max_lines` in here and no fixed height on anything but the
  poster, which is a shape. That absence is the whole screen — see the
  moduledoc. The card grows downward and the `Scroll` takes it.

  The action line is what became of screen 19's trailing chevron. A chevron
  alone at this size is a 22pt glyph adrift at the end of a 90pt column, so the
  drawing gives it the word `Open` and a rule to sit under, which also puts a
  label on the one part of the row that had none.
  """
  @spec hit(map()) :: map()
  def hit(hit) do
    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={22}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={16}
    >
      {Kati.Screens.SearchLarge.thumb(hit)}
      <Spacer size={14} />
      {Kati.Screens.SearchLarge.title(hit)}
      <Spacer size={9} />
      <Text text={hit.sub} text_size={17} line_height={1.4} text_color={Palette.muted()} />
      <Spacer size={14} />
      {MishkaSeparator.separator(color: Palette.hairline(), thickness: 1, render: :box)}
      <Spacer size={13} />
      {Kati.Screens.SearchLarge.action()}
    </Column>
    """
  end

  @doc """
  The title, with the matched word recorded as its own run.

  `Kati.UI.rich_text/1` concatenates the runs and applies one style, so the
  emphasis is dropped and the title stays a single `Text` — the only node that
  wraps. Splitting it across a `Row` the way screen 19 splits its note would
  keep the bold and cost the wrap, and this title needs three lines.

  Handing the words over as runs rather than as one pre-joined string is not
  ceremony: `rich_text/1`'s own doc describes the `runs` prop that would make
  the emphasis real, and when it lands every call here already says which word
  matched.

  `base: true` marks the body run explicitly. The first hit's title is short
  enough — `The Long ` against `Hollow` — that editing it could otherwise flip
  the longest-run choice onto the emphasis and set the whole line in bold.
  """
  @spec title(map()) :: map()
  def title(hit) do
    body = [
      text_size: 22,
      line_height: 1.35,
      font_weight: "semibold",
      text_color: :on_surface
    ]

    [{hit.lead, [base: true] ++ body}, {hit.match, :bold}, {hit.tail, body}]
    |> Enum.reject(fn {text, _style} -> text == "" end)
    |> UI.rich_text()
  end

  @doc """
  The 64x90 poster, or the placeholder for a seed that was never exported.

  Fixed, and it stays fixed however large the text gets: a 2:3 tile is a shape,
  which is `Kati.DynamicTypeTest`'s own rule for telling a shape from a
  measurement of text.
  """
  @spec thumb(map()) :: map()
  def thumb(hit) do
    case Kati.Design.Images.poster(hit.seed) do
      nil ->
        ~MOB"<Box width={64} height={90} corner_radius={9} background={Palette.placeholder()} />"

      src ->
        ~MOB"""
        <Image src={src} width={64} height={90} corner_radius={9} content_mode="fill" />
        """
    end
  end

  @doc """
  The card's action line: `Open`, then the chevron it used to be.

  `weight={1.0}` on the label rather than a trailing `Spacer`, so the chevron
  keeps the right edge and the word keeps everything else — including the room
  to take a second line, which is why it carries no `max_lines` either.
  """
  @spec action() :: map()
  def action do
    ~MOB"""
    <Row fill_width={true} align="center">
      <Text
        text="Open"
        text_size={17}
        font_weight="semibold"
        text_color={Palette.sub()}
        weight={1.0}
      />
      <Spacer size={8} />
      {UI.symbol("chevron_right", size: 22, color: Palette.rail_idle())}
    </Row>
    """
  end

  @doc """
  The footnote, in `Kati.UI.SettingsList.note/2`'s frame.

  The shared note is the right frame down to the number: an `info` glyph on the
  first line, an 18pt radius, 16 of padding and the drawing's 1.5pt border at
  16% ink. It is solid where the board is dashed, and that gap is recorded on
  `note/2` itself rather than restated here.

  It takes no cap. This is body copy — it wraps, it has nowhere to clip, and it
  is the one block on the page that should keep growing when the reader asks
  for more.
  """
  @spec footnote() :: map()
  def footnote, do: SettingsList.note("info", @footnote)

  # The specimen's count for one scope. A miss is 0 rather than a raise: a
  # ninth scope in `Kati.Search` should draw a chip that says nothing matched,
  # not take the screen down.
  defp count(label) do
    case List.keyfind(@counts, label, 0) do
      {^label, count} -> count
      nil -> 0
    end
  end
end
