defmodule Kati.Media.CachePolicyTest do
  @moduledoc """
  The TMDB ceiling is a licence term, not a tuning knob, so it gets a test that
  fails loudly if someone widens it.
  """
  use ExUnit.Case, async: true

  alias Kati.Media.CachePolicy

  @tmdb_legal_ceiling_days 180

  describe "TMDB's six-month cap" do
    test "eviction sits comfortably inside the legal ceiling" do
      evict = CachePolicy.evict_after_days(:tmdb)

      assert is_integer(evict)

      assert evict < @tmdb_legal_ceiling_days,
             "TMDB caps caching at six months; #{evict} days leaves no slack"

      # A device offline for a month must not cross the line while it sleeps.
      assert @tmdb_legal_ceiling_days - evict >= 30,
             "leave at least a month of slack for an offline device"
    end

    test "refresh happens long before eviction" do
      assert CachePolicy.refresh_after_days(:tmdb) < CachePolicy.evict_after_days(:tmdb)
    end

    test "a row past the ceiling is expired, not merely stale" do
      old = DateTime.add(DateTime.utc_now(), -(CachePolicy.evict_after_days(:tmdb) + 1), :day)

      assert CachePolicy.expired?(:tmdb, old)
      assert CachePolicy.stale?(:tmdb, old)
    end

    test "a freshly fetched row is neither" do
      now = DateTime.utc_now()
      refute CachePolicy.expired?(:tmdb, now)
      refute CachePolicy.stale?(:tmdb, now)
    end

    test "stale and expired are different questions" do
      # Old enough to refresh, nowhere near the legal ceiling.
      mid = DateTime.add(DateTime.utc_now(), -(CachePolicy.refresh_after_days(:tmdb) + 1), :day)

      assert CachePolicy.stale?(:tmdb, mid), "should want a refresh"
      refute CachePolicy.expired?(:tmdb, mid), "must not be deleted yet"
    end
  end

  describe "sources without a legal ceiling" do
    test "never expire, but still go stale" do
      long_ago = DateTime.add(DateTime.utc_now(), -3650, :day)

      for source <- [:tvmaze, :anilist, :openlibrary, :musicbrainz, :wikidata] do
        refute CachePolicy.expired?(source, long_ago), "#{source} has no ceiling"
        assert CachePolicy.stale?(source, long_ago), "#{source} should still refresh"
      end
    end

    test "eviction_cutoff is nil where there is no ceiling" do
      assert is_nil(CachePolicy.eviction_cutoff(:tvmaze))
      assert %DateTime{} = CachePolicy.eviction_cutoff(:tmdb)
    end
  end

  describe "every source is complete" do
    test "has a refresh horizon, an eviction rule and an attribution" do
      for source <- CachePolicy.sources() do
        # `:never` became a legal refresh horizon with `:manual` (#87): a title
        # someone typed has nothing behind it to refresh FROM, so a number here
        # would be a schedule for a request that can never be made. Every
        # source that IS a provider still has to name one, which is what the
        # second assertion below keeps true.
        assert CachePolicy.refresh_after_days(source) == :never or
                 is_integer(CachePolicy.refresh_after_days(source))

        assert source == :manual or is_integer(CachePolicy.refresh_after_days(source)),
               "#{source} is a provider and must say how often it is refreshed"

        assert CachePolicy.evict_after_days(source) == :never or
                 is_integer(CachePolicy.evict_after_days(source))

        # Attribution is a licence obligation, not a nicety (#8 renders these).
        assert is_binary(CachePolicy.attribution(source))
        assert CachePolicy.attribution(source) != ""
      end
    end

    test "TMDB's attribution is the exact wording their terms require" do
      assert CachePolicy.attribution(:tmdb) =~ "not endorsed or certified by TMDB"
    end
  end
end
