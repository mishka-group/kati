defmodule Kati.Media do
  @moduledoc """
  Titles: what a provider said about them, and what the user did with them.

  Two halves that never mix, because only one of them may be deleted:

    * **Evictable** — `Kati.Media.CachedTitle`, `Kati.Media.CachedSeason` and
      `Kati.Media.CachedEpisode`. Posters, synopses, air dates, runtimes,
      episode names and season inventories. A wipe costs a re-fetch.
    * **Durable** — `Kati.Media.TrackedTitle` and `Kati.Media.Watch`. Status,
      position, ratings, reviews, watch dates, and the date the user corrected
      by hand. A wipe must cost none of it.

  The durable half references the cache by `{source, source_id}` — a value, not
  a foreign key — so eviction can never orphan a memory, and a re-fetch finds
  its way back to the row it belongs to. The three cache resources reference
  each other the same way and for the same reason: a season is
  `{source, title_source_id, season_number}`, an episode is
  `{source, source_id}` with a `title_source_id` beside it, and a
  `Kati.Media.Watch`'s `episode_source_id` reaches an episode as
  `{tracked.source, watch.episode_source_id}`. Nothing cascades, so any one of
  the three can be evicted without taking the others — or a single tick — with
  it.

  `Kati.Media.Release` is where the two halves meet: it decides which date is
  next, for a title, a season or an episode alike, and whether Kati is sure
  enough of it to say so out loud.
  """
  use Ash.Domain, validate_config_inclusion?: false

  resources do
    resource Kati.Media.CachedTitle
    resource Kati.Media.CachedSeason
    resource Kati.Media.CachedEpisode
    resource Kati.Media.TrackedTitle
    resource Kati.Media.Watch
  end
end
