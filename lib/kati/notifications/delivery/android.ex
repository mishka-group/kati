defmodule Kati.Notifications.Delivery.Android do
  @moduledoc """
  The delivery backend that actually arms something.

  Until this module, `Kati.Notifications.Delivery.Inert` was the only
  implementation of the behaviour, and it was the only one *possible*: the
  Kotlin half has been complete since `K-01 notify-persist` — an AlarmManager
  alarm recorded in `KatiNotificationStore` so it survives a reboot — and
  nothing in Elixir could reach it. `:mob_nif` has no notify entry anywhere in
  mob 0.7.20, and `mob_notify` is not a dependency. So Kati had a full budget,
  a quiet-hours rule, a digest rule and a reconciler, and the whole thing ended
  in a function that returned `:ok` and did nothing.

  The missing link is a project-owned static NIF (`Kati.Nifs.KatiBridge`), and
  this module is the first thing on the other side of it.

  ## AlarmManager, and why the air date is pre-armed rather than polled

  A release reminder is a **known instant**. Once TMDB says an episode airs at
  19:00, nothing has to run in the background to remember that — the alarm is
  set now and the OS holds it, through app kills, through the BEAM being dead,
  through days of the phone not being touched. Polling for something already
  known is a battery bill for no information, and #58's whole architecture
  follows from noticing this: *pre-schedule what is known, use periodic work
  only to learn what changed, and refresh on open as the net.*

  This module is the first of those three.

  ## What it refuses

  A candidate the scheduler already refused — suppressed, or with no
  `fire_at` — is not armed and is not a silent success either. Arming it would
  contradict a decision the layer above already made and recorded; returning
  `:ok` would tell `Kati.Notifications.Delivery.run/2` an alarm exists when it
  does not, which is exactly the lie `Kati.Notifications.Armed` compares
  against next time.

  ## Failures are values, and one of them is invisible

  `arm/1` never raises: Kati runs one screen process and re-arming two hundred
  alarms on foreground must not be able to take the UI down.

  The failure worth knowing about is `:not_permitted`. With `POST_NOTIFICATIONS`
  refused, Android **still** arms the alarm, **still** runs the receiver, and
  **still** accepts `nm.notify(...)` — the notification simply never appears,
  and nothing reports an error at any layer. `status/0` asks the platform up
  front so a caller can install `Kati.Notifications.Delivery.Inert` instead and
  tell the user, rather than arming two hundred alarms that will never be seen.
  `Kati.Notifications.Delivery.Inert`'s own docs describe that as one of the
  two real situations it exists for; this is the module that can detect it.

  ## Exactness degrades; delivery does not

  `SCHEDULE_EXACT_ALARM` is ungranted by default from Android 13, and
  `KatiNotificationStore` answers that by arming an inexact alarm rather than
  throwing. An episode reminder a few minutes late is a far better outcome
  than one that never fires, and `status/0` reports which of the two the device
  is giving so a screen can say so.
  """

  @behaviour Kati.Notifications.Delivery

  alias Kati.Native.Bridge
  alias Kati.Notifications.Candidate

  @type status :: %{pending: non_neg_integer(), exact: boolean(), permitted: boolean()}

  @doc """
  Whether this backend can do anything on this build.

  `false` on the host and on iOS. `Kati.Notifications.Delivery.backend/0` uses
  it to choose, so nothing has to ask "which platform am I on".
  """
  @spec available?() :: boolean()
  defdelegate available?(), to: Bridge

  @impl true
  @spec arm(Candidate.t()) :: :ok | {:error, term()}
  def arm(%Candidate{suppressed: reason}) when not is_nil(reason) do
    {:error, {:suppressed, reason}}
  end

  def arm(%Candidate{fire_at: nil}), do: {:error, :unresolved}

  def arm(%Candidate{} = candidate) do
    candidate
    |> payload()
    |> Bridge.encode()
    |> then(&Bridge.reply(:notify_arm, [&1]))
    |> ack()
  end

  @impl true
  @spec cancel(String.t()) :: :ok | {:error, term()}
  def cancel(id) when is_binary(id) do
    :notify_cancel |> Bridge.reply([id]) |> ack()
  end

  @doc """
  What the platform will actually honour.

  `pending` is how many alarms `KatiNotificationStore` currently holds — Kati's
  own record, not a query to AlarmManager, which cannot be asked. `exact` is
  whether `SCHEDULE_EXACT_ALARM` is granted. `permitted` is whether
  notifications may be shown at all, and is the one that fails silently.
  """
  @spec status() :: {:ok, status()} | {:error, term()}
  def status do
    case Bridge.reply(:notify_status, []) do
      {:ok, reply} -> decode_status(reply)
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  The payload sent across the bridge, as a plain map.

  Public because it is the contract with `MobBridge.katiNotifyArm` and
  `KatiNotificationStore.schedule`, and because it is the half of this module a
  host test can assert on — everything else needs a JVM.

  `trigger_at` is **epoch seconds**, matching what the Kotlin side multiplies
  by 1000. `data` carries what the tap handler needs to open the right screen,
  and deliberately nothing else: a notification payload is stored in a
  `SharedPreferences` entry and re-read at boot, so it is not a place to put
  the user's data.
  """
  @spec payload(Candidate.t()) :: map()
  def payload(%Candidate{} = candidate) do
    %{
      "id" => candidate.id,
      "title" => candidate.title || "",
      "body" => candidate.body || "",
      "trigger_at" => DateTime.to_unix(candidate.fire_at),
      "data" => %{
        "domain" => Atom.to_string(candidate.domain),
        "members" => candidate.members,
        "meta" => stringify(candidate.meta)
      }
    }
  end

  # ── internals ───────────────────────────────────────────────────────────

  defp ack({:ok, reply}) do
    case Bridge.split(reply) do
      {:ok, _payload} -> :ok
      {:error, reason} -> {:error, reason_atom(reason)}
    end
  end

  defp ack({:error, reason}), do: {:error, reason}

  defp decode_status(reply) do
    with {:ok, payload} <- Bridge.split(reply),
         [pending, exact, permitted] <- String.split(payload, ":"),
         {count, ""} <- Integer.parse(pending) do
      {:ok, %{pending: count, exact: exact == "true", permitted: permitted == "true"}}
    else
      {:error, reason} -> {:error, reason_atom(reason)}
      _ -> {:error, {:bad_reply, reply}}
    end
  end

  # A closed set: a reply from across JNI never reaches String.to_atom.
  defp reason_atom("no_context"), do: :no_context
  defp reason_atom("bad_request"), do: :bad_request
  defp reason_atom("arm_failed"), do: :arm_failed
  defp reason_atom("cancel_failed"), do: :cancel_failed
  defp reason_atom("status_failed"), do: :status_failed
  defp reason_atom(reason) when reason in ~w(no_jvm no_bridge no_method), do: :no_bridge
  defp reason_atom(other) when is_binary(other), do: {:native, other}
  defp reason_atom(other), do: other

  # `meta` is domain-authored and can hold atoms, dates and structs; the JNI
  # side is a JSON string. Flattening to strings here rather than trusting the
  # encoder means a domain adding a struct to `meta` cannot break arming for
  # every other domain at once.
  #
  # Nil-valued keys are dropped, not encoded. Erlang's `:json.encode/1` renders
  # the atom `nil` as the STRING "nil" — only `:null` becomes JSON null — so a
  # `%{episode: nil}` would reach the tap handler as the text "nil" and open
  # the wrong thing. An absent key is unambiguous on both sides.
  defp stringify(map) when is_map(map) and not is_struct(map) do
    map
    |> Map.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new(fn {key, value} -> {to_key(key), stringify(value)} end)
  end

  defp stringify(list) when is_list(list) do
    list |> Enum.reject(&is_nil/1) |> Enum.map(&stringify/1)
  end

  defp stringify(value) when is_binary(value) or is_number(value) or is_boolean(value), do: value
  defp stringify(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify(value), do: to_string_safe(value)

  defp to_key(key) when is_atom(key), do: Atom.to_string(key)
  defp to_key(key) when is_binary(key), do: key
  defp to_key(key), do: to_string_safe(key)

  defp to_string_safe(value) do
    if String.Chars.impl_for(value), do: to_string(value), else: inspect(value)
  end
end
