defmodule Kati.Notifications.Sources.Money do
  @moduledoc """
  Renewal reminders, on the morning a subscription is about to take money.

  `Kati.Services.Service.renews_on` is a date and not an instant, because that
  is what a renewal is: the card is charged on a day, at an hour nobody tells
  you. So the reminder is a wall-clock candidate at a chosen morning hour
  rather than a false precision — 09:00 by default, and `:at` to move it.

  ## It fires the day before, and that is the only useful day

  A notification on the morning of a renewal tells you about money that has
  already gone. Screen 122's whole argument is that the money section exists to
  serve one question — *is this earning its keep* — and the only day on which
  that question can still be answered is the day before. `lead_days` is one,
  and it is named rather than baked in because the answer for an annual
  subscription may not be the answer for a monthly one.

  ## Paused is a state, not an absence

  A paused service still has a renewal date and screen 123 draws the state.
  Suppressing it with `:paused` rather than filtering it out is what lets the
  help page answer *why am I not getting these* — and it is the difference
  between a service you told Kati to stop nagging you about and one Kati simply
  lost.

  `:no_renewal` is the other reason and it is the ordinary one: a service the
  user added for its price alone, with no date. Nothing is wrong with it.

  ## One per service, and no aggregation

  This is the one domain where aggregating would lose the point. *£13.99 goes
  tomorrow* names an amount and a service, and *3 renewals tomorrow* names
  neither — the number a person needs is the one they might act on.
  `Kati.Notifications.Budget` gives `:money` thirty Android slots and four on
  iOS, which is more than a realistic subscription list needs, so the budget
  does not force the trade here the way it does for habits.
  """

  alias Kati.Notifications.Candidate
  alias Kati.Services.Service

  @lead_days 1
  @hour ~T[09:00:00]

  @doc """
  A candidate per subscribed service whose renewal falls `lead_days` after `day`.

  Takes the rows rather than reading them — `subscribed/0` is the reader.

  `opts` takes `:zone`, `:at` (the hour the reminder fires, 09:00) and
  `:lead_days` (1). Services that are not renewing on the target date
  contribute nothing at all — they are not suppressed, because *this service
  renews in three weeks* is not a reason a notification is missing.
  """
  @spec candidates([Service.t()], Date.t(), keyword()) :: [Candidate.t()]
  def candidates(services, %Date{} = day, opts \\ []) when is_list(services) do
    zone = Keyword.get(opts, :zone) || Kati.Time.device_zone()
    at = Keyword.get(opts, :at, @hour)
    lead = Keyword.get(opts, :lead_days, @lead_days)
    target = Date.add(day, lead)

    services
    |> Enum.filter(&renews_on?(&1, target))
    |> Enum.map(&candidate(&1, day, at, zone))
  end

  @doc "Every subscribed service, or `[]` when the store cannot answer."
  @spec subscribed() :: [Service.t()]
  def subscribed do
    Service
    |> Ash.Query.for_read(:subscribed)
    |> Ash.read()
    |> case do
      {:ok, rows} -> rows
      _error -> []
    end
  rescue
    _error -> []
  end

  @doc "The stable id for one service's renewal reminder."
  @spec id(Service.t(), Date.t()) :: String.t()
  def id(%Service{id: service_id}, %Date{} = on),
    do: Candidate.id(["renew", service_id, on])

  # A service with no date cannot renew on any day, and one that is paused
  # renews on the day it says and should not say so. Both answer separately.
  defp renews_on?(%Service{renews_on: nil}, _target), do: false
  defp renews_on?(%Service{renews_on: on}, target), do: Date.compare(on, target) == :eq

  defp candidate(%Service{paused: true} = service, day, _at, _zone) do
    Candidate.suppressed(id(service, day), :money, :paused,
      title: service.name,
      meta: meta(service)
    )
  end

  defp candidate(%Service{} = service, day, at, zone) do
    Candidate.wall_clock(id(service, day), :money, NaiveDateTime.new!(day, at), zone,
      title: service.name,
      body: body(service),
      priority: :low,
      members: [service.id],
      meta: meta(service)
    )
  end

  # The amount, in the one currency the app keeps — `Kati.Screens.Currency`
  # states the rule the whole section rests on: Kati records and shows every
  # amount in one currency, chosen once and never converted.
  defp body(%Service{monthly_pence: nil}), do: "Renews tomorrow"

  defp body(%Service{monthly_pence: pence, currency: currency}),
    do: "#{Kati.Money.format(pence, currency)} tomorrow"

  defp meta(%Service{} = service),
    do: %{service_id: service.id, renews_on: service.renews_on, tier: service.tier}
end
