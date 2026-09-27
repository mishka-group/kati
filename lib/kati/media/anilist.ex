defmodule Kati.Media.Anilist do
  @moduledoc """
  AniList: anime, as series and as films, with no key at all.

  One GraphQL endpoint, `POST https://graphql.anilist.co`, asked two
  questions — `search/1` finds titles, `fetch/2` fills the cache for one of
  them — and between them they write `Kati.Media.CachedTitle`,
  `Kati.Media.CachedSeason` and `Kati.Media.CachedEpisode` under `source:
  :anilist` and nothing else. Like `Kati.Media.Tmdb`, it never touches a
  `Kati.Media.TrackedTitle`: that row is the reader's.

  ## Film or series

  AniList's `format` decides. `MOVIE` is a film; `TV`, `TV_SHORT`, `ONA`,
  `OVA` and `SPECIAL` are all a series, because each is something with
  episodes that can be ticked one at a time.

  ## Anime, by the rule that already exists

  The cached row says `original_language: "ja"` when AniList's
  `countryOfOrigin` is `JP`, and its `genres` always carry *Animation* —
  every AniList anime is animated, and AniList's own genre list never says
  so. That is `Kati.Media.Anime.provider_says?/1`'s rule 3, so a title added
  from here is tracked as `:anime` with no rule of its own.

  ## Episodes AniList does not have

  AniList counts episodes — `episodes`, or for a show still airing the
  number of the next one — and has no episode entity: no id, no title, no
  air date except the next one's. So a series is written as one season with
  episodes `1..N`, each with `source_id` `"<media id>-<n>"`.

  Deterministic, and that is the point: `Kati.Media.Watch` joins a tick to
  its episode by `{source, episode_source_id}`, so an id made up afresh on
  each fetch would orphan every tick the next time the title was written.
  `"<media id>-<n>"` is the same string for the same episode every time, and
  cannot collide across titles because the media id is in it. The runtime is
  AniList's per-episode `duration`, and the next episode to air carries its
  exact `airingAt`.

  ## Failures

  Every answer is `{:ok, …}` or `{:error, reason}`, never a raise — the
  transport is `Kati.Media.Provider.request/3`, and its reasons are worded by
  `Kati.Media.Provider.message/2`.

  ## Test seam

  `:anilist_req_options`, merged into every request as `:tmdb_req_options`
  is into TMDB's, so a host test hands Req an adapter instead of a socket.
  """

  alias Kati.Media.CachedEpisode
  alias Kati.Media.CachedSeason
  alias Kati.Media.CachedTitle
  alias Kati.Media.Provider

  @url "https://graphql.anilist.co"
  @dns_host "graphql.anilist.co"

  @fields "id format episodes duration title{romaji english native} coverImage{large} " <>
            "startDate{year month day} countryOfOrigin description(asHtml:false) genres"

  @search "query($s:String,$p:Int){Page(page:$p,perPage:20){pageInfo{hasNextPage} " <>
            "media(search:$s,type:ANIME,isAdult:false){" <> @fields <> "}}}"

  @detail "query($id:Int){Media(id:$id,type:ANIME){" <>
            @fields <>
            " idMal coverImage{extraLarge} bannerImage nextAiringEpisode{episode airingAt}}}"

  @languages %{"JP" => "ja", "KR" => "ko", "CN" => "zh", "TW" => "zh"}

  @doc """
  Search AniList for an anime.

  Answers `{:ok, [result]}` in `Kati.Media.Tmdb.result/0`'s shape with
  `source: :anilist` on each row, or `{:error, reason}`. The empty query is
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
    with {:ok, page} <- search_page(query, 1), do: {:ok, page.results}
  end

  @doc """
  One page of `search/1`'s answer, and whether AniList has another after it
  (`pageInfo.hasNextPage`). Twenty rows a page.
  """
  @spec search_page(String.t(), pos_integer()) ::
          {:ok, %{results: [map()], more?: boolean()}} | {:error, term()}
  def search_page(query, page) when is_binary(query) and is_integer(page) and page > 0 do
    case String.trim(query) do
      "" ->
        {:ok, %{results: [], more?: false}}

      trimmed ->
        with {:ok, body} <- post(@search, %{s: trimmed, p: page}) do
          {:ok,
           %{
             results:
               body
               |> get_in_safe(["data", "Page", "media"])
               |> List.wrap()
               |> Enum.flat_map(&shape_result/1),
             more?: get_in_safe(body, ["data", "Page", "pageInfo", "hasNextPage"]) == true
           }}
        end
    end
  end

  @doc """
  A search row out of one AniList `media` object, or `[]` for one with no
  usable title.

      iex> Kati.Media.Anilist.shape_result(%{
      ...>   "id" => 177_709,
      ...>   "format" => "TV",
      ...>   "title" => %{"romaji" => "SAKAMOTO DAYS", "english" => "SAKAMOTO DAYS"},
      ...>   "startDate" => %{"year" => 2025},
      ...>   "coverImage" => %{"large" => "https://s4.anilist.co/c.jpg"},
      ...>   "description" => "A retired hitman<br>runs a shop."
      ...> })
      [%{title: "SAKAMOTO DAYS", kind: :tv, source: :anilist, source_id: "177709", year: "2025",
         overview: "A retired hitman runs a shop.", poster_path: "https://s4.anilist.co/c.jpg",
         titles: ["SAKAMOTO DAYS"]}]

      iex> Kati.Media.Anilist.shape_result(%{"id" => 1, "title" => %{}})
      []
  """
  @spec shape_result(term()) :: [map()]
  def shape_result(%{"id" => id} = media) when is_integer(id) do
    case title_of(media) do
      nil ->
        []

      title ->
        [
          %{
            title: title,
            kind: kind_of(media["format"]),
            source: :anilist,
            source_id: Integer.to_string(id),
            year: year_string(media),
            overview: Provider.plain(media["description"]),
            poster_path: https(get_in_safe(media, ["coverImage", "large"])),
            titles: titles_of(media)
          }
        ]
    end
  end

  def shape_result(_other), do: []

  @doc """
  The kind a `format` is.

      iex> Kati.Media.Anilist.kind_of("MOVIE")
      :movie

      iex> Kati.Media.Anilist.kind_of("ONA")
      :tv
  """
  @spec kind_of(term()) :: :movie | :tv
  def kind_of("MOVIE"), do: :movie
  def kind_of(_series), do: :tv

  @doc """
  Fill the cache for one AniList title, answering `%{title: row, seasons: n,
  episodes: n}` as `Kati.Media.Tmdb.fetch/2` does.

  `kind` is what the row that was tapped said; AniList's own `format` in the
  answer is what is written, so a row can never be cached as the wrong kind.
  """
  @spec fetch(String.t(), :movie | :tv) :: {:ok, map()} | {:error, term()}
  def fetch(source_id, _kind) when is_binary(source_id) do
    with {id, ""} <- Integer.parse(source_id),
         {:ok, body} <- post(@detail, %{id: id}),
         %{} = media <- get_in_safe(body, ["data", "Media"]) || {:error, :not_found},
         {:ok, title} <- upsert_title(media, source_id) do
      write_episodes(media, title, source_id)
    else
      {:error, _reason} = error -> error
      _unparsed -> {:error, :not_found}
    end
  end

  defp write_episodes(_media, %CachedTitle{kind: :movie} = title, _source_id) do
    {:ok, %{title: title, seasons: 0, episodes: 0}}
  end

  defp write_episodes(media, title, source_id) do
    count = episode_count(media)

    if count > 0 do
      _season = upsert_season(media, source_id, count)
      written = Enum.count(1..count, &upsert_episode(media, source_id, &1))
      {:ok, %{title: title, seasons: 1, episodes: written}}
    else
      {:ok, %{title: title, seasons: 0, episodes: 0}}
    end
  end

  @doc """
  How many episodes to write: AniList's count, or — for a show still airing
  with no count yet — up to the next one to air.

      iex> Kati.Media.Anilist.episode_count(%{"episodes" => 12})
      12

      iex> Kati.Media.Anilist.episode_count(%{"episodes" => nil, "nextAiringEpisode" => %{"episode" => 8}})
      8

      iex> Kati.Media.Anilist.episode_count(%{})
      0
  """
  @spec episode_count(map()) :: non_neg_integer()
  def episode_count(media) do
    counted = Provider.positive(media["episodes"]) || 0
    next = Provider.positive(get_in_safe(media, ["nextAiringEpisode", "episode"])) || 0
    max(counted, next)
  end

  defp upsert_title(media, source_id) do
    kind = kind_of(media["format"])

    attrs =
      %{
        source: :anilist,
        source_id: source_id,
        kind: kind,
        title: title_of(media),
        title_original: blank(get_in_safe(media, ["title", "native"])) || romaji(media),
        original_language: Map.get(@languages, media["countryOfOrigin"]),
        overview: Provider.plain(media["description"]),
        poster_path:
          https(get_in_safe(media, ["coverImage", "extraLarge"])) ||
            https(get_in_safe(media, ["coverImage", "large"])),
        backdrop_path: https(media["bannerImage"]),
        runtime_minutes: if(kind == :movie, do: Provider.positive(media["duration"])),
        genres: genres(media["genres"]),
        anilist_id: source_id,
        fetched_at: DateTime.utc_now(),
        last_checked_at: DateTime.utc_now()
      }
      |> Provider.put_if(:mal_id, if(is_integer(media["idMal"]), do: to_string(media["idMal"])))
      |> Provider.put_if(:first_release_year, year_number(media))
      |> Provider.put_if(
        :episode_count,
        if(kind == :tv, do: Provider.positive(episode_count(media)))
      )

    Provider.upsert(CachedTitle, [source: :anilist, source_id: source_id], attrs)
  end

  defp upsert_season(media, source_id, count) do
    Provider.upsert(
      CachedSeason,
      [source: :anilist, title_source_id: source_id, season_number: 1],
      %{
        source: :anilist,
        title_source_id: source_id,
        season_number: 1,
        source_id: source_id <> "-s1",
        episode_count: count,
        fetched_at: DateTime.utc_now()
      }
      |> Provider.put_day(start_date(media))
    )
  end

  defp upsert_episode(media, source_id, number) do
    episode_id = source_id <> "-" <> Integer.to_string(number)

    attrs =
      %{
        source: :anilist,
        source_id: episode_id,
        title_source_id: source_id,
        season_number: 1,
        episode_number: number,
        special: false,
        runtime_minutes: Provider.positive(media["duration"]),
        fetched_at: DateTime.utc_now()
      }
      |> put_airing(media["nextAiringEpisode"], number)

    match?(
      {:ok, _row},
      Provider.upsert(CachedEpisode, [source: :anilist, source_id: episode_id], attrs)
    )
  end

  defp put_airing(attrs, %{"episode" => number, "airingAt" => at}, number) when is_integer(at) do
    case DateTime.from_unix(at) do
      {:ok, instant} ->
        attrs
        |> Map.put(:air_at, %{instant | microsecond: {0, 6}})
        |> Map.put(:date_confidence, :exact)

      _error ->
        attrs
    end
  end

  defp put_airing(attrs, _next, _number), do: attrs

  defp post(query, variables) do
    Provider.request(
      [
        method: :post,
        url: @url,
        json: %{query: query, variables: variables},
        headers: [{"accept", "application/json"}]
      ],
      @dns_host,
      :anilist_req_options
    )
  end

  defp title_of(media) do
    blank(get_in_safe(media, ["title", "english"])) || romaji(media) ||
      blank(get_in_safe(media, ["title", "native"]))
  end

  defp romaji(media), do: blank(get_in_safe(media, ["title", "romaji"]))

  defp titles_of(media) do
    ["english", "romaji"]
    |> Enum.map(&blank(get_in_safe(media, ["title", &1])))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp genres(list) when is_list(list) do
    ["Animation" | Enum.filter(list, &is_binary/1)] |> Enum.uniq() |> Enum.join(", ")
  end

  defp genres(_none), do: "Animation"

  defp year_number(media) do
    case get_in_safe(media, ["startDate", "year"]) do
      year when is_integer(year) and year >= 1888 -> year
      _unknown -> nil
    end
  end

  defp year_string(media) do
    case year_number(media) do
      nil -> nil
      year -> Integer.to_string(year)
    end
  end

  defp start_date(media) do
    with %{"year" => y, "month" => m, "day" => d}
         when is_integer(y) and is_integer(m) and is_integer(d) <- media["startDate"],
         {:ok, date} <- Date.new(y, m, d) do
      Date.to_iso8601(date)
    else
      _partial -> nil
    end
  end

  defp https("https://" <> _rest = url), do: url
  defp https(_other), do: nil

  defp blank(text) when is_binary(text) do
    case String.trim(text) do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp blank(_other), do: nil

  defp get_in_safe(value, []), do: value
  defp get_in_safe(%{} = map, [key | rest]), do: get_in_safe(Map.get(map, key), rest)
  defp get_in_safe(_other, _path), do: nil
end
