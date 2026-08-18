defmodule Kati.Media do
  @moduledoc """
  Cached third-party metadata.

  Everything in this domain is **evictable**. The user's own facts — watched
  dates, ratings, notes, list membership — live elsewhere and reference a title
  by `{source, source_id}`, so a cache wipe costs a re-fetch and never a memory.
  """
  use Ash.Domain, validate_config_inclusion?: false

  resources do
    resource Kati.Media.CachedTitle
  end
end
