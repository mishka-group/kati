defmodule Kati.Notifications.QuietHours do
  @moduledoc """
  23:00 to 08:00, and it **moves** a notification rather than dropping one.

  This distinction is the whole module. Suppressing a 23:30 reminder is a
  notification the user never receives — the same silent loss #59 exists to
  prevent, arrived at politely. Shifting it to 08:00 costs the user eight and a
  half hours of latency on something that was never urgent, and they still get
  it.

  The window wraps midnight, so "inside" means `>= 23:00` **or** `< 08:00`.
  Everything inside lands on the next 08:00: 23:30 tonight and 02:00 tomorrow
  morning both come out as 08:00 tomorrow.

  ## Two consequences worth knowing before reading `Kati.Notifications.Digest`

  Shifting is a *clustering* operation — everything the night swallows piles up
  on one instant. That is not a bug to be dithered away: the digest pass runs
  straight afterwards and turns the pile into one notification that says how
  many things happened, which is both the better morning and the cheaper one in
  slots.

  And shifting is wrong for anything tied to its own clock. A 07:30 meeting
  alert moved to 08:00 arrives after the meeting started, which is worse than
  arriving in the small hours — so a candidate may declare
  `quiet_hours: :exempt` and this module leaves it alone. The default is
  `:shift`, because the default reminder is an announcement, not an appointment.

  The window is configurable because it is a user setting (screen 38), not a
  constant; `false` for the whole rule is what "quiet hours off" means.
  """

  @type t :: %__MODULE__{from: Time.t(), to: Time.t()}

  defstruct from: ~T[23:00:00], to: ~T[08:00:00]

  @doc """
  The rule as the design draws it: quiet from 23:00, over at 08:00.

  `new/2` takes any pair; a window where `from` is later than `to` wraps
  midnight and one where it is earlier does not, so 13:00–14:00 is a valid (if
  unusual) quiet hour.
  """
  @spec default() :: t()
  def default, do: %__MODULE__{}

  @spec new(Time.t(), Time.t()) :: t()
  def new(%Time{} = from, %Time{} = to), do: %__MODULE__{from: from, to: to}

  @doc "Whether a local time of day falls inside the window."
  @spec within?(t(), Time.t()) :: boolean()
  def within?(%__MODULE__{from: from, to: to}, %Time{} = time) do
    if Time.compare(from, to) == :gt do
      # Wraps midnight: late evening or early morning.
      Time.compare(time, from) != :lt or Time.compare(time, to) == :lt
    else
      Time.compare(time, from) != :lt and Time.compare(time, to) == :lt
    end
  end

  @doc """
  Move an instant out of the quiet window, in the user's own zone.

  Returns `{:shifted, instant}` when the entry moved and `:keep` when it did not
  — including when the shifted wall clock cannot be resolved at all, because a
  notification at the wrong hour still beats one that vanished.

  The shifted instant is produced through `Kati.Time.to_utc/2`, so the one
  morning a year when 08:00 sits inside a DST gap resolves by Kati's stated
  policy rather than raising.
  """
  @spec shift(t(), DateTime.t(), String.t()) :: {:shifted, DateTime.t()} | :keep
  def shift(%__MODULE__{} = window, %DateTime{} = instant, zone) do
    local = Kati.Time.in_zone(instant, zone)

    if within?(window, DateTime.to_time(local)) do
      local
      |> DateTime.to_date()
      |> wake_date(window, DateTime.to_time(local))
      |> NaiveDateTime.new!(window.to)
      |> Kati.Time.to_utc(zone)
      |> case do
        {:ok, shifted} -> {:shifted, shifted}
        {:error, _reason} -> :keep
      end
    else
      :keep
    end
  end

  # Caught after the window opened, so the far side is tomorrow morning; caught
  # before it closed, so the far side is this morning, still ahead.
  defp wake_date(date, %__MODULE__{from: from, to: to}, time) do
    if Time.compare(from, to) == :gt and Time.compare(time, from) != :lt do
      Date.add(date, 1)
    else
      date
    end
  end
end
