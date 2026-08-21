defmodule Kati.Sync.Ownership do
  @moduledoc """
  Who owns a row: Kati, a remote, or nobody yet.

  `Kati.Backup.Catalog` already answers a neighbouring question — is this row
  the user's own work (`:backup`), or someone else's data Kati holds
  temporarily (`:cache`)? Sync needs the same distinction one step finer,
  because a calendar row can be *both*: an event Kati created **into** a Google
  calendar is Kati-owned and remote-backed at the same time. That is why
  `Kati.Calendars.Event.origin` is one enum in one table, not two tables, and
  why `remote_id` sits beside it rather than implying anything.

      origin: :kati,   calendar local     → never synced. Habits, meals, air-dates.
      origin: :kati,   calendar remote    → Kati is authoritative; local wins on conflict.
      origin: :mirror                     → the remote is authoritative.

  ## The predicate

  Screen 32 promises Kati *"never touches an event it did not create"*. That is
  one line, `permitted?/2`:

      origin == :kati or calendar.writeback_policy == :full

  `writable?/2` is that predicate **and** the feed-level veto: a calendar whose
  policy is `:none` accepts nothing at all, not even a Kati-owned event. That
  is what `Kati.Calendars.DeviceImport` sets for every provider calendar,
  because Kati does not request `WRITE_CALENDAR` — and a queue of writes that
  can never be delivered is worse than a refusal at the door. The two functions
  are separate so the stricter rule cannot be mistaken for the promise.

  ## Two gates, on purpose

  The editor calls `Kati.Sync.edit/3`, which authorises before it writes, so
  the UI is read-only where policy forbids. `Kati.Sync.Outbox.enqueue/1`
  authorises **again**, independently, so a write reaching the queue by a path
  the editor does not own is still refused. They do not share a call; that is
  the point of having two.

  ## What is *not* the ownership signal

  Not the section colour, not the calendar colour, not which app created the
  row. `origin` is set at creation and
  `Kati.Calendars.Changes.RejectOriginChange` makes it immutable, so a mirrored
  event can never quietly become a Kati-owned one and get pushed to a server
  that never asked for it.

  ## Overrides

  An override has no `origin` of its own: it is part of the same iCalendar
  resource as its master, so it inherits the master's ownership. Callers pass
  `%{origin: master.origin}` rather than the override row, which keeps the
  inheritance visible at the call site instead of buried here.
  """

  alias Kati.Calendars.Calendar

  @typedoc """
  The three ownership situations, named.

  `:kati_local` is the common case and the one that costs nothing: it never
  goes near a transport.
  """
  @type class :: :kati_local | :kati_remote | :mirror

  @typedoc "Anything carrying an `origin` — an event, or `%{origin: master.origin}`."
  @type owned :: %{:origin => :kati | :mirror, optional(any()) => any()}

  @doc "Which of the three situations a row is in."
  @spec classify(owned(), Calendar.t()) :: class()
  def classify(%{origin: :mirror}, %Calendar{}), do: :mirror
  def classify(%{origin: :kati}, %Calendar{kind: :local}), do: :kati_local
  def classify(%{origin: :kati}, %Calendar{}), do: :kati_remote

  @doc """
  Screen 32's promise, exactly as the design states it.

  Deliberately does **not** consider `:none`; see `writable?/2`.
  """
  @spec permitted?(owned(), Calendar.t()) :: boolean()
  def permitted?(%{origin: :kati}, %Calendar{}), do: true
  def permitted?(%{origin: :mirror}, %Calendar{writeback_policy: :full}), do: true
  def permitted?(%{origin: :mirror}, %Calendar{}), do: false

  @doc """
  Whether Kati may write this row back to this feed at all.

  `permitted?/2` and the feed-level `:none` veto together.
  """
  @spec writable?(owned(), Calendar.t()) :: boolean()
  def writable?(_row, %Calendar{writeback_policy: :none}), do: false
  def writable?(row, %Calendar{} = calendar), do: permitted?(row, calendar)

  @doc """
  `:ok`, or a refusal naming why.

  Returned rather than raised so both gates can report it: the editor renders
  it as a read-only state, the engine as a rejected enqueue.
  """
  @spec authorise(owned(), Calendar.t()) :: :ok | {:error, {:not_writable, map()}}
  def authorise(row, %Calendar{} = calendar) do
    if writable?(row, calendar) do
      :ok
    else
      {:error,
       {:not_writable,
        %{
          origin: Map.get(row, :origin),
          writeback_policy: calendar.writeback_policy,
          calendar_id: calendar.id,
          reason: refusal(row, calendar)
        }}}
    end
  end

  @doc """
  Who wins an overlapping conflict, from ownership alone.

  No timestamp is consulted. `Kati.Sync.Merge` reaches this only after a
  property-level merge has failed to make the question go away.
  """
  @spec winner(owned() | :kati | :mirror) :: :local | :remote
  def winner(:kati), do: :local
  def winner(:mirror), do: :remote
  def winner(%{origin: origin}), do: winner(origin)

  @doc """
  Whether this row's mutations should ever reach a transport at all.

  A Kati event on a local calendar is a complete, correct, permanently unsynced
  row. It is not "pending" and it is not an error.
  """
  @spec syncable?(owned(), Calendar.t()) :: boolean()
  def syncable?(row, calendar), do: classify(row, calendar) != :kati_local

  defp refusal(_row, %Calendar{writeback_policy: :none} = calendar) do
    "write-back is off for #{name(calendar)}, so Kati stores changes locally and sends nothing"
  end

  defp refusal(_row, calendar) do
    "this event is mirrored from #{name(calendar)} and that feed's write-back policy is " <>
      "#{calendar.writeback_policy} — only events Kati created are sent"
  end

  defp name(%Calendar{display_name: nil}), do: "a remote calendar"
  defp name(%Calendar{display_name: display_name}), do: display_name
end
