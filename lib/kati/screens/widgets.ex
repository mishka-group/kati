defmodule Kati.Screens.Widgets do
  @moduledoc """
  Screen 39 — Widgets, Shortcuts & share, pushed under Settings.

  Built to `test/design/screens/39.html`: the parts of the app used
  without opening it. Three square widget previews at the top, a wide one
  underneath, the voice shortcuts as a switch list, and the share extension
  described in a card.

  The previews are drawn, not screenshotted — they are the real widget
  layouts at widget scale, which is the only way this screen can be checked
  against the drawing.

  Two literal details worth keeping:

    * the eyebrow above **Share sheet** has a `#C4BDB3` dash rather than the
      accent one, because that section is descriptive rather than actionable.
      `Kati.UI.eyebrow/2` takes a `dash:` option — this bullet used to say it
      always drew the accent one, and that stopped being true — so what keeps
      `quiet_eyebrow/1` here is the rest of the node rather than the colour:
      the helper adds a weighted `Spacer` and a trailing slot and closes on a
      `Box`, where this pins its label to `max_lines={1}` and closes on a
      `Spacer`. Everything here that is NOT the dash now follows the helper
      exactly, which is the collapse `Kati.Screens.Account.quiet_eyebrow/1`
      made on the same node;
    * the widget captions (`UP NEXT`, `TONIGHT`, `STREAK`, `TODAY · WIDE`) are
      capitals in the drawing's own copy, not `text-transform`, so they are
      capitals in the data.

  The three shortcut switches are live; the widget previews above them are
  not, and that is deliberate. The eyebrow says **Sizes**, but the drawing
  shows previews rather than a picker: none of the four is drawn selected and
  the three squares carry three different fills, so a selected state would have
  to be invented and the resting frame would move. They stay pictures of
  widgets, which is what they are.

  No dock, so the frame's bottom inset is 40 rather than 132.

  ## The one colour here that is still a literal

  Every other colour on this screen is a `Kati.Theme.Palette` token. The
  TONIGHT tile's caption is not: the drawing sets it in `#6A6560` on the ink
  tile, and `#6A6560` exists in the palette only as a **dark** value — it is
  what `muted`, `tertiary` and `segment_idle` all collapse to on near-black —
  and never as a light one. So no token resolves to it in light, and giving it
  the nearest one (`on_ink_muted`, `#BFB8AC`) would change a baseline frame to
  make dark mode work. It stays `0xFF6A6560` until the table names it; see
  `sizes/1`.

  It happens to land well on the inverted tile anyway — `#6A6560` on
  `ink_fill`'s `#F7EFE4` reads at about 5.5:1 — so the tile is legible in dark
  rather than merely unbroken.

  ## Audited: drawn copy — the tiles are pictures of widgets, not widgets

  **Every value the four tiles draw is `Kati.Widgets.Sample`'s, and it stays
  that way** — the page's own chrome is this file's, and the section below
  draws that line. The eyebrow says **Sizes** and the export's own caption says
  *"four widget sizes off one data model"*: what is being shown is the same
  content at four scales, which is a claim about layout rather than about this
  user's evening.

  Three of the four could be read today — `Long Hollow · S2E6` is the hero
  `Kati.Screens.UpNext.queue/0` already assembles from `Kati.Media`, and
  `20:00 · 6 episodes air` is `Kati.Calendars.Today`, which screens 01 and 02
  read. **STREAK · 11 nights cannot**, and that is what decides it: nothing
  anywhere records that a habit was kept — `Kati.Calendars.Override.kind` is
  `:modified | :cancelled`, so an occurrence can be called off and cannot be
  ticked — which is why `Kati.Screens.Habits` is on its Sample outright. Making
  three tiles live would leave one permanently invented sitting in the same row,
  which is the mixture `Kati.Screens.Film` refuses: either every value is this
  user's or every value is the drawing's. The set moves when a habit completion
  exists to count.

  The **shortcut switches** flip locally and are stored nowhere, honestly:
  there is no voice layer in `lib/` at all, so *"Hey Siri, what's next?"* is
  describing a surface Kati does not yet have rather than a setting it keeps.
  A stored boolean would arm nothing.

  ## Which half of the copy this file owns, after the fold

  mishka-group/kati#103 folded the 33 Persian mirrors away, so this module is
  board 39 in both languages and every word it writes has to come from
  `Kati.Gettext`. Two modules hold the words on this page and only one of them
  is this one — `Kati.Screens.AutoDetect` says the same thing about board 36
  and its Sample, for the same reason.

  **This file owns the chrome**: the 28pt title, the mono line under it, and
  the three section labels — *Sizes*, *Shortcuts*, *Share sheet*. Those are
  literals at these call sites, so they are the msgids this file carries, and
  *Widgets* is deliberately the msgid `Kati.Settings.Sample` already holds for
  the row that pushes here — ابزارک‌ها — so the row a reader taps and the
  heading they land on are the same word rather than two translations of it.

  The back pill's *Settings* is a literal here too and is **not** wrapped: it
  lands in `@back_label` on the way through `use Kati.Screens.Pushed`, and
  `gettext/1` inside a module attribute is evaluated at COMPILE time and frozen
  in whichever locale the compiler happened to be in.
  `Kati.Screens.Pushed.back_vocabulary/0` is what keeps that msgid alive for
  the extractor, and `back_label/2` looks it up at runtime.

  **`Kati.Widgets.Sample` owns the drawing**, and its words are still English
  literals: the four captions (`UP NEXT`, `TONIGHT`, `STREAK`, `TODAY · WIDE`),
  *Long Hollow* and its `S2E6`, both count lines, the wide widget's two events,
  the four shortcut rows with their spoken phrases, and the share card's three
  strings. Those belong to that module the way `Kati.Settings.DetectSample`'s
  rows belong to it, and the split is the one `Kati.Screens.NumberingScheme`
  states for its own fixture: one msgid per string, wherever the string lives.
  A `gettext/1` here could not reach them anyway — its argument has to be a
  literal at the call site for `mix gettext.extract` to see a msgid at all, and
  what this file holds is a map key — and a screen that made its own copy of a
  fixture's copy would be two strings to keep in step.

  What this file DOES owe those strings is the typesetting, which is why the
  mechanical half of the fold is all on this side of the line:

    * every mono slot the fixture fills asks `Kati.Locale.mono_face/1` about
      the run it was handed rather than naming `mono` outright.
      `kati_mono.ttf` carries no glyph in U+0600–U+06FF, so the moment the
      Sample says «امشب» that line is handed to Android's own substitute face,
      beside Kati's. Deciding by the STRING's script rather than the reader's
      is what keeps `S2E6` — an episode code, not copy — in DM Mono in both
      scripts, exactly as screen 80's provider names stay;
    * the two tile counts and the wide widget's two clocks go through
      `Kati.Locale.number/1`, so a Persian reader is given ۶, ۱۱ and ۲۰:۰۰
      rather than Latin numerals under a Persian heading. `Kati.Music.Sample`
      writes its track durations the same way, and `mono_face/1` then answers
      `fa` for the converted run, which is where those digits exist;
    * every `letter_spacing` is `Kati.Locale.tracking/1`. Arabic script has no
      tracking tradition and a negative em pulls the letters out of their
      joins — the one typographic setting that does not merely look wrong in
      the script but stops the word being one word;
    * the share card's paragraph takes `Kati.Locale.leading/1`, because 1.55
      was measured against Plus Jakarta's metrics and Vazirmatn's are not
      those;
    * the Automations row's chevron is `Kati.Locale.forward_chevron/0`. It
      points the way the reader is going, and Material Symbols are text in a
      font: they auto-mirror nothing unless asked.
  """
  # `back: "Settings"` stays the English word and is translated at RUNTIME by
  # `Kati.Screens.Pushed` — see the moduledoc: the label lands in a module
  # attribute on the way, where a `gettext/1` would freeze at compile time.
  use Kati.Screens.Pushed, back: "Settings"
  use Gettext, backend: Kati.Gettext

  alias Kati.Components.MishkaSeparator
  alias Kati.Components.MishkaSwitch
  alias Kati.Components.MishkaThemeIcon
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.Widgets.Sample

  @impl true
  def load(socket) do
    Mob.Socket.assign(socket, :widgets, %{
      up_next: Kati.Screens.Widgets.up_next_now(),
      share: Sample.share()
    })
  end

  @doc """
  The shipped widget's own content, or `nil` when nothing is queued.

  Board 39 drew four tiles at four sizes from `Kati.Widgets.Sample` — UP NEXT,
  TONIGHT, STREAK and a wide one — and the file argued all-or-nothing: STREAK
  could not be real, because nothing records that a habit was kept, so none of
  them were.

  That argument expired when a real widget shipped. There is exactly one, it is
  the UP NEXT one, and it reads `Kati.Screens.UpNext.queue/0` through
  `Kati.Widgets.Snapshot` — the same hero, off the same function. So the page
  shows that, and the three tiles with nothing behind them are gone rather than
  drawn: a picture of three widgets nobody can add is worse than one preview of
  the widget they can.
  """
  @spec up_next_now() :: map() | nil
  def up_next_now do
    case Kati.Screens.UpNext.queue() do
      %{hero: %{} = hero} ->
        %{
          label: pgettext("a home-screen widget's own name", "UP NEXT"),
          seed: Map.get(hero, :seed),
          title: hero.title,
          episode: hero.meta
        }

      _nothing ->
        nil
    end
  end

  @doc false
  def content(assigns) do
    w = assigns.widgets

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {Kati.Screens.Widgets.header()}
        {Kati.Screens.Widgets.title()}
        {UI.eyebrow(gettext("On your home screen"))}
        {Kati.Screens.Widgets.preview(w.up_next)}
        {Kati.Screens.Widgets.quiet_eyebrow(gettext("Share sheet"))}
        {Kati.Screens.Widgets.share(w)}
      </Column>
    </Scroll>
    """
  end

  # 44pt reserves the row the back pill floats in — the pill is drawn by
  # Kati.Screens.Pushed — so the overflow disc sits opposite it.
  @doc false
  def header do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} height={44} align="center">
        <Spacer weight={1.0} />
        {Kati.Screens.Widgets.disc("more_horiz")}
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  The 44pt floating disc the header hangs opposite the back pill.

  `Kati.Components.MishkaThemeIcon` is documented as "a themed container around
  exactly one icon", which is precisely what this is — and it could not be one
  until the container took a `shadow`. That is the whole difference here: a disc
  is *defined* by floating. `variant: :filled` paints `#FBFAF8` and stops, which
  on this screen's `#F2EFEA` paper reads as a pale patch rather than as a button
  above it, so before `shadow` existed this had to stay hand-rolled markup.

  ## Why the pixels do not move

  With children and no `id`, `theme_icon/2` returns

      %{type: :box,
        props: %{width: 44, height: 44, align: :center, corner_radius: 22,
                 background: Palette.card(), shadow: Kati.Theme.shadow_button()},
        children: [glyph]}

  — the same seven keys, with the same seven values, that the `<Box>` above it
  carried. `align: :center` and `align="center"` reach the bridge as the same
  string: `align` is in none of the renderer's token whitelists, so an
  unrecognised atom passes through and `:json.encode/1` writes an atom as its
  own name.

  Nothing else in the component runs. `:filled` contributes no gradient layer;
  `skin(:filled, …)` proposes no border, so `put_some/3` drops both
  `border_color` and `border_width` rather than writing nils; the id markers are
  skipped without an `id`; and the `icon` shorthand is skipped when children are
  given — which is also why the glyph goes in as a child. That shorthand builds
  a `Text` with no `font_family`, so the Material Symbols ligature
  `"more_horiz"` would be typeset as the word instead of resolved to the glyph.

  `Kati.UI.SettingsList.disc/1` is the same call, and both now spell the colour
  `Kati.Theme.Palette.card/0` — the card token, not `on_ink`, `fab_glyph` or
  `on_media`, which are the other three meanings of `0xFFFBFAF8`. A disc is a
  surface that floats above the page, so it follows the ground: `#1E1D1B` in
  dark, like every card.
  """
  def disc(icon) do
    MishkaThemeIcon.theme_icon(
      %{
        variant: :filled,
        color: Palette.card(),
        size: 44,
        radius: 22,
        shadow: Kati.Theme.shadow_button()
      },
      [Kati.UI.symbol(icon, size: 21)]
    )
  end

  @doc """
  The page's own title, and the mono line under it.

  `gettext("Widgets")` is deliberately the msgid `Kati.Settings.Sample` already
  carries for the settings row that pushes here — ابزارک‌ها — so the row a
  reader taps and the heading they land on are the same word rather than two
  translations of it.

  Three things moved and none of them moves for an English reader:

    * `Kati.Locale.tracking/1`, because -0.03em pulls Persian letters out of
      their joins — the one typographic setting that does not merely look
      wrong in the Arabic script but stops the word being one word;
    * `max_lines={1}`, which this display heading had none of. A 28pt title
      handed a longer word should truncate rather than wrap a second line down
      into the first row of widget tiles, which are `aspect_ratio`-measured and
      would be pushed whole;
    * `Kati.Locale.mono_face/0` for the strap, since `kati_mono.ttf` has no
      Persian glyph at all. The arity-0 form and not `mono_face/1`: this line
      is product copy in the reader's own script, never a provider's ASCII
      name.
  """
  def title do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={gettext("Widgets")}
        text_size={28}
        max_font_scale={1.6}
        font_weight="bold"
        letter_spacing={Kati.Locale.tracking(-0.03)}
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer size={5} />
      <Text
        text={gettext("add to home screen")}
        font_family={Kati.Locale.mono_face()}
        text_size={11}
        text_color={Palette.muted()}
        max_lines={1}
      />
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  The muted eyebrow: the design's `#C4BDB3` dash instead of the accent.

  This page draws three section labels — two accent, one muted — and only the
  dash is supposed to tell the kinds apart. So everything here that is not the
  dash now follows `Kati.UI.eyebrow/1` exactly, and every one of those calls
  answers the value this wrote by hand when the reader is English:

    * `Kati.UI.eyebrow_label/1` in place of `String.upcase/1`. Persian has no
      letter case, so upcasing a Persian label is a no-op — one that still
      *reads* as one beside the two accent eyebrows above it, which is why the
      call has to be the shared one rather than a conditional here;
    * `Kati.Locale.mono_face/0`, since `kati_mono.ttf` has no Persian glyph.
      The arity-0 form and not `mono_face/1`, matching `Kati.UI.eyebrow/1`:
      the one label this screen passes is product copy in the reader's own
      script, never a provider's ASCII name;
    * Vazirmatn at 11/semibold rather than DM Mono at 10.5/normal, which is
      what the mirrored boards drew — the Persian face reads thin at an eyebrow
      size that suits DM Mono;
    * no tracking at all under `:fa`. 0.16em between Persian letters breaks the
      joins that make them one word.
  """
  def quiet_eyebrow(label) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        <Box width={13} height={2} corner_radius={1} background={Palette.rail_idle()} />
        <Spacer size={9} />
        <Text
          text={Kati.UI.eyebrow_label(label)}
          font_family={Kati.Locale.mono_face()}
          text_size={Kati.Locale.pick(10.5, 11)}
          font_weight={Kati.Locale.pick("normal", "semibold")}
          letter_spacing={Kati.Locale.tracking(0.16)}
          text_color={Palette.eyebrow()}
          max_lines={1}
        />
      </Row>
      <Spacer size={11} />
    </Column>
    """
  end

  # Three squares. The drawing writes them `flex:1; aspect-ratio:1`, and 113
  # was only ever what that resolved to on the 402dp frame: (360 - 22) / 3 =
  # 112.67. On a 411dp device the weights make each tile 115.67 wide while the
  # declared height stayed 113, so the "squares" were 3dp out and the up-next
  # tile's content — 13 + label + 42 + 7 + title + 2 + episode + 13 — had
  # already outgrown the box it was pinned to. The tiles carry
  # `aspect_ratio={1.0}` instead: the height follows the width the weight
  # actually hands out, at any frame. See `up_next_tile/1`.
  @doc false
  def sizes(w) do
    # The ink tile is an ink-filled surface carrying an `on_ink` number, so it
    # takes screen 28's drawn pair: `ink_fill` under `on_ink`. The cream tile
    # stays in the cream family, headline included — `cream_ink`, not `ink`,
    # because `0xFF1A1917` on cream is the headline meaning of that literal.
    tonight =
      Kati.Screens.Widgets.count_tile(
        w.tonight,
        Palette.ink_fill(),
        # Still a literal, and it has to be: `0xFF6A6560` appears in
        # `Kati.Theme.Palette` only as a DARK value (`muted`, `tertiary`,
        # `segment_idle`), never as a light one, so no token resolves to it in
        # light and naming one would move a baseline frame. See the moduledoc.
        0xFF6A6560,
        Palette.on_ink(),
        Palette.on_ink_meta()
      )

    streak =
      Kati.Screens.Widgets.count_tile(
        w.streak,
        Palette.cream(),
        Palette.cream_meta(),
        Palette.cream_ink(),
        Palette.cream_sub()
      )

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {Kati.Screens.Widgets.up_next_tile(w.up_next)}
        <Spacer size={11} />
        {tonight}
        <Spacer size={11} />
        {streak}
      </Row>
      <Spacer size={14} />
    </Column>
    """
  end

  # `aspect_ratio` rather than a declared height, and the height has to stay
  # bounded somehow: `fill_height` on the inner Column and the `Spacer
  # weight={1.0}` below it are what produce the drawing's
  # `justify-content:space-between`, and both collapse to nothing the moment
  # the tile wraps its content. The modifier chain is weight → aspect_ratio,
  # so the square is measured off the width the Row actually granted.
  #
  # Both mono slots ask `Kati.Locale.mono_face/1` about the STRING rather than
  # about the reader: `S2E6` is an episode code and stays in DM Mono in both
  # scripts, where the caption becomes Vazirmatn the day `Kati.Widgets.Sample`
  # says بعدی — DM Mono has no glyph in that block at all.
  @doc """
  The one shipped widget, previewed at its own size — or nothing queued.

  A single tile where the board drew a row of four. The other three were
  TONIGHT, STREAK and a wide variant, none of which exists as a widget a reader
  can add, so drawing them promised three things the launcher has not got.
  """
  def preview(nil) do
    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={16}
    >
      <Text
        text={gettext("Nothing queued yet")}
        text_size={15}
        font_weight="bold"
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer size={4} />
      <Text
        text={
          gettext(
            "Start something on your shelf and the widget shows it, here and on your home screen."
          )
        }
        text_size={13}
        line_height={Kati.Locale.leading(1.4)}
        text_color={Palette.muted()}
      />
      <Spacer size={14} />
    </Column>
    """
  end

  def preview(tile) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {Kati.Screens.Widgets.up_next_tile(tile)}
        <Spacer weight={2.0} />
      </Row>
      <Spacer size={14} />
    </Column>
    """
  end

  @doc false
  def up_next_tile(tile) do
    ~MOB"""
    <Box
      weight={1.0}
      aspect_ratio={1.0}
      corner_radius={20}
      background={Palette.card()}
      shadow={Kati.Theme.shadow_card_soft()}
    >
      <Column fill_width={true} fill_height={true} padding={13}>
        <Text
          text={tile.label}
          font_family={Kati.Locale.mono_face(tile.label)}
          text_size={9}
          letter_spacing={Kati.Locale.tracking(0.14)}
          text_color={Palette.eyebrow()}
          max_lines={1}
        />
        <Spacer weight={1.0} />
        {Kati.Screens.Widgets.mini_poster(tile)}
        <Spacer size={7} />
        <Text
          text={tile.title}
          text_size={11}
          font_weight="bold"
          text_color={:on_surface}
          max_lines={1}
        />
        <Spacer size={2} />
        <Text
          text={tile.episode}
          font_family={Kati.Locale.mono_face(tile.episode)}
          text_size={9}
          text_color={Palette.muted()}
          max_lines={1}
        />
      </Column>
    </Box>
    """
  end

  @doc false
  def mini_poster(tile) do
    case Kati.Design.Images.poster(tile.seed) do
      nil ->
        ~MOB"<Box width={30} height={42} corner_radius={5} background={Palette.placeholder()} />"

      src ->
        ~MOB"""
        <Image src={src} width={30} height={42} corner_radius={5} content_mode="fill" />
        """
    end
  end

  # The two numeric tiles differ only in their four colours, so they share one
  # function rather than being copied — the drawing's own structure.
  @doc false
  def count_tile(tile, background, label_color, number_color, line_color) do
    # The figure is the one thing on this tile a Persian reader must not be
    # shown in Latin: 6 and 11 are quantities in a sentence the tile makes with
    # its line under them, not a code. `Kati.Locale.number/1`'s caveat about
    # keeping Latin digits is about a figure the design sets in DM MONO — this
    # one carries no `font_family` and is drawn in the reader's own face, which
    # has ۶ and ۱۱. `Kati.Screens.Goals` converts its Sample's progress the
    # same way.
    count = Kati.Locale.number(tile.count)

    ~MOB"""
    <Box
      weight={1.0}
      aspect_ratio={1.0}
      corner_radius={20}
      background={background}
      shadow={Kati.Theme.shadow_card_soft()}
    >
      <Column fill_width={true} fill_height={true} padding={13}>
        <Text
          text={tile.label}
          font_family={Kati.Locale.mono_face(tile.label)}
          text_size={9}
          letter_spacing={Kati.Locale.tracking(0.14)}
          text_color={label_color}
          max_lines={1}
        />
        <Spacer weight={1.0} />
        <Text
          text={count}
          text_size={34}
          font_weight="extrabold"
          letter_spacing={Kati.Locale.tracking(-0.04)}
          text_color={number_color}
          max_lines={1}
        />
        <Spacer size={2} />
        <Text text={tile.line} text_size={10} text_color={line_color} max_lines={1} />
      </Column>
    </Box>
    """
  end

  @doc false
  def wide(w) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={15}
      >
        <Row fill_width={true} align="center">
          <Text
            text={w.today_label}
            font_family={Kati.Locale.mono_face(w.today_label)}
            text_size={9}
            letter_spacing={Kati.Locale.tracking(0.14)}
            text_color={Palette.eyebrow()}
            max_lines={1}
          />
          <Spacer weight={1.0} />
          {Kati.UI.symbol("calendar_month", size: 14, color: Palette.rail_idle())}
        </Row>
        <Spacer size={12} />
        <Row fill_width={true} align="center">
          {w.today
           |> Enum.map(fn event -> Kati.Screens.Widgets.wide_event(event) end)
           |> Enum.intersperse(Kati.Screens.Widgets.wide_gap())}
        </Row>
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def wide_gap, do: ~MOB"<Spacer size={10} />"

  @doc false
  def wide_event(event) do
    # A clock, in the reader's own digits: ۲۰:۰۰ rather than 20:00, which is
    # what `Kati.Locale.time/1` answers everywhere the app formats one and what
    # `Kati.Music.Sample` writes its durations as. The face has to be asked
    # about the CONVERTED string — `mono_face/1` answers `mono` for the ASCII
    # form and `fa` for the Persian one, because U+06F0–U+06F9 is exactly what
    # `kati_mono.ttf` does not carry; asking about `event.time` instead would
    # set Persian numerals in a font with no numerals to set them in.
    time = Kati.Locale.number(event.time)

    ~MOB"""
    <Row weight={1.0} align="center">
      <Box width={2.5} height={26} corner_radius={2} background={event.color} />
      <Spacer size={9} />
      <Column weight={1.0}>
        <Text
          text={time}
          font_family={Kati.Locale.mono_face(time)}
          text_size={9.5}
          text_color={Palette.muted()}
          max_lines={1}
        />
        <Spacer size={2} />
        <Text
          text={event.title}
          text_size={11.5}
          font_weight="semibold"
          text_color={:on_surface}
          max_lines={1}
        />
      </Column>
    </Row>
    """
  end

  @doc false
  def shortcuts(w) do
    last = length(w.shortcuts) - 1

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={15}
        padding_right={15}
        padding_top={4}
        padding_bottom={4}
      >
        {w.shortcuts
         |> Enum.with_index()
         |> Enum.map(fn {row, i} -> Kati.Screens.Widgets.shortcut_row(row, i, i < last) end)}
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  # Both strings are `Kati.Widgets.Sample.shortcuts/0`'s and neither is wrapped
  # here — a map key cannot be a msgid. Nothing needs typesetting either: this
  # row is the one place on the board with no mono slot, no tracking and no
  # multi-line paragraph. The quotation marks around a spoken phrase are the
  # fixture's to fold with `Kati.Locale.quoted/1`, which draws the guillemets a
  # Persian reader expects rather than U+201C/U+201D.
  @doc false
  def shortcut_row(row, i, rule?) do
    tap = Kati.Screens.Widgets.shortcut_tap(row, i)

    ~MOB"""
    <Column fill_width={true} on_tap={tap}>
      <Row fill_width={true} align="center" padding_top={13} padding_bottom={13}>
        {Kati.Screens.Widgets.icon_tile(row.icon)}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text
            text={row.title}
            text_size={13.5}
            font_weight="semibold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={3} />
          <Text text={row.sub} text_size={11.5} text_color={Palette.sub()} max_lines={1} />
        </Column>
        <Spacer size={13} />
        {Kati.Screens.Widgets.trailing(row)}
      </Row>
      {Kati.Screens.Widgets.hairline(rule?)}
    </Column>
    """
  end

  @doc """
  The 30x30 paper tile a shortcut row leads with, from
  `Kati.Components.MishkaThemeIcon` — "a themed container around exactly one
  icon", which is what this is.

  The same swap `Kati.UI.SettingsList.icon_tile/1` makes for the settings rows,
  with the drawing's own numbers: 30dp square, radius 9, `#EFECE7` paper, glyph
  at 17 in `#5C574F`. `variant: :filled` with an explicit `color`, not
  `variant: :white` — the white variant paints the theme's `:surface`, which
  here is `#FBFAF8`, the card the tile sits on.

  The glyph is a child rather than the `icon` prop, because that shorthand
  builds a `Text` with no `font_family` and a Material Symbols ligature —
  `"mic"`, `"ios_share"` — would be typeset as the word instead of resolved to
  the glyph.

  With children and no `id`, `theme_icon/2` returns the same `:box` node
  carrying the same five props this wrote by hand, so nothing moves.
  """
  def icon_tile(name) do
    MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Palette.paper(), size: 30, radius: 9},
      [Kati.UI.symbol(name, size: 17, color: Palette.ink_soft())]
    )
  end

  # A switch when the row is a state, a chevron when it leads somewhere.
  #
  # `Kati.Locale.forward_chevron/0` rather than `"chevron_right"`: the chevron
  # on the Automations row points the way the reader is GOING, so it has to be
  # `chevron_left` on an RTL page. `layout_direction` mirrors a layout and
  # cannot mirror a picture, and a Material Symbol is text in a font — nothing
  # auto-mirrors here unless it is asked for.
  @doc false
  def trailing(row) do
    case Map.get(row, :toggle) do
      nil -> Kati.UI.symbol(Kati.Locale.forward_chevron(), size: 18, color: Palette.rail_idle())
      on? -> Kati.Screens.Widgets.toggle(on?)
    end
  end

  @doc """
  The tap a shortcut row carries, or `nil` when it carries none.

  The same fact `trailing/1` reads decides both: a row with a `toggle` is a
  state and flips, a row with a chevron leads to a screen that does not exist
  yet, so it gets no tap rather than one that silently does nothing — the rule
  `Kati.Screens.Series.episode/1` applies to an unaired episode.
  """
  @spec shortcut_tap(map(), non_neg_integer()) :: {pid(), atom()} | nil
  def shortcut_tap(row, i) do
    case Map.get(row, :toggle) do
      nil -> nil
      _ -> {self(), String.to_atom("shortcut_" <> Integer.to_string(i))}
    end
  end

  @doc """
  The design's own switch, as `Kati.Components.MishkaSwitch` in `render: :box`.

  It used to say the component could not draw this and the shape had to be
  hand-built. That was true of `render: :toggle`, which is Compose's Material
  `Switch` at Material's own 52x32 metrics with a handle that grows from 16 to
  24 on the way on — no prop at any layer reshapes it. It is **not** true of
  `render: :box`, which draws a track `Box` carrying a thumb `Box` and takes
  the drawing's own numbers: 46x28, radius 14, a 22pt thumb at a 3pt inset.

  `thumb_offset/4` places the thumb, so the arithmetic is not repeated here.
  It resolves to -9 off and +9 on, which is the 3..25 / 21..43 span the 40pt
  inner Row and its weighted Spacers used to produce — same pixels, one node
  shallower, and no `weight` in the tree at all.

  No `on_toggle`: the tap stays on the row (`shortcut_tap/2`), because 46x28 is
  under the 44pt touch minimum this screen's neighbours honour.
  """
  def toggle(on?) do
    MishkaSwitch.switch(
      render: :box,
      checked: on?,
      track_width: 46,
      track_height: 28,
      track_radius: 14,
      thumb_size: 22,
      thumb_radius: 11,
      thumb_inset: 3,
      # The whole control inverts rather than following the ground, which is
      # what the design does with every ink-filled control: `ink_fill` under
      # `on_ink`, the pair screen 28 draws for the hero's CTA pill. Both thumb
      # colours stay ONE token, because the drawing's thumb does not change
      # colour — only the track does.
      track_on_color: Palette.ink_fill(),
      track_off_color: Palette.track_off(),
      thumb_on_color: Palette.on_ink(),
      thumb_off_color: Palette.on_ink(),
      thumb_shadow: "0 1 3 0 #4D1A1917"
    )
  end

  @doc """
  The share extension, described in a card.

  All three strings are `Kati.Widgets.Sample.share/0`'s and none of them is
  wrapped here: they arrive as runtime values and `gettext/1` needs a literal
  at the call site, so the msgids belong to the module that writes them. What
  belongs here is the typography carrying them, and the paragraph is the one
  slot on this screen that needed it — `Kati.Locale.leading/1`, because 1.55 is
  a ratio measured against Plus Jakarta's metrics and Vazirmatn's ascender and
  descender are not those. Three Persian lines at the Latin leading close up.

  The note is the only multi-line paragraph on the board, which is why nothing
  else here asks for a leading. What it must NOT get is `Kati.Locale.ltr/1`
  around the whole paragraph: this is the screen's body copy rather than a
  Latin run inside a Persian sentence, and once the Sample folds its own full
  stop belongs to a Persian sentence and resolves correctly on its own.
  Isolating it would then pin a Persian paragraph to LTR. Until that fold the
  note is an English sentence on a Persian page and its terminating period sits
  at the left edge — screen 83's symptom, fixed where the string lives.
  """
  def share(w) do
    s = w.share

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={16}
    >
      <Row fill_width={true} align="center" padding_bottom={13}>
        <Box width={34} height={34} corner_radius={10} background={Palette.ink()} align="center">
          <Box width={9} height={9} corner_radius={5} background={Kati.Theme.accent()} />
        </Box>
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text
            text={s.title}
            text_size={13}
            font_weight="bold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={2} />
          <Text text={s.sub} text_size={11} text_color={Palette.sub()} max_lines={1} />
        </Column>
      </Row>
      {Kati.Screens.Widgets.hairline(true)}
      <Spacer size={13} />
      <Text
        text={s.note}
        text_size={12.5}
        line_height={Kati.Locale.leading(1.55)}
        text_color={Palette.ink_soft()}
      />
    </Column>
    """
  end

  @doc """
  The 7% ink rule — between two shortcut rows, and inside the share card.

  `Kati.Components.MishkaSeparator` is what a 1px rule between rows is, so the
  rule is its, and `render: :box` is the word that makes that true here.

  ## Why `render: :box`

  The component's default `:divider` maps to Material3's `HorizontalDivider`,
  which is not the `Box(fillMaxWidth().height(t).background(c))` this file used
  to claim but an antialiased `drawLine`. At 2.6875x a 1dp rule is given a 3px
  canvas and a 2.6875px stroke, so its bottom pixel row lands at ~69% coverage
  — a full-width row 4-5/255 lighter than the two above it. The drawing paints a
  flat 7% hairline, and no `color`/`thickness` pair recovers it, because the
  softness is in the primitive rather than the values.

  `render: :box` builds

      <Box fill_width={true} height={1} background={Palette.hairline()}>
        <Spacer size={1} />
      </Box>

  — the exact three modifiers this screen wrote by hand before it adopted the
  component. The `Spacer` is an iOS workaround for `MobBox` dropping a Box's
  `height` when it has no `width`; on Android the `height` pins the rule and
  `MobSpacer` is a bare sized `Spacer` with no background, so it draws nothing.

  The alpha survives because the colour is an ARGB int: `color` is in the
  renderer's `@color_props` whitelist and an integer reaches `colorProp`
  untouched.
  """
  def hairline(false), do: ~MOB"<Spacer size={0} />"

  def hairline(true),
    do: MishkaSeparator.separator(color: Palette.hairline(), thickness: 1, render: :box)

  # The index rather than the title: these titles are spoken phrases wrapped in
  # typographic quotes, and the tag has to survive a round trip through
  # `String.to_atom/1`.
  @impl true
  def handle_tap(tag, socket) do
    w = socket.assigns.widgets

    case Atom.to_string(tag) do
      "shortcut_" <> i ->
        rows =
          List.update_at(w.shortcuts, String.to_integer(i), fn row ->
            %{row | toggle: not row.toggle}
          end)

        {:noreply, Mob.Socket.assign(socket, :widgets, %{w | shortcuts: rows})}

      _ ->
        {:noreply, socket}
    end
  end
end
