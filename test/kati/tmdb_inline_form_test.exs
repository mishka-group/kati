defmodule Kati.TmdbInlineFormTest do
  @moduledoc """
  The TMDB token form on the page that needs it (`Kati.UI.TmdbPrompt.inline/3`).

  The owner's rule, 27 Sep: with no token, Home and Discover suggest one and
  hold the form themselves — Save fills the page in where it stands, and Skip
  says what doing without costs (no films; series and anime from AniList and
  TVmaze, with less detail) and is remembered.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Screens.Discover
  alias Kati.Screens.Home
  alias Kati.UI.TmdbPrompt

  @skipped_line "Without a TMDB token Kati can’t bring you films. Series and anime still come from AniList and TVmaze, with less detail."

  setup do
    Kati.Locale.put(:en)
    Application.delete_env(:kati, :tmdb_test_token)
    Mob.State.put(:tmdb_prompt_skipped, false)
    :ok
  end

  describe "on Home with no token" do
    test "the form is drawn in place, with Save, Skip and a way to get one" do
      view = mount_screen(Home, %{})
      tags = tap_tags(view)

      assert "Add your TMDB token" in texts(view)
      assert :inline_save_token in tags
      assert :skip_tmdb_token in tags
      assert :get_tmdb_token in tags
      refute :add_tmdb_token in tags, "Home still sends the reader to another page for it"
    end

    test "Save on an empty field says so" do
      view = mount_screen(Home, %{}) |> render_info({:tap, :inline_save_token})
      assert "Paste a token first." in texts(view)
    end

    test "Save stores the token or says why it could not" do
      view =
        mount_screen(Home, %{})
        |> render_info({:change, :inline_tmdb_token, "  eyJ.test.token  "})
        |> render_info({:tap, :inline_save_token})

      form = assigns(view).tmdb_form

      assert assigns(view).tmdb_ready == true or is_binary(form.error)
      if assigns(view).tmdb_ready == true, do: assert(form.token == "")
    end

    test "Skip says what is missing and what still works, and is remembered" do
      view = mount_screen(Home, %{}) |> render_info({:tap, :skip_tmdb_token})

      assert @skipped_line in texts(view)
      refute :inline_save_token in tap_tags(view)
      assert TmdbPrompt.skipped?()

      again = mount_screen(Home, %{})
      assert @skipped_line in texts(again), "the skip was forgotten on the next visit"
    end

    test "Add a token under the note brings the form back" do
      view =
        mount_screen(Home, %{})
        |> render_info({:tap, :skip_tmdb_token})
        |> render_info({:tap, :tmdb_unskip})

      assert :inline_save_token in tap_tags(view)
      refute TmdbPrompt.skipped?()
    end

    test "Get a token says what happened" do
      view = mount_screen(Home, %{}) |> render_info({:tap, :get_tmdb_token})
      assert assigns(view).tmdb_form.opened in [:ok, :failed]
    end
  end

  describe "with a token" do
    test "Home draws no form" do
      Application.put_env(:kati, :tmdb_test_token, "test-token")
      on_exit(fn -> Application.delete_env(:kati, :tmdb_test_token) end)

      refute :inline_save_token in tap_tags(mount_screen(Home, %{}))
    end
  end

  describe "on Discover with no token" do
    test "the form is on the page, and Skip leaves the note" do
      view = mount_screen(Discover, %{})
      assert :inline_save_token in tap_tags(view)

      view = render_info(view, {:tap, :skip_tmdb_token})
      assert @skipped_line in texts(view)
    end
  end

  describe "in Persian" do
    test "the form and the note are Persian" do
      drawn =
        Kati.Locale.as(:fa, fn ->
          inspect(TmdbPrompt.inline(false, nil, false)) <> inspect(TmdbPrompt.skipped_note())
        end)

      refute drawn =~ "Add your TMDB token"
      refute drawn =~ "Without a TMDB token"
    end
  end

  defp tap_tags(view) do
    for node <- flatten(view),
        {_pid, tag} <- [Map.get(Map.get(node, :props) || %{}, :on_tap)],
        is_atom(tag),
        do: tag
  end

  defp texts(view) do
    view
    |> flatten()
    |> Enum.flat_map(fn node ->
      case Map.get(node, :props) || %{} do
        %{text: text} when is_binary(text) -> [text]
        _other -> []
      end
    end)
  end
end
