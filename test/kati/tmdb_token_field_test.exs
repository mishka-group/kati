defmodule Kati.TmdbTokenFieldTest do
  @moduledoc """
  *Use my own key* now has a key to use.

  Tapping that chip wrote `:own` to `Mob.State` and there was nowhere on screen
  80 — or anywhere in the app — to put a token. `Kati.Media.Tmdb.key/0` then
  routed to the always-empty secure store and answered `{:error, :no_api_key}`,
  so screen 06 stopped returning results and started drawing a notice pointing
  back at THIS page. One tap on a control that reads as a preference, and
  search was off with no way to switch it on. MOVIES-AND-TV.md #70.

  It is also the flow the app is built around: Kati ships no key of its own to
  a public build, so a reader creates a token on themoviedb.org and brings it
  in — and until now there was no *in*.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Screens.DataSources

  describe "the field" do
    test "is drawn only when the reader has chosen their own key" do
      under_own = inspect(DataSources.tmdb(:own, "", false, nil), limit: :infinity)
      under_kati = inspect(DataSources.tmdb(:kati, "", false, nil), limit: :infinity)

      refute under_kati =~ "tmdb_token",
             "there is nothing to enter under Kati's key, and board 80 is drawn in that state"

      # On a host with no encrypted store the field is withheld and the reason
      # is drawn instead — `Kati.SecureStore.available?/0` is checked BEFORE
      # the field is offered, which is the rule that module states in its own
      # words.
      if Kati.SecureStore.available?() do
        assert under_own =~ "tmdb_token"
      else
        assert under_own =~ "no encrypted store"
        refute under_own =~ "tmdb_token"
      end
    end
  end

  describe "saving" do
    test "an empty field is refused rather than silently ignored" do
      socket =
        DataSources
        |> Mob.Socket.new()
        |> Mob.Socket.assign(token: "   ", token_error: nil, token_saved?: false)

      {:noreply, after_tap} = DataSources.handle_tap(:save_token, socket)

      assert after_tap.assigns.token_error == "Paste a token first."
    end

    test "and a store that cannot hold it says so rather than reporting success" do
      socket =
        DataSources
        |> Mob.Socket.new()
        |> Mob.Socket.assign(token: "abc.def", token_error: nil, token_saved?: false)

      after_tap = DataSources.store_token(socket, "abc.def")

      # There is no native store on the host BEAM, which is exactly the
      # condition `Kati.SecureStore.available?/0` exists to surface. Either it
      # saved or it said why; what it must never do is neither.
      assert after_tap.assigns.token_saved? or is_binary(after_tap.assigns.token_error)
    end
  end

  describe "what the reader is told" do
    test "where to get a token, when none is stored" do
      drawn = inspect(DataSources.token_state(false, nil), limit: :infinity)

      assert drawn =~ "themoviedb.org"
      assert drawn =~ "read access token"
    end

    test "that one is stored, when one is" do
      drawn = inspect(DataSources.token_state(true, nil), limit: :infinity)

      assert drawn =~ "A token of yours is stored"
    end

    test "and a refusal wins over both" do
      drawn = inspect(DataSources.token_state(true, "That did not save."), limit: :infinity)

      assert drawn =~ "That did not save."
      refute drawn =~ "A token of yours is stored"
    end
  end

  describe "the typing" do
    test "reaches the assign" do
      socket = Mob.Socket.assign(Mob.Socket.new(DataSources), :token, "")

      {:noreply, typed} = DataSources.handle_info({:change, :tmdb_token, "abc"}, socket)

      assert typed.assigns.token == "abc"
    end
  end
end
