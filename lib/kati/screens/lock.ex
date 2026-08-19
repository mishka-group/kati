defmodule Kati.Screens.Lock do
  @moduledoc """
  Screen 29 — the lock screen and its widgets.

  Built to `.scratch/design/screens/29.html`: a full-bleed wallpaper under a
  three-stop scrim, the clock, then three glass widgets — small, small,
  medium, large — off one data model.

  ## What the drawing is claiming

  *Three widget sizes off one data model*: what to watch next, how loaded
  tonight is, and the year as a pixel field. The two rows in the Today widget
  are the same two events screen 28 lists under *Rest of today*, at the same
  times, on the same evening. The pixel field is the same visual as the Stats
  hero at a different scale. Nothing here is invented for the lock screen; it
  is the app, quoted.

  The design's caption also names the one borrowed idea: *the glass treatment
  is the only place the app borrows from the OS*. Everywhere else Kati draws
  its own surfaces.

  ## Glass, without a backdrop filter

  The drawing asks for `backdrop-filter: blur(22px)` behind a
  `rgba(28,26,24,.5)` fill. Android has no backdrop blur through Mob — the
  same limit `Kati.Theme.chrome_fill/1` records for the dock — so this ships
  as the flat half-alpha fill over the wallpaper, with the drawing's
  `rgba(255,255,255,.14)` inset ring as a border. The intent, a panel that
  reads as sitting *on* the photograph, survives; the literal blur does not.

  ## No frame, no dock, no gutters at the top level

  The scroll carries `padding: 0 0 40px` and the wallpaper runs edge to edge;
  the 21pt gutters start inside it, at 52 from the top rather than the usual
  64. Tapping anywhere dismisses, since a lock screen with no way off it is a
  dead end on a device with a software back gesture.
  """
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Screens.Lock.Sample

  def mount(_params, _session, socket) do
    Mob.Theme.set(Kati.Theme.dark())
    {:ok, socket}
  end

  def render(_assigns) do
    dismiss = {self(), :dismiss}

    ~MOB"""
    <Box fill_width={true} fill_height={true} background={:background} layout_direction={Kati.Locale.direction_prop()} on_tap={dismiss}>
      <Scroll>
        <Column fill_width={true} padding_bottom={40}>
          <Box fill_width={true} height={810}>
            {Kati.Screens.Lock.wallpaper()}
            {Kati.Screens.Lock.scrim()}
            <Column fill_width={true} padding_left={21} padding_right={21} padding_top={52}>
              {Kati.Screens.Lock.clock()}
              {Kati.Screens.Lock.small_widgets()}
              {Kati.Screens.Lock.today()}
              {Kati.Screens.Lock.year()}
            </Column>
          </Box>
        </Column>
      </Scroll>
    </Box>
    """
  end

  def handle_info({:tap, :dismiss}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}
  def handle_info(_message, socket), do: {:noreply, socket}

  @doc false
  def wallpaper do
    case Kati.Design.Images.hero(Sample.wallpaper()) do
      nil -> ~MOB"<Box fill_width={true} height={810} background={0xFF1C1A18} />"
      src -> ~MOB"""
        <Image src={src} fill_width={true} height={810} content_mode="fill" />
        """
    end
  end

  # Three stops, not two: the photograph is darkened at both ends and left
  # alone across the middle 40%, so the clock reads at the top and the widgets
  # read at the bottom without flattening the picture between them.
  @doc false
  def scrim do
    ~MOB"""
    <Box fill_width={true} height={810} gradient="to_bottom #8C0C0B0A #400C0B0A 40% #CC0C0B0A" />
    """
  end

  # 74pt at weight 300 — the only place in the app that asks for a light
  # weight, and the reason is the OS: a lock clock is thin everywhere, so a
  # bold one would read as Kati shouting over the system rather than sitting
  # in it.
  #
  # Known gap: `res/font/` ships Plus Jakarta Sans 400–800, so there is no 300
  # face for Compose to resolve `FontWeight.Light` against and it falls back to
  # 400. The prop stays as the design writes it, because the day a 300 face
  # ships this line becomes correct with no edit; recorded here rather than
  # silently rounded to `"medium"`.
  @doc false
  def clock do
    now = Sample.clock()

    ~MOB"""
    <Column fill_width={true} padding_top={14}>
      <Row fill_width={true} align="center">
        <Spacer weight={1.0} />
        <Text
          text={now.date}
          font_family="mono"
          text_size={14}
          letter_spacing={0.06}
          text_color={0xD9FFFFFF}
          max_lines={1}
        />
        <Spacer weight={1.0} />
      </Row>
      <Spacer size={2} />
      <Row fill_width={true} align="center">
        <Spacer weight={1.0} />
        <Text
          text={now.time}
          text_size={74}
          font_weight="light"
          letter_spacing={-0.04}
          line_height={1.05}
          text_color={0xFFFFFFFF}
          max_lines={1}
        />
        <Spacer weight={1.0} />
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def small_widgets do
    up_next = Sample.up_next()
    tonight = Sample.tonight()

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Box weight={1.0}>
          <Column fill_width={true} background={0x801C1A18} corner_radius={20} border_width={1} border_color={0x24FFFFFF} padding={14}>
            {Kati.Screens.Lock.eyebrow(up_next.eyebrow)}
            <Spacer size={10} />
            <Row fill_width={true} align="center">
              {Kati.Screens.Lock.thumb(up_next)}
              <Spacer size={9} />
              <Column weight={1.0}>
                <Text text={up_next.title} text_size={12} font_weight="bold" text_color={0xFFFFFFFF} max_lines={1} />
                <Spacer size={3} />
                <Text text={up_next.meta} font_family="mono" text_size={9.5} text_color={0x99FFFFFF} max_lines={1} />
              </Column>
            </Row>
          </Column>
        </Box>
        <Spacer size={11} />
        <Box weight={1.0}>
          <Column fill_width={true} background={0x801C1A18} corner_radius={20} border_width={1} border_color={0x24FFFFFF} padding={14}>
            {Kati.Screens.Lock.eyebrow(tonight.eyebrow)}
            <Spacer size={8} />
            <Text text={tonight.count} text_size={28} font_weight="extrabold" letter_spacing={-0.03} text_color={0xFFFFFFFF} max_lines={1} />
            <Spacer size={2} />
            <Text text={tonight.label} text_size={10.5} text_color={0xA6FFFFFF} max_lines={1} />
          </Column>
        </Box>
      </Row>
      <Spacer size={11} />
    </Column>
    """
  end

  # No accent dash here. On the lock screen the widget titles are the OS's
  # idiom — mono, letter-spaced, half-alpha — and Kati's orange dash would
  # claim more of the wallpaper than a widget label should.
  @doc false
  def eyebrow(label) do
    ~MOB"""
    <Text
      text={label}
      font_family="mono"
      text_size={9}
      letter_spacing={0.14}
      text_color={0x8CFFFFFF}
      max_lines={1}
    />
    """
  end

  @doc false
  def thumb(widget) do
    case Kati.Design.Images.poster(widget.seed) do
      nil ->
        ~MOB"<Box width={30} height={42} corner_radius={5} background={0x26FFFFFF} />"

      src ->
        ~MOB"""
        <Image src={src} width={30} height={42} corner_radius={5} content_mode="fill" />
        """
    end
  end

  @doc false
  def today do
    widget = Sample.today()

    ~MOB"""
    <Column fill_width={true}>
      <Column fill_width={true} background={0x801C1A18} corner_radius={22} border_width={1} border_color={0x24FFFFFF} padding={16}>
        <Row fill_width={true} align="center">
          {Kati.Screens.Lock.eyebrow(widget.eyebrow)}
          <Spacer weight={1.0} />
          {Kati.UI.symbol("calendar_month", size: 15, color: 0x8CFFFFFF)}
        </Row>
        <Spacer size={12} />
        {widget.rows
         |> Enum.map(fn row -> Kati.Screens.Lock.today_row(row) end)
         |> Enum.intersperse(Kati.Screens.Lock.row_gap())}
      </Column>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc false
  def row_gap, do: ~MOB"<Spacer size={10} />"

  @doc false
  def today_row(row) do
    rail = if row.now?, do: 0xFFE8823C, else: 0x66FFFFFF

    ~MOB"""
    <Row fill_width={true} align="center">
      <Column width={36}>
        <Text text={row.time} font_family="mono" text_size={10.5} text_color={0x99FFFFFF} max_lines={1} />
      </Column>
      <Spacer size={11} />
      <Box width={2.5} height={16} corner_radius={2} background={rail} />
      <Spacer size={11} />
      <Text text={row.title} text_size={12} font_weight="semibold" text_color={0xFFFFFFFF} weight={1.0} max_lines={1} />
    </Row>
    """
  end

  @doc false
  def year do
    field = Sample.year()

    ~MOB"""
    <Column fill_width={true} background={0x801C1A18} corner_radius={22} border_width={1} border_color={0x24FFFFFF} padding={16}>
      {Kati.Screens.Lock.eyebrow(field.eyebrow)}
      <Spacer size={12} />
      {Enum.map(field.rows, fn row -> Kati.Screens.Lock.pixel_row(row) end)}
      <Spacer size={8} />
      <Row fill_width={true} align="center">
        <Text text={field.watched} font_family="mono" text_size={9.5} text_color={0x80FFFFFF} max_lines={1} />
        <Spacer weight={1.0} />
        <Text text={field.streak} font_family="mono" text_size={9.5} text_color={0x80FFFFFF} max_lines={1} />
      </Row>
    </Column>
    """
  end

  @doc false
  def pixel_row(row) do
    ~MOB"""
    <Column>
      <Row>
        {row
         |> Enum.map(fn level -> Kati.Screens.Lock.pixel(level) end)
         |> Enum.intersperse(Kati.Screens.Lock.pixel_gap())}
      </Row>
      <Spacer size={3} />
    </Column>
    """
  end

  @doc false
  def pixel_gap, do: ~MOB"<Spacer size={3} />"

  @doc false
  def pixel(level) do
    color = Sample.intensity(level)

    ~MOB"""
    <Box width={7} height={7} corner_radius={2} background={color} />
    """
  end
end
