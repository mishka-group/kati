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
  use Gettext, backend: Kati.Gettext
  import Mob.Sigil

  alias Kati.Services
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList
  alias Kati.UI.Sheet

  def mount(_params, _session, socket) do
    Kati.Theme.activate()
    Kati.Locale.activate()

    {:ok,
     socket
     |> Mob.Socket.assign(:region, Kati.Screens.CountryPicker.marked())
     |> Mob.Socket.assign(:query, "")}
  end

  def render(assigns),
    do: Sheet.sheet(gettext("Your country"), body(assigns), Kati.Screens.Identity.of(__MODULE__))

  @doc false
  def body(assigns) do
    region = assigns.region

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.CountryPicker.search_field(Map.get(assigns, :query, ""))}
      <Spacer size={16} />
      {Kati.Screens.CountryPicker.list(region, Map.get(assigns, :query, ""))}
      <Spacer size={14} />
      {Kati.UI.SettingsList.note("info", gettext("Availability is per country. Changing this changes what Kati shows as watchable — it never touches your library, ratings or history."))}
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
      # the tap sweep had it on `@inert_taps`. Both
      # halves are fixed here: the field is a `<TextField>` that filters, and
      # the placeholder counts the list it is over.
      placeholder: Kati.Screens.CountryPicker.placeholder()
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
  What the search field says, counting the list it is actually over.

      iex> Kati.Screens.CountryPicker.placeholder()
      "Search 7 countries"

  It said `Search 190 countries` over a list of seven,
  and 190 is JustWatch's number rather than Kati's. The numeral takes the
  reader's own digits through `Kati.Locale.number/1`, which is why board 301
  reads `جست‌وجو در ۷ کشور`.
  """
  @spec placeholder() :: String.t()
  def placeholder do
    gettext("Search %{count} countries", count: Kati.Locale.number(length(Services.countries())))
  end

  @doc """
  The country this sheet marks: the one the reader chose, or the locale's own.

      iex> Kati.Screens.CountryPicker.marked()
      "GB"

  Board 301's ruling, kept for both scripts. `Kati.Services.region/0`'s `"GB"`
  is a default rather than a choice — it is the country the drawings were
  captured in — and answering for Britain on a Persian phone that has said
  nothing is answering for the wrong country. A MARK, never a write: screen 97's
  row still says no country is set until one is tapped here.
  """
  @spec marked() :: String.t()
  def marked do
    case Services.chosen_region() do
      code when is_binary(code) and code != "" -> code
      _unchosen -> Kati.Locale.pick("GB", "IR")
    end
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
    named =
      Enum.map(Services.countries(), fn {code, _en} -> {code, Services.region_name(code)} end)

    case String.trim(query) do
      "" ->
        named

      typed ->
        needle = String.downcase(typed)

        Enum.filter(named, fn {code, name} ->
          String.contains?(name, typed) or
            String.contains?(String.downcase(Services.latin_region_name(code)), needle) or
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
          gettext("No country matches"),
          gettext("Kati lists %{count}, and none of them is “%{typed}”.",
            count: Kati.Locale.number(length(Services.countries())),
            typed: typed
          )
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
