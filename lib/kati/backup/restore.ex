defmodule Kati.Backup.Restore do
  @moduledoc """
  A verified bundle into the database — the hard half.

  ## What happens to rows that are already there

  Three modes, and the default is the refusal:

    * **`:into_empty`** (default) — every backed-up table must be empty. If any
      one of them is not, the restore refuses and names what it found, and the
      database is untouched. This is the only mode with no way to lose
      anything, which is why it is what you get when you do not choose.
    * **`:merge`** — insert-only, by primary key. A row whose id is already
      here is **skipped**; nothing existing is ever overwritten, updated or
      deleted, and the count of skips comes back in the report. If a backup row
      collides with an existing row on a natural key instead of an id — the
      same show tracked again on the new phone under a fresh id — the whole
      restore is refused rather than guessing which of the two the user meant.
      Screen 37's per-conflict resolver is what eventually answers that
      question; a lossless restore must not wait for it.
    * **`:replace`** — the tables are emptied and the backup takes their place.
      Only reachable by asking for it **and** by handing over a `:safety_sink`
      that successfully takes an export of the current state first. If the
      safety export cannot be written, the wipe does not happen. #64: *"replace
      auto-exports current state first."*

  ## Nothing partial, on a data layer that says it cannot transact

  `AshSqlite` reports `can?(:transact) == false`, so an Ash action is not
  atomic and a fourteen-table restore is thousands of separate writes. The
  repository underneath is still Ecto and still SQLite, so every write here —
  the deletes and the inserts both — runs inside one `Kati.Repo.transaction/1`,
  and any failure at any point rolls the whole thing back, including a
  `:replace`'s wipe. A restore either happened or it did not.

  ## Rows go in exactly as they came out

  Writes go through `Ash.Seed.seed!/2`, which addresses the data layer directly
  and runs no action, no change and no validation. That is not a shortcut, it
  is the requirement: `Kati.Media.Changes.Touch` would stamp `last_touched_at`
  with the moment of the restore and reorder every shelf, `timestamps()` would
  replace `inserted_at` with today, and `Kati.Meals.MealLog`'s create actions
  would recompute the frozen nutrition figures from whatever the recipe says
  *now* — destroying the one property #73 exists to establish. A restore
  replays rows, not the user's actions.
  """

  alias Kati.Backup.Bundle
  alias Kati.Backup.Catalog
  alias Kati.Backup.Error
  alias Kati.Backup.Export
  alias Kati.Backup.Manifest

  @modes [:into_empty, :merge, :replace]

  @doc """
  Write a verified bundle.

  Options:

    * `:mode` — `:into_empty` (default), `:merge` or `:replace`.
    * `:safety_sink` — required by `:replace`. A one-argument function given
      the `%Kati.Backup.Bundle{}` of the **current** state, before anything is
      deleted; it must return `{:ok, term}` for the restore to continue, and
      whatever it returns is handed back in the report so a screen can tell the
      user where their old data went.
    * `:on_progress` — called with `{table, index, total}` once per table.
      Never per row: there is no BEAM-side diff, and a callback that redraws on
      every record would spend the restore re-serialising the screen tree.
  """
  @spec apply(Bundle.t(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def apply(bundle, opts \\ [])

  def apply(%Bundle{rows: rows} = bundle, opts) when is_map(rows) do
    mode = Keyword.get(opts, :mode, :into_empty)
    on_progress = Keyword.get(opts, :on_progress, fn _ -> :ok end)

    with :ok <- check_mode(mode),
         :ok <- check_precondition(mode, rows),
         {:ok, safety} <- safety_export(mode, opts) do
      write(bundle, mode, safety, on_progress)
    end
  end

  def apply(%Bundle{}, _opts) do
    Error.error(
      :bad_manifest,
      "This backup has not been checked yet, so Kati will not write it."
    )
  end

  defp check_mode(mode) when mode in @modes, do: :ok

  defp check_mode(mode) do
    Error.error(:bad_manifest, "#{inspect(mode)} is not a restore mode.", %{modes: @modes})
  end

  defp check_precondition(:into_empty, _rows) do
    occupied =
      Catalog.entries()
      |> Enum.map(fn entry -> {entry.table, Ash.count!(entry.resource)} end)
      |> Enum.reject(fn {_table, count} -> count == 0 end)

    if occupied == [] do
      :ok
    else
      Error.error(
        :not_empty,
        "Kati already has data on this device (" <>
          Enum.map_join(occupied, ", ", fn {table, count} -> "#{count} in #{table}" end) <>
          "). Choose whether to merge this backup into it or to replace it. " <>
          "Nothing has been changed.",
        %{occupied: Map.new(occupied)}
      )
    end
  end

  defp check_precondition(_mode, _rows), do: :ok

  defp safety_export(:replace, opts) do
    case Keyword.get(opts, :safety_sink) do
      nil ->
        Error.error(
          :safety_export_required,
          "Replacing everything means deleting what is on this device, and Kati will " <>
            "not do that without saving a copy of it first. Nothing has been changed."
        )

      sink when is_function(sink, 1) ->
        case sink.(Export.bundle()) do
          {:ok, where} ->
            {:ok, where}

          {:error, reason} ->
            Error.error(
              :safety_export_required,
              "Kati could not save a copy of your current data, so it has not deleted " <>
                "any of it. Nothing has been changed.",
              %{reason: inspect(reason)}
            )
        end
    end
  end

  defp safety_export(_mode, _opts), do: {:ok, nil}

  defp write(%Bundle{manifest: manifest, rows: rows}, mode, safety, on_progress) do
    entries = Catalog.entries()
    total = length(entries)

    result =
      Kati.Repo.transaction(fn ->
        try do
          deleted = if mode == :replace, do: wipe(entries), else: %{}

          {inserted, skipped} =
            entries
            |> Enum.with_index(1)
            |> Enum.reduce({%{}, %{}}, fn {entry, index}, {inserted, skipped} ->
              on_progress.({entry.table, index, total})
              table_rows = Map.fetch!(rows, entry.table)
              {written, passed} = insert_table(entry, table_rows, mode)

              {Map.put(inserted, entry.table, written), Map.put(skipped, entry.table, passed)}
            end)

          %{deleted: deleted, inserted: inserted, skipped: skipped}
        rescue
          exception -> Kati.Repo.rollback(write_failed(exception, __STACKTRACE__))
        end
      end)

    case result do
      {:ok, counts} ->
        {:ok, report(counts, manifest, mode, safety)}

      {:error, %Error{} = error} ->
        {:error, error}

      # Anything else the repository rolled back on its own. Still a refusal
      # with nothing written, and still a sentence rather than a crash.
      {:error, other} ->
        Error.error(
          :write_failed,
          "Kati could not write this backup, so it has put everything back the way it " <>
            "was. Nothing has been changed.",
          %{rollback: inspect(other)}
        )
    end
  end

  # Children first, so a foreign key is never left pointing at a row that has
  # already gone. This is `Catalog.entries/0` read backwards, which is the same
  # list the inserts walk forwards.
  defp wipe(entries) do
    entries
    |> Enum.reverse()
    |> Map.new(fn entry ->
      # Counted before the delete rather than read off the result: SQLite's
      # `num_rows` for a `delete` without `RETURNING` is 0, so a report built
      # from it would tell the user nothing was deleted while it deleted
      # everything.
      count = Ash.count!(entry.resource)
      Ecto.Adapters.SQL.query!(Kati.Repo, "delete from #{entry.table}", [])
      {entry.table, count}
    end)
  end

  defp insert_table(entry, rows, :merge) do
    existing =
      entry.resource
      |> Ash.Query.new()
      |> Ash.Query.select([:id])
      |> Ash.read!()
      |> MapSet.new(& &1.id)

    {fresh, already_here} = Enum.split_with(rows, &(not MapSet.member?(existing, &1.id)))
    Enum.each(fresh, &Ash.Seed.seed!(entry.resource, &1))
    {length(fresh), length(already_here)}
  end

  defp insert_table(entry, rows, _mode) do
    Enum.each(rows, &Ash.Seed.seed!(entry.resource, &1))
    {length(rows), 0}
  end

  defp write_failed(exception, stacktrace) do
    Error.new(
      :write_failed,
      "Kati could not write this backup, so it has put everything back the way it " <>
        "was. Nothing has been changed. (#{Exception.message(exception)})",
      %{exception: inspect(exception.__struct__), where: Enum.take(stacktrace, 3)}
    )
  end

  defp report(counts, manifest, mode, safety) do
    %{
      mode: mode,
      schema_version: Map.fetch!(manifest, "schema_version"),
      app_version: Map.get(manifest, "app_version", "unknown"),
      exported_at: Manifest.exported_at(manifest),
      inserted: counts.inserted,
      skipped: counts.skipped,
      deleted: counts.deleted,
      total_inserted: counts.inserted |> Map.values() |> Enum.sum(),
      total_skipped: counts.skipped |> Map.values() |> Enum.sum(),
      safety_export: safety
    }
  end
end
