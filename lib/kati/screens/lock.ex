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
  `Kati.ScreenDesignLiteralTest`'s allow-list — a list whose bound is **30, and
  which holds all 30**, with the note at every move of it that raising the bound
  is *a decision to check less*. `Kati.Screens.HomeDark` carries the same
  arithmetic for the same two lines and is where that count is kept straight;
  this paragraph used to say four, which was the bound several moves ago.

  Pinned is not the same as frozen in one language, and this is where the two
  part company. `@drawn_evening` and `@drawn_time` hold the evening as a `Date`
  and a `Time` rather than as the two sentences the board types, and
  `drawn_clock/0` renders them through `Kati.Locale.date/2` at `:full` and
  `Kati.Locale.time/1` — so the same pinned instant draws `Sunday 16 August`
  over `21:40` in English and یکشنبه ۲۵ مرداد over ۲۱:۴۰ in Persian. That
  second one is a different **calendar** and not a translation of the first,
  which is precisely the half of mishka-group/kati#103 a catalogue cannot do:
  `Kati.Calendar.Shamsi` is the arithmetic and `Kati.Gettext` has no shape for
  one.

  **The wallpaper** is pinned because Kati does not have one. It stores no
  photograph and cannot read the one the OS is showing, so the picture behind
  the glass is the design's and nothing in any resource could replace it.

  ## Where the words come from, now that there is no Persian mirror

  mishka-group/kati#103 folded the 33 `*Fa` screens away, so this module is the
  Persian lock screen as well as the English one and every string it draws has
  to come off `Kati.Gettext`.

  `Kati.Screens.Lock.Sample` still holds the board's copy as the English
  literals the board types, and it is **not** where the translation happens.
  The drawn copy is re-stated against the catalogue here instead, in
  `drawn_up_next/0`, `drawn_tonight/0`, `drawn_today/0` and `drawn_year/0`,
  for two reasons worth keeping apart:

    * the Sample is the *drawing's* specification — the value a test compares a
      render against — and a fixture that answered a different sentence
      depending on which locale the test process was in would stop being one, and
    * `Kati.Screens.MarkIos` and `Kati.Screens.MarkAndroid` both quote
      `drawn_widgets/0`'s Today row to draw a Kati notification, so a
      translation on this side reaches them and needs nothing of theirs.

  Every msgid in those four functions is byte-identical to the literal it
  replaces, so the English render is the board unchanged and the Persian one is
  the same nodes with the catalogue's answers in them.

  The eyebrows keep their capitals **in the msgid** rather than going through
  `Kati.UI.eyebrow_label/1`. `Sample.up_next/0` records why — there is no
  `text-transform` on those lines, so `UP NEXT` is the copy rather than a
  styling of *Up next* — and the helper's own doc records the other half:
  `String.upcase/1` is a Latin operation, and Persian has no case for it to
  reach. A capital is content on this screen, and content is translated.
  """
  use Mob.Screen
  use Gettext, backend: Kati.Gettext
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

  # The evening screen 29 is drawn at, held as the two values it IS rather than
  # as the two sentences the board types. `Kati.Screens.Lock.Sample.clock/0`
  # keeps `Sunday 16 August` and `21:40`, and an English sentence is the one
  # thing a Persian reader cannot be handed: ۲۵ مرداد ۱۴۰۵ is the same evening
  # counted in another calendar, which is an arithmetic and not a wording. A
  # `Date` and a `Time` are what `Kati.Locale.date/2` and `Kati.Locale.time/1`
  # take, so the clock stays pinned to the drawing's instant — the moduledoc
  # says why it is pinned — and only the rendering of it moves.
  @drawn_evening ~D[2026-08-16]
  @drawn_time ~T[21:40:00]

  # The figures the board's own widgets state, beside the copy that names them.
  # Named rather than written into the sentences because each is an ARGUMENT to
  # a msgid now and no longer part of one — `TODAY · 4 LEFT` is
  # `TODAY · %{n} LEFT` with a 4 in it — and a numeral carried inside a sentence
  # is a numeral `Kati.Locale.number/1` never gets to see.
  #
  # `@drawn_airing` is deliberately one number and not two. Six is what the
  # Tonight widget counts and what the Today widget's 20:00 row names, and the
  # Sample's moduledoc is where that is a rule rather than a coincidence: *three
  # widget sizes off one data model*. Two constants would be two facts that
  # happen to agree today.
  #
  # `S2E6` and `18M` are not here. They are a position inside one title rather
  # than a figure a widget states, they are read together as one bookmark, and
  # `drawn_up_next/0` is the only thing that could ever want them.
  @drawn_airing 6
  @drawn_left 4
  @drawn_hours 312
  @drawn_nights 11

  def mount(_params, _session, socket) do
    Mob.Theme.set(Kati.Theme.dark())
    # Resolves the stored locale into THIS process. `Gettext.put_locale/2`
    # snapshots into the calling process exactly as `Mob.Theme.set/1` does,
    # and a screen is its own process — see `Kati.Locale.activate/0`.
    Kati.Locale.activate()
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
      clock: clock(),
      up_next: up_next() || empty_up_next(),
      tonight: tonight() || empty_tonight(),
      today: today() || empty_today(),
      year: year() || empty_year()
    }
  end

  @doc """
  The four widgets with nothing behind any of them.

  Each is its own frame with its own name and empty slots — a widget that says
  what it is and that it has nothing yet, which is what this screen is FOR. The
  four used to answer `drawn_up_next/0`, `drawn_tonight/0`, `drawn_today/0` and
  `drawn_year/0` instead, so a fresh install's lock screen promised *The Long
  Hollow S2E6*, six episodes airing, four things left today and a 312-hour year
  with an eleven-night streak. Every figure on it was the board's.

  The clock is not among them: `clock/0` reads the device and there is no state
  in which it has nothing to say.
  """
  @spec empty_widgets() :: map()
  def empty_widgets do
    %{
      clock: clock(),
      up_next: empty_up_next(),
      tonight: empty_tonight(),
      today: empty_today(),
      year: empty_year()
    }
  end

  defp empty_up_next do
    %{
      eyebrow: pgettext("a lock-screen widget's own name", "UP NEXT"),
      title: pgettext("the Up next lock-screen widget with nothing on the shelf", "Nothing yet"),
      meta: "",
      seed: nil
    }
  end

  defp empty_tonight, do: tonight_widget(0)

  defp empty_today, do: %{eyebrow: today_eyebrow(0), rows: []}

  defp empty_year do
    %{
      eyebrow: pgettext("a lock-screen widget's own name", "THIS YEAR"),
      watched: watched_label(0),
      streak: streak_label(0),
      rows: []
    }
  end

  @doc """
  Screen 29 exactly as it is drawn, from `Kati.Screens.Lock.Sample`.

  Kept as the fixture rather than inlined here, for the reason
  `Kati.Screens.Film.drawn_film/0` gives: it is the frame's specification and
  the value a test compares a real render against, and two copies of the
  drawing's copy is exactly how the two drift apart.

  Its shape, its seed and its 78 cells are still the Sample's; its words and
  its figures pass through `Kati.Gettext` and `Kati.Locale` on the way out, so
  this is the drawing in the reader's own language rather than in the language
  it happened to be drawn in. The moduledoc's *Where the words come from*
  carries why that happens on this side of the boundary and not in the fixture.
  """
  @spec drawn_widgets() :: map()
  def drawn_widgets do
    %{
      clock: drawn_clock(),
      up_next: drawn_up_next(),
      tonight: drawn_tonight(),
      today: drawn_today(),
      year: drawn_year()
    }
  end

  # ── The drawing's own copy, in the reader's own language ────────────────────
  #
  # Four functions and a clock, each the Sample's map with its copy re-stated
  # against the catalogue. Every msgid here is byte-identical to the literal it
  # replaces — `UP NEXT` is `UP NEXT`, `TODAY · 4 LEFT` is `TODAY · %{n} LEFT`
  # with the board's own 4 — so nothing about the English render changes.

  defp drawn_clock do
    %{date: Kati.Locale.date(@drawn_evening, :full), time: Kati.Locale.time(@drawn_time)}
  end

  # The device's own evening. `@drawn_evening` and `@drawn_time` are board 29's
  # — Sunday 16 August, 21:40 — and they were what the live screen drew too, so
  # the one widget on this page that every phone already renders correctly by
  # itself was the one showing a date eleven months out of date.
  defp clock do
    now = Kati.Time.now()

    %{
      date: Kati.Locale.date(DateTime.to_date(now), :full),
      time: Kati.Locale.time(DateTime.to_time(now))
    }
  end

  # `seed` is the Sample's and stays a seed: `hollow71` is a file name
  # `Kati.Design.Images.poster/1` looks the picture up by, and a translated file
  # name finds no file. The title above it is a different thing entirely — an
  # invented series the app already names in both scripts, `The Long Hollow` and
  # گودال بلند, and `Kati.Library.Sample` and `Kati.Screens.Home` both put that
  # exact msgid on the same show.
  defp drawn_up_next do
    %{
      Sample.up_next()
      | eyebrow: pgettext("a lock-screen widget's own name", "UP NEXT"),
        title: gettext("The Long Hollow"),
        # Built from the same two halves `up_next_widget/2` builds a real row's
        # meta from, rather than kept whole as `S2E6 · 18M`. One pair of msgids
        # then serves the drawn widget and the user's own, which is the same
        # argument the Sample's moduledoc makes about one data model: a drawn
        # bookmark spelt differently from a real one is two objects.
        meta: meta_line(episode_text(2, 6), minutes_text(18))
    }
  end

  # `count` and `label` are one fact said twice — the figure at 28pt and the
  # noun under it — so they are built together from the number, and `ngettext/3`
  # is what stops an evening with one episode on it from reading `1 · episodes
  # airing`. The Sample stores the plural because the board's own count is six.
  defp drawn_tonight, do: tonight_widget(@drawn_airing)

  defp tonight_widget(count) do
    %{
      Sample.tonight()
      | eyebrow: pgettext("a lock-screen widget's own name", "TONIGHT"),
        count: Kati.Locale.number(count),
        label: ngettext("episode airing", "episodes airing", count)
    }
  end

  # The board's two events, at the same two times `Kati.Screens.HomeDark` draws
  # them at. The times go through `Kati.Locale.time/1` and not through a literal
  # for the reason the real rows do: `Kati.Calendars.Today.row/2` formats its own
  # with that call, so a drawn row keeping `20:00` in Latin beside a real row
  # reading ۲۱:۳۰ would be one widget with two clocks in it.
  defp drawn_today do
    %{
      Sample.today()
      | eyebrow: today_eyebrow(@drawn_left),
        rows: [
          %{
            time: Kati.Locale.time(~T[20:00:00]),
            # Plural in the msgid rather than `ngettext/3`, and that is not the
            # call `tonight_widget/1` makes two functions up: this row is the
            # BOARD's, its count is the drawing's own six and nothing varies it.
            # A plural form nothing could ever select is a form to translate for
            # nothing.
            title: gettext("%{n} episodes air", n: Kati.Locale.number(@drawn_airing)),
            now?: true
          },
          %{time: Kati.Locale.time(~T[21:30:00]), title: gettext("Call Mum"), now?: false}
        ]
    }
  end

  # `rows` — the 78 cells, chunked 33 — is the Sample's and has no words in it.
  defp drawn_year do
    %{
      Sample.year()
      | eyebrow: pgettext("a lock-screen widget's own name", "THIS YEAR"),
        watched: watched_label(@drawn_hours),
        streak: streak_label(@drawn_nights)
    }
  end

  # `TODAY · 4 LEFT` with the count as a binding, because the count is the one
  # part of it that is the reader's. One msgid serves the drawn eyebrow and the
  # counted one; `Kati.Locale.number/1` is what makes the 4 a ۴.
  defp today_eyebrow(left) do
    pgettext("a lock-screen widget's own name", "TODAY · %{n} LEFT", n: Kati.Locale.number(left))
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
      font_family={Kati.Locale.face_prop()}
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

  def handle_info({:tap, :dismiss}, socket), do: {:noreply, Kati.Screens.Resume.pop(socket)}
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
  #
  # Both lines ask the string which script it is in rather than being told.
  # The date is a SENTENCE — `Sunday 16 August`, or یکشنبه ۲۵ مرداد — so
  # `Kati.Locale.mono_face/1` hands the Persian one to Vazirmatn, which has the
  # glyphs `kati_mono.ttf` does not, and drops the `.06em` the drawing sets it
  # in: positive tracking on Arabic script pulls apart joins that are the
  # letterforms rather than a gap between them. The time under it is digits, and
  # `-.04em` on a Latin display face is a decision about Plus Jakarta's numerals
  # and nobody else's; `Kati.Locale.tracking/1` is how both say so at the point
  # they differ.
  @doc false
  def clock(now) do
    ~MOB"""
    <Column fill_width={true} padding_top={14}>
      <Row fill_width={true} align="center">
        <Spacer weight={1.0} />
        <Text
          text={now.date}
          font_family={Kati.Locale.mono_face(now.date)}
          text_size={14}
          letter_spacing={Kati.Locale.tracking(0.06)}
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
          letter_spacing={Kati.Locale.tracking(-0.04)}
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
                  font_family={Kati.Locale.mono_face(up_next.meta)}
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
              letter_spacing={Kati.Locale.tracking(-0.03)}
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
  #
  # Two of the three parts of that idiom are Latin typography and say so at the
  # call site. `.14em` is a small-caps effect the Arabic script has no tradition
  # of and Vazirmatn is not drawn for — `Kati.UI.eyebrow_label/1` carries the
  # long version — and DM Mono has no Persian glyph at all, so امشب set in it
  # would be handed to Android's own substitute face and render, correctly
  # shaped, in a typeface that is not Kati's. The half-alpha is the part that
  # survives both scripts, and it is the part that carries the idiom.
  @doc false
  def eyebrow(label) do
    ~MOB"""
    <Text
      text={label}
      font_family={Kati.Locale.mono_face(label)}
      text_size={9}
      letter_spacing={Kati.Locale.tracking(0.14)}
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

  # `Kati.Locale.mono_face/1` on the clock column and NOT the flat `"mono"`
  # `Kati.Screens.Agenda.row/2` keeps. That screen states the opposite rule and
  # is right about its own column — it formats its times itself and leaves them
  # in Latin digits, so DM Mono has every glyph they need. This column does not
  # get that choice: its rows come from `Kati.Calendars.Today.row/2`, which
  # formats `time` through `Kati.Locale.time/1`, so under `:fa` the string
  # arriving here is ۲۰:۰۰ and `kati_mono.ttf` carries none of U+06F0–U+06F9.
  # Asking the string which script it is in is what lets one helper answer both
  # screens correctly.
  @doc false
  def today_row(row) do
    rail = if row.now?, do: 0xFFE8823C, else: 0x66FFFFFF

    ~MOB"""
    <Row fill_width={true} align="center">
      <Column width={36}>
        <Text
          text={row.time}
          font_family={Kati.Locale.mono_face(row.time)}
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
          font_family={Kati.Locale.mono_face(field.watched)}
          text_size={9.5}
          text_color={0x80FFFFFF}
          max_lines={1}
        />
        <Spacer weight={1.0} />
        <Text
          text={field.streak}
          font_family={Kati.Locale.mono_face(field.streak)}
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
  # time here. `drawn_up_next/0` rather than `Sample.up_next/0` for exactly that
  # reason: the drawn widget is where that name is now translated, and reading
  # the fixture instead would put an English eyebrow over a Persian title.
  # The three values under it are the user's.
  defp up_next_widget(tracked, cached) do
    %{
      drawn_up_next()
      | title: title_of(cached),
        meta: meta_line(episode_label(tracked), left_label(tracked, cached)),
        seed: seed_of(tracked, cached)
    }
  end

  # ` · ` between the halves that exist, nothing where one does not. The
  # separator is a neutral character between two runs of the reader's own
  # script in both directions, so it needs no isolate — there is no Latin run
  # inside this line to have its punctuation pulled to the wrong edge.
  defp meta_line(episode, left) do
    Enum.join(Enum.reject([episode, left], &is_nil/1), " · ")
  end

  # The answer `Kati.Screens.Film` and `Kati.Screens.UpNext` both give: the
  # memory survived the eviction and the poster did not, so the widget says so
  # rather than naming somebody else's show. The app already has one word for
  # it — `Kati.Screens.UpNext.title_of/1` draws the same msgid — so this is
  # `gettext/1` on the same string rather than a second word for one state.
  defp title_of(%CachedTitle{title: title}) when is_binary(title) and title != "", do: title
  defp title_of(_cached), do: gettext("Untitled")

  # The cache row's poster path, or `nil` once the cache row is gone — the
  # renderer draws its placeholder for a `nil`.
  defp seed_of(_tracked, %CachedTitle{poster_path: path}) when is_binary(path) and path != "",
    do: path

  defp seed_of(_tracked, _cached), do: nil

  defp episode_label(%TrackedTitle{progress_season: season, progress_episode: episode})
       when is_integer(season) and is_integer(episode),
       do: episode_text(season, episode)

  defp episode_label(%TrackedTitle{progress_episode: episode}) when is_integer(episode),
    do: episode_text(episode)

  defp episode_label(_tracked), do: nil

  # `S2E6`, run together the way this widget writes it — `Kati.Screens.UpNext`
  # spaces the same two numbers as `S2 · E6`, because it has a whole row to put
  # them on and this has 30pt beside a poster.
  #
  # `pgettext/2` on both, and not because the two readings differ: `S%{s}E%{e}`
  # is eight characters, far under the length `mix gettext.merge` stops
  # fuzzy-matching at, and the app already holds three other spellings of this
  # same bookmark for it to match against. Persian writes ف۲ق۶ — the initials of
  # فصل and قسمت — which is what `Kati.Screens.Activity`'s own row writes, so the
  # word is the app's rather than this screen's.
  defp episode_text(season, episode) do
    pgettext("the episode bookmark on the lock screen's Up next widget", "S%{s}E%{e}",
      s: Kati.Locale.number(season),
      e: Kati.Locale.number(episode)
    )
  end

  defp episode_text(episode) do
    pgettext("the episode bookmark on the lock screen's Up next widget", "E%{e}",
      e: Kati.Locale.number(episode)
    )
  end

  # `18M` is what is LEFT, which needs both halves: the resume point on the
  # durable row and the runtime on the cached one. With no resume point the
  # widget says how long the thing is instead of inventing a position, and with
  # neither it says nothing at all rather than `0M`.
  defp left_label(tracked, cached) do
    case {tracked.progress_seconds, runtime_seconds(cached)} do
      {done, total} when is_integer(done) and is_integer(total) and total > done and done > 0 ->
        minutes_text(div(total - done, 60))

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
      {0, m} -> minutes_text(m)
      {h, 0} -> hours_text(h)
      {h, m} -> hours_minutes_text(h, m)
    end
  end

  # The capital is the drawing's, and it is content rather than a transform:
  # screen 29 types `18M` in DM Mono beside a poster and there is no
  # `text-transform` on the line. So the unit is in the msgid — three of them,
  # one context, because `%{n}M` and `%{n}H` are each four characters and
  # `mix gettext.merge` would fuzzy-match either against any of the half-dozen
  # lower-case durations the app already holds.
  #
  # Persian has no case to raise and writes a unit as a word — ۱۸ دقیقه — which
  # is the same answer `Kati.Screens.UpNext` and `Kati.Books.Sample` give for
  # their own `%{n}m` and `%{h}h %{m}m`. The Latin side keeps the board's
  # capitals; the Persian side keeps the app's vocabulary.
  defp minutes_text(minutes) do
    pgettext("a duration on the lock screen's Up next widget", "%{n}M",
      n: Kati.Locale.number(minutes)
    )
  end

  defp hours_text(hours) do
    pgettext("a duration on the lock screen's Up next widget", "%{n}H",
      n: Kati.Locale.number(hours)
    )
  end

  defp hours_minutes_text(hours, minutes) do
    pgettext("a duration on the lock screen's Up next widget", "%{h}H %{m}M",
      h: Kati.Locale.number(hours),
      m: Kati.Locale.number(minutes)
    )
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
      # `tonight_widget/1` and not `%{Sample.tonight() | count: ...}`: the noun
      # under the figure has to be counted by the same number the figure is, or
      # a single episode reads `۱` over `قسمت‌ها`. It used to be kept from the
      # drawn widget, which meant every evening in the app said *episodes*
      # including the ones with one episode on them.
      [] -> nil
      tracked -> tonight_widget(airing_today(tracked))
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
    # Zero-padded `HH:MM` sorts chronologically inside one day, and both sides
    # are formatted by the same call against the same zone — so this is one
    # clock compared with itself rather than a time parsed back out of a label.
    #
    # `Kati.Locale.time/1` is what makes that claim true again, and it was not
    # true between the fold and this line. `Kati.Calendars.Today.row/2` formats
    # its own `time` through that helper, so under `:fa` a row arrives as ۲۰:۰۰
    # — U+06F0–U+06F9, every one of which sorts ABOVE every ASCII digit — while
    # `Calendar.strftime/2` wrote this side's `21:40` in Latin. Every row on the
    # day then compared greater, so the eyebrow counted the whole day as still
    # ahead and the two rows under it were the day's FIRST two rather than its
    # next two. Persian digits are contiguous and ascending, and both strings
    # are `HH:MM` with the colon at the same offset, so one call on both sides
    # orders them exactly as the Latin pair did.
    now = Kati.Locale.time(Kati.Time.now())
    left = Enum.filter(rows, &(&1.time >= now))

    %{
      eyebrow: today_eyebrow(length(left)),
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

  # KNOWN, and deliberately not fixed here. `today().year` is the GREGORIAN
  # year, and the widget over it says امسال under `:fa` — the Shamsi year, which
  # opens at Nowruz and straddles two Gregorian ones. `Kati.Screens.Music`'s
  # `subtitle/2` carries the full argument and `Kati.Locale.year_start/1` is the
  # tool for it: between Nowruz and 1 January this figure omits the reader's own
  # year, and between 1 January and Nowruz it counts last year's.
  #
  # The reason it stays is the one this whole widget exists under.
  # `Kati.Screens.Stats.year/1` still folds on `on.year == today.year` for the
  # same three facts — only its header asks `year_start/1` — and screens 07 and
  # 29 must report the same hours or neither is worth reporting. Moving one side
  # alone would make a lock screen saying ۳۱۲ ساعت over an app saying ۲۸۹, which
  # is the failure the moduledoc names. Both move together, or a shared fold
  # moves for both.
  defp this_year(entries) do
    year = Kati.Time.today().year
    Enum.filter(entries, &(&1.on.year == year))
  end

  # `eyebrow`, `watched` and `streak` are the drawn widget's, overwritten with
  # the user's own numbers; the words around them — `watched`, `-night streak` —
  # are the widget's copy and are written here beside the arithmetic that fills
  # them. `drawn_year/0` and not `Sample.year/0` for the reason
  # `up_next_widget/2` gives: the eyebrow that comes through untouched is the
  # translated one.
  defp year_field(entries) do
    hours = div(Enum.sum(Enum.map(entries, &(&1.minutes || 0))), 60)

    %{
      drawn_year()
      | watched: watched_label(hours),
        streak: streak_label(longest_run(entries)),
        rows: entries |> field_cells() |> Enum.chunk_every(@field_row)
    }
  end

  defp watched_label(hours), do: gettext("%{n}h watched", n: Kati.Locale.number(hours))

  # One clause, where there were two. `streak_label(1)` wrote `1-night streak`
  # out in full and the general clause interpolates the identical string for the
  # identical argument, so the special case was never a different sentence — and
  # once the sentence is a msgid, two clauses are two call sites extracting one
  # entry, which is a second chance to let them drift.
  #
  # No `ngettext/3` either, and that is the same observation from the other
  # side: English attributes the noun here — *11-night streak*, never *11-nights
  # streak* — so the two plural forms would be one string. Persian says پیاپی
  # after the count for the same reason `Kati.Screens.Calendar` writes
  # `%{n} روز پیاپی` on a habit's.
  defp streak_label(nights), do: gettext("%{n}-night streak", n: Kati.Locale.number(nights))

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
