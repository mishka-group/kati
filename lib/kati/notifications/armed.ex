defmodule Kati.Notifications.Armed do
  @moduledoc """
  One notification Kati believes is armed on the platform right now.

  Kati keeps this record itself rather than asking the OS, because neither OS
  can be asked usefully. Android exposes no list of pending alarms at all, and
  the iOS list is asynchronous and reflects only what the system chose to keep
  after its own silent truncation — reconciling against it would mean treating a
  truncation as an intention. So the armed set is Kati's own bookkeeping, and
  the reconcile loop's job is to make the platform match it.

  The three fields are exactly what reconciliation needs and nothing more:

    * `id` — what to cancel, and how to recognise the same reminder next time.
    * `fire_at` — the *expected* fire time. This is Step 8's `expected_fire_at`:
      compared against `now` on foreground it is how Kati notices a missed alarm
      (`Kati.Notifications.Reconcile.missed/2`), which is the only way a device
      with no telemetry will ever learn that an OEM is eating its alarms.
    * `fingerprint` — `Kati.Notifications.Candidate.fingerprint/1` at the moment
      it was armed, so an unchanged entry can be left alone instead of re-armed.

  `armed_at` is kept for the diagnostic screen. Nothing decides on it.

  This is the in-memory shape of the `Kati.Notifications.Pending` rows #59's
  Step 1 describes; the persisted resource needs a generated migration and is
  deliberately not part of the decision layer. Everything here works on a list,
  so the store can arrive later without the scheduler noticing.
  """

  alias Kati.Notifications.Candidate

  @type t :: %__MODULE__{
          id: String.t(),
          fire_at: DateTime.t(),
          fingerprint: non_neg_integer(),
          armed_at: DateTime.t() | nil
        }

  defstruct [:id, :fire_at, :fingerprint, :armed_at]

  @doc "The record for a candidate that has just been armed."
  @spec from_candidate(Candidate.t(), DateTime.t() | nil) :: t()
  def from_candidate(%Candidate{} = candidate, armed_at \\ nil) do
    %__MODULE__{
      id: candidate.id,
      fire_at: candidate.fire_at,
      fingerprint: Candidate.fingerprint(candidate),
      armed_at: armed_at
    }
  end

  @doc "By id, for the O(1) lookups reconciliation does per candidate."
  @spec index([t()]) :: %{String.t() => t()}
  def index(armed) when is_list(armed) do
    Map.new(armed, fn %__MODULE__{} = record -> {record.id, record} end)
  end
end
