defmodule Kati.Screens.AddIngredient do
  @moduledoc """
  Screen 119 — Add an ingredient, a sheet over the meal editor.

  ## The manual path is the whole path

  Name, quantity, unit, aisle — all provider-free. Scan and search are drawn
  and carry the same `NOT IN V1` badge the retired Health tiles use, so
  *designed, not built* means one thing app-wide rather than a different visual
  in every corner. Both reasons are printed rather than implied: a barcode
  needs a food database Kati has not chosen, and a search needs a licence,
  coverage and rate limits that are unresolved.

  ## A missing aisle becomes `Uncategorised`, never nothing

  The caption states the consequence, and it is the sharp end of the whole
  sheet: **a dropped ingredient vanishes from the shopping list.** So an
  ingredient with no aisle is filed under one rather than filed nowhere, and
  `Kati.Meals.Aisle` already has the value for it.

  ## The preview is the point of the bottom half

  *This is how the row will look in the meal.* An ingredient with no numbers
  still lands on the shopping list and still leaves the meal total approximate,
  and showing the row it will become is how the sheet says both at once.

  ## Save writes the row the preview is showing

  It popped the screen and wrote nothing, which on a sheet whose whole bottom
  half is a picture of the row it is about to add is the worst possible place
  for that: the preview said *this is how the row will look in the meal*, the
  sheet closed as though it had landed, and the meal behind it was unchanged.
  Screen 118 re-reads its ingredient list on every render, so the row's absence
  was visible one frame later and there was nothing anywhere to say why.

  `Kati.Meals.Totals.write_ingredient/2` is the only door in — not
  `Ash.create/2` on `Kati.Meals.RecipeIngredient`. That module is the sole
  writer of a recipe's cached macro totals and its three-step order (*bump the
  rev, write the line, store the totals*) is what stops a stale cache being
  frozen into a `Kati.Meals.MealLog`. A line inserted around it would leave
  `totals_rev == ingredients_rev` over a recipe whose ingredients had changed,
  which is the one ordering `Kati.Meals.Changes.FreezeNutrition` cannot
  survive: it freezes what the cache claims, permanently, and a logged meal is
  a record of something that was eaten.

  ## Which meal, and why the sheet refuses when it was handed none

  The meal that opened the sheet. Screen 118 pushes here with its own
  `meal_id` — `Kati.Screens.MealEdit.params_for/1`, the same key and the same
  spelling the editor itself mounts with — and this screen carries it from
  `mount/3` to the write without asking the store for a meal in between. That
  is #84 in one sentence: a sheet that re-queried for "a recipe" would file
  your ingredient against whichever row the query happened to head with, and
  the meal editor behind it would redraw showing no change at all.

  Handed no id, **it does not write**. That is not the same decision screen
  118's own `save_slot/2` makes, and the difference is the difference between
  the two writes: a slot is a field of the meal the editor is *already drawing*,
  so writing it back to the library's first is writing back to what is on
  screen. An ingredient is a NEW ROW, and a new row filed against a meal nobody
  named is a row in somebody else's dinner. So the sheet stays open and says
  `Nothing to save yet.`

  This is also what makes the sheet safe under `Kati.ScreenTapSweepTest`, which
  taps `:save` on every screen against the shared database with no params at
  all: no id, no write, nothing left behind for the next suite to trip over.
  `Kati.Screens.Rating` reached the same answer from the same corner.

  ## What Save does NOT write, and why that is not a missing write path

  The aisle is a real control — five chips, one selected, and the chosen one is
  what the row is filed under. The name, the quantity and the unit are the
  draft's, because nothing on this sheet edits them: `:edit_name`,
  `:edit_quantity` and `:edit_unit` are drawn rows that open nothing. So Save
  commits exactly what the preview is showing, which is the honest reading of a
  sheet that draws its own outcome, and the day a field lands on those three
  rows the write path they will use is the one that now exists. Screen 118 says
  the same thing about its title and method, and screen 33 about its five inert
  context rows.

  ## `Uncategorised` is this sheet's word for `Kati.Meals.Aisle`'s `:other`

  Two of the five chips do not read as their stored label — the sheet draws
  `Dairy` where `Kati.Meals.Aisle` prints `Dairy & eggs`, and `Uncategorised`
  where it prints `Other`. The chips are the drawing's copy and the labels are
  screen 48's, so neither can move to meet the other; `aisle_value/1` is where
  the two vocabularies are mapped, once. The consequence is visible and worth
  stating: the preview here says `UNCATEGORISED · FREE TEXT` and the row it
  becomes reads `OTHER · FREE TEXT` in the meal. Same bucket, two words for it,
  and the shopping list groups by the atom.
  """

  use Mob.Screen
  import Mob.Sigil

  alias Kati.Meals.Recipe
  alias Kati.Meals.SampleLibrary
  alias Kati.Meals.Totals
  alias Kati.Screens.MealEdit
  alias Kati.UI
  alias Kati.UI.SettingsList
  alias Kati.UI.Sheet
  alias Kati.Write

  @doc """
  The sheet, holding the draft and the meal it will be added to.

  `meal_id` is the whole of #84 here: the row screen 118 named when it pushed,
  carried rather than looked up again at save time. `nil` — pushed by an editor
  that names no meal — is a sheet that will refuse rather than pick one.
  """
  def mount(params, _session, socket) do
    Kati.Theme.activate()

    draft = SampleLibrary.draft()

    {:ok,
     socket
     |> Mob.Socket.assign(:draft, draft)
     |> Mob.Socket.assign(:aisle, draft.aisle)
     |> Mob.Socket.assign(:meal_id, Map.get(params || %{}, :meal_id))
     |> Mob.Socket.assign(:save_error, nil)}
  end

  def render(assigns),
    do: Sheet.sheet("Add an ingredient", body(assigns), Kati.Screens.Identity.of(__MODULE__))

  @doc false
  def body(assigns) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.AddIngredient.fields(assigns.draft)}
      <Spacer size={18} />
      {UI.eyebrow("Aisle")}
      {Kati.Screens.AddIngredient.aisles(assigns.aisle)}
      <Spacer size={18} />
      {UI.eyebrow("Nutrition per 100 g")}
      {Kati.Screens.AddIngredient.nutrition()}
      <Spacer size={18} />
      {Kati.Screens.AddIngredient.preview(assigns.draft, assigns.aisle)}
      <Spacer size={16} />
      {Kati.Screens.AddIngredient.save_notice(assigns.save_error)}
      {Sheet.commit("Save", :save)}
    </Column>
    """
  end

  @doc """
  The sentence that says the ingredient did not save, or nothing.

  Above the button rather than below it, which is `Kati.Screens.NewGoal`'s
  argument on the same sheet frame: `Kati.UI.Sheet.sheet/3` closes with 34pt of
  bottom padding and the commit pill is the last thing in it, so a notice under
  the pill lands in that padding or off the edge of the phones this sheet
  already fills. Above it, the sentence is between the person and the control
  they just pressed.

  `nil` draws a zero `Spacer` rather than nothing, so the healthy sheet and the
  failed one have the same node shape and the preview above does not shift when
  the notice appears.
  """
  @spec save_notice(String.t() | nil) :: map()
  def save_notice(nil), do: ~MOB"<Spacer size={0} />"

  def save_notice(message) do
    assigns = %{message: message}

    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={@message}
        text_size={12.5}
        font_weight="semibold"
        line_height={1.45}
        text_color={Kati.Theme.Palette.red()}
      />
      <Spacer size={12} />
    </Column>
    """
  end

  @doc """
  Name, quantity and unit.

  Three rows rather than a form, because Mob has no text input and every field
  in this app is a drawn value with a tap behind it (#45). What the rows do
  carry is the *shape* of the record — which is what makes the preview below
  them meaningful.
  """
  @spec fields(map()) :: map()
  def fields(draft) do
    rows = [
      SettingsList.row(
        nil,
        SettingsList.body("Name", nil),
        SettingsList.trailing(Kati.Screens.AddIngredient.value(draft.name)),
        on_tap: {self(), :edit_name}
      ),
      SettingsList.row(
        nil,
        SettingsList.body("Quantity", nil),
        SettingsList.trailing(Kati.Screens.AddIngredient.value(draft.quantity)),
        on_tap: {self(), :edit_quantity}
      ),
      SettingsList.row(
        nil,
        SettingsList.body("Unit", nil),
        SettingsList.trailing(Kati.Screens.AddIngredient.unit_trailing(draft.unit)),
        on_tap: {self(), :edit_unit}
      )
    ]

    SettingsList.card(rows)
  end

  @doc false
  def value(text) do
    assigns = %{text: text}

    ~MOB"""
    <Text text={@text} text_size={13.5} text_color={Kati.Theme.Palette.sub()} max_lines={1} />
    """
  end

  @doc false
  def unit_trailing(unit) do
    assigns = %{unit: unit}

    ~MOB"""
    <Row align="center">
      <Text
        text={@unit}
        font_family="mono"
        text_size={12.5}
        text_color={Kati.Theme.Palette.sub()}
        max_lines={1}
      />
      <Spacer size={8} />
      {Kati.UI.symbol("unfold_more", size: 18, color: Kati.Theme.Palette.tertiary())}
    </Row>
    """
  end

  @doc """
  The aisle chips, with `Uncategorised` always among them.

  Always, because it is not a fallback the user picks — it is where an
  ingredient goes when nobody said, and it exists on the page so the shopping
  list never loses a row. See the moduledoc.
  """
  @spec aisles(String.t()) :: map()
  def aisles(active) do
    chips =
      SampleLibrary.aisles()
      |> Enum.map(fn aisle ->
        UI.chip(aisle,
          selected: aisle == active,
          on_toggle: String.to_atom("aisle_" <> String.replace(aisle, " ", "_"))
        )
      end)
      |> Enum.intersperse(~MOB"<Spacer size={7} />")

    ~MOB"""
    <Scroll axis="horizontal">
      <Row>
        {chips}
      </Row>
    </Scroll>
    """
  end

  @doc """
  The three ways to get nutrition figures, two of them not in v1.

  Drawn rather than hidden, because the two that do not exist are the two
  people will look for first, and a page that simply omitted them would invite
  the question forever. Each says what is actually missing.
  """
  @spec nutrition() :: map()
  def nutrition do
    rows =
      Enum.map(SampleLibrary.nutrition_paths(), fn path ->
        SettingsList.row(
          SettingsList.icon_tile(path.icon),
          SettingsList.body(path.title, path.sub, lines: 2),
          SettingsList.trailing(Kati.Screens.AddIngredient.path_trailing(path.built?)),
          on_tap: Kati.Screens.AddIngredient.path_tap(path.built?)
        )
      end)

    SettingsList.card(rows)
  end

  @doc false
  def path_trailing(true), do: SettingsList.chevron()

  def path_trailing(false) do
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
        text="NOT IN V1"
        font_family="mono"
        text_size={9}
        letter_spacing={0.1}
        text_color={Kati.Theme.Palette.sub()}
        max_lines={1}
      />
    </Row>
    """
  end

  # An unbuilt path takes no tag at all rather than an inert one — a tag
  # nothing answers is a dead tap, and these are not dead, they are labelled.
  @doc false
  def path_tap(true), do: {self(), :type_it_in}
  def path_tap(false), do: nil

  @doc """
  The row this ingredient will become, drawn as it will look.

  The same `state_glyph/1` the meal editor uses, so the preview and the thing
  it previews cannot diverge.
  """
  @spec preview(map(), String.t()) :: map()
  def preview(draft, aisle) do
    meta = String.upcase(aisle <> " · Free text")

    assigns = %{
      row:
        MealEdit.ingredient_row(
          %{
            name: draft.name,
            meta: meta,
            amount: draft.quantity,
            state: :free_text
          },
          false
        )
    }

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card([@row])}
      <Spacer size={11} />
      {Kati.UI.SettingsList.note("info", "This is how the row will look in the meal. It adds no numbers, so the meal total stays approximate — and it still lands on the shopping list.")}
    </Column>
    """
  end

  def handle_info({:tap, :close}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}

  # A save that landed closes the sheet; a save that did not KEEPS IT OPEN and
  # says so. Closing on failure is the specific behaviour `Kati.Write` exists to
  # forbid — a sheet that shuts is how a lost write looks like a completed one,
  # and this sheet had nothing to distinguish the two because it never wrote at
  # all.
  def handle_info({:tap, :save}, socket) do
    case save_ingredient(socket.assigns) do
      {:ok, _ingredient} ->
        {:noreply,
         socket
         |> Mob.Socket.assign(:save_error, nil)
         |> Mob.Socket.pop_screen()}

      {:error, _reason} = error ->
        {:noreply, Mob.Socket.assign(socket, :save_error, Write.message(error))}
    end
  end

  def handle_info({:tap, tag}, socket) do
    case Atom.to_string(tag) do
      "aisle_" <> aisle ->
        {:noreply, Mob.Socket.assign(socket, :aisle, String.replace(aisle, "_", " "))}

      _other ->
        {:noreply, socket}
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  @doc """
  Add the drafted line to the meal that opened this sheet.

  Through `Kati.Meals.Totals.write_ingredient/2`, which is the only writer of a
  recipe's cached totals — see the moduledoc for what going around it would
  cost a frozen `Kati.Meals.MealLog`.

  Two refusals, and neither is a quiet no-op:

    * **No meal id** — the sheet was opened by an editor that names no meal, so
      there is nothing to add to. `:nothing_to_save`, which the person reads as
      *Nothing to save yet.*
    * **An id whose row is gone** — a meal deleted while this sheet was open.
      Not the same fact as the first, and not a reason to write the line
      somewhere else.

  Returns `{:ok, line}` or `{:error, reason}`, both through `Kati.Write.note/2`.
  Never a bare `:ok`: the sheet's own drawing is identical whether a save landed
  or not, so the tuple is the only thing that can tell them apart.
  """
  @spec save_ingredient(map()) :: {:ok, struct()} | {:error, term()}
  def save_ingredient(%{meal_id: nil}),
    do: Write.note({:error, :nothing_to_save}, "add an ingredient")

  def save_ingredient(%{meal_id: id} = assigns) do
    result =
      case meal_record(id) do
        %Recipe{} = recipe ->
          {line, _totalled} = Totals.write_ingredient(recipe, line_attrs(recipe, assigns))
          {:ok, line}

        nil ->
          {:error, :meal_is_gone}
      end

    Write.note(result, "add an ingredient")
  end

  defp meal_record(id) do
    # The meal named, as a row, or `nil`.
    #
    # A READ, which is why it is a function of its own rather than a `case` in
    # the writer above: the guard below is the one
    # `Kati.Screens.MealEdit.recipe/1` carries for the same reason — a store
    # that cannot be reached mid-migration must leave the sheet open saying the
    # save did not land, not kill the screen process the person is looking at.
    # On a WRITE the same construction would be the app deciding on your behalf
    # that a failure did not happen, and `Kati.WriteContractTest` forbids it
    # inside `save_ingredient/1` for exactly that reason.
    case Ash.get(Recipe, id) do
      {:ok, %Recipe{} = recipe} -> recipe
      _other -> nil
    end
  rescue
    _error -> nil
  end

  @doc """
  The line, in `Kati.Meals.RecipeIngredient` terms.

  Everything the sheet knows and nothing it does not: no kcal and no macros,
  because the two paths that would supply them carry `NOT IN V1` and the third
  is a form Mob cannot draw yet. The defaults are all zero and the preview says
  so out loud — *it adds no numbers, so the meal total stays approximate.*

  `shop_for` is the resource's own default and is left alone deliberately: the
  sheet's sharp end is that **a dropped ingredient vanishes from the shopping
  list**, and an ingredient added here has never been ticked off one.
  """
  @spec line_attrs(Recipe.t(), map()) :: map()
  def line_attrs(%Recipe{} = recipe, %{draft: draft, aisle: aisle}) do
    %{
      position: next_position(recipe),
      name: draft.name,
      amount_mg: Kati.Screens.AddIngredient.amount_mg(draft.quantity),
      unit: Kati.Screens.AddIngredient.unit_value(draft.unit),
      aisle: Kati.Screens.AddIngredient.aisle_value(aisle)
    }
  end

  # The next free slot in this recipe's list, never a constant.
  #
  # `Kati.Meals.RecipeIngredient` carries a UNIQUE index on
  # `{recipe_id, position}` — "already a line at this position" — so a sheet
  # that wrote `position: 0` would add one ingredient to a meal and then reject
  # every ingredient after it. Max-plus-one rather than a count, because a
  # removed line leaves a hole and a count would land back on top of a row that
  # is still there.
  defp next_position(%Recipe{} = recipe) do
    positions =
      recipe
      |> Kati.Screens.MealLibrary.ingredients_of()
      |> Enum.map(& &1.position)

    if positions == [], do: 0, else: Enum.max(positions) + 1
  end

  @doc """
  A drawn quantity in thousandths of its unit, or zero when it is words.

  Zero is not a failure to parse — it is the app's own way of storing *the
  quantity is words*: `Kati.Screens.MealEdit.amount_line/1` matches it first and
  prints `a few`, and `ingredient_state/1` reads a line with no amount and no
  figures as `:free_text`, which is the state this sheet's preview draws. So
  the drawing's `a few` round-trips to the row the preview promised rather than
  to a `0 g` that claims a measurement nobody made.

      iex> Kati.Screens.AddIngredient.amount_mg("180")
      180000
      iex> Kati.Screens.AddIngredient.amount_mg("1.5")
      1500
      iex> Kati.Screens.AddIngredient.amount_mg("a few")
      0
  """
  @spec amount_mg(String.t()) :: non_neg_integer()
  def amount_mg(quantity) when is_binary(quantity) do
    case Float.parse(quantity) do
      {number, _rest} when number > 0 -> round(number * 1000)
      _other -> 0
    end
  end

  def amount_mg(_quantity), do: 0

  @doc """
  The stored unit for a drawn one.

  `free` is not a unit and the resource has no value for it — it is the
  drawing's word for *the quantity is words*, which the row stores as
  `amount_mg: 0`. The column is `allow_nil?: false`, so the line still needs a
  unit, and the resource's own default is the honest one: nothing reads it
  while the amount is zero.

      iex> Kati.Screens.AddIngredient.unit_value("ml")
      :ml
      iex> Kati.Screens.AddIngredient.unit_value("free")
      :g
  """
  @spec unit_value(String.t()) :: atom()
  def unit_value(unit) when unit in ~w(g ml piece tsp tbsp pinch pack tub),
    do: String.to_existing_atom(unit)

  def unit_value(_free), do: :g

  @doc """
  The `Kati.Meals.Aisle` value a chip stands for.

  The one place this sheet's vocabulary and the store's are mapped — see the
  moduledoc for why `Dairy` and `Uncategorised` cannot simply be renamed to
  match `Kati.Meals.Aisle.label/1`.

  The catch-all is the sheet's stated rule rather than a shrug: **a missing
  aisle becomes `Uncategorised`, never nothing**, because an ingredient filed
  nowhere vanishes off the shopping list, and `:other` is the value that exists
  so an aisle is always answerable.

      iex> Kati.Screens.AddIngredient.aisle_value("Fish & meat")
      :fish_and_meat
      iex> Kati.Screens.AddIngredient.aisle_value("Uncategorised")
      :other
  """
  @spec aisle_value(String.t()) :: atom()
  def aisle_value("Produce"), do: :produce
  def aisle_value("Cupboard"), do: :cupboard
  def aisle_value("Fish & meat"), do: :fish_and_meat
  def aisle_value("Dairy"), do: :dairy_and_eggs
  def aisle_value(_uncategorised), do: :other
end
