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

  ## Two departures from the drawing, both bridge limits

    * **The switch is hand-built.** `Kati.Components.MishkaSwitch` wraps Mob's
      `Toggle`, which paints Compose's own Material `Switch` at Material's own
      metrics. The design draws a 46x28 track at radius 14 with a 22pt thumb
      and an ink "on" state; no prop reshapes a `Switch` into that, and the
      port's own docs note the colour props are ignored on iOS anyway.
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

  @doc "A 44pt floating disc carrying one symbol."
  def disc(icon) do
    ~MOB"""
    <Box
      width={44}
      height={44}
      corner_radius={22}
      background={0xFFFBFAF8}
      shadow={Kati.Theme.shadow_button()}
      align="center"
    >
      {Kati.UI.symbol(icon, size: 21)}
    </Box>
    """
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

  @doc false
  def hairline(false), do: ~MOB"<Spacer size={0} />"
  def hairline(true), do: ~MOB"<Box fill_width={true} height={1} background={0x121A1917} />"

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

  @doc "The small paper button a row carries instead of a switch."
  def action_pill(label) do
    ~MOB"""
    <Row height={30} corner_radius={15} background={0xFFEFECE7} padding_left={12} padding_right={12} align="center">
      <Text text={label} text_size={11.5} font_weight="semibold" text_color={:on_surface} max_lines={1} />
    </Row>
    """
  end

  @doc "A status pill: a 5pt dot, then the state in the dot's own colour."
  def status_pill(label, color, background) do
    ~MOB"""
    <Row height={24} corner_radius={12} background={background} padding_left={9} padding_right={9} align="center">
      <Box width={5} height={5} corner_radius={3} background={color} />
      <Spacer size={5} />
      <Text text={label} text_size={10.5} font_weight="semibold" text_color={color} max_lines={1} />
    </Row>
    """
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
