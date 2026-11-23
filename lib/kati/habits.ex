defmodule Kati.Habits do
  @moduledoc """
  A habit, and every day it was kept.

  Screen 22's note is the design decision this domain encodes: *"a habit is
  just a repeating calendar item that keeps a streak — no new visual language
  needed."* So the store is deliberately the smallest thing that can answer
  the screen's three questions:

    * **which habits are mine** — `Kati.Habits.Habit`, one row each;
    * **was it kept today** — `Kati.Habits.Tick`, one row per habit per day;
    * **how long is the streak** — a count over those ticks, computed here and
      never stored. A stored streak is a number a missed day has to go back
      and correct, and the day it forgets to is the day the card lies.

  ## A tick is a date, not an instant

  `ticked_on` is a `:date`. "Kept it on Tuesday" is a fact about the calendar day the
  reader was living in, and `Kati.Time.today/0` is what asks for that day in
  the device's own zone. An instant would move a tick into yesterday for the
  first two hours of every Amsterdam day, which is the defect
  `Kati.Calendars.Event` splits two columns to avoid.

  ## Four tones, and what they now mean

  The drawing's day square has four states — green, bronze, grey, empty. They
  were *ages of a streak* in the sample; from real data they are what a day
  itself says:

    * `:done` — kept, and part of the streak running into today (green)
    * `:partial` — kept, but the streak through it has since lapsed (bronze)
    * `:lapsed` — kept, and the run it belonged to is old (grey)
    * `:missed` — not kept (empty)

  `day_state/3` is that rule and it is the only place it exists, so the week
  strip, the consistency field and the streak line cannot disagree about what
  a day was.

  ## Kept means one tap

  `toggle/2` is the whole write path: it creates today's tick, or destroys it.
  The unique index on `[habit_id, ticked_on]` makes a double tap a no-op at the
  database rather than two rows a count would double.

  ## What is not here yet

  No schedule column: every habit is daily, which is what the drawing's seven
  squares already say. A habit that repeats on chosen days — the calendar's
  `:habit` kind can express one — is a second column and a filter, and adding
  it before a screen asks for it would be a control with nowhere to land.
  """

  use Ash.Domain, validate_config_inclusion?: false

  require Ash.Query

  resources do
    resource Kati.Habits.Habit
    resource Kati.Habits.Tick
  end

  @doc """
  Every habit still kept, newest first.

  Newest first for the reason the screen's `+` gives: the point of pressing it
  is to see the thing you just made, and a fifth card below four is off the
  bottom of the phone. A store that cannot be read answers `[]` — the
  degradation every screen in Kati makes — rather than taking the page down.
  """
  @spec list() :: [Kati.Habits.Habit.t()]
  def list do
    Kati.Habits.Habit
    |> Ash.Query.for_read(:active)
    |> Ash.read()
    |> case do
      {:ok, habits} -> habits
      _other -> []
    end
  rescue
    _error -> []
  end

  @doc """
  Every tick between two dates, as `%{{habit_id, date} => true}`.

  One read for the whole page: the week strip and the consistency field ask
  about the same history, and two queries that must agree about what "this
  week" means is two chances to disagree.
  """
  @spec ticks(Date.t(), Date.t()) :: %{{term(), Date.t()} => true}
  def ticks(from, to) do
    Kati.Habits.Tick
    |> Ash.Query.filter(ticked_on >= ^from and ticked_on <= ^to)
    |> Ash.read!()
    |> Map.new(&{{&1.habit_id, &1.ticked_on}, true})
  rescue
    _error -> %{}
  end

  @doc """
  Add a habit by name.

  The name is trimmed and a blank one is refused here rather than in the
  screen, because the rule is about the row: an empty name renders as a card
  with no title and a switch nobody can recognise. Returns
  `{:error, :empty_name}` so the caller can say so and keep the sheet open —
  see `Kati.Write`'s contract.
  """
  @spec add(String.t()) :: {:ok, Kati.Habits.Habit.t()} | {:error, term()}
  def add(name) when is_binary(name) do
    case String.trim(name) do
      "" -> {:error, :empty_name}
      trimmed -> Ash.create(Kati.Habits.Habit, %{name: trimmed})
    end
  end

  def add(_not_a_string), do: {:error, :empty_name}

  @doc """
  Keep or unkeep one habit on one day.

  Returns `{:ok, kept?}` — the new state — or `{:error, reason}`. The create
  is refused by the unique index if two taps race, and that refusal is read as
  "already kept" rather than as a failure: the tick the second tap wanted is
  the tick the first one wrote.
  """
  @spec toggle(term(), Date.t()) :: {:ok, boolean()} | {:error, term()}
  def toggle(habit_id, on) do
    Kati.Habits.Tick
    |> Ash.Query.filter(habit_id == ^habit_id and ticked_on == ^on)
    |> Ash.read_one()
    |> case do
      {:ok, nil} ->
        case Ash.create(Kati.Habits.Tick, %{habit_id: habit_id, ticked_on: on}) do
          {:ok, _tick} -> {:ok, true}
          {:error, _already} -> {:ok, true}
        end

      {:ok, tick} ->
        case Ash.destroy(tick) do
          :ok -> {:ok, false}
          {:ok, _gone} -> {:ok, false}
          {:error, reason} -> {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Keep or unkeep **every habit** on one past day — the field's own gesture.

  The thirteen-week field is a day at a time across all habits, so tapping one
  of its cells is a statement about the day rather than about a habit: if the
  day was complete it becomes empty, and if it was not, every habit is ticked.

  Every habit, not only the ones that existed then. `fraction/3` counts a day
  against the habits that existed, and it still does — a tick on a day before
  a habit was created is ignored by the figure. But a person who installs Kati
  today and wants to record that they ran yesterday is not making a false
  claim, and refusing the tick because the row is newer than the day would be
  the app arguing with its own reader.

  Returns `{:ok, kept?}` with the day's new state.
  """
  @spec toggle_all(Date.t()) :: {:ok, boolean()} | {:error, term()}
  def toggle_all(date) do
    case list() do
      [] ->
        {:ok, false}

      habits ->
        kept = ticks(date, date)
        complete? = Enum.all?(habits, &Map.has_key?(kept, {&1.id, date}))

        result =
          Enum.reduce_while(habits, :ok, fn habit, :ok ->
            ticked? = Map.has_key?(kept, {habit.id, date})

            if ticked? == complete? do
              case toggle(habit.id, date) do
                {:ok, _} -> {:cont, :ok}
                {:error, reason} -> {:halt, {:error, reason}}
              end
            else
              {:cont, :ok}
            end
          end)

        case result do
          :ok -> {:ok, not complete?}
          {:error, reason} -> {:error, reason}
        end
    end
  end

  @doc """
  Remove a habit, and every day it was kept with it.

  The ticks go at the database: `habit_ticks`' reference carries
  `on_delete: :delete`, so a habit destroyed here cannot leave a tick pointing
  at nothing. That is the right shape for a delete — a tick with no habit is
  not history, it is a row nobody can read.

  Returns `:ok` or `{:error, reason}` so the screen can keep the confirmation
  open and say what happened. `Kati.Write`'s contract: a write never answers a
  bare `:ok` it did not earn.
  """
  @spec delete(term()) :: :ok | {:error, term()}
  def delete(habit_id) do
    with {:ok, habit} <- Ash.get(Kati.Habits.Habit, habit_id),
         :ok <- delete_ticks(habit_id) do
      case Ash.destroy(habit) do
        :ok -> :ok
        {:ok, _gone} -> :ok
        {:error, reason} -> {:error, reason}
      end
    end
  end

  # Ticks go before the habit, not after. The reference carries
  # `on_delete: :delete`, and a device migrated before that was written into
  # the migration keeps a foreign key that only refuses — so the delete is done
  # here in the order both schemas accept. An interrupted run leaves the habit
  # in place with some ticks gone, never a tick pointing at nothing.
  defp delete_ticks(habit_id) do
    Kati.Habits.Tick
    |> Ash.Query.filter(habit_id == ^habit_id)
    |> Ash.read()
    |> case do
      {:ok, ticks} ->
        Enum.reduce_while(ticks, :ok, fn tick, :ok ->
          case Ash.destroy(tick) do
            :ok -> {:cont, :ok}
            {:ok, _gone} -> {:cont, :ok}
            {:error, reason} -> {:halt, {:error, reason}}
          end
        end)

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  The streak ending today, or ending yesterday when today is not yet kept.

  Ending **yesterday** matters: an untapped today is a day that has not
  happened yet, not a broken run, and a streak that read `0` every morning
  until the tap would make the card shout at the reader for waking up.

  `kept?` is `(habit_id, date) -> boolean`, so the same arithmetic serves the
  page's one read and a test's map.
  """
  @spec streak(term(), Date.t(), (term(), Date.t() -> boolean())) :: non_neg_integer()
  def streak(habit_id, today, kept?) do
    start =
      if kept?.(habit_id, today),
        do: today,
        else: Date.add(today, -1)

    count(habit_id, start, kept?, 0)
  end

  defp count(habit_id, date, kept?, n) do
    if kept?.(habit_id, date),
      do: count(habit_id, Date.add(date, -1), kept?, n + 1),
      else: n
  end

  @doc """
  The longest run of kept days a habit has ever had.

  Walks the days it was kept, sorted, and counts adjacent dates. A run ends at
  a gap of more than one day; nothing here reads the streak column, because
  there is none.
  """
  @spec longest(term(), %{{term(), Date.t()} => true}) :: non_neg_integer()
  def longest(habit_id, ticks) do
    ticks
    |> Map.keys()
    |> Enum.filter(fn {id, _on} -> id == habit_id end)
    |> Enum.map(&elem(&1, 1))
    |> Enum.sort_by(&Date.to_gregorian_days/1)
    |> Enum.reduce({0, 0, nil}, fn date, {top, run, previous} ->
      run = if previous && Date.diff(date, previous) == 1, do: run + 1, else: 1
      {if(top > run, do: top, else: run), run, date}
    end)
    |> elem(0)
  end

  @doc """
  One day's state for one habit — the four tones the drawing uses.

  `:done` while the run reaches today (or yesterday, before today's tap);
  `:partial` for a kept day in a run that has since lapsed; `:lapsed` for a
  kept day whose run is older than a week; `:missed` for a day not kept. The
  exact cut between bronze and grey is a judgement, and it is here so the
  week strip and the field cannot make it twice.
  """
  @spec day_state(term(), Date.t(), Date.t(), %{{term(), Date.t()} => true}) :: atom()
  def day_state(habit_id, date, today, ticks) do
    cond do
      Date.compare(date, today) == :gt -> :missed
      not Map.has_key?(ticks, {habit_id, date}) -> :missed
      Date.compare(date, Date.add(today, -6)) != :lt -> :done
      Date.compare(date, Date.add(today, -27)) != :lt -> :partial
      true -> :lapsed
    end
  end

  @doc """
  The seven dates of the week containing `today`, in the order the ruler
  draws them.

  The English ruler opens on Monday and the Persian one on Saturday — see
  the screen's own `week_ruler/0` — so the caller passes the first weekday it
  drew. `Date.day_of_week/2` does the arithmetic, so a locale's week start is
  never re-derived here.
  """
  @spec week_dates(Date.t(), non_neg_integer()) :: [Date.t()]
  def week_dates(today, week_starts_on) do
    monday = Date.add(today, 1 - Date.day_of_week(today))

    start =
      if week_starts_on == 6,
        do: Date.add(monday, -2),
        else: monday

    for offset <- 0..6, do: Date.add(start, offset)
  end

  @doc """
  A day's completion as a `0.0..1.0` fraction of the habits there are now.

  Every habit counts, including one made after that date. The stricter rule —
  a habit that did not exist cannot be missed — was tried and read as a broken
  field: a person who installs Kati today and backfills a week of ticks saw
  ninety pale squares, because every habit they own was newer than every day
  they had just marked. A record that refuses to show what was recorded is
  worse than one that counts a day against a habit that came later.
  """
  @spec fraction(Date.t(), [Kati.Habits.Habit.t()], %{{term(), Date.t()} => true}) :: float()
  def fraction(_date, [], _ticks), do: 0.0

  def fraction(date, habits, ticks) do
    kept = Enum.count(habits, &Map.has_key?(ticks, {&1.id, date}))
    kept / length(habits)
  end

  @doc """
  The consistency field's tones: one per day, oldest first, over `days` days
  ending today.

  Four tones for four shades, and the cut points are the drawing's own
  arithmetic rather than an invention: a full day is every habit kept, two
  thirds is bronze, a third is light, and the palest is a day with something
  kept but under a third.
  """
  @spec field(Date.t(), non_neg_integer(), [Kati.Habits.Habit.t()], map()) :: [atom()]
  def field(today, days, habits, ticks) do
    for offset <- (days - 1)..0//-1 do
      date = Date.add(today, -offset)
      tone(fraction(date, habits, ticks))
    end
  end

  @doc "The fraction as one of the field's four tones."
  @spec tone(float()) :: atom()
  def tone(f) when f <= 0.0, do: :pale
  def tone(f) when f >= 0.999, do: :full
  def tone(f) when f >= 0.66, do: :mid
  def tone(f) when f >= 0.33, do: :light
  def tone(_f), do: :pale
end
