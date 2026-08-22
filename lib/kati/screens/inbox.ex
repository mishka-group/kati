defmodule Kati.Screens.Inbox do
  @moduledoc """
  Screen 05 — the new releases inbox, pushed under Home.

  Built to `.scratch/design/screens/05.html`. Two lists that look different
  because they answer different questions: **Out now** is a card per title with
  its poster and a Watch button, because each row is something you can act on;
  **Coming up** is one card of dated rows, because it is a schedule and the
  dates are the spine.

  The watcher card at the top is the honest bit — it says how many titles are
  watched and when it last checked, so background work that runs every six
  hours is visible rather than assumed.

  ## Where the two lists come from

  `Kati.Media`, through `inbox/0`. Both lists are episode-level and neither
  could exist before `Kati.Media.CachedEpisode` and `Kati.Media.CachedSeason`
  did — this moduledoc used to say *"`Kati.Media` has no episode resource at
  all"*, and that sentence is now false. `S2 E6 — Ash and After`, `48 min` and
  `aired 20:00` are `season_number`, `episode_number`, `title`,
  `runtime_minutes` and an air date; the coming-up rows and the bell beside each
  are `Kati.Media.Release`.

  Five reads, never one per row: the followed titles, the cache rows they name,
  the episodes those titles have scheduled, the seasons they have scheduled, and
  the episode ticks. The cache is reached by the value pair the durable rows
  reference it by, so an evicted poster cannot take a release out of the list.

  `:followed` rather than a filter written out here: it is the action
  `Kati.Media.TrackedTitle` describes as *"the titles the release watcher has
  any business looking at"* — finished and dropped shows excluded, because an
  announcement about a show the user abandoned is noise. This screen is that
  watcher's output, so it must not have a second opinion about what it watches.

  With nothing followed there is nothing to be new and `Kati.Library.Sample` is
  drawn instead, the values `.scratch/design/screens/05.html` was captured from.
  FIDELITY's rule: *missing data is not a reason for a blank screen*. The Sample
  module stays exactly where it is; it is the fallback and the fixture, not a
  stage this screen has passed through. A user who follows something and has
  nothing out this week sees an **empty** Out now section rather than the
  drawing's three rows: that is the true answer, and substituting the drawing
  there would be three titles they do not have.

  ### Out now

  Episodes of followed titles that `Kati.Media.Release.airing/2` says have
  `:aired`, are not already ticked, and went out within the last seven days. Newest
  first.

  Two of those bounds are worth stating plainly:

    * **"Now" is a window, and it is this screen's own.** Nothing stores when
      the watcher last swept (see below), so an episode cannot be "new since the
      last check"; without a bound, *out now* would be the user's entire
      unwatched backlog. A week is the cadence of the weekly show the drawing
      is of, and it bounds a **display**, never an alarm — `Kati.Media.Release`
      is still the only thing that arms anything.
    * **Films are not in this list**, and the drawing's `Blue Hour · Premiere`
      row is why the rule is written down. A film's date is
      `Kati.Media.CachedTitle.next_release_at`, which is *the next* release — a
      pointer that moves forward as soon as the thing it named is out. Reading
      it backwards to say "this came out today" is asking a forward-looking
      column a question about the past. An episode's `air_at` is a fact about
      one episode and does not move, so the list is episodes. The green dot the
      design gives a film premiere is therefore drawn only on the drawn rows.

  ### Coming up

  Three kinds of thing can be next, and the drawing has one of each: an episode
  (`The Long Hollow — S2E6`), a whole-season drop (`Nightbirds — Season 2`) and
  a film (`Vellum`). Episodes and seasons resolve through
  `Kati.Media.Release.air/1`; a film through `Kati.Media.Release.resolve/2`,
  which is the path a `user_override_date` wins on. A **series** contributes no
  title-level row, because `next_release_at` on a series is a restatement of its
  own next episode and the row would be drawn twice.

  Only dates `Kati.Media.Release` is willing to name — `:exact` or `:day` —
  reach the list. The card's whole left edge is a month and a day, and an
  `:approximate` answer carries no day at all; the same rule
  `Kati.Screens.UpNext.airing_soon/2` counts by, honoured rather than
  re-decided.

  The bell is `Kati.Media.Release.alarm_for/3` (`alarm_at/3` for a film): filled
  and orange when an alarm can actually be set for that row, hollow when it
  cannot. That is exactly the design's distinction — *already being watched
  for* against *only listed* — and it comes out of the one gate, so a muted show
  and a vague date both draw the hollow bell without this screen deciding
  either.

  ## What is still frozen, and why

    * **`LUMEN+`, `CINEMA`, `In cinemas` and `Full season drop`.** The first
      three are availability, which no column holds —
      `Kati.Media.Watch.service` is where the *user* watched something, which is
      a different fact and is per-watch. The fourth is a claim that a season
      lands all at once rather than weekly, and nothing records a release
      pattern. A real row draws what is left: `48 min · aired 20:00`, and a
      coming-up line that is the episode's own name and its hour.
    * **The whole watcher card.** Three values with three different answers, and
      only one of them is queryable:

        * `Watching for 24 titles` — real today. `:followed` is precisely the
          set, and counting it is the number.
        * `last checked 18:02` — **nothing records when the watcher last ran.**
          `Kati.Media.CachedTitle.last_checked_at` is per title, not per sweep,
          and the max across a library is not the same fact: a library where one
          title was refreshed a minute ago and the rest a week ago would read as
          fully current.
        * `every 6h` — the watcher's cadence, which lives in no resource and no
          policy module (`Kati.Media.CachePolicy` states refresh and eviction
          horizons in *days*, which is a different clock).

      So the count stays frozen with the other two rather than being wired up on
      its own. A card that reads `Watching for 7 titles · last checked 18:02`
      puts a live number beside a frozen one in the same breath, and the second
      is then indistinguishable from the first — which is `Kati.Library.Sample`'s
      own warning: *sample data that looks like real data is how a demo quietly
      becomes a lie*. The whole card moves when the watcher records its own run.

  """
  use Kati.Screens.Pushed, back: "Home"

  require Ash.Query

  alias Kati.Components.MishkaSeparator
  alias Kati.Library.Sample
  alias Kati.Media.CachedEpisode
  alias Kati.Media.CachedSeason
  alias Kati.Media.CachedTitle
  alias Kati.Media.Release
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Theme.Palette
  alias Kati.UI

  # How far back `Out now` reaches. See the moduledoc: nothing stores when the
  # watcher last swept, so "new" has to be a window, and this one bounds a
  # display rather than an alarm.
  @recent_days 7

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :inbox, inbox())

  @doc """
  The inbox this screen draws: the user's releases, or the drawing's.

  The gate is `:followed` being empty, which is the fresh install — not either
  list being empty, because "nothing is out this week" is a true thing for this
  screen to say and the drawing's three rows would be a false one.
  """
  @spec inbox() :: map()
  def inbox, do: releases() || drawn_inbox()

  @doc """
  Screen 05 exactly as it is drawn.

  `Kati.Library.Sample` for the watcher card and the Out now rows; the
  coming-up rows are `coming_up_rows/0`, which is stated in this module and
  says why in its own doc.
  """
  @spec drawn_inbox() :: map()
  def drawn_inbox, do: %{Sample.inbox() | coming_up: coming_up_rows()}

  @doc """
  The user's own releases, or `nil` when they follow nothing.

  `nil` is the ordinary answer on a fresh install and the one `inbox/0` reads as
  *draw the drawing*. A database that cannot be read at all answers `nil` too:
  `Ash.read!` on a device mid-migration raises, and a screen that dies is
  strictly worse than a screen showing the values it was drawn from — the same
  degradation `Kati.Screens.Library.shelf/0` and `Kati.Calendars.Today` make.
  """
  @spec releases() :: map() | nil
  def releases do
    case followed() do
      [] -> nil
      tracked -> assemble(tracked)
    end
  rescue
    _ -> nil
  end

  # The watcher card is untouched — see the moduledoc — so the real inbox is the
  # drawn one with its two lists replaced. Laying it over the drawn map rather
  # than building a fresh one is what keeps "which parts are still the design's"
  # a single visible line instead of an omission.
  defp assemble(tracked) do
    cache = cached_titles(tracked)
    episodes = scheduled_episodes(tracked)
    now = Kati.Time.now()

    %{
      drawn_inbox()
      | out_now: out_now_rows(tracked, cache, episodes, ticked_ids(tracked), now),
        coming_up: upcoming_rows(tracked, cache, episodes, scheduled_seasons(tracked), now)
    }
  end

  defp followed do
    TrackedTitle
    |> Ash.Query.for_read(:followed)
    |> Ash.read!()
  end

  # One read for every poster and every show name on the screen, keyed by the
  # `{source, source_id}` pair the durable rows reference the cache by — a
  # value, never a foreign key, which is what lets the cache be wiped underneath
  # them.
  defp cached_titles(tracked) do
    CachedTitle
    |> Ash.Query.filter(source_id in ^source_ids(tracked))
    |> Ash.read!()
    |> Map.new(&{{&1.source, &1.source_id}, &1})
  end

  # Everything a followed title has scheduled from a week ago onwards: the same
  # rows serve both lists, split by `Kati.Media.Release.airing/2` rather than by
  # two queries that could disagree about where the line is.
  #
  # The read is bounded below and not above. A title with fifty announced
  # episodes genuinely has fifty things coming up, and a cap chosen here would
  # be a policy this screen invented; the floor is the `Out now` window and is
  # the one bound the moduledoc argues for.
  defp scheduled_episodes(tracked) do
    references = references(tracked)

    CachedEpisode
    |> Ash.Query.filter(title_source_id in ^source_ids(tracked) and air_at >= ^horizon())
    |> Ash.read!()
    |> Enum.filter(&MapSet.member?(references, {&1.source, &1.title_source_id}))
  end

  defp scheduled_seasons(tracked) do
    references = references(tracked)

    CachedSeason
    |> Ash.Query.filter(title_source_id in ^source_ids(tracked) and air_at >= ^horizon())
    |> Ash.read!()
    |> Enum.filter(&MapSet.member?(references, {&1.source, &1.title_source_id}))
  end

  # `title_source_id in ids` can match a row from a different provider that
  # happens to use the same id, so the pair is checked in memory afterwards —
  # `Kati.Screens.Lock.airing_today/1` makes the same move for the same reason.
  defp references(tracked), do: MapSet.new(tracked, &{&1.source, &1.source_id})
  defp source_ids(tracked), do: tracked |> Enum.map(& &1.source_id) |> Enum.uniq()

  # `Kati.Time.now/0` and not UTC: a screen reads the device's clock through
  # `Kati.Time` and `Kati.ScreenDateTest` fails the build over it. Shifted back
  # to UTC only to be compared with a stored instant, which is what the column
  # holds.
  defp horizon do
    Kati.Time.now()
    |> DateTime.add(-@recent_days * 24 * 60 * 60, :second)
    |> Kati.Time.in_zone("Etc/UTC")
  end

  # Every episode the user has already ticked, across the followed titles. One
  # read; membership is the only question asked of it, which is why
  # `Kati.Media.CachedEpisode.ticked_ids/1` answers a `MapSet`.
  defp ticked_ids(tracked) do
    ids = Enum.map(tracked, & &1.id)

    Watch
    |> Ash.Query.filter(tracked_title_id in ^ids and not is_nil(episode_source_id))
    |> Ash.read!()
    |> CachedEpisode.ticked_ids()
  end

  # ── Out now ────────────────────────────────────────────────────────────────

  defp out_now_rows(tracked, cache, episodes, ticked, now) do
    by_reference = Map.new(tracked, &{{&1.source, &1.source_id}, &1})

    episodes
    |> Enum.reject(&MapSet.member?(ticked, &1.source_id))
    |> Enum.map(&{&1, Release.air(&1)})
    |> Enum.filter(fn {_episode, air} -> Release.airing(air, now) == :aired end)
    |> Enum.sort_by(fn {_episode, air} -> resolved_date(air) end, {:desc, Date})
    |> Enum.map(fn {episode, air} ->
      tracked_row = Map.get(by_reference, {episode.source, episode.title_source_id})
      out_now_row(episode, air, cached_for(tracked_row, cache), now)
    end)
  end

  # The show's name and poster, the episode's number and name, and how long it
  # is beside when it went out. `dot` is the design's orange in every real row:
  # its green is the film premiere this list deliberately does not hold.
  defp out_now_row(episode, air, cached, now) do
    %{
      title: show_title(cached),
      seed: cached && cached.poster_path,
      line: episode_line(episode),
      meta: join([episode_runtime(episode), aired_label(air, now)]),
      dot: Palette.accent()
    }
  end

  # `S2 E6 — Ash and After`, and each half is dropped rather than faked: an
  # episode a source left unnumbered has no `S2 E6`, and one announced without a
  # name has no title. `Kati.Media.CachedEpisode` calls `TBA` *"a string a
  # provider invented"*, so nothing stands in for either.
  defp episode_line(episode) do
    [number_label(episode), episode.title]
    |> Enum.reject(&blank?/1)
    |> Enum.join(" — ")
  end

  defp number_label(%CachedEpisode{season_number: s, episode_number: e})
       when is_integer(s) and is_integer(e),
       do: "S#{s} E#{e}"

  defp number_label(%CachedEpisode{episode_number: e}) when is_integer(e), do: "E#{e}"
  defp number_label(%CachedEpisode{}), do: nil

  # `48 min`, the drawing's own unit for an episode.
  defp episode_runtime(%CachedEpisode{runtime_minutes: m}) when is_integer(m) and m > 0 do
    "#{m} min"
  end

  defp episode_runtime(%CachedEpisode{}), do: nil

  # `aired 20:00` for something that went out today, `aired 6 Aug` for anything
  # older: an hour with no day is only a useful answer while the day is obvious.
  defp aired_label(air, now) do
    case air do
      {:exact, at, _origin} -> exact_aired(at, now)
      {:day, date, _origin} -> "aired " <> Calendar.strftime(date, "%-d %b")
      _coarse -> nil
    end
  end

  defp exact_aired(at, now) do
    local = Kati.Time.in_zone(at, Kati.Time.device_zone())

    if DateTime.to_date(local) == DateTime.to_date(now) do
      "aired " <> Calendar.strftime(local, "%H:%M")
    else
      "aired " <> Calendar.strftime(local, "%-d %b")
    end
  end

  # ── Coming up ──────────────────────────────────────────────────────────────

  # One dated row per thing a followed title has ahead of it: its episodes, its
  # season drops, and — for a film only — the title's own next release. See the
  # moduledoc for why a series contributes no title-level row.
  defp upcoming_rows(tracked, cache, episodes, seasons, now) do
    by_reference = Map.new(tracked, &{{&1.source, &1.source_id}, &1})

    (episode_candidates(episodes, by_reference) ++
       season_candidates(seasons, by_reference) ++
       film_candidates(tracked, cache))
    |> Enum.filter(fn {_row, _airing, air} -> resolved_date(air) != nil end)
    |> Enum.filter(fn {_row, _airing, air} -> Release.airing(air, now) != :aired end)
    |> Enum.sort_by(fn {_row, _airing, air} -> resolved_date(air) end, Date)
    |> Enum.map(fn {tracked_row, airing, air} ->
      upcoming_row(tracked_row, airing, air, cached_for(tracked_row, cache))
    end)
  end

  defp episode_candidates(episodes, by_reference) do
    for episode <- episodes,
        tracked_row = Map.get(by_reference, {episode.source, episode.title_source_id}),
        tracked_row != nil,
        do: {tracked_row, episode, Release.air(episode)}
  end

  defp season_candidates(seasons, by_reference) do
    for season <- seasons,
        tracked_row = Map.get(by_reference, {season.source, season.title_source_id}),
        tracked_row != nil,
        do: {tracked_row, season, Release.air(season)}
  end

  defp film_candidates(tracked, cache) do
    for row <- tracked,
        row.kind == :movie,
        cached = cached_for(row, cache),
        do: {row, :title, Release.resolve(row, cached)}
  end

  defp upcoming_row(tracked_row, airing, air, cached) do
    date = resolved_date(air)

    %{
      month: date |> Calendar.strftime("%b") |> String.upcase(),
      day: Calendar.strftime(date, "%d"),
      title: upcoming_title(show_title(cached), airing),
      line: upcoming_line(airing, air),
      armed: armed?(tracked_row, airing, cached)
    }
  end

  # `The Long Hollow — S2E6`, `Nightbirds — Season 2`, `Vellum`. The drawing
  # writes an episode's number without the space it uses elsewhere, and that is
  # the drawing's own typography rather than a second numbering scheme.
  defp upcoming_title(title, %CachedEpisode{} = episode) do
    case number_label(episode) do
      nil -> title
      label -> title <> " — " <> String.replace(label, " ", "")
    end
  end

  defp upcoming_title(title, %CachedSeason{} = season) do
    title <> " — " <> season_label(season)
  end

  defp upcoming_title(title, :title), do: title

  defp season_label(%CachedSeason{name: name}) when is_binary(name) and name != "", do: name
  defp season_label(%CachedSeason{season_number: 0}), do: "Specials"
  defp season_label(%CachedSeason{season_number: n}), do: "Season #{n}"

  # The drawing puts a service and an hour here and there is no service, so what
  # is left is the hour — plus, for an episode, its own name, which is the one
  # thing on this row a provider does supply. A date known only to the day has
  # no hour, and nothing is invented to fill the line.
  defp upcoming_line(%CachedEpisode{} = episode, air) do
    join([episode.title, time_label(air)])
  end

  defp upcoming_line(_airing, air), do: join([time_label(air)])

  defp time_label({:exact, at, _origin}) do
    at |> Kati.Time.in_zone(Kati.Time.device_zone()) |> Calendar.strftime("%H:%M")
  end

  defp time_label(_resolution), do: nil

  # The filled orange bell is a row an alarm can actually be set for, and the
  # hollow one is a row that is only listed. Asked of `Kati.Media.Release`'s own
  # gate rather than by comparing a date here: a muted show and a date coarser
  # than a day are both suppressed there, and this screen must not honour one
  # rule and forget the other.
  defp armed?(tracked_row, :title, cached) do
    match?({:ok, _at}, Release.alarm_at(tracked_row, cached))
  end

  defp armed?(tracked_row, airing, _cached) do
    match?({:ok, _at}, Release.alarm_for(tracked_row, airing))
  end

  # ── Shared ─────────────────────────────────────────────────────────────────

  defp cached_for(nil, _cache), do: nil
  defp cached_for(row, cache), do: Map.get(cache, {row.source, row.source_id})

  # The name the cache holds, and `Untitled` when it has been evicted — the
  # answer `Kati.Screens.Film` and `Kati.Screens.UpNext` already give. Screen 03
  # drops such a row instead, because there a nameless tile among nine named
  # ones says nothing; here the row still carries the episode number, its name
  # and its hour, which is most of the news.
  defp show_title(%CachedTitle{title: title}) when is_binary(title) and title != "", do: title
  defp show_title(_cached), do: "Untitled"

  defp resolved_date({:exact, at, _origin}) do
    at |> Kati.Time.in_zone(Kati.Time.device_zone()) |> DateTime.to_date()
  end

  defp resolved_date({:day, date, _origin}), do: date
  defp resolved_date(_resolution), do: nil

  defp join(parts), do: parts |> Enum.reject(&blank?/1) |> Enum.join(" · ")

  defp blank?(nil), do: true
  defp blank?(""), do: true
  defp blank?(_value), do: false

  @doc false
  def content(assigns) do
    inbox = assigns.inbox

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {Kati.Screens.Inbox.mark_all()}
        {Kati.Screens.Inbox.title(inbox)}
        {Kati.Screens.Inbox.watcher(inbox)}
        {UI.eyebrow("Out now · #{length(inbox.out_now)}")}
        {Kati.Screens.Inbox.out_now(inbox)}
        {Kati.UI.eyebrow("Coming up", dash: Palette.rail_idle(), gap: 12)}
        {Kati.Screens.Inbox.coming_up(inbox)}
      </Column>
    </Scroll>
    """
  end

  # The back pill is drawn by Kati.Screens.Pushed; this row reserves its height
  # and carries the Mark all action opposite it. The height is the PILL's 44,
  # not the 36 of the control inside it — the drawing centres a 36 pill against
  # a 44 one, and a row that measured 36 pulled the title and everything under
  # it 8 up the frame.
  @doc false
  def mark_all do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} height={44} align="center">
        <Spacer weight={1.0} />
        <Row
          height={36}
          corner_radius={18}
          background={Palette.placeholder()}
          padding_left={14}
          padding_right={14}
          align="center"
        >
          <Text
            text="Mark all"
            text_size={12.5}
            font_weight="semibold"
            text_color={:on_surface}
            max_lines={1}
          />
        </Row>
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  The three dated rows the **drawing** puts in the Coming up card.

  Stated here rather than taken from `Kati.Library.Sample`, whose list had
  drifted to a different three titles with a mono day/time where the design
  draws a bell. The drawing is the authority for this card: an air date that
  is already being watched for (a filled orange `notifications_active`) and
  two that are only listed (a hollow `notifications`).

  `drawn_inbox/0` lays these over the Sample map, so the fallback this screen
  answers with is one value rather than a map beside a list — which is what lets
  `Kati.ScreenEmptyDatabaseTest` compare `inbox/0` with it as a term.
  """
  @spec coming_up_rows() :: [map()]
  def coming_up_rows do
    [
      %{
        month: "AUG",
        day: "20",
        title: "The Long Hollow — S2E6",
        line: "Lumen+ · 20:00",
        armed: true
      },
      %{month: "SEP", day: "04", title: "Vellum", line: "In cinemas", armed: false},
      %{
        month: "SEP",
        day: "12",
        title: "Nightbirds — Season 2",
        line: "Full season drop",
        armed: false
      }
    ]
  end

  @doc false
  def title(inbox) do
    subtitle = "#{length(inbox.out_now)} out now · #{length(inbox.coming_up)} coming up"

    ~MOB"""
    <Column fill_width={true}>
      <Text
        text="New releases"
        text_size={28}
        font_weight="bold"
        letter_spacing={-0.03}
        text_color={:on_surface}
      />
      <Spacer size={5} />
      <Text
        text={subtitle}
        font_family="mono"
        text_size={11}
        text_color={Palette.muted()}
        max_lines={1}
      />
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def watcher(inbox) do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.cream()}
        corner_radius={20}
        padding_left={17}
        padding_right={17}
        padding_top={15}
        padding_bottom={15}
        align="center"
      >
        {Kati.UI.symbol("auto_awesome", size: 22, color: Palette.gold_icon())}
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text
            text={"Watching for #{inbox.watching} titles"}
            text_size={13.5}
            font_weight="bold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={4} />
          <Text
            text={inbox.last_checked}
            font_family="mono"
            text_size={10.5}
            text_color={Palette.cream_meta()}
            max_lines={1}
          />
        </Column>
        <Spacer size={12} />
        {Kati.UI.symbol("settings", size: 19, color: Palette.gold_icon())}
      </Row>
      <Spacer size={26} />
    </Column>
    """
  end

  @doc false
  def out_now(inbox) do
    ~MOB"""
    <Column fill_width={true}>
      {inbox.out_now
       |> Enum.map(fn row -> Kati.Screens.Inbox.release_row(row) end)
       |> Enum.intersperse(Kati.Screens.Inbox.row_gap())}
      <Spacer size={26} />
    </Column>
    """
  end

  @doc false
  def release_row(row) do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.card()}
        corner_radius={18}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={13}
        padding_right={13}
        padding_top={11}
        padding_bottom={11}
        align="center"
      >
        {Kati.Screens.Inbox.thumb(row)}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Row fill_width={true} align="center">
            <Box width={6} height={6} corner_radius={3} background={row.dot} />
            <Spacer size={7} />
            <Text
              text={row.title}
              text_size={14}
              font_weight="bold"
              letter_spacing={-0.015}
              text_color={:on_surface}
              max_lines={1}
            />
          </Row>
          <Spacer size={5} />
          <Text text={row.line} text_size={12} text_color={Palette.ink_soft()} max_lines={1} />
          <Spacer size={4} />
          <Text
            text={row.meta}
            font_family="mono"
            text_size={10.5}
            text_color={Palette.tertiary()}
            max_lines={1}
          />
        </Column>
        <Spacer size={13} />
        <Row
          height={32}
          corner_radius={16}
          background={Palette.ink_fill()}
          padding_left={14}
          padding_right={14}
          align="center"
        >
          <Text
            text="Watch"
            text_size={12}
            font_weight="semibold"
            text_color={Palette.on_ink()}
            max_lines={1}
          />
        </Row>
      </Row>
    </Column>
    """
  end

  @doc false
  def row_gap, do: ~MOB"<Spacer size={9} />"

  # `Kati.Design.Images.poster/1` rather than `Kati.Library.Sample.poster/1` —
  # the Sample function is a one-line delegation to it, and a real row's seed now
  # arrives on `Kati.Media.CachedTitle.poster_path` (see `out_now_row/4`), so
  # routing it through the fixture module would be a lie about where the value
  # came from. Screens 03 and 08 made the same move for the same reason.
  @doc false
  def thumb(row) do
    case Kati.Design.Images.poster(row[:seed]) do
      nil ->
        ~MOB"<Box width={44} height={62} corner_radius={9} background={Palette.placeholder()} />"

      src ->
        ~MOB"""
        <Image src={src} width={44} height={62} corner_radius={9} content_mode="fill" />
        """
    end
  end

  @doc false
  def coming_up(inbox) do
    rows = inbox.coming_up
    last = length(rows) - 1

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card()}
      padding_left={15}
      padding_right={15}
      padding_top={4}
      padding_bottom={4}
    >
      {rows
       |> Enum.with_index()
       |> Enum.map(fn {row, i} -> Kati.Screens.Inbox.upcoming_row(row, i < last) end)}
    </Column>
    """
  end

  @doc false
  def upcoming_row(row, rule?) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={14} padding_bottom={14}>
        <Column width={42} align="center">
          <Text
            text={row.month}
            font_family="mono"
            text_size={10}
            letter_spacing={0.1}
            text_color={Palette.muted()}
            text_align="center"
          />
          <Text
            text={row.day}
            text_size={17}
            font_weight="bold"
            letter_spacing={-0.02}
            text_color={:on_surface}
            text_align="center"
          />
        </Column>
        <Spacer size={14} />
        <Column weight={1.0}>
          <Text
            text={row.title}
            text_size={13.5}
            font_weight="semibold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={3} />
          <Text text={row.line} text_size={11.5} text_color={Palette.sub()} max_lines={1} />
        </Column>
        <Spacer size={14} />
        {Kati.Screens.Inbox.bell(row.armed)}
      </Row>
      {Kati.Screens.Inbox.hairline(rule?)}
    </Column>
    """
  end

  # Armed is the filled bell in accent; listed is the hollow one in #C4BDB3.
  @doc false
  def bell(true),
    do: Kati.UI.symbol("notifications_active", size: 19, color: Palette.accent(), fill: true)

  def bell(false), do: Kati.UI.symbol("notifications", size: 19, color: Palette.rail_idle())

  # Chelekom's headless Separator, given the design's own 7%-ink rule colour.
  #
  # `render: :box` is load-bearing, and the comment that used to sit here was
  # wrong about why. The default `:divider` is NOT the hand-rolled Box this
  # replaced: the bridge maps it to Material3's `HorizontalDivider`, which is a
  # Canvas drawing an ANTIALIASED `drawLine`, not a filled rect. At this
  # device's 2.6875x a 1dp rule gets a 3px canvas and a 2.6875px stroke, so the
  # last pixel row lands at ~69% coverage — a hairline 4-5/255 lighter than the
  # design's on one full-width row. `render: :box` swaps the primitive back to
  # `<Box fill_width height={1} background={color}>`, which is the node this
  # screen drew by hand, so every pixel row carries the full colour again.
  @doc false
  def hairline(false), do: ~MOB"<Spacer size={0} />"

  def hairline(true),
    do: MishkaSeparator.separator(color: Palette.hairline(), thickness: 1, render: :box)
end
