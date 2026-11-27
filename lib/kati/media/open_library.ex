defmodule Kati.Media.OpenLibrary do
  @moduledoc """
  Open Library: books, by title, author or ISBN, with no key at all.

  The shelf this app has always been able to *hold* — `Kati.Books.Book` even
  carries `source: :open_library` — but never to *fill*: the only way in was
  type it by hand. `Kati.Sources`' moduledoc says so in as many words, and
  screen 19's books panel said *"Searching for books is coming"* under the
  reader's query. This is that client (mishka-group/kati#100).

  ## One endpoint

  `GET /search.json?q=…` — title, author, first year, median page count, ISBN
  and cover id in one answer, so a search row carries everything the shelf
  needs and a second request is never needed to add it. Keyless, CORS-free and
  documented, which is the tier-0 rule `Kati.Sources` sets: a book is found
  without an account or a token.

  ## The row

  The same shape `Kati.Search.Query`'s local book hits carry — `:title`, `:sub`,
  `:seed`, `:kind` — plus the fields an add writes (`:author`, `:year`,
  `:pages`, `:isbn`, `:source_id`, `:cover_id`). `:seed` is `"ol-<cover id>"`
  where Open Library has a jacket, so `Kati.Design.Images.poster/1` draws the
  same picture for the same book twice; `nil` where it has none, and the row
  draws the placeholder rather than a borrowed cover.

  ## Failures

  `Kati.Media.Provider.request/3` is the transport and words its own reasons.
  Nothing here raises; an unreachable catalogue is `{:error, reason}` and the
  search section says so, the way the keyless film sections do.
  """

  alias Kati.Media.Provider

  @host "https://openlibrary.org"
  @dns_host "openlibrary.org"
  @fields "key,title,author_name,first_publish_year,number_of_pages_median,isbn,cover_i,edition_count"

  @doc "Whether Open Library can be asked at all. It needs no key, so always."
  @spec usable?() :: boolean()
  def usable?, do: true

  @doc """
  Books matching `query`, best first, at most `#{20}`.

  Empty and too-short queries answer `{:ok, []}` without a request — the same
  minimum `Kati.Search.minimum/1` sets for the local search, so the section
  appears exactly when the local one would have looked.
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
          with {:ok, body} <- get("/search.json", q: trimmed, limit: 20, fields: @fields) do
            {:ok, body |> Map.get("docs", []) |> Enum.flat_map(&shape/1)}
          end
        end
    end
  end

  @doc "`search/1` as a page; Open Library's first answer is the only one."
  @spec search_page(String.t(), pos_integer()) ::
          {:ok, %{results: [map()], more?: boolean()}} | {:error, term()}
  def search_page(query, 1) when is_binary(query) do
    with {:ok, results} <- search(query), do: {:ok, %{results: results, more?: false}}
  end

  def search_page(_query, _page), do: {:ok, %{results: [], more?: false}}

  @doc """
  One search row out of one Open Library document, or `[]` for a document with
  no title (a work with none is not a book anybody can add).

      iex> Kati.Media.OpenLibrary.shape(%{
      ...>   "key" => "/works/OL123W",
      ...>   "title" => "The Salt Almanac",
      ...>   "author_name" => ["Ines Karvel"],
      ...>   "first_publish_year" => 2024,
      ...>   "number_of_pages_median" => 380,
      ...>   "isbn" => ["9780571339152"],
      ...>   "cover_i" => 12345
      ...> })
      [%{title: "The Salt Almanac", sub: "Ines Karvel · 2024 · 380 p.",
         seed: "ol-12345", kind: :book, source: :open_library,
         source_id: "/works/OL123W", author: "Ines Karvel", year: 2024,
         pages: 380, isbn: "9780571339152", cover_id: 12345}]
  """
  @spec shape(map()) :: [map()]
  def shape(%{} = doc) do
    case Map.get(doc, "title") do
      title when is_binary(title) and title != "" ->
        author = doc |> Map.get("author_name", []) |> List.first()
        year = int(Map.get(doc, "first_publish_year"))
        pages = int(Map.get(doc, "number_of_pages_median"))
        isbn = doc |> Map.get("isbn", []) |> Enum.find(&(String.length(&1) == 13))
        cover = int(Map.get(doc, "cover_i"))

        [
          %{
            title: String.trim(title),
            sub: sub(author, year, pages),
            seed: cover && "ol-#{cover}",
            kind: :book,
            source: :open_library,
            source_id: Map.get(doc, "key"),
            author: author,
            year: year,
            pages: pages,
            isbn: isbn,
            cover_id: cover
          }
        ]

      _none ->
        []
    end
  end

  def shape(_doc), do: []

  # `Ines Karvel · 2024 · 380 p.` — the line a search row draws under the
  # title, with each part dropped when Open Library does not know it. No
  # translation: an author's name and a year are not words, and `p.` is the
  # abbreviation `Kati.Screens.BookDetail` already writes on the book's page.
  defp sub(author, year, pages) do
    [author, year && Integer.to_string(year), pages && "#{pages} p."]
    |> Enum.reject(&is_nil/1)
    |> case do
      [] -> nil
      parts -> Enum.join(parts, " · ")
    end
  end

  defp int(value) when is_integer(value) and value > 0, do: value
  defp int(_value), do: nil

  defp get(path, params) do
    Provider.request(
      [
        method: :get,
        url: @host <> path,
        params: params,
        headers: [{"accept", "application/json"}]
      ],
      @dns_host,
      :open_library_req_options
    )
  end
end
