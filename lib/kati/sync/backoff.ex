defmodule Kati.Sync.Backoff do
  @moduledoc """
  When to try again, and — more importantly — when to stop.

  The delay is Google's published formula:
  `min(((2^n) + random_number_milliseconds), maximum_backoff)`, with
  *"randomization of up to 1,000 milliseconds"* and a `maximum_backoff` of
  *"typically 32 or 64 seconds"*. The jitter is not decoration: without it every
  device that failed in the same minute retries in the same millisecond, which
  is how a transient outage becomes a sustained one.

  ## Not every failure is a retry

  This is the half that prevents data loss in the other direction. A silent
  infinite retry loop on a malformed event is worse than an error card, because
  nothing ever tells the user that the change they made in March is still not
  on their calendar.

      :read_only      → :quarantine   the transport cannot write, and never will
      401             → :reauth       stop, and ask for credentials
      403 (quota)     → :hard_backoff wait much longer, do not hammer
      400, 422        → :quarantine   surface it; never retry forever
      409, 412 create → :already_landed  the idempotency key did its job
      412 update      → :conflict     the remote moved; merge, do not retry blind
      404 delete      → :already_gone  the thing we wanted gone is gone
      404 update      → :conflict     the remote deleted it under our edit
      5xx, timeouts   → :retry
      after N tries   → :quarantine

  `:already_landed` is the one that matters most and reads oddly: a retry that
  comes back `409` or `412` is a **success**. No transport Kati speaks offers
  an idempotency key, so `Kati.Sync.Outbox` constructs one — a client-generated
  `UID` plus `If-None-Match: *` on CalDAV, a client-supplied `id` on Google —
  and the whole point of constructing it is that the ambiguous timeout ("did it
  land, or did the response die?") gets a definite answer on the next attempt.
  Treating that answer as a failure is how one network hiccup becomes two
  identical events.
  """

  @typedoc "What the engine should do about one failed attempt."
  @type verdict ::
          :retry
          | :hard_backoff
          | :reauth
          | :quarantine
          | :conflict
          | :already_landed
          | :already_gone

  @default_cap_ms 32_000
  @jitter_ms 1_000
  # A 403 quota is not a transient failure; retrying it inside the same minute
  # is what earns the next 403.
  @hard_backoff_ms 15 * 60 * 1_000
  @max_attempts 8

  @doc "How many attempts before an entry is quarantined regardless of verdict."
  @spec max_attempts() :: pos_integer()
  def max_attempts, do: @max_attempts

  @doc """
  The delay before attempt `n + 1`, in milliseconds.

  `n` is the number of attempts already made, so the first retry waits ~1 s.
  `:jitter` is injectable purely so the tests can assert the formula rather
  than assert a range and call it proven.
  """
  @spec delay_ms(non_neg_integer(), keyword()) :: pos_integer()
  def delay_ms(attempts, opts \\ []) when is_integer(attempts) and attempts >= 0 do
    cap = Keyword.get(opts, :cap_ms, @default_cap_ms)
    jitter = Keyword.get_lazy(opts, :jitter, fn -> :rand.uniform(@jitter_ms + 1) - 1 end)

    # 2^n seconds, in milliseconds, before the cap. Bounded exponent so a
    # quarantine-worthy attempt count cannot overflow into a nonsense integer.
    base = Bitwise.bsl(1, min(attempts, 20)) * 1_000

    min(base + jitter, cap)
  end

  @doc """
  The delay for a verdict, which is not always the exponential one.

  `:hard_backoff` deliberately leaves the exponential curve: a quota is a
  statement about the next hour, not the next four seconds.
  """
  @spec delay_for(verdict(), non_neg_integer(), keyword()) :: pos_integer()
  def delay_for(:hard_backoff, _attempts, opts) do
    Keyword.get(opts, :hard_backoff_ms, @hard_backoff_ms)
  end

  def delay_for(_verdict, attempts, opts), do: delay_ms(attempts, opts)

  @doc """
  What a transport error means, given which operation produced it.

  The operation matters: a `404` on a delete is success and a `404` on an
  update is a conflict, and a `412` on a create is success while a `412` on an
  update is a conflict. Collapsing them into one table is how a delete that
  already happened turns into a permanent error card.
  """
  @spec classify(term(), :create | :update | :delete) :: verdict()
  def classify({:http, 401}, _op), do: :reauth
  def classify({:http, 401, _detail}, _op), do: :reauth

  def classify({:http, 403, detail}, _op) do
    if quota?(detail), do: :hard_backoff, else: :quarantine
  end

  def classify({:http, 403}, _op), do: :quarantine

  def classify({:http, status}, _op) when status in [400, 422], do: :quarantine
  def classify({:http, status, _detail}, _op) when status in [400, 422], do: :quarantine

  def classify({:http, status}, :create) when status in [409, 412], do: :already_landed

  def classify({:http, status}, op) when status in [409, 412] and op in [:update, :delete],
    do: :conflict

  def classify({:http, 404}, :delete), do: :already_gone
  def classify({:http, 404}, :create), do: :quarantine
  def classify({:http, 404}, :update), do: :conflict

  def classify({:http, status}, _op) when status >= 500 and status < 600, do: :retry
  def classify({:http, _status}, _op), do: :quarantine

  def classify(reason, _op)
      when reason in [:timeout, :closed, :econnrefused, :enetunreach, :nxdomain, :offline],
      do: :retry

  # A transport saying it cannot write is not a transient failure. Retrying a
  # permission Kati never requested would loop until the phone dies.
  def classify(reason, _op) when reason in [:read_only, :no_transport, :unsupported],
    do: :quarantine

  def classify({:error, reason}, op), do: classify(reason, op)
  # An unrecognised failure is retried a bounded number of times and then
  # quarantined by `max_attempts/0` — never retried forever, never discarded
  # on the first sight of something new.
  def classify(_reason, _op), do: :retry

  @doc """
  Whether an entry has run out of attempts.

  The cap applies to every verdict except the ones that are not really
  failures, which is why `classify/2` runs first.
  """
  @spec exhausted?(non_neg_integer()) :: boolean()
  def exhausted?(attempts), do: attempts >= @max_attempts

  defp quota?(detail) when is_binary(detail) do
    text = String.downcase(detail)
    String.contains?(text, "quota") or String.contains?(text, "rate limit")
  end

  defp quota?(detail) when is_atom(detail), do: detail in [:quota, :rate_limit, :rate_limited]
  defp quota?(%{reason: reason}), do: quota?(reason)
  defp quota?(_detail), do: false
end
