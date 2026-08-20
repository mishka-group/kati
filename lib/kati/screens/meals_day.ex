defmodule Kati.Screens.MealsDay do
  @moduledoc """
  Screen 52 — meals on the calendar.

  Built to `.scratch/design/screens/52.html`. A day where five of the eleven
  items are meals, drawn to prove that meals need no special lane: they take a
  bronze rule, sit in clock order with everything else, and then collapse into
  a single row under the same 3+ density rule that collapses six episodes on
  screen 09.

  Pushed under Calendar — the drawing's back pill says `‹ Calendar` — so the
  frame's bottom padding is **40, not 132**. There is no dock here, and 132
  would leave a hand's width of dead paper under the last row.

  ## Where this diverges from the drawing

    * The lane rule is `align-self: stretch` in the design and a declared 34pt
      here. Nothing measures geometry on this bridge, and every row carries the
      same two lines of text, so a fixed rule is exact rather than approximate
      — but it would need revisiting if a title ever wrapped.
    * An unlogged meal's ring is drawn empty. The design puts a `check` glyph
      inside it at `rgba(26,25,23,0)` — fully transparent — which is a way of
      reserving space in CSS, not a mark anyone sees.

  ## The two controls

  Both start in the state the drawing is in, so the resting screen is the
  drawing:

    * The **chips** filter the spine. `All` is selected, so every row shows —
      which is what the drawing draws. The section chips read a row's *lane
      colour*, because that is where this screen already stores what a row is:
      bronze is a meal, orange is Screen, and everything else (the habit's
      green, the appointment's ink) is Personal. Deriving the chip from the
      rule keeps the filter and the stripe from ever disagreeing.
    * The **density disc** — and the collapsed row's own chevron, which is the
      same control drawn twice — folds the five meals out of the spine and
      into the summary the `Collapse meals` eyebrow already labels. That is
      the screen's whole argument made operable: the drawing shows both states
      at once so the reader can compare them, and the disc lets you actually
      switch between them.
  """
  use Kati.Screens.Pushed, back: "Calendar"

  alias Kati.Calendar.SampleMealDay
  alias Kati.Theme
  alias Kati.UI

  # The lane colours `Kati.Calendar.SampleMealDay` paints, read back as kinds.
  @meal 0xFFB08E55
  @screen 0xFFE8823C

  @impl true
  def load(socket) do
    Mob.Socket.assign(socket,
      day: SampleMealDay.day(),
      filter: "All",
      density: :comfortable
    )
  end

  @doc false
  def content(assigns) do
    day = assigns.day
    filter = assigns.filter
    density = assigns.density
    rows = Kati.Screens.MealsDay.visible(day.rows, filter, density)

    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={40}>
        {Kati.Screens.MealsDay.header(density)}
        {Kati.Screens.MealsDay.title(day)}
        {Kati.Screens.MealsDay.chips(day, filter)}
        {Kati.Screens.MealsDay.timeline(rows)}
        {Kati.Screens.MealsDay.muted_eyebrow("Collapse meals")}
        {Kati.Screens.MealsDay.collapsed(day)}
        {Kati.Screens.MealsDay.note(day)}
      </Column>
    </Scroll>
    """
  end

  # The back pill is drawn by Kati.Screens.Pushed over this content; this row
  # reserves its height and carries the density control opposite it.
  #
  # The glyph stays `density_medium` in both states — it is the drawing's, and
  # the disc says which state it is in by filling with ink, the same way every
  # selected chip on this screen does.
  @doc false
  def header(density) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Spacer weight={1.0} />
        {Kati.Screens.MealsDay.density_disc(density)}
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  The 44pt density control.

  `Kati.Components.MishkaActionIcon` — "a compact icon-only button" — which is
  exactly what this is: a square tap target holding one glyph, and the only
  control on the screen's chrome row. It became buildable this round, because
  the component now takes a `shadow`, and **a floating disc is defined by its
  shadow**: 52.html gives this one
  `0 1px 2px rgba(26,25,23,.05), 0 8px 16px -12px rgba(26,25,23,.5)`, which is
  `Kati.Theme.shadow_button/0`. Without it the disc is a flat patch of card
  white on paper rather than a button lifted off it.

  ## Why the pixels do not move

  `shape: :circle` resolves its radius as `size / 2` — 22.0, the number this
  wrote by hand, and `corner_radius` is read through `floatProp`, so 22.0 and
  22 are the same `22.dp`. With `variant: :filled` the fill is the caller's
  `background` rather than `:transparent`, and `shadow` and `on_tap` are
  merged onto the container only because they were passed — an omitted one is
  absent from the map rather than a JSON `null`. So the container is
  `%{width: 44, height: 44, align: :center, corner_radius: 22.0,
  background: background, shadow: …, on_tap: …}` — key for key the `Box` this
  used to write out.

  The one structural difference is that content passed as children is wrapped
  in a `<Row>`. That `Row` is layout-neutral here: it holds a single `Text`,
  so it measures exactly the glyph, and the container's `align: :center` then
  centres the `Row` where it used to centre the glyph.

  Both states are one call rather than two clauses, because the disc's shape,
  size and shadow never change — only which of the two colours is the fill and
  which the glyph, which is the drawing's own inversion.
  """
  def density_disc(density) do
    on? = density == :dense
    background = if on?, do: Theme.ink(), else: Theme.card(:light)
    color = if on?, do: 0xFFFBFAF8, else: Theme.ink()

    Kati.Components.MishkaActionIcon.action_icon(
      %{
        variant: :filled,
        shape: :circle,
        size: 44,
        background: background,
        shadow: Theme.shadow_button(),
        on_tap: {self(), :density}
      },
      [UI.symbol("density_medium", size: 21, color: color)]
    )
  end

  @doc false
  def title(day) do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={day.title}
        text_size={28}
        font_weight="bold"
        letter_spacing={-0.03}
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer size={5} />
      <Text text={day.subtitle} font_family="mono" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def chips(day, active) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {day.chips
         |> Enum.map(fn {label, count} -> Kati.Screens.MealsDay.chip(label, count, label == active) end)
         |> Enum.intersperse(Kati.Screens.MealsDay.chip_gap())}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc false
  def chip_gap, do: ~MOB"<Spacer size={7} />"

  @doc false
  def chip(label, count, on?) do
    # The tag carries the label, so one clause serves every chip and a new
    # section in the data needs no new code here.
    tap = {self(), String.to_atom("filter_" <> label)}
    background = if on?, do: Theme.ink(), else: Theme.card(:light)
    color = if on?, do: 0xFFFBFAF8, else: 0xFF5C574F
    shadow = if on?, do: nil, else: Theme.shadow_card_soft()

    ~MOB"""
    <Row
      height={30}
      corner_radius={15}
      background={background}
      shadow={shadow}
      padding_left={13}
      padding_right={13}
      align="center"
      on_tap={tap}
    >
      <Text text={label} text_size={12} font_weight="semibold" text_color={color} max_lines={1} />
      {Kati.Screens.MealsDay.chip_count(count)}
    </Row>
    """
  end

  # The count is the label at 60% — `opacity:.6` on the same colour, which as
  # ARGB is the alpha, not a lighter grey.
  @doc false
  def chip_count(nil), do: ~MOB"<Spacer size={0} />"

  def chip_count(count) do
    ~MOB"""
    <Row align="center">
      <Spacer size={6} />
      <Text text={count} font_family="mono" text_size={10} text_color={0x995C574F} max_lines={1} />
    </Row>
    """
  end

  @doc false
  def timeline(rows) do
    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(rows, fn row -> Kati.Screens.MealsDay.row(row) end)}
      <Spacer size={14} />
    </Column>
    """
  end

  @doc """
  Which section a spine row belongs to, read off its lane colour.

  The stripe is already the row's kind made visible — bronze for a meal,
  orange for Screen — so reading the chip back out of it means the filter and
  the stripe cannot drift apart. A habit's green and an appointment's ink both
  fall to `Personal`, which is the same bucket `Kati.Screens.Calendar.visible/2`
  puts them in.
  """
  @spec kind(map()) :: String.t()
  def kind(%{rule: @meal}), do: "Meals"
  def kind(%{rule: @screen}), do: "Screen"
  def kind(_row), do: "Personal"

  @doc """
  The spine rows a chip and the density control leave standing.

  `All` at comfortable density is every row, which is the drawing. Dense drops
  the meals, because the collapsed row beneath is already carrying them — that
  is what `Collapse meals` means, and with `Meals` also selected the spine
  empties entirely, which is honest: the five meals are all in the one row
  below.
  """
  @spec visible([map()], String.t(), atom()) :: [map()]
  def visible(rows, filter, density) do
    rows
    |> Enum.filter(fn row -> filter == "All" or Kati.Screens.MealsDay.kind(row) == filter end)
    |> Enum.reject(fn row -> density == :dense and Kati.Screens.MealsDay.kind(row) == "Meals" end)
  end

  @doc false
  def row(row) do
    background = if row.state == :past, do: 0xFFF4F1EC, else: Theme.card(:light)
    shadow = if row.state == :past, do: nil, else: Theme.shadow_card_soft()
    color = if row.state == :past, do: 0xFF9C958B, else: 0xFF1A1917

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column width={44} padding_top={13}>
          <Text text={row.time} font_family="mono" text_size={12} text_color={0xFFA9A29A} max_lines={1} />
        </Column>
        <Spacer size={12} />
        <Box weight={1.0}>
          <Row
            fill_width={true}
            background={background}
            corner_radius={17}
            shadow={shadow}
            padding_left={13}
            padding_right={13}
            padding_top={12}
            padding_bottom={12}
            align="center"
          >
            <Box width={3} height={34} corner_radius={2} background={row.rule} />
            <Spacer size={11} />
            <Column weight={1.0}>
              <Text text={row.title} text_size={13} font_weight="semibold" text_color={color} max_lines={1} />
              <Spacer size={4} />
              <Text text={row.sub} font_family="mono" text_size={10.5} text_color={0xFFB3ACA2} max_lines={1} />
            </Column>
            {Kati.Screens.MealsDay.check(row.check)}
          </Row>
        </Box>
      </Row>
      <Spacer size={8} />
    </Column>
    """
  end

  # In a Row, after the text. As a sibling inside the Box it would stack over
  # the title instead of sitting beside it.
  @doc false
  def check(:none), do: ~MOB"<Spacer size={0} />"

  def check(:eaten) do
    ~MOB"""
    <Row align="center">
      <Spacer size={11} />
      {Kati.Screens.MealsDay.ring(:eaten)}
    </Row>
    """
  end

  def check(:todo) do
    ~MOB"""
    <Row align="center">
      <Spacer size={11} />
      {Kati.Screens.MealsDay.ring(:todo)}
    </Row>
    """
  end

  @doc """
  The 24pt disc that says whether a meal has been logged.

  Both states are `Kati.Components.MishkaThemeIcon` — "a themed container
  around exactly one icon", and a 24pt disc holding a `check` is nothing else.
  Neither could be built before this round: 52.html draws **both** rings with
  a 1.5pt border, and `theme_icon/2` used to paint a border only under
  `variant: :outline`, which forfeits the fill and hard-codes the width at 1.
  `border_color` and `border_width` are now caller overrides on any variant,
  so the fill and the hairline can be asked for together and the hairline can
  be 1.5.

  ## Why the pixels do not move

  Neither call passes an `id`, an `icon` or an `on_tap`, so the id markers,
  the glyph shorthand and the handler are all skipped, and `:filled` and
  `:subtle` both contribute an empty gradient layer.

  `:eaten` is `variant: :filled` with `color` and `border_color` set to the
  same `#4E9A73` the drawing gives it (`border:1.5px solid #4E9A73;
  background:#4E9A73`), so the container is `%{width: 24, height: 24,
  align: :center, corner_radius: 12, background: 0xFF4E9A73,
  border_color: 0xFF4E9A73, border_width: 1.5}` — key for key the `Box` this
  wrote by hand — holding the same 14pt `check`.

  `:todo` is `variant: :subtle`, whose skin is no background and no border, so
  the only fill-related keys on the node are the two overrides:
  `%{width: 24, height: 24, align: :center, corner_radius: 12,
  border_color: 0x291A1917, border_width: 1.5}`. `put_some/3` drops a nil
  background rather than writing one, which matters — the drawing says
  `background:transparent`, and a `nil` would serialise as a JSON null for the
  bridge to read. The `align: :center` the component adds is the one key the
  hand-rolled node lacked, and it is a no-op on a box with no children: the
  drawing puts a fully transparent `check` in this ring, which is a way of
  reserving space in CSS rather than a mark anyone sees, so nothing is centred
  here.
  """
  def ring(:eaten) do
    Kati.Components.MishkaThemeIcon.theme_icon(
      %{
        variant: :filled,
        color: 0xFF4E9A73,
        size: 24,
        radius: 12,
        border_color: 0xFF4E9A73,
        border_width: 1.5
      },
      [Kati.UI.symbol("check", size: 14, color: 0xFFFBFAF8)]
    )
  end

  def ring(:todo) do
    Kati.Components.MishkaThemeIcon.theme_icon(%{
      variant: :subtle,
      size: 24,
      radius: 12,
      border_color: 0x291A1917,
      border_width: 1.5
    })
  end

  # Kati.UI.eyebrow's dash is always the accent, and orange here would claim
  # the collapsed meals are new. The design draws this one #C4BDB3.
  @doc false
  def muted_eyebrow(label) do
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

  # The `expand_more` chevron is the density control's other face, so it sends
  # the same tag. The glyph does not flip with the state: the drawing draws it
  # pointing down, and the drawing is the resting screen.
  @doc false
  def collapsed(day) do
    collapsed = day.collapsed
    tap = {self(), :density}

    ~MOB"""
    <Row
      fill_width={true}
      background={Theme.card(:light)}
      corner_radius={18}
      shadow={Theme.shadow_card_soft()}
      padding_left={14}
      padding_right={14}
      padding_top={13}
      padding_bottom={13}
      align="center"
      on_tap={tap}
    >
      <Box width={3} height={36} corner_radius={2} background={collapsed.rule} />
      <Spacer size={12} />
      <Column weight={1.0}>
        <Text text={collapsed.title} text_size={13} font_weight="bold" text_color={:on_surface} max_lines={1} />
        <Spacer size={4} />
        <Text text={collapsed.sub} font_family="mono" text_size={10.5} text_color={0xFFA9A29A} max_lines={1} />
      </Column>
      <Spacer size={12} />
      {UI.symbol("expand_more", size: 19, color: 0xFF5C574F)}
    </Row>
    """
  end

  @doc false
  def note(day) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={13} />
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        {UI.symbol("info", size: 15, color: 0xFFB3ACA2)}
        <Spacer size={8} />
        <Text text={day.note} text_size={11.5} line_height={1.45} text_color={0xFF8A8479} weight={1.0} />
      </Row>
    </Column>
    """
  end

  @impl true
  def handle_tap(:density, socket) do
    next = if socket.assigns.density == :dense, do: :comfortable, else: :dense
    {:noreply, Mob.Socket.assign(socket, :density, next)}
  end

  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "filter_" <> label -> {:noreply, Mob.Socket.assign(socket, :filter, label)}
      _ -> {:noreply, socket}
    end
  end
end
