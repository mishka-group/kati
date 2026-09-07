defmodule Kati.Lists.Shelf do
  @moduledoc """
  What screen 12 draws, out of the store rather than out of a fixture.

  MOVIES-AND-TV.md #106. Every number and every row on that page belonged to
  somebody else: three lists nobody made, four *Kept automatically* counts
  frozen at the drawing's, and a `+` that invented a row the moment it was
  pressed and lost it on the way back.

  Two of the kept rows are one query each and stay here beside the made lists,
  because the page reads as one thing: `Rewatches` is a `Kati.Media.Watch`
  carrying a `rewatch_number` and `Abandoned` is `status: :dropped`. The two
  the drawing also listed — `Wishlist` and `Owned on disc` — are assertions a
  reader makes and no column holds, and are not drawn.

  ## The fan is the list's own first three posters

  Board 12 draws three overlapped tiles per made list. They are the first three
  memberships' `Kati.Media.CachedTitle.poster_path` — in the list's own order,
  so a ranked list fans its top three — and an evicted cache costs a tile and
  not the row.
  """
  require Ash.Query

  alias Kati.Lists.List, as: Listing
  alias Kati.Lists.Membership
  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle

  @doc """
  The page: made lists, their counts and fans, and the two kept rows.

  Falls back to nothing rather than to the drawing: a reader with no lists sees
  the empty card, which is what `Kati.Screens.Lists` draws for `made: []`. The
  fixture is gone from the read path entirely — it is what the BOARD is, and
  `Kati.ScreenDesignLiteralTest` still compares against it.
  """
  @spec page() :: map()
  def page do
    made = Kati.Lists.Shelf.made()

    %{
      subtitle: Kati.Lists.Shelf.subtitle(made),
      made: made,
      kept: Kati.Lists.Shelf.kept()
    }
  end

  @doc """
  Every hand-made list, newest first, with its count and its fan.

  One read of the memberships and one of the cache, joined here — a query per
  list would be a query per row on a page whose whole point is that there may
  be many.
  """
  @spec made() :: [map()]
  def made do
    lists = Listing |> Ash.Query.for_read(:newest_first) |> Ash.read!()

    by_list = Membership |> Ash.read!() |> Enum.group_by(& &1.list_id)
    posters = Kati.Lists.Shelf.posters()

    Enum.map(lists, fn list ->
      rows = by_list |> Map.get(list.id, []) |> Enum.sort_by(& &1.position)

      %{
        id: list.id,
        title: list.name,
        count: Kati.Lists.Shelf.count_label(length(rows)),
        badge: Kati.Lists.Shelf.badge(list),
        seeds:
          rows
          |> Enum.take(3)
          |> Enum.map(&Map.get(posters, &1.tracked_title_id))
          |> Enum.reject(&is_nil/1)
      }
    end)
  rescue
    _error -> []
  end

  @doc """
  `7 lists · 2 ranked`, counted — the board's own line.

      iex> Kati.Lists.Shelf.subtitle([])
      "No lists yet"

      iex> Kati.Lists.Shelf.subtitle([%{badge: "ranked"}, %{badge: nil}])
      "2 lists · 1 ranked"

      iex> Kati.Lists.Shelf.subtitle([%{badge: nil}])
      "1 list"
  """
  @spec subtitle([map()]) :: String.t()
  def subtitle([]), do: "No lists yet"

  def subtitle(made) do
    n = length(made)
    ranked = Enum.count(made, &(&1.badge == "ranked"))
    line = "#{n} #{if n == 1, do: "list", else: "lists"}"

    if ranked > 0, do: line <> " · #{ranked} ranked", else: line
  end

  @doc """
      iex> Kati.Lists.Shelf.count_label(1)
      "1 title"

      iex> Kati.Lists.Shelf.count_label(0)
      "0 titles"
  """
  @spec count_label(non_neg_integer()) :: String.t()
  def count_label(1), do: "1 title"
  def count_label(n), do: "#{n} titles"

  @doc """
      iex> Kati.Lists.Shelf.badge(%{ranked: true, shared: false})
      "ranked"

      iex> Kati.Lists.Shelf.badge(%{ranked: false, shared: true})
      "shared"

      iex> Kati.Lists.Shelf.badge(%{ranked: false, shared: false})
      nil
  """
  @spec badge(map()) :: String.t() | nil
  def badge(%{ranked: true}), do: "ranked"
  def badge(%{shared: true}), do: "shared"
  def badge(_plain), do: nil

  @doc """
  The two kept lists the store can answer, with the reader's own counts.

  A count of nothing is still drawn: `Abandoned · 0` is a true answer about a
  shelf nobody has dropped anything from, and the row is what tells a reader
  the rule exists.
  """
  @spec kept() :: [map()]
  def kept do
    [
      %{icon: "replay", title: "Rewatches", count: Integer.to_string(rewatches())},
      %{icon: "do_not_disturb_on", title: "Abandoned", count: Integer.to_string(abandoned())}
    ]
  end

  @doc "How many watches the reader has marked as a rewatch."
  @spec rewatches() :: non_neg_integer()
  def rewatches do
    Kati.Media.Watch
    |> Ash.read!()
    |> Enum.count(&(is_integer(&1.rewatch_number) and &1.rewatch_number > 1))
  rescue
    _error -> 0
  end

  @doc "How many titles the reader has dropped."
  @spec abandoned() :: non_neg_integer()
  def abandoned do
    TrackedTitle
    |> Ash.read!()
    |> Enum.count(&(&1.status == :dropped and not &1.archived))
  rescue
    _error -> 0
  end

  @doc """
  Make a list, or answer the one already called that.

  `{:ok, list}` either way — re-typing a name you already have is how somebody
  checks whether they already have it, which is `Kati.Screens.AddTitle.cache/1`'s
  reasoning, and making a second `Rainy Sunday` is not what they asked for.
  """
  @spec create(String.t()) :: {:ok, term()} | {:error, term()}
  def create(name) do
    trimmed = String.trim(to_string(name))

    if trimmed == "" do
      {:error, :nothing_to_save}
    else
      key = Kati.Import.Job.name_key(trimmed)

      case Kati.Lists.Shelf.named(key) do
        nil -> Ash.create(Listing, %{name: trimmed, name_key: key})
        list -> {:ok, list}
      end
    end
  end

  @doc false
  @spec named(String.t()) :: term() | nil
  def named(key) do
    Listing |> Ash.Query.filter(name_key == ^key) |> Ash.read!() |> Elixir.List.first()
  rescue
    _error -> nil
  end

  @doc """
  Put a title in a list, at the end of it.

  Already there is `:ok` and writes nothing: the identity on
  `{list_id, tracked_title_id}` is what says a title is in a list once, and
  adding it twice is how somebody checks.
  """
  @spec add(term(), String.t()) :: :ok | {:error, term()}
  def add(list, tracked_title_id) do
    existing =
      Membership
      |> Ash.Query.for_read(:for_list, %{list_id: list.id})
      |> Ash.read!()

    if Enum.any?(existing, &(&1.tracked_title_id == tracked_title_id)) do
      :ok
    else
      case Ash.create(Membership, %{
             list_id: list.id,
             tracked_title_id: tracked_title_id,
             position: length(existing)
           }) do
        {:ok, _row} -> :ok
        {:error, reason} -> {:error, reason}
      end
    end
  rescue
    error -> {:error, error}
  end

  @doc "Take a title out of a list."
  @spec remove(String.t(), String.t()) :: :ok
  def remove(list_id, tracked_title_id) do
    Membership
    |> Ash.Query.for_read(:for_list, %{list_id: list_id})
    |> Ash.read!()
    |> Enum.filter(&(&1.tracked_title_id == tracked_title_id))
    |> Enum.each(&Ash.destroy!/1)

    :ok
  rescue
    _error -> :ok
  end

  @doc "Delete a list and everything in it."
  @spec delete(String.t()) :: :ok
  def delete(list_id) do
    case Ash.get(Listing, list_id) do
      {:ok, list} -> Ash.destroy!(list)
      _gone -> :ok
    end

    :ok
  rescue
    _error -> :ok
  end

  @doc """
  One list, and the titles in it, shaped the way screen 12's rows are.

  `nil` for a list that is not there — a list deleted on another device is not
  the same fact as an empty one, which is `Kati.Screens.Film.tracked_film/1`'s
  rule for the identical question.
  """
  @spec detail(String.t() | nil) :: map() | nil
  # A push naming no list answers NOTHING, and deliberately not the newest one.
  # Screen 08 opens the newest film on a bare push because a film screen with
  # no film is not a state; a list screen with no list is — the reader can have
  # made none. And `Kati.ScreenWriteTargetTest` names the cost of the other
  # answer: a page that picks its own subject on a bare mount is a page whose
  # `Remove` writes to a row the reader never chose. The gallery's row shows
  # the empty card, which is the honest thing for a door that names nothing.
  def detail(nil), do: nil

  def detail(list_id) do
    case Ash.get(Listing, list_id) do
      {:ok, list} ->
        rows =
          Membership
          |> Ash.Query.for_read(:for_list, %{list_id: list.id})
          |> Ash.read!()

        %{
          id: list.id,
          title: list.name,
          badge: Kati.Lists.Shelf.badge(list),
          ranked?: list.ranked,
          shared?: list.shared,
          count: Kati.Lists.Shelf.count_label(length(rows)),
          titles: Kati.Lists.Shelf.titles_for(rows)
        }

      _gone ->
        nil
    end
  rescue
    _error -> nil
  end

  @doc false
  @spec titles_for([term()]) :: [map()]
  def titles_for(rows) do
    tracked = TrackedTitle |> Ash.read!() |> Map.new(&{&1.id, &1})
    cached = CachedTitle |> Ash.read!() |> Map.new(&{{&1.source, &1.source_id}, &1})

    for row <- rows, mine = Map.get(tracked, row.tracked_title_id), mine != nil do
      cache = Map.get(cached, {mine.source, mine.source_id})

      %{
        id: mine.id,
        tracked_id: mine.id,
        title: (cache && cache.title) || "Untitled",
        seed: cache && cache.poster_path,
        kind: if(Kati.Media.Anime.film?(mine.kind, cache), do: :film, else: :series),
        position: row.position
      }
    end
  end

  # Every tracked title's poster, keyed by the id a membership names it with.
  @doc false
  @spec posters() :: %{String.t() => String.t() | nil}
  def posters do
    cached = CachedTitle |> Ash.read!() |> Map.new(&{{&1.source, &1.source_id}, &1.poster_path})

    TrackedTitle
    |> Ash.read!()
    |> Map.new(&{&1.id, Map.get(cached, {&1.source, &1.source_id})})
  rescue
    _error -> %{}
  end
end
