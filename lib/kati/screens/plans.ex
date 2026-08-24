defmodule Kati.Screens.Plans do
  @moduledoc """
  Screen 49 — Meal plan profiles, pushed under Meals.

  Built to `test/design/screens/49.html`. Plans are the profile mechanism:
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
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :plans, SampleProfiles.plans())

  @doc false
  def content(assigns) do
    plans = assigns.plans

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {SettingsList.chrome(nil, 42)}
        {SettingsList.title("Plans", plans.subtitle, "add", :meta_tight)}
        {UI.eyebrow("Active")}
        {Kati.Screens.Plans.active(plans.active)}
        {SettingsList.eyebrow_muted("Saved plans")}
        {Kati.Screens.Plans.saved(plans.saved)}
        {UI.eyebrow("Switching")}
        {Kati.Screens.Plans.switching(plans.switching)}
        {Kati.Screens.Plans.note(plans.note)}
        {Kati.Screens.Plans.import_row()}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The row that takes a plan in, opposite screen 50 which sends one out.

  On Plans rather than on Meals, because a plan somebody sent you has to land
  where plans live — and because the import writes nothing until its last step,
  which is screen 37's discipline and is what makes an import row safe to put on
  a page full of live plans.
  """
  @spec import_row() :: map()
  def import_row do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={22} />
      {Kati.UI.SettingsList.card([
        Kati.UI.SettingsList.row(
          Kati.UI.SettingsList.icon_tile("download"),
          Kati.UI.SettingsList.body("Import a plan", "From a link or a code somebody sent you"),
          Kati.UI.SettingsList.trailing(Kati.UI.SettingsList.chevron()),
          on_tap: {self(), :import_plan}
        )
      ])}
    </Column>
    """
  end

  # The one card in the app drawn on ink rather than on card: it is the plan
  # every other screen is currently obeying, and the inversion says so without
  # a badge.
  #
  # `Palette.ink_fill/0` rather than `Palette.ink/0`: this is the ink-FILLED
  # ground the `on_ink_*` family is measured against. `Kati.Theme.Palette`'s
  # `:inversion` rule solves those for contrast against the pill screen 28
  # draws as `#F7EFE4`, which is `ink_fill`'s dark value and not `ink`'s.
  #
  # The three `0xFF6A6560` mono figures below are LEFT as literals: no token in
  # `Kati.Theme.Palette` has that LIGHT value — it appears there only as the
  # dark side of `muted`, `segment_idle` and `tertiary`. They mean "the mono
  # meta step on an ink fill", which is `on_ink_meta`, but that token's light
  # value is `#8A837B` and swapping would move light-mode pixels. Naming them
  # is the palette's call, not this screen's.
  @doc false
  def active(active) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.ink_fill()}
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
            <Text
              text={active.name}
              text_size={22}
              font_weight="bold"
              letter_spacing={-0.03}
              text_color={Palette.on_ink()}
              max_lines={1}
            />
            <Spacer size={6} />
            <Text
              text={active.targets}
              text_size={12.5}
              text_color={Palette.on_ink_meta()}
              max_lines={1}
            />
          </Column>
          <Spacer size={12} />
          {Kati.Screens.Plans.overflow()}
        </Row>
        <Spacer size={16} />
        {Kati.Screens.Plans.progress(active.progress)}
        <Spacer size={10} />
        <Row fill_width={true} align="center">
          <Text
            text={active.started}
            font_family="mono"
            text_size={10}
            text_color={0xFF6A6560}
            max_lines={1}
          />
          <Spacer weight={1.0} />
          <Text
            text={active.adherence}
            font_family="mono"
            text_size={10}
            text_color={0xFF6A6560}
            max_lines={1}
          />
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
  # `Palette.on_ink_veil/0` is `rgba(245,242,238,.12)` — a white-ish veil ON
  # the ink card, not a grey — and `Palette.on_ink_glyph/0` is the mark on it.
  # Both invert with the card rather than following the page. The glyph is a
  # child rather than `icon:`, because Kati's icons are Material Symbols
  # through `Kati.UI.symbol/2`; a child is wrapped in a `<Row>` that hugs it,
  # inside a Box that already centred it.
  #
  # ## Why this disc opens screen 50
  #
  # `Kati.Screens.PlanShare`'s drawing opens with a `‹ Plans` back pill and is
  # titled *"Cutting v3 · share & transfer"* — so it is pushed from this
  # screen, over the plan this card names. This disc is the only control the
  # drawing puts on that card, and 49 draws no other affordance that could
  # lead anywhere: the header disc is `add`, the saved rows end in Activate
  # pills, and the Switching group is one chevron and two switches.
  #
  # It is an overflow glyph, so on a platform with menus it would open one and
  # share would be an item in it. Mob has no menu node, and inventing a menu is
  # a bigger fiction than letting the plan's only button reach the plan's only
  # other screen. `on_tap` adds no ink, so the card's resting pixels are the
  # drawing's, unchanged.
  @doc false
  def overflow do
    MishkaActionIcon.action_icon(
      [
        size: 36,
        shape: :circle,
        variant: :filled,
        background: Palette.on_ink_veil(),
        on_tap: :share_plan
      ],
      [UI.symbol("more_horiz", size: 19, color: Palette.on_ink_glyph())]
    )
  end

  # Orange, and allowed to be: this bar is how far through *now* is.
  @doc false
  def progress(fraction) do
    ~MOB"""
    <Box fill_width={true} height={5} corner_radius={3} background={Palette.on_ink_track()}>
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
        background={Palette.card()}
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
          <Text
            text={row.name}
            text_size={13.5}
            font_weight="bold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={4} />
          <Text text={row.line} text_size={11.5} text_color={Palette.sub()} max_lines={1} />
          <Spacer size={3} />
          <Text
            text={row.meta}
            font_family="mono"
            text_size={10}
            text_color={Palette.rail_idle()}
            max_lines={1}
          />
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
      background: Palette.paper(),
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
        ~MOB"<Box width={44} height={44} corner_radius={12} background={Palette.placeholder()} />"

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
      border_color={Palette.border()}
      border_width={1.5}
      padding={15}
      align="top"
    >
      {Kati.UI.symbol("info", size: 17, color: Palette.sub())}
      <Spacer size={11} />
      <Text
        text={text}
        text_size={12.5}
        line_height={1.55}
        text_color={Palette.ink_soft()}
        weight={1.0}
      />
    </Row>
    """
  end

  # One clause and no `_tag` catch-all, deliberately. A catch-all here would
  # answer every future control with silence, and `Kati.Screens.Pushed`'s
  # moduledoc is explicit that the DEAD TAP report is the only thing that can
  # see a button whose resting pixels are correct and whose wiring is absent.
  # The Activate pills are drawn without a tap and so are not reported; the
  # moment one grows one, this screen says so.
  @impl true
  # Screen 120 is the other half of 50: one screen shares a plan and the other
  # takes one in. The import row is on Plans because that is where a plan you
  # have been sent has to land.
  def handle_tap(:import_plan, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.PlanImport)}

  def handle_tap(:share_plan, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.PlanShare)}
end
