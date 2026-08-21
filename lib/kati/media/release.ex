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
  """

  require Ash.Query

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
    case cached.date_confidence do
      :exact -> {:exact, at, :cache}
      :day -> {:day, DateTime.to_date(at), :cache}
      :month -> {:approximate, {:month, at.year, at.month}, :cache}
      :quarter -> {:approximate, {:quarter, at.year, quarter(at.month)}, :cache}
      :year -> {:approximate, {:year, at.year}, :cache}
      # :unknown, and anything a later migration adds. Degrading is the safe
      # default; arming is not.
      _coarse -> {:approximate, {:year, at.year}, :cache}
    end
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
    case resolve(tracked, cached) do
      {:exact, at, _origin} -> {:ok, at}
      {:day, date, _origin} -> arm_on(date, opts)
      {:approximate, _period, _origin} -> {:suppressed, :low_confidence}
      :unknown -> {:suppressed, :no_date}
    end
  end

  @doc """
  True when a resolution is precise enough to schedule anything from.

  The same test `alarm_at/3` applies, exposed for callers that want to decide
  how to *draw* a row rather than whether to notify — screen 05's "coming up"
  list can show a period, but it cannot show a countdown to one.
  """
  @spec armable?(resolution()) :: boolean()
  def armable?({tag, _value, _origin}) when tag in [:exact, :day], do: true
  def armable?(_resolution), do: false

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
