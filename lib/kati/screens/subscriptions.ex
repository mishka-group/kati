defmodule Kati.Screens.Subscriptions do
  @moduledoc """
  Screen 23 — Subscriptions, pushed under Stats.

  Built to `test/design/screens/23.html`. The money section, and the
  drawing says plainly why it belongs in this app rather than a finance one:
  *"cost per watched hour is the one subscription number no finance app can
  compute for you."* The price comes from a bank; the hours come from the
  Screen shelf; only here do they meet.

  So the rate is the point of the list, and it is coloured rather than merely
  printed — green at £0.21/h, `#B4553C` at £2.33/h. That red is the same token
  `Kati.Theme.red/0` uses for an error, which is the design being blunt: an
  hour of television costing more than a cinema ticket is a fault, not a
  statistic.

  Details taken literally from the export:

    * The back pill shares its row with a `more_horiz` disc, so unlike screens
      15 and 22 that row is 44 tall rather than 42 — the disc sets the height.
    * "Worth a look" gets the grey dash (`Kati.UI.Eyebrow.quiet/1`): a
      suggestion the app is offering is not new and not now.
    * The paused row drops its rate entirely and greys both its lines. It is
      the one row where the right-hand column is a single value.

  The suggestion's body is drawn with `6 hours` and `1 title` in bold inside a
  wrapping paragraph. Mob's `Text` carries one weight, and a paragraph
  assembled from separate runs breaks at the wrong words, so it renders as one
  run — recorded here because it is a real loss against the drawing, not an
  oversight.

  No dock on a pushed screen, so the frame ends at 40 rather than 132.

  ## What the two buttons do, and what they deliberately do not

  The suggestion card is the only thing on this screen that can move, and it
  moves in exactly the two directions the drawing's own buttons name:

    * **Dismiss** retires the suggestion — the card *and* the "Worth a look"
      eyebrow above it, since an eyebrow labelling nothing is worse than no
      eyebrow. Nothing takes their place.
    * **Remind me 23 Aug** marks the offer as taken: the primary button changes
      into the card's own secondary treatment (`#EFECE7` on `#5C574F` — the
      Dismiss chip's two colours, already in this row). Tapping again cancels.

  The label does not change and no tick appears, because the drawing has no
  "reminder set" wording and inventing one would be inventing a screen. The
  weight change is therefore the whole signal, and that is a real loss against
  a drawing that never had to show this state.

  **Nothing is actually scheduled.** `Kati.Notifications.Scheduler` is a
  planned child of `Kati.Supervisor` (#59) and is not built, so `:remind`
  records that you asked and nothing more. When the scheduler lands this is
  where it gets called; until then the button must not claim otherwise.

  Both states start off, so the resting screen is the drawing exactly.

  ## Why this screen is still on `Kati.Subscriptions.Sample`

  This section used to open *no table anywhere holds a price*, and that stopped
  being true. `Kati.Services.Service` carries `monthly_pence` and `currency`,
  screen 92 owns them and says so on the page, and since #95 a person can put a
  service into that table themselves — the `Something else` row, through
  `Kati.Screens.MyServices.save_service/1`. So a price has a home and a door
  now, and the paragraph claiming otherwise would have sent the next reader off
  to build one that exists.

  What it does not have is a **figure**, and that is why this screen has not
  moved. `Something else` writes a name and no price, because band 6 of ticket
  `D-10` asks for an editable price and no artboard in the set draws the editor.
  A service created today is a row with `monthly_pence: nil`, which screen 92
  renders honestly as a name with a blank right-hand column and this screen
  could only render as `£0.00` or as a hole. Neither is one of the four rows the
  drawing has.

  And there is no control on **this** screen to fix that with. 23.html holds one
  `more_horiz` and no menu, sheet or popover anywhere in the export — see
  `handle_tap/2`'s last clause — so a *New subscription* sheet here would be a
  screen invented rather than built, which is the one thing 152 drawn artboards
  exist to make unnecessary.

  The rest of the gap is untouched by any of that, and it is the part the screen
  is actually about. The nearest thing that exists is
  `Kati.Calendars.Event.kind`'s `:money`
  value, and the deleted `Kati.Seeds` used to write two renewal events with a
  price in the `description`. That was not a source and must not become one:

    * It is **two** of the four services the card lists, seeded only because
      screen 09 merges them into one *"2 renewals · £22.98"* row.
    * The price rides in `description`, which is free text on a calendar event.
      Parsing money out of a description would make the total depend on how
      somebody phrased a reminder.
    * A renewal event is a **date**. It says nothing about whether a service is
      paused, what it cost last month, or what it costs per month at all.

  And the number the screen exists for is further away still. *"Cost per
  watched hour is the one subscription number no finance app can compute for
  you"* needs the hours as well as the price, and `Kati.Media.Watch` records
  that an episode was watched — not for how long. `Kati.Media.CachedTitle`
  carries `runtime_minutes`, so hours per *service* would additionally need a
  provider→service mapping, which nothing holds either.

  So the ask here was a domain, not a column: a service with a price and a
  cadence, a link from a tracked title to the service that carries it, and a
  duration on a watch. The first of the three landed with `Kati.Services`; the
  other two have not, and the rate is the one this screen exists for. Until they
  do, every row here is the drawing's, and a screen half-priced from a table
  that holds names without figures would be worse than one that is honestly a
  drawing.
  """
  # `My services`, not `Stats`. Board 23's pill reads Stats and the only route
  # into this page is screen 92's Money row — so the
  # word and the gesture disagreed. `Kati.Screens.Pushed.back_label/2` takes a
  # caller's own word ahead of this one, so a door that opens it from anywhere
  # else says so without touching this line.
  use Kati.Screens.Pushed, back: "My services"
  use Gettext, backend: Kati.Gettext

  alias Kati.Subscriptions.Sample
  alias Kati.Theme.Palette
  alias Kati.UI

  @impl true
  def load(socket) do
    Mob.Socket.assign(socket,
      ledger: Kati.Screens.Subscriptions.ledger(),
      # Read once, at mount, and carried — so the page cannot change its mind
      # mid-render, and so a captured frame can put this screen in the state
      # its own board draws without writing a service into the store.
      set_up?: Kati.Screens.NothingSetUpKnockOn.set_up?(),
      # Read from the store, not assumed true. `Dismiss` used to be a socket
      # assign and nothing else, so the card came back on the next mount.
      suggestion: Kati.Screens.Subscriptions.offer?(),
      reminded: false
    )
  end

  @doc """
  The ledger this page draws: the reader's, or the drawing's.

  All-or-nothing, the gate screens 04 and 92 keep: a page with the reader's
  one service in it and the drawing's other three under it reads as entirely
  real and is three-quarters invented.
  """
  @spec ledger() :: map()
  def ledger, do: Kati.Subscriptions.ledger() || Kati.Screens.Subscriptions.empty_ledger()

  @doc """
  The ledger with nothing subscribed.

  `drawn_ledger/0`'s shape at zero. It was the drawing — `5 active`, `£46.47`,
  `Up £4.00` and four services — so a reader who pays for nothing was shown a
  bill, on a page about money.

  `Kati.Subscriptions.ledger/0` answers nil both for an empty list and from a
  `rescue`, and neither is a reason to invent a total: a database Kati cannot
  read has not told it what anybody spends.
  """
  @spec empty_ledger() :: map()
  def empty_ledger do
    %{
      active_line: Kati.Subscriptions.active_line([]),
      monthly: %{
        label: "Every month",
        total: "—",
        change_lead: nil,
        change_amount: nil,
        change_rest: nil
      },
      services: [],
      suggestion: nil
    }
  end

  @doc "Board 23 exactly as it is drawn, from `Kati.Subscriptions.Sample`."
  @spec drawn_ledger() :: map()
  def drawn_ledger do
    %{
      active_line: Sample.active_line(),
      monthly: Sample.monthly(),
      services: Sample.services(),
      suggestion: Sample.suggestion()
    }
  end

  @doc false
  def content(assigns) do
    shown? = assigns.suggestion
    reminded? = assigns.reminded
    ledger = assigns[:ledger] || Kati.Screens.Subscriptions.ledger()

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {Kati.Screens.Subscriptions.back_row()}
        {Kati.Screens.Subscriptions.body(ledger, shown?, reminded?, Map.get(assigns, :set_up?, true))}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The page, or board 96's fourth band in place of it.

  Screen 96 draws *an empty ledger* — **No subscriptions
  yet**, and explicitly not `£0.00 a month`, because a zero total is a sentence
  about your spending and it would be false. Nothing in the app could ever
  enter that state: this screen fell back to `Kati.Subscriptions.Sample` when
  the store had nothing, so a reader with no services was shown somebody
  else's four.

  The band's own note says what the decision takes out with it — the delta
  badge, the per-service rows and the Worth-a-look card, all of which would
  otherwise report a change of nothing against nothing — so this branch draws
  none of them rather than drawing them empty.

  `set_up?/0` could not answer `false` until #75 took the fixture fallback off
  `Kati.Screens.MyServices.listed/0`; screen 96's moduledoc named exactly that
  as the change these four bands were waiting on.
  """
  @spec body(map(), boolean(), boolean(), boolean()) :: term()
  def body(ledger, shown?, reminded?, set_up?) do
    if set_up? do
      [
        Kati.Screens.Subscriptions.title(ledger),
        Kati.Screens.Subscriptions.monthly(ledger),
        UI.eyebrow(gettext("Services")),
        Kati.Screens.Subscriptions.services(ledger),
        Kati.Screens.Subscriptions.suggestion(ledger.suggestion, shown?, reminded?)
      ]
    else
      # ONE replaced section, which is board 96's own caption: *each band is a
      # single replaced section of a screen that already exists*. The page keeps
      # its header — 23 still has a page — and what goes is the ledger under it:
      # the monthly total, the services and the Worth-a-look card, all three of
      # which would otherwise report a change of nothing against nothing.
      #
      # The msgid keeps the board's capitals and the Persian does not try to
      # carry them: this line is drawn by `title/1` rather than passed through
      # `Kati.UI.eyebrow_label/1`, so what the catalogue answers is what is
      # drawn, and Arabic script has no case to shout in. `Kati.Money.Sample`'s
      # `SCREEN` / `BOOKS` / `MEALS` are the same shape — an all-caps msgid
      # against a natural Persian word.
      [
        Kati.Screens.Subscriptions.title(%{ledger | active_line: gettext("NONE YET")}),
        Kati.Screens.NothingSetUpKnockOn.ledger()
      ]
    end
  end

  # The back pill itself is drawn by Kati.Screens.Pushed as floating chrome;
  # this row reserves its height and carries the overflow disc opposite it.
  @doc false
  def back_row do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Spacer weight={1.0} />
        {Kati.Screens.Subscriptions.disc()}
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  The 44pt `more_horiz` disc that shares the back pill's row.

  `Kati.Components.MishkaActionIcon`, which is what a round tap target holding
  one glyph is. It could not be until the port grew a `shadow` prop: this disc
  floats off paper on `Kati.Theme.shadow_button()`, and a disc without its
  shadow is a flat patch rather than a control sitting above the page.

  **The pixels are the same node.** The port builds

      <Box width={44} height={44} align={:center} corner_radius={22.0}
           background=… shadow=… on_tap=…><Row>{glyph}</Row></Box>

  against the `<Box width={44} height={44} background corner_radius={22} shadow
  align="center" on_tap>` this was, prop for prop: `shape: :circle` resolves to
  an exact `size / 2` and 44 gives the drawing's 22, `variant: :filled` is what
  lets `background` through (the port paints `:transparent` on the default
  `:plain`), and `align={:center}` serialises to the same `"center"` string.
  The added `Row` carries no props, so it takes no modifier and hugs its one
  child — the glyph measures and centres exactly where it did.
  """
  def disc do
    Kati.Components.MishkaActionIcon.action_icon(
      [
        size: 44,
        shape: :circle,
        variant: :filled,
        background: Palette.card(),
        shadow: Kati.Theme.shadow_button()
      ],
      [Kati.UI.symbol("more_horiz", size: 21)]
    )
  end

  @doc """
  The page's name and, under it, how many services are on the account.

  `mono_face/1` on the second line rather than `mono_face/0`, because this one
  slot holds two different kinds of string. `Kati.Subscriptions.active_line/1`
  counts the reader's services and `Kati.Subscriptions.Sample.active_line/0`
  draws the board's `5 active`, both of which are figures the design sets in
  DM Mono; `body/4` puts the ledger's empty-state word here instead, which is
  the reader's own language and which
  `kati_mono.ttf` has no glyph for. Asking the STRING means the answer stays
  right when the ledger's own copy folds — see `Kati.Locale.mono_face/1`.

  The 28pt heading loses its tracking under `:fa` and gains `max_lines={1}`:
  a fraction of an em taken out between letters breaks the joins Arabic script
  is written with, and a heading that is one word in English can be two in
  Persian, which at 28pt on a 1.6 font scale would wrap into the mono line
  underneath it rather than under the pill.
  """
  @spec title(map()) :: map()
  def title(ledger) do
    assigns = %{active_line: ledger.active_line, title: gettext("Subscriptions")}

    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={@title}
        text_size={28}
        max_font_scale={1.6}
        font_weight="bold"
        letter_spacing={Kati.Locale.tracking(-0.03)}
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer size={5} />
      <Text
        text={@active_line}
        font_family={Kati.Locale.mono_face(@active_line)}
        text_size={11}
        text_color={Palette.muted()}
        max_lines={1}
      />
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  The cream hero: what leaves the account every month, and what changed.

  `Kati.UI.eyebrow_label/1` in place of `String.upcase/1` on the label. Arabic
  script has no case, so the upcasing was a no-op that still *read* as one —
  a Persian eyebrow beside an English one looked like the catalogue had been
  given the wrong word rather than like a script that does not shout. The
  helper upcases in Latin and leaves the Persian alone, which is what screen
  122 does with the same label on the same card (`Kati.Screens.Money.hero/0`).

  The label's face follows its own string for the reason `title/1` gives, and
  its tracking goes with the script.
  """
  @spec monthly(map()) :: map()
  def monthly(ledger) do
    m = ledger.monthly

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.cream()}
        corner_radius={24}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={19}
      >
        <Text
          text={Kati.UI.eyebrow_label(m.label)}
          font_family={Kati.Locale.mono_face(m.label)}
          text_size={10.5}
          letter_spacing={Kati.Locale.tracking(0.16)}
          text_color={Palette.cream_meta()}
        />
        <Spacer size={7} />
        <Text
          text={m.total}
          text_size={36}
          font_weight="extrabold"
          letter_spacing={Kati.Locale.tracking(-0.04)}
          text_color={:on_surface}
          max_lines={1}
        />
        {Kati.Screens.Subscriptions.change_line(m)}
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  `↗ Up £4.00 since March — Orbit raised its price`, or nothing at all.

  Nothing at all is what a real account gets, and will until something records
  what a price used to be: `Kati.Services.Service` holds the price a service
  is at, not the one it was. Board 23 draws the line because board 23's reader
  had a rise; inventing one for anybody else would be inventing the number
  this page is about.
  """
  @spec change_line(map()) :: map()
  def change_line(%{change_amount: nil}), do: ~MOB"<Spacer size={0} />"

  def change_line(m) do
    assigns = %{lead: m.change_lead, amount: m.change_amount, rest: m.change_rest}

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={12} />
      <Row fill_width={true} align="center">
        {Kati.UI.symbol("trending_up", size: 15, color: Palette.red())}
        <Spacer size={7} />
        <Text text={@lead} text_size={12.5} text_color={Palette.cream_sub()} max_lines={1} />
        <Spacer size={4} />
        <Text
          text={@amount}
          text_size={12.5}
          font_weight="semibold"
          text_color={:on_surface}
          max_lines={1}
        />
        <Spacer size={4} />
        <Text text={@rest} text_size={12.5} text_color={Palette.cream_sub()} max_lines={1} />
        <Spacer weight={1.0} />
      </Row>
    </Column>
    """
  end

  @doc false
  def services(ledger) do
    rows = ledger.services
    last = length(rows) - 1

    children =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, i} -> service_row(row, i < last) end)

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={15}
        padding_right={15}
        padding_top={4}
        padding_bottom={4}
      >
        {children}
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  One service on the ledger, and the door to the page about it.

  Boards 252 and 302 draw a per-service page and it had no way in: screen 92's
  row is #119's price editor and owns that gesture, so the door is here, on the
  page whose rows already ARE one service each. That page is where `paused` and
  `renews_on` are set — two columns this screen READS (a paused row greys and
  drops its rate) and nothing could write.

  A drawn row carries no name to look up, so it draws no tap: the fixture's
  services are not the reader's, and `Kati.Screens.Service.find/1` would answer
  `nil` for every one of them.
  """
  @spec service_row(map(), boolean()) :: map()
  def service_row(row, rule?) do
    paused? = Map.get(row, :paused, false)
    name_color = if paused?, do: Palette.sub(), else: Palette.ink()
    line_color = if paused?, do: Palette.tertiary(), else: Palette.sub()
    tap = Kati.Screens.Subscriptions.service_tap(row)

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={14} padding_bottom={14} on_tap={tap}>
        {Kati.Screens.Subscriptions.badge(row.badge)}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text
            text={row.name}
            text_size={13.5}
            font_weight="semibold"
            text_color={name_color}
            max_lines={1}
          />
          {Kati.Screens.Subscriptions.row_line(row.line, line_color)}
        </Column>
        <Spacer size={13} />
        {Kati.Screens.Subscriptions.money(row, paused?)}
      </Row>
      {Kati.Screens.Subscriptions.hairline(rule?)}
    </Column>
    """
  end

  @doc """
  The line under a service's name, or nothing.

  `nil` is an ordinary answer: a service with no renewal date and nothing
  watched on it has nothing to put here. The `Text` was unconditional and a
  `nil` reached the bridge, which renders it as the four letters `nil` — the
  device found that in the first minute of looking at this page, and it is
  the class of defect `Kati.Write.message/1` exists to stop one layer down.
  """
  @spec row_line(String.t() | nil, term()) :: map()
  def row_line(nil, _colour), do: ~MOB"<Spacer size={0} />"

  def row_line(line, colour) do
    assigns = %{line: line, colour: colour}

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={3} />
      <Text text={@line} text_size={11.5} text_color={@colour} max_lines={1} />
    </Column>
    """
  end

  @doc """
  The service's letter on its 32pt paper tile.

  `Kati.Components.MishkaAvatar` with `shape: :rounded`, which is what this is:
  an avatar whose fallback is the initial, for services that ship no logo. The
  port's `:rounded` radius is a flat 10 at any size, which is the drawing's own
  radius here — so `size: 32, shape: :rounded` reproduces the tile exactly and
  nothing is passed twice.

  The letter goes in as a **child** rather than as `initials`, and that is the
  reason the pixels are unchanged: `initials` is drawn by the component's own
  `Text`, which carries no `font_family`, and this badge is mono. A child
  replaces that `Text` wholesale, so the drawing's mono at 13 survives. An
  `initials_font_family` prop upstream would let this be one line instead of
  two; until there is one, the child is what keeps the mono — and, since
  mishka-group/kati#103, what lets the face follow the letter rather than be
  fixed at a typeface that has no Persian in it.
  """
  def badge(letter) do
    # The face follows the LETTER, not the reader. `Kati.Services.Service.badge/1`
    # takes the first character of the service's own name, so a service the
    # reader typed in Persian — the `Something else` row on screen 92 — gives a
    # Persian initial, and DM Mono has no glyph for it. `Lumen+` still gives
    # `L` and still sets in DM Mono on a Persian page, which is the same
    # decision the brand names themselves get on board 127.
    glyph = ~MOB"""
    <Text
      text={letter}
      font_family={Kati.Locale.mono_face(letter)}
      text_size={13}
      text_color={:on_surface}
      max_lines={1}
    />
    """

    Kati.Components.MishkaAvatar.avatar(
      [size: 32, shape: :rounded, background: Palette.paper()],
      [glyph]
    )
  end

  # A paused service has one value on the right, not two: it has no rate,
  # because £5.00 buying nothing is not a price per hour. Two clauses rather
  # than a nil-rate branch, so the shapes stay honestly different.
  @doc false
  def money(%{price: nil}, _paused?), do: ~MOB"<Spacer size={0} />"

  def money(row, true) do
    ~MOB"""
    <Text
      text={row.price}
      font_family={Kati.Locale.mono_face(row.price)}
      text_size={12}
      text_color={Palette.tertiary()}
      max_lines={1}
    />
    """
  end

  # 46 wide, not hugging. `text_align="right"` makes a Text fillMaxWidth on
  # this bridge — the defect that flattened screen 08's rating card — so it
  # only behaves inside a column of declared width. 46 clears the widest value
  # the drawing carries (`£13.99` at mono 12).
  def money(row, false) do
    # Two faces asked separately, because these two slots are not the same kind
    # of string. A price is a figure the design sets in DM Mono and keeps in
    # Latin digits in both scripts — `Kati.Locale.number/1`'s own note — so it
    # stays in DM Mono. The rate is a figure OR a sentence:
    # `Kati.Subscriptions.rate/2` answers `Not used yet` for a service with no
    # hours on it, which is copy and which folds to Persian, and DM Mono would
    # hand that to Android's substitute face. `mono_face/1` asks the string
    # rather than the reader, so each slot gets the right one on one page.
    rate = row.rate || ""

    ~MOB"""
    <Column width={46}>
      <Text
        text={row.price}
        font_family={Kati.Locale.mono_face(row.price)}
        text_size={12}
        font_weight="medium"
        text_color={:on_surface}
        text_align="right"
        max_lines={1}
      />
      <Spacer size={3} />
      <Text
        text={rate}
        font_family={Kati.Locale.mono_face(rate)}
        text_size={10}
        text_color={row.rate_tone}
        text_align="right"
        max_lines={1}
      />
    </Column>
    """
  end

  # The eyebrow lives in here rather than in `content/1` so that Dismiss takes
  # the label away with the card it labels.
  #
  # A two-element LIST, not a wrapping Column. `content/1` interpolates it into
  # the same slot the eyebrow and the card occupied separately, so the tree it
  # produces at rest is the one this screen produced before the buttons worked —
  # identical, not merely equivalent. A wrapper Column would almost certainly
  # have laid out the same; "almost certainly" is not what the frame comparison
  # is measured in.
  @doc false
  # `nil` is the third state and the important one: a reader whose every
  # service is being used has nothing worth a look, and a card that appeared
  # every month regardless would be a card nobody reads. Board 23 always draws
  # it because board 23's reader is paying £13.99 for six hours.
  def suggestion(nil, _shown?, _reminded?), do: ~MOB"<Spacer size={0} />"
  def suggestion(_advice, false, _reminded?), do: ~MOB"<Spacer size={0} />"

  def suggestion(advice, true, reminded?) do
    [
      Kati.UI.Eyebrow.quiet(gettext("Worth a look")),
      Kati.Screens.Subscriptions.advice(advice, reminded?)
    ]
  end

  @doc """
  The suggestion card: one wrapping paragraph, and the two buttons under it.

  The body takes `Kati.Locale.leading/1` rather than the drawing's flat 1.55.
  It is the only paragraph on this screen that wraps — the moduledoc records
  why it is one run rather than the drawing's three bolded ones — and
  Vazirmatn's ascenders and descenders are not Plus Jakarta's, so 1.55 set on
  the Latin card crowds the Persian one. `Kati.Locale.leading/1` carries the
  Persian number and keeps the drawing's own beside it at the call site, which
  is the point of that helper: a card that differs by a leading should say so
  where it differs.
  """
  @spec advice(map(), boolean()) :: map()
  def advice(s, reminded?) do
    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={17}
    >
      <Row fill_width={true} align="top">
        {Kati.UI.symbol("lightbulb", size: 19, color: Palette.accent())}
        <Spacer size={11} />
        <Text
          text={s.body}
          text_size={13}
          line_height={Kati.Locale.leading(1.55)}
          text_color={Palette.cream_body()}
          weight={1.0}
        />
      </Row>
      <Spacer size={15} />
      <Row fill_width={true} align="center">
        {Kati.Screens.Subscriptions.confirm_slot(s, reminded?)}
        {Kati.Screens.Subscriptions.dismiss(s.dismiss)}
      </Row>
    </Column>
    """
  end

  @doc """
  The primary button, or nothing at all.

  Nothing when the service has no renewal date: no reminder exists for it
  anywhere, so a button offering one would be the lie this whole change is
  removing. *Dismiss* still stands on its own — the card is still worth
  reading, it just has one answer instead of two.
  """
  @spec confirm_slot(map(), boolean()) :: map()
  def confirm_slot(%{remind_on: nil}, _reminded?), do: ~MOB"<Spacer size={0} />"

  def confirm_slot(s, reminded?) do
    assigns = %{
      button: Kati.Screens.Subscriptions.confirm(confirm_label(s, reminded?), reminded?)
    }

    ~MOB"""
    <Row weight={1.0} align="center">
      {@button}
      <Spacer size={9} />
    </Row>
    """
  end

  @doc """
  What the primary button says — *Remind me*, or when the reminder arrives.

  `other_tap(:remind, …)` flipped a socket boolean and the button changed to its
  secondary treatment. Nothing was armed, and the audit recorded the
  reason as `Kati.Notifications.Scheduler` not being built. **That reason is no
  longer true, and it turned out not to be the problem.**

  `Kati.Notifications.Sources.Money.candidates/3` arms a renewal reminder for
  every subscribed service that has a `renews_on` date — unconditionally, with
  no opt-in anywhere. So there was never anything for this button to arm: the
  reminder it offers already exists. What it could not do was **say so**.

  Pressed, it names the day. `Kati.Subscriptions.remind_on/1` counts back from
  the renewal using the scheduler's own `lead_days/0`, so the card and the
  thing that fires cannot name different days.

  A service with no renewal date gets no reminder from anywhere, and
  `confirm/2`'s caller drops the button entirely rather than offering one — the
  rule `Kati.Screens.Season` states for *Merge multi-part*: a control that
  cannot be honoured is not offered.
  """
  @spec confirm_label(map(), boolean()) :: String.t()
  def confirm_label(%{remind_on: %Date{} = on}, true),
    do: gettext("Reminder set · %{date}", date: Kati.Locale.date(on, :short))

  def confirm_label(s, _reminded?), do: s.confirm

  # Two clauses, not a pair of conditional colours, because these are the card's
  # two drawn button treatments and not a spectrum: ink on paper for the primary,
  # `#EFECE7` on `#5C574F` for the secondary. "Already asked for" is the primary
  # wearing the secondary's clothes — no new colour enters the card.
  #
  # The primary is `ink_fill` / `on_ink`, which is the pair screen 28 inverts:
  # ink filled with paper in light, paper filled with ink in dark. It is NOT
  # `ink` / `card`, whose light values are the same two numbers and whose dark
  # values would leave this button ink-on-ink.
  @doc false
  def confirm(label, false), do: confirm_button(label, Palette.ink_fill(), Palette.on_ink())
  def confirm(label, true), do: confirm_button(label, Palette.paper(), Palette.ink_soft())

  @doc """
  The primary button of the suggestion card, sharing its row with `dismiss/1`.

  This is the closest thing on the screen to `Kati.Components.MishkaChip`, and
  the fit is closer than it looks: the two treatments `confirm/2` chooses between
  are precisely a chip's checked and unchecked fills, and `checked: reminded?`
  with `color` / `text_color` for the armed pair and `unchecked_color` /
  `unchecked_text_color` for the loud one says exactly what the two clauses say.
  Since the chip took `height`, `padding_x` / `padding_y`, `corner_radius`,
  `text_size`, `font_weight` and `max_lines`, every number here is a prop too.

  It still cannot be one. **The chip hardcodes `fill_width={false}`** — the
  comment beside it says so, it is what makes the "content-sized" claim true —
  and offers no prop to override it, where `Kati.Components.MishkaPill` does.
  This button takes its width from the `weight={1.0}` on the Box around it, and
  a chip inside that Box would hug its label and sit at the leading edge with
  the trough of the row showing beside it. `width` is no way out either: the
  width is whatever the row has left after the Dismiss chip, which is not a
  number this screen knows.

  So: a `fill_width` prop on the chip, defaulting to `false`, is what this needs.
  """
  def confirm_button(label, background, foreground) do
    tap = {self(), :remind}

    ~MOB"""
    <Box weight={1.0}>
      <Row
        fill_width={true}
        height={40}
        corner_radius={20}
        background={background}
        align="center"
        on_tap={tap}
      >
        <Spacer weight={1.0} />
        <Text
          text={label}
          text_size={12.5}
          font_weight="semibold"
          text_color={foreground}
          max_lines={1}
        />
        <Spacer weight={1.0} />
      </Row>
    </Box>
    """
  end

  @doc """
  The secondary button beside `confirm_button/3` — `#EFECE7` on `#5C574F`.

  Left hand-rolled, and this one is not blocked by a missing prop.
  `Kati.Components.MishkaPill` would reproduce it exactly: a hugging `Box` at
  `height: 40, padding: 0, padding_left: 15, padding_right: 15,
  corner_radius: 20, align: :center` around one `Text`, with `on_tap` on the
  body, which is this node plus the two prop-less `Row`s the pill wraps content
  in. Nothing would move.

  It is not adopted because of what it would *say*. The pill port's own opening
  section exists to stop exactly this: *"a Chip is selected, a Pill is removed"* —
  a pill is a token you can take out of a set, and its remove affordance is the
  ✕ it draws, not its label. This is a one-shot action button whose whole content
  is the verb. Calling it a pill because the box matches would spend the one
  distinction that section is defending.

  What the set actually lacks is a **Button**: there is no headless button among
  the 73, only `mishka_close_button`, which is
  `Kati.Components.MishkaActionIcon` with a fixed ✕. A button taking `label`,
  `height`, `padding_x`, `corner_radius`, `background`, `color`, `text_size`,
  `font_weight` and `fill_width` would take this, `confirm_button/3` above, and
  screen 28's hero call-to-action, all three of which are currently three
  hand-rolled copies of the same rounded row.
  """
  def dismiss(label) do
    tap = {self(), :dismiss}

    ~MOB"""
    <Row
      height={40}
      corner_radius={20}
      background={Palette.paper()}
      padding_left={15}
      padding_right={15}
      align="center"
      on_tap={tap}
    >
      <Text
        text={label}
        text_size={12.5}
        font_weight="semibold"
        text_color={Palette.ink_soft()}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc """
  The `rgba(26,25,23,.07)` rule between two services, absent after the last.

  ## `Kati.Components.MishkaSeparator`, and only because of `render: :box`

  A rule between rows is exactly what a separator is, and the port's API always
  fitted — `separator(color: Palette.hairline())` at its default `thickness: 1` is this
  line. What did not fit was what it *drew*. On its default `render: :divider`
  the port emits `<Divider>`, which `MobBridge` hands to Material 3's
  `HorizontalDivider`, and in 1.2.0 that composable is not a filled box:

      Canvas(modifier.fillMaxWidth().height(thickness)) {
        drawLine(color, strokeWidth = thickness.toPx(), …)
      }

  `height(1.dp)` **rounds** to whole device pixels while `thickness.toPx()`
  does not, and the capture device runs at 2.6875x. So the node is 3px tall and
  the antialiased stroke covers 2.6875 of them: the last row lands at 69%
  coverage instead of 100%. On this screen's `#FBFAF8` card that is about five
  levels of grey along the bottom edge of every rule — small enough that nothing
  in the repo would report it, and still a difference, and a difference is not
  what this rule is. Nothing measures these pixels at all now: the frame differ
  that once did called anything under twelve levels a channel a match and would
  have passed this, and it went with the rest of the device-capture tooling,
  while the sweeps that outlived it — `Kati.ScreenDesignLiteralTest` and
  `Kati.ScreenTapSweepTest` — assert literals, symbols and tap targets against
  the rendered tree, where a hairline is none of the three. It vanishes at any
  density where 1dp is a whole number of pixels, which is why it was invisible
  in a unit test.

  `render: :box` is the way out, and it is why the default is not taken here:
  the port swaps the Material stroke for the background-filled `Box` it has
  always used on its vertical axis, and a filled rect has no antialiased edge,
  so all three device-pixel rows carry the full colour.

  **The pixels are the same node.** `separator(color: Palette.hairline(), render: :box)`
  builds

      <Box fill_width={true} height={1} background={Palette.hairline()}>
        <Spacer size={1} />
      </Box>

  where this was the same `Box` with no child. The `Spacer` is the port's iOS
  height workaround (`MobBox` drops a childless Box's height there); on Android
  `MobSpacer` is `Spacer(modifier.size(1.dp))` — no background, nothing drawn —
  and the Box's own `height(1.dp)` is applied after padding and pins the box, so
  a 1pt child cannot grow it. It adds an invisible node and no pixel.
  """
  def hairline(false), do: ~MOB"<Spacer size={0} />"

  def hairline(true),
    do: Kati.Components.MishkaSeparator.separator(color: Palette.hairline(), render: :box)

  # `:remind` toggles rather than latches, so the one control that arms it can
  # also cancel it. There is nowhere else on this screen to cancel from, and a
  # button that can only be pressed once is a button that lies the second time.
  # Board 96's button, on the band this screen draws when nothing is set up
  # (#120). All four of the sheet's routes lead to one place.
  @doc """
  The tap that opens one service's page, or `nil` on a row that is a picture.

  Keyed on the name, which is what `Kati.Screens.Service.find/1` looks a
  service up by and what `Kati.Screens.MyServices.service_tag/1` already keys
  its own row on. `live?` is the ledger's own flag for *these are the reader's
  services*; the drawing's are not, so they open nothing.

      iex> Kati.Screens.Subscriptions.service_tap(%{name: "Lumen+", live?: false})
      nil
  """
  @spec service_tap(map()) :: {pid(), atom()} | nil
  def service_tap(%{live?: true, name: name}) when is_binary(name) and name != "",
    do: {self(), String.to_atom("open_service_" <> String.replace(name, " ", "_"))}

  def service_tap(_drawn), do: nil

  @impl true
  def handle_tap(:my_services_ledger, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.MyServices)}

  def handle_tap(tag, socket) when is_atom(tag) do
    case Atom.to_string(tag) do
      "open_service_" <> name ->
        {:noreply,
         Mob.Socket.push_screen(socket, Kati.Screens.Service, %{
           name: String.replace(name, "_", " ")
         })}

      _other ->
        Kati.Screens.Subscriptions.other_tap(tag, socket)
    end
  end

  @doc """
  Whether the *Worth a look* card is offered at all.

  `false` once the reader has dismissed the advice for the service it is about
  — see `Kati.Subscriptions.dismissed/0`. It was an unconditional `true` at
  mount, so *Dismiss* retired the card for as long as they stayed on the page
  and it was back the moment they came again.
  """
  @spec offer?() :: boolean()
  def offer? do
    case Kati.Screens.Subscriptions.ledger() do
      %{suggestion: %{service: name}} when is_binary(name) ->
        Kati.Subscriptions.dismissed() != name

      _nothing_to_offer ->
        true
    end
  rescue
    _error -> true
  end

  @doc false
  # Only over a service the reminder can actually be about — see
  # `confirm_label/2`. A card with no renewal date draws no button, so this is
  # belt and braces rather than a reachable state.
  def other_tap(:remind, socket) do
    case get_in(socket.assigns, [:ledger, Access.key(:suggestion), Access.key(:remind_on)]) do
      %Date{} -> {:noreply, Mob.Socket.assign(socket, :reminded, not socket.assigns.reminded)}
      _no_date -> {:noreply, socket}
    end
  end

  def other_tap(:dismiss, socket) do
    case get_in(socket.assigns, [:ledger, Access.key(:suggestion), Access.key(:service)]) do
      name when is_binary(name) -> Kati.Subscriptions.dismiss(name)
      _unnamed -> :ok
    end

    {:noreply, Mob.Socket.assign(socket, :suggestion, false)}
  end

  # The `more_horiz` disc no longer lands here, because it no longer takes a
  # tap. 23.html contains exactly one `more_horiz` and no menu, sheet or
  # popover anywhere in the export, so there is nothing for it to open that
  # would not be invented — and the previous argument for keeping the tap was
  # that *"stripping `on_tap` would take its press feedback away too."*
  #
  # Press feedback is precisely what was wrong with it. A disc that lights
  # under the finger and does nothing is a control that has answered; one that
  # does not light has not been offered. The drawing still draws the disc and
  # this screen still draws it, as the board's own furniture.
  #
  # The catch-all stays for the tags this screen does not own.
  def other_tap(_tag, socket), do: {:noreply, socket}
end
