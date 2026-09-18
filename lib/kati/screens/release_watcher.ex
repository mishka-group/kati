defmodule Kati.Screens.ReleaseWatcher do
  @moduledoc """
  Screen 25 — the release watcher's settings, pushed under Settings.

  Built to `test/design/screens/25.html`. Three questions in order: what to
  look for, how often to look, and how loudly to say so. The last group is the
  one that matters — push is off, the inbox badge is on, and the dashed
  footnote says why rather than leaving it to be discovered.

  The cream banner is the same card screen 05 puts at the top of the inbox, so
  the thing the watcher does and the thing you configure look like one object
  seen from two sides.

  Every control on the screen is live and every one of them edits the single
  `:watcher` assign: the banner is the master switch, each row of the two
  groups flips its own, and the cadence segments move the selection. The screen
  still opens on `Kati.Settings.WatcherSample`'s own defaults, which are the
  drawing's state — the resting frame is unchanged.

  No dock — pushed screen — so the frame closes at 40, not 132.

  ## Why this screen is still on `Kati.Settings.WatcherSample`

  Everything it draws is a preference, and Kati has no preferences resource.
  The Ash domains are `Kati.Calendars`, `Kati.Media`, `Kati.Meals` and
  `Kati.Sync`; none of them holds a switch, a cadence or a last-checked time,
  and `lib/kati/settings` is four sample modules with no resource among them.
  `Kati.Notifications.QuietHours` is the shape of the gap: it states 23:00 to
  08:00 as a struct default and says out loud that the window is "configurable
  because it is a user setting", with nowhere for that configuration to live.
  So every control here edits one socket assign and forgets it on pop, and
  moving the screen onto a domain means adding the domain first.

  One value is already derivable and deliberately not taken.
  `Kati.Media.TrackedTitle`'s `:followed` read is, in its own description,
  "the titles the release watcher has any business looking at", so the banner's
  `Watching 24 titles` could be a real count today. Counting it while the ten
  switches, the cadence and the `3 FOUND THIS WEEK` beside it stayed invented
  would make the card look live and be half made up — a worse thing to reason
  about than a card that is honestly all sample.
  """
  use Kati.Screens.Pushed, back: "Settings"
  use Gettext, backend: Kati.Gettext

  alias Kati.Settings.WatcherSample, as: Sample
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @impl true
  def load(socket) do
    Mob.Socket.assign(socket, :watcher, %{
      # Board 314: a relative line from a real timestamp, and `never checked` —
      # which is every fresh install — where there is none. `checked 18:02` was
      # a wall-clock time from a column that did not exist.
      checked: Kati.Settings.Watcher.checked_line(Kati.Settings.Watcher.last_checked(), false),
      checking?: false,
      banner: %{banner() | on: Kati.Settings.Watcher.watching?()},
      # MOVIES-AND-TV.md #67 and `design-briefs/D-64`. Fifteen controls edited a
      # socket assign and were forgotten on the pop, and three of them have a
      # consumer today: the cadence, *New episodes* and the banner's master
      # switch. Those three are read from `Mob.State` and written back; the
      # other twelve — eight *Tell me about* rows and all four *How loudly*
      # rows — keep the board's values and take the `not yet` mark screen 88
      # already uses for a scope nothing searches (#74).
      #
      # Persisting all fifteen was the obvious patch and is the wrong one — the
      # brief says why in a sentence: it turns *forgotten on the pop* into
      # *remembered, and still inert*, which is a worse lie.
      kinds: Kati.Screens.ReleaseWatcher.kinds(),
      cadences: Kati.Settings.Watcher.cadences(),
      cadence: Kati.Settings.Watcher.cadence(),
      loudness: Kati.Screens.ReleaseWatcher.loudness(),
      note: Sample.note()
    })
  end

  @doc """
  The nine *Tell me about* rows, with the one that is live reading its own state.

  `New episodes` is the global gate over every title's `notify_new_episodes`
  and `Kati.Notifications.Sources.Media.followed/0` reads it. The other eight
  keep the board's value and are marked, because a switch a reader can move
  that changes nothing is the defect #67 reports.

  This said *six* and *five* until now, which was the count before board 307
  added its three shelves — books, records and films — to
  `Kati.Settings.WatcherSample.kinds/0`. The list grew and the sentence
  counting it did not; `load/1`'s *twelve* is the number that stayed right.
  """
  @spec kinds() :: [map()]
  def kinds do
    Enum.map(Sample.kinds(), fn row ->
      if Kati.Settings.Watcher.live?(row.title) do
        %{row | on: Kati.Settings.Watcher.new_episodes?()}
      else
        Map.put(row, :not_yet?, true)
      end
    end)
  end

  @doc """
  The four *How loudly* rows. All four are marked, and the list `loud?/1` reads
  is empty on purpose.

  Nothing in Kati sends a notification for a release.
  `Kati.Notifications.Scheduler` is built by `Kati.Screens.InboxNotifications`
  and armed by nothing; the only `Kati.Notifications.Delivery.backend/0` calls
  in `lib/` are auto-detect's *What was that?*, a different feature with its
  own page. So push has no sender, quiet hours has nothing to quiet and no
  weekly job exists.

  Two of the four have a READER and are still marked. `Kati.Screens.Home`'s
  unread dot is a real consumer of the badge and `Scheduler.plan/2` takes
  `:quiet_hours` — but the dot is derived from the plan rather than stored, and
  quiet hours only shifts a `fire_at` in a plan nothing arms, so either switch
  would change a printed hour rather than keep the promise it makes.
  `design-briefs/D-64` asks for the board that decides between a marked group,
  an absence, and one honest line; until it lands the mark is the answer.
  """
  @spec loudness() :: [map()]
  def loudness do
    Enum.map(Sample.loudness(), fn row ->
      if Kati.Settings.Watcher.loud?(row.title),
        do: row,
        else: Map.put(row, :not_yet?, true)
    end)
  end

  @doc """
  The cream banner: how many titles are being watched, and what that found.

  `Watching 24 titles · 3 FOUND THIS WEEK` was `Kati.Settings.WatcherSample`'s
  on every device — two specific claims about the reader's own library, of
  exactly the kind MOVIES-AND-TV.md #67 and #50 are about, on a phone that may
  follow none. Both are counts and both are countable: the followed rows, and
  the `out_now` list screen 05 already builds out of them.

  A device following nothing keeps the board's line. That is the gate every
  other screen on this list keeps — an empty store answers the drawing — and
  `Watching 0 titles` over a page of switches would be a page about nothing.
  """
  @spec banner() :: map()
  def banner do
    case Kati.Screens.Inbox.releases() do
      nil ->
        board_banner()

      inbox ->
        %{
          Sample.banner()
          | title: watching_line(%{followed: Kati.Screens.Inbox.followed_count()}),
            meta: found_line(inbox)
        }
    end
  rescue
    _error -> board_banner()
  end

  # The board's line, drawn through the same two sentences the live card uses.
  #
  # `Kati.Settings.WatcherSample.banner/0` holds it as two English LITERALS —
  # `Watching 24 titles · 3 FOUND THIS WEEK` — and a literal is the one thing
  # `gettext/1` cannot reach: a msgid has to be at the call site, and the
  # sample is not this screen's file. So the fallback stops taking the sample's
  # SENTENCES and takes its two FIGURES, which `watching_line/1` and
  # `found_line/1` already know how to say in either script. Without this the
  # resting frame — which is every phone that follows nothing, and so most of
  # them — was the one card on a Persian page still in Latin.
  #
  # The two numbers are written here and the sample's are written there, and
  # `Kati.ReleaseWatcherBannerTest`'s `banner() == WatcherSample.banner()` is
  # what keeps them the same two: they disagree and that assertion fails.
  # Zero, and said in the screen's own two sentences rather than the board's
  # figures. This answered `watching_text(24)` and `found_text(3)` — so a fresh
  # install was told it was watching 24 titles and had found 3 — and it answered
  # them for a raised read as well as for an empty one.
  defp board_banner do
    %{Sample.banner() | title: watching_text(0), meta: found_text(0)}
  end

  @doc """
  `Watching 1 title`, or `Watching 24 titles`.

      iex> Kati.Screens.ReleaseWatcher.watching_line(%{followed: 1})
      "Watching 1 title"

      iex> Kati.Screens.ReleaseWatcher.watching_line(%{followed: 24})
      "Watching 24 titles"

  One clause rather than two now, for the reason
  `Kati.Screens.Inbox.watching_line/1` gives about the same card: the plural is
  `ngettext/4`'s question and not this screen's, because Persian does not
  inflect a noun after a numeral — *۲۴ عنوان* takes the same word as *۱ عنوان*
  — so a screen that picks the form itself has picked it for one language.

  Board 05 says `Watching for 24 titles` where this one says `Watching 24
  titles`, so the two keep their own msgids and share one Persian sentence.
  """
  @spec watching_line(map()) :: String.t()
  def watching_line(%{followed: n}), do: watching_text(n)

  defp watching_text(n) do
    ngettext("Watching %{n} title", "Watching %{n} titles", n, n: Kati.Locale.number(n))
  end

  @doc """
  `3 FOUND THIS WEEK`, in the mono capitals the banner draws.

      iex> Kati.Screens.ReleaseWatcher.found_line(%{out_now: []})
      "NOTHING NEW THIS WEEK"

      iex> Kati.Screens.ReleaseWatcher.found_line(%{out_now: [%{}]})
      "1 FOUND THIS WEEK"

  The capitals are Latin typography and live inside the English msgid rather
  than being applied to the result of one — `String.upcase/1` on Persian is a
  no-op, which is `Kati.Screens.Inbox.cadence_label/1`'s finding about the same
  card's other mono line.
  """
  @spec found_line(map()) :: String.t()
  def found_line(inbox), do: found_text(length(Map.get(inbox, :out_now, [])))

  defp found_text(0), do: gettext("NOTHING NEW THIS WEEK")
  defp found_text(n), do: gettext("%{n} FOUND THIS WEEK", n: Kati.Locale.number(n))

  @doc false
  def content(assigns) do
    w = assigns.watcher

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
        {SettingsList.title(gettext("Release watcher"), w.checked, nil, :meta_tight)}
        {Kati.Screens.ReleaseWatcher.banner(w.banner)}
        {UI.eyebrow(pgettext("eyebrow", "Tell me about"))}
        {Kati.Screens.ReleaseWatcher.group(w.kinds, "kind", 13, 22)}
        {UI.eyebrow(pgettext("eyebrow", "How often"))}
        {Kati.Screens.ReleaseWatcher.cadence(w)}
        {UI.eyebrow(pgettext("eyebrow", "How loudly"))}
        {Kati.Screens.ReleaseWatcher.group(w.loudness, "loud", 14, 22)}
        {SettingsList.note("info", Kati.Screens.ReleaseWatcher.note(w.note))}
      </Column>
    </Scroll>
    """
  end

  # The whole banner is the master switch's hit target, the way `SettingsList.row`
  # makes a whole settings row one — the switch alone is 46pt wide and this card
  # is the same object screen 05 puts at the top of the inbox.
  #
  # The mono line is `Kati.Locale.mono_face/0` and not `"mono"`, asked of the
  # READER rather than of the string, which is the answer screen 05's twin of
  # this card already gives: `found_line/1` is translated end to end, so under
  # `:fa` there is never a Latin run in it, and `kati_mono.ttf` carries no
  # Persian glyph at all — Android would substitute its own face for the whole
  # line, beside a title set in Kati's.
  @doc false
  def banner(b) do
    tap = {self(), :banner}

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.cream()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={18}
        align="center"
        on_tap={tap}
      >
        {Kati.UI.symbol("auto_awesome", size: 24, color: Palette.gold_icon())}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text
            text={b.title}
            text_size={14.5}
            font_weight="bold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={4} />
          <Text
            text={b.meta}
            font_family={Kati.Locale.mono_face()}
            text_size={10.5}
            text_color={Palette.cream_meta()}
            max_lines={1}
          />
        </Column>
        <Spacer size={13} />
        {SettingsList.switch(b.on)}
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  # `key` names which list in `:watcher` the group is drawing, so the row tags
  # are `kind_2` / `loud_0` and one handler clause serves a group of any length.
  @doc false
  def group(rows, key, pad, gap) do
    last = length(rows) - 1

    body =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, i} -> Kati.Screens.ReleaseWatcher.row(row, key, i, pad, i < last) end)

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(body)}
      <Spacer size={gap} />
    </Column>
    """
  end

  # The tap is the whole row, not the switch: `SettingsList.row/4` hangs it off
  # the row's own Column, and a 46pt track is a poor target for a screen that is
  # ten switches tall. The tag carries the position rather than the title so the
  # two groups cannot collide on a shared name.
  @doc false
  def row(row, key, i, pad, rule?) do
    # A row with nothing behind it carries no tap and says so instead of its
    # switch — `Kati.Screens.SearchSpec.state_pill/1`'s `not yet`, which is the
    # same mark for the same thing one screen over (#74, #67).
    not_yet? = Map.get(row, :not_yet?, false)

    SettingsList.row(
      SettingsList.icon_tile(row.icon),
      SettingsList.body(copy(row.title), copy(row.sub)),
      if(not_yet?, do: Kati.Screens.ReleaseWatcher.not_yet(), else: SettingsList.switch(row.on)),
      padding: pad,
      rule: rule?,
      on_tap:
        if(not_yet?, do: nil, else: {self(), String.to_atom(key <> "_" <> Integer.to_string(i))})
    )
  end

  # A sample row's English literal, said in the reader's own language.
  #
  # `Kati.Settings.WatcherSample` holds all thirteen rows and their sub-lines,
  # and those titles are KEYS as well as copy: `Kati.Settings.Watcher.live?/1`
  # and `loud?/1` match on `New episodes` by name, deliberately, because the
  # board's order is the board's and an index would silently move with it. So
  # the store cannot be translated where it lives — and a msgid has to be a
  # literal at the call site besides, which is why the twenty-six strings are
  # written out here rather than handed to `gettext/1` as `row.title`, which
  # does not compile. `Kati.Screens.Inbox.cadence_label/1` is the same shape one
  # screen over and carries the same argument.
  #
  # Contexts on the one- and two-word titles, and none on the sentences:
  # `mix gettext.merge` fuzzy-matches anything that short onto any sentence it
  # resembles, and `Episodes`, `Albums` and `Inbox` are already msgids of their
  # own.
  #
  # Every figure goes through `Kati.Locale.number/1` or `Kati.Locale.time/1`
  # rather than being spelled into the Persian, so `7 days’ notice` is ۷ روز
  # and `23:00 – 08:00` is ۲۳:۰۰ without a translator carrying a digit. The
  # quiet-hours range is a msgid rather than a join, because Persian puts a
  # word between the two times where the drawing puts an en dash, and a screen
  # that concatenates has already decided.
  defp copy("New episodes"), do: pgettext("watcher kind", "New episodes")
  defp copy("Shows you are watching"), do: gettext("Shows you are watching")
  defp copy("Premieres"), do: pgettext("watcher kind", "Premieres")
  defp copy("New seasons and first episodes"), do: gettext("New seasons and first episodes")
  defp copy("New books"), do: pgettext("watcher kind", "New books")
  defp copy("Authors you follow"), do: gettext("Authors you follow")
  defp copy("New records"), do: pgettext("watcher kind", "New records")
  defp copy("Artists you follow"), do: gettext("Artists you follow")
  defp copy("Film releases"), do: pgettext("watcher kind", "Film releases")

  defp copy("Wishlisted films reaching cinemas or streaming"),
    do: gettext("Wishlisted films reaching cinemas or streaming")

  defp copy("Leaving soon"), do: pgettext("watcher kind", "Leaving soon")
  defp copy("7 days’ notice"), do: gettext("%{n} days’ notice", n: Kati.Locale.number(7))
  defp copy("People you follow"), do: gettext("People you follow")
  defp copy("Announcements, not just releases"), do: gettext("Announcements, not just releases")
  defp copy("Price drops"), do: pgettext("watcher kind", "Price drops")
  defp copy("Titles on your wishlist"), do: gettext("Titles on your wishlist")
  defp copy("Renewals"), do: pgettext("watcher kind", "Renewals")
  defp copy("2 days before"), do: gettext("%{n} days before", n: Kati.Locale.number(2))
  defp copy("Push notifications"), do: gettext("Push notifications")
  defp copy("Off — the home card is enough"), do: gettext("Off — the home card is enough")
  defp copy("Inbox badge"), do: pgettext("watcher loudness", "Inbox badge")
  defp copy("Unread count on the bell"), do: gettext("Unread count on the bell")
  defp copy("Quiet hours"), do: pgettext("watcher loudness", "Quiet hours")

  defp copy("23:00 – 08:00") do
    pgettext("quiet hours", "%{from} – %{to}",
      from: Kati.Locale.time(~T[23:00:00]),
      to: Kati.Locale.time(~T[08:00:00])
    )
  end

  # `Weekly digest` is already in the catalogue — the onboarding's loudness
  # step (`Kati.Screens.OnboardingLoudness`, board 136) offers the same words
  # for the same thing — so this takes the msgid that exists rather than a
  # second one under a context of its own. Two Persians for one setting, on two
  # screens a reader meets a week apart, is the drift a shared msgid prevents.
  defp copy("Weekly digest"), do: gettext("Weekly digest")

  defp copy("Sundays at 18:00"),
    do: gettext("Sundays at %{time}", time: Kati.Locale.time(~T[18:00:00]))

  # A row this screen does not know, drawn as it is stored. Every string above
  # is `Kati.Settings.WatcherSample`'s and a row added there tomorrow must not
  # take the whole page down with a `FunctionClauseError` — the fallback
  # `Kati.Screens.Inbox.cadence_label/1` keeps, for the same reason.
  defp copy(other), do: other

  @doc """
  `not yet`, on a control this app cannot keep a promise about.

  Screen 88's own pill, drawn here for the same argument: the contract is the
  design's and stating it whole is what the page is for; what was missing is
  which half of it is live. `design-briefs/D-64` lists what each of the
  thirteen would need, and every one becomes a switch again the day its
  resource exists.
  """
  @spec not_yet() :: map()
  def not_yet, do: Kati.Screens.SearchSpec.not_yet_pill()

  @doc """
  The dashed footnote, in the reader's own language.

  `Kati.Settings.WatcherSample.note/0` stores the sentence and this is where it
  is said, which is `copy/1`'s arrangement for the thirteen rows and is here
  for the same two reasons: a msgid has to be a literal at the call site, and
  the sample is not this screen's file to change.

  Matched on its opening clause rather than on the whole sentence, so the
  sample and the msgid cannot drift apart over a comma and leave the footnote
  silently English; and an unrecognised note is drawn as it is stored rather
  than taking the page down.
  """
  @spec note(String.t()) :: String.t()
  def note("Push is off by default." <> _rest) do
    gettext(
      "Push is off by default. The app is designed to be checked, not to interrupt — that " <>
        "is what the home card and the badge are for."
    )
  end

  def note(other), do: other

  @doc """
  Four segments on an `#E4E0D9` trough, each taking a weight so they divide the
  frame evenly — screen 03's control is the same object at a different width.

  Not `Kati.Components.MishkaSegmentedControl`, for the one reason
  `Kati.Screens.ViewSwitcher`'s moduledoc sets out in full: since
  `segment_weight` landed the port can do every other thing this strip does —
  the weights, the 34pt segments, the radii, the two label colours and weights,
  the lift under the selected tile — but it emits its four segments back to back
  with **no gap between them and no prop that adds one**, where this drawing puts
  4pt. Padding cannot stand in, because the bridge applies `background` before
  `padding` and a segment's padding therefore widens its own fill; and a
  `<Spacer>` cannot be interspersed by hand, because `expand/3` drops every child
  that is not an option. Without the gaps the track is 12 narrower and all four
  boundaries move, so the markup stays.
  """
  def cadence(w) do
    tiles =
      w.cadences
      |> Enum.map(fn c -> Kati.Screens.ReleaseWatcher.segment(c, c == w.cadence) end)
      |> Enum.intersperse(Kati.Screens.ReleaseWatcher.segment_gap())

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.placeholder()}
        corner_radius={16}
        padding={4}
        align="center"
      >
        {tiles}
      </Row>
      <Spacer size={14} />
      {Kati.Screens.ReleaseWatcher.check_now(w)}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  **Check now** — board 314's replacement for the `Manual` segment.

  *"Nothing schedules a manual run, so Manual is never — and a segment that
  silently switches the watcher off is worse than no segment… A one-off run is
  an action, not a schedule."* It runs `Kati.Media.Cache.ask/1`, which is the
  same sweep screen 80's *Refresh* pill runs, and stamps the line this board
  also fixed.
  """
  @spec check_now(map()) :: term()
  def check_now(w) do
    # The row's two lines are built here rather than inside the sigil, where
    # `@title` would mean an ASSIGN and not a module attribute — which is what
    # this map is for.
    assigns = %{
      label:
        if(Map.get(w, :checking?),
          do: pgettext("release watcher", "Checking…"),
          else: pgettext("release watcher", "Check")
        ),
      tap: unless(Map.get(w, :checking?), do: {self(), :check_now}),
      title: pgettext("release watcher", "Check now"),
      sub: gettext("Runs once, here, and updates the line above")
    }

    ~MOB"""
    <Row
      fill_width={true}
      height={56}
      corner_radius={20}
      background={Palette.card()}
      shadow={Kati.Theme.shadow_card_soft()}
      padding_left={15}
      padding_right={15}
      align="center"
    >
      {Kati.UI.SettingsList.icon_tile("sync")}
      <Spacer size={13} />
      <Column weight={1.0}>
        {Kati.UI.SettingsList.body(@title, @sub)}
      </Column>
      <Spacer size={12} />
      {Kati.UI.SettingsList.action_pill(@label, @tap)}
    </Row>
    """
  end

  @doc false
  def segment_gap, do: ~MOB"<Spacer size={4} />"

  @doc false
  def segment(label, on?) do
    # The tag carries the cadence, so a fifth interval is a change to
    # `WatcherSample.cadences/0` and nothing else.
    #
    # The TAG keeps the English label and only the drawn word is translated:
    # `Kati.Settings.Watcher.put_cadence/1` matches the three names and
    # `Mob.State` holds one of them, so a Persian tag would write a cadence
    # `interval_for/1` has never heard of — and `Kati.ScreenTapSweepTest`
    # names `:"cadence_Every 6h"` by hand.
    tap = {self(), String.to_atom("cadence_" <> label)}
    word = cadence_label(label)
    bg = if on?, do: Palette.card(), else: Palette.transparent()
    fg = if on?, do: Palette.ink(), else: Palette.segment_idle()
    weight = if on?, do: "bold", else: "semibold"
    shadow = if on?, do: "0 1 2 0 #0F1A1917", else: "0 0 0 0 #00000000"

    ~MOB"""
    <Box weight={1.0}>
      <Row
        fill_width={true}
        height={34}
        corner_radius={12}
        background={bg}
        shadow={shadow}
        align="center"
        on_tap={tap}
      >
        <Spacer weight={1.0} />
        <Text text={word} text_size={12} font_weight={weight} text_color={fg} max_lines={1} />
        <Spacer weight={1.0} />
      </Row>
    </Box>
    """
  end

  # The three cadence names, in the reader's own words.
  #
  # `Kati.Screens.Inbox.cadence_label/1` is the same table, lowercased, because
  # 05 says `never checked · every 6h` inside a sentence where this draws three
  # segments with a capital each. Latin case is not a thing Persian has, so the
  # case lives inside the English msgid and both tables answer the same Persian
  # — a reader who sets **Daily** here reads روزانه on both screens.
  #
  # Contexts, and the same context 05 uses: `hourly` and `daily` are one word
  # each and `mix gettext.merge` fuzzy-matches anything that short onto any
  # sentence it resembles.
  defp cadence_label("Hourly"), do: pgettext("watcher cadence", "Hourly")
  defp cadence_label("Every 6h"), do: pgettext("watcher cadence", "Every 6h")
  defp cadence_label("Daily"), do: pgettext("watcher cadence", "Daily")

  # A fourth interval added to `Kati.Settings.Watcher` and not here draws as it
  # is stored rather than taking the strip down.
  defp cadence_label(other), do: other

  @doc """
  Flip the `on` flag of one row of a group.

  A list rather than a map keyed by title: the drawing's order is the screen's
  order, and the index is what the tag carries.
  """
  @spec flip([map()], String.t()) :: [map()]
  def flip(rows, index) do
    List.update_at(rows, String.to_integer(index), fn row -> %{row | on: not row.on} end)
  end

  # The sweep answering. It stamps the timestamp board 314 asks for and redraws
  # the line from it, so the page says what actually happened rather than what
  # was hoped: a refresh that could not start — no TMDB key is the usual reason
  # — leaves *never checked* standing, which is true.
  @impl true
  def handle_info({:cache_refreshed, result}, socket) do
    w = socket.assigns.watcher
    if match?({:ok, _tally}, result), do: Kati.Settings.Watcher.checked!()

    {:noreply,
     Mob.Socket.assign(socket, :watcher, %{
       w
       | checking?: false,
         checked: Kati.Settings.Watcher.checked_line(Kati.Settings.Watcher.last_checked(), false)
     })}
  end

  def handle_info(message, socket), do: super(message, socket)

  # Every control on this screen edits the one `:watcher` map, so there is a
  # clause per kind of control rather than per row.
  @impl true
  def handle_tap(tag, socket) do
    w = socket.assigns.watcher

    case Atom.to_string(tag) do
      # Board 314's button. `Kati.Media.Cache.ask/1` is the same sweep screen
      # 80's *Refresh* pill runs, and it answers on this pid when it is done.
      "check_now" ->
        Kati.Media.Cache.ask(self())

        # `checked_line/2`'s own `checking now` and not a literal of the same
        # words. Board 314 gave that module all three of this line's states and
        # mishka-group/kati#103 translated them there; a second copy written
        # here was the one of the three that stayed English under `:fa`, and it
        # is the state a reader sees precisely when they have just tapped
        # something and are watching the line to see what it does.
        {:noreply,
         Mob.Socket.assign(socket, :watcher, %{
           w
           | checking?: true,
             checked: Kati.Settings.Watcher.checked_line(nil, true)
         })}

      # The master switch, and the one thing on this page it could mean:
      # `Kati.Background.Periodic` is the watcher's background check, so off
      # cancels the worker and on enqueues it at the cadence below. It survives
      # the pop because it is `Mob.State`'s, beside the cadence.
      "banner" ->
        on? = not w.banner.on
        Kati.Settings.Watcher.put_watching(on?)

        {:noreply, Mob.Socket.assign(socket, :watcher, %{w | banner: %{w.banner | on: on?}})}

      # Only the live one reaches here — a marked row carries no tag at all —
      # and it writes, which is the whole of #67 for this switch.
      "kind_" <> i ->
        flipped = Kati.Screens.ReleaseWatcher.flip(w.kinds, i)

        Enum.each(flipped, fn row ->
          if Kati.Settings.Watcher.live?(row.title),
            do: Kati.Settings.Watcher.put_new_episodes(row.on)
        end)

        {:noreply, Mob.Socket.assign(socket, :watcher, %{w | kinds: flipped})}

      # And the cadence, which `Kati.Background.Periodic.ensure/1`'s own doc
      # named as *a future "check less often" setting* before there was one.
      "cadence_" <> label ->
        Kati.Settings.Watcher.put_cadence(label)

        {:noreply, Mob.Socket.assign(socket, :watcher, %{w | cadence: label})}

      _ ->
        {:noreply, socket}
    end
  end
end
