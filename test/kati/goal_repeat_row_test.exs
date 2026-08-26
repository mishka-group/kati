defmodule Kati.GoalRepeatRowTest do
  @moduledoc """
  Screen 104's repeat switch changes the goal it names, and nothing else.

  ## The defect these are written against

  The page carried ONE repeat switch and its handler was
  `Enum.each(stored(), &Ash.update(&1, %{repeat: now}))` — every live goal
  rewritten from a control that named none of them. On a page with one goal
  that is indistinguishable from correct, which is why it survived: the old
  test stored one goal, tapped, and found it changed.

  So every assertion here uses **two** goals and acts on the **second**. A fix
  that reads the first row, one that writes them all, and one that falls back
  to the drawing all pass a one-goal test and fail these.

  ## Why the order is pinned rather than assumed

  `Kati.Goals.Goal`'s `:live` read sorts by `ends_on` ascending, so "the second
  row" is a fact about the data rather than about insertion. The fixtures are
  dated off `Kati.Time.today/0` — never `DateTime.utc_now/0`, which is the
  screen rule and is just as much a test rule, since a fixture dated in UTC
  drops out of the `ends_on >= today` filter for the first two hours of every
  Amsterdam day.

  ## What the drawn rows are here for

  A fresh install has no goals and the page is `Kati.Goals.Sample`'s three.
  Those rows have no id, and the two claims worth pinning are that their
  switches still MOVE — a switch that cannot be pressed is a picture of a
  switch — and that pressing one writes nothing at all.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Goals.Goal
  alias Kati.Screens.Goals

  setup do
    # BOTH sides. The `with nothing stored` tests below assert
    # `Ash.read!(Goal) == []`, so they are exactly the tests a neighbour's
    # leaked row turns into a mystery — and a suite that only cleans on the way
    # out is one leak away from being order-dependent.
    Kati.Repo.query!("DELETE FROM goals", [])
    on_exit(fn -> Kati.Repo.query!("DELETE FROM goals", []) end)

    :ok
  end

  # Two goals, in the order the page draws them: `:live` sorts by `ends_on`, so
  # the one that ends sooner is the first row and `second` is the second.
  defp two_goals! do
    today = Kati.Time.today()

    first =
      a_goal!(%{kind: :books, target: 52, progress: 38, ends_on: Date.add(today, 30)})

    second =
      a_goal!(%{kind: :films, target: 120, progress: 84, ends_on: Date.add(today, 60)})

    {first, second}
  end

  defp a_goal!(attrs) do
    Ash.create!(
      Goal,
      Map.merge(
        %{
          kind: :books,
          target: 52,
          progress: 38,
          period: :year,
          repeat: true,
          starts_on: Date.add(Kati.Time.today(), -30)
        },
        attrs
      )
    )
  end

  defp row_tags(view) do
    view
    |> assigns()
    |> Map.fetch!(:goals)
    |> Enum.map(& &1.repeat_tag)
  end

  describe "the row you tapped" do
    test "tapping the second row changes the second goal and leaves the first alone" do
      {first, second} = two_goals!()

      view = mount_screen(Goals)
      [_first_tag, second_tag] = row_tags(view)

      render_info(view, {:tap, second_tag})

      assert Ash.get!(Goal, second.id).repeat == false,
             "the row that was tapped did not change"

      assert Ash.get!(Goal, first.id).repeat == true,
             "the first goal changed too, which is the unbounded update this screen was " <>
               "opened for"
    end

    test "the second row's tag carries the second goal's id" do
      {first, second} = two_goals!()

      view = mount_screen(Goals)
      [first_tag, second_tag] = row_tags(view)

      # An ATOM, not a tuple: only `is_atom(tag)` reaches Compose as a testTag
      # and emits an `accessibility_id`, so a tuple here is a switch no device
      # test and no screen reader can address.
      assert is_atom(second_tag)
      assert second_tag == Goals.repeat_tag(second.id)
      assert first_tag == Goals.repeat_tag(first.id)
      refute first_tag == second_tag
    end

    test "the second row is drawn with that tag, and the rows are titled apart" do
      {_first, second} = two_goals!()

      view = mount_screen(Goals)
      [_first_tag, second_tag] = row_tags(view)

      tags =
        for node <- flatten(view),
            {pid, tag} <- [Map.get(Map.get(node, :props) || %{}, :on_tap)],
            is_pid(pid),
            do: tag

      assert second_tag in tags,
             "the second goal's switch is not on the screen, so nothing could tap it"

      # And the tag that is ON THE SCREEN is the second goal's own, not the
      # first's and not a drawn row's — which is the whole claim of this file,
      # asserted against the tree rather than against the assigns.
      assert Goals.repeat_tag(second.id) in tags

      # The row says which goal it changes. A switch that does not name what it
      # changes is one you cannot use correctly, whatever it writes.
      assert "120 films this year" in text_nodes(view)
      assert "52 books this year" in text_nodes(view)
    end

    test "the page's assigns move for the tapped row only" do
      two_goals!()

      view = mount_screen(Goals)
      [_first_tag, second_tag] = row_tags(view)

      assert [true, true] = Enum.map(assigns(view).goals, & &1.repeat)

      toggled = render_info(view, {:tap, second_tag})

      assert [true, false] = Enum.map(assigns(toggled).goals, & &1.repeat)
    end

    test "tapping the second row twice puts the second goal back, and nothing else moved" do
      {first, second} = two_goals!()

      view = mount_screen(Goals)
      [_first_tag, second_tag] = row_tags(view)

      view
      |> render_info({:tap, second_tag})
      |> render_info({:tap, second_tag})

      assert Ash.get!(Goal, second.id).repeat == true
      assert Ash.get!(Goal, first.id).repeat == true
    end

    test "a row deleted underneath the page takes the write with it, and the page re-reads" do
      {first, second} = two_goals!()

      view = mount_screen(Goals)
      [_first_tag, second_tag] = row_tags(view)

      # The screen is still holding a goal that is no longer there. This is
      # what a stale push looks like, and it is the shape the tap sweep
      # reproduces: a switch that toggles a goal nobody has.
      Ash.destroy!(second)

      toggled = render_info(view, {:tap, second_tag})

      assert Enum.map(assigns(toggled).goals, & &1.id) == [first.id],
             "the page kept a row the store no longer has"

      assert Ash.get!(Goal, first.id).repeat == true,
             "a write for a goal that is gone landed on the goal that is left"
    end

    test "no two rows share a tag, so no tag names two goals" do
      two_goals!()
      a_goal!(%{kind: :albums, target: 30, ends_on: Date.add(Kati.Time.today(), 90)})

      tags = row_tags(mount_screen(Goals))

      assert length(tags) == 3
      assert Enum.uniq(tags) == tags
    end
  end

  describe "with nothing stored" do
    test "the page is the drawing, and the drawing's rows are tagged apart" do
      view = mount_screen(Goals)
      tags = row_tags(view)

      assert Goals.goals() == Goals.drawn_goals()
      assert length(tags) == 3
      assert Enum.uniq(tags) == tags
      assert Enum.all?(tags, &is_atom/1)
    end

    test "a drawn row's switch moves and writes nothing" do
      view = mount_screen(Goals)
      [_first_tag, second_tag | _rest] = row_tags(view)

      toggled = render_info(view, {:tap, second_tag})

      # The switch moved, and only the second one.
      assert [true, false, true] = Enum.map(assigns(toggled).goals, & &1.repeat)

      # And a sample is not a row: nothing was created to carry the change.
      assert Ash.read!(Goal) == []
    end

    test "a drawn row cannot be mistaken for a stored one" do
      # The two namespaces are held apart on purpose: a device test that waits
      # for `goal_repeat_drawn_2` is waiting for the empty state, and one that
      # waits for `goal_repeat_<uuid>` is waiting for a goal.
      for tag <- row_tags(mount_screen(Goals)) do
        assert String.starts_with?(Atom.to_string(tag), "goal_repeat_drawn_")
      end
    end
  end

  defp text_nodes(view) do
    for node <- flatten(view),
        text = Map.get(Map.get(node, :props) || %{}, :text),
        is_binary(text),
        do: text
  end
end
