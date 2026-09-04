defmodule Kati.AddByHandTest do
  @moduledoc """
  Screen 154 writes a real row, and refuses in words when it cannot.

  The receipt is `Kati.Media.TrackedTitle`, not the socket: a form that moves
  an assign and writes nothing is exactly what screen 89's row was for as long
  as it had no destination.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Media.TrackedTitle
  alias Kati.Screens.AddByHand

  setup do
    on_exit(fn -> Kati.Repo.query!("DELETE FROM tracked_titles", []) end)
    :ok
  end

  # A real mounted socket, not a map with an `:assigns` key. `Mob.Socket`
  # carries more than its assigns and its own functions pattern-match on the
  # struct, so a stand-in fails inside `assign/3` rather than in the code
  # under test.
  defp socket(overrides) do
    Enum.reduce(overrides, mount_screen(AddByHand).socket, fn {k, v}, s ->
      Mob.Socket.assign(s, k, v)
    end)
  end

  test "a typed title reaches the store as a manual row" do
    AddByHand.save(socket(%{title: "The Long Hollow", kind: :tv, status: "Watching"}))

    assert [row] = Ash.read!(TrackedTitle)
    assert row.source == :manual
    assert row.source_id == "The Long Hollow"
    assert row.kind == :tv
    assert row.status == :watching
  end

  test "a film is a film" do
    AddByHand.save(socket(%{title: "Estuary", kind: :movie}))

    assert [row] = Ash.read!(TrackedTitle)
    assert row.kind == :movie
    assert row.status == :not_started
  end

  test "surrounding space is not part of the title" do
    AddByHand.save(socket(%{title: "  Low Water  "}))

    assert [row] = Ash.read!(TrackedTitle)
    assert row.source_id == "Low Water"
  end

  describe "the save that refuses" do
    test "no title writes nothing and says so" do
      result = AddByHand.save(socket(%{title: ""}))

      assert Ash.count!(TrackedTitle) == 0
      assert result.assigns.save_error =~ "title"
    end

    test "a title of only space is no title" do
      result = AddByHand.save(socket(%{title: "   "}))

      assert Ash.count!(TrackedTitle) == 0
      assert is_binary(result.assigns.save_error)
    end
  end

  test "every status the board draws maps to one the resource takes" do
    for {label, expected} <- [
          {"Not started", :not_started},
          {"Watching", :watching},
          {"Finished", :finished}
        ] do
      assert AddByHand.status_atom(label) == expected
    end
  end
end
