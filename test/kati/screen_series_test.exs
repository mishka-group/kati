defmodule Kati.ScreenSeriesTest do
  @moduledoc """
  Screens 04 and 58 against `Kati.Media`, and against an empty database.

  ## Why this is not covered by the sweeps

  `Kati.ScreenRenderSweepTest` mounts each screen once and asserts it renders;
  `Kati.ScreenTapSweepTest` taps what that render drew. Neither reads the copy,
  so an episode list that queried the wrong title, sliced the wrong season or
  drew somebody else's runtimes would pass both.

  `Kati.ScreenDesignLiteralTest` does read the copy and cannot settle it either,
  for the reason `Kati.ScreenEmptyDatabaseTest` sets out at length: that suite
  has no Ecto sandbox, one SQLite file is shared, and which of the two paths ran
  when the sweep rendered screen 04 moves with `--seed`.
  `Kati.ScreenEmptyDatabaseTest` pins the fallback. Nothing pinned the other
  half — that the migration reads what it claims to read — which is this file.

  ## What it asserts, and why each one is here rather than assumed

    * **`3 SEASONS` survives a partly-fetched title.** The fixture caches three
      seasons and the episodes of exactly one, which is the state
      `Kati.Media.CachedSeason` was created for: derived from the episodes the
      answer would be `1 SEASON`, confidently and wrongly. The season strip is
      checked the same way and for the same reason.
    * **The counter divides by the provider's count.** Six episodes are cached
      and the season says nine, so a denominator taken from `length(episodes)`
      reads `5 of 6` — right-looking, and a different claim. Nine rather than
      the drawing's seven, so a screen still on its fallback cannot pass this
      by agreeing with the frame it was captured from.
    * **Specials are in neither.** A season 0 row is cached, and `3 SEASONS`
      means three.
    * **The next airing goes through `Kati.Media.Release`.** Once with an
      `:exact` instant, and once with a bare year, because #74's whole rule is
      that the second must not become a day. The Persian page draws nothing at
      all there, and that is a decision `Kati.Screens.Series` argues for
      rather than an omission.
    * **The two pages are one page.** 58 reads through
      `Kati.Screens.Series.tracked_series/0`, so the same fixture is asserted
      twice — same season, same denominator, same rows — with only the wording
      allowed to differ. A second query written into the Persian file would
      pass every assertion above and fail these.
    * **`LUMEN+` and `2024` stay gone.** Both are decisions
      (`Kati.Screens.Series`'s moduledoc says why), and a later round that
      quietly fills either from a sample row should fail here rather than ship
      an availability claim nothing stores.

  ## The wipe in `setup`

  The suite shares one SQLite file, so "an empty database" has to be made rather
  than assumed — and what this module writes is not inert either: a tracked
  series left behind would put a stranger's title on this screen, on 58, and on
  screen 03's grid the moment another module mounts one. Same reasoning and the
  same `on_exit` as `Kati.ScreenFilmTest`.
  """
  use Mob.ScreenCase, async: false

  require Ash.Query

  alias Kati.Calendar.Shamsi
  alias Kati.Library.Sample
  alias Kati.Media.CachedEpisode
  alias Kati.Media.CachedSeason
  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Screens.Series
  alias Kati.Screens.Series

  # Child first: a watch carries the foreign key. The two cache tables reference
  # nothing and are referenced by nothing — that is the point of the value-pair
  # split — so their order does not matter and they are emptied anyway.
  @tables ~w(media_watches media_content_warnings tracked_titles cached_titles cached_seasons cached_episodes)

  @source :tmdb
  @title_id "series-north"

  setup do
    empty_the_tables!()
    on_exit(&empty_the_tables!/0)
    :ok
  end

  defp empty_the_tables! do
    for table <- @tables, do: Ecto.Adapters.SQL.query!(Kati.Repo, "delete from #{table}", [])
    :ok
  end

  # ── The fixture ─────────────────────────────────────────────────────────────

  defp cached_title!(attrs \\ %{}) do
    CachedTitle
    |> Ash.Changeset.for_create(
      :create,
      Map.merge(
        %{
          source: @source,
          source_id: @title_id,
          kind: :tv,
          title: "Northlight Bay",
          genres: "Thriller",
          poster_path: "cartog60",
          fetched_at: DateTime.utc_now()
        },
        attrs
      )
    )
    |> Ash.create!()
  end

  defp season!(number, attrs) do
    CachedSeason
    |> Ash.Changeset.for_create(
      :create,
      Map.merge(
        %{
          source: @source,
          title_source_id: @title_id,
          season_number: number,
          fetched_at: DateTime.utc_now()
        },
        attrs
      )
    )
    |> Ash.create!()
  end

  defp episode!(source_id, attrs) do
    CachedEpisode
    |> Ash.Changeset.for_create(
      :create,
      Map.merge(
        %{
          source: @source,
          source_id: source_id,
          title_source_id: @title_id,
          fetched_at: DateTime.utc_now()
        },
        attrs
      )
    )
    |> Ash.create!()
  end

  defp tracked!(attrs \\ %{}) do
    TrackedTitle
    |> Ash.Changeset.for_create(
      :create,
      Map.merge(
        %{
          source: @source,
          source_id: @title_id,
          kind: :tv,
          status: :watching,
          progress_season: 2
        },
        attrs
      )
    )
    |> Ash.create!()
  end

  defp tick!(tracked, episode_source_id) do
    Watch
    |> Ash.Changeset.for_create(:create, %{
      tracked_title_id: tracked.id,
      episode_source_id: episode_source_id
    })
    |> Ash.create!()
  end

  # Three seasons and a specials shelf, the episodes of season 2 only, five of
  # them ticked, and a sixth still to air. Not one of the drawing's own values
  # is reused: the drawing is `The Long Hollow`, `Season 2`, seven episodes and
  # `48 min`, so a screen that never left its fallback cannot pass a single
  # assertion below by coincidence.
  #
  # Season 2 is named `Part Two` on purpose. The English page must use the
  # provider's name and the Persian page must not — a Persian heading built out
  # of an English string is the failure `Kati.Screens.Series` says it is
  # avoiding, and only a season whose name is not "Season 2" can tell.
  defp a_series!(opts \\ []) do
    next_at = Keyword.get(opts, :next_at, DateTime.add(DateTime.utc_now(), 7, :day))
    next_confidence = Keyword.get(opts, :next_confidence, :exact)

    cached_title!()
    season!(0, %{name: "Specials", episode_count: 2})
    season!(1, %{name: "Season 1", episode_count: 5})
    # Nine, not seven: the drawing's own counter reads `5 of 7`, so a fixture
    # that agreed with it would let a screen still on its fallback pass every
    # assertion about the counter — on both pages.
    season!(2, %{name: Keyword.get(opts, :season_name, "Part Two"), episode_count: 9})
    season!(3, %{name: "Season 3", episode_count: 3})

    aired_from = DateTime.add(DateTime.utc_now(), -60, :day)

    for n <- 1..5 do
      episode!("north-s2e#{n}", %{
        season_number: 2,
        episode_number: n,
        title: "Episode #{n} of Part Two",
        runtime_minutes: 40 + n,
        air_at: DateTime.add(aired_from, 7 * n, :day),
        date_confidence: :day
      })
    end

    episode!("north-s2e6", %{
      season_number: 2,
      episode_number: 6,
      title: "The Ferry Road",
      runtime_minutes: 50,
      air_at: next_at,
      date_confidence: next_confidence
    })

    tracked = tracked!()
    for n <- 1..5, do: tick!(tracked, "north-s2e#{n}")
    tracked
  end

  defp texts(tree), do: tree |> find_all(:text) |> Enum.map(&(&1.props[:text] || ""))

  defp drawn?(tree, string), do: Enum.any?(texts(tree), &(&1 == string))

  defp local(%DateTime{} = at), do: Kati.Time.in_zone(at, Kati.Time.device_zone())

  # ── An empty database ───────────────────────────────────────────────────────

  describe "an empty database" do
    test "nothing is tracked, so both pages draw their drawing" do
      assert Series.tracked_series() == nil,
             "a series answered against an empty database, so nothing below is measuring " <>
               "the fallback"

      assert Series.series() == Series.empty_series(),
             "04 answers its own empty page against an empty store. A shelf with nothing " <>
               "on it is not a reason to draw somebody else's show"

      refute Series.series() == Series.drawn_series(),
             "the drawing is back on the live path — `drawn_series/0` belongs to the " <>
               "design-literal comparison now, not to a reader"
    end

    test "a tracked series with nothing cached about it draws ITSELF, empty" do
      # This asserted the opposite until 6 September, and the opposite was
      # MOVIES-AND-TV.md #38: a hand-typed series has no cached seasons and no
      # cached episodes, so `facts/1` answered `nil` and every one of them
      # opened as **The Long Hollow** — hollow71 artwork, three seasons and
      # seven named episodes, none of which the reader had ever heard of.
      #
      # The gate this screen keeps is about whether a ROW exists, not about
      # whether a provider has filled it in. There is a row, so the page is
      # that row's: its own title, an empty strip, `0 of 0 watched`, and a card
      # where the list would be.
      tracked = tracked!()

      facts = Series.tracked_series()

      refute facts == nil
      assert facts.tracked_id == tracked.id
      assert facts.seasons == [%{number: 2, name: nil, total: 0, episodes: []}]

      page = Series.series()

      refute page == Series.drawn_series(),
             "a reader's own hand-typed series opened as somebody else's show"

      assert page.episodes == []
      assert page.total == 0
      assert page.watched == 0
    end

    test "and draws board 248: whose doing it is, and what still works" do
      tracked!()

      drawn = inspect(Series.episodes(Series.series()), limit: :infinity)

      # The card said "Kati has this show but not its episode list" over a
      # centred tile — which reads as a fault to be repaired and tells the
      # reader nothing they can do. Board 248 says whose doing it is, promises
      # what happens if a source finds it later, and then lists the three
      # things that still work.
      assert drawn =~ "No episode list yet."
      assert drawn =~ "You added this by hand"
      assert drawn =~ "nothing you typed changes"
      refute drawn =~ "No episodes yet"

      # `Kati.UI.SettingsList.eyebrow_muted/1` upcases, as every eyebrow does;
      # the drawing writes it in sentence case and `Kati.DesignLiterals` compares
      # case-insensitively for exactly this reason.
      assert drawn =~ "WHAT STILL WORKS"

      for row <- ["Log a watch", "Drop this show", "Remove from library"] do
        assert drawn =~ row, "board 248's #{row} row is missing"
      end

      assert drawn =~ "Works without an episode list"
      assert drawn =~ "Keeps where you stopped"
      assert drawn =~ "No primary button here."
    end

    test "and the three rows act, rather than being a picture of three rows" do
      tracked!()

      drawn = inspect(Series.episodes(Series.series()), limit: :infinity)

      for tag <- [":rate_title", ":open_drop_sheet", ":remove_title"] do
        assert drawn =~ tag, "board 248's row for #{tag} carries no tap"
      end
    end

    test "and a drawn series carries no taps, because there is nothing to act on" do
      # The rule this repository keeps everywhere: a control with nowhere to go
      # draws no tap rather than a dead one.
      drawn = inspect(Series.still_works(nil), limit: :infinity)

      refute drawn =~ ":rate_title"
      refute drawn =~ ":remove_title"
    end

    test "and the primary slot stays empty, which is board 248's own ruling" do
      tracked!()

      # "There is no next episode to mark, and a primary that refuses is worse
      # than none."
      drawn = inspect(Series.actions(Series.series()), limit: :infinity)

      refute drawn =~ ":mark_next"
      refute drawn =~ "Mark"
    end

    test "and none of the drawing's episodes are on it" do
      tracked!()

      words =
        inspect(
          Series.render(%{
            series: Series.series(),
            back: "Library",
            menu?: false,
            save_error: nil
          }),
          limit: :infinity
        )

      for ep <- Sample.series().episodes do
        refute words =~ ep.title, "the drawing's episodes are on a real reader's series"
      end
    end

    test "no string the drawing carries reaches screen 04's tree" do
      tree = tree(mount_screen(Series))
      drawn = Sample.series()

      for string <- [drawn.title, drawn.meta, drawn.season, drawn.next_air] do
        refute drawn?(tree, string),
               "#{inspect(string)} is on the page of a reader who owns no series"
      end

      refute drawn?(tree, "#{drawn.watched} of #{drawn.total} watched")

      for label <- drawn.seasons, do: refute(drawn?(tree, label))

      for ep <- drawn.episodes do
        refute drawn?(tree, ep.title)
        refute drawn?(tree, ep.sub)
      end

      # The page itself still renders: the frame is a state of 04, not a blank
      # process. Board 248 draws the same shape with an empty primary.
      assert drawn?(tree, "EPISODES")
    end

    test "no string the drawing carries reaches board 58's tree either" do
      # Board 58 is screen 04 under `:fa` since mishka-group/kati#103, so what
      # this asks is that the empty page is empty in BOTH locales: a fallback
      # left on one side only would put the drawing in front of one reader.
      Kati.Locale.as(:fa, fn ->
        tree = tree(mount_screen(Series))
        drawn = Series.drawn_series()

        for string <- [drawn.title, drawn.meta, drawn.season] do
          refute drawn?(tree, string),
                 "#{inspect(string)} is on the page of a reader who owns no series"
        end

        refute drawn?(tree, Series.watched_line(drawn.watched, drawn.total))

        for label <- drawn.seasons,
            do: refute(drawn?(tree, Series.season_pill_label(label)))

        for ep <- drawn.episodes do
          refute drawn?(tree, ep.title)
          refute drawn?(tree, ep.sub)
        end
      end)
    end

    test "the season pills still switch, so the control is not decoration" do
      # `by_season` rides on the drawn map too. A fallback that dropped it would
      # leave three pills that change nothing, which is the state the Sample's
      # extra seasons exist to prevent.
      drawn = Series.drawn_series()

      assert Map.keys(drawn.by_season) |> Enum.sort() == Enum.sort(drawn.seasons)
      assert drawn.by_season["S1"].season == "Season 1"
      assert drawn.by_season["S1"].total == length(drawn.by_season["S1"].episodes)

      # And the same map under `:fa`, where the heading is built from the number
      # because the fixture's seasons carry Kati's own names rather than a
      # provider's.
      Kati.Locale.as(:fa, fn ->
        fa = Series.drawn_series()
        assert map_size(fa.by_season) == length(fa.seasons)
      end)
    end
  end

  # ── The user's own series ───────────────────────────────────────────────────

  describe "with the user's own series, on screen 04" do
    test "the page is the user's and none of the drawn values survive" do
      a_series!()
      series = Series.series()

      assert series.title == "Northlight Bay"
      assert series.season == "Part Two"
      assert series.current_season == "S2"
      assert series.seasons == ["S1", "S2", "S3"]

      tree = tree(mount_screen(Series))
      drawn = Sample.series()

      for string <- [drawn.title, drawn.meta, drawn.season, drawn.next_air] do
        refute drawn?(tree, string),
               "#{inspect(string)} is the drawing's, and a real series is being shown"
      end

      for ep <- drawn.episodes do
        refute drawn?(tree, ep.title), "#{ep.title} is an episode of the drawing's season"
      end
    end

    test "the season count is the inventory's, not the cached episodes'" do
      a_series!()

      # Only season 2's episodes are cached. Derived from them the answer is
      # `1 SEASON`, which is exactly the confident wrong number
      # `Kati.Media.CachedSeason` was split out to prevent.
      assert Series.series().meta == "THRILLER · 3 SEASONS"
      assert drawn?(tree(mount_screen(Series)), "THRILLER · 3 SEASONS")
    end

    test "specials are in neither the count nor the strip" do
      a_series!()
      series = Series.series()

      refute "S0" in series.seasons
      assert series.meta =~ "3 SEASONS"
    end

    test "the counter divides by the provider's count, not by what is cached" do
      a_series!()
      series = Series.series()

      # Six episodes cached, nine announced, five ticked.
      assert length(series.episodes) == 6
      assert series.watched == 5
      assert series.total == 9
      assert drawn?(tree(mount_screen(Series)), "5 of 9 watched")
      assert_in_delta Series.fraction(series), 5 / 9, 0.0001
    end

    test "a season with no episodes cached still counts against its own total" do
      a_series!()
      view = Series.series().by_season["S1"]

      assert view.episodes == [], "season 1's episodes were never cached"

      assert view.total == 5,
             "the denominator came from the empty episode list rather than from " <>
               "`Kati.Media.CachedSeason.episode_count`"
    end

    test "a season with a zero denominator does not divide by zero" do
      # `min: 1` keeps a zero out of the column, so the case this guards is a
      # season a provider announced and never populated: no `episode_count` and
      # no cached episodes. `5 / 0` is an ArithmeticError, not an empty bar.
      cached_title!()
      season!(1, %{name: "Season 1"})
      tracked!(%{progress_season: 1})

      series = Series.series()
      assert series.total == 0
      assert Series.fraction(series) == 0.0
      assert drawn?(tree(mount_screen(Series)), "0 of 0 watched")
    end

    test "each episode row is its own cached record" do
      a_series!()
      series = Series.series()

      first = hd(series.episodes)
      assert first.n == 1
      assert first.title == "Episode 1 of Part Two"
      assert first.sub =~ ~r/^41 min · /
      assert first.watched
      assert first.aired

      last = List.last(series.episodes)
      assert last.title == "The Ferry Road"
      assert last.sub =~ ~r/^Airs /
      refute last.watched
      refute last.aired, "the sixth episode is a week away and cannot be ticked"
    end

    test "an episode a provider announced without naming is not called TBA" do
      cached_title!()
      season!(1, %{name: "Season 1", episode_count: 1})
      episode!("north-s1e1", %{season_number: 1, episode_number: 1})
      tracked!(%{progress_season: 1})

      assert hd(Series.series().episodes).title == "Episode 1"
    end

    test "the next airing is Release's answer, drawn with its hour" do
      at = DateTime.add(DateTime.utc_now(), 7, :day)
      a_series!(next_at: at)

      expected = at |> local() |> Calendar.strftime("%a %-d %b, %H:%M")
      assert Series.series().next_air == expected
      assert drawn?(tree(mount_screen(Series)), expected)
    end

    test "a bare year is drawn as a year and never as the first of January" do
      # #74's rule. `Kati.Media.Release.resolve_at/3` hands back a period with no
      # day in the value at all, so there is nothing here that could print one.
      year = DateTime.utc_now().year + 4
      at = DateTime.new!(Date.new!(year, 1, 1), ~T[00:00:00.000000], "Etc/UTC")
      a_series!(next_at: at, next_confidence: :year)

      assert Series.series().next_air == "#{year}"
      refute Series.series().next_air =~ "Jan"
    end

    test "a series with nothing announced draws no next-airing row at all" do
      cached_title!()
      season!(1, %{name: "Season 1", episode_count: 1})

      episode!("north-s1e1", %{
        season_number: 1,
        episode_number: 1,
        title: "Low Water",
        runtime_minutes: 46
      })

      tracked!(%{progress_season: 1})

      assert Series.series().next_air == nil
      refute drawn?(tree(mount_screen(Series)), "Next episode airs ")
    end

    test "the meta line still carries no year and no availability" do
      a_series!()
      meta = Series.series().meta

      refute meta =~ ~r/\d{4}/,
             "`next_release_at` is the NEXT release and would print next Tuesday as a " <>
               "series' debut year"

      refute meta =~ ~r/LUMEN/i,
             "`Kati.Media.Watch.service` is where the USER watched something, which is a " <>
               "different fact from where a series can be watched"

      refute drawn?(tree(mount_screen(Series)), Sample.series().meta)
    end

    test "the newest series on the shelf is the one drawn, across tv and anime" do
      a_series!()

      CachedTitle
      |> Ash.Changeset.for_create(:create, %{
        source: @source,
        source_id: "anime-ember",
        kind: :anime,
        title: "Ember & Ash",
        fetched_at: DateTime.utc_now()
      })
      |> Ash.create!()

      CachedSeason
      |> Ash.Changeset.for_create(:create, %{
        source: @source,
        title_source_id: "anime-ember",
        season_number: 1,
        episode_count: 12,
        fetched_at: DateTime.utc_now()
      })
      |> Ash.create!()

      TrackedTitle
      |> Ash.Changeset.for_create(:create, %{
        source: @source,
        source_id: "anime-ember",
        kind: :anime,
        status: :watching
      })
      |> Ash.create!()

      # `Kati.Media.Changes.Touch` stamps `last_touched_at` on every write, so the
      # anime row is the newer of the two and an `:anime` shelf this screen never
      # read would leave `Northlight Bay` on the page.
      assert Series.series().title == "Ember & Ash"
    end

    test "an archived series is off this screen, as it is off the shelf" do
      a_series!()
      assert Series.series().title == "Northlight Bay"

      tracked = Ash.read_one!(Ash.Query.filter(TrackedTitle, source_id == ^@title_id))

      tracked
      |> Ash.Changeset.for_update(:update, %{archived: true})
      |> Ash.update!()

      assert Series.series() == Series.empty_series(),
             "`:shelf` is where *keeps history, hides from shelf* is enforced, and this " <>
               "screen reads through it — archiving the only series empties the page"
    end
  end

  # ── The same series, in Persian ─────────────────────────────────────────────

  # Board 58 is screen 04 under `:fa` since mishka-group/kati#103 folded
  # `Kati.Screens.SeriesFa` away, so this whole describe is that screen read in
  # the other script rather than a second module compared with the first.
  describe "board 58, which is screen 04 under :fa" do
    test "the numbers Kati writes are Persian and the provider's words are not" do
      a_series!()

      Kati.Locale.as(:fa, fn ->
        fa = Series.series()

        # `Thriller` is the provider's genre and `Part Two` its season name —
        # neither is Kati's to translate. `۳ فصل`, `فصل ۲`, the episode numbers
        # and the counter are all Kati's own arithmetic.
        # `Thriller` is the provider's word and `Kati.UI.eyebrow_label/1` does
        # not upcase Persian, so a mixed line keeps the provider's own case.
        assert fa.meta == "Thriller · ۳ فصل"
        assert fa.season == "Part Two"
        assert hd(fa.episodes).title == "Episode 1 of Part Two"
        assert Series.watched_line(fa.watched, fa.total) =~ ~r/^\p{N}+ از \p{N}+ دیده شده$/u
        assert Series.season_pill_label("S2") == "ف۲"
      end)
    end

    test "the heading is built from the number when the provider gave no name" do
      a_series!(season_name: nil)

      Kati.Locale.as(:fa, fn ->
        assert Series.series().season == "فصل ۲"
      end)
    end

    test "an unaired episode says when it airs, in Shamsi" do
      at = DateTime.add(DateTime.utc_now(), 7, :day)
      a_series!(next_at: at)

      Kati.Locale.as(:fa, fn ->
        fa = Series.series()

        assert List.last(fa.episodes).sub ==
                 "پخش " <> Kati.Locale.date(DateTime.to_date(local(at)), :long)

        assert fa.next_air =~ "، ساعت "

        refute fa.next_air =~ ~r/[0-9]/,
               "an ASCII digit reached a Persian sentence Kati wrote"
      end)
    end

    test "a coarse date is the broadcast calendar's, in the reader's digits" do
      # 2026 spans ۱۴۰۴ and ۱۴۰۵, so a Gregorian period has no Shamsi
      # counterpart — and a broadcast year is a fact about the schedule rather
      # than a day in the reader's life, which is `Kati.Locale.year/1`'s rule.
      # The mirror drew nothing at all here; the fold draws the year, in
      # Persian digits, because a year the reader can act on beats a blank.
      year = DateTime.utc_now().year + 4
      at = DateTime.new!(Date.new!(year, 1, 1), ~T[00:00:00.000000], "Etc/UTC")
      a_series!(next_at: at, next_confidence: :year)

      assert Series.series().next_air == "#{year}"

      Kati.Locale.as(:fa, fn ->
        assert Series.series().next_air == Kati.Locale.number(year)
      end)
    end
  end
end
