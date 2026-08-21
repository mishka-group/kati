defmodule Kati.Notifications.Candidate do
  @moduledoc """
  One notification a domain intends to exist, before the budget has had its say.

  A candidate is a *statement of intent*, not an armed alarm: the six domains
  build these and hand them to `Kati.Notifications.Scheduler`, which decides
  which of them survive. Nothing here talks to a platform, and a candidate
  carries no idea of which one it is on.

  ## The two kinds of time, and why they are not the same field

  Android arms absolute epoch milliseconds (`RTC_WAKEUP`), so an alarm does not
  move when the user does. That is right for one kind of reminder and wrong for
  the other:

    * `absolute/4` — *this instant*. An air date at 19:00 in the show's own
      market is a fact about the world; a Tehran → London flight must not move
      it.
    * `wall_clock/5` — *this time of day, wherever you are*. A 07:00 habit is
      07:00 in whatever zone the phone is in this morning. Passing `nil` for the
      zone means exactly that ("floating", the same model
      `Kati.Calendars.Event` uses for `tzid: nil`); naming a zone pins the wall
      clock to that zone instead.

  A wall-clock candidate holds its `NaiveDateTime` and resolves to an instant
  only inside `resolve/2`, through `Kati.Time`, which already has Kati's answers
  for the two nights a year when a wall-clock time does not exist or exists
  twice — `after` for a spring-forward gap, `first` for a fall-back ambiguity.
  That is why a timezone change needs no rebuild code: the same candidate list
  planned again with a new zone produces new instants for the wall-clock entries
  and identical ones for the absolute entries.

  ## Ids are deterministic, and that is a cross-language contract

  `id/1` joins its parts with `":"` — `"ep:tmdb:1396"`, `"habit:3:2026-08-18"`.
  They are derived from identity, never from a counter or a timestamp, for three
  reasons: re-planning must recognise an alarm it already armed (upserting the
  same id is idempotent, and both `MobNotify.schedule/2` and Android's
  `FLAG_UPDATE_CURRENT` are built for it), the Kotlin worker of #58 cancels a
  stale air-date alarm by rebuilding the id from `(show, season, episode)`
  without asking the BEAM, and a test can assert on *which* notifications
  survived a budget rather than only how many.

  ## A candidate can arrive already suppressed

  `suppressed/4` exists so the answer "no, and here is why" travels the same
  path as the answer "yes, at 19:00". `Kati.Media.Release.alarm_at/3` returns
  `{:suppressed, :muted}` or `{:suppressed, :low_confidence}`, and those reasons
  have to reach the plan — the *"why am I not getting notifications?"* screen is
  a listing of them. A suppressed candidate has no `fire_at` and never competes
  for a slot.
  """

  alias Kati.Notifications.Budget

  @typedoc "Lower is more urgent. Priority breaks ties; it never outranks time."
  @type priority :: :high | :normal | :low

  @typedoc """
  Whether quiet hours may move this entry.

  `:shift` is the default and the manners rule. `:exempt` is for a reminder tied
  to something's own clock — a 07:30 meeting alert shifted to 08:00 arrives
  after the meeting started, which is worse than arriving early in the morning.
  """
  @type quiet_hours :: :shift | :exempt

  @type at ::
          {:absolute, DateTime.t()}
          | {:wall_clock, NaiveDateTime.t(), String.t() | nil}
          | nil

  @type t :: %__MODULE__{
          id: String.t(),
          domain: Budget.domain(),
          at: at(),
          fire_at: DateTime.t() | nil,
          title: String.t() | nil,
          body: String.t() | nil,
          priority: priority(),
          quiet_hours: quiet_hours(),
          members: [String.t()],
          suppressed: atom() | nil,
          shifted_from: DateTime.t() | nil,
          meta: map()
        }

  defstruct [
    :id,
    :domain,
    :at,
    :fire_at,
    :title,
    :body,
    :suppressed,
    :shifted_from,
    priority: :normal,
    quiet_hours: :shift,
    members: [],
    meta: %{}
  ]

  @priorities %{high: 0, normal: 1, low: 2}

  @doc """
  A candidate for one instant, wherever the user happens to be standing.

  Options: `:title`, `:body`, `:priority`, `:quiet_hours`, `:members`, `:meta`.
  """
  @spec absolute(String.t(), Budget.domain(), DateTime.t(), keyword()) :: t()
  def absolute(id, domain, %DateTime{} = at, opts \\ []) do
    build(id, domain, {:absolute, at}, opts)
  end

  @doc """
  A candidate for a time of day. `zone` of `nil` means the device's zone, read
  when the plan is built rather than when the candidate is.
  """
  @spec wall_clock(String.t(), Budget.domain(), NaiveDateTime.t(), String.t() | nil, keyword()) ::
          t()
  def wall_clock(id, domain, %NaiveDateTime{} = wall, zone \\ nil, opts \\ [])
      when is_binary(zone) or is_nil(zone) do
    build(id, domain, {:wall_clock, wall, zone}, opts)
  end

  @doc """
  A candidate a gate has already refused, carrying the reason forward.

  The reason is the gate's own word — `:muted`, `:low_confidence`, `:no_date` —
  and reaches `Kati.Notifications.Plan` unchanged.
  """
  @spec suppressed(String.t(), Budget.domain(), atom(), keyword()) :: t()
  def suppressed(id, domain, reason, opts \\ []) when is_atom(reason) and not is_nil(reason) do
    id |> build(domain, nil, opts) |> Map.put(:suppressed, reason)
  end

  defp build(id, domain, at, opts) when is_binary(id) do
    if id == "" do
      raise ArgumentError, "a notification id must not be empty"
    end

    unless Budget.domain?(domain) do
      raise ArgumentError,
            "#{inspect(domain)} is not a budgeted domain. " <>
              "One of #{inspect(Budget.domains())} — see Kati.Notifications.Budget."
    end

    priority = Keyword.get(opts, :priority, :normal)

    unless is_map_key(@priorities, priority) do
      raise ArgumentError, "priority must be one of #{inspect(Map.keys(@priorities))}"
    end

    %__MODULE__{
      id: id,
      domain: domain,
      at: at,
      fire_at: fire_at(at),
      title: Keyword.get(opts, :title),
      body: Keyword.get(opts, :body),
      priority: priority,
      quiet_hours: Keyword.get(opts, :quiet_hours, :shift),
      members: Keyword.get(opts, :members, []),
      meta: Keyword.get(opts, :meta, %{})
    }
  end

  defp fire_at({:absolute, at}), do: at
  defp fire_at(_unresolved), do: nil

  @doc """
  Join id parts into a stable id: `id(["ep", :tmdb, "1396"])` → `"ep:tmdb:1396"`.

  Rejects a part containing `":"`, because an id that can be built two ways from
  two different identities is an id that can collide — and a collision here is
  one reminder silently replacing another.
  """
  @spec id([String.t() | atom() | integer() | Date.t()]) :: String.t()
  def id(parts) when is_list(parts) and parts != [] do
    Enum.map_join(parts, ":", &id_part/1)
  end

  defp id_part(%Date{} = date), do: Date.to_iso8601(date)
  defp id_part(part) when is_atom(part) and not is_nil(part), do: id_part(Atom.to_string(part))
  defp id_part(part) when is_integer(part), do: Integer.to_string(part)

  defp id_part(part) when is_binary(part) do
    if part == "" or String.contains?(part, ":") do
      raise ArgumentError, "#{inspect(part)} cannot be part of a notification id"
    end

    part
  end

  @doc """
  Fill in `fire_at` for a wall-clock candidate, in `zone` unless it named one.

  A wall clock that cannot be resolved at all becomes `:no_date` rather than an
  exception — an unknown zone is a bad row, not a reason to take the one screen
  process down with it.
  """
  @spec resolve(t(), String.t()) :: t()
  def resolve(%__MODULE__{suppressed: reason} = candidate, _zone) when not is_nil(reason) do
    candidate
  end

  def resolve(%__MODULE__{at: {:absolute, at}} = candidate, _zone) do
    %{candidate | fire_at: at}
  end

  def resolve(%__MODULE__{at: {:wall_clock, wall, wall_zone}} = candidate, zone) do
    case Kati.Time.to_utc(wall, wall_zone || zone) do
      {:ok, instant} -> %{candidate | fire_at: instant}
      {:error, _reason} -> suppress(candidate, :no_date)
    end
  end

  def resolve(%__MODULE__{at: nil} = candidate, _zone), do: suppress(candidate, :no_date)

  @doc """
  Mark a candidate refused, keeping everything else about it.

  Suppression is recorded on the candidate rather than reduced to a bare reason
  so that the plan can still say *which* reminder was dropped, at what time, for
  which domain. `meta` merges, so a `:digested` entry can record what it was
  folded into.
  """
  @spec suppress(t(), atom(), map()) :: t()
  def suppress(%__MODULE__{} = candidate, reason, meta \\ %{}) when is_atom(reason) do
    %{candidate | suppressed: reason, meta: Map.merge(candidate.meta, meta)}
  end

  @doc "Whether this candidate still wants a slot."
  @spec live?(t()) :: boolean()
  def live?(%__MODULE__{suppressed: nil, fire_at: %DateTime{}}), do: true
  def live?(%__MODULE__{}), do: false

  @doc """
  The sort key the budget sheds by: soonest first, then priority, then id.

  Time comes first and priority cannot override it. #59 is explicit that an
  over-budget domain *"sheds its furthest-future entries first, never its
  soonest"* — so a `:high` reminder six months out still loses to a `:low` one
  tomorrow, and a user never loses the reminder they are about to need. The id
  is the final tie-break, so an identical pair of times always shed in the same
  order rather than in whatever order the rows came back.
  """
  @spec order_key(t()) :: {integer(), non_neg_integer(), String.t()}
  def order_key(%__MODULE__{fire_at: %DateTime{} = at} = candidate) do
    {DateTime.to_unix(at, :microsecond), Map.fetch!(@priorities, candidate.priority),
     candidate.id}
  end

  @doc "Priority as a number, where 0 is most urgent."
  @spec rank(priority()) :: non_neg_integer()
  def rank(priority), do: Map.fetch!(@priorities, priority)

  @doc """
  A hash of everything the platform was told, so re-arming can be skipped.

  Reconciliation compares this against what is already armed. Time, text and
  digest membership are in it; nothing else is, because nothing else reaches the
  platform. Two candidates with the same id and the same fingerprint are the
  same armed alarm, and re-arming one is a no-op worth avoiding rather than a
  correctness problem — `MobNotify.schedule/2` upserts.
  """
  @spec fingerprint(t()) :: non_neg_integer()
  def fingerprint(%__MODULE__{} = candidate) do
    :erlang.phash2({
      candidate.id,
      candidate.fire_at && DateTime.to_unix(candidate.fire_at, :microsecond),
      candidate.title,
      candidate.body,
      Enum.sort(candidate.members)
    })
  end
end
