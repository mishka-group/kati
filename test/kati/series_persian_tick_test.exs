defmodule Kati.SeriesPersianTickTest do
  @moduledoc """
  Marking an episode watched on the Persian series page writes it.

  The audit's finding: *"Marking an episode watched on the Persian page
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
  alias Kati.Screens.Series

  @prefix "series-fa-tick-"

  # Board 58 is screen 04 under `:fa` since mishka-group/kati#103 folded
  # `Kati.Screens.SeriesFa` away, so this file reads as a Persian reader.
  setup do
    Kati.Locale.put(:fa)
    Kati.Locale.activate()

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
      [first | _rest] = Series.series(tracked.id).episodes

      assert first.source_id == @prefix <> "ep1"
      assert first.season == 1
      assert first.n == 1
    end

    test "and its numeral is the reader's while the row stays an integer",
         %{tracked: tracked} do
      [first | _rest] = Series.series(tracked.id).episodes

      # The row carries the INTEGER — `Kati.Screens.Series.tick/2` writes
      # against it — and the screen converts at the draw site. The mirror
      # carried both, a `number` beside an `n` string, because it could not
      # convert where it drew.
      assert first.n == 1
      assert Kati.Locale.number(first.n) == "۱"
    end
  end

  describe "a tick" do
    test "writes a watch row", %{tracked: tracked} do
      socket = mounted(tracked)

      _ticked = Series.tick(socket, "0")

      assert [%{episode_source_id: source_id, season_number: 1, episode_number: 1}] =
               Ash.read!(Watch)

      assert source_id == @prefix <> "ep1"
    end

    test "so the English page shows it too", %{tracked: tracked} do
      _ticked = Series.tick(mounted(tracked), "0")

      episode = Kati.Screens.Series.series(tracked.id).episodes |> hd()
      assert episode.watched
    end

    test "and ticking it again takes the row away", %{tracked: tracked} do
      ticked = Series.tick(mounted(tracked), "0")
      _untick = Series.tick(ticked, "0")

      assert Ash.read!(Watch) == []
    end

    test "the ring follows the store, not the tap", %{tracked: tracked} do
      ticked = Series.tick(mounted(tracked), "0")

      assert hd(ticked.assigns.series.episodes).watched
      assert ticked.assigns.save_error == nil
    end
  end

  describe "board 249 — a series with no episode list, in the mirror" do
    test "says whose doing it is, and lists what still works" do
      # `text/1` rather than `inspect/2`: Persian copy carries U+200C, the
      # zero-width non-joiner that keeps قسمت‌ها one word, and `inspect`
      # escapes it to `\\u200C` — so a literal in the source never matches a
      # literal in an inspected tree, however right the screen is.
      drawn = text(Series.episodes(%{episodes: [], tracked_id: "x", by_hand?: true}))

      assert drawn =~ "هنوز فهرست قسمت‌ها نیست."
      assert drawn =~ "این را دستی اضافه کرده‌اید"
      assert drawn =~ "کارهایی که می‌شود کرد"

      for row <- ["ثبت یک تماشا", "رهاکردن این سریال", "حذف از کتابخانه"] do
        assert drawn =~ row, "board 249's #{row} row is missing"
      end

      refute drawn =~ "اینجا دکمهٔ اصلی نیست.",
             "board 249's footnote is a note to the designer, not to a reader"
    end

    test "and a series from a provider says the list is on its way, in Persian" do
      drawn = text(Series.episodes(%{episodes: [], tracked_id: "x", by_hand?: false}))

      refute drawn =~ "این را دستی اضافه کرده‌اید"
      refute drawn =~ "Its source has not listed"
      assert drawn =~ Series.pending_note()
    end

    test "and its chevrons point the way a Persian reader travels" do
      # `chevron_left`, not `chevron_right`. A container mirrors under RTL and a
      # glyph does not — board 156's caption calls that the commonest RTL bug
      # there is, and board 249 draws the mirrored one.
      drawn = inspect(Series.episodes(%{episodes: [], tracked_id: "x"}), limit: :infinity)

      assert drawn =~ Kati.Icons.glyph("chevron_left")
      refute drawn =~ Kati.Icons.glyph("chevron_right")
    end

    test "and the three rows act rather than being a picture of three rows" do
      drawn = inspect(Series.episodes(%{episodes: [], tracked_id: "x"}), limit: :infinity)

      for tag <- [":rate_title", ":open_drop_sheet", ":confirm_remove"] do
        assert drawn =~ tag, "board 249's row for #{tag} carries no tap"
      end
    end

    test "and a drawn series carries none, because there is nothing to act on" do
      drawn = inspect(Series.episodes(%{episodes: [], tracked_id: nil}), limit: :infinity)

      refute drawn =~ ":rate_title"
      refute drawn =~ ":remove_title"
    end

    test "and its rows are set in the Persian face without saying so on each Text" do
      # The point of `K-48 locale-face`, and the reason this state is the first
      # thing in `Kati.Screens.Series` built out of the SHARED components:
      # `Kati.UI.SettingsList` builds its own `Text` nodes with no
      # `font_family`, and the root's declared face is what they resolve to.
      # `Kati.PersianFontTest` is the sweep that holds it for every screen.
      assert Kati.Locale.face_for(:fa) == "fa"

      tree = tree(mount_screen(Series))

      assert Map.get(tree.props, :font_family) == "fa",
             "screen 58's root does not declare the face its unmarked Texts fall back to"
    end
  end

  describe "a series that is only a drawing" do
    test "writes nothing and says so in Persian" do
      socket =
        Kati.Screens.Series
        |> Mob.Socket.new()
        |> Mob.Socket.assign(:series, Series.drawn_series())
        |> Mob.Socket.assign(:save_error, nil)

      refused = Series.tick(socket, "0")

      assert Ash.read!(Watch) == []
      assert refused.assigns.save_error == "این سریال هنوز در کتابخانه‌ی شما نیست."

      # The list is untouched, ticks and all — the ring follows the store, and
      # the store said no.
      assert refused.assigns.series.episodes == socket.assigns.series.episodes
    end
  end

  defp mounted(tracked) do
    {:ok, socket} =
      Series.mount(%{id: tracked.id}, %{}, Mob.Socket.new(Kati.Screens.Series))

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
