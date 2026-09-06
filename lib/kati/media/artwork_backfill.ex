defmodule Kati.Media.ArtworkBackfill do
  @moduledoc """
  The pictures of titles that were added before there was anything to fetch them.

  ## Why this is not a function on `Kati.Media.Artwork`

  It was, for about ten minutes, and `Kati.ScreenEmptyDatabaseTest` refused it
  — correctly. That file decides which screens "reach the database" from the
  **compiled call graph**, and `Kati.Media.Artwork` is now called by
  `Kati.Design.Images.path/2`, which is called by every screen in the app that
  draws a picture. One `Ash.read!/1` inside `Artwork` therefore made a dozen
  screens — Agenda, Discover, Lists, Import, Onboarding — look like store
  readers overnight, and each was demanded to prove an empty state it has
  nothing to do with.

  The rule the closure is enforcing is a real one: **the module every render
  path touches must not be able to query.** So the query lives here, on its
  own, called from `Kati.App` at boot and from nowhere a screen can reach.
  """

  require Logger

  alias Kati.Media.Artwork

  @doc """
  Fetch the pictures of every tracked title that has not got one yet.

  `cache/1` runs when a title is ADDED, which leaves two populations without a
  picture: titles added before this module existed, and titles whose download
  failed because the device was offline at the time. Neither ever tries again
  on its own — the poster is a grey card for the life of the row — so this is
  the second half, run once at boot from `Kati.App`.

  Deliberately narrow. Only rows the user actually tracks, only rows whose
  `poster_path` is a CDN path, and only the ones with no file already on the
  disk, so a device that is up to date does one query and no requests. Failures
  are logged and skipped: a backfill that stopped at the first offline row
  would leave everything after it grey for another launch.

  Answers the number it fetched, which is what makes it testable — a boot task
  that reports nothing can only be checked by looking at the filesystem.
  """
  @spec run() :: non_neg_integer()
  def run do
    Kati.Media.CachedTitle
    |> Ash.read!()
    |> Enum.map(& &1.poster_path)
    |> Enum.filter(&Artwork.remote?/1)
    |> Enum.uniq()
    |> Enum.reject(&Artwork.local(&1, :poster))
    |> Enum.reduce(0, fn path, done ->
      case Artwork.cache(path) do
        {:ok, _file} -> done + 1
        _other -> done
      end
    end)
  rescue
    error ->
      Logger.info("artwork backfill: #{inspect(error)}")
      0
  end
end
