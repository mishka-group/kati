defmodule Kati.Goals.Goal do
  @moduledoc """
  One goal: a kind, a target, a period, and whether it comes back.

  ## `progress` is stored, and that is not laziness

  A books goal could count `Kati.Books.Book` rows with `status: :finished` in
  the window, and a films goal could count `Kati.Media.Watch`. Two of the ten
  kinds have no source at all — `meals cooked` and `habit days` — and two more
  count things that predate the goal. So a goal that could only ever be as good
  as its domain would be a goal you could not set for anything Kati does not
  yet track, which is most of what people set goals about.

  `progress` is therefore a column that a domain **may** move. Where a real
  count exists, `Kati.Goals.recount/1` writes it; where none does, the number is
  the user's own. One shape either way, and the screen cannot tell which it is
  looking at — which is correct, because neither can the user, and both are true.

  ## Periods are dates, not enum arithmetic

  `starts_on` and `ends_on` are stored even for `:year`, because *a yearly goal
  restarts on 1 January* is a rule about the **next** period rather than a
  description of this one — a goal set in March runs to 31 December and the
  repeat makes the next one a full year. Deriving the window from `period`
  would silently move the deadline of every goal set mid-period.
  """

  use Ash.Resource, domain: Kati.Goals, data_layer: AshSqlite.DataLayer

  sqlite do
    table "goals"
    repo Kati.Repo

    custom_indexes do
      # Screen 104's list: the live ones, in the order they were made.
      index [:ends_on]
    end
  end

  # The ten kinds screen 106 offers, grouped by the section they belong to, with
  # the unit each counts and the sentence that says what counts. The sentence is
  # the D-14 answer and is data rather than screen copy so it cannot go missing.
  @kinds [
    {:films, "Screen", "films", "Counts a film once, however many times you watch it."},
    {:episodes, "Screen", "episodes", "Counts every tick, including rewatches."},
    {:hours_watched, "Screen", "hours watched",
     "Dropped shows keep the hours they earned. Nothing is taken back."},
    {:books, "Books", "books",
     "Counts finished books only. A book you did not finish counts its pages toward the " <>
       "pages goal, not this one."},
    {:pages, "Books", "pages", "Counts every page logged, finished or not."},
    {:minutes_read, "Books", "minutes read",
     "Counts timed sittings only — a session logged by page has no minutes to give."},
    {:albums, "Music", "albums", "Counts an album the first time you play it in the period."},
    {:minutes_listened, "Music", "minutes listened", "Counts every logged listen."},
    {:meals_cooked, "Health", "meals cooked", "Counts a meal logged from a recipe you own."},
    {:habit_days, "Health", "habit days", "Counts a day on which every habit was ticked."}
  ]

  attributes do
    uuid_primary_key :id

    attribute :kind, :atom,
      allow_nil?: false,
      public?: true,
      constraints: [one_of: Enum.map(@kinds, &elem(&1, 0))]

    attribute :target, :integer, allow_nil?: false, public?: true, constraints: [min: 1]

    attribute :progress, :integer,
      allow_nil?: false,
      default: 0,
      public?: true,
      constraints: [min: 0]

    attribute :period, :atom,
      allow_nil?: false,
      default: :year,
      public?: true,
      constraints: [one_of: [:week, :month, :year, :custom]]

    attribute :starts_on, :date, allow_nil?: false, public?: true
    attribute :ends_on, :date, allow_nil?: false, public?: true

    attribute :repeat, :boolean, allow_nil?: false, default: true, public?: true

    timestamps()
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]

    read :live do
      description "Goals whose period has not closed — screen 104's list."
      argument :today, :date, allow_nil?: false
      filter expr(ends_on >= ^arg(:today))
      prepare build(sort: [ends_on: :asc])
    end
  end

  @doc "Every kind, as `{value, section, unit, what counts}`."
  @spec kinds() :: [{atom(), String.t(), String.t(), String.t()}]
  def kinds, do: @kinds

  @doc "The sections screen 106 groups its chips under, in order and without repeats."
  @spec sections() :: [String.t()]
  def sections, do: @kinds |> Enum.map(&elem(&1, 1)) |> Enum.uniq()

  @doc "The unit a kind counts: `films`, `pages`, `minutes read`."
  @spec unit(atom()) :: String.t()
  def unit(kind) do
    case Enum.find(@kinds, &(elem(&1, 0) == kind)) do
      {_kind, _section, unit, _counts} -> unit
      nil -> "items"
    end
  end

  @doc "The sentence under a card that says what counts. Never empty."
  @spec counts(atom()) :: String.t()
  def counts(kind) do
    case Enum.find(@kinds, &(elem(&1, 0) == kind)) do
      {_kind, _section, _unit, counts} -> counts
      nil -> "Counts what you log."
    end
  end

  @doc "The card's title: `52 books this year`."
  @spec title(t()) :: String.t()
  def title(%__MODULE__{kind: kind, target: target, period: period}) do
    "#{target} #{unit(kind)} #{period_phrase(period)}"
  end

  defp period_phrase(:week), do: "this week"
  defp period_phrase(:month), do: "a month"
  defp period_phrase(:year), do: "this year"
  defp period_phrase(:custom), do: "this period"

  @doc """
  Where you land if you carry on at this rate, given the day.

  `nil` before the period starts and on its first day — one day of data
  extrapolated over a year is not a projection, it is a multiplication, and
  presenting it as the first would be the screen's one dishonest number.

  Capped at the target, because *on pace to finish 140 of 120* is not something
  a goal card should say: past the target the answer is that you made it.
  """
  @spec project(t(), Date.t()) :: non_neg_integer() | nil
  def project(%__MODULE__{} = goal, %Date{} = today) do
    elapsed = Date.diff(today, goal.starts_on) + 1
    total = Date.diff(goal.ends_on, goal.starts_on) + 1

    cond do
      elapsed < 2 or total < 1 -> nil
      true -> min(round(goal.progress * total / elapsed), goal.target)
    end
  end

  @doc """
  How the card is doing: `:ahead`, `:on_pace` or `:behind`.

  Measured against where you would be if the period ran evenly, and the middle
  band is deliberately wide — five per cent either side — because a goal that
  flipped between *ahead* and *behind* on a single day would be reporting noise
  as news.
  """
  @spec pace(t(), Date.t()) :: :ahead | :on_pace | :behind
  def pace(%__MODULE__{} = goal, %Date{} = today) do
    case expected(goal, today) do
      nil ->
        :on_pace

      +0.0 ->
        :on_pace

      expected ->
        cond do
          goal.progress > expected * 1.05 -> :ahead
          goal.progress < expected * 0.95 -> :behind
          true -> :on_pace
        end
    end
  end

  @doc """
  How far off the even line you are, as a whole percentage.

  Screen 104 prints it beside an arrow — `23%` up, `11%` down — and never
  beside `On pace`, because a number attached to *on pace* would invite reading
  the band as a failure.
  """
  @spec drift(t(), Date.t()) :: non_neg_integer() | nil
  def drift(%__MODULE__{} = goal, %Date{} = today) do
    case expected(goal, today) do
      nil -> nil
      +0.0 -> nil
      expected -> round(abs(goal.progress - expected) / expected * 100)
    end
  end

  defp expected(%__MODULE__{} = goal, %Date{} = today) do
    elapsed = Date.diff(today, goal.starts_on) + 1
    total = Date.diff(goal.ends_on, goal.starts_on) + 1

    if elapsed < 1 or total < 1, do: nil, else: goal.target * elapsed / total
  end

  @doc "Days left in the period, floored at zero."
  @spec days_left(t(), Date.t()) :: non_neg_integer()
  def days_left(%__MODULE__{ends_on: ends_on}, %Date{} = today),
    do: max(Date.diff(ends_on, today), 0)

  @doc "The fraction of the target reached, capped at one."
  @spec fraction(t()) :: float()
  def fraction(%__MODULE__{target: target, progress: progress}) when target > 0,
    do: min(progress / target, 1.0)

  def fraction(%__MODULE__{}), do: 0.0

  @type t :: %__MODULE__{}
end
