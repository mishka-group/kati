defmodule Kati.Screens.MarkAndroid do
  @moduledoc """
  Screen 64 — the Kati mark on an Android home screen, pushed under Settings.

  Built to `.scratch/design/pending/64.html`: a wallpaper bezel to bezel, the
  4x2 widget across the top, eight app icons in two rows of four, and the
  launcher's glass search bar pinned to the bottom. Screen 63 is the same
  picture with iOS's squircle mask and iOS's dock; this is Android's circle and
  Android's search pill.

  ## What the drawing is claiming

  *Wallpaper runs edge to edge under a transparent status bar, as it does on a
  real device.* So nothing here draws a frame at the top level: the wallpaper
  and its scrim are siblings of the content inside one root `Box`, which is the
  arrangement `Kati.Screens.Lock` arrived at for the same reason and for the
  same bound — directly inside that Box the height constraint is the viewport,
  so `fill_height` reaches the bottom bezel instead of collapsing to
  wrap-content. There is no `Scroll` at all: a home screen is a fixed
  composition, and the slack between the second icon row and the search bar is
  a weighted `Spacer` so that slack lands on whatever device this opens on.

  *Same mark, Android's fully-round mask — which is exactly why the ladder is
  drawn inside a generous margin.* One drawing serves both sizes and both
  masks. `mark/2` is the ladder and its star in the export's own 240-unit box,
  scaled to whatever size is asked for: 16 beside the widget's eyebrow, 38
  inside the icon tile. The ladder spans x 82 to 158 of those 240 units, so a
  third of the tile's width is empty on each side — and that margin is the
  whole reason 63 and 64 can share a mark. A squircle and a circle clip
  different corners; neither of them reaches the rungs.

  *The 4x2 widget carries the two things worth glancing at: what airs and what
  you are eating.* The two rows are deliberately from two domains rather than
  two entries in one list, and the rail colour says which — `Palette.accent/0`
  for a release, `Palette.bronze/0` for a meal, which is the token the palette
  already reserves for *meals, money*. The airing row is not written here: it is
  `Kati.Screens.Lock.drawn_widgets/0`'s own first row, so `20:00 · 6 episodes
  air` exists once in the app and screens 28, 29, 63 and 64 cannot come to
  disagree about the same evening.

  ## The caveat, which is 63's caveat

  **Kati cannot draw an Android home screen, and this screen is not one.** A
  launcher icon is a `res/mipmap` asset the system composites behind its own
  adaptive-icon mask, and a home-screen widget is `RemoteViews` built by an
  `AppWidgetProvider` in a process that never starts the BEAM. Neither surface
  is reachable from a Mob screen, and neither one would be able to call into
  this module if it were.

  So this is a *picture*, pushed under Settings, and it is the same kind of
  object `Kati.Screens.Widgets` is: previews drawn at the real scale, which is
  the only form in which they can be checked against a drawing at all. Screen
  39 states the rule this inherits — *the previews are drawn, not screenshotted*
  — and adds the consequence, which is that nothing on the picture is live.

  ## Nothing here reads a store, and the mixture is the reason

  Four of the strings on this screen could be read today, and none of them is.
  `20:00 · 6 episodes air` is the row `Kati.Calendars.Today.rows/1` already
  answers for `Kati.Screens.HomeDark` and `Kati.Screens.Lock`. `3 new episodes
  waiting` is the release watcher's unread count, which is the one thing 63's
  caption says Kati ever puts on a home screen. But the wallpaper belongs to the
  OS, the date belongs to the same pinned evening screens 28 and 29 are drawn
  at, and *seven of the eight icons belong to other people's applications* —
  Calendar, Photos, Play, Books, Fit, Notes and Settings are furniture, and no
  amount of domain work will ever make them true. Half a picture reading a
  store and half of it invented is precisely the mixture `Kati.Screens.Film`
  refuses: either every value on a surface is this user's or every value is the
  drawing's. On a picture of somebody else's launcher it can only be the
  drawing's.

  The badge and the headline are the one place that rule still binds something.
  Both are the same unread count, so `home/0` formats the headline from the
  badge rather than writing `3` twice — two copies of one number is how a badge
  starts contradicting the sentence beside it.

  ## A picture of a device, drawn in the language of whoever is holding it

  Everything the drawing *writes* is copy and goes through `Kati.Gettext`: the
  headline, the meal, the search pill's placeholder and seven of the eight icon
  names. A Persian reader's launcher names its own apps in Persian — تقویم,
  عکس‌ها, تنظیمات — so leaving `Calendar` and `Settings` in Latin under `:fa`
  would not be *respecting somebody else's product name*, it would be drawing a
  launcher no Persian reader has ever seen. The section above already says these
  seven are furniture rather than brands, and that is exactly why they
  translate: inventing seven brands was refused, so there is no brand here left
  to protect.

  **`Kati` is the one word that does not translate, and it appears twice** —
  the widget's eyebrow and the icon's own name. It is the mark's name, and board
  127's rule covers it: a product name spelled one way in Latin and another in
  Persian is one thing spelled twice. The eyebrow therefore also keeps
  `String.upcase/1` and its bare `font_family`/`letter_spacing`, which is
  `Kati.Screens.LaunchScreen.line_name/0`'s case in full and the opposite of
  what every translated eyebrow in the app does — see `widget_header/1`.

  The date stopped being a string. `Sun 16 Aug` and یکشنبه ۲۵ مرداد ۱۴۰۵ are the
  same evening in two different *calendars* rather than two spellings of one,
  which is the half of mishka-group/kati#103 a catalogue cannot do, so `home/0`
  holds the day itself and `Kati.Locale.date/2` writes it.

  The airing row is the exception, and it is an exception about ownership rather
  than about language: `6 episodes air` is `Kati.Screens.Lock.Sample.today/0`'s
  copy, and it translates on the day screen 29 folds. Its *digits* are converted
  here all the same — see `widget_row/1`.

  ## Nothing on this screen taps, and that is why there is no `handle_tap/2`

  `Kati.Screens.Pushed` defines none on purpose, and adding one here would be
  wrong twice over: the icons are pictures of other apps, and the Kati icon is a
  picture of the way into an app you are already inside. The back pill is the
  only control, and the macro wires that itself.

  ## The mark is a canvas, not an image asset

  The export ships the mark as inline SVG — two tapered rails, five rungs, a
  closed diamond and three spokes, all strokes, no fills. Mob has no SVG node,
  and rasterising it into `priv/` would mean one file per size and per colour
  and a new one the day the mark changes. `Mob.Canvas` draws exactly these
  primitives, so `mark_ops/2` is the SVG's own path data transcribed once and
  scaled.

  The scaling has to happen in Elixir, and that is a property of this bridge
  rather than a preference. `Mob.Canvas`'s own documentation describes a
  renderer that maps declared logical units onto the canvas's actual size;
  `MobBridge.kt`'s `canvasFloat` instead reads every coordinate as **dp** and
  converts dp to pixels, so a `240`-unit op on a 38pt canvas would be drawn
  six times outside it. `mark_ops/2` therefore multiplies every coordinate
  *and every stroke width* by `size / 240` before handing them over, which is
  also what keeps the rails visibly heavier than the rungs at 16pt.

  ## What is reused from screen 29, and what could not be

  `Kati.Screens.Lock.wallpaper/0` and `Kati.Screens.Lock.scrim/0` draw the
  ground, because the two screens are asking the identical question — what does
  Kati look like sitting on the device's own wallpaper — and Kati owns exactly
  one wallpaper and one scrim recipe. The drawing paints a
  `#7E7466`→`#38332D` gradient with an orange radial bloom over it; that is the
  export standing in for a photograph, and 63's caption says what the
  photograph is for: *the icon has to win on a crowded, mid-tone wallpaper*. A
  real picture is a harder test of that claim than a gradient, and a gradient
  written from those three literals could not be built out of
  `Kati.Theme.Palette` in any case.

  `Kati.Screens.Lock.today_row/1` is **not** reused, and the reason is geometry
  rather than taste: it sets a 36pt mono time gutter, then the rail, then the
  title on one line, because a lock widget is one column 328 wide. This widget
  puts two events side by side in 158 each, which forces the rail beside a
  stacked time and title. Calling 29's row here would draw a different object.
  `Kati.Screens.Lock.eyebrow/1` is not reused either — it is pinned to
  `Palette.lock_ink_55/0`, which is white over a wallpaper, and this eyebrow
  sits on the ivory widget in `Palette.eyebrow/0` with the mark where the dash
  goes.

  ## The picture is pinned to the light palette

  Everything inside the frame takes an explicit `:light`, and `Kati.Theme`'s
  resolved mode is left to the back pill alone. A launcher icon does not consult
  a preference stored inside the application it launches — Android composites a
  static asset — so an ivory tile that turned near-black because the user had
  chosen dark inside Kati would be a claim about the OS that is not true. The
  same holds for the widget beside it: this is one photograph of one device, and
  half of it changing with a setting would make the picture disagree with
  itself. The palette already carries this idea for the eight values drawn
  *over* the wallpaper — every `:media`-sourced token holds one value in both
  modes for exactly this reason — and the ivory panel is only pinned by hand
  because the table has no `:media` ivory to name.

  ## Five things the drawing does that the bridge cannot

    * **The radial bloom.** `radial-gradient(110% 60% at 24% 10%, …)` — the
      gradient prop is linear and vertical, the limit `Kati.Screens.States`
      records for its shimmer. `Kati.Screens.Lock.scrim/0` stands in.
    * **The text shadow under the icon labels.** `0 1px 3px rgba(0,0,0,.45)` on
      a `.94` white; no text node carries a shadow. The labels are drawn at
      `Palette.lock_ink/0`, full white, which is what buys back the legibility
      the shadow was there for — and it matters here because 29's scrim
      deliberately leaves the middle 40% of the picture alone, and that band is
      exactly where these eight labels sit.
    * **`backdrop-filter: blur(18px)` on the search bar.** No backdrop blur
      through Mob, the same limit `Kati.Theme.chrome_fill/1` records for the
      dock. It ships as the flat translucent fill the drawing puts under the
      blur.
    * **The badge's `top:-4px; right:-4px`.** Nothing takes a negative offset,
      so the badge sits flush inside the tile's top-right corner rather than
      overhanging it — drawn as a stacked `Box` at `align="top_trailing"`.
    * **`min-width: 20px` on that badge.** A `Row` hugs its content; at a
      two-digit count it grows rather than staying square, which is what a
      count badge should do anyway.
  """

  use Kati.Screens.Pushed, back: "Settings"
  use Gettext, backend: Kati.Gettext

  alias Kati.Screens.Lock
  alias Kati.Theme.Palette

  # The export's own viewBox. Every number in @rails, @rungs, @star and @spokes
  # is read straight off the SVG in `64.html` and means nothing except relative
  # to this box, so the box is named rather than repeated as a literal 240.
  @mark_box 240

  # Two rails, tapering inward as they rise — 82→92 on the left, 158→148 on the
  # right — which is the perspective that makes it read as a ladder leaning away
  # rather than a bracket.
  @rails [{82, 218, 92, 94}, {158, 218, 148, 94}]

  # Five rungs, as {left, right, y}. Each is narrower than the one below it by
  # the amount the rails have converged at that height, so they have to be
  # written out rather than derived from a step: the drawing's numbers are what
  # the mark is.
  @rungs [
    {82.6, 157.4, 208.8},
    {84.8, 155.2, 182.4},
    {87.0, 153.0, 156.0},
    {89.2, 150.8, 129.6},
    {91.4, 148.6, 103.2}
  ]

  # The star above the ladder: a closed diamond and three spokes off it. There
  # is no fourth spoke below, because that is where the ladder is.
  @star [{120, 37}, {135, 52}, {120, 67}, {105, 52}]
  @spokes [{120, 28, 120, 16}, {132, 42, 143, 31}, {108, 42, 97, 31}]

  # Three stroke weights, in the same 240-unit box. The rails are the heaviest
  # so the ladder still reads as a ladder at 16pt, where the whole mark is
  # about five points wide.
  @rail_stroke 12
  @rung_stroke 10
  @star_stroke 8

  # The launcher's own metrics — the 60pt tile, its 30pt radius, the 27pt glyph
  # — stay written into the markup rather than named here, and they have to:
  # inside `~MOB` an `@name` is read as an ASSIGN, so `@tile` in a prop would
  # resolve to `assigns.tile` and fail. Only values this module computes with
  # can be attributes.

  # The release watcher's unread count, which 63's caption calls the only thing
  # Kati ever puts on the home screen. One number, read twice — see `home/0`.
  @unread 3

  # The pinned evening, as a DATE and not as `"Sun 16 Aug"`. Under `:fa` the
  # widget's top line is a Shamsi date — a different calendar rather than a
  # translation of this one — so the day has to survive as a day for
  # `Kati.Locale.date/2` to have anything to convert.
  #
  # A literal here and not `Kati.Screens.Lock.Sample.clock/0`'s, which names the
  # same evening: that one is already formatted, in English, in the `:full`
  # style a lock screen's clock wants, and there is no day left inside it to
  # ask. It is the one piece of this evening that is still written twice, and it
  # stops being written twice when 29 folds and `Sample` starts answering a
  # `Date`.
  #
  # Safe as an attribute where a `gettext/1` would not be: a sigil is data and
  # freezes nothing. Every call that reads the locale is in a function body.
  @drawn_day ~D[2026-08-16]

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :home, home())

  @doc """
  Everything on the home screen, as one map.

  One map rather than a value per part, because a home screen is a single
  photograph of a single device and the parts have to agree: the badge on the
  icon and the sentence in the widget are the same unread count, so the headline
  is formatted from `@unread` here instead of `3` being typed on two lines that
  can drift apart.

  The airing row comes from `Kati.Screens.Lock.drawn_widgets/0` rather than
  being written again, for the reason the moduledoc gives — screens 28, 29, 63
  and 64 are drawn at one evening, and one evening should exist in one place.
  The meal row is this screen's own: 29's second row is `Call Mum`, and 64
  picks a different second row on purpose, because a home widget's claim is
  *what airs and what you are eating* rather than *what is left of today*.

  The map is built in the reader's language, which is why it is built in a
  function and read on `load/1` rather than held as an attribute: `gettext/1`
  in a module attribute is evaluated while the file compiles and freezes into
  whichever locale the compiler happened to be in.

  `ngettext/4` on the headline even though `@unread` is a frozen 3, and
  `Kati.Screens.Home.headline_lines/1` makes the argument this follows: the
  count is the sentence's own number, and one episode waiting is the ordinary
  case rather than an edge one the moment this stops being a drawing. Persian
  does not inflect a noun after a numeral, so both forms are one sentence there
  — the plural exists for the English half.
  """
  @spec home() :: map()
  def home do
    [airing | _rest_of_the_evening] = Lock.drawn_widgets().today.rows

    %{
      widget: %{
        eyebrow: "Kati",
        date: Kati.Locale.date(@drawn_day, :long),
        headline:
          ngettext(
            "%{n} new episode waiting",
            "%{n} new episodes waiting",
            @unread,
            n: Kati.Locale.number(@unread)
          ),
        rows: [
          %{time: airing.time, title: airing.title, kind: :release},
          %{
            time: Kati.Locale.time(~T[19:30:00]),
            title: gettext("Dinner — salmon"),
            kind: :meal
          }
        ]
      },
      apps: [
        [
          # `Kati` in both scripts, and the badge in the reader's digits: the
          # name is the mark's and the count is the reader's.
          %{label: "Kati", icon: :mark, badge: Kati.Locale.number(@unread)},
          %{label: gettext("Calendar"), icon: "calendar_month", badge: nil},
          %{label: gettext("Photos"), icon: "movie", badge: nil},
          # `Play` and `Fit` take a context and the other five do not. Each is
          # one short word that is a verb or an adjective in English before it
          # is an app, and `mix gettext.merge` fuzzy-matches a msgid that short
          # against any sentence that happens to end in it. `Calendar`, `Books`,
          # `Notes` and `Settings` are labels this app already names: the
          # entries exist with one Persian word each, and a bare `gettext/1`
          # joins them rather than opening a second entry for the same word.
          # `Photos` is new and still needs no context — no sentence in the
          # catalogue ends in it.
          %{
            label: pgettext("an app icon on the home screen", "Play"),
            icon: "play_arrow",
            badge: nil
          }
        ],
        [
          %{label: gettext("Books"), icon: "menu_book", badge: nil},
          %{
            label: pgettext("an app icon on the home screen", "Fit"),
            icon: "fitness_center",
            badge: nil
          },
          %{label: gettext("Notes"), icon: "sticky_note_2", badge: nil},
          %{label: gettext("Settings"), icon: "settings", badge: nil}
        ]
      ],
      search: gettext("Search")
    }
  end

  @doc false
  @spec content(map()) :: map()
  def content(assigns) do
    home = assigns.home
    [first_row, second_row] = home.apps

    # The gutter is `Kati.Theme.gutter/0` and not the drawing's 22. One point,
    # and it is the point that matters: the back pill this screen does not draw
    # itself is laid out at 21, and a widget card that started one point inside
    # it would read as a misalignment rather than as a margin.
    #
    # `Kati.Screens.Pushed.content_top/0` replaces the drawing's 56 for the same
    # reason — the pill floats where the drawing puts the widget, and 110 is
    # where it stops. The weighted Spacer below absorbs the difference, so the
    # search bar still lands 58 off the bottom bezel.
    ~MOB"""
    <Box fill_width={true} fill_height={true}>
      {Kati.Screens.Lock.wallpaper()}
      {Kati.Screens.Lock.scrim()}
      <Column
        fill_width={true}
        fill_height={true}
        padding_left={Kati.Theme.gutter()}
        padding_right={Kati.Theme.gutter()}
        padding_top={Kati.Screens.Pushed.content_top()}
        padding_bottom={58}
      >
        {Kati.Screens.MarkAndroid.widget(home.widget)}
        <Spacer size={26} />
        {Kati.Screens.MarkAndroid.app_row(first_row)}
        <Spacer size={24} />
        {Kati.Screens.MarkAndroid.app_row(second_row)}
        <Spacer weight={1.0} />
        {Kati.Screens.MarkAndroid.search_bar(home.search)}
      </Column>
    </Box>
    """
  end

  @doc """
  The 4x2 widget: who it is from, what day it is, the headline, and two events.

  `Palette.dock_fill/1` for the panel, at the light literal. The drawing paints
  it `rgba(251,250,248,.92)` and that token is the same ivory at `.90` — two
  points of alpha apart, and it is the only value in the table that means *a
  floating chrome surface with the wallpaper showing faintly through*, which is
  what a widget is. `Palette.card/1` would be the same ivory made opaque, which
  loses the one thing the alpha is saying.

  The headline's `-0.02` tracking goes through `Kati.Locale.tracking/1`, which
  answers 0 under `:fa`. Negative tracking on a Latin display line is what keeps
  a bold 15pt sentence tight; on Arabic script it pulls the letters of a word
  past the joins that make it one word, so قسمت comes apart into four shapes.
  """
  @spec widget(map()) :: map()
  def widget(w) do
    ~MOB"""
    <Column
      fill_width={true}
      background={Kati.Theme.Palette.dock_fill(:light)}
      corner_radius={26}
      padding={17}
      shadow={Kati.Theme.shadow_card()}
    >
      {Kati.Screens.MarkAndroid.widget_header(w)}
      <Spacer size={13} />
      <Text
        text={w.headline}
        text_size={15}
        font_weight="bold"
        letter_spacing={Kati.Locale.tracking(-0.02)}
        text_color={Kati.Theme.Palette.ink(:light)}
        max_lines={1}
      />
      <Spacer size={13} />
      {Kati.Screens.MarkAndroid.widget_rows(w.rows)}
    </Column>
    """
  end

  @doc """
  The widget's top line: the mark, the app's name, and the date opposite it.

  This is `Kati.UI.eyebrow/2`'s shape with the mark where the 13x2 accent dash
  goes, which is why it is drawn here rather than called from there. The
  substitution is the point: on Kati's own pages an eyebrow's dash is
  punctuation, but on somebody else's home screen the label has to say **whose
  widget this is**, and a mark does that where a coloured rule does not. The
  copy is stored as `Kati` and upcased at render, because the drawing sets it
  with `text-transform: uppercase` rather than typing capitals — the same
  distinction `Kati.Screens.Widgets` records for its own tile captions, landing
  the other way round.

  ## `String.upcase/1` and **not** `Kati.UI.eyebrow_label/1`

  Which is the opposite of what mishka-group/kati#103 asked of every other
  eyebrow in the app, and the same exception `Kati.Screens.LaunchScreen`'s
  `line_name/0` makes for `LADDER`. That helper leaves a Persian label's case
  alone because Persian has none — right for an eyebrow whose words are
  translated, and wrong for one whose word is a name. This eyebrow is the
  mark's name, it is `Kati` in both scripts, and passing it through
  `eyebrow_label/1` would draw `KATI` on the English page and `Kati` on the
  Persian one: one product spelled two ways rather than one label cased two
  ways.

  `font_family="mono"` and the bare `letter_spacing` stay pinned for the same
  reason and not by omission. DM Mono carries no Persian glyph and this word can
  never be Persian, so `Kati.Locale.mono_face/1` has nothing to decide; tracking
  is dropped where it would break the joins between Arabic letters, and `KATI`
  has none to break under either locale.

  The **date** opposite it is the other half of that rule and goes the other
  way. It is Shamsi under `:fa` — یکشنبه ۲۵ مرداد ۱۴۰۵ — so its face is asked of
  the string rather than pinned, or a Persian month name would be handed to DM
  Mono and come back in whatever face Android substitutes, beside a widget set
  in Vazirmatn. `Kati.Locale.mono_face/1` answers `mono` for the English `Sun 16
  Aug`, which is the line the drawing draws.

  `:long` in both, which is the style that carries the year in Shamsi and drops
  it in Latin — `Kati.Locale.date/2` states that asymmetry and it is a property
  of the calendars rather than of this widget: a Persian reader does not know
  ۱۴۰۵ by heart the way a Latin one knows 2026. The header has the room; the
  weighted `Spacer` before the date gives whatever is left to it.
  """
  @spec widget_header(map()) :: map()
  def widget_header(w) do
    label = String.upcase(w.eyebrow)

    ~MOB"""
    <Row fill_width={true} align="center">
      {Kati.Screens.MarkAndroid.mark(16, Kati.Theme.Palette.ink(:light))}
      <Spacer size={9} />
      <Text
        text={label}
        font_family="mono"
        text_size={9.5}
        letter_spacing={0.14}
        text_color={Kati.Theme.Palette.eyebrow(:light)}
        max_lines={1}
      />
      <Spacer weight={1.0} />
      <Text
        text={w.date}
        font_family={Kati.Locale.mono_face(w.date)}
        text_size={10}
        text_color={Kati.Theme.Palette.tertiary(:light)}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc """
  The two events, side by side across the widget.

  A `Row` of two weighted halves rather than anything that wraps, since a Row
  does not wrap and a two-up widget that reflowed to one column on a narrow
  device would stop being the 4x2 object the drawing names. Each half gets
  `weight={1.0}`, so the pair divides whatever width is actually present
  instead of the 402pt frame this was measured on.
  """
  @spec widget_rows([map()]) :: map()
  def widget_rows(rows) do
    [airing, meal] = rows

    ~MOB"""
    <Row fill_width={true} align="center">
      {Kati.Screens.MarkAndroid.widget_row(airing)}
      <Spacer size={9} />
      {Kati.Screens.MarkAndroid.widget_row(meal)}
    </Row>
    """
  end

  @doc """
  One event: a coloured rail, then the time above what it is.

  The rail's colour is the row's **domain** and not its nowness, which is where
  this parts company with `Kati.Screens.Lock.today_row/1`. On the lock screen a
  rail is orange when the row is the next one; here the first rail is orange
  because a release is a release — orange means new or now — and the second is
  `Palette.bronze/0`, the token the table already reserves for *meals, money*.
  Two rails of one colour would say the two halves are the same kind of thing,
  and the caption says they are not.

  ## The time is converted here, and the title is not

  `Kati.Locale.number/1` on `row.time` at the RENDER site rather than where each
  row is built, because the two rows are built in two different modules. The
  meal is this screen's and comes through `Kati.Locale.time/1` already; the
  airing row is `Kati.Screens.Lock.Sample.today/0`'s, which is not folded yet
  and answers `20:00` in Latin digits in either language. Two times four points
  apart in one widget, one of them `۱۹:۳۰` and the other `20:00`, is the kind of
  disagreement the moduledoc says a single photograph of a single device must
  not have — and asking again about a string that is already Persian costs
  nothing, since `number/1` has no Latin digit left to convert.

  The row's **title** is left exactly as it arrives. `6 episodes air` is 29's
  copy and 29's msgid to add; translating it here would give one evening two
  catalogue entries that could then disagree about the same sentence. It reads
  English on the Persian page until screen 29 folds, and that is the honest
  state of it.

  The face follows the converted string rather than the locale, so the English
  `20:00` stays in DM Mono and `۱۹:۳۰` — which DM Mono has no glyph for — does
  not.
  """
  @spec widget_row(map()) :: map()
  def widget_row(row) do
    rail = rail_color(row.kind)
    time = Kati.Locale.number(row.time)

    ~MOB"""
    <Row weight={1.0} align="center">
      <Box width={3} height={26} corner_radius={2} background={rail} />
      <Spacer size={8} />
      <Column weight={1.0}>
        <Text
          text={time}
          font_family={Kati.Locale.mono_face(time)}
          text_size={9.5}
          text_color={Kati.Theme.Palette.muted(:light)}
          max_lines={1}
        />
        <Spacer size={2} />
        <Text
          text={row.title}
          text_size={12}
          font_weight="semibold"
          text_color={Kati.Theme.Palette.ink(:light)}
          max_lines={1}
        />
      </Column>
    </Row>
    """
  end

  defp rail_color(:meal), do: Palette.bronze()
  defp rail_color(_release), do: Palette.accent()

  @doc """
  One row of four app icons, spread from gutter to gutter.

  Hand-rolled rather than `Kati.UI.even_row/2`, and the difference is visible.
  `even_row/2` divides the width into equal cells and centres each cell's
  content, which is CSS's `space-around`: the outer two tiles would sit about
  ten points inside the gutters, off the edge the widget card above them
  establishes. The drawing is `space-between`, so the outer tiles must touch the
  gutters and only the three gaps may flex — which is a fixed cell with a
  weighted `Spacer` between, exactly as written here.
  """
  @spec app_row([map()]) :: map()
  def app_row(apps) do
    [a, b, c, d] = apps

    ~MOB"""
    <Row fill_width={true} align="top">
      {Kati.Screens.MarkAndroid.app(a)}
      <Spacer weight={1.0} />
      {Kati.Screens.MarkAndroid.app(b)}
      <Spacer weight={1.0} />
      {Kati.Screens.MarkAndroid.app(c)}
      <Spacer weight={1.0} />
      {Kati.Screens.MarkAndroid.app(d)}
    </Row>
    """
  end

  @doc """
  One app: its tile, then its name under it.

  The label is centred by a `Box` at `align="center"` and not by the `Column`
  around it, because the bridge's Column takes no horizontal alignment at all —
  `MobBridge.kt` builds it as a bare `Column(modifier = m)` — so an `align` prop
  there is silently ignored and the name would sit hard against the left of the
  tile. A Box does carry `contentAlignment`.

  Full white, where the drawing asks for 94% white over a text shadow. See the
  moduledoc: the shadow cannot be drawn, these eight labels sit in the band 29's
  scrim deliberately leaves alone, and the six points of alpha are what pays for
  that.

  The `Box` stays 60 wide and the label stays at `max_lines={1}` now that seven
  of the eight names are translated, which is the launcher's own behaviour and
  not an oversight: an icon's name is clipped to its tile on a real home screen
  rather than allowed to grow into its neighbour, and the grid here is
  `space-between` with no slack to give. The Persian names were chosen to fit
  that 60 — تقویم, عکس‌ها, کتاب‌ها, تنظیمات — and `Kati` is four Latin letters in
  either language.
  """
  @spec app(map()) :: map()
  def app(app) do
    ~MOB"""
    <Column width={60}>
      {Kati.Screens.MarkAndroid.tile(app)}
      <Spacer size={7} />
      <Box width={60} align="center">
        <Text
          text={app.label}
          text_size={10.5}
          font_weight="medium"
          text_color={Kati.Theme.Palette.lock_ink()}
          max_lines={1}
        />
      </Box>
    </Column>
    """
  end

  @doc """
  The 60pt round tile — Kati's, with its badge, or another application's.

  Kati's is ivory with the mark inked on it, which is 63's caption in full:
  *ivory tile, ink mark, no gradient*. It has to win against a busy mid-tone
  wallpaper, and a tile that gradiated would be competing with the photograph on
  the photograph's own terms. Everyone else's is the 15% white patch the drawing
  gives them, because they are furniture: the picture needs seven neighbours for
  Kati's to be sitting among something, and inventing seven brands to fill them
  would be worse than saying nothing.

  The badge is stacked over the tile in a second `Box` at `align="top_trailing"`
  rather than offset out of the corner, since nothing in the bridge takes a
  negative inset.
  """
  @spec tile(map()) :: map()
  def tile(%{icon: :mark} = app) do
    ~MOB"""
    <Box width={60} height={60}>
      <Box
        width={60}
        height={60}
        corner_radius={30}
        background={Kati.Theme.Palette.card(:light)}
        shadow={Kati.Theme.shadow_button()}
        align="center"
      >
        {Kati.Screens.MarkAndroid.mark(38, Kati.Theme.Palette.ink(:light))}
      </Box>
      <Box width={60} height={60} align="top_trailing">
        {Kati.Screens.MarkAndroid.badge(app.badge)}
      </Box>
    </Box>
    """
  end

  def tile(app) do
    ~MOB"""
    <Box
      width={60}
      height={60}
      corner_radius={30}
      background={Kati.Theme.Palette.lock_ink_15()}
      shadow={Kati.Theme.shadow_button()}
      align="center"
    >
      {Kati.UI.symbol(app.icon, size: 27, color: Kati.Theme.Palette.lock_ink_85())}
    </Box>
    """
  end

  @doc """
  The unread count, ringed so it separates from whatever it overlaps.

  The ring is `Palette.on_media/0` — ivory, and the token means *burnt over
  artwork*, which is what the ring is doing: the badge sits on the tile's edge
  where the ivory ends and the wallpaper begins, and without it the orange would
  merge into a warm photograph. The count itself is `Palette.on_ink/1` at the
  light literal, which is the ivory the table reserves for a label on a filled
  control; orange is a fill like any other here.

  The count arrives already in the reader's digits — `home/0` puts it and the
  headline through `Kati.Locale.number/1` together, since a badge reading `3`
  beside a sentence reading ۳ is the contradiction this screen went to the
  trouble of formatting one from the other to avoid. The face is then asked of
  the string: `kati_mono.ttf` carries none of U+06F0–U+06F9, so ۳ requested in
  DM Mono comes back in Android's own substitute face. Same pair in the same
  order as `Kati.Screens.Day.chip_count/2`.
  """
  @spec badge(String.t()) :: map()
  def badge(count) do
    ~MOB"""
    <Row
      height={20}
      corner_radius={10}
      background={Kati.Theme.Palette.accent()}
      border_width={2}
      border_color={Kati.Theme.Palette.on_media()}
      padding_left={5}
      padding_right={5}
      align="center"
    >
      <Text
        text={count}
        font_family={Kati.Locale.mono_face(count)}
        text_size={10}
        font_weight="medium"
        text_color={Kati.Theme.Palette.on_ink(:light)}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc """
  Android's search pill along the bottom.

  `Palette.on_media_track/0` is the fill: 25% ivory, against the drawing's 22%
  white, and it is the only token in the table that means a translucent light
  patch laid over a photograph. The nearer white by number is
  `Palette.lock_ink_15/0`, but that is the value the eight app tiles above are
  already drawn in, and the drawing separates the two on purpose — the search
  bar is meant to read as the brighter, nearer surface.

  Drawn, not wired. It is the launcher's search field, not Kati's; `Kati.Screens.Search`
  is the one this app owns.
  """
  @spec search_bar(String.t()) :: map()
  def search_bar(label) do
    ~MOB"""
    <Row
      fill_width={true}
      height={52}
      corner_radius={26}
      background={Kati.Theme.Palette.on_media_track()}
      padding_left={18}
      padding_right={18}
      align="center"
    >
      {Kati.UI.symbol("search", size: 20, color: Kati.Theme.Palette.lock_ink_85())}
      <Spacer size={11} />
      <Text
        text={label}
        text_size={13.5}
        text_color={Kati.Theme.Palette.on_media_meta()}
        weight={1.0}
        max_lines={1}
      />
      <Spacer size={11} />
      {Kati.UI.symbol("mic", size: 19, color: Kati.Theme.Palette.lock_ink_85())}
    </Row>
    """
  end

  @doc """
  The Kati mark at `size`, stroked in `color`.

  A `Mob.Canvas` surface rather than an image, so that one definition serves
  every size the app draws the mark at and changes in one place. The canvas is
  square at `size` and the ops inside it are already scaled, which is what
  `mark_ops/2` is for.

  Nothing about this is Android-specific; when screen 63 lands it should call
  this and pass 38 as well. The mask is the tile's `corner_radius`, and that is
  the only value the two screens differ on.
  """
  @spec mark(number(), pos_integer()) :: map()
  def mark(size, color) do
    Mob.UI.canvas(width: size, height: size, draw: mark_ops(size, color))
  end

  @doc """
  The mark's draw ops, scaled out of the export's 240-unit box onto `size`.

  Coordinates reach `MobBridge.kt` as **dp**, not as units of a declared
  viewport — `canvasFloat` calls `dp.toPx()` on each one — so the 240-unit
  numbers have to be multiplied down here or the ladder is drawn six times
  larger than the tile that holds it. Stroke widths take the same factor,
  because a rail that stayed 12dp at a 38pt size would be a third of the mark.

  Order matters: rails, rungs, then the star, which is the order the SVG stacks
  them in. The rungs cross the rails, so a rung drawn first would show the
  rail's butt cap through it at the joins.

      iex> ops = Kati.Screens.MarkAndroid.mark_ops(240, 0xFF1A1917)
      iex> length(ops)
      11
  """
  @spec mark_ops(number(), pos_integer()) :: [map()]
  def mark_ops(size, color) do
    scale = size / @mark_box

    rails =
      Enum.map(@rails, fn {x1, y1, x2, y2} ->
        Mob.Canvas.line(x1 * scale, y1 * scale, x2 * scale, y2 * scale,
          color: color,
          width: @rail_stroke * scale
        )
      end)

    rungs =
      Enum.map(@rungs, fn {left, right, y} ->
        Mob.Canvas.line(left * scale, y * scale, right * scale, y * scale,
          color: color,
          width: @rung_stroke * scale
        )
      end)

    # `closed: true` and no `fill`, because the drawing's diamond is an outline.
    # The default miter join is what the SVG's `stroke-miterlimit="8"` asks for,
    # and it is what keeps the four corners sharp instead of rounding the star
    # into a blob at 16pt.
    star =
      Mob.Canvas.path(Enum.map(@star, fn {x, y} -> {x * scale, y * scale} end),
        color: color,
        width: @star_stroke * scale,
        closed: true
      )

    spokes =
      Enum.map(@spokes, fn {x1, y1, x2, y2} ->
        Mob.Canvas.line(x1 * scale, y1 * scale, x2 * scale, y2 * scale,
          color: color,
          width: @star_stroke * scale
        )
      end)

    rails ++ rungs ++ [star] ++ spokes
  end
end
