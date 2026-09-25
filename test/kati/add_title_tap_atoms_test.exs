defmodule Kati.AddTitleTapAtomsTest do
  @moduledoc """
  Screen 06's add discs cost no atom per title.

  The tag was `add_<source_id>`, and `String.to_atom/1` on it left an atom in
  the BEAM's table — never collected, capped at about a million — for every
  distinct title ever searched. The tag is now the row's position in the full
  result list, so one page of results bounds it.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Screens.AddTitle

  defp tmdb(title, source_id, kind) do
    %{
      title: title,
      seed: nil,
      meta: "",
      note: "",
      added: false,
      source: :tmdb,
      source_id: source_id,
      kind: kind
    }
  end

  defp rows do
    [
      tmdb("Arrival", "329865", :movie),
      tmdb("Arrival", "94997", :tv),
      tmdb("Arrival", "40001", :movie)
    ]
  end

  defp add_tags(tree) do
    for %{props: %{on_tap: {_pid, tag}}} <- Mob.ScreenCase.flatten(tree),
        is_atom(tag),
        name = Atom.to_string(tag),
        String.starts_with?(name, "add_"),
        name != "add_by_hand",
        do: name
  end

  defp screen_with(rows, filter) do
    AddTitle
    |> Mob.Socket.new()
    |> Mob.Socket.assign(:query, "arrival")
    |> Mob.Socket.assign(:filter, filter)
    |> Mob.Socket.assign(:results, rows)
  end

  defp render(socket) do
    {:ok, mounted} = AddTitle.mount(%{}, %{}, Mob.Socket.new(AddTitle))
    assigns = Map.merge(mounted.assigns, socket.assigns)
    AddTitle.render(assigns)
  end

  test "the discs are tagged by position, not by TMDB id" do
    tags = rows() |> screen_with("All") |> render() |> add_tags()

    assert tags == ["add_0", "add_1", "add_2"]
    refute Enum.any?(tags, &(&1 =~ "329865"))
  end

  test "a chip that hides rows does not renumber the rest" do
    tags = rows() |> screen_with("Films") |> render() |> add_tags()

    # The series at position 1 is hidden; the second film keeps its own number.
    assert tags == ["add_0", "add_2"]
  end

  test "a tap on a position toggles exactly that row" do
    socket = screen_with(rows(), "Films")
    toggled = AddTitle.mark(socket.assigns.results, "40001")

    assert Enum.map(toggled, & &1.added) == [false, false, true],
           "mark/2 is what add/2 applies, and it must name the row by its own id"

    assert %{source_id: "40001"} = Enum.at(socket.assigns.results, 2)
  end

  test "a position that is not a row is ignored" do
    socket = screen_with(rows(), "All")

    assert AddTitle.add_at(socket, "7") == socket
    assert AddTitle.add_at(socket, "-1") == socket
    assert AddTitle.add_at(socket, "329865x") == socket
  end
end
