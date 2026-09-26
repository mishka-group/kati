Code.require_file("../support/show_boards.exs", __DIR__)

defmodule Kati.RateEpisodeTest do
  @moduledoc """
  Screen 144, the sheet that could not rate an episode.

  Finding #25 was three defects in one screen, and each one on its own was
  enough to make the page impossible to use:

    * **No subject it could ever find.** `newest_episode_log/0` asked for an
      episode-level `Kati.Media.Watch` carrying a rating or a review, and the
      app's only episode-level writer — `Kati.Screens.Series.write_tick/2` —
      writes neither, because a tick is not a verdict. So the query answered
      `nil` on every phone in the world and the sheet drew The Long Hollow.
    * **Stars that were a picture.** `Kati.Screens.Rating.stars/2` has taken a
      `tappable?` since screen 33 got its own; this screen passed the default.
    * **A Save that saved nothing.** `handle_info({:tap, :save}, …)` popped the
      screen, full stop.

  The three are tested apart because they fail apart: a subject with no taps
  is a sheet you can read and not use, and taps with no write is worse than
  either — it draws the rating you chose and then throws it away.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedEpisode
  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Screens.RateEpisode
  alias Kati.Screens.Series

  @prefix "rate-episode-"

  setup do
    on_exit(fn ->
      Kati.Repo.query!(
        "DELETE FROM media_watches WHERE tracked_title_id IN " <>
          "(SELECT id FROM tracked_titles WHERE source_id LIKE ?1)",
        [@prefix <> "%"]
      )

      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM cached_episodes WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
    end)

    %{tracked: tracked!()}
  end

  describe "the episode the sheet opens over" do
    test "is the one you just ticked, not the drawing's", %{tracked: tracked} do
      :ok = Series.write_tick(tracked.id, row())

      sheet = RateEpisode.sheet()

      assert sheet.headline == "S2 E5 · Trojan's Horse"
      assert sheet.show_title == "Severance"
      refute sheet.headline =~ "Undertow"
    end

    test "carries the id of the row a rating would be written onto", %{tracked: tracked} do
      :ok = Series.write_tick(tracked.id, row())

      assert [watch] = Ash.read!(Watch)
      assert RateEpisode.sheet().watch_id == watch.id
    end

    test "has no rating yet, because a tick is not a verdict", %{tracked: tracked} do
      :ok = Series.write_tick(tracked.id, row())

      assert RateEpisode.sheet().rating == nil
    end

    test "and is the drawing's when nothing has been ticked at all" do
      assert RateEpisode.sheet().headline == "S2 E6 · The Undertow"
      refute RateEpisode.writable?(RateEpisode.sheet())
    end
  end

  describe "the stars" do
    test "are tappable over a real tick", %{tracked: tracked} do
      :ok = Series.write_tick(tracked.id, row())

      assert RateEpisode.writable?(RateEpisode.sheet())
      assert drawn(RateEpisode.sheet()) =~ "star_9"
    end

    test "stay a picture over the drawing", %{tracked: _tracked} do
      refute drawn(RateEpisode.sheet()) =~ "star_"
    end
  end

  describe "Save" do
    test "writes the rating onto the ticked episode's own watch row", %{tracked: tracked} do
      :ok = Series.write_tick(tracked.id, row())

      socket =
        Kati.Screens.RateEpisode
        |> Mob.Socket.new()
        |> Mob.Socket.assign(:sheet, RateEpisode.sheet())
        |> Mob.Socket.assign(:save_error, nil)
        |> Mob.Socket.assign(:verdict_expanded?, false)

      # Four and a half stars: the right-hand target of the fifth star's left
      # half, which is point 9 of the column's ten.
      {:noreply, picked} = RateEpisode.handle_info({:tap, :star_9}, socket)
      assert picked.assigns.sheet.rating == 4.5

      {:noreply, _popped} = RateEpisode.handle_info({:tap, :save}, picked)

      assert [%{rating: 9}] = Ash.read!(Watch)
    end

    test "and reopening the sheet finds the verdict, not the tick", %{tracked: tracked} do
      :ok = Series.write_tick(tracked.id, row())
      {:ok, _watch} = RateEpisode.save_rating(%{RateEpisode.sheet() | rating: 3.0})

      assert RateEpisode.sheet().rating == 3.0
    end

    test "on the drawing writes nothing at all" do
      assert RateEpisode.save_rating(RateEpisode.sheet()) == :nothing_to_save
      assert Ash.read!(Watch) == []
    end

    test "refuses when the row it was opened over has since gone", %{tracked: tracked} do
      :ok = Series.write_tick(tracked.id, row())
      sheet = %{RateEpisode.sheet() | rating: 4.0}

      Ash.read!(Watch) |> Enum.each(&Ash.destroy!/1)

      assert {:error, _reason} = RateEpisode.save_rating(sheet)
    end
  end

  describe "the route in" do
    test "screen 04 draws a rating door on every aired episode", %{tracked: tracked} do
      series = Kati.Screens.Series.series(tracked.id)

      assert drawn_series(series) =~ "rate_0"
    end

    test "and the door hands the sheet the pair it writes by", %{tracked: tracked} do
      socket =
        Kati.Screens.Series
        |> Mob.Socket.new()
        |> Mob.Socket.assign(:series, Kati.Screens.Series.series(tracked.id))

      pushed = Kati.Screens.Series.rate(socket, "0")

      assert %{tracked_id: id, episode_source_id: @prefix <> "ep"} = pushed_params(pushed)
      assert id == tracked.id
    end

    test "so the sheet opens over that episode even with a newer log elsewhere", %{
      tracked: tracked
    } do
      other = shelve_other!()
      :ok = Series.write_tick(other.id, %{source_id: @prefix <> "other-ep", watched: false})

      sheet = RateEpisode.sheet(%{tracked_id: tracked.id, episode_source_id: @prefix <> "ep"})

      assert sheet.headline == "S2 E5 · Trojan's Horse"
      assert sheet.episode_source_id == @prefix <> "ep"
    end

    test "a drawn series opens nothing" do
      socket =
        Kati.Screens.Series
        |> Mob.Socket.new()
        |> Mob.Socket.assign(:series, Kati.Test.ShowBoards.series())

      assert pushed_params(Kati.Screens.Series.rate(socket, "0")) == nil
    end
  end

  describe "rating an episode nobody has ticked" do
    test "creates the watch the tick would have made", %{tracked: tracked} do
      sheet =
        %{tracked_id: tracked.id, episode_source_id: @prefix <> "ep"}
        |> RateEpisode.sheet()
        |> Map.put(:rating, 4.0)

      assert {:ok, _watch} = RateEpisode.save_rating(sheet)

      assert [%{rating: 8, season_number: 2, episode_number: 5}] = Ash.read!(Watch)
    end

    test "so the episode reads as watched afterwards", %{tracked: tracked} do
      sheet =
        %{tracked_id: tracked.id, episode_source_id: @prefix <> "ep"}
        |> RateEpisode.sheet()
        |> Map.put(:rating, 4.0)

      {:ok, _watch} = RateEpisode.save_rating(sheet)

      series = Kati.Screens.Series.series(tracked.id)
      episode = Enum.find(series.episodes, &(&1.source_id == @prefix <> "ep"))

      assert episode.watched
      assert episode.rating == 4.0
    end

    test "and the column prints it", %{tracked: tracked} do
      sheet =
        %{tracked_id: tracked.id, episode_source_id: @prefix <> "ep"}
        |> RateEpisode.sheet()
        |> Map.put(:rating, 3.5)

      {:ok, _watch} = RateEpisode.save_rating(sheet)

      assert drawn_series(Kati.Screens.Series.series(tracked.id)) =~ "3.5"
    end
  end

  defp pushed_params(socket) do
    case Map.get(socket.__mob__, :nav_action) do
      {:push, Kati.Screens.RateEpisode, params} -> params
      _no_push -> nil
    end
  end

  defp drawn_series(series) do
    Kati.Screens.Series.episodes(series)
    |> inspect(limit: :infinity, printable_limit: :infinity)
  end

  defp shelve_other! do
    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: @prefix <> "other",
      kind: :tv,
      title: "Other",
      fetched_at: Kati.Time.now()
    })

    Ash.create!(CachedEpisode, %{
      source: :tmdb,
      title_source_id: @prefix <> "other",
      source_id: @prefix <> "other-ep",
      season_number: 1,
      episode_number: 1,
      title: "Pilot",
      fetched_at: Kati.Time.now()
    })

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: @prefix <> "other",
      kind: :tv,
      status: :watching
    })
  end

  defp drawn(sheet) do
    Kati.Screens.RateEpisode.rating_card(sheet)
    |> inspect(limit: :infinity, printable_limit: :infinity)
  end

  defp row do
    %{source_id: @prefix <> "ep", watched: false, season: 2, n: 5}
  end

  describe "the three context rows — board 204's decision, settled" do
    test "they are dead on the drawing and live over a real episode", %{tracked: tracked} do
      # A picture's rows do not open, which is the rule this round keeps
      # everywhere: a control that exists only over data is not drawn live over
      # a drawing of it.
      refute RateEpisode.editable?(Kati.Screens.RateEpisode.Sample.sheet())

      live = RateEpisode.sheet(%{tracked_id: tracked.id, episode_source_id: @prefix <> "ep"})
      assert RateEpisode.editable?(live)

      drawn = inspect(RateEpisode.context_card(live, nil), limit: :infinity)
      assert drawn =~ "row_watched_on"
      assert drawn =~ "row_where"
      assert drawn =~ "row_with"
    end

    test "one opens at a time, and pressing the open one closes it", %{tracked: tracked} do
      view = open(tracked)

      {:noreply, socket} = RateEpisode.handle_info({:tap, :row_watched_on}, view.socket)
      assert socket.assigns.open_row == :watched_on

      {:noreply, socket} = RateEpisode.handle_info({:tap, :row_where}, socket)
      assert socket.assigns.open_row == :where

      {:noreply, socket} = RateEpisode.handle_info({:tap, :row_where}, socket)
      assert socket.assigns.open_row == nil
    end

    test "and a row it never drew closes whatever is open rather than raising", %{
      tracked: tracked
    } do
      view = open(tracked)
      {:noreply, socket} = RateEpisode.handle_info({:tap, :row_watched_on}, view.socket)
      {:noreply, socket} = RateEpisode.handle_info({:tap, :row_nothing}, socket)

      assert socket.assigns.open_row == nil
    end

    test "a day chip dates the watch, and the row says so before it is saved", %{
      tracked: tracked
    } do
      view = open(tracked)
      yesterday = Date.add(Kati.Time.today(), -1)

      {:noreply, socket} =
        RateEpisode.handle_info({:tap, :"day_#{Date.to_iso8601(yesterday)}"}, view.socket)

      assert socket.assigns.sheet.watched_on == yesterday
      assert socket.assigns.open_row == nil

      row = Enum.find(RateEpisode.context_of(socket.assigns.sheet), &(&1.key == :watched_on))
      assert row.sub == "Yesterday"
      refute row.trailing, "the mono `now` survived a watch dated yesterday"
    end

    test "a service chip fills Where, and `Not on a service` stores nothing", %{tracked: tracked} do
      view = open(tracked)

      {:noreply, socket} = RateEpisode.handle_info({:tap, :"where_Lumen+"}, view.socket)
      assert socket.assigns.sheet.service == "Lumen+"

      not_on_one = String.to_atom("where_" <> Kati.Screens.Rating.no_service())
      {:noreply, socket} = RateEpisode.handle_info({:tap, not_on_one}, socket)

      assert socket.assigns.sheet.service == nil
    end

    test "With is typed and committed, and an empty field clears it", %{tracked: tracked} do
      view = open(tracked)

      {:noreply, socket} = RateEpisode.handle_info({:change, :with_draft, "Jo"}, view.socket)
      {:noreply, socket} = RateEpisode.handle_info({:tap, :commit_with}, socket)

      assert socket.assigns.sheet.companions == "Jo"
      assert socket.assigns.open_row == nil

      {:noreply, socket} = RateEpisode.handle_info({:change, :with_draft, "   "}, socket)
      {:noreply, socket} = RateEpisode.handle_info({:tap, :commit_with}, socket)

      assert socket.assigns.sheet.companions == nil
    end

    test "all three reach the store on the row Save creates", %{tracked: tracked} do
      yesterday = Date.add(Kati.Time.today(), -1)

      sheet =
        %{tracked_id: tracked.id, episode_source_id: @prefix <> "ep"}
        |> RateEpisode.sheet()
        |> Map.merge(%{
          rating: 4.0,
          watched_on: yesterday,
          service: "Lumen+",
          companions: "Jo"
        })

      assert {:ok, _watch} = RateEpisode.save_rating(sheet)

      assert [%{watched_on: ^yesterday, service: "Lumen+", companions: "Jo"} = watch] =
               Ash.read!(Watch)

      # `watched_at` follows `watched_on`, because the two are one fact: a row
      # dated yesterday whose timestamp says tonight puts the same watch on two
      # days depending which column you read it through.
      assert DateTime.to_date(watch.watched_at) == yesterday
    end

    test "and onto the row it updates", %{tracked: tracked} do
      # With a rating on it, because that is what `sheet/1` looks for: a tick
      # is not a verdict, so a watch carrying neither a rating nor a review is
      # not the row this sheet opens over. `Kati.RateEpisodeTest`'s moduledoc
      # records that as finding #25's first defect and its fix.
      created =
        Ash.create!(Watch, %{
          tracked_title_id: tracked.id,
          episode_source_id: @prefix <> "ep",
          season_number: 2,
          episode_number: 5,
          watched_at: Kati.Time.now(),
          watched_on: Kati.Time.today(),
          rating: 8,
          service: "Orbit"
        })

      sheet =
        %{tracked_id: tracked.id, episode_source_id: @prefix <> "ep"}
        |> RateEpisode.sheet()
        |> Map.merge(%{rating: 3.0, service: "Lumen+"})

      assert {:ok, _watch} = RateEpisode.save_rating(sheet)
      assert %{service: "Lumen+", rating: 6} = Ash.get!(Watch, created.id)
    end

    test "a row nobody opened writes nothing over what is already there", %{tracked: tracked} do
      # The reason `context_changes/1` reads `Map.fetch/2` rather than
      # `Map.get/2`: a sheet whose rows were never touched must not put `nil`
      # over a service somebody set on screen 33.
      created =
        Ash.create!(Watch, %{
          tracked_title_id: tracked.id,
          episode_source_id: @prefix <> "ep",
          season_number: 2,
          episode_number: 5,
          watched_at: Kati.Time.now(),
          watched_on: Kati.Time.today(),
          rating: 8,
          service: "Orbit",
          companions: "Jo"
        })

      sheet =
        %{tracked_id: tracked.id, episode_source_id: @prefix <> "ep"}
        |> RateEpisode.sheet()
        |> Map.put(:rating, 2.0)

      assert {:ok, _watch} = RateEpisode.save_rating(sheet)
      assert %{service: "Orbit", companions: "Jo"} = Ash.get!(Watch, created.id)
    end
  end

  defp open(tracked) do
    mount_screen(RateEpisode, %{
      tracked_id: tracked.id,
      episode_source_id: @prefix <> "ep"
    })
  end

  defp tracked! do
    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: @prefix <> "title",
      kind: :tv,
      title: "Severance",
      fetched_at: Kati.Time.now()
    })

    Ash.create!(CachedEpisode, %{
      source: :tmdb,
      title_source_id: @prefix <> "title",
      source_id: @prefix <> "ep",
      season_number: 2,
      episode_number: 5,
      title: "Trojan's Horse",
      runtime_minutes: 47,
      fetched_at: Kati.Time.now()
    })

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: @prefix <> "title",
      kind: :tv,
      status: :watching
    })
  end
end
