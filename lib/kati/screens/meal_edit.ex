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

  ## The editor edits the meal you tapped, and used not to

  Screen 116 is a grid of six tiles and every one of them pushed here with no
  params at all. This screen then read `recipes` and took the head, for the
  title, for the figures, for the ingredients, for the method and for the one
  thing it writes. Tap the third meal and you edited the first — and because
  every band came off that same wrong row, the page was perfectly consistent
  with itself and simply about the wrong dinner.

  It takes `%{meal_id: id}` now, and the grid's tiles carry a tag apiece so a
  tap can say which. Handed nothing — which is what `Add a meal` means, and
  what the empty-database sweep does — it is the library's first and then
  `Kati.Meals.SampleLibrary`'s drawing, exactly as before. See #84.

  ## The ingredient sheet is handed the same meal

  `Add an ingredient` and every ingredient row's chevron push
  `Kati.Screens.AddIngredient` with this editor's own `meal_id`, through
  `params_for/1` so the key is spelled once. That sheet's Save writes now, and
  a sheet pushed with nothing would have had to find a recipe for itself —
  which is the defect above, one screen down and with a new row rather than an
  edited field at the end of it.

  ## A Save that did not land leaves the screen where it is

  `Save` used to pop the screen whatever the write returned, which on this
  screen is the worst place for that bug to live: with no recipe stored the
  editor draws `SampleLibrary`'s meal anyway, so a slot that saved and a slot
  that did not produced the same pixels on the way out. The screen was
  reporting success by returning to Meals, and returning to Meals was
  unconditional.

  So the failure now stops the pop and prints, in `Palette.red()`, directly
  under the button that caused it. Next to the control rather than in a toast,
  because the toast would have been racing the pop it no longer does, and next
  to the control is where the person is looking. *Under* and not over, because
  the band over the `Save` pill belongs to the floating back pill and anything
  drawn into it is drawn behind it — `chrome/1` has the measurements.
  `Kati.Write` carries the argument in full.

  ## The copy is `Kati.Gettext`'s and the slot is not

  mishka-group/kati#103 folded the Persian mirrors away, so this screen renders
  in both scripts and every sentence on it goes through the catalogue. Two
  things on the page deliberately do not:

    * **The slot a chip stands for.** `@slots` is four VALUES —
      `Kati.Meals.Recipe.slot_name`, the chip's own `selected` comparison, and
      the `slot_Dinner` inside an `accessibility_id` — and `slot_label/1` is
      the only thing that translates. A translated value would have been
      written to the database by `save_slot/2`, which is worse than the dead
      tap the same mistake causes elsewhere in this app.
    * **`Kati.Meals.Aisle.label/1` and `Kati.Meals.SampleLibrary`.** Both draw
      on this page and neither is this file's; an ingredient's meta line is
      half a word this screen owns and half a word that module does.

  ## The multiplier is drawn, and used not to be

  `:portion_up` and `:portion_down` moved an assign nothing rendered, while the
  figure between the two discs came off `meal.portion` — the frozen `1.0×` in
  the shaped map. So the stepper's pixels were correct at rest and the control
  was dead, which is exactly the shape `Kati.Screens.Root.rescue_tap/3` cannot
  see because the tap *is* handled. `figures/3` takes the live float now, and
  `portion_label/1` prints it in the reader's own digits.
  """

  use Kati.Screens.Pushed, back: "Meals"
  use Gettext, backend: Kati.Gettext

  alias Kati.Meals.Recipe
  alias Kati.Meals.SampleLibrary
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList
  alias Kati.Write

  # The four slot VALUES, and deliberately not the four slot LABELS.
  #
  # This list is three things at once: what `Kati.Meals.Recipe.slot_name`
  # stores, what a chip compares itself against to know it is selected, and
  # what `String.to_atom("slot_" <> slot)` puts into an `accessibility_id`. So
  # it stays English in both scripts and `slot_label/1` does the translating —
  # `Kati.Screens.MealsToday.meal_tag/1` carries the long version of the
  # argument, that a drawn word inside an atom which crosses into Kotlin and
  # back is mishka-group/kati#103's recurring defect.
  #
  # Here it would have been worse than a dead tap. `handle_tap/2` reads the
  # word back out of its own tag and `save_slot/2` writes it to the database,
  # so a Persian reader pressing `شام` would have stored `شام` as the recipe's
  # slot — and an English reader opening the same meal afterwards would see
  # four chips and none of them selected.
  @slots ~w(Breakfast Lunch Dinner Snack)

  # `Kati.Screens.Pushed` puts the push's params on `:params`, and this is the
  # screen reading them. The id is kept in its own assign rather than dug back
  # out of `assigns.meal` on every call, because the meal a caller named and the
  # meal that was found are two different facts: a row deleted under you draws
  # the sample and must still not fall through to editing somebody else's.
  def load(socket) do
    id = Map.get(socket.assigns.params || %{}, :meal_id)
    meal = meal(id)

    socket
    |> Mob.Socket.assign(:meal_id, id)
    |> Mob.Socket.assign(:meal, meal)
    |> Mob.Socket.assign(:slot, meal.slot)
    |> Mob.Socket.assign(:portion, 1.0)
    |> Mob.Socket.assign(:save_error, nil)
  end

  @doc """
  The params that name a meal — to this editor, and on to screen 119.

  Here rather than at the grid so the key is spelled once. A shaped row carries
  `:id`; the drawing's six do not, and a meal with no id — or no meal at all,
  which is what `Add a meal` means — yields `%{}`.

  Both doors use it: screen 116 names a meal to this editor from the tile that
  was tapped, and this editor names the same meal to `Kati.Screens.AddIngredient`
  from the id it is holding. One spelling of `:meal_id`, so the two cannot drift
  apart and leave a sheet writing to a meal the page never mentioned.
  """
  @spec params_for(map() | nil) :: map()
  def params_for(%{id: id}) when is_binary(id), do: %{meal_id: id}
  def params_for(_meal), do: %{}

  @doc """
  The meal being edited: the library's first, or the drawing's.

  The no-id answer, and the one the empty-database sweep renders.
  """
  @spec meal() :: map()
  def meal, do: meal(nil)

  @doc """
  The meal this editor was handed, or — given no id — the library's first.

  The whole of #84 on this screen. Screen 116 draws a grid of six tiles and
  pushed here with nothing, so the editor re-read `recipes` and took the head:
  tap the third meal, edit the first. Nothing on screen said which one it had —
  the title, the figures, the ingredients and the method all came off the same
  wrong row, so the page was internally consistent and externally about
  somebody else's dinner.
  """
  @spec meal(String.t() | nil) :: map()
  def meal(id) do
    case recipe(id) do
      nil -> SampleLibrary.meal()
      %Recipe{} = recipe -> shaped(recipe)
    end
  end

  @doc "The drawing's meal, unconditionally."
  @spec drawn_meal() :: map()
  def drawn_meal, do: SampleLibrary.meal()

  # The one read every band on this screen goes through, so no two of them can
  # end up describing different recipes. An id that names no row answers `nil`
  # rather than the library's head — see `Kati.Screens.BookDetail.shelved_book/1`
  # for the argument, which is the same one.
  defp recipe(nil) do
    case Ash.read(Recipe, action: :read) do
      {:ok, [recipe | _rest]} -> recipe
      _other -> nil
    end
  rescue
    _error -> nil
  end

  defp recipe(id) when is_binary(id) do
    case Ash.get(Recipe, id) do
      {:ok, %Recipe{} = recipe} -> recipe
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
      # The tilde is the drawing's mark for *approximate* and is punctuation
      # rather than a word, so it is the same mark in both scripts; the digits
      # beside it are the reader's own, and `figures/3` sets this line in
      # `Kati.Locale.mono_face/1` so the Persian ones have a face that draws
      # them.
      kcal: "#{if approximate?, do: "~", else: ""}#{Kati.Locale.number(recipe.total_kcal)}",
      # The multiplier a meal opens at. The LIVE one is `socket.assigns.portion`
      # and `figures/3` draws that; this is the resting figure the map carries,
      # kept so a shaped meal and `Kati.Meals.SampleLibrary.meal/0` describe the
      # same thing with the same keys.
      portion: Kati.Screens.MealEdit.portion_label(1.0),
      minutes: recipe.minutes && gettext("%{n} min", n: Kati.Locale.number(recipe.minutes)),
      heat:
        recipe.oven_c &&
          pgettext("oven temperature", "%{n}°C", n: Kati.Locale.number(recipe.oven_c)),
      serves: gettext("Serves %{n}", n: Kati.Locale.number(recipe.serves)),
      method: recipe.method
    }
  end

  @doc "The macro rows: the recipe's, or the drawing's six."
  @spec macros() :: [{String.t(), String.t()}]
  def macros, do: macros(nil)

  @doc "The macro rows for one named recipe. Same row, same six figures."
  @spec macros(String.t() | nil) :: [{String.t(), String.t()}]
  def macros(id) do
    case recipe(id) do
      nil ->
        SampleLibrary.macros()

      %Recipe{} = recipe ->
        [
          {gettext("Protein"), grams(recipe.total_protein_mg)},
          {gettext("Carbs"), grams(recipe.total_carbs_mg)},
          {gettext("Fat"), grams(recipe.total_fat_mg)},
          {gettext("Fibre"), grams(recipe.total_fibre_mg)},
          {gettext("Sugar"), grams(recipe.total_sugar_mg)},
          {gettext("Sodium"), grams(recipe.total_sodium_mg)}
        ]
    end
  end

  # An em dash for nothing recorded, never `0 g` — see the moduledoc. The dash
  # is punctuation and is drawn the same in both scripts, so it is not a msgid:
  # a bare `"—"` would be fuzzy-matched by `mix gettext.merge` against any
  # sentence that happens to end in one.
  defp grams(0), do: "—"
  defp grams(mg), do: gettext("%{n} g", n: Kati.Locale.number(round(mg / 1000)))

  @doc "The ingredient rows: the recipe's, or the drawing's four."
  @spec ingredients() :: [map()]
  def ingredients, do: ingredients(nil)

  @doc "The ingredient rows for one named recipe."
  @spec ingredients(String.t() | nil) :: [map()]
  def ingredients(id) do
    case recipe(id) do
      nil ->
        SampleLibrary.ingredients()

      %Recipe{} = recipe ->
        recipe
        |> Kati.Screens.MealLibrary.ingredients_of()
        |> Enum.map(fn ingredient ->
          state = Kati.Screens.MealEdit.ingredient_state(ingredient)

          %{
            name: ingredient.name,
            # `Kati.UI.eyebrow_label/1` rather than `String.upcase/1`: Persian
            # has no case, so upcasing a Persian meta line is a no-op that
            # reads as one — the helper upcases in Latin and leaves the
            # Arabic-script half alone. `Kati.Meals.Aisle.label/1`'s half of
            # this line is still English under `:fa`; that module owns it.
            meta:
              Kati.UI.eyebrow_label(
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

  # Two words apiece, and each is a STATE rather than a sentence — so they take
  # a context. A bare two-word msgid is exactly what `mix gettext.merge` fuzzy-
  # matches against something longer, and `Kati.Screens.AddIngredient` writes a
  # `Free text` of its own for the sheet's preview line.
  @doc false
  def state_label(:known), do: pgettext("ingredient state", "Nutrition known")
  def state_label(:quantity_only), do: pgettext("ingredient state", "Quantity only")
  def state_label(_free), do: pgettext("ingredient state", "Free text")

  @doc ~S"""
  What a row prints on its right: the amount, in the reader's own digits.

  ## Why every unit gets a clause of its own

  This ended in one interpolation — `"#{round(mg / 1000)} #{unit}"` — which is
  a msgid nothing can translate: `gettext/1` needs a literal at the call site,
  and the unit here is an atom read out of the row. Interpolating it instead,
  as `gettext("%{n} %{unit}", …)`, would have localised the number and left the
  word `tbsp` sitting in Latin in the middle of a Persian list.

  `Kati.Meals.RecipeIngredient` constrains `unit` to eight values, so the
  vocabulary is closed and each one can be written out. The four that take an
  English plural take `ngettext/4`; `g`, `ml`, `tsp` and `tbsp` are
  abbreviations and do not inflect in either script.
  """
  @spec amount_line(map()) :: String.t()
  def amount_line(%{amount_mg: 0}), do: pgettext("ingredient amount", "a few")

  def amount_line(%{amount_mg: mg, unit: unit}),
    do: Kati.Screens.MealEdit.unit_amount(unit, round(mg / 1000))

  @doc false
  @spec unit_amount(atom(), integer()) :: String.t()
  def unit_amount(:ml, n), do: gettext("%{n} ml", n: Kati.Locale.number(n))
  def unit_amount(:g, n), do: gettext("%{n} g", n: Kati.Locale.number(n))
  def unit_amount(:tsp, n), do: gettext("%{n} tsp", n: Kati.Locale.number(n))
  def unit_amount(:tbsp, n), do: gettext("%{n} tbsp", n: Kati.Locale.number(n))

  def unit_amount(:piece, n),
    do: ngettext("%{n} piece", "%{n} pieces", n, n: Kati.Locale.number(n))

  def unit_amount(:pinch, n),
    do: ngettext("%{n} pinch", "%{n} pinches", n, n: Kati.Locale.number(n))

  def unit_amount(:pack, n), do: ngettext("%{n} pack", "%{n} packs", n, n: Kati.Locale.number(n))
  def unit_amount(:tub, n), do: ngettext("%{n} tub", "%{n} tubs", n, n: Kati.Locale.number(n))

  # A unit outside the eight `Kati.Meals.RecipeIngredient` allows cannot be
  # stored, so this is unreachable through the store — but a row shaped by hand
  # (a test, a future importer) must print a number rather than raise inside a
  # render, which is the one place in this app a raise costs the whole screen.
  def unit_amount(unit, n), do: "#{Kati.Locale.number(n)} #{unit}"

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
        {Kati.Screens.MealEdit.chrome(assigns.save_error)}
        {Kati.Screens.MealEdit.slots(assigns.slot)}
        {Kati.Screens.MealEdit.title_and_photo(assigns.meal)}
        {UI.eyebrow(gettext("Per portion"))}
        {Kati.Screens.MealEdit.figures(assigns.meal, assigns.meal_id, assigns.portion)}
        {Kati.Screens.MealEdit.approx_note(assigns.meal.approximate?)}
        {UI.eyebrow(Kati.Screens.MealEdit.ingredients_label(assigns.meal_id))}
        {Kati.Screens.MealEdit.ingredient_list(assigns.meal_id)}
        {UI.eyebrow(gettext("Method"))}
        {Kati.Screens.MealEdit.method(assigns.meal)}
        {UI.eyebrow(gettext("This meal is in an active plan"))}
        {Kati.Screens.MealEdit.plan_group()}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The back-pill row with `Save` on the right, under it the line that says a
  save did not land.

  Takes the message rather than reading it, so the one place that decides a
  save failed is the handler that got the tuple — a second reader would be a
  second chance to disagree with it.

  ## The message goes UNDER the Save pill, and that is not a preference

  `Kati.Screens.Pushed.chrome/3` is a `Box` — a z-stack (`MobBridge.kt`'s
  `"box"` branch) — and it paints the floating back pill *over* the content, at
  `padding_top={64}`, `padding_left={21}`, 44 tall. This screen's content
  column opens at exactly the same `padding_top={64}`, `padding_left={21}`, so
  the first thing drawn here shares its pixels with an opaque pill that has a
  shadow and wins.

  That is why the row below starts with `Spacer weight={1.0}`: the left half of
  this band is not empty by accident, it is the back pill's, and the only thing
  in the band is `Save`, hugging the right edge and level with the pill.

  A `fill_width` line of red text placed above that row therefore did two
  things at once — drew the message under the pill, where its first ~90pt read
  `‹ Meals`, and pushed `Save` down out of level with the pill the instant a
  save failed. Below the row the message clears the overlay, still touches the
  control that caused it, and still sits above the slot chips it is about.
  """
  @spec chrome(String.t() | nil) :: map()
  def chrome(save_error) do
    assigns = %{save_error: save_error, save: gettext("Save")}

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
            text={@save}
            text_size={13}
            font_weight="bold"
            text_color={Palette.on_ink()}
            max_lines={1}
          />
        </Row>
      </Row>
      {Kati.Screens.MealEdit.save_error_line(@save_error)}
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  The sentence that says the slot did not save, or nothing.

  Red and not muted: `Palette.red()` is the token for *destructive, stale,
  over*, and a write that did not happen is all three. The same
  `[]`-for-nothing shape `approx_note/1` uses, so the row collapses to no
  height at all rather than reserving a gap for a message that is usually
  absent.

  The 10 leads rather than trails: this hangs below the `Save` pill, so the
  gap it owes is the one between the pill and the sentence. `chrome/1`'s
  existing 16 still separates it from the slot chips.
  """
  @spec save_error_line(String.t() | nil) :: map() | []
  def save_error_line(nil), do: []

  def save_error_line(message) do
    assigns = %{message: message}

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={10} />
      <Text
        text={@message}
        text_size={12.5}
        font_weight="semibold"
        line_height={Kati.Locale.leading(1.55)}
        text_color={Palette.red()}
      />
    </Column>
    """
  end

  @doc """
  The four slot chips.

  The chip's LABEL is translated and its VALUE is not — see `@slots`. `active`
  arrives as `Kati.Meals.Recipe.slot_name`, which is English in every locale,
  and the tag `slot_Dinner` is what `handle_tap/2` reads back and `save_slot/2`
  stores, so both comparisons stay on this side of the catalogue.
  """
  @spec slots(String.t() | nil) :: map()
  def slots(active) do
    chips =
      @slots
      |> Enum.map(fn slot ->
        UI.chip(Kati.Screens.MealEdit.slot_label(slot),
          selected: slot == active,
          on_toggle: String.to_atom("slot_" <> slot)
        )
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

  @doc """
  One slot's word, in the reader's language.

  A clause apiece because a msgid must be a literal at the call site — and
  because the four are exactly `@slots`, which is a closed list this screen
  owns. `Kati.Meals.SamplePlan` and `Kati.Meals.SampleToday` already spell the
  same four, so these reuse their entries rather than opening a second set.

  The fallback answers the word it was given. `Kati.Meals.Recipe.slot_name` is
  a free string on purpose — *somebody who eats second breakfast should be able
  to say so* — so a chip list that grows a fifth slot draws its English word
  rather than raising inside a render.
  """
  @spec slot_label(String.t()) :: String.t()
  def slot_label("Breakfast"), do: gettext("Breakfast")
  def slot_label("Lunch"), do: gettext("Lunch")
  def slot_label("Dinner"), do: gettext("Dinner")
  def slot_label("Snack"), do: gettext("Snack")
  def slot_label(other), do: other

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
        letter_spacing={Kati.Locale.tracking(-0.03)}
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
      {Kati.UI.symbol("add", size: 19, color: Palette.ink_soft())}
      <Spacer size={11} />
      <Text
        text={gettext("Add a meal photo")}
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

  @doc """
  The calorie figure, the portion multiplier, and the six macros.

  ## The multiplier now draws the multiplier

  This took the meal and the id, and printed `meal.portion` — the `1.0×` that
  `shaped/1` and `Kati.Meals.SampleLibrary.meal/0` both freeze into the map.
  `:portion_up` and `:portion_down` have always moved an assign of their own,
  and nothing has ever rendered it, so both discs were dead controls that
  looked alive: the press landed, the state moved, and the figure between them
  did not. Screen 45 is the component this is supposed to be *the same as*, and
  there the stepper moves the number.

  So the live value comes in as its own argument and `portion_label/1` prints
  it. The float stays the state and the label stays a rendering of it — the
  opposite way round from `Kati.Screens.Meal`, which keeps `"1.25×"` in the
  assign and parses it back with `portion_factor/1`; a label is a poor place to
  keep a number, and under `:fa` it would be a Persian-digit label parsed by
  `Float.parse/1`, which answers `:error` on ۱٫۲۵.
  """
  @spec figures(map(), String.t() | nil, float()) :: map()
  def figures(meal, id, portion) do
    rows =
      id
      |> Kati.Screens.MealEdit.macros()
      |> Enum.map(fn {label, value} ->
        SettingsList.row(
          nil,
          SettingsList.body(label, nil),
          SettingsList.trailing(Kati.Screens.MealEdit.value(value))
        )
      end)

    assigns = %{
      meal: meal,
      rows: rows,
      portion: Kati.Screens.MealEdit.portion_label(portion),
      kcal: gettext("kcal")
    }

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {Kati.Screens.MealLibrary.approx_badge(@meal.approximate?)}
        <Text
          text={@meal.kcal}
          font_family={Kati.Locale.mono_face(@meal.kcal)}
          text_size={30}
          font_weight="medium"
          letter_spacing={Kati.Locale.tracking(-0.02)}
          text_color={:on_surface}
          max_lines={1}
        />
        <Spacer size={5} />
        <Text text={@kcal} text_size={14} text_color={Palette.muted()} max_lines={1} />
        <Spacer weight={1.0} />
        {Kati.Screens.MealEdit.portion(@portion)}
      </Row>
      <Spacer size={16} />
      {Kati.UI.SettingsList.card(@rows)}
      <Spacer size={12} />
    </Column>
    """
  end

  # `mono_face/1` and not `mono_face/0`: a macro figure is `18 g` in one script
  # and ۱۸ گرم in the other, and `kati_mono.ttf` carries no Persian glyph, so a
  # Persian figure set in it is handed to Android's own substitute face — it
  # renders, in a typeface that is not Kati's, beside figures that are. Asking
  # the LINE's own script rather than the reader's language is what keeps an
  # all-Latin figure in DM Mono on a Persian page, which is the case this
  # column will meet the moment a macro is recorded and its unit is not.
  @doc false
  def value(text) do
    assigns = %{text: text}

    ~MOB"""
    <Text
      text={@text}
      font_family={Kati.Locale.mono_face(@text)}
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
      <Text
        text={@label}
        font_family={Kati.Locale.mono_face(@label)}
        text_size={14}
        text_color={:on_surface}
        max_lines={1}
      />
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

  @doc """
  The multiplier, as the drawing prints it: one decimal, then `×`.

  `1.0×` and not `1×` — board 118 prints the decimal on a whole portion, and
  the stepper must not be the thing that changes what the screen says at rest.

  The digits are the reader's (`Kati.Locale.number/1` converts the decimal
  SEPARATOR as well, so Persian gets ۱٫۰ with U+066B and not a Latin full
  stop), and `×` is U+00D7 — a mathematical sign rather than a letter, and the
  same sign in both scripts.

      iex> Kati.Screens.MealEdit.portion_label(1.0)
      "1.0×"

      iex> Kati.Locale.as(:fa, fn -> Kati.Screens.MealEdit.portion_label(1.5) end)
      "۱٫۵×"
  """
  @spec portion_label(number()) :: String.t()
  def portion_label(factor) when is_number(factor) do
    # `/ 1` rather than an `is_float` guard: the assign is a float everywhere
    # today, and a whole number arriving from anywhere else has to print rather
    # than raise — this runs inside a render, where a `FunctionClauseError`
    # costs the screen and not the line.
    Kati.Locale.number(:erlang.float_to_binary(factor / 1, decimals: 1)) <> "×"
  end

  @doc "The sentence that says why the figure carries a tilde, or nothing."
  @spec approx_note(boolean()) :: map() | []
  def approx_note(false), do: []

  def approx_note(true) do
    # `Two` is the drawing's count and is frozen into the sentence rather than
    # counted off the recipe — board 118's meal has exactly two ingredients
    # without figures. It stays frozen here on purpose: the board is the
    # specification for this paragraph, and a `%{n} ingredients` that read `2`
    # rather than `Two` would be a different sentence from the one signed off.
    # See the note in the module's own header.
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.note("info", gettext("Two ingredients have no nutrition data, so this total is approximate and says so everywhere it appears. A total built from partial data that pretends to be exact makes every number downstream a lie."))}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc "The ingredients eyebrow, carrying the real count."
  @spec ingredients_label() :: String.t()
  def ingredients_label, do: ingredients_label(nil)

  @doc """
  The ingredients eyebrow for one named recipe.

  One msgid with the count inside it rather than a word and a number glued
  together at the call site: the separator is part of the phrase, and a
  right-to-left page puts the count on the other side of it.
  """
  @spec ingredients_label(String.t() | nil) :: String.t()
  def ingredients_label(id) do
    gettext("Ingredients · %{count}",
      count: Kati.Locale.number(length(Kati.Screens.MealEdit.ingredients(id)))
    )
  end

  @doc "The ingredient rows, plus the row that adds one."
  @spec ingredient_list() :: map()
  def ingredient_list, do: ingredient_list(nil)

  @doc "The ingredient rows for one named recipe, plus the row that adds one."
  @spec ingredient_list(String.t() | nil) :: map()
  def ingredient_list(id) do
    rows =
      id
      |> Kati.Screens.MealEdit.ingredients()
      |> Enum.map(&Kati.Screens.MealEdit.ingredient_row/1)

    rows =
      rows ++
        [
          SettingsList.row(
            SettingsList.icon_tile("add"),
            SettingsList.body(gettext("Add an ingredient"), nil),
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

  @doc """
  One ingredient line.

  `tappable?` is false for screen 119's preview, which draws this same row to
  show what Save will add. A preview is not a control: giving it a tap tag put
  a live `accessibility_id` on a row that answers nothing, which is precisely
  the dead-button shape `Kati.ScreenTapSweepTest` exists to catch — and did.
  """
  @spec ingredient_row(map(), boolean()) :: map()
  def ingredient_row(ingredient, tappable? \\ true) do
    opts =
      if tappable? do
        [on_tap: {self(), Kati.Screens.MealEdit.ingredient_tag(ingredient)}]
      else
        []
      end

    SettingsList.row(
      Kati.Screens.MealEdit.state_glyph(ingredient.state),
      SettingsList.body(ingredient.name, ingredient.meta),
      SettingsList.trailing(Kati.Screens.MealEdit.trailing(ingredient.amount)),
      opts
    )
  end

  @doc """
  This ingredient line's own tap tag.

  Every row carried `:edit_ingredient`, so a meal with four ingredients gave
  four nodes one `accessibility_id` and `onNodeWithTag` threw on the second.
  The rows were unaddressable on a device — which is why #95's ingredient
  journey could not be written as a device test until they were named.

  Naming them does not invent an edit screen. The comment on
  `ingredient_sheet/1` still holds: the design draws none, and all these tags
  open `Add an ingredient`. What changes is only that a test — and TalkBack's
  ordering, and any future per-row action — can now tell the second line from
  the first.

      iex> Kati.Screens.MealEdit.ingredient_tag(%{name: "Olive oil"})
      :ingredient_Olive_oil
  """
  @spec ingredient_tag(map()) :: atom()
  def ingredient_tag(%{name: name}) when is_binary(name) do
    case String.trim(name) do
      "" -> :edit_ingredient
      real -> String.to_atom("ingredient_" <> String.replace(real, " ", "_"))
    end
  end

  def ingredient_tag(_ingredient), do: :edit_ingredient

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

  # `Kati.UI.SettingsList.chevron/0` already points the reading direction —
  # `Kati.Locale.forward_chevron/0` inside it — so a row that opens the
  # ingredient sheet points leftward on a Persian page without this call site
  # having to know.
  @doc false
  def trailing(amount) do
    assigns = %{amount: amount}

    ~MOB"""
    <Row align="center">
      <Text
        text={@amount}
        font_family={Kati.Locale.mono_face(@amount)}
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
        font_family={Kati.Locale.mono_face(@facts)}
        text_size={11}
        letter_spacing={Kati.Locale.tracking(0.1)}
        text_color={Palette.muted()}
        max_lines={1}
      />
      <Spacer size={10} />
      <Text
        text={@method}
        text_size={13.5}
        line_height={Kati.Locale.leading(1.55)}
        text_color={Palette.ink_soft()}
      />
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

  ## `next Monday` names the reader's own first day

  The day is interpolated out of `Kati.Locale.week_start/0` rather than written
  into the sentence, so an English page says *next Monday* — the board's own
  words, character for character — and a Persian one says شنبه. Board 137's
  ruling is that the week's first day follows the language chosen in step one
  and is not a setting of its own; `Kati.Screens.Stats.week_start_on/1` is the
  arithmetic half of the same ruling, and `Kati.Screens.PickSections.follows_note/0`
  interpolates the same helper into the same kind of sentence. A Persian page
  promising a Monday rollover would be promising a day its own plan does not
  turn over on.
  """
  @spec plan_group() :: map()
  def plan_group do
    assigns = %{
      effect_title: gettext("Changes take effect next %{day}", day: Kati.Locale.week_start()),
      effect_sub: gettext("This week’s plan keeps the meal as it was"),
      history_title: gettext("Keep the history"),
      history_sub: gettext("Past days keep the old numbers — nothing is recalculated")
    }

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card([
        Kati.UI.SettingsList.row(
          Kati.UI.SettingsList.icon_tile("event_upcoming"),
          Kati.UI.SettingsList.body(@effect_title, @effect_sub, lines: 2),
          Kati.UI.SettingsList.trailing(Kati.Screens.MealEdit.default_badge())
        ),
        Kati.UI.SettingsList.row(
          Kati.UI.SettingsList.icon_tile("history"),
          Kati.UI.SettingsList.body(@history_title, @history_sub, lines: 2),
          Kati.UI.SettingsList.trailing(Kati.Screens.MealEdit.default_badge())
        )
      ])}
    </Column>
    """
  end

  @doc false
  def default_badge do
    # Lower case, and a badge rather than a sentence — so it takes a context. A
    # one-word msgid is exactly what `mix gettext.merge` fuzzy-matches against
    # something longer, and this `default` means *the behaviour you get without
    # choosing anything*, which is not what the word means on a settings row
    # that has a chosen value and a fallback.
    assigns = %{label: pgettext("plan row badge", "default")}

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
        text={@label}
        font_family={Kati.Locale.mono_face(@label)}
        text_size={9.5}
        letter_spacing={Kati.Locale.tracking(0.08)}
        text_color={Kati.Theme.Palette.sub()}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc false
  def handle_tap(:add_ingredient, socket), do: {:noreply, ingredient_sheet(socket)}

  def handle_tap(:edit_ingredient, socket), do: {:noreply, ingredient_sheet(socket)}

  # Clamped at both ends now that `figures/3` actually draws the figure. The
  # floor was already here; the ceiling was not, so a finger resting on the
  # `add` disc used to walk an assign nobody could see up past any number a
  # portion means. Screen 45 clamps the same stepper into `[0.5, 4.0]` through
  # `MishkaNumberField.step/3`; this one steps by halves rather than quarters,
  # which is the drawing's difference, so it keeps its own arithmetic and
  # borrows the bounds.
  def handle_tap(:portion_up, socket),
    do: {:noreply, Mob.Socket.assign(socket, :portion, min(socket.assigns.portion + 0.5, 4.0))}

  def handle_tap(:portion_down, socket),
    do: {:noreply, Mob.Socket.assign(socket, :portion, max(socket.assigns.portion - 0.5, 0.5))}

  def handle_tap(:save, socket) do
    case save_slot(socket.assigns.slot, socket.assigns.meal_id) do
      {:ok, _recipe} ->
        {:noreply,
         socket
         |> Mob.Socket.assign(:save_error, nil)
         |> Kati.Screens.Resume.pop()}

      {:error, _reason} = error ->
        {:noreply, Mob.Socket.assign(socket, :save_error, Write.message(error))}
    end
  end

  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "slot_" <> slot ->
        {:noreply, Mob.Socket.assign(socket, :slot, slot)}

      # Every ingredient line, by its own name — see `ingredient_tag/1`. They
      # open the sheet `:edit_ingredient` opened, because that is still the only
      # screen the design draws for an ingredient.
      "ingredient_" <> _name ->
        {:noreply, ingredient_sheet(socket)}

      _other ->
        {:noreply, socket}
    end
  end

  # Screen 119, carrying the meal it will add an ingredient to.
  #
  # The push used to take no params at all, which is the same defect #84 fixed
  # one screen up: the sheet's Save now writes, and a sheet that had to find a
  # recipe for itself would file the line against the head of a re-query rather
  # than against the meal whose `Add an ingredient` row was tapped.
  # `params_for/1` builds it, so the key is spelled in one place for both doors
  # into this screen — the grid's push into the editor and the editor's push
  # into the sheet.
  #
  # BOTH tags open the same sheet, and `:edit_ingredient` is the honest half of
  # that: the design draws no edit-an-ingredient screen, and every ingredient
  # row carries one shared `:edit_ingredient` tag, so nothing here could say
  # WHICH line was tapped even if there were a screen to open with it. The
  # chevron opens `Add an ingredient`, whose header says exactly that and whose
  # preview shows the row it will add.
  defp ingredient_sheet(socket) do
    Mob.Socket.push_screen(
      socket,
      Kati.Screens.AddIngredient,
      params_for(%{id: socket.assigns.meal_id})
    )
  end

  @doc """
  Write the slot back to the recipe.

  The only thing this editor commits, and it is deliberate: the title, the
  method and the ingredients are all fields Mob cannot yet take typed input for
  (#45), so writing them would mean writing values nobody could have changed.
  The slot chips are real controls and so the slot is a real write.

  Hands back `Ash.update/2`'s own tuple, where this used to end `:ok` and
  `rescue` to `:ok`. Both halves of that were wrong and only one was the
  rescue: `Ash.update/2` does not raise on a rejected changeset, so the rescue
  caught nothing worth catching, and the trailing `:ok` had already thrown the
  answer away a line above it.

  No recipe stored is a failure too, not a quiet no-op. `Save` on an editor
  showing `SampleLibrary`'s meal has nothing to write to, and the person needs
  telling — a button that does nothing and says it worked is the same lie this
  whole change is about.

  ## Which recipe, and why the id is a default argument

  The one the editor was handed. An editor that drew the third meal and wrote
  the slot onto the first would move a chip on a page nobody has open, and the
  page in front of the person would redraw showing a change it did not make.

  `nil` — the library's first — stays the answer for `Add a meal`, which names
  no row on purpose. One clause and not two, so the whole write, its
  `Kati.Write.note/2` included, reads as one thing.
  """
  @spec save_slot(String.t() | nil, String.t() | nil) :: {:ok, Recipe.t()} | {:error, term()}
  def save_slot(slot, id \\ nil) do
    result =
      case recipe(id) do
        %Recipe{} = recipe -> Ash.update(recipe, %{slot_name: slot})
        nil -> {:error, :nothing_to_save}
      end

    Write.note(result, "meal slot")
  end
end
