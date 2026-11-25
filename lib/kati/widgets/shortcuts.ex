defmodule Kati.Widgets.Shortcuts do
  @moduledoc """
  The three voice-shortcut switches, stored where the other device choices are.

  Screen 39's switches flipped a row on an assign and nothing else: leave the
  page and every switch returned to on. A switch that does not survive its own
  screen is a picture of a switch, which is the defect this closes.

  The value is per shortcut, keyed by its **position**, not by its spoken
  phrase — the phrase is copy and is quoted typographically, and a catalogue
  edit that moved a comma would silently reset a switch. Position is stable
  because the list is `Kati.Widgets.Sample.shortcuts/0`'s own order.

  `Mob.State` rather than a table, for `Kati.Sections`'s reason: it is a
  preference about this device, one value, readable before the repo is up.
  """

  @key :kati_widget_shortcuts

  @doc "The stored map of index => boolean, or an empty map."
  @spec stored() :: %{integer() => boolean()}
  def stored do
    case Mob.State.get(@key) do
      map when is_map(map) -> map
      _unset -> %{}
    end
  rescue
    _error -> %{}
  end

  @doc """
  Apply what is stored to the drawn rows.

  A row with no stored answer keeps the drawing's own position — the design's
  three switches are on, and a fresh install shows what the board shows.
  """
  @spec apply([map()]) :: [map()]
  def apply(rows) do
    stored = stored()

    rows
    |> Enum.with_index()
    |> Enum.map(fn {row, index} ->
      case Map.fetch(stored, index) do
        {:ok, on?} when is_boolean(on?) -> %{row | toggle: on?}
        _nothing_stored -> row
      end
    end)
  end

  @doc "Flip one row and remember it. Answers the updated rows."
  @spec toggle([map()], non_neg_integer()) :: [map()]
  def toggle(rows, index) do
    rows =
      List.update_at(rows, index, fn row -> %{row | toggle: not Map.get(row, :toggle, false)} end)

    case Enum.at(rows, index) do
      %{toggle: on?} ->
        Mob.State.put(@key, Map.put(stored(), index, on?))
        rows

      nil ->
        rows
    end
  rescue
    _error -> rows
  end

  @doc "Forget every stored switch, so the drawing answers again. For tests."
  @spec forget!() :: :ok
  def forget! do
    Mob.State.delete(@key)
    :ok
  rescue
    _error -> :ok
  end
end
