defmodule Kati.Money do
  @moduledoc """
  What Kati costs you: the subscriptions that renew, and the things you bought.

  ## This is not a budgeting app, and the boundary is drawn on purpose

  Screen 122's caption: *23 widened to hold quick-add's expenses without
  becoming a budgeting app: no categories, no budget, no chart.* So there is no
  category column — each expense names the **section** it belongs to, which is
  the only classification Kati has and the same one the home screen and the
  settings page use. Adding categories would mean inventing a taxonomy, and
  then maintaining it, for a feature nobody asked for.

  ## One currency, chosen once, never converted

  `Kati.Money.currency/0` is a device-level setting in `Mob.State`, and screen
  125 states the consequence in the bluntest terms it can find: *£8.99 becomes
  €8.99, not €10.42.* That is not a shortcut — Kati has no server, so it cannot
  know what yesterday's rate was, and a converted history that quietly used
  today's rate would be worse than no conversion at all.

  Formatting comes from CLDR through `Kati.Cldr`, so Persian gets U+066C and
  U+066B, arabext digits, and the currency word after the figure — never
  hand-placed.

  ## The figure worth looking at is cost per watched hour

  Screen 122 says so and it is the reason this module exists rather than a
  column on `Kati.Services.Service`: `£0.21/h` needs a price **and** hours
  watched, which live in two different domains. `per_hour/2` is where they
  meet, and it is the only number on the page a bank could not have told you.
  """

  use Ash.Domain, validate_config_inclusion?: false

  resources do
    resource Kati.Money.Expense
  end

  @currency_key :kati_currency

  # The five screen 125 offers, as `{code, symbol, name}`. Not every currency
  # CLDR knows: the list is what the drawing draws, and a picker of 300 rows is
  # a different screen with a search field on it.
  @currencies [
    {"GBP", "£", "Pound sterling"},
    {"EUR", "€", "Euro"},
    {"USD", "$", "US dollar"},
    {"IRR", "﷼", "Iranian rial"},
    {"TRY", "₺", "Turkish lira"}
  ]

  @doc "Every currency screen 125 offers."
  @spec currencies() :: [{String.t(), String.t(), String.t()}]
  def currencies, do: @currencies

  @doc "The one currency every amount is recorded and shown in. `GBP` by default."
  @spec currency() :: String.t()
  def currency do
    case Mob.State.get(@currency_key) do
      code when is_binary(code) -> code
      _other -> "GBP"
    end
  end

  @doc """
  Change the currency.

  Changes the symbol and the formatting and **nothing else** — no stored figure
  moves. That is the whole content of screen 125's confirmation, and it is true
  here by construction: there is no code path in this module that rewrites an
  amount.
  """
  @spec put_currency(String.t()) :: :ok
  def put_currency(code) when is_binary(code) do
    Mob.State.put(@currency_key, code)
    :ok
  end

  @doc "A currency's symbol, or the code itself for one this list has not got."
  @spec symbol(String.t()) :: String.t()
  def symbol(code) do
    case Enum.find(@currencies, fn {c, _symbol, _name} -> c == code end) do
      {_code, symbol, _name} -> symbol
      nil -> code
    end
  end

  @doc "A currency's name, or the code."
  @spec name(String.t()) :: String.t()
  def name(code) do
    case Enum.find(@currencies, fn {c, _symbol, _name} -> c == code end) do
      {_code, _symbol, name} -> name
      nil -> code
    end
  end

  @doc """
  An amount in minor units, formatted for the current locale and currency.

  Through `Kati.Cldr`, which is why Persian comes out with the group and
  decimal marks its own locale uses and the currency word trailing the figure.
  Falls back to a plain symbol-and-digits form if CLDR has nothing to say about
  the code, rather than raising on a screen that is only trying to print a
  price.
  """
  @spec format(integer(), String.t() | nil) :: String.t()
  def format(minor_units, code \\ nil) do
    code = code || currency()
    amount = Decimal.div(Decimal.new(minor_units), 100)

    case Kati.Cldr.Number.to_string(amount,
           currency: code,
           locale: Kati.Locale.current(),
           format: :currency
         ) do
      {:ok, formatted} -> formatted
      _other -> plain(minor_units, code)
    end
  rescue
    _error -> plain(minor_units, code || "GBP")
  end

  defp plain(minor_units, code) do
    sign = if minor_units < 0, do: "-", else: ""
    abs = abs(minor_units)

    sign <>
      symbol(code) <>
      "#{div(abs, 100)}.#{String.pad_leading(Integer.to_string(rem(abs, 100)), 2, "0")}"
  end

  @doc """
  Cost per watched hour: `£0.21/h`, or `—` for a service nothing was watched on.

  An em dash rather than an infinity or a zero. A service you paid for and did
  not watch has no cost per hour — the figure is undefined, and printing
  anything numeric there would be inventing one.
  """
  @spec per_hour(integer(), number()) :: String.t()
  def per_hour(_pence, hours) when hours <= 0, do: "—"

  def per_hour(pence, hours) do
    per = round(pence / hours)
    format(per) <> "/h"
  end
end
