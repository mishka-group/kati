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

  ## A row is a RECORD, not a plan — D-59

  Nothing in `lib/` ever created one of these. The resource shipped with
  `create: :*` and the only writer that had ever existed was
  `Kati.Backup.Catalog`'s restore, which is exactly the sentence `D-43` wrote
  about `Kati.Health.Medication` before board 188 gave it a sheet. That was
  invisible while both tables were equally empty, and it stopped being
  invisible the afternoon 188 shipped: a person typed their first prescription
  and screen 112 answered with the drawing's four tablets over their own single
  schedule, one of them an Iron marked MISSED. Screen 20's rule, which this app
  writes into its own suite — *either every value on the page is this reader's
  or every value is the drawing's* — broken on the first medication rather than
  the hundredth.

  `D-59` settles which way it is fixed, and the answer is **derived**:

    * Today's list is composed from each active medication's `times` by
      `derive/2`. `times` is already this app's answer to *what is due today* —
      `Kati.Notifications.Sources.Health` reads it and nothing else to arm the
      reminder, and `Kati.Health.Medication`'s own comment says the field is
      structured *because `Kati.Notifications` arms from it*. So composing the
      day from it is the app agreeing with itself rather than a second source,
      and two sources for one question is how a page comes to disagree with
      itself in the first place.
    * A ROW is written the first time somebody marks a dose —
      `Kati.Screens.Medication.save_dose/2`'s create clause. That is the first
      moment there is anything to record: before it, a dose is a plan the
      schedule already states, and materialising rows at midnight would need a
      device that was awake at midnight and would answer *did I take it* on the
      user's behalf. `Kati.Screens.AddMedication`'s moduledoc refuses that in as
      many words for create time, and it is the same refusal here.

  So a row in `health_doses` means *somebody decided about this dose*, and its
  absence means nothing more than *not yet*. `merge/2` is where the two halves
  meet, and it is written so the stored half always wins.
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

  ## A derived dose cannot have been missed before its medication existed

  The argument above is an argument about a ROW: it existed at 14:00, the
  reminder for it was armed, and nobody answered — so `:missed` is a fair
  reading of the reader's own day. `derive/2` composes rows retroactively, and
  that premise does not survive the move. Somebody who opens board 188 at 15:00
  and saves the draft it opens with — Levothyroxine, `times: ["08:00"]` — has an
  08:00 dose composed for a time at which the app knew nothing about the
  medication and `Kati.Notifications.Sources.Health` had armed nothing forward.
  Reading it `:missed` puts `· MISSED` and the gold ✗ against the reader's own
  first prescription and asserts a failure that could not have happened, on the
  page whose own moduledoc says *did I take it* is the question a wrong answer
  costs the most.

  So a DERIVED dose — `id: nil`, carrying the medication `derive/2` put on it —
  whose clock time on `day` precedes that medication's `inserted_at` reads
  `:due` rather than `:missed`. The row is kept rather than dropped, because the
  reader may genuinely have taken the tablet before typing it in and the two
  verbs are how they say so; what is refused is the app saying it for them.

  A STORED row is untouched by this and has to be: `merge/2` lets it win its
  derived twin precisely because it is the record rather than the plan, and a
  row written before `times` was edited is still a row that existed at its own
  due time.
  """
  @spec resolve(t(), DateTime.t()) :: :taken | :skipped | :missed | :due
  def resolve(%__MODULE__{state: state}, _now) when state in [:taken, :skipped], do: state

  def resolve(%__MODULE__{due_on: on, due_at: at} = dose, %DateTime{} = now) do
    with [hour, minute] <- String.split(at, ":"),
         {hour, ""} <- Integer.parse(hour),
         {minute, ""} <- Integer.parse(minute),
         {:ok, time} <- Time.new(hour, minute, 0),
         {:ok, due} <- DateTime.new(on, time, now.time_zone),
         :gt <- DateTime.compare(now, due) do
      if retroactive?(dose, due), do: :due, else: :missed
    else
      _other -> :due
    end
  end

  # A derived dose composed for a clock time the medication cannot have been
  # able to miss — see `resolve/2`. Absence of a timestamp is not an answer
  # either way and reads as `false`: a bare `%Kati.Health.Dose{}` in a test, or
  # a stored row whose `:medication` was never loaded, keeps the plain clock
  # reading it has always had.
  #
  # **`updated_at` as well as `inserted_at`**, and the second one is the one
  # that took a review to find. `inserted_at` alone answers only *the
  # medication did not exist yet*, and `times` is editable for as long as the
  # medication is: `Kati.Screens.MedicationDetail`'s *add a time* appends the
  # earliest unused entry of `Kati.Screens.AddMedication`'s common times, so a
  # medication saved last week with `["21:00"]` grows an `08:00` at 14:00 today
  # and the plan then asserts a dose was missed at breakfast — a failure that
  # could not have happened, on the one page whose own moduledoc says a wrong
  # answer to *did I take it* costs the most.
  #
  # `updated_at` is the coarse witness rather than the exact one: it moves for
  # any edit, so renaming a medication this afternoon also forgives this
  # morning's genuinely missed dose until midnight. That is the safe direction
  # — the row stays `:due` and the two verbs are still how the reader says what
  # happened — and the exact witness is a column that does not exist
  # (`times_changed_at`, or per-time entries), which is a migration and a
  # decision rather than a fix. `derive/2` carries the whole medication struct,
  # so if that column is ever added this is the one clause that changes.
  defp retroactive?(%__MODULE__{id: nil, medication: %{} = medication}, %DateTime{} = due) do
    [Map.get(medication, :inserted_at), Map.get(medication, :updated_at)]
    |> Enum.any?(fn
      %DateTime{} = stamp -> DateTime.compare(stamp, due) == :gt
      _absent -> false
    end)
  end

  defp retroactive?(%__MODULE__{}, _due), do: false

  @doc "The suffix a today row prints after the dose: `· MISSED`, or nothing."
  @spec state_suffix(:taken | :skipped | :missed | :due) :: String.t() | nil
  def state_suffix(:missed), do: "MISSED"
  def state_suffix(:skipped), do: "SKIPPED"
  def state_suffix(_other), do: nil

  @doc """
  One day's doses composed from the medications themselves — UNSAVED structs.

  D-59, and the moduledoc above is the argument. One `%__MODULE__{}` per
  (medication, clock time), in clock order, with `id: nil` because none of them
  is a row: they are what the schedule already says about today, restated in the
  shape screen 112 draws and `resolve/2` reads.

  Three things about the shape, each of which is load-bearing:

    * **It takes the medications and the day rather than reading either.**
      `Kati.Notifications.Sources.Health.candidates/3` states the reason for
      itself and it is the same reason here: *a function that reads its own
      input cannot be asked about a value.* `Kati.Screens.Medication` calls
      `Kati.Notifications.Sources.Health.active/0` for the list, so the page and
      the reminder are demonstrably composing today from ONE read.
    * **The medication struct the caller already holds is put on `:medication`.**
      A derived row and a row read with `Ash.Query.load(:medication)` are then
      the same shape, and one shaper on the screen can read both — which matters
      more than it looks, because a derived row and a stored row shaped by two
      pieces of code are two lists that can disagree about what a dose is, and
      disagreeing lists are the defect one level up.
    * **A time that does not parse contributes no row.**
      `Kati.Notifications.Sources.Health.wall/2` drops one for the same reason
      and says so: *a row whose time does not parse is dropped rather than
      guessed at* — arming, or here drawing, a dose at a time the app invented
      is worse than not drawing it. `clock?/1` is that test.

  The struct on `:medication` is also what `resolve/2` reads to refuse `:missed`
  for a clock time on `day` that had already passed when the medication was
  stored — a derived row is composed retroactively, and a plan cannot report a
  past failure the way a materialised row can. The argument is written out
  there.

  Duplicate times inside one medication collapse: `["08:00", "08:00"]` is one
  dose at 08:00, because two rows for one clock time would be two cards with
  the same name, the same minute and — through
  `Kati.Screens.Medication.tags/1` — the same `accessibility_id`.
  """
  @spec derive([Kati.Health.Medication.t()], Date.t()) :: [t()]
  def derive(medications, %Date{} = day) when is_list(medications) do
    rows =
      for medication <- medications,
          at <- Enum.uniq(medication.times),
          clock?(at) do
        # `struct/2` rather than `%__MODULE__{}`. Ash defines a resource's
        # struct in a `@before_compile` hook, so the literal cannot be expanded
        # from inside the resource's own body — the compiler says as much and
        # calls it a cyclic module usage. `struct/2` resolves at runtime and
        # produces the identical term.
        struct(__MODULE__, %{
          id: nil,
          medication_id: medication.id,
          medication: medication,
          due_on: day,
          due_at: at,
          state: :due
        })
      end

    Enum.sort_by(rows, &{&1.due_at, name_of(&1)})
  end

  @doc """
  The day's stored rows, plus the derived ones no stored row already covers.

  Keyed on `{medication_id, due_at}`. The day is not in the key because both
  lists are one day's already, and a key carrying a value that cannot vary is a
  key that invites a caller to vary it.

  **The stored row always wins its derived twin.** A derived twin replacing a
  stored one would un-tick a tick on the next reload, and screen 112's own
  moduledoc names that as the failure this page cannot have: *of everything in
  this app, did I take it is the question a wrong answer costs the most.*

  The converse follows and is deliberate. A stored dose at a time the
  medication no longer lists — somebody marked 14:00 taken and then edited
  `times` on screen 189 — survives the merge rather than being dropped, because
  the derived side is the PLAN and the stored side is the record of what
  happened. Editing tomorrow's plan cannot delete this afternoon.
  """
  @spec merge([t()], [t()]) :: [t()]
  def merge(stored, derived) when is_list(stored) and is_list(derived) do
    covered = MapSet.new(stored, &{&1.medication_id, &1.due_at})

    extra = Enum.reject(derived, &MapSet.member?(covered, {&1.medication_id, &1.due_at}))

    Enum.sort_by(stored ++ extra, &{&1.due_at, name_of(&1)})
  end

  @doc """
  Whether a string is a clock time this app can put a dose at: `"08:00"`.

  The same parse `Kati.Notifications.Sources.Health.wall/2` does, so a time that
  draws a row is a time that arms a reminder and there is no third answer to
  *what counts as a due time*. It is also what bounds the atom family
  `Kati.Screens.Medication.tags/1` builds for a derived row: nothing reaches
  `String.to_atom/1` there until this has said yes, so the clock half of that
  key ranges over at most 1440 values and in practice over the medication's own
  `times`.

      iex> Kati.Health.Dose.clock?("08:00")
      true

      iex> Kati.Health.Dose.clock?("morning")
      false

      iex> Kati.Health.Dose.clock?(nil)
      false
  """
  @spec clock?(term()) :: boolean()
  def clock?(at) when is_binary(at), do: match?({:ok, _time}, Time.from_iso8601(at <> ":00"))
  def clock?(_other), do: false

  # The medication's name, for the tiebreak inside one clock time, and `""`
  # when the relationship was never loaded. Sorting is not worth raising over:
  # two tablets at 08:00 in an unstable order is a redraw that shuffles, and a
  # page that refused to render at all would be worse.
  defp name_of(%__MODULE__{medication: %{name: name}}) when is_binary(name), do: name
  defp name_of(%__MODULE__{}), do: ""

  @type t :: %__MODULE__{}
end
