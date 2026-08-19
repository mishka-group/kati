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
  """
  def render(assigns) do
    active = assigns.root
    mode = Map.get(assigns, :mode, :light)

    direction = Kati.Locale.direction_prop()

    ~MOB"""
    <Box fill_width={true} fill_height={true} background={:background} layout_direction={direction}>
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
  defp scrim(mode) do
    fill = Kati.Theme.paper(mode)

    ~MOB"""
    <Box fill_width={true} fill_height={true} align="bottom">
      <Box fill_width={true} height={112} background={fill} />
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
    ink = Kati.Theme.ink()
    fill = Kati.Theme.chrome_fill(mode)
    add = {self(), :fab}

    ~MOB"""
    <Box fill_width={true} fill_height={true} align="bottom">
      <Row
        fill_width={true}
        vertical_align="center"
        padding_left={18}
        padding_right={18}
        padding_bottom={30}
      >
        <Box weight={1.0} height={64} background={fill} corner_radius={32}>
          <Row fill_width={true} vertical_align="center">
            {Enum.map(Kati.Shell.roots(), fn root -> Kati.Shell.tab(root, active, mode) end)}
          </Row>
        </Box>
        <Spacer size={11} />
        <Box width={64} height={64} background={ink} corner_radius={32} align="center" on_tap={add}>
          {Kati.UI.symbol("add", size: 27, color: 0xFFFBFAF8)}
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
    tint = if on?, do: Kati.Theme.ink(), else: 0xFFB3ACA2
    disc = if on?, do: Kati.Theme.paper(mode), else: 0x00FFFFFF
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
