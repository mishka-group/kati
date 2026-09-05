defmodule Kati.Screens.MealsToday do
  @moduledoc """
  Screen 43 — Today, pushed under Health.

  Built to `test/design/screens/43.html`. The design's own caption says
  what this screen is: *"The day reads like the schedule screen because it is
  the same component: time gutter, one card per item, the next one lifted."*
  So the 44pt time column, the card per meal and the lift on the next thing
  are not choices made here — they are screen 02's, reused, which is the whole
  argument for meals not needing a lane of their own.

  Three states are drawn, and they are genuinely different cards rather than
  one card with a flag:

    * `:eaten` — flat `#F4F1EC`, no shadow, text dropped to `#9C958B`, and a
      filled green ring. It is done; it should stop asking for attention.
    * `:skipped` — no photograph at all, an outline instead of a fill, and
      `SKIPPED` where the calories were. A skipped meal has no calories, so
      showing a number would be a lie.
    * `:next` — lifted on the day's heaviest shadow, a 3pt accent rule, a
      larger photograph, and its three actions inline.

  ## Where this diverges from the drawing

    * **The dashed outline on the skipped card is solid.** `1.5px dashed
      rgba(26,25,23,.14)` has no dashed equivalent on this bridge, so it is a
      1.5pt solid edge at the same colour — the same trade `Kati.Screens.Health`
      records for its unbuilt tiles.
    * **The next card's 3pt rule is a declared 52pt.** It is `align-self:
      stretch` in the drawing; nothing measures geometry here, and 52 is the
      photograph's height, which is what sets the row's height.

  ## Where the data comes from

  `Kati.Meals`, through `day/1`: the active plan names the pill, its slots for
  today's weekday are merged with the day's `Kati.Meals.MealLog` rows into the
  timeline, and the week strip counts the same slots a day at a time. With no
  active plan the whole screen falls back to `Kati.Meals.SampleToday` — see
  `day/1` for why that gate is one question rather than seven.

  Two blocks are **not** domain data, and are named here rather than left to be
  discovered:

    * **The four quick tiles** are navigation. There is no resource behind an
      icon and a destination.
    * **The prep card is still the drawing's.** *"Soak the oats, thaw the
      chicken"* is an instruction, and *"2 need prep"* counts the meals that
      have one. `Kati.Meals.Recipe` stores a method, a duration and an oven
      temperature, and nothing that says a step belongs to the night before. So
      the card stays on `Kati.Meals.SampleToday.prep/0` rather than being faked
      out of `minutes`: a wrong instruction the evening before a meal is worse
      than a drawn one.

  No dock on a pushed screen, so the frame ends at 40 rather than 132.
  """
  use Kati.Screens.Pushed, back: "Health"

  require Ash.Query

  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaPill
  alias Kati.Meals.MealLog
  alias Kati.Meals.MealPlanSlot
  alias Kati.Meals.Nutrition
  alias Kati.Meals.Recipe
  alias Kati.Meals.SampleToday, as: Sample
  alias Kati.Theme
  alias Kati.Theme.Palette
  alias Kati.UI

  @impl true
  def load(socket),
    do: Mob.Socket.assign(socket, day: day(Kati.Time.today()), menu?: false)

  @doc false
  def content(assigns) do
    day = assigns.day

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {Kati.Screens.MealsToday.header(assigns.menu?)}
        {Kati.Screens.MealsToday.title(day)}
        {Kati.Screens.MealsToday.week_strip(day.week)}
        {Kati.Screens.MealsToday.tiles()}
        {UI.eyebrow(day.intake_line)}
        {Kati.Screens.MealsToday.macro_card(day)}
        {Kati.Screens.MealsToday.timeline(day.meals)}
        {UI.eyebrow("Tomorrow — needs prep tonight")}
        {Kati.Screens.MealsToday.prep()}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The day this screen draws: the active plan's own, or the drawing's.

  `Kati.Meals` answers with the device's own plan, and a device that has never
  been given one answers with nothing — which would draw an empty timeline, an
  empty week strip and a macro bar with no segments where the design draws five
  meals and a 31/44/25 split. FIDELITY's rule covers exactly that: *missing
  data is not a reason for a blank screen*, and it is the same fallback
  `Kati.Screens.Calendar.day_rows/1` already makes for a day with no events.

  The gate is one question asked once — **is there an active plan with anything
  on it?** — rather than a fallback per block, because a screen half drawn from
  the drawing and half from the database is a screen nobody can compare with
  either. With a plan, every figure below is the user's own; with none, all of
  them are `Kati.Meals.SampleToday`'s.
  """
  @spec day(Date.t()) :: map()
  def day(date) do
    with plan when not is_nil(plan) <- active_plan(),
         slots = plan_slots(plan),
         logs = logs_on(date),
         true <- slots != %{} or logs != [] do
      planned_day(plan, date, slots, logs)
    else
      _ -> drawn_day()
    end
  end

  @doc """
  Screen 43 exactly as `test/design/screens/43.html` draws it.

  Stand-in data, and marked as such — `Kati.Meals.SampleToday` is what the
  frame was captured from, so it is both the fallback and the fixture, and
  deleting it would leave the drawing with nothing to be compared against.
  """
  @spec drawn_day() :: map()
  def drawn_day do
    %{
      plan: Sample.plan(),
      day_line: Sample.day_line(),
      week: Sample.week(),
      intake_line: Sample.intake_line(),
      macros: Sample.macros(),
      remaining: Sample.remaining(),
      meals: Sample.meals()
    }
  end

  defp planned_day(plan, date, slots, logs) do
    meals = timeline_rows(Map.get(slots, Date.day_of_week(date), []), logs)
    intake = logs |> Enum.filter(&(&1.state == :eaten)) |> Nutrition.sum()
    target = plan.target_kcal || 0

    %{
      plan: plan.name,
      day_line: day_line(date, length(meals)),
      week: week(date, slots, logs),
      intake_line: intake_line(intake.kcal, target),
      macros: macro_split(intake),
      remaining: remaining(intake.kcal, target),
      meals: meals
    }
  end

  # The day in clock order: the plan's slots for this weekday, with a log laid
  # over any slot that has one, plus every log that belongs to no slot at all —
  # an ad-hoc `log_manual` meal is still a meal that was eaten today.
  defp timeline_rows(slots, logs) do
    by_slot =
      logs
      |> Enum.filter(& &1.meal_plan_slot_id)
      |> Map.new(&{&1.meal_plan_slot_id, &1})

    from_slots =
      slots
      |> Enum.map(fn slot ->
        case Map.fetch(by_slot, slot.id) do
          {:ok, log} -> log_row(log)
          :error -> slot_row(slot)
        end
      end)
      |> Enum.reject(&is_nil/1)

    slot_ids = MapSet.new(slots, & &1.id)

    loose =
      logs
      |> Enum.reject(&(&1.meal_plan_slot_id && MapSet.member?(slot_ids, &1.meal_plan_slot_id)))
      |> Enum.map(&log_row/1)

    Enum.sort_by(from_slots ++ loose, &{&1.time == "", &1.time})
  end

  # `:next` is not a state on `Kati.Meals.MealLog` and is not meant to be — its
  # moduledoc calls it "a fact about the clock rather than about a row". Both
  # things that are true of an upcoming meal reduce to it: a slot with no log
  # yet, and a `:planned` log, which is what screen 46's *"swap just today"*
  # writes. Neither has been eaten or skipped, and the drawing has exactly one
  # card for that.
  defp slot_row(%MealPlanSlot{state: :planned, recipe: %Recipe{} = recipe} = slot) do
    %{
      state: :next,
      time: clock(slot.slot_time),
      slot: slot.slot_name,
      title: recipe.title,
      calories: "#{Nutrition.scale(recipe_figures(recipe), slot.portion_milli).kcal} kcal",
      seed: recipe.photo_seed,
      # Carried so **Mark eaten** can write. The row used to hold only what the
      # card draws, so the button had nothing to write about and did nothing at
      # all — and because a day can hold three upcoming meals, a bare
      # `:mark_eaten` tag would have been ambiguous even once it did.
      slot_id: slot.id,
      recipe_id: recipe.id,
      portion_milli: slot.portion_milli,
      plan_id: slot.meal_plan_id,
      slot_time: slot.slot_time,
      slot_name: slot.slot_name
    }
  end

  # A `:free` or `:open` cell is not a meal, and a `:planned` slot with nothing
  # decided for it yet has no title to draw. Both are absent from the timeline
  # rather than drawn as a blank card; the week strip still counts them.
  defp slot_row(_slot), do: nil

  defp log_row(log) do
    %{
      state: card_state(log.state),
      time: clock(log.slot_time),
      slot: log.slot_name || "",
      title: log.title,
      calories: calories(log),
      seed: photo_seed(log.recipe),
      # The row names itself, and the comment that used to sit here was wrong in
      # a way three separate probes found.
      #
      # It said: *a logged meal has already been decided, so there is nothing
      # for Mark eaten to write — `meal_card/1` only draws the button on a
      # `:next` card.* The second half is the false part. `card_state/1` answers
      # `:next` for anything that is not `:eaten` or `:skipped`, and a
      # `:planned` log is exactly that — it is what screen 46's *swap just
      # today* writes. So a swapped meal draws as upcoming, draws **Mark eaten**
      # and **Swap**, and with the ids blanked neither button could name the row
      # under it: `Mark eaten` found nothing and did nothing, and `Swap` handed
      # over whatever `Mob.State` happened to be holding.
      #
      # Blanked ids are not a way to make a control unreachable. If a card must
      # not offer a write, the card decides that; a row that exists tells the
      # truth about which row it is.
      slot_id: log.meal_plan_slot_id,
      recipe_id: log.recipe_id,
      portion_milli: log.portion_milli,
      plan_id: log.meal_plan_id,
      slot_time: log.slot_time,
      slot_name: log.slot_name
    }
  end

  defp card_state(:eaten), do: :eaten
  defp card_state(:skipped), do: :skipped
  defp card_state(_planned), do: :next

  # A skipped meal has no calories, so printing a number would be a lie — the
  # drawing's own reasoning, and the reason the figures are frozen anyway.
  defp calories(%{state: :skipped}), do: "SKIPPED"
  defp calories(log), do: "#{log.kcal} kcal"

  # The snapshot carries no photograph — `Kati.Meals.MealLog` freezes figures,
  # and a seed is not one. It comes through `recipe_id`, which is provenance
  # and may be nil, and `Kati.Screens.MealsToday.thumb/3` draws the placeholder
  # when it is.
  defp photo_seed(%Recipe{photo_seed: seed}), do: seed
  defp photo_seed(_), do: nil

  defp recipe_figures(recipe) do
    Map.new(Nutrition.fields(), fn field -> {field, Map.fetch!(recipe, :"total_#{field}")} end)
  end

  # Five pips per day, filled first then hollow — the drawing's own shorthand:
  # *"a day with four planned meals and one free evening reads as four filled
  # pips and one hollow"*. It is a count, not a slot-by-slot map, which is why
  # Wednesday's free 10:30 draws its hollow pip last rather than second.
  #
  # Today is the one day read from the log rather than from the plan, because
  # today is the only day that has already happened: three green means three
  # eaten, and the skipped 16:00 and the unstarted 19:30 are both still hollow.
  defp week(date, slots, logs) do
    eaten = Enum.count(logs, &(&1.state == :eaten))
    monday = Date.add(date, -(Date.day_of_week(date) - 1))

    Enum.map(0..6, fn offset ->
      on = Date.add(monday, offset)
      day_slots = Map.get(slots, Date.day_of_week(on), [])

      %{
        dow: Calendar.strftime(on, "%a"),
        day: Calendar.strftime(on, "%-d"),
        today?: on == date,
        dots: dots(day_slots, on == date, eaten)
      }
    end)
  end

  defp dots(slots, true, eaten) do
    filled = min(eaten, length(slots))

    List.duplicate(Palette.green(), filled) ++
      List.duplicate(Palette.star_empty(), length(slots) - filled)
  end

  defp dots(slots, false, _eaten) do
    planned = Enum.count(slots, &(&1.state == :planned))

    List.duplicate(Palette.rail_idle(), planned) ++
      List.duplicate(Palette.star_empty(), length(slots) - planned)
  end

  defp day_line(date, 1), do: Calendar.strftime(date, "%A %-d %B") <> " · 1 meal"
  defp day_line(date, count), do: Calendar.strftime(date, "%A %-d %B") <> " · #{count} meals"

  defp intake_line(kcal, 0), do: "Today · #{group(kcal)} kcal"
  defp intake_line(kcal, target), do: "Today · #{group(kcal)} of #{group(target)} kcal"

  defp remaining(_kcal, 0), do: ""
  defp remaining(kcal, target), do: "#{group(max(target - kcal, 0))} kcal left"

  # The drawing declares 31/44/25 rather than deriving it, and says so. What is
  # derived here is the same three shares from the same three macros, by the
  # energy each contributes — 4 kcal a gram of protein and of carbohydrate,
  # 9 a gram of fat — which is the only reading under which the segments add up
  # to the intake the eyebrow above states.
  defp macro_split(figures) do
    protein = div(figures.protein_mg, 1000) * 4
    carbs = div(figures.carbs_mg, 1000) * 4
    fat = div(figures.fat_mg, 1000) * 9
    total = protein + carbs + fat

    [
      {"Protein", share(protein, total), Palette.ink()},
      {"Carbs", share(carbs, total), Palette.bronze()},
      {"Fat", share(fat, total), Palette.bar_gold()}
    ]
  end

  defp share(_part, 0), do: 0.0
  defp share(part, total), do: Float.round(part / total, 2)

  defp clock(nil), do: ""
  defp clock(time), do: Calendar.strftime(time, "%H:%M")

  # `1,480`, never `1480`. Written here rather than taken from `Cldr.Number`
  # because this screen's figures are the drawing's ASCII ones in every locale
  # — the Persian meals screens are 60 and their own module.
  defp group(number) do
    number
    |> Integer.to_string()
    |> String.reverse()
    |> String.replace(~r/(\d{3})(?=\d)/, "\\1,")
    |> String.reverse()
  end

  defp active_plan do
    case Kati.Meals.MealPlan |> Ash.Query.for_read(:active) |> Ash.read_one() do
      {:ok, plan} -> plan
      _ -> nil
    end
  rescue
    _ -> nil
  end

  defp plan_slots(plan) do
    MealPlanSlot
    |> Ash.Query.filter(meal_plan_id == ^plan.id)
    |> Ash.Query.sort(day_of_week: :asc, position: :asc)
    |> Ash.Query.load(:recipe)
    |> Ash.read!()
    |> Enum.group_by(& &1.day_of_week)
  rescue
    _ -> %{}
  end

  defp logs_on(date) do
    MealLog
    |> Ash.Query.for_read(:on_day, %{on: date})
    |> Ash.Query.load(:recipe)
    |> Ash.read!()
  rescue
    _ -> []
  end

  # `Kati.Screens.Pushed` floats the ‹ Health pill over this content. This row
  # reserves its height and carries the week button opposite it.
  @doc false
  def header(menu?) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Spacer weight={1.0} />
        {Kati.Screens.MealsToday.menu(menu?)}
        <Spacer size={9} />
        {Kati.Screens.MealsToday.week_button()}
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  # `Kati.Components.MishkaActionIcon` — an icon-only button on a raised
  # surface, which is what this is. It could not be one until the component
  # took a `shadow`: a floating disc is DEFINED by its shadow, and a
  # `variant: :filled` without one is a flat patch of `#FBFAF8` on `#EFECE7`
  # paper, which is nearly the same colour.
  #
  # `shape: :circle` is an exact `size / 2` — 44 gives the 22 written here
  # before. The glyph is a child rather than `icon:` because Kati's icons are
  # Material Symbols through `Kati.UI.symbol/2`, a `Text` in the `symbols`
  # family, not the component's own `:lg` Text. A child is wrapped in a `<Row>`
  # that hugs it, inside a Box that already centred it, so the glyph does not
  # move.
  @doc """
  The ⋯ disc and the one screen behind it.

  Added to screen 43's header, which the drawing does not draw. The ⋯ that IS
  drawn on 43 belongs to the next meal's card — it sits beside that meal's
  title and calorie count — so wiring it here would make a per-meal control do
  something section-wide. Screen 51's own moduledoc checks all seven sibling
  drawings glyph by glyph and concludes the entry point is missing from the
  design rather than from the code; this supplies it.
  """
  def menu(open?) do
    trigger =
      MishkaActionIcon.action_icon(
        [
          size: 44,
          shape: :circle,
          variant: :filled,
          background: Palette.card(),
          shadow: Theme.shadow_button(),
          on_tap: :toggle_menu
        ],
        [UI.symbol("more_horiz", size: 21)]
      )

    Kati.UI.Menu.overflow(
      trigger,
      open?,
      [Kati.UI.Menu.item("notifications", "Reminders", :open_reminders)],
      dismiss: :close_menu
    )
  end

  @doc false
  def week_button do
    MishkaActionIcon.action_icon(
      [
        size: 44,
        shape: :circle,
        variant: :filled,
        # `card`, not `on_ink` / `fab_glyph` / `on_media` — the other three
        # meanings `Kati.Theme.Palette` gives `0xFFFBFAF8`. A floating disc is a
        # surface above the page, so it follows the ground into `#1E1D1B`.
        background: Palette.card(),
        shadow: Theme.shadow_button(),
        on_tap: :open_week_disc
      ],
      [UI.symbol("calendar_view_week", size: 21)]
    )
  end

  @doc false
  def title(day) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="bottom">
        <Column weight={1.0}>
          <Text
            text="Today"
            text_size={28}
            max_font_scale={1.6}
            font_weight="bold"
            letter_spacing={-0.03}
            text_color={:on_surface}
          />
          <Spacer size={5} />
          <Text
            text={day.day_line}
            font_family="mono"
            text_size={11}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
        <Spacer size={12} />
        {Kati.Screens.MealsToday.plan_pill(day.plan)}
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  # Orange here is the plan that is running *now*, which is the one meaning the
  # accent is allowed to carry.
  @doc false
  def plan_pill(plan) do
    tap = {self(), :switch_plan}

    ~MOB"""
    <Row
      height={36}
      corner_radius={18}
      background={Palette.card()}
      shadow={Kati.Theme.shadow_button()}
      padding_left={13}
      padding_right={13}
      align="center"
      on_tap={tap}
    >
      <Box width={7} height={7} corner_radius={4} background={Kati.Theme.accent()} />
      <Spacer size={7} />
      <Text text={plan} text_size={12.5} font_weight="bold" text_color={:on_surface} max_lines={1} />
      <Spacer size={7} />
      {Kati.UI.symbol("unfold_more", size: 16, color: Palette.sub())}
    </Row>
    """
  end

  @doc false
  def week_strip(week) do
    cells =
      week
      |> Enum.map(&day_cell/1)
      |> Enum.intersperse(day_gap())

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {cells}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc false
  def day_gap, do: ~MOB"<Spacer size={2} />"

  # Centring is done with weighted spacers inside full-width Rows, not with
  # text_align: a Text given text_align fills its parent's width on this
  # bridge, which is exactly what a flex-1 cell must not let it do.
  @doc false
  def day_cell(day) do
    # `transparent`, not `card_hairline` / `cream_hairline` — the other two
    # tokens that are `0x00FFFFFF` in light. Those two are hairlines dark ADDS;
    # this is a cell the drawing simply does not fill, and it stays unfilled in
    # both modes. `day_color` is `ink` rather than `ink_fill`: it is the day
    # number as text on a card, not a control filled with ink.
    background = if day.today?, do: Palette.card(), else: Palette.transparent()
    shadow = if day.today?, do: Theme.shadow_button(), else: nil
    dow_color = if day.today?, do: Palette.sub(), else: Palette.tertiary()
    day_color = if day.today?, do: Palette.ink(), else: Palette.sub()

    ~MOB"""
    <Box weight={1.0}>
      <Box
        fill_width={true}
        corner_radius={16}
        background={background}
        shadow={shadow}
        padding_top={9}
        padding_bottom={10}
        align="center"
      >
        <Column fill_width={true}>
          <Row fill_width={true} align="center">
            <Spacer weight={1.0} />
            <Text
              text={day.dow}
              font_family="mono"
              text_size={10}
              text_color={dow_color}
              max_lines={1}
            />
            <Spacer weight={1.0} />
          </Row>
          <Spacer size={4} />
          <Row fill_width={true} align="center">
            <Spacer weight={1.0} />
            <Text
              text={day.day}
              text_size={15}
              font_weight="bold"
              text_color={day_color}
              max_lines={1}
            />
            <Spacer weight={1.0} />
          </Row>
          <Spacer size={6} />
          <Row fill_width={true} align="center">
            <Spacer weight={1.0} />
            {day.dots |> Enum.map(&Kati.Screens.MealsToday.pip/1) |> Enum.intersperse(Kati.Screens.MealsToday.pip_gap())}
            <Spacer weight={1.0} />
          </Row>
        </Column>
      </Box>
    </Box>
    """
  end

  @doc false
  def pip_gap, do: ~MOB"<Spacer size={1.5} />"

  @doc false
  def pip(color) do
    ~MOB"""
    <Box width={3} height={3} corner_radius={2} background={color} />
    """
  end

  @doc false
  def tiles do
    tiles =
      Sample.tiles()
      |> Enum.map(fn {icon, label} -> tile(icon, label) end)
      |> Enum.intersperse(tile_gap())

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {tiles}
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def tile_gap, do: ~MOB"<Spacer size={8} />"

  @doc """
  Where each quick tile goes, keyed by its **icon** rather than its label.

  The icon is a Material Symbols identifier and is never translated; the label
  is display text and one day will be. Keying on the label would wire four
  live controls in English and four dead ones in every other locale, and the
  failure would be invisible — an unknown key yields no `on_tap`, and a Box
  with no `on_tap` is drawn exactly like one that has it.

  The destinations are the screens whose own drawing carries a `‹ Meals` back
  pill, which is what identifies them as the places Meals goes: 116 the
  library, 44 the repeating week, 48 Shopping, 47 Nutrition, 49 Plans. `tune`
  is the odd one only until you read 49 — a plan owns its meals, its targets
  and its reminder times, so "Plan" is the profile you pick, not the week you
  look at.
  """
  @tile_taps %{
    "grid_view" => :open_library,
    "calendar_view_week" => :open_week,
    "shopping_cart" => :open_shopping,
    "monitoring" => :open_nutrition,
    "tune" => :open_plan
  }

  @spec tile_taps() :: %{String.t() => atom()}
  def tile_taps, do: @tile_taps

  # Nothing here changes a resting pixel: the four tiles were already drawn
  # exactly like this, and `on_tap` adds a click target, not ink. What it fixes
  # is that three of the four destinations below already had a `handle_tap/2`
  # clause and no control ever sent the tag — `Kati.Screens.MealPlan`,
  # `Kati.Screens.Shopping` and `Kati.Screens.Nutrition` were reachable only
  # from `Kati.Screens.Gallery`, and the tiles that name them did nothing.
  @doc false
  def tile(icon, label) do
    # `Map.fetch!`, not `Map.get`: an icon with no entry would otherwise yield
    # `on_tap={nil}`, which the bridge drops without a word and draws as a tile
    # that looks identical and answers nothing. A raise here is caught by the
    # render sweep long before a device sees it.
    tap = {self(), Map.fetch!(@tile_taps, icon)}

    ~MOB"""
    <Box weight={1.0}>
      <Box
        fill_width={true}
        background={Palette.card()}
        corner_radius={16}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={8}
        padding_right={8}
        padding_top={11}
        padding_bottom={11}
        align="center"
        on_tap={tap}
      >
        <Column fill_width={true}>
          <Row fill_width={true} align="center">
            <Spacer weight={1.0} />
            {Kati.UI.symbol(icon, size: 18)}
            <Spacer weight={1.0} />
          </Row>
          <Spacer size={7} />
          <Row fill_width={true} align="center">
            <Spacer weight={1.0} />
            <Text
              text={label}
              text_size={11}
              font_weight="semibold"
              text_color={Palette.ink_soft()}
              max_lines={1}
            />
            <Spacer weight={1.0} />
          </Row>
        </Column>
      </Box>
    </Box>
    """
  end

  @doc false
  def macro_card(day) do
    macros = day.macros

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={15}
      >
        <Box fill_width={true} height={9} corner_radius={4.5} background={Palette.paper()}>
          <Row fill_width={true}>
            {Enum.map(macros, fn {_name, share, tone} -> Kati.Screens.MealsToday.segment(share, tone) end)}
          </Row>
        </Box>
        <Spacer size={11} />
        <Row fill_width={true} align="center">
          {macros |> Enum.map(fn {name, _share, tone} -> Kati.Screens.MealsToday.legend_key(name, tone) end) |> Enum.intersperse(Kati.Screens.MealsToday.legend_gap())}
          <Spacer weight={1.0} />
          <Text
            text={day.remaining}
            font_family="mono"
            text_size={10}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Row>
      </Column>
      <Spacer size={20} />
    </Column>
    """
  end

  # The drawing rounds the bar's ends with `overflow:hidden`. Mob does not clip
  # children, so the segments stay square inside a rounded track and the ink
  # one overhangs the 4.5pt corner by a hair — the same compromise screen 42
  # records, and preferable to per-segment radii, which open visible notches.
  #
  # Still hand-rolled for the reason `Kati.Screens.Health.macro_bar/1` sets out
  # at length: `Kati.Components.MishkaMeter` draws ONE fill in ONE colour over a
  # track, and this is three fills in three colours filling the track between
  # them. Its `render={:box}` mode has no segmented form and forwards no
  # `weight`, so neither the bar nor any single segment of it can be a meter.
  # 42 and 43 draw the same bar and want the same upstream change.
  #
  # A macro that contributed nothing draws nothing, rather than a segment of
  # zero weight: `weight` is a share of the leftover space, and asking for a
  # share of zero is a different question from asking for no width. The drawing
  # never asks it — 31/44/25 — and a day before breakfast asks it every
  # morning.
  @doc false
  def segment(share, _tone) when share == 0 do
    ~MOB"""
    <Spacer size={0} />
    """
  end

  def segment(share, tone) do
    ~MOB"""
    <Box weight={share} height={9} background={tone} />
    """
  end

  @doc false
  def legend_gap, do: ~MOB"<Spacer size={13} />"

  @doc false
  def legend_key(name, tone) do
    ~MOB"""
    <Row align="center">
      <Box width={7} height={7} corner_radius={2} background={tone} />
      <Spacer size={5} />
      <Text
        text={String.upcase(name)}
        font_family="mono"
        text_size={9.5}
        letter_spacing={0.08}
        text_color={Palette.eyebrow()}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc false
  def timeline(meals) do
    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(meals, fn meal -> Kati.Screens.MealsToday.meal_row(meal) end)}
    </Column>
    """
  end

  @doc """
  This meal's own tap tag.

  Every card on the timeline carried `:open_meal`, so `Mob.Renderer` stamped
  every card with the same `accessibility_id` and `onNodeWithTag` throws on the
  second match — the timeline was unaddressable on a device, not merely
  untested.

  ## Why the clock is in the tag and the slot alone is not

  The slot name is what a person reads off the card, so `meal_Breakfast_08:00`
  leads with it. It cannot stand alone: a day can hold two `Snack` rows, and
  the first draft of this function named both of them `meal_Snack` — the same
  defect one layer down, caught by the check above going red rather than by
  anybody noticing. The clock is what separates two cards a person would also
  tell apart by looking at.

      iex> Kati.Screens.MealsToday.meal_tag(%{slot: "Breakfast", time: "08:00"})
      :"meal_Breakfast_08:00"

      iex> Kati.Screens.MealsToday.meal_tag(%{slot: "", time: "19:30"})
      :"meal_19:30"
  """
  @spec meal_tag(map()) :: atom()
  # The slot's own id when the row has one, which every real row now does.
  #
  # The clause below builds the tag out of the slot word and the clock, and it
  # was not enough: a day can hold two `Snack` rows AT THE SAME TIME, and it
  # named both `meal_Snack_16:00` — so the second card opened the first, which
  # is the defect this whole phase is about, one layer down from the push. An
  # eaten card and the planned slot it came from collided the same way.
  #
  # `tag/2` has always keyed **Mark eaten** and **Swap** on the id; this brings
  # the card's own tap in line with them, and the two-nodes-one-name problem
  # goes with it. `log_row/1` blanking `slot_id` is what used to make this
  # impossible — see the note there.
  #
  # The word-and-clock form stays for the fixture, whose rows have no id, and it
  # is what `test/design/screens/43.html` is captured with.
  def meal_tag(%{slot_id: id}) when is_binary(id), do: String.to_atom("meal_" <> id)

  def meal_tag(meal) do
    slot = meal |> Map.get(:slot, "") |> to_string() |> String.trim() |> String.replace(" ", "_")
    time = meal |> Map.get(:time, "") |> to_string() |> String.trim()

    case {slot, time} do
      {"", ""} -> :open_meal
      {"", clock} -> String.to_atom("meal_" <> clock)
      {name, ""} -> String.to_atom("meal_" <> name)
      {name, clock} -> String.to_atom("meal_" <> name <> "_" <> clock)
    end
  end

  @doc false
  def meal_row(meal) do
    gutter_top = if meal.state == :next, do: 17, else: 15
    # `ink`, not `ink_fill`: the time is text on the page, not a filled control.
    gutter_color = if meal.state == :next, do: Palette.ink(), else: Palette.muted()
    gutter_weight = if meal.state == :next, do: "medium", else: "regular"

    tap = {self(), Kati.Screens.MealsToday.meal_tag(meal)}

    ~MOB"""
    <Column fill_width={true} on_tap={tap}>
      <Row fill_width={true} align="top">
        <Column width={44} padding_top={gutter_top}>
          <Text
            text={meal.time}
            font_family="mono"
            text_size={12}
            font_weight={gutter_weight}
            text_color={gutter_color}
            max_lines={1}
          />
        </Column>
        <Spacer size={12} />
        <Box weight={1.0}>
          {Kati.Screens.MealsToday.meal_card(meal)}
        </Box>
      </Row>
      <Spacer size={9} />
    </Column>
    """
  end

  # The tick sits on a GREEN disc, and the green is a hue: it does not move with
  # the mode. So `0xFFFBFAF8` is LEFT AS A LITERAL below — see the comment there.
  @doc false
  def meal_card(%{state: :eaten} = meal) do
    # `0xFFFBFAF8` LEFT AS A LITERAL. `Kati.Theme.Palette` names four meanings
    # for this value — the card, a label on an ink fill, the FAB's plus, and a
    # title over artwork — and this is none of them: it is a glyph on a HUE.
    # `green` is `:hue`, unchanged in dark, so a tick that took `on_ink` would
    # turn to ink on a disc that never darkened. The two tokens that keep the
    # value in dark are scoped to a photographic ground (`on_media`) or to the
    # FAB, so neither is honestly this. The table has no "on a hue fill" row;
    # `Kati.Screens.Habits.today_button/2` leaves the same value for the same
    # reason.
    tick = 0xFFFBFAF8

    ~MOB"""
    <Row
      fill_width={true}
      background={Palette.card_settled()}
      corner_radius={18}
      padding_left={13}
      padding_right={13}
      padding_top={11}
      padding_bottom={11}
      align="center"
    >
      {Kati.Screens.MealsToday.thumb(meal.seed, 40, 11)}
      <Spacer size={12} />
      <Column weight={1.0}>
        <Text
          text={String.upcase(meal.slot)}
          font_family="mono"
          text_size={9.5}
          letter_spacing={0.14}
          text_color={Palette.eyebrow()}
          max_lines={1}
        />
        <Spacer size={4} />
        <Text
          text={meal.title}
          text_size={13.5}
          font_weight="semibold"
          letter_spacing={-0.015}
          text_color={Palette.settled_ink()}
          max_lines={1}
        />
        <Spacer size={4} />
        <Text
          text={meal.calories}
          font_family="mono"
          text_size={10.5}
          text_color={Palette.muted()}
          max_lines={1}
        />
      </Column>
      <Spacer size={12} />
      <Box
        width={27}
        height={27}
        corner_radius={16}
        background={Palette.green()}
        border_width={1.5}
        border_color={Palette.green()}
        align="center"
      >
        {Kati.UI.symbol("check", size: 16, color: tick)}
      </Box>
    </Row>
    """
  end

  # No photograph, no fill: a skipped meal is an outline of the meal that was
  # planned. The drawing dashes that outline and this bridge cannot.
  #
  # Its three faint marks are `rail_idle` for their VALUE, not their name: the
  # token whose meaning is "a faint chevron / an idle glyph" is `tertiary`, and
  # its light value is `0xFFB3ACA2` where these are `0xFFC4BDB3`. The design
  # draws two faint greys and only one of them is `tertiary`. Taking the better
  # name would move light mode eleven units, so the value wins — the same trade
  # `Kati.UI.SettingsList.chevron/0` records.
  def meal_card(%{state: :skipped} = meal) do
    ~MOB"""
    <Row
      fill_width={true}
      corner_radius={18}
      border_width={1.5}
      border_color={Palette.border_soft()}
      padding_left={13}
      padding_right={13}
      padding_top={11}
      padding_bottom={11}
      align="center"
    >
      <Column weight={1.0}>
        <Text
          text={String.upcase(meal.slot)}
          font_family="mono"
          text_size={9.5}
          letter_spacing={0.14}
          text_color={Palette.rail_idle()}
          max_lines={1}
        />
        <Spacer size={4} />
        <Text
          text={meal.title}
          text_size={13.5}
          font_weight="semibold"
          letter_spacing={-0.015}
          text_color={Palette.tertiary()}
          max_lines={1}
        />
        <Spacer size={4} />
        <Text
          text={meal.calories}
          font_family="mono"
          text_size={10.5}
          text_color={Palette.rail_idle()}
          max_lines={1}
        />
      </Column>
      <Spacer size={12} />
      <Box
        width={27}
        height={27}
        corner_radius={16}
        border_width={1.5}
        border_color={Palette.border()}
        align="center"
      >
        {Kati.UI.symbol("close", size: 16, color: Palette.rail_idle())}
      </Box>
    </Row>
    """
  end

  # The empty tick in the ring is `track_ink` — right by value, and the one part
  # of the name that is wrong. `0x381A1917` has exactly one row in
  # `Kati.Theme.Palette` and it is called a track because that is where the
  # design's other 22% ink appears; what matters is that it is the same ink-tint
  # ladder the ring's own `border` sits on, so both take the alpha swap in dark
  # and the ring keeps a mark inside it. Left as the literal it would be 22%
  # black on a `#1E1D1B` card — a tick that renders as nothing.
  def meal_card(%{state: :next} = meal) do
    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={18}
      shadow="0 1 2 0 #0D1A1917 | 0 16 30 -18 #BF1A1917"
      padding={14}
    >
      <Row fill_width={true} align="center">
        <Box width={3} height={52} corner_radius={2} background={Kati.Theme.accent()} />
        <Spacer size={12} />
        {Kati.Screens.MealsToday.thumb(meal.seed, 52, 13)}
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text
            text={String.upcase(meal.slot)}
            font_family="mono"
            text_size={9.5}
            letter_spacing={0.14}
            text_color={Palette.eyebrow()}
            max_lines={1}
          />
          <Spacer size={4} />
          <Text
            text={meal.title}
            text_size={15}
            font_weight="bold"
            letter_spacing={-0.015}
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={4} />
          <Text
            text={meal.calories}
            font_family="mono"
            text_size={10.5}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
        <Spacer size={12} />
        <Box
          width={32}
          height={32}
          corner_radius={16}
          border_width={1.5}
          border_color={Palette.border()}
          align="center"
        >
          {Kati.UI.symbol("check", size: 19, color: Palette.track_ink())}
        </Box>
      </Row>
      <Spacer size={13} />
      <Row fill_width={true} padding_left={15} align="center">
        {Kati.Screens.MealsToday.action("Mark eaten", :ink, Kati.Screens.MealsToday.tag("mark_eaten", meal))}
        <Spacer size={8} />
        {Kati.Screens.MealsToday.action("Swap", :paper, Kati.Screens.MealsToday.tag("swap", meal))}
        <Spacer size={8} />
        {Kati.Screens.MealsToday.overflow()}
      </Row>
    </Column>
    """
  end

  @doc """
  A per-meal tap tag, or the bare one when the row cannot be written about.

  A day holds up to three upcoming meals and the card is drawn once per meal,
  so `:mark_eaten` on its own named none of them: whichever handler ran would
  have had to guess. The slot's id makes each button address its own row, which
  is also what stops two cards sharing an `accessibility_id` — the thing
  `Kati.ScreenTapSweepTest` exists to catch.

  **Both buttons on the lifted card go through here.** `Mark eaten` did from
  the day it learned to write; `Swap` did not, and stayed `:swap` on every card
  until 2026-09-05 — so a day with lunch and dinner still ahead drew two Swap
  buttons under one name, and `handle_tap(:swap, …)` resolved them by taking
  the first upcoming meal it could find. Tapping dinner's swapped the lunch.
  One prefix, one rule, and neither button can now reach a row the reader was
  not pressing.

  The drawing's own fallback keeps the bare tag. `Kati.Meals.SampleToday` rows
  have no slot id because they are a transcription of a board rather than rows
  in a store, and a tag ending in `_nil` would be a worse name than no id at
  all. Both bare tags are recorded against this screen in
  `Kati.ScreenParamsSweepTest` and in `Kati.ScreenTapSweepTest`, so the fixture
  path is pinned from the outside as well.

      iex> Kati.Screens.MealsToday.tag("swap", %{slot_id: "abc"})
      :swap_abc

      iex> Kati.Screens.MealsToday.tag("swap", %{slot_id: nil})
      :swap
  """
  @spec tag(String.t(), map()) :: atom()
  def tag(prefix, %{slot_id: id}) when is_binary(id), do: String.to_atom(prefix <> "_" <> id)
  def tag(prefix, _meal), do: String.to_atom(prefix)

  @doc """
  Write that a planned meal was eaten.

  `Kati.Meals.MealLog.log_eaten/1` freezes the figures at the moment of the
  claim — that is the whole point of the resource, and why re-logging is a
  destroy and a create rather than an update. So this hands it the slot's
  recipe and portion and lets `Kati.Meals.Changes.FreezeNutrition` do the
  arithmetic, rather than copying today's numbers into the row itself. Screen
  45's own **Mark eaten** calls the same function, because two screens that
  mean *I ate this* must not be able to write two different rows.

  **The row is the one this page drew, found by the id the button carried.**
  `Enum.find` over `socket.assigns.day.meals` and never a fresh read: a query
  here would answer with the day as it stands at TAP time, and a plan edited in
  another tab between the render and the finger would log a meal the reader was
  not looking at. That is screen 73's defect, which credited a play to whoever
  led the shelf at save. A tag whose slot is no longer in the drawn day finds
  nothing and this function returns the socket untouched — the page refuses
  rather than guessing, which is also what every `Kati.Meals.SampleToday` row
  gets, since none of them has a slot id to be found by.

  The day is re-read afterwards rather than patched in the socket: the card a
  logged meal draws is `log_row/1`'s, not `slot_row/1`'s, and deriving it twice
  in two places is how the two would come to disagree.
  """
  @spec mark_eaten(Mob.Socket.t(), String.t()) :: Mob.Socket.t()
  def mark_eaten(socket, slot_id) do
    meal = Enum.find(socket.assigns.day.meals, &(Map.get(&1, :slot_id) == slot_id))

    if meal do
      MealLog.log_eaten(meal)

      Mob.Socket.assign(socket, :day, Kati.Screens.MealsToday.day(Kati.Time.today()))
    else
      socket
    end
  end

  @doc """
  Hand screen 46 the slot whose **Swap** was pressed.

  The slot goes over through `Mob.State` — `Kati.Screens.MealSwap.hand_over/1`,
  the way screen 86 hands a query to 19 — rather than on the push, because that
  is the door screen 46 was built around and `Kati.MealSwapTest` drives
  directly: `Kati.Screens.MealSwap.swap/1` reads a named slot first and falls
  back to the store.

  The id is resolved against `socket.assigns.day.meals` — the rows THIS render
  drew — and not against a fresh read, so a slot deleted or re-planned since
  the render hands nothing over instead of handing over a stale name. Same
  lookup, same list and same refusal as `mark_eaten/2`.
  """
  @spec swap(Mob.Socket.t(), String.t()) :: Mob.Socket.t()
  def swap(socket, slot_id) do
    case Enum.find(socket.assigns.day.meals, &(Map.get(&1, :slot_id) == slot_id)) do
      %{slot_id: id} when is_binary(id) -> Kati.Screens.MealSwap.hand_over(id)
      _gone -> :ok
    end

    Mob.Socket.push_screen(socket, Kati.Screens.MealSwap)
  end

  @doc """
  Open screen 45 on the card that was tapped.

  The tag is matched by rebuilding every row's own tag rather than by splitting
  this one back apart: `meal_tag/1` replaces the spaces in a slot name with
  underscores, so `meal_Post_workout_16:00` has no first separator that means
  anything, and the row is the thing that owns its name anyway. Same lookup
  shape as `mark_eaten/2` one function above.

  A row with no slot id — every `Kati.Meals.SampleToday` row, and every logged
  one — gives `%{}` through `Kati.Screens.Meal.params_for/1`, which is the push
  this screen made before and the screen 45 the drawing shows.
  """
  @spec open_meal(Mob.Socket.t(), atom()) :: Mob.Socket.t()
  def open_meal(socket, tag) do
    meal = Enum.find(socket.assigns.day.meals, &(Kati.Screens.MealsToday.meal_tag(&1) == tag))

    Mob.Socket.push_screen(socket, Kati.Screens.Meal, Kati.Screens.Meal.params_for(meal))
  end

  # The third action is a disc rather than a label, so it is the icon-only
  # button component. No `shadow` here — the drawing gives this one none, it
  # sits inside the lifted card rather than on the paper — and `variant:
  # :filled` on its own is exactly the `background` + `corner_radius` box it
  # replaces. `shape: :circle` computes 34 / 2 = 17.0, the radius written
  # before. It carries no handler, and passing no `on_tap` wires none.
  @doc false
  def overflow do
    MishkaActionIcon.action_icon(
      [size: 34, shape: :circle, variant: :filled, background: Palette.paper()],
      [UI.symbol("more_horiz", size: 17, color: Palette.ink_soft())]
    )
  end

  # `Kati.Components.MishkaPill`: a compact label with a tap and no selected
  # state, which is the port's own dividing line — "a Chip is selected, a Pill
  # is removed… if you find yourself giving a pill a checked state, you want
  # Chip". These never carry one, so they are pills.
  #
  # Pixel-for-pixel the same node, one wrapper deeper. Before: a hugging `Row`
  # with the fill, the radius, 14 of horizontal padding and a 34 height, around
  # one `Text`. Now: a `Box fill_width={false}` carrying that same fill, radius,
  # padding and height, around a `Row` holding the `Text` and the empty `Row`
  # the unused remove-slot leaves behind — which measures 0x0 and adds nothing
  # to the line.
  #
  # The four padding edges are all named, so the component's `:space_sm`
  # default is inert: `nodeModifier/1` reads the uniform value only for an edge
  # that is missing. `padding_top`/`padding_bottom` of 0 are what the Row got
  # by having no vertical padding at all, and 0 pins the outer height at 34,
  # since the bridge pads before it sizes.
  #
  # `align: :center` replaces the Row's `align="center"`: a Box centres its
  # content in both axes, and horizontally the content box is exactly the
  # Text's width, so only the vertical half of that does anything — which is
  # what `CenterVertically` was doing.
  @doc false
  def action(label, tone, tag) do
    # The ink tone is a filled call-to-action, so it INVERTS rather than
    # following the ground: `ink_fill` under `on_ink`, the pair screen 28 draws
    # for the hero's Open-inbox pill. The paper tone is a surface and follows
    # the page down instead.
    background = if tone == :ink, do: Palette.ink_fill(), else: Palette.paper()
    color = if tone == :ink, do: Palette.on_ink(), else: Palette.ink_soft()

    MishkaPill.pill(
      label: label,
      background: background,
      color: color,
      corner_radius: 17,
      height: 34,
      padding_left: 14,
      padding_right: 14,
      padding_top: 0,
      padding_bottom: 0,
      text_size: 12,
      font_weight: :semibold,
      align: :center,
      on_tap: tag
    )
  end

  @doc false
  def thumb(seed, size, radius) do
    case Kati.Design.Images.poster(seed) do
      nil ->
        ~MOB"""
        <Box width={size} height={size} corner_radius={radius} background={Palette.placeholder()} />
        """

      src ->
        ~MOB"""
        <Image src={src} width={size} height={size} corner_radius={radius} content_mode="fill" />
        """
    end
  end

  @doc false
  def prep do
    prep = Sample.prep()

    ~MOB"""
    <Column fill_width={true} background={Palette.cream()} corner_radius={20} padding={16}>
      <Row fill_width={true} align="center">
        {Kati.UI.symbol("schedule", size: 20, color: Palette.gold_icon())}
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text
            text={prep.title}
            text_size={13.5}
            font_weight="bold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={3} />
          <Text text={prep.line} text_size={11.5} text_color={Palette.cream_sub()} max_lines={1} />
        </Column>
      </Row>
      <Spacer size={13} />
      <Row fill_width={true} align="center">
        {Kati.Screens.MealsToday.action(prep.primary, :ink, :see_tomorrow)}
        <Spacer size={8} />
        {Kati.Screens.MealsToday.prep_secondary(prep.secondary)}
      </Row>
    </Column>
    """
  end

  # `rgba(255,255,255,.6)` on cream, which is a lighter cream rather than a
  # grey — so it stays a white at 60% alpha instead of being flattened.
  #
  # `cream_raise`, not `lock_ink_60` — the other meaning `Kati.Theme.Palette`
  # gives `0x99FFFFFF`. That one sits on a photograph and does not move; this is
  # a chip lifted a step off the cream card, so it follows the card and goes
  # solid `#3A342D` in dark, where a 60% white would blow the panel out.
  #
  # The same pill as `action/3`, and it does not call it only because its fill
  # and ink are neither of that function's two tones.
  @doc false
  def prep_secondary(label) do
    MishkaPill.pill(
      label: label,
      background: Palette.cream_raise(),
      color: Palette.cream_sub(),
      corner_radius: 17,
      height: 34,
      padding_left: 14,
      padding_right: 14,
      padding_top: 0,
      padding_bottom: 0,
      text_size: 12,
      font_weight: :semibold,
      align: :center,
      on_tap: :done_prepping
    )
  end

  # Meals is a hub, and every screen it reaches is one whose own drawing opens
  # with a `‹ Meals` back pill — 44, 45, 47, 48 and 49. Five of the six; screen
  # 51 is the sixth and no drawing anywhere gives it a control, which
  # `Kati.Screens.MealReminders` records rather than papering over.
  #
  # `:open_week` is the header disc AND the first tile: the drawing gives both
  # the same `calendar_view_week` glyph, so they are one affordance drawn twice
  # and they go to one place.
  @impl true
  def handle_tap(:open_meal, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Meal)}

  # The header disc and the first week tile are drawn with the same glyph and go
  # to the same place, which is why they shared a tag. Sharing a tag also made
  # both of them unaddressable, so they keep the one destination and take
  # separate names.
  def handle_tap(:open_week_disc, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.MealPlan)}

  def handle_tap(:open_library, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.MealLibrary)}

  def handle_tap(:open_week, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.MealPlan)}

  def handle_tap(:open_shopping, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Shopping)}

  @doc """
  Swap, and see tomorrow — two controls that drew and did nothing.

  Both had a screen waiting the whole time. **Swap** is board 46, which is
  named *Meal swap* and draws the two answers to it; **See tomorrow** is board
  52, the day view.

  Both now say which. Swap hands its slot over through `Mob.State`, because
  that is the door screen 46 has always read and `Kati.MealSwapTest` covers;
  See tomorrow carries the date in the push, because a control labelled
  *tomorrow* that opened whatever day the destination chose for itself was
  naming a day it had no part in picking.
  """
  # The drawn day's Swap, and the ONLY page that can still reach this clause.
  #
  # It used to be every card's tag, and it guessed:
  # `Enum.find(meals, &(&1.state == :next and &1.slot_id))` is the FIRST
  # upcoming meal, not the one whose button was pressed. A day with lunch and
  # dinner both ahead of you drew two **Swap** buttons, both tagged `:swap`,
  # and tapping dinner's handed screen 46 the lunch — screen 79's defect
  # exactly, where a page that drew one artist followed whoever led the shelf.
  # It also stamped the two cards with one `accessibility_id`, which is the
  # thing `Kati.ScreenTapSweepTest` exists to catch.
  #
  # `tag("swap", meal)` gives every real card its own name, so a real row never
  # reaches here. What does is `Kati.Meals.SampleToday`, whose rows have no slot
  # id — and a page that resolved nothing hands nothing over. The guess is gone
  # rather than narrowed: screen 46 with no slot is the drawing, which is a swap
  # of nothing, and that is the honest answer for a day that is a transcription
  # of a board.
  def handle_tap(:swap, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.MealSwap)}

  # This screen's own day is `Kati.Time.today/0`, so tomorrow is that plus one.
  # Named here rather than derived there: the control says *tomorrow*, and
  # tomorrow-relative-to-what is a fact the screen that drew the pill holds.
  def handle_tap(:see_tomorrow, socket),
    do:
      {:noreply,
       Mob.Socket.push_screen(socket, Kati.Screens.MealsDay, %{
         date: Date.add(Kati.Time.today(), 1)
       })}

  def handle_tap(:open_nutrition, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Nutrition)}

  # Both of these open screen 49, and both are the drawing's own words for it.
  # The `tune` tile is labelled "Plan" — the profile, not the week — and the
  # title pill is "Cutting v3" under an `unfold_more`, which is a picker glyph:
  # it says there are others. 49 is where the others are.
  def handle_tap(:open_plan, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Plans)}

  def handle_tap(:switch_plan, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Plans)}

  def handle_tap(:toggle_menu, socket),
    do: {:noreply, Mob.Socket.assign(socket, :menu?, not socket.assigns.menu?)}

  def handle_tap(:close_menu, socket),
    do: {:noreply, Mob.Socket.assign(socket, :menu?, false)}

  def handle_tap(:open_reminders, socket) do
    {:noreply,
     socket
     |> Mob.Socket.assign(:menu?, false)
     |> Mob.Socket.push_screen(Kati.Screens.MealReminders)}
  end

  # Every timeline card, by its own name. `meal_row/1` gives each card a tag
  # built from its slot, because four cards sharing `:open_meal` gave four nodes
  # one `accessibility_id` and `onNodeWithTag` throws on the second match — the
  # timeline was unaddressable on a device, not merely untested.
  #
  # Each card now names its own meal on the way through. Naming them was the
  # step that had to come first and it has been taken: the tag `meal_tag/1`
  # built is the row's own name, so `open_meal/2` finds the row by rebuilding
  # each row's tag rather than by taking this one apart, and
  # `Kati.Screens.Meal.params_for/1` turns that row into the push's params. A
  # `Kati.Meals.SampleToday` row has no slot id and yields `%{}`, which is the
  # bare push this replaced and the drawn screen 45.
  def handle_tap(tag, socket) when is_atom(tag) do
    case Atom.to_string(tag) do
      "mark_eaten_" <> slot_id ->
        {:noreply, Kati.Screens.MealsToday.mark_eaten(socket, slot_id)}

      "swap_" <> slot_id ->
        {:noreply, Kati.Screens.MealsToday.swap(socket, slot_id)}

      "meal_" <> _rest ->
        {:noreply, Kati.Screens.MealsToday.open_meal(socket, tag)}

      _other ->
        {:noreply, socket}
    end
  end

  def handle_tap(_tag, socket), do: {:noreply, socket}
end
