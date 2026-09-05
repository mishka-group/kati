defmodule Kati.MusicAddByHandTest do
  @moduledoc """
  `D-39` — the three screens that make the music domain reachable, and the four
  claims the brief asks a run to settle.

  Screens 178, 179 and 180 are the first writers `Kati.Music` has ever had.
  Before them `Kati.Music.Album`, `Artist`, `Track` and `Listen` were migrated,
  indexed and read by four screens with nothing anywhere creating one — so
  screen 21 was permanently on `Kati.Music.Sample`, screen 74's rating tile
  printed 4.5 stars nothing could set, and screen 73's **Save listen** answered
  `{:error, :nothing_to_save}` on every device that has ever existed.

  Four things are asked here, in the brief's own order:

    * **the form writes what was typed** — and the album, its artist and its
      track count all land, with the artist REUSED when the typed name is
      already somebody Kati knows;
    * **a refusal is refused and says why** — nothing is written, the sheet
      stays open with the draft intact, and the sentence names what is missing
      *and* says nothing was written, which is board 155's shape;
    * **the shelf shows the new row afterwards** — screen 21 stops drawing its
      fixture the moment there is one record, which is the whole point of the
      ticket;
    * **the empty state is the empty state** — with nothing shelved every one
      of the three screens draws the drawing, and 180's Save refuses rather
      than filing the fixture's rating onto somebody's shelf.

  ## Why every row is prefixed and deleted

  `Kati.MusicTest`'s hazard, and the reason is the same: screens 21, 73, 74 and
  77 fall back to their drawings only while the tables are empty, and
  `Kati.ScreenDesignLiteralTest` renders all four against this same shared
  database. One album left behind makes four screens take the real path and the
  failure lands in a file that never touched music.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Music.Album
  alias Kati.Music.Artist
  alias Kati.Music.Track
  alias Kati.Screens.AddByHandRecord
  alias Kati.Screens.AddTitle
  alias Kati.Screens.AddTitleMusic
  alias Kati.Screens.AlbumDetail
  alias Kati.Screens.Music
  alias Kati.Screens.RateAlbum

  doctest Kati.Screens.AddByHandRecord, only: [parse_date: 1]

  doctest Kati.Screens.RateAlbum,
    only: [five_point: 1, ten_point: 1, characters_label: 1]

  @prefix "d39-test-"

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

    # Screen 179's three rows are the BOARD's own titles and cannot be
    # prefixed: the sheet draws what board 179 draws, and a test that renamed
    # them would be testing something else. So the rows this file's add-disc
    # test creates are cleaned by name, tracks first — `music_tracks`
    # references `music_albums`, which references `music_artists`.
    for title <- ["Tidal Works", "Estuary Tapes", "Nine Rooms"] do
      Kati.Repo.query!(
        "DELETE FROM music_tracks WHERE album_id IN " <>
          "(SELECT id FROM music_albums WHERE title = ?1)",
        [title]
      )

      Kati.Repo.query!("DELETE FROM music_albums WHERE title = ?1", [title])
    end

    Kati.Repo.query!("DELETE FROM music_artists WHERE name = ?1", ["Kell Ostrand"])
  end

  # The form, driven the way a person drives it: one change per field, then the
  # one button. Never by calling `write/3` directly — the defect this whole
  # ticket is about is a screen whose control and whose write were introduced to
  # each other by nobody.
  defp typed(view, values) do
    Enum.reduce(values, view, fn {field, text}, acc ->
      render_info(acc, {:change, field, text})
    end)
  end

  defp albums, do: Album |> Ash.read!() |> Enum.filter(&String.starts_with?(&1.title, @prefix))

  defp artists, do: Artist |> Ash.read!() |> Enum.filter(&String.starts_with?(&1.name, @prefix))

  defp tracks_of(album),
    do: Track |> Ash.Query.for_read(:for_album, %{album_id: album.id}) |> Ash.read!()

  # ── the form writes what was typed ──────────────────────────────────────────

  describe "screen 178 writes an album" do
    test "every field the board draws lands on the row" do
      view =
        AddByHandRecord
        |> mount_screen()
        |> typed(
          title: @prefix <> "Tidal Works",
          artist: @prefix <> "Kell Ostrand",
          released: "2025",
          tracks: "3",
          first_heard: "3 Mar 2024"
        )
        |> render_info({:tap, :add})

      assert [album] = albums()
      assert album.title == @prefix <> "Tidal Works"
      assert album.released_year == 2025
      assert album.first_heard_on == ~D[2024-03-03]
      assert album.source == :manual

      # The artist the album points at is the artist that was typed, and it is a
      # row rather than a string: `Kati.Music.Album.belongs_to :artist` is
      # `allow_nil? true`, so an album-only path would accumulate records with
      # nobody behind them — which is why Artist is a Kind of its own.
      assert [artist] = artists()
      assert album.artist_id == artist.id
      assert artist.name == @prefix <> "Kell Ostrand"

      # Tracks is a count, and a count with nowhere to be stored is a count
      # that becomes rows: three positions, no timings. `Kati.Music.Track` says
      # why the timings are absent rather than invented — *a tracklist typed by
      # hand often has names and no timings*.
      assert Enum.map(tracks_of(album), & &1.position) == [1, 2, 3]
      assert Enum.all?(tracks_of(album), &(&1.seconds == nil))
      assert Enum.all?(tracks_of(album), &(&1.plays == 0))

      # A save that landed closes the sheet. A save that did not must not, and
      # that pair is what #85 is about.
      assert {:pop} = view.socket.__mob__.nav_action
    end

    test "a typed artist who already exists is reused, not filed twice" do
      existing = Ash.create!(Artist, %{name: @prefix <> "Kell Ostrand", role: "Composer"})

      AddByHandRecord
      |> mount_screen()
      |> typed(
        title: @prefix <> "Estuary Tapes",
        # Typed as a person types it, in the case they happen to use. Two rows
        # for one person would give screen 77 two pages and screen 21 two
        # follow switches for them.
        artist: @prefix <> "kell ostrand"
      )
      |> render_info({:tap, :add})

      assert [album] = albums()
      assert album.artist_id == existing.id
      assert length(artists()) == 1
      assert hd(artists()).role == "Composer"
    end

    test "an album with no artist typed is a real album with no artist" do
      AddByHandRecord
      |> mount_screen()
      |> typed(title: @prefix <> "Nine Rooms")
      |> render_info({:tap, :add})

      assert [album] = albums()
      assert album.artist_id == nil
      assert album.released_year == nil
      assert artists() == []
      assert tracks_of(album) == []
    end

    test "the Artist kind writes an artist, with the switch it was left on" do
      view =
        AddByHandRecord
        |> mount_screen()
        |> render_info({:tap, :kind_Artist})
        |> typed(title: @prefix <> "Aud Marne", role: "Composer", country: "Iceland")
        |> render_info({:tap, :toggle_following})

      assert assigns(view).following

      render_info(view, {:tap, :add})

      assert [artist] = artists()
      assert artist.name == @prefix <> "Aud Marne"
      assert artist.role == "Composer"
      assert artist.country == "Iceland"
      assert artist.following
      assert albums() == []
    end

    test "the Kind row's other three chips open the form that owns them" do
      # The Kind row reads as one control and reveals two forms — board 178's
      # own annotation. Film, Series and Book are `Kati.Media`'s write, not this
      # one, so their chips push the form that makes it rather than pretending
      # this one can file a film.
      for tag <- [:kind_Film, :kind_Series, :kind_Book] do
        view =
          AddByHandRecord
          |> mount_screen()
          |> render_info({:tap, tag})

        assert {:push, Kati.Screens.AddByHand, _params} = view.socket.__mob__.nav_action
      end

      assert albums() == []
      assert artists() == []
    end
  end

  # ── a refusal is refused and says why ───────────────────────────────────────

  describe "screen 178 refuses" do
    test "an album with no title writes nothing and says nothing was written" do
      view =
        AddByHandRecord
        |> mount_screen()
        |> typed(artist: @prefix <> "Kell Ostrand", released: "2025", tracks: "11")
        |> render_info({:tap, :add})

      assert albums() == []
      assert artists() == []

      # Board 155's shape: name what is missing, then say nothing was written.
      # A message that only says *a title is needed* leaves the reader
      # wondering what happened to the rest of the form.
      assert assigns(view).save_error =~ "album title"
      assert assigns(view).save_error =~ "Nothing was written"

      # The sheet stays open, and the draft with it — the recovery is to type a
      # title and press Add again, and that is only one tap if what was already
      # typed survived.
      refute match?({:pop}, view.socket.__mob__.nav_action)
      assert assigns(view).artist == @prefix <> "Kell Ostrand"
      assert assigns(view).released == "2025"
    end

    test "an artist with no name refuses in the noun the form is wearing" do
      view =
        AddByHandRecord
        |> mount_screen()
        |> render_info({:tap, :kind_Artist})
        |> render_info({:tap, :add})

      assert artists() == []
      assert assigns(view).save_error =~ "name"
      assert assigns(view).save_error =~ "Nothing was written"
    end

    test "a whitespace title is not a title" do
      view =
        AddByHandRecord
        |> mount_screen()
        |> typed(title: "   ")
        |> render_info({:tap, :add})

      assert albums() == []
      assert assigns(view).save_error != nil
    end
  end

  # ── the shelf shows the new row afterwards ──────────────────────────────────

  describe "screen 21 after the first hand-typed record" do
    test "the shelf stops drawing its fixture and draws the record" do
      assert Music.page() == Music.drawn_page(),
             "with nothing shelved the Music shelf must be its own drawing"

      AddByHandRecord
      |> mount_screen()
      |> typed(title: @prefix <> "Tidal Works", artist: @prefix <> "Kell Ostrand")
      |> render_info({:tap, :add})

      page = Music.page()

      refute page == Music.drawn_page()
      assert Enum.map(page.albums, & &1.title) == [@prefix <> "Tidal Works"]

      # And the tile can name what it drew, which is what makes it a door:
      # screen 21's tiles have carried ids since `b4b9a0d`, and this is the
      # first commit in which anything could put a row under one.
      assert [tile] = page.albums
      assert is_binary(tile.id)
      assert AlbumDetail.params_for(tile) == %{album_id: tile.id}
    end

    test "one album is still a third of the rail, not a square the height of the page" do
      # Found on a device, on the first shelf that had ever held exactly one
      # album. The tiles are weighted — `flex:1`, the export's own — so weights
      # divide whatever is in the Row, and one tile alone took all 369dp and
      # then squared it with `aspect_ratio={1.0}`. The drawing's three fill the
      # rail, so nothing on the host had ever drawn a short one.
      #
      # Counted as weighted columns rather than by rendering, because the
      # padding is what is being asserted and an empty column draws nothing:
      # a test that looked for covers would pass on the broken rail too.
      for count <- 1..3 do
        columns =
          count
          |> then(&Enum.take(Music.drawn_page().albums, &1))
          |> Music.tiles()
          |> Mob.ScreenCase.flatten()
          |> Enum.filter(&(&1.type == :column and Map.get(&1.props || %{}, :weight) == 1.0))

        assert length(columns) == 3,
               "a rail of #{count} album(s) drew #{length(columns)} weighted columns; " <>
                 "it must always be three, or the tiles resize with the shelf"
      end
    end
  end

  # ── screen 179, the sheet the FAB opens ─────────────────────────────────────

  describe "screen 179" do
    test "screen 21's FAB opens it, and the other roots' FAB does not" do
      # `Kati.Screens.Root` gives every shelf `add_sheet/0` and marks it
      # overridable; this shelf is the only one that overrides it. Asserted on
      # a second root as well, because an override that leaked into the macro
      # would open the music sheet from the Library's `+` too.
      assert Music.add_sheet() == AddTitleMusic
      assert Kati.Screens.Library.add_sheet() == AddTitle

      view = render_info(mount_screen(Music), {:tap, :fab})

      assert {:push, AddTitleMusic, _params} = view.socket.__mob__.nav_action
    end

    test "it opens with Albums lit and the board's three rows under it" do
      view = mount_screen(AddTitleMusic)

      assert assigns(view).filter == "Albums"
      assert length(AddTitleMusic.visible(assigns(view).results, "Albums")) == 3
    end

    test "the add disc shelves the row it drew, and only that row" do
      view =
        AddTitleMusic
        |> mount_screen()
        |> render_info({:tap, String.to_atom("add_Estuary Tapes")})

      assert [album] = Album |> Ash.read!() |> Enum.filter(&(&1.title == "Estuary Tapes"))
      assert album.released_year == 2026

      assert length(Track |> Ash.Query.for_read(:for_album, %{album_id: album.id}) |> Ash.read!()) ==
               8

      # The row the page drew is marked, and no other row is.
      added = for r <- assigns(view).results, r.added, do: r.title
      assert added == ["Estuary Tapes", "Nine Rooms"]
    end

    test "both doors into the form by hand are the form by hand" do
      for tag <- [:add_by_hand, :add_by_hand_empty] do
        view = render_info(mount_screen(AddTitleMusic), {:tap, tag})

        assert {:push, AddByHandRecord, _params} = view.socket.__mob__.nav_action
      end
    end

    test "a query past the floor answers nothing, and the card says why" do
      # Kati has no music catalogue to look in, and the board's own empty card
      # is that sentence. A screen that performed a query it cannot run would
      # read as a query that works.
      view = render_info(mount_screen(AddTitleMusic), {:change, :album_query, "ostrand"})

      assert assigns(view).results == []
      assert AddTitleMusic.named("ostrand") == "ostrand"

      # Below the floor it is the board again — screen 06's arrangement, and
      # for the reason written there.
      back = render_info(view, {:change, :album_query, "os"})
      assert length(assigns(back).results) == 3
    end
  end

  # ── screen 180, and the record it rates ─────────────────────────────────────

  describe "screen 180" do
    test "screen 74's Rate row names the album the page drew" do
      first = an_album!(@prefix <> "Tidal Works")
      second = an_album!(@prefix <> "Low Country")

      view =
        AlbumDetail
        |> mount_screen()
        |> then(
          &%{
            &1
            | socket: Mob.Socket.assign(&1.socket, :album, AlbumDetail.shelved_album(second.id))
          }
        )
        |> render_info({:tap, :rate})

      assert {:push, RateAlbum, %{album_id: id}} = view.socket.__mob__.nav_action
      assert id == second.id
      refute id == first.id
    end

    test "the rating and the note land on the album it was opened on" do
      first = an_album!(@prefix <> "Tidal Works")
      second = an_album!(@prefix <> "Low Country")

      RateAlbum
      |> mount_screen(%{album_id: second.id})
      |> render_info({:tap, :star_7})
      |> render_info({:change, :note, "Played track three until it stopped meaning anything."})
      |> render_info({:tap, :save})

      assert Ash.get!(Album, second.id).rating == 7
      assert Ash.get!(Album, second.id).note =~ "track three"
      assert Ash.get!(Album, second.id).note_on == Kati.Time.today()

      # The other record is untouched, which is the whole of rule 2 in one
      # assertion: the write acted on the row the page drew.
      assert Ash.get!(Album, first.id).rating == nil
      assert Ash.get!(Album, first.id).note == nil
    end

    test "the count under the note follows the note, not the board" do
      view = mount_screen(RateAlbum)

      # The drawing's own 104, beside a body of a different length —
      # `Kati.Rating.Sample` records the identical decision for screen 33's 184.
      assert assigns(view).characters == "104 characters"

      typed = render_info(view, {:change, :note, "hello"})
      assert assigns(typed).characters == "5 characters"
    end

    test "a named album that is gone draws the drawing and writes nothing" do
      gone = Ecto.UUID.generate()

      view =
        RateAlbum
        |> mount_screen(%{album_id: gone})
        |> render_info({:tap, :star_7})
        |> render_info({:tap, :save})

      assert assigns(view).album == AlbumDetail.drawn_album()
      assert assigns(view).save_error == "Nothing to save yet."
      refute match?({:pop}, view.socket.__mob__.nav_action)
      assert albums() == []
    end
  end

  # ── the empty state is the empty state ──────────────────────────────────────

  describe "with nothing shelved" do
    test "180 draws the drawing and refuses to commit it" do
      view = mount_screen(RateAlbum)

      assert assigns(view).album == AlbumDetail.drawn_album()
      assert assigns(view).album_id == nil
      assert assigns(view).rating == 4.5

      saved = render_info(view, {:tap, :save})

      assert assigns(saved).save_error == "Nothing to save yet."
      assert albums() == []
    end

    test "179's Artists scope is empty, and the card that rescues it is drawn" do
      view = render_info(mount_screen(AddTitleMusic), {:tap, :filter_Artists})

      assert AddTitleMusic.visible(assigns(view).results, "Artists") == []

      # With nothing typed the card still names a query, because the board's
      # own is what it is drawn from — the same rule screen 178's Artist inset
      # follows for the state it is not in.
      assert AddTitleMusic.named("") == AddTitleMusic.drawn_query()
    end

    test "178 opens on Album with nothing assumed" do
      view = mount_screen(AddByHandRecord)

      assert assigns(view).kind == :album
      assert assigns(view).title == ""
      assert assigns(view).following == false
      assert assigns(view).save_error == nil
    end
  end

  defp an_album!(title) do
    Ash.create!(Album, %{title: title, source: :manual, source_id: title})
  end
end
