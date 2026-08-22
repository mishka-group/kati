defmodule Kati.Media.EpisodeTest do
  @moduledoc """
  The episode and season records, against a real SQLite file.

  `Kati.Media.Watch` has always carried an `episode_source_id` and nothing
  stored the record it names, so the app could say *something was watched* and
  never *what S2E6 is called*. `Kati.Media.CachedEpisode` and
  `Kati.Media.CachedSeason` are that record, and there are four claims about
  them worth holding down:

    1. **They are cache, entirely.** No column here can hold something the user
       made, and every row has an age the eviction sweep can reach.
    2. **They belong to a title by reference.** Evicting the title leaves the
       episodes; evicting the episodes leaves the title, and leaves every tick.
    3. **An unknown air date degrades rather than becoming a date.** #74's rule
       is not re-implemented for episodes — it is the same
       `Kati.Media.Release`, so an episode "airing Thursday" that is really a
       bare year cannot arm.
    4. **A tick joins to its episode**, by the provider id and never by the
       numbering, so a renumbered season keeps its ticks.

  The date rules run against plain structs where they can, for the reason
  `Kati.Media.ReleaseTest` gives: the rule has to keep working when the schema's
  other half has been deleted. The eviction and join claims cannot — they are
  about rows — so those go through the database.
  """
  use ExUnit.Case, async: false

  require Ash.Query

  alias Kati.Media.CachedEpisode
  alias Kati.Media.CachedSeason
  alias Kati.Media.CachedTitle
  alias Kati.Media.Release
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch

  # Exactly what a provider hands back for "sometime in 2026": the earliest
  # instant consistent with the period, which is not a date.
  @new_years_day ~U[2026-01-01 00:00:00.000000Z]

  # A fixed clock, so "has this aired" is a fact about the fixtures rather than
  # about the day the suite happens to run.
  @now ~U[2026-08-21 09:00:00.000000Z]

  setup do
    # Every row goes again afterwards. `Kati.Screens.Activity` draws screen 15's
    # log out of `media_watches` and `Kati.Screens.UpNext` reads
    # `tracked_titles`, so fixtures left behind here are drawn on a screen
    # `Kati.ScreenDesignLiteralTest` compares with its drawing — and whether that
    # passes would then depend on the shuffle. Same hazard `Kati.SeedsTest`
    # documents for events, and the same fix.
    on_exit(&empty_the_tables!/0)
    {:ok, prefix: "me#{System.unique_integer([:positive])}-"}
  end

  # Children first: media_watches carries the only foreign key in the domain.
  # The three cache tables reference each other by value, so their order among
  # themselves does not matter — which is itself the thing under test.
  defp empty_the_tables! do
    for table <-
          ~w(media_watches media_content_warnings tracked_titles cached_episodes cached_seasons cached_titles),
        do: Ecto.Adapters.SQL.query!(Kati.Repo, "delete from #{table}", [])

    :ok
  end

  # ── Fixtures ────────────────────────────────────────────────────────────────

  defp cache_title!(source_id, attrs \\ %{}) do
    CachedTitle
    |> Ash.Changeset.for_create(
      :create,
      Map.merge(
        %{
          source: :tmdb,
          source_id: source_id,
          kind: :tv,
          title: "The Long Hollow",
          fetched_at: DateTime.utc_now()
        },
        attrs
      )
    )
    |> Ash.create!()
  end

  defp cache_season!(title_source_id, number, attrs) do
    CachedSeason
    |> Ash.Changeset.for_create(
      :create,
      Map.merge(
        %{
          source: :tmdb,
          title_source_id: title_source_id,
          season_number: number,
          fetched_at: DateTime.utc_now()
        },
        attrs
      )
    )
    |> Ash.create!()
  end

  defp cache_episode!(title_source_id, source_id, attrs \\ %{}) do
    CachedEpisode
    |> Ash.Changeset.for_create(
      :create,
      Map.merge(
        %{
          source: :tmdb,
          source_id: source_id,
          title_source_id: title_source_id,
          fetched_at: DateTime.utc_now()
        },
        attrs
      )
    )
    |> Ash.create!()
  end

  defp track!(source_id, attrs) do
    TrackedTitle
    |> Ash.Changeset.for_create(
      :create,
      Map.merge(%{source: :tmdb, source_id: source_id, kind: :tv}, attrs)
    )
    |> Ash.create!()
  end

  defp watch!(title, attrs) do
    Watch
    |> Ash.Changeset.for_create(:create, Map.merge(%{tracked_title_id: title.id}, attrs))
    |> Ash.create!()
  end

  # A whole series in one call: a cached title, three seasons, and the episodes
  # of season 2 — which is the shape screen 04 draws and the shape a partial
  # fetch actually leaves behind.
  defp long_hollow!(prefix) do
    title_id = prefix <> "1399"
    cache_title!(title_id)

    for {number, count} <- [{1, 5}, {2, 7}, {3, 3}],
        do: cache_season!(title_id, number, %{name: "Season #{number}", episode_count: count})

    episodes =
      for n <- 1..7 do
        cache_episode!(title_id, "#{prefix}ep2#{n}", %{
          season_number: 2,
          episode_number: n,
          title: "Episode #{n}",
          runtime_minutes: 48,
          air_at: DateTime.add(~U[2026-07-02 19:00:00.000000Z], 7 * (n - 1), :day),
          date_confidence: :exact,
          release_source: :tvmaze
        })
      end

    %{title_source_id: title_id, episodes: episodes}
  end

  defp confidences do
    Ash.Resource.Info.attribute(CachedEpisode, :date_confidence).constraints[:one_of]
  end

  defp episode_with(confidence, at \\ @new_years_day) do
    %CachedEpisode{
      source: :tmdb,
      source_id: "1399-2-6",
      title_source_id: "1399",
      air_at: at,
      date_confidence: confidence,
      fetched_at: ~U[2026-08-01 00:00:00.000000Z]
    }
  end

  defp tracked_struct(attrs \\ []) do
    struct(
      %TrackedTitle{
        source: :tmdb,
        source_id: "1399",
        kind: :tv,
        notify_new_episodes: true
      },
      attrs
    )
  end

  # ── The cache/durable line, stated in the schema ─────────────────────────────

  describe "an episode is cache, entirely" do
    test "it holds nothing the user made" do
      # If any of these ever appeared here, a cache wipe would cost the user
      # their progress — which is the one thing the split exists to prevent. A
      # tick is a media_watches row and belongs on the durable side.
      forbidden = [
        :watched,
        :watched_on,
        :watched_at,
        :rating,
        :review,
        :note,
        :tags,
        :rewatch_number,
        :user_override_date,
        :status,
        :archived
      ]

      for resource <- [CachedEpisode, CachedSeason], name <- forbidden do
        refute Ash.Resource.Info.attribute(resource, name),
               "#{inspect(resource)}.#{name} would put the user's own work on an evictable row"
      end
    end

    test "every row carries an age, so the eviction sweep can reach it", %{prefix: prefix} do
      # `Kati.Media.CachedTitle` makes fetched_at not-null for this reason:
      # "a row with no age cannot be evicted". The same has to hold here or the
      # episode table sits outside TMDB's six-month ceiling.
      assert {:error, _} =
               CachedEpisode
               |> Ash.Changeset.for_create(:create, %{
                 source: :tmdb,
                 source_id: prefix <> "ageless",
                 title_source_id: prefix <> "1399"
               })
               |> Ash.create()

      assert {:error, _} =
               CachedSeason
               |> Ash.Changeset.for_create(:create, %{
                 source: :tmdb,
                 title_source_id: prefix <> "1399",
                 season_number: 1
               })
               |> Ash.create()
    end

    test "the stale scan finds old rows and leaves fresh ones", %{prefix: prefix} do
      title_id = prefix <> "1399"
      fresh = cache_episode!(title_id, prefix <> "fresh")

      old =
        cache_episode!(title_id, prefix <> "old", %{
          fetched_at: DateTime.add(DateTime.utc_now(), -200, :day)
        })

      stale =
        CachedEpisode
        |> Ash.Query.for_read(:stale, %{
          source: :tmdb,
          before: DateTime.add(DateTime.utc_now(), -30, :day)
        })
        |> Ash.Query.filter(title_source_id == ^title_id)
        |> Ash.read!()

      assert Enum.map(stale, & &1.id) == [old.id]
      refute fresh.id in Enum.map(stale, & &1.id)
    end

    test "neither reaches a title through a foreign key" do
      # A belongs_to would make eviction either impossible or destructive; there
      # is no third option. This is the schema-level statement of that.
      for resource <- [CachedEpisode, CachedSeason] do
        assert Ash.Resource.Info.attribute(resource, :title_source_id)

        assert [] ==
                 resource
                 |> Ash.Resource.Info.relationships()
                 |> Enum.filter(&(&1.destination == CachedTitle))
      end
    end

    test "every resource in the domain names the same sources" do
      # A row naming a source the cache cannot hold could never be fetched. The
      # list is a literal in five files; this pins them equal.
      expected =
        CachedTitle
        |> Ash.Resource.Info.attribute(:source)
        |> then(& &1.constraints[:one_of])
        |> Enum.sort()

      for resource <- [CachedEpisode, CachedSeason, TrackedTitle] do
        got =
          resource
          |> Ash.Resource.Info.attribute(:source)
          |> then(& &1.constraints[:one_of])
          |> Enum.sort()

        assert got == expected, "#{inspect(resource)} disagrees about which sources exist"
      end
    end

    test "every dated row shares one confidence ladder, defaulting to :unknown" do
      expected =
        Enum.sort(Ash.Resource.Info.attribute(CachedTitle, :date_confidence).constraints[:one_of])

      for resource <- [CachedEpisode, CachedSeason] do
        attribute = Ash.Resource.Info.attribute(resource, :date_confidence)

        assert Enum.sort(attribute.constraints[:one_of]) == expected,
               "#{inspect(resource)} has a ladder of its own, which is a second date rule"

        refute attribute.allow_nil?
        assert attribute.default == :unknown
      end
    end
  end

  # ── Reference, and eviction from either end ─────────────────────────────────

  describe "episodes belong to a title by reference" do
    test "for_title answers with that title's episodes and no others", %{prefix: prefix} do
      %{title_source_id: title_id} = long_hollow!(prefix)

      other_id = prefix <> "other"
      cache_title!(other_id, %{title: "Salt & Iron"})
      cache_episode!(other_id, prefix <> "salt1", %{season_number: 1, episode_number: 1})

      episodes = CachedEpisode.for_title(:tmdb, title_id)

      assert length(episodes) == 7
      assert Enum.map(episodes, & &1.episode_number) == [1, 2, 3, 4, 5, 6, 7]
      assert Enum.map(episodes, & &1.title) == Enum.map(1..7, &"Episode #{&1}")
      assert Enum.all?(episodes, &(&1.title_source_id == title_id))

      assert [prefix <> "salt1"] ==
               :tmdb |> CachedEpisode.for_title(other_id) |> Enum.map(& &1.source_id)
    end

    test "for_season narrows to one season", %{prefix: prefix} do
      %{title_source_id: title_id} = long_hollow!(prefix)

      cache_episode!(title_id, prefix <> "sp1", %{
        season_number: 0,
        episode_number: 1,
        special: true,
        title: "The Estuary — a making-of"
      })

      assert length(CachedEpisode.for_season(:tmdb, title_id, 2)) == 7
      assert [special] = CachedEpisode.for_season(:tmdb, title_id, 0)
      assert special.special
      assert special.title == "The Estuary — a making-of"
      assert CachedEpisode.for_season(:tmdb, title_id, 9) == []
    end

    test "evicting the title leaves every episode and season standing", %{prefix: prefix} do
      %{title_source_id: title_id} = long_hollow!(prefix)
      tracked = track!(title_id, %{status: :watching, progress_season: 2, progress_episode: 6})

      assert %CachedTitle{} = Release.cached_for(tracked)

      # The wipe: the title's cache row and nothing else.
      CachedTitle
      |> Ash.Query.filter(source_id == ^title_id)
      |> Ash.read!()
      |> Enum.each(&Ash.destroy!/1)

      assert Release.cached_for(tracked) == nil

      survivors = CachedEpisode.for_title(:tmdb, title_id)
      assert length(survivors) == 7
      assert Enum.map(survivors, & &1.title) == Enum.map(1..7, &"Episode #{&1}")
      assert Enum.all?(survivors, &(&1.runtime_minutes == 48))

      seasons = CachedSeason.for_title(:tmdb, title_id)
      assert length(seasons) == 3
      assert Enum.map(seasons, & &1.episode_count) == [5, 7, 3]

      # And the reference still points where it pointed, so a re-fetch of the
      # title alone puts the poster back beside the episodes that never left.
      assert Enum.all?(survivors, &(&1.title_source_id == tracked.source_id))
    end

    test "evicting the episodes leaves the title and every tick standing", %{prefix: prefix} do
      %{title_source_id: title_id, episodes: episodes} = long_hollow!(prefix)
      tracked = track!(title_id, %{status: :watching})

      tick =
        watch!(tracked, %{
          episode_source_id: Enum.at(episodes, 5).source_id,
          season_number: 2,
          episode_number: 6,
          rating: 8,
          review: "the estuary scenes land differently the second time"
        })

      # The other direction of the same wipe.
      CachedEpisode
      |> Ash.Query.filter(title_source_id == ^title_id)
      |> Ash.read!()
      |> Enum.each(&Ash.destroy!/1)

      assert CachedEpisode.for_title(:tmdb, title_id) == []
      assert %CachedTitle{title: "The Long Hollow"} = Release.cached_for(tracked)

      survivor = Ash.get!(Watch, tick.id)
      assert survivor.episode_source_id == tick.episode_source_id
      assert survivor.rating == 8
      assert survivor.review == "the estuary scenes land differently the second time"

      # The label snapshot is what keeps screen 15's log reading "S2E6" while
      # the record that would name the episode is gone.
      assert survivor.season_number == 2
      assert survivor.episode_number == 6

      # And the join is a miss rather than a crash.
      assert CachedEpisode.for_ticks(:tmdb, [survivor]) == %{}
    end

    test "one episode per {source, source_id}", %{prefix: prefix} do
      title_id = prefix <> "1399"
      first = cache_episode!(title_id, prefix <> "dup")

      duplicate =
        try do
          {:ok, cache_episode!(title_id, prefix <> "dup")}
        rescue
          error -> {:error, error}
        end

      assert match?({:error, _}, duplicate)

      remaining =
        CachedEpisode
        |> Ash.Query.filter(source_id == ^(prefix <> "dup"))
        |> Ash.read!()

      assert Enum.map(remaining, & &1.id) == [first.id]
    end
  end

  # ── The season inventory ────────────────────────────────────────────────────

  describe "the season inventory is what progress_season counts against" do
    test "it counts the seasons that exist, not the ones that were fetched",
         %{prefix: prefix} do
      %{title_source_id: title_id} = long_hollow!(prefix)

      seasons = CachedSeason.for_title(:tmdb, title_id)
      assert CachedSeason.count(seasons) == 3

      # Only season 2's episodes are cached, which is the ordinary state of a
      # partly fetched title. Deriving the count from them would draw
      # "1 SEASON" — specific, confident and wrong.
      assert :tmdb |> CachedEpisode.for_title(title_id) |> CachedEpisode.seasons() == [2]
    end

    test "specials are in the order and out of the count", %{prefix: prefix} do
      %{title_source_id: title_id} = long_hollow!(prefix)
      cache_season!(title_id, 0, %{name: "Specials", episode_count: 2})

      seasons = CachedSeason.for_title(:tmdb, title_id)

      assert Enum.map(seasons, & &1.season_number) == [0, 1, 2, 3]
      assert CachedSeason.count(seasons) == 3
      assert seasons |> CachedSeason.numbered() |> Enum.map(& &1.season_number) == [1, 2, 3]
      assert [specials] = Enum.filter(seasons, &CachedSeason.specials?/1)
      assert specials.name == "Specials"
    end

    test "the denominator is the provider's count, and nil where there is none",
         %{prefix: prefix} do
      title_id = prefix <> "1399"

      counted = cache_season!(title_id, 1, %{episode_count: 7})
      silent = cache_season!(title_id, 2, %{})

      assert CachedSeason.denominator(counted) == 7
      assert CachedSeason.denominator(silent) == nil
      # An evicted season, which is the case the whole split exists for.
      assert CachedSeason.denominator(nil) == nil

      # A source that answers 0 is declining to say. `min: 1` stops it being
      # stored at all, so a zero denominator can never reach a progress ring.
      assert {:error, _} =
               CachedSeason
               |> Ash.Changeset.for_create(:create, %{
                 source: :tmdb,
                 title_source_id: title_id,
                 season_number: 3,
                 episode_count: 0,
                 fetched_at: DateTime.utc_now()
               })
               |> Ash.create()
    end

    test "one season per {source, title, number}", %{prefix: prefix} do
      title_id = prefix <> "1399"
      first = cache_season!(title_id, 2, %{name: "Season 2"})

      duplicate =
        try do
          {:ok, cache_season!(title_id, 2, %{name: "Season Two"})}
        rescue
          error -> {:error, error}
        end

      assert match?({:error, _}, duplicate)
      assert %CachedSeason{name: "Season 2"} = CachedSeason.by_reference(:tmdb, title_id, 2)

      # The same number under a different title is a different season, not a
      # clash — which is what makes the triple the right key.
      other = cache_season!(prefix <> "other", 2, %{name: "Season 2"})
      assert other.id != first.id
    end
  end

  # ── #74, applied to an airing ───────────────────────────────────────────────

  describe "an unknown air date degrades rather than becoming a date" do
    test "the ladder is read through Release and nothing else" do
      assert Enum.sort(confidences()) == [:day, :exact, :month, :quarter, :unknown, :year]

      assert Release.air(episode_with(:exact, ~U[2026-08-06 19:00:00.000000Z])) ==
               {:exact, ~U[2026-08-06 19:00:00.000000Z], :cache}

      assert Release.air(episode_with(:day)) == {:day, ~D[2026-01-01], :cache}
      assert Release.air(episode_with(:month)) == {:approximate, {:month, 2026, 1}, :cache}
      assert Release.air(episode_with(:quarter)) == {:approximate, {:quarter, 2026, 1}, :cache}
      assert Release.air(episode_with(:year)) == {:approximate, {:year, 2026}, :cache}

      # The default, which is what most rows carry: it degrades, it does not arm.
      assert Release.air(episode_with(:unknown)) == {:approximate, {:year, 2026}, :cache}
      assert Release.air(episode_with(:year, nil)) == :unknown
    end

    test "a coarse answer carries no day at all, so nothing can arm on one" do
      for confidence <- [:month, :quarter, :year, :unknown] do
        assert {:approximate, period, :cache} = Release.air(episode_with(confidence))

        # A tag and then whole numbers — a year, a quarter, a month. There is no
        # day in the value at all, which is stronger than documenting that a
        # caller must not arm on one.
        [tag | parts] = Tuple.to_list(period)

        assert tag in [:month, :quarter, :year]

        assert Enum.all?(parts, &is_integer/1),
               "#{confidence} produced #{inspect(period)}, which is not a bare period"

        refute Enum.any?(parts, &match?(%Date{}, &1))
        refute Enum.any?(parts, &match?(%DateTime{}, &1))
      end
    end

    test "only :exact and :day arm, checked against the schema's own ladder" do
      armed =
        for confidence <- confidences(),
            match?(
              {:ok, _},
              Release.alarm_for(tracked_struct(), episode_with(confidence), zone: "Etc/UTC")
            ),
            do: confidence

      assert Enum.sort(armed) == [:day, :exact],
             "these confidences armed an alarm for an episode: #{inspect(armed)}"
    end

    test "an exact airing arms at exactly that instant" do
      airs = ~U[2026-08-20 19:00:00.000000Z]

      assert {:ok, at} =
               Release.alarm_for(tracked_struct(), episode_with(:exact, airs), zone: "Etc/UTC")

      assert DateTime.compare(at, airs) == :eq
    end

    test "a muted show suppresses an airing it is certain about" do
      # The same gate as `alarm_at/3`: a caller matching {:ok, at} cannot honour
      # one rule and forget the other.
      muted = tracked_struct(notify_new_episodes: false)
      certain = episode_with(:exact, ~U[2026-08-20 19:00:00.000000Z])

      assert Release.alarm_for(muted, certain, zone: "Etc/UTC") == {:suppressed, :muted}

      assert Release.alarm_for(muted, episode_with(:year), zone: "Etc/UTC") ==
               {:suppressed, :muted}
    end

    test "no date at all is :no_date, and a vague one is :low_confidence" do
      assert Release.alarm_for(tracked_struct(), episode_with(:exact, nil), zone: "Etc/UTC") ==
               {:suppressed, :no_date}

      assert Release.alarm_for(tracked_struct(), episode_with(:year), zone: "Etc/UTC") ==
               {:suppressed, :low_confidence}
    end

    test "a season drop resolves and arms by the same rule" do
      season = %CachedSeason{
        source: :tmdb,
        title_source_id: "1399",
        season_number: 2,
        air_at: @new_years_day,
        date_confidence: :year,
        fetched_at: ~U[2026-08-01 00:00:00.000000Z]
      }

      assert Release.air(season) == {:approximate, {:year, 2026}, :cache}

      assert Release.alarm_for(tracked_struct(), season, zone: "Etc/UTC") ==
               {:suppressed, :low_confidence}

      dated = %{season | air_at: ~U[2026-09-12 00:00:00.000000Z], date_confidence: :day}
      assert Release.air(dated) == {:day, ~D[2026-09-12], :cache}
      assert {:ok, %DateTime{}} = Release.alarm_for(tracked_struct(), dated, zone: "Etc/UTC")
    end

    test "the user's override is a claim about the title, not about an episode" do
      # Rule 1 must not reach in here: a hand-typed "it's out on the 14th"
      # corrects when the show is next on, and would otherwise rewrite the air
      # date of every episode that has already gone out.
      corrected = tracked_struct(user_override_date: ~D[2026-11-14])
      aired_long_ago = episode_with(:exact, ~U[2024-07-02 19:00:00.000000Z])

      assert Release.air(aired_long_ago) == {:exact, ~U[2024-07-02 19:00:00.000000Z], :cache}

      assert {:ok, at} = Release.alarm_for(corrected, aired_long_ago, zone: "Etc/UTC")
      assert DateTime.compare(at, ~U[2024-07-02 19:00:00.000000Z]) == :eq

      # While the title's own resolution still honours it.
      assert Release.resolve(corrected, nil) == {:day, ~D[2026-11-14], :user_override}
    end
  end

  describe "airing/2 answers aired, upcoming, or neither" do
    test "an exact instant is decided by the instant" do
      assert Release.airing(
               Release.air(episode_with(:exact, ~U[2026-08-06 19:00:00.000000Z])),
               @now
             ) ==
               :aired

      assert Release.airing(
               Release.air(episode_with(:exact, ~U[2026-08-27 19:00:00.000000Z])),
               @now
             ) ==
               :upcoming
    end

    test "a day-precise date on today itself is unknown, because the hour is" do
      yesterday = episode_with(:day, ~U[2026-08-20 00:00:00.000000Z])
      today = episode_with(:day, ~U[2026-08-21 00:00:00.000000Z])
      tomorrow = episode_with(:day, ~U[2026-08-22 00:00:00.000000Z])

      assert Release.airing(Release.air(yesterday), @now) == :aired
      assert Release.airing(Release.air(today), @now) == :unknown
      assert Release.airing(Release.air(tomorrow), @now) == :upcoming
    end

    test "a period is answered by its own bounds, never by a day inside it" do
      # 2019 is entirely behind us and 2030 entirely ahead: that is an
      # entailment, not a guess. 2026 contains today, and there the honest
      # answer is that nobody knows.
      assert Release.airing(
               Release.air(episode_with(:year, ~U[2019-01-01 00:00:00.000000Z])),
               @now
             ) ==
               :aired

      assert Release.airing(
               Release.air(episode_with(:year, ~U[2030-01-01 00:00:00.000000Z])),
               @now
             ) ==
               :upcoming

      assert Release.airing(Release.air(episode_with(:year, @new_years_day)), @now) == :unknown

      # Q1 of this year is over; Q4 has not started.
      assert Release.airing(
               Release.air(episode_with(:quarter, ~U[2026-01-01 00:00:00.000000Z])),
               @now
             ) == :aired

      assert Release.airing(
               Release.air(episode_with(:quarter, ~U[2026-10-01 00:00:00.000000Z])),
               @now
             ) == :upcoming

      assert Release.airing(
               Release.air(episode_with(:month, ~U[2026-08-01 00:00:00.000000Z])),
               @now
             ) == :unknown
    end

    test "nothing known is unknown, not not-yet-aired" do
      assert Release.airing(:unknown, @now) == :unknown
      assert Release.airing(Release.air(episode_with(:exact, nil)), @now) == :unknown
    end
  end

  # ── The join Kati deliberately does not have as a foreign key ───────────────

  describe "a tick joins to its episode" do
    test "for_ticks returns every episode the ticks name, keyed by the provider id",
         %{prefix: prefix} do
      %{title_source_id: title_id, episodes: episodes} = long_hollow!(prefix)
      tracked = track!(title_id, %{status: :watching})

      for episode <- Enum.take(episodes, 5) do
        watch!(tracked, %{
          episode_source_id: episode.source_id,
          season_number: 2,
          episode_number: episode.episode_number
        })
      end

      ticks =
        Watch
        |> Ash.Query.for_read(:episode_ticks, %{tracked_title_id: tracked.id})
        |> Ash.read!()

      assert length(ticks) == 5

      joined = CachedEpisode.for_ticks(tracked.source, ticks)

      assert map_size(joined) == 5

      assert joined |> Map.values() |> Enum.map(& &1.title) |> Enum.sort() ==
               Enum.sort(Enum.map(1..5, &"Episode #{&1}"))

      # And the counter screen 04 draws, derived and never stored.
      ticked = CachedEpisode.ticked_ids(ticks)
      assert CachedEpisode.watched_of(episodes, ticked) == {5, 7}
      assert CachedEpisode.ticked?(Enum.at(episodes, 0), ticked)
      refute CachedEpisode.ticked?(Enum.at(episodes, 6), ticked)
    end

    test "the join survives a renumbering, because it is not on the numbers",
         %{prefix: prefix} do
      %{title_source_id: title_id, episodes: episodes} = long_hollow!(prefix)
      tracked = track!(title_id, %{status: :watching})
      episode = Enum.at(episodes, 5)

      tick =
        watch!(tracked, %{
          episode_source_id: episode.source_id,
          season_number: 2,
          episode_number: 6
        })

      # Screen 34: absolute order renumbers this season 27–35. Both halves are
      # relabelled and neither is the identity.
      episode
      |> Ash.Changeset.for_update(:update, %{season_number: nil, absolute_number: 32})
      |> Ash.update!()

      tick
      |> Ash.Changeset.for_update(:update, %{season_number: nil, episode_number: 32})
      |> Ash.update!()

      joined = CachedEpisode.for_ticks(:tmdb, [Ash.get!(Watch, tick.id)])

      assert %CachedEpisode{} = found = Map.get(joined, episode.source_id)
      assert found.id == episode.id
      assert found.absolute_number == 32
      assert found.title == "Episode 6"
    end

    test "whole-title watches carry no episode and are not looked up", %{prefix: prefix} do
      %{title_source_id: title_id, episodes: episodes} = long_hollow!(prefix)
      tracked = track!(title_id, %{status: :watching})

      film_log = watch!(tracked, %{rating: 9, review: "worth a rewatch on a proper screen"})
      tick = watch!(tracked, %{episode_source_id: hd(episodes).source_id})

      joined = CachedEpisode.for_ticks(:tmdb, [film_log, tick])

      assert map_size(joined) == 1
      assert Map.has_key?(joined, hd(episodes).source_id)

      assert CachedEpisode.for_ticks(:tmdb, [film_log]) == %{}
      assert CachedEpisode.for_ticks(:tmdb, []) == %{}
      assert CachedEpisode.ticked_ids([film_log]) == MapSet.new()
    end

    test "an episode id from another source is not a match", %{prefix: prefix} do
      %{episodes: episodes} = long_hollow!(prefix)
      id = hd(episodes).source_id

      assert %CachedEpisode{} = CachedEpisode.by_reference(:tmdb, id)
      assert CachedEpisode.by_reference(:tvmaze, id) == nil
      assert CachedEpisode.by_reference(:tmdb, prefix <> "never") == nil
      assert CachedEpisode.by_source_ids(:tmdb, [prefix <> "never"]) == %{}
    end
  end

  # ── The orders Kati can and cannot draw ─────────────────────────────────────

  describe "the numbering orders" do
    test "there are two, and the third is absent rather than faked" do
      # Screen 34 draws Aired, Absolute and DVD. No source in
      # CachePolicy.sources/0 gives per-episode DVD numbering, so it is not
      # offered — a segmented tile that renumbers nothing is a lie in pixels.
      assert CachedEpisode.orders() == [:aired, :absolute]
    end

    test "aired order is season then episode, with the unplaced at the end" do
      episodes = [
        %CachedEpisode{source_id: "c", season_number: 2, episode_number: 1},
        %CachedEpisode{source_id: "a", season_number: 1, episode_number: 1},
        %CachedEpisode{source_id: "d", season_number: 2, episode_number: nil, special: true},
        %CachedEpisode{source_id: "b", season_number: 1, episode_number: 2}
      ]

      assert episodes |> CachedEpisode.in_order(:aired) |> Enum.map(& &1.source_id) ==
               ~w(a b c d)
    end

    test "absolute order drops what it cannot number rather than inventing one" do
      episodes = [
        %CachedEpisode{source_id: "b", season_number: 2, episode_number: 1, absolute_number: 28},
        %CachedEpisode{source_id: "special", season_number: 0, episode_number: 1, special: true},
        %CachedEpisode{source_id: "a", season_number: 2, episode_number: 2, absolute_number: 27}
      ]

      ordered = CachedEpisode.in_order(episodes, :absolute)

      assert Enum.map(ordered, & &1.source_id) == ~w(a b)
      assert Enum.map(ordered, & &1.absolute_number) == [27, 28]

      refute "special" in Enum.map(ordered, & &1.source_id),
             "an episode with no absolute number was given one"
    end

    test "number_in says nil rather than borrowing the other scheme's number" do
      episode = %CachedEpisode{source_id: "x", season_number: 2, episode_number: 6}

      assert CachedEpisode.number_in(episode, :aired) == 6
      assert CachedEpisode.number_in(episode, :absolute) == nil
      assert CachedEpisode.number_in(%{episode | absolute_number: 32}, :absolute) == 32
    end

    test "seasons/1 reports what is cached, specials included", %{prefix: prefix} do
      %{title_source_id: title_id} = long_hollow!(prefix)

      cache_episode!(title_id, prefix <> "sp1", %{
        season_number: 0,
        episode_number: 1,
        special: true
      })

      assert :tmdb |> CachedEpisode.for_title(title_id) |> CachedEpisode.seasons() == [0, 2]
    end
  end
end
