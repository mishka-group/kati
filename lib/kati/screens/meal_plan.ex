defmodule Kati.Screens.MealPlan do
  @moduledoc """
  Screen 44 — the repeating week, pushed under Meals.

  Built to `.scratch/design/screens/44.html`. The design's caption states both
  the layout and the domain rule behind it: *"Five slots × seven days as a
  matrix — too narrow for names, so cells carry state only and the tapped day
  lists underneath, exactly like the week calendar. The plan is a rule, not 52
  copies."*

  So the matrix is deliberately dumb. A cell says planned / free / not-in-the-
  plan and nothing more, and the names live in the list below it — the same
  split screen 17 makes between the week grid and the day it expands.

  ## Where this diverges from the drawing

    * **The cells are a declared 37pt square.** They are `flex:1` with
      `aspect-ratio:1` in the drawing, and nothing measures geometry on this
      bridge, so the height has to be declared. The arithmetic is done against
      the device, not the 402pt frame, because the width is fluid and the
      height is not: 411 less the 21pt gutters, less the card's 14pt padding
      either side, less the 62pt label column and seven 3pt gaps, is 258 across
      seven cells — 36.9 each. A capture measured 36.5 against a declared 35,
      which read as a wide cell rather than a square one.
    * **The unplanned Sunday snack is a solid outline.** `1.5px dashed
      rgba(26,25,23,.16)` has no dashed equivalent here, so it is solid at the
      same weight and colour.

  ## Where the data comes from

  `Kati.Meals`, through `plan/1`: the active plan's name and repeat rule, and
  its `Kati.Meals.MealPlanSlot` rows folded into five rows of seven cells.
  `:today` is computed rather than read — the resource is explicit that today
  is a fact about the calendar, not about the plan — and so is the week number
  under `Started`. With no active plan the screen falls back to
  `Kati.Meals.SamplePlan`.

  Two things here have no column behind them and stay written out: the
  Week / Day / Shop strip, a control this screen has never wired, and the third
  repeat-rule row, *"Edit this week only"*, which is a mode rather than a stored
  fact. Both are marked where they are built.

  No dock on a pushed screen, so the frame ends at 40 rather than 132.
  """
  use Kati.Screens.Pushed, back: "Meals"

  require Ash.Query

  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaSegmentedControl
  alias Kati.Components.MishkaSeparator
  alias Kati.Meals.MealPlanSlot
  alias Kati.Meals.Nutrition
  alias Kati.Meals.Recipe
  alias Kati.Meals.SamplePlan, as: Sample
  alias Kati.Theme
  alias Kati.Theme.Palette
  alias Kati.UI

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :plan, plan(Kati.Time.today()))

  @doc false
  def content(assigns) do
    plan = assigns.plan

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {Kati.Screens.MealPlan.header()}
        {Kati.Screens.MealPlan.title(plan)}
        {Kati.Screens.MealPlan.segments()}
        {Kati.Screens.MealPlan.matrix(plan)}
        {UI.eyebrow(plan.day_line)}
        {Kati.Screens.MealPlan.day_list(plan.day)}
        {Kati.Screens.MealPlan.muted_eyebrow("Repeat rule")}
        {Kati.Screens.MealPlan.repeat_rule(plan.repeat_rule)}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The week this screen draws: the active plan's, or the drawing's.

  35 cells is what a plan looks like when it exists, and seven empty columns is
  what one looks like when it does not — which is the screen the design cannot
  be compared with. FIDELITY's rule again: *missing data is not a reason for a
  blank screen*, so a device with no active plan draws `Kati.Meals.SamplePlan`,
  the values `.scratch/design/screens/44.html` was drawn from.

  The gate is the plan **and its slots**: a plan row with no week on it yet is
  a name, and a matrix of a name is 35 outlines.
  """
  @spec plan(Date.t()) :: map()
  def plan(date) do
    with row when not is_nil(row) <- active_plan(),
         [_ | _] = slots <- plan_slots(row) do
      planned_week(row, slots, date)
    else
      _ -> drawn_plan()
    end
  end

  @doc """
  Screen 44 exactly as it is drawn, from `Kati.Meals.SamplePlan`.

  `today` is 6 rather than `Date.day_of_week/1`: the drawing inks its last
  column because Sunday is the day its list below shows, and a fallback that
  inked a different column on a Tuesday would no longer be the drawing.
  """
  @spec drawn_plan() :: map()
  def drawn_plan do
    %{
      title: Sample.title(),
      subtitle: Sample.subtitle(),
      today: 6,
      matrix: Sample.matrix(),
      day_line: Sample.day_line(),
      day: Sample.day(),
      repeat_rule: Sample.repeat_rule()
    }
  end

  defp planned_week(row, slots, date) do
    today = Date.day_of_week(date)
    day = day_meals(slots, today)

    %{
      title: row.name,
      subtitle: subtitle(row),
      today: today - 1,
      matrix: matrix_rows(slots, today),
      day_line: "#{Calendar.strftime(date, "%A")} · #{meals(length(day))}",
      day: day,
      repeat_rule: repeat_rows(row)
    }
  end

  defp subtitle(%{repeat: :weekly}), do: "repeats every week"

  # Five rows of seven, from 35 rows that are stored one per cell. `position`
  # is what makes a row a row — two snacks share a name and differ only there —
  # and a day with no slot at that position is `:open`, which is the drawing's
  # own word for "not part of the plan this week".
  defp matrix_rows(slots, today) do
    slots
    |> Enum.group_by(& &1.position)
    |> Enum.sort_by(fn {position, _slots} -> position end)
    |> Enum.map(fn {_position, row} -> matrix_row_of(row, today) end)
  end

  defp matrix_row_of(row, today) do
    by_day = Map.new(row, &{&1.day_of_week, &1})
    [first | _] = Enum.sort_by(row, & &1.day_of_week)

    %{
      name: first.slot_name,
      time: clock(first.slot_time),
      cells: Enum.map(1..7, fn day -> cell_state(Map.get(by_day, day), day == today) end)
    }
  end

  # `:today` is not stored and must not be — `Kati.Meals.MealPlanSlot` says so
  # in as many words: *"today is a fact about the calendar, not about the
  # plan"*. It is computed here, over a cell that is planned; a free evening
  # stays free on the day it falls on.
  defp cell_state(nil, _today?), do: :open
  defp cell_state(%{state: :planned}, true), do: :today
  defp cell_state(%{state: state}, _today?), do: state

  defp day_meals(slots, today) do
    slots
    |> Enum.filter(&(&1.day_of_week == today and &1.state == :planned))
    |> Enum.sort_by(& &1.position)
    |> Enum.flat_map(&day_meal/1)
  end

  defp day_meal(%MealPlanSlot{recipe: %Recipe{} = recipe} = slot) do
    [
      %{
        slot: "#{slot.slot_name} · #{clock(slot.slot_time)}",
        title: recipe.title,
        calories: "#{Nutrition.scale(recipe_figures(recipe), slot.portion_milli).kcal}",
        seed: recipe.photo_seed
      }
    ]
  end

  # A planned slot with nothing decided for it yet has no meal to list. It
  # keeps its cell in the matrix above, which is the whole difference between
  # `:planned` with no recipe and `:free`.
  defp day_meal(_slot), do: []

  # Three rows, and only two of them have a column behind them.
  #
  # `Edit this week only` is a **mode**, not a stored fact: nothing in
  # `Kati.Meals.MealPlan` records it, the drawing draws the switch off, and the
  # screen has never wired it. It is written out here rather than derived so
  # that it is visible as the one row on this card that the database cannot
  # answer for.
  defp repeat_rows(row) do
    [
      %{icon: "repeat", title: "Repeats", sub: repeat_sub(row), trailing: :chevron},
      %{icon: "event_available", title: "Started", sub: started_sub(row), trailing: :chevron},
      %{
        icon: "edit_calendar",
        title: "Edit this week only",
        sub: "Changes will not carry forward",
        trailing: :switch_off
      }
    ]
  end

  defp repeat_sub(%{repeat: :weekly, weeks_total: nil}), do: "Every week, indefinitely"
  defp repeat_sub(%{repeat: :weekly, weeks_total: weeks}), do: "Every week, #{weeks} weeks"

  # "Week 6 · 6 Jul 2026" — the week is counted from the start date, not stored,
  # because a stored week number is wrong every Monday morning. A plan with no
  # start date says nothing rather than claiming week 1: `starts_on` is
  # nullable and an invented start would date every figure on screen 47.
  defp started_sub(%{starts_on: nil}), do: ""

  defp started_sub(%{starts_on: starts_on}) do
    week = div(Date.diff(Kati.Time.today(), starts_on), 7) + 1
    "Week #{week} · #{Calendar.strftime(starts_on, "%-d %b %Y")}"
  end

  defp meals(1), do: "1 meal"
  defp meals(count), do: "#{count} meals"

  defp clock(nil), do: ""
  defp clock(time), do: Calendar.strftime(time, "%H:%M")

  defp recipe_figures(recipe) do
    Map.new(Nutrition.fields(), fn field -> {field, Map.fetch!(recipe, :"total_#{field}")} end)
  end

  defp active_plan do
    case Kati.Meals.MealPlan |> Ash.Query.for_read(:active) |> Ash.read_one() do
      {:ok, row} -> row
      _ -> nil
    end
  rescue
    _ -> nil
  end

  defp plan_slots(row) do
    MealPlanSlot
    |> Ash.Query.filter(meal_plan_id == ^row.id)
    |> Ash.Query.sort(day_of_week: :asc, position: :asc)
    |> Ash.Query.load(:recipe)
    |> Ash.read!()
  rescue
    _ -> []
  end

  # `Kati.Screens.Pushed` floats the ‹ Meals pill over this content. This row
  # reserves its height and carries the edit button opposite it.
  #
  # The disc is `Kati.Components.MishkaActionIcon`, which is what it is: an
  # icon-only button on a raised surface. It could not be one until the
  # component took a `shadow`, because a floating disc IS its shadow — a
  # `variant: :filled` without one is a flat patch of card on card, and this
  # sits on `#EFECE7` paper.
  #
  # `shape: :circle` is an exact `size / 2`, so 44 gives the 22 written here
  # before; `variant: :filled` paints `background` and nothing else. The glyph
  # goes in as a child rather than as `icon:` because Kati's icons are Material
  # Symbols through `Kati.UI.symbol/2` (a `Text` in the `symbols` family), not
  # the component's own `:lg` Text. A child is wrapped in a `<Row>`, which hugs
  # it, inside a Box that already centred it — so the glyph lands where it did.
  @doc false
  def header do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Spacer weight={1.0} />
        {Kati.Screens.MealPlan.edit_button()}
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc false
  def edit_button do
    MishkaActionIcon.action_icon(
      [
        size: 44,
        shape: :circle,
        variant: :filled,
        background: Palette.card(),
        shadow: Theme.shadow_button(),
        on_tap: :edit_plan
      ],
      [Kati.UI.symbol("edit", size: 21)]
    )
  end

  @doc false
  def title(plan, style \\ :meta_tight) do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={plan.title}
        text_size={28}
        max_font_scale={1.6}
        font_weight="bold"
        letter_spacing={-0.03}
        text_color={:on_surface}
        max_lines={1}
      />
      {Kati.UI.SettingsList.subtitle(plan.subtitle, style)}
      <Spacer size={20} />
    </Column>
    """
  end

  # `Kati.Components.MishkaSegmentedControl`, not three hand-rolled Boxes in a
  # Row. It is the control's own definition — a joined strip where exactly one
  # option is always selected — and every value the strip is drawn from is now
  # a prop rather than a hardcoded token.
  #
  # The node tree is the same one, one wrapper shorter. Before: a `Row` carried
  # the trough (background, radius 16, padding 4) and each segment was a
  # `Box weight={1.0}` wrapping a `Box fill_width height={34}`, the outer one
  # existing only to hold the weight. The component's track is a `Box` holding a
  # full-width `Row`, which measures the same — a Box with a background and
  # padding, then a Row inside it, is what the single Row was doing in one node
  # — and each segment is ONE box carrying both the weight and the height, since
  # the bridge reads `weight` off the child's props and then applies the child's
  # own modifiers after it (`RenderNodeInner`: `modifier.then(nodeModifier)`).
  # `RowScope.weight` defaults to `fill = true`, so a weighted box is exactly
  # its share wide, which is what the inner `fill_width={true}` produced.
  #
  # Three prop-level notes, all of them no-ops on screen:
  #
  #   * the idle fill is the component's `:transparent` (0x00000000) where this
  #     screen wrote 0x00FFFFFF. Both are alpha 0.
  #   * `padding: 0` replaces "no padding prop at all". `intProp` reads 0 and
  #     the bridge applies `Modifier.padding(0.dp)`, which measures nothing.
  #     It has to be said, because the component's default is `:space_sm`.
  #   * the label was centred by a full-width Row with a weighted Spacer either
  #     side; it is now centred by the segment Box's own `align: :center`, over
  #     a content box of exactly the same width.
  #
  # The trough's own `align="center"` is gone with the Row, and does not need
  # replacing: `rowAlignProp` defaults to `CenterVertically`, and all three
  # segments are 34 tall anyway.
  #
  # No `on_change`: this strip has never been wired, and `Event.handler/2`
  # returns nil for a missing handler, so no segment gains a tap it did not
  # have.
  @doc false
  def segments do
    [first | _rest] = labels = Sample.segments()

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.MealPlan.strip(labels, first)}
      <Spacer size={18} />
    </Column>
    """
  end

  @doc false
  def strip(labels, active) do
    MishkaSegmentedControl.segmented_control(
      [
        value: active,
        fill_width: true,
        background: Palette.placeholder(),
        corner_radius: 16,
        track_padding: 4,
        segment_radius: 12,
        segment_height: 34,
        segment_weight: 1.0,
        padding: 0,
        color: Palette.card(),
        text_color: Palette.ink(),
        label_color: Palette.segment_idle(),
        text_size: 12.5,
        font_weight: :semibold,
        selected_weight: :bold,
        max_lines: 1,
        selected_shadow: "0 1 2 0 #0F1A1917 | 0 6 12 -8 #661A1917"
      ],
      Enum.map(labels, fn label -> MishkaSegmentedControl.option(label, label) end)
    )
  end

  @doc false
  def matrix(plan) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={14}
        padding_right={14}
        padding_top={16}
        padding_bottom={16}
      >
        {Kati.Screens.MealPlan.column_heads(plan.today)}
        {Enum.map(plan.matrix, fn row -> Kati.Screens.MealPlan.matrix_row(row) end)}
        {Kati.Screens.MealPlan.legend()}
      </Column>
      <Spacer size={16} />
    </Column>
    """
  end

  # One column is inked because it is the day the list below shows — the last
  # one in the drawing, which is Sunday, and `Date.day_of_week/1 - 1` on a
  # device, which is today. The seven letters themselves are the calendar's,
  # not the plan's, so they stay written out here.
  #
  # The 62pt lead is `width`, not `size`: `size` sets both axes, and a 62pt tall
  # spacer would give the header row 62pt of height for a 10pt letter.
  @doc false
  def column_heads(today) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Box width={62} height={12} />
        {Sample.columns()
         |> Enum.with_index()
         |> Enum.map(fn {letter, i} -> Kati.Screens.MealPlan.column_head(letter, i == today) end)}
      </Row>
      <Spacer size={9} />
    </Column>
    """
  end

  @doc false
  def column_head(letter, on?) do
    color = if on?, do: Palette.ink(), else: Palette.tertiary()

    ~MOB"""
    <Row weight={1.0} align="center">
      <Spacer size={3} />
      <Spacer weight={1.0} />
      <Text text={letter} font_family="mono" text_size={10} text_color={color} max_lines={1} />
      <Spacer weight={1.0} />
    </Row>
    """
  end

  @doc false
  def matrix_row(row) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Column width={62}>
          <Text
            text={row.name}
            text_size={11.5}
            font_weight="semibold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={2} />
          <Text
            text={row.time}
            font_family="mono"
            text_size={9.5}
            text_color={Palette.tertiary()}
            max_lines={1}
          />
        </Column>
        {Enum.map(row.cells, fn state -> Kati.Screens.MealPlan.cell(state) end)}
      </Row>
      <Spacer size={6} />
    </Column>
    """
  end

  # The 3pt gap rides inside the cell rather than being interspersed, so the
  # label column gets one too — which is what `display:flex;gap:3px` does when
  # the label is the first child.
  @doc false
  def cell(state) do
    ~MOB"""
    <Row weight={1.0} align="center">
      <Spacer size={3} />
      <Box
        weight={1.0}
        height={37}
        corner_radius={9}
        background={Kati.Screens.MealPlan.cell_fill(state)}
        border_width={Kati.Screens.MealPlan.cell_border(state)}
        border_color={Palette.border()}
        align="center"
      >
        {Kati.Screens.MealPlan.pip(state)}
      </Box>
    </Row>
    """
  end

  # Three of `Kati.Theme.Palette`'s multi-meaning literals meet in these three
  # clauses, so each names which meaning it took:
  #
  #   * `ink`, not `ink_fill` / `fab_fill` — the other two things `0xFF1A1917`
  #     is. A cell is a MARK on the matrix card, not a control you press, so it
  #     takes the ink that goes on a card (`#F5F2EE`) rather than the warm
  #     `#F7EFE4` the palette reserves for the hero's CTA pill. Today's orange
  #     pip inverts with it — orange on ink in light, orange on paper-ink in
  #     dark — which is what `:inversion` means.
  #   * `transparent`, not `card_hairline` / `cream_hairline`, the other two
  #     `0x00FFFFFF`s. This one is a deliberate absence of fill: the free cell
  #     is drawn as `cell_border/1`'s ring and nothing else.
  #   * `paper`, not `tab_well`. A planned cell is a well recessed into the
  #     card, so it follows the page down to `#121110`; `tab_well` is the
  #     dock's hole and is darker still.
  @doc false
  def cell_fill(:today), do: Palette.ink()
  def cell_fill(:open), do: Palette.transparent()
  def cell_fill(_), do: Palette.paper()

  @doc false
  def cell_border(:open), do: 1.5
  def cell_border(_), do: 0

  @doc false
  def pip(:planned) do
    ~MOB"""
    <Box width={7} height={7} corner_radius={4} background={Palette.rail_idle()} />
    """
  end

  def pip(:today) do
    ~MOB"""
    <Box width={7} height={7} corner_radius={4} background={Palette.accent()} />
    """
  end

  def pip(_), do: ~MOB"<Spacer size={0} />"

  @doc false
  def legend do
    keys =
      Sample.legend()
      |> Enum.map(fn {label, state} -> legend_key(label, state) end)
      |> Enum.intersperse(legend_gap())

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={7} />
      {Kati.Screens.MealPlan.hairline(true)}
      <Spacer size={13} />
      <Row fill_width={true} align="center">
        {keys}
      </Row>
    </Column>
    """
  end

  @doc false
  def legend_gap, do: ~MOB"<Spacer size={14} />"

  # `Free` is a ring rather than a fill — `box-shadow: inset 0 0 0 1.5px` in
  # the drawing, which is a border by another name.
  @doc false
  def legend_key(label, state) do
    ~MOB"""
    <Row align="center">
      {Kati.Screens.MealPlan.legend_swatch(state)}
      <Spacer size={5} />
      <Text
        text={String.upcase(label)}
        font_family="mono"
        text_size={9.5}
        letter_spacing={0.06}
        text_color={Palette.eyebrow()}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc false
  def legend_swatch(:planned) do
    ~MOB"""
    <Box width={7} height={7} corner_radius={4} background={Palette.rail_idle()} />
    """
  end

  def legend_swatch(:today) do
    ~MOB"""
    <Box width={7} height={7} corner_radius={4} background={Palette.accent()} />
    """
  end

  def legend_swatch(_) do
    ~MOB"""
    <Box
      width={7}
      height={7}
      corner_radius={4}
      border_width={1.5}
      border_color={Palette.track_off()}
    />
    """
  end

  @doc false
  def day_list(rows) do
    last = length(rows) - 1

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
        {rows |> Enum.with_index() |> Enum.map(fn {row, i} -> Kati.Screens.MealPlan.day_row(row, i < last) end)}
      </Column>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc false
  def day_row(row, rule?) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={11} padding_bottom={11}>
        {Kati.Screens.MealPlan.thumb(row.seed)}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text
            text={String.upcase(row.slot)}
            font_family="mono"
            text_size={9.5}
            letter_spacing={0.14}
            text_color={Palette.eyebrow()}
            max_lines={1}
          />
          <Spacer size={4} />
          <Text
            text={row.title}
            text_size={13.5}
            font_weight="semibold"
            text_color={:on_surface}
            max_lines={1}
          />
        </Column>
        <Spacer size={13} />
        <Text
          text={row.calories}
          font_family="mono"
          text_size={11}
          text_color={Palette.muted()}
          max_lines={1}
        />
      </Row>
      {Kati.Screens.MealPlan.hairline(rule?)}
    </Column>
    """
  end

  @doc false
  def thumb(seed) do
    case Kati.Design.Images.poster(seed) do
      nil ->
        ~MOB"<Box width={40} height={40} corner_radius={11} background={Palette.placeholder()} />"

      src ->
        ~MOB"""
        <Image src={src} width={40} height={40} corner_radius={11} content_mode="fill" />
        """
    end
  end

  # Kati.UI.eyebrow's dash is always the accent, and orange means new or now.
  # The repeat rule is neither, so the drawing gives it a #C4BDB3 dash.
  #
  # `#C4BDB3` is `Palette.rail_idle/0`, and the NAME is the part of it that is
  # off: the palette calls it the timeline rail because that is where the dark
  # drawing shows this neutral, and screen 28's `#4A453F` is the only measured
  # dark twin it has. It is the token this screen's four `#C4BDB3` marks — this
  # dash, the two planned pips, the trailing chevron — must take, because it is
  # the only one whose LIGHT value is `#C4BDB3`; `tertiary`, whose meaning
  # ("a faint chevron, an idle tab glyph") fits better, is `#B3ACA2` and would
  # move the baseline by eleven units.
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

  @doc false
  def repeat_rule(rows) do
    last = length(rows) - 1

    ~MOB"""
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
      {rows |> Enum.with_index() |> Enum.map(fn {row, i} -> Kati.Screens.MealPlan.rule_row(row, i < last) end)}
    </Column>
    """
  end

  @doc false
  def rule_row(row, rule?) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={13} padding_bottom={13}>
        <Box width={30} height={30} corner_radius={9} background={Palette.paper()} align="center">
          {Kati.UI.symbol(row.icon, size: 17, color: Palette.ink_soft())}
        </Box>
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
        <Spacer size={13} />
        {Kati.Screens.MealPlan.trailing(row.trailing)}
      </Row>
      {Kati.Screens.MealPlan.hairline(rule?)}
    </Column>
    """
  end

  @doc false
  def trailing(:chevron),
    do: Kati.UI.symbol("chevron_right", size: 18, color: Palette.rail_idle())

  # 46x28 with a 22pt knob inset 3pt, drawn the way
  # `Kati.Screens.Accessibility.toggle/1` draws it: the inset comes from a 40pt
  # inner Row, not from `padding`, because this bridge applies padding outside
  # an explicit width — `width={46} padding={3}` renders 52x34, not 46x28.
  # The knob leads and the space trails, which is the off state.
  def trailing(:switch_off) do
    ~MOB"""
    <Box width={46} height={28} corner_radius={14} background={Palette.track_off()} align="center">
      <Row width={40} align="center">
        <Box
          width={22}
          height={22}
          corner_radius={11}
          background={Palette.card()}
          shadow="0 1 3 0 #4D1A1917"
        />
        <Spacer weight={1.0} />
      </Row>
    </Box>
    """
  end

  # `Kati.Components.MishkaSeparator` with `render: :box` — and the `render` is
  # the whole point, because the note that used to sit here was wrong.
  #
  # `MobDivider` is not `Box().fillMaxWidth().height(t.dp).background(color)`.
  # It renders Material3's `HorizontalDivider`, which is a `Canvas` of height
  # `t` with an ANTIALIASED `drawLine` down its middle. At this device's 2.6875x
  # a 1dp rule is handed a 3px canvas and a 2.6875px stroke, so the last pixel
  # row lands at ~69% coverage — a full-width row 4-5/255 lighter than the two
  # above it. The design specifies a 1px hairline and Material cannot draw one.
  #
  # `render: :box` swaps the primitive back to the filled rect this screen drew
  # by hand before the component arrived: `<Box fill_width={true} height={1}
  # background={…}>` — the same three modifiers `nodeModifier/1` builds, in the
  # same order — so every pixel row carries the full colour again. The `Spacer`
  # the component nests inside it is a 1x1 iOS height workaround that the
  # background covers on Android.
  #
  # The colour stays the drawing's `rgba(26,25,23,.07)`; the component's own
  # `:border` default would repaint every hairline in the theme's token.
  @doc false
  def hairline(false), do: ~MOB"<Spacer size={0} />"

  def hairline(true),
    do: MishkaSeparator.separator(color: Palette.hairline(), thickness: 1, render: :box)

  @impl true
  def handle_tap(:edit_plan, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Plans)}

  def handle_tap(_tag, socket), do: {:noreply, socket}
end
