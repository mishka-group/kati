defmodule Kati.Subscriptions do
  @moduledoc """
  What the reader pays for every month, and whether they are using it.

  Screen 23's ledger, read rather than quoted. MOVIES-AND-TV.md #66: that
  page drew Lumen+, Orbit, Kino and Aria Free at £46.47 a month on every
  device, and its only route in is screen 92's Money row — so a reader who
  had told Kati about one service, at a price they typed, was shown four they
  had not and a total that was none of their money.

  ## Hours, without asking anybody to log them

  The drawing's rows carry `41h watched` and `£0.21/h`, and the obvious source
  is `Kati.Media.Watch.service` — where you watched it. Nothing writes that
  column: no screen in the app offers a picker for it, and asking somebody to
  name a service every time they tick an episode would be a worse app.

  So the hours are derived from what Kati already knows. A title is on the
  services `Kati.Media.CachedTitle.providers` says it is on, in the reader's
  country; a watch of that title is an hour spent on one of them.

  **One service per watch, never two.** A film on both Netflix and Now would
  otherwise put its two hours on each and make both look better value than
  they are. The subscribed provider that comes first alphabetically takes it —
  arbitrary, and stated as arbitrary, because any rule here is: what matters
  is that the same hour is counted once.

  A watch of a title with no providers is counted in nobody's hours. It is not
  evidence about any service, and quietly attributing it to the cheapest one
  would be inventing the number this module exists to stop inventing.

  ## What is not here, and will not be until something records it

  The board's `Up £4.00 since March — Orbit raised its price` needs a price
  history and Kati keeps none: a service row holds one price, the one in it
  now. So the change line is absent rather than guessed — `nil`, which
  `Kati.Screens.Subscriptions.change_line/1` draws as nothing at all.
  """

  require Ash.Query

  use Gettext, backend: Kati.Gettext

  alias Kati.Media.Availability
  alias Kati.Media.CachedTitle
  alias Kati.Media.Watch
  alias Kati.Services.Service

  # Below this, a service is not being used enough to be worth its price, and
  # the card says so. Two hours a month is one film: a subscription nobody has
  # opened twice is the case this page exists to notice.
  @quiet_hours 2

  @doc """
  The reader's own ledger, or `nil` when they have told Kati about nothing.

  `nil` is what screen 23 reads as *draw the drawing* — the same all-or-nothing
  gate screens 04 and 92 apply, and for the same reason: a page half the
  reader's and half the board's reads as entirely real.
  """
  @spec ledger() :: map() | nil
  def ledger do
    case subscribed() do
      [] ->
        nil

      services ->
        hours = hours_by_service()

        rows = Enum.map(services, &row(&1, Map.get(hours, fold(&1.name), 0)))

        %{
          active_line: active_line(services),
          monthly: %{
            label: "Every month",
            total: Service.total(services) || "—",
            change_lead: nil,
            change_amount: nil,
            change_rest: nil
          },
          services: rows,
          suggestion: suggestion(rows)
        }
    end
  rescue
    _error -> nil
  end

  @doc """
  `5 active`, `1 active` — the count of what is being paid for.

      iex> Kati.Subscriptions.active_line([%{}])
      "1 active"

      iex> Kati.Subscriptions.active_line([%{}, %{}])
      "2 active"
  """
  @spec active_line([term()]) :: String.t()
  def active_line(services), do: "#{length(services)} active"

  @doc """
  Minutes watched, by service name folded for comparison.

  One pass over the reader's watches, one over the titles they name, and one
  provider lookup each — see the moduledoc for why a watch lands on exactly
  one service.
  """
  @spec hours_by_service() :: %{String.t() => non_neg_integer()}
  def hours_by_service do
    reader = Kati.Services.availability()
    mine = MapSet.new(reader.subscribed, &fold/1)
    watches = Ash.read!(Watch)
    titles = titles_for(watches)
    runtimes = episode_runtimes(watches)

    Enum.reduce(watches, %{}, fn watch, acc ->
      with %CachedTitle{} = cached <- Map.get(titles, watch.tracked_title_id),
           name when is_binary(name) <- billed_to(cached, reader.region, mine),
           minutes when is_integer(minutes) and minutes > 0 <- minutes(watch, cached, runtimes) do
        Map.update(acc, fold(name), minutes, &(&1 + minutes))
      else
        _not_attributable -> acc
      end
    end)
  rescue
    _error -> %{}
  end

  @doc """
  Which service an hour of this title belongs to, or `nil`.

  The first subscribed provider in alphabetical order — arbitrary, and the
  moduledoc says why arbitrary is the right kind of answer here.

      iex> providers = %{"GB" => %{"flatrate" => ["Now", "Netflix"]}}
      iex> Kati.Subscriptions.billed_to(providers, "GB", MapSet.new(["netflix", "now"]))
      "Netflix"

      iex> providers = %{"GB" => %{"flatrate" => ["Apple TV"]}}
      iex> Kati.Subscriptions.billed_to(providers, "GB", MapSet.new(["netflix"]))
      nil
  """
  @spec billed_to(map() | CachedTitle.t() | nil, String.t(), MapSet.t()) :: String.t() | nil
  def billed_to(providers, region, mine) do
    case Availability.offers(providers, region) do
      nil ->
        nil

      offers ->
        offers
        |> Map.get("flatrate", [])
        |> Enum.filter(&MapSet.member?(mine, fold(&1)))
        |> Enum.sort()
        |> List.first()
    end
  end

  @doc """
  What a service costs per hour watched, and how that reads.

  `nil` for a service with no price — a rate is a division and Kati will not
  invent a numerator. `Not used yet` for one with no hours, which is a
  sentence rather than a division by zero, and the one the suggestion card is
  about.

      iex> Kati.Subscriptions.rate(899, 240)
      {"£2.25/h", :fair}

      iex> Kati.Subscriptions.rate(899, 0)
      {"Not used yet", :dear}

      iex> Kati.Subscriptions.rate(nil, 240)
      {nil, :fair}
  """
  @spec rate(integer() | nil, non_neg_integer()) :: {String.t() | nil, :good | :fair | :dear}
  def rate(nil, _minutes), do: {nil, :fair}
  def rate(_pence, 0), do: {"Not used yet", :dear}

  def rate(pence, minutes) do
    per_hour = pence / (minutes / 60)
    {"£#{:erlang.float_to_binary(per_hour / 100, decimals: 2)}/h", tone(per_hour)}
  end

  # Under a pound an hour is a good subscription; over three is a dear one.
  # Round numbers, chosen once, and named rather than repeated at the two
  # places that colour a row.
  defp tone(per_hour) when per_hour <= 100, do: :good
  defp tone(per_hour) when per_hour >= 300, do: :dear
  defp tone(_per_hour), do: :fair

  @doc """
  The card at the foot: the service the reader is paying most for and using
  least, or `nil` when there is nothing to say.

  Only for a service with a price and under `#{@quiet_hours} hours` on it,
  because that is the case worth interrupting somebody about. A page that
  suggested something every month would be a page nobody reads.
  """
  @spec suggestion([map()]) :: map() | nil
  def suggestion(rows) do
    rows
    |> Enum.filter(&(&1.pence != nil and &1.minutes < @quiet_hours * 60))
    |> Enum.max_by(& &1.pence, fn -> nil end)
    |> case do
      nil ->
        nil

      row ->
        %{
          # Whose advice this is, so `dismissed/0` can be about one service rather
          # than about advice in general.
          service: row.name,
          body:
            gettext(
              "You have watched %{hours} on %{name} this month. Pausing it saves %{price} a month.",
              hours: hours_word(row.minutes),
              name: Kati.Locale.ltr(row.name),
              price: row.price
            ),
          confirm: gettext("Remind me"),
          dismiss: gettext("Dismiss"),
          # When the reminder this card is offering would actually arrive, or
          # `nil` when it cannot. `Kati.Notifications.Sources.Money` arms a
          # renewal reminder for every subscribed service that HAS a renewal
          # date — unconditionally, with no opt-in — so the honest thing for
          # this button to do is name that date rather than pretend to arm
          # something. A service with no `renews_on` gets no reminder from
          # anywhere, and the card must not offer one.
          remind_on: remind_on(row.renews_on)
        }
    end
  end

  @dismissed_key :kati_subscription_advice_dismissed

  @doc """
  Whose suggestion the reader has already dismissed, if any.

  *Dismiss* was a socket assign and nothing else: the card came back on the
  next mount, so the button retired it for as long as the reader stayed on the
  page and no longer. MOVIES-AND-TV.md #59.

  Keyed by the SERVICE, not by a bare boolean. The card is advice about one
  subscription, and a reader who dismisses it has said something about that
  service rather than about advice in general. A blanket flag would silence the
  next card too, about a service they have never been shown anything about.
  """
  @spec dismissed() :: String.t() | nil
  def dismissed do
    case Mob.State.get(@dismissed_key) do
      name when is_binary(name) and name != "" -> name
      _none -> nil
    end
  rescue
    _error -> nil
  end

  @doc "Retire the suggestion for one service."
  @spec dismiss(String.t()) :: :ok
  def dismiss(name) when is_binary(name) do
    Mob.State.put(@dismissed_key, name)
    :ok
  rescue
    _error -> :ok
  end

  @doc """
  The day the renewal reminder fires, counted back from the renewal itself.

  `Kati.Notifications.Sources.Money.lead_days/0` rather than a second copy of
  the number: a card naming a date the scheduler disagrees with is the defect
  this is fixing, one step along.
  """
  @spec remind_on(Date.t() | nil) :: Date.t() | nil
  def remind_on(nil), do: nil

  def remind_on(%Date{} = renews_on),
    do: Date.add(renews_on, -Kati.Notifications.Sources.Money.lead_days())

  @doc false
  def hours_word(minutes) when minutes < 60,
    do: pgettext("hours watched on a service, when it is under an hour", "nothing")

  def hours_word(minutes) do
    hours = div(minutes, 60)

    ngettext("%{n} hour", "%{n} hours", hours, n: Kati.Locale.number(hours))
  end

  defp row(%Service{} = service, minutes) do
    {rate, tone} = rate(service.monthly_pence, minutes)

    %{
      badge: Service.badge(service),
      name: service.name,
      line: line(service, minutes),
      price: Service.price(service),
      pence: service.monthly_pence,
      minutes: minutes,
      rate: rate,
      rate_tone: colour(tone),
      # Screen 23 greys a paused row and drops its rate — `service_row/2` reads
      # `Map.get(row, :paused, false)` — and this map never carried the column,
      # so that branch fired for the drawing's rows and never for a reader's.
      # Board 302 is what can now set it.
      paused: service.paused,
      # Carried for `suggestion/1`, which has to say when the renewal reminder
      # it offers would arrive. Not for drawing: `line/2` already words the
      # renewal for the row itself.
      renews_on: service.renews_on,
      # Whose row this is. The drawing's services are not on this device, so
      # `Kati.Screens.Service.find/1` would answer `nil` for every one of them
      # and a tap would open a page about nothing. See
      # `Kati.Screens.Subscriptions.service_tap/1`.
      live?: true
    }
  end

  # `renews 18 Aug · 41h watched`, minus whichever half is unknown. A service
  # with no renewal date and no hours has nothing to put here and gets nothing,
  # rather than a bullet with air on both sides of it.
  defp line(service, minutes) do
    [renewal(service.renews_on), watched(minutes)]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" · ")
    |> case do
      "" -> nil
      line -> line
    end
  end

  defp renewal(%Date{} = date), do: "renews " <> Calendar.strftime(date, "%-d %b")
  defp renewal(_none), do: nil

  defp watched(minutes) when minutes >= 60, do: "#{div(minutes, 60)}h watched"
  defp watched(_minutes), do: nil

  defp colour(:good), do: Kati.Theme.Palette.green()
  defp colour(:dear), do: Kati.Theme.Palette.red()
  defp colour(:fair), do: Kati.Theme.Palette.sub()

  defp subscribed do
    Service
    |> Ash.Query.for_read(:subscribed)
    |> Ash.read!()
  end

  # `%{tracked_title_id => CachedTitle}` for every title the history names, by
  # the `{source, source_id}` pair a tracked row references its cache with.
  defp titles_for(watches) do
    ids = watches |> Enum.map(& &1.tracked_title_id) |> Enum.uniq()

    tracked =
      Kati.Media.TrackedTitle
      |> Ash.Query.filter(id in ^ids)
      |> Ash.read!()

    cached =
      CachedTitle
      |> Ash.Query.filter(source_id in ^Enum.map(tracked, & &1.source_id))
      |> Ash.read!()
      |> Map.new(&{{&1.source, &1.source_id}, &1})

    Map.new(tracked, &{&1.id, Map.get(cached, {&1.source, &1.source_id})})
  end

  # The same read `Kati.Screens.Stats.runtimes_for/1` makes, for the same
  # reason: TMDB puts a series' duration on each EPISODE, so a tick's minutes
  # are the episode's and a film's are the title's.
  defp episode_runtimes(watches) do
    ids =
      watches |> Enum.map(& &1.episode_source_id) |> Enum.reject(&is_nil/1) |> Enum.uniq()

    case ids do
      [] ->
        %{}

      ids ->
        Kati.Media.CachedEpisode
        |> Ash.Query.filter(source_id in ^ids)
        |> Ash.read!()
        |> Enum.reject(&is_nil(&1.runtime_minutes))
        |> Map.new(&{&1.source_id, &1.runtime_minutes})
    end
  end

  defp minutes(watch, cached, runtimes) do
    Map.get(runtimes, watch.episode_source_id) || cached.runtime_minutes
  end

  defp fold(name) when is_binary(name), do: name |> String.trim() |> String.downcase()
  defp fold(_other), do: ""
end
