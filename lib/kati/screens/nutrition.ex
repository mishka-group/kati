defmodule Kati.Screens.Nutrition do
  @moduledoc """
  Screen 47 — nutrition and adherence, pushed under Meals.

  Built to `test/design/screens/47.html`. The order of the screen is its
  argument, and the design states it: *"Adherence is the number that matters,
  not calories — so it leads."* Calories get the cream hero because they are
  the number people look for; adherence gets the first count card because it
  is the number that decides whether the plan is working.

  The pixel field is deliberately the same one screens 07 and 22 draw — *"so a
  good week looks the same everywhere"* — and the target tick sits on every
  macro bar rather than only on the ones that missed, because a bar with no
  reference is a shape rather than a measurement.

  ## Where this diverges from the drawing

    * **The target tick is a centred child, not an absolute one.** The drawing
      positions it `top:-3px; left:95%` over the 8pt track. There is no
      absolute positioning here, so the track is a 14pt frame with the bar and
      the 14pt tick both centred inside it — the same 95% (a weighted Row) and
      the same 3pt of overhang either side, as layout rather than as an offset.
    * **`4 of 5 skips` is not bold.** The drawing puts a `<strong>` run inside
      the insight sentence; a `Text` on this bridge carries one style, so the
      emphasis is lost and the sentence is intact.

  ## The segments are the screen's one control

  Week / Month / All is a *period*, and a period that does not change the
  numbers under it is a lie the screen tells three times. So the segment owns
  everything above the consistency field — the hero average, its bar chart and
  day labels, the three count cards, and the four macro bars — and
  `period_data/1` is where a period's figures live. `"Week"` returns
  `Kati.Meals.SampleNutrition` unchanged, which is what the drawing shows and
  therefore what the resting screen must still draw.

  What the segment does **not** touch is deliberate: `Consistency · 12 weeks`
  names its own window in its own eyebrow, and the insight is a standing
  observation about Fridays. Neither is scoped to the segment, so neither moves
  when it does.

  ## Where the data comes from

  `Kati.Meals`, through `periods/1`: twelve weeks of `Kati.Meals.MealLog`, read
  once at `load/1` and bucketed three ways against the active plan's targets.
  Adherence is `eaten / (eaten + skipped)`, the hero is the daily average of the
  days that were actually logged, and a bar's verdict is the plan's
  `tolerance_permille` either side of the target — which is what makes the
  drawing's 2,120 Tuesday ink and its 2,400 Friday red against one 2,100 line.

  **Two blocks below the segment are still the drawing's, and cannot yet be
  anything else:**

    * **`Consistency · 12 weeks`** is 84 days at one of four levels, and nothing
      in `Kati.Meals` says what a level is. A day is not 0–3 of anything the
      schema holds, and inventing a scale would make the field look computed
      while meaning nothing. Its caption — `Jun`, `best run — 19 days` — goes
      with it.
    * **The insight** is written prose: *"4 of 5 skips happen after 16:00 on a
      Friday"*. `slot_time` and `state` would carry that arithmetic; the
      sentence around it is generated language, and nothing here generates it.

  Both stay on `Kati.Meals.SampleNutrition` and are named here, rather than
  being drawn as computed-looking blanks.

  No dock on a pushed screen, so the frame ends at 40 rather than 132.
  """
  use Kati.Screens.Pushed, back: "Meals"

  require Ash.Query

  alias Kati.Components.MishkaActionIcon
  alias Kati.Meals.MealLog
  alias Kati.Meals.SampleNutrition, as: Sample
  alias Kati.Theme
  alias Kati.Theme.Palette
  alias Kati.UI

  # The drawing's own scale for the hero chart: its 2,040 average stands 51pt
  # tall and its 2,400 Friday stands 60, which is 40 kcal to the point over a
  # 64pt frame. Written as the ceiling rather than as the divisor because that
  # is what it means — a day over 2,560 kcal fills the frame and stops.
  @chart_ceiling 2560

  @impl true
  def load(socket) do
    figures = figures(Kati.Time.today())

    Mob.Socket.assign(socket,
      period: "Week",
      plan_line: figures.plan_line,
      periods: figures.periods
    )
  end

  @doc false
  def content(assigns) do
    period = assigns.period
    data = Map.fetch!(assigns.periods, period)

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {Kati.Screens.Nutrition.back_gap()}
        {Kati.Screens.Nutrition.header(assigns.plan_line)}
        {Kati.Screens.Nutrition.segments(period)}
        {Kati.Screens.Nutrition.hero(data)}
        {Kati.Screens.Nutrition.counts(data)}
        {UI.eyebrow("Macros vs target")}
        {Kati.Screens.Nutrition.macros(data)}
        {Kati.Screens.Nutrition.muted_eyebrow("Consistency · 12 weeks")}
        {Kati.Screens.Nutrition.field()}
        {Kati.Screens.Nutrition.muted_eyebrow("What the data says")}
        {Kati.Screens.Nutrition.insight()}
      </Column>
    </Scroll>
    """
  end

  @doc """
  Everything on this screen that comes off the database, decided once.

  The header line and all three periods together, because they answer the same
  question — *whose figures are these?* — and a screen that titled the
  drawing's 2,040 kcal with the user's own plan name would be the worst of both
  answers. Three windows over twelve weeks of `Kati.Meals.MealLog`: seven daily
  buckets, four weekly ones and twelve weekly ones, all from one read, built at
  `load/1` rather than per render because the segment is a tap and a tap that
  re-queries the database to redraw four cards is a tap that stutters.

  With no active plan, or no log under it inside the window, this hands back
  `drawn_figures/0` — what the screen has always drawn, `"Week"` being
  `Kati.Meals.SampleNutrition` itself. FIDELITY's rule again: *missing data is
  not a reason for a blank screen*, and this is the one screen where a blank
  would read as "you have eaten nothing" rather than as "there is nothing here
  yet".
  """
  @spec figures(Date.t()) :: %{plan_line: String.t(), periods: %{String.t() => map()}}
  def figures(date) do
    with plan when not is_nil(plan) <- active_plan(),
         [_ | _] = logs <- plan_logs(plan, Date.add(date, -83), date) do
      %{
        plan_line: plan.name <> week_of(plan, date),
        periods: %{
          "Week" => window(plan, logs, daily_buckets(date)),
          "Month" => window(plan, logs, weekly_buckets(date, 4, &"W#{&1}")),
          "All" => window(plan, logs, weekly_buckets(date, 12, &"#{&1}"))
        }
      }
    else
      _ -> drawn_figures()
    end
  end

  @doc """
  The screen as it is drawn: `Kati.Meals.SampleNutrition`'s header line and its
  three sets of figures, `"Week"` being the drawing itself.

  `Kati.Meals.SampleNutrition` is what `.scratch/design/audit/47.png` was
  captured from, so it is the fallback and the fixture both. `mark` is added to
  each macro row here because the target tick is a fact about the plan's
  tolerance rather than about a macro, and the drawn rows have to carry it in
  the same shape the computed ones do.
  """
  @spec drawn_figures() :: %{plan_line: String.t(), periods: %{String.t() => map()}}
  def drawn_figures do
    %{
      plan_line: Sample.plan_line(),
      periods: %{
        "Week" => marked(period_data("Week")),
        "Month" => marked(period_data("Month")),
        "All" => marked(period_data("All"))
      }
    }
  end

  defp marked(data) do
    mark = Sample.target_mark()
    %{data | macros: Enum.map(data.macros, &Map.put(&1, :mark, mark))}
  end

  # One bucket per day, Monday first, labelled with the day's own initial —
  # `M T W T F S S`, which is what the drawing's axis is.
  defp daily_buckets(date) do
    monday = Date.add(date, -(Date.day_of_week(date) - 1))

    Enum.map(0..6, fn offset ->
      day = Date.add(monday, offset)
      {String.first(Calendar.strftime(day, "%a")), [day]}
    end)
  end

  # `count` weeks ending with the one `date` falls in, oldest first, each
  # bucket the seven days of its week.
  defp weekly_buckets(date, count, label) do
    monday = Date.add(date, -(Date.day_of_week(date) - 1))

    Enum.map(1..count, fn index ->
      start = Date.add(monday, -7 * (count - index))
      {label.(index), Enum.map(0..6, &Date.add(start, &1))}
    end)
  end

  defp window(plan, logs, buckets) do
    eaten = Enum.filter(logs, &(&1.state == :eaten))
    days = buckets |> Enum.flat_map(fn {_label, dates} -> dates end) |> MapSet.new()
    inside = Enum.filter(eaten, &MapSet.member?(days, &1.logged_on))
    target = plan.target_kcal || 0

    %{
      hero: hero(inside, target),
      bars: Enum.map(buckets, &bar_of(&1, eaten, target, plan)),
      counts: counts(logs, days),
      macros: macro_rows(inside, plan)
    }
  end

  # The average of the days that were LOGGED, not of the days in the window: a
  # week you recorded two days of is not a week you averaged 600 kcal in, and
  # the honest reading of a gap is that nothing is known about it.
  defp hero(eaten, target) do
    %{
      label: "Daily average",
      average: group(daily_average(eaten, &(&1.kcal || 0))),
      unit: " kcal",
      target_label: "Target",
      target: group(target)
    }
  end

  defp bar_of({label, dates}, eaten, target, plan) do
    days = MapSet.new(dates)
    inside = Enum.filter(eaten, &MapSet.member?(days, &1.logged_on))
    average = daily_average(inside, &(&1.kcal || 0))

    {label, height(average), verdict(average, target, plan)}
  end

  defp height(average) do
    round(min(average / @chart_ceiling, 1.0) * 64)
  end

  # Three verdicts, and the band between them is the plan's own
  # `tolerance_permille` — 950 by default, which is the 95% tick the drawing
  # puts on every macro bar. Under it is under; as far over it is on target;
  # past that is over. A symmetric band is what makes the drawing's 2,120
  # Tuesday ink and its 2,400 Friday red against the same 2,100 target.
  defp verdict(_average, 0, _plan), do: Palette.cream_ink()

  defp verdict(average, target, plan) do
    tolerance = plan.tolerance_permille || 950
    floor = target * tolerance / 1000
    ceiling = target * (2000 - tolerance) / 1000

    cond do
      average > ceiling -> Palette.red()
      average < floor -> Palette.bar_neutral()
      true -> Palette.cream_ink()
    end
  end

  # `30 hit / 5 skipped / 86%` — the adherence is the share of the meals that
  # were answered at all, which is what the drawing's three cards add up to.
  defp counts(logs, days) do
    inside = Enum.filter(logs, &MapSet.member?(days, &1.logged_on))
    hit = Enum.count(inside, &(&1.state == :eaten))
    skipped = Enum.count(inside, &(&1.state == :skipped))

    [
      {adherence(hit, skipped), "Adherence", Palette.ink()},
      {"#{hit}", "Meals hit", Palette.ink()},
      {"#{skipped}", "Skipped", Palette.red()}
    ]
  end

  defp adherence(0, 0), do: "—"
  defp adherence(hit, skipped), do: "#{round(hit * 100 / (hit + skipped))}%"

  # A macro with no target is not drawn: this card is `Macros vs target`, and a
  # bar with nothing to be measured against is the shape the moduledoc says a
  # measurement must not be. `Kati.Meals.MealPlan` allows every target to be
  # nil, so all four rows can legitimately be absent.
  defp macro_rows(eaten, plan) do
    [
      {"Protein", :protein_mg, plan.target_protein_mg, Palette.ink()},
      {"Carbs", :carbs_mg, plan.target_carbs_mg, Palette.bronze()},
      {"Fat", :fat_mg, plan.target_fat_mg, Palette.bar_gold()},
      {"Fibre", :fibre_mg, plan.target_fibre_mg, Palette.bar_ink()}
    ]
    |> Enum.reject(fn {_name, _field, target, _tone} -> is_nil(target) or target == 0 end)
    |> Enum.map(fn {name, field, target, tone} ->
      value = daily_average(eaten, &(Map.get(&1, field) || 0))
      grams = div(value, 1000)
      target_grams = div(target, 1000)

      %{
        name: name,
        value: "#{grams} / #{target_grams} g",
        fill: Float.round(min(grams / target_grams, 1.0), 2),
        tone: tone,
        mark: (plan.tolerance_permille || 950) / 1000
      }
    end)
  end

  defp daily_average([], _figure), do: 0

  defp daily_average(logs, figure) do
    days = logs |> Enum.map(& &1.logged_on) |> Enum.uniq() |> length()
    div(Enum.reduce(logs, 0, &(figure.(&1) + &2)), days)
  end

  # "Cutting v3 · week 6 of 12". The week is counted from the plan's start
  # date; a plan with none says its name and stops, rather than claiming a week
  # it cannot count.
  defp week_of(%{starts_on: nil}, _date), do: ""

  defp week_of(%{starts_on: starts_on, weeks_total: nil}, date),
    do: " · week #{div(Date.diff(date, starts_on), 7) + 1}"

  defp week_of(%{starts_on: starts_on, weeks_total: total}, date),
    do: " · week #{div(Date.diff(date, starts_on), 7) + 1} of #{total}"

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

  # Scoped to the plan, not merely to the window.
  #
  # This screen is titled with a plan and a week of it — `Cutting v3 · week 6
  # of 12` — and the number it leads with is adherence, which is a question
  # about the plan's own meals: the drawing's `30 hit / 5 skipped` is 35, one
  # week of `Kati.Meals.MealPlanSlot` rows. `Kati.Meals.MealLog` records the
  # plan a meal was logged under precisely so the past stays with the plan it
  # belonged to (`keep_history`), and reading every log in the window instead
  # would measure a plan by meals it never asked for.
  #
  # The cost is stated rather than hidden: a meal logged with no plan behind it
  # — eating out, `log_manual` with no `meal_plan_id` — is in nobody's
  # adherence and so is in no average here either. It is on screen 43's
  # timeline, where it was eaten.
  defp plan_logs(plan, from, to) do
    MealLog
    |> Ash.Query.filter(meal_plan_id == ^plan.id and logged_on >= ^from and logged_on <= ^to)
    |> Ash.read!()
  rescue
    _ -> []
  end

  @doc """
  The figures the drawing carries, for one period.

  `"Week"` is `Kati.Meals.SampleNutrition` unchanged, so the resting screen is
  pixel-identical to `47.html`. The other two are the same four shapes at a
  longer scale — a monthly average slightly over the weekly one, four weekly
  bars instead of seven daily ones, counts that are the week's multiplied out,
  and macro averages that drift the way a longer window does.

  The bar tones are the same three verdicts `bars/0` uses — ink on target,
  `#D8D2C8` under, `#B4553C` over — so a red bar means the same thing in every
  period.

  ## Why the on-target ink is two tokens

  Three lists here write `0xFF1A1917` and they sit on two different grounds, so
  they resolve through two different `Kati.Theme.Palette` tokens. Both are
  `#1A1917` in light, so nothing moves; in dark they are ten units of blue
  apart, which is the palette's whole point.

    * `bars` are drawn inside the **cream** hero, alongside a `cream_meta`
      label and a `cream_meta` axis, so the on-target bar is `cream_ink` and
      warms to `#F7EFE4` with everything else on that card.
    * `counts` and `macros` are drawn on plain **cards**, so their on-target
      figure and dot are `ink` and go to `#F5F2EE`.

  The two verdicts either side are unambiguous: `#D8D2C8` is `bar_neutral`,
  which the palette defines as "a bar in a chart that is not the highlighted
  one" — this chart — and `#B4553C` is `red`. The macro tones are the palette's
  own chart family too: `bronze`, `bar_gold` and `bar_ink`.
  """
  @spec period_data(String.t()) :: %{
          hero: map(),
          bars: [{String.t(), pos_integer(), non_neg_integer()}],
          counts: [{String.t(), String.t(), non_neg_integer()}],
          macros: [map()]
        }
  def period_data("Month") do
    %{
      hero: %{
        label: "Daily average",
        average: "2,088",
        unit: " kcal",
        target_label: "Target",
        target: "2,100"
      },
      bars: [
        {"W1", 46, Palette.bar_neutral()},
        {"W2", 52, Palette.cream_ink()},
        {"W3", 61, Palette.red()},
        {"W4", 50, Palette.cream_ink()}
      ],
      counts: [
        {"84%", "Adherence", Palette.ink()},
        {"126", "Meals hit", Palette.ink()},
        {"24", "Skipped", Palette.red()}
      ],
      macros: [
        %{name: "Protein", value: "149 / 168 g", fill: 0.89, tone: Palette.ink()},
        %{name: "Carbs", value: "205 / 210 g", fill: 0.98, tone: Palette.bronze()},
        %{name: "Fat", value: "64 / 70 g", fill: 0.91, tone: Palette.bar_gold()},
        %{name: "Fibre", value: "27 / 35 g", fill: 0.77, tone: Palette.bar_ink()}
      ]
    }
  end

  def period_data("All") do
    %{
      hero: %{
        label: "Daily average",
        average: "2,062",
        unit: " kcal",
        target_label: "Target",
        target: "2,100"
      },
      bars: [
        {"1", 38, Palette.bar_neutral()},
        {"2", 44, Palette.bar_neutral()},
        {"3", 49, Palette.cream_ink()},
        {"4", 52, Palette.cream_ink()},
        {"5", 47, Palette.bar_neutral()},
        {"6", 51, Palette.cream_ink()},
        {"7", 58, Palette.cream_ink()},
        {"8", 62, Palette.red()},
        {"9", 55, Palette.cream_ink()},
        {"10", 43, Palette.bar_neutral()},
        {"11", 50, Palette.cream_ink()},
        {"12", 46, Palette.bar_neutral()}
      ],
      counts: [
        {"81%", "Adherence", Palette.ink()},
        {"340", "Meals hit", Palette.ink()},
        {"80", "Skipped", Palette.red()}
      ],
      macros: [
        %{name: "Protein", value: "146 / 168 g", fill: 0.87, tone: Palette.ink()},
        %{name: "Carbs", value: "212 / 210 g", fill: 1.0, tone: Palette.bronze()},
        %{name: "Fat", value: "66 / 70 g", fill: 0.94, tone: Palette.bar_gold()},
        %{name: "Fibre", value: "24 / 35 g", fill: 0.69, tone: Palette.bar_ink()}
      ]
    }
  end

  def period_data(_week) do
    %{
      hero: Sample.hero(),
      bars: Sample.bars(),
      counts: Sample.counts(),
      macros: Sample.macros()
    }
  end

  # `Kati.Screens.Pushed` floats the ‹ Meals pill over this content, and unlike
  # screens 43 and 44 nothing sits opposite it — so this is a plain reservation
  # of the drawing's 42pt pill and the 16pt gap under it.
  @doc false
  def back_gap, do: ~MOB"<Spacer size={58} />"

  @doc false
  def header(plan_line) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column weight={1.0}>
          <Text
            text="Nutrition"
            text_size={28}
            max_font_scale={1.6}
            font_weight="bold"
            letter_spacing={-0.03}
            text_color={:on_surface}
          />
          <Spacer size={5} />
          <Text
            text={plan_line}
            font_family="mono"
            text_size={11}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
        <Spacer size={9} />
        {Kati.Screens.Nutrition.share_button()}
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  # `Kati.Components.MishkaActionIcon` — an icon-only button on a raised
  # surface, which is what this is. It could not be one until the component
  # took a `shadow`: a floating disc is defined by its shadow, and `#FBFAF8` on
  # `#EFECE7` paper without one barely reads as a disc.
  #
  # `shape: :circle` computes 44 / 2 = 22.0, the radius written here before;
  # `variant: :filled` paints `background` and stops. The glyph goes in as a
  # child rather than as `icon:`, because Kati's icons are Material Symbols
  # through `Kati.UI.symbol/2` — a `Text` in the `symbols` family — not the
  # component's own `:lg` Text. A child is wrapped in a `<Row>` that hugs it,
  # inside a Box that already centred it, so the glyph does not move.
  @doc false
  def share_button do
    MishkaActionIcon.action_icon(
      [
        size: 44,
        shape: :circle,
        variant: :filled,
        background: Palette.card(),
        shadow: Theme.shadow_button(),
        on_tap: :share
      ],
      [UI.symbol("ios_share", size: 21)]
    )
  end

  # NOT `Kati.Components.MishkaSegmentedControl`, and the reason is one number.
  #
  # The control can now build everything else this strip is: the trough is
  # `background`, `corner_radius: 16` and `track_padding: 4`; a segment is
  # `segment_radius: 12`, `segment_height: 34`, `segment_weight: 1.0` and
  # `padding: 0`; the chosen one takes `color`, `text_color`, `selected_weight`
  # and `selected_shadow`, the others `label_color` and `font_weight`. Screen
  # 44's strip is that call, and is pixel-identical to what it replaced.
  #
  # What it cannot do is **put 4pt between the segments**. The drawing's track
  # is `display:flex;gap:4px` and the reason is visual rather than tidy: the
  # chosen segment is a white pill on a `#E4E0D9` trough, and with the three
  # abutting, the trough disappears between them and the pill reads as a lid on
  # the strip rather than as one of three. The component lays its segments out
  # in a bare `<Row>` with no gap and no way to intersperse one — `expand/3`
  # and `segmented_control/2` keep only children matching
  # `:mishka_segmented_control_option` and drop everything else, so a `<Spacer>`
  # written between the options never reaches the tree.
  #
  # That is the whole gap: a `segment_gap` (or a `gap` on the segments' Row —
  # `gap` is already a spacing prop the renderer resolves) would make this call
  # identical to 44's. Screen 44 differs only in that its own markup has never
  # drawn the gap its drawing also asks for, which is why the component fits
  # there today and not here.
  @doc false
  def segments(active) do
    tabs =
      Sample.segments()
      |> Enum.map(fn label -> segment(label, label == active) end)
      |> Enum.intersperse(segment_gap())

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.placeholder()}
        corner_radius={16}
        padding={4}
        align="center"
      >
        {tabs}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  # The selected tab's white pill has to read as one of three, not as a lid on
  # a strip: without this the three abut and the trough disappears between them.
  @doc false
  def segment_gap, do: ~MOB"<Spacer size={4} />"

  @doc false
  def segment(label, on?) do
    # The tag carries the period, so one handler serves all three and a fourth
    # segment would be a change to `SampleNutrition.segments/0` alone.
    tap = {self(), String.to_atom("period_" <> label)}
    background = if on?, do: Palette.card(), else: Palette.transparent()
    color = if on?, do: Palette.ink(), else: Palette.segment_idle()
    weight = if on?, do: "bold", else: "semibold"
    shadow = if on?, do: "0 1 2 0 #0F1A1917 | 0 6 12 -8 #661A1917", else: nil

    ~MOB"""
    <Box weight={1.0}>
      <Box
        fill_width={true}
        height={34}
        corner_radius={12}
        background={background}
        shadow={shadow}
        align="center"
        on_tap={tap}
      >
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          <Text text={label} text_size={12.5} font_weight={weight} text_color={color} max_lines={1} />
          <Spacer weight={1.0} />
        </Row>
      </Box>
    </Box>
    """
  end

  @doc false
  def hero(data) do
    hero = data.hero
    bars = data.bars

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.cream()}
        corner_radius={24}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={19}
      >
        <Row fill_width={true} align="bottom">
          <Column weight={1.0}>
            <Text
              text={String.upcase(hero.label)}
              font_family="mono"
              text_size={10.5}
              letter_spacing={0.16}
              text_color={Palette.cream_meta()}
            />
            <Spacer size={7} />
            {Kati.Screens.Nutrition.average_figure(hero)}
          </Column>
          <Spacer size={12} />
          <Column width={52}>
            <Text
              text={String.upcase(hero.target_label)}
              font_family="mono"
              text_size={10}
              letter_spacing={0.1}
              text_color={Palette.cream_meta()}
              text_align="right"
              max_lines={1}
            />
            <Spacer size={6} />
            <Text
              text={hero.target}
              text_size={15}
              font_weight="semibold"
              text_color={:on_surface}
              text_align="right"
              max_lines={1}
            />
          </Column>
        </Row>
        <Spacer size={18} />
        {Kati.Screens.Nutrition.chart(bars)}
        <Spacer size={9} />
        {Kati.Screens.Nutrition.chart_labels(bars)}
      </Column>
      <Spacer size={14} />
    </Column>
    """
  end

  # `2,040` and ` kcal` are one inline run in the drawing, so they share a
  # baseline. `align="bottom"` aligns the two text *boxes*, and a 34pt box
  # carries more descent than a 15pt one, so the unit sank below the figure —
  # a capture measured it 3.8pt low. The lift is that descent difference,
  # 0.2 × (34 − 15) = 3.8, applied by `Kati.UI.number_with_unit/3`.
  @doc false
  def average_figure(hero) do
    number = ~MOB"""
    <Text
      text={hero.average}
      text_size={34}
      font_weight="extrabold"
      letter_spacing={-0.04}
      text_color={:on_surface}
      max_lines={1}
    />
    """

    unit = ~MOB"""
    <Text
      text={hero.unit}
      text_size={15}
      font_weight="semibold"
      text_color={Palette.cream_meta()}
      max_lines={1}
    />
    """

    UI.number_with_unit(number, unit, 3.8)
  end

  # A 64pt frame with the bars aligned to its bottom, which is what the
  # drawing's `justify-content:flex-end` inside a full-height column does.
  @doc false
  def chart(bars) do
    columns =
      bars
      |> Enum.map(fn {_letter, height, tone} -> bar(height, tone) end)
      |> Enum.intersperse(bar_gap())

    ~MOB"""
    <Row fill_width={true} height={64} align="bottom">
      {columns}
    </Row>
    """
  end

  @doc false
  def bar_gap, do: ~MOB"<Spacer size={6} />"

  @doc false
  def bar(height, tone) do
    ~MOB"""
    <Box weight={1.0} height={height} corner_radius={5} background={tone} />
    """
  end

  @doc false
  def chart_labels(bars) do
    labels = Enum.map(bars, fn {letter, _height, _tone} -> chart_label(letter) end)

    ~MOB"""
    <Row fill_width={true} align="center">
      {labels}
    </Row>
    """
  end

  @doc false
  def chart_label(letter) do
    ~MOB"""
    <Row weight={1.0} align="center">
      <Spacer weight={1.0} />
      <Text
        text={letter}
        font_family="mono"
        text_size={9.5}
        text_color={Palette.cream_meta()}
        max_lines={1}
      />
      <Spacer weight={1.0} />
    </Row>
    """
  end

  @doc false
  def counts(data) do
    cards =
      data.counts
      |> Enum.map(fn {value, label, tone} -> count_card(value, label, tone) end)
      |> Enum.intersperse(count_gap())

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {cards}
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def count_gap, do: ~MOB"<Spacer size={12} />"

  @doc false
  def count_card(value, label, tone) do
    ~MOB"""
    <Box weight={1.0}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={15}
      >
        <Text
          text={value}
          text_size={24}
          font_weight="extrabold"
          letter_spacing={-0.035}
          text_color={tone}
          max_lines={1}
        />
        <Spacer size={5} />
        <Text
          text={String.upcase(label)}
          font_family="mono"
          text_size={10}
          letter_spacing={0.1}
          text_color={Palette.muted()}
          max_lines={1}
        />
      </Column>
    </Box>
    """
  end

  @doc false
  def macros(data) do
    rows = data.macros
    last = length(rows) - 1

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={17}
      >
        {rows |> Enum.with_index() |> Enum.map(fn {row, i} -> Kati.Screens.Nutrition.macro_row(row, i < last) end)}
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def macro_row(row, gap?) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Box width={7} height={7} corner_radius={2} background={row.tone} />
        <Spacer size={6} />
        <Text
          text={row.name}
          text_size={12.5}
          font_weight="semibold"
          text_color={:on_surface}
          max_lines={1}
        />
        <Spacer weight={1.0} />
        <Text
          text={row.value}
          font_family="mono"
          text_size={11}
          text_color={Palette.muted()}
          max_lines={1}
        />
      </Row>
      <Spacer size={7} />
      {Kati.Screens.Nutrition.track(row)}
      {Kati.Screens.Nutrition.macro_gap(gap?)}
    </Column>
    """
  end

  @doc false
  def macro_gap(false), do: ~MOB"<Spacer size={0} />"
  def macro_gap(true), do: ~MOB"<Spacer size={13} />"

  # A 14pt frame holding two centred layers: the 8pt bar, and the 14pt tick
  # over it. The frame is what gives the tick its 3pt of overhang either side —
  # a taller child is not clipped by a Box, but it *is* clipped by the 8pt
  # track's own corner_radius, which is where the tick lost 9 of its 14 points
  # and rendered as a stub. Centring both in 14 draws the drawing's
  # `top:-3px` as real space rather than as an offset out of a mask.
  @doc false
  def track(row) do
    ~MOB"""
    <Box fill_width={true} height={14} align="center">
      <Box fill_width={true} height={8} corner_radius={4} background={Palette.paper()}>
        {Kati.Screens.Nutrition.fill(row.fill, row.tone)}
      </Box>
      {Kati.Screens.Nutrition.tick(row.mark)}
    </Box>
    """
  end

  # A full bar is drawn as a full-width Box rather than as weight 1.0 beside a
  # weight 0.0 spacer, which Compose rejects.
  @doc false
  def fill(amount, tone) when amount >= 1.0 do
    ~MOB"""
    <Box fill_width={true} height={8} corner_radius={4} background={tone} />
    """
  end

  # And an empty bar is drawn as nothing at all, for the mirror-image reason:
  # `weight` is a share of the leftover space, so a share of zero is a question
  # Compose rejects rather than a child of no width. The drawing never asks it;
  # a macro nobody has eaten any of asks it on the first morning.
  def fill(amount, _tone) when amount == 0 do
    ~MOB"""
    <Spacer size={0} />
    """
  end

  def fill(amount, tone) do
    rest = 1.0 - amount

    ~MOB"""
    <Row fill_width={true}>
      <Box weight={amount} height={8} corner_radius={4} background={tone} />
      <Spacer weight={rest} />
    </Row>
    """
  end

  # The tick is `0x591A1917`, and `divider_heavy` is the only token whose light
  # value is that — the palette named it for the 35% vertical rule it draws
  # between two numbers, which is the same ink tint at the same alpha and the
  # same 1.5pt width, put to a different use. Taking it keeps the tick on the
  # ink-tint ladder, so in dark it becomes 35% of `#F5F2EE` and stays a mark ON
  # the bar; left as `0x591A1917` it would be 35% black over a `#1E1D1B` card
  # and the target would silently stop being drawn.
  @doc false
  def tick(mark) do
    rest = 1.0 - mark

    ~MOB"""
    <Row fill_width={true}>
      <Spacer weight={mark} />
      <Box width={1.5} height={14} background={Palette.divider_heavy()} />
      <Spacer weight={rest} />
    </Row>
    """
  end

  @doc false
  def field do
    rows = Sample.consistency() |> Enum.chunk_every(27)
    {left, right} = Sample.field_caption()

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={17}
      >
        {Enum.map(rows, fn row -> Kati.Screens.Nutrition.field_row(row) end)}
        <Spacer size={8} />
        <Row fill_width={true} align="center">
          <Text
            text={left}
            font_family="mono"
            text_size={10}
            text_color={Palette.tertiary()}
            max_lines={1}
          />
          <Spacer weight={1.0} />
          <Text
            text={right}
            font_family="mono"
            text_size={10}
            text_color={Palette.tertiary()}
            max_lines={1}
          />
        </Row>
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def field_row(row) do
    ~MOB"""
    <Column>
      <Row>
        {row |> Enum.map(&Kati.Screens.Nutrition.cell/1) |> Enum.intersperse(Kati.Screens.Nutrition.cell_gap())}
      </Row>
      <Spacer size={4} />
    </Column>
    """
  end

  @doc false
  def cell_gap, do: ~MOB"<Spacer size={4} />"

  @doc false
  def cell(level) do
    tone = Sample.tone(level)

    ~MOB"""
    <Box width={8} height={8} corner_radius={2} background={tone} />
    """
  end

  # Kati.UI.eyebrow's dash is always the accent, and orange means new or now.
  # Neither the field nor the insight is either, so both take #C4BDB3.
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

  # `cream_body` on a card, which reads as a contradiction and is not one:
  # `0xFF4A4238` appears exactly once in the palette's light column and that is
  # the token. The design uses its warmest body ink for the one paragraph on
  # this screen meant to be READ rather than counted, and puts it on a white
  # card rather than on cream. In dark it becomes `#E4DBCE` — warm off-white on
  # `#1E1D1B`, which keeps the sentence reading warmer than the figures around
  # it, which is what the light drawing does too.
  @doc false
  def insight do
    ~MOB"""
    <Row
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={17}
      align="top"
    >
      {Kati.UI.symbol("lightbulb", size: 19, color: Palette.accent())}
      <Spacer size={11} />
      <Text
        text={Kati.Meals.SampleNutrition.insight()}
        text_size={13}
        line_height={1.55}
        text_color={Palette.cream_body()}
        weight={1.0}
      />
    </Row>
    """
  end

  # One clause for all three segments: the tag carries the period, so the
  # handler never learns their names. `:share` falls through deliberately —
  # the disc is drawn and its sheet is not this screen's to open.
  @impl true
  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "period_" <> label -> {:noreply, Mob.Socket.assign(socket, :period, label)}
      _ -> {:noreply, socket}
    end
  end
end
