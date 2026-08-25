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
  """

  use Mob.Screen
  import Mob.Sigil

  alias Kati.Meals.SampleLibrary
  alias Kati.Screens.MealEdit
  alias Kati.UI
  alias Kati.UI.SettingsList
  alias Kati.UI.Sheet

  def mount(_params, _session, socket) do
    Kati.Theme.activate()

    {:ok,
     socket
     |> Mob.Socket.assign(:draft, SampleLibrary.draft())
     |> Mob.Socket.assign(:aisle, SampleLibrary.draft().aisle)}
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
      {Sheet.commit("Save", :save)}
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
        MealEdit.ingredient_row(%{
          name: draft.name,
          meta: meta,
          amount: draft.quantity,
          state: :free_text
        })
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

  def handle_info({:tap, :save}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}

  def handle_info({:tap, tag}, socket) do
    case Atom.to_string(tag) do
      "aisle_" <> aisle ->
        {:noreply, Mob.Socket.assign(socket, :aisle, String.replace(aisle, "_", " "))}

      _other ->
        {:noreply, socket}
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}
end
