defmodule Kati.Library.ShelfFilters do
  @moduledoc """
  The sort and filter screen 145 chooses, and the shelf it is applied to.

  ## The defect

  Screen 145 — the sheet the Library's sort disc opens — was a picture. It had
  no way to learn which shelf opened it and handed nothing back, so no sort or
  filter chosen on it could ever affect anything. It
  also opened **already filtered** — 2020s, 4★ and up, Anime — and announced
  `showing 41 of 418` on a phone that might hold two (#54).

  Both are the same missing thing: the sheet had no state outside its own
  socket, and its own socket dies on the pop.

  ## Where the choice lives

  `Mob.State`, which is the app's own durable key-value store and already
  holds the locale, the theme and the search history. Not a resource: a sort
  order is a view preference and not a fact about the library, and
  `Kati.Media` is for what a provider said and what the reader did.

  The sheet writes it, pops through `Kati.Screens.Resume`, and screen 03's
  `handle_kati(:resumed, …)` re-reads the shelf — which is the mechanism the
  whole app now uses for *a screen you come back to re-reads*.

  ## What can be filtered, and what cannot

  Four facets are drawn on board 145 and two of them have nothing behind them:

    * **Sort** — real. `last_touched_at`, `title` and the rating are all on the
      rows the shelf already reads.
    * **Genre** — real, from `Kati.Media.CachedTitle.genres`, the same
      `", "`-separated column screen 07's genre bars read.
    * **Decade** — no column. `Kati.Media.CachedTitle` holds `next_release_at`,
      which is the NEXT release and not a first-air year. Screen 14's meta line
      drops the year for this reason.
    * **Service** — no resource. `Kati.Media.Watch.service` is where ONE night
      was watched, not a catalogue, and screen 08 and screen 14 both say so.

  So the two that cannot be answered are not offered on a device. The board
  keeps all four, because the board is a drawing of a library this app cannot
  yet hold.
  """

  @key "library:shelf_filters"

  @sorts [:recently_added, :title, :rating, :runtime]

  @doc """
  The stored choice, or the resting one.

  Resting is *nothing selected, newest first* — not board 145's preselection,
  which is an illustration of the sheet in use. A sheet that opened already
  filtered would hide part of the reader's own library the first time they
  touched it.

      iex> Kati.Library.ShelfFilters.resting()
      %{sort: :recently_added, direction: :desc, genres: [], decade: nil}
  """
  @spec resting() :: map()
  def resting, do: %{sort: :recently_added, direction: :desc, genres: [], decade: nil}

  @doc "The choice this device has stored, falling back to `resting/0`."
  @spec current() :: map()
  def current do
    case Mob.State.get(@key) do
      %{sort: sort, direction: direction, genres: genres} = stored
      when sort in @sorts and direction in [:asc, :desc] and is_list(genres) ->
        %{sort: sort, direction: direction, genres: genres, decade: Map.get(stored, :decade)}

      _absent ->
        resting()
    end
  rescue
    # `Mob.State` is DETS and raises when its table is not open — a bare
    # `mix run`, a test that has not started the app. A view preference is not
    # worth a crash.
    _error -> resting()
  catch
    # And it is a named GenServer, so a call to it EXITS rather than raising
    # when the process is not up — which `Kati.Media.SearchDebounce.ask/2`
    # documents at length, having been written without this clause first.
    :exit, _reason -> resting()
  end

  @doc "Store a choice. Answers it back, so a caller can pipe."
  @spec put(map()) :: map()
  def put(choice) do
    Mob.State.put(@key, choice)
    choice
  rescue
    _error -> choice
  catch
    :exit, _reason -> choice
  end

  @doc "Forget the choice, which is what *Reset* does."
  @spec clear() :: :ok
  def clear do
    Mob.State.put(@key, resting())
    :ok
  rescue
    _error -> :ok
  catch
    :exit, _reason -> :ok
  end

  @doc """
  Whether anything is narrowing the shelf.

      iex> Kati.Library.ShelfFilters.narrowed?(Kati.Library.ShelfFilters.resting())
      false

      iex> Kati.Library.ShelfFilters.narrowed?(%{sort: :title, direction: :asc, genres: [], decade: nil})
      true

      iex> Kati.Library.ShelfFilters.narrowed?(%{sort: :recently_added, direction: :desc, genres: ["Drama"], decade: nil})
      true
  """
  @spec narrowed?(map()) :: boolean()
  def narrowed?(choice), do: choice != resting()

  @doc """
  The shelf, sorted and filtered.

  Rows are `Kati.Screens.Library.shaped/4`'s, and the two keys this reads —
  `:genres` and `:rating` — are carried there for this. A row that names no
  genre survives every genre filter being off and is dropped by any that is
  on, which is the same rule screen 07's bars follow: a title with no genres
  takes part in no genre.
  """
  @spec apply([map()], map()) :: [map()]
  def apply(rows, choice) do
    rows
    |> Enum.filter(&genre_match?(&1, choice.genres))
    |> Enum.filter(&decade_match?(&1, Map.get(choice, :decade)))
    |> sort(choice)
  end

  @doc """
  Every decade this shelf holds, newest first, with how many titles are in it.

  Board 145 draws four frozen buckets — 2020s, 2010s, 2000s, Older — and until
  6 September `Kati.Media.CachedTitle` had no year column at all, so none of
  them could be answered. It has one now (see the migration), and these are the
  reader's own decades: a bucket with nothing in it is not offered, and a title
  a provider has not dated takes part in none.

      iex> Kati.Library.ShelfFilters.decades([%{year: 2021}, %{year: 2019}, %{year: 2024}])
      [{2020, 2}, {2010, 1}]

      iex> Kati.Library.ShelfFilters.decades([%{year: nil}])
      []
  """
  @spec decades([map()]) :: [{integer(), non_neg_integer()}]
  def decades(rows) do
    rows
    |> Enum.flat_map(&decade_of/1)
    |> Enum.frequencies()
    |> Enum.sort_by(fn {decade, _n} -> -decade end)
  end

  defp decade_of(%{year: year}) when is_integer(year), do: [div(year, 10) * 10]
  defp decade_of(_undated), do: []

  defp decade_match?(_row, nil), do: true
  defp decade_match?(row, decade), do: decade in decade_of(row)

  @doc """
  Every genre on this shelf, with how many titles carry it, commonest first.

  The chips a device can honestly offer, in place of board 145's four frozen
  ones. An empty list means no title on the shelf names a genre, and the
  Filters group is not drawn at all.
  """
  @spec facets([map()]) :: [{String.t(), non_neg_integer()}]
  def facets(rows) do
    rows
    |> Enum.flat_map(&genres_of/1)
    |> Enum.frequencies()
    |> Enum.sort_by(fn {genre, n} -> {-n, genre} end)
  end

  defp genre_match?(_row, []), do: true

  defp genre_match?(row, wanted) do
    Enum.any?(genres_of(row), &(&1 in wanted))
  end

  defp genres_of(%{genres: genres}) when is_binary(genres) and genres != "" do
    genres |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))
  end

  defp genres_of(_row), do: []

  # `Enum.sort_by/3` with an explicit direction rather than two branches: the
  # key is the same either way and only the comparison flips.
  defp sort(rows, %{sort: :title, direction: direction}),
    do: Enum.sort_by(rows, &String.downcase(&1.title || ""), direction)

  defp sort(rows, %{sort: :rating, direction: direction}),
    do: Enum.sort_by(rows, &(Map.get(&1, :rating) || 0), direction)

  defp sort(rows, %{sort: :runtime, direction: direction}),
    do: Enum.sort_by(rows, &(Map.get(&1, :runtime) || 0), direction)

  # Recently added is the shelf's own order — `:shelf` sorts newest touch first
  # — so `:desc` is the list as it arrived and `:asc` is it reversed. Nothing
  # is re-sorted by a key the row does not carry.
  defp sort(rows, %{direction: :desc}), do: rows
  defp sort(rows, %{direction: :asc}), do: Enum.reverse(rows)

  @doc "The sort keys this module understands, for a screen's chip row."
  @spec sorts() :: [atom()]
  def sorts, do: @sorts
end
