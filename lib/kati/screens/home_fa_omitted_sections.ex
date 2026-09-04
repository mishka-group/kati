defmodule Kati.Screens.HomeFaOmittedSections do
  @moduledoc """
  Screen 160 — the two empty sections, omitted and decided.

  A reference sheet in screen 27's manner, and the answer to the one question
  brief `D-32` left open: with nothing to put in them, an empty
  تازه‌های این هفته and an empty ادامه تماشا are **omitted entirely** rather
  than worded.

  ## Why omission and not a sentence

  The board argues it in its own words, and the argument is the same both
  ways round: *یک ردیف خالی می‌گوید چیزی خراب است؛ نبودن ردیف می‌گوید هنوز
  شروع نکرده‌اید* — an empty row says something is broken, a missing row says
  you have not started yet.

  **The decision is the same in English.** The app already omitted both, by
  accident rather than by decision, because no board worded them in either
  language. This is the board that makes it a decision.

  ## What does not go

  باقی امروز stays whatever happens, and the board says why: the calendar does
  not depend on sections, and *"nothing today"* is itself a piece of news.
  That is 139's rule — an empty page states which parts still work — applied
  one level down.
  """
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Screens.Fa
  alias Kati.Screens.HomeFa
  alias Kati.Screens.HomeFaEmpty
  alias Kati.Theme.Palette
  alias Kati.UI

  def mount(_params, _session, socket) do
    Kati.Theme.activate()
    {:ok, socket}
  end

  def render(assigns),
    do: Fa.frame(:home, content(assigns), Kati.Screens.Identity.of(__MODULE__))

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
        {Kati.Screens.HomeFaOmittedSections.header()}
        {Kati.Screens.HomeFaOmittedSections.search()}
        {Kati.Screens.HomeFaOmittedSections.omitted("تازه‌های این هفته", "با هیچ عنوانی برای پیگیری، این بخش", "نمایش داده نمی‌شود", "— نه با یک جمله خالی، بلکه اصلاً.")}
        {Kati.Screens.HomeFaOmittedSections.omitted("ادامه تماشا", "همین‌طور. یک ردیف خالی می‌گوید چیزی خراب است؛", "نبودن ردیف", "می‌گوید هنوز شروع نکرده‌اید.")}
        {Kati.Screens.Fa.quiet_eyebrow("بخش‌ها")}
        {Kati.Screens.HomeFaOmittedSections.section_cards()}
        {Kati.Screens.HomeFaOmittedSections.footnote()}
      </Column>
    </Scroll>
    """
  end

  @doc false
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
        {HomeFaEmpty.disc("notifications", :open_inbox)}
      </Row>
      <Spacer size={20} />
    </Column>
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
          text="جست‌وجوی فیلم، سریال، رویداد…"
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
  One section named, and the annotation saying it is not drawn.

  The `block` glyph rather than a card: the whole point is that no card is
  here, so drawing one to explain the absence would contradict the thing it
  explains.
  """
  @spec omitted(String.t(), String.t(), String.t(), String.t()) :: map()
  def omitted(title, lead, emphasis, tail) do
    assigns = %{title: title, lead: lead, emphasis: emphasis, tail: tail}

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.Fa.quiet_eyebrow(@title)}
      <Row fill_width={true} align="top">
        {UI.symbol("block", size: 17, color: Palette.tertiary())}
        <Spacer size={9} />
        <Column weight={1.0}>
          <Text font_family="fa" text={@lead} text_size={12.5} line_height={1.55} text_color={Palette.ink_soft()} />
          <Text
            text={@emphasis}
            font_family="fa"
            text_size={12.5}
            line_height={1.55}
            font_weight="semibold"
            text_color={Palette.ink()}
          />
          <Text font_family="fa" text={@tail} text_size={12.5} line_height={1.55} text_color={Palette.ink_soft()} />
        </Column>
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def section_cards do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {Kati.Screens.HomeFaOmittedSections.card("restaurant", "وعده‌ها", "شام ۱۹:۳۰")}
        <Spacer size={11} />
        {Kati.Screens.HomeFaOmittedSections.card("bolt", "عادت‌ها", "۲ مورد مانده")}
      </Row>
      <Spacer size={11} />
      <Row fill_width={true} align="top">
        {Kati.Screens.HomeFaOmittedSections.card("tune", "تنظیمات", nil)}
        <Spacer size={11} />
        <Box weight={1.0} />
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def card(icon, title, line) do
    assigns = %{icon: icon, title: title, line: line}

    ~MOB"""
    <Column
      weight={1.0}
      background={Palette.card()}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={16}
    >
      {UI.symbol(@icon, size: 22)}
      <Spacer size={10} />
      <Text font_family="fa" text={@title} text_size={13.5} font_weight="semibold" text_color={:on_surface} max_lines={1} />
      {Kati.Screens.HomeFaOmittedSections.line(@line)}
    </Column>
    """
  end

  @doc false
  def line(nil), do: ~MOB"<Spacer size={0} />"

  def line(text) do
    assigns = %{text: text}

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={5} />
      <Text font_family="fa" text={@text} text_size={11.5} text_color={Palette.sub()} max_lines={1} />
    </Column>
    """
  end

  @doc false
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
          text="یک بخش بدون محتوا حذف می‌شود، نه اینکه خالی نوشته شود — اما"
          font_family="fa"
          text_size={12}
          line_height={1.5}
          text_color={Palette.ink_soft()}
        />
        <Text
          text="باقی امروز"
          font_family="fa"
          text_size={12}
          line_height={1.5}
          font_weight="semibold"
          text_color={Palette.ink()}
        />
        <Text
          text="همیشه می‌ماند، چون تقویم به بخش‌ها وابسته نیست و «امروز چیزی نیست» خودش یک خبر است."
          font_family="fa"
          text_size={12}
          line_height={1.5}
          text_color={Palette.ink_soft()}
        />
        <Text
          text="این تصمیم برای انگلیسی هم همین است."
          font_family="fa"
          text_size={12}
          line_height={1.5}
          text_color={Palette.ink_soft()}
        />
      </Column>
    </Row>
    """
  end

  def handle_info({:tap, :open_search}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.SearchFa)}

  def handle_info({:tap, :open_inbox}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Inbox)}

  def handle_info({:tap, tag}, socket), do: Fa.dock_tap(tag, :home, socket)
  def handle_info(_message, socket), do: {:noreply, socket}
end
