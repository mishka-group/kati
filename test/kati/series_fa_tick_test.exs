defmodule Kati.SeriesFaTickTest do
  @moduledoc """
  Marking an episode watched on the Persian series page writes it.

  MOVIES-AND-TV.md #33: *"Marking an episode watched on the Persian page
  writes nothing. The ring fills, the counter moves and the button relabels,
  and every one of those changes is discarded when the screen is popped."*

  The cause was the one screen 04 had already had and fixed: `episode_row/2`
  rebuilt the row for the tree and dropped `source_id` on the way, and
  `Kati.Media.Watch` names an episode by that and nothing else. So the Persian
  page had no way to write even if it had tried, and it did not try.

  en and fa are one app in two languages. A tick has to mean the same thing on
  both, so both go through `Kati.Screens.Series.write_tick/2` — and this file
  checks that by ticking in Persian and reading the result in English.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedEpisode
  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Screens.SeriesFa

  @prefix "series-fa-tick-"

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

  describe "the row the Persian page draws" do
    test "carries what a tick is written against", %{tracked: tracked} do
      [first | _rest] = SeriesFa.series(tracked.id).episodes

      assert first.source_id == @prefix <> "ep1"
      assert first.season == 1
      assert first.number == 1
    end

    test "and its Persian numeral is beside the integer, not instead of it", %{tracked: tracked} do
      [first | _rest] = SeriesFa.series(tracked.id).episodes

      assert first.n == "۱"
      assert first.number == 1
    end
  end

  describe "a tick" do
    test "writes a watch row", %{tracked: tracked} do
      socket = mounted(tracked)

      _ticked = SeriesFa.tick(socket, 0)

      assert [%{episode_source_id: source_id, season_number: 1, episode_number: 1}] =
               Ash.read!(Watch)

      assert source_id == @prefix <> "ep1"
    end

    test "so the English page shows it too", %{tracked: tracked} do
      _ticked = SeriesFa.tick(mounted(tracked), 0)

      episode = Kati.Screens.Series.series(tracked.id).episodes |> hd()
      assert episode.watched
    end

    test "and ticking it again takes the row away", %{tracked: tracked} do
      ticked = SeriesFa.tick(mounted(tracked), 0)
      _untick = SeriesFa.tick(ticked, 0)

      assert Ash.read!(Watch) == []
    end

    test "the ring follows the store, not the tap", %{tracked: tracked} do
      ticked = SeriesFa.tick(mounted(tracked), 0)

      assert hd(ticked.assigns.series.episodes).watched
      assert ticked.assigns.save_error == nil
    end
  end

  describe "a series that is only a drawing" do
    test "writes nothing and says so in Persian" do
      socket =
        Kati.Screens.SeriesFa
        |> Mob.Socket.new()
        |> Mob.Socket.assign(:series, SeriesFa.drawn_series())
        |> Mob.Socket.assign(:save_error, nil)

      refused = SeriesFa.tick(socket, 0)

      assert Ash.read!(Watch) == []
      assert refused.assigns.save_error == "این سریال هنوز در کتابخانه‌ی شما نیست."

      # The list is untouched, ticks and all — the ring follows the store, and
      # the store said no.
      assert refused.assigns.series.episodes == socket.assigns.series.episodes
    end
  end

  defp mounted(tracked) do
    {:ok, socket} =
      SeriesFa.mount(%{id: tracked.id}, %{}, Mob.Socket.new(Kati.Screens.SeriesFa))

    socket
  end

  defp tracked! do
    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: @prefix <> "title",
      kind: :tv,
      title: "جدایی",
      fetched_at: Kati.Time.now()
    })

    for n <- 1..3 do
      Ash.create!(CachedEpisode, %{
        source: :tmdb,
        title_source_id: @prefix <> "title",
        source_id: @prefix <> "ep#{n}",
        season_number: 1,
        episode_number: n,
        title: "قسمت #{n}",
        runtime_minutes: 45,
        fetched_at: Kati.Time.now()
      })
    end

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: @prefix <> "title",
      kind: :tv,
      status: :watching,
      progress_season: 1
    })
  end
end
