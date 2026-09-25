defmodule Kati.Language.Page do
  @moduledoc """
  What screen 54 is made of: its heading, the two installed languages, the
  dashed row under them, the *Follows the language* and *Content* rows, and the
  promise the page closes on.

  App structure, not sample data, which is why this is not called `Sample` any
  more. It was `Kati.Language.Sample`, and by the time it was deleted nothing
  in it was a stand-in: the heading and the row titles are the page's own
  words, the picker reads `Kati.Locale.current/0`, *Title language* reads
  `Kati.Locale.original_titles?/0`, *Currency* reads `Kati.Money.currency/0`,
  and the four *Follows the language* rows read the locale (below). A module
  named `Sample` that holds none is how a reader comes to believe the page is
  still a picture.

  ## Every word is said here, in the reader's language

  The rows used to carry the drawing's English as LITERALS, and
  `Kati.Screens.Language.copy/1` turned each one into a `gettext/1` call at the
  leaf, because a msgid has to sit at a call site. Now that the rows are built
  by functions, the call site is here, and the screen draws what it is handed.
  The msgids and contexts are the ones `copy/1` used, so the Persian catalogue
  carries over unchanged.

  Every group is a function and none is an attribute: `gettext/1` in a module
  attribute is evaluated at compile time and would freeze whichever locale the
  compiler was in. `Kati.Settings.Sample` records the same rule.

  ## The four *Follows the language* rows state what the locale does

  They were frozen copy — *Left to right · set by English*, *Gregorian ·
  Shamsi available*, *Latin 1234 · or Persian ۰۱۲۳*, *Monday · Saturday in
  فارسی* — identical at every locale, with the Persian catalogue flipping three
  of them into sentences about Persian. Correct on the day it was written and
  held true by nothing.

  Each now reads the function the rest of the app acts on:

    * **Writing direction** — `Kati.Locale.direction/1` of the current locale.
    * **Calendar** — `Kati.Locale.calendar/0`, the decision `Kati.Locale.date/2`
      makes before it formats a date.
    * **Numerals** — `Kati.Locale.numerals/0`, the decision
      `Kati.Locale.number/1` makes; the specimen is `number(1234)` itself.
    * **Week starts** — `Kati.Locale.week_start/0`.

  and names the language that set it, by the name the picker above prints for
  that language (`language_name/1`). So the English page says *Left to right ·
  set by English* and the Persian one says *راست به چپ · از فارسی می‌آید*, and
  both are true because the code that lays the page out is the code that says
  so.

  None of the four carries a tap or a chevron: each is a consequence of the
  language, not a preference with a store behind it. The writing-direction row
  prints `auto` in place of a control, which is the drawing's own mark for a
  derived value.

  ## Time format is a fact, not a setting

  `Kati.Locale.time/1` is `%H:%M` in both languages and no store holds a clock
  format, so the row says *24-hour* and offers nothing to tap. Adding a
  preference to make the row a control would be building the setting in order
  to justify the row.

  ## `script:` on the picker rows

  Only the two picker rows carry it. `فا`, `فارسی` and `ایران` are Persian
  whatever the reader's locale, and Plus Jakarta Sans has no Arabic glyphs, so
  the screen sets that row in Vazirmatn and pins `sans` on the Latin one.
  `Kati.Screens.Language.locale_of/1` also reads it to tell the two rows apart.
  The picker rows stay literal — they are the specimens a reader chooses
  between, and a catalogue would translate the choice away.
  """

  use Gettext, backend: Kati.Gettext

  @doc "The screen's title, its mono subtitle and its three eyebrows."
  @spec heading() :: map()
  def heading do
    %{
      title: gettext("Language"),
      subtitle: gettext("Changes apply instantly"),
      interface_label: pgettext("eyebrow", "Interface language"),
      follows_label: pgettext("eyebrow", "Follows the language"),
      content_label: pgettext("eyebrow", "Content")
    }
  end

  @doc """
  The installed interface languages, as specimens.

  Literal in both locales — see the moduledoc. Which one is selected is
  `Kati.Locale.current/0`'s answer, read by the screen, and never a flag here.
  """
  @spec languages() :: [map()]
  def languages do
    [
      %{code: "En", name: "English", region: "United Kingdom", script: :latin},
      %{code: "فا", name: "فارسی", region: "ایران", script: :fa}
    ]
  end

  @doc """
  A locale's name as the picker prints it: its own name for itself.

      iex> Kati.Language.Page.language_name(:en)
      "English"

      iex> Kati.Language.Page.language_name(:fa)
      "فارسی"
  """
  @spec language_name(:en | :fa) :: String.t()
  def language_name(locale) do
    Enum.find_value(languages(), fn row ->
      Kati.Screens.Language.locale_of(row) == locale && row.name
    end)
  end

  @doc "The dashed row under the installed languages."
  @spec add_language() :: map()
  def add_language do
    %{title: gettext("Add a language"), sub: gettext("Arabic, Turkish, German…")}
  end

  @doc """
  The five rows the language carries with it, each read from `Kati.Locale`.

  See the moduledoc for which function each row states. `:none` is the control
  of a row with nothing to open; `{:value, text}` is the writing-direction row's
  `auto`.
  """
  @spec follows() :: [map()]
  def follows do
    locale = Kati.Locale.current()
    language = language_name(locale)

    [
      %{
        icon: "format_textdirection_l_to_r",
        title: pgettext("language setting", "Writing direction"),
        sub: direction_line(Kati.Locale.direction(locale), language),
        control: {:value, pgettext("the derived value on the writing-direction row", "auto")}
      },
      %{
        icon: "calendar_month",
        title: gettext("Calendar"),
        sub: calendar_line(Kati.Locale.calendar(), language),
        control: :none
      },
      %{
        icon: "pin",
        title: pgettext("language setting", "Numerals"),
        sub: numerals_line(Kati.Locale.numerals(), language),
        control: :none
      },
      %{
        icon: "event",
        title: pgettext("language setting", "Week starts"),
        sub:
          gettext("%{day} · set by %{language}",
            day: Kati.Locale.week_start(),
            language: language
          ),
        control: :none
      },
      %{
        icon: "schedule",
        title: pgettext("language setting", "Time format"),
        sub: time_line(),
        control: :none
      }
    ]
  end

  @doc """
  The writing-direction row's line, for a direction and the language that set
  it.

      iex> Kati.Language.Page.direction_line(:ltr, "English")
      "Left to right · set by English"
  """
  @spec direction_line(:ltr | :rtl, String.t()) :: String.t()
  def direction_line(:ltr, language),
    do: gettext("Left to right · set by %{language}", language: language)

  def direction_line(:rtl, language),
    do: gettext("Right to left · set by %{language}", language: language)

  @doc """
  The calendar row's line.

      iex> Kati.Language.Page.calendar_line(:gregorian, "English")
      "Gregorian · set by English"
  """
  @spec calendar_line(:gregorian | :shamsi, String.t()) :: String.t()
  def calendar_line(:gregorian, language),
    do: gettext("Gregorian · set by %{language}", language: language)

  def calendar_line(:shamsi, language),
    do: gettext("Shamsi · set by %{language}", language: language)

  @doc """
  The numerals row's line, with `Kati.Locale.number/1`'s own digits as the
  specimen — so the figure on the row is the figure every sentence gets.

      iex> Kati.Language.Page.numerals_line(:latin, "English")
      "Latin 1234 · set by English"
  """
  @spec numerals_line(:latin | :persian, String.t()) :: String.t()
  def numerals_line(:latin, language),
    do:
      gettext("Latin %{digits} · set by %{language}",
        digits: Kati.Locale.number(1234),
        language: language
      )

  def numerals_line(:persian, language),
    do:
      gettext("Persian %{digits} · set by %{language}",
        digits: Kati.Locale.number(1234),
        language: language
      )

  @doc """
  The time-format row's line: 24-hour, which is what `Kati.Locale.time/1`
  writes in both languages. The 24 goes through `Kati.Locale.number/1` so a
  translator never carries a digit.

      iex> Kati.Language.Page.time_line()
      "24-hour"
  """
  @spec time_line() :: String.t()
  def time_line,
    do: pgettext("the time format a language carries", "%{n}-hour", n: Kati.Locale.number(24))

  @doc """
  What the language does to content rather than to the interface.

  *Title language* is drawn on here and pointed at the store by
  `Kati.Screens.Language.settled_content/1`.
  """
  @spec content() :: [map()]
  def content do
    [
      %{
        icon: "subtitles",
        title: pgettext("language setting", "Title language"),
        sub: gettext("Show original titles alongside"),
        control: {:switch, true}
      },
      %{
        icon: "restaurant",
        title: gettext("Units"),
        sub: gettext("Metric · grams and millilitres"),
        control: :none
      },
      %{
        icon: "payments",
        title: gettext("Currency"),
        sub: Kati.Locale.ltr(currency_line()),
        control: :chevron
      }
    ]
  end

  @doc """
  The reader's own currency, as the row under **Currency** reads it.

  It was the literal `"£ GBP"`, on a row that taps through to
  `Kati.Screens.Currency`, which both reads and writes the very key this now
  reads. The symbol and the ISO code stay Latin in both locales — a code is a
  name a machine gave itself — and `content/0` isolates the pair with
  `Kati.Locale.ltr/1` so a right-to-left page does not put the symbol on the
  wrong side of its code.
  """
  @spec currency_line() :: String.t()
  def currency_line do
    code = Kati.Money.currency()
    Kati.Money.symbol(code) <> " " <> code
  end

  @doc "The promise the screen closes on."
  @spec note() :: String.t()
  def note do
    gettext(
      "Your own words — notes, list names, meal titles — are never translated. " <>
        "Only the interface changes."
    )
  end
end
