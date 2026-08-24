defmodule Kati.Screens.MyServicesStates do
  @moduledoc """
  Screen 95 — the five states of screen 92, on one sheet pushed under Settings.

  Screen 92 draws My services as it looks once somebody has finished with it: a
  region, three subscriptions, two free tiers and a total. This is the board
  that draws it on the way there and on the way wrong — a region chosen before
  any service is, a search that matches nothing, the provider catalogue
  unreachable, the region changed under a library that is already full, and a
  service switched off while the history still names it. It is a reference sheet
  in screen 27's manner — pictures of a screen you go and look at, rather than
  something the app puts in front of you — and it carries a back pill for
  exactly that reason, as 27, 67, 78 and 81 do.

  One eyebrow keeps the orange dash. *Region set, no services* is the state a
  reader is in **while they are setting the screen up**, which is a moment
  rather than a condition, and orange means new/now. The other four name
  conditions — a search that missed, a list that would not load, a change that
  has already landed, a service that is off — so they take 27's grey dash. The
  board draws it that way and the reading holds: even *Region changed* is drawn
  after the fact, with an `Undo` beside it, rather than as something happening.

  ## The two states that matter are about honesty

  The design's own caption names them, and both are answers to a fear rather
  than reports of a change.

  **Region changed leads with what does not change.** The obvious sentence for a
  region switch is what it breaks — three services vanish from the list — and
  that is the sentence that makes somebody put the phone down. The fear a region
  switch raises is *have I just lost my data*, so the paragraph spends its
  emphasis on `Your library, ratings, notes and history do not change at all`
  and only then says which three services stop being listed. The claim is true
  of the code rather than reassurance: `Kati.Services.put_region/1` writes one
  key into `Mob.State` and touches no resource at all, so nothing under
  `Kati.Media` can move when it runs. `Got it` and `Undo` sit under it in that
  order for the reason screen 81 gives about its own pair — the reader has
  already made this change, so the answer their thumb finds first is the one
  that accepts it, and `Undo` hugs its own label beside it.

  **Removed service says the history stays.** Turning Orbit off is a claim about
  the *future* — what counts as watchable from today — and none about the past,
  so the card leads with `Those stay exactly as they were` and names the log
  that guarantees it: screen 15, `Kati.Screens.Activity`, is append-only. Only
  the last clause is about availability, which is the whole shape of the state:
  43 old entries keep naming Orbit and nothing rewrites one of them.

  ## Everything both screens draw the same way is screen 92's

  The region row's tile is `Kati.Screens.MyServices.flag_tile/1` and the two
  service tiles are `Kati.Screens.MyServices.badge_tile/1`, so `🇬🇧`, `L` and `O`
  are drawn by the functions that draw them on 92 rather than by a second copy
  of the same `Box`. The prices are `Kati.Screens.MyServices.price/1` and the
  services themselves are `Kati.Screens.MyServices.drawn/0`, which exists for
  precisely this — its own doc calls it *the fixture, not a fallback path* — so
  `Lumen+ · £8.99` and `Orbit · £13.99` are 92's figures and cannot drift from
  them.

  The country is not typed here either. `Kati.Services.flag/1` derives the flag
  from the code and `Kati.Services.region_name/1` spells `United Kingdom` and
  `Iran` out of the same seven-country table screen 94 offers, so the two bands
  on this sheet name the countries the app can actually be set to. It does cost
  the literal check two lines — `Region is now Iran` is composed rather than
  written, the way screen 81 composes `OLDEST ENTRY 5 MONTHS` — and that is the
  trade: a retyped country name goes stale the first time the table is edited.

  The cream offline badge is 27's card at this screen's metrics — radius 20 and
  15 of padding, where 27 draws 18 and 14/16 — which is the arrangement 67, 71
  and 81 all landed on, and the sentence under it is this page's own. `Got it`
  and `Undo` are `Kati.Screens.DataSourcesStates.answer/5`, the 40pt pill at
  radius 20 that 81 built for its confirmation, at the same five numbers this
  board asks for.

  ## Where the board and screen 92 disagree, and which one wins

  92 wins everywhere, for 67's reason: a sheet that redrew a band its own way
  would report a difference between the two screens that the app does not have.

    * **The service rows carry no price pill and no switch.** The board draws
      each price in a 32pt paper lozenge with an inset `rgba(26,25,23,.09)` ring
      and a 46x28 ink switch after it. Screen 92 draws neither —
      `Kati.Screens.MyServices.service_row/1` puts `price/1`'s bare mono figure
      in the trailing slot and offers no per-service control at all — and 92's
      *own* drawing specifies both, so this is 92 being behind its board rather
      than this sheet being behind 92's. The pill and the switch are the change
      92 would have to make first, once, for both screens. It leaves the cream
      card's promise — `Your saved services still show, and still toggle` —
      naming a control the rows have not grown yet, which is worth having on a
      states sheet in exactly those words.
    * **The search field is 92's field.** 48 tall at radius 24 with
      `Kati.Theme.shadow_search/0` and 17 of side padding, where the board draws
      46/23 and the card shadow; 92 departs from its own drawing by those two
      points and this sheet follows 92. Only the two things the *state* changes
      are changed: the placeholder becomes the reader's own query, in ink
      because it is now their text and not a prompt, and the filled `cancel`
      appears to clear it.
    * **The region row has no sub-line.** On 92 it reads *Decides what
      “available” means*, which is that screen's argument for putting region
      above the list. Here the row is drawn as the board draws it, because the
      band's subject is the row *below* it — the empty money row — and repeating
      92's justification would bury it.

  One tile is this sheet's own number and not the board's. The `payments` row
  sits in the same card as the flag and the board gives both tiles 40pt, so it
  is drawn at 40 rather than at `Kati.UI.SettingsList.icon_tile/1`'s 30. That is
  not the concession 81 refused: 92 leads *this* card with
  `Kati.Screens.MyServices.flag_tile/1`, which is 40, so 40 is what 92 draws in
  the slot directly above. Two tiles at two sizes in one card is the thing that
  would read as a defect.

  The subtitle is `five states` in `Kati.UI.SettingsList.title/2`'s mono 11
  where the board sets it in sans at 13.5. Screen 78 records the same departure
  and takes the same answer: two reference sheets that disagreed about their own
  heading would be the more visible mistake.

  ## Nothing here reads a store

  27's argument, unchanged: each card is a picture of a state, not a report that
  the app is in it. Three lines look like data and each is refused for its own
  reason.

    * **`43 entries mention it`** is the one that could genuinely be read.
      `Kati.Media.Watch` carries a `:service` string, so counting the watches
      that name `Orbit` is one query. It is still not read, because the removal
      it is counted against never happened: switching a service off moves
      `Kati.Services.Service`'s tier to `:not_mine` or destroys the row, and
      neither leaves a tombstone, so there is no *from today* for the count to
      be true as of. A real figure — almost certainly `0` on any device — under
      an invented removal reads as a live incident report and is not one.
    * **`United Kingdom`** is pinned to `GB` rather than read from
      `Kati.Services.region/0`. A reader who has already switched to Iran would
      see the first band say Iran and the fourth band announce the switch *to*
      Iran, and the before/after that is this sheet's entire subject would be
      the same country twice.
    * **`mubi plus`** is a query nobody typed, under an eyebrow promising a
      search that missed. Reading the field's real contents would show an empty
      box.

  ## What the bridge cannot draw

    * **The bold spans are not bold.** `Kati.UI.rich_text/1` concatenates its
      runs and applies one style, because `MobText` takes a `String` and there
      is no `AnnotatedString` in the bridge. The three emphasised phrases are
      still written as runs rather than as flat strings: `leaving soon`,
      `Your library, ratings, notes and history do not change at all` and
      `Something else` are what each sentence *means*, and on the day the bridge
      grows a `runs` prop these call sites are already right.
    * **`15` is not a link.** The board makes the screen reference an anchor.
      Per-run styling is what the bridge is missing, and a per-run tap is a
      further thing again, so the reference sets as the number it is — which is
      how `Kati.Screens.MyServices.credit/0` already writes *credited on 83*.

  ## Nothing on this sheet taps

  The chevron, the clear glyph, `Got it` and `Undo` are drawn and not wired, so
  no `handle_tap/2` is defined and `Kati.Screens.Pushed` has no catch-all to
  swallow one. 67's reason, and it has teeth here: the live `Undo` on screen 92
  would put the region back, and a specimen control that moved a device's region
  would change what every other screen in the app calls watchable.
  """

  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.Screens.DataSourcesStates
  alias Kati.Screens.MyServices
  alias Kati.Services
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @doc false
  @spec content(map()) :: map()
  def content(_assigns) do
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
        {SettingsList.title("My services", "five states", nil, :name)}
        {UI.eyebrow("Region set, no services — a legitimate middle")}
        {Kati.Screens.MyServicesStates.region_set()}
        {SettingsList.eyebrow_muted("Search with no match")}
        {Kati.Screens.MyServicesStates.no_match()}
        {SettingsList.eyebrow_muted("Provider list unavailable")}
        {Kati.Screens.MyServicesStates.provider_list_down()}
        {SettingsList.eyebrow_muted("Region changed")}
        {Kati.Screens.MyServicesStates.region_changed()}
        {SettingsList.eyebrow_muted("A service removed while history references it")}
        {Kati.Screens.MyServicesStates.removed_service()}
      </Column>
    </Scroll>
    """
  end

  @doc """
  A region chosen, and nothing subscribed under it.

  The board calls this *a legitimate middle*, and the card is the argument: a
  country row that has done its job sitting above a money row that has nothing
  to do. It is drawn as one card rather than as an empty state, because the
  screen is not empty — the region is set, and the region is the only thing on
  this page anything else depends on.

  The money row says `Nothing to add up yet` instead of `£0.00`. A zero is a
  total somebody could read as an error in the arithmetic; the sentence under it
  says which arithmetic, and it is the distinction
  `Kati.Services.Service`'s `:free_with_ads` tier exists for — free is a
  property of the service, not a price of nought.
  """
  @spec region_set() :: map()
  def region_set do
    rows = [
      SettingsList.row(
        MyServices.flag_tile(Services.flag("GB")),
        SettingsList.body(Services.region_name("GB")),
        SettingsList.trailing(SettingsList.chevron())
      ),
      SettingsList.row(
        Kati.Screens.MyServicesStates.glyph_tile("payments"),
        SettingsList.body(
          "Nothing to add up yet",
          "Free-with-ads only counts as watchable, not payable",
          lines: 2
        ),
        SettingsList.trailing(nil),
        rule: false
      )
    ]

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(rows)}
      <Spacer size={11} />
      {Kati.Screens.MyServicesStates.reassurance()}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The 40pt paper tile the region card's second row leads with.

  `Kati.UI.SettingsList.icon_tile/1` is the settings tree's tile and is 30
  square at radius 9 with a 17pt glyph, which is right everywhere a card is a
  list of settings. This card is not: its first row is
  `Kati.Screens.MyServices.flag_tile/1` at 40 square, radius 12, because a flag
  is a mark rather than an icon and 92 sizes it to match its service badges. A
  30pt tile under a 40pt one steps down mid-card and reads as a mistake, so this
  is `flag_tile/1`'s geometry carrying a Material Symbol instead of an emoji.
  """
  @spec glyph_tile(String.t()) :: map()
  def glyph_tile(name) do
    glyph = UI.symbol(name, size: 19, color: Palette.ink_soft())

    ~MOB"""
    <Box width={40} height={40} corner_radius={12} background={Palette.paper()} align="center">
      {glyph}
    </Box>
    """
  end

  @doc """
  The green tick that says the empty list is not a broken screen.

  Without it the band above is a page that has failed to do anything, which is
  the reading a reader arrives with and the wrong one. Region alone already
  makes leaving-soon dates and rental prices true — both are facts about a
  country rather than about an account — and the only question still waiting on
  the empty list is *what is included in something I already pay for*. So the
  card names the two things that already work rather than the one that does not.

  A filled `check_circle` in `Kati.Theme.Palette.green/0`, which is the glyph
  and the hue this design gives a settled fact everywhere else it draws one.
  """
  @spec reassurance() :: map()
  def reassurance do
    body = [text_size: 12.5, line_height: 1.55, text_color: Palette.ink_soft()]
    strong = [text_size: 12.5, font_weight: "semibold", text_color: Palette.ink()]

    message =
      UI.rich_text([
        {"Availability already works — region alone is enough for ", body},
        {"leaving soon", strong},
        {" and rental prices.", body}
      ])

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      padding={15}
      shadow={Kati.Theme.shadow_card_soft()}
    >
      <Row fill_width={true} align="center">
        {UI.symbol("check_circle", size: 18, color: Palette.green(), fill: true)}
        <Spacer size={11} />
        <Column weight={1.0}>
          {message}
        </Column>
      </Row>
    </Column>
    """
  end

  @doc """
  A query that matched nothing, and the field it was typed into.

  Two cards ten and eleven apart rather than the 22 between states, because the
  field and the answer are one moment: the query has to stay on screen next to
  the sentence about it, or the sentence is about nothing.

  The answer names the catalogue by name — JustWatch, through TMDB — and then
  points at the way out, which is the `Something else` row screen 92 already
  carries. That is the difference between *no results* and this: a search box
  that shrugs leaves the reader to decide whether Kati is broken or their
  service is obscure, and the second sentence answers it.
  """
  @spec no_match() :: map()
  def no_match do
    body = [text_size: 12, line_height: 1.55, text_color: Palette.sub()]
    strong = [text_size: 12, font_weight: "semibold", text_color: Palette.ink()]

    message =
      UI.rich_text([
        {"Kati uses JustWatch’s list through TMDB. If it is a real service they do not track, add it as ",
         body},
        {"Something else", strong},
        {".", body}
      ])

    field = Kati.Screens.MyServicesStates.query_field("mubi plus")

    answer =
      Kati.Screens.MyServicesStates.advice(
        "search",
        Palette.sub(),
        "No service called that",
        message,
        title_size: 13,
        gap: 5
      )

    ~MOB"""
    <Column fill_width={true}>
      {field}
      <Spacer size={11} />
      {answer}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  Screen 92's search field with something in it.

  Every metric is `Kati.Screens.MyServices.search_field/0`'s — 48 tall at radius
  24, the card ground, `Kati.Theme.shadow_search/0`, 17 of side padding and a
  19pt glyph — so this is that field in a different condition rather than a
  second field that resembles it. See the moduledoc for the two points by which
  92 and its own board differ, and why 92 wins here.

  The label changes colour along with its content. `Search services` is a prompt
  and sets in `Kati.Theme.Palette.tertiary/0`; `mubi plus` is the reader's own
  text and sets in ink, which is the whole visible difference between a field
  waiting and a field holding an answer.
  """
  @spec query_field(String.t()) :: map()
  def query_field(query) do
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
      <Text text={query} text_size={14} text_color={:on_surface} weight={1.0} max_lines={1} />
      <Spacer size={11} />
      {UI.symbol("cancel", size: 18, color: Palette.rail_idle(), fill: true)}
    </Row>
    """
  end

  @doc """
  The provider catalogue unreachable, over the services it does not affect.

  Order carries the meaning, as it does in 67's error/offline pair: the cream
  badge is the event and the card under it is the proof of what the badge
  claims. `Your saved services still show, and still toggle` would be a promise
  on its own; with two saved services drawn underneath it, it is an observation.

  The two rows are the first two of `Kati.Screens.MyServices.drawn/0`'s three —
  the board draws two and the account has three, and taking them off the front
  of 92's own fixture keeps the names, the badges and the prices 92's. See the
  moduledoc for the price pill and the switch the board puts on each row and 92
  does not.
  """
  @spec provider_list_down() :: map()
  def provider_list_down do
    services = Enum.take(MyServices.drawn().subscribed, 2)
    last = length(services) - 1

    rows =
      services
      |> Enum.with_index()
      |> Enum.map(fn {service, index} ->
        SettingsList.row(
          MyServices.badge_tile(service.badge),
          SettingsList.body(service.name),
          SettingsList.trailing(MyServices.price(service.price)),
          rule: index != last
        )
      end)

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.MyServicesStates.unreachable()}
      <Spacer size={11} />
      {SettingsList.card(rows)}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The cream badge, flat, at this screen's metrics.

  Radius 20 with 15 of padding, where `Kati.Screens.States.offline/1` draws 18
  and 14/16 — the same adjustment 67, 71 and 81 make to the same card, and for
  the same reason each time: a sheet's cards are one radius and one padding or
  the sheet reads as several sheets. No shadow, which is 27's own distinction
  rather than an omission — a condition the app is in is not an object lifted
  off the page.

  The sentence is this page's. What a reader fears when a catalogue goes down is
  that the account went with it, so the line says the saved services are still
  here and still theirs to change, rather than repeating 27's promise about the
  ticks.
  """
  @spec unreachable() :: map()
  def unreachable do
    ~MOB"""
    <Row
      fill_width={true}
      background={Palette.cream()}
      corner_radius={20}
      padding={15}
      align="center"
    >
      {UI.symbol("cloud_off", size: 20, color: Palette.gold_icon())}
      <Spacer size={12} />
      <Column weight={1.0}>
        <Text
          text="Can’t reach the provider list"
          text_size={13}
          font_weight="bold"
          text_color={:on_surface}
          max_lines={1}
        />
        <Spacer size={3} />
        <Text
          text="Your saved services still show, and still toggle"
          text_size={11.5}
          text_color={Palette.cream_sub()}
          max_lines={2}
        />
      </Column>
    </Row>
    """
  end

  @doc """
  The region switched, said in the order that answers the fear first.

  See the moduledoc for why the paragraph leads with what does not change. Two
  details of the writing are load-bearing beyond that. `three of your services`
  is a real count — `Kati.Services.Sample.subscribed/0` holds exactly three —
  and it is written out rather than counted, for the reason 81 gives about its
  own *three accounts*: a specimen sentence on a device with one service would
  print a true figure attached to an event that never happened. And the services
  `switch to Something else` rather than disappearing, which is the same
  `:not_mine` tier 92's own *Not mine* group is built on — a service that is
  unlisted in your new country is still a service you pay for.

  The body run is marked `base: true`. `Kati.UI.rich_text/1` otherwise takes its
  style from the longest run, and the emphasised clause here is sixty characters
  long — close enough to the body's that editing either could flip the choice
  and set the whole paragraph in semibold ink.
  """
  @spec region_changed() :: map()
  def region_changed do
    body = [text_size: 12.5, line_height: 1.6, text_color: Palette.ink_soft()]
    strong = [text_size: 12.5, font_weight: "semibold", text_color: Palette.ink()]
    region = Services.region_name("IR")

    message =
      UI.rich_text([
        {"What counts as watchable changes everywhere. ", body ++ [base: true]},
        {"Your library, ratings, notes and history do not change at all", strong},
        {" — three of your services are not listed in #{region} and switch to Something else.",
         body}
      ])

    card =
      Kati.Screens.MyServicesStates.advice(
        "public",
        Palette.gold_icon(),
        "Region is now #{region}",
        message,
        footer: Kati.Screens.MyServicesStates.answers()
      )

    ~MOB"""
    <Column fill_width={true}>
      {card}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  `Got it` and `Undo`, in that order.

  `Kati.Screens.DataSourcesStates.answer/5` at the board's five numbers — 40
  tall, radius 20, 16 of side padding, a 12.5pt label, ink under paper — so the
  two states sheets offer the same pill for the same kind of question rather
  than two pills that happen to agree.

  The order is 81's inverted, deliberately. 81 puts the destructive answer first
  because it is asking a question the reader has not answered yet. Here the
  change has already happened, so the wide answer is the one that accepts it and
  `Undo` hugs its own label beside it: a reader reaching without reading gets
  the harmless half.
  """
  @spec answers() :: map()
  def answers do
    got_it = DataSourcesStates.answer("Got it", Palette.ink_fill(), Palette.on_ink(), :bold, true)
    undo = DataSourcesStates.answer("Undo", Palette.paper(), Palette.ink_soft(), :semibold, false)

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={14} />
      <Row fill_width={true} align="center">
        <Column weight={1.0} fill_width={true}>
          {got_it}
        </Column>
        <Spacer size={8} />
        {undo}
      </Row>
    </Column>
    """
  end

  @doc """
  A service switched off, with the log that does not care.

  One flat `Text` rather than runs, and that is the board's own emphasis being
  declined rather than lost: the board makes `15` a link and nothing else in the
  sentence is emphasised, so there is no bold to record for a future `runs`
  prop — only a tap the bridge has no way to attach. The reference sets as the
  number it is, which is how `Kati.Screens.MyServices.credit/0` already writes
  *credited on 83*.

  `history` and not `error`, in `Kati.Theme.Palette.sub/0` and not red. Nothing
  has gone wrong here — a service you stopped paying for is a fact you told Kati
  — and a red glyph would make the log look like a casualty of it.
  """
  @spec removed_service() :: map()
  def removed_service do
    message =
      ~MOB"""
      <Text
        text="Those stay exactly as they were. Kati never rewrites what happened — 15 is append-only. Orbit simply stops counting as watchable from today."
        text_size={12.5}
        line_height={1.6}
        text_color={Palette.ink_soft()}
      />
      """

    Kati.Screens.MyServicesStates.advice(
      "history",
      Palette.sub(),
      "Orbit is off, but 43 entries mention it",
      message
    )
  end

  @doc """
  The sheet's paper card: a glyph, a title, and a paragraph the caller owns.

  Three of the five states end in one of these and the container is identical
  across all three — card ground, radius 20, 15 of padding, the soft card
  shadow, a 19pt glyph top-aligned against the first line of the title. What
  differs is the paragraph, so the paragraph arrives as a node: two of them are
  `Kati.UI.rich_text/1` runs and one is a flat `Text`, and a builder that took a
  string would have had to grow a second argument for the emphasis and a third
  for the size.

  Three options, each of which the board actually asks for:

    * `:title_size` — 13.5, and 13 on the search answer. The board sets that one
      notch quieter than the two consequential cards, which is the difference
      between reporting a miss and reporting a change.
    * `:gap` — 6 under the title, 5 on the same quieter card.
    * `:footer` — anything below the paragraph, which is only ever
      `answers/0`. Empty by default rather than absent, so a card with nothing
      under it draws nothing rather than a zero-height node.
  """
  @spec advice(String.t(), pos_integer(), String.t(), map(), keyword()) :: map()
  def advice(icon, colour, title, message, opts \\ []) do
    glyph = UI.symbol(icon, size: 19, color: colour)
    title_size = Keyword.get(opts, :title_size, 13.5)
    gap = Keyword.get(opts, :gap, 6)
    footer = Keyword.get(opts, :footer, [])

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      padding={15}
      shadow={Kati.Theme.shadow_card_soft()}
    >
      <Row fill_width={true} align="top">
        {glyph}
        <Spacer size={11} />
        <Column weight={1.0}>
          <Text
            text={title}
            text_size={title_size}
            font_weight="bold"
            text_color={:on_surface}
            max_lines={2}
          />
          <Spacer size={gap} />
          {message}
        </Column>
      </Row>
      {footer}
    </Column>
    """
  end
end
