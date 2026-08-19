defmodule Kati.Language.Sample do
  @moduledoc """
  Stand-in data for the language screen, until it reads `Kati.Locale`.

  `Kati.Locale` already knows which locale is active and which direction it
  writes in, and screen 54's job is eventually to set it. Until the write path
  exists this module supplies the shape the picker will read — two installed
  locales, one selected — so every state the drawing specifies is exercised
  rather than one of them being hypothetical.

  ## `script:` is not decoration

  Three of these strings are Persian — `فا`, `فارسی`, `ایران` — and two more
  mix Persian into an English sentence: *Monday · Saturday in فارسی* and
  *Latin 1234 · or Persian ۰۱۲۳*. Plus Jakarta Sans has no Arabic glyphs and
  no Arabic-Indic digits, so a row that carries them has to be drawn in
  Vazirmatn or it draws empty boxes. `script: :fa` is how a row says so, and
  `Kati.Screens.Language` is what acts on it.

  The design makes this the screen's own subject matter, which is why it is
  data and not an accident: the last row of the drawing promises that nothing
  the user typed is ever rewritten, and a picker that cannot render its own
  options is a poor place to make that promise.
  """

  @doc "The screen's title and its mono subtitle."
  @spec heading() :: map()
  def heading do
    %{
      title: "Language",
      subtitle: "Changes apply instantly",
      interface_label: "Interface language",
      follows_label: "Follows the language",
      content_label: "Content"
    }
  end

  @doc "The installed interface languages, the active one first."
  @spec languages() :: [map()]
  def languages do
    [
      %{code: "En", name: "English", region: "United Kingdom", script: :latin, on: true},
      %{code: "فا", name: "فارسی", region: "ایران", script: :fa, on: false}
    ]
  end

  @doc "The dashed row under the installed languages."
  @spec add_language() :: map()
  def add_language do
    %{title: "Add a language", sub: "Arabic, Turkish, German…"}
  end

  @doc """
  The five settings the language carries with it, each still overridable.

  Writing direction shows a value rather than a chevron because it is not a
  choice — it is derived, and the drawing says so by printing `auto` where the
  other four print an arrow.
  """
  @spec follows() :: [map()]
  def follows do
    [
      %{
        icon: "format_textdirection_l_to_r",
        title: "Writing direction",
        sub: "Left to right · set by English",
        control: {:value, "auto"}
      },
      %{
        icon: "calendar_month",
        title: "Calendar",
        sub: "Gregorian · Shamsi available",
        control: :chevron
      },
      %{
        icon: "pin",
        title: "Numerals",
        sub: "Latin 1234 · or Persian ۰۱۲۳",
        control: :chevron,
        script: :fa
      },
      %{
        icon: "event",
        title: "Week starts",
        sub: "Monday · Saturday in فارسی",
        control: :chevron,
        script: :fa
      },
      %{icon: "schedule", title: "Time format", sub: "24-hour", control: :chevron}
    ]
  end

  @doc "What the language does to content rather than to the interface."
  @spec content() :: [map()]
  def content do
    [
      %{
        icon: "subtitles",
        title: "Title language",
        sub: "Show original titles alongside",
        control: {:switch, true}
      },
      %{
        icon: "restaurant",
        title: "Units",
        sub: "Metric · grams and millilitres",
        control: :chevron
      },
      %{icon: "payments", title: "Currency", sub: "£ GBP", control: :chevron}
    ]
  end

  @doc "The promise the screen closes on."
  @spec note() :: String.t()
  def note do
    "Your own words — notes, list names, meal titles — are never translated. Only the interface changes."
  end
end
