defmodule Kati.CalendarAiringsTest do
  @moduledoc """
  L4 — an airing on the Schedule carries its show.

  Nothing put a followed show's episode on screen 02 at all: `Kati.Calendars.Event`
  has no `{source, source_id}` pair, so an `:air_date` event could not reach the
  show's poster, its `S# · E#` line or its series page, and nothing wrote one.
  `Kati.Calendars.Airings` reads the day's episodes off
  `Kati.Media.CachedEpisode.air_at` at render time, joined by `title_source_id`,
  and these seed a followed show with an episode airing today and walk it from
  the row to the tap.

  Every row is written inside one rolled-back transaction, for the reason
  `Kati.ScreenCalendarEmptyStateTest` gives: one SQLite file is shared by every
  test, and the mount reads through the test's own connection.
  """
  use Mob.ScreenCase, async: false

  doctest Kati.Calendars.Airings

  alias Kati.Calendars.Airings
  alias Kati.Media.CachedEpisode
  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Screens.Calendar, as: Schedule

  @poster "/calendar-airings-test.jpg"

  setup do
    Kati.Locale.put(:en)
    File.mkdir_p!(Path.dirname(artwork_file()))
    File.write!(artwork_file(), "poster")
    on_exit(fn -> File.rm(artwork_file()) end)
    :ok
  end

  test "a followed show airing today is a row with its title, episode line and poster" do
    rolled_back(fn ->
      show = follow!("Severance", poster: @poster)
      episode!(show, season: 2, episode: 3, on: Kati.Time.today())

      assert [row] = Airings.rows(Kati.Time.today())
      assert row.title == "Severance"
      assert row.meta == "S2 · E3"
      assert row.seed == @poster
      assert row.tracked_id == show.id
      assert row.time == "All day"

      assert [shaped] = Schedule.day_rows(Kati.Time.today())
      assert shaped.shape == :show
      assert shaped.kind == "screen"

      {:ok, socket} = Schedule.mount(%{}, %{}, %Mob.Socket{})
      drawn = inspect(Schedule.content(socket.assigns), limit: :infinity)

      assert drawn =~ "Severance"
      assert drawn =~ "S2 · E3"
      assert drawn =~ artwork_file(), "the show's own poster is not on the row"
    end)
  end

  test "tapping the row opens the show's series page" do
    rolled_back(fn ->
      show = follow!("Severance", poster: @poster)
      episode!(show, season: 2, episode: 3, on: Kati.Time.today())

      {:ok, socket} = Schedule.mount(%{}, %{}, %Mob.Socket{})
      [row] = socket.assigns.rows
      tag = Schedule.tag(row)

      {:noreply, moved} = Schedule.handle_info({:tap, tag}, socket)

      assert {:push, Kati.Screens.Series, %{id: id}} = moved.__mob__.nav_action
      assert id == show.id
    end)
  end

  test "an hour-exact airing is placed at its hour, after the all-day ones" do
    rolled_back(fn ->
      today = Kati.Time.today()
      zone = Kati.Time.device_zone()
      {:ok, nine} = Kati.Time.to_utc(NaiveDateTime.new!(today, ~T[21:00:00]), zone)

      timed = follow!("Frieren", poster: nil)
      episode!(timed, season: 1, episode: 12, at: nine, confidence: :exact)

      all_day = follow!("Dark", poster: nil)
      episode!(all_day, season: 3, episode: 1, on: today)

      assert [%{title: "Dark", time: "All day"}, %{title: "Frieren", time: "21:00"}] =
               Airings.rows(today)
    end)
  end

  test "a whole season on one day is one row that says how many" do
    rolled_back(fn ->
      show = follow!("Arcane", poster: nil)

      for n <- 1..3 do
        episode!(show, season: 2, episode: n, on: Kati.Time.today())
      end

      assert [%{meta: "S2 · E1 · 3 episodes"}] = Airings.rows(Kati.Time.today())
    end)
  end

  test "only followed shows with calendar dates on, and only dates known to the day" do
    rolled_back(fn ->
      today = Kati.Time.today()

      dropped = follow!("Dropped Show", status: :dropped)
      episode!(dropped, season: 1, episode: 1, on: today)

      off = follow!("Switched Off", calendar?: false)
      episode!(off, season: 1, episode: 1, on: today)

      vague = follow!("Some Year")
      episode!(vague, season: 1, episode: 1, on: today, confidence: :year)

      tomorrow = follow!("Tomorrow's")
      episode!(tomorrow, season: 1, episode: 1, on: Date.add(today, 1))

      assert Airings.rows(today) == []
    end)
  end

  test "the Persian row reads its episode line in Persian" do
    rolled_back(fn ->
      show = follow!("Severance", poster: @poster)
      episode!(show, season: 2, episode: 3, on: Kati.Time.today())

      Kati.Locale.as(:fa, fn ->
        assert [%{meta: "ف۲ · ق۳", time: "تمام‌روز"}] = Airings.rows(Kati.Time.today())
      end)
    end)
  end

  defp follow!(title, opts \\ []) do
    source_id = "calendar-airings:#{System.unique_integer([:positive])}"

    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: source_id,
      kind: :tv,
      title: title,
      poster_path: Keyword.get(opts, :poster),
      fetched_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: source_id,
      kind: :tv,
      status: Keyword.get(opts, :status, :watching),
      add_air_dates_to_calendar: Keyword.get(opts, :calendar?, true)
    })
  end

  defp episode!(show, opts) do
    at =
      case Keyword.fetch(opts, :on) do
        {:ok, date} -> DateTime.new!(date, ~T[00:00:00.000000], "Etc/UTC")
        :error -> Keyword.fetch!(opts, :at)
      end

    Ash.create!(CachedEpisode, %{
      source: show.source,
      source_id: "calendar-airings-episode:#{System.unique_integer([:positive])}",
      title_source_id: show.source_id,
      season_number: Keyword.fetch!(opts, :season),
      episode_number: Keyword.fetch!(opts, :episode),
      air_at: at,
      date_confidence: Keyword.get(opts, :confidence, :day),
      fetched_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
  end

  defp artwork_file do
    Path.join([Mob.data_dir(), "artwork", "w342_" <> String.trim_leading(@poster, "/")])
  end

  defp rolled_back(fun) when is_function(fun, 0) do
    {:error, {:rolled_back, result}} =
      Kati.Repo.transaction(fn -> Kati.Repo.rollback({:rolled_back, fun.()}) end)

    result
  end
end
