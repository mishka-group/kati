defmodule Kati.Media.Tvmaze do
  @moduledoc """
  TVmaze: series, with real seasons and episodes, and no key at all.

  Two endpoints — `GET /search/shows?q=…` for `search/1`, and `GET
  /shows/:id?embed[]=seasons&embed[]=episodes` for `fetch/2` — and between
  them they write `Kati.Media.CachedTitle`, `Kati.Media.CachedSeason` and
  `Kati.Media.CachedEpisode` under `source: :tvmaze` and nothing else. Like
  `Kati.Media.Tmdb`, it never touches a `Kati.Media.TrackedTitle`.

  ## Series only

  TVmaze has no films, so every row here is `:tv`. The one detail call brings
  every season and every episode with it, each episode with TVmaze's own id —
  which is `Kati.Media.CachedEpisode`'s identity, so a tick survives a
  re-fetch the way a TMDB one does.

  ## What an episode carries

  Its title, its runtime, its summary with TVmaze's HTML stripped
  (`Kati.Media.Provider.plain/1`), and when it aired: `airstamp` is an exact
  instant and is kept as `:exact`; a bare `airdate` is `:day`, the confidence
  TMDB's dates get. An episode with no number is a special.

  ## Anime, by the rule that already exists

  `original_language` is TVmaze's language name as a code (`Japanese` is
  `ja`), and a show whose `type` is *Animation* has *Animation* among its
  `genres` — so a Japanese animated series found here is
  `Kati.Media.Anime.provider_says?/1`'s rule 3 like any other.

  ## Failures, and the test seam

  `Kati.Media.Provider.request/3` is the transport and
  `Kati.Media.Provider.message/2` words its reasons; nothing here raises.
  `:tvmaze_req_options` is merged into every request, so a host test hands
  Req an adapter instead of a socket.
  """

  alias Kati.Media.CachedEpisode
  alias Kati.Media.CachedSeason
  alias Kati.Media.CachedTitle
  alias Kati.Media.Provider

  @host "https://api.tvmaze.com"
  @dns_host "api.tvmaze.com"

  @languages %{
    "Arabic" => "ar",
    "Chinese" => "zh",
    "Danish" => "da",
    "Dutch" => "nl",
    "English" => "en",
    "French" => "fr",
    "German" => "de",
    "Hindi" => "hi",
    "Italian" => "it",
    "Japanese" => "ja",
    "Korean" => "ko",
    "Norwegian" => "no",
    "Persian" => "fa",
    "Polish" => "pl",
    "Portuguese" => "pt",
    "Russian" => "ru",
    "Spanish" => "es",
    "Swedish" => "sv",
    "Thai" => "th",
    "Turkish" => "tr"
  }

  @doc """
  Search TVmaze for a series.

  Answers `{:ok, [result]}` in `Kati.Media.Tmdb.result/0`'s shape with
  `source: :tvmaze` on each row, or `{:error, reason}`. The empty query is
  answered here and asks nothing.
  """
  @spec search(String.t()) :: {:ok, [map()]} | {:error, term()}
  def search(query) when is_binary(query) do
    case String.trim(query) do
      "" -> {:ok, []}
      trimmed -> do_search(trimmed)
    end
  end

  defp do_search(query) do
    with {:ok, body} <- get("/search/shows", q: query) do
      {:ok, body |> List.wrap() |> Enum.flat_map(&shape_result/1)}
    end
  end

  @doc """
  `search/1` as a page. TVmaze's show search answers its best ten and has no
  second page, so page 1 is the whole answer and `more?` is always false.
  """
  @spec search_page(String.t(), pos_integer()) ::
          {:ok, %{results: [map()], more?: boolean()}} | {:error, term()}
  def search_page(query, 1) when is_binary(query) do
    with {:ok, results} <- search(query), do: {:ok, %{results: results, more?: false}}
  end

  def search_page(query, page) when is_binary(query) and is_integer(page) and page > 1,
    do: {:ok, %{results: [], more?: false}}

  @doc """
  A search row out of one `{score, show}` hit, or `[]` for one with no name.

      iex> Kati.Media.Tvmaze.shape_result(%{
      ...>   "score" => 0.9,
      ...>   "show" => %{
      ...>     "id" => 82,
      ...>     "name" => "Game of Thrones",
      ...>     "premiered" => "2011-04-17",
      ...>     "summary" => "<p>Nine noble families.</p>",
      ...>     "image" => %{"medium" => "https://static.tvmaze.com/m.jpg"}
      ...>   }
      ...> })
      [%{title: "Game of Thrones", kind: :tv, source: :tvmaze, source_id: "82", year: "2011",
         overview: "Nine noble families.", poster_path: "https://static.tvmaze.com/m.jpg",
         titles: ["Game of Thrones"]}]

      iex> Kati.Media.Tvmaze.shape_result(%{"show" => %{"id" => 1, "name" => ""}})
      []
  """
  @spec shape_result(term()) :: [map()]
  def shape_result(%{"show" => %{"id" => id, "name" => name} = show})
      when is_integer(id) and is_binary(name) and name != "" do
    [
      %{
        title: name,
        kind: :tv,
        source: :tvmaze,
        source_id: Integer.to_string(id),
        year: year_string(show["premiered"]),
        overview: Provider.plain(show["summary"]),
        poster_path: https(image(show, "medium")) || https(image(show, "original")),
        titles: [name]
      }
    ]
  end

  def shape_result(_other), do: []

  @doc """
  Fill the cache for one TVmaze show, its seasons and its episodes, answering
  `%{title: row, seasons: n, episodes: n}` as `Kati.Media.Tmdb.fetch/2` does.
  """
  @spec fetch(String.t(), :movie | :tv) :: {:ok, map()} | {:error, term()}
  def fetch(source_id, _kind) when is_binary(source_id) do
    with {_id, ""} <- Integer.parse(source_id),
         {:ok, %{} = show} <-
           get("/shows/" <> source_id, [{"embed[]", "seasons"}, {"embed[]", "episodes"}]),
         {:ok, title} <- upsert_title(show, source_id) do
      seasons = Enum.count(embedded(show, "seasons"), &upsert_season(&1, source_id))
      episodes = Enum.count(embedded(show, "episodes"), &upsert_episode(&1, source_id))
      {:ok, %{title: title, seasons: seasons, episodes: episodes}}
    else
      {:error, _reason} = error -> error
      _unusable -> {:error, :not_found}
    end
  end

  defp upsert_title(show, source_id) do
    regular = Enum.count(embedded(show, "episodes"), &is_integer(&1["number"]))

    attrs =
      %{
        source: :tvmaze,
        source_id: source_id,
        kind: :tv,
        title: show["name"],
        original_language: Map.get(@languages, show["language"]),
        overview: Provider.plain(show["summary"]),
        poster_path: https(image(show, "original")) || https(image(show, "medium")),
        genres: genres(show),
        tvmaze_id: source_id,
        fetched_at: DateTime.utc_now(),
        last_checked_at: DateTime.utc_now()
      }
      |> Provider.put_if(:imdb_id, text(get_in_safe(show, ["externals", "imdb"])))
      |> Provider.put_if(:tvdb_id, integer_text(get_in_safe(show, ["externals", "thetvdb"])))
      |> Provider.put_if(:first_release_year, year_number(show["premiered"]))
      |> Provider.put_if(:episode_count, Provider.positive(regular))

    Provider.upsert(CachedTitle, [source: :tvmaze, source_id: source_id], attrs)
  end

  defp upsert_season(%{"number" => number} = season, title_source_id)
       when is_integer(number) and number >= 0 do
    attrs =
      %{
        source: :tvmaze,
        title_source_id: title_source_id,
        season_number: number,
        source_id: integer_text(season["id"]),
        name: text(season["name"]),
        overview: Provider.plain(season["summary"]),
        poster_path: https(image(season, "original")) || https(image(season, "medium")),
        fetched_at: DateTime.utc_now()
      }
      |> Provider.put_if(:episode_count, Provider.positive(season["episodeOrder"]))
      |> Provider.put_day(season["premiereDate"])

    match?(
      {:ok, _row},
      Provider.upsert(
        CachedSeason,
        [source: :tvmaze, title_source_id: title_source_id, season_number: number],
        attrs
      )
    )
  end

  defp upsert_season(_season, _title_source_id), do: false

  defp upsert_episode(%{"id" => id} = episode, title_source_id) when is_integer(id) do
    special = not is_integer(episode["number"])
    episode_id = Integer.to_string(id)

    attrs =
      %{
        source: :tvmaze,
        source_id: episode_id,
        title_source_id: title_source_id,
        season_number: if(special, do: 0, else: non_negative(episode["season"])),
        episode_number: if(special, do: nil, else: non_negative(episode["number"])),
        special: special,
        title: text(episode["name"]),
        overview: Provider.plain(episode["summary"]),
        still_path: https(image(episode, "original")) || https(image(episode, "medium")),
        runtime_minutes: Provider.positive(episode["runtime"]),
        fetched_at: DateTime.utc_now()
      }
      |> put_air(episode["airstamp"], episode["airdate"])

    match?(
      {:ok, _row},
      Provider.upsert(CachedEpisode, [source: :tvmaze, source_id: episode_id], attrs)
    )
  end

  defp upsert_episode(_episode, _title_source_id), do: false

  defp put_air(attrs, stamp, date) when is_binary(stamp) and stamp != "" do
    case DateTime.from_iso8601(stamp) do
      {:ok, instant, _offset} ->
        attrs
        |> Map.put(:air_at, %{instant | microsecond: {0, 6}})
        |> Map.put(:date_confidence, :exact)

      _error ->
        Provider.put_day(attrs, date)
    end
  end

  defp put_air(attrs, _stamp, date), do: Provider.put_day(attrs, date)

  defp get(path, params) do
    Provider.request(
      [
        method: :get,
        url: @host <> path,
        params: params,
        headers: [{"accept", "application/json"}]
      ],
      @dns_host,
      :tvmaze_req_options
    )
  end

  defp embedded(show, key) do
    case get_in_safe(show, ["_embedded", key]) do
      list when is_list(list) -> list
      _none -> []
    end
  end

  defp genres(show) do
    listed = show |> Map.get("genres") |> List.wrap() |> Enum.filter(&is_binary/1)
    animated = if show["type"] == "Animation", do: ["Animation"], else: []

    case Enum.uniq(animated ++ listed) do
      [] -> nil
      all -> Enum.join(all, ", ")
    end
  end

  defp image(map, size), do: get_in_safe(map, ["image", size])

  defp year_number(date) when is_binary(date) do
    case Integer.parse(String.slice(date, 0, 4)) do
      {year, ""} when year >= 1888 -> year
      _other -> nil
    end
  end

  defp year_number(_date), do: nil

  defp year_string(date) do
    case year_number(date) do
      nil -> nil
      year -> Integer.to_string(year)
    end
  end

  defp non_negative(n) when is_integer(n) and n >= 0, do: n
  defp non_negative(_other), do: nil

  defp integer_text(n) when is_integer(n), do: Integer.to_string(n)
  defp integer_text(_other), do: nil

  defp https("https://" <> _rest = url), do: url
  defp https(_other), do: nil

  defp text(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp text(_other), do: nil

  defp get_in_safe(value, []), do: value
  defp get_in_safe(%{} = map, [key | rest]), do: get_in_safe(Map.get(map, key), rest)
  defp get_in_safe(_other, _path), do: nil
end
