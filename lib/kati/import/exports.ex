defmodule Kati.Import.Exports do
  @moduledoc """
  The two anime exports that are not CSV, read into the header-and-rows shape
  the rest of the import works on.

  Screen 140 offers **MyAnimeList · animelist.xml** and **AniList ·
  anilist-export.json**, and `Kati.Import.Job.read/2` only read CSV — so the
  file a MyAnimeList reader actually has was answered *unrecognised* (P5).

  Both are turned into a table rather than taught to the rest of the pipeline:
  the mapping card, the rating-scale reading, the anime marking and the commit
  already work on headers and rows, and a second path through them is a second
  place for the two to disagree.

    * **MyAnimeList** writes one `<anime>` element per title. The headers are
      `Anime Title`, `Type`, `My Score`, `Watched Date` and `Watched
      Episodes` — `Anime Title` and `My Score` are the columns
      `Kati.Import.Mapping.looks_like/1` recognises as MyAnimeList's, so
      everything in the file is marked anime. A score of `0` is MyAnimeList's
      *not scored*, and a date of `0000-00-00` is *no date*; both become blank.
    * **AniList** writes `lists`, each with `entries` carrying a `media`
      object. The score is on whatever scale the reader chose there — up to 100
      — so it is brought to ten here, before the column is read.

  Plain pattern reading for the XML rather than an XML library: the export is
  flat and fixed, and a parser dependency on the phone for one file shape is a
  larger thing to carry than these functions.
  """

  @mal_headers ["Anime Title", "Type", "My Score", "Watched Date", "Watched Episodes"]
  @anilist_headers ["Title", "Type", "Rating", "Watched Date", "AniList ID"]

  @doc """
  The export's table, or `:not_an_export` for anything else (CSV included).

      iex> Kati.Import.Exports.table("Title,Rating\\nDune,4")
      :not_an_export
  """
  @spec table(String.t()) :: {:ok, {[String.t()], [[String.t()]]}} | :not_an_export
  def table(text) when is_binary(text) do
    trimmed = String.trim_leading(text)

    cond do
      String.starts_with?(trimmed, "<") and String.contains?(trimmed, "<myanimelist") ->
        {:ok, {@mal_headers, Kati.Import.Exports.mal_rows(trimmed)}}

      String.starts_with?(trimmed, "{") ->
        anilist(trimmed)

      true ->
        :not_an_export
    end
  end

  @doc """
  One row per `<anime>` element.

      iex> xml = "<myanimelist><anime><series_title><![CDATA[Cowboy Bebop]]></series_title><series_type>TV</series_type><my_score>9</my_score><my_finish_date>1999-04-24</my_finish_date><my_watched_episodes>26</my_watched_episodes></anime></myanimelist>"
      iex> Kati.Import.Exports.mal_rows(xml)
      [["Cowboy Bebop", "TV", "9", "1999-04-24", "26"]]

      iex> xml = "<myanimelist><anime><series_title>Frieren</series_title><series_type>TV</series_type><my_score>0</my_score><my_finish_date>0000-00-00</my_finish_date><my_watched_episodes>3</my_watched_episodes></anime></myanimelist>"
      iex> Kati.Import.Exports.mal_rows(xml)
      [["Frieren", "TV", "", "", "3"]]
  """
  @spec mal_rows(String.t()) :: [[String.t()]]
  def mal_rows(xml) do
    ~r{<anime>(.*?)</anime>}s
    |> Regex.scan(xml, capture: :all_but_first)
    |> Enum.map(fn [entry] ->
      [
        tag(entry, "series_title"),
        tag(entry, "series_type"),
        score(tag(entry, "my_score")),
        date(tag(entry, "my_finish_date")),
        tag(entry, "my_watched_episodes")
      ]
    end)
    |> Enum.reject(fn [title | _] -> title == "" end)
  end

  defp tag(entry, name) do
    case Regex.run(~r{<#{name}>(.*?)</#{name}>}s, entry, capture: :all_but_first) do
      [raw] -> raw |> unwrap_cdata() |> unescape() |> String.trim()
      nil -> ""
    end
  end

  defp unwrap_cdata(raw) do
    case Regex.run(~r{^\s*<!\[CDATA\[(.*)\]\]>\s*$}s, raw, capture: :all_but_first) do
      [inner] -> inner
      nil -> raw
    end
  end

  defp unescape(text) do
    text
    |> String.replace("&lt;", "<")
    |> String.replace("&gt;", ">")
    |> String.replace("&quot;", "\"")
    |> String.replace("&apos;", "'")
    |> String.replace("&amp;", "&")
  end

  defp score(raw) do
    case Integer.parse(raw) do
      {n, _} when n > 0 -> Integer.to_string(n)
      _unscored -> ""
    end
  end

  defp date("0000" <> _rest), do: ""
  defp date(raw), do: raw

  defp anilist(json) do
    case JSON.decode(json) do
      {:ok, %{"lists" => lists}} when is_list(lists) ->
        entries = Enum.flat_map(lists, &Map.get(&1, "entries", []))
        {:ok, {@anilist_headers, Kati.Import.Exports.anilist_rows(entries)}}

      _other ->
        :not_an_export
    end
  end

  @doc """
  One row per AniList list entry, its score brought to ten.

      iex> Kati.Import.Exports.anilist_rows([
      ...>   %{"score" => 85, "completedAt" => %{"year" => 2024, "month" => 3, "day" => 9},
      ...>     "media" => %{"id" => 1, "format" => "TV", "title" => %{"english" => "Frieren", "romaji" => "Sousou no Frieren"}}}
      ...> ])
      [["Frieren", "TV", "9", "2024-03-09", "1"]]
  """
  @spec anilist_rows([map()]) :: [[String.t()]]
  def anilist_rows(entries) do
    scale = if Enum.any?(entries, &((&1["score"] || 0) > 10)), do: 10, else: 1

    entries
    |> Enum.map(fn entry ->
      media = entry["media"] || %{}
      title = media["title"] || %{}

      [
        title["english"] || title["romaji"] || title["native"] || "",
        media["format"] || "",
        anilist_score(entry["score"], scale),
        anilist_date(entry["completedAt"]),
        to_string(media["id"] || "")
      ]
    end)
    |> Enum.reject(fn [name | _] -> name == "" end)
  end

  defp anilist_score(score, scale) when is_number(score) and score > 0,
    do: score |> Kernel./(scale) |> round() |> Integer.to_string()

  defp anilist_score(_score, _scale), do: ""

  defp anilist_date(%{"year" => y, "month" => m, "day" => d})
       when is_integer(y) and is_integer(m) and is_integer(d) do
    case Date.new(y, m, d) do
      {:ok, date} -> Date.to_iso8601(date)
      _invalid -> ""
    end
  end

  defp anilist_date(_none), do: ""
end
