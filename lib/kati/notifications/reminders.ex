defmodule Kati.Notifications.Reminders do
  @moduledoc """
  Reminders for what the reader scheduled, on the platform (#124).

  An event with `alarm_minutes` — a *Schedule* from a film, show or anime page,
  or a Quick Add sentence ending *remind 1h before* — is armed as an alarm that
  fires that many minutes before it starts, with the app closed.

  Shaped as `Kati.Notifications.Releases`: candidates are planned through
  `Kati.Notifications.Scheduler` with the reader's quiet hours, reconciled
  against what this module last armed (the `:calendar` domain, ids under
  `rem:`), and delivered through `Kati.Notifications.Delivery`. Calling
  `sync/1` again with nothing changed arms and cancels nothing.

  Unlike release alerts these are not gated on screen 25's *Push* switch: a
  reminder is something the reader asked for by name, on the one event.

  Fourteen days ahead, because an alarm armed further out is one a reschedule
  is more likely to make wrong than right, and `sync/1` runs again on every
  boot and every schedule change.
  """
  require Ash.Query

  alias Kati.Calendars.Event
  alias Kati.Notifications.Candidate
  alias Kati.Notifications.Delivery
  alias Kati.Notifications.Pending
  alias Kati.Notifications.Plan
  alias Kati.Notifications.Reconcile
  alias Kati.Notifications.Scheduler
  alias Kati.Settings.Watcher

  use Gettext, backend: Kati.Gettext

  @horizon_days 14
  @prefix "rem:"

  @doc "The reminder options a scheduled event cycles through, in minutes."
  @spec choices() :: [non_neg_integer() | nil]
  def choices, do: [nil, 0, 10, 60]

  @doc """
  What a reminder says it is.

      iex> Kati.Notifications.Reminders.label(nil)
      "No reminder"
      iex> Kati.Notifications.Reminders.label(0)
      "At the start"
      iex> Kati.Notifications.Reminders.label(10)
      "10 min before"
      iex> Kati.Notifications.Reminders.label(60)
      "1 hr before"
  """
  @spec label(non_neg_integer() | nil) :: String.t()
  def label(nil), do: gettext("No reminder")
  def label(0), do: gettext("At the start")

  def label(minutes) when rem(minutes, 60) == 0,
    do: gettext("%{n} hr before", n: Kati.Locale.number(div(minutes, 60)))

  def label(minutes), do: gettext("%{n} min before", n: Kati.Locale.number(minutes))

  @doc "The reminder after `current` in `choices/0`, wrapping round."
  @spec next(non_neg_integer() | nil) :: non_neg_integer() | nil
  def next(current) do
    choices = choices()

    case Enum.find_index(choices, &(&1 == current)) do
      nil -> 0
      i -> Enum.at(choices, rem(i + 1, length(choices)))
    end
  end

  @doc """
  One candidate per event with a reminder, starting within the horizon.
  """
  @spec candidates(DateTime.t()) :: [Candidate.t()]
  def candidates(now \\ Kati.Time.now()) do
    scheduled =
      if Watcher.reminder?(:scheduled),
        do:
          now
          |> Kati.Notifications.Reminders.events()
          |> Enum.map(&Kati.Notifications.Reminders.candidate/1),
        else: []

    # #125: a loved title on the anniversary of its last watch.
    rewatch =
      if Watcher.reminder?(:rewatch),
        do: Kati.Notifications.Sources.Rewatch.candidates(),
        else: []

    scheduled ++ rewatch
  end

  @doc false
  def events(now) do
    to = DateTime.add(now, @horizon_days * 86_400, :second)

    Event
    |> Ash.Query.filter(
      is_nil(deleted_at) and not is_nil(alarm_minutes) and not is_nil(dtstart_utc) and
        dtstart_utc >= ^now and dtstart_utc <= ^to
    )
    |> Ash.Query.sort(dtstart_utc: :asc)
    |> Ash.read!()
  rescue
    _error -> []
  end

  @doc false
  def candidate(%Event{} = event) do
    fire_at = DateTime.add(event.dtstart_utc, -event.alarm_minutes * 60, :second)

    Candidate.absolute(@prefix <> event.uid, :calendar, fire_at,
      title: event.summary || gettext("Something you scheduled"),
      body: Kati.Notifications.Reminders.body(event.alarm_minutes),
      meta: %{
        event_id: event.id,
        tracked_id: event.tracked_title_id,
        kind: Kati.Notifications.Reminders.kind_of(event.tracked_title_id)
      }
    )
  end

  @doc false
  def kind_of(id) when is_binary(id) do
    case Ash.get(Kati.Media.TrackedTitle, id) do
      {:ok, tracked} -> tracked.kind
      _gone -> nil
    end
  rescue
    _error -> nil
  end

  def kind_of(_none), do: nil

  @doc false
  def body(0), do: gettext("Starting now")

  def body(minutes) when rem(minutes, 60) == 0,
    do: gettext("In %{n} hr", n: Kati.Locale.number(div(minutes, 60)))

  def body(minutes), do: gettext("In %{n} min", n: Kati.Locale.number(minutes))

  @doc "The plan the platform should hold for these reminders."
  @spec plan(keyword()) :: Plan.t()
  def plan(opts \\ []) do
    now = Keyword.get_lazy(opts, :now, &Kati.Time.now/0)

    Scheduler.plan(
      Kati.Notifications.Reminders.candidates(now),
      Keyword.merge([platform: :android, now: now, quiet_hours: Watcher.quiet_hours()], opts)
    )
  end

  @doc """
  Make the platform hold exactly the reminders scheduled. Never raises;
  `{:error, :no_delivery}` where there is no platform to hold them.
  """
  @spec sync(keyword()) :: Delivery.result() | {:error, term()}
  def sync(opts \\ []) do
    backend = Keyword.get_lazy(opts, :backend, &Delivery.backend/0)

    if backend == Delivery.Inert do
      {:error, :no_delivery}
    else
      now = Keyword.get_lazy(opts, :now, &Kati.Time.now/0)
      rows = Kati.Notifications.Reminders.armed()
      intended = Kati.Notifications.Reminders.plan(now: now)

      result =
        intended
        |> Reconcile.operations(Enum.map(rows, &Pending.to_armed/1))
        |> Delivery.run(backend)

      record!(result, intended, Map.new(rows, &{&1.id, &1}), now)
      result
    end
  rescue
    error -> {:error, error}
  end

  @doc "Sync off the caller's process: a screen's save must not wait on it."
  @spec sync_later() :: :ok
  def sync_later do
    Task.Supervisor.start_child(Kati.TaskSupervisor, fn -> Kati.Notifications.Reminders.sync() end)

    :ok
  catch
    :exit, _no_supervisor -> :ok
  end

  @doc "The reminders recorded as armed."
  @spec armed() :: [Pending.t()]
  def armed do
    Pending
    |> Ash.Query.for_read(:for_domain, %{domain: :calendar})
    |> Ash.read!()
    |> Enum.filter(&String.starts_with?(&1.id, @prefix))
  end

  defp record!(result, plan, existing, now) do
    Enum.each(result.cancelled, fn id -> destroy(Map.get(existing, id)) end)
    by_id = Map.new(plan.armed, &{&1.id, &1})
    armed_at = utc(now)

    Kati.Notifications.History.remember_armed(Enum.map(result.armed, &Map.fetch!(by_id, &1)))

    Enum.each(result.armed, fn id ->
      destroy(Map.get(existing, id))

      attrs =
        by_id
        |> Map.fetch!(id)
        |> Pending.from_candidate(armed_at)
        |> Map.update!(:fire_at_utc, &utc/1)

      Pending
      |> Ash.Changeset.for_create(:create, attrs)
      |> Ash.create!()
    end)
  end

  defp destroy(nil), do: :ok
  defp destroy(row), do: Ash.destroy!(row)

  defp utc(at), do: at |> DateTime.shift_zone!("Etc/UTC") |> DateTime.truncate(:second)
end
