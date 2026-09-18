defmodule Kati.DataSourcesWipeTest do
  @moduledoc """
  *Disconnect everything and wipe tokens* asks before it does it.

  It did not. `handle_tap(:wipe_tokens, …)` called
  `Kati.Sources.disconnect_all/0` on the tap itself: one press and every stored
  token was gone — the reader's own TMDB key among them, the only one on this
  page they had to go and fetch — with no confirmation, no undo, and a chevron
  on the row promising a page it never opened.

  Screen 80's own `@doc` for that row names it "the only destructive control on
  the page and the only one whose consequence cannot be undone by pressing it
  again", which is the argument against what it did rather than for it.

  Board 81 draws the confirmation and settles the two judgements — inline rather
  than modal, and leading with what survives before it asks. This file holds the
  live screen to it.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Screens.DataSources
  alias Kati.Sources

  # On a host there is no encrypted store — `Kati.SecureStore.available?/0` is
  # false and `put/2` is a no-op — so the branches that need a token actually
  # stored are gated on it rather than faked. The same split
  # `Kati.TmdbTokenFieldTest` already makes, and for the same reason: a store
  # that pretended to hold a secret it had not held would be the worst of both
  # worlds, which is that module's own argument.
  @store? Kati.SecureStore.available?()

  setup do
    on_exit(fn -> Sources.disconnect_all() end)
    :ok
  end

  defp mounted do
    {:ok, socket} = DataSources.mount(%{}, %{}, Mob.Socket.new(DataSources))
    socket
  end

  describe "the first tap" do
    test "asks, and destroys nothing" do
      if @store? do
        Kati.SecureStore.put("tmdb", "a-real-token")
        assert Sources.connected_count() >= 1

        {:noreply, asked} = DataSources.handle_tap(:wipe_tokens, mounted())

        assert asked.assigns.confirm_wipe?

        assert {:ok, "a-real-token"} = Kati.SecureStore.get("tmdb"),
               "the token was destroyed by the tap that was supposed to ask about it"
      end
    end

    test "and the question is drawn, with both answers wired" do
      Kati.SecureStore.put("tmdb", "a-real-token")

      drawn = inspect(DataSources.wipe_confirm(true), limit: :infinity)

      assert drawn =~ "Wipe all tokens?"
      assert drawn =~ "wipe_confirm"
      assert drawn =~ "wipe_cancel"

      # Board 81: the sentence answers the question the destructive button
      # raises, before it asks it.
      assert drawn =~ "library, ratings and history are untouched"
    end

    test "and nothing is asked about when nothing is connected" do
      assert Sources.connected_count() == 0

      {:noreply, answered} = DataSources.handle_tap(:wipe_tokens, mounted())

      refute answered.assigns.confirm_wipe?,
             "a confirmation was raised over an event that cannot happen"

      assert answered.assigns.wipe_notice == "Nothing is connected."
    end
  end

  describe "the second tap" do
    test "is the one that wipes, and says how many went" do
      {:noreply, done} =
        DataSources.handle_tap(
          :wipe_confirm,
          Mob.Socket.assign(mounted(), :confirm_wipe?, true)
        )

      refute done.assigns.confirm_wipe?
      assert is_binary(done.assigns.wipe_notice)

      refute match?({:ok, t} when is_binary(t) and t != "", Kati.SecureStore.get("tmdb")),
             "the confirmed wipe did not wipe"

      if @store? do
        Kati.SecureStore.put("tmdb", "a-real-token")
        count = Sources.connected_count()

        {:noreply, asked} = DataSources.handle_tap(:wipe_tokens, mounted())
        {:noreply, wiped} = DataSources.handle_tap(:wipe_confirm, asked)

        assert wiped.assigns.wipe_notice =~ to_string(count)
      end
    end

    test "and Keep them keeps them, and asks nothing further" do
      {:noreply, kept} =
        DataSources.handle_tap(
          :wipe_cancel,
          Mob.Socket.assign(mounted(), :confirm_wipe?, true)
        )

      refute kept.assigns.confirm_wipe?

      if @store? do
        Kati.SecureStore.put("tmdb", "a-real-token")

        {:noreply, asked} = DataSources.handle_tap(:wipe_tokens, mounted())
        {:noreply, still_there} = DataSources.handle_tap(:wipe_cancel, asked)

        refute still_there.assigns.confirm_wipe?
        assert {:ok, "a-real-token"} = Kati.SecureStore.get("tmdb")
      end
    end
  end

  describe "the count" do
    test "is the reader's own, and zero when there is nothing" do
      # Board 81 writes `Three accounts` as a word, and its moduledoc's reason —
      # a specimen would count to zero — is an argument about a DRAWING. On a
      # live screen zero is the answer that stops the row offering to destroy
      # nothing.
      assert Sources.connected_count() == 0

      if @store? do
        Kati.SecureStore.put("tmdb", "a-real-token")
        assert Sources.connected_count() == 1

        Sources.disconnect_all()
        assert Sources.connected_count() == 0
      end
    end
  end
end
