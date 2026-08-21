defmodule Kati.Media do
  @moduledoc """
  Titles: what a provider said about them, and what the user did with them.

  Two halves that never mix, because only one of them may be deleted:

    * **Evictable** — `Kati.Media.CachedTitle`. Posters, synopses, air dates,
      runtimes. A wipe costs a re-fetch.
    * **Durable** — `Kati.Media.TrackedTitle` and `Kati.Media.Watch`. Status,
      position, ratings, reviews, watch dates, and the date the user corrected
      by hand. A wipe must cost none of it.

  The durable half references the cache by `{source, source_id}` — a value, not
  a foreign key — so eviction can never orphan a memory, and a re-fetch finds
  its way back to the row it belongs to.

  `Kati.Media.Release` is where the two meet: it decides which date is next and
  whether Kati is sure enough of it to say so out loud.
  """
  use Ash.Domain, validate_config_inclusion?: false

  resources do
    resource Kati.Media.CachedTitle
    resource Kati.Media.TrackedTitle
    resource Kati.Media.Watch
  end
end
