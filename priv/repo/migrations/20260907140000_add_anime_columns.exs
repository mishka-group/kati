defmodule Kati.Repo.Migrations.AddAnimeColumns do
  @moduledoc """
  The two columns board 152 says the anime flag needs, and had neither.

  MOVIES-AND-TV.md #104: `:anime` was a kind every reader in the app knew and
  nothing in the app ever wrote — `Kati.Screens.Library.shelf/0` queried a
  third shelf that was always empty, and screen 152's entire subject had no
  column and no writer.

  Board 152 states the rule in priority order and it needs exactly two things
  that were not stored:

    1. **Your own tag** — `tracked_titles.anime_override`. Three-valued on
       purpose: `NULL` is *I have not said*, which is not the same as *no*.
       A boolean defaulting to false could not tell "the guess is right" from
       "I have overruled the guess", and the board's first rule is that a
       reader's own answer always wins.
    2. **The provider genre** — TMDB's *Animation + Japanese origin*. `genres`
       was already kept and the origin was not, so the second half of the rule
       could not be asked. `cached_titles.original_language` is TMDB's own
       `original_language`, a two-letter tag, which is the field that answers
       it for both films and series.

  The middle rule — *a MAL or AniList file marks everything in it* — needs no
  column: the importer knows which file it read.
  """
  use Ecto.Migration

  def up do
    alter table(:tracked_titles) do
      add :anime_override, :boolean
    end

    alter table(:cached_titles) do
      add :original_language, :text
    end
  end

  def down do
    alter table(:tracked_titles) do
      remove :anime_override
    end

    alter table(:cached_titles) do
      remove :original_language
    end
  end
end
