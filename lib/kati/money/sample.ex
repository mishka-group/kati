defmodule Kati.Money.Sample do
  use Gettext, backend: Kati.Gettext

  @moduledoc """
  Screen 122, as the drawing captured it.

  The recurring half mirrors `Kati.Subscriptions.Sample` to the penny — screen
  23 and screen 122 draw the same four services, and screen 92 owns their
  prices — so a drifted figure here would be three screens disagreeing about
  one number.
  """

  @doc "The header's mono subtitle."
  @spec subtitle() :: String.t()
  def subtitle,
    do:
      Kati.UI.eyebrow_label(
        ngettext("%{n} service", "%{n} services", 3, n: Kati.Locale.number(3)) <>
          " · " <>
          ngettext("%{n} expense this month", "%{n} expenses this month", 7,
            n: Kati.Locale.number(7)
          )
      )

  @doc """
  The cream hero: what leaves the account every month, and the change.

  Three parts because the drawing bolds only the amount, and a `Text` carries
  one weight.
  """
  @spec monthly() :: map()
  def monthly do
    %{
      label: gettext("Every month"),
      total: Kati.Money.display(4647),
      direction: :up,
      change_lead: gettext("Up"),
      change_amount: Kati.Money.display(400),
      change_rest: gettext("since March — Orbit raised its price")
    }
  end

  @doc """
  The recurring rows, with the figure the caption calls the loudest on the page.

  Aria Audio is paused, keeps its row, and leaves the total — which is the
  behaviour the `info` line under the group states and the reason a paused
  service is not simply deleted.
  """
  @spec recurring() :: [map()]
  def recurring do
    [
      %{
        badge: "L",
        name: gettext("Lumen+"),
        line:
          gettext("renews %{date} · %{hours}h watched",
            date: Kati.Locale.date(~D[2026-08-18], :short_padded),
            hours: Kati.Locale.number(41)
          ),
        price: Kati.Money.display(899),
        rate: Kati.Money.per_hour(21, 1),
        good?: true
      },
      %{
        badge: "O",
        name: gettext("Orbit"),
        line:
          gettext("renews %{date} · %{hours}h watched",
            date: Kati.Locale.date(~D[2026-08-24], :short_padded),
            hours: Kati.Locale.number(6)
          ),
        price: Kati.Money.display(1399),
        rate: Kati.Money.per_hour(233, 1),
        good?: false
      },
      %{
        badge: "K",
        name: gettext("Kino"),
        line:
          gettext("renews %{date} · %{hours}h watched",
            date: Kati.Locale.date(~D[2026-09-01], :short_padded),
            hours: Kati.Locale.number(19)
          ),
        price: Kati.Money.display(1149),
        rate: Kati.Money.per_hour(60, 1),
        good?: true
      },
      %{
        badge: "A",
        name: gettext("Aria Audio"),
        line: gettext("paused until October · not in the total"),
        price: Kati.Money.display(500),
        rate: "—",
        good?: nil
      }
    ]
  end

  # A drawn expense: a date and an amount formatted where they are read, and a
  # category word from the catalogue. It was three frozen strings, which is why
  # board 127's mirror kept a second copy of all six rows.
  defp expense(name, on, category, pence) do
    %{
      name: name,
      meta: Kati.UI.eyebrow_label(Kati.Locale.date(on, :short_padded) <> " · " <> category),
      amount: Kati.Money.display(pence)
    }
  end

  @doc "The one-off expenses, grouped by month with a total and a delta."
  @spec months() :: [map()]
  def months do
    [
      %{
        label: gettext("August"),
        total: Kati.Money.display(6140),
        direction: :down,
        delta: Kati.Money.display(1210),
        rows: [
          expense(gettext("Kino rental — Blue Hour"), ~D[2026-08-16], gettext("SCREEN"), 349),
          expense(gettext("The Salt Almanac, paperback"), ~D[2026-08-12], gettext("BOOKS"), 999),
          expense(gettext("Cinema — Vellum"), ~D[2026-08-09], gettext("SCREEN"), 1400),
          expense(gettext("Weekly shop"), ~D[2026-08-04], gettext("MEALS"), 3392)
        ]
      },
      %{
        label: gettext("July"),
        total: Kati.Money.display(7350),
        direction: nil,
        delta: nil,
        rows: [
          expense(gettext("Vinyl — Tidal Works"), ~D[2026-07-28], gettext("MUSIC"), 2800),
          expense(gettext("Weekly shop"), ~D[2026-07-21], gettext("MEALS"), 4550)
        ]
      }
    ]
  end

  @doc """
  The cream suggestion at the foot.

  A sentence about a specific service with a specific saving, which is the only
  kind of money advice this app gives — it comes from two figures Kati already
  has, and offers to remind rather than to act.
  """
  @spec suggestion() :: map()
  def suggestion do
    %{
      lead: gettext("You watched"),
      hours: ngettext("%{n} hour", "%{n} hours", 6, n: Kati.Locale.number(6)),
      middle: gettext("on %{service} this month and have", service: gettext("Orbit")),
      titles: ngettext("%{n} title", "%{n} titles", 1, n: Kati.Locale.number(1)),
      tail:
        gettext("left in its queue. Pausing after %{date} saves %{amount}.",
          date: Kati.Locale.date(~D[2026-08-24], :short),
          amount: Kati.Money.display(1399)
        ),
      action: gettext("Remind me %{date}", date: Kati.Locale.date(~D[2026-08-23], :short))
    }
  end
end
