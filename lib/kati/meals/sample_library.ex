defmodule Kati.Meals.SampleLibrary do
  use Gettext, backend: Kati.Gettext

  @moduledoc """
  Screens 116, 118 and 119, as the drawings captured them.

  Six meals, two of them without a photo, because the grid's whole argument is
  that the no-photo tile is the same size as the others — *so the grid never
  goes ragged*. A fixture where every meal had a picture could not show that.

  One meal is `approximate?`. That is the other thing these screens exist to
  say: a total built from partial ingredient data is marked everywhere it
  appears, because *a total built from partial data that pretends to be exact
  makes every number downstream a lie.*

  ## What translates here, and what must not

  mishka-group/kati#103. `Kati.Screens.MealLibrary`'s moduledoc names this file
  as the thing that screen cannot reach — *they still render in Latin under
  `:fa`, and they translate where they live* — and this is where they live. So
  every word a reader sees now goes through `Kati.Gettext` and every figure
  through `Kati.Locale.number/1`.

  Three things below are **not** copy, and translating them would break a
  control rather than merely read oddly:

    * **`meals/0`'s `:slot` and `chips/0`'s keys.** One vocabulary, English in
      every locale. `Kati.Screens.MealLibrary.grid/3` tests `meal.slot ==
      filter`, `chips/2` builds `:filter_Dinner` out of the key, `handle_tap/2`
      takes the word back off the tag, and `Kati.Screens.MealEdit.save_slot/2`
      writes it to the database. `slot_label/1` is where it becomes a word, at
      the two places it is drawn. A Persian `شام` here is a grid that answers
      *no meals* to every filter and a recipe row whose slot no English reader
      can select.
    * **`aisles/0` and the four stored keys of `draft/0`.**
      `Kati.Screens.AddIngredient`'s moduledoc spends a section on this: that
      sheet's `aisle_value/1`, `unit_value/1` and `amount_mg/1` all match the
      fixture's English tokens, and a chip tagged `دسته‌بندی‌نشده` files *every*
      ingredient under `:other`, silently, in one script only. The sheet
      translates them at the render sites — `aisle_label/1`, `unit_label/1`,
      `quantity_label/1`, `ingredient_name/1` — so this file hands it tokens.
    * **`nutrition_paths/0`'s `:title` and `:sub`.** Keyed on by
      `Kati.Screens.AddIngredient.path_title/1` and `path_sub/1`, which need a
      literal at the call site because these arrive as data.

  Everything else is drawn raw by the screen that reads it and is therefore
  this file's to translate: the meal titles, the kcal lines, the subtitle, the
  macro rows, the ingredient names, their meta lines and their amounts, and
  screen 118's three facts and method.

  ## The msgids are borrowed, never reinvented

  Where a string already has an entry the catalogue keeps it: `%{count} kcal`
  is `Kati.Screens.MealLibrary.kcal_line/2`'s, `%{n} g` and `%{n} piece` are
  `Kati.Screens.MealEdit.unit_amount/2`'s, the aisle words are
  `Kati.Screens.AddIngredient.aisle_label/1`'s, the three state words are
  `Kati.Screens.MealEdit.state_label/1`'s and `a few` is `amount_line/1`'s. A
  drawn row and the stored row it stands in for must not acquire two Persian
  words for one thing — the drawing is what the person sees first.
  """

  @doc """
  The six meals screen 116's grid draws, in order.

  ## The title is copy and the slot is not

  `Kati.Screens.MealLibrary.tile/2` draws `meal.title` raw and pushes
  `meal.slot` through `Kati.Screens.MealLibrary.slot_label/1`, which is the
  whole of the split — see the moduledoc.

  **Board 117 keys on the English title, and no longer finds it under `:fa`.**
  `Kati.Screens.MealLibraryEmpty.meals/0` filters
  `Kati.Screens.MealLibrary.drawn_meals/0` through its
  own `@titles` map, whose keys are `Miso salmon, greens & rice` and `Leftover
  dal`; on a Persian page those titles now answer Persian and the mirror panel
  draws an empty grid. That board's own moduledoc already records the panel as
  broken under `:fa` for a second reason — the hand mirror double-mirrors
  against an RTL root — and names the two honest fixes as the board's decision
  rather than the translation's. The join wants to move off the drawn title
  (the seed is the stable key) whichever fix is taken.
  """
  @spec meals() :: [map()]
  def meals do
    [
      %{
        title: gettext("Miso salmon, greens & rice"),
        kcal: kcal_line(620, false),
        slot: "Dinner",
        seed: "meal-miso",
        approximate?: false
      },
      %{
        title: gettext("Chicken, quinoa, slaw"),
        kcal: kcal_line(540, false),
        slot: "Lunch",
        seed: nil,
        approximate?: false
      },
      %{
        title: gettext("Overnight oats, berries"),
        kcal: kcal_line(410, false),
        slot: "Breakfast",
        seed: "meal-oats",
        approximate?: false
      },
      %{
        title: gettext("Leftover dal"),
        kcal: kcal_line(380, true),
        slot: "Dinner",
        seed: nil,
        approximate?: true
      },
      %{
        title: gettext("Apple, almond butter"),
        kcal: kcal_line(210, false),
        slot: "Snack",
        seed: "meal-apple",
        approximate?: false
      },
      %{
        title: gettext("Eggs, sourdough, avocado"),
        kcal: kcal_line(520, false),
        slot: "Brunch",
        seed: "meal-eggs",
        approximate?: false
      }
    ]
  end

  # A tile's calorie figure, built exactly as
  # `Kati.Screens.MealLibrary.kcal_line/2` builds a stored meal's — the same
  # msgid, the same isolate, the same digits. Two constructions of one line is
  # how the grid comes to say `۶۲۰ کالری` over a real meal and `620 kcal` over
  # the drawing's on the same page.
  #
  # The tilde goes INSIDE the interpolated value and through `Kati.Locale.ltr/1`
  # because it is bidi-NEUTRAL: a bare one in front of the number takes the
  # paragraph's direction and lands at the far end of the figure — `۳۸۰~ کالری`,
  # a mark against the word rather than against the number it qualifies. A no-op
  # under `:en`, where this still answers `~380 kcal` byte for byte.
  defp kcal_line(total_kcal, approximate?) do
    figure = Kati.Locale.number(total_kcal)

    gettext("%{count} kcal",
      count: if(approximate?, do: Kati.Locale.ltr("~" <> figure), else: figure)
    )
  end

  @doc """
  The header's mono subtitle.

  Built from `Kati.Screens.MealLibrary.subtitle/1`'s two msgids rather than
  frozen as one Latin literal, so the fixture's header and a real library's
  header are one sentence in both scripts. The two figures stay the DRAWING's —
  24 meals behind six tiles, which is the asymmetry `chips/0` records and which
  no arithmetic over six rows can reach.

  `Kati.UI.eyebrow_label/1` and not `String.upcase/1`: Arabic script has no case,
  so upcasing a Persian line is a no-op that READS as one. It goes around the
  finished line rather than inside the msgids, so `%{n} meal` stays the entry the
  rest of Meals already uses. What the drawing prints is unchanged —
  `24 MEALS · 6 WITHOUT A PHOTO`.
  """
  @spec subtitle() :: String.t()
  def subtitle do
    Kati.UI.eyebrow_label(
      ngettext("%{n} meal", "%{n} meals", 24, n: Kati.Locale.number(24)) <>
        " · " <> gettext("%{n} without a photo", n: Kati.Locale.number(6))
    )
  end

  @doc """
  The filter chips, with the counts the drawing prints.

  The counts are the library's, not the grid's — 24 meals behind six tiles, the
  same asymmetry `Kati.Books.Sample` records for the shelf. A count computed
  from the six drawn would quietly turn 24 into 6.

  **Neither half of a pair is copy, which is why nothing here is wrapped.** The
  key is compared against `meal.slot` in `Kati.Screens.MealLibrary.grid/3`,
  rebuilt out of `:filter_Dinner` in that screen's `handle_tap/2` and looked up in
  `Kati.Screens.MealLibraryEmpty`'s `@slots`; the count is a Latin-digit string
  two different screens fold for themselves — `Kati.Locale.number/1` at the chip
  on 116, `Kati.I18n.Digits.to_persian/1` on 117's specimen panel, which is
  Persian because the specimen is and not because the reader is. Folding it here
  would hand both of them a number they cannot convert back.
  """
  @spec chips() :: [{String.t(), String.t()}]
  def chips do
    [{"All", "24"}, {"Breakfast", "5"}, {"Lunch", "7"}, {"Dinner", "9"}, {"Snack", "3"}]
  end

  @doc """
  Screen 118's meal, as drawn — the approximate one.

  The three facts and the method are drawn raw by
  `Kati.Screens.MealEdit.method/1`, so they are copy and they translate. The
  slot is not: `Kati.Screens.MealEdit.load/1` puts it straight onto `:slot`, the
  chips compare themselves against it and `Kati.Screens.MealEdit.save_slot/2`
  writes it to the database.
  """
  @spec meal() :: map()
  def meal do
    %{
      title: gettext("Leftover dal"),
      slot: "Dinner",
      seed: nil,
      approximate?: true,
      # No `Kati.Locale.ltr/1` on this one, and that is not an oversight:
      # `Kati.Screens.MealEdit.shaped/1` builds the same field with a bare
      # tilde, and this Text holds nothing but the mark and the figure — the
      # neutral resolves against the digits on its own. The isolate is for
      # `kcal_line/2` above, where the word کالری follows and would otherwise
      # take the tilde with it.
      kcal: "~" <> Kati.Locale.number(380),
      # The multiplier the meal opens at, printed the way
      # `Kati.Screens.MealEdit.portion_label/1` prints it: one decimal, then
      # `×`. `Kati.Locale.number/1` converts the decimal SEPARATOR as well, so
      # Persian gets ۱٫۰ with U+066B rather than Persian numerals around a Latin
      # full stop, and `×` is U+00D7 — a mathematical sign, the same in both
      # scripts. `figures/3` draws the LIVE portion; this is the resting figure
      # the map carries so a shaped meal and this one describe the same thing
      # with the same keys.
      portion: Kati.Locale.number("1.0") <> "×",
      minutes: gettext("%{n} min", n: Kati.Locale.number(25)),
      # A hob is not an oven, so it takes a msgid of its own rather than
      # `shaped/1`'s `%{n}°C` — the two facts sit in the same slot on the same
      # line and mean different things. `pgettext/2` because one word is exactly
      # what `mix gettext.merge` fuzzy-matches against something longer.
      heat: pgettext("cooking heat", "Hob"),
      serves: gettext("Serves %{n}", n: Kati.Locale.number(2)),
      method:
        gettext(
          "Sweat the onion, add the lentils and coconut milk, simmer twenty minutes. Spinach in at the end."
        )
    }
  end

  @doc """
  The six macro rows screen 118 prints, two of them unknown.

  An em dash rather than a zero, for the reason the whole screen is about: a
  meal with no sodium figure has not got zero sodium.

  The six labels and the gram figures are
  `Kati.Screens.MealEdit.macros/1`'s own msgids, so the drawing's rows and a
  stored recipe's rows are one card in both scripts. The dash is punctuation and
  is drawn the same either way, so it is NOT a msgid — a bare `"—"` is what
  `mix gettext.merge` fuzzy-matches against any sentence that happens to end in
  one, and `Kati.Screens.MealEdit.grams/1` leaves it alone for the same reason.
  """
  @spec macros() :: [{String.t(), String.t()}]
  def macros do
    [
      {gettext("Protein"), grams(18)},
      {gettext("Carbs"), grams(52)},
      {gettext("Fat"), grams(11)},
      {gettext("Fibre"), grams(9)},
      {gettext("Sugar"), "—"},
      {gettext("Sodium"), "—"}
    ]
  end

  defp grams(n), do: gettext("%{n} g", n: Kati.Locale.number(n))

  @doc """
  The five ingredients, in the three states the drawing marks by glyph.

  Marked by a **leading glyph** rather than colour alone — green check for
  auto-filled, bronze query for quantity-only, ink pencil for free text —
  which is the caption's own instruction and is the reason the states survive
  a colour-blind reader and a greyscale screenshot.

  ## The meta line is half an aisle and half a state, and both are borrowed

  `Kati.Screens.MealEdit.ingredients/1` builds a stored row's meta out of
  `Kati.Meals.Aisle.label/1` and `state_label/1`, and
  `Kati.Screens.AddIngredient.preview/2` builds screen 119's out of
  `aisle_label/1` and the same `state_label/1`. So the drawing's four use those
  same msgids rather than a set of their own: a reader who has just seen
  `خواربار · تغذیه مشخص` in the preview must not meet a second Persian phrase
  for it one screen up.

  The names take `ingredient name`, the context
  `Kati.Screens.AddIngredient.ingredient_name/1` already opened for
  `Curry leaves` — every one of them is one or two words, which is exactly the
  length `mix gettext.merge` offers as a fuzzy match for a longer sentence.
  """
  @spec ingredients() :: [map()]
  def ingredients do
    [
      %{
        key: :red_lentils,
        name: pgettext("ingredient name", "Red lentils, dry"),
        meta:
          meta(pgettext("aisle", "Cupboard"), pgettext("ingredient state", "Nutrition known")),
        amount: grams(180),
        state: :known
      },
      %{
        key: :coconut_milk,
        name: pgettext("ingredient name", "Coconut milk"),
        meta:
          meta(pgettext("aisle", "Cupboard"), pgettext("ingredient state", "Nutrition known")),
        amount: gettext("%{n} ml", n: Kati.Locale.number(400)),
        state: :known
      },
      %{
        key: :spinach,
        name: pgettext("ingredient name", "Spinach"),
        meta: meta(pgettext("aisle", "Produce"), pgettext("ingredient state", "Quantity only")),
        # A handful is the drawing's own measure and is not one of the eight
        # `Kati.Meals.RecipeIngredient` allows, so it cannot borrow a
        # `unit_amount/2` clause and takes an entry of its own. `ngettext/4`
        # because English inflects it; Persian does not inflect a noun after a
        # numeral, so both forms answer the same word.
        amount: ngettext("%{n} handful", "%{n} handfuls", 2, n: Kati.Locale.number(2)),
        state: :quantity_only
      },
      %{
        key: :curry_leaves,
        name: pgettext("ingredient name", "Curry leaves"),
        meta: meta(pgettext("aisle", "Uncategorised"), pgettext("ingredient state", "Free text")),
        amount: pgettext("ingredient amount", "a few"),
        state: :free_text
      },
      # The fifth. The drawing's eyebrow says `Ingredients · 5` and its list has
      # room for four, so the onion the method names is the one that did not
      # fit — the same asymmetry `Kati.Music.Sample.tracks/0` records for a
      # tracklist, and resolved the same way: the fixture holds all of them.
      %{
        key: :onion,
        name: pgettext("ingredient name", "Onion"),
        meta: meta(pgettext("aisle", "Produce"), pgettext("ingredient state", "Nutrition known")),
        amount: ngettext("%{n} piece", "%{n} pieces", 1, n: Kati.Locale.number(1)),
        state: :known
      }
    ]
  end

  # `Kati.UI.eyebrow_label/1` and not `String.upcase/1`, for the reason
  # `Kati.Screens.MealEdit.ingredients/1` gives at the same line: Persian has no
  # case, so upcasing a Persian meta line is a no-op that reads as one. The
  # helper shouts in Latin and leaves the Arabic-script half alone, and the
  # separator is punctuation that is the same mark in both scripts.
  defp meta(aisle, state), do: Kati.UI.eyebrow_label(aisle <> " · " <> state)

  @doc """
  Screen 119's draft ingredient, as drawn.

  **Four tokens and two drawn values, and the difference is load-bearing.**
  `:name`, `:quantity`, `:unit` and `:aisle` are the STORED vocabulary —
  `Kati.Screens.AddIngredient.aisle_value/1` maps the aisle onto a
  `Kati.Meals.Aisle`, `unit_value/1` matches the unit against the eight
  `Kati.Meals.RecipeIngredient` allows, `amount_mg/1` parses a numeral out of
  the quantity, and a chip's tap tag is the aisle's own name with its spaces
  swapped for underscores. That sheet translates all four at the render sites
  and writes the tokens, which is its moduledoc's own section; a localised
  token here would drop through every one of those catch-alls and store a
  plausible wrong answer rather than raise.

  `:meta` is the other kind: the row's eyebrow, built from the same two msgids
  `ingredients/0` builds it from, so the sheet's preview and the row it
  previews cannot come to say two different things. Nothing reads it today —
  `preview/2` composes its own from the LIVE aisle chip, which is the only
  honest source once the chips are a real control — and it is kept in the
  drawing's shape rather than left as a Latin literal for the same screen to
  trip over the day it does.
  """
  @spec draft() :: map()
  def draft do
    %{
      name: "Curry leaves",
      quantity: "a few",
      unit: "free",
      aisle: "Uncategorised",
      meta: meta(pgettext("aisle", "Uncategorised"), pgettext("ingredient state", "Free text")),
      state: :free_text
    }
  end

  @doc """
  The aisles screen 119 offers, in the drawing's order.

  English in both scripts, and the one list in this file where that is a
  control rather than a preference: `Kati.Screens.AddIngredient.aisles/1` tags
  each chip `String.to_atom("aisle_" <> aisle)`, `handle_info/2` reads the word
  back out of that tag into `:aisle`, and `aisle_value/1` turns it into a
  `Kati.Meals.Aisle`. `aisle_label/1` is what a reader sees, and it draws these
  five through `pgettext("aisle", …)` — `ingredients/0` above borrows the same
  entries. A Persian chip label here would file every ingredient under
  `:other`, silently, on one page in one script, and that sheet exists to say
  that an ingredient filed nowhere vanishes off the shopping list.
  """
  @spec aisles() :: [String.t()]
  def aisles, do: ["Produce", "Cupboard", "Fish & meat", "Dairy", "Uncategorised"]

  @doc """
  The two nutrition paths that are drawn and not built.

  Both carry the same `NOT IN V1` badge the retired Health tiles use, so
  *designed, not built* means one thing app-wide rather than a different visual
  in every corner. The reasons are real and are printed: a barcode needs a food
  database Kati has not chosen, and a search needs a licence, a coverage
  guarantee and a rate limit that are all unresolved.

  The three titles and their three reasons stay English HERE and are translated
  at the point they are drawn, by
  `Kati.Screens.AddIngredient.path_title/1` and `path_sub/1`. Those clauses
  match on the literal because `gettext/1` needs one at the call site and this
  function hands them over as data — `gettext(path.title)` does not compile.
  Wrapping them here as well would leave those six clauses matching a msgid
  that no longer arrives under `:fa`, and every row would fall through to its
  own catch-all and draw the Persian twice-translated by luck rather than by
  design.
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
