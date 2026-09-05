defmodule Kati.Screens.MedicationEmpty do
  @moduledoc """
  Screen 190 — Medication, empty and annotated.

  Built to `test/design/screens/190.html`. Board 190 is the D-43 edit to
  screen 112 drawn as its own artboard: **the empty frame nobody had ever
  drawn**, plus the two destinations named, the reminder caption, and the
  failure line `Kati.Screens.Medication.save_notice/1` renders and no board
  showed. It is screen 27's kind of sheet — a picture of situations rather
  than a situation the app can be in — which is why it is on
  `Kati.AppReachabilityTest`'s `@no_route` beside every other states board.

  ## The empty frame is the point

  `D-19-medication.md` asked for it in 2026 and nothing drew it, so screen
  112 has printed four tablets belonging to nobody on every fresh install and
  `Kati.ScreenEmptyDatabaseTest` has held it to its own fixture. Screen 139's
  house recipe — *glyph tile, sentence, one ink action, one quiet
  alternative* — with the medication noun, and its own subtitle literal:
  `SUNDAY 16 AUGUST · NO DOSES`, because `Kati.Health.WeightSample.doses_subtitle/0`
  says `4 DOSES` and an empty page cannot print that.

  **Screen 112 itself still falls back**, and that is deliberately not changed
  here: moving it off `Kati.ScreenEmptyDatabaseTest`'s `fallbacks/0` is a
  change to the gate a live page answers to, and this commit's job was to draw
  the frame that change will be compared against. The board now exists; the
  swap is one edit away and is not this one.

  ## Both destinations are live, on this board too

  The header `add` disc and the empty card's ink pill both open
  `Kati.Screens.AddMedication`, with distinct tags because `Mob.Renderer`
  emits an `accessibility_id` from every atom tag and two controls sharing one
  is a node `onNodeWithTag` throws on. *or restore a backup* pushes
  `Kati.Screens.Restore`, which is `Kati.Screens.HomeEmpty.restore_link/0`'s
  own decision and true for the same reason: restore is the only writer of
  `health_medications` that existed before screen 188.

  ## The reminder caption counts clock times, not medications

  `SET ON EACH MEDICATION · 3 OF 4 CLOCK TIMES ARMED`, and the count is the
  one the board argues for: two tablets sharing 08:00 is **one** notification,
  because `Kati.Notifications.Sources.Health` aggregates by clock time. A
  page-level switch is deliberately absent — the switch is screen 189's, one
  per medication, and a fifth control able to disagree with four is what the
  caption exists instead of.
  """

  use Kati.Screens.Pushed, back: "Health"

  alias Kati.Components.MishkaThemeIcon
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @doc """
  The subtitle an empty medication page prints.

  Not `Kati.Health.WeightSample.doses_subtitle/0`, which is the fixture's
  `SUNDAY 16 AUGUST · 4 DOSES`: a page with nothing stored cannot count four
  doses, and a sweep cannot check a string nobody drew.
  """
  @spec subtitle() :: String.t()
  def subtitle, do: "SUNDAY 16 AUGUST · NO DOSES"

  @doc false
  def content(_assigns) do
    Kati.Screens.Pushed.page(
      ~MOB"""
      <Column fill_width={true}>
        {Kati.Screens.Goals.chrome()}
        {Kati.Screens.MedicationDetail.heading("Medication", Kati.Screens.MedicationEmpty.subtitle())}
        {Kati.Screens.MedicationEmpty.empty_card()}
        {Kati.Screens.MedicationEmpty.subtitle_note()}
        {Kati.UI.eyebrow("The two destinations, named")}
        {Kati.Screens.MedicationEmpty.destinations()}
        {Kati.Screens.MedicationEmpty.destinations_note()}
        {Kati.UI.Eyebrow.quiet("The reminder caption")}
        {Kati.Screens.MedicationEmpty.reminder_caption()}
        {Kati.Screens.MedicationEmpty.caption_note()}
        {Kati.UI.Eyebrow.quiet("The failure line, where it renders")}
        {Kati.Screens.MedicationEmpty.failure_line()}
      </Column>
      """,
      # 64, not `content_top/0`: this page opens with screen 104's chrome row
      # exactly as screen 112 does, and 112 has always started at the board's
      # own 64 with the floating pill overlapping the right-aligned disc's
      # empty half. A board that is a redraw of 112 starts where 112 starts.
      64
    )
  end

  @doc "Screen 139's recipe with the medication noun: tile, sentence, one ink action, one quiet alternative."
  @spec empty_card() :: map()
  def empty_card do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={17}
        align="center"
      >
        <Spacer size={12} />
        {Kati.Screens.MedicationEmpty.tile()}
        <Spacer size={16} />
        <Text
          text="No medications yet"
          text_size={16}
          font_weight="bold"
          letter_spacing={-0.02}
          text_align="center"
          text_color={:on_surface}
        />
        <Spacer size={8} />
        <Text
          text="Add one and its doses appear here each day, in clock order."
          text_size={12.5}
          line_height={1.55}
          text_align="center"
          text_color={Palette.sub()}
        />
        <Spacer size={18} />
        {Kati.Screens.MedicationEmpty.add_pill()}
        <Spacer size={15} />
        {Kati.Screens.MedicationEmpty.restore_link()}
        <Spacer size={12} />
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc "The 60pt paper square, at `Kati.Screens.HomeEmpty.tile/0`'s own recipe."
  @spec tile() :: map()
  def tile do
    MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Palette.paper(), size: 60, radius: 19},
      [UI.symbol("medication", size: 27, color: Palette.rail_idle())]
    )
  end

  @doc "The one ink action on the board. `:add_first`, so it does not share the header disc's name."
  @spec add_pill() :: map()
  def add_pill do
    ~MOB"""
    <Box
      fill_width={true}
      height={44}
      corner_radius={22}
      background={Palette.ink_fill()}
      align="center"
      on_tap={{self(), :add_first}}
    >
      <Text
        text="Add a medication"
        text_size={13}
        font_weight="bold"
        text_color={Palette.on_ink()}
        max_lines={1}
      />
    </Box>
    """
  end

  @doc "The quiet alternative, wired the way `Kati.Screens.HomeEmpty.restore_link/0` is."
  @spec restore_link() :: map()
  def restore_link do
    ~MOB"""
    <Column fill_width={true} on_tap={{self(), :restore_backup}}>
      <Text
        text="or restore a backup"
        text_size={12.5}
        font_weight="semibold"
        text_align="center"
        text_color={Palette.sub()}
      />
    </Column>
    """
  end

  @doc false
  def subtitle_note do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.note("info", "SUNDAY 16 AUGUST · NO DOSES is a literal that has to be drawn — the fallback prints 4 DOSES from a fixture, and an empty page cannot say that. or restore a backup is true: restore is the only writer that exists today.")}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc "The two controls screen 112 has drawn and inert since it shipped, and where each now goes."
  @spec destinations() :: map()
  def destinations do
    rows = [
      SettingsList.row(
        SettingsList.icon_tile("add"),
        SettingsList.body("Header add disc", "Opens 188 — drawn and inert since the page shipped",
          lines: 2
        ),
        nil
      ),
      SettingsList.row(
        SettingsList.icon_tile("chevron_right"),
        SettingsList.body("Each Schedules row", "Opens 189 — the chevron was always honest",
          lines: 2
        ),
        nil,
        rule: false
      )
    ]

    assigns = %{rows: rows}

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card(@rows)}
      <Spacer size={11} />
    </Column>
    """
  end

  @doc false
  def destinations_note do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.note("info", "Not new affordances — both are drawn, reachable and inert today, and the tap sweep lists all five by name. This brief gives them somewhere to go.")}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  Screen 112's reminder picture with the caption it lacked.

  The bubble is `Kati.Health.WeightSample.reminder/0`'s own two lines, drawn
  and inert here as they are there, and the DM Mono line under it is the new
  copy: a statement of where the switch lives, not a switch.
  """
  @spec reminder_caption() :: map()
  def reminder_caption do
    r = Kati.Health.WeightSample.reminder()

    assigns = %{title: r.title, body: r.body}

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={17}
      >
        <Column fill_width={true} background={Palette.card_settled()} corner_radius={20} padding={14}>
          <Text
            text="KATI · 08:00"
            font_family="mono"
            text_size={9.5}
            letter_spacing={0.1}
            text_color={Palette.eyebrow()}
            max_lines={1}
          />
          <Spacer size={9} />
          <Text
            text={@title}
            text_size={13.5}
            font_weight="bold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={5} />
          <Text text={@body} text_size={12.5} text_color={Palette.sub()} max_lines={1} />
        </Column>
        <Spacer size={12} />
        <Text
          text="SET ON EACH MEDICATION · 3 OF 4 CLOCK TIMES ARMED"
          font_family="mono"
          text_size={10}
          letter_spacing={0.1}
          text_color={Palette.muted()}
        />
      </Column>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc false
  def caption_note do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.note("info", "Not a switch — the switch is on 189, one per medication, and a page-level one would be a fifth thing that can disagree with the four. The count is clock times armed, not medications with times, because two tablets sharing 08:00 is one notification. And the caption resolves the body mismatch: 112’s drawn With water, before bed is the caption to redraw — the composed dose · instruction is the target.")}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  Where `Kati.Screens.Medication.save_notice/1` renders, drawn at last.

  Between the list it failed to change and the two verbs that were just
  pressed. The pair below it carry no `on_tap`: this is a picture of screen
  112's controls, and tapping a picture of a verb is not recording a dose.
  """
  @spec failure_line() :: map()
  def failure_line do
    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={22}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={17}
    >
      <Text
        text="Nothing to save yet."
        text_size={12.5}
        font_weight="semibold"
        text_color={Palette.red()}
      />
      <Spacer size={13} />
      <Row fill_width={true} align="center">
        <Row
          weight={1.0}
          height={36}
          corner_radius={18}
          background={Palette.ink_fill()}
          align="center"
        >
          <Spacer weight={1.0} />
          <Text
            text="Taken"
            text_size={12.5}
            font_weight="semibold"
            text_color={Palette.on_ink()}
            max_lines={1}
          />
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={9} />
        <Row weight={1.0} height={36} corner_radius={18} background={Palette.paper()} align="center">
          <Spacer weight={1.0} />
          <Text
            text="Skip"
            text_size={12.5}
            font_weight="semibold"
            text_color={Palette.ink_soft()}
            max_lines={1}
          />
          <Spacer weight={1.0} />
        </Row>
      </Row>
    </Column>
    """
  end

  @impl true
  def handle_tap(tag, socket) when tag in [:add, :add_first],
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.AddMedication)}

  def handle_tap(:restore_backup, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Restore)}

  def handle_tap(_tag, socket), do: {:noreply, socket}
end
