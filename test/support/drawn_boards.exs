defmodule Kati.Test.DrawnBoards do
  @moduledoc """
  Boards 03, 05 and 92 as TEST fixtures: the state each drawing was captured
  in, for the tests that compare a screen against its own board.

  They lived on the screens as `Kati.Screens.Library.drawn_titles/0`,
  `Kati.Screens.Inbox.drawn_inbox/0` and `Kati.Screens.MyServices.drawn_page/0`.
  No reader could reach any of them, and a fixture belongs under
  `test/support/`, never in a screen that ships — `Kati.Test.HeavyDay`'s
  reason.
  """

  @doc """
  The nine titles board 03 draws, each with the `status` a real row carries.

  The drawn rows predate `Kati.Media.TrackedTitle` and carry a fraction where
  a real row carries a status: 0 is not started, 1 is finished, anything
  between is watching.
  """
  @spec library_titles() :: [map()]
  def library_titles, do: Enum.map(Kati.Library.Sample.titles(), &with_status/1)

  defp with_status(%{progress: progress} = row) do
    status =
      cond do
        progress <= 0.0 -> :not_started
        progress >= 1.0 -> :finished
        true -> :watching
      end

    Map.put(row, :status, status)
  end

  @doc "Board 05 exactly as it is drawn."
  @spec inbox() :: map()
  def inbox do
    Map.merge(Kati.Library.Sample.inbox(), %{
      coming_up: inbox_coming_up(),
      last_checked: Kati.Screens.Inbox.watcher_line()
    })
  end

  @doc "The three dated rows board 05 puts in its Coming up card."
  @spec inbox_coming_up() :: [map()]
  def inbox_coming_up do
    [
      %{
        month: "AUG",
        day: "20",
        title: "The Long Hollow — S2E6",
        line: "Lumen+ · 20:00",
        armed: true
      },
      %{month: "SEP", day: "04", title: "Vellum", line: "In cinemas", armed: false},
      %{
        month: "SEP",
        day: "12",
        title: "Nightbirds — Season 2",
        line: "Full season drop",
        armed: false
      }
    ]
  end

  @doc "Board 92's own arrival: the drawing's services, on a page that is set up."
  @spec services_page() :: map()
  def services_page, do: %{Kati.Screens.MyServices.drawn() | set_up?: true}
end
