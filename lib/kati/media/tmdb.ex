defmodule Kati.Media.Tmdb do
  @moduledoc """
  The one provider: TMDB, over one search call and one detail call.

  #89's scope, and no more than it. Two entry points — `search/1` finds titles,
  `fetch/2` fills the cache for one of them — and between them they write
  `Kati.Media.CachedTitle`, `Kati.Media.CachedSeason` and
  `Kati.Media.CachedEpisode` and nothing else. No second provider, no writes to
  anything the user decided: a `Kati.Media.TrackedTitle` row is the user's and
  this module never touches one.

  ## Why series and not films

  Films work on hand-typed rows: a title and a year is the whole of one. A
  series cannot be, because nothing can be ticked before episodes exist and an
  episode list cannot be typed by hand at any sane cost. That is the sentence
  #89 opens with, and it is why this module's detail call walks seasons.

  ## The key, and which one

  `Kati.Sources.tmdb_key/0` answers `:kati` or `:own`, and *which* is not a
  secret — only the key is. A user-supplied key lives in `Kati.SecureStore`
  under `tmdb`; the bundled one is a developer's token read at build time, is
  absent in a checkout and in every store release (`compiled_key?/0`), which
  is why `key/0` can answer `{:error, :no_api_key}` and every caller has to
  handle it.

  The key reaches exactly one place: the `authorization` header of a request
  to TMDB. Nothing here logs, and no failure this module answers can carry it
  — a transport error that quotes the request is replaced by `:redacted`
  before it leaves `get/3` (`Kati.Net.Redact`).

  A missing key is **not** an error state the user caused, so it is reported as
  itself rather than as a failed request: screen 80 is where a key is entered,
  and that is what the message points at.

  ## Offline is not a failure

  Every function here answers `{:error, reason}` rather than raising, and no
  caller may treat that as fatal. `:manual` rows are the app working with no
  network at all, which is the third of #89's criteria and the reason the
  fallbacks in `Kati.Screens.AddTitle` stay where they are.

  ## TLS

  `Kati.Net.Tls.ensure!/0` on every request, per its own moduledoc: it is the
  second `Req.` caller in the app, and `Kati.BootPathTest` fails on a caller
  that skips it. The failure mode it prevents is a TLS error three screens from
  its cause.
  """

  use Gettext, backend: Kati.Gettext

  alias Kati.Media.CachedEpisode
  alias Kati.Media.CachedSeason
  alias Kati.Media.CachedTitle

  @host "https://api.themoviedb.org/3"
  @dns_host "api.themoviedb.org"
  @timeout 15_000

  # Test seam, and the only one. `:tmdb_req_options` is merged into every
  # request so a test can hand Req a plug instead of a socket; it is empty in
  # dev and on device, where the merge costs one `Keyword.merge/2` over an
  # empty list. The alternative — a behaviour and a stub module — would put an
  # indirection in the shipping path to serve the tests, which is the wrong way
  # round for a module this small.

  @typedoc "What a search row carries: enough to draw it, and enough to fetch it."
  @type result :: %{
          title: String.t(),
          kind: :movie | :tv,
          source_id: String.t(),
          year: String.t() | nil,
          overview: String.t() | nil,
          poster_path: String.t() | nil
        }

  @doc """
  Search TMDB for a title.

  One call to `/search/multi`, narrowed to the two kinds Kati tracks. Answers
  `{:ok, [result]}` or `{:error, reason}` — never a partial list and never a
  raise.

  The empty query is answered here rather than at the endpoint: TMDB returns a
  422 for it, and a user who has typed nothing has not made a mistake.
  """
  @spec search(String.t()) :: {:ok, [result()]} | {:error, term()}
  def search(query) when is_binary(query) do
    case String.trim(query) do
      "" -> {:ok, []}
      trimmed -> do_search(trimmed)
    end
  end

  @doc """
  What TMDB suggests for one title: `/movie/{id}/recommendations`.

  Screen 11 was `Kati.Discover.Sample.feed()` end to end — *Tuned to 128
  titles* on a shelf of six, *Because you watched The Long Hollow* for a
  reader who never had, and three invented films with invented match
  percentages. Its first band is the one that can be real, and this is the
  call that makes it: the app already knows what somebody watched, and TMDB
  already answers what is like it.

  Shaped exactly as `search/1` shapes a result, so a suggestion can be added
  by the same `Kati.Screens.AddTitle.track/2` that adds a search hit — a row
  that could be shown and not kept would be a worse page than the fixture.

  `{:error, :no_api_key}` and every transport failure come back as they do
  everywhere else in this module, and screen 11 falls back to its drawing:
  a recommendation nobody could fetch is not a recommendation.
  """
  @spec recommendations(String.t(), :movie | :tv) :: {:ok, [map()]} | {:error, term()}
  def recommendations(source_id, kind) when is_binary(source_id) and kind in [:movie, :tv] do
    path = if kind == :movie, do: "/movie/", else: "/tv/"

    with {:ok, key} <- key(),
         {:ok, body} <- get(key, path <> source_id <> "/recommendations", page: "1") do
      {:ok, body |> Map.get("results", []) |> Enum.flat_map(&shape_recommendation(&1, kind))}
    end
  end

  @doc """
  Browse rather than be recommended: `/discover/movie` and `/discover/tv`.

  The endpoint board 169's sheet is built on. `/movie/{id}/recommendations`
  answers *what is like this one*, which needs a title to be like; `/discover`
  answers *what is there*, narrowed by parameters, and needs nothing on the
  shelf at all. So a reader with an empty library can still be shown something
  real, and a reader with a full one can ask a question their own history
  cannot answer.

  `params` is passed to TMDB untouched — `Kati.Discover.Filters.params/3` is
  the one place that builds it, so the sheet's vocabulary and TMDB's are
  translated in a single function rather than at each call.

  Answers the shape `recommendations/2` answers, plus the count TMDB itself
  reports:

      {:ok, %{picks: [%{title: ..., kind: :movie, source_id: ..., ...}], total: 4213}}

  `total` is **TMDB's `total_results`**, not a count of `picks` — one page is
  20 rows out of it. That distinction is the reason the sheet draws no count
  badge on a chip: a per-chip figure would need one request per chip, and a
  badge that is the page size wearing the corpus's name is exactly the kind of
  plausible number board 169's own note tells the build not to infer.
  """
  @spec discover(:movie | :tv, keyword()) ::
          {:ok, %{picks: [map()], total: non_neg_integer()}} | {:error, term()}
  def discover(kind, params) when kind in [:movie, :tv] and is_list(params) do
    with {:ok, key} <- key(),
         {:ok, body} <- get(key, "/discover/" <> Atom.to_string(kind), params) do
      {:ok,
       %{
         picks: body |> Map.get("results", []) |> Enum.flat_map(&shape_recommendation(&1, kind)),
         total: body |> Map.get("total_results", 0) |> to_count()
       }}
    end
  end

  defp to_count(n) when is_integer(n) and n >= 0, do: n
  defp to_count(_other), do: 0

  @doc """
  Where one title can be watched, on its own.

  `fetch/2` gets this for free by appending to the detail request, and a title
  the reader does not have has never been fetched — which is every row on
  screen 11's rail. So this is the one-title endpoint, asked only when
  somebody has turned *Hide titles I can't watch* on: three lookups for a
  reader who asked for them, none for a reader who did not.

  Answers the same shape `providers/1` does, so both sides of the app read one
  format.
  """
  @spec watch_providers(String.t(), :movie | :tv) :: {:ok, map() | nil} | {:error, term()}
  def watch_providers(source_id, kind) when is_binary(source_id) and kind in [:movie, :tv] do
    path = if kind == :movie, do: "/movie/", else: "/tv/"

    with {:ok, key} <- key(),
         {:ok, body} <- get(key, path <> source_id <> "/watch/providers", []) do
      {:ok, Kati.Media.Tmdb.providers(%{"watch/providers" => body})}
    end
  end

  # `/recommendations` answers rows with no `media_type`, because the endpoint
  # is already about one kind — so `shape_result/1`'s guard cannot match them
  # and the kind is carried in rather than read off.
  defp shape_recommendation(%{"id" => id} = row, kind) do
    title = row["title"] || row["name"]

    if is_binary(title) and title != "" do
      [
        %{
          title: title,
          kind: kind,
          source_id: to_string(id),
          year: year_of(row["release_date"] || row["first_air_date"]),
          overview: blank_to_nil(row["overview"]),
          poster_path: row["poster_path"]
        }
      ]
    else
      []
    end
  end

  defp shape_recommendation(_other, _kind), do: []

  defp do_search(query) do
    with {:ok, key} <- key(),
         {:ok, body} <-
           get(key, "/search/multi", query: query, include_adult: "false", page: "1") do
      {:ok, body |> Map.get("results", []) |> Enum.flat_map(&shape_result/1)}
    end
  end

  # `multi` returns people as well as titles, and a person has no `media_type`
  # Kati tracks. Dropped here rather than filtered by the caller, so a search
  # row is always something that can be added.
  defp shape_result(%{"media_type" => type} = row) when type in ["movie", "tv"] do
    kind = if type == "movie", do: :movie, else: :tv
    title = row["title"] || row["name"]

    if is_binary(title) and title != "" do
      [
        %{
          title: title,
          kind: kind,
          source_id: to_string(row["id"]),
          year: year_of(row["release_date"] || row["first_air_date"]),
          overview: blank_to_nil(row["overview"]),
          poster_path: row["poster_path"]
        }
      ]
    else
      []
    end
  end

  defp shape_result(_other), do: []

  @doc """
  Fill the cache for one title, and answer what was written.

  A film is one row. A series is one row plus a season row and an episode row
  for every episode TMDB lists, which is the whole point: `Kati.Media.Watch`
  can only tick an episode that exists.

  Season 0 is TMDB's specials bucket and is fetched like any other, with
  `special: true` on its episodes — `Kati.Media.CachedEpisode` has the column
  because a special has no place in an ordinary numbering and still airs.
  """
  # One extra query parameter, no extra request: TMDB folds the watch-provider
  # block into the detail response. See `providers/1`.
  @with_providers [append_to_response: "watch/providers"]

  @spec fetch(String.t(), :movie | :tv) :: {:ok, map()} | {:error, term()}
  def fetch(source_id, :movie) when is_binary(source_id) do
    with {:ok, key} <- key(),
         {:ok, body} <- get(key, "/movie/" <> source_id, @with_providers) do
      {:ok, title} = upsert_title(body, :movie, source_id)
      {:ok, %{title: title, seasons: 0, episodes: 0}}
    end
  end

  def fetch(source_id, :tv) when is_binary(source_id) do
    with {:ok, key} <- key(),
         {:ok, body} <- get(key, "/tv/" <> source_id, @with_providers) do
      {:ok, title} = upsert_title(body, :tv, source_id)
      {seasons, episodes} = fetch_seasons(key, source_id, body)
      {:ok, %{title: title, seasons: seasons, episodes: episodes}}
    end
  end

  # One call per season. TMDB has no endpoint that returns every episode of a
  # show at once, so this is the fixed number of reads the shape allows rather
  # than an N+1 that could be avoided.
  #
  # A season that fails is skipped, not fatal: eight seasons cached and one
  # missing is a better answer than nothing cached, and the missing one is
  # re-fetched by the next `:stale` pass.
  defp fetch_seasons(key, title_source_id, body) do
    body
    |> Map.get("seasons", [])
    |> Enum.reduce({0, 0}, fn season, {seasons, episodes} ->
      number = season["season_number"]

      case get(key, "/tv/#{title_source_id}/season/#{number}", []) do
        {:ok, detail} ->
          upsert_season(season, title_source_id)
          written = Enum.count(detail["episodes"] || [], &upsert_episode(&1, title_source_id))
          {seasons + 1, episodes + written}

        {:error, _reason} ->
          {seasons, episodes}
      end
    end)
  end

  @doc """
  Where a title can be watched, out of TMDB's `watch/providers` block.

  `append_to_response=watch/providers` rides along on the detail request, so
  this costs no extra call — the fetch that caches a title brings its
  availability home with it.

  TMDB's shape is `{"results": {"GB": {"link": …, "flatrate": [{provider_name:
  "Netflix", …}], "rent": […], "buy": […]}}}`, and what comes out here is the
  same thing with the names lifted out and the link dropped:

      %{"GB" => %{"flatrate" => ["Netflix"], "rent" => ["Apple TV"]}}

  NAMES, because a JustWatch provider id means nothing to a reader and nothing
  to `Kati.Services.Service`, which is keyed on the name a person typed. An
  empty monetisation list is dropped rather than stored as `[]`: three empty
  keys per region is a lot of nothing to carry, and `Kati.Media.Availability`
  reads a missing key and an empty one the same way.

  `nil` when TMDB sent no block at all, which `put_if/3` then skips — a fetch
  that could not answer must not overwrite an answer an earlier one gave.

      iex> Kati.Media.Tmdb.providers(%{})
      nil

      iex> Kati.Media.Tmdb.providers(%{
      ...>   "watch/providers" => %{
      ...>     "results" => %{
      ...>       "GB" => %{
      ...>         "link" => "https://example",
      ...>         "flatrate" => [%{"provider_name" => "Netflix"}],
      ...>         "rent" => []
      ...>       }
      ...>     }
      ...>   }
      ...> })
      %{"GB" => %{"flatrate" => ["Netflix"]}}
  """
  @spec providers(map()) :: map() | nil
  def providers(body) do
    case get_in(body, ["watch/providers", "results"]) do
      results when is_map(results) and results != %{} ->
        Map.new(results, fn {region, offers} -> {region, monetisations(offers)} end)

      _absent ->
        nil
    end
  end

  defp monetisations(offers) when is_map(offers) do
    for kind <- ["flatrate", "free", "ads", "rent", "buy"],
        names = provider_names(Map.get(offers, kind)),
        names != [],
        into: %{},
        do: {kind, names}
  end

  defp monetisations(_offers), do: %{}

  defp provider_names(list) when is_list(list) do
    list
    |> Enum.map(&Map.get(&1, "provider_name"))
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
  end

  defp provider_names(_absent), do: []

  # Only stamped when there was a block to read. A fetch that answered nothing
  # must not claim the question was asked and settled.
  defp providers_stamp(body) do
    if is_map(get_in(body, ["watch/providers", "results"])),
      do: DateTime.utc_now() |> DateTime.truncate(:second)
  end

  defp upsert_title(body, kind, source_id) do
    attrs =
      %{
        source: :tmdb,
        source_id: source_id,
        kind: kind,
        title: body["title"] || body["name"],
        title_original: body["original_title"] || body["original_name"],
        # Board 152's third rule is *Animation + Japanese origin* and the genre
        # half was already kept; this is the half that was not (#104).
        original_language: blank_to_nil(body["original_language"]),
        overview: blank_to_nil(body["overview"]),
        poster_path: body["poster_path"],
        backdrop_path: body["backdrop_path"],
        runtime_minutes: positive(body["runtime"]),
        genres: genres(body["genres"]),
        tmdb_id: source_id,
        imdb_id: blank_to_nil(body["imdb_id"]),
        fetched_at: DateTime.utc_now(),
        last_checked_at: DateTime.utc_now()
      }
      |> put_if(:episode_count, positive(body["number_of_episodes"]))
      # `release_date` for a film, `first_air_date` for a series — the same
      # pair `shape_result/1` already reads for a search row's year, now kept
      # rather than shown once and thrown away. Screen 14's meta line and
      # screen 145's decade chips both wanted it and there was no column.
      |> put_if(:first_release_year, year_number(body["release_date"] || body["first_air_date"]))
      |> put_if(:providers, Kati.Media.Tmdb.providers(body))
      |> put_if(:providers_checked_at, providers_stamp(body))

    upsert(CachedTitle, [source: :tmdb, source_id: source_id], attrs)
  end

  defp upsert_season(season, title_source_id) do
    number = season["season_number"]

    upsert(
      CachedSeason,
      [source: :tmdb, title_source_id: title_source_id, season_number: number],
      %{
        source: :tmdb,
        title_source_id: title_source_id,
        season_number: number,
        source_id: to_string(season["id"]),
        name: season["name"],
        overview: blank_to_nil(season["overview"]),
        poster_path: season["poster_path"],
        fetched_at: DateTime.utc_now()
      }
      |> put_if(:episode_count, positive(season["episode_count"]))
      |> put_air(season["air_date"])
    )
  end

  # `source_id` is the identity and the only one — a special can have no season
  # and no number at all, which `Kati.Media.CachedEpisode`'s own moduledoc says
  # in as many words. An episode TMDB gives no id for is not written rather
  # than written under a made-up one.
  defp upsert_episode(episode, title_source_id) do
    case episode["id"] do
      nil ->
        false

      id ->
        number = episode["season_number"]

        upsert(
          CachedEpisode,
          [source: :tmdb, source_id: to_string(id)],
          %{
            source: :tmdb,
            source_id: to_string(id),
            title_source_id: title_source_id,
            season_number: number,
            episode_number: episode["episode_number"],
            special: number == 0,
            title: blank_to_nil(episode["name"]),
            overview: blank_to_nil(episode["overview"]),
            still_path: episode["still_path"],
            runtime_minutes: positive(episode["runtime"]),
            fetched_at: DateTime.utc_now()
          }
          |> put_air(episode["air_date"])
        )

        true
    end
  end

  # Upsert by hand rather than by an Ash identity: the three resources are
  # cache tables that a `:stale` pass re-fetches, so writing the same row twice
  # must update rather than fail, and the read that decides is the same one
  # `by_reference` makes.
  defp upsert(resource, filter, attrs) do
    existing =
      resource
      |> Ash.Query.do_filter(filter)
      |> Ash.read!()
      |> List.first()

    case existing do
      nil -> resource |> Ash.Changeset.for_create(:create, attrs) |> Ash.create()
      row -> row |> Ash.Changeset.for_update(:update, attrs) |> Ash.update()
    end
  rescue
    error -> {:error, error}
  end

  @doc """
  The key in force, or why there is none.

  `:own` reads `Kati.SecureStore`; `:kati` reads the bundled key, which is
  absent in a checkout. Either way a missing key is `{:error, :no_api_key}` and
  never a crash — screen 80 is where one is entered.
  """
  @spec key() :: {:ok, String.t()} | {:error, :no_api_key}
  def key do
    token =
      case which_key() do
        :own -> own_key()
        :kati -> bundled_key()
      end

    if is_binary(token) and token != "", do: {:ok, token}, else: {:error, :no_api_key}
  end

  # `Kati.Sources.tmdb_key/0` reads `Mob.State`, which is DETS, and DETS raises
  # rather than answering when its table is not open — a bare `mix run` and a
  # test that has not started the app both hit it. This module's contract is
  # that nothing here raises, so the unopened table is read as "no choice
  # recorded", which is what `:kati` already means.
  defp which_key do
    Kati.Sources.tmdb_key()
  rescue
    _error -> :own
  end

  @doc """
  Whether this build carries Kati's own key.

  A development convenience — `~/.config/kati/tmdb.env` or `TMDB_READ_TOKEN` at
  build time — and never present in a public build or under test. Screen 80
  offers *Use Kati's key* only when this is true, because offering a key that
  is not there would switch search off with one tap.
  """
  @spec bundled?() :: boolean()
  # `to_string/1` because the key's type differs by build: a string in dev,
  # `nil` under test. Any branch on `nil` reads as dead code to the type checker
  # in whichever build it is compiled for, and `nil` becomes `""` here either way.
  def bundled?, do: bundled_key() |> to_string() |> byte_size() > 0

  @doc """
  Whether a search could be made right now: a key is in force and present.

  What Home and screen 06 ask before sending a reader to search, so a missing
  key is a door to screen 80 rather than a search that returns nothing.
  """
  @spec usable?() :: boolean()
  def usable?, do: match?({:ok, _key}, key())

  defp own_key do
    case Kati.SecureStore.get("tmdb") do
      {:ok, token} -> token
      _other -> nil
    end
  end

  # The environment, and nothing committed. A checkout has no bundled key, so a
  # developer's own key is the only one there is.
  #
  # **This is where a development device build gets one.** `System.get_env/1` is read on the
  # machine the code is RUNNING on, and the machine a Kati release runs on is a
  # phone, which has no shell and no environment: every device build answered
  # `{:error, :no_api_key}` and every search for a film came back empty. Found
  # by typing `matrix` into screen 06 on a Pixel 9a and getting `RESULTS 0`.
  #
  # So the value is also captured at COMPILE time, into `@bundled_key`, and
  # travels in the BEAM that `mix kati.e2e.stage` pushes. The runtime read
  # still wins, so a developer's shell still overrides a stale build.
  #
  # **Never in `:test`**, and that is the whole reason for the `Mix.env/0`
  # guard rather than a bare capture: `Kati.MediaTmdbTest`'s *no key is not a
  # failed request* deletes both variables and asserts the refusal, and a key
  # baked into the test binary would answer past it and quietly delete that
  # coverage. A test binary must not carry anybody's credentials either.
  #
  # The token reaches the build from `~/.config/kati/tmdb.env`, which is
  # outside the repository and mode 600. Nothing here is committed: the value
  # lives in `_build`, which is ignored, and in the pushed artefact.
  # The documented location, read at compile time as well as the environment —
  # because depending on the environment alone meant depending on whether the
  # shell that happened to run `mix kati.e2e.stage` had sourced the file.
  # `Kati.Media.TmdbKeyFile` carries the rest of that argument, and the
  # `@external_resource` is what makes a changed token recompile this.
  #
  # **Never in a store release either** — `Kati.Media.TmdbKeyFile.bundle?/2`.
  # A release compiles under `:dev` like every Mob build, so the `Mix.env/0`
  # guard alone would have put the developer's token in the AAB. The release
  # flag is what tells the two apart, and a release build reads no environment
  # at run time as well: the key it answers is the reader's or none.
  @env_file Kati.Media.TmdbKeyFile.path()
  @external_resource @env_file

  @release_build Kati.Media.TmdbKeyFile.release_build?()

  @bundled_key if Kati.Media.TmdbKeyFile.bundle?(Mix.env(), @release_build),
                 do:
                   System.get_env("TMDB_READ_TOKEN") || System.get_env("TMDB_TOKEN") ||
                     Kati.Media.TmdbKeyFile.read(@env_file),
                 else: nil

  @compiled_key is_binary(@bundled_key)

  @doc """
  Whether a developer's token was compiled into this build.

  Answers a boolean and never the token. The `mob.release` alias in `mix.exs`
  refuses to package a build where this is `true`.
  """
  @spec compiled_key?() :: boolean()
  def compiled_key?, do: @compiled_key

  @doc false
  # Mix's recompile hook: a release compile after a dev one — same `_build/dev`,
  # nothing in the source changed — must still recompile this module, or the
  # token captured by the dev compile would travel in the release.
  def __mix_recompile__?, do: Kati.Media.TmdbKeyFile.release_build?() != @release_build

  if @release_build do
    defp bundled_key, do: nil
  else
    defp bundled_key do
      System.get_env("TMDB_READ_TOKEN") || System.get_env("TMDB_TOKEN") || @bundled_key
    end
  end

  # Every failure the user can be shown, named. A tuple rather than a message,
  # because the wording belongs to the screen and the reason belongs here.
  defp get(key, path, params) do
    Kati.Net.Tls.ensure!()

    # Android's resolver lives behind a Java API the BEAM cannot reach, so the
    # pure-BEAM resolver `Kati.Net.Tls.ensure!/0` configures gets nowhere on a
    # phone: `:inet_res.gethostbyname/1` answers `:nxdomain` for a host the
    # same device pings without trouble, and every request here dies as a
    # transport error. `Mob.DNS.resolve/1` asks the platform through a NIF and
    # seeds `:inet_db`, which is where Req/Finch/Mint look.
    #
    # Idempotent, so it costs a cache read after the first call. On the host
    # the NIF is absent and it answers `{:error, :nif_not_loaded}` — ignored,
    # because ordinary DNS already works there, which is exactly why this was
    # invisible until the emulator.
    _resolved = Mob.DNS.resolve(@dns_host)

    [
      url: @host <> path,
      params: params,
      headers: [{"authorization", "Bearer " <> key}, {"accept", "application/json"}],
      receive_timeout: @timeout,
      retry: false
    ]
    |> Keyword.merge(Application.get_env(:kati, :tmdb_req_options, []))
    |> Req.new()
    |> Req.request()
    |> case do
      {:ok, %Req.Response{status: 200, body: body}} when is_map(body) ->
        {:ok, body}

      {:ok, %Req.Response{status: 401}} ->
        {:error, :unauthorised}

      {:ok, %Req.Response{status: 429}} ->
        {:error, :rate_limited}

      {:ok, %Req.Response{status: 404}} ->
        {:error, :not_found}

      {:ok, %Req.Response{status: status}} ->
        {:error, {:http, status}}

      {:error, reason} ->
        {:error, Kati.Media.Tmdb.transport_failure(Kati.Net.Redact.reason(reason, [key]))}
    end
  rescue
    error -> {:error, Kati.Media.Tmdb.transport_failure(Kati.Net.Redact.reason(error, [key]))}
  end

  @doc """
  What a transport failure actually was: the network refusing TMDB, or TMDB
  simply not answering.

  A network that filters TMDB does it in DNS: its resolver answers
  `api.themoviedb.org` with a private sinkhole address instead of TMDB's, and
  the TLS handshake to that address is closed. Found on the owner's home Wi-Fi,
  25 Sep — the router at `192.168.70.1` answers `10.10.34.36` where `8.8.8.8`
  answers TMDB's real `198.20.2.61`. The phone on that Wi-Fi reported *"Could
  not reach TMDB"*, which reads like a flaky connection or a missing key, and
  was neither: the same build on the same key returned 17 results the moment
  the emulator was given a resolver that does not filter.

  So on a failure, and only then, the name is looked up once more. A private,
  loopback or unspecified answer for a public API host is a network that has
  decided TMDB is not reachable — `:blocked` — and the reader is told that, in
  words they can act on. Anything else stays `{:network, reason}`.

  Only on the failure path, so a working search pays nothing for it.
  """
  @spec transport_failure(term()) :: :blocked | {:network, term()}
  def transport_failure(reason) do
    case :inet.gethostbyname(String.to_charlist(@dns_host)) do
      {:ok, {:hostent, _name, _aliases, :inet, 4, [address | _rest]}} ->
        if Kati.Media.Tmdb.sinkhole?(address), do: :blocked, else: {:network, reason}

      _unresolved ->
        {:network, reason}
    end
  rescue
    _error -> {:network, reason}
  end

  @doc """
  Whether an IPv4 address is one no public API is ever served from.

      iex> Kati.Media.Tmdb.sinkhole?({10, 10, 34, 36})
      true

      iex> Kati.Media.Tmdb.sinkhole?({198, 20, 2, 61})
      false

      iex> Kati.Media.Tmdb.sinkhole?({192, 168, 70, 1})
      true
  """
  @spec sinkhole?(:inet.ip4_address()) :: boolean()
  def sinkhole?({10, _, _, _}), do: true
  def sinkhole?({172, b, _, _}) when b in 16..31, do: true
  def sinkhole?({192, 168, _, _}), do: true
  def sinkhole?({127, _, _, _}), do: true
  def sinkhole?({0, _, _, _}), do: true
  def sinkhole?({169, 254, _, _}), do: true
  def sinkhole?(_public), do: false

  @doc """
  The sentence a screen shows for a failure. One per reason, and no `_` clause.

  A catch-all here would turn a reason nobody has worded yet into a plausible
  sentence about a different problem, which is worse than an ugly one — so a
  new reason is a compile-time gap rather than a silent mistranslation.
  """
  @spec message({:error, term()} | term()) :: String.t()
  def message({:error, reason}), do: message(reason)
  def message(:no_api_key), do: gettext("No TMDB key yet. Add one in Settings → Data sources.")

  def message(:unauthorised),
    do: gettext("TMDB refused that key. Check it in Settings → Data sources.")

  def message(:rate_limited),
    do: gettext("TMDB is rate-limiting Kati. Try again in a minute.")

  def message(:not_found), do: gettext("TMDB has nothing under that id.")

  def message({:http, status}),
    do: gettext("TMDB answered %{status}. Nothing was saved.", status: status)

  def message({:network, _reason}),
    do: gettext("Could not reach TMDB. Hand-typed titles still work.")

  def message(:blocked),
    do:
      gettext(
        "This network is blocking TMDB. Try another Wi-Fi or mobile data. Hand-typed titles still work."
      )

  defp year_of(nil), do: nil
  defp year_of(""), do: nil
  defp year_of(date) when is_binary(date), do: String.slice(date, 0, 4)

  # The same four characters as an integer, for the column. `nil` for anything
  # that is not a plausible year: TMDB answers `""` for a title with no date
  # and has been known to answer a partial one.
  defp year_number(date) do
    case date |> year_of() |> to_string() |> Integer.parse() do
      {year, ""} when year >= 1888 -> year
      _unparsed -> nil
    end
  end

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(text) when is_binary(text), do: text

  defp positive(n) when is_integer(n) and n > 0, do: n
  defp positive(_other), do: nil

  defp genres(list) when is_list(list) do
    list |> Enum.map(& &1["name"]) |> Enum.reject(&is_nil/1) |> Enum.join(", ") |> blank_to_nil()
  end

  defp genres(_other), do: nil

  defp put_if(map, _key, nil), do: map
  defp put_if(map, key, value), do: Map.put(map, key, value)

  # TMDB gives a date and no time, so the confidence is `:day` and never
  # `:exact`. Saying `:exact` of a midnight this provider invented is the kind
  # of small lie the whole cache exists to avoid.
  defp put_air(map, date) when is_binary(date) and date != "" do
    case Date.from_iso8601(date) do
      {:ok, d} ->
        map
        |> Map.put(:air_at, DateTime.new!(d, ~T[00:00:00.000000], "Etc/UTC"))
        |> Map.put(:date_confidence, :day)

      _error ->
        map
    end
  end

  defp put_air(map, _date), do: map
end
