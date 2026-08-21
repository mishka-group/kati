defmodule Kati.ScreenDayTest do
  @moduledoc """
  Screen 09's collapsed group, closed and open.

  ## Why this is not covered by the sweeps

  `Kati.ScreenRenderSweepTest` renders every screen exactly once, from
  `mount/3`, so it only ever sees a screen's **resting** tree.
  `Kati.ScreenTapSweepTest` taps everything that tree draws and asserts the
  handler answers and that the assigns moved — not what the next render
  contains. Between them, a group whose chevron flips a flag and draws nothing
  passes both: the tap is live, the assigns change, and the members are still
  missing.

  So every assertion here is a count or a string. Three members means three
  poster `<Image>`s in the stack and three more in the open block, each title
  drawn exactly once and each member's own clock beside it. `Kati.UI.symbol/2`
  draws a glyph the font may not have, `src=` is dropped in silence if it is
  ever written `source=`, and an unregistered composite renders as nothing —
  every one of those failures is invisible except as a count that fell.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Calendar.SampleDay
  alias Kati.Screens.Day

  # The 20:00 cluster's tag, built from its start minute — `20 * 60`. Written
  # out rather than computed so a change to the tagging scheme fails here
  # loudly instead of agreeing with itself.
  @group :group_1200

  # `Kati.Calendar.SampleDay`'s three 20:00 episodes, in the order
  # `Kati.Calendar.Layout` sorts them: by start minute.
  @members [
    {"Ashfall", "S3 · E2", "20:00", "ashfall42"},
    {"Salt & Iron", "S1 · E4", "20:05", "saltiron33"},
    {"The Cartographer", "S2 · E1", "20:10", "cartog60"}
  ]

  describe "the collapsed group" do
    test "draws the whole day, with the grouped card in it" do
      card = group_card(tree(mount_screen(Day)))

      assert card != nil,
             "no radius-18 card on screen 09. The 20:00 group is the only card " <>
               "the drawing gives an 18pt radius, so either Kati.Calendar.Layout " <>
               "stopped collapsing the three episodes or the card changed shape " <>
               "and every assertion below is now measuring the wrong node."

      assert text(card) =~ "3 episodes"
      assert text(card) =~ "Ashfall · Salt & Iron"
    end

    test "stacks one poster per member, plus the count tile" do
      stack = poster_stack(group_card(tree(mount_screen(Day))))

      assert stack != nil,
             "the 96x48 poster stack is gone — three 34pt tiles at 22 apart plus " <>
               "a 30pt count tile is 96, and without it the group is a title with " <>
               "no artwork."

      images = find_all(stack, :image)

      assert length(images) == length(@members),
             "the stack drew #{length(images)} posters for #{length(@members)} " <>
               "members. An <Image> with an unknown prop renders as nothing and " <>
               "says nothing, so a count is the only evidence the artwork is there."

      for {_title, _meta, _time, seed} <- @members do
        assert Enum.any?(images, &String.contains?(&1.props.src, seed)),
               "no poster in the stack came from #{seed}"
      end

      # `{{ groupCount }}` in the export, drawn as the group's own size.
      assert text(stack) == "3"
    end

    test "draws no member row until it is opened" do
      card = group_card(tree(mount_screen(Day)))

      for {title, meta, _time, _seed} <- @members do
        assert find_all(card, :text, text: title) == [],
               "#{inspect(title)} is drawn while the group is closed"

        assert find_all(card, :text, text: meta) == []
      end

      assert find(card, :box, rotate: 180.0) == nil,
             "the chevron is already flipped on a closed group"
    end

    test "the header row carries the tap that opens it" do
      row = tapped_row(tree(mount_screen(Day)))

      assert row != nil,
             "nothing on screen 09 draws #{inspect(@group)}, so the group cannot " <>
               "be opened at all"

      assert row.props.on_tap == {self(), @group}
    end
  end

  describe "the open group" do
    test "draws every member, with its own poster, line and clock" do
      card = opened() |> tree() |> group_card()

      for {title, meta, time, seed} <- @members do
        assert length(find_all(card, :text, text: title)) == 1
        assert length(find_all(card, :text, text: meta)) == 1

        assert length(find_all(card, :text, text: time)) == 1,
               "#{title}'s clock (#{time}) is missing or drawn twice"

        assert Enum.count(find_all(card, :image), &String.contains?(&1.props.src, seed)) == 2,
               "#{seed} should appear twice while the group is open — once in the " <>
                 "stack and once on its own row"
      end

      assert length(find_all(card, :image)) == 2 * length(@members)
    end

    test "the members sit under the drawn hairline, inside the card" do
      card = opened() |> tree() |> group_card()

      assert find(card, :box, height: 1, background: 0x141A1917) != nil,
             "the 8%-ink rule between the header and the members is missing"

      # Inside the card, not under it: the rule and every member row are
      # descendants of the same radius-18 node the header row lives in.
      assert length(find_all(card, :image)) == 6
    end

    test "the chevron is the same glyph, turned over" do
      card = opened() |> tree() |> group_card()

      assert find(card, :box, rotate: 180.0) != nil,
             "the open group still points its chevron down. There is no " <>
               "expand_less in the icon subset — a missing glyph draws empty " <>
               "space — so the collapse arrow is expand_more at 180."
    end

    test "renders a tree the native layer can draw" do
      # The render sweep never sees this tree: it renders each screen once,
      # from mount, and the group is closed there. An unrenderable node type
      # draws NOTHING on Android, with no crash and no log.
      assert_renderable(opened())
    end

    test "opens in Persian too" do
      # Restored in an `after`, never in `on_exit/1`: `Mob.ScreenCase` stops
      # `Mob.State` — the DETS table the locale lives in — as the test's own
      # teardown, so an `on_exit` callback calls a GenServer that is already
      # gone and the test fails on the way out with every assertion passed.
      previous = Kati.Locale.current()

      card =
        try do
          Kati.Locale.put(:fa)
          opened() |> tree() |> group_card()
        after
          Kati.Locale.put(previous)
        end

      for {title, _meta, _time, _seed} <- @members do
        assert length(find_all(card, :text, text: title)) == 1
      end
    end
  end

  describe "the toggle" do
    test "records the group it opened, and only that one" do
      view = opened()

      assert assigns(view).open_groups == [@group]
    end

    test "closing restores the resting tree exactly" do
      # The rule screen 09 is being held to: opening and closing a group may
      # not leave a single prop moved. Compared as whole trees rather than by
      # eye, because a 13pt spacer that failed to leave with the members is
      # invisible in a screenshot and obvious here.
      view = mount_screen(Day)
      resting = tree(view)

      reopened = view |> render_info({:tap, @group}) |> render_info({:tap, @group})

      assert assigns(reopened).open_groups == []
      assert tree(reopened) == resting
    end

    test "handle_tap/2 answers the tag and moves the assigns" do
      view = mount_screen(Day)
      %{socket: socket} = view

      assert {:noreply, opened} = Day.handle_tap(@group, socket)
      assert opened.assigns.open_groups == [@group]

      assert {:noreply, closed} = Day.handle_tap(@group, opened)
      assert closed.assigns.open_groups == []
    end

    test "survives a chip that filters the group off the timeline and back" do
      # The clusters are rebuilt from the filtered occurrences on every render,
      # so an open group cannot be remembered by its position in that list.
      # Narrowing to Personal takes every episode off the day; widening back
      # has to bring the group back open, not merely back.
      narrowed =
        Day
        |> mount_screen()
        |> render_info({:tap, @group})
        |> render_info({:tap, :filter_Personal})

      assert group_card(tree(narrowed)) == nil,
             "the 20:00 group is still drawn with the timeline narrowed to Personal"

      widened = render_info(narrowed, {:tap, :filter_Personal})
      card = group_card(tree(widened))

      for {title, _meta, _time, _seed} <- @members do
        assert length(find_all(card, :text, text: title)) == 1
      end
    end

    test "a group the day does not have leaves the screen alone" do
      view = mount_screen(Day)
      %{socket: socket} = view

      assert {:noreply, updated} = Day.handle_tap(:group_99999, socket)
      assert updated.assigns.open_groups == [:group_99999]
      refute find(tree(%{view | socket: updated}), :box, rotate: 180.0)
    end
  end

  describe "the sample day the group is built from" do
    test "still holds three episodes at 20:00" do
      # Everything above counts to three. If `Kati.Calendar.SampleDay` ever
      # holds a different number of 20:00 episodes, these tests should fail
      # here — naming the data — rather than as six confusing count mismatches.
      at_2000 =
        SampleDay.occurrences()
        |> Enum.filter(&(&1.kind == :air_date and &1.start_min in 1200..1210))

      assert length(at_2000) == length(@members)

      assert Enum.map(at_2000, & &1.title) == Enum.map(@members, fn {t, _, _, _} -> t end)
    end
  end

  # ── helpers ────────────────────────────────────────────────────────────────

  defp opened, do: Day |> mount_screen() |> render_info({:tap, @group})

  # The grouped card: the one node the drawing gives an 18pt radius. Every
  # other card on screen 09 is 16, so this cannot pick up a neighbour, and
  # scoping to it keeps the gutter's own "20:00" out of the member counts.
  defp group_card(tree), do: find(tree, :column, corner_radius: 18)

  # Three 34pt tiles overlapped to 22 apart, plus the 30pt count tile.
  defp poster_stack(nil), do: nil
  defp poster_stack(card), do: find(card, :box, width: 96, height: 48)

  defp tapped_row(tree) do
    tree
    |> flatten()
    |> Enum.find(fn node ->
      props = Map.get(node, :props) || %{}
      match?({pid, @group} when is_pid(pid), Map.get(props, :on_tap))
    end)
  end
end
