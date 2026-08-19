defmodule Kati.Activity.Sample do
  @moduledoc """
  Stand-in activity history, until the Screen domain keeps a real one.

  Screen 15 is the app's append-only log — *"every tick, rating, drop and
  import"* — and it is also the undo trail, so the shape here is the shape a
  real entry has to have: **when** it happened, **what** it happened to, and a
  verb that names the change. Nothing else.

  The verb is stored apart from the rest of the line (`lead` / `rest`) because
  the drawing sets it in bold ink against `#5C574F` body text, and Mob's `Text`
  carries one weight. Two runs in a `Row`, not one string with markup.

  `stars` is present on exactly one row, which is the design's own doing: a
  rating entry shows the rating it recorded. Rows without it simply do not
  carry the key.
  """

  @doc "The mono line under the title."
  @spec entries_line() :: String.t()
  def entries_line, do: "1,204 entries"

  @doc "The filter chips, the first one selected."
  @spec filters() :: [String.t()]
  def filters, do: ["All", "Watched", "Rated", "Added"]

  @doc """
  Today's entries, newest first, stamped with a clock.
  """
  @spec today() :: [map()]
  def today do
    [
      %{stamp: "21:12", seed: "hollow71", lead: "Watched", rest: "The Long Hollow S2E5"},
      %{stamp: "20:40", seed: "bluehour58", lead: "Rated", rest: "Blue Hour", stars: 4},
      %{stamp: "18:03", seed: "vellum97", lead: "Added", rest: "Vellum to Wishlist"}
    ]
  end

  @doc """
  Earlier this month, stamped with a date instead of a clock.

  Same row, different gutter: once a day has passed the time stops carrying
  information and the date starts to.
  """
  @spec earlier() :: [map()]
  def earlier do
    [
      %{
        stamp: "12 AUG",
        seed: "nightbirds24",
        lead: "Rewatched",
        rest: "Nightbirds S1E1 · 3rd time"
      },
      %{stamp: "10 AUG", seed: "nightbirds24", lead: "Finished", rest: "Nightbirds — Season 1"},
      %{stamp: "07 AUG", seed: "quietones12", lead: "Dropped", rest: "The Quiet Ones after S1E3"},
      %{stamp: "02 AUG", seed: "cartog60", lead: "Imported", rest: "412 titles from a CSV backup"}
    ]
  end

  @doc "What has been watched more than once, and how many times."
  @spec rewatch() :: [{String.t(), String.t()}]
  def rewatch do
    [
      {"Nightbirds S1E1", "3×"},
      {"Blue Hour", "2×"},
      {"The Cartographer S1", "2×"}
    ]
  end
end
