defmodule Kati.Health.WeightSample do
  @moduledoc """
  Screens 109, 111 and 112, as the drawings captured them.

  The two weight screens share one series, because the sheet's confirmation —
  *0.4 kg down from your last reading, three days ago* — is arithmetic over the
  same list the page charts. A second copy would let the two disagree about
  what "your last reading" was.
  """

  @doc "The four entries screen 109 lists, newest first."
  @spec entries() :: [map()]
  def entries do
    [
      %{date: "16 AUG", weight: "76.0 kg", delta: "−0.4", grams: 76_000},
      %{date: "13 AUG", weight: "76.4 kg", delta: "+0.1", grams: 76_400},
      %{date: "09 AUG", weight: "76.3 kg", delta: "−0.2", grams: 76_300},
      %{date: "06 AUG", weight: "76.5 kg", delta: "−0.6", grams: 76_500}
    ]
  end

  @doc """
  The hero: the latest reading and how far it is from where the series began.

  `DOWN FROM 78.4 ON 4 MAY` reaches back past the four entries above, which is
  the drawing's own asymmetry and is right: the list shows recent changes, the
  hero shows the whole arc.
  """
  @spec latest() :: map()
  def latest do
    %{
      label: "Latest · today",
      figure: "76.0",
      unit: "kg",
      direction: :down,
      change: "2.4 kg",
      since: "DOWN FROM 78.4 ON 4 MAY"
    }
  end

  @doc "The chart's bars, oldest first, with the two axis labels the drawing prints."
  @spec bars() :: [float()]
  def bars do
    # Read off the drawing: a slow decline with two rises in it, which is what
    # a real series looks like and what a generated one never does.
    [1.0, 0.94, 0.97, 0.88, 0.83, 0.86, 0.79, 0.74, 0.77, 0.71, 0.66, 0.69, 0.62, 0.58]
  end

  @doc "The two labels under the chart."
  @spec axis() :: {String.t(), String.t()}
  def axis, do: {"4 MAY", "TODAY"}

  @doc "Screen 111's confirmation, as drawn."
  @spec confirmation() :: map()
  def confirmation do
    %{direction: :down, lead: "0.4 kg down", tail: "from your last reading, three days ago."}
  end

  @doc "Screen 112's four doses for today, in clock order."
  @spec doses() :: [map()]
  def doses do
    [
      %{time: "08:00", name: "Levothyroxine", line: "50 mcg · before food", state: :taken},
      %{time: "13:00", name: "Vitamin D", line: "1000 IU", state: :taken},
      %{time: "14:00", name: "Iron", line: "65 mg", state: :missed},
      %{time: "21:00", name: "Magnesium", line: "200 mg · with water", state: :taken}
    ]
  end

  @doc "Screen 112's schedules, in the order the group lists them."
  @spec schedules() :: [map()]
  def schedules do
    [
      %{name: "Levothyroxine", line: "50 mcg · every morning, 08:00"},
      %{name: "Vitamin D", line: "1000 IU · daily, 13:00"},
      %{name: "Iron", line: "65 mg · Mon, Wed, Fri"},
      %{name: "Magnesium", line: "200 mg · every night, 21:00"}
    ]
  end

  @doc """
  The reminder screen 112 draws as the notification it becomes.

  Drawn on the page rather than only on the lock screen, because the three
  actions on it — Taken, Skip, Snooze — are the whole reason the reminder is
  worth arming, and a user deciding whether to turn it on needs to see them.
  """
  @spec reminder() :: map()
  def reminder do
    %{
      app: "KATI · 21:00",
      title: "Magnesium — 200 mg",
      body: "With water, before bed",
      actions: ["Taken", "Skip", "Snooze"]
    }
  end

  @doc "Screen 112's header subtitle."
  @spec doses_subtitle() :: String.t()
  def doses_subtitle, do: "SUNDAY 16 AUGUST · 4 DOSES"
end
