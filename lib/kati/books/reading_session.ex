defmodule Kati.Books.ReadingSession do
  @moduledoc """
  One sitting: the pages it covered and the minutes it took.

  Append-only. Screen 70 writes one, screen 66's history band reads them back,
  and nothing edits one after the fact — an undo deletes the row rather than
  rewriting it, which is why screen 71's `Undo` is drawn as a pill that removes
  a thing rather than a form that corrects one.

  ## `from_page` is stored, not inferred

  The obvious saving is to keep only `to_page` and read the previous session's
  as the start. Two things break that. A book read before Kati has no previous
  session, so the first row would claim to start at page one. And screen 71's
  re-read case writes a session whose pages run *backwards* through material
  already covered — `Log a re-read` — so "previous row's end" is not where the
  next one begins. Both are ordinary, so both columns are real.

  ## Minutes may be absent

  Screen 70 offers a manual field and a timer, and the manual field asks only
  for a page. A session with no minutes is a session that happened, and it must
  not be dropped from the history band just because it cannot contribute to a
  pace. `pace/1` skips them; the band shows them without a duration.
  """

  use Ash.Resource, domain: Kati.Books, data_layer: AshSqlite.DataLayer

  sqlite do
    table "book_reading_sessions"
    repo Kati.Repo

    custom_indexes do
      # Screen 66's history band, and `pace/1`'s seven-day window.
      index [:book_id, :read_on]
    end
  end

  attributes do
    uuid_primary_key :id

    # A date rather than a timestamp, for the reason `Kati.Media.Watch` keeps
    # `watched_on` beside `watched_at`: the history band groups by day, and a
    # session that starts at 23:50 belongs to the evening it felt like.
    attribute :read_on, :date, allow_nil?: false, public?: true

    # Kept as well, when known, so a timer session can say when it ran. Null
    # for a session entered by hand days later.
    attribute :started_at, :utc_datetime, public?: true

    attribute :from_page, :integer, allow_nil?: false, public?: true, constraints: [min: 0]
    attribute :to_page, :integer, allow_nil?: false, public?: true, constraints: [min: 0]

    attribute :minutes, :integer, public?: true, constraints: [min: 0]

    attribute :source, :atom,
      allow_nil?: false,
      default: :manual,
      public?: true,
      constraints: [one_of: [:manual, :timer, :import]]

    # Screen 71's `Log a re-read`. A re-read covers pages already read, so it
    # must not move `current_page` backwards and must not count towards
    # progress — but it is real reading and does count towards pace.
    attribute :reread, :boolean, allow_nil?: false, default: false, public?: true

    timestamps()
  end

  relationships do
    belongs_to :book, Kati.Books.Book do
      allow_nil? false
      public? true
    end
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]

    read :for_book do
      description "One book's sessions, newest first — screen 66's history band."
      argument :book_id, :uuid, allow_nil?: false
      filter expr(book_id == ^arg(:book_id))
      prepare build(sort: [read_on: :desc, inserted_at: :desc])
    end
  end

  @doc "Pages covered by this session. Always positive; a re-read counts its span."
  @spec pages(t()) :: non_neg_integer()
  def pages(%__MODULE__{from_page: from, to_page: to}), do: abs(to - from)

  @doc """
  The pace figure both screen 20 and screen 66 print, in minutes per day.

  Screen 70's caption is the specification: *minutes read across the last seven
  calendar days ÷ 7, so a skipped night dilutes the figure rather than
  vanishing from it.* The divisor is therefore always seven — not the number of
  days that happen to have a session — and `today` is passed in rather than
  read, so the arithmetic is testable without a clock.

  `nil` when no session in the window recorded any minutes: a pace of zero and
  "nobody timed anything" are different claims, and only one of them belongs on
  a card.
  """
  @spec pace([t()], Date.t()) :: non_neg_integer() | nil
  def pace(sessions, %Date{} = today) do
    from = Date.add(today, -6)

    minutes =
      sessions
      |> Enum.filter(fn %__MODULE__{read_on: on} ->
        Date.compare(on, from) != :lt and Date.compare(on, today) != :gt
      end)
      |> Enum.map(& &1.minutes)
      |> Enum.reject(&is_nil/1)

    case minutes do
      [] -> nil
      list -> div(Enum.sum(list), 7)
    end
  end

  @doc """
  Screen 66's history row: `p. 168 → 214`.

  An arrow rather than a dash because the direction is the information — screen
  71's re-read runs the other way and must read as one.
  """
  @spec span_line(t()) :: String.t()
  def span_line(%__MODULE__{from_page: from, to_page: to}), do: "p. #{from} → #{to}"

  @doc "Screen 66's trailing duration, `38m`, or `nil` when the sitting was untimed."
  @spec duration_line(t()) :: String.t() | nil
  def duration_line(%__MODULE__{minutes: m}) when is_integer(m) and m > 0, do: "#{m}m"
  def duration_line(%__MODULE__{}), do: nil

  @type t :: %__MODULE__{}
end
