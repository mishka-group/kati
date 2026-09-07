defmodule Kati.Repo.Migrations.AddMediaTitleAliases do
  @moduledoc """
  The names a reader has told Kati are one of their titles.

  Auto-detect matches what the phone announces against the shelf **by name**,
  because there is no shared id to match on: Android's `MediaMetadata` carries
  `METADATA_KEY_MEDIA_ID`, but it is app-private — Netflix's `81234567` means
  nothing to Plex and nothing to TMDB. No player publishes a TMDB or IMDb id.

  Name matching gets most of the way. `Kati.Media.CachedTitle.names/1` gives
  TMDB's own two — `Frieren: Beyond Journey's End` and `Sousou no Frieren` —
  and `Kati.Media.Detect.unfile/1` reads a filename as the name of the thing
  inside it. It does not get all the way, and it never will: a fansub group's
  spelling, a Plex library somebody renamed by hand, a service that announces
  a franchise rather than a season.

  So the last resort is the reader. Kati says *I heard “X” and could not find
  it*, they point at the title on their shelf, and this is where that answer
  lives — so it is asked **once** rather than every time that thing plays.

  Keyed on the announced name, normalised the way every other comparison in
  this domain is (`Kati.Import.Job.name_key/1`: trimmed, case-folded, nothing
  else). Unique, because one heard name means one title; teaching Kati a new
  answer replaces the old one rather than accumulating two.

  It is user data, not a cache. It goes in backups with everything else the
  reader made, and a cache wipe leaves it alone: `Kati.Media.Cache.clear/0`
  empties the three cached_* tables and this is not one of them.
  """
  use Ecto.Migration

  def up do
    create table(:media_title_aliases, primary_key: false) do
      add :id, :uuid, primary_key: true, null: false
      add :heard, :text, null: false

      add :tracked_title_id,
          references(:tracked_titles, type: :uuid, on_delete: :delete_all),
          null: false

      timestamps()
    end

    create unique_index(:media_title_aliases, [:heard])
  end

  def down do
    drop table(:media_title_aliases)
  end
end
