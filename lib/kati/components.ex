defmodule Kati.Components do
  @moduledoc """
  Mishka Chelekom's headless Mob components, vendored into Kati.

  These are copies of
  `mishka_chelekom/development/mob/lib/mishka_mob/components/*.ex` with the
  module namespace rewritten from `MishkaMob.Components` to
  `Kati.Components`. Nothing else is changed, so a component here can be
  diffed against its origin and any fix can travel back.

  **Copied, not generated.** `mix mishka.ui.gen.mob` hangs (#78), and a
  generator is not needed for this: the components are plain modules, so
  bringing them in is a copy and a rename.

  **Headless.** Every one takes its look from props — the design's colours,
  radii and type are passed at the call site, and the component contributes
  structure and behaviour. Where a component cannot express something the
  design needs, the fix belongs upstream in Mishka Chelekom rather than in a
  local edit here, so every Chelekom user gets it.

  ## Registering

  A composite tag (`<MishkaChip />` in `~MOB` markup) only expands once its
  tag is registered with `Mob.Composite`. `register_all/0` does that for every
  vendored component and is called from `Kati.App` at boot.

  The tag is the snake_case of the module name — `MishkaChip` is
  `:mishka_chip`, `MishkaCloseButton` is `:mishka_close_button` — which is the
  same rule Mishka's own catalog follows, so the registry is derived rather
  than transcribed. A hand-written list would be one more thing to forget to
  update when a component is added.
  """

  @source_dir "lib/kati/components"

  # Derived from the SOURCE FILES, not from the loaded module list.
  #
  # `:code.all_available/0` at compile time returns whatever happens to be
  # compiled already, so on a clean `mix compile --force` this module can be
  # built before the components it is meant to list and the registry resolves
  # EMPTY — with no error, and every `<MishkaChip />` in the app silently
  # expanding to nothing. The file list cannot do that.
  #
  # `@external_resource` so adding a component recompiles this module rather
  # than leaving a stale registry behind.
  @component_files @source_dir |> Path.join("*.ex") |> Path.wildcard() |> Enum.sort()
  for file <- @component_files, do: @external_resource(file)

  @components @component_files
              |> Enum.map(&Path.basename(&1, ".ex"))
              |> Enum.map(&Macro.camelize/1)
              |> Enum.filter(&String.starts_with?(&1, "Mishka"))
              |> Enum.map(&Module.concat(Kati.Components, &1))
              |> Enum.sort()

  @doc """
  Every vendored component module.

  Resolved at COMPILE time from the source files, because
  `:code.all_available/0` at runtime on the device walks a flat `-pa`
  directory of 3000+ BEAMs.
  """
  @spec modules() :: [module()]
  def modules, do: @components

  @doc "The `~MOB` tag a module answers to: `MishkaChip` -> `:mishka_chip`."
  @spec tag(module()) :: atom()
  def tag(module) do
    module
    |> Module.split()
    |> List.last()
    |> Macro.underscore()
    |> String.to_atom()
  end

  @doc """
  Register every vendored component as a composite tag.

  Only modules that actually export `expand/3` are registered: a few files
  here are pure helpers (`Color`, `Event`) or are not composite tags at all,
  and registering those would put a tag in the registry that expands to
  nothing.
  """
  @spec register_all() :: :ok
  def register_all do
    for module <- modules(), composite?(module) do
      Mob.Composite.register(tag(module), {module, :expand})
    end

    :ok
  end

  # `Code.ensure_loaded?/1` FIRST, and this is not defensive padding.
  #
  # `function_exported?/3` answers about a LOADED module and returns false for
  # one that simply has not been loaded yet. Modules load lazily, and on the
  # device they live in a flat `-pa` directory, so at boot none of these are
  # loaded — the guard was false for all 74 and `register_all/0` registered
  # NOTHING. An unregistered composite tag renders as nothing rather than
  # raising, so every component would have silently drawn empty.
  defp composite?(module) do
    Code.ensure_loaded?(module) and function_exported?(module, :expand, 3)
  end
end
