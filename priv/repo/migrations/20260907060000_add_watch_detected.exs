defmodule Kati.Repo.Migrations.AddWatchDetected do
  @moduledoc """
  Whether Kati noticed this watch, or the reader told it.

  Screen 36's cream banner reads `41 EPISODES TICKED FOR YOU`, and it could not
  be derived from anything: `Kati.Media.Watch` recorded no provenance at all.
  `driven_by` is the nearest column and it is a story preference — `:character`,
  `:both`, `:plot` — not "detected versus tapped". So the banner was a literal,
  and screen 36's own moduledoc named the gap as one of two near misses.
  MOVIES-AND-TV.md #100.

  A boolean and not a source enum. Every tick has exactly two origins that
  matter to a reader — *I said so* and *Kati worked it out* — and the second is
  the one they may want to audit. Which app it was heard from is a fact about a
  session rather than about the watch, and a column for it would be one nothing
  reads.

  `false` by default, which is the truth about every row that already exists:
  nothing has ever detected anything, and a migration that guessed otherwise
  would be inventing the very count the banner was criticised for inventing.
  """
  use Ecto.Migration

  def up do
    alter table(:media_watches) do
      add :detected, :boolean, null: false, default: false
    end
  end

  def down do
    alter table(:media_watches) do
      remove :detected
    end
  end
end
