defmodule Kati.Screens.HomeFaEmpty do
  @moduledoc """
  Screen 158 — خانه with nothing stored, in the mirror.

  Built to `test/design/screens/158.html`. Screen 139's page in Persian, and
  the one this app most needed: `Kati.Onboarding.shell_root/1` answers screen
  55 for `:fa`, so this is the first page a Persian first run lands on, and
  until board 158 arrived no artboard worded an empty Persian day at all. The
  app wrote **one sentence in code** instead — `Kati.Screens.SettingsFa`'s
  `backup_line/1` precedent — and marked it as the stopgap it was.

  ## What 139's caption asks for, kept

  *"states which parts still work, because an empty Home that looks broken
  sends a new user back out"*. So the calendar card and the quick-add stay
  live and the board says why in its own footnote: تقویم و افزودن سریع به بخش
  وابسته نیستند — the calendar and quick-add do not depend on a section, and
  can be used before the app is set up at all.

  ## The two empty sections, decided

  Board 160 is titled *"The two empty sections — omitted, decided"*, and that
  is the answer to the question brief `D-32` left open: an empty
  تازه‌های این هفته and an empty ادامه تماشا are **omitted**, not worded. The
  app already omitted them, by accident rather than by decision, because no
  board worded them in either language. Now it omits them on purpose, and
  `Kati.Screens.HomeFaEmptyDecisions` is where that is written down.
  """
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Screens.Fa
  alias Kati.Screens.HomeFa
  alias Kati.Theme.Palette
  alias Kati.UI

  def mount(_params, _session, socket) do
    Kati.Theme.activate()
    {:ok, socket}
  end

  def render(assigns), do: Fa.frame(:home, content(assigns), Kati.Screens.Identity.of(__MODULE__))

  @doc false
  def content(_assigns) do
    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={132}
      >
        {Kati.Screens.HomeFaEmpty.header()}
        {Kati.Screens.HomeFaEmpty.search()}
        {Kati.Screens.HomeFaEmpty.invitation()}
        {Fa.quiet_eyebrow("تقویم همچنان کار می‌کند")}
        {Kati.Screens.HomeFaEmpty.today_card()}
        {Kati.Screens.HomeFaEmpty.footnote()}
      </Column>
    </Scroll>
    """
  end

  @doc "The date line and greeting, read from the clock exactly as screen 55 does."
  @spec header() :: map()
  def header do
    assigns = %{moment: HomeFa.moment()}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Column weight={1.0}>
          <Text
            text={@moment.date}
            font_family="fa"
            text_size={11.5}
            font_weight="medium"
            text_color={Palette.tertiary()}
            max_lines={1}
          />
          <Spacer size={7} />
          <Text
            text={@moment.greeting}
            font_family="fa"
            text_size={26}
            max_font_scale={1.6}
            font_weight="bold"
            letter_spacing={-0.03}
            text_color={:on_surface}
          />
        </Column>
        {Kati.Screens.HomeFaEmpty.disc("tune", :open_settings)}
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def disc(icon, tag) do
    assigns = %{icon: icon, tap: {self(), tag}}

    ~MOB"""
    <Box
      width={44}
      height={44}
      corner_radius={22}
      background={Palette.card()}
      shadow={Kati.Theme.shadow_button()}
      align="center"
      on_tap={@tap}
    >
      {Kati.UI.symbol(@icon, size: 21)}
    </Box>
    """
  end

  @doc false
  def search do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        height={52}
        corner_radius={26}
        background={Palette.card()}
        shadow={Kati.Theme.shadow_search()}
        padding_left={18}
        padding_right={18}
        align="center"
        on_tap={{self(), :open_search}}
      >
        {UI.symbol("search", size: 20, color: Palette.tertiary())}
        <Spacer size={11} />
        <Text
          text="جست‌وجوی هر چیزی که نگه می‌دارید"
          font_family="fa"
          text_size={14.5}
          text_color={Palette.tertiary()}
          weight={1.0}
          max_lines={1}
        />
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  The empty card: what is missing, and the one thing that fixes it.

  Screen 96's rule, in Persian — *"an empty state should say what is missing
  and offer the one thing that fixes it — never render a plausible-looking
  zero"*. The quiet alternative under the ink action is the restore path, which
  is the same pair screen 139 draws.
  """
  @spec invitation() :: map()
  def invitation do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={20}
        align="center"
      >
        <Box width={56} height={56} corner_radius={16} background={Palette.placeholder()} align="center">
          {UI.symbol("grid_view", size: 28, color: Palette.tertiary())}
        </Box>
        <Spacer size={18} />
        <Text
          text="هنوز چیزی اینجا نیست"
          font_family="fa"
          text_size={16.5}
          font_weight="bold"
          text_color={:on_surface}
          text_align="center"
        />
        <Spacer size={8} />
        <Text
          text="کاتی همان چیزی را نگه می‌دارد که به آن بسپارید. یک بخش را انتخاب کنید و این صفحه با چیزهایی که تماشا و مطالعه می‌کنید پر می‌شود."
          font_family="fa"
          text_size={12.5}
          line_height={1.6}
          text_color={Palette.ink_soft()}
          text_align="center"
        />
        <Spacer size={16} />
        {Kati.UI.Sheet.commit("انتخاب بخش‌ها", :pick_sections, "fa")}
        <Spacer size={11} />
        <Box fill_width={true} on_tap={{self(), :import_backup}}>
          <Text
            text="یا بازگردانی از پشتیبان"
            font_family="fa"
            text_size={13}
            font_weight="semibold"
            text_color={Palette.sub()}
            text_align="center"
          />
        </Box>
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def today_card do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={17}
        align="center"
        on_tap={{self(), :open_calendar}}
      >
        <Box width={38} height={38} corner_radius={12} background={Palette.placeholder()} align="center">
          {UI.symbol("calendar_month", size: 19, color: Palette.ink_soft())}
        </Box>
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text font_family="fa" text="امروز" text_size={13.5} font_weight="semibold" text_color={:on_surface} />
          <Spacer size={4} />
          <Text
            text="چیزی برنامه‌ریزی نشده — با + هر چیزی اضافه کنید"
            font_family="fa"
            text_size={11.5}
            text_color={Palette.sub()}
          />
        </Column>
        {UI.symbol("chevron_left", size: 18, color: Palette.rail_idle())}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc """
  Why the page is empty, and which parts are not.

  Two sentences with the middle clause emphasised, exactly as the board draws
  it — the same shape `Kati.Screens.AddByHand.split_note/3` produces, and the
  emphasis falls on the half a new user needs: the calendar and quick-add do
  not depend on a section.
  """
  @spec footnote() :: map()
  def footnote do
    ~MOB"""
    <Row
      fill_width={true}
      background={Palette.cream()}
      corner_radius={16}
      padding={13}
      align="top"
    >
      {UI.symbol("info", size: 17, color: Palette.sub())}
      <Spacer size={9} />
      <Column weight={1.0}>
        <Text
          text="خانه صفحه‌ای از کارت‌های بخش‌هاست، پس بدون بخش چیزی برای نشان‌دادن ندارد."
          font_family="fa"
          text_size={12}
          line_height={1.5}
          text_color={Palette.ink_soft()}
        />
        <Text
          text="تقویم و افزودن سریع به بخش وابسته نیستند"
          font_family="fa"
          text_size={12}
          line_height={1.5}
          font_weight="semibold"
          text_color={Palette.ink()}
        />
        <Text
          text="و همیشه زنده می‌مانند — پیش از آنکه برنامه تنظیم شود هم می‌شود از آن استفاده کرد."
          font_family="fa"
          text_size={12}
          line_height={1.5}
          text_color={Palette.ink_soft()}
        />
      </Column>
    </Row>
    """
  end

  def handle_info({:tap, :pick_sections}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.PickSections)}

  def handle_info({:tap, :import_backup}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.RestoreFa)}

  def handle_info({:tap, :open_settings}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.SettingsFa)}

  def handle_info({:tap, :open_search}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.SearchFa)}

  # The Today card leads to the Persian calendar, which is the board's own
  # promise: تقویم همچنان کار می‌کند — the calendar still works, and a card
  # that says so and goes nowhere would be the page disproving its own
  # footnote.
  def handle_info({:tap, :open_calendar}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.CalendarFa)}

  def handle_info({:tap, tag}, socket), do: Fa.dock_tap(tag, :home, socket)
  def handle_info(_message, socket), do: {:noreply, socket}
end
