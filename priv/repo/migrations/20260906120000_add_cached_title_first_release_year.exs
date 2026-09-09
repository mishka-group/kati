defmodule Kati.Repo.Migrations.AddCachedTitleFirstReleaseYear do
  @moduledoc """
  The year a title came out, which nothing could hold.

  `Kati.Media.CachedTitle` carries `next_release_at` — the NEXT release — and
  no first-air or first-release date at all. Three screens have been paying for
  that absence:

    * screen 154's form collects a **Year**, holds it on the socket and drops
      it (MOVIES-AND-TV.md #59);
    * screen 14's meta line draws `2024 · 15 · DRAMA…` on its board and can
      only produce the genres, the season count and the episode count (#51);
    * screen 145's decade chips have nothing to bucket by (#54).

  A YEAR and not a date. A provider gives a full release date and Kati stores
  one already for the next episode; what these three screens ask for is the
  year, and a column that held a date would invite a precision the two boards
  do not draw and the third cannot use. `Kati.Media.Release` is explicit that a
  bare year must not become 1 January, and this is the column that lets a bare
  year stay one.

  Nullable, because it is genuinely unknown for a hand-typed title and for
  anything a provider has not dated — and an unknown year and a year of zero
  are not the same thing.
  """
  use Ecto.Migration

  def up do
    alter table(:cached_titles) do
      add :first_release_year, :integer
    end
  end

  def down do
    alter table(:cached_titles) do
      remove :first_release_year
    end
  end
end
