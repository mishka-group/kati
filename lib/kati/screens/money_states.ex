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
  the price the fixture carries.

  The label is `Kati.Money.Sample.monthly/0`'s, upcased. Screen 122's cream hero
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
        {SettingsList.title("Money", "FOUR STATES")}
        {UI.eyebrow("Nothing set up — not £0.00")}
        {Kati.Screens.MoneyStates.nothing_set_up()}
        {SettingsList.eyebrow_muted("No watch hours yet — the first-week state")}
        {Kati.Screens.MoneyStates.no_hours()}
        {SettingsList.eyebrow_muted("Paused — excluded from the total")}
        {Kati.Screens.MoneyStates.paused()}
        {SettingsList.eyebrow_muted("Cancelled, with history kept")}
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
      drawn_service("Kino")
      | line: "renews 01 Sep · nothing watched yet",
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
    %{drawn_service("Aria Audio") | line: "paused until October"}
  end

  @doc """
  One of screen 122's four recurring services, by name.

  By name rather than by position, because `Kati.Money.Sample.recurring/0` is
  ordered by renewal date and a service added to it would silently hand this
  sheet a different specimen under the same eyebrow.
  """
  @spec drawn_service(String.t()) :: map()
  def drawn_service(name), do: Enum.find(Sample.recurring(), &(&1.name == name))

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
          text="Nothing to add up yet"
          text_size={15}
          font_weight="bold"
          letter_spacing={-0.02}
          text_color={:on_surface}
          text_align="center"
        />
        <Spacer size={7} />
        <Text
          text="An empty ledger, not zero pounds a month. Add the services you pay for and this fills in."
          text_size={12.5}
          line_height={1.55}
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
            text="My services"
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
    body = [text_size: 12.5, line_height: 1.55, text_color: Palette.ink_soft()]
    strong = [text_size: 12.5, font_weight: "semibold", text_color: Palette.ink()]

    message =
      UI.rich_text([
        {"The rate reads ", body},
        {"—", strong},
        {", never £0.00 and never infinity. Dividing by no hours has no answer, so Kati declines to invent one.",
         body}
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

  The sentence names Aria and names £5.00, which is the only way a total can be
  checked: a figure that merely claimed to exclude something would be asking to
  be trusted about the one thing this band exists to show. See the moduledoc for
  why £34.48 is the board's figure rather than a sum computed here, and why the
  label is taken from `Kati.Money.Sample.monthly/0` while the figure is not.
  """
  @spec monthly_without_paused() :: map()
  def monthly_without_paused do
    label = String.upcase(Sample.monthly().label)
    assigns = %{label: label}

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
          font_family="mono"
          text_size={10.5}
          letter_spacing={0.14}
          text_color={Palette.eyebrow()}
        />
        <Spacer weight={1.0} />
        <Text
          text="£34.48"
          font_family="mono"
          text_size={18}
          text_color={:on_surface}
          max_lines={1}
        />
      </Row>
      <Spacer size={10} />
      <Text
        text="Aria’s £5.00 is not in this figure while it is paused."
        text_size={12}
        line_height={1.5}
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
    body = [text_size: 12.5, line_height: 1.6, text_color: Palette.ink_soft()]
    strong = [text_size: 12.5, font_weight: "semibold", text_color: Palette.ink()]

    message =
      UI.rich_text([
        {"Out of the active list and out of the monthly figure. Its ", body},
        {"31 hours", strong},
        {" still count toward 07, because you did watch them.", body}
      ])

    MyServicesStates.advice(
      "history",
      Palette.sub(),
      "Dispatch — cancelled 2 Jun",
      message
    )
  end
end
