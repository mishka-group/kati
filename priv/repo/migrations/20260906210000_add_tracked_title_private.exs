defmodule Kati.Repo.Migrations.AddTrackedTitlePrivate do
  @moduledoc """
  A title you would rather not put in a picture.

  Screen 98's share card draws a switch reading *Hide titles I marked private*
  and there was nothing to mark: no column, no control, and the switch moved an
  assign nothing read, so it relit over an unchanged card
  (MOVIES-AND-TV.md #103).

  A share card is the one page in this app whose whole purpose is to leave the
  device, so *some of my shelf is nobody else's business* is the most ordinary
  request it could get. This is the column that lets somebody make it, set from
  the ⋯ menu on the title's own page — which is where a decision about one
  title belongs.

  It hides a title from the CARD and from nothing else. The shelf, Up next and
  the year's own numbers are unchanged: the switch's own sentence on board 98
  is about the picture, and a private title is still a title you watched.
  """
  use Ecto.Migration

  def up do
    alter table(:tracked_titles) do
      add :private, :boolean, null: false, default: false
    end
  end

  def down do
    alter table(:tracked_titles) do
      remove :private
    end
  end
end
