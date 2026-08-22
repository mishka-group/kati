defmodule Kati.Health do
  @moduledoc """
  Readings you typed and doses you took.

  Two resources, and both are shaped by the same constraint: **Kati is not a
  medical device.** Screen 112 prints that sentence and this domain is what
  makes it true — nothing here computes a dose, warns about an interaction,
  infers a trend or advises anything. It records what it was told.

  ## Nothing is connected, and the screen says so

  Screen 109's own note: *Kati stores the readings you type and nothing else —
  no scale is connected, and nothing here leaves the device.* There is no
  integration point in this domain, no `source` column with a `:healthkit`
  value waiting to be filled in, and no sync. Adding one later means adding a
  column and saying so; leaving room for one now would be implying a road map
  the app has not committed to.

  ## Units are a display choice, never a stored one

  `Kati.Health.Reading.grams` is grams, always, and `unit/0` decides what the
  screen prints. Screen 111 puts the unit switch inside the sheet as well as in
  Settings, and its caption says why: *changing it here is a correction, not a
  preference* — you weighed yourself in pounds and typed pounds. Converting on
  the way in and storing one unit is what lets that be a correction rather than
  a rewrite of your history.

  This is the opposite decision from `Kati.Money`, which stores the currency
  beside the amount and never converts. The difference is that a kilogram is a
  kilogram — the conversion is exact and timeless — where an exchange rate is a
  fact about a day nobody recorded.
  """

  use Ash.Domain, validate_config_inclusion?: false

  resources do
    resource Kati.Health.Reading
    resource Kati.Health.Medication
    resource Kati.Health.Dose
  end

  @unit_key :kati_weight_unit

  @doc "The unit weights are shown in: `:kg`, `:lb` or `:st`. Kilograms by default."
  @spec unit() :: :kg | :lb | :st
  def unit do
    case Mob.State.get(@unit_key) do
      unit when unit in [:kg, :lb, :st] -> unit
      _other -> :kg
    end
  end

  @doc "Change the display unit. Converts nothing — see the moduledoc."
  @spec put_unit(:kg | :lb | :st) :: :ok
  def put_unit(unit) when unit in [:kg, :lb, :st] do
    Mob.State.put(@unit_key, unit)
    :ok
  end
end
