defmodule Kati.Screens.MarkIos do
  @moduledoc """
  Screen 63 — the Kati mark on an iOS home screen, pushed under Settings.

  Built to `.scratch/design/pending/63.html`: eight app tiles on somebody's
  wallpaper with Kati's first among them, a `Kati · tonight` widget under the
  grid, page dots, and the dock. Screen 29 is the precedent — a drawing of an
  OS surface that happens to have Kati on it, built as a reference screen
  rather than as something the app does — and this is the second of that pair,
  so it stands on 29's ground instead of inventing a second one.

  ## "Ivory tile, ink mark, no gradient"

  `Palette.card(:light)` and `Palette.ink(:light)`, pinned, and they are the
  only two pinned colours on the screen. An app icon is an **asset**: it is
  compiled into a launcher's grid and looks the same whatever the phone is set
  to, so a tile that followed `Kati.Theme.Mode` would turn `#1E1D1B` in dark
  and the mark on it would turn `#F5F2EE` — Kati would have two icons, which is
  not something an icon is allowed to have. `Kati.Screens.PlanShare` pins the
  same two tokens for the same reason and states the rule this borrows: the
  palette's `:media` family is *a colour whose ground is a photograph*, and a
  photograph does not get lighter when the app does. Light mode is untouched
  either way — `Palette.card(:light)` is `0xFFFBFAF8` and `Palette.ink(:light)`
  is `0xFF1A1917`, exactly the two values the drawing writes.

  *No gradient* is the third of those three, and it is a claim about a prop
  rather than a colour. Two nodes on this screen carry `gradient` — the scrim
  and the accent bloom, both of them ground — and the tile carries a flat
  `background` beside seven translucent ones. That is what makes it findable on
  a crowded mid-tone wallpaper: it is the only opaque light object in the grid,
  and it wins by being the one thing that is not showing the picture through.

  ## The badge

  *The release watcher's unread count — the only thing Kati ever puts on the
  home screen.* Both halves of that were checked.

  The count already has a function: `Kati.Notifications.Inbox.badge/1` is
  exactly this number, the length of the `:now` group of a
  `Kati.Notifications.Plan`. What does not exist is the other end of it —
  **nothing in `lib/` or in `android/` writes an app-icon badge**, so there is
  no launcher count for this drawing to be a picture of. It is drawn as the
  design's `3`, and `badge/1` here takes the string rather than reading
  anything, for the reason `Kati.Screens.States` gives about `Last success 6h
  ago`: a true figure attached to a surface the app does not yet write to reads
  as a live report and is not one.

  The second half is why every other tile's badge is `nil` rather than absent:
  the grid is one shape with one badge slot, and *the only thing Kati ever puts
  on the home screen* is a statement about the whole row, not about one tile.

  ## The widget is the lock screen's evening, quoted

  *The same "tonight" data as the lock screen*, so it is taken from screen 29
  rather than typed again. `tonight/0` reads the first row of
  `Kati.Screens.Lock.drawn_widgets/0`'s Today widget — `20:00 · 6 episodes
  air`, the same map, so the two screens cannot name two different evenings —
  and pairs it with the dinner `Kati.Meals.SamplePlan.day/0` holds, `19:30 ·
  Miso salmon, greens, rice`, cut to its first clause because the column is one
  line wide and the drawing cuts it in the same place.

  29 has no meal row to lend: its second Today row is `21:30 · Call Mum`, a
  calendar reminder. So the home-screen widget is media on the left and meals
  on the right — two domains rather than two calendar rows — and each half is
  quoted from the module that owns it. If either fixture stops holding what it
  holds, `tonight/0` raises at mount instead of quietly drawing a different
  evening, which is the failure worth having: the agreement between 29 and 63
  is the whole claim the caption makes.

  Nothing here reads a store. 27's argument applies unchanged — every tile is a
  picture of a launcher, not a report that the app is in one — and the drawn
  neighbours (Calendar, Notes, Camera) are other people's apps, which Kati
  could not read if it wanted to.

  ## What is 29's, and what deliberately is not

    * `Kati.Screens.Lock.wallpaper/0` and `Kati.Screens.Lock.scrim/0` draw the
      ground. They are the same object on both screens — one phone, locked on
      29 and unlocked here — and 29's three-stop scrim does the same job here
      that it does there: it darkens the top so the icon labels read and the
      bottom so the dock does, and leaves the middle 40% of the picture alone.
      The drawing's own ground is a flat `#8E8579 → #6E665C → #4A443C` sweep,
      which is a stand-in for a photograph in an export that cannot embed one;
      taking 29's actual wallpaper answers the caption's *crowded, mid-tone*
      better than a sweep does, and it costs no new colour.
    * `Kati.Screens.Lock.eyebrow/1` is **not** reused, and that is the one place
      the two screens look alike and are not. 29's eyebrow is white at 55% over
      a photograph; this one sits on the widget's own ivory plate and is
      `Palette.eyebrow()`, the app's ordinary mono section label. Same
      typeface, same tracking, different ground — and a lock eyebrow borrowed
      onto paper would be invisible. `Kati.UI.eyebrow/2` is not it either: that
      always draws the 13x2 accent dash, and this line's leading mark is the
      Kati glyph at 15pt. `KATI · TONIGHT` is `String.upcase/1` over the
      drawing's `Kati · tonight`, which is `text-transform` in the CSS and so a
      styling rather than the copy — the distinction `Kati.Screens.Widgets`
      records for its own captions, which are capitals in the copy.
    * 29's `today_row/1`, `small_widgets/2` and the pixel field have no
      counterpart here. The home widget is two columns split by a rule, where
      29's is two rows split by a time gutter; reusing the row builder would
      have drawn a different widget and called it the same one.

  ## The mark is drawn, path for path

  Every stroke in the drawing's SVG is a `Box`, and the answer to whether that
  was possible is *yes, all ten of them*, because of two props that already
  exist for exactly this kind of mark: `offset_x`/`offset_y`, which
  `MobBridge.RenderNode` turns into a `Modifier.offset` that moves what is
  painted without moving what was measured, and `rotate`, which `MobBridge`
  added for *marks the design makes WITHOUT their own Material Symbol, and
  which therefore can never enter the icon subset*. Kati's own mark is the
  clearest case of that sentence there is.

  So `mark/2` is the 240x240 viewBox at a scale, and every number in it is an
  SVG coordinate:

    * the two **rails** are 12-wide bars 124.4 long, centred on the midpoint of
      each drawn segment and rotated ±4.61° — the lean of `M82 218 L92 94`,
      taken as `asin(10/124.4)` rather than dropped, since a ladder whose rails
      were parallel would not narrow;
    * the five **rungs** are 10-tall bars at the drawn widths, 74.8 down to
      57.2, which is where the taper actually lives;
    * the **spark** is a 21.21 square rotated 45° with an 8-wide border and no
      fill, which is what an unfilled 30-diagonal diamond is; and its three
      rays are 8-wide bars, one upright and two rotated ∓45° about their own
      midpoints.

  `stroke-linecap="butt"` is why no part of it has a corner radius. Both sizes
  the drawing uses come off the same builder: 38pt on the tile and 15pt in the
  widget eyebrow, where the strokes fall to three quarters of a point and the
  ladder reads as a texture rather than as five countable rungs — which is what
  it does in the export too.

  The colour is a parameter for the reason the first section gives: the tile's
  mark is `Palette.ink(:light)`, pinned with the asset, and the widget's is
  `Palette.ink()`, which follows the mode with the plate it sits on.

  ## Three things the drawing does that the bridge cannot

    * **A radial gradient.** `radial-gradient(120% 70% at 72% 8%, …)` is the
      warm bloom in the top corner. `MobBridge`'s parser is `to_top` or
      `to_bottom` and nothing else — the limit `Kati.Screens.States` records
      for its skeleton shimmer — so `glow/0` is that bloom flattened to a
      top-anchored vertical band. Its colour survives exactly:
      `rgba(232,130,60,.28)` is `Palette.accent_fill/0` to the byte, and the
      band fades to the same RGB at zero alpha rather than to transparent
      white, which is the rule `Kati.UI.paper_fade/3` sets out — Compose
      interpolates in straight RGBA and any other end colour dirties the middle.
    * **A text shadow.** The icon labels carry `0 1px 3px rgba(0,0,0,.45)`, and
      no `Text` node has a shadow prop; the scrim under them is what keeps them
      legible instead, which is the same trick 29 uses for its clock.
    * **A backdrop blur.** The widget and the dock are both
      `backdrop-filter: blur(…)`. Android has no backdrop blur through Mob —
      the limit `Kati.Theme.chrome_fill/1` records for the dock and 29 records
      for its glass — so both ship as the flat alpha fill the drawing sets
      behind the blur.

  ## The four alphas that had to move, and why they moved that way

  The palette has fourteen white-over-photograph steps and the drawing asks for
  four values that are not among them. Each takes the nearest token, and the
  choice was made on the **ordering** rather than on the individual number,
  because what these alphas encode is which plate sits on top of which:

    * tiles at 16% → `Palette.lock_ink_15/0` (15%);
    * the dock plate at 20% → `Palette.on_media_track/0` (25%), and it goes
      *up* where the tiles went down on purpose. The dock tiles are the same
      16% as the grid tiles and sit **inside** the plate, so a plate rounded
      down to 15% would have been darker than the tiles it contains and the
      dock would have read as four holes;
    * icon glyphs at 85% are `Palette.lock_ink_85/0` exactly; the dock's 90%
      and the badge ring's 90% round to the same token rather than earning a
      fifteenth step for five percent;
    * labels at 94% take `Palette.lock_ink/0` at 100%, which buys back a little
      of what the missing text shadow cost them.

  ## Where the grid starts

  The drawing insets its content by 74, which is iOS's status-bar clearance —
  and Kati's back pill floats at 54 and is 42 tall, so the ivory tile would
  have been half under it. The grid opens at `Kati.Screens.Pushed.content_top/0`
  instead, which is that measurement rather than a guess. The dock is pinned to
  the bottom against a `fill_height` Box, so the 36pt goes into the gap above
  the dock and no drawn spacing changes.

  Nothing scrolls. A home screen pages sideways and the three dots say which
  page you are on, so a vertical `Scroll` would be wrong twice — and it would
  also hand its children an unbounded height, which is the bound the bottom
  block needs to sit against. 29 records the same trap for its wallpaper.
  """
  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.Meals.SamplePlan
  alias Kati.Screens.Lock
  alias Kati.Theme.Palette
  alias Kati.UI

  # The SVG the mark is drawn in is 240x240 and every coordinate in `mark/2` is
  # one of its numbers, so the whole figure scales from this one divisor.
  @view_box 240

  # The drawing's copy, in the case the drawing types it. The capitals are
  # `text-transform` in the CSS rather than the words themselves, so they are
  # applied at the call site by `String.upcase/1`.
  @eyebrow "Kati · tonight"

  @impl true
  def load(socket) do
    Mob.Socket.assign(socket, :home, %{
      grid: grid(),
      dock: dock_apps(),
      tonight: tonight()
    })
  end

  @doc false
  @spec content(map()) :: term()
  def content(assigns) do
    home = assigns.home
    [first_row, second_row] = home.grid
    top = Kati.Screens.Pushed.content_top()

    ~MOB"""
    <Box fill_width={true} fill_height={true}>
      {Kati.Screens.Lock.wallpaper()}
      {Kati.Screens.Lock.scrim()}
      {Kati.Screens.MarkIos.glow()}
      <Column
        fill_width={true}
        fill_height={true}
        padding_left={22}
        padding_right={22}
        padding_top={top}
      >
        {Kati.Screens.MarkIos.app_row(first_row)}
        {Kati.Screens.MarkIos.app_row(second_row)}
        {Kati.Screens.MarkIos.widget(home.tonight)}
      </Column>
      <Box fill_width={true} fill_height={true} align="bottom">
        <Column fill_width={true} padding_left={22} padding_right={22} padding_bottom={34}>
          {Kati.Screens.MarkIos.dots()}
          {Kati.Screens.MarkIos.dock(home.dock)}
        </Column>
      </Box>
    </Box>
    """
  end

  @doc """
  The eight tiles of the home screen, in the two rows the drawing lays them out.

  Rows rather than a flat list of eight, because a `Row` does not wrap: the
  chunking has to be declared somewhere, and declaring it in the data keeps
  `app_row/1` free of any opinion about how many tiles a row holds.

  Two of the labels do not match their glyphs, and that is the drawing's own
  doing rather than a slip. Kati ships a **subset** of Material Symbols — 140
  icons, every symbol the drawn screens use — and it contains no camera and no
  music note, so the export named the neighbouring apps for what they are and
  drew them with what the font has: `movie` for Camera, `graphic_eq` for Music.
  Substituting a truer glyph would mean re-subsetting the font for two apps that
  are not Kati's, on a screen whose whole subject is the one tile that is.
  """
  @spec grid() :: [[map()]]
  def grid do
    [
      [
        %{label: "Kati", icon: :mark, badge: "3"},
        %{label: "Calendar", icon: "calendar_month", badge: nil},
        %{label: "Notes", icon: "sticky_note_2", badge: nil},
        %{label: "Camera", icon: "movie", badge: nil}
      ],
      [
        %{label: "Music", icon: "graphic_eq", badge: nil},
        %{label: "Books", icon: "menu_book", badge: nil},
        %{label: "Health", icon: "monitor_heart", badge: nil},
        %{label: "Settings", icon: "settings", badge: nil}
      ]
    ]
  end

  @doc """
  The four apps in the dock, as glyph names only.

  No labels and no badges: an iOS dock draws neither, and the tiles down there
  are a different object from the grid's — 58pt on a plate rather than 60pt on
  the wallpaper — so they take a list of names rather than the grid's maps.
  """
  @spec dock_apps() :: [String.t()]
  def dock_apps, do: ["phone_iphone", "mail", "translate", "graphic_eq"]

  @doc """
  The two halves of the tonight widget, quoted from the screens that own them.

  The media half is the first row of screen 29's own Today widget, taken as the
  map rather than as two strings, so the lock screen and the home screen cannot
  disagree about the evening they are both drawn at. The meal half is the
  dinner in `Kati.Meals.SamplePlan.day/0`, whose slot carries the time and
  whose title carries three courses — the widget column is one line wide and
  shows the first, which is where the drawing cuts it too.

  Both matches are strict. A fixture that stopped holding a dinner, or a Today
  widget that stopped opening on an episode row, fails here at mount rather
  than drawing a plausible different evening, and a plausible different evening
  is precisely the defect this function exists to make impossible.
  """
  @spec tonight() :: [%{time: String.t(), title: String.t()}]
  def tonight do
    [media | _rest] = Lock.drawn_widgets().today.rows
    [%{time: media.time, title: media.title}, dinner()]
  end

  @doc """
  One row of four tiles, spread the way the drawing spreads them.

  `justify-content: space-between` is weighted spacers **between** the cells and
  none at the ends, which is what puts the first tile on the 22pt gutter and the
  last one on the opposite gutter. `Kati.UI.even_row/2` is the usual answer for
  a grid row and is not the answer here: it centres each cell inside an equal
  share of the width, which pulls the two outer tiles inward off the gutters —
  about 15pt each on the frame this was drawn at — and a home screen whose grid
  does not touch its own margins reads as the wrong screen.
  """
  @spec app_row([map()]) :: term()
  def app_row(cells) do
    children =
      cells
      |> Enum.map(&Kati.Screens.MarkIos.app_cell/1)
      |> Enum.intersperse(Kati.Screens.MarkIos.spread())

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {children}
      </Row>
      <Spacer size={26} />
    </Column>
    """
  end

  @doc "The weighted gap that turns a `Row` into `space-between`."
  @spec spread() :: term()
  def spread, do: ~MOB"<Spacer weight={1.0} />"

  @doc """
  One app: its tile, any badge over it, and its label under it.

  The tile and the badge share a 60pt stacking `Box` so the badge can hang off
  the corner. A `Box` gives all of its children one alignment, so the badge is
  laid out at the stack's top-left and carried to `top:-4; right:-4` with
  `offset_x`/`offset_y` — the displacement `Kati.Screens.PickSections` uses for
  the same shape of problem, and for the same reason: it moves what is painted
  without moving what was measured, so the tile does not shift under it.

  The label is centred by a 60pt `Box` rather than by the `Column`, because a
  `Column` has no cross-axis alignment prop and aligns every child to the
  start. The drawing lets a long label overflow its 60pt cell with
  `white-space: nowrap`; a `Text` cannot overflow, so this one ellipsises
  instead, and `max_font_scale` caps how far Dynamic Type can push it towards
  that edge.
  """
  @spec app_cell(map()) :: term()
  def app_cell(app) do
    ~MOB"""
    <Column width={60}>
      <Box width={60} height={60}>
        {Kati.Screens.MarkIos.tile(app)}
        {Kati.Screens.MarkIos.badge(app.badge)}
      </Box>
      <Spacer size={7} />
      <Box width={60} align="center">
        <Text
          text={app.label}
          text_size={10.5}
          max_font_scale={1.4}
          font_weight="medium"
          text_color={Palette.lock_ink()}
          max_lines={1}
        />
      </Box>
    </Column>
    """
  end

  @doc """
  The 60pt tile, in its two kinds.

  Kati's is opaque ivory with the mark drawn on it and does not follow the
  theme; everybody else's is a 15% white patch of the wallpaper with one glyph
  on it, and neither does. The two clauses carry the same geometry — 60pt,
  15pt radius, the drawing's soft drop shadow — because on a launcher grid a
  tile that measured differently from its neighbours would be the bug.
  """
  @spec tile(map()) :: term()
  def tile(%{icon: :mark}) do
    ~MOB"""
    <Box
      width={60}
      height={60}
      corner_radius={15}
      background={Palette.card(:light)}
      shadow={Kati.Screens.MarkIos.tile_shadow()}
      align="center"
    >
      {Kati.Screens.MarkIos.mark(38, Palette.ink(:light))}
    </Box>
    """
  end

  def tile(%{icon: name}) do
    ~MOB"""
    <Box
      width={60}
      height={60}
      corner_radius={15}
      background={Palette.lock_ink_15()}
      shadow={Kati.Screens.MarkIos.tile_shadow()}
      align="center"
    >
      {UI.symbol(name, size: 27, color: Palette.lock_ink_85())}
    </Box>
    """
  end

  @doc """
  The unread disc on the corner of Kati's tile, or nothing at all.

  `nil` draws an explicit empty node rather than being omitted, so that every
  cell in the grid has the same number of children and the one tile that
  carries a count is the only difference between them.

  The `3` is `Palette.on_media/0` — near-white at full alpha in both modes.
  `Kati.Screens.PickSections` reports the gap this fills from the other side:
  its check sits on an orange disc **on a card**, where no token honestly
  covers "a glyph on a hue", so it is left as a literal. Here the disc sits on
  the wallpaper, which puts the mark squarely in the family the palette calls
  `:media` — over a photograph, and so fixed in both modes for the reason the
  hue under it is fixed.
  """
  @spec badge(String.t() | nil) :: term()
  def badge(nil), do: ~MOB"<Spacer size={0} />"

  def badge(count) do
    ~MOB"""
    <Box
      width={20}
      height={20}
      offset_x={44}
      offset_y={-4}
      corner_radius={10}
      background={Palette.accent()}
      border_width={2}
      border_color={Palette.lock_ink_85()}
      align="center"
    >
      <Text
        text={count}
        font_family="mono"
        text_size={10}
        font_weight="medium"
        text_color={Palette.on_media()}
        max_lines={1}
      />
    </Box>
    """
  end

  @doc """
  Kati's mark, at a size and in a colour, as ten boxes on a 240pt grid.

  Every tuple below is one path out of the drawing's SVG — `{x, y, w, h,
  degrees}` in viewBox units, with `x`/`y` the top-left of the **unrotated**
  box, because `rotate` turns a node about its own centre and changes nothing
  about where it was placed. So a rotated stroke is positioned by its midpoint:
  a segment's two endpoints give a centre, a length and an angle, and those
  become a box and a number of degrees.

  The size is a parameter and not two functions because the two instances the
  design draws — 38pt on the tile, 15pt in the widget eyebrow — are the same
  figure, and a second copy at a second scale is how two drawings of one mark
  start to disagree. The colour is a parameter for the reason the moduledoc
  gives: on the tile it is pinned with the asset, in the widget it follows the
  plate.
  """
  @spec mark(number(), pos_integer()) :: term()
  def mark(size, color) do
    s = size / @view_box

    figure =
      [
        # The two rails. `M82 218 L92 94` and its mirror: 124.403 long between
        # the endpoints, centred at (87,156) and (153,156), leaning by
        # asin(10/124.403) — 4.61° — in opposite directions.
        {81.0, 93.8, 12.0, 124.4, 4.61},
        {147.0, 93.8, 12.0, 124.4, -4.61},
        # Five rungs, bottom to top. `y` is the drawn centre less half of the
        # 10-unit stroke; the widths are the drawn ones, and their taper from
        # 74.8 to 57.2 is what makes the ladder recede.
        {82.6, 203.8, 74.8, 10.0, 0.0},
        {84.8, 177.4, 70.4, 10.0, 0.0},
        {87.0, 151.0, 66.0, 10.0, 0.0},
        {89.2, 124.6, 61.6, 10.0, 0.0},
        {91.4, 98.2, 57.2, 10.0, 0.0},
        # The spark's three rays: one upright, two at 45° about their midpoints.
        {116.0, 16.0, 8.0, 12.0, 0.0},
        {129.72, 32.5, 15.56, 8.0, -45.0},
        {94.72, 32.5, 15.56, 8.0, 45.0}
      ]
      |> Enum.map(fn {x, y, w, h, deg} -> stroke(x * s, y * s, w * s, h * s, deg, color) end)
      |> Enum.concat([diamond(109.39 * s, 41.39 * s, 21.21 * s, 8.0 * s, color)])

    ~MOB"""
    <Box width={size} height={size}>
      {figure}
    </Box>
    """
  end

  @doc """
  The tonight widget: the mark, its eyebrow, and two columns split by a rule.

  The plate is `Palette.dock_fill/0` — the app's 90%-opaque chrome surface —
  which is what the drawing asks for down to the byte in light
  (`rgba(251,250,248,.9)`) and which is also the honest reading of the node: a
  widget is Kati's own surface sitting on somebody else's picture, so it follows
  Kati's theme where the tile above it, an asset, does not.

  The rule between the columns is the one measurement here that had to be
  declared. The drawing gets its height from `align-items: stretch`, which has
  no prop; a 1pt `Box` with no height is 0 tall, so it is given the 32pt its
  neighbours measure — a 10pt mono line, the 3pt gap, and a 12.5pt bold line.
  Screen 29 declares its two small widgets' height for the same reason and says
  so.
  """
  @spec widget([map()]) :: term()
  def widget([left, right]) do
    eyebrow = String.upcase(@eyebrow)

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.dock_fill()}
      corner_radius={22}
      shadow={Kati.Screens.MarkIos.widget_shadow()}
      padding={15}
    >
      <Row fill_width={true} align="center">
        {Kati.Screens.MarkIos.mark(15, Palette.ink())}
        <Spacer size={9} />
        <Text
          text={eyebrow}
          font_family="mono"
          text_size={9.5}
          letter_spacing={0.14}
          text_color={Palette.eyebrow()}
          max_lines={1}
        />
      </Row>
      <Spacer size={12} />
      <Row fill_width={true} align="top">
        {Kati.Screens.MarkIos.widget_column(left)}
        <Spacer size={11} />
        <Box width={1} height={32} background={Palette.hairline_strong()} />
        <Spacer size={11} />
        {Kati.Screens.MarkIos.widget_column(right)}
      </Row>
    </Column>
    """
  end

  @doc """
  One half of the widget: a mono time over what happens at it.

  Weighted rather than sized, so the two halves split whatever the device
  leaves after the 15pt padding and the rule — the reason `Kati.UI.even_row/2`
  gives at length for weighting anything that was measured off the 402dp frame.
  """
  @spec widget_column(map()) :: term()
  def widget_column(row) do
    ~MOB"""
    <Column weight={1.0}>
      <Text
        text={row.time}
        font_family="mono"
        text_size={10}
        text_color={Palette.muted()}
        max_lines={1}
      />
      <Spacer size={3} />
      <Text
        text={row.title}
        text_size={12.5}
        font_weight="bold"
        text_color={Palette.ink()}
        max_lines={1}
      />
    </Column>
    """
  end

  @doc """
  The three page dots, the first of them lit.

  Drawn rather than derived: this screen has one page and no paging gesture, so
  the dots say what the *drawing* says — that a real home screen has more pages
  than the one Kati is on — and nothing here could count them.
  """
  @spec dots() :: term()
  def dots do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Spacer weight={1.0} />
        <Box width={6} height={6} corner_radius={3} background={Palette.lock_ink()} />
        <Spacer size={6} />
        <Box width={6} height={6} corner_radius={3} background={Palette.lock_ink_40()} />
        <Spacer size={6} />
        <Box width={6} height={6} corner_radius={3} background={Palette.lock_ink_40()} />
        <Spacer weight={1.0} />
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc """
  The dock: four tiles on a translucent plate, spread like the grid above it.

  The plate is `Palette.on_media_track/0` at 25% where the drawing writes 20%,
  which is the one rounding on this screen that goes the wrong way on purpose.
  The tiles inside it are the same 15% as the tiles on the wallpaper, so a
  plate rounded *down* would have been darker than its own contents and the
  dock would have read as four holes cut in the wallpaper rather than as a
  shelf laid on it.
  """
  @spec dock([String.t()]) :: term()
  def dock(icons) do
    children =
      icons
      |> Enum.map(&Kati.Screens.MarkIos.dock_tile/1)
      |> Enum.intersperse(Kati.Screens.MarkIos.spread())

    ~MOB"""
    <Row
      fill_width={true}
      corner_radius={28}
      background={Palette.on_media_track()}
      padding_left={16}
      padding_right={16}
      padding_top={11}
      padding_bottom={11}
      align="center"
    >
      {children}
    </Row>
    """
  end

  @doc "A dock tile: 58pt and 14pt of radius, where the grid's are 60 and 15."
  @spec dock_tile(String.t()) :: term()
  def dock_tile(name) do
    ~MOB"""
    <Box width={58} height={58} corner_radius={14} background={Palette.lock_ink_15()} align="center">
      {UI.symbol(name, size: 27, color: Palette.lock_ink_85())}
    </Box>
    """
  end

  @doc """
  The warm bloom in the top corner, as much of it as a vertical band can be.

  `Palette.accent_fill/0` is `0x47E8823C`, which is the drawing's
  `rgba(232,130,60,.28)` exactly, so the colour survives the flattening even
  though the shape does not. Both ends of the band are the same RGB and only
  the alpha moves, for the reason `Kati.UI.paper_fade/3` sets out: Compose
  interpolates in straight RGBA, so a fade to transparent white greys the
  middle of the band and a fade to transparent black dirties it.

  The 420pt height is where the drawn bloom reaches zero on the 874pt frame it
  was exported at — its centre is 8% down and it clears at 60% of a 70% radius —
  and it is declared rather than a fraction of the device because the bloom is
  a fixed piece of the picture, not a proportion of whatever screen it lands on.
  """
  @spec glow() :: term()
  def glow do
    gradient = "to_bottom #" <> hex8(Palette.accent_fill()) <> " #00" <> rgb(Palette.accent())

    ~MOB"""
    <Box fill_width={true} height={420} gradient={gradient} />
    """
  end

  @doc """
  `0 2px 6px -2px rgba(26,25,23,.35)` — the lift under every tile.

  Built the way `Kati.UI.paper_fade/3` builds its gradient: the RGB is read off
  the palette and only the alpha is written here, so no colour in this file is
  a hex literal. `Palette.ink(:light)` and not `Palette.ink/0`, because a
  shadow cast onto a wallpaper is cast by an object sitting on a photograph —
  the mode-following ink would turn this into a white glow on a dark phone.
  `Kati.Theme` has seven shadow recipes and this is none of them: a launcher
  tile sits closer to its ground than any card in the app does.
  """
  @spec tile_shadow() :: String.t()
  def tile_shadow, do: "0 2 6 -2 #59" <> rgb(Palette.ink(:light))

  @doc """
  `0 8px 24px -10px rgba(0,0,0,.4)` — the widget's deeper lift.

  The drawing casts this one in pure black where the tiles are cast in ink, and
  it is taken as ink at the same alpha: every one of `Kati.Theme`'s own shadow
  recipes is `#..1A1917`, so a black shadow on one node would be the only cool
  shadow in the app for a difference nobody can see at 40% under a 24pt blur.
  """
  @spec widget_shadow() :: String.t()
  def widget_shadow, do: "0 8 24 -10 #66" <> rgb(Palette.ink(:light))

  # The dinner half of the widget. `Dinner · 19:30` and `Miso salmon, greens,
  # rice` are one row of the meal plan, split at the separators the fixture
  # already writes rather than re-typed — the time off the slot, the first
  # course off the title.
  defp dinner do
    %{slot: slot, title: title} =
      Enum.find(SamplePlan.day(), &String.starts_with?(&1.slot, "Dinner"))

    %{
      time: slot |> String.split(" · ") |> List.last(),
      title: title |> String.split(", ") |> hd()
    }
  end

  # One SVG stroke. `corner_radius` is deliberately absent: the mark is drawn
  # with `stroke-linecap="butt"`, so every end is square.
  defp stroke(x, y, w, h, deg, color) do
    ~MOB"""
    <Box offset_x={x} offset_y={y} width={w} height={h} rotate={deg} background={color} />
    """
  end

  # The spark. An unfilled diamond of diagonal 30 is a square of side 30/√2
  # turned 45°, and a border is what an SVG stroke with `fill="none"` is.
  defp diamond(x, y, side, width, color) do
    ~MOB"""
    <Box
      offset_x={x}
      offset_y={y}
      width={side}
      height={side}
      rotate={45.0}
      border_width={width}
      border_color={color}
    />
    """
  end

  # `rem/2` rather than a Bitwise import: the low 24 bits of an 0xAARRGGBB
  # integer are the RGB, and this file imports one sigil and nothing else.
  defp rgb(argb),
    do: argb |> rem(0x1000000) |> Integer.to_string(16) |> String.pad_leading(6, "0")

  defp hex8(argb), do: argb |> Integer.to_string(16) |> String.pad_leading(8, "0")
end
