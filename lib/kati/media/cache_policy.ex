defmodule Kati.Media.CachePolicy do
  @moduledoc """
  How long cached third-party metadata may live, per source.

  ## The durable/cached line

  Two categories, and nothing may straddle them:

    * **Durable, never evicted** — the user's own facts: watched/read dates,
      ratings, reviews, notes, tags, status, positions, list membership, and the
      provider IDs needed to re-fetch. This is what makes a cache wipe
      survivable.
    * **Cached, evictable** — titles, synopses, poster paths, runtimes, air
      dates, cast, genres, availability. All re-fetchable.

  The test for any field: **if this vanished tonight, would the user lose
  something they created?** If not, it is cache. A row that mixes the two cannot
  be evicted, which is how a schema quietly becomes non-compliant.

  ## Why TMDB has a hard ceiling

  TMDB's terms cap caching at **six months**. That is a licence term, not a
  performance choice, so the eviction horizon is deliberately well inside it:
  **150 days** to evict, **30 days** to refresh in the background. A device that
  is offline for a month must never cross the line, and a user who opens the app
  rarely must not either.

  The CC0 and open sources have no such ceiling, so their horizons are about
  freshness rather than compliance and are expressed as soft refresh windows.
  """

  @type source :: :tmdb | :tvmaze | :anilist | :jikan | :openlibrary | :musicbrainz | :wikidata

  # {refresh_after_days, evict_after_days | :never}
  @policies %{
    # A title someone typed in. Never refreshed and never evicted, because
    # there is nothing behind it to refresh FROM and it is the only copy that
    # exists.
    #
    # This entry is not bookkeeping. `evict_after_days/1` is `Map.fetch!/2`, so
    # a `:manual` row without it raises rather than defaulting — and the
    # default, had there been one, would have been worse: every other source
    # here can be re-fetched, so evicting one costs a request. Evicting a
    # hand-typed title deletes the only record that it ever existed. #60 ships
    # film and TV in v1 and has no provider client, which makes `:manual` the
    # ONLY way a title enters Kati today.
    manual: {:never, :never},
    # Hard legal ceiling of 180 days. 150 leaves a month of slack for a device
    # that has been offline, and refresh at 30 keeps most rows far from it.
    tmdb: {30, 150},
    # Release schedules change; nothing legal forces eviction.
    tvmaze: {7, :never},
    anilist: {3, :never},
    jikan: {7, :never},
    openlibrary: {90, :never},
    musicbrainz: {90, :never},
    wikidata: {90, :never}
  }

  @doc "Every source Kati knows how to cache."
  @spec sources() :: [source()]
  def sources, do: Map.keys(@policies)

  @doc "Days after which a row should be refreshed in the background."
  @spec refresh_after_days(source()) :: pos_integer()
  def refresh_after_days(source), do: @policies |> Map.fetch!(source) |> elem(0)

  @doc """
  Days after which a row must be deleted, or `:never`.

  `:never` means no legal ceiling — not that the row is durable.
  """
  @spec evict_after_days(source()) :: pos_integer() | :never
  def evict_after_days(source), do: @policies |> Map.fetch!(source) |> elem(1)

  @doc "True when a row is old enough to refresh."
  @spec stale?(source(), DateTime.t(), DateTime.t()) :: boolean()
  def stale?(source, fetched_at, now \\ DateTime.utc_now()) do
    # `:never` is matched rather than compared. `integer >= :never` happens to
    # be `false` — atoms sort above numbers in Elixir's term order — so the
    # answer was already right, by an ordering rule that has nothing to do with
    # what this function means. A source that is never refreshed should say so.
    case refresh_after_days(source) do
      :never -> false
      days -> DateTime.diff(now, fetched_at, :day) >= days
    end
  end

  @doc """
  True when a row must be evicted to stay within the source's terms.

  Distinct from `stale?/3`: stale means "refresh when convenient", expired means
  "delete, whether or not a replacement is available".
  """
  @spec expired?(source(), DateTime.t(), DateTime.t()) :: boolean()
  def expired?(source, fetched_at, now \\ DateTime.utc_now()) do
    case evict_after_days(source) do
      :never -> false
      days -> DateTime.diff(now, fetched_at, :day) >= days
    end
  end

  @doc """
  The cut-off before which rows from a source must be deleted.

  `nil` when the source has no ceiling.
  """
  @spec eviction_cutoff(source(), DateTime.t()) :: DateTime.t() | nil
  def eviction_cutoff(source, now \\ DateTime.utc_now()) do
    case evict_after_days(source) do
      :never -> nil
      days -> DateTime.add(now, -days, :day)
    end
  end

  @doc """
  Attribution required when a source's data is displayed.

  Kept beside the cache policy because both are licence obligations attached to
  the same rows, and #8 renders these.
  """
  @spec attribution(source()) :: String.t()
  def attribution(:tmdb),
    do: "This product uses the TMDB API but is not endorsed or certified by TMDB."

  # Nobody to credit. A hand-typed title came from the person using the app,
  # and an attribution line naming a provider it never had would be a false
  # claim on screen 83 — which exists precisely to say where facts come from.
  def attribution(:manual), do: "Added by you."

  def attribution(:tvmaze), do: "Data provided by TVmaze (CC BY-SA)."
  def attribution(:anilist), do: "Data provided by AniList."
  def attribution(:jikan), do: "Data provided by Jikan / MyAnimeList."
  def attribution(:openlibrary), do: "Data provided by Open Library."
  def attribution(:musicbrainz), do: "Data provided by MusicBrainz."
  def attribution(:wikidata), do: "Data from Wikidata (CC0)."
end
