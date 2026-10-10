defmodule Kati.DayAllDayGroupTest do
  @moduledoc """
  The Day page's all-day band folds three or more date-only episodes into the
  timeline's grouped card, opened by `group_all_day`; films and the reader's
  own all-day events stay rows.
  """
  use ExUnit.Case, async: false

  alias Kati.Screens.Day

  defp episode(n, episodes \\ 1) do
    %{
      episodes: episodes,
      id: nil,
      at: nil,
      time: "All day",
      location: nil,
      tracked_id: "show-#{n}",
      tracked_kind: :series,
      title: "Show #{n}",
      meta: "S1 · E#{n}",
      seed: nil,
      kind: "screen",
      shape: :episode,
      now?: false,
      posters: []
    }
  end

  defp film do
    %{
      id: nil,
      at: nil,
      time: "All day",
      location: nil,
      tracked_id: "film-1",
      tracked_kind: :film,
      title: "A Film",
      meta: "Release",
      seed: nil,
      kind: "screen",
      shape: :film,
      now?: false,
      posters: []
    }
  end

  defp drawn(tree), do: inspect(tree, limit: :infinity, printable_limit: :infinity)

  test "three episodes fold into one card, closed, with the film still a row" do
    out = drawn(Day.all_day_block([episode(1), episode(2), episode(3), film()]))

    assert out =~ "3 episodes"
    assert out =~ "group_all_day"
    assert out =~ "A Film"
    refute out =~ "S1 · E3"
  end

  test "opened, every episode is a row that opens its show" do
    out = drawn(Day.all_day_block([episode(1), episode(2), episode(3)], [:group_all_day]))

    for n <- 1..3 do
      assert out =~ "Show #{n}"
      assert out =~ "row_series_show-#{n}"
    end
  end

  test "two episodes stay plain rows" do
    out = drawn(Day.all_day_block([episode(1), episode(2)]))

    refute out =~ "group_all_day"
    assert out =~ "Show 1"
    assert out =~ "Show 2"
  end

  test "shows that each drop a season say how many shows and how many episodes" do
    out = drawn(Day.all_day_block([episode(1, 8), episode(2, 9), episode(3)]))

    assert out =~ "3 shows · 18 episodes"
  end

  test "coming back re-reads the day and keeps the chip and the open groups" do
    socket =
      Mob.Socket.new(Day)
      |> Mob.Socket.assign(
        open_groups: [:group_all_day],
        filter: "Screen",
        date: ~D[2021-09-17],
        occurrences: [:stale],
        all_day: [:stale]
      )

    {:noreply, back} = Day.handle_kati(:resumed, nil, socket)

    refute :stale in back.assigns.all_day
    refute :stale in back.assigns.occurrences
    assert back.assigns.filter == "Screen"
    assert back.assigns.open_groups == [:group_all_day]
  end

  test "the chevron toggles the group" do
    socket =
      Mob.Socket.new(Day)
      |> Mob.Socket.assign(open_groups: [], date: Date.utc_today(), filter: nil)

    {:noreply, opened} = Day.handle_tap(:group_all_day, socket)
    assert opened.assigns.open_groups == [:group_all_day]

    {:noreply, closed} = Day.handle_tap(:group_all_day, opened)
    assert closed.assigns.open_groups == []
  end
end
