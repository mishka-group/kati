defmodule Kati.Screens.MoneyStates do
  @moduledoc """
  Screen 123 — the four states of screen 122, on one sheet pushed under Settings.

  Screen 122 draws Money once somebody has been using it for a while: four
  services, two months of expenses, a cost per watched hour beside every row and
  a suggestion at the foot. This is the board for the four conditions that page
  cannot show while it is full — an account with nothing in it, a subscription
  in its first week, a service paused out of the total, and a service cancelled
  with its hours kept. It is a reference sheet in screen 27's manner, pictures of
  a screen you go and look at rather than something the app puts in front of you,
  and it carries a back pill for exactly that reason, as 27, 67, 75 and 95 do.

  One eyebrow keeps the orange dash. *Nothing set up* is where a reader is on the
  day they install the app, which is a moment rather than a condition, and orange
  means new/now. The other three name conditions that have already settled — no
  hours logged, a service paused, a service cancelled — so they take 27's grey
  dash.

  ## The second band is the one the sheet exists for, and it is not a formatting choice

  A subscription with no watched hours is what every reader has in week one, and
  the honest answer for its cost per hour is an em dash: `£0.00` claims the
  service is free and an infinity claims the app is broken, when the truth is
  that dividing by no hours has no answer at all.

  That answer is not typed into this file. Kino's rate comes out of
  `Kati.Money.per_hour/2`, whose first clause is `hours <= 0 -> "—"`, which is
  the same function screen 122 calls for every row it draws. So the sheet cannot
  advertise a behaviour 122 does not have — the day that clause changes to a
  zero, this board changes with it and the change is visible on a page whose
  whole subject is that number.

  The paragraph under the row says the rest, and `Kati.Screens.Money.rate/1`
  paints it: `good?: nil` is the third arm of that function's colour table, so
  the dash sets in `Kati.Theme.Palette.tertiary/0` rather than in the green of a
  service earning its money or the red of one that is not. A verdict is withheld
  by drawing no verdict.

  ## Every row here is 122's row, and the tap is the only thing declined

  `Kati.Screens.MyServices.badge_tile/1`, `Kati.UI.SettingsList.body/3` and
  `Kati.Screens.Money.rate/1` are what `Kati.Screens.Money.service_row/1` is made
  of, and they are what `service_row/1` is made of here too, in the same
  `Kati.UI.SettingsList.row/4` with the same padding. What is not reused is that
  function's `on_tap`, which opens screen 23: a specimen row that navigated would
  take the reader off the sheet they came to read, and `Kati.Screens.Pushed`
  defines no `handle_tap/2` on purpose so a tap nobody wired is reported rather
  than swallowed. Nothing on this board taps — not the row, not `My services`.

  Both specimens are `Kati.Money.Sample.recurring/0`'s own services under a
  map-update, so what differs is the only thing that differs. Kino keeps its
  badge, its name and its £11.49 and loses its hours; Aria keeps everything and
  loses `· not in the total` from its second line, because the card directly
  under it now says that in a sentence. A key either fixture stops carrying
  fails here loudly rather than quietly adding a state the row would ignore.

  ## Where the board and screen 122 disagree, and which one wins

  122 wins, in all three places, for the reason 67 gives: a sheet that redrew a
  band its own way would report a difference the app does not have. All three are
  departures 122 already made from *its own* board, not new ones this sheet is
  choosing.

    * **The badge tile** sets in Plus Jakarta bold at
      `Kati.Theme.Palette.ink_soft/0` where both boards draw DM Mono in ink.
      `Kati.Screens.MyServices.badge_tile/1` owns that letter and screen 92 owns
      the services it stands for.
    * **The price above the rate** is 12.5pt in `Kati.Theme.Palette.sub/0` where
      both boards draw 12pt in ink. It is inside `Kati.Screens.Money.rate/1`,
      where nothing can be passed to it, and the rate is meant to be the loud
      figure of the pair.
    * **The paused row is not dimmed.** The board greys Aria's tile, title, price
      and second line; 122 draws it at full strength and says *paused* in words
      instead. The band's subject survives that intact — the eyebrow, the em
      dash, the second line and the total card below it all say the row is out of
      the figure — and greying a row here while 122 leaves it black would make
      the two screens disagree about what pausing looks like.

  ## The £34.48 is the board's figure and is not computed

  Summing the three unpaused prices in `Kati.Money.Sample.recurring/0` gives
  £34.47, and 122's own hero prints £46.47 for the same account. There are
  already two answers on the drawing board, and deriving a third one here would
  only add an answer. This card's subject is what the figure *excludes* rather
  than what it totals: `Aria’s £5.00` is the number on it doing work, and it is
  the price the fixture carries — read off `drawn_service/1` rather than typed
  into the sentence, so the total and the row above it cannot drift apart.

  Not computed is not the same as not formatted. Both figures are pence through
  `Kati.Money.display/1`, which is what draws every price on 122, so under `:fa`
  the card reads **۳۴٫۴۸ پوند** over **۵٫۰۰ پوند** — the board's own arithmetic
  in the reader's numerals, decimal mark and currency word.

  The label is `Kati.Money.Sample.monthly/0`'s, through
  `Kati.UI.eyebrow_label/1`. Screen 122's cream hero
  says *Every month* over a figure that includes everything; this paper card says
  it over a figure that does not, and taking the words from the same fixture is
  what makes that a comparison rather than a coincidence. Paper and not cream,
  because cream is the palette's ground for a card that asserts something and
  this one is an aside about the row above it.

  ## What is on the board and is not on the screen

    * **The back pill says `Settings`.** The board draws 122's own `Stats` pill,
      inherited along with its chrome. Every states sheet in the app is reached
      from Settings and pushed under it, and a pill that popped to Stats from a
      sheet Stats does not link to would be a dead end drawn as a route.
    * **`07` is not a link.** The board makes the screen reference an anchor.
      Per-run styling is what the bridge is missing and a per-run tap is a
      further thing again, so the reference sets as the number it is — which is
      how `Kati.Screens.MyServices.credit/0` already writes *credited on 83*.
    * **The bold spans are not bold.** `Kati.UI.rich_text/1` concatenates its runs
      and applies one style, because `MobText` takes a `String` and there is no
      `AnnotatedString` in the bridge. Both emphasised phrases are still written
      as runs: the em dash and `31 hours` are what those two sentences are about,
      and on the day the bridge grows a `runs` prop these call sites are already
      right.
    * **The two figures sit bottom-aligned, not baseline-aligned.** The bridge's
      `align` takes `top`, `center` and `bottom` and has no baseline, so the
      10.5pt label rides about a point low against the 18pt figure.

  ## Nothing here reads a store

  27's argument, unchanged: each card is a picture of a state, not a report that
  the app is in it. `Kati.Money.Expense` would answer *what is in the ledger* and
  `Kati.Screens.MyServices.subscribed/0` would answer *how many services* — which
  is exactly why neither is asked. An account with services in it would draw the
  empty state over a true count of three, and a reader on a fresh install would
  see three states where everyone else sees four.
  """

  # The board's own word, not the route's. These sheets are on `@no_route` —
  # `Kati.Screens.Gallery` is the only way to open one — so the pill names
  # nowhere in particular either way, and `Kati.Screens.WeightStates` already
  # set the precedent by keeping `Health` from its own board. Reproducing the
  # board is the rule; inventing a word for a pill nobody navigates by is not.
  use Kati.Screens.Pushed, back: "Stats"
  use Gettext, backend: Kati.Gettext

  alias Kati.Money.Sample
  alias Kati.Screens.Money
  alias Kati.Screens.MyServices
  alias Kati.Screens.MyServicesStates
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @doc false
  @spec content(map()) :: map()
  def content(_assigns) do
    # THE TITLE IS SCREEN 122'S OWN MSGID, AND THE EYEBROW'S ZERO IS A PRICE.
    #
    # `pgettext("screen title", "Money")` is what `Kati.Screens.Money.content/1`
    # heads the page with, and the catalogue holds three different Persian words
    # under `Money` — پول for the screen, مالی for the Stats section and for the
    # search scope. A sheet of a screen's states that picked a fourth, or picked
    # the section's word, would name the page it pictures something the page
    # does not call itself. So it takes the same context rather than a msgid of
    # its own.
    #
    # The eyebrow's `£0.00` goes through `Kati.Money.display/1` for the reason
    # `Kati.Screens.NothingSetUpKnockOn.ledger/0` writes down about its own
    # typed zero: under `:fa` the figure is `۰٫۰۰ پوند` — Persian numerals, the
    # U+066B decimal mark and the currency as a WORD after it — and a typed
    # `£0.00` would sit in Latin digits behind a Latin symbol in the middle of a
    # Persian line. English is byte-for-byte what the board draws. Not wrapped
    # in `Kati.Locale.ltr/1`: `display/1` has already put the run in the order
    # the Persian board draws it, and an isolate would pin it back to the Latin
    # one.
    #
    # The three muted eyebrows stay sentence case at the call site because
    # `Kati.UI.SettingsList.eyebrow_muted/1` upcases — a no-op on Persian, which
    # has no case — and a msgid that arrived shouting would make the translator
    # guess whether the shout is the copy or the styling.
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
        {SettingsList.title(pgettext("screen title", "Money"), gettext("FOUR STATES"))}
        {UI.eyebrow(gettext("Nothing set up — not %{total}", total: Kati.Money.display(0)))}
        {Kati.Screens.MoneyStates.nothing_set_up()}
        {SettingsList.eyebrow_muted(gettext("No watch hours yet — the first-week state"))}
        {Kati.Screens.MoneyStates.no_hours()}
        {SettingsList.eyebrow_muted(gettext("Paused — excluded from the total"))}
        {Kati.Screens.MoneyStates.paused()}
        {SettingsList.eyebrow_muted(gettext("Cancelled, with history kept"))}
        {Kati.Screens.MoneyStates.cancelled()}
      </Column>
    </Scroll>
    """
  end

  @doc """
  Screen 122's Kino, in the week before anything has been watched on it.

  `1149` is Kino's £11.49 in pence and the hours are zero, which is the argument
  `Kati.Money.per_hour/2` guards on — so the em dash this band is about is
  produced by the app's own function rather than typed in as a string. Passing
  the real price keeps the two halves of the row honest with each other: the
  figure above the dash is what is being divided.
  """
  @spec no_hours_yet() :: map()
  def no_hours_yet do
    %{
      drawn_service("K")
      | line:
          gettext("renews %{date} · nothing watched yet",
            date: Kati.Locale.date(~D[2026-09-01], :short_padded)
          ),
        rate: Kati.Money.per_hour(1149, 0),
        good?: nil
    }
  end

  @doc """
  Screen 122's Aria Audio, with the half of its line that moved into the card below.

  The fixture says `paused until October · not in the total`, which is one row
  carrying both the fact and its consequence because 122 has no room to say the
  second part anywhere else. This band does: the total card under the row states
  the exclusion in a full sentence and names the amount, so repeating it in the
  row's second line would be the same claim twice at two levels of detail.
  """
  @spec paused_service() :: map()
  def paused_service do
    %{drawn_service("A") | line: gettext("paused until October")}
  end

  @doc """
  One of screen 122's four recurring services, by name.

  By name rather than by position, because `Kati.Money.Sample.recurring/0` is
  ordered by renewal date and a service added to it would silently hand this
  sheet a different specimen under the same eyebrow.
  """
  @spec drawn_service(String.t()) :: map()
  def drawn_service(badge), do: Enum.find(Sample.recurring(), &(&1.badge == badge))

  @doc """
  An account with no services in it, which is not an account costing nothing.

  The distinction is the whole card, and it is the same one
  `Kati.Screens.MyServicesStates.region_set/0` draws one screen over with the
  same words — *Nothing to add up yet*, over `payments`, rather than a £0.00 that
  a reader would take for either a free month or a failed sum. Two screens
  reaching the same empty state should say it the same way.

  The button is drawn and inert, as 27's own `add` button is. It names where the
  services would come from, which is the one thing a reader on this card needs
  to know; wiring it would be this sheet acting on a state the app is not in.
  """
  @spec nothing_set_up() :: map()
  def nothing_set_up do
    # THE TITLE AND THE BUTTON ARE BOTH MSGIDS THIS APP ALREADY HAS.
    #
    # `Nothing to add up yet` is `Kati.Screens.MyServicesStates.region_set/0`'s
    # second row, word for word, and the doc above says why the two screens must
    # say it the same way; reaching for the same msgid is what makes that true
    # in Persian as well as in English, where it is only true because two people
    # typed the same sentence. `My services` is `Kati.Screens.MyServices`'s own
    # title. A second msgid for either would be this sheet naming a screen
    # something that screen does not call itself.
    #
    # `zero pounds` stays WORDS and is not `Kati.Money.display(0)`, which is the
    # opposite of the call the eyebrow above makes — and the board draws the
    # difference on purpose. The eyebrow says *not £0.00* about a figure, and
    # this sentence says *not zero pounds a month* about an idea; a formatter
    # here would put `£0.00` into a sentence whose whole point is that the
    # number is not the thing being denied.
    #
    # `-0.02` becomes `Kati.Locale.tracking/1` and `1.55` becomes
    # `Kati.Locale.leading/1`: tracking prises apart the joins that make Persian
    # legible, and Vazirmatn's metrics want the taller line. Both pass the Latin
    # number through unchanged, so nothing on board 123 moves.
    #
    # Hoisted rather than called in the prop, as
    # `Kati.Screens.NothingSetUpKnockOn.ledger/0` hoists its own: a `~MOB` prop
    # is read a line at a time, and a call that wraps is a call the sigil does
    # not see the end of.
    sentence =
      gettext(
        "An empty ledger, not zero pounds a month. " <>
          "Add the services you pay for and this fills in."
      )

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        padding={17}
        shadow={Kati.Theme.shadow_card_soft()}
      >
        <Spacer size={8} />
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          <Box width={52} height={52} corner_radius={16} background={Palette.paper()} align="center">
            {UI.symbol("payments", size: 24, color: Palette.rail_idle())}
          </Box>
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={14} />
        <Text
          text={gettext("Nothing to add up yet")}
          text_size={15}
          font_weight="bold"
          letter_spacing={Kati.Locale.tracking(-0.02)}
          text_color={:on_surface}
          text_align="center"
        />
        <Spacer size={7} />
        <Text
          text={sentence}
          text_size={12.5}
          line_height={Kati.Locale.leading(1.55)}
          text_color={Palette.sub()}
          text_align="center"
        />
        <Spacer size={16} />
        <Row
          fill_width={true}
          height={44}
          corner_radius={22}
          background={Palette.ink_fill()}
          align="center"
        >
          <Spacer weight={1.0} />
          <Text
            text={gettext("My services")}
            text_size={13}
            font_weight="bold"
            text_color={Palette.on_ink()}
            max_lines={1}
          />
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={8} />
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  A paid subscription with no hours against it, and the note that reads its dash.

  Eleven points between the row and the note rather than the 24 that separates
  the states, because the two are one statement: the note is about the character
  in the row's bottom-right corner, and a gap the size of a section break would
  leave it pointing at nothing.
  """
  @spec no_hours() :: map()
  def no_hours do
    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card([Kati.Screens.MoneyStates.service_row(Kati.Screens.MoneyStates.no_hours_yet())])}
      <Spacer size={11} />
      {Kati.Screens.MoneyStates.rate_note()}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  Screen 122's service row, without the tap that opens screen 23.

  Every part is 122's — `Kati.Screens.MyServices.badge_tile/1` for the letter,
  `Kati.UI.SettingsList.body/3` for the two lines, `Kati.Screens.Money.rate/1`
  for the price over its verdict — assembled by the same `row/4` at the same
  padding, so a change to any of them arrives here the next time this renders.
  Only `Kati.Screens.Money.service_row/1` itself is not called, and only because
  it carries `on_tap`; see the moduledoc for why a specimen must not navigate.

  `rule: false` on every call. Each band draws a card holding exactly one row,
  and a hairline under the last row of a card is a rule with nothing beneath it.
  """
  @spec service_row(map()) :: map()
  def service_row(service) do
    SettingsList.row(
      MyServices.badge_tile(service.badge),
      SettingsList.body(service.name, service.line),
      SettingsList.trailing(Money.rate(service)),
      rule: false
    )
  end

  @doc """
  The sentence that keeps the em dash from reading as a missing value.

  A blank cell and an undefined figure look identical on paper, and only one of
  them is a statement. The note says which this is, in the app's voice rather
  than in arithmetic: Kati has the price and has no hours, so the division has no
  answer, and it declines rather than rounding to a zero that would say the
  service is free or an infinity that would say the app has broken.

  Paper and not `Kati.UI.SettingsList.note/2`. That helper draws the outlined
  footnote frame 122 puts under its own recurring group — a caption about a list.
  This is a card about one character in the row above it, and it takes the card
  ground so that it reads as the row's second half rather than as the section's
  small print.
  """
  @spec rate_note() :: map()
  def rate_note do
    # `base: true` on the body run, because `Kati.UI.rich_text/1` otherwise
    # takes its style from the LONGEST run and the em dash is one character in
    # either script. English survives that by accident — the third run is the
    # longest — and a Persian sentence that came out shorter than it would
    # silently take the strong run's weight and lose the leading. The mark says
    # which run is the paragraph.
    body = [
      text_size: 12.5,
      line_height: Kati.Locale.leading(1.55),
      text_color: Palette.ink_soft(),
      base: true
    ]

    strong = [text_size: 12.5, font_weight: "semibold", text_color: Palette.ink()]

    # TWO MSGIDS EITHER SIDE OF THE DASH, AND THE VERB CROSSES THE BOUNDARY.
    #
    # The run split is the card's subject — the moduledoc's *the bold spans are
    # not bold* explains why the em dash is written as a run of its own — so it
    # survives the fold rather than collapsing into one sentence. Splitting a
    # sentence across msgids is normally how a translation gets a word order it
    # cannot fix, and it is safe here for the same reason
    # `Kati.Screens.MyServicesStates.reassurance/0` gives: Persian is
    # verb-final, so *reads* moves to the far side of the dash — «هزینهٔ هر
    # ساعت به‌شکل — نوشته می‌شود، …» — and the dash stays exactly where English
    # put it, between the subject and the rest of the sentence.
    #
    # The spaces live INSIDE the msgids, as
    # `Kati.Screens.ImportStates.wrong_guess/0` keeps its own: the two halves
    # break differently in Persian, where the first run ends at a preposition
    # and the second opens with the verb, and a space concatenated at the call
    # site would put it in the one place neither script wants it.
    #
    # `pgettext/2` on the short half. Three words and a trailing space is
    # exactly what `mix gettext.merge` will fuzzy-match onto some other screen's
    # sentence, and the Persian is a fragment that means nothing away from the
    # dash it leads into.
    #
    # `£0.00` is `Kati.Money.display/1` for the reason the eyebrow's is; see
    # `content/1`.
    message =
      UI.rich_text([
        {pgettext("screen 123’s rate note, before the em dash", "The rate reads "), body},
        {"—", strong},
        {gettext(
           ", never %{zero} and never infinity. Dividing by no hours has no answer, " <>
             "so Kati declines to invent one.",
           zero: Kati.Money.display(0)
         ), body}
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
        {UI.symbol("info", size: 18, color: Palette.sub())}
        <Spacer size={11} />
        <Column weight={1.0}>
          {message}
        </Column>
      </Row>
    </Column>
    """
  end

  @doc """
  A paused service keeping its row, over the total that has left it out.

  The order is the argument. Screen 122 states the rule in a footnote — *paused
  services keep their row and leave the total* — and a rule stated once is a
  promise; here the row and the figure it is missing from are stacked eleven
  points apart, so the reader can check it instead of believing it.
  """
  @spec paused() :: map()
  def paused do
    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card([Kati.Screens.MoneyStates.service_row(Kati.Screens.MoneyStates.paused_service())])}
      <Spacer size={11} />
      {Kati.Screens.MoneyStates.monthly_without_paused()}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  The monthly figure, with the paused service's price named as the thing outside it.

  The sentence names Aria and names the row's own £5.00 — `drawn_service/1`'s,
  not a second copy of it — which is the only way a total can be checked: a
  figure that merely claimed to exclude something would be asking to be trusted
  about the one thing this band exists to show. See the moduledoc for
  why £34.48 is the board's figure rather than a sum computed here, and why the
  label is taken from `Kati.Money.Sample.monthly/0` while the figure is not.
  """
  @spec monthly_without_paused() :: map()
  def monthly_without_paused do
    # `Kati.UI.eyebrow_label/1` where this upcased by hand, which is screen
    # 122's own expression for the same fixture word — its cream hero draws
    # `eyebrow_label(@m.label)`. Persian has no case, so `String.upcase/1` on
    # **هر ماه** returns it unchanged: the call did nothing and read as though
    # something had been done. The helper says so out loud.
    label = UI.eyebrow_label(Sample.monthly().label)

    # The amount in the sentence is READ OFF THE FIXTURE rather than retyped,
    # which is what the moduledoc already claims about it — *it is the price the
    # fixture carries* — and was true of the drawing and not of the code. A
    # sentence that names an amount as the thing a total excludes is checkable
    # only if it is the same amount the row above it draws, and `£5.00` typed
    # here would have gone on saying so after screen 92 repriced Aria.
    #
    # `Aria` stays inside the msgid rather than arriving as `%{service}`. The
    # board writes the short form and the fixture carries `Aria Audio`, so
    # interpolating would change the English copy to make the Persian easier;
    # and the catalogue already answers **آریا آدیو** for that fixture name, so
    # the translator writes the same آریا this sentence needs rather than
    # inventing a second spelling. It is not one of the real provider names
    # board 127 keeps in Latin — those are services that exist.
    #
    # No `Kati.Locale.ltr/1` around the amount: `display/1` has already laid the
    # run out the way the Persian board draws a price, and an isolate would pin
    # it back to the Latin order.
    note =
      gettext("Aria’s %{amount} is not in this figure while it is paused.",
        amount: drawn_service("A").price
      )

    # The figure is still the board's `£34.48` and is still not a sum — see the
    # moduledoc — but it is a PRICE, so it goes through the app's one money
    # formatter rather than staying a typed string. `3448` is those pence, and
    # under `:fa` the card reads **۳۴٫۴۸ پوند**: Persian numerals, U+066B for
    # the point, the currency as a word after the figure, exactly as
    # `Kati.Money.Sample.monthly/0` renders 122's own hero beside it. A typed
    # `£34.48` would have been the one figure on a Persian page still in Latin
    # digits behind a Latin symbol.
    assigns = %{label: label, total: Kati.Money.display(3448), note: note}

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      padding={15}
      shadow={Kati.Theme.shadow_card_soft()}
    >
      <Row fill_width={true} align="bottom">
        <Text
          text={@label}
          font_family={Kati.Locale.mono_face()}
          text_size={10.5}
          letter_spacing={Kati.Locale.tracking(0.14)}
          text_color={Palette.eyebrow()}
        />
        <Spacer weight={1.0} />
        <Text
          text={@total}
          font_family={Kati.Locale.mono_face()}
          text_size={18}
          text_color={:on_surface}
          max_lines={1}
        />
      </Row>
      <Spacer size={10} />
      <Text
        text={@note}
        text_size={12}
        line_height={Kati.Locale.leading(1.5)}
        text_color={Palette.sub()}
      />
    </Column>
    """
  end

  @doc """
  A service cancelled, and the hours it leaves behind.

  This is the state where money and history part company. Cancelling takes a
  service out of the active list and out of the monthly figure, and it must not
  touch the watching — those thirty-one hours happened, and a ledger that deleted
  them to keep its own list tidy would be rewriting what the reader did.

  `Kati.Screens.MyServicesStates.advice/5` at its own defaults, which are this
  card's numbers exactly: radius 20, 15 of padding, a 19pt glyph top-aligned
  against a 13.5pt title, six points of gap. Two states sheets drawing the same
  card from one builder is the point of it being public.

  `history` in `Kati.Theme.Palette.sub/0` and not `error` in red, which is 95's
  distinction for the same event: a service you stopped paying for is a fact you
  told Kati, and a red glyph would make the log look like a casualty of it.
  """
  @spec cancelled() :: map()
  def cancelled do
    body = [
      text_size: 12.5,
      line_height: Kati.Locale.leading(1.6),
      text_color: Palette.ink_soft(),
      base: true
    ]

    strong = [text_size: 12.5, font_weight: "semibold", text_color: Palette.ink()]

    # `ngettext/4` on the emphasised run, over the catalogue's existing
    # `%{n} hour` — `Kati.Money.Sample.suggestion/0`'s own plural, which is the
    # fixture this whole sheet is drawn from. The count is frozen at 31 and that
    # is still the right form: English inflects the noun after a numeral and
    # Persian does not, so both Persian forms are one sentence, which is what
    # `Kati.Screens.MyServicesStates.removed_service/0` records for its own
    # frozen count. The digits go through `Kati.Locale.number/1` inside it, so
    # the run reads **۳۱ ساعت** rather than Latin numerals mid-sentence.
    #
    # `07` stays inside the third msgid. It is a screen reference in a sentence
    # — the way `Kati.Screens.MyServices.credit/0` writes *credited on 83* and
    # `removed_service/0` keeps its own `15` — rather than a figure this page
    # computes, so the translator writes it in the reader's own digits.
    #
    # The two body runs keep their spaces inside the msgids, and the emphasis
    # survives the fold for the reason it does in `rate_note/0`: Persian is
    # verb-final, so *still count toward 07* lands after the hours exactly as
    # English puts it, and *Its* moves to the far side of the boundary as a
    # trailing آن. `base: true` for the same reason as well — the strong run is
    # now a whole phrase, and in Persian it must not be allowed to win the
    # longest-run vote and hand the paragraph its weight.
    message =
      UI.rich_text([
        {gettext("Out of the active list and out of the monthly figure. Its "), body},
        {ngettext("%{n} hour", "%{n} hours", 31, n: Kati.Locale.number(31)), strong},
        {gettext(" still count toward 07, because you did watch them."), body}
      ])

    # THE SERVICE NAME IS LATIN IN BOTH SCRIPTS AND THE DATE IS NEITHER.
    #
    # `Dispatch` is a real-shaped service name — `Kati.Services.Sample` carries
    # it beside Orbit, and screen 92 draws it — so it stays in Latin on a
    # Persian page the way board 127 draws `Lumen+`, and takes
    # `Kati.Locale.ltr/1` because the em dash that follows it is NEUTRAL to the
    # bidi algorithm: without the isolate it resolves against the paragraph and
    # lays itself in front of the name instead of after it. Screen 83's licence
    # notices are where that was found.
    #
    # `2 Jun` becomes a real `Date` through `Kati.Locale.date/2`, which is the
    # half of mishka-group/kati#103 a catalogue cannot do: under `:fa` this is
    # not *2 Jun* translated but ۱۲ خرداد, the same day counted in the reader's
    # own calendar. `:short` is the day-and-month shape, which is what the board
    # draws and what a title wants.
    title =
      gettext("%{service} — cancelled %{date}",
        service: Kati.Locale.ltr("Dispatch"),
        date: Kati.Locale.date(~D[2026-06-02], :short)
      )

    MyServicesStates.advice("history", Palette.sub(), title, message)
  end
end
