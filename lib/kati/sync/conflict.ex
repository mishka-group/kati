defmodule Kati.Sync.Conflict do
  @moduledoc """
  Did both sides move? Two comparisons, no clock.

      local_dirty  = local_rev > synced_rev
      remote_moved = fetched_etag != stored_remote_etag
      conflict     = local_dirty and remote_moved

  Nothing here reads `LAST-MODIFIED`, `DTSTAMP`, `updated_at` or the device
  clock. That is not fastidiousness: a phone three minutes fast, or manually
  set to 2019, would otherwise change which edit survives — and the user whose
  clock is wrong is exactly the user least able to notice their edit vanished.
  `Kati.SyncBoundaryTest` reads this module's source and fails the build if a
  timestamp comparison appears in it.

  ## Why a `nil` stored etag is not evidence

  sabre warns that a `PUT` *"often"* returns an ETag but sometimes does not, and
  both Google's CalDAV and iCloud rewrite the object server-side after storing
  it. So a successful push can legitimately leave `remote_etag` unset. Reading
  that as "the remote moved" would manufacture a conflict on every such push;
  reading it as *unknown* costs one extra pull and invents nothing. The next
  pull fills the etag in.

  ## The provider transport

  `CalendarContract` has no etag. It has `_SYNC_ID` and a `DIRTY` flag, and the
  arbitration is between Kati and the OS sync adapter rather than between Kati
  and a server. `detect_provider/2` reads those instead, with the same shape of
  answer, so the engine above never learns which transport it is talking to.
  """

  alias Kati.Sync.Revision

  @typedoc """
  What the two comparisons found.

    * `:clean` — neither side moved.
    * `:local_only` — push it.
    * `:remote_only` — apply the pull over it.
    * `:conflict` — both moved. `Kati.Sync.Merge` decides what that means.
  """
  @type t :: :clean | :local_only | :remote_only | :conflict

  @doc """
  Compare a local row against what the transport just handed back.

  `fetched_etag` is the etag on the pulled copy — Google's `etag`, CalDAV's
  `ETag`, Graph's `@odata.etag`. Pass `nil` when the transport did not supply
  one; that is treated as *unknown*, never as *moved*.
  """
  @spec detect(Revision.row(), String.t() | nil) :: t()
  def detect(row, fetched_etag) do
    decide(Revision.dirty?(row), remote_moved?(row.remote_etag, fetched_etag))
  end

  @doc """
  The `CalendarContract` equivalent.

  `dirty_flag` is the provider's `Events.DIRTY` for the row and `sync_id` its
  `_SYNC_ID`. A `_SYNC_ID` that changed means the OS sync adapter replaced the
  row underneath us, which is the provider's version of "the remote moved"; a
  set `DIRTY` means the provider itself holds an unsynced change.
  """
  @spec detect_provider(Revision.row(), %{
          optional(:sync_id) => String.t() | nil,
          optional(:dirty) => boolean()
        }) :: t()
  def detect_provider(row, provider) do
    sync_id = Map.get(provider, :sync_id)
    moved? = remote_moved?(row.remote_id, sync_id) or Map.get(provider, :dirty, false)
    decide(Revision.dirty?(row), moved?)
  end

  defp decide(true, true), do: :conflict
  defp decide(true, false), do: :local_only
  defp decide(false, true), do: :remote_only
  defp decide(false, false), do: :clean

  # An unknown value on either side is not evidence of movement.
  defp remote_moved?(nil, _fetched), do: false
  defp remote_moved?(_stored, nil), do: false
  defp remote_moved?(stored, fetched), do: stored != fetched
end
