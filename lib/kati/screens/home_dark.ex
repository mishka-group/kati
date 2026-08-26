defmodule Kati.Screens.HomeDark do
  @moduledoc """
  Screen 28 — Home in dark.

  Built to `test/design/screens/28.html`. Same page as screen 01, same
  `64px 21px 132px` frame, same order of parts — and deliberately **not** an
  inversion of it. The drawing's own caption states the rule this screen
  exists to prove:

    * paper becomes near-black `#121110`, not white flipped to black;
    * cards lift with an **inset hairline** — `rgba(245,242,238,.06)` — where
      light lifts them with a shadow, because a drop shadow on a dark ground
      is invisible and outlining is how depth reads there;
    * cream warms to a lit-lamp brown `#2A2622` and keeps an orange hairline,
      so "personal" still reads as warm rather than as another grey card;
    * the FAB inverts to paper-on-ink, since ink-on-ink would disappear.

  ## Why this draws its own dock instead of using `Kati.Shell`

  `Kati.Shell.render/1` takes a `mode`, but only two of its colours follow it.
  The inactive tab tint, the active tab's icon colour, the FAB's fill and its
  glyph are all light-mode literals, and the scrim is `Kati.UI.paper_fade/1`,
  which is `#EFECE7` — a light fade over a near-black page. Rendered through
  the shell, this screen's dock would be near-black icons on a near-black bar
  under a pale smear.

  So the dark dock is drawn here, from the drawing's own numbers, rather than
  the shell being bent to a mode it does not yet carry. When dark becomes a
  real mode, this dock is what `Kati.Shell` should grow — and this module
  should disappear into it.

  The tabs and the FAB are wired to the real roots and the real add sheet, so
  this is an entry point rather than a picture of one.

  ## What this screen reads, and why it is exactly what Home reads

  Screen 28 is screen 01 in dark, so it reads what screen 01 reads and nothing
  else. That sentence has been in this moduledoc since the screen was built and
  it used to describe a much smaller split: Home took *Rest of today* from
  `Kati.Calendars.Today` and left the hero, the two continue-watching cards and
  their fractions as the drawing's own copy, and this page matched it.

  **Home's split changed with #91, so this one changes with it.** Every band on
  screen 01 is a read now, and the rule that made this page copy 01's split is
  the same rule that forces it now: *two pages that are the same page must not
  disagree about which half of themselves is real*. A dark Home still announcing
  `3 new episodes are waiting` beside a light Home that draws nothing would be
  the two pages disagreeing about the one thing they exist to be a pair about.

  So `mount/3` fills one assign per band and `render/1` draws assigns and
  nothing else:

    * `:hero` — `Kati.Screens.Home.hero_summary/0`, over
      `Kati.Screens.Inbox.releases/0`. Screen 01's reader rather than a second
      copy of it, for the reason its own moduledoc gives: two answers to *how
      many episodes are out* would be visible on two taps.
    * `:continue` — `Kati.Screens.Home.continue_watching_rows/0`, over
      `Kati.Screens.Library.shelf/0`.
    * `:timeline` — `Kati.Calendars.Today`, the device's real calendar.

  `Kati.Screens.HomeDark.Sample` stays exactly where it is and **nothing on a
  device reaches it**. It is the transcription screen 28 was captured from and
  the fixture `Kati.ScreenDesignLiteralTest.drawn_state/0` installs to compare
  this page against `test/design/screens/28.html`; `drawn_hero/0` beside
  `hero_summary/0` is that map in the shape the render takes, and is the same
  arrangement `Kati.Screens.Home.drawn_hero/0` is in one screen over.

  ## What an empty band draws here, and what it must not

  **The two announcing bands are omitted whole, eyebrow and all** — the answer
  `Kati.Screens.Home.new_this_week/1` and `continue_watching/1` give, for the
  reason screen 96 states: *"an empty state should say what is missing and offer
  the one thing that fixes it — never render a plausible-looking zero."* Two
  dark cards with no titles behind them are that zero, and a section label over
  an omitted section is a heading for nothing.

  *Rest of today* keeps its card and takes screen 139's own sentence —
  `Nothing scheduled — add anything with +` — exactly as
  `Kati.Screens.Home.rest_of_today/1` does, in this page's colours. 139's whole
  argument is that the calendar still works, and the `+` the sentence names is
  the FAB `dock/0` draws at the bottom of this page.

  ## No dark 139 exists, and that is stated rather than worked around

  Screen 01 has a second board for a device with nothing kept at all — screen
  139, *Home — nothing set up* — and switches to it whole. **The design draws no
  dark mirror of 139**, so this page does not branch: it is board 28 with its
  empty bands omitted, which is a real page (header, search, the calendar band,
  the dock and the FAB) and needs no copy no designer wrote.

  It costs less here than it would anywhere else, and the reason is
  `Kati.AppReachabilityTest`'s own entry for this module: 28 is *"screen 01 in
  the dark colourway. The same screen, not another one — reached by changing the
  theme, not by navigating"* — it is registered in `Kati.Screens.Gallery` and
  named by neither `Kati.Shell.roots/0` nor `Kati.Onboarding.shell_root/1`, so
  **no fresh install opens on it**. A dark 139 is a drawing to ask for, not one
  to invent; what could not wait is the fabricated spine, because a gallery is
  still a place a person looks at this app's answer about their own evening.

  ## The header stays pinned, and that is a decision rather than an omission

  Home's other real value is its header: the date line and the greeting come off
  the device clock. This screen cannot take that one, and the reason is written
  into `Kati.Screens.HomeDark.Sample` — screen 29 draws the lock screen of *this
  same evening*, down to the same two events at 20:00 and 21:30, so the two
  pages have to agree about what time it is or they stop being one design.

  There is a second reason, and its arithmetic is restated here because the
  number this paragraph carried was wrong. `Kati.ScreenDesignLiteralTest` can
  only excuse a drawn literal a screen replaces with a clock value by naming it
  on an allow-list, and the bound on that list is not four: it is **30, and the
  list holds all 30** — moved eight times since it was seven, up and back down
  again, with the note at each move that raising it is *a decision to check
  less*. There is no room in it at all today. `Sunday · 16 August`
  and `Good evening` would need two more, so today they would not fit at all
  without moving the bound again. A screen is not worth making the suite check
  less of the app.

  That is the smaller of the two reasons even so, and it is worth saying which
  way round they stand: if the allow-list had room tomorrow, screen 29 would
  still be drawn at this evening and these two lines would still be pinned.

  The cost is stated rather than hidden: on a device with a mirrored calendar
  this page prints the drawing's evening over the device's own today. That is
  the same class of split screen 09 already carries in the other direction — a
  live header over drawn rows — and it closes for good when dark stops being a
  separate page and becomes `Kati.Shell`'s `mode`, which is when this module and
  its Sample both disappear.

  **`last check 18:02` used to be counted as a third one and is no longer part
  of that bargain at all.** It sat in the hero rather than the header, and it is
  not a frozen clock standing in for a device value the way the date line is:
  `Kati.Screens.Inbox`'s moduledoc records that **nothing stores when the
  watcher last swept**, so there is no device value it is standing in for. It
  goes with the hero's own `sub` — see `drawn_hero/0` — and the header keeps
  exactly the two literals it always did.
  """
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Calendars.Today
  alias Kati.Components.MishkaProgress
  alias Kati.Screens.HomeDark.Sample

  # The drawing's dark palette stays as literals at each point of use, the way
  # every other screen here writes colour. It is not lifted into `Kati.Theme`
  # because `Mob.Theme` carries one slot per role and this page needs three
  # different near-blacks — page `#121110`, card `#1E1D1B`, and the `#0E0D0C`
  # disc punched behind the active tab — plus a `rgba(245,242,238,.06)`
  # hairline standing in for the shadow the light theme uses.
  def mount(_params, _session, socket) do
    Mob.Theme.set(Kati.Theme.dark())

    socket
    |> Mob.Socket.assign(:moment, Sample.moment())
    |> Mob.Socket.assign(:hero, Kati.Screens.HomeDark.hero_summary())
    |> Mob.Socket.assign(:continue, Kati.Screens.Home.continue_watching_rows())
    |> Mob.Socket.assign(:timeline, Today.rows())
    |> then(&{:ok, &1})
  end

  def render(assigns) do
    moment = assigns.moment
    timeline = assigns.timeline

    ~MOB"""
    <Box
      fill_width={true}
      fill_height={true}
      background={:background}
      layout_direction={Kati.Locale.direction_prop()}
      accessibility_id={Kati.Screens.Identity.of(__MODULE__)}
    >
      <Scroll>
        <Column
          fill_width={true}
          padding_left={21}
          padding_right={21}
          padding_top={64}
          padding_bottom={132}
        >
          {Kati.Screens.HomeDark.header(moment)}
          {Kati.Screens.HomeDark.search()}
          {Kati.Screens.HomeDark.new_this_week(assigns.hero)}
          {Kati.Screens.HomeDark.continue_watching(assigns.continue)}
          {Kati.Screens.HomeDark.eyebrow("Rest of today")}
          {Kati.Screens.HomeDark.rest_of_today(timeline)}
        </Column>
      </Scroll>
      {Kati.Screens.HomeDark.scrim()}
      {Kati.Screens.HomeDark.dock()}
    </Box>
    """
  end

  # ── What the store answers ──────────────────────────────────────────────────

  @doc """
  *New this week* in the shape this page draws it, or `nil` when there is
  nothing to announce.

  `Kati.Screens.Home.hero_summary/0` is the read — screen 01's own, not a second
  copy of it — and this reshapes its answer rather than re-querying: the light
  hero draws two `Text` nodes off a count and this one draws the same two, so
  the count is turned into the drawing's own pair of lines here and the pair is
  what the render takes. That is what lets `drawn_hero/0` hand the board's
  headline straight from `Kati.Screens.HomeDark.Sample.inbox/0` without a second
  copy of `3` living anywhere.

  `sub` and `checked` are `nil` and stay `nil` on every device — see the
  moduledoc for the two facts no column holds — and they exist as keys only so
  that `drawn_hero/0` can put the board's own copy back under
  `Kati.ScreenDesignLiteralTest`.
  """
  @spec hero_summary() :: map() | nil
  def hero_summary do
    case Kati.Screens.Home.hero_summary() do
      nil ->
        nil

      %{count: count, seeds: seeds} ->
        %{headline: Kati.Screens.Home.headline_lines(count), seeds: seeds, sub: nil, checked: nil}
    end
  end

  @doc """
  The hero exactly as `test/design/screens/28.html` draws it.

  Stand-in data and marked as such, and — since this round — **unreachable from
  a render**, exactly as `Kati.Screens.Home.drawn_hero/0` is. Every string comes
  out of `Kati.Screens.HomeDark.Sample`, which is what the board was captured
  from and what screen 29's lock screen is drawn against; nothing is restated
  here, so the two pages cannot drift by an edit to one of them.

  `checked` is `Sample.moment/0`'s, not the header's — see the moduledoc's note
  on why `last check 18:02` left the pinned-clock bargain.
  """
  @spec drawn_hero() :: map()
  def drawn_hero do
    inbox = Sample.inbox()

    %{
      headline: inbox.headline,
      seeds: inbox.posters,
      sub: inbox.sub,
      checked: Sample.moment().last_check
    }
  end

  def handle_info({:tap, :inbox}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Inbox)}

  def handle_info({:tap, :search}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Search)}

  def handle_info({:tap, :fab}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.AddTitle)}

  def handle_info({:tap, tag}, socket) do
    case Atom.to_string(tag) do
      "root_home" -> {:noreply, socket}
      "root_" <> id -> {:noreply, leave(socket, id)}
      _ -> {:noreply, socket}
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  defp leave(socket, id) do
    target = String.to_existing_atom(id)
    Mob.Socket.reset_to(socket, Kati.Shell.screen_for(target))
  end

  @doc false
  def header(moment) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column weight={1.0}>
          <Text
            text={String.upcase(moment.date)}
            font_family="mono"
            text_size={11}
            letter_spacing={0.14}
            text_color={0xFF6A6560}
          />
          <Spacer size={7} />
          <Text
            text={moment.greeting}
            text_size={28}
            max_font_scale={1.6}
            font_weight="bold"
            letter_spacing={-0.03}
            text_color={0xFFF5F2EE}
          />
        </Column>
        {Kati.Screens.HomeDark.disc("notifications", :inbox)}
        <Spacer size={9} />
        {Kati.Screens.HomeDark.disc("calendar_month", :root_calendar)}
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  A 44pt header disc — an inset ring, not a shadow.

  The drawing writes the lift as `inset 0 0 0 1px rgba(245,242,238,.06)`, and a
  border of that colour is the same pixel. That is why this disc waited:
  `Kati.Components.MishkaActionIcon` is exactly a round tap target holding one
  glyph, but it painted a fill and stopped, with no way to say *outlined*. It
  now takes `border_color` and `border_width`, which is the whole of what dark
  mode uses instead of a shadow.

  **The pixels are the same node.** The port builds

      <Box width={44} height={44} align={:center} corner_radius={22.0}
           background={0xFF1E1D1B} border_color={0x0FF5F2EE} border_width={1}
           on_tap=…><Row>{glyph}</Row></Box>

  which is this `Box` prop for prop: `shape: :circle` resolves to an exact
  `size / 2` so 44 gives 22, `variant: :filled` is what lets `background`
  through, and `align={:center}` serialises to the `"center"` string
  `MobBridge.boxAlignProp` reads. The border needs both keys to draw anything —
  the port omits `border_width` entirely unless `border_color` is set, which is
  the same condition the bridge applies. The added `Row` carries no props, takes
  no modifier and hugs its one child, so the glyph measures and centres as it
  did.
  """
  def disc(icon, tag) do
    Kati.Components.MishkaActionIcon.action_icon(
      [
        size: 44,
        shape: :circle,
        variant: :filled,
        background: 0xFF1E1D1B,
        border_color: 0x0FF5F2EE,
        border_width: 1,
        on_tap: {self(), tag}
      ],
      [Kati.UI.symbol(icon, size: 21, color: 0xFFF5F2EE)]
    )
  end

  @doc false
  def search do
    tap = {self(), :search}

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        height={52}
        corner_radius={26}
        background={0xFF1E1D1B}
        border_width={1}
        border_color={0x0FF5F2EE}
        padding_left={18}
        padding_right={18}
        align="center"
        on_tap={tap}
      >
        {Kati.UI.symbol("search", size: 20, color: 0xFF6A6560)}
        <Spacer size={11} />
        <Text
          text="Search films, shows, events…"
          text_size={14.5}
          text_color={0xFF6A6560}
          weight={1.0}
          max_lines={1}
        />
        <Spacer size={11} />
        {Kati.UI.symbol("tune", size: 19, color: 0xFFF5F2EE)}
      </Row>
      <Spacer size={26} />
    </Column>
    """
  end

  # `Kati.UI.eyebrow/2` is the light one: its label is `#A0998F` against paper.
  # Dark drops the label to `#6A6560` and keeps the accent dash exactly, which
  # is the point — the dash is punctuation and does not change with the ground.
  @doc false
  def eyebrow(label) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        <Box width={13} height={2} corner_radius={1} background={0xFFE8823C} />
        <Spacer size={9} />
        <Text
          text={String.upcase(label)}
          font_family="mono"
          text_size={10.5}
          letter_spacing={0.16}
          text_color={0xFF6A6560}
        />
      </Row>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc """
  *New this week*: its eyebrow and its hero, or nothing at all.

  The eyebrow goes with the card rather than staying in `render/1`, for the
  reason `Kati.Screens.Home.new_this_week/1` gives: a section label over an
  omitted section is a heading for nothing.
  """
  @spec new_this_week(map() | nil) :: map() | [map()]
  def new_this_week(nil), do: ~MOB"<Spacer size={0} />"

  def new_this_week(summary),
    do: [Kati.Screens.HomeDark.eyebrow("New this week"), Kati.Screens.HomeDark.hero(summary)]

  # Cream, warmed rather than darkened, and ringed in 14%-alpha orange instead
  # of carrying the light card's shadow.
  #
  # `Open inbox` is written out here rather than read from the Sample: a button
  # label is chrome, not data — it says the same thing on a device with three
  # episodes and on one with one — and reading it through `Sample.inbox/0` was
  # the last thing keeping that module reachable from a render.
  @doc false
  def hero(summary) do
    tap = {self(), :inbox}

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={0xFF2A2622}
        corner_radius={24}
        border_width={1}
        border_color={0x24E8823C}
        padding={19}
      >
        <Row fill_width={true} align="top">
          <Column weight={1.0}>
            {Enum.map(summary.headline, fn line -> Kati.Screens.HomeDark.headline(line) end)}
            {Kati.Screens.HomeDark.hero_sub(summary.sub)}
          </Column>
          {Kati.Screens.HomeDark.hero_posters(summary.seeds)}
        </Row>
        <Spacer size={17} />
        <Row fill_width={true} align="center">
          <Row
            height={40}
            corner_radius={20}
            background={0xFFF7EFE4}
            padding_left={18}
            padding_right={18}
            align="center"
            on_tap={tap}
          >
            <Text
              text="Open inbox"
              text_size={13.5}
              font_weight="semibold"
              text_color={0xFF1A1917}
              max_lines={1}
            />
            <Spacer size={7} />
            {Kati.UI.symbol("arrow_forward", size: 17, color: 0xFF1A1917)}
          </Row>
          {Kati.Screens.HomeDark.hero_checked(summary.checked)}
        </Row>
      </Column>
      <Spacer size={26} />
    </Column>
    """
  end

  # The drawing's second line — availability, which screen 96 says needs a
  # subscribed service to count down from and no column holds. Drawn when
  # `drawn_hero/0` puts it back and omitted on every device.
  @doc false
  def hero_sub(nil), do: ~MOB"<Spacer size={0} />"

  def hero_sub(text) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={8} />
      <Text text={text} text_size={13} line_height={1.45} text_color={0xFFA89B87} />
    </Column>
    """
  end

  # `last check 18:02`. Nothing records when the watcher last swept, so the
  # gutter goes with the line rather than leaving a hole beside the button.
  @doc false
  def hero_checked(nil), do: ~MOB"<Spacer size={0} />"

  def hero_checked(text) do
    ~MOB"""
    <Row align="center">
      <Spacer size={10} />
      <Text text={text} font_family="mono" text_size={11} text_color={0xFF7A6F5E} max_lines={1} />
    </Row>
    """
  end

  @doc false
  def headline(line) do
    ~MOB"""
    <Text
      text={line}
      text_size={21}
      font_weight="bold"
      letter_spacing={-0.025}
      line_height={1.2}
      text_color={0xFFF7EFE4}
      max_lines={1}
    />
    """
  end

  # Three 46-wide posters overlapping leftward by 16 measure 106, not 138 —
  # `margin-left:-16px` shrinks the box as well as shifting the child, and
  # negative padding throws on Compose. Fixed 106 box, each poster offset 30.
  #
  # The drawing hangs the stack off a container with `padding-top:2px`, which
  # only moves the posters — the row is 96 tall and driven by the text beside
  # them — so it is reproduced as `offset_y` rather than as padding that would
  # also grow the box.
  #
  # The width is arithmetic rather than the drawn 106, for
  # `Kati.Screens.Home.poster_stack/1`'s reason: a hero announcing one episode
  # draws one 46-wide poster instead of two thirds of an empty box. Three seeds
  # still measure `46 + 30 * 2 = 106`, which is the drawing's own number.
  # The 14pt gutter belongs to the stack, so a hero whose posters were all
  # evicted closes up rather than leaving a hole where three of them were.
  @doc false
  def hero_posters([]), do: ~MOB"<Spacer size={0} />"

  def hero_posters(seeds) do
    ~MOB"""
    <Row align="top">
      <Spacer size={14} />
      {Kati.Screens.HomeDark.poster_stack(seeds)}
    </Row>
    """
  end

  @doc false
  def poster_stack(seeds) do
    width = 46 + 30 * (length(seeds) - 1)

    ~MOB"""
    <Box width={width} height={64} offset_y={2}>
      {seeds
       |> Enum.with_index()
       |> Enum.map(fn {seed, i} -> Kati.Screens.HomeDark.poster(seed, i) end)}
    </Box>
    """
  end

  @doc false
  def poster(seed, index) do
    offset = index * 30
    src = Kati.Design.Images.poster(seed)

    ~MOB"""
    <Box
      width={46}
      height={64}
      offset_x={offset}
      corner_radius={9}
      background={0xFF3A342D}
      border_width={2}
      border_color={0xFF2A2622}
      shadow="0 4 10 -4 #99000000"
    >
      {Kati.Screens.HomeDark.poster_image(src)}
    </Box>
    """
  end

  @doc false
  def poster_image(nil), do: ~MOB"<Spacer size={0} />"

  def poster_image(src) do
    ~MOB"""
    <Image src={src} width={42} height={60} corner_radius={7} content_mode="fill" />
    """
  end

  @doc """
  *Continue watching*: its eyebrow and its cards, or nothing at all.

  **Omitted rather than emptied**, and screen 01's own reasoning decides it: no
  artboard draws an empty Continue-watching band in either colourway, and screen
  96 says what that leaves — *"never render a plausible-looking zero"*. Screen
  27's *No titles yet* card is not the substitute either; it is the Library's
  emptiness and `Kati.Screens.Library.empty_state/0` owns it.
  """
  @spec continue_watching([map()]) :: map() | [map()]
  def continue_watching([]), do: ~MOB"<Spacer size={0} />"

  def continue_watching(rows) do
    [Kati.Screens.HomeDark.eyebrow("Continue watching"), Kati.Screens.HomeDark.continue(rows)]
  end

  @doc false
  def continue(rows) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {Kati.Screens.HomeDark.cards_in_row(rows)}
      </Row>
      <Spacer size={26} />
    </Column>
    """
  end

  # One title in progress is an ordinary state and the board draws no picture of
  # it. A lone `weight: 1.0` card would stretch to the full width — a card twice
  # the drawn size — so the empty half of the row is held open and nothing is
  # drawn into it. `Kati.Screens.Home.cards_in_row/1`, one colourway over.
  @doc false
  def cards_in_row([row]) do
    [
      Kati.Screens.HomeDark.watch_card(row),
      Kati.Screens.HomeDark.card_gap(),
      Kati.Screens.HomeDark.half()
    ]
  end

  def cards_in_row(rows) do
    rows
    |> Enum.map(&Kati.Screens.HomeDark.watch_card/1)
    |> Enum.intersperse(Kati.Screens.HomeDark.card_gap())
  end

  @doc false
  def card_gap, do: ~MOB"<Spacer size={13} />"

  @doc false
  def half, do: ~MOB"<Spacer weight={1.0} />"

  @doc false
  def watch_card(row) do
    ~MOB"""
    <Box weight={1.0}>
      <Column
        fill_width={true}
        background={0xFF1E1D1B}
        corner_radius={20}
        border_width={1}
        border_color={0x0FF5F2EE}
        padding={11}
      >
        {Kati.Screens.HomeDark.still(row)}
        <Spacer size={11} />
        <Text
          text={row.title}
          text_size={14.5}
          font_weight="bold"
          letter_spacing={-0.02}
          text_color={0xFFF5F2EE}
          max_lines={1}
        />
        {Kati.Screens.HomeDark.watch_meta(row.meta)}
        <Spacer size={10} />
        {Kati.Screens.HomeDark.watch_bar(row.progress || 0.0)}
      </Column>
    </Box>
    """
  end

  # `S2 · E6 · 18m left` is the drawing's, and nothing writes either half of it:
  # `Kati.Media.TrackedTitle` says of `progress_seconds` that "nothing writes it
  # yet", and the same is true of `progress_season` and `progress_episode`. A
  # real card carries the progress it does know as the bar and says nothing it
  # cannot source.
  @doc false
  def watch_meta(nil), do: ~MOB"<Spacer size={0} />"

  def watch_meta(meta) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={3} />
      <Text text={meta} font_family="mono" text_size={10.5} text_color={0xFF6A6560} max_lines={1} />
    </Column>
    """
  end

  @doc """
  The 4pt elapsed rail — paper on `#312F2C`, the drawing's own
  `height:4px;border-radius:2px`.

  `Kati.Components.MishkaProgress` in `render: :box` rather than the two
  weighted Boxes this used to hand-roll, and the reason is not tidiness.
  A finished episode is `1.0` and an unstarted one `0.0`; the hand-rolled shape
  wrote `weight={0.0}` onto the fill at one end and onto the remainder at the
  other, and **Compose throws on a zero weight rather than warning**. That was
  unreachable while the row came from `Sample.continue/0` — `0.62` and `0.24`
  are both safely inside the range — and it is reachable from the first real
  shelf row: `Kati.Media.CachedTitle.progress/2` answers `0.0` for a title
  marked *watching* with no tick logged against it yet, which is the ordinary
  state of a show somebody has just added. The component omits whichever node
  would carry the zero, so both ends draw.

  `Kati.Screens.Home.watch_bar/1` and `Kati.Screens.HomeFa.watch_card/1` are the
  same call at the same three numbers in their own palettes.
  """
  @spec watch_bar(float()) :: map()
  def watch_bar(progress) do
    MishkaProgress.progress(
      render: :box,
      value: progress,
      max: 1,
      height: 4,
      corner_radius: 2,
      color: 0xFFF5F2EE,
      track_color: 0xFF312F2C
    )
  end

  # The card wants the 520x384 crop, not the 400x600 poster — the design shot
  # each title at both sizes because a landscape still and a poster are
  # different photographs, not one scaled.
  @doc false
  def still(row) do
    case Kati.Design.Images.path(row.seed, {520, 384}) do
      nil ->
        ~MOB"<Box fill_width={true} height={112} corner_radius={12} background={0xFF2A2826} />"

      src ->
        ~MOB"""
        <Image src={src} fill_width={true} height={112} corner_radius={12} content_mode="fill" />
        """
    end
  end

  @doc """
  The rest of the evening: the device's own calendar, or screen 139's sentence.

  `Kati.Screens.Home.rest_of_today/1` in dark, clause for clause — **including
  what the `[]` head now says**. It used to substitute
  `Kati.Screens.HomeDark.Sample.rest_of_today/0`, which is how a device with
  nothing mirrored came to be told, in the drawing's own words, to ring their
  mother at 21:30. An empty day is not missing data; it is a day with nothing on
  it, and 139 is the board that words that state: *Nothing scheduled — add
  anything with +*.

  The `+` the sentence names is the FAB `dock/0` draws over this page, so the
  affordance it points at is on screen here exactly as it is on 139. What is
  borrowed is the one thing 139 contributes that this page does not have — the
  words for an empty day — and the container is this page's own card, which is
  the same division `Kati.Screens.Home.rest_of_today/1` argues for at length.

  A row is `%{time, title, meta, now?}` whichever side it came from, so
  `timeline_row/2` cannot tell a mirrored event from a drawn one and cannot
  answer the two differently.
  """
  @spec rest_of_today([map()]) :: map()
  def rest_of_today([]) do
    ~MOB"""
    <Column
      fill_width={true}
      background={0xFF1E1D1B}
      corner_radius={20}
      border_width={1}
      border_color={0x0FF5F2EE}
      padding_left={15}
      padding_right={15}
      padding_top={20}
      padding_bottom={20}
    >
      <Text
        text="Nothing scheduled — add anything with +"
        text_size={13}
        line_height={1.55}
        text_color={0xFF8A837B}
      />
    </Column>
    """
  end

  def rest_of_today(rows) do
    last = length(rows) - 1

    ~MOB"""
    <Column
      fill_width={true}
      background={0xFF1E1D1B}
      corner_radius={20}
      border_width={1}
      border_color={0x0FF5F2EE}
      padding_left={15}
      padding_right={15}
      padding_top={5}
      padding_bottom={5}
    >
      {rows
       |> Enum.with_index()
       |> Enum.map(fn {row, i} -> Kati.Screens.HomeDark.timeline_row(row, i < last) end)}
    </Column>
    """
  end

  @doc false
  def timeline_row(row, rule?) do
    rail = if row.now?, do: 0xFFE8823C, else: 0xFF4A453F

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={14} padding_bottom={14}>
        <Column width={40}>
          <Text
            text={row.time}
            font_family="mono"
            text_size={12}
            text_color={0xFF6A6560}
            max_lines={1}
          />
        </Column>
        <Spacer size={14} />
        <Box width={3} height={34} corner_radius={2} background={rail} />
        <Spacer size={14} />
        <Column weight={1.0}>
          <Text
            text={row.title}
            text_size={14}
            font_weight="semibold"
            text_color={0xFFF5F2EE}
            max_lines={1}
          />
          <Spacer size={3} />
          <Text text={row.meta} text_size={12} text_color={0xFF8A837B} max_lines={1} />
        </Column>
      </Row>
      {Kati.Screens.HomeDark.hairline(rule?)}
    </Column>
    """
  end

  @doc """
  The rule between two timeline rows — paper at 7% on near-black, not ink.

  `Kati.Components.MishkaSeparator` at `render: :box`, for the reason
  `Kati.Screens.Subscriptions.hairline/1` sets out at length: the port's default
  `render: :divider` emits `<Divider>`, Material 3 draws that as an antialiased
  `drawLine` inside a `height(thickness)` canvas, and at the capture device's
  2.6875x a 1dp stroke leaves the last of three device-pixel rows at 69%
  coverage where a filled `Box` gives 100%. The API always fitted this line;
  until `render: :box` existed the pixels did not.

  The node it builds is `<Box fill_width={true} height={1} background=…>` with a
  `<Spacer size={1} />` inside — the port's iOS height workaround. On Android
  `MobSpacer` is a background-less `Spacer(modifier.size(1.dp))` and the Box's
  `height(1.dp)` pins the box, so the child draws nothing and measures nothing.
  Same rule, one invisible node.
  """
  def hairline(false), do: ~MOB"<Spacer size={0} />"

  def hairline(true),
    do: Kati.Components.MishkaSeparator.separator(color: 0x12F5F2EE, render: :box)

  # A fade to the page colour, not to paper. `Kati.UI.paper_fade/1` is
  # `#EFECE7` and would draw a pale band across the bottom of a near-black page.
  @doc false
  def scrim do
    ~MOB"""
    <Box fill_width={true} fill_height={true} align="bottom">
      <Box fill_width={true} height={120} gradient="to_top #FF121110 42% #00121110" />
    </Box>
    """
  end

  @doc false
  def dock do
    ~MOB"""
    <Box fill_width={true} fill_height={true} align="bottom">
      <Row fill_width={true} align="center" padding_left={18} padding_right={18} padding_bottom={30}>
        <Box
          weight={1.0}
          height={64}
          background={0xEB1E1D1B}
          corner_radius={32}
          shadow={Kati.Theme.shadow_dock()}
          align="center"
        >
          <Row fill_width={true} fill_height={true} align="center" padding_left={9} padding_right={9}>
            {Enum.map(Kati.Shell.roots(), fn root -> Kati.Screens.HomeDark.tab(root) end)}
          </Row>
        </Box>
        <Spacer size={11} />
        {Kati.Screens.HomeDark.fab()}
      </Row>
    </Box>
    """
  end

  @doc """
  The 64pt add button beside the dock, inverted to paper-on-ink.

  `Kati.Components.MishkaActionIcon`. The port's own docs put it plainly — *"a
  floating disc is defined by its shadow"* — and until it took a `shadow` prop
  it could draw a flat paper patch here and nothing else. `0 12 26 -10
  #CC1A1917` is what lifts the FAB off a near-black page, so it was the whole
  difference between the component and this button.

  **The pixels are the same node.** The port builds

      <Box width={64} height={64} align={:center} corner_radius={32.0}
           background={0xFFF5F2EE} shadow="0 12 26 -10 #CC1A1917"
           on_tap=…><Row>{glyph}</Row></Box>

  against the identical hand-rolled `Box`: `shape: :circle` is an exact
  `size / 2`, so 64 gives the drawing's 32; `variant: :filled` lets the paper
  fill through; `align={:center}` serialises to `"center"`; and the `shadow`
  string is handed to the container untouched, so `MobBridge`'s `shadowLayers`
  parses the same one layer. The extra `Row` has no props, hugs its one child
  and adds nothing to measure.
  """
  def fab do
    Kati.Components.MishkaActionIcon.action_icon(
      [
        size: 64,
        shape: :circle,
        variant: :filled,
        background: 0xFFF5F2EE,
        shadow: "0 12 26 -10 #CC1A1917",
        on_tap: {self(), :fab}
      ],
      [Kati.UI.symbol("add", size: 27, color: 0xFF16150F)]
    )
  end

  # The active disc is #0E0D0C — darker than the page, so it reads as a hole
  # punched through the bar rather than a highlight sitting on it. That is the
  # dark counterpart of the light dock's paper-coloured disc, and it is why the
  # shell's `Kati.Theme.paper(mode)` is not quite enough on its own.
  @doc false
  def tab(root) do
    on? = root.id == :home
    tint = if on?, do: 0xFFF5F2EE, else: 0xFF6A6560
    disc = if on?, do: 0xFF0E0D0C, else: 0x00FFFFFF
    tap = {self(), String.to_atom("root_#{root.id}")}

    ~MOB"""
    <Box weight={1.0} align="center" on_tap={tap}>
      <Box width={46} height={46} background={disc} corner_radius={23} align="center">
        {Kati.UI.symbol(root.icon, size: 22, color: tint, fill: on?)}
      </Box>
    </Box>
    """
  end
end
