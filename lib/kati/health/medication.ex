defmodule Kati.Health.Medication do
  @moduledoc """
  A thing you take, and when you are meant to take it.

  ## The schedule is text, and that is deliberate

  `every morning, 08:00` and `Mon, Wed, Fri` are what screen 112 prints, and
  they are stored as written rather than parsed into a rule. `Kati.Recurrence`
  exists and could express both — and using it here would mean Kati deciding
  what your prescription says, which is precisely the line the screen's own
  footnote draws: *Kati is not a medical device and gives no medical advice —
  it only records what you tell it.*

  What is structured is `times`, the list of clock times a dose is due, because
  that is what `Kati.Notifications` needs to arm a reminder. Everything else
  about the schedule is the user's sentence about their own prescription.

  ## `dose` is text too

  `50 mcg`, `1000 IU`, `65 mg`. A number and a unit would need a unit
  vocabulary, and the vocabulary of medicine doses is not one an app should be
  guessing at — `IU` is not convertible to `mg` without knowing the substance.
  """

  use Ash.Resource, domain: Kati.Health, data_layer: AshSqlite.DataLayer

  sqlite do
    table "health_medications"
    repo Kati.Repo

    custom_indexes do
      index [:name]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string, allow_nil?: false, public?: true
    attribute :dose, :string, public?: true

    # The user's own sentence — see the moduledoc.
    attribute :schedule, :string, public?: true

    # The clock times a dose is due, `"08:00"` each. Structured because
    # `Kati.Notifications` arms from it; everything else about the schedule is
    # not.
    attribute :times, {:array, :string}, allow_nil?: false, default: [], public?: true

    # `before food`, `with water`. Printed under the dose on screen 112 and in
    # the reminder itself, because an instruction that only appears in the app
    # is an instruction nobody reads at 21:00.
    attribute :instruction, :string, public?: true

    attribute :active, :boolean, allow_nil?: false, default: true, public?: true

    timestamps()
  end

  relationships do
    has_many :doses, Kati.Health.Dose do
      destination_attribute :medication_id
      public? true
    end
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]

    read :active do
      description "The medications still being taken — screen 112's Schedules group."
      filter expr(active == true)
      prepare build(sort: [name: :asc])
    end
  end

  @doc "The row's second line: `50 mcg · every morning, 08:00`."
  @spec schedule_line(t()) :: String.t()
  def schedule_line(%__MODULE__{dose: dose, schedule: schedule}) do
    [dose, schedule] |> Enum.reject(&(is_nil(&1) or &1 == "")) |> Enum.join(" · ")
  end

  @doc "The dose line on a today row: `50 mcg · before food`, or as much as is known."
  @spec dose_line(t()) :: String.t()
  def dose_line(%__MODULE__{dose: dose, instruction: instruction}) do
    [dose, instruction] |> Enum.reject(&(is_nil(&1) or &1 == "")) |> Enum.join(" · ")
  end

  @type t :: %__MODULE__{}
end
