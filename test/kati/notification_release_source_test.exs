defmodule Kati.Notifications.Sources.MediaTest do
  @moduledoc """
  Release reminders reach the scheduler through #74's gate, or not at all.

  `Kati.Media.Release.alarm_at/3` refuses a muted show and a vague date at the
  same gate, deliberately, *"so a caller cannot accidentally honour one rule and
  forget the other"*. These tests are the proof that the notification layer is
  such a caller: not that it applies the same rules, which would be a second
  implementation to keep in step, but that both refusals arrive in the plan with
  the gate's own word on them.

  The last test does it against a real database, because `followed/0` is the
  path the app actually takes and a rule proved only against hand-built structs
  is a rule proved only against hand-built structs.
  """
  use ExUnit.Case, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Notifications.Plan
  alias Kati.Notifications.Scheduler
  alias Kati.Notifications.Sources.Media

  @now ~U[2026-08-21 10:00:00Z]
  @new_years_day ~U[2026-01-01 00:00:00.000000Z]

  setup do
    {:ok, prefix: "ns#{System.unique_integer([:positive])}-"}
  end

  defp tracked(attrs \\ []) do
    struct(
      %TrackedTitle{
        source: :tmdb,
        source_id: "603692",
        kind: :tv,
        notify_new_episodes: true
      },
      attrs
    )
  end

  defp cached(confidence, at \\ @new_years_day, attrs \\ []) do
    struct(
      %CachedTitle{
        source: :tmdb,
        source_id: "603692",
        kind: :tv,
        title: "Wilderness",
        next_release_at: at,
        date_confidence: confidence,
        fetched_at: ~U[2026-08-01 00:00:00.000000Z]
      },
      attrs
    )
  end

  defp plan(candidates) do
    Scheduler.plan(candidates, platform: :ios, now: @now, zone: "Etc/UTC", quiet_hours: false)
  end

  describe "the gate's refusals travel into the plan" do
    test "a muted title never schedules, and the plan says muted" do
      muted = tracked(notify_new_episodes: false)
      exact_and_soon = cached(:exact, ~U[2026-08-22 19:00:00Z])

      candidate = Media.candidate({muted, exact_and_soon}, zone: "Etc/UTC")
      plan = plan([candidate])

      assert plan.armed == []
      assert Plan.reason(plan, "ep:tmdb:603692") == :muted
      assert Plan.pending_count(plan) == 0
    end

    test "a year-confidence release never schedules, and 1 January appears nowhere" do
      vague = cached(:year, @new_years_day)

      candidate = Media.candidate({tracked(), vague}, zone: "Etc/UTC")
      plan = plan([candidate])

      assert plan.armed == []
      assert Plan.reason(plan, "ep:tmdb:603692") == :low_confidence
      assert candidate.fire_at == nil
    end

    test "an exact date does schedule — which is what makes the two above mean something" do
      candidate =
        Media.candidate({tracked(), cached(:exact, ~U[2026-08-22 19:00:00Z])}, zone: "Etc/UTC")

      plan = plan([candidate])

      assert Plan.armed_ids(plan) == ["ep:tmdb:603692"]
      entry = Plan.find(plan, "ep:tmdb:603692")
      assert entry.fire_at == ~U[2026-08-22 19:00:00Z]
      assert entry.title == "Wilderness"
      assert entry.body == "New episode out today"
      assert entry.domain == :tv
      assert entry.meta.source_id == "603692"
    end

    test "a date the user typed arms at 09:00, through the same gate" do
      corrected = tracked(user_override_date: ~D[2026-11-14])

      plan = plan([Media.candidate({corrected, cached(:year)}, zone: "Etc/UTC")])

      assert Plan.find(plan, "ep:tmdb:603692").fire_at == ~U[2026-11-14 09:00:00Z]
    end

    test "an evicted cache costs the notification its name and not its existence" do
      corrected = tracked(user_override_date: ~D[2026-11-14])

      plan = plan([Media.candidate({corrected, nil}, zone: "Etc/UTC")])

      entry = Plan.find(plan, "ep:tmdb:603692")
      assert entry.fire_at == ~U[2026-11-14 09:00:00Z]
      assert entry.title == "A title you follow"
    end

    test "a library of three produces one alarm and two stated reasons" do
      candidates =
        Media.candidates(
          [
            {tracked(source_id: "1"), cached(:exact, ~U[2026-08-22 19:00:00Z], source_id: "1")},
            {tracked(source_id: "2", notify_new_episodes: false),
             cached(:exact, ~U[2026-08-23 19:00:00Z], source_id: "2")},
            {tracked(source_id: "3"), cached(:year, @new_years_day, source_id: "3")}
          ],
          zone: "Etc/UTC"
        )

      plan = plan(candidates)

      assert Plan.armed_ids(plan) == ["ep:tmdb:1"]
      assert Plan.reason(plan, "ep:tmdb:2") == :muted
      assert Plan.reason(plan, "ep:tmdb:3") == :low_confidence
      assert Plan.reasons(plan) == %{muted: 1, low_confidence: 1}
    end
  end

  describe "ids" do
    test "the prefix is #58's cross-language contract" do
      assert Media.id(tracked(source_id: "1396")) == "ep:tmdb:1396"
      assert Media.episode_id(:tmdb, "1396", 5, 14) == "ep:tmdb:1396:5:14"
    end
  end

  describe "against the database the app actually reads" do
    test "followed titles become candidates, muted ones as refusals", %{prefix: prefix} do
      airs_soon = track!(prefix, "1", %{})
      muted = track!(prefix, "2", %{notify_new_episodes: false})
      vague = track!(prefix, "3", %{})
      dropped = track!(prefix, "4", %{status: :dropped})

      cache!(airs_soon, %{
        next_release_at: ~U[2026-08-22 19:00:00Z],
        date_confidence: :exact,
        title: "Wilderness"
      })

      cache!(muted, %{next_release_at: ~U[2026-08-23 19:00:00Z], date_confidence: :exact})
      cache!(vague, %{next_release_at: @new_years_day, date_confidence: :year})
      cache!(dropped, %{next_release_at: ~U[2026-08-24 19:00:00Z], date_confidence: :exact})

      mine =
        Media.followed()
        |> Enum.filter(fn {title, _cached} -> String.starts_with?(title.source_id, prefix) end)
        |> Media.candidates(zone: "Etc/UTC")

      # The dropped title is excluded by TrackedTitle's own :followed action —
      # this layer does not get a second opinion about what "followed" means.
      assert length(mine) == 3

      plan = plan(mine)

      assert Plan.armed_ids(plan) == [Media.id(airs_soon)]
      assert Plan.find(plan, Media.id(airs_soon)).title == "Wilderness"
      assert Plan.reason(plan, Media.id(muted)) == :muted
      assert Plan.reason(plan, Media.id(vague)) == :low_confidence
      assert Plan.reason(plan, Media.id(dropped)) == nil
    end
  end

  defp track!(prefix, suffix, attrs) do
    TrackedTitle
    |> Ash.Changeset.for_create(
      :create,
      Map.merge(%{source: :tmdb, source_id: prefix <> suffix, kind: :tv}, attrs)
    )
    |> Ash.create!()
  end

  defp cache!(%TrackedTitle{} = tracked, attrs) do
    CachedTitle
    |> Ash.Changeset.for_create(
      :create,
      Map.merge(
        %{
          source: tracked.source,
          source_id: tracked.source_id,
          kind: :tv,
          fetched_at: DateTime.utc_now()
        },
        attrs
      )
    )
    |> Ash.create!()
  end
end
