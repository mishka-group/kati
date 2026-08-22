defmodule Kati.Health.Reading do
  @moduledoc """
  One weight, on one day, typed by hand.

  ## Grams, and only grams

  Stored in grams because it is the smallest unit any of the three display
  units divides cleanly into: a kilogram is 1000, a pound is 453.59237 and a
  stone is fourteen of those. Storing kilograms as a float and rendering pounds
  would drift in the second decimal place, which is exactly where a weight is
  read.

  ## A series of readings is not a line

  Screen 109's caption settles the chart: *bars, not a line — weight is a
  series of discrete readings, and a line implies measurements between them
  that do not exist.* That is a statement about this resource: there is one row
  per weighing and nothing between them, so `delta/2` compares a reading with
  the one before it and never interpolates.
  """

  use Ash.Resource, domain: Kati.Health, data_layer: AshSqlite.DataLayer

  sqlite do
    table "health_readings"
    repo Kati.Repo

    custom_indexes do
      # Screen 109's list and its chart, both newest first.
      index [:taken_on]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :grams, :integer, allow_nil?: false, public?: true, constraints: [min: 1]

    attribute :taken_on, :date, allow_nil?: false, public?: true
    attribute :taken_at, :utc_datetime, public?: true

    # Screen 111's optional note — *after a run, before breakfast…*. Optional
    # because a weight with no context is still a weight, and a required field
    # is how a log stops being kept.
    attribute :note, :string, public?: true

    timestamps()
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]

    read :recent do
      description "Every reading, newest first."
      prepare build(sort: [taken_on: :desc, inserted_at: :desc])
    end
  end

  @doc """
  A weight in the display unit, as the screen prints it.

  One decimal place for kilograms and pounds; stones print as `12st 0.4` because
  a stone alone is too coarse to read a change in. Never two decimals — a scale
  that reads to 100g does not justify printing 76.04.
  """
  @spec display(integer(), :kg | :lb | :st) :: String.t()
  def display(grams, :lb), do: one_place(grams / 453.59237) <> " lb"

  def display(grams, :st) do
    pounds = grams / 453.59237
    stones = trunc(pounds / 14)
    "#{stones}st #{one_place(pounds - stones * 14)}"
  end

  def display(grams, _kg), do: one_place(grams / 1000) <> " kg"

  @doc "Just the number, for the hero that sets its unit separately."
  @spec figure(integer(), :kg | :lb | :st) :: String.t()
  def figure(grams, :lb), do: one_place(grams / 453.59237)

  def figure(grams, :st) do
    pounds = grams / 453.59237
    stones = trunc(pounds / 14)
    "#{stones}st #{one_place(pounds - stones * 14)}"
  end

  def figure(grams, _kg), do: one_place(grams / 1000)

  @doc "The unit's own label — `kg`, `lb`, `st`."
  @spec unit_label(:kg | :lb | :st) :: String.t()
  def unit_label(:lb), do: "lb"
  def unit_label(:st), do: "st"
  def unit_label(_kg), do: "kg"

  defp one_place(value), do: :erlang.float_to_binary(value, decimals: 1)

  @doc """
  The change from one reading to the next, in grams. Positive is heavier.

  `nil` for the first reading, because a delta needs two — and screen 109's
  rows print nothing rather than `0.0` there, since a first weighing did not
  hold steady, it simply has nothing before it.
  """
  @spec delta(t(), t() | nil) :: integer() | nil
  def delta(%__MODULE__{}, nil), do: nil
  def delta(%__MODULE__{grams: now}, %__MODULE__{grams: before}), do: now - before

  @doc "A delta as the row prints it: `−0.4`, `+0.1`, or `nil`."
  @spec delta_label(integer() | nil, :kg | :lb | :st) :: String.t() | nil
  def delta_label(nil, _unit), do: nil

  def delta_label(grams, unit) do
    # A true minus sign, not a hyphen: the column is numeric and the drawing
    # sets U+2212, which aligns with the digits where a hyphen does not.
    sign = if grams < 0, do: "−", else: "+"
    sign <> figure(abs(grams), unit)
  end

  @type t :: %__MODULE__{}
end
