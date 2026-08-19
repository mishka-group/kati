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

  alias Kati.Screens.Search.Sample
  alias Kati.UI

  def mount(_params, _session, socket) do
    Mob.Theme.set(Kati.Theme.light())
    {:ok, Mob.Socket.assign(socket, :results, Sample.results())}
  end

  def render(assigns) do
    results = assigns.results

    ~MOB"""
    <Box fill_width={true} fill_height={true} background={:background} layout_direction={Kati.Locale.direction_prop()}>
      <Scroll>
        <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={40}>
          {Kati.Screens.Search.back()}
          {Kati.Screens.Search.field(results)}
          {Kati.Screens.Search.chips()}
          {UI.eyebrow("Screen")}
          {Kati.Screens.Search.titles(results)}
          {Kati.Screens.Search.section("Calendar")}
          {Kati.Screens.Search.calendar(results)}
          {Kati.Screens.Search.section("Notes")}
          {Kati.Screens.Search.note(results)}
          {Kati.Screens.Search.section("Recent")}
          {Kati.Screens.Search.recent(results)}
        </Column>
      </Scroll>
    </Box>
    """
  end

  def handle_info({:tap, :back}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}
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

  @doc false
  def chips do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {Kati.Screens.Search.Sample.chips()
         |> Enum.map(fn chip -> Kati.Screens.Search.chip(chip) end)
         |> Enum.intersperse(Kati.Screens.Search.gap())}
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc "The drawing's 7pt flex gap, between chips and between chip rows."
  def gap, do: ~MOB"<Spacer size={7} />"

  # The count is the label's own colour at .6 alpha, not a second token — the
  # design tints it down rather than colouring it differently, so a chip reads
  # as one object with a quiet number after it.
  @doc false
  def chip({label, count, on?}) do
    background = if on?, do: Kati.Theme.ink(), else: Kati.Theme.card(:light)
    color = if on?, do: 0xFFFBFAF8, else: 0xFF5C574F
    count_color = if on?, do: 0x99FBFAF8, else: 0x995C574F

    ~MOB"""
    <Row height={32} corner_radius={16} background={background} padding_left={14} padding_right={14} align="center">
      <Text text={label} text_size={12.5} font_weight="semibold" text_color={color} max_lines={1} />
      <Spacer size={6} />
      <Text text={to_string(count)} font_family="mono" text_size={10.5} text_color={count_color} max_lines={1} />
    </Row>
    """
  end

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
  def hairline(true), do: ~MOB"<Box fill_width={true} height={1} background={0x121A1917} />"

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
        <Text text={rest} text_size={13} line_height={1.55} text_color={0xFF4A4238} />
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

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
  def recent(results) do
    ~MOB"""
    <Column fill_width={true}>
      {results.recent
       |> Enum.map(fn row -> Kati.Screens.Search.recent_row(row) end)
       |> Enum.intersperse(Kati.Screens.Search.gap())}
    </Column>
    """
  end

  @doc false
  def recent_row(row) do
    ~MOB"""
    <Row fill_width={true} align="center">
      {row
       |> Enum.map(fn label -> Kati.Screens.Search.recent_chip(label) end)
       |> Enum.intersperse(Kati.Screens.Search.gap())}
    </Row>
    """
  end

  @doc false
  def recent_chip(label) do
    ~MOB"""
    <Row height={30} corner_radius={15} background={0xFFF4F1EC} padding_left={12} padding_right={12} align="center">
      {Kati.UI.symbol("history", size: 14, color: 0xFFA9A29A)}
      <Spacer size={6} />
      <Text text={label} text_size={12} text_color={0xFF5C574F} max_lines={1} />
    </Row>
    """
  end
end
