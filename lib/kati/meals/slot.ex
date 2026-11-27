defmodule Kati.Meals.Slot do
  @moduledoc """
  The word a meal's slot is drawn with, in the reader's own script.

  `Kati.Meals.MealLog.slot_name` and `Kati.Meals.Recipe.slot_name` are free
  strings stored in English — `Breakfast`, `Lunch`, `Dinner`, `Snack` — because
  they are an enum the screens compare, not a sentence anyone reads. The moment
  one is drawn it has to become a word: a Persian day showed `LUNCH` over the
  row it had just logged.

  The four known slots are translated; anything else answers the word it was
  given, which is `Kati.Meals.Recipe`'s own promise that somebody who eats
  second breakfast can say so.
  """

  use Gettext, backend: Kati.Gettext

  @doc """
  A slot as a person reads it.

      iex> Kati.Meals.Slot.label("Lunch")
      "Lunch"

      iex> Kati.Meals.Slot.label("lunch")
      "Lunch"

      iex> Kati.Meals.Slot.label(nil)
      ""

      iex> Kati.Meals.Slot.label("Second breakfast")
      "Second breakfast"
  """
  @spec label(String.t() | nil) :: String.t()
  def label(nil), do: ""
  def label(""), do: ""

  def label(slot) when is_binary(slot) do
    case canon(slot) do
      "Breakfast" -> gettext("Breakfast")
      "Lunch" -> gettext("Lunch")
      "Dinner" -> gettext("Dinner")
      "Snack" -> gettext("Snack")
      # A word somebody typed themselves is already theirs to read.
      _other -> slot
    end
  end

  # Rows written before the vocabulary settled stored the lowercase key
  # (`lunch`); the screens' own writes store `Lunch`. Both draw the same word.
  defp canon(slot), do: slot |> String.trim() |> String.capitalize()
end
