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

  @roots [
    %{id: :home, label: "Home", icon: "home", screen: Kati.Screens.Home},
    %{id: :calendar, label: "Calendar", icon: "calendar", screen: Kati.Screens.Calendar},
    %{id: :library, label: "Library", icon: "library", screen: Kati.Screens.Library},
    %{id: :stats, label: "Stats", icon: "stats", screen: Kati.Screens.Stats}
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
      {pill(active, mode)}
      {fab()}
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

  defp pill(active, mode) do
    fill = Kati.Theme.chrome_fill(mode)

    ~MOB"""
    <Box fill_width={true} fill_height={true} align="bottom">
      <Column padding_bottom={30}>
        <Row background={fill} corner_radius={32} padding={7} align="center">
          {Enum.map(Kati.Shell.roots(), fn root -> Kati.Shell.tab(root, active, mode) end)}
        </Row>
      </Column>
    </Box>
    """
  end

  @doc false
  def tab(root, active, mode) do
    on? = root.id == active
    # Orange only ever means new/now, so an active tab is INK, never accent.
    tint = if on?, do: Kati.Theme.ink(), else: 0xFF9A948B
    bg = if on?, do: Kati.Theme.cream(mode), else: 0x00FFFFFF
    tap = {self(), String.to_atom("root_#{root.id}")}

    ~MOB"""
    <Box width={74} height={52} background={bg} corner_radius={22} align="center" on_tap={tap}>
      <Column align="center">
        <Icon name={root.icon} text_size={22} text_color={tint} text={root.label} />
        <Spacer size={3} />
        <Text text={root.label} text_size={10} text_color={tint} />
      </Column>
    </Box>
    """
  end

  # 64x64, detached, sitting above the pill on the trailing edge.
  defp fab do
    ink = Kati.Theme.ink()
    tap = {self(), :fab}

    ~MOB"""
    <Box fill_width={true} fill_height={true} align="bottom_trailing">
      <Column padding_bottom={104} padding_right={21}>
        <Box width={64} height={64} background={ink} corner_radius={32} align="center" on_tap={tap}>
          <Icon name="plus" text_size={26} text_color={0xFFFBFAF8} text="Add" />
        </Box>
      </Column>
    </Box>
    """
  end
end
