defmodule Kati.Screens.Language do
  @moduledoc """
  Screen 54 — Language, pushed under Settings.

  Built to `.scratch/design/screens/54.html`. The design's caption states the
  idea: *"language is one switch that carries five settings with it, each still
  overridable. The row that matters most is the last one: nothing you typed
  yourself ever gets rewritten."*

  Three parts, in that order of consequence: the picker, the five settings the
  choice drags along, and then Content — which is a footnote to the language
  rather than a peer of it, so its eyebrow takes the grey dash from
  `Kati.UI.SettingsList.eyebrow_muted/1` and not the accent one.

  ## Persian rows are drawn in Vazirmatn

  `فا`, `فارسی` and `ایران` are the picker's own copy, and two rows below mix
  Persian into an English sentence. Plus Jakarta Sans carries neither Arabic
  glyphs nor Arabic-Indic digits, so those five strings take
  `font_family="fa"` — Vazirmatn, which Kati ships at 400–800 and which covers
  Latin as well, so the English half of a mixed line still reads. The rows
  carry `script: :fa` in `Kati.Language.Sample` rather than the screen
  guessing from the characters.

  This is only the picker. `Kati.Locale` owns the active locale and its
  direction, and this screen will set it rather than duplicate it.

  No dock — this is a pushed screen — so the frame closes at 40, not 132. The
  header is the back pill alone, with nothing opposite it, so the chrome row
  reserves the pill's height and draws no disc.
  """
  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.Language.Sample
  alias Kati.UI
  alias Kati.UI.SettingsList

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :heading, Sample.heading())

  @doc false
  def content(assigns) do
    h = assigns.heading

    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={40}>
        {SettingsList.chrome(nil, 44)}
        {SettingsList.title(h.title, h.subtitle)}
        {UI.eyebrow(h.interface_label)}
        {Kati.Screens.Language.picker()}
        {UI.eyebrow(h.follows_label)}
        {Kati.Screens.Language.group(Kati.Language.Sample.follows(), 24)}
        {SettingsList.eyebrow_muted(h.content_label)}
        {Kati.Screens.Language.group(Kati.Language.Sample.content(), 24)}
        {Kati.Screens.Language.note()}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def picker do
    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(Kati.Language.Sample.languages(), fn l -> Kati.Screens.Language.language(l) end)}
      {Kati.Screens.Language.add_language()}
      <Spacer size={24} />
    </Column>
    """
  end

  # The selected card carries the drawing's inset 2pt ink ring. Two clauses
  # rather than a conditional border, because `border_width` and `border_color`
  # are opt-in as a pair in this bridge and a nil colour draws a black hairline
  # rather than nothing.
  @doc false
  def language(%{on: true} = l) do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Kati.Theme.card(:light)}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        border_width={2}
        border_color={0xFF1A1917}
        padding={14}
        align="center"
      >
        {Kati.Screens.Language.code_tile(l)}
        <Spacer size={13} />
        {Kati.Screens.Language.language_body(l)}
        <Spacer size={13} />
        <Box width={24} height={24} corner_radius={12} background={Kati.Theme.ink()} align="center">
          {Kati.UI.symbol("check", size: 15, color: 0xFFFBFAF8)}
        </Box>
      </Row>
      <Spacer size={10} />
    </Column>
    """
  end

  def language(l) do
    tap = {self(), :choose_language}

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Kati.Theme.card(:light)}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={14}
        align="center"
        on_tap={tap}
      >
        {Kati.Screens.Language.code_tile(l)}
        <Spacer size={13} />
        {Kati.Screens.Language.language_body(l)}
        <Spacer size={13} />
        <Box width={24} height={24} corner_radius={12} border_width={1.5} border_color={0x291A1917} />
      </Row>
      <Spacer size={10} />
    </Column>
    """
  end

  @doc false
  def code_tile(%{script: :fa} = l) do
    ~MOB"""
    <Box width={38} height={38} corner_radius={12} background={0xFFEFECE7} align="center">
      <Text text={l.code} font_family="fa" text_size={15} font_weight="bold" text_color={:on_surface} max_lines={1} />
    </Box>
    """
  end

  def code_tile(l) do
    ~MOB"""
    <Box width={38} height={38} corner_radius={12} background={0xFFEFECE7} align="center">
      <Text text={l.code} font_family="mono" text_size={13} text_color={:on_surface} max_lines={1} />
    </Box>
    """
  end

  @doc false
  def language_body(%{script: :fa} = l) do
    ~MOB"""
    <Column weight={1.0}>
      <Text text={l.name} font_family="fa" text_size={15} font_weight="bold" text_color={:on_surface} max_lines={1} />
      <Spacer size={3} />
      <Text text={l.region} font_family="fa" text_size={12} text_color={0xFF8A8479} max_lines={1} />
    </Column>
    """
  end

  def language_body(l) do
    ~MOB"""
    <Column weight={1.0}>
      <Text text={l.name} text_size={14} font_weight="bold" text_color={:on_surface} max_lines={1} />
      <Spacer size={3} />
      <Text text={l.region} text_size={11.5} text_color={0xFF8A8479} max_lines={1} />
    </Column>
    """
  end

  # Solid, not dashed: `Modifier.border` takes a width and a colour and no
  # PathEffect. The 1.5pt weight and the alpha are the drawing's own.
  @doc false
  def add_language do
    a = Sample.add_language()
    tap = {self(), :add_language}

    ~MOB"""
    <Row
      fill_width={true}
      corner_radius={20}
      border_width={1.5}
      border_color={0x291A1917}
      padding={14}
      align="center"
      on_tap={tap}
    >
      <Box width={38} height={38} corner_radius={12} background={0xFFEFECE7} align="center">
        {Kati.UI.symbol("add", size: 18, color: 0xFF8A8479)}
      </Box>
      <Spacer size={13} />
      <Column weight={1.0}>
        <Text text={a.title} text_size={14} font_weight="bold" text_color={0xFF8A8479} max_lines={1} />
        <Spacer size={3} />
        <Text text={a.sub} text_size={11.5} text_color={0xFF8A8479} max_lines={1} />
      </Column>
      <Spacer size={13} />
      {Kati.UI.SettingsList.chevron()}
    </Row>
    """
  end

  @doc false
  def group(rows, gap) do
    last = length(rows) - 1

    body =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, i} -> Kati.Screens.Language.row(row, i < last) end)

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(body)}
      <Spacer size={gap} />
    </Column>
    """
  end

  @doc false
  def row(row, rule?) do
    SettingsList.row(
      SettingsList.icon_tile(row.icon),
      Kati.Screens.Language.body(row),
      Kati.Screens.Language.control(row.control),
      padding: 13,
      rule: rule?
    )
  end

  # Vazirmatn for the two rows whose second line carries Persian — see the
  # moduledoc. The title stays in the body face; only the line with the glyphs
  # in it changes font.
  @doc false
  def body(%{script: :fa} = row) do
    ~MOB"""
    <Column fill_width={true}>
      <Text text={row.title} text_size={13.5} font_weight="semibold" text_color={:on_surface} max_lines={1} />
      <Spacer size={3} />
      <Text text={row.sub} font_family="fa" text_size={11.5} text_color={0xFF8A8479} max_lines={1} />
    </Column>
    """
  end

  def body(row), do: SettingsList.body(row.title, row.sub)

  @doc false
  def control(:chevron), do: SettingsList.chevron()
  def control({:switch, on?}), do: SettingsList.switch(on?)

  def control({:value, text}) do
    ~MOB"""
    <Text text={text} font_family="mono" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
    """
  end

  @doc false
  def note do
    text = Sample.note()

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
      <Text text={text} text_size={12.5} line_height={1.55} text_color={0xFF5C574F} weight={1.0} />
    </Row>
    """
  end
end
