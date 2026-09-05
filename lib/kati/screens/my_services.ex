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

  ## `Something else` is the only create path drawn for a service

  `Kati.Services.Service` has had full CRUD since it was written and nothing in
  `lib/` created one, so every service on this page was the drawing's. The door
  the design draws is band 9 of ticket `D-10` — *an escape-hatch row for a
  service TMDB does not list* — and it is on 92.html as an `add` tile reading
  *Something else · Kati will remember it for your subscription total, but
  cannot tell you what is on it*.

  What the row adds is what the search field above it holds, and that pairing is
  the design's rather than this module's. Screen 95 draws this very field with
  `mubi plus` typed into it and answers: *No service called that. Kati uses
  JustWatch's list through TMDB. If it is a real service they do not track, add
  it as Something else.* So the field names the service and the row commits it,
  which is why `search_field/1` became a `<TextField>` on this screen and stayed
  a drawing on 93 — see both.

  The row writes `tier: :subscribed` and `provider_id: nil`. Neither is a
  choice this module made: `Kati.Services.Service`'s own comment reserves a nil
  `provider_id` for *"one the user typed under `Something else`"*, and only
  `:subscribed` is counted by `Kati.Services.Service.total/1`, which is the
  *subscription total* the row's sub-line promises to remember it for.

  It carries **no price**, and that is the honest half of the promise rather
  than an omission. Band 6 of the ticket asks for an editable monthly price and
  no artboard anywhere draws the editor — `Kati.ScreenTapSweepTest` records the
  same absence against `:edit_service` — so a service typed in here appears in
  the Subscribed group with its name and a blank right-hand column, which is
  exactly what `service_row/1` already draws for a service with no
  `monthly_pence`. It takes a figure the day a price field is drawn.
  """

  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.Services
  alias Kati.Services.Sample
  alias Kati.Services.Service
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList
  alias Kati.Write

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

  # `:query` and `:save_error` open empty and nil, so the resting page is the
  # drawing to the pixel: an unfilled field showing its placeholder, and no
  # notice under the catalogue card.
  def load(socket) do
    socket
    |> Mob.Socket.assign(:region, Services.region())
    |> Mob.Socket.assign(:rules, Services.rules())
    |> Mob.Socket.assign(:query, "")
    |> Mob.Socket.assign(:save_error, nil)
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
    query = assigns[:query] || ""
    save_error = assigns[:save_error]

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
        {SettingsList.title("My services", "So Kati only shows you what you can actually watch.", nil, :name)}
        {UI.eyebrow("Region")}
        {Kati.Screens.MyServices.region_group(assigns.region)}
        {Kati.Screens.MyServices.search_field(query)}
        {UI.eyebrow(Kati.Screens.MyServices.subscribed_label())}
        {Kati.Screens.MyServices.service_group(Kati.Screens.MyServices.subscribed(), true)}
        {UI.eyebrow("Free with ads")}
        {Kati.Screens.MyServices.service_group(Kati.Screens.MyServices.free(), false)}
        {Kati.Screens.MyServices.catalogue_group(save_error)}
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

  @doc """
  The search field, which stays on this screen rather than opening one.

  ## Two clauses, and 93 keeps the first

  `search_field/0` is the drawing: a `<Text>` reading `Search services` beside
  the glyph, which is a picture of a field. Nine screens carry a comment saying
  Mob has no text input; `Kati.Screens.AddTitle.field/1` records that it does
  and always did, and that the belief cost more than the feature.

  `search_field/1` is the field, and it exists because of what the search is
  *for* here. Screen 95 draws it mid-query — `mubi plus` typed, the list gone —
  and answers *No service called that. Kati uses JustWatch's list through TMDB.
  If it is a real service they do not track, add it as Something else.* That
  sentence points the field at `catalogue_group/1`'s escape hatch, and the hatch
  cannot add a service without a name to add it under.

  Screen 93 stays on the drawn clause deliberately. It is the board with
  nothing set up, and 93.html draws no `Something else` row at all — so a field
  you could type into there would take a name and have nowhere to put it, which
  is a worse field than one that is honestly a picture.

  The `on_tap` stays on the row in both. It is the drawn hit area, and on the
  typing clause it is what a tap on the glyph or the padding lands on rather
  than on the field itself.
  """
  @spec search_field(String.t() | nil) :: map()
  def search_field(query \\ nil)

  def search_field(nil) do
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

  def search_field(query) when is_binary(query) do
    assigns = %{query: query, on_change: {self(), :service_query}}

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
          placeholder="Search services"
          return_key="search"
          weight={1.0}
          accessibility_id="service_query"
          on_change={@on_change}
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

  @doc """
  One service row's tag, built from the service's name.

  Every row of both cards shared `:edit_service`, so five rows carried one
  `accessibility_id` and `onNodeWithTag` throws on the second match (#97).

  The name, because it is what the row is: `Kati.Services.Sample`'s five are
  distinct, and `Kati.Services.Service`'s `:listed` read is a list of named
  services rather than a set of anonymous rows. A service with no name keeps
  the bare tag rather than being given one that means nothing.

  This function serves screen 93 as well as 92 — `Kati.Screens.MyServicesEmpty`
  draws its rows through this same `service_row/1`, which is why both boards
  carried the collision and why one fix clears both.

      iex> Kati.Screens.MyServices.service_tag(%{name: "Aria Free"})
      :edit_service_Aria_Free

      iex> Kati.Screens.MyServices.service_tag(%{name: ""})
      :edit_service
  """
  @spec service_tag(map()) :: atom()
  def service_tag(service) do
    case service
         |> Map.get(:name, "")
         |> to_string()
         |> String.trim()
         |> String.replace(" ", "_") do
      "" -> :edit_service
      name -> String.to_atom("edit_service_" <> name)
    end
  end

  @doc false
  def service_row(service) do
    SettingsList.row(
      Kati.Screens.MyServices.badge_tile(service.badge),
      SettingsList.body(service.name, nil),
      SettingsList.trailing(Kati.Screens.MyServices.price(service.price)),
      on_tap: {self(), Kati.Screens.MyServices.service_tag(service)}
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
  @spec catalogue_group(String.t() | nil) :: map()
  def catalogue_group(save_error \\ nil) do
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
      {Kati.Screens.MyServices.save_notice(save_error)}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  What a refused `Something else` says, under the row that refused.

  Under the card rather than at the top of the page, because the control that
  failed is the one whose sub-line promised to remember the service — a notice
  a scroll away from it would be reporting on a row the reader cannot see.

  `nil` draws a zero `Spacer` rather than nothing, for `hairline/1`'s reason on
  screen 23: an absent notice must occupy the same slot as a present one so the
  resting tree is the tree this screen produced before the row could write.
  """
  @spec save_notice(String.t() | nil) :: map()
  def save_notice(nil), do: ~MOB"<Spacer size={0} />"

  def save_notice(message) do
    assigns = %{message: message}

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={10} />
      <Text text={@message} text_size={13} line_height={1.5} text_color={Palette.red()} />
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

  # `Show all 47` opens the whole JustWatch catalogue for the region, which is
  # what screen 93 draws when none of it is set up yet — the empty state IS the
  # catalogue with nothing chosen from it.
  def handle_tap(:show_all, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.MyServicesEmpty)}

  # `Something else` used to push screen 23, which is a read-only page about
  # money you already spend — the one place in the app that could not answer
  # "add a service Kati has never heard of". It writes now; see `add_service/1`.
  def handle_tap(:add_service, socket),
    do: {:noreply, Kati.Screens.MyServices.add_service(socket)}

  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "rule_" <> rule ->
        key = String.to_existing_atom(rule)
        Services.toggle_rule(key)
        {:noreply, Mob.Socket.assign(socket, :rules, Services.rules())}

      # Every service row, by its own name — see `service_tag/1`. It changes
      # nothing, exactly as the bare `:edit_service` changed nothing before it:
      # there is no edit sheet to push, and #97 is about being addressable
      # rather than about wiring a destination this board does not draw.
      "edit_service_" <> _name ->
        {:noreply, socket}

      _other ->
        {:noreply, socket}
    end
  end

  # The service search field. Held as typed, and the field is the only place
  # the name of a service Kati has never heard of can come from — see
  # `search_field/1` for the sentence on screen 95 that says so.
  #
  # Typing also drops the notice. `save_notice/1` reports on the FIELD as it was
  # when the row was tapped, and the commonest failure here is the empty one:
  # tap `Something else` with nothing typed, read *Nothing to save yet.*, then
  # type a name — and the red line sat there contradicting a field that now held
  # one. A notice about a state the screen has left is the same lie #85 is
  # about, pointed the other way: this one reports a failure that is over.
  # `Kati.Screens.QuickAddExpense`'s own change clause drops `:saved?` for the
  # mirror-image reason — an edited field has no receipt yet either.
  def handle_info({:change, :service_query, typed}, socket) when is_binary(typed) do
    {:noreply,
     socket
     |> Mob.Socket.assign(:query, typed)
     |> Mob.Socket.assign(:save_error, nil)}
  end

  # `super/2` for everything else, because the macro's `handle_info/2` clauses
  # are `defoverridable` and an override replaces the WHOLE set — dropping this
  # would take `:back` and every tap on the page with it.
  def handle_info(message, socket), do: super(message, socket)

  @doc """
  Add what the field holds, and say so when it does not land.

  The sheet-open rule of `Kati.Write` in the one shape a screen without a sheet
  can take it: a failure leaves the typed name **in the field** and puts
  `Kati.Write.message/1` under the row that refused, so nothing is lost and
  nothing looks finished. A success clears the field, which is the only receipt
  worth printing here — the service itself appears in the Subscribed group four
  rows up, under the name you typed, and the eyebrow's count follows it.

  The notice lasts until the next tap **or the next keystroke** — see
  `handle_info/2`'s `:service_query` clause. It is a sentence about what the
  field held, so it cannot outlive the field holding it.
  """
  @spec add_service(Mob.Socket.t()) :: Mob.Socket.t()
  def add_service(socket) do
    case Kati.Screens.MyServices.save_service(socket.assigns[:query]) do
      {:ok, _service} ->
        socket
        |> Mob.Socket.assign(:query, "")
        |> Mob.Socket.assign(:save_error, nil)

      {:error, _reason} = error ->
        Mob.Socket.assign(socket, :save_error, Write.message(error))
    end
  end

  @doc """
  The write. A service the user typed, in the tier the row's own copy promises.

  `:nothing_to_save` for an empty field rather than a row named `""`:
  `name` is `allow_nil?: false` but a string of spaces satisfies that, and
  `Kati.Write.message/1` already owns the sentence for a save with nothing in
  it — *Nothing to save yet.*

  A name already on the list answers `{:ok, existing}` and writes nothing.
  Nothing in `services` is unique, so a second `Mubi` would be a second row: two
  identical lines in the Subscribed group, a count of two, and — the day a price
  editor exists — a subscription total charging you twice for one service.
  `Kati.Screens.AddTitle.cache/1` reaches the same answer from the other
  direction, and its reasoning holds here: re-adding something you already have
  is the ordinary way somebody checks whether they already have it.

  The read behind that check does not rescue and neither does the write. A store
  this screen cannot reach answers `{:error, _}` at one end or the other, which
  is a failure the row reports rather than one it swallows — the whole of #85.
  """
  @spec save_service(String.t() | nil) :: {:ok, Service.t()} | {:error, term()}
  def save_service(name) when is_binary(name) do
    case String.trim(name) do
      "" ->
        Write.note({:error, :nothing_to_save}, "add service")

      typed ->
        case Kati.Screens.MyServices.already_listed(typed) do
          %Service{} = service ->
            Write.note({:ok, service}, "add service #{typed}")

          nil ->
            Kati.Screens.MyServices.create_service(typed) |> Write.note("add service #{typed}")
        end
    end
  end

  def save_service(_nothing), do: Write.note({:error, :nothing_to_save}, "add service")

  @doc """
  The row itself, spelled out rather than left to the resource's defaults.

  `tier` and `provider_id` both happen to be what `Kati.Services.Service`
  defaults to, and both are written here anyway: they are the two columns this
  screen's copy makes a promise about — *your subscription total*, which only
  `:subscribed` is counted for, and *cannot tell you what is on it*, which is
  what a nil `provider_id` means — and a promise resting on somebody else's
  default is a promise nobody would think to check before changing it.
  """
  @spec create_service(String.t()) :: {:ok, Service.t()} | {:error, term()}
  def create_service(name) do
    Ash.create(Service, %{name: name, tier: :subscribed, provider_id: nil})
  end

  @doc """
  The stored service of that name, or `nil` — case- and space-insensitively.

  Case-insensitively because the field is a search field: somebody typing
  `mubi` to look for `Mubi` and finding nothing has just been told by screen 95
  to add it as `Something else`, and taking them at their word there would put
  both spellings on the list.
  """
  @spec already_listed(String.t()) :: Service.t() | nil
  def already_listed(name) do
    folded = String.downcase(name)

    case Ash.read(Service) do
      {:ok, services} ->
        Enum.find(services, &(String.downcase(String.trim(&1.name)) == folded))

      _unreachable ->
        nil
    end
  end
end
