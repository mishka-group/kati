defmodule Kati.Health.SleepNight do
  @moduledoc """
  One night's sleep, typed by hand.

  Screen 42's Sleep tile was an outline from the day it was drawn: the design
  promised a section and Kati had nothing behind it, so the tile said *Not set
  up* and pressing it opened an explanation. This is the row that makes the
  tile's line a fact — the minutes slept, on the night's own date, in the
  smallest unit a person actually types.

  ## Minutes, and the night's morning

  `minutes` rather than a duration pair, and `night_on` is the morning the
  night ended: *last night* is a night that ended today, which is the question
  the tile asks and the only one a one-row-per-night table can answer without
  a bedtime.
  """

  use Ash.Resource, domain: Kati.Health, data_layer: AshSqlite.DataLayer
  use Gettext, backend: Kati.Gettext

  sqlite do
    table "sleep_nights"
    repo Kati.Repo

    custom_indexes do
      index [:night_on]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :minutes, :integer, allow_nil?: false, public?: true, constraints: [min: 1]

    attribute :night_on, :date, allow_nil?: false, public?: true
    attribute :note, :string, public?: true

    timestamps()
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]

    read :recent do
      description "Every night, newest first."
      prepare build(sort: [night_on: :desc, inserted_at: :desc])
    end
  end

  @doc """
  Minutes as a person reads them: `7h 12m`, or `48m` under the hour.

  Both figures go through `Kati.Locale.number/1`, and the units are msgids:
  a Persian reader is shown ۷ ساعت و ۱۲ دقیقه, not `7h 12m` in the middle of a
  Persian tile — the same Latin-text defect #103 keeps finding on this board.

      iex> Kati.Health.SleepNight.label(432)
      "7h 12m"
      iex> Kati.Health.SleepNight.label(48)
      "48m"
  """
  @spec label(non_neg_integer()) :: String.t()
  def label(minutes) when minutes >= 60 do
    gettext("%{hours}h %{minutes}m",
      hours: Kati.Locale.number(div(minutes, 60)),
      minutes: Kati.Locale.number(rem(minutes, 60))
    )
  end

  def label(minutes), do: gettext("%{minutes}m", minutes: Kati.Locale.number(minutes))
end
