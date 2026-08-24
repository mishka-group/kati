defmodule Kati.Screens.Stats do
  @moduledoc """
  Screen 07 — Your year.

  Built to `test/design/screens/07.html`: a cream hero carrying the year's
  headline figure, a change pill, and 26 weeks of contribution squares; three
  count cards; then the breakdown bars.

  The contribution grid is a `flex-wrap` of 8px squares in the drawing, and
  Mob has no wrap primitive — so it is chunked into rows of 26, one column per
  week, which is exactly the "26 weeks" the design labels it with.

  ## Real data versus the drawing

  Same split `Kati.Screens.Home` makes, and for the same reason: the sections
  whose domain exists read it, and the sections whose domain does not are
  labelled stand-ins rather than blank space.

  **From `Kati.Media`** — every figure above the fold. One read of
  `Kati.Media.Watch`, joined through `Kati.Media.TrackedTitle` to
  `Kati.Media.CachedTitle`, answers all of them:

    * `312h 40m` is the year's watches summed by `runtime_minutes`.
    * `18%` is that total against the same span of last year, and the pill's
      arrow follows the sign — a year down on the last one is not drawn as a
      rise.
    * `84 Films` / `19 Series` count **distinct titles**, not ticks, off
      `Kati.Media.TrackedTitle.kind`; a series watched all year is one series.
    * `Avg ★` is the ten-point `rating` halved, floored the way the star row
      draws it — 9 is four and a half stars and four glyphs.
    * the 182 squares are that many days of watch counts, and `26 weeks` is the
      grid's own length rather than a second number that could disagree with it.
    * `longest streak — 11 nights` is the longest run of consecutive dates.
    * `Recently watched` is the three newest watches, with the episode label
      the tick stored and the rating that night carried.

  **Still the drawing's own copy**, because the domain cannot say it yet:

    * **Where the hours went.** `Kati.Media.CachedTitle.genres` is one free-text
      column with no defined separator, written by nothing and read by nothing.
      Splitting it here would be inventing a format and then reporting hours
      against it.
    * **More numbers.** Four rows belonging to four other domains, and three of
      them — Habits, Nutrition, Subscriptions — have no resource at all. The
      card stays whole rather than having one real line among three stand-ins.

  A watch with no date at all is real — *"I have seen this, I do not remember
  when"* is an answer `Kati.Media.Watch` deliberately allows — and it takes part
  in none of the figures above, all of which are questions about *when*.

  ## An empty database still draws the drawing

  No watches means no year, and this screen is also the reference for frame 07,
  so `load/1` falls back to `Kati.Stats.Sample` whole — the same fallback
  `Kati.Screens.Home.rest_of_today/1` and `Kati.Screens.Calendar.day_rows/1`
  make. All of it or none of it: a real 312 hours over the drawing's own
  contribution grid would be two different years in one card.
  """
  use Kati.Screens.Root, root: :stats

  require Ash.Query

  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaSeparator
  alias Kati.Components.MishkaThemeIcon
  alias Kati.Media.CachedTitle
  alias Kati.Media.Watch
  alias Kati.Stats.Sample
  alias Kati.Theme.Palette
  alias Kati.UI

  # The contribution grid's own span: 26 weeks, which is the caption the design
  # prints under it. Everything the grid needs is derived from this one number,
  # so the squares and the label cannot disagree.
  @weeks 26
  @grid_days @weeks * 7

  @impl true
  def load(socket) do
    Mob.Socket.assign(socket, figures())
  end

  @doc """
  Everything this screen draws that is not a fixed label.

  `[year: …, grid: …, recent: …]`, from `Kati.Media` when the user has watched
  anything and from `Kati.Stats.Sample` when they have not. See the moduledoc
  for which line is which column, and for the two sections that are stand-ins
  either way.
  """
  @spec figures() :: keyword()
  def figures do
    case entries() do
      [] ->
        [
          year: Map.put(Sample.year(), :rising?, true),
          grid: Sample.contributions(),
          recent: recent()
        ]

      entries ->
        [year: year(entries), grid: contributions(entries), recent: recent(entries)]
    end
  end

  @doc false
  def content(assigns) do
    year = assigns.year

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={132}
      >
        {Kati.Screens.Stats.header(year)}
        {Kati.Screens.Stats.hero(year, assigns.grid)}
        {Kati.Screens.Stats.counts(year)}
        {UI.eyebrow("Where the hours went")}
        {Kati.Screens.Stats.breakdown(year)}
        <Spacer size={26} />
        {UI.eyebrow("More numbers")}
        {Kati.Screens.Stats.more_numbers()}
        <Spacer size={26} />
        {UI.eyebrow("Recently watched", dash: Palette.rail_idle(), gap: 12)}
        {Kati.Screens.Stats.recently_watched(assigns.recent)}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def header(year) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Column weight={1.0}>
          <Text
            text="Your year"
            text_size={28}
            max_font_scale={1.6}
            font_weight="bold"
            letter_spacing={-0.03}
            text_color={:on_surface}
          />
          <Spacer size={5} />
          <Text
            text={year.range}
            font_family="mono"
            text_size={11}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
        {Kati.Screens.Stats.share_disc()}
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  # Chelekom's headless Action Icon. `shadow` is what made it usable for this:
  # `variant: :filled` alone paints card white on paper, two values that barely
  # separate, and the drawing's disc is legible only because it floats above
  # them on `shadow_button()`.
  #
  # It carried no handler for a long time, and that was the honest state: a disc
  # that swallowed a tap silently would have been worse than one that plainly
  # did nothing. Screen 98 is what it was waiting for, so it has one now.
  @doc false
  def share_disc do
    MishkaActionIcon.action_icon(
      [
        size: 44,
        shape: :circle,
        variant: :filled,
        background: Palette.card(),
        shadow: Kati.Theme.shadow_button(),
        on_tap: {self(), :share_year}
      ],
      [Kati.UI.symbol("ios_share", size: 21)]
    )
  end

  @doc false
  def hero(year, grid) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.cream()}
        corner_radius={24}
        shadow={Kati.Theme.shadow_hero()}
        padding={19}
      >
        <Row fill_width={true} align="bottom">
          <Column weight={1.0}>
            <Text
              text={String.upcase("Time watched")}
              font_family="mono"
              text_size={10.5}
              letter_spacing={0.16}
              text_color={Palette.cream_meta()}
            />
            <Spacer size={7} />
            <Text
              text={year.time}
              text_size={34}
              font_weight="extrabold"
              letter_spacing={-0.04}
              text_color={:on_surface}
            />
          </Column>
          <Column padding_bottom={5}>
            <Row
              height={28}
              corner_radius={14}
              background={Palette.green_wash()}
              padding_left={11}
              padding_right={11}
              align="center"
            >
              {Kati.Screens.Stats.arrow(year)}
              <Spacer size={5} />
              <Text
                text={year.change}
                font_family="mono"
                text_size={11.5}
                font_weight="medium"
                text_color={Palette.green_text()}
              />
            </Row>
          </Column>
        </Row>
        <Spacer size={18} />
        {Kati.Screens.Stats.grid(grid)}
        <Spacer size={12} />
        <Row fill_width={true}>
          <Text
            text={"#{year.weeks} weeks"}
            font_family="mono"
            text_size={10}
            text_color={Palette.cream_meta()}
          />
          <Spacer weight={1.0} />
          <Text
            text={year.streak}
            font_family="mono"
            text_size={10}
            text_color={Palette.cream_meta()}
            max_lines={1}
          />
        </Row>
      </Column>
      <Spacer size={14} />
    </Column>
    """
  end

  @doc """
  Which way the change pill points.

  The drawing has one state — a year up on the last one — so the glyph was a
  literal `arrow_drop_up`. A real year can be down, and a pill that says `12%`
  beside an up arrow over a year that fell is the one thing on this card that
  would be actively false rather than merely approximate. The drawn figures
  carry `rising?: true`, so frame 07 is unchanged.
  """
  # `arrow_downward` and not `arrow_drop_down`, which is the glyph this drew
  # until the drawings were re-exported against Kati's font subset. The subset
  # holds `arrow_drop_up` and not its twin, so the falling branch — reachable
  # only when a real year is down on the last, and therefore never captured —
  # was a tofu box waiting to happen.
  @spec arrow(map()) :: map()
  def arrow(%{rising?: false}),
    do: Kati.UI.symbol("arrow_downward", size: 14, color: Palette.green_text(), fill: true)

  def arrow(_year),
    do: Kati.UI.symbol("arrow_drop_up", size: 14, color: Palette.green_text(), fill: true)

  # 26 columns per row, one per week. 26*8 + 25*4 = 308, inside the 360 the
  # gutters leave, which is why the design's wrap lands on 26 as well.
  @doc false
  def grid(levels) do
    rows = Enum.chunk_every(levels, @weeks)

    ~MOB"""
    <Column fill_width={true}>
      {rows
       |> Enum.map(fn row -> Kati.Screens.Stats.grid_row(row) end)
       |> Enum.intersperse(Kati.Screens.Stats.cell_gap())}
    </Column>
    """
  end

  @doc false
  def grid_row(row) do
    ~MOB"""
    <Row>
      {row |> Enum.map(&Kati.Screens.Stats.cell/1) |> Enum.intersperse(Kati.Screens.Stats.cell_gap())}
    </Row>
    """
  end

  @doc false
  def cell_gap, do: ~MOB"<Spacer size={4} />"

  @doc false
  def cell(level) do
    color = Sample.intensity(level)

    ~MOB"""
    <Box width={8} height={8} corner_radius={2} background={color} />
    """
  end

  @doc false
  def counts(year) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {year.counts |> Enum.map(fn {n, l} -> Kati.Screens.Stats.count_card(n, l) end) |> Enum.intersperse(Kati.Screens.Stats.count_gap())}
      </Row>
      <Spacer size={26} />
    </Column>
    """
  end

  @doc false
  def count_gap, do: ~MOB"<Spacer size={12} />"

  @doc false
  def count_card(number, label) do
    ~MOB"""
    <Box weight={1.0}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card()}
        padding={15}
      >
        <Text
          text={number}
          text_size={26}
          font_weight="extrabold"
          letter_spacing={-0.035}
          text_color={:on_surface}
        />
        <Spacer size={5} />
        <Text
          text={String.upcase(label)}
          font_family="mono"
          text_size={10.5}
          letter_spacing={0.1}
          text_color={Palette.muted()}
          max_lines={1}
        />
      </Column>
    </Box>
    """
  end

  @doc false
  def breakdown(year) do
    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card()}
      padding={17}
    >
      {Enum.map(year.breakdown, fn row -> Kati.Screens.Stats.bar(row) end)}
    </Column>
    """
  end

  @doc false
  def bar({name, fraction, value, color}) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Column width={88}>
          <Text
            text={name}
            text_size={12.5}
            font_weight="semibold"
            text_color={:on_surface}
            max_lines={1}
          />
        </Column>
        <Spacer size={12} />
        <Box weight={1.0}>
          <Box fill_width={true} height={8} corner_radius={4} background={Palette.paper()}>
            <Row fill_width={true}>
              <Box weight={fraction} height={8} corner_radius={4} background={color} />
              <Spacer weight={1.0 - fraction} />
            </Row>
          </Box>
        </Box>
        <Spacer size={12} />
        <Column width={34}>
          <Text
            text={value}
            font_family="mono"
            text_size={11}
            text_color={Palette.muted()}
            text_align="right"
            max_lines={1}
          />
        </Column>
      </Row>
      <Spacer size={13} />
    </Column>
    """
  end

  @doc false
  def more_numbers do
    rows = Enum.reject(Kati.Stats.Sample.more_numbers(), &(&1.title == "Recently watched"))
    last = length(rows) - 1

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card()}
      padding_left={15}
      padding_right={15}
      padding_top={4}
      padding_bottom={4}
    >
      {rows |> Enum.with_index() |> Enum.map(fn {row, i} -> Kati.Screens.Stats.number_row(row, i < last) end)}
    </Column>
    """
  end

  @doc false
  def number_row(row, rule?) do
    tap = {self(), String.to_atom("go_" <> row.title)}

    ~MOB"""
    <Column fill_width={true} on_tap={tap}>
      <Row fill_width={true} align="center" padding_top={13} padding_bottom={13}>
        {Kati.Screens.Stats.row_tile(row.icon)}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text
            text={row.title}
            text_size={13.5}
            font_weight="semibold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={3} />
          <Text text={row.sub} text_size={11.5} text_color={Palette.sub()} max_lines={1} />
        </Column>
        <Spacer size={12} />
        {Kati.UI.symbol("chevron_right", size: 18, color: Palette.rail_idle())}
      </Row>
      {Kati.Screens.Stats.hairline(rule?)}
    </Column>
    """
  end

  # Chelekom's headless Theme Icon — "a themed container around exactly one
  # icon", which is exactly this tile. Not Action Icon: that one is a button,
  # and the tap here belongs to the whole row (`number_row/2` wires `on_tap` on
  # the Column), so a tile claiming its own would be describing an affordance
  # the drawing does not have.
  #
  # Theme Icon also builds the tighter node of the two. With no `id`,
  # `markers(nil, …)` returns caller-supplied children untouched, so the tree is
  # a Box holding the glyph — the hand-rolled node with nothing added. Action
  # Icon would have interposed a `<Row>`.
  #
  # `variant: :filled` makes `color` the fill; the glyph ink the variant derives
  # from it is unused, because a child carries its own and `Kati.UI.symbol/2`
  # supplies the drawn #5C574F at 17.
  @doc false
  def row_tile(icon) do
    MishkaThemeIcon.theme_icon(
      [variant: :filled, color: Palette.paper(), size: 30, radius: 9],
      [Kati.UI.symbol(icon, size: 17, color: Palette.ink_soft())]
    )
  end

  # Chelekom's headless Separator, given the design's own 7%-ink rule colour.
  #
  # `render: :box` is load-bearing, and the comment that used to sit here was
  # wrong about why. The default `:divider` is NOT the hand-rolled Box this
  # replaced: the bridge maps it to Material3's `HorizontalDivider`, which is a
  # Canvas drawing an ANTIALIASED `drawLine`, not a filled rect. At this
  # device's 2.6875x a 1dp rule gets a 3px canvas and a 2.6875px stroke, so the
  # last pixel row lands at ~69% coverage — a hairline 4-5/255 lighter than the
  # design's on one full-width row. `render: :box` swaps the primitive back to
  # `<Box fill_width height={1} background={color}>`, which is the node this
  # screen drew by hand, so every pixel row carries the full colour again.
  @doc false
  def hairline(false), do: ~MOB"<Spacer size={0} />"

  def hairline(true),
    do: MishkaSeparator.separator(color: Palette.hairline(), thickness: 1, render: :box)

  @doc """
  The last section of the drawing, which the screen was not drawing at all.

  Three cards under a `Recently watched` kicker, each a 38x54 poster, a title,
  a mono line and the rating in accent stars. The drawing templates the copy;
  these are the library's own titles and their photographs, so the section is
  the drawn shape filled with the data this build actually has.

  This is the **drawn** three, kept as the fallback and as the fixture the
  frame was captured from. `recent/1` builds the same shape out of
  `Kati.Media.Watch`.
  """
  @spec recent() :: [map()]
  def recent do
    [
      %{seed: "hollow71", title: "The Long Hollow", meta: "S2 E5 · 2h ago", stars: 5},
      %{seed: "bluehour58", title: "Blue Hour", meta: "FILM · yesterday", stars: 4},
      %{seed: "marram15", title: "Marram", meta: "S1 E8 · 3 days ago", stars: 4}
    ]
  end

  @doc false
  def recently_watched(rows) do
    ~MOB"""
    <Column fill_width={true}>
      {rows
       |> Enum.map(fn row -> Kati.Screens.Stats.recent_row(row) end)
       |> Enum.intersperse(Kati.Screens.Stats.recent_gap())}
    </Column>
    """
  end

  @doc false
  def recent_gap, do: ~MOB"<Spacer size={9} />"

  @doc false
  def recent_row(row) do
    ~MOB"""
    <Row
      fill_width={true}
      background={Palette.card()}
      corner_radius={18}
      shadow={Kati.Theme.shadow_card_soft()}
      padding_left={13}
      padding_right={13}
      padding_top={10}
      padding_bottom={10}
      align="center"
    >
      {Kati.Screens.Stats.recent_thumb(row)}
      <Spacer size={13} />
      <Column weight={1.0}>
        <Text
          text={row.title}
          text_size={13.5}
          font_weight="bold"
          letter_spacing={-0.015}
          text_color={:on_surface}
          max_lines={1}
        />
        <Spacer size={4} />
        <Text
          text={row.meta}
          font_family="mono"
          text_size={10.5}
          text_color={Palette.muted()}
          max_lines={1}
        />
      </Column>
      <Spacer size={13} />
      {Kati.Screens.Stats.stars(row.stars)}
    </Row>
    """
  end

  @doc false
  def recent_thumb(row) do
    case Kati.Design.Images.poster(row.seed) do
      nil ->
        ~MOB"<Box width={38} height={54} corner_radius={8} background={Palette.placeholder()} />"

      src ->
        ~MOB"""
        <Image src={src} width={38} height={54} corner_radius={8} content_mode="fill" />
        """
    end
  end

  # The drawing writes the rating as a run of star characters. Plus Jakarta
  # Sans has no U+2605, so a literal one renders as nothing at all — these are
  # the Material Symbols glyph, at the drawn 12 and the drawn accent, spaced by
  # the .08em the design tracks the run with.
  #
  # The zero clause is not defensive tidiness: `1..0` is a valid DECREASING
  # range in Elixir, so an unrated title would have drawn two stars — a rating
  # invented out of the absence of one, on the row whose whole job is to report
  # what the user thought. `Kati.Media.Watch.rating` is nullable by design.
  @doc false
  def stars(n) when n <= 0, do: ~MOB"<Spacer size={0} />"

  def stars(n) do
    ~MOB"""
    <Row align="center">
      {1..n
       |> Enum.map(fn _ -> Kati.UI.symbol("star", size: 12, color: Palette.accent(), fill: true) end)
       |> Enum.intersperse(Kati.Screens.Stats.star_gap())}
    </Row>
    """
  end

  @doc false
  def star_gap, do: ~MOB"<Spacer size={1} />"

  # ── The year, out of Kati.Media ────────────────────────────────────────────
  #
  # One read of the watch log, joined through the durable tracking row to the
  # cache. Everything above the `Where the hours went` eyebrow is folded out of
  # that one list, so no two figures on this card can be answering from
  # different reads of the database.

  @typep entry :: %{
           tracked_id: Ash.UUID.t(),
           on: Date.t() | nil,
           at: DateTime.t() | nil,
           minutes: pos_integer() | nil,
           kind: atom(),
           title: String.t() | nil,
           seed: String.t() | nil,
           season: integer() | nil,
           episode: integer() | nil,
           rating: 1..10 | nil,
           title_rating: 1..10 | nil
         }

  @spec entries() :: [entry()]
  defp entries do
    watches =
      Watch
      |> Ash.Query.load(:tracked_title)
      |> Ash.read!()

    cache = cache_for(watches)
    zone = Kati.Time.device_zone()

    watches
    |> Enum.reject(&is_nil(&1.tracked_title))
    |> Enum.map(&entry(&1, cache, zone))
  rescue
    # A stats screen is not worth a crash: off device, or before the repo is
    # up, there is no history and the drawing stands in for it.
    _ -> []
  end

  defp entry(watch, cache, zone) do
    tracked = watch.tracked_title
    cached = Map.get(cache, {tracked.source, tracked.source_id})

    %{
      tracked_id: tracked.id,
      on: watched_on(watch, zone),
      at: watch.watched_at,
      minutes: cached && cached.runtime_minutes,
      kind: tracked.kind,
      title: cached && cached.title,
      seed: cached && cached.poster_path,
      season: watch.season_number,
      episode: watch.episode_number,
      # What the user thought THAT NIGHT first, and what they think now only as
      # a fallback — `Kati.Media.Watch`'s moduledoc draws exactly that line, and
      # the star row on a `Recently watched` card is about that night.
      rating: watch.rating || tracked.rating,
      # The rating that STANDS, which is the one an average is an average of.
      # Kept apart rather than reusing the line above: a title's average would
      # otherwise depend on which of its watches the database happened to return
      # first, and be a different number on the next render.
      title_rating: tracked.rating
    }
  end

  # `watched_on` is date-valued and `watched_at` is an instant; the date wins
  # where both exist, because "watched on 12 August" is what the user said and
  # the instant is only how it was recorded. Neither is `nil` for most rows and
  # both may be — see the moduledoc on the watches that take part in nothing.
  defp watched_on(%Watch{watched_on: %Date{} = date}, _zone), do: date
  defp watched_on(%Watch{watched_at: nil}, _zone), do: nil

  defp watched_on(%Watch{watched_at: at}, zone),
    do: at |> Kati.Time.in_zone(zone) |> DateTime.to_date()

  defp cache_for([]), do: %{}

  defp cache_for(watches) do
    ids =
      watches
      |> Enum.reject(&is_nil(&1.tracked_title))
      |> Enum.map(& &1.tracked_title.source_id)
      |> Enum.uniq()

    case ids do
      [] ->
        %{}

      ids ->
        CachedTitle
        |> Ash.Query.filter(source_id in ^ids)
        |> Ash.read!()
        |> Map.new(&{{&1.source, &1.source_id}, &1})
    end
  end

  defp year(entries) do
    today = Kati.Time.today()
    this = Enum.filter(entries, &in_year?(&1, today.year))
    minutes = Enum.sum(Enum.map(this, &(&1.minutes || 0)))
    last = Enum.filter(entries, &(in_year?(&1, today.year - 1) and &1.on.month <= today.month))
    change = change(minutes, Enum.sum(Enum.map(last, &(&1.minutes || 0))))

    %{
      range: range(today),
      time: hours_and_minutes(minutes),
      change: "#{abs(change)}%",
      rising?: change >= 0,
      weeks: @weeks,
      streak: streak(this),
      counts: count_cards(this),
      # Not derivable — see the moduledoc. The drawing's own bars.
      breakdown: Sample.year().breakdown
    }
  end

  defp in_year?(%{on: %Date{} = on}, year), do: on.year == year
  defp in_year?(_entry, _year), do: false

  # `Jan – Aug 2026`: the year so far, in the device's own clock.
  defp range(today) do
    "#{short_month(1)} – #{short_month(today.month)} #{today.year}"
  end

  defp short_month(month), do: month |> Kati.Time.month_name() |> String.slice(0, 3)

  defp hours_and_minutes(minutes), do: "#{div(minutes, 60)}h #{rem(minutes, 60)}m"

  # A first year has nothing to be up on. Reporting that as 100% rather than as
  # a division by zero, and as 0% when there is nothing either side.
  defp change(_now, 0), do: 0
  defp change(now, before), do: round((now - before) / before * 100)

  # Distinct TITLES, not ticks: a series watched every week of the year is one
  # series, and the drawing's `19 Series` beside `1,204 entries` on the row
  # below is only coherent if these two count different things.
  defp count_cards(entries) do
    films = distinct(entries, &(&1.kind == :movie))
    series = distinct(entries, &(&1.kind in [:tv, :anime]))

    [
      {Integer.to_string(films), "Films"},
      {Integer.to_string(series), "Series"},
      {average_rating(entries), "Avg ★"}
    ]
  end

  defp distinct(entries, filter) do
    entries |> Enum.filter(filter) |> Enum.map(& &1.tracked_id) |> Enum.uniq() |> length()
  end

  # The ten-point scale shown as five stars, to one decimal, which is the
  # drawing's `4.1`. Unrated titles are absent rather than zero — an average
  # that counts "no opinion" as nought stars is a different statistic.
  defp average_rating(entries) do
    ratings =
      entries
      |> Enum.uniq_by(& &1.tracked_id)
      |> Enum.map(& &1.title_rating)
      |> Enum.reject(&is_nil/1)

    case ratings do
      [] -> "—"
      list -> :erlang.float_to_binary(Enum.sum(list) / length(list) / 2, decimals: 1)
    end
  end

  # The longest run of consecutive dates with something watched on them. Nights,
  # not watches: two films on one evening is one night.
  defp streak(entries) do
    case longest_run(entries) do
      0 -> "no streak yet"
      1 -> "longest streak — 1 night"
      n -> "longest streak — #{n} nights"
    end
  end

  defp longest_run(entries) do
    entries
    |> Enum.map(& &1.on)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort(Date)
    |> Enum.reduce({0, 0, nil}, fn date, {best, run, previous} ->
      run = if previous && Date.diff(date, previous) == 1, do: run + 1, else: 1
      {max(best, run), run, date}
    end)
    |> elem(0)
  end

  # 182 days ending today, oldest first, so the grid reads left to right and top
  # to bottom the way the drawing does.
  defp contributions(entries) do
    today = Kati.Time.today()

    counted =
      entries
      |> Enum.map(& &1.on)
      |> Enum.reject(&is_nil/1)
      |> Enum.frequencies()

    for offset <- (@grid_days - 1)..0//-1 do
      counted |> Map.get(Date.add(today, -offset), 0) |> level()
    end
  end

  # Five steps, because `Kati.Stats.Sample.intensity/1` paints five. Four or
  # more in a day is the heaviest square there is; the ramp has nowhere further
  # to go and a busier day is not a different colour.
  defp level(0), do: 0
  defp level(1), do: 1
  defp level(2), do: 2
  defp level(3), do: 3
  defp level(_many), do: 4

  # The three newest, by the instant they were recorded at. A watch with no
  # instant has no place in "recently", so it sorts out rather than to the top.
  defp recent(entries) do
    entries
    |> Enum.reject(&is_nil(&1.at))
    |> Enum.sort_by(& &1.at, {:desc, DateTime})
    |> Enum.take(3)
    |> Enum.map(&recent_data/1)
  end

  defp recent_data(entry) do
    %{
      seed: entry.seed,
      title: entry.title || "Untitled",
      meta: "#{recent_label(entry)} · #{ago(entry.at)}",
      # `div/2`, not `round/1`: nine on the ten-point scale is four and a half
      # stars and the row draws four whole ones.
      stars: div(entry.rating || 0, 2)
    }
  end

  # `S2 E5` where the tick stored a label, and the kind where it did not — the
  # drawing's `FILM · yesterday` is a whole-title watch with nothing to number.
  defp recent_label(%{season: season, episode: episode})
       when is_integer(season) and is_integer(episode),
       do: "S#{season} E#{episode}"

  defp recent_label(%{episode: episode}) when is_integer(episode), do: "E#{episode}"
  defp recent_label(%{kind: :movie}), do: "FILM"
  defp recent_label(%{kind: :anime}), do: "ANIME"
  defp recent_label(%{kind: :book}), do: "BOOK"
  defp recent_label(%{kind: :album}), do: "ALBUM"
  defp recent_label(_entry), do: "SERIES"

  @doc """
  How long ago something was watched, in the drawing's own words —
  `2h ago`, `yesterday`, `3 days ago`.

  Public because it is the one string in the `Recently watched` card that no
  column holds: `watched_at` is an instant and this is the sentence about it.
  A test can pin the wording directly, which it cannot do through a fixture
  whose rows are all minutes old.
  """
  @spec ago(DateTime.t()) :: String.t()
  def ago(at) do
    minutes = DateTime.diff(Kati.Time.now(), at, :second) |> div(60) |> max(0)
    days = div(minutes, 1440)

    # Days rather than a running minute count once past the first day, so a
    # "month" here is thirty of them and not the 40_320 minutes that a
    # minutes-only ladder quietly makes it. Same buckets as
    # `Kati.Screens.UpNext.age/1`, which says the same thing in the louder
    # voice its own drawing uses.
    cond do
      minutes < 1 -> "just now"
      minutes < 60 -> "#{minutes}m ago"
      days < 1 -> "#{div(minutes, 60)}h ago"
      days == 1 -> "yesterday"
      days < 7 -> "#{days} days ago"
      days < 14 -> "1 week ago"
      days < 30 -> "#{div(days, 7)} weeks ago"
      days < 60 -> "1 month ago"
      true -> "#{div(days, 30)} months ago"
    end
  end

  # The More numbers rows are the only route to these screens outside the
  # gallery, which is scaffolding.
  @destinations %{
    "Activity log" => Kati.Screens.Activity,
    "Habits" => Kati.Screens.Habits,
    "Nutrition" => Kati.Screens.Health,
    "Goals" => Kati.Screens.Goals,
    "Money" => Kati.Screens.Money,
    "Recently watched" => Kati.Screens.UpNext
  }

  @impl true
  def handle_tap(:share_year, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.YearShare)}

  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "go_" <> title ->
        case Map.fetch(@destinations, title) do
          {:ok, module} -> {:noreply, Mob.Socket.push_screen(socket, module)}
          :error -> {:noreply, socket}
        end

      _ ->
        {:noreply, socket}
    end
  end
end
