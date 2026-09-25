defmodule Kati.RemoveWatchedTitleTest do
  @moduledoc """
  A title you have watched can be removed from the library.

  `media_watches.tracked_title_id` referenced `tracked_titles(id)` with no
  `ON DELETE` action, so SQLite refused to delete any title that had ever been
  watched. Both doors failed — the ⋯ *Remove* row on screen 04 and screen 06's
  untick — with *"Referenced something that does not exist"*, and the title
  stayed. Found on the owner's A55 with *Marram*.

  The owner's decision was a full delete, so these assert the history goes too.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Media.ContentWarning
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch

  @prefix "remove-watched-"

  setup do
    on_exit(fn ->
      Kati.Repo.query!(
        "DELETE FROM media_watches WHERE tracked_title_id IN (SELECT id FROM tracked_titles WHERE source_id LIKE ?1)",
        [@prefix <> "%"]
      )

      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
    end)

    :ok
  end

  defp watched!(name) do
    source_id = @prefix <> name

    Ash.create!(CachedTitle, %{
      source: :manual,
      source_id: source_id,
      kind: :tv,
      title: name,
      fetched_at: Kati.Time.now()
    })

    tracked =
      Ash.create!(TrackedTitle, %{
        source: :manual,
        source_id: source_id,
        kind: :tv,
        status: :watching
      })

    Ash.create!(Watch, %{tracked_title_id: tracked.id, watched_at: Kati.Time.now()})

    tracked
  end

  defp watches_for(tracked) do
    Watch |> Ash.read!() |> Enum.filter(&(&1.tracked_title_id == tracked.id))
  end

  describe "the ⋯ Remove row on screen 04" do
    test "removes a title that has been watched" do
      tracked = watched!("marram")
      assert [_one] = watches_for(tracked), "the fixture wrote no watch, so this proves nothing"

      assert :ok = Kati.Screens.Series.remove(%{tracked_id: tracked.id}),
             "the delete was refused — the foreign key still has no ON DELETE action"

      assert {:error, _gone} = Ash.get(TrackedTitle, tracked.id)
    end

    test "and takes the history with it, which is the owner's decision" do
      tracked = watched!("history")

      :ok = Kati.Screens.Series.remove(%{tracked_id: tracked.id})

      assert watches_for(tracked) == [],
             "the title went and its watch was left behind pointing at nothing"
    end

    test "and leaves what the provider said about it" do
      # The cached title is a provider's record, not the reader's. It is not a
      # child of the tracked row and nothing here should touch it.
      tracked = watched!("cache")

      :ok = Kati.Screens.Series.remove(%{tracked_id: tracked.id})

      assert [_kept] =
               CachedTitle
               |> Ash.read!()
               |> Enum.filter(&(&1.source_id == @prefix <> "cache"))
    end
  end

  describe "a content warning" do
    test "does not hold a title on the shelf either" do
      tracked = watched!("warned")

      Ash.create!(ContentWarning, %{tracked_title_id: tracked.id, category: :violence})

      assert :ok = Kati.Screens.Series.remove(%{tracked_id: tracked.id}),
             "media_content_warnings is the other child with no ON DELETE action"
    end
  end

  describe "the schema itself" do
    test "every child of tracked_titles cascades" do
      # The rule this bug broke, stated so a new child table cannot break it
      # again without this failing: a foreign key into tracked_titles either
      # cascades or it traps the title on the shelf.
      %{rows: tables} =
        Kati.Repo.query!(
          "SELECT name, sql FROM sqlite_master WHERE type = 'table' AND sql LIKE '%REFERENCES%tracked_titles%'"
        )

      trapping =
        for [name, sql] <- tables,
            Regex.match?(~r/REFERENCES "?tracked_titles"?\s*\("?id"?\)(?!\s+ON DELETE)/, sql),
            do: name

      assert trapping == [],
             "these tables reference tracked_titles with no ON DELETE action, so a title " <>
               "with a row in any of them cannot be removed: #{inspect(trapping)}"
    end
  end
end
