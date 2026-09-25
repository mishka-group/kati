defmodule Kati.Books.FollowedAuthor do
  @moduledoc """
  An author whose next book you want to hear about.

  Board 307 is the whole reason this exists. It gives screen 25 a **New books**
  switch subtitled *Authors you follow*, and it gives screen 66 the row that
  fills it: *"Follow Ines Karvel — new row on the book page, the only new ink
  66 needs."* The switch was a promise about a noun the app did not have.

  ## Why a row per name and not a column on the book

  `Kati.Music.Artist` can carry `following` as a column because an artist is a
  row: screen 77 is a page about one. An author is a **string on each of their
  books**, so the same column here would be per copy, and two books by the same
  author could disagree about whether you follow them. Following is about the
  person.

  `name_key` is `Kati.Import.Job.name_key/1`'s trimmed, case-folded form,
  stored so SQLite can hold the unique index on it — `Kati.Lists.List`'s
  arrangement, for its reason: `ines karvel` and `Ines Karvel ` are one person
  followed twice.

  ## What follows from following, today

  A row here, and screen 66's switch reading back on. Nothing yet **produces**
  a new-book announcement: Open Library is the only book source in view and
  Kati asks it about a title, never about a person's next one. So this is the
  half of board 307 that can be true — the reader's own statement, kept and
  backed up — and the shelf that reads it is written down as missing
  rather than faked with a sample row on screen 05.
  """
  use Ash.Resource, domain: Kati.Books, data_layer: AshSqlite.DataLayer

  require Ash.Query

  sqlite do
    table "followed_authors"
    repo Kati.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string, allow_nil?: false, public?: true

    # The key `name` is compared on — trimmed and case-folded.
    attribute :name_key, :string, allow_nil?: false, public?: true

    timestamps()
  end

  identities do
    identity :unique_name, [:name_key]
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]
    default_accept :*

    read :alphabetical do
      description "Everyone followed, by name — the only order a list of people has."
      prepare build(sort: [name_key: :asc])
    end
  end

  @doc """
  Is this author followed?

  `false` for a blank or missing name, without asking the store: a book with no
  author is not a book by somebody you have not followed, and screen 66 draws
  no row for it at all.

      iex> Kati.Books.FollowedAuthor.following?(nil)
      false

      iex> Kati.Books.FollowedAuthor.following?("   ")
      false
  """
  @spec following?(String.t() | nil) :: boolean()
  def following?(name) do
    case key(name) do
      nil -> false
      key -> row(key) != nil
    end
  end

  @doc """
  Follow an author. Following someone already followed is `{:ok, row}` and
  writes nothing — it is not a collision with itself, which is
  `Kati.Lists.Shelf.rename/2`'s rule for the same question.
  """
  @spec follow(String.t() | nil) :: {:ok, term()} | {:error, term()}
  def follow(name) do
    case key(name) do
      nil ->
        {:error, :no_author}

      key ->
        case row(key) do
          nil -> Ash.create(__MODULE__, %{name: String.trim(name), name_key: key})
          existing -> {:ok, existing}
        end
    end
  end

  @doc """
  Unfollow. Unfollowing someone not followed is `:ok`, because the state the
  caller asked for is the state that holds.
  """
  @spec unfollow(String.t() | nil) :: :ok | {:error, term()}
  def unfollow(name) do
    with key when is_binary(key) <- key(name),
         %__MODULE__{} = existing <- row(key) do
      case Ash.destroy(existing) do
        :ok -> :ok
        {:ok, _destroyed} -> :ok
        {:error, reason} -> {:error, reason}
      end
    else
      _nothing -> :ok
    end
  end

  @doc "Everyone followed, by name. `[]` on an empty or unreachable store."
  @spec names() :: [String.t()]
  def names do
    __MODULE__
    |> Ash.Query.for_read(:alphabetical)
    |> Ash.read!()
    |> Enum.map(& &1.name)
  rescue
    _error -> []
  end

  @doc "How many authors are followed. `0` on an empty or unreachable store."
  @spec count() :: non_neg_integer()
  def count, do: length(names())

  @doc """
  The stored key for a name, or `nil` when there is no name to key.

      iex> Kati.Books.FollowedAuthor.key("  Ines Karvel ")
      "ines karvel"

      iex> Kati.Books.FollowedAuthor.key("")
      nil
  """
  @spec key(String.t() | nil) :: String.t() | nil
  def key(name) when is_binary(name) do
    case Kati.Import.Job.name_key(name) do
      "" -> nil
      key -> key
    end
  end

  def key(_absent), do: nil

  defp row(key) do
    __MODULE__ |> Ash.Query.filter(name_key == ^key) |> Ash.read!() |> Elixir.List.first()
  rescue
    _error -> nil
  end

  @type t :: %__MODULE__{}
end
