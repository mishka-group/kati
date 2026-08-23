defmodule Kati.Stats.ShareSample do
  @moduledoc """
  Screens 98 and 100, as the drawings captured them.

  Screen 100 is the **render spec**: four faces at both ratios on one board, so
  the generator has nothing to infer. That is why the faces live here as data
  rather than in the screen — the same four are drawn twice at two sizes, and a
  second copy would let 4:5 and 9:16 drift apart.
  """

  @doc "The four card faces, in the order both ratios stack them."
  @spec faces() :: [atom()]
  def faces, do: [:hours, :top_titles, :where_hours_went, :field]

  @doc "The header's mono subtitle on screen 98."
  @spec subtitle() :: String.t()
  def subtitle, do: "JAN – AUG 2026"

  @doc "The scope chips: which part of the year a card is about."
  @spec scopes() :: [String.t()]
  def scopes, do: ~w(All Screen Books Music Meals Habits)

  @doc "The hours face: the figure, the change, and the year it is about."
  @spec hours() :: map()
  def hours do
    %{label: "Time watched", figure: "312h 40m", direction: :up, change: "18%", year: "2026"}
  end

  @doc "The three titles, with the seeds the export used."
  @spec top_titles() :: [map()]
  def top_titles do
    [
      %{rank: "1", title: "The Long Hollow", seed: "hollow71"},
      %{rank: "2", title: "Blue Hour", seed: "bluehour22"},
      %{rank: "3", title: "The Cartographer", seed: "cartog60"}
    ]
  end

  @doc """
  Where the hours went, as bars.

  A four-tone ink ramp rather than a hue per genre: a saved image has no legend
  beside it, and four colours that mean four genres would need one.
  """
  @spec where_hours_went() :: [{String.t(), integer()}]
  def where_hours_went do
    [{"Drama", 104}, {"Thriller", 71}, {"Documentary", 49}, {"Comedy", 31}]
  end

  @doc "The field face's three lines, and the one wordmark on any card."
  @spec field_face() :: map()
  def field_face do
    %{year: "2026", title: "Your year", span: "26 WEEKS", wordmark: "Kati"}
  end

  @doc """
  The palette sentence screen 100 prints, and the rule inside it.

  `No orange on any card` is the rule, and the reason is one line: *a saved
  image has no "now" to point at.* Orange means new/now everywhere else in this
  app, and an image that outlives the day it was made cannot mean now.
  """
  @spec palette_note() :: String.t()
  def palette_note,
    do:
      "Paper #EFECE7, card #FBFAF8, ink #1A1917, bronze ramp for the field, " <>
        "four-tone ink ramp for the bars. No orange on any card — a saved image has no " <>
        "“now” to point at."
end
