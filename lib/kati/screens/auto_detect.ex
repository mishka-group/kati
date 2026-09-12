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

  ## What this screen reads, and what `Kati.Settings.DetectSample` is now

  This section used to be headed *why this screen is still on
  `Kati.Settings.DetectSample`* and to end *detection is a feature that has not
  been built, not a screen that has not been wired* (MOVIES-AND-TV.md #115).
  It is built: `Kati.Media.Detect` holds the master switch and the threshold,
  reads what the phone is playing through `KatiMediaListener`, matches it
  against the reader's own shelf by name, ticks what it is sure of and turns
  what it is not into the question the queue card draws. `Kati.Media.Watch`
  carries `detected`, so `41 EPISODES TICKED FOR YOU` counts the ticks Kati
  made rather than every tick ever — the first of the two near misses below,
  and it is no longer one.

  The Sample is what a device with detection off or unavailable falls back to,
  which is the arrangement every other screen here keeps.

  The second near miss, kept because the next pass should not re-derive it:

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

  ## Which half of the copy this file owns, after the fold

  mishka-group/kati#103 folded the 33 Persian mirrors away, so this module is
  now board 36 in both languages and every word it writes has to come from
  `Kati.Gettext`. Two modules hold the words on this page and only one of them
  is this one — `Kati.Screens.AutoDetectMusic` says the same thing about board
  150 and its Sample, for the same reason.

  **This file owns the chrome and everything a device answers**: the 28pt
  title and the mono line under it, the three eyebrows, the banner's headline
  and its earned count, the *Now playing* pill and rule, the permission row and
  the threshold row, and the question an unplaced name becomes with its two
  answers. All of those are literals written here and all of them now go
  through `gettext/1`.

  **`Kati.Settings.DetectSample` owns the drawing**, and its words are still
  English literals: `3 sources`, `41 EPISODES TICKED FOR YOU`, *The Long
  Hollow* and its `S2E6 · LUMEN+ · APPLE TV`, the four source rows with their
  tick counts, the three rule rows, and the Marram question with its three
  answers. Those belong to that module the way `Kati.Music.Sample`'s tracklist
  belongs to it; inlining them here would put two copies of the drawing's copy
  in the repository, which is how a fixture and a screen start disagreeing
  about what the board says.

  What this file does for those strings is typeset them correctly whichever
  language they arrive in: every mono slot asks `Kati.Locale.mono_face/1` about
  the run it was handed rather than naming `mono` outright, and the elapsed
  clock is isolated so an RTL page cannot swap its two halves.
  """
  use Kati.Screens.Pushed, back: "Settings"
  use Gettext, backend: Kati.Gettext

  alias Kati.Components.MishkaProgress
  alias Kati.Components.MishkaToggle
  alias Kati.Settings.DetectSample, as: Sample
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @impl true
  def load(socket) do
    # Act on whatever is playing right now, before drawing. Opening this page
    # is the one moment a reader is asking Kati about detection, and a page
    # that showed a session at 97% and did not tick it would be the picture it
    # used to be. `Kati.App` drains what was recorded while the BEAM was dead;
    # this is the live half.
    _ = Kati.Media.Detect.sweep()

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
  def sources_line(:granted), do: gettext("watching this phone")
  def sources_line(_denied), do: gettext("not allowed to look yet")

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
      title: gettext("Detect what you play"),
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
  def ticked_line(0), do: gettext("NOTHING TICKED FOR YOU YET")

  # `ngettext/4` in place of the `1` clause and the interpolated one. Persian
  # does not inflect a noun after a numeral — `۱ قسمت` and `۴۱ قسمت` take the
  # same word — so the two forms are one sentence there and two here, which is
  # the whole of what a plural entry is for. A pattern match on `1` would have
  # to be repeated, wrongly, in every language that disagrees with English.
  #
  # `Kati.Locale.number/1` on the numeral because this line is set in the
  # reader's own script the moment it stops being ASCII: `banner/2` asks
  # `Kati.Locale.mono_face/1` about the finished string, so Persian words and
  # Persian digits travel into Vazirmatn together rather than leaving `41`
  # behind in a face the sentence around it is not in.
  def ticked_line(n) do
    ngettext(
      "%{n} EPISODE TICKED FOR YOU",
      "%{n} EPISODES TICKED FOR YOU",
      n,
      n: Kati.Locale.number(n)
    )
  end

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
      # `pgettext/2` for both: one word each, and `mix gettext.merge` fuzzy-
      # matches a msgid that short against any longer entry containing it —
      # the catalogue already holds three different `Paused` entries, each with
      # its own context, because a book, a shelf and a subscription do not
      # pause in the same word. A media session is a fourth.
      status:
        if(session.playing?,
          do: pgettext("now playing pill", "Live"),
          else: pgettext("now playing pill", "Paused")
        ),
      progress: (percent || 0) / 100,
      elapsed: Kati.Screens.AutoDetect.elapsed(session),
      rule: gettext("ticks at %{n}%", n: Kati.Locale.number(Kati.Media.Detect.threshold()))
    }
  end

  @doc false
  def session_meta(session) do
    [session.subtitle, Kati.Screens.AutoDetect.app_name(session.app)]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(" · ")
    # `Kati.UI.eyebrow_label/1` rather than `String.upcase/1`. The board sets
    # this line in caps — `S2E6 · LUMEN+ · APPLE TV` — and Arabic script has no
    # case at all, so upcasing a Persian episode title is a no-op that still
    # reads as one: it leaves the app name beside it shouting while the half
    # the reader is actually reading cannot. `eyebrow_label/1` upcases in Latin
    # and returns the Persian untouched, which is the rule every other eyebrow
    # in the app already follows.
    |> Kati.UI.eyebrow_label()
  end

  @doc """
  A package name as a person would say it.

  The last segment, capitalised — `com.netflix.mediaclient` is *Mediaclient*,
  which is wrong, so the handful worth naming are named and everything else
  falls back to the package. A wrong friendly name is worse than a package
  name: one is a mistake and the other is obviously a machine talking.

  None of the eight goes through `gettext/1` and none ever should. These are
  the names the services call themselves, the same rule board 127 draws
  `Lumen+` in Latin on a Persian page for: a transliteration would spell one
  thing two ways across the app, and the package fallback is an identifier
  rather than a word. `Kati.Locale.mono_face/1` is what makes them legible on
  a Persian page — they are pure ASCII, so they keep DM Mono in both scripts.

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
          # Two words, so `pgettext/2` — and the context is also the only thing
          # that separates this from `real_now_playing/1`'s *Live* pill, which
          # says the same fact about the same session in a different register.
          # English keeps them apart by word order and Persian need not; a
          # translator reading two bare msgids would have to guess which is the
          # pill and which is the row.
          sub: pgettext("a source Kati has heard from", "Playing now"),
          control: nil,
          # Nothing to open: this row reports what Kati heard rather than
          # offering a setting. An explicit `nil` because `row_tap/1` reads the
          # KEY — a row that carries one has answered, including with *none*.
          tap: nil
        }
      end)

    [
      %{
        icon: "phone_iphone",
        title: pgettext("detection source", "This phone"),
        sub: Kati.Screens.AutoDetect.access_line(access),
        control: if(access == :granted, do: {:switch, Kati.Media.Detect.on?()}, else: :chevron),
        # The row NAMES its tap rather than leaving `row/1` to recognise its
        # title. See `row_tap/1`: a title is a drawn string now, and a drawn
        # string is translated.
        tap: :open_media_access
      }
    ] ++ heard
  end

  @doc """
      iex> Kati.Screens.AutoDetect.access_line(:granted)
      "Detects audio from any app"
  """
  @spec access_line(atom()) :: String.t()
  def access_line(:granted), do: gettext("Detects audio from any app")
  def access_line(_denied), do: gettext("Needs notification access — tap to allow")

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
        # Two words and a preposition left dangling, which is exactly the kind
        # of msgid `mix gettext.merge` fuzzy-matches against a longer sentence.
        # The context also says what the row IS, which `Tick at` on its own
        # does not: a Persian translator reading the msgid alone cannot tell a
        # threshold from a time of day.
        title: pgettext("the detection threshold row", "Tick at"),
        # The same msgid `Kati.Screens.Library` writes over a progress bar, and
        # deliberately the same: one figure, one sentence, one entry. The
        # numeral goes through `Kati.Locale.number/1` because this is a sans
        # sub-line rather than a mono one, so Persian digits belong in it.
        sub: gettext("%{n}% watched", n: Kati.Locale.number(Kati.Media.Detect.threshold())),
        control: :chevron,
        tap: :cycle_threshold
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
        suggestions = Kati.Media.Detect.suggestions_for(title)

        %{
          seed: nil,
          heard: title,
          # `Kati.Locale.quoted/1` rather than a pair of `“…”` in the msgid.
          # A Persian reader meets the Latin curly quote as a foreign mark and
          # the guillemets as their own; `quoted/1` is where the app already
          # settles that, and keeping the marks out of the msgid means a
          # translator cannot accidentally drop one half of the pair.
          question:
            gettext("%{title} — is that something you keep?", title: Kati.Locale.quoted(title)),
          sub: Kati.Screens.AutoDetect.decision_sub(suggestions),
          suggestions: suggestions,
          # `{label, tag}` and not a bare label. The tag used to be DERIVED
          # from the label — see `answer_tag/1` — which is a lookup keyed on a
          # drawn string, and a drawn string is translated.
          options: [
            {gettext("Add it"), :answer_add_it},
            {gettext("Not mine"), :answer_not_mine}
          ],
          chosen: nil
        }
    end
  end

  @doc """
      iex> Kati.Screens.AutoDetect.decision_sub([])
      "Kati heard it play and found nothing on your shelf"

      iex> Kati.Screens.AutoDetect.decision_sub([%{title: "Frieren", tracked_id: "x"}])
      "Kati heard it play — tap the one it is, or add it"
  """
  @spec decision_sub([map()]) :: String.t()
  def decision_sub([]), do: gettext("Kati heard it play and found nothing on your shelf")
  def decision_sub(_some), do: gettext("Kati heard it play — tap the one it is, or add it")

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
        {SettingsList.title(gettext("Auto-detect"), d.sources_line, nil, :meta_tight)}
        {Kati.UI.Segmented.plain(Kati.Screens.AutoDetectMusic.modes(), :tv)}
        <Spacer size={20} />
        {Kati.Screens.AutoDetect.banner(d.banner, Kati.Screens.AutoDetect.live?(d))}
        {Kati.Screens.AutoDetect.playing_band(d)}
        {UI.eyebrow(gettext("Sources"))}
        {Kati.Screens.AutoDetect.group(d.sources)}
        {SettingsList.eyebrow_muted(gettext("Rules"))}
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
    # The meta line asks the STRING which face it needs rather than naming
    # `mono`: `kati_mono.ttf` carries no Persian glyph and none of U+06F0–U+06F9
    # either, so `۴۱ قسمت برایتان تیک خورد` set in it is handed to Android's own
    # substitute face beside sentences that are in Kati's. The board's own
    # `41 EPISODES TICKED FOR YOU` is pure ASCII and keeps DM Mono in both
    # scripts, which is what `test/design/screens/36.html` draws.
    #
    # Computed here rather than inside the sigil because `@b` there is an
    # ASSIGN, and an assign is what the whole map is for.
    assigns = %{
      b: b,
      meta_face: Kati.Locale.mono_face(b.meta),
      tap: if(live?, do: {self(), :toggle_detect})
    }

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
            font_family={@meta_face}
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
    # `41:02 / 55:00` is two number runs with a neutral ` / ` between them, and
    # a neutral that is not directly between two numbers takes the PARAGRAPH's
    # direction rather than theirs. Under `:fa` the page is RTL, so the bidi
    # algorithm lays the pair out right-to-left and the card reads
    # `55:00 / 41:02` — the elapsed and the duration swapped, the position of
    # the bar above it contradicted, and legible enough that nobody files it.
    # `Kati.Locale.ltr/1` opens an isolate around the run so the neutrals
    # resolve against it instead; it is a no-op in English.
    #
    # The FACE is asked of the raw string and not of the isolated one. U+2066
    # and U+2069 are not ASCII, so `mono_face/1` would answer `fa` for a clock
    # that is pure Latin digits and push it out of DM Mono — which is the one
    # thing board 36 and board 150 both keep in DM Mono in both scripts.
    elapsed = Kati.Locale.ltr(n.elapsed)
    elapsed_face = Kati.Locale.mono_face(n.elapsed)

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
              font_family={Kati.Locale.mono_face(n.meta)}
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
            text={elapsed}
            font_family={elapsed_face}
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
      eyebrow: UI.eyebrow(gettext("Now playing")),
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
      eyebrow: UI.eyebrow(gettext("Needs a decision")),
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
      on_tap: Kati.Screens.AutoDetect.row_tap(row)
    )
  end

  @doc """
  The tap a row carries: the one it names, or the one its title implies.

  `tap/1` recognised the row by its English TITLE, and mishka-group/kati#103 is
  what turns that shortcut into a defect: a title is a drawn string now, a
  drawn string goes through `gettext/1`, and under `:fa` *This phone* is
  **این گوشی** and *Tick at* is **تیک زدن در**. Every clause would fall through
  to `nil`, so the permission row and the threshold row lose their taps on
  exactly the page a reader opened in order to grant the permission — silently,
  because a row with no tap is indistinguishable from a row that never had one.
  `Kati.Retired`'s moduledoc states the same rule about tile names, and
  `Kati.Screens.RetiredTile.label/1` is the fix applied there.

  So the rows `real_sources/2` and `real_rules/0` build carry `:tap`
  themselves. `Kati.Settings.DetectSample`'s rows do not and will not: that
  module is the drawing, its words are English literals by design — see the
  moduledoc — and `tap/1` still reads them exactly as it always did. Hence two
  clauses rather than one rewritten lookup.
  """
  @spec row_tap(map()) :: {pid(), atom()} | nil
  # A row that carries the key at all has answered, and `nil` is an answer.
  def row_tap(%{tap: nil}), do: nil
  def row_tap(%{tap: tag}) when is_atom(tag), do: {self(), tag}
  def row_tap(row), do: Kati.Screens.AutoDetect.tap(row.title)

  @doc """
  The tap a DRAWN row carries, or `nil` for the rows that carry none.

  One row here promises something that is not in this version: **Browser
  extension**, drawn `Not installed` with a `Get` pill that led nowhere. That
  is the same dead control screen 42's dashed tiles were, and it gets the same
  answer — `Kati.Screens.RetiredTile`, the sheet that says *X isn't in this
  version* and why. #22 asks for the treatment to be applied consistently to
  exactly this row rather than left as a Health one-off.

  Matched on the title because that is what `Kati.Settings.DetectSample` keys
  its rows by; `nil` rather than an inert tag, so a row with nowhere to go
  draws no tap at all and `Kati.ScreenTapSweepTest` has nothing to report.

  These three literals are the Sample's OWN English and are not copy this
  module draws any more — `row_tap/1` reaches this only for a row that named no
  tap of its own, and the only such rows are the drawing's. So they stay
  Latin: translating them would key a lookup on one language and feed it
  another.
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
    suggestions = Kati.Screens.AutoDetect.suggestion_row(Map.get(d, :suggestions, []), live?)

    buttons =
      d.options
      |> Enum.map(fn o ->
        Kati.Screens.AutoDetect.choice(o, Kati.Screens.AutoDetect.chosen?(o, d.chosen), live?)
      end)
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
      {suggestions}
      <Spacer size={13} />
      <Row fill_width={true} align="center">
        {buttons}
      </Row>
    </Column>
    """
  end

  @doc """
  The titles Kati thinks it might be, as pills you tap to connect.

  The answer to *there is no shared id*, and to being handed a name and left to
  find it: `Kati.Media.Detect.Near` ranks the shelf against what was announced
  and the two or three best go here. Tapping one teaches Kati the name for good
  (`Kati.Media.TitleAlias`) and ticks it, because the queue only holds names
  that already passed the threshold.

  Nothing at all when the ranking has nothing above its floor. A row of bad
  guesses is worse than no row: it invites a wrong tap, and a wrong tap here
  writes both a watch and an alias that will keep being wrong.
  """
  @spec suggestion_row([map()], boolean()) :: map()
  def suggestion_row([], _live?), do: ~MOB"<Spacer size={0} />"

  def suggestion_row(suggestions, live?) do
    assigns = %{
      pills:
        suggestions
        |> Enum.with_index()
        |> Enum.map(fn {s, i} -> Kati.Screens.AutoDetect.suggestion(s, i, live?) end)
        |> Enum.intersperse(~MOB"<Spacer size={7} />")
    }

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={12} />
      <Row fill_width={true} align="center">
        {@pills}
      </Row>
    </Column>
    """
  end

  @doc false
  def suggestion(s, index, live?) do
    Kati.Components.MishkaPill.pill(
      label: s.title,
      background: Palette.paper(),
      color: :on_surface,
      height: 30,
      corner_radius: 15,
      padding: 0,
      padding_left: 12,
      padding_right: 12,
      text_size: 11.5,
      font_weight: :semibold,
      align: :center,
      max_lines: 1,
      on_tap: if(live?, do: {self(), String.to_atom("connect_#{index}")})
    )
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

  ## What an option is, since the labels stopped being English

  Either a bare label or a `{label, tag}` pair. `real_decision/0` writes the
  pair and `Kati.Settings.DetectSample` writes the bare label, and the bare
  clause derives its tag through `answer_tag/1` exactly as this always did —
  which is correct for the drawing and only for the drawing. `answer_tag/1`
  says why.
  """
  @spec choice(String.t() | {String.t(), atom()}, boolean(), boolean()) :: map()
  def choice(option, on?, live? \\ false)

  def choice(label, on?, live?) when is_binary(label) do
    tag = Kati.Screens.AutoDetect.answer_tag(label)

    Kati.Screens.AutoDetect.choice({label, tag}, on?, live?)
  end

  def choice({label, tag}, on?, live?) do
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
        #
        # The tag comes from the OPTION now and not from the label. See
        # `answer_tag/1`: a tag spelled out of a drawn string is a tag that
        # changes with the language.
        on_change: if(live?, do: {self(), tag}),
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

  @doc """
  Whether an answer is the one already chosen.

      iex> Kati.Screens.AutoDetect.chosen?({"Not mine", :answer_not_mine}, "Not mine")
      true

  Compares the LABEL half, because an option is either a bare label or a
  `{label, tag}` pair and `chosen` is a label in both cases — it is what the
  drawing records, and the drawing is the only thing that arrives with one
  already chosen.
  """
  @spec chosen?(String.t() | {String.t(), atom()}, String.t() | nil) :: boolean()
  def chosen?({label, _tag}, chosen), do: label == chosen
  def chosen?(label, chosen), do: label == chosen

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

  # Turn detection on, or off. MOVIES-AND-TV.md #100's master switch.
  #
  # Re-reads the whole screen rather than flipping the assign: the banner's
  # count, the Sources row's own switch and the *Now playing* card all follow
  # from this one setting, and a switch that moved alone would be the picture it
  # used to be with a different pixel lit.
  def handle_tap(:toggle_detect, socket) do
    Kati.Media.Detect.put(not Kati.Media.Detect.on?())

    {:noreply, Mob.Socket.assign(socket, :detect, Kati.Screens.AutoDetect.detect())}
  end

  # Open the page that grants notification access.
  #
  # There is no runtime dialog for `BIND_NOTIFICATION_LISTENER_SERVICE` —
  # `ACTION_NOTIFICATION_LISTENER_SETTINGS` is the whole of what an app may do,
  # and `K-44 open-settings` already carries it. So the row is a door rather than
  # a switch, which is also the honest shape: the reader grants this somewhere
  # Kati cannot reach.
  def handle_tap(:open_media_access, socket) do
    _ = Kati.Native.Links.settings(:notification_listener)

    {:noreply, socket}
  end

  # Step the threshold through the values a person would pick.
  #
  # A chevron row on the board, which promises a screen; four values do not want
  # one. 80, 90 and 95 are the three anybody means by *when does this count as
  # watched*, and the row says which is set.
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

  # Answer the unplaced name: keep it, or forget it.
  #
  # *Add it* opens the add sheet already searching for what was heard, which is
  # the one thing that would make the next play of it tick. *Not mine* forgets
  # the name — a question answered is a question gone.
  def handle_tap(:answer_add_it, socket) do
    heard = Kati.Screens.AutoDetect.asked_title(socket)
    Kati.Media.Detect.resolve(heard)

    {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.AddTitle, %{query: heard})}
  end

  def handle_tap(:answer_not_mine, socket) do
    Kati.Media.Detect.resolve(Kati.Screens.AutoDetect.asked_title(socket))

    {:noreply, Mob.Socket.assign(socket, :detect, Kati.Screens.AutoDetect.detect())}
  end

  def handle_tap(:open_music, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.AutoDetectMusic)}

  # `"Browser extension"` here is a KEY and not copy. `Kati.Screens.RetiredTile`
  # matches this exact English string in its `offsite/1` and then draws
  # `gettext("Browser extension")` in its own header — its comment there states
  # the pair in full: *the same string in English and two different jobs, which
  # is exactly why one of them is translated and the other cannot be*. Sending
  # a Persian key at a Latin match would fall through to the drawn subject and
  # open a sheet about Sleep.
  def handle_tap(:open_retired, socket) do
    {:noreply,
     Mob.Socket.push_screen(socket, Kati.Screens.RetiredTile, %{section: "Browser extension"})}
  end

  # Connect the heard name to the title the reader tapped.
  #
  # Writes the alias and the watch in one go — see `Kati.Media.Detect.connect/2`.
  # The reader has told Kati two things by tapping: what it was, and that they
  # watched it, because a name only reaches this queue by passing the threshold.
  def handle_tap(tag, socket) when is_atom(tag) do
    with "connect_" <> index <- Atom.to_string(tag),
         %{} = card <- Map.get(socket.assigns.detect, :decision),
         %{} = pick <- Enum.at(Map.get(card, :suggestions, []), String.to_integer(index)) do
      _ = Kati.Media.Detect.connect(Map.get(card, :heard, ""), pick.tracked_id)

      {:noreply, Mob.Socket.assign(socket, :detect, Kati.Screens.AutoDetect.detect())}
    else
      _not_a_connect -> {:noreply, socket}
    end
  end

  @doc """
  The tag a DRAWN answer pill sends, built from its own label.

      iex> Kati.Screens.AutoDetect.answer_tag("Not mine")
      :answer_not_mine

  This used to be how every answer got its tag, and mishka-group/kati#103 is
  what makes that wrong twice over. Under `:fa` *Not mine* is
  **مال من نیست**, so `String.to_atom("answer_" <> …)` mints an atom no
  `handle_tap/2` clause matches and the pill answers nothing — and it MINTS
  one, per label, per language, into a table that is never collected. A tag is
  a name in the program; a label is a word on a screen; the two stopped being
  the same string the day this screen had two languages.

  So `real_decision/0` names `:answer_add_it` and `:answer_not_mine` itself and
  this is what is left for `Kati.Settings.DetectSample`'s three English
  answers, which are the drawing's and never move.
  """
  @spec answer_tag(String.t()) :: atom()
  def answer_tag(label) do
    String.to_atom("answer_" <> (label |> String.downcase() |> String.replace(" ", "_")))
  end

  @doc false
  @spec asked_title(Mob.Socket.t()) :: String.t()
  def asked_title(socket) do
    case Kati.Media.Detect.unsure() do
      [title | _rest] ->
        title

      # `Map.get/2` and not `Map.get(…, %{})`. The `%{}` default was a fallback
      # that crashed when it was reached: an empty map is truthy, so
      # `&1 && &1.title` asked `%{}` for a key it has not got and raised
      # `KeyError` — the one path here that exists for the case where there is
      # nothing to name. It is unreachable today because `detect/0` always
      # writes `:now_playing`, which is why nothing has found it. `nil` falls
      # through the `&&` to the `""` the clause already meant to answer.
      [] ->
        Map.get(socket.assigns.detect, :now_playing) |> then(&(&1 && &1.title)) || ""
    end
  end
end
