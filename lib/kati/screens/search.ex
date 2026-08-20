defmodule Kati.Screens.Search do
  @moduledoc """
  Screen 19 — Search everything, pushed under Home.

  Built to `.scratch/design/screens/19.html`: the `64px 21px 40px` frame with
  no dock, a focused field carrying its 2px ink ring and orange caret, four
  counted filter chips, and then the hits **grouped by where they live** —
  Screen, Calendar, Notes — with a recent-searches shelf underneath.

  ## Why the groups look different from each other

  Three sections, three shapes, on purpose. A title is a card with its poster
  and a chevron, because it is somewhere to go. Calendar hits are rows inside
  one card, because they are a schedule and the dates are the spine. The note
  is on cream and quotes itself with the match highlighted in place, because
  it is the user's own words. Flattening these into one list of identical rows
  would lose the only thing the screen is claiming: one query, four kinds of
  answer.

  ## The eyebrow dash is not always orange

  The first group's dash is `#E8823C`; every group after it is `#C4BDB3`. That
  is the design telling you where the strongest match is rather than
  decorating each heading equally, so `Kati.UI.eyebrow/2` is used for the
  first and `section/2` here draws the muted ones. Orange still means
  new/now — here, *this is the hit*.

  ## What the chips do

  The four counted chips narrow the page to one group — Screen, Calendar or
  Notes — and "All" puts all three back. The recent shelf is not narrowed with
  them: it is a shortcut into a new search, not a result, and hiding the user's
  own history because they filtered to Calendar would be an odd punishment.

  A recent chip fills to show it is picked and stops there. Writing it into the
  field would leave six hits for `hollow` sitting under a query that says
  `dentist`, and until an index exists the screen cannot answer the new
  question — so it does not pretend to have been asked.

  ## Not `Kati.Screens.Pushed`

  The drawing puts the back pill **in the flow**, at the top of the scroll,
  with its own `#FBFAF8` fill and button shadow — not floating over the
  content at 54pt like the shared pushed chrome. Using the shared chrome would
  draw a second, differently styled pill on top of the search field, so this
  screen owns its frame and its dismissal, the way screens 06 and 08 do. Back
  goes to Home.
  """
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Components.MishkaChip
  alias Kati.Components.MishkaSeparator
  alias Kati.Screens.Search.Sample
  alias Kati.UI

  # `filter` is "All" and `recent` is nil because that is the state the drawing
  # is in: the All chip filled, all three groups on the page, and no recent
  # search picked out of the shelf.
  def mount(_params, _session, socket) do
    Mob.Theme.set(Kati.Theme.light())
    {:ok, Mob.Socket.assign(socket, results: Sample.results(), filter: "All", recent: nil)}
  end

  def render(assigns) do
    results = assigns.results
    filter = assigns.filter
    recent = assigns.recent

    ~MOB"""
    <Box fill_width={true} fill_height={true} background={:background} layout_direction={Kati.Locale.direction_prop()}>
      <Scroll>
        <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={40}>
          {Kati.Screens.Search.back()}
          {Kati.Screens.Search.field(results)}
          {Kati.Screens.Search.chips(filter)}
          {Kati.Screens.Search.groups(results, filter)}
          {Kati.Screens.Search.section("Recent")}
          {Kati.Screens.Search.recent(results, recent)}
        </Column>
      </Scroll>
    </Box>
    """
  end

  def handle_info({:tap, :back}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}

  # One clause for every chip on the screen: the tag carries the label, so a
  # fifth filter or a fifth recent search is a change to the sample, not here.
  def handle_info({:tap, tag}, socket) do
    case Atom.to_string(tag) do
      "filter_" <> label ->
        {:noreply, Mob.Socket.assign(socket, :filter, label)}

      # A second tap on the same recent search puts it back — the shelf is a
      # shortcut, not a mode, so there has to be a way out of it.
      "recent_" <> label ->
        picked = if socket.assigns.recent == label, do: nil, else: label
        {:noreply, Mob.Socket.assign(socket, :recent, picked)}

      _other ->
        {:noreply, socket}
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  # A Row, not a Box: the pill hugs "Home" and the drawing's asymmetric
  # `padding:0 16px 0 12px` keeps the chevron optically centred against text
  # that has no left bearing.
  @doc false
  def back do
    tap = {self(), :back}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Row
          height={44}
          corner_radius={22}
          background={Kati.Theme.card(:light)}
          shadow={Kati.Theme.shadow_button()}
          padding_left={12}
          padding_right={16}
          align="center"
          on_tap={tap}
        >
          {Kati.UI.symbol("arrow_back_ios_new", size: 17)}
          <Spacer size={6} />
          <Text text="Home" text_size={13.5} font_weight="semibold" letter_spacing={-0.01} text_color={:on_surface} max_lines={1} />
        </Row>
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  # `0 0 0 2px #1A1917` is a ring, so it is a border; the drawing's remaining
  # `0 8px 18px -14px rgba(26,25,23,.6)` is a single layer and darker than
  # `Kati.Theme.shadow_search/0`, so it is written out rather than borrowed.
  @doc false
  def field(results) do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        height={52}
        corner_radius={26}
        background={Kati.Theme.card(:light)}
        border_width={2}
        border_color={0xFF1A1917}
        shadow="0 8 18 -14 #991A1917"
        padding_left={18}
        padding_right={18}
        align="center"
      >
        {Kati.UI.symbol("search", size: 20)}
        <Spacer size={11} />
        <Text text={results.query} text_size={14.5} font_weight="medium" text_color={:on_surface} max_lines={1} />
        <Spacer size={2} />
        <Box width={2} height={19} background={0xFFE8823C} />
        <Spacer weight={1.0} />
        {Kati.UI.symbol("cancel", size: 19, color: 0xFFC4BDB3, fill: true)}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  # The sample's own `on?` is ignored and selection comes from the assign, so
  # there is one place that knows which chip is lit. It starts on "All", which
  # is the chip the sample marks and the chip the drawing fills.
  @doc false
  def chips(active) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {Kati.Screens.Search.Sample.chips()
         |> Enum.map(fn {label, count, _on?} ->
           Kati.Screens.Search.chip(label, count, label == active)
         end)
         |> Enum.intersperse(Kati.Screens.Search.gap())}
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc "The drawing's 7pt flex gap, between chips and between chip rows."
  def gap, do: ~MOB"<Spacer size={7} />"

  @doc """
  One counted filter chip — `Kati.Components.MishkaChip`, count in the
  **trailing slot**.

  The count is the label's own colour at .6 alpha, not a second token — the
  design tints it down rather than colouring it differently, so a chip reads
  as one object with a quiet number after it. That is also why the count goes
  in as a *node* rather than as a string: `trailing` renders a string in the
  chip's own ink and size, and this one is mono at 10.5 in a colour of its
  own.

  Two of the port's props are new this round and both are load-bearing here.
  `trailing`/`trailing_gap` is the slot itself — before it a chip was a Box
  around exactly one Text, so a chip with a number after its name could not be
  built at all. The rest (`height`, `padding_x`/`padding_y`, `corner_radius`,
  `text_size`, `font_weight`, `max_lines`, `unchecked_color`,
  `unchecked_text_color`) are what let it be 32 tall on Kati's greys instead of
  the port's old hardcoded look.

  **Why the pixels do not move.** The chip was a `Row` holding label, gap and
  count; the port builds a `Box` holding a `Row` holding label, gap and count.
  The outer node hugs either way — a `Row` by nature, the `Box` by
  `fill_width={false}`, which the bridge reads since fence K-17 — and both run
  background → rounded clip → `padding(0, 14, 0, 14)` → `height(32)`, so the
  chip is 32 tall and `14 + label + 6 + count + 14` wide in both trees.

  The extra `Row` does not move the two runs either. Before, each Text was
  centred in the 32pt Row, putting both centres at 16. Now the inner `Row`
  centres the 10.5 count against the 12.5 label — this bridge's default
  vertical alignment for a `Row` is `CenterVertically`, so the port omitting
  `align` on it changes nothing — and the `Box` centres that group in the 32:
  `(32 - h) / 2 + h / 2` is 16 again.
  """
  def chip(label, count, on?) do
    # The tag carries the label, so one handler serves every chip.
    count_color = if on?, do: 0x99FBFAF8, else: 0x995C574F

    MishkaChip.chip(
      label: label,
      checked: on?,
      on_toggle: {self(), String.to_atom("filter_" <> label)},
      color: Kati.Theme.ink(),
      text_color: 0xFFFBFAF8,
      unchecked_color: Kati.Theme.card(:light),
      unchecked_text_color: 0xFF5C574F,
      height: 32,
      padding_x: 14,
      padding_y: 0,
      corner_radius: 16,
      text_size: 12.5,
      font_weight: :semibold,
      max_lines: 1,
      trailing: Kati.Screens.Search.chip_count(count, count_color),
      trailing_gap: 6
    )
  end

  @doc false
  def chip_count(count, color) do
    ~MOB"""
    <Text text={to_string(count)} font_family="mono" text_size={10.5} text_color={color} max_lines={1} />
    """
  end

  @doc """
  The result groups a filter leaves standing, in the drawing's order.

  "All" is every group, which is the page as drawn; any other chip is the one
  group it names. The recent shelf is not in here — it is a shortcut, not a
  result, and narrowing to Calendar should not hide the user's own history.

  The accent dash goes to whichever group is **first**, not to Screen
  specifically: the moduledoc's rule is positional, and orange means "this is
  the hit". Filtering to Notes makes Notes the hit.
  """
  @spec groups(map(), String.t()) :: term()
  def groups(results, filter) do
    visible =
      [{"Screen", :titles}, {"Calendar", :calendar}, {"Notes", :note}]
      |> Enum.filter(fn {label, _key} -> filter == "All" or filter == label end)
      |> Enum.with_index()

    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(visible, fn {{label, key}, i} ->
        Kati.Screens.Search.group(results, label, key, i == 0)
      end)}
    </Column>
    """
  end

  @doc false
  def group(results, label, key, first?) do
    heading = if first?, do: UI.eyebrow(label), else: Kati.Screens.Search.section(label)
    body = Kati.Screens.Search.body(results, key)

    ~MOB"""
    <Column fill_width={true}>
      {heading}
      {body}
    </Column>
    """
  end

  @doc false
  def body(results, :titles), do: Kati.Screens.Search.titles(results)
  def body(results, :calendar), do: Kati.Screens.Search.calendar(results)
  def body(results, :note), do: Kati.Screens.Search.note(results)

  # `Kati.UI.eyebrow/2` with the accent dash marks the first, strongest group;
  # every group after it takes the drawing's muted #C4BDB3 dash.
  @doc false
  def section(label) do
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
        />
      </Row>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc false
  def titles(results) do
    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(results.titles, fn row -> Kati.Screens.Search.title_row(row) end)}
      <Spacer size={13} />
    </Column>
    """
  end

  @doc false
  def title_row(row) do
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
        {Kati.Screens.Search.thumb(row)}
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text text={row.title} text_size={13.5} font_weight="bold" text_color={:on_surface} max_lines={1} />
          <Spacer size={4} />
          <Text text={row.sub} text_size={11.5} text_color={0xFF8A8479} max_lines={1} />
        </Column>
        <Spacer size={12} />
        {Kati.UI.symbol("chevron_right", size: 18, color: 0xFFC4BDB3)}
      </Row>
      <Spacer size={9} />
    </Column>
    """
  end

  @doc false
  def thumb(row) do
    case Kati.Design.Images.poster(row.seed) do
      nil ->
        ~MOB"<Box width={36} height={51} corner_radius={7} background={0xFFE4E0D9} />"

      src ->
        ~MOB"""
        <Image src={src} width={36} height={51} corner_radius={7} content_mode="fill" />
        """
    end
  end

  @doc false
  def calendar(results) do
    last = length(results.calendar) - 1

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
        {results.calendar
         |> Enum.with_index()
         |> Enum.map(fn {row, i} -> Kati.Screens.Search.calendar_row(row, i < last) end)}
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def calendar_row(row, rule?) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={13} padding_bottom={13}>
        <Column width={44}>
          <Text text={row.date} font_family="mono" text_size={10} letter_spacing={0.06} text_color={0xFFA9A29A} max_lines={1} />
        </Column>
        <Spacer size={13} />
        <Text text={row.title} text_size={12.5} font_weight="semibold" text_color={:on_surface} weight={1.0} max_lines={1} />
        <Spacer size={13} />
        <Text text={row.time} font_family="mono" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
      </Row>
      {Kati.Screens.Search.hairline(rule?)}
    </Column>
    """
  end

  @doc false
  def hairline(false), do: ~MOB"<Spacer size={0} />"
  # `MishkaSeparator` rather than a hand-rolled Box, and `render: :box` rather
  # than the component's `:divider` default.
  #
  # `:divider` is NOT the Box this used to be. The comment that stood here said
  # it was — that Compose's `HorizontalDivider` is
  # `Box(fillMaxWidth().height(t).background(color))` — and that is wrong:
  # Material3 draws it as `Canvas { drawLine(strokeWidth = t.toPx()) }`, an
  # ANTIALIASED stroke. At this device's 2.6875x a 1dp rule gets a 3px canvas
  # and a 2.6875px stroke centred in it, so the bottom pixel row lands at ~69%
  # coverage — a full-width row 4-5/255 lighter than the two above it. The
  # adoption softened the hairline by one pixel row and nothing said so.
  #
  # `render: :box` is the component's filled-rect primitive: `<Box fill_width
  # height={thickness} background={color}>`, which is the node that was written
  # here by hand before the adoption, so the rule goes back to three full-colour
  # rows. (Its `<Spacer size={1} />` child is an iOS height workaround — on
  # Android the Box's own `height` pins it and the background covers it.)
  #
  # `color` is passed rather than left to the component's `:border` default:
  # Kati's border token is 0x14000000 and the drawing's rule is 0x121A1917.
  def hairline(true),
    do: MishkaSeparator.separator(color: 0x121A1917, thickness: 1, render: :box)

  # The note card carries no shadow in the drawing — cream is the ground for
  # the user's own words, and lifting it would make it compete with the hits.
  @doc false
  def note(results) do
    note = results.note
    {inline, rest} = note_lines(note)

    ~MOB"""
    <Column fill_width={true}>
      <Column fill_width={true} background={0xFFFBF1DE} corner_radius={20} padding={16}>
        <Text
          text={note.eyebrow}
          font_family="mono"
          text_size={10}
          letter_spacing={0.14}
          text_color={0xFFB09A72}
          max_lines={1}
        />
        <Spacer size={8} />
        <Row fill_width={true} align="center">
          <Text text={note.lead} text_size={13} line_height={1.55} text_color={0xFF4A4238} max_lines={1} />
          <Spacer size={4} />
          <Row background={0x47E8823C} align="center">
            <Text text={note.match} text_size={13} line_height={1.55} text_color={0xFF4A4238} max_lines={1} />
          </Row>
          <Spacer size={4} />
          <Text text={inline} text_size={13} line_height={1.55} text_color={0xFF4A4238} max_lines={1} />
        </Row>
        {Kati.Screens.Search.note_leading()}
        <Text text={rest} text_size={13} line_height={1.55} text_color={0xFF4A4238} />
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  The half-leading `line_height` cannot supply, because it is trimmed away.

  `line_height={1.55}` on 13pt text asks for a 20.15pt line box, and the bridge
  does set it — but Compose's default `LineHeightStyle` trims the leading off
  the top of the first line and the bottom of the last, so on a Text that holds
  **one** line it changes nothing. The drawing's paragraph is one wrapping
  block and gets its 20.15 between the lines; ours is a `Row` of runs and then
  a `Text`, two separate one-line boxes, and a capture measured them 16.3
  apart. This is the 3.9 that trimming removed, so the break sits where the
  export puts it.

  A second `Text` run inside the first line — the highlight — is why the two
  cannot be one node: there is no inline span on this bridge.
  """
  def note_leading, do: ~MOB"<Box fill_width={true} height={4} />"

  @doc """
  Splits the quoted sentence where the drawing breaks it.

  The highlight has to share a line with the words either side of it, and a
  `Row` does not wrap — so the sentence is kept whole in the sample and cut
  here, at a declared word count, rather than stored pre-broken.
  """
  @spec note_lines(map()) :: {String.t(), String.t()}
  def note_lines(note) do
    {inline, rest} = note.tail |> String.split(" ") |> Enum.split(note.inline_words)
    {Enum.join(inline, " "), Enum.join(rest, " ")}
  end

  @doc false
  def recent(results, picked) do
    ~MOB"""
    <Column fill_width={true}>
      {results.recent
       |> Enum.map(fn row -> Kati.Screens.Search.recent_row(row, picked) end)
       |> Enum.intersperse(Kati.Screens.Search.gap())}
    </Column>
    """
  end

  @doc false
  def recent_row(row, picked) do
    ~MOB"""
    <Row fill_width={true} align="center">
      {row
       |> Enum.map(fn label -> Kati.Screens.Search.recent_chip(label, label == picked) end)
       |> Enum.intersperse(Kati.Screens.Search.gap())}
    </Row>
    """
  end

  # Picking a recent search fills the chip the way the filter chips fill —
  # ink, paper text, the clock at .6 of it. It does not rewrite the query,
  # because the hits below still describe "hollow" and a field that said
  # "dentist" over them would be the screen lying about its own results.
  @doc false
  def recent_chip(label, on?) do
    tap = {self(), String.to_atom("recent_" <> label)}
    background = if on?, do: Kati.Theme.ink(), else: 0xFFF4F1EC
    color = if on?, do: 0xFFFBFAF8, else: 0xFF5C574F
    icon = if on?, do: 0x99FBFAF8, else: 0xFFA9A29A

    ~MOB"""
    <Row height={30} corner_radius={15} background={background} padding_left={12} padding_right={12} align="center" on_tap={tap}>
      {Kati.UI.symbol("history", size: 14, color: icon)}
      <Spacer size={6} />
      <Text text={label} text_size={12} text_color={color} max_lines={1} />
    </Row>
    """
  end
end
