defmodule Kati.Repo.Migrations.AddTrackedTitleNumbering do
  @moduledoc """
  How one title's episodes are numbered, when the reader has said.

  One source says *episode 87* and another says *S4E12* about the same
  episode. `cached_episodes.absolute_number` could hold the first and
  `season_number`/`episode_number` hold the second, but nothing held which of
  the two a reader wants to see for a given show — screen 34's Aired/Absolute
  strip forgot the choice the moment the page closed, and screen 153 drew an
  override nobody could make.

  `tracked_titles.numbering` is that choice: `seasons` or `absolute`, and
  `NULL` for *I have not said*. `NULL` is the ordinary value and is not the
  same as either answer: `Kati.Media.Numbering.default/1` derives the scheme
  from what the title is — anime counts absolutely, everything else by season
  — and a title that later turns out to be anime should follow the new
  default rather than keep a guess nobody made.

  Held as text, the way `kind` and `status` are.
  """
  use Ecto.Migration

  def up do
    alter table(:tracked_titles) do
      add :numbering, :text
    end
  end

  def down do
    alter table(:tracked_titles) do
      remove :numbering
    end
  end
end
