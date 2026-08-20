defmodule Kati.Screens.Health do
  @moduledoc """
  Screen 42 — Health, pushed under Home.

  Built to `.scratch/design/screens/42.html`. The drawing says what it is in a
  dashed box at the bottom of itself: *"Health is a container, not a feature.
  Each tile is an independent section with its own shelf, calendar feed and
  home card."* Meals is not a top-level thing; it sits inside Health, which is
  itself a section that happens to hold others.

  That is why the grid draws two live tiles and four dashed ones side by side
  instead of hiding what is not built. Screen 03 makes the same move with Books
  and Music, and for the same reason: a grid with the unbuilt tiles removed
  would misrepresent the app's shape, while a dashed outline states the intent.

  Where this diverges from the export, and why:

    * **Dashed borders are drawn solid.** `border:1.5px dashed rgba(26,25,23,.14)`
      has no dashed equivalent on this bridge, so it is a 1.5pt solid edge at
      the same colour — the treatment `Kati.Screens.AddTitle` already uses for
      its by-hand row. The tile still reads as an outline against a filled one;
      it does not read as *provisional*, and that is a real loss.
    * **`1,480 / 2,100 kcal` is two runs on one baseline.** 34pt extrabold and
      16pt semibold in the drawing's single heading, so a `Row` aligned
      `bottom` rather than one `Text`.

  The tiles split the row by weight rather than by the drawing's literal 174.
  `calc(50% - 6px)` of the 360 the gutters leave *is* 174, but this bridge
  applies padding before width, so a `width={174}` tile carrying `padding={16}`
  measures 206 and the two columns stop matching. Weight is measured after the
  gap, which is the same arithmetic without the trap. Mob has no wrap
  primitive, so the two-across grid is still chunked by a declared count, the
  same as screen 03's posters.

  No dock on a pushed screen, so the frame ends at 40 rather than 132.
  """
  use Kati.Screens.Pushed, back: "Home"

  alias Kati.Health.Sample
  alias Kati.UI

  @doc false
  def content(_assigns) do
    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={40}>
        {Kati.Screens.Health.back_gap()}
        {Kati.Screens.Health.header()}
        {Kati.Screens.Health.eaten()}
        {Kati.Screens.Health.next_meal()}
        {UI.eyebrow("Sections")}
        {Kati.Screens.Health.sections()}
        {Kati.Screens.Health.container_note()}
      </Column>
    </Scroll>
    """
  end

  # `Kati.Screens.Pushed` floats the back pill over the content, so the content
  # leaves room for it: a 42pt pill and the drawing's 16pt gap under it.
  @doc false
  def back_gap, do: ~MOB"<Spacer size={58} />"

  @doc false
  def header do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column weight={1.0}>
          <Text text="Health" text_size={28} font_weight="bold" letter_spacing={-0.03} text_color={:on_surface} />
          <Spacer size={5} />
          <Text text={Kati.Health.Sample.day_line()} font_family="mono" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
        </Column>
        {Kati.Screens.Health.disc("tune", :open_filters)}
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def disc(icon, tag) do
    tap = {self(), tag}

    ~MOB"""
    <Box
      width={44}
      height={44}
      background={Kati.Theme.card(:light)}
      corner_radius={22}
      shadow={Kati.Theme.shadow_button()}
      align="center"
      on_tap={tap}
    >
      {Kati.UI.symbol(icon, size: 21)}
    </Box>
    """
  end

  @doc false
  def eaten do
    e = Sample.eaten()

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={0xFFFBF1DE}
        corner_radius={24}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={19}
      >
        <Row fill_width={true} align="bottom">
          <Column weight={1.0}>
            <Text text={String.upcase(e.label)} font_family="mono" text_size={10.5} letter_spacing={0.16} text_color={0xFFB09A72} />
            <Spacer size={7} />
            <Row align="bottom">
              <Text text={e.calories} text_size={34} font_weight="extrabold" letter_spacing={-0.04} text_color={:on_surface} max_lines={1} />
              <Text text={e.target} text_size={16} font_weight="semibold" text_color={0xFFB09A72} max_lines={1} />
            </Row>
          </Column>
          <Spacer size={12} />
          {Kati.Screens.Health.meals_pill(e.meals)}
        </Row>
        <Spacer size={16} />
        {Kati.Screens.Health.macro_bar(e.macros)}
        <Spacer size={11} />
        <Row fill_width={true} align="center">
          {Kati.Screens.Health.legend(e.macros)}
          <Spacer weight={1.0} />
          <Text text={e.grams} font_family="mono" text_size={10} text_color={0xFFB09A72} max_lines={1} />
        </Row>
      </Column>
      <Spacer size={14} />
    </Column>
    """
  end

  # Green at 16% on cream, the same pill screens 04 and 08 use for "done" —
  # three of five meals logged is progress, not an alert.
  @doc false
  def meals_pill(label) do
    ~MOB"""
    <Row height={28} corner_radius={14} background={0x294E9A73} padding_left={11} padding_right={11} align="center">
      {Kati.UI.symbol("check", size: 14, color: 0xFF3E8460)}
      <Spacer size={5} />
      <Text text={label} font_family="mono" text_size={11.5} font_weight="medium" text_color={0xFF3E8460} max_lines={1} />
    </Row>
    """
  end

  # One 9pt track carrying three weighted segments and no gaps, built the way
  # screen 07's breakdown bars are: heights declared on both the track and the
  # fills rather than inherited, because a fill_height child of a Row inside a
  # fixed Box is one indirection more than this bridge has ever been asked for.
  #
  # The drawing gets its rounded ends from `overflow:hidden` on the track. Mob
  # does not clip children, so the segments stay square and the ink one
  # overhangs the track's 4.5pt corner by a hair. Giving each segment its own
  # radius would be worse — it would open visible notches between them.
  @doc false
  def macro_bar(macros) do
    segments = Enum.map(macros, fn {_name, share, tone} -> macro_segment(share, tone) end)

    ~MOB"""
    <Box fill_width={true} height={9} corner_radius={4.5} background={0xFFEFECE7}>
      <Row fill_width={true}>
        {segments}
      </Row>
    </Box>
    """
  end

  @doc false
  def macro_segment(share, tone) do
    ~MOB"""
    <Box weight={share} height={9} background={tone} />
    """
  end

  @doc false
  def legend(macros) do
    keys =
      macros
      |> Enum.map(fn {name, _share, tone} -> legend_key(name, tone) end)
      |> Enum.intersperse(legend_gap())

    ~MOB"""
    <Row align="center">
      {keys}
    </Row>
    """
  end

  @doc false
  def legend_gap, do: ~MOB"<Spacer size={13} />"

  @doc false
  def legend_key(name, tone) do
    ~MOB"""
    <Row align="center">
      <Box width={7} height={7} corner_radius={2} background={tone} />
      <Spacer size={5} />
      <Text
        text={String.upcase(name)}
        font_family="mono"
        text_size={9.5}
        letter_spacing={0.08}
        text_color={0xFFA0998F}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc false
  def next_meal do
    m = Sample.next_meal()
    tap = {self(), :open_meals}

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Kati.Theme.card(:light)}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={16}
        align="center"
        on_tap={tap}
      >
        <Box width={36} height={36} corner_radius={12} background={0xFFEFECE7} align="center">
          {Kati.UI.symbol("restaurant", size: 19)}
        </Box>
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text text={m.title} text_size={14.5} font_weight="bold" letter_spacing={-0.015} text_color={:on_surface} max_lines={1} />
          <Spacer size={3} />
          <Text text={m.line} text_size={11.5} text_color={0xFF8A8479} max_lines={1} />
        </Column>
        <Spacer size={12} />
        {Kati.UI.symbol("chevron_right", size: 19, color: 0xFFC4BDB3)}
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  # Two across. 174*2 + 12 = 360, which is what the gutters leave — so the
  # declared chunk of two reproduces the wrap rather than approximating it, and
  # the tiles take that half by weight (see the moduledoc) rather than by a
  # literal 174 that padding would inflate.
  @doc false
  def sections do
    rows = Sample.sections() |> Enum.chunk_every(2)

    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(rows, fn row -> Kati.Screens.Health.tile_row(row) end)}
      <Spacer size={10} />
    </Column>
    """
  end

  @doc false
  def tile_row(row) do
    tiles =
      row
      |> Enum.map(&tile/1)
      |> Enum.intersperse(tile_gap())

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {tiles}
      </Row>
      <Spacer size={12} />
    </Column>
    """
  end

  @doc false
  def tile_gap, do: ~MOB"<Spacer size={12} />"

  @doc false
  def tile(%{on?: true} = section) do
    ~MOB"""
    <Column
      weight={1.0}
      background={Kati.Theme.card(:light)}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={16}
    >
      <Row fill_width={true} align="center">
        {Kati.UI.symbol(section.icon, size: 22)}
        <Spacer weight={1.0} />
        <Box width={7} height={7} corner_radius={4} background={section.dot} />
      </Row>
      <Spacer size={14} />
      <Text text={section.name} text_size={14.5} font_weight="bold" letter_spacing={-0.02} text_color={:on_surface} max_lines={1} />
      <Spacer size={4} />
      <Text text={section.line} text_size={11} text_color={0xFF8A8479} max_lines={1} />
    </Column>
    """
  end

  # No dot, no fill, no shadow: an unbuilt section is an outline. The drawing
  # dashes that outline and this bridge cannot, so it is solid at the same
  # 1.5pt and the same rgba(26,25,23,.14).
  def tile(%{on?: false} = section) do
    ~MOB"""
    <Column
      weight={1.0}
      corner_radius={20}
      border_width={1.5}
      border_color={0x241A1917}
      padding={16}
    >
      <Row fill_width={true} align="center">
        {Kati.UI.symbol(section.icon, size: 22, color: 0xFFB3ACA2)}
      </Row>
      <Spacer size={14} />
      <Text text={section.name} text_size={14.5} font_weight="bold" letter_spacing={-0.02} text_color={0xFFA9A29A} max_lines={1} />
      <Spacer size={4} />
      <Text text={section.line} text_size={11} text_color={0xFFC4BDB3} max_lines={1} />
    </Column>
    """
  end

  @doc false
  def container_note do
    ~MOB"""
    <Row
      fill_width={true}
      corner_radius={18}
      border_width={1.5}
      border_color={0x291A1917}
      padding={15}
      align="top"
    >
      {Kati.UI.symbol("info", size: 17, color: 0xFF8A8479)}
      <Spacer size={11} />
      <Text
        text={Kati.Health.Sample.container_note()}
        text_size={12.5}
        line_height={1.55}
        text_color={0xFF5C574F}
        weight={1.0}
      />
    </Row>
    """
  end
end
