defmodule Kati.Screens.Discover do
  @moduledoc """
  Screen 11 — Discover, pushed under Library.

  Built to `.scratch/design/screens/11.html`: a chip row, a three-poster rail
  of matches, a card of people you follow, and the titles about to leave a
  service.

  Two of the three sections are recommendations and one is a deadline, and the
  design marks the difference with the eyebrow dash rather than with a
  different layout. "Because you watched" and "People you follow" get the
  orange dash because something is new; "Leaving Lumen+ in 7 days" gets the
  grey one, because a thing disappearing is not a thing arriving. That is
  `Kati.UI.Eyebrow.quiet/1`.

  A person's row ends in an orange dot when they have news and a muted `check`
  when they do not — the same distinction, at row scale, and the reason the
  sample carries someone with nothing new.

  The rail is three 112pt posters with 12pt gutters: 112*3 + 12*2 = 360, which
  is the content width inside the 21pt margins, so the drawing's row is exactly
  full rather than scrolled.
  """
  use Kati.Screens.Pushed, back: "Library"

  alias Kati.Screens.Discover.Sample
  alias Kati.Theme
  alias Kati.UI

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :feed, Sample.feed())

  @doc false
  def content(assigns) do
    f = assigns.feed

    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={40}>
        {Kati.Screens.Discover.pill_row()}
        {Kati.Screens.Discover.header(f)}
        {Kati.Screens.Discover.chips(f)}
        {UI.eyebrow(f.because)}
        {Kati.Screens.Discover.rail(f)}
        {UI.eyebrow("People you follow")}
        {Kati.Screens.Discover.people(f)}
        {Kati.UI.Eyebrow.quiet(f.leaving_label)}
        {Kati.Screens.Discover.leaving(f)}
      </Column>
    </Scroll>
    """
  end

  # The drawing gives the back pill a row of its own — 42pt tall with 16pt
  # under it — before the title. Kati.Screens.Pushed floats the pill, so this
  # reserves the space it occupies rather than drawing a second one.
  @doc false
  def pill_row, do: ~MOB"<Spacer size={58} />"

  @doc false
  def header(f) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column weight={1.0}>
          <Text text="Discover" text_size={28} font_weight="bold" letter_spacing={-0.03} text_color={:on_surface} />
          <Spacer size={5} />
          <Text text={f.subtitle} font_family="mono" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
        </Column>
        <Spacer size={9} />
        <Box
          width={44}
          height={44}
          corner_radius={22}
          background={Kati.Theme.card(:light)}
          shadow={Kati.Theme.shadow_button()}
          align="center"
        >
          {Kati.UI.symbol("tune", size: 21)}
        </Box>
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def chips(f) do
    ~MOB"""
    <Column fill_width={true}>
      <Scroll axis="horizontal">
        <Row align="center">
          {f.chips |> Enum.map(&Kati.Screens.Discover.chip/1) |> Enum.intersperse(Kati.Screens.Discover.chip_gap())}
        </Row>
      </Scroll>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def chip_gap, do: ~MOB"<Spacer size={7} />"

  @doc false
  def chip(c) do
    bg = if c.selected, do: Theme.ink(), else: Theme.card(:light)
    fg = if c.selected, do: 0xFFFBFAF8, else: 0xFF5C574F

    ~MOB"""
    <Row height={32} corner_radius={16} background={bg} padding_left={14} padding_right={14} align="center">
      <Text text={c.label} text_size={12.5} font_weight="semibold" text_color={fg} max_lines={1} />
      {Kati.Screens.Discover.chip_count(c.count, c.selected)}
    </Row>
    """
  end

  # The count rides at .6 of the label's own colour rather than a token of its
  # own, so it stays a shade of the chip it sits on in either state.
  @doc false
  def chip_count(nil, _selected), do: ~MOB"<Spacer size={0} />"

  def chip_count(count, selected) do
    fg = if selected, do: 0x99FBFAF8, else: 0x995C574F

    ~MOB"""
    <Row align="center">
      <Spacer size={6} />
      <Text text={count} font_family="mono" text_size={10.5} text_color={fg} max_lines={1} />
    </Row>
    """
  end

  @doc false
  def rail(f) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {f.picks |> Enum.map(&Kati.Screens.Discover.pick/1) |> Enum.intersperse(Kati.Screens.Discover.rail_gap())}
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def rail_gap, do: ~MOB"<Spacer size={12} />"

  @doc false
  def pick(p) do
    ~MOB"""
    <Column width={112}>
      <Box width={112} height={158} corner_radius={13} background={0xFFE4E0D9} shadow={Kati.Theme.shadow_card_soft()}>
        {Kati.Screens.Discover.poster(p.seed)}
      </Box>
      <Spacer size={9} />
      <Text text={p.title} text_size={12.5} font_weight="bold" text_color={:on_surface} max_lines={1} />
      <Spacer size={3} />
      <Text text={p.match} font_family="mono" text_size={10.5} text_color={0xFFE8823C} max_lines={1} />
    </Column>
    """
  end

  @doc false
  def poster(seed) do
    case Sample.image(seed) do
      nil ->
        ~MOB"<Spacer size={0} />"

      src ->
        ~MOB"""
        <Image src={src} width={112} height={158} corner_radius={13} content_mode="fill" />
        """
    end
  end

  @doc false
  def people(f) do
    last = length(f.people) - 1

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Kati.Theme.card(:light)}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={15}
        padding_right={15}
        padding_top={4}
        padding_bottom={4}
      >
        {f.people
         |> Enum.with_index()
         |> Enum.map(fn {row, i} -> Kati.Screens.Discover.person_row(row, i < last) end)}
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def person_row(p, rule?) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={13} padding_bottom={13}>
        {Kati.Screens.Discover.face(p.seed)}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text text={p.name} text_size={13.5} font_weight="semibold" text_color={:on_surface} max_lines={1} />
          <Spacer size={3} />
          <Text text={p.line} text_size={11.5} text_color={0xFF8A8479} max_lines={1} />
        </Column>
        <Spacer size={13} />
        {Kati.Screens.Discover.person_mark(p.new?)}
      </Row>
      {Kati.Screens.Discover.hairline(rule?)}
    </Column>
    """
  end

  @doc false
  def face(seed) do
    case Sample.image(seed) do
      nil ->
        ~MOB"<Box width={38} height={38} corner_radius={19} background={0xFFE4E0D9} />"

      src ->
        ~MOB"""
        <Image src={src} width={38} height={38} corner_radius={19} content_mode="fill" />
        """
    end
  end

  @doc false
  def person_mark(true), do: ~MOB"<Box width={8} height={8} corner_radius={4} background={0xFFE8823C} />"
  def person_mark(false), do: Kati.UI.symbol("check", size: 18, color: 0xFFC4BDB3)

  @doc false
  def leaving(f) do
    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(f.leaving, fn row -> Kati.Screens.Discover.leaving_row(row) end)}
    </Column>
    """
  end

  @doc false
  def leaving_row(row) do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Kati.Theme.card(:light)}
        corner_radius={18}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={13}
        padding_right={13}
        padding_top={10}
        padding_bottom={10}
        align="center"
      >
        {Kati.Screens.Discover.thumb(row.seed)}
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text text={row.title} text_size={13.5} font_weight="bold" text_color={:on_surface} max_lines={1} />
          <Spacer size={4} />
          <Text text={row.line} text_size={11.5} text_color={0xFF8A8479} max_lines={1} />
        </Column>
        <Spacer size={12} />
        <Row height={30} corner_radius={15} background={Kati.Theme.ink()} padding_left={13} padding_right={13} align="center">
          <Text text={row.action} text_size={11.5} font_weight="semibold" text_color={0xFFFBFAF8} max_lines={1} />
        </Row>
      </Row>
      <Spacer size={9} />
    </Column>
    """
  end

  @doc false
  def thumb(seed) do
    case Sample.image(seed) do
      nil ->
        ~MOB"<Box width={40} height={56} corner_radius={8} background={0xFFE4E0D9} />"

      src ->
        ~MOB"""
        <Image src={src} width={40} height={56} corner_radius={8} content_mode="fill" />
        """
    end
  end

  @doc false
  def hairline(false), do: ~MOB"<Spacer size={0} />"
  def hairline(true), do: ~MOB"<Box fill_width={true} height={1} background={0x121A1917} />"
end
