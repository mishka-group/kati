defmodule Kati.Notifications.Sources.Health do
  @moduledoc """
  Medication reminders — the highest-stakes notification Kati sends.

  `Kati.Health.Medication.times` exists for this and says so in its own comment:
  the user's `schedule` sentence is free text and deliberately unparsed, and
  `times` is the structured half *because `Kati.Notifications` arms from it*.
  Nothing here re-reads the sentence.

  ## One candidate per clock time, not per medication

  Three tablets at 08:00 is one thing that happens at 08:00. Waking someone
  three times for it teaches them to ignore the second and third, which is the
  failure mode a medication reminder cannot afford — so the doses at a time are
  **aggregated** into one candidate whose `members` are the medication ids.

  That is the same aggregation `Kati.Notifications.Candidate` already carries
  for every other domain, and it is why `members` is a list rather than a
  boolean: the sheet behind the notification can name all three.

  ## `wall_clock`, and `quiet_hours: :exempt`

  A dose is a wall-clock fact. *Take it at 08:00* means 08:00 wherever the user
  is standing, so these are `Kati.Notifications.Candidate.wall_clock/5` rather
  than instants — `Kati.Notifications.Candidate`'s own moduledoc argues the
  distinction, and this is the domain it was drawn for.

  They are also the one domain that is `:exempt` from quiet hours. Every other
  reminder in the app shifts out of the night window; a 21:00 dose that shifts
  to 08:00 is not a late reminder, it is the wrong instruction. Screen 112's
  reliability note already tells the user that reminders can be late and that
  Kati is not a medical device — shifting them silently would make that note a
  lie rather than a caveat.

  ## Priority is `:high`, which is a budget decision and not a loudness one

  `Kati.Notifications.Budget` allocates `:health` forty slots on Android and
  four on iOS, and when a domain overflows its share the scheduler drops by
  priority. `:high` says *if something in health has to go, this is not it.*
  """

  alias Kati.Health.Medication
  alias Kati.Notifications.Candidate

  @doc """
  A candidate per clock time on `day`, aggregating the medications due at each.

  Takes the rows rather than reading them, which is
  `Kati.Notifications.Sources.Media`'s shape and is the shape for the same
  reason: *six hundred candidates in, fifty out, and here are the fifty* is an
  assertion about a value, and a function that reads its own input cannot be
  asked it. `active/0` is the reader.

  `opts` takes `:zone`, which defaults to the device's. A medication with no
  times contributes a suppressed candidate rather than nothing, because *this
  medication never reminds me* has to be answerable and `:no_times` is the
  answer — screen 112 lets a schedule be a sentence with no clock in it.
  """
  @spec candidates([Medication.t()], Date.t(), keyword()) :: [Candidate.t()]
  def candidates(medications, %Date{} = day, opts \\ []) when is_list(medications) do
    zone = Keyword.get(opts, :zone) || Kati.Time.device_zone()

    Enum.concat(untimed(medications), timed(medications, day, zone))
  end

  @doc "The medications still being taken, or `[]` when the store cannot answer."
  @spec active() :: [Medication.t()]
  def active do
    Medication
    |> Ash.Query.for_read(:active)
    |> Ash.read()
    |> case do
      {:ok, rows} -> rows
      _error -> []
    end
  rescue
    _error -> []
  end

  @doc """
  The stable id for one clock time's dose group. Shared with the Kotlin worker.

  The colon comes out — `"08:00"` becomes `"0800"` — because
  `Kati.Notifications.Candidate.id/1` refuses a part containing one, and it
  refuses for a reason worth keeping: an id that can be built two ways from two
  identities is an id that can collide, and a collision here is one reminder
  silently replacing another.
  """
  @spec id(Date.t(), String.t()) :: String.t()
  def id(%Date{} = day, at) when is_binary(at),
    do: Candidate.id(["dose", day, String.replace(at, ":", "")])

  # A medication with a schedule but no parsed time. Suppressed rather than
  # absent — see the moduledoc on `:no_times`.
  defp untimed(medications) do
    for %Medication{times: []} = medication <- medications do
      Candidate.suppressed(Candidate.id(["dose", medication.id]), :health, :no_times,
        title: medication.name,
        meta: %{medication_id: medication.id}
      )
    end
  end

  defp timed(medications, day, zone) do
    medications
    |> Enum.flat_map(fn medication ->
      Enum.map(medication.times, &{&1, medication})
    end)
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.map(fn {at, group} -> group_candidate(day, at, group, zone) end)
    |> Enum.reject(&is_nil/1)
  end

  defp group_candidate(day, at, group, zone) do
    case wall(day, at) do
      {:ok, wall} ->
        Candidate.wall_clock(id(day, at), :health, wall, zone,
          title: title(group),
          body: body(group),
          priority: :high,
          quiet_hours: :exempt,
          members: Enum.map(group, & &1.id),
          meta: %{at: at, count: length(group)}
        )

      :error ->
        nil
    end
  end

  # `"08:00"`, the shape screen 112 writes. A row whose time does not parse is
  # dropped rather than guessed at: arming a medication reminder at a time the
  # app invented is worse than not arming it.
  defp wall(day, at) do
    with {:ok, time} <- Time.from_iso8601(at <> ":00"),
         {:ok, naive} <- NaiveDateTime.new(day, time) do
      {:ok, naive}
    else
      _error -> :error
    end
  end

  defp title([%Medication{name: name}]), do: name
  defp title(group), do: "#{length(group)} doses"

  defp body([%Medication{} = one]) do
    [one.dose, one.instruction]
    |> Enum.reject(&(is_nil(&1) or &1 == ""))
    |> Enum.join(" · ")
    |> case do
      "" -> "Due now"
      line -> line
    end
  end

  defp body(group), do: group |> Enum.map_join(", ", & &1.name)
end
