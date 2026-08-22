defmodule Kati.ScreenSeasonTest do
  @moduledoc """
  Screen 34's running order, read from `Kati.Media` instead of frozen.

  This screen moved **partly**, and the partition is the thing under test here
  as much as the list is. Four claims:

    * **The list, the heading and the count are the user's.** Every line is a
      column on `Kati.Media.CachedEpisode` or `Kati.Media.CachedSeason`, and the
      tick is a `Kati.Media.Watch` row keyed on `episode_source_id` — which is
      the footnote's own rule, *your ticks follow the episode, not the number*.
    * **The order strip, the two switches and the `PARTS 1–2` badge are not**,
      and must still be drawn beside a real season. Each is a column that does
      not exist rather than a query nobody wrote, and
      `Kati.Screens.Season`'s moduledoc says which is which. A round that
      quietly wired one of them up would be inventing a column, so this file
      asserts they are unchanged rather than merely present.
    * **The footnote loses its first sentence and keeps its second.** `Absolute
      order renumbers this season 27–35` is a claim about one particular season;
      *your ticks follow the episode, not the number* is true of every one.
    * **With nothing to draw it still draws the drawing** — and there are three
      ways to have nothing, not one: no tracked series, a tracked series with no
      `progress_season`, and a bookmarked season with no cached episodes.

  ## The shared database

  `test/test_helper.exs` gives the whole suite one SQLite file, so an empty
  library has to be made rather than assumed — the same reason
  `Kati.ScreenUpNextTest` and `Kati.MediaEpisodeTest` empty their tables in
  `setup`. The wipe afterwards is what keeps `Kati.ScreenDesignLiteralTest`
  mounting screen 34 against a library with nothing in it, which is what lets it
  find the drawing's own copy.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedEpisode
  alias Kati.Media.CachedSeason
  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Screens.Season

  # Child first: a watch carries the only foreign key in the domain.
  @tables ~w(media_watches tracked_titles cached_episodes cached_seasons cached_titles)

  @day 24 * 60 * 60

  setup do
    empty_the_tables!()
    on_exit(&empty_the_tables!/0)
    :ok
  end

  describe "with nothing to draw" do
    test "an empty library answers with the drawing's own season, whole" do
      assert Season.season() == Season.drawn_season()
      assert Season.tracked_season() == nil
    end

    test "a tracked series with no bookmark answers with the drawing" do
      # `progress_season` is the only thing that says which season this screen
      # is of. Without it there is no referent, and picking one would be this
      # screen inventing the user's place in a show.
      track!(%{title: "Tidewrack", season: nil})

      assert Season.season() == Season.drawn_season()
    end

    test "a bookmarked season with nothing cached answers with the drawing" do
      # The list IS the screen. A heading and an order strip over an empty card
      # says less than the drawing does.
      track!(%{title: "Tidewrack", season: 2})

      assert Season.season() == Season.drawn_season()
    end

    test "renders every line frame 34 draws" do
      words = text(tree(mount_screen(Season)))
      drawn = Season.drawn_season()

      assert words =~ drawn.title
      assert words =~ drawn.subtitle
      assert words =~ String.upcase(drawn.eyebrow)
      assert words =~ drawn.note

      for order <- drawn.orders, do: assert(words =~ order)
      for option <- drawn.options, do: assert(words =~ option.title)

      for episode <- drawn.episodes do
        assert words =~ episode.number
        assert words =~ episode.title
        assert words =~ episode.sub
      end
    end
  end

  describe "a bookmarked season" do
    setup :seed_season

    test "takes its heading from the provider's own name for the season" do
      assert Season.season().title == "Season 2"
    end

    test "falls back to the number when the season row has been evicted" do
      Kati.Repo.query!("delete from cached_seasons")

      assert Season.season().title == "Season 2"
    end

    test "counts the episodes it is about to draw" do
      assert Season.season().eyebrow == "Episodes · 5 in this order"
    end

    test "lists them in aired order, unnumbered last" do
      assert Enum.map(Season.season().episodes, & &1.title) == [
               "Making the Marsh",
               "Tidewrack",
               "Saltmarsh",
               "Nightjar",
               "Untitled"
             ]
    end

    test "labels each row with what the aired order calls it" do
      assert Enum.map(Season.season().episodes, & &1.number) == ["S1", "E2", "E3", "E4", ""]
    end

    test "marks the special with the bronze number and the badge, off one column" do
      [special | rest] = Season.season().episodes

      assert special.special
      assert special.badge == %{label: "SPECIAL", tone: :cream}
      refute Enum.any?(rest, & &1.special)
      assert Enum.all?(rest, &(&1.badge == nil))
    end

    test "puts the runtime beside the air date, and says which have aired" do
      [_special, aired, _saltmarsh, upcoming, bare] = Season.season().episodes

      assert aired.sub == "54m · " <> day_month(-30)
      assert upcoming.sub == "55m · airs " <> day_month(5)

      # No runtime and a bare year: both halves decline, so the line is empty
      # rather than a month pretending to be the first of it.
      assert bare.sub == ""
    end

    test "ticks by episode id, never by number" do
      ticked = Season.season().episodes |> Enum.filter(& &1.watched) |> Enum.map(& &1.title)

      assert ticked == ["Tidewrack"]
    end

    test "keeps only the half of the footnote that is true of every season" do
      season = Season.season()

      assert season.note == "Your ticks follow the episode, not the number."
      refute season.note =~ "27"
    end

    test "leaves the order strip, the switches and the subtitle exactly as drawn" do
      season = Season.season()
      drawn = Season.drawn_season()

      # None of these has a column — see `Kati.Screens.Season`'s moduledoc — and
      # a round that wired one up would have invented one.
      assert season.orders == drawn.orders
      assert season.current_order == drawn.current_order
      assert season.options == drawn.options
      assert season.subtitle == drawn.subtitle
    end

    test "the DVD tile is still offered, and CachedEpisode still has two orders" do
      # The strip is the design's, and the data can fill two of its three tiles.
      # Both halves are pinned so the drawn tile and the missing order cannot
      # drift apart without one of them failing.
      assert "DVD" in Season.season().orders
      assert CachedEpisode.orders() == [:aired, :absolute]
    end

    test "renders the rows, and none of the sample module's own" do
      words = text(tree(mount_screen(Season)))

      assert words =~ "Season 2"
      assert words =~ "Tidewrack"
      assert words =~ "Making the Marsh"
      assert words =~ "SPECIAL"
      assert words =~ String.upcase("Episodes · 5 in this order")

      # Still drawn, because none of these can be read.
      assert words =~ "DVD"
      assert words =~ "Include specials"
      assert words =~ "Merge multi-part"

      # All of these are in the drawn season and in none of these rows. A screen
      # that fell back would still draw a full running order.
      refute words =~ "Low Water"
      refute words =~ "Blackthorn"
      refute words =~ "PARTS 1"
      refute words =~ "renumbers this season"
    end
  end

  describe "picking the season" do
    test "follows the most recently touched series, across tv and anime" do
      # Created oldest first: `Kati.Media.Changes.Touch` forces `last_touched_at`
      # to now on every write, so creation order IS shelf order.
      older = track!(%{title: "Tidewrack", season: 2})
      episode!(older, %{number: 2, title: "Saltmarsh", runtime: 54, days: -30})

      newer = track!(%{title: "Nightjar", season: 4, kind: :anime})
      episode!(newer, %{number: 1, title: "Marram", runtime: 22, days: -2})

      assert Season.season().title == "Season 4"
      assert Enum.map(Season.season().episodes, & &1.title) == ["Marram"]
    end

    test "leaves out an archived series, however recently it was touched" do
      kept = track!(%{title: "Tidewrack", season: 2})
      episode!(kept, %{number: 2, title: "Saltmarsh", runtime: 54, days: -30})

      # `archived` means "keeps history, hides from shelf", and `:shelf` is where
      # that is enforced rather than in this screen.
      hidden = track!(%{title: "Nightjar", season: 4, archived: true})
      episode!(hidden, %{number: 1, title: "Marram", runtime: 22, days: -2})

      assert Season.season().title == "Season 2"
    end
  end

  # ── fixtures ───────────────────────────────────────────────────────────────

  # One bookmarked season: a special, two that have aired, one that has not, and
  # one a provider has announced without a number, a name, a runtime or a date
  # it is willing to stand behind.
  defp seed_season(_context) do
    tracked = track!(%{title: "Tidewrack", season: 2})

    season!(tracked, %{number: 2, name: "Season 2", episode_count: 9})

    special =
      episode!(tracked, %{
        number: 1,
        title: "Making the Marsh",
        runtime: 22,
        days: -32,
        special: true
      })

    ticked = episode!(tracked, %{number: 2, title: "Tidewrack", runtime: 54, days: -30})
    episode!(tracked, %{number: 3, title: "Saltmarsh", runtime: 49, days: -20})
    episode!(tracked, %{number: 4, title: "Nightjar", runtime: 55, days: 5})
    episode!(tracked, %{number: nil, title: nil, runtime: nil, days: 300, confidence: :year})

    tick!(tracked, ticked)

    %{special: special, ticked: ticked}
  end

  defp track!(attrs) do
    source_id = "season:#{System.unique_integer([:positive])}"
    kind = attrs[:kind] || :tv

    CachedTitle
    |> Ash.Changeset.for_create(:create, %{
      source: :tmdb,
      source_id: source_id,
      kind: kind,
      title: attrs[:title],
      fetched_at: now()
    })
    |> Ash.create!()

    TrackedTitle
    |> Ash.Changeset.for_create(:create, %{
      source: :tmdb,
      source_id: source_id,
      kind: kind,
      status: :watching,
      archived: attrs[:archived] || false,
      progress_season: attrs[:season]
    })
    |> Ash.create!()
  end

  defp season!(%TrackedTitle{} = tracked, attrs) do
    CachedSeason
    |> Ash.Changeset.for_create(:create, %{
      source: tracked.source,
      title_source_id: tracked.source_id,
      season_number: attrs.number,
      name: attrs[:name],
      episode_count: attrs[:episode_count],
      fetched_at: now()
    })
    |> Ash.create!()
  end

  defp episode!(%TrackedTitle{} = tracked, attrs) do
    source_id = "episode:#{System.unique_integer([:positive])}"

    CachedEpisode
    |> Ash.Changeset.for_create(:create, %{
      source: tracked.source,
      source_id: source_id,
      title_source_id: tracked.source_id,
      season_number: tracked.progress_season,
      episode_number: attrs[:number],
      special: attrs[:special] || false,
      title: attrs[:title],
      runtime_minutes: attrs[:runtime],
      air_at: DateTime.add(now(), (attrs[:days] || 0) * @day, :second),
      date_confidence: attrs[:confidence] || :exact,
      fetched_at: now()
    })
    |> Ash.create!()

    source_id
  end

  defp tick!(%TrackedTitle{} = tracked, episode_source_id) do
    Watch
    |> Ash.Changeset.for_create(:create, %{
      tracked_title_id: tracked.id,
      episode_source_id: episode_source_id,
      watched_at: now()
    })
    |> Ash.create!()
  end

  defp now, do: Kati.Time.now() |> DateTime.shift_zone!("Etc/UTC")

  defp day_month(days) do
    Kati.Time.now()
    |> DateTime.add(days * @day, :second)
    |> DateTime.to_date()
    |> Calendar.strftime("%-d %b")
  end

  defp empty_the_tables! do
    for table <- @tables,
        do: Ecto.Adapters.SQL.query!(Kati.Repo, "delete from #{table}", [])

    :ok
  end
end
