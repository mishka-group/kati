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

  ## Nothing on this sheet is domain data, and that was checked rather than assumed

  Every other screen in this round moved onto `Kati.Media`, `Kati.Calendars` or
  `Kati.Meals`. This one has nothing to move, and the reason is structural
  rather than a gap in the domains: **a reference sheet draws all five states at
  once, unconditionally.** Each card is a picture of a state, not a report that
  the app is in it, so a value read from a resource would be a true number
  attached to an event that never happened.

  Four lines look like data. None of them is:

    * **`Last success 6h ago`** is the one that could be read.
      `Kati.Calendars.Account.last_sync_at` holds exactly that instant and
      `Kati.Sync.Engine` writes it **only on success**, so the figure exists and
      is trustworthy. It is still not read here, because the card above it —
      *Couldn't check for releases* — is drawn whether or not a check failed.
      Dating a real last success against an invented failure is worse than the
      drawing: it reads as a live incident report and is not one.
    * **`Dropped The Quiet Ones`** names a title nothing dropped.
      `Kati.Media.TrackedTitle.status` can be `:dropped`, and nothing anywhere
      records **when** a status changed — no tombstone, no audit row, no undo
      window. So there is no most-recent destructive action to name, and none
      that tapping `Undo` could take back.
    * **`Offline`** is a condition of the device. No resource stores it, and the
      badge is drawn on this sheet whether the radio is on or off.
    * **`No titles yet`** is the empty state, drawn here beside a full library on
      purpose. Gating it on `Kati.Media.TrackedTitle` being empty would show
      five states on a fresh install and four on every other device, which is
      the opposite of what a reference sheet is for.

  So this screen reads no store and has no fallback to keep: its Sample module
  is the specimen itself rather than a stand-in for data that has not arrived,
  which is why `Kati.Settings.StatesSample` says *the "sample" here is the
  specimen itself* in its own first paragraph. The one thing that would change
  this is a **live** states screen — the app showing its own current condition —
  and that is a different screen from the sheet the design draws.
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
      undo: Sample.undo(),
      retired: Sample.retired()
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
        <Spacer size={26} />
        {SettingsList.eyebrow_muted("Not in this version — drawn, not built")}
        {Kati.Screens.States.retired(s.retired)}
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

  @doc """
  The sixth band, and the one that is about a screen rather than about a state.

  Five bands above say what a screen does while it waits, fails or undoes. This
  one says what a screen does when it is **drawn and not built** — the ritual
  #22 named as missing. The rule is in words and then in a tile, because the
  words are what another screen has to follow and the tile is what a reader
  recognises.

  The tile is pressable and lands on `Kati.Screens.RetiredTile`, which is the
  half of the treatment a static picture cannot show: the answer to *what does
  tapping it do*. It is drawn here rather than borrowed from
  `Kati.Screens.Health.tile/1` on purpose — that builder reads a live section
  list, and a reference sheet that reported today's sections would stop being a
  reference the day one of them turned on.
  """
  @spec retired(map()) :: map()
  def retired(r) do
    ~MOB"""
    <Column
      fill_width={true}
      background={0xFFFBFAF8}
      corner_radius={22}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={22}
    >
      <Text
        text={r.title}
        text_size={15}
        font_weight="bold"
        letter_spacing={-0.01}
        text_color={:on_surface}
      />
      <Spacer size={8} />
      <Text text={r.body} text_size={13} line_height={1.6} text_color={0xFF8A8479} max_lines={6} />
      <Spacer size={16} />
      {Kati.Screens.States.dashed_tile(r.example)}
    </Column>
    """
  end

  @doc """
  One dashed tile, in screen 42's geometry, carrying the tap that is the point.

  `border_width` and `border_color` rather than a fill: a tile that is drawn
  and not built has an outline where the others have a surface, which is the
  whole of how the grid says it without a word.
  """
  @spec dashed_tile(map()) :: map()
  def dashed_tile(example) do
    ~MOB"""
    <Column
      fill_width={true}
      corner_radius={20}
      border_width={1.5}
      border_color={Kati.Theme.Palette.border_soft()}
      padding={16}
      on_tap={{self(), :open_retired}}
    >
      <Row fill_width={true} align="center">
        {Kati.UI.symbol(example.icon, size: 22, color: Kati.Theme.Palette.tertiary())}
        <Spacer size={10} />
        <Text
          text={example.name}
          text_size={14}
          font_weight="semibold"
          text_color={Kati.Theme.Palette.tertiary()}
          weight={1.0}
          max_lines={1}
        />
        <Text
          text={example.status}
          text_size={11.5}
          text_color={Kati.Theme.Palette.tertiary()}
          max_lines={1}
        />
      </Row>
    </Column>
    """
  end

  # The tap the band exists to demonstrate. Pushed with the section the example
  # tile names, so the sheet that opens is the one screen 42 would have opened.
  @impl true
  def handle_tap(:open_retired, socket) do
    {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.RetiredTile, %{section: "Sleep"})}
  end
end
