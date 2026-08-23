defmodule Kati.Notifications.Pending do
  @moduledoc """
  Every notification Kati believes is armed on the platform, on disk.

  ## Why this is a table and not `Mob.State`

  #59 says so and the reason is capacity. `Mob.State` is `:dets` and the
  framework's own research describes it as *"O(dozens) of keys — themes,
  onboarding flags, cached IDs"*. The pending set is up to **480 rows** on
  Android — one per intended notification across six domains — and it is
  rewritten on every foreground and every successful worker run. That is a
  table.

  ## Why Kati keeps this at all rather than asking the OS

  `Kati.Notifications.Armed` gives the full answer: neither platform can be
  asked usefully. Android exposes no list of pending alarms, and iOS's list is
  asynchronous and reflects only what the system chose to keep after its own
  silent truncation — reconciling against it would mean treating a truncation as
  an intention.

  So this is Kati's own bookkeeping, and `Kati.Notifications.Reconcile`'s job is
  to make the platform match it.

  ## The id is deterministic, and that is what makes reconcile cheap

  `ep:1396:5:14`, `habit:3:2026-08-18` — domain-prefixed and derived from what
  the reminder is *about*, never generated. Two runs that mean the same
  reminder produce the same id, so an unchanged entry is recognised rather than
  cancelled and re-armed. `Kati.Notifications.Candidate.fingerprint/1` then
  decides whether it changed.

  ## `armed_at` is null for a row that is intended and not yet armed

  The distinction matters on exactly one screen: the diagnostic (#26) reports
  how many reminders are armed, and a row Kati meant to arm and did not is not
  one of them. Nothing decides on it — `Kati.Notifications.Reconcile` works from
  `fire_at` and `fingerprint` — which is why it can be null without any code
  path having to handle the case.

  ## What is not here

  No `title` or `body` **column**. They are inputs to the notification rather
  than facts about it, they are recomputed from the domain on every plan, and
  storing them would mean a reminder whose show was renamed firing under its old
  name. `Kati.Notifications.Candidate` carries them for the length of a plan and
  no longer.
  """

  use Ash.Resource, domain: Kati.Notifications, data_layer: AshSqlite.DataLayer

  alias Kati.Notifications.Armed
  alias Kati.Notifications.Budget
  alias Kati.Notifications.Candidate

  sqlite do
    table "notification_pending"
    repo Kati.Repo

    custom_indexes do
      # The reconcile loop's own read: everything still to come, soonest first.
      index [:fire_at_utc]
      # The diagnostic's per-domain count, and the budget's shed set.
      index [:domain, :fire_at_utc]
    end
  end

  attributes do
    # The deterministic id IS the primary key — see the moduledoc. A generated
    # uuid beside it would mean two identities for one reminder and a reconcile
    # that had to reconcile them.
    attribute :id, :string, primary_key?: true, allow_nil?: false, public?: true

    attribute :domain, :atom,
      allow_nil?: false,
      public?: true,
      constraints: [one_of: Budget.domains()]

    attribute :fire_at_utc, :utc_datetime, allow_nil?: false, public?: true

    # `:wall_clock` entries move when the device's zone changes and `:absolute`
    # ones do not. Stored because a re-plan after a flight has to know which
    # rows to recompute, and the answer is not derivable from the instant.
    attribute :kind, :atom,
      allow_nil?: false,
      default: :absolute,
      public?: true,
      constraints: [one_of: [:absolute, :wall_clock]]

    # The zone a wall-clock entry was resolved in. Null for an absolute one,
    # which is what makes "did the zone change under this row" answerable.
    attribute :tz, :string, public?: true

    attribute :priority, :atom,
      allow_nil?: false,
      default: :normal,
      public?: true,
      constraints: [one_of: [:high, :normal, :low]]

    # `Kati.Notifications.Candidate.fingerprint/1` at the moment it was armed.
    # An unchanged entry is left alone rather than cancelled and re-armed.
    attribute :fingerprint, :integer, allow_nil?: false, public?: true

    # Null means intended and not yet armed — see the moduledoc.
    attribute :armed_at, :utc_datetime, public?: true

    timestamps()
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]

    read :upcoming do
      description "Everything still to come, soonest first — the reconcile loop's read."
      argument :now, :utc_datetime, allow_nil?: false
      filter expr(fire_at_utc >= ^arg(:now))
      prepare build(sort: [fire_at_utc: :asc])
    end

    read :for_domain do
      description "One domain's pending set, soonest first."
      argument :domain, :atom, allow_nil?: false
      filter expr(domain == ^arg(:domain))
      prepare build(sort: [fire_at_utc: :asc])
    end
  end

  @doc """
  The row a candidate becomes once it has been armed.

  Takes the armed instant rather than reading a clock, for the reason every
  other function in this domain does: a scheduler that reads the clock cannot
  be tested against one.
  """
  @spec from_candidate(Candidate.t(), DateTime.t() | nil) :: map()
  def from_candidate(%Candidate{} = candidate, armed_at \\ nil) do
    %{
      id: candidate.id,
      domain: candidate.domain,
      fire_at_utc: candidate.fire_at,
      kind: Kati.Notifications.Pending.kind_of(candidate),
      tz: Kati.Notifications.Pending.zone_of(candidate),
      priority: candidate.priority,
      fingerprint: Candidate.fingerprint(candidate),
      armed_at: armed_at
    }
  end

  @doc """
  Whether a candidate's time is a wall-clock one or an absolute instant.

  `Kati.Notifications.Candidate.at` is either a `DateTime` — an instant, which
  does not move — or a `{Date, Time}` pair, which is a wall-clock intention and
  resolves differently in a different zone. That distinction is the whole reason
  a re-plan after a timezone change produces new instants for some rows and
  identical ones for others.
  """
  @spec kind_of(Candidate.t()) :: :absolute | :wall_clock
  def kind_of(%Candidate{at: %DateTime{}}), do: :absolute
  def kind_of(%Candidate{}), do: :wall_clock

  @doc "The zone a wall-clock candidate resolved in, or `nil` for an absolute one."
  @spec zone_of(Candidate.t()) :: String.t() | nil
  def zone_of(%Candidate{at: %DateTime{}}), do: nil
  def zone_of(%Candidate{fire_at: %DateTime{time_zone: zone}}), do: zone
  def zone_of(%Candidate{}), do: nil

  @doc """
  The in-memory shape `Kati.Notifications.Reconcile` works on.

  The reconcile layer is a pure function over lists and knows nothing about a
  store — which is what let the store arrive after it. This is the one function
  that crosses between them.
  """
  @spec to_armed(t()) :: Armed.t()
  def to_armed(%__MODULE__{} = row) do
    %Armed{
      id: row.id,
      fire_at: row.fire_at_utc,
      fingerprint: row.fingerprint,
      armed_at: row.armed_at
    }
  end

  @type t :: %__MODULE__{}
end
