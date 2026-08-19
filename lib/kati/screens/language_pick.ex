defmodule Kati.Screens.LanguagePick do
  @moduledoc """
  Screen 53 — the onboarding language choice.

  Built to `.scratch/design/screens/53.html`. The first step of five, and the
  first thing the app asks: nothing else can be worded until it is answered.
  So the question is asked twice, once in each script, and each option states
  its three consequences — direction, digits, calendar — in its own script.
  `RIGHT TO LEFT · ۱۲۳۴ · SHAMSI` is legible to someone who cannot read the
  English row, which an English description of Persian would not be.

  There is no back pill and no dock: the drawing has neither, and the way out
  is **Continue**. The frame's bottom inset is therefore 40, not 132.

  ## Fonts are the content here

  The Persian strings are set in Vazirmatn (`font_family="fa"`), not in Plus
  Jakarta Sans. A Persian name in a Latin face is precisely the near-miss this
  screen exists to prevent, and the app ships the face already — see
  `Kati.Theme`'s substrate table.

  The drawing marks the Persian blocks `direction:rtl`. The container stays
  `Kati.Locale.direction_prop()`, which is still `ltr` at this point in the
  flow — the whole interface flips only once the choice is *made*, which is
  what the cream note promises. Bidi resolution puts the Arabic script the
  right way round inside an LTR paragraph on its own.
  """
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Onboarding.LanguageSample

  def mount(_params, _session, socket) do
    Mob.Theme.set(Kati.Theme.light())
    {:ok, Mob.Socket.assign(socket, :pick, LanguageSample.pick())}
  end

  def render(assigns) do
    pick = assigns.pick

    ~MOB"""
    <Box fill_width={true} fill_height={true} background={:background} layout_direction={Kati.Locale.direction_prop()}>
      <Scroll>
        <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={40}>
          <Column fill_width={true} padding_top={26}>
            {Kati.Screens.LanguagePick.steps(pick)}
            {Kati.Screens.LanguagePick.mark()}
            {Kati.Screens.LanguagePick.question(pick)}
            {Kati.Screens.LanguagePick.options(pick)}
            {Kati.Screens.LanguagePick.note(pick)}
            {Kati.Screens.LanguagePick.cta(pick)}
          </Column>
        </Column>
      </Scroll>
    </Box>
    """
  end

  # Five segments, `done` of them filled — the step count without a "1 of 5"
  # anyone has to read.
  @doc false
  def steps(pick) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {1..pick.steps
         |> Enum.map(fn i -> Kati.Screens.LanguagePick.step_bar(i <= pick.done) end)
         |> Enum.intersperse(Kati.Screens.LanguagePick.step_gap())}
      </Row>
      <Spacer size={26} />
    </Column>
    """
  end

  @doc false
  def step_gap, do: ~MOB"<Spacer size={5} />"

  @doc false
  def step_bar(done?) do
    color = if done?, do: Kati.Theme.ink(), else: 0xFFDCD7CF

    ~MOB"<Box weight={1.0} height={4} corner_radius={2} background={color} />"
  end

  @doc false
  def mark do
    ~MOB"""
    <Column fill_width={true}>
      <Box width={56} height={56} corner_radius={18} background={Kati.Theme.ink()} align="center">
        {Kati.UI.symbol("translate", size: 26, color: 0xFFFBFAF8)}
      </Box>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def question(pick) do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={pick.title}
        text_size={32}
        font_weight="extrabold"
        letter_spacing={-0.035}
        line_height={1.12}
        text_color={:on_surface}
      />
      <Spacer size={10} />
      <Text
        text={pick.title_fa}
        font_family="fa"
        text_size={26}
        font_weight="bold"
        line_height={1.4}
        text_color={0xFF8A8479}
      />
      <Spacer size={14} />
      <Text text={pick.body} text_size={14.5} line_height={1.6} text_color={0xFF5C574F} />
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def options(pick) do
    ~MOB"""
    <Column fill_width={true}>
      {pick.options
       |> Enum.map(fn option -> Kati.Screens.LanguagePick.option(option) end)
       |> Enum.intersperse(Kati.Screens.LanguagePick.option_gap())}
    </Column>
    """
  end

  @doc false
  def option_gap, do: ~MOB"<Spacer size={11} />"

  # The chosen row is drawn on ink, the same inversion screen 49 gives the
  # active plan: the choice you are living with is the dark one.
  @doc false
  def option(%{chosen: true} = option) do
    ~MOB"""
    <Row
      fill_width={true}
      background={Kati.Theme.ink()}
      corner_radius={22}
      shadow="0 14 28 -14 #E61A1917"
      padding={17}
      align="center"
    >
      <Box width={42} height={42} corner_radius={14} background={0x1FF5F2EE} align="center">
        {Kati.Screens.LanguagePick.badge(option, 0xFFF5F2EE)}
      </Box>
      <Spacer size={14} />
      <Column weight={1.0}>
        {Kati.Screens.LanguagePick.name(option, 0xFFFBFAF8)}
        <Spacer size={4} />
        <Text text={option.meta} font_family="mono" text_size={10.5} text_color={0xFF8A837B} max_lines={1} />
      </Column>
      <Spacer size={14} />
      <Box width={24} height={24} corner_radius={12} background={Kati.Theme.accent()} align="center">
        {Kati.UI.symbol("check", size: 15, color: 0xFFFBFAF8)}
      </Box>
    </Row>
    """
  end

  def option(%{chosen: false} = option) do
    ~MOB"""
    <Row
      fill_width={true}
      background={Kati.Theme.card(:light)}
      corner_radius={22}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={17}
      align="center"
    >
      <Box width={42} height={42} corner_radius={14} background={0xFFEFECE7} align="center">
        {Kati.Screens.LanguagePick.badge(option, Kati.Theme.ink())}
      </Box>
      <Spacer size={14} />
      <Column weight={1.0}>
        {Kati.Screens.LanguagePick.name(option, Kati.Theme.ink())}
        <Spacer size={4} />
        <Text text={option.meta} font_family="mono" text_size={10.5} text_color={0xFFA9A29A} max_lines={1} />
      </Column>
      <Spacer size={14} />
      <Box width={24} height={24} corner_radius={12} border_width={1.5} border_color={0x291A1917} />
    </Row>
    """
  end

  # The Latin badge is DM Mono at 14 and the Persian one is Vazirmatn Bold at
  # 16 — the drawing's own sizes, chosen so two scripts of different x-height
  # look the same weight inside the same 42pt tile.
  @doc false
  def badge(%{script: :persian} = option, color) do
    ~MOB"""
    <Text text={option.badge} font_family="fa" text_size={16} font_weight="bold" text_color={color} max_lines={1} />
    """
  end

  def badge(option, color) do
    ~MOB"""
    <Text text={option.badge} font_family="mono" text_size={14} text_color={color} max_lines={1} />
    """
  end

  @doc false
  def name(%{script: :persian} = option, color) do
    ~MOB"""
    <Text text={option.name} font_family="fa" text_size={17} font_weight="bold" text_color={color} max_lines={1} />
    """
  end

  def name(option, color) do
    ~MOB"""
    <Text
      text={option.name}
      text_size={16}
      font_weight="bold"
      letter_spacing={-0.02}
      text_color={color}
      max_lines={1}
    />
    """
  end

  # Cream, and filled rather than outlined: this is the consequence of the
  # choice above it, not an aside about the screen.
  @doc false
  def note(pick) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={18} />
      <Row fill_width={true} background={0xFFFBF1DE} corner_radius={18} padding={15} align="top">
        {Kati.UI.symbol("info", size: 17, color: 0xFFC98A3E)}
        <Spacer size={11} />
        <Text text={pick.note} text_size={12.5} line_height={1.55} text_color={0xFF4A4238} weight={1.0} />
      </Row>
    </Column>
    """
  end

  @doc false
  def cta(pick) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={20} />
      <Box fill_width={true} height={54} corner_radius={27} background={Kati.Theme.ink()} align="center">
        <Row align="center">
          <Text text={pick.cta} text_size={14.5} font_weight="bold" text_color={0xFFFBFAF8} max_lines={1} />
          <Spacer size={9} />
          {Kati.UI.symbol("arrow_forward", size: 19, color: 0xFFFBFAF8)}
        </Row>
      </Box>
    </Column>
    """
  end

  def handle_info(_message, socket), do: {:noreply, socket}
end
