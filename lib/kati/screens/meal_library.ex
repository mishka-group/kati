defmodule Kati.Screens.MealLibrary do
  @moduledoc """
  Screen 116 — Meal library, pushed under Meals.

  The missing input to the eleven meal screens. Everything from screen 43 down
  assumed a library of meals existed; this is it.

  ## A grid, not a list

  The design's caption: *a meal is recognised by its photo faster than by its
  name, and the no-photo tile is deliberately the same size so the grid never
  goes ragged.* That second clause is the load-bearing one — the obvious
  treatment for a meal without a picture is a shorter row, and a grid with
  shorter tiles in it stops being scannable, which was the whole reason for a
  grid.

  So `Kati.Screens.MealLibrary.tile/1` draws the same rectangle either way, and
  the no-photo case fills it with the `restaurant` glyph and the words *Meal
  photo* — which also tells the user the tile is missing something they could
  add.

  ## `APPROX` travels

  A meal whose total is built from partial ingredient data is marked here, on
  screen 118, and anywhere else the figure appears. Screen 118's own note gives
  the reason: *a total built from partial data that pretends to be exact makes
  every number downstream a lie.*

  ## Create is a header disc

  Matching screens 104 and 109. The FAB slot belongs to global quick-add, and
  putting a second floating button in a pushed screen would make two controls
  compete for the same corner.
  """

  use Kati.Screens.Pushed, back: "Meals"

  require Ash.Query

  alias Kati.Meals.Recipe
  alias Kati.Meals.SampleLibrary
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  def load(socket) do
    socket
    |> Mob.Socket.assign(:meals, meals())
    |> Mob.Socket.assign(:filter, "All")
  end

  @doc "The library: what is stored, or the drawing's six."
  @spec meals() :: [map()]
  def meals do
    case stored() do
      [] -> SampleLibrary.meals()
      recipes -> Enum.map(recipes, &shaped/1)
    end
  end

  @doc "The drawing's six, unconditionally."
  @spec drawn_meals() :: [map()]
  def drawn_meals, do: SampleLibrary.meals()

  defp stored do
    Recipe
    |> Ash.Query.sort(title: :asc)
    |> Ash.read()
    |> case do
      {:ok, recipes} -> recipes
      _other -> []
    end
  rescue
    _error -> []
  end

  @doc """
  One recipe as the grid wants it. Pure, so `approximate?/1` can be tested.
  """
  @spec shaped(Recipe.t()) :: map()
  def shaped(%Recipe{} = recipe) do
    approximate? = Kati.Screens.MealLibrary.approximate?(recipe)

    %{
      title: recipe.title,
      kcal: "#{if approximate?, do: "~", else: ""}#{recipe.total_kcal} kcal",
      slot: recipe.slot_name,
      seed: recipe.photo_seed,
      approximate?: approximate?
    }
  end

  @doc """
  Whether a recipe's total is built from partial ingredient data.

  True when the recipe has ingredients and any of them contributes no calories
  while carrying an amount — which is what *quantity only* and *free text* mean
  in `Kati.Meals.RecipeIngredient` terms. A recipe with no ingredients at all is
  not approximate; it is empty, and its total of zero is exactly right.
  """
  @spec approximate?(Recipe.t()) :: boolean()
  def approximate?(%Recipe{} = recipe) do
    case ingredients_of(recipe) do
      [] -> false
      ingredients -> Enum.any?(ingredients, &(&1.kcal == 0 and &1.amount_mg > 0))
    end
  end

  @doc false
  def ingredients_of(%Recipe{id: id}) do
    Kati.Meals.RecipeIngredient
    |> Ash.Query.filter(recipe_id == ^id)
    |> Ash.Query.sort(position: :asc)
    |> Ash.read()
    |> case do
      {:ok, ingredients} -> ingredients
      _other -> []
    end
  rescue
    _error -> []
  end

  @doc false
  def content(assigns) do
    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {Kati.Screens.Goals.chrome()}
        {SettingsList.title("Meal library", Kati.Screens.MealLibrary.subtitle(assigns.meals))}
        {Kati.Screens.MealLibrary.search_field()}
        {Kati.Screens.MealLibrary.chips(assigns.filter)}
        {Kati.Screens.MealLibrary.grid(assigns.meals, assigns.filter)}
        {Kati.Screens.MealLibrary.notes()}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The header's mono subtitle: how many meals, and how many have no photo.

  The second figure is not decoration — it is the number of tiles the grid is
  drawing as glyphs, and it is what the *Add a meal photo* affordance on screen
  118 exists to reduce.
  """
  @spec subtitle([map()]) :: String.t()
  def subtitle(meals) do
    case stored() do
      [] ->
        SampleLibrary.subtitle()

      _stored ->
        without = Enum.count(meals, &is_nil(&1.seed))

        String.upcase(
          "#{length(meals)} #{if length(meals) == 1, do: "meal", else: "meals"} · " <>
            "#{without} without a photo"
        )
    end
  end

  @doc false
  def search_field do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        height={48}
        corner_radius={24}
        background={Palette.card()}
        shadow={Kati.Theme.shadow_search()}
        padding_left={17}
        padding_right={17}
        align="center"
        on_tap={{self(), :search}}
      >
        {UI.symbol("search", size: 19, color: Palette.tertiary())}
        <Spacer size={11} />
        <Text
          text="Search your meals"
          text_size={14}
          text_color={Palette.tertiary()}
          weight={1.0}
          max_lines={1}
        />
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc "The filter chips, each with its count."
  @spec chips(String.t()) :: map()
  def chips(active) do
    chips =
      Kati.Screens.MealLibrary.chip_counts()
      |> Enum.map(fn {label, count} ->
        UI.chip(label,
          selected: label == active,
          count: count,
          on_toggle: String.to_atom("filter_" <> label)
        )
      end)
      |> Enum.intersperse(~MOB"<Spacer size={7} />")

    ~MOB"""
    <Column fill_width={true}>
      <Scroll axis="horizontal">
        <Row>
          {chips}
        </Row>
      </Scroll>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc """
  The chip counts: the library's own, or the drawing's.

  Counted over the whole library rather than over the filtered grid, which is
  what a filter count means — the number of things the chip would show you, not
  the number it is showing.
  """
  @spec chip_counts() :: [{String.t(), String.t()}]
  def chip_counts do
    case stored() do
      [] ->
        SampleLibrary.chips()

      _stored ->
        meals = Kati.Screens.MealLibrary.meals()

        [{"All", Integer.to_string(length(meals))}] ++
          for slot <- ~w(Breakfast Lunch Dinner Snack) do
            {slot, Integer.to_string(Enum.count(meals, &(&1.slot == slot)))}
          end
    end
  end

  @doc "The grid, two across, filtered by the chip."
  @spec grid([map()], String.t()) :: map()
  def grid(meals, filter) do
    rows =
      meals
      |> Enum.filter(&(filter == "All" or &1.slot == filter))
      |> Enum.chunk_every(2)
      |> Enum.map(&Kati.Screens.MealLibrary.grid_row/1)
      |> Enum.intersperse(~MOB"<Spacer size={12} />")

    ~MOB"""
    <Column fill_width={true}>
      {rows}
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def grid_row(row) do
    tiles =
      row
      |> Enum.map(&Kati.Screens.MealLibrary.tile/1)
      |> Enum.intersperse(~MOB"<Spacer size={12} />")

    # A single-tile row still needs the second half of its width taken, or one
    # meal on the last row stretches to the full frame.
    filler =
      if length(row) == 1,
        do: [~MOB"<Spacer size={12} />", ~MOB"<Column weight={1.0} />"],
        else: []

    ~MOB"""
    <Row fill_width={true} align="top">
      {tiles}
      {filler}
    </Row>
    """
  end

  @doc """
  One meal tile, the same size whether it has a photo or not.

  See the moduledoc: the equal size is the grid's whole argument, and the
  glyph-and-label treatment is what makes the missing photo look like a gap
  worth filling rather than a broken image.
  """
  @spec tile(map()) :: map()
  def tile(meal) do
    assigns = %{meal: meal}

    ~MOB"""
    <Column weight={1.0} on_tap={{self(), :open_meal}}>
      {Kati.Screens.MealLibrary.photo(@meal)}
      <Spacer size={9} />
      <Text
        text={@meal.title}
        text_size={12.5}
        font_weight="bold"
        text_color={:on_surface}
        max_lines={2}
      />
      <Spacer size={4} />
      <Row fill_width={true} align="center">
        <Text
          text={@meal.kcal}
          font_family="mono"
          text_size={10.5}
          text_color={Palette.muted()}
          max_lines={1}
        />
        {Kati.Screens.MealLibrary.approx_badge(@meal.approximate?)}
        <Spacer weight={1.0} />
        <Text
          text={@meal.slot || ""}
          text_size={10.5}
          text_color={Palette.tertiary()}
          max_lines={1}
        />
      </Row>
    </Column>
    """
  end

  @doc false
  def photo(%{seed: nil}) do
    ~MOB"""
    <Column
      fill_width={true}
      height={112}
      corner_radius={14}
      background={Palette.placeholder()}
      align="center"
    >
      <Spacer weight={1.0} />
      {Kati.UI.symbol("restaurant", size: 22, color: Palette.tertiary())}
      <Spacer size={6} />
      <Text
        text="Meal photo"
        font_family="mono"
        text_size={9.5}
        letter_spacing={0.1}
        text_align="center"
        text_color={Palette.tertiary()}
      />
      <Spacer weight={1.0} />
    </Column>
    """
  end

  def photo(meal) do
    case Kati.Design.Images.poster(meal.seed) do
      nil ->
        Kati.Screens.MealLibrary.photo(%{meal | seed: nil})

      src ->
        ~MOB"""
        <Image src={src} fill_width={true} height={112} corner_radius={14} content_mode="fill" />
        """
    end
  end

  @doc "The `APPROX` badge, or nothing."
  @spec approx_badge(boolean()) :: map() | []
  def approx_badge(false), do: []

  def approx_badge(true) do
    ~MOB"""
    <Row align="center">
      <Spacer size={6} />
      {Kati.UI.symbol("help", size: 13, color: Kati.Theme.Palette.gold_icon())}
      <Spacer size={3} />
      <Text
        text="APPROX"
        font_family="mono"
        text_size={8.5}
        letter_spacing={0.1}
        text_color={Kati.Theme.Palette.gold_text()}
      />
    </Row>
    """
  end

  @doc "The two sentences the grid needs to explain itself."
  @spec notes() :: map()
  def notes do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.note("info", "A grid, not a list — a meal is recognised by its photo faster than by its name, and the no-photo tile is deliberately the same size so the grid never goes ragged. APPROX marks a total built from partial ingredient data.")}
    </Column>
    """
  end

  @doc false
  def handle_tap(:open_meal, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.MealEdit)}

  def handle_tap(:add, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.MealEdit)}

  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "filter_" <> label -> {:noreply, Mob.Socket.assign(socket, :filter, label)}
      _other -> {:noreply, socket}
    end
  end
end
