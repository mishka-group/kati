defmodule Kati.Meals.Aisle do
  @moduledoc """
  The shelf taxonomy, owned by Kati.

  Fourteen values, fixed, and **not** taken from a food database: no food
  database agrees on a shelf taxonomy, so borrowing one means the shopping list
  regroups itself whenever the upstream vocabulary drifts. It is not free text
  either — screen 48 groups by aisle and that grouping has to be stable across
  every item on the list, including the ones a user typed by hand.

  `:other` exists so an aisle is always answerable. A nullable aisle would put
  the "no aisle yet" case into every grouping query instead of into one bucket.

  The three the design actually draws — `Produce`, `Fish & meat`, `Cupboard` —
  keep their exact wording in `label/1`, because screen 48's copy is the
  reference and "Fish and meat" is a different string.
  """

  @values [
    :produce,
    :bakery,
    :fish_and_meat,
    :dairy_and_eggs,
    :chilled,
    :frozen,
    :cupboard,
    :grains_and_pasta,
    :tins_and_jars,
    :herbs_and_spices,
    :drinks,
    :snacks,
    :household,
    :other
  ]

  @labels %{
    produce: "Produce",
    bakery: "Bakery",
    fish_and_meat: "Fish & meat",
    dairy_and_eggs: "Dairy & eggs",
    chilled: "Chilled",
    frozen: "Frozen",
    cupboard: "Cupboard",
    grains_and_pasta: "Grains & pasta",
    tins_and_jars: "Tins & jars",
    herbs_and_spices: "Herbs & spices",
    drinks: "Drinks",
    snacks: "Snacks",
    household: "Household",
    other: "Other"
  }

  @doc """
  Every aisle, in shopping order — the order a supermarket is walked, not
  alphabetical, so a list grouped by aisle reads as a route.
  """
  @spec values() :: [atom()]
  def values, do: @values

  @doc "How many aisles there are. Fixed at 14; a test holds it there."
  @spec count() :: pos_integer()
  def count, do: length(@values)

  @doc "The label screen 48 prints over a group."
  @spec label(atom()) :: String.t()
  def label(aisle) when is_map_key(@labels, aisle), do: Map.fetch!(@labels, aisle)
end
