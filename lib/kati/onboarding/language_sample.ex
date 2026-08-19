defmodule Kati.Onboarding.LanguageSample do
  @moduledoc """
  The language choice screen 53 draws, as data.

  The copy is the design's own, from `.scratch/design/screens/53.html`. It is
  the first thing the app asks, before anything else can be worded, so nothing
  on it can be translated by the answer — which is why the question is asked
  twice, once in each script, and each option states its three consequences in
  its own script rather than in the app's.

  Those three consequences — direction, digits, calendar — are the whole
  content of `meta`. `RIGHT TO LEFT · ۱۲۳۴ · SHAMSI` is legible to someone who
  cannot read the other row, which is the point of writing it in Persian
  digits rather than describing it in English.

  Nothing is persisted here yet. When the choice becomes real it goes through
  `Kati.Locale.put/1`, which already stores the locale and derives the writing
  direction from it; only `chosen` moves.
  """

  @doc "Everything screen 53 shows, in the order it shows it."
  @spec pick() :: map()
  def pick do
    %{
      steps: 5,
      done: 1,
      title: "Choose your\nlanguage",
      title_fa: "زبان خود را انتخاب کنید",
      body:
        "This sets the writing direction, the calendar and the number style. " <>
          "You can change it any time in Settings.",
      options: options(),
      note:
        "Picking فارسی flips the whole interface, not just the words — " <>
          "navigation, progress bars, charts and the week all run right to left.",
      cta: "Continue"
    }
  end

  @doc """
  The two locales Kati ships, each described in its own script.

  `script` picks the typeface for the badge and the name — Plus Jakarta Sans
  for `:latin`, Vazirmatn for `:persian` — because a Persian name set in a
  Latin face is exactly the kind of near-miss this screen exists to prevent.
  The `meta` line stays in DM Mono in both, since it is a specification.
  """
  @spec options() :: [map()]
  def options do
    [
      %{
        script: :latin,
        badge: "En",
        name: "English",
        meta: "LEFT TO RIGHT · 1234 · GREGORIAN",
        chosen: true
      },
      %{
        script: :persian,
        badge: "فا",
        name: "فارسی",
        meta: "RIGHT TO LEFT · ۱۲۳۴ · SHAMSI",
        chosen: false
      }
    ]
  end
end
