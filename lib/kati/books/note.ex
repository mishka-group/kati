defmodule Kati.Books.Note do
  @moduledoc """
  A quote you copied out, or a note you left yourself.

  Screen 66 draws both in one cream card, and the design's own caption for
  screen 08 says why the card is cream: *it is the one place the palette warms
  up*, marking the user's own words as different from metadata. Two kinds share
  the card because they share that property, and `kind` is what decides whether
  the body is set in quotation marks.

  `page` is the anchor and it is optional. A thought about a book is not always
  a thought about a page, and a note with no anchor is still worth keeping —
  the drawing's mono `p. 148` simply does not appear on it.
  """

  use Ash.Resource, domain: Kati.Books, data_layer: AshSqlite.DataLayer

  sqlite do
    table "book_notes"
    repo Kati.Repo

    custom_indexes do
      index [:book_id, :page]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :body, :string, allow_nil?: false, public?: true

    attribute :kind, :atom,
      allow_nil?: false,
      default: :note,
      public?: true,
      constraints: [one_of: [:quote, :note]]

    attribute :page, :integer, public?: true, constraints: [min: 0]

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
      description "One book's notes, in page order — the order the reader met them."
      argument :book_id, :uuid, allow_nil?: false
      filter expr(book_id == ^arg(:book_id))
      prepare build(sort: [page: :asc, inserted_at: :asc])
    end
  end

  @doc "The anchor line, `p. 148`, or `nil` when the note is not about a page."
  @spec anchor(t()) :: String.t() | nil
  def anchor(%__MODULE__{page: page}) when is_integer(page) and page > 0, do: "p. #{page}"
  def anchor(%__MODULE__{}), do: nil

  @doc """
  The body as the card prints it: a quote wears typographic quotation marks,
  a note does not.

  Applied here rather than in the screen so the two screens that draw notes —
  66 and its dark twin 68 — cannot disagree about it.
  """
  @spec display(t()) :: String.t()
  def display(%__MODULE__{kind: :quote, body: body}), do: "“" <> body <> "”"
  def display(%__MODULE__{body: body}), do: body

  @type t :: %__MODULE__{}
end
