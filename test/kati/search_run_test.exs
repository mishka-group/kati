defmodule Kati.SearchRunTest do
  @moduledoc """
  `Kati.Search.run/1` against the store.

  #92's receipt is the store, not the screen, so these seed rows and assert
  what comes back — including the rows that must NOT, which is the half a
  presence-only assertion cannot make.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Search
  alias Kati.Search.Query

  setup do
    # `tracked_titles` is on this list because three tests below call
    # `Kati.Screens.AddByHand.save/1`, and that writes BOTH rows — a
    # `Kati.Media.CachedTitle` for search to find and a
    # `Kati.Media.TrackedTitle` to put it on the shelf. Only the first was
    # cleaned, so every run of this file left `Estuary Nights` tracked as a
    # manual movie, and screens 05 and 08 then drew a stored title where their
    # drawing has one — a failure that lands on
    # `Kati.ScreenDesignLiteralTest`, a file this one never touched, on the
    # seeds that order them the wrong way round.
    #
    # `Kati.ScreenTapSweepTest`'s own cleanup comment predicts this failure
    # word for word: *the list did not grow with the write*.
    on_exit(fn ->
      for table <-
            ~w(media_watches cached_episodes tracked_titles cached_titles events calendars book_notes books media_title_aliases) do
        Kati.Repo.query!("DELETE FROM " <> table, [])
      end
    end)

    for {id, title, kind} <- [
          {"1", "The Long Hollow", :tv},
          {"2", "Hollow Season", :tv},
          {"3", "Estuary", :movie}
        ] do
      Ash.create!(CachedTitle, %{
        source: :tmdb,
        source_id: id,
        kind: kind,
        title: title,
        fetched_at: DateTime.utc_now()
      })
    end

    :ok
  end

  test "a query returns what matches and nothing that does not" do
    result = Query.run("hollow")

    titles = Enum.map(result.titles, & &1.title)

    assert "The Long Hollow" in titles
    assert "Hollow Season" in titles

    # The half that matters. A presence-only assertion passes on a screen that
    # returns everything it has.
    refute "Estuary" in titles
  end

  test "the best tier comes first" do
    # `Hollow Season` is a prefix match, `The Long Hollow` a substring — tier 2
    # before tier 3, which is the order `tiers/0` specifies.
    assert [%{title: "Hollow Season"} | _rest] = Query.run("hollow").titles
  end

  test "each row says which kind it is" do
    assert %{sub: sub} = Enum.find(Query.run("hollow").titles, &(&1.title == "Hollow Season"))
    assert sub =~ "Series"
  end

  test "nothing typed and nothing found are different answers" do
    idle = Query.run("h")
    assert idle.idle?, "a query under the minimum is the screen waiting, not a result"

    empty = Query.run("zzzznothing")
    refute empty.idle?, "a long-enough query that matched nothing is the screen having looked"
    assert empty.titles == []

    # Both carry lists, never nil: the render maps over them, so a nil group
    # is a crash rather than a state.
    assert is_list(idle.titles) and is_list(idle.calendar)
  end

  test "the chips count the results they stand for" do
    counts = Query.run("hollow") |> Query.chip_counts() |> Map.new()

    assert counts["Screen"] == 2
    # Books included. It was omitted and passed only because this fixture has
    # no books — the same arithmetic this round fixed one group over.
    assert counts["All"] ==
             counts["Screen"] + counts["Books"] + counts["Calendar"] + counts["Notes"]
  end

  test "an empty store answers the no-match state rather than raising" do
    Kati.Repo.query!("DELETE FROM cached_titles", [])

    assert %{titles: [], calendar: [], notes: []} = Query.run("hollow")
  end

  describe "the seven fields the Screen scope names" do
    test "your own review of a film is findable" do
      # MOVIES-AND-TV.md #114. The Notes group and the Screen scope both said
      # a review was searchable and neither read one: `notes_for/1` knew only
      # `Kati.Books.Note`, and a film review lives on `Kati.Media.Watch`.
      tracked = track!("3")

      Ash.create!(Kati.Media.Watch, %{
        tracked_title_id: tracked.id,
        review: "A marram-grass film, all wind and no plot.",
        watched_on: ~D[2026-08-06],
        watched_at: DateTime.truncate(Kati.Time.now(), :second)
      })

      found = Query.run("marram")

      # A one-element list, bound rather than checked for truthiness: the
      # fixture seeds exactly one review and no book notes, so binding is a
      # stronger claim than the `assert found.note` it replaces.
      assert [note] = found.notes, "the review was not findable as a note"
      assert note.eyebrow =~ "NOTE"
      assert note.eyebrow =~ "ESTUARY", "the card did not say what the review is about"

      # And as a hit on the film itself, which is the Screen scope's own
      # `your review` field.
      assert "Estuary" in Enum.map(found.titles, & &1.title)
    end

    test "your own tags are findable" do
      tracked = track!("3")

      Ash.create!(Kati.Media.Watch, %{
        tracked_title_id: tracked.id,
        tags: "rainy sunday,comfort",
        watched_on: ~D[2026-08-06],
        watched_at: DateTime.truncate(Kati.Time.now(), :second)
      })

      assert "Estuary" in Enum.map(Query.run("comfort").titles, & &1.title)
    end

    test "the original title is findable" do
      Ash.create!(CachedTitle, %{
        source: :tmdb,
        source_id: "9",
        kind: :tv,
        title: "Frieren: Beyond Journey's End",
        title_original: "Sousou no Frieren",
        fetched_at: DateTime.utc_now()
      })

      titles = Enum.map(Query.run("sousou").titles, & &1.title)

      assert "Frieren: Beyond Journey's End" in titles
    end

    test "a name auto-detect learned is findable" do
      tracked = track!("3")
      Kati.Media.TitleAlias.learn("Estuary Nights 1080p WEB-DL", tracked.id)

      assert "Estuary" in Enum.map(Query.run("WEB-DL").titles, & &1.title)
    end

    test "and an alt title matching exactly is an exact match" do
      # The BEST tier across every name: a query that hits an alias head-on
      # should not sort under a substring hit on somebody else's title.
      tracked = track!("3")
      Kati.Media.TitleAlias.learn("Hollow", tracked.id)

      assert [%{title: "Estuary"} | _rest] = Query.run("hollow").titles
    end

    test "cast is named on the board and searched by nothing, and says so" do
      # Nothing on the device holds a person, so the field is struck rather
      # than quietly dropped — #74 at the field level.
      refute Kati.Search.kept?("cast")
      assert Kati.Search.kept?("your review")

      drawn = inspect(Kati.Screens.SearchSpec.scopes(), limit: :infinity)

      assert drawn =~ "cast", "the board stopped stating its own contract"
      assert drawn =~ "your review"
    end

    test "an episode TMDB wrote onto the device is findable by its own name" do
      # MOVIES-AND-TV.md #144. `Kati.Search.Query` never touched
      # `Kati.Media.CachedEpisode`, though board 19 draws an episode hit and
      # board 88's own tier-2 example is `hollow → Hollow Season`.
      track!("1")
      episode!("1", "Ash and After")

      found = Query.run("ash and after")

      assert [hit] = found.titles
      assert hit.title == "Ash and After"
      assert hit.sub == "Episode · S2E5"
      assert hit.kind == :episode
    end

    test "and it sits in the Screen group, counted by the Screen chip" do
      # Board 19 draws it as a sibling card in the same stack under one
      # eyebrow, and its chip row has no fourth chip.
      track!("1")
      episode!("1", "Hollow Ground")

      counts = "hollow" |> Query.run() |> Query.chip_counts() |> Map.new()

      assert counts["Screen"] == 3, "two titles and one episode, under one chip"
      refute Map.has_key?(counts, "Episodes")
    end

    test "it carries the series' poster and opens the series" do
      # A still is a 16:9 crop and the slot is 36x51 portrait, so the card
      # draws the parent's poster — which is what board 19 draws, same seed on
      # both cards.
      tracked = track!("1")
      episode!("1", "Ash and After")

      assert [hit] = Query.run("ash and after").titles
      assert hit.id == tracked.id, "an episode opens the series it belongs to"
      assert Kati.Screens.Search.hit_tag(hit) != nil
    end

    test "and its tap tag is its own, not its parent's" do
      # Both would emit one `accessibility_id` and `onNodeWithTag` throws on the
      # second match. The episode's `:id` IS its parent's, so the tag cannot
      # come from there.
      track!("1")
      episode!("1", "The Long Hollow")

      tags =
        "the long hollow"
        |> Query.run()
        |> Map.fetch!(:titles)
        |> Enum.map(&Kati.Screens.Search.hit_tag/1)

      assert length(tags) == 2, "the series and an episode of the same name both matched"
      assert tags == Enum.uniq(tags), "the two rows share one tag: #{inspect(tags)}"
    end

    test "an episode a provider has not named yet is not a hit" do
      # `title` is nullable because *TBA* is a string a provider invented.
      track!("1")
      episode!("1", nil, %{season_number: 3, episode_number: 1})

      assert Enum.all?(Query.run("hollow").titles, &(&1.title != nil))
    end
  end

  describe "the tie-break board 88 renders" do
    test "is recency, not the alphabet" do
      # MOVIES-AND-TV.md #129: `Kati.Search.rank/1` implemented tier-then-
      # recency, was public, was documented, and had no call site — every
      # group tied alphabetically instead.
      older = track!("1", ~U[2026-01-01 09:00:00Z])
      newer = track!("2", ~U[2026-09-01 09:00:00Z])

      assert older.id != newer.id

      # Both are substring hits on `hollow` at the same tier once the prefix
      # match is set aside, so only the tie-break can order them.
      assert [%{title: "Hollow Season"}, %{title: "The Long Hollow"}] =
               Query.run("hollow").titles
    end

    test "and an undated thing is not the newest thing" do
      assert Kati.Search.rank([{1, nil, :undated}, {1, ~D[2020-01-01], :dated}]) ==
               [:dated, :undated]
    end
  end

  describe "the Calendar and Books fields" do
    test "an event is findable by where it is" do
      # #74's last field: `location` has been on the board since it was drawn
      # and read by nothing.
      calendar =
        Kati.Calendars.Calendar
        |> Ash.Changeset.for_create(:create, %{display_name: "Search test", kind: :local})
        |> Ash.create!()

      Kati.Calendars.Event
      |> Ash.Changeset.for_create(:create, %{
        uid: "search-test-barbican@kati",
        calendar_id: calendar.id,
        origin: :kati,
        summary: "Book club",
        location: "The Barbican, Silk Street",
        kind: :event,
        status: :confirmed,
        dtstart_utc: ~U[2026-09-20 18:00:00Z],
        dtstart_wall: "20260920T190000",
        tzid: Kati.Time.device_zone(),
        duration_iso: "PT120M",
        sync_state: :local_only
      })
      |> Ash.create!()

      assert [%{title: "Book club"}] = Query.run("barbican").calendar
    end

    test "a book is findable by its ISBN and by what you wrote in it" do
      book =
        Ash.create!(Kati.Books.Book, %{
          title: "The Estuary Notebook",
          author: "R. Karvel",
          isbn: "9781234567897",
          status: :reading
        })

      Ash.create!(Kati.Books.Note, %{
        book_id: book.id,
        body: "The chapter on marram grass is the whole book.",
        kind: :quote
      })

      assert [%{title: "The Estuary Notebook"}] = Query.run("9781234567897").books
      assert [%{title: "The Estuary Notebook"}] = Query.run("marram").books
    end
  end

  describe "a recent query reopened from screen 86" do
    test "comes back exactly as it was typed" do
      # MOVIES-AND-TV.md #130. `query_tag/2` replaced spaces with underscores
      # to make an atom a device test can type, and `open/2` undid it by
      # replacing underscores with spaces — which is not the inverse of
      # anything. `sci_fi` is stored as typed (`Kati.Search.Recent.remember/1`
      # "never translates — they are your words"), tagged `:repeat_query_sci_fi`
      # and came back as `sci fi`: a different search, silently.
      assert Kati.Screens.SearchIdle.resolve("sci_fi", ["sci_fi"]) == "sci_fi"
      assert Kati.Screens.SearchIdle.resolve("two__spaces", ["two  spaces"]) == "two  spaces"

      # And the ordinary case still works, both ways round.
      assert Kati.Screens.SearchIdle.resolve("the_long_hollow", ["the long hollow"]) ==
               "the long hollow"
    end

    test "and a row that has since gone still opens something readable" do
      assert Kati.Screens.SearchIdle.resolve("gone_away", []) == "gone away"
    end

    test "the tap carries the line the shelf actually holds" do
      Kati.Search.Recent.forget!()
      Kati.Search.Recent.remember("sci_fi")

      socket =
        Kati.Screens.SearchIdle
        |> Mob.Socket.new()
        |> Mob.Socket.assign(:scope, "All")
        |> Mob.Socket.assign(:query, "")
        |> Mob.Socket.assign(:history, Kati.Search.Recent.all())

      {:noreply, opened} =
        Kati.Screens.SearchIdle.handle_info({:tap, :repeat_query_sci_fi}, socket)

      assert {:push, Kati.Screens.Search, %{query: "sci_fi"}} =
               Map.get(opened.__mob__, :nav_action)
    end
  end

  describe "screen 88's back pill" do
    test "names the page it actually returns to" do
      # MOVIES-AND-TV.md #131: the board draws `Settings` and the tune disc on
      # 86 is its only door, so the pill named a screen the pop does not land
      # on.
      socket =
        Kati.Screens.SearchIdle
        |> Mob.Socket.new()
        |> Mob.Socket.assign(:scope, "All")
        |> Mob.Socket.assign(:query, "")
        |> Mob.Socket.assign(:history, [])

      {:noreply, pushed} = Kati.Screens.SearchIdle.handle_info({:tap, :filters}, socket)

      assert {:push, Kati.Screens.SearchSpec, %{back: "Search"}} =
               Map.get(pushed.__mob__, :nav_action)

      assert Kati.Screens.Pushed.back_label(%{back: "Search"}, "Settings") == "Search"
    end
  end

  describe "the history the field keeps" do
    setup do
      Kati.Search.Recent.forget!()
      :ok
    end

    test "a fresh install has none, which is a state and not a placeholder" do
      # `Kati.Search.Sample.recent/0` used to answer `dentist`, `leaving soon`,
      # `ines karvel`, `4 stars` and `miso salmon` on every device — five words
      # nobody had typed, presented as their own search history. That is the
      # defect #91 reports about the shelves, one screen further in.
      assert Kati.Search.Recent.all() == []
    end

    test "a query that ran is remembered, newest first" do
      Kati.Search.Recent.remember("hollow")
      Kati.Search.Recent.remember("estuary")

      assert Kati.Search.Recent.all() == ["estuary", "hollow"]
    end

    test "searching the same thing twice moves it to the front rather than doubling it" do
      Kati.Search.Recent.remember("hollow")
      Kati.Search.Recent.remember("estuary")
      Kati.Search.Recent.remember("hollow")

      assert Kati.Search.Recent.all() == ["hollow", "estuary"]
    end

    test "the keystrokes on the way to a word are not five searches" do
      # Screen 19 records on every keystroke and says why: the results arrive
      # while you type, so there is no submit to record on. On a device that
      # left `Ash`, `Ashf`, `Ashfa`, `Ashfal` and `Ashfall` in a list that
      # keeps eight — one search holding five of the eight slots and pushing
      # out everything typed before it.
      Kati.Search.Recent.remember("estuary")

      for typed <- ["Ash", "Ashf", "Ashfa", "Ashfal", "Ashfall"] do
        Kati.Search.Recent.remember(typed)
      end

      assert Kati.Search.Recent.all() == ["Ashfall", "estuary"]
    end

    test "a shorter search after a longer one is its own search" do
      # The rule is one-way on purpose. `Ash` typed after `Ashfall` has been
      # searched is a person looking for something else, not the abandoned
      # start of the word they already found.
      Kati.Search.Recent.remember("Ashfall")
      Kati.Search.Recent.remember("Ash")

      assert Kati.Search.Recent.all() == ["Ash", "Ashfall"]
    end

    test "case is not a second search" do
      Kati.Search.Recent.remember("ash")
      Kati.Search.Recent.remember("Ashfall")

      assert Kati.Search.Recent.all() == ["Ashfall"]
    end

    test "a query too short to run is not remembered" do
      # The shelf would otherwise fill with the first letter of everything ever
      # typed. `Kati.Search.long_enough?/1` is what says a query ran at all.
      Kati.Search.Recent.remember("h")

      assert Kati.Search.Recent.all() == []
    end

    test "it keeps the number screen 88 specifies and no more" do
      for i <- 1..12, do: Kati.Search.Recent.remember("query#{i}")

      assert length(Kati.Search.Recent.all()) == Kati.Search.recent_kept()
      assert hd(Kati.Search.Recent.all()) == "query12"
    end

    test "nothing is folded, because they are your words" do
      # Screen 88's own row: *never translated, they are your words*. So the
      # normalisation that ranks a query does not touch the one that is stored.
      Kati.Search.Recent.remember("Café")

      assert Kati.Search.Recent.all() == ["Café"]
    end
  end

  describe "the results page draws what the query actually returned" do
    setup do
      Kati.Search.Recent.forget!()
      :ok
    end

    test "a query that matches a title and nothing else renders" do
      # Board 19 is drawn with a hit in all three groups, so the screen drew
      # all three unconditionally and `note_lines/1` raised `BadMapError` on the
      # nil note the moment a real query matched a title and nothing else.
      #
      # Which is the FIRST query anybody runs: a title added by hand has no note
      # about it yet. The whole page went down, so it never stamped its name, so
      # the device test timed out waiting for a screen rather than failing on a
      # missing row — a render crash reads exactly like a navigation that never
      # happened, and that is what made it expensive to find.
      Kati.Screens.AddByHand.save(%Mob.Socket{
        Mob.Socket.new(Kati.Screens.AddByHand)
        | assigns: %{
            title: "Estuary Nights",
            kind: :movie,
            status: "Not started",
            save_error: nil
          }
      })

      results = Kati.Search.Query.run("estuary")

      assert results.notes == [], "the fixture no longer sets up the case this test is about"
      assert %{type: :box} = render(results, "All")
    end

    test "every scope renders against a result set that only has titles" do
      # One assertion per chip, because the crash was in the group the filter
      # chose and any one of them could grow the same hole.
      Kati.Screens.AddByHand.save(%Mob.Socket{
        Mob.Socket.new(Kati.Screens.AddByHand)
        | assigns: %{
            title: "Estuary Nights",
            kind: :movie,
            status: "Not started",
            save_error: nil
          }
      })

      results = Kati.Search.Query.run("estuary")

      for scope <- ["All", "Screen", "Calendar", "Notes"] do
        assert %{type: :box} = render(results, scope),
               "screen 19 could not render with the #{scope} chip on"
      end
    end

    test "narrowing to a scope with nothing in it says so rather than drawing a blank" do
      # An empty page under a query reads as a search that broke. Omitting the
      # empty group is screen 96's rule; saying nothing at all when every group
      # is omitted is not.
      Kati.Screens.AddByHand.save(%Mob.Socket{
        Mob.Socket.new(Kati.Screens.AddByHand)
        | assigns: %{
            title: "Estuary Nights",
            kind: :movie,
            status: "Not started",
            save_error: nil
          }
      })

      results = Kati.Search.Query.run("estuary")
      drawn = rendered_text(render(results, "Notes"))

      # MOVIES-AND-TV.md #117: and what it says is WHERE the answer is, not
      # that there is none. `Nothing here for estuary` over a query that found
      # a film is the misreading board 89's third band was drawn to prevent —
      # this used to assert exactly that sentence.
      assert Enum.any?(drawn, &String.contains?(&1, "Nothing in Notes.")),
             "the Notes chip with no notes drew neither results nor a state: " <> inspect(drawn)

      assert Enum.any?(drawn, &String.contains?(&1, "in Screen")),
             "the cross-scope row did not name the scope holding the hits: " <> inspect(drawn)

      refute Enum.any?(drawn, &String.contains?(&1, "Nothing here for")),
             "a scope with no hits still claimed the query matched nothing: " <> inspect(drawn)
    end

    test "and still says nothing matched when nothing did" do
      results = Kati.Search.Query.run("zzzznothingatall")
      drawn = rendered_text(render(results, "All"))

      assert Enum.any?(drawn, &String.contains?(&1, "Nothing here for")),
             "a query that found nothing anywhere lost its no-match card: " <> inspect(drawn)

      refute Enum.any?(drawn, &String.contains?(&1, "Nothing in")),
             "the cross-scope row was drawn with nowhere to point: " <> inspect(drawn)
    end

    test "and the cross-scope row is the chip it names" do
      Kati.Screens.AddByHand.save(%Mob.Socket{
        Mob.Socket.new(Kati.Screens.AddByHand)
        | assigns: %{
            title: "Estuary Nights",
            kind: :movie,
            status: "Not started",
            save_error: nil
          }
      })

      results = Kati.Search.Query.run("estuary")

      assert {"Screen", 2} = Kati.Screens.Search.elsewhere(results, "Notes")

      # Pressing the row and pressing the chip are one action, so the tag is
      # the chip's own.
      assert inspect(Kati.Screens.Search.cross_scope("Notes", {"Screen", 2}), limit: :infinity) =~
               "go_Screen"
    end

    test "and pressing it moves the lit scope" do
      # `Kati.ScreenTapSweepTest` renders against an empty store and so cannot
      # see a control that only exists over data. This presses it over rows.
      results = Kati.Search.Query.run("hollow")

      socket =
        Kati.Screens.Search
        |> Mob.Socket.new()
        |> Mob.Socket.assign(:query, "hollow")
        |> Mob.Socket.assign(:results, results)
        |> Mob.Socket.assign(:filter, "Notes")
        |> Mob.Socket.assign(:recent, nil)
        |> Mob.Socket.assign(:history, [])
        |> Mob.Socket.assign(:back, "Home")

      {:noreply, moved} = Kati.Screens.Search.handle_info({:tap, :go_Screen}, socket)

      assert moved.assigns.filter == "Screen"
    end

    test "and the row's tag is not one another node already carries" do
      # Two nodes may not share an `accessibility_id` — `onNodeWithTag` throws
      # on the second match. The row drew the chip's own `filter_Screen` first,
      # and `ui.sh ids` on the Pixel_9a listed it twice.
      results = Kati.Search.Query.run("hollow")
      drawn = inspect(render(results, "Notes"), limit: :infinity)

      tags = Regex.scan(~r/:filter_Screen\b/, drawn)

      assert length(tags) == 1,
             "filter_Screen is drawn #{length(tags)} times on one frame"
    end
  end

  # A shelf row for one of the three cached titles the setup makes, so a watch
  # has something to hang off.
  defp track!(source_id, touched \\ nil) do
    Ash.create!(Kati.Media.TrackedTitle, %{
      source: :tmdb,
      source_id: source_id,
      kind: :tv,
      status: :watching,
      last_touched_at: touched
    })
  end

  # One cached episode of a cached title, which is what TMDB writes when a
  # series is added and what nothing could find until #144.
  defp episode!(title_source_id, title, attrs \\ %{}) do
    Ash.create!(
      Kati.Media.CachedEpisode,
      Map.merge(
        %{
          source: :tmdb,
          source_id: "ep-#{System.unique_integer([:positive])}",
          title_source_id: title_source_id,
          title: title,
          season_number: 2,
          episode_number: 5,
          fetched_at: Kati.Time.now()
        },
        attrs
      )
    )
  end

  defp render(results, filter) do
    Kati.Screens.Search.render(%{
      results: results,
      filter: filter,
      recent: nil,
      query: results.query,
      history: []
    })
  end

  defp rendered_text(tree) do
    tree
    |> Mob.ScreenCase.flatten()
    |> Enum.flat_map(fn node ->
      case Map.get(node, :props) || %{} do
        %{text: text} when is_binary(text) -> [text]
        _other -> []
      end
    end)
  end
end
