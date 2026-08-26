defmodule Kati.Calendars.Today do
  @moduledoc """
  Today's timeline rows, rendered from real events.

  Queries by UTC window rather than by date, because "today" is a wall-clock
  question in the device's zone and the rows are stored as instants.

  ## A row carries its kind; the label is a rendering decision

  A row is `%{id, time, title, meta, kind, location, now?}`. `kind` is the
  event's own `Kati.Calendars.Event` kind, **verbatim** rather than collapsed,
  and `location` is the event's own — so a screen has the two facts the
  sub-line is made of, not only the one sentence one language wrote out of
  them.

  ## A row carries WHICH event it is

  `id` is the event's primary key, and it is here for the same reason `kind` is:
  a screen that draws a list of rows and then opens one has to be able to say
  which one, and everything else on a row is a rendering of the event rather
  than a handle on it. Without it screen 02's timeline could push screen 31 and
  screen 31 could only re-query and take the first row back — tap the third
  event, edit the first (#84). `occurrences/1` has carried `:id` since it was
  written, because `Kati.Calendar.Layout` cannot lane rows it cannot tell
  apart; the timeline rows had the same need and not the field.

  `meta` is that sentence **in English**: it is what screens 01, 02 and 28
  draw and what their captured frames hold, so it does not move. A screen
  drawing in another language composes its own line with `meta/2` instead of
  reading the field — which is the bug screens 55 and 56 exposed, where every
  real row on a Persian page ended in `Airs today` or `Habit` because the label
  was baked in before the row left this module.

  Two things follow, and both matter more than the field does:

    * **The label is written once**, in `kind_label/2`. It used to be written
      here and read back out of the composed string by
      `Kati.Screens.Calendar.kind/1`, which decided a card's shape, its chip and
      the screen a tap pushed by `String.contains?(meta, "Money")` — so an event
      whose location the user had typed as *Money* was routed to Subscriptions,
      and any edit to a word here silently re-routed every row of that kind.
      That screen reads `:kind` now.

    * **Nothing downstream has to guess.** A kind is a fact of the event; a
      label is a fact of a language. Deriving the first from the second is the
      one direction that cannot be done safely, and it is the direction the two
      screens were forced into.
  """

  require Ash.Query

  alias Kati.Calendars.Event

  @doc "Rows for today, ordered, already formatted for the timeline."
  @spec rows(Date.t() | nil) :: [map()]
  def rows(date \\ nil) do
    zone = Kati.Time.device_zone()
    day = date || Kati.Time.today()

    day
    |> events(zone)
    |> Enum.map(&row(&1, zone))
  end

  # One query, shared by the timeline rows and the lane layout, so the two
  # can never disagree about what is on a day.
  defp events(day, zone) do
    with {:ok, from} <- Kati.Time.to_utc(NaiveDateTime.new!(day, ~T[00:00:00]), zone),
         {:ok, to} <- Kati.Time.to_utc(NaiveDateTime.new!(day, ~T[23:59:59]), zone) do
      Event
      |> Ash.Query.filter(is_nil(deleted_at) and dtstart_utc >= ^from and dtstart_utc <= ^to)
      |> Ash.Query.sort(dtstart_utc: :asc)
      |> Ash.read!()
    else
      _ -> []
    end
  rescue
    _ -> []
  end

  @doc """
  The day's timed occurrences as `Kati.Calendar.Layout` input.

  Minutes from midnight in the device zone, all-day events excluded — they
  belong to the band above the gutter and the layout engine has no concept
  of them.
  """
  @spec occurrences(Date.t() | nil) :: [map()]
  def occurrences(date \\ nil) do
    zone = Kati.Time.device_zone()
    day = date || Kati.Time.today()

    day
    |> events(zone)
    |> Enum.reject(& &1.is_all_day)
    |> Enum.map(&to_occurrence(&1, zone, day))
  end

  defp to_occurrence(event, zone, day) do
    start_min = minutes_into(event.dtstart_utc, zone, day)

    end_min =
      case event.dtend_utc do
        nil -> start_min
        dt -> minutes_into(dt, zone, day)
      end

    %{
      id: event.id,
      start_min: start_min,
      # An event running past midnight is clipped to the day it is drawn on,
      # not dropped and not wrapped — the next day draws its own share.
      end_min: min(max(end_min, start_min), 1440),
      kind: event.kind,
      location: event.location,
      title: event.summary || "Untitled",
      meta: meta(event)
    }
  end

  defp minutes_into(utc, zone, day) do
    local = Kati.Time.in_zone(utc, zone)

    case Date.compare(DateTime.to_date(local), day) do
      :lt -> 0
      :gt -> 1440
      :eq -> local.hour * 60 + local.minute
    end
  end

  @doc """
  One event in the shape the timeline draws it, in a given zone.

  Public because it is the whole of the row contract, and the only way to
  exercise that contract without a store: an `%Kati.Calendars.Event{}` built in
  memory answers exactly the row a stored one does. `rows/1` reads the zone once
  and passes it in, so every row of a day is stamped against one clock.
  """
  @spec row(Event.t(), String.t()) :: map()
  def row(event, zone) do
    local = Kati.Time.in_zone(event.dtstart_utc, zone)
    now = DateTime.utc_now()

    %{
      # The handle, not a rendering. See the moduledoc: a row that cannot name
      # its own event is a row a screen can draw and cannot open.
      id: event.id,
      time: Calendar.strftime(local, "%H:%M"),
      title: event.summary || "Untitled",
      # The event's own kind, uncollapsed. `:reminder` and `:event` share a
      # label and draw differently — screen 56 gives a reminder a hollow ring
      # and an appointment a rule — so the row keeps the value that can still
      # tell them apart, and the collapsing happens at each point of use.
      kind: event.kind,
      location: event.location,
      meta: meta(event),
      # Orange means new/now, and only that: within the next hour counts as now.
      now?: DateTime.diff(event.dtstart_utc, now, :second) in 0..3600
    }
  end

  @doc """
  The sub-line under a row's title, in one locale.

  Takes a row, an occurrence or the `Kati.Calendars.Event` any of them was built
  from — all three carry the `:location` and the `:kind` the line is made of —
  so a screen that needs the line in another language asks for it here rather
  than translating a sentence back into its parts.

  The location leads because it is the user's own words and the label is Kati's,
  and it is dropped when there is none. `kind_label/2` is never empty, so the
  line never is either.

  English is the default because it is what the row's `:meta` field holds and
  what screens 01, 02 and 28 were captured drawing.
  """
  @spec meta(map(), :en | :fa) :: String.t()
  def meta(row_or_event, locale \\ :en)

  def meta(%{location: location, kind: kind}, locale) do
    [location, kind_label(kind, locale)]
    |> Enum.reject(&(is_nil(&1) or &1 == ""))
    |> Enum.join(" · ")
  end

  @doc """
  The word for an event kind, in one locale.

  Seven kinds, five words: `:event`, `:reminder` and `:note` are all *on the
  calendar* and the drawings give them one label. An unknown locale answers in
  English, which is `Kati.Locale`'s own default and the safer half of a guess.

  **The English words are exactly what this module has always written.** Screens
  01, 02 and 28 draw this line and are compared pixel-by-pixel with captured
  frames, so these five strings are fixed until a capture says otherwise. (09 is
  compared the same way and is not on this path at all — `Kati.Screens.Day` is
  still on `Kati.Calendar.SampleDay` and writes its own sub-lines, for the five
  reasons its moduledoc lists.)

  The Persian words are the ones screens 55–62 already use for the same things,
  rather than a second translation of the same concept: عادت and مالی are
  `Kati.Screens.ScheduleFa.Sample`'s own, وعده‌ها is the Meals root's title in
  `Kati.Screens.HomeFa.Sample`, and تقویم is Settings'.
  """
  @spec kind_label(atom(), :en | :fa) :: String.t()
  def kind_label(kind, locale \\ :en)

  def kind_label(:air_date, :fa), do: "پخش امروز"
  def kind_label(:meal, :fa), do: "وعده‌ها"
  def kind_label(:habit, :fa), do: "عادت"
  def kind_label(:money, :fa), do: "مالی"
  def kind_label(_kind, :fa), do: "تقویم"

  def kind_label(:air_date, _locale), do: "Airs today"
  def kind_label(:meal, _locale), do: "Meals"
  def kind_label(:habit, _locale), do: "Habit"
  def kind_label(:money, _locale), do: "Money"
  def kind_label(_kind, _locale), do: "Calendar"
end
