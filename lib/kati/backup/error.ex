defmodule Kati.Backup.Error do
  @moduledoc """
  The one failure value the backup tree returns.

  Every refusal is a value rather than a raise, because every refusal is a
  sentence a screen has to show a user who is standing in front of a phone
  holding the only copy of their life. `reason` is what code branches on,
  `message` is what the user reads, and `details` is what a bug report needs.

  There is deliberately no partial success: an error from `Kati.Backup.restore/2`
  means **nothing was written**.
  """

  @type reason ::
          :not_a_backup
          | :unreadable_archive
          | :missing_file
          | :unexpected_file
          | :bad_manifest
          | :checksum_mismatch
          | :count_mismatch
          | :unsupported_format
          | :unsupported_schema_version
          | :unknown_resource
          | :column_mismatch
          | :bad_value
          | :duplicate_id
          | :not_empty
          | :safety_export_required
          | :write_failed
          | :unsupported_type

  defexception [:reason, :message, details: %{}]

  @type t :: %__MODULE__{reason: reason(), message: String.t(), details: map()}

  @doc "Build an error. `details` is for the log, never for the user."
  @spec new(reason(), String.t(), map()) :: t()
  def new(reason, message, details \\ %{}) do
    %__MODULE__{reason: reason, message: message, details: details}
  end

  @doc "Build an error already wrapped in `{:error, …}`."
  @spec error(reason(), String.t(), map()) :: {:error, t()}
  def error(reason, message, details \\ %{}), do: {:error, new(reason, message, details)}
end
