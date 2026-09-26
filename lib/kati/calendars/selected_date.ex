defmodule Kati.Calendars.SelectedDate do
  @moduledoc """
  The day the reader has selected in the calendar, shared by every view of it.

  Screen 02 (Schedule), 16 (Month), 17 (Week), 30 (Agenda) and 09 (Day) are
  five drawings of one question — *what is on this day* — and a person moving
  between them expects the day to come with them. It could not ride on a push:
  02, 16, 17 and 30 are roots, and `Kati.Screens.Root.mount/3` discards push
  params outright, so a date picked on the month grid never reached the
  Schedule and the Schedule opened on today whatever the reader had chosen.

  So the date lives here, outside every screen process. A view writes it when
  the reader picks a day (`put/1`), reads it in `load/1` and again on
  `:resumed` (`get/0`), and the Schedule's *Today* pill clears it (`reset/0`).

  ## Kept for one launch, not for ever

  `Mob.State` is where Kati keeps UI state that must outlive a screen —
  `Kati.Discover.Filters` and `Kati.Library.ShelfFilters` live there — but it
  is DETS-backed and survives a restart. A calendar that reopened next week on
  a Tuesday someone looked at last month would be a stale answer to *what is on
  today*. So the stored value carries the launch it was written in, and a
  value from another launch reads as today. `launch/0` is that token: the OS
  process id and the instant the VM started, both of which a new launch
  changes and nothing inside one does, so it needs no process and no write.

  Every reader answers today when `Mob.State` cannot be reached, which is the
  answer the calendar gave before this module existed.
  """

  @key "calendar:selected_date"

  @doc "The selected day: the one stored this launch, or today."
  @spec get() :: Date.t()
  def get do
    stored(Mob.State.get(@key), launch())
  rescue
    _error -> Kati.Time.today()
  catch
    :exit, _reason -> Kati.Time.today()
  end

  @doc """
  What a stored value means under a launch token.

      iex> Kati.Calendars.SelectedDate.stored({:a, ~D[2026-03-01]}, :a)
      ~D[2026-03-01]

      iex> Kati.Calendars.SelectedDate.stored({:a, ~D[2026-03-01]}, :b) == Kati.Time.today()
      true
  """
  @spec stored(term(), term()) :: Date.t()
  def stored({launch, %Date{} = date}, launch), do: date
  def stored(_other, _launch), do: Kati.Time.today()

  @doc "Select `date`. Answers it back, so a caller can pipe."
  @spec put(Date.t()) :: Date.t()
  def put(%Date{} = date) do
    Mob.State.put(@key, {launch(), date})
    date
  rescue
    _error -> date
  catch
    :exit, _reason -> date
  end

  @doc "Forget the selection, which is what *Today* does. Answers today."
  @spec reset() :: Date.t()
  def reset do
    Mob.State.delete(@key)
    Kati.Time.today()
  rescue
    _error -> Kati.Time.today()
  catch
    :exit, _reason -> Kati.Time.today()
  end

  @doc false
  @spec launch() :: term()
  def launch, do: {System.pid(), :erlang.system_info(:start_time)}
end
