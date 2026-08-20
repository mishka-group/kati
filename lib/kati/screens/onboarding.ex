defmodule Kati.Screens.Onboarding do
  @moduledoc """
  Screen 38 — Onboarding, steps 1, 3 and 4.

  Built to `.scratch/design/screens/38.html`, which draws all three steps in
  one frame separated by hairlines rather than three frames side by side. This
  screen renders exactly that: one scroll, three sections, a divider between
  them. It is the drawing, so it is what gets built — the flow that shows one
  step at a time is a later job for whatever pushes this screen, and splitting
  it now would mean nothing could be compared against the export.

  There is no back pill and no dock: the drawing has neither, and each step
  carries its own way out (**Get started**, **Finish setup**, **Skip**). The
  frame's bottom inset is therefore 40, not 132.

  ## The selection ring is drawn inside its tile

  The design outlines the chosen poster with `outline: 2.5px solid #1A1917;
  outline-offset: 2px` — an outline, which in CSS costs no layout and simply
  overhangs the tile. Compose has no such thing: a border is part of the box.
  Two tiles and an 11pt gap already use the whole width between the gutters, so
  a ring drawn *outside* would push the row past the content width and squeeze
  both columns. It is therefore drawn on the tile's own edge with the artwork
  inset 4pt inside it, which reads as the same selection ring and keeps the
  grid on its arithmetic.

  The cell itself is a weight, not the drawing's 174: the export's own width is
  `calc(50% - 6px)`, and half of the 411dp device's content is 179, so a fixed
  174 would leave the second column 10pt short of the right gutter. The height
  is the export's own `aspect-ratio:2/3` rather than a number, so the tile
  stays 2:3 at whatever width the weight grants.
  """
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Onboarding.Sample

  def mount(_params, _session, socket) do
    Mob.Theme.set(Kati.Theme.light())
    {:ok, Mob.Socket.assign(socket, :flow, Sample.flow())}
  end

  def render(assigns) do
    flow = assigns.flow

    ~MOB"""
    <Box fill_width={true} fill_height={true} background={:background} layout_direction={Kati.Locale.direction_prop()}>
      <Scroll>
        <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={40}>
          {Kati.Screens.Onboarding.welcome(flow.welcome)}
          {Kati.Screens.Onboarding.divider()}
          {Kati.Screens.Onboarding.telling(flow.telling)}
          {Kati.Screens.Onboarding.divider()}
          {Kati.Screens.Onboarding.first_title(flow.first_title)}
        </Column>
      </Scroll>
    </Box>
    """
  end

  @doc false
  def welcome(w) do
    ~MOB"""
    <Column fill_width={true} padding_top={26}>
      {Kati.Screens.Onboarding.steps(1)}
      <Box width={56} height={56} corner_radius={18} background={Kati.Theme.ink()} align="center">
        <Box width={13} height={13} corner_radius={7} background={Kati.Theme.accent()} />
      </Box>
      <Spacer size={20} />
      <Text
        text={w.title}
        text_size={32}
        font_weight="extrabold"
        letter_spacing={-0.035}
        line_height={1.12}
        text_color={:on_surface}
      />
      <Spacer size={14} />
      <Text text={w.body} text_size={14.5} line_height={1.6} text_color={0xFF5C574F} />
      <Spacer size={24} />
      <Box fill_width={true} height={54} corner_radius={27} background={Kati.Theme.ink()} align="center">
        <Text text={w.cta} text_size={14.5} font_weight="bold" text_color={0xFFFBFAF8} max_lines={1} />
      </Box>
    </Column>
    """
  end

  # Four segments, `done` of them filled. The bar says which step you are on
  # without a "3 of 4" anyone has to read.
  @doc false
  def steps(done) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {1..4
         |> Enum.map(fn i -> Kati.Screens.Onboarding.step_bar(i <= done) end)
         |> Enum.intersperse(Kati.Screens.Onboarding.step_gap())}
      </Row>
      <Spacer size={24} />
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
  def divider do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={30} />
      <Box fill_width={true} height={1} background={0x1A1A1917} />
      <Spacer size={30} />
    </Column>
    """
  end

  @doc false
  def telling(t) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.Onboarding.steps(3)}
      <Text
        text={t.title}
        text_size={26}
        font_weight="extrabold"
        letter_spacing={-0.035}
        line_height={1.15}
        text_color={:on_surface}
      />
      <Spacer size={10} />
      <Text text={t.body} text_size={13.5} line_height={1.55} text_color={0xFF5C574F} />
      <Spacer size={18} />
      {t.options
       |> Enum.map(fn option -> Kati.Screens.Onboarding.option(option) end)
       |> Enum.intersperse(Kati.Screens.Onboarding.option_gap())}
    </Column>
    """
  end

  @doc false
  def option_gap, do: ~MOB"<Spacer size={10} />"

  # The chosen option inverts to ink and carries an accent tick, so the answer
  # is legible without comparing three cards' backgrounds.
  @doc false
  def option(%{selected?: true} = option) do
    ~MOB"""
    <Row
      fill_width={true}
      background={Kati.Theme.ink()}
      corner_radius={20}
      shadow="0 12 24 -14 #E61A1917"
      padding={15}
      align="center"
    >
      {Kati.UI.symbol(option.icon, size: 21, color: 0xFFFBFAF8)}
      <Spacer size={13} />
      <Column weight={1.0}>
        <Text text={option.title} text_size={14} font_weight="bold" text_color={0xFFFBFAF8} max_lines={1} />
        <Spacer size={3} />
        <Text text={option.sub} text_size={11.5} text_color={0x99FBFAF8} max_lines={1} />
      </Column>
      <Spacer size={13} />
      <Box width={22} height={22} corner_radius={11} background={Kati.Theme.accent()} align="center">
        {Kati.UI.symbol("check", size: 14, color: 0xFFFBFAF8)}
      </Box>
    </Row>
    """
  end

  def option(option) do
    ~MOB"""
    <Row
      fill_width={true}
      background={Kati.Theme.card(:light)}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={15}
      align="center"
    >
      {Kati.UI.symbol(option.icon, size: 21, color: 0xFF8A8479)}
      <Spacer size={13} />
      <Column weight={1.0}>
        <Text text={option.title} text_size={14} font_weight="bold" text_color={:on_surface} max_lines={1} />
        <Spacer size={3} />
        <Text text={option.sub} text_size={11.5} text_color={0xFF8A8479} max_lines={1} />
      </Column>
    </Row>
    """
  end

  # Two across. 174*2 + 11 = 359, the content width between the 21pt gutters,
  # which is the design's own `calc(50% - 6px)` with an 11pt gap.
  @doc false
  def first_title(f) do
    rows = Enum.chunk_every(f.posters, 2)

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.Onboarding.steps(4)}
      <Text
        text={f.title}
        text_size={26}
        font_weight="extrabold"
        letter_spacing={-0.035}
        line_height={1.15}
        text_color={:on_surface}
      />
      <Spacer size={10} />
      <Text text={f.body} text_size={13.5} line_height={1.55} text_color={0xFF5C574F} />
      <Spacer size={18} />
      {Enum.map(rows, fn row -> Kati.Screens.Onboarding.poster_row(row) end)}
      <Spacer size={9} />
      <Box fill_width={true} height={52} corner_radius={26} background={Kati.Theme.ink()} align="center">
        <Text text={f.cta} text_size={14} font_weight="bold" text_color={0xFFFBFAF8} max_lines={1} />
      </Box>
      <Spacer size={14} />
      <Text
        text={f.skip}
        text_size={13}
        font_weight="semibold"
        text_color={0xFF8A8479}
        text_align="center"
      />
    </Column>
    """
  end

  @doc false
  def poster_row(row) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {row
         |> Enum.map(fn poster -> Kati.Screens.Onboarding.poster(poster) end)
         |> Enum.intersperse(Kati.Screens.Onboarding.poster_gap())}
      </Row>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc false
  def poster_gap, do: ~MOB"<Spacer size={11} />"

  # The cell takes a weight, not a width. 174 was the drawing's own number at
  # 402pt; on the 411dp device the same two tiles plus the 11pt gap come to 359
  # of the 369 between the gutters and the grid stops short of the right one.
  # The tile's height is `aspect_ratio` — the export's own `aspect-ratio:2/3` —
  # so it follows whatever width the weight hands out, at any frame width.
  @doc false
  def poster(p) do
    ~MOB"""
    <Column weight={1.0}>
      {Kati.Screens.Onboarding.poster_art(p)}
      <Spacer size={8} />
      <Text text={p.title} text_size={12.5} font_weight="bold" text_color={:on_surface} max_lines={1} />
    </Column>
    """
  end

  @doc false
  def poster_art(%{selected?: true} = p) do
    ~MOB"""
    <Box
      fill_width={true}
      aspect_ratio={0.6667}
      corner_radius={17}
      border_color={0xFF1A1917}
      border_width={2.5}
    >
      <Column fill_width={true} fill_height={true} padding={4}>
        <Box
          fill_width={true}
          fill_height={true}
          corner_radius={13}
          background={0xFFE4E0D9}
          shadow={Kati.Theme.shadow_card_soft()}
        >
          {Kati.Screens.Onboarding.art(p)}
          <Box fill_width={true} fill_height={true} align="top_trailing">
            <Column padding={9}>
              <Box width={24} height={24} corner_radius={12} background={Kati.Theme.accent()} align="center">
                {Kati.UI.symbol("check", size: 15, color: 0xFFFBFAF8)}
              </Box>
            </Column>
          </Box>
        </Box>
      </Column>
    </Box>
    """
  end

  def poster_art(p) do
    ~MOB"""
    <Box
      fill_width={true}
      aspect_ratio={0.6667}
      corner_radius={13}
      background={0xFFE4E0D9}
      shadow={Kati.Theme.shadow_card_soft()}
    >
      {Kati.Screens.Onboarding.art(p)}
    </Box>
    """
  end

  @doc false
  def art(p) do
    case Kati.Design.Images.poster(p.seed) do
      nil ->
        ~MOB"<Spacer size={0} />"

      src ->
        ~MOB"""
        <Image src={src} fill_width={true} fill_height={true} corner_radius={13} content_mode="fill" />
        """
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}
end
