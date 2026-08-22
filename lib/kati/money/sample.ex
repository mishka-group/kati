defmodule Kati.Money.Sample do
  @moduledoc """
  Screen 122, as the drawing captured it.

  The recurring half mirrors `Kati.Subscriptions.Sample` to the penny — screen
  23 and screen 122 draw the same four services, and screen 92 owns their
  prices — so a drifted figure here would be three screens disagreeing about
  one number.
  """

  @doc "The header's mono subtitle."
  @spec subtitle() :: String.t()
  def subtitle, do: "3 SERVICES · 7 EXPENSES THIS MONTH"

  @doc """
  The cream hero: what leaves the account every month, and the change.

  Three parts because the drawing bolds only the amount, and a `Text` carries
  one weight.
  """
  @spec monthly() :: map()
  def monthly do
    %{
      label: "Every month",
      total: "£46.47",
      direction: :up,
      change_lead: "Up",
      change_amount: "£4.00",
      change_rest: "since March — Orbit raised its price"
    }
  end

  @doc """
  The recurring rows, with the figure the caption calls the loudest on the page.

  Aria Audio is paused, keeps its row, and leaves the total — which is the
  behaviour the `info` line under the group states and the reason a paused
  service is not simply deleted.
  """
  @spec recurring() :: [map()]
  def recurring do
    [
      %{
        badge: "L",
        name: "Lumen+",
        line: "renews 18 Aug · 41h watched",
        price: "£8.99",
        rate: "£0.21/h",
        good?: true
      },
      %{
        badge: "O",
        name: "Orbit",
        line: "renews 24 Aug · 6h watched",
        price: "£13.99",
        rate: "£2.33/h",
        good?: false
      },
      %{
        badge: "K",
        name: "Kino",
        line: "renews 01 Sep · 19h watched",
        price: "£11.49",
        rate: "£0.60/h",
        good?: true
      },
      %{
        badge: "A",
        name: "Aria Audio",
        line: "paused until October · not in the total",
        price: "£5.00",
        rate: "—",
        good?: nil
      }
    ]
  end

  @doc "The one-off expenses, grouped by month with a total and a delta."
  @spec months() :: [map()]
  def months do
    [
      %{
        label: "August",
        total: "£61.40",
        direction: :down,
        delta: "£12.10",
        rows: [
          %{name: "Kino rental — Blue Hour", meta: "16 AUG · SCREEN", amount: "£3.49"},
          %{name: "The Salt Almanac, paperback", meta: "12 AUG · BOOKS", amount: "£9.99"},
          %{name: "Cinema — Vellum", meta: "09 AUG · SCREEN", amount: "£14.00"},
          %{name: "Weekly shop", meta: "04 AUG · MEALS", amount: "£33.92"}
        ]
      },
      %{
        label: "July",
        total: "£73.50",
        direction: nil,
        delta: nil,
        rows: [
          %{name: "Vinyl — Tidal Works", meta: "28 JUL · MUSIC", amount: "£28.00"},
          %{name: "Weekly shop", meta: "21 JUL · MEALS", amount: "£45.50"}
        ]
      }
    ]
  end

  @doc """
  The cream suggestion at the foot.

  A sentence about a specific service with a specific saving, which is the only
  kind of money advice this app gives — it comes from two figures Kati already
  has, and offers to remind rather than to act.
  """
  @spec suggestion() :: map()
  def suggestion do
    %{
      lead: "You watched",
      hours: "6 hours",
      middle: "on Orbit this month and have",
      titles: "1 title",
      tail: "left in its queue. Pausing after 24 Aug saves £13.99.",
      action: "Remind me 23 Aug"
    }
  end
end
