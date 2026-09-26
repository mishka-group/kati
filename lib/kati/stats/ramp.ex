defmodule Kati.Stats.Ramp do
  @moduledoc """
  The contribution grid's five-step colour ramp, empty to heaviest.

  Screen 07's grid and screen 98's field face paint a day's watch count
  through it. It is a palette, not data, so it lives apart from
  `Kati.Stats.Sample`, which holds the drawing's figures.
  """

  @doc """
  The colour for a day at `level`, 0 (nothing watched) to 4 (four or more).

      iex> Kati.Stats.Ramp.intensity(0)
      0xFFE7E3DC
  """
  @spec intensity(0..4) :: integer()
  def intensity(0), do: 0xFFE7E3DC
  def intensity(1), do: 0xFFE9CFA8
  def intensity(2), do: 0xFFEDB273
  def intensity(3), do: 0xFFE8823C
  def intensity(4), do: 0xFFC96A28
end
