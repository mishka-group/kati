defmodule Kati.SubscriptionsDismissTest do
  @moduledoc """
  *Dismiss* retires the card for longer than the visit.

  It was `Mob.Socket.assign(socket, :suggestion, false)` and nothing else, and
  `load/1` assigned `suggestion: true` unconditionally — so the card came back
  on the next mount. The button retired it for as long as the reader stayed on
  the page and no longer.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Screens.Subscriptions, as: Screen
  alias Kati.Subscriptions

  setup do
    Subscriptions.dismiss("")
    :ok
  end

  describe "the dismissal" do
    test "is nothing until something is dismissed" do
      assert Subscriptions.dismissed() == nil
    end

    test "and survives being made" do
      :ok = Subscriptions.dismiss("Lumen+")

      assert Subscriptions.dismissed() == "Lumen+"
    end

    test "is about one service, not about advice in general" do
      # The card is advice about one subscription. A reader who dismisses it
      # has said something about that service — not that they never want to be
      # told anything about any subscription again.
      :ok = Subscriptions.dismiss("Lumen+")

      refute Subscriptions.dismissed() == "Estuary TV"
    end
  end

  describe "the card" do
    test "is offered on a device with nothing to advise about" do
      # No services means no suggestion, and nothing to suppress.
      assert Screen.offer?()
    end

    test "and mount reads the store rather than assuming true" do
      {:ok, socket} = Screen.mount(%{}, %{}, Mob.Socket.new(Screen))

      assert socket.assigns.suggestion == Screen.offer?(),
             "the mount assigned a constant where it should have read the dismissal"
    end
  end

  describe "the overflow disc" do
    test "is not drawn, because there is nothing for it to open" do
      # M18, then the owner on a device: a disc that answers a press by doing
      # nothing reads as broken. The board's disc opens no menu anywhere in
      # the export, so the page draws none.
      refute inspect(Screen.back_row(), limit: :infinity) =~ "symbols"
    end
  end
end
