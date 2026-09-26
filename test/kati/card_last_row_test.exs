defmodule Kati.CardLastRowTest do
  @moduledoc """
  A card never draws a hairline under its last row (`Kati.UI.SettingsList.card/1`).

  A one-row card whose row kept `rule: true` drew a line with nothing below it —
  screen 80's TMDB card, reported on the Galaxy A55, 26 Sep.
  """
  use ExUnit.Case, async: true

  alias Kati.UI.SettingsList

  defp ruled?(row), do: match?(%{props: %{height: 1}}, List.last(row.children))

  defp row(rule?) do
    SettingsList.row(SettingsList.icon_tile("movie"), SettingsList.body("TMDB"), nil, rule: rule?)
  end

  test "a single ruled row loses its line inside a card" do
    assert ruled?(row(true))
    [only] = SettingsList.card([row(true)]).children
    refute ruled?(only)
  end

  test "rows above the last keep theirs" do
    [first, last] = SettingsList.card([row(true), row(true)]).children
    assert ruled?(first)
    refute ruled?(last)
  end
end
