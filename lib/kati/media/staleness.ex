defmodule Kati.Media.Staleness do
  @moduledoc """
  Gone cold — the one status Kati infers rather than being told.

  ## The gap this closes

  Board 148 draws five states and says `Kati.Media.TrackedTitle.status` holds
  `:active | :paused | :gone_cold | :dropped | :finished`. The resource holds
  `:not_started | :watching | :paused | :finished | :dropped` — no
  `:gone_cold`, and nothing anywhere in the app ever wrote `:paused` either
  (MOVIES-AND-TV.md #55 and #56). So both screens that draw a Gone cold band —
  148 and screen 10 — read `status == :paused`, a value with no writer, and
  drew nothing on every device that has ever existed.

  The board is right and the workaround was wrong. Its own footnote says which:

  > Paused and Dropped are things a person decided. **Gone cold is something
  > Kati noticed.**

  A thing Kati noticed is not a stored status. It is a question asked of the
  row every time it is drawn — which is why no migration is needed and why one
  would have been the wrong answer: a stored `:gone_cold` would have to be
  written by a job, unwritten the moment the reader watched something, and
  would disagree with the shelf for as long as that job had not run.

  ## What "cold" means, and where the number comes from

  Board 148's own Show row: **No activity for 4 months**. Not a number this
  module invented — `Kati.Settings.DropStatesSample.gone_cold/0` is the
  drawing's copy, and the three media it lists have three different thresholds
  because a book and an album are not watched weekly.

  `last_touched_at` is what it is measured on. `Kati.Media.TrackedTitle` keeps
  that column for exactly this kind of question, and it is what the `:shelf`
  read already sorts by.

  Only a `:watching` title can go cold. One that is `:finished`, `:dropped` or
  `:not_started` is in a state the reader chose, and Kati has nothing to notice
  about it.
  """

  alias Kati.Media.TrackedTitle

  # Four months for a show, which is board 148's own Show row. Books and albums
  # have their own thresholds on that board — six weeks and three months — and
  # this module answers for `Kati.Media` only.
  @cold_after_days 120

  @doc """
  The threshold, in days, so a test can sit either side of it rather than
  sleeping.

      iex> Kati.Media.Staleness.cold_after_days()
      120
  """
  @spec cold_after_days() :: pos_integer()
  def cold_after_days, do: @cold_after_days

  @doc """
  Whether Kati would say this title has gone cold.

  `now` is an argument for `Kati.Calendars.Today.rows/1`'s reason: a function
  that reads the clock itself can only be tested on the day it was written.
  """
  @spec gone_cold?(TrackedTitle.t(), DateTime.t()) :: boolean()
  def gone_cold?(tracked, now \\ nil)

  def gone_cold?(%TrackedTitle{status: :watching, last_touched_at: %DateTime{} = at}, now) do
    DateTime.diff(now || Kati.Time.now(), at, :day) >= @cold_after_days
  end

  def gone_cold?(_other, _now), do: false

  @doc "The cold ones, out of a list of tracked rows."
  @spec cold([TrackedTitle.t()], DateTime.t() | nil) :: [TrackedTitle.t()]
  def cold(tracked, now \\ nil), do: Enum.filter(tracked, &gone_cold?(&1, now))

  @doc """
  The warm ones — everything `cold/2` leaves.

  Both halves, because a screen that drew the cold list from one predicate and
  the ready list from a different one would eventually draw a title twice or
  not at all.
  """
  @spec warm([TrackedTitle.t()], DateTime.t() | nil) :: [TrackedTitle.t()]
  def warm(tracked, now \\ nil), do: Enum.reject(tracked, &gone_cold?(&1, now))
end
