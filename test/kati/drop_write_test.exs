defmodule Kati.DropWriteTest do
  @moduledoc """
  Dropping a show says whether it was dropped.

  `update_tracked/2` ran `Ash.update/2`, threw the result away and rescued a
  raise to `:ok`, so a refused drop and a successful one were the same thing to
  look at: the sheet flipped to its *Dropped* face and announced a change that
  had not been made. MOVIES-AND-TV.md #57.

  The `rescue` stays, and it matters that it does — an `Ash.Changeset` error is
  a value and a raise is not, and a sheet that died inside a tap handler would
  take the screen process with it. What changed is that both now reach the
  socket instead of being flattened to `:ok`.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Screens.DropSheet

  @prefix "drop-write-"

  setup do
    on_exit(fn ->
      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
    end)

    :ok
  end

  describe "a write that lands" do
    setup do
      %{tracked: tracked!(:paused)}
    end

    test "sets the status and clears any refusal", %{tracked: tracked} do
      {:noreply, after_tap} = DropSheet.handle_info({:tap, :drop}, sheet_for(tracked))

      assert after_tap.assigns.save_error == nil
      assert after_tap.assigns.dropped?

      assert Ash.get!(TrackedTitle, tracked.id).status == :dropped
    end

    test "and *still on it* pops", %{tracked: tracked} do
      {:noreply, after_tap} = DropSheet.handle_info({:tap, :keep}, sheet_for(tracked))

      assert after_tap.__mob__.nav_action == {:pop}
      assert Ash.get!(TrackedTitle, tracked.id).status == :watching
    end
  end

  describe "a write that cannot land" do
    setup do
      tracked = tracked!(:paused)
      socket = sheet_for(tracked)

      # The row is gone by the time the button is pressed — the sheet was
      # opened, the title removed on another screen, and the tap arrives
      # against a stale struct. `Ash.update/2` raises for this, which is the
      # branch the old `rescue _ -> :ok` swallowed whole.
      Ash.destroy!(tracked)

      %{socket: socket, tracked: tracked}
    end

    test "says so rather than announcing a drop", %{socket: socket} do
      {:noreply, after_tap} = DropSheet.handle_info({:tap, :drop}, socket)

      assert is_binary(after_tap.assigns.save_error)

      refute after_tap.assigns.dropped?,
             "the sheet flipped to its Dropped face over a write that did not happen"
    end

    test "and draws the message", %{socket: socket} do
      {:noreply, after_tap} = DropSheet.handle_info({:tap, :drop}, socket)

      drawn = inspect(DropSheet.render(after_tap.assigns), limit: :infinity)

      assert drawn =~ after_tap.assigns.save_error
    end

    test "a refused *still on it* stays on the sheet", %{socket: socket} do
      {:noreply, after_tap} = DropSheet.handle_info({:tap, :keep}, socket)

      assert after_tap.__mob__.nav_action == nil,
             "popping would take the message with it and land the reader on an " <>
               "unchanged page with nothing to explain why"

      assert is_binary(after_tap.assigns.save_error)
    end
  end

  describe "the drawn sheet" do
    test "has no row to write against, and that is not a refusal" do
      {:ok, socket} = DropSheet.mount(%{}, %{}, Mob.Socket.new(DropSheet))

      {:noreply, after_tap} = DropSheet.handle_info({:tap, :drop}, socket)

      assert after_tap.assigns.save_error == nil,
             "board 149 has no tracked row by design, and *that did not save* over a " <>
               "drawing is an error message about a picture"

      assert after_tap.assigns.dropped?
    end
  end

  defp sheet_for(tracked) do
    {:ok, socket} =
      DropSheet.mount(%{title_id: tracked.id}, %{}, Mob.Socket.new(DropSheet))

    socket
  end

  defp tracked!(status) do
    source_id = @prefix <> "one"

    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: source_id,
      kind: :tv,
      title: "The Quiet Ones",
      fetched_at: Kati.Time.now()
    })

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: source_id,
      kind: :tv,
      status: status
    })
  end
end
