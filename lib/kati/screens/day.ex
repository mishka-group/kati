defmodule Kati.Screens.Day do
  @moduledoc """
  Screen 09 — a heavy day, and the density rules.

  A time-gutter timeline: a mono time column on the left, one card per item
  on the right. Clashes split that right-hand side into lanes, capped at
  two, with a `+n MORE` footer when a cluster needs more.

  The lane widths are **weights, never pixels**. `Kati.Calendar.Layout`
  emits `{col, span, n_cols}` and each card carries `weight = span`, so
  Compose resolves the real widths at layout time, at the device's actual
  density (`MobBridge.kt:2195-2200`). Elixir cannot do that arithmetic —
  `Mob.Device` reports battery, thermal, network, orientation and model, and
  no screen size at all — which is why the engine is built to need only
  proportions.

  Deliberately **not** an absolutely-positioned grid. The design calls for a
  gutter timeline, so vertical placement is ordinary stacking and the
  `offset_x`/`offset_y` props stay unused. Those are not Mob API — they
  appear nowhere in `mob/lib`, `mob/guides` or `mob/priv` — and a screen
  this central should not be the first thing to depend on a prop with no
  upstream contract.
  """
  use Kati.Screens.Pushed, back: "Calendar"

  alias Kati.Calendar.Layout

  # The design's inter-card gap (design-index.md:344).
  @lane_gap 9

  @impl true
  def load(socket) do
    date = Kati.Time.today()

    Mob.Socket.assign(socket,
      date: date,
      clusters: clusters(Kati.Calendar.SampleDay.occurrences())
    )
  end

  @doc false
  def content(assigns) do
    date = assigns.date
    clusters = assigns.clusters

    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_top={64} padding_bottom={132}>
        <Column fill_width={true} padding_left={21} padding_right={21}>
          {Kati.Screens.Day.header(date, clusters)}
          {Kati.Screens.Day.chips()}
          {Kati.Screens.Day.all_day()}
        </Column>
        {Enum.map(clusters, &Kati.Screens.Day.cluster_block/1)}
        {Kati.Screens.Day.money_row()}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def header(date, _clusters) do
    heading = "#{Kati.Time.day_name(date) |> String.slice(0, 3)} #{date.day} #{Kati.Time.month_name(date.month) |> String.slice(0, 3)}"

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Spacer weight={1.0} />
        <Box
          width={44}
          height={44}
          corner_radius={22}
          background={Kati.Theme.card(:light)}
          shadow={Kati.Theme.shadow_button()}
          align="center"
        >
          {Kati.UI.symbol("density_medium", size: 21)}
        </Box>
      </Row>
      <Spacer size={16} />
      <Text text={heading} text_size={28} font_weight="bold" letter_spacing={-0.03} text_color={:on_surface} />
      <Spacer size={5} />
      <Text text={Kati.Calendar.SampleDay.summary()} font_family="mono" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def chips do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true}>
        {Kati.Calendar.SampleDay.chips()
         |> Enum.with_index()
         |> Enum.map(fn {{label, n}, i} -> Kati.Screens.Day.chip(label, n, i == 0) end)
         |> Enum.intersperse(Kati.Screens.Day.chip_gap())}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc false
  def chip_gap, do: ~MOB"<Spacer size={7} />"

  @doc false
  def chip(label, count, on?) do
    bg = if on?, do: Kati.Theme.ink(), else: Kati.Theme.card(:light)
    fg = if on?, do: 0xFFFBFAF8, else: 0xFF5C574F
    cf = if on?, do: 0x99FBFAF8, else: 0x8C5C574F

    ~MOB"""
    <Row height={30} corner_radius={15} background={bg} padding_left={13} padding_right={13} align="center">
      <Text text={label} text_size={12.5} font_weight="semibold" text_color={fg} max_lines={1} />
      <Spacer size={6} />
      <Text text={"#{count}"} font_family="mono" text_size={10.5} text_color={cf} max_lines={1} />
    </Row>
    """
  end

  # The all-day band sits above the gutter and is never laned — an all-day
  # item has no start minute to collide on.
  @doc false
  def all_day do
    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(Kati.Calendar.SampleDay.all_day(), &Kati.Screens.Day.all_day_row/1)}
      <Spacer size={14} />
    </Column>
    """
  end

  @doc false
  def all_day_row(item) do
    ~MOB"""
    <Row fill_width={true} align="top">
      <Column width={44} padding_top={12}>
        <Text text="ALL" font_family="mono" text_size={10} letter_spacing={0.06} text_color={0xFFA9A29A} />
        <Text text="DAY" font_family="mono" text_size={10} letter_spacing={0.06} text_color={0xFFA9A29A} />
      </Column>
      <Spacer size={12} />
      <Box weight={1.0}>
        <Row fill_width={true} background={0xFFFBF1DE} corner_radius={16} padding_left={13} padding_right={13} padding_top={11} padding_bottom={11} align="center">
          {Kati.Screens.Day.thumb(item)}
          <Spacer size={11} />
          <Column weight={1.0}>
            <Text text={item.title} text_size={13} font_weight="bold" text_color={:on_surface} max_lines={1} />
            <Spacer size={3} />
            <Text text={item.meta} font_family="mono" text_size={10.5} text_color={0xFFB09A72} max_lines={1} />
          </Column>
        </Row>
      </Box>
    </Row>
    """
  end

  @doc false
  def thumb(item) do
    case Kati.Library.Sample.poster(item[:seed]) do
      nil ->
        ~MOB"<Box width={26} height={37} corner_radius={5} background={0xFFEADFC6} />"

      src ->
        ~MOB"""
        <Image src={src} width={26} height={37} corner_radius={5} content_mode="fill" />
        """
    end
  end

  # Two renewals on one row rather than two rows — the design merges money
  # events on a day, because "two subscriptions renewed" is one fact.
  @doc false
  def money_row do
    m = Kati.Calendar.SampleDay.money()

    ~MOB"""
    <Column fill_width={true} padding_left={21} padding_right={21}>
      <Row fill_width={true} align="top">
        <Column width={44} padding_top={12}>
          <Text text="00:00" font_family="mono" text_size={12} text_color={0xFFA9A29A} max_lines={1} />
        </Column>
        <Spacer size={12} />
        <Box weight={1.0}>
          <Row fill_width={true} background={Kati.Theme.card(:light)} corner_radius={16} shadow={Kati.Theme.shadow_card_soft()} padding_left={13} padding_right={13} padding_top={11} padding_bottom={11} align="center">
            {Kati.UI.symbol("payments", size: 14, color: 0xFF5C574F)}
            <Spacer size={11} />
            <Text text={m.label} text_size={13} font_weight="semibold" text_color={:on_surface} weight={1.0} max_lines={1} />
            <Text text={m.total} font_family="mono" text_size={11.5} text_color={0xFF5C574F} max_lines={1} />
            <Spacer size={9} />
            {Kati.UI.symbol("expand_more", size: 17, color: 0xFFB3ACA2)}
          </Row>
        </Box>
      </Row>
    </Column>
    """
  end

  @doc false
  def summary([]), do: "Nothing scheduled"

  def summary(clusters) do
    items =
      Enum.reduce(clusters, 0, fn c, acc ->
        acc + length(c.placements) + hidden_count(c.overflow)
      end)

    clashes = Enum.count(clusters, &(&1.n_cols > 1))

    [plural(items, "item", "items"), clashes > 0 && plural(clashes, "clash", "clashes")]
    |> Enum.filter(& &1)
    |> Enum.join(" · ")
  end

  defp hidden_count(nil), do: 0
  defp hidden_count(tile), do: length(tile.event.overflow)

  defp plural(1, singular, _plural), do: "1 #{singular}"
  defp plural(n, _singular, plural), do: "#{n} #{plural}"

  # A clash is labelled, not just laid out. The design puts "2 at once" or
  # "3 at once" above the split with a `call_split` glyph, so the reason two
  # cards are side by side is stated rather than inferred from their width.
  @doc false
  def clash_label(%{n_cols: n} = cluster) when n > 1 do
    total = length(cluster.placements) + hidden_count(cluster.overflow)

    ~MOB"""
    <Row align="center" padding_left={56} padding_bottom={6}>
      {Kati.UI.symbol("call_split", size: 14, color: 0xFFE8823C)}
      <Spacer size={6} />
      <Text
        text={"#{total} at once"}
        font_family="mono"
        text_size={10.5}
        letter_spacing={0.16}
        text_color={0xFFC08A4C}
        max_lines={1}
      />
    </Row>
    """
  end

  def clash_label(_), do: ~MOB"<Spacer size={0} />"

  @doc false
  def cluster_block(cluster) do
    ~MOB"""
    <Column fill_width={true} padding_left={21} padding_right={21}>
      {Kati.Screens.Day.clash_label(cluster)}
      <Row align="top" fill_width={true}>
        {Kati.Screens.Day.gutter(cluster.label)}
        {Kati.Screens.Day.lanes(cluster)}
      </Row>
      {Kati.Screens.Day.overflow_footer(cluster)}
      <Spacer size={14} />
    </Column>
    """
  end

  @doc false
  def gutter(label) do
    # A Column, sized to its content, and neither detail is incidental.
    #
    # Fixed at 54dp the label wrapped onto two lines at 235% Dynamic Type —
    # "02:" above "19" — which is the one thing a time column must not do.
    # But a **Box** cannot express "wrap": the bridge fills width whenever
    # `width` is not a number (`MobBridge.kt:2673`), and `width={:wrap}` is
    # not a number, so the gutter swallowed the row and every card rendered
    # at zero width. Column applies only its modifier, so it sizes to
    # content. Every label is HH:MM, so the column stays straight at any
    # scale and the lanes give up exactly the width the larger text needs.
    ~MOB"""
    <Column padding_top={16} padding_right={12}>
      <Text text={label} text_size={12} text_color={:muted} font_family="mono" max_lines={1} />
    </Column>
    """
  end

  @doc """
  The lane row.

  One child per column position, each carrying `weight = span`. A gap
  `Spacer` sits between lanes and is a fixed size rather than a weight, so
  the gap stays 9dp at every width instead of growing with the lane.
  """
  def lanes(%{n_cols: 1, placements: [only]}) do
    card(only)
  end

  def lanes(cluster) do
    children =
      cluster.placements
      |> Enum.sort_by(& &1.col)
      |> Enum.map(&card/1)
      |> Enum.intersperse(gap())

    ~MOB"""
    <Row fill_width={true} align="top">
      {children}
    </Row>
    """
  end

  defp gap do
    # A local, not @lane_gap: inside ~MOB an `@name` means an assign, so the
    # module attribute would be read as `assigns.lane_gap` and fail.
    size = @lane_gap

    ~MOB"""
    <Spacer size={size} />
    """
  end

  @doc false
  def card(%{event: event, span: span}) do
    weight = span * 1.0
    title = Map.get(event, :title) || collapsed_title(event)
    meta = Map.get(event, :meta) || collapsed_meta(event)

    # A done or todo row sits on #F4F1EC with no shadow — the design sinks
    # anything already dealt with, so the live rows are the ones that lift.
    settled? = Map.get(event, :done) == true or Map.get(event, :todo) == true
    background = if settled?, do: 0xFFF4F1EC, else: Kati.Theme.card(:light)
    shadow = if settled?, do: nil, else: Kati.Theme.shadow_card_soft()

    ~MOB"""
    <Box weight={weight}>
      <Row
        fill_width={true}
        background={background}
        corner_radius={16}
        shadow={shadow}
        padding_left={13}
        padding_right={13}
        padding_top={11}
        padding_bottom={11}
        align="center"
      >
        {Kati.Screens.Day.kind_rail(event)}
        {Kati.Screens.Day.leading_state(event)}
        <Column weight={1.0}>
          <Text text={title} text_size={13} font_weight="semibold" text_color={:on_surface} max_lines={2} />
          <Spacer size={3} />
          <Text text={meta} font_family="mono" text_size={10} text_color={:muted} max_lines={1} />
        </Column>
        {Kati.Screens.Day.state_icon(event)}
      </Row>
    </Box>
    """
  end

  # The 3dp rail that says what KIND of thing this is, before the title says
  # what it is. Green for a habit, bronze for money, ink for everything else.
  @doc false
  def kind_rail(event) do
    colour =
      case Map.get(event, :kind) do
        :habit -> 0xFF4E9A73
        :money -> 0xFFB08E55
        :air_date -> 0xFFE8823C
        _ -> Kati.Theme.ink()
      end

    ~MOB"""
    <Row align="center">
      <Box width={3} height={34} corner_radius={2} background={colour} />
      <Spacer size={11} />
    </Row>
    """
  end

  # A todo's circle leads the row — it is a thing to tick, and the drawing puts
  # the affordance where the eye starts. A done check trails, because it is a
  # statement rather than an invitation.
  @doc false
  def leading_state(%{todo: true}) do
    ~MOB"""
    <Row align="center">
      {Kati.UI.symbol("radio_button_unchecked", size: 19, color: 0xFFB3ACA2)}
      <Spacer size={11} />
    </Row>
    """
  end

  def leading_state(_), do: ~MOB"<Spacer size={0} />"

  # In a Row, so it sits AFTER the text. As a sibling of the Column inside the
  # Box it stacked on top of it instead — the green check landed across the
  # middle of "Morning run".
  @doc false
  def state_icon(%{todo: true}), do: ~MOB"<Spacer size={0} />"

  def state_icon(%{done: true}) do
    ~MOB"""
    <Row align="center">
      <Spacer size={11} />
      {Kati.UI.symbol("check_circle", size: 19, color: 0xFF4E9A73, fill: true)}
    </Row>
    """
  end

  def state_icon(_), do: ~MOB"<Spacer size={0} />"

  defp collapsed_title(%{collapsed: members, kind: kind}),
    do: "#{length(members)} #{kind_plural(kind, length(members))}"

  defp collapsed_title(_), do: "Untitled"

  defp collapsed_meta(%{collapsed: members}) do
    members
    |> Enum.map(&Map.get(&1, :title, "Untitled"))
    |> Enum.take(2)
    |> Enum.join(" · ")
  end

  defp collapsed_meta(_), do: ""

  # The label a user reads, not the atom the schema stores. "3 air_date
  # events" is a database row talking to itself.
  defp kind_plural(:meal, n), do: if(n == 1, do: "meal", else: "meals")
  defp kind_plural(:air_date, n), do: if(n == 1, do: "episode", else: "episodes")
  defp kind_plural(:habit, n), do: if(n == 1, do: "habit", else: "habits")
  defp kind_plural(:money, n), do: if(n == 1, do: "renewal", else: "renewals")
  defp kind_plural(_kind, n), do: if(n == 1, do: "event", else: "events")

  @doc false
  def overflow_footer(%{overflow: nil}) do
    ~MOB"""
    <Spacer size={0} />
    """
  end

  # The 54dp indent matches the gutter at 100% text scale and drifts at
  # larger ones. The footer reads correctly either way, and pinning it
  # exactly would need a measured width Elixir does not have.
  def overflow_footer(%{overflow: tile}) do
    label = "+#{length(tile.event.overflow)} MORE"

    # A Row, not a Box with `width={:wrap}` — that prop does nothing, the
    # bridge fills width whenever `width` is not a NUMBER, and this tile was
    # rendering as a full-width cream bar instead of a small chip. Same
    # mistake as the back pill, two files apart.
    ~MOB"""
    <Row fill_width={true}>
      <Spacer size={54} />
      <Row
        background={Kati.Theme.cream(:light)}
        corner_radius={999}
        padding_left={14}
        padding_right={14}
        padding_top={7}
        padding_bottom={7}
        align="center"
      >
        <Text text={label} text_size={11} text_color={:on_surface} letter_spacing={0.1} />
      </Row>
      <Spacer weight={1.0} />
    </Row>
    """
  end

  # The engine groups these itself. An earlier version reconstructed the
  # clusters here by grouping placements on `start_min`, which gave every
  # event its own cluster: the lanes never split, the Row never got two
  # children, and the screen looked plausible while proving nothing.
  defp clusters(occurrences) do
    occurrences
    |> Layout.clusters()
    |> Enum.map(fn cluster ->
      %{
        label: label_for(cluster.start_min),
        n_cols: cluster.n_cols,
        placements: Enum.filter(cluster.placements, &(&1.role == :event)),
        overflow: cluster.overflow
      }
    end)
  end

  defp label_for(minutes) do
    :io_lib.format("~2..0B:~2..0B", [div(minutes, 60), rem(minutes, 60)]) |> to_string()
  end
end
