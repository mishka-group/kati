defmodule Kati.Media.ProgressTest do
  @moduledoc """
  The shelf denominators, against a real SQLite file.

  Screens 03 and 20 draw a ring and "p.214/380" out of two rows that are
  deliberately not joined: the position is on the durable
  `Kati.Media.TrackedTitle`, the total is on the evictable
  `Kati.Media.CachedTitle`. So there are two claims to hold down, and the second
  matters more than the first:

    1. The fraction is **computable** — the total survives a write and a read,
       and the right column answers for each kind.
    2. When it is not, the answer **degrades rather than lies**. An evicted row,
       a provider that never said, and a stored zero must all produce "p.214"
       with no ring — never "p.214/0", never a crash, never an invented total.

  The zero case is the one worth being explicit about: a zero denominator is not
  0% read, it is a division by zero wearing a progress ring.
  """
  use ExUnit.Case, async: false

  require Ash.Query

  alias Kati.Media.CachedTitle
  alias Kati.Media.Release
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch

  setup do
    # The rows go again afterwards. `Kati.Screens.Activity` reads `media_watches`
    # for screen 15's log and `Kati.Screens.UpNext` reads `tracked_titles`, so
    # fixtures left here are drawn on a screen `Kati.ScreenDesignLiteralTest`
    # compares with its drawing — and whether that passes would depend on the
    # shuffle. Same hazard `Kati.SeedsTest` documents for events.
    on_exit(&empty_the_tables!/0)
    {:ok, prefix: "mp#{System.unique_integer([:positive])}-"}
  end

  # Children first: media_watches carries the foreign key into tracked_titles.
  defp empty_the_tables! do
    for table <- ~w(media_watches media_content_warnings tracked_titles cached_titles),
        do: Ecto.Adapters.SQL.query!(Kati.Repo, "delete from #{table}", [])

    :ok
  end

  defp cache!(prefix, attrs) do
    CachedTitle
    |> Ash.Changeset.for_create(
      :create,
      Map.merge(
        %{
          source: :openlibrary,
          source_id: prefix <> "#{System.unique_integer([:positive])}",
          kind: :book,
          title: prefix <> "cached",
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
      Map.merge(%{source: :openlibrary, source_id: source_id, kind: :book}, attrs)
    )
    |> Ash.create!()
  end

  # What a shelf row prints, derived only from what `progress/2` hands back.
  # There is no clause that can produce a denominator, because the coarse
  # results carry no total to print.
  defp label({:fraction, done, total}), do: "p.#{done}/#{total}"
  defp label({:position, done}), do: "p.#{done}"
  defp label(:unknown), do: "—"

  describe "the fraction screens 03 and 20 draw" do
    test "computes from a total that really round-tripped through SQLite", %{prefix: prefix} do
      cached = cache!(prefix, %{kind: :book, page_count: 380})
      tracked = track!(cached.source_id, %{kind: :book, progress_page: 214})

      # Read the cache row back rather than trusting the create result: the
      # claim is that the column exists and stores, not that Ash echoed it.
      reloaded = Ash.get!(CachedTitle, cached.id)
      assert reloaded.page_count == 380

      # And reach it the way a shelf does — by {source, source_id}, no join.
      assert %CachedTitle{page_count: 380} = Release.cached_for(tracked)

      progress = CachedTitle.progress(reloaded, tracked.progress_page)

      assert progress == {:fraction, 214, 380}
      assert label(progress) == "p.214/380"
      assert_in_delta CachedTitle.ratio(progress), 0.5631, 0.0001
    end

    test "a series ring counts watch ticks, not the season bookmark", %{prefix: prefix} do
      cached = cache!(prefix, %{kind: :tv, source: :tmdb, episode_count: 8})

      tracked =
        TrackedTitle
        |> Ash.Changeset.for_create(:create, %{
          source: :tmdb,
          source_id: cached.source_id,
          kind: :tv,
          status: :watching,
          # The bookmark says "episode 5 of season 2" — a position inside a
          # season, which is not the numerator and must not be mistaken for it.
          progress_season: 2,
          progress_episode: 5
        })
        |> Ash.create!()

      for n <- 1..5 do
        Watch
        |> Ash.Changeset.for_create(:create, %{
          tracked_title_id: tracked.id,
          episode_source_id: "#{prefix}ep-#{n}",
          season_number: 1,
          episode_number: n
        })
        |> Ash.create!()
      end

      ticks =
        Watch
        |> Ash.Query.for_read(:episode_ticks, %{tracked_title_id: tracked.id})
        |> Ash.read!()

      assert length(ticks) == 5

      progress = CachedTitle.progress(Release.cached_for(tracked), length(ticks))

      assert progress == {:fraction, 5, 8}
      assert label(progress) == "p.5/8"
      assert_in_delta CachedTitle.ratio(progress), 0.625, 0.0001
    end

    test "an untouched title is an empty ring, not an absent one", %{prefix: prefix} do
      cached = cache!(prefix, %{kind: :book, page_count: 380})
      tracked = track!(cached.source_id, %{kind: :book})

      assert tracked.progress_page == nil

      progress = CachedTitle.progress(cached, tracked.progress_page)

      assert progress == {:fraction, 0, 380}
      assert CachedTitle.ratio(progress) == 0.0
    end

    test "a position past a stale total keeps the label honest and the ring inside 1.0",
         %{prefix: prefix} do
      # The user is on page 400 of an edition the cache thinks is 380 pages.
      cached = cache!(prefix, %{kind: :book, page_count: 380})

      progress = CachedTitle.progress(cached, 400)

      assert progress == {:fraction, 400, 380}, "must not rewrite where the user says they are"
      assert CachedTitle.ratio(progress) == 1.0, "the ring must not sweep past full"
    end
  end

  describe "each kind's denominator comes from its own column" do
    test "episodes for tv and anime, pages for books, tracks for albums", %{prefix: prefix} do
      assert prefix |> cache!(%{kind: :tv, source: :tmdb, episode_count: 8}) |> denominator() == 8

      assert prefix
             |> cache!(%{kind: :anime, source: :anilist, episode_count: 24})
             |> denominator() == 24

      assert prefix |> cache!(%{kind: :book, page_count: 380}) |> denominator() == 380

      assert prefix
             |> cache!(%{kind: :album, source: :musicbrainz, track_count: 12})
             |> denominator() == 12
    end

    test "a film has none, because its total is a runtime in another unit", %{prefix: prefix} do
      cached = cache!(prefix, %{kind: :movie, source: :tmdb, runtime_minutes: 137})

      assert CachedTitle.denominator(cached) == nil

      # Screen 10's "18M LEFT" does that conversion where the units are visible.
      progress = CachedTitle.progress(cached, 7140)
      assert progress == {:position, 7140}
      assert CachedTitle.ratio(progress) == nil
    end

    test "the wrong kind's count is never borrowed", %{prefix: prefix} do
      # A book row carrying an episode count is nonsense a provider could still
      # hand over. It must not become the book's denominator.
      cached = cache!(prefix, %{kind: :book, episode_count: 8, track_count: 12})

      assert cached.page_count == nil
      assert CachedTitle.denominator(cached) == nil
      assert label(CachedTitle.progress(cached, 214)) == "p.214"
    end
  end

  describe "an unknown denominator degrades instead of lying" do
    test "an evicted cache row leaves the position standing alone", %{prefix: prefix} do
      cached = cache!(prefix, %{kind: :book, page_count: 380})
      tracked = track!(cached.source_id, %{kind: :book, progress_page: 214})

      assert CachedTitle.progress(Release.cached_for(tracked), 214) == {:fraction, 214, 380}

      # The wipe the whole durable/cached split exists to survive.
      CachedTitle
      |> Ash.Query.filter(source_id == ^tracked.source_id)
      |> Ash.read!()
      |> Enum.each(&Ash.destroy!/1)

      assert Release.cached_for(tracked) == nil

      survivor = Ash.get!(TrackedTitle, tracked.id)
      assert survivor.progress_page == 214

      progress = CachedTitle.progress(Release.cached_for(survivor), survivor.progress_page)

      assert progress == {:position, 214}
      assert label(progress) == "p.214"
      assert CachedTitle.ratio(progress) == nil
    end

    test "a provider that never said how long the book is", %{prefix: prefix} do
      # Open Library at the work level: a title, no pagination.
      cached = cache!(prefix, %{kind: :book, page_count: nil})

      progress = CachedTitle.progress(cached, 214)

      assert progress == {:position, 214}
      assert CachedTitle.ratio(progress) == nil
    end

    test "nothing known at all says nothing" do
      assert CachedTitle.progress(nil, nil) == :unknown
      assert CachedTitle.ratio(:unknown) == nil
      assert label(:unknown) == "—"
    end

    test "no degraded answer ever renders a denominator", %{prefix: prefix} do
      unknowable = [
        nil,
        cache!(prefix, %{kind: :book, page_count: nil}),
        cache!(prefix, %{kind: :movie, source: :tmdb, runtime_minutes: 137}),
        # Rows that never met a changeset — a fetcher's struct, a decoded blob.
        %CachedTitle{kind: :book, page_count: 0},
        %CachedTitle{kind: :book, page_count: -1},
        %CachedTitle{kind: :tv, episode_count: 0},
        %CachedTitle{kind: :album, track_count: 0}
      ]

      assert length(unknowable) == 7

      for cached <- unknowable do
        progress = CachedTitle.progress(cached, 214)
        rendered = label(progress)

        assert progress == {:position, 214}, "expected a bare position, got #{inspect(progress)}"
        assert rendered == "p.214"
        refute rendered =~ "/", "invented a denominator: #{rendered}"
        assert CachedTitle.ratio(progress) == nil, "drew a ring with nothing to divide by"
      end
    end

    test "a zero denominator cannot be stored in the first place", %{prefix: prefix} do
      attempted = [page_count: 0, episode_count: 0, track_count: 0]

      for {attr, value} <- attempted do
        attrs = %{
          source: :openlibrary,
          source_id: prefix <> "zero-#{attr}",
          kind: :book,
          fetched_at: DateTime.utc_now()
        }

        assert {:error, %Ash.Error.Invalid{}} =
                 CachedTitle
                 |> Ash.Changeset.for_create(:create, Map.put(attrs, attr, value))
                 |> Ash.create(),
               "#{attr} accepted 0; a source answering 0 means it does not know"
      end

      # And nothing was written by the attempts above.
      ids = Enum.map(attempted, fn {attr, _} -> prefix <> "zero-#{attr}" end)

      rows =
        CachedTitle
        |> Ash.Query.filter(source_id in ^ids)
        |> Ash.read!()

      assert rows == []
    end
  end

  describe "the columns themselves" do
    test "are public, integer and nullable" do
      for name <- [:episode_count, :page_count, :track_count] do
        attribute = Ash.Resource.Info.attribute(CachedTitle, name)

        assert attribute, "#{name} is missing from CachedTitle"
        assert attribute.type == Ash.Type.Integer, "#{name} must be an integer count"
        assert attribute.public?, "#{name} is read by the shelves and must be public"

        assert attribute.allow_nil?,
               "#{name} must be nullable: an unknown count is the normal case"
      end
    end
  end

  defp denominator(cached), do: CachedTitle.denominator(cached)
end
