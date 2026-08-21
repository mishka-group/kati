defmodule Kati.Backup.Bundle do
  @moduledoc """
  One backup, in whichever of its three shapes is currently in hand.

    * `files` — the archive members as bytes, `"manifest.json"` and
      `"data/<table>.json"`. This is what gets hashed and zipped, and it is the
      only shape that is ever written to disk.
    * `manifest` — the parsed manifest, string-keyed exactly as it appears in
      the file.
    * `rows` — `%{table => [%{column => native value}]}`, present on a bundle
      that came from `Kati.Backup.Export` or one that has been through
      `Kati.Backup.Verify`, and `nil` on one that has only been unzipped.

  `rows` being `nil` is the type-level statement of the restore rule: nothing
  writes to the database from a bundle it has not verified, because a verified
  bundle is the only kind that has rows at all.
  """

  @enforce_keys [:manifest, :files]
  defstruct [:manifest, :files, rows: nil]

  @type t :: %__MODULE__{
          manifest: map(),
          files: %{String.t() => binary()},
          rows: %{String.t() => [map()]} | nil
        }
end
