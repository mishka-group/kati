defmodule Kati.Screens.Health do
  @moduledoc """
  Screen 42 — Health, pushed under Home.

  Built to `.scratch/design/screens/42.html`. The drawing says what it is in a
  dashed box at the bottom of itself: *"Health is a container, not a feature.
  Each tile is an independent section with its own shelf, calendar feed and
  home card."* Meals is not a top-level thing; it sits inside Health, which is
  itself a section that happens to hold others.

  That is why the grid draws two live tiles and four dashed ones side by side
  instead of hiding what is not built. Screen 03 makes the same move with Books
  and Music, and for the same reason: a grid with the unbuilt tiles removed
  would misrepresent the app's shape, while a dashed outline states the intent.

  Where this diverges from the export, and why:

    * **Dashed borders are drawn solid.** `border:1.5px dashed rgba(26,25,23,.14)`
      has no dashed equivalent on this bridge, so it is a 1.5pt solid edge at
      the same colour — the treatment `Kati.Screens.AddTitle` already uses for
      its by-hand row. The tile still reads as an outline against a filled one;
      it does not read as *provisional*, and that is a real loss.
    * **`1,480 / 2,100 kcal` is two runs on one baseline.** 34pt extrabold and
      16pt semibold in the drawing's single heading, so a `Row` aligned
      `bottom` rather than one `Text`.

  The tiles split the row by weight rather than by the drawing's literal 174.
  `calc(50% - 6px)` of the 360 the gutters leave *is* 174, but this bridge
  applies padding before width, so a `width={174}` tile carrying `padding={16}`
  measures 206 and the two columns stop matching. Weight is measured after the
  gap, which is the same arithmetic without the trap. Mob has no wrap
  primitive, so the two-across grid is still chunked by a declared count, the
  same as screen 03's posters.

  No dock on a pushed screen, so the frame ends at 40 rather than 132.
  """
  use Kati.Screens.Pushed, back: "Home"

  alias Kati.Components.MishkaPill
  alias Kati.Components.MishkaThemeIcon
  alias Kati.Health.Sample
  alias Kati.Theme.Palette
  alias Kati.UI

  @doc false
  def content(_assigns) do
    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {Kati.Screens.Health.back_gap()}
        {Kati.Screens.Health.header()}
        {Kati.Screens.Health.eaten()}
        {Kati.Screens.Health.next_meal()}
        {UI.eyebrow("Sections")}
        {Kati.Screens.Health.sections()}
        {Kati.Screens.Health.container_note()}
      </Column>
    </Scroll>
    """
  end

  # `Kati.Screens.Pushed` floats the back pill over the content, so the content
  # leaves room for it: a 42pt pill and the drawing's 16pt gap under it.
  @doc false
  def back_gap, do: ~MOB"<Spacer size={58} />"

  @doc false
  def header do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column weight={1.0}>
          <Text
            text="Health"
            text_size={28}
            font_weight="bold"
            letter_spacing={-0.03}
            text_color={:on_surface}
          />
          <Spacer size={5} />
          <Text
            text={Kati.Health.Sample.day_line()}
            font_family="mono"
            text_size={11}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
        {Kati.Screens.Health.disc("tune", :open_filters)}
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  The 44pt floating disc the header hangs opposite the title.

  `Kati.Components.MishkaThemeIcon` is documented as "a themed container around
  exactly one icon", which is exactly what a disc is — and it could not be one
  until the container took a `shadow`. That is the whole of the difference here:
  a disc is *defined* by floating. `variant: :filled` paints `#FBFAF8` and stops
  there, which on this screen's warm paper reads as a pale patch rather than as
  a button sitting above it.

  ## Why the pixels do not move

  With children and no `id`, `theme_icon/2` returns

      %{type: :box,
        props: %{width: 44, height: 44, align: :center, corner_radius: 22,
                 background: Palette.card(), shadow: Kati.Theme.shadow_button(),
                 on_tap: {self(), tag}},
        children: [glyph]}

  — the same eight keys with the same eight values the hand-rolled `<Box>`
  carried; `Palette.card/0` is `0xFFFBFAF8` in light, which is what that `<Box>`
  wrote. `align: :center` and `align="center"` reach the bridge as the same
  string: `align` is in none of the renderer's token whitelists, so an
  unrecognised atom passes through and `:json.encode/1` writes an atom as its
  own name.

  The handler is unchanged too. `theme_icon/2` routes `on_tap` through
  `Kati.Components.Event.handler/1`, whose second clause returns an already
  wired `{pid, tag}` untouched — so the `{self(), tag}` this built by hand is
  the same tuple the component registers. Passing the bare atom would give the
  same result, because `handler/1` widens it with `self()` and a component
  function runs inside the screen's own process; the tuple is kept because it is
  what the markup said.

  Nothing else in the component runs: `:filled` has no gradient layer,
  `skin(:filled, …)` proposes no border so `put_some/3` omits `border_color` and
  `border_width` entirely rather than writing nils, and the id markers are
  skipped without an `id`. The glyph goes in as a child rather than through the
  `icon` prop because that shorthand builds a `Text` with no `font_family` — the
  ligature `"tune"` would be typeset as the word — and because a child keeps
  `Kati.UI.symbol/2`'s default ink, which is the colour the drawing gives it.
  """
  def disc(icon, tag) do
    MishkaThemeIcon.theme_icon(
      %{
        variant: :filled,
        # `card`, not `on_ink` / `fab_glyph` / `on_media` — the other three
        # meanings `Kati.Theme.Palette` gives `0xFFFBFAF8`. A disc is a surface
        # floating above the page, so it follows the ground into `#1E1D1B`.
        color: Palette.card(),
        size: 44,
        radius: 22,
        shadow: Kati.Theme.shadow_button(),
        on_tap: {self(), tag}
      },
      [Kati.UI.symbol(icon, size: 21)]
    )
  end

  @doc false
  def eaten do
    e = Sample.eaten()

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.cream()}
        corner_radius={24}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={19}
      >
        <Row fill_width={true} align="bottom">
          <Column weight={1.0}>
            <Text
              text={String.upcase(e.label)}
              font_family="mono"
              text_size={10.5}
              letter_spacing={0.16}
              text_color={Palette.cream_meta()}
            />
            <Spacer size={7} />
            <Row align="bottom">
              <Text
                text={e.calories}
                text_size={34}
                font_weight="extrabold"
                letter_spacing={-0.04}
                text_color={:on_surface}
                max_lines={1}
              />
              <Text
                text={e.target}
                text_size={16}
                font_weight="semibold"
                text_color={Palette.cream_meta()}
                max_lines={1}
              />
            </Row>
          </Column>
          <Spacer size={12} />
          <Column>
            {Kati.Screens.Health.meals_pill(e.meals)}
            <Spacer size={5} />
          </Column>
        </Row>
        <Spacer size={16} />
        {Kati.Screens.Health.macro_bar(e.macros)}
        <Spacer size={11} />
        <Row fill_width={true} align="center">
          {Kati.Screens.Health.legend(e.macros)}
          <Spacer weight={1.0} />
          <Text
            text={e.grams}
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

  @doc """
  The "3 of 5 logged" badge, green at 16% on cream.

  The same pill screens 04 and 08 use for "done" — three of five meals logged is
  progress, not an alert.

  The drawing hangs it off the row's `flex-end` and then lifts it with
  `margin-bottom:5px`, so it rides just above the baseline of "1,480" rather
  than sitting on it. The caller wraps it in a Column with that 5 underneath; a
  bottom-aligned Row has no other way to say "5 short of the bottom".

  ## The container is `Kati.Components.MishkaPill`

  A compact label on its own fill is what a pill *is*, and the pill can be this
  one now that it takes a `height`, per-edge padding and a numeric `text_size`:
  28 tall, radius 14, 11 of side padding. It is the same call
  `Kati.UI.SettingsList.status_pill/3` makes for the settings rows' status
  badges, and for the same reason.

  The content goes in as **children** rather than as `label`, so the tick can
  come first. That costs the label the pill's own typography props —
  `text_size`, `font_weight` and `color` stay on the `Text` here rather than
  being handed over — and wraps the three nodes in the component's content
  `Row`, one level deeper than the markup put them.

  ## The `leading` slot arrived and does not unblock this

  MishkaPill now has `leading` / `leading_gap`, which is what this used to ask
  for, and it still cannot take the label: **the pill's label carries no
  `font_family`**. `label/3` builds its `Text` from `text`, `text_size`,
  `text_color` and `max_lines`, then merges only `font_weight`,
  `letter_spacing` and `line_height`; `font_family` is in none of those and is
  not a documented pill prop, so `font_family: "mono"` passed alongside `label`
  reaches the tree as nothing at all — an unknown prop, dropped without a word.
  The label would render in the default face instead of DM Mono, and this
  screen's pixels may not move.

  Passing the tick as `leading` while keeping the `Text` as a child *is*
  pixel-safe — it splits one hugging `Row` into two nested hugging `Row`s with
  the same 5pt gap — but it buys nothing: the children wrapper survives, so
  neither of the two costs above goes away, and the tree gains a node. So the
  call stays as it is.

  `font_family` on the label is what would take this over, and it is the one
  prop between here and a pill that owns its own typography.

  ## `padding: 0` is load-bearing

  The pill pads before it sizes and its `padding` default is `:space_sm`, so
  that token would be the fallback for the two edges this does not name and a
  `height: 28` pill would measure 28 plus two paddings. `padding: 0` makes the
  vertical fallback zero; the bridge's `hasEdge` arm then resolves top and
  bottom to `uniform ?: 0`, which is the same `Modifier.padding` call the
  hand-rolled `Row` produced by writing no vertical padding at all.

  ## Why the pixels do not move

  The container changes from a `Row` to a `Box`, and `nodeModifier` is one
  function for every node type — background, radius, padding and height are
  applied by the same chain either way. What differs is how it hugs and where
  its content sits:

    * a `Row` hugs its width; a `Box` hugs only when told, and MishkaPill's root
      passes `fill_width={false}`, which fence K-17 now honours
      (`hugs = boolProp(props, "fill_width") == false` in the bridge's box
      branch). Same width;
    * the `Row` centred its children with `verticalAlignment`; the `Box` centres
      its content with `align: :center`, and the component's own content `Row`
      carries no `align` — which `rowAlignProp` resolves to
      `Alignment.CenterVertically`, since top and bottom are the named cases and
      centre is the default. So the tick lands centred against the label, and
      that centred row lands centred in the 28pt pill;
    * the empty `<Row />` that stands in for the ✕ when `with_remove` is false
      measures 0x0 and adds nothing.
  """
  def meals_pill(label) do
    MishkaPill.pill(
      %{
        background: Palette.green_wash(),
        corner_radius: 14,
        height: 28,
        padding: 0,
        padding_left: 11,
        padding_right: 11,
        align: :center
      },
      meals_content(label)
    )
  end

  # One root node per sigil, so the tick, the gap and the label are three of
  # them. They are handed over as a list, which the pill drops straight into its
  # content Row — wrapping them in a Row here would only add a level.
  defp meals_content(label) do
    [
      Kati.UI.symbol("check", size: 14, color: Palette.green_text()),
      ~MOB"<Spacer size={5} />",
      ~MOB"""
      <Text
        text={label}
        font_family="mono"
        text_size={11.5}
        font_weight="medium"
        text_color={Palette.green_text()}
        max_lines={1}
      />
      """
    ]
  end

  # One 9pt track carrying three weighted segments and no gaps, built the way
  # screen 07's breakdown bars are: heights declared on both the track and the
  # fills rather than inherited, because a fill_height child of a Row inside a
  # fixed Box is one indirection more than this bridge has ever been asked for.
  #
  # The drawing gets its rounded ends from `overflow:hidden` on the track. Mob
  # does not clip children, so the segments stay square and the ink one
  # overhangs the track's 4.5pt corner by a hair. Giving each segment its own
  # radius would be worse — it would open visible notches between them.
  #
  # NOT `Kati.Components.MishkaMeter`, and the name is the trap. This looks like
  # a meter — a value drawn as a proportion of a track — and it is not one. A
  # meter reads ONE measurement inside a range; `render={:box}` accordingly
  # emits one fill `Box` in one `color` plus a remainder. This bar has three
  # fills in three colours that sum to the whole track, and there is no prop
  # anywhere in `MishkaProgress`/`MishkaMeter` that takes more than one: no
  # `segments`, no list-valued `color`. Screens 36 and 55's single-fill bars DO
  # adopt it; this one cannot, and neither can screen 43's copy of it.
  #
  # Nor can a segment be a meter on its own. A weighted share needs `weight` on
  # the node the parent `Row` measures, and the drawn bar's outer track takes
  # only `width` / `fill_width` — `bar/3`'s `:box` arm reads `height`,
  # `corner_radius`, `color`, `track_color`, `id` and `width`, and forwards no
  # `weight` at all. Three cumulative fixed-`width` meters stacked in a Box
  # would draw this shape, but the track here is `fill_width` and no width is
  # known here to do that arithmetic with.
  #
  # Upstream, then: a stacked/segmented mode on the drawn bar — one track, a
  # list of `{share, colour}` — is the thing that would take this over, and it
  # is the same component two screens want. `weight` passthrough on the drawn
  # track would be the smaller, more general fix.
  #
  # The track is `paper` rather than `track`: the drawing fills it `#EFECE7`,
  # which is the page colour, not the `#E7E3DC` the design uses for a progress
  # track elsewhere — and a token has to resolve in light to the literal it
  # replaces. It follows the page down to `#121110` in dark, which keeps it
  # reading as a well sunk into the cream card. The three `tone`s that cover it
  # come from `Kati.Health.Sample` and are still literals there.
  @doc false
  def macro_bar(macros) do
    segments = Enum.map(macros, fn {_name, share, tone} -> macro_segment(share, tone) end)

    ~MOB"""
    <Box fill_width={true} height={9} corner_radius={4.5} background={Palette.paper()}>
      <Row fill_width={true}>
        {segments}
      </Row>
    </Box>
    """
  end

  @doc false
  def macro_segment(share, tone) do
    ~MOB"""
    <Box weight={share} height={9} background={tone} />
    """
  end

  @doc false
  def legend(macros) do
    keys =
      macros
      |> Enum.map(fn {name, _share, tone} -> legend_key(name, tone) end)
      |> Enum.intersperse(legend_gap())

    ~MOB"""
    <Row align="center">
      {keys}
    </Row>
    """
  end

  @doc false
  def legend_gap, do: ~MOB"<Spacer size={13} />"

  @doc false
  def legend_key(name, tone) do
    ~MOB"""
    <Row align="center">
      <Box width={7} height={7} corner_radius={2} background={tone} />
      <Spacer size={5} />
      <Text
        text={String.upcase(name)}
        font_family="mono"
        text_size={9.5}
        letter_spacing={0.08}
        text_color={Palette.eyebrow()}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc false
  def next_meal do
    m = Sample.next_meal()
    tap = {self(), :open_meals}

    # `rail_idle` is right by value and wrong by name: the token whose MEANING
    # is "a faint chevron" is `tertiary`, but its light value is `0xFFB3ACA2`
    # and this chevron is `0xFFC4BDB3`. The design draws two chevron greys and
    # only one of them is `tertiary`; taking the better name would move light
    # mode eleven units, so the value wins. `Kati.UI.SettingsList.chevron/0`
    # records the same discrepancy for the same reason.
    chevron = Kati.UI.symbol("chevron_right", size: 19, color: Palette.rail_idle())

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={16}
        align="center"
        on_tap={tap}
      >
        {Kati.Screens.Health.meal_tile()}
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text
            text={m.title}
            text_size={14.5}
            font_weight="bold"
            letter_spacing={-0.015}
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={3} />
          <Text text={m.line} text_size={11.5} text_color={Palette.sub()} max_lines={1} />
        </Column>
        <Spacer size={12} />
        {chevron}
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  The 36x36 paper tile the next-meal row leads with, from
  `Kati.Components.MishkaThemeIcon` — "a themed container around exactly one
  icon", which is what this is. Every number stays the drawing's: 36dp square,
  radius 12, `#EFECE7` paper, `restaurant` at 19 in the theme's own ink.

  `variant: :filled` with an explicit `color`, not `variant: :white` — the
  white variant paints the theme's `:surface`, which here is `#FBFAF8`, the
  card the tile sits on.

  The glyph is a child rather than the `icon` prop: that shorthand builds a
  `Text` with no `font_family`, so the ligature `"restaurant"` would be
  typeset as the word rather than resolved to the Material Symbols glyph — and
  the child keeps `Kati.UI.symbol/2`'s default colour, which is what the
  drawing gives this one tile.

  With children and no `id`, `theme_icon/2` returns
  `%{type: :box, props: %{width: 36, height: 36, align: :center,
  corner_radius: 12, background: Palette.paper()}, children: [glyph]}` — node for
  node what the row wrote by hand, so nothing moves.
  """
  def meal_tile do
    MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Palette.paper(), size: 36, radius: 12},
      [Kati.UI.symbol("restaurant", size: 19)]
    )
  end

  # Two across. 174*2 + 12 = 360, which is what the gutters leave — so the
  # declared chunk of two reproduces the wrap rather than approximating it, and
  # the tiles take that half by weight (see the moduledoc) rather than by a
  # literal 174 that padding would inflate.
  @doc false
  def sections do
    rows = Sample.sections() |> Enum.chunk_every(2)

    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(rows, fn row -> Kati.Screens.Health.tile_row(row) end)}
      <Spacer size={10} />
    </Column>
    """
  end

  @doc false
  def tile_row(row) do
    tiles =
      row
      |> Enum.map(&tile/1)
      |> Enum.intersperse(tile_gap())

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {tiles}
      </Row>
      <Spacer size={12} />
    </Column>
    """
  end

  @doc false
  def tile_gap, do: ~MOB"<Spacer size={12} />"

  @doc false
  def tile(%{on?: true} = section) do
    ~MOB"""
    <Column
      weight={1.0}
      background={Palette.card()}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={16}
    >
      <Row fill_width={true} align="center">
        {Kati.UI.symbol(section.icon, size: 22)}
        <Spacer weight={1.0} />
        <Box width={7} height={7} corner_radius={4} background={section.dot} />
      </Row>
      <Spacer size={14} />
      <Text
        text={section.name}
        text_size={14.5}
        font_weight="bold"
        letter_spacing={-0.02}
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer size={4} />
      <Text text={section.line} text_size={11} text_color={Palette.sub()} max_lines={1} />
    </Column>
    """
  end

  # No dot, no fill, no shadow: an unbuilt section is an outline. The drawing
  # dashes that outline and this bridge cannot, so it is solid at the same
  # 1.5pt and the same rgba(26,25,23,.14).
  #
  # The line under the name is `rail_idle` for its value, not its name — see
  # `next_meal/0` on the two chevron greys. `0xFFC4BDB3` has exactly one row in
  # `Kati.Theme.Palette` and this is it.
  def tile(%{on?: false} = section) do
    ~MOB"""
    <Column
      weight={1.0}
      corner_radius={20}
      border_width={1.5}
      border_color={Palette.border_soft()}
      padding={16}
    >
      <Row fill_width={true} align="center">
        {Kati.UI.symbol(section.icon, size: 22, color: Palette.tertiary())}
      </Row>
      <Spacer size={14} />
      <Text
        text={section.name}
        text_size={14.5}
        font_weight="bold"
        letter_spacing={-0.02}
        text_color={Palette.muted()}
        max_lines={1}
      />
      <Spacer size={4} />
      <Text text={section.line} text_size={11} text_color={Palette.rail_idle()} max_lines={1} />
    </Column>
    """
  end

  @doc false
  def container_note do
    ~MOB"""
    <Row
      fill_width={true}
      corner_radius={18}
      border_width={1.5}
      border_color={Palette.border()}
      padding={15}
      align="top"
    >
      {Kati.UI.symbol("info", size: 17, color: Palette.sub())}
      <Spacer size={11} />
      <Text
        text={Kati.Health.Sample.container_note()}
        text_size={12.5}
        line_height={1.55}
        text_color={Palette.ink_soft()}
        weight={1.0}
      />
    </Row>
    """
  end

  @doc """
  The whole card is the tap target, so the chevron does not need its own.

  `Kati.Screens.MealsToday` is screen 43, and it is pushed `back: "Health"` —
  the two screens already name each other, so the row's *"Open Meals — dinner
  19:30"* has one destination and it is not a choice.
  """
  @impl true
  def handle_tap(:open_meals, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.MealsToday)}

  # `:open_filters` — the header's `tune` disc — is deliberately inert.
  #
  # Screen 42 draws the disc and nothing behind it: there is no filter sheet in
  # the export, no chip row on this screen, and nothing on it that filtering
  # would narrow. The hero is today's single total, the meal row is the one
  # next thing, and the grid is the six sections Health *has* — a list that
  # would be a lie with any of them hidden, which is the argument the dashed
  # tiles and the container note at the bottom exist to make.
  #
  # So there is no honest consequence to wire, and a sheet invented to give the
  # disc something to do would put a screen in the app the design never drew.
  # It stays a no-op until 42 gains a filter to apply. What this clause does buy
  # is that it is a *quiet* no-op: without a catch-all, the tap raises
  # `UndefinedFunctionError` inside `Kati.Screens.Root.rescue_tap/3` and logs an
  # error on every press, which reads like a bug rather than an unbuilt control.
  def handle_tap(_tag, socket), do: {:noreply, socket}
end
