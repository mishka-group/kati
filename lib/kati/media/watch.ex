defmodule Kati.Media.Watch do
  @moduledoc """
  One act of watching, reading or listening. **Never evicted.**

  Screen 04's episode tick and screen 33's log sheet are the same fact recorded
  at two levels of detail, so they are one row shape rather than two resources:
  a tick is a watch with an episode and nothing else filled in, and a log is a
  watch of the whole title carrying a rating, a review, a date, a place and the
  people who were there. Splitting them would put "when did I see this" in two
  tables and make the activity log on screen 15 a union query for no gain.

  ## The tick follows the episode, not the number

  Screen 34 states the requirement outright: *"progress is stored per episode so
  switching order never loses a tick … your ticks follow the episode, not the
  number."* Aired, absolute and DVD orders renumber the same season, specials
  appear inline or vanish, and a two-part finale merges into one entry — so
  `episode_source_id` is the identity and `season_number` / `episode_number` are
  a **label snapshot**, written at tick time and never read back as identity.
  Keying on `{season, episode}` is precisely the bug that caption warns about.

  A `nil` `episode_source_id` means the watch is of the whole title: a film, a
  finished book, a record played through.

  ## Why `rewatch_number` is stored rather than counted

  Screen 33 prints "2nd rewatch". Counting rows would say "1st" for anyone who
  watched the film twice before Kati existed or imported a partial history — and
  screen 15's import row ("412 titles from a CSV backup") says that user exists.
  It is the user's own count, so it is the user's own column.

  ## Dates

  `watched_on` is a date and `watched_at` is an instant, and they are separate
  for the reason `Kati.Calendars.Event` keeps `dtstart_date` apart from
  `dtstart_utc`: "watched on 12 August" is date-valued, and storing it as
  midnight moves it a day the moment the user flies. Screen 33 knows the hour
  ("Sun 16 Aug · 21:40") and screen 08 does not ("Watched 12 Aug"). Both are
  nullable: "I have seen this, I do not remember when" is a real answer and must
  not be recorded as never.

  `service` and `place` are stored apart even though screen 33 draws them as one
  line ("Lumen+ · living room"), because one of them is a thing stats can group
  by and the other is a room in a house.
  """
  use Ash.Resource, domain: Kati.Media, data_layer: AshSqlite.DataLayer

  sqlite do
    table "media_watches"
    repo Kati.Repo

    custom_indexes do
      # Screen 04: which episodes of this title are ticked.
      index [:tracked_title_id, :episode_source_id]
      # Screen 08's "seen 2 times", and this title's history newest first.
      index [:tracked_title_id, :watched_at]
      # Screen 15's activity log across every title.
      index [:watched_at]
    end
  end

  attributes do
    uuid_primary_key :id

    # ── Which episode, if any ──────────────────────────────────────────────
    # The provider's own episode id. nil means the whole title.
    attribute :episode_source_id, :string, public?: true

    # A label snapshot, so the activity log still reads "S2E5" after a cache
    # wipe. Never treated as identity — see the moduledoc.
    attribute :season_number, :integer, public?: true
    attribute :episode_number, :integer, public?: true

    # ── When ───────────────────────────────────────────────────────────────
    attribute :watched_on, :date, public?: true
    attribute :watched_at, :utc_datetime_usec, public?: true

    # ── What the user thought that time ────────────────────────────────────
    # Ten-point scale, as on TrackedTitle: screen 33's 4.5 stars is 9.
    attribute :rating, :integer, public?: true, constraints: [min: 1, max: 10]
    attribute :review, :string, public?: true

    # Screen 33's "Spoilers hidden" — a property of the review, so it travels
    # with the review rather than sitting in settings.
    attribute :contains_spoilers, :boolean, allow_nil?: false, default: false, public?: true

    # The user's own count, not `count(rows)`. See the moduledoc.
    attribute :rewatch_number, :integer, public?: true, constraints: [min: 1]

    # ── Where, and who with ────────────────────────────────────────────────
    attribute :service, :string, public?: true
    attribute :place, :string, public?: true

    # Names as typed, comma-separated. Kati has no people table and no contacts
    # permission, and inventing either to hold the word "Jo" would be a larger
    # privacy decision than the feature is asking for.
    attribute :companions, :string, public?: true

    # Screen 33's tags, comma-separated. Flat on purpose until something filters
    # by them: a join table nothing queries is a migration with no reader.
    attribute :tags, :string, public?: true

    # ── How it felt, which is the part a local recommender can use ─────────
    #
    # On the WATCH and not on the title, which is #16's own open question. A
    # rewatch in a different frame of mind is the example the issue gives, and
    # it settles it: the title-level answer is derivable from its watches
    # (`Kati.Media.Mood.for_title/1`) and the reverse is not. Recording per
    # title would make "I found it funny the first time and sad the second"
    # unsayable.
    #
    # An array rather than `tags`' comma-separated string, and the difference
    # is not taste. Nothing filters on `tags`; screen 07's distribution and
    # screen 11's mood filter both read this. On a delimited string those become
    # `LIKE '%tense%'`, which matches **intense** — a bug that shows up as a
    # wrong recommendation and never as an error.
    #
    # Fixed vocabulary, the fourteen the brief names verbatim. Extensible was
    # the alternative and needs a source Kati does not have: a free-text mood is
    # unaggregatable across titles, which is the one thing this attribute exists
    # to make possible.
    attribute :moods, {:array, :atom},
      public?: true,
      default: [],
      constraints: [items: [one_of: Kati.Media.Mood.vocabulary()]]

    # StoryGraph's other axis. Three values, not a number: "medium" is a
    # judgement and a 1-10 pace scale invites a precision nobody has.
    attribute :pace, :atom, public?: true, constraints: [one_of: [:slow, :medium, :fast]]

    # A segmented control, not the slider the brief asks for. The design has no
    # slider in its 38-row component table, and D-13 prefers the segmented
    # control for the same reason: no new component, no new gesture, no new
    # accessibility story.
    attribute :driven_by, :atom,
      public?: true,
      constraints: [one_of: [:character, :both, :plot]]

    timestamps()
  end

  relationships do
    # A foreign key here is safe where one to the cache would not be: both ends
    # are durable, so nothing evicts out from under it.
    belongs_to :tracked_title, Kati.Media.TrackedTitle,
      allow_nil?: false,
      attribute_writable?: true,
      attribute_public?: true
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]
    default_accept :*

    read :for_title do
      description "Everything logged against one title, newest first."
      argument :tracked_title_id, :uuid, allow_nil?: false
      filter expr(tracked_title_id == ^arg(:tracked_title_id))
      prepare build(sort: [watched_at: :desc])
    end

    # Screen 04 asks this once per render and ticks by membership: an episode is
    # watched when a row for it exists, so unticking destroys and rewatching
    # simply adds another.
    read :episode_ticks do
      description "Every episode-level watch for one title."
      argument :tracked_title_id, :uuid, allow_nil?: false

      filter expr(tracked_title_id == ^arg(:tracked_title_id) and not is_nil(episode_source_id))
    end

    read :for_episode do
      description "Every watch of one particular episode."
      argument :tracked_title_id, :uuid, allow_nil?: false
      argument :episode_source_id, :string, allow_nil?: false

      filter expr(
               tracked_title_id == ^arg(:tracked_title_id) and
                 episode_source_id == ^arg(:episode_source_id)
             )
    end
  end
end
