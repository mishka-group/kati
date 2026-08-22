defmodule Kati.UI do
  @moduledoc """
  Shared building blocks, styled to the design.

  These live here rather than in Mishka Chelekom for now: #44 decided every
  component is built in Kati first and only promoted upstream once Kati has
  actually used it, so that other people's apps never receive a half-proven
  component.

  ## Sizing rules that govern every helper here

    * A `Box` fills its parent's width unless it carries an explicit `width`
      **or explicitly asks to hug**. `fill_width={false}` used to be inert — the
      box branch consulted `width` alone, and `fill_width` was only ever tested
      for `== true` — so a box with neither was force-filled whatever it asked
      for. Fence K-17 in `MobBridge.kt` reads it: the branch is now
      `hasWidth || hugs`. A declared `width` still wins, so nothing that already
      sized itself changed, and the vendored components that define their
      silhouette by hugging (chip, pill, segmented control, toggle, …) draw as
      pills rather than as full-width bars.
    * `Row` and `Column` hug their content. A `Row` given no `align` centres its
      children vertically — `rowAlignProp` names only top and bottom, and
      centre is the fallback — so `align="center"` on a Row is the default
      spelled out, not a change.
    * There is no wrapping primitive, and no geometry is reported back to
      `render/1`, so anything grid-shaped is chunked by a **declared** column
      count rather than measured.
    * A `Text` carries exactly ONE style. The bridge has no `AnnotatedString`
      and no spans, so a paragraph with a bold word inside it cannot be drawn
      the way it is drawn — see `rich_text/1`.
    * A `nil` prop is not an absent prop. `Mob.Renderer` does not strip nils
      and `:json.encode/1` turns the atom `nil` into the **string** `"nil"`
      (`renderer.ex:239`), so it arrives as a value rather than as nothing.
      Numeric and colour props coerce that string back to unset and are safe;
      props matched as strings are not — `font_family={nil}` is read as the
      name of a font and falls through to a system typeface. Helpers here
      therefore always pass a real `font_family`.
  """

  import Mob.Sigil

  alias Kati.Theme.Palette

  @doc """
  A Material Symbol, by the name the design uses.

  The design's icons are Material Symbols Rounded — a ligature font — and Kati
  ships a 143-glyph subset of it. `Kati.Icons.glyph!/1` raises for a name that
  is not in the subset, because the alternative is an empty box on screen that
  reads as a layout bug rather than a missing asset.

  `fill: true` selects the FILL 1 instance. The design uses it for exactly one
  thing — the active tab — and never for a partial value.

  ## The default colour follows the mode

  It was `Kati.Theme.ink/0`, which takes no mode and is `#1A1917` forever. This
  is the single most-called helper in the app — 263 call sites — so that one
  constant would have painted near-black glyphs on near-black cards across every
  screen at once, and the two dark drawings would not have caught it: screens 28
  and 29 pass an explicit `:color` to every symbol they draw, so neither ever
  exercises this default. It is `Palette.ink/0` now, which is the same
  `0xFF1A1917` in light and `#F5F2EE` in dark.

  `Palette.ink/0` reads the installed theme out of application environment, so
  the default costs one `Application.get_env` per glyph and no process hop —
  `Kati.Theme.mode/0` would have put a `Mob.State` GenServer call on every icon
  in every frame.
  """
  @spec symbol(String.t(), keyword()) :: term()
  def symbol(name, opts \\ []) do
    glyph = Kati.Icons.glyph!(name)
    size = Keyword.get(opts, :size, 22)
    color = Keyword.get(opts, :color, Palette.ink())
    family = if Keyword.get(opts, :fill, false), do: "symbols_filled", else: "symbols"

    ~MOB"""
    <Text text={glyph} font_family={family} text_size={size} text_color={color} max_lines={1} />
    """
  end

  @doc """
  A fade from paper up to nothing.

  The design uses this twice over: a 120pt band under the dock so content
  dissolves rather than stopping, and a 190pt band over the bottom of a hero
  photograph so the title has something to sit on.

  It replaced a flat opaque rectangle, which does not fade — it guillotines.
  On Home it was cutting the Sections tiles in half.

  `stop` is where the gradient stops being fully opaque paper, as a percentage
  of `height` measured from the bottom. It is a parameter because the drawings
  disagree on purpose: five of them (04, 08, 14, 45, 58) want the 4% default —
  a hairline of solid paper under a dock that content may touch — while
  thirteen (01, 02, 03, 07, 16, 17, 20, 21, 30, 55, 56, 57, 61) want 42%, which
  is what actually hides the content behind the dock. At 4% the Persian Home's
  section tiles read straight through it.

  ## Both ends of the gradient are the page, so both follow the mode

  The colour was written twice into a string — `#FFEFECE7` and `#00EFECE7` —
  which is why it is the one literal in this file that a grep for `0x` does not
  find. A gradient takes CSS-style `#AARRGGBB`, so the page colour is taken from
  `Palette.paper/1` and its alpha varied here.

  The transparent end MUST be the page colour at alpha 0 and not simply
  transparent-black or `#00FFFFFF`: Compose interpolates in straight RGBA, so a
  fade to transparent white greys the middle of the band and a fade to
  transparent black dirties it. Only a fade to *the same RGB* stays invisible
  along its whole length, which is also why this cannot be `Palette.transparent/0`.

  `mode` defaults to the installed one and is a parameter because `Kati.Shell`
  already has an answer for the frame it is drawing and should not have two.
  """
  @spec paper_fade(pos_integer(), number(), :light | :dark) :: term()
  def paper_fade(height, stop \\ 4, mode \\ Palette.mode()) do
    # ~MOB is an uppercase sigil, so #{} inside it is literal text — the
    # gradient string has to be built out here.
    #
    # `rem/2` rather than a Bitwise import: the low 24 bits of an 0xAARRGGBB
    # integer are the RGB, and this file imports one sigil and nothing else.
    rgb =
      Palette.paper(mode)
      |> rem(0x1000000)
      |> Integer.to_string(16)
      |> String.pad_leading(6, "0")

    gradient = "to_top #FF#{rgb} #{stop}% #00#{rgb}"

    ~MOB"""
    <Box fill_width={true} height={height} gradient={gradient} />
    """
  end

  @doc """
  A section label: a 13x2 accent dash, then mono caps.

  The design uses it eleven times on Home alone, always
  `DM Mono 10.5px / .16em / uppercase / #A0998F` after a `#E8823C` dash — the
  one place orange appears without meaning "new" or "now", because it is
  punctuation rather than status.

  `:trailing` adds a right-aligned label, which the design uses for "See all".
  """
  @spec eyebrow(String.t(), keyword()) :: term()
  def eyebrow(label, opts \\ []) do
    trailing = Keyword.get(opts, :trailing)

    # The dash is not always the accent, and hardcoding it made three screens
    # write their own eyebrow to say so. Orange means new/now in this design —
    # so "Coming up" (05) and "Recently watched" (07) take #C4BDB3 instead,
    # because nothing in either section has happened yet.
    dash = Keyword.get(opts, :dash, Palette.accent())

    # And the tail is not always 11: the drawings say 12 wherever the eyebrow
    # opens a section rather than labelling a card.
    gap = Keyword.get(opts, :gap, 11)

    # `Palette.eyebrow/0` is named for exactly this call site — the mono section
    # label after the dash — and is the only token whose light value is
    # `0xFFA0998F`.
    label_color = Palette.eyebrow()

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        <Box width={13} height={2} corner_radius={1} background={dash} />
        <Spacer size={9} />
        <Text
          text={String.upcase(label)}
          font_family="mono"
          text_size={10.5}
          letter_spacing={0.16}
          text_color={label_color}
        />
        <Spacer weight={1.0} />
        {Kati.UI.eyebrow_trailing(trailing)}
      </Row>
      <Box fill_width={true} height={gap} />
    </Column>
    """
  end

  @doc false
  def eyebrow_trailing(nil), do: ~MOB"<Spacer size={0} />"

  def eyebrow_trailing(label) do
    # "See all". `0xFF8A8479` is `Palette.sub/0`'s light value and no other
    # token's, so the mapping is forced rather than chosen — the name says
    # "second line under a row's title" and this is a trailing action, but the
    # dark value is a ramp step at that lightness and carries no meaning of its
    # own to be wrong about.
    color = Palette.sub()

    ~MOB"""
    <Text text={label} text_size={12.5} font_weight="semibold" text_color={color} />
    """
  end

  @doc "The elevated card: the design's most repeated recipe (262 uses)."
  def card(children, opts \\ []) do
    pad = Keyword.get(opts, :padding, 21)
    bg = Keyword.get(opts, :background, :surface)

    ~MOB"""
    <Box background={bg} corner_radius={20} padding={pad} fill_width={true}>
      <Column fill_width={true}>
        {children}
      </Column>
    </Box>
    """
  end

  @doc "Section heading: small, muted, letter-spaced — sits above a rail or list."
  def section_title(text) do
    ~MOB"""
    <Column padding_bottom={9}>
      <Text text={text} text_size={11} text_color={:muted} letter_spacing={0.14} />
    </Column>
    """
  end

  @doc """
  A paragraph of mixed styling, kept inside ONE wrapping line box.

  Screens 14, 17, 23 and 33 each set a bold or muted span inside a running
  paragraph. The obvious translation — a `Row` of `Text` nodes, one per run —
  is wrong, and wrong in a way that looks like a bug: a `Row` does not wrap, so
  every run becomes its own unbreakable box and the emphasised words orphan
  onto a line of their own. A single `Text` is the only node that wraps, so
  this stays a single `Text`.

  ## What the bridge can do, and what it cannot

  `MobText` (`MobBridge.kt:2725`) reads `text` as a plain `String` and hands it
  to Compose's `Text(String, …)` overload with one `color`, one `fontWeight`,
  one `fontFamily`. There is no `AnnotatedString`, no `SpanStyle` and no
  `buildAnnotatedString` anywhere in the bridge — the only occurrence of the
  word "span" is in a comment about icon coverage.

  **Per-run styling is therefore not rendered.** This function concatenates the
  runs and applies ONE style to all of them. The paragraph then wraps and
  measures correctly, and the emphasis is silently dropped. That trade is
  deliberate — a bold that came out regular reads as plain typography, while an
  orphaned word reads as a broken layout — but it is an approximation, not the
  thing the design asks for.

  ### The bridge change that would make it real

  Give `MobText` a `runs` prop. The wire already carries lists of maps (Canvas
  `draw` ops travel that way, `MobBridge.kt:3347`), so nothing new is needed
  underneath. When `runs` is present, build the value with

      buildAnnotatedString {
        runs.forEach { r ->
          withStyle(SpanStyle(fontWeight = …, color = …)) { append(r["text"]) }
        }
      }

  and pass it to the `Text(AnnotatedString, …)` overload, keeping the flat
  `text` prop as the path for every existing call site. Only this function's
  body would change; its callers would not.

  ## Runs, and which style wins

  A run is `{text, style}`. `style` is a keyword list of `Text` props, or one of
  the shorthands `:bold`, `:semibold`, `:muted`, or `nil` for no change.

      body = [text_size: 13, text_color: :muted, line_height: 1.5]

      Kati.UI.rich_text([
        {"You have watched ", body},
        {"14 episodes", :bold},
        {" this week.", body}
      ])

  The style handed to the `Text` is the one from the run marked `base: true`;
  with no such mark it is the style of the LONGEST run, ties going to the run
  written first. For the shape these four screens use — a long body with a
  short emphasis inside it — that resolves to the body, which is the answer you
  want. Mark a run `base: true` when the copy is short enough that editing it
  could flip the choice.

  `text_size` falls back to 14 and `text_color` to `:on_surface` rather than
  being left unset, because an unset size does not fail — it renders at
  Compose's own default, which is the expensive kind of wrong.
  """
  @spec rich_text([{String.t(), keyword() | atom()}]) :: term()
  def rich_text(runs) when is_list(runs) do
    normalised = Enum.map(runs, fn {text, style} -> {text, run_style(style)} end)
    text = Enum.map_join(normalised, "", fn {t, _style} -> t end)
    base = base_run_style(normalised)

    size = Keyword.get(base, :text_size, 14)
    color = Keyword.get(base, :text_color, :on_surface)
    weight = Keyword.get(base, :font_weight)
    line_height = Keyword.get(base, :line_height)
    tracking = Keyword.get(base, :letter_spacing)
    align = Keyword.get(base, :text_align)

    # Every other optional prop below coerces a stray "nil" back to unset, but
    # font_family is matched as a string, so a nil would be taken for the name
    # of a font and resolve to a system typeface instead of Plus Jakarta.
    family = Keyword.get(base, :font_family, "sans")

    ~MOB"""
    <Text
      text={text}
      text_size={size}
      text_color={color}
      font_weight={weight}
      font_family={family}
      line_height={line_height}
      letter_spacing={tracking}
      text_align={align}
    />
    """
  end

  # Shorthands for the two things the four screens actually ask for; anything
  # else is spelled out as Text props.
  defp run_style(nil), do: []
  defp run_style(:bold), do: [font_weight: "bold"]
  defp run_style(:semibold), do: [font_weight: "semibold"]
  defp run_style(:muted), do: [text_color: :muted]
  defp run_style(style) when is_list(style), do: style

  defp base_run_style([]), do: []

  defp base_run_style(runs) do
    marked = Enum.find(runs, fn {_text, style} -> Keyword.get(style, :base, false) end)

    # sort_by is stable, so runs of equal length keep the order they were
    # written in and the choice does not wobble between renders.
    {_text, style} =
      marked || hd(Enum.sort_by(runs, fn {text, _style} -> -String.length(text) end))

    Keyword.delete(style, :base)
  end

  @doc """
  A poster tile at the design's 2:3 ratio.

  Real artwork arrives with the media tickets; until then this is a toned
  placeholder rather than a network fetch, so the shell can be judged offline
  and on a cold emulator.
  """
  def poster(label, tone) do
    # `on_media`, not `card` — both are `0xFFFBFAF8` in light and they are
    # opposites in dark. The ground here is `tone`, which stands in for artwork,
    # and a photograph does not get darker when the app does: `on_media` holds
    # at `#FBFAF8` in both modes. `card`, `on_ink` and `fab_glyph` are the other
    # three meanings of this same literal and every one of them would have
    # turned this title near-black over a picture.
    ink = Palette.on_media()

    ~MOB"""
    <Column padding_right={13}>
      <Box width={112} height={168} background={tone} corner_radius={14} align="bottom">
        <Column padding={9}>
          <Text text={label} text_size={10} text_color={ink} />
        </Column>
      </Box>
    </Column>
    """
  end

  @doc "A row in the day timeline: fixed time gutter, then the event card."
  def timeline_row(time, title, meta, accent?) do
    # LEFT AS A LITERAL. `0xFFC9C3B8` is in no `Kati.Theme.Palette` row. The
    # nearest is `rail_idle`'s `0xFFC4BDB3` — the timeline rail on the very
    # screens this row belongs to — but five units apart is a different colour,
    # and taking it would change light mode to make dark mode work.
    dot = if accent?, do: Kati.Theme.accent(), else: 0xFFC9C3B8

    ~MOB"""
    <Row align="top" fill_width={true}>
      <Box min_width={54} min_height={44} align="top">
        <Column>
          <Text text={time} text_size={11} text_color={:muted} font_family="mono" />
        </Column>
      </Box>
      <Box width={16} height={44} align="top">
        <Column padding_top={4}>
          <Box width={7} height={7} background={dot} corner_radius={4} />
        </Column>
      </Box>
      <Column fill_width={true} padding_bottom={13}>
        <Text text={title} text_size={14} text_color={:on_surface} />
        <Spacer size={2} />
        <Text text={meta} text_size={11} text_color={:muted} />
      </Column>
    </Row>
    """
  end

  @doc "A two-up tile for the Sections grid. Chunked by a declared count — nothing wraps."
  def section_tile(label, count, tone) do
    ~MOB"""
    <Column padding_right={13} padding_bottom={13}>
      <Box width={158} height={92} background={tone} corner_radius={20} align="bottom">
        <Column padding={15}>
          <Text text={label} text_size={14} text_color={:on_surface} />
          <Spacer size={2} />
          <Text text={count} text_size={11} text_color={:muted} />
        </Column>
      </Box>
    </Column>
    """
  end

  @doc """
  One row of a grid, divided evenly across whatever width the device has.

  The grids here were measured off the drawing's 402dp frame — `section_tile/3`
  is a hard 158dp — so on a 411dp device the row ends early and leaves a dead
  gutter down one side. A weight divides the space that is actually present, so
  a weighted row fits every device rather than one.

  Each cell is wrapped in a `weight={1.0}` column, with a fixed gap between
  them. The gap is a sized `Box`, not a `Spacer`: a `Spacer` sizes BOTH axes
  from `size`, so a 13dp gap would also put a 13dp floor under the row.

  ## Short rows have to be padded

  A weight divides what is present, so a final row holding a single cell hands
  that cell the entire width and it renders three times the size of its
  neighbours in the row above. Pass `:columns` — the grid's declared column
  count — and the missing cells are filled with empty weighted columns that
  hold the geometry open.

      titles
      |> Enum.chunk_every(3)
      |> Enum.map(&Kati.UI.even_row(&1, columns: 3))

  Cells inside are top-aligned, so one tall cell does not drag its neighbours
  down. Cells should size themselves vertically and leave width alone — a cell
  carrying its own fixed `width` defeats the whole point.

  A weight needs a bounded parent to divide, so this belongs in a `Column` or a
  vertical `Scroll`. Inside a horizontal `Scroll` the available width is
  unbounded and there is nothing to share out.

  ## Options

    * `:columns` — the grid's column count. Defaults to the number of cells
      given, which means no padding and is only correct for a full row.
    * `:gap` — dp between cells. Defaults to the design's 13.
  """
  @spec even_row([term()], keyword()) :: term()
  def even_row(cells, opts \\ []) do
    gap = Keyword.get(opts, :gap, Kati.Theme.gap_md())
    columns = max(Keyword.get(opts, :columns, length(cells)), length(cells))
    blank = ~MOB"<Spacer size={0} />"

    children =
      (cells ++ List.duplicate(blank, columns - length(cells)))
      |> Enum.map(&even_cell/1)
      |> Enum.intersperse(even_gap(gap))

    ~MOB"""
    <Row fill_width={true} align="top">
      {children}
    </Row>
    """
  end

  # The weight is read off the CHILD's own props by the parent Row
  # (`MobBridge.kt:2675`), so it has to live on a wrapper — it cannot be
  # applied to a cell node that has already been rendered.
  defp even_cell(node) do
    ~MOB"""
    <Column weight={1.0} fill_width={true}>
      {node}
    </Column>
    """
  end

  # Height is declared so this reserves space on one axis only. 1dp rather than
  # 0 so it is unambiguously a laid-out node, and 1dp can never be the tallest
  # thing in a row of cells.
  defp even_gap(width) do
    ~MOB"""
    <Box width={width} height={1} />
    """
  end

  @doc """
  A filter chip.

  Three states, not two. `:disabled` is the design's own way of showing a
  section that exists but is not built yet — screens 03 and 57 draw Books and
  Music greyed rather than hiding them, which is also how #60 scoped v1 to
  Screen. Hiding them would misrepresent the app's shape; grey states the
  intent.

  ## Options

    * `:selected` — the filled state: ink pill, `#FBFAF8` label.
    * `:disabled` — transparent pill, `#B5AEA3` label.
    * `:count` — a dimmer number after the label, as the library and day filters
      draw it.

  ## No trailing gap

  This pill deliberately ends where it ends. Several screens grew their own chip
  with the inter-chip gap baked in *inside* the pill as a trailing `Spacer`,
  which both pushes the label off centre — the pill has 15dp on the left and
  15dp plus the gap on the right — and makes chips abut whenever the gap is
  interpreted as part of the background. The gap belongs to whoever is arranging
  the chips, so callers intersperse a `<Spacer width={9} />` between them.

  ## Built on `Kati.Components.MishkaChip`

  The pill was hand-rolled until the component stopped hardcoding its own
  dimensions and its own unchecked/disabled colours. It no longer does: `height`,
  `width`, `padding_x`/`padding_y`, `corner_radius`, `text_size`, `max_lines`,
  the `trailing` slot and all six state colours are props, so the design's chip
  is now expressible and this is a call rather than markup.

  **Nothing moved.** The component builds the same node this wrote by hand:

      Box(background, corner_radius: 16, height: 32, width, align: center,
          padding_left: 15, padding_right: 15)
        Row(center)
          Text(label, 12, ink, max_lines: 1)
          <trailing>

  with three differences that are all no-ops against this bridge:

    * the Box also carries `fill_width: false`. `nodeModifier` only ever tests
      `fill_width == true`, and the box branch is `hasWidth || hugs`, so a box
      that already declares a `width` takes the same arm either way
      (`MobBridge.kt`, fence K-17).
    * the four padding edges are written out — `padding_top`/`padding_bottom` of
      `0` where this wrote nothing. The bridge's `hasEdge` arm resolves a missing
      edge to `uniform ?: 0`, so an absent top and a top of `0` are the same
      `Modifier.padding` call.
    * with no `:count` the Box holds the `Text` directly instead of a `Row`
      holding the `Text` and a zero-sized `Spacer`. A `Row` hugs, and a `Spacer`
      of `size={0}` measures 0x0 and paints nothing, so the wrapper was already
      the same box as the text it contained.

  With a `:count` the tree is identical node for node: `chip_count/2` is handed
  in as the `trailing` slot, and MishkaChip places a node slot as given.
  """
  @spec chip(String.t(), keyword() | atom()) :: term()
  def chip(label, opts \\ [])

  # The old positional-state form, kept so a call written from memory does not
  # raise on a keyword lookup against an atom.
  def chip(label, state) when is_atom(state) do
    chip(label, selected: state == :selected, disabled: state == :disabled)
  end

  def chip(label, opts) when is_list(opts) do
    count = Keyword.get(opts, :count)
    count_text = if count, do: to_string(count), else: nil
    selected? = Keyword.get(opts, :selected, false)
    disabled? = Keyword.get(opts, :disabled, false)

    # The pill and the label are the component's to resolve — it checks
    # disabled BEFORE checked in both `background/3` and `text_color/3`, which
    # is the precedence the three states had here. The count is not: it lives in
    # the trailing slot as a finished node, carrying its own colour, so its
    # third value stays on this side.
    count_fg =
      cond do
        # LEFT AS A LITERAL. `0xFFB5AEA3` is not in `Kati.Theme.Palette` — it is
        # two units off `tertiary`'s `0xFFB3ACA2` and naming it that would move
        # light. It stays light-grey in dark, which is wrong and visible; it
        # needs a token, not a guess. Same value, same reason, on
        # `disabled_text_color` below.
        disabled? -> 0xFFB5AEA3
        selected? -> Palette.on_ink_muted()
        true -> Palette.eyebrow()
      end

    Kati.Components.MishkaChip.chip(
      label: label,
      checked: selected?,
      disabled: disabled?,
      # A selected chip is an ink-filled control, so it takes the pair the
      # design draws for one: `ink_fill` under `on_ink`. Screen 28 draws that
      # pair — `#1A1917` + `#FBFAF8` becomes `#F7EFE4` + `#1A1917` — the fill
      # inverting rather than following the ground. `Kati.Theme.ink/0` was the
      # fill before and takes no mode, so the pill and its label would both have
      # gone near-black.
      color: Palette.ink_fill(),
      text_color: Palette.on_ink(),
      unchecked_color: Kati.Theme.card(Palette.mode()),
      unchecked_text_color: Palette.ink_soft(),
      # One value for both disabled states, which is what this design asks for:
      # a section that is not built yet reads the same whether or not it is the
      # current filter.
      disabled_color: Palette.transparent(),
      disabled_text_color: 0xFFB5AEA3,
      corner_radius: 16,
      height: 32,
      # No `width`. The chip MEASURES itself now.
      #
      # It used to declare `chip_content_width/2` — 7dp per glyph — because a
      # Box force-filled its parent unless given a number, so a hugging chip
      # was impossible and an approximation was the only way to get one. Fence
      # K-17 made `fill_width={false}` work, and MishkaChip's root passes it,
      # so the component sizes itself from its own text and padding.
      #
      # Dropping it changed NOTHING on device — 62 of 62 frames identical, pill
      # runs byte for byte. That is worth recording, because the reason given
      # for dropping it was wrong: the sub-pixel text shift seen when this
      # chip became a component came from the structural change (a hand-rolled
      # Row becoming the component's Box + Row), not from centring inside a
      # declared width. The approximation and the measurement simply agree at
      # this text size.
      #
      # It stays retired because measuring is correct and approximating is not
      # — 7dp per glyph errs wide on "iOS" and narrow on "Watchlist", and the
      # next label that disagrees would be a bug nobody could see coming.
      # padding_y MUST be given. The component pads before it sizes, so the
      # default `:space_sm` on the vertical axis would make a `height: 32` chip
      # measure 32 plus two paddings.
      padding_x: 15,
      padding_y: 0,
      text_size: 12,
      max_lines: 1,
      trailing: chip_trailing(count_text, count_fg)
    )
  end

  # `nil` is the component's "no trailing slot", which is not what
  # `chip_count/2` returns for a missing count — that clause predates the slot
  # and answers a zero-sized Spacer, because the old markup always had a Row to
  # put something in.
  defp chip_trailing(nil, _color), do: nil
  defp chip_trailing(text, color), do: chip_count(text, color)

  @doc false
  def chip_count(nil, _color), do: ~MOB"<Spacer size={0} />"

  def chip_count(text, color) do
    # A Box stacks, so the count has to share a Row with the label rather than
    # be handed to the pill as a second child.
    ~MOB"""
    <Row align="center">
      <Spacer width={6} />
      <Text text={text} text_size={11} text_color={color} max_lines={1} />
    </Row>
    """
  end

  @doc "A headline statistic with its label."
  def stat(value, label) do
    ~MOB"""
    <Column padding_right={26}>
      <Text text={value} text_size={22} text_color={:on_surface} letter_spacing={-0.5} />
      <Spacer size={3} />
      <Text text={label} text_size={11} text_color={:muted} />
    </Column>
    """
  end

  @doc """
  A big number and its small unit, sitting on one optical baseline.

  `align="bottom"` is not baseline alignment. It bottoms out the two text
  *boxes* (`MobBridge.kt:4208`), and a text box carries descender space in
  proportion to its size, so a small unit beside a big number lands 3-4dp below
  the number's baseline at the sizes the design uses, and further as the gap
  between the two sizes widens — far enough to read as a bug rather than as
  typography. The bridge has no baseline mode (`align` is top/center/bottom
  only) and no metrics come back from `render/1`, so the correction cannot be
  computed: it is declared.

  `lift` is how far the unit has to be raised, in dp. It is applied as bottom
  padding on a `Column` wrapped around the unit, because the unit arrives here
  as a finished node — there is no way to add a prop to it after the fact.
  `(number_size - unit_size) / 5` is a decent first guess, but it is a design
  number rather than a formula — pass what the drawing shows. The far side
  reads padding with `intProp`, so a fractional lift is truncated rather than
  honoured.

  Both arguments are already-rendered nodes, so the caller keeps control of
  size, weight and colour.

  ## Naming

  This is the former `baseline_row/3` renamed, not a second helper beside it:
  there was already one doing exactly this, and its name claimed the one thing
  the bridge does not have. `baseline_row/3` still delegates here so a call
  written from memory does not raise.
  """
  @spec number_with_unit(term(), term(), number()) :: term()
  # `offset_y`, not `padding_bottom`, and the difference is not cosmetic: the
  # bridge reads padding with `intProp`, which truncates a Double (3.4 -> 3),
  # so a fractional lift silently lost its fraction. `offset_y` goes through
  # `floatProp` and keeps it. It also shifts the PAINT rather than the layout,
  # which is what a baseline nudge is — the row's height must not change
  # because a unit moved up 3.4pt inside it.
  def number_with_unit(number, unit, lift) do
    ~MOB"""
    <Row align="bottom">
      {number}
      <Column offset_y={-lift}>
        {unit}
      </Column>
    </Row>
    """
  end

  @doc false
  @deprecated "Renamed — use Kati.UI.number_with_unit/3"
  def baseline_row(number, unit, lift), do: number_with_unit(number, unit, lift)

  @doc "A labelled horizontal bar. Width is declared, never measured."
  def bar(label, width, tone) do
    ~MOB"""
    <Column padding_bottom={11} fill_width={true}>
      <Row align="center">
        <Box width={92} height={22} align="leading">
          <Column>
            <Text text={label} text_size={12} text_color={:on_surface} />
          </Column>
        </Box>
        <Box width={width} height={9} background={tone} corner_radius={5} />
      </Row>
    </Column>
    """
  end

  @doc """
  The design's pixel field: 104 cells at 2px radius, the shared visual for
  anything that accumulates over time.

  Chunked into declared rows because `Row` does not wrap and no geometry comes
  back from `render/1`.
  """
  def pixel_field(intensities, per_row) do
    rows = Enum.chunk_every(intensities, per_row)

    ~MOB"""
    <Column>
      {Enum.map(rows, fn row -> Kati.UI.pixel_row(row) end)}
    </Column>
    """
  end

  @doc false
  def pixel_row(row) do
    ~MOB"""
    <Row>
      {Enum.map(row, fn i -> Kati.UI.pixel(i) end)}
    </Row>
    """
  end

  @doc false
  # LEFT AS LITERALS, all five, and deliberately as a set.
  #
  # Only `0xFFB08E55` has a token — it is `Kati.Theme.bronze/0` — and the other
  # four are in no `Kati.Theme.Palette` row at all. This is one bronze ramp, so
  # naming its middle step and leaving its neighbours as hex would read as if
  # the four unnamed ones had been checked and rejected. They have not been
  # checked; there is nothing to check them against.
  #
  # It matters more here than the count suggests: step 0 is `#E4DFD6`, a pale
  # warm grey that is a whole field of near-white squares on a near-black card.
  # The field needs a ramp of its own in the palette before it can be converted.
  def pixel(intensity) do
    tone =
      case intensity do
        0 -> 0xFFE4DFD6
        1 -> 0xFFD8CDB8
        2 -> 0xFFC7A97E
        3 -> 0xFFB08E55
        _ -> 0xFF8A6B3A
      end

    ~MOB"""
    <Column padding_right={3} padding_bottom={3}>
      <Box width={15} height={15} background={tone} corner_radius={2} />
    </Column>
    """
  end
end
