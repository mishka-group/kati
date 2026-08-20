defmodule Kati.Screens.ReleaseWatcher do
  @moduledoc """
  Screen 25 — the release watcher's settings, pushed under Settings.

  Built to `.scratch/design/screens/25.html`. Three questions in order: what to
  look for, how often to look, and how loudly to say so. The last group is the
  one that matters — push is off, the inbox badge is on, and the dashed
  footnote says why rather than leaving it to be discovered.

  The cream banner is the same card screen 05 puts at the top of the inbox, so
  the thing the watcher does and the thing you configure look like one object
  seen from two sides.

  Every control on the screen is live and every one of them edits the single
  `:watcher` assign: the banner is the master switch, each row of the two
  groups flips its own, and the cadence segments move the selection. The screen
  still opens on `Kati.Settings.WatcherSample`'s own defaults, which are the
  drawing's state — the resting frame is unchanged.

  No dock — pushed screen — so the frame closes at 40, not 132.
  """
  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.Settings.WatcherSample, as: Sample
  alias Kati.UI
  alias Kati.UI.SettingsList

  @impl true
  def load(socket) do
    Mob.Socket.assign(socket, :watcher, %{
      checked: Sample.checked(),
      banner: Sample.banner(),
      kinds: Sample.kinds(),
      cadences: Sample.cadences(),
      cadence: Sample.cadence(),
      loudness: Sample.loudness(),
      note: Sample.note()
    })
  end

  @doc false
  def content(assigns) do
    w = assigns.watcher

    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={40}>
        {SettingsList.chrome("more_horiz")}
        {SettingsList.title("Release watcher", w.checked)}
        {Kati.Screens.ReleaseWatcher.banner(w.banner)}
        {UI.eyebrow("Tell me about")}
        {Kati.Screens.ReleaseWatcher.group(w.kinds, "kind", 13, 22)}
        {UI.eyebrow("How often")}
        {Kati.Screens.ReleaseWatcher.cadence(w)}
        {UI.eyebrow("How loudly")}
        {Kati.Screens.ReleaseWatcher.group(w.loudness, "loud", 14, 22)}
        {SettingsList.note("info", w.note)}
      </Column>
    </Scroll>
    """
  end

  # The whole banner is the master switch's hit target, the way `SettingsList.row`
  # makes a whole settings row one — the switch alone is 46pt wide and this card
  # is the same object screen 05 puts at the top of the inbox.
  @doc false
  def banner(b) do
    tap = {self(), :banner}

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={0xFFFBF1DE}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={18}
        align="center"
        on_tap={tap}
      >
        {Kati.UI.symbol("auto_awesome", size: 24, color: 0xFFC98A3E)}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text text={b.title} text_size={14.5} font_weight="bold" text_color={:on_surface} max_lines={1} />
          <Spacer size={4} />
          <Text text={b.meta} font_family="mono" text_size={10.5} text_color={0xFFB09A72} max_lines={1} />
        </Column>
        <Spacer size={13} />
        {SettingsList.switch(b.on)}
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  # `key` names which list in `:watcher` the group is drawing, so the row tags
  # are `kind_2` / `loud_0` and one handler clause serves a group of any length.
  @doc false
  def group(rows, key, pad, gap) do
    last = length(rows) - 1

    body =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, i} -> Kati.Screens.ReleaseWatcher.row(row, key, i, pad, i < last) end)

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(body)}
      <Spacer size={gap} />
    </Column>
    """
  end

  # The tap is the whole row, not the switch: `SettingsList.row/4` hangs it off
  # the row's own Column, and a 46pt track is a poor target for a screen that is
  # ten switches tall. The tag carries the position rather than the title so the
  # two groups cannot collide on a shared name.
  @doc false
  def row(row, key, i, pad, rule?) do
    tap = {self(), String.to_atom(key <> "_" <> Integer.to_string(i))}

    SettingsList.row(
      SettingsList.icon_tile(row.icon),
      SettingsList.body(row.title, row.sub),
      SettingsList.switch(row.on),
      padding: pad,
      rule: rule?,
      on_tap: tap
    )
  end

  # Four segments on an #E4E0D9 trough, each taking a weight so they divide the
  # frame evenly — screen 03's control is the same object at a different width.
  @doc false
  def cadence(w) do
    tiles =
      w.cadences
      |> Enum.map(fn c -> Kati.Screens.ReleaseWatcher.segment(c, c == w.cadence) end)
      |> Enum.intersperse(Kati.Screens.ReleaseWatcher.segment_gap())

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} background={0xFFE4E0D9} corner_radius={16} padding={4} align="center">
        {tiles}
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def segment_gap, do: ~MOB"<Spacer size={4} />"

  @doc false
  def segment(label, on?) do
    # The tag carries the cadence, so a fifth interval is a change to
    # `WatcherSample.cadences/0` and nothing else.
    tap = {self(), String.to_atom("cadence_" <> label)}
    bg = if on?, do: 0xFFFBFAF8, else: 0x00FFFFFF
    fg = if on?, do: Kati.Theme.ink(), else: 0xFFAFA89E
    weight = if on?, do: "bold", else: "semibold"
    shadow = if on?, do: "0 1 2 0 #0F1A1917", else: "0 0 0 0 #00000000"

    ~MOB"""
    <Box weight={1.0}>
      <Row fill_width={true} height={34} corner_radius={12} background={bg} shadow={shadow} align="center" on_tap={tap}>
        <Spacer weight={1.0} />
        <Text text={label} text_size={12} font_weight={weight} text_color={fg} max_lines={1} />
        <Spacer weight={1.0} />
      </Row>
    </Box>
    """
  end

  @doc """
  Flip the `on` flag of one row of a group.

  A list rather than a map keyed by title: the drawing's order is the screen's
  order, and the index is what the tag carries.
  """
  @spec flip([map()], String.t()) :: [map()]
  def flip(rows, index) do
    List.update_at(rows, String.to_integer(index), fn row -> %{row | on: not row.on} end)
  end

  # Every control on this screen edits the one `:watcher` map, so there is a
  # clause per kind of control rather than per row.
  @impl true
  def handle_tap(tag, socket) do
    w = socket.assigns.watcher

    case Atom.to_string(tag) do
      "banner" ->
        {:noreply, Mob.Socket.assign(socket, :watcher, %{w | banner: %{w.banner | on: not w.banner.on}})}

      "kind_" <> i ->
        {:noreply, Mob.Socket.assign(socket, :watcher, %{w | kinds: Kati.Screens.ReleaseWatcher.flip(w.kinds, i)})}

      "loud_" <> i ->
        {:noreply, Mob.Socket.assign(socket, :watcher, %{w | loudness: Kati.Screens.ReleaseWatcher.flip(w.loudness, i)})}

      "cadence_" <> label ->
        {:noreply, Mob.Socket.assign(socket, :watcher, %{w | cadence: label})}

      _ ->
        {:noreply, socket}
    end
  end
end
