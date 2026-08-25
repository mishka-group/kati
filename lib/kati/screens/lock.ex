defmodule Kati.Screens.Lock do
  @moduledoc """
  Screen 29 — the lock screen and its widgets.

  Built to `test/design/screens/29.html`: a full-bleed wallpaper under a
  three-stop scrim, the clock, then three glass widgets — small, small,
  medium, large — off one data model.

  ## What the drawing is claiming

  *Three widget sizes off one data model*: what to watch next, how loaded
  tonight is, and the year as a pixel field. The two rows in the Today widget
  are the same two events screen 28 lists under *Rest of today*, at the same
  times, on the same evening. The pixel field is the same visual as the Stats
  hero at a different scale. Nothing here is invented for the lock screen; it
  is the app, quoted.

  The design's caption also names the one borrowed idea: *the glass treatment
  is the only place the app borrows from the OS*. Everywhere else Kati draws
  its own surfaces.

  ## Glass, without a backdrop filter

  The drawing asks for `backdrop-filter: blur(22px)` behind a
  `rgba(28,26,24,.5)` fill. Android has no backdrop blur through Mob — the
  same limit `Kati.Theme.chrome_fill/1` records for the dock — so this ships
  as the flat half-alpha fill over the wallpaper, with the drawing's
  `rgba(255,255,255,.14)` inset ring as a border. The intent, a panel that
  reads as sitting *on* the photograph, survives; the literal blur does not.

  ## No frame, no dock, no gutters at the top level

  The wallpaper runs edge to edge and bezel to bezel behind everything; the
  scroll over it carries `padding: 0 0 40px`, and the 21pt gutters start inside
  that, at 52 from the top rather than the usual 64. Tapping anywhere
  dismisses, since a lock screen with no way off it is a dead end on a device
  with a software back gesture.

  ## Nothing here is a Chelekom component, and that is the finding

  Every part of this screen was re-checked against the vendored set after the
  chip/pill/action-icon props landed, and none of it fits. The reason is one
  sentence: **the glass panels are not containers around content, they are the
  content's own surface.** Each is a `Column` that draws its own fill, its
  `rgba(255,255,255,.14)` inset ring and 14-16pt of padding, and then stacks an
  eyebrow, a poster, two `Text` runs and sometimes a 7x7 pixel grid inside it.
  `MishkaThemeIcon` and `MishkaActionIcon` are containers around exactly *one*
  icon; `MishkaPill` and `MishkaChip` put their content in a `Row`, which would
  set every widget's title beside its eyebrow rather than under it.

  What that asks for upstream is a headless **card** — a container that takes a
  fill, a radius, a border, a shadow and padding and then gets out of the way of
  a `Column` of children. Kati draws that shape 262 times across the app and has
  no component for it in any of them.

  ## Where the widgets come from

  `Kati.Screens.Lock.Sample` puts the requirement in one sentence — *a widget
  that could disagree with the app it came from is worse than no widget* — and a
  widget frozen at the evening the design was drawn disagrees with the app every
  day but that one. So the three data widgets read the domains the screens they
  quote read, and each says which:

    * **Up next** is `Kati.Media.TrackedTitle` at `:watching`, newest touch
      first, joined to `Kati.Media.CachedTitle` by the `{source, source_id}`
      **value pair** the durable row references the cache by. That is the same
      row `Kati.Screens.UpNext` puts in its hero, chosen by the same rule, so
      the widget and the screen it is a widget for cannot name two different
      titles. `S2E6` is `progress_season`/`progress_episode`, the bookmark that
      resource stores for exactly this, and `18M` is `progress_seconds` against
      `runtime_minutes` — the one arithmetic, done where the units are visible.
    * **Tonight** is episode-level, so it is `Kati.Media.CachedEpisode` for the
      titles `Kati.Media.TrackedTitle`'s own `:followed` action returns —
      finished and dropped shows excluded, because that action's whole reason is
      *the titles the release watcher has any business looking at*. Whether an
      episode airs today is asked of `Kati.Media.Release.air/1` and nowhere else:
      it is the one date path, and a `:month`-confidence air date read as a day
      would put a show on tonight's count that nobody said airs tonight.
    * **Today** is `Kati.Calendars.Today.rows/1` — the same call
      `Kati.Screens.HomeDark` makes for *Rest of today*, which is what keeps
      screens 28 and 29 the same evening rather than two evenings that happen to
      rhyme. `N LEFT` counts the rows still ahead on the device's own clock.
    * **This year** is `Kati.Media.Watch` joined through the durable row to the
      cache, which is what `Kati.Screens.Stats` folds its whole hero out of. The
      hours, the streak and the pixel field are the same three facts screen 07
      reports, deliberately by the same arithmetic — see `year_field/1` — because
      two numbers that are the same fact must not disagree.

  Each widget falls back to its drawn self when its own source has nothing to
  say, the way `Kati.Screens.Home` substitutes one card at a time rather than
  gating the page. FIDELITY's rule: *missing data is not a reason for a blank
  screen*. The Sample stays exactly where it is; it is the fallback and the
  fixture, not a stage this screen has passed through.

  ## The clock and the wallpaper stay drawn

  Two parts do not move, for two different reasons.

  **The clock** is pinned because screen 28 is drawn at the same evening and the
  two have to agree about it, and because replacing `Sunday 16 August` and
  `21:40` with the device's own would need two more entries on
  `Kati.ScreenDesignLiteralTest`'s allow-list, which is capped at four with the
  note that raising the bound is *a decision to check less*.

  **The wallpaper** is pinned because Kati does not have one. It stores no
  photograph and cannot read the one the OS is showing, so the picture behind
  the glass is the design's and nothing in any resource could replace it.
  """
  use Mob.Screen
  import Mob.Sigil

  require Ash.Query

  alias Kati.Media.CachedEpisode
  alias Kati.Media.CachedTitle
  alias Kati.Media.Release
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Screens.Lock.Sample

  # The pixel field's own shape. 78 cells chunked 33 to a row is where the
  # drawing's `flex-wrap` breaks, and `Kati.Screens.Lock.Sample.year/0` sets out
  # at length why 33 rather than a count reasoned from the device's width. Both
  # numbers are stated here as well because a field built from watch history has
  # to be built to the same shape the drawn one is, or the two render as
  # different objects.
  @field_days 78
  @field_row 33

  def mount(_params, _session, socket) do
    Mob.Theme.set(Kati.Theme.dark())
    {:ok, Mob.Socket.assign(socket, :widgets, widgets())}
  end

  @doc """
  The four widgets this screen draws, each the user's own or each the drawing's.

  Per widget rather than per page: they are four independent objects on a
  wallpaper, not four cards of one page, and a lock screen that hid the user's
  real *Up next* because their calendar is not mirrored would be withholding the
  one thing it is for. `Kati.Screens.Film` gates its whole page for the opposite
  reason and says so — there every value describes one film.
  """
  @spec widgets() :: map()
  def widgets do
    %{
      clock: Sample.clock(),
      up_next: up_next() || Sample.up_next(),
      tonight: tonight() || Sample.tonight(),
      today: today() || Sample.today(),
      year: year() || Sample.year()
    }
  end

  @doc """
  Screen 29 exactly as it is drawn, from `Kati.Screens.Lock.Sample`.

  Kept as the fixture rather than inlined here, for the reason
  `Kati.Screens.Film.drawn_film/0` gives: it is the frame's specification and
  the value a test compares a real render against, and two copies of the
  drawing's copy is exactly how the two drift apart.
  """
  @spec drawn_widgets() :: map()
  def drawn_widgets do
    %{
      clock: Sample.clock(),
      up_next: Sample.up_next(),
      tonight: Sample.tonight(),
      today: Sample.today(),
      year: Sample.year()
    }
  end

  # The wallpaper and its scrim are siblings of the `Scroll`, not children of
  # it. A lock screen's photograph has to reach the bottom bezel on any device,
  # and the only honest way to say that is `fill_height` — but a vertical
  # `Scroll` hands its children an unbounded height, where `fill_height` is a
  # no-op that collapses back to wrap-content. Directly inside this root Box
  # the bound is the viewport, so the picture ends where the screen does. (It
  # was a declared 810 before, which left a hard #121110 band under it on any
  # display taller than that.) The Box stacks, so the scrolling content still
  # draws over the photograph.
  def render(assigns) do
    dismiss = {self(), :dismiss}
    w = assigns.widgets

    ~MOB"""
    <Box
      fill_width={true}
      fill_height={true}
      background={:background}
      layout_direction={Kati.Locale.direction_prop()}
      accessibility_id={Kati.Screens.Identity.of(__MODULE__)}
      on_tap={dismiss}
    >
      {Kati.Screens.Lock.wallpaper()}
      {Kati.Screens.Lock.scrim()}
      <Scroll>
        <Column
          fill_width={true}
          padding_left={21}
          padding_right={21}
          padding_top={52}
          padding_bottom={40}
        >
          {Kati.Screens.Lock.clock(w.clock)}
          {Kati.Screens.Lock.small_widgets(w.up_next, w.tonight)}
          {Kati.Screens.Lock.today_card(w.today)}
          {Kati.Screens.Lock.year_card(w.year)}
        </Column>
      </Scroll>
    </Box>
    """
  end

  def handle_info({:tap, :dismiss}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}
  def handle_info(_message, socket), do: {:noreply, socket}

  @doc false
  def wallpaper do
    case Kati.Design.Images.hero(Sample.wallpaper()) do
      nil ->
        ~MOB"<Box fill_width={true} fill_height={true} background={0xFF1C1A18} />"

      src ->
        ~MOB"""
        <Image src={src} fill_width={true} fill_height={true} content_mode="fill" />
        """
    end
  end

  # Three stops, not two: the photograph is darkened at both ends and left
  # alone across the middle 40%, so the clock reads at the top and the widgets
  # read at the bottom without flattening the picture between them.
  @doc false
  def scrim do
    ~MOB"""
    <Box
      fill_width={true}
      fill_height={true}
      gradient="to_bottom #8C0C0B0A #400C0B0A 40% #CC0C0B0A"
    />
    """
  end

  # 74pt at weight 300 — the only place in the app that asks for a light
  # weight, and the reason is the OS: a lock clock is thin everywhere, so a
  # bold one would read as Kati shouting over the system rather than sitting
  # in it.
  #
  # Known gap: `res/font/` ships Plus Jakarta Sans 400–800, so there is no 300
  # face for Compose to resolve `FontWeight.Light` against and it falls back to
  # 400. The prop stays as the design writes it, because the day a 300 face
  # ships this line becomes correct with no edit; recorded here rather than
  # silently rounded to `"medium"`.
  @doc false
  def clock(now) do
    ~MOB"""
    <Column fill_width={true} padding_top={14}>
      <Row fill_width={true} align="center">
        <Spacer weight={1.0} />
        <Text
          text={now.date}
          font_family="mono"
          text_size={14}
          letter_spacing={0.06}
          text_color={0xD9FFFFFF}
          max_lines={1}
        />
        <Spacer weight={1.0} />
      </Row>
      <Spacer size={2} />
      <Row fill_width={true} align="center">
        <Spacer weight={1.0} />
        <Text
          text={now.time}
          text_size={74}
          font_weight="light"
          letter_spacing={-0.04}
          line_height={1.05}
          text_color={0xFFFFFFFF}
          max_lines={1}
        />
        <Spacer weight={1.0} />
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  # A declared 97pt on both, because the two widgets are the same object at the
  # same size in the drawing and their contents are not: a 42pt poster on the
  # left against a 28pt figure and two lines on the right measured 91 and 97,
  # and two glass panels six points out of step read as a mistake. The height
  # goes on the weighted Box and the panel fills it — putting it on the panel
  # itself would land outside its 14pt padding and measure 125.
  @doc false
  def small_widgets(up_next, tonight) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Box weight={1.0} height={97}>
          <Column
            fill_width={true}
            fill_height={true}
            background={0x801C1A18}
            corner_radius={20}
            border_width={1}
            border_color={0x24FFFFFF}
            padding={14}
          >
            {Kati.Screens.Lock.eyebrow(up_next.eyebrow)}
            <Spacer size={10} />
            <Row fill_width={true} align="center">
              {Kati.Screens.Lock.thumb(up_next)}
              <Spacer size={9} />
              <Column weight={1.0}>
                <Text
                  text={up_next.title}
                  text_size={12}
                  font_weight="bold"
                  text_color={0xFFFFFFFF}
                  max_lines={1}
                />
                <Spacer size={3} />
                <Text
                  text={up_next.meta}
                  font_family="mono"
                  text_size={9.5}
                  text_color={0x99FFFFFF}
                  max_lines={1}
                />
              </Column>
            </Row>
          </Column>
        </Box>
        <Spacer size={11} />
        <Box weight={1.0} height={97}>
          <Column
            fill_width={true}
            fill_height={true}
            background={0x801C1A18}
            corner_radius={20}
            border_width={1}
            border_color={0x24FFFFFF}
            padding={14}
          >
            {Kati.Screens.Lock.eyebrow(tonight.eyebrow)}
            <Spacer size={8} />
            <Text
              text={tonight.count}
              text_size={28}
              max_font_scale={1.6}
              font_weight="extrabold"
              letter_spacing={-0.03}
              text_color={0xFFFFFFFF}
              max_lines={1}
            />
            <Spacer size={2} />
            <Text text={tonight.label} text_size={10.5} text_color={0xA6FFFFFF} max_lines={1} />
          </Column>
        </Box>
      </Row>
      <Spacer size={11} />
    </Column>
    """
  end

  # No accent dash here. On the lock screen the widget titles are the OS's
  # idiom — mono, letter-spaced, half-alpha — and Kati's orange dash would
  # claim more of the wallpaper than a widget label should.
  @doc false
  def eyebrow(label) do
    ~MOB"""
    <Text
      text={label}
      font_family="mono"
      text_size={9}
      letter_spacing={0.14}
      text_color={0x8CFFFFFF}
      max_lines={1}
    />
    """
  end

  @doc false
  def thumb(widget) do
    case Kati.Design.Images.poster(widget.seed) do
      nil ->
        ~MOB"<Box width={30} height={42} corner_radius={5} background={0x26FFFFFF} />"

      src ->
        ~MOB"""
        <Image src={src} width={30} height={42} corner_radius={5} content_mode="fill" />
        """
    end
  end

  @doc false
  def today_card(widget) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={0x801C1A18}
        corner_radius={22}
        border_width={1}
        border_color={0x24FFFFFF}
        padding={16}
      >
        <Row fill_width={true} align="center">
          {Kati.Screens.Lock.eyebrow(widget.eyebrow)}
          <Spacer weight={1.0} />
          {Kati.UI.symbol("calendar_month", size: 15, color: 0x8CFFFFFF)}
        </Row>
        <Spacer size={12} />
        {widget.rows
         |> Enum.map(fn row -> Kati.Screens.Lock.today_row(row) end)
         |> Enum.intersperse(Kati.Screens.Lock.row_gap())}
      </Column>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc false
  def row_gap, do: ~MOB"<Spacer size={10} />"

  @doc false
  def today_row(row) do
    rail = if row.now?, do: 0xFFE8823C, else: 0x66FFFFFF

    ~MOB"""
    <Row fill_width={true} align="center">
      <Column width={36}>
        <Text
          text={row.time}
          font_family="mono"
          text_size={10.5}
          text_color={0x99FFFFFF}
          max_lines={1}
        />
      </Column>
      <Spacer size={11} />
      <Box width={2.5} height={16} corner_radius={2} background={rail} />
      <Spacer size={11} />
      <Text
        text={row.title}
        text_size={12}
        font_weight="semibold"
        text_color={0xFFFFFFFF}
        weight={1.0}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc false
  def year_card(field) do
    ~MOB"""
    <Column
      fill_width={true}
      background={0x801C1A18}
      corner_radius={22}
      border_width={1}
      border_color={0x24FFFFFF}
      padding={16}
    >
      {Kati.Screens.Lock.eyebrow(field.eyebrow)}
      <Spacer size={12} />
      {Enum.map(field.rows, fn row -> Kati.Screens.Lock.pixel_row(row) end)}
      <Spacer size={8} />
      <Row fill_width={true} align="center">
        <Text
          text={field.watched}
          font_family="mono"
          text_size={9.5}
          text_color={0x80FFFFFF}
          max_lines={1}
        />
        <Spacer weight={1.0} />
        <Text
          text={field.streak}
          font_family="mono"
          text_size={9.5}
          text_color={0x80FFFFFF}
          max_lines={1}
        />
      </Row>
    </Column>
    """
  end

  @doc false
  def pixel_row(row) do
    ~MOB"""
    <Column>
      <Row>
        {row
         |> Enum.map(fn level -> Kati.Screens.Lock.pixel(level) end)
         |> Enum.intersperse(Kati.Screens.Lock.pixel_gap())}
      </Row>
      <Spacer size={3} />
    </Column>
    """
  end

  @doc false
  def pixel_gap, do: ~MOB"<Spacer size={3} />"

  @doc false
  def pixel(level) do
    color = Sample.intensity(level)

    ~MOB"""
    <Box width={7} height={7} corner_radius={2} background={color} />
    """
  end

  # ── Up next, out of Kati.Media ──────────────────────────────────────────────
  #
  # Two reads: the shelf row this widget is about, and the one cache row it
  # names. Never one read per anything — there is exactly one title here.

  defp up_next do
    case watching() do
      nil -> nil
      tracked -> up_next_widget(tracked, cached_for(tracked))
    end
  rescue
    # The degradation `Kati.Screens.Library.shelf/0` and `Kati.Calendars.Today`
    # both make: a store that cannot be reached draws the drawing rather than
    # taking the activity down. A lock screen is the worst possible place to
    # raise from, because it is the one the user did not choose to open.
    _ -> nil
  end

  # `archived == false and status == :watching`, newest touch first — written
  # out here exactly as `Kati.Screens.UpNext` writes it, because it is that
  # screen's hero this widget is quoting and `:shelf` filters by kind rather
  # than by status. `archived` is excluded for the reason the column exists:
  # *keeps history, hides from shelf*.
  defp watching do
    TrackedTitle
    |> Ash.Query.filter(archived == false and status == :watching)
    |> Ash.Query.sort(last_touched_at: :desc)
    |> Ash.Query.limit(1)
    |> Ash.read!()
    |> List.first()
  end

  # By the VALUE PAIR, not a foreign key. A wiped cache leaves the durable row
  # and its position untouched, and this answers `nil` — which `up_next_widget/2`
  # treats as an ordinary state rather than an error.
  defp cached_for(%TrackedTitle{source: source, source_id: source_id}) do
    CachedTitle
    |> Ash.Query.filter(source == ^source and source_id == ^source_id)
    |> Ash.read_one!()
  end

  # `eyebrow` is the widget's own name — every lock screen's UP NEXT widget says
  # UP NEXT — so it is kept from the drawn widget rather than written a second
  # time here. The three values under it are the user's.
  defp up_next_widget(tracked, cached) do
    %{
      Sample.up_next()
      | title: title_of(cached),
        meta:
          Enum.join(
            Enum.reject([episode_label(tracked), left_label(tracked, cached)], &is_nil/1),
            " · "
          ),
        seed: seed_of(tracked, cached)
    }
  end

  # The answer `Kati.Screens.Film` and `Kati.Screens.UpNext` both give: the
  # memory survived the eviction and the poster did not, so the widget says so
  # rather than naming somebody else's show.
  defp title_of(%CachedTitle{title: title}) when is_binary(title) and title != "", do: title
  defp title_of(_cached), do: "Untitled"

  # `Kati.Seeds` writes the design's own seed into `poster_path` and
  # `sample_source_id/1` is the other half of that convention, so a row whose
  # cache row has gone can still find its picture. A real provider path is a
  # path `Kati.Design.Images.poster/1` will not find, and `thumb/1` already
  # draws the empty rectangle for that.
  defp seed_of(tracked, cached) do
    case cached do
      %CachedTitle{poster_path: path} when is_binary(path) and path != "" -> path
      _ -> Kati.Seeds.sample_seed(tracked.source_id)
    end
  end

  # `S2E6`, run together the way this widget writes it — `Kati.Screens.UpNext`
  # spaces the same two numbers as `S2 · E6`, because it has a whole row to put
  # them on and this has 30pt beside a poster.
  defp episode_label(%TrackedTitle{progress_season: season, progress_episode: episode})
       when is_integer(season) and is_integer(episode),
       do: "S#{season}E#{episode}"

  defp episode_label(%TrackedTitle{progress_episode: episode}) when is_integer(episode),
    do: "E#{episode}"

  defp episode_label(_tracked), do: nil

  # `18M` is what is LEFT, which needs both halves: the resume point on the
  # durable row and the runtime on the cached one. With no resume point the
  # widget says how long the thing is instead of inventing a position, and with
  # neither it says nothing at all rather than `0M`.
  defp left_label(tracked, cached) do
    case {tracked.progress_seconds, runtime_seconds(cached)} do
      {done, total} when is_integer(done) and is_integer(total) and total > done and done > 0 ->
        "#{div(total - done, 60)}M"

      {_done, total} when is_integer(total) ->
        minutes_label(div(total, 60))

      _neither ->
        nil
    end
  end

  defp runtime_seconds(%CachedTitle{runtime_minutes: m}) when is_integer(m) and m > 0, do: m * 60
  defp runtime_seconds(_cached), do: nil

  defp minutes_label(minutes) do
    case {div(minutes, 60), rem(minutes, 60)} do
      {0, m} -> "#{m}M"
      {h, 0} -> "#{h}H"
      {h, m} -> "#{h}H #{m}M"
    end
  end

  # ── Tonight, out of Kati.Media ──────────────────────────────────────────────

  # Two reads: the followed titles, then every episode of any of them with an
  # air date anywhere near today. Not one read per title.
  #
  # `nil` — draw the drawing — means *nothing is followed*, which is a fresh
  # install. A followed library with a quiet evening answers `0`, and `0` is a
  # real answer this widget is allowed to give: "how loaded tonight is" has
  # "not at all" among its answers.
  defp tonight do
    case followed() do
      [] -> nil
      tracked -> %{Sample.tonight() | count: Integer.to_string(airing_today(tracked))}
    end
  rescue
    _ -> nil
  end

  defp followed do
    TrackedTitle
    |> Ash.Query.for_read(:followed)
    |> Ash.read!()
  end

  defp airing_today(tracked) do
    today = Kati.Time.today()
    zone = Kati.Time.device_zone()
    references = MapSet.new(tracked, &{&1.source, &1.source_id})
    ids = tracked |> Enum.map(& &1.source_id) |> Enum.uniq()

    case window_around(today, zone) do
      nil ->
        0

      {from, to} ->
        CachedEpisode
        |> Ash.Query.filter(title_source_id in ^ids and air_at >= ^from and air_at <= ^to)
        |> Ash.read!()
        |> Enum.filter(&MapSet.member?(references, {&1.source, &1.title_source_id}))
        |> Enum.count(&airs_on?(&1, today, zone))
    end
  end

  # A day either side of the device's own day, in UTC. The window is wide
  # because it is only a bound on how much is read — `airs_on?/3` is what
  # decides, and it decides in the device's zone against the confidence the
  # source gave the date.
  defp window_around(day, zone) do
    with {:ok, from} <- Kati.Time.to_utc(NaiveDateTime.new!(day, ~T[00:00:00]), zone),
         {:ok, to} <- Kati.Time.to_utc(NaiveDateTime.new!(day, ~T[23:59:59]), zone) do
      {DateTime.add(from, -86_400, :second), DateTime.add(to, 86_400, :second)}
    else
      _ -> nil
    end
  end

  # `Kati.Media.Release.air/1` and nothing else. The whole point of that module
  # is that a stored instant is only as good as the confidence beside it: an
  # episode a source described as "some time in March" is a `:month` answer with
  # a day component nobody asserted, and counting it as airing tonight is the
  # 1 January bug that module exists to make impossible.
  defp airs_on?(episode, day, zone) do
    case Release.air(episode) do
      {:exact, at, _origin} -> at |> Kati.Time.in_zone(zone) |> DateTime.to_date() == day
      {:day, date, _origin} -> date == day
      _coarse -> false
    end
  end

  # ── Today, out of Kati.Calendars ────────────────────────────────────────────

  # `Kati.Calendars.Today.rows/1` — the same call `Kati.Screens.HomeDark` makes,
  # so the two pages are the same evening rather than two readings of it. That
  # helper already answers `[]` for a device with nothing mirrored and rescues
  # its own read, so there is nothing to rescue here.
  defp today do
    case Kati.Calendars.Today.rows() do
      [] -> nil
      rows -> today_widget(rows)
    end
  end

  defp today_widget(rows) do
    now = Calendar.strftime(Kati.Time.now(), "%H:%M")
    # Zero-padded `HH:MM` sorts chronologically inside one day, and both sides
    # are formatted by the same call against the same zone — so this is one
    # clock compared with itself rather than a time parsed back out of a label.
    left = Enum.filter(rows, &(&1.time >= now))

    %{
      eyebrow: "TODAY · #{length(left)} LEFT",
      # The next two still to come. With nothing ahead the widget shows the last
      # two of the day rather than an empty card — `0 LEFT` is the honest count
      # and a glass panel with nothing in it is not a state the design has.
      rows:
        rows |> ahead_or_tail(left) |> Enum.map(&%{time: &1.time, title: &1.title, now?: &1.now?})
    }
  end

  defp ahead_or_tail(rows, []), do: Enum.take(rows, -2)
  defp ahead_or_tail(_rows, left), do: Enum.take(left, 2)

  # ── This year, out of Kati.Media ────────────────────────────────────────────
  #
  # Two reads, and deliberately the two `Kati.Screens.Stats` makes: the watch log
  # with its durable row loaded, and one query for every cache row those name.
  # The hours and the streak on this widget and on screen 07's hero are the same
  # two facts, so they are folded out of the same list by the same arithmetic —
  # a lock screen that said 312 hours where the app said 289 would be worse than
  # one that said nothing.

  defp year do
    case this_year(watch_entries()) do
      [] -> nil
      entries -> year_field(entries)
    end
  rescue
    _ -> nil
  end

  defp watch_entries do
    watches =
      Watch
      |> Ash.Query.load(:tracked_title)
      |> Ash.read!()
      |> Enum.reject(&is_nil(&1.tracked_title))

    cache = cache_by_reference(watches)
    zone = Kati.Time.device_zone()

    watches
    |> Enum.map(fn watch ->
      cached = Map.get(cache, {watch.tracked_title.source, watch.tracked_title.source_id})
      %{on: watched_on(watch, zone), minutes: cached && cached.runtime_minutes}
    end)
    # A watch with no date at all is real — *"I have seen this, I do not
    # remember when"* is an answer `Kati.Media.Watch` deliberately allows — and
    # every figure on this widget is a question about *when*, so it takes part
    # in none of them.
    |> Enum.reject(&is_nil(&1.on))
  end

  defp cache_by_reference([]), do: %{}

  defp cache_by_reference(watches) do
    ids = watches |> Enum.map(& &1.tracked_title.source_id) |> Enum.uniq()

    CachedTitle
    |> Ash.Query.filter(source_id in ^ids)
    |> Ash.read!()
    |> Map.new(&{{&1.source, &1.source_id}, &1})
  end

  # `watched_on` first: it is the date-valued half, and `Kati.Media.Watch` keeps
  # the two apart because storing "watched on 12 August" as midnight moves it a
  # day the moment the user flies.
  defp watched_on(%Watch{watched_on: %Date{} = date}, _zone), do: date

  defp watched_on(%Watch{watched_at: %DateTime{} = at}, zone),
    do: at |> Kati.Time.in_zone(zone) |> DateTime.to_date()

  defp watched_on(%Watch{}, _zone), do: nil

  defp this_year(entries) do
    year = Kati.Time.today().year
    Enum.filter(entries, &(&1.on.year == year))
  end

  # `eyebrow`, `watched` and `streak` are the drawn widget's, overwritten with
  # the user's own numbers; the words around them — `watched`, `-night streak` —
  # are the widget's copy and are written here beside the arithmetic that fills
  # them.
  defp year_field(entries) do
    hours = div(Enum.sum(Enum.map(entries, &(&1.minutes || 0))), 60)

    %{
      Sample.year()
      | watched: "#{hours}h watched",
        streak: streak_label(longest_run(entries)),
        rows: entries |> field_cells() |> Enum.chunk_every(@field_row)
    }
  end

  defp streak_label(1), do: "1-night streak"
  defp streak_label(nights), do: "#{nights}-night streak"

  # Nights, not watches: two films on one evening is one night. Same fold
  # `Kati.Screens.Stats` uses for the same sentence on screen 07.
  defp longest_run(entries) do
    entries
    |> Enum.map(& &1.on)
    |> Enum.uniq()
    |> Enum.sort(Date)
    |> Enum.reduce({0, 0, nil}, fn date, {best, run, previous} ->
      run = if previous && Date.diff(date, previous) == 1, do: run + 1, else: 1
      {max(best, run), run, date}
    end)
    |> elem(0)
  end

  # 78 days ending today, oldest first, so the field reads left to right and top
  # to bottom the way the drawing does.
  defp field_cells(entries) do
    today = Kati.Time.today()
    counted = entries |> Enum.map(& &1.on) |> Enum.frequencies()

    for offset <- (@field_days - 1)..0//-1 do
      counted |> Map.get(Date.add(today, -offset), 0) |> level()
    end
  end

  # Four steps, because `Kati.Screens.Lock.Sample.intensity/1` paints four —
  # *four steps, not a ramp, which is what keeps a pixel field readable at 7pt*.
  # Three or more in a day is the heaviest cell there is; a busier day is not a
  # different colour. Screen 07's grid has five and is a different object at a
  # different scale.
  defp level(0), do: 0
  defp level(1), do: 1
  defp level(2), do: 2
  defp level(_many), do: 3
end
