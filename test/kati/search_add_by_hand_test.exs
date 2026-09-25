defmodule Kati.SearchAddByHandTest do
  @moduledoc """
  *or add it by hand* carries the word you just typed.

  It pushed screen 154 bare, so a reader who searched for *Estuary*, was told
  nothing matched, and pressed the row landed on an empty title field and
  typed the word the app had just shown them.

  The handover is 154's own ONE-SHOT key, and both halves of that matter.
  `Kati.Search.hand_over/1` — what *Look it up* uses one row up — writes a DETS
  key nothing clears, and screens 03 and 20 each carry a comment about what
  that cost: the Library's search disc opening *"somebody's last search, from a
  previous launch"*. A prefill that outlives its one arrival is that bug again.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Screens.AddByHand

  setup do
    AddByHand.take_prefill()
    :ok
  end

  test "nothing is prefilled when nobody left anything" do
    assert AddByHand.take_prefill() == ""
  end

  test "and the title arrives when screen 19 leaves one" do
    :ok = AddByHand.prefill("Estuary")

    {:ok, socket} = AddByHand.mount(%{}, %{}, Mob.Socket.new(AddByHand))

    assert socket.assigns.title == "Estuary",
           "the reader retypes the word the app just showed them"
  end

  test "it is taken, so the next arrival is empty again" do
    :ok = AddByHand.prefill("Estuary")

    {:ok, first} = AddByHand.mount(%{}, %{}, Mob.Socket.new(AddByHand))
    {:ok, second} = AddByHand.mount(%{}, %{}, Mob.Socket.new(AddByHand))

    assert first.assigns.title == "Estuary"

    assert second.assigns.title == "",
           "a door reached some other way opened on a search that was not for it"
  end

  test "and the tap on screen 19 is what leaves it" do
    socket =
      Kati.Screens.Search
      |> Mob.Socket.new()
      |> Mob.Socket.assign(:query, "Estuary")

    {:noreply, _pushed} = Kati.Screens.Search.handle_info({:tap, :add_by_hand}, socket)

    assert AddByHand.take_prefill() == "Estuary"
  end
end
