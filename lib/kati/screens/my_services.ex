defmodule Kati.Screens.MyServices do
  @moduledoc """
  Screen 92 — My services, pushed under Settings.

  The design's own caption: *the screen that makes availability, leaving-soon
  and cost-per-watched-hour true rather than decorative.* Everything else in the
  app that says a title is watchable is downstream of this page.

  ## Region sits above the list, not in a More group

  Because the list is meaningless without it. `Availability is per country.
  Telling you a film is on Lumen+ when it is only on Lumen+ in Canada is worse
  than telling you nothing at all` is an `info` row on the page rather than a
  tooltip, for the same reason.

  ## This screen owns the prices, and says so

  Screen 23 lists the same services with a cost per watched hour. The `info`
  row under the subscribed group prints the ownership out loud — *this screen
  owns these prices; 23 reads them — edit here, and cost per watched hour
  follows* — so nobody has to work out which page to edit.

  ## Every rule carries its consequence in words

  `Hide titles I can't watch` silently empties three other screens, so its own
  sub-line names them: Discover, Up next and What fits tonight. And it names
  what it does **not** touch, because "hide" beside a library is a frightening
  word.

  ## The Money row quotes screen 23 rather than summing this page

  See `Kati.Services.Sample.monthly_total/0`. The two figures differ and the
  difference is real.
  """

  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.Services
  alias Kati.Services.Sample
  alias Kati.Services.Service
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  # Each rule with the sentence that says what it does. The sentence is not
  # optional copy — see the moduledoc.
  @rules [
    {:rentals, "Count rentals as available",
     "A film you would have to rent still shows up in What fits tonight."},
    {:purchases, "Count purchases as available",
     "Titles you would have to buy outright are included too."},
    {:hide_unavailable, "Hide titles I can’t watch",
     "Removes them from Discover, Up next and What fits tonight. Your library and wishlist keep everything."}
  ]

  def load(socket) do
    socket
    |> Mob.Socket.assign(:region, Services.region())
    |> Mob.Socket.assign(:rules, Services.rules())
  end

  @doc "The services you pay for: what is stored, or the drawing's three."
  @spec subscribed() :: [map()]
  def subscribed do
    case stored(:subscribed) do
      [] -> Sample.subscribed()
      services -> Enum.map(services, &shape/1)
    end
  end

  @doc "The ones that cost nothing: what is stored, or the drawing's two."
  @spec free() :: [map()]
  def free do
    case stored(:free_with_ads) do
      [] -> Sample.free()
      services -> Enum.map(services, &shape/1)
    end
  end

  @doc "The drawing's values, unconditionally — the fixture, not a fallback path."
  @spec drawn() :: %{subscribed: [map()], free: [map()]}
  def drawn, do: %{subscribed: Sample.subscribed(), free: Sample.free()}

  @doc "What this screen would show, for the empty-database gate."
  @spec listed() :: %{subscribed: [map()], free: [map()]}
  def listed, do: %{subscribed: subscribed(), free: free()}

  defp stored(tier) do
    Service
    |> Ash.Query.for_read(:listed)
    |> Ash.read()
    |> case do
      {:ok, services} -> Enum.filter(services, &(&1.tier == tier))
      _other -> []
    end
  rescue
    _error -> []
  end

  defp shape(%Service{} = service) do
    %{
      badge: Service.badge(service),
      name: service.name,
      price: Service.price(service),
      pence: service.monthly_pence
    }
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
        {SettingsList.chrome(nil, 44)}
        {SettingsList.title("My services", "So Kati only shows you what you can actually watch.")}
        {UI.eyebrow("Region")}
        {Kati.Screens.MyServices.region_group(assigns.region)}
        {Kati.Screens.MyServices.search_field()}
        {UI.eyebrow(Kati.Screens.MyServices.subscribed_label())}
        {Kati.Screens.MyServices.service_group(Kati.Screens.MyServices.subscribed(), true)}
        {UI.eyebrow("Free with ads")}
        {Kati.Screens.MyServices.service_group(Kati.Screens.MyServices.free(), false)}
        {Kati.Screens.MyServices.catalogue_group()}
        {UI.eyebrow("Rules")}
        {Kati.Screens.MyServices.rules_group(assigns.rules)}
        {UI.eyebrow("Money")}
        {Kati.Screens.MyServices.money_group()}
        {Kati.Screens.MyServices.credit()}
      </Column>
    </Scroll>
    """
  end

  @doc "The country row, and the sentence that says why it is first."
  @spec region_group(String.t()) :: map()
  def region_group(code) do
    assigns = %{flag: Services.flag(code), name: Services.region_name(code)}

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card([
        Kati.UI.SettingsList.row(
          Kati.Screens.MyServices.flag_tile(@flag),
          Kati.UI.SettingsList.body(@name, "Decides what “available” means"),
          Kati.UI.SettingsList.trailing(Kati.UI.SettingsList.chevron()),
          on_tap: {self(), :pick_country}
        )
      ])}
      <Spacer size={10} />
      {Kati.UI.SettingsList.note("info", "Availability is per country. Telling you a film is on Lumen+ when it is only on Lumen+ in Canada is worse than telling you nothing at all.")}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  The flag, in a plain tile.

  A `Text` and not a symbol: a flag is an emoji pair rather than a Material
  Symbol, and it comes out of the system emoji font. That is why it is sized
  rather than coloured — a coloured emoji is not a thing.
  """
  @spec flag_tile(String.t()) :: map()
  def flag_tile(flag) do
    assigns = %{flag: flag}

    ~MOB"""
    <Box width={40} height={40} corner_radius={12} background={Palette.paper()} align="center">
      <Text text={@flag} text_size={20} text_align="center" />
    </Box>
    """
  end

  @doc "The search field, which filters the list rather than opening a screen."
  @spec search_field() :: map()
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
          text="Search services"
          text_size={14}
          text_color={Palette.tertiary()}
          weight={1.0}
          max_lines={1}
        />
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc "The subscribed eyebrow, carrying the count of what is actually listed."
  @spec subscribed_label() :: String.t()
  def subscribed_label, do: "Subscribed · #{length(Kati.Screens.MyServices.subscribed())}"

  @doc """
  A group of services, with prices where they have them.

  The subscribed group takes the ownership `info` row under it; the free group
  does not, because nothing on it has a price to own.
  """
  @spec service_group([map()], boolean()) :: map()
  def service_group(services, owner_note?) do
    rows = Enum.map(services, &Kati.Screens.MyServices.service_row/1)

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card(rows)}
      {Kati.Screens.MyServices.ownership_note(owner_note?)}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def service_row(service) do
    SettingsList.row(
      Kati.Screens.MyServices.badge_tile(service.badge),
      SettingsList.body(service.name, nil),
      SettingsList.trailing(Kati.Screens.MyServices.price(service.price)),
      on_tap: {self(), :edit_service}
    )
  end

  @doc false
  def badge_tile(badge) do
    assigns = %{badge: badge}

    ~MOB"""
    <Box width={40} height={40} corner_radius={12} background={Palette.paper()} align="center">
      <Text
        text={@badge}
        text_size={15}
        font_weight="bold"
        text_align="center"
        text_color={Palette.ink_soft()}
      />
    </Box>
    """
  end

  @doc false
  def price(nil), do: nil

  def price(text) do
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

  @doc false
  def ownership_note(false), do: []

  def ownership_note(true) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={10} />
      {Kati.UI.SettingsList.note("info", "This screen owns these prices. 23 reads them — edit here, and cost per watched hour follows.")}
    </Column>
    """
  end

  @doc """
  The two rows that reach beyond the account: everything JustWatch lists, and
  a service Kati has never heard of.

  The second one states its own limit — *Kati will remember it for your
  subscription total, but cannot tell you what is on it* — because a service
  with no catalogue behind it cannot answer the question this page exists for,
  and a row that took the name and stayed quiet about that would be a promise
  it could not keep.
  """
  @spec catalogue_group() :: map()
  def catalogue_group do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.eyebrow_muted("Not mine")}
      {Kati.UI.SettingsList.card([
        Kati.UI.SettingsList.row(
          Kati.UI.SettingsList.icon_tile("more_horiz"),
          Kati.UI.SettingsList.body(Kati.Services.Sample.catalogue_count(), "Everything JustWatch lists for the UK"),
          Kati.UI.SettingsList.trailing(Kati.UI.SettingsList.chevron()),
          on_tap: {self(), :show_all}
        ),
        Kati.UI.SettingsList.row(
          Kati.UI.SettingsList.icon_tile("add"),
          Kati.UI.SettingsList.body("Something else", "Kati will remember it for your subscription total, but cannot tell you what is on it", lines: 3),
          Kati.UI.SettingsList.trailing(nil),
          on_tap: {self(), :add_service}
        )
      ])}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc "The three rules, each with its consequence written under it."
  @spec rules_group(map()) :: map()
  def rules_group(rules) do
    rows =
      Enum.map(@rules, fn {key, title, why} ->
        SettingsList.row(
          nil,
          SettingsList.body(title, why, lines: 3),
          SettingsList.trailing(SettingsList.switch(Map.fetch!(rules, key))),
          on_tap: {self(), String.to_atom("rule_#{key}")}
        )
      end)

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card(rows)}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc "The link into screen 23, quoting screen 23's own figure."
  @spec money_group() :: map()
  def money_group do
    count = length(Kati.Screens.MyServices.subscribed())

    assigns = %{
      line: "#{count} #{if count == 1, do: "service", else: "services"}",
      total: String.upcase(Sample.monthly_total() <> " a month")
    }

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card([
        Kati.UI.SettingsList.row(
          Kati.UI.SettingsList.icon_tile("payments"),
          Kati.UI.SettingsList.body("Subscriptions", @line),
          Kati.UI.SettingsList.trailing(Kati.Screens.MyServices.total_trailing(@total)),
          on_tap: {self(), :open_subscriptions}
        )
      ])}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def total_trailing(total) do
    assigns = %{total: total}

    ~MOB"""
    <Row align="center">
      <Text
        text={@total}
        font_family="mono"
        text_size={11}
        letter_spacing={0.1}
        text_color={Kati.Theme.Palette.sub()}
        max_lines={1}
      />
      <Spacer size={8} />
      {Kati.UI.SettingsList.chevron()}
    </Row>
    """
  end

  @doc "Where the availability data comes from, pointing at screen 83."
  @spec credit() :: map()
  def credit do
    SettingsList.note(
      "info",
      "Which service carries what comes from JustWatch, through TMDB. " <>
        "Both are credited on 83."
    )
  end

  @doc false
  def handle_tap(:pick_country, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.CountryPicker)}

  def handle_tap(:open_subscriptions, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Subscriptions)}

  def handle_tap(:show_all, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Subscriptions)}

  def handle_tap(:add_service, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Subscriptions)}

  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "rule_" <> rule ->
        key = String.to_existing_atom(rule)
        Services.toggle_rule(key)
        {:noreply, Mob.Socket.assign(socket, :rules, Services.rules())}

      _other ->
        {:noreply, socket}
    end
  end
end
