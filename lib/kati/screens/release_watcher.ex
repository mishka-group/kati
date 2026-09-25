defmodule Kati.Screens.ReleaseWatcher do
  @moduledoc """
  Screen 25 — the release watcher's settings, pushed under Settings.

  Built to `test/design/screens/25.html`. Three questions in order: what to
  look for, how often to look, and how loudly to say so.

  Every control writes `Kati.Settings.Watcher` (`Mob.State`) and the page reads
  it back on every mount, so a switch that moved is still moved after the pop.
  What each one governs is that module's moduledoc; in short:

    * **the banner** — the master switch over `Kati.Background.Periodic`, the
      watcher's background check. Its two lines are counts: the followed titles
      and the Out now rows screen 05 draws.
    * **Tell me about** — *New episodes*, *Premieres* and *Film releases*,
      which filter screen 05, Home's *New this week* and every release alert.
    * **How often** — the cadence the background check is asked for, and
      **Check now**, which runs the sweep once and stamps the line under the
      title.
    * **How loudly** — *Push notifications* (release alerts armed on the
      platform by `Kati.Notifications.Releases`), *Inbox badge* (the dot on
      Home's bell) and *Quiet hours* (the window the scheduler moves reminders
      out of).

  Board 25 also draws *New books*, *New records*, *Leaving soon*, *People you
  follow*, *Price drops*, *Renewals* and *Weekly digest*. None of them has
  anything behind it in Kati — no book or record release producer, no offers or
  availability data, no people, no prices, no weekly job, and renewal reminders
  belong to the subscriptions ledger rather than to a release watcher — so they
  are not drawn: a switch that moves and does nothing is the defect this page
  was rebuilt to remove.

  Turning push on asks Android for the notification permission when it has not
  been refused for good, and the row says so when Android is blocking Kati.

  No dock — pushed screen — so the frame closes at 40, not 132.
  """
  use Kati.Screens.Pushed, back: "Settings"
  use Gettext, backend: Kati.Gettext

  alias Kati.Notifications.QuietHours
  alias Kati.Settings.Watcher
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @kind_icons %{new_episodes: "live_tv", premieres: "celebration", film_releases: "movie"}

  @impl true
  def load(socket) do
    Mob.Socket.assign(socket, :watcher, Kati.Screens.ReleaseWatcher.watcher())
  end

  @doc """
  Everything the page draws, read from the store.

  `notifications` is `Kati.Permissions.status/1` for the notification
  permission, which the push row's second line reads.
  """
  @spec watcher() :: map()
  def watcher do
    %{
      checked: Watcher.checked_line(Watcher.last_checked(), false),
      checking?: false,
      banner: %{banner() | on: Watcher.watching?()},
      kinds: kinds(),
      cadences: Watcher.cadences(),
      cadence: Watcher.cadence(),
      loudness: loudness(),
      notifications: Kati.Permissions.status(:notifications)
    }
  end

  @doc """
  The *Tell me about* rows, each reading its own switch.

      iex> Enum.map(Kati.Screens.ReleaseWatcher.kinds(), & &1.key)
      [:new_episodes, :premieres, :film_releases]
  """
  @spec kinds() :: [map()]
  def kinds do
    Enum.map(
      Watcher.kinds(),
      &%{key: &1, icon: Map.fetch!(@kind_icons, &1), on: Watcher.kind?(&1)}
    )
  end

  @doc """
  The *How loudly* rows, each reading its own switch.

      iex> Enum.map(Kati.Screens.ReleaseWatcher.loudness(), & &1.key)
      [:push, :badge, :quiet_hours]
  """
  @spec loudness() :: [map()]
  def loudness, do: Enum.map(Watcher.loudness(), &%{key: &1, on: Watcher.loud?(&1)})

  @doc """
  The cream banner: how many titles are watched, and how many releases that
  found this week.

  Both are counts off `Kati.Screens.Inbox.releases/0` — the followed titles and
  the Out now rows — so the banner and the inbox it summarises cannot disagree.
  A device following nothing, or a store that cannot be read, is told zero of
  each. `on` is filled in by `watcher/0` from the master switch.
  """
  @spec banner() :: map()
  def banner do
    case Kati.Screens.Inbox.releases() do
      nil ->
        %{title: watching_text(0), meta: found_text(0), on: true}

      inbox ->
        %{title: watching_line(%{followed: inbox.watching}), meta: found_line(inbox), on: true}
    end
  rescue
    _error -> %{title: watching_text(0), meta: found_text(0), on: true}
  end

  @doc """
  `Watching 1 title`, or `Watching 24 titles`.

      iex> Kati.Screens.ReleaseWatcher.watching_line(%{followed: 1})
      "Watching 1 title"

      iex> Kati.Screens.ReleaseWatcher.watching_line(%{followed: 24})
      "Watching 24 titles"

  The plural is `ngettext/4`'s question: Persian does not inflect a noun after
  a numeral, so a screen that picked the form itself would have picked it for
  one language. Board 05 says `Watching for 24 titles`, so the two keep their
  own msgids and share one Persian sentence.
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

  The capitals live inside the English msgid: `String.upcase/1` on Persian is a
  no-op.
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
        {Kati.Screens.ReleaseWatcher.group(w.kinds, "kind", 13, 22, w)}
        {UI.eyebrow(pgettext("eyebrow", "How often"))}
        {Kati.Screens.ReleaseWatcher.cadence(w)}
        {UI.eyebrow(pgettext("eyebrow", "How loudly"))}
        {Kati.Screens.ReleaseWatcher.group(w.loudness, "loud", 14, 22, w)}
        {SettingsList.note("info", Kati.Screens.ReleaseWatcher.note())}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The banner card. The whole card is the master switch's hit target, the way
  `SettingsList.row/4` makes a whole settings row one.

  The mono line takes `Kati.Locale.mono_face/0`: `found_line/1` is translated
  end to end and `kati_mono.ttf` carries no Persian glyph.
  """
  @spec banner(map()) :: map()
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

  @doc """
  One card of switch rows. `key` is `"kind"` or `"loud"`, and each row's tag is
  that prefix and the row's own key — `:kind_premieres`, `:loud_push` — so the
  two groups cannot collide and one handler clause serves each.
  """
  @spec group([map()], String.t(), number(), number(), map()) :: map()
  def group(rows, key, pad, gap, w) do
    last = length(rows) - 1

    body =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, i} -> Kati.Screens.ReleaseWatcher.row(row, key, pad, i < last, w) end)

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(body)}
      <Spacer size={gap} />
    </Column>
    """
  end

  @doc """
  One switch row. The tap is the whole row, not the 46pt track.
  """
  @spec row(map(), String.t(), number(), boolean(), map()) :: map()
  def row(row, key, pad, rule?, w) do
    {title, sub} = copy(row, Map.get(w, :notifications))

    SettingsList.row(
      SettingsList.icon_tile(icon(row)),
      SettingsList.body(title, sub),
      SettingsList.switch(row.on),
      padding: pad,
      rule: rule?,
      on_tap: {self(), String.to_atom(key <> "_" <> Atom.to_string(row.key))}
    )
  end

  defp icon(%{key: :push, on: true}), do: "notifications_active"
  defp icon(%{key: :push}), do: "notifications_off"
  defp icon(%{key: :badge}), do: "inbox"
  defp icon(%{key: :quiet_hours}), do: "bedtime"
  defp icon(%{icon: icon}), do: icon

  @doc """
  A row's two lines, in the reader's language.

  The push row's second line says what the switch is doing right now, and when
  Android is refusing Kati's notifications it says that instead of promising
  alerts that would never appear. The quiet-hours window is
  `Kati.Notifications.QuietHours.default/0`, the one the scheduler applies.
  """
  @spec copy(map(), atom() | nil) :: {String.t(), String.t()}
  def copy(%{key: :new_episodes}, _status),
    do: {pgettext("watcher kind", "New episodes"), gettext("Episodes of shows you follow")}

  def copy(%{key: :premieres}, _status),
    do: {pgettext("watcher kind", "Premieres"), gettext("New seasons and first episodes")}

  def copy(%{key: :film_releases}, _status),
    do:
      {pgettext("watcher kind", "Film releases"),
       gettext("Films you follow, on the day they come out")}

  def copy(%{key: :push, on: false}, _status),
    do: {gettext("Push notifications"), gettext("Off — the home card is enough")}

  def copy(%{key: :push, on: true}, status) when status in [:denied, :blocked],
    do: {gettext("Push notifications"), gettext("On, but Android is not letting Kati show them")}

  def copy(%{key: :push, on: true}, _status),
    do:
      {gettext("Push notifications"),
       gettext("On — an alert when something you follow comes out")}

  def copy(%{key: :badge}, _status),
    do: {pgettext("watcher loudness", "Inbox badge"), gettext("The dot on Home's bell")}

  def copy(%{key: :quiet_hours}, _status) do
    window = QuietHours.default()

    {pgettext("watcher loudness", "Quiet hours"),
     pgettext("quiet hours", "%{from} – %{to}",
       from: Kati.Locale.time(window.from),
       to: Kati.Locale.time(window.to)
     )}
  end

  @doc """
  The dashed footnote. True because push defaults off
  (`Kati.Settings.Watcher.loud?/1`) and the home card and the badge are what
  report a release without it.
  """
  @spec note() :: String.t()
  def note do
    gettext(
      "Push is off by default. The app is designed to be checked, not to interrupt — that " <>
        "is what the home card and the badge are for."
    )
  end

  @doc """
  The cadence strip: one segment per `Kati.Settings.Watcher.cadences/0`, on an
  `#E4E0D9` trough, each taking a weight so they divide the frame evenly, with
  **Check now** under it.

  Hand-rolled rather than `Kati.Components.MishkaSegmentedControl`, which emits
  its segments back to back with no gap and no prop that adds one, where this
  drawing puts 4pt between them.
  """
  @spec cadence(map()) :: map()
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
  **Check now** — one run of `Kati.Media.Cache.ask/1`, the sweep screen 80's
  *Refresh* runs. It answers on this pid; a successful run stamps
  `Kati.Settings.Watcher.checked!/0` and re-syncs the release alerts.
  """
  @spec check_now(map()) :: term()
  def check_now(w) do
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

  @doc """
  One cadence segment. The tag keeps the stored English label —
  `Kati.Settings.Watcher.put_cadence/1` matches on it — and only the drawn word
  is translated.
  """
  @spec segment(String.t(), boolean()) :: map()
  def segment(label, on?) do
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

  defp cadence_label("Hourly"), do: pgettext("watcher cadence", "Hourly")
  defp cadence_label("Every 6h"), do: pgettext("watcher cadence", "Every 6h")
  defp cadence_label("Daily"), do: pgettext("watcher cadence", "Daily")
  defp cadence_label(other), do: other

  @impl true
  def handle_info({:cache_refreshed, result}, socket) do
    if match?({:ok, _tally}, result) do
      Watcher.checked!()
      Kati.Notifications.Releases.sync()
    end

    {:noreply, Mob.Socket.assign(socket, :watcher, Kati.Screens.ReleaseWatcher.watcher())}
  end

  def handle_info({:permission, :notifications, _result}, socket) do
    Kati.Notifications.Releases.sync()
    {:noreply, Kati.Screens.ReleaseWatcher.reread(socket)}
  end

  def handle_info(message, socket), do: super(message, socket)

  @impl true
  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "check_now" ->
        Kati.Media.Cache.ask(self())

        {:noreply,
         Mob.Socket.assign(socket, :watcher, %{
           socket.assigns.watcher
           | checking?: true,
             checked: Watcher.checked_line(nil, true)
         })}

      "banner" ->
        Watcher.put_watching(not Watcher.watching?())
        {:noreply, Kati.Screens.ReleaseWatcher.reread(socket)}

      "kind_" <> key ->
        {:noreply, Kati.Screens.ReleaseWatcher.flip(socket, :kind, key)}

      "loud_" <> key ->
        {:noreply, Kati.Screens.ReleaseWatcher.flip(socket, :loud, key)}

      "cadence_" <> label ->
        Watcher.put_cadence(label)
        {:noreply, Kati.Screens.ReleaseWatcher.reread(socket)}

      _ ->
        {:noreply, socket}
    end
  end

  @doc """
  Flip one switch in the store, re-sync the release alerts it affects, and
  redraw from the store.

  Turning push on also asks Android for the notification permission when it
  has not been refused for good — the same request
  `Kati.Screens.LoudnessPrompt` makes. A key that names no switch changes
  nothing.
  """
  @spec flip(Mob.Socket.t(), :kind | :loud, String.t()) :: Mob.Socket.t()
  def flip(socket, :kind, key) do
    case Enum.find(Watcher.kinds(), &(Atom.to_string(&1) == key)) do
      nil ->
        socket

      kind ->
        Watcher.put_kind(kind, not Watcher.kind?(kind))
        Kati.Notifications.Releases.sync()
        Kati.Screens.ReleaseWatcher.reread(socket)
    end
  end

  def flip(socket, :loud, key) do
    case Enum.find(Watcher.loudness(), &(Atom.to_string(&1) == key)) do
      nil ->
        socket

      loud ->
        on? = not Watcher.loud?(loud)
        Watcher.put_loud(loud, on?)
        socket = if loud == :push and on?, do: ask_permission(socket), else: socket
        if loud != :badge, do: Kati.Notifications.Releases.sync()
        Kati.Screens.ReleaseWatcher.reread(socket)
    end
  end

  defp ask_permission(socket) do
    if Kati.Permissions.status(:notifications) in [:unasked, :denied] do
      Kati.Permissions.note_asked(:notifications)
      Mob.Permissions.request(socket, :notifications)
    else
      socket
    end
  end

  @doc """
  The page redrawn from the store, keeping a *Check now* that is still running.
  """
  @spec reread(Mob.Socket.t()) :: Mob.Socket.t()
  def reread(socket) do
    fresh = Kati.Screens.ReleaseWatcher.watcher()
    w = socket.assigns.watcher

    if Map.get(w, :checking?),
      do: Mob.Socket.assign(socket, :watcher, %{fresh | checking?: true, checked: w.checked}),
      else: Mob.Socket.assign(socket, :watcher, fresh)
  end
end
