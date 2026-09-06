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

    {:ok,
     socket
     |> Mob.Socket.assign(:region, Services.region())
     |> Mob.Socket.assign(:query, "")}
  end

  def render(assigns),
    do: Sheet.sheet("Your country", body(assigns), Kati.Screens.Identity.of(__MODULE__))

  @doc false
  def body(assigns) do
    region = assigns.region

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.CountryPicker.search_field(Map.get(assigns, :query, ""))}
      <Spacer size={16} />
      {Kati.Screens.CountryPicker.list(region, Map.get(assigns, :query, ""))}
      <Spacer size={14} />
      {Kati.UI.SettingsList.note("info", "Availability is per country. Changing this changes what Kati shows as watchable — it never touches your library, ratings or history.")}
    </Column>
    """
  end

  @doc """
  The search field, whose placeholder carries the real total.

  The placeholder counts `Kati.Services.countries/0`. It said `Search 190
  countries` — JustWatch's number, over Kati's seven — on the argument that
  saying `Search 7` would be *telling the truth about the wrong thing*. It is
  the truth about the thing this field actually filters, which is what a
  placeholder is for; the day the list is 190 the placeholder says 190 without
  anybody remembering to come back here.
  """
  @spec search_field(String.t()) :: map()
  def search_field(query \\ "") do
    assigns = %{
      query: query,
      on_change: {self(), :country_query},
      # `Search 190 countries` over a list of seven, and the field was a
      # picture — its `on_tap` fell through to `handle_info(_message, …)`, and
      # the tap sweep had it on `@inert_taps`. MOVIES-AND-TV.md #78. Both
      # halves are fixed here: the field is a `<TextField>` that filters, and
      # the placeholder counts the list it is over.
      placeholder: "Search #{length(Services.countries())} countries"
    }

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
    >
      {UI.symbol("search", size: 19, color: Palette.tertiary())}
      <Spacer size={11} />
      <TextField
        value={@query}
        placeholder={@placeholder}
        return_key="search"
        weight={1.0}
        accessibility_id="country_query"
        on_change={@on_change}
      />
    </Row>
    """
  end

  @doc """
  The countries a query leaves, by name or by code.

  By code as well, because a reader who knows `NL` should not have to remember
  whether Kati calls it *Netherlands* or *The Netherlands*.

      iex> Kati.Screens.CountryPicker.matching("ger")
      [{"DE", "Germany"}]

      iex> Kati.Screens.CountryPicker.matching("NL")
      [{"NL", "Netherlands"}]

      iex> Kati.Screens.CountryPicker.matching("") == Kati.Services.countries()
      true
  """
  @spec matching(String.t()) :: [{String.t(), String.t()}]
  def matching(query) do
    case String.trim(query) do
      "" ->
        Services.countries()

      typed ->
        needle = String.downcase(typed)

        Enum.filter(Services.countries(), fn {code, name} ->
          String.contains?(String.downcase(name), needle) or
            String.contains?(String.downcase(code), needle)
        end)
    end
  end

  @doc "Every country, the current one marked."
  @spec list(String.t()) :: map()
  def list(region, query \\ "") do
    case Kati.Screens.CountryPicker.matching(query) do
      [] -> Kati.Screens.CountryPicker.nothing_card(query)
      countries -> SettingsList.card(Enum.map(countries, &row_for(&1, region)))
    end
  end

  defp row_for({code, name}, region),
    do: Kati.Screens.CountryPicker.row(code, name, code == region)

  @doc "A query that matches no country, said rather than left as a gap."
  @spec nothing_card(String.t()) :: map()
  def nothing_card(query) do
    typed = String.trim(query)

    SettingsList.card([
      SettingsList.row(
        SettingsList.icon_tile("search"),
        Kati.UI.SettingsList.body(
          "No country matches",
          "Kati lists #{length(Services.countries())}, and none of them is “#{typed}”."
        ),
        SettingsList.trailing(nil),
        rule: false
      )
    ])
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

  def handle_info({:tap, :close}, socket), do: {:noreply, Kati.Screens.Resume.pop(socket)}

  def handle_info({:change, :country_query, typed}, socket) when is_binary(typed),
    do: {:noreply, Mob.Socket.assign(socket, :query, typed)}

  def handle_info({:tap, tag}, socket) do
    case Atom.to_string(tag) do
      "pick_" <> code ->
        Services.put_region(code)
        {:noreply, socket |> Mob.Socket.assign(:region, code) |> Kati.Screens.Resume.pop()}

      _other ->
        {:noreply, socket}
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}
end
