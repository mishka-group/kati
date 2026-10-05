defmodule Kati.Repo.Migrations.AddTrackedTitleWatchOn do
  @moduledoc """
  Where a title is watched: the name of one of the reader's services.

  Set from a service's own page (*What you watch here*). Screen 23 counts a
  watch of the title against that service, which is the only way a service
  TMDB has never heard of — a local site, a sports pass — is ever *used*.
  `NULL` for a title nobody has placed, which falls back to TMDB's providers.
  """
  use Ecto.Migration

  def up do
    alter table(:tracked_titles) do
      add :watch_on, :text
    end
  end

  def down do
    alter table(:tracked_titles) do
      remove :watch_on
    end
  end
end
