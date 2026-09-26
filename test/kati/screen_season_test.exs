Code.require_file("../support/show_boards.exs", __DIR__)

defmodule Kati.ScreenSeasonTest do
  @moduledoc """
  Screen 34's running order, read from `Kati.Media` instead of frozen.

  This screen moved **partly**, and the partition is the thing under test here
  as much as the list is. Four claims:

    * **The list, the heading and the count are the user's.** Every line is a
      column on `Kati.Media.CachedEpisode` or `Kati.Media.CachedSeason`, and the
      tick is a `Kati.Media.Watch` row keyed on `episode_source_id` — which is
      the footnote's own rule, *your ticks follow the episode, not the number*.
    * **The order strip offers only the tiles it can fill, and the `PARTS 1–2`
      badge is still the drawing's.** The strip was the
      screen's central control and none of its three tiles was tappable.
      Making all three live would have been the worse fix — DVD has no numbers
      anywhere and Absolute had none either — so a tile with nothing behind it
      is dropped, and a strip of one is dropped whole. The tiles that remain
      renumber something, and that is asserted from both ends: the seasons a
      cache can renumber, and the seasons it cannot.
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
  @tables ~w(media_watches media_content_warnings tracked_titles cached_episodes cached_seasons cached_titles)

  @day 24 * 60 * 60

  setup do
    empty_the_tables!()
    on_exit(&empty_the_tables!/0)
    :ok
  end

  describe "with nothing to draw" do
    test "an empty library answers with its own empty season" do
      assert Season.season() == Season.empty_season()
      assert Season.tracked_season() == nil
    end

    test "a tracked series with no bookmark answers empty, not the drawing" do
      # `progress_season` is the only thing that says which season this screen
      # is of. Without it there is no referent, and picking one would be this
      # screen inventing the user's place in a show.
      track!(%{title: "Tidewrack", season: nil})

      season = Season.season()
      assert is_binary(season.tracked_id)
      assert Map.delete(season, :tracked_id) == Season.empty_season()
    end

    test "a bookmarked season with nothing cached answers empty" do
      # The list IS the screen. A heading and an order strip over an empty card
      # says less than the drawing does.
      track!(%{title: "Tidewrack", season: 2})

      season = Season.season()
      assert is_binary(season.tracked_id)
      assert Map.delete(season, :tracked_id) == Season.empty_season()
      assert text(tree(mount_screen(Season))) =~ "No episode list yet."
    end

    test "renders one sentence, and none of the drawing's own season in it" do
      words = text(tree(mount_screen(Season)))
      drawn = Kati.Test.ShowBoards.season()

      # N52-A: no order strip, no switch, no count over nothing — the page
      # says there is no season to draw.
      assert words =~ "No series in your library yet"
      for order <- drawn.orders, do: refute(words =~ order)
      refute words =~ "in this order"

      # Everything that was a claim about somebody's season is gone.
      refute words =~ drawn.title
      refute words =~ drawn.note

      for option <- drawn.options, do: refute(words =~ option.title)

      for episode <- drawn.episodes do
        refute words =~ episode.title
        refute words =~ episode.sub
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

    test "drops the whole order strip when nothing here can be renumbered" do
      season = Season.season()

      # One cached season and nothing before it, so `derived_absolute/1`
      # declines: numbering S2E1 as 1 is a claim about a season the user never
      # watched. What is left is one tile, and one segment is not a control.
      assert season.orders == ["Aired"]
      assert season.current_order == "Aired"
      refute text(tree(mount_screen(Season))) =~ "Absolute"
    end

    test "and leaves the subtitle exactly as drawn" do
      # This one has no column — see `Kati.Screens.Season`'s moduledoc — and a
      # round that wired it up would have invented one.
      assert Season.season().subtitle == Kati.Test.ShowBoards.season().subtitle
    end

    test "and offers only the switch it can honour" do
      # `Include specials` was drawn ON above a list `for_season/3` could not
      # put a season-0 special into, and `Merge multi-part` promised a merge
      # nothing records. Season 0 is read now, and the
      # switch that cannot be honoured is not offered.
      assert Enum.map(Season.season().options, & &1.title) == ["Include specials"]

      assert Enum.map(Kati.Test.ShowBoards.season().options, & &1.title) == [
               "Include specials",
               "Merge multi-part"
             ]
    end

    test "and says where the specials actually are" do
      [specials] = Season.season().options

      assert specials.on, "this season has one and the switch reads off"

      assert specials.sub == "Listed first, before the season",
             "the board's *Shown inline, at air date* is what `in_order(:aired)` cannot " <>
               "deliver: it sorts by {season, episode} and season 0 sorts ahead of the season"
    end

    test "and the switch is a control, not a picture of one" do
      # It was drawn in the right position and carried no tap, and `on:` was
      # *whether the provider filed any specials* rather than whether the reader
      # wants them — a row named for a choice, reporting a fact.
      [specials] = Season.season().options

      assert specials.tap, "the switch cannot be pressed"

      with_specials = Season.season(%{}, :aired, true)
      without = Season.season(%{}, :aired, false)

      [on] = with_specials.options
      [off] = without.options

      assert on.on
      refute off.on, "the switch reads on with the specials switched off"

      assert off.sub == "Hidden from this list",
             "the row says where they are when they are shown; it has to say so when they are not"

      refute Enum.any?(without.episodes, & &1.special),
             "the switch is off and a special is still in the list"

      assert length(without.episodes) < length(with_specials.episodes),
             "switching them off removed nothing"

      # And the count above the list moves with it, rather than promising rows
      # the list no longer has.
      refute without.eyebrow == with_specials.eyebrow
    end

    test "a season with none filed reports that, and offers nothing to press" do
      # The module's own rule for *Merge multi-part*, one row up: "A switch that
      # cannot be honoured is not offered." A season with no specials has
      # nothing to include or leave out.
      [row] = Season.real_options(false, true)

      refute row.on
      refute row.tap, "a season with no specials offered a switch anyway"
      assert row.sub == "None filed for this season"
    end

    test "the DVD tile is only ever the board's, and it is not tappable there" do
      # No source in `Kati.Media.CachePolicy.sources/0` provides per-episode DVD
      # numbering — `CachedEpisode`'s moduledoc gives the whole reason — so the
      # tile is never offered over real episodes and the board's own is a
      # picture rather than a dead control. Both halves pinned, so the drawn
      # tile and the missing order cannot drift apart without one failing.
      refute "DVD" in Season.season().orders
      assert "DVD" in Kati.Test.ShowBoards.season().orders
      assert Season.order_tap("DVD", :aired) == nil
      assert CachedEpisode.orders() == [:aired, :absolute]
    end

    test "renders the rows, and none of the sample module's own" do
      words = text(tree(mount_screen(Season)))

      assert words =~ "Season 2"
      assert words =~ "Tidewrack"
      assert words =~ "Making the Marsh"
      assert words =~ "SPECIAL"
      assert words =~ String.upcase("Episodes · 5 in this order")

      # Gone: this cache can renumber nothing, so the strip is dropped whole
      # rather than drawn with one live tile and two dead ones.
      refute words =~ "DVD"

      # Wired, and drawn in the state the list is actually in.
      assert words =~ "Include specials"

      refute words =~ "Merge multi-part",
             "a switch that promises a merge nothing records is still offered"

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
  describe "a tick made on screen 34" do
    setup :seed_season

    test "is accepted, which it was not" do
      # The row carried `number: "E2"` — a STRING, because it is a label that
      # can also be `S1` or `""` — and `Kati.Screens.Series.write_tick/2` falls
      # back to it for `Kati.Media.Watch.episode_number`, an integer column. So
      # every tick made on this screen came back `Is invalid.` and the ring
      # never filled. Screen 04's rows have carried `:n` and `:season` since
      # #46; this screen's never did, and its tick had never been pressed on a
      # real season.
      socket = mount_screen(Season).socket
      row = Enum.find_index(socket.assigns.season.episodes, &(&1.title == "Saltmarsh"))

      {:noreply, after_tap} =
        Season.handle_tap(String.to_atom("episode_#{row}"), socket)

      assert after_tap.assigns.save_error == nil
      assert Enum.at(after_tap.assigns.season.episodes, row).watched
    end

    test "and records the season and number the SHOW uses, not the label drawn" do
      socket = mount_screen(Season).socket
      row = Enum.find_index(socket.assigns.season.episodes, &(&1.title == "Saltmarsh"))

      {:noreply, _ticked} = Season.handle_tap(String.to_atom("episode_#{row}"), socket)

      written = Ash.read!(Watch) |> Enum.find(&(&1.episode_number == 3))

      assert written.season_number == 2
      assert written.episode_number == 3
    end
  end

  describe "a series the cache holds whole" do
    setup :seed_whole_series

    test "offers Absolute beside Aired, and never DVD", %{} do
      assert Season.season(%{}, :aired).orders == ["Aired", "Absolute"]
    end

    test "renumbers the season from the first episode of the show" do
      season = Season.season(%{}, :absolute)

      assert season.current_order == "Absolute"
      assert Enum.map(season.episodes, & &1.number) == ["E4", "E5", "E6"]
      assert Enum.map(season.episodes, & &1.title) == ["Four", "Five", "Six"]
    end

    test "and the same list in aired order is numbered within the season" do
      assert Season.season(%{}, :aired).episodes
             |> Enum.reject(& &1.special)
             |> Enum.map(& &1.number) == ["E1", "E2", "E3"]
    end

    test "drops the special, which is what absolute order means" do
      aired = Season.season(%{}, :aired)
      absolute = Season.season(%{}, :absolute)

      assert Enum.any?(aired.episodes, & &1.special)
      refute Enum.any?(absolute.episodes, & &1.special)
      assert absolute.eyebrow == "Episodes · 3 in this order"
    end

    test "a tick survives the renumbering, which is the footnote's own claim" do
      watched = fn season ->
        season.episodes |> Enum.filter(& &1.watched) |> Enum.map(& &1.title)
      end

      assert watched.(Season.season(%{}, :aired)) == ["Five"]
      assert watched.(Season.season(%{}, :absolute)) == ["Five"]
    end

    test "pressing a tile redraws the list in that order" do
      socket = mount_screen(Season).socket

      {:noreply, absolute} = Season.handle_tap(:order_Absolute, socket)
      assert absolute.assigns.season.current_order == "Absolute"
      assert Enum.map(absolute.assigns.season.episodes, & &1.number) == ["E4", "E5", "E6"]

      {:noreply, back} = Season.handle_tap(:order_Aired, absolute)
      assert back.assigns.season.current_order == "Aired"
      assert Enum.any?(back.assigns.season.episodes, & &1.special)
    end

    test "and pressing the tile already lit redraws the same list rather than nothing" do
      socket = mount_screen(Season).socket

      {:noreply, again} = Season.handle_tap(:order_Aired, socket)

      assert again.assigns.season.episodes == socket.assigns.season.episodes
    end

    test "a tag no order answers to leaves the screen alone" do
      socket = mount_screen(Season).socket

      {:noreply, after_tap} = Season.handle_tap(:order_DVD, socket)

      assert after_tap.assigns.season == socket.assigns.season
    end

    test "and a gap anywhere in the cache withdraws the offer" do
      # One episode deleted out of the middle of season 1, which is what a
      # half-finished fetch leaves behind. Absolute cannot be derived from it,
      # so the tile goes rather than drawing a list numbered from a guess.
      Kati.Repo.query!("delete from cached_episodes where title = 'Two'")

      assert Season.season(%{}, :absolute).orders == ["Aired"]
      assert Season.season(%{}, :absolute).current_order == "Aired"
    end
  end

  # Three episodes in S1, three in S2 plus a special, and the bookmark on S2 —
  # the smallest shape `derived_absolute/1` will answer for, and the one the
  # design's own note describes: *absolute order renumbers this season and
  # drops the special*.
  defp seed_whole_series(_context) do
    tracked = track!(%{title: "Tidewrack", season: 2})

    season!(tracked, %{number: 1, name: "Season 1", episode_count: 3})
    season!(tracked, %{number: 2, name: "Season 2", episode_count: 3})

    for {n, title} <- [{1, "One"}, {2, "Two"}, {3, "Three"}] do
      episode!(tracked, %{season: 1, number: n, title: title, runtime: 50, days: -100 + n})
    end

    episode!(tracked, %{
      season: 0,
      number: 1,
      title: "Marsh",
      runtime: 22,
      days: -60,
      special: true
    })

    episode!(tracked, %{season: 2, number: 1, title: "Four", runtime: 50, days: -50})
    five = episode!(tracked, %{season: 2, number: 2, title: "Five", runtime: 50, days: -40})
    episode!(tracked, %{season: 2, number: 3, title: "Six", runtime: 50, days: -30})

    tick!(tracked, five)

    %{tracked: tracked}
  end

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
      season_number: attrs[:season] || tracked.progress_season,
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
