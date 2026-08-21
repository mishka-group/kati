defmodule Kati.Screens.Stats do
  @moduledoc """
  Screen 07 — Your year.

  Built to `.scratch/design/screens/07.html`: a cream hero carrying the year's
  headline figure, a change pill, and 26 weeks of contribution squares; three
  count cards; then the breakdown bars.

  The contribution grid is a `flex-wrap` of 8px squares in the drawing, and
  Mob has no wrap primitive — so it is chunked into rows of 26, one column per
  week, which is exactly the "26 weeks" the design labels it with.
  """
  use Kati.Screens.Root, root: :stats

  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaSeparator
  alias Kati.Components.MishkaThemeIcon
  alias Kati.Stats.Sample
  alias Kati.Theme.Palette
  alias Kati.UI

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :year, Sample.year())

  @doc false
  def content(assigns) do
    year = assigns.year

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={132}
      >
        {Kati.Screens.Stats.header(year)}
        {Kati.Screens.Stats.hero(year)}
        {Kati.Screens.Stats.counts(year)}
        {UI.eyebrow("Where the hours went")}
        {Kati.Screens.Stats.breakdown(year)}
        <Spacer size={26} />
        {UI.eyebrow("More numbers")}
        {Kati.Screens.Stats.more_numbers()}
        <Spacer size={26} />
        {UI.eyebrow("Recently watched", dash: Palette.rail_idle(), gap: 12)}
        {Kati.Screens.Stats.recently_watched()}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def header(year) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Column weight={1.0}>
          <Text
            text="Your year"
            text_size={28}
            font_weight="bold"
            letter_spacing={-0.03}
            text_color={:on_surface}
          />
          <Spacer size={5} />
          <Text
            text={year.range}
            font_family="mono"
            text_size={11}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
        {Kati.Screens.Stats.share_disc()}
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  # Chelekom's headless Action Icon. `shadow` is what made it usable for this:
  # `variant: :filled` alone paints card white on paper, two values that barely
  # separate, and the drawing's disc is legible only because it floats above
  # them on `shadow_button()`.
  #
  # It carries no handler, and passing none is the right way to say so — the
  # component omits the `on_tap` key entirely rather than sending a null, so
  # `RenderNodeInner` attaches no `clickable` and the disc stays exactly as
  # inert as the Box it replaces. Sharing a year is not built yet, and a disc
  # that swallowed a tap silently would be worse than one that plainly does
  # nothing.
  @doc false
  def share_disc do
    MishkaActionIcon.action_icon(
      [
        size: 44,
        shape: :circle,
        variant: :filled,
        background: Palette.card(),
        shadow: Kati.Theme.shadow_button()
      ],
      [Kati.UI.symbol("ios_share", size: 21)]
    )
  end

  @doc false
  def hero(year) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.cream()}
        corner_radius={24}
        shadow={Kati.Theme.shadow_hero()}
        padding={19}
      >
        <Row fill_width={true} align="bottom">
          <Column weight={1.0}>
            <Text
              text={String.upcase("Time watched")}
              font_family="mono"
              text_size={10.5}
              letter_spacing={0.16}
              text_color={Palette.cream_meta()}
            />
            <Spacer size={7} />
            <Text
              text={year.time}
              text_size={34}
              font_weight="extrabold"
              letter_spacing={-0.04}
              text_color={:on_surface}
            />
          </Column>
          <Column padding_bottom={5}>
            <Row
              height={28}
              corner_radius={14}
              background={Palette.green_wash()}
              padding_left={11}
              padding_right={11}
              align="center"
            >
              {Kati.UI.symbol("arrow_drop_up", size: 14, color: Palette.green_text(), fill: true)}
              <Spacer size={5} />
              <Text
                text={year.change}
                font_family="mono"
                text_size={11.5}
                font_weight="medium"
                text_color={Palette.green_text()}
              />
            </Row>
          </Column>
        </Row>
        <Spacer size={18} />
        {Kati.Screens.Stats.grid()}
        <Spacer size={12} />
        <Row fill_width={true}>
          <Text
            text={"#{year.weeks} weeks"}
            font_family="mono"
            text_size={10}
            text_color={Palette.cream_meta()}
          />
          <Spacer weight={1.0} />
          <Text
            text={year.streak}
            font_family="mono"
            text_size={10}
            text_color={Palette.cream_meta()}
            max_lines={1}
          />
        </Row>
      </Column>
      <Spacer size={14} />
    </Column>
    """
  end

  # 26 columns per row, one per week. 26*8 + 25*4 = 308, inside the 360 the
  # gutters leave, which is why the design's wrap lands on 26 as well.
  @doc false
  def grid do
    rows = Sample.contributions() |> Enum.chunk_every(26)

    ~MOB"""
    <Column fill_width={true}>
      {rows
       |> Enum.map(fn row -> Kati.Screens.Stats.grid_row(row) end)
       |> Enum.intersperse(Kati.Screens.Stats.cell_gap())}
    </Column>
    """
  end

  @doc false
  def grid_row(row) do
    ~MOB"""
    <Row>
      {row |> Enum.map(&Kati.Screens.Stats.cell/1) |> Enum.intersperse(Kati.Screens.Stats.cell_gap())}
    </Row>
    """
  end

  @doc false
  def cell_gap, do: ~MOB"<Spacer size={4} />"

  @doc false
  def cell(level) do
    color = Sample.intensity(level)

    ~MOB"""
    <Box width={8} height={8} corner_radius={2} background={color} />
    """
  end

  @doc false
  def counts(year) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {year.counts |> Enum.map(fn {n, l} -> Kati.Screens.Stats.count_card(n, l) end) |> Enum.intersperse(Kati.Screens.Stats.count_gap())}
      </Row>
      <Spacer size={26} />
    </Column>
    """
  end

  @doc false
  def count_gap, do: ~MOB"<Spacer size={12} />"

  @doc false
  def count_card(number, label) do
    ~MOB"""
    <Box weight={1.0}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card()}
        padding={15}
      >
        <Text
          text={number}
          text_size={26}
          font_weight="extrabold"
          letter_spacing={-0.035}
          text_color={:on_surface}
        />
        <Spacer size={5} />
        <Text
          text={String.upcase(label)}
          font_family="mono"
          text_size={10.5}
          letter_spacing={0.1}
          text_color={Palette.muted()}
          max_lines={1}
        />
      </Column>
    </Box>
    """
  end

  @doc false
  def breakdown(year) do
    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card()}
      padding={17}
    >
      {Enum.map(year.breakdown, fn row -> Kati.Screens.Stats.bar(row) end)}
    </Column>
    """
  end

  @doc false
  def bar({name, fraction, value, color}) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Column width={88}>
          <Text
            text={name}
            text_size={12.5}
            font_weight="semibold"
            text_color={:on_surface}
            max_lines={1}
          />
        </Column>
        <Spacer size={12} />
        <Box weight={1.0}>
          <Box fill_width={true} height={8} corner_radius={4} background={Palette.paper()}>
            <Row fill_width={true}>
              <Box weight={fraction} height={8} corner_radius={4} background={color} />
              <Spacer weight={1.0 - fraction} />
            </Row>
          </Box>
        </Box>
        <Spacer size={12} />
        <Column width={34}>
          <Text
            text={value}
            font_family="mono"
            text_size={11}
            text_color={Palette.muted()}
            text_align="right"
            max_lines={1}
          />
        </Column>
      </Row>
      <Spacer size={13} />
    </Column>
    """
  end

  @doc false
  def more_numbers do
    rows = Enum.reject(Kati.Stats.Sample.more_numbers(), &(&1.title == "Recently watched"))
    last = length(rows) - 1

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card()}
      padding_left={15}
      padding_right={15}
      padding_top={4}
      padding_bottom={4}
    >
      {rows |> Enum.with_index() |> Enum.map(fn {row, i} -> Kati.Screens.Stats.number_row(row, i < last) end)}
    </Column>
    """
  end

  @doc false
  def number_row(row, rule?) do
    tap = {self(), String.to_atom("go_" <> row.title)}

    ~MOB"""
    <Column fill_width={true} on_tap={tap}>
      <Row fill_width={true} align="center" padding_top={13} padding_bottom={13}>
        {Kati.Screens.Stats.row_tile(row.icon)}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text
            text={row.title}
            text_size={13.5}
            font_weight="semibold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={3} />
          <Text text={row.sub} text_size={11.5} text_color={Palette.sub()} max_lines={1} />
        </Column>
        <Spacer size={12} />
        {Kati.UI.symbol("chevron_right", size: 18, color: Palette.rail_idle())}
      </Row>
      {Kati.Screens.Stats.hairline(rule?)}
    </Column>
    """
  end

  # Chelekom's headless Theme Icon — "a themed container around exactly one
  # icon", which is exactly this tile. Not Action Icon: that one is a button,
  # and the tap here belongs to the whole row (`number_row/2` wires `on_tap` on
  # the Column), so a tile claiming its own would be describing an affordance
  # the drawing does not have.
  #
  # Theme Icon also builds the tighter node of the two. With no `id`,
  # `markers(nil, …)` returns caller-supplied children untouched, so the tree is
  # a Box holding the glyph — the hand-rolled node with nothing added. Action
  # Icon would have interposed a `<Row>`.
  #
  # `variant: :filled` makes `color` the fill; the glyph ink the variant derives
  # from it is unused, because a child carries its own and `Kati.UI.symbol/2`
  # supplies the drawn #5C574F at 17.
  @doc false
  def row_tile(icon) do
    MishkaThemeIcon.theme_icon(
      [variant: :filled, color: Palette.paper(), size: 30, radius: 9],
      [Kati.UI.symbol(icon, size: 17, color: Palette.ink_soft())]
    )
  end

  # Chelekom's headless Separator, given the design's own 7%-ink rule colour.
  #
  # `render: :box` is load-bearing, and the comment that used to sit here was
  # wrong about why. The default `:divider` is NOT the hand-rolled Box this
  # replaced: the bridge maps it to Material3's `HorizontalDivider`, which is a
  # Canvas drawing an ANTIALIASED `drawLine`, not a filled rect. At this
  # device's 2.6875x a 1dp rule gets a 3px canvas and a 2.6875px stroke, so the
  # last pixel row lands at ~69% coverage — a hairline 4-5/255 lighter than the
  # design's on one full-width row. `render: :box` swaps the primitive back to
  # `<Box fill_width height={1} background={color}>`, which is the node this
  # screen drew by hand, so every pixel row carries the full colour again.
  @doc false
  def hairline(false), do: ~MOB"<Spacer size={0} />"

  def hairline(true),
    do: MishkaSeparator.separator(color: Palette.hairline(), thickness: 1, render: :box)

  @doc """
  The last section of the drawing, which the screen was not drawing at all.

  Three cards under a `Recently watched` kicker, each a 38x54 poster, a title,
  a mono line and the rating in accent stars. The drawing templates the copy;
  these are the library's own titles and their photographs, so the section is
  the drawn shape filled with the data this build actually has.
  """
  @spec recent() :: [map()]
  def recent do
    [
      %{seed: "hollow71", title: "The Long Hollow", meta: "S2 E5 · 2h ago", stars: 5},
      %{seed: "bluehour58", title: "Blue Hour", meta: "FILM · yesterday", stars: 4},
      %{seed: "marram15", title: "Marram", meta: "S1 E8 · 3 days ago", stars: 4}
    ]
  end

  @doc false
  def recently_watched do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.Stats.recent()
       |> Enum.map(fn row -> Kati.Screens.Stats.recent_row(row) end)
       |> Enum.intersperse(Kati.Screens.Stats.recent_gap())}
    </Column>
    """
  end

  @doc false
  def recent_gap, do: ~MOB"<Spacer size={9} />"

  @doc false
  def recent_row(row) do
    ~MOB"""
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
      {Kati.Screens.Stats.recent_thumb(row)}
      <Spacer size={13} />
      <Column weight={1.0}>
        <Text
          text={row.title}
          text_size={13.5}
          font_weight="bold"
          letter_spacing={-0.015}
          text_color={:on_surface}
          max_lines={1}
        />
        <Spacer size={4} />
        <Text
          text={row.meta}
          font_family="mono"
          text_size={10.5}
          text_color={Palette.muted()}
          max_lines={1}
        />
      </Column>
      <Spacer size={13} />
      {Kati.Screens.Stats.stars(row.stars)}
    </Row>
    """
  end

  @doc false
  def recent_thumb(row) do
    case Kati.Design.Images.poster(row.seed) do
      nil ->
        ~MOB"<Box width={38} height={54} corner_radius={8} background={Palette.placeholder()} />"

      src ->
        ~MOB"""
        <Image src={src} width={38} height={54} corner_radius={8} content_mode="fill" />
        """
    end
  end

  # The drawing writes the rating as a run of star characters. Plus Jakarta
  # Sans has no U+2605, so a literal one renders as nothing at all — these are
  # the Material Symbols glyph, at the drawn 12 and the drawn accent, spaced by
  # the .08em the design tracks the run with.
  @doc false
  def stars(n) do
    ~MOB"""
    <Row align="center">
      {1..n
       |> Enum.map(fn _ -> Kati.UI.symbol("star", size: 12, color: Palette.accent(), fill: true) end)
       |> Enum.intersperse(Kati.Screens.Stats.star_gap())}
    </Row>
    """
  end

  @doc false
  def star_gap, do: ~MOB"<Spacer size={1} />"

  # The More numbers rows are the only route to these screens outside the
  # gallery, which is scaffolding.
  @destinations %{
    "Activity log" => Kati.Screens.Activity,
    "Habits" => Kati.Screens.Habits,
    "Nutrition" => Kati.Screens.Health,
    "Subscriptions" => Kati.Screens.Subscriptions,
    "Recently watched" => Kati.Screens.UpNext
  }

  @impl true
  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "go_" <> title ->
        case Map.fetch(@destinations, title) do
          {:ok, module} -> {:noreply, Mob.Socket.push_screen(socket, module)}
          :error -> {:noreply, socket}
        end

      _ ->
        {:noreply, socket}
    end
  end
end
