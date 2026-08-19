defmodule Kati.Screens.Fa do
  @moduledoc """
  Shared chrome and type rules for the Persian mirrors, screens 55–62.

  ## Why these screens carry their own frame

  `Kati.Shell` reads the direction from `Kati.Locale`, and the bridge takes
  `layout_direction` from the **root node only** (`MainActivity.kt:245`). A
  Persian mirror rendered through the shell while the app is still set to
  English would draw Persian copy in a left-to-right grid — the one thing
  these eight drawings exist to disprove. So the frame here hard-codes `rtl`:
  the screen *is* the Persian one, whatever the setting says.

  Everything else about the dock is `Kati.Shell`'s dock, number for number.
  It mirrors for free — a `Row` lays out start-to-end, so the bar lands at the
  right, the FAB at the left, and home is the rightmost tab, which is exactly
  what 55, 56 and 57 draw. Nothing here reverses a list by hand.

  ## Two type rules, both forced by the fonts that ship

    * **Every Persian string needs `font_family="fa"`.** Plus Jakarta Sans —
      the default for an unstyled `Text` — has no Arabic-script glyphs at all
      (checked: `kati_sans_400.ttf` carries none of U+0600–U+06FF), so a
      Persian label without the prop is a row of empty boxes, not a fallback.

    * **Persian digits cannot go in the mono face.** The drawings ask for DM
      Mono on times, day numbers and episode numbers, and 58's own caption
      says the episode column "stays in the mono face with Persian digits".
      `kati_mono.ttf` contains **zero** of U+06F0–U+06F9; Vazirmatn carries
      all ten. So anything numeric that the design sets in mono is set here in
      `fa` at the design's size and colour. The face is wrong and the glyphs
      are right, which is the better half of an unwinnable trade — and it goes
      away the day the mono subset is regenerated with the Persian digits in
      it.

  The eyebrow is the same case one level up: the design's Latin eyebrow is DM
  Mono 10.5 at .16em, and the Persian one is **Vazirmatn 11 / 600 / no
  tracking** in all four drawings. `eyebrow/1` here is that recipe, not
  `Kati.UI.eyebrow/2` with a translated label.
  """

  import Mob.Sigil

  # The four roots, in the order the bar draws them. `Kati.Screens.Stats` is
  # the English root standing in for drawing 61 (آمار) until it is built: a
  # tab that does nothing reads as a broken bar, and this at least arrives
  # somewhere. Swap the module when 61 lands; nothing else changes.
  @roots [
    %{id: :home, icon: "home", screen: Kati.Screens.HomeFa},
    %{id: :calendar, icon: "calendar_month", screen: Kati.Screens.ScheduleFa},
    %{id: :library, icon: "grid_view", screen: Kati.Screens.LibraryFa},
    %{id: :stats, icon: "bar_chart_4_bars", screen: Kati.Screens.Stats}
  ]

  @doc "The four roots of the Persian shell."
  def roots, do: @roots

  @doc """
  The Persian root frame: content, the 120pt fade, then the dock — all inside
  a root `Box` that declares `rtl`.
  """
  def frame(active, content) do
    ~MOB"""
    <Box fill_width={true} fill_height={true} background={:background} layout_direction="rtl">
      {content}
      <Box fill_width={true} fill_height={true} align="bottom">
        {Kati.UI.paper_fade(120)}
      </Box>
      {Kati.Screens.Fa.dock(active)}
    </Box>
    """
  end

  @doc """
  The pushed Persian frame: no dock, no fade, just the direction.

  A pushed mirror draws its own dismissal — 58 floats a back pill over its
  artwork — so unlike `Kati.Screens.Pushed` this adds nothing but the root
  node.
  """
  def pushed_frame(content) do
    ~MOB"""
    <Box fill_width={true} fill_height={true} background={:background} layout_direction="rtl">
      {content}
    </Box>
    """
  end

  @doc false
  def dock(active) do
    add = {self(), :fab}

    ~MOB"""
    <Box fill_width={true} fill_height={true} align="bottom">
      <Row fill_width={true} align="center" padding_left={18} padding_right={18} padding_bottom={30}>
        <Box weight={1.0} height={64} background={0xE6FBFAF8} corner_radius={32} align="center">
          <Row fill_width={true} fill_height={true} align="center">
            {Enum.map(Kati.Screens.Fa.roots(), fn root -> Kati.Screens.Fa.tab(root, active) end)}
          </Row>
        </Box>
        <Spacer size={11} />
        <Box width={64} height={64} background={0xFF1A1917} corner_radius={32} align="center" on_tap={add}>
          {Kati.UI.symbol("add", size: 27, color: 0xFFFBFAF8)}
        </Box>
      </Row>
    </Box>
    """
  end

  @doc false
  def tab(root, active) do
    on? = root.id == active
    tint = if on?, do: 0xFF1A1917, else: 0xFFB3ACA2
    disc = if on?, do: 0xFFEFECE7, else: 0x00FFFFFF
    tap = {self(), String.to_atom("root_#{root.id}")}

    ~MOB"""
    <Box weight={1.0} align="center" on_tap={tap}>
      <Box width={46} height={46} background={disc} corner_radius={23} align="center">
        {Kati.UI.symbol(root.icon, size: 22, color: tint, fill: on?)}
      </Box>
    </Box>
    """
  end

  @doc """
  A section label in Persian: the same 13x2 accent dash, then Vazirmatn 11 at
  600 in `#A0998F`. No uppercasing — the Arabic script has no case — and no
  tracking, which the drawings set to 0 on every Persian line.
  """
  def eyebrow(label) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        <Box width={13} height={2} corner_radius={1} background={0xFFE8823C} />
        <Spacer size={9} />
        <Text text={label} font_family="fa" font_weight="semibold" text_size={11} text_color={0xFFA0998F} />
      </Row>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc "A 44pt header disc: card white, the button shadow, a 21pt symbol."
  def disc(icon, tag) do
    tap = {self(), tag}

    ~MOB"""
    <Box
      width={44}
      height={44}
      background={0xFFFBFAF8}
      corner_radius={22}
      shadow={Kati.Theme.shadow_button()}
      align="center"
      on_tap={tap}
    >
      {Kati.UI.symbol(icon, size: 21)}
    </Box>
    """
  end

  @doc """
  The dock's taps, for any Persian root.

  A screen matches its own tags first and sends the rest here, so the four
  tabs and the FAB are written once. Anything unrecognised leaves the screen
  as it was rather than raising in a tap handler, which Mob does not catch.
  """
  def dock_tap(:fab, _active, socket) do
    {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.AddTitle)}
  end

  def dock_tap(tag, active, socket) when is_atom(tag) do
    case Atom.to_string(tag) do
      "root_" <> id ->
        target = Enum.find(@roots, &(Atom.to_string(&1.id) == id))

        cond do
          target == nil -> {:noreply, socket}
          target.id == active -> {:noreply, socket}
          true -> {:noreply, Mob.Socket.reset_to(socket, target.screen)}
        end

      _ ->
        {:noreply, socket}
    end
  end

  def dock_tap(_tag, _active, socket), do: {:noreply, socket}
end
