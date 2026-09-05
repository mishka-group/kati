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

  So `Kati.Screens.MealLibrary.tile/2` draws the same rectangle either way, and
  the no-photo case fills it with the `restaurant` glyph and the words *Meal
  photo* — which also tells the user the tile is missing something they could
  add.

  ## The field is a field

  The caption's argument is that a photo is recognised faster than a name, and
  it holds for a grid you are scanning. It stops holding at the length this
  screen is built for: past two screenfuls there is nothing to scan, and the
  fastest way to a meal you can already name is to type it. So the drawn field
  is a `<TextField>` rather than a picture of one, and the grid narrows on the
  title as you type — see `search_field/1` and `matches?/2`.

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
    |> Mob.Socket.assign(:query, "")
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
      # The row's own id. A tile is the one control in this app that has to say
      # *which* — six of them are drawn and every one used to push screen 118
      # with nothing, which then re-read the table and edited its first row.
      # `Kati.Meals.SampleLibrary`'s six carry no id and are not given a `nil`
      # one, so `meal[:id]` reads `nil` by absence and the editor falls back to
      # the drawing.
      id: recipe.id,
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
        {Kati.Screens.MealLibrary.search_field(assigns.query)}
        {Kati.Screens.MealLibrary.chips(assigns.filter)}
        {Kati.Screens.MealLibrary.grid(assigns.meals, assigns.filter, assigns.query)}
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

  @doc """
  The search field, which is a field now rather than a picture of one.

  `Kati.ScreenTapSweepTest`'s `@inert_taps` listed this as *"`search` opens no
  keyboard (#45)"*, and that premise is gone: `<TextField>` with `on_change`
  ships on screen 154 (`Kati.Screens.AddByHand.field/3`) and screen 92
  (`Kati.Screens.MyServices.search_field/1`), and the bridge honours it under
  `native/LEDGER.md`'s text-field fence. This screen is the one place in Meals
  where reading beats recognition — a library grown past two screenfuls of tiles
  cannot be scanned, which is board 116's own argument for the grid pointed the
  other way.

  The row keeps its `on_tap`, for `Kati.Screens.MyServices.search_field/1`'s
  reason: it is the drawn hit area, and it is what a tap on the glyph or on the
  padding lands on rather than on the field itself. What it opens is still
  nothing, which is what keeps its `@inert_taps` entry honest — the entry's
  REASON is what is stale, not the entry.

  The copy stays the drawing's and moves from `:text` to `:placeholder`, which
  `Kati.DesignLiterals.content_props/0` already reads, so
  `Kati.ScreenDesignLiteralTest` still finds *Search your meals* in the tree.
  """
  @spec search_field(String.t()) :: map()
  def search_field(query \\ "") do
    assigns = %{query: query, on_change: {self(), :meal_query}}

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
        <TextField
          value={@query}
          placeholder="Search your meals"
          return_key="search"
          weight={1.0}
          accessibility_id="meal_query"
          on_change={@on_change}
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

  @doc """
  The grid, two across, filtered by the chip and by what is typed.

  Indexed **before** either filter, not after: the index a tile carries is its
  position in `assigns.meals`, which is the list `handle_tap/2` reads back. An
  index into the filtered list would name the third *Dinner* while the handler
  looked up the third meal, and the two coincide exactly when the chip is `All`
  and the field is empty — which is what a screenshot shows.

  An empty query is not a filter of nothing, it is no filter: `query == ""`
  short-circuits, which is the branch every sweep renders and the branch board
  116 is drawn in.
  """
  @spec grid([map()], String.t(), String.t()) :: map()
  def grid(meals, filter, query \\ "") do
    rows =
      meals
      |> Enum.with_index()
      |> Enum.filter(fn {meal, _index} -> filter == "All" or meal.slot == filter end)
      |> Enum.filter(fn {meal, _index} -> Kati.Screens.MealLibrary.matches?(meal, query) end)
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

  @doc """
  Whether a meal survives what is typed in the field.

  Containment over the title and nothing else: the tile draws a title, a figure
  and a slot word, and matching on the slot would make typing *dinner* and
  tapping the **Dinner** chip two spellings of one control.

  Through `Kati.Search.normalise/1` rather than `String.downcase/1`, so this
  field folds a query the way the app's own search does — the Persian kaf and
  ya, the ZWNJ, and Persian digits — instead of inventing a second, weaker rule
  for one screen.
  """
  @spec matches?(map(), String.t()) :: boolean()
  def matches?(_meal, ""), do: true

  def matches?(meal, query) when is_binary(query),
    do: String.contains?(Kati.Search.normalise(meal.title), Kati.Search.normalise(query))

  @doc false
  def grid_row(row) do
    tiles =
      row
      |> Enum.map(fn {meal, index} -> Kati.Screens.MealLibrary.tile(meal, index) end)
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
  @spec tile(map(), non_neg_integer()) :: map()
  def tile(meal, index) do
    assigns = %{meal: meal, tap: {self(), Kati.Screens.MealLibrary.tag(index)}}

    ~MOB"""
    <Column weight={1.0} on_tap={@tap}>
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

  @doc """
  A tile's tap tag: `:open_meal_2` for the third meal in `assigns.meals`.

  An **atom**, and an atom built from a position rather than from the recipe's
  id. Both halves are the house rule and both have a reason written down
  elsewhere in this app. `Kati.Screens.ImportSources.tag/1` is the shape: a
  tuple tag renders and fires but emits no `accessibility_id`, so nothing —
  not a device test, not a screen reader — can address the control. And
  `Kati.Screens.Sync.outbox_row/3` is why the payload is the index: a UUID in a
  tag is `String.to_atom/1` over unbounded input, and the atom table is never
  collected.

  The index is enough because the handler reads it back out of the same
  `assigns.meals` this render drew from, so the two cannot disagree about which
  row `2` is.
  """
  @spec tag(non_neg_integer()) :: atom()
  def tag(index) when is_integer(index) and index >= 0,
    do: String.to_atom("open_meal_" <> Integer.to_string(index))

  # `:add` is the one push that is deliberately given no meal: it opens the
  # editor on a new meal, which is the drawing's own fallback.
  @doc false
  def handle_tap(:add, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.MealEdit)}

  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "open_meal_" <> index -> {:noreply, open_meal(socket, index)}
      "filter_" <> label -> {:noreply, Mob.Socket.assign(socket, :filter, label)}
      _other -> {:noreply, socket}
    end
  end

  # The tile's index into the list this render drew, resolved to the row's id
  # and handed to screen 118. Every tile used to push `Kati.Screens.MealEdit`
  # with nothing at all, and that screen answered by re-reading `recipes` and
  # taking the head — tap the third meal, edit the first (#84). A sample tile
  # has no id and pushes `%{}`, which is the editor's drawn fallback.
  defp open_meal(socket, index) do
    meal = Enum.at(socket.assigns.meals, String.to_integer(index))

    Mob.Socket.push_screen(socket, Kati.Screens.MealEdit, Kati.Screens.MealEdit.params_for(meal))
  end

  @doc """
  What was typed in the search field.

  **The catch-all delegates to `super/2`.** `Kati.Screens.Pushed` marks
  `handle_info/2` overridable and defines four clauses on it, one of which
  routes every `{:tap, tag}` to `handle_tap/2` and another of which answers
  `:back` — so an override that replaced all four would take every tap on this
  page with it. `Kati.Screens.MyServices`' own change clause carries the same
  warning, and it is there because that failure has already happened once.

  A keystroke narrows the grid and nothing else: it does not touch `:filter`,
  because the chip and the field are two different questions and a screen that
  cleared one when you used the other would be answering neither.
  """
  def handle_info({:change, :meal_query, typed}, socket) when is_binary(typed),
    do: {:noreply, Mob.Socket.assign(socket, :query, typed)}

  def handle_info(message, socket), do: super(message, socket)
end
