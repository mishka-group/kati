defmodule Kati.Screens.AutoDetect do
  @moduledoc """
  Screen 36 — Auto-detect, pushed under Settings.

  Built to `test/design/screens/36.html`. Manual ticking stays the
  default; this is the opt-in that removes it, and the screen is arranged as
  the argument for trusting it: the cream banner says how many episodes it has
  already ticked, Now playing shows the rule being applied live, and the last
  card is the one ambiguous match it refused to guess at.

  Rules carries the grey dash rather than the orange one — it qualifies the
  sources above it rather than announcing anything new.

  The "Needs a decision" card is the design's real point. An unsure match
  becomes a question instead of a tick, because a wrong tick pollutes a watch
  history nobody audits.

  No dock — pushed screen — so the frame closes at 40, not 132.

  ## Why this screen is still on `Kati.Settings.DetectSample`

  None of it has a resource. There is no row for the master switch, none for
  the per-source switches or their tick counts, none for the tick threshold,
  none for a playing session, and none for the queue of unsure matches — which
  is the card the whole screen is arranged around. Detection is a feature that
  has not been built, not a screen that has not been wired.

  Two near misses, so the next pass does not re-derive them:

    * **`41 EPISODES TICKED FOR YOU`.** `Kati.Media.Watch` holds the ticks, but
      it records no provenance — there is no column saying a tick was detected
      rather than tapped — so a count of every tick ever would be a different
      sentence wearing the same words.

    * **`S2E6 · LUMEN+ · APPLE TV`.** `Watch` has `service`, and the episode
      half can now be named — `Kati.Media.CachedEpisode` carries
      `season_number`, `episode_number` and `title` since
      `20260821231241_media_seasons_and_episodes`, which is what let
      `Kati.Screens.Series` and `Kati.Screens.Inbox` come off their Sample
      modules. **That is no longer the blocker here, and this bullet used to say
      it was.** What is missing is the other half: *Now playing* is a session in
      flight, and nothing anywhere holds one. `Watch` records a tick after the
      fact, so a screen reading it would be drawing something already finished
      under a heading that says it is happening.
  """
  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.Components.MishkaProgress
  alias Kati.Components.MishkaToggle
  alias Kati.Settings.DetectSample, as: Sample
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @impl true
  def load(socket) do
    Mob.Socket.assign(socket, :detect, Kati.Screens.AutoDetect.detect())
  end

  @doc """
  What this screen draws: the reader's own detection, or the drawing's.

  MOVIES-AND-TV.md #100 said ten of twelve controls were inert and the
  moduledoc above agreed with it and explained why — *detection is a feature
  that has not been built*. It is built now: `Kati.Media.Detect` reads what the
  phone is playing through `KatiMediaListener`, matches it against the shelf by
  name, and ticks past a threshold. So every one of these values is a real one.

  The board is what a device with no bridge draws — a host test, the gallery —
  because `Kati.Media.Detect.access/0` answers `:unavailable` there, and that
  is not the same as *denied*: nobody has refused anything.
  """
  @spec detect() :: map()
  def detect do
    access = Kati.Media.Detect.access()

    if access == :unavailable do
      Kati.Screens.AutoDetect.drawn_detect()
    else
      sessions = Kati.Media.Detect.sessions()

      %{
        sources_line: Kati.Screens.AutoDetect.sources_line(access),
        banner: Kati.Screens.AutoDetect.real_banner(),
        now_playing: Kati.Screens.AutoDetect.real_now_playing(sessions),
        sources: Kati.Screens.AutoDetect.real_sources(access, sessions),
        rules: Kati.Screens.AutoDetect.real_rules(),
        decision: Kati.Screens.AutoDetect.real_decision(),
        access: access
      }
    end
  end

  @doc "Screen 36 exactly as it is drawn."
  @spec drawn_detect() :: map()
  def drawn_detect do
    %{
      sources_line: Sample.sources_line(),
      banner: Sample.banner(),
      now_playing: Sample.now_playing(),
      sources: Sample.sources(),
      rules: Sample.rules(),
      decision: Sample.decision(),
      access: :unavailable
    }
  end

  @doc """
  The mono line under the title: what Kati may look at.

      iex> Kati.Screens.AutoDetect.sources_line(:denied)
      "not allowed to look yet"
  """
  @spec sources_line(atom()) :: String.t()
  def sources_line(:granted), do: "watching this phone"
  def sources_line(_denied), do: "not allowed to look yet"

  @doc """
  The cream banner: the master switch, and the count it earned.

  `41 EPISODES TICKED FOR YOU` was a literal over a column that did not exist
  — `Kati.Media.Watch` recorded no provenance at all, which the moduledoc
  named as one of two near misses. `20260907060000_add_watch_detected` is that
  column and this is the count.
  """
  @spec real_banner() :: map()
  def real_banner do
    count = Kati.Media.Detect.detected_count()

    %{
      title: "Detect what you play",
      meta: Kati.Screens.AutoDetect.ticked_line(count),
      on: Kati.Media.Detect.on?()
    }
  end

  @doc """
      iex> Kati.Screens.AutoDetect.ticked_line(0)
      "NOTHING TICKED FOR YOU YET"

      iex> Kati.Screens.AutoDetect.ticked_line(1)
      "1 EPISODE TICKED FOR YOU"
  """
  @spec ticked_line(non_neg_integer()) :: String.t()
  def ticked_line(0), do: "NOTHING TICKED FOR YOU YET"
  def ticked_line(1), do: "1 EPISODE TICKED FOR YOU"
  def ticked_line(n), do: "#{n} EPISODES TICKED FOR YOU"

  @doc """
  The *Now playing* card, or nothing at all.

  Nothing at all is the ordinary state of this card: a phone is not playing
  something most of the time. The board's own is a session in flight, and the
  moduledoc's second near miss was that nothing anywhere held one — this reads
  it from the device.
  """
  @spec real_now_playing([map()]) :: map() | nil
  def real_now_playing([]), do: nil

  def real_now_playing([session | _rest]) do
    percent = Kati.Media.Detect.progress(session)

    %{
      seed: nil,
      title: session.title,
      meta: Kati.Screens.AutoDetect.session_meta(session),
      status: if(session.playing?, do: "Live", else: "Paused"),
      progress: (percent || 0) / 100,
      elapsed: Kati.Screens.AutoDetect.elapsed(session),
      rule: "ticks at #{Kati.Media.Detect.threshold()}%"
    }
  end

  @doc false
  def session_meta(session) do
    [session.subtitle, Kati.Screens.AutoDetect.app_name(session.app)]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(" · ")
    |> String.upcase()
  end

  @doc """
  A package name as a person would say it.

  The last segment, capitalised — `com.netflix.mediaclient` is *Mediaclient*,
  which is wrong, so the handful worth naming are named and everything else
  falls back to the package. A wrong friendly name is worse than a package
  name: one is a mistake and the other is obviously a machine talking.

      iex> Kati.Screens.AutoDetect.app_name("com.netflix.mediaclient")
      "Netflix"

      iex> Kati.Screens.AutoDetect.app_name("org.example.player")
      "org.example.player"
  """
  @spec app_name(String.t()) :: String.t()
  def app_name("com.netflix.mediaclient"), do: "Netflix"
  def app_name("com.apple.atve.androidtv.appletv"), do: "Apple TV"
  def app_name("com.apple.android.music"), do: "Apple Music"
  def app_name("com.plexapp.android"), do: "Plex"
  def app_name("com.google.android.youtube"), do: "YouTube"
  def app_name("com.amazon.avod.thirdpartyclient"), do: "Prime Video"
  def app_name("com.disney.disneyplus"), do: "Disney+"
  def app_name("tv.jellyfin.mobile"), do: "Jellyfin"
  def app_name(package), do: package

  @doc false
  def elapsed(session) do
    "#{Kati.Screens.AutoDetect.clock(session.position_ms)} / " <>
      Kati.Screens.AutoDetect.clock(session.duration_ms)
  end

  @doc """
      iex> Kati.Screens.AutoDetect.clock(2_462_000)
      "41:02"

      iex> Kati.Screens.AutoDetect.clock(0)
      "—"
  """
  @spec clock(integer()) :: String.t()
  def clock(ms) when not is_integer(ms) or ms <= 0, do: "—"

  def clock(ms) do
    seconds = div(ms, 1000)

    "#{div(seconds, 60)}:#{String.pad_leading("#{rem(seconds, 60)}", 2, "0")}"
  end

  @doc """
  The Sources card: the permission, and whatever is actually playing.

  The board draws Apple TV, Chromecast, a browser extension and this phone,
  each with a tick count. Kati has one source — this phone, through the
  notification listener — and inventing three more would be the same claim the
  count above them was. So the card says what Kati may look at and names the
  apps it has actually heard from.
  """
  @spec real_sources(atom(), [map()]) :: [map()]
  def real_sources(access, sessions) do
    heard =
      sessions
      |> Enum.map(& &1.app)
      |> Enum.uniq()
      |> Enum.reject(&(&1 == ""))
      |> Enum.map(fn app ->
        %{
          icon: "play_circle",
          title: Kati.Screens.AutoDetect.app_name(app),
          sub: "Playing now",
          control: nil
        }
      end)

    [
      %{
        icon: "phone_iphone",
        title: "This phone",
        sub: Kati.Screens.AutoDetect.access_line(access),
        control: if(access == :granted, do: {:switch, Kati.Media.Detect.on?()}, else: :chevron)
      }
    ] ++ heard
  end

  @doc """
      iex> Kati.Screens.AutoDetect.access_line(:granted)
      "Detects audio from any app"
  """
  @spec access_line(atom()) :: String.t()
  def access_line(:granted), do: "Detects audio from any app"
  def access_line(_denied), do: "Needs notification access — tap to allow"

  @doc """
  The Rules card. Two of the board's three, and the third is dropped.

  *Tick at* is real and settable. *Ask before ticking* is not a switch: a match
  Kati cannot make is ALWAYS a question rather than a guess, which is the
  card below this one and the sentence board 36 is arranged around — offering
  to turn it off would be offering to let Kati guess. *Ignore trailers,
  anything under 5 min* is dropped because nothing records a runtime floor and
  a session with no duration is already never a tick.
  """
  @spec real_rules() :: [map()]
  def real_rules do
    [
      %{
        icon: "percent",
        title: "Tick at",
        sub: "#{Kati.Media.Detect.threshold()}% watched",
        control: :chevron
      }
    ]
  end

  @doc """
  The oldest thing Kati heard and could not place, or nothing.

  Board 36's *“Marram E3” or “Marram Grass”?* is a question between two titles
  the reader has. A real unplaced session is the other case and the commoner
  one: a name that matches nothing on the shelf. So the question is the honest
  one — *is this something you keep?* — and its answers are what a reader can
  actually do about it.
  """
  @spec real_decision() :: map() | nil
  def real_decision do
    case Kati.Media.Detect.unsure() do
      [] ->
        nil

      [title | _rest] ->
        %{
          seed: nil,
          question: "“#{title}” — is that something you keep?",
          sub: "Kati heard it play and found nothing on your shelf",
          options: ["Add it", "Not mine"],
          chosen: nil
        }
    end
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
        {SettingsList.chrome("more_horiz")}
        {SettingsList.title("Auto-detect", d.sources_line, nil, :meta_tight)}
        {Kati.UI.Segmented.plain(Kati.Screens.AutoDetectMusic.modes(), :tv)}
        <Spacer size={20} />
        {Kati.Screens.AutoDetect.banner(d.banner, Kati.Screens.AutoDetect.live?(d))}
        {Kati.Screens.AutoDetect.playing_band(d)}
        {UI.eyebrow("Sources")}
        {Kati.Screens.AutoDetect.group(d.sources)}
        {SettingsList.eyebrow_muted("Rules")}
        {Kati.Screens.AutoDetect.group(d.rules)}
        {Kati.Screens.AutoDetect.decision_band(d)}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The master switch, live over a device that can answer.

  MOVIES-AND-TV.md #100 called this *the master control of the feature*, drawn
  as a picture of an on switch. It is the whole of what `Kati.Media.Detect.on?/0`
  reads, and it is drawn OFF on a first run because nothing is detecting
  anything until somebody says so.

  Not tappable over the board, which is what a build with no bridge draws: a
  preference set on a device that cannot look is a preference about nothing.
  """
  @spec banner(map(), boolean()) :: map()
  def banner(b, live? \\ false) do
    assigns = %{b: b, tap: if(live?, do: {self(), :toggle_detect})}

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.cream()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={18}
        align="center"
        on_tap={@tap}
      >
        {Kati.UI.symbol("sensors", size: 24, color: Palette.gold_icon())}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text
            text={@b.title}
            text_size={14.5}
            font_weight="bold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={4} />
          <Text
            text={@b.meta}
            font_family="mono"
            text_size={10.5}
            text_color={Palette.cream_meta()}
            max_lines={1}
          />
        </Column>
        <Spacer size={12} />
        {SettingsList.switch(@b.on)}
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The Now playing card, with the elapsed bar drawn by
  `Kati.Components.MishkaProgress` in its `render={:box}` mode.

  The three things this bar needs were all things `<Progress>` has no prop for
  — a `#E7E3DC` track (`MobProgress` passes `color` and nothing else, so the
  groove stays whatever `ProgressIndicatorDefaults.linearTrackColor` resolves
  to), a 5pt thickness on the track *and* the fill, and a 3pt radius on both.
  `render={:box}` draws the same two weighted cells this file used to write by
  hand, from the same numbers, so the component is now the one that owns them.

  ## Why the pixels do not move

  Serialising both trees and diffing them key by key, every node and every prop
  matches — the track `Box` (`fill_width`, `height: 5`, `corner_radius: 3`,
  `background:` the track token, `0xFFE7E3DC` in light), the `fill_width` `Row`
  inside it, the fill `Box`
  (`weight: 0.74`, `height: 5`, `corner_radius: 3`, `background:` ink) and the
  remainder `<Spacer weight={0.26} />`. One node differs: the component appends
  a `<Spacer size={5} />` as a second child of the track. It is the iOS
  workaround its moduledoc documents — `MobBox` drops a childless Box's height
  — and on this bridge it is a 4-prop-less, background-less 5x5 Spacer laid at
  the track's `Alignment.TopStart` inside a Box that already carries
  `fillMaxWidth().height(5.dp)`, so it paints nothing and cannot resize
  anything.

  `max: 1` rather than `value: progress * 100`: `fraction/1` is then
  `(v - 0) / 1`, which returns the identical float. Scaling by 100 and back
  does not — `0.62 * 100 / 100` is `0.6200000000000001`.

  ## Both ends were checked

  The hand-rolled version was one sample value away from killing the activity:
  at `progress: 0.0` it emitted `<Box weight={0.0}>` and at `1.0` a
  `<Spacer weight={0.0} />`, and Compose throws on either — *"invalid weight
  0.0; must be greater than zero"*. The component omits the node instead: at
  `0.0` there is no fill and the remainder carries `weight: 1.0`; at `1.0`
  there is no remainder and the fill carries `weight: 1.0`. Neither end emits a
  zero. Today's sample is `0.74`, so this is a latent crash removed rather than
  a live one fixed.
  """
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
        padding={15}
      >
        <Row fill_width={true} align="center">
          {Kati.Screens.AutoDetect.poster(n.seed, 44, 62, 9)}
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
          <Spacer size={12} />
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
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def poster(seed, w, h, radius) do
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

  @doc """
  Whether this screen is looking at a device that can answer.

      iex> Kati.Screens.AutoDetect.live?(Kati.Screens.AutoDetect.drawn_detect())
      false
  """
  @spec live?(map()) :: boolean()
  def live?(detect), do: Map.get(detect, :access, :unavailable) != :unavailable

  @doc """
  *Now playing*, or nothing at all.

  Nothing at all is the ordinary state: a phone is not playing something most
  of the time, and an eyebrow over a card describing nothing is the gap this
  round drops everywhere else. The board always has one, which is what the
  board is a drawing of.
  """
  @spec playing_band(map()) :: map()
  def playing_band(%{now_playing: nil}), do: ~MOB"<Spacer size={0} />"

  def playing_band(d) do
    assigns = %{
      eyebrow: UI.eyebrow("Now playing"),
      card: Kati.Screens.AutoDetect.now_playing(d.now_playing)
    }

    ~MOB"""
    <Column fill_width={true}>
      {@eyebrow}
      {@card}
    </Column>
    """
  end

  @doc """
  *Needs a decision*, or nothing at all.

  Same rule, and here it is also what stops the screen dying: `decision/1`
  reads `d.question` and a device that has heard nothing it could not place has
  no decision to draw.
  """
  @spec decision_band(map()) :: map()
  def decision_band(%{decision: nil}), do: ~MOB"<Spacer size={0} />"

  def decision_band(d) do
    assigns = %{
      eyebrow: UI.eyebrow("Needs a decision"),
      card: Kati.Screens.AutoDetect.decision(d.decision, Kati.Screens.AutoDetect.live?(d))
    }

    ~MOB"""
    <Column fill_width={true}>
      {@eyebrow}
      {@card}
    </Column>
    """
  end

  @doc false
  def group(rows) do
    last = length(rows) - 1

    body =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, i} -> Kati.Screens.AutoDetect.row(row, i < last) end)

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(body)}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def row(row, rule?) do
    SettingsList.row(
      SettingsList.icon_tile(row.icon),
      SettingsList.body(row.title, row.sub),
      Kati.Screens.AutoDetect.control(row.control),
      padding: 13,
      rule: rule?,
      on_tap: Kati.Screens.AutoDetect.tap(row.title)
    )
  end

  @doc """
  The tap a row carries, or `nil` for the rows that carry none.

  One row here promises something that is not in this version: **Browser
  extension**, drawn `Not installed` with a `Get` pill that led nowhere. That
  is the same dead control screen 42's dashed tiles were, and it gets the same
  answer — `Kati.Screens.RetiredTile`, the sheet that says *X isn't in this
  version* and why. #22 asks for the treatment to be applied consistently to
  exactly this row rather than left as a Health one-off.

  Matched on the title because that is what `Kati.Settings.DetectSample` keys
  its rows by; `nil` rather than an inert tag, so a row with nowhere to go
  draws no tap at all and `Kati.ScreenTapSweepTest` has nothing to report.
  """
  @spec tap(String.t()) :: {pid(), atom()} | nil
  def tap("Browser extension"), do: {self(), :open_retired}
  # #100's two, and both are the row's whole point. *This phone* is the
  # permission — there is no runtime dialog for a notification listener, so the
  # row opens the system page that grants it — and *Tick at* is the threshold
  # `Kati.Media.Detect.threshold/0` reads.
  def tap("This phone"), do: {self(), :open_media_access}
  def tap("Tick at"), do: {self(), :cycle_threshold}
  def tap(_title), do: nil

  @doc false
  def control(nil), do: ~MOB"<Spacer size={0} />"
  def control(:chevron), do: SettingsList.chevron()
  def control({:switch, on?}), do: SettingsList.switch(on?)
  def control({:pill, label}), do: SettingsList.action_pill(label)

  @doc false
  def decision(d, live? \\ false) do
    buttons =
      d.options
      |> Enum.map(fn o -> Kati.Screens.AutoDetect.choice(o, o == d.chosen, live?) end)
      |> Enum.intersperse(Kati.Screens.AutoDetect.choice_gap())

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={15}
    >
      <Row fill_width={true} align="center">
        {Kati.Screens.AutoDetect.poster(d.seed, 36, 51, 7)}
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
    </Column>
    """
  end

  @doc false
  def choice_gap, do: ~MOB"<Spacer size={8} />"

  @doc """
  One answer to the ambiguous match: a 34pt pill, ink when it is the chosen one.

  `Kati.Components.MishkaToggle` — "a square-cornered button that looks pushed
  in", except that every dimension it draws is a prop, so the corners are as
  round as the drawing says. It is the component's own documented use: the
  moduledoc's showcase builds a segmented bar out of nothing but these props,
  and three mutually exclusive answers drawn as three separate pressed pills is
  that bar.

  ## Why not the chip, and why not the segmented control

  `Kati.Components.MishkaChip` is the closer name — the sample is a radio set,
  one of `["The series", "The film", "Neither"]` chosen, and the chip's docs
  spell out the radio case. It cannot be used: the chip's root `Box` hardcodes
  `fill_width={false}` with no prop to override it, so a chip always hugs its
  label. These three split the card's width by weight, and a hugging chip leaves
  the row three short pills and a gap.

  `Kati.Components.MishkaSegmentedControl` is the wrong shape. It draws one
  continuous track with the segments inside it, and the drawing has no track at
  all: three separate pills with 8pt of card showing between them. The control
  has `track_padding` but no inter-segment gap, so its segments butt together —
  there is no combination of props that opens 8pt between them.

  ## The numbers

  Padding is applied before height, and the toggle's `padding` default is
  `:space_sm`, so `height: 34` alone would measure 34 plus two paddings.
  `padding: 0` pins the outer 34. `border_width: 0` removes the component's
  default hairline: the bridge draws a border only when `borderColor != null &&
  borderWidth > 0f`, so the `border_color: :border` the component still writes
  paints nothing.

  ## Why the pixels do not move

  The `<Box weight={1.0}>` wrapper is untouched — the toggle exposes no `weight`
  and this is the node that splits the row — so only its child changes, from a
  `Row` to the toggle's `Box`:

      <Box fill_width={true} height={34} corner_radius={17}
           background={bg} align={:center} padding={0}
           border_color={:border} border_width={0}>
        <Text text={label} text_size={11.5} font_weight={:semibold}
              text_color={fg} max_lines={1} />
      </Box>

  against the `<Row fill_width={true} height={34} corner_radius={17}
  background={bg} align="center">` it replaces. Five props are the same five
  values; the three extra ones are the no-ops above.

  `nodeModifier` is one function for every node type, so the background, the
  radius and the height are applied by the same chain either way, and both
  containers fill the weighted slot: the `Row` because `fill_width={true}`, the
  `Box` because fence K-17's `hugs = boolProp(props, "fill_width") == false` is
  false when the prop is true, leaving `m.fillMaxWidth()`.

  What changes is how the label is centred. The `Row` did it with two
  `weight={1.0}` `Spacer`s horizontally and `align="center"` vertically; the
  `Box` does both with `contentAlignment`, since `align: :center` and
  `align="center"` reach the bridge as the same string — `align` is in none of
  the renderer's token whitelists, so an unrecognised atom passes through and
  `:json.encode/1` writes an atom as its own name. A single child centred in a
  box of the same width lands where two equal weights put it.

  The three colour props map one for one onto what the two branches computed:
  `color` and `text_color` are the pressed pair — `Palette.ink_fill/0` under
  `Palette.on_ink/0`, `#1A1917` / `#FBFAF8` in light, the pair screen 28 draws
  for the hero's CTA pill — `background` and `label_color` the idle pair
  (`Palette.paper/0` / `Palette.ink_soft/0`, `#EFECE7` / `#5C574F`), and
  `pressed` picks between them exactly as the `if` did.
  """
  def choice(label, on?, live? \\ false) do
    button =
      MishkaToggle.toggle(
        label: label,
        pressed: on?,
        # `on_change`, not `on_tap`: `Kati.Components.MishkaToggle` takes the
        # handler under that name and wires it onto the node itself — a toggle
        # that is pressed IS a change. Passing `on_tap` puts an unread key in
        # the props map and draws the same dead pill, which is how the first
        # version of this shipped.
        #
        # MOVIES-AND-TV.md #100's last dead control. The board draws three
        # answers to an ambiguous match and none of them carried a tap, so the
        # card the whole screen is arranged around — *a wrong tick pollutes a
        # watch history nobody audits* — could not be answered.
        on_change: if(live?, do: {self(), Kati.Screens.AutoDetect.answer_tag(label)}),
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

  # `handle_tap/2` rather than a `handle_info/2` clause: `Kati.Screens.Pushed`
  # owns `handle_info/2` and its `:back` clause, and overriding it here would
  # take the back pill with it.
  # #20 draws the music half of this screen as a MODE of it rather than as a
  # second screen — the sources, rules and disambiguation card are shared, and
  # two boards would drift within a release. The switch itself is drawn on 150.
  @impl true
  @doc """
  The music mode, which this screen had a handler for and no control.

  `Kati.Screens.AutoDetectMusic` is board 150, and its own caption calls the
  entry a *"segmented control under the title"* — TV & film against Music. 150
  draws that control; 36 did not, so `:open_music` sat here answering a tag
  nothing emitted and `Kati.ScreenTapSweepTest` never saw it, because a handler
  with no control is not a control the sweep can tap.

  The pair is now drawn on both sides, which is what the design says: one
  segmented control, two modes, either of which can be the one you are on.
  """
  def handle_tap(:music, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.AutoDetectMusic)}

  # The already-selected segment. `Kati.Screens.AutoDetectMusic` answers its own
  # the same way and says why: there is no second state for a screen to move to
  # when you tap the mode you are already in, and a segment that did nothing at
  # all would read as a broken control rather than as a settled one.
  def handle_tap(:tv, socket), do: {:noreply, socket}

  @doc """
  Turn detection on, or off. MOVIES-AND-TV.md #100's master switch.

  Re-reads the whole screen rather than flipping the assign: the banner's
  count, the Sources row's own switch and the *Now playing* card all follow
  from this one setting, and a switch that moved alone would be the picture it
  used to be with a different pixel lit.
  """
  def handle_tap(:toggle_detect, socket) do
    Kati.Media.Detect.put(not Kati.Media.Detect.on?())

    {:noreply, Mob.Socket.assign(socket, :detect, Kati.Screens.AutoDetect.detect())}
  end

  @doc """
  Open the page that grants notification access.

  There is no runtime dialog for `BIND_NOTIFICATION_LISTENER_SERVICE` —
  `ACTION_NOTIFICATION_LISTENER_SETTINGS` is the whole of what an app may do,
  and `K-44 open-settings` already carries it. So the row is a door rather than
  a switch, which is also the honest shape: the reader grants this somewhere
  Kati cannot reach.
  """
  def handle_tap(:open_media_access, socket) do
    _ = Kati.Native.Links.settings(:notification_listener)

    {:noreply, socket}
  end

  @doc """
  Step the threshold through the values a person would pick.

  A chevron row on the board, which promises a screen; four values do not want
  one. 80, 90 and 95 are the three anybody means by *when does this count as
  watched*, and the row says which is set.
  """
  def handle_tap(:cycle_threshold, socket) do
    next =
      case Kati.Media.Detect.threshold() do
        80 -> 90
        90 -> 95
        _other -> 80
      end

    Kati.Media.Detect.put_threshold(next)

    {:noreply, Mob.Socket.assign(socket, :detect, Kati.Screens.AutoDetect.detect())}
  end

  @doc """
  Answer the unplaced name: keep it, or forget it.

  *Add it* opens the add sheet already searching for what was heard, which is
  the one thing that would make the next play of it tick. *Not mine* forgets
  the name — a question answered is a question gone.
  """
  def handle_tap(:answer_add_it, socket) do
    heard = Kati.Screens.AutoDetect.asked_title(socket)
    Kati.Media.Detect.resolve(heard)

    {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.AddTitle, %{query: heard})}
  end

  def handle_tap(:answer_not_mine, socket) do
    Kati.Media.Detect.resolve(Kati.Screens.AutoDetect.asked_title(socket))

    {:noreply, Mob.Socket.assign(socket, :detect, Kati.Screens.AutoDetect.detect())}
  end

  @doc """
  The tag an answer pill sends, built from its own label.

      iex> Kati.Screens.AutoDetect.answer_tag("Not mine")
      :answer_not_mine
  """
  @spec answer_tag(String.t()) :: atom()
  def answer_tag(label) do
    String.to_atom("answer_" <> (label |> String.downcase() |> String.replace(" ", "_")))
  end

  @doc false
  @spec asked_title(Mob.Socket.t()) :: String.t()
  def asked_title(socket) do
    case Kati.Media.Detect.unsure() do
      [title | _rest] -> title
      [] -> Map.get(socket.assigns.detect, :now_playing, %{}) |> then(&(&1 && &1.title)) || ""
    end
  end

  def handle_tap(:open_music, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.AutoDetectMusic)}

  def handle_tap(:open_retired, socket) do
    {:noreply,
     Mob.Socket.push_screen(socket, Kati.Screens.RetiredTile, %{section: "Browser extension"})}
  end
end
