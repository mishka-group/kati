defmodule Kati.Screens.Home do
  @moduledoc """
  Screen 01 — Home.

  Built to `test/design/screens/01.html`, where every number is literal:
  the `64px 21px 132px` frame, the 44px header discs, the 52px search bar at
  radius 26, the cream hero at radius 24 with its three overlapping posters,
  the two continue-watching cards, three section tiles, and the rest-of-today
  card whose rows are separated by a `rgba(26,25,23,.07)` hairline.

  The design's one fixed element is the **New this week** card; everything
  below it is a shelf that can be swapped as sections arrive.

  ## Real data versus the drawing

  **Every shelf on this page is a read.** `load/1` fills one assign per band
  and `content/1` draws assigns and nothing else, which is what makes the
  drawing installable rather than baked in: `Kati.ScreenDesignLiteralTest`'s
  `drawn_state/0` puts the board's own values into those five assigns and
  compares screen 01 against `test/design/screens/01.html` exactly as it always
  did, and a device compares against its own store.

    * `:timeline` — `Kati.Calendars.Today`, the device's real calendar.
    * `:hero` — `hero_summary/0`, over `Kati.Screens.Inbox.releases/0`.
    * `:continue` — `continue_watching_rows/0`, over `Kati.Screens.Library.shelf/0`.
    * `:services` — `services/0`, over `Kati.Services.subscribed_count/0`.
    * `:tiles` — `tile_rows/0`.

  The `drawn_*` functions beside each reader are the transcriptions the board
  was captured from. They are public, they are the fixture both sweeps build
  screen 01 out of, and — exactly as `Kati.Screens.Library.drawn_titles/0` is
  since #91 — **nothing on a device reaches them**. A render that reached one
  would be this screen handing somebody the drawing as their own, which is the
  whole of the report below.

  ## On a fresh device this page is screen 139, not screen 01 (#91)

  Screen 01 is Home **once there is something to draw**. It was, until this
  round, also what Home drew when there was nothing: a hero announcing three
  episodes nobody follows, two half-watched shows nobody started, and a
  calendar card carrying `Call Mum · Repeats weekly`. The owner installed the
  app on his own phone and read that as what it is — *"you all show dummy data
  and it is not connected to database"*. A first launch that fabricates the
  user's own content is not a fidelity aid; it is the app lying about the one
  thing it exists to hold.

  The design already answers this and has since 139 landed: **Home — nothing
  set up**, `test/design/screens/139.html`. So `content/1` branches, and the
  empty branch is `Kati.Screens.HomeEmpty.content/1` **called**, not copied —
  see `nothing_kept?/1` for the condition and the moduledoc note below for why
  the call goes that way round.

  ### Why Home calls HomeEmpty and not the reverse

  139 is a board in its own right and stays one: it is registered in
  `Kati.Screens.Gallery` under its own number, it is `root: :home` so the dock
  and the FAB sit on it exactly as they do here, and
  `Kati.ScreenEmptyDatabaseTest` renders it under `"139"`. The module that owns
  an artboard owns its copy — the same rule that makes `Kati.Screens.SeriesFa`
  read through `Kati.Screens.Series` rather than restate it — and the artboard
  here is 139's. So Home holds the *condition* and HomeEmpty holds the *page*,
  and there is exactly one copy of 139 in the app. A second column of
  `padding_left={21} padding_right={21}` listing the same six blocks would be
  the drift this file is supposed to be removing, not adding.

  `HomeEmpty`'s blocks build their taps as `{self(), tag}`, and `self()` during
  this screen's render is *this* screen — so `:choose_sections`,
  `:restore_backup` and `:open_calendar` arrive at `handle_tap/2` below, which
  answers each with the destination HomeEmpty answers it with.

  ### The gate was not the fix, and this round is the fix

  `nothing_kept?/1` kept the fabricated spine off a *fresh* install and off
  nothing else. Two things followed from that, and both were walked on a Pixel
  9a rather than deduced:

    * a person who picked **Screen** and **Books** on the sections step and
      finished the run was shown 139 — *Nothing chosen yet*, over a **Choose
      sections** button — which tells them their answer did not register and
      offers to redo the step they just finished; and
    * the moment anything at all was kept, the page came back whole: three
      episodes nobody follows, two shows nobody started, a services card
      reading *3 subscribed* on a device with no services, and a *Rest of
      today* card carrying `20:00 · The Long Hollow — S2E6` and `Call Mum`.

  So the order matters and is recorded here because getting it wrong is what
  put the second bullet on a device: the spine is queried **first**, and
  `nothing_kept?/1` learns about sections **after**. A build that does the
  second half alone ships the first half's lie to every user who answers the
  question.

  ### What the design does not draw, stated rather than guessed

  No artboard draws an empty *New this week* hero or an empty *Continue
  watching* band. Screen 96 says what that leaves: *"an empty state should say
  what is missing and offer the one thing that fixes it — never render a
  plausible-looking zero."* Two half-watched cards with no titles behind them
  are precisely a plausible-looking zero, and writing a sentence into a band no
  board words would be typing copy the design never wrote — the trap
  `Kati.Screens.HomeEmpty` names for its own calendar row. **So both bands are
  omitted, eyebrow and all**, and the page that remains is the section cards
  139's own footnote calls Home — *"Home is a page of section cards"* — over a
  calendar that says what is on it.

  Three lines the drawing carries have no column behind them anywhere and are
  drawn only from `drawn_hero/0`, never from a read:

    * *One premiere · two titles leave Lumen+ on Friday.* Leaving-soon is
      availability. Screen 96 is explicit that it *"needs at least one
      subscribed service — there is nothing to count down from"*, and
      `Kati.Media.Watch.service` is where the user watched something, which is
      a different fact and is per-watch.
    * *last check 18:02.* `Kati.Screens.Inbox`'s moduledoc records that
      **nothing stores when the watcher last swept** and why the max of
      `last_checked_at` is not that fact.
    * *S2 · E6 · 18m left.* `Kati.Media.TrackedTitle` says of `progress_seconds`
      that *"nothing writes it yet"*, and the same is true of
      `progress_season` and `progress_episode`. The card draws the progress it
      does know as the **bar**, which is how 01 draws it; substituting screen
      03's `62% watched` caption would be one board's copy in another board's
      slot.

  The two section-tile metas go the same way. `Kati.Screens.Habits`'s moduledoc
  states it outright — *"there is no resource anywhere in this app that records
  a habit being kept"* — so `2 left today` cannot be counted, and `0 left
  today` is the plausible-looking zero 96 forbids. `Dinner 19:30` belongs to
  screen 43, which has its own active-plan gate and its own fallback debt;
  reaching across it from Home would be a second opinion about the same day.
  `tile_rows/0` draws the card and its tap, and no meta.

  ### The two mirrors followed, and what is still owed

  This section used to read *the Persian home is untouched*, and it was the
  largest thing this file left behind. It is not true any more.
  `Kati.Screens.HomeDark` (28) and `Kati.Screens.HomeFa` (55) are this page in
  dark and in Persian, and the round after this one gave each of them the split
  above: one assign per band, screen 01's own readers **called rather than
  copied** — both take `hero_summary/0` and `continue_watching_rows/0` from here
  — and each `Sample` left exactly where it is with nothing on a device reaching
  it.

  55 is the one that mattered. `Kati.Onboarding.shell_root/1` answers
  `Kati.Screens.HomeFa` for `:fa`, so it is the page a Persian install opens on
  after screen 53 — the same first launch this file was rewritten for, in the
  other language, and leaving it was the defect being honest in one language and
  invented in the other. 28 is a gallery board by comparison:
  `Kati.Screens.Gallery` pushes it under its own number and neither
  `Kati.Shell.roots/0` nor `shell_root/1` names it, so no fresh install opens on
  it.

  **The design still draws no Persian 139, and that debt is unpaid rather than
  closed.** Nothing in 55-62, 90, 97 or 103 words an empty Persian Home, so 55
  does not branch the way this page branches: it is board 55 with its stand-in
  data gone — the two announcing bands omitted eyebrow and all, the section
  tiles kept and their uncountable metas dropped — over one sentence this app
  wrote, `Kati.Screens.HomeFa.empty_day/0`, which argues at its own doc why it
  exists and what a designer is owed instead. 28 needs no such sentence: 139 is
  English and so is 28, so its empty day takes 139's words verbatim, the way
  `rest_of_today/1` does here.

  **Screen 24's own Watching row still reads a sample.**
  `Kati.Settings.Sample.watching/0` builds its subtitle out of
  `Kati.Screens.MyServices.subscribed/0`, which answers an empty table with
  `Kati.Subscriptions.Sample`'s three rows — that is screen 92's fallback, and
  five other screens are gated on it in `Kati.ScreenEmptyDatabaseTest`. Home
  therefore stopped calling that function rather than changing it, and Settings
  can now say *3 subscribed* where Home says *No subscriptions yet*. That is a
  visible inconsistency and it is the smaller of the two lies: Home is the page
  a fresh install opens on.
  """
  use Kati.Screens.Root, root: :home

  alias Kati.Components.MishkaProgress
  alias Kati.Components.MishkaSeparator
  alias Kati.Theme
  alias Kati.Theme.Palette
  alias Kati.UI

  # The hero's stack is three posters overlapping leftward; a fourth would have
  # nowhere to sit. See `poster_stack/1` for the arithmetic the count feeds.
  @hero_posters 3

  # Screen 01 draws two continue-watching cards side by side and no second row.
  # See `continue_watching_rows/0`.
  @continue_cards 2

  # The design's own three posters, in the order it stacks them.
  @hero_seeds ~w(ashfall42 marram15 harbour86)

  @impl true
  def load(socket) do
    timeline = Kati.Calendars.Today.rows()

    socket
    |> Mob.Socket.assign(:timeline, timeline)
    |> Mob.Socket.assign(:hero, hero_summary())
    |> Mob.Socket.assign(:continue, continue_watching_rows())
    |> Mob.Socket.assign(:services, services())
    |> Mob.Socket.assign(:tiles, tile_rows())
    |> Mob.Socket.assign(:nothing_kept, nothing_kept?(timeline))
  end

  @doc """
  Whether this device has nothing for Home to draw.

  Two halves, and they are not the same kind of fact.

  *Rest of today* is a real read: `Kati.Calendars.Today` is this device's own
  calendar, and `timeline == []` is that shelf being empty.

  So is the media spine, now. `hero_summary/0` and `continue_watching_rows/0`
  query the store and answer `nil` and `[]` on a device that has kept nothing —
  which means this predicate is no longer what stands between a person and a
  page of invented rows. It decides one thing only: **which of two boards a
  device with nothing on it is shown.**

  `tracking_anything?/0` is still counted rather than derived from those two
  reads, and deliberately: `Kati.Screens.Library.shelf/0` hides archived rows
  and drops a tracked row whose cache was evicted, and neither of those people
  has kept nothing. A row in `tracked_titles` is the cheapest true answer to
  *has this person used the app*, which is the question 139 turns on.

  All three halves are needed and no two are enough. Tracking alone would put
  139's `Nothing scheduled — add anything with +` over a real appointment; the
  calendar alone would draw *Nothing chosen yet* at somebody halfway through a
  season. `Kati.Screens.HomeEmpty`'s moduledoc is explicit that its calendar
  row is the drawing's sentence *verbatim* — the affordance is live, the
  sentence is not a query — so this screen must not hand it a day that has
  events on it.

  **Archived titles count as something.** `:shelf` hides them and this does not:
  a row in `tracked_titles` means this person has used the app, and telling
  them *Nothing chosen yet* would be the same lie in the other direction.

  A read that fails answers `false`. "The store is empty" and "the store could
  not be asked" are different facts, and only the first one may draw 139.
  """
  # ## Sections answered is not the same as sections filled
  #
  # Screen 139 is *Home with nothing chosen* — `Kati.Screens.HomeEmpty`'s own
  # moduledoc calls it "the state after *Skip, I will add*". It offers **Choose
  # sections** as the one thing that fixes it.
  #
  # So it is the wrong board for somebody who has already chosen. Walking a clean
  # install on a Pixel 9a and picking Screen and Books, Home drew *Nothing chosen
  # yet* and a button to choose sections — telling a person their answer had not
  # registered, and offering to redo the step they had just finished. Nothing in
  # the suite caught it: every test asked about an empty STORE, and this is a
  # person with an empty store who has answered.
  #
  # `Kati.Sections.answered?/0` is the third term for that reason. A person who
  # kept two sections and has no rows in them yet sees their two section cards
  # empty, which is the truth; only a person who kept none sees 139.
  #
  # This term is LAST in the file's history on purpose, and the moduledoc says
  # why at length: adding it while `hero/0` and `continue_watching/0` were still
  # literals is what put three invented episodes and two invented shows in front
  # of the person who reported them. It is safe to add now because the bands it
  # uncovers are reads.
  @spec nothing_kept?([map()]) :: boolean()
  def nothing_kept?(timeline) do
    timeline == [] and not tracking_anything?() and not Kati.Sections.answered?()
  end

  defp tracking_anything? do
    case Ash.count(Kati.Media.TrackedTitle) do
      {:ok, 0} -> false
      _counted_or_failed -> true
    end
  end

  @doc false
  def content(%{nothing_kept: true} = assigns), do: Kati.Screens.HomeEmpty.content(assigns)

  def content(assigns) do
    timeline = assigns.timeline

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={132}
      >
        {Kati.Screens.Home.header()}
        {Kati.Screens.Home.search()}
        {Kati.Screens.Home.new_this_week(assigns.hero)}
        {Kati.Screens.Home.continue_watching(assigns.continue)}
        {UI.eyebrow("Watching")}
        {Kati.Screens.Home.watching(assigns.services)}
        {UI.eyebrow("Sections")}
        {Kati.Screens.Home.sections(assigns.tiles)}
        {UI.eyebrow("Rest of today",
           trailing: "See all",
           trailing_tap: {self(), :see_all_today}
         )}
        {Kati.Screens.Home.rest_of_today(timeline)}
      </Column>
    </Scroll>
    """
  end

  # ── What the store answers ──────────────────────────────────────────────────

  @doc """
  What *New this week* has to announce, or `nil` when it has nothing.

  `Kati.Screens.Inbox.releases/0` is the read, not a second opinion about it:
  screen 05 is the release watcher's output and this hero is that page's
  summary with an `Open inbox` button on it, so two different answers to *how
  many episodes are out* would be visible on two taps. That function answers
  `nil` for a device that follows nothing and — its own doc says so — for a
  database that cannot be read at all; both mean *say nothing*, and both are
  correct here, because a hero is an announcement and there is no honest
  announcement to make when the count is unknown.

  `count` is episodes, which is what the drawing's own sentence counts. The
  seeds are the posters of those episodes' shows, up to the three the stack
  draws; a show whose cache row was evicted contributes no seed and the stack
  narrows rather than borrowing one.

  `sub` and `checked` are `nil` and stay `nil` on every device. They are the
  two lines of the drawing that no column can supply — see the moduledoc — and
  they exist as keys so that `drawn_hero/0` can put the board's own copy back
  under `Kati.ScreenDesignLiteralTest` without this function pretending it
  could ever produce them.
  """
  @spec hero_summary() :: map() | nil
  def hero_summary do
    case Kati.Screens.Inbox.releases() do
      %{out_now: [_ | _] = rows} ->
        %{
          count: length(rows),
          seeds:
            rows |> Enum.map(& &1.seed) |> Enum.reject(&is_nil/1) |> Enum.take(@hero_posters),
          sub: nil,
          checked: nil
        }

      _nothing_to_announce ->
        nil
    end
  end

  @doc """
  The titles this person is part-way through, newest touch first.

  `Kati.Screens.Library.shelf/0` is the read, for the reason `hero_summary/0`
  reads screen 05's: the shelf already joins `Kati.Media.TrackedTitle` to the
  cache by the value pair the durable rows reference it by, already drops a row
  whose title was evicted rather than drawing an anonymous rectangle, already
  derives the fraction from ticks through `Kati.Media.CachedTitle.progress/2`,
  and already degrades to `[]` on a store it cannot reach. A second copy of
  that query here is a second set of answers about the same shelf.

  `status == :watching` and not "has a fraction above zero": the status is the
  user's own declaration and `Kati.Media.TrackedTitle` names `:watching` as
  exactly that, while a fraction is `nil` for every film and for every series
  whose episode total was evicted. Somebody who marked a show as being watched
  and has ticked nothing yet is in the middle of it.

  At most two, because the board draws two side by side and Mob has no wrap
  primitive — the same kind of display bound `Kati.Screens.Inbox` argues for its
  seven-day window, and stated here rather than left to the layout to enforce.
  """
  @spec continue_watching_rows() :: [map()]
  def continue_watching_rows do
    Kati.Screens.Library.shelf()
    |> Enum.filter(&(&1.status == :watching))
    |> Enum.take(@continue_cards)
    |> Enum.map(
      &%{
        # The row a card opens, and which of the two screens opens it.
        # `Kati.Screens.Library.shaped/3` has carried both since #91 — this
        # function dropped them, which is why a card that draws a title could
        # not name it. Same pair, same reason, as the grid tile one screen over.
        id: &1.id,
        kind: &1.kind,
        title: &1.title,
        seed: &1.seed,
        progress: &1.progress,
        meta: nil
      }
    )
  end

  @doc """
  The region Kati answers *available* for, and how many services are set up.

  `Kati.Services.subscribed_count/0` rather than
  `Kati.Screens.MyServices.subscribed/0` — that reader answers an empty table
  with the drawing's three rows, which is how this card came to print
  `United Kingdom · 3 subscribed` on a phone with no services on it. See the
  moduledoc for why 92's fallback is left where it is.
  """
  @spec services() :: map()
  def services do
    %{
      region: Kati.Services.region_name(Kati.Services.region()),
      count: Kati.Services.subscribed_count()
    }
  end

  @doc """
  The home cards, minus the sections you turned off.

  Only Habits is a section here — Meals and Settings are not things the first
  run offers to keep, so they are always drawn. The rule this enforces is the
  design's: a section turned off leaves the home screen, the calendar feed and
  the shelf together, and a home card that outlived the choice would be the
  first half of that rule failing quietly.

  **No meta and no dot.** The drawing's `Dinner 19:30` and `2 left today` have
  nothing behind them — see the moduledoc — and a dot means *there is something
  here*, which is a claim rather than decoration. `drawn_tiles/0` carries both
  for the board.
  """
  @spec tile_rows() :: [map()]
  def tile_rows do
    [
      %{section: nil, icon: "restaurant", title: "Meals", meta: nil, dot: nil, tag: :open_meals},
      %{section: "habits", icon: "bolt", title: "Habits", meta: nil, dot: nil, tag: :open_habits},
      %{section: nil, icon: "tune", title: "Settings", meta: nil, dot: nil, tag: :open_settings}
    ]
    |> Enum.filter(&(is_nil(&1.section) or Kati.Sections.on?(&1.section)))
  end

  # ── The drawing's own values, which nothing on a device reaches ─────────────

  @doc """
  The hero exactly as `test/design/screens/01.html` draws it.

  Stand-in data and marked as such. It is what the board was captured from and
  what `Kati.ScreenDesignLiteralTest.drawn_state/0` installs to compare screen
  01 against its drawing; `hero_summary/0` is what a device answers with, and
  the two are different functions precisely so that a render can never reach
  this one — the rule `Kati.Screens.Library.drawn_titles/0` has carried since
  #91.
  """
  @spec drawn_hero() :: map()
  def drawn_hero do
    %{
      count: 3,
      seeds: @hero_seeds,
      sub: "One premiere · two titles leave Lumen+ on Friday",
      checked: "last check 18:02"
    }
  end

  @doc "The two half-watched cards screen 01 draws, in its own order."
  @spec drawn_continue_watching() :: [map()]
  def drawn_continue_watching do
    [
      %{title: "The Long Hollow", meta: "S2 · E6 · 18m left", progress: 0.62, seed: "hollow71"},
      %{title: "Salt & Iron", meta: "S1 · E3 · 41m left", progress: 0.24, seed: "saltiron33"}
    ]
  end

  @doc """
  The Watching row's two values as screen 01 froze them.

  `United Kingdom` written out rather than read through
  `Kati.Services.region_name/1`: this is a transcription of a board, and a
  device that has moved to Germany would otherwise silently change what the
  drawing is said to contain.
  """
  @spec drawn_services() :: map()
  def drawn_services, do: %{region: "United Kingdom", count: 3}

  @doc "The three section cards screen 01 draws, with the two metas it froze."
  @spec drawn_tiles() :: [map()]
  def drawn_tiles do
    [
      %{
        section: nil,
        icon: "restaurant",
        title: "Meals",
        meta: "Dinner 19:30",
        dot: Palette.bronze(),
        tag: :open_meals
      },
      %{
        section: "habits",
        icon: "bolt",
        title: "Habits",
        meta: "2 left today",
        dot: Palette.green(),
        tag: :open_habits
      },
      %{section: nil, icon: "tune", title: "Settings", meta: nil, dot: nil, tag: :open_settings}
    ]
  end

  @doc false
  def header do
    {date_line, greeting} = today()

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column weight={1.0}>
          <Text
            text={String.upcase(date_line)}
            font_family="mono"
            text_size={11}
            letter_spacing={0.14}
            text_color={Palette.muted()}
          />
          <Spacer size={7} />
          <Text
            text={greeting}
            text_size={28}
            max_font_scale={1.6}
            font_weight="bold"
            letter_spacing={-0.03}
            text_color={:on_surface}
          />
        </Column>
        {Kati.Screens.Home.disc("notifications", true, :notifications)}
        <Spacer size={9} />
        {Kati.Screens.Home.disc("calendar_month", false, :open_calendar)}
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  # A 44px disc. The unread dot is 8px of #E8823C with a 2px card-coloured
  # ring, which is how the design keeps it legible against the icon behind it.
  # CSS grows that ring OUTWARD from the 8px box (content-box), so the drawn
  # badge measures 12; Compose draws a border INWARD, so the box is stated as
  # 12 and the border eats back to the 8px the design shows.
  #
  # NOT Chelekom's Action Icon, though screens 02, 03, 06 and 07 all draw their
  # header discs with it now that `shadow` exists. This one has TWO children,
  # and the component puts caller-supplied children in a `<Row>`:
  #
  #     defp glyph(_props, content, _disabled?), do: ~MOB(<Row>{content}</Row>)
  #
  # A Row lays out along its axis; a Box stacks. The badge is an overlay — a
  # `fill_width`/`fill_height` Box that pins a 12pt dot to `top_trailing` of the
  # 44pt disc — so through a Row it would sit BESIDE the bell rather than over
  # its corner, and its two fills would have a hugging Row to fill rather than
  # the disc. The unread dot is the only thing on this screen that says there is
  # anything to open, so that is not a subtle regression.
  #
  # What it lacks, precisely: a way to say "stack these children", or a badge /
  # overlay slot of its own. `<Row>` is right for the icon-plus-nothing case it
  # was written for and wrong for every decorated one.
  @doc false
  def disc(icon, badge?, tag) do
    tap = {self(), tag}
    card = Palette.card()
    shadow = Theme.shadow_button()

    ~MOB"""
    <Box
      width={44}
      height={44}
      background={card}
      corner_radius={22}
      shadow={shadow}
      align="center"
      on_tap={tap}
    >
      {UI.symbol(icon, size: 21)}
      {Kati.Screens.Home.badge(badge?)}
    </Box>
    """
  end

  @doc false
  def badge(false), do: ~MOB"<Spacer size={0} />"

  def badge(true) do
    ~MOB"""
    <Box fill_width={true} fill_height={true} align="top_trailing">
      <Column padding_top={9} padding_right={10}>
        <Box
          width={12}
          height={12}
          corner_radius={6}
          background={Palette.accent()}
          border_width={2}
          border_color={Palette.card()}
        />
      </Column>
    </Box>
    """
  end

  @doc false
  def search do
    tap = {self(), :open_search}
    card = Palette.card()
    shadow = Theme.shadow_search()

    ~MOB"""
    <Column fill_width={true}>
      <Box
        fill_width={true}
        height={52}
        background={card}
        corner_radius={26}
        shadow={shadow}
        padding_left={18}
        padding_right={18}
        on_tap={tap}
      >
        <Row fill_width={true} fill_height={true} align="center">
          {UI.symbol("search", size: 20, color: Palette.muted())}
          <Spacer size={11} />
          <Text
            text="Search films, shows, events…"
            text_size={14.5}
            text_color={Palette.muted()}
            weight={1.0}
            max_lines={1}
          />
          <Spacer size={11} />
          {UI.symbol("tune", size: 19)}
        </Row>
      </Box>
      <Spacer size={26} />
    </Column>
    """
  end

  @doc """
  *New this week*: its eyebrow and its hero, or nothing at all.

  The eyebrow goes with the card rather than staying in `content/1`, because a
  section label over an omitted section is a heading for nothing — and screen
  01's caption calls this *"the one card that never moves"*, which is a
  statement about where it sits on a page that has one, not a promise to draw
  it at somebody who follows nothing.
  """
  @spec new_this_week(map() | nil) :: map() | [map()]
  def new_this_week(nil), do: ~MOB"<Spacer size={0} />"

  def new_this_week(summary), do: [UI.eyebrow("New this week"), Kati.Screens.Home.hero(summary)]

  @doc false
  def hero(summary) do
    tap = {self(), :open_inbox}
    fill = Palette.ink_fill()

    ~MOB"""
    <Column fill_width={true}>
      <Box
        fill_width={true}
        background={Palette.cream()}
        corner_radius={24}
        shadow={Kati.Theme.shadow_hero()}
        padding_left={19}
        padding_right={19}
        padding_top={19}
        padding_bottom={17}
      >
        <Column fill_width={true}>
          <Row fill_width={true} align="top">
            <Column weight={1.0}>
              {Enum.map(Kati.Screens.Home.headline_lines(summary.count), fn line ->
              Kati.Screens.Home.headline(line)
            end)}
              {Kati.Screens.Home.hero_sub(summary.sub)}
            </Column>
            {Kati.Screens.Home.hero_posters(summary.seeds)}
          </Row>
          <Spacer size={17} />
          <Row align="center">
            <Row
              height={40}
              corner_radius={20}
              background={fill}
              padding_left={18}
              padding_right={18}
              align="center"
              on_tap={tap}
            >
              <Text
                text="Open inbox"
                text_size={13.5}
                font_weight="semibold"
                text_color={Palette.on_ink()}
              />
              <Spacer size={7} />
              {UI.symbol("arrow_forward", size: 17, color: Palette.on_ink())}
            </Row>
            {Kati.Screens.Home.hero_checked(summary.checked)}
          </Row>
        </Column>
      </Box>
      <Spacer size={26} />
    </Column>
    """
  end

  # The design breaks this headline itself — `3 new episodes<br>are waiting` —
  # so the break is content, not wrapping. Left to reflow, Compose fits
  # "3 new episodes are" on the first line and drops one word onto the second.
  # Two Texts rather than one `\n` string, which is how screen 28 draws the
  # same two lines.
  #
  # The count is real, so the verb has to agree with it: one episode *is*
  # waiting. That is the drawing's own sentence with its own number put back in,
  # not a second piece of copy — and the singular is reachable the moment
  # somebody follows one weekly show, which is the ordinary case rather than an
  # edge one.
  @doc false
  def headline_lines(1), do: ["1 new episode", "is waiting"]
  def headline_lines(count), do: ["#{count} new episodes", "are waiting"]

  # The drawing's second line, which no column supplies — see the moduledoc.
  # Drawn when `drawn_hero/0` puts it back and omitted on every device.
  @doc false
  def hero_sub(nil), do: ~MOB"<Spacer size={0} />"

  def hero_sub(text) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={8} />
      <Text text={text} text_size={13} line_height={1.45} text_color={Palette.cream_sub()} />
    </Column>
    """
  end

  # `last check 18:02`. Same story: nothing records when the watcher last swept.
  @doc false
  def hero_checked(nil), do: ~MOB"<Spacer size={0} />"

  def hero_checked(text) do
    ~MOB"""
    <Row align="center">
      <Spacer size={10} />
      <Text text={text} font_family="mono" text_size={11} text_color={Palette.cream_meta()} />
    </Row>
    """
  end

  # The 14pt gutter belongs to the stack, so a hero with no artwork to show
  # closes up rather than leaving a hole where three posters were.
  @doc false
  def hero_posters([]), do: ~MOB"<Spacer size={0} />"

  def hero_posters(seeds) do
    ~MOB"""
    <Row align="top">
      <Spacer size={14} />
      {Kati.Screens.Home.poster_stack(seeds)}
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
      text_color={:on_surface}
      max_lines={1}
    />
    """
  end

  # 46x64 posters overlapping leftward by 16, each ringed 2px in the hero's own
  # cream so the overlap reads as a stack rather than a smear.
  #
  # The design does this with `margin-left:-16px`, which both shifts the poster
  # AND shrinks the box it occupies: three 46px posters at -16 measure
  # 46*3 - 16*2 = 106, not 138. Negative padding cannot express that — Compose
  # throws and takes the activity down — so the stack is a fixed-width Box with
  # each poster offset by 30. Same geometry, stated once, and stated as
  # arithmetic rather than as 106 so that a hero announcing one episode draws
  # one 46-wide poster instead of two thirds of an empty box.
  @doc false
  def poster_stack(seeds) do
    width = 46 + 30 * (length(seeds) - 1)

    ~MOB"""
    <Box width={width} height={64}>
      {seeds |> Enum.with_index() |> Enum.map(fn {seed, i} ->
        Kati.Screens.Home.poster(seed, i)
      end)}
    </Box>
    """
  end

  @doc false
  def poster(seed, index) do
    shadow = Theme.shadow_poster()
    offset = index * 30
    src = Kati.Design.Images.poster(seed)

    ~MOB"""
    <Box
      width={46}
      height={64}
      offset_x={offset}
      corner_radius={9}
      background={Palette.poster_on_cream()}
      border_width={2}
      border_color={Palette.cream()}
      shadow={shadow}
    >
      {Kati.Screens.Home.poster_image(src)}
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

  **Omitted rather than emptied**, and the design is what decides that. No
  artboard draws an empty Continue-watching band — 01 draws two cards, 139
  replaces the whole page — and screen 96 states what that leaves: *"an empty
  state should say what is missing and offer the one thing that fixes it —
  never render a plausible-looking zero."* Two cards with no titles behind them
  are that zero. Screen 27's *No titles yet* card is not the substitute either:
  it is the **Library**'s emptiness, `Kati.Screens.Library.empty_state/0` owns
  it, and a second copy under 01's eyebrow would be the drift this file exists
  to remove.
  """
  @spec continue_watching([map()]) :: map() | [map()]
  def continue_watching([]), do: ~MOB"<Spacer size={0} />"

  def continue_watching(rows) do
    [UI.eyebrow("Continue watching"), Kati.Screens.Home.watch_cards(rows)]
  end

  @doc false
  def watch_cards(rows) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {Kati.Screens.Home.cards_in_row(rows)}
      </Row>
      <Spacer size={26} />
    </Column>
    """
  end

  # One title in progress is an ordinary state and the board draws no picture of
  # it. A lone `weight: 1.0` card would stretch to the full 370dp — a card twice
  # the drawn size, which is a shape the design does not have — so the empty
  # half of the row is held open. Nothing is drawn into it.
  @doc false
  def cards_in_row([row]) do
    [Kati.Screens.Home.watch_card(row), Kati.Screens.Home.card_gap(), Kati.Screens.Home.half()]
  end

  def cards_in_row(rows) do
    rows
    |> Enum.map(&Kati.Screens.Home.watch_card/1)
    |> Enum.intersperse(Kati.Screens.Home.card_gap())
  end

  @doc false
  def card_gap, do: ~MOB"<Spacer size={13} />"

  @doc false
  def half, do: ~MOB"<Spacer weight={1.0} />"

  @doc false
  def watch_card(row) do
    card = Palette.card()
    shadow = Theme.shadow_card()

    # `Kati.Screens.Library.poster_tag/1` and not a tag of this screen's own:
    # a card and a grid tile are the same door onto the same row, and two
    # spellings of it would be two names for one destination. It answers
    # `open_series_<Title>` for a row with no `:kind` — which is every row of
    # `drawn_continue_watching/0`, and correct for both of them.
    tap = {self(), Kati.Screens.Library.poster_tag(row)}

    ~MOB"""
    <Box weight={1.0} on_tap={tap}>
      <Box fill_width={true} background={card} corner_radius={20} shadow={shadow} padding={11}>
        <Column fill_width={true}>
          <Box fill_width={true} height={112} corner_radius={12} background={Palette.placeholder()}>
            {Kati.Screens.Home.still(row.seed)}
          </Box>
          <Spacer size={11} />
          <Text
            text={row.title}
            text_size={14.5}
            font_weight="bold"
            letter_spacing={-0.02}
            text_color={:on_surface}
            max_lines={1}
          />
          {Kati.Screens.Home.watch_meta(row.meta)}
          <Spacer size={10} />
          {Kati.Screens.Home.watch_bar(row.progress || 0.0)}
        </Column>
      </Box>
    </Box>
    """
  end

  # `S2 · E6 · 18m left` is the drawing's, and nothing writes either half of it
  # — see the moduledoc. A real card carries the same fact as a bar and says
  # nothing it cannot source.
  @doc false
  def watch_meta(nil), do: ~MOB"<Spacer size={0} />"

  def watch_meta(meta) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={3} />
      <Text
        text={meta}
        font_family="mono"
        text_size={10.5}
        text_color={Palette.muted()}
        max_lines={1}
      />
    </Column>
    """
  end

  @doc """
  The continue-watching rail — 4pt, radius 2, ink on `#E7E3DC`, the design's
  `height:4px;border-radius:2px` twice over in screen 01.

  Chelekom's headless Progress in `render: :box`. Under the native mode this is
  Material's `LinearProgressIndicator`: it fills its parent, draws its own
  track in a colour that is not a prop, and carries whatever thickness and caps
  the pinned material3 draws that year — so none of the three numbers above
  were expressible, and the card hand-rolled two weighted Boxes instead.

  A finished episode is 100% and an unstarted one 0%; both made the
  hand-rolled shape hand Compose a literal `weight: 0.0` — the crash, not a
  warning. The component omits the node at either end.

  This screen already trusts the same shape elsewhere: `hairline/1` is
  `MishkaSeparator.separator(render: :box)`, which is the identical
  track-Box-with-a-trailing-`Spacer`, and it draws as a 1pt rule.
  """
  @spec watch_bar(float()) :: map()
  def watch_bar(progress) do
    MishkaProgress.progress(
      render: :box,
      value: progress,
      max: 1,
      height: 4,
      corner_radius: 2,
      color: Palette.ink(),
      track_color: Palette.track()
    )
  end

  # The 520x384 crop, which is what the design draws in these cards — a
  # different photograph from the 400x600 poster of the same title, not the
  # same image scaled.
  @doc false
  def still(seed) do
    case Kati.Design.Images.path(seed, {520, 384}) do
      nil ->
        ~MOB"<Spacer size={0} />"

      src ->
        ~MOB"""
        <Image src={src} fill_width={true} height={112} corner_radius={12} content_mode="fill" />
        """
    end
  end

  @doc """
  The Watching band — one row, and the same row screen 24 draws.

  The 23 August redraw puts *My services* on Home as well as in Settings, and
  the reason is what the row answers: **what can I actually watch**. Every
  recommendation, every "leaving on Friday", every *What fits tonight* is
  downstream of it, and a user whose services are wrong gets a home page full
  of confident nonsense with no visible cause.

  The row is built here rather than read from `Kati.Settings.Sample.watching/0`,
  which is where it used to come from and is why the card said *United Kingdom ·
  3 subscribed* on a device with no services: that function's subtitle counts
  `Kati.Screens.MyServices.subscribed/0`, and that reader answers an empty table
  with the drawing's three rows. `Kati.Services.subscribed_count/0` is the
  number, and the moduledoc says why 92's own fallback is left alone.

  **The card stays when the count is nought.** Screen 96 puts a *My services*
  action under all four of its empty bands — the rule is *offer the one thing
  that fixes it* — and this row, with its chevron into screen 92, already is
  that action. What changes is the sentence, not the card.
  """
  @spec watching(map()) :: map()
  def watching(services) do
    row =
      Kati.UI.SettingsList.row(
        Kati.UI.SettingsList.icon_tile("subscriptions"),
        Kati.UI.SettingsList.body("My services", Kati.Screens.Home.services_line(services)),
        Kati.UI.SettingsList.chevron(),
        rule: false,
        on_tap: {self(), :open_services}
      )

    assigns = %{card: Kati.UI.SettingsList.card([row])}

    ~MOB"""
    <Column fill_width={true}>
      {@card}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The row's second line: the region and the count, or screen 96's sentence.

  `United Kingdom · 0 subscribed` is exactly what 96 refuses — *"an empty
  ledger, not £0.00 a month — there is nothing here to be zero"* — so nought
  gets that board's own words for this state rather than a nought. The region
  goes with them: it is the precondition availability is answered against, and
  with nothing set up there is nothing for it to qualify.
  """
  @spec services_line(map()) :: String.t()
  def services_line(%{count: 0}), do: "No subscriptions yet"
  def services_line(%{region: region, count: count}), do: "#{region} · #{count} subscribed"

  @doc false
  def sections(tiles) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {Kati.Screens.Home.tiles(tiles)}
      </Row>
      <Spacer size={26} />
    </Column>
    """
  end

  @doc false
  def tiles(rows) do
    rows
    |> Enum.map(&Kati.Screens.Home.tile/1)
    |> Enum.intersperse(Kati.Screens.Home.tile_gap())
  end

  @doc false
  def tile_gap, do: ~MOB"<Spacer size={9} />"

  @doc false
  def tile(%{icon: icon, title: title, meta: meta, dot: dot, tag: tag}) do
    card = Palette.card()
    shadow = Theme.shadow_card_soft()
    tap = {self(), tag}

    ~MOB"""
    <Box weight={1.0} on_tap={tap}>
      <Box
        fill_width={true}
        background={card}
        corner_radius={18}
        shadow={shadow}
        padding_left={12}
        padding_right={12}
        padding_top={13}
        padding_bottom={13}
      >
        <Column fill_width={true}>
          <Row fill_width={true} align="center">
            {UI.symbol(icon, size: 19)}
            <Spacer weight={1.0} />
            {Kati.Screens.Home.dot(dot)}
          </Row>
          <Spacer size={10} />
          <Text
            text={title}
            text_size={12.5}
            font_weight="bold"
            letter_spacing={-0.01}
            text_color={:on_surface}
            max_lines={1}
          />
          {Kati.Screens.Home.tile_meta(meta)}
        </Column>
      </Box>
    </Box>
    """
  end

  @doc false
  def dot(nil), do: ~MOB"<Spacer size={0} />"
  def dot(color), do: ~MOB"<Box width={6} height={6} corner_radius={3} background={color} />"

  @doc false
  def tile_meta(nil), do: ~MOB"<Spacer size={0} />"

  def tile_meta(meta) do
    ~MOB"""
    <Column>
      <Spacer size={3} />
      <Text
        text={meta}
        font_family="mono"
        text_size={9.5}
        text_color={Palette.muted()}
        max_lines={1}
      />
    </Column>
    """
  end

  @doc """
  The two rows the drawing puts in this card.

  Stand-in data, marked as such, and — since this round — **unreachable from a
  render**, exactly as `Kati.Screens.Library.drawn_titles/0` is. It is what
  `test/design/screens/01.html` was captured from and what
  `Kati.ScreenDesignLiteralTest.drawn_state/0` installs into `:timeline` to
  compare this card against its board.

  It used to be `rest_of_today/1`'s answer for an empty day, on FIDELITY's rule
  that *missing data is not a reason for a blank screen*. That rule was applied
  to the wrong thing: an empty day is not missing data, it is a day with nothing
  on it, and the card said `21:30 · Call Mum · Repeats weekly` to a person who
  has never opened a calendar.
  """
  @spec drawn_rows() :: [map()]
  def drawn_rows do
    [
      %{
        time: "20:00",
        title: "The Long Hollow — S2E6",
        meta: "Airs tonight · Lumen+",
        # The kind the board draws, which the transcription had been missing:
        # `Airs tonight` is an air date and `Repeats weekly` is a reminder, and
        # `Kati.Calendars.Today.row/2` puts that field on every real row. It was
        # absent while nothing read it; a row's tag is read off it now, and
        # `Kati.Screens.Calendar.kind/1` matches on the key rather than
        # defaulting, so a row without one is a FunctionClauseError.
        kind: :air_date,
        now?: true
      },
      %{
        time: "21:30",
        title: "Call Mum",
        meta: "Repeats weekly",
        kind: :reminder,
        now?: false
      }
    ]
  end

  @doc """
  A day with nothing on it, in screen 01's own card.

  The sentence is screen 139's, verbatim — *Nothing scheduled — add anything
  with +* — and the `+` it names is the FAB `Kati.Shell` draws over this page,
  so the affordance the sentence points at is on screen here as it is there.

  **No artboard draws this combination and that is stated rather than hidden.**
  01 draws the card full; 139 draws the sentence, but as a `Today` row in a
  settings list on a page where nothing else exists either. Lifting 139's whole
  row up here would import a `Today` title and a chevron that duplicate the
  eyebrow and the *See all* beside it. So what is borrowed is the one thing 139
  contributes that this screen does not have — the words for an empty day — and
  the container is this screen's own. Screen 96 is what makes that the right
  call rather than a convenient one: *"an empty state should say what is
  missing and offer the one thing that fixes it — never render a
  plausible-looking zero."*
  """
  @spec rest_of_today([map()]) :: map()
  def rest_of_today([]) do
    card = Palette.card()

    ~MOB"""
    <Box
      fill_width={true}
      background={card}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card()}
      padding_left={15}
      padding_right={15}
      padding_top={20}
      padding_bottom={20}
    >
      <Text
        text="Nothing scheduled — add anything with +"
        text_size={13}
        line_height={1.55}
        text_color={Palette.sub()}
      />
    </Box>
    """
  end

  def rest_of_today(rows) do
    card = Palette.card()
    last = length(rows) - 1

    ~MOB"""
    <Box
      fill_width={true}
      background={card}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card()}
      padding_left={15}
      padding_right={15}
      padding_top={5}
      padding_bottom={5}
    >
      <Column fill_width={true}>
        {rows |> Enum.with_index() |> Enum.map(fn {row, i} ->
          Kati.Screens.Home.timeline_row(row, i < last)
        end)}
      </Column>
    </Box>
    """
  end

  @doc false
  def timeline_row(row, rule?) do
    accent = if row.now?, do: Palette.accent(), else: Palette.rail_idle()
    icon = if row.now?, do: "notifications_active", else: "radio_button_unchecked"

    # Screen 02 draws these rows and opens them, off the same
    # `Kati.Calendars.Today` shape; this card is that timeline with the day's
    # spent hours dropped. `Kati.Screens.Calendar.tag/1` is borrowed rather
    # than restated so one row cannot have two names — see that function's own
    # doc for why the id is in the atom and why it is optional.
    tap = {self(), Kati.Screens.Calendar.tag(row)}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={14} padding_bottom={14} on_tap={tap}>
        <Box width={40}>
          <Text
            text={row.time}
            font_family="mono"
            text_size={12}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Box>
        <Spacer size={14} />
        <Box width={3} height={34} corner_radius={2} background={accent} />
        <Spacer size={14} />
        <Column weight={1.0}>
          <Text
            text={row.title}
            text_size={14}
            font_weight="semibold"
            letter_spacing={-0.01}
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={3} />
          <Text text={row.meta} text_size={12} text_color={Palette.sub()} max_lines={1} />
        </Column>
        <Spacer size={14} />
        {UI.symbol(icon, size: 20, color: Palette.rail_idle())}
      </Row>
      {Kati.Screens.Home.hairline(rule?)}
    </Column>
    """
  end

  # Chelekom's headless Separator, given the design's own 7%-ink rule colour.
  #
  # `render: :box` is load-bearing, and the comment that used to sit here was
  # wrong about why. The default `:divider` is NOT the hand-rolled Box this
  # replaced: the bridge maps it to Material3's `HorizontalDivider`, which is a
  # Canvas drawing an ANTIALIASED `drawLine`, not a filled rect. At this
  # device's 2.6875x a 1dp rule gets a 3px canvas and a 2.6875px stroke, so the
  # last pixel row lands at ~69% coverage — a hairline 4-5/255 lighter than the
  # design's on one full-width row. `render: :box` swaps the primitive back to
  # `<Box fill_width height={1} background={color}>`, which is the node this
  # screen drew by hand, so every pixel row carries the full colour again.
  @doc false
  def hairline(false), do: ~MOB"<Spacer size={0} />"

  def hairline(true),
    do: MishkaSeparator.separator(color: Palette.hairline(), thickness: 1, render: :box)

  @doc "Today's date line and greeting, in the device's zone."
  def today do
    now = Kati.Time.now()
    day = Kati.Time.day_name(now)
    month = Kati.Time.month_name(now.month)

    greeting =
      cond do
        now.hour < 12 -> "Good morning"
        now.hour < 18 -> "Good afternoon"
        true -> "Good evening"
      end

    {"#{day} · #{now.day} #{month}", greeting}
  end

  @impl true
  def handle_tap(:open_inbox, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Inbox)}

  # The bell opens the gallery for now. Every page needs to be reachable
  # before any of it can be checked, and this is the one tap that does it.
  # The bell opened `Kati.Screens.Gallery` for as long as the gallery was the
  # only way to reach 53 screens that had landed at once. Every one of them is
  # reachable from its own place now, so the bell means what a bell means:
  # `Kati.Screens.InboxNotifications`, which is where Kati's badge-instead-of-
  # push manners are visible. The gallery moved to Settings → About, which is
  # where a page that describes the app belongs.
  def handle_tap(:notifications, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.InboxNotifications)}

  def handle_tap(:open_settings, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Settings)}

  # The three tags the empty branch draws that the full page does not, each
  # answered with the screen `Kati.Screens.HomeEmpty.handle_tap/2` answers it
  # with — the page is drawn once, so its controls must mean one thing.
  def handle_tap(:choose_sections, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.PickSections)}

  def handle_tap(:restore_backup, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Restore)}

  # Drawn on BOTH branches and, until now, wired on neither: the header's
  # `calendar_month` disc has carried this tag since screen 01 was built and
  # reached the `_tag` catch-all below, which is why
  # `Kati.ScreenTapSweepTest`'s backlog listed it. 139's *Today* row carries
  # the same tag, so the empty branch would have shipped a second dead control
  # rather than one. `Kati.Screens.Calendar` is the root both mean, and it is
  # what `Kati.Screens.HomeEmpty` already pushed.
  def handle_tap(:open_calendar, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Calendar)}

  def handle_tap(:open_services, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.MyServices)}

  def handle_tap(:open_meals, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.MealsToday)}

  def handle_tap(:open_habits, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Habits)}

  # Screen 86 rather than 19, and the two are different states rather than a
  # replacement: 86 is the empty field the moment it opens — which is what a tap
  # on this one produces — and 19 is *Search everything* with results showing,
  # reached from the Library. Both are drawn and both are worth being able to
  # look at.
  def handle_tap(:open_search, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.SearchIdle)}

  # *See all* over the day's own card. Screen 02 with no params opens on
  # `Kati.Time.today()` by its own `load/1`, which is the day this card is —
  # so the date the survey asks this tap to carry is carried by the
  # destination rather than dropped. It cannot be named in the push either
  # way: 02 is a root and `Kati.Screens.Root.mount/3` discards params.
  #
  # The header's `calendar_month` disc opens the same root, and that is the
  # board's arrangement rather than a duplicate: 01 draws both, and a page
  # reached two ways from one screen is what a section label and a header
  # control are for.
  def handle_tap(:see_all_today, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Calendar)}

  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      # A Rest-of-today row, routed exactly as screen 02 routes the same row —
      # see `Kati.Screens.Calendar.open_timeline_row/3`. The card is today, so
      # today is the date a meals or money row is opened on.
      "row_" <> _rest ->
        {:noreply, Kati.Screens.Calendar.open_timeline_row(socket, tag, Kati.Time.today())}

      # A continue-watching card, by its own title. `Kati.Screens.Library`
      # answers the identical two prefixes for the identical rows; the only
      # difference is which assign the tag is resolved against.
      "open_film_" <> _title ->
        {:noreply, Kati.Screens.Home.open_watching(socket, tag, Kati.Screens.Film)}

      "open_series_" <> _title ->
        {:noreply, Kati.Screens.Home.open_watching(socket, tag, Kati.Screens.Series)}

      _other ->
        {:noreply, socket}
    end
  end

  @doc """
  Open `module` on the continue-watching card that carries `tag`.

  `Kati.Screens.Library.open_tile/3`'s rule, over this screen's own assign: the
  tag is resolved back to its row by running `poster_tag/1` over the very list
  the band was built from rather than by reversing the string, and a row with
  no id — every row of `drawn_continue_watching/0` — pushes with **no params at
  all** rather than with `%{id: nil}`, so the destination's drawing is the
  branch that survives.
  """
  @spec open_watching(Mob.Socket.t(), atom(), module()) :: Mob.Socket.t()
  def open_watching(socket, tag, module) do
    # `Map.get` and not `socket.assigns.continue`: this is dispatched from
    # sweeps and from `Kati.ScreenHomeEmptyStateTest`, which press a tag against
    # a socket built by hand, and a `KeyError` raised inside a tap handler is a
    # crash where the honest answer is *no row of that name*. A missing assign
    # and an empty band mean the same thing here, and both take the bare push
    # the doc below describes.
    rows = Map.get(socket.assigns, :continue, [])
    row = Enum.find(rows, &(Kati.Screens.Library.poster_tag(&1) == tag))

    case row && Map.get(row, :id) do
      nil -> Mob.Socket.push_screen(socket, module)
      id -> Mob.Socket.push_screen(socket, module, %{id: id})
    end
  end
end
