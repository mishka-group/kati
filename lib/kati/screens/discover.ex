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

  ## Why this screen still reads `Kati.Screens.Discover.Sample`

  Screen 03 moved onto `Kati.Media` (see `Kati.Screens.Library.shelf/0`) and
  screen 10 with it. This one did not, and it is the furthest of the four from
  being able to: the drawing's own caption says the feed is *"recommendations
  built only from your own history, plus people you follow"*, and Kati has
  neither a recommender nor a person. Every one of the three sections is a
  fact about the world outside the library, and `Kati.Media` holds only what a
  provider said about a title and what the user did with it.

  Precisely what this screen draws and no resource can currently express:

    * **the picks and their `94% match`** — a recommendation and its score.
      Nothing scores a title against a history, and there is no column to keep
      a score in. `Kati.Media.CachedTitle` is a projection of one provider
      record; a match is a statement about two.
    * **`People you follow`, and every part of a person's row** — the name,
      the role (`Director` / `Writer` / `Actor`), the credit count
      (`2 new projects`), and the trailing mark that says whether there is
      news. There is no person anywhere in the app, and that is a decision
      rather than an omission: `Kati.Media.Watch.companions` says so outright
      — *"Kati has no people table and no contacts permission, and inventing
      either to hold the word 'Jo' would be a larger privacy decision than the
      feature is asking for."* That column is also who you watched *with*,
      which is not who you follow.
    * **`Leaving Lumen+ in 7 days`, and the rows under it** — an availability
      window on a named service. There is no service resource and nothing
      stores when a title leaves one. `Kati.Media.Watch.service` is again a
      past fact about the user, not a catalogue.
    * **`Tuned to 128 titles`** — the size of the corpus the recommender is
      tuned to. `Ash.count!(Kati.Media.TrackedTitle)` is a *different* number
      wearing this one's caption, and on a seeded install it is nine.
    * **the `Leaving` chip's `5`** — a count of the section above.

  One line here *is* reachable today and is deliberately not split out:
  `Because you watched The Long Hollow` is the newest touched
  `Kati.Media.TrackedTitle` joined to its `Kati.Media.CachedTitle.title`. It
  stays frozen with the rest because it is the heading *over* the picks, and a
  real sentence above three invented posters claims more for them than drawing
  both from the sample does.
  """
  use Kati.Screens.Pushed, back: "Library"

  alias Kati.Components.MishkaAvatar
  alias Kati.Components.MishkaChip
  alias Kati.Components.MishkaScrollArea
  alias Kati.Components.MishkaSeparator
  alias Kati.Screens.Discover.Sample
  alias Kati.Theme.Palette
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
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
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
          <Text
            text="Discover"
            text_size={28}
            font_weight="bold"
            letter_spacing={-0.03}
            text_color={:on_surface}
          />
          <Spacer size={5} />
          <Text
            text={f.subtitle}
            font_family="mono"
            text_size={11}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
        <Spacer size={9} />
        <Box
          width={44}
          height={44}
          corner_radius={22}
          background={Palette.card()}
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

  # Mishka's Scroll Area rather than a bare `<Scroll axis="horizontal">`: with
  # `orientation: :horizontal` and no bound asked for, `scroll_area/2` emits
  # that exact node — it only wraps the scroller in a Box when a height,
  # background, padding or radius is passed, and none is. Same node, same
  # pixels, and the chip rail now says what it is.
  @doc false
  def chips(f, active) do
    rail =
      ~MOB"""
      <Row align="center">
        {f.chips
         |> Enum.map(fn c -> Kati.Screens.Discover.chip(c, c.label == active) end)
         |> Enum.intersperse(Kati.Screens.Discover.chip_gap())}
      </Row>
      """

    scroller = MishkaScrollArea.scroll_area([orientation: :horizontal], [rail])

    ~MOB"""
    <Column fill_width={true}>
      {scroller}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def chip_gap, do: ~MOB"<Spacer size={7} />"

  @doc """
  One feed chip — Mishka's Chip.

  A chip is a label that carries a selected state and toggles it, which is this
  row exactly, so the only thing that ever kept it hand-rolled was that the
  component decided its own metrics and its own *unselected* colours. Both are
  props now, so the drawing's numbers — 32 tall, 16 of radius, 14 of side
  padding, a 12.5pt semibold label — are stated rather than approximated, and
  the unlit fill (`card`) and ink (`#5C574F`) are passed the same way the lit
  ones always were.

  Nothing moves. `padding_x: 14` with `padding_y: 0` reproduces the Row's
  14/0, and since the bridge pads before it sizes, `height: 32` is still 32 on
  screen. The chip is a hugging `Box` where this was a `Row` (K-17 makes
  `fill_width={false}` real), and a Box that hugs its content and centres it
  cannot move that content: the inner Row is exactly the width it is given.

  The count is still its own node rather than a string, so it keeps mono at
  10.5 in its own tone; `trailing_gap: 6` is the `Spacer` that used to sit
  inside it. A chip with **no** count now emits no trailing node at all,
  where it used to carry a `<Spacer size={0}>` — a zero-sized Spacer draws
  nothing, so the row is unchanged.
  """
  @spec chip(map(), boolean()) :: map()
  def chip(c, on?) do
    MishkaChip.chip(
      label: c.label,
      checked: on?,
      # The tag carries the label, so one handler serves every chip and a new
      # chip is a data change rather than a code change.
      on_toggle: String.to_atom("filter_" <> c.label),
      color: Palette.ink_fill(),
      text_color: Palette.on_ink(),
      unchecked_color: Palette.card(),
      unchecked_text_color: Palette.ink_soft(),
      height: 32,
      corner_radius: 16,
      padding_x: 14,
      padding_y: 0,
      text_size: 12.5,
      font_weight: :semibold,
      max_lines: 1,
      trailing_gap: 6,
      trailing: Kati.Screens.Discover.chip_count(c.count, on?)
    )
  end

  # The count rides at .6 of the label's own colour rather than a token of its
  # own, so it stays a shade of the chip it sits on in either state. `nil` is
  # no trailing slot rather than an empty one — the chip then builds the same
  # single-Text body it built before the slot existed.
  @doc false
  def chip_count(nil, _selected), do: nil

  def chip_count(count, selected) do
    fg = if selected, do: Palette.on_ink_count(), else: Palette.count_idle()

    ~MOB"""
    <Text text={count} font_family="mono" text_size={10.5} text_color={fg} max_lines={1} />
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
      <Box
        fill_width={true}
        height={158}
        corner_radius={13}
        background={Palette.placeholder()}
        shadow={Kati.Theme.shadow_card_soft()}
      >
        {Kati.Screens.Discover.poster(p.seed)}
      </Box>
      <Spacer size={9} />
      <Text
        text={p.title}
        text_size={12.5}
        font_weight="bold"
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer size={3} />
      <Text
        text={p.match}
        font_family="mono"
        text_size={10.5}
        text_color={Palette.accent()}
        max_lines={1}
      />
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
        background={Palette.card()}
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
          <Text
            text={p.name}
            text_size={13.5}
            font_weight="semibold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={3} />
          <Text text={p.line} text_size={11.5} text_color={Palette.sub()} max_lines={1} />
        </Column>
        <Spacer size={13} />
        {Kati.Screens.Discover.person_mark(p.new?)}
      </Row>
      {Kati.Screens.Discover.hairline(rule?)}
    </Column>
    """
  end

  # Mishka's Avatar. A circular face with a fallback under it is exactly what
  # the component is, and it carries the seed-missing branch that used to be
  # written out here: `:circle` resolves to an exact `size / 2` radius, so 38pt
  # still rounds at 19.
  #
  # The pixels do not move in either state. With no image it draws the same
  # 38x38 disc in the same `#E4E0D9`, plus an empty initials Text that renders
  # nothing inside a box already sized to 38. With an image, the avatar stacks
  # `[fallback, image]` — and the design's photographs are opaque JPEGs at the
  # same 38x38 with the same radius, so the image covers the fallback exactly
  # rather than tinting it.
  @doc false
  def face(seed) do
    MishkaAvatar.avatar(src: Sample.image(seed), size: 38, background: Palette.placeholder())
  end

  @doc false
  def person_mark(true),
    do: ~MOB"<Box width={8} height={8} corner_radius={4} background={Palette.accent()} />"

  def person_mark(false), do: Kati.UI.symbol("check", size: 18, color: Palette.rail_idle())

  @doc false
  def leaving(f, scheduled) do
    ~MOB"""
    <Column fill_width={true}>
      {f.leaving |> Enum.map(fn row -> Kati.Screens.Discover.leaving_row(row, row.title in scheduled) end) |> Enum.intersperse(Kati.Screens.Discover.leaving_gap())}
    </Column>
    """
  end

  @doc false
  def leaving_gap, do: ~MOB"<Box fill_width={true} height={9} />"

  @doc false
  def leaving_row(row, done?) do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.card()}
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
          <Text
            text={row.title}
            text_size={13.5}
            font_weight="bold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={4} />
          <Text text={row.line} text_size={11.5} text_color={Palette.sub()} max_lines={1} />
        </Column>
        <Spacer size={12} />
        {Kati.Screens.Discover.leaving_action(row, done?)}
      </Row>
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
      background={Palette.ink_fill()}
      padding_left={13}
      padding_right={13}
      align="center"
      on_tap={tap}
    >
      <Text
        text={row.action}
        text_size={11.5}
        font_weight="semibold"
        text_color={Palette.on_ink()}
        max_lines={1}
      />
    </Row>
    """
  end

  def leaving_action(row, true) do
    tap = {self(), String.to_atom("schedule_" <> row.title)}

    ~MOB"""
    <Row
      height={30}
      corner_radius={15}
      background={Palette.placeholder()}
      padding_left={13}
      padding_right={13}
      align="center"
      on_tap={tap}
    >
      <Text
        text="Scheduled"
        text_size={11.5}
        font_weight="semibold"
        text_color={Palette.ink_soft()}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc false
  def thumb(seed) do
    case Sample.image(seed) do
      nil ->
        ~MOB"<Box width={40} height={56} corner_radius={8} background={Palette.placeholder()} />"

      src ->
        ~MOB"""
        <Image src={src} width={40} height={56} corner_radius={8} content_mode="fill" />
        """
    end
  end

  # Mishka's Separator, at the design's own colour and thickness. `render:
  # :box` is not optional — the default `:divider` is Material 3's antialiased
  # drawLine and softens the bottom pixel row of every rule on this screen. See
  # `Kati.Screens.Film.hairline/1` for the measurement.
  @doc false
  def hairline(false), do: ~MOB"<Spacer size={0} />"

  def hairline(true),
    do: MishkaSeparator.separator(color: Palette.hairline(), thickness: 1, render: :box)

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
