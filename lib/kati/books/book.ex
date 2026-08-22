defmodule Kati.Books.Book do
  @moduledoc """
  One book, and where you are in it.

  ## Why `status` is five values and not four

  Screen 66's status control offers four — *Reading · Finished · Paused · Did
  not finish* — and screen 67 draws a fifth state, **not started**, whose
  primary button reads `Start reading` rather than `Log progress`. A book you
  have added and not opened is not "paused", and calling it that would make the
  shelf's `2 reading` count a lie the moment you add three books at once. So
  `:not_started` is the default, and the four the control offers are the four
  you can move *to*.

  ## Page count and duration are one field each, never both

  An audiobook has no pages and a paperback has no runtime, and the drawing
  restates the unit on switch — *380 pages* against *11h 20m* — precisely so
  the number never looks like the other kind. Storing both and showing one
  would let an edition switch silently keep a stale figure, so `format` is what
  decides which of `page_count` and `duration_minutes` is meaningful, and
  `extent/1` is the only thing that reads them.

  `page_count` is nullable on purpose. Screen 67's *partial metadata* state is
  a real Open Library answer — a work with no pagination — and the screen draws
  `p. 214 · NO PAGE COUNT` and an `Add page count` affordance rather than
  inventing a denominator.

  ## Lending

  `lent_to` and `lent_due_on` sit here rather than in their own resource
  because a book is lent to at most one person at a time and Kati has no reason
  to remember who had it in 2019. When it does, this becomes a relationship and
  these two become the newest row.
  """

  use Ash.Resource, domain: Kati.Books, data_layer: AshSqlite.DataLayer

  sqlite do
    table "books"
    repo Kati.Repo

    custom_indexes do
      # The shelf's own order — screen 20 puts the most recently touched first,
      # exactly as `Kati.Media.TrackedTitle`'s `:shelf` does for films.
      index [:updated_at]

      # Screen 20's `2 reading` chip, and screen 66's referent when nothing
      # names a book: the one you are reading.
      index [:status, :updated_at]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :title, :string, allow_nil?: false, public?: true
    attribute :author, :string, public?: true

    # Open Library's work key when the book came from there, `nil` when it was
    # typed. Kept as a value rather than a foreign key for the reason
    # `Kati.Media` gives: a cache row may go, the book may not.
    attribute :source, :atom,
      allow_nil?: false,
      default: :manual,
      public?: true,
      constraints: [one_of: [:manual, :open_library, :import]]

    attribute :source_id, :string, public?: true

    # The picsum seed the drawing was captured from, so a sample book and a
    # real one reach `Kati.Design.Images.poster/1` the same way.
    attribute :cover_seed, :string, public?: true

    attribute :publisher, :string, public?: true
    attribute :published_year, :integer, public?: true
    attribute :isbn, :string, public?: true

    attribute :status, :atom,
      allow_nil?: false,
      default: :not_started,
      public?: true,
      constraints: [one_of: [:not_started, :reading, :finished, :paused, :did_not_finish]]

    attribute :format, :atom,
      allow_nil?: false,
      default: :paperback,
      public?: true,
      constraints: [one_of: [:paperback, :ebook, :audiobook]]

    attribute :page_count, :integer, public?: true, constraints: [min: 1]
    attribute :duration_minutes, :integer, public?: true, constraints: [min: 1]

    # Where you are. Rewritten by every session; see the domain's moduledoc for
    # why it is stored rather than derived.
    attribute :current_page, :integer, allow_nil?: false, default: 0, public?: true

    # Screen 67's *did not finish* state draws `STOPPED AT p. 148 / 380 · 39%`,
    # which is not the same fact as `current_page`: you can stop at 148 and
    # later re-read to 200 without un-abandoning the book. Written only when
    # `status` becomes `:did_not_finish`.
    attribute :stopped_at_page, :integer, public?: true

    # Free text, because D-14 owns the reason vocabulary and had not shipped
    # one. A closed enum here would have to be guessed and then migrated.
    attribute :did_not_finish_reason, :string, public?: true

    # Screen 66's `This is the edition I own` toggle.
    attribute :owned, :boolean, allow_nil?: false, default: false, public?: true

    attribute :lent_to, :string, public?: true
    attribute :lent_due_on, :date, public?: true

    # Halves, as `Kati.Media.TrackedTitle` stores them, so `★★★★½` is an
    # integer and `4.5` is a rendering of it.
    attribute :rating, :integer, public?: true, constraints: [min: 0, max: 10]

    attribute :series_name, :string, public?: true
    attribute :series_position, :integer, public?: true, constraints: [min: 1]
    attribute :series_total, :integer, public?: true, constraints: [min: 1]

    timestamps()
  end

  relationships do
    has_many :sessions, Kati.Books.ReadingSession do
      destination_attribute :book_id
      public? true
    end

    has_many :notes, Kati.Books.Note do
      destination_attribute :book_id
      public? true
    end
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]

    read :shelf do
      description "Every book, most recently touched first — screen 20's order."
      prepare build(sort: [updated_at: :desc])
    end

    read :reading do
      description "The books in progress, newest first. Screen 20's `2 reading`."
      filter expr(status == :reading)
      prepare build(sort: [updated_at: :desc])
    end
  end

  @doc """
  The book's extent as `{amount, unit}`, or `nil` when the edition has none.

  The unit follows `format` rather than which column happens to be filled, so
  switching a paperback to an audiobook stops reporting its page count in the
  same render the chip changes — screen 66's *restate the unit on switch*.
  """
  @spec extent(t()) :: {pos_integer(), :pages | :minutes} | nil
  def extent(%__MODULE__{format: :audiobook, duration_minutes: m}) when is_integer(m) and m > 0,
    do: {m, :minutes}

  def extent(%__MODULE__{format: format, page_count: p})
      when format in [:paperback, :ebook] and is_integer(p) and p > 0,
      do: {p, :pages}

  def extent(%__MODULE__{}), do: nil

  @doc """
  How far through the book you are, `0.0..1.0`, or `nil` with no denominator.

  `nil` rather than `0.0`, because screen 67's partial-metadata state draws no
  bar at all — a bar pinned at zero would say "you have read none of it", which
  is the one thing the state exists to avoid claiming.
  """
  @spec fraction(t()) :: float() | nil
  def fraction(%__MODULE__{current_page: page} = book) do
    case extent(book) do
      {total, :pages} when total > 0 and is_integer(page) -> min(page / total, 1.0)
      _other -> nil
    end
  end

  @doc """
  The line under the cover on screen 20's grid: `p.214/380`, `finished`,
  `to read`, or `p.214` when nothing says how long the book is.
  """
  @spec shelf_line(t()) :: String.t()
  def shelf_line(%__MODULE__{status: :finished}), do: "finished"
  def shelf_line(%__MODULE__{status: :not_started}), do: "to read"

  def shelf_line(%__MODULE__{current_page: page} = book) do
    case extent(book) do
      {total, :pages} -> "p.#{page}/#{total}"
      _other -> "p.#{page}"
    end
  end

  @doc "Screen 66's series row: `#3 of 7 in The Coastal Ledgers`, or `nil`."
  @spec series_line(t()) :: String.t() | nil
  def series_line(%__MODULE__{series_name: name, series_position: at, series_total: of})
      when is_binary(name) and is_integer(at) and is_integer(of),
      do: "##{at} of #{of} in #{name}"

  def series_line(%__MODULE__{series_name: name, series_position: at})
      when is_binary(name) and is_integer(at),
      do: "##{at} in #{name}"

  def series_line(%__MODULE__{}), do: nil

  @type t :: %__MODULE__{}
end
