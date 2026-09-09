defmodule Kati.Media.Mood do
  @moduledoc """
  The mood vocabulary, and what it is for.

  ## Why a closed list

  Fourteen values, fixed. #16 leaves "fixed or extensible" open and this closes
  it: the whole point of recording a mood is that it aggregates — a
  distribution across a year, and a local recommender that filters on it — and
  free text does not aggregate. "tense", "Tense", "tense!" and "a bit tense" are
  four moods to a database and one to a person.

  Extensible needs a vocabulary source, and Kati has none. StoryGraph's list is
  StoryGraph's dataset; these fourteen come from the ranked brief and are the
  same fourteen.

  ## Why it lives on the watch

  #16's other open question — title or viewing — and the issue answers itself
  with the example: *a rewatch in a different frame of mind*. A mood recorded
  on the title cannot say "funny the first time, sad the second"; a mood
  recorded per watch can, and `for_title/1` derives the title-level answer from
  it. The lossy direction is the one that has to be derived.

  ## What it feeds

  Kati is device-only with no server and no social graph, so it cannot
  recommend from other people's behaviour. Mood and pace are the only inputs
  that make a purely local recommender produce something a genre filter cannot.
  This is infrastructure for screen 11, not decoration.

  ## Nothing writes a mood yet, and no board draws the control that would

  Stated here because this module reads as finished and is not. The column is
  real — `Kati.Media.Watch.moods`, `{:array, :atom}` over the fourteen below,
  migrated by `20260822190546_add_mood_pace_and_content_warnings` — and it is
  `[]` on every device that has ever existed. All five places that create a
  watch write rating, review, tags, context and the stamps, and none of them
  writes this. `parse/1` says *from an import or a form* and neither exists:
  `Kati.Import.Mapping` has no mood field, so a column named for one is
  *Skipped*. Board 33 — the log sheet, the one place a mood could be picked —
  draws a rating, a review, three context rows and three tags, and no mood.

  So `distribution/1` and `for_title/1` answer emptily for every reader, and
  screen 13's four mood chips are dropped rather than drawn dead. The order is
  writer, then control, then chips; a writer alone would still not light them.
  """

  @vocabulary [
    :adventurous,
    :challenging,
    :dark,
    :emotional,
    :funny,
    :hopeful,
    :informative,
    :inspiring,
    :lighthearted,
    :mysterious,
    :reflective,
    :relaxing,
    :sad,
    :tense
  ]

  @doc "Every mood, alphabetically. No board draws them yet; see the moduledoc."
  @spec vocabulary() :: [atom()]
  def vocabulary, do: @vocabulary

  @doc "Whether `value` is a mood Kati records."
  @spec known?(term()) :: boolean()
  def known?(value), do: value in @vocabulary

  @doc """
  A mood's chip label.

  Derived rather than stored: a second list of fourteen strings is a second
  place for the vocabulary to drift.
  """
  @spec label(atom()) :: String.t()
  def label(mood) when mood in @vocabulary do
    mood |> Atom.to_string() |> String.capitalize()
  end

  @doc """
  Parse a list of strings — from an import or a form — keeping only known moods.

  Unknown values are dropped rather than raising. A StoryGraph export carries
  its own vocabulary and the overlap is partial; refusing the whole import over
  one unmapped word would lose the thirteen that did match.
  """
  @spec parse([String.t()] | String.t() | nil) :: [atom()]
  def parse(nil), do: []

  def parse(value) when is_binary(value) do
    value |> String.split(",") |> parse()
  end

  def parse(values) when is_list(values) do
    values
    |> Enum.map(fn v -> v |> to_string() |> String.trim() |> String.downcase() end)
    |> Enum.flat_map(fn v ->
      case Enum.find(@vocabulary, &(Atom.to_string(&1) == v)) do
        nil -> []
        mood -> [mood]
      end
    end)
    |> Enum.uniq()
  end

  @doc """
  How often each mood appears across a list of watches, most common first.

  What screen 07's distribution card reads. Moods with no watches are omitted
  rather than reported as zero — a distribution of fourteen bars, eleven of
  them empty, says less than three bars.
  """
  @spec distribution([%{moods: [atom()]}]) :: [{atom(), pos_integer()}]
  def distribution(watches) do
    watches
    |> Enum.flat_map(&(Map.get(&1, :moods) || []))
    |> Enum.frequencies()
    |> Enum.sort_by(fn {mood, count} -> {-count, mood} end)
  end

  @doc """
  The moods a title has been given across every watch of it.

  The derived title-level answer. Order is by how often the mood was chosen, so
  a title watched three times and called tense twice reads as tense first.
  """
  @spec for_title([%{moods: [atom()]}]) :: [atom()]
  def for_title(watches) do
    watches |> distribution() |> Enum.map(&elem(&1, 0))
  end
end
