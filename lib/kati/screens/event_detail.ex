defmodule Kati.Screens.EventDetail do
  @moduledoc """
  Screen 31 — Event detail & edit.

  Built to `.scratch/design/screens/31.html`. Its own dismissal, not a back
  pill: the drawing puts a `close` disc, a centred "Edit event" title and an
  ink Save pill on one row, in flow at the top of the scroll — an editor you
  finish or abandon, not a page you came from. So this is `use Mob.Screen`
  with its own `mount/3` and `render/1`, the way screen 08 is, rather than
  `Kati.Screens.Pushed`.

  The frame's bottom padding is **40, not 132**: there is no dock under this
  screen, so the 132 that clears the tab bar would just be dead paper.

  ## Where this diverges from the drawing

    * The title's caret is a real 2x22 accent rule after the text rather than
      an inline `vertical-align:-3px` span. Same mark, laid out by a `Row`.
    * "Add someone" has a `1.5px dashed` ring. The bridge's border has no dash
      pattern, so it ships solid at the design's `rgba(26,25,23,.2)`.
    * The timezone switch is drawn from primitives rather than
      `Kati.Components.MishkaSwitch`: the design specifies its exact geometry
      (46x28 track, 3pt inset, 22pt knob with its own shadow), and a component
      whose whole job is to own those numbers would have to be overridden on
      every one of them.
  """
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Calendar.SampleEvent
  alias Kati.Design.Images
  alias Kati.Theme
  alias Kati.UI

  def mount(_params, _session, socket) do
    Mob.Theme.set(Kati.Theme.light())
    {:ok, Mob.Socket.assign(socket, :event, SampleEvent.event())}
  end

  def render(assigns) do
    event = assigns.event

    ~MOB"""
    <Box fill_width={true} fill_height={true} background={:background} layout_direction={Kati.Locale.direction_prop()}>
      <Scroll>
        <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={40}>
          {Kati.Screens.EventDetail.chrome()}
          {Kati.Screens.EventDetail.title_card(event)}
          {Kati.Screens.EventDetail.fields(event)}
          {UI.eyebrow("Clash")}
          {Kati.Screens.EventDetail.clash(event)}
          {Kati.Screens.EventDetail.muted_eyebrow("Invitees")}
          {Kati.Screens.EventDetail.invitees(event)}
          {Kati.Screens.EventDetail.delete()}
        </Column>
      </Scroll>
    </Box>
    """
  end

  @doc false
  def chrome do
    close = {self(), :close}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Box
          width={44}
          height={44}
          corner_radius={22}
          background={Theme.card(:light)}
          shadow={Theme.shadow_button()}
          align="center"
          on_tap={close}
        >
          {UI.symbol("close", size: 21)}
        </Box>
        <Spacer weight={1.0} />
        <Text text="Edit event" text_size={15} font_weight="bold" text_color={:on_surface} max_lines={1} />
        <Spacer weight={1.0} />
        <Row height={38} corner_radius={19} background={Theme.ink()} padding_left={16} padding_right={16} align="center">
          <Text text="Save" text_size={13} font_weight="bold" text_color={0xFFFBFAF8} max_lines={1} />
        </Row>
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def title_card(event) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Theme.card(:light)}
        corner_radius={22}
        shadow={Theme.shadow_card_soft()}
        padding={18}
      >
        <Row fill_width={true} align="center">
          <Text
            text={event.title}
            text_size={22}
            font_weight="bold"
            letter_spacing={-0.025}
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={3} />
          <Box width={2} height={22} background={Theme.accent()} />
        </Row>
        <Spacer size={12} />
        <Row fill_width={true} align="center">
          {UI.symbol("label", size: 16, color: 0xFF8A8479)}
          <Spacer size={8} />
          {event.sections
           |> Enum.map(fn {label, on?} -> Kati.Screens.EventDetail.section_chip(label, on?) end)
           |> Enum.intersperse(Kati.Screens.EventDetail.chip_gap())}
        </Row>
      </Column>
      <Spacer size={14} />
    </Column>
    """
  end

  @doc false
  def chip_gap, do: ~MOB"<Spacer size={6} />"

  @doc false
  def section_chip(label, on?) do
    background = if on?, do: Theme.ink(), else: 0xFFEFECE7
    color = if on?, do: 0xFFFBFAF8, else: 0xFF8A8479

    ~MOB"""
    <Row height={26} corner_radius={13} background={background} padding_left={11} padding_right={11} align="center">
      <Text text={label} text_size={11.5} font_weight="semibold" text_color={color} max_lines={1} />
    </Row>
    """
  end

  @doc false
  def fields(event) do
    last = length(event.fields) - 1

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Theme.card(:light)}
        corner_radius={20}
        shadow={Theme.shadow_card_soft()}
        padding_left={15}
        padding_right={15}
        padding_top={4}
        padding_bottom={4}
      >
        {event.fields
         |> Enum.with_index()
         |> Enum.map(fn {row, i} -> Kati.Screens.EventDetail.field_row(row, i < last) end)}
      </Column>
      <Spacer size={14} />
    </Column>
    """
  end

  @doc false
  def field_row(row, rule?) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={13} padding_bottom={13}>
        <Box width={30} height={30} corner_radius={9} background={0xFFEFECE7} align="center">
          {Kati.UI.symbol(row.icon, size: 17, color: 0xFF5C574F)}
        </Box>
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text text={row.title} text_size={13.5} font_weight="semibold" text_color={:on_surface} max_lines={1} />
          <Spacer size={3} />
          <Text text={row.sub} text_size={11.5} text_color={0xFF8A8479} max_lines={1} />
        </Column>
        <Spacer size={13} />
        {Kati.Screens.EventDetail.trailing(row.trailing)}
      </Row>
      {Kati.Screens.EventDetail.hairline(rule?)}
    </Column>
    """
  end

  @doc false
  def trailing({:value, text}) do
    ~MOB"""
    <Text text={text} font_family="mono" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
    """
  end

  # The knob is pushed to the trailing edge by a weighted Spacer inside a
  # fixed-width Row, which is what `justify-content:flex-end` is here. A Box
  # would have stacked the knob over the track instead of beside it.
  def trailing({:switch, true}) do
    ~MOB"""
    <Row width={46} height={28} corner_radius={14} background={Kati.Theme.ink()} padding={3} align="center">
      <Spacer weight={1.0} />
      <Box width={22} height={22} corner_radius={11} background={0xFFFBFAF8} shadow={"0 1 3 0 #4D1A1917"} />
    </Row>
    """
  end

  def trailing({:switch, false}) do
    ~MOB"""
    <Row width={46} height={28} corner_radius={14} background={0xFFDCD7CF} padding={3} align="center">
      <Box width={22} height={22} corner_radius={11} background={0xFFFBFAF8} shadow={"0 1 3 0 #4D1A1917"} />
      <Spacer weight={1.0} />
    </Row>
    """
  end

  def trailing(:chevron), do: Kati.UI.symbol("chevron_right", size: 18, color: 0xFFC4BDB3)

  @doc false
  def hairline(false), do: ~MOB"<Spacer size={0} />"
  def hairline(true), do: ~MOB"<Box fill_width={true} height={1} background={0x121A1917} />"

  # On cream, and with no shadow: the design's warm card is where the app
  # speaks in its own voice rather than listing a field.
  @doc false
  def clash(event) do
    clash = event.clash

    ~MOB"""
    <Column fill_width={true}>
      <Column fill_width={true} background={Theme.cream(:light)} corner_radius={20} padding={16}>
        <Row fill_width={true} align="center">
          {UI.symbol("call_split", size: 18, color: 0xFFC98A3E)}
          <Spacer size={10} />
          <Text text={clash.line} text_size={13} font_weight="bold" text_color={:on_surface} weight={1.0} max_lines={1} />
        </Row>
        <Spacer size={13} />
        <Row fill_width={true} align="center">
          {clash.actions
           |> Enum.map(fn {label, tone} -> Kati.Screens.EventDetail.action(label, tone) end)
           |> Enum.intersperse(Kati.Screens.EventDetail.action_gap())}
        </Row>
      </Column>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def action_gap, do: ~MOB"<Spacer size={8} />"

  @doc false
  def action(label, :primary) do
    ~MOB"""
    <Row height={34} corner_radius={17} background={Kati.Theme.ink()} padding_left={13} padding_right={13} align="center">
      <Text text={label} text_size={11.5} font_weight="semibold" text_color={0xFFFBFAF8} max_lines={1} />
    </Row>
    """
  end

  def action(label, :quiet) do
    ~MOB"""
    <Row height={34} corner_radius={17} background={0x99FFFFFF} padding_left={13} padding_right={13} align="center">
      <Text text={label} text_size={11.5} font_weight="semibold" text_color={0xFF8A7B60} max_lines={1} />
    </Row>
    """
  end

  # Kati.UI.eyebrow's dash is always the accent; this one is #C4BDB3, which is
  # how the design marks a section that lists rather than warns.
  @doc false
  def muted_eyebrow(label) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        <Box width={13} height={2} corner_radius={1} background={0xFFC4BDB3} />
        <Spacer size={9} />
        <Text
          text={String.upcase(label)}
          font_family="mono"
          text_size={10.5}
          letter_spacing={0.16}
          text_color={0xFFA0998F}
        />
      </Row>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc false
  def invitees(event) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Theme.card(:light)}
        corner_radius={20}
        shadow={Theme.shadow_card_soft()}
        padding_left={15}
        padding_right={15}
        padding_top={4}
        padding_bottom={4}
      >
        {Enum.map(event.invitees, fn person -> Kati.Screens.EventDetail.invitee_row(person) end)}
        {Kati.Screens.EventDetail.add_someone()}
      </Column>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def invitee_row(person) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={11} padding_bottom={11}>
        {Kati.Screens.EventDetail.avatar(person)}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text text={person.name} text_size={13} font_weight="semibold" text_color={:on_surface} max_lines={1} />
          <Spacer size={2} />
          <Text text={person.sub} text_size={11} text_color={0xFF8A8479} max_lines={1} />
        </Column>
        <Spacer size={13} />
        {Kati.Screens.EventDetail.reply(person.state)}
      </Row>
      <Box fill_width={true} height={1} background={0x121A1917} />
    </Column>
    """
  end

  @doc false
  def avatar(person) do
    case Images.poster(person.seed) do
      nil ->
        ~MOB"<Box width={34} height={34} corner_radius={17} background={0xFFE4E0D9} />"

      src ->
        ~MOB"""
        <Image src={src} width={34} height={34} corner_radius={17} content_mode="fill" />
        """
    end
  end

  @doc false
  def reply(:accepted), do: Kati.UI.symbol("check_circle", size: 18, color: 0xFF4E9A73, fill: true)
  def reply(:waiting), do: Kati.UI.symbol("schedule", size: 18, color: 0xFFC4BDB3)

  @doc false
  def add_someone do
    ~MOB"""
    <Row fill_width={true} align="center" padding_top={11} padding_bottom={11}>
      <Box
        width={34}
        height={34}
        corner_radius={17}
        border_color={0x331A1917}
        border_width={1.5}
        align="center"
      >
        {Kati.UI.symbol("add", size: 16, color: 0xFF8A8479)}
      </Box>
      <Spacer size={13} />
      <Text text="Add someone" text_size={13} font_weight="semibold" text_color={0xFF8A8479} weight={1.0} max_lines={1} />
    </Row>
    """
  end

  # Outlined in red rather than filled: destructive, and one tap away from
  # nothing. The design gives it no background at all.
  @doc false
  def delete do
    ~MOB"""
    <Box
      fill_width={true}
      height={48}
      corner_radius={24}
      border_color={0x4DB4553C}
      border_width={1.5}
      align="center"
    >
      <Row align="center">
        {UI.symbol("delete", size: 18, color: 0xFFB4553C)}
        <Spacer size={8} />
        <Text text="Delete event" text_size={13} font_weight="bold" text_color={0xFFB4553C} max_lines={1} />
      </Row>
    </Box>
    """
  end

  def handle_info({:tap, :close}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}
  def handle_info(_message, socket), do: {:noreply, socket}
end
