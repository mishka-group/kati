defmodule Kati.Screens.CountryPickerFa do
  @moduledoc """
  کشور شما — the Persian country sheet.

  Board **301**, the mirror of 94, and the door screen 97's country row has
  never had. Board 324 draws that row inviting a choice — *«کشورتان را انتخاب
  کنید / تا این تنظیم نشود چیزی کار نمی‌کند»* — and its own note names what
  opens behind it: *«۳۰۱ انتخابگر پشت این ردیف را می‌کشد.»*

  A sheet and not a pushed screen, for 94's reason quoted whole: *picking a
  country is one decision you come back from, not a place you navigate to.*
  The tick is a mark rather than a radio, for 94's reason as well.

  ## Iran is the mark before any choice, and that is the board's ruling

  *«تیک روی ایران است نه بریتانیا: ۹۷ در ایران گرفته شده و آینه‌ای که پیش از هر
  انتخابی برای بریتانیا پاسخ بدهد، برای کشور اشتباه پاسخ داده.»*

  `Kati.Services.region/0` answers `"GB"` on a phone nobody has told anything,
  because the English drawings were captured in one country. This sheet reads
  `Kati.Services.chosen_region/0` instead and falls back to `"IR"`, so the
  Persian side answers for the country its own boards were captured in — and
  the fallback is a MARK rather than a write. Nothing is stored until a row is
  tapped, which is what keeps screen 97's row able to say no country is set.

  301's closing sentence is the bug that made this distinction necessary:
  *«امروز کسی که آگاهانه بریتانیا را انتخاب کند باز ایران می‌بیند، چون کد
  نمی‌تواند «GB»ی ذخیره‌شده را از تنظیم‌نشده تشخیص دهد.»* Screen 97 rewrote
  `region/0`'s default to `"IR"` and could not tell a chosen Britain from an
  unchosen anything. It reads `chosen_region/0` now, and so does this.

  ## One deviation from the board, and it is a decision already made

  301 draws the field as *«جست‌وجو در ۱۹۰ کشور»* and argues for it: seven rows
  do not need filtering, but the sentence should speak correctly about the
  list. That is the exact argument MOVIES-AND-TV.md #78 was filed against on
  screen 94 — `Search 190 countries` over a list of seven — and the fix there
  was to count what the field actually filters, so that *the day the list is
  190 the placeholder says 190 without anybody remembering to come back here*.
  A Persian mirror that said ۱۹۰ over seven rows would put that defect back in
  the other locale, so the placeholder counts `Kati.Services.countries/0` and
  prints the number in Persian digits.

  ## What is this file's, and what is 94's

  Every string, and nothing else. The card, the row, the paper tile, the flag
  tile, the tick and the search field's geometry are the shared controls; a
  flag does not translate and neither does a country code. The matching is
  `Kati.Screens.CountryPicker.matching/1`'s — by name or by code — with the
  Persian names added to what a query is compared against, because a reader
  typing «آلمان» is not going to be helped by a list that only knows
  *Germany*.
  """

  use Mob.Screen

  import Mob.Sigil

  alias Kati.I18n.Digits
  alias Kati.Screens.CountryPicker
  alias Kati.Screens.MyServicesFa
  alias Kati.Services
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @copy %{
    title: "کشور شما",
    search_prefix: "جست‌وجو در ",
    search_suffix: " کشور",
    nothing: "کشوری پیدا نشد",
    note:
      "دسترسی به محتوا کشور به کشور فرق می‌کند. تغییر این گزینه آنچه را که «در دسترس» " <>
        "شمرده می‌شود عوض می‌کند و به کتابخانه، امتیازها و تاریخچهٔ شما دست نمی‌زند."
  }

  @impl true
  def mount(_params, _session, socket) do
    Kati.Theme.activate()

    {:ok,
     socket
     |> Mob.Socket.assign(:region, Kati.Screens.CountryPickerFa.marked())
     |> Mob.Socket.assign(:query, "")}
  end

  @impl true
  def render(assigns) do
    Kati.UI.Sheet.sheet(
      @copy.title,
      Kati.Screens.CountryPickerFa.content(assigns),
      Kati.Screens.Identity.of(__MODULE__),
      face: "fa"
    )
  end

  @doc """
  The country this sheet marks: the one the reader chose, or Iran.

  Board 301's ruling. `Kati.Services.region/0`'s `"GB"` is a default rather
  than a choice, and answering for Britain on a Persian phone that has said
  nothing is answering for the wrong country. A MARK, never a write — screen
  97's row still says no country is set until one is tapped here.
  """
  @spec marked() :: String.t()
  def marked do
    case Services.chosen_region() do
      code when is_binary(code) and code != "" -> code
      _unchosen -> "IR"
    end
  end

  @doc false
  def content(assigns) do
    query = Map.get(assigns, :query, "")
    # Bound to a local: inside `~MOB` an `@name` is an ASSIGN, so `@copy.note`
    # would be read as `assigns.copy` and raise.
    note = Kati.Screens.DataSourcesFa.note(@copy.note)

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.CountryPickerFa.search_field(query)}
      <Spacer size={16} />
      {Kati.Screens.CountryPickerFa.list(assigns.region, query)}
      <Spacer size={14} />
      {note}
    </Column>
    """
  end

  @doc """
  The placeholder, counting the list it is over, in Persian digits.

  See the moduledoc for why it is not the board's ۱۹۰.
  """
  @spec placeholder() :: String.t()
  def placeholder do
    @copy.search_prefix <>
      Digits.to_persian(length(Services.countries())) <> @copy.search_suffix
  end

  @doc false
  def search_field(query \\ "") do
    assigns = %{
      query: query,
      on_change: {self(), :country_query},
      placeholder: Kati.Screens.CountryPickerFa.placeholder()
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
        font_family="fa"
        weight={1.0}
        accessibility_id="country_query_fa"
        on_change={@on_change}
      />
    </Row>
    """
  end

  @doc """
  The countries a query leaves — by Persian name, by English name, or by code.

  Three, not 94's two. A Persian reader types «آلمان»; a reader who knows the
  catalogue types `DE`; and a reader reading an English source types `Germany`.
  All three name one country and none of them should come back empty.

      iex> Kati.Screens.CountryPickerFa.matching("آلمان")
      [{"DE", "آلمان"}]

      iex> Kati.Screens.CountryPickerFa.matching("ger")
      [{"DE", "آلمان"}]

      iex> Kati.Screens.CountryPickerFa.matching("NL")
      [{"NL", "هلند"}]
  """
  @spec matching(String.t()) :: [{String.t(), String.t()}]
  def matching(query) do
    typed = String.trim(query)

    Services.countries()
    |> Enum.filter(fn {code, name} ->
      typed == "" or
        String.contains?(MyServicesFa.region_name(code), typed) or
        String.contains?(String.downcase(name), String.downcase(typed)) or
        String.contains?(String.downcase(code), String.downcase(typed))
    end)
    |> Enum.map(fn {code, _english} -> {code, MyServicesFa.region_name(code)} end)
  end

  @doc "Every country, the marked one ticked."
  @spec list(String.t(), String.t()) :: map()
  def list(region, query \\ "") do
    case Kati.Screens.CountryPickerFa.matching(query) do
      [] -> Kati.Screens.CountryPickerFa.nothing_card(query)
      countries -> SettingsList.card(Enum.map(countries, &row_for(&1, region)))
    end
  end

  defp row_for({code, name}, region),
    do: Kati.Screens.CountryPickerFa.row(code, name, code == region)

  @doc "A query that matches no country, said rather than left as a gap."
  @spec nothing_card(String.t()) :: map()
  def nothing_card(query) do
    typed = String.trim(query)

    body =
      MyServicesFa.body(
        @copy.nothing,
        "کاتی " <>
          Digits.to_persian(length(Services.countries())) <>
          " کشور دارد و هیچ‌کدام «" <> typed <> "» نیست."
      )

    SettingsList.card([
      SettingsList.row(SettingsList.icon_tile("search"), body, SettingsList.trailing(nil),
        rule: false
      )
    ])
  end

  @doc false
  def row(code, name, current?) do
    SettingsList.row(
      Kati.Screens.MyServices.flag_tile(Services.flag(code)),
      MyServicesFa.body(name, nil),
      SettingsList.trailing(CountryPicker.tick(current?)),
      on_tap: {self(), String.to_atom("pick_" <> code)}
    )
  end

  @impl true
  def handle_info({:tap, :close}, socket), do: {:noreply, Kati.Screens.Resume.pop(socket)}

  def handle_info({:change, :country_query, typed}, socket) when is_binary(typed),
    do: {:noreply, Mob.Socket.assign(socket, :query, typed)}

  def handle_info({:tap, tag}, socket) when is_atom(tag) do
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
