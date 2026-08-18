defmodule Kati.RuntimeTest do
  @moduledoc """
  Guards the host/device configuration split.

  The failure this prevents is a dependency quietly reading a key at runtime
  that only `config/config.exs` sets. On the host every test passes; on the
  phone the key is `nil` and the feature silently does nothing.
  """
  use ExUnit.Case, async: false

  @config_exs Path.expand("../../config/config.exs", __DIR__)

  describe "the registry" do
    test "configure/0 is idempotent" do
      assert :ok = Kati.Runtime.configure()
      first = snapshot()
      assert :ok = Kati.Runtime.configure()
      assert snapshot() == first
    end

    test "every registered key is actually set after configure/0" do
      Kati.Runtime.configure()

      for {app, key, value} <- Kati.Runtime.runtime_env() do
        assert Application.get_env(app, key) == value,
               "#{inspect(app)}/#{inspect(key)} not applied by configure/0"
      end
    end

    test "runtime keys and config.exs keys are disjoint" do
      config_keys =
        @config_exs
        |> File.read!()
        |> then(&Regex.scan(~r/^config\s+:(\w+),\s*:?([\w?!]+)/m, &1))
        |> Enum.map(fn [_, app, key] -> {String.to_atom(app), String.to_atom(key)} end)
        |> MapSet.new()

      runtime_keys =
        Kati.Runtime.runtime_env()
        |> Enum.map(fn {app, key, _} -> {app, key} end)
        |> MapSet.new()

      overlap = MapSet.intersection(config_keys, runtime_keys)

      assert MapSet.size(overlap) == 0,
             "keys set in both places: #{inspect(MapSet.to_list(overlap))}. " <>
               "A key belongs to exactly one — config.exs for compile_env and mix " <>
               "tasks, Kati.Runtime for anything read at runtime."
    end
  end

  describe "assert!/1" do
    test "raises with an actionable message when a table is missing" do
      Kati.Runtime.configure()

      assert_raise RuntimeError, ~r/migrations did not create/, fn ->
        Kati.Runtime.assert!(["a_table_that_does_not_exist"])
      end
    end

    test "the missing-table message names the deploy footgun that causes it" do
      Kati.Runtime.configure()

      message =
        try do
          Kati.Runtime.assert!(["nope"])
          nil
        rescue
          e -> Exception.message(e)
        end

      assert message =~ "mob.deploy --native",
             "the message must say how to fix it — priv/ is only synced by --native"
    end

    test "raises when the screen-state repo is unset" do
      original = Application.get_env(:mob, :repo)
      Application.delete_env(:mob, :repo)
      on_exit(fn -> Application.put_env(:mob, :repo, original) end)

      assert_raise RuntimeError, ~r/silent no-op/, fn ->
        Kati.Runtime.assert!([])
      end
    end
  end

  describe "the discipline" do
    test "Kati.Runtime is the only module in lib/ that writes application env" do
      offenders =
        Path.wildcard(Path.expand("../../lib/**/*.ex", __DIR__))
        |> Enum.reject(&String.ends_with?(&1, "runtime.ex"))
        |> Enum.filter(fn f ->
          # A real call, not a moduledoc mentioning `Application.put_env/3` —
          # the docs that explain this rule would otherwise trip it.
          f |> File.read!() |> String.replace(~r/^\s*#.*$/m, "") =~ "Application.put_env("
        end)
        |> Enum.map(&Path.relative_to(&1, Path.expand("../..", __DIR__)))

      assert offenders == [],
             "runtime configuration must live in Kati.Runtime, found writes in: " <>
               inspect(offenders)
    end
  end

  defp snapshot do
    Enum.map(Kati.Runtime.runtime_env(), fn {app, key, _} ->
      {app, key, Application.get_env(app, key)}
    end)
  end
end
