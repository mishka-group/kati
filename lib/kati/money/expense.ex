defmodule Kati.Money.Expense do
  @moduledoc """
  One thing you bought.

  ## No categories, and that is the design

  Screen 122's caption forbids them by name. What an expense has instead is a
  **section** — Screen, Books, Music, Meals — which is the classification the
  whole app already runs on: the same list screen 24's Sections group toggles
  and the same one the home screen orders its cards by. One taxonomy, reused,
  rather than a second one invented for money.

  ## An amount is optional, and a screen says so

  Screen 124's whole subject: *an expense with no amount still counts as a
  thing that happened.* So `amount_pence` is nullable, and the sheet's missing
  amount is an inline field ringed in orange rather than a warning row — a
  warning implies something is wrong, and "bought a book, forgot the price" is
  a perfectly good record.

  The currency is stored per row rather than read at render, because screen 125
  changes the *display* currency and must not touch a stored figure. A row that
  read the current setting would silently relabel £8.99 as €8.99 — which is
  exactly what the confirmation promises does not happen.
  """

  use Ash.Resource, domain: Kati.Money, data_layer: AshSqlite.DataLayer

  sqlite do
    table "expenses"
    repo Kati.Repo

    custom_indexes do
      # Screen 122 groups by month, newest first.
      index [:spent_on]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :description, :string, allow_nil?: false, public?: true

    # Minor units, for the reason `Kati.Services.Service` gives. Nullable — see
    # the moduledoc.
    attribute :amount_pence, :integer, public?: true

    # Stored, not read. See the moduledoc.
    attribute :currency, :string, allow_nil?: false, default: "GBP", public?: true

    attribute :spent_on, :date, allow_nil?: false, public?: true

    attribute :section, :atom,
      allow_nil?: false,
      default: :other,
      public?: true,
      constraints: [one_of: [:screen, :books, :music, :meals, :habits, :other]]

    timestamps()
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]

    read :recent do
      description "Every expense, newest first — screen 122's month groups."
      prepare build(sort: [spent_on: :desc, inserted_at: :desc])
    end
  end

  @doc "The section's label, in the drawing's own capitals: `16 AUG · SCREEN`."
  @spec meta(t()) :: String.t()
  def meta(%__MODULE__{spent_on: on, section: section}) do
    String.upcase(Calendar.strftime(on, "%d %b") <> " · " <> section_label(section))
  end

  @doc "A section's display name."
  @spec section_label(atom()) :: String.t()
  def section_label(:screen), do: "Screen"
  def section_label(:books), do: "Books"
  def section_label(:music), do: "Music"
  def section_label(:meals), do: "Meals"
  def section_label(:habits), do: "Habits"
  def section_label(_other), do: "Other"

  @doc "The amount as the row prints it, or `nil` for one nobody priced."
  @spec amount(t()) :: String.t() | nil
  def amount(%__MODULE__{amount_pence: nil}), do: nil

  def amount(%__MODULE__{amount_pence: pence, currency: currency}),
    do: Kati.Money.format(pence, currency)

  @doc """
  Group expenses by calendar month, newest month first, each with its total.

  Returns `{label, total_pence, rows}`. Rows with no amount are kept in their
  group and contribute nothing to the total, which is the only honest way to
  total a list that contains an unpriced thing.
  """
  @spec by_month([t()]) :: [{String.t(), integer(), [t()]}]
  def by_month(expenses) do
    expenses
    |> Enum.group_by(&{&1.spent_on.year, &1.spent_on.month})
    |> Enum.sort_by(fn {key, _rows} -> key end, :desc)
    |> Enum.map(fn {_key, rows} ->
      total = rows |> Enum.map(&(&1.amount_pence || 0)) |> Enum.sum()
      label = rows |> hd() |> Map.fetch!(:spent_on) |> Calendar.strftime("%B")
      {label, total, Enum.sort_by(rows, & &1.spent_on, {:desc, Date})}
    end)
  end

  @type t :: %__MODULE__{}
end
