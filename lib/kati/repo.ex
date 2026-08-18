defmodule Kati.Repo do
  @moduledoc """
  Kati's SQLite repository.

  Uses `AshSqlite.Repo` rather than `Ecto.Repo` directly. That matters more than
  it looks: `AshSqlite.Repo.__using__` defines its own `init/2` which injects
  `installed_extensions`, `migrations_path` and `case_sensitive_like`. Returning
  `{:ok, config}` from our `init/2` — as the Mob template's plain Ecto repo does —
  would skip all of it. Hence `super(type, config)`.
  """
  use AshSqlite.Repo, otp_app: :kati

  @impl AshSqlite.Repo
  def installed_extensions, do: []

  # Required by the AshSqlite.Repo behaviour and meaningless for SQLite.
  @impl AshSqlite.Repo
  def min_pg_version, do: %Version{major: 10, minor: 0, patch: 0}

  @impl Ecto.Repo
  def init(type, config) do
    config =
      Keyword.merge(config,
        # `Mob.data_dir/0` is the documented writable location — Android's
        # `getFilesDir()`, iOS's NSDocumentDirectory — and falls back to
        # $HOME/cwd off device so host tooling works.
        #
        # Deliberately NOT MOB_BEAMS_DIR: on iOS that points inside the signed,
        # read-only .app bundle, so writes fail with :eperm. That trap stays
        # hidden until the app ships to iOS.
        database: Path.join(Mob.data_dir(), "kati.db"),
        # One connection. SQLite is single-writer, and the device has no pool to
        # gain from.
        pool_size: 1,
        # AshSqlite has can?(:transact) == false, so actions are not atomic;
        # immediate mode at least takes the write lock up front rather than
        # failing midway on contention.
        default_transaction_mode: :immediate,
        busy_timeout: 5_000
      )

    super(type, config)
  end
end
