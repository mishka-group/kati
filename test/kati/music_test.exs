defmodule Kati.MusicTest do
  @moduledoc """
  The Music domain, and the three screens standing on it.

  ## The two figures the drawings pin

  Screen 73 says `11 tracks · 47 minutes` and screen 74 says `41 plays`. Both
  are arithmetic over `Kati.Music.Sample.tracks/0`, and both are asserted here
  rather than trusted to a comment — the sample is the fixture every capture is
  compared against, so a drifted duration is a drifted frame on two screens at
  once.

  ## Why every row is prefixed and deleted

  Same hazard `Kati.BooksTest` and `Kati.MediaMoodTest` record: screens 73, 74
  and 77 fall back to their drawings only while the tables are empty, and
  `Kati.ScreenDesignLiteralTest` renders all three against this same shared
  database. One album left behind makes three screens take the real path and
  the failure lands somewhere else.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Music.Album
  alias Kati.Music.Artist
  alias Kati.Music.Listen
  alias Kati.Music.Sample
  alias Kati.Music.Track
  alias Kati.Screens.AlbumDetail
  alias Kati.Screens.ArtistDetail
  alias Kati.Screens.LogListen
  alias Kati.Screens.Music

  # The pure functions screen 21's shelf is arithmetic in. Nothing here touches
  # the store, and each was documented with an example before it was run as one
  # — which is the whole difference between a doc and a doctest.
  doctest Kati.Screens.Music,
    only: [
      album_tag: 1,
      artist_tag: 1,
      clock: 1,
      oclock: 1,
      plays_label: 1,
      subtitle: 2,
      window: 1
    ]

  doctest Kati.Screens.ArtistDetail, only: [unheard_line: 0]

  @prefix "music-test-"

  setup do
    on_exit(&delete_rows!/0)
    :ok
  end

  defp delete_rows! do
    for table <- ~w(music_tracks music_listens) do
      Kati.Repo.query!(
        "DELETE FROM #{table} WHERE album_id IN " <>
          "(SELECT id FROM music_albums WHERE title LIKE ?1)",
        [@prefix <> "%"]
      )
    end

    Kati.Repo.query!("DELETE FROM music_albums WHERE title LIKE ?1", [@prefix <> "%"])
    Kati.Repo.query!("DELETE FROM music_artists WHERE name LIKE ?1", [@prefix <> "%"])
  end

  defp listens_of(album) do
    Listen |> Ash.Query.for_read(:for_album, %{album_id: album.id}) |> Ash.read!()
  end

  defp an_artist!(attrs \\ %{}) do
    Ash.create!(
      Artist,
      Map.merge(
        %{
          name: @prefix <> "Kell Ostrand",
          role: "Composer",
          country: "Iceland",
          following: true,
          first_heard_on: ~D[2024-03-03]
        },
        attrs
      )
    )
  end

  defp an_album!(artist, attrs \\ %{}) do
    Ash.create!(
      Album,
      Map.merge(
        %{
          title: @prefix <> "Tidal Works",
          artist_id: artist.id,
          released_year: 2025,
          rating: 9,
          first_heard_on: ~D[2024-03-03],
          last_played_on: Date.add(Kati.Time.today(), -1)
        },
        attrs
      )
    )
  end

  defp tracks!(album, specs) do
    for {position, title, seconds, plays} <- specs do
      Ash.create!(Track, %{
        album_id: album.id,
        position: position,
        title: title,
        seconds: seconds,
        plays: plays
      })
    end
  end

  describe "the sample the drawings were captured from" do
    test "eleven tracks running forty-seven minutes" do
      tracks = Sample.tracks()

      assert length(tracks) == 11

      seconds =
        Enum.sum(
          Enum.map(tracks, fn %{duration: d} ->
            [m, s] = String.split(d, ":")
            String.to_integer(m) * 60 + String.to_integer(s)
          end)
        )

      assert div(seconds, 60) == 47, "screen 73 prints `47 minutes`"
    end

    test "the play counts total the forty-one screen 74 prints" do
      assert Enum.sum(Enum.map(Sample.tracks(), & &1.plays)) == 41
    end

    test "a track with no plays cannot be counted this month" do
      # The one place `plays` and `counted?` constrain each other: you cannot
      # have played something this month and never at all.
      for %{plays: plays, counted?: counted?} <- Sample.tracks() do
        assert not (counted? and plays == 0)
      end
    end
  end

  describe "an album's own arithmetic" do
    test "the initial is the title's, and never blank" do
      assert Album.initial(%Album{title: "Tidal Works"}) == "T"
      assert Album.initial(%Album{title: "  low country"}) == "L"
      # A title that begins with something uncased still gets a square with
      # something in it — a blank one reads as a failure rather than a choice.
      assert Album.initial(%Album{title: "1999"}) == "1"
      assert Album.initial(%Album{title: "   "}) == "?"
    end

    test "the byline drops the half that is missing" do
      artist = %Artist{name: "Kell Ostrand"}

      assert Album.byline(%Album{released_year: 2025}, artist) == "Kell Ostrand · 2025"
      assert Album.byline(%Album{released_year: nil}, artist) == "Kell Ostrand"
      assert Album.byline(%Album{released_year: 2025}, nil) == "2025"
      assert Album.byline(%Album{released_year: nil}, nil) == nil
    end

    test "plays are summed from the tracklist and never stored twice" do
      assert Album.plays([%Track{plays: 9}, %Track{plays: 7}, %Track{plays: 0}]) == 16
      assert Album.plays([]) == 0
    end
  end

  describe "a track's own arithmetic" do
    test "durations are written the way a running time is written" do
      assert Track.duration(%Track{seconds: 252}) == "4:12"
      assert Track.duration(%Track{seconds: 68}) == "1:08"
      # An hour-long track rolls into minutes rather than growing an hours
      # field, so the column stays two parts wide and keeps aligning.
      assert Track.duration(%Track{seconds: 4350}) == "72:30"
      assert Track.duration(%Track{seconds: nil}) == nil
    end

    test "the dot is today and nothing else" do
      today = ~D[2026-08-16]

      assert Track.played_today?(%Track{last_played_on: today}, today)
      refute Track.played_today?(%Track{last_played_on: Date.add(today, -1)}, today)
      refute Track.played_today?(%Track{last_played_on: nil}, today)
    end
  end

  describe "listens" do
    test "this month is a calendar month, not a rolling thirty days" do
      today = ~D[2026-08-16]

      listens = [
        %Listen{listened_on: ~D[2026-08-01]},
        %Listen{listened_on: ~D[2026-08-16]},
        # Twenty days ago, and in the previous month, so it does not count —
        # which is the whole difference between the two definitions.
        %Listen{listened_on: ~D[2026-07-27]}
      ]

      assert Listen.this_month(listens, today) == 2

      # And the count is the length of the list screen 21's card totals the
      # minutes of, so the two screens cannot disagree about the boundary.
      assert Enum.map(Listen.in_month(listens, today), & &1.listened_on) ==
               [~D[2026-08-01], ~D[2026-08-16]]
    end

    test "untimed sittings are skipped rather than counted as zero" do
      assert Listen.total_minutes([%Listen{minutes: 41}, %Listen{minutes: nil}]) == 41
    end

    test "hours are whole" do
      assert Listen.hours_label(3660) == "61h"
      assert Listen.hours_label(0) == "0h"
    end
  end

  describe "screen 74 with a shelf" do
    setup do
      artist = an_artist!()
      album = an_album!(artist)

      tracks!(album, [
        {1, "Low Water", 252, 9},
        {2, "The Cull", 228, 7},
        {3, "Blackthorn", 302, 0}
      ])

      %{artist: artist, album: album}
    end

    test "every band reads the row rather than the drawing", %{album: album} do
      Ash.create!(Listen, %{
        album_id: album.id,
        listened_on: Kati.Time.today(),
        tracks: 11,
        minutes: 47
      })

      shown = AlbumDetail.album()

      assert shown.title == @prefix <> "Tidal Works"
      assert shown.byline == "#{@prefix}Kell Ostrand · 2025"
      assert shown.rating_label == "4.5"
      assert shown.first_heard == "3 Mar 2024"
      assert shown.last_played == "yesterday"
      # 9 + 7 + 0 from the tracklist, one listen this month.
      assert shown.plays_line == "16 plays · 1 this month"
    end

    test "the tracklist eyebrow carries the real count, not the drawing's eleven" do
      assert AlbumDetail.tracklist_label() == "Tracklist · 3 tracks"
    end

    test "the art square carries the album's initial when there is no artwork" do
      # The drawn default, not an error path — see the screen's moduledoc.
      assert AlbumDetail.album().art_seed == nil
      assert find(tree(mount_screen(AlbumDetail)), :text, text: "Art") != nil
    end

    test "last played says today, yesterday, then a date", %{album: album} do
      today = Kati.Time.today()

      for {on, expected} <- [
            {today, "today"},
            {Date.add(today, -1), "yesterday"},
            {~D[2024-03-03], "3 Mar 2024"}
          ] do
        updated = Ash.update!(Ash.get!(Album, album.id), %{last_played_on: on})

        assert AlbumDetail.shaped(updated, nil, [], []).last_played == expected
      end
    end

    test "the page renders the row's copy in the tree" do
      tree = tree(mount_screen(AlbumDetail))

      assert find(tree, :text, text: @prefix <> "Tidal Works") != nil
      assert find(tree, :text, text: "Low Water") != nil
      assert find(tree, :text, text: "4:12") != nil
    end
  end

  describe "screen 77" do
    setup do
      artist = an_artist!()
      first = an_album!(artist)
      second = an_album!(artist, %{title: @prefix <> "Low Country", released_year: 2023})
      unheard = an_album!(artist, %{title: @prefix <> "Estuary Tapes", released_year: nil})

      tracks!(first, [{1, "Low Water", 252, 9}])
      tracks!(second, [{1, "Ferry Road", 240, 4}])

      %{artist: artist, unheard: unheard}
    end

    test "the album lines say Unheard rather than nought plays" do
      lines = Map.new(ArtistDetail.albums(), &{&1.title, &1.line})

      assert lines[@prefix <> "Tidal Works"] == "2025 · 9 plays"
      assert lines[@prefix <> "Low Country"] == "2023 · 4 plays"
      # Not `0 plays`: the count is not the point, never having heard it is —
      # and it is the fact the unheard card acts on.
      assert lines[@prefix <> "Estuary Tapes"] == "Unheard"
    end

    test "Following writes to the artist on screen, not to whoever heads the shelf" do
      # The wrong-record write, one domain over from screen 66's. Screen 79
      # draws a real artist when one is shelved, and its map used to carry no
      # `:id` — so `ArtistDetail.target/1` had nothing to pin to and the write
      # fell through to re-reading the shelf AT TAP TIME. Follow somebody, and
      # whoever led the shelf when your finger landed got followed instead.
      x = an_artist!(%{name: @prefix <> "On Screen"})
      y = an_artist!(%{name: @prefix <> "Somebody Else"})
      first = an_album!(x, %{title: @prefix <> "Theirs"})
      an_album!(y, %{title: @prefix <> "Not Theirs"})

      Ash.update!(first, %{last_played_on: Kati.Time.today()})

      {:ok, socket} =
        Kati.Screens.ArtistDetailFa.mount(%{}, %{}, Mob.Socket.new(Kati.Screens.ArtistDetailFa))

      assert socket.assigns.artist.name == x.name, "the fixture no longer sets this up"
      assert socket.assigns.artist.id == x.id, "the page must be able to name who it drew"

      was_x = Ash.get!(Artist, x.id).following
      was_y = Ash.get!(Artist, y.id).following

      {:noreply, _moved} =
        Kati.Screens.ArtistDetailFa.handle_info({:tap, :toggle_following}, socket)

      # The flip, not a fixed value: what matters is WHICH row moved.
      assert Ash.get!(Artist, x.id).following == not was_x,
             "the artist on screen did not move"

      assert Ash.get!(Artist, y.id).following == was_y,
             "somebody the reader never saw was followed instead"
    end

    test "a page drawing the fixture follows nobody, and still moves its switch" do
      # The other half. A page drawing `Kati.Music.SampleFa` has no artist to
      # name, so the write is a refusal rather than a guess — and the switch
      # still moves, because a control that looked broken on a device with
      # nothing shelved would be the least explicable thing on it.
      #
      # The fixture state is CONSTRUCTED rather than assumed: this block's setup
      # shelves artists, so a bare mount resolves a real one. Overwriting the
      # assign is the same thing the screen does when it has nothing to resolve.
      shelved = an_artist!(%{name: @prefix <> "Untouched"})
      an_album!(shelved, %{title: @prefix <> "Untouched Record"})
      was = Ash.get!(Artist, shelved.id).following

      {:ok, mounted} =
        Kati.Screens.ArtistDetailFa.mount(%{}, %{}, Mob.Socket.new(Kati.Screens.ArtistDetailFa))

      drawn = Map.delete(mounted.assigns.artist, :id)
      socket = Mob.Socket.assign(mounted, :artist, drawn)

      refute ArtistDetail.target(socket.assigns), "the fixture case needs no id to pin to"

      {:noreply, moved} =
        Kati.Screens.ArtistDetailFa.handle_info({:tap, :toggle_following}, socket)

      assert moved.assigns.artist.following == not drawn.following, "the switch did not move"

      assert Ash.get!(Artist, shelved.id).following == was,
             "a page with nobody to name still wrote to a real artist"
    end

    test "the unheard card names the album with no plays", %{unheard: unheard} do
      assert ArtistDetail.unheard_release().title == unheard.title
    end

    test "the rail and the chart cap at four, and the chart says how many it dropped" do
      artist = an_artist!(%{name: @prefix <> "Prolific"})

      for n <- 1..6 do
        an_album!(artist, %{title: "#{@prefix}Record #{n}", released_year: 2000 + n})
      end

      # `stored/0` follows the shelf's first album, so the cap is asserted
      # through whichever artist that is — six new albums makes it this one.
      assert length(ArtistDetail.albums()) == 4
      assert ArtistDetail.truncated() == 2
      assert find(tree(mount_screen(ArtistDetail)), :text, text: "and 2 more") != nil
    end

    test "nothing is truncated when nothing was dropped" do
      assert ArtistDetail.truncated() == 0
      assert ArtistDetail.truncation() == []
    end

    test "following writes through, and the switch still moves with nothing stored", %{
      artist: artist
    } do
      view = mount_screen(ArtistDetail)
      assert assigns(view).artist.following == true

      toggled = render_info(view, {:tap, :toggle_following})

      assert assigns(toggled).artist.following == false
      assert Ash.get!(Artist, artist.id).following == false
    end

    test "dismiss takes the card off this render and writes nothing" do
      view = mount_screen(ArtistDetail)
      assert find(tree(view), :text, text: @prefix <> "Estuary Tapes") != nil

      dismissed = render_info(view, {:tap, :dismiss_release})

      assert assigns(dismissed).dismissed? == true
      assert ArtistDetail.unheard(true) == []
      # Still unheard, because dismissing is not hearing.
      assert ArtistDetail.unheard_release() != nil
    end
  end

  describe "screen 73, the write path" do
    setup do
      artist = an_artist!()
      album = an_album!(artist)

      tracks!(album, [
        {1, "Low Water", 252, 9},
        {2, "The Cull", 228, 7},
        {3, "Blackthorn", 302, 0}
      ])

      %{album: album}
    end

    test "the sheet opens on Selected tracks with the month's tracks ticked", %{album: album} do
      today = Kati.Time.today()

      [first | _rest] =
        Track |> Ash.Query.for_read(:for_album, %{album_id: album.id}) |> Ash.read!()

      Ash.update!(first, %{last_played_on: today})

      view = mount_screen(LogListen)

      assert assigns(view).scope == :scope_selected
      assert assigns(view).ticked == MapSet.new([first.position])
      assert find(tree(view), :text, text: "Ticked rows are already counted this month") != nil
    end

    test "the confirmation reports the sitting, not the ticks" do
      # 252 + 228 + 302 = 782s = 13 minutes, three tracks — and it stays that
      # whatever is ticked. See `Kati.Screens.LogListen.chosen_count/1` for why.
      view = mount_screen(LogListen)

      assert LogListen.chosen_count(assigns(view)) == 3
      assert LogListen.chosen_minutes(assigns(view)) == 13

      toggled = render_info(view, {:tap, :track_1})

      assert LogListen.chosen_count(assigns(toggled)) == 3
    end

    test "saving writes the listen, credits the ticked tracks, and moves last played", %{
      album: album
    } do
      view = mount_screen(LogListen)
      # Nothing is ticked to start — no track has been played this month — so
      # tick two of the three and leave the third alone.
      ticked = view |> render_info({:tap, :track_1}) |> render_info({:tap, :track_2})

      render_info(ticked, {:tap, :save})

      assert [listen] = listens_of(album)
      assert listen.tracks == 3
      assert listen.minutes == 13
      assert listen.scope == :selected
      assert listen.listened_on == Kati.Time.today()

      plays =
        Track
        |> Ash.Query.for_read(:for_album, %{album_id: album.id})
        |> Ash.read!()
        |> Map.new(&{&1.position, &1.plays})

      assert plays == %{1 => 10, 2 => 8, 3 => 0}
      assert Ash.get!(Album, album.id).last_played_on == Kati.Time.today()
    end

    test "the whole album credits every track", %{album: album} do
      view = mount_screen(LogListen)
      whole = render_info(view, {:tap, :scope_album})

      assert assigns(whole).scope == :scope_album
      # The tracklist is not drawn under this scope — there is nothing to
      # choose, and a list of ticks nobody needs to touch makes the common case
      # look like work.
      assert find(tree(whole), :text, text: "Low Water") == nil

      render_info(whole, {:tap, :save})

      plays =
        Track
        |> Ash.Query.for_read(:for_album, %{album_id: album.id})
        |> Ash.read!()
        |> Map.new(&{&1.position, &1.plays})

      assert plays == %{1 => 10, 2 => 8, 3 => 1}
    end

    test "minutes credits nothing, because nothing names a track", %{album: album} do
      view = mount_screen(LogListen)
      minutes = render_info(view, {:tap, :scope_minutes})

      render_info(minutes, {:tap, :save})

      assert [listen] = listens_of(album)
      assert listen.scope == :minutes

      plays =
        Track
        |> Ash.Query.for_read(:for_album, %{album_id: album.id})
        |> Ash.read!()
        |> Map.new(&{&1.position, &1.plays})

      assert plays == %{1 => 9, 2 => 7, 3 => 0}
    end

    test "closing writes nothing", %{album: album} do
      closed =
        mount_screen(LogListen) |> render_info({:tap, :track_1}) |> render_info({:tap, :close})

      assert navigated_to(closed) == {:pop}
      assert listens_of(album) == []
    end

    test "the ordinal gets the teens right" do
      # 11, 12 and 13 end in 1, 2 and 3 and take `th` anyway, which is the case
      # every naive implementation gets wrong.
      assert Enum.map([1, 2, 3, 4, 11, 12, 13, 21, 22, 101, 111], &LogListen.ordinal/1) ==
               ~w(1st 2nd 3rd 4th 11th 12th 13th 21st 22nd 101st 111th)
    end

    test "the whole sheet renders a tree the native layer can draw" do
      assert_renderable(mount_screen(LogListen))
    end
  end

  describe "screen 21 with a shelf" do
    test "one album on the shelf is one tile, and the drawing's three are gone" do
      artist = an_artist!()
      album = an_album!(artist, %{title: @prefix <> "Estuary Nights"})
      tracks!(album, [{1, "Low Water", 252, 9}, {2, "The Cull", 228, 3}])

      page = Music.page()

      assert [%{title: @prefix <> "Estuary Nights", plays: "12 PLAYS"}] = page.albums

      # Not merely "the band is short": the fixture's own records must be off
      # the screen entirely. A rail drawing the user's album AND the drawing's
      # three would satisfy every count above.
      drawn = MapSet.new(Music.drawn_page().albums, & &1.title)
      assert Enum.all?(page.albums, &(not MapSet.member?(drawn, &1.title)))

      # And the header counts the shelf it is over. `418` is the drawing's
      # window onto a library of 418 and stops being a defence the moment there
      # is a real shelf to count.
      assert page.subtitle == "1 albums · 0h this year"
      refute page.subtitle == Kati.Music.Sample.subtitle()
    end

    test "the tile's count is the number screen 74 prints under the same record" do
      # One rule, and the reason it is one: the tile says `41 PLAYS` over a
      # cover that is one tap from a page saying `41 plays` under it. Both go
      # through `Kati.Screens.AlbumDetail.play_count/1`, so the shelf and the
      # detail cannot answer a reader differently inside one journey.
      artist = an_artist!()
      album = an_album!(artist, %{title: @prefix <> "Tidal Works"})
      tracks!(album, [{1, "Low Water", 252, 9}, {2, "The Cull", 228, 7}])

      [tile] = Music.page().albums

      assert tile.plays == "16 PLAYS"
      assert AlbumDetail.album(album.id).plays_line == "16 plays · 0 this month"
      assert Map.new(ArtistDetail.albums(artist.id), &{&1.title, &1.plays})[album.title] == 16
    end

    test "the tiles are the records played this week, then the shelf's own order" do
      artist = an_artist!()
      old = an_album!(artist, %{title: @prefix <> "Nine Rooms"})
      # Written second, so it heads `:shelf` on `updated_at` — and it has not
      # been played this week, so the eyebrow's own word puts the other first.
      an_album!(artist, %{title: @prefix <> "Low Country"})

      Ash.create!(Listen, %{album_id: old.id, listened_on: Kati.Time.today(), tracks: 11})

      assert [%{title: @prefix <> "Nine Rooms"}, %{title: @prefix <> "Low Country"}] =
               Music.page().albums
    end

    test "the listening card totals the sittings rather than the drawing's 9h 12m" do
      artist = an_artist!()
      album = an_album!(artist)
      today = Kati.Time.today()

      Ash.create!(Listen, %{
        album_id: album.id,
        listened_on: today,
        tracks: 11,
        minutes: 47,
        started_at: DateTime.new!(today, ~T[21:30:00])
      })

      Ash.create!(Listen, %{
        album_id: album.id,
        listened_on: Date.add(today, -3),
        tracks: 4,
        minutes: 20,
        started_at: DateTime.new!(Date.add(today, -3), ~T[21:05:00])
      })

      card = Music.page().listening

      assert card.label == "This month"
      assert card.window == "mostly 21:00–23:00"
      assert length(card.bars) == 20

      # 67 minutes of listening, and the twentieth bar is today's — the tallest,
      # so it is the field's full height and above the run of ordinary days.
      assert card.total == "1h 7m"
      assert List.last(card.bars) == {40.0, Kati.Music.Sample.tone(3)}
      # A day with nothing draws nothing rather than a floor this file invented.
      assert Enum.count(card.bars, &(elem(&1, 0) == 0.0)) == 18
    end

    test "the release band is what screen 77 calls unheard, for everyone you follow" do
      followed = an_artist!(%{name: @prefix <> "Kell Ostrand", following: true})
      ignored = an_artist!(%{name: @prefix <> "Vesper Line", following: false})

      unheard = an_album!(followed, %{title: @prefix <> "Estuary Tapes"})
      heard = an_album!(followed, %{title: @prefix <> "Tidal Works"})
      tracks!(heard, [{1, "Low Water", 252, 9}])
      an_album!(ignored, %{title: @prefix <> "Low Country"})

      assert [row] = Music.page().releases
      assert row.id == unheard.id
      assert row.artist_id == followed.id
      assert row.artist == followed.name
      assert row.line == "#{@prefix}Estuary Tapes · you have not heard it"

      # And it is the same list screen 77's own card is drawn from, which is
      # what stops a record being new in the band and heard on the page it
      # opens.
      assert Enum.map(ArtistDetail.unheard_albums(followed), & &1.id) == [unheard.id]
      assert ArtistDetail.unheard_release(followed.id).title == unheard.title
    end

    test "a shelf row is named by its id and a drawn row by nothing" do
      artist = an_artist!()
      album = an_album!(artist, %{title: @prefix <> "Estuary Nights"})

      [row] = Music.page().albums

      assert row.id == album.id
      assert Music.album_tag(row) == String.to_atom("open_album_" <> album.id)
      assert AlbumDetail.params_for(row) == %{album_id: album.id}
      assert LogListen.params_for(row) == %{album_id: album.id}

      # The other half, and the one that has to keep working: a fixture row has
      # no id and must yield `%{}`, never `%{album_id: nil}`. A destination that
      # matched on the key would otherwise take a `nil` for an answer.
      for drawn <- Music.drawn_page().albums, do: assert(AlbumDetail.params_for(drawn) == %{})
      for drawn <- Music.drawn_page().releases, do: assert(ArtistDetail.params_for(drawn) == %{})
    end

    test "the page renders the row's copy and none of the drawing's" do
      artist = an_artist!()
      album = an_album!(artist, %{title: @prefix <> "Estuary Nights"})
      tracks!(album, [{1, "Low Water", 252, 9}])

      tree = tree(mount_screen(Music))

      assert find(tree, :text, text: @prefix <> "Estuary Nights") != nil
      assert find(tree, :text, text: "9 PLAYS") != nil
      assert find(tree, :text, text: "1 albums · 0h this year") != nil

      for drawn <- Music.drawn_page().albums do
        assert find(tree, :text, text: drawn.title) == nil,
               "the drawing's #{drawn.title} is still on a shelf that holds one real album"
      end

      assert find(tree, :text, text: Kati.Music.Sample.subtitle()) == nil
      assert find(tree, :text, text: Kati.Music.Sample.listening().total) == nil
    end

    test "a shelf with nothing played renders a tree the native layer can draw" do
      # The bars are the reason this is asserted on the REAL branch rather than
      # on the drawing: a day with no listening is `0.0` tall, which is a node
      # the drawing never produces — its own field has no zero in it.
      an_album!(an_artist!())

      assert Enum.all?(Music.page().listening.bars, &(elem(&1, 0) == 0.0))
      assert_renderable(mount_screen(Music))
    end

    test "a write on screen 77 acts on the artist it was NAMED, not on the shelf's" do
      # Screen 66's defect in this domain: `artist/1` collapses *nobody named an
      # artist* and *the named artist is gone* into the drawing, which has no
      # id, so a toggle recovering its subject from the drawn map would follow
      # whoever heads the shelf. `Following` is a statement about a shelf and an
      # alert type, so the wrong one is a real change to the app's behaviour.
      artist = an_artist!(%{name: @prefix <> "Kell Ostrand", following: true})
      an_album!(artist)

      gone = an_artist!(%{name: @prefix <> "Deleted", following: true})
      Ash.destroy!(gone)

      view = mount_screen(ArtistDetail, %{artist_id: gone.id})

      assert assigns(view).artist == ArtistDetail.drawn_artist(),
             "a named-but-gone artist is the drawing"

      toggled = render_info(view, {:tap, :toggle_following})

      assert assigns(toggled).artist.following == false,
             "the switch still moves, or the control looks broken on the one device where " <>
               "nothing else is wrong"

      assert Ash.get!(Artist, artist.id).following == true,
             "the write reached another artist while the page drew the drawing"
    end
  end

  describe "screen 21 with nothing shelved" do
    test "the drawing is what the screen reads, whole" do
      # The values `test/design/screens/21.html` was captured from, and the
      # branch `Kati.ScreenDesignLiteralTest` renders. Compared as the whole map
      # rather than as the tiles alone: a listening card that had stopped
      # falling back would pass a check on the three covers.
      assert Music.page() == Music.drawn_page()
      assert Music.drawn_page().albums == Sample.albums()
      assert Music.drawn_page().listening == Sample.listening()
      assert Music.drawn_page().releases == Sample.releases()
      assert Music.drawn_page().subtitle == Sample.subtitle()
    end

    test "the empty store's own arithmetic is still the honest answer" do
      # Not the drawing's: these are what `page/0` would have said had the
      # branch gone the other way, and they are the reason it does not.
      assert Music.subtitle([], []) == "0 albums · 0h this year"
      assert Music.listening([]).total == "0h 0m"
      assert Music.listening([]).window == ""
      assert Music.new_releases() == []
    end
  end

  describe "with nothing stored" do
    test "each screen falls back to its own drawing, whole" do
      assert AlbumDetail.album() == AlbumDetail.drawn_album()
      assert ArtistDetail.artist() == ArtistDetail.drawn_artist()
      assert LogListen.album() == AlbumDetail.drawn_album()
      assert Music.page() == Music.drawn_page()
    end

    test "the sheet still ticks the month's tracks" do
      # Four of the drawing's eleven, which is what makes its `info` line true.
      assert LogListen.counted_this_month() == MapSet.new([1, 2, 3, 4, 6, 7, 8, 9, 10])
    end
  end
end
