defmodule Kati.Screens.MealsDay do
  @moduledoc """
  Screen 52 — meals on the calendar.

  Built to `test/design/screens/52.html`. A day where five of the eleven
  items are meals, drawn to prove that meals need no special lane: they take a
  bronze rule, sit in clock order with everything else, and then collapse into
  a single row under the same 3+ density rule that collapses six episodes on
  screen 09.

  Pushed under Calendar — the drawing's back pill says `‹ Calendar` — so the
  frame's bottom padding is **40, not 132**. There is no dock here, and 132
  would leave a hand's width of dead paper under the last row.

  ## Where this diverges from the drawing

    * The lane rule is `align-self: stretch` in the design and a declared 34pt
      here. Nothing measures geometry on this bridge, and every row carries the
      same two lines of text, so a fixed rule is exact rather than approximate
      — but it would need revisiting if a title ever wrapped.
    * An unlogged meal's ring is drawn empty. The design puts a `check` glyph
      inside it at `rgba(26,25,23,0)` — fully transparent — which is a way of
      reserving space in CSS, not a mark anyone sees.

  ## The two controls

  Both start in the state the drawing is in, so the resting screen is the
  drawing:

    * The **chips** filter the spine. `All` is selected, so every row shows —
      which is what the drawing draws. The section chips read a row's *lane
      colour*, because that is where this screen already stores what a row is:
      bronze is a meal, orange is Screen, and everything else (the habit's
      green, the appointment's ink) is Personal. Deriving the chip from the
      rule keeps the filter and the stripe from ever disagreeing.
    * The **density disc** — and the collapsed row's own chevron, which is the
      same control drawn twice — folds the five meals out of the spine and
      into the summary the `Collapse meals` eyebrow already labels. That is
      the screen's whole argument made operable: the drawing shows both states
      at once so the reader can compare them, and the disc lets you actually
      switch between them.
  """
  use Kati.Screens.Pushed, back: "Calendar"

  alias Kati.Calendar.SampleMealDay
  alias Kati.Meals.MealLog
  alias Kati.Theme
  alias Kati.Theme.Palette
  alias Kati.UI

  # The lane colours `Kati.Calendar.SampleMealDay` paints, read back as kinds.
  #
  # LEFT AS LITERALS on purpose: these two are not paint, they are the patterns
  # `kind/1` matches a row's `rule` against, and a pattern cannot hold a
  # function call. They stay correct in dark because both colours they stand for
  # are mode-invariant — `Palette.bronze/0` is `:theme` and `Palette.accent/0`
  # keeps full strength on near-black — so whatever the data module ends up
  # calling them, the value on the wire is still these.
  @meal 0xFFB08E55
  @screen 0xFFE8823C

  @impl true
  def load(socket) do
    Mob.Socket.assign(socket,
      day: Kati.Screens.MealsDay.day(socket.assigns.params),
      filter: "All",
      density: :comfortable
    )
  end

  @doc """
  The day this page is about: the one the push named, or the drawing's.

  ## The date is the route's, not the fixture's

  `%{date: date}` is what `Kati.Screens.Calendar` pushes — the day its strip is
  on, and the day whose meals row was tapped. This screen assigned
  `Kati.Calendar.SampleMealDay.day/0` unconditionally, so every route in landed
  on `Mon 17 Aug`, and the page's own title was the one thing on it that could
  never be wrong because it was never right. That is the same defect
  `Kati.Screens.Day` fixed one screen along, and the fix has the same shape.

  ## No date still means the drawn day, and must

  52 is reachable without one — `Kati.Screens.Gallery` opens it bare and every
  sweep mounts it with `%{}` — and that is the state
  `test/design/screens/52.html` was captured in: eight expanded rows, five of
  them meals, then the collapsed summary underneath. **That branch asks the
  database nothing**, which is what keeps the empty-database sweep rendering
  the drawing rather than a page that merely happens to be empty.

  ## Today with nothing stored is the drawn day

  `Kati.Screens.Day.day/1` makes exactly this exception and states why at
  length: the routes in are taps on screens that have already drawn today from
  their own rows, and two screens one tap apart must not disagree about one
  date. Any other empty date renders empty, because that is the honest answer
  and the one screen 02 already gives for every date but today.
  """
  @spec day(map() | nil) :: map()
  def day(params) do
    case Map.get(params || %{}, :date) do
      %Date{} = date -> handed(date)
      _no_date -> drawn_day()
    end
  end

  @doc """
  Screen 52 exactly as `test/design/screens/52.html` draws it.

  `drawn?` is stamped on here rather than inside `Kati.Calendar.SampleMealDay`,
  so the fixture stays a transcription of the board and the flag stays this
  screen's own bookkeeping.
  """
  @spec drawn_day() :: map()
  def drawn_day, do: Map.put(SampleMealDay.day(), :drawn?, true)

  defp handed(date) do
    case spine(date) do
      [] -> if date == Kati.Time.today(), do: drawn_day(), else: empty(date)
      rows -> stored_day(date, rows)
    end
  end

  # A day the user opened that holds nothing renders as a day that holds
  # nothing. The collapsed summary and the note go with it: the note is the
  # design's caption about density and the summary is a summary of no meals, so
  # both would be furniture invented over an empty day. The same call
  # `Kati.Screens.Day` makes about its all-day band and its headline.
  defp empty(date) do
    %{
      title: Calendar.strftime(date, "%a %-d %b"),
      subtitle: "NOTHING ON THIS DAY",
      chips: [{"All", nil}],
      rows: [],
      collapsed: nil,
      note: nil,
      drawn?: false
    }
  end

  defp stored_day(date, rows) do
    meals = Enum.filter(rows, &(Kati.Screens.MealsDay.kind(&1) == "Meals"))
    others = length(rows) - length(meals)

    %{
      title: Calendar.strftime(date, "%a %-d %b"),
      subtitle: "#{tally(length(meals), "meal")} · #{tally(others, "other item")}",
      chips: chips_for(rows),
      rows: rows,
      collapsed: collapsed_for(meals),
      note: nil,
      drawn?: false
    }
  end

  defp tally(1, noun), do: "1 #{noun}"
  defp tally(n, noun), do: "#{n} #{noun}s"

  # Only the sections that have something in them. A chip that empties the
  # spine is a control that looks broken, and the drawing never draws one.
  defp chips_for(rows) do
    counted =
      for label <- ~w(Meals Screen Personal),
          n = Enum.count(rows, &(Kati.Screens.MealsDay.kind(&1) == label)),
          n > 0,
          do: {label, "#{n}"}

    [{"All", nil} | counted]
  end

  # The same meals as one row — computed from them rather than invented,
  # because the density control folds the spine's meals into exactly this row
  # and the two must agree. No meals means nothing to collapse, and the block
  # is dropped rather than drawn as `0 meals · 0 kcal`.
  defp collapsed_for([]), do: nil

  defp collapsed_for(meals) do
    kcal = Enum.reduce(meals, 0, &(&2 + Map.get(&1, :kcal, 0)))
    eaten = Enum.count(meals, &(&1.check == :eaten))

    sub =
      case Enum.find(meals, &(&1.check == :todo)) do
        %{time: time} when time != "" -> "#{eaten} EATEN · NEXT AT #{time}"
        _none -> "#{eaten} EATEN"
      end

    %{rule: @meal, title: "#{tally(length(meals), "meal")} · #{kcal} kcal", sub: sub}
  end

  # The day's meals and everything else on the calendar, in one clock order —
  # which is the screen's whole claim, that meals need no lane of their own.
  defp spine(date) do
    Enum.sort_by(meal_rows(date) ++ event_rows(date), &{&1.time == "", &1.time})
  end

  defp meal_rows(date) do
    MealLog
    |> Ash.Query.for_read(:on_day, %{on: date})
    |> Ash.read!()
    |> Enum.map(fn log ->
      # A skipped meal has no calories, so printing a number would be a lie —
      # `Kati.Screens.MealsToday`'s own reasoning, and the reason it contributes
      # nothing to the collapsed row's total either.
      {state, check, sub, kcal} =
        case log.state do
          :eaten -> {:past, :eaten, "#{log.kcal} kcal", log.kcal}
          :skipped -> {:past, :none, "SKIPPED", 0}
          _planned -> {:live, :todo, "#{log.kcal} kcal", log.kcal}
        end

      %{
        time: clock(log.slot_time),
        rule: @meal,
        title: meal_title(log),
        sub: sub,
        state: state,
        check: check,
        kcal: kcal
      }
    end)
  rescue
    _error -> []
  end

  defp meal_title(log) do
    [log.slot_name, log.title]
    |> Enum.reject(&(is_nil(&1) or &1 == ""))
    |> Enum.join(" — ")
  end

  defp event_rows(date) do
    date
    |> Kati.Calendars.Today.rows()
    |> Enum.map(fn row ->
      %{
        time: row.time,
        rule: rule(row.kind),
        title: row.title,
        sub: row.meta,
        state: if(row.now?, do: :live, else: :past),
        check: :none
      }
    end)
  rescue
    _error -> []
  end

  # `@meal` and `@screen` are literals because `kind/1` matches a row's rule
  # against them and a pattern cannot hold a function call. The other two lanes
  # need no literal at all: a habit's green and an appointment's ink both fall
  # to `kind/1`'s catch-all, so they can be asked for by name — which is also
  # the only way the appointment stripe stays visible on near-black, `ink`
  # being `#F5F2EE` in dark where the fixture's `#1A1917` would vanish.
  defp rule(:air_date), do: @screen
  defp rule(:habit), do: Palette.green()
  defp rule(_kind), do: Palette.ink()

  defp clock(nil), do: ""
  defp clock(%Time{} = time), do: Calendar.strftime(time, "%H:%M")

  @doc false
  def content(assigns) do
    day = assigns.day
    filter = assigns.filter
    density = assigns.density
    rows = Kati.Screens.MealsDay.visible(day.rows, filter, density)

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {Kati.Screens.MealsDay.header(density)}
        {Kati.Screens.MealsDay.title(day)}
        {Kati.Screens.MealsDay.chips(day, filter)}
        {Kati.Screens.MealsDay.timeline(rows)}
        {Kati.Screens.MealsDay.collapse_eyebrow(day)}
        {Kati.Screens.MealsDay.collapsed(day)}
        {Kati.Screens.MealsDay.note(day)}
      </Column>
    </Scroll>
    """
  end

  # The back pill is drawn by Kati.Screens.Pushed over this content; this row
  # reserves its height and carries the density control opposite it.
  #
  # The glyph stays `density_medium` in both states — it is the drawing's, and
  # the disc says which state it is in by filling with ink, the same way every
  # selected chip on this screen does.
  @doc false
  def header(density) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Spacer weight={1.0} />
        {Kati.Screens.MealsDay.density_disc(density)}
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  The 44pt density control.

  `Kati.Components.MishkaActionIcon` — "a compact icon-only button" — which is
  exactly what this is: a square tap target holding one glyph, and the only
  control on the screen's chrome row. It became buildable this round, because
  the component now takes a `shadow`, and **a floating disc is defined by its
  shadow**: 52.html gives this one
  `0 1px 2px rgba(26,25,23,.05), 0 8px 16px -12px rgba(26,25,23,.5)`, which is
  `Kati.Theme.shadow_button/0`. Without it the disc is a flat patch of card
  white on paper rather than a button lifted off it.

  ## Why the pixels do not move

  `shape: :circle` resolves its radius as `size / 2` — 22.0, the number this
  wrote by hand, and `corner_radius` is read through `floatProp`, so 22.0 and
  22 are the same `22.dp`. With `variant: :filled` the fill is the caller's
  `background` rather than `:transparent`, and `shadow` and `on_tap` are
  merged onto the container only because they were passed — an omitted one is
  absent from the map rather than a JSON `null`. So the container is
  `%{width: 44, height: 44, align: :center, corner_radius: 22.0,
  background: background, shadow: …, on_tap: …}` — key for key the `Box` this
  used to write out.

  The one structural difference is that content passed as children is wrapped
  in a `<Row>`. That `Row` is layout-neutral here: it holds a single `Text`,
  so it measures exactly the glyph, and the container's `align: :center` then
  centres the `Row` where it used to centre the glyph.

  Both states are one call rather than two clauses, because the disc's shape,
  size and shadow never change — only which of the two colours is the fill and
  which the glyph, which is the drawing's own inversion.
  """
  def density_disc(density) do
    on? = density == :dense

    # `ink_fill`/`on_ink` when it is on: a control FILLED with ink, which screen
    # 28 inverts to a paper fill with an ink glyph. Off it is a card-white disc
    # on paper carrying an ink glyph, so `card`/`ink`.
    background = if on?, do: Palette.ink_fill(), else: Palette.card()
    color = if on?, do: Palette.on_ink(), else: Palette.ink()

    Kati.Components.MishkaActionIcon.action_icon(
      %{
        variant: :filled,
        shape: :circle,
        size: 44,
        background: background,
        shadow: Theme.shadow_button(),
        on_tap: {self(), :density}
      },
      [UI.symbol("density_medium", size: 21, color: color)]
    )
  end

  @doc false
  def title(day) do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={day.title}
        text_size={28}
        max_font_scale={1.6}
        font_weight="bold"
        letter_spacing={-0.03}
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer size={5} />
      <Text
        text={day.subtitle}
        font_family="mono"
        text_size={11}
        text_color={Palette.muted()}
        max_lines={1}
      />
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def chips(day, active) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {day.chips
         |> Enum.map(fn {label, count} -> Kati.Screens.MealsDay.chip(label, count, label == active) end)
         |> Enum.intersperse(Kati.Screens.MealsDay.chip_gap())}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc false
  def chip_gap, do: ~MOB"<Spacer size={7} />"

  @doc false
  def chip(label, count, on?) do
    # The tag carries the label, so one clause serves every chip and a new
    # section in the data needs no new code here.
    tap = {self(), String.to_atom("filter_" <> label)}
    background = if on?, do: Palette.ink_fill(), else: Palette.card()
    color = if on?, do: Palette.on_ink(), else: Palette.ink_soft()
    shadow = if on?, do: nil, else: Theme.shadow_card_soft()

    ~MOB"""
    <Row
      height={30}
      corner_radius={15}
      background={background}
      shadow={shadow}
      padding_left={13}
      padding_right={13}
      align="center"
      on_tap={tap}
    >
      <Text text={label} text_size={12} font_weight="semibold" text_color={color} max_lines={1} />
      {Kati.Screens.MealsDay.chip_count(count)}
    </Row>
    """
  end

  # The count is the label at 60% — `opacity:.6` on the same colour, which as
  # ARGB is the alpha, not a lighter grey.
  #
  # `count_idle` for BOTH states, because the drawing gives the count one value
  # and this function is not told which chip it is in. Splitting it into
  # `on_ink_count`/`count_idle` would put `0x99FBFAF8` on the selected chip,
  # which is not the literal 52.html draws — and light mode may not move.
  # 52.html's resting screen has `All` selected and `All` carries no count, so
  # the drawing never shows a count on ink; the pairing stays as drawn.
  @doc false
  def chip_count(nil), do: ~MOB"<Spacer size={0} />"

  def chip_count(count) do
    ~MOB"""
    <Row align="center">
      <Spacer size={6} />
      <Text
        text={count}
        font_family="mono"
        text_size={10}
        text_color={Palette.count_idle()}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc false
  def timeline(rows) do
    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(rows, fn row -> Kati.Screens.MealsDay.row(row) end)}
      <Spacer size={14} />
    </Column>
    """
  end

  @doc """
  Which section a spine row belongs to, read off its lane colour.

  The stripe is already the row's kind made visible — bronze for a meal,
  orange for Screen — so reading the chip back out of it means the filter and
  the stripe cannot drift apart. A habit's green and an appointment's ink both
  fall to `Personal`, which is the same bucket `Kati.Screens.Calendar.visible/2`
  puts them in.
  """
  @spec kind(map()) :: String.t()
  def kind(%{rule: @meal}), do: "Meals"
  def kind(%{rule: @screen}), do: "Screen"
  def kind(_row), do: "Personal"

  @doc """
  The spine rows a chip and the density control leave standing.

  `All` at comfortable density is every row, which is the drawing. Dense drops
  the meals, because the collapsed row beneath is already carrying them — that
  is what `Collapse meals` means, and with `Meals` also selected the spine
  empties entirely, which is honest: the five meals are all in the one row
  below.
  """
  @spec visible([map()], String.t(), atom()) :: [map()]
  def visible(rows, filter, density) do
    rows
    |> Enum.filter(fn row -> filter == "All" or Kati.Screens.MealsDay.kind(row) == filter end)
    |> Enum.reject(fn row -> density == :dense and Kati.Screens.MealsDay.kind(row) == "Meals" end)
  end

  @doc false
  def row(row) do
    background = if row.state == :past, do: Palette.card_settled(), else: Palette.card()
    shadow = if row.state == :past, do: nil, else: Theme.shadow_card_soft()
    color = if row.state == :past, do: Palette.settled_ink(), else: Palette.ink()

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column width={44} padding_top={13}>
          <Text
            text={row.time}
            font_family="mono"
            text_size={12}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
        <Spacer size={12} />
        <Box weight={1.0}>
          <Row
            fill_width={true}
            background={background}
            corner_radius={17}
            shadow={shadow}
            padding_left={13}
            padding_right={13}
            padding_top={12}
            padding_bottom={12}
            align="center"
          >
            <Box width={3} height={34} corner_radius={2} background={row.rule} />
            <Spacer size={11} />
            <Column weight={1.0}>
              <Text
                text={row.title}
                text_size={13}
                font_weight="semibold"
                text_color={color}
                max_lines={1}
              />
              <Spacer size={4} />
              <Text
                text={row.sub}
                font_family="mono"
                text_size={10.5}
                text_color={Palette.tertiary()}
                max_lines={1}
              />
            </Column>
            {Kati.Screens.MealsDay.check(row.check)}
          </Row>
        </Box>
      </Row>
      <Spacer size={8} />
    </Column>
    """
  end

  # In a Row, after the text. As a sibling inside the Box it would stack over
  # the title instead of sitting beside it.
  @doc false
  def check(:none), do: ~MOB"<Spacer size={0} />"

  def check(:eaten) do
    ~MOB"""
    <Row align="center">
      <Spacer size={11} />
      {Kati.Screens.MealsDay.ring(:eaten)}
    </Row>
    """
  end

  def check(:todo) do
    ~MOB"""
    <Row align="center">
      <Spacer size={11} />
      {Kati.Screens.MealsDay.ring(:todo)}
    </Row>
    """
  end

  @doc """
  The 24pt disc that says whether a meal has been logged.

  Both states are `Kati.Components.MishkaThemeIcon` — "a themed container
  around exactly one icon", and a 24pt disc holding a `check` is nothing else.
  Neither could be built before this round: 52.html draws **both** rings with
  a 1.5pt border, and `theme_icon/2` used to paint a border only under
  `variant: :outline`, which forfeits the fill and hard-codes the width at 1.
  `border_color` and `border_width` are now caller overrides on any variant,
  so the fill and the hairline can be asked for together and the hairline can
  be 1.5.

  ## Why the pixels do not move

  Neither call passes an `id`, an `icon` or an `on_tap`, so the id markers,
  the glyph shorthand and the handler are all skipped, and `:filled` and
  `:subtle` both contribute an empty gradient layer.

  `:eaten` is `variant: :filled` with `color` and `border_color` set to the
  same `#4E9A73` the drawing gives it (`border:1.5px solid #4E9A73;
  background:#4E9A73`), so the container is `%{width: 24, height: 24,
  align: :center, corner_radius: 12, background: Palette.green(),
  border_color: Palette.green(), border_width: 1.5}` — key for key the `Box`
  this wrote by hand — holding the same 14pt `check`.

  `:todo` is `variant: :subtle`, whose skin is no background and no border, so
  the only fill-related keys on the node are the two overrides:
  `%{width: 24, height: 24, align: :center, corner_radius: 12,
  border_color: Palette.border(), border_width: 1.5}`. `put_some/3` drops a nil
  background rather than writing one, which matters — the drawing says
  `background:transparent`, and a `nil` would serialise as a JSON null for the
  bridge to read. The `align: :center` the component adds is the one key the
  hand-rolled node lacked, and it is a no-op on a box with no children: the
  drawing puts a fully transparent `check` in this ring, which is a way of
  reserving space in CSS rather than a mark anyone sees, so nothing is centred
  here.
  """
  def ring(:eaten) do
    # `0xFFFBFAF8` LEFT AS A LITERAL. `Kati.Theme.Palette` names four meanings
    # for this value — the card, a label on an ink fill, the FAB's plus, and a
    # title over artwork — and this is none of them: it is a glyph on a HUE.
    # Green is `:hue`, unchanged in dark, so a tick that followed the mode would
    # turn to ink on a ring that never darkened. The two tokens that keep this
    # value in dark are scoped to a photographic ground (`on_media`) or to the
    # FAB, so neither is honestly this. Left, and reported: the table has no
    # "on a hue fill" row.
    Kati.Components.MishkaThemeIcon.theme_icon(
      %{
        variant: :filled,
        color: Palette.green(),
        size: 24,
        radius: 12,
        border_color: Palette.green(),
        border_width: 1.5
      },
      [Kati.UI.symbol("check", size: 14, color: 0xFFFBFAF8)]
    )
  end

  def ring(:todo) do
    Kati.Components.MishkaThemeIcon.theme_icon(%{
      variant: :subtle,
      size: 24,
      radius: 12,
      border_color: Palette.border(),
      border_width: 1.5
    })
  end

  # Kati.UI.eyebrow's dash is always the accent, and orange here would claim
  # the collapsed meals are new. The design draws this one #C4BDB3.
  @doc false
  def muted_eyebrow(label) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        <Box width={13} height={2} corner_radius={1} background={Palette.rail_idle()} />
        <Spacer size={9} />
        <Text
          text={String.upcase(label)}
          font_family="mono"
          text_size={10.5}
          letter_spacing={0.16}
          text_color={Palette.eyebrow()}
        />
      </Row>
      <Spacer size={11} />
    </Column>
    """
  end

  # The eyebrow labels the row beneath it, so it goes when that row goes. A
  # heading over nothing is worse than no heading.
  @doc false
  def collapse_eyebrow(%{collapsed: nil}), do: ~MOB"<Spacer size={0} />"
  def collapse_eyebrow(_day), do: Kati.Screens.MealsDay.muted_eyebrow("Collapse meals")

  # The `expand_more` chevron is the density control's other face and does the
  # same thing, under its own name: the same tag on both made the disc and the
  # row one accessibility_id, and `onNodeWithTag` throws on the second match
  # (#97). The glyph does not flip with the state: the drawing draws it
  # pointing down, and the drawing is the resting screen.
  @doc false
  def collapsed(%{collapsed: nil}), do: ~MOB"<Spacer size={0} />"

  def collapsed(day) do
    collapsed = day.collapsed
    tap = {self(), :density_collapsed}

    ~MOB"""
    <Row
      fill_width={true}
      background={Palette.card()}
      corner_radius={18}
      shadow={Theme.shadow_card_soft()}
      padding_left={14}
      padding_right={14}
      padding_top={13}
      padding_bottom={13}
      align="center"
      on_tap={tap}
    >
      <Box width={3} height={36} corner_radius={2} background={collapsed.rule} />
      <Spacer size={12} />
      <Column weight={1.0}>
        <Text
          text={collapsed.title}
          text_size={13}
          font_weight="bold"
          text_color={:on_surface}
          max_lines={1}
        />
        <Spacer size={4} />
        <Text
          text={collapsed.sub}
          font_family="mono"
          text_size={10.5}
          text_color={Palette.muted()}
          max_lines={1}
        />
      </Column>
      <Spacer size={12} />
      {UI.symbol("expand_more", size: 19, color: Palette.ink_soft())}
    </Row>
    """
  end

  # The note is the design's caption — an argument about the drawing rather
  # than a fact about anyone's day — so a stored day does not carry one.
  @doc false
  def note(%{note: nil}), do: ~MOB"<Spacer size={0} />"

  def note(day) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={13} />
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        {UI.symbol("info", size: 15, color: Palette.tertiary())}
        <Spacer size={8} />
        <Text
          text={day.note}
          text_size={11.5}
          line_height={1.45}
          text_color={Palette.sub()}
          weight={1.0}
        />
      </Row>
    </Column>
    """
  end

  @impl true
  def handle_tap(tag, socket) when tag in [:density, :density_collapsed] do
    next = if socket.assigns.density == :dense, do: :comfortable, else: :dense
    {:noreply, Mob.Socket.assign(socket, :density, next)}
  end

  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "filter_" <> label -> {:noreply, Mob.Socket.assign(socket, :filter, label)}
      _ -> {:noreply, socket}
    end
  end
end
