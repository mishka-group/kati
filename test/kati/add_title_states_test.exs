Code.require_file("../support/screen_sweep.exs", __DIR__)

defmodule Kati.AddTitleStatesTest do
  @moduledoc """
  Screen 06 in each state a person can put it in, and what it says in each.

  A search that found nothing drew the eyebrow `0 results` and then a blank
  page — the sheet looked broken rather than answered. Found on a device by
  typing a query TMDB has nothing for.
  """

  use Mob.ScreenCase, async: false

  alias Kati.ScreenSweep
  alias Kati.Screens.AddTitle

  defp words(socket) do
    socket.assigns
    |> AddTitle.render()
    |> Mob.ScreenCase.flatten()
    |> Enum.filter(&(&1.type == :text))
    |> Enum.map_join(" | ", &(Map.get(&1.props || %{}, :text) || ""))
  end

  defp mounted do
    {:ok, socket} = AddTitle.mount(%{}, %{}, Mob.Socket.new(AddTitle))
    socket
  end

  describe "a search that found nothing" do
    test "says so, naming what was typed" do
      socket =
        mounted()
        |> Mob.Socket.assign(:query, "zzzqwertyfilm")
        |> Mob.Socket.assign(:results, [])

      assert words(socket) =~ "Nothing here for “zzzqwertyfilm”"
    end

    test "the sentence is the one the music sheet already uses" do
      # Rule 6: the copy is quoted, not invented. If 179's headline is ever
      # reworded this must move with it, and this is what says so.
      assert Kati.Screens.AddTitleMusic.nothing_card("x")
             |> Mob.ScreenCase.flatten()
             |> Enum.any?(fn n ->
               n.type == :text and (Map.get(n.props || %{}, :text) || "") =~ "Nothing here for"
             end)
    end

    test "and still offers the by-hand row, once" do
      socket =
        mounted()
        |> Mob.Socket.assign(:query, "zzzqwertyfilm")
        |> Mob.Socket.assign(:results, [])

      said = words(socket)

      assert said =~ "Add it by hand"

      refute said =~ ~r/Add it by hand.*Add it by hand/s,
             "two by-hand buttons — the card's and the screen's"
    end
  end

  describe "states that are not that one" do
    test "under the three-character floor, no card" do
      for typed <- ["", "a", "ab"] do
        socket =
          mounted()
          |> Mob.Socket.assign(:query, typed)
          |> Mob.Socket.assign(:results, [])

        refute words(socket) =~ "Nothing here for",
               "a search that has not been made was reported as finding nothing"
      end
    end

    test "a refusal says why instead, and not both" do
      socket =
        mounted()
        |> Mob.Socket.assign(:query, "arrival")
        |> Mob.Socket.assign(:results, [])
        |> Mob.Socket.assign(
          :search_error,
          "No TMDB key yet. Add one in Settings → Data sources."
        )

      said = words(socket)

      assert said =~ "No TMDB key yet"

      refute said =~ "Nothing here for",
             "it said it could not look AND that it looked and found nothing"
    end

    test "results present, no card" do
      socket =
        mounted()
        |> Mob.Socket.assign(:query, "arrival")
        |> Mob.Socket.assign(:results, [
          AddTitle.row(%{
            title: "Arrival",
            kind: :movie,
            source_id: "329865",
            year: "2016",
            overview: "Aliens land.",
            poster_path: "/abc.jpg"
          })
        ])

      refute words(socket) =~ "Nothing here for"
    end

    test "the sheet opens on a card, not on the drawing's four results" do
      # This asserted the opposite until 6 September, on the argument that the
      # gallery pushes with no params and so the mount state must keep drawing
      # the drawing. It is MOVIES-AND-TV.md #43: board 06 is drawn MID-QUERY,
      # and opening on its results meant a reader who had typed nothing was
      # shown four invented films with real poster images, a `4 results`
      # caption, fabricated availability lines, and one of them ticked as
      # already in their library.
      #
      # Board 06's literals are still compared, in the state the board was
      # captured in — see `Kati.ScreenDesignLiteralTest.drawn_state/0`.
      assert {:ok, _socket, tree} = ScreenSweep.render(AddTitle)

      said =
        tree
        |> Mob.ScreenCase.flatten()
        |> Enum.filter(&(&1.type == :text))
        |> Enum.map_join(" | ", &(Map.get(&1.props || %{}, :text) || ""))

      refute said =~ "The Quiet Coast",
             "the sheet still opens on four films nobody searched for"

      assert said =~ "Search for something to add"
      assert said =~ "0 RESULTS"

      # The chrome survives, which is what `Kati.ScreenEmptyDatabaseTest`'s
      # `@quoted` rows for 06 hold from the other side.
      assert said =~ "Add a title"
      assert said =~ "Everything"
    end

    test "and one or two letters do not put them back" do
      {:noreply, typed} =
        AddTitle.handle_info({:change, :title_query, "Up"}, mounted())

      assert typed.assigns.results == []
      assert words(typed) =~ "Keep typing"

      refute words(typed) =~ "The Quiet Coast",
             "typing `Up` answered with four films nobody searched for"
    end
  end

  describe "the × at the end of the field" do
    test "clears the query, the results and any refusal" do
      # It was a bare glyph with no `on_tap`: the tap fell through to the
      # `<TextField>` under it, the keyboard opened, and the next thing typed
      # was appended to what somebody was trying to delete. On a device,
      # clearing `zzqwx` and typing `severance` gave `zzqwxseverance`.
      typed =
        mounted()
        |> Mob.Socket.assign(:query, "zzqwx")
        |> Mob.Socket.assign(:results, [])
        |> Mob.Socket.assign(:search_error, "No TMDB key yet.")

      {:noreply, cleared} = AddTitle.handle_info({:tap, :clear_query}, typed)

      assert cleared.assigns.query == ""
      refute cleared.assigns.search_error

      assert cleared.assigns.results == [],
             "clearing the field put the drawing's four results back under it"

      assert words(cleared) =~ "Search for something to add"
    end

    test "clearing does not reach the network" do
      # An empty field is under the three-character floor, so the reset must
      # not go through `searched/2` — a request for "" is a request for nothing.
      typed = Mob.Socket.assign(mounted(), :query, "arrival")

      {:noreply, cleared} = AddTitle.handle_info({:tap, :clear_query}, typed)

      refute cleared.assigns.search_error,
             "clearing the field made a request"
    end

    test "the disc is a 40pt target around a 19pt glyph" do
      target =
        AddTitle.clear_disc()
        |> Mob.ScreenCase.flatten()
        |> Enum.find(&(Map.get(&1.props || %{}, :width) == 40))

      assert target, "the glyph is its own tap target, which is 19pt"

      assert {_pid, :clear_query} = Map.get(target.props, :on_tap)
    end
  end

  describe "two results with one name" do
    test "each row carries its own key, so the second is addable" do
      rows = [
        %{title: "Severance", kind: :tv, source_id: "95396", added: false},
        %{title: "Severance", kind: :movie, source_id: "9977", added: false}
      ]

      keys = Enum.map(rows, &AddTitle.row_key/1)

      assert keys == ["95396", "9977"]
      assert length(Enum.uniq(keys)) == 2, "two rows, one accessibility_id"
    end

    test "marking the second leaves the first alone" do
      rows = [
        %{title: "Severance", kind: :tv, source_id: "95396", added: false},
        %{title: "Severance", kind: :movie, source_id: "9977", added: false}
      ]

      assert [first, second] = AddTitle.mark(rows, "9977")

      refute first.added, "adding the 2006 film ticked the 2022 series"
      assert second.added
    end

    test "a fixture row with no id keeps its title as the key" do
      assert AddTitle.row_key(%{title: "The Quiet Coast"}) == "The Quiet Coast"
    end
  end
end
