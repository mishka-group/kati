defmodule Kati.Notifications.SchedulerTest.Recorder do
  @moduledoc false
  @behaviour Kati.Notifications.Delivery

  # The backend runs in the caller's process, so a message to `self/0` is the
  # cheapest possible proof that delivery happened in the order it was asked to.
  @impl true
  def arm(candidate) do
    send(self(), {:armed, candidate.id})
    :ok
  end

  @impl true
  def cancel(id) do
    send(self(), {:cancelled, id})
    :ok
  end
end

defmodule Kati.Notifications.SchedulerTest.Denied do
  @moduledoc false
  @behaviour Kati.Notifications.Delivery

  @impl true
  def arm(_candidate), do: {:error, :permission_denied}

  @impl true
  def cancel(_id), do: :ok
end

defmodule Kati.Notifications.SchedulerTest do
  @moduledoc """
  The decision layer: what should exist, when, and what quietly must not.

  Every test here injects `:now` and `:zone`. Planning is a pure function and
  the suite treats it as one — a scheduler test that read the wall clock would
  pass or fail depending on the hour it ran at, which for a module about quiet
  hours and timezones is not a hypothetical.
  """
  use ExUnit.Case, async: true

  alias Kati.Notifications.Armed
  alias Kati.Notifications.Candidate
  alias Kati.Notifications.Delivery
  alias Kati.Notifications.Digest
  alias Kati.Notifications.Plan
  alias Kati.Notifications.QuietHours
  alias Kati.Notifications.Reconcile
  alias Kati.Notifications.Scheduler
  alias Kati.Notifications.SchedulerTest.Denied
  alias Kati.Notifications.SchedulerTest.Recorder

  doctest Kati.Notifications.Scheduler

  @now ~U[2026-08-21 10:00:00Z]
  @lib Path.expand("../../lib", __DIR__)

  defp plan(candidates, opts \\ []) do
    Scheduler.plan(
      candidates,
      Keyword.merge([platform: :ios, now: @now, zone: "Etc/UTC"], opts)
    )
  end

  defp episode(id, at, opts \\ []) do
    Candidate.absolute(id, :tv, at, Keyword.put_new(opts, :title, id))
  end

  # Applies operations to an armed set exactly as a store would, so a test can
  # stop halfway and ask what is left to do.
  defp apply_ops(operations, armed) do
    Enum.reduce(operations, armed, fn
      {:arm, candidate}, acc ->
        [Armed.from_candidate(candidate) | Enum.reject(acc, &(&1.id == candidate.id))]

      {:cancel, id}, acc ->
        Enum.reject(acc, &(&1.id == id))
    end)
  end

  describe "a platform must be named" do
    test "there is no default, because the wrong default picks the wrong cliff" do
      assert_raise ArgumentError, ~r/needs :platform/, fn ->
        Scheduler.plan([], now: @now, zone: "Etc/UTC")
      end
    end
  end

  describe "the same reminder cannot hold two slots" do
    test "one id scheduled twice arms once, and the earlier time wins" do
      duplicated = [
        episode("ep:tmdb:1396", ~U[2026-08-25 19:00:00Z]),
        episode("ep:tmdb:1396", ~U[2026-08-23 19:00:00Z])
      ]

      plan = plan(duplicated)

      assert Plan.armed_ids(plan) == ["ep:tmdb:1396"]
      assert Plan.find(plan, "ep:tmdb:1396").fire_at == ~U[2026-08-23 19:00:00Z]
      assert length(Plan.suppressed(plan, :duplicate)) == 1
      assert Plan.pending_count(plan) == 1
    end

    test "collecting the same event from two sources is one alarm, not two" do
      # The realistic version: a calendar event mirrored twice, plus a genuinely
      # different event. Two candidates in, two out — never three.
      candidates = [
        Candidate.absolute("ev:uid-a", :calendar, ~U[2026-08-22 09:00:00Z], title: "Standup"),
        Candidate.absolute("ev:uid-a", :calendar, ~U[2026-08-22 09:00:00Z], title: "Standup"),
        Candidate.absolute("ev:uid-b", :calendar, ~U[2026-08-24 09:00:00Z], title: "Dentist")
      ]

      plan = plan(candidates)

      assert Plan.armed_ids(plan) == ["ev:uid-a", "ev:uid-b"]
      assert Plan.counts(plan)[:calendar] == 2
    end
  end

  describe "the past" do
    test "an instant behind now is dropped and says so" do
      plan =
        plan([
          episode("ep:old", ~U[2026-08-20 19:00:00Z]),
          episode("ep:soon", ~U[2026-08-22 19:00:00Z])
        ])

      assert Plan.armed_ids(plan) == ["ep:soon"]
      assert Plan.reason(plan, "ep:old") == :past
    end

    test "this exact instant is not the future" do
      plan = plan([episode("ep:now", @now)])

      assert plan.armed == []
      assert Plan.reason(plan, "ep:now") == :past
    end
  end

  describe "quiet hours shift a notification rather than dropping one" do
    test "a 23:30 reminder is delivered at 08:00, not lost" do
      plan = plan([episode("ep:late", ~U[2026-08-21 23:30:00Z])])

      assert Plan.pending_count(plan) == 1
      assert plan.suppressed == []

      entry = Plan.find(plan, "ep:late")
      assert entry.fire_at == ~U[2026-08-22 08:00:00Z]
      assert entry.shifted_from == ~U[2026-08-21 23:30:00Z]
    end

    test "a 02:00 reminder waits for this morning, not tomorrow's" do
      plan = plan([episode("ep:small-hours", ~U[2026-08-22 02:00:00Z])])

      assert Plan.find(plan, "ep:small-hours").fire_at == ~U[2026-08-22 08:00:00Z]
    end

    test "the window is closed at 23:00 and open again at 08:00" do
      plan =
        plan([
          episode("ep:evening", ~U[2026-08-21 22:59:00Z]),
          episode("ep:morning", ~U[2026-08-22 08:00:00Z])
        ])

      assert Plan.find(plan, "ep:evening").fire_at == ~U[2026-08-21 22:59:00Z]
      assert Plan.find(plan, "ep:morning").fire_at == ~U[2026-08-22 08:00:00Z]
      assert Enum.all?(plan.armed, &is_nil(&1.shifted_from))
    end

    test "quiet is quiet where the user is standing, not in UTC" do
      # 20:00Z is 23:30 in Tehran, which is inside the window; the same instant
      # is 20:00 in London, which is not. Same candidate, two zones.
      at = ~U[2026-08-21 20:00:00Z]

      tehran = plan([episode("ep:tehran", at)], zone: "Asia/Tehran")
      london = plan([episode("ep:london", at)], zone: "Europe/London")

      assert Plan.find(tehran, "ep:tehran").fire_at == ~U[2026-08-22 04:30:00Z]
      assert Plan.find(london, "ep:london").fire_at == at
    end

    test "an entry tied to its own clock is exempt, because 08:00 is too late" do
      # A 07:30 meeting alert shifted to 08:00 arrives after the meeting began.
      meeting =
        Candidate.absolute("ev:standup", :calendar, ~U[2026-08-22 07:30:00Z],
          title: "Standup",
          quiet_hours: :exempt
        )

      plan = plan([meeting])

      assert Plan.find(plan, "ev:standup").fire_at == ~U[2026-08-22 07:30:00Z]
      assert Plan.find(plan, "ev:standup").shifted_from == nil
    end

    test "the rule can be turned off, and then nothing moves" do
      plan = plan([episode("ep:late", ~U[2026-08-21 23:30:00Z])], quiet_hours: false)

      assert Plan.find(plan, "ep:late").fire_at == ~U[2026-08-21 23:30:00Z]
    end

    test "a window that does not wrap midnight still shifts forward" do
      window = QuietHours.new(~T[13:00:00], ~T[14:00:00])
      plan = plan([episode("ep:lunch", ~U[2026-08-22 13:30:00Z])], quiet_hours: window)

      assert Plan.find(plan, "ep:lunch").fire_at == ~U[2026-08-22 14:00:00Z]
    end
  end

  describe "the nine-minute floor" do
    test "a cluster becomes one digest that names what is in it" do
      plan =
        plan([
          episode("ep:a", ~U[2026-08-22 08:00:00Z], title: "Wilderness"),
          episode("ep:b", ~U[2026-08-22 08:03:00Z], title: "The Estuary"),
          episode("ep:c", ~U[2026-08-22 08:06:00Z], title: "Nightjar")
        ])

      assert Plan.pending_count(plan) == 1
      [digest] = plan.armed

      assert digest.title == "3 new episodes"
      assert digest.body == "Wilderness · The Estuary · Nightjar"
      assert digest.members == ["ep:a", "ep:b", "ep:c"]
      assert digest.domain == :tv

      # It fires at the EARLIEST member's instant. Folding must never delay
      # anything, or a digest becomes a way of missing an appointment.
      assert digest.fire_at == ~U[2026-08-22 08:00:00Z]

      for id <- ["ep:a", "ep:b", "ep:c"] do
        assert Plan.reason(plan, id) == :digested
        assert Enum.find(plan.suppressed, &(&1.id == id)).meta.into == digest.id
      end
    end

    test "a mixed cluster is counted, not mislabelled" do
      plan =
        plan([
          episode("ep:a", ~U[2026-08-22 08:00:00Z], title: "Wilderness"),
          Candidate.absolute("meal:lunch", :meals, ~U[2026-08-22 08:04:00Z], title: "Porridge")
        ])

      [digest] = plan.armed
      assert digest.title == "2 reminders"
      assert digest.body == "Wilderness · Porridge"
      assert digest.meta.domains == [:tv, :meals]
    end

    test "a body longer than three names says how many more" do
      plan =
        plan(
          for {name, minute} <- Enum.with_index(~w(One Two Three Four Five)) do
            episode("ep:#{minute}", DateTime.add(~U[2026-08-22 08:00:00Z], minute, :minute),
              title: name
            )
          end
        )

      [digest] = plan.armed
      assert digest.title == "5 new episodes"
      assert digest.body == "One · Two · Three and 2 more"
    end

    test "ten minutes apart is far enough to stay two notifications" do
      plan =
        plan([
          episode("ep:a", ~U[2026-08-22 08:00:00Z]),
          episode("ep:b", ~U[2026-08-22 08:10:00Z])
        ])

      assert Plan.armed_ids(plan) == ["ep:a", "ep:b"]
      assert Plan.suppressed(plan, :digested) == []
    end

    test "however densely they are packed, no two armed alarms are within nine minutes" do
      # Sixty entries at three-minute intervals: a naive chain that measured each
      # gap against the previous member would keep every one of them.
      dense =
        for n <- 0..59 do
          episode("ep:#{n}", DateTime.add(@now, 3600 + n * 180, :second))
        end

      plan = plan(dense, platform: :android)

      gaps =
        plan.armed
        |> Enum.map(& &1.fire_at)
        |> Enum.chunk_every(2, 1, :discard)
        |> Enum.map(fn [a, b] -> DateTime.diff(b, a) end)

      assert gaps != []
      assert Enum.all?(gaps, &(&1 >= Digest.min_gap()))

      # And nothing was quietly dropped on the way: every entry is either armed
      # on its own or folded into a digest that is.
      folded = Plan.suppressed(plan, :digested)
      singles = Enum.reject(plan.armed, &Map.get(&1.meta, :digest, false))
      assert length(folded) + length(singles) == 60
      assert plan.suppressed == folded
    end

    test "no digest ever delays a member" do
      dense =
        for n <- 0..29 do
          episode("ep:#{n}", DateTime.add(@now, 3600 + n * 120, :second))
        end

      plan = plan(dense, platform: :android)
      digests = Map.new(plan.armed, &{&1.id, &1})

      for member <- Plan.suppressed(plan, :digested) do
        digest = Map.fetch!(digests, member.meta.into)
        assert DateTime.compare(digest.fire_at, member.fire_at) != :gt
      end
    end

    test "the floor can be lifted, and then every entry stays discrete" do
      plan =
        plan(
          [
            episode("ep:a", ~U[2026-08-22 08:00:00Z]),
            episode("ep:b", ~U[2026-08-22 08:03:00Z]),
            episode("ep:c", ~U[2026-08-22 08:06:00Z])
          ],
          min_gap: false
        )

      assert Plan.armed_ids(plan) == ["ep:a", "ep:b", "ep:c"]
    end

    test "the night's pile-up becomes one morning" do
      # Quiet hours put three reminders on the same instant; the digest is what
      # makes that a summary rather than three alarms Android would throttle.
      plan =
        plan([
          episode("ep:a", ~U[2026-08-21 23:10:00Z], title: "Wilderness"),
          episode("ep:b", ~U[2026-08-21 23:40:00Z], title: "The Estuary"),
          episode("ep:c", ~U[2026-08-22 02:00:00Z], title: "Nightjar")
        ])

      assert Plan.pending_count(plan) == 1
      [digest] = plan.armed

      assert digest.fire_at == ~U[2026-08-22 08:00:00Z]
      assert digest.members == ["ep:a", "ep:b", "ep:c"]
      assert length(Plan.suppressed(plan, :digested)) == 3
    end
  end

  describe "wall-clock entries rebuild when the user flies" do
    test "a 09:00 habit is 09:00 wherever the phone is" do
      habit = Candidate.wall_clock("habit:3", :habits, ~N[2026-08-22 09:00:00], nil, title: "Run")
      fixed = episode("ep:air", ~U[2026-08-22 17:00:00Z])

      amsterdam = plan([habit, fixed], zone: "Europe/Amsterdam")
      tehran = plan([habit, fixed], zone: "Asia/Tehran")

      assert Plan.find(amsterdam, "habit:3").fire_at == ~U[2026-08-22 07:00:00Z]
      assert Plan.find(tehran, "habit:3").fire_at == ~U[2026-08-22 05:30:00Z]

      # The air date is a fact about the world and does not follow the traveller.
      assert Plan.find(amsterdam, "ep:air").fire_at == ~U[2026-08-22 17:00:00Z]
      assert Plan.find(tehran, "ep:air").fire_at == ~U[2026-08-22 17:00:00Z]
    end

    test "an entry may pin its own zone instead of following the device" do
      pinned =
        Candidate.wall_clock("habit:9", :habits, ~N[2026-08-22 12:00:00], "Asia/Tehran",
          title: "Call home"
        )

      # Noon in Tehran, planned on a phone in Amsterdam: the wall clock follows
      # the zone it named, and quiet hours still answer to the device's.
      assert Plan.find(plan([pinned], zone: "Europe/Amsterdam"), "habit:9").fire_at ==
               ~U[2026-08-22 08:30:00Z]
    end

    test "a wall clock in a spring-forward gap fires AFTER the jump, not never" do
      # 01:30 does not exist in London on 29 March 2026. Kati.Time's answer is
      # `after`; quiet hours are off here because the point of the test is the
      # resolution, not the manners.
      habit =
        Candidate.wall_clock("habit:gap", :habits, ~N[2026-03-29 01:30:00], "Europe/London")

      plan =
        plan([habit], now: ~U[2026-03-01 10:00:00Z], quiet_hours: false)

      assert Plan.find(plan, "habit:gap").fire_at == ~U[2026-03-29 01:00:00Z]
    end

    test "a wall clock that happens twice fires at the FIRST of them" do
      habit =
        Candidate.wall_clock("habit:twice", :habits, ~N[2026-10-25 01:30:00], "Europe/London")

      plan = plan([habit], now: ~U[2026-10-01 10:00:00Z], quiet_hours: false)

      assert Plan.find(plan, "habit:twice").fire_at == ~U[2026-10-25 00:30:00Z]
    end

    test "a zone nothing recognises is a bad row, not a crash" do
      broken = Candidate.wall_clock("habit:x", :habits, ~N[2026-08-22 07:00:00], "Mars/Olympus")

      plan = plan([broken])

      assert plan.armed == []
      assert Plan.reason(plan, "habit:x") == :no_date
    end
  end

  describe "reconciliation" do
    setup do
      candidates = [
        episode("ep:a", ~U[2026-08-22 17:00:00Z]),
        episode("ep:b", ~U[2026-08-23 17:00:00Z]),
        Candidate.absolute("ev:1", :calendar, ~U[2026-08-24 09:00:00Z], title: "Dentist")
      ]

      {:ok, candidates: candidates, plan: plan(candidates)}
    end

    test "from nothing armed, everything is armed soonest first", %{plan: plan} do
      operations = Reconcile.operations(plan, [])

      assert operations == [
               {:arm, Plan.find(plan, "ep:a")},
               {:arm, Plan.find(plan, "ep:b")},
               {:arm, Plan.find(plan, "ev:1")}
             ]
    end

    test "running it again changes nothing", %{plan: plan} do
      armed = plan |> Reconcile.operations([]) |> apply_ops([])

      assert length(armed) == 3
      assert Reconcile.operations(plan, armed) == []
    end

    test "an entry whose time moved is re-armed, and not cancelled first", %{
      candidates: candidates,
      plan: plan
    } do
      armed = plan |> Reconcile.operations([]) |> apply_ops([])

      moved =
        Enum.map(candidates, fn
          %{id: "ep:b"} = candidate -> episode(candidate.id, ~U[2026-08-30 17:00:00Z])
          candidate -> candidate
        end)

      operations = Reconcile.operations(plan(moved), armed)

      # The id is stable, so arming it again is an upsert. A cancel here would
      # be a window in which the reminder does not exist.
      assert [{:arm, %{id: "ep:b", fire_at: ~U[2026-08-30 17:00:00Z]}}] = operations
    end

    test "an entry that no longer exists is cancelled, before anything is armed", %{
      candidates: candidates,
      plan: plan
    } do
      armed = plan |> Reconcile.operations([]) |> apply_ops([])

      remaining = Enum.reject(candidates, &(&1.id == "ep:a"))
      later = plan(remaining ++ [episode("ep:new", ~U[2026-08-29 17:00:00Z])])

      assert [{:cancel, "ep:a"} | arms] = Reconcile.operations(later, armed)
      assert Enum.map(arms, fn {:arm, candidate} -> candidate.id end) == ["ep:new"]
    end

    test "interrupted halfway, the next run asks for exactly what is left", %{plan: plan} do
      operations = Reconcile.operations(plan, [])
      {done, remaining} = Enum.split(operations, 1)

      # No transaction exists — AshSqlite reports can?(:transact) == false — so
      # this is the state the loop has to be able to resume from.
      partial = apply_ops(done, [])

      assert Reconcile.operations(plan, partial) == remaining
      assert plan |> Reconcile.operations(partial) |> apply_ops(partial) |> length() == 3
    end

    test "a budget-shed entry that was armed last time is cancelled" do
      first =
        plan(
          for n <- 0..3,
              do: Candidate.absolute("m:#{n}", :money, DateTime.add(@now, 86_400 * (n + 1)))
        )

      armed = first |> Reconcile.operations([]) |> apply_ops([])
      assert length(armed) == 4

      # A fifth, sooner renewal appears. Money holds four slots on iOS, so the
      # furthest-future one has to go — and go from the platform too.
      second =
        plan([
          Candidate.absolute("m:new", :money, DateTime.add(@now, 3600))
          | Enum.map(
              0..3,
              &Candidate.absolute("m:#{&1}", :money, DateTime.add(@now, 86_400 * (&1 + 1)))
            )
        ])

      assert Plan.reason(second, "m:3") == :over_budget
      assert [{:cancel, "m:3"}, {:arm, %{id: "m:new"}}] = Reconcile.operations(second, armed)
    end

    test "an alarm whose moment passed while the phone was off is reported, not re-armed" do
      armed = [
        %Armed{id: "ep:missed", fire_at: ~U[2026-08-20 17:00:00Z], fingerprint: 1},
        %Armed{id: "ep:soon", fire_at: ~U[2026-08-25 17:00:00Z], fingerprint: 2}
      ]

      assert Reconcile.missed(armed, @now) |> Enum.map(& &1.id) == ["ep:missed"]

      # And it is not in the next plan either — a day-old reminder is noise.
      plan = plan([episode("ep:missed", ~U[2026-08-20 17:00:00Z])])
      assert plan.armed == []
      assert Plan.reason(plan, "ep:missed") == :past
    end

    test "Scheduler.reconcile/3 plans and diffs in one call", %{candidates: candidates} do
      {plan, operations} =
        Scheduler.reconcile(candidates, [], platform: :ios, now: @now, zone: "Etc/UTC")

      assert Plan.pending_count(plan) == 3
      assert length(operations) == 3
      assert Enum.all?(operations, &match?({:arm, _}, &1))
    end
  end

  describe "delivery is a backend the scheduler never names" do
    test "operations are performed in order and reported back" do
      plan =
        plan([
          episode("ep:a", ~U[2026-08-22 17:00:00Z]),
          episode("ep:b", ~U[2026-08-23 17:00:00Z])
        ])

      operations = [{:cancel, "ep:gone"} | Reconcile.operations(plan, [])]
      result = Delivery.run(operations, Recorder)

      assert result.cancelled == ["ep:gone"]
      assert result.armed == ["ep:a", "ep:b"]
      assert result.errors == []

      assert_received {:cancelled, "ep:gone"}
      assert_received {:armed, "ep:a"}
      assert_received {:armed, "ep:b"}
    end

    test "a backend that fails is a diagnostic line, not a dead UI" do
      plan = plan([episode("ep:a", ~U[2026-08-22 17:00:00Z])])
      result = plan |> Reconcile.operations([]) |> Delivery.run(Denied)

      assert result.armed == []
      assert [{{:arm, %{id: "ep:a"}}, :permission_denied}] = result.errors
    end

    test "the inert backend arms nothing and still succeeds" do
      plan = plan([episode("ep:a", ~U[2026-08-22 17:00:00Z])])
      result = plan |> Reconcile.operations([]) |> Delivery.run(Kati.Notifications.Delivery.Inert)

      assert result.armed == ["ep:a"]
      assert result.errors == []

      # The plan is what the in-app inbox badge renders when the OS permission
      # was denied, so it still has to be complete.
      assert Plan.pending_count(plan) == 1
    end
  end

  describe "exactly one module arms or cancels a notification" do
    test "no decision-layer module calls a platform notification API" do
      offenders =
        for path <- Path.wildcard(Path.join(@lib, "kati/notifications/**/*.ex")),
            not String.contains?(path, "notifications/delivery"),
            source = File.read!(path),
            source =~ ~r/(MobNotify|KatiNotificationStore|UNUserNotificationCenter)\.\w+\(/,
            do: Path.relative_to(path, @lib)

      assert offenders == [],
             "the scheduler must not know which platform it is on: #{inspect(offenders)}"
    end

    test "no domain module arms its own notifications" do
      offenders =
        for path <- Path.wildcard(Path.join(@lib, "**/*.ex")),
            not String.contains?(path, "kati/notifications/"),
            source = File.read!(path),
            source =~ ~r/(MobNotify|KatiNotificationStore)\.(schedule|cancel)\(/,
            do: Path.relative_to(path, @lib)

      assert offenders == [],
             "notifications are armed through Kati.Notifications.Delivery only: " <>
               inspect(offenders)
    end
  end
end
