defmodule Kati.Notifications.Inbox do
  @moduledoc """
  What Kati would tell you, gathered from every domain, in one list.

  ## Why an inbox at all

  Kati's notification manners are deliberate and they are the thing the app is
  quietest about: push is **off by default**, quiet hours run 23:00–08:00,
  reminders stop after two skips, and a weekly digest replaces a stream of
  individual pushes. An app that arranges to interrupt you less has to put what
  it did not interrupt you with somewhere, or "quiet" and "broken" look
  identical.

  This is that somewhere. It is the badge on the bell rather than a push.

  ## It reads the plan, not the platform

  `Kati.Notifications.Scheduler.plan/2` already decides which reminders exist,
  when, and which were shed — per domain, against a real budget, with quiet
  hours and the digest applied. The inbox is a **presentation** of that plan
  and computes nothing of its own, which is what stops the badge and the alarms
  from ever disagreeing.

  Three groups, and each answers a different question:

    * **Now** — armed for today. What you are about to be told.
    * **Later** — armed beyond today. What is coming.
    * **Held back** — suppressed, each with the reason it was. This is the
      group that makes the quiet defensible: `muted`, `quiet hours`, `budget`
      and `digest` are decisions, and a user who can see them can tell the
      difference between an app being polite and an app being broken.

  ## Aggregation is by domain, exactly as the budget is

  `Kati.Notifications.Budget.domains/0` is the list, and the inbox does not keep
  a second one. A new domain arrives in the budget and appears here on the same
  day, with no edit to this module.
  """

  alias Kati.Notifications.Budget
  alias Kati.Notifications.Candidate
  alias Kati.Notifications.Plan

  @doc """
  The inbox for a plan: `{now, later, held}`.

  `now` and `later` are split on the device's calendar day rather than on a
  rolling 24 hours, because *today* is what the header says and a reminder at
  23:50 belongs to tonight rather than to tomorrow.
  """
  @spec groups(Plan.t()) :: %{now: [Candidate.t()], later: [Candidate.t()], held: [Candidate.t()]}
  def groups(%Plan{armed: armed, suppressed: suppressed, now: now, zone: zone}) do
    today = now |> Kati.Time.in_zone(zone) |> DateTime.to_date()

    {today_armed, later} =
      Enum.split_with(armed, fn %Candidate{fire_at: at} ->
        at && Date.compare(at |> Kati.Time.in_zone(zone) |> DateTime.to_date(), today) != :gt
      end)

    %{now: today_armed, later: later, held: suppressed}
  end

  @doc """
  How many entries the bell's badge shows.

  The `now` group only. A badge counting everything Kati will ever tell you
  would be a number that never goes down, and a badge you cannot clear is a
  badge people learn to ignore.
  """
  @spec badge(Plan.t()) :: non_neg_integer()
  def badge(%Plan{} = plan), do: plan |> groups() |> Map.fetch!(:now) |> length()

  @doc """
  One line per domain: how many are armed, and how many the budget allows.

  Reads `Kati.Notifications.Budget.domains/0` rather than a list of its own —
  see the moduledoc. A domain with nothing armed still gets a row, because
  *nothing today* is an answer and an absent row is not.
  """
  @spec by_domain(Plan.t()) :: [{Budget.domain(), non_neg_integer(), pos_integer()}]
  def by_domain(%Plan{armed: armed, platform: platform}) do
    counts = Enum.frequencies_by(armed, & &1.domain)

    for domain <- Budget.domains() do
      {domain, Map.get(counts, domain, 0), Budget.limit(platform || :android, domain)}
    end
  end

  @doc """
  A domain's display name.

  Kati's own section names rather than the atoms — `Screen` and not `tv` — so
  the inbox reads in the vocabulary the rest of the app uses.
  """
  @spec domain_label(Budget.domain()) :: String.t()
  def domain_label(:calendar), do: "Calendar"
  def domain_label(:tv), do: "Screen"
  def domain_label(:habits), do: "Habits"
  def domain_label(:meals), do: "Meals"
  def domain_label(:health), do: "Health"
  def domain_label(:money), do: "Money"
  def domain_label(other), do: other |> Atom.to_string() |> String.capitalize()

  @doc "The glyph a domain's rows carry — the same one its section uses elsewhere."
  @spec domain_icon(Budget.domain()) :: String.t()
  def domain_icon(:calendar), do: "calendar_month"
  def domain_icon(:tv), do: "movie"
  def domain_icon(:habits), do: "bolt"
  def domain_icon(:meals), do: "restaurant"
  def domain_icon(:health), do: "monitor_heart"
  def domain_icon(:money), do: "payments"
  def domain_icon(_other), do: "notifications"

  @doc """
  Why a reminder was held back, in words rather than in an atom.

  Each names the decision and, where it is one, the setting that made it — a
  user who reads *quiet hours* should know which switch to look for.
  """
  @spec held_reason(atom() | nil) :: String.t()
  def held_reason(:muted), do: "Muted for this show"
  def held_reason(:quiet_hours), do: "Inside quiet hours — moved to the morning"
  def held_reason(:budget), do: "Beyond this section's share of the phone's alarms"
  def held_reason(:digest), do: "Rolled into the weekly digest"
  def held_reason(:skipped), do: "Stopped after two skips"
  def held_reason(nil), do: "Held back"

  def held_reason(other),
    do: other |> Atom.to_string() |> String.replace("_", " ") |> String.capitalize()

  @doc """
  What a row says when it has no title of its own.

  A candidate is allowed to carry no copy — `Kati.Notifications.Candidate`
  makes `title` and `body` nullable because the scheduler's job is *when*, not
  *what*. The inbox is the one place that has to print something anyway, so it
  falls back to the domain rather than to an empty row.
  """
  @spec title(Candidate.t()) :: String.t()
  def title(%Candidate{title: title}) when is_binary(title) and title != "", do: title
  def title(%Candidate{domain: domain}), do: domain_label(domain) <> " reminder"
end
