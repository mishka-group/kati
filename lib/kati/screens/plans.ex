defmodule Kati.Screens.Plans do
  @moduledoc """
  Screen 49 — Meal plan profiles, pushed under Meals.

  Built to `.scratch/design/screens/49.html`. Plans are the profile mechanism:
  a plan owns its meals, its targets and its reminder times, exactly one is
  active, and switching swaps all three at once. The screen is arranged to say
  that — one ink card for the active plan, a list of saved ones you can
  activate, and then the rules that govern the swap.

  Switching is **scheduled**, not instant. "Next Monday · keeps this week
  intact" is the design's answer to the obvious bug of flipping targets
  half-way through a logged week, and it is drawn as a disclosure rather than a
  switch because it opens a date rather than toggling a behaviour.

  Two eyebrows take the accent dash and one takes the muted one, exactly as
  drawn: **Active** and **Switching** are now, **Saved plans** is a shelf.

  The Switching group is `Kati.UI.SettingsList` unchanged. The active card and
  the saved rows are not, because the drawing does not draw them that way: the
  active plan is the one card in the app set on ink, and a saved row leads with
  a 44pt photograph and ends in a 32pt Activate pill.

  ## Where this diverges from the drawing

    * **The footnote's frame is solid, not dashed.** `1.5px dashed
      rgba(26,25,23,.16)` has no dashed equivalent on this bridge —
      `Modifier.border` takes a width and a colour and no `PathEffect` — so the
      weight and the alpha are the drawing's and the rhythm is lost, the same
      trade `Kati.UI.SettingsList.note/2` records.

  No dock, so the frame's bottom inset is 40 rather than 132.
  """
  use Kati.Screens.Pushed, back: "Meals"

  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaPill
  alias Kati.Meals.SampleProfiles
  alias Kati.UI
  alias Kati.UI.SettingsList

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :plans, SampleProfiles.plans())

  @doc false
  def content(assigns) do
    plans = assigns.plans

    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={40}>
        {SettingsList.chrome(nil, 42)}
        {SettingsList.title("Plans", plans.subtitle, "add")}
        {UI.eyebrow("Active")}
        {Kati.Screens.Plans.active(plans.active)}
        {SettingsList.eyebrow_muted("Saved plans")}
        {Kati.Screens.Plans.saved(plans.saved)}
        {UI.eyebrow("Switching")}
        {Kati.Screens.Plans.switching(plans.switching)}
        {Kati.Screens.Plans.note(plans.note)}
      </Column>
    </Scroll>
    """
  end

  # The one card in the app drawn on ink rather than on card: it is the plan
  # every other screen is currently obeying, and the inversion says so without
  # a badge.
  @doc false
  def active(active) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Kati.Theme.ink()}
        corner_radius={24}
        shadow="0 16 32 -16 #E61A1917"
        padding={19}
      >
        <Row fill_width={true} align="top">
          <Column weight={1.0}>
            <Text
              text={String.upcase(active.week)}
              font_family="mono"
              text_size={10}
              letter_spacing={0.16}
              text_color={0xFF6A6560}
              max_lines={1}
            />
            <Spacer size={8} />
            <Text text={active.name} text_size={22} font_weight="bold" letter_spacing={-0.03} text_color={0xFFFBFAF8} max_lines={1} />
            <Spacer size={6} />
            <Text text={active.targets} text_size={12.5} text_color={0xFF8A837B} max_lines={1} />
          </Column>
          <Spacer size={12} />
          {Kati.Screens.Plans.overflow()}
        </Row>
        <Spacer size={16} />
        {Kati.Screens.Plans.progress(active.progress)}
        <Spacer size={10} />
        <Row fill_width={true} align="center">
          <Text text={active.started} font_family="mono" text_size={10} text_color={0xFF6A6560} max_lines={1} />
          <Spacer weight={1.0} />
          <Text text={active.adherence} font_family="mono" text_size={10} text_color={0xFF6A6560} max_lines={1} />
        </Row>
      </Column>
      <Spacer size={20} />
    </Column>
    """
  end

  # `Kati.Components.MishkaActionIcon` — an icon-only button, here on ink
  # rather than on paper. No `shadow`: this one sits inside the card, and the
  # drawing gives it none; `variant: :filled` on its own is the `background` +
  # `corner_radius` box it replaces, and `shape: :circle` computes 36 / 2 =
  # 18.0, the radius written before.
  #
  # `0x1FF5F2EE` is `rgba(245,242,238,.12)` — a white-ish veil ON the ink card,
  # not a grey — so it stays an ARGB int rather than a token. The glyph is a
  # child rather than `icon:`, because Kati's icons are Material Symbols
  # through `Kati.UI.symbol/2`; a child is wrapped in a `<Row>` that hugs it,
  # inside a Box that already centred it. It carries no handler and passing no
  # `on_tap` wires none.
  @doc false
  def overflow do
    MishkaActionIcon.action_icon(
      [size: 36, shape: :circle, variant: :filled, background: 0x1FF5F2EE],
      [UI.symbol("more_horiz", size: 19, color: 0xFFF5F2EE)]
    )
  end

  # Orange, and allowed to be: this bar is how far through *now* is.
  @doc false
  def progress(fraction) do
    ~MOB"""
    <Box fill_width={true} height={5} corner_radius={3} background={0x26F5F2EE}>
      <Row fill_width={true}>
        <Box weight={fraction} height={5} corner_radius={3} background={Kati.Theme.accent()} />
        <Spacer weight={1.0 - fraction} />
      </Row>
    </Box>
    """
  end

  @doc false
  def saved(rows) do
    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(rows, fn row -> Kati.Screens.Plans.saved_row(row) end)}
      <Spacer size={12} />
    </Column>
    """
  end

  # Separate cards with a 10pt gap, not one grouped card with hairlines: each
  # of these is a thing you can activate, so it gets its own edge.
  @doc false
  def saved_row(row) do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Kati.Theme.card(:light)}
        corner_radius={18}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={13}
        padding_right={13}
        padding_top={12}
        padding_bottom={12}
        align="center"
      >
        {Kati.Screens.Plans.thumb(row.seed)}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text text={row.name} text_size={13.5} font_weight="bold" text_color={:on_surface} max_lines={1} />
          <Spacer size={4} />
          <Text text={row.line} text_size={11.5} text_color={0xFF8A8479} max_lines={1} />
          <Spacer size={3} />
          <Text text={row.meta} font_family="mono" text_size={10} text_color={0xFFC4BDB3} max_lines={1} />
        </Column>
        <Spacer size={13} />
        {Kati.Screens.Plans.activate(row.action)}
      </Row>
      <Spacer size={10} />
    </Column>
    """
  end

  # `Kati.Components.MishkaPill`: a compact label, no selected state, no tap —
  # which is the port's own dividing line ("a Chip is selected, a Pill is
  # removed"). This one is drawn but not yet wired, so it is a label in the
  # tree as well as in the drawing.
  #
  # The same pixels, one wrapper deeper. The hugging `Row` that carried the
  # `#EFECE7` fill, the 16 radius, 13 of horizontal padding and a 32 height
  # becomes the pill's root `Box fill_width={false}` carrying all four, around
  # a `Row` holding the `Text` and the empty `Row` the unused remove slot
  # leaves behind — a 0x0 node that adds nothing to the line.
  #
  # All four padding edges are named, so the component's `:space_sm` default
  # never reads: `nodeModifier/1` consults the uniform value only for an edge
  # that is missing. The vertical zeros pin the outer height at 32, since the
  # bridge pads before it sizes. `align: :center` stands in for the Row's
  # `align="center"`; horizontally the content box is exactly the Text's width,
  # so only its vertical half has anything to do.
  @doc false
  def activate(label) do
    MishkaPill.pill(
      label: label,
      background: 0xFFEFECE7,
      color: :on_surface,
      corner_radius: 16,
      height: 32,
      padding_left: 13,
      padding_right: 13,
      padding_top: 0,
      padding_bottom: 0,
      text_size: 11.5,
      font_weight: :semibold,
      align: :center
    )
  end

  @doc false
  def thumb(seed) do
    case Kati.Design.Images.poster(seed) do
      nil ->
        ~MOB"<Box width={44} height={44} corner_radius={12} background={0xFFE4E0D9} />"

      src ->
        ~MOB"""
        <Image src={src} width={44} height={44} corner_radius={12} content_mode="fill" />
        """
    end
  end

  @doc false
  def switching(rows) do
    last = length(rows) - 1

    cards =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, i} ->
        SettingsList.row(
          SettingsList.icon_tile(row.icon),
          SettingsList.body(row.title, row.sub),
          Kati.Screens.Plans.trail(row.trail),
          rule: i < last
        )
      end)

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card(cards)}
      <Spacer size={22} />
    </Column>
    """
  end

  # A disclosure, not a switch: the first row opens a date rather than toggling
  # a behaviour, and the drawing distinguishes the two.
  @doc false
  def trail(:chevron), do: SettingsList.chevron()
  def trail({:toggle, on?}), do: SettingsList.switch(on?)

  # Not SettingsList.note/2: that one pads 16 and sets its glyph at 18, and
  # this drawing says 15 and 17. FIDELITY's rule is that a number in the export
  # is a number here, so the frame is redrawn rather than approximated.
  @doc false
  def note(text) do
    ~MOB"""
    <Row
      fill_width={true}
      corner_radius={18}
      border_color={0x291A1917}
      border_width={1.5}
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
