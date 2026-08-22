defmodule Kati.Media.TrackingTest do
  @moduledoc """
  The durable half of the media schema, against a real SQLite file.

  The claim under test is the one `Kati.Media.CachedTitle`'s moduledoc makes:
  *"nothing the user created lives here — that belongs on their own tracking
  rows, which reference a title by `{source, source_id}` and survive a cache
  wipe intact."* So the centrepiece is a wipe: build a library, delete every
  cache row it points at, and prove the ticks, ratings, reviews and the
  hand-typed date are all still there afterwards.
  """
  use ExUnit.Case, async: false

  require Ash.Query

  alias Kati.Media.CachedTitle
  alias Kati.Media.Release
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch

  setup do
    # Every row this module makes shares one prefix, so the cache wipe below can
    # be a real wipe of this test's titles without touching another test's.
    #
    # And every row goes again afterwards, because what this module leaves behind
    # stopped being inert the moment a screen started reading these tables:
    # `Kati.Screens.Activity` draws screen 15's log out of `media_watches`, and
    # the watches below are stamped inside the current month, so they land in its
    # "Earlier this month" card. `Kati.ScreenDesignLiteralTest` then compares
    # that screen with its drawing and finds this module's fixtures instead —
    # and whether it passes depends on the shuffle putting it before this file
    # rather than after it. Same hazard `Kati.SeedsTest` documents for events,
    # and the same fix.
    on_exit(&empty_the_tables!/0)
    {:ok, prefix: "mt#{System.unique_integer([:positive])}-"}
  end

  # Children first: media_watches carries the foreign key into tracked_titles.
  defp empty_the_tables! do
    for table <- ~w(media_watches media_content_warnings tracked_titles cached_titles),
        do: Ecto.Adapters.SQL.query!(Kati.Repo, "delete from #{table}", [])

    :ok
  end

  defp track!(prefix, attrs \\ %{}) do
    TrackedTitle
    |> Ash.Changeset.for_create(
      :create,
      Map.merge(
        %{
          source: :tmdb,
          source_id: prefix <> "#{System.unique_integer([:positive])}",
          kind: :tv
        },
        attrs
      )
    )
    |> Ash.create!()
  end

  defp cache!(prefix, source_id, attrs) do
    CachedTitle
    |> Ash.Changeset.for_create(
      :create,
      Map.merge(
        %{
          source: :tmdb,
          source_id: source_id,
          kind: :tv,
          title: prefix <> "cached",
          fetched_at: DateTime.utc_now()
        },
        attrs
      )
    )
    |> Ash.create!()
  end

  defp watch!(title, attrs) do
    Watch
    |> Ash.Changeset.for_create(:create, Map.merge(%{tracked_title_id: title.id}, attrs))
    |> Ash.create!()
  end

  describe "a cache wipe costs a re-fetch and never a memory" do
    test "everything the user made is still there when the cache is gone", %{prefix: prefix} do
      title =
        track!(prefix, %{
          status: :watching,
          progress_season: 2,
          progress_episode: 6,
          rating: 9,
          user_override_date: ~D[2026-11-14]
        })

      cache!(prefix, title.source_id, %{
        next_release_at: ~U[2026-01-01 00:00:00.000000Z],
        date_confidence: :year
      })

      watch!(title, %{
        episode_source_id: "ep-1234",
        season_number: 2,
        episode_number: 5,
        rating: 8,
        review: "the estuary scenes land differently the second time",
        watched_at: ~U[2026-08-16 21:40:00.000000Z],
        service: "Lumen+",
        place: "living room",
        companions: "Jo",
        rewatch_number: 2
      })

      watch!(title, %{episode_source_id: "ep-1235", season_number: 2, episode_number: 6})

      assert %CachedTitle{} = Release.cached_for(title)

      # The wipe.
      CachedTitle
      |> Ash.Query.filter(source_id == ^title.source_id)
      |> Ash.read!()
      |> Enum.each(&Ash.destroy!/1)

      assert Release.cached_for(title) == nil

      survivor = Ash.get!(TrackedTitle, title.id)
      assert survivor.status == :watching
      assert survivor.progress_season == 2
      assert survivor.progress_episode == 6
      assert survivor.rating == 9
      assert survivor.user_override_date == ~D[2026-11-14]

      watches =
        Watch
        |> Ash.Query.for_read(:for_title, %{tracked_title_id: title.id})
        |> Ash.read!()

      assert length(watches) == 2

      logged = Enum.find(watches, &(&1.episode_source_id == "ep-1234"))
      assert logged.rating == 8
      assert logged.review == "the estuary scenes land differently the second time"
      assert logged.service == "Lumen+"
      assert logged.place == "living room"
      assert logged.companions == "Jo"
      assert logged.rewatch_number == 2
      assert logged.season_number == 2
      assert logged.episode_number == 5

      # And the rule still answers, from the surviving half alone.
      assert Release.for_tracked(survivor) == {:day, ~D[2026-11-14], :user_override}
    end

    test "the reference finds its way back after a re-fetch", %{prefix: prefix} do
      title = track!(prefix, %{status: :watching})
      cache!(prefix, title.source_id, %{title: "The Long Hollow"})

      found =
        TrackedTitle
        |> Ash.Query.for_read(:by_reference, %{source: :tmdb, source_id: title.source_id})
        |> Ash.read_one!()

      assert found.id == title.id
      assert Release.cached_for(found).title == "The Long Hollow"

      # A pair that was never tracked is a miss, not a stray row.
      assert nil ==
               TrackedTitle
               |> Ash.Query.for_read(:by_reference, %{
                 source: :tmdb,
                 source_id: prefix <> "never"
               })
               |> Ash.read_one!()
    end

    test "one tracked row per {source, source_id}", %{prefix: prefix} do
      title = track!(prefix)

      duplicate =
        try do
          {:ok, track!(prefix, %{source_id: title.source_id})}
        rescue
          error -> {:error, error}
        end

      assert match?({:error, _}, duplicate)

      remaining =
        TrackedTitle
        |> Ash.Query.filter(source_id == ^title.source_id)
        |> Ash.read!()

      assert length(remaining) == 1
    end
  end

  describe "last_touched_at, which the shelves sort by" do
    test "is forced on create, even when the caller supplies one", %{prefix: prefix} do
      title = track!(prefix, %{last_touched_at: ~U[2020-01-01 00:00:00.000000Z]})

      assert DateTime.compare(title.last_touched_at, ~U[2020-01-01 00:00:00.000000Z]) == :gt
      assert DateTime.diff(DateTime.utc_now(), title.last_touched_at, :second) < 10
    end

    test "is forced forward on update, so the shelf cannot be poisoned", %{prefix: prefix} do
      title = track!(prefix)

      updated =
        title
        |> Ash.Changeset.for_update(:update, %{
          status: :watching,
          last_touched_at: ~U[2020-01-01 00:00:00.000000Z]
        })
        |> Ash.update!()

      assert updated.status == :watching
      assert DateTime.compare(updated.last_touched_at, ~U[2020-01-01 00:00:00.000000Z]) == :gt
      assert DateTime.compare(updated.last_touched_at, title.last_touched_at) != :lt
    end

    test "the shelf action returns one section, newest first, minus the archived",
         %{prefix: prefix} do
      # Written oldest-first, then stamped apart, so a shelf that ignored the
      # sort would come back in insertion order and fail.
      oldest = track!(prefix, %{kind: :tv})
      middle = track!(prefix, %{kind: :tv})
      newest = track!(prefix, %{kind: :tv})
      hidden = track!(prefix, %{kind: :tv, archived: true})
      book = track!(prefix, %{kind: :book})

      for {row, days} <- [{oldest, -30}, {middle, -10}, {newest, -1}, {hidden, 0}] do
        stamp!(row, DateTime.add(DateTime.utc_now(), days, :day))
      end

      shelf =
        TrackedTitle
        |> Ash.Query.for_read(:shelf, %{kind: :tv})
        |> Ash.Query.filter(source_id |> contains(^prefix))
        |> Ash.read!()

      assert Enum.map(shelf, & &1.id) == [newest.id, middle.id, oldest.id]
      refute hidden.id in Enum.map(shelf, & &1.id)
      refute book.id in Enum.map(shelf, & &1.id)

      books =
        TrackedTitle
        |> Ash.Query.for_read(:shelf, %{kind: :book})
        |> Ash.Query.filter(source_id |> contains(^prefix))
        |> Ash.read!()

      assert Enum.map(books, & &1.id) == [book.id]
    end
  end

  describe "who the release watcher looks at" do
    test "not-started, watching and paused; never finished, dropped or archived",
         %{prefix: prefix} do
      wanted =
        for status <- [:not_started, :watching, :paused],
            do: {status, track!(prefix, %{status: status})}

      unwanted =
        [
          {:finished, track!(prefix, %{status: :finished})},
          {:dropped, track!(prefix, %{status: :dropped})},
          {:archived, track!(prefix, %{status: :watching, archived: true})}
        ]

      followed =
        TrackedTitle
        |> Ash.Query.for_read(:followed)
        |> Ash.Query.filter(source_id |> contains(^prefix))
        |> Ash.read!()

      ids = Enum.map(followed, & &1.id) |> Enum.sort()

      assert ids == wanted |> Enum.map(fn {_s, t} -> t.id end) |> Enum.sort()
      assert length(ids) == 3
      assert Enum.sort(Enum.map(followed, & &1.status)) == [:not_started, :paused, :watching]

      for {label, row} <- unwanted do
        refute row.id in ids, "#{label} should not be followed"
      end
    end

    test "a followed title defaults to being told about, and can be muted",
         %{prefix: prefix} do
      title = track!(prefix)
      assert title.notify_new_episodes
      assert title.auto_add_new_seasons
      assert title.add_air_dates_to_calendar
      refute title.hide_unwatched_titles
      refute title.archived
      assert title.status == :not_started

      muted =
        title
        |> Ash.Changeset.for_update(:update, %{notify_new_episodes: false})
        |> Ash.update!()

      refute muted.notify_new_episodes

      assert Release.alarm_at(muted, nil) == {:suppressed, :muted}
    end
  end

  describe "episode ticks follow the episode, not the number" do
    test "a renumbered season keeps its ticks", %{prefix: prefix} do
      # Screen 34: aired, absolute and DVD orders renumber the same episodes.
      # The tick is keyed on the provider's episode id, so switching order
      # rewrites the label and finds the same row.
      title = track!(prefix, %{status: :watching})
      tick = watch!(title, %{episode_source_id: "ep-1234", season_number: 2, episode_number: 6})

      renumbered =
        tick
        |> Ash.Changeset.for_update(:update, %{season_number: nil, episode_number: 33})
        |> Ash.update!()

      assert renumbered.episode_number == 33
      assert renumbered.season_number == nil

      still_ticked =
        Watch
        |> Ash.Query.for_read(:for_episode, %{
          tracked_title_id: title.id,
          episode_source_id: "ep-1234"
        })
        |> Ash.read!()

      assert length(still_ticked) == 1
      assert hd(still_ticked).id == tick.id
    end

    test "episode_ticks excludes whole-title watches", %{prefix: prefix} do
      title = track!(prefix, %{kind: :movie, status: :finished})

      watch!(title, %{episode_source_id: "ep-1", season_number: 1, episode_number: 1})
      watch!(title, %{episode_source_id: "ep-2", season_number: 1, episode_number: 2})
      film_log = watch!(title, %{rating: 9, review: "worth a rewatch on a proper screen"})

      ticks =
        Watch
        |> Ash.Query.for_read(:episode_ticks, %{tracked_title_id: title.id})
        |> Ash.read!()

      assert length(ticks) == 2
      assert Enum.sort(Enum.map(ticks, & &1.episode_source_id)) == ["ep-1", "ep-2"]
      refute film_log.id in Enum.map(ticks, & &1.id)

      all =
        Watch
        |> Ash.Query.for_read(:for_title, %{tracked_title_id: title.id})
        |> Ash.read!()

      assert length(all) == 3
    end

    test "rewatching an episode adds a row rather than replacing one", %{prefix: prefix} do
      title = track!(prefix, %{status: :watching})

      for n <- 1..3 do
        watch!(title, %{
          episode_source_id: "ep-1234",
          season_number: 1,
          episode_number: 1,
          rewatch_number: n
        })
      end

      viewings =
        Watch
        |> Ash.Query.for_read(:for_episode, %{
          tracked_title_id: title.id,
          episode_source_id: "ep-1234"
        })
        |> Ash.read!()

      # Screen 15's "Rewatched Nightbirds S1E1 · 3rd time".
      assert length(viewings) == 3
      assert Enum.sort(Enum.map(viewings, & &1.rewatch_number)) == [1, 2, 3]
    end

    test "a watch may be a date with no hour, and neither is invented",
         %{prefix: prefix} do
      title = track!(prefix, %{kind: :movie})

      # Screen 08: "Watched 12 Aug", no time known.
      dated = watch!(title, %{watched_on: ~D[2026-08-12]})
      assert dated.watched_on == ~D[2026-08-12]
      assert dated.watched_at == nil

      # Screen 33: "Sun 16 Aug · 21:40".
      timed = watch!(title, %{watched_at: ~U[2026-08-16 21:40:00.000000Z]})
      assert DateTime.compare(timed.watched_at, ~U[2026-08-16 21:40:00.000000Z]) == :eq

      # "I have seen this, I do not remember when" is a real answer.
      neither = watch!(title, %{rating: 7})
      assert neither.watched_on == nil
      assert neither.watched_at == nil
      assert neither.rating == 7
    end
  end

  describe "ratings are the ten-point scale" do
    test "half stars survive the round trip and the ends are rejected",
         %{prefix: prefix} do
      title = track!(prefix)

      # Screen 33 draws 4.5 stars; that is 9 here.
      rated = title |> Ash.Changeset.for_update(:update, %{rating: 9}) |> Ash.update!()
      assert Ash.get!(TrackedTitle, title.id).rating == 9
      assert rated.rating / 2 == 4.5

      assert {:error, _} =
               title |> Ash.Changeset.for_update(:update, %{rating: 11}) |> Ash.update()

      assert {:error, _} =
               title |> Ash.Changeset.for_update(:update, %{rating: 0}) |> Ash.update()

      # The stored value is untouched by the two rejections.
      assert Ash.get!(TrackedTitle, title.id).rating == 9
    end
  end

  # last_touched_at is forced by Kati.Media.Changes.Touch on every Ash write, by
  # design — so a test that needs an old one has to go under it.
  defp stamp!(row, at) do
    {:ok, _} =
      Ecto.Adapters.SQL.query(
        Kati.Repo,
        "update tracked_titles set last_touched_at = ? where id = ?",
        [at, row.id]
      )

    :ok
  end
end
