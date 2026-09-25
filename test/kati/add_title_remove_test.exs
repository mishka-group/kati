defmodule Kati.AddTitleRemoveTest do
  @moduledoc """
  Removing a title you added, and being told when a write did not happen.

  ## #41 — the remove that removed nothing

  `untrack/1` looked for `source == :manual and source_id == title`, which is
  the pair a HAND-TYPED title is stored under. `track/2` stores a TMDB title
  under `{:tmdb, "329865"}` — deliberately, because the cached episodes
  reference the provider id — so removing something added from TMDB found
  nothing, answered `{:ok, :already_gone}`, and reported success. The check
  flipped back to a `+`, the row stayed in the library forever, and the next
  tap on the same result tried to add it again.

  ## #42 — every failure was silent

  `:save_error` was assigned in three places on screen 06 and drawn in none.
  Adding a duplicate, or removing something that would not delete, redrew the
  page identically.

  Both were filed as `lies-to-user`, and neither could be seen by a
  sweep: `Kati.ScreenTapSweepTest` runs against an empty store, where there is
  no tracked row for a remove to miss.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Screens.AddTitle

  doctest AddTitle, only: [tracked_key: 2]

  @prefix "add-title-remove-"

  setup do
    on_exit(fn ->
      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id = ?1", ["Typed By Hand"])
    end)

    :ok
  end

  describe "the key a remove looks under" do
    test "is the provider's, for a row that came from TMDB" do
      assert AddTitle.tracked_key("Arrival", %{source: :tmdb, source_id: "329865"}) ==
               {:tmdb, "329865"}
    end

    test "and the title, for everything else" do
      assert AddTitle.tracked_key("The Quiet Coast", nil) == {:manual, "The Quiet Coast"}
      assert AddTitle.tracked_key("Hand typed", %{title: "Hand typed"}) == {:manual, "Hand typed"}
      assert AddTitle.tracked_key("No id", %{source: :tmdb, source_id: ""}) == {:manual, "No id"}
    end
  end

  describe "removing a title that came from TMDB" do
    setup do
      tracked!(@prefix <> "329865")
      :ok
    end

    test "actually removes it" do
      row = %{source: :tmdb, source_id: @prefix <> "329865", title: "Arrival"}

      assert {:ok, :removed} = AddTitle.untrack("Arrival", row)
      assert tracked_ids() == []
    end

    test "and looking under the title alone finds nothing, which was the defect" do
      assert {:ok, :already_gone} = AddTitle.untrack("Arrival", nil)

      assert tracked_ids() == [@prefix <> "329865"],
             "the row was deleted by the old key, so this test proves nothing"
    end
  end

  describe "removing a hand-typed title" do
    test "still looks under the title, which is what it is stored as" do
      Ash.create!(TrackedTitle, %{
        source: :manual,
        source_id: "Typed By Hand",
        kind: :movie,
        status: :watching
      })

      assert {:ok, :removed} = AddTitle.untrack("Typed By Hand", %{title: "Typed By Hand"})
    end
  end

  describe "a write the screen refused" do
    test "is drawn rather than swallowed" do
      assigns = %{
        results: [],
        filter: "Everything",
        query: "",
        query_epoch: 0,
        save_error: "That did not save. Your text is still here — try again.",
        search_error: nil
      }

      drawn = inspect(AddTitle.render(assigns), limit: :infinity, printable_limit: :infinity)

      assert drawn =~ "That did not save."
    end

    test "and a page with nothing wrong draws no band" do
      {:ok, socket} = AddTitle.mount(%{}, %{}, Mob.Socket.new(AddTitle))

      assert socket.assigns.save_error == nil
      assert AddTitle.save_notice(nil) == []
    end
  end

  defp tracked_ids do
    TrackedTitle
    |> Ash.read!()
    |> Enum.map(& &1.source_id)
    |> Enum.filter(&String.starts_with?(&1, @prefix))
  end

  defp tracked!(source_id) do
    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: source_id,
      kind: :movie,
      title: "Arrival",
      fetched_at: Kati.Time.now()
    })

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: source_id,
      kind: :movie,
      status: :watching
    })
  end
end
