defmodule Kati.Media.Release do
  @moduledoc """
  When a title is next out, and whether Kati may set an alarm for it (#74).

  This is the one place that decides what beats what. Two rules, in order:

    1. **`user_override_date` wins over every source.** A date the user typed by
       hand is the most authoritative thing Kati has. It beats an `:exact`
       provider timestamp, and because it lives on the durable
       `Kati.Media.TrackedTitle` it still wins when the cache row it corrects has
       been evicted entirely.
    2. Otherwise the cached `next_release_at`, **read through its
       `date_confidence`**.

  ## The 1 January rule

  Providers answer a question they were not asked. "2026" comes back as
  `2026-01-01T00:00:00Z`; "Q3 2026" comes back as `2026-07-01`. Those are not
  dates, they are the earliest instant consistent with a period, and an app that
  arms a notification on one tells the user a film is out today when it is out
  in nine months. A release tracker that is confidently wrong about a release is
  worse than one that says nothing.

  So a low-confidence date **never becomes a day here**. `resolve/2` returns a
  *period* for anything coarser than a day — `{:year, 2026}`, `{:quarter, 2026,
  3}` — with no day component in the value at all. There is nothing for a caller
  to arm on even if it tries, which is stronger than documenting that it must
  not.

      {:exact, ~U[2026-10-03 19:00:00Z], :cache}   # may arm
      {:day, ~D[2026-10-03], :user_override}       # may arm, at a chosen hour
      {:approximate, {:quarter, 2026, 3}, :cache}  # display only, never arms
      :unknown                                     # nothing to say

  `:unknown` confidence degrades to a year rather than being trusted. It is
  `CachedTitle`'s *default*, so anything that armed on it would arm on every row
  a source never annotated — which is most of them.

  ## Arming

  `alarm_at/3` is the only function that produces an instant to schedule, and it
  is the same gate for both reasons a title stays silent:

      {:ok, ~U[2026-10-03 08:00:00Z]}
      {:suppressed, :low_confidence}   # coarser than a day
      {:suppressed, :muted}            # screen 35's per-show switch is off
      {:suppressed, :no_date}          # nothing known at all

  A caller that pattern-matches `{:ok, at}` cannot accidentally honour one rule
  and forget the other.

  A `:day` result has no hour, so `alarm_at/3` supplies one — 09:00 in the
  device's zone by default, resolved through `Kati.Time` so a date whose 09:00
  falls in a DST gap still produces an instant instead of vanishing once a year.

  ## Three things have dates, and there is one rule

  A title's next release is `resolve/2`. A season drop and an episode airing are
  `air/1`, and they arm through `alarm_for/3`. All three read their stored
  instant through the same `resolve_at/3` and arm through the same gate, so the
  1 January rule cannot hold for a film and lapse for an episode.

  What `air/1` deliberately does **not** do is apply rule 1. A
  `user_override_date` is the user correcting *when this title is next out*; it
  is not a claim about season 1 episode 3, which aired two years ago. Letting it
  win there would rewrite the history of every episode of a title the moment the
  user fixed one date, so the override stays where it belongs — on the title's
  own resolution — and `air/1` is `:cache` in every answer.
  """

  require Ash.Query

  alias Kati.Media.CachedEpisode
  alias Kati.Media.CachedSeason
  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle

  @typedoc "Which of the two authorities produced the answer."
  @type origin :: :user_override | :cache

  @typedoc "A span of time with no day in it. Displayable, never armable."
  @type period ::
          {:month, integer(), 1..12}
          | {:quarter, integer(), 1..4}
          | {:year, integer()}

  @type resolution ::
          {:exact, DateTime.t(), origin()}
          | {:day, Date.t(), origin()}
          | {:approximate, period(), origin()}
          | :unknown

  @type suppression :: :low_confidence | :muted | :no_date

  # 09:00 local. Early enough to be that morning's news, late enough not to be
  # the thing that wakes someone up.
  @default_alarm_time ~T[09:00:00]

  @doc """
  When this title is next out, and how precisely that is known.

  The user's own date first, then the cache read through its confidence. See the
  moduledoc for the shape of each answer and why the coarse ones carry no day.

  `cached` may be `nil` — that is the evicted case, and an override still
  resolves through it.
  """
  @spec resolve(TrackedTitle.t(), CachedTitle.t() | nil) :: resolution()
  def resolve(tracked, cached)

  # Rule 1. Nothing below this clause can outrank a date the user typed.
  def resolve(%TrackedTitle{user_override_date: %Date{} = date}, _cached) do
    {:day, date, :user_override}
  end

  def resolve(%TrackedTitle{}, nil), do: :unknown
  def resolve(%TrackedTitle{}, %CachedTitle{next_release_at: nil}), do: :unknown

  def resolve(%TrackedTitle{}, %CachedTitle{next_release_at: %DateTime{} = at} = cached) do
    resolve_at(at, cached.date_confidence, :cache)
  end

  @doc """
  A stored instant read through the confidence the source gave it.

  The single place a `date_confidence` becomes an answer, and the reason a
  title, a season and an episode cannot drift apart: `resolve/2` and `air/1`
  both end here, so the 1 January rule is written once.

  A coarse confidence produces a *period* with no day component in the value at
  all — see the moduledoc. `:unknown`, and anything a later migration adds to
  the ladder without classifying it, degrade to a year rather than arming.
  """
  @spec resolve_at(DateTime.t() | nil, atom(), origin()) :: resolution()
  def resolve_at(nil, _confidence, _origin), do: :unknown

  def resolve_at(%DateTime{} = at, confidence, origin) do
    case confidence do
      :exact -> {:exact, at, origin}
      :day -> {:day, DateTime.to_date(at), origin}
      :month -> {:approximate, {:month, at.year, at.month}, origin}
      :quarter -> {:approximate, {:quarter, at.year, quarter(at.month)}, origin}
      :year -> {:approximate, {:year, at.year}, origin}
      # :unknown, and anything a later migration adds. Degrading is the safe
      # default; arming is not.
      _coarse -> {:approximate, {:year, at.year}, origin}
    end
  end

  @doc """
  When a season lands or an episode airs, and how precisely that is known.

  The cached instant read through its own confidence, and nothing else — see
  the moduledoc for why the user's override does not reach in here.

  Every answer's origin is `:cache`, because a season and an episode have no
  other authority. The shapes are `resolve/2`'s, so a caller that already knows
  how to draw a title's date knows how to draw these.
  """
  @spec air(CachedEpisode.t() | CachedSeason.t()) :: resolution()
  def air(%CachedEpisode{air_at: at, date_confidence: confidence}) do
    resolve_at(at, confidence, :cache)
  end

  def air(%CachedSeason{air_at: at, date_confidence: confidence}) do
    resolve_at(at, confidence, :cache)
  end

  @doc """
  The instant to schedule a notification for, or why there is none.

  Arms only for `:exact` and `:day`. Everything coarser is `:low_confidence`,
  and a show whose `notify_new_episodes` switch is off is `:muted` before the
  date is even looked at.

  Options:

    * `:at` — the local time of day a `:day` result fires at. Defaults to 09:00.
    * `:zone` — IANA zone for that hour. Defaults to `Kati.Time.device_zone/0`.
  """
  @spec alarm_at(TrackedTitle.t(), CachedTitle.t() | nil, keyword()) ::
          {:ok, DateTime.t()} | {:suppressed, suppression()}
  def alarm_at(tracked, cached, opts \\ [])

  def alarm_at(%TrackedTitle{notify_new_episodes: false}, _cached, _opts) do
    {:suppressed, :muted}
  end

  def alarm_at(%TrackedTitle{} = tracked, cached, opts) do
    tracked |> resolve(cached) |> arm(opts)
  end

  @doc """
  The instant to schedule for a season drop or an episode airing, or why there
  is none.

  The same gate as `alarm_at/3`, applied to `air/1` instead of `resolve/2`: the
  show's `notify_new_episodes` switch is read first, then the confidence. An
  episode a source described as "airing Thursday" that is really a bare year is
  `:low_confidence` here exactly as a film would be, which is the whole reason
  this function exists rather than each caller comparing dates for itself.

  `opts` are `alarm_at/3`'s — `:at` for the local hour a day-precision airing
  fires at, `:zone` for the zone that hour is in.
  """
  @spec alarm_for(TrackedTitle.t(), CachedEpisode.t() | CachedSeason.t(), keyword()) ::
          {:ok, DateTime.t()} | {:suppressed, suppression()}
  def alarm_for(tracked, airing, opts \\ [])

  def alarm_for(%TrackedTitle{notify_new_episodes: false}, _airing, _opts) do
    {:suppressed, :muted}
  end

  def alarm_for(%TrackedTitle{}, airing, opts), do: airing |> air() |> arm(opts)

  # The one gate. Both alarm functions end here, so a caller cannot honour the
  # mute rule and forget the confidence rule, or the other way round.
  defp arm({:exact, at, _origin}, _opts), do: {:ok, at}
  defp arm({:day, date, _origin}, opts), do: arm_on(date, opts)
  defp arm({:approximate, _period, _origin}, _opts), do: {:suppressed, :low_confidence}
  defp arm(:unknown, _opts), do: {:suppressed, :no_date}

  @doc """
  True when a resolution is precise enough to schedule anything from.

  The same test `alarm_at/3` applies, exposed for callers that want to decide
  how to *draw* a row rather than whether to notify — screen 05's "coming up"
  list can show a period, but it cannot show a countdown to one.
  """
  @spec armable?(resolution()) :: boolean()
  def armable?({tag, _value, _origin}) when tag in [:exact, :day], do: true
  def armable?(_resolution), do: false

  @typedoc """
  Whether a dated thing has happened yet.

  `:unknown` is a first-class answer rather than a defaulted `false`. Screen 04
  draws three episode states and the third — *aired, not watched* — is an
  affordance: a tick the user can press. Guessing `:aired` invites a tick for
  something nobody has seen; guessing `:upcoming` hides the tick for something
  that went out last night. Neither is worth pretending to know.
  """
  @type airing :: :aired | :upcoming | :unknown

  @doc """
  Whether an airing is behind `now`, ahead of it, or not knowable.

  Applied to a resolution rather than to a raw column, so it inherits the 1
  January rule instead of re-deciding it. The three coarse cases are answered by
  the **period's own bounds**, never by turning the period into a day:
  `{:year, 2019}` is entirely behind 2026 and is `:aired`; `{:year, 2030}` is
  entirely ahead and is `:upcoming`; `{:year, 2026}` contains today and is
  `:unknown`. That is an entailment, not a guess — there is no instant in 2019
  that is not already past.

  A `:day` result on today itself is `:unknown` for the same reason in
  miniature: day precision is precisely not knowing the hour, and an episode
  that airs at 20:00 has not aired at 09:00.

      airing({:exact, ~U[2026-08-06 19:00:00Z], :cache}, now)  #=> :aired
      airing({:approximate, {:year, 2026}, :cache}, now)       #=> :unknown
      airing(:unknown, now)                                     #=> :unknown
  """
  @spec airing(resolution(), DateTime.t()) :: airing()
  def airing({:exact, at, _origin}, %DateTime{} = now) do
    if DateTime.compare(at, now) == :gt, do: :upcoming, else: :aired
  end

  def airing({:day, date, _origin}, %DateTime{} = now) do
    case Date.compare(date, DateTime.to_date(now)) do
      :lt -> :aired
      :eq -> :unknown
      :gt -> :upcoming
    end
  end

  def airing({:approximate, period, _origin}, %DateTime{} = now) do
    today = DateTime.to_date(now)

    cond do
      Date.compare(period_ends(period), today) == :lt -> :aired
      Date.compare(period_begins(period), today) == :gt -> :upcoming
      true -> :unknown
    end
  end

  def airing(:unknown, %DateTime{}), do: :unknown

  # The first and last day a period can mean. Used only to ask whether the whole
  # of it is on one side of today — never handed back, never armed on.
  defp period_begins({:year, year}), do: Date.new!(year, 1, 1)
  defp period_begins({:quarter, year, q}), do: Date.new!(year, (q - 1) * 3 + 1, 1)
  defp period_begins({:month, year, month}), do: Date.new!(year, month, 1)

  defp period_ends({:year, year}), do: Date.new!(year, 12, 31)
  defp period_ends({:quarter, year, q}), do: last_day(year, q * 3)
  defp period_ends({:month, year, month}), do: last_day(year, month)

  defp last_day(year, month) do
    first = Date.new!(year, month, 1)
    Date.new!(year, month, Date.days_in_month(first))
  end

  @doc """
  `resolve/2` for a tracked title, fetching its cache row by `{source,
  source_id}`.

  A miss is `nil` rather than an error: an evicted or never-fetched title is an
  ordinary state, and the override path still answers through it.
  """
  @spec for_tracked(TrackedTitle.t()) :: resolution()
  def for_tracked(%TrackedTitle{} = tracked) do
    resolve(tracked, cached_for(tracked))
  end

  @doc """
  The cache row a tracked title points at, or `nil`.

  The reference is a value pair, not a foreign key — see
  `Kati.Media.TrackedTitle` — so this is the lookup that stands in for the join
  Kati deliberately does not have.
  """
  @spec cached_for(TrackedTitle.t()) :: CachedTitle.t() | nil
  def cached_for(%TrackedTitle{source: source, source_id: source_id}) do
    CachedTitle
    |> Ash.Query.filter(source == ^source and source_id == ^source_id)
    |> Ash.read_one!()
  end

  defp arm_on(%Date{} = date, opts) do
    time = Keyword.get(opts, :at, @default_alarm_time)
    zone = Keyword.get(opts, :zone) || Kati.Time.device_zone()

    case Kati.Time.to_utc(NaiveDateTime.new!(date, time), zone) do
      {:ok, instant} -> {:ok, instant}
      {:error, _reason} -> {:suppressed, :no_date}
    end
  end

  defp quarter(month) when month in 1..12, do: div(month - 1, 3) + 1
end
