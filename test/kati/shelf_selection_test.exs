defmodule Kati.ShelfSelectionTest do
  @moduledoc """
  Screen 146 selects the reader's own shelf and acts on it (#120).

  It drew the design board around the live bar — a still Library header, an
  *ONE SELECTED* bar with dead buttons, a frozen *Removed 4 titles* pill, two
  notes about the board — and its Status flipped one title between finished and
  watching, losing whatever it was. Remove destroyed at once, so Undo brought a
  title back with none of its history.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Screens.ShelfSelection

  doctest Kati.Screens.ShelfSelection, only: [count_line: 1]
  doctest Kati.Screens.Library, only: [hold_tag: 1]

  @prefix "shelf-selection-"

  setup do
    Mob.State.put(:pending_removals, [])
    Kati.Library.ShelfFilters.put(Kati.Library.ShelfFilters.resting())

    on_exit(fn ->
      Mob.State.put(:pending_removals, [])

      Kati.Repo.query!(
        "DELETE FROM media_watches WHERE tracked_title_id IN " <>
          "(SELECT id FROM tracked_titles WHERE source_id LIKE ?1)",
        [@prefix <> "%"]
      )

      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
    end)

    :ok
  end

  defp shelve!(title, kind, status \\ :watching) do
    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: @prefix <> title,
      kind: kind,
      title: title,
      fetched_at: Kati.Time.now()
    })

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: @prefix <> title,
      kind: kind,
      status: status
    })
  end

  defp tag(row), do: String.to_atom("open_" <> kind_word(row) <> "_" <> row.id)
  defp kind_word(%{kind: :movie}), do: "film"
  defp kind_word(_row), do: "series"

  defp tags(view) do
    for %{props: %{on_tap: {_pid, tag}}} <- flatten(view), is_atom(tag), do: tag
  end

  defp row(id), do: Ash.get!(TrackedTitle, id)

  describe "what is drawn" do
    test "none of the design board's stills: no frozen bars, no notes, no fake count" do
      shelve!("Severance", :tv)
      words = text(mount_screen(ShelfSelection))

      for still <- [
            "Resting header",
            "One selected",
            "ONE SELECTED",
            "Removed 4 titles",
            "Sort persists",
            "Selection survives",
            "Undo — every destructive action"
          ] do
        refute words =~ still, "the screen still draws the board's #{inspect(still)}"
      end

      assert words =~ "Select titles"
      assert words =~ "Tap titles to select them"
    end

    test "an empty shelf says so instead of drawing a grid" do
      assert text(mount_screen(ShelfSelection)) =~ "Nothing on your shelf yet"
    end

    test "the actions are inert until something is selected" do
      shelve!("Severance", :tv)
      view = mount_screen(ShelfSelection)

      refute :remove_selected in tags(view)
      refute :add_to_list in tags(view)
      refute :change_status in tags(view)
    end
  end

  describe "selecting" do
    test "a tap toggles a title, and the count follows" do
      a = shelve!("Severance", :tv)
      view = mount_screen(ShelfSelection) |> render_info({:tap, tag(a)})

      assert assigns(view).selected == MapSet.new([a.id])
      assert text(view) =~ "1 selected"
      assert Enum.all?([:remove_selected, :add_to_list, :change_status], &(&1 in tags(view)))

      view = render_info(view, {:tap, tag(a)})
      assert assigns(view).selected == MapSet.new()
    end

    test "a long press on the Library opens this with that title already selected" do
      a = shelve!("Severance", :tv)

      library = mount_screen(Kati.Screens.Library)
      hold = String.to_atom("select_" <> a.id)

      assert Enum.any?(flatten(library), &match?(%{props: %{on_long_press: {_, ^hold}}}, &1))

      view = render_info(library, {:long_press, hold})
      assert {:push, Kati.Screens.ShelfSelection, %{selected: id}} = view.socket.__mob__.nav_action
      assert id == a.id

      assert assigns(mount_screen(ShelfSelection, %{selected: a.id})).selected ==
               MapSet.new([a.id])
    end

    test "Select all takes every title the chips show, and turns into Clear" do
      a = shelve!("Severance", :tv)
      b = shelve!("Dune", :movie)

      view = mount_screen(ShelfSelection) |> render_info({:tap, :select_all})
      assert assigns(view).selected == MapSet.new([a.id, b.id])
      assert :clear_selection in tags(view)

      view = render_info(view, {:tap, :clear_selection})
      assert assigns(view).selected == MapSet.new()
    end

    test "Select all under a chip takes only what that chip shows" do
      _watching = shelve!("Severance", :tv, :watching)
      waiting = shelve!("Dune", :movie, :not_started)

      view =
        mount_screen(ShelfSelection)
        |> render_info({:tap, :filter_not_started})
        |> render_info({:tap, :select_all})

      assert assigns(view).selected == MapSet.new([waiting.id])
    end
  end

  describe "Status" do
    test "sets the chosen status on every selected title, whatever each one was" do
      a = shelve!("Severance", :tv, :paused)
      b = shelve!("Dune", :movie, :not_started)

      view =
        mount_screen(ShelfSelection)
        |> render_info({:tap, :select_all})
        |> render_info({:tap, :change_status})

      assert :set_status_finished in tags(view)

      view = render_info(view, {:tap, :set_status_finished})
      assert row(a.id).status == :finished
      assert row(b.id).status == :finished
      refute assigns(view).status_open?

      render_info(view, {:tap, :change_status}) |> render_info({:tap, :set_status_paused})
      assert row(a.id).status == :paused
    end
  end

  describe "Remove and Undo" do
    test "Remove takes the titles off the shelf at once and leaves an Undo" do
      a = shelve!("Severance", :tv)

      view =
        mount_screen(ShelfSelection)
        |> render_info({:tap, tag(a)})
        |> render_info({:tap, :remove_selected})

      assert assigns(view).titles == []
      assert text(view) =~ "Removed 1 title"
      assert :undo in tags(view)
      assert row(a.id).archived
      assert Mob.State.get(:pending_removals) == [a.id]
      assert Kati.Screens.Library.shelf() |> Enum.filter(&(&1.id == a.id)) == []
    end

    test "Undo puts the title back with its history, in its place on the shelf" do
      a = shelve!("Severance", :tv)
      Ash.create!(Watch, %{tracked_title_id: a.id, watched_at: Kati.Time.now()})
      touched = row(a.id).last_touched_at

      view =
        mount_screen(ShelfSelection)
        |> render_info({:tap, tag(a)})
        |> render_info({:tap, :remove_selected})
        |> render_info({:tap, :undo})

      restored = row(a.id)
      refute restored.archived
      assert restored.last_touched_at == touched
      assert [_watch] = Ash.read!(Watch) |> Enum.filter(&(&1.tracked_title_id == a.id))
      assert assigns(view).selected == MapSet.new([a.id])
      assert assigns(view).undo == nil
      assert Mob.State.get(:pending_removals) == []
    end

    test "back on the Library, a Remove nobody undid is final" do
      a = shelve!("Severance", :tv)

      mount_screen(ShelfSelection)
      |> render_info({:tap, tag(a)})
      |> render_info({:tap, :remove_selected})

      mount_screen(Kati.Screens.Library) |> render_info({:kati, :resumed, nil})

      assert {:error, _gone} = Ash.get(TrackedTitle, a.id)
      assert Mob.State.get(:pending_removals) == []
    end

    test "a second Remove ends the first one's window" do
      a = shelve!("Severance", :tv)
      b = shelve!("Dune", :movie)

      view =
        mount_screen(ShelfSelection)
        |> render_info({:tap, tag(a)})
        |> render_info({:tap, :remove_selected})
        |> render_info({:tap, tag(b)})
        |> render_info({:tap, :remove_selected})

      assert {:error, _gone} = Ash.get(TrackedTitle, a.id)
      assert row(b.id).archived
      assert assigns(view).undo.ids == [b.id]
    end

    test "✕ ends the window too" do
      a = shelve!("Severance", :tv)

      mount_screen(ShelfSelection)
      |> render_info({:tap, tag(a)})
      |> render_info({:tap, :remove_selected})
      |> render_info({:tap, :close})

      assert {:error, _gone} = Ash.get(TrackedTitle, a.id)
    end

    test "an app closed inside the window still removes them at the next start" do
      a = shelve!("Severance", :tv)
      :ok = ShelfSelection.archive([a.id], true)
      ShelfSelection.remember_pending([a.id])

      ShelfSelection.finalize_pending()

      assert {:error, _gone} = Ash.get(TrackedTitle, a.id)
    end

    test "a pending id that was restored meanwhile is left alone" do
      a = shelve!("Severance", :tv)
      ShelfSelection.remember_pending([a.id])

      ShelfSelection.finalize_pending()

      assert {:ok, _kept} = Ash.get(TrackedTitle, a.id)
      assert Mob.State.get(:pending_removals) == []
    end
  end

  describe "one selection, every action in turn" do
    test "Status, then Remove, then Undo" do
      a = shelve!("Severance", :tv)
      b = shelve!("Dune", :movie)

      view =
        mount_screen(ShelfSelection, %{selected: a.id})
        |> render_info({:tap, tag(b)})
        |> render_info({:tap, :change_status})
        |> render_info({:tap, :set_status_paused})
        |> render_info({:tap, :remove_selected})

      assert assigns(view).save_error == nil
      assert :undo in tags(view)
      assert row(a.id).archived and row(b.id).archived

      view = render_info(view, {:tap, :undo})
      refute row(a.id).archived or row(b.id).archived
      assert row(a.id).status == :paused
      assert assigns(view).selected == MapSet.new([a.id, b.id])
    end
  end

  describe "Add to list" do
    test "carries the whole selection to the list picker" do
      a = shelve!("Severance", :tv)
      b = shelve!("Dune", :movie)

      view =
        mount_screen(ShelfSelection)
        |> render_info({:tap, :select_all})
        |> render_info({:tap, :add_to_list})

      assert {:push, Kati.Screens.AddToList, %{members: members}} = view.socket.__mob__.nav_action
      assert Enum.sort(members) == Enum.sort([{:tracked_title, a.id}, {:tracked_title, b.id}])
    end
  end
end
