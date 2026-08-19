defmodule Kati.Screens.WhatFits do
  @moduledoc """
  Screen 13 — What fits?, pushed under Library.

  Built to `.scratch/design/screens/13.html`: a cream card carrying the window
  of time you actually have, then the episodes that fit inside it, then the
  nearest thing that does not.

  Cream is doing the same job here as on Home and on screen 08 — it marks the
  one block that is *yours* rather than the library's. The window is an input,
  not a statistic, so its buttons sit on `rgba(255,255,255,.6)` wells inside the
  cream instead of on cards of their own.

  The last section is the honest half of the feature: the design labels it
  `Nothing else fits — nearest film is 1h 46m` under a **grey** dash, and draws
  the row flat on `#F4F1EC` with a `Tomorrow` button. Telling the user what was
  excluded, and offering to move it rather than hiding it, is why the screen is
  worth having; a filter that silently drops things is just a shorter list.

  The five window buttons are `flex:1` in the drawing, so each is a
  `Box weight={1.0}`; the four mood chips hug their labels, so they are Rows.
  """
  use Kati.Screens.Pushed, back: "Library"

  alias Kati.Screens.WhatFits.Sample
  alias Kati.Theme
  alias Kati.UI

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :tonight, Sample.tonight())

  @doc false
  def content(assigns) do
    t = assigns.tonight

    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={40}>
        {Kati.Screens.WhatFits.more_row()}
        {Kati.Screens.WhatFits.header(t)}
        {Kati.Screens.WhatFits.window(t)}
        {UI.eyebrow(t.fits_label)}
        {Kati.Screens.WhatFits.fits(t)}
        {Kati.UI.Eyebrow.quiet(t.over_label)}
        {Kati.Screens.WhatFits.over(t)}
      </Column>
    </Scroll>
    """
  end

  # The back pill is Kati.Screens.Pushed's, floating at the left. This row
  # reserves its height and carries the overflow disc opposite it.
  @doc false
  def more_row do
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
  def header(t) do
    ~MOB"""
    <Column fill_width={true}>
      <Text text="What fits?" text_size={28} font_weight="bold" letter_spacing={-0.03} text_color={:on_surface} />
      <Spacer size={5} />
      <Text text={t.now} font_family="mono" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def window(t) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={0xFFFBF1DE}
        corner_radius={24}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={19}
      >
        <Text
          text={String.upcase("Time you have")}
          font_family="mono"
          text_size={10.5}
          letter_spacing={0.16}
          text_color={0xFFB09A72}
        />
        <Spacer size={8} />
        <Text text={t.window} text_size={40} font_weight="extrabold" letter_spacing={-0.04} text_color={:on_surface} />
        <Spacer size={16} />
        <Row fill_width={true} align="center">
          {t.lengths
           |> Enum.map(&Kati.Screens.WhatFits.length_button/1)
           |> Enum.intersperse(Kati.Screens.WhatFits.gap())}
        </Row>
        <Spacer size={10} />
        <Row fill_width={true} align="center">
          {t.moods
           |> Enum.map(&Kati.Screens.WhatFits.mood_chip/1)
           |> Enum.intersperse(Kati.Screens.WhatFits.gap())}
        </Row>
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def gap, do: ~MOB"<Spacer size={6} />"

  @doc false
  def length_button(l) do
    bg = if l.selected, do: Theme.ink(), else: 0x99FFFFFF
    fg = if l.selected, do: 0xFFFBFAF8, else: 0xFF8A7B60

    ~MOB"""
    <Box weight={1.0}>
      <Box fill_width={true} height={36} corner_radius={12} background={bg} align="center">
        <Text text={l.label} text_size={12.5} font_weight="semibold" text_color={fg} max_lines={1} />
      </Box>
    </Box>
    """
  end

  # The chosen mood is `rgba(232,130,60,.18)` with a bronze label rather than
  # solid ink: a mood is a preference, not a commitment, so the design gives it
  # a tint where it gives the runtime a fill.
  @doc false
  def mood_chip(m) do
    bg = if m.selected, do: 0x2EE8823C, else: 0x99FFFFFF
    fg = if m.selected, do: 0xFF96723C, else: 0xFF8A7B60

    ~MOB"""
    <Row height={28} corner_radius={14} background={bg} padding_left={11} padding_right={11} align="center">
      <Text text={m.label} text_size={11.5} font_weight="semibold" text_color={fg} max_lines={1} />
    </Row>
    """
  end

  @doc false
  def fits(t) do
    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(t.fits, fn row -> Kati.Screens.WhatFits.fit_row(row) end)}
      <Spacer size={13} />
    </Column>
    """
  end

  @doc false
  def fit_row(row) do
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
        {Kati.Screens.WhatFits.thumb(row.seed)}
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text text={row.title} text_size={13.5} font_weight="bold" text_color={:on_surface} max_lines={1} />
          <Spacer size={4} />
          <Text text={row.meta} font_family="mono" text_size={10.5} text_color={0xFFA9A29A} max_lines={1} />
        </Column>
        <Spacer size={12} />
        <Text text={row.run} font_family="mono" text_size={12} font_weight="medium" text_color={:on_surface} max_lines={1} />
      </Row>
      <Spacer size={9} />
    </Column>
    """
  end

  @doc false
  def over(t) do
    row = t.over

    ~MOB"""
    <Row
      fill_width={true}
      background={0xFFF4F1EC}
      corner_radius={18}
      padding_left={13}
      padding_right={13}
      padding_top={10}
      padding_bottom={10}
      align="center"
    >
      {Kati.Screens.WhatFits.thumb(row.seed)}
      <Spacer size={12} />
      <Column weight={1.0}>
        <Text text={row.title} text_size={13.5} font_weight="semibold" text_color={0xFF5C574F} max_lines={1} />
        <Spacer size={4} />
        <Text text={row.meta} font_family="mono" text_size={10.5} text_color={0xFFB3ACA2} max_lines={1} />
      </Column>
      <Spacer size={12} />
      <Row height={30} corner_radius={15} background={0xFFE4E0D9} padding_left={12} padding_right={12} align="center">
        <Text text={row.action} text_size={11.5} font_weight="semibold" text_color={0xFF5C574F} max_lines={1} />
      </Row>
    </Row>
    """
  end

  @doc false
  def thumb(seed) do
    case Sample.poster(seed) do
      nil ->
        ~MOB"<Box width={40} height={56} corner_radius={8} background={0xFFE4E0D9} />"

      src ->
        ~MOB"""
        <Image src={src} width={40} height={56} corner_radius={8} content_mode="fill" />
        """
    end
  end
end
