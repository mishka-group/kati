defmodule Kati.Media.Log do
  @moduledoc """
  The one place anything writes to `Kati.Media.Event`.

  Five screens make events — the drop sheet, both add screens, the importer,
  and the film menu — and each of them has its own reason for being interrupted
  mid-write. So the write is here, it rescues, and it returns `:ok` whatever
  happens: a title that got added is added, and an activity log that failed to
  record it is a smaller loss than an add screen that raises over one.

  That is the same call `Kati.Media.Watch`'s own writers make and the opposite
  of `Kati.Import.Commit`'s, and the difference is which one the reader asked
  for. Nobody presses **Drop this show** to make a log entry.
  """

  @doc """
  Record what happened to one title.

  `nil` for the title is the drawn-board case every screen that calls this has
  — 149, 15 and 08 all render against fixtures when nothing is behind them —
  and it writes nothing rather than a row about a drawing.

  ## Examples

      iex> Kati.Media.Log.write(nil, :dropped, %{})
      :ok
  """
  @spec write(term(), atom(), map()) :: :ok
  def write(nil, _kind, _attrs), do: :ok

  def write(tracked, kind, attrs) do
    Ash.create!(
      Kati.Media.Event,
      attrs
      |> Map.put(:tracked_title_id, tracked.id)
      |> Map.put(:kind, kind)
      |> Map.put(:at, Kati.Time.now())
      |> Map.put_new(:from_status, Map.get(tracked, :status))
    )

    :ok
  rescue
    _error -> :ok
  end

  @doc """
  Record an import, which is the one event with no single title behind it.

  Screen 15 draws it as a row all the same — *Imported 412 titles from a CSV
  backup* is the sample's own line — so `tracked_title_id` is nullable and this
  is the caller that leaves it nil.
  """
  @spec imported(non_neg_integer(), String.t() | nil) :: :ok
  def imported(0, _source), do: :ok

  def imported(count, source) do
    Ash.create!(Kati.Media.Event, %{
      kind: :imported,
      at: Kati.Time.now(),
      count: count,
      source_label: source
    })

    :ok
  rescue
    _error -> :ok
  end
end
