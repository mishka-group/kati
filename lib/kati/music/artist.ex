defmodule Kati.Music.Artist do
  @moduledoc """
  A person or group, and whether you are following them.

  ## `following` is one switch with two readers, and deliberately not three

  Screen 77's caption is precise about this: the toggle is *the single source of
  truth for 21's new-releases band and, of 25's six alert types, drives `People
  you follow` only — premieres stay a separate opt-in so following an artist
  cannot silently turn on push.*

  That last clause is the whole design of this column. Following somebody is a
  statement about a shelf; a premiere alert is a statement about a notification.
  Wiring one to the other would mean a tap on a `Following` toggle quietly
  arming push, which is the behaviour every app that does it gets complained
  about for. So `following` is read by the shelf and by one alert type, and
  `Kati.Notifications.Plan` owns the rest.

  ## `role` and `country` are free text

  MusicBrainz's type vocabulary is large, versioned and not ours, and screen
  77 prints one line — `Composer · Iceland`. An enum here would be a guess at a
  vocabulary somebody else maintains, and the line degrades cleanly with either
  half missing.
  """

  use Ash.Resource, domain: Kati.Music, data_layer: AshSqlite.DataLayer

  sqlite do
    table "music_artists"
    repo Kati.Repo

    custom_indexes do
      # Screen 21's new-releases band and screen 25's `People you follow`.
      index [:following]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string, allow_nil?: false, public?: true
    attribute :role, :string, public?: true
    attribute :country, :string, public?: true

    attribute :source, :atom,
      allow_nil?: false,
      default: :manual,
      public?: true,
      constraints: [one_of: [:manual, :musicbrainz, :import]]

    attribute :source_id, :string, public?: true

    # The photograph, as a picsum seed on the fallback and a cached path on a
    # real artist. Same treatment as `Kati.Books.Book.cover_seed`.
    attribute :photo_seed, :string, public?: true

    attribute :following, :boolean, allow_nil?: false, default: false, public?: true

    # Screen 77's `2024 · First heard`. A date and not a timestamp: the fact is
    # which year you met them, and an hour would be precision nobody asked for.
    attribute :first_heard_on, :date, public?: true

    timestamps()
  end

  relationships do
    has_many :albums, Kati.Music.Album do
      destination_attribute :artist_id
      public? true
    end
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]

    read :followed do
      description "Artists you follow — screen 21's new-releases band."
      filter expr(following == true)
      prepare build(sort: [name: :asc])
    end
  end

  @doc """
  Screen 77's subtitle: `Composer · Iceland`, or as much of it as is known.

  `nil` when neither half is, so the screen draws no line rather than an empty
  one — the same rule every degrading meta line in this app follows.
  """
  @spec subtitle(t()) :: String.t() | nil
  def subtitle(%__MODULE__{role: role, country: country}) do
    case Enum.reject([role, country], &(is_nil(&1) or &1 == "")) do
      [] -> nil
      parts -> Enum.join(parts, " · ")
    end
  end

  @type t :: %__MODULE__{}
end
