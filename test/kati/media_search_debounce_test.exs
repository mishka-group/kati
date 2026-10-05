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
end
