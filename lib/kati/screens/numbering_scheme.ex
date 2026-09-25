defmodule Kati.Screens.NumberingScheme do
  @moduledoc """
  Screen 153 — pushed under Series, explaining the numbering feature rather
  than showing one show's setting.

  Built to `test/design/reference/153.html`. Its own eyebrow is the thesis:
  *"a default that announces its own reason"*. Kati stores absolute episode
  numbers and season/episode pairs for the same show at once — every anime
  tracker's oldest footgun — and picks Absolute for anime on no other basis
  than genre. A silent guess and an explained one look identical until the
  guess is wrong, and then the explained one is the only one a user can
  correct with confidence instead of suspicion. So the board draws the
  mechanism in three moves: what the row looks like **before** anyone touches
  it (`tile_card/1` over `Sample.inherited/0`, an untouched guess with its
  reason on show), **after** the guess turns out wrong (the same `tile_card/1`
  over `Sample.overridden/0`, correcting itself and naming what it overrode),
  and what flipping between the two actually **costs** (`comparison_card/1` —
  nothing: display changes, storage does not). `Kati.NumberingScheme.Sample`
  explains at length why
  those are two illustrations of one feature rather than one show's state
  shown twice, and why that puts this screen outside the migration question
  `Kati.Screens.SeriesSettings` spends its own moduledoc on.

  No dock — this is a pushed screen — so the frame closes at 40, not 132, and
  `SettingsList.chrome/2` reserves the back pill's height with `nil` rather
  than a right-hand disc: the board draws nothing on that side.

  ## Why nothing here carries `on_tap`

  "Override" and "Reset" are drawn as `Kati.UI.SettingsList.action_pill/1`,
  which does not accept one. That is not a gap to work around.
  `Kati.Screens.SeriesSettings`
  argues that a switch which flips and forgets is worse than one that visibly
  does nothing — a screen that *looks* saved and is not. The same is true
  here a step earlier: there is no `numbering_scheme` column anywhere in
  `Kati.Media` for a tap to write, because (per `Kati.NumberingScheme.Sample`)
  this screen was never a single show's live control to begin with. Wiring a
  tap that flipped a local assign between the two cards would perform a
  toggle the feature does not have — the design draws two titles, not one
  title in two states — so the honest control is the one the board actually
  gives these pills: none.

  ## Two literals the shared components could not carry unstyled

  `Kati.UI.SettingsList.note/2` and `Kati.UI.rich_text/1` share one limit,
  spelled out on `rich_text/1`: the bridge has no `AnnotatedString`, so a `Text` carries
  exactly one style and a bold word inside a sentence cannot survive as bold.
  Both notes below lose theirs — "**why**" in the first, "**only what is
  displayed**" and "**not**" in the comparison card and the MAL tile — the
  same trade `rich_text/1` documents: a bold that renders plain reads as
  typography, an orphaned emphasis reads as a layout bug, and the first is the
  one this bridge can actually produce.

  ## The MyAnimeList tile's check background is a stated literal

  `rgba(78,154,115,.14)` behind the two `check` glyphs is fourteen percent
  green, and `Kati.Theme.Palette` has no token at that alpha — `green_wash` is
  sixteen (`0x294E9A73`), and reaching for the nearest neighbour is exactly
  the move `Kati.UI.chip/2`'s moduledoc warns against for `0xFFB5AEA3`: taking
  a close token would move this tile without moving the drawing it copies.
  `mal_check_bg/0` states the drawing's own `0x244E9A73` instead.

  ## The vertical rule in the comparison card is a declared height

  The drawing gets the rule's height from `align-items: stretch`, which has no
  Mob prop, and an unsized `Box` measures zero. `comparison_column/2`'s two
  lines — a 9.5pt mono kicker, a 7pt gap, a 17pt mono value — are declared at
  40 for that reason: nothing comes back from `render/1` to measure it with.

  ## What this file translates, and what `Kati.NumberingScheme.Sample` owns

  The board's words arrive from two places and only one of them is here. The
  four eyebrows, the two info notes and the MAL tile's three row labels are
  literals at these call sites, so they are the msgids this file carries.
  Everything the cards are *filled* with — the header, both rows' titles, subs
  and pills, the comparison card's two labels, its two values and its
  footnote, and every line of the MAL tile's body — is declared in
  `Kati.NumberingScheme.Sample` and is wrapped **there**, the split
  `Kati.Screens.SeriesSettings` states for its own fixture: one msgid per
  string, wherever the string lives, and a screen that made its own copy of a
  fixture's copy would be two strings to keep in step. A `gettext/1` here could
  not reach them anyway — its argument has to be a literal at the call site for
  `mix gettext.extract` to see a msgid at all, and what this file holds is a
  map key.

  What this file DOES owe those strings is the typesetting, which is why the
  mechanical half of the fold is all on this side of the line. `kicker/1` and
  `comparison_column/2` both pinned `font_family="mono"` on a slot the fixture
  fills, and `kati_mono.ttf` carries no glyph in U+0600–U+06FF: the moment the
  Sample says «مطلق» those two lines are handed to Android's own substitute
  face, beside Kati's, in a way `Kati.PersianFontTest` is the only reader of.
  Both ask `Kati.Locale.mono_face/1` — the STRING's script rather than the
  reader's — so `E32` and `S2 E6` stay in DM Mono in both scripts exactly as
  screen 80's provider names do, and a Persian label does not.

  The one name on this board that is not copy in either script is
  `MyAnimeList` itself, and `animelist.xml` with it: a service's name for
  itself and a file it writes. Board 127 draws `Lumen+` in Latin on a Persian
  page for the same reason, and the eyebrow above the tile keeps the Latin run
  inside its Persian sentence rather than transliterating it.
  """
  # `back: "Series"` stays the English word and is translated at RUNTIME by
  # `Kati.Screens.Pushed` — the label lands in a module attribute on the way,
  # and `gettext/1` inside an attribute is evaluated at COMPILE time and frozen
  # in whichever locale the compiler happened to be in.
  # `Kati.Screens.Pushed.back_vocabulary/0` is what keeps the msgid alive for
  # the extractor; `Series` is in it, and so is the `Episodes` that
  # `Kati.Screens.Season` pushes this screen with.
  use Kati.Screens.Pushed, back: "Series"
  use Gettext, backend: Kati.Gettext

  alias Kati.NumberingScheme.Sample
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @impl true
  def load(socket) do
    socket
    |> Mob.Socket.assign(:header, Sample.header())
    |> Mob.Socket.assign(:inherited, Sample.inherited())
    |> Mob.Socket.assign(:overridden, Sample.overridden())
    |> Mob.Socket.assign(:comparison, Sample.comparison())
    |> Mob.Socket.assign(:mal, Sample.mal())
  end

  @doc false
  def content(assigns) do
    # `pgettext/2` for the two short eyebrows and plain `gettext/1` for the two
    # long ones. `mix gettext.merge` fuzzy-matches a short msgid against any
    # entry close to it, and both short ones have a near neighbour already in
    # the catalogue — *What it changes* against screen 92's *What it would be*,
    # one word apart in the half of the string a distance metric weighs most.
    # An untranslated eyebrow arriving pre-filled with another board's sentence,
    # marked fuzzy, is the failure this whole fold keeps meeting: legible enough
    # that nobody files it. The two long ones are their own nearest neighbour.
    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {SettingsList.chrome(nil, 44)}
        {SettingsList.title(assigns.header.title, assigns.header.subtitle)}
        {UI.eyebrow(pgettext("a setting nobody has changed", "Inherited"))}
        {Kati.Screens.NumberingScheme.tile_card(assigns.inherited)}
        <Spacer size={11} />
        {SettingsList.note("info", Kati.Screens.NumberingScheme.reason_note())}
        <Spacer size={20} />
        {UI.eyebrow(gettext("Overridden — the override announces itself"))}
        {Kati.Screens.NumberingScheme.tile_card(assigns.overridden)}
        <Spacer size={20} />
        {UI.eyebrow(pgettext("what switching numbering affects", "What it changes"))}
        {Kati.Screens.NumberingScheme.comparison_card(assigns.comparison)}
        <Spacer size={14} />
        {SettingsList.note("info", Kati.Screens.NumberingScheme.clutter_note())}
        <Spacer size={20} />
        {UI.eyebrow(gettext("The MyAnimeList tile — sole integration those users get"))}
        {Kati.Screens.NumberingScheme.mal_card(assigns.mal)}
      </Column>
    </Scroll>
    """
  end

  @doc "The single-row card both `Sample.inherited/0` and `Sample.overridden/0` draw — same shape, opposite state."
  def tile_card(row) do
    SettingsList.card([
      SettingsList.row(
        SettingsList.icon_tile(row.icon),
        # `lines: 2`, which is `Kati.UI.SettingsList.body/3`'s own exception and
        # this row's whole point. That function pins a sub-line to one line
        # because *"one line is right for a setting and wrong for an
        # explanation"* — and per `Kati.NumberingScheme.Sample.inherited/0` this
        # sub IS the explanation: *because this is anime* is the fact that turns
        # a guess into something a user can correct on sight, and *you set this ·
        # anime default was Absolute* names both halves of the override. A row
        # that truncates either has deleted the only thing on it worth reading,
        # the same way screen 26's diagnostic printed `…the phone …` and stopped.
        #
        # It was already truncating in ENGLISH. `test/design/screens/153.html`
        # gives the body `flex:1;min-width:0` with no `nowrap`, so the drawing
        # wraps it; at 402pt the slot is about 198 wide and the overridden row's
        # sub needs more. Persian only makes a live defect louder — it is longer
        # again, and it is the half of the board an untranslated screen was
        # hiding.
        SettingsList.body(row.title, row.sub, lines: 2),
        SettingsList.action_pill(row.action),
        padding: 13,
        rule: false
      )
    ])
  end

  # Both notes are one msgid each, `<>`-joined for the line width rather than
  # split into sentences: Gettext expands a concatenation of literals at compile
  # time (`Gettext.Macros.expand_to_binary/3`), so the extractor sees the whole
  # paragraph, and a translator gets the argument in one piece instead of three
  # clauses whose Persian order is not the English one. The bold word each one
  # loses — **why** here, **only what is displayed** below — is the trade this
  # module's own moduledoc states for `Kati.UI.rich_text/1`.
  @doc false
  def reason_note do
    gettext(
      "That phrasing is the point. An inherited default that says why is the " <>
        "difference between a helpful guess and a confusing one — and " <>
        "numbering is the single most common thing anime trackers get wrong."
    )
  end

  @doc false
  def clutter_note do
    gettext(
      "Showing both is clutter; showing the wrong one is a bug. Storage is " <>
        "one scheme, display is a preference."
    )
  end

  @doc """
  Absolute vs Seasons, same episode, side by side over one footnote.

  Not `SettingsList.card/1` — that recipe is 20pt radius over 4/15pt padding
  for a stack of rows, and this is a 22pt radius over 17pt padding holding a
  two-column comparison with no row in it at all. Same shadow, same card
  fill, different shape entirely; reaching for the row card here would be
  reaching for the wrong tool because the numbers happen to be close.
  """
  def comparison_card(data) do
    ~MOB"""
    <Column
      fill_width={true}
      background={Kati.Theme.card(Palette.mode())}
      corner_radius={22}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={17}
    >
      <Row fill_width={true} align="top">
        {Kati.Screens.NumberingScheme.comparison_column(data.left)}
        <Spacer size={12} />
        <Box width={1} height={40} background={Palette.hairline_strong()} />
        <Spacer size={12} />
        {Kati.Screens.NumberingScheme.comparison_column(data.right)}
      </Row>
      <Spacer size={13} />
      {SettingsList.hairline(true)}
      <Spacer size={13} />
      <Text
        text={data.note}
        text_size={12.5}
        line_height={Kati.Locale.leading(1.65)}
        text_color={Palette.ink_soft()}
      />
    </Column>
    """
  end

  # `Kati.Locale.mono_face/1` and not the literal `"mono"`, and not
  # `mono_face/0` either: the question this slot has to ask is the VALUE's
  # script, not the reader's. `E32` and `S2 E6` are a machine's shorthand and
  # pure ASCII, so they keep DM Mono on a Persian page exactly as screen 80's
  # provider names do — including their Latin DIGITS, which is
  # `Kati.Locale.number/1`'s own stated exception, since `kati_mono.ttf` carries
  # none of U+06F0–U+06F9. If `Kati.NumberingScheme.Sample.comparison/0` ever
  # spells these out as words, the same call hands them Vazirmatn instead of
  # letting Android substitute a face nobody chose.
  @doc false
  def comparison_column(%{label: label, value: value}) do
    ~MOB"""
    <Column weight={1.0}>
      {Kati.Screens.NumberingScheme.kicker(label)}
      <Spacer size={7} />
      <Text
        text={value}
        font_family={Kati.Locale.mono_face(value)}
        text_size={17}
        text_color={Palette.ink()}
        max_lines={1}
      />
    </Column>
    """
  end

  # The 9.5pt mono uppercase label both the comparison card and the MAL tile
  # draw over their values — the board's one small-print recipe, used twice.
  #
  # It is `Kati.UI.eyebrow/2`'s inner Text one size down, so it takes that
  # recipe whole rather than half of it. `Kati.UI.eyebrow_label/1`'s doc is
  # where the four differences are argued and it says they travel together:
  # `String.upcase/1` is a **Latin** operation and the Arabic script has no
  # case, `.1em` of tracking is a Latin small-caps effect that breaks the joins
  # between Persian letters, and Vazirmatn wants half a point more than DM Mono
  # at semibold to hold the same optical weight — 10 over 9.5 here, the same
  # +0.5 that makes the eyebrow's 11 out of 10.5.
  #
  # `mono_face/1` rather than `mono_face/0`, for the reason
  # `comparison_column/2` above carries: this slot draws BOTH this file's own
  # translated labels and whatever `Kati.NumberingScheme.Sample` hands the
  # comparison card, so the face has to follow the string rather than the
  # reader. Note it asks the RAW text — `eyebrow_label/1` upcases ASCII and
  # returns Persian untouched, so either way the answer is the same.
  @doc false
  def kicker(text) do
    ~MOB"""
    <Text
      text={Kati.UI.eyebrow_label(text)}
      font_family={Kati.Locale.mono_face(text)}
      text_size={Kati.Locale.pick(9.5, 10)}
      font_weight={Kati.Locale.pick("normal", "semibold")}
      letter_spacing={Kati.Locale.tracking(0.1)}
      text_color={Palette.tertiary()}
      max_lines={1}
    />
    """
  end

  @doc """
  The MAL import tile: what it reads, what it does not, and why the tile has
  to say both.

  The three row labels are this file's msgids and the three bodies are not —
  `Kati.NumberingScheme.Sample.mal/0` owns those, along with the tile's title
  and its file name. All three labels take one `msgctxt` because they are one
  set of three and two of them are too short to be safe without it: *Does not*
  is an elliptical two words (*does not come across*) that `mix gettext.merge`
  would fuzzy-match against any sentence with a negation in it, and *Comes
  across* is an idiom rather than a phrase a catalogue can guess at. The
  context also keeps the pair readable as a pair for whoever translates it —
  Persian mirrors the ellipsis with «چه می‌آید» / «چه نمی‌آید», which only works
  if both arrive together.
  """
  def mal_card(data) do
    ~MOB"""
    <Column
      fill_width={true}
      background={Kati.Theme.card(Palette.mode())}
      corner_radius={22}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={17}
    >
      <Row fill_width={true} align="center">
        {Kati.Screens.NumberingScheme.mal_glyph(data.glyph)}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text
            text={data.title}
            text_size={13.5}
            font_weight="bold"
            text_color={Palette.ink()}
            max_lines={1}
          />
          <Spacer size={4} />
          <Text
            text={data.file}
            font_family="mono"
            text_size={10.5}
            text_color={Palette.sub()}
            max_lines={1}
          />
        </Column>
      </Row>
      <Spacer size={14} />
      {Kati.Screens.NumberingScheme.mal_fact(
        "check",
        Kati.Screens.NumberingScheme.mal_check_bg(),
        Palette.green_text(),
        pgettext("what a MyAnimeList import brings", "Comes across"),
        data.comes_across,
        Palette.ink(),
        true
      )}
      {Kati.Screens.NumberingScheme.mal_fact(
        "check",
        Kati.Screens.NumberingScheme.mal_check_bg(),
        Palette.green_text(),
        pgettext("what a MyAnimeList import brings", "Numbering"),
        data.numbering,
        Palette.ink(),
        true
      )}
      {Kati.Screens.NumberingScheme.mal_fact(
        "block",
        Kati.Theme.paper(Palette.mode()),
        Palette.sub(),
        pgettext("what a MyAnimeList import brings", "Does not"),
        data.does_not,
        Palette.sub(),
        false
      )}
      <Spacer size={13} />
      {SettingsList.hairline(true)}
      <Spacer size={12} />
      <Text
        text={data.footnote}
        text_size={11.5}
        line_height={Kati.Locale.leading(1.55)}
        text_color={Palette.sub()}
      />
    </Column>
    """
  end

  # The literal `rgba(78,154,115,.14)` behind the tile's two `check` glyphs —
  # see the moduledoc for why the nearest named token is the wrong reach.
  @doc false
  def mal_check_bg, do: Palette.green_wash_soft()

  # 34pt, mono "M" — not `SettingsList.icon_tile/1`, which types a Material
  # Symbols ligature and would render this letter as a blank box: `M` is not
  # in the icon subset, it is the drawing's own literal glyph.
  #
  # The one `font_family="mono"` on this board that is NOT
  # `Kati.Locale.mono_face/1`, and deliberately. Every other mono slot here
  # holds a string that could one day be Persian; this one holds MyAnimeList's
  # own initial, which is the service's name for itself in the same sense
  # `Kati.Services.Service` keeps `TMDB` and board 127 keeps `Lumen+` in Latin
  # on a Persian page. A transliterated `M` would be a brand spelled two ways.
  @doc false
  def mal_glyph(letter) do
    ~MOB"""
    <Box
      width={34}
      height={34}
      corner_radius={11}
      background={Kati.Theme.paper(Palette.mode())}
      align="center"
    >
      <Text text={letter} font_family="mono" text_size={14} text_color={Palette.ink()} />
    </Box>
    """
  end

  # One MAL fact: a 22pt tinted glyph, a kicker, a line, the hairline unless
  # it is the tile's last fact. `align="top"` rather than `SettingsList.row/4`'s
  # centred one — these bodies wrap to a second line and the glyph has to sit
  # on the first, the same reason `Kati.UI.SettingsList.note/2` pins its own icon to `:top`.
  @doc false
  def mal_fact(icon, icon_bg, icon_color, label, text, text_color, rule?) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top" padding_top={11} padding_bottom={11}>
        <Box width={22} height={22} corner_radius={8} background={icon_bg} align="center">
          {Kati.UI.symbol(icon, size: 13, color: icon_color)}
        </Box>
        <Spacer size={11} />
        <Column weight={1.0}>
          {Kati.Screens.NumberingScheme.kicker(label)}
          <Spacer size={5} />
          <Text
            text={text}
            text_size={12.5}
            line_height={Kati.Locale.leading(1.5)}
            text_color={text_color}
          />
        </Column>
      </Row>
      {SettingsList.hairline(rule?)}
    </Column>
    """
  end
end
