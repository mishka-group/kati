defmodule Kati.Music.Album do
  @moduledoc """
  A release: its art, your rating, your note, and when you first met it.

  ## `art_seed` is nullable and the screen is drawn for that case

  Screen 74's own caption says it: *drawn in its default state: no art, since
  Cover Art Archive coverage is patchy — a paper square carrying the album
  initial and the "Art" placeholder rather than a broken image.* So the
  no-artwork case is the **default** rendering rather than an error path, and
  `initial/1` is what fills it.

  ## Two dates, and neither is derived from the listens

  `first_heard_on` and `last_played_on` are columns. They could be `min` and
  `max` over `Kati.Music.Listen`, and they are not, for the same reason
  `Kati.Books.Book.current_page` is stored: a scrobble import supplies per-album
  dates and no sittings, and #62 is entirely about importing history that has no
  `Listen` rows behind it. Deriving them would report *first heard: yesterday*
  for a record somebody has had since 2011.

  When a `Listen` **is** written, `Kati.Screens.LogListen` moves
  `last_played_on` with it, so the two agree wherever both exist.
  """

  use Ash.Resource, domain: Kati.Music, data_layer: AshSqlite.DataLayer

  sqlite do
    table "music_albums"
    repo Kati.Repo

    custom_indexes do
      # Screen 21's shelf order, and screen 74's referent when nothing names an
      # album: the most recently touched.
      index [:updated_at]
      # Screen 77's `Albums · 4` rail and its plays-by-album chart.
      index [:artist_id, :released_year]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :title, :string, allow_nil?: false, public?: true
    attribute :released_year, :integer, public?: true

    attribute :source, :atom,
      allow_nil?: false,
      default: :manual,
      public?: true,
      constraints: [one_of: [:manual, :musicbrainz, :import]]

    attribute :source_id, :string, public?: true

    # `nil` is the drawn default — see the moduledoc.
    attribute :art_seed, :string, public?: true

    # Halves, as every other rating in this app is stored.
    attribute :rating, :integer, public?: true, constraints: [min: 0, max: 10]

    # Screen 74's cream card. One note per album rather than a resource: unlike
    # a book, which is read over weeks and annotated at pages, an album gets the
    # one thing you thought about it.
    attribute :note, :string, public?: true
    attribute :note_on, :date, public?: true

    attribute :first_heard_on, :date, public?: true
    attribute :last_played_on, :date, public?: true

    timestamps()
  end

  relationships do
    belongs_to :artist, Kati.Music.Artist do
      allow_nil? true
      public? true
    end

    has_many :tracks, Kati.Music.Track do
      destination_attribute :album_id
      public? true
    end

    has_many :listens, Kati.Music.Listen do
      destination_attribute :album_id
      public? true
    end
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]

    read :shelf do
      description "Every album, most recently touched first — screen 21's order."
      prepare build(sort: [updated_at: :desc])
    end

    read :for_artist do
      description "One artist's albums, newest release first — screen 77's rail."
      argument :artist_id, :uuid, allow_nil?: false
      filter expr(artist_id == ^arg(:artist_id))
      prepare build(sort: [released_year: :desc])
    end
  end

  @doc """
  The letter the paper square carries when there is no art.

  The album's own initial, upper-cased, and `?` for a title that starts with
  something that has no case — a number, a bracket, a non-Latin script. Never
  empty: the square is drawn either way and a blank one reads as a failure
  rather than as a choice.
  """
  @spec initial(t()) :: String.t()
  def initial(%__MODULE__{title: title}) when is_binary(title) do
    case String.trim(title) do
      "" -> "?"
      trimmed -> trimmed |> String.first() |> String.upcase()
    end
  end

  def initial(%__MODULE__{}), do: "?"

  @doc """
  Screen 74's header line: `Kell Ostrand · 2025`.

  Takes the artist as an argument rather than reading the relationship, so the
  screen's single read decides how many queries the page makes.
  """
  @spec byline(t(), Kati.Music.Artist.t() | nil) :: String.t() | nil
  def byline(%__MODULE__{released_year: year}, artist) do
    name = artist && artist.name

    case Enum.reject([name, year && Integer.to_string(year)], &is_nil/1) do
      [] -> nil
      parts -> Enum.join(parts, " · ")
    end
  end

  @doc """
  Screen 74's total: the sum of the tracklist's play counts.

  Derived rather than stored — see the domain's moduledoc. An album with no
  tracklist has no total, which is a different thing from zero plays and is why
  this answers `0` only when there are tracks and all of them are unplayed.
  """
  @spec plays([Kati.Music.Track.t()]) :: non_neg_integer()
  def plays(tracks), do: Enum.sum(Enum.map(tracks, & &1.plays))

  @type t :: %__MODULE__{}
end
