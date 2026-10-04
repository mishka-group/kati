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
  owns these prices; Subscriptions reads them — edit here, and cost per
  watched hour follows* — so nobody has to work out which page to edit. It
  names the page by its title: it said *23*, the page's number in the design,
  which no reader has ever been shown.

  ## Every rule carries its consequence in words

  `Hide titles I can't watch` silently empties three other screens, so its own
  sub-line names them: Discover, Up next and What fits tonight. And it names
  what it does **not** touch, because "hide" beside a library is a frightening
  word.

  ## The Money row adds up what is stored

  See `monthly_total/0`: the stored prices through
  `Kati.Services.Service.total/1`, and a dash when nothing has a price.

  ## Adding a service is one card with two fields

  The card under the region is the only way in, and it takes any name:
  a service TMDB lists (Netflix, Mubi) or one it has never heard of (a local
  cinema club, a sports pass). Name, price a month, and whether it is paid or
  free with ads — `save_service/4` writes it, and tapping a listed service puts
  it back in the same card to correct or delete.

  It was one field doing two jobs, search and add, with the price typed after
  the name (`Netflix 10.99`) and the commit on a *Something else* row at the
  foot of the page. On the device that read as a search that found nothing, a
  button under it that said *Nothing to save yet* off the bottom of the screen,
  and — because every keystroke redrew the whole page — a keyboard that froze
  long enough for Android to offer to close the app.

  ## Typing does not redraw the page

  What the fields hold lives in `:draft_name` and `:draft_price`, which nothing
  renders. The fields draw `:field_name` and `:field_price` instead, which move
  only when the page itself fills or clears them (with `:field_epoch`, so the
  bridge takes the new value). A keystroke therefore changes no node, and Mob
  skips the repaint for an unchanged tree — see `handle_info/2`.

  A service typed in carries `provider_id: nil`. `Kati.Services.Service`
  reserves that for a service the user named, which Kati counts in the
  subscription total but cannot list titles for.
  """

  use Kati.Screens.Pushed, back: "Settings"
  use Gettext, backend: Kati.Gettext

  alias Kati.Services
  alias Kati.Services.Sample
  alias Kati.Services.Service
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList
  alias Kati.Write

  # Each rule with the sentence that says what it does. The sentence is not
  # optional copy — see the moduledoc.
  # A function, not a module attribute: `gettext/1` in an attribute is
  # evaluated once at COMPILE time, so the locale of whoever ran `mix compile`
  # would be the locale every reader got. See `Kati.Screens.Attribution`.
  @doc false
  @spec rules() :: [{atom(), String.t(), String.t()}]
  def rules do
    [
      {:rentals, gettext("Count rentals as available"),
       gettext("A film you would have to rent still shows up in What fits tonight.")},
      {:purchases, gettext("Count purchases as available"),
       gettext("Titles you would have to buy outright are included too.")},
      # Board 310: three, counted from the filter and not from memory. The
      # sentence had been cut to two because screen 13 read a fixture and a
      # switch that claimed to filter it would have been the promise this rule
      # was reported for. `Kati.Screens.WhatFits.watchable/1` closed that, so the
      # board's own sentence goes back — 310 counts the pages the filter reaches
      # (11 Discover, 10 Up next, 13 What fits tonight) and finds three.
      {:hide_unavailable, gettext("Hide titles I can’t watch"),
       gettext(
         "Removes them from Discover, Up next and What fits tonight. Your library and wishlist keep everything."
       )}
    ]
  end

  @impl true
  def load(socket) do
    socket
    |> Mob.Socket.assign(:region, Services.region())
    # Both, because they answer two questions and this page hands one of them
    # on. `:region` is the country the page is answering FOR — `"GB"` until
    # somebody says otherwise — and `:chosen_region` is whether anybody has,
    # which is what board 93 asks when it draws *Pick your country*.
    |> Mob.Socket.assign(:chosen_region, Services.chosen_region())
    |> Mob.Socket.assign(:rules, Services.rules())
    |> Mob.Socket.assign(:services, Kati.Screens.MyServices.listed())
    |> Mob.Socket.assign(:suggestions, Kati.Screens.MyServices.suggestions())
    |> Mob.Socket.assign(:not_mine, Kati.Screens.MyServices.not_mine())
    |> Kati.Screens.MyServices.reset_card()
  end

  @doc """
  The add card, empty: no draft, no notice, a paid service, adding not editing.

  The epoch moves so a field the bridge has already drawn takes the empty
  value rather than keeping what was typed.
  """
  @spec reset_card(Mob.Socket.t()) :: Mob.Socket.t()
  def reset_card(socket) do
    socket
    |> Kati.Screens.MyServices.fill_card("", "")
    |> Mob.Socket.assign(:kind, :subscribed)
    |> Mob.Socket.assign(:editing, nil)
    |> Mob.Socket.assign(:notice, nil)
  end

  @doc false
  @spec fill_card(Mob.Socket.t(), String.t(), String.t()) :: Mob.Socket.t()
  def fill_card(socket, name, price) do
    socket
    |> Mob.Socket.assign(:draft_name, name)
    |> Mob.Socket.assign(:draft_price, price)
    |> Mob.Socket.assign(:field_name, name)
    |> Mob.Socket.assign(:field_price, price)
    |> Mob.Socket.assign(:field_epoch, Map.get(socket.assigns, :field_epoch, 0) + 1)
  end

  @doc """
  The services your own titles are on, in your region, that you have not told
  Kati about yet (#127): `[{name, titles}]`, most titles first.

  The list a reader picks from, instead of having to know and type every
  service's name. It is read from the providers TMDB reported for the titles
  on the shelf, so it is real for this reader and this country, and it grows
  as the shelf does.
  """
  @spec suggestions() :: [{String.t(), pos_integer()}]
  def suggestions do
    region = Services.region()
    listed = MapSet.new(all_stored(), &String.downcase(String.trim(&1.name)))

    Kati.Media.TrackedTitle
    |> Ash.read!()
    |> Enum.reject(& &1.archived)
    |> Enum.map(&Kati.Media.Release.cached_for/1)
    |> Enum.reject(&is_nil/1)
    |> Kati.Media.Availability.suggestions(region)
    |> Enum.reject(fn {name, _n} -> MapSet.member?(listed, String.downcase(name)) end)
    |> Enum.take(12)
  rescue
    _error -> []
  end

  @doc "The services marked *not mine*, so they can be added back (#127)."
  @spec not_mine() :: [map()]
  def not_mine, do: stored(:not_mine) |> Enum.map(&shape/1)

  @doc """
  Coming back from the country picker, or from anything else pushed over this.

  See `Kati.Screens.Resume`. Screen 94 writes the region and pops, and this
  page's region row is drawn from `assigns.region` — read once at mount — so
  picking a country left the row saying the old one. It is
  the same defect the shelf had one screen along.

  The reads only. What is in the add card is the reader's, and coming back
  from the picker is no reason to empty it.
  """
  @impl true
  def handle_kati(:resumed, _payload, socket) do
    {:noreply,
     socket
     |> Mob.Socket.assign(:region, Services.region())
     |> Mob.Socket.assign(:chosen_region, Services.chosen_region())
     |> Mob.Socket.assign(:rules, Services.rules())
     |> Mob.Socket.assign(:services, Kati.Screens.MyServices.listed())
     |> Mob.Socket.assign(:suggestions, Kati.Screens.MyServices.suggestions())
     |> Mob.Socket.assign(:not_mine, Kati.Screens.MyServices.not_mine())}
  end

  @doc """
  The services you pay for: what is stored, or the drawing's three.

  Gated on the WHOLE page rather than on this group. The two groups fell back
  independently, so adding one service produced a page
  that was half the reader's and half the drawing's: their one service under
  Subscribed, and Aria Free and Dispatch still under Free.
  """
  @spec subscribed() :: [map()]
  def subscribed, do: stored(:subscribed) |> Enum.map(&shape/1)

  @doc """
  The ones that cost nothing: what is stored, and nothing when nothing is.

  Neither group falls back to `Kati.Services.Sample` any more.
  A phone that had been told nothing was shown Lumen+
  £8.99, Orbit £13.99, Kino £11.49, *Subscribed · 3* and `£46.47 A MONTH` —
  one tap after Home had said *No subscriptions yet*.
  """
  @spec free() :: [map()]
  def free, do: stored(:free_with_ads) |> Enum.map(&shape/1)

  @doc """
  Whether this reader has told Kati about any service at all.

  One gate for the page. Home's own row already asks this question — it reads
  `Kati.Services.subscribed_count/0` and says *No subscriptions yet* — and 92
  answered the opposite one tap later, listing Lumen+ £8.99, Orbit £13.99, Kino
  £11.49 and `£46.47 A MONTH`. Two screens, opposite answers, one tap apart.

  Both tiers, because a reader who has added only a free service has still set
  the page up and should not be shown three subscriptions they do not pay for.
  """
  @spec set_up?() :: boolean()
  def set_up?, do: all_stored() != []

  defp all_stored do
    Service
    |> Ash.Query.for_read(:listed)
    |> Ash.read!()
  rescue
    _error -> []
  end

  @doc """
  The drawing's values, unconditionally — the fixture, not a fallback path.

  Nothing on this page reads it. Its callers are the two reference boards
  that draw 92's services as a specimen, `Kati.Screens.MyServicesStates` and
  `Kati.Screens.MyServicesEmpty`'s free group, both reached only from
  `Kati.Screens.Gallery`; board 92's own set-up arrival is
  `Kati.Test.DrawnBoards.services_page/0`, a test fixture.
  """
  @spec drawn() :: map()
  def drawn, do: page(Sample.subscribed(), Sample.free(), false, Sample.monthly_total())

  @doc """
  Everything this page draws that comes from anywhere but the markup, as one
  map — which is what the page renders FROM.

  Read once, in `load/1`, and put on `:services`. It was six separate function
  calls inside `content/1`, and that is what the audit's shape note
  is about: `Kati.ScreenDesignLiteralTest.drawn_state/0` can put a screen into
  the state its own board draws only by handing it assigns, and a screen that
  reads through function calls cannot be handed anything. So 92 could not be
  compared against board 93 on an empty device, and the disagreement between
  Home's *No subscriptions yet* and this page's three subscriptions stood as a
  passing test in `Kati.MyServicesGateTest` rather than as a fixed bug.

  `set_up?` rides along because every other value here is gated on it, and
  asking twice is how the halves come apart.
  """
  @spec listed() :: %{
          subscribed: [map()],
          free: [map()],
          set_up?: boolean(),
          money: {String.t(), String.t() | nil}
        }
  def listed, do: page(subscribed(), free(), set_up?(), monthly_total())

  # One shaper for both sides of `Kati.ScreenEmptyDatabaseTest`'s pair. The map
  # this page renders from and the map its drawing renders from have to be the
  # same SHAPE or the pair compares two different kinds of thing, and the
  # comparison stops meaning anything the day a key is added to one of them.
  defp page(subscribed, free, set_up?, total) do
    %{
      subscribed: subscribed,
      free: free,
      set_up?: set_up?,
      money: Kati.Screens.MyServices.money_line(subscribed, total)
    }
  end

  @doc """
  What the Money row says a month costs.

  It said `£46.47` — `Kati.Services.Sample.monthly_total/0` — beside a LIVE
  count, so a reader with one service was told *1 service · £46.47 A MONTH*.
  `Kati.Services.Service.total/1` adds the stored prices
  up; a set-up page whose services carry no price says `—` rather than
  borrowing the drawing's figure, because a total nobody entered is not a
  total.
  """
  @spec monthly_total() :: String.t()
  def monthly_total do
    # `"—"` and not `Kati.Services.Sample.monthly_total/0` on a device with no
    # services set up. The old else-branch billed a reader who had told Kati
    # about nothing, and `Kati.Screens.Stats` already handles the dash — board
    # 93's own argument for it: "a figure is an answer, and an answer of zero
    # invites you to act on it."
    Kati.Services.Service.total(stored(:subscribed)) || "—"
  end

  @doc """
  The Money row's second line, which is a count and a total or neither.

  `Nothing to add up yet` on a device with no services, which is board 93's own
  wording and its own argument: *a figure is an answer, and an answer of zero
  invites you to believe the account has been totalled and came to nothing;
  what is true is that nothing has been totalled.*
  """
  @spec money_line([map()], String.t()) :: {String.t(), String.t() | nil}
  def money_line([], _total), do: {gettext("Nothing to add up yet"), nil}

  def money_line(subscribed, total) do
    count = length(subscribed)

    {ngettext("%{n} service", "%{n} services", count, n: Kati.Locale.number(count)),
     Kati.UI.eyebrow_label(gettext("%{total} a month", total: total))}
  end

  defp stored(tier), do: Enum.filter(all_stored(), &(&1.tier == tier))

  defp shape(%Service{} = service) do
    %{
      # The row this row IS. Board 95 draws a switch on every service row and
      # 92 drew none, so nothing on this page could remove, rename or price
      # one — and a row that cannot name itself cannot
      # be the one that changes.
      id: service.id,
      badge: Service.badge(service),
      name: service.name,
      price: Service.price(service),
      pence: service.monthly_pence,
      # For the total over a NARROWED list — see `total_of/1`.
      currency: service.currency
    }
  end

  @doc false
  def content(assigns) do
    services = assigns[:services] || Kati.Screens.MyServices.listed()
    Kati.Screens.MyServices.page_for(assigns, services)
  end

  @doc """
  The page: what it is for, the country, the add card, then what you have.

  The add card sits above the lists so the keyboard never covers the button
  that commits what it typed, and so a notice about that button is drawn
  beside it rather than a scroll away.
  """
  @spec page_for(map(), map()) :: map()
  def page_for(assigns, services) do
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
        {Kati.Screens.MyServices.heading()}
        {UI.eyebrow(gettext("Region"))}
        {Kati.Screens.MyServices.region_group(assigns.region, Map.get(assigns, :chosen_region) != nil)}
        {UI.eyebrow(Kati.Screens.MyServices.card_label(Map.get(assigns, :editing)))}
        {Kati.Screens.MyServices.add_card(assigns)}
        {Kati.Screens.MyServices.suggestions_group(Map.get(assigns, :suggestions, []))}
        {UI.eyebrow(Kati.Screens.MyServices.subscribed_label(services))}
        {Kati.Screens.MyServices.service_group(services.subscribed, true)}
        {Kati.Screens.MyServices.free_band(services.free)}
        {Kati.Screens.MyServices.not_mine_group(Map.get(assigns, :not_mine, []))}
        {UI.eyebrow(gettext("Rules"))}
        {Kati.Screens.MyServices.rules_group(assigns.rules)}
        {UI.eyebrow(gettext("Money"))}
        {Kati.Screens.MyServices.money_group(services)}
        {Kati.Screens.MyServices.credit()}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The title, and the sentence that says what the page is for in full.

  `Kati.UI.SettingsList.title/4` gives a `:name` subtitle one line, which is
  right for a person's name and cut this sentence off at *What fits and U…*.
  """
  @spec heading() :: map()
  def heading do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.title_text(gettext("My services"))}
      <Spacer size={5} />
      <Text
        text={gettext("The streaming services you have. Kati uses them to show where you can watch each title, and adds up what you pay each month.")}
        text_size={13.5}
        line_height={Kati.Locale.leading(1.45)}
        text_color={Kati.UI.SettingsList.subtitle_ink()}
      />
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  The country row, and the sentence that says why it is first.

  `chosen?` is whether the reader has picked a country
  (`Kati.Services.chosen_region/0`). `Kati.Services.region/0` answers `"GB"`
  on a phone nobody has told anything, so every availability question has an
  answer; that is an assumption rather than the reader's country, and the row
  says so until a country is picked. See `region_sub/1`.
  """
  @spec region_group(String.t(), boolean()) :: map()
  def region_group(code, chosen? \\ true) do
    assigns = %{
      flag: Services.flag(code),
      name: Services.region_name(code),
      sub: Kati.Screens.MyServices.region_sub(chosen?)
    }

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card([
        Kati.UI.SettingsList.row(
          Kati.Screens.MyServices.flag_tile(@flag),
          Kati.UI.SettingsList.body(@name, @sub, lines: 2),
          Kati.UI.SettingsList.trailing(Kati.UI.SettingsList.chevron()),
          on_tap: {self(), :pick_country}
        )
      ])}
      <Spacer size={10} />
      {Kati.UI.SettingsList.note("info", gettext("Availability is per country: a title on a service in one country is often not on it in another, so Kati only uses the country you pick."))}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  The region row's sub-line: what a chosen country decides, or that the
  country shown is an assumption.

      iex> Kati.Screens.MyServices.region_sub(false)
      "Not picked yet — Kati assumes this until you choose"
  """
  @spec region_sub(boolean()) :: String.t()
  def region_sub(true), do: gettext("Decides what “available” means")
  def region_sub(false), do: gettext("Not picked yet — Kati assumes this until you choose")

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
  Board 93's search field, which is a picture of one.

  Screen 93 (`Kati.Screens.MyServicesEmpty`) is the board with nothing set up
  and draws this field without anywhere for a typed name to go, so it stays a
  drawing there. Screen 92 adds through `add_card/1` and has no search: the
  lists on it are short enough to read.
  """
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
          text={gettext("Search services")}
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

  @doc """
  The subscribed eyebrow, carrying the count of what is listed.

      iex> Kati.Screens.MyServices.subscribed_label(%{subscribed: []})
      "Subscribed · none yet"
  """
  @spec subscribed_label(map()) :: String.t()
  def subscribed_label(%{subscribed: []}), do: gettext("Subscribed · none yet")

  def subscribed_label(services),
    do:
      gettext("Subscribed · %{count}",
        count: Kati.Locale.number(length(services.subscribed))
      )

  @doc """
  The eyebrow over the add card, which is also the edit card.

      iex> Kati.Screens.MyServices.card_label(nil)
      "Add a service"

      iex> Kati.Screens.MyServices.card_label("an-id")
      "Edit service"
  """
  @spec card_label(String.t() | nil) :: String.t()
  def card_label(nil), do: gettext("Add a service")
  def card_label(_editing), do: gettext("Edit service")

  @doc """
  The add card: a name, whether it is paid or free, a price for a paid one,
  the button, and what the button just did.

  Any name is accepted. A service TMDB knows is matched to titles by name; one
  it does not know is still counted in the monthly total.
  """
  @spec add_card(map()) :: map()
  def add_card(assigns) do
    kind = Map.get(assigns, :kind, :subscribed)
    epoch = Map.get(assigns, :field_epoch, 0)

    assigns = %{
      name: Kati.Screens.MyServices.name_field(Map.get(assigns, :field_name, ""), epoch),
      chips: Kati.Screens.MyServices.kind_chips(kind),
      price: Kati.Screens.MyServices.price_field(kind, Map.get(assigns, :field_price, ""), epoch),
      buttons: Kati.Screens.MyServices.card_buttons(Map.get(assigns, :editing)),
      notice: Kati.Screens.MyServices.card_notice(Map.get(assigns, :notice))
    }

    ~MOB"""
    <Column fill_width={true}>
      {@name}
      <Spacer size={12} />
      {@chips}
      {@price}
      <Spacer size={16} />
      {@buttons}
      {@notice}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  One field, in the shape every field in the app takes: a white pill with the
  search shadow and a glyph before the text, as on Add title and the search
  bars.
  """
  @spec field_row(String.t(), map()) :: map()
  def field_row(icon, field) do
    assigns = %{icon: icon, field: field}

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
      {UI.symbol(@icon, size: 19, color: Palette.tertiary())}
      <Spacer size={11} />
      {@field}
    </Row>
    """
  end

  @doc false
  @spec name_field(String.t(), non_neg_integer()) :: map()
  def name_field(value, epoch) do
    assigns = %{value: value, epoch: epoch, on_change: {self(), :service_name}}

    Kati.Screens.MyServices.field_row("subscriptions", ~MOB"""
    <TextField
      value={@value}
      placeholder={gettext("Service name — Netflix, or any other")}
      return_key="next"
      weight={1.0}
      accessibility_id="service_name"
      on_change={@on_change}
      value_epoch={@epoch}
    />
    """)
  end

  @doc """
  The price, for a paid service only: a free one has nothing to add up.
  """
  @spec price_field(atom(), String.t(), non_neg_integer()) :: map()
  def price_field(:free_with_ads, _value, _epoch), do: ~MOB"<Spacer size={0} />"

  def price_field(_kind, value, epoch) do
    assigns = %{value: value, epoch: epoch, on_change: {self(), :service_price}}

    field =
      ~MOB"""
      <TextField
        value={@value}
        placeholder={gettext("Price a month, like 10.99 (optional)")}
        keyboard="decimal"
        return_key="done"
        weight={1.0}
        accessibility_id="service_price"
        on_change={@on_change}
        value_epoch={@epoch}
      />
      """

    assigns = %{row: Kati.Screens.MyServices.field_row("payments", field)}

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={12} />
      {@row}
    </Column>
    """
  end

  @doc false
  @spec kind_chips(atom()) :: map()
  def kind_chips(kind) do
    assigns = %{
      paid:
        Kati.Screens.MyServices.kind_chip(
          gettext("I pay for it"),
          :kind_paid,
          kind == :subscribed
        ),
      free:
        Kati.Screens.MyServices.kind_chip(
          gettext("Free with ads"),
          :kind_free,
          kind == :free_with_ads
        )
    }

    ~MOB"""
    <Row fill_width={true} align="center">
      {@paid}
      <Spacer size={8} />
      {@free}
    </Row>
    """
  end

  @doc false
  @spec kind_chip(String.t(), atom(), boolean()) :: map()
  def kind_chip(label, tag, chosen?) do
    Kati.Components.MishkaPill.pill(
      label: label,
      on_tap: {self(), tag},
      background: if(chosen?, do: Palette.ink_fill(), else: Palette.card()),
      shadow: if(chosen?, do: nil, else: Kati.Theme.shadow_search()),
      color: if(chosen?, do: Palette.on_ink(), else: :on_surface),
      corner_radius: 17,
      height: 34,
      padding: 0,
      padding_left: 14,
      padding_right: 14,
      text_size: 12.5,
      font_weight: :semibold,
      align: :center
    )
  end

  @doc """
  *Add service*, or *Save* with *Delete* and *Cancel* while a listed service
  is in the card.
  """
  @spec card_buttons(String.t() | nil) :: map()
  def card_buttons(nil) do
    assigns = %{add: Kati.Screens.MyServices.primary_button(gettext("Add service"), :add_service)}

    ~MOB"""
    <Row fill_width={true}>
      {@add}
    </Row>
    """
  end

  def card_buttons(_editing) do
    assigns = %{
      save: Kati.Screens.MyServices.primary_button(gettext("Save"), :add_service),
      delete:
        Kati.Screens.MyServices.quiet_button(gettext("Delete"), :delete_service, Palette.red()),
      cancel: Kati.Screens.MyServices.quiet_button(gettext("Cancel"), :cancel_edit, :on_surface)
    }

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true}>
        {@save}
      </Row>
      <Spacer size={10} />
      <Row fill_width={true} align="center">
        {@delete}
        <Spacer weight={1.0} />
        {@cancel}
      </Row>
    </Column>
    """
  end

  @doc false
  @spec quiet_button(String.t(), atom(), term()) :: map()
  def quiet_button(label, tag, color) do
    Kati.Components.MishkaPill.pill(
      label: label,
      on_tap: {self(), tag},
      background: Palette.card(),
      shadow: Kati.Theme.shadow_search(),
      color: color,
      height: 36,
      corner_radius: 18,
      padding: 0,
      padding_left: 16,
      padding_right: 16,
      text_size: 13,
      font_weight: :semibold,
      align: :center
    )
  end

  @doc false
  @spec primary_button(String.t(), atom()) :: map()
  def primary_button(label, tag) do
    Kati.Components.MishkaPill.pill(
      label: label,
      on_tap: {self(), tag},
      background: Palette.ink_fill(),
      color: Palette.on_ink(),
      fill_width: true,
      height: 44,
      corner_radius: 22,
      padding: 0,
      text_size: 14,
      font_weight: :bold,
      align: :center
    )
  end

  @doc """
  What the button just did, under it: red for a refusal, quiet for a success.
  A zero spacer when there is nothing to say.
  """
  @spec card_notice({:error | :ok, String.t()} | nil) :: map()
  def card_notice(nil), do: ~MOB"<Spacer size={0} />"

  def card_notice({level, message}) do
    assigns = %{
      message: message,
      color: if(level == :error, do: Palette.red(), else: Palette.sub())
    }

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={10} />
      <Text
        text={@message}
        text_size={13}
        line_height={Kati.Locale.leading(1.5)}
        text_color={@color}
        accessibility_id="service_notice"
      />
    </Column>
    """
  end

  @doc """
  The *Free with ads* band, or nothing at all.

  A heading over an empty section is an eyebrow over a hole — the rule screen
  14 arrived at when its bands started falling away one at a time. Board 92
  draws two free services and board 93 draws the same two, and neither is a
  service the reader has: `Kati.Services.Sample`'s Aria Free and Dispatch were
  what a device with nothing showed under this heading, which is a good part
  of the fallback defect in one band.
  """
  @spec free_band([map()]) :: map()
  def free_band([]), do: ~MOB"<Spacer size={0} />"

  def free_band(free) do
    assigns = %{group: Kati.Screens.MyServices.service_group(free, false)}

    ~MOB"""
    <Column fill_width={true}>
      {UI.eyebrow(gettext("Free with ads"))}
      {@group}
    </Column>
    """
  end

  @doc """
  A group of services, with prices where they have them.

  The subscribed group takes the ownership `info` row under it; the free group
  does not, because nothing on it has a price to own. An empty subscribed group
  is one line pointing at the card above it, not a card of its own.
  """
  @spec service_group([map()], boolean()) :: map()
  def service_group([], true) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.note("info", gettext("Nothing here yet. Add the services you pay for above."))}
      <Spacer size={24} />
    </Column>
    """
  end

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

  @doc """
  One service, with the control board 95 draws on it.

  Board 95 specifies the control: an on/off pill on every row. Off moves the
  service to `:not_mine`, so it leaves this page's two lists without being
  deleted — a service you cancelled is not a service you never had, and the
  *Not mine* group offers it back.

  The row's own tap puts the service in the add card (`edit_service/2`), where
  its name, price and kind can be corrected, or the service deleted.
  """
  @spec service_row(map()) :: map()
  def service_row(service) do
    SettingsList.row(
      Kati.Screens.MyServices.badge_tile(service.badge),
      SettingsList.body(service.name, nil),
      SettingsList.trailing(Kati.Screens.MyServices.row_trailing(service)),
      on_tap: {self(), Kati.Screens.MyServices.edit_tag(service)}
    )
  end

  @doc """
  A listed service's tap: put it in the card, keyed by id. The drawing's
  rows have no id and keep `service_tag/1`'s name tag.

      iex> Kati.Screens.MyServices.edit_tag(%{id: "abc", name: "Mubi"})
      :edit_service_abc
  """
  @spec edit_tag(map()) :: atom()
  def edit_tag(%{id: id}) when is_binary(id), do: String.to_atom("edit_service_" <> id)
  def edit_tag(service), do: Kati.Screens.MyServices.service_tag(service)

  @doc false
  def row_trailing(service) do
    assigns = %{
      price: Kati.Screens.MyServices.price(service.price),
      switch: Kati.Screens.MyServices.mine_switch(service)
    }

    ~MOB"""
    <Row align="center">
      {@price}
      <Spacer size={11} />
      {@switch}
    </Row>
    """
  end

  @doc """
  `Mine` / `Not mine`, per service — board 95's own 46x28 switch.

  Drawn only over a real row. A service with no id is the drawing's, and a
  switch that turned off a picture would be a control with nothing behind it.
  """
  @spec mine_switch(map()) :: map()
  def mine_switch(service) do
    Kati.Components.MishkaToggle.toggle(
      label: gettext("Mine"),
      pressed: true,
      on_change:
        if(Map.get(service, :id),
          do: {self(), Kati.Screens.MyServices.drop_tag(service)}
        ),
      color: Palette.ink_fill(),
      text_color: Palette.on_ink(),
      background: Palette.paper(),
      label_color: Palette.ink_soft(),
      corner_radius: 14,
      height: 28,
      padding: 0,
      padding_left: 12,
      padding_right: 12,
      border_width: 0,
      fill_width: false,
      align: :center,
      text_size: 11,
      font_weight: :semibold,
      max_lines: 1
    )
  end

  @doc """
  A service's *turn this off* tag, keyed by its id.

  By id and not by name, for `Kati.Screens.Library.poster_tag/1`'s reason one
  screen over: two services whose names differ only by a space collapse onto
  one `accessibility_id`, and `onNodeWithTag` throws on the second match.

      iex> Kati.Screens.MyServices.drop_tag(%{id: "abc"})
      :drop_service_abc
  """
  @spec drop_tag(map()) :: atom()
  def drop_tag(%{id: id}) when is_binary(id), do: String.to_atom("drop_service_" <> id)
  def drop_tag(_drawn), do: :drop_service

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
      font_family={Kati.Locale.mono_face()}
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
      {Kati.UI.SettingsList.note("info", gettext("This screen owns these prices. Subscriptions reads them — edit here, and cost per watched hour follows."))}
    </Column>
    """
  end

  @doc """
  The services you said are not yours, each with *Add back* — or nothing when
  there are none.
  """
  @spec not_mine_group([map()]) :: map() | []
  def not_mine_group([]), do: []

  def not_mine_group(not_mine) do
    rows = Enum.map(not_mine, &Kati.Screens.MyServices.not_mine_row/1)

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.eyebrow_muted(gettext("Not mine"))}
      {Kati.UI.SettingsList.card(rows)}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  The services on the reader's own titles, each with the two ways to have it
  (#127): *I pay* puts it under Subscribed, *Free* under Free with ads.
  Nothing at all when there is nothing to suggest.
  """
  def suggestions_group([]), do: []

  def suggestions_group(suggestions) do
    rows =
      suggestions
      |> Enum.with_index()
      |> Enum.map(fn {{name, n}, i} -> Kati.Screens.MyServices.suggestion_row(name, n, i) end)

    assigns = %{rows: rows}

    ~MOB"""
    <Column fill_width={true}>
      {UI.eyebrow(gettext("On your titles"))}
      {Kati.UI.SettingsList.card(@rows)}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def suggestion_row(name, n, index) do
    i = Integer.to_string(index)

    sub =
      ngettext("On %{n} of your titles", "On %{n} of your titles", n, n: Kati.Locale.number(n))

    Kati.UI.SettingsList.row(
      Kati.Screens.MyServices.badge_tile(String.first(name)),
      Kati.UI.SettingsList.body(name, sub),
      Kati.Screens.MyServices.suggestion_pills(i)
    )
  end

  @doc false
  def suggestion_pills(i) do
    assigns = %{i: i}

    ~MOB"""
    <Row align="center">
      {Kati.UI.SettingsList.action_pill(gettext("I pay"), {self(), String.to_atom("suggest_sub_" <> @i)})}
      <Spacer size={6} />
      {Kati.UI.SettingsList.action_pill(gettext("Free"), {self(), String.to_atom("suggest_free_" <> @i)})}
    </Row>
    """
  end

  @doc "A service marked not mine, with the way back (#127)."
  def not_mine_row(service) do
    Kati.UI.SettingsList.row(
      Kati.Screens.MyServices.badge_tile(service.badge),
      Kati.UI.SettingsList.body(service.name, gettext("You said this is not yours")),
      Kati.UI.SettingsList.action_pill(
        gettext("Add back"),
        {self(), String.to_atom("restore_service_" <> service.id)}
      )
    )
  end

  @doc """
  The three rules, each with its consequence written under it.

  Screen 93 draws this group too, and board 323 is why it is this one rather
  than a copy: *"93 is 92 with nothing configured — not a second screen with
  its own memory."* Same three rows, the same sentence board 310 counted, and
  the same persistence.

  The last row takes no hairline, which is what both drawings show and what
  93's own file had been doing alone.
  """
  @spec rules_group(map()) :: map()
  def rules_group(rules) do
    last = length(Kati.Screens.MyServices.rules()) - 1

    rows =
      Kati.Screens.MyServices.rules()
      |> Enum.with_index()
      |> Enum.map(fn {{key, title, why}, index} ->
        SettingsList.row(
          nil,
          # Three lines, not one: each of these sentences is the *reason* for a
          # switch, and a reason that ellipsises has been deleted.
          SettingsList.body(title, why, lines: 3),
          SettingsList.trailing(SettingsList.switch(Map.fetch!(rules, key))),
          on_tap: {self(), String.to_atom("rule_#{key}")},
          rule: index < last
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
  @spec money_group(map()) :: map()
  def money_group(services) do
    {line, total} = services.money

    assigns = %{line: line, total: total}

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card([
        Kati.UI.SettingsList.row(
          Kati.UI.SettingsList.icon_tile("payments"),
          Kati.UI.SettingsList.body(gettext("Subscriptions"), @line),
          Kati.UI.SettingsList.trailing(Kati.Screens.MyServices.total_trailing(@total)),
          on_tap: {self(), :open_subscriptions}
        )
      ])}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def total_trailing(nil), do: ~MOB"<Spacer size={0} />"

  def total_trailing(total) do
    assigns = %{total: total}

    # `Kati.Locale.tracking/1` rather than the flat `0.1`. This `Text` holds
    # `money_line/2`'s second element — `£46.47 A MONTH` in Latin and
    # `۴۶٫۴۷ £ در ماه` in Persian — so it is a node that can hold Arabic script,
    # and tracking pulls the joins apart between `د` and `ر`. Latin keeps the
    # design's tenth of a pixel.
    ~MOB"""
    <Row align="center">
      <Text
        text={@total}
        font_family={Kati.Locale.mono_face()}
        text_size={11}
        letter_spacing={Kati.Locale.tracking(0.1)}
        text_color={Kati.Theme.Palette.sub()}
        max_lines={1}
      />
      <Spacer size={8} />
      {Kati.UI.SettingsList.chevron()}
    </Row>
    """
  end

  @doc """
  Where the availability data comes from, pointing at the page that credits it.

  It said *credited on 83*, which is the page's number in the design and not a
  word a reader has ever seen: the page is *Where this comes from*, under
  Settings, and the note names it the way the Settings list does.
  """
  @spec credit() :: map()
  def credit do
    SettingsList.note(
      "info",
      gettext(
        "Which service carries what comes from JustWatch, through TMDB. Both are credited in Settings, under Where this comes from."
      )
    )
  end

  @doc false
  @impl true
  def handle_tap(:pick_country, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.CountryPicker)}

  def handle_tap(:open_subscriptions, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Subscriptions)}

  def handle_tap(:add_service, socket),
    do: {:noreply, Kati.Screens.MyServices.add_service(socket)}

  def handle_tap(:kind_paid, socket),
    do: {:noreply, Kati.Screens.MyServices.choose_kind(socket, :subscribed)}

  def handle_tap(:kind_free, socket),
    do: {:noreply, Kati.Screens.MyServices.choose_kind(socket, :free_with_ads)}

  def handle_tap(:cancel_edit, socket), do: {:noreply, Kati.Screens.MyServices.reset_card(socket)}

  def handle_tap(:delete_service, socket),
    do: {:noreply, Kati.Screens.MyServices.delete_service(socket)}

  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "suggest_sub_" <> i ->
        {:noreply, Kati.Screens.MyServices.add_suggestion(socket, i, :subscribed)}

      "suggest_free_" <> i ->
        {:noreply, Kati.Screens.MyServices.add_suggestion(socket, i, :free_with_ads)}

      "restore_service_" <> id ->
        {:noreply, Kati.Screens.MyServices.restore_service(socket, id)}

      "rule_" <> rule ->
        key = String.to_existing_atom(rule)
        Services.toggle_rule(key)
        {:noreply, Mob.Socket.assign(socket, :rules, Services.rules())}

      # Board 95's switch, off. `:not_mine` rather than a destroy: a service you
      # cancelled is not one you never had, and the *Not mine* group lists it
      # with a way back.
      "drop_service_" <> id ->
        {:noreply, Kati.Screens.MyServices.drop_service(socket, id)}

      "edit_service_" <> id ->
        {:noreply, Kati.Screens.MyServices.edit_service(socket, id)}

      _other ->
        {:noreply, socket}
    end
  end

  # What is typed is held and not drawn: `:draft_*` is read by the save and by
  # nothing in `render/1`, so a keystroke leaves the tree as it was and Mob
  # skips the repaint. A notice is dropped on the first keystroke after it —
  # that one change does redraw, once.
  @impl true
  def handle_info({:change, :service_name, typed}, socket) when is_binary(typed),
    do: {:noreply, socket |> Mob.Socket.assign(:draft_name, typed) |> clear_notice()}

  def handle_info({:change, :service_price, typed}, socket) when is_binary(typed),
    do: {:noreply, socket |> Mob.Socket.assign(:draft_price, typed) |> clear_notice()}

  # `super/2` for everything else, because the macro's `handle_info/2` clauses
  # are `defoverridable` and an override replaces the WHOLE set — dropping this
  # would take `:back` and every tap on the page with it.
  def handle_info(message, socket), do: super(message, socket)

  defp clear_notice(%{assigns: %{notice: nil}} = socket), do: socket
  defp clear_notice(socket), do: Mob.Socket.assign(socket, :notice, nil)

  @doc """
  Paid or free with ads. What is typed stays: the fields are refilled from the
  drafts, because switching to free hides the price field and switching back
  draws it again.
  """
  @spec choose_kind(Mob.Socket.t(), atom()) :: Mob.Socket.t()
  def choose_kind(socket, kind) do
    socket
    |> Kati.Screens.MyServices.fill_card(
      Map.get(socket.assigns, :draft_name, ""),
      Map.get(socket.assigns, :draft_price, "")
    )
    |> Mob.Socket.assign(:kind, kind)
    |> Mob.Socket.assign(:notice, nil)
  end

  @doc """
  Add what the card holds, or save the service being edited.

  A refusal keeps everything typed and says why under the button. A success
  clears the card and says what was added; the service appears in its list
  below.
  """
  @spec add_service(Mob.Socket.t()) :: Mob.Socket.t()
  def add_service(socket) do
    a = socket.assigns

    case Kati.Screens.MyServices.save_service(
           Map.get(a, :draft_name, ""),
           Map.get(a, :draft_price, ""),
           Map.get(a, :kind, :subscribed),
           Map.get(a, :editing)
         ) do
      {:ok, service} ->
        message =
          if Map.get(a, :editing),
            do: gettext("Saved %{name}.", name: service.name),
            else: gettext("Added %{name}.", name: service.name)

        socket
        |> Kati.Screens.MyServices.reread()
        |> Kati.Screens.MyServices.reset_card()
        |> Mob.Socket.assign(:notice, {:ok, message})

      {:error, reason} ->
        Mob.Socket.assign(socket, :notice, {:error, Kati.Screens.MyServices.refusal(reason)})
    end
  end

  @doc """
  The sentence for a save that did not land.

      iex> Kati.Screens.MyServices.refusal(:no_name)
      "Type the service’s name first."

      iex> Kati.Screens.MyServices.refusal(:bad_price)
      "The price has to be a number, like 10.99."
  """
  @spec refusal(term()) :: String.t()
  def refusal(:no_name), do: gettext("Type the service’s name first.")
  def refusal(:bad_price), do: gettext("The price has to be a number, like 10.99.")

  def refusal({:already_listed, name}),
    do: gettext("%{name} is already on your list. Tap it below to change it.", name: name)

  def refusal(reason), do: Write.message({:error, reason})

  @doc """
  Put a listed service into the card, to correct its name, price or kind, or to
  delete it.
  """
  @spec edit_service(Mob.Socket.t(), String.t()) :: Mob.Socket.t()
  def edit_service(socket, id) do
    case Ash.get(Service, id) do
      {:ok, service} ->
        socket
        |> Kati.Screens.MyServices.fill_card(
          service.name,
          Kati.Screens.MyServices.price_text(service)
        )
        |> Mob.Socket.assign(
          :kind,
          if(service.tier == :free_with_ads, do: :free_with_ads, else: :subscribed)
        )
        |> Mob.Socket.assign(:editing, service.id)
        |> Mob.Socket.assign(:notice, nil)

      _gone ->
        socket
    end
  end

  @doc """
  A stored price as the field shows it.

      iex> Kati.Screens.MyServices.price_text(%{monthly_pence: 1099})
      "10.99"

      iex> Kati.Screens.MyServices.price_text(%{monthly_pence: nil})
      ""
  """
  @spec price_text(map()) :: String.t()
  def price_text(%{monthly_pence: pence}) when is_integer(pence),
    do: :erlang.float_to_binary(pence / 100, decimals: 2)

  def price_text(_no_price), do: ""

  @doc "Delete the service being edited, for good, and empty the card."
  @spec delete_service(Mob.Socket.t()) :: Mob.Socket.t()
  def delete_service(socket) do
    with id when is_binary(id) <- Map.get(socket.assigns, :editing),
         {:ok, service} <- Ash.get(Service, id),
         {:ok, _deleted} <-
           service |> Ash.destroy(return_destroyed?: true) |> Write.note("delete service") do
      socket
      |> Kati.Screens.MyServices.reread()
      |> Kati.Screens.MyServices.reset_card()
      |> Mob.Socket.assign(:notice, {:ok, gettext("Deleted %{name}.", name: service.name)})
    else
      {:error, reason} ->
        Mob.Socket.assign(socket, :notice, {:error, Write.message({:error, reason})})

      _nothing ->
        Kati.Screens.MyServices.reset_card(socket)
    end
  end

  @doc """
  Turn a service off: `:not_mine`, and the page re-read.

  Not a destroy. The *Not mine* group lists it with *Add back*, so the row
  leaves the two lists above without leaving the store — a service you
  cancelled in March is a thing you had, and `Kati.Screens.Money` reads the
  history.
  """
  @spec drop_service(Mob.Socket.t(), String.t()) :: Mob.Socket.t()
  def drop_service(socket, id) do
    with {:ok, service} <- Ash.get(Service, id),
         {:ok, _updated} <-
           service |> Ash.Changeset.for_update(:update, %{tier: :not_mine}) |> Ash.update() do
      socket
      |> Kati.Screens.MyServices.reread()
      |> then(fn s ->
        if Map.get(s.assigns, :editing) == id, do: Kati.Screens.MyServices.reset_card(s), else: s
      end)
    else
      error -> Mob.Socket.assign(socket, :notice, {:error, Write.message(error)})
    end
  end

  @doc """
  The write behind the card.

  `editing` is the id of the service in the card, or `nil` to add one. A name
  already on the list is refused when adding — it would be a second row and a
  second charge in the total — unless it is under *Not mine*, which brings it
  back with what was typed. Any name is allowed: a service TMDB does not list is
  still a service you pay for.

      iex> Kati.Screens.MyServices.save_service("  ", "", :subscribed, nil)
      {:error, :no_name}

      iex> Kati.Screens.MyServices.save_service("Mubi", "abc", :subscribed, nil)
      {:error, :bad_price}
  """
  @spec save_service(String.t(), String.t(), atom(), String.t() | nil) ::
          {:ok, Service.t()} | {:error, term()}
  def save_service(name, price, kind, editing) do
    name = String.trim(name || "")

    result =
      with {:name, true} <- {:name, name != ""},
           {:ok, pence} <- Kati.Screens.MyServices.parse_price(price) do
        pence = if kind == :free_with_ads, do: nil, else: pence
        write(name, pence, kind, editing)
      else
        {:name, false} -> {:error, :no_name}
        {:error, _reason} = error -> error
      end

    Write.note(result, "save service #{name}")
  end

  defp write(name, pence, kind, nil) do
    case Kati.Screens.MyServices.already_listed(name) do
      %Service{tier: :not_mine} = service ->
        service
        |> Ash.Changeset.for_update(:update, %{tier: kind, monthly_pence: pence})
        |> Ash.update()

      %Service{name: listed} ->
        {:error, {:already_listed, listed}}

      nil ->
        Kati.Screens.MyServices.create_service(name, pence, kind)
    end
  end

  defp write(name, pence, kind, id) do
    clash = Kati.Screens.MyServices.already_listed(name)

    with {:clash, false} <- {:clash, clash != nil and clash.id != id},
         {:ok, service} <- Ash.get(Service, id) do
      service
      |> Ash.Changeset.for_update(:update, %{name: name, tier: kind, monthly_pence: pence})
      |> Ash.update()
    else
      {:clash, true} -> {:error, {:already_listed, clash.name}}
      {:error, _reason} = error -> error
    end
  end

  @doc """
  The price field as minor units, `nil` when it is empty.

  Persian and Arabic digits are read as well as Latin ones, a comma works as
  the decimal point, and a leading `£`, `$` or `€` is ignored.

      iex> Kati.Screens.MyServices.parse_price("")
      {:ok, nil}

      iex> Kati.Screens.MyServices.parse_price("10.99")
      {:ok, 1099}

      iex> Kati.Screens.MyServices.parse_price("£9")
      {:ok, 900}

      iex> Kati.Screens.MyServices.parse_price("۱۲٫۵")
      {:ok, 1250}

      iex> Kati.Screens.MyServices.parse_price("ten")
      {:error, :bad_price}
  """
  @spec parse_price(String.t() | nil) :: {:ok, non_neg_integer() | nil} | {:error, :bad_price}
  def parse_price(nil), do: {:ok, nil}

  def parse_price(text) do
    cleaned =
      text
      |> String.trim()
      |> Kati.Screens.MyServices.latin_digits()
      |> String.replace(["٫", ","], ".")
      |> String.trim_leading("£")
      |> String.trim_leading("$")
      |> String.trim_leading("€")
      |> String.trim()

    cond do
      cleaned == "" ->
        {:ok, nil}

      Regex.match?(~r/^\d+(\.\d{1,2})?$/, cleaned) ->
        {:ok, round(String.to_float(float_text(cleaned)) * 100)}

      true ->
        {:error, :bad_price}
    end
  end

  defp float_text(cleaned),
    do: if(String.contains?(cleaned, "."), do: cleaned, else: cleaned <> ".0")

  @doc """
  Persian and Arabic-Indic digits as Latin ones; everything else as it was.

      iex> Kati.Screens.MyServices.latin_digits("۱۲٫۵ ١٠")
      "12٫5 10"
  """
  @spec latin_digits(String.t()) :: String.t()
  def latin_digits(text) do
    for g <- String.graphemes(text), into: "" do
      Kati.Screens.MyServices.digit_value(g) || g
    end
  end

  @doc false
  @spec digit_value(String.t()) :: String.t() | nil
  def digit_value(g) do
    index =
      Enum.find_index(~w(۰ ۱ ۲ ۳ ۴ ۵ ۶ ۷ ۸ ۹), &(&1 == g)) ||
        Enum.find_index(~w(٠ ١ ٢ ٣ ٤ ٥ ٦ ٧ ٨ ٩), &(&1 == g))

    index && Integer.to_string(index)
  end

  def create_service(name, pence \\ nil, tier \\ :subscribed) do
    Ash.create(Service, %{
      name: name,
      tier: tier,
      provider_id: nil,
      monthly_pence: pence
    })
  end

  @doc """
  Add a suggested service under `tier`, by its exact provider name, so it
  matches what TMDB says the titles are on (#127).
  """
  @spec add_suggestion(Mob.Socket.t(), String.t(), atom()) :: Mob.Socket.t()
  def add_suggestion(socket, index, tier) do
    with {i, ""} <- Integer.parse(index),
         {name, _n} <- Enum.at(socket.assigns.suggestions, i),
         {:ok, _service} <-
           name
           |> Kati.Screens.MyServices.create_service(nil, tier)
           |> Write.note("add service #{name}") do
      Kati.Screens.MyServices.reread(socket)
    else
      {:error, reason} ->
        Mob.Socket.assign(socket, :notice, {:error, Write.message({:error, reason})})

      _no_suggestion ->
        socket
    end
  end

  @doc "Put a *not mine* service back under Subscribed (#127)."
  @spec restore_service(Mob.Socket.t(), String.t()) :: Mob.Socket.t()
  def restore_service(socket, id) do
    with {:ok, service} <- Ash.get(Service, id),
         {:ok, _restored} <-
           service |> Ash.update(%{tier: :subscribed}) |> Write.note("restore service") do
      Kati.Screens.MyServices.reread(socket)
    else
      {:error, reason} ->
        Mob.Socket.assign(socket, :notice, {:error, Write.message({:error, reason})})
    end
  end

  @doc false
  def reread(socket) do
    socket
    |> Mob.Socket.assign(:services, Kati.Screens.MyServices.listed())
    |> Mob.Socket.assign(:suggestions, Kati.Screens.MyServices.suggestions())
    |> Mob.Socket.assign(:not_mine, Kati.Screens.MyServices.not_mine())
  end

  @doc """
  The stored service of that name, or `nil` — case- and space-insensitively.

  Case-insensitively because `mubi` typed into the add card is the `Mubi`
  already listed, and taking it as a new name would put both spellings on the
  list and charge for both in the total.
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
