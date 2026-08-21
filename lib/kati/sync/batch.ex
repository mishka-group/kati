defmodule Kati.Sync.Batch do
  @moduledoc """
  Bounded batches inside a hand-rolled `Kati.Repo.transaction/1`.

  Two facts force this shape. AshSqlite reports `can?(:transact) == false`, so
  Ash actions are **not** atomic and there is no `Ash.transaction` to lean on —
  the transaction has to be opened on the repo directly. And `pool_size: 1`,
  because SQLite is a single writer, so the sync engine and the UI share one
  connection: a transaction held open for the length of a whole account sync is
  a UI that has stopped responding.

  So: chunk the work, wrap each chunk, let go of the connection between chunks.
  A chunk is atomic; a sync is not, and does not need to be — every operation in
  it is independently meaningful and replayable, which is the same property
  `Kati.Notifications.Reconcile` relies on for the same reason.
  """

  @default_size 50

  @doc """
  Run `fun` over `items` in transactional chunks, returning every result in
  order.

  A chunk that raises rolls that chunk back and re-raises, so a bug cannot
  leave half a chunk applied and report success. Earlier chunks stay committed
  — deliberately: they are the work that did land, and discarding them would
  mean a single malformed event undoes an otherwise good sync.
  """
  @spec run([item], (item -> result), keyword()) :: [result] when item: term(), result: term()
  def run(items, fun, opts \\ []) do
    size = Keyword.get(opts, :size, @default_size)

    items
    |> Enum.chunk_every(size)
    |> Enum.flat_map(&transact(&1, fun))
  end

  defp transact(chunk, fun) do
    case Kati.Repo.transaction(fn -> Enum.map(chunk, fun) end) do
      {:ok, results} -> results
      {:error, reason} -> raise "sync batch rolled back: #{inspect(reason)}"
    end
  end

  @doc "The default chunk size, so callers and tests agree on one number."
  @spec default_size() :: pos_integer()
  def default_size, do: @default_size
end
