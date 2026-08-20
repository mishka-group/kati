defmodule Kati.Screens.Import do
  @moduledoc """
  Screen 37 — Import, pushed under Settings.

  Built to `.scratch/design/screens/37.html`. The drawing's argument is that
  nothing is written until the person has seen what will happen: the file is
  acknowledged, every column is shown mapped to a field with a real value
  beside it, the write is summarised as three counts, and each conflict is
  answered on its own.

  Two details the drawing is specific about and which are easy to lose:

    * the dropped column is `block` + grey `Skip` + the word "skipped", so the
      fact that it will be ignored is said three ways and never by colour
      alone;
    * the conflict card sits on cream, the same warming the note gets on
      screen 08 — it marks the one place the screen is asking rather than
      telling.

  The stars in "converts 10pt → 5★" and "Yours ★4 · file says ★5" are drawn
  as text in the export, but Plus Jakarta Sans carries no U+2605 — screen 08
  proved that renders as nothing at all. So `star_text/3` keeps the design's
  literal string as the data and splits it at the star, rendering the Material
  Symbols `star` glyph in its place at the surrounding text's size and colour.

  No dock, so the frame's bottom inset is 40 rather than 132.
  """
  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.Components.MishkaSeparator
  alias Kati.Components.MishkaThemeIcon
  alias Kati.Import.Sample
  alias Kati.UI

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :job, Sample.job())

  @doc false
  def content(assigns) do
    job = assigns.job

    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={40}>
        {Kati.Screens.Import.header(job)}
        {Kati.Screens.Import.title(job)}
        {Kati.Screens.Import.steps(job)}
        {Kati.Screens.Import.file_card(job)}
        {UI.eyebrow("Match columns")}
        {Kati.Screens.Import.mapping(job)}
        {UI.eyebrow("What will happen")}
        {Kati.Screens.Import.outcome(job)}
        {UI.eyebrow("Conflicts · keep which?")}
        {Kati.Screens.Import.conflict(job)}
      </Column>
    </Scroll>
    """
  end

  # The 44pt height reserves the row the back pill floats in — the pill itself
  # is drawn by Kati.Screens.Pushed — so the ink action sits opposite it.
  @doc false
  def header(job) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} height={44} align="center">
        <Spacer weight={1.0} />
        <Row
          height={38}
          corner_radius={19}
          background={Kati.Theme.ink()}
          padding_left={16}
          padding_right={16}
          align="center"
        >
          <Text text={job.action} text_size={13} font_weight="bold" text_color={0xFFFBFAF8} max_lines={1} />
        </Row>
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc false
  def title(job) do
    ~MOB"""
    <Column fill_width={true}>
      <Text text="Import" text_size={28} font_weight="bold" letter_spacing={-0.03} text_color={:on_surface} />
      <Spacer size={5} />
      <Text text={job.subtitle} font_family="mono" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def steps(job) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {1..job.steps
         |> Enum.map(fn i -> Kati.Screens.Import.step_bar(i <= job.step) end)
         |> Enum.intersperse(Kati.Screens.Import.step_gap())}
      </Row>
      <Spacer size={22} />
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
  def file_card(job) do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Kati.Theme.card(:light)}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={15}
        align="center"
      >
        {Kati.Screens.Import.file_tile()}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text text={job.file} text_size={13.5} font_weight="bold" text_color={:on_surface} max_lines={1} />
          <Spacer size={4} />
          <Text text={job.shape} font_family="mono" text_size={10.5} text_color={0xFFA9A29A} max_lines={1} />
        </Column>
        <Spacer size={13} />
        {Kati.UI.symbol("check_circle", size: 20, color: Kati.Theme.green(), fill: true)}
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The 38x38 paper tile the file card leads with, from
  `Kati.Components.MishkaThemeIcon` — "a themed container around exactly one
  icon", which is what this is. Larger than the settings rows' 30 and rounded
  to 11 rather than 9, both the drawing's own numbers, both props.

  `variant: :filled` with an explicit `color`, not `variant: :white` — the
  white variant paints the theme's `:surface`, which here is `#FBFAF8`, the
  card the tile sits on.

  The glyph is a child rather than the `icon` prop: that shorthand builds a
  `Text` with no `font_family`, so the ligature `"description"` would be
  typeset as the word rather than resolved to the Material Symbols glyph.

  With children and no `id`, `theme_icon/2` returns
  `%{type: :box, props: %{width: 38, height: 38, align: :center,
  corner_radius: 11, background: 0xFFEFECE7}, children: [glyph]}` — node for
  node what the card wrote by hand.
  """
  def file_tile do
    MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: 0xFFEFECE7, size: 38, radius: 11},
      [Kati.UI.symbol("description", size: 20, color: 0xFF5C574F)]
    )
  end

  @doc false
  def mapping(job) do
    last = length(job.columns) - 1

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
        {job.columns
         |> Enum.with_index()
         |> Enum.map(fn {row, i} -> Kati.Screens.Import.map_row(row, i < last) end)}
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def map_row(row, rule?) do
    field_color = if row.skipped?, do: 0xFFB3ACA2, else: Kati.Theme.ink()

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={13} padding_bottom={13}>
        <Column weight={1.0}>
          <Text text={row.column} font_family="mono" text_size={11} text_color={:on_surface} max_lines={1} />
          <Spacer size={4} />
          <Text text={row.sample} text_size={10.5} text_color={0xFFB3ACA2} max_lines={1} />
        </Column>
        <Spacer size={11} />
        {Kati.UI.symbol(row.icon, size: 15, color: 0xFFC4BDB3)}
        <Spacer size={11} />
        <Column width={106}>
          <Text
            text={row.field}
            text_size={12.5}
            font_weight="semibold"
            text_color={field_color}
            text_align="right"
            max_lines={1}
          />
          {Kati.Screens.Import.map_note(row)}
        </Column>
      </Row>
      {Kati.Screens.Import.hairline(rule?)}
    </Column>
    """
  end

  @doc false
  def map_note(%{note: nil}), do: ~MOB"<Spacer size={0} />"

  def map_note(row) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={3} />
      <Row fill_width={true} align="center">
        <Spacer weight={1.0} />
        {Kati.Screens.Import.star_text(row.note, 10, 0xFFA0998F)}
      </Row>
    </Column>
    """
  end

  @doc """
  A line of text with the design's ★ rendered as the Material Symbols glyph.

  The export writes `&starf;` inline, which is U+2605 — a character the sans
  face does not carry. Keeping the whole string as the data and splitting it
  here means the copy stays the design's own while the glyph comes from the
  font that actually has it.
  """
  def star_text(line, size, color) do
    parts = String.split(line, "★")

    ~MOB"""
    <Row align="center">
      {parts
       |> Enum.map(fn part -> Kati.Screens.Import.star_part(part, size, color) end)
       |> Enum.intersperse(Kati.Screens.Import.star_glyph(size, color))}
    </Row>
    """
  end

  @doc false
  def star_part(part, size, color) do
    ~MOB"""
    <Text text={part} text_size={size} text_color={color} max_lines={1} />
    """
  end

  @doc false
  def star_glyph(size, color), do: Kati.UI.symbol("star", size: size, color: color, fill: true)

  @doc false
  def outcome(job) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {job.outcome
         |> Enum.map(fn card -> Kati.Screens.Import.outcome_card(card) end)
         |> Enum.intersperse(Kati.Screens.Import.outcome_gap())}
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def outcome_gap, do: ~MOB"<Spacer size={10} />"

  @doc false
  def outcome_card(card) do
    ~MOB"""
    <Box weight={1.0}>
      <Column
        fill_width={true}
        background={Kati.Theme.card(:light)}
        corner_radius={18}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={14}
      >
        <Text
          text={card.value}
          text_size={22}
          font_weight="extrabold"
          letter_spacing={-0.03}
          text_color={card.color}
          text_align="center"
        />
        <Spacer size={5} />
        <Text
          text={String.upcase(card.label)}
          font_family="mono"
          text_size={10}
          letter_spacing={0.1}
          text_color={0xFFA9A29A}
          text_align="center"
          max_lines={1}
        />
      </Column>
    </Box>
    """
  end

  @doc false
  def conflict(job) do
    c = job.conflict

    ~MOB"""
    <Column fill_width={true} background={0xFFFBF1DE} corner_radius={20} padding={15}>
      <Row fill_width={true} align="center">
        {Kati.Screens.Import.conflict_poster(c)}
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text text={c.title} text_size={13} font_weight="bold" text_color={:on_surface} max_lines={1} />
          <Spacer size={3} />
          {Kati.Screens.Import.star_text(c.line, 11.5, 0xFF8A7B60)}
        </Column>
      </Row>
      <Spacer size={12} />
      <Row fill_width={true} align="center">
        {c.choices
         |> Enum.map(fn choice -> Kati.Screens.Import.choice(choice) end)
         |> Enum.intersperse(Kati.Screens.Import.choice_gap())}
      </Row>
      <Spacer size={12} />
      <Text
        text={c.progress}
        font_family="mono"
        text_size={10.5}
        text_color={0xFFB09A72}
        text_align="center"
        max_lines={1}
      />
    </Column>
    """
  end

  @doc false
  def choice_gap, do: ~MOB"<Spacer size={8} />"

  @doc false
  def choice({label, primary?}) do
    bg = if primary?, do: Kati.Theme.ink(), else: 0x99FFFFFF
    fg = if primary?, do: 0xFFFBFAF8, else: 0xFF8A7B60

    ~MOB"""
    <Box weight={1.0} height={32} corner_radius={16} background={bg} align="center">
      <Text text={label} text_size={11.5} font_weight="semibold" text_color={fg} max_lines={1} />
    </Box>
    """
  end

  @doc false
  def conflict_poster(c) do
    case Kati.Design.Images.poster(c.seed) do
      nil ->
        ~MOB"<Box width={34} height={48} corner_radius={7} background={0xFFE4E0D9} />"

      src ->
        ~MOB"""
        <Image src={src} width={34} height={48} corner_radius={7} content_mode="fill" />
        """
    end
  end

  # `Kati.Components.MishkaSeparator` is what a 1px rule between mapping rows
  # is, so the rule is its. Its plain variant is a `<Divider>`, and the
  # bridge's `MobDivider` renders Compose's `HorizontalDivider(thickness,
  # color)` — defined as `Box(modifier.fillMaxWidth().height(thickness)
  # .background(color))`, the same three modifiers this wrote by hand. The
  # drawing's 7% ink survives because the colour is an ARGB int: `color` is in
  # the renderer's `@color_props` whitelist and an integer reaches `colorProp`
  # untouched.
  @doc false
  def hairline(false), do: ~MOB"<Spacer size={0} />"
  def hairline(true), do: MishkaSeparator.separator(color: 0x121A1917, thickness: 1)
end
