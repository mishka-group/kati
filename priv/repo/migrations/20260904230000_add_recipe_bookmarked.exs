defmodule Kati.Repo.Migrations.AddRecipeBookmarked do
  @moduledoc """
  Screen 45's bookmark disc gets a column to write to.

  The board has drawn the control since the screen was built and nothing could
  hold it, so the tap sat on `Kati.ScreenTapSweepTest`'s backlog under its own
  heading: *a button that never marks anything*.

  `null: false` with a default, so every recipe already in a store answers the
  question rather than answering `nil` — an unbookmarked recipe and one nobody
  has been asked about are the same thing, and a tri-state would make the
  screen decide which of them a blank disc means.
  """
  use Ecto.Migration

  def up do
    alter table(:recipes) do
      add :bookmarked, :boolean, null: false, default: false
    end
  end

  def down do
    alter table(:recipes) do
      remove :bookmarked
    end
  end
end
