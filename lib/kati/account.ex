defmodule Kati.Account do
  @moduledoc """
  The device's own data, and the one operation that removes all of it.

  Kati has no account and no server, so there is nothing to sign in to and
  nothing to sign out of. What screen 40 is about is this phone: what it
  stores, what Kati may do with it, and how it leaves. `Kati.Account.Sample`
  carries the copy; this module carries the one action the copy promises.

  ## Delete everything means everything the backup carries

  `wipe!/0` deletes every row of every table in `Kati.Backup.Catalog` — the
  catalogue the backup itself is built from — in reverse order, because that
  list is parents before children and SQLite enforces the references. One
  transaction, so a failure leaves the phone exactly as it was.

  What is NOT deleted is the store the app keeps beside the database: the
  locale, the theme and the sections a reader chose are preferences about the
  app, not their films, books or meals. Signing back in is not a concept here,
  so a reader who wipes and relaunches finds their language still chosen and
  their shelves empty — which is what they asked for.
  """

  @doc """
  Every table this wipes, in the order it deletes them.

  Child-first, which is `Kati.Backup.Catalog.tables/0` reversed: that list is
  in insert order because a restore has to create parents before children.
  """
  @spec tables() :: [String.t()]
  def tables, do: Enum.reverse(Kati.Backup.Catalog.tables())

  @doc """
  Delete everything the app stores. Returns `:ok` or the error that kept the
  phone as it was.

  The whole delete is one transaction: `Kati.Repo` is a single connection
  (`pool_size: 1`), so a half-deleted shelf is worse than a refusal.
  """
  @spec wipe!() :: :ok | {:error, term()}
  def wipe! do
    case Kati.Repo.transaction(fn -> Enum.each(tables(), &delete!/1) end) do
      {:ok, _result} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp delete!(table) do
    Kati.Repo.query!("DELETE FROM #{table}", [])
  end
end
