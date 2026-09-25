defmodule Kati.Screens.AutoDetectMusic do
  @moduledoc """
  Screen 150 — Auto-detect, music mode, pushed under Settings.

  Built to `test/design/reference/150.html`, the sibling frame to screen
  36's `Kati.Screens.AutoDetect`. The board's own caption says this should be
  *"a mode on 36 rather than a second board"* — sources, rules and the
  disambiguation card are shared in spirit, and two boards risk drifting
  within a release. This file exists anyway, as its own module, because that
  is the shape this build pass asked for; the segmented control at the top is
  built to make the merge cheap later rather than to pretend it already
  happened. See `## Two boards, one switch` below for what that costs today.

  ## Reachable from the development gallery only

  Every value on this page is `Kati.Settings.DetectMusicSample`'s: the
  `3 SOURCES · 41 EPISODES, 128 TRACKS` line, the now-playing cards, the four
  app switches. Kati has no music detection — `Kati.Media.Detect` ticks films
  and episodes — and music is outside the film and series scope, so screen 36
  does not draw the TV & film / Music control that led here and no reader can
  arrive. `Kati.AppReachabilityTest`'s `@no_route` records it. The page stays
  as the drawing of board 150 for the day music detection is built.

  ## Two now-playing cards, and the order is the argument

  A media-session notification carries artwork only when the source app
  bothers to attach one, and Spotify, YouTube Music and Poweramp do not
  always. So the board draws the **no-art** card first, at full size, with
  every field a live session would carry — title, artist, album, a `Live`
  pill, the elapsed bar, the scrobble rule — and follows it with a second,
  compact **with-art** card that exists only to show what the icon tile
  becomes when the session *does* attach a picture. Building it the other way
  round — art-first, no-art as the footnote — would have told a truer story
  about how the design looks and a false one about how often it happens.

  ## The threshold is OR, not AND

  `scrobbles at 50% or 4 min` — a two-minute hardcore track and a nine-minute
  post-rock one both need to be scrobblable, and a single percentage cannot
  do that (50% of two minutes is fifty-eight seconds short of a play anyone
  would call real; 50% of nine minutes is four and a half). The four-minute
  floor is what makes the short track count; the 50% ceiling is what stops a
  long track from counting after a skip. Screen 36's `ticks at 90%` is a
  single number because a TV episode has no equivalent problem — a 20-minute
  and a 70-minute episode both clear 90% at roughly the moment a viewer would
  agree they watched it.

  ## Two boards, one switch

  `Kati.UI.Segmented.plain/2` is exactly right for the control the board
  draws — 34pt tiles in a 16pt trough, no icons, switching what the whole
  screen means rather than a value inside it, which is precisely the
  distinction its own moduledoc draws between itself and screen 20's control.

  What it cannot do, because this is two modules and not one screen with a
  mode assign, is switch in place. Tapping `TV & film` here pushes
  `Kati.Screens.AutoDetect` — a real screen change, not a fake one, but a
  push rather than a swap, so the back stack grows by one frame the merged
  version would not have. Screen 36 no longer draws the control's other half. Tapping `Music` while already on `Music` does
  nothing to the picture; `handle_tap/2` still answers it, the same way
  `Kati.Screens.LogWeight` answers its own already-selected unit segment,
  because a control the board drew keeps a handler whether or not that
  handler has anything to change.

  ## Which apps: a letter, not an icon

  `Kati.UI.SettingsList.icon_tile/1` is the shared 30pt leading tile
  everywhere else in this file — `Rules`, `Sources` on screen 36 — but the
  board does not give Spotify, YouTube Music or Poweramp an icon at all; it
  gives each a single mono capital on a paper square, the first letter of the
  name next to it. `app_tile/1` is that other 30pt tile: same square, same
  radius, a `DM Mono` glyph in `on_surface` instead of a symbol in
  `ink_soft`. Reusing `icon_tile/1` here would have meant inventing an icon
  the board never drew.

  Switch state is drawn, not wired — `Spotify` and `YouTube Music` on,
  `Poweramp` and `Everything else` off, exactly as `Kati.Settings.DetectMusicSample.apps/0`
  states them — for the same reason screen 36's per-source switches carry no
  tap: there is no allow-list resource yet for a tap to write into, and a
  switch that flips in socket state alone and forgets itself on the next push
  would be a worse lie than a switch that plainly does not move. No `on_tap`
  is drawn, so `Kati.ScreenTapSweepTest` has nothing to report.

  ## The footnote's bold word, and why it is `rich_text/1` and not `note/2`

  `Kati.UI.SettingsList.note/2` draws the same dashed-to-solid frame this
  needs, but its child is a single plain-string `Text` and the board bolds
  `Everything else` inside a longer sentence. `Kati.Screens.Backup.footnote/0`
  (screen 128) is the precedent for the way out — the same `MishkaPill` frame
  `note/2` builds, assembled by hand so the paragraph can go in through
  `Kati.UI.rich_text/1` instead. `apps_note/0` and `decision/1`'s closing
  paragraph both use it. Per `rich_text/1`'s own moduledoc the bold is an
  approximation, not a real span — the bridge has no `AnnotatedString`, so
  the whole run gets one style, and both paragraphs now say **which** run that
  is with `base: true` on their body copy rather than letting it fall out of
  which run happens to be longest. In English the two answers were the same;
  in Persian they need not be, and a translation that came out shorter than
  its own bold word would have set the whole footnote semibold in ink. The
  layout is correct; the emphasis is not drawn. That is the documented trade,
  not an oversight of this file's.

  ## The decision card: same shape, a different question

  `Kati.Screens.AutoDetect.decision/1` asks *which title*; this asks *which
  release* — "the same track on the studio album, a live record and a
  compilation," per the board's own closing line, which is why the card grows
  a paragraph the TV version does not draw. The art tile shrinks from a 2:3
  TV poster (`36×51`) to a square (`40×40`), because a music match is
  disambiguated by album art, not by a poster's portrait crop. `choice/2` is
  otherwise the same `Kati.Components.MishkaToggle` call screen 36 makes,
  down to the three colour pairs and the reasons for them — see that
  function's doc for the full case against `MishkaChip` and
  `MishkaSegmentedControl` — with this board's own three release names in
  place of its three title guesses.

  ## Everything the board draws is here

  Nothing on `test/design/reference/150.html`'s frame was left unbuilt.

  ## Which half of the copy this file owns, after the fold

  mishka-group/kati#103 folded the 33 Persian mirrors away, so this module is
  now both language's board 150 and every word on it has to come from
  `Kati.Gettext` rather than from a literal. Two files hold those words and
  only one of them is this one.

  **This file owns its own chrome**: the 28pt title, the two segment labels
  (`modes/0`, which `Kati.Screens.AutoDetect` draws as well), the four
  eyebrows, and the two hand-assembled paragraphs — `apps_note/0`'s and
  `decision/1`'s. All of those are literals written here and all of them now
  go through `gettext/1`. The back pill's `Settings` is the exception that
  needs nothing: `Kati.Screens.Pushed` translates a `back:` option at draw
  time and declares the word in its own `back_vocabulary/0`, so the pill was
  already Persian before this file was touched.

  **`Kati.Settings.DetectMusicSample` owns the state**, and its words are
  still English literals: the subtitle's three frozen counts, the now-playing
  track, artist and album, the `Live` pill, the elapsed clock and the scrobble
  rule, the `With art` eyebrow and its caption, the four app names and their
  reasons, the four rule names and theirs, and the queued question with its
  three release names. Those belong to that module the same way
  `Kati.Music.Sample`'s album and tracklist belong to it — that one has
  already folded, and `Kati.Locale.number/1` on its `4:12` and
  `gettext("Low Water")` on its opening track are what this card's own copy
  should read like when its turn comes. Inlining them here instead would put
  two copies of the drawing's copy in the repository, which is exactly how the
  fixture and the screen start disagreeing about what the board says —
  `Kati.Screens.Activity.drawn/0` states that argument at length and keeps its
  own Sample for it.

  What this file does do for those strings is typeset them correctly whichever
  language they arrive in: every mono slot asks `Kati.Locale.mono_face/1` about
  the run it is handed rather than naming `mono` outright, so the day the
  fixture folds, `کارهای جزر و مد` lands in Vazirmatn at the mono size and
  `1:58 / 4:12` stays in DM Mono, with nothing here to change.
  """

  use Kati.Screens.Pushed, back: "Settings"
  use Gettext, backend: Kati.Gettext

  alias Kati.Components.MishkaPill
  alias Kati.Components.MishkaProgress
  alias Kati.Components.MishkaToggle
  alias Kati.Settings.DetectMusicSample, as: Sample
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList
  alias Kati.UI.Segmented

  @impl true
  def load(socket) do
    Mob.Socket.assign(socket, :detect, %{
      subtitle: Sample.subtitle(),
      now_playing: Sample.now_playing(),
      with_art: Sample.with_art(),
      apps: Sample.apps(),
      rules: Sample.rules(),
      decision: Sample.decision()
    })
  end

  @doc false
  def content(assigns) do
    d = assigns.detect

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {SettingsList.chrome(nil)}
        {SettingsList.title(gettext("Auto-detect"), d.subtitle)}
        {Segmented.plain(Kati.Screens.AutoDetectMusic.modes(), :music)}
        <Spacer size={20} />
        {UI.eyebrow(gettext("Now playing — no art, the common case"))}
        {Kati.Screens.AutoDetectMusic.now_playing(d.now_playing)}
        {Kati.Screens.AutoDetectMusic.with_art(d.with_art)}
        {SettingsList.eyebrow_muted(gettext("Which apps"))}
        {Kati.Screens.AutoDetectMusic.apps_card(d.apps)}
        {Kati.Screens.AutoDetectMusic.apps_note()}
        {SettingsList.eyebrow_muted(gettext("Rules"))}
        {Kati.Screens.AutoDetectMusic.rules_card(d.rules)}
        {UI.eyebrow(gettext("Needs a decision"))}
        {Kati.Screens.AutoDetectMusic.decision(d.decision)}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The header switch's two tags. `:music` is this screen; `:tv` is screen 36.

  The TAG is the key and the LABEL is asked for here, which is the rule
  mishka-group/kati#103 settled and `Kati.Screens.AddByHand.kind_list/0` states
  at length: `handle_tap/2` matches on `:tv` and `:music` in every locale, and
  a pair whose words were frozen into a module attribute would come out in
  whichever language the compiler happened to be in. This is already a function
  rather than an attribute, so the fold costs nothing here.

  Only this page draws the pair. `Kati.Screens.AutoDetect` used to draw it
  too, with `:tv` selected, and stopped when music detection was taken out of
  scope — see the moduledoc.
  """
  @spec modes() :: [{String.t(), atom()}]
  def modes, do: [{gettext("TV & film"), :tv}, {gettext("Music"), :music}]

  @doc """
  The no-art now-playing card — the primary state, drawn first and in full.

  The elapsed bar is `Kati.Components.MishkaProgress` in `render={:box}` mode,
  the same call `Kati.Screens.AutoDetect.now_playing/1` makes and for the same
  reasons its doc gives in full: a `#E7E3DC` track no plain `<Progress>` prop
  reaches, a shared 5pt thickness and 3pt radius on both bars, and `max: 1`
  rather than scaling to 100 so `fraction/1` never round-trips a float through
  a multiply-then-divide.

  ## Three mono slots, and each one asks the STRING which face it needs

  `meta`, `elapsed` and `rule` are all DM Mono on the board, and
  `kati_mono.ttf` carries no Persian glyph at all — not a letter, and none of
  U+06F0–U+06F9 either. So each of the three goes through
  `Kati.Locale.mono_face/1`, which asks the run's own script rather than the
  reader's language: `KELL OSTRAND · TIDAL WORKS` and `1:58 / 4:12` are pure
  ASCII and keep DM Mono in both locales, exactly as board 150 draws them,
  while the same three lines set in Persian take Vazirmatn at the mono size.
  `Kati.Locale.mono_face/1`'s own doc argues the rule and `Kati.PersianFontTest`
  is what keeps it; the alternative — a hardcoded `mono` — renders the Persian
  half in Android's own substitute face beside the Latin half in Kati's, which
  is the failure that looks deliberate.

  The face is asked per string rather than once per card because the three do
  not have to agree: the elapsed clock can stay Latin digits while the artist
  and album line beside it is Persian, and on this card it does.
  """
  @spec now_playing(map()) :: map()
  def now_playing(n) do
    bar =
      MishkaProgress.progress(
        value: n.progress,
        max: 1,
        render: :box,
        height: 5,
        corner_radius: 3,
        track_color: Palette.track(),
        color: Palette.ink()
      )

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={17}
      >
        <Row fill_width={true} align="center">
          {Kati.Screens.AutoDetectMusic.no_art_tile()}
          <Spacer size={13} />
          <Column weight={1.0}>
            <Text
              text={n.title}
              text_size={14}
              font_weight="bold"
              text_color={:on_surface}
              max_lines={1}
            />
            <Spacer size={4} />
            <Text
              text={n.meta}
              font_family={Kati.Locale.mono_face(n.meta)}
              text_size={10.5}
              text_color={Palette.muted()}
              max_lines={1}
            />
          </Column>
          <Spacer size={13} />
          {SettingsList.status_pill(n.status, Palette.green_text(), Palette.green_wash())}
        </Row>
        <Spacer size={14} />
        {bar}
        <Spacer size={9} />
        <Row fill_width={true} align="center">
          <Text
            text={n.elapsed}
            font_family={Kati.Locale.mono_face(n.elapsed)}
            text_size={10.5}
            text_color={Palette.muted()}
            max_lines={1}
          />
          <Spacer weight={1.0} />
          <Text
            text={n.rule}
            font_family={Kati.Locale.mono_face(n.rule)}
            text_size={10.5}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Row>
      </Column>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc """
  The 52pt icon tile the no-art card leads with: `graphic_eq` on a placeholder
  square, because there is no artwork to fill it and the board draws that
  absence as an icon rather than as empty space.
  """
  @spec no_art_tile() :: map()
  def no_art_tile do
    ~MOB"""
    <Box width={52} height={52} corner_radius={12} background={Palette.placeholder()} align="center">
      {UI.symbol("graphic_eq", size: 22, color: Palette.tertiary())}
    </Box>
    """
  end

  @doc """
  The compact with-art card: a 52pt art tile beside two lines of label copy,
  no progress bar and no status pill, because the point of this card is the
  tile, not a second now-playing state.

  `albm1` is a shipped seed — `priv/sample/design/albm1_400x400.jpg` — so
  `art/4` resolves it to the real picture rather than to its own placeholder
  branch.

  ## The eyebrow, three ways, and none of them is `String.upcase/1`

  The board sets `WITH ART` as a spaced mono capital run, which is a Latin
  typographic device three times over. `Kati.UI.eyebrow_label/1` upcases in
  Latin and hands Persian back untouched — Arabic script has no case, so
  `String.upcase/1` on it is a no-op that still reads, in a diff, as a decision
  somebody made. `Kati.Locale.tracking/1` drops the 0.1 in Persian, because
  tracking breaks the joins between Persian letters rather than airing them
  out. And `Kati.Locale.mono_face/1` asks the finished label which face it
  needs, for the reason `now_playing/1`'s doc gives in full.

  All three are asked of the SAME string, so the label is built once above the
  sigil rather than upcased twice inside it — once for the text and once for
  the face, which is how the two would drift apart.
  """
  @spec with_art(map()) :: map()
  def with_art(w) do
    eyebrow = UI.eyebrow_label(w.eyebrow)

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
          {Kati.Screens.AutoDetectMusic.art(w.seed, 52, 52, 12)}
          <Spacer size={13} />
          <Column weight={1.0}>
            <Text
              text={eyebrow}
              font_family={Kati.Locale.mono_face(eyebrow)}
              text_size={9.5}
              letter_spacing={Kati.Locale.tracking(0.1)}
              text_color={Palette.tertiary()}
              max_lines={1}
            />
            <Spacer size={5} />
            <Text text={w.caption} text_size={13} font_weight="semibold" text_color={:on_surface} />
          </Column>
        </Row>
      </Column>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  A square art tile, or a placeholder square when the seed has no shipped
  image — the same fallback `Kati.Screens.AutoDetect.poster/4` draws for TV
  posters, sized here for music's square art instead of a 2:3 crop.
  """
  @spec art(String.t(), pos_integer(), pos_integer(), pos_integer()) :: map()
  def art(seed, w, h, radius) do
    case Kati.Design.Images.poster(seed) do
      nil ->
        ~MOB"""
        <Box width={w} height={h} corner_radius={radius} background={Palette.placeholder()} />
        """

      src ->
        ~MOB"""
        <Image src={src} width={w} height={h} corner_radius={radius} content_mode="fill" />
        """
    end
  end

  @doc "The `Which apps` card: four rows, each a mono initial, a name and reason, a switch."
  @spec apps_card([map()]) :: map()
  def apps_card(apps) do
    last = length(apps) - 1

    rows =
      apps
      |> Enum.with_index()
      |> Enum.map(fn {app, i} -> Kati.Screens.AutoDetectMusic.app_row(app, i < last) end)

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(rows)}
      <Spacer size={11} />
    </Column>
    """
  end

  @doc false
  def app_row(app, rule?) do
    SettingsList.row(
      Kati.Screens.AutoDetectMusic.app_tile(app.initial),
      SettingsList.body(app.title, app.sub),
      SettingsList.switch(app.on),
      padding: 13,
      rule: rule?
    )
  end

  @doc """
  The 30pt mono-initial tile — see `## Which apps: a letter, not an icon`
  above for why this is not `Kati.UI.SettingsList.icon_tile/1`.

  The face is `Kati.Locale.mono_face/1` of the letter itself rather than a
  hardcoded `mono`, because three of the four letters are the first character
  of a brand — `S`, `Y`, `P` — and stay in DM Mono in both scripts, while the
  fourth belongs to a row whose name is translated. `Kati.Music.Sample.album/0`
  makes the same distinction one step earlier, taking its tile letter from
  `String.first/1` of the album's own translated title so board 76 can draw
  **ک** for کارهای جزر و مد; the letters here arrive already chosen by
  `Kati.Settings.DetectMusicSample.apps/0`, so this end only has to typeset
  whichever one it is handed.
  """
  @spec app_tile(String.t()) :: map()
  def app_tile(initial) do
    ~MOB"""
    <Box width={30} height={30} corner_radius={9} background={Palette.paper()} align="center">
      <Text
        text={initial}
        font_family={Kati.Locale.mono_face(initial)}
        text_size={13}
        text_color={:on_surface}
        text_align="center"
      />
    </Box>
    """
  end

  @doc """
  The dashed-to-solid footnote under `Which apps` — see
  `## The footnote's bold word` above for why this hand-assembles
  `Kati.Components.MishkaPill` instead of calling
  `Kati.UI.SettingsList.note/2`.

  ## Three runs, three msgids, and the spaces between them are not translated

  The bold word sits INSIDE the sentence, so the paragraph cannot be one
  msgid. Each run is therefore its own `gettext/1` and the two joining spaces
  stay outside them: a msgid with a trailing space is one a translator loses without noticing, and a
  Persian sentence needs the join to be a space in exactly the same place
  anyway. `Kati.UI.rich_text/1` concatenates in the order written, and that
  order is the LOGICAL one — the bidi algorithm lays the Persian out
  right-to-left from it without the runs having to be reversed here.

  `Everything else` is the app's own existing msgid rather than a fourth one
  of this screen's: `Kati.Stats.Sample.year/0` names the same catch-all on
  board 33's breakdown, and two spellings of one word is how a catalogue
  starts disagreeing with itself.

  `base: true` on `body` rather than leaving the choice to run length. See
  `## The footnote's bold word` above: `rich_text/1` takes its one style from
  the longest run when nothing is marked, which is the plain body copy in
  English and was only ever true by arithmetic — a Persian translation that
  came out shorter than its bold word would silently set the whole paragraph
  semibold in ink. Marking it says which run the style is, in every language.
  """
  @spec apps_note() :: map()
  def apps_note do
    body = [
      text_size: 12.5,
      line_height: Kati.Locale.leading(1.65),
      text_color: Palette.ink_soft(),
      font_family: Kati.Locale.face_prop(),
      base: true
    ]

    strong = [
      font_weight: "semibold",
      text_color: Palette.ink(),
      text_size: 12.5,
      line_height: Kati.Locale.leading(1.65),
      font_family: Kati.Locale.face_prop()
    ]

    paragraph =
      UI.rich_text([
        {gettext("A per-app list does not scale to a phone with twelve music apps, so") <> " ",
         body},
        {gettext("Everything else"), strong},
        {" " <>
           gettext(
             "is a single catch-all and the named rows are exceptions above it — on by " <>
               "default for the three Kati has seen."
           ), body}
      ])

    note =
      MishkaPill.pill(
        %{
          background: :none,
          corner_radius: 18,
          border_color: Palette.border(),
          border_width: 1.5,
          padding: 15,
          fill_width: true,
          content_align: :top,
          content_fill_width: true,
          leading: UI.symbol("info", size: 17, color: Palette.sub()),
          leading_gap: 11
        },
        [paragraph]
      )

    ~MOB"""
    <Column fill_width={true}>
      {note}
      <Spacer size={20} />
    </Column>
    """
  end

  @doc "The `Rules` card: four rows, three shapes of trailing control among them."
  @spec rules_card([map()]) :: map()
  def rules_card(rules) do
    last = length(rules) - 1

    rows =
      rules
      |> Enum.with_index()
      |> Enum.map(fn {rule, i} -> Kati.Screens.AutoDetectMusic.rule_row(rule, i < last) end)

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(rows)}
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def rule_row(rule, rule?) do
    SettingsList.row(
      SettingsList.icon_tile(rule.icon),
      SettingsList.body(rule.title, rule.sub),
      Kati.Screens.AutoDetectMusic.rule_control(rule.control),
      padding: 13,
      rule: rule?
    )
  end

  @doc """
  A rule row's trailing slot: a mono value, a switch, or nothing at all.

  `:none` answers `nil`, which `Kati.UI.SettingsList.row/4` already turns into
  a zero-size spacer — the fourth rule, `A track skipped at 45%`, draws no
  trailing control on the board and gets none here.

  The mono value asks `Kati.Locale.mono_face/1` which face it needs for the
  reason `now_playing/1`'s doc gives: `30s` is ASCII and keeps DM Mono in both
  scripts, and a value carrying a Persian numeral or a Persian unit takes
  Vazirmatn at the mono size, because `kati_mono.ttf` has none of
  U+06F0–U+06F9.
  """
  @spec rule_control({:value, String.t()} | {:switch, boolean()} | :none) :: map() | nil
  def rule_control(:none), do: nil
  def rule_control({:switch, on?}), do: SettingsList.switch(on?)

  def rule_control({:value, text}) do
    ~MOB"""
    <Text
      text={text}
      font_family={Kati.Locale.mono_face(text)}
      text_size={12}
      text_color={Palette.meta()}
      max_lines={1}
    />
    """
  end

  @doc """
  The `Needs a decision` card — see `## The decision card` above for how this
  differs from `Kati.Screens.AutoDetect.decision/1`, the TV version it is
  built beside.
  """
  @spec decision(map()) :: map()
  def decision(d) do
    buttons =
      d.options
      |> Enum.map(fn o -> Kati.Screens.AutoDetectMusic.choice(o, o == d.chosen) end)
      |> Enum.intersperse(Kati.Screens.AutoDetectMusic.choice_gap())

    body = [
      text_size: 11.5,
      line_height: Kati.Locale.leading(1.5),
      text_color: Palette.sub(),
      font_family: Kati.Locale.face_prop(),
      base: true
    ]

    strong = [
      font_weight: "semibold",
      text_color: Palette.ink(),
      text_size: 11.5,
      line_height: Kati.Locale.leading(1.5),
      font_family: Kati.Locale.face_prop()
    ]

    # `pgettext/2` for the two short runs rather than `gettext/1`. Both are
    # fragments of a sentence split around its bold word — `which release` is
    # two words and the tail is a clause opening on a comma — and
    # `mix gettext.merge` fuzzy-matches a new short msgid against any longer
    # one that resembles it. The context says which sentence they belong to, so
    # neither can be handed the translation of some other board's `release`.
    paragraph =
      UI.rich_text([
        {gettext(
           "Music’s ambiguity is not TV’s: the same track on the studio album, a live record " <>
             "and a compilation. The three answers are"
         ) <> " ", body},
        {pgettext("music disambiguation", "which release"), strong},
        {pgettext("music disambiguation", ", not which title."), body}
      ])

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={22}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={17}
    >
      <Row fill_width={true} align="center">
        {Kati.Screens.AutoDetectMusic.art(d.seed, 40, 40, 11)}
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text text={d.question} text_size={13} font_weight="bold" text_color={:on_surface} />
          <Spacer size={4} />
          <Text text={d.sub} text_size={11.5} text_color={Palette.sub()} max_lines={1} />
        </Column>
      </Row>
      <Spacer size={13} />
      <Row fill_width={true} align="center">
        {buttons}
      </Row>
      <Spacer size={12} />
      {paragraph}
    </Column>
    """
  end

  @doc false
  def choice_gap, do: ~MOB"<Spacer size={8} />"

  @doc """
  One answer pill, 34pt, ink when it is the chosen release.

  The same `Kati.Components.MishkaToggle` call `Kati.Screens.AutoDetect.choice/2`
  makes — see that function's doc for the full case against `MishkaChip`
  (hugs its label, cannot split the row by weight) and
  `Kati.Components.MishkaSegmentedControl` (one continuous track, no gap
  between segments) and for the number-by-number account of why the pixels
  match. Same five props, same three colour pairs; only the three labels
  differ.
  """
  @spec choice(String.t(), boolean()) :: map()
  def choice(label, on?) do
    button =
      MishkaToggle.toggle(
        label: label,
        pressed: on?,
        color: Palette.ink_fill(),
        text_color: Palette.on_ink(),
        background: Palette.paper(),
        label_color: Palette.ink_soft(),
        corner_radius: 17,
        height: 34,
        padding: 0,
        border_width: 0,
        fill_width: true,
        align: :center,
        text_size: 11.5,
        font_weight: :semibold,
        max_lines: 1
      )

    ~MOB"""
    <Box weight={1.0}>
      {button}
    </Box>
    """
  end

  # `handle_tap/2` rather than a `handle_info/2` clause, for the reason
  # `Kati.Screens.AutoDetect`'s own comment on this gives: `Kati.Screens.Pushed`
  # owns `handle_info/2` and its `:back` clause, and overriding it here would
  # take the back pill with it.
  @impl true
  def handle_tap(:tv, socket) do
    {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.AutoDetect, %{})}
  end

  # The already-selected segment. There is no second state for this screen to
  # move to — `Music` is what it already is — so this answers with the socket
  # unchanged, the same way `Kati.Screens.LogWeight` answers a tap on its own
  # already-selected unit segment. Handled explicitly rather than left for
  # `Kati.Screens.Root.rescue_tap/3` to hit a missing clause on, because
  # `Segmented.plain/2` wires every segment's tap, selected one included.
  def handle_tap(:music, socket), do: {:noreply, socket}
end
