defmodule Kati.Screens.OnboardingLoudnessFa do
  @moduledoc """
  Screen 165 — اعلان‌ها, step 4 of five in Persian.

  Built to `test/design/screens/165.html`, the mirror of
  `Kati.Screens.OnboardingLoudness`, and the step that carries the same
  decision: **Quietly asks for nothing.** Kati raises no OS notification prompt
  for a reader who chose آرام — a dialog for a permission the choice does not
  need is how an app teaches people to refuse them.

  ## The digest day is Friday, not Sunday

  The English board reads *"One summary, Sundays at 18:00"* and this one reads
  «یک خلاصه، جمعه‌ها ساعت ۱۸:۰۰». That is a translation of the intent rather
  than of the words: the digest lands at the quiet end of the week, and in Iran
  that is Friday. Translating "Sunday" would have put the week's summary in the
  middle of a working week — the kind of literal correctness that reads as an
  app built somewhere else.

  ## What the caption pins about the mirror

  RTL flex puts the glyph at the **right**, leading the label, and carries the
  tick to the **trailing left edge** of each row. Both fall out of a `Row`
  under `layout_direction="rtl"`; nothing here reverses a list by hand.
  ۱۸:۰۰ stays at the design's mono size in Vazirmatn, because `kati_mono.ttf`
  carries none of U+06F0–U+06F9 — `Kati.Screens.Fa` states that rule and
  `Kati.PersianFontTest` now keeps it.
  """
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Screens.Fa
  alias Kati.Screens.OnboardingWelcome
  alias Kati.Screens.OnboardingWelcomeFa
  alias Kati.Theme.Palette
  alias Kati.UI

  @choices [
    {"آرام", "یک کارت در خانه. هیچ صدایی بلند نمی‌شود.", "inbox"},
    {"خبرم کن", "یک اعلان وقتی چیزی می‌رسد.", "notifications"},
    {"خلاصه هفتگی", "یک خلاصه، جمعه‌ها ساعت ۱۸:۰۰.", "mail"}
  ]

  def mount(_params, _session, socket) do
    Kati.Theme.activate()
    Kati.Onboarding.reached!(:loudness)
    {:ok, Mob.Socket.assign(socket, :choice, "آرام")}
  end

  def render(assigns) do
    Fa.pushed_frame(Fa.page(content(assigns)), Kati.Screens.Identity.of(__MODULE__))
  end

  @doc false
  def content(assigns) do
    ~MOB"""
    <Column fill_width={true}>
      {OnboardingWelcome.rail(4)}
      <Text
        text="چطور به شما خبر بدهیم؟"
        font_family="fa"
        text_size={24}
        max_font_scale={1.6}
        font_weight="bold"
        text_color={:on_surface}
      />
      <Spacer size={11} />
      <Text
        text="کاتی خودش قسمت‌های تازه را می‌بیند. شما انتخاب می‌کنید چقدر بلند بگوید."
        font_family="fa"
        text_size={13.5}
        line_height={1.75}
        text_color={Palette.ink_soft()}
      />
      <Spacer size={18} />
      {Kati.Screens.OnboardingLoudnessFa.choices(assigns.choice)}
      {Kati.Screens.OnboardingLoudnessFa.quiet_note(assigns.choice)}
      <Spacer size={16} />
      {OnboardingWelcomeFa.forward("ادامه", :next)}
      <Spacer size={16} />
      {Fa.note("info", "اگر «خبرم کن» را انتخاب کنید، گام بعد اجازه سیستم را می‌گیرد — همان بندی که در ۱۳۶ کشیده شده.")}
      {OnboardingWelcomeFa.back_row("بازگشت به بخش‌ها")}
    </Column>
    """
  end

  @doc false
  def choice_list, do: @choices

  @doc false
  def choices(active) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.OnboardingLoudnessFa.choice_list()
       |> Enum.map(fn {label, line, icon} ->
         Kati.Screens.OnboardingLoudnessFa.row(label, line, icon, label == active)
       end)
       |> Enum.intersperse(Kati.Screens.OnboardingLoudnessFa.gap())}
    </Column>
    """
  end

  @doc false
  def gap, do: ~MOB"<Spacer size={10} />"

  @doc false
  def row(label, line, icon, on?) do
    assigns = %{
      label: label,
      line: line,
      icon: icon,
      on?: on?,
      tap: {self(), Kati.Screens.OnboardingLoudnessFa.tag(label)}
    }

    ~MOB"""
    <Row
      fill_width={true}
      background={if @on?, do: Palette.ink_fill(), else: Palette.card()}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={15}
      align="center"
    >
      {UI.symbol(@icon, size: 20, color: if(@on?, do: Palette.on_ink(), else: Palette.ink_soft()))}
      <Spacer size={13} />
      <Column weight={1.0} on_tap={@tap}>
        <Text
          text={@label}
          font_family="fa"
          text_size={14}
          font_weight="bold"
          text_color={if @on?, do: Palette.on_ink(), else: :on_surface}
        />
        <Spacer size={3} />
        <Text
          text={@line}
          font_family="fa"
          text_size={11.5}
          line_height={1.6}
          text_color={if @on?, do: Palette.on_ink(), else: Palette.sub()}
        />
      </Column>
      {Kati.Screens.OnboardingLoudnessFa.tick(@on?)}
    </Row>
    """
  end

  @doc """
  The tap tag for a Persian choice, keyed on its position rather than its words.

  `String.to_atom("choose_" <> label)` is what the English screen does and it
  cannot be done here: `Kati.ScreenTapSweepTest` and `KatiRule` both address a
  control by the atom, and an atom carrying Persian is a name nobody can type
  into a device test. The three choices are a fixed list, so the index is a
  stable name for them.
  """
  @spec tag(String.t()) :: atom()
  def tag(label) do
    case label do
      "آرام" -> :choose_quiet
      "خبرم کن" -> :choose_notify
      _weekly -> :choose_digest
    end
  end

  @doc false
  def tick(false), do: ~MOB"<Spacer size={0} />"

  def tick(true) do
    ~MOB"""
    <Box width={22} height={22} corner_radius={11} background={Kati.Theme.accent()} align="center">
      {Kati.UI.symbol("check", size: 14, color: Palette.on_ink())}
    </Box>
    """
  end

  @doc """
  The sentence only آرام earns, drawn as a card the way 165 draws it.

  The consequence of the choice, stated under it: Kati raises no notification
  permission prompt at all for a reader who picked the quiet option.
  """
  @spec quiet_note(String.t()) :: map()
  def quiet_note("آرام") do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={16} />
      <Row
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={15}
        align="top"
      >
        {Kati.UI.symbol("check_circle", size: 18, color: Palette.green(), fill: true)}
        <Spacer size={11} />
        <Column weight={1.0}>
          <Text
            text="کاتی برای اعلان"
            font_family="fa"
            text_size={12.5}
            line_height={1.65}
            text_color={Palette.ink_soft()}
          />
          <Text
            text="اجازه نمی‌خواهد"
            font_family="fa"
            text_size={12.5}
            line_height={1.65}
            font_weight="semibold"
            text_color={Palette.ink()}
          />
          <Text
            text=". همه‌چیز در صندوق شما می‌آید."
            font_family="fa"
            text_size={12.5}
            line_height={1.65}
            text_color={Palette.ink_soft()}
          />
        </Column>
      </Row>
    </Column>
    """
  end

  def quiet_note(_other), do: ~MOB"<Spacer size={0} />"

  def handle_info({:tap, :next}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.OnboardingFirstTitleFa)}

  def handle_info({:tap, :choose_quiet}, socket),
    do: {:noreply, Mob.Socket.assign(socket, :choice, "آرام")}

  def handle_info({:tap, :choose_notify}, socket),
    do: {:noreply, Mob.Socket.assign(socket, :choice, "خبرم کن")}

  def handle_info({:tap, :choose_digest}, socket),
    do: {:noreply, Mob.Socket.assign(socket, :choice, "خلاصه هفتگی")}

  def handle_info({:tap, tag}, socket) when tag in [:step_back, :back],
    do: {:noreply, Mob.Socket.pop_screen(socket)}

  def handle_info({:tap, tag}, socket), do: Fa.dock_tap(tag, :home, socket)
  def handle_info(_message, socket), do: {:noreply, socket}
end
