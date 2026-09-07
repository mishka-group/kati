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
      banner: banner(),
      # MOVIES-AND-TV.md #67 and `design-briefs/D-64`. Fifteen controls edited a
      # socket assign and were forgotten on the pop, and the brief's own table
      # says which two have a consumer today: the cadence and *New episodes*.
      # Those two are read from `Mob.State` and written back; the other
      # thirteen keep the board's values and take the `not yet` mark screen 88
      # already uses for a scope nothing searches (#74).
      #
      # Persisting all fifteen was the obvious patch and is the wrong one — the
      # brief says why in a sentence: it turns *forgotten on the pop* into
      # *remembered, and still inert*, which is a worse lie.
      kinds: Kati.Screens.ReleaseWatcher.kinds(),
      cadences: Kati.Settings.Watcher.cadences(),
      cadence: Kati.Settings.Watcher.cadence(),
      loudness: Sample.loudness(),
      note: Sample.note()
    })
  end

  @doc """
  The six *Tell me about* rows, with the one that is live reading its own state.

  `New episodes` is the global gate over every title's `notify_new_episodes`
  and `Kati.Notifications.Sources.Media.followed/0` reads it. The other five
  keep the board's value and are marked, because a switch a reader can move
  that changes nothing is the defect #67 reports.
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
        Sample.banner()

      inbox ->
        %{
          Sample.banner()
          | title: watching_line(%{followed: Kati.Screens.Inbox.followed_count()}),
            meta: found_line(inbox)
        }
    end
  rescue
    _error -> Sample.banner()
  end

  @doc """
  `Watching 1 title`, or `Watching 24 titles`.

      iex> Kati.Screens.ReleaseWatcher.watching_line(%{followed: 1})
      "Watching 1 title"

      iex> Kati.Screens.ReleaseWatcher.watching_line(%{followed: 24})
      "Watching 24 titles"
  """
  @spec watching_line(map()) :: String.t()
  def watching_line(%{followed: 1}), do: "Watching 1 title"
  def watching_line(%{followed: n}), do: "Watching #{n} titles"

  @doc """
  `3 FOUND THIS WEEK`, in the mono capitals the banner draws.

      iex> Kati.Screens.ReleaseWatcher.found_line(%{out_now: []})
      "NOTHING NEW THIS WEEK"

      iex> Kati.Screens.ReleaseWatcher.found_line(%{out_now: [%{}]})
      "1 FOUND THIS WEEK"
  """
  @spec found_line(map()) :: String.t()
  def found_line(inbox) do
    case length(Map.get(inbox, :out_now, [])) do
      0 -> "NOTHING NEW THIS WEEK"
      n -> "#{n} FOUND THIS WEEK"
    end
  end

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
        {SettingsList.title("Release watcher", w.checked, nil, :meta_tight)}
        {Kati.Screens.ReleaseWatcher.banner(w.banner)}
        {UI.eyebrow("Tell me about")}
        {Kati.Screens.ReleaseWatcher.group(w.kinds, "kind", 13, 22)}
        {UI.eyebrow("How often")}
        {Kati.Screens.ReleaseWatcher.cadence(w)}
        {UI.eyebrow("How loudly")}
        {Kati.Screens.ReleaseWatcher.group(w.loudness, "loud", 14, 22)}
        {SettingsList.note("info", w.note)}
      </Column>
    </Scroll>
    """
  end

  # The whole banner is the master switch's hit target, the way `SettingsList.row`
  # makes a whole settings row one — the switch alone is 46pt wide and this card
  # is the same object screen 05 puts at the top of the inbox.
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
            font_family="mono"
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
      SettingsList.body(row.title, row.sub),
      if(not_yet?, do: Kati.Screens.ReleaseWatcher.not_yet(), else: SettingsList.switch(row.on)),
      padding: pad,
      rule: rule?,
      on_tap:
        if(not_yet?, do: nil, else: {self(), String.to_atom(key <> "_" <> Integer.to_string(i))})
    )
  end

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
    assigns = %{
      label: if(Map.get(w, :checking?), do: "Checking…", else: "Check"),
      tap: unless(Map.get(w, :checking?), do: {self(), :check_now})
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
        {Kati.UI.SettingsList.body("Check now", "Runs once, here, and updates the line above")}
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
    tap = {self(), String.to_atom("cadence_" <> label)}
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
        <Text text={label} text_size={12} font_weight={weight} text_color={fg} max_lines={1} />
        <Spacer weight={1.0} />
      </Row>
    </Box>
    """
  end

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

        {:noreply,
         Mob.Socket.assign(socket, :watcher, %{w | checking?: true, checked: "checking now"})}

      "banner" ->
        {:noreply,
         Mob.Socket.assign(socket, :watcher, %{w | banner: %{w.banner | on: not w.banner.on}})}

      # Only the live one reaches here — a marked row carries no tag at all —
      # and it writes, which is the whole of #67 for this switch.
      "kind_" <> i ->
        flipped = Kati.Screens.ReleaseWatcher.flip(w.kinds, i)

        Enum.each(flipped, fn row ->
          if Kati.Settings.Watcher.live?(row.title),
            do: Kati.Settings.Watcher.put_new_episodes(row.on)
        end)

        {:noreply, Mob.Socket.assign(socket, :watcher, %{w | kinds: flipped})}

      "loud_" <> i ->
        {:noreply,
         Mob.Socket.assign(socket, :watcher, %{
           w
           | loudness: Kati.Screens.ReleaseWatcher.flip(w.loudness, i)
         })}

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
