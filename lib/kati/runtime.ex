defmodule Kati.Runtime do
  @moduledoc """
  The **only** place Kati writes runtime application environment.

  `config/*.exs` is host-only. The device boots `start_clean` with no `-config`
  in argv and an empty `.app` env, so every `config :foo, :bar, …` line is
  invisible on a phone. Measured on device (#31):

      Application.get_env(:kati, :ecto_repos)   #=> nil     (device)
      Application.get_env(:kati, :ecto_repos)   #=> [Kati.Repo]  (host)

  So: any key a dependency reads via `Application.get_env/2` **at runtime**
  must be set here. Any key read via `Application.compile_env/2` must stay in
  `config/config.exs` and must **not** appear here — it is baked at compile
  time and setting it at runtime does nothing.

  `test/test_helper.exs` calls `configure/0` too, so host tests and the device
  configure through the identical code path. That is what makes a host test
  about configuration meaningful.
  """

  @doc """
  Writes every runtime key Kati or its dependencies need. Idempotent.
  """
  @spec configure() :: :ok
  def configure do
    Enum.each(runtime_env(), fn {app, key, value} ->
      Application.put_env(app, key, value)
    end)

    :ok
  end

  @doc """
  The runtime key registry: `{app, key, value}`.

  Load-bearing (the app is wrong without them):

    * `:mnesia/:dir` — `:ash` declares `extra_applications: [:mnesia]`, so mnesia
      starts on the phone regardless. Without a writable dir it fails at boot.
    * `:mob/:repo` — `Mob.ScreenState` is a **silent no-op** when unset, so
      screen state would simply never persist and nothing would say so.

  Defensive (correct by default, set so a future change cannot flip them):

    * `:ash/:disable_async?` — async execution buys nothing against a
      single-connection SQLite repo on a phone and risks contention.
  """
  @spec runtime_env() :: [{atom(), atom(), term()}]
  def runtime_env do
    [
      {:mnesia, :dir, String.to_charlist(Mob.data_dir())},
      {:mob, :repo, Kati.Repo},
      {:ash, :disable_async?, true},
      # Without this, Calendar falls back to UTCOnlyTimeZoneDatabase and every
      # zone lookup fails — silently for display, catastrophically for
      # recurrence. `tz` compiles IANA data in at build time, so there is no
      # writable directory and no network involved.
      {:elixir, :time_zone_database, Tz.TimeZoneDatabase}
    ]
  end

  @doc """
  Fails the boot loudly when the runtime environment is not what the app needs.

  Every condition here currently fails **silently** in a stock Mob app: missing
  tables render as a frozen screen because the screen GenServer crashes on its
  first query, and an unset repo key makes screen-state persistence quietly do
  nothing. Raising here converts each into a crash with a readable message,
  which reaches logcat through `Mob.NativeLogger`.

  `expected_tables` is passed in rather than hardcoded so the caller — which
  knows which migrations it just ran — owns the list.
  """
  @spec assert!([String.t()]) :: :ok
  def assert!(expected_tables) do
    check!(
      Application.get_env(:mob, :repo) == Kati.Repo,
      "Mob screen-state repo is not configured. Mob.ScreenState is a silent " <>
        "no-op without it, so screen state would never persist. " <>
        "Kati.Runtime.configure/0 must run before this point."
    )

    dir = Mob.data_dir()

    check!(
      File.dir?(dir) and writable?(dir),
      "data dir #{dir} is missing or not writable — the database cannot be opened"
    )

    present = table_names()
    missing = expected_tables -- present

    check!(
      missing == [],
      "migrations did not create #{inspect(missing)}. Present: #{inspect(present)}. " <>
        "This is the \"Migrations already up\" failure: most often priv/ was not " <>
        "synced to the device, which `mix mob.deploy` does NOT do — only " <>
        "`mix mob.deploy --native` copies priv/."
    )

    :ok
  end

  defp check!(true, _message), do: :ok

  defp check!(false, message) do
    # Print before raising. Mob catches whatever `on_start/0` raises, logs it as
    # `step N => {error, #{message => <<75,97,...>>}}` — a raw byte list, which
    # is unreadable in logcat — and then lets the app carry on. So the raise
    # alone is neither loud nor fatal. Measured on device (#31).
    #
    # stdout is piped to logcat under the BEAMout tag as plain text, which is
    # what makes this legible at all.
    banner = String.duplicate("=", 60)

    IO.puts("""

    #{banner}
    KATI BOOT ASSERTION FAILED
    #{banner}
    #{message}
    #{banner}
    """)

    raise "Kati.Runtime.assert!/1: " <> message
  end

  defp writable?(dir) do
    probe = Path.join(dir, ".kati_write_probe")

    case File.write(probe, "1") do
      :ok -> File.rm(probe) == :ok
      _ -> false
    end
  end

  defp table_names do
    case Ecto.Adapters.SQL.query(
           Kati.Repo,
           "select name from sqlite_master where type='table'",
           []
         ) do
      {:ok, %{rows: rows}} -> rows |> List.flatten() |> Enum.sort()
      _ -> []
    end
  rescue
    _ -> []
  end
end
