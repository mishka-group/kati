defmodule Kati.DataSourcesKeyTest do
  @moduledoc """
  The reader brings their own TMDB token, and the app asks for it.

  The owner's decision: *"all users must put their token there."* A key of
  Kati's own used to be compiled into development builds and offered on screen
  80 as a choice beside the reader's; it is gone. The reader's own token, saved
  in `Kati.SecureStore`, is the only TMDB key there is, and a missing key is a
  door to screen 80 wherever a search would have failed.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Screens.DataSources
  alias Kati.UI.TmdbPrompt

  describe "screen 80" do
    setup do
      was = System.get_env("TMDB_READ_TOKEN")
      Application.delete_env(:kati, :tmdb_test_token)

      on_exit(fn ->
        if was,
          do: System.put_env("TMDB_READ_TOKEN", was),
          else: System.delete_env("TMDB_READ_TOKEN")
      end)

      :ok
    end

    test "offers no key of Kati's own, and no chip to choose one" do
      drawn = inspect(tree(mount_screen(DataSources)), limit: :infinity)

      assert drawn =~ "TMDB"
      refute drawn =~ "Use Kati’s key"
      refute drawn =~ "key_kati"
      refute drawn =~ "key_own"
    end

    test "with no token of the reader's, there is no key — whatever the environment holds" do
      System.put_env("TMDB_READ_TOKEN", "an-environment-token")

      assert Kati.Media.Tmdb.key() == {:error, :no_api_key}
      refute Kati.Media.Tmdb.usable?()
    end

    test "and the paragraph under the card says how to get one" do
      drawn = inspect(DataSources.tmdb(), limit: :infinity)

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

    test "and it opens screen 80, whose pill names the page it returns to" do
      socket = TmdbPrompt.open(Mob.Socket.new(Kati.Screens.Home), "Home")

      assert {:push, DataSources, %{back: "Home"}} = socket.__mob__.nav_action
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
