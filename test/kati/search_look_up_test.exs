defmodule Kati.SearchLookUpTest do
  @moduledoc """
  *Search TMDB for "…"* carries the word you typed.

  Screen 19's `:look_up` handed the query over through `Kati.Search.hand_over/1`
  and pushed screen 06 bare. Screen 06 has never read that key — it reads
  `params[:query]` through `Kati.Screens.AddTitle.opening_query/1` — so the
  sheet opened blank with its placeholder greyed in the field, while the key it
  did write changed what the Library's search disc opened next. Found on the
  Pixel 9a, 25 Sep, while checking whether TMDB answers at all.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Screens.AddTitle
  alias Kati.Screens.Search

  defp searched(query) do
    Search
    |> Mob.Socket.new()
    |> Mob.Socket.assign(:query, query)
  end

  test "the push names the query" do
    {:noreply, pushed} = Search.handle_info({:tap, :look_up}, searched("Arrival"))

    assert {:push, AddTitle, %{query: "Arrival"}} = pushed.__mob__.nav_action,
           "screen 06 was pushed without the word the reader typed"
  end

  test "and screen 06 opens on it" do
    {:noreply, pushed} = Search.handle_info({:tap, :look_up}, searched("Arrival"))
    {:push, AddTitle, params} = pushed.__mob__.nav_action

    assert AddTitle.opening_query(params) == "Arrival"
  end

  test "and it writes nothing another screen would read later" do
    # The key it used to write is the one the Library's search disc falls back
    # to, so a lookup here quietly changed what that disc opened next.
    before = Kati.Search.handed_over()

    {:noreply, _pushed} = Search.handle_info({:tap, :look_up}, searched("Arrival"))

    assert Kati.Search.handed_over() == before
  end
end
