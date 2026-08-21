defmodule Kati.Backup.Upgrade do
  @moduledoc """
  Older backups, brought forward one schema version at a time.

  #64's forward-compatibility rule has two halves and they are not symmetric: a
  **newer** file is refused outright by `Kati.Backup.Manifest`, and an **older**
  file must keep working forever. This is the second half.

  A step is `{from, to, fun}` where `fun` takes `%{table => [row]}` — rows still
  as JSON, before any column is decoded — and returns the same shape one
  version newer. `walk/3` composes them, so a v1 file read by a v4 app runs
  three functions rather than one function that has to remember three shapes.

  There are no steps yet, because there has only ever been one schema version.
  The walker is here and tested anyway: the moment the first column moves,
  writing the step is the whole job, and nobody has to invent the mechanism
  under the pressure of a user whose backup will not open.
  """

  alias Kati.Backup.Catalog
  alias Kati.Backup.Error

  @type rows :: %{String.t() => [map()]}
  @type step :: {pos_integer(), pos_integer(), (rows() -> rows())}

  @doc "Every upgrade step, oldest first."
  @spec steps() :: [step()]
  def steps, do: []

  @doc """
  Bring rows from `from` up to the current schema version.

  Fails rather than guessing when a version has no path forward — a file from a
  version this app has no step for is a file it cannot honestly claim to read.
  """
  @spec walk(rows(), pos_integer(), [step()]) :: {:ok, rows()} | {:error, Error.t()}
  def walk(rows, from, steps \\ steps()) do
    walk(rows, from, Catalog.schema_version(), steps)
  end

  @doc """
  `walk/3` with the destination spelled out.

  The general form: `walk/3` is this with the target fixed at whatever version
  the app is on today.
  """
  @spec walk(rows(), pos_integer(), pos_integer(), [step()]) ::
          {:ok, rows()} | {:error, Error.t()}
  def walk(rows, from, target, steps), do: walk_to(rows, from, target, steps)

  defp walk_to(rows, version, target, _steps) when version == target, do: {:ok, rows}

  defp walk_to(rows, version, target, steps) do
    case Enum.find(steps, fn {from, _to, _fun} -> from == version end) do
      {_from, to, fun} -> walk_to(fun.(rows), to, target, steps)
      nil -> no_path(version, target)
    end
  end

  defp no_path(version, target) do
    Error.error(
      :unsupported_schema_version,
      "This backup was written with schema version #{version}, and this version of " <>
        "Kati (schema version #{target}) has no way to read it. Nothing has been changed.",
      %{from: version, to: target}
    )
  end
end
