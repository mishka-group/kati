defmodule Kati.Sync.Revision do
  @moduledoc """
  The `local_rev` / `synced_rev` pair, and the one race it exists to survive.

  A dirty **boolean** loses an edit. The sequence is: push of revision 4 goes
  out; the user edits the row while it is in flight; the push succeeds and
  clears the flag; revision 5 is now on the device, marked clean, and will
  never be sent. The pair cannot do that — the push acknowledges *revision 4*,
  so `synced_rev` becomes 4, `local_rev` is 5, and the row is still correctly
  dirty.

  That is the whole reason both columns exist, and it is why `mark_pushed/2`
  takes the revision that was **pushed** rather than reading the row's current
  one.

  ## Counters, not clocks

  `local_rev` is a monotonic integer with no relationship to any wall clock. It
  is comparable only with its own row's `synced_rev` — never across rows, never
  across devices, never against a server timestamp. Two devices' `local_rev`s
  mean nothing to each other; that is what etags are for.
  """

  alias Kati.Calendars.Event
  alias Kati.Calendars.Override

  @typedoc "Anything carrying the sync bookkeeping columns."
  @type row :: Event.t() | Override.t()

  @doc "`local_rev > synced_rev`. The only definition of dirty in the system."
  @spec dirty?(row()) :: boolean()
  def dirty?(%{local_rev: local, synced_rev: synced}), do: local > synced

  @doc """
  The revision a write **about to happen** will produce.

  `Kati.Calendars.Changes.BumpLocalRev` increments on every local write, so the
  caller of an Ash update knows the resulting revision before the update runs.
  The sync engine needs that to write `synced_rev` in the *same* changeset when
  it is applying a remote change — otherwise applying a pull would leave every
  mirrored row permanently dirty and every foreground would try to push the
  server's own data back at it.
  """
  @spec next_rev(row()) :: pos_integer()
  def next_rev(%{local_rev: local}), do: local + 1

  @doc """
  Attributes that mark a row clean **as of the revision that was pushed**.

  If the user edited the row while the push was in flight, `local_rev` has
  already moved past `pushed_rev` and the row stays dirty — deliberately, and
  `synced_rev` stays at `pushed_rev` so the newer edit is still owed to the
  server.

  If nothing moved, `synced_rev` is `next_rev/1` rather than `pushed_rev`. That
  looks like an off-by-one and is not: the acknowledgement is written through
  the same `:update` action every local write uses, so
  `Kati.Calendars.Changes.BumpLocalRev` bumps `local_rev` as this very
  changeset is applied. Writing `pushed_rev` would leave the row one revision
  dirty **for ever**, and every foreground would push the server its own data
  back. The bookkeeping has to absorb its own bump.
  """
  @spec mark_pushed(row(), pos_integer(), map()) :: map()
  def mark_pushed(row, pushed_rev, remote_ref \\ %{}) do
    still_dirty? = row.local_rev > pushed_rev

    %{
      synced_rev: if(still_dirty?, do: pushed_rev, else: next_rev(row)),
      sync_state: if(still_dirty?, do: :dirty, else: :clean)
    }
    |> put_present(:remote_id, Map.get(remote_ref, :id))
    |> put_present(:remote_etag, Map.get(remote_ref, :etag))
    |> put_present(:remote_href, Map.get(remote_ref, :href))
  end

  @doc """
  Attributes that mark a row clean after **applying a pull** to it.

  `next_rev/1` rather than the current revision because the Ash update that
  carries these attributes will itself bump `local_rev`; writing the current
  value would leave the row one revision dirty forever.
  """
  @spec mark_pulled(row(), map()) :: map()
  def mark_pulled(row, remote_ref \\ %{}) do
    rev = next_rev(row)

    %{synced_rev: rev, sync_state: :clean}
    |> put_present(:remote_id, Map.get(remote_ref, :id))
    |> put_present(:remote_etag, Map.get(remote_ref, :etag))
    |> put_present(:remote_href, Map.get(remote_ref, :href))
  end

  # A transport that returned no etag must not erase the one already stored.
  defp put_present(attrs, _key, nil), do: attrs
  defp put_present(attrs, key, value), do: Map.put(attrs, key, value)
end
