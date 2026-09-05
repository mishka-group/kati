defmodule Kati.Screens.Series do
  @moduledoc """
  Screen 04 — a series, pushed under Library.

  Built to `test/design/screens/04.html`. The shape is a 330pt artwork
  block with a 190pt gradient lifting the paper back over it, floating chrome
  at 60pt, and the title sitting on the gradient rather than in a bar.

  The chrome here is the screen's own, not `Kati.Screens.Pushed`'s: this back
  pill floats over artwork at `rgba(251,250,248,.82)` and carries the label
  inline, where the standard pushed chrome sits on paper. Matching the drawing
  matters more than sharing a helper.

  Three episode states are drawn and all three are exercised by the sample:
  watched (muted title, filled check), unwatched (ink title, hollow check),
  and not yet aired (muted, no check).

  ## Where the data comes from

  `Kati.Media`, through `tracked_series/0`.

  **This moduledoc used to say the opposite, at length, and it was wrong.** It
  read that `Kati.Media` has no episode, that nothing anywhere could answer
  *what is S2E6 called*, *how long is it* or *when did it air*, and that there
  is no season resource and no season count. Every one of those sentences was
  true when it was written and none of them survived
  `20260821231241_media_seasons_and_episodes`: `Kati.Media.CachedEpisode` and
  `Kati.Media.CachedSeason` were built naming this screen — `for_season/3` is
  *"one season's episodes, in aired order"*, `CachedEpisode.watched_of/2` is
  *"the counter screen 04 draws as `5 of 7 watched`"*, and
  `CachedSeason.count/1` is *"how many seasons a title has — screen 04's `3
  SEASONS`"*. A stale blocker is worse than no comment at all: a Persian agent
  read this one while blocked on 58, correctly declined to re-derive somebody
  else's decision from it, and the round was spent.

  Five reads, never one per row: the top of the series shelf (`:tv` and
  `:anime`, one each), the one cache row it names, that title's seasons, that
  title's episodes, and its episode ticks. The cache is reached by
  `{source, source_id}` because that is what a tracked row holds — a value
  pair, not a foreign key — so an evicted poster cannot take the ticks down
  with it.

  ### Which value comes from where, and why not from somewhere nearer

    * **the episode list** — `Kati.Media.CachedEpisode.for_title/2`, sliced per
      season in memory rather than re-read per pill. Each row's name, runtime
      and air date are that resource's `title`, `runtime_minutes` and `air_at`.
    * **the S1/S2/S3 strip and `3 SEASONS`** — `Kati.Media.CachedSeason`, and
      **not** `CachedEpisode.seasons/1`. That distinction is the whole reason
      the season resource exists: the inventory is authoritative *before* every
      episode is fetched, and a three-season show with only S2 cached would
      otherwise draw `1 SEASON` — a confident, specific, wrong number with
      nothing on screen to mark it as a fetch artefact. `count/1` answering `0`
      is *nothing to say*, so the meta line drops the clause rather than
      claiming a series with no seasons.
    * **`5 of 7 watched`** — the numerator is `Kati.Media.Watch` ticks, counted
      by membership; the denominator is `CachedSeason.denominator/1`, falling
      back to how many episodes are cached. The provider's count is the honest
      total when the cached list is short, and it is guarded against a stored
      zero, which is a source declining to answer rather than a season of
      nothing. Never stored: two places that both know "5 of 7" disagree the
      first time an episode is ticked.
    * **`Next episode airs …`** — `Kati.Media.Release`, and only
      `Kati.Media.Release`. #74's rule is that a coarse date never becomes a
      day, so `air_label/3` renders a `{:quarter, 2026, 3}` as a quarter and
      never as 1 July, and an episode with nothing known draws no row at all
      rather than a dash. `Release.airing/2` is likewise what decides whether a
      row is unaired, so the third episode state is an entailment rather than a
      date comparison written out a second time here.

  ### The gate is the whole screen

  Either every value on the page is this user's or every value is the drawing's
  — a page whose title is a real series and whose episode list is somebody
  else's season reads as entirely real. `tracked_series/0` therefore answers
  `nil` for a shelf with no series *and* for a series with no numbered season
  cached anywhere: this page is an inventory and a list, and with neither there
  is nothing on it that is the user's. A tick names an episode id and cannot
  name an episode.

  With nothing to draw, `Kati.Library.Sample` is drawn instead — the values
  `test/design/screens/04.html` was captured from. FIDELITY's rule:
  *missing data is not a reason for a blank screen*. The Sample module stays
  exactly where it is; it is the fallback and the fixture, not a stage this
  screen has passed through.

  ## What no resource can express, and is therefore not drawn

  Both live in the meta line, and both are drawn in full on the fallback,
  because there they are the drawing rather than a claim about a title.

    * **`LUMEN+`** — availability. `Kati.Media.Watch.service` is where the
      *user* watched something, which is a different fact, is per-watch, and
      says nothing about where a series can be watched now. Screen 08 wants the
      same thing for its `Where to watch` card and gets the same answer: what
      this needs is an offers resource per `{title, service, region}`.
    * **`2024`** — the first-air year. `Kati.Media.CachedTitle` holds
      `next_release_at`, which is the NEXT release; reading it as the first
      would print next Tuesday's date as a series' debut year. A `first_air_at`
      column is the direct answer and belongs to whoever owns that resource.

  The line degrades to `DRAMA · 3 SEASONS`, which is `genres` and the season
  inventory and nothing else — the same shape `Kati.Screens.Film.meta_line/1`
  degrades to for the same reason.

  `Kati.Media.TrackedTitle.hide_unwatched_titles` is annotated *"spoiler-safe
  episode names on screen 04"* and is the one column here with a reader and no
  feature; the drawing never shows that state, so nothing reads it yet.
  """
  use Mob.Screen
  import Mob.Sigil

  # No `require Ash.Query`: every read below is an action by name, so nothing
  # here builds a `filter` expression. The one filter this screen needs — the
  # cache row a tracked title points at — is `Kati.Media.Release.cached_for/1`,
  # which is where that value-pair lookup already lives.
  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaProgress
  alias Kati.Library.Sample
  alias Kati.Media.CachedEpisode
  alias Kati.Media.CachedSeason
  alias Kati.Media.CachedTitle
  alias Kati.Media.Release
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Theme
  alias Kati.Theme.Palette

  # What this screen considers a series. `Kati.Screens.Library.poster/1` sends
  # everything that is not a film here, and `:book` / `:album` are the shelves
  # #60 draws inactive, so these two are the whole of it.
  @series_kinds [:tv, :anime]

  # `use Mob.Screen` and not `Kati.Screens.Root`, so this screen's own `mount/3`
  # takes the push's params directly. `Map.get/2` rather than a pattern match on
  # the key, so a bare push — the gallery's, every sweep's — still gets the top
  # of the shelf, which is what this screen has always drawn.
  def mount(params, _session, socket) do
    Mob.Theme.set(Kati.Theme.current())

    {:ok,
     socket
     |> Mob.Socket.assign(:series, series(Map.get(params || %{}, :id)))
     |> Mob.Socket.assign(:menu?, false)}
  end

  @doc """
  The series this screen draws: the user's, or the drawing's.

  The English page. `tracked_series/1` is the half that reads the store and it
  answers in no language at all; everything below this line is presentation,
  which is what lets `Kati.Screens.SeriesFa` share the reads without sharing
  the wording.

  `id` is the tracked row a poster carried here. Without one the referent is
  the top of the shelf, which is what every arrival used to get.
  """
  @spec series(String.t() | nil) :: map()
  def series(id \\ nil) do
    case tracked_series(id) do
      nil -> drawn_series()
      facts -> shaped(facts)
    end
  end

  @doc """
  Screen 04 exactly as it is drawn, from `Kati.Library.Sample`.

  Kept in the fixture rather than inlined here: it is the frame's specification
  and the fixture the tests compare a real render against, and two copies of the
  drawing's copy is exactly how the two drift apart.

  `by_season/0`'s three entries are added on the way out, because the S1/S2/S3
  pills are a real control and a control that changes nothing is a lie told in
  pixels. The drawn season is unchanged — `Sample.season_episodes/1` answers
  `series/0`'s own list for S2 — so the captured frame is untouched.
  """
  @spec drawn_series() :: map()
  def drawn_series do
    drawn = Sample.series()

    by_season =
      Map.new(drawn.seasons, fn label ->
        episodes = Sample.season_episodes(label)

        {label,
         %{
           season: "Season " <> String.trim_leading(label, "S"),
           total: length(episodes),
           episodes: episodes
         }}
      end)

    Map.put(drawn, :by_season, by_season)
  end

  # ── Reading `Kati.Media` ────────────────────────────────────────────────────

  @doc """
  What `Kati.Media` knows about the series this screen draws, or `nil`.

  **The facts, in no language.** Numbers, resolutions and booleans — no
  formatted date, no pluralised noun, no `Season 2`. `Kati.Screens.SeriesFa`
  calls this rather than copying the query, the way
  `Kati.Screens.LibraryFa` calls `Kati.Screens.Library.shelf/0`: one series,
  read once, presented twice. A second query written out over there could
  disagree with this one about which title is on top, which season the bookmark
  names, or which episodes are ticked, and the first eviction would be the day
  it did.

  **Which series.** The one the caller names, and otherwise the one the shelf
  itself puts first. `:shelf` decides both: it is the action
  `Kati.Media.TrackedTitle` names for "screens 03, 20 and 21" and it is where
  *keeps history, hides from shelf* is enforced, so a title read around it
  would be a title the user archived, reachable again by id. Two reads because
  `:tv` and `:anime` are two sections of one shelf, re-sorted as one because
  `last_touched_at` is the order and it does not restart per kind.

  An id that names no shelf row answers `nil` rather than the shelf's head.
  That is `Kati.Screens.BookDetail.shelved_book/1`'s rule and its reason:
  a title archived or deleted under the user is not the same fact as an empty
  shelf, and quietly showing a different show is the swap this argument exists
  to prevent.

  `nil` is the ordinary answer on a fresh install, and a database that cannot
  be read at all answers `nil` too: `Ash.read!` on a device mid-migration
  raises, and a screen that dies is strictly worse than a screen showing the
  values it was drawn from — the same degradation `Kati.Screens.Film` and
  `Kati.Calendars.Today` make.
  """
  @spec tracked_series(String.t() | nil) :: map() | nil
  def tracked_series(id \\ nil) do
    case series_record(id) do
      nil -> nil
      tracked -> facts(tracked)
    end
  rescue
    _ -> nil
  end

  @doc """
  The params that name a series to screen 04, or to its Persian twin.

  Here rather than at each caller so the key is spelled once. The argument is a
  shelf row — `Kati.Screens.Library.shaped/3`'s, or `Kati.Screens.LibraryFa`'s
  copy of it — and the only field on it that is an identity rather than a
  caption is `:id`. A row without one is `Kati.Library.Sample`'s, and it yields
  `%{}`: the drawing has no tracked row to name, and a title carried as a name
  would be a caption pretending to be an identity.

      iex> Kati.Screens.Series.params_for(%{id: "abc", title: "The Long Hollow"})
      %{id: "abc"}

      iex> Kati.Screens.Series.params_for(%{title: "The Long Hollow"})
      %{}
  """
  @spec params_for(map() | nil) :: map()
  def params_for(%{id: id}) when is_binary(id), do: %{id: id}
  def params_for(_row), do: %{}

  # The series the caller named, or — given no id — the top of the shelf.
  # `Enum.find` over the SAME `:shelf` reads rather than an `Ash.Query.filter`
  # expression, so this screen goes on reading by action name only and the note
  # beside the aliases stays true. The per-kind `limit(1)` is deliberately gone
  # from this direction: the row the caller named need not be the newest of its
  # kind, and `newest_series/0` — which does need it — is left alone below.
  defp series_record(nil), do: newest_series()

  defp series_record(title_id) do
    @series_kinds
    |> Enum.flat_map(fn kind ->
      TrackedTitle
      |> Ash.Query.for_read(:shelf, %{kind: kind})
      |> Ash.read!()
    end)
    |> Enum.find(&(&1.id == title_id))
  end

  # The top of the series shelf, newest touch first across both kinds.
  defp newest_series do
    @series_kinds
    |> Enum.flat_map(fn kind ->
      TrackedTitle
      |> Ash.Query.for_read(:shelf, %{kind: kind})
      |> Ash.Query.limit(1)
      |> Ash.read!()
    end)
    |> Enum.max_by(& &1.last_touched_at, DateTime, fn -> nil end)
  end

  # Four more reads, all of them by the VALUE PAIR the durable half references
  # the cache by. `season_numbers/2` answering `[]` is the second half of the
  # gate — see the moduledoc.
  defp facts(tracked) do
    cached = Release.cached_for(tracked)
    seasons = CachedSeason.for_title(tracked.source, tracked.source_id)
    episodes = CachedEpisode.for_title(tracked.source, tracked.source_id)

    case season_numbers(seasons, episodes) do
      [] -> nil
      numbers -> assembled(tracked, cached, seasons, episodes, numbers)
    end
  end

  defp assembled(tracked, cached, seasons, episodes, numbers) do
    ticked = tracked |> episode_ticks() |> CachedEpisode.ticked_ids()
    now = Kati.Time.now()
    inventory = Map.new(seasons, &{&1.season_number, &1})
    grouped = Enum.group_by(episodes, & &1.season_number)

    %{
      title: cached && cached.title,
      seed: seed_of(tracked, cached),
      # The row a tick belongs to. Carried on the assembled map rather than
      # re-read in the handler, so the page cannot write a tick against a
      # different title from the one it is drawing.
      tracked_id: tracked.id,
      genres: cached && cached.genres,
      # The inventory's count, never `length(numbers)` — see the moduledoc.
      season_count: CachedSeason.count(seasons),
      seasons:
        Enum.map(
          numbers,
          &season_facts(&1, Map.get(inventory, &1), Map.get(grouped, &1, []), ticked, now)
        ),
      current: current_number(tracked, numbers),
      next_air: next_airing(episodes, now)
    }
  end

  # The strip's own list. The inventory first, because it knows about a season
  # before a single episode of it is cached; the episodes' own numbers only
  # when there is no inventory at all, and marked as the weaker answer by being
  # second rather than by a comment at the call site.
  #
  # Specials are out of both. `Kati.Media.CachedSeason.numbered/1` drops them
  # from the inventory because "3 seasons" has never meant "2 seasons and a
  # making-of", and dropping season 0 from the derived list keeps the strip and
  # the count from disagreeing about the same show. Screen 34 is where a
  # special is in the order and out of the count.
  defp season_numbers(seasons, episodes) do
    case CachedSeason.numbered(seasons) do
      [] -> episodes |> CachedEpisode.seasons() |> Enum.reject(&(&1 == 0))
      rows -> Enum.map(rows, & &1.season_number)
    end
  end

  # `progress_season` is a bookmark — `Kati.Media.TrackedTitle` is explicit that
  # it is not an inventory — so it decides which pill is lit and nothing else.
  # A bookmark pointing at a season that is not in the strip (renumbered,
  # evicted, never fetched) falls to the first one rather than lighting nothing.
  defp current_number(%TrackedTitle{progress_season: n}, numbers) do
    if n in numbers, do: n, else: List.first(numbers)
  end

  defp season_facts(number, inventory, episodes, ticked, now) do
    %{
      number: number,
      name: inventory && inventory.name,
      # The provider's count when it gave one, and how many are cached when it
      # did not. `denominator/1` is what turns a stored zero back into nil.
      total: CachedSeason.denominator(inventory) || length(episodes),
      episodes: Enum.map(episodes, &episode_facts(&1, ticked, now))
    }
  end

  defp episode_facts(episode, ticked, now) do
    air = Release.air(episode)

    %{
      number: episode.episode_number,
      title: episode.title,
      runtime: episode.runtime_minutes,
      air: air,
      airing: Release.airing(air, now),
      watched: CachedEpisode.ticked?(episode, ticked),
      # What a tick is written against. `Kati.Media.Watch` names an episode by
      # `episode_source_id` and nothing else, so a row drawn without one can be
      # flipped on screen and never persisted — which is what #90 opened on.
      source_id: episode.source_id
    }
  end

  # The next episode is the first one still ahead, in aired order — which is
  # the order `for_title/2` already answers in and the order the drawing's own
  # "next" runs in. `:upcoming` and not `:unknown`: an episode Kati cannot
  # place is not a date to announce, and `Release.airing/2` is deliberate about
  # keeping the two apart.
  defp next_airing(episodes, now) do
    Enum.find_value(episodes, :unknown, fn episode ->
      air = Release.air(episode)
      if Release.airing(air, now) == :upcoming, do: air
    end)
  end

  defp episode_ticks(%TrackedTitle{id: id}) do
    Watch
    |> Ash.Query.for_read(:episode_ticks, %{tracked_title_id: id})
    |> Ash.read!()
  end

  # `Kati.Seeds` writes the design seed straight into `poster_path` — "not a
  # TMDB path: the sample artwork is resolved by seed" — and `sample_seed/1` is
  # the other half of that convention, so a row whose cache has been evicted can
  # still find its picture. Screen 08's `seed_of/2` is the same two clauses.
  defp seed_of(tracked, cached) do
    case cached do
      %CachedTitle{poster_path: path} when is_binary(path) and path != "" -> path
      _ -> Kati.Seeds.sample_seed(tracked.source_id)
    end
  end

  # ── The English page ────────────────────────────────────────────────────────

  @doc """
  `tracked_series/0`'s facts in the shape the markup reads.

  Every absence is an ordinary state and none of them invents a value: a title
  the cache has lost is `Untitled` (screen 08's answer, and for its reason —
  here it is the whole page), an episode a provider announced without naming is
  `Episode 6` rather than the `TBA` a provider made up, and an air date nobody
  knows leaves the sub-line to the runtime alone.
  """
  @spec shaped(map()) :: map()
  def shaped(facts) do
    zone = Kati.Time.device_zone()
    by_season = Map.new(facts.seasons, &{label(&1.number), season_view(&1, zone)})
    current = label(facts.current)
    view = Map.fetch!(by_season, current)

    %{
      # `assembled/5` puts `tracked_id` on the facts and this map used to drop
      # it, which is why `tick/2`'s `Map.get(series, :tracked_id)` was always
      # `nil` and no tick on a real series ever reached `write_tick/2`. It is
      # also what the ⋯ menu needs: a row that opens screen 34 has to name the
      # series the page is drawing. `Map.get/2` rather than `facts.tracked_id`
      # so a facts map built without the key raises nothing.
      tracked_id: Map.get(facts, :tracked_id),
      title: facts.title || "Untitled",
      seed: facts.seed,
      meta: meta_line(facts),
      season: view.season,
      seasons: Enum.map(facts.seasons, &label(&1.number)),
      current_season: current,
      total: view.total,
      watched: Enum.count(view.episodes, & &1.watched),
      next_air: next_air_label(facts.next_air, zone),
      episodes: view.episodes,
      by_season: by_season
    }
  end

  # `S2`, which is the strip's label and the tap tag both. ASCII by
  # construction, which is what `String.to_atom/1` and the accessibility id
  # need — the Persian page builds its own and says so.
  defp label(number), do: "S#{number}"

  defp season_view(season, zone) do
    %{
      # The provider's own name when it gave one ("Part 1", "Miniseries"), and
      # the number spelled out when it did not. `Kati.Media.CachedSeason`
      # declines to invent this on purpose: "a screen that wants `Season 2` out
      # of a bare number is the thing that knows what its own heading reads".
      season: season.name || "Season #{season.number}",
      total: season.total,
      episodes: Enum.map(season.episodes, &episode_row(&1, zone))
    }
  end

  # `aired` collapses `Kati.Media.Release.airing/2`'s three answers into the two
  # treatments this drawing has, and `:unknown` is deliberately grouped with
  # `:aired`. That is the affordance answer `Release`'s own typedoc argues for:
  # withholding the tick is a claim the user has not seen it, and the thing Kati
  # does not know is when it went out, not what the user did.
  defp episode_row(episode, zone) do
    %{
      n: episode.number,
      title: episode_title(episode),
      sub: episode_sub(episode, zone),
      watched: episode.watched,
      aired: episode.airing != :upcoming
    }
  end

  defp episode_title(%{title: title}) when is_binary(title) and title != "", do: title
  defp episode_title(%{number: n}) when is_integer(n), do: "Episode #{n}"
  defp episode_title(_episode), do: "Untitled"

  # `Airs Thu 20 Aug` ahead of time and `48 min · 2 Jul` behind it, which are
  # the drawing's own two sub-lines. Both halves of the second are nullable — a
  # provider can decline either — and an absent half is left out rather than
  # spelled as a dash.
  defp episode_sub(%{airing: :upcoming} = episode, zone) do
    case air_label(episode.air, :long, zone) do
      nil -> ""
      label -> "Airs " <> label
    end
  end

  defp episode_sub(episode, zone) do
    [runtime_label(episode.runtime), air_label(episode.air, :short, zone)]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" · ")
  end

  defp runtime_label(m) when is_integer(m) and m > 0, do: "#{m} min"
  defp runtime_label(_minutes), do: nil

  @doc """
  The `2024 · DRAMA · LUMEN+ · 3 SEASONS` line, minus the two nothing stores.

  See the moduledoc: there is no availability and no first-air year, so a real
  series answers `DRAMA · 3 SEASONS` and a series whose provider gave neither a
  genre nor a season inventory answers with an empty line rather than with
  punctuation holding nothing apart.
  """
  @spec meta_line(map()) :: String.t()
  def meta_line(facts) do
    [genre_label(facts.genres), seasons_label(facts.season_count)]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" · ")
  end

  defp genre_label(genres) when is_binary(genres) and genres != "", do: String.upcase(genres)
  defp genre_label(_genres), do: nil

  # `0` is `Kati.Media.CachedSeason.count/1` saying *nothing to say* rather than
  # *a series with no seasons*, so it produces no clause at all.
  defp seasons_label(1), do: "1 SEASON"
  defp seasons_label(n) when is_integer(n) and n > 1, do: "#{n} SEASONS"
  defp seasons_label(_none), do: nil

  # `Thu 20 Aug, 20:00` — the drawing's own format, and the only one of these
  # that carries an hour, because it is the only place a resolution precise
  # enough to have one is drawn.
  defp next_air_label({:exact, at, _origin}, zone) do
    at |> Kati.Time.in_zone(zone) |> Calendar.strftime("%a %-d %b, %H:%M")
  end

  defp next_air_label({:day, date, _origin}, _zone), do: Calendar.strftime(date, "%a %-d %b")
  defp next_air_label({:approximate, period, _origin}, _zone), do: period_label(period)
  defp next_air_label(:unknown, _zone), do: nil

  # #74's rule, kept rather than restated: a resolution coarser than a day has
  # no day in the value at all, so there is nothing here that *could* print one.
  # A quarter draws as a quarter and a bare year as a year.
  defp air_label({:exact, at, _origin}, style, zone) do
    at |> Kati.Time.in_zone(zone) |> DateTime.to_date() |> day_label(style)
  end

  defp air_label({:day, date, _origin}, style, _zone), do: day_label(date, style)
  defp air_label({:approximate, period, _origin}, _style, _zone), do: period_label(period)
  defp air_label(:unknown, _style, _zone), do: nil

  defp day_label(date, :short), do: Calendar.strftime(date, "%-d %b")
  defp day_label(date, :long), do: Calendar.strftime(date, "%a %-d %b")

  defp period_label({:month, year, month}) do
    year |> Date.new!(month, 1) |> Calendar.strftime("%b %Y")
  end

  defp period_label({:quarter, year, quarter}), do: "Q#{quarter} #{year}"
  defp period_label({:year, year}), do: "#{year}"

  # ── The drawn page ──────────────────────────────────────────────────────────

  # The counter and the ring are DERIVED, never stored. Storing "5 of 7" beside
  # a list of episodes means two places can disagree, and the first tap that
  # marks an episode watched is the one that makes them.
  #
  # `total` is NOT recounted here, and that is the change the provider's
  # denominator forced: it is a fact about the season rather than about the list
  # on screen, and `length(episodes)` would quietly overwrite a provider's 7
  # with the 5 that happen to be cached. It is set where a season is chosen —
  # in `handle_info/2` and in `shaped/1` — and a tick cannot change it.
  defp recount(s), do: %{s | watched: Enum.count(s.episodes, & &1.watched)}

  def render(assigns) do
    s = assigns.series
    pct = Kati.Screens.Series.fraction(s)

    ~MOB"""
    <Box
      fill_width={true}
      fill_height={true}
      background={:background}
      layout_direction={Kati.Locale.direction_prop()}
      accessibility_id={Kati.Screens.Identity.of(__MODULE__)}
    >
      <Scroll>
        <Column fill_width={true}>
          {Kati.Screens.Series.artwork(s)}
          <Column
            fill_width={true}
            padding_left={21}
            padding_right={21}
            padding_top={16}
            padding_bottom={40}
          >
            {Kati.Screens.Series.season_card(s, pct)}
            {Kati.Screens.Series.actions()}
            {Kati.Screens.Series.episodes_header(s)}
            {Kati.Screens.Series.episodes(s)}
          </Column>
        </Column>
      </Scroll>
      {Kati.Screens.Series.chrome(assigns.menu?)}
    </Box>
    """
  end

  @doc """
  The `0.0..1.0` the season rail sweeps.

  `render/1` used to divide `watched / total` inline, which was safe only while
  the denominator was `length(sample.episodes)` and could never be zero. It can
  now: a season a provider has announced and not populated has nothing cached
  and no `episode_count`, and `5 / 0` is an `ArithmeticError` rather than an
  empty bar. Clamped at the top for the mirror case — a stale `episode_count`
  smaller than the number of ticks against it should not sweep past full.
  """
  @spec fraction(map()) :: float()
  def fraction(%{watched: watched, total: total}) when is_integer(total) and total > 0 do
    min(watched / total, 1.0)
  end

  def fraction(_series), do: 0.0

  @doc false
  def artwork(s) do
    ~MOB"""
    <Box fill_width={true} height={330} background={Palette.track_off()}>
      {Kati.Screens.Series.hero_art(s.seed)}
      <Box fill_width={true} fill_height={true} align="bottom">
        {Kati.UI.paper_fade(190)}
      </Box>
      <Box fill_width={true} fill_height={true} align="bottom">
        <Column fill_width={true} padding_left={21} padding_right={21} padding_bottom={6}>
          <Text
            text={s.title}
            text_size={30}
            font_weight="extrabold"
            letter_spacing={-0.035}
            line_height={1.05}
            text_color={:on_surface}
          />
          <Spacer size={9} />
          <Text
            text={s.meta}
            font_family="mono"
            text_size={11.5}
            text_color={Palette.meta()}
            max_lines={1}
          />
        </Column>
      </Box>
    </Box>
    """
  end

  # `Kati.Design.Images.hero/1` rather than `Kati.Library.Sample.art/1` — the
  # Sample function is a one-line delegation to it, and a real series' seed now
  # arrives on `Kati.Media.CachedTitle.poster_path` (see `seed_of/2`), so
  # routing it through the fixture module would be a lie about where the value
  # came from. Screens 03 and 08 made the same move for the same reason.
  @doc false
  def hero_art(seed) do
    case Kati.Design.Images.hero(seed) do
      nil ->
        ~MOB"<Spacer size={0} />"

      src ->
        ~MOB"""
        <Image src={src} fill_width={true} height={330} content_mode="fill" />
        """
    end
  end

  # The floating chrome. `arrow_back_ios_new` rather than a chevron, because
  # that is the glyph the drawing names.
  @doc false
  def chrome(menu?) do
    back = {self(), :back}
    fill = Palette.chrome_disc()
    lift = "0 6 16 -8 #991A1917"

    ~MOB"""
    <Box fill_width={true} fill_height={true} align="top">
      <Row fill_width={true} padding_left={21} padding_right={21} padding_top={60} align="center">
        <Row
          height={42}
          corner_radius={21}
          background={fill}
          shadow={lift}
          padding_left={12}
          padding_right={16}
          align="center"
          on_tap={back}
        >
          {Kati.UI.symbol("arrow_back_ios_new", size: 17)}
          <Spacer size={6} />
          <Text
            text="Library"
            text_size={13.5}
            font_weight="semibold"
            letter_spacing={-0.01}
            text_color={:on_surface}
          />
        </Row>
        <Spacer weight={1.0} />
        {Kati.Screens.Series.more_disc(fill, lift, menu?)}
      </Row>
    </Box>
    """
  end

  # The ⋯ half of the floating chrome, as Chelekom's headless Action Icon — the
  # component's own example of what it is for. Both of the props that made it
  # possible are non-theme values this screen invents: a 0xD1 translucent paper
  # fill and a one-layer lift that is not in `Kati.Theme` at all, because this
  # is chrome over artwork rather than a card on paper. `background` and
  # `shadow` take them verbatim.
  #
  # `shape: :circle` computes `42 / 2` = 21.0 against the Box's stated 21.
  #
  # The back pill beside it stays hand-rolled: it is a Row of glyph + label,
  # and an Action Icon is by definition icon-only — its children go into a Row
  # inside a SQUARE `size x size` box, so a 42-tall pill 100-odd wide has no
  # shape to be built out of.
  @doc false
  def more_disc(fill, lift, menu?) do
    trigger =
      MishkaActionIcon.action_icon(
        [
          size: 42,
          shape: :circle,
          variant: :filled,
          background: fill,
          shadow: lift,
          on_tap: :toggle_menu
        ],
        [Kati.UI.symbol("more_horiz", size: 21)]
      )

    # The drawing puts a ⋯ here and never draws what it opens; three screens
    # were stranded behind it. `on_tap` used to go straight to screen 35, which
    # made the button honest about one destination and silent about the other
    # two — 14 and 34 were reachable only from the gallery.
    #
    # Order is the drawing's own sense of scope: what this show IS, then how
    # its episodes are numbered, then what Kati does about it.
    Kati.UI.Menu.overflow(
      trigger,
      menu?,
      [
        Kati.UI.Menu.item("info", "Show details", :show_details),
        Kati.UI.Menu.item("checklist", "Episode order", :episode_order),
        Kati.UI.Menu.rule(),
        Kati.UI.Menu.item("tune", "Show settings", :open_settings),
        # #94's two. `Kati.Screens.RateEpisode`'s drawn entry is a LONG PRESS
        # on an episode row and `Kati.Screens.DropSheet`'s is a Drop action on
        # this board — neither gesture is drawn on 04, 66 or 74, so both were
        # reachable only from the developer gallery that #94 deletes. Menu rows
        # rather than dead code, on the precedent
        # `Kati.Screens.Library.menu/1` argues at length: the alternative was
        # leaving a finished screen unreachable forever.
        #
        # Placeholders for a drawing. When 04 is redrawn with the long press,
        # `RateEpisode` moves to it and leaves this menu.
        Kati.UI.Menu.item("star", "Rate an episode", :open_rate_episode),
        Kati.UI.Menu.item("do_not_disturb_on", "Drop this show", :open_drop_sheet)
      ],
      dismiss: :close_menu
    )
  end

  @doc false
  def season_card(s, pct) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card()}
        padding={17}
      >
        <Row fill_width={true} align="center">
          <Text
            text={s.season}
            text_size={15}
            font_weight="bold"
            letter_spacing={-0.02}
            text_color={:on_surface}
          />
          <Spacer weight={1.0} />
          <Text
            text={"#{s.watched} of #{s.total} watched"}
            font_family="mono"
            text_size={11.5}
            text_color={Palette.sub()}
            max_lines={1}
          />
        </Row>
        <Spacer size={12} />
        {Kati.Screens.Series.season_bar(pct)}
        {Kati.Screens.Series.next_air(s.next_air)}
      </Column>
      <Spacer size={14} />
    </Column>
    """
  end

  @doc """
  The `Next episode airs …` row and the 14pt of air above it, or neither.

  A list rather than a wrapper `Column`, because the sigil flattens an
  interpolated list into its parent: the drawn series gets the same two nodes in
  the same place it already had them, and a series with nothing announced leaves
  no node behind at all rather than a bullet beside an empty sentence. Same move
  as `Kati.Screens.Film.watched/1`, and for the same reason.

  `nil` arrives from `next_air_label/2` for a `:unknown` resolution, which is
  every series that has finished, every one whose next episode a provider has
  not scheduled, and every one whose cache has been evicted. `Kati.Media.Release`
  is what decides that, here as everywhere.
  """
  @spec next_air(String.t() | nil) :: [map()]
  def next_air(nil), do: []

  def next_air(label) do
    [
      ~MOB"<Spacer size={14} />",
      ~MOB"""
      <Row fill_width={true} align="center">
        <Box width={6} height={6} corner_radius={3} background={Palette.accent()} />
        <Spacer size={8} />
        <Text
          text="Next episode airs "
          text_size={12.5}
          text_color={Palette.ink_soft()}
          max_lines={1}
        />
        <Text
          text={label}
          text_size={12.5}
          font_weight="semibold"
          text_color={:on_surface}
          max_lines={1}
        />
      </Row>
      """
    ]
  end

  @doc """
  The season rail — 6pt, radius 3, ink on `#E7E3DC` — as Chelekom's headless
  Progress in its drawn mode.

  It was two weighted Boxes because `<Progress>` is Material's
  `LinearProgressIndicator`: it fills its parent, paints its own track in
  `ProgressIndicatorDefaults.linearTrackColor`, and carries the material3
  version of the day's thickness and caps. None of the drawing's three numbers
  were reachable through it. `render: :box` draws the same track-Box-with-a-
  fill-Box this file hand-rolled, with the arithmetic in one place.

  ## Why this one, and not just any bar

  The end this screen actually reaches is **100%**: the sample's S1 is 5 of 5,
  and every tap on a watched episode can put any season there. The hand-rolled
  shape emitted `<Spacer weight={1.0 - pct} />` unguarded, so a finished season
  handed Compose a literal `weight: 0.0` — `"invalid weight 0.0; must be
  greater than zero"`, which is a crash, not a warning. `0%` is equally
  ordinary (a season with nothing watched) and produced the same zero on the
  fill. The component omits the node at either end rather than weighting it
  zero, which draws the same nothing without the throw.

  `max: 1` because `pct` is already a fraction; `fraction/1` owns the
  `watched / total` division, including the zero denominator a real season can
  now have.
  """
  @spec season_bar(float()) :: map()
  def season_bar(pct) do
    MishkaProgress.progress(
      render: :box,
      value: pct,
      max: 1,
      height: 6,
      corner_radius: 3,
      color: Palette.ink(),
      track_color: Palette.track()
    )
  end

  @doc false
  def actions do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Box weight={1.0}>
          <Row
            fill_width={true}
            height={50}
            corner_radius={25}
            background={Palette.ink_fill()}
            align="center"
          >
            <Spacer weight={1.0} />
            {Kati.UI.symbol("check", size: 19, color: Palette.on_ink())}
            <Spacer size={8} />
            <Text
              text="Mark next watched"
              text_size={14}
              font_weight="bold"
              text_color={Palette.on_ink()}
              max_lines={1}
            />
            <Spacer weight={1.0} />
          </Row>
        </Box>
        <Spacer size={10} />
        {Kati.Screens.Series.action_disc("bookmark")}
        <Spacer size={10} />
        {Kati.Screens.Series.action_disc("star")}
      </Row>
    </Column>
    """
  end

  # Chelekom's headless Action Icon. `shadow` is the prop that made it usable:
  # these two discs sit beside a 50pt ink button on paper, and with a flat fill
  # they read as holes in the row rather than as buttons next to it. The lift is
  # the design's own `shadow_card_soft()`.
  #
  # `shape: :circle` computes `50 / 2` = 25.0 where the Box stated 25;
  # `floatProp` reads both as 25.0f. No handler is passed and none is wanted —
  # bookmark and rate are not built — and the component omits the key entirely
  # rather than sending a null, so no `clickable` is attached and the disc is as
  # inert as the Box was.
  @doc false
  def action_disc(icon) do
    MishkaActionIcon.action_icon(
      [
        size: 50,
        shape: :circle,
        variant: :filled,
        background: Palette.card(),
        shadow: Theme.shadow_card_soft()
      ],
      [Kati.UI.symbol(icon, size: 21)]
    )
  end

  @doc false
  def episodes_header(s) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={26} />
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        <Box width={13} height={2} corner_radius={1} background={Palette.accent()} />
        <Spacer size={9} />
        <Text
          text="EPISODES"
          font_family="mono"
          text_size={10.5}
          letter_spacing={0.16}
          text_color={Palette.eyebrow()}
        />
        <Spacer weight={1.0} />
        {s.seasons |> Enum.map(fn n -> Kati.Screens.Series.season_pill(n, n == s.current_season) end) |> Enum.intersperse(Kati.Screens.Series.pill_gap())}
      </Row>
      <Spacer size={12} />
    </Column>
    """
  end

  @doc false
  def pill_gap, do: ~MOB"<Spacer size={5} />"

  # NOT Chelekom's Chip, though this is a chip in every other respect — S1 / S2
  # / S3, exactly one checked, tapping replaces the selection. It has the size,
  # the radius, both fills and both inks now.
  #
  # What it lacks is one prop: **`font_family` on the label.** The component
  # builds its own `<Text text text_size text_color />` and merges only
  # `font_weight` and `max_lines` onto it, so a label can be sized, weighted and
  # clipped but not set in another face. These pills are DM Mono at 11.5, and a
  # season number in Plus Jakarta beside a mono episode list is a visible
  # change, not a rounding error.
  #
  # `trailing` is the escape hatch on screen 03 — its count goes in as a node,
  # which keeps its own family — but there is no such slot for the LABEL, which
  # is the only content here. Upstream ask: `font_family`, alongside the
  # `text_size` / `font_weight` / `max_lines` the label already takes. Kati sets
  # mono on every count, clock time, season number and meta line in the design,
  # so this is the prop that decides how many chips the component can draw.
  @doc false
  def season_pill(label, on?) do
    bg = if on?, do: Palette.ink_fill(), else: Palette.placeholder()
    fg = if on?, do: Palette.on_ink(), else: Palette.meta()
    tap = {self(), String.to_atom("season_" <> label)}

    ~MOB"""
    <Box width={30} height={28} corner_radius={10} background={bg} align="center" on_tap={tap}>
      <Text text={label} font_family="mono" text_size={11.5} text_color={fg} max_lines={1} />
    </Box>
    """
  end

  # The tap tag carries the row's POSITION in the list, not its number. An
  # episode number is a label rather than an identity — `Kati.Media.Watch` is
  # explicit that ticks follow the episode and not the number — and a real one
  # is nullable, so `String.to_integer/1` on a special TVmaze never numbered
  # would raise inside a tap handler. `episode/1` keeps its arity because two
  # other screens' moduledocs cite it by name.
  @doc false
  def episodes(s) do
    rows = s.episodes |> Enum.with_index() |> Enum.map(fn {ep, i} -> Map.put(ep, :index, i) end)

    ~MOB"""
    <Column fill_width={true}>
      {rows
       |> Enum.map(fn ep -> Kati.Screens.Series.episode(ep) end)
       |> Enum.intersperse(Kati.Screens.Series.episode_gap())}
    </Column>
    """
  end

  @doc false
  def episode(ep) do
    aired? = Map.get(ep, :aired, true)
    bg = if ep.watched, do: Palette.card_settled(), else: Palette.card()
    title_color = if ep.watched or not aired?, do: Palette.sub(), else: Palette.ink()
    # An episode that has not aired cannot be marked watched, so it gets no tap
    # at all rather than a tap that silently does nothing.
    tap = if aired?, do: {self(), String.to_atom("episode_#{ep.index}")}, else: nil

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        on_tap={tap}
        background={bg}
        corner_radius={17}
        padding_left={15}
        padding_right={15}
        padding_top={13}
        padding_bottom={13}
        align="center"
      >
        <Column width={22}>
          <Text
            text={"#{ep.n}"}
            font_family="mono"
            text_size={12}
            text_color={Palette.tertiary()}
            max_lines={1}
          />
        </Column>
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text
            text={ep.title}
            text_size={14}
            font_weight="semibold"
            letter_spacing={-0.01}
            text_color={title_color}
            max_lines={1}
          />
          <Spacer size={4} />
          <Text
            text={ep.sub}
            font_family="mono"
            text_size={10.5}
            text_color={Palette.tertiary()}
            max_lines={1}
          />
        </Column>
        <Spacer size={13} />
        {Kati.Screens.Series.check(ep.watched, aired?)}
      </Row>
    </Column>
    """
  end

  @doc false
  def episode_gap, do: ~MOB"<Spacer size={8} />"

  @doc false
  def check(true, _aired?) do
    ~MOB"""
    <Box width={27} height={27} corner_radius={14} background={Palette.ink_fill()} align="center">
      {Kati.UI.symbol("check", size: 16, color: Palette.on_ink())}
    </Box>
    """
  end

  def check(false, true) do
    ~MOB"""
    <Box
      width={27}
      height={27}
      corner_radius={14}
      border_width={1}
      border_color={Palette.bar_neutral()}
      align="center"
    >
      {Kati.UI.symbol("check", size: 16, color: Palette.bar_neutral())}
    </Box>
    """
  end

  # Not aired yet: no affordance at all, because there is nothing to mark.
  def check(false, false), do: ~MOB"<Spacer size={27} />"

  def handle_info({:tap, :back}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}

  def handle_info({:tap, :toggle_menu}, socket),
    do: {:noreply, Mob.Socket.assign(socket, :menu?, not socket.assigns.menu?)}

  def handle_info({:tap, :close_menu}, socket),
    do: {:noreply, Mob.Socket.assign(socket, :menu?, false)}

  def handle_info({:tap, :show_details}, socket),
    do: {:noreply, Kati.Screens.Series.pick(socket, Kati.Screens.SeriesMeta)}

  # The page knows both halves of what screen 34 is about: which series it is
  # drawing, and which pill on the season strip is lit. Bare, "Episode order"
  # opened whichever season the newest title's bookmark happened to name.
  def handle_info({:tap, :episode_order}, socket),
    do:
      {:noreply,
       Kati.Screens.Series.pick(
         socket,
         Kati.Screens.Season,
         Kati.Screens.Season.params_for(socket.assigns.series)
       )}

  def handle_info({:tap, :open_settings}, socket),
    do: {:noreply, Kati.Screens.Series.pick(socket, Kati.Screens.SeriesSettings)}

  # #94's two. See the menu above for why they are rows rather than the
  # gestures the design intends, and for what takes them out of it.
  def handle_info({:tap, :open_rate_episode}, socket),
    do: {:noreply, Kati.Screens.Series.pick(socket, Kati.Screens.RateEpisode)}

  def handle_info({:tap, :open_drop_sheet}, socket),
    do: {:noreply, Kati.Screens.Series.pick(socket, Kati.Screens.DropSheet)}

  def handle_info({:tap, tag}, socket) do
    case Atom.to_string(tag) do
      "season_" <> label ->
        {:noreply, Mob.Socket.assign(socket, :series, switch(socket.assigns.series, label))}

      "episode_" <> index ->
        {:noreply, Kati.Screens.Series.tick(socket, index)}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  # The season the pill names, out of the map both paths built — the drawing's
  # three from `Kati.Library.Sample.season_episodes/1`, a real title's from
  # `Kati.Media.CachedEpisode`. A label with no entry cannot happen from a drawn
  # pill and is answered by leaving the screen alone rather than by raising in a
  # tap handler.
  defp switch(s, label) do
    case Map.fetch(s.by_season, label) do
      {:ok, view} ->
        recount(%{
          s
          | current_season: label,
            season: view.season,
            total: view.total,
            episodes: view.episodes
        })

      :error ->
        s
    end
  end

  @doc """
  Tick or untick one episode, and write it.

  This moved a boolean on the socket and nothing else, which is the sentence
  #90 opens with. What it writes is a `Kati.Media.Watch` row, and what it
  deletes on a second tap is that same row — the resource says so itself:
  *"an episode is watched when a row for it exists, so unticking destroys and
  rewatching simply adds another"*. Untick therefore removes rather than
  writing a second row saying "not watched", which is the third criterion.

  The screen follows the store rather than leading it: the assign flips only
  after the write answers `:ok`, so a refused write leaves the tick where it
  was instead of showing a state the database does not hold. That is the same
  rule `Kati.Screens.MealsToday` keeps for a dose.

  An episode with no `source_id` and a page with no `tracked_id` cannot be
  written against anything, so they flip nothing and say so — a drawn series
  that nobody has tracked is exactly that case.
  """
  @spec tick(Mob.Socket.t(), String.t()) :: Mob.Socket.t()
  def tick(socket, index) do
    series = socket.assigns.series
    position = String.to_integer(index)
    episode = Enum.at(series.episodes, position)

    case Kati.Screens.Series.write_tick(Map.get(series, :tracked_id), episode) do
      :ok ->
        flip = fn ep -> %{ep | watched: not ep.watched} end

        socket
        |> Mob.Socket.assign(
          :series,
          recount(%{series | episodes: List.update_at(series.episodes, position, flip)})
        )
        |> Mob.Socket.assign(:save_error, nil)

      {:error, reason} ->
        Mob.Socket.assign(socket, :save_error, Kati.Write.message({:error, reason}))
    end
  end

  @doc false
  @spec write_tick(binary() | nil, map() | nil) :: :ok | {:error, term()}
  def write_tick(nil, _episode), do: {:error, :not_tracked}
  def write_tick(_tracked_id, nil), do: {:error, :no_episode}

  def write_tick(tracked_id, %{source_id: nil}) when is_binary(tracked_id),
    do: {:error, :no_episode_id}

  def write_tick(tracked_id, %{source_id: source_id, watched: watched?}) do
    if watched? do
      Kati.Media.Watch
      |> Ash.Query.for_read(:for_episode, %{
        tracked_title_id: tracked_id,
        episode_source_id: source_id
      })
      |> Ash.read!()
      |> Enum.each(&Ash.destroy!/1)

      :ok
    else
      Kati.Media.Watch
      |> Ash.Changeset.for_create(:create, %{
        tracked_title_id: tracked_id,
        episode_source_id: source_id,
        # `Kati.Time` and not `DateTime.utc_now/0`: a tick is stamped in the
        # device's zone, which is what `Kati.ScreenDateTest` enforces and what
        # makes "watched today" mean the user's today rather than UTC's.
        watched_at: Kati.Time.now(),
        watched_on: Kati.Time.today()
      })
      |> Ash.create()
      |> case do
        {:ok, _watch} -> :ok
        {:error, reason} -> {:error, reason}
      end
    end
  rescue
    error -> {:error, error}
  end

  @doc """
  Close the menu, then go.

  Both halves matter. The push is the point; closing first is what stops the
  panel being on screen again when the user comes back — this socket is what
  `Mob.Screen` saves onto the nav history, so a menu left open is a menu that
  reopens itself on every return from the screen it opened.

  `params` defaults to `%{}`, which is what `Mob.Socket.push_screen/3` sends
  when nobody passes any: one menu row can name its destination's subject
  without the other four gaining an argument they have nothing to fill.
  """
  def pick(socket, module, params \\ %{}) do
    socket
    |> Mob.Socket.assign(:menu?, false)
    |> Mob.Socket.push_screen(module, params)
  end
end
