defmodule Kati.Screens.Subscriptions do
  @moduledoc """
  Screen 23 — Subscriptions, pushed under Stats.

  Built to `.scratch/design/screens/23.html`. The money section, and the
  drawing says plainly why it belongs in this app rather than a finance one:
  *"cost per watched hour is the one subscription number no finance app can
  compute for you."* The price comes from a bank; the hours come from the
  Screen shelf; only here do they meet.

  So the rate is the point of the list, and it is coloured rather than merely
  printed — green at £0.21/h, `#B4553C` at £2.33/h. That red is the same token
  `Kati.Theme.red/0` uses for an error, which is the design being blunt: an
  hour of television costing more than a cinema ticket is a fault, not a
  statistic.

  Details taken literally from the export:

    * The back pill shares its row with a `more_horiz` disc, so unlike screens
      15 and 22 that row is 44 tall rather than 42 — the disc sets the height.
    * "Worth a look" gets the grey dash (`Kati.UI.Eyebrow.quiet/1`): a
      suggestion the app is offering is not new and not now.
    * The paused row drops its rate entirely and greys both its lines. It is
      the one row where the right-hand column is a single value.

  The suggestion's body is drawn with `6 hours` and `1 title` in bold inside a
  wrapping paragraph. Mob's `Text` carries one weight, and a paragraph
  assembled from separate runs breaks at the wrong words, so it renders as one
  run — recorded here because it is a real loss against the drawing, not an
  oversight.

  No dock on a pushed screen, so the frame ends at 40 rather than 132.
  """
  use Kati.Screens.Pushed, back: "Stats"

  alias Kati.Subscriptions.Sample
  alias Kati.UI

  @doc false
  def content(_assigns) do
    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={40}>
        {Kati.Screens.Subscriptions.back_row()}
        {Kati.Screens.Subscriptions.title()}
        {Kati.Screens.Subscriptions.monthly()}
        {UI.eyebrow("Services")}
        {Kati.Screens.Subscriptions.services()}
        {Kati.UI.Eyebrow.quiet("Worth a look")}
        {Kati.Screens.Subscriptions.suggestion()}
      </Column>
    </Scroll>
    """
  end

  # The back pill itself is drawn by Kati.Screens.Pushed as floating chrome;
  # this row reserves its height and carries the overflow disc opposite it.
  @doc false
  def back_row do
    tap = {self(), :open_menu}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Spacer weight={1.0} />
        <Box
          width={44}
          height={44}
          background={Kati.Theme.card(:light)}
          corner_radius={22}
          shadow={Kati.Theme.shadow_button()}
          align="center"
          on_tap={tap}
        >
          {Kati.UI.symbol("more_horiz", size: 21)}
        </Box>
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc false
  def title do
    ~MOB"""
    <Column fill_width={true}>
      <Text text="Subscriptions" text_size={28} font_weight="bold" letter_spacing={-0.03} text_color={:on_surface} />
      <Spacer size={5} />
      <Text text={Kati.Subscriptions.Sample.active_line()} font_family="mono" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def monthly do
    m = Sample.monthly()

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={0xFFFBF1DE}
        corner_radius={24}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={19}
      >
        <Text text={String.upcase(m.label)} font_family="mono" text_size={10.5} letter_spacing={0.16} text_color={0xFFB09A72} />
        <Spacer size={7} />
        <Text text={m.total} text_size={36} font_weight="extrabold" letter_spacing={-0.04} text_color={:on_surface} />
        <Spacer size={12} />
        <Row fill_width={true} align="center">
          {Kati.UI.symbol("trending_up", size: 15, color: 0xFFB4553C)}
          <Spacer size={7} />
          <Text text={m.change_lead} text_size={12.5} text_color={0xFF8A7B60} max_lines={1} />
          <Spacer size={4} />
          <Text text={m.change_amount} text_size={12.5} font_weight="semibold" text_color={:on_surface} max_lines={1} />
          <Spacer size={4} />
          <Text text={m.change_rest} text_size={12.5} text_color={0xFF8A7B60} max_lines={1} />
          <Spacer weight={1.0} />
        </Row>
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def services do
    rows = Sample.services()
    last = length(rows) - 1

    children =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, i} -> service_row(row, i < last) end)

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
        {children}
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def service_row(row, rule?) do
    paused? = Map.get(row, :paused, false)
    name_color = if paused?, do: 0xFF8A8479, else: Kati.Theme.ink()
    line_color = if paused?, do: 0xFFB3ACA2, else: 0xFF8A8479

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={14} padding_bottom={14}>
        <Box width={32} height={32} corner_radius={10} background={0xFFEFECE7} align="center">
          <Text text={row.badge} font_family="mono" text_size={13} text_color={:on_surface} max_lines={1} />
        </Box>
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text text={row.name} text_size={13.5} font_weight="semibold" text_color={name_color} max_lines={1} />
          <Spacer size={3} />
          <Text text={row.line} text_size={11.5} text_color={line_color} max_lines={1} />
        </Column>
        <Spacer size={13} />
        {Kati.Screens.Subscriptions.money(row, paused?)}
      </Row>
      {Kati.Screens.Subscriptions.hairline(rule?)}
    </Column>
    """
  end

  # A paused service has one value on the right, not two: it has no rate,
  # because £5.00 buying nothing is not a price per hour. Two clauses rather
  # than a nil-rate branch, so the shapes stay honestly different.
  @doc false
  def money(row, true) do
    ~MOB"""
    <Text text={row.price} font_family="mono" text_size={12} text_color={0xFFB3ACA2} max_lines={1} />
    """
  end

  # 46 wide, not hugging. `text_align="right"` makes a Text fillMaxWidth on
  # this bridge — the defect that flattened screen 08's rating card — so it
  # only behaves inside a column of declared width. 46 clears the widest value
  # the drawing carries (`£13.99` at mono 12).
  def money(row, false) do
    ~MOB"""
    <Column width={46}>
      <Text text={row.price} font_family="mono" text_size={12} font_weight="medium" text_color={:on_surface} text_align="right" max_lines={1} />
      <Spacer size={3} />
      <Text text={row.rate} font_family="mono" text_size={10} text_color={row.rate_tone} text_align="right" max_lines={1} />
    </Column>
    """
  end

  @doc false
  def suggestion do
    s = Sample.suggestion()

    ~MOB"""
    <Column
      fill_width={true}
      background={Kati.Theme.card(:light)}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={17}
    >
      <Row fill_width={true} align="top">
        {Kati.UI.symbol("lightbulb", size: 19, color: 0xFFE8823C)}
        <Spacer size={11} />
        <Text text={s.body} text_size={13} line_height={1.55} text_color={0xFF4A4238} weight={1.0} />
      </Row>
      <Spacer size={15} />
      <Row fill_width={true} align="center">
        {Kati.Screens.Subscriptions.confirm(s.confirm)}
        <Spacer size={9} />
        {Kati.Screens.Subscriptions.dismiss(s.dismiss)}
      </Row>
    </Column>
    """
  end

  @doc false
  def confirm(label) do
    tap = {self(), :remind}

    ~MOB"""
    <Box weight={1.0}>
      <Row fill_width={true} height={40} corner_radius={20} background={Kati.Theme.ink()} align="center" on_tap={tap}>
        <Spacer weight={1.0} />
        <Text text={label} text_size={12.5} font_weight="semibold" text_color={0xFFFBFAF8} max_lines={1} />
        <Spacer weight={1.0} />
      </Row>
    </Box>
    """
  end

  @doc false
  def dismiss(label) do
    tap = {self(), :dismiss}

    ~MOB"""
    <Row height={40} corner_radius={20} background={0xFFEFECE7} padding_left={15} padding_right={15} align="center" on_tap={tap}>
      <Text text={label} text_size={12.5} font_weight="semibold" text_color={0xFF5C574F} max_lines={1} />
    </Row>
    """
  end

  @doc false
  def hairline(false), do: ~MOB"<Spacer size={0} />"
  def hairline(true), do: ~MOB"<Box fill_width={true} height={1} background={0x121A1917} />"
end
