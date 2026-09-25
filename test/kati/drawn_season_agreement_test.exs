defmodule Kati.DrawnSeasonAgreementTest do
  @moduledoc """
  Screen 04's Season 2 and screen 34's Season 2 are the same season.

  Opening *Episode order* from the drawn series showed a
  different Season 2 from the one on screen — *The Weight of Water / Hollow
  Ground / Salt in the Wound* on 04, *Low Water / The Cull / Blackthorn* on
  34, same show, same season, one back tap apart.

  Neither board was wrong on its own, and that is what made it hard to see.
  `test/design/screens/04.html` draws `{{ ep.title }}` — a template, with no
  episode names in it at all — so `Kati.Library.Sample` invented seven, and
  nothing compared them to the board that does name them. 34 is that board.

  So this file asks the one question neither board can ask alone: **do the two
  fixtures describe the same evening?** It compares titles rather than whole
  rows, because 34 legitimately carries two things 04 does not draw — the
  making-of, which is what 34's *Include specials* switch is about, and the
  `PARTS 1–2` badge on its merged finale.
  """

  use ExUnit.Case, async: true

  alias Kati.Library.Sample
  alias Kati.Season.Sample, as: SeasonSample

  test "every episode screen 04 draws for S2 is one screen 34 draws" do
    on_04 = Enum.map(Sample.series().episodes, & &1.title)
    on_34 = Enum.map(SeasonSample.season().episodes, & &1.title)

    assert on_04 -- on_34 == [],
           "these are on screen 04's Season 2 and not on screen 34's, so a user " <>
             "who taps Episode order sees a season they have not been watching: " <>
             inspect(on_04 -- on_34)
  end

  test "and they are in the same order" do
    on_34 = SeasonSample.season().episodes |> Enum.reject(& &1[:special]) |> Enum.map(& &1.title)

    assert Enum.map(Sample.series().episodes, & &1.title) == on_34
  end

  test "the only thing 34 has that 04 does not is the special" do
    on_04 = MapSet.new(Sample.series().episodes, & &1.title)
    extra = SeasonSample.season().episodes |> Enum.reject(&MapSet.member?(on_04, &1.title))

    assert Enum.map(extra, & &1.title) == ["The Estuary — a making-of"]
    assert Enum.all?(extra, & &1[:special])
  end

  test "screen 05's out-now row names an episode of that same season" do
    titles = MapSet.new(Sample.series().episodes, & &1.title)
    line = Sample.inbox().out_now |> hd() |> Map.fetch!(:line)

    assert Enum.any?(titles, &String.ends_with?(line, &1)),
           "the inbox announces #{inspect(line)}, which is not an episode of the " <>
             "season screens 04 and 34 draw"
  end

  test "S2 keeps the drawing's three row states" do
    episodes = Sample.series().episodes

    assert Enum.count(episodes, & &1.watched) == 5
    assert Enum.count(episodes) == 7
    assert Enum.count(episodes, &(Map.get(&1, :aired, true) == false)) == 1
  end
end
