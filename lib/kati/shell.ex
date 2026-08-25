defmodule Kati.Shell do
  @moduledoc """
  The four-root shell: content, scrim, floating pill tab bar, detached FAB.

  ## Why this is hand-rolled rather than `<TabBar>`

  Mob's `<TabBar>` node is **fully implemented** — `MobBridge.kt:3726-3751`
  builds a `Scaffold` with a Material 3 `NavigationBar`, one `NavigationBarItem`
  per tab, and renders `children[activeIdx]`. It works. It is simply the wrong
  shape: Kati's chrome is a *detached* pill (`corner_radius: 32`, 0.9-alpha
  fill, inset from every edge) with a separate 64×64 FAB beside it, and a
  Material `NavigationBar` is an edge-to-edge bar pinned to the window bottom.
  No prop on that node reshapes it into this.

  Note also that `<TabBar>` serialises **all** branches and renders only the
  active one, so four real roots would cost four subtrees of JSON per frame.

  ## Why `switch_tab/2` is not used

  `Mob.Socket.switch_tab/2` writes `{:switch_tab, tab}` into the socket, and
  `Mob.Screen` then explicitly throws it away — `screen.ex:611-613`:

      {:switch_tab, _tab} ->
        # Tab switching is handled renderer-side; clear the action.

  That is correct for `<TabBar>`, whose Compose code owns its own selection
  state. For a hand-rolled shell it means the function is inert, so Kati keeps
  the active root in its own assign and swaps screens with `reset_to/3`.

  ## Structure

  A root `Box` stacks its children, later ones on top (`MobBridge.kt:2654-2660`),
  and `align:` sets `contentAlignment`. Since alignment applies to every child
  of a Box, each overlay is its own fill-Box with its own alignment:

      Box(fill)                      ← content, top-aligned
        ├── content
        ├── Box(align: :bottom)      ← scrim
        ├── Box(align: :bottom)      ← the pill
        └── Box(align: :bottom_trailing) ← the FAB
  """

  import Mob.Sigil

  alias Kati.Theme.Palette

  # The design's icon names, not Compose's. Screen 01's bar is
  # home / calendar_month / grid_view / bar_chart_4_bars — and the Material
  # Icons set the template ships with has neither of the last two.
  @roots [
    %{id: :home, label: "Home", icon: "home", screen: Kati.Screens.Home},
    %{id: :calendar, label: "Calendar", icon: "calendar_month", screen: Kati.Screens.Calendar},
    %{id: :library, label: "Library", icon: "grid_view", screen: Kati.Screens.Library},
    %{id: :stats, label: "Stats", icon: "bar_chart_4_bars", screen: Kati.Screens.Stats}
  ]

  def roots, do: @roots

  def screen_for(id), do: Enum.find(@roots, &(&1.id == id)).screen

  @doc """
  Wraps a root screen's content in the shell chrome.

  ## The sizing rule that governs this file

  On Android a **`Box` always fills its parent's width unless it carries an
  explicit `width`** — `MobBridge.kt:2662-2663` applies `fillMaxWidth()` whenever
  no `width` prop is present, and `fill_width: false` does not opt out. Mob's own
  README advises passing `fill_width={false}` "for anything meant to be as wide
  as its content", which is **wrong for Box on Android**.

  `Row` and `Column` do hug their content (`:2644-2655` apply only the node's own
  modifier). So: containers that should hug are Rows and Columns; a Box is used
  only when something must fill, or must be an exact size.

  Overlays additionally need `fill_height: true` — without the viewport as a
  reference frame, `align:` has nothing to align against and the chrome lands at
  the top of a wrap-height Box.

  ## Which mode the chrome draws in

  `:mode` used to default to `:light`, and every caller passed `:light` anyway,
  so the dock fill, the tab well and the FAB were light-mode colours whatever
  theme was installed. The default is now the mode that **is** installed —
  `Kati.Theme.Palette.mode/0`, which reads `Mob.Theme.current/0` rather than
  re-resolving the stored preference, so the raw colours below and the
  `:background` atom above cannot end up on opposite sides within one frame.

  The key is still read, so a screen drawn deliberately on one side can pin it.
  Passing `:light` from a screen that is not is how this bug started.
  """
  def render(assigns) do
    active = assigns.root
    mode = Map.get(assigns, :mode, Palette.mode())

    direction = Kati.Locale.direction_prop()

    # What the device calls this screen. Nothing else on a phone says which of
    # the 152 is on top: the bridge's root state is a counter and a string, and
    # asserting on visible text is not a substitute because Kati draws the same
    # words in an English screen and its Persian mirror, and in a live screen
    # and its `— states` sheet. `Mob.Renderer` serialises any prop it does not
    # special-case, so this arrives in Kotlin under the key `K-35 test-tag`
    # reads and becomes a Compose `testTag`.
    # `active` is the root's atom — `:home`, `:calendar`, `:library`, `:stats` —
    # not the struct `tab/3` receives.
    screen = "screen:#{active}"

    ~MOB"""
    <Box
      fill_width={true}
      fill_height={true}
      background={:background}
      layout_direction={direction}
      accessibility_id={screen}
    >
      {assigns.content}
      {scrim(mode)}
      {dock(active, mode)}
    </Box>
    """
  end

  # The design layers a 120pt `pointer-events: none` gradient between content and
  # chrome so text does not collide with the pill as it scrolls under. Mob has no
  # gradient node, so this is a flat scrim at the paper colour: visually weaker
  # than the design, and recorded as such rather than pretended.
  # A fade, not a lid. The flat opaque Box this replaces cut straight through
  # whatever it covered — visibly slicing Home's Sections tiles in half.
  # The fade is to the PAGE, so it takes the shell's mode rather than resolving
  # one of its own — a light scrim over a dark page is a 120pt pale band across
  # the bottom of the screen, which is the loudest possible way to get this
  # wrong and the easiest to leave in by threading nothing.
  defp scrim(mode) do
    ~MOB"""
    <Box fill_width={true} fill_height={true} align="bottom">
      {Kati.UI.paper_fade(120, 4, mode)}
    </Box>
    """
  end

  # The bar and the FAB are ONE row, not a bar with something floating over it.
  #
  # Screen 01: `padding:0 18px 30px; display:flex; align-items:center; gap:11px`,
  # a `flex:1` bar 64 tall with radius 32, then a 64x64 circle beside it. Drawn
  # as a separate overlay pinned above the bar — which is what this did first —
  # the FAB lands in the wrong place at every width, because in the design it is
  # not above the bar, it is the last item in the row.
  # The bar's contents are centred BOTH ways, and the vertical half is not
  # optional: a Box defaults to top alignment, and the icon row wraps to its
  # 46dp content inside a 64dp bar — so without `align="center"` the icons ride
  # 9dp high and the active disc very nearly clips the bar's top edge. It looks
  # exactly like "the icons are not centred", and no horizontal measurement
  # catches it, which is how it survived a round of measuring.
  #
  # The bar carries NO inner padding, despite the drawing's `padding:0 9px`.
  #
  # Measured against the reference: with 9dp each side the four icon centres
  # land at 14.9 / 38.4 / 61.8 / 85.4% of the bar, compressed inward, because
  # the padding is subtracted before the four weighted slots are distributed.
  # Without it they sit at 12.5 / 37.5 / 62.5 / 87.5%, which is what the
  # drawing shows. CSS `space-around` distributes within the content box and
  # then the browser's own optical rounding differs; the number that matters
  # is where the icons end up, and this is the version that matches.
  defp dock(active, mode) do
    # `Palette.fab_fill/1`, not `Kati.Theme.ink/0`. Both are `0xFF1A1917` in
    # light — the FAB is an ink disc on paper — but in dark the design inverts
    # the control rather than following the ground: `#F5F2EE` fill with a
    # `#16150F` plus, drawn on screen 28. `Kati.Theme.ink/0` takes no mode and
    # would have left an ink-on-ink disc that renders as a hole with nothing in
    # it.
    fab = Palette.fab_fill(mode)
    glyph = Palette.fab_glyph(mode)

    # `chrome_fill/1` already takes a mode, and there is no palette token for it
    # — the dock's .97 is `Kati.Theme`'s own recorded compromise for the blur
    # Mob cannot do, and `Palette.dock_fill/1`'s light value is the drawing's
    # .90, a different number. Using the palette here would have changed light.
    fill = Kati.Theme.chrome_fill(mode)
    add = {self(), :fab}

    ~MOB"""
    <Box fill_width={true} fill_height={true} align="bottom">
      <Row fill_width={true} align="center" padding_left={18} padding_right={18} padding_bottom={30}>
        <Box weight={1.0} height={64} background={fill} corner_radius={32} align="center">
          <Row fill_width={true} fill_height={true} align="center">
            {Enum.map(Kati.Shell.roots(), fn root -> Kati.Shell.tab(root, active, mode) end)}
          </Row>
        </Box>
        <Spacer size={11} />
        <Box width={64} height={64} background={fab} corner_radius={32} align="center" on_tap={add}>
          {Kati.UI.symbol("add", size: 27, color: glyph)}
        </Box>
      </Row>
    </Box>
    """
  end

  @doc false
  def tab(root, active, mode) do
    on? = root.id == active
    # Inactive icons are #B3ACA2; the active one is ink inside an #EFECE7 disc —
    # the paper colour, so the disc reads as a hole punched in the bar rather
    # than a highlight. Orange means new/now and never appears here.
    #
    # The disc is `Palette.tab_well/1`, NOT `Kati.Theme.paper/1`. Both are
    # `0xFFEFECE7` in light, so nothing moves there — but the two disagree in
    # dark on purpose. The bar is `#1E1D1B`, which is LIGHTER than the page, so
    # a well painted at the page's `#121110` is not dark enough to read as a
    # hole; screen 28 draws `#0E0D0C`, darker than the page, and that is the
    # token. `Kati.Screens.HomeDark` says the same thing in its own comment.
    tint = if on?, do: Palette.ink(mode), else: Palette.tertiary(mode)
    disc = if on?, do: Palette.tab_well(mode), else: Palette.transparent(mode)
    tap = {self(), String.to_atom("root_#{root.id}")}

    # weight 1 per item is space-around: four equal segments, content centred.
    # No labels — screen 01's bar is icons only.
    ~MOB"""
    <Box weight={1.0} align="center" on_tap={tap}>
      <Box width={46} height={46} background={disc} corner_radius={23} align="center">
        {Kati.UI.symbol(root.icon, size: 22, color: tint, fill: on?)}
      </Box>
    </Box>
    """
  end
end
