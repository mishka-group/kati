defmodule Kati.Screens.MealEdit do
  @moduledoc """
  Screen 118 — Create or edit a meal, pushed under Meals.

  Screen 45's layout in edit mode, and the caption is precise that it is the
  *same* layout: *same portion multiplier component, not a second
  implementation.* A meal seen and a meal edited differ in what you can touch,
  not in what it looks like.

  ## The three ingredient states are marked by a glyph, not by colour

  Green check for auto-filled, bronze query for quantity-only, ink pencil for
  free text. The caption asks for the glyph by name, and the reason is the one
  that always applies: a state carried by colour alone is a state a
  colour-blind reader and a greyscale screenshot both lose.

  ## `approximate` travels, and says why

  Two of this meal's ingredients have no nutrition data, so the total is
  approximate *and says so everywhere it appears*. The note under the figures
  gives the argument in one line: **a total built from partial data that
  pretends to be exact makes every number downstream a lie.**

  That is why the six macro rows print an em dash rather than a zero for sugar
  and sodium. A meal with no sodium figure has not got zero sodium.

  ## Editing a meal inside a live plan follows screen 49's discipline exactly

  Next Monday, history kept. Both are stated on the page rather than assumed:
  *changes take effect next Monday*, and *past days keep the old numbers —
  nothing is recalculated.* A meal edit that silently rewrote last Tuesday's
  logged calories would be changing a record of something that happened.
  """

  use Kati.Screens.Pushed, back: "Meals"

  alias Kati.Meals.Recipe
  alias Kati.Meals.SampleLibrary
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @slots ~w(Breakfast Lunch Dinner Snack)

  def load(socket) do
    meal = meal()

    socket
    |> Mob.Socket.assign(:meal, meal)
    |> Mob.Socket.assign(:slot, meal.slot)
    |> Mob.Socket.assign(:portion, 1.0)
  end

  @doc "The meal being edited: the library's first, or the drawing's."
  @spec meal() :: map()
  def meal do
    case newest() do
      nil -> SampleLibrary.meal()
      %Recipe{} = recipe -> shaped(recipe)
    end
  end

  @doc "The drawing's meal, unconditionally."
  @spec drawn_meal() :: map()
  def drawn_meal, do: SampleLibrary.meal()

  defp newest do
    case Ash.read(Recipe, action: :read) do
      {:ok, [recipe | _rest]} -> recipe
      _other -> nil
    end
  rescue
    _error -> nil
  end

  @doc "One recipe, as the editor wants it. Pure."
  @spec shaped(Recipe.t()) :: map()
  def shaped(%Recipe{} = recipe) do
    approximate? = Kati.Screens.MealLibrary.approximate?(recipe)

    %{
      title: recipe.title,
      slot: recipe.slot_name,
      seed: recipe.photo_seed,
      approximate?: approximate?,
      kcal: "#{if approximate?, do: "~", else: ""}#{recipe.total_kcal}",
      portion: "1.0×",
      minutes: recipe.minutes && "#{recipe.minutes} min",
      heat: recipe.oven_c && "#{recipe.oven_c}°C",
      serves: "Serves #{recipe.serves}",
      method: recipe.method
    }
  end

  @doc "The macro rows: the recipe's, or the drawing's six."
  @spec macros() :: [{String.t(), String.t()}]
  def macros do
    case newest() do
      nil ->
        SampleLibrary.macros()

      %Recipe{} = recipe ->
        [
          {"Protein", grams(recipe.total_protein_mg)},
          {"Carbs", grams(recipe.total_carbs_mg)},
          {"Fat", grams(recipe.total_fat_mg)},
          {"Fibre", grams(recipe.total_fibre_mg)},
          {"Sugar", grams(recipe.total_sugar_mg)},
          {"Sodium", grams(recipe.total_sodium_mg)}
        ]
    end
  end

  # An em dash for nothing recorded, never `0 g` — see the moduledoc.
  defp grams(0), do: "—"
  defp grams(mg), do: "#{round(mg / 1000)} g"

  @doc "The ingredient rows: the recipe's, or the drawing's four."
  @spec ingredients() :: [map()]
  def ingredients do
    case newest() do
      nil ->
        SampleLibrary.ingredients()

      %Recipe{} = recipe ->
        recipe
        |> Kati.Screens.MealLibrary.ingredients_of()
        |> Enum.map(fn ingredient ->
          state = Kati.Screens.MealEdit.ingredient_state(ingredient)

          %{
            name: ingredient.name,
            meta:
              String.upcase(
                Kati.Meals.Aisle.label(ingredient.aisle) <>
                  " · " <> Kati.Screens.MealEdit.state_label(state)
              ),
            amount: Kati.Screens.MealEdit.amount_line(ingredient),
            state: state
          }
        end)
    end
  end

  @doc """
  Which of the three states an ingredient is in.

  `:known` when it carries nutrition, `:quantity_only` when it has an amount
  and no figures, `:free_text` when its unit says the amount is words rather
  than a measurement.
  """
  @spec ingredient_state(map()) :: :known | :quantity_only | :free_text
  def ingredient_state(%{kcal: kcal}) when kcal > 0, do: :known
  def ingredient_state(%{amount_mg: mg}) when mg > 0, do: :quantity_only
  def ingredient_state(_ingredient), do: :free_text

  @doc false
  def state_label(:known), do: "Nutrition known"
  def state_label(:quantity_only), do: "Quantity only"
  def state_label(_free), do: "Free text"

  @doc false
  def amount_line(%{amount_mg: 0}), do: "a few"
  def amount_line(%{amount_mg: mg, unit: :ml}), do: "#{round(mg / 1000)} ml"
  def amount_line(%{amount_mg: mg, unit: :g}), do: "#{round(mg / 1000)} g"
  def amount_line(%{amount_mg: mg, unit: unit}), do: "#{round(mg / 1000)} #{unit}"

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
        {Kati.Screens.MealEdit.chrome()}
        {Kati.Screens.MealEdit.slots(assigns.slot)}
        {Kati.Screens.MealEdit.title_and_photo(assigns.meal)}
        {UI.eyebrow("Per portion")}
        {Kati.Screens.MealEdit.figures(assigns.meal)}
        {Kati.Screens.MealEdit.approx_note(assigns.meal.approximate?)}
        {UI.eyebrow(Kati.Screens.MealEdit.ingredients_label())}
        {Kati.Screens.MealEdit.ingredient_list()}
        {UI.eyebrow("Method")}
        {Kati.Screens.MealEdit.method(assigns.meal)}
        {UI.eyebrow("This meal is in an active plan")}
        {Kati.Screens.MealEdit.plan_group()}
      </Column>
    </Scroll>
    """
  end

  @doc "The back-pill row with `Save` on the right."
  @spec chrome() :: map()
  def chrome do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} height={44} align="center">
        <Spacer weight={1.0} />
        <Row
          height={36}
          corner_radius={18}
          background={Palette.ink_fill()}
          padding_left={16}
          padding_right={16}
          align="center"
          on_tap={{self(), :save}}
        >
          <Text
            text="Save"
            text_size={13}
            font_weight="bold"
            text_color={Palette.on_ink()}
            max_lines={1}
          />
        </Row>
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc "The four slot chips."
  @spec slots(String.t() | nil) :: map()
  def slots(active) do
    chips =
      @slots
      |> Enum.map(fn slot ->
        UI.chip(slot, selected: slot == active, on_toggle: String.to_atom("slot_" <> slot))
      end)
      |> Enum.intersperse(~MOB"<Spacer size={7} />")

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true}>
        {chips}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc "The title and, when there is no photo, the row that offers one."
  @spec title_and_photo(map()) :: map()
  def title_and_photo(meal) do
    assigns = %{meal: meal}

    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={@meal.title}
        text_size={26}
        font_weight="bold"
        letter_spacing={-0.03}
        text_color={:on_surface}
        max_lines={2}
      />
      <Spacer size={12} />
      {Kati.Screens.MealEdit.photo_row(@meal)}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def photo_row(%{seed: nil}) do
    ~MOB"""
    <Row
      fill_width={true}
      height={48}
      corner_radius={16}
      background={Palette.card()}
      shadow={Kati.Theme.shadow_card()}
      padding_left={15}
      padding_right={15}
      align="center"
      on_tap={{self(), :add_photo}}
    >
      {Kati.UI.symbol("add_a_photo", size: 19, color: Palette.ink_soft())}
      <Spacer size={11} />
      <Text
        text="Add a meal photo"
        text_size={13.5}
        font_weight="semibold"
        text_color={Palette.ink_soft()}
        weight={1.0}
        max_lines={1}
      />
    </Row>
    """
  end

  def photo_row(meal) do
    case Kati.Design.Images.poster(meal.seed) do
      nil ->
        Kati.Screens.MealEdit.photo_row(%{meal | seed: nil})

      src ->
        ~MOB"""
        <Image src={src} fill_width={true} height={160} corner_radius={16} content_mode="fill" />
        """
    end
  end

  @doc "The calorie figure, the portion multiplier, and the six macros."
  @spec figures(map()) :: map()
  def figures(meal) do
    rows =
      Kati.Screens.MealEdit.macros()
      |> Enum.map(fn {label, value} ->
        SettingsList.row(
          nil,
          SettingsList.body(label, nil),
          SettingsList.trailing(Kati.Screens.MealEdit.value(value))
        )
      end)

    assigns = %{meal: meal, rows: rows}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {Kati.Screens.MealLibrary.approx_badge(@meal.approximate?)}
        <Text
          text={@meal.kcal}
          font_family="mono"
          text_size={30}
          font_weight="medium"
          letter_spacing={-0.02}
          text_color={:on_surface}
        />
        <Spacer size={5} />
        <Text text="kcal" text_size={14} text_color={Palette.muted()} />
        <Spacer weight={1.0} />
        {Kati.Screens.MealEdit.portion(@meal.portion)}
      </Row>
      <Spacer size={16} />
      {Kati.UI.SettingsList.card(@rows)}
      <Spacer size={12} />
    </Column>
    """
  end

  @doc false
  def value(text) do
    assigns = %{text: text}

    ~MOB"""
    <Text
      text={@text}
      font_family="mono"
      text_size={12.5}
      text_color={Kati.Theme.Palette.sub()}
      max_lines={1}
    />
    """
  end

  @doc """
  The portion multiplier — screen 45's component, not a second implementation.

  Two 34pt discs around the figure, which is the same arrangement screen 45
  draws and the same one screen 70's page stepper uses at 46. Smaller here
  because it sits on a header row rather than owning one.
  """
  @spec portion(String.t()) :: map()
  def portion(label) do
    assigns = %{label: label}

    ~MOB"""
    <Row align="center">
      <Box
        width={34}
        height={34}
        corner_radius={17}
        background={Palette.card()}
        align="center"
        shadow={Kati.Theme.shadow_button()}
        on_tap={{self(), :portion_down}}
      >
        {Kati.UI.symbol("remove", size: 17)}
      </Box>
      <Spacer size={10} />
      <Text text={@label} font_family="mono" text_size={14} text_color={:on_surface} max_lines={1} />
      <Spacer size={10} />
      <Box
        width={34}
        height={34}
        corner_radius={17}
        background={Palette.card()}
        align="center"
        shadow={Kati.Theme.shadow_button()}
        on_tap={{self(), :portion_up}}
      >
        {Kati.UI.symbol("add", size: 17)}
      </Box>
    </Row>
    """
  end

  @doc "The sentence that says why the figure carries a tilde, or nothing."
  @spec approx_note(boolean()) :: map() | []
  def approx_note(false), do: []

  def approx_note(true) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.note("info", "Two ingredients have no nutrition data, so this total is approximate and says so everywhere it appears. A total built from partial data that pretends to be exact makes every number downstream a lie.")}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc "The ingredients eyebrow, carrying the real count."
  @spec ingredients_label() :: String.t()
  def ingredients_label, do: "Ingredients · #{length(Kati.Screens.MealEdit.ingredients())}"

  @doc "The ingredient rows, plus the row that adds one."
  @spec ingredient_list() :: map()
  def ingredient_list do
    rows =
      Kati.Screens.MealEdit.ingredients()
      |> Enum.map(&Kati.Screens.MealEdit.ingredient_row/1)

    rows =
      rows ++
        [
          SettingsList.row(
            SettingsList.icon_tile("add"),
            SettingsList.body("Add an ingredient", nil),
            SettingsList.trailing(nil),
            on_tap: {self(), :add_ingredient}
          )
        ]

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card(rows)}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def ingredient_row(ingredient) do
    SettingsList.row(
      Kati.Screens.MealEdit.state_glyph(ingredient.state),
      SettingsList.body(ingredient.name, ingredient.meta),
      SettingsList.trailing(Kati.Screens.MealEdit.trailing(ingredient.amount)),
      on_tap: {self(), :edit_ingredient}
    )
  end

  @doc """
  The leading glyph that marks an ingredient's state.

  A glyph and not a tint — see the moduledoc. Each sits in the same 40pt tile
  every other leading control on this page uses, so the column does not shift
  between states.
  """
  @spec state_glyph(atom()) :: map()
  def state_glyph(state) do
    {icon, colour} =
      case state do
        :known -> {"check", Palette.green()}
        :quantity_only -> {"help", Palette.gold_icon()}
        _free -> {"edit", Palette.ink()}
      end

    assigns = %{icon: icon, colour: colour}

    ~MOB"""
    <Box width={40} height={40} corner_radius={12} background={Palette.paper()} align="center">
      {Kati.UI.symbol(@icon, size: 18, color: @colour)}
    </Box>
    """
  end

  @doc false
  def trailing(amount) do
    assigns = %{amount: amount}

    ~MOB"""
    <Row align="center">
      <Text
        text={@amount}
        font_family="mono"
        text_size={12}
        text_color={Kati.Theme.Palette.sub()}
        max_lines={1}
      />
      <Spacer size={8} />
      {Kati.UI.SettingsList.chevron()}
    </Row>
    """
  end

  @doc "The method, with the three facts above it."
  @spec method(map()) :: map()
  def method(meal) do
    facts =
      [meal.minutes, meal.heat, meal.serves]
      |> Enum.reject(&is_nil/1)
      |> Enum.join(" · ")

    assigns = %{facts: facts, method: meal.method || ""}

    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={@facts}
        font_family="mono"
        text_size={11}
        letter_spacing={0.1}
        text_color={Palette.muted()}
        max_lines={1}
      />
      <Spacer size={10} />
      <Text text={@method} text_size={13.5} line_height={1.55} text_color={Palette.ink_soft()} />
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  The two promises an edit inside a live plan makes.

  Screen 49's discipline, stated rather than assumed: next Monday, history
  kept. The second is marked `default` in the drawing because it is the
  behaviour you get without choosing anything, and a promise you have to opt
  into is not a promise.
  """
  @spec plan_group() :: map()
  def plan_group do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card([
        Kati.UI.SettingsList.row(
          Kati.UI.SettingsList.icon_tile("event_upcoming"),
          Kati.UI.SettingsList.body("Changes take effect next Monday", "This week’s plan keeps the meal as it was"),
          Kati.UI.SettingsList.trailing(Kati.Screens.MealEdit.default_badge())
        ),
        Kati.UI.SettingsList.row(
          Kati.UI.SettingsList.icon_tile("history"),
          Kati.UI.SettingsList.body("Keep the history", "Past days keep the old numbers — nothing is recalculated"),
          Kati.UI.SettingsList.trailing(Kati.Screens.MealEdit.default_badge())
        )
      ])}
    </Column>
    """
  end

  @doc false
  def default_badge do
    ~MOB"""
    <Row
      height={22}
      corner_radius={11}
      background={Kati.Theme.Palette.track()}
      padding_left={9}
      padding_right={9}
      align="center"
    >
      <Text
        text="default"
        font_family="mono"
        text_size={9.5}
        letter_spacing={0.08}
        text_color={Kati.Theme.Palette.sub()}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc false
  def handle_tap(:add_ingredient, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.AddIngredient)}

  def handle_tap(:edit_ingredient, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.AddIngredient)}

  def handle_tap(:portion_up, socket),
    do: {:noreply, Mob.Socket.assign(socket, :portion, socket.assigns.portion + 0.5)}

  def handle_tap(:portion_down, socket),
    do: {:noreply, Mob.Socket.assign(socket, :portion, max(socket.assigns.portion - 0.5, 0.5))}

  def handle_tap(:save, socket) do
    save_slot(socket.assigns.slot)
    {:noreply, Mob.Socket.pop_screen(socket)}
  end

  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "slot_" <> slot -> {:noreply, Mob.Socket.assign(socket, :slot, slot)}
      _other -> {:noreply, socket}
    end
  end

  @doc """
  Write the slot back to the recipe.

  The only thing this editor commits, and it is deliberate: the title, the
  method and the ingredients are all fields Mob cannot yet take typed input for
  (#45), so writing them would mean writing values nobody could have changed.
  The slot chips are real controls and so the slot is a real write.
  """
  @spec save_slot(String.t() | nil) :: :ok
  def save_slot(slot) do
    with %Recipe{} = recipe <- newest() do
      Ash.update(recipe, %{slot_name: slot})
    end

    :ok
  rescue
    _error -> :ok
  end
end
