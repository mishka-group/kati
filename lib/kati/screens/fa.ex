defmodule Kati.Screens.Fa do
  @moduledoc """
  Shared chrome and type rules for the Persian mirrors, screens 55–62.

  ## Why these screens carry their own frame

  `Kati.Shell` reads the direction from `Kati.Locale`, and the bridge takes
  `layout_direction` from the **root node only** (`MainActivity.kt:245`). A
  Persian mirror rendered through the shell while the app is still set to
  English would draw Persian copy in a left-to-right grid — the one thing
  these eight drawings exist to disprove. So the frame here hard-codes `rtl`:
  the screen *is* the Persian one, whatever the setting says.

  Everything else about the dock is `Kati.Shell`'s dock, number for number.
  It mirrors for free — a `Row` lays out start-to-end, so the bar lands at the
  right, the FAB at the left, and home is the rightmost tab, which is exactly
  what 55, 56 and 57 draw. Nothing here reverses a list by hand.

  ## Two type rules, both forced by the fonts that ship

    * **Every Persian string needs `font_family="fa"`.** Plus Jakarta Sans —
      the default for an unstyled `Text` — has no Arabic-script glyphs at all
      (checked: `kati_sans_400.ttf` carries none of U+0600–U+06FF).

      This file used to finish that sentence *"so a Persian label without the
      prop is a row of empty boxes, not a fallback"*, and that was wrong.
      Photographed on the Pixel_9a: Compose falls through a `FontFamily` that
      lacks the glyph to the platform's own chain, so Android substitutes its
      system Arabic face and the label renders, shaped and joined and
      perfectly readable. The rule is unchanged and the reason is worse. A
      blank box is a bug anyone would file; Kati's Persian quietly set in
      somebody else's typeface, one paragraph at a time, next to paragraphs
      that are not, is a thing you can look straight at for a year.
      `Kati.PersianFontTest` is what says it out loud now, because nobody
      else was going to.

    * **Persian digits cannot go in the mono face.** The drawings ask for DM
      Mono on times, day numbers and episode numbers, and 58's own caption
      says the episode column "stays in the mono face with Persian digits".
      `kati_mono.ttf` contains **zero** of U+06F0–U+06F9; Vazirmatn carries
      all ten. So anything numeric that the design sets in mono is set here in
      `fa` at the design's size and colour. The face is wrong and the glyphs
      are right, which is the better half of an unwinnable trade — and it goes
      away the day the mono subset is regenerated with the Persian digits in
      it.

      Stated here since these screens were written, and disobeyed by four of
      them until `Kati.PersianFontTest` counted: `Kati.Screens.StatsFa`'s
      figures, `Kati.Screens.TodayFa`'s and `Kati.Screens.MealsMatrixFa`'s
      meal times and `Kati.Screens.YearShareFa`'s wordmark were all still
      asking mono for glyphs it does not have. A rule a module states about
      itself is not a rule the module keeps.

  The eyebrow is the same case one level up: the design's Latin eyebrow is DM
  Mono 10.5 at .16em, and the Persian one is **Vazirmatn 11 / 600 / no
  tracking** in all four drawings. `eyebrow/1` here is that recipe, not
  `Kati.UI.eyebrow/2` with a translated label.

  ## What that costs the vendored components, and it is most of them

  Both rules above are `font_family`, and **not one of the 77 components in
  `Kati.Components` accepts it** — re-checked by grep across the whole
  directory this round: `grep -rl font_family lib/kati/components/` returns
  nothing at all. Every one of them that renders a label builds the `Text`
  itself and leaves the prop off, and `MobBridge.kt:4222` is explicit about
  what that means: *"No prop means body text, and body text is Plus Jakarta
  Sans. This is the case that matters: it is every unstyled Text in the app."*

  `kati_sans_400.ttf` carries **zero** code points in U+0600-U+06FF — parsed
  out of its `cmap`, against 142 in `kati_fa_400.ttf`. So a Persian label
  handed to a Chelekom component is not degraded, it is *absent*: a row of
  blank boxes. That is the single reason the Persian screens adopt so little
  of the set. It is not an RTL failure — direction is a container attribute and
  the components inherit it correctly — it is a typography failure.

  ## The content slot is the way round it, where a component has one

  A component that builds its own `Text` cannot draw Persian. A component that
  takes the label as **children** can, because the caller builds the `Text` and
  puts `font_family="fa"` on it. Four of them do:
  `MishkaThemeIcon` (children are the icon), `MishkaActionIcon` (children
  override `icon`), `MishkaPill` and `MishkaToggle` (children replace `label`).
  Every adoption on these eight screens goes through that door.

  The three that would matter most here have no such door — `MishkaChip`'s
  `expand/3` discards its children outright, `MishkaSegmentedControl` says in
  as many words that "the label is a prop rather than the slot's children
  because the control paints it", and `MishkaNavLink` takes `label` and
  `description` as strings. That is the single upstream ask from this pass, and
  it is smaller than `font_family` on 77 components: give the three a content
  slot their siblings already have.

  ## What these screens adopt

  Text-free, so the font rule never bites:

    * `MishkaThemeIcon` — every icon tile and state ring: `tab/1` here,
      `Kati.Screens.SettingsFa.leading/1`, `Kati.Screens.SeriesFa.check/1`,
      `Kati.Screens.TodayFa`'s three meal-card rings.
    * `MishkaActionIcon` — every header disc: `disc/2` here (so 55, 56, 57, 59,
      60, 61 and 62 at once) and `Kati.Screens.SeriesFa.more/0` and its
      bookmark.
    * `MishkaAvatar` — `Kati.Screens.SettingsFa.avatar/1`.
    * `MishkaSeparator` with `render: :box` — every hairline in a card:
      `Kati.Screens.SettingsFa.hairline/1`, `Kati.Screens.MealsMatrixFa`'s row
      rule and legend rule.
    * `MishkaScrollArea` — `Kati.Screens.LibraryFa.chips/1`.

  `MishkaThemeIcon` also carries the one *labelled* adoption on these screens,
  `Kati.Screens.SettingsFa.leading/1`'s فا badge tile, and it carries it only
  because the badge goes in as a child `Text` this file's own rules wrote.
  """

  import Mob.Sigil

  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaThemeIcon
  alias Kati.Theme.Palette

  # The four roots, in the order the bar draws them. All four are Persian: the
  # آمار tab stood in with `Kati.Screens.Stats` while drawing 61 was unbuilt,
  # on the reasoning that a tab going nowhere reads as a broken bar. 61 has
  # landed, so the stand-in is gone — it was the one tab that changed the
  # app's language out from under the reader, and RTL with it.
  @roots [
    %{id: :home, icon: "home", screen: Kati.Screens.HomeFa},
    %{id: :calendar, icon: "calendar_month", screen: Kati.Screens.ScheduleFa},
    %{id: :library, icon: "grid_view", screen: Kati.Screens.LibraryFa},
    %{id: :stats, icon: "bar_chart_4_bars", screen: Kati.Screens.StatsFa}
  ]

  @doc "The four roots of the Persian shell."
  def roots, do: @roots

  @doc """
  The Persian root frame: content, the 120pt fade, then the dock — all inside
  a root `Box` that declares `rtl`.
  """
  def frame(active, content, screen \\ nil) do
    ~MOB"""
    <Box
      fill_width={true}
      fill_height={true}
      background={:background}
      layout_direction="rtl"
      accessibility_id={screen}
    >
      {content}
      <Box fill_width={true} fill_height={true} align="bottom">
        {Kati.UI.paper_fade(120, 42)}
      </Box>
      {Kati.Screens.Fa.dock(active)}
    </Box>
    """
  end

  @doc """
  The pushed Persian frame: no dock, no fade, just the direction.

  A pushed mirror draws its own dismissal — 58 floats a back pill over its
  artwork — so unlike `Kati.Screens.Pushed` this adds nothing but the root
  node.
  """
  def pushed_frame(content, screen \\ nil) do
    ~MOB"""
    <Box
      fill_width={true}
      fill_height={true}
      background={:background}
      layout_direction="rtl"
      accessibility_id={screen}
    >
      {content}
    </Box>
    """
  end

  @doc false
  def dock(active) do
    add = {self(), :fab}

    # `dock_fill` here, where `Kati.Shell` uses `Kati.Theme.chrome_fill/1`, and
    # the difference is not an oversight on either side: this dock was drawn at
    # the design's own .90 (`0xE6`) and the shell's at the .97 that stands in for
    # a backdrop blur Mob cannot do. Both light values are kept exactly as they
    # were; `dock_fill`'s dark alpha (.92) is drawn on screen 28.
    fill = Palette.dock_fill()
    fab = Palette.fab_fill()
    glyph = Palette.fab_glyph()

    ~MOB"""
    <Box fill_width={true} fill_height={true} align="bottom">
      <Row fill_width={true} align="center" padding_left={18} padding_right={18} padding_bottom={30}>
        <Box weight={1.0} height={64} background={fill} corner_radius={32} align="center">
          <Row fill_width={true} fill_height={true} align="center">
            {Enum.map(Kati.Screens.Fa.roots(), fn root -> Kati.Screens.Fa.tab(root, active) end)}
          </Row>
        </Box>
        <Spacer size={11} />
        <Box width={64} height={64} background={fab} corner_radius={32} align="center" on_tap={add}>
          {Kati.UI.symbol("add", size: 27, color: glyph)}
        </Box>
      </Row>
    </Box>
    """
  end

  # The 46pt disc under a tab's glyph is `Kati.Components.MishkaThemeIcon` —
  # "a themed container around exactly one icon" is the component's own first
  # line, and this is that and nothing else.
  #
  # It is node-identical, not merely equivalent. Without an `id` the component
  # emits no test markers (`markers(nil, …)` returns the icon untouched), so
  # `theme_icon/2` builds
  #
  #     %{type: :box,
  #       props: %{width: 46, height: 46, align: :center,
  #                corner_radius: 23, background: disc},
  #       children: [symbol]}
  #
  # against the sigil's `%{type: :box, props: %{width: 46, height: 46,
  # corner_radius: 23, background: disc, align: "center"}, children: [symbol]}`.
  # The one difference is `align`, and `:json.encode/1` renders the atom
  # `:center` as the string `"center"` — which is what `boxAlignProp`
  # (`MobBridge.kt:4298`) matches on, `props["align"] as? String`.
  #
  # The inactive disc's transparent fill survives: `put_some/3` drops `nil` and
  # `false`, not a transparent colour, so the key is on the node either way.
  # `Palette.transparent/0` is `0x00FFFFFF` in both modes, so that stays true.
  # `variant: :filled` picks a glyph colour from the fill's luminance, and that
  # value is discarded here — the child `Text` carries `Kati.UI.symbol/2`'s own
  # tint, which is the whole reason the glyph is a child rather than `icon`.
  @doc false
  def tab(root, active) do
    on? = root.id == active
    # Same four tokens as `Kati.Shell.tab/3`, and for the same reasons — the
    # active well is `tab_well`, not `paper`: in dark it is DARKER than the page
    # so it still reads as a hole punched in the bar.
    tint = if on?, do: Palette.ink(), else: Palette.tertiary()
    disc = if on?, do: Palette.tab_well(), else: Palette.transparent()
    tap = {self(), String.to_atom("root_#{root.id}")}

    glyph =
      MishkaThemeIcon.theme_icon(
        %{variant: :filled, color: disc, size: 46, radius: 23},
        [Kati.UI.symbol(root.icon, size: 22, color: tint, fill: on?)]
      )

    ~MOB"""
    <Box weight={1.0} align="center" on_tap={tap}>
      {glyph}
    </Box>
    """
  end

  @doc """
  A section label in Persian: the same 13x2 accent dash, then Vazirmatn 11 at
  600 in `#A0998F`. No uppercasing — the Arabic script has no case — and no
  tracking, which the drawings set to 0 on every Persian line.
  """
  def eyebrow(label) do
    dash = Palette.accent()
    label_color = Palette.eyebrow()

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        <Box width={13} height={2} corner_radius={1} background={dash} />
        <Spacer size={9} />
        <Text
          text={label}
          font_family="fa"
          font_weight="semibold"
          text_size={11}
          text_color={label_color}
        />
      </Row>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc """
  `Kati.UI.Eyebrow.quiet/1`'s eyebrow, in Persian.

  Not the Latin one with the family swapped, for the same two reasons
  `eyebrow/1` gives: `String.upcase/1` is a no-op on a script with no case,
  and DM Mono's 10.5 at .16em is a Latin small-caps effect that sets Persian
  letters adrift from each other. Vazirmatn 11/600 with no tracking, which is
  what all four Persian drawings measure.

  The dash is `rail_idle` rather than `accent`, which is the whole difference
  between this and `eyebrow/1`: it is the drawing saying *present, but not
  now* about a section, in the same grey the timeline rail uses to say it
  about an hour.
  """
  @spec quiet_eyebrow(String.t()) :: map()
  def quiet_eyebrow(label) do
    dash = Palette.rail_idle()
    label_color = Palette.eyebrow()

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        <Box width={13} height={2} corner_radius={1} background={dash} />
        <Spacer size={9} />
        <Text
          text={label}
          font_family="fa"
          font_weight="semibold"
          text_size={11}
          text_color={label_color}
        />
      </Row>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc """
  `Kati.UI.SettingsList.note/2`'s dashed aside, typeset in Persian.

  The Latin one cannot be reused, and the reason is the whole subject of this
  module's second section: the pill hands its paragraph to a `Text` it builds
  itself, with no `font_family`, so a Persian note drawn through it asks Plus
  Jakarta Sans for glyphs that face does not contain. `Kati.PersianFontTest`
  is what now says so out loud.

  Same numbers as the Latin note — 18pt radius, 1.5pt dashed border, 16pt
  padding, an 18pt leading glyph 11pt from the text — because the difference
  between the two is the face and nothing else.
  """
  @spec note(String.t(), String.t()) :: map()
  def note(icon, text) do
    Kati.Components.MishkaPill.pill(
      %{
        background: :none,
        corner_radius: 18,
        border_color: Palette.border(),
        border_width: 1.5,
        padding: 16,
        fill_width: true,
        content_align: :top,
        content_fill_width: true,
        leading: Kati.UI.symbol(icon, size: 18, color: Palette.sub()),
        leading_gap: 11
      },
      [note_text(text)]
    )
  end

  defp note_text(text) do
    ~MOB"""
    <Text
      text={text}
      font_family="fa"
      text_size={12.5}
      line_height={1.55}
      text_color={Palette.ink_soft()}
      weight={1.0}
    />
    """
  end

  @doc """
  A 44pt header disc: card white, the button shadow, a 21pt symbol.

  `Kati.Components.MishkaActionIcon`, which is exactly this — a square tap
  target holding a glyph, with `:circle` resolving to an exact `size / 2`, so
  44 rounds at 22.0 and `corner_radius` is a `floatProp` either way
  (`MobBridge.kt:3887`).

  **This is what `shadow` unblocked.** The prop was the whole reason this disc
  was hand-drawn: a floating disc is *defined* by `Kati.Theme.shadow_button/0`,
  and until this round no component in the vendored set took a shadow at all.
  It now rides on the container — the node that already carries the fill, the
  radius and the tap — so the drawn result is the node this function replaced
  plus one bare `Row` around the glyph, which has no size, no background and no
  padding of its own. That wrapper is not a new risk: `MishkaActionIcon` with a
  symbol child is what `Kati.Screens.SeriesFa.more/0` has been rendering
  against the captured frames since the last pass.

  `tag` defaults to `nil`, and `Kati.Components.Event.handler/1` maps `nil` to
  no handler at all rather than to a registered `{pid, nil}` — so `disc/1` is
  the same disc with nothing wired, which is what screens 59, 60, 61 and 62
  draw beside their back pills. Before this, each of those four spelled the
  same seven props out inline.
  """
  def disc(icon, tag \\ nil) do
    MishkaActionIcon.action_icon(
      %{
        size: 44,
        shape: :circle,
        variant: :filled,
        # The doc above calls this "card white", so it is the `card` token and
        # not one of the other three meanings of `0xFFFBFAF8` — the disc is a
        # surface that floats, not a mark burnt onto one.
        background: Kati.Theme.card(Palette.mode()),
        shadow: Kati.Theme.shadow_button(),
        on_tap: tag
      },
      [Kati.UI.symbol(icon, size: 21)]
    )
  end

  @doc """
  The dock's taps, for any Persian root.

  A screen matches its own tags first and sends the rest here, so the four
  tabs and the FAB are written once. Anything unrecognised leaves the screen
  as it was rather than raising in a tap handler, which Mob does not catch.
  """
  def dock_tap(:fab, _active, socket) do
    {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.AddTitle)}
  end

  def dock_tap(tag, active, socket) when is_atom(tag) do
    case Atom.to_string(tag) do
      "root_" <> id ->
        target = Enum.find(@roots, &(Atom.to_string(&1.id) == id))

        cond do
          target == nil -> {:noreply, socket}
          target.id == active -> {:noreply, socket}
          true -> {:noreply, Mob.Socket.reset_to(socket, target.screen)}
        end

      _ ->
        {:noreply, socket}
    end
  end

  def dock_tap(_tag, _active, socket), do: {:noreply, socket}
end
