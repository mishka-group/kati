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

  ## The words are this screen's; the drawing's figures are the fixture's

  Every label this module writes is a msgid — the title, the three periods,
  the hero's two eyebrows, the three count cards, the four macro names, both
  muted eyebrows — and every figure it counts goes out through `Kati.Locale`,
  which is also what starts a Persian reader's seven-day axis on a Saturday
  rather than on a Monday.

  What is not here is `Kati.Meals.SampleNutrition`'s own copy. The resting
  screen draws the fixture's `Cutting v3 · week 6 of 12`, its `2,040 kcal`,
  its `Jun` and `best run — 19 days` and its Friday sentence, and those are
  that module's to translate the way `Kati.Meals.SampleToday` already has.
  Every slot they land in here asks `Kati.Locale.mono_face/1` about the string
  rather than pinning `mono`, so the day they change they are typeset in
  Vazirmatn at the design's mono size and this file needs no second edit.

  No dock on a pushed screen, so the frame ends at 40 rather than 132.
  """
  use Kati.Screens.Pushed, back: "Meals"
  use Gettext, backend: Kati.Gettext

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

    # The field names its own window in its own eyebrow, and the window is
    # interpolated rather than written into the sentence so the reader meets it
    # in their own digits — `ثبات · ۱۲ هفته`. Twelve is still the fixture's own
    # count: `Kati.Meals.SampleNutrition.consistency/0` is 84 cells.
    consistency = gettext("Consistency · %{n} weeks", n: Kati.Locale.number(12))

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
        {UI.eyebrow(gettext("Macros vs target"))}
        {Kati.Screens.Nutrition.macros(data)}
        {Kati.Screens.Nutrition.muted_eyebrow(consistency)}
        {Kati.Screens.Nutrition.field()}
        {Kati.Screens.Nutrition.muted_eyebrow(gettext("What the data says"))}
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
          "Month" => window(plan, logs, weekly_buckets(date, 4, &week_label/1)),
          "All" => window(plan, logs, weekly_buckets(date, 12, &Kati.Locale.number/1))
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

  # One bucket per day, the reader's own week first, labelled with the day's
  # own initial — `M T W T F S S`, which is what the drawing's axis is, and
  # `ش ی د س چ پ ج` on a Persian one.
  #
  # Two things moved for `:fa` and they have to move together. The label is
  # `Kati.Locale.weekday_initial/1` rather than the first letter of `%a`, which
  # is Latin in every locale; and the week begins where the READER's week
  # begins — board 137 makes that follow the language, so a Persian axis starts
  # on Saturday. `Kati.Screens.Stats.week_start_on/1` is the app's one answer
  # to that and screens 02 and 22 ask it too. A Persian axis labelled ش and
  # bucketed from Monday would put Saturday's calories under Monday's letter,
  # which is the quiet kind of wrong this fold keeps finding.
  defp daily_buckets(date) do
    start = Kati.Screens.Stats.week_start_on(date)

    Enum.map(0..6, fn offset ->
      day = Date.add(start, offset)
      {Kati.Locale.weekday_initial(day), [day]}
    end)
  end

  # `count` weeks ending with the one `date` falls in, oldest first, each
  # bucket the seven days of its week — counted from the reader's own week
  # start, for the reason `daily_buckets/1` gives.
  defp weekly_buckets(date, count, label) do
    this_week = Kati.Screens.Stats.week_start_on(date)

    Enum.map(1..count, fn index ->
      start = Date.add(this_week, -7 * (count - index))
      {label.(index), Enum.map(0..6, &Date.add(start, &1))}
    end)
  end

  # `W1`, and `ه۱` in Persian: the initial of the reader's own word for a week,
  # which is how this app abbreviates anywhere it has no room for the word —
  # `Kati.Screens.Stats` writes an episode as `E%{e}` and `ق%{e}` for exactly
  # the same reason.
  #
  # `pgettext/3` because two characters and a number is the size of msgid
  # `mix gettext.merge` will fuzzy-match against any sentence that happens to
  # end in one.
  defp week_label(index),
    do: pgettext("a week number on a chart axis", "W%{n}", n: Kati.Locale.number(index))

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
    hero_figures(group(daily_average(eaten, &(&1.kcal || 0))), group(target))
  end

  # The cream hero's five values in one place, because the computed week and
  # the two drawn periods all write the same three words and one msgid written
  # three times is one word that can drift three ways.
  #
  # Both figures arrive already grouped — `2,040` — and go through
  # `Kati.Locale.number/1` here: the digits change and the comma does not,
  # which is the ruling `Kati.Locale.number/1` takes off board 59.
  defp hero_figures(average, target) do
    %{
      label: gettext("Daily average"),
      average: Kati.Locale.number(average),
      # The leading space is the GAP between the two runs of one inline figure
      # — a 34pt Text beside a 15pt one on one baseline — rather than part of
      # the word, so it stays out of the msgid and `kcal` reaches the catalogue
      # as the word the rest of the app already translates: کالری.
      unit: " " <> gettext("kcal"),
      target_label: gettext("Target"),
      target: Kati.Locale.number(target)
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

    count_cards(adherence(hit, skipped), Kati.Locale.number(hit), Kati.Locale.number(skipped))
  end

  # The three cards' words, in one place for the reason `hero_figures/2` is:
  # the computed week and the two drawn periods label the same three cards, and
  # a card whose word drifted between periods would read as a different card.
  #
  # Two of the three are `pgettext/2`, and the context is doing real work. A
  # count card is a WORD UNDER A NUMBER in a third of the screen's width, so
  # the Persian has to be the short participle — `خورده‌شده` and `رد شده`, a
  # matched pair a reader takes in at a glance — where the app's plain
  # `Skipped` is the state of one meal on screens 43 and 44 and reads as a
  # sentence about it. One msgid cannot be both, which is the case
  # `Kati.Screens.Pushed.back_label/2` writes out at length for *Meals*.
  defp count_cards(adherence, hit, skipped) do
    [
      {adherence, gettext("Adherence"), Palette.ink()},
      {hit, pgettext("the count card on board 47 counting meals eaten as planned", "Meals hit"),
       Palette.ink()},
      {skipped, pgettext("the count card on board 47 counting meals skipped", "Skipped"),
       Palette.red()}
    ]
  end

  defp adherence(0, 0), do: "—"
  defp adherence(hit, skipped), do: percent(round(hit * 100 / (hit + skipped)))

  # `%{n}%` is the app's own msgid for a share and its Persian is `%{n}٪` —
  # U+066A, the Arabic percent sign, which is the mark board 07 draws its own
  # percentages with.
  defp percent(n), do: gettext("%{n}%", n: Kati.Locale.number(n))

  # A macro with no target is not drawn: this card is `Macros vs target`, and a
  # bar with nothing to be measured against is the shape the moduledoc says a
  # measurement must not be. `Kati.Meals.MealPlan` allows every target to be
  # nil, so all four rows can legitimately be absent.
  #
  # `< 1000` rather than `== 0`, and that is arithmetic rather than taste: the
  # row draws WHOLE grams, so a target under one gram divides down to a
  # `target_grams` of nought and `grams / target_grams` raises on the way to
  # the screen. A target that cannot be measured against in the unit the row
  # prints is the same case as no target at all.
  defp macro_rows(eaten, plan) do
    [
      {gettext("Protein"), :protein_mg, plan.target_protein_mg, Palette.ink()},
      {gettext("Carbs"), :carbs_mg, plan.target_carbs_mg, Palette.bronze()},
      {gettext("Fat"), :fat_mg, plan.target_fat_mg, Palette.bar_gold()},
      {gettext("Fibre"), :fibre_mg, plan.target_fibre_mg, Palette.bar_ink()}
    ]
    |> Enum.reject(fn {_name, _field, target, _tone} -> is_nil(target) or target < 1000 end)
    |> Enum.map(fn {name, field, target, tone} ->
      value = daily_average(eaten, &(Map.get(&1, field) || 0))
      grams = div(value, 1000)
      target_grams = div(target, 1000)

      %{
        name: name,
        value: macro_value(grams, target_grams),
        fill: Float.round(min(grams / target_grams, 1.0), 2),
        tone: tone,
        mark: (plan.tolerance_permille || 950) / 1000
      }
    end)
  end

  # `155 / 168 g`, and `۱۵۵ / ۱۶۸ گرم`. One msgid rather than a figure with a
  # unit appended, because the gram has to be able to move to the other end of
  # the run: a Persian reader reads the whole of it right to left.
  defp macro_value(grams, target_grams) do
    gettext("%{value} / %{target} g",
      value: Kati.Locale.number(grams),
      target: Kati.Locale.number(target_grams)
    )
  end

  defp daily_average([], _figure), do: 0

  defp daily_average(logs, figure) do
    days = logs |> Enum.map(& &1.logged_on) |> Enum.uniq() |> length()
    div(Enum.reduce(logs, 0, &(figure.(&1) + &2)), days)
  end

  # "Cutting v3 · week 6 of 12". The week is counted from the plan's start
  # date; a plan with none says its name and stops, rather than claiming a week
  # it cannot count.
  #
  # The ` · ` stays outside the msgid — it is the separator this whole screen
  # joins mono runs with, not a word — and the plan's own name stays outside it
  # too, because it is the reader's and no catalogue has it. What goes in is
  # the counted half: `هفته ۶ از ۱۲`.
  #
  # `pgettext/3` under the context `Kati.Screens.Health.week_of/2` already
  # writes, and the shorter clause is literally that screen's msgid: screen 42
  # draws `Cutting v3 · week 6` from the same plan and the two tails must not
  # be able to say it differently. The context is what keeps a lower-case
  # two-token tail off the catalogue's own `Week`, `Week %{week} · %{date}`
  # and `Week %{n} of %{total}`, any of which `mix gettext.merge` would
  # otherwise fuzzy-match it onto.
  defp week_of(%{starts_on: nil}, _date), do: ""

  defp week_of(%{starts_on: starts_on, weeks_total: nil}, date) do
    " · " <> pgettext("meal plan, mid-sentence", "week %{n}", n: week_number(starts_on, date))
  end

  defp week_of(%{starts_on: starts_on, weeks_total: total}, date) do
    " · " <>
      pgettext("meal plan, mid-sentence", "week %{n} of %{total}",
        n: week_number(starts_on, date),
        total: Kati.Locale.number(total)
      )
  end

  defp week_number(starts_on, date),
    do: Kati.Locale.number(div(Date.diff(date, starts_on), 7) + 1)

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
      hero: hero_figures("2,088", "2,100"),
      bars: [
        {week_label(1), 46, Palette.bar_neutral()},
        {week_label(2), 52, Palette.cream_ink()},
        {week_label(3), 61, Palette.red()},
        {week_label(4), 50, Palette.cream_ink()}
      ],
      counts: count_cards(percent(84), Kati.Locale.number(126), Kati.Locale.number(24)),
      macros: [
        macro(gettext("Protein"), 149, 168, 0.89, Palette.ink()),
        macro(gettext("Carbs"), 205, 210, 0.98, Palette.bronze()),
        macro(gettext("Fat"), 64, 70, 0.91, Palette.bar_gold()),
        macro(gettext("Fibre"), 27, 35, 0.77, Palette.bar_ink())
      ]
    }
  end

  def period_data("All") do
    %{
      hero: hero_figures("2,062", "2,100"),
      bars: [
        {Kati.Locale.number(1), 38, Palette.bar_neutral()},
        {Kati.Locale.number(2), 44, Palette.bar_neutral()},
        {Kati.Locale.number(3), 49, Palette.cream_ink()},
        {Kati.Locale.number(4), 52, Palette.cream_ink()},
        {Kati.Locale.number(5), 47, Palette.bar_neutral()},
        {Kati.Locale.number(6), 51, Palette.cream_ink()},
        {Kati.Locale.number(7), 58, Palette.cream_ink()},
        {Kati.Locale.number(8), 62, Palette.red()},
        {Kati.Locale.number(9), 55, Palette.cream_ink()},
        {Kati.Locale.number(10), 43, Palette.bar_neutral()},
        {Kati.Locale.number(11), 50, Palette.cream_ink()},
        {Kati.Locale.number(12), 46, Palette.bar_neutral()}
      ],
      counts: count_cards(percent(81), Kati.Locale.number(340), Kati.Locale.number(80)),
      macros: [
        macro(gettext("Protein"), 146, 168, 0.87, Palette.ink()),
        macro(gettext("Carbs"), 212, 210, 1.0, Palette.bronze()),
        macro(gettext("Fat"), 66, 70, 0.94, Palette.bar_gold()),
        macro(gettext("Fibre"), 24, 35, 0.69, Palette.bar_ink())
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

  # A drawn macro row, and `fill` is passed rather than derived on purpose: it
  # is the width the DRAWING gives the bar, which is not always `grams /
  # target` — `212 / 210 g` is over its target and the drawing still stops the
  # bar at full, because a bar cannot say "nine grams past the end".
  defp macro(name, grams, target, fill, tone) do
    %{name: name, value: macro_value(grams, target), fill: fill, tone: tone}
  end

  # `Kati.Screens.Pushed` floats the ‹ Meals pill over this content, and unlike
  # screens 43 and 44 nothing sits opposite it — so this is a plain reservation
  # of the drawing's 42pt pill and the 16pt gap under it.
  @doc false
  def back_gap, do: ~MOB"<Spacer size={58} />"

  # `plan_line` is the one mono line on this screen whose script is not decided
  # here: `Cutting v3` is the reader's own plan name and `· هفته ۶ از ۱۲` is
  # the half `week_of/2` counts, so the run can be Latin, Persian or both.
  # `Kati.Locale.mono_face/1` asks the STRING rather than the reader — DM Mono
  # while it is ASCII, Vazirmatn at the mono size the moment it is not, since
  # `kati_mono.ttf` carries no Persian glyph and would hand the line to
  # Android's own substitute face.
  @doc false
  def header(plan_line) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column weight={1.0}>
          <Text
            text={gettext("Nutrition")}
            text_size={28}
            max_font_scale={1.6}
            font_weight="bold"
            letter_spacing={Kati.Locale.tracking(-0.03)}
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={5} />
          <Text
            text={plan_line}
            font_family={Kati.Locale.mono_face(plan_line)}
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
      period_keys()
      |> Enum.map(fn key -> segment(key, period_label(key), key == active) end)
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

  # The three periods, in the order the strip draws them, as KEYS and not as
  # words.
  #
  # `Kati.Meals.SampleNutrition.segments/0` was both at once, and a screen that
  # translates cannot let it stay both: the key is what `figures/1` builds its
  # map under, what `period_data/1` matches on and what `handle_tap/2` puts
  # back into the assign, while the word is only what the reader reads. Built
  # out of its own labels, a Persian strip taps `:period_هفته` into
  # `Map.fetch!(periods, "هفته")` — a KeyError on the first tap. The label was
  # doing two jobs and only one of them survives being translated;
  # `Kati.Screens.Weight` split board 109's range row the same way and its
  # three words are these three msgids.
  #
  # This is also where a fourth segment goes, and always was: a fourth name in
  # the fixture alone would have drawn a segment that no clause of
  # `period_data/1` answers and no key of `figures/1` holds.
  @doc false
  @spec period_keys() :: [String.t()]
  def period_keys, do: ["Week", "Month", "All"]

  # The word a segment shows. No catch-all clause: a key added above without a
  # word here should fail where it was added rather than draw itself in English
  # on a Persian strip — `Kati.Screens.Pushed`'s moduledoc makes the same
  # argument about a default `handle_tap/2`.
  @doc false
  @spec period_label(String.t()) :: String.t()
  def period_label("Week"), do: gettext("Week")
  def period_label("Month"), do: gettext("Month")
  def period_label("All"), do: gettext("All")

  @doc false
  def segment(key, label, on?) do
    # The tag carries the period's KEY and the segment draws its WORD, so one
    # handler serves all three and what comes back out of a tap is the string
    # `figures/1` filed its figures under rather than the string the reader
    # read.
    tap = {self(), String.to_atom("period_" <> key)}
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
              text={Kati.UI.eyebrow_label(hero.label)}
              font_family={Kati.Locale.mono_face(hero.label)}
              text_size={10.5}
              letter_spacing={Kati.Locale.tracking(0.16)}
              text_color={Palette.cream_meta()}
            />
            <Spacer size={7} />
            {Kati.Screens.Nutrition.average_figure(hero)}
          </Column>
          <Spacer size={12} />
          <Column width={52}>
            <Text
              text={Kati.UI.eyebrow_label(hero.target_label)}
              font_family={Kati.Locale.mono_face(hero.target_label)}
              text_size={10}
              letter_spacing={Kati.Locale.tracking(0.1)}
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
      letter_spacing={Kati.Locale.tracking(-0.04)}
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

  # The axis letter is `M` under one period and `ه۱` or `۷` under the others,
  # so the face is decided by the label rather than by the reader: DM Mono has
  # the Latin initials and none of U+06F0–U+06F9, and a Persian week number
  # left in it is handed to Android's own substitute face.
  @doc false
  def chart_label(letter) do
    ~MOB"""
    <Row weight={1.0} align="center">
      <Spacer weight={1.0} />
      <Text
        text={letter}
        font_family={Kati.Locale.mono_face(letter)}
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
          letter_spacing={Kati.Locale.tracking(-0.035)}
          text_color={tone}
          max_lines={1}
        />
        <Spacer size={5} />
        <Text
          text={Kati.UI.eyebrow_label(label)}
          font_family={Kati.Locale.mono_face(label)}
          text_size={10}
          letter_spacing={Kati.Locale.tracking(0.1)}
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
          font_family={Kati.Locale.mono_face(row.value)}
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
            font_family={Kati.Locale.mono_face(left)}
            text_size={10}
            text_color={Palette.tertiary()}
            max_lines={1}
          />
          <Spacer weight={1.0} />
          <Text
            text={right}
            font_family={Kati.Locale.mono_face(right)}
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
  #
  # Everything else about the label is `Kati.UI.eyebrow/2`'s and is repeated
  # here rather than approximated: the Persian face, the half-point the Persian
  # label takes instead of the tracking, and the weight that carries it. The
  # two eyebrows on this screen differ by the colour of a 13pt dash, and a
  # reader who could also tell them apart by their typeface would be reading a
  # distinction nobody drew.
  @doc false
  def muted_eyebrow(label) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        <Box width={13} height={2} corner_radius={1} background={Palette.rail_idle()} />
        <Spacer size={9} />
        <Text
          text={Kati.UI.eyebrow_label(label)}
          font_family={Kati.Locale.mono_face()}
          text_size={Kati.Locale.pick(10.5, 11)}
          font_weight={Kati.Locale.pick("normal", "semibold")}
          letter_spacing={Kati.Locale.tracking(0.16)}
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
  #
  # It is also the one paragraph on this screen, so it is the one line whose
  # leading is `Kati.Locale.leading/1`: Vazirmatn's ascenders and descenders
  # are not Plus Jakarta's, and 1.55 set on Persian closes the sentence up
  # until the diacritics of one line touch the next.
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
        line_height={Kati.Locale.leading(1.55)}
        text_color={Palette.cream_body()}
        weight={1.0}
      />
    </Row>
    """
  end

  # One clause for all three segments: the tag carries the period's key, so the
  # handler never learns their words — which is also what makes it safe in a
  # second language. What comes back out is one of `period_keys/0`, the same
  # string `figures/1` filed its three windows under. `:share` falls through
  # deliberately — the disc is drawn and its sheet is not this screen's to open.
  @impl true
  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "period_" <> key -> {:noreply, Mob.Socket.assign(socket, :period, key)}
      _ -> {:noreply, socket}
    end
  end
end
