defmodule Kati.Notifications.Delivery.Inert do
  @moduledoc """
  A delivery backend that arms nothing and succeeds. The default, and not a stub.

  Two real situations want exactly this:

    * **the host.** `mix test` and `iex -S mix` have no notification centre.
      Planning still has to work — most of what #59 owns is decisions, and
      decisions are testable without a phone.
    * **`POST_NOTIFICATIONS` denied.** With the permission refused, Android
      still lets `MobNotify.schedule/2` arm the alarm and still lets the
      receiver call `nm.notify(...)`; the notification simply never appears and
      **nothing reports an error**. Installing this backend instead makes the
      denial explicit: nothing is armed, the plan still exists in full, and the
      in-app inbox badge the design already specifies renders from it. The user
      is told the app cannot show notifications rather than left wondering why
      they never arrive.

  The plan is the product here, not the alarm.
  """

  @behaviour Kati.Notifications.Delivery

  alias Kati.Notifications.Candidate

  @impl true
  @spec arm(Candidate.t()) :: :ok
  def arm(%Candidate{}), do: :ok

  @impl true
  @spec cancel(String.t()) :: :ok
  def cancel(id) when is_binary(id), do: :ok
end
