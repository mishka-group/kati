defmodule Kati.Spike do
  @moduledoc """
  Throwaway Ash domain proving AshSqlite works on a device BEAM.

  Exists only to satisfy the acceptance criteria of the Ash spike. Delete it,
  and its migration, once the real domains land.
  """
  use Ash.Domain, validate_config_inclusion?: false

  resources do
    resource(Kati.Spike.Thing)
  end
end
