defmodule Kati.Money.DaySample do
  @moduledoc """
  Screen 126, as the drawing captured it.

  ## A renewal and an expense are different kinds of thing

  The board says it in one line and the whole screen follows from it: *a
  renewal is a commitment — solid card, a time, an amount you will owe. An
  expense is a fact — outlined card, no time slot, an amount already spent.*

  Both belong on the day. One tells you what is coming and the other what
  happened, and the difference is drawn rather than coloured: the same palette,
  a filled card against an outlined one. Inventing a colour for *past* would
  have meant a fifth lane hue on a screen that already has four.
  """

  @doc "The day's header line and its mono subtitle."
  @spec day() :: map()
  def day, do: %{title: "Mon 24 Aug", subtitle: "3 RENEWALS · 5 OTHER ITEMS"}

  @doc "The filter chips, with the counts the drawing prints."
  @spec chips() :: [{String.t(), String.t() | nil}]
  def chips, do: [{"All", nil}, {"Money", "3"}, {"Screen", "2"}, {"Personal", "3"}]

  @doc """
  The rows, in the order the spine draws them.

  Four kinds: an all-day renewal with no set time, a merged group of three, a
  single renewal, and a past expense. Each is the drawing's own.
  """
  @spec rows() :: [map()]
  def rows do
    [
      %{
        kind: :renewal,
        time: "ALL DAY",
        all_day?: true,
        title: "Kino annual renews",
        meta: "NO SET TIME · £89.00",
        amount: nil
      },
      %{
        kind: :merged,
        time: "18:00",
        all_day?: false,
        title: "3 renewals",
        meta: "LUMEN+, ORBIT, ARIA",
        amount: "£27.98",
        members: [
          %{badge: "L", name: "Lumen+", amount: "£8.99"},
          %{badge: "O", name: "Orbit", amount: "£13.99"},
          %{badge: "A", name: "Aria Audio", amount: "£5.00"}
        ]
      },
      %{
        kind: :renewal,
        time: "09:00",
        all_day?: false,
        title: "Kino renews",
        meta: nil,
        amount: "£11.49"
      },
      %{
        kind: :expense,
        time: "—",
        all_day?: false,
        title: "Bought The Salt Almanac",
        meta: "RECORDED, NOT SCHEDULED",
        amount: "£9.99"
      }
    ]
  end

  @doc """
  The sentence that says why money merges at three.

  Screen 09 merges at two and is the exception; meals on 52 and episodes merge
  at three. The board moves money to three so the app has one density rule
  rather than two, and says which one lost.
  """
  @spec merge_note() :: String.t()
  def merge_note do
    "09 merges at two; money merges at three, matching meals on 52 and episodes on 09. " <>
      "Two renewals stay two rows."
  end

  @doc "The sentence that distinguishes a commitment from a fact."
  @spec kinds_note() :: String.t()
  def kinds_note do
    "A renewal is a commitment: solid card, a time, an amount you will owe. An expense is a " <>
      "fact: outlined card, no time slot, an amount already spent. Both belong on the day — " <>
      "one tells you what is coming, the other what happened."
  end

  @doc "How many items on one day collapse into a summary row."
  @spec merge_threshold() :: pos_integer()
  def merge_threshold, do: 3
end
