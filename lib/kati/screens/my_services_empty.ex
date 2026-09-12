defmodule Kati.Screens.MyServicesEmpty do
  @moduledoc """
  Screen 93 — My services with nothing set up, pushed under Settings.

  Screen 92 is this page once a country, three subscriptions and a month's
  prices are in it. This is the ten minutes before any of that, which the
  design's own caption calls *the state every new user is in, so it gets a real
  board rather than a band* — a full artboard rather than a strip on screen
  27's states sheet, because it is the state most people will see first and the
  only one where every group on the page has to say something different.

  ## Everything the two boards draw the same, this file calls rather than redraws

  `Kati.Screens.MyServices.search_field/0` and its `service_group/2` are called
  straight through, so the search field and the two free services are not a
  second copy of anything: if 92's field grows a clear button, this one grows it
  in the same commit. The chrome, title, eyebrows, cards, rows, switches,
  chevrons and the region note are `Kati.UI` and `Kati.UI.SettingsList` on both
  boards for the same reason.

  What is written out here is only what the drawings genuinely disagree about —
  four groups and one sentence — and each has its own function and its own
  reason below.

  ## The unset region row is cream, not grey

  The caption states it as a decision: *it is the one thing blocking the rest*.
  Every other row on this page leads with `Kati.UI.SettingsList.icon_tile/1`,
  paper under a `#5C574F` glyph — the tile for a row that is one row among
  rows. `region_tile/0` is the exception, on the warm ground the design reserves
  for a note, because until a country is picked the service list below it is not
  wrong so much as meaningless. `Pick your country` / `Nothing works until this
  is set` says the same thing in words: 92's line describes what the setting
  *does*, this one says what happens while it is not set, which is the whole
  difference between a preference and a precondition.

  ## The rules group is screen 92's group, live — board 323

  This file used to own three rules of its own: 92's first two sentences
  copied, a third written for this state (*Off by default — with no services
  set it would hide everything*), and a `flip/2` that moved the switch in the
  socket and nowhere else. The argument was that a board about defaults which
  remembered a tap would stop drawing defaults after the first one.

  Board 323 overturns it, and the sentence it overturns it with is the one this
  whole file is written around: *"A specimen switch is a dead control with a
  costume, and this file has spent four waves removing those. 93 is 92 with
  nothing configured — not a second screen with its own memory."*

  So `Kati.Screens.MyServices.rules_group/1` draws the group, the tap calls
  `Kati.Services.toggle_rule/1`, and `load/1` reads `Kati.Services.rules/0`.
  On the device this board is about those answer the defaults anyway, because
  nothing has been stored — which is what makes the two pages one page in two
  states rather than two pages.

  `Hide titles I can't watch` is still off with nothing configured, for this
  board's own reason: it would hide everything. That is now a fact about
  `Kati.Services.default_rules/0` rather than a sentence under a switch, and
  323 says so — *"93's own reasoning, unchanged."*

  Flipping one changes no screen on a device with no country and no services,
  and 323 rules that acceptable rather than papering it: *"it is a preference
  stored ahead of the data it governs. The page does not pretend otherwise, and
  it does not refuse the tap."* The `not yet` mark board 322 defines is
  deliberately not used here — that mark is for a control with nothing behind
  it, and these have something behind them the moment a country is picked.

  ## The Money row reads "Nothing to add up yet"

  Not `£0.00`. A figure is an answer, and an answer of zero invites you to
  believe the account has been totalled and came to nothing; what is true is
  that nothing has been totalled. The row still opens screen 23, because that
  is where the total will appear and a row that greyed itself out would hide
  the destination along with the number.

  ## Three things screen 92 draws that this board does not

    * **The ownership note.** *This screen owns these prices; 23 reads them* is
      about prices, and nothing on this board has one. `service_group/2` already
      takes that as an argument for exactly this reason.
    * **The `Something else` row.** Naming a service Kati has never heard of is
      a step past the catalogue, and the catalogue is not trustworthy until a
      country is picked — which is what the row that *does* stay says.
    * **The JustWatch credit.** It credits availability data and this board
      shows none. `Kati.Screens.MyServices.credit/0` puts it back the moment
      there is something to credit, and screen 83 carries the attribution
      regardless.

  ## Two smaller departures from the sibling file, both toward the drawing

  The rows built here pass `rule: false` on the last row of every card, which is
  what both drawings show and what `Kati.UI.SettingsList.row/4` takes the option
  for. And `Free with ads` and `Money` take the grey dash of
  `Kati.UI.SettingsList.eyebrow_muted/1` rather than the accent one — both
  artboards draw them at `#C4BDB3`, and grey is what that helper's own doc calls
  a section that is a footnote to the one above it.
  """

  use Kati.Screens.Pushed, back: "Settings"
  use Gettext, backend: Kati.Gettext

  alias Kati.Components.MishkaThemeIcon
  alias Kati.Screens.MyServices
  alias Kati.Services
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @doc false
  def load(socket) do
    socket
    # Board 323: the reader's own answer, not `default_rules/0`. This page had
    # read the defaults because the rules group below it was a specimen; it is
    # 92's live group now, so reading anything but what 92 wrote would be the
    # page disagreeing with itself the moment it was opened twice.
    #
    # On the device this board is about, the two are the same map: nothing has
    # been configured, so nothing has been stored, and `rules/0` answers
    # `default_rules/0`. That is the point rather than a coincidence — it is
    # what makes 93 *92 with nothing configured* instead of a second screen.
    |> Mob.Socket.assign(:rules, Services.rules())
    |> Mob.Socket.assign(:chosen_region, Services.chosen_region())
  end

  @doc false
  def content(assigns) do
    # Every label in this sigil is the bare `gettext/1` screen 92 hands the same
    # helper, msgid for msgid, because the two boards are one page in two states
    # and a second msgid would let the Persian drift where the English cannot.
    # *Money* is the one that had a choice: the catalogue holds both `"Money"`
    # (*مالی*) and `pgettext("screen title", "Money")` (*پول*, screen 97's own
    # title). This is a section label that is a footnote to the group above it —
    # 92's `UI.eyebrow(gettext("Money"))` — so it is the bare one.
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
        {SettingsList.title(gettext("My services"), gettext("So Kati only shows you what you can actually watch."), nil, :name)}
        {UI.eyebrow(gettext("Region"))}
        {Kati.Screens.MyServicesEmpty.region_group(assigns[:chosen_region])}
        {Kati.Screens.MyServices.search_field()}
        {UI.eyebrow(gettext("Subscribed · none yet"))}
        {Kati.Screens.MyServicesEmpty.empty_group()}
        {SettingsList.eyebrow_muted(gettext("Free with ads"))}
        {Kati.Screens.MyServicesEmpty.free_group()}
        {Kati.Screens.MyServicesEmpty.catalogue_group()}
        {UI.eyebrow(gettext("Rules"))}
        {Kati.Screens.MyServices.rules_group(assigns.rules)}
        {SettingsList.eyebrow_muted(gettext("Money"))}
        {Kati.Screens.MyServicesEmpty.money_group()}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The country row with no country in it, over the sentence that says why it
  comes first.

  The note is `Kati.UI.SettingsList.note/2` carrying screen 92's paragraph
  unchanged, because both drawings put the same words in the same place. Both
  boards therefore draw whatever that helper draws, and neither can drift from
  the other while a designer is still deciding whether the frame is a border or
  a cream card.
  """
  @spec region_group(String.t() | nil) :: map()
  # A country the reader has chosen is drawn as screen 92 draws it — the flag,
  # the name, the chevron — because this page is 92 with no services on it, not
  # 92 with nothing known about it. `Pick your country · Nothing works until
  # this is set` is true of a phone nobody has told anything and false the
  # moment somebody has, and `Kati.Services.chosen_region/0` is the difference:
  # `region/0` answers `"GB"` on a fresh install so the availability questions
  # have an answer, which is a working assumption rather than a claim about the
  # reader.
  def region_group(code) when is_binary(code) and code != "",
    do: Kati.Screens.MyServices.region_group(code)

  def region_group(_unset) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card([
        Kati.UI.SettingsList.row(
          Kati.Screens.MyServicesEmpty.region_tile(),
          Kati.UI.SettingsList.body(
            gettext("Pick your country"),
            gettext("Nothing works until this is set")
          ),
          Kati.UI.SettingsList.trailing(Kati.UI.SettingsList.chevron()),
          on_tap: {self(), :pick_country},
          rule: false
        )
      ])}
      <Spacer size={11} />
      {Kati.UI.SettingsList.note("info", gettext("Availability is per country. Telling you a film is on Lumen+ when it is only on Lumen+ in Canada is worse than telling you nothing at all."))}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  The country tile: cream under a gold `public`, at the 40pt square screen 92's
  flag sits in.

  The colours are the pair the design uses for a note — `Palette.cream/0` and
  `Palette.gold_icon/0` — and they are here rather than on the paper tile every
  other row takes because this row is the page's precondition. See the moduledoc.

  `Kati.Components.MishkaThemeIcon` for the reason `Kati.UI.SettingsList.icon_tile/1`
  gives: it is a themed container around exactly one icon, which is precisely
  what a tile is. The glyph goes in as a child rather than through the `icon`
  shorthand, because that shorthand builds a `Text` with no `font_family` and
  would typeset the ligature `public` as the word; handed in as a child it keeps
  the symbols face and keeps `Kati.Icons.glyph!/1`'s raise for a name outside the
  shipped subset.
  """
  @spec region_tile() :: map()
  def region_tile do
    MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Palette.cream(), size: 40, radius: 12},
      [UI.symbol("public", size: 19, color: Palette.gold_icon())]
    )
  end

  @doc """
  The Subscribed group with nothing in it.

  Drawn as a card rather than as absence, for the reason
  `Kati.Screens.Sync.empty_card/3` gives: a settings group that vanishes when it
  is empty makes the page's shape depend on the data, and somebody who has just
  arrived should be able to see where their services will land before they have
  any.

  The copy invites rather than apologises — screen 27's rule for an empty state
  — and it names the payoff instead of the action. *Kati stops showing you
  things you can't watch* is what turning a service on actually buys, and this
  is the only place on the board that says it.

  ## Why this is markup and not `Kati.Components.MishkaEmptyState`

  That component is the one for this shape and it cannot carry this drawing. Its
  `title` and `description` props pin `text_size: :xl` and `:base` against
  `:on_surface` and `:muted`; the drawing wants 13.5pt semibold ink over 12pt
  `Palette.sub/0` at a 1.55 line, and none of the four is reachable. Passing the
  pair in as the component's inner block is not the way round it either: that
  block is centred by a single `Box`, and a Box stacks its children rather than
  stacking them in a column, so a tile, a heading and a paragraph would land on
  top of one another.

  So the recipe is `Kati.Screens.States.empty/1`'s, which is the sheet that
  documents empty states in the first place: a `Row` with a `Spacer weight={1.0}`
  either side of the tile, and `text_align="center"` on the two paragraphs under
  it. The card's own padding is the drawing's 15 on the sides and its 15 + 6
  added up on top and bottom.
  """
  @spec empty_group() :: map()
  def empty_group do
    # The paragraph's leading is `Kati.Locale.leading/1` rather than the
    # drawing's flat 1.55, which is the recipe's one departure under `:fa` and
    # the same one `Kati.UI.SettingsList.note_text/1` already makes for the
    # region note two groups up. Vazirmatn's ascenders and descenders are not
    # Plus Jakarta's, and three centred lines set at 1.55 collide; the card has
    # no fixed height, so the only thing that moves is the gap between lines.
    #
    # Both sentences are wrapped here rather than in the caller because this
    # card is drawn on screen 92 as well — `Kati.Screens.MyServices.service_group/3`
    # calls this function for its own empty state — so one msgid serves both
    # boards, which is the whole argument for the card living in this file.
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={15}
        padding_right={15}
        padding_top={21}
        padding_bottom={21}
      >
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          {Kati.Screens.MyServicesEmpty.empty_tile()}
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={13} />
        <Text
          text={gettext("No services yet")}
          text_size={13.5}
          font_weight="bold"
          text_align="center"
          text_color={:on_surface}
        />
        <Spacer size={6} />
        <Text
          text={gettext("Turn on the ones you pay for and Kati stops showing you things you can’t watch.")}
          text_size={12}
          line_height={Kati.Locale.leading(1.55)}
          text_align="center"
          text_color={Palette.sub()}
        />
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  The 48pt tile the empty group is headed by.

  Bigger and paler than a row's tile — 48 at radius 15, `subscriptions` at 22 in
  `Palette.rail_idle/0` — because it is illustrating the group rather than
  labelling a row, and the faintest mark on the page is the right weight for a
  picture of something that is not there yet.
  """
  @spec empty_tile() :: map()
  def empty_tile do
    MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Palette.paper(), size: 48, radius: 15},
      [UI.symbol("subscriptions", size: 22, color: Palette.rail_idle())]
    )
  end

  @doc """
  The two free services, through screen 92's own group builder.

  `Kati.Screens.MyServices.drawn/0` rather than its `free/0`, and the choice is
  the point of this function existing at all. `free/0` reads the database and
  falls back to the fixture, which is right on 92 and wrong here: a board whose
  subject is having nothing set up would stop being that board the moment a
  device had services stored. `drawn/0` is documented as the fixture rather than
  a fallback path, which is what a state board needs.

  `false` is `service_group/2`'s ownership-note argument, and it is false here
  for the reason that function's own doc gives — nothing in this group has a
  price to own.
  """
  @spec free_group() :: map()
  def free_group, do: MyServices.service_group(MyServices.drawn().free, false)

  @doc """
  The one row on this board that reaches past the account, and it is provisional.

  Screen 92 draws the same row saying *Everything JustWatch lists for the UK* —
  a country this device has not picked. `Pick a country first for an accurate
  list` is the same row admitting that its own 47 is a guess, which is why the
  count still comes from `Kati.Services.Sample.catalogue_count/0`: the number is
  JustWatch's on both boards, and only its trustworthiness differs.
  """
  @spec catalogue_group() :: map()
  # `Show all 47` is the board's own row and it opens nothing, here as on 92.
  #
  # It used to open screen 23 — the money ledger, a read-only page about what
  # you already spend, which is not a catalogue of anything (MOVIES-AND-TV.md
  # #35). There is no catalogue in this app to open: `Kati.Services.Service`
  # holds the services a person has told Kati about, and `47` is a number from
  # the drawing. The row keeps the board's words, because this board is what a
  # device with nothing set up looks like, and loses its chevron and its tap,
  # because there is nothing on the other side.
  def catalogue_group do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.eyebrow_muted(gettext("Not mine"))}
      {Kati.UI.SettingsList.card([
        Kati.UI.SettingsList.row(
          Kati.UI.SettingsList.icon_tile("more_horiz"),
          Kati.UI.SettingsList.body(Kati.Services.Sample.catalogue_count(), gettext("Pick a country first for an accurate list")),
          Kati.UI.SettingsList.trailing(nil),
          rule: false
        )
      ])}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  The link into screen 23, with nothing to quote yet.

  `Nothing to add up yet` in the title slot that 92 gives to a service count,
  and `Subscriptions` — the destination — on the second line where 92 prints
  `£46.47 A MONTH`. Neither a figure nor a count is withheld out of caution:
  see the moduledoc on why `£0.00` would be a false answer rather than an empty
  one. The trailing control is the chevron alone, because the total it normally
  sits beside is the thing that does not exist.
  """
  @spec money_group() :: map()
  def money_group do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card([
        Kati.UI.SettingsList.row(
          Kati.UI.SettingsList.icon_tile("payments"),
          Kati.UI.SettingsList.body(gettext("Nothing to add up yet"), gettext("Subscriptions")),
          Kati.UI.SettingsList.trailing(Kati.UI.SettingsList.chevron()),
          on_tap: {self(), :open_subscriptions},
          rule: false
        )
      ])}
    </Column>
    """
  end

  @doc false
  def handle_tap(:pick_country, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.CountryPicker)}

  def handle_tap(:open_subscriptions, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Subscriptions)}

  # Two tags arrive with the markup this screen borrows from 92, and both are
  # answered here rather than left to fall through, because neither is a
  # forgotten wire. Mob has no text input at all (#45), so the search field is a
  # resting field with nothing to focus; and a service row on a board whose
  # entire subject is having no services has no service to edit.
  def handle_tap(tag, socket) when tag in [:search, :edit_service], do: {:noreply, socket}

  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "rule_" <> rule ->
        # Board 323's ruling, in one line: *"92 and 97 remember; 93 forgets —
        # deliberately"* was the old reading and 323 overturns it. *"A specimen
        # switch is a dead control with a costume."* So the write goes through
        # `Kati.Services.toggle_rule/1`, the same call screen 92's identical
        # clause makes, and the assign is re-read from the store rather than
        # flipped in place.
        #
        # What flipping one does today is nothing visible, and 323 answers that
        # too: *"it is a preference stored ahead of the data it governs. The
        # page does not pretend otherwise, and it does not refuse the tap."*
        Services.toggle_rule(String.to_existing_atom(rule))
        {:noreply, Mob.Socket.assign(socket, :rules, Services.rules())}

      # The same two-tags-borrowed-from-92 argument as the clause above, for the
      # per-row form `Kati.Screens.MyServices.service_tag/1` now gives them
      # (#97). Answered here rather than left to fall through, because the
      # clause below reports what it does not recognise and this is recognised.
      "edit_service_" <> _name ->
        {:noreply, socket}

      _other ->
        # Reported, not swallowed. A bare `{:noreply, socket}` here would be the
        # disappearing act `Kati.Screens.Pushed` refuses to build in, done by
        # hand one file lower down.
        Kati.Screens.Root.unhandled_tap(__MODULE__, tag, socket)
    end
  end
end
