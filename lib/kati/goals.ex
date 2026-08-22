defmodule Kati.Goals do
  @moduledoc """
  A number you meant to reach by a date, and how far along you are.

  ## What a goal is not

  Screen 104's own footer draws the line and it is the sharpest sentence on the
  page: *"Read every day" is a habit. "Read 52 books" is a goal.* A habit is a
  streak — `Kati.Habits.Sample` and screen 22 — and a goal is a **quantity
  against a deadline**. Two different shapes with two different failure modes:
  you break a habit, and you fall behind a goal.

  ## The projection states where you land, never how you feel about it

  *On pace to finish 106 of 120*, not *you're falling behind*. The design's
  caption calls this the point of the screen, and `project/3` is where it is
  kept honest: it extrapolates the rate so far across the whole period and says
  the number. Nothing here computes an adjective.

  ## Ten kinds, and each says what counts

  Screen 104 puts a footnote on every card — *counts finished books only. A
  book you did not finish counts its pages toward the pages goal, not this
  one.* That is the D-14 question made visible rather than deferred, so
  `Kati.Goals.Goal.counts/1` carries the sentence beside the kind rather than
  leaving it to a screen to remember.
  """

  use Ash.Domain, validate_config_inclusion?: false

  resources do
    resource Kati.Goals.Goal
  end
end
