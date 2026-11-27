defmodule Kati.SearchMusicBrainzTest do
  @moduledoc """
  An album found in MusicBrainz is a row that adds itself.

  Screen 19's music panel used to say *searching is coming*; the catalogue is
  real now (`Kati.Media.MusicBrainz`), so the row exists, its tag names the
  release group, and pressing it writes the artist and album and opens the
  album's page.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Music.Album
  alias Kati.Music.Artist
  alias Kati.Screens.Search

  @row %{
    title: "Tide Ledger",
    sub: "Kell Ostrand · 1997 · Album",
    seed: "7f2b5d0e-0000-0000-0000-000000000000",
    kind: :album,
    source: :musicbrainz,
    source_id: "7f2b5d0e-0000-0000-0000-000000000000",
    artist: "Kell Ostrand",
    year: 1997,
    kind_label: "Album"
  }

  setup do
    on_exit(fn ->
      Album |> Ash.read!() |> Enum.each(&Ash.destroy!/1)
      Artist |> Ash.read!() |> Enum.each(&Ash.destroy!/1)
    end)

    :ok
  end

  test "a catalogue row's tag names the release group" do
    assert Search.hit_tag(@row) == :shelf_album_7f2b5d0e_0000_0000_0000_000000000000
  end

  test "the music section draws the catalogue's rows before the shelf's" do
    drawn = text(Search.rows([@row]))
    assert drawn =~ "Tide Ledger"
    assert drawn =~ "Kell Ostrand"
  end

  test "adding an album writes the album and its artist, only once" do
    assert {:ok, album} = Search.add_album(@row)
    assert album.title == "Tide Ledger"
    assert album.source == :musicbrainz
    assert album.released_year == 1997

    assert [artist] = Ash.read!(Artist)
    assert artist.name == "Kell Ostrand"
    assert album.artist_id == artist.id

    assert {:ok, again} = Search.add_album(@row)
    assert again.id == album.id
    assert length(Ash.read!(Album)) == 1
    assert length(Ash.read!(Artist)) == 1
  end

  test "pressing the row adds the album and opens it" do
    view = mount_screen(Search, %{query: "tide"})
    socket = Mob.Socket.assign(view.socket, :music_hits, [@row])

    moved =
      Search.handle_info({:tap, :shelf_album_7f2b5d0e_0000_0000_0000_000000000000}, socket)
      |> elem(1)

    assert [album] = Ash.read!(Album)
    assert moved.__mob__.nav_action == {:push, Kati.Screens.AlbumDetail, %{album_id: album.id}}
  end
end
