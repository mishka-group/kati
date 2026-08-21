defmodule Kati.Media.ReleaseTest do
  @moduledoc """
  #74's resolution rule, which is the correctness requirement behind the app's
  headline feature.

  Two things are proven here and neither is a nicety:

    * a date the user typed beats every source, **and survives the cache being
      wiped out from under it**;
    * a date a source was vague about never becomes a day, so nothing can arm a
      notification on an invented 1 January.

  These run against plain structs rather than the database on purpose: the rule
  is a pure function and must be provable without a schema, because it is the
  thing that has to keep working when the schema's other half has been deleted.
  """
  use ExUnit.Case, async: true

  alias Kati.Media.CachedTitle
  alias Kati.Media.Release
  alias Kati.Media.TrackedTitle

  # Exactly what a provider hands back for "sometime in 2026": the earliest
  # instant consistent with the period, which is not a date.
  @new_years_day ~U[2026-01-01 00:00:00.000000Z]

  defp tracked(attrs \\ []) do
    struct(
      %TrackedTitle{
        source: :tmdb,
        source_id: "603692",
        kind: :movie,
        notify_new_episodes: true
      },
      attrs
    )
  end

  defp cached(confidence, at \\ @new_years_day) do
    %CachedTitle{
      source: :tmdb,
      source_id: "603692",
      kind: :movie,
      next_release_at: at,
      date_confidence: confidence,
      fetched_at: ~U[2026-08-01 00:00:00.000000Z]
    }
  end

  describe "the user's date wins over every source" do
    test "it beats a source that was certain to the minute" do
      # The source is exact and it is wrong. The user fixed it by hand.
      certain_but_wrong = cached(:exact, ~U[2026-10-03 19:00:00.000000Z])
      title = tracked(user_override_date: ~D[2026-11-14])

      assert Release.resolve(title, certain_but_wrong) ==
               {:day, ~D[2026-11-14], :user_override}
    end

    test "it survives the cache row being evicted entirely" do
      # This is the whole reason the column is on the tracked row. With the
      # cache gone there is no other place the correction could have lived.
      title = tracked(user_override_date: ~D[2026-11-14])

      assert Release.resolve(title, nil) == {:day, ~D[2026-11-14], :user_override}
      assert {:ok, _at} = Release.alarm_at(title, nil, zone: "Etc/UTC")
    end

    test "it rescues a title the source could only place in a year" do
      # Without the override this is unarmable. With it, the user gets their
      # reminder — which is the point of letting them type one.
      vague = cached(:year)

      assert {:suppressed, :low_confidence} =
               Release.alarm_at(tracked(), vague, zone: "Etc/UTC")

      corrected = tracked(user_override_date: ~D[2026-06-19])

      assert {:ok, at} = Release.alarm_at(corrected, vague, zone: "Etc/UTC")
      assert DateTime.compare(at, ~U[2026-06-19 09:00:00Z]) == :eq
    end

    test "an absent override does not shadow a good source date" do
      exact = cached(:exact, ~U[2026-10-03 19:00:00.000000Z])

      assert Release.resolve(tracked(user_override_date: nil), exact) ==
               {:exact, ~U[2026-10-03 19:00:00.000000Z], :cache}
    end
  end

  describe "a vague date never becomes a day" do
    test "a bare year is a year, and 1 January appears nowhere in the answer" do
      assert Release.resolve(tracked(), cached(:year)) ==
               {:approximate, {:year, 2026}, :cache}
    end

    test "a quarter is a quarter" do
      q3 = cached(:quarter, ~U[2026-07-01 00:00:00.000000Z])
      assert Release.resolve(tracked(), q3) == {:approximate, {:quarter, 2026, 3}, :cache}
    end

    test "a month is a month" do
      october = cached(:month, ~U[2026-10-01 00:00:00.000000Z])
      assert Release.resolve(tracked(), october) == {:approximate, {:month, 2026, 10}, :cache}
    end

    test "an unlabelled date is trusted no further than its year" do
      # :unknown is CachedTitle's DEFAULT. Anything that armed on it would arm
      # on every row a source never annotated, which is most of them.
      assert Ash.Resource.Info.attribute(CachedTitle, :date_confidence).default == :unknown

      assert Release.resolve(tracked(), cached(:unknown)) ==
               {:approximate, {:year, 2026}, :cache}
    end

    test "no coarse answer carries a Date or a DateTime at all" do
      # The structural guarantee. A caller cannot arm on 1 January by mistake
      # because there is no January in the value it was handed.
      for confidence <- [:month, :quarter, :year, :unknown] do
        assert {:approximate, period, :cache} =
                 Release.resolve(tracked(), cached(confidence))

        for element <- Tuple.to_list(period) do
          refute match?(%Date{}, element), "#{confidence} leaked a Date"
          refute match?(%DateTime{}, element), "#{confidence} leaked a DateTime"
          assert is_atom(element) or is_integer(element)
        end
      end
    end

    test "quarters are derived from the month the source picked, all twelve of them" do
      expected = [1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4]

      got =
        for month <- 1..12 do
          at = DateTime.new!(Date.new!(2026, month, 1), ~T[00:00:00.000000], "Etc/UTC")

          {:approximate, {:quarter, 2026, q}, :cache} =
            Release.resolve(tracked(), cached(:quarter, at))

          q
        end

      assert got == expected
    end
  end

  describe "arming" do
    test "only :exact and :day may arm, and that is checked against the schema itself" do
      # Read the confidence ladder off CachedTitle rather than restating it, so
      # adding a seventh value without classifying it fails here.
      ladder = Ash.Resource.Info.attribute(CachedTitle, :date_confidence).constraints[:one_of]

      assert Enum.sort(ladder) == [:day, :exact, :month, :quarter, :unknown, :year]

      armed =
        for confidence <- ladder,
            match?({:ok, _}, Release.alarm_at(tracked(), cached(confidence), zone: "Etc/UTC")),
            do: confidence

      assert Enum.sort(armed) == [:day, :exact],
             "these confidences armed an alarm: #{inspect(armed)}"
    end

    test "an exact instant arms at exactly that instant" do
      premiere = ~U[2026-10-03 19:00:00.000000Z]

      assert {:ok, at} = Release.alarm_at(tracked(), cached(:exact, premiere), zone: "Etc/UTC")
      assert DateTime.compare(at, premiere) == :eq
    end

    test "a day-precise date arms at a chosen local hour, never at midnight" do
      day = cached(:day, ~U[2026-10-03 00:00:00.000000Z])

      assert {:ok, at} =
               Release.alarm_at(tracked(), day, zone: "Europe/Amsterdam", at: ~T[09:00:00])

      # 09:00 Amsterdam in October is CEST, UTC+2.
      assert DateTime.compare(at, ~U[2026-10-03 07:00:00Z]) == :eq
    end

    test "an hour that does not exist that night still produces an instant" do
      # Spring forward in Amsterdam, 2026-03-29: 02:00 becomes 03:00, so an
      # alarm set for 02:30 has no instant to fire at. Kati.Time's policy is to
      # take the first instant AFTER the jump rather than drop the alarm, and
      # this is the path that has to honour it: 03:00 CEST is 01:00 UTC.
      day = cached(:day, ~U[2026-03-29 00:00:00.000000Z])

      assert {:ok, at} =
               Release.alarm_at(tracked(), day, zone: "Europe/Amsterdam", at: ~T[02:30:00])

      assert DateTime.compare(at, ~U[2026-03-29 01:00:00Z]) == :eq

      # And it is not silently dropped, which is the failure this guards.
      refute Release.alarm_at(tracked(), day, zone: "Europe/Amsterdam", at: ~T[02:30:00]) ==
               {:suppressed, :no_date}
    end

    test "nothing known at all is :no_date, not a guess" do
      assert Release.alarm_at(tracked(), nil, zone: "Etc/UTC") == {:suppressed, :no_date}

      assert Release.alarm_at(tracked(), cached(:exact, nil), zone: "Etc/UTC") ==
               {:suppressed, :no_date}
    end

    test "a muted show is silent even when the date is certain" do
      # Screen 35's per-show switch. The same gate as low confidence, so a
      # scheduler cannot honour one rule and forget the other.
      muted = tracked(notify_new_episodes: false)
      certain = cached(:exact, ~U[2026-10-03 19:00:00.000000Z])

      assert Release.alarm_at(muted, certain, zone: "Etc/UTC") == {:suppressed, :muted}
    end

    test "a muted show is silent even when the user typed the date themselves" do
      # An override outranks every *source*. It does not outrank the user's own
      # decision to be left alone.
      muted = tracked(notify_new_episodes: false, user_override_date: ~D[2026-11-14])

      assert Release.alarm_at(muted, nil, zone: "Etc/UTC") == {:suppressed, :muted}
    end

    test "the default hour and zone need no options" do
      assert {:ok, %DateTime{}} =
               Release.alarm_at(tracked(), cached(:day, ~U[2026-10-03 00:00:00.000000Z]))
    end
  end

  describe "armable?/1 agrees with alarm_at/3" do
    test "on every confidence the cache can hold, plus an override and a miss" do
      ladder = Ash.Resource.Info.attribute(CachedTitle, :date_confidence).constraints[:one_of]

      cases =
        [{tracked(user_override_date: ~D[2026-11-14]), nil}, {tracked(), nil}] ++
          for confidence <- ladder, do: {tracked(), cached(confidence)}

      assert length(cases) == 8

      for {title, cache} <- cases do
        armed? = match?({:ok, _}, Release.alarm_at(title, cache, zone: "Etc/UTC"))

        assert Release.armable?(Release.resolve(title, cache)) == armed?,
               "disagreement on #{inspect(cache && cache.date_confidence)}"
      end
    end
  end

  describe "where the override is allowed to live" do
    test "user_override_date is on the durable row and absent from the cache" do
      # If it were on CachedTitle the eviction sweep would delete a correction
      # the user made by hand, and #74's rule would hold only until the next
      # sweep. This is the schema-level statement of that rule.
      assert %{type: Ash.Type.Date} =
               Ash.Resource.Info.attribute(TrackedTitle, :user_override_date)

      refute Ash.Resource.Info.attribute(CachedTitle, :user_override_date),
             "the override must not live on an evictable row"
    end

    test "the tracked row reaches the cache by value, never by a foreign key" do
      # A belongs_to would make eviction either impossible or destructive.
      assert Ash.Resource.Info.attribute(TrackedTitle, :source)
      assert Ash.Resource.Info.attribute(TrackedTitle, :source_id)

      assert [] ==
               TrackedTitle
               |> Ash.Resource.Info.relationships()
               |> Enum.filter(&(&1.destination == CachedTitle))
    end

    test "both halves name the same sources and the same kinds" do
      # A tracked row that names a source the cache cannot hold can never be
      # filled in. The lists are literals in both files; this pins them equal.
      for attribute <- [:source, :kind] do
        tracked_values = Ash.Resource.Info.attribute(TrackedTitle, attribute).constraints[:one_of]
        cached_values = Ash.Resource.Info.attribute(CachedTitle, attribute).constraints[:one_of]

        assert Enum.sort(tracked_values) == Enum.sort(cached_values),
               "#{attribute} disagrees between the durable and cached halves"
      end
    end
  end
end
