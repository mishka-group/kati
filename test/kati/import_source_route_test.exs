defmodule Kati.ImportSourceRouteTest do
  @moduledoc """
  A film import does not open a page about books.

  Screen 140's six tiles each carry their own id in their tap tag, and
  `handle_tap/2` matched `"source_" <> _id` and threw it away — so all six
  pushed screen 141, a **Goodreads** job headed with *Author*, *Bookshelves*
  and *Number of Pages*. Four of those six sources are film and TV
  (Letterboxd, Trakt, MyAnimeList, AniList) and every one of them landed on a
  screen about books.

  There is no import engine behind either board. What this holds is which
  drawing a tile opens: screen 141 is a Goodreads export, screen 37 is a Trakt
  one, and a tile opens the job of its own kind.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Screens.ImportSources

  doctest ImportSources, only: [opens: 1]

  describe "the four film and TV sources" do
    for id <- ~w(letterboxd trakt myanimelist anilist) do
      test "#{id} opens the film job, not the book one" do
        assert ImportSources.opens(unquote(id)) == Kati.Screens.Import
        refute ImportSources.opens(unquote(id)) == Kati.Screens.ImportRecognised
      end
    end
  end

  describe "the two book sources" do
    for id <- ~w(goodreads storygraph) do
      test "#{id} opens the book job" do
        assert ImportSources.opens(unquote(id)) == Kati.Screens.ImportRecognised
      end
    end
  end

  describe "the tap itself" do
    test "carries the id through to the push" do
      socket = Mob.Socket.new(ImportSources)

      {:noreply, films} = ImportSources.handle_tap(ImportSources.tag(:letterboxd), socket)
      {:noreply, books} = ImportSources.handle_tap(ImportSources.tag(:goodreads), socket)

      assert {:push, Kati.Screens.Import, _} = films.__mob__.nav_action
      assert {:push, Kati.Screens.ImportRecognised, _} = books.__mob__.nav_action
    end

    test "and a tile nobody drew still opens something" do
      socket = Mob.Socket.new(ImportSources)

      {:noreply, moved} = ImportSources.handle_tap(ImportSources.tag(:nothing_drawn), socket)

      assert {:push, Kati.Screens.ImportRecognised, _} = moved.__mob__.nav_action
    end
  end
end
