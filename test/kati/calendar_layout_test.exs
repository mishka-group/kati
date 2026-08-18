defmodule Kati.Calendar.LayoutTest do
  use ExUnit.Case, async: true

  alias Kati.Calendar.Layout

  defp ev(id, start_min, end_min, kind \\ nil),
    do: %{id: id, start_min: start_min, end_min: end_min, kind: kind}

  defp by_id(placements), do: Map.new(placements, &{&1.event.id, &1})

  describe "clustering" do
    test "events that do not overlap each get the full width" do
      placements = Layout.lanes([ev(1, 540, 600), ev(2, 600, 660)])

      assert Enum.all?(placements, &(&1.n_cols == 1 and &1.span == 1))
    end

    test "an event starting exactly when another ends does not clash" do
      # The boundary case: 10:00–11:00 and 11:00–12:00 are sequential, and a
      # calendar that draws them side by side is wrong in a way users read
      # as "I am double-booked" when they are not.
      assert [%{n_cols: 1}, %{n_cols: 1}] = Layout.lanes([ev(1, 600, 660), ev(2, 660, 720)])
    end

    test "overlapping events split into lanes" do
      placements = Layout.lanes([ev(1, 600, 660), ev(2, 630, 690)]) |> by_id()

      assert placements[1].col == 0
      assert placements[2].col == 1
      assert placements[1].n_cols == 2
    end

    test "a cluster is independent of its neighbours" do
      # The clash at 10:00 must not widen the unrelated 14:00 event.
      placements = Layout.lanes([ev(1, 600, 660), ev(2, 630, 690), ev(3, 840, 900)]) |> by_id()

      assert placements[3].n_cols == 1
    end
  end

  describe "phase 3 — expansion" do
    test "a short event widens into the gap left by a finished neighbour" do
      # 1 runs 10:00–12:00 in column 0. 2 runs 10:30–11:00 in column 1 and
      # has nothing to its right, so it takes the remaining width rather
      # than leaving the lane half empty.
      placements = Layout.lanes([ev(1, 600, 720), ev(2, 630, 660)], max_cols: 3) |> by_id()

      assert placements[2].span == 1
      assert placements[2].n_cols == 2
    end

    test "an event blocked on its right keeps span 1" do
      placements =
        Layout.lanes([ev(1, 600, 720), ev(2, 610, 700), ev(3, 620, 690)], max_cols: 3) |> by_id()

      assert placements[1].span == 1
    end
  end

  describe "phase 0 — collapse by kind" do
    test "three of a kind become one occurrence carrying its members" do
      placements = Layout.lanes([ev(1, 600, 630, :meal), ev(2, 610, 640, :meal), ev(3, 620, 650, :meal)])

      assert [%{event: %{id: {:collapsed, :meal, ids}} = collapsed}] = placements
      assert ids == [1, 2, 3]
      assert collapsed.start_min == 600
      assert collapsed.end_min == 650
      assert length(collapsed.collapsed) == 3
    end

    test "two of a kind do not collapse" do
      assert length(Layout.lanes([ev(1, 600, 660, :meal), ev(2, 610, 670, :meal)])) == 2
    end

    test "collapsing runs BEFORE lane assignment, not after" do
      # The ordering requirement stated in the research: three meals plus one
      # other event must end up as two lanes, not four. If collapse ran after
      # colouring, the meals would each have been allocated a column first and
      # the cluster would overflow to a `+n MORE` tile it never needed.
      placements =
        Layout.lanes([
          ev(1, 600, 660, :meal),
          ev(2, 605, 665, :meal),
          ev(3, 610, 670, :meal),
          ev(4, 600, 660, :work)
        ])

      assert length(placements) == 2
      assert Enum.all?(placements, &(&1.n_cols == 2))
      refute Enum.any?(placements, &(&1.role == :overflow))
    end

    test "generic calendar events never collapse, however many clash" do
      # DeviceImport stamps every mirrored row :event. Folding three clashing
      # meetings into one card would hide the clash the day view exists to
      # show — and a hidden meeting is a missed one.
      placements =
        Layout.lanes([
          ev(1, 600, 660, :event),
          ev(2, 610, 670, :event),
          ev(3, 620, 680, :event)
        ])

      refute Enum.any?(placements, &match?({:collapsed, _, _}, &1.event.id))
      assert [_tile] = Enum.filter(placements, &(&1.role == :overflow))
    end

    test "only kinds where a group reads better than its members fold" do
      for kind <- Layout.collapsible_kinds() do
        placements =
          Layout.lanes([ev(1, 600, 660, kind), ev(2, 610, 670, kind), ev(3, 620, 680, kind)])

        assert [%{event: %{id: {:collapsed, ^kind, _}}}] = placements
      end
    end

    test "occurrences with no kind never collapse" do
      assert length(Layout.lanes([ev(1, 600, 660), ev(2, 605, 665), ev(3, 610, 670)], max_cols: 3)) == 3
    end
  end

  describe "overflow" do
    test "three clashing events give two lanes and a +1 MORE tile" do
      # Screen 09's stated composition: "2 at once split lanes capped at two
      # columns with a +1 MORE tile".
      placements = Layout.lanes([ev(1, 600, 700), ev(2, 610, 700), ev(3, 620, 700)])

      assert [tile] = Enum.filter(placements, &(&1.role == :overflow))
      assert length(tile.event.overflow) == 1
      assert length(placements) == 3
      assert Enum.all?(placements, &(&1.n_cols == 2))
    end

    test "the tile is a footer across the cluster, not a lane" do
      # If it took a lane, three events capped at two columns would read
      # "+2 MORE" beside one card rather than screen 09's "+1 MORE".
      placements = Layout.lanes([ev(1, 600, 700), ev(2, 610, 700), ev(3, 620, 700)])
      [tile] = Enum.filter(placements, &(&1.role == :overflow))

      assert tile.col == 0
      assert tile.span == tile.n_cols
    end

    test "the kept events are the earliest, longest ones" do
      placements = Layout.lanes([ev(3, 620, 700), ev(1, 600, 720), ev(2, 610, 700)])
      kept = for p <- placements, p.role == :event, do: p.event.id

      assert kept == [1, 2]
    end

    test "the tile spans the hidden events" do
      placements = Layout.lanes([ev(1, 600, 700), ev(2, 610, 700), ev(3, 620, 780), ev(4, 630, 760)])
      [tile] = Enum.filter(placements, &(&1.role == :overflow))

      assert tile.event.start_min == 620
      assert tile.event.end_min == 780
    end
  end

  describe "zero-length occurrences" do
    test "get a layout-only floor so they are visible and can clash" do
      [a, b] = Layout.lanes([ev(1, 600, 600), ev(2, 605, 665)])

      assert a.n_cols == 2, "a zero-length event must still occupy a lane"
      assert b.n_cols == 2
    end

    test "the floor never reaches storage" do
      # lanes/2 returns the occurrence it was given, lengthened only for the
      # purpose of drawing it. Nothing here may be written back.
      [%{event: event}] = Layout.lanes([ev(1, 600, 600)])

      assert event.end_min - event.start_min == Layout.min_render_minutes()
      assert event.id == 1
    end
  end

  describe "stability" do
    test "the output is a pure function of the input set, not its order" do
      events = [ev(1, 600, 660), ev(2, 630, 690), ev(3, 640, 700), ev(4, 900, 960)]
      expected = events |> Layout.lanes(max_cols: 3) |> by_id()

      for _ <- 1..40 do
        assert events |> Enum.shuffle() |> Layout.lanes(max_cols: 3) |> by_id() == expected
      end
    end

    test "equal intervals are ordered by id, so lanes cannot swap between renders" do
      # Without the id tiebreak these two sort equally. There is no BEAM-side
      # diff — every change ships the whole tree and calls set_root — so a
      # tie that resolves differently makes lanes jump on an unrelated tap.
      a = Layout.lanes([ev(:b, 600, 660), ev(:a, 600, 660)]) |> by_id()
      b = Layout.lanes([ev(:a, 600, 660), ev(:b, 600, 660)]) |> by_id()

      assert a[:a].col == 0 and a[:b].col == 1
      assert a == b
    end
  end

  describe "invariants over a generated day" do
    test "no two placements ever occupy the same column at the same minute" do
      # The property that matters visually: overlapping cards. Checked over
      # 200 random days rather than the handful of shapes above.
      for seed <- 1..200 do
        :rand.seed(:exsss, {seed, seed, seed})

        events =
          for id <- 1..:rand.uniform(12) do
            start_min = :rand.uniform(1400)
            ev(id, start_min, start_min + :rand.uniform(180))
          end

        placements =
          events
          |> Layout.lanes(max_cols: 4, collapse?: false)
          |> Enum.filter(&(&1.role == :event))

        for a <- placements, b <- placements, a.event.id < b.event.id do
          time_overlap? =
            a.event.start_min < b.event.end_min and b.event.start_min < a.event.end_min

          col_overlap? =
            a.col < b.col + b.span and b.col < a.col + a.span

          refute time_overlap? and col_overlap?,
                 "seed #{seed}: #{inspect(a.event.id)} and #{inspect(b.event.id)} overlap in both time and columns"
        end
      end
    end

    test "column and span always stay inside n_cols" do
      for seed <- 1..100 do
        :rand.seed(:exsss, {seed, seed, seed})

        events =
          for id <- 1..:rand.uniform(10) do
            start_min = :rand.uniform(1400)
            ev(id, start_min, start_min + :rand.uniform(240))
          end

        for p <- Layout.lanes(events, collapse?: false) do
          assert p.col >= 0
          assert p.span >= 1
          assert p.col + p.span <= p.n_cols
        end
      end
    end
  end
end
