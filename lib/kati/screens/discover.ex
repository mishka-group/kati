defmodule Kati.Screens.Discover do
  @moduledoc """
  Screen 11 — Discover, pushed under Library.

  Built to `.scratch/design/screens/11.html`: a chip row, a three-poster rail
  of matches, a card of people you follow, and the titles about to leave a
  service.

  Two of the three sections are recommendations and one is a deadline, and the
  design marks the difference with the eyebrow dash rather than with a
  different layout. "Because you watched" and "People you follow" get the
  orange dash because something is new; "Leaving Lumen+ in 7 days" gets the
  grey one, because a thing disappearing is not a thing arriving. That is
  `Kati.UI.Eyebrow.quiet/1`.

  A person's row ends in an orange dot when they have news and a muted `check`
  when they do not — the same distinction, at row scale, and the reason the
  sample carries someone with nothing new.

  The rail is three posters with 12pt gutters, each taking an equal share of
  whatever is left. The drawing's 112pt is arithmetic for its own 402pt frame —
  112*3 + 12*2 = 360 — and a real 411dp device leaves ~370dp between the 21pt
  margins, so a fixed 112 stops ~9dp short and ragged. Weighting the three
  columns keeps the row exactly full at any width, which is what the drawing
  meant.

  ## What the chips select

  The chip row names the sections underneath it, so a chip keeps the section it
  names and drops the others. **"For you" is the whole feed**, which is what the
  drawing shows and therefore what the screen shows at rest — the default is
  read off the sample's own `selected` flag rather than typed here, so the
  resting screen cannot drift from the data.

  "Awards" names a section this feed does not carry, so it empties the screen
  rather than relabelling one of the others as awards. Screen 03 makes the same
  trade with its Books and Music shelves: showing the emptiness honestly beats
  a chip that lies about what is behind it.

  ## Schedule

  The button on a leaving row is that row's only control, so it has to change
  when it is used. Scheduled swaps the ink pill for the toned one screen 10
  gives a row that has stopped asking for anything, and says `Scheduled`.
  Tapping it again undoes it — nothing here writes to a store yet, so the
  screen owns the state and reversing it is the honest affordance.
  """
  use Kati.Screens.Pushed, back: "Library"

  alias Kati.Screens.Discover.Sample
  alias Kati.Theme
  alias Kati.UI

  @impl true
  def load(socket) do
    feed = Sample.feed()

    Mob.Socket.assign(socket,
      feed: feed,
      chip: Kati.Screens.Discover.default_chip(feed),
      scheduled: []
    )
  end

  @doc """
  The chip the data marks selected.

  Read rather than typed: the resting screen is compared against the drawing,
  and the drawing's selected chip lives in the sample. Taking it from there
  means the two cannot disagree.
  """
  @spec default_chip(map()) :: String.t()
  def default_chip(feed) do
    Enum.find_value(feed.chips, "For you", fn c -> if c.selected, do: c.label end)
  end

  @doc """
  Whether a section survives the selected chip.

  See the moduledoc: "For you" is everything, "People" and "Leaving" narrow to
  the section they name, and a chip naming a section this feed has none of
  keeps nothing.
  """
  @spec shows?(atom(), String.t()) :: boolean()
  def shows?(section, chip) do
    case chip do
      "For you" -> true
      "People" -> section == :people
      "Leaving" -> section == :leaving
      _ -> false
    end
  end

  @doc false
  def content(assigns) do
    f = assigns.feed
    chip = assigns.chip
    scheduled = assigns.scheduled

    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={40}>
        {Kati.Screens.Discover.pill_row()}
        {Kati.Screens.Discover.header(f)}
        {Kati.Screens.Discover.chips(f, chip)}
        {Kati.Screens.Discover.because_section(f, chip)}
        {Kati.Screens.Discover.people_section(f, chip)}
        {Kati.Screens.Discover.leaving_section(f, chip, scheduled)}
      </Column>
    </Scroll>
    """
  end

  # The drawing gives the back pill a row of its own — 42pt tall with 16pt
  # under it — before the title. Kati.Screens.Pushed floats the pill, so this
  # reserves the space it occupies rather than drawing a second one.
  @doc false
  def pill_row, do: ~MOB"<Spacer size={58} />"

  @doc false
  def header(f) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column weight={1.0}>
          <Text text="Discover" text_size={28} font_weight="bold" letter_spacing={-0.03} text_color={:on_surface} />
          <Spacer size={5} />
          <Text text={f.subtitle} font_family="mono" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
        </Column>
        <Spacer size={9} />
        <Box
          width={44}
          height={44}
          corner_radius={22}
          background={Kati.Theme.card(:light)}
          shadow={Kati.Theme.shadow_button()}
          align="center"
        >
          {Kati.UI.symbol("tune", size: 21)}
        </Box>
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def chips(f, active) do
    ~MOB"""
    <Column fill_width={true}>
      <Scroll axis="horizontal">
        <Row align="center">
          {f.chips
           |> Enum.map(fn c -> Kati.Screens.Discover.chip(c, c.label == active) end)
           |> Enum.intersperse(Kati.Screens.Discover.chip_gap())}
        </Row>
      </Scroll>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def chip_gap, do: ~MOB"<Spacer size={7} />"

  @doc false
  def chip(c, on?) do
    # The tag carries the label, so one handler serves every chip and a new
    # chip is a data change rather than a code change.
    tap = {self(), String.to_atom("filter_" <> c.label)}
    bg = if on?, do: Theme.ink(), else: Theme.card(:light)
    fg = if on?, do: 0xFFFBFAF8, else: 0xFF5C574F

    ~MOB"""
    <Row height={32} corner_radius={16} background={bg} padding_left={14} padding_right={14} align="center" on_tap={tap}>
      <Text text={c.label} text_size={12.5} font_weight="semibold" text_color={fg} max_lines={1} />
      {Kati.Screens.Discover.chip_count(c.count, on?)}
    </Row>
    """
  end

  # The count rides at .6 of the label's own colour rather than a token of its
  # own, so it stays a shade of the chip it sits on in either state.
  @doc false
  def chip_count(nil, _selected), do: ~MOB"<Spacer size={0} />"

  def chip_count(count, selected) do
    fg = if selected, do: 0x99FBFAF8, else: 0x995C574F

    ~MOB"""
    <Row align="center">
      <Spacer size={6} />
      <Text text={count} font_family="mono" text_size={10.5} text_color={fg} max_lines={1} />
    </Row>
    """
  end

  # Each section is its eyebrow plus its body, kept together so that dropping
  # one drops its label with it — a heading over nothing is worse than no
  # heading. The wrapper Column stacks and fills like the frame it sits in, so
  # the visible section is drawn exactly where it was before.
  @doc false
  def because_section(f, chip) do
    if shows?(:because, chip) do
      ~MOB"""
      <Column fill_width={true}>
        {UI.eyebrow(f.because)}
        {Kati.Screens.Discover.rail(f)}
      </Column>
      """
    else
      ~MOB"<Spacer size={0} />"
    end
  end

  @doc false
  def people_section(f, chip) do
    if shows?(:people, chip) do
      ~MOB"""
      <Column fill_width={true}>
        {UI.eyebrow("People you follow")}
        {Kati.Screens.Discover.people(f)}
      </Column>
      """
    else
      ~MOB"<Spacer size={0} />"
    end
  end

  @doc false
  def leaving_section(f, chip, scheduled) do
    if shows?(:leaving, chip) do
      ~MOB"""
      <Column fill_width={true}>
        {Kati.UI.Eyebrow.quiet(f.leaving_label)}
        {Kati.Screens.Discover.leaving(f, scheduled)}
      </Column>
      """
    else
      ~MOB"<Spacer size={0} />"
    end
  end

  @doc false
  def rail(f) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {f.picks |> Enum.map(&Kati.Screens.Discover.pick/1) |> Enum.intersperse(Kati.Screens.Discover.rail_gap())}
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def rail_gap, do: ~MOB"<Spacer size={12} />"

  # Weighted rather than 112 wide: three equal shares of the real content width
  # fill the row on any device, where a fixed 112 only fills the drawing's frame.
  @doc false
  def pick(p) do
    ~MOB"""
    <Column weight={1.0}>
      <Box fill_width={true} height={158} corner_radius={13} background={0xFFE4E0D9} shadow={Kati.Theme.shadow_card_soft()}>
        {Kati.Screens.Discover.poster(p.seed)}
      </Box>
      <Spacer size={9} />
      <Text text={p.title} text_size={12.5} font_weight="bold" text_color={:on_surface} max_lines={1} />
      <Spacer size={3} />
      <Text text={p.match} font_family="mono" text_size={10.5} text_color={0xFFE8823C} max_lines={1} />
    </Column>
    """
  end

  @doc false
  def poster(seed) do
    case Sample.image(seed) do
      nil ->
        ~MOB"<Spacer size={0} />"

      src ->
        ~MOB"""
        <Image src={src} fill_width={true} height={158} corner_radius={13} content_mode="fill" />
        """
    end
  end

  @doc false
  def people(f) do
    last = length(f.people) - 1

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
        {f.people
         |> Enum.with_index()
         |> Enum.map(fn {row, i} -> Kati.Screens.Discover.person_row(row, i < last) end)}
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def person_row(p, rule?) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={13} padding_bottom={13}>
        {Kati.Screens.Discover.face(p.seed)}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text text={p.name} text_size={13.5} font_weight="semibold" text_color={:on_surface} max_lines={1} />
          <Spacer size={3} />
          <Text text={p.line} text_size={11.5} text_color={0xFF8A8479} max_lines={1} />
        </Column>
        <Spacer size={13} />
        {Kati.Screens.Discover.person_mark(p.new?)}
      </Row>
      {Kati.Screens.Discover.hairline(rule?)}
    </Column>
    """
  end

  @doc false
  def face(seed) do
    case Sample.image(seed) do
      nil ->
        ~MOB"<Box width={38} height={38} corner_radius={19} background={0xFFE4E0D9} />"

      src ->
        ~MOB"""
        <Image src={src} width={38} height={38} corner_radius={19} content_mode="fill" />
        """
    end
  end

  @doc false
  def person_mark(true), do: ~MOB"<Box width={8} height={8} corner_radius={4} background={0xFFE8823C} />"
  def person_mark(false), do: Kati.UI.symbol("check", size: 18, color: 0xFFC4BDB3)

  @doc false
  def leaving(f, scheduled) do
    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(f.leaving, fn row -> Kati.Screens.Discover.leaving_row(row, row.title in scheduled) end)}
    </Column>
    """
  end

  @doc false
  def leaving_row(row, done?) do
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
        {Kati.Screens.Discover.thumb(row.seed)}
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text text={row.title} text_size={13.5} font_weight="bold" text_color={:on_surface} max_lines={1} />
          <Spacer size={4} />
          <Text text={row.line} text_size={11.5} text_color={0xFF8A8479} max_lines={1} />
        </Column>
        <Spacer size={12} />
        {Kati.Screens.Discover.leaving_action(row, done?)}
      </Row>
      <Spacer size={9} />
    </Column>
    """
  end

  # The tag carries the title, so one handler serves every row.
  @doc false
  def leaving_action(row, false) do
    tap = {self(), String.to_atom("schedule_" <> row.title)}

    ~MOB"""
    <Row
      height={30}
      corner_radius={15}
      background={Kati.Theme.ink()}
      padding_left={13}
      padding_right={13}
      align="center"
      on_tap={tap}
    >
      <Text text={row.action} text_size={11.5} font_weight="semibold" text_color={0xFFFBFAF8} max_lines={1} />
    </Row>
    """
  end

  def leaving_action(row, true) do
    tap = {self(), String.to_atom("schedule_" <> row.title)}

    ~MOB"""
    <Row
      height={30}
      corner_radius={15}
      background={0xFFE4E0D9}
      padding_left={13}
      padding_right={13}
      align="center"
      on_tap={tap}
    >
      <Text text="Scheduled" text_size={11.5} font_weight="semibold" text_color={0xFF5C574F} max_lines={1} />
    </Row>
    """
  end

  @doc false
  def thumb(seed) do
    case Sample.image(seed) do
      nil ->
        ~MOB"<Box width={40} height={56} corner_radius={8} background={0xFFE4E0D9} />"

      src ->
        ~MOB"""
        <Image src={src} width={40} height={56} corner_radius={8} content_mode="fill" />
        """
    end
  end

  @doc false
  def hairline(false), do: ~MOB"<Spacer size={0} />"
  def hairline(true), do: ~MOB"<Box fill_width={true} height={1} background={0x121A1917} />"

  @impl true
  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "filter_" <> label ->
        {:noreply, Mob.Socket.assign(socket, :chip, label)}

      "schedule_" <> title ->
        {:noreply,
         Mob.Socket.update(socket, :scheduled, fn done ->
           Kati.Screens.Discover.toggle(done, title)
         end)}

      _ ->
        {:noreply, socket}
    end
  end

  @doc false
  @spec toggle([String.t()], String.t()) :: [String.t()]
  def toggle(list, title) do
    if title in list, do: List.delete(list, title), else: [title | list]
  end
end
