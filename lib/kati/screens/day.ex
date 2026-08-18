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
      clusters: date |> Kati.Calendars.Today.occurrences() |> clusters()
    )
  end

  @doc false
  def content(assigns) do
    date = assigns.date
    heading = "#{Kati.Time.day_name(date)} #{date.day}"
    clusters = assigns.clusters

    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_top={112} padding_bottom={40}>
        <Column padding_left={21} padding_right={21} fill_width={true}>
          <Text
            text={String.upcase("#{Kati.Time.month_name(date.month)} #{date.year}")}
            text_size={11}
            text_color={:muted}
            letter_spacing={0.14}
          />
          <Spacer size={5} />
          <Text
            text={heading}
            text_size={34}
            text_color={:on_surface}
            font_weight="bold"
            letter_spacing={-1.0}
          />
          <Spacer size={4} />
          <Text text={Kati.Screens.Day.summary(clusters)} text_size={13} text_color={:muted} />
        </Column>
        <Spacer size={22} />
        {Enum.map(clusters, &Kati.Screens.Day.cluster_block/1)}
      </Column>
    </Scroll>
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

  @doc false
  def cluster_block(cluster) do
    ~MOB"""
    <Column fill_width={true} padding_left={21} padding_right={21}>
      <Row vertical_align="top" fill_width={true}>
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
      <Text text={label} text_size={12} text_color={:muted} font_family="monospace" max_lines={1} />
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
    <Row fill_width={true} vertical_align="top">
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

    ~MOB"""
    <Box weight={weight}>
      <Box background={:surface} corner_radius={20} padding={16} fill_width={true}>
        <Column fill_width={true}>
          <Text text={title} text_size={15} text_color={:on_surface} max_lines={2} />
          <Spacer size={3} />
          <Text text={meta} text_size={12} text_color={:muted} max_lines={1} />
        </Column>
      </Box>
    </Box>
    """
  end

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

  defp kind_plural(:meal, n) when n != 1, do: "meals"
  defp kind_plural(kind, n) when n != 1, do: "#{kind} events"
  defp kind_plural(kind, _), do: to_string(kind)

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

    ~MOB"""
    <Row fill_width={true}>
      <Spacer size={54} />
      <Box
        background={Kati.Theme.cream(:light)}
        corner_radius={999}
        padding_left={14}
        padding_right={14}
        padding_top={7}
        padding_bottom={7}
        width={:wrap}
      >
        <Text text={label} text_size={11} text_color={:on_surface} letter_spacing={0.1} />
      </Box>
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
