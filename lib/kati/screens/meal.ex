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

  `Kati.Meals`, through `meal/1` — the day's earliest unlogged slot and its
  recipe, ingredient lines loaded, because nothing hands this screen an id.
  Every figure is that recipe's own cached total at the slot's portion, and the
  three history rows are drawn one per fact the recipe can answer for. With no
  active plan the screen falls back to `Kati.Meals.SampleRecipe`.

  The drawing's rating row reads `★★★★★ · a keeper`, and the two words are
  lost: *"a keeper"* is an adjective for a five rather than a column. The stars
  are the stored number and the sub-line beside them is empty, which is the
  honest half of that row.

  No dock on a pushed screen, so the frame ends at 40 rather than 132.
  """
  use Mob.Screen
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

  def mount(_params, _session, socket) do
    Mob.Theme.set(Kati.Theme.current())
    {:ok, Mob.Socket.assign(socket, :meal, meal(Kati.Time.today()))}
  end

  @doc """
  The meal this screen opens on: the day's next one, or the drawing's.

  Nothing hands this screen an id — `Kati.Screens.MealsToday` pushes it from a
  row that carries the tag `:open_meal` and no meal with it — so the referent
  is the one the drawing itself names in its eyebrow: *"Dinner · 19:30 ·
  today"*, the earliest slot today that has not been logged yet. Failing that
  (a day already fully logged) it is the day's first planned meal.

  With no active plan there is no such meal, and `Kati.Meals.SampleRecipe` is
  drawn instead — the values `test/design/screens/45.html` was captured
  from. FIDELITY's rule: *missing data is not a reason for a blank screen*.
  """
  @spec meal(Date.t()) :: map()
  def meal(date) do
    case next_meal(date) do
      {slot, recipe} -> cooked(slot, recipe)
      nil -> drawn_meal()
    end
  end

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
      slot: "#{slot.slot_name} · #{clock(slot.slot_time)} · today",
      title: recipe.title,
      seed: recipe.photo_seed,
      portion: portion_label(portion / Nutrition.one_portion()),
      calories: "#{figures.kcal}",
      unit: " kcal",
      split: split(figures),
      macros: macro_tiles_of(figures),
      minors: minors_of(figures),
      ingredients: Enum.map(recipe.ingredients, &ingredient_line(&1, portion)),
      method_facts: method_facts(recipe),
      method: recipe.method || "",
      history: history_rows(recipe)
    }
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
      {"Protein", "#{grams(figures.protein_mg)} g", Palette.ink()},
      {"Carbs", "#{grams(figures.carbs_mg)} g", Palette.bronze()},
      {"Fat", "#{grams(figures.fat_mg)} g", Palette.bar_gold()}
    ]
  end

  # Sodium is the one figure the drawing prints in milligrams, which is the
  # unit it is stored in — `840 mg`, not `0.84 g`.
  defp minors_of(figures) do
    [
      {"Fibre", "#{grams(figures.fibre_mg)} g"},
      {"Sugar", "#{grams(figures.sugar_mg)} g"},
      {"Sodium", "#{figures.sodium_mg} mg"}
    ]
  end

  # Each line carries its own kcal so the total is visibly the sum of its
  # parts, which is screen 45's claim about itself — and the reason
  # `Kati.Meals.RecipeIngredient` stores the figures on the line rather than
  # reaching through the food reference for them.
  defp ingredient_line(line, portion) do
    %{
      name: line.name,
      amount: amount(line.unit, scale_amount(line.amount_mg, portion)),
      calories: "#{Nutrition.scale(Nutrition.take(line), portion).kcal}"
    }
  end

  defp scale_amount(amount_mg, portion) do
    div(amount_mg * portion + div(Nutrition.one_portion(), 2), Nutrition.one_portion())
  end

  defp amount(:piece, amount), do: "×#{div(amount, 1000)}"
  defp amount(unit, amount), do: "#{div(amount, 1000)} #{unit}"

  # A fact with no column behind it is not drawn. A recipe that never sees an
  # oven has no oven temperature, and `Oven —°` would be worse than three facts
  # where the drawing has three and two where it has two.
  defp method_facts(recipe) do
    [
      {"schedule", recipe.minutes, fn minutes -> "#{minutes} min" end},
      {"local_fire_department", recipe.oven_c, fn celsius -> "Oven #{celsius}°" end},
      {"restaurant", recipe.serves, fn serves -> "Serves #{serves}" end}
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
        sub: "Last on #{Calendar.strftime(last, "%A")}",
        stars: 0
      }
    ]
  end

  defp rating_row(rating) when is_integer(rating) and rating > 0,
    do: [%{icon: "star", title: "Your rating", sub: "", stars: rating}]

  defp rating_row(_rating), do: []

  defp note_row(note) when is_binary(note) and note != "",
    do: [%{icon: "sticky_note_2", title: "Note", sub: note, stars: 0}]

  defp note_row(_note), do: []

  defp times(1), do: "Eaten once"
  defp times(count), do: "Eaten #{count} times"

  defp grams(milligrams), do: div(milligrams, 1000)

  defp clock(nil), do: ""
  defp clock(time), do: Calendar.strftime(time, "%H:%M")

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
            {Kati.Screens.Meal.actions()}
            {UI.eyebrow("Ingredients · 1 portion")}
            {Kati.Screens.Meal.ingredients(meal.ingredients)}
            {Kati.Screens.Meal.muted_eyebrow("Method")}
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
            text={String.upcase(meal.slot)}
            font_family="mono"
            text_size={10.5}
            letter_spacing={0.14}
            text_color={Palette.sub()}
            max_lines={1}
          />
          <Spacer size={7} />
          <Text
            text={meal.title}
            text_size={26}
            font_weight="extrabold"
            letter_spacing={-0.035}
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
          {Kati.UI.symbol("arrow_back_ios_new", size: 17)}
          <Spacer size={6} />
          <Text
            text="Meals"
            text_size={13.5}
            font_weight="semibold"
            letter_spacing={-0.01}
            text_color={:on_surface}
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
              text={String.upcase("Per portion")}
              font_family="mono"
              text_size={10.5}
              letter_spacing={0.16}
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
      letter_spacing={-0.04}
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
        font_family="mono"
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
            text={String.upcase(name)}
            font_family="mono"
            text_size={9}
            letter_spacing={0.1}
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
        text={String.upcase(label)}
        font_family="mono"
        text_size={9}
        letter_spacing={0.1}
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
  def actions do
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
                text="Mark eaten"
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
        {Kati.Screens.Meal.disc("bookmark", :save)}
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
          font_family="mono"
          text_size={11.5}
          text_color={Palette.ink_soft()}
          max_lines={1}
        />
        <Spacer size={13} />
        <Column width={30}>
          <Text
            text={row.calories}
            font_family="mono"
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

  # On cream, like screen 08's note: the design's one warm surface, used here
  # for the part of the card a person reads rather than counts.
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
          line_height={1.65}
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
    [muted_eyebrow("History"), history(rows)]
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
        {Kati.UI.symbol("chevron_right", size: 18, color: Palette.rail_idle())}
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

  def handle_info({:tap, :back}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}

  def handle_info({:tap, :swap}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.MealSwap)}

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

  def handle_info({:tap, :mark_eaten}, socket) do
    meal = socket.assigns.meal

    {:noreply,
     Mob.Socket.assign(socket, :meal, Map.put(meal, :eaten, not Map.get(meal, :eaten, false)))}
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  @doc false
  @spec portion_factor(String.t()) :: float()
  def portion_factor(label) do
    case Float.parse(String.trim_trailing(label, "×")) do
      {n, _} -> n
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

    text <> "×"
  end
end
