defmodule Kati.Repo.Migrations.AddMediaEvents do
  @moduledoc """
  What happened to a title, in the order it happened.

  Screen 15 draws an activity log with four verbs — watched, rated, added,
  dropped — and until this table only the first two had anywhere to come from.
  `Kati.Media.Watch` records an act of watching; a status moving from
  `:watching` to `:dropped` overwrote a column on `Kati.Media.TrackedTitle` and
  left nothing behind, so the `Added` chip could never match a row and the
  `Dropped … after S1E3` line was a literal (MOVIES-AND-TV.md #111, #112).

  The reason is the sharpest case. Screen 149 asks *why* a show is being
  dropped and offers five answers; the answer was assigned to a socket and
  thrown away when the sheet closed — the one question in the app whose answer
  nothing could ever read back.

  Append-only. `tracked_title_id` is NULLABLE, unlike `media_watches`', because
  an import is an event with no one title behind it and screen 15 draws it as a
  row all the same.
  """
  use Ecto.Migration

  def up do
    create table(:media_events, primary_key: false) do
      add :id, :uuid, primary_key: true, null: false
      add :kind, :text, null: false
      add :at, :utc_datetime_usec, null: false
      add :season_number, :integer
      add :episode_number, :integer
      add :reason, :text
      add :from_status, :text
      add :count, :integer
      add :source_label, :text

      add :tracked_title_id,
          references(:tracked_titles, type: :uuid, on_delete: :delete_all),
          null: true

      timestamps()
    end

    # Screen 15's log across every title, newest first.
    create index(:media_events, [:at])
    # One title's own history — screen 08's ⋯ and screen 04's header.
    create index(:media_events, [:tracked_title_id, :at])
  end

  def down do
    drop table(:media_events)
  end
end
