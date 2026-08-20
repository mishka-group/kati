defmodule Kati.UI.SettingsList do
  @moduledoc """
  The grouped list the Settings subtree is built from.

  Screens 24, 25, 32 and 36 are almost entirely one recipe: a `#FBFAF8` card at
  radius 20 with `4px 15px` of padding, holding rows of
  *30x30 icon tile · title (+ secondary line) · trailing control*, separated by
  a `rgba(26,25,23,.07)` hairline that the last row does not get. Between those
  four drawings exactly one number moves — 13pt or 14pt of vertical row padding
  — so that is the only knob `row/4` takes.

  This lives beside the screens rather than inside `Kati.UI` for the reason #44
  gives for Mishka: a shared component earns its place by being used, and this
  one is used five times in one commit. `Kati.Shell` is the precedent for the
  checker as well — `bin/check_screen.py` is passed the file that owns a
  screen's shared chrome, which for these five is this module.

  ## What is a component and what is not

  `icon_tile/1` and `disc/1` are `Kati.Components.MishkaThemeIcon`, `hairline/1`
  is `Kati.Components.MishkaSeparator` (with `render: :box` — see its docs for
  why that word is load-bearing), and both pills are
  `Kati.Components.MishkaPill`. Each of those became possible only once the
  component stopped hardcoding a number the drawing specifies; each call's own
  doc records which number, and why its node is the node the markup built.

  ## Two departures from the drawing, both bridge limits

    * **The switch is hand-built.** `Kati.Components.MishkaSwitch` wraps Mob's
      `Toggle`, which paints Compose's own Material `Switch` at Material's own
      metrics. The design draws a 46x28 track at radius 14 with a 22pt thumb
      and an ink "on" state; no prop reshapes a `Switch` into that, and the
      port's own docs note the colour props are ignored on iOS anyway. This is
      not a component that is missing props: `material3` fixes the track at
      52x32 with 24/16pt handles and a 2dp outline, and parameterises only the
      colours. A prop cannot reach those numbers, so the switch stays markup
      until the bridge grows a non-Material toggle.
    * **Dashed borders are solid.** `Modifier.border` takes a width and a
      colour and no `PathEffect`, so `note/2` draws its 1.5pt hairline solid at
      the design's own `rgba(26,25,23,.16)`. The frame reads as a footnote
      either way; the stitching does not survive.

  Nothing here carries copy. Every string and every icon name is passed in, so
  a screen's own file still holds every literal its drawing contains.
  """

  import Mob.Sigil

  @doc """
  The row the pushed back pill floats over.

  `Kati.Screens.Pushed` draws the pill as an overlay, so the content has to
  reserve its height and hang the trailing disc opposite it — the same
  arrangement `Kati.Screens.Inbox.mark_all/0` uses for "Mark all". Pass `nil`
  when the drawing puts nothing on the right of the pill.

  **Known gap, recorded rather than hacked around.** The drawing puts the pill
  and the disc in one row; the shared pill is pinned at `padding_top: 54` while
  this row starts at the frame's own 64, so the disc's centre lands about 13pt
  below the pill's. Screen 05 has the same 9pt version of it and is signed off,
  and the fix belongs in `Kati.Screens.Pushed` — one number, once — rather than
  in an `offset_y` repeated on every screen that uses this.
  """
  def chrome(icon, height \\ 44)

  def chrome(nil, height) do
    ~MOB"""
    <Column fill_width={true}>
      <Box fill_width={true} height={height} />
      <Spacer size={16} />
    </Column>
    """
  end

  def chrome(icon, height) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} height={height} align="center">
        <Spacer weight={1.0} />
        {Kati.UI.SettingsList.disc(icon)}
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  A 44pt floating disc carrying one symbol.

  Built on `Kati.Components.MishkaThemeIcon` for the same reason `icon_tile/1`
  is — it is a themed container around exactly one icon — and it could not be
  until the container took a `shadow`. That mattered here more than anywhere:
  a disc is *defined* by floating. `variant: :filled` paints a fill and stops,
  which reads as a pale patch on paper rather than as a button above it, so
  without `shadow` this had to stay hand-rolled markup.

  ## Why the pixels do not move

  With children and no `id`, `theme_icon/2` returns

      %{type: :box,
        props: %{width: 44, height: 44, align: :center, corner_radius: 22,
                 background: 0xFFFBFAF8, shadow: Kati.Theme.shadow_button()},
        children: [glyph]}

  which is the node this wrote by hand, key for key. `align: :center` and
  `align="center"` reach the bridge as the same string. Nothing else in the
  component runs: `:filled` has no gradient layer and no border, the id markers
  are skipped without an `id`, and the `icon` shorthand is skipped when children
  are given — which is also why the glyph is passed as a child, since that
  shorthand builds a `Text` with no `font_family` and would typeset the ligature
  name instead of resolving it.

  `Kati.Components.MishkaActionIcon` would have been the other candidate and now
  takes a `shadow` too, but it wraps caller-supplied content in a `Row`. That
  `Row` is layout-neutral and the disc would still render identically; the theme
  icon simply produces the same tree with one node fewer, and keeps this
  file's two containers on one component.
  """
  def disc(icon) do
    Kati.Components.MishkaThemeIcon.theme_icon(
      %{
        variant: :filled,
        color: 0xFFFBFAF8,
        size: 44,
        radius: 22,
        shadow: Kati.Theme.shadow_button()
      },
      [Kati.UI.symbol(icon, size: 21)]
    )
  end

  @doc """
  The 28pt screen title over its mono subtitle.

  Screen 24 is the one that hangs a disc off this row instead of off the back
  pill's, so `disc` is an option rather than a second function.
  """
  def title(text, sub, disc \\ nil)

  def title(text, sub, nil) do
    ~MOB"""
    <Column fill_width={true}>
      <Text text={text} text_size={28} font_weight="bold" letter_spacing={-0.03} text_color={:on_surface} />
      <Spacer size={5} />
      <Text text={sub} font_family="mono" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
      <Spacer size={20} />
    </Column>
    """
  end

  def title(text, sub, icon) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column weight={1.0}>
          <Text text={text} text_size={28} font_weight="bold" letter_spacing={-0.03} text_color={:on_surface} />
          <Spacer size={5} />
          <Text text={sub} font_family="mono" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
        </Column>
        <Spacer size={9} />
        {Kati.UI.SettingsList.disc(icon)}
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  An eyebrow whose dash is `#C4BDB3` rather than accent.

  `Kati.UI.eyebrow/2` always draws the orange dash, and orange means new/now.
  These drawings use the grey dash for a section that is a footnote to the one
  above it — About under Data, Write back under Which calendars show — so the
  colour is carrying meaning and cannot be flattened to one helper.
  """
  def eyebrow_muted(label) do
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

  @doc "The grouped card: `#FBFAF8` at radius 20, 4pt top and bottom, 15pt sides."
  def card(rows) do
    ~MOB"""
    <Column
      fill_width={true}
      background={0xFFFBFAF8}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card_soft()}
      padding_left={15}
      padding_right={15}
      padding_top={4}
      padding_bottom={4}
    >
      {rows}
    </Column>
    """
  end

  @doc """
  One row: leading · body · trailing, with the hairline unless it is the last.

  `:padding` is 13 or 14 depending on the group — the drawings differ by that
  one point and nothing else. `:rule` is false for the final row.
  """
  def row(leading, body, trailing, opts \\ []) do
    pad = Keyword.get(opts, :padding, 13)
    rule? = Keyword.get(opts, :rule, true)
    # A row that names a screen should open it. Without a tap the whole
    # settings tree is a picture of a settings tree.
    tap = Keyword.get(opts, :on_tap)

    ~MOB"""
    <Column fill_width={true} on_tap={tap}>
      <Row fill_width={true} align="center" padding_top={pad} padding_bottom={pad}>
        {leading}
        <Spacer size={13} />
        <Column weight={1.0}>
          {body}
        </Column>
        {Kati.UI.SettingsList.trailing(trailing)}
      </Row>
      {Kati.UI.SettingsList.hairline(rule?)}
    </Column>
    """
  end

  @doc false
  def trailing(nil), do: ~MOB"<Spacer size={0} />"

  def trailing(node) do
    ~MOB"""
    <Row align="center">
      <Spacer size={12} />
      {node}
    </Row>
    """
  end

  @doc """
  The `rgba(26,25,23,.07)` rule between two rows.

  `render: :box` is not optional here, and it is the whole reason this can be
  `Kati.Components.MishkaSeparator` at all. The default `:divider` maps to
  Material3's `HorizontalDivider`, which is an antialiased `drawLine`: at this
  device's 2.6875x a 1dp rule gets a 3px canvas and a 2.6875px stroke, so the
  last pixel row lands at ~69% coverage and the hairline comes out 4-5/255
  lighter along one row. `render: :box` swaps the primitive for a filled rect,
  where every row carries the full colour — which is what the drawing specifies
  and what this file drew by hand.

  ## Why the pixels do not move

  `separator(render: :box)` builds

      <Box fill_width={true} height={1} background={0x121A1917}>
        <Spacer size={1} />
      </Box>

  — the same Box, with one child added. The `Spacer` is an iOS workaround
  (`MobBox` drops a Box's `height` unless the Box also has a `width`, so a
  childless bar measures 0pt tall there). On Android the Box's own `height`
  pins it, and a `Spacer` paints nothing at all: `MobSpacer` is a bare
  `Spacer(modifier.size(1.dp))` with no background. So the rule is 1dp tall
  with or without it, and nothing is drawn inside.

  `false` still answers a zero-sized `Spacer` rather than a separator: the last
  row in a card has no rule, and a component whose entire job is to draw a line
  has no way to say "draw nothing".
  """
  def hairline(false), do: ~MOB"<Spacer size={0} />"

  def hairline(true) do
    Kati.Components.MishkaSeparator.separator(
      color: 0x121A1917,
      thickness: 1,
      render: :box
    )
  end

  @doc "A row's title, with the design's 11.5pt secondary line under it when there is one."
  def body(title, sub \\ nil)

  def body(title, nil) do
    ~MOB"""
    <Text text={title} text_size={13.5} font_weight="semibold" text_color={:on_surface} max_lines={1} />
    """
  end

  def body(title, sub) do
    ~MOB"""
    <Column fill_width={true}>
      <Text text={title} text_size={13.5} font_weight="semibold" text_color={:on_surface} max_lines={1} />
      <Spacer size={3} />
      <Text text={sub} text_size={11.5} text_color={0xFF8A8479} max_lines={1} />
    </Column>
    """
  end

  @doc "A row title the design greys out — a calendar switched off, an add affordance."
  def body_muted(title) do
    ~MOB"""
    <Text text={title} text_size={13.5} font_weight="semibold" text_color={0xFF8A8479} max_lines={1} />
    """
  end

  @doc """
  The 30x30 paper tile every settings row leads with.

  `Kati.Components.MishkaThemeIcon` is documented as "a themed container around
  exactly one icon", which is precisely what this is, so the container is its
  rather than one more hand-rolled `Box`. Every number stays the drawing's:
  30dp square, radius 9, `#EFECE7` paper, glyph at 17 in `#5C574F`.

  `variant: :filled` with an explicit `color`, **not** `variant: :white` — the
  white variant paints the theme's `:surface`, which here is `#FBFAF8`, the
  card. The tile is paper, and the two are three values apart.

  ## Why the glyph is a child rather than the `icon` prop

  The `icon` shorthand builds its own `Text` and that `Text` carries no
  `font_family`, so a Material Symbols **ligature** — `"chevron_right"` — would
  be typeset as the words rather than resolved to the glyph. Handing
  `Kati.UI.symbol/2` in as a child keeps the symbols face, and keeps
  `Kati.Icons.glyph!/1`'s raise for a name outside the shipped subset, which is
  the entire reason that helper exists.

  ## Why the pixels do not move

  With children and no `id`, `theme_icon/2` returns
  `%{type: :box, props: %{width: 30, height: 30, align: :center,
  corner_radius: 9, background: 0xFFEFECE7}, children: [glyph]}` — node for
  node what this wrote by hand. `align: :center` and `align="center"` reach the
  bridge as the same string: `align` is in none of the renderer's token
  whitelists, so an unrecognised atom passes through and `:json.encode/1`
  writes an atom as its own name. Nothing else in the component runs — the
  gradient layer is empty for `:filled`, the id markers are skipped without an
  `id`, and the glyph shorthand is skipped when children are given.
  """
  def icon_tile(name) do
    Kati.Components.MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: 0xFFEFECE7, size: 30, radius: 9},
      [Kati.UI.symbol(name, size: 17, color: 0xFF5C574F)]
    )
  end

  @doc "The disclosure chevron, at the design's `#C4BDB3`."
  def chevron do
    Kati.UI.symbol("chevron_right", size: 18, color: 0xFFC4BDB3)
  end

  @doc """
  The 46x28 track with its 22pt thumb.

  Two clauses rather than one with a conditional child, because the thumb sits
  against the opposite edge in each state and a `Spacer` cannot be conditional
  inside `~MOB`.
  """
  def switch(true) do
    ~MOB"""
    <Box width={46} height={28} corner_radius={14} background={0xFF1A1917}>
      <Row fill_width={true} fill_height={true} align="center" padding_left={3} padding_right={3}>
        <Spacer weight={1.0} />
        <Box width={22} height={22} corner_radius={11} background={0xFFFBFAF8} shadow="0 1 3 0 #4D1A1917" />
      </Row>
    </Box>
    """
  end

  def switch(false) do
    ~MOB"""
    <Box width={46} height={28} corner_radius={14} background={0xFFDCD7CF}>
      <Row fill_width={true} fill_height={true} align="center" padding_left={3} padding_right={3}>
        <Box width={22} height={22} corner_radius={11} background={0xFFFBFAF8} shadow="0 1 3 0 #4D1A1917" />
        <Spacer weight={1.0} />
      </Row>
    </Box>
    """
  end

  @doc """
  The small paper button a row carries instead of a switch.

  `Kati.Components.MishkaPill`, now that the pill takes a `height`, per-edge
  padding and a numeric `text_size` — 30 tall, 12 of side padding and an 11.5pt
  semibold label are the three numbers the drawing gives, and none of them was
  expressible before.

  ## `padding: 0` is load-bearing

  The pill pads before it sizes, and its `padding` default is `:space_sm`. Left
  alone that token would be the fallback for the two edges this does not name,
  so a `height: 30` pill would measure 30 plus two paddings. Passing `padding: 0`
  makes the vertical fallback zero; the bridge's `hasEdge` arm then resolves
  top and bottom to `uniform ?: 0`, which is the same `Modifier.padding` call the
  hand-rolled `Row` produced with no vertical padding written at all.

  ## Why the pixels do not move

  The container changes from a `Row` to a `Box`, and both build the same
  modifier chain — `nodeModifier` is one function for every node type, so the
  background, the radius, the padding and the height are applied identically.
  What differs is how the container hugs and how its content is placed:

    * a `Row` hugs its width; a `Box` hugs only when told, and MishkaPill's root
      passes `fill_width={false}`, which fence K-17 now honours. Same width.
    * the `Row` centred its child with `verticalAlignment`; the `Box` centres it
      with `align: :center`. Same 30pt box, same centred label.
    * the label gains two wrappers — MishkaPill's body `Row`, and the empty
      `<Row />` that stands in for the ✕ when `with_remove` is false. Both hug,
      the empty one measures 0x0, and a `Row` given no `align` already defaults
      to `Alignment.CenterVertically` (`rowAlignProp`), so neither shifts
      anything.

  `max_lines: 1` is the component's own and matches what this passed: a Compose
  `Text` squeezed narrower than its content wraps character by character, and a
  pill that does not quite fit its row would render as a stack of letters.
  """
  def action_pill(label) do
    Kati.Components.MishkaPill.pill(
      label: label,
      background: 0xFFEFECE7,
      color: :on_surface,
      corner_radius: 15,
      height: 30,
      padding: 0,
      padding_left: 12,
      padding_right: 12,
      text_size: 11.5,
      font_weight: :semibold,
      align: :center
    )
  end

  @doc """
  A status pill: a 5pt dot, then the state in the dot's own colour.

  The same `Kati.Components.MishkaPill` container as `action_pill/1` — 24 tall,
  9 of side padding, radius 12 — but the content goes in as children rather than
  as `label`, because a pill has no leading slot and the dot has to come first.

  ## What that costs, and why it costs nothing on screen

  Content bypasses the pill's own typography props, so the label keeps its
  `text_size`, `font_weight` and colour here rather than being handed over. The
  three nodes are then wrapped in the component's own `Row`, one level deeper
  than the hand-rolled markup put them.

  That `Row` carries no `align`, and an absent `align` on a row is
  `Alignment.CenterVertically` (`rowAlignProp` in `MobBridge.kt` — top and
  bottom are the named cases, centre is the default), so it centres the 5pt dot
  against the label exactly as `align="center"` did. The dot then lands in the
  same place twice over: centred in a row that is itself centred in the 24pt
  pill is centred in the 24pt pill.

  A leading slot on MishkaPill would remove the nesting and let the label go
  through `label`/`text_size`/`font_weight`; it is the one thing this needs that
  the component does not have. Nothing renders differently for the want of it.
  """
  def status_pill(label, color, background) do
    Kati.Components.MishkaPill.pill(
      %{
        background: background,
        corner_radius: 12,
        height: 24,
        padding: 0,
        padding_left: 9,
        padding_right: 9,
        align: :center
      },
      status_content(label, color)
    )
  end

  # One root node per sigil, so the dot, the gap and the label are three of
  # them. They are handed over as a list, which the pill drops straight into its
  # content Row — wrapping them in a Row here would only add a level.
  defp status_content(label, color) do
    [
      ~MOB"<Box width={5} height={5} corner_radius={3} background={color} />",
      ~MOB"<Spacer size={5} />",
      ~MOB"""
      <Text text={label} text_size={10.5} font_weight="semibold" text_color={color} max_lines={1} />
      """
    ]
  end

  @doc """
  The footnote in a dashed frame.

  Solid, not dashed — see the moduledoc. The alpha and the 1.5pt width are the
  drawing's own, so the weight of the line is right even though its rhythm is
  not.
  """
  def note(icon, text) do
    ~MOB"""
    <Row
      fill_width={true}
      corner_radius={18}
      border_color={0x291A1917}
      border_width={1.5}
      padding={16}
      align="top"
    >
      {Kati.UI.symbol(icon, size: 18, color: 0xFF8A8479)}
      <Spacer size={11} />
      <Text text={text} text_size={12.5} line_height={1.55} text_color={0xFF5C574F} weight={1.0} />
    </Row>
    """
  end
end
