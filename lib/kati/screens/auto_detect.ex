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

  ## What this screen reads

  Every value a reader sees is read, and nothing falls back to the drawing:

    * **the subtitle** — `sources_line/2`, from `Kati.Media.Detect.access/0`
      and the master switch: *watching this phone*, *allowed, switched off*,
      or *not allowed to look yet*.
    * **the access notice** — `access_notice/1`, drawn whenever access is not
      granted. Detection reads media sessions through Android's
      notification-listener grant, and Play Protect blocks that grant for an
      app installed outside the Play Store, which is how most copies of Kati
      are installed. The feature is kept because it works where the grant is
      given; the page says plainly when it is not, with a door to screen 151
      (how to allow it) and a door to logging by hand (`Kati.Screens.Search`,
      scoped to the Screen shelf — see `Kati.Screens.NotificationAccess`).
    * **the banner** — the master switch is `Kati.Media.Detect.on?/0`, stored
      in `Mob.State` and read by `Kati.Media.Detect.sweep/0` and `drain/0`,
      which do nothing while it is off. Its meta line is
      `Kati.Media.Detect.detected_count/0`, the `Kati.Media.Watch` rows marked
      `detected`.
    * **Now playing** — the first live media session, or no card at all.
    * **Sources** — *This phone*, whose sub-line is the grant and whose tap
      opens screen 151, then one row per app Kati has actually heard play.
    * **Rules** — one row, *Tick at*: `Kati.Media.Detect.threshold/0`, the
      percentage `Kati.Media.Detect.verdict/1` compares a session against.
      Board 36's *Ask before ticking* and *Ignore trailers* rows are not
      drawn: nothing stores either and no code reads one.
    * **Needs a decision** — the oldest name `Kati.Media.Detect.unsure/0`
      holds, or no card at all.

  Board 36 also draws a TV & film / Music segmented control that leads to
  board 150 (`Kati.Screens.AutoDetectMusic`). It is not drawn: Kati has no
  music detection and music is outside the film and series scope, so 150 is
  reachable from the development gallery only.

  Board 36's own values — `3 sources`, `41 EPISODES TICKED FOR YOU`, *The Long
  Hollow* playing, four sources with tick counts, three rules and the Marram
  question — live with the test that compares the frame
  (`Kati.DesignLiterals.detect_board/0`). Nothing in `lib/` holds them, and the
  rows that only the drawing had — Apple TV, Chromecast, the browser extension
  with its `Get` pill, *Ask before ticking*, *Ignore trailers* — are not drawn
  on any device, because nothing detects through them or stores them.

  ## Two languages

  Every word this file writes goes through `Kati.Gettext`. What stays Latin is
  a service's name for itself (`app_name/1` carries the argument), and every
  Latin name inside a line that can be Persian is isolated with
  `Kati.Locale.ltr/1`, so an RTL page cannot move its trailing mark. Every mono
  slot asks `Kati.Locale.mono_face/1` about the run it was handed rather than
  naming `mono` outright.
  """
  use Kati.Screens.Pushed, back: "Settings"
  use Gettext, backend: Kati.Gettext

  alias Kati.Components.MishkaProgress
  alias Kati.Components.MishkaToggle
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @doc """
  Acts on whatever is playing right now, then reads the page.

  Opening this page is the one moment a reader is asking Kati about
  detection, so `Kati.Media.Detect.sweep/0` runs first: a page that showed a
  session at 97% and did not tick it would be wrong about itself. The sweep
  does nothing while the switch is off or access is not granted. `Kati.App`
  drains what the listener recorded while the BEAM was not running; this is
  the live half.
  """
  @impl true
  def load(socket) do
    _ = Kati.Media.Detect.sweep()

    Mob.Socket.assign(socket, :detect, Kati.Screens.AutoDetect.detect())
  end

  @doc """
  What this screen draws, read from the device and the store.

  There is no branch on `:unavailable`, the answer on a build with no bridge
  (a host test, the gallery on a host). Every function below takes `access`
  and says what it means, so a phone that has not granted access sees its own
  state rather than board 36.
  """
  @spec detect() :: map()
  def detect do
    access = Kati.Media.Detect.access()
    sessions = Kati.Media.Detect.sessions()

    %{
      sources_line: Kati.Screens.AutoDetect.sources_line(access, Kati.Media.Detect.on?()),
      banner: Kati.Screens.AutoDetect.real_banner(),
      now_playing: Kati.Screens.AutoDetect.real_now_playing(sessions),
      sources: Kati.Screens.AutoDetect.real_sources(access, sessions),
      rules: Kati.Screens.AutoDetect.real_rules(),
      decision: Kati.Screens.AutoDetect.real_decision(),
      access: access
    }
  end

  @doc """
  The mono line under the title: what Kati may look at, and whether it is.

      iex> Kati.Screens.AutoDetect.sources_line(:denied, true)
      "not allowed to look yet"

      iex> Kati.Screens.AutoDetect.sources_line(:granted, false)
      "allowed, switched off"

      iex> Kati.Screens.AutoDetect.sources_line(:granted, true)
      "watching this phone"
  """
  @spec sources_line(atom(), boolean()) :: String.t()
  def sources_line(:granted, true), do: gettext("watching this phone")
  def sources_line(:granted, _off), do: gettext("allowed, switched off")
  def sources_line(_not_granted, _on?), do: gettext("not allowed to look yet")

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
    # `Kati.Locale.ltr/1` around the app name: a name
    # that ends in a NEUTRAL has that character resolved against the PARAGRAPH
    # rather than against the run it belongs to, so under `:fa` the mark jumps
    # to the far side and the line reads `+Disney`. `Disney+` is the one of
    # `app_name/1`'s eight that ends in a mark, and the package fallback can
    # end in anything at all — it is whatever the phone announced.
    #
    # Isolated AFTER the empty check and not before it: under `:fa`
    # `Kati.Locale.ltr("")` is U+2066 followed by U+2069, which is two
    # characters rather than `""`, so a session that named no package would
    # survive `Enum.reject/2` and leave the line a dangling ` · ` with nothing
    # after it.
    app = Kati.Screens.AutoDetect.app_name(session.app)

    [session.subtitle, if(app == "", do: nil, else: Kati.Locale.ltr(app))]
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

  *This phone* carries a chevron in every state, because its tap opens screen
  151 in every state. It used to draw a switch once access was granted, which
  was a second picture of the banner's switch that opened a page instead of
  switching anything. The row names its own `:tap` rather than leaving
  `row_tap/1` to recognise its translated title.
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
          # `Kati.Locale.ltr/1` even though a row title is the whole of its own
          # `<Text>`: a lone title has no Persian run beside it, but a name
          # that ends in a neutral still resolves against the page. A paragraph takes the PAGE's
          # direction whatever is in it, so under `:fa` the trailing `+` of
          # `Disney+` resolves right-to-left and the row reads `+Disney`. The
          # package fallback is the other half: it is whatever the phone
          # announced and can end in any character at all.
          title: Kati.Locale.ltr(Kati.Screens.AutoDetect.app_name(app)),
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
        control: :chevron,
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
          #
          # `Kati.Locale.ltr/1` INSIDE the marks and not around them. What a
          # media app announced is arbitrary text — `9-1-1` and `S.W.A.T.` are
          # two real ones — and a Latin run made largely of neutrals dropped
          # into a Persian sentence has every one of them resolved against the
          # page: the hyphens and the stops land at the wrong edge of the name
          # the reader is being asked about. The quotation marks belong to the
          # Persian sentence rather than to the name, so they stay outside the
          # isolate; `Kati.Screens.Service` wraps a service's own name the same
          # way, and `Kati.Screens.MedicationDetail` a medicine the reader
          # typed.
          question:
            gettext("%{title} — is that something you keep?",
              title: Kati.Locale.quoted(Kati.Locale.ltr(title))
            ),
          sub: Kati.Screens.AutoDetect.decision_sub(suggestions),
          suggestions: suggestions,
          # `{label, tag}` and not a bare label: a tag derived from the label
          # would be a lookup keyed on a drawn string, and a drawn string is
          # translated.
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
        {SettingsList.chrome(nil)}
        {SettingsList.title(gettext("Auto-detect"), d.sources_line, nil, :meta_tight)}
        <Spacer size={20} />
        {Kati.Screens.AutoDetect.access_notice(Map.get(d, :access, :unavailable))}
        {Kati.Screens.AutoDetect.banner(d.banner, Kati.Screens.AutoDetect.banner_tap(d))}
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
  What a device that cannot look is told, or nothing when it can.

  Detection needs Android's notification-listener grant, and Play Protect
  blocks that grant for an app installed outside the Play Store. So on most
  phones this is the state the page opens in, and it says so in words rather
  than leaving a reader to wonder why nothing ticks. Two doors: screen 151,
  which explains the grant and opens the system page that gives it, and
  logging by hand, which is `Kati.Screens.NotificationAccess.log_by_hand/2`.

  Nothing when access is granted.
  """
  @spec access_notice(atom()) :: map()
  def access_notice(:granted), do: ~MOB"<Spacer size={0} />"

  def access_notice(_not_granted) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={17}
      >
        <Row fill_width={true} align="top">
          {Kati.UI.symbol("notifications_off", size: 19, color: Palette.gold_icon())}
          <Spacer size={11} />
          <Column weight={1.0}>
            <Text
              text={gettext("Kati cannot see what you play yet")}
              text_size={13.5}
              font_weight="bold"
              text_color={:on_surface}
            />
            <Spacer size={6} />
            <Text
              text={gettext("Detection needs notification access, which only you can allow, in Android’s settings. Some phones block it for apps installed outside the Play Store — if yours does, log what you watch by hand.")}
              text_size={12.5}
              line_height={Kati.Locale.leading(1.65)}
              text_color={Palette.ink_soft()}
            />
          </Column>
        </Row>
        <Spacer size={14} />
        <Row align="center">
          {SettingsList.action_pill(gettext("How to allow it"), {self(), :how_to_allow})}
          <Spacer size={8} />
          {SettingsList.action_pill(gettext("Log by hand instead"), {self(), :log_by_hand})}
        </Row>
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  What tapping the banner does, from the grant.

  Granted: flips the master switch. Not granted: opens screen 151, because a
  switch Kati cannot act on is a preference about nothing, and the page that
  explains the grant is what the reader needs. No bridge at all (a host test):
  nothing.

      iex> Kati.Screens.AutoDetect.banner_tap(%{access: :unavailable})
      nil
  """
  @spec banner_tap(map()) :: atom() | nil
  def banner_tap(%{access: :granted}), do: :toggle_detect
  def banner_tap(%{access: :denied}), do: :allow_to_detect
  def banner_tap(_no_bridge), do: nil

  @doc """
  The master switch and the count of ticks it earned.

  The switch is `Kati.Media.Detect.on?/0`, drawn off on a first run because
  nothing detects anything until somebody says so. `tap` is `banner_tap/1`'s
  answer.

  The meta line asks the string which face it needs rather than naming
  `mono`: `kati_mono.ttf` carries no Persian glyph, so a Persian count set in
  it would fall back to Android's substitute face.
  """
  @spec banner(map(), atom() | nil) :: map()
  def banner(b, tap \\ nil) do
    assigns = %{
      b: b,
      meta_face: Kati.Locale.mono_face(b.meta),
      tap: if(tap, do: {self(), tap})
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

    # The meta's face is asked the same question, and the isolates have to come
    # out of the string before it is asked. Both producers wrap a service name
    # in `Kati.Locale.ltr/1` — `session_meta/1` does, because `Disney+` ends in
    # a mark — so a finished meta can carry U+2066 around a run that is otherwise pure
    # ASCII. Handing that to `mono_face/1` would answer `fa` for
    # `S2E6 · NETFLIX` and push a Latin eyebrow out of DM Mono, which is the
    # one run boards 36 and 150 both keep there in both scripts. Stripping the
    # two isolates asks the question about the characters a reader can see.
    # Escapes rather than the characters themselves, which is how
    # `Kati.Locale.ltr/1` writes the same two: an isolate is invisible, and a
    # pair of them sitting in a source line is a line nobody can review.
    meta_face = Kati.Locale.mono_face(String.replace(n.meta, ["\u2066", "\u2069"], ""))

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
              font_family={meta_face}
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

      iex> Kati.Screens.AutoDetect.live?(%{access: :unavailable})
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
  The tap a row carries: the one it names, and `nil` names none.

  Keyed on the row's own `:tap` and never on its title. A title is a drawn
  string, and under `:fa` *This phone* is **این گوشی** — a lookup by title
  would drop the permission row's tap on exactly the page a reader opened to
  grant it.
  """
  @spec row_tap(map()) :: {pid(), atom()} | nil
  def row_tap(%{tap: tag}) when is_atom(tag) and not is_nil(tag), do: {self(), tag}
  def row_tap(_row), do: nil

  @doc false
  def control(nil), do: ~MOB"<Spacer size={0} />"
  def control(:chevron), do: SettingsList.chevron()

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

  ## An option is a label and a tag

  `{label, tag}`: the tag is a name in the program and the label is a word on
  a screen, and the two stop being the same string the moment the page has
  two languages.
  """
  @spec choice({String.t(), atom()}, boolean(), boolean()) :: map()
  def choice({label, tag}, on?, live? \\ false) do
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
        # The screen's last dead control. The board draws three
        # answers to an ambiguous match and none of them carried a tap, so the
        # card the whole screen is arranged around — *a wrong tick pollutes a
        # watch history nobody audits* — could not be answered.
        #
        # The tag comes from the OPTION and not from the label: a tag spelled
        # out of a drawn string is a tag that changes with the language.
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

  Compares the LABEL half: `chosen` is the label of the answer already given,
  and `nil` on a question nobody has answered yet.
  """
  @spec chosen?({String.t(), atom()}, String.t() | nil) :: boolean()
  def chosen?({label, _tag}, chosen), do: label == chosen

  @doc """
  Every control on the page.

  `handle_tap/2` rather than a `handle_info/2` clause: `Kati.Screens.Pushed`
  owns `handle_info/2` and its `:back` clause.

    * `:toggle_detect` — the banner, once access is granted. Writes
      `Kati.Media.Detect.put/1` and re-reads the page.
    * `:open_media_access` (*This phone*), `:how_to_allow` (the notice's
      pill) and `:allow_to_detect` (the banner while access is not granted)
      — three doors, three tags so each node keeps its own accessibility id,
      and all three push screen 151.
    * `:log_by_hand` — the notice's second pill. Opens the search over the
      reader's own shelf, as screen 151's does; see
      `Kati.Screens.NotificationAccess.log_by_hand/2`.
    * `:cycle_threshold` — *Tick at*, stepping 80 → 90 → 95.
    * `:answer_add_it`, `:answer_not_mine`, `:connect_N` — the decision card.

  Board 36's TV & film / Music control is not drawn, so there is no `:tv` or
  `:music` here; see the moduledoc.
  """
  @impl true
  # Turn detection on, or off. The screen's master switch.
  #
  # Re-reads the whole screen rather than flipping the assign: the banner's
  # count, the Sources row's own switch and the *Now playing* card all follow
  # from this one setting, and a switch that moved alone would be the picture it
  # used to be with a different pixel lit.
  def handle_tap(:toggle_detect, socket) do
    Kati.Media.Detect.put(not Kati.Media.Detect.on?())

    {:noreply, Mob.Socket.assign(socket, :detect, Kati.Screens.AutoDetect.detect())}
  end

  # Open screen 151, the page about notification access.
  #
  # There is no runtime dialog for `BIND_NOTIFICATION_LISTENER_SERVICE` —
  # `ACTION_NOTIFICATION_LISTENER_SETTINGS` is the whole of what an app may do.
  # This row used to fire that intent straight from here, which sent a reader
  # to a system list with nothing saying why Kati wanted a permission that
  # reads every notification on the phone. Screen 151 is that explanation,
  # drawn, and its own `Open system settings` button is the same intent — so
  # the row is a door to the page that asks, and the page is the door to the
  # system screen that grants.
  def handle_tap(tag, socket) when tag in [:open_media_access, :how_to_allow, :allow_to_detect] do
    {:noreply,
     Mob.Socket.push_screen(socket, Kati.Screens.NotificationAccess, %{back: "Auto-detect"})}
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

  def handle_tap(:log_by_hand, socket) do
    {:noreply, Kati.Screens.NotificationAccess.log_by_hand(socket, gettext("Auto-detect"))}
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
