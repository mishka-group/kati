defmodule Kati.Screens.AddTitle do
  @moduledoc """
  Screen 06 — Add a title, reached from the `+` button.

  Built to `.scratch/design/screens/06.html`, drawn mid-query on "quiet": the
  field carries a 2px ink ring and an orange caret, because the design shows
  the focused state rather than the resting one, and a screen that only draws
  its resting state is untested where it matters.

  The design's note says this is one sheet that will later add a book, an
  album or an event — "the type is inferred from what you pick". So the search
  and the result row are the parts to keep general; the chips are the part
  that will grow.

  Two controls, and the drawing settles the default state of both:
  `Everything` is the chip in ink and all four results are drawn under it, so
  `filter: "Everything"` reproduces the frame exactly while `Films` and
  `Series` narrow the list *and* the `4 RESULTS` eyebrow above it. The third
  result is drawn already added — a grey check where the others carry an ink
  `+` — so `added` is per-result state that the disc toggles both ways.

  **This should eventually be a native bottom sheet**, not a pushed screen:
  #45 settled that screens 06, 18 and 46 become Android sheets via a new
  `:sheet` node type. Until that lands it pushes, which is the same
  information in a different container.
  """
  # Not `Kati.Screens.Pushed`: this screen has its own close button in the
  # header, and the pushed chrome would draw a second back affordance over the
  # title. The drawing has one dismissal, so the build has one.
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaChip
  alias Kati.Library.Sample
  alias Kati.Theme
  alias Kati.Theme.Palette
  alias Kati.UI

  # `results` is the whole answer to the query and never shrinks — the chip
  # narrows the VIEW, so a title added under `Films` is still added when the
  # user goes back to `Everything`.
  def mount(_params, _session, socket) do
    Mob.Theme.set(Kati.Theme.current())

    {:ok, Mob.Socket.assign(socket, results: Sample.search_results(), filter: "Everything")}
  end

  def render(assigns) do
    filter = assigns.filter
    shown = visible(assigns.results, filter)
    count = "#{length(shown)} results"

    ~MOB"""
    <Box fill_width={true} fill_height={true} background={:background} layout_direction={Kati.Locale.direction_prop()}>
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={40}>
        {Kati.Screens.AddTitle.header()}
        {Kati.Screens.AddTitle.field()}
        {Kati.Screens.AddTitle.chips(filter)}
        {UI.eyebrow(count)}
        {Kati.Screens.AddTitle.results(shown)}
        {Kati.Screens.AddTitle.by_hand()}
      </Column>
    </Scroll>
    </Box>
    """
  end

  def handle_info({:tap, :back}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}

  def handle_info({:tap, tag}, socket) do
    case Atom.to_string(tag) do
      "filter_" <> label ->
        {:noreply, Mob.Socket.assign(socket, :filter, label)}

      # The toggle runs over the FULL list, not the filtered one: the row the
      # user tapped is identified by its title, so which chip was on when they
      # tapped it cannot matter.
      "add_" <> title ->
        results =
          Enum.map(socket.assigns.results, fn r ->
            if r.title == title, do: %{r | added: not r.added}, else: r
          end)

        {:noreply, Mob.Socket.assign(socket, :results, results)}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  @doc """
  The results a chip leaves visible.

  Read off the result's own `meta` — `2019 · FILM · 1h 48m` — rather than a
  second `:kind` field, so the row and the chip are answering one question
  from one source. The design's note says the type is inferred from what you
  searched, and this is that inference in the one place it exists.
  """
  @spec visible([map()], String.t()) :: [map()]
  def visible(results, "Films"), do: Enum.filter(results, &String.contains?(&1.meta, "FILM"))
  def visible(results, "Series"), do: Enum.filter(results, &String.contains?(&1.meta, "SERIES"))
  def visible(results, _filter), do: results

  @doc false
  def header do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Text text="Add a title" text_size={26} font_weight="bold" letter_spacing={-0.03} text_color={:on_surface} />
        <Spacer weight={1.0} />
        {Kati.Screens.AddTitle.close_disc()}
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  # The sheet's one dismissal, as Chelekom's headless Action Icon — the same
  # component `add_button/2` already uses on this screen, now that `shadow`
  # exists to carry `shadow_button()`. Without the lift a filled disc is card
  # white on paper, and the drawing's close button reads as floating over the
  # sheet rather than printed on it.
  #
  # `shape: :circle` resolves `44 / 2` = 22.0 against the Box's stated 22, which
  # `floatProp` reads identically, and the glyph stays a CHILD so
  # `Kati.UI.symbol/2` supplies the Material Symbol at the drawn 21.
  @doc false
  def close_disc do
    MishkaActionIcon.action_icon(
      [
        size: 44,
        shape: :circle,
        variant: :filled,
        background: Palette.card(),
        shadow: Theme.shadow_button(),
        on_tap: :back
      ],
      [UI.symbol("close", size: 21)]
    )
  end

  # The focused field. `0 0 0 2px #1A1917` in the drawing is a ring, not a
  # shadow, so it is a 2px border here — a shadow at zero blur and zero offset
  # would be invisible under the card's own elevation.
  @doc false
  def field do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        height={52}
        corner_radius={26}
        background={Palette.card()}
        border_width={2}
        border_color={Palette.ink()}
        shadow={Kati.Theme.shadow_search()}
        padding_left={18}
        padding_right={18}
        align="center"
      >
        {Kati.UI.symbol("search", size: 20)}
        <Spacer size={11} />
        <Text text="quiet" text_size={14.5} font_weight="medium" text_color={:on_surface} max_lines={1} />
        <Spacer size={2} />
        <Box width={2} height={19} background={Palette.accent()} />
        <Spacer weight={1.0} />
        {Kati.UI.symbol("cancel", size: 19, color: Palette.rail_idle(), fill: true)}
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc false
  def chips(active) do
    children =
      ["Everything", "Films", "Series"]
      |> Enum.map(fn label -> Kati.Screens.AddTitle.chip(label, label == active) end)
      |> Enum.intersperse(Kati.Screens.AddTitle.chip_gap())

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true}>
        {children}
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  # Chelekom's headless Chip, which is what these are: three filter chips of
  # which exactly one is checked. Everything the drawing specifies is passed in
  # — the component's own defaults are theme tokens and would draw a different
  # chip, which is why this could not be built out of it before this round.
  #
  # Identical to screen 02's filter chips down to the number, which is the
  # design's own doing: both are `height:32 / radius:16 / padding:0 15 /
  # 12.5 semibold`, ink when on and card white when off. The two screens still
  # state it separately because they are separate drawings that happen to
  # agree, not one control shared between them.
  #
  # The node swaps a `<Row>` for a `<Box fill_width={false}>` and gains an
  # explicit `padding_top`/`padding_bottom` of 0. Neither moves a pixel:
  # `boxAlignProp("center")` is `Alignment.Center` where `rowAlignProp` was
  # `CenterVertically`, and the second axis is inert because K-17 lets the box
  # hug — it is 15 + label + 15 wide, with no slack to centre in. The zero
  # edges are what `nodeModifier`'s `pad(v) = v ?: uniform ?: 0` already
  # substituted for the Row's absent ones.
  @doc false
  def chip(label, on?) do
    # The tag carries the label, so the day the sheet grows a Books chip is a
    # change to one list and `visible/2`, not to the handler.
    MishkaChip.chip(
      label: label,
      checked: on?,
      on_toggle: String.to_atom("filter_" <> label),
      height: 32,
      padding_x: 15,
      padding_y: 0,
      corner_radius: 16,
      text_size: 12.5,
      font_weight: :semibold,
      max_lines: 1,
      color: Palette.ink_fill(),
      text_color: Palette.on_ink(),
      unchecked_color: Palette.card(),
      unchecked_text_color: Palette.ink_soft()
    )
  end

  # `gap:7px` in the drawing is the space BETWEEN chips. Carried inside the
  # chip it made every chip 7 wider than the drawn `padding:0 15px` and left
  # the row with no gap of its own.
  @doc false
  def chip_gap, do: ~MOB"<Spacer size={7} />"

  @doc false
  def results(results) do
    ~MOB"""
    <Column fill_width={true}>
      {results
       |> Enum.map(fn r -> Kati.Screens.AddTitle.result_row(r) end)
       |> Enum.intersperse(Kati.Screens.AddTitle.row_gap())}
      <Spacer size={26} />
    </Column>
    """
  end

  @doc false
  def result_row(r) do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.card()}
        corner_radius={18}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={13}
        padding_right={13}
        padding_top={11}
        padding_bottom={11}
        align="center"
      >
        {Kati.Screens.AddTitle.thumb(r)}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text text={r.title} text_size={14} font_weight="bold" letter_spacing={-0.015} text_color={:on_surface} max_lines={1} />
          <Spacer size={5} />
          <Text text={r.meta} font_family="mono" text_size={10.5} text_color={Palette.muted()} max_lines={1} />
          <Spacer size={5} />
          <Text text={r.note} text_size={11.5} text_color={Palette.sub()} max_lines={1} />
        </Column>
        <Spacer size={13} />
        {Kati.Screens.AddTitle.add_button(r.added, r.title)}
      </Row>
    </Column>
    """
  end

  @doc false
  def row_gap, do: ~MOB"<Spacer size={9} />"

  @doc false
  def thumb(r) do
    case Kati.Library.Sample.poster(r[:seed]) do
      nil -> ~MOB"<Box width={44} height={62} corner_radius={9} background={Palette.placeholder()} />"
      src -> ~MOB"""
        <Image src={src} width={44} height={62} corner_radius={9} content_mode="fill" />
        """
    end
  end

  # Added is muted, not celebratory: the design keeps ink for the action still
  # available and greys the one already taken.
  #
  # One clause rather than two, because the two states are one button and it
  # has to go both ways — an add that cannot be undone is a trap on a list of
  # near-identical search results, three of which are called "Quiet".
  #
  # Chelekom's headless Action Icon draws it: this is exactly what that
  # component is for — a compact icon-only button — and the design's 34pt disc,
  # its fill and its glyph are all passed in, which is what headless means.
  #
  # The geometry is unchanged. `shape: :circle` computes `size / 2` = 17.0,
  # which is the 17 the Box stated; `variant: :filled` is what lets the fill be
  # the design's rather than the theme's; and the glyph goes in as a CHILD, so
  # `Kati.UI.symbol/2` still supplies the Material Symbol at the drawn 19 in the
  # drawn colour instead of the component's own `:lg` text glyph. The only
  # structural difference is the `<Row>` the component wraps children in, which
  # hugs its single Text and is centred by the same Box — no measurement moves.
  @doc false
  def add_button(added?, title) do
    # Keyed on the title, not the row's position: the chips reorder nothing but
    # they do renumber, and `add_1` would mean a different film under `Films`.
    tap = {self(), String.to_atom("add_" <> title)}
    bg = if added?, do: Palette.placeholder(), else: Palette.ink_fill()
    icon = if added?, do: "check", else: "add"
    ink = if added?, do: Palette.sub(), else: Palette.on_ink()

    MishkaActionIcon.action_icon(
      [size: 34, shape: :circle, variant: :filled, background: bg, on_tap: tap],
      [UI.symbol(icon, size: 19, color: ink)]
    )
  end

  # `1.5px dashed rgba(26,25,23,.16)` in the drawing. The bridge draws only
  # solid borders, so the dash is the one thing here that is not the design;
  # the COLOUR is now the design's own 16% ink rather than the opaque
  # #D8D2C8 that stood in for it, which read a shade light on paper.
  @doc false
  def by_hand do
    ~MOB"""
    <Row
      fill_width={true}
      corner_radius={18}
      border_width={1.5}
      border_color={Palette.border()}
      padding_top={14}
      padding_bottom={14}
      align="center"
    >
      <Spacer weight={1.0} />
      {Kati.UI.symbol("edit_note", size: 18, color: Palette.sub())}
      <Spacer size={7} />
      <Text text="Can’t find it? Add it by hand" text_size={13} font_weight="semibold" text_color={Palette.ink_soft()} max_lines={1} />
      <Spacer weight={1.0} />
    </Row>
    """
  end
end
