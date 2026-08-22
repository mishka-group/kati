defmodule Kati.Health.Dose do
  @moduledoc """
  One dose, on one day, and what happened to it.

  ## Three states, and they are screen 43's three

  Screen 112's caption: *doses reuse 43's meal-card treatment exactly — taken,
  missed and skipped are the same three states as eaten, skipped and upcoming.*
  So the vocabulary is deliberately parallel rather than medical, and the
  reason is that a person reading both pages should not have to learn two
  systems for *did this happen*.

  `:missed` is not something the user sets. It is what a `:due` dose becomes
  once its time has passed, and `resolve/2` is the only thing that decides it —
  which is why the state is stored as `:due` and read as `:missed`, rather than
  a background job rewriting rows at midnight.
  """

  use Ash.Resource, domain: Kati.Health, data_layer: AshSqlite.DataLayer

  sqlite do
    table "health_doses"
    repo Kati.Repo

    custom_indexes do
      # Screen 112's Today group.
      index [:due_on, :due_at]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :due_on, :date, allow_nil?: false, public?: true

    # The clock time, `"08:00"`. A string rather than a `Time`, so it is the
    # same shape as `Kati.Health.Medication.times` and the two cannot disagree
    # about what a due time is.
    attribute :due_at, :string, allow_nil?: false, public?: true

    attribute :state, :atom,
      allow_nil?: false,
      default: :due,
      public?: true,
      constraints: [one_of: [:due, :taken, :skipped]]

    attribute :recorded_at, :utc_datetime, public?: true

    timestamps()
  end

  relationships do
    belongs_to :medication, Kati.Health.Medication do
      allow_nil? false
      public? true
    end
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]

    read :for_day do
      description "One day's doses, in clock order — screen 112's Today group."
      argument :day, :date, allow_nil?: false
      filter expr(due_on == ^arg(:day))
      prepare build(sort: [due_at: :asc])
    end
  end

  @doc """
  What a dose reads as right now: `:taken`, `:skipped`, `:missed` or `:due`.

  `:missed` is derived rather than stored — see the moduledoc. A dose due at
  14:00 is `:due` at 13:59 and `:missed` at 14:01, and nothing has to run at
  midnight for that to be true.
  """
  @spec resolve(t(), DateTime.t()) :: :taken | :skipped | :missed | :due
  def resolve(%__MODULE__{state: state}, _now) when state in [:taken, :skipped], do: state

  def resolve(%__MODULE__{due_on: on, due_at: at}, %DateTime{} = now) do
    with [hour, minute] <- String.split(at, ":"),
         {hour, ""} <- Integer.parse(hour),
         {minute, ""} <- Integer.parse(minute),
         {:ok, time} <- Time.new(hour, minute, 0),
         {:ok, due} <- DateTime.new(on, time, now.time_zone) do
      if DateTime.compare(now, due) == :gt, do: :missed, else: :due
    else
      _other -> :due
    end
  end

  @doc "The suffix a today row prints after the dose: `· MISSED`, or nothing."
  @spec state_suffix(:taken | :skipped | :missed | :due) :: String.t() | nil
  def state_suffix(:missed), do: "MISSED"
  def state_suffix(:skipped), do: "SKIPPED"
  def state_suffix(_other), do: nil

  @type t :: %__MODULE__{}
end
