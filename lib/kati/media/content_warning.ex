defmodule Kati.Media.ContentWarning do
  @moduledoc """
  A content warning on a title, entered by the person using Kati.

  ## The honesty problem this resource is shaped around

  Kati has **no source** for content warnings. Open Library carries none, and
  StoryGraph's are its own dataset rather than an API. D-13 states the
  consequence plainly: a warnings block that is always empty is worse than
  none, so the design must say where warnings come from.

  They come from here — the user's own entries, plus whatever an import brings
  in. That is why `origin` exists and why it is not decoration: a warning the
  user typed and a warning a StoryGraph CSV supplied should not be presented as
  equally authoritative, and only the row knows which it is.

  ## Why a resource rather than a column on the title

  Three reasons, in order of how much they cost to get wrong:

    * **A warning has a severity per person, not per title.** The same warning
      is "avoid" for one reader and "show" for another, and that preference
      lives in `Kati.Media.WarningPreference` keyed on the category — so the
      category has to be a value something else can key on, not free text
      buried in a title's row.
    * **They are queried.** Screens 11 and 19 flag or hide a title whose
      warnings match an avoided category. `Kati.Media.Watch`'s `tags` column
      earned its comma-separated string by having no reader; this has two.
    * **An import writes many at once.** A StoryGraph CSV is the one realistic
      bulk source, and rows are what an import produces.

  ## Categories are open, and that is deliberate

  Unlike `Kati.Media.Mood`, whose closed vocabulary exists so it can be
  aggregated, a warning is a thing that happened in a story and nobody owns the
  list. A fixed enum would make the feature useless for the warning the user
  actually needs to record. `category` is therefore a free string, normalised
  on the way in so "Animal death" and "animal death" are one category rather
  than two.
  """

  use Ash.Resource, domain: Kati.Media, data_layer: AshSqlite.DataLayer

  sqlite do
    table "media_content_warnings"
    repo Kati.Repo

    custom_indexes do
      # Screens 11 and 19: does this title carry a category the user avoids.
      index [:tracked_title_id, :category]
    end
  end

  attributes do
    uuid_primary_key :id

    # Normalised on write — see `normalise/1`. Stored lower-case so a lookup
    # against `Kati.Media.WarningPreference` is an equality test rather than a
    # case-insensitive scan the index cannot serve.
    attribute :category, :string, allow_nil?: false, public?: true

    # The user's own words about this title, kept apart from the category so
    # the category stays joinable. Optional: most warnings are the category.
    attribute :note, :string, public?: true

    # Where the row came from. `:user` outranks `:import` when the two disagree,
    # for the same reason `TrackedTitle.user_override_date` outranks a provider:
    # somebody typed it.
    attribute :origin, :atom,
      allow_nil?: false,
      default: :user,
      public?: true,
      constraints: [one_of: [:user, :import]]

    timestamps()
  end

  relationships do
    belongs_to :tracked_title, Kati.Media.TrackedTitle do
      allow_nil? false
      public? true
    end
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]
  end

  @doc """
  The stored form of a category.

  Trimmed, collapsed and lower-cased, so "Animal  Death " and "animal death"
  are the same category. Returns `nil` for anything that normalises to nothing,
  which the caller should treat as "no warning given" rather than storing an
  empty row.
  """
  @spec normalise(String.t() | nil) :: String.t() | nil
  def normalise(nil), do: nil

  def normalise(category) when is_binary(category) do
    category
    |> String.trim()
    |> String.replace(~r/\s+/u, " ")
    |> String.downcase()
    |> case do
      "" -> nil
      normalised -> normalised
    end
  end

  @doc """
  A category's display form: the stored value, capitalised.

  Derived rather than stored for the reason `Kati.Media.Mood.label/1` gives —
  a second copy is a second place to drift.
  """
  @spec label(String.t()) :: String.t()
  def label(category) when is_binary(category), do: String.capitalize(category)
end
