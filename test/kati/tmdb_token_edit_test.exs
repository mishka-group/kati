defmodule Kati.TmdbTokenEditTest do
  @moduledoc """
  A saved token is edited or cleared from the card, not from two loose pills.

  The owner, 26 Sep, on the Galaxy A55: Replace and Remove sat under the card
  as a plain pill and a pink one. Edit and Clear are rows of the card now;
  Edit opens the field with Cancel, and Clear asks with the app's own
  destructive confirmation before anything is deleted.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Screens.DataSources

  defp drawn(node), do: inspect(node, limit: :infinity)

  defp socket(assigns) do
    Enum.reduce(assigns, Mob.Socket.new(DataSources), fn {k, v}, acc ->
      Mob.Socket.assign(acc, k, v)
    end)
  end

  test "the saved card offers Edit and Clear, and no Replace or Remove pills" do
    Kati.Locale.put(:en)
    card = drawn(DataSources.key_in_use())

    assert card =~ "Edit token"
    assert card =~ "Clear token"
    assert card =~ "edit_token"
    assert card =~ "clear_token"
    refute card =~ "Replace"
    refute card =~ ~s("Remove")
  end

  test "Edit opens the field without clearing the store, and Cancel goes back" do
    {:noreply, editing} =
      DataSources.handle_tap(:edit_token, socket(token_saved?: true, token_epoch: 0))

    assert editing.assigns.editing?
    assert editing.assigns.token_saved?
    assert drawn(DataSources.key_field("", nil, 1, true)) =~ "edit_cancel"
    assert drawn(DataSources.key_field("", nil, 1, true)) =~ "save_token"

    {:noreply, back} = DataSources.handle_tap(:edit_cancel, editing)
    refute back.assigns.editing?
    assert back.assigns.token_saved?
  end

  test "Clear asks first, and Cancel on the question keeps the token" do
    Kati.Locale.put(:en)
    {:noreply, asking} = DataSources.handle_tap(:clear_token, socket(token_saved?: true))

    assert asking.assigns.confirm_clear?
    question = drawn(DataSources.clear_confirm())
    assert question =~ "Clear your TMDB token?"
    assert question =~ "clear_token_confirm"
    assert question =~ "clear_token_cancel"

    {:noreply, kept} = DataSources.handle_tap(:clear_token_cancel, asking)
    refute kept.assigns.confirm_clear?
    assert kept.assigns.token_saved?
  end

  test "a clear the store refuses says so and leaves the card as it was" do
    {:noreply, refused} =
      DataSources.handle_tap(
        :clear_token_confirm,
        socket(token_saved?: true, confirm_clear?: true)
      )

    refute refused.assigns.confirm_clear?
    assert refused.assigns.token_saved?
    assert is_binary(refused.assigns.token_error)
  end
end
