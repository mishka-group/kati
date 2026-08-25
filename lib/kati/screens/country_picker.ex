defmodule Kati.Screens.CountryPicker do
  @moduledoc """
  Screen 94 — Your country, a sheet over My services.

  ## A sheet, not a pushed screen

  The design's caption says why: *picking a country is one decision you come
  back from, not a place you navigate to.* A pushed screen puts the choice on
  the back stack and makes leaving it feel like retreating; a sheet closes.

  ## The tick is a mark, not a radio

  Also the caption's: *the tick marks the current selection rather than a radio
  control, matching how 35 marks per-show state.* The difference matters
  because a radio group implies the whole list is one control and every row is
  equally a candidate — here the list is 190 long and the tick is telling you
  where you are in it.

  ## The footnote is repeated on purpose

  Screen 92 already says availability is per country. This says it again, in the
  place the decision is actually made, and adds the half screen 92 does not
  need to: *it never touches your library, ratings or history.* A country
  picker in a media app is a frightening control until somebody says what it
  cannot do.
  """

  use Mob.Screen
  import Mob.Sigil

  alias Kati.Services
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList
  alias Kati.UI.Sheet

  def mount(_params, _session, socket) do
    Kati.Theme.activate()
    {:ok, Mob.Socket.assign(socket, :region, Services.region())}
  end

  def render(assigns),
    do: Sheet.sheet("Your country", body(assigns), Kati.Screens.Identity.of(__MODULE__))

  @doc false
  def body(assigns) do
    region = assigns.region

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.CountryPicker.search_field()}
      <Spacer size={16} />
      {Kati.Screens.CountryPicker.list(region)}
      <Spacer size={14} />
      {Kati.UI.SettingsList.note("info", "Availability is per country. Changing this changes what Kati shows as watchable — it never touches your library, ratings or history.")}
    </Column>
    """
  end

  @doc """
  The search field, whose placeholder carries the real total.

  190 is the count of countries JustWatch answers for, and it is a literal here
  because `Kati.Services.countries/0` holds the seven the drawing lists rather
  than all of them — a placeholder that said `Search 7 countries` would be
  telling the truth about the wrong thing.
  """
  @spec search_field() :: map()
  def search_field do
    ~MOB"""
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
        text="Search 190 countries"
        text_size={14}
        text_color={Palette.tertiary()}
        weight={1.0}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc "Every country, the current one marked."
  @spec list(String.t()) :: map()
  def list(region) do
    rows =
      Enum.map(Services.countries(), fn {code, name} ->
        Kati.Screens.CountryPicker.row(code, name, code == region)
      end)

    SettingsList.card(rows)
  end

  @doc false
  def row(code, name, current?) do
    SettingsList.row(
      Kati.Screens.MyServices.flag_tile(Services.flag(code)),
      SettingsList.body(name, nil),
      SettingsList.trailing(Kati.Screens.CountryPicker.tick(current?)),
      on_tap: {self(), String.to_atom("pick_" <> code)}
    )
  end

  @doc false
  def tick(false), do: nil

  def tick(true), do: UI.symbol("check", size: 20, color: Palette.green())

  def handle_info({:tap, :close}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}

  def handle_info({:tap, tag}, socket) do
    case Atom.to_string(tag) do
      "pick_" <> code ->
        Services.put_region(code)
        {:noreply, socket |> Mob.Socket.assign(:region, code) |> Mob.Socket.pop_screen()}

      _other ->
        {:noreply, socket}
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}
end
