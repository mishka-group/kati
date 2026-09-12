defmodule Kati.Meals.SampleRecipe do
  use Gettext, backend: Kati.Gettext

  @moduledoc """
  Stand-in data for screen 45 — a meal in full.

  The design's caption lists what a meal has to carry: *"Everything a meal
  needs to be cooked and counted: portion multiplier that rescales every
  number, macros as a bar and as figures, ingredients that tick off into the
  shopping list, and the history that tells you whether it is worth keeping."*

  Every figure is stored at **one portion**, because the multiplier is the
  thing that rescales them. The drawing shows `1.0×`, so the drawn numbers and
  the stored numbers are the same until someone taps `add`.

  The headline `620 kcal` is **declared rather than derived**: the five
  ingredient lines sum to 662, and the three macros — 52 g protein and 64 g
  carbohydrate at 4 kcal a gram, 17 g fat at 9 — sum to 617, which is the
  figure the drawing rounded. Screen 45's claim is that the total is *visibly*
  the sum of its parts, and the drawing is the specification, so the headline
  stays as drawn and is not recomputed. `Kati.MealsTest` cites this paragraph
  where its own fixture asserts the 662.

  ## The copy is the drawing's, in the reader's language

  The wording is `test/design/screens/45.html`'s, line for line, and since
  mishka-group/kati#103 it goes out through `Kati.Gettext`. There is no second
  module holding a Persian copy of it — `Kati.PersianScreensRatchetTest` is
  what makes sure there never is — so board 45 in Persian is
  `Kati.Screens.Meal` with the locale set, and a fixture holding frozen English
  is a page that draws half in Latin whatever the screen around it does.

  Wherever `Kati.Screens.Meal` already names one of these figures for a COOKED
  meal — the eyebrow's joined sentence, `kcal`, the three macros, the three
  minors, the three method facts, the three history titles — this file reaches
  for the SAME msgid rather than opening a second one. The drawn meal and a
  cooked one land at the same coordinates on the same card, and two catalogue
  entries for `Protein` is the one way they could come to disagree.

  The numbers are the reader's own through `Kati.Locale.number/1`, the `1.0×`
  in the stepper pill included. That one is not decoration: a cooked slot's
  pill is `Kati.Screens.Meal.portion_label/1`'s, which writes Persian numerals,
  so a drawn pill left as ASCII would have changed script under the reader's
  finger on the first tap of `add`. `portion_factor/1` folds Persian digits
  before it parses, so the label still round-trips, and
  `Kati.Locale.mono_face/1` asks the STRING rather than the reader which face
  it needs — so these strings are typeset correctly in either script.

  Three things stay Latin: `seed` is never drawn, the `method_facts` icons are
  Material Symbols names, and the tones are colours.
  """

  @doc "The eyebrow and title over the photograph."
  @spec meal() :: map()
  def meal do
    %{
      # One msgid with the two `·` joins inside it rather than three fragments
      # concatenated — the entry `Kati.Screens.Meal.slot_line/1` already makes
      # for a cooked slot. A translator who needs the clock at the other end of
      # the sentence can move it, which a `<>` between literals does not allow,
      # and moving it once moves it for both the drawn meal and the cooked one.
      #
      # `Dinner` is the word `Kati.Screens.MealEdit.slot_label/1` answers for
      # this slot, reached as the msgid itself rather than through that
      # function: `gettext/1` needs a literal at the call site, the board has
      # exactly one slot, and naming the same entry here opens nothing new.
      slot:
        gettext("%{slot} · %{at} · today",
          slot: gettext("Dinner"),
          at: Kati.Locale.time(~T[19:30:00])
        ),
      title: gettext("Miso salmon, greens & rice"),
      # Not copy. `Kati.Design.Images.hero/1` hashes this into a photograph and
      # it is never drawn, so it is a key and stays ASCII in both scripts.
      seed: "mealsalmon",
      # `Kati.Screens.Meal.portion_label/1`'s shape, arrived at from the other
      # end: that one holds the float and renders it, this one holds the
      # string. The digits and the decimal mark are the reader's —
      # `Kati.Locale.number/1` moves U+066B with them — and `×` is U+00D7, a
      # mathematical sign rather than a letter and the same sign in both
      # scripts, so it is appended and never translated.
      portion: Kati.Locale.number("1.0") <> "×",
      calories: Kati.Locale.number(620),
      # The space belongs to the LAYOUT and not to the catalogue: `620` and the
      # unit are one inline run in `Kati.Screens.Meal.portion_figure/1`, and a
      # msgid with a leading space is a msgid a translator cannot see the edge
      # of. `kcal` alone is the entry `Kati.Screens.MealEdit` made and
      # `Kati.Screens.Meal` reuses, so no screen can spell a calorie its own way.
      unit: " " <> gettext("kcal")
    }
  end

  @doc "The 10pt bar's three segments, as the drawing splits them."
  @spec split() :: [{float(), non_neg_integer()}]
  def split, do: [{0.34, 0xFF1A1917}, {0.42, 0xFFB08E55}, {0.24, 0xFFE4D2B0}]

  @doc "The three macro tiles under the bar."
  @spec macros() :: [{String.t(), String.t(), non_neg_integer()}]
  def macros do
    [
      {gettext("Protein"), grams_label(52), 0xFF1A1917},
      {gettext("Carbs"), grams_label(64), 0xFFB08E55},
      {gettext("Fat"), grams_label(17), 0xFFE4D2B0}
    ]
  end

  @doc "The three secondary figures under the hairline."
  @spec minors() :: [{String.t(), String.t()}]
  def minors do
    [
      {gettext("Fibre"), grams_label(7)},
      {gettext("Sugar"), grams_label(9)},
      # Sodium is the one figure the drawing prints in milligrams, which is the
      # unit it is stored in — `840 mg`, not `0.84 g`. Its own msgid for the
      # same reason a gram has one: a milligram is a WORD in Persian.
      {gettext("Sodium"), gettext("%{n} mg", n: Kati.Locale.number(840))}
    ]
  end

  @doc """
  The ingredients, at one portion.

  Each carries its own kcal so the total is visibly the sum of its parts, and
  each has a checkbox because ticking one is what puts it on the shopping list.

  The names take `ingredient name`, the context
  `Kati.Screens.AddIngredient.ingredient_name/1` opened and
  `Kati.Meals.SampleLibrary.ingredients/0` already writes its five rows in.
  Three of these words also sit in the catalogue under `shopping item`, which
  `Kati.Screens.Shopping.item_name/1` owns, and that is deliberate rather than
  an oversight: those two are two vocabularies — what a recipe calls a thing
  and what a list calls it — and a context is how `mix gettext.merge` is told
  they are allowed to diverge. They are spelled identically today.

  A stored recipe's lines are the reader's own words and are drawn untranslated;
  `Kati.Screens.Meal.ingredient_line/1` says so where it builds them. These
  five are the drawing's.
  """
  @spec ingredients() :: [map()]
  def ingredients do
    [
      %{
        name: pgettext("ingredient name", "Salmon fillet"),
        amount: grams_label(150),
        calories: Kati.Locale.number(312)
      },
      %{
        name: pgettext("ingredient name", "Jasmine rice, dry"),
        amount: grams_label(65),
        calories: Kati.Locale.number(234)
      },
      %{
        name: pgettext("ingredient name", "Tenderstem broccoli"),
        amount: grams_label(120),
        calories: Kati.Locale.number(42)
      },
      %{
        name: pgettext("ingredient name", "White miso"),
        amount: grams_label(15),
        calories: Kati.Locale.number(30)
      },
      %{
        name: pgettext("ingredient name", "Sesame oil"),
        # The one line the drawing measures by volume, and `%{n} ml` is the
        # entry `Kati.Screens.MealEdit.unit_amount/2` already keeps for it.
        amount: gettext("%{n} ml", n: Kati.Locale.number(5)),
        calories: Kati.Locale.number(44)
      }
    ]
  end

  @doc """
  The three facts above the method, each with its own icon.

  The icons are Material Symbols names — a font's index rather than copy — and
  stay Latin. The labels are the three `Kati.Screens.Meal.method_facts/1`
  builds for a stored recipe, so the drawn card and a cooked one say a minute,
  an oven and a serving the same way.
  """
  @spec method_facts() :: [{String.t(), String.t()}]
  def method_facts do
    [
      {"schedule", gettext("%{n} min", n: Kati.Locale.number(25))},
      # `°` is dropped in Persian rather than kept: the catalogue's entry reads
      # `فر %{n} درجه`, which spells the degree as the word it is said as.
      {"local_fire_department", gettext("Oven %{n}°", n: Kati.Locale.number(200))},
      {"restaurant", gettext("Serves %{n}", n: Kati.Locale.number(1))}
    ]
  end

  @doc """
  The method itself — one paragraph, as the drawing writes it.

  One msgid rather than three sentences, because the paragraph is the unit a
  cook reads and Persian orders its clauses differently: *rest while the rice
  cooks* is one clause in English and the rest is what moves around it. The
  `<>` concatenation is the file's own line wrapping and gettext folds it into
  a single literal before extraction.

  A stored recipe's method is what the reader typed and is drawn untranslated —
  `Kati.Screens.Meal.method/1` notes that where it draws it. This one is the
  drawing's own words about the drawing's own salmon.
  """
  @spec method() :: String.t()
  def method do
    gettext(
      "Whisk the miso with the sesame oil and a splash of water. Coat the " <>
        "salmon, rest 10 minutes while the rice cooks. Roast 12 minutes, steam " <>
        "the broccoli for the last 4."
    )
  end

  @doc """
  The history rows.

  `stars: 5` rather than a string of `★`: Plus Jakarta Sans carries no U+2605,
  so the rating is drawn with the Material Symbols `star` glyph — the same
  thing screen 08 discovered when its rating card rendered empty.

  The three titles are `Kati.Screens.Meal.history_rows/1`'s own entries. The
  two sub-lines are not: a cooked meal's `Last on` names the weekday its last
  log fell on and its note is what the reader typed, where these two are the
  drawing's — a frozen Thursday and a frozen remark — so they are copy and are
  translated as copy.
  """
  @spec history() :: [map()]
  def history do
    [
      %{
        icon: "event_repeat",
        # `Eaten %{n} times` and not `ngettext/4`: English says *once* rather
        # than *1 time*, so `Kati.Screens.Meal.times/1` splits the two into
        # separate entries and the counted one is what 14 reaches.
        title: gettext("Eaten %{n} times", n: Kati.Locale.number(14)),
        # The weekday is a WORD and it is its own msgid, because `gettext/1`
        # cannot take a variable. It is not a date and does not go through
        # `Kati.Locale.date/2`: both calendars share the seven-day cycle,
        # so Thursday is پنج‌شنبه in both calendars and there is no arithmetic
        # to do — the same reading `Kati.Calendar.SampleEvent` wrote its repeat
        # rule with, and the same entry.
        sub: gettext("Last on %{day}", day: gettext("Thursday")),
        stars: 0
      },
      %{
        icon: "star",
        title: gettext("Your rating"),
        # The separator is LAYOUT: `Kati.Screens.Meal.history_sub/1` draws five
        # star glyphs and then this string, so the ` · ` is what holds the
        # phrase off the last star. It is concatenated rather than carried into
        # the msgid for the reason `meal/0`'s `unit` gives — a translator
        # cannot see the edge of a msgid that begins with a space — and it
        # needs no `Kati.Locale.ltr/1`: a leading neutral in a right-to-left
        # line resolves to the line's own direction, which puts the dot back
        # against the stars in both scripts.
        #
        # `pgettext/2` because *a keeper* is two words. `mix gettext.merge`
        # fuzzy-matches a msgid that short against any sentence that resembles
        # it, and this one is an adjective for a five rather than a label.
        sub: " · " <> pgettext("meal history", "a keeper"),
        stars: 5
      },
      %{
        icon: "sticky_note_2",
        title: gettext("Note"),
        sub: gettext("Better with double the miso"),
        stars: 0
      }
    ]
  end

  # A gram is a WORD in Persian — ۵۲ گرم — and the numeral is the reader's, so
  # both halves of the figure move. The msgid is the one
  # `Kati.Screens.MealEdit.unit_amount/2` keeps and `Kati.Screens.Meal`'s own
  # `grams_label/1` reuses, which is why this is a function rather than the
  # interpolation written out at all nine figures that take a gram.
  defp grams_label(grams), do: gettext("%{n} g", n: Kati.Locale.number(grams))
end
