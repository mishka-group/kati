defmodule Kati.Screens.States do
  @moduledoc """
  Screen 27 — States, a reference sheet pushed under Settings.

  Built to `.scratch/design/screens/27.html`: the four states nobody designs,
  drawn once so every other screen can quote them. Empty invites rather than
  apologises; loading is a skeleton and never a spinner; offline promises the
  ticks are safe; and every destructive action leaves an undo bar behind.

  Two eyebrows carry the grey dash instead of the orange one — Offline and
  Undo are consequences of something going wrong, not things that are new or
  happening now, and orange means new/now.

  ## Two things the drawing does that the bridge cannot

    * **Opacity.** The skeleton rows fade to 1, .75 and .5. No node carries an
      opacity prop, so `Kati.Settings.StatesSample.skeletons/0` composites each
      row's colours against paper and scales its shadow alphas to match.
    * **A horizontal shimmer.** The design fills each skeleton bar with
      `linear-gradient(90deg, #E7E3DC, #F1EEE9, #E7E3DC)`. The bridge's
      gradient parser is vertical only — `to_top` or `to_bottom` — so the bars
      are the flat `#E7E3DC` the gradient starts and ends on.

  No dock — pushed screen — so the frame closes at 40, not 132.
  """
  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.Settings.StatesSample, as: Sample
  alias Kati.UI
  alias Kati.UI.SettingsList

  @impl true
  def load(socket) do
    Mob.Socket.assign(socket, :states, %{
      empty: Sample.empty(),
      skeletons: Sample.skeletons(),
      offline: Sample.offline(),
      error: Sample.error(),
      undo: Sample.undo()
    })
  end

  @doc false
  def content(assigns) do
    s = assigns.states

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {SettingsList.chrome("more_horiz")}
        {SettingsList.title("States", "reference sheet")}
        {UI.eyebrow("Empty — nothing added yet")}
        {Kati.Screens.States.empty(s.empty)}
        {UI.eyebrow("Loading — skeleton, never a spinner")}
        {Kati.Screens.States.skeletons(s.skeletons)}
        {SettingsList.eyebrow_muted("Offline — the library still works")}
        {Kati.Screens.States.offline(s.offline)}
        {Kati.Screens.States.error(s.error)}
        {SettingsList.eyebrow_muted("Undo — every destructive action")}
        {Kati.Screens.States.undo(s.undo)}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def empty(e) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={0xFFFBFAF8}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={22}
        padding_right={22}
        padding_top={30}
        padding_bottom={30}
      >
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          <Box width={64} height={64} corner_radius={20} background={0xFFEFECE7} align="center">
            {Kati.UI.symbol(e.icon, size: 28, color: 0xFFC4BDB3)}
          </Box>
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={18} />
        <Text
          text={e.title}
          text_size={17}
          font_weight="bold"
          letter_spacing={-0.02}
          text_color={:on_surface}
          text_align="center"
        />
        <Spacer size={8} />
        <Text
          text={e.body}
          text_size={13}
          line_height={1.55}
          text_color={0xFF8A8479}
          text_align="center"
        />
        <Spacer size={18} />
        <Row
          fill_width={true}
          height={44}
          corner_radius={22}
          background={Kati.Theme.ink()}
          align="center"
        >
          <Spacer weight={1.0} />
          {Kati.UI.symbol("add", size: 18, color: 0xFFFBFAF8)}
          <Spacer size={7} />
          <Text
            text={e.action}
            text_size={13}
            font_weight="bold"
            text_color={0xFFFBFAF8}
            max_lines={1}
          />
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={14} />
        <Text
          text={e.secondary}
          text_size={12.5}
          font_weight="semibold"
          text_color={0xFF8A8479}
          text_align="center"
        />
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def skeletons(rows) do
    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(rows, fn row -> Kati.Screens.States.skeleton(row) end)}
      <Spacer size={15} />
    </Column>
    """
  end

  # 11pt above and below, 13 each side, and a 9pt gap to the next — so the row
  # carries its own trailing spacer rather than the list interspersing one.
  @doc false
  def skeleton(row) do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={row.card}
        corner_radius={18}
        shadow={row.shadow}
        padding_left={13}
        padding_right={13}
        padding_top={11}
        padding_bottom={11}
        align="center"
      >
        <Box width={40} height={56} corner_radius={8} background={row.bar} />
        <Spacer size={12} />
        <Column weight={1.0}>
          <Box fill_width={true} height={11} corner_radius={6} background={row.bar} />
          <Spacer size={8} />
          <Row fill_width={true}>
            <Box weight={0.52} height={9} corner_radius={6} background={row.bar} />
            <Spacer weight={0.48} />
          </Row>
        </Column>
      </Row>
      <Spacer size={9} />
    </Column>
    """
  end

  # Cream, and flat. The offline badge is the one card on this sheet with no
  # shadow in the drawing: it is a condition the app is in, not an object
  # lifted off the paper.
  @doc false
  def offline(o) do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={0xFFFBF1DE}
        corner_radius={18}
        padding_left={16}
        padding_right={16}
        padding_top={14}
        padding_bottom={14}
        align="center"
      >
        {Kati.UI.symbol(o.icon, size: 20, color: 0xFFC98A3E)}
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text
            text={o.title}
            text_size={13}
            font_weight="bold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={3} />
          <Text text={o.sub} text_size={11.5} text_color={0xFF8A7B60} max_lines={1} />
        </Column>
      </Row>
      <Spacer size={12} />
    </Column>
    """
  end

  @doc false
  def error(e) do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={0xFFFBFAF8}
        corner_radius={18}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={16}
        padding_right={16}
        padding_top={14}
        padding_bottom={14}
        align="center"
      >
        {Kati.UI.symbol(e.icon, size: 20, color: Kati.Theme.red())}
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text
            text={e.title}
            text_size={13}
            font_weight="bold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={3} />
          <Text text={e.sub} text_size={11.5} text_color={0xFF8A8479} max_lines={1} />
        </Column>
        <Spacer size={12} />
        {SettingsList.action_pill(e.action)}
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def undo(u) do
    ~MOB"""
    <Row
      fill_width={true}
      background={Kati.Theme.ink()}
      corner_radius={20}
      padding_left={16}
      padding_right={16}
      padding_top={13}
      padding_bottom={13}
      align="center"
    >
      {Kati.UI.symbol(u.icon, size: 19, color: 0xFFFBFAF8)}
      <Spacer size={12} />
      <Text
        text={u.text}
        text_size={13}
        font_weight="semibold"
        text_color={0xFFFBFAF8}
        weight={1.0}
        max_lines={1}
      />
      <Spacer size={12} />
      <Text
        text={u.action}
        text_size={12.5}
        font_weight="bold"
        text_color={0xFFE8823C}
        max_lines={1}
      />
    </Row>
    """
  end
end
