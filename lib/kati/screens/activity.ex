defmodule Kati.Screens.Activity do
  @moduledoc """
  Screen 15 — Activity, pushed under Stats.

  Built to `test/design/screens/15.html`. An append-only history — every
  tick, rating, drop and import — grouped by when it happened, with the
  per-episode rewatch counts underneath. The drawing's own note calls it the
  undo trail: *nothing in the app deletes silently*, so nothing here is a
  summary, every line is an event.

  Three things the drawing is specific about and this file follows literally:

    * **Two stamps, one gutter.** Today's rows carry a `21:12` clock at mono
      11; Earlier this month's carry `12 AUG` at mono 10 with `.06em`. Both
      sit in a 44pt column, which is what screen 19's calendar rows already
      give the same stamp. Sizing each card's gutter to its own stamp is the
      tempting move and the wrong one — the export's own 38 both truncated the
      date to `12 A…` and stepped the two cards' thumbnails out of line with
      each other. The 6 the column borrowed is given back out of the gap after
      it, so `stamp column + gap` is the drawing's 50 either way and everything
      right of the stamp sits where the export puts it — see `entry_row/5`.
    * **The second eyebrow is grey.** "Earlier this month" gets a `#C4BDB3`
      dash, not the accent — see `Kati.UI.Eyebrow`. Last month is neither new
      nor now.
    * **The verb is a separate run.** `Watched`, `Rated`, `Dropped` are bold
      ink inside a `#5C574F` line, and one `Text` carries one weight. The 2
      between the runs is the word space that split them, not a gap between
      two things — at 4 the line read as two phrases.

  The rating row is written `Blue Hour ★★★★` in the export. U+2605 is not in
  Plus Jakarta Sans — screen 08 discovered that by rendering an empty rating
  card — so the stars are Material Symbols `star` glyphs at the line's own
  size and colour. The checker therefore reports that one line as missing; it
  is a glyph, not a word.

  ## The chips filter the log, and a filter can empty a day

  `All` is the resting state and shows every row, which is what `15.html`
  draws. The other three name a verb, and the verb is what the row stores in
  `lead`, so the chip filters on that and nothing else.

  A filter that leaves a dated group with no rows takes the group's **eyebrow
  with it** — `Rated` and `Added` have nothing in Earlier this month, and a
  headed card with no rows inside it is a worse answer than no card. The
  rewatch count is not part of the log and is never filtered.

  No dock on a pushed screen, so the frame ends at 40 rather than 132.

  ## The log is `Kati.Media.Watch`, and only `Kati.Media.Watch`

  That resource's own moduledoc names this screen — it is why `media_watches`
  carries a bare `watched_at` index, *"screen 15's activity log across every
  title"* — so the rows here are read through the domain rather than off
  `Kati.Activity.Sample`. One `Ash.read!` of the user's watches, joined to the
  title they belong to and to whatever the cache still holds about it, shaped
  into the same `%{stamp, seed, lead, rest, stars}` the sample produced. The
  shaping is in this file rather than a read model beside the resource because
  every judgement in it — which verb a row gets, where the stamp changes from a
  clock to a date — is a statement about *this drawing* and belongs next to the
  markup that draws it.

  **An empty database still draws the drawing.** `log/0` falls back to
  `drawn/0` — the sample verbatim — the way `Kati.Screens.Home.rest_of_today/1`
  and `Kati.Screens.Calendar.day_rows/1` already do, because this screen is
  also the reference the frame is compared against and a fresh install has no
  watches. The gate is the whole screen, not each group: a log with rows today
  and none earlier shows its real emptiness rather than borrowing four drawn
  rows from last month.

  ### What `Kati.Media.Watch` cannot say yet

  The drawing's log is *"every tick, rating, drop and import"* and `Watch` is
  the ticks and the ratings. `Added … to Wishlist`, `Finished … Season 1`,
  `Dropped … after S1E3` and `Imported 412 titles from a CSV backup` are the
  other four rows the sample carries, and none of them has a store: a status
  moving from `:watching` to `:dropped` overwrites a column on
  `Kati.Media.TrackedTitle` and leaves nothing behind, there is no list
  resource for a wishlist to be added to, and no import ever records that it
  ran. So the `Added` chip finds nothing in a real log. That is a missing
  resource, not a missing query: a `media_events` append-only table, or a
  status-change row beside `Kati.Media.TrackedTitle`, is what those four verbs
  need, and inventing a column from a screen would be the wrong end to build it
  from. Until it exists the drawn rows carry them, which is why
  `Kati.Activity.Sample` stays.
  """
  use Kati.Screens.Pushed, back: "Stats"

  require Ash.Query

  alias Kati.Activity.Sample
  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaChip
  alias Kati.Components.MishkaSeparator
  alias Kati.Media.CachedTitle
  alias Kati.Media.Watch
  alias Kati.Theme.Palette
  alias Kati.UI

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, filter: "All", log: log())

  @doc false
  def content(assigns) do
    filter = assigns.filter
    log = assigns.log
    today = visible(log.today, filter)
    earlier = visible(log.earlier, filter)

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {Kati.Screens.Activity.back_gap()}
        {Kati.Screens.Activity.header(log.entries_line)}
        {Kati.Screens.Activity.filters(filter)}
        {Kati.Screens.Activity.group(today, UI.eyebrow("Today"), 44, 11, 0.0)}
        {Kati.Screens.Activity.group(earlier, Kati.UI.Eyebrow.quiet("Earlier this month"), 44, 10, 0.06)}
        {Kati.Screens.Activity.rewatch_section(log.rewatch)}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The log this screen draws — the user's own, or the drawing's.

  Real rows whenever there are any, and `drawn/0` when there are none, which
  is the rule `Kati.Screens.Calendar.day_rows/1` states: *missing data is not
  a reason for a blank screen*. The two dated groups are what the gate reads,
  not the rewatch card — a user whose every watch is older than this month has
  an empty log and a real rewatch tally, and showing the drawing's four rows
  beside their own counts would be two different months in one frame.

  A database that cannot be read at all draws the drawing too. `Ash.read!` on
  a device mid-migration raises, and a screen that dies is strictly worse than
  a screen showing the values it was drawn from; the tests below fail loudly
  on a query that is merely wrong, because they assert the real strings.
  """
  @spec log() :: map()
  def log do
    case entries() do
      %{today: [], earlier: []} -> drawn()
      log -> log
    end
  rescue
    _ -> drawn()
  end

  @doc """
  The drawing's own log — `test/design/screens/15.html`, verbatim.

  `Kati.Activity.Sample` is kept rather than inlined here: it is the frame's
  specification and the fixture the tests compare a real render against, and
  two copies of the drawing's copy is exactly how the two drift apart.
  """
  @spec drawn() :: map()
  def drawn do
    %{
      entries_line: Sample.entries_line(),
      today: Sample.today(),
      earlier: Sample.earlier(),
      rewatch: Sample.rewatch()
    }
  end

  @doc """
  Every watch the user has recorded, shaped into the drawing's rows.

  One read of `Kati.Media.Watch` rather than one per group. The screen needs
  the whole history anyway — the header counts it and the rewatch card groups
  it — and three filtered queries that must agree about what "this month"
  means is three chances to disagree.

  Stamps are the precision the row actually has. `watched_at` is an instant, so
  it yields the local clock Today's gutter draws; `watched_on` is a date, and
  `Kati.Media.Watch` is explicit that the two are separate because *"watched on
  12 August" is date-valued*. A date-only watch therefore cannot appear in
  Today, whose gutter is a clock — it is the row that says "I have seen this, I
  do not remember when", and giving it a manufactured 00:00 would be the same
  lie as `Kati.Media.Release` refusing to turn a bare year into 1 January.

  `today` is an argument for the same reason `Kati.Calendars.Today.rows/1`
  takes one: the two groups are *"today"* and *"earlier this month"*, and a
  function that reads the clock itself can only be tested on the day the
  fixtures were written for — or, worse, only on the days of the month where
  "earlier this month" is a non-empty range at all.
  """
  @spec entries(Date.t()) :: map()
  def entries(today \\ Kati.Time.today()) do
    zone = Kati.Time.device_zone()
    month = Date.beginning_of_month(today)

    watches = watches()
    cached = cached_by_reference(watches)

    dated =
      watches
      |> Enum.map(&stamped(&1, zone))
      |> Enum.reject(fn {date, _clock, _watch} -> is_nil(date) end)
      |> Enum.sort_by(fn {date, clock, watch} ->
        {Date.to_erl(date), clock || "", watch.id}
      end)
      |> Enum.reverse()

    %{
      entries_line: entries_line(length(watches)),
      today:
        for {date, clock, watch} <- dated, date == today, not is_nil(clock) do
          row(watch, clock, cached)
        end,
      earlier:
        for {date, _clock, watch} <- dated,
            Date.compare(date, month) != :lt,
            Date.compare(date, today) == :lt do
          row(watch, date_stamp(date), cached)
        end,
      rewatch: rewatch_counts(watches, cached)
    }
  end

  @doc """
  The rows a chip leaves visible.

  The chip names a verb and the row keeps its verb in `lead`, so the match is
  on `lead` alone. It is a *contains*, not an equality, and that is the one
  judgement here: `Watched` keeps `Rewatched` too, because a rewatch is a
  watch — the rewatch count at the bottom of this screen already counts it as
  one.
  """
  @spec visible([map()], String.t()) :: [map()]
  def visible(rows, "All"), do: rows

  def visible(rows, filter) do
    verb = String.downcase(filter)
    Enum.filter(rows, fn row -> String.contains?(String.downcase(row.lead), verb) end)
  end

  @doc """
  One dated group — its eyebrow and its card — or nothing at all.

  Returning a list rather than a wrapper `Column` is deliberate: the sigil
  flattens an interpolated list into its parent, so an empty group leaves no
  node behind and the groups that remain keep the exact spacing they had.
  """
  @spec group([map()], map(), pos_integer(), number(), number()) :: [map()]
  def group([], _eyebrow, _stamp_width, _stamp_size, _stamp_spacing), do: []

  def group(rows, eyebrow, stamp_width, stamp_size, stamp_spacing) do
    [eyebrow, entries(rows, stamp_width, stamp_size, stamp_spacing)]
  end

  # `Kati.Screens.Pushed` floats the back pill over the content, so the content
  # has to leave room for it: the drawing's pill is 42 tall with a 16 gap under
  # it, which puts the title at 122 from the top exactly as the export does.
  @doc false
  def back_gap, do: ~MOB"<Spacer size={58} />"

  @doc false
  def header(entries_line) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column weight={1.0}>
          <Text
            text="Activity"
            text_size={28}
            max_font_scale={1.6}
            font_weight="bold"
            letter_spacing={-0.03}
            text_color={:on_surface}
          />
          <Spacer size={5} />
          <Text
            text={entries_line}
            font_family="mono"
            text_size={11}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
        {Kati.Screens.Activity.disc("search", :open_search)}
        <Spacer size={9} />
        {Kati.Screens.Activity.disc("tune", :open_filters)}
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  A 44pt round tap target holding one glyph — `Kati.Components.MishkaActionIcon`.

  Hand-rolled until the port grew a `shadow`, and that prop is the whole reason
  it can move now: a floating disc is *defined* by the lift under it, and
  `variant: :filled` paints a fill and stops. Without the shadow the port drew
  a flat #FBFAF8 patch on #EFECE7 paper — a 4%-different rectangle, which is
  worse than not adopting.

  **The pixels are the same node.** The port builds
  `<Box width={44} height={44} align={:center} corner_radius={22.0}
  background shadow on_tap>` — the same seven props this wrote by hand, with
  `shape: :circle` resolving to an exact `size / 2` where the markup said 22,
  and `align={:center}` where it said `align="center"` (both serialise to the
  string the bridge matches on). The one structural difference is the `<Row>`
  the port wraps children in; a `Row` with no props hugs its single child and
  centres it vertically, so the glyph measures and lands exactly where it did.
  """
  def disc(icon, tag) do
    MishkaActionIcon.action_icon(
      [
        size: 44,
        shape: :circle,
        variant: :filled,
        background: Palette.card(),
        shadow: Kati.Theme.shadow_button(),
        on_tap: {self(), tag}
      ],
      [Kati.UI.symbol(icon, size: 21)]
    )
  end

  # Four chips at 7pt gaps measure ~285 inside the 360 the gutters leave, so
  # unlike screen 03's counted chips these do not need a horizontal Scroll.
  @doc false
  def filters(active) do
    chips =
      Sample.filters()
      |> Enum.map(fn label -> filter_chip(label, label == active) end)
      |> Enum.intersperse(chip_gap())

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {chips}
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def chip_gap, do: ~MOB"<Spacer size={7} />"

  @doc """
  One filter chip — `Kati.Components.MishkaChip`.

  A chip that carries a `checked` state and toggles is the whole of what that
  component is, and this is the first round where it can be *this* chip: the
  port used to hardcode its size, its radius, its type and both unchecked
  colours, so a 32pt pill with a 12.5 semibold label on Kati's own two greys
  could not be expressed. `height`, `padding_x`/`padding_y`, `corner_radius`,
  `text_size`, `font_weight`, `max_lines`, `unchecked_color` and
  `unchecked_text_color` are all props now, and this passes every one.

  **Why the pixels do not move.** The chip was a `Row`; the port builds a
  `Box`. Both hug — a `Row` by nature, the `Box` because the port sends
  `fill_width={false}` and the bridge finally reads it (fence K-17) — and both
  run the same modifier chain: background on the rounded shape, then
  `padding(0, 14, 0, 14)`, then `height(32)`. Padding is applied before height
  on either node, so the chip measures 32 tall and `14 + label + 14` wide
  either way.

  Two prop-level differences, both inert:

    * `padding_y: 0` is written where the `Row` wrote nothing. The bridge
      resolves a missing edge to the uniform padding and a missing uniform to
      zero, so an absent top edge and an explicit `0` are the same number.
    * `align` moves from the `Row` to the `Box`. On a `Row` this bridge's
      default vertical alignment is already `CenterVertically`, so `align`
      was a no-op there; on a hugging `Box` it centres the label in the 32,
      which is the same position — `(32 - label height) / 2` from the top in
      both.
  """
  def filter_chip(label, on?) do
    # The tag carries the label, so one handler serves every chip and a fifth
    # verb is a change to `Kati.Activity.Sample.filters/0` alone.
    MishkaChip.chip(
      label: label,
      checked: on?,
      on_toggle: {self(), String.to_atom("filter_" <> label)},
      color: Palette.ink_fill(),
      text_color: Palette.on_ink(),
      unchecked_color: Palette.card(),
      unchecked_text_color: Palette.ink_soft(),
      height: 32,
      padding_x: 14,
      padding_y: 0,
      corner_radius: 16,
      text_size: 12.5,
      font_weight: :semibold,
      max_lines: 1
    )
  end

  @doc """
  One dated group as a single card of rows.

  `stamp_size` and `stamp_spacing` are the only difference between Today and
  Earlier this month, which is why they are parameters here rather than two
  near-identical functions. `stamp_width` is 44 from both callers — it stays
  an argument so the two calls state the shared gutter side by side, where a
  disagreement is visible.
  """
  def entries(rows, stamp_width, stamp_size, stamp_spacing) do
    last = length(rows) - 1

    children =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, i} ->
        entry_row(row, stamp_width, stamp_size, stamp_spacing, i < last)
      end)

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={15}
        padding_right={15}
        padding_top={4}
        padding_bottom={4}
      >
        {children}
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  # The line is a Box with a weight wrapping a Row, not a Row with a weight:
  # only a Box is guaranteed to take the weighted slot on this bridge, and the
  # two text runs have to sit side by side inside it. The trailing weighted
  # Spacer is what makes the unweighted Texts ellipsize instead of overflowing.
  #
  # The stamp's gap is 6, not the drawing's 12, and that is arithmetic rather
  # than taste: the export writes a 38pt stamp column and a 12pt gap, so the
  # thumbnail starts 50 in from the card's padding. Our column is 44 (see the
  # moduledoc — 38 ellipsised `12 AUG`), so the gap carries the other 6 and the
  # thumbnail lands exactly where the export draws it. A measured capture had
  # it 6.4dp right of the drawing before this. The whitespace either side of
  # the stamp is unchanged: the text is start-aligned in its column, so what
  # the eye reads as the gap is (column − text) + gap, which is 17 for `21:12`
  # in both the drawing and here.
  @doc false
  def entry_row(row, stamp_width, stamp_size, stamp_spacing, rule?) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={12} padding_bottom={12}>
        <Column width={stamp_width}>
          <Text
            text={row.stamp}
            font_family="mono"
            text_size={stamp_size}
            letter_spacing={stamp_spacing}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
        <Spacer size={6} />
        {Kati.Screens.Activity.thumb(row)}
        <Spacer size={12} />
        <Box weight={1.0}>
          <Row fill_width={true} align="center">
            <Text
              text={row.lead}
              text_size={12.5}
              font_weight="bold"
              text_color={:on_surface}
              max_lines={1}
            />
            <Spacer size={2} />
            <Text text={row.rest} text_size={12.5} text_color={Palette.ink_soft()} max_lines={1} />
            {Kati.Screens.Activity.stars(row[:stars])}
            <Spacer weight={1.0} />
          </Row>
        </Box>
      </Row>
      {Kati.Screens.Activity.hairline(rule?)}
    </Column>
    """
  end

  @doc false
  def thumb(row) do
    case Kati.Design.Images.poster(row.seed) do
      nil ->
        ~MOB"<Box width={26} height={37} corner_radius={5} background={Palette.placeholder()} />"

      src ->
        ~MOB"""
        <Image src={src} width={26} height={37} corner_radius={5} content_mode="fill" />
        """
    end
  end

  # The drawing writes four ★ characters straight into the line. Plus Jakarta
  # Sans has no U+2605, so those would render as nothing at all — screen 08's
  # empty rating card was exactly this bug. Material Symbols `star` at the
  # line's own size and colour is the same mark in a font that carries it.
  @doc false
  def stars(nil), do: ~MOB"<Spacer size={0} />"

  def stars(count) do
    star = Kati.UI.symbol("star", size: 11, color: Palette.ink_soft(), fill: true)
    glyphs = List.duplicate(star, count)

    ~MOB"""
    <Row align="center">
      <Spacer size={5} />
      {glyphs}
    </Row>
    """
  end

  @doc """
  The rewatch card and its eyebrow, or neither.

  Same shape as `group/5` and for the same reason: a user who has never
  rewatched anything has nothing to count, and an eyebrow over an empty card
  is the "headed card with no rows" this screen's own moduledoc rejects. A
  list rather than a wrapper, so the two nodes flatten into the page's Column
  exactly where they were written and the drawn frame is unchanged.
  """
  @spec rewatch_section([{String.t(), String.t()}]) :: [map()]
  def rewatch_section([]), do: []
  def rewatch_section(rows), do: [UI.eyebrow("Rewatch count"), rewatch(rows)]

  @doc false
  def rewatch(rows) do
    last = length(rows) - 1

    children =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {{name, count}, i} -> rewatch_row(name, count, i < last) end)

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={17}
    >
      {children}
    </Column>
    """
  end

  # Orange on the count is the design's own use of accent for "again, now" —
  # a rewatch is the one number on this screen that is still happening.
  @doc false
  def rewatch_row(name, count, gap?) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Text
          text={name}
          text_size={12.5}
          font_weight="semibold"
          text_color={:on_surface}
          max_lines={1}
        />
        <Spacer weight={1.0} />
        <Text
          text={count}
          font_family="mono"
          text_size={12}
          text_color={Palette.accent()}
          max_lines={1}
        />
      </Row>
      {Kati.Screens.Activity.row_gap(gap?)}
    </Column>
    """
  end

  @doc false
  def row_gap(false), do: ~MOB"<Spacer size={0} />"
  def row_gap(true), do: ~MOB"<Spacer size={12} />"

  @doc false
  def hairline(false), do: ~MOB"<Spacer size={0} />"
  # `MishkaSeparator` rather than a hand-rolled Box, and `render: :box` rather
  # than the component's `:divider` default.
  #
  # `:divider` is NOT the Box this used to be. The comment that stood here said
  # it was — that Compose's `HorizontalDivider` is
  # `Box(fillMaxWidth().height(t).background(color))` — and that is wrong:
  # Material3 draws it as `Canvas { drawLine(strokeWidth = t.toPx()) }`, an
  # ANTIALIASED stroke. At this device's 2.6875x a 1dp rule gets a 3px canvas
  # and a 2.6875px stroke centred in it, so the bottom pixel row lands at ~69%
  # coverage — a full-width row 4-5/255 lighter than the two above it. The
  # adoption softened the hairline by one pixel row and nothing said so.
  #
  # `render: :box` is the component's filled-rect primitive: `<Box fill_width
  # height={thickness} background={color}>`, which is the node that was written
  # here by hand before the adoption, so the rule goes back to three full-colour
  # rows. (Its `<Spacer size={1} />` child is an iOS height workaround — on
  # Android the Box's own `height` pins it and the background covers it.)
  #
  # `color` is passed rather than left to the component's `:border` default:
  # Kati's border token is 0x14000000 and the drawing's rule is 0x121A1917.
  def hairline(true),
    do: MishkaSeparator.separator(color: Palette.hairline(), thickness: 1, render: :box)

  @doc """
  The search disc, which drew and opened nothing.

  Screen 19 is where a query goes from everywhere else in the app — 03's disc,
  20's and 21's — and there is no second search to point this one at. It said
  *"the drawing gives neither a destination"*, which was true of the drawing
  and not of the app: 19 has existed the whole time and every other header disc
  already opened it.

  The filter disc stays on `Kati.ScreenTapSweepTest`'s backlog. No board in the
  165 draws an activity filter sheet, so it has nowhere to go that would not be
  invented here.
  """
  @impl true
  def handle_tap(:open_search, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Search)}

  # One clause for all four chips: the tag carries the label.
  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "filter_" <> label -> {:noreply, Mob.Socket.assign(socket, :filter, label)}
      _ -> {:noreply, socket}
    end
  end

  # ── The log, read through Kati.Media ───────────────────────────────────────

  # `tracked_title` is loaded rather than looked up per row: it carries the
  # {source, source_id} pair every other lookup here is keyed on, and a query
  # per row is what turns a 1,204-entry log into 1,204 statements.
  defp watches do
    Watch
    |> Ash.Query.load(:tracked_title)
    |> Ash.read!()
  end

  # The cache half, keyed by the VALUE PAIR the durable half references it by
  # — never by a foreign key, which is the split `Kati.Media.CachedTitle`
  # exists to protect. A missing entry is the evicted case and is normal: the
  # row still draws, without its title's artwork.
  defp cached_by_reference([]), do: %{}

  defp cached_by_reference(watches) do
    ids = watches |> Enum.map(& &1.tracked_title.source_id) |> Enum.uniq()

    CachedTitle
    |> Ash.Query.filter(source_id in ^ids)
    |> Ash.read!()
    |> Map.new(&{{&1.source, &1.source_id}, &1})
  end

  # {date, clock, watch}. See `entries/0` on why a date-only watch has no clock
  # and therefore never lands in Today.
  defp stamped(watch, zone) do
    cond do
      watch.watched_at ->
        local = Kati.Time.in_zone(watch.watched_at, zone)
        {DateTime.to_date(local), Calendar.strftime(local, "%H:%M"), watch}

      watch.watched_on ->
        {watch.watched_on, nil, watch}

      true ->
        {nil, nil, watch}
    end
  end

  # `12 AUG`, the gutter Earlier this month draws. `%d` pads, which is what
  # makes `07 AUG` and `12 AUG` line up in a 44pt mono column.
  defp date_stamp(date), do: date |> Calendar.strftime("%d %b") |> String.upcase()

  defp row(watch, stamp, cached) do
    tracked = watch.tracked_title
    named = named(title_of(tracked, cached), episode_label(watch))
    {lead, rest} = verb(watch, named)

    row = %{stamp: stamp, seed: seed_of(tracked, cached), lead: lead, rest: rest}

    # The key is absent rather than nil when there is no rating, because that is
    # what `Kati.Activity.Sample` produces and `entry_row/5` reads it with
    # `row[:stars]` — a rating of nothing and no rating are the same node, and
    # the two shapes have to be indistinguishable for the fallback to be one.
    case star_count(watch.rating) do
      nil -> row
      count -> Map.put(row, :stars, count)
    end
  end

  # Which verb a watch gets. Order matters: a rewatch that was also rated reads
  # as `Rated`, because the stars are the thing the row is showing and the chip
  # that finds it is the one the user pressed. `Watched` keeps `Rewatched` too
  # — see `visible/2`, which matches on containment for exactly this.
  defp verb(%{rating: rating}, named) when is_integer(rating), do: {"Rated", named}

  defp verb(%{rewatch_number: n}, named) when is_integer(n) and n > 1 do
    {"Rewatched", named <> " · " <> ordinal(n) <> " time"}
  end

  defp verb(_watch, named), do: {"Watched", named}

  defp named(title, nil), do: title
  defp named(title, label), do: title <> " " <> label

  # A label snapshot, never identity — `Kati.Media.Watch` is emphatic about
  # that, and this is the one place the snapshot is for: printing it.
  defp episode_label(%{season_number: s, episode_number: e})
       when is_integer(s) and is_integer(e),
       do: "S#{s}E#{e}"

  defp episode_label(%{season_number: s}) when is_integer(s), do: "S#{s}"
  defp episode_label(_watch), do: nil

  defp title_of(tracked, cached) do
    case Map.get(cached, {tracked.source, tracked.source_id}) do
      %{title: title} when is_binary(title) and title != "" -> title
      # The evicted case. The memory survived the wipe and the poster did not,
      # so the row says so rather than disappearing from the user's own history.
      _ -> "Untitled"
    end
  end

  # `Kati.Seeds` writes the design seed straight into `poster_path` — "not a
  # TMDB path: the sample artwork is resolved by seed" — and `sample_source_id/1`
  # is the other half of the same convention. Either answer is a seed
  # `Kati.Design.Images.poster/1` can miss harmlessly: `thumb/1` draws the
  # placeholder tile for a nil.
  defp seed_of(tracked, cached) do
    case Map.get(cached, {tracked.source, tracked.source_id}) do
      %{poster_path: path} when is_binary(path) and path != "" -> path
      _ -> Kati.Seeds.sample_seed(tracked.source_id)
    end
  end

  # Ten-point scale to whole glyphs: `9` is four and a half stars and this row
  # draws whole ones, so it draws four. `div/2` rather than `round/1` on
  # purpose — rounding 9 up to five would claim half a star the user did not
  # give. A 1 is half a star and no whole one, which is no glyphs at all, and
  # that is the absent key rather than an empty Row.
  defp star_count(rating) when is_integer(rating) do
    case div(rating, 2) do
      0 -> nil
      count -> count
    end
  end

  defp star_count(_rating), do: nil

  defp ordinal(n) do
    suffix =
      cond do
        rem(n, 100) in 11..13 -> "th"
        rem(n, 10) == 1 -> "st"
        rem(n, 10) == 2 -> "nd"
        rem(n, 10) == 3 -> "rd"
        true -> "th"
      end

    Integer.to_string(n) <> suffix
  end

  # "1,204 entries". Grouped by hand rather than through `Kati.Cldr` because
  # the drawing's line is ASCII digits and a locale switch would silently turn
  # it into Persian ones — the Persian mirrors are their own screens.
  defp entries_line(1), do: "1 entry"
  defp entries_line(n), do: delimited(n) <> " entries"

  defp delimited(n) do
    n
    |> Integer.to_string()
    |> String.reverse()
    |> String.graphemes()
    |> Enum.chunk_every(3)
    |> Enum.map_join(",", &Enum.join/1)
    |> String.reverse()
  end

  # What has been watched more than once, and how many times.
  #
  # Grouped by `{tracked_title_id, episode_source_id}` — the episode's own id,
  # which is what makes a tick survive a renumbering — so a film groups under
  # its `nil` episode and each episode counts on its own.
  defp rewatch_counts(watches, cached) do
    watches
    |> Enum.group_by(&{&1.tracked_title_id, &1.episode_source_id})
    |> Enum.map(fn {_key, rows} -> rewatch_entry(rows, cached) end)
    |> Enum.reject(&is_nil/1)
    |> Enum.sort_by(fn {label, times} -> {-times, label} end)
    |> Enum.map(fn {label, times} -> {label, "#{times}×"} end)
  end

  # `rewatch_number` is the user's own count and beats the row count, because
  # `Kati.Media.Watch` says it exists precisely for the history that predates
  # Kati: someone who saw a film twice before installing and once since has one
  # row saying "3rd", and counting rows would print 1×.
  defp rewatch_entry([first | _] = rows, cached) do
    claimed =
      rows
      |> Enum.map(& &1.rewatch_number)
      |> Enum.filter(&is_integer/1)
      |> Enum.max(fn -> 0 end)

    times = max(length(rows), claimed)

    if times > 1 do
      {named(title_of(first.tracked_title, cached), episode_label(first)), times}
    end
  end
end
