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
    # Board 310: three, counted from the filter and not from memory. The
    # sentence had been cut to two because screen 13 read a fixture and a
    # switch that claimed to filter it would have been the promise this rule
    # was reported for. `Kati.Screens.WhatFits.watchable/1` closed that, so the
    # board's own sentence goes back — 310 counts the pages the filter reaches
    # (11 Discover, 10 Up next, 13 What fits tonight) and finds three.
    {:hide_unavailable, "Hide titles I can’t watch",
     "Removes them from Discover, Up next and What fits tonight. " <>
       "Your library and wishlist keep everything."}
  ]

  # `:query` and `:save_error` open empty and nil, so the resting page is the
  # drawing to the pixel: an unfilled field showing its placeholder, and no
  # notice under the catalogue card.
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
    |> Mob.Socket.assign(:query, "")
    |> Mob.Socket.assign(:save_error, nil)
  end

  @doc """
  Coming back from the country picker, or from anything else pushed over this.

  See `Kati.Screens.Resume`. Screen 94 writes the region and pops, and this
  page's region row is drawn from `assigns.region` — read once at mount — so
  picking a country left the row saying the old one. MOVIES-AND-TV.md #36, and
  it is the same defect the shelf had one screen along.

  The two reads only. `query` is what the reader has typed into the filter and
  `save_error` is about the last thing they did, and neither is the picker's to
  clear.
  """
  @impl true
  def handle_kati(:resumed, _payload, socket) do
    {:noreply,
     socket
     |> Mob.Socket.assign(:region, Services.region())
     |> Mob.Socket.assign(:chosen_region, Services.chosen_region())
     |> Mob.Socket.assign(:rules, Services.rules())
     |> Mob.Socket.assign(:services, Kati.Screens.MyServices.listed())}
  end

  @doc """
  The services you pay for: what is stored, or the drawing's three.

  Gated on the WHOLE page rather than on this group. The two groups fell back
  independently, so adding one service through *Something else* produced a page
  that was half the reader's and half the drawing's: their one service under
  Subscribed, and Aria Free and Dispatch still under Free.
  MOVIES-AND-TV.md #76.
  """
  @spec subscribed() :: [map()]
  def subscribed, do: stored(:subscribed) |> Enum.map(&shape/1)

  @doc """
  The ones that cost nothing: what is stored, and nothing when nothing is.

  Neither group falls back to `Kati.Services.Sample` any more, which is
  MOVIES-AND-TV.md #75. A phone that had been told nothing was shown Lumen+
  £8.99, Orbit £13.99, Kino £11.49, *Subscribed · 3* and `£46.47 A MONTH` —
  one tap after Home had said *No subscriptions yet*. The drawing's values are
  still the drawing's: `Kati.ScreenDesignLiteralTest.drawn_state/0` installs
  them to compare board 92 against, which is the arrangement screens 01 and 03
  already have.
  """
  @spec free() :: [map()]
  def free, do: stored(:free_with_ads) |> Enum.map(&shape/1)

  @doc """
  Whether this reader has told Kati about any service at all.

  One gate for the page. Home's own row already asks this question — it reads
  `Kati.Services.subscribed_count/0` and says *No subscriptions yet* — and 92
  answered the opposite one tap later, listing Lumen+ £8.99, Orbit £13.99, Kino
  £11.49 and `£46.47 A MONTH`. Two screens, opposite answers, one tap apart.
  MOVIES-AND-TV.md #75.

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

  @doc "The drawing's values, unconditionally — the fixture, not a fallback path."
  @spec drawn() :: map()
  def drawn, do: page(Sample.subscribed(), Sample.free(), false, Sample.monthly_total())

  @doc """
  Board 92's own arrival: the drawing's services, on a page that IS set up.

  `drawn/0`'s `set_up?` is false because that is the question it answers — what
  a device with nothing stored reads back — and a device with nothing stored
  draws board 93 now. This is the other thing: the state board 92 was captured
  in, which is a reader with three subscriptions. Two maps, because they are
  answers to two questions, and collapsing them is how a board stops being
  compared against the page it is a drawing of.
  """
  @spec drawn_page() :: map()
  def drawn_page, do: page(Sample.subscribed(), Sample.free(), true, Sample.monthly_total())

  @doc """
  Everything this page draws that comes from anywhere but the markup, as one
  map — which is what the page renders FROM.

  Read once, in `load/1`, and put on `:services`. It was six separate function
  calls inside `content/1`, and that is what MOVIES-AND-TV.md #75's shape note
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
  MOVIES-AND-TV.md #76. `Kati.Services.Service.total/1` adds the stored prices
  up; a set-up page whose services carry no price says `—` rather than
  borrowing the drawing's figure, because a total nobody entered is not a
  total.
  """
  @spec monthly_total() :: String.t()
  def monthly_total do
    if set_up?(),
      do: Kati.Services.Service.total(stored(:subscribed)) || "—",
      else: Sample.monthly_total()
  end

  @doc """
  The Money row's second line, which is a count and a total or neither.

  `Nothing to add up yet` on a device with no services, which is board 93's own
  wording and its own argument: *a figure is an answer, and an answer of zero
  invites you to believe the account has been totalled and came to nothing;
  what is true is that nothing has been totalled.*
  """
  @spec money_line([map()], String.t()) :: {String.t(), String.t() | nil}
  def money_line([], _total), do: {"Nothing to add up yet", nil}

  def money_line(subscribed, total) do
    count = length(subscribed)

    {"#{count} #{if count == 1, do: "service", else: "services"}",
     String.upcase(total <> " a month")}
  end

  defp stored(tier), do: Enum.filter(all_stored(), &(&1.tier == tier))

  defp shape(%Service{} = service) do
    %{
      # The row this row IS. Board 95 draws a switch on every service row and
      # 92 drew none, so nothing on this page could remove, rename or price
      # one — MOVIES-AND-TV.md #119 — and a row that cannot name itself cannot
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
    query = assigns[:query] || ""
    save_error = assigns[:save_error]
    services = assigns[:services] || Kati.Screens.MyServices.listed()

    Kati.Screens.MyServices.page_for(
      assigns,
      Kati.Screens.MyServices.matching(services, query),
      query,
      save_error
    )
  end

  @doc """
  The page narrowed to what the field holds.

  MOVIES-AND-TV.md #118: the field typed and filtered nothing — `content/1`
  passed `query` to `search_field/1` and to no one else — so a reader searching
  a list of twelve services watched all twelve stay put.

  `subscribed_label/1` and the money line are recomputed from the narrowed
  lists on purpose. A count over a filtered list is what the filter is for; a
  count that stayed at the unfiltered number would be the eyebrow disagreeing
  with the rows under it, which is the same defect #75 fixed between Home and
  this page.

      iex> Kati.Screens.MyServices.matching(%{subscribed: [%{name: "Mubi"}], free: [], set_up?: true, money: nil}, "mu").subscribed
      [%{name: "Mubi"}]

      iex> Kati.Screens.MyServices.matching(%{subscribed: [%{name: "Mubi"}], free: [], set_up?: true, money: nil}, "netflix").subscribed
      []
  """
  @spec matching(map(), String.t()) :: map()
  def matching(services, query) do
    case Kati.Screens.MyServices.searched_name(query) do
      "" ->
        services

      typed ->
        subscribed = Kati.Screens.MyServices.named(services.subscribed, typed)
        free = Kati.Screens.MyServices.named(services.free, typed)

        %{
          services
          | subscribed: subscribed,
            free: free,
            money:
              Kati.Screens.MyServices.money_line(
                subscribed,
                Kati.Screens.MyServices.total_of(subscribed)
              )
        }
    end
  end

  @doc """
  The NAME half of what the field holds.

  One field does two jobs on this page — it searches, and it is where a service
  is typed with its price after it (`Netflix 10.99`). Tapping a row now puts
  that line back into it (#119), and on the device the two jobs collided at
  once: `Mubi 9.99` matched no service called *Mubi 9.99*, so the page emptied
  and said **No service called that** about the row the reader had just tapped.

  So the filter reads the name and ignores the price, which is right for both
  jobs: mid-edit you see the row you are editing, and mid-add you see whether
  the thing you are typing is already listed.

      iex> Kati.Screens.MyServices.searched_name("Mubi 9.99")
      "Mubi"

      iex> Kati.Screens.MyServices.searched_name("mubi plus")
      "mubi plus"
  """
  @spec searched_name(String.t()) :: String.t()
  def searched_name(query) do
    query |> Kati.Screens.MyServices.split_price() |> elem(0)
  end

  @doc false
  @spec named([map()], String.t()) :: [map()]
  def named(services, query) do
    needle = String.downcase(query)

    Enum.filter(services, &String.contains?(String.downcase(&1.name), needle))
  end

  @doc """
  What a narrowed list costs a month, in its own currency — or `"—"`.

  `Kati.Services.Service.total/1` answers this for the whole list and takes the
  structs; this takes the shaped rows the page is already holding, so the
  filtered total is computed from exactly the rows the filtered count counted.

      iex> Kati.Screens.MyServices.total_of([%{pence: 1099, currency: "GBP"}])
      "£10.99"

      iex> Kati.Screens.MyServices.total_of([%{pence: nil, currency: "GBP"}])
      "—"
  """
  @spec total_of([map()]) :: String.t()
  def total_of(services) do
    case Enum.reject(services, &is_nil(Map.get(&1, :pence))) do
      [] ->
        "—"

      priced ->
        Service.format(
          Enum.sum(Enum.map(priced, & &1.pence)),
          Map.get(hd(priced), :currency) || "GBP"
        )
    end
  end

  @doc """
  Board 95's own sentence, when the field names nothing on the page.

  *No service called that. Kati uses JustWatch's list through TMDB. If it is a
  real service they do not track, add it as Something else.* — the copy exists
  on 95 and nothing on 92 could produce it (#118). Drawn immediately above the
  `Something else` row it names, so the answer and the way out of it are one
  glance apart.

  Nothing at all when the field is empty, or when it matched: a card that said
  *no service called that* over a list of services would be worse than none.
  """
  @spec no_match(map(), String.t()) :: map()
  def no_match(services, query) do
    if Kati.Screens.MyServices.searched_name(query) != "" and services.subscribed == [] and
         services.free == [] do
      Kati.UI.SettingsList.note(
        "search",
        "No service called that. Kati uses JustWatch’s list through TMDB. " <>
          "If it is a real service they do not track, add it as Something else."
      )
    else
      ~MOB"<Spacer size={0} />"
    end
  end

  @doc """
  The page, in the one shape it has.

  It nearly had two. MOVIES-AND-TV.md #75's shape note says 92's empty state
  should be board 93 through `@empty_boards`, the way Home's is board 139, and
  the assigns half of that is done — this page renders from one map now, which
  is what made the swap expressible at all.

  The swap itself does not survive reading board 93. That board has **no way
  to add a service**: 92's *Something else* row, the app's only writer for a
  first service, is not on it, and its *Free with ads* group lists Aria Free
  and Dispatch — two fixture services a reader with nothing has not got. So a
  device sent there could see that it had nothing and could do nothing about
  it, which is worse than the disagreement being fixed.

  What 92's empty state should be — its own chrome over an empty list, in the
  manner screen 03 keeps over screen 27's card, with *Something else* still on
  it — is a drawing that does not exist. Recorded on #75 rather than invented
  here.
  """
  @spec page_for(map(), map(), String.t(), String.t() | nil) :: map()
  def page_for(assigns, services, query, save_error) do
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
        {Kati.Screens.MyServices.search_field(query, services.set_up?, Map.get(assigns, :query_epoch, 0))}
        {UI.eyebrow(Kati.Screens.MyServices.subscribed_label(services, query))}
        {Kati.Screens.MyServices.service_group(services.subscribed, true, query)}
        {Kati.Screens.MyServices.free_band(services.free)}
        {Kati.Screens.MyServices.no_match(services, query)}
        {Kati.Screens.MyServices.catalogue_group(services, save_error)}
        {UI.eyebrow("Rules")}
        {Kati.Screens.MyServices.rules_group(assigns.rules)}
        {UI.eyebrow("Money")}
        {Kati.Screens.MyServices.money_group(services)}
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
  sentence points the field at `catalogue_group/2`'s escape hatch, and the hatch
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
  def search_field(query \\ nil, set_up? \\ true, epoch \\ 0)

  def search_field(nil, _set_up?, _epoch) do
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

  def search_field(query, set_up?, epoch) when is_binary(query) do
    assigns = %{
      query: query,
      on_change: {self(), :service_query},
      # `Kati.Screens.Search`'s counter, for its reason and `K-46`'s: the
      # bridge remembers the last epoch it saw per field and ignores a `value`
      # for a field it has already drawn. Without it a save cleared the assign
      # and left the line sitting in the box — found on the Pixel_9a, where
      # correcting Mubi's price wrote £12.99 and the field still read
      # `Mubi 12.99` over an unfiltered list.
      epoch: epoch,
      # A field over an empty list cannot be searching it. `Search services`
      # is the right word on a page with services on it and a dead end on one
      # without: there is nothing to search, and the field is in fact the way
      # you name the first one. Same control, same tap, the sentence the page
      # is actually in.
      placeholder: if(set_up?, do: "Search services", else: "Name a service, and what it costs")
    }

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
          placeholder={@placeholder}
          return_key="search"
          weight={1.0}
          accessibility_id="service_query"
          on_change={@on_change}
          value_epoch={@epoch}
        />
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  The subscribed eyebrow, carrying the count of what is actually listed.

  `none yet` is about a reader who has told Kati nothing, so under a filter it
  is simply false — they have four and typed a word that matches none. The
  count is what the eyebrow says then, and `0` is the honest one (#118).
  """
  @spec subscribed_label(map(), String.t()) :: String.t()
  def subscribed_label(services, query \\ "")

  def subscribed_label(%{subscribed: []}, query) when is_binary(query) and query != "",
    do: "Subscribed · 0"

  def subscribed_label(%{subscribed: []}, _none), do: "Subscribed · none yet"
  def subscribed_label(services, _query), do: "Subscribed · #{length(services.subscribed)}"

  @doc """
  The pill under the empty card: add the service named in the field above.

  `:add_first`, and the same writer as *Something else* — one way a service
  gets into Kati, two places to reach it, rather than two writers able to
  disagree. Its own TAG, though: `Mob.Renderer` registers `{pid, atom}` and
  emits the atom as the control's `accessibility_id`, so two nodes sharing one
  would be two controls a device test could not tell apart, and
  `Kati.ScreenTapSweepTest` fails on exactly that.

  An empty field answers *Nothing to save yet* under the row, which
  `Kati.Write.message/1` already words.
  """
  @spec add_first_pill() :: map()
  def add_first_pill do
    assigns = %{
      pill:
        Kati.Components.MishkaPill.pill(
          label: "Add it",
          background: Palette.ink_fill(),
          color: Palette.on_ink(),
          height: 38,
          corner_radius: 19,
          padding: 0,
          padding_left: 18,
          padding_right: 18,
          text_size: 13,
          font_weight: :bold,
          align: :center,
          on_tap: {self(), :add_first}
        )
    }

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={13} />
      <Row fill_width={true} align="center">
        <Spacer weight={1.0} />
        {@pill}
        <Spacer weight={1.0} />
      </Row>
      <Spacer size={10} />
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
  of MOVIES-AND-TV.md #75 in one band.
  """
  @spec free_band([map()]) :: map()
  def free_band([]), do: ~MOB"<Spacer size={0} />"

  def free_band(free) do
    assigns = %{group: Kati.Screens.MyServices.service_group(free, false)}

    ~MOB"""
    <Column fill_width={true}>
      {UI.eyebrow("Free with ads")}
      {@group}
    </Column>
    """
  end

  @spec service_group([map()], boolean()) :: map()
  # Board 93's own card, called rather than copied — the module that owns an
  # artboard owns its copy, which is the arrangement Home keeps with screen 139
  # and the Library with band one of screen 27 — with the action under it.
  #
  # The card says *Turn on the ones you pay for* and there is nothing on the
  # page to turn on: with no catalogue, the only way to name a service is to
  # type it and press the row at the far end of the page. A card that tells
  # somebody what to do and does not offer it is a card they read twice. So
  # the pill goes under the sentence, on the same write as *Something else*,
  # and the field above it is asking for the name.
  @doc """
  A group of services, with prices where they have them.

  The subscribed group takes the ownership `info` row under it; the free group
  does not, because nothing on it has a price to own.
  """
  def service_group(services, owner_note?, query \\ "")

  # A GROUP a filter emptied is not a group that is empty. *Nothing here yet*
  # over a reader with four subscriptions, because they typed `mubi plus`, is
  # the same misreading #117 fixed on the search screen and #112 on the
  # activity log — and `no_match/2` is already saying the true thing one row
  # down. So under a query the group draws nothing and lets it. #118.
  def service_group([], _owner_note?, query) when is_binary(query) and query != "" do
    ~MOB"<Spacer size={0} />"
  end

  def service_group([], true, _query) do
    assigns = %{card: Kati.Screens.MyServicesEmpty.empty_group()}

    ~MOB"""
    <Column fill_width={true}>
      {@card}
      {Kati.Screens.MyServices.add_first_pill()}
    </Column>
    """
  end

  def service_group(services, owner_note?, _query) do
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

  MOVIES-AND-TV.md #119: there was no way to remove, rename or price a service.
  Once *Something else* wrote a row you were stuck with it — the row's own tap
  reached `"edit_service_" <> _name -> {:noreply, socket}`, five drawn rows
  the sweep listed as inert with the reason that no per-service editor is drawn
  anywhere in the set.

  Board 95 specifies the control and this is it: an on/off pill on every row.
  Off moves the service to `:not_mine`, which is the tier the *Not mine* group
  already counts, so it leaves this page's two lists without being deleted —
  a service you cancelled is not a service you never had, and the reader can
  turn it back on from the catalogue.

  The row's own tap still opens the price. See `handle_tap/2`'s
  `"edit_service_"` clause: it puts the service's name and price back in the
  field the *Something else* row writes from, so correcting `Netflix 10.99` to
  `Netflix 12.99` is retyping the line you typed, in the place you typed it.
  """
  @spec service_row(map()) :: map()
  def service_row(service) do
    SettingsList.row(
      Kati.Screens.MyServices.badge_tile(service.badge),
      SettingsList.body(service.name, nil),
      SettingsList.trailing(Kati.Screens.MyServices.row_trailing(service)),
      on_tap: {self(), Kati.Screens.MyServices.service_tag(service)}
    )
  end

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
      label: "Mine",
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
  @spec catalogue_group(map(), String.t() | nil) :: map()
  def catalogue_group(services, save_error \\ nil) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.eyebrow_muted("Not mine")}
      {Kati.UI.SettingsList.card(
        Kati.Screens.MyServices.count_row(services) ++
        [
        Kati.UI.SettingsList.row(
          Kati.UI.SettingsList.icon_tile("add"),
          Kati.UI.SettingsList.body("Something else", "Type its name, and its price after it — Netflix 10.99. Kati remembers both for your subscription total.", lines: 3),
          Kati.UI.SettingsList.trailing(nil),
          on_tap: {self(), :add_service}
        )
        ]
      )}
      {Kati.Screens.MyServices.save_notice(save_error)}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  What the *Not mine* row says, and it no longer says `Show all 47`.

  MOVIES-AND-TV.md #35. That row read *Show all 47 · Everything JustWatch
  lists for the UK* and opened screen 93 — the board that announces
  *Subscribed · none yet* and *Pick your country · Nothing works until this is
  set* — to a reader with three services and a country. Two lies for the price
  of one tap: a catalogue that does not exist anywhere in this app, and a page
  contradicting the page it was opened from.

  Kati has no catalogue provider. `Kati.Services.Service` holds the services a
  person has told it about and nothing else, so `47` was the drawing's number
  and could never become anyone's. What this row can honestly say is how many
  Kati knows, and that a fuller list needs a source it has not got — so that
  is what it says, and it is a statement rather than a door, because there is
  nothing on the other side of it. `Kati.UI.SettingsList.trailing(nil)` and no
  `on_tap`: not tappable rather than broken.

  The drawing keeps its own words. A device with nothing set up renders board
  92 whole, `Show all 47` included, which is the state that board was captured
  in — see `set_up?/0` for why the gate is the page.

      iex> Kati.Screens.MyServices.count_row(%{subscribed: [], free: []})
      []

      iex> Kati.Screens.MyServices.catalogue_line(%{set_up?: true, subscribed: [1, 2], free: [3]})
      {"Kati lists 3 services",
       "The ones you have told it about. A fuller list needs a source Kati has not got yet."}

      iex> Kati.Screens.MyServices.catalogue_line(%{set_up?: true, subscribed: [1], free: []})
      {"Kati lists 1 service",
       "The ones you have told it about. A fuller list needs a source Kati has not got yet."}
  """
  @spec catalogue_line(map()) :: {String.t(), String.t()}
  def catalogue_line(%{subscribed: subscribed, free: free}) do
    count = length(subscribed) + length(free)
    noun = if count == 1, do: "service", else: "services"

    {"Kati lists #{count} #{noun}",
     "The ones you have told it about. A fuller list needs a source Kati has not got yet."}
  end

  @doc """
  The count row, or no row at all on a page with nothing counted.

  *Not mine* over `Kati lists 0 services` above a card that has just said *No
  services yet* is the same sentence twice, and the second time it is a
  number. A section with nothing to say does not say it — the rule this page
  now keeps for its Free with ads band as well.
  """
  @spec count_row(map()) :: [map()]
  def count_row(%{subscribed: [], free: []}), do: []

  def count_row(services) do
    {label, sub} = Kati.Screens.MyServices.catalogue_line(services)

    [
      Kati.UI.SettingsList.row(
        Kati.UI.SettingsList.icon_tile("more_horiz"),
        Kati.UI.SettingsList.body(label, sub, lines: 3),
        Kati.UI.SettingsList.trailing(nil)
      )
    ]
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

  @doc """
  The three rules, as `{key, title, sentence}`.

  Public because screen 93 draws the same three (board 323) and the private
  attribute was what made that file copy them: its own comment said the
  sentences *"are duplicated rather than shared because they live in a private
  attribute there"*, and a drift would then be found by a literal check rather
  than made impossible.
  """
  @spec rules() :: [{atom(), String.t(), String.t()}]
  def rules, do: @rules

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
    last = length(@rules) - 1

    rows =
      @rules
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
  def total_trailing(nil), do: ~MOB"<Spacer size={0} />"

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
  @impl true
  def handle_tap(:pick_country, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.CountryPicker)}

  def handle_tap(:open_subscriptions, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Subscriptions)}

  # `Something else` used to push screen 23, which is a read-only page about
  # money you already spend — the one place in the app that could not answer
  # "add a service Kati has never heard of". It writes now; see `add_service/1`.
  def handle_tap(tag, socket) when tag in [:add_service, :add_first],
    do: {:noreply, Kati.Screens.MyServices.add_service(socket)}

  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "rule_" <> rule ->
        key = String.to_existing_atom(rule)
        Services.toggle_rule(key)
        {:noreply, Mob.Socket.assign(socket, :rules, Services.rules())}

      # Board 95's switch, off. `:not_mine` rather than a destroy: a service you
      # cancelled is not one you never had, and the *Not mine* group already
      # counts that tier — so the row leaves this page's two lists and the
      # reader can put it back from the catalogue. MOVIES-AND-TV.md #119.
      "drop_service_" <> id ->
        {:noreply, Kati.Screens.MyServices.drop_service(socket, id)}

      # Every service row, by its own name — see `service_tag/1`. It puts the
      # service back in the field the *Something else* row writes from, so
      # correcting `Netflix 10.99` to `Netflix 12.99` is retyping the line you
      # typed where you typed it — which is the whole of the editor #119 asks
      # for, without a second sheet drawing a second way to say one thing.
      "edit_service_" <> name ->
        {:noreply, Kati.Screens.MyServices.edit_service(socket, name)}

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
  @impl true
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
        # Re-read, because the page renders from `:services` and that map was
        # built at mount. Before this the row was written and the page went on
        # drawing the list it had — the reader added a service and the screen
        # said *Subscribed · 3* over the drawing's three, which is the same
        # class of defect `Kati.Screens.Resume` fixes for a screen you come
        # back to. Here the screen never left.
        socket
        |> Mob.Socket.assign(:query, "")
        |> Mob.Socket.assign(:query_epoch, (socket.assigns[:query_epoch] || 0) + 1)
        |> Mob.Socket.assign(:services, Kati.Screens.MyServices.listed())
        |> Mob.Socket.assign(:save_error, nil)

      {:error, _reason} = error ->
        Mob.Socket.assign(socket, :save_error, Write.message(error))
    end
  end

  @doc """
  Turn a service off: `:not_mine`, and the page re-read.

  Not a destroy. The *Not mine* group already counts this tier, so the row
  leaves the two lists above without leaving the store — a service you
  cancelled in March is a thing you had, and `Kati.Screens.Money` reads the
  history. MOVIES-AND-TV.md #119.
  """
  @spec drop_service(Mob.Socket.t(), String.t()) :: Mob.Socket.t()
  def drop_service(socket, id) do
    with {:ok, service} <- Ash.get(Service, id),
         {:ok, _updated} <-
           service |> Ash.Changeset.for_update(:update, %{tier: :not_mine}) |> Ash.update() do
      socket
      |> Mob.Socket.assign(:services, Kati.Screens.MyServices.listed())
      |> Mob.Socket.assign(:save_error, nil)
    else
      error -> Mob.Socket.assign(socket, :save_error, Write.message(error))
    end
  end

  @doc """
  Put a service back in the field, so the next save corrects it.

  `Netflix 10.99` is the line the *Something else* row asks for and
  `save_service/1` already answers `{:ok, existing}` for a name already listed
  — so the same field, refilled, is the editor. What was missing was any way
  to get the line back into it.

  The price goes in only when there is one: `Netflix` for a service with no
  price is the line a reader would type to give it one, and `Netflix ` with a
  trailing space is not.
  """
  @spec edit_service(Mob.Socket.t(), String.t()) :: Mob.Socket.t()
  def edit_service(socket, tagged) do
    services = socket.assigns[:services] || Kati.Screens.MyServices.listed()

    case Kati.Screens.MyServices.by_tag(services, tagged) do
      nil ->
        socket

      service ->
        socket
        |> Mob.Socket.assign(:query, Kati.Screens.MyServices.line_for(service))
        # The field has already been drawn, so the refill needs a new epoch
        # too — otherwise the line goes into the assign and never into the box.
        |> Mob.Socket.assign(:query_epoch, (socket.assigns[:query_epoch] || 0) + 1)
    end
  end

  @doc false
  @spec by_tag(map(), String.t()) :: map() | nil
  def by_tag(services, tagged) do
    (services.subscribed ++ services.free)
    |> Enum.find(
      &(Kati.Screens.MyServices.service_tag(&1) == String.to_atom("edit_service_" <> tagged))
    )
  end

  @doc """
  A service as the line the field takes.

      iex> Kati.Screens.MyServices.line_for(%{name: "Netflix", pence: 1099})
      "Netflix 10.99"

      iex> Kati.Screens.MyServices.line_for(%{name: "Aria Free", pence: nil})
      "Aria Free"
  """
  @spec line_for(map()) :: String.t()
  def line_for(%{pence: pence} = service) when is_integer(pence) and pence > 0,
    do: "#{service.name} #{:erlang.float_to_binary(pence / 100, decimals: 2)}"

  def line_for(service), do: service.name

  @doc """
  The same service, at the price that was just typed and back on the shelf.

  Two things, because typing a name into this field means both. A price after
  the name is a correction (#119); the name alone, on a service the reader
  switched OFF, is them putting it back — and *Netflix* typed into the add row
  answering `{:ok, existing}` while the row stayed under *Not mine* is a save
  that reports success and shows nothing, which is what the device did.

  A service already on the shelf is left where it is: `:free_with_ads` is a
  tier the reader chose and re-typing the name must not promote it.

      iex> Kati.Screens.MyServices.repriced(%{monthly_pence: 1099, tier: :subscribed}, nil)
      {:ok, %{monthly_pence: 1099, tier: :subscribed}}
  """
  @spec repriced(term(), integer() | nil) :: {:ok, term()} | {:error, term()}
  def repriced(%{tier: tier} = service, nil) when tier != :not_mine, do: {:ok, service}

  def repriced(service, pence) do
    attrs = if is_nil(pence), do: %{}, else: %{monthly_pence: pence}

    attrs =
      if Map.get(service, :tier) == :not_mine,
        do: Map.put(attrs, :tier, :subscribed),
        else: attrs

    if attrs == %{} do
      {:ok, service}
    else
      service |> Ash.Changeset.for_update(:update, attrs) |> Ash.update()
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
        {name, pence} = Kati.Screens.MyServices.split_price(typed)

        case Kati.Screens.MyServices.already_listed(name) do
          %Service{} = service ->
            # A name already listed, with a price after it, is somebody
            # CORRECTING the price — which is the editor MOVIES-AND-TV.md #119
            # asks for, in the field they typed the line in rather than in a
            # second sheet drawing a second way to say one thing. A bare name
            # still writes nothing: re-adding something you already have is
            # the ordinary way somebody checks whether they already have it,
            # and it must not blank a price they set earlier.
            Kati.Screens.MyServices.repriced(service, pence)
            |> Write.note("add service #{name}")

          nil ->
            Kati.Screens.MyServices.create_service(name, pence)
            |> Write.note("add service #{name}")
        end
    end
  end

  def save_service(_nothing), do: Write.note({:error, :nothing_to_save}, "add service")

  @doc """
  A name, and a price if one was typed after it.

  One field, because two would be a form. Screen 23 is a page about money and
  nothing in this app could enter any: `Kati.Services.Service.monthly_pence`
  has existed since the resource was written and every writer left it `nil`,
  so *Every month* read `—` however many services somebody added and the
  *Something else* row's promise — *Kati will remember it for your
  subscription total* — was one it could not keep.

  So the field takes both. `Netflix 10.99` is a name and a price; `Netflix` is
  a name. A trailing number is read as money in the account's own currency, a
  leading `£`, `$` or `€` is ignored rather than parsed, and anything that is
  not a bare amount stays part of the name — `Apple TV+ 4K` is a service
  called *Apple TV+ 4K*, not one costing four thousand pence.

      iex> Kati.Screens.MyServices.split_price("Netflix")
      {"Netflix", nil}

      iex> Kati.Screens.MyServices.split_price("Netflix 10.99")
      {"Netflix", 1099}

      iex> Kati.Screens.MyServices.split_price("Now £9")
      {"Now", 900}

      iex> Kati.Screens.MyServices.split_price("Apple TV+ 4K")
      {"Apple TV+ 4K", nil}
  """
  @spec split_price(String.t()) :: {String.t(), non_neg_integer() | nil}
  def split_price(typed) do
    case Regex.run(~r/^(.*?)\s+[£$€]?(\d+(?:[.,]\d{1,2})?)$/u, String.trim(typed)) do
      [_whole, name, amount] when name != "" -> {String.trim(name), pence(amount)}
      _no_price -> {String.trim(typed), nil}
    end
  end

  defp pence(amount) do
    case amount |> String.replace(",", ".") |> Float.parse() do
      {pounds, ""} -> round(pounds * 100)
      _not_a_number -> nil
    end
  end

  @doc """
  The row itself, spelled out rather than left to the resource's defaults.

  `tier` and `provider_id` both happen to be what `Kati.Services.Service`
  defaults to, and both are written here anyway: they are the two columns this
  screen's copy makes a promise about — *your subscription total*, which only
  `:subscribed` is counted for, and *cannot tell you what is on it*, which is
  what a nil `provider_id` means — and a promise resting on somebody else's
  default is a promise nobody would think to check before changing it.
  """
  @spec create_service(String.t(), non_neg_integer() | nil) ::
          {:ok, Service.t()} | {:error, term()}
  def create_service(name, pence \\ nil) do
    Ash.create(Service, %{
      name: name,
      tier: :subscribed,
      provider_id: nil,
      monthly_pence: pence
    })
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
