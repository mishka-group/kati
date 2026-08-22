defmodule Kati.Music.Track do
  @moduledoc """
  One track: its place in the running order, how long it is, how often it played.

  ## `plays` is a column and not a count of listens

  A `Kati.Music.Listen` says *eleven tracks, forty-seven minutes* and does not
  say which eleven. That is deliberate — screen 73 offers `Whole album` as its
  first and default choice, and demanding a track breakdown for a whole-album
  play would be asking the user to enumerate something they did not do.

  So per-track counts come from two places that are both real: `Selected
  tracks` on screen 73, and a scrobble import, which supplies counts with no
  sittings behind them at all. Neither can be reconstructed from the other,
  which is why this is stored.

  ## `played_today` is derived, and only screen 74 uses it

  The dot on screen 74's tracklist marks *a track played today — the only
  recency signal here*, and the drawing's own caption calls it that. It comes
  from `last_played_on`, compared against the device's date, which is why the
  comparison takes today as an argument rather than reading a clock.
  """

  use Ash.Resource, domain: Kati.Music, data_layer: AshSqlite.DataLayer

  sqlite do
    table "music_tracks"
    repo Kati.Repo

    custom_indexes do
      # Screen 74's tracklist, in running order.
      index [:album_id, :position]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :position, :integer, allow_nil?: false, public?: true, constraints: [min: 1]
    attribute :title, :string, allow_nil?: false, public?: true

    # Seconds, because that is what a duration is and `4:12` is a rendering of
    # it. Nullable: a tracklist typed by hand often has names and no timings.
    attribute :seconds, :integer, public?: true, constraints: [min: 0]

    attribute :plays, :integer,
      allow_nil?: false,
      default: 0,
      public?: true,
      constraints: [min: 0]

    attribute :last_played_on, :date, public?: true

    timestamps()
  end

  relationships do
    belongs_to :album, Kati.Music.Album do
      allow_nil? false
      public? true
    end
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]

    read :for_album do
      description "One album's tracklist, in running order."
      argument :album_id, :uuid, allow_nil?: false
      filter expr(album_id == ^arg(:album_id))
      prepare build(sort: [position: :asc])
    end
  end

  @doc """
  `4:12`, or `nil` for a track nobody timed.

  Seconds are zero-padded and minutes are not, which is how a running time is
  written everywhere and is what the drawing shows. An hour-long track rolls
  into minutes rather than growing an hours field: `72:30`, not `1:12:30`,
  because a tracklist column that sometimes has three parts does not align.
  """
  @spec duration(t()) :: String.t() | nil
  def duration(%__MODULE__{seconds: nil}), do: nil

  def duration(%__MODULE__{seconds: seconds}) do
    "#{div(seconds, 60)}:#{String.pad_leading(Integer.to_string(rem(seconds, 60)), 2, "0")}"
  end

  @doc "Whether this track's dot is lit — see the moduledoc."
  @spec played_today?(t(), Date.t()) :: boolean()
  def played_today?(%__MODULE__{last_played_on: %Date{} = on}, %Date{} = today),
    do: Date.compare(on, today) == :eq

  def played_today?(%__MODULE__{}, %Date{}), do: false

  @type t :: %__MODULE__{}
end
