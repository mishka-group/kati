defmodule Kati.Screens.AutoDetectMusic do
  @moduledoc """
  Screen 150 — Auto-detect, music mode, pushed under Settings.

  Built to `.scratch/design/incoming/150.html`, the sibling frame to screen
  36's `Kati.Screens.AutoDetect`. The board's own caption says this should be
  *"a mode on 36 rather than a second board"* — sources, rules and the
  disambiguation card are shared in spirit, and two boards risk drifting
  within a release. This file exists anyway, as its own module, because that
  is the shape this build pass asked for; the segmented control at the top is
  built to make the merge cheap later rather than to pretend it already
  happened. See `## Two boards, one switch` below for what that costs today.

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
  version would not have. Tapping `Music` while already on `Music` does
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
  the whole run gets one style, the longest run's, which for both paragraphs
  here is the plain body copy the bold word sits inside. The layout is
  correct; the emphasis is not drawn. That is the documented trade, not an
  oversight of this file's.

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

  Nothing on `.scratch/design/incoming/150.html`'s frame was left unbuilt.
  """

  use Kati.Screens.Pushed, back: "Settings"

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
        {SettingsList.title("Auto-detect", d.subtitle)}
        {Segmented.plain(Kati.Screens.AutoDetectMusic.modes(), :music)}
        <Spacer size={20} />
        {UI.eyebrow("Now playing — no art, the common case")}
        {Kati.Screens.AutoDetectMusic.now_playing(d.now_playing)}
        {Kati.Screens.AutoDetectMusic.with_art(d.with_art)}
        {SettingsList.eyebrow_muted("Which apps")}
        {Kati.Screens.AutoDetectMusic.apps_card(d.apps)}
        {Kati.Screens.AutoDetectMusic.apps_note()}
        {SettingsList.eyebrow_muted("Rules")}
        {Kati.Screens.AutoDetectMusic.rules_card(d.rules)}
        {UI.eyebrow("Needs a decision")}
        {Kati.Screens.AutoDetectMusic.decision(d.decision)}
      </Column>
    </Scroll>
    """
  end

  @doc "The header switch's two tags. `:music` is this screen; `:tv` is screen 36."
  @spec modes() :: [{String.t(), atom()}]
  def modes, do: [{"TV & film", :tv}, {"Music", :music}]

  @doc """
  The no-art now-playing card — the primary state, drawn first and in full.

  The elapsed bar is `Kati.Components.MishkaProgress` in `render={:box}` mode,
  the same call `Kati.Screens.AutoDetect.now_playing/1` makes and for the same
  reasons its doc gives in full: a `#E7E3DC` track no plain `<Progress>` prop
  reaches, a shared 5pt thickness and 3pt radius on both bars, and `max: 1`
  rather than scaling to 100 so `fraction/1` never round-trips a float through
  a multiply-then-divide.
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
              font_family="mono"
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
            font_family="mono"
            text_size={10.5}
            text_color={Palette.muted()}
            max_lines={1}
          />
          <Spacer weight={1.0} />
          <Text
            text={n.rule}
            font_family="mono"
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
  """
  @spec with_art(map()) :: map()
  def with_art(w) do
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
              text={String.upcase(w.eyebrow)}
              font_family="mono"
              text_size={9.5}
              letter_spacing={0.1}
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
  """
  @spec app_tile(String.t()) :: map()
  def app_tile(initial) do
    ~MOB"""
    <Box width={30} height={30} corner_radius={9} background={Palette.paper()} align="center">
      <Text
        text={initial}
        font_family="mono"
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
  """
  @spec apps_note() :: map()
  def apps_note do
    body = [
      text_size: 12.5,
      line_height: 1.65,
      text_color: Palette.ink_soft(),
      font_family: "sans"
    ]

    strong = [
      font_weight: "semibold",
      text_color: Palette.ink(),
      text_size: 12.5,
      line_height: 1.65,
      font_family: "sans"
    ]

    paragraph =
      UI.rich_text([
        {"A per-app list does not scale to a phone with twelve music apps, so ", body},
        {"Everything else", strong},
        {" is a single catch-all and the named rows are exceptions above it — on by default for " <>
           "the three Kati has seen.", body}
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
  """
  @spec rule_control({:value, String.t()} | {:switch, boolean()} | :none) :: map() | nil
  def rule_control(:none), do: nil
  def rule_control({:switch, on?}), do: SettingsList.switch(on?)

  def rule_control({:value, text}) do
    ~MOB"""
    <Text text={text} font_family="mono" text_size={12} text_color={Palette.meta()} max_lines={1} />
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

    body = [text_size: 11.5, line_height: 1.5, text_color: Palette.sub(), font_family: "sans"]

    strong = [
      font_weight: "semibold",
      text_color: Palette.ink(),
      text_size: 11.5,
      line_height: 1.5,
      font_family: "sans"
    ]

    paragraph =
      UI.rich_text([
        {"Music’s ambiguity is not TV’s: the same track on the studio album, a live record and " <>
           "a compilation. The three answers are ", body},
        {"which release", strong},
        {", not which title.", body}
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
