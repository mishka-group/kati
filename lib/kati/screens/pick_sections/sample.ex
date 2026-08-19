defmodule Kati.Screens.PickSections.Sample do
  @moduledoc """
  The six sections screen 26 offers, and the two it starts with chosen.

  This is not stand-in data in the way `Kati.Library.Sample` is — the list of
  sections is the app's own shape rather than a database row — but it lives
  here for the same reason: when a real `Kati.Sections` domain exists, the
  screen should read the same list of maps from it and nothing in
  `Kati.Screens.PickSections` should have to change.

  Order matters. The drawing puts Screen and Books first and pre-selects them,
  which is what makes the heading's *Pick two to start* true on arrival rather
  than an instruction the user has to obey before the button lights up.
  """

  @sections [
    %{id: "screen", icon: "movie", label: "Screen", sub: "Films & TV"},
    %{id: "books", icon: "menu_book", label: "Books", sub: "Reading"},
    %{id: "music", icon: "graphic_eq", label: "Music", sub: "Listening"},
    %{id: "habits", icon: "bolt", label: "Habits", sub: "Streaks"},
    %{id: "money", icon: "payments", label: "Money", sub: "Subscriptions"},
    %{id: "notes", icon: "edit_note", label: "Notes", sub: "Journal"}
  ]

  @doc "Every section Kati can keep, in the order the grid draws them."
  @spec sections() :: [map()]
  def sections, do: @sections

  @doc "The two the drawing arrives with already chosen."
  @spec chosen() :: MapSet.t()
  def chosen, do: MapSet.new(["screen", "books"])

  @doc """
  Onboarding progress: four steps, two done.

  Drawn as four equal bars rather than a percentage, because the design is
  promising *four steps* and a bar that only moves cannot promise a length.
  """
  @spec steps() :: {pos_integer(), pos_integer()}
  def steps, do: {4, 2}

  @doc "The heading, kept as the two lines the drawing's `<br>` makes of it."
  @spec heading() :: [String.t()]
  def heading, do: ["What should", "Kati keep?"]

  @doc "The line under the heading."
  @spec blurb() :: String.t()
  def blurb do
    "Pick two to start. You can add the rest whenever — every section drops " <>
      "into the same calendar and the same home page."
  end
end
