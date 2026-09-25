defmodule Kati.Media.NextEpisode do
  @moduledoc """
  The episode a reader watches next: the first cached episode after the
  bookmark.

  Two screens answered this differently. Home's *Continue watching* counted
  ticks and printed `S1 · E<ticks + 1>` — season 1 always, so the thirteenth
  tick on a twelve-episode season read `S1 · E13`. Screen 10's hero and the
  home-screen widget printed the bookmark itself, the furthest episode already
  watched. For *Dark* with two ticks one said `S1 · E3` and the other
  `S1 · E2` (N15). Both are cards whose job is *continue*, so both now ask this.

  The bookmark is `Kati.Screens.Series.bookmark/1`'s — the furthest episode
  ticked — and the order is the provider's season and episode numbers. Specials
  (season 0) are skipped: a special is not the next episode of anything.
  """

  require Ash.Query

  alias Kati.Media.CachedEpisode
  alias Kati.Media.TrackedTitle

  @doc """
  `{season, episode}` of the next episode, or `nil` when nothing is cached or
  the reader is caught up.
  """
  @spec of(TrackedTitle.t()) :: {pos_integer(), pos_integer()} | nil
  def of(%TrackedTitle{source: source, source_id: source_id} = tracked) do
    CachedEpisode
    |> Ash.Query.filter(source == ^source and title_source_id == ^source_id)
    |> Ash.read!()
    |> Enum.reject(
      &(&1.special or not positive?(&1.season_number) or not positive?(&1.episode_number))
    )
    |> Enum.map(&{&1.season_number, &1.episode_number})
    |> Enum.sort()
    |> Enum.uniq()
    |> after_bookmark(bookmark(tracked))
  rescue
    _error -> nil
  end

  @doc """
  The first place after `bookmark` in an ordered list of places.

      iex> Kati.Media.NextEpisode.after_bookmark([{1, 1}, {1, 2}, {2, 1}], {1, 2})
      {2, 1}

      iex> Kati.Media.NextEpisode.after_bookmark([{1, 1}, {1, 2}], nil)
      {1, 1}

      iex> Kati.Media.NextEpisode.after_bookmark([{1, 1}, {1, 2}], {1, 2})
      nil
  """
  @spec after_bookmark([{pos_integer(), pos_integer()}], {integer(), integer()} | nil) ::
          {pos_integer(), pos_integer()} | nil
  def after_bookmark(places, nil), do: List.first(places)
  def after_bookmark(places, mark), do: Enum.find(places, &(&1 > mark))

  defp bookmark(%TrackedTitle{progress_season: s, progress_episode: e})
       when is_integer(s) and is_integer(e),
       do: {s, e}

  defp bookmark(_tracked), do: nil

  defp positive?(n), do: is_integer(n) and n > 0
end
