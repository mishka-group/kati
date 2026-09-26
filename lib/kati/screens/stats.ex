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

    * **More numbers.** Four rows belonging to four other domains, and three of
      them — Habits, Nutrition, Subscriptions — have no resource at all. The
      card stays whole rather than having one real line among three stand-ins.

  *Where the hours went* was in that list until 6 September, on the argument
  that `Kati.Media.CachedTitle.genres` is *"one free-text column with no defined
  separator, written by nothing and read by nothing"*. Two thirds of that had
  gone stale: `Kati.Media.Tmdb.genres/1` writes it `", "`-separated, and screens
  04 and 14 both read it back that way. It is `genre_bars/1` now — see there for
  the one judgement it does make, which is that a watch counts in full towards
  each genre it names.

  A watch with no date at all is real — *"I have seen this, I do not remember
  when"* is an answer `Kati.Media.Watch` deliberately allows — and it takes part
  in none of the figures above, all of which are questions about *when*.

  ## A year nobody has watched anything of

  This screen used to answer an empty database with `Kati.Stats.Sample` whole —
  `312h 40m`, `84 Films`, `4.1 Avg ★`, a 182-day contribution field and three
  invented titles — on the argument that frame 07 was captured from those
  values and a device with nothing tracked must still draw them. That argument
  is about the frame, and the person holding the phone is not looking at the
  frame. What they saw on a fresh install was somebody else's year with their
  name on it.

  **No board in the 152 draws screen 07 with no history.** So this is built to
  the nearest four that *are* drawn, and each decision below names which:

    * **101 — Year cards, states**, band 1 *Not enough data*. The only place the
      design draws the year's own figures with too little behind them, and what
      it draws is not a dashboard of zeroes: the card's contents are replaced by
      one glyph and the sentence *"Not much to show yet"*. That literal is this
      card's headline, and the replacement — figures out, sentence in — is this
      screen's whole empty state. 101's fifth band also decides the share disc:
      *SAVE STAYS AVAILABLE* in the not-enough-data state, so `share_disc/0`
      stays wired.
    * **27 — States**, the reference sheet every empty state in the app quotes:
      a 64pt paper tile carrying the glyph of the thing that is empty, a bold
      headline, one sentence. `Kati.Screens.HomeEmpty.invitation/0` is the same
      recipe on a root, and its numbers are the ones used here.
    * **123 — Money**, which is reached *from this screen* and states the rule
      for a statistic with nothing under it: *"The rate reads —, never £0.00 and
      never infinity. Dividing by no hours has no answer, so Kati declines to
      invent one."* An empty ledger is drawn as an empty ledger and not as a
      measured zero. A year with nothing watched is the same thing: not `0h 0m`
      over a field of 182 grey squares, which is a measurement of nothing, but a
      year that has not started being recorded.
    * **110 — Weight**, which refuses a chart that would mean nothing — *"a
      chart with a single point would be a flat line that means nothing"* — and
      says so in words instead. A contribution grid at level zero for 182 days
      is that flat line, so it is not drawn.

  ### What is drawn when nothing is counted

  The header, because `Your year` and the range under it are the page's identity
  and the range is the device's own clock. The share disc, per 101. One card in
  27's geometry. Then `More numbers`, kept — screen 139's empty Home *"states
  which parts still work, because an empty Home that looks broken sends a new
  user back out"*, and these five rows are the only route to Activity, Habits,
  Nutrition, Goals and Money outside the gallery. They keep their titles, their
  tiles and their chevrons, and lose their second lines: `1,204 entries` and
  `4 active · 12-day best` are figures this app cannot ask for, and a row with no
  second line is the same recipe minus a line it has no source for.

  Nothing else. No hero figure, no change pill, no grid, no count cards, no
  breakdown bars, no `Recently watched`.

  ### Two fabrications this screen still carries, and they are not the empty state

  Both are drawn on a device that *has* watched things, so neither is reachable
  from a fresh install any more, and both are recorded here rather than quietly
  left:

    * `More numbers`' second lines are `Kati.Stats.Sample.more_numbers/0` on
      every device. Three of the five domains have no resource at all.
  """
  use Kati.Screens.Root, root: :stats
  use Gettext, backend: Kati.Gettext

  require Ash.Query

  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaSeparator
  alias Kati.Components.MishkaThemeIcon
  alias Kati.Media.CachedTitle
  alias Kati.Media.Watch
  alias Kati.Theme.Palette
  alias Kati.UI

  # The contribution grid's own span: 26 weeks, which is the caption the design
  # prints under it. Everything the grid needs is derived from this one number,
  # so the squares and the label cannot disagree.
  #
  # The caption reads `26 weeks TO TODAY`, and the last two words are
  # the fix. The grid is 182 days back from today and the header
  # above it says *Jan – <this month> <this year>*, so in March the two
  # described different spans and the field was mostly last year under this
  # year's label. Clipping the grid to the calendar year was the other option
  # and is worse: on 3 January it would be a field of three squares, and the
  # thing the grid is for — *have I kept this up* — needs a window long enough
  # to see a habit in. So the window stays and the label stops pretending.
  @weeks 26
  @grid_days @weeks * 7

  @doc """
  The grid's span in weeks — 26, and the one place it is written down.

  Public because screen 98's share card draws the same field and board 100
  labels it `26 WEEKS`; reading it here rather than typing it again is what
  stops the squares and the label disagreeing, which is the reason this
  attribute exists at all.
  """
  @spec weeks() :: pos_integer()
  def weeks, do: @weeks

  @doc """
  `26 weeks to today`, in the reader's own digits.

      iex> Kati.Screens.Stats.weeks_line(26)
      "26 weeks to today"
  """
  @spec weeks_line(pos_integer()) :: String.t()
  def weeks_line(weeks) do
    ngettext("%{n} week to today", "%{n} weeks to today", weeks, n: Kati.Locale.number(weeks))
  end

  @impl true
  def load(socket) do
    Mob.Socket.assign(socket, figures())
  end

  @doc """
  Everything this screen draws that is not a fixed label.

  `[year: …, grid: …, recent: …, range: …]`, all of it out of `Kati.Media`.

  **`year` is `nil` when nothing has been watched**, and that is the whole
  signal the screen's two states turn on. Not an empty map and not a map of
  zeroes: every figure on this card is an answer to a question about a year that
  has begun, and there is no honest zero for *"how much of your year has Kati
  seen"* — see the moduledoc's reading of board 123. `grid` and `recent` are
  `[]` beside it, so nothing downstream can draw half a card.

  `range` is on its own key and is answered on both branches, because the header
  under `Your year` is the device's own clock rather than a figure — it is true
  on a phone that has watched nothing, and it is the one line of this screen
  that never needed a database.
  """
  @spec figures() :: keyword()
  def figures do
    case entries() do
      [] ->
        [year: nil, grid: [], week: [], recent: [], range: range(Kati.Time.today())]

      entries ->
        year = year(entries)

        [
          year: year,
          grid: contributions(entries),
          week: this_week(entries),
          recent: recent(entries),
          range: year.range
        ]
    end
  end

  @doc false
  def content(assigns) do
    case assigns.year do
      nil -> nothing_counted(assigns.range)
      year -> counted(year, assigns.range, assigns.grid, assigns.week, assigns.recent)
    end
  end

  # The two states are written out as two whole pages rather than one page with
  # a hole in it, because they share only the header: the counted page is the
  # drawing, node for node, and the empty page is a card and a list.
  @doc false
  def counted(year, range, grid, week, recent) do
    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={132}
      >
        {Kati.Screens.Stats.header(range)}
        {Kati.Screens.Stats.hero(year, grid)}
        {Kati.Screens.Stats.counts(year)}
        {UI.eyebrow(gettext("Where the hours went"))}
        {Kati.Screens.Stats.breakdown(year)}
        <Spacer size={26} />
        {UI.eyebrow(gettext("This week"), dash: Palette.rail_idle())}
        {Kati.Screens.Stats.week_card(week)}
        <Spacer size={26} />
        {UI.eyebrow(gettext("More numbers"))}
        {Kati.Screens.Stats.more_numbers()}
        <Spacer size={26} />
        {UI.eyebrow(gettext("Recently watched"), dash: Palette.rail_idle(), gap: 12)}
        {Kati.Screens.Stats.recently_watched(recent)}
      </Column>
    </Scroll>
    """
  end

  @doc """
  Screen 07 on a phone that has watched nothing.

  Header, one card, and the `More numbers` list with its invented second lines
  gone. See the moduledoc for which board decided each of those three.
  """
  @spec nothing_counted(String.t()) :: map()
  def nothing_counted(range) do
    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={132}
      >
        {Kati.Screens.Stats.header(range)}
        {Kati.Screens.Stats.nothing_yet()}
        {UI.eyebrow(gettext("More numbers"))}
        {Kati.Screens.Stats.more_numbers()}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def header(range) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Column weight={1.0}>
          <Text
            text={gettext("Your year")}
            text_size={28}
            max_font_scale={1.6}
            font_weight="bold"
            letter_spacing={Kati.Locale.tracking(-0.03)}
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={5} />
          <Text
            text={range}
            font_family={Kati.Locale.mono_face(range)}
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

  @doc """
  The card that stands where the year's figures would be.

  Board 101's *Not enough data* decision — the card's contents replaced by a
  glyph and a sentence — drawn at board 27's geometry, which is the one every
  empty state in the app quotes and which
  `Kati.Screens.HomeEmpty.invitation/0` already re-derives for a root screen.
  The numbers are that card's: radius 22 at 17pt of padding on `card/0` under
  `shadow_card_soft/0`, a 64pt tile, 18 above the headline, 9 between the two
  texts.

  **Card white, not this screen's cream.** Cream is the house style's *"a card
  that carries a claim or a warning"*, which is what the hero is; every empty
  state the design draws — 27, 110, 113, 117, 123, 139 — is on card white, and
  this card carries no claim.

  **No ink action and no quiet alternative**, which is where this leaves 27's
  full recipe. Board 113's Health card is the drawn precedent for an empty
  state without one: it omits the button because the acts it would offer are
  already on the page. So are these — the `+` in the dock is the app's one add
  action on every root, and `More numbers` sits directly below. A second ink
  pill here would be a third route to the same thing, and it would put a tap
  tag on a page whose whole point is that it is not pretending.
  """
  @spec nothing_yet() :: map()
  def nothing_yet do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        padding={17}
        shadow={Kati.Theme.shadow_card_soft()}
      >
        <Spacer size={14} />
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          {Kati.Screens.Stats.nothing_yet_tile()}
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={18} />
        <Text
          text={gettext("Not much to show yet")}
          text_size={17}
          font_weight="bold"
          letter_spacing={-0.02}
          text_align="center"
          text_color={:on_surface}
        />
        <Spacer size={9} />
        <Text
          text={gettext("Your year is counted from what you tick off. Mark one thing watched and this page starts filling itself.")}
          text_size={13}
          line_height={1.6}
          text_align="center"
          text_color={Palette.sub()}
        />
        <Spacer size={14} />
      </Column>
      <Spacer size={26} />
    </Column>
    """
  end

  @doc """
  The 64pt paper square the empty card is headed by.

  `bar_chart_4_bars` — the glyph `Kati.Shell` already gives this tab, and the
  rule every drawn empty state follows: 27 heads its own with `movie`, 113 with
  `monitor_heart`, 117 with `restaurant`, 110 with `monitor_weight`, 123 with
  `payments`. Each is the glyph of the thing that is empty, and here the thing
  that is empty is the statistics.

  Board 101 uses `schedule` instead, and it is the closer board — but its card
  is 160pt wide with no room for a tile, and its sentence is about *how long
  Kati has been counting* rather than about there being nothing to count. At
  zero there is no elapsed span to point at, so the tab's own glyph wins.

  Metrics and construction are `Kati.Screens.HomeEmpty.tile/0`'s: 64 square,
  radius 20, `rail_idle/0` on `paper/0`, and the glyph passed as a child rather
  than through `theme_icon/2`'s `icon` shorthand, which would typeset
  `bar_chart_4_bars` as four words.
  """
  @spec nothing_yet_tile() :: map()
  def nothing_yet_tile do
    MishkaThemeIcon.theme_icon(
      [variant: :filled, color: Palette.paper(), size: 64, radius: 20],
      [UI.symbol("bar_chart_4_bars", size: 28, color: Palette.rail_idle())]
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
              text={Kati.UI.eyebrow_label(gettext("Time watched"))}
              font_family={Kati.Locale.mono_face()}
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
          {Kati.Screens.Stats.change_pill(year)}
        </Row>
        <Spacer size={18} />
        {Kati.Screens.Stats.grid(grid)}
        <Spacer size={12} />
        <Row fill_width={true}>
          <Text
            text={Kati.Screens.Stats.weeks_line(year.weeks)}
            font_family={Kati.Locale.mono_face()}
            text_size={10}
            text_color={Palette.cream_meta()}
          />
          <Spacer weight={1.0} />
          <Text
            text={year.streak}
            font_family={Kati.Locale.mono_face(year.streak)}
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

  `opts` is `:size` and `:fill`, and it is here because screen 98's share card
  draws this same decision at 20pt unfilled where this pill draws it at 14
  filled. What the two pages share is the GLYPH and the COLOUR — which of the
  two arrows the font subset actually has, and that down is
  `Kati.Theme.Palette.red/0` — and a second copy of that is precisely how 98
  came to congratulate a year 07 had just drawn in red. The two numbers around
  it are not shared and are the caller's. The defaults are this pill's.
  """
  # `arrow_downward` and not `arrow_drop_down`, which is the glyph this drew
  # until the drawings were re-exported against Kati's font subset. The subset
  # holds `arrow_drop_up` and not its twin, so the falling branch — reachable
  # only when a real year is down on the last, and therefore never captured —
  # was a tofu box waiting to happen.
  @spec arrow(map()) :: map()
  @spec arrow(map(), keyword()) :: map()
  def arrow(year, opts \\ [])

  def arrow(%{rising?: false}, opts),
    do: Kati.UI.symbol("arrow_downward", arrow_opts(opts, Palette.red()))

  def arrow(_year, opts),
    do: Kati.UI.symbol("arrow_drop_up", arrow_opts(opts, Palette.green_text()))

  defp arrow_opts(opts, colour),
    do: [
      size: Keyword.get(opts, :size, 14),
      color: colour,
      fill: Keyword.get(opts, :fill, true)
    ]

  @doc """
  The pill beside *Time watched*, when there is something to compare with.

  Two halves of one defect, and they are different mistakes.

  **A first year has no last year.** `change/2` answered `0` for a prior year
  of zero minutes, so a device whose history begins today drew `↑ 0%` in green
  — a claim of *level with last year* about a year that does not exist. It
  answers `nil` now and this draws nothing at all: the headline stands on its
  own, which is what it is.

  **A year that fell was green.** The arrow had a falling branch and the
  colours did not: both the glyph and the number were `green_text` on a
  `green_wash` ground whatever the direction, so watching less than last year
  was congratulated. Down is `Palette.red/0` on `red_wash`, which is the pair
  this app already uses for a figure going the wrong way.

  The drawn year rises, so board 07 is unchanged.
  """
  @spec change_pill(map()) :: map()
  def change_pill(%{change: nil}), do: ~MOB"<Spacer size={0} />"

  def change_pill(year) do
    assigns = %{
      year: year,
      arrow: arrow(year),
      ground: if(year.rising?, do: Palette.green_wash(), else: Palette.red_wash()),
      ink: if(year.rising?, do: Palette.green_text(), else: Palette.red())
    }

    ~MOB"""
    <Column padding_bottom={5}>
      <Row
        height={28}
        corner_radius={14}
        background={@ground}
        padding_left={11}
        padding_right={11}
        align="center"
      >
        {@arrow}
        <Spacer size={5} />
        <Text
          text={@year.change}
          font_family="mono"
          text_size={11.5}
          font_weight="medium"
          text_color={@ink}
        />
      </Row>
    </Column>
    """
  end

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
    color = Kati.Stats.Ramp.intensity(level)

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

  @doc """
  Board 61's *این هفته* card, over the reader's own seven days.

  Bars grow from the leading edge of a 56pt well and the day initials sit under
  them; under `rtl` the row starts on the right, which is the drawing's own
  reading and needs no mirroring of its own — `Kati.Screens.Search.chips/2`
  makes the same argument for its chip rail.

  A day with nothing watched still draws a 4pt stub. A zero-height bar is an
  absent bar, and a week with two quiet days would read as a chart that failed
  to load rather than as a quiet week.
  """
  @spec week_card([{Date.t(), non_neg_integer()}]) :: map()
  def week_card(week) do
    most = week |> Enum.map(&elem(&1, 1)) |> Enum.max(fn -> 0 end)
    today = Kati.Time.today()

    assigns = %{
      bars:
        week
        |> Enum.map(fn {date, count} ->
          Kati.Screens.Stats.week_bar(Kati.Screens.Stats.bar_height(count, most), date == today)
        end)
        |> Enum.intersperse(~MOB"<Spacer size={6} />"),
      labels: Enum.map(week, fn {date, _count} -> Kati.Screens.Stats.week_label(date) end)
    }

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={17}
      >
        <Row fill_width={true} height={56} align="bottom">
          {@bars}
        </Row>
        <Spacer size={10} />
        <Row fill_width={true} align="center">
          {@labels}
        </Row>
      </Column>
    </Column>
    """
  end

  @doc """
  A day's bar height in the 56pt well — 4 for a quiet day, 56 for the busiest.

      iex> Kati.Screens.Stats.bar_height(0, 4)
      4

      iex> Kati.Screens.Stats.bar_height(4, 4)
      56

      iex> Kati.Screens.Stats.bar_height(1, 0)
      4
  """
  @spec bar_height(non_neg_integer(), non_neg_integer()) :: pos_integer()
  def bar_height(_count, 0), do: 4
  def bar_height(0, _most), do: 4
  def bar_height(count, most), do: max(round(count / most * 56), 4)

  @doc false
  def week_bar(height, today?) do
    color = if today?, do: Palette.ink(), else: Palette.placeholder()

    ~MOB"<Box weight={1.0} height={height} corner_radius={5} background={color} />"
  end

  @doc false
  def week_label(date) do
    assigns = %{day: Kati.Locale.weekday_initial(date)}

    ~MOB"""
    <Box weight={1.0}>
      <Text
        text={@day}
        text_size={10.5}
        text_color={Palette.tertiary()}
        text_align="center"
        max_lines={1}
      />
    </Box>
    """
  end

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
            font_family={Kati.Locale.mono_face(value)}
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

  @doc """
  The five rows under `More numbers`.

  `counted?` is whether this device has watched anything, and it decides one
  thing: whether each row carries its second line. Those lines —
  `1,204 entries`, `4 active · 12-day best`, `Cutting v3 · 86%`,
  `3 active · 38 of 52 books`, `£46.47 a month · 7 expenses` — are
  `Kati.Stats.Sample`'s, and three of the five domains behind them have no
  resource at all. On a phone that has counted nothing they are the defect this
  round exists to remove, so they are not drawn.

  The rows themselves stay on both branches, and that is deliberate: screen
  139's empty Home *"states which parts still work"*, and these five are the
  only route to Activity, Habits, Nutrition, Goals and Money outside the
  gallery. Dropping them would make half the app unreachable for exactly the
  person who has just installed it.
  """
  @spec more_numbers() :: map()
  def more_numbers do
    rows =
      Kati.Stats.Sample.more_numbers()
      |> Enum.reject(&(&1.id == :recently_watched))
      |> Enum.map(&entries_line/1)
      |> Kati.Screens.Stats.with_subscriptions()

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

  @doc """
  Board 61's rows, plus the one Kati adds: **Subscriptions**.

  Appended here rather than written into `Kati.Stats.Sample.more_numbers/0`,
  and the distinction is the reason that module exists: the Sample is board
  61's own transcription, the value a design test compares a render against,
  and a row the board never drew does not belong in it. This is the app's own
  addition to a card the board specified.

  The argument for adding it is that **cost per watched hour is a watch
  statistic**. `Kati.Subscriptions.hours_by_service/0` divides what a service
  costs by the hours actually watched on it, and it reads episode runtimes
  through the same rule `runtimes_for/1` uses one function over — a series'
  duration is on the EPISODE, a film's on the title. That question is asked
  nowhere on this page and answered in full one tap away.

  Screen 23 was already reachable, from *My services* and from Money, so this
  is a second door to a page that has one rather than a rescue. It earns its
  place by subject: a reader asking how much they watched is a tap from asking
  what it cost them, and neither of the existing doors is on the page where
  that question is being asked.

  The sub-line is the ledger's own monthly total, and **the words screen 23 uses
  when there is no ledger** — not `empty_ledger/0`'s bare `—`. That dash is
  right on screen 23, where it sits under an `Every month` label; standing alone
  as a row sub-line beside *Nothing to add up yet*, *No goals set* and *Not set
  up* it reads as a rendering fault, which is board 309's rule for this card
  stated in its own words: *"A row missing its sub-line is not the same claim as
  a row that has one and says the honest thing — the first reads as a rendering
  fault, and the second as an answer. **Not set up** is what the page behind each
  of them says."* Found by tapping the row on the emulator and reading the page
  it opened, which says *No subscriptions yet*.

  Not a figure either way: `£46.47 a month · 7 expenses` is what the Money row
  beside it carried on every device until #45.
  """
  @spec with_subscriptions([map()]) :: [map()]
  def with_subscriptions(rows) do
    rows ++
      [
        %{
          id: :subscriptions,
          icon: "subscriptions",
          title: gettext("Subscriptions"),
          sub: Kati.Screens.Stats.subscriptions_line()
        }
      ]
  end

  @doc """
  What the subscriptions row says under its title: the monthly total, or the
  words screen 23 uses when there is nothing to total.

      iex> is_binary(Kati.Screens.Stats.subscriptions_line())
      true
  """
  @spec subscriptions_line() :: String.t()
  def subscriptions_line do
    case Kati.Subscriptions.ledger() do
      %{monthly: %{total: total}} when is_binary(total) and total != "—" -> total
      _nothing_subscribed -> gettext("No subscriptions yet")
    end
  rescue
    _error -> gettext("No subscriptions yet")
  end

  # The one row of the five whose second line this app can actually answer.
  #
  # `1,204 entries` was `Kati.Stats.Sample`'s on every device — a specific claim
  # about the reader's own history, of exactly the kind a fixture must
  # not make, sitting on a phone that may hold four watches. It is the
  # activity log's own count, read off the log — see `entries_count/0`.
  #
  # The other four stay the drawing's, and the moduledoc's reason stands for
  # them: Habits, Nutrition and Money have no resource behind them at all, and a
  # card with one real line among three stand-ins would be harder to read as a
  # stand-in card than one that is wholly frozen. What changes here is that the
  # line the app CAN answer is no longer among the frozen ones.
  # The rest of the frozen-figure defect. Four rows carried the drawing's own
  # figures on every device — `4 active · 12-day best`, `Cutting v3 · 86%`,
  # `3 active · 38 of 52 books`, `£46.47 a month · 7 expenses` — beside one
  # that counts. Two of the four can be counted now and are; the other two
  # cannot and say nothing rather than saying somebody else's numbers, which
  # is the call #75 made on screen 92 and #58 on screen 15.
  defp entries_line(%{id: :activity} = row) do
    %{row | sub: Kati.Screens.Stats.entries_count()}
  end

  defp entries_line(%{id: :goals} = row), do: %{row | sub: Kati.Screens.Stats.goals_line()}
  defp entries_line(%{id: :money} = row), do: %{row | sub: Kati.Screens.Stats.money_line()}
  defp entries_line(%{id: :health} = row), do: %{row | sub: Kati.Screens.Stats.weight_line()}

  # `Kati.Habits` is a `Sample` module and nothing else — no resource, no
  # table — and `Nutrition`'s `Cutting v3 · 86%` is a diet plan, which
  # `Kati.Health` holds no column for either. Both rows stay, because the row
  # is the door to a page that exists; what goes is the figure.
  #
  # `nil` until board 309, which is the half this got wrong: *"The row was
  # shipping with no second line while every other row on the page carried
  # one."* A row missing its sub-line is not the same claim as a row that has
  # one and says the honest thing — the first reads as a rendering fault, and
  # the second as an answer. **Not set up** is what the page behind each of them
  # says, which is 309's rule for the whole card.
  # The ID, not the drawn title. `Kati.Stats.Sample.more_numbers/0` has
  # translated its titles since mishka-group/kati#103, so this clause matched
  # two English words and no Persian ones: on board 61 Habits and Nutrition fell
  # through to the drawing's frozen `4 active · 12-day best` and
  # `Cutting v3 · 86%`, which is the very defect the clause was written to
  # close, restored by translating the thing it was keyed on.
  defp entries_line(%{id: id} = row) when id in [:habits, :nutrition],
    do: %{row | sub: gettext("Not set up")}

  defp entries_line(row), do: row

  @doc """
  `3 active` — the goals the reader is running, counted.

      iex> is_binary(Kati.Screens.Stats.goals_line())
      true
  """
  @spec goals_line() :: String.t()
  def goals_line do
    case Kati.Goals.Goal |> Ash.read!() |> length() do
      # Board 309's wording, which says what 105 says: the count runs whether or
      # not a goal has been set, so *none set* is not *nothing counted*.
      0 -> gettext("No goals set — Kati counts anyway")
      n -> ngettext("%{n} goal", "%{n} goals", n, n: Kati.Locale.number(n))
    end
  rescue
    _error -> gettext("None set")
  end

  @doc """
  `76.0 kg` — the reader's latest weight, or the absence of one.

  Board 61's third *More numbers* row, which the English card does not have:
  screen 42 is the Health hub in English and Persian has no such page, so
  screen 61's own moduledoc calls this row the route. It drew **۷۶٫۰ کیلوگرم**
  frozen on every device, which is the frozen-figure defect on the one
  row of the three that has a resource behind it — `Kati.Health.Reading` —
  and `Kati.Screens.Weight.latest/0` is the reader that answers it.
  """
  @spec weight_line() :: String.t()
  def weight_line do
    if Kati.Screens.Weight.stored?() do
      latest = Kati.Screens.Weight.latest()

      gettext("%{figure} %{unit}",
        figure: Kati.Locale.number(latest.figure),
        unit: latest.unit
      )
    else
      # 309's rule for a row whose page has nothing in it: the row stays,
      # because it is the door to a page that exists, and the figure goes.
      #
      # `stored?/0` and not `entries() == []`, which is what this asked and
      # which is never true: screen 110 falls back to its drawing on an empty
      # store, so the guard took the other branch on every device and this row
      # reported the drawing's **76.0 kg** to somebody who has never been
      # weighed. The function's own doc says it was written against exactly
      # that defect.
      gettext("Not set up")
    end
  rescue
    _error -> gettext("Not set up")
  end

  @doc """
  `£46.47 a month · 7 expenses` — the reader's own, both halves.

  The subscription total is `Kati.Screens.MyServices`'s, read through the same
  function screen 92's own Money row reads, so the two pages cannot disagree
  about what a month costs.
  """
  @spec money_line() :: String.t()
  def money_line do
    total = Kati.Screens.MyServices.monthly_total()
    n = Kati.Money.Expense |> Ash.read!() |> length()

    [
      # `Kati.Locale.ltr/1` on the total. It is a Latin money run — `£46.47` —
      # and the currency mark is a neutral character to the bidi algorithm, so
      # inside a Persian sentence it resolved right-to-left and the page drew
      # **۴۶٫۴۷ £ در ماه** with the sign on the wrong side of its own figure.
      if(total in [nil, "—"],
        do: nil,
        else: gettext("%{total} a month", total: Kati.Locale.ltr(total))
      ),
      if(n == 0,
        do: nil,
        else: ngettext("%{n} expense", "%{n} expenses", n, n: Kati.Locale.number(n))
      )
    ]
    |> Enum.reject(&is_nil/1)
    |> case do
      # 309's wording for a money row at zero: what 123's page says of itself.
      [] -> gettext("Nothing to add up yet")
      parts -> Enum.join(parts, " · ")
    end
  rescue
    _error -> gettext("Nothing added yet")
  end

  @doc """
  How many entries the activity log holds — the line its own header draws.

  `Kati.Screens.Activity.log/0`'s `entries_line`, read rather than recounted.
  This counted `Kati.Media.Watch` alone, and the log has counted watches AND
  `Kati.Media.Event`s since *Added* and *Dropped* became entries,
  so a reader with three adds, two watches and a drop
  was told `2 entries` on this row and `6 entries` on the page it opens. One
  function answering both is what stops the next kind of entry from splitting
  them again. `log/0` answers its empty wording for a store it cannot read, so
  this does too.
  """
  @spec entries_count() :: String.t()
  def entries_count do
    Kati.Screens.Activity.log().entries_line
  rescue
    _error -> Kati.Screens.Activity.entries_line(0)
  end

  @doc false
  def number_row(row, rule?) do
    tap = {self(), String.to_atom("go_" <> Atom.to_string(row.id))}

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
          {Kati.Screens.Stats.row_sub(row)}
        </Column>
        <Spacer size={12} />
        {Kati.UI.symbol(Kati.Locale.forward_chevron(), size: 18, color: Palette.rail_idle())}
      </Row>
      {Kati.Screens.Stats.hairline(rule?)}
    </Column>
    """
  end

  # The second line, or nothing where there is no figure to put on it. A row of
  # a title and a chevron is the settings-list recipe the whole app is built
  # from; a row of a title and an invented figure is not a recipe at all.
  #
  # ## It took a `counted?` flag, and the flag outlived its reason
  #
  # `nothing_counted/1` passed `false` and every row on the empty page lost its
  # second line at once — the blunt answer from before any of these lines could
  # be read. Each of them can now, and each answers the empty store honestly:
  # **No goals set — Kati counts anyway**, **Nothing to add up yet**, **Not set
  # up**, **0 entries**. Those are board 309's own wordings for exactly this
  # state, so suppressing them was the page withholding the answer 309 asked
  # for.
  #
  # Board 61 is what said so. Its mirror drew all three lines in every state
  # because it read them rather than the flag, and folding the mirror into this
  # screen would have taken that away. mishka-group/kati#103.
  #
  # A row whose figure is nobody's still draws no second line — #45. `Habits`
  # and `Nutrition` have no resource to count, and `entries_line/1` gives them
  # **Not set up** rather than the drawing's figures.
  @doc false
  def row_sub(%{sub: nil}), do: ~MOB"<Spacer size={0} />"

  def row_sub(row) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={3} />
      <Text text={row.sub} text_size={11.5} text_color={Palette.sub()} max_lines={1} />
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

  This is the **drawn** three, and it is no longer a fallback: a phone that has
  watched nothing draws no `Recently watched` section at all. It is kept as the
  fixture frame 07 was captured from and as the shape `recent/1` has to agree
  with — `Kati.ScreenStatsTest` asserts the real reader answers exactly this
  against a fixture built to match, so the meta line and the star count are
  pinned against the drawing rather than against literals typed into a test.
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
    runtimes = runtimes_for(watches)
    zone = Kati.Time.device_zone()

    watches
    |> Enum.reject(&is_nil(&1.tracked_title))
    |> Enum.map(&entry(&1, cache, runtimes, zone))
  rescue
    # A stats screen is not worth a crash: off device, or before the repo is
    # up, there is no history and the drawing stands in for it.
    _ -> []
  end

  defp entry(watch, cache, runtimes, zone) do
    tracked = watch.tracked_title
    cached = Map.get(cache, {tracked.source, tracked.source_id})

    %{
      tracked_id: tracked.id,
      on: watched_on(watch, zone),
      at: watch.watched_at,
      # The EPISODE's runtime for an episode tick, and the title's for a film.
      # This read the title's for both, and TMDB puts a series' duration on
      # each episode — `/tv/{id}` answers `episode_run_time` and not `runtime`,
      # so `Kati.Media.CachedTitle.runtime_minutes` is `nil` for every series
      # in the store. *Time watched* therefore read `0h 0m` however many
      # episodes somebody ticked.
      minutes: Map.get(runtimes, watch.episode_source_id) || (cached && cached.runtime_minutes),
      kind: tracked.kind,
      # For `breakdown/1`. The title's, because a genre is a property of the
      # show rather than of one night of it.
      genres: cached && cached.genres,
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

  # `%{episode_source_id => runtime_minutes}` for every episode a tick names.
  # One query for the whole history, the shape `cache_for/1` already uses, and
  # an episode with no runtime is simply absent — `entry/4` falls through to
  # the title's, which is right for a film and `nil` for a series nobody has
  # runtimes for.
  defp runtimes_for(watches) do
    ids =
      watches
      |> Enum.map(& &1.episode_source_id)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()

    case ids do
      [] ->
        %{}

      ids ->
        Kati.Media.CachedEpisode
        |> Ash.Query.filter(source_id in ^ids)
        |> Ash.read!()
        |> Enum.reject(&is_nil(&1.runtime_minutes))
        |> Map.new(&{&1.source_id, &1.runtime_minutes})
    end
  rescue
    _error -> %{}
  end

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
      change: change && gettext("%{n}%", n: Kati.Locale.number(abs(change))),
      rising?: is_nil(change) or change >= 0,
      weeks: @weeks,
      streak: streak(this),
      counts: count_cards(this),
      breakdown: genre_bars(this)
    }
  end

  # The genre bars, from the genres the provider actually gave.
  #
  # This was `Kati.Stats.Sample.year/0`'s five frozen bars on every device, and
  # the moduledoc's reason was that `Kati.Media.CachedTitle.genres` is *"one
  # free-text column with no defined separator, written by nothing and read by
  # nothing"*. Two thirds of that went stale: `Kati.Media.Tmdb.genres/1` writes
  # it, `", "`-separated, and screens 04 and 14 both read it back that way. So
  # the separator is defined, by the only writer there is.
  #
  # What is still true is that a title has SEVERAL genres and one duration, and
  # there is no honest way to divide ninety minutes between *Drama* and
  # *Mystery*. So a watch counts in full towards each genre it names — the
  # question the band asks is *where did the hours go*, and an hour of a
  # drama-mystery went to both — and the bars are scaled against the largest
  # rather than against a total that would then exceed the year. The value
  # under each is the hours themselves, so the arithmetic is visible rather
  # than implied.
  #
  # Five bars, because the drawing has five: the top four by hours and
  # `Everything else` for the rest, which is exactly what board 07 draws.
  # The drawing's five, named rather than written out — `Kati.Theme.PaletteTest`
  # is right that a hex in a screen is a colour that cannot follow the mode, and
  # these five have to, because the bars sit on a card. Functions rather than a
  # module attribute for the same reason: the palette resolves at call time.
  defp genre_colours,
    do: [Palette.ink(), Palette.green(), Palette.accent(), Palette.bronze()]

  defp rest_colour, do: Palette.rail_idle()

  defp genre_bars([]), do: []

  defp genre_bars(entries) do
    by_genre =
      entries
      |> Enum.flat_map(fn entry ->
        Enum.map(genres_of(entry), &{&1, entry.minutes || 0})
      end)
      |> Enum.reduce(%{}, fn {genre, minutes}, acc ->
        Map.update(acc, genre, minutes, &(&1 + minutes))
      end)
      |> Enum.sort_by(fn {genre, minutes} -> {-minutes, genre} end)

    case by_genre do
      [] -> []
      ranked -> bars(ranked)
    end
  end

  defp bars(ranked) do
    colours = genre_colours()
    {top, rest} = Enum.split(ranked, length(colours))
    top_minutes = Enum.map(top, &elem(&1, 1))
    rest_minutes = Enum.sum(Enum.map(rest, &elem(&1, 1)))
    largest = Enum.max([rest_minutes | top_minutes])

    named =
      top
      |> Enum.zip(colours)
      |> Enum.map(fn {{genre, minutes}, colour} -> bar_row(genre, minutes, largest, colour) end)

    if rest == [],
      do: named,
      else: named ++ [bar_row(gettext("Everything else"), rest_minutes, largest, rest_colour())]
  end

  defp bar_row(name, minutes, largest, colour) do
    fraction = if largest > 0, do: minutes / largest, else: 0.0

    {name, Float.round(fraction, 2), gettext("%{n}h", n: Kati.Locale.number(div(minutes, 60))),
     colour}
  end

  # `Drama, Mystery, Sci-Fi & Fantasy` as it is stored, split on the separator
  # its only writer uses. A title with no genres takes part in no bar rather
  # than becoming an `Unknown` one, which would be a genre nobody named.
  defp genres_of(%{genres: genres}) when is_binary(genres) and genres != "" do
    genres
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp genres_of(_entry), do: []

  defp in_year?(%{on: %Date{} = on}, year), do: on.year == year
  defp in_year?(_entry, _year), do: false

  @doc """
  `Jan – Aug 2026`: the year so far, in the device's own clock and calendar.

      iex> Kati.Screens.Stats.range(~D[2026-08-12])
      "Jan – Aug 2026"

      iex> Kati.Locale.as(:fa, fn -> Kati.Screens.Stats.range(~D[2026-08-12]) end)
      "فروردین تا مرداد ۱۴۰۵"

  Public because `Kati.Stats.Sample.year/0` composes the boards' own header from
  it: board 07 draws **Jan – Aug 2026** and board 61 draws
  **فروردین تا مرداد ۱۴۰۵**, and those are one function over one date rather
  than two frozen strings that could disagree about which year it is.
  """
  @spec range(Date.t()) :: String.t()
  #
  # `Kati.Locale.date/2` and not `Kati.Time.month_name/1`, because the year this
  # line names is the reader's year: board 61's header reads
  # **فروردین تا مرداد ۱۴۰۵**, which is the Shamsi year so far and neither the
  # same months nor the same number as the Gregorian one. The first of the year
  # is Farvardin 1 in Shamsi and January 1 in Gregorian, so the range is built
  # from two REAL dates and the calendar decides what to call them.
  def range(today) do
    gettext("%{from} – %{to} %{year}",
      from: month_word(Kati.Locale.year_start(today)),
      to: month_word(today),
      year: Kati.Locale.year_of(today)
    )
  end

  defp month_word(date), do: Kati.Locale.month_name(date, :short)

  # `312h 40m`, in the reader's own digits and words. It was two Latin letters
  # glued to two Latin numbers, so board 61's hero read `312h 40m` on a Persian
  # page — which is why the mirror carried its own `hours`/`hours_unit` pair.
  defp hours_and_minutes(minutes) do
    gettext("%{h}h %{m}m",
      h: Kati.Locale.number(div(minutes, 60)),
      m: Kati.Locale.number(rem(minutes, 60))
    )
  end

  # A first year has nothing to be up on. Reporting that as 100% rather than as
  # a division by zero, and as 0% when there is nothing either side.
  # `nil` and not `0` when there is nothing to compare with. A first year has no
  # last year, and `0%` beside a green up arrow is a claim that this year is
  # level with one that does not exist — the pill said *unchanged* to somebody
  # whose history begins today. `change_pill/1` draws
  # nothing for `nil`.
  defp change(_now, 0), do: nil
  defp change(now, before), do: round((now - before) / before * 100)

  # Distinct TITLES, not ticks: a series watched every week of the year is one
  # series, and the drawing's `19 Series` beside `1,204 entries` on the row
  # below is only coherent if these two count different things.
  defp count_cards(entries) do
    films = distinct(entries, &(&1.kind == :movie))
    series = distinct(entries, &(&1.kind in [:tv, :anime]))

    [
      {Kati.Locale.number(films), gettext("Films")},
      {Kati.Locale.number(series), gettext("Series")},
      {average_rating(entries), gettext("Avg ★")}
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
      [] ->
        "—"

      list ->
        list
        |> Enum.sum()
        |> Kernel./(length(list) * 2)
        |> :erlang.float_to_binary(decimals: 1)
        |> Kati.Locale.number()
    end
  end

  # The longest run of consecutive dates with something watched on them. Nights,
  # not watches: two films on one evening is one night.
  defp streak(entries) do
    case longest_run(entries) do
      0 ->
        gettext("no streak yet")

      n ->
        ngettext("longest streak — %{n} night", "longest streak — %{n} nights", n,
          n: Kati.Locale.number(n)
        )
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

  @doc """
  The seven days of the reader's own week, each with what was watched on it.

  `[{date, count}]`, Saturday-first in Persian and Monday-first in English —
  `Kati.Locale.week_start/0` is the same ruling board 137 makes about the
  calendar, applied to a chart.

  ## Board 61 drew this card and screen 07 did not have it

  `Kati.Fa.SampleYear.week/0` was seven frozen bar heights and a frozen *this
  one is lit* flag: `[{42, false}, {36, false}, {12, false}, {54, true}, …]`,
  identical on every device, which is the frozen-figure defect over a whole card.
  So the card does not survive the fold as it stood — but the DATA behind it
  was already on this screen, because the contribution grid above it counts the
  same watches over 182 days. Seven of those days is this week.

  The lit bar is **today**, which is the one reading of the drawing a device can
  honour: a week strip whose dark bar moves with the date says where you are in
  the week, and one whose dark bar is the tallest says nothing the heights do
  not already say.
  """
  @spec this_week([map()]) :: [{Date.t(), non_neg_integer()}]
  def this_week(entries) do
    today = Kati.Time.today()

    counted =
      entries
      |> Enum.map(& &1.on)
      |> Enum.reject(&is_nil/1)
      |> Enum.frequencies()

    start = Kati.Screens.Stats.week_start_on(today)

    for offset <- 0..6 do
      date = Date.add(start, offset)
      {date, Map.get(counted, date, 0)}
    end
  end

  @doc """
  The date this reader's week began on, at or before `today`.

      iex> Kati.Screens.Stats.week_start_on(~D[2026-09-12])
      ~D[2026-09-07]

      iex> Kati.Locale.as(:fa, fn -> Kati.Screens.Stats.week_start_on(~D[2026-09-12]) end)
      ~D[2026-09-12]

  12 September 2026 is a Saturday, so a Persian week starts on it and an
  English one started five days earlier.
  """
  @spec week_start_on(Date.t()) :: Date.t()
  def week_start_on(%Date{} = today) do
    # `Date.day_of_week/1` is 1 = Monday .. 7 = Sunday.
    back =
      if Kati.Locale.direction(Kati.Locale.current()) == :rtl do
        rem(Date.day_of_week(today) + 1, 7)
      else
        Date.day_of_week(today) - 1
      end

    Date.add(today, -back)
  end

  # Five steps, because `Kati.Stats.Ramp.intensity/1` paints five. Four or
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
      title: entry.title || gettext("Untitled"),
      # The kind takes the eyebrow's casing and the time does not, which is the
      # drawing's own pairing: `FILM · yesterday`. `Kati.UI.eyebrow_label/1`
      # rather than `String.upcase/1`, so the Persian side is left alone —
      # Persian has no case and upcasing it is a no-op that reads as one.
      meta:
        gettext("%{what} · %{when}",
          what: Kati.UI.eyebrow_label(recent_label(entry)),
          when: ago(entry.at)
        ),
      # `div/2`, not `round/1`: nine on the ten-point scale is four and a half
      # stars and the row draws four whole ones.
      stars: div(entry.rating || 0, 2)
    }
  end

  # `S2 E5` where the tick stored a label, and the kind where it did not — the
  # drawing's `FILM · yesterday` is a whole-title watch with nothing to number.
  defp recent_label(%{season: season, episode: episode})
       when is_integer(season) and is_integer(episode),
       do:
         gettext("S%{s} E%{e}",
           s: Kati.Locale.number(season),
           e: Kati.Locale.number(episode)
         )

  defp recent_label(%{episode: episode}) when is_integer(episode),
    do: gettext("E%{e}", e: Kati.Locale.number(episode))

  defp recent_label(%{kind: :movie}), do: gettext("Film")
  defp recent_label(%{kind: :anime}), do: gettext("Anime")
  defp recent_label(%{kind: :book}), do: gettext("Book")
  defp recent_label(%{kind: :album}), do: gettext("Album")
  defp recent_label(_entry), do: gettext("Series")

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
      minutes < 1 ->
        gettext("just now")

      minutes < 60 ->
        gettext("%{n}m ago", n: Kati.Locale.number(minutes))

      days < 1 ->
        gettext("%{n}h ago", n: Kati.Locale.number(div(minutes, 60)))

      days == 1 ->
        gettext("yesterday")

      days < 7 ->
        ngettext("%{n} day ago", "%{n} days ago", days, n: Kati.Locale.number(days))

      days < 30 ->
        weeks = max(div(days, 7), 1)
        ngettext("%{n} week ago", "%{n} weeks ago", weeks, n: Kati.Locale.number(weeks))

      true ->
        months = max(div(days, 30), 1)
        ngettext("%{n} month ago", "%{n} months ago", months, n: Kati.Locale.number(months))
    end
  end

  # The More numbers rows are the only route to these screens outside the
  # gallery, which is scaffolding.
  @destinations %{
    "activity" => Kati.Screens.Activity,
    "habits" => Kati.Screens.Habits,
    "nutrition" => Kati.Screens.Health,
    "goals" => Kati.Screens.Goals,
    "money" => Kati.Screens.Money,
    # Board 61's row, kept through the fold — see `Kati.Stats.Sample`. Screen
    # 110 is the weight page itself rather than screen 42's hub, because the row
    # names a reading and the hub is a menu.
    "health" => Kati.Screens.Weight,
    # Kati's own row rather than board 61's — see `with_subscriptions/1` for
    # why cost per watched hour belongs on the page that counts the hours.
    "subscriptions" => Kati.Screens.Subscriptions
    # `Recently watched` was here, and `more_numbers/1` rejects that row by
    # name — so no `go_Recently watched` tag was ever emitted and the entry was
    # dead code. Deleted rather than drawn: the row is
    # rejected because this screen already shows those three watches in full
    # one section down, and a numbers row that only counts them would be the
    # page telling you twice.
  }

  @impl true
  def handle_tap(:share_year, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.YearShare)}

  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "go_" <> id ->
        case Map.fetch(@destinations, id) do
          {:ok, module} -> {:noreply, Mob.Socket.push_screen(socket, module)}
          :error -> {:noreply, socket}
        end

      _ ->
        {:noreply, socket}
    end
  end
end
