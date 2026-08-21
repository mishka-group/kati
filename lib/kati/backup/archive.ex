defmodule Kati.Backup.Archive do
  @moduledoc """
  The zip container, in memory, both ways.

  A `.katibackup` is a zip of JSON files rather than a copy of `kati.db`,
  and #64 gives the reason: a SQLite file is opaque, coupled to the schema
  version that wrote it, and unrepairable by hand. JSON in a zip is diffable,
  greppable, and salvageable with a text editor on any machine the user owns.

  Nothing here touches the filesystem — `:zip` is driven in `:memory` mode in
  both directions — so the whole verification path runs on a binary that came
  from a picked `content://` URI just as well as from a file.
  """

  alias Kati.Backup.Bundle
  alias Kati.Backup.Error

  # A backup of a phone's lifetime of logs is a few megabytes of JSON. This cap
  # exists so a hostile or truncated file cannot be expanded into memory on a
  # device with 100MB to its name; it is two orders of magnitude above a
  # realistic file.
  @max_uncompressed_bytes 256 * 1024 * 1024

  @doc "Zip a bundle's files into one binary."
  @spec pack(Bundle.t()) :: binary()
  def pack(%Bundle{files: files}) do
    members =
      files
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.map(fn {path, bytes} -> {String.to_charlist(path), bytes} end)

    {:ok, {_name, binary}} = :zip.create(~c"kati.katibackup", members, [:memory])
    binary
  end

  @doc "The largest a backup may expand to before Kati refuses to open it."
  @spec max_uncompressed_bytes() :: pos_integer()
  def max_uncompressed_bytes, do: @max_uncompressed_bytes

  @doc """
  Unzip a binary into `%{path => bytes}`.

  Every failure mode of a file that arrived from a document picker is a value
  here: not a zip at all, truncated, or absurdly large once expanded.
  `:max_uncompressed_bytes` overrides the cap.
  """
  @spec unpack(binary(), keyword()) :: {:ok, %{String.t() => binary()}} | {:error, Error.t()}
  def unpack(binary, opts \\ [])

  def unpack(binary, opts) when is_binary(binary) do
    max = Keyword.get(opts, :max_uncompressed_bytes, @max_uncompressed_bytes)

    with :ok <- check_size(binary, max) do
      case :zip.unzip(binary, [:memory]) do
        {:ok, members} ->
          {:ok, Map.new(members, fn {name, bytes} -> {List.to_string(name), bytes} end)}

        {:error, reason} ->
          Error.error(
            :unreadable_archive,
            "This file is not a Kati backup, or it did not copy over completely.",
            %{zip: inspect(reason)}
          )
      end
    end
  end

  def unpack(_other, _opts) do
    Error.error(:not_a_backup, "This file is not a Kati backup.")
  end

  @doc "The lowercase hex SHA-256 of some bytes — one payload file's fingerprint."
  @spec sha256(binary()) :: String.t()
  def sha256(bytes), do: :sha256 |> :crypto.hash(bytes) |> Base.encode16(case: :lower)

  defp check_size(binary, max) do
    case :zip.list_dir(binary) do
      {:ok, entries} ->
        total =
          Enum.reduce(entries, 0, fn
            {:zip_file, _name, info, _comment, _offset, _comp_size}, acc ->
              acc + elem(info, 1)

            _other, acc ->
              acc
          end)

        if total > max do
          Error.error(
            :unreadable_archive,
            "This backup expands to #{total} bytes, which is more than Kati will " <>
              "open (#{max}). Kati will not read it.",
            %{uncompressed_bytes: total, max: max}
          )
        else
          :ok
        end

      {:error, reason} ->
        Error.error(
          :unreadable_archive,
          "This file is not a Kati backup, or it did not copy over completely.",
          %{zip: inspect(reason)}
        )
    end
  end
end
