defmodule Kati.Screens.Meal do
  @moduledoc """
  Screen 45 — a meal in full, pushed under Meals.

  Built to `test/design/screens/45.html`. It shares screens 04 and 08's
  shape — artwork with the paper gradient lifted back over it, chrome floating
  at 60pt, the title sitting on paper rather than on the photograph — and
  diverges where a meal differs from a film: the hero is 250pt instead of 330
  because the numbers matter more than the picture, and the first card under it
  is the portion.

  Its own chrome rather than `Kati.Screens.Pushed`, for the same reason screen
  08 has its own: the back pill has to float **over** the photograph, and the
  pushed frame draws it over paper.

  ## Where this diverges from the drawing

    * **The rating is five Material Symbols stars, not five `&starf;`
      characters.** Plus Jakarta Sans carries no U+2605 — screen 08 shipped
      that once and the card rendered empty. So the glyph changes and the mark
      does not, and `Kati.ScreenDesignLiteralTest` reads that as a match rather
      than a missing line: it maps `★` to the `star` glyph on both sides before
      comparing, because holding the character against the glyph would report
      all seven rating screens' deliberate substitution as an absence. The cost
      is strictness rather than silence — the drawing writes the five as a
      single run and this screen draws five separate `Text` nodes, so the row
      is only found at the `:squashed` tier, with its spacing thrown away.
    * **The macro bar's ends are square inside a rounded track.** The drawing
      clips them with `overflow:hidden`; Mob does not clip children.

  ## Where the data comes from

  `Kati.Meals`, through `meal/2` — the slot the push named, or, handed nothing,
  the day's earliest unlogged slot; either way with its recipe's ingredient
  lines loaded. Every figure is that recipe's own cached total at the slot's
  portion, and the three history rows are drawn one per fact the recipe can
  answer for. With no active plan the screen falls back to
  `Kati.Meals.SampleRecipe`.

  The drawing's rating row reads `★★★★★ · a keeper`, and the two words are
  lost: *"a keeper"* is an adjective for a five rather than a column. The stars
  are the stored number and the sub-line beside them is empty, which is the
  honest half of that row.

  No dock on a pushed screen, so the frame ends at 40 rather than 132.
  """
  use Mob.Screen
  use Gettext, backend: Kati.Gettext
  import Mob.Sigil

  require Ash.Query

  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaNumberField
  alias Kati.Components.MishkaSeparator
  alias Kati.Meals.MealLog
  alias Kati.Meals.MealPlanSlot
  alias Kati.Meals.Nutrition
  alias Kati.Meals.Recipe
  alias Kati.Meals.SampleRecipe, as: Sample
  alias Kati.Theme.Palette
  alias Kati.UI

  # `use Mob.Screen` rather than `Kati.Screens.Pushed`, so there is no `load/1`
  # and no `:params` assign — the push's params arrive here, one step earlier,
  # and this is the screen reading them.
  def mount(params, _session, socket) do
    Mob.Theme.set(Kati.Theme.current())
    # Resolves the stored locale into THIS process. `Gettext.put_locale/2`
    # snapshots into the calling process exactly as `Mob.Theme.set/1` does,
    # and a screen is its own process — see `Kati.Locale.activate/0`.
    Kati.Locale.activate()
    {:ok, Mob.Socket.assign(socket, :meal, meal(Kati.Time.today(), params))}
  end

  @doc """
  The meal this screen opens on when it was handed nothing: the day's next one,
  or the drawing's.

  Named no slot, the referent is the one the drawing itself names in its
  eyebrow — *"Dinner · 19:30 · today"*, the earliest slot today that has not
  been logged yet. Failing that (a day already fully logged) it is the day's
  first planned meal.

  With no active plan there is no such meal, and `Kati.Meals.SampleRecipe` is
  drawn instead — the values `test/design/screens/45.html` was captured
  from. FIDELITY's rule: *missing data is not a reason for a blank screen*.
  """
  @spec meal(Date.t()) :: map()
  def meal(date), do: meal(date, %{})

  @doc """
  The meal a push named, or — named nothing — `meal/1`'s answer.

  `%{slot_id: id}` is what a card on screen 43 now pushes.
  `Kati.Screens.MealsToday.meal_tag/1` gives every card a tag and
  `Kati.Screens.MealsToday.open_meal/2` resolves that tag back to the row it was
  drawn from, so tapping the 13:00 lunch opens the 13:00 lunch rather than the
  day's next unlogged meal — the same #84 that `Kati.Screens.MealEdit.meal/1`
  records on the editor, arriving here from the timeline rather than from the
  grid.

  ## Named-and-missing is NOT the same as named-nothing

  This paragraph used to say a slot that had gone *falls through to exactly the
  no-id answer*, and that was the defect. The two are different questions and
  `next_meal/1` only answers one of them: it is the earliest unlogged slot
  TODAY, so a card whose dinner had been removed from the plan opened on the
  LUNCH, drew the lunch's title and macros, and — because `mark_eaten/1` writes
  whatever this page resolved — logged the lunch when the reader pressed the
  button. You named one meal and the app ate another.

  Screen 66 carries the same distinction for the same reason, in
  `Kati.Screens.BookDetail.book/1`'s own words: *named-and-missing refuses,
  named-nothing is still the newest and still correct*. So:

    * **no `:slot_id` at all** — the gallery, the board, the dock — is
      `next_meal/1` and then the drawing. Unchanged, and it has to stay
      unchanged: `test/design/screens/45.html` was captured in exactly that
      state.
    * **a `:slot_id` that names nothing** is the DRAWING, straight away. It
      carries no `slot_id` and no `recipe_id`, so
      `Kati.Meals.MealLog.log_eaten/1` refuses it and the button writes
      nothing. A page that cannot name what it drew must not be able to write.

  Falling to the drawing rather than to a blank screen is still FIDELITY's
  rule; what changed is that it no longer falls to somebody else's dinner on
  the way.
  """
  @spec meal(Date.t(), map() | nil) :: map()
  def meal(date, params) do
    case Map.get(params || %{}, :slot_id) do
      id when is_binary(id) and id != "" ->
        case named_slot(params) do
          {slot, recipe} -> cooked(slot, recipe)
          nil -> drawn_meal()
        end

      _unnamed ->
        case next_meal(date) do
          {slot, recipe} -> cooked(slot, recipe)
          nil -> drawn_meal()
        end
    end
  end

  @doc """
  The params that name a meal to this screen, from a screen 43 timeline row.

  Here rather than at the timeline so the key is spelled once — the reason
  `Kati.Screens.MealEdit.params_for/1` sits on the editor and not on the grid.
  `:slot_id` and not `:meal_id`: what a timeline row identifies is the plan
  slot, which is what `Kati.Screens.MealSwap` already calls a swap's subject and
  what `mark_eaten/1` already writes against.

  A `Kati.Meals.SampleToday` row carries no slot id, and neither does a logged
  one — `Kati.Screens.MealsToday`'s `log_row/1` sets `slot_id: nil` on purpose —
  so both yield `%{}` and the bare push this replaced.
  """
  @spec params_for(map() | nil) :: map()
  def params_for(%{slot_id: id}) when is_binary(id) and id != "", do: %{slot_id: id}
  def params_for(_meal), do: %{}

  @doc "Screen 45 exactly as it is drawn, from `Kati.Meals.SampleRecipe`."
  @spec drawn_meal() :: map()
  def drawn_meal do
    Map.merge(Sample.meal(), %{
      split: Sample.split(),
      macros: Sample.macros(),
      minors: Sample.minors(),
      ingredients: Sample.ingredients(),
      method_facts: Sample.method_facts(),
      method: Sample.method(),
      history: Sample.history()
    })
  end

  # The slot a push named, loaded with the recipe behind it. `nil` for no id,
  # for an id that names nothing, and for a slot whose recipe has gone — each of
  # which leaves `meal/2` on `next_meal/1`, which is where it was before any of
  # this. A caller that names a row deleted under it must not fall through to
  # somebody else's dinner, and `next_meal/1` is not somebody else's: it is the
  # screen's own no-argument answer.
  #
  # Every named slot comes off screen 43's timeline, which is a timeline of
  # today — which is what keeps `cooked/2`'s eyebrow honest, since it writes
  # *"· today"* as a literal. A screen that one day opens a slot from another
  # day has to derive that word before it can.
  defp named_slot(params) do
    with id when is_binary(id) and id != "" <- Map.get(params || %{}, :slot_id),
         %MealPlanSlot{} = slot <- slot_for(id),
         %Recipe{} = recipe <- with_ingredients(slot.recipe_id) do
      {slot, recipe}
    else
      _none -> nil
    end
  end

  # `Ash.Query.filter` + `read_one`, the shape `Kati.Screens.MealSwap`'s own
  # `slot_for/1` already uses for the same lookup, rather than `Ash.get/2`.
  # `rescue` because a screen can be rendered before the repo is up, which is
  # the window `Kati.Screens.MealSwap.handed_over/0` documents at length.
  defp slot_for(id) do
    MealPlanSlot
    |> Ash.Query.filter(id == ^id)
    |> Ash.read_one()
    |> case do
      {:ok, slot} -> slot
      _error -> nil
    end
  rescue
    _error -> nil
  end

  defp next_meal(date) do
    with plan when not is_nil(plan) <- active_plan(),
         [_ | _] = slots <- cookable(plan, date),
         %MealPlanSlot{} = slot <- unlogged(slots, date),
         %Recipe{} = recipe <- with_ingredients(slot.recipe_id) do
      {slot, recipe}
    else
      _ -> nil
    end
  end

  defp cookable(plan, date) do
    MealPlanSlot
    |> Ash.Query.for_read(:on_day, %{
      meal_plan_id: plan.id,
      day_of_week: Date.day_of_week(date)
    })
    |> Ash.read!()
    |> Enum.filter(&(&1.state == :planned and &1.recipe_id))
  rescue
    _ -> []
  end

  # The earliest slot with nothing logged against it. A day whose meals are all
  # behind it has no *next* meal, and the screen opens on its first rather than
  # on nothing — the tap that got here came from a row, and a row that opens a
  # blank screen is worse than one that opens the wrong meal.
  defp unlogged(slots, date) do
    logged =
      date
      |> logs_on()
      |> Enum.filter(&(&1.state in [:eaten, :skipped]))
      |> MapSet.new(& &1.meal_plan_slot_id)

    Enum.find(slots, hd(slots), &(not MapSet.member?(logged, &1.id)))
  end

  defp with_ingredients(recipe_id) do
    case Ash.get(Recipe, recipe_id, load: [:ingredients]) do
      {:ok, recipe} -> recipe
      _ -> nil
    end
  rescue
    _ -> nil
  end

  defp cooked(slot, recipe) do
    portion = slot.portion_milli
    figures = Nutrition.scale(recipe_figures(recipe), portion)

    %{
      slot: slot_line(slot),
      title: recipe.title,
      seed: recipe.photo_seed,
      portion: portion_label(portion / Nutrition.one_portion()),
      # Carried so **Mark eaten** can write one. Without them the button had
      # nothing to log against, so it toggled a flag on the socket instead —
      # which drew a tick, survived until the screen was popped, and left
      # nothing behind. A control that looks like it worked is worse than one
      # that plainly does not.
      slot_id: slot.id,
      recipe_id: recipe.id,
      bookmarked: recipe.bookmarked,
      portion_milli: portion,
      plan_id: slot.meal_plan_id,
      # The eyebrow above is a SENTENCE — `Dinner · 19:30 · today` — and a
      # sentence cannot be written to a log. These two are the same two facts
      # unjoined, carried for `Kati.Meals.MealLog.log_eaten/1` so a meal logged
      # here keeps the name and the clock it keeps when it is logged from
      # screen 43's card. Parsing them back out of `:slot` would be a second
      # implementation of the format one line above.
      slot_name: slot.slot_name,
      slot_time: slot.slot_time,
      calories: Kati.Locale.number(figures.kcal),
      # The space belongs to the LAYOUT and not to the catalogue: `620` and the
      # unit are one inline run in the drawing (see `portion_figure/1`), and a
      # msgid with a leading space is a msgid a translator cannot see the edge
      # of. `kcal` alone is the entry `Kati.Screens.MealEdit` already made, so
      # the two screens cannot come to spell a calorie differently.
      unit: " " <> gettext("kcal"),
      split: split(figures),
      macros: macro_tiles_of(figures),
      minors: minors_of(figures),
      ingredients: Enum.map(recipe.ingredients, &ingredient_line(&1, portion)),
      method_facts: method_facts(recipe),
      method: recipe.method || "",
      history: history_rows(recipe)
    }
  end

  # The eyebrow over the photograph: `Dinner · 19:30 · today`, and
  # `شام · ۱۹:۳۰ · امروز` for the same slot. Three separate facts joined by a
  # `·`, so the join is the msgid rather than three fragments concatenated —
  # a translator who needs the clock at the other end of the sentence can move
  # it, which a `<>` between literals does not allow.
  #
  # The slot's own word goes through `Kati.Screens.MealEdit.slot_label/1`
  # rather than a fourth copy of the same four entries.
  # `Kati.Meals.MealPlanSlot.slot_name` is a free string on purpose, and that
  # function already carries the fallback that answers an invented fifth slot
  # its own word instead of raising inside a render.
  #
  # `· today` stays a literal for the reason `named_slot/1` gives: every slot
  # that reaches this screen is a slot of TODAY, and a screen that one day
  # opens another day's has to derive the word before it can.
  #
  # **A slot with no clock now loses the separator with it.** `clock/1`
  # answered `""` for a nil time and the sentence was assembled around it
  # regardless, so a slot the plan never gave an hour drew `Dinner ·  · today`
  # — two dots around a hole. Two sentences rather than a conditional fragment,
  # because a msgid has to be a literal at the call site.
  defp slot_line(%{slot_time: nil} = slot),
    do: gettext("%{slot} · today", slot: Kati.Screens.MealEdit.slot_label(slot.slot_name))

  defp slot_line(slot) do
    gettext("%{slot} · %{at} · today",
      slot: Kati.Screens.MealEdit.slot_label(slot.slot_name),
      at: Kati.Locale.time(slot.slot_time)
    )
  end

  # The drawing declares 34/42/24 rather than deriving it. What is derived here
  # is the same three shares by the energy each macro contributes — 4 kcal a
  # gram of protein and of carbohydrate, 9 a gram of fat — which is the only
  # reading that makes the bar a picture of the figure above it.
  defp split(figures) do
    protein = grams(figures.protein_mg) * 4
    carbs = grams(figures.carbs_mg) * 4
    fat = grams(figures.fat_mg) * 9
    total = protein + carbs + fat

    [
      {share(protein, total), Palette.ink()},
      {share(carbs, total), Palette.bronze()},
      {share(fat, total), Palette.bar_gold()}
    ]
  end

  defp share(_part, 0), do: 0.0
  defp share(part, total), do: Float.round(part / total, 2)

  defp macro_tiles_of(figures) do
    [
      {gettext("Protein"), grams_label(figures.protein_mg), Palette.ink()},
      {gettext("Carbs"), grams_label(figures.carbs_mg), Palette.bronze()},
      {gettext("Fat"), grams_label(figures.fat_mg), Palette.bar_gold()}
    ]
  end

  # Sodium is the one figure the drawing prints in milligrams, which is the
  # unit it is stored in — `840 mg`, not `0.84 g`.
  defp minors_of(figures) do
    [
      {gettext("Fibre"), grams_label(figures.fibre_mg)},
      {gettext("Sugar"), grams_label(figures.sugar_mg)},
      {gettext("Sodium"), gettext("%{n} mg", n: Kati.Locale.number(figures.sodium_mg))}
    ]
  end

  # `%{n} g` rather than `"#{n} g"`. A gram is a WORD in Persian — ۵۲ گرم — and
  # the numeral is the reader's, so both halves of the figure move. The msgid is
  # the one `Kati.Screens.MealEdit.grams/1` already made, which is why this is a
  # function of its own rather than the interpolation repeated five times.
  defp grams_label(milligrams), do: gettext("%{n} g", n: Kati.Locale.number(grams(milligrams)))

  # Each line carries its own kcal so the total is visibly the sum of its
  # parts, which is screen 45's claim about itself — and the reason
  # `Kati.Meals.RecipeIngredient` stores the figures on the line rather than
  # reaching through the food reference for them.
  defp ingredient_line(line, portion) do
    %{
      name: line.name,
      amount: amount(line.unit, scale_amount(line.amount_mg, portion)),
      calories: Kati.Locale.number(Nutrition.scale(Nutrition.take(line), portion).kcal)
    }
  end

  defp scale_amount(amount_mg, portion) do
    div(amount_mg * portion + div(Nutrition.one_portion(), 2), Nutrition.one_portion())
  end

  # `×2` keeps its sign and takes `Kati.Locale.ltr/1`: `×` is U+00D7, a
  # MATHEMATICAL sign and therefore a bidi neutral, so on a Persian page it
  # resolves to the paragraph's direction and lands to the right of the digits
  # — ۲× where every drawing writes ×2. An isolate pins the run to its own
  # direction, which is `Kati.Locale.ltr/1`'s whole job.
  defp amount(:piece, amount), do: Kati.Locale.ltr("×#{Kati.Locale.number(div(amount, 1000))}")

  # Every other unit is a WORD once the page is Persian — 150 g is ۱۵۰ گرم —
  # and `#{unit}` was interpolating the ATOM, so a folded screen would have
  # drawn `۱۵۰ g` with a Latin letter in it. `Kati.Screens.MealEdit.unit_amount/2`
  # already spells all eight units this column can hold, plural rules included,
  # and a second table here would be the same eight words kept twice — which is
  # the mistake `mark_eaten/1`'s own doc records about the write it shares.
  defp amount(unit, amount), do: Kati.Screens.MealEdit.unit_amount(unit, div(amount, 1000))

  # A fact with no column behind it is not drawn. A recipe that never sees an
  # oven has no oven temperature, and `Oven —°` would be worse than three facts
  # where the drawing has three and two where it has two.
  defp method_facts(recipe) do
    # The three labels are built inside anonymous functions rather than in a
    # `@fact_labels` module attribute, and that is not an accident of style:
    # `gettext/1` in a module attribute is evaluated at COMPILE time and freezes
    # into whichever locale the compiler happened to be in. These run per render.
    [
      {"schedule", recipe.minutes,
       fn minutes -> gettext("%{n} min", n: Kati.Locale.number(minutes)) end},
      {"local_fire_department", recipe.oven_c,
       fn celsius -> gettext("Oven %{n}°", n: Kati.Locale.number(celsius)) end},
      {"restaurant", recipe.serves,
       fn serves -> gettext("Serves %{n}", n: Kati.Locale.number(serves)) end}
    ]
    |> Enum.reject(fn {_icon, value, _label} -> is_nil(value) end)
    |> Enum.map(fn {icon, value, label} -> {icon, label.(value)} end)
  end

  # Three rows, each drawn only when there is something to say.
  #
  # The drawing's rating row reads `★★★★★ · a keeper`, and *"a keeper"* has no
  # column and is not one: it is an adjective for a five, not a fact about the
  # recipe. `Kati.Meals.Recipe` stores the number, so the number is drawn and
  # the sub-line beside the stars is empty rather than invented.
  defp history_rows(recipe) do
    eaten = eaten_logs(recipe)

    Enum.concat([
      eaten_row(eaten),
      rating_row(recipe.rating),
      note_row(recipe.note)
    ])
  end

  defp eaten_row([]), do: []

  defp eaten_row(logs) do
    last = logs |> Enum.map(& &1.logged_on) |> Enum.sort({:desc, Date}) |> hd()

    [
      %{
        icon: "event_repeat",
        title: times(length(logs)),
        sub: gettext("Last on %{day}", day: weekday(last)),
        stars: 0
      }
    ]
  end

  defp rating_row(rating) when is_integer(rating) and rating > 0,
    do: [%{icon: "star", title: gettext("Your rating"), sub: "", stars: rating}]

  defp rating_row(_rating), do: []

  # The note itself is what the reader typed, so it is drawn and never
  # translated — only the word over it is Kati's.
  defp note_row(note) when is_binary(note) and note != "",
    do: [%{icon: "sticky_note_2", title: gettext("Note"), sub: note, stars: 0}]

  defp note_row(_note), do: []

  # `pgettext/2` on the one-off, because `Eaten once` is two words and
  # `mix gettext.merge` fuzzy-matches a short msgid against any sentence that
  # resembles it. The counted form carries a placeholder and is safe as it is.
  #
  # Two clauses rather than `ngettext/4`: English says *once* and not *1 time*,
  # which is a different word rather than a different inflection, and the
  # second clause is therefore only ever reached with a count above one.
  defp times(1), do: pgettext("meal history", "Eaten once")
  defp times(count), do: gettext("Eaten %{n} times", n: Kati.Locale.number(count))

  # A weekday NAMED, with no day of the month beside it — which is the one
  # shape `Kati.Locale` has no helper for: `weekday_initial/1` is a chart axis's
  # single letter and `date/2`'s `:full` carries the day and the month as well.
  # So the pick is here, over the same two tables those two read, rather than a
  # sixth style added to `date/2` for one row on one screen.
  #
  # `Calendar.strftime(last, "%A")` was the English name in both scripts, and
  # `%A` has no locale to consult — Elixir's default calendar names its days in
  # English and nothing about `:fa` changes that.
  defp weekday(date) do
    Kati.Locale.pick(
      Kati.Time.day_name(date),
      Kati.Calendar.Shamsi.weekday_name(Kati.Calendar.Shamsi.weekday_index(date))
    )
  end

  defp grams(milligrams), do: div(milligrams, 1000)

  defp recipe_figures(recipe) do
    Map.new(Nutrition.fields(), fn field -> {field, Map.fetch!(recipe, :"total_#{field}")} end)
  end

  defp active_plan do
    case Kati.Meals.MealPlan |> Ash.Query.for_read(:active) |> Ash.read_one() do
      {:ok, plan} -> plan
      _ -> nil
    end
  rescue
    _ -> nil
  end

  defp logs_on(date) do
    MealLog
    |> Ash.Query.for_read(:on_day, %{on: date})
    |> Ash.read!()
  rescue
    _ -> []
  end

  defp eaten_logs(recipe) do
    MealLog
    |> Ash.Query.filter(recipe_id == ^recipe.id and state == :eaten)
    |> Ash.read!()
  rescue
    _ -> []
  end

  def render(assigns) do
    meal = assigns.meal

    ~MOB"""
    <Box
      fill_width={true}
      fill_height={true}
      background={:background}
      layout_direction={Kati.Locale.direction_prop()}
      font_family={Kati.Locale.face_prop()}
      accessibility_id={Kati.Screens.Identity.of(__MODULE__)}
    >
      <Scroll>
        <Column fill_width={true}>
          {Kati.Screens.Meal.artwork(meal)}
          <Column
            fill_width={true}
            padding_left={21}
            padding_right={21}
            padding_top={16}
            padding_bottom={40}
          >
            {Kati.Screens.Meal.portion_card(meal)}
            {Kati.Screens.Meal.actions(meal)}
            {UI.eyebrow(gettext("Ingredients · 1 portion"))}
            {Kati.Screens.Meal.ingredients(meal.ingredients)}
            {Kati.Screens.Meal.muted_eyebrow(gettext("Method"))}
            {Kati.Screens.Meal.method(meal)}
            {Kati.Screens.Meal.history_block(meal.history)}
          </Column>
        </Column>
      </Scroll>
      {Kati.Screens.Meal.chrome()}
    </Box>
    """
  end

  # The 250pt ground behind the photograph is `#DCD7CF`, and the only token in
  # `Kati.Theme.Palette` whose LIGHT value is `#DCD7CF` is `track_off` — whose
  # name means a switch's off track. The name is wrong here and the ladder is
  # right: `track_off` is placed on the drawing's INERT-FILL ladder rather than
  # its text one, which is exactly what an image ground is, and it lands on
  # `#3A3732` — a dark that still reads as a held slot behind a picture that
  # has not loaded. `placeholder` (`#E4E0D9`) names this meaning and is eight
  # units lighter, so taking it would move the frame.
  #
  # The slot eyebrow and the title below are NOT over media: `Kati.UI.paper_fade/1`
  # has already laid the page back over the bottom 130pt, which is why the title
  # is `:on_surface` and the eyebrow is `sub` rather than the `on_media` family.
  #
  # The eyebrow takes `Kati.Locale.mono_face/0` and not `"mono"`, because what
  # it holds is a sentence rather than a serial number: `kati_mono.ttf` carries
  # no Persian glyph, so `شام · ۱۹:۳۰ · امروز` in DM Mono is handed to Android's
  # substitute face and comes out beside Kati's own type in something that is
  # not. `Kati.UI.eyebrow_label/1` for the same reason `String.upcase/1` is
  # wrong there: Persian has no case, and upcasing it is a no-op that reads on
  # the diff as a rule being applied.
  #
  # The title keeps `line_height={1.1}` and takes no `max_lines`. It is a
  # RECIPE's own name, not a heading this app wrote — it can be long in either
  # script, it wraps in the drawing, and clipping it to one line would hide the
  # half of *Miso salmon, greens & rice* that says what is in it.
  @doc false
  def artwork(meal) do
    ~MOB"""
    <Box fill_width={true} height={250} background={Palette.track_off()}>
      {Kati.Screens.Meal.hero_art(meal)}
      <Box fill_width={true} fill_height={true} align="bottom">
        {Kati.UI.paper_fade(130)}
      </Box>
      <Box fill_width={true} fill_height={true} align="bottom">
        <Column fill_width={true} padding_left={21} padding_right={21} padding_bottom={4}>
          <Text
            text={Kati.UI.eyebrow_label(meal.slot)}
            font_family={Kati.Locale.mono_face()}
            text_size={10.5}
            letter_spacing={Kati.Locale.tracking(0.14)}
            text_color={Palette.sub()}
            max_lines={1}
          />
          <Spacer size={7} />
          <Text
            text={meal.title}
            text_size={26}
            font_weight="extrabold"
            letter_spacing={Kati.Locale.tracking(-0.035)}
            line_height={1.1}
            text_color={:on_surface}
          />
        </Column>
      </Box>
    </Box>
    """
  end

  @doc false
  def hero_art(meal) do
    case Kati.Design.Images.hero(meal.seed) do
      nil ->
        ~MOB"<Spacer size={0} />"

      src ->
        ~MOB"""
        <Image src={src} fill_width={true} height={250} content_mode="fill" />
        """
    end
  end

  # The card fill, not `chrome_fill/1`. The dock's 90%-opaque chrome reads as
  # glass over a blurred backdrop; there is no backdrop blur here, so over a
  # photograph it is simply see-through — the building behind the meal came
  # through the overflow disc. Every other floating disc in the app
  # (`Kati.Screens.Health.disc/2`, screen 47's share button) is opaque card.
  #
  # The pill's word is `gettext("Meals")` rather than
  # `Kati.Screens.Pushed.back_label/2`, because this screen draws its own chrome
  # and has no `:params` assign to read a `%{back: …}` out of — see the note on
  # `mount/2`. The two reach the same catalogue entry, and the difference is
  # that this one cannot yet say *Home* when the reader came from Home. That is
  # the same gap `back_label/2` was written to close, and closing it here is a
  # navigation change rather than a translation.
  @doc false
  def chrome do
    back = {self(), :back}
    fill = Palette.card()

    ~MOB"""
    <Box fill_width={true} fill_height={true} align="top">
      <Row fill_width={true} padding_left={21} padding_right={21} padding_top={60} align="center">
        <Row
          height={44}
          corner_radius={22}
          background={fill}
          shadow={Kati.Theme.shadow_button()}
          padding_left={12}
          padding_right={16}
          align="center"
          on_tap={back}
        >
          {Kati.UI.symbol(Kati.Screens.Pushed.back_glyph(), size: 17)}
          <Spacer size={6} />
          <Text
            text={gettext("Meals")}
            text_size={13.5}
            font_weight="semibold"
            letter_spacing={Kati.Locale.tracking(-0.01)}
            text_color={:on_surface}
            max_lines={1}
          />
        </Row>
        <Spacer weight={1.0} />
        {Kati.Screens.Meal.more_button()}
      </Row>
    </Box>
    """
  end

  # `Kati.Components.MishkaActionIcon`: an icon-only button on a raised
  # surface, which is exactly what this is. It could not be one until the
  # component took a `shadow` — a floating disc IS its shadow, and the comment
  # above is the whole argument for why this one is opaque card rather than
  # glass, which a flat `variant: :filled` would have thrown away.
  #
  # `shape: :circle` is an exact `size / 2`, so 44 gives the 22 written here
  # before. The glyph goes in as a child rather than as `icon:` because Kati's
  # icons are Material Symbols through `Kati.UI.symbol/2` — a `Text` in the
  # `symbols` family — not the component's own `:lg` Text. A child is wrapped
  # in a `<Row>` that hugs it, inside a Box that already centred it.
  @doc false
  def more_button do
    MishkaActionIcon.action_icon(
      [
        size: 44,
        shape: :circle,
        variant: :filled,
        background: Palette.card(),
        shadow: Kati.Theme.shadow_button(),
        on_tap: :more
      ],
      [Kati.UI.symbol("more_horiz", size: 21)]
    )
  end

  @doc false
  def portion_card(meal) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={18}
      >
        <Row fill_width={true} align="bottom">
          <Column weight={1.0}>
            <Text
              text={Kati.UI.eyebrow_label(gettext("Per portion"))}
              font_family={Kati.Locale.mono_face()}
              text_size={10.5}
              letter_spacing={Kati.Locale.tracking(0.16)}
              text_color={Palette.eyebrow()}
            />
            <Spacer size={6} />
            {Kati.Screens.Meal.portion_figure(meal)}
          </Column>
          <Spacer size={12} />
          {Kati.Screens.Meal.stepper(meal)}
        </Row>
        <Spacer size={14} />
        {Kati.Screens.Meal.macro_bar(meal)}
        <Spacer size={14} />
        {Kati.Screens.Meal.macro_tiles(meal)}
        <Spacer size={12} />
        {Kati.Screens.Meal.hairline(true)}
        <Spacer size={12} />
        {Kati.Screens.Meal.minors(meal)}
      </Column>
      <Spacer size={12} />
    </Column>
    """
  end

  # `620` and ` kcal` are one inline run in the drawing, so they share a
  # baseline. `align="bottom"` aligns the two text *boxes*, and a 32pt box
  # carries more descent than a 15pt one, so the unit sank below the figure —
  # a capture measured it 3.4pt low. `Kati.UI.number_with_unit/3` exists for
  # exactly this: the lift is the descent difference, 0.2 × (32 − 15) = 3.4.
  @doc false
  def portion_figure(meal) do
    number = ~MOB"""
    <Text
      text={meal.calories}
      text_size={32}
      font_weight="extrabold"
      letter_spacing={Kati.Locale.tracking(-0.04)}
      text_color={:on_surface}
      max_lines={1}
    />
    """

    unit = ~MOB"""
    <Text
      text={meal.unit}
      text_size={15}
      font_weight="semibold"
      text_color={Palette.muted()}
      max_lines={1}
    />
    """

    UI.number_with_unit(number, unit, 3.4)
  end

  # `remove` is muted and `add` is inked: at 1.0× there is nothing to take away
  # yet, which the drawing says with colour rather than with a disabled state.
  #
  # Drawn by hand rather than as `Kati.Components.MishkaNumberField`: that
  # component is a bordered strip — stepper, hairline, native TextField,
  # hairline, stepper — and this is a 32pt filled pill with no border, no rules
  # and no editable field, whose steppers are Material Symbols rather than the
  # component's "−"/"+" Text glyphs. Only its arithmetic is shared; see
  # `handle_info/2`.
  #
  # `Kati.Locale.mono_face/1` on the pill and not `mono_face/0`: the label is
  # `portion_label/1`'s, so it is `۱٫۲۵×` for a Persian reader and `1.25×` for a
  # Latin one, and `kati_mono.ttf` carries none of U+06F0–U+06F9. Asking the
  # STRING rather than the reader keeps the drawn meal — whose `1.0×` comes off
  # `Kati.Meals.SampleRecipe` as ASCII — in DM Mono on a Persian page, which is
  # the right answer for a figure that has no Persian in it.
  @doc false
  def stepper(meal) do
    down = {self(), :portion_down}
    up = {self(), :portion_up}

    ~MOB"""
    <Row
      height={32}
      corner_radius={16}
      background={Palette.paper()}
      padding_left={12}
      padding_right={12}
      align="center"
    >
      <Box on_tap={down} width={16} height={16} align="center">
        {Kati.UI.symbol("remove", size: 16, color: Palette.sub())}
      </Box>
      <Spacer size={7} />
      <Text
        text={meal.portion}
        font_family={Kati.Locale.mono_face(meal.portion)}
        text_size={13}
        font_weight="medium"
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer size={7} />
      <Box on_tap={up} width={16} height={16} align="center">
        {Kati.UI.symbol("add", size: 16)}
      </Box>
    </Row>
    """
  end

  # `paper`, not `track`. This screen draws every well on its cards — this bar's
  # unfilled part, the stepper pill, the macro tiles, the history icon discs —
  # at `#EFECE7`, the page colour, rather than at the `#E7E3DC` the palette
  # calls "the unfilled part of a progress bar". So they all take `paper` and
  # sink to `#121110` in dark: a hole punched through the card down to the page,
  # which is the same reading they have in light.
  @doc false
  def macro_bar(meal) do
    ~MOB"""
    <Box fill_width={true} height={10} corner_radius={5} background={Palette.paper()}>
      <Row fill_width={true}>
        {Enum.map(meal.split, fn {share, tone} -> Kati.Screens.Meal.segment(share, tone) end)}
      </Row>
    </Box>
    """
  end

  # A macro that contributed nothing draws nothing rather than a segment of
  # zero weight: `weight` is a share of the leftover space, and a share of zero
  # is a different question from no width. The drawing never asks it — 34/42/24
  # — and a recipe with no figures yet asks it on the first tap.
  @doc false
  def segment(share, _tone) when share == 0 do
    ~MOB"""
    <Spacer size={0} />
    """
  end

  def segment(share, tone) do
    ~MOB"""
    <Box weight={share} height={10} background={tone} />
    """
  end

  @doc false
  def macro_tiles(meal) do
    tiles =
      meal.macros
      |> Enum.map(fn {name, value, tone} -> macro_tile(name, value, tone) end)
      |> Enum.intersperse(tile_gap())

    ~MOB"""
    <Row fill_width={true} align="top">
      {tiles}
    </Row>
    """
  end

  @doc false
  def tile_gap, do: ~MOB"<Spacer size={10} />"

  @doc false
  def macro_tile(name, value, tone) do
    ~MOB"""
    <Box weight={1.0}>
      <Column fill_width={true} background={Palette.paper()} corner_radius={14} padding={11}>
        <Row fill_width={true} align="center">
          <Box width={6} height={6} corner_radius={2} background={tone} />
          <Spacer size={5} />
          <Text
            text={Kati.UI.eyebrow_label(name)}
            font_family={Kati.Locale.mono_face()}
            text_size={9}
            letter_spacing={Kati.Locale.tracking(0.1)}
            text_color={Palette.eyebrow()}
            max_lines={1}
          />
        </Row>
        <Spacer size={6} />
        <Text text={value} text_size={16} font_weight="bold" text_color={:on_surface} max_lines={1} />
      </Column>
    </Box>
    """
  end

  @doc false
  def minors(meal) do
    columns =
      meal.minors
      |> Enum.map(fn {label, value} -> minor(label, value) end)
      |> Enum.intersperse(minor_gap())

    ~MOB"""
    <Row fill_width={true} align="top">
      {columns}
    </Row>
    """
  end

  @doc false
  def minor_gap, do: ~MOB"<Spacer size={14} />"

  @doc false
  def minor(label, value) do
    ~MOB"""
    <Column weight={1.0}>
      <Text
        text={Kati.UI.eyebrow_label(label)}
        font_family={Kati.Locale.mono_face()}
        text_size={9}
        letter_spacing={Kati.Locale.tracking(0.1)}
        text_color={Palette.eyebrow()}
        max_lines={1}
      />
      <Spacer size={4} />
      <Text
        text={value}
        text_size={13}
        font_weight="semibold"
        text_color={Palette.ink_soft()}
        max_lines={1}
      />
    </Column>
    """
  end

  # `Mark eaten` is this screen's call-to-action, so it takes `ink_fill` — the
  # palette's name for the hero CTA pill's fill, the one `0xFF1A1917` meaning
  # that inverts to a WARM `#F7EFE4` in dark rather than to `ink`'s `#F5F2EE`.
  # Screen 28 draws that inversion: the pill goes paper-filled and its label
  # goes ink, which is `on_ink` — the other half of the pair, and the reason
  # the glyph and the label here are `on_ink` rather than `card`. The two discs
  # beside it are surfaces, not fills, so they are `card`.
  #
  # The shadow keeps the drawing's own recipe; dark's card treatment is
  # `Kati.Theme`'s business, not a colour table's.
  @doc false
  def actions(meal) do
    eat = {self(), :mark_eaten}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Box weight={1.0}>
          <Box
            fill_width={true}
            height={50}
            corner_radius={25}
            background={Palette.ink_fill()}
            shadow="0 12 24 -12 #D91A1917"
            align="center"
            on_tap={eat}
          >
            <Row fill_width={true} align="center">
              <Spacer weight={1.0} />
              {Kati.UI.symbol("check", size: 19, color: Palette.on_ink())}
              <Spacer size={8} />
              <Text
                text={gettext("Mark eaten")}
                text_size={14}
                font_weight="bold"
                text_color={Palette.on_ink()}
                max_lines={1}
              />
              <Spacer weight={1.0} />
            </Row>
          </Box>
        </Box>
        <Spacer size={10} />
        {Kati.Screens.Meal.disc("swap_horiz", :swap)}
        <Spacer size={10} />
        {Kati.Screens.Meal.bookmark(meal)}
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  # The two 50pt discs beside `Mark eaten` are `MishkaActionIcon` for the same
  # reason the chrome's is: an icon-only button whose lift off the paper is the
  # thing that makes it read as a button at all. `shadow` is the card-soft
  # recipe the drawing gives them, passed through untouched — the component
  # does not interpret it, it hands the string to the container.
  #
  # `shape: :circle` computes 50 / 2 = 25.0, the radius that was written here.
  @doc """
  The bookmark disc, filled when the recipe is bookmarked.

  The disc drew and did nothing for as long as the screen existed, because
  `Kati.Meals.Recipe` had no column to hold the answer —
  `Kati.ScreenTapSweepTest`'s backlog listed it under *a button that never
  marks anything*. It has one now.

  Filled rather than merely darker, because the glyph is the state: an outline
  bookmark and a solid one are what the Material set gives for exactly this,
  and a disc that changed only its background would be saying the same thing in
  a way that has to be learned.

  On the drawing — no plan, so no recipe — it stays outlined and inert. There
  is nothing to bookmark, and inventing a row to record the tap against would
  be inventing the meal it belongs to.
  """
  @spec bookmark(map()) :: map()
  def bookmark(meal) do
    on? = Map.get(meal, :bookmarked, false)

    MishkaActionIcon.action_icon(
      [
        size: 50,
        shape: :circle,
        variant: :filled,
        background: if(on?, do: Palette.ink_fill(), else: Palette.card()),
        shadow: Kati.Theme.shadow_card_soft(),
        on_tap: :save
      ],
      [
        Kati.UI.symbol("bookmark",
          size: 21,
          fill: on?,
          color: if(on?, do: Palette.on_ink(), else: Palette.ink())
        )
      ]
    )
  end

  @doc false
  def disc(icon, tag) do
    MishkaActionIcon.action_icon(
      [
        size: 50,
        shape: :circle,
        variant: :filled,
        background: Palette.card(),
        shadow: Kati.Theme.shadow_card_soft(),
        on_tap: tag
      ],
      [Kati.UI.symbol(icon, size: 21)]
    )
  end

  @doc false
  def ingredients(rows) do
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
        {rows |> Enum.with_index() |> Enum.map(fn {row, i} -> Kati.Screens.Meal.ingredient_row(row, i < last) end)}
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  # The name is the RECIPE's — typed by the reader or imported with the recipe —
  # so it is drawn as stored and never translated. The two mono columns beside
  # it are Kati's own and both ask `Kati.Locale.mono_face/1` which face they
  # need. Neither can stay in DM Mono on a Persian page: `kati_mono.ttf` carries
  # no Persian letter for `۱۵۰ گرم` and none of U+06F0–U+06F9 for `۳۱۲` either,
  # which is the rule `Kati.PersianFontTest` states as *Persian numerals are set
  # in `fa` at the design's mono size*.
  #
  # `mono_face/1` and not `mono_face/0` because the two sources of these strings
  # disagree: a cooked meal's are the reader's script and a drawn one's come off
  # `Kati.Meals.SampleRecipe` as ASCII, and `150 g` beside `312` has every glyph
  # it needs in DM Mono whatever language the page is in. Asking the STRING
  # answers both without a branch on where the row came from.
  #
  # `text_align="right"` is absolute rather than direction-relative and stays
  # that way: nothing in the app mirrors a text alignment yet, and inside a
  # 30pt box the whole of the difference is a few points.
  @doc false
  def ingredient_row(row, rule?) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={12} padding_bottom={12}>
        <Box
          width={20}
          height={20}
          corner_radius={6}
          border_width={1.5}
          border_color={Palette.border()}
        />
        <Spacer size={13} />
        <Text
          text={row.name}
          text_size={13}
          font_weight="semibold"
          text_color={:on_surface}
          weight={1.0}
          max_lines={1}
        />
        <Spacer size={13} />
        <Text
          text={row.amount}
          font_family={Kati.Locale.mono_face(row.amount)}
          text_size={11.5}
          text_color={Palette.ink_soft()}
          max_lines={1}
        />
        <Spacer size={13} />
        <Column width={30}>
          <Text
            text={row.calories}
            font_family={Kati.Locale.mono_face(row.calories)}
            text_size={10.5}
            text_color={Palette.rail_idle()}
            text_align="right"
            max_lines={1}
          />
        </Column>
      </Row>
      {Kati.Screens.Meal.hairline(rule?)}
    </Column>
    """
  end

  # Kati.UI.eyebrow's dash is always the accent, and orange means new or now.
  # Method and History are neither, so the drawing gives them a #C4BDB3 dash.
  #
  # Everything else about the label is `Kati.UI.eyebrow/2`'s, down to the two
  # values it picks by script: 11pt semibold in Persian where Latin takes 10.5
  # normal. Those picks are copied rather than left out because this eyebrow and
  # that one sit on the SAME page — *Ingredients* is drawn by
  # `Kati.UI.eyebrow/2` and *Method* by this, a card below it — and two eyebrows
  # in one stack that disagree about their size is the one difference a reader
  # of either script cannot help seeing. They are copied rather than shared
  # because the only difference left between the two functions would then be the
  # dash colour, and `Kati.UI.eyebrow/2` already takes that as an option; that
  # merge is a change to what this screen draws in BOTH scripts, which is not
  # what a fold is for.
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

  # On cream, like screen 08's note: the design's one warm surface, used here
  # for the part of the card a person reads rather than counts.
  #
  # The paragraph is the one place on this screen a reader READS rather than
  # scans, so it takes `Kati.Locale.leading/1`: the drawing's 1.65 in Latin and
  # `Kati.Theme.fa_line_height/0` in Persian, because Vazirmatn's ascenders and
  # descenders are not Plus Jakarta's and a method set at 1.65 collides with
  # itself. The method text itself is the recipe's, so it is never translated.
  @doc false
  def method(meal) do
    facts =
      meal.method_facts
      |> Enum.map(fn {icon, label} -> fact(icon, label) end)
      |> Enum.intersperse(fact_gap())

    ~MOB"""
    <Column fill_width={true}>
      <Column fill_width={true} background={Palette.cream()} corner_radius={20} padding={17}>
        <Row fill_width={true} align="center">
          {facts}
        </Row>
        <Spacer size={13} />
        <Text
          text={meal.method}
          text_size={13.5}
          line_height={Kati.Locale.leading(1.65)}
          text_color={Palette.cream_body()}
        />
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def fact_gap, do: ~MOB"<Spacer size={14} />"

  @doc false
  def fact(icon, label) do
    ~MOB"""
    <Row align="center">
      {Kati.UI.symbol(icon, size: 15, color: Palette.gold_icon())}
      <Spacer size={6} />
      <Text
        text={label}
        text_size={11.5}
        font_weight="semibold"
        text_color={Palette.cream_sub()}
        max_lines={1}
      />
    </Row>
    """
  end

  # The eyebrow belongs to the card, not to the screen: a recipe nobody has
  # eaten, rated or written a note about has no history, and an eyebrow over an
  # empty card states a heading for nothing. Both are absent together, or
  # neither is — and in the drawing all three rows are there, so both are.
  @doc false
  def history_block([]), do: []

  def history_block(rows) do
    [muted_eyebrow(gettext("History")), history(rows)]
  end

  @doc false
  def history(rows) do
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
      {rows |> Enum.with_index() |> Enum.map(fn {row, i} -> Kati.Screens.Meal.history_row(row, i < last) end)}
    </Column>
    """
  end

  # `Kati.Locale.forward_chevron/0` and not `"chevron_right"`. Material Symbols
  # are text in a font and auto-mirror nothing, so a right-pointing chevron on a
  # right-to-left row points back the way the reader came.
  #
  # It points and opens nothing: this row carries no `on_tap` and never has, on
  # any of the three facts. That is a separate question from which way it faces
  # — a chevron that lies about the direction is wrong in one script whether or
  # not it is also wrong about being a control.
  @doc false
  def history_row(row, rule?) do
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
          {Kati.Screens.Meal.history_sub(row)}
        </Column>
        <Spacer size={13} />
        {Kati.UI.symbol(Kati.Locale.forward_chevron(), size: 18, color: Palette.rail_idle())}
      </Row>
      {Kati.Screens.Meal.hairline(rule?)}
    </Column>
    """
  end

  # Material Symbols, not U+2605 — screen 08 proved the text version renders as
  # nothing at all in Plus Jakarta Sans, which reads as a layout bug rather
  # than a missing glyph.
  @doc false
  def history_sub(%{stars: 0} = row) do
    ~MOB"""
    <Text text={row.sub} text_size={11.5} text_color={Palette.sub()} max_lines={1} />
    """
  end

  def history_sub(row) do
    ~MOB"""
    <Row align="center">
      {Enum.map(1..row.stars, fn _ -> Kati.Screens.Meal.star() end)}
      <Text text={row.sub} text_size={11.5} text_color={Palette.sub()} max_lines={1} />
    </Row>
    """
  end

  @doc false
  def star, do: Kati.UI.symbol("star", size: 12, color: Palette.sub(), fill: true)

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

  def handle_info({:tap, :back}, socket), do: {:noreply, Kati.Screens.Resume.pop(socket)}

  # The meal on screen goes with the tap. Screen 43 hands its slot to 46 through
  # `Mob.State` — `Kati.Screens.MealSwap.hand_over/1` — and this disc handed over
  # nothing at all, so 46 opened on whatever slot the store still held from an
  # earlier tap on a different screen, or on `Kati.Meals.SampleSwap`. Named in
  # the push rather than in the store because the push is the thing that cannot
  # go stale: it is written and read inside one navigation.
  #
  # A drawn meal has no slot id and pushes `%{}`, which leaves 46 reading the
  # store exactly as it does today.
  def handle_info({:tap, :swap}, socket) do
    params = Kati.Screens.MealSwap.params_for(socket.assigns.meal)

    {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.MealSwap, params)}
  end

  # The stepper moves in quarters and stops at 0.5x, which is what the drawing
  # implies by muting `remove` at 1.0x rather than hiding it: there is a floor,
  # and it is below where the screen opens.
  #
  # The arithmetic is `Kati.Components.MishkaNumberField.step/3` rather than a
  # hand-rolled `+ delta |> max |> min`, because that is precisely the function
  # the component exposes for callers who draw their own stepper — it clamps
  # into `[min, max]` and rounds to the step's own precision, so repeated
  # quarters cannot drift into 1.7500000000000002 and print as `1.75×` one tap
  # and `1.76×` the next. The pill above is still drawn by hand: see the note
  # on `stepper/1`.
  def handle_info({:tap, step}, socket) when step in [:portion_up, :portion_down] do
    meal = socket.assigns.meal
    direction = if step == :portion_up, do: :up, else: :down

    factor =
      meal.portion
      |> Kati.Screens.Meal.portion_factor()
      |> MishkaNumberField.step(direction, step: 0.25, min: 0.5, max: 4.0)

    {:noreply,
     Mob.Socket.assign(socket, :meal, %{meal | portion: Kati.Screens.Meal.portion_label(factor)})}
  end

  @doc """
  Bookmark the recipe, or take the bookmark off.

  A toggle on the row rather than an add-only action: the disc is the same disc
  either way, and a control that can only ever be pressed once is a control
  that lies the second time.

  On the drawing there is no recipe, so nothing is written and nothing is
  toggled — see `bookmark/1`.
  """
  def handle_info({:tap, :save}, socket) do
    {:noreply, Kati.Screens.Meal.toggle_bookmark(socket)}
  end

  # Mark the meal eaten, for real. A comment rather than a second `@doc`,
  # because these are clauses of one `handle_info/2` and the clause above
  # already carries the doc.
  #
  # This used to flip `:eaten` on the socket — a tick that drew, survived until
  # the screen was popped, and left nothing in the store. Screen 43's button had
  # the same shape and `Kati.MealsTodayWriteTest` is what settled it; this is the
  # same write from the detail page, through the same action, so the two cannot
  # come to disagree about what marking a meal means.
  #
  # `Kati.Meals.MealLog`'s `:log_recipe` freezes the figures at the moment of the
  # claim, which is why the portion goes in as the slot's rather than as this
  # screen's label: `portion_label/1` is for reading and `portion_milli` is what
  # the arithmetic is done on.
  #
  # With no active plan the screen is `Kati.Meals.SampleRecipe`'s drawing and
  # there is no slot to log against, so the tap keeps its old local toggle. A
  # drawn meal is not a planned one, and writing a log for a meal nobody planned
  # would be inventing the row it then displayed.
  def handle_info({:tap, :mark_eaten}, socket) do
    {:noreply, Kati.Screens.Meal.mark_eaten(socket)}
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  @doc false
  @spec toggle_bookmark(Mob.Socket.t()) :: Mob.Socket.t()
  def toggle_bookmark(socket) do
    meal = socket.assigns.meal
    wanted = not Map.get(meal, :bookmarked, false)

    with id when is_binary(id) <- meal[:recipe_id],
         {:ok, recipe} <- Ash.get(Kati.Meals.Recipe, id),
         {:ok, _updated} <-
           recipe
           |> Ash.Changeset.for_update(:update, %{bookmarked: wanted})
           |> Ash.update()
           |> Kati.Write.note("bookmark #{meal.title}") do
      Mob.Socket.assign(socket, :meal, Map.put(meal, :bookmarked, wanted))
    else
      _drawn_or_failed -> socket
    end
  end

  @doc """
  Write that this page's meal was eaten.

  **Through `Kati.Meals.MealLog.log_eaten/1`, which screen 43's timeline card
  also calls.** The two used to spell the same seven attributes out separately,
  and both spellings were missing `slot_name` and `slot_time` — so a meal
  logged from either screen came back with no clock and no eyebrow. Two copies
  of one write is two chances to lose the same field, which is what happened,
  and one function is the fix `Kati.Screens.Books.rail/2` records for a value
  read twice.

  The row is `socket.assigns.meal` — what `meal/2` RESOLVED at mount and this
  page has been drawing since. `log_eaten/1` reads its ids and queries for
  nothing, so there is no path from this button to a slot the reader is not
  looking at, and a page showing `Kati.Meals.SampleRecipe` has no ids to give:
  the store is left alone and only the tick moves, which is what
  `Kati.MealsTodayWriteTest` pins.
  """
  @spec mark_eaten(Mob.Socket.t()) :: Mob.Socket.t()
  def mark_eaten(socket) do
    meal = socket.assigns.meal

    case Kati.Meals.MealLog.log_eaten(meal) do
      {:ok, _log} ->
        Mob.Socket.assign(socket, :meal, Map.put(meal, :eaten, true))

      :error ->
        # The drawing. It has no slot and no recipe, so there is nothing to log
        # — the tick is local and dies with the screen, which is the honest
        # thing a board-shaped page can do with the tap.
        Mob.Socket.assign(socket, :meal, Map.put(meal, :eaten, not Map.get(meal, :eaten, false)))

      {:error, _reason} ->
        socket
    end
  end

  @doc """
  The multiplier the pill is showing, read back out of its own label.

  ## It has to fold the digits before it parses them

  This was `Float.parse/1`, and under `:fa` that is a defect rather than an
  inelegance: `portion_label/1` writes the reader's own numerals, so the string
  handed back here is `۱٫۲۵×` — Persian digits around U+066B — and
  `Float.parse/1` answers `:error` on the first character. The `:error` clause
  is a FALLBACK and it answered `1.0`, so every tap of `add` moved the portion
  from 1.0 to 1.25, and the next tap read 1.25 as 1.0 and moved it to 1.25
  again. The pill counted 1.0, 1.25, 1.25, 1.25 and the stepper looked broken
  in exactly one language.

  `Kati.I18n.Digits.parse_float/1` folds U+06F0–U+06F9 and U+066B down to ASCII
  first, so both scripts round-trip. `Kati.Screens.MealEdit.figures/3` names
  this file as the one that keeps a number inside a label and says a label is a
  poor place to keep one; that is still true and is a larger change than this.
  At least the label round-trips now.
  """
  @spec portion_factor(String.t()) :: float()
  def portion_factor(label) do
    case Kati.I18n.Digits.parse_float(String.trim_trailing(label, "×")) do
      {n, _rest} -> n
      :error -> 1.0
    end
  end

  @doc false
  @spec portion_label(float()) :: String.t()
  def portion_label(factor) do
    # "1.0×", not "1×". The drawing prints one decimal on a whole portion, and
    # the stepper must not be the thing that changes what the screen says at
    # rest — screen 45 is compared against that frame.
    text =
      case :erlang.float_to_binary(factor, decimals: 2) do
        <<head::binary-size(3), "0">> -> head
        other -> other
      end

    # The digits are the reader's, and `Kati.Locale.number/1` moves the DECIMAL
    # SEPARATOR with them — ۱٫۰ with U+066B, not Persian numerals around a Latin
    # full stop. `×` is U+00D7, a mathematical sign rather than a letter and the
    # same sign in both scripts, so it is appended and never translated. This is
    # `Kati.Screens.MealEdit.portion_label/1`'s shape, arrived at from the other
    # end: that one holds the float and renders it, this one holds the string.
    Kati.Locale.number(text) <> "×"
  end
end
