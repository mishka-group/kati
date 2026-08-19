defmodule Kati.Subscriptions.Sample do
  @moduledoc """
  Stand-in subscription data, until spend and watch time are both real.

  Screen 23's note names the one number that justifies a money section inside a
  media app: *"cost per watched hour is the one subscription number no finance
  app can compute for you."* It needs both halves — the price, which a bank
  knows, and the hours, which only the Screen shelf knows — so `rate` is stored
  here as a value rather than derived, precisely because deriving it is the
  thing the real domain will do and this module must not pretend to.

  `rate_tone` carries the judgement the drawing makes: green when an hour is
  cheap, `#B4553C` when it is not. Orbit at £2.33/h is the row the suggestion
  card at the bottom is about.

  A paused service has no rate at all — not a zero, no key. £5.00 a month for
  nothing is not a rate, it is a leak, and the drawing greys the whole row to
  say so.
  """

  @doc "How many services are on the account."
  @spec active_line() :: String.t()
  def active_line, do: "5 active"

  @doc """
  The cream hero: what leaves the account every month, and what changed.

  The change line is three runs because the drawing bolds only the amount —
  `Up **£4.00** since March` — and a `Text` carries one weight.
  """
  @spec monthly() :: map()
  def monthly do
    %{
      label: "Every month",
      total: "£46.47",
      change_lead: "Up",
      change_amount: "£4.00",
      change_rest: "since March — Orbit raised its price"
    }
  end

  @doc "Every service, in the order the card lists them."
  @spec services() :: [map()]
  def services do
    [
      %{
        badge: "L",
        name: "Lumen+",
        line: "renews 18 Aug · 41h watched",
        price: "£8.99",
        rate: "£0.21/h",
        rate_tone: 0xFF4E9A73
      },
      %{
        badge: "O",
        name: "Orbit",
        line: "renews 24 Aug · 6h watched",
        price: "£13.99",
        rate: "£2.33/h",
        rate_tone: 0xFFB4553C
      },
      %{
        badge: "K",
        name: "Kino",
        line: "renews 01 Sep · 19h watched",
        price: "£11.49",
        rate: "£0.60/h",
        rate_tone: 0xFF4E9A73
      },
      %{
        badge: "A",
        name: "Aria Audio",
        line: "paused until October",
        price: "£5.00",
        paused: true
      }
    ]
  end

  @doc """
  The suggestion the numbers add up to.

  Kept as one sentence rather than the drawing's three bolded runs: it wraps to
  three lines in a 322pt card, and a wrapped paragraph assembled from separate
  `Text` runs breaks at the wrong words. The emphasis is lost; the sentence,
  which is the part that has to be right, is not.
  """
  @spec suggestion() :: map()
  def suggestion do
    %{
      body:
        "You watched 6 hours on Orbit this month and have 1 title " <>
          "left in its queue. Pausing after 24 Aug saves £13.99.",
      confirm: "Remind me 23 Aug",
      dismiss: "Dismiss"
    }
  end
end
