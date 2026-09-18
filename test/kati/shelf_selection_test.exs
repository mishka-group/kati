defmodule Kati.ShelfSelectionTest do
  @moduledoc """
  Screen 146 — selection mode that selects your own shelf, and writes.

  MOVIES-AND-TV.md #27: *"Selection mode operates on a fixture shelf and every
  action — select, Status, Remove, Undo — mutates assigns only; nothing reaches
  the store, so nothing survives closing the screen."*

  Two halves, and the second is the one with teeth. Reading the real shelf is
  a one-line swap; making Remove *remove* means a destroy, and a destroy means
  Undo cannot be an undelete. It re-creates, from the `{source, source_id}`
  pair the row was keyed on — so the new row finds the same cached title, the
  same episodes and the same ticks, and the only thing that changed is the id.
  Which is why Undo re-reads the shelf instead of putting its own stale shapes
  back: tiles tagged with ids the store no longer has draw perfectly and do
  nothing.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Screens.ShelfSelection

  @prefix "shelf-selection-"

  setup do
    on_exit(fn ->
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

  describe "the shelf it selects from" do
    test "is empty when nothing is tracked, not the drawing's nine" do
      titles = ShelfSelection.shelf()

      assert titles == [],
             "a reader with nothing shelved was offered the board's own nine tiles to " <>
               "select from, two of them pre-selected"

      refute Enum.any?(titles, & &1.selected?)
    end

    test "is the user's when there is one, with nothing selected" do
      shelve!("Severance", :tv)

      titles = ShelfSelection.shelf()

      assert Enum.map(titles, & &1.title) == ["Severance"]
      refute Enum.any?(titles, & &1.selected?)
    end

    test "carries the pair a row is keyed on, which Undo needs" do
      shelve!("Severance", :tv)

      assert [%{source: :tmdb, source_id: source_id}] = ShelfSelection.shelf()
      assert source_id == @prefix <> "Severance"
    end
  end

  describe "Status" do
    test "writes the status, so it survives leaving the screen" do
      tracked = shelve!("Severance", :tv)
      [row] = ShelfSelection.shelf()

      assert :ok = ShelfSelection.write_status(row)

      assert {:ok, %{status: :finished}} = Ash.get(TrackedTitle, tracked.id)
    end

    test "and flips back off a finished title" do
      tracked = shelve!("Severance", :tv)
      [row] = ShelfSelection.shelf()
      :ok = ShelfSelection.write_status(row)

      [again] = ShelfSelection.shelf()
      assert again.done?
      assert :ok = ShelfSelection.write_status(again)

      assert {:ok, %{status: :watching}} = Ash.get(TrackedTitle, tracked.id)
    end

    test "writes nothing for a row that names no tracked title" do
      # There is no drawn row to take the head of any more — `shelf/0` answers
      # `[]` on an empty store. The guard this was testing is still the one that
      # matters: a row carrying no id must not reach a write.
      assert ShelfSelection.shelf() == []
      assert :ok = ShelfSelection.write_status(%{id: nil, status: :watching})
      assert Ash.read!(TrackedTitle) == []
    end
  end

  describe "Remove" do
    test "takes the title off the shelf for real" do
      shelve!("Severance", :tv)
      removed = ShelfSelection.shelf()

      assert :ok = ShelfSelection.write_removals(removed)
      assert Ash.read!(TrackedTitle) == []
    end

    test "leaves the cached title behind, so Undo has something to key to" do
      shelve!("Severance", :tv)
      :ok = ShelfSelection.write_removals(ShelfSelection.shelf())

      assert [%{title: "Severance"}] =
               Ash.read!(CachedTitle) |> Enum.filter(&String.starts_with?(&1.source_id, @prefix))
    end

    test "and removing what is already gone is not an error" do
      shelve!("Severance", :tv)
      removed = ShelfSelection.shelf()

      assert :ok = ShelfSelection.write_removals(removed)
      assert :ok = ShelfSelection.write_removals(removed)
    end
  end

  describe "Undo" do
    test "puts the title back on the shelf" do
      shelve!("Severance", :tv)
      removed = ShelfSelection.shelf()
      :ok = ShelfSelection.write_removals(removed)

      assert :ok = ShelfSelection.write_restorations(removed)
      assert [%{title: "Severance"}] = ShelfSelection.shelf()
    end

    test "under a new id, which is why the ids are looked up again" do
      shelve!("Severance", :tv)
      removed = ShelfSelection.shelf()
      :ok = ShelfSelection.write_removals(removed)
      :ok = ShelfSelection.write_restorations(removed)

      titles = ShelfSelection.shelf()
      restored = ShelfSelection.restored_ids(titles, removed)

      assert MapSet.size(restored) == 1
      assert MapSet.to_list(restored) == Enum.map(titles, & &1.id)
      refute MapSet.to_list(restored) == Enum.map(removed, & &1.id)
    end

    test "keeps a finished title finished" do
      shelve!("Severance", :tv)
      [row] = ShelfSelection.shelf()
      :ok = ShelfSelection.write_status(row)

      removed = ShelfSelection.shelf()
      :ok = ShelfSelection.write_removals(removed)
      :ok = ShelfSelection.write_restorations(removed)

      assert [%{done?: true}] = ShelfSelection.shelf()
    end

    test "restores nothing for a drawn row" do
      drawn = ShelfSelection.shelf()

      assert :ok = ShelfSelection.write_restorations(drawn)
      assert Ash.read!(TrackedTitle) == []
    end
  end

  describe "board 147's rule at 235%" do
    test "the count grows and the chrome caps" do
      # MOVIES-AND-TV.md #6. Board 147 is this bar at the largest text size and
      # states the split: *`4 selected` carries no `max_lines` and no cap — the
      # board's own caption names it as the one thing this bar exists to say* —
      # while *the close glyph caps because it is chrome whose size carries
      # structure*. Both lines of the count carried `max_lines={1}`.
      one = inspect(ShelfSelection.count_body(1), limit: :infinity)
      four = inspect(ShelfSelection.count_body(4), limit: :infinity)

      refute one =~ "max_lines", "the one thing this bar exists to say can clip"
      refute four =~ "max_lines"
      assert four =~ "4 selected"
      assert four =~ "Actions apply to all four"

      # And the glyph beside it does not grow with the text.
      assert inspect(ShelfSelection.close_glyph(true), limit: :infinity) =~ "max_font_scale"
      assert inspect(ShelfSelection.close_glyph(false), limit: :infinity) =~ "max_font_scale"
    end
  end

  defp shelve!(title, kind) do
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
      status: :watching
    })
  end
end
