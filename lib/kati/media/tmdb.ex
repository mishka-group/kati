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
  under `tmdb`; the bundled one is read from the environment at build time and
  is absent in a checkout, which is why `key/0` can answer `{:error,
  :no_api_key}` and every caller has to handle it.

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

  alias Kati.Media.CachedEpisode
  alias Kati.Media.CachedSeason
  alias Kati.Media.CachedTitle

  @host "https://api.themoviedb.org/3"
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
  @spec fetch(String.t(), :movie | :tv) :: {:ok, map()} | {:error, term()}
  def fetch(source_id, :movie) when is_binary(source_id) do
    with {:ok, key} <- key(),
         {:ok, body} <- get(key, "/movie/" <> source_id, []) do
      {:ok, title} = upsert_title(body, :movie, source_id)
      {:ok, %{title: title, seasons: 0, episodes: 0}}
    end
  end

  def fetch(source_id, :tv) when is_binary(source_id) do
    with {:ok, key} <- key(),
         {:ok, body} <- get(key, "/tv/" <> source_id, []) do
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

  defp upsert_title(body, kind, source_id) do
    attrs =
      %{
        source: :tmdb,
        source_id: source_id,
        kind: kind,
        title: body["title"] || body["name"],
        title_original: body["original_title"] || body["original_name"],
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
    _error -> :kati
  end

  defp own_key do
    case Kati.SecureStore.get("tmdb") do
      {:ok, token} -> token
      _other -> nil
    end
  end

  # The environment, and nothing committed. A checkout has no bundled key, so a
  # developer's own key is the only one there is until a release supplies one.
  defp bundled_key, do: System.get_env("TMDB_READ_TOKEN") || System.get_env("TMDB_TOKEN")

  # Every failure the user can be shown, named. A tuple rather than a message,
  # because the wording belongs to the screen and the reason belongs here.
  defp get(key, path, params) do
    Kati.Net.Tls.ensure!()

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
      {:ok, %Req.Response{status: 200, body: body}} when is_map(body) -> {:ok, body}
      {:ok, %Req.Response{status: 401}} -> {:error, :unauthorised}
      {:ok, %Req.Response{status: 429}} -> {:error, :rate_limited}
      {:ok, %Req.Response{status: 404}} -> {:error, :not_found}
      {:ok, %Req.Response{status: status}} -> {:error, {:http, status}}
      {:error, reason} -> {:error, {:network, reason}}
    end
  rescue
    error -> {:error, {:network, error}}
  end

  @doc """
  The sentence a screen shows for a failure. One per reason, and no `_` clause.

  A catch-all here would turn a reason nobody has worded yet into a plausible
  sentence about a different problem, which is worse than an ugly one — so a
  new reason is a compile-time gap rather than a silent mistranslation.
  """
  @spec message({:error, term()} | term()) :: String.t()
  def message({:error, reason}), do: message(reason)
  def message(:no_api_key), do: "No TMDB key yet. Add one in Settings → Data sources."
  def message(:unauthorised), do: "TMDB refused that key. Check it in Settings → Data sources."
  def message(:rate_limited), do: "TMDB is rate-limiting Kati. Try again in a minute."
  def message(:not_found), do: "TMDB has nothing under that id."
  def message({:http, status}), do: "TMDB answered #{status}. Nothing was saved."
  def message({:network, _reason}), do: "Could not reach TMDB. Hand-typed titles still work."

  defp year_of(nil), do: nil
  defp year_of(""), do: nil
  defp year_of(date) when is_binary(date), do: String.slice(date, 0, 4)

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
