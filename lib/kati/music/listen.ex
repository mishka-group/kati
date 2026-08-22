defmodule Kati.Music.Listen do
  @moduledoc """
  One sitting with an album.

  Screen 73's sibling of `Kati.Books.ReadingSession`, and shaped the same way
  for the same reasons: append-only, dated by day rather than by instant, and
  written by exactly one screen.

  ## Where it differs, and the difference is the design's

  Screen 73's caption settles it: *music gets no "finished" shortcut — an album
  has no equivalent of closing a book.* So there is no status to move and no
  second commit. A listen is only ever a listen.

  The other difference is `tracks`: a book session is a span of pages and this
  is a count of tracks, because `Whole album` is the default choice and a whole
  album is a number rather than a range. `Selected tracks` writes the same count
  and additionally increments the tracks it names — which is the only place in
  this domain where one write touches two tables, and is why `Kati.Screens.LogListen`
  owns the order.
  """

  use Ash.Resource, domain: Kati.Music, data_layer: AshSqlite.DataLayer

  sqlite do
    table "music_listens"
    repo Kati.Repo

    custom_indexes do
      # Screen 74's `41 plays · 4 this month`, and its 13-week pixel field.
      index [:album_id, :listened_on]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :listened_on, :date, allow_nil?: false, public?: true
    attribute :started_at, :utc_datetime, public?: true

    attribute :tracks, :integer,
      allow_nil?: false,
      default: 0,
      public?: true,
      constraints: [min: 0]

    attribute :minutes, :integer, public?: true, constraints: [min: 0]

    attribute :scope, :atom,
      allow_nil?: false,
      default: :album,
      public?: true,
      constraints: [one_of: [:album, :selected, :minutes]]

    attribute :source, :atom,
      allow_nil?: false,
      default: :manual,
      public?: true,
      constraints: [one_of: [:manual, :scrobble, :import]]

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
      description "One album's listens, newest first."
      argument :album_id, :uuid, allow_nil?: false
      filter expr(album_id == ^arg(:album_id))
      prepare build(sort: [listened_on: :desc, inserted_at: :desc])
    end
  end

  @doc """
  How many of these listens fall in the calendar month `today` is in.

  Screen 74's `4 this month`, and screen 73's `4th time this month`. Calendar
  month rather than a rolling thirty days, because the phrase says *this month*
  and a rolling window would make the figure drop on the first without anything
  having changed.
  """
  @spec this_month([t()], Date.t()) :: non_neg_integer()
  def this_month(listens, %Date{year: year, month: month}) do
    Enum.count(listens, fn %__MODULE__{listened_on: on} ->
      on.year == year and on.month == month
    end)
  end

  @doc """
  Total listening time across these sittings, in minutes.

  Skips the untimed ones rather than treating them as zero, which is the same
  distinction `Kati.Books.ReadingSession.pace/1` makes: a sitting nobody timed
  is not a sitting of no length.
  """
  @spec total_minutes([t()]) :: non_neg_integer()
  def total_minutes(listens) do
    listens |> Enum.map(& &1.minutes) |> Enum.reject(&is_nil/1) |> Enum.sum()
  end

  @doc "Screen 77's `61h` total, from minutes."
  @spec hours_label(non_neg_integer()) :: String.t()
  def hours_label(minutes), do: "#{div(minutes, 60)}h"

  @type t :: %__MODULE__{}
end
