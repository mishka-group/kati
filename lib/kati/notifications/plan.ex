defmodule Kati.Notifications.Plan do
  @moduledoc """
  The answer: what should be armed, what was refused, and why.

  Every candidate handed to `Kati.Notifications.Scheduler` comes out in exactly
  one of the two lists. Nothing is dropped on the floor, and that is deliberate:
  the debug surfaces #59 asks for — `pending_count / 64` with a per-domain
  breakdown, and the *"why am I not getting notifications?"* screen — are both
  just readings of a plan. A budget whose losers cannot be enumerated is a
  priority rule nobody can inspect.

  ## The reasons, and who produced them

  | Reason             | Produced by |
  |--------------------|-------------|
  | `:muted`           | `Kati.Media.Release.alarm_at/3` — the per-show switch on screen 35 |
  | `:low_confidence`  | the same gate — a date coarser than a day (#74's 1 January rule) |
  | `:no_date`         | the same gate, or a wall clock that no zone could resolve |
  | `:past`            | the entry's instant is behind `now` |
  | `:duplicate`       | a second candidate claiming an id already taken |
  | `:over_budget`     | `Kati.Notifications.Budget` — its domain was full |
  | `:digested`        | `Kati.Notifications.Digest` — folded into `meta.into` |

  The first three arrive already decided, from whichever gate owns the rule, and
  are carried rather than re-derived. There is one release gate in Kati and this
  is not a second one.
  """

  alias Kati.Notifications.Budget
  alias Kati.Notifications.Candidate

  @type t :: %__MODULE__{
          armed: [Candidate.t()],
          suppressed: [Candidate.t()],
          platform: Budget.platform(),
          now: DateTime.t(),
          zone: String.t()
        }

  defstruct armed: [], suppressed: [], platform: nil, now: nil, zone: nil

  @doc "What would actually be armed, soonest first."
  @spec armed_ids(t()) :: [String.t()]
  def armed_ids(%__MODULE__{armed: armed}), do: Enum.map(armed, & &1.id)

  @doc """
  How many pending notifications the plan holds — the numerator of
  `pending_count / 64`.
  """
  @spec pending_count(t()) :: non_neg_integer()
  def pending_count(%__MODULE__{armed: armed}), do: length(armed)

  @doc """
  Armed entries per domain, zero included.

  Zero included on purpose: a domain missing from a map reads as "no answer",
  and the breakdown screen exists precisely to answer "why is nothing arriving
  for my habits?".
  """
  @spec counts(t()) :: %{Budget.domain() => non_neg_integer()}
  def counts(%__MODULE__{armed: armed}) do
    tally = Enum.frequencies_by(armed, & &1.domain)
    Map.new(Budget.domains(), fn domain -> {domain, Map.get(tally, domain, 0)} end)
  end

  @doc """
  The debug breakdown: `%{domain => {armed, limit}}` for this plan's platform.

  This is the whole of Step 7's first surface. *"You will regret not having
  it."*
  """
  @spec usage(t()) :: %{Budget.domain() => {non_neg_integer(), pos_integer()}}
  def usage(%__MODULE__{platform: platform} = plan) do
    counts = counts(plan)

    Map.new(Budget.domains(), fn domain ->
      {domain, {counts[domain], Budget.limit(platform, domain)}}
    end)
  end

  @doc "Every candidate refused for this reason."
  @spec suppressed(t(), atom()) :: [Candidate.t()]
  def suppressed(%__MODULE__{suppressed: suppressed}, reason) do
    Enum.filter(suppressed, &(&1.suppressed == reason))
  end

  @doc "Why this id is not being armed, or `nil` if it is."
  @spec reason(t(), String.t()) :: atom() | nil
  def reason(%__MODULE__{suppressed: suppressed}, id) do
    Enum.find_value(suppressed, fn candidate -> candidate.id == id and candidate.suppressed end)
  end

  @doc "How many candidates were refused for each reason."
  @spec reasons(t()) :: %{atom() => non_neg_integer()}
  def reasons(%__MODULE__{suppressed: suppressed}) do
    Enum.frequencies_by(suppressed, & &1.suppressed)
  end

  @doc "The armed entry with this id, or `nil`."
  @spec find(t(), String.t()) :: Candidate.t() | nil
  def find(%__MODULE__{armed: armed}, id), do: Enum.find(armed, &(&1.id == id))
end
