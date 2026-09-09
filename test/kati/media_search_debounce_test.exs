defmodule Kati.MediaSearchDebounceTest do
  @moduledoc """
  One TMDB request when the typing stops, not one per letter.

  `Kati.Screens.AddTitle` searched from its `{:change, :title_query, _}`
  handler, which the bridge sends on every keystroke — so typing `severance`
  made nine requests, eight of whose answers the ninth discarded. Reported from
  a device.

  What is pinned here is the decision, not the sleep: a keystroke asks, an
  answer comes back, and the screen searches only if that answer is still the
  one wanted. The network is never reached in this file — `Kati.Media.Tmdb`
  refuses without a key and these assertions are about which branch was taken.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Media.SearchDebounce
  alias Kati.Screens.AddTitle

  doctest Kati.Media.SearchDebounce, only: [delay: 0]

  describe "asking" do
    test "a keystroke sends its query back, once, after the delay" do
      SearchDebounce.ask(self(), "severance")

      refute_received {:search_ready, _query}, "it answered before the typing stopped"
      assert_receive {:search_ready, "severance"}, SearchDebounce.delay() * 4
      refute_receive {:search_ready, _again}, 50, "one ask, one answer"
    end

    test "nine keystrokes send nine answers, which is the point of the check below" do
      # The debounce does not stop the asks — it stops the REQUESTS, and it does
      # that in the screen by comparing each answer against what is now typed.
      # Asserted so nobody later "optimises" the asks away and breaks the
      # comparison that actually does the work.
      for q <- ["s", "se", "sev", "seve", "sever", "severa", "severan", "severanc", "severance"] do
        SearchDebounce.ask(self(), q)
      end

      answers =
        for _ <- 1..9 do
          assert_receive {:search_ready, q}, SearchDebounce.delay() * 6
          q
        end

      assert "severance" in answers
      assert length(answers) == 9
    end

    test "an answer for a screen that has gone away is dropped, not an error" do
      dead = spawn(fn -> :ok end)
      Process.sleep(20)
      refute Process.alive?(dead)

      assert SearchDebounce.ask(dead, "severance") == :ok
      Process.sleep(SearchDebounce.delay() * 2)
    end
  end

  describe "what the screen does with the answer" do
    setup do
      {:ok, socket} = AddTitle.mount(%{}, %{}, Mob.Socket.new(AddTitle))
      %{socket: socket}
    end

    test "a stale answer is dropped before the network is touched", %{socket: socket} do
      typed = Mob.Socket.assign(socket, :query, "severance")

      # `sev` arrived late: the field says `severance` now.
      {:noreply, after_stale} = AddTitle.handle_info({:search_ready, "sev"}, typed)

      assert after_stale.assigns.results == typed.assigns.results,
             "a stale query changed the results"
    end

    test "an answer for a query the field has since emptied is dropped", %{socket: socket} do
      cleared = Mob.Socket.assign(socket, :query, "")

      {:noreply, after_cleared} = AddTitle.handle_info({:search_ready, "severance"}, cleared)

      assert after_cleared.assigns.results == cleared.assigns.results
    end

    test "an answer below the floor is dropped even though it was once asked", %{socket: socket} do
      # Type `sev`, delete a letter: `se` is under the three-character floor and
      # a request for it should not be made late either.
      shortened = Mob.Socket.assign(socket, :query, "se")

      {:noreply, after_short} = AddTitle.handle_info({:search_ready, "se"}, shortened)

      assert after_short.assigns.results == shortened.assigns.results
    end

    test "the current query is searched, and says so when there is no key", %{socket: socket} do
      # No TMDB key in `:test` — `Kati.Media.Tmdb` guards `@bundled_key` on
      # `Mix.env/0` — so this asserts the branch was ENTERED, by the refusal it
      # leaves behind. A dropped answer would leave `:search_error` nil.
      typed = Mob.Socket.assign(socket, :query, "severance")

      {:noreply, searched} = AddTitle.handle_info({:search_ready, "severance"}, typed)

      assert searched.assigns.search_error,
             "the live query was not searched — the debounce is dropping everything"
    end

    test "typing itself never searches", %{socket: socket} do
      {:noreply, after_typing} =
        AddTitle.handle_info({:change, :title_query, "severance"}, socket)

      assert after_typing.assigns.query == "severance"

      refute after_typing.assigns.search_error,
             "the keystroke handler reached the network; the debounce is bypassed"
    end
  end
end
