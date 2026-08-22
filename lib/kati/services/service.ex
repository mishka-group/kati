defmodule Kati.Services.Service do
  @moduledoc """
  One streaming service, and what it costs you.

  ## Price is pence, and the currency is beside it

  `£8.99` is `899` and `"GBP"`, never a float. Screen 92 sums three of these
  into `£46.47 A MONTH` and screen 23 divides one by watched hours to get a
  cost per hour, and both of those are arithmetic that floats get wrong in the
  third decimal place and then print.

  The currency is stored per service rather than taken from the region, because
  they genuinely differ: a service billed in dollars does not become a pound
  when you move.

  ## Three tiers, and `:not_mine` is one of them

  Screen 92 lists services you do not subscribe to — *Not mine*, and *Show all
  47*. That is not clutter: knowing a title is on a service you have **not**
  got is what makes `Hide titles I can't watch` mean anything, so a service the
  user has explicitly marked as not theirs is a fact worth keeping.

  `:free_with_ads` is its own tier and not a `:subscribed` at zero, because
  free is a property of the service and zero is a price somebody might have
  failed to fill in.
  """

  use Ash.Resource, domain: Kati.Services, data_layer: AshSqlite.DataLayer

  sqlite do
    table "services"
    repo Kati.Repo

    custom_indexes do
      # Screen 92's three groups, each in its own order.
      index [:tier, :name]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string, allow_nil?: false, public?: true

    # The letter tile. Derived from the name by default — see `badge/1` — and a
    # column because a service whose initial is not its mark ("+" for Apple TV+)
    # needs somewhere to say so.
    attribute :badge, :string, public?: true

    attribute :tier, :atom,
      allow_nil?: false,
      default: :subscribed,
      public?: true,
      constraints: [one_of: [:subscribed, :free_with_ads, :not_mine]]

    # Pence, cents, rials — the minor unit of `currency`. See the moduledoc.
    attribute :monthly_pence, :integer, public?: true, constraints: [min: 0]
    attribute :currency, :string, allow_nil?: false, default: "GBP", public?: true

    attribute :renews_on, :date, public?: true
    attribute :paused, :boolean, allow_nil?: false, default: false, public?: true

    # JustWatch's own id where the service came from its catalogue, `nil` for
    # one the user typed under `Something else`. Screen 92 says what that costs:
    # *Kati will remember it for your subscription total, but cannot tell you
    # what is on it.*
    attribute :provider_id, :string, public?: true

    timestamps()
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]

    read :listed do
      description "Every service, grouped as screen 92 groups them."
      prepare build(sort: [tier: :asc, name: :asc])
    end

    read :subscribed do
      description "The ones you pay for — screen 92's total and screen 23's list."
      filter expr(tier == :subscribed)
      prepare build(sort: [name: :asc])
    end
  end

  @doc """
  The letter tile: the stored badge, or the name's first character.

  Upper-cased, and never empty for the reason `Kati.Music.Album.initial/1`
  gives — a blank tile reads as a failure rather than as a choice.
  """
  @spec badge(t()) :: String.t()
  def badge(%__MODULE__{badge: badge}) when is_binary(badge) and badge != "", do: badge

  def badge(%__MODULE__{name: name}) when is_binary(name) do
    case String.trim(name) do
      "" -> "?"
      trimmed -> trimmed |> String.first() |> String.upcase()
    end
  end

  def badge(%__MODULE__{}), do: "?"

  @doc """
  A price as the screens print it: `£8.99`.

  Two decimal places always, because a price that renders as `£9` beside one
  that renders as `£13.99` reads as an estimate. Currencies with no minor unit
  are not handled and are not pretended to be — there is no service in the
  catalogue billed in yen, and inventing a rule for one would be inventing a
  rule nobody could check.
  """
  @spec price(t()) :: String.t() | nil
  def price(%__MODULE__{monthly_pence: nil}), do: nil

  def price(%__MODULE__{monthly_pence: pence, currency: currency}) do
    symbol(currency) <>
      "#{div(pence, 100)}.#{String.pad_leading(Integer.to_string(rem(pence, 100)), 2, "0")}"
  end

  @doc "The total of a list of services, formatted. `nil` when none of them has a price."
  @spec total([t()]) :: String.t() | nil
  def total([]), do: nil

  def total(services) do
    priced = Enum.reject(services, &is_nil(&1.monthly_pence))

    case priced do
      [] ->
        nil

      [%__MODULE__{currency: currency} | _rest] ->
        pence = Enum.sum(Enum.map(priced, & &1.monthly_pence))

        symbol(currency) <>
          "#{div(pence, 100)}.#{String.pad_leading(Integer.to_string(rem(pence, 100)), 2, "0")}"
    end
  end

  # Three symbols and a fallback that prints the code with a space. Not a
  # currency library: Kati bills nobody and displays what the user typed, so a
  # code the user can read is a better failure than a symbol Kati guessed.
  defp symbol("GBP"), do: "£"
  defp symbol("USD"), do: "$"
  defp symbol("EUR"), do: "€"
  defp symbol(code), do: code <> " "

  @type t :: %__MODULE__{}
end
