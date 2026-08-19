defmodule Kati.Screens.Accessibility do
  @moduledoc """
  Screen 41 — Accessibility, pushed under Settings.

  Built to `.scratch/design/screens/41.html`. The design's caption calls it
  "the spec drawn rather than described", and that is exactly what it is: the
  Up next card rendered at 235% Dynamic Type so the claim "nothing truncates"
  can be checked by looking, the six guarantees as a switch list, and the
  sentence VoiceOver speaks on an episode row printed on ink.

  At that size the buttons are 60pt tall and carry both a glyph and a word —
  the drawing's own demonstration of "icon-only buttons grow labels".

  The **VoiceOver reads** eyebrow takes the muted `#C4BDB3` dash rather than
  the accent one, because it is a quotation rather than a section you act on;
  `Kati.UI.eyebrow/2` always draws the accent dash, so `quiet_eyebrow/1` here
  is the muted variant.

  No dock, so the frame's bottom inset is 40 rather than 132.
  """
  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.Accessibility.Sample
  alias Kati.UI

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :spec, Sample.spec())

  @doc false
  def content(assigns) do
    spec = assigns.spec

    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={40}>
        {Kati.Screens.Accessibility.header()}
        {Kati.Screens.Accessibility.title(spec)}
        {Kati.Screens.Accessibility.up_next(spec)}
        {Kati.Screens.Accessibility.note(spec)}
        {UI.eyebrow("Built in")}
        {Kati.Screens.Accessibility.built_in(spec)}
        {Kati.Screens.Accessibility.quiet_eyebrow("VoiceOver reads")}
        {Kati.Screens.Accessibility.voiceover(spec)}
      </Column>
    </Scroll>
    """
  end

  # 44pt reserves the row the back pill floats in — the pill is drawn by
  # Kati.Screens.Pushed — so the overflow disc sits opposite it.
  @doc false
  def header do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} height={44} align="center">
        <Spacer weight={1.0} />
        <Box
          width={44}
          height={44}
          corner_radius={22}
          background={Kati.Theme.card(:light)}
          shadow={Kati.Theme.shadow_button()}
          align="center"
        >
          {Kati.UI.symbol("more_horiz", size: 21)}
        </Box>
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc false
  def title(spec) do
    ~MOB"""
    <Column fill_width={true}>
      <Text text="Accessibility" text_size={28} font_weight="bold" letter_spacing={-0.03} text_color={:on_surface} />
      <Spacer size={5} />
      <Text text={spec.subtitle} font_family="mono" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
      <Spacer size={20} />
    </Column>
    """
  end

  @doc "The muted eyebrow: the design's `#C4BDB3` dash instead of the accent."
  def quiet_eyebrow(label) do
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
          max_lines={1}
        />
      </Row>
      <Spacer size={11} />
    </Column>
    """
  end

  # No max_lines anywhere in this card: the whole demonstration is that text
  # wraps and the card grows rather than the words being cut.
  @doc false
  def up_next(spec) do
    u = spec.up_next

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Kati.Theme.card(:light)}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={18}
      >
        <Text
          text={String.upcase(u.label)}
          font_family="mono"
          text_size={12}
          letter_spacing={0.16}
          text_color={0xFFA0998F}
        />
        <Spacer size={12} />
        <Text
          text={u.title}
          text_size={30}
          font_weight="bold"
          letter_spacing={-0.02}
          line_height={1.2}
          text_color={:on_surface}
        />
        <Spacer size={10} />
        <Text text={u.lines} text_size={22} line_height={1.35} text_color={0xFF5C574F} />
        <Spacer size={18} />
        <Box fill_width={true} height={60} corner_radius={30} background={Kati.Theme.ink()} align="center">
          <Row align="center">
            {Kati.UI.symbol("play_arrow", size: 26, color: 0xFFFBFAF8, fill: true)}
            <Spacer size={10} />
            <Text text={u.resume} text_size={19} font_weight="bold" text_color={0xFFFBFAF8} />
          </Row>
        </Box>
        <Spacer size={10} />
        <Box fill_width={true} height={60} corner_radius={30} background={0xFFEFECE7} align="center">
          <Row align="center">
            {Kati.UI.symbol("check", size: 24)}
            <Spacer size={10} />
            <Text text={u.mark} text_size={19} font_weight="bold" text_color={:on_surface} />
          </Row>
        </Box>
      </Column>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def note(spec) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} background={0xFFFBF1DE} corner_radius={18} padding={15} align="top">
        {Kati.UI.symbol("info", size: 18, color: 0xFFC98A3E)}
        <Spacer size={11} />
        <Text
          text={spec.note}
          text_size={12.5}
          line_height={1.55}
          text_color={0xFF4A4238}
          weight={1.0}
        />
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def built_in(spec) do
    rows = spec.built_in
    last = length(rows) - 1

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
        {rows
         |> Enum.with_index()
         |> Enum.map(fn {row, i} -> Kati.Screens.Accessibility.row(row, i < last) end)}
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def row(row, rule?) do
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
        {Kati.Screens.Accessibility.toggle(row.toggle)}
      </Row>
      {Kati.Screens.Accessibility.hairline(rule?)}
    </Column>
    """
  end

  @doc """
  The design's own switch, drawn rather than delegated.

  46x28 with a 22pt thumb and a 3pt inset. The 40pt inner row produces that
  inset without mixing `padding` and an explicit `width` on one node, which in
  this bridge inflates the node instead of insetting it.
  """
  def toggle(on?) do
    track = if on?, do: Kati.Theme.ink(), else: 0xFFDCD7CF

    ~MOB"""
    <Box width={46} height={28} corner_radius={14} background={track} align="center">
      <Row width={40} align="center">
        {Kati.Screens.Accessibility.thumb_lead(on?)}
        <Box width={22} height={22} corner_radius={11} background={0xFFFBFAF8} shadow="0 1 3 0 #4D1A1917" />
        {Kati.Screens.Accessibility.thumb_trail(on?)}
      </Row>
    </Box>
    """
  end

  @doc false
  def thumb_lead(true), do: ~MOB"<Spacer weight={1.0} />"
  def thumb_lead(false), do: ~MOB"<Spacer size={0} />"

  @doc false
  def thumb_trail(true), do: ~MOB"<Spacer size={0} />"
  def thumb_trail(false), do: ~MOB"<Spacer weight={1.0} />"

  @doc false
  def voiceover(spec) do
    v = spec.voiceover

    ~MOB"""
    <Column fill_width={true} background={Kati.Theme.ink()} corner_radius={20} padding={17}>
      <Text
        text={v.label}
        font_family="mono"
        text_size={10}
        letter_spacing={0.14}
        text_color={0xFF6A6560}
        max_lines={1}
      />
      <Spacer size={10} />
      <Text text={v.reads} text_size={13.5} line_height={1.6} text_color={0xFFF5F2EE} />
    </Column>
    """
  end

  @doc false
  def hairline(false), do: ~MOB"<Spacer size={0} />"
  def hairline(true), do: ~MOB"<Box fill_width={true} height={1} background={0x121A1917} />"
end
