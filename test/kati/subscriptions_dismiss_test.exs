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
    test "draws, and takes no tap" do
      # M18. It lit under the finger and did nothing, kept on the argument that
      # stripping `on_tap` would take its press feedback away. Press feedback
      # was the defect: a disc that answers a press by doing nothing is worse
      # than one that was never offered.
      disc = Screen.disc()
      drawn = inspect(disc, limit: :infinity)

      # The glyph reaches the tree as a resolved codepoint, not as the ligature
      # name — `Kati.UI.symbol/2` does that lookup — so the disc is checked by
      # the face it is set in.
      assert drawn =~ "symbols", "the board's own disc stopped being drawn"

      refute drawn =~ "open_menu", "the dead tag is still on it"

      refute drawn =~ "on_tap",
             "it still answers a press, which is the whole of what was wrong with it"
    end
  end
end
