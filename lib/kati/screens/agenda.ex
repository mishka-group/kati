defmodule Kati.Screens.Agenda do
  @moduledoc """
  Screen 30 — Calendar, agenda.

  Built to `.scratch/design/screens/30.html`. The fourth view mode, and the
  only one with no grid at all: a date kicker appears where something exists
  and nowhere else, so an empty week costs no scrolling. The gap at the end is
  *stated* — "Nothing else until 12 Sep" inside a dashed outline — rather than
  left as blank paper the user has to interpret.

  A root, not a pushed screen: the drawing carries the dock with Calendar
  active.

  ## The components this screen uses

    * `disc/1` — `Kati.Components.MishkaActionIcon`, filled and circular. It
      became one this round: an Action Icon had no `shadow` prop before, and a
      filled disc without one is a flat patch rather than a button floating
      over the paper.
    * `hairline/1` — `Kati.Components.MishkaSeparator` at **`render: :box`**.
      The default `:divider` is Material3's antialiased `drawLine`, whose last
      pixel row lands at ~69% coverage on this device; the design asks for a
      1px rule and `:box` is the only setting that draws one.

  The switcher belongs to `Kati.Screens.ViewSwitcher`, and the footer's outline
  is not a component — see below.

  ## Where this diverges from the drawing

  The footer's outline is `1.5px dashed`. The bridge's border draws a solid
  stroke — there is no dash pattern on the prop — so it ships solid at the
  design's `rgba(26,25,23,.16)`. The intent (an outline that reads as a
  placeholder rather than a control) mostly survives; the literal dash does
  not, and is recorded here rather than faked with a row of small boxes.
  """
  use Kati.Screens.Root, root: :calendar

  alias Kati.Calendar.SampleAgenda
  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaSeparator
  alias Kati.Design.Images
  alias Kati.Theme
  alias Kati.UI

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :agenda, SampleAgenda.agenda())

  @doc false
  def content(assigns) do
    agenda = assigns.agenda

    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={132}>
        {Kati.Screens.Agenda.header()}
        {Kati.Screens.Agenda.switcher()}
        {Enum.map(agenda.groups, fn group -> Kati.Screens.Agenda.group(group) end)}
        {Kati.Screens.Agenda.footer(agenda.footer)}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def header do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Text
          text="Agenda"
          text_size={24}
          font_weight="bold"
          letter_spacing={-0.03}
          text_color={:on_surface}
          max_lines={1}
        />
        <Spacer weight={1.0} />
        {Kati.Screens.Agenda.disc("search")}
        <Spacer size={9} />
        {Kati.Screens.Agenda.disc("tune")}
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  A header disc: `Kati.Components.MishkaActionIcon`, filled and circular.

  An icon-only button is what an Action Icon is for, and `shape: :circle`
  resolves to an exact `size / 2` — the 22 that was written here by hand.

  **`shadow` is the whole point.** `variant: :filled` paints a fill and stops
  there, which reads as a flat patch of paper; the design's disc floats, and
  `Kati.Theme.shadow_button()` is how far. That prop is new this round, and its
  absence is why this stayed a hand-rolled `Box`.

  The glyph goes in as a child: the component's `icon:` shorthand builds a
  `Text` with no `font_family`, so `"search"` would be typeset as the word
  rather than resolved through the Material Symbols ligature — and
  `Kati.UI.symbol/2` keeps `Kati.Icons.glyph!/1`'s raise for a name outside the
  shipped subset.

  ## Why the pixels do not move

  The node is `Box{width: 44, height: 44, align: :center, corner_radius: 22.0,
  background: …, shadow: …}` — every number this wrote by hand. `align: :center`
  and `align="center"` reach the bridge as the same string, and `corner_radius`
  is read with `floatProp`, so `22.0` is `22`.

  The one addition is the `Row` the component wraps children in, and it is
  inert: `MobBridge.kt`'s row branch never fills, so a propless `Row` hugs its
  single child on both axes and the Box centres the same rectangle.
  """
  def disc(icon) do
    MishkaActionIcon.action_icon(
      %{
        size: 44,
        shape: :circle,
        variant: :filled,
        background: Kati.Theme.card(:light),
        shadow: Kati.Theme.shadow_button()
      },
      [Kati.UI.symbol(icon, size: 21)]
    )
  end

  @doc false
  def switcher do
    bar =
      Kati.Screens.ViewSwitcher.bar([
        {"Day", false},
        {"Week", false},
        {"Month", false},
        {"Agenda", true}
      ])

    ~MOB"""
    <Column fill_width={true}>
      {bar}
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def group(group) do
    last = length(group.rows) - 1

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.Agenda.kicker(group)}
      <Column
        fill_width={true}
        background={Theme.card(:light)}
        corner_radius={20}
        shadow={Theme.shadow_card_soft()}
        padding_left={15}
        padding_right={15}
        padding_top={4}
        padding_bottom={4}
      >
        {group.rows
         |> Enum.with_index()
         |> Enum.map(fn {row, i} -> Kati.Screens.Agenda.row(row, i < last) end)}
      </Column>
      <Spacer size={20} />
    </Column>
    """
  end

  # Two mono labels on one baseline: the day in ink, its weight in #A0998F.
  @doc false
  def kicker(group) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        <Text
          text={group.kicker}
          font_family="mono"
          text_size={10.5}
          letter_spacing={0.16}
          text_color={:on_surface}
          max_lines={1}
        />
        <Spacer size={9} />
        <Text text={group.sub} font_family="mono" text_size={10.5} text_color={0xFFA0998F} max_lines={1} />
      </Row>
      <Spacer size={10} />
    </Column>
    """
  end

  @doc false
  def row(row, rule?) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={13} padding_bottom={13}>
        <Column width={38}>
          <Text text={row.time} font_family="mono" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
        </Column>
        <Spacer size={12} />
        <Box width={3} height={30} corner_radius={2} background={row.rule} />
        <Spacer size={12} />
        {Kati.Screens.Agenda.thumb(row)}
        <Column weight={1.0}>
          <Text
            text={row.title}
            text_size={13}
            font_weight="semibold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={3} />
          <Text text={row.sub} text_size={11.5} text_color={0xFF8A8479} max_lines={1} />
        </Column>
      </Row>
      {Kati.Screens.Agenda.hairline(rule?)}
    </Column>
    """
  end

  # A poster only where the drawing has one — the two screen rows and the
  # cinema release. A row without artwork closes the gap rather than reserving
  # an empty 26pt slot, which is what the design does too.
  @doc false
  def thumb(%{seed: nil}), do: ~MOB"<Spacer size={0} />"

  def thumb(row) do
    case Images.poster(row.seed) do
      nil ->
        ~MOB"""
        <Row align="center">
          <Box width={26} height={37} corner_radius={5} background={0xFFE4E0D9} />
          <Spacer size={12} />
        </Row>
        """

      src ->
        ~MOB"""
        <Row align="center">
          <Image src={src} width={26} height={37} corner_radius={5} content_mode="fill" />
          <Spacer size={12} />
        </Row>
        """
    end
  end

  @doc """
  The rule between two agenda rows — `Kati.Components.MishkaSeparator`, and it
  has to be `render: :box`.

  The component's default is `:divider`, which the bridge maps to Material3's
  `HorizontalDivider` — an antialiased `drawLine`, not a filled rect. At this
  device's 2.6875x a 1dp rule is handed a 3px canvas and a 2.6875px stroke, so
  the last pixel row lands at ~69% coverage: a full-width row 4-5/255 lighter
  than the two above it. `render: :box` paints three full rows of
  `rgba(26,25,23,.07)`, which is the hairline this drew by hand.

  A `:box` rule carries one extra node, a `<Spacer size={1}/>` that exists for
  iOS (`MobBox` drops a Box's height unless the Box also has a width). On
  Android it is a 1x1dp child with no background inside a `Box` already pinned
  to `fill_width` and `height: 1` — it measures nothing new and paints nothing.
  """
  def hairline(false), do: ~MOB"<Spacer size={0} />"

  def hairline(true),
    do: MishkaSeparator.separator(render: :box, color: 0x121A1917, thickness: 1)

  @doc false
  def footer(label) do
    ~MOB"""
    <Box
      fill_width={true}
      corner_radius={18}
      border_color={0x291A1917}
      border_width={1.5}
      padding={14}
      align="center"
    >
      <Row align="center">
        {UI.symbol("expand_more", size: 18, color: 0xFF8A8479)}
        <Spacer size={7} />
        <Text text={label} text_size={13} font_weight="semibold" text_color={0xFF5C574F} max_lines={1} />
      </Row>
    </Box>
    """
  end

  # ── What a tap changes ────────────────────────────────────────────────────

  # The switcher this screen draws is its only control, and its three live
  # segments (`view_Day`, `view_Week`, `view_Month`) are routed by the module
  # that drew them. `Kati.Screens.ViewSwitcher.handle_tap/2` returns the socket
  # untouched for anything that is not a `view_*` tag, so delegating the whole
  # callback is safe and stays right if this screen grows a control of its own
  # — those clauses go above this line.
  @impl true
  def handle_tap(tag, socket), do: Kati.Screens.ViewSwitcher.handle_tap(tag, socket)
end
