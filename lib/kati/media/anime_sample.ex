defmodule Kati.Media.AnimeSample do
  @moduledoc """
  Stand-in numbers for `.scratch/design/incoming/152.html`'s Anime board.

  `:anime` is not a proposal. `Kati.Media.TrackedTitle` and
  `Kati.Media.CachedTitle` already constrain `:kind` to
  `[:movie, :tv, :anime, :book, :album]`, and `Kati.Screens.Library.shelf/0`
  already reads it — `@screen_kinds` is `[:movie, :tv, :anime]`, one shelf, not
  two. What is missing is everything board 152 is actually arguing for: a
  **per-title override** ("your own tag" beats the provider), a rule for what
  a fresh import decides before anyone overrides it, and the two places that
  reasoning surfaces on screen. None of those three has a column. There is no
  `type_override` on `TrackedTitle`, no import-provenance flag saying a row
  came from a MAL file rather than a tap, and no stored answer to "does this
  household watch anime" from onboarding.

  So this module is `Kati.Settings.DetectSample`'s move, for the same reason:
  a screen that cannot be compared against its own board because the feature
  behind it does not exist yet still has to draw the board. `Live action` vs
  `Animation` compounds the gap — splitting the *non-anime* rows by
  `CachedTitle.genres` is a real query someone could write, but nothing in
  `Kati.Media` writes it today, and a screen 152 exists to argue for a flag
  should not quietly invent the query that flag depends on.

  Every number below is the board's own — `12`, `76`, `4`, `92`, `4`, `3` — and
  `Marram` is not a new fixture: it is `Kati.Library.Sample`'s own ninth title
  (`seed: "marram15"`), the same one `Kati.Settings.DetectSample.decision/0`
  reaches for when *this app's* design system needs an ambiguous match. Reusing
  it here rather than inventing a tenth fictional show is the same discipline.
  """

  @doc "The Type-card chips (Placement A), in the board's own order and counts."
  @spec type_counts() :: [{String.t(), non_neg_integer()}]
  def type_counts, do: [{"Anime", 12}, {"Live action", 76}, {"Animation", 4}]

  @doc """
  The tab row's three ALWAYS-shown counts (Placement B, minus the Anime chip
  itself — see `Kati.Screens.AnimeFilter.promote?/2` for why that one is
  computed rather than carried here).
  """
  @spec tab_counts() :: [{String.t(), non_neg_integer()}]
  def tab_counts, do: [{"All", 92}, {"Watching", 4}, {"Finished", 3}]

  @doc "The board's own threshold: `10 or more`, stated as a number and not a feeling."
  @spec promote_threshold() :: pos_integer()
  def promote_threshold, do: 10

  @doc "What sets the flag, and what wins — in priority order, 1 first."
  @spec priority_rules() :: [{pos_integer(), String.t(), String.t()}]
  def priority_rules do
    [
      {1, "Your own tag", "Always wins — you know"},
      {2, "The import source", "A MAL or AniList file marks everything in it"},
      {3, "The provider genre", "TMDB’s Animation + Japanese origin"}
    ]
  end

  @doc """
  The one case the guess gets wrong: `Kati.Library.Sample`'s own Marram,
  imported from MAL (rule 2) and actually live action — the case rule 1 exists
  to override.
  """
  @spec misclassified() :: %{title: String.t(), seed: String.t(), note: String.t()}
  def misclassified do
    %{
      title: "Marram",
      seed: "marram15",
      note: "Tagged anime from a MAL import — it is live action"
    }
  end
end
