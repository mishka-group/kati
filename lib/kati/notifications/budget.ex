defmodule Kati.Notifications.Budget do
  @moduledoc """
  The allocation table: how many pending notifications each domain may hold.

  Kati arms alarms from six places — the calendar, air dates, habits, meals,
  health prompts and money renewals — and both platforms cap the *app*, not the
  feature. So the cap has to be divided up somewhere, and this is the one place
  it is divided. A domain that wants a slot asks here; nothing schedules outside
  the table.

  ## The two cliffs, and their opposite failure modes

    * **Android throws.** `AlarmManager` allows **500 concurrent alarms per
      UID** on API 31+; the 501st raises
      `IllegalStateException: "Maximum limit of concurrent alarms 500 reached
      for uid"` (https://github.com/invertase/notifee/issues/349). Kati has one
      screen process, so an uncaught throw in `handle_event/3` is a visible app
      crash rather than a missing reminder.

    * **iOS discards, silently.** The system *"keeps the soonest-firing 64
      notifications … and discards the rest"*. The current `UserNotifications`
      documentation does not restate the number anywhere; the authoritative
      sentence survives only in the deprecated `UILocalNotification` reference
      (https://developer.apple.com/documentation/uikit/uilocalnotification).
      Nothing raises, nothing logs — the 65th reminder simply never arrives and
      the user reports that notifications are unreliable.

  Because the iOS failure is silent, the iOS column is the one that must be
  deliberately conservative. It sums to **50 of 64**: fourteen slots of headroom
  against a cliff that gives no warning. The Android column sums to **480 of
  500**, twenty alarms of headroom against a cliff that throws.

  ## The table

  | Domain     | Android | iOS |
  |------------|---------|-----|
  | `:calendar`| 150     | 16  |
  | `:tv`      | 120     | 12  |
  | `:habits`  | 80      | 8   |
  | `:meals`   | 60      | 6   |
  | `:health`  | 40      | 4   |
  | `:money`   | 30      | 4   |
  | **total**  | **480** | **50** |

  The Android TV row is the research's stated policy — *"at most the next 2
  episodes per followed show, and at most 120 TV alarms total"* — which leaves a
  user following forty shows their eighty alarms with headroom, and still leaves
  TV *"a slice, not the whole 500"*.

  `:tv` is the whole media slice, not television alone: films, books and records
  come from the same watcher and the same gate (`Kati.Media.Release.alarm_at/3`),
  so they draw from the same row rather than getting an unbudgeted one.

  ## Slots are not redistributed

  An empty calendar does not lend its 150 alarms to television. The table is a
  ceiling per domain, checked independently, because the alternative — a
  first-come allocation — makes the set that gets shed depend on the order the
  domains happened to be collected in, and a shed set nobody can predict is not
  a budget. `Kati.Notifications.Scheduler` sheds a domain's **furthest-future**
  entries first, never its soonest, so the reminder a user is about to need is
  the last thing to go.

  The sums are checked at compile time. A change to one row that breaks a cliff
  fails the build rather than a phone.
  """

  @domains [:calendar, :tv, :habits, :meals, :health, :money]

  @caps %{android: 500, ios: 64}

  @table %{
    calendar: %{android: 150, ios: 16},
    tv: %{android: 120, ios: 12},
    habits: %{android: 80, ios: 8},
    meals: %{android: 60, ios: 6},
    health: %{android: 40, ios: 4},
    money: %{android: 30, ios: 4}
  }

  # The totals the moduledoc and #59 both commit to. Stated rather than derived
  # so that a row edited by hand has to admit what it did to the total.
  @totals %{android: 480, ios: 50}

  for {platform, cap} <- @caps do
    summed = Enum.reduce(@domains, 0, fn domain, acc -> acc + @table[domain][platform] end)
    declared = @totals[platform]

    cond do
      summed != declared ->
        raise "Kati.Notifications.Budget: the #{platform} column sums to #{summed}, " <>
                "but the table declares #{declared}. Update both, and the moduledoc."

      summed >= cap ->
        raise "Kati.Notifications.Budget: the #{platform} column sums to #{summed}, " <>
                "which leaves no headroom under the #{cap} cap."

      true ->
        :ok
    end
  end

  @type platform :: :android | :ios
  @type domain :: :calendar | :tv | :habits | :meals | :health | :money

  @doc """
  The six domains that may schedule anything, in the table's own order.

  `Kati.Notifications.Candidate` validates against this list, so a typo'd domain
  fails where it is written rather than being silently dropped at plan time.
  """
  @spec domains() :: [domain()]
  def domains, do: @domains

  @doc "Whether this atom names a domain the table budgets for."
  @spec domain?(term()) :: boolean()
  def domain?(domain), do: domain in @domains

  @doc "The platforms with an allocation column."
  @spec platforms() :: [platform()]
  def platforms, do: Map.keys(@caps) |> Enum.sort()

  @doc """
  How many pending notifications this domain may hold on this platform.

  Raises for an unknown domain: there is no default allocation, because a domain
  with an implicit slot budget is a domain that can overrun the cliff without
  anyone having decided it could.
  """
  @spec limit(platform(), domain()) :: pos_integer()
  def limit(platform, domain) do
    case @table do
      %{^domain => %{^platform => limit}} ->
        limit

      _ ->
        raise ArgumentError,
              "no allocation for #{inspect(domain)} on #{inspect(platform)}. " <>
                "Domains: #{inspect(@domains)}, platforms: #{inspect(Map.keys(@caps))}."
    end
  end

  @doc "One platform's whole column, as `%{domain => limit}`."
  @spec table(platform()) :: %{domain() => pos_integer()}
  def table(platform) do
    Map.new(@domains, fn domain -> {domain, limit(platform, domain)} end)
  end

  @doc """
  The platform's own cap — 500 alarms per UID on Android, 64 pending on iOS.

  This is the number Kati must stay under, not the number it aims for. See
  `total/1` for what the table actually allocates and `headroom/1` for the gap
  that is deliberately left between them.
  """
  @spec cap(platform()) :: pos_integer()
  def cap(platform) do
    Map.fetch!(@caps, platform)
  end

  @doc "Everything the table allocates on this platform: 480 on Android, 50 on iOS."
  @spec total(platform()) :: pos_integer()
  def total(platform), do: Map.fetch!(@totals, platform)

  @doc "Slots left unallocated under the cap: 20 on Android, 14 on iOS."
  @spec headroom(platform()) :: pos_integer()
  def headroom(platform), do: cap(platform) - total(platform)
end
