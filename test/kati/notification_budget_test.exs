defmodule Kati.Notifications.BudgetTest do
  @moduledoc """
  The budget, asserted as a value rather than described as a policy.

  #59's acceptance is specific: *"a test arms 600 intended notifications across
  six domains and asserts that the armed count never exceeds the table, that no
  `IllegalStateException` is possible, and that the entries dropped are the
  furthest-future ones."* All three are here, and the third is the one that
  needs content rather than counts — "fifty survived" is satisfied by any fifty,
  including the wrong fifty, so these tests name the survivors.
  """
  use ExUnit.Case, async: true

  alias Kati.Notifications.Budget
  alias Kati.Notifications.Candidate
  alias Kati.Notifications.Plan
  alias Kati.Notifications.Scheduler

  @now ~U[2026-08-21 10:00:00Z]

  # A hundred per domain, one hour apart, with each domain offset ten minutes
  # from the next. Ten minutes clears the nine-minute floor, so nothing here
  # collapses into a digest and the numbers below are the budget's own work and
  # not the digest's.
  defp six_hundred do
    for {domain, index} <- Enum.with_index(Budget.domains()),
        n <- 0..99 do
      Candidate.absolute(
        Candidate.id([domain, n]),
        domain,
        DateTime.add(@now, 3600 + n * 3600 + index * 600, :second),
        title: "#{domain} #{n}"
      )
    end
  end

  defp plan(candidates, platform) do
    Scheduler.plan(candidates,
      platform: platform,
      now: @now,
      zone: "Etc/UTC",
      quiet_hours: false
    )
  end

  describe "the table" do
    test "each column sums to what the module claims, and both leave headroom" do
      for platform <- Budget.platforms() do
        summed = platform |> Budget.table() |> Map.values() |> Enum.sum()

        assert summed == Budget.total(platform)
        assert summed < Budget.cap(platform)
        assert Budget.headroom(platform) == Budget.cap(platform) - summed
      end
    end

    test "the two numbers are the two documented cliffs" do
      # 500 concurrent alarms per UID (notifee#349) — exceeding it throws.
      assert Budget.cap(:android) == 500
      assert Budget.total(:android) == 480
      assert Budget.headroom(:android) == 20

      # The soonest-firing 64 are kept and the rest discarded, silently
      # (the deprecated UILocalNotification reference). Fourteen slots of
      # deliberate distance from a cliff that gives no warning.
      assert Budget.cap(:ios) == 64
      assert Budget.total(:ios) == 50
      assert Budget.headroom(:ios) == 14
    end

    test "all six domains have an allocation on both platforms" do
      assert Budget.domains() == [:calendar, :tv, :habits, :meals, :health, :money]

      for platform <- Budget.platforms(), domain <- Budget.domains() do
        assert Budget.limit(platform, domain) > 0
      end
    end

    test "a domain outside the table cannot be given one by accident" do
      assert_raise ArgumentError, ~r/no allocation for :crypto/, fn ->
        Budget.limit(:ios, :crypto)
      end

      # And it cannot even be written down: the candidate refuses at the point
      # the domain module builds it, not silently at plan time.
      assert_raise ArgumentError, ~r/not a budgeted domain/, fn ->
        Candidate.absolute("x:1", :crypto, @now)
      end
    end
  end

  describe "600 candidates across six domains" do
    test "iOS keeps exactly the table, and nothing is lost track of" do
      candidates = six_hundred()
      plan = plan(candidates, :ios)

      assert length(candidates) == 600
      assert Plan.pending_count(plan) == 50
      assert Plan.counts(plan) == Budget.table(:ios)

      assert Plan.counts(plan) == %{
               calendar: 16,
               tv: 12,
               habits: 8,
               meals: 6,
               health: 4,
               money: 4
             }

      # Under the cliff with the headroom intact — this is the assertion that
      # stands in for "no silent truncation is possible".
      assert Plan.pending_count(plan) < Budget.cap(:ios)

      # Every candidate came out somewhere. A budget that drops entries without
      # recording them cannot answer "why am I not getting notifications?".
      assert length(plan.armed) + length(plan.suppressed) == 600
      assert length(Plan.suppressed(plan, :over_budget)) == 550
      assert Plan.suppressed(plan, :digested) == []
    end

    test "the survivors are the soonest of each domain, named" do
      plan = plan(six_hundred(), :ios)

      for {domain, limit} <- Budget.table(:ios) do
        kept = plan.armed |> Enum.filter(&(&1.domain == domain)) |> Enum.map(& &1.id)

        assert kept == Enum.map(0..(limit - 1), &Candidate.id([domain, &1])),
               "#{domain} kept #{inspect(kept)}"
      end
    end

    test "what was shed is further out than everything that was kept" do
      plan = plan(six_hundred(), :ios)

      for domain <- Budget.domains() do
        latest_kept =
          plan.armed
          |> Enum.filter(&(&1.domain == domain))
          |> Enum.map(& &1.fire_at)
          |> Enum.max(DateTime)

        shed =
          plan
          |> Plan.suppressed(:over_budget)
          |> Enum.filter(&(&1.domain == domain))

        assert length(shed) == 100 - Budget.limit(:ios, domain)

        for candidate <- shed do
          assert DateTime.compare(candidate.fire_at, latest_kept) == :gt,
                 "#{candidate.id} was shed while a later entry was kept"
        end
      end
    end

    test "each shed entry says which domain filled up and at what limit" do
      plan = plan(six_hundred(), :ios)
      shed = Enum.find(plan.suppressed, &(&1.id == Candidate.id([:tv, 99])))

      assert shed.suppressed == :over_budget
      assert shed.meta.domain == :tv
      assert shed.meta.limit == 12
      assert Plan.reason(plan, Candidate.id([:tv, 99])) == :over_budget
      assert Plan.find(plan, Candidate.id([:tv, 99])) == nil
    end

    test "Android takes the same input and keeps 410 of it" do
      plan = plan(six_hundred(), :android)

      # Four domains have room for all hundred; two do not, and only those two
      # shed anything. Same candidates, different column.
      assert Plan.counts(plan) == %{
               calendar: 100,
               tv: 100,
               habits: 80,
               meals: 60,
               health: 40,
               money: 30
             }

      assert Plan.pending_count(plan) == 410
      assert Plan.pending_count(plan) <= Budget.total(:android)
      assert Plan.pending_count(plan) < Budget.cap(:android)

      assert plan
             |> Plan.suppressed(:over_budget)
             |> Enum.map(& &1.domain)
             |> Enum.uniq()
             |> Enum.sort() ==
               [:habits, :health, :meals, :money]
    end
  end

  describe "slots are not redistributed" do
    test "an empty calendar does not lend television its allocation" do
      television =
        for n <- 0..99 do
          Candidate.absolute(
            Candidate.id([:tv, n]),
            :tv,
            DateTime.add(@now, 3600 + n * 3600, :second),
            title: "episode #{n}"
          )
        end

      plan = plan(television, :ios)

      # Fifty slots exist and television may have twelve of them. The other
      # thirty-eight stay unclaimed rather than going to whoever asked first.
      assert Plan.pending_count(plan) == 12
      assert Plan.counts(plan)[:tv] == 12

      assert Plan.usage(plan) == %{
               calendar: {0, 16},
               tv: {12, 12},
               habits: {0, 8},
               meals: {0, 6},
               health: {0, 4},
               money: {0, 4}
             }
    end
  end
end
