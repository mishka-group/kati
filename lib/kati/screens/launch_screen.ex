defmodule Kati.Screens.LaunchScreen do
  @moduledoc """
  Screen 65 — the launch screen, as a picture of itself.

  Built to `.scratch/design/pending/65.html`: the display mark at full size on
  paper, the wordmark under it in both scripts, the product line between two
  rules, and a boot bar with the house credit under it at the bottom bezel.

  ## Android draws the launch. This module draws a portrait of it.

  The caption calls this *what you see for the second after the tap*, and the
  honest answer is that **no Elixir screen can be that**, this one included.
  Two mechanisms own the real launch and both are Android's:

    * `android/app/src/main/res/values-v31/styles.xml` hands the system splash
      `@color/ic_launcher_background` and lets Android 12+ scale the adaptive
      launcher icon into its own 288dp canvas, and
    * `@drawable/splash` takes over partway through the boot and draws
      `@drawable/kati_mark` at its intrinsic 133dp — a number chosen, as that
      file records, so the mark does not change size at the handoff.

  Elixir is not running yet for either of them. `mob_start_beam` polls
  `Activity.hasWindowFocus()` before `erl_start()`, and `hasWindowFocus()` only
  goes true once the window has **drawn** — so the very frame this screen would
  have to paint is the frame the BEAM is waiting on. `res/drawable/splash.xml`
  says what happens when you hold it: the poll burns its 3000ms timeout and
  starts the BEAM anyway, into the hwui/ERTS race the wait exists to prevent.

  So screen 65 is a reference sheet in screen 27's manner — a picture of a
  state, pushed under Settings and gone to rather than shown — and it carries a
  back pill for that reason, as 27 and 67 do. The drawing has no pill; the frame
  adds one, and that is the frame's, not the drawing's.

  ## The colourway the drawing chose is the one the splash does not use

  The real splash is the **black** colourway: `#1A1917` ground, mark in
  `#F5F2EE`, stated in `values/ic_launcher_background.xml` and in
  `kati_mark.xml`'s own header. The drawing is the paper colourway — ink on
  `#EFECE7` — and its caption says why: *over the same paper the app is built
  on, so the launch dissolves into the home screen rather than cutting to it.*

  Both are true and neither is a mistake, so this file draws what 65 draws and
  says where that lands. Every colour here is a `Kati.Theme.Palette` token, so
  the page follows the mode — and in **dark** it resolves to `#F5F2EE` on
  `#121110`, which is the splash's own colourway to within the few units
  `Palette`'s ramp puts between `#121110` and `#1A1917`. The dissolve the
  caption asks for is therefore already true in dark and is still a repaint in
  light. That is a finding about the app, not a defect in either drawing, and
  the thing that would settle it is a second splash colourway keyed to the
  stored theme preference — which is `Kati.Theme.Mode`'s question, not a
  screen's.

  ## What screen 29 has that this could call, and why none of it fits

  Screen 29 is the other drawing of the app seen from outside, and the reuse
  check against it comes back empty for one structural reason:
  **every public builder in `Kati.Screens.Lock` paints on a photograph.** They
  are the `lock_*` family, which `Kati.Theme.Palette` labels `:media` and
  defines as *a colour whose ground is a photograph, not a themed surface — a
  photograph does not get lighter when the app does*. Screen 65's ground is
  `paper`, the themed surface, so a call into any of them would paint a
  wallpaper colour on a page that has no wallpaper. Candidate by candidate:

    * **`Lock.scrim/0`** is the right *node* — one full-bleed `Box` carrying a
      vertical gradient over the ground — and the wrong three stops: it darkens
      a picture at both ends, where `glow/0` warms a 280pt band at the top and
      is transparent everywhere else.
    * **`Lock.eyebrow/1`** is the right *idea*. Both screens set a mono,
      letter-spaced, uppercase label with **no accent dash**, and for the same
      reason — Kati's orange means new/now, and neither an OS-idiom widget
      title nor a brand line is either. It is still uncallable: it is 9pt at
      .14 tracking in `lock_ink_55`, against 10pt at .2 and .18 in `eyebrow`
      and `tertiary` here. If it took its colour the way `Kati.UI.paper_fade/3`
      takes its mode — as a parameter with the drawn value as the default —
      this screen would call it twice. That is the one upstream ask this
      comparison produced.
    * **`Lock.clock/1`** is the same stack in the other order (small line over
      large), in the same photograph whites.
    * **`wallpaper/0`, `thumb/1`, `today_card/1`, `year_card/1`,
      `small_widgets/2`, `pixel/1`** draw objects screen 65 does not contain.

  Two things do carry over, and both are findings rather than code:

    * **No `Scroll`.** 29's `render/1` records that a vertical `Scroll` hands
      its children an unbounded height, where `fill_height` collapses back to
      wrap-content — and that directly inside the root `Box` the bound is the
      viewport. This screen needs exactly that: the boot bar is pinned 56 from
      the **bezel**, so nothing here may scroll.
    * **Centring is a `Row`, not a `Column` property.** `MobBridge.kt` builds a
      `column` as `Column(modifier = m)` with no `horizontalAlignment` argument
      at all, so a Column's children are start-aligned always. `Lock.clock/1`
      centres its two lines with `fill_width` Rows and weighted `Spacer`s on
      both sides; `centred/1` here is that idiom given a name, because this
      screen does it five times.

  ## The mark is drawn, not imported

  `<Image>` resolves to Coil with a URL or a `java.io.File`
  (`MobBridge.kt`'s `MobImage`), and `@drawable/kati_mark` is an Android vector
  resource that never becomes a file Coil can decode — the bridge's `canvas`
  `image` op is explicit that drawable lookup is not implemented. So `mark/0`
  redraws the vector through `Mob.Canvas`, from the same 240-unit viewport, the
  same coordinates, the same stroke widths and — load-bearing, per
  `kati_mark.xml`'s own header — the same paint order: rails and rungs, then
  the spark, then the legs, then the filled body over the top, then the
  punched-out eye. That order is what puts the sparrow in FRONT of the near
  rail with the rungs passing BEHIND it.

  The coordinates stay in the vector's units and are scaled by `unit/1` at the
  end, so the tables below can be diffed line for line against
  `res/drawable/kati_mark.xml`. Two notes on the redraw:

    * **This repo's canvas reads dp, not viewport units.** `Mob.Canvas`'s own
      docs promise a declared-logical-unit coordinate space, and this app's
      `MobCanvas` does not implement it — `canvasFloat/1` is `dp.dp.toPx()`
      with no `sx`/`sy`. So the scale is applied here rather than by the
      bridge, and `@mark_scale` is the whole of it.
    * **Miter limit is Compose's 4, not the vector's 10.** `canvasStroke/1`
      builds a `Stroke` without one. The sharpest join in the mark is the
      spark's 90°, which needs a ratio of 1.41, so nothing in this drawing
      reaches either bound and the two render identically.

  ## The radial glow is a vertical one, and loses an axis doing it

  The drawing asks for `radial-gradient(80% 100% at 50% 0%, rgba(232,130,60,.13),
  transparent 70%)`. The bridge's gradient parser is vertical only — `to_top` or
  `to_bottom`, the same limit `Kati.Screens.States` records for its skeleton
  shimmer — so the wash keeps its vertical falloff and loses its horizontal
  one: it reaches the left and right bezels at full strength along the top edge,
  where the radial would already have faded off. At 13% alpha over paper that is
  a difference of about two units at the corners, which is why the band ships
  rather than being dropped.

  The string is built the way `Kati.UI.paper_fade/3` builds its own: the RGB
  comes out of `Palette.accent/0` and only the **alpha** is written here. The
  transparent end must be the accent at alpha 0 and not `Palette.transparent/0`,
  for the reason that helper gives — Compose interpolates in straight RGBA, so a
  fade to transparent white greys the middle of the band.

  ## Where a token's value and a token's name disagree

  Two colours in the drawing are somebody else's name:

    * The boot bar's track is `#E0DAD1`, which is `Palette.star_empty/0`'s light
      value **and no other token's**, so the mapping is forced rather than
      chosen — the same argument `Kati.UI.eyebrow_trailing/1` makes for taking
      `Palette.sub/0` for a trailing action. `Palette.track/0` is the name that
      fits a progress groove and is three units lighter, and this module's rule
      is the palette's own: *light mode must not change by a single pixel.*
    * The two 20pt rules flanking the product line are `#D6D0C7`, which is no
      token's value at all. `Palette.bar_neutral/0` is the nearest, two units
      off on red and green and one on blue, and it is on the drawing's
      **inert-fill** ladder rather than its text ladder — which is where the
      palette says a rule belongs, because a rule and a glyph at one lightness
      on paper are not the same thing on near-black. This is the only colour on
      the screen that is not exact, and it is recorded here rather than rounded
      quietly.

  ## Two labels hand-rolled, and one Persian word

  `Kati.UI.eyebrow/2` is not called for either mono line. It draws a 13x2 accent
  dash and then a **left-aligned** label inside a `fill_width` Column, and both
  lines here are centred — one between two rules, one alone. Reproducing that
  through the helper would mean passing a transparent dash and then defeating
  its own `fill_width`, which is two workarounds to arrive at a different
  layout.

  `کاتی` carries `font_family="fa"` even though this is a Latin screen, and it
  is not optional: `kati_sans_400.ttf` carries **zero** code points in
  U+0600–U+06FF, so a Persian label without the prop is a row of empty boxes
  rather than a fallback — `Kati.Screens.Fa` has the cmap parse. The drawing
  states no Persian line height, so it takes `Kati.Theme.fa_line_height/0`, the
  declared 1.2 that exists so a wrong number is wrong in one place.

  ## The bar is at 58% because the drawing is, and nothing can improve on that

  27's rule applies unchanged: each card on a reference sheet is a picture of a
  state, not a report that the app is in it. A boot bar is the extreme case —
  the one quantity it could report is the BEAM's own start, and by the time an
  Elixir screen renders, that has finished. There is nothing to read, so the
  fraction is the drawing's own and is drawn through
  `Kati.Components.MishkaProgress` in its `render: :box` shape, which is the
  only one where the geometry lives in the values rather than in Material's
  defaults.

  Nothing on this screen taps. `Kati.Screens.Pushed` defines no `handle_tap/2`
  on purpose, so a control that grew one and was never wired would be reported
  as a `DEAD TAP` rather than silently doing nothing; there are no controls here
  to report.
  """

  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.Components.MishkaProgress
  alias Kati.Theme.Palette

  # The mark's own viewport, and the size the drawing renders it at. Every
  # coordinate below is written in the 240-unit space `res/drawable/kati_mark.xml`
  # uses, so the two can be compared without arithmetic, and `unit/1` is the
  # only place the 150 appears.
  @mark_viewport 240
  @mark_size 150
  @mark_scale @mark_size / @mark_viewport

  # Five rungs, `{x1, x2, y}`, narrowing as the ladder recedes. Transcribed from
  # the vector rather than derived from a taper, because the vector is the
  # artwork and a formula that happened to agree today would stop agreeing the
  # first time the mark is redrawn.
  @rungs [
    {102.6, 177.4, 208.8},
    {104.8, 175.2, 182.4},
    {107.0, 173.0, 156.0},
    {109.2, 170.8, 129.6},
    {111.4, 168.6, 103.2}
  ]

  # The faceted spark carried over from the Mishka mark: a stroked, closed
  # quadrilateral, not a rotated square. Compose's `rotate` is a paint-only
  # modifier and would have worked for the shape, but not for the four mitred
  # corners, which are the facets.
  @spark [{140, 37}, {155, 52}, {140, 67}, {125, 52}]

  # The sparrow, as one filled twelve-point path — head and back, breast, the
  # tail spike out to the left, and back up over the wing. A concave polygon is
  # the one thing no arrangement of `Box` nodes can approximate honestly, and it
  # is why this screen goes to the canvas at all.
  @body [
    {106, 151},
    {92, 148},
    {80, 157},
    {76, 172},
    {73, 188},
    {56, 197},
    {63, 205},
    {80, 200},
    {88, 205},
    {105, 191},
    {108, 176},
    {102, 160}
  ]

  # Punched out in the PAGE colour rather than left as a hole: the canvas has no
  # even-odd fill rule exposed, so the eye is a second fill over the first, and
  # it therefore has to know what it is sitting on. In dark that is `#121110`,
  # which is what keeps the eye an eye instead of a light spot.
  @eye [{92, 155}, {96, 159}, {92, 163}, {88, 159}]

  @doc """
  Screen 65's frame: the wash, the lockup, and the bottom band, in that order.

  A `Box` and not a `Scroll`, for the reason `Kati.Screens.Lock` records — a
  vertical `Scroll` hands its children an unbounded height and `fill_height`
  becomes a no-op inside one. The bottom band is pinned 56 from the bezel, so
  this screen has to measure against the viewport, and directly inside the
  frame's root `Box` it does.

  No background is painted here. `Kati.Screens.Pushed.chrome/2`'s root already
  carries `background={:background}`, which is `Kati.Theme`'s `@paper` in light
  and `@paper_dark` in dark — the drawing's `#EFECE7` exactly, and repainting it
  would be a second answer to a question already answered.
  """
  @spec content(map()) :: map()
  def content(_assigns) do
    ~MOB"""
    <Box fill_width={true} fill_height={true}>
      {Kati.Screens.LaunchScreen.glow()}
      <Box fill_width={true} fill_height={true} align="center">
        {Kati.Screens.LaunchScreen.lockup()}
      </Box>
      <Box fill_width={true} fill_height={true} align="bottom" padding_bottom={56}>
        {Kati.Screens.LaunchScreen.footer()}
      </Box>
    </Box>
    """
  end

  @doc """
  The 280pt warm wash across the top of the page.

  The drawing's radial gradient with its horizontal axis removed — see the
  moduledoc for what that costs and why the band still ships. The colour is
  `Palette.accent/0`'s RGB with the drawing's own alphas written around it, the
  technique `Kati.UI.paper_fade/3` uses for the same reason: a gradient takes a
  CSS-shaped `#AARRGGBB` string, which is not a colour prop and cannot take a
  token, so the token supplies the only part of it that is a colour.

  The far end is the accent at alpha 0 rather than `Palette.transparent/0`.
  Compose interpolates in straight RGBA, so fading to transparent white would
  grey the middle of the band; only a fade to the same RGB stays invisible along
  its whole length.
  """
  @spec glow() :: map()
  def glow do
    # ~MOB is an uppercase sigil, so #{} inside it is literal text — the
    # gradient string has to be built out here, as `paper_fade/3` builds its own.
    rgb =
      Palette.accent()
      |> rem(0x1000000)
      |> Integer.to_string(16)
      |> String.pad_leading(6, "0")

    # 0x21 is .13 x 255 rounded, the drawing's own alpha; 70% is where it
    # reaches nothing, also the drawing's.
    gradient = "to_bottom #21#{rgb} #00#{rgb} 70%"

    ~MOB"""
    <Box fill_width={true} height={280} gradient={gradient} />
    """
  end

  @doc """
  The centred block: the mark, the wordmark in both scripts, then the line name.

  `offset_y` is **-20 and not the drawing's -40**, and the difference is CSS
  rather than a correction. The lockup is the only in-flow child of a
  `justify-content: center` column, and `justify-content` distributes free space
  computed from each item's **margin** box — so a `margin-top: -40px` enlarges
  the free space by 40, hands half of it back above the item, and moves it by
  20. Copying the -40 across would put the mark twice as far off centre as the
  drawing has it.

  Every row is centred through `centred/1` rather than by the Column, because a
  Column in this bridge has no horizontal alignment at all.
  """
  @spec lockup() :: map()
  def lockup do
    ~MOB"""
    <Column fill_width={true} offset_y={-20}>
      {Kati.Screens.LaunchScreen.centred(Kati.Screens.LaunchScreen.mark())}
      <Spacer size={26} />
      {Kati.Screens.LaunchScreen.centred(Kati.Screens.LaunchScreen.wordmark())}
      <Spacer size={8} />
      {Kati.Screens.LaunchScreen.centred(Kati.Screens.LaunchScreen.wordmark_fa())}
      <Spacer size={22} />
      {Kati.Screens.LaunchScreen.line_name()}
    </Column>
    """
  end

  @doc """
  The display mark, redrawn from `res/drawable/kati_mark.xml` onto a canvas.

  Paint order is the vector's and is load-bearing: rails, rungs, spark, legs,
  filled body, eye. That is what puts the sparrow in front of the near rail with
  the rungs passing behind it, which is how the brand sheet defines this lockup —
  reordering the list changes which shape the bird is standing on.

  `Palette.ink/0` for every stroke and the body, `Palette.paper/0` for the eye,
  so the whole mark inverts with the mode in one step rather than in fifteen.
  """
  @spec mark() :: map()
  def mark do
    ink = Palette.ink()

    rails = [line(102, 218, 112, 94, 12, ink), line(178, 218, 168, 94, 12, ink)]
    rungs = Enum.map(@rungs, fn {x1, x2, y} -> line(x1, y, x2, y, 10, ink) end)

    spark = [
      outline(@spark, 8, ink),
      line(140, 28, 140, 16, 8, ink),
      line(152, 42, 163, 31, 8, ink),
      line(128, 42, 117, 31, 8, ink)
    ]

    sparrow = [
      line(88, 204, 88, 213, 5, ink),
      line(99, 199, 100, 213, 5, ink),
      solid(@body, ink),
      solid(@eye, Palette.paper())
    ]

    Mob.UI.canvas(
      width: @mark_size,
      height: @mark_size,
      draw: rails ++ rungs ++ spark ++ sparrow
    )
  end

  @doc """
  `Kati`, at the one size in the app where the name is the content.

  36pt at `extrabold` with the drawing's -.04em tracking. There is no
  `Kati.UI` helper for this and there should not be: the app's largest existing
  type is the 28pt statistic in `Kati.UI.stat/2`, which is a number with a label
  under it, and a wordmark that borrowed a statistic's recipe would move the
  next time a statistic did.
  """
  @spec wordmark() :: map()
  def wordmark do
    ~MOB"""
    <Text
      text="Kati"
      text_size={36}
      font_weight="extrabold"
      letter_spacing={-0.04}
      text_color={Kati.Theme.Palette.ink()}
      max_lines={1}
    />
    """
  end

  @doc """
  `کاتی`, the name in the script the app is mirrored into.

  `font_family="fa"` is not decoration: `kati_sans_400.ttf` — what an unstyled
  `Text` resolves to — carries no code point in U+0600–U+06FF, so without the
  prop this line is four empty boxes rather than a degraded rendering. It sits
  in `Palette.sub/0`, the drawing's `#8A8479`, because the Persian name is the
  second line of the wordmark rather than a second wordmark.

  `Kati.UI.chip/2` and `Kati.UI.Segmented` are deliberately not in reach of this
  line for the same reason `Kati.Screens.Fa` gives about the vendored set: they
  build their own `Text` and leave `font_family` off, so a Persian label handed
  to either is absent rather than restyled.
  """
  @spec wordmark_fa() :: map()
  def wordmark_fa do
    ~MOB"""
    <Text
      text="کاتی"
      font_family="fa"
      text_size={19}
      font_weight="semibold"
      line_height={Kati.Theme.fa_line_height()}
      text_color={Kati.Theme.Palette.sub()}
      max_lines={1}
    />
    """
  end

  @doc """
  `LADDER` between two 20pt rules — the product line, not a section label.

  Hand-rolled rather than `Kati.UI.eyebrow/2`, which draws a 13x2 accent dash
  and then a left-aligned label inside a `fill_width` Column. Both differences
  are fatal here: the label is centred between two rules rather than trailing
  one mark, and Kati's orange means new/now, which a line name is not — the same
  reason `Kati.Screens.Lock.eyebrow/1` drops the dash on the lock screen.

  Written in sentence case and upcased at render, as `Kati.UI.eyebrow/2` does,
  because the drawing sets it in sentence case under `text-transform: uppercase`
  and the label in the source should read the way the design file writes it.

  Centred by a weighted `Spacer` at **each** end. There was one only at the
  leading end for a while, which does not centre a group — it pushes it to the
  trailing edge — and on a Pixel 9a the second rule ran off the right of the
  screen with the label pinned against it. A single weighted spacer is the
  idiom for *push everything after me to the far side*; two are the idiom for
  *centre what is between them*, and this is the second one.
  """
  @spec line_name() :: map()
  def line_name do
    ~MOB"""
    <Row fill_width={true} align="center">
      <Spacer weight={1.0} />
      {Kati.Screens.LaunchScreen.rule()}
      <Spacer size={9} />
      <Text
        text={String.upcase("Ladder")}
        font_family="mono"
        text_size={10}
        letter_spacing={0.2}
        text_color={Kati.Theme.Palette.eyebrow()}
        max_lines={1}
      />
      <Spacer size={9} />
      {Kati.Screens.LaunchScreen.rule()}
      <Spacer weight={1.0} />
    </Row>
    """
  end

  @doc """
  One of the two 20x1.5 rules the line name sits between.

  `Palette.bar_neutral/0` rather than an exact match, because the drawing's
  `#D6D0C7` is no token's value — see the moduledoc for the two units. It is
  taken off the palette's **inert-fill** ladder rather than its text ladder,
  which is the placement rule for a mark that is a fill rather than a glyph, and
  is what keeps this rule visible on near-black instead of four units off the
  page.
  """
  @spec rule() :: map()
  def rule do
    ~MOB"""
    <Box width={20} height={1.5} background={Kati.Theme.Palette.bar_neutral()} />
    """
  end

  @doc """
  The bottom band: the boot bar, then the house credit, 56 above the bezel.

  Pinned to the bezel rather than placed after the lockup, which is what the
  drawing does with `position: absolute; bottom: 56px` — the two blocks are
  independent of each other, so a taller device moves them apart rather than
  moving both down.
  """
  @spec footer() :: map()
  def footer do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.LaunchScreen.centred(Kati.Screens.LaunchScreen.boot_bar())}
      <Spacer size={16} />
      {Kati.Screens.LaunchScreen.centred(Kati.Screens.LaunchScreen.credit())}
    </Column>
    """
  end

  @doc """
  The 120x3 boot bar, filled to the drawing's 58%.

  `render: :box` and a declared `width`, which is the shape
  `Kati.Components.MishkaProgress` calls portable: both boxes carry both
  dimensions, the fill is `120 * 0.58` rather than a `weight`, and Material's
  own metrics — its 4dp thickness, its track colour, whatever caps and gaps the
  Material version of the day draws — are out of the picture entirely. A 3pt
  bar with 2pt corners and a `#E0DAD1` groove is not expressible through
  `<Progress>` at any combination of props, because there the geometry lives in
  the primitive.

  58 is the drawing's number and stays one. The only quantity a boot bar could
  report is the BEAM's own start, and an Elixir screen renders after that has
  finished — so this is a picture of a state in 27's sense, and reading a true
  figure into it would be dating a real number against a boot that already
  happened.
  """
  @spec boot_bar() :: map()
  def boot_bar do
    MishkaProgress.progress(
      value: 58,
      render: :box,
      width: 120,
      height: 3,
      corner_radius: 2,
      color: Palette.ink(),
      track_color: Palette.star_empty()
    )
  end

  @doc """
  `A MISHKA PROJECT`, the last line on the page.

  `Palette.tertiary/0` is the drawing's `#B3ACA2` exactly, and its meaning fits
  as well as its value does — *a mark that is present but not addressed*, which
  is what a credit under a boot bar is. Upcased at render for the reason
  `line_name/0` gives.
  """
  @spec credit() :: map()
  def credit do
    ~MOB"""
    <Text
      text={String.upcase("A Mishka project")}
      font_family="mono"
      text_size={10}
      letter_spacing={0.18}
      text_color={Kati.Theme.Palette.tertiary()}
      max_lines={1}
    />
    """
  end

  @doc """
  One node, centred across the width.

  A `fill_width` Row with a weighted `Spacer` on each side — the idiom
  `Kati.Screens.Lock.clock/1` uses to centre the lock screen's date and time,
  and it is an idiom rather than a preference: `MobBridge.kt` builds a `column`
  as `Column(modifier = m)` with no `horizontalAlignment` argument, so a
  Column's children are start-aligned and nothing in the markup can ask
  otherwise. Named here because this screen centres five things and five copies
  of the same three-node Row is how one of them ends up different.
  """
  @spec centred(map()) :: map()
  def centred(node) do
    ~MOB"""
    <Row fill_width={true} align="center">
      <Spacer weight={1.0} />
      {node}
      <Spacer weight={1.0} />
    </Row>
    """
  end

  # ── The mark's own arithmetic ───────────────────────────────────────────────
  #
  # Everything above passes coordinates in the vector's 240-unit space; these
  # three are the only place the drawing's 150 touches them.

  # `cap: :butt` on every stroke, matching the vector's own `strokeLineCap`. It
  # is not the default anywhere it matters visually — a round cap would extend
  # each rung by half its 10-unit width at both ends and push the ladder wider
  # than the rails it sits between.
  defp line(x1, y1, x2, y2, width, color) do
    Mob.Canvas.line(unit(x1), unit(y1), unit(x2), unit(y2),
      color: color,
      width: unit(width),
      cap: :butt
    )
  end

  # A closed, STROKED path — the spark is an outline in the vector, and
  # `Mob.Canvas.path/2` fills only when told to. `join: :miter` is what makes
  # the four corners points rather than curves.
  defp outline(points, width, color) do
    Mob.Canvas.path(Enum.map(points, &unit/1),
      color: color,
      width: unit(width),
      closed: true,
      cap: :butt,
      join: :miter
    )
  end

  defp solid(points, color) do
    Mob.Canvas.path(Enum.map(points, &unit/1), color: color, fill: true, closed: true)
  end

  defp unit({x, y}), do: {unit(x), unit(y)}
  defp unit(n), do: n * @mark_scale
end
