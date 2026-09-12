defmodule Kati.Screens.HomeOmittedSections do
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
  use Gettext, backend: Kati.Gettext
  import Mob.Sigil

  alias Kati.Screens.Home
  alias Kati.Theme.Palette
  alias Kati.UI

  def mount(_params, _session, socket) do
    Kati.Theme.activate()
    Kati.Locale.activate()
    {:ok, socket}
  end

  # The shell's own chrome, with this page's name on the root rather than the
  # shell's: `Kati.Shell.render/1` stamps `screen:home`, and a reference sheet
  # that answered to the root's id would be a second node with the same tag —
  # `onNodeWithTag` throws on the second match.
  def render(assigns) do
    ~MOB"""
    <Box
      fill_width={true}
      fill_height={true}
      background={:background}
      layout_direction={Kati.Locale.direction_prop()}
      font_family={Kati.Locale.face_prop()}
      accessibility_id={Kati.Screens.Identity.of(__MODULE__)}
    >
      {content(assigns)}
      <Box fill_width={true} fill_height={true} align="bottom">
        {Kati.UI.paper_fade(120, 42)}
      </Box>
      {Kati.Shell.dock(:home, Palette.mode())}
    </Box>
    """
  end

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
        {Kati.Screens.HomeOmittedSections.header()}
        {Kati.Screens.HomeOmittedSections.search()}
        {Kati.Screens.HomeOmittedSections.omitted(
          gettext("New this week"),
          gettext("With nothing to follow, this section is "),
          gettext("not drawn"),
          gettext(" — not worded empty, not at all.")
        )}
        {Kati.Screens.HomeOmittedSections.omitted(
          gettext("Continue watching"),
          gettext("The same. An empty row says something is broken; "),
          gettext("a missing row"),
          gettext(" says you have not started yet.")
        )}
        {Kati.UI.eyebrow(gettext("Sections"), dash: Palette.rail_idle())}
        {Kati.Screens.HomeOmittedSections.section_cards()}
        {Kati.Screens.HomeOmittedSections.footnote()}
      </Column>
    </Scroll>
    """
  end

  # Screen 160's bell keeps `:open_inbox` and keeps opening
  # `Kati.Screens.Inbox`. Screens 01, 28 and 55 call their bell
  # `:notifications` and open `Kati.Screens.InboxNotifications`; this page
  # draws no hero, so the name collides with nothing here and was left rather
  # than moved with them. The drift is real and is written down at the site
  # because this is the file the next reader will be in: a device test that
  # addresses "the bell" by screen 01's name does not find this one.
  @doc false
  def header do
    {date, greeting} = Home.today()
    assigns = %{date: date, greeting: greeting}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Column weight={1.0}>
          <Text
            text={@date}
            text_size={11.5}
            font_weight="medium"
            text_color={Palette.tertiary()}
            max_lines={1}
          />
          <Spacer size={7} />
          <Text
            text={@greeting}
            text_size={26}
            max_font_scale={1.6}
            font_weight="bold"
            letter_spacing={Kati.Locale.tracking(-0.03)}
            text_color={:on_surface}
            max_lines={1}
          />
        </Column>
        {Home.disc("notifications", false, :open_inbox)}
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
          text={gettext("Search films, shows, events…")}
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
      {Kati.UI.eyebrow(@title, dash: Palette.rail_idle())}
      <Row fill_width={true} align="top">
        {UI.symbol("block", size: 17, color: Palette.tertiary())}
        <Spacer size={9} />
        <Column weight={1.0}>
          <Text text={@lead} text_size={12.5} line_height={1.55} text_color={Palette.ink_soft()} />
          <Text
            text={@emphasis}
            text_size={12.5}
            line_height={1.55}
            font_weight="semibold"
            text_color={Palette.ink()}
          />
          <Text text={@tail} text_size={12.5} line_height={1.55} text_color={Palette.ink_soft()} />
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
        {Kati.Screens.HomeOmittedSections.card("restaurant", gettext("Meals"), gettext("Dinner %{at}", at: Kati.Locale.time(~T[19:30:00])))}
        <Spacer size={11} />
        {Kati.Screens.HomeOmittedSections.card("bolt", gettext("Habits"), ngettext("%{n} left today", "%{n} left today", 2, n: Kati.Locale.number(2)))}
      </Row>
      <Spacer size={11} />
      <Row fill_width={true} align="top">
        {Kati.Screens.HomeOmittedSections.card("tune", gettext("Settings"), nil)}
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
      <Text
        text={@title}
        text_size={13.5}
        font_weight="semibold"
        text_color={:on_surface}
        max_lines={1}
      />
      {Kati.Screens.HomeOmittedSections.line(@line)}
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
      <Text text={@text} text_size={11.5} text_color={Palette.sub()} max_lines={1} />
    </Column>
    """
  end

  @doc false
  def footnote do
    ~MOB"""
    <Row fill_width={true} background={Palette.cream()} corner_radius={16} padding={13} align="top">
      {UI.symbol("info", size: 17, color: Palette.sub())}
      <Spacer size={9} />
      <Column weight={1.0}>
        <Text
          text={gettext("A section with nothing in it is omitted rather than worded empty — but ")}
          text_size={12}
          line_height={1.5}
          text_color={Palette.ink_soft()}
        />
        <Text
          text={gettext("Rest of today")}
          text_size={12}
          line_height={1.5}
          font_weight="semibold"
          text_color={Palette.ink()}
        />
        <Text
          text={gettext(" always stays, because the calendar does not depend on sections and *nothing today* is itself a piece of news.")}
          text_size={12}
          line_height={1.5}
          text_color={Palette.ink_soft()}
        />
        <Text
          text={gettext("The decision is the same in English.")}
          text_size={12}
          line_height={1.5}
          text_color={Palette.ink_soft()}
        />
      </Column>
    </Row>
    """
  end

  def handle_info({:tap, :open_search}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Search)}

  def handle_info({:tap, :open_inbox}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Inbox)}

  # The dock. `Kati.Screens.Root`'s shared `root_*` clause is not available
  # here — this page hand-rolls its mount so it can pin nothing — so the four
  # tabs are answered through `Kati.Shell.screen_for/1`, which reads the
  # reader's own locale. mishka-group/kati#103.
  def handle_info({:tap, :fab}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.AddTitle)}

  def handle_info({:tap, tag}, socket) do
    case Atom.to_string(tag) do
      "root_home" ->
        {:noreply, socket}

      "root_" <> id ->
        {:noreply,
         Mob.Socket.reset_to(socket, Kati.Shell.screen_for(String.to_existing_atom(id)))}

      _other ->
        {:noreply, socket}
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}
end
