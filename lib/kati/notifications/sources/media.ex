defmodule Kati.Notifications.Sources.Media do
  @moduledoc """
  Release reminders, produced through the gate that already exists.

  `Kati.Media.Release.alarm_at/3` is the only thing in Kati allowed to say when
  a title's alarm should fire, and it refuses two different things at the same
  gate: a show whose per-show switch is off (`:muted`, screen 35) and a date no
  source was sure about (`:low_confidence`, #74's 1 January rule). That pairing
  is the point of the gate — *"a caller that pattern-matches `{:ok, at}` cannot
  accidentally honour one rule and forget the other"* — so this module
  pattern-matches `{:ok, at}` and does no date reasoning of its own.

  Both refusals become suppressed candidates rather than absences, because the
  question *"why am I not getting notifications for this show?"* has to be
  answerable, and "muted" and "we only know the year" are different answers with
  different fixes.

  ## One row of the table for all four kinds

  Films, books and records draw from the `:tv` allocation alongside television.
  They come from the same watcher, the same cache, the same gate and the same
  screens; giving them an unbudgeted row of their own would put the sum over the
  cliff that `Kati.Notifications.Budget` exists to stay under.

  ## Ids

  `"ep:<source>:<source_id>"`, or `"ep:<source>:<source_id>:<season>:<episode>"`
  once an episode is identified. The `ep:` prefix is #58's cross-language
  contract: the Kotlin worker cancels a stale air-date alarm by rebuilding the
  id from the identity it already has, without waking the BEAM to ask. Today
  Kati's own identity for a next release is the `{source, source_id}` pair —
  `Kati.Media.CachedTitle` carries `next_release_at` but no episode numbering —
  so that is what the id is built from, and `episode_id/4` is here for when the
  worker's diff supplies the rest.
  """

  alias Kati.Media.CachedTitle
  alias Kati.Media.Release
  alias Kati.Media.TrackedTitle
  alias Kati.Notifications.Candidate

  @type pair :: {TrackedTitle.t(), CachedTitle.t() | nil}

  @doc """
  A candidate per tracked title — armed, muted or vague, all three kept.

  `opts` pass straight through to `Kati.Media.Release.alarm_at/3`, so `:zone`
  and `:at` (the hour a day-precision release fires at, 09:00 by default) mean
  exactly what they mean there.
  """
  @spec candidates([pair()], keyword()) :: [Candidate.t()]
  def candidates(pairs, opts \\ []) when is_list(pairs) do
    Enum.map(pairs, &candidate(&1, opts))
  end

  @spec candidate(pair(), keyword()) :: Candidate.t()
  def candidate({%TrackedTitle{} = tracked, cached}, opts \\ []) do
    id = id(tracked)

    case Release.alarm_at(tracked, cached, opts) do
      {:ok, at} ->
        Candidate.absolute(id, :tv, at,
          title: title(tracked, cached),
          body: body(tracked),
          meta: meta(tracked)
        )

      {:suppressed, reason} ->
        Candidate.suppressed(id, :tv, reason, meta: meta(tracked))
    end
  end

  @doc """
  Every followed title paired with its cache row, ready for `candidates/2`.

  The filter is `TrackedTitle`'s own `:followed` action — archived, finished and
  dropped titles are excluded there, with the reasoning beside the action rather
  than duplicated here. The cache row is fetched by `{source, source_id}`, the
  value pair that stands in for the join Kati deliberately does not have, and a
  miss is `nil`: an evicted title with a hand-typed override still resolves.
  """
  @spec followed() :: [pair()]
  def followed do
    TrackedTitle
    |> Ash.Query.for_read(:followed)
    |> Ash.read!()
    |> Enum.map(fn tracked -> {tracked, Release.cached_for(tracked)} end)
  end

  @doc "The stable id for a title's next release."
  @spec id(TrackedTitle.t()) :: String.t()
  def id(%TrackedTitle{source: source, source_id: source_id}) do
    Candidate.id(["ep", source, source_id])
  end

  @doc "The stable id for one identified episode — #58's Kotlin side builds the same string."
  @spec episode_id(atom(), String.t(), integer(), integer()) :: String.t()
  def episode_id(source, source_id, season, episode) do
    Candidate.id(["ep", source, source_id, season, episode])
  end

  defp meta(%TrackedTitle{} = tracked) do
    %{source: tracked.source, source_id: tracked.source_id, kind: tracked.kind}
  end

  # The cache holds the name; the tracked row holds the follow. An evicted cache
  # costs the notification its title and not its existence.
  defp title(%TrackedTitle{}, %CachedTitle{title: title}) when is_binary(title), do: title
  defp title(%TrackedTitle{}, _evicted), do: "A title you follow"

  # English, and a fallback: #61 owns localisation.
  defp body(%TrackedTitle{kind: kind}) when kind in [:tv, :anime], do: "New episode out today"
  defp body(%TrackedTitle{kind: :book}), do: "Published today"
  defp body(%TrackedTitle{}), do: "Out today"
end
