defmodule Kati.Repo.Migrations.AddEventTitleAndAlarm do
  @moduledoc """
  A scheduled watch knows what it is for, and when to say so (#124).

  `events.tracked_title_id` is the title a *Schedule* on a film, show or anime
  page was made for, so the calendar row and the title's own page can find each
  other. `NULL` for every event that is not a scheduled watch.

  `events.alarm_minutes` is how long before the start the reader asked to be
  reminded — `0` at the start, `60` an hour before — and `NULL` for no
  reminder. Quick Add has always read *remind 1h before* out of a sentence and
  then dropped it on the floor; this is where it goes.

  Held as text and an integer, the way the rest of the table holds its ids and
  numbers.
  """
  use Ecto.Migration

  def up do
    alter table(:events) do
      add :tracked_title_id, :text
      add :alarm_minutes, :integer
    end
  end

  def down do
    alter table(:events) do
      remove :tracked_title_id
      remove :alarm_minutes
    end
  end
end
