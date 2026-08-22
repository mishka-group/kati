defmodule Kati.Screens.Sync do
  @moduledoc """
  Sync — pushed under Settings. The screen that makes `Kati.Sync` visible.

  ## There is no drawing for this screen, and this is what it follows instead

  Every other file in `lib/kati/screens/` is built to a numbered frame under
  `.scratch/design/screens/`. This one is not. Issue #25 asks for a drawing of
  the sync surface and it does not exist, and the two frames the sync
  moduledocs point at are not pictures of this page:
  `.scratch/design/screens/37.html` is the CSV **import** wizard — its
  *Keep mine / Take file / Keep both* strip is what `Kati.Sync.resolve/3`'s doc
  borrows a vocabulary from — and `27.html` is the states reference sheet whose
  error card carries the **Retry** `Kati.Sync.Outbox.retry/1` names.

  So the look is borrowed rather than invented, and screen 24
  (`Kati.Screens.Settings`) is what it is borrowed from: the same 21pt gutter,
  the same `Kati.UI.SettingsList.title/3` over a mono subtitle, the same
  `Kati.UI.eyebrow/2` groups over `Kati.UI.SettingsList.card/1`, the same
  30x30 icon tiles, hairlines, pills and dashed-frame notes. Nothing here draws
  a container `Kati.UI.SettingsList` does not already own, and no colour is a
  literal — every one resolves through `Kati.Theme.Palette`, which is what lets
  a screen with no dark drawing still be a dark screen.

  Because there is no frame to be faithful to, two small freedoms are taken
  that a drawn screen could not take, and both are noted where they happen:
  the account glyph is **derived** from `Kati.Calendars.Account.provider`
  (`Kati.Screens.Calendars` refuses to, because 32's drawing distinguishes
  iCloud from CalDAV and the column cannot — here there is no drawing to
  contradict), and the tally strip uses `Kati.UI.number_with_unit/3` rather
  than reproducing 24's account card, which is about an account this app does
  not model.

  ## What it is for

  `Kati.Sync` and `Kati.Sync.Outbox` were finished and proven on device with
  nothing calling them. The engine's central promise is that **nothing is
  discarded** — a losing edit is preserved in `Kati.Sync.RejectedChange` with
  the base it was a change from — and a promise no screen can show is very
  nearly a promise not kept. Four questions, four groups:

    * **Accounts and Calendars** — `Kati.Sync.status/1` per calendar: what is
      waiting, what is stuck, when each last succeeded.
    * **Waiting to send** — the outbox, with `Kati.Sync.Outbox.retry/1` on the
      entries that can be retried and a reason on the ones that cannot.
    * **Needs you** — `Kati.Sync.conflicts/1`, each as a **question** with the
      three answers `Kati.Sync.resolve/3` takes.
    * **Kept, not sent** — the preserved losing edits, and the statement that
      re-applying one is another three-way merge rather than a clobber.

  ## Ownership is not symmetric, and the copy says so

  Kati's canonical store is the device; a remote calendar is an upstream Kati
  does not control and cannot lock. `Kati.Sync`'s moduledoc states that, and a
  screen that laid the two sides out as equal halves would quietly deny it. So
  the page says it in its own words in the frame under the tally strip, the
  three answers are named *Keep mine / Take the calendar's / Keep both* rather
  than mine-versus-theirs, and every conflict question names the calendar by
  its own `display_name` rather than calling it "remote".

  ## Which entries can be retried, and which cannot

  `Kati.Sync.Outbox.fail/3` parks `:reauth` and `:conflict` in `:blocked`
  *"because trying again cannot fix either of them"*, and quarantines
  everything else in `:push_failed`. So **Retry** is drawn on `:push_failed`
  and on nothing else. A blocked entry gets a sentence saying which of the two
  it is instead: if a conflicted event exists for its UID, the answer is the
  question below it; otherwise the credential or the merge has to come first.
  Drawing Retry on a blocked entry would be a button that reliably does
  nothing, which is the defect `Kati.ScreenTapSweepTest` exists to end.

  ## Why the three conflict questions can be told apart at all

  `Kati.Sync.conflicts/1` answers with events, not verdicts, so the reason has
  to be recovered. It is, from data the engine already wrote rather than from a
  guess: `Kati.Sync.Engine.park_conflict/4` stores the merge's own reason in
  the blocked outbox entry's `last_error` (`"delete_edit"`, `"no_base"`,
  `"unparseable"`), and the entry's payload still holds the merge base and the
  properties the local edit changed. `question/3` reads those:

    * **A missing base** — no open entry, or an entry whose `base_icalendar` is
      `nil`. `Kati.Sync.Merge`'s first clause: *"Without a base there is no
      merge. Two documents that differ tell you nothing about who moved."*
    * **Delete versus edit** — the entry's op is `:delete`, or the row carries
      a `deleted_at`, or the parked reason says so. This is the case where
      *Keep both* is a real outcome that neither side's rule expresses.
    * **Entangled timing** — the local edit touched `DTSTART`/`RRULE`/… and so
      did the calendar. Both halves are named: the local ones off the entry's
      `changed_properties`, the remote ones by diffing the entry's base against
      the row's `raw_icalendar`, which `park_conflict/4` set to the remote's
      bytes. That is what lets the question say *you moved DTSTART, the
      calendar changed RRULE* — one description, two property names — instead
      of "there is a conflict".

  `@entangled` below is a second copy of `Kati.Sync.Merge`'s private list, and
  a second copy of a constant goes stale. `Kati.ScreenSyncTest` pins it by
  exercising `Kati.Sync.Merge.merge/4` with every name in it, so the list here
  cannot drift from the behaviour it is describing.

  ## Re-applying, and the order the two calls are made in

  `Kati.Sync.reapply/1` marks the row applied and hands back the property
  lines; `Kati.Sync.edit/3` is what actually writes and queues, *"because a
  shortcut here would be a second write path"*. Marking first and editing
  second would lose the kept values if the edit were then refused — so
  `Kati.Sync.Ownership.authorise/2` is asked **first**, with the same event and
  calendar `Kati.Sync.edit/3` will ask it with, and the pill is not drawn at
  all where `Kati.Sync.Ownership.writable?/2` is false. That is the two-gates
  rule applied to a screen: do not offer a write policy forbids, and still
  handle the refusal if one arrives.

  ## What this screen deliberately does not do

    * **No Send now.** Draining is `Kati.Sync.Engine.drain/3` and it takes an
      adapter. `Kati.SyncBoundaryTest` asserts that `lib/kati/sync/engine.ex`
      is the only file in the app that speaks to a transport, and a screen
      choosing one would be the second. Sending is the background syncer's job.
    * **No Dismiss on a kept edit.** `Kati.Sync.RejectedChange.dismissed_at`
      has no writer anywhere in `lib/`, and inventing one on this side would be
      a discard button for the one table whose entire purpose is that nothing
      is discarded. It wants a `Kati.Sync.dismiss/1` first.
    * **No editing.** Opening the event belongs to screen 31; this page is
      about the queue.
  """
  use Kati.Screens.Pushed, back: "Settings"

  require Ash.Query

  alias Kati.Calendars.Account
  # Deliberately aliased away from `Calendar`, which is Elixir's own module —
  # the same trap `Kati.Screens.Calendars` and `Kati.Seeds` step around.
  alias Kati.Calendars.Calendar, as: CalendarRow
  alias Kati.Calendars.Event
  alias Kati.Sync.ICalendar
  alias Kati.Sync.Operation
  alias Kati.Sync.OutboxEntry
  alias Kati.Sync.Ownership
  alias Kati.Sync.RejectedChange
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  # A second copy of `Kati.Sync.Merge`'s private `@entangled`. Pinned against
  # the real thing by `Kati.ScreenSyncTest` — see the moduledoc.
  @entangled ~w(DTSTART DTEND DURATION RRULE RDATE EXDATE RECURRENCE-ID)

  @doc """
  The property names that are one description of when an event happens.

  Exposed so `Kati.ScreenSyncTest` can put every one of them through
  `Kati.Sync.Merge.merge/4` and prove this copy has not drifted from the
  behaviour it describes. A constant duplicated across two modules is a
  constant that goes stale; a constant duplicated and pinned is a constant.
  """
  @spec entangled() :: [String.t()]
  def entangled, do: @entangled

  # How much of each list is drawn. The caps are not about the tap-handle
  # budget — this screen is nowhere near 256 — but about a queue of two hundred
  # entries being a wall rather than an answer. The count above each group is
  # the whole number either way, so a truncated list still says how many there
  # are.
  @outbox_limit 12
  @conflict_limit 6
  @rejected_limit 8

  @impl true
  def load(socket) do
    socket
    |> Mob.Socket.assign(:sync, Kati.Screens.Sync.state())
    |> Mob.Socket.assign(:message, nil)
  end

  # ── Reading ────────────────────────────────────────────────────────────────

  @doc """
  Everything the page draws, read once per render pass.

  One function rather than four assigns, because every group answers about the
  same set of calendars and a page that had read them at four different moments
  could show a count that disagrees with the list under it.
  """
  @spec state() :: map()
  def state do
    calendars = Kati.Screens.Sync.stored_calendars()
    accounts = Kati.Screens.Sync.stored_accounts()
    by_account = Map.new(accounts, &{&1.id, &1})

    models = Enum.map(calendars, &Kati.Screens.Sync.calendar_model(&1, by_account))
    conflicts = Kati.Screens.Sync.conflict_models(calendars)
    entries = Kati.Screens.Sync.stored_entries(calendars, models, conflicts)
    rejected = Kati.Screens.Sync.rejected_models(calendars)

    %{
      accounts: Enum.map(accounts, &Kati.Screens.Sync.account_model(&1, calendars)),
      calendars: models,
      outbox: entries,
      conflicts: conflicts,
      rejected: rejected,
      waiting: Enum.count(entries, &(&1.state in [:pending, :in_flight])),
      stuck: Enum.count(entries, &(&1.state in [:blocked, :push_failed])),
      last_sync_at: Kati.Screens.Sync.newest(Enum.map(models, & &1.last_sync_at))
    }
  end

  @doc """
  Every calendar, oldest first.

  Ordered by `inserted_at` for `Kati.Screens.Calendars.stored_calendars/0`'s
  reason: there is no position column and the order a calendar arrived in is
  the only order the schema actually holds. The `rescue` is the degradation
  every reading screen in this app makes — a store it cannot reach draws an
  empty page, never a crash on a screen the user is looking at.
  """
  @spec stored_calendars() :: [CalendarRow.t()]
  def stored_calendars do
    CalendarRow |> Ash.Query.sort(inserted_at: :asc, id: :asc) |> Ash.read!()
  rescue
    _ -> []
  end

  @doc "Every account, oldest first. See `stored_calendars/0` for the `rescue`."
  @spec stored_accounts() :: [Account.t()]
  def stored_accounts do
    Account |> Ash.Query.sort(inserted_at: :asc, id: :asc) |> Ash.read!()
  rescue
    _ -> []
  end

  @doc """
  One account row: what it is, how many calendars it brought, and its state.

  The `Kati.Calendars.Account.state` enum is drawn as it is stored. Screen 32
  draws Live and Stale from this same column and stops there; `:error` and
  `:disconnected` are the two it never had a drawing for, and they are exactly
  the two a sync page has to be able to say out loud.
  """
  @spec account_model(Account.t(), [CalendarRow.t()]) :: map()
  def account_model(account, calendars) do
    mine = Enum.count(calendars, &(&1.account_id == account.id))

    %{
      title: Kati.Screens.Sync.account_label(account),
      icon: Kati.Screens.Sync.provider_icon(account.provider),
      calendars: mine,
      state: account.state,
      last_sync_at: account.last_sync_at
    }
  end

  @doc "An account's name, or the provider it is, or the honest last resort."
  @spec account_label(Account.t()) :: String.t()
  def account_label(%Account{display_name: name}) when is_binary(name) and name != "", do: name
  def account_label(%Account{account_name: name}) when is_binary(name) and name != "", do: name
  def account_label(%Account{provider: provider}), do: Kati.Screens.Sync.provider_label(provider)

  @doc "The word for a provider, in the user's language rather than the column's."
  @spec provider_label(atom()) :: String.t()
  def provider_label(:local), do: "This device"
  def provider_label(:android_provider), do: "The phone's calendars"
  def provider_label(:caldav), do: "A CalDAV calendar"
  def provider_label(:google), do: "Google Calendar"
  def provider_label(:graph), do: "Outlook"
  def provider_label(_other), do: "A calendar account"

  @doc """
  The 30pt tile's glyph, derived from `Kati.Calendars.Account.provider`.

  `Kati.Screens.Calendars` deliberately does **not** derive this and says why:
  screen 32's drawing distinguishes iCloud (`cloud`) from Fastmail-over-CalDAV
  (`dns`) and the column collapses both into `:caldav`, so deriving there would
  draw the wrong glyph against a frame that can be compared. There is no frame
  here, so there is nothing to be wrong against — and a generic tile on every
  row would carry less than the column already knows.
  """
  @spec provider_icon(atom()) :: String.t()
  def provider_icon(:local), do: "phone_iphone"
  def provider_icon(:android_provider), do: "phone_iphone"
  def provider_icon(:caldav), do: "dns"
  def provider_icon(:google), do: "mail"
  def provider_icon(:graph), do: "cloud"
  def provider_icon(_other), do: "cloud"

  @doc """
  One calendar's row: its queue counts from `Kati.Sync.status/1`, plus the two
  columns that decide whether it can be written to at all.

  `partially_synced` is carried rather than summed away. It is the "half
  landed" case — a *this and following* split whose trim succeeded and whose
  successor did not — and `Kati.Sync.Outbox.partially_synced/1`'s own doc says
  losing it is how that becomes a silent loss of every future occurrence.
  """
  @spec calendar_model(CalendarRow.t(), %{optional(String.t()) => Account.t()}) :: map()
  def calendar_model(calendar, by_account) do
    status = Kati.Screens.Sync.status(calendar.id)
    account = Map.get(by_account, calendar.account_id)

    %{
      id: calendar.id,
      title: calendar.display_name || "Untitled calendar",
      account: if(account, do: Kati.Screens.Sync.account_label(account), else: "This device"),
      kind: calendar.kind,
      read_only: calendar.read_only,
      writeback_policy: calendar.writeback_policy,
      pending: status.pending,
      blocked: status.blocked,
      failed: status.failed,
      partially_synced: status.partially_synced,
      last_sync_at: calendar.last_sync_at
    }
  end

  @doc "`Kati.Sync.status/1`, with the empty answer when the store is unreachable."
  @spec status(String.t()) :: map()
  def status(calendar_id) do
    Kati.Sync.status(calendar_id)
  rescue
    _ -> %{pending: 0, blocked: 0, failed: 0, partially_synced: []}
  end

  @doc """
  Every outbox entry that has not landed, oldest first, across every calendar.

  `:done` entries are read too and then dropped, because they are the only
  thing that can answer a `depends_on`: an entry whose dependency is not
  `:done` is not due *at any time*, and a row that says "queued" when it is
  actually waiting on a predecessor is a row that will look stuck for no
  visible reason.
  """
  @spec stored_entries([CalendarRow.t()], [map()], [map()]) :: [map()]
  def stored_entries(calendars, models, conflicts) do
    titles = Map.new(calendars, &{&1.id, &1.display_name || "Untitled calendar"})
    all = Kati.Screens.Sync.all_entries()
    done = MapSet.new(Enum.filter(all, &(&1.state == :done)), & &1.id)
    open = Enum.reject(all, &(&1.state == :done))
    summaries = Kati.Screens.Sync.summaries(Enum.map(open, & &1.event_uid))
    conflicted = MapSet.new(conflicts, & &1.event.uid)
    half = Kati.Screens.Sync.half_landed(models)

    Enum.map(open, fn entry ->
      %{
        id: entry.id,
        op: entry.op,
        state: entry.state,
        attempts: entry.attempt_count,
        last_error: entry.last_error,
        calendar: Map.get(titles, entry.calendar_id, "A calendar Kati no longer has"),
        title: Map.get(summaries, entry.event_uid) || entry.event_uid,
        waiting_on: entry.depends_on != nil and not MapSet.member?(done, entry.depends_on),
        conflicted: MapSet.member?(conflicted, entry.event_uid),
        half_landed: MapSet.member?(half, entry.event_uid),
        entry: entry
      }
    end)
  end

  @doc "Every outbox entry there is, in insertion order. See `stored_calendars/0`."
  @spec all_entries() :: [OutboxEntry.t()]
  def all_entries do
    OutboxEntry |> Ash.Query.sort(inserted_at: :asc, id: :asc) |> Ash.read!()
  rescue
    _ -> []
  end

  @doc """
  UID to event summary, for the UIDs given.

  One query rather than one per row. A UID with no event is simply absent, and
  the caller falls back to the UID itself — an outbox entry outliving its row
  is the documented case, not a bug: `Kati.Sync.OutboxEntry`'s foreign keys are
  plain columns precisely so the queue survives a `410 Gone`.
  """
  @spec summaries([String.t()]) :: %{optional(String.t()) => String.t()}
  def summaries([]), do: %{}

  def summaries(uids) do
    unique = Enum.uniq(uids)

    Event
    |> Ash.Query.filter(uid in ^unique)
    |> Ash.read!()
    |> Enum.reduce(%{}, fn event, acc ->
      case event.summary do
        summary when is_binary(summary) and summary != "" -> Map.put(acc, event.uid, summary)
        _ -> acc
      end
    end)
  rescue
    _ -> %{}
  end

  @doc """
  The UIDs whose chain is half-landed, as a set.

  Taken off the calendar models rather than asked again:
  `Kati.Sync.status/1` already answered `partially_synced` once per calendar,
  and a second pass over the same table could only produce a page whose badge
  and whose row disagreed.
  """
  @spec half_landed([map()]) :: MapSet.t(String.t())
  def half_landed(models) do
    Enum.reduce(models, MapSet.new(), fn model, acc ->
      MapSet.union(acc, MapSet.new(model.partially_synced))
    end)
  end

  @doc "`Kati.Sync.conflicts/1`, with the empty answer when the store is unreachable."
  @spec conflicts_for(String.t()) :: [Event.t()]
  def conflicts_for(calendar_id) do
    Kati.Sync.conflicts(calendar_id)
  rescue
    _ -> []
  end

  @doc "`Kati.Sync.rejected/1`, with the empty answer when the store is unreachable."
  @spec rejected_for(String.t()) :: [RejectedChange.t()]
  def rejected_for(calendar_id) do
    Kati.Sync.rejected(calendar_id)
  rescue
    _ -> []
  end

  # ── Conflicts ──────────────────────────────────────────────────────────────

  @doc "Every conflicted row on the device, each already turned into a question."
  @spec conflict_models([CalendarRow.t()]) :: [map()]
  def conflict_models(calendars) do
    Enum.flat_map(calendars, fn calendar ->
      calendar.id
      |> Kati.Screens.Sync.conflicts_for()
      |> Enum.map(&Kati.Screens.Sync.conflict_model(&1, calendar))
    end)
  end

  @doc false
  @spec conflict_model(Event.t(), CalendarRow.t()) :: map()
  def conflict_model(event, calendar) do
    entry = Kati.Screens.Sync.open_entry(calendar.id, event.uid)
    operation = Kati.Screens.Sync.operation(entry)
    question = Kati.Screens.Sync.question(event, calendar, operation)

    Map.merge(question, %{
      title: event.summary || event.uid,
      calendar: calendar.display_name || "Untitled calendar",
      event: event,
      calendar_row: calendar
    })
  end

  @doc false
  def open_entry(calendar_id, uid) do
    List.first(Kati.Sync.Outbox.open_entries(calendar_id, uid))
  rescue
    _ -> nil
  end

  @doc false
  def operation(nil), do: nil

  def operation(entry) do
    case Operation.from_entry(entry) do
      {:ok, operation} -> operation
      _ -> nil
    end
  end

  @doc """
  Which of the engine's unmergeable cases this row is in, as a question.

  Ordered the way `Kati.Sync.Merge` orders them: a missing base first, because
  without one there is no merge to reason about at all; then delete-versus-edit,
  which no property rule can express; then entangled timing, which is a merge
  that would succeed and produce a document nobody wrote. Everything else is
  the honest generic case rather than a guess dressed as one of the three.
  """
  @spec question(Event.t(), CalendarRow.t(), Operation.t() | nil) :: map()
  def question(event, calendar, operation) do
    name = calendar.display_name || "the calendar"

    cond do
      operation == nil or operation.base_icalendar == nil ->
        Kati.Screens.Sync.no_base_question(name)

      operation.op == :delete or event.deleted_at != nil ->
        Kati.Screens.Sync.delete_question(name, :local)

      Kati.Screens.Sync.remote_deleted?(event) ->
        Kati.Screens.Sync.delete_question(name, :remote)

      true ->
        Kati.Screens.Sync.property_question(event, operation, name)
    end
  end

  @doc false
  def no_base_question(name) do
    %{
      kind: :no_base,
      icon: "help",
      headline: "There is no record of what this looked like before the edit.",
      detail:
        "Kati keeps the version an edit started from, so that a disagreement can be a " <>
          "three-way merge rather than a guess. This one has none — the queued change was " <>
          "quarantined, or the edit is older than the queue. Your version and the one on " <>
          name <>
          " differ, and two versions that differ say nothing about who moved, so " <>
          "Kati will not choose between them for you."
    }
  end

  @doc false
  def delete_question(name, :local) do
    %{
      kind: :delete_edit,
      icon: "event_busy",
      headline: "You deleted this. " <> name <> " changed it.",
      detail:
        "There is no property merge for a delete. Sending it destroys an edit that a " <>
          "tombstone cannot carry; ignoring it brings back something you removed on purpose. " <>
          "Keep both is the answer neither side's rule can express: " <>
          name <> " keeps its version, and yours comes back as a separate Kati event."
    }
  end

  def delete_question(name, :remote) do
    %{
      kind: :delete_edit,
      icon: "event_busy",
      headline: name <> " deleted this. You changed it.",
      detail:
        "There is no property merge for a delete. Taking the deletion throws away the edit " <>
          "you made; refusing it puts back something that was removed elsewhere. Keep both " <>
          "leaves " <> name <> " as it is and keeps your version here as a Kati event."
    }
  end

  @doc """
  The two property-level cases, told apart by which names moved on each side.

  The local names come off the queued operation's `changed_properties`; the
  remote names come from diffing that operation's base against the row's
  `raw_icalendar`, which `Kati.Sync.Engine.park_conflict/4` set to the bytes
  the calendar sent. When both sides moved something inside the entangled
  timing set, that is the case `Kati.Sync.Merge` refuses to merge across
  differing names — and the question can name both halves.
  """
  @spec property_question(Event.t(), Operation.t(), String.t()) :: map()
  def property_question(event, operation, name) do
    local = Kati.Screens.Sync.changed_names(operation)
    remote = Kati.Screens.Sync.remote_names(operation.base_icalendar, event.raw_icalendar)
    local_timing = Enum.filter(local, &(&1 in @entangled))
    remote_timing = Enum.filter(remote, &(&1 in @entangled))

    if local_timing != [] and remote_timing != [] do
      Kati.Screens.Sync.timing_question(name, local_timing, remote_timing)
    else
      Kati.Screens.Sync.overlap_question(name, local, remote)
    end
  end

  @doc false
  def timing_question(name, local, remote) do
    mine = Kati.Screens.Sync.list_names(local)
    theirs = Kati.Screens.Sync.list_names(remote)

    %{
      kind: :entangled_timing,
      icon: "event_repeat",
      headline: "You changed " <> mine <> ". " <> name <> " changed " <> theirs <> ".",
      detail:
        "Those are different property names and one description. DTSTART, DTEND, DURATION, " <>
          "RRULE, RDATE, EXDATE and RECURRENCE-ID together say when this happens, so merging " <>
          "a move on one side with a repeat rule from the other produces a series neither of " <>
          "you wrote. Kati would rather ask than invent one."
    }
  end

  @doc false
  def overlap_question(name, local, remote) do
    both = Enum.filter(local, &(&1 in remote))
    named = if both == [], do: "the same event", else: Kati.Screens.Sync.list_names(both)

    %{
      kind: :overlap,
      icon: "call_merge",
      headline: "You and " <> name <> " both changed " <> named <> ".",
      detail:
        "Everything the two of you touched separately has already been merged and kept. " <>
          "This is what is left: one value, changed on both sides, where taking either one " <>
          "means the other is set aside. Whichever you pick, the one you did not pick is " <>
          "kept below rather than dropped."
    }
  end

  @doc "Property names the queued edit changed, sorted."
  @spec changed_names(Operation.t()) :: [String.t()]
  def changed_names(%Operation{changed_properties: properties}) when is_map(properties),
    do: properties |> Map.keys() |> Enum.sort()

  def changed_names(_operation), do: []

  @doc """
  Property names that differ between the merge base and the calendar's bytes.

  `nil` on either side answers `[]` rather than "everything changed": an
  unreadable document is not evidence about who moved, which is the same rule
  `Kati.Sync.Conflict` applies to a missing etag.
  """
  @spec remote_names(String.t() | nil, String.t() | nil) :: [String.t()]
  def remote_names(base, remote) when is_binary(base) and is_binary(remote) do
    with {:ok, base_props} <- ICalendar.properties(base),
         {:ok, remote_props} <- ICalendar.properties(remote) do
      base_props
      |> Map.keys()
      |> Enum.concat(Map.keys(remote_props))
      |> Enum.uniq()
      |> Enum.filter(&(Map.get(base_props, &1) != Map.get(remote_props, &1)))
      |> Enum.sort()
    else
      _ -> []
    end
  end

  def remote_names(_base, _remote), do: []

  @doc """
  Whether the calendar's copy of this row is a deletion.

  `Kati.Sync.Engine.park_conflict/4` writes the remote's bytes onto the row, so
  a `STATUS:CANCELLED` there is the calendar saying it removed the event —
  which RFC 5545 makes the only way a document can say so.
  """
  @spec remote_deleted?(Event.t()) :: boolean()
  def remote_deleted?(%Event{raw_icalendar: raw}) when is_binary(raw) do
    case ICalendar.properties(raw) do
      {:ok, properties} ->
        properties
        |> Map.get("STATUS", [])
        |> Enum.any?(&String.contains?(String.upcase(&1), "CANCELLED"))

      _ ->
        false
    end
  end

  def remote_deleted?(_event), do: false

  @doc "One, two or many property names, as a sentence rather than a list."
  @spec list_names([String.t()]) :: String.t()
  def list_names([]), do: "something"
  def list_names([one]), do: one
  def list_names([one, two]), do: one <> " and " <> two

  def list_names(names) do
    {first, [last]} = Enum.split(names, length(names) - 1)
    Enum.join(first, ", ") <> " and " <> last
  end

  # ── Kept edits ─────────────────────────────────────────────────────────────

  @doc "Every preserved losing edit on the device, with what it would take to put it back."
  @spec rejected_models([CalendarRow.t()]) :: [map()]
  def rejected_models(calendars) do
    Enum.flat_map(calendars, fn calendar ->
      rows = Kati.Screens.Sync.rejected_for(calendar.id)
      events = Kati.Screens.Sync.events_by_uid(Enum.map(rows, & &1.event_uid))

      Enum.map(rows, fn row ->
        Kati.Screens.Sync.rejected_model(row, calendar, Map.get(events, row.event_uid))
      end)
    end)
  end

  @doc false
  @spec rejected_model(RejectedChange.t(), CalendarRow.t(), Event.t() | nil) :: map()
  def rejected_model(row, calendar, event) do
    names = Kati.Screens.Sync.property_names(row.properties)

    %{
      id: row.id,
      side: row.side,
      reason: row.reason,
      names: names,
      entangled: names != [] and Enum.all?(names, &(&1 in @entangled)),
      title: (event && event.summary) || row.event_uid,
      calendar: calendar.display_name || "Untitled calendar",
      kept_at: row.inserted_at,
      writable: event != nil and Ownership.writable?(event, calendar),
      event: event,
      calendar_row: calendar,
      rejected: row
    }
  end

  @doc """
  The property names inside a stored rejection, sorted.

  The column is JSON text rather than a map — `Kati.Sync.RejectedChange` stores
  it that way because SQLite has no JSONB index and it is read whole or not at
  all — so this is where it becomes names again. Anything unreadable answers
  `[]`, and the row still draws: a kept edit whose payload cannot be parsed is
  still a kept edit, and hiding it would be the discard this table exists to
  prevent.
  """
  @spec property_names(String.t() | nil) :: [String.t()]
  def property_names(json) when is_binary(json) do
    case Jason.decode(json) do
      {:ok, map} when is_map(map) -> map |> Map.keys() |> Enum.sort()
      _ -> []
    end
  end

  def property_names(_json), do: []

  @doc false
  @spec events_by_uid([String.t()]) :: %{optional(String.t()) => Event.t()}
  def events_by_uid([]), do: %{}

  def events_by_uid(uids) do
    unique = Enum.uniq(uids)

    Event
    |> Ash.Query.filter(uid in ^unique)
    |> Ash.read!()
    |> Map.new(&{&1.uid, &1})
  rescue
    _ -> %{}
  end

  # ── Words ──────────────────────────────────────────────────────────────────

  @doc """
  The mono line under the title.

  Upper case and abbreviated, which is what that slot is on every other screen
  in the Settings subtree — 24's `1,204 ENTRIES · SYNCED 2 MIN AGO`, 32's
  connected line.
  """
  @spec subtitle(map()) :: String.t()
  def subtitle(%{calendars: []}), do: "NO CALENDAR CONNECTED · NOTHING LEAVES THIS DEVICE"

  def subtitle(state) do
    count = length(state.calendars)
    noun = if count == 1, do: " CALENDAR · LAST SENT ", else: " CALENDARS · LAST SENT "
    Integer.to_string(count) <> noun <> String.upcase(Kati.Screens.Sync.ago(state.last_sync_at))
  end

  @doc """
  How long ago, in the device's own zone.

  A screen may read a wall clock; `Kati.SyncBoundaryTest` forbids it only in
  the four modules that decide whose edit survives, and none of them is this
  one. Nothing here feeds a decision — it is a label.
  """
  @spec ago(DateTime.t() | nil) :: String.t()
  def ago(nil), do: "never"

  def ago(%DateTime{} = at) do
    seconds = DateTime.diff(Kati.Time.now(), at, :second)

    cond do
      seconds < 60 -> "just now"
      seconds < 3600 -> Integer.to_string(div(seconds, 60)) <> "m ago"
      seconds < 86_400 -> Integer.to_string(div(seconds, 3600)) <> "h ago"
      true -> Integer.to_string(div(seconds, 86_400)) <> "d ago"
    end
  end

  @doc "The newest of a list of instants, ignoring the ones that are not set."
  @spec newest([DateTime.t() | nil]) :: DateTime.t() | nil
  def newest(instants) do
    instants
    |> Enum.reject(&is_nil/1)
    |> Enum.sort({:desc, DateTime})
    |> List.first()
  end

  @doc "What a calendar's row says under its name."
  @spec calendar_line(map()) :: String.t()
  def calendar_line(%{writeback_policy: :none} = c) do
    c.account <> " · write-back is off, so changes stay on this device"
  end

  def calendar_line(%{kind: :local} = c) do
    c.account <> " · local calendar, nothing is ever sent"
  end

  def calendar_line(%{partially_synced: [_ | _]} = c) do
    c.account <>
      " · " <>
      Kati.Screens.Sync.plural(length(c.partially_synced), "change") <> " only half landed"
  end

  def calendar_line(%{blocked: b, failed: f} = c) when b + f > 0 do
    c.account <> " · " <> Kati.Screens.Sync.plural(b + f, "change") <> " stuck"
  end

  def calendar_line(%{pending: p} = c) when p > 0 do
    c.account <> " · " <> Kati.Screens.Sync.plural(p, "change") <> " waiting"
  end

  def calendar_line(c) do
    c.account <> " · nothing waiting · last sent " <> Kati.Screens.Sync.ago(c.last_sync_at)
  end

  @doc "The pill at the end of a calendar's row: label, ink, ground."
  @spec calendar_pill(map()) :: {String.t(), pos_integer(), pos_integer()}
  def calendar_pill(%{writeback_policy: :none}), do: {"Read only", Palette.sub(), Palette.paper()}
  def calendar_pill(%{kind: :local}), do: {"On device", Palette.sub(), Palette.paper()}

  def calendar_pill(%{partially_synced: [_ | _]}),
    do: {"Half sent", Palette.red(), Palette.red_wash_strong()}

  def calendar_pill(%{blocked: b, failed: f}) when b + f > 0,
    do: {"Stuck", Palette.red(), Palette.red_wash_strong()}

  def calendar_pill(%{pending: p}) when p > 0,
    do: {"Waiting", Palette.accent(), Palette.accent_wash()}

  def calendar_pill(_calendar), do: {"Clear", Palette.green_text(), Palette.green_wash()}

  @doc "What an account's row says under its name."
  @spec account_line(map()) :: String.t()
  def account_line(a) do
    Kati.Screens.Sync.plural(a.calendars, "calendar") <>
      " · last checked " <> Kati.Screens.Sync.ago(a.last_sync_at)
  end

  @doc "The pill at the end of an account's row."
  @spec account_pill(map()) :: {String.t(), pos_integer(), pos_integer()}
  def account_pill(%{state: :live}), do: {"Live", Palette.green_text(), Palette.green_wash()}
  def account_pill(%{state: :stale}), do: {"Stale", Palette.red(), Palette.red_wash_strong()}
  def account_pill(%{state: :error}), do: {"Error", Palette.red(), Palette.red_wash_strong()}
  def account_pill(_account), do: {"Off", Palette.sub(), Palette.paper()}

  @doc "The glyph on an outbox row: what the change is, not how it is going."
  @spec op_icon(atom()) :: String.t()
  def op_icon(:create), do: "add"
  def op_icon(:update), do: "edit"
  def op_icon(:delete), do: "delete"
  def op_icon(_op), do: "sync"

  @doc "The verb an outbox row leads with."
  @spec op_label(atom()) :: String.t()
  def op_label(:create), do: "New event"
  def op_label(:update), do: "Changed"
  def op_label(:delete), do: "Deleted"
  def op_label(_op), do: "Change"

  @doc """
  Why an entry is where it is, in a sentence.

  The blocked arm is the one that had to be written rather than templated:
  `Kati.Sync.Outbox.fail/3` puts both `:reauth` and `:conflict` in `:blocked`
  and the column cannot tell them apart, so the row asks the other table —
  a conflicted event with this UID means the answer is the question below, and
  no conflicted event means it is the account, not the merge.
  """
  @spec entry_line(map()) :: String.t()
  def entry_line(%{waiting_on: true} = e) do
    e.calendar <> " · waiting for an earlier change to land first"
  end

  def entry_line(%{state: :in_flight} = e), do: e.calendar <> " · sending now"

  def entry_line(%{state: :blocked, conflicted: true} = e) do
    e.calendar <> " · blocked until you answer the question below"
  end

  def entry_line(%{state: :blocked} = e) do
    e.calendar <>
      " · blocked · " <>
      Kati.Screens.Sync.reason(e.last_error) <>
      " — trying again cannot fix this on its own"
  end

  def entry_line(%{state: :push_failed} = e) do
    e.calendar <>
      " · gave up after " <>
      Kati.Screens.Sync.plural(e.attempts, "attempt") <>
      " · " <> Kati.Screens.Sync.reason(e.last_error)
  end

  def entry_line(%{attempts: 0} = e), do: e.calendar <> " · queued, nothing has been lost"

  def entry_line(e) do
    e.calendar <>
      " · trying again · " <> Kati.Screens.Sync.plural(e.attempts, "attempt") <> " so far"
  end

  @doc """
  The engine's own recorded reason, made readable.

  `Kati.Sync.Engine.park_conflict/4` writes the merge verdict here verbatim and
  `Kati.Sync.Outbox.fail/3` writes `inspect/1` of whatever the transport said,
  so this maps the three it knows and passes anything else through rather than
  flattening it to "an error" — a message nobody can act on is the failure this
  whole page exists to remove.
  """
  @spec reason(String.t() | nil) :: String.t()
  def reason(nil), do: "no reason was recorded"
  def reason("delete_edit"), do: "a deletion met an edit"
  def reason("no_base"), do: "the version this edit started from is missing"
  def reason("unparseable"), do: "one of the two versions could not be read"

  def reason(text) when is_binary(text) do
    if String.contains?(text, "remote_moved") do
      "the calendar moved under this change"
    else
      text
    end
  end

  @doc "What a kept edit's row says under the event's name."
  @spec kept_line(map()) :: String.t()
  def kept_line(row) do
    Kati.Screens.Sync.kept_owner(row.side) <>
      " " <>
      Kati.Screens.Sync.kept_names(row) <>
      ", kept " <>
      Kati.Screens.Sync.ago(row.kept_at) <> " · " <> Kati.Screens.Sync.why(row.reason)
  end

  @doc false
  def kept_owner(:local), do: "Your"
  def kept_owner(:remote), do: "The calendar's"

  @doc false
  def kept_names(%{names: []}), do: "edit"
  def kept_names(%{names: names}), do: Kati.Screens.Sync.list_names(names)

  @doc """
  Which rule set this edit aside.

  `:ownership_kati` and `:ownership_mirror` are the asymmetry stated at the
  point it bit: `Kati.Calendars.Event.origin` decides, and it is a column set
  at creation, never the calendar's colour and never which app wrote the row.
  """
  @spec why(atom()) :: String.t()
  def why(:ownership_kati), do: "this is a Kati event, so Kati's version won"
  def why(:ownership_mirror), do: "this event is mirrored, so the calendar's version won"
  def why(:delete_edit), do: "a deletion met an edit"
  def why(:user_choice), do: "you chose the other one"
  def why(_reason), do: "set aside by a rule"

  @doc "`1 change` / `2 changes`, without a formatter for two words."
  @spec plural(integer(), String.t()) :: String.t()
  def plural(1, noun), do: "1 " <> noun
  def plural(n, noun), do: Integer.to_string(n) <> " " <> noun <> "s"

  # ── Drawing ────────────────────────────────────────────────────────────────

  @doc false
  def content(assigns) do
    s = assigns.sync
    message = assigns.message
    subtitle = Kati.Screens.Sync.subtitle(s)

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {SettingsList.chrome(nil, 42)}
        {SettingsList.title("Sync", subtitle)}
        {Kati.Screens.Sync.tallies(s)}
        {Kati.Screens.Sync.notice(message)}
        {Kati.Screens.Sync.footnote("shield", Kati.Screens.Sync.ownership_note())}
        {UI.eyebrow("Accounts")}
        {Kati.Screens.Sync.accounts(s.accounts)}
        {UI.eyebrow("Calendars")}
        {Kati.Screens.Sync.calendars(s.calendars)}
        {UI.eyebrow("Waiting to send")}
        {Kati.Screens.Sync.outbox(s.outbox)}
        {UI.eyebrow("Needs you")}
        {Kati.Screens.Sync.questions(s.conflicts)}
        {SettingsList.eyebrow_muted("Kept, not sent")}
        {Kati.Screens.Sync.kept(s.rejected)}
        {Kati.Screens.Sync.footnote("call_merge", Kati.Screens.Sync.merge_note())}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The asymmetry, in the page's own words.

  `Kati.Sync`'s moduledoc states it as a rule about ownership; this is the same
  sentence written for the person holding the phone. It sits above the groups
  rather than under them because it is what the rest of the page means, not a
  caveat about it.
  """
  @spec ownership_note() :: String.t()
  def ownership_note do
    "This device holds the original. A calendar you connect is somewhere else Kati copies " <>
      "to and cannot lock, so a disagreement here almost always means that calendar changed " <>
      "under something you did — not that two equal copies drifted apart. Kati sends only " <>
      "the events it created, unless you turn write-back on for a calendar."
  end

  @doc "The sentence the Kept group exists to make true."
  @spec merge_note() :: String.t()
  def merge_note do
    "Nothing above was thrown away. Every edit that lost is kept here with the version it " <>
      "started from, so putting one back is the same three-way merge as any other edit — it " <>
      "goes through the queue, it can be refused, and it will not overwrite whatever the " <>
      "winner left behind."
  end

  @doc """
  The three headline counts.

  `Kati.UI.number_with_unit/3` rather than two stacked `Text`s: the unit is a
  10pt mono cap beside a 26pt figure, and `align="bottom"` alone drops the
  small one three or four points below the big one's baseline. The lift is
  declared, as that helper's doc requires — no metrics come back from a render.
  """
  @spec tallies(map()) :: term()
  def tallies(s) do
    waiting = Kati.Screens.Sync.tally(s.waiting, "WAITING")
    stuck = Kati.Screens.Sync.tally(s.stuck, "STUCK")
    asking = Kati.Screens.Sync.tally(length(s.conflicts), "TO ANSWER")

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Kati.Theme.card(Palette.mode())}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={18}
        align="bottom"
      >
        <Column weight={1.0}>
          {waiting}
        </Column>
        <Column weight={1.0}>
          {stuck}
        </Column>
        <Column weight={1.0}>
          {asking}
        </Column>
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def tally(count, unit) do
    text = Integer.to_string(count)
    ink = if count == 0, do: Palette.tertiary(), else: Palette.ink()

    number = ~MOB"""
    <Text
      text={text}
      text_size={26}
      font_weight="bold"
      letter_spacing={-0.03}
      text_color={ink}
      max_lines={1}
    />
    """

    label = ~MOB"""
    <Text
      text={unit}
      font_family="mono"
      text_size={9.5}
      letter_spacing={0.14}
      text_color={Palette.eyebrow()}
      max_lines={1}
    />
    """

    UI.number_with_unit(number, label, 4)
  end

  @doc """
  What the last tap did, or nothing at all.

  Drawn as `Kati.UI.SettingsList.note/2` rather than as a toast, because the
  refusals this page can produce are ones the user has to read —
  `Kati.Sync.Ownership.authorise/2`'s `detail.reason` is a whole sentence about
  a policy, and the Ownership moduledoc says the editor is the thing that
  renders it.
  """
  @spec notice(String.t() | nil) :: term()
  def notice(nil), do: ~MOB"<Spacer size={0} />"

  def notice(message), do: Kati.Screens.Sync.footnote("info", message)

  @doc false
  def footnote(icon, text) do
    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.note(icon, text)}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def accounts([]) do
    Kati.Screens.Sync.empty_card(
      "person",
      "No account is connected",
      "Kati is complete with none. Connect one in Calendars and it will appear here."
    )
  end

  def accounts(rows) do
    last = length(rows) - 1

    body =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, i} -> Kati.Screens.Sync.account_row(row, i < last) end)

    Kati.Screens.Sync.group(body)
  end

  @doc false
  def account_row(a, rule?) do
    {label, ink, ground} = Kati.Screens.Sync.account_pill(a)

    SettingsList.row(
      SettingsList.icon_tile(a.icon),
      Kati.Screens.Sync.body(a.title, Kati.Screens.Sync.account_line(a)),
      SettingsList.status_pill(label, ink, ground),
      padding: 13,
      rule: rule?
    )
  end

  @doc false
  def calendars([]) do
    Kati.Screens.Sync.empty_card(
      "calendar_month",
      "No calendar is connected",
      "Everything you add stays on this device, which is where Kati keeps the original anyway."
    )
  end

  def calendars(rows) do
    last = length(rows) - 1

    body =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, i} -> Kati.Screens.Sync.calendar_row(row, i < last) end)

    Kati.Screens.Sync.group(body)
  end

  @doc false
  def calendar_row(c, rule?) do
    {label, ink, ground} = Kati.Screens.Sync.calendar_pill(c)

    SettingsList.row(
      SettingsList.icon_tile(Kati.Screens.Sync.calendar_icon(c)),
      Kati.Screens.Sync.body(c.title, Kati.Screens.Sync.calendar_line(c)),
      SettingsList.status_pill(label, ink, ground),
      padding: 13,
      rule: rule?
    )
  end

  @doc false
  def calendar_icon(%{kind: :local}), do: "phone_iphone"
  def calendar_icon(%{writeback_policy: :none}), do: "lock"
  def calendar_icon(%{read_only: true}), do: "lock"
  def calendar_icon(_calendar), do: "sync"

  @doc false
  def outbox([]) do
    Kati.Screens.Sync.empty_card(
      "cloud_done",
      "Nothing is waiting",
      "Every change Kati has made has already left this device, or never needed to."
    )
  end

  def outbox(rows) do
    shown = Enum.take(rows, @outbox_limit)
    last = length(shown) - 1

    body =
      shown
      |> Enum.with_index()
      |> Enum.map(fn {row, i} -> Kati.Screens.Sync.outbox_row(row, i, i < last) end)

    Kati.Screens.Sync.group(body ++ Kati.Screens.Sync.overflow(rows, @outbox_limit, "change"))
  end

  @doc """
  One queued change.

  The trailing control is **Retry** on `:push_failed` and a state pill on
  everything else — see the moduledoc on why a blocked entry does not get one.
  The tap tag carries the row's position in the list this render drew, not the
  entry's id: a UUID in a tag means `String.to_atom/1` on unbounded input, and
  the atom table is never collected.
  """
  @spec outbox_row(map(), non_neg_integer(), boolean()) :: term()
  def outbox_row(e, index, rule?) do
    tag = if e.state == :push_failed, do: {self(), :"retry_#{index}"}

    SettingsList.row(
      SettingsList.icon_tile(Kati.Screens.Sync.op_icon(e.op)),
      Kati.Screens.Sync.body(
        Kati.Screens.Sync.op_label(e.op) <> " · " <> e.title,
        Kati.Screens.Sync.entry_line(e)
      ),
      Kati.Screens.Sync.outbox_trailing(e),
      padding: 13,
      rule: rule?,
      on_tap: tag
    )
  end

  @doc false
  def outbox_trailing(%{state: :push_failed}), do: SettingsList.action_pill("Retry")

  def outbox_trailing(%{half_landed: true}),
    do: SettingsList.status_pill("Half sent", Palette.red(), Palette.red_wash_strong())

  def outbox_trailing(%{state: :blocked}),
    do: SettingsList.status_pill("Blocked", Palette.red(), Palette.red_wash_strong())

  def outbox_trailing(%{state: :in_flight}),
    do: SettingsList.status_pill("Sending", Palette.accent(), Palette.accent_wash())

  def outbox_trailing(%{waiting_on: true}),
    do: SettingsList.status_pill("After", Palette.sub(), Palette.paper())

  def outbox_trailing(_entry),
    do: SettingsList.status_pill("Queued", Palette.accent(), Palette.accent_wash())

  @doc false
  def questions([]) do
    Kati.Screens.Sync.empty_card(
      "check_circle",
      "Nothing is waiting on you",
      "Kati asks only when it genuinely cannot decide without inventing something."
    )
  end

  def questions(rows) do
    shown = Enum.take(rows, @conflict_limit)

    cards =
      shown
      |> Enum.with_index()
      |> Enum.map(fn {row, i} -> Kati.Screens.Sync.question_card(row, i) end)

    extra = Kati.Screens.Sync.overflow(rows, @conflict_limit, "question")

    ~MOB"""
    <Column fill_width={true}>
      {cards}
      {Kati.Screens.Sync.group(extra)}
    </Column>
    """
  end

  @doc """
  One conflict, as a card: what it is about, the question, and three answers.

  The three answers are rows rather than a strip of pills, and that is the one
  place this page argues with screen 37's shape. 37 puts *Keep mine / Take file
  / Keep both* in a segmented strip because it is resolving forty rows of a CSV
  and the same three words apply to every one. Here each answer has a different
  consequence for *this* event — one of them creates a second event — and a
  three-word pill cannot say which. So each answer carries its own line.
  """
  @spec question_card(map(), non_neg_integer()) :: term()
  def question_card(c, index) do
    header =
      SettingsList.row(
        SettingsList.icon_tile(c.icon),
        Kati.Screens.Sync.body(c.title, c.calendar),
        SettingsList.status_pill("Needs you", Palette.accent(), Palette.accent_wash()),
        padding: 13,
        rule: true
      )

    body = Kati.Screens.Sync.question_body(c.headline, c.detail)
    choices = Kati.Screens.Sync.answers(c, index)

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card([header, body] ++ choices)}
      <Spacer size={14} />
    </Column>
    """
  end

  @doc false
  def question_body(headline, detail) do
    ~MOB"""
    <Column fill_width={true} padding_top={14} padding_bottom={14}>
      <Text
        text={headline}
        text_size={13.5}
        font_weight="semibold"
        line_height={1.35}
        text_color={:on_surface}
      />
      <Spacer size={7} />
      <Text text={detail} text_size={12.5} line_height={1.55} text_color={Palette.ink_soft()} />
    </Column>
    """
  end

  @doc """
  The three answers `Kati.Sync.resolve/3` takes, each with what it does.

  Named for what happens rather than for the atom: `:take_file` is the import
  wizard's word for a CSV and there is no file here, so the row says *Take
  <calendar>'s* — which is also the only phrasing that keeps the asymmetry
  visible, since one of these two sides is an upstream and the other is this
  device.
  """
  @spec answers(map(), non_neg_integer()) :: [term()]
  def answers(c, index) do
    name = c.calendar

    [
      Kati.Screens.Sync.answer_row(
        "phone_iphone",
        "Keep mine",
        "Send your version. Theirs is kept below.",
        {self(), :"keep_mine_#{index}"},
        true
      ),
      Kati.Screens.Sync.answer_row(
        "cloud",
        "Take " <> name <> "'s",
        "Drop the queued change. Yours is kept below.",
        {self(), :"take_theirs_#{index}"},
        true
      ),
      Kati.Screens.Sync.answer_row(
        "call_split",
        "Keep both",
        "Theirs stays. Yours becomes a new event.",
        {self(), :"keep_both_#{index}"},
        false
      )
    ]
  end

  @doc false
  def answer_row(icon, title, sub, tap, rule?) do
    SettingsList.row(
      SettingsList.icon_tile(icon),
      Kati.Screens.Sync.body(title, sub),
      SettingsList.chevron(),
      padding: 12,
      rule: rule?,
      on_tap: tap
    )
  end

  @doc false
  def kept([]) do
    Kati.Screens.Sync.empty_card(
      "history",
      "Nothing has been set aside",
      "When two changes cannot both survive, the one that loses is kept here rather than lost."
    )
  end

  def kept(rows) do
    shown = Enum.take(rows, @rejected_limit)
    last = length(shown) - 1

    body =
      shown
      |> Enum.with_index()
      |> Enum.map(fn {row, i} -> Kati.Screens.Sync.kept_row(row, i, i < last) end)

    Kati.Screens.Sync.group(body ++ Kati.Screens.Sync.overflow(rows, @rejected_limit, "edit"))
  end

  @doc """
  One preserved losing edit.

  **Re-apply** is drawn only where `Kati.Sync.Ownership.writable?/2` says the
  write would be allowed, so the page never offers a control that policy will
  refuse — and the refusal is still handled, because the second gate in
  `Kati.Sync.Outbox.enqueue/1` is a separate call by design.
  """
  @spec kept_row(map(), non_neg_integer(), boolean()) :: term()
  def kept_row(row, index, rule?) do
    tag = if row.writable, do: {self(), :"reapply_#{index}"}

    SettingsList.row(
      SettingsList.icon_tile(Kati.Screens.Sync.kept_icon(row)),
      Kati.Screens.Sync.body(row.title, Kati.Screens.Sync.kept_line(row)),
      Kati.Screens.Sync.kept_trailing(row),
      padding: 13,
      rule: rule?,
      on_tap: tag
    )
  end

  @doc false
  def kept_icon(%{entangled: true}), do: "event_repeat"
  def kept_icon(%{reason: :delete_edit}), do: "event_busy"
  def kept_icon(_row), do: "history"

  @doc false
  def kept_trailing(%{writable: true}), do: SettingsList.action_pill("Re-apply")

  def kept_trailing(_row),
    do: SettingsList.status_pill("Kept", Palette.sub(), Palette.paper())

  @doc """
  The row a truncated list ends with, or nothing.

  A cap that hid its own existence would make a queue of two hundred look like
  a queue of twelve, which is the one thing a page about a queue must not do.
  """
  @spec overflow([term()], pos_integer(), String.t()) :: [term()]
  def overflow(rows, limit, noun) do
    hidden = length(rows) - limit

    if hidden > 0 do
      [
        SettingsList.row(
          SettingsList.icon_tile("more_horiz"),
          SettingsList.body_muted(Kati.Screens.Sync.plural(hidden, noun) <> " more, not shown"),
          nil,
          padding: 13,
          rule: false
        )
      ]
    else
      []
    end
  end

  @doc false
  def group([]), do: ~MOB"<Spacer size={0} />"

  def group(body) do
    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(body)}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  A group with nothing in it, which is this screen's ordinary state.

  Drawn as a real row in a real card rather than as absence: a settings group
  that vanishes when it is empty makes the page's shape depend on the data, and
  a person who has never had a conflict should still be able to see where the
  answer would appear.
  """
  @spec empty_card(String.t(), String.t(), String.t()) :: term()
  def empty_card(icon, title, sub) do
    row =
      SettingsList.row(
        SettingsList.icon_tile(icon),
        Kati.Screens.Sync.muted_body(title, sub),
        nil,
        padding: 14,
        rule: false
      )

    Kati.Screens.Sync.group([row])
  end

  @doc """
  A row's title over a second line that is allowed to wrap.

  `Kati.UI.SettingsList.body/2` pins its second line to `max_lines: 1`, which
  is right for *"CSV, JSON, or another tracker's backup"* and wrong for
  *"blocked · the calendar moved under this change — trying again cannot fix
  this on its own"*. Same type, same colours, same 3pt gap; three lines instead
  of one.

  Three and not two, and it is measured rather than picked: a row's body sits
  in roughly 195pt once the 21pt page gutters, the card's 15pt sides, the 30pt
  tile, its 13pt gap and a trailing pill are taken out, which is about 34
  characters of 11.5pt text. The longest line this screen builds — a kept
  edit's properties, when it was kept, and which rule set it aside — runs to
  ninety-odd. At two lines it ellipsised exactly the half that says *why*.
  """
  @spec body(String.t(), String.t()) :: term()
  def body(title, sub) do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={title}
        text_size={13.5}
        font_weight="semibold"
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer size={3} />
      <Text text={sub} text_size={11.5} line_height={1.35} text_color={Palette.sub()} max_lines={3} />
    </Column>
    """
  end

  @doc "The same two lines, greyed, for a group with nothing in it."
  @spec muted_body(String.t(), String.t()) :: term()
  def muted_body(title, sub) do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={title}
        text_size={13.5}
        font_weight="semibold"
        text_color={Palette.sub()}
        max_lines={1}
      />
      <Spacer size={3} />
      <Text
        text={sub}
        text_size={11.5}
        line_height={1.35}
        text_color={Palette.muted()}
        max_lines={3}
      />
    </Column>
    """
  end

  # ── Answering ──────────────────────────────────────────────────────────────

  @impl true
  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "retry_" <> index ->
        {:noreply, Kati.Screens.Sync.act(socket, :outbox, index, &Kati.Screens.Sync.retry/1)}

      "keep_mine_" <> index ->
        {:noreply, Kati.Screens.Sync.resolve(socket, index, :keep_mine)}

      "take_theirs_" <> index ->
        {:noreply, Kati.Screens.Sync.resolve(socket, index, :take_file)}

      "keep_both_" <> index ->
        {:noreply, Kati.Screens.Sync.resolve(socket, index, :keep_both)}

      "reapply_" <> index ->
        {:noreply, Kati.Screens.Sync.act(socket, :rejected, index, &Kati.Screens.Sync.reapply/1)}

      _other ->
        {:noreply, socket}
    end
  end

  @doc """
  Run `fun` over the row `index` names in `list`, then re-read the page.

  Every arm ends in a re-read plus a message, which is deliberate on two
  counts. A queue is the one thing on which stale assigns are actively
  misleading — an entry that has just been requeued must stop saying it gave
  up — and a tap that changed nothing in the assigns is indistinguishable from
  a dead control to `Kati.ScreenTapSweepTest`'s heuristic, which is exactly the
  net this app relies on.
  """
  @spec act(Mob.Socket.t(), atom(), String.t(), (map() -> String.t())) :: Mob.Socket.t()
  def act(socket, list, index, fun) do
    rows = Map.get(socket.assigns.sync, list, [])

    case Kati.Screens.Sync.at(rows, index) do
      nil ->
        Kati.Screens.Sync.settle(socket, "That row is no longer here. The page has been re-read.")

      row ->
        Kati.Screens.Sync.settle(socket, Kati.Screens.Sync.attempt(fun, row))
    end
  end

  @doc false
  def resolve(socket, index, choice) do
    rows = socket.assigns.sync.conflicts

    case Kati.Screens.Sync.at(rows, index) do
      nil ->
        Kati.Screens.Sync.settle(
          socket,
          "That question is no longer here. The page has been re-read."
        )

      row ->
        answer = fn r -> Kati.Screens.Sync.answer(r, choice) end
        Kati.Screens.Sync.settle(socket, Kati.Screens.Sync.attempt(answer, row))
    end
  end

  @doc """
  Anything a tap does, with the raise turned into a sentence.

  `Kati.Screens.Root.rescue_tap/3` already stops a raise from killing the
  screen process, but it answers with a `DEAD TAP` report meant for a developer
  reading a log. A person who tapped Retry deserves to be told the retry did
  not happen, on the screen, which is what this is for.
  """
  @spec attempt((map() -> String.t()), map()) :: String.t()
  def attempt(fun, row) do
    fun.(row)
  rescue
    error -> "That did not go through: " <> Exception.message(error)
  end

  @doc "`Kati.Sync.Outbox.retry/1` — the one control a quarantined entry gets."
  @spec retry(map()) :: String.t()
  def retry(row) do
    Kati.Sync.Outbox.retry(row.entry)
    "Queued again. Kati will try to send it the next time it syncs."
  end

  @doc """
  One of `Kati.Sync.resolve/3`'s three answers, applied and then described.

  The description is not decoration. *Keep both* is the only lossless answer
  and it is also the only one that leaves the device holding **two** events, so
  a person who picks it and is told nothing will later find a duplicate and
  read it as a bug.
  """
  @spec answer(map(), :keep_mine | :take_file | :keep_both) :: String.t()
  def answer(row, choice) do
    case Kati.Sync.resolve(row.event, row.calendar_row, choice) do
      {:ok, _event} -> Kati.Screens.Sync.answered(row, choice)
      {:error, reason} -> Kati.Screens.Sync.refused(reason)
      _other -> "Kati could not tell whether that went through, so nothing has been assumed."
    end
  end

  @doc false
  def answered(row, :keep_mine) do
    "Your version is queued again. What " <> row.calendar <> " had is kept below."
  end

  def answered(row, :take_file) do
    row.calendar <> "'s version is what stays. Your edit is kept below, not discarded."
  end

  def answered(row, :keep_both) do
    row.calendar <>
      " keeps its version, and yours is now a separate Kati event with its own identifier."
  end

  @doc """
  Put a kept edit back, in the order that cannot lose it.

  `Kati.Sync.Ownership.authorise/2` first — the same call with the same two
  arguments `Kati.Sync.edit/3` makes before it writes anything — then
  `Kati.Sync.reapply/1`, which marks the row applied and hands over the
  property lines, then `Kati.Sync.edit/3`, which is the only door a local edit
  uses. Marking before editing is safe *because* of the order: the gate that
  could refuse has already answered.
  """
  @spec reapply(map()) :: String.t()
  def reapply(%{event: nil}) do
    "The event this edit belonged to is no longer on the device, so there is nothing to put " <>
      "it back into."
  end

  def reapply(row) do
    with :ok <- Ownership.authorise(row.event, row.calendar_row),
         {:ok, properties} <- Kati.Sync.reapply(row.rejected),
         {:ok, _event} <- Kati.Sync.edit(row.event, row.calendar_row, %{properties: properties}) do
      "Put back and queued. It goes out as an ordinary edit, merged against what is there now."
    else
      {:error, reason} -> Kati.Screens.Sync.refused(reason)
      _other -> "Kati could not read what was kept, so nothing has been changed."
    end
  end

  @doc """
  A refusal, in the words the refusing module chose.

  `Kati.Sync.Ownership.authorise/2` builds `detail.reason` as a whole sentence
  naming the calendar and its policy, and its own moduledoc says the editor is
  what renders it. Flattening that to "not allowed" would throw away the only
  part a person could act on.
  """
  @spec refused(term()) :: String.t()
  def refused({:not_writable, %{reason: reason}}) when is_binary(reason),
    do: "Kati did not send that: " <> reason <> "."

  def refused({:read_only_transport, _detail}),
    do: "That calendar cannot be written to at all, so nothing was queued."

  def refused(reason), do: "That did not go through: " <> inspect(reason)

  @doc false
  @spec at([map()], String.t()) :: map() | nil
  def at(rows, index) do
    case Integer.parse(index) do
      {i, ""} when i >= 0 -> Enum.at(rows, i)
      _ -> nil
    end
  end

  @doc false
  @spec settle(Mob.Socket.t(), String.t()) :: Mob.Socket.t()
  def settle(socket, message) do
    socket
    |> Mob.Socket.assign(:sync, Kati.Screens.Sync.state())
    |> Mob.Socket.assign(:message, message)
  end
end
