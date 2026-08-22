defmodule Kati.Media.WarningPreference do
  @moduledoc """
  What Kati should do when a title carries a warning category — *Settings →
  Content I'd rather avoid*.

  ## Three states, not a switch

  D-13 asks for **Avoid · Warn me · Show**, and the middle one is the reason
  this is not a boolean. "Avoid" hides a title from Discover and Search;
  "Warn me" still shows it and flags it. Collapsing those into on/off forces
  the user to choose between never seeing something and getting no warning
  about it, which is the choice the screen exists to avoid making them make.

  `:show` is the default and is stored explicitly when chosen. A row that
  exists saying `:show` and no row at all mean the same thing today, and will
  not once the screen can list "categories you have decided about" — deciding
  to show something is a decision.

  ## Keyed on the category string

  `Kati.Media.ContentWarning.category` is normalised on write precisely so this
  key is an equality test. There is no foreign key because there is nothing to
  point at: a preference can exist for a category no title has yet, which is
  the useful case — the user says "avoid animal death" before meeting one.
  """

  use Ash.Resource, domain: Kati.Media, data_layer: AshSqlite.DataLayer

  sqlite do
    table "media_warning_preferences"
    repo Kati.Repo

    custom_indexes do
      index [:category], unique: true
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :category, :string, allow_nil?: false, public?: true

    attribute :stance, :atom,
      allow_nil?: false,
      default: :show,
      public?: true,
      constraints: [one_of: [:avoid, :warn, :show]]

    timestamps()
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]
  end

  @doc """
  What to do with a title carrying `categories`, given the user's preferences.

  `:avoid` wins over `:warn` wins over `:show`, because a title carrying two
  warnings should be treated as its worst one. Anything with no preference is
  `:show` — an unrecorded category is not a silent avoid.
  """
  @spec verdict([String.t()], %{String.t() => atom()}) :: :avoid | :warn | :show
  def verdict(categories, preferences) do
    categories
    |> Enum.map(&Map.get(preferences, &1, :show))
    |> Enum.reduce(:show, fn
      :avoid, _acc -> :avoid
      _stance, :avoid -> :avoid
      :warn, _acc -> :warn
      _stance, :warn -> :warn
      stance, _acc -> stance
    end)
  end
end
