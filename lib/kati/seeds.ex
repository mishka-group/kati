defmodule Kati.Seeds do
  @moduledoc """
  First-launch data: the design's own values, written into a fresh database.

  Kati's screens were built against 79 `Sample` modules, and every number the
  drawings show lives in one of them. A first launch against an empty database
  would therefore render the same screens as blank frames — no calendars, no
  day, no library grid — which is a worse first impression than the design and,
  more practically, makes "does the app match the drawing?" unanswerable on a
  device that has never synced anything.

  So this module copies the sample values into real rows once, and never again.

  ## The two things that make it safe to call on every boot

    * **A group is skipped when its tables already hold data.** The guard is the
      whole group, not a row count: if any of a group's marker resources has a
      single row, the group is a no-op. That is what makes it safe to call after
      `Ecto.Migrator.run/4` on every start, and what stops it touching a
      database that already holds a user's own events.
    * **Every write is an upsert on a natural key**, so even a forced re-run
      converges instead of duplicating. The guard is the cheap check; the
      upserts are what make the guard's failure modes survivable.

  Those are two independent mechanisms on purpose. The guard alone would be
  enough for the happy path, but AshSqlite reports `can?(:transact) == false`,
  so an Ash action is not atomic and a crash part-way through a group is a real
  state. Each group's writes are therefore wrapped in one `Kati.Repo`
  transaction — which SQLite does support even though Ash declines to use it —
  and the upserts are the belt to that braces.

  ## Ordering

  Seeding must run **after** `Ecto.Migrator.run/4` (there are no tables before
  it) and **before** `Kati.Calendars.DeviceImport.run/0` (which mirrors the
  user's real calendars; letting it run first would fill the calendar tables and
  make this a permanent no-op on a device that has granted the permission).
  Nothing here is wired into `Kati.App.on_start/0` yet.

  ## Adding a group

  `groups/0` is the whole extension point. A new domain is one entry there plus
  one private `seed_*` function; nothing else in this module changes. The two
  groups that are expected next are named in the comment beside it.

  ## Telling seeded rows apart later

  Seeded rows are tagged so a later round can find and evict them when the real
  data arrives:

    * `Kati.Calendars.Account.account_type` is `"kati:sample"`.
    * `Kati.Calendars.Calendar.remote_id` and `Kati.Calendars.Event.uid` are
      prefixed `kati:sample:` / `kati-sample-`.
    * `Kati.Media.CachedTitle.source_id` is `sample:<seed>` — see
      `sample_source_id/1`, which is also the join key any tracking row should
      use to point at one of these titles.
  """

  require Ash.Query

  alias Kati.Calendar.SampleDay
  alias Kati.Calendars.Account
  # Deliberately NOT aliasing Kati.Calendars.Calendar: it would shadow Elixir's
  # Calendar, and Calendar.strftime/2 is used below.
  alias Kati.Calendars.Calendar, as: CalendarRow
  alias Kati.Calendars.Event
  alias Kati.Library.Sample, as: LibrarySample
  alias Kati.Media.CachedTitle
  alias Kati.Settings.CalendarsSample
  alias Kati.Subscriptions.Sample, as: SubscriptionsSample

  @typedoc """
  What one group did. `rows` counts what this run wrote, so it is `%{}` for a
  group that was skipped — a caller can tell "already seeded" from "seeded
  nothing" without a second query.
  """
  @type outcome :: %{
          status: :seeded | :skipped,
          rows: %{atom() => non_neg_integer()}
        }

  @typedoc "A seedable domain: a name, the tables that gate it, and the writer."
  @type group :: %{
          name: atom(),
          markers: [module()],
          seed: (-> %{atom() => non_neg_integer()})
        }

  # Marks a row as sample data rather than something a user or a sync produced.
  @sample_tag "kati:sample"

  # The two subscriptions behind screen 09's merged `2 renewals · £22.98` row.
  # Named rather than inferred: SampleDay states only the merged total, and
  # picking services by "which two prices add up" would silently choose a
  # different pair the moment a price changes. `Kati.SeedsTest` asserts these
  # two still sum to the total the design prints.
  @renewals ["Lumen+", "Orbit"]

  @doc """
  Seed every group that has not been seeded, and report what happened.

  Idempotent: calling it twice writes rows once. Options:

    * `:force` — run a group even when its tables already hold data. The
      upserts make this converge rather than duplicate, so it is the repair for
      a group left half-written by a crash, and the reseed for development.
    * `:only` — a list of group names to consider; the rest are absent from the
      report entirely rather than reported as skipped.
  """
  @spec run(keyword()) :: %{atom() => outcome()}
  def run(opts \\ []) do
    force? = Keyword.get(opts, :force, false)
    only = Keyword.get(opts, :only)

    groups()
    |> Enum.filter(&(is_nil(only) or &1.name in only))
    |> Map.new(&{&1.name, run_group(&1, force?)})
  end

  @doc """
  Every seedable group, in the order `run/1` runs them.

  **This list is the extension point.** A resource that lands in a later round
  is one entry here and one private `seed_*/0` function beside the existing
  ones:

      %{name: :media_tracking,
        markers: [Kati.Media.TrackedTitle, Kati.Media.Watch],
        seed: &seed_media_tracking/0},
      %{name: :meals,
        markers: [Kati.Meals.MealPlan, Kati.Meals.MealPlanSlot, Kati.Meals.Recipe],
        seed: &seed_meals/0},

  `markers` is every table the group writes to. All of them must be empty for
  the group to run, so a group can never half-overwrite data that arrived from
  somewhere else. Order matters: `:media_tracking` must come after `:media`,
  because a tracking row points at a cached title by `{source, source_id}` and
  `sample_source_id/1` is what computes that key.
  """
  @spec groups() :: [group()]
  def groups do
    [
      %{
        name: :calendars,
        markers: [Account, CalendarRow, Event],
        seed: &seed_calendars/0
      },
      %{
        name: :media,
        markers: [CachedTitle],
        seed: &seed_media/0
      }
    ]
  end

  @doc """
  True when every one of a group's tables is empty.

  The question `run/1` asks before writing anything, exposed because a boot
  trace wants to log the answer without doing the work.
  """
  @spec empty?(atom()) :: boolean()
  def empty?(name) do
    case Enum.find(groups(), &(&1.name == name)) do
      nil -> raise ArgumentError, "no such seed group: #{inspect(name)}"
      group -> group_empty?(group)
    end
  end

  @doc """
  The `{source, source_id}` half of a sample title's identity.

  A tracking row references a title by `{source, source_id}` and survives a
  cache wipe — that is the whole point of the durable/cached split in
  `Kati.Media.CachePolicy`. So the seeded tracking rows a later round adds must
  compute their key with this function rather than reproducing the string, or
  the join breaks the first time the prefix changes.
  """
  @spec sample_source_id(String.t()) :: String.t()
  def sample_source_id(seed) when is_binary(seed), do: "sample:" <> seed

  @doc "The design seed behind a `sample_source_id/1`, or `nil` for a real one."
  @spec sample_seed(String.t()) :: String.t() | nil
  def sample_seed("sample:" <> seed), do: seed
  def sample_seed(_), do: nil

  @doc "The source every seeded cached title claims."
  @spec sample_source() :: atom()
  def sample_source, do: :tmdb

  # ── The runner ─────────────────────────────────────────────────────────────

  defp run_group(group, force?) do
    if force? or group_empty?(group) do
      {:ok, rows} = Kati.Repo.transaction(group.seed)
      %{status: :seeded, rows: rows}
    else
      %{status: :skipped, rows: %{}}
    end
  end

  defp group_empty?(group), do: Enum.all?(group.markers, &(Ash.count!(&1) == 0))

  # ── Calendars ──────────────────────────────────────────────────────────────

  # Screen 32's three accounts. The display fields are the drawing's own; the
  # provider atom is not, because the drawing has no way to say "this iCloud row
  # is CalDAV underneath". `Kati.SeedsTest` pins the display fields to
  # `Kati.Settings.CalendarsSample.accounts/0` so the two cannot drift.
  @accounts [
    %{
      key: "icloud",
      provider: :caldav,
      display_name: "iCloud",
      account_name: "jo@icloud.com",
      state: :live
    },
    %{
      key: "google",
      provider: :google,
      display_name: "Google",
      account_name: "work@studio.co",
      state: :live
    },
    %{
      key: "caldav",
      provider: :caldav,
      display_name: "CalDAV",
      account_name: "fastmail",
      state: :stale
    }
  ]

  # Which account owns which calendar, and which palette slot the calendar
  # lends its events. The split satisfies both counts the drawing states in its
  # own subtitles — iCloud "2 calendars", Google "1 calendar".
  @calendar_owners %{
    "Personal" => {"icloud", :ink},
    "Family" => {"icloud", :bronze},
    "Work" => {"google", :green},
    "Birthdays" => {"caldav", :rail_idle}
  }

  # Screen 09 draws Design review and Standup as work; `Kati.Calendar.SampleEvent`
  # confirms it, with Work the ticked section on the event it opens. Everything
  # else on the day is personal.
  @work_events ["Standup", "Design review"]

  # `Kati.Calendars.Event.kind` has no :todo — a todo is a reminder with a tick.
  defp event_kind(:todo), do: :reminder
  defp event_kind(kind), do: kind

  defp seed_calendars do
    accounts = Map.new(@accounts, &{&1.key, upsert_account(&1)})
    calendars = Map.new(seed_calendar_rows(accounts), &{&1.display_name, &1})

    zone = Kati.Time.device_zone()
    today = Kati.Time.today()

    events =
      seed_timed_events(calendars, today, zone) +
        seed_all_day_events(calendars, today) +
        seed_renewal_events(calendars, today, zone)

    %{accounts: map_size(accounts), calendars: map_size(calendars), events: events}
  end

  defp seed_calendar_rows(accounts) do
    for %{title: title, color: colour, on: on?} <- CalendarsSample.calendars() do
      {owner, token} = Map.fetch!(@calendar_owners, title)

      upsert_calendar(%{
        account_id: Map.fetch!(accounts, owner).id,
        remote_id: "#{@sample_tag}:#{slug(title)}",
        display_name: title,
        # The provider's own value, verbatim and never rendered — which for a
        # sample means the drawing's ARGB with its alpha dropped, in the
        # `#RRGGBB` shape a CalDAV `apple:calendar-color` arrives in.
        colour_source: hex(colour),
        colour_token: token,
        kind: :provider,
        read_only: false,
        visible: on?,
        # Screen 32's privacy promise, and its default.
        writeback_policy: :kati_only
      })
    end
  end

  # Each of these counts the rows it wrote, by writing them. An upsert that
  # cannot write raises, so the length is the number that landed rather than the
  # length of the list it was handed.
  defp seed_timed_events(calendars, today, zone) do
    SampleDay.occurrences()
    |> Enum.map(fn occ ->
      attrs =
        %{
          uid: "kati-sample-day-#{occ.id}@kati",
          origin: :kati,
          summary: occ.title,
          kind: event_kind(occ.kind),
          status: :confirmed,
          tz_behaviour: :fixed,
          sync_state: :local_only
        }
        |> Map.merge(timing(today, occ.start_min, occ.end_min, zone))

      upsert_event(calendar_for(calendars, occ.title), attrs)
    end)
    |> length()
  end

  defp seed_all_day_events(calendars, today) do
    SampleDay.all_day()
    |> Enum.map(fn item ->
      attrs = %{
        uid: "kati-sample-allday-#{item.seed}@kati",
        origin: :kati,
        summary: item.title,
        description: item.meta,
        kind: :air_date,
        status: :confirmed,
        # An all-day event is date-valued, never a midnight instant.
        is_all_day: true,
        dtstart_date: today,
        duration_iso: "P1D",
        sync_state: :local_only
      }

      upsert_event(calendar_for(calendars, item.title), attrs)
    end)
    |> length()
  end

  # Screen 09 merges these two into one `2 renewals` row, but a merged row is a
  # rendering decision — the database holds the two events it merges, which is
  # also what makes the day's stated `14 items` add up.
  defp seed_renewal_events(calendars, today, zone) do
    services = Map.new(SubscriptionsSample.services(), &{&1.name, &1})
    at = 18 * 60

    @renewals
    |> Enum.map(fn name ->
      service = Map.fetch!(services, name)

      attrs =
        %{
          uid: "kati-sample-renewal-#{slug(name)}@kati",
          origin: :kati,
          summary: name,
          description: service.price,
          kind: :money,
          status: :confirmed,
          tz_behaviour: :fixed,
          sync_state: :local_only
        }
        |> Map.merge(timing(today, at, at + 15, zone))

      upsert_event(calendar_for(calendars, name), attrs)
    end)
    |> length()
  end

  defp calendar_for(calendars, title) when title in @work_events,
    do: Map.fetch!(calendars, "Work").id

  defp calendar_for(calendars, _title), do: Map.fetch!(calendars, "Personal").id

  # `dtstart_wall` is the authored wall clock and `dtstart_utc` is only the
  # range-query key — see `Kati.Calendars.Event`. Both are written, because
  # storing one is what makes a 09:00 event drift across a DST boundary.
  defp timing(date, start_min, end_min, zone) do
    naive =
      date
      |> NaiveDateTime.new!(~T[00:00:00])
      |> NaiveDateTime.add(start_min * 60, :second)

    {:ok, utc} = Kati.Time.to_utc(naive, zone)

    %{
      dtstart_utc: utc,
      dtstart_wall: Calendar.strftime(naive, "%Y%m%dT%H%M%S"),
      tzid: zone,
      duration_iso: "PT#{end_min - start_min}M"
    }
  end

  # ── Media ──────────────────────────────────────────────────────────────────

  defp seed_media do
    now = DateTime.utc_now()

    count =
      LibrarySample.titles()
      |> Enum.map(fn title ->
        upsert_title(%{
          source: sample_source(),
          source_id: sample_source_id(title.seed),
          kind: title_kind(title.kind),
          title: title.title,
          # Not a TMDB path: the sample artwork is resolved by seed through
          # `Kati.Design.Images.poster/1`, and the seed is what a renderer needs.
          poster_path: title.seed,
          # Not null on purpose — a row with no age cannot be evicted.
          fetched_at: now
        })
      end)
      |> length()

    %{cached_titles: count}
  end

  defp title_kind(:series), do: :tv
  defp title_kind(:film), do: :movie

  # ── Upserts ────────────────────────────────────────────────────────────────
  #
  # Read-then-write rather than an `upsert?: true` create, because only two of
  # these four natural keys have a unique index behind them and a single shape
  # is easier to reason about than two.

  defp upsert_account(spec) do
    attrs = %{
      provider: spec.provider,
      display_name: spec.display_name,
      account_name: spec.account_name,
      account_type: @sample_tag,
      state: spec.state,
      last_sync_at: last_sync_for(spec.state)
    }

    name = spec.account_name

    case Account |> Ash.Query.filter(account_name == ^name) |> Ash.read_one!() do
      nil -> Account |> Ash.Changeset.for_create(:create, attrs) |> Ash.create!()
      row -> row |> Ash.Changeset.for_update(:update, attrs) |> Ash.update!()
    end
  end

  # The drawing's own copy: the stale account says "last sync 4h ago", and the
  # live ones are current.
  defp last_sync_for(:stale), do: DateTime.add(DateTime.utc_now(), -4, :hour)
  defp last_sync_for(_state), do: DateTime.utc_now()

  defp upsert_calendar(attrs) do
    %{account_id: account_id, remote_id: remote_id} = attrs

    existing =
      CalendarRow
      |> Ash.Query.filter(account_id == ^account_id and remote_id == ^remote_id)
      |> Ash.read_one!()

    case existing do
      nil -> CalendarRow |> Ash.Changeset.for_create(:create, attrs) |> Ash.create!()
      row -> row |> Ash.Changeset.for_update(:update, attrs) |> Ash.update!()
    end
  end

  defp upsert_event(calendar_id, attrs) do
    attrs = Map.put(attrs, :calendar_id, calendar_id)
    uid = attrs.uid

    existing =
      Event
      |> Ash.Query.filter(uid == ^uid and calendar_id == ^calendar_id)
      |> Ash.read_one!()

    case existing do
      nil -> Event |> Ash.Changeset.for_create(:create, attrs) |> Ash.create!()
      row -> row |> Ash.Changeset.for_update(:update, attrs) |> Ash.update!()
    end
  end

  defp upsert_title(attrs) do
    %{source: source, source_id: source_id} = attrs

    existing =
      CachedTitle
      |> Ash.Query.filter(source == ^source and source_id == ^source_id)
      |> Ash.read_one!()

    case existing do
      nil -> CachedTitle |> Ash.Changeset.for_create(:create, attrs) |> Ash.create!()
      row -> row |> Ash.Changeset.for_update(:update, attrs) |> Ash.update!()
    end
  end

  # ── Small helpers ──────────────────────────────────────────────────────────

  defp slug(name) do
    name
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.trim("-")
  end

  # ARGB integer to the `#RRGGBB` a provider would have sent.
  defp hex(argb) do
    "#" <>
      (argb
       |> rem(0x1000000)
       |> Integer.to_string(16)
       |> String.pad_leading(6, "0"))
  end
end
