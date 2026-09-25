defmodule Kati.DataSourcesKeyTest do
  @moduledoc """
  The reader brings their own TMDB token, and the app asks for it.

  The owner's decision, 19 Sep: *"user must put its token, not my code."* The
  default was Kati's key, so a fresh install silently used whatever was compiled
  into the build — and a public build has none, so the first film search came
  back empty with nothing saying why. Now the reader's own key is the default,
  Kati's key is offered only on a build that carries one, and a missing key is
  a door to screen 80 wherever a search would have failed.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Screens.DataSources
  alias Kati.UI.TmdbPrompt

  describe "screen 80's key chips" do
    test "are offered on a build that carries Kati's key" do
      drawn = inspect(DataSources.key_chips(:own, true), limit: :infinity)

      assert drawn =~ "Use Kati’s key"
      assert drawn =~ "Use my own key"

      # Only the chip NOT in force carries a tap — `key_chip/3`'s own rule.
      assert drawn =~ "key_kati"
      refute drawn =~ "key_own"
    end

    test "and are not offered where there is none to choose" do
      # Offering *Use Kati's key* on a build without one would switch search
      # off with a single tap.
      drawn = inspect(DataSources.key_chips(:own, false), limit: :infinity)

      refute drawn =~ "Use Kati’s key"
      refute drawn =~ "key_kati"
    end

    test "and the paragraph under them no longer argues against the decision" do
      drawn = inspect(DataSources.tmdb(:own), limit: :infinity)

      refute drawn =~ "Paste your own only if"
      assert drawn =~ "API Read Access Token"
    end
  end

  describe "the Home prompt" do
    test "is drawn when no search could run" do
      drawn = inspect(TmdbPrompt.block(false), limit: :infinity)

      assert drawn =~ "Add your TMDB token"
      assert drawn =~ "add_tmdb_token"
    end

    test "and is gone once a key is usable" do
      refute inspect(TmdbPrompt.block(true), limit: :infinity) =~ "add_tmdb_token"
    end

    test "and it opens screen 80" do
      socket = TmdbPrompt.open(Mob.Socket.new(Kati.Screens.Home))

      assert {:push, DataSources, _params} = socket.__mob__.nav_action
    end

    test "and Home answers the tap" do
      {:noreply, socket} =
        Kati.Screens.Home.handle_tap(:add_tmdb_token, Mob.Socket.new(Kati.Screens.Home))

      assert {:push, DataSources, _params} = socket.__mob__.nav_action
    end
  end

  describe "screen 06" do
    test "a missing key is a door, not only a sentence" do
      message = Kati.Media.Tmdb.message(:no_api_key)

      drawn =
        inspect(Kati.Screens.AddTitle.search_notice(message, :no_api_key), limit: :infinity)

      assert drawn =~ "open_data_sources"
    end

    test "and any other failure stays a sentence" do
      message = Kati.Media.Tmdb.message(:blocked)

      refute inspect(Kati.Screens.AddTitle.search_notice(message, :blocked), limit: :infinity) =~
               "open_data_sources"
    end
  end
end
