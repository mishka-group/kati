defmodule Kati.Lists.Shelf do
  use Gettext, backend: Kati.Gettext

  @moduledoc """
  What screen 12 draws, out of the store rather than out of a fixture.

  Every number and every row on that page belonged to
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
        # What is in it, as `{kind, id}` — the picker sheet ticks against this,
        # which is board 182's rule that ticks *arrive populated* rather than
        # opening blank and inviting the duplicate the tick exists to prevent.
        members: Enum.map(rows, &Membership.member/1) |> Enum.reject(&is_nil/1),
        seeds:
          rows
          |> Enum.take(3)
          |> Enum.map(fn row ->
            case Membership.member(row) do
              {_kind, id} -> Map.get(posters, id)
              nil -> nil
            end
          end)
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
  def subtitle([]), do: gettext("No lists yet")

  def subtitle(made) do
    n = length(made)
    ranked = Enum.count(made, &(&1.badge == "ranked"))
    # One msgid for every count: Persian does not inflect a noun after a
    # number, so `1 list` is the English grammar's special case rather than the
    # sentence's. English keeps its own singular here and the catalogue carries
    # the plural form for both.
    line = if n == 1, do: "1 list", else: gettext("%{count} lists", count: Kati.Locale.number(n))

    if ranked > 0,
      do: line <> " · " <> Kati.Locale.number(ranked) <> " " <> gettext("ranked"),
      else: line
  end

  @doc """
      iex> Kati.Lists.Shelf.count_label(1)
      "1 title"

      iex> Kati.Lists.Shelf.count_label(0)
      "0 titles"
  """
  @spec count_label(non_neg_integer()) :: String.t()
  def count_label(1), do: "1 title"
  def count_label(n), do: gettext("%{count} titles", count: Kati.Locale.number(n))

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
  the rule exists. Board 331 goes further and gives that row its own empty
  sentence, because *Add to list* is a lie on a shelf you cannot add to.

  ## Why Wishlist and Owned on disc are not here

  Board 333 draws four kept rows in the picker and words the lock as **"Kept by
  Kati"** — the reason a row is not tickable is that a rule fills it. Two rules
  exist: a dropped status fills Abandoned, and a watch carrying a rewatch number
  fills Rewatches. Nothing fills Wishlist or Owned on disc, so locking them with
  that sentence would state a rule that is not there, and drawing them tickable
  is what 182 did and 333 overruled. They come back the day a rule does.
  """
  @spec kept() :: [map()]
  def kept do
    [
      %{
        id: "kept:rewatches",
        icon: "replay",
        title: gettext("Rewatches"),
        count: Kati.Locale.number(rewatches()),
        empty_title: gettext("Nothing rewatched"),
        empty_body:
          gettext(
            "Kati fills this one — log a watch of something you have seen and it lands here."
          )
      },
      %{
        id: "kept:abandoned",
        icon: "do_not_disturb_on",
        title: gettext("Abandoned"),
        count: Kati.Locale.number(abandoned()),
        empty_title: gettext("Nothing abandoned"),
        empty_body: gettext("Kati fills this one — drop a show and it lands here.")
      }
    ]
  end

  @doc """
  Whether an id names a kept list rather than a made one.

      iex> Kati.Lists.Shelf.kept?("kept:abandoned")
      true

      iex> Kati.Lists.Shelf.kept?("8971abd5-7a2b-4854-8305-9cd105c32d7b")
      false
  """
  @spec kept?(String.t() | nil) :: boolean()
  def kept?(id) when is_binary(id), do: String.starts_with?(id, "kept:")
  def kept?(_none), do: false

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
  Make a list, or say the name is taken.

  `{:exists, list}` is a different answer from `{:ok, list}` and board 335 is
  why: the old code returned the existing list and wrote nothing, which was
  *indistinguishable from making one*. A reader who thought they had two lists
  called `Rainy Sunday` now learns they have one, and is offered it.

      iex> Kati.Lists.Shelf.create("   ")
      {:error, :nothing_to_save}
  """
  @spec create(String.t()) :: {:ok, term()} | {:exists, term()} | {:error, term()}
  def create(name) do
    trimmed = String.trim(to_string(name))

    if trimmed == "" do
      {:error, :nothing_to_save}
    else
      key = Kati.Import.Job.name_key(trimmed)

      case Kati.Lists.Shelf.named(key) do
        nil -> Ash.create(Listing, %{name: trimmed, name_key: key})
        list -> {:exists, list}
      end
    end
  end

  @doc """
  Rename a list, or say the new name is taken.

  Board 330 ruled rename in — the third thing 181 named as undrawn — and 335
  rules it reuses the index's own field rather than inventing a second naming
  grammar. Renaming to the name it already has is `{:ok, list}` and writes
  nothing, because it is not a collision with itself.
  """
  @spec rename(String.t(), String.t()) :: {:ok, term()} | {:exists, term()} | {:error, term()}
  def rename(list_id, name) do
    trimmed = String.trim(to_string(name))
    key = Kati.Import.Job.name_key(trimmed)

    with false <- trimmed == "",
         {:ok, list} <- Ash.get(Listing, list_id) do
      case Kati.Lists.Shelf.named(key) do
        nil -> Ash.update(list, %{name: trimmed, name_key: key})
        %{id: same} = list when same == list_id -> {:ok, list}
        clash -> {:exists, clash}
      end
    else
      true -> {:error, :nothing_to_save}
      {:error, reason} -> {:error, reason}
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
  Put a film, a series, a book or an album in a list, at the end of it.

  The member arrives as `{kind, id}` — `Kati.Lists.Membership.member/1`'s own
  shape, and `column/1` maps it onto the column the store holds it in. Already
  there is `:ok` and writes nothing: the partial unique index per kind is what
  says a title is in a list once, and adding it twice is how somebody checks.
  """
  @spec add(term(), {atom(), String.t()} | String.t()) :: :ok | {:error, term()}
  def add(list, id) when is_binary(id), do: add(list, {:tracked_title, id})

  def add(list, {kind, id}) do
    column = Membership.column(kind)

    existing =
      Membership
      |> Ash.Query.for_read(:for_list, %{list_id: list.id})
      |> Ash.read!()

    if Enum.any?(existing, &(Map.get(&1, column) == id)) do
      :ok
    else
      attrs = %{list_id: list.id, position: length(existing)} |> Map.put(column, id)

      case Ash.create(Membership, attrs) do
        {:ok, _row} -> :ok
        {:error, reason} -> {:error, reason}
      end
    end
  rescue
    error -> {:error, error}
  end

  @doc """
  Take one member out of a list.

  **Answers the failure.** It used to `rescue _error -> :ok`, and board 335 is
  the reason that had to stop: *"Nothing moves until the write returns. The
  optimistic tick, the popped page and the silent reappearing row all come from
  acting first."* A remove that fails now says so, and the row never left.
  """
  @spec remove(String.t(), {atom(), String.t()} | String.t()) :: :ok | {:error, term()}
  def remove(list_id, id) when is_binary(id), do: remove(list_id, {:tracked_title, id})

  def remove(list_id, {kind, id}) do
    column = Membership.column(kind)

    Membership
    |> Ash.Query.for_read(:for_list, %{list_id: list_id})
    |> Ash.read!()
    |> Enum.filter(&(Map.get(&1, column) == id))
    |> Enum.reduce(:ok, fn row, acc ->
      case Ash.destroy(row) do
        :ok -> acc
        {:ok, _destroyed} -> acc
        {:error, reason} -> {:error, reason}
      end
    end)
  rescue
    error -> {:error, error}
  end

  @doc """
  Delete a list and everything in it.

  Answers the failure for board 335's reason, the same as `remove/2`: the page
  does not pop until this returns `:ok`, so a reader whose delete failed is
  still on the list they tried to delete rather than back on an index that
  still shows it.

  A list that is already gone is `:ok` — the reader asked for it to not be
  there, and it is not there.
  """
  @spec delete(String.t()) :: :ok | {:error, term()}
  def delete(list_id) do
    case Ash.get(Listing, list_id) do
      {:ok, list} ->
        case Ash.destroy(list) do
          :ok -> :ok
          {:ok, _destroyed} -> :ok
          {:error, reason} -> {:error, reason}
        end

      _gone ->
        :ok
    end
  rescue
    error -> {:error, error}
  end

  @doc """
  One list, and what is in it, shaped the way screen 12's rows are.

  `nil` for a list that is not there — a list deleted on another device is not
  the same fact as an empty one, which board 331 draws apart and which is
  `Kati.Screens.Film.tracked_film/1`'s rule for the identical question.
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

  # A kept list is derived, not stored — `Kati.Lists.Shelf.kept/0`'s two rules
  # read back as rows. Board 331 draws its empty state apart from a made list's
  # for the reason its own annotation gives: *Add to list* is a lie on a shelf
  # you cannot add to, so the sentence names what fills it instead.
  def detail("kept:" <> which) do
    row = Enum.find(kept(), &(&1.id == "kept:" <> which))

    row &&
      %{
        id: row.id,
        title: row.title,
        badge: nil,
        ranked?: false,
        shared?: false,
        kept?: true,
        empty_title: row.empty_title,
        empty_body: row.empty_body,
        count: Kati.Lists.Shelf.count_label(length(kept_titles(which))) <> " · KEPT BY KATI",
        titles: kept_titles(which)
      }
  rescue
    _error -> nil
  end

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
          kept?: false,
          count: Kati.Lists.Shelf.count_label(length(rows)),
          titles: Kati.Lists.Shelf.titles_for(rows)
        }

      _gone ->
        nil
    end
  rescue
    _error -> nil
  end

  # The rows behind a kept list, in the shape `titles_for/1` produces so the two
  # draw through one recipe. Both read the durable rows and neither writes.
  defp kept_titles("abandoned") do
    cached = CachedTitle |> Ash.read!() |> Map.new(&{{&1.source, &1.source_id}, &1})

    TrackedTitle
    |> Ash.read!()
    |> Enum.filter(&(&1.status == :dropped and not &1.archived))
    |> Enum.with_index()
    |> Enum.map(fn {mine, i} -> title_row(mine, cached, i) end)
    |> Enum.reject(&is_nil/1)
  end

  defp kept_titles("rewatches") do
    cached = CachedTitle |> Ash.read!() |> Map.new(&{{&1.source, &1.source_id}, &1})
    tracked = TrackedTitle |> Ash.read!() |> Map.new(&{&1.id, &1})

    Kati.Media.Watch
    |> Ash.read!()
    |> Enum.filter(&(is_integer(&1.rewatch_number) and &1.rewatch_number > 1))
    |> Enum.map(& &1.tracked_title_id)
    |> Enum.uniq()
    |> Enum.with_index()
    |> Enum.map(fn {id, i} -> title_row(Map.get(tracked, id), cached, i) end)
    |> Enum.reject(&is_nil/1)
  end

  defp kept_titles(_unknown), do: []

  @doc """
  The rows of a list, whatever kinds they are.

  Board 332's claim in code: one 38x54 slot, three fills, three titles on one
  baseline. `sub` is the second line the board words per kind — `SERIES · 2024`,
  `BOOK · INES KARVEL`, `ALBUM · KELL OSTRAND` — and `art` says which shape
  fills the slot, so a square is letterboxed rather than cropped.

  A member whose row has gone is dropped rather than drawn as a hole: the
  cascade removes memberships with their subject, so this only happens to a
  file restored from a backup written before the cascade existed.
  """
  @spec titles_for([term()]) :: [map()]
  def titles_for(rows) do
    tracked = TrackedTitle |> Ash.read!() |> Map.new(&{&1.id, &1})
    cached = CachedTitle |> Ash.read!() |> Map.new(&{{&1.source, &1.source_id}, &1})
    books = Kati.Books.Book |> Ash.read!() |> Map.new(&{&1.id, &1})
    albums = Kati.Music.Album |> Ash.read!() |> Map.new(&{&1.id, &1})
    artists = Kati.Music.Artist |> Ash.read!() |> Map.new(&{&1.id, &1.name})

    rows
    |> Enum.map(fn row ->
      case Membership.member(row) do
        {:tracked_title, id} -> title_row(Map.get(tracked, id), cached, row.position)
        {:book, id} -> book_row(Map.get(books, id), row.position)
        {:album, id} -> album_row(Map.get(albums, id), artists, row.position)
        nil -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp title_row(nil, _cached, _position), do: nil

  defp title_row(mine, cached, position) do
    cache = Map.get(cached, {mine.source, mine.source_id})
    kind = if Kati.Media.Anime.film?(mine.kind, cache), do: :film, else: :series

    %{
      id: mine.id,
      tracked_id: mine.id,
      member: {:tracked_title, mine.id},
      title: (cache && cache.title) || "Untitled",
      titled?: not is_nil(cache && cache.title),
      seed: cache && cache.poster_path,
      art: :poster,
      kind: kind,
      sub: Kati.Lists.Shelf.sub_line(kind, cache && cache.first_release_year),
      position: position
    }
  end

  defp book_row(nil, _position), do: nil

  defp book_row(book, position) do
    %{
      id: book.id,
      tracked_id: nil,
      member: {:book, book.id},
      title: book.title,
      titled?: true,
      seed: book.cover_seed,
      art: :cover,
      kind: :book,
      sub: Kati.Lists.Shelf.sub_line(:book, book.author),
      position: position
    }
  end

  defp album_row(nil, _artists, _position), do: nil

  defp album_row(album, artists, position) do
    %{
      id: album.id,
      tracked_id: nil,
      member: {:album, album.id},
      title: album.title,
      titled?: true,
      seed: album.art_seed,
      # The square. Board 332: 38x38 centred in the 38x54 slot, with 8px of the
      # slot's own colour showing above and below — "a square reads as art in a
      # slot rather than art with a frame".
      art: :square,
      kind: :album,
      sub: Kati.Lists.Shelf.sub_line(:album, Map.get(artists, album.artist_id)),
      position: position
    }
  end

  @doc """
  A row's second line, in the words board 332 gives each kind.

      iex> Kati.Lists.Shelf.sub_line(:series, 2024)
      "SERIES · 2024"

      iex> Kati.Lists.Shelf.sub_line(:book, "Ines Karvel")
      "BOOK · INES KARVEL"

  Board 331: a title with no metadata still names its kind, because the kind is
  a thing the store knows even when the cache is gone.

      iex> Kati.Lists.Shelf.sub_line(:film, nil)
      "FILM · NO DETAILS YET"
  """
  @spec sub_line(atom(), term()) :: String.t()
  def sub_line(kind, nil),
    do: Kati.Lists.Shelf.kind_word(kind) <> " · " <> gettext("NO DETAILS YET")

  def sub_line(kind, fact),
    do: Kati.Lists.Shelf.kind_word(kind) <> " · " <> Kati.Lists.Shelf.fact_word(fact)

  @doc """
  A kind as the word this line prints.

      iex> Kati.Lists.Shelf.kind_word(:series)
      "SERIES"

  Upper case is a LATIN effect — the Arabic script has no case — so the Persian
  catalogue answers with the word as it is written and only the Latin side is
  raised. `Kati.Screens.AddByHand.labelled/4` carries the long version of the
  same argument for its eyebrow labels.
  """
  @spec kind_word(atom()) :: String.t()
  def kind_word(:book), do: gettext("BOOK")
  def kind_word(:album), do: gettext("ALBUM")
  def kind_word(:series), do: gettext("SERIES")
  def kind_word(_film), do: gettext("FILM")

  @doc false
  @spec fact_word(term()) :: String.t()
  def fact_word(fact) do
    text = to_string(fact)
    Kati.Locale.pick(String.upcase(text), Kati.Locale.number(text))
  end

  # Every member's artwork seed, keyed the way a membership names it.
  @doc false
  @spec posters() :: %{String.t() => String.t() | nil}
  def posters do
    cached = CachedTitle |> Ash.read!() |> Map.new(&{{&1.source, &1.source_id}, &1.poster_path})

    titles =
      TrackedTitle
      |> Ash.read!()
      |> Map.new(&{&1.id, Map.get(cached, {&1.source, &1.source_id})})

    books = Kati.Books.Book |> Ash.read!() |> Map.new(&{&1.id, &1.cover_seed})
    albums = Kati.Music.Album |> Ash.read!() |> Map.new(&{&1.id, &1.art_seed})

    titles |> Map.merge(books) |> Map.merge(albums)
  rescue
    _error -> %{}
  end
end
