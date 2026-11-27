defmodule Kati.Media.MusicBrainz do
  @moduledoc """
  MusicBrainz: albums by title or artist, with no key at all.

  The other half of the gap `Kati.Sources`' moduledoc names: `Kati.Music.Album`
  has carried `source: :musicbrainz` since the shelf existed, and nothing in
  `lib/` ever asked the catalogue (mishka-group/kati#101). This is the client,
  so screen 19's music section can find an album instead of telling the reader
  to type one.

  ## One endpoint, and the header it requires

  `GET /ws/2/release-group/?query=…&fmt=json` — a release group is what a
  person means by *album*: the work, not one pressing of it. MusicBrainz asks
  every client to identify itself, so the request carries Kati's own
  `user-agent`; that is the API's rule, not a preference of ours.

  ## Rate limit

  One request a second for an anonymous client. Kati asks once per committed
  query — the same debounce screens 19 already applies to the film sections —
  and a `503`/`429` is named `:rate_limited` by `Kati.Media.Provider.request/3`
  rather than retried in a loop.

  ## The row

  The shape the shelf writes: `:title`, `:sub`, `:seed`, `:kind`, plus the add's
  own fields (`:artist`, `:year`, `:source_id`). `:seed` is the release group's
  mbid, so the generated sleeve is the same for the same album twice.
  """

  alias Kati.Media.Provider

  @host "https://musicbrainz.org"
  @dns_host "musicbrainz.org"

  # MusicBrainz's own rule: a client identifies itself with a reachable URL.
  @agent "Kati/1.0 (https://github.com/mishka-group/kati)"

  @doc "Whether MusicBrainz can be asked at all. It needs no key, so always."
  @spec usable?() :: boolean()
  def usable?, do: true

  @doc """
  Albums matching `query`, best first, at most twenty.

  Under two characters nothing is sent, the same minimum the local search
  and Open Library use.
  """
  @spec search(String.t()) :: {:ok, [map()]} | {:error, term()}
  def search(query) when is_binary(query) do
    case String.trim(query) do
      "" ->
        {:ok, []}

      trimmed ->
        if String.length(trimmed) < 2 do
          {:ok, []}
        else
          with {:ok, body} <- get(trimmed) do
            {:ok, body |> Map.get("release-groups", []) |> Enum.flat_map(&shape/1)}
          end
        end
    end
  end

  @doc "`search/1` as a page; the first answer is the only one."
  @spec search_page(String.t(), pos_integer()) ::
          {:ok, %{results: [map()], more?: boolean()}} | {:error, term()}
  def search_page(query, 1) when is_binary(query) do
    with {:ok, results} <- search(query), do: {:ok, %{results: results, more?: false}}
  end

  def search_page(_query, _page), do: {:ok, %{results: [], more?: false}}

  @doc """
  One row out of one release-group document, or `[]` for one with no title.

      iex> Kati.Media.MusicBrainz.shape(%{
      ...>   "id" => "7f2b5d0e-0000-0000-0000-000000000000",
      ...>   "title" => "Tide Ledger",
      ...>   "first-release-date" => "1997-05-01",
      ...>   "primary-type" => "Album",
      ...>   "artist-credit" => [%{"name" => "Kell Ostrand"}]
      ...> })
      [%{title: "Tide Ledger", sub: "Kell Ostrand · 1997 · Album",
         seed: "7f2b5d0e-0000-0000-0000-000000000000", kind: :album,
         source: :musicbrainz, source_id: "7f2b5d0e-0000-0000-0000-000000000000",
         artist: "Kell Ostrand", year: 1997, kind_label: "Album"}]
  """
  @spec shape(map()) :: [map()]
  def shape(%{} = doc) do
    case Map.get(doc, "title") do
      title when is_binary(title) and title != "" ->
        artist = doc |> Map.get("artist-credit", []) |> List.first() |> credit_name()
        year = doc |> Map.get("first-release-date", "") |> first_year()
        type = Map.get(doc, "primary-type")
        id = Map.get(doc, "id")

        [
          %{
            title: String.trim(title),
            sub: sub(artist, year, type),
            seed: id,
            kind: :album,
            source: :musicbrainz,
            source_id: id,
            artist: artist,
            year: year,
            kind_label: type
          }
        ]

      _none ->
        []
    end
  end

  def shape(_doc), do: []

  defp credit_name(%{"name" => name}) when is_binary(name), do: name
  defp credit_name(_credit), do: nil

  defp first_year(date) when is_binary(date) do
    case Integer.parse(String.slice(date, 0, 4)) do
      {year, ""} -> year
      _none -> nil
    end
  end

  defp first_year(_date), do: nil

  defp sub(artist, year, type) do
    [artist, year && Integer.to_string(year), type]
    |> Enum.reject(&is_nil/1)
    |> case do
      [] -> nil
      parts -> Enum.join(parts, " · ")
    end
  end

  defp get(query) do
    # MusicBrainz's own rule: one anonymous request a second. The wait runs in
    # the reader's fetch task, never on the screen.
    Kati.Media.RateLimit.take(:musicbrainz, 1_000)

    Provider.request(
      [
        method: :get,
        url: @host <> "/ws/2/release-group/",
        params: [query: query, fmt: "json", limit: 20],
        headers: [{"accept", "application/json"}, {"user-agent", @agent}]
      ],
      @dns_host,
      :music_brainz_req_options
    )
  end
end
