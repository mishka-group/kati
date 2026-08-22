defmodule Kati.Meals.SampleLibrary do
  @moduledoc """
  Screens 116, 118 and 119, as the drawings captured them.

  Six meals, two of them without a photo, because the grid's whole argument is
  that the no-photo tile is the same size as the others — *so the grid never
  goes ragged*. A fixture where every meal had a picture could not show that.

  One meal is `approximate?`. That is the other thing these screens exist to
  say: a total built from partial ingredient data is marked everywhere it
  appears, because *a total built from partial data that pretends to be exact
  makes every number downstream a lie.*
  """

  @doc "The six meals screen 116's grid draws, in order."
  @spec meals() :: [map()]
  def meals do
    [
      %{
        title: "Miso salmon, greens & rice",
        kcal: "620 kcal",
        slot: "Dinner",
        seed: "meal-miso",
        approximate?: false
      },
      %{
        title: "Chicken, quinoa, slaw",
        kcal: "540 kcal",
        slot: "Lunch",
        seed: nil,
        approximate?: false
      },
      %{
        title: "Overnight oats, berries",
        kcal: "410 kcal",
        slot: "Breakfast",
        seed: "meal-oats",
        approximate?: false
      },
      %{title: "Leftover dal", kcal: "~380 kcal", slot: "Dinner", seed: nil, approximate?: true},
      %{
        title: "Apple, almond butter",
        kcal: "210 kcal",
        slot: "Snack",
        seed: "meal-apple",
        approximate?: false
      },
      %{
        title: "Eggs, sourdough, avocado",
        kcal: "520 kcal",
        slot: "Brunch",
        seed: "meal-eggs",
        approximate?: false
      }
    ]
  end

  @doc "The header's mono subtitle."
  @spec subtitle() :: String.t()
  def subtitle, do: "24 MEALS · 6 WITHOUT A PHOTO"

  @doc """
  The filter chips, with the counts the drawing prints.

  The counts are the library's, not the grid's — 24 meals behind six tiles, the
  same asymmetry `Kati.Books.Sample` records for the shelf. A count computed
  from the six drawn would quietly turn 24 into 6.
  """
  @spec chips() :: [{String.t(), String.t()}]
  def chips do
    [{"All", "24"}, {"Breakfast", "5"}, {"Lunch", "7"}, {"Dinner", "9"}, {"Snack", "3"}]
  end

  @doc "Screen 118's meal, as drawn — the approximate one."
  @spec meal() :: map()
  def meal do
    %{
      title: "Leftover dal",
      slot: "Dinner",
      seed: nil,
      approximate?: true,
      kcal: "~380",
      portion: "1.0×",
      minutes: "25 min",
      heat: "Hob",
      serves: "Serves 2",
      method:
        "Sweat the onion, add the lentils and coconut milk, simmer twenty minutes. " <>
          "Spinach in at the end."
    }
  end

  @doc """
  The six macro rows screen 118 prints, two of them unknown.

  An em dash rather than a zero, for the reason the whole screen is about: a
  meal with no sodium figure has not got zero sodium.
  """
  @spec macros() :: [{String.t(), String.t()}]
  def macros do
    [
      {"Protein", "18 g"},
      {"Carbs", "52 g"},
      {"Fat", "11 g"},
      {"Fibre", "9 g"},
      {"Sugar", "—"},
      {"Sodium", "—"}
    ]
  end

  @doc """
  The five ingredients, in the three states the drawing marks by glyph.

  Marked by a **leading glyph** rather than colour alone — green check for
  auto-filled, bronze query for quantity-only, ink pencil for free text —
  which is the caption's own instruction and is the reason the states survive
  a colour-blind reader and a greyscale screenshot.
  """
  @spec ingredients() :: [map()]
  def ingredients do
    [
      %{
        name: "Red lentils, dry",
        meta: "CUPBOARD · NUTRITION KNOWN",
        amount: "180 g",
        state: :known
      },
      %{
        name: "Coconut milk",
        meta: "CUPBOARD · NUTRITION KNOWN",
        amount: "400 ml",
        state: :known
      },
      %{
        name: "Spinach",
        meta: "PRODUCE · QUANTITY ONLY",
        amount: "2 handfuls",
        state: :quantity_only
      },
      %{
        name: "Curry leaves",
        meta: "UNCATEGORISED · FREE TEXT",
        amount: "a few",
        state: :free_text
      },
      # The fifth. The drawing's eyebrow says `Ingredients · 5` and its list has
      # room for four, so the onion the method names is the one that did not
      # fit — the same asymmetry `Kati.Music.Sample.tracks/0` records for a
      # tracklist, and resolved the same way: the fixture holds all of them.
      %{name: "Onion", meta: "PRODUCE · NUTRITION KNOWN", amount: "1 piece", state: :known}
    ]
  end

  @doc "Screen 119's draft ingredient, as drawn."
  @spec draft() :: map()
  def draft do
    %{
      name: "Curry leaves",
      quantity: "a few",
      unit: "free",
      aisle: "Uncategorised",
      meta: "UNCATEGORISED · FREE TEXT",
      state: :free_text
    }
  end

  @doc "The aisles screen 119 offers, in the drawing's order."
  @spec aisles() :: [String.t()]
  def aisles, do: ["Produce", "Cupboard", "Fish & meat", "Dairy", "Uncategorised"]

  @doc """
  The two nutrition paths that are drawn and not built.

  Both carry the same `NOT IN V1` badge the retired Health tiles use, so
  *designed, not built* means one thing app-wide rather than a different visual
  in every corner. The reasons are real and are printed: a barcode needs a food
  database Kati has not chosen, and a search needs a licence, a coverage
  guarantee and a rate limit that are all unresolved.
  """
  @spec nutrition_paths() :: [map()]
  def nutrition_paths do
    [
      %{icon: "edit", title: "Type it in", sub: "kcal and macros, by hand", built?: true},
      %{
        icon: "qr_code_scanner",
        title: "Scan a barcode",
        sub: "Needs a food database Kati has not chosen",
        built?: false
      },
      %{
        icon: "search",
        title: "Search a food database",
        sub: "Licence, coverage and rate limits unresolved",
        built?: false
      }
    ]
  end
end
