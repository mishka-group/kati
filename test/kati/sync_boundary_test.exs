defmodule Kati.SyncBoundaryTest do
  @moduledoc """
  Two architectural rules, checked against the compiled call graph rather than
  against prose.

  ## 1. Nothing above `Kati.Sync.Adapter` names a transport

  The engine is handed an adapter module at run time and never learns which one
  it is. That is what makes the later CalDAV and EventKit adapters cheap, and
  it is what keeps `ContentResolver` knowledge strictly below the boundary. A
  single `Kati.Sync.Adapter.DeviceProvider.pull(...)` anywhere above it would
  undo that quietly and compile perfectly.

  ## 2. No wall clock decides precedence

  `Kati.Sync.Conflict`, `Kati.Sync.Merge`, `Kati.Sync.Ownership` and
  `Kati.Sync.Revision` decide whose edit survives. None of them may read a
  clock: a phone three minutes fast, or manually set to 2019, must change no
  outcome, and the user whose clock is wrong is exactly the user least able to
  notice their edit vanished. Scheduling a retry and ageing a tombstone *do*
  use wall-clock time; deciding a winner never does.

  Both checks read the BEAM `imports` chunk — the exact list of external
  functions each module calls — so a mention inside a `@moduledoc` cannot
  satisfy them and a real call cannot hide from them.
  """
  use ExUnit.Case, async: true

  @precedence [
    Kati.Sync.Conflict,
    Kati.Sync.Merge,
    Kati.Sync.Ownership,
    Kati.Sync.Revision
  ]

  @clock_modules [DateTime, NaiveDateTime, Date, Time, :calendar, :os, :erlang, System]
  @clock_functions [
    :utc_now,
    :now,
    :system_time,
    :timestamp,
    :local_time,
    :universal_time,
    :monotonic_time
  ]

  defp app_modules do
    {:ok, modules} = :application.get_key(:kati, :modules)
    Enum.filter(modules, &match?("Elixir.Kati." <> _, Atom.to_string(&1)))
  end

  defp imports(module) do
    case :beam_lib.chunks(:code.which(module), [:imports]) do
      {:ok, {_module, [imports: imports]}} -> imports
      _ -> []
    end
  end

  defp adapters do
    Enum.filter(app_modules(), fn module ->
      Code.ensure_loaded?(module) and
        Kati.Sync.Adapter in List.wrap(module.module_info(:attributes)[:behaviour])
    end)
  end

  test "the sweep sees something, so a green result is not an empty list" do
    assert length(app_modules()) > 50
    assert Kati.Sync.Engine in app_modules()
    assert length(imports(Kati.Sync.Engine)) > 10

    # The detector finds real cross-module calls, so an empty offender list
    # below means "no offenders" and not "the chunk reader returned nothing".
    assert {Kati.Sync.Outbox, :due, 2} in imports(Kati.Sync.Engine)
  end

  test "the clock detector detects a clock" do
    # Positive control. `Kati.Sync.Outbox` legitimately reads the wall clock —
    # it schedules retries — so it must trip exactly the predicate the
    # precedence modules must not trip. Without this, the test below would pass
    # just as happily against a detector that matched nothing.
    hits =
      for {called, function, _arity} <- imports(Kati.Sync.Outbox),
          called in @clock_modules and function in @clock_functions,
          do: {called, function}

    assert hits != [], "the wall-clock predicate matches nothing at all"
  end

  test "at least two transports implement the behaviour, with all four callbacks" do
    found = adapters()

    assert Kati.Sync.Adapter.Inert in found
    assert Kati.Sync.Adapter.DeviceProvider in found

    for adapter <- found do
      assert function_exported?(adapter, :list_calendars, 1)
      assert function_exported?(adapter, :pull, 2)
      assert function_exported?(adapter, :push, 2)

      assert function_exported?(adapter, :capabilities, 1),
             "#{inspect(adapter)} is missing capabilities/1 — the part people forget"
    end
  end

  test "no module calls a concrete adapter: the engine is handed one at run time" do
    transports = MapSet.new(adapters())

    offenders =
      for module <- app_modules(),
          not MapSet.member?(transports, module),
          {called, function, arity} <- imports(module),
          MapSet.member?(transports, called) do
        "#{inspect(module)} calls #{inspect(called)}.#{function}/#{arity}"
      end

    assert offenders == [],
           "a transport is named above the adapter boundary: " <> Enum.join(offenders, ", ")
  end

  test "only the drainer and the syncer talk to an adapter at all" do
    callers =
      for path <- Path.wildcard("lib/**/*.ex"),
          source = File.read!(path),
          Regex.match?(~r/adapter\.(push|pull|capabilities|list_calendars)\(/, source),
          do: path

    assert callers == ["lib/kati/sync/engine.ex"],
           "something other than the engine calls a transport: #{inspect(callers)}"
  end

  test "the modules that decide precedence never read a clock" do
    offenders =
      for module <- @precedence,
          {called, function, arity} <- imports(module),
          called in @clock_modules and function in @clock_functions do
        "#{inspect(module)} calls #{inspect(called)}.#{function}/#{arity}"
      end

    assert offenders == [],
           "wall-clock time reached a precedence decision: " <> Enum.join(offenders, ", ")
  end

  test "the precedence modules do not reach the database either" do
    # A query is a way to smuggle `updated_at` into a decision. These four take
    # everything they need as arguments, which is also what makes them testable
    # without a repo.
    offenders =
      for module <- @precedence,
          {called, _function, _arity} <- imports(module),
          called in [Ash, Ash.Query, Kati.Repo, Ecto.Adapters.SQL],
          do: inspect(module)

    assert offenders == []
  end

  test "the engine stays free of Mob: only the transport touches the platform" do
    above =
      for path <- Path.wildcard("lib/kati/sync/**/*.ex") ++ ["lib/kati/sync.ex"],
          not String.starts_with?(path, "lib/kati/sync/adapter"),
          source = File.read!(path),
          Regex.match?(~r/\bMob\.[A-Za-z_]+\(/, source),
          do: path

    assert above == [],
           "platform knowledge leaked above the adapter boundary: #{inspect(above)}"
  end

  test "every remote mutation is written down before it is attempted" do
    # `Kati.Sync.OutboxEntry` is the only thing `Kati.Sync.Engine.drain/3` reads
    # from, so a UI path that skipped the queue would have to call the adapter
    # itself — which the test above already forbids. This one closes the other
    # half: the public write API is exactly the four functions that enqueue.
    exports = Kati.Sync.__info__(:functions) |> Keyword.keys() |> Enum.uniq()

    for name <- [:edit, :publish, :delete, :split_series] do
      assert name in exports, "Kati.Sync.#{name} is the documented write path and is missing"
    end

    enqueuers =
      for module <- app_modules(),
          {Kati.Sync.Outbox, :enqueue, 1} in imports(module),
          do: module

    assert Enum.sort(enqueuers) == Enum.sort([Kati.Sync, Kati.Sync.Tombstone]),
           "something other than the documented write path enqueues: #{inspect(enqueuers)}"
  end
end
