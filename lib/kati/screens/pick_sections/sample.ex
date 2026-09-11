defmodule Kati.Screens.PickSections.Sample do
  use Gettext, backend: Kati.Gettext

  @moduledoc """
  The six sections screen 26 offers, and the two it starts with chosen.

  This is not stand-in data in the way `Kati.Library.Sample` is — the list of
  sections is the app's own shape rather than a database row — but it lives
  here for the same reason: when a real `Kati.Sections` domain exists, the
  screen should read the same list of maps from it and nothing in
  `Kati.Screens.PickSections` should have to change.

  Order matters. The drawing puts Screen and Books first and pre-selects them,
  which is what makes the heading's *Pick two to start* true on arrival rather
  than an instruction the user has to obey before the button lights up.
  """

  # `{id, glyph, label, sub}` with the two words asked for at draw time, because
  # a label is a translation and a module attribute is frozen at compile time.
  # The `id` is what the tap, the store and `chosen/0` all key off, and it does
  # not move with the language — MOVIES-AND-TV.md #158. mishka-group/kati#103.
  @sections [
    {"screen", "movie"},
    {"books", "menu_book"},
    {"music", "graphic_eq"},
    {"habits", "bolt"},
    {"money", "payments"},
    {"notes", "edit_note"}
  ]

  @doc "Every section Kati can keep, in the order the grid draws them."
  @spec sections() :: [map()]
  def sections do
    Enum.map(@sections, fn {id, icon} ->
      %{id: id, icon: icon, label: label(id), sub: sub(id)}
    end)
  end

  @doc """
  A section's name.

      iex> Kati.Screens.PickSections.Sample.label("habits")
      "Habits"
  """
  @spec label(String.t()) :: String.t()
  def label("screen"), do: gettext("Screen")
  def label("books"), do: gettext("Books")
  def label("music"), do: gettext("Music")
  def label("habits"), do: gettext("Habits")
  def label("money"), do: gettext("Money")
  def label(_notes), do: gettext("Notes")

  @doc false
  @spec sub(String.t()) :: String.t()
  def sub("screen"), do: gettext("Films & TV")
  def sub("books"), do: gettext("Reading")
  def sub("music"), do: gettext("Listening")
  def sub("habits"), do: gettext("Streaks")
  def sub("money"), do: gettext("Subscriptions")
  def sub(_notes), do: gettext("Journal")

  @doc "The two the drawing arrives with already chosen."
  @spec chosen() :: MapSet.t()
  def chosen, do: MapSet.new(["screen", "books"])

  @doc """
  Onboarding progress: four steps, two done.

  Drawn as four equal bars rather than a percentage, because the design is
  promising *four steps* and a bar that only moves cannot promise a length.
  """
  @spec steps() :: {pos_integer(), pos_integer()}
  # **Five, not four.** The run has five steps — `Kati.Onboarding`'s own
  # `@steps` lists them and `Kati.Screens.OnboardingWelcome.rail/1` draws five
  # bars — and this said four, so screen 26 was the one step in the sequence
  # whose progress rail disagreed with the sequence. Board 26 was captured
  # before the run split into five and its mirror, 137, was drawn after: the
  # Persian sample has read `{5, 3}` since it existed, which is the two boards
  # answering the same question and only one of them being current.
  # mishka-group/kati#103 is what made them one function.
  def steps, do: {5, 3}

  @doc "The heading, kept as the two lines the drawing's `<br>` makes of it."
  @spec heading() :: [String.t()]
  # As many lines as the board draws it in, and that differs: 26 breaks it after
  # *What should* and 137 after را. One msgid with a `\n`, split here — a line
  # break is typesetting, and typesetting is part of a translation.
  def heading, do: String.split(gettext("What should\nKati keep?"), "\n")

  @doc "The line under the heading."
  @spec blurb() :: String.t()
  def blurb do
    gettext(
      "Pick two to start. You can add the rest whenever — every section drops into the same calendar and the same home page."
    )
  end
end
