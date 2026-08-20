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

  ## The chips, and the state the drawing is actually in

  `Screen 6 · Personal 6 · Money 2` narrow the timeline to one kind — band,
  cards and the merged renewals row together, since a filter that leaves two
  of the three behind is only pretending.

  There is no `All` chip, unlike screen 02, and the drawing shows the first
  chip in ink above a timeline holding **every** kind — a habit, a todo, five
  meetings, two renewals, a release. So the drawn state is *the whole day with
  the first chip lit*, and that is what `filter: nil` is: the counts sum to
  the day's own 14, so no single chip can be the state that shows all 14.
  `lit/2` lights the first chip for it, and tapping the kind already showing
  widens back to it — the screen would otherwise have three states and no way
  home.
  """
  use Kati.Screens.Pushed, back: "Calendar"

  alias Kati.Calendar.Layout

  # The design's inter-card gap (design-index.md:344).
  @lane_gap 9

  # `nil` is the whole day, and it is the state the screen opens in: the
  # drawing puts `Screen` in ink above a timeline that still holds a habit, a
  # todo, two renewals and five meetings, so the lit chip there cannot mean
  # "only Screen". It means the chip the row lights while nothing is narrowed
  # — see `lit/2`.
  @impl true
  def load(socket) do
    date = Kati.Time.today()

    Mob.Socket.assign(socket,
      date: date,
      filter: nil,
      occurrences: Kati.Calendar.SampleDay.occurrences()
    )
  end

  @doc false
  def content(assigns) do
    date = assigns.date
    filter = assigns.filter

    # Clustered from the FILTERED list, not filtered after clustering: a clash
    # between a meeting and a renewal is not a clash once the renewals are
    # gone, and the lanes have to be recomputed to say so.
    clusters = clusters(visible(assigns.occurrences, filter))

    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_top={64} padding_bottom={132}>
        <Column fill_width={true} padding_left={21} padding_right={21}>
          {Kati.Screens.Day.header(date, clusters, filter)}
          {Kati.Screens.Day.chips(filter)}
          {Kati.Screens.Day.all_day(filter)}
        </Column>
        {Enum.map(clusters, &Kati.Screens.Day.cluster_block/1)}
        {Kati.Screens.Day.money_row(filter)}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def header(date, clusters, filter) do
    heading = "#{Kati.Time.day_name(date) |> String.slice(0, 3)} #{date.day} #{Kati.Time.month_name(date.month) |> String.slice(0, 3)}"
    subtitle = subtitle(clusters, filter)

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
      <Text text={subtitle} font_family="mono" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def chips(filter) do
    all = Kati.Calendar.SampleDay.chips()
    lit = lit(all, filter)

    children =
      all
      |> Enum.map(fn {label, n} -> Kati.Screens.Day.chip(label, n, label == lit) end)
      |> Enum.intersperse(Kati.Screens.Day.chip_gap())

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true}>
        {children}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc """
  Which chip the row lights.

  A narrowed timeline lights its own chip. The whole day — `nil` — lights the
  first, because that is the state the design draws: `Screen` in ink over a
  timeline that still holds every kind. Reading it off the chip list rather
  than naming `"Screen"` keeps the default a data fact, the way the old
  `i == 0` did.
  """
  @spec lit([{String.t(), non_neg_integer()}], String.t() | nil) :: String.t() | nil
  def lit(chips, nil) do
    case chips do
      [{first, _count} | _rest] -> first
      [] -> nil
    end
  end

  def lit(_chips, filter), do: filter

  @doc false
  def chip_gap, do: ~MOB"<Spacer size={7} />"

  @doc false
  def chip(label, count, on?) do
    # The tag carries the label, so one handler serves every chip and a fourth
    # kind is a change to `SampleDay.chips/0` alone.
    tap = {self(), String.to_atom("filter_" <> label)}
    bg = if on?, do: Kati.Theme.ink(), else: Kati.Theme.card(:light)
    fg = if on?, do: 0xFFFBFAF8, else: 0xFF5C574F
    cf = if on?, do: 0x99FBFAF8, else: 0x8C5C574F

    ~MOB"""
    <Row height={30} corner_radius={15} background={bg} padding_left={13} padding_right={13} align="center" on_tap={tap}>
      <Text text={label} text_size={12.5} font_weight="semibold" text_color={fg} max_lines={1} />
      <Spacer size={6} />
      <Text text={"#{count}"} font_family="mono" text_size={10.5} text_color={cf} max_lines={1} />
    </Row>
    """
  end

  # The all-day band sits above the gutter and is never laned — an all-day
  # item has no start minute to collide on. It answers to the chips all the
  # same: a cinema release is a Screen item, so narrowing to Personal or Money
  # has to take the band with it or the filter is only half honest.
  @doc false
  def all_day(filter) do
    # An empty band draws nothing at all, not an empty Column — the 14dp that
    # separates it from the first card belongs to the band, and a filter that
    # removes the band has to take that gap with it.
    case band(filter) do
      [] ->
        ~MOB"<Spacer size={0} />"

      rows ->
        ~MOB"""
        <Column fill_width={true}>
          {Enum.map(rows, &Kati.Screens.Day.all_day_row/1)}
          <Spacer size={14} />
        </Column>
        """
    end
  end

  @doc """
  The band's rows under a filter.

  Everything the band holds is a release — the design's `release ·
  wishlisted` — and a release is a Screen item, so the whole band belongs to
  one chip.
  """
  @spec band(String.t() | nil) :: [map()]
  def band(nil), do: Kati.Calendar.SampleDay.all_day()
  def band("Screen"), do: Kati.Calendar.SampleDay.all_day()
  def band(_filter), do: []

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
  def money_row(filter) do
    if money?(filter), do: money_row(), else: ~MOB"<Spacer size={0} />"
  end

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

  @doc """
  The occurrences a chip leaves on the timeline.

  The design's three chips are the day's three kinds and their counts sum to
  the day's own total — `6 + 6 + 2 = 14` — so every item belongs to exactly
  one of them and the buckets can be an exhaustive split rather than a set of
  overlapping searches.
  """
  @spec visible([map()], String.t() | nil) :: [map()]
  def visible(occurrences, nil), do: occurrences

  def visible(occurrences, filter),
    do: Enum.filter(occurrences, fn o -> Kati.Screens.Day.bucket(o) == filter end)

  @doc """
  Which chip an occurrence belongs to.

  Read off `:kind`, the same field `kind_rail/1` colours from, so the rail and
  the chip cannot disagree about what a row is. A device-mirrored event
  arrives as `:event` and lands in Personal, which is what a phone's own
  calendar holds.
  """
  @spec bucket(map()) :: String.t()
  def bucket(occurrence) do
    case Map.get(occurrence, :kind) do
      :air_date -> "Screen"
      :episode -> "Screen"
      :money -> "Money"
      _ -> "Personal"
    end
  end

  @doc "Whether the merged renewals row survives a filter."
  @spec money?(String.t() | nil) :: boolean()
  def money?(nil), do: true
  def money?("Money"), do: true
  def money?(_filter), do: false

  @doc """
  The mono line under the date.

  Unfiltered it is the day's own headline, `14 items · 2 clashes` — the
  design's number, which counts the all-day release, both merged renewals and
  the members inside the collapsed group, and so is not recoverable from the
  cluster maths alone. Narrowed to one kind it is counted from what is
  actually on screen, because a stale `14` over four rows is a worse lie than
  an approximate count.
  """
  @spec subtitle([map()], String.t() | nil) :: String.t()
  def subtitle(_clusters, nil), do: Kati.Calendar.SampleDay.summary()

  def subtitle(clusters, filter) do
    renewals = if money?(filter), do: Kati.Calendar.SampleDay.money().count, else: 0
    extra = length(band(filter)) + renewals

    items =
      Enum.reduce(clusters, extra, fn c, acc ->
        acc + Enum.sum(Enum.map(c.placements, &member_count(&1.event))) + hidden_count(c.overflow)
      end)

    clashes = Enum.count(clusters, &(&1.n_cols > 1))

    case {items, clashes} do
      {0, _} ->
        "Nothing scheduled"

      {_, 0} ->
        plural(items, "item", "items")

      _ ->
        plural(items, "item", "items") <> " · " <> plural(clashes, "clash", "clashes")
    end
  end

  # A collapsed card is one card and several items — "3 episodes" is three
  # things the day contains, not one.
  defp member_count(%{collapsed: members}), do: length(members)
  defp member_count(_event), do: 1

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
  #
  # So the tick flips in place rather than moving to the trailing edge: the
  # hollow ring becomes the same filled green `check_circle` the done habit
  # wears, which is the design's own word for "dealt with", said in the slot
  # the design chose for a todo. The row's paper does not change because the
  # design already sinks a todo onto `#F4F1EC` — it is settled either way,
  # once as a thing to do and once as a thing done.
  @doc false
  def leading_state(%{todo: true} = event) do
    tap = {self(), String.to_atom("todo_" <> to_string(event.id))}
    done? = Map.get(event, :done) == true
    icon = if done?, do: "check_circle", else: "radio_button_unchecked"
    ink = if done?, do: 0xFF4E9A73, else: 0xFFB3ACA2

    ~MOB"""
    <Row align="center" on_tap={tap}>
      {Kati.UI.symbol(icon, size: 19, color: ink, fill: done?)}
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

  # One clause for all three chips: the tag carries the label, so a fourth kind
  # is a change to `SampleDay.chips/0` and to `bucket/1`, not to this.
  #
  # Tapping the kind the timeline is already narrowed to widens it back to the
  # whole day. Without that the screen has three states and no way back to the
  # one it opened in.
  @impl true
  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "filter_" <> label ->
        filter = if socket.assigns.filter == label, do: nil, else: label
        {:noreply, Mob.Socket.assign(socket, :filter, filter)}

      # Matched as a string rather than converted back to an integer: the id is
      # `term()` in `Layout`, and a tick should not be the thing that decides
      # every occurrence must be numbered.
      "todo_" <> id ->
        occurrences =
          Enum.map(socket.assigns.occurrences, fn o ->
            if to_string(o.id) == id, do: Map.put(o, :done, Map.get(o, :done) != true), else: o
          end)

        {:noreply, Mob.Socket.assign(socket, :occurrences, occurrences)}

      _ ->
        {:noreply, socket}
    end
  end
end
