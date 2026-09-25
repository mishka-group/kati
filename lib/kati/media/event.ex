defmodule Kati.Media.Event do
  @moduledoc """
  What happened to a title, in the order it happened. **Append-only.**

  Screen 15's own moduledoc named this resource and named why it was missing:

  > `Dropped … after S1E3` and `Imported 412 titles from a CSV backup` are the
  > other four rows the sample carries, and none of them has a store: a status
  > moving from `:watching` to `:dropped` overwrites a column on
  > `Kati.Media.TrackedTitle` and leaves nothing behind … That is a missing
  > resource, not a missing query.

  This is that table.

  ## Why a status column is not enough

  `Kati.Media.TrackedTitle.status` is where a title *is*. It cannot say when it
  got there, what it was before, or why — every one of those is overwritten by
  the next change, and all three are things screen 15 draws. A title added in
  March, dropped in July and picked back up in September has one status and
  three events, and the log is about the three.

  The reason is the sharpest case. Screen 149 asks *why* and offers five
  answers, and until this existed the answer was assigned to a socket and
  thrown away the moment the sheet closed — the one question in the app whose
  answer nothing could ever read back.

  ## Why not a row on `Kati.Media.Watch`

  A watch is an act of watching. Dropping a show is the opposite of one, and
  adding a title is neither. Folding them together would make every count of
  *how many times have I seen this* wrong by however many times the shelf
  changed its mind.

  ## Append-only, and what that costs

  No update action and no destroy of one row: an event is a fact about the
  past. `:destroy` stays for the title's own cascade — deleting a tracked title
  takes its events with it, because an event about a title that no longer
  exists is a row nobody can render.

  ## The position is a label snapshot

  `season_number` and `episode_number` are written at drop time and never read
  back as identity, for `Kati.Media.Watch`'s reason: aired, absolute and DVD
  orders renumber the same season. *Dropped after S1E3* is what the reader saw
  on the day, and it stays what they saw.
  """
  use Ash.Resource, domain: Kati.Media, data_layer: AshSqlite.DataLayer

  sqlite do
    table "media_events"
    repo Kati.Repo

    custom_indexes do
      # Screen 15's log across every title, newest first.
      index [:at]
      # This title's own history — screen 08's ⋯ and screen 04's header.
      index [:tracked_title_id, :at]
    end
  end

  attributes do
    uuid_primary_key :id

    # What happened. One of the verbs screen 15 draws, and no others.
    #
    # `:dropped`, `:abandoned` and `:dnf` are three answers to one sheet and
    # stay three kinds rather than one with a flag, because screen 149's own
    # copy distinguishes them and screen 15 prints the word.
    attribute :kind, :atom,
      description: "What happened to the title.",
      allow_nil?: false,
      public?: true,
      constraints: [
        one_of: [:added, :dropped, :abandoned, :dnf, :resumed, :finished, :imported]
      ]

    # When, as an instant. Screen 15 groups by day and screen 08 prints a date,
    # and both derive theirs from this — one field, because unlike a watch
    # ("watched on 12 August, I forget the hour") an event is something the app
    # itself observed and always knows the hour of.
    attribute :at, :utc_datetime_usec, allow_nil?: false, public?: true

    # Where the reader had got to. Both nil for a film, and for anything that
    # has no position — an import, an add.
    attribute :season_number, :integer, public?: true, constraints: [min: 0]
    attribute :episode_number, :integer, public?: true, constraints: [min: 0]

    # Why, in the reader's own words or screen 149's. Free text rather than an
    # enum: the sheet offers five and a sixth field, and an enum would make
    # *Something else* unstorable — which is the answer most worth keeping.
    attribute :reason, :string, public?: true

    # What it was before, where that is known. Screen 15 draws
    # `Watching → Dropped` and this is the left half; nil where there was no
    # before, which is every `:added`.
    attribute :from_status, :atom, public?: true

    # How many titles an import brought in. Only ever set on `:imported`, which
    # is the one kind that is about a batch rather than a title — see
    # `tracked_title` below.
    attribute :count, :integer, public?: true, constraints: [min: 0]

    # Where an import came from, as the reader would say it: `Letterboxd`.
    attribute :source_label, :string, public?: true

    timestamps()
  end

  relationships do
    # Nullable, unlike `Kati.Media.Watch`'s: an import is an event with no one
    # title behind it. Screen 15 draws it as a row all the same — *Imported 412
    # titles from a CSV backup* is the sample's own line — and forcing a title
    # onto it would mean either inventing one or not recording the import.
    belongs_to :tracked_title, Kati.Media.TrackedTitle,
      allow_nil?: true,
      attribute_writable?: true,
      attribute_public?: true
  end

  actions do
    # No `:update`. An event is a fact about the past, and the one thing this
    # table exists to stop is a change overwriting what came before it.
    defaults [:read, :destroy, create: :*]
    default_accept :*

    read :for_title do
      description "Everything that has happened to one title, newest first."
      argument :tracked_title_id, :uuid, allow_nil?: false
      filter expr(tracked_title_id == ^arg(:tracked_title_id))
      prepare build(sort: [at: :desc])
    end

    read :recent do
      description "The log across every title, newest first."
      prepare build(sort: [at: :desc])
    end
  end
end
