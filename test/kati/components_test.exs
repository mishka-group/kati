defmodule Kati.ComponentsTest do
  @moduledoc """
  Guards the vendored Mishka Chelekom components against silent emptiness.

  The registry is derived rather than hand-written, which removes one way to
  get it wrong and introduces another: a derivation that returns nothing looks
  exactly like a codebase with no components, and an unregistered composite
  tag renders as NOTHING rather than raising. So the count is asserted against
  the files on disk.
  """
  use ExUnit.Case, async: true

  @source_dir "lib/kati/components"

  test "every vendored component file is in the registry" do
    on_disk =
      @source_dir
      |> Path.join("mishka_*.ex")
      |> Path.wildcard()
      |> Enum.map(&Path.basename(&1, ".ex"))
      |> MapSet.new()

    registered =
      Kati.Components.modules()
      |> Enum.map(fn m -> m |> Module.split() |> List.last() |> Macro.underscore() end)
      |> MapSet.new()

    assert MapSet.size(on_disk) > 0, "no component files found — did the vendored copy move?"
    assert MapSet.difference(on_disk, registered) |> MapSet.to_list() == []
  end

  test "the tag of a module is the snake_case of its name" do
    assert Kati.Components.tag(Kati.Components.MishkaChip) == :mishka_chip
    assert Kati.Components.tag(Kati.Components.MishkaCloseButton) == :mishka_close_button
  end

  test "register_all registers every composite, and enough of them to be real" do
    Kati.Components.register_all()

    composites = Enum.filter(Kati.Components.modules(), &function_exported?(&1, :expand, 3))

    # A registry that silently resolved to nothing would pass every assertion
    # above that is only about consistency, so this one is about SIZE.
    assert length(composites) > 60

    # `Mob.Composite` has no `registered?/1` — the registry is a plain map in
    # persistent_term, so ask it directly.
    expanders = Mob.Composite.expanders()

    for module <- composites do
      tag = Kati.Components.tag(module)
      assert Map.get(expanders, tag) == {module, :expand}, "#{tag} did not register"
    end
  end

  @markup_dirs ["lib/kati/screens", "lib/kati/ui", "lib/kati/ui.ex", "lib/kati/shell.ex"]

  test "composite tags are registered at boot, or no markup uses one" do
    tags =
      @markup_dirs
      |> Enum.flat_map(fn path ->
        if File.dir?(path), do: Path.wildcard(Path.join(path, "**/*.ex")), else: [path]
      end)
      |> Enum.filter(&File.exists?/1)
      |> Enum.flat_map(fn file ->
        file
        |> File.read!()
        |> String.split("\n")
        |> Enum.reject(&(String.trim_leading(&1) |> String.starts_with?("#")))
        |> Enum.join("\n")
        |> then(&Regex.scan(~r/<(Mishka[A-Za-z]+)[\s\/>]/, &1))
        |> Enum.map(fn [_, tag] -> {file, tag} end)
      end)

    boot_registers? =
      "lib/kati/app.ex" |> File.read!() |> String.contains?("Components.register_all()")

    # An unregistered composite tag renders as NOTHING rather than raising, so
    # this is the only thing standing between "someone wrote <MishkaChip/>" and
    # a blank area on a screen. register_all/0 is off the boot path because it
    # costs ~245ms of cold start and nothing uses tags; the moment something
    # does, this fails and names the trade.
    assert tags == [] or boot_registers?,
           """
           markup uses composite tags but Kati.App does not call \
           Kati.Components.register_all/0, so they will render as NOTHING:

             #{Enum.map_join(tags, "\n  ", fn {f, t} -> "#{f}: <#{t}>" end)}

           Either register at boot (costing ~245ms of cold start) or use the \
           direct function call, e.g. Kati.Components.MishkaChip.chip(...).
           """
  end
end
