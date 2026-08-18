defmodule Kati.Time do
  @moduledoc """
  Kati's timezone policy.

  Everything the calendar does eventually passes through here: recurrence
  expands in an event's own zone before converting to UTC (#47), alarms fire at
  an instant (#59), and a Shamsi grid renders a UTC-stored instant in local
  terms (#51).

  ## The two cases RFC 5545 leaves to the implementation

  A wall-clock time does not always exist, and sometimes exists twice:

    * **Gap** (spring forward) — 01:30 on a night the clocks jump 01:00 → 02:00
      never happens. RFC 5545 says a recurrence generator should drop it. Kati
      instead picks the **`after`** instant, because a user who set a 01:30 alarm
      wants it to fire that night, not to silently vanish once a year.
    * **Ambiguous** (fall back) — 01:30 happens twice. Kati picks the **`first`**,
      the earlier of the two, so a reminder fires at the first opportunity rather
      than an hour late.

  Both choices are deliberate and both differ from "just use `!`", which raises.

  ## The device zone

  Mob exposes no timezone API, and on device the BEAM sees no `TZ` environment
  variable — `System.get_env("TZ")` is `nil`. `:calendar.local_time/0` is
  correctly offset because bionic resolves the system property internally, but
  an **offset is not a zone**: it cannot say when DST changes, so it cannot
  expand a recurrence.

  So `KatiDeviceZone` (Kotlin) writes the IANA id into `filesDir` on app start
  and on `ACTION_TIMEZONE_CHANGED`, and this module reads it. `Etc/UTC` is the
  fallback, never a crash.
  """

  require Logger

  @zone_file "device_tz"
  @fallback "Etc/UTC"

  @doc """
  The device's IANA zone id, e.g. `"Europe/Amsterdam"`.

  Read fresh rather than cached: the file is rewritten on
  `ACTION_TIMEZONE_CHANGED`, and a user who has just flown is exactly the user
  who must not see a stale zone.
  """
  @spec device_zone() :: String.t()
  def device_zone do
    path = Path.join(Mob.data_dir(), @zone_file)

    case File.read(path) do
      {:ok, id} ->
        id = String.trim(id)
        if valid_zone?(id), do: id, else: @fallback

      {:error, _} ->
        @fallback
    end
  end

  @doc "True when the timezone database knows this zone."
  @spec valid_zone?(String.t()) :: boolean()
  def valid_zone?(id) when is_binary(id) do
    match?({:ok, _}, DateTime.from_naive(~N[2026-01-01 12:00:00], id))
  end

  def valid_zone?(_), do: false

  @doc """
  Resolve a wall-clock time in a zone to an instant, applying Kati's policy.

  Returns `{:ok, datetime, resolution}` where resolution is `:exact`, `:gap` or
  `:ambiguous`, so a caller that wants to tell the user "that time doesn't exist
  tonight" still can.
  """
  @spec resolve(NaiveDateTime.t(), String.t()) ::
          {:ok, DateTime.t(), :exact | :gap | :ambiguous} | {:error, term()}
  def resolve(%NaiveDateTime{} = naive, zone) do
    case DateTime.from_naive(naive, zone) do
      {:ok, dt} -> {:ok, dt, :exact}
      # Spring forward: take the instant AFTER the jump rather than dropping it.
      {:gap, _before, after_dt} -> {:ok, after_dt, :gap}
      # Fall back: take the FIRST of the two, so a reminder is not an hour late.
      {:ambiguous, first, _second} -> {:ok, first, :ambiguous}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc "Wall-clock in a zone to a UTC instant, applying `resolve/2`'s policy."
  @spec to_utc(NaiveDateTime.t(), String.t()) :: {:ok, DateTime.t()} | {:error, term()}
  def to_utc(naive, zone) do
    with {:ok, dt, _} <- resolve(naive, zone) do
      {:ok, DateTime.shift_zone!(dt, "Etc/UTC")}
    end
  end

  @doc "A UTC instant rendered in a zone."
  @spec in_zone(DateTime.t(), String.t()) :: DateTime.t()
  def in_zone(%DateTime{} = dt, zone), do: DateTime.shift_zone!(dt, zone)

  @doc "The IANA release the compiled database was built from, for bug reports."
  @spec iana_version() :: String.t()
  def iana_version, do: Tz.iana_version()
end
