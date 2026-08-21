defmodule Kati.BackgroundHandoffTest do
  @moduledoc """
  The BEAM half of the two-language filesystem protocol.

  The other half is Kotlin and cannot run here, so two different things are
  asserted and they are not interchangeable:

    * **behaviour** — round trips, atomicity, ordering, and what happens to a
      file this build cannot read. Real files on a real filesystem.
    * **the wire** — that `KatiRefreshWorker.kt` names the same directory, the
      same filenames and the same JSON keys this module does. A protocol whose
      two ends are in different languages drifts silently, and the only signal
      is a user quietly getting no notifications.
  """
  use ExUnit.Case, async: true

  alias Kati.Background.Handoff

  @root Path.expand("../..", __DIR__)
  @worker Path.join(@root, "android/app/src/main/java/com/example/kati/KatiRefreshWorker.kt")

  setup do
    dir = Path.join(System.tmp_dir!(), "kati_handoff_#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf(dir) end)
    {:ok, dir: dir}
  end

  describe "the watchlist the BEAM writes" do
    test "round trips every field the worker reads", %{dir: dir} do
      entries = [
        %{
          source: "tmdb",
          source_id: "1396",
          title: "Breaking Bad",
          last_season: 5,
          last_episode: 16,
          etag: "W/\"abc123\""
        },
        %{
          source: "tvmaze",
          source_id: "82",
          title: nil,
          last_season: nil,
          last_episode: nil,
          etag: nil
        }
      ]

      assert {:ok, 2} = Handoff.put_watchlist(entries, dir: dir)
      assert [first, second] = Handoff.watchlist(dir: dir)

      assert first.source_id == "1396"
      assert first.title == "Breaking Bad"
      assert first.last_season == 5
      assert first.last_episode == 16
      assert first.etag == "W/\"abc123\""
      assert second.source == "tvmaze"
      assert second.title == nil
    end

    test "a title with a quote, a newline and Persian digits survives", %{dir: dir} do
      # The Kotlin side parses this with org.json. A hand-built JSON writer on
      # either end breaks on exactly these three, and the symptom is an empty
      # watchlist rather than an error.
      awkward = "She said \"it's fine\",\nthen — ۱۲ مرداد"

      assert {:ok, 1} =
               Handoff.put_watchlist(
                 [%{source: "tmdb", source_id: "1", title: awkward}],
                 dir: dir
               )

      assert [%{title: ^awkward}] = Handoff.watchlist(dir: dir)
    end

    test "the write is atomic and leaves nothing behind", %{dir: dir} do
      assert {:ok, 1} = Handoff.put_watchlist([%{source: "tmdb", source_id: "1"}], dir: dir)

      # A .tmp left in place means the rename did not happen, which on the
      # Kotlin side reads as "the user follows nothing".
      assert File.ls!(dir) == ["kati_watchlist.json"]
    end

    test "rewriting replaces rather than merging", %{dir: dir} do
      assert {:ok, 2} =
               Handoff.put_watchlist(
                 [%{source: "tmdb", source_id: "1"}, %{source: "tmdb", source_id: "2"}],
                 dir: dir
               )

      assert {:ok, 1} = Handoff.put_watchlist([%{source: "tmdb", source_id: "3"}], dir: dir)

      # An unfollowed show that stayed in the file would keep being fetched and
      # keep producing notifications the user asked to stop.
      assert [%{source_id: "3"}] = Handoff.watchlist(dir: dir)
    end

    test "an absent or corrupt watchlist reads as empty rather than raising", %{dir: dir} do
      assert Handoff.watchlist(dir: dir) == []

      File.write!(Handoff.watchlist_path(dir: dir), "{ this is not json")
      assert Handoff.watchlist(dir: dir) == []

      File.write!(Handoff.watchlist_path(dir: dir), ~s({"schema":1}))
      assert Handoff.watchlist(dir: dir) == []
    end
  end

  describe "draining what the worker wrote" do
    test "runs come back oldest first and the files go", %{dir: dir} do
      for minute <- [30, 10, 20] do
        assert {:ok, _} =
                 Handoff.record_run(
                   %{
                     at: DateTime.new!(~D[2026-08-21], Time.new!(9, minute, 0)),
                     outcome: "ok",
                     checked: minute,
                     items: []
                   },
                   dir: dir
                 )
      end

      assert [first, second, third] = Handoff.drain(dir: dir)
      assert [first.checked, second.checked, third.checked] == [10, 20, 30]

      # Drained means gone: a second drain must not replay the same runs, or
      # every foreground would re-ingest the same episodes.
      assert Handoff.drain(dir: dir) == []
      assert File.ls!(Handoff.inbox_dir(dir: dir)) == []
    end

    test "the items a run found survive the round trip", %{dir: dir} do
      items = [
        %{
          "source" => "tmdb",
          "source_id" => "1396",
          "season" => 5,
          "episode" => 16,
          "air_date" => "2026-09-01",
          "notified" => true
        }
      ]

      assert {:ok, _} =
               Handoff.record_run(
                 %{at: ~U[2026-08-21 09:00:00Z], outcome: "ok", checked: 1, items: items},
                 dir: dir
               )

      assert [run] = Handoff.drain(dir: dir)
      assert run.outcome == "ok"
      assert run.items == items

      # `notified` is what stops the BEAM re-notifying something the Worker
      # already posted. If it stopped crossing the boundary the user would get
      # every episode twice.
      assert [%{"notified" => true}] = run.items
    end

    test "a record this build cannot read is kept, not thrown away", %{dir: dir} do
      inbox = Handoff.inbox_dir(dir: dir)
      File.write!(Path.join(inbox, "1.json"), ~s({"schema":99,"run":{"at":1}}))
      File.write!(Path.join(inbox, "2.json"), "truncated{")

      assert {:ok, _} =
               Handoff.record_run(
                 %{at: ~U[2026-08-21 09:00:00Z], outcome: "ok", checked: 0, items: []},
                 dir: dir
               )

      assert [run] = Handoff.drain(dir: dir)
      assert run.checked == 0

      # Deleting an unreadable record is how "notifications stopped after the
      # update" becomes unexplainable.
      assert Handoff.stale(dir: dir) == ["1.json", "2.json"]
    end

    test "a write in flight is ignored", %{dir: dir} do
      inbox = Handoff.inbox_dir(dir: dir)
      File.write!(Path.join(inbox, "1755000000000.tmp"), ~s({"schema":1,"run":))

      assert Handoff.drain(dir: dir) == []
      assert Handoff.stale(dir: dir) == []
      assert File.ls!(inbox) == ["1755000000000.tmp"]
    end

    test "draining an empty inbox creates it and answers nothing", %{dir: dir} do
      assert Handoff.drain(dir: dir) == []
      assert File.dir?(Handoff.inbox_dir(dir: dir))
    end
  end

  describe "the refresh-on-open net" do
    test "boot drains the inbox and re-ensures the worker" do
      # The wiring is the thing that silently does not happen. A drain that is
      # never called leaves the Worker writing into a directory nobody reads,
      # and the symptom is "background checking doesn't work" with every part
      # of it individually correct.
      [on_start] =
        Regex.run(
          ~r/def on_start do(?s).*?\n  end\n/,
          File.read!(Path.join(@root, "lib/kati/app.ex"))
        )

      assert on_start =~ "Kati.Background.Handoff.drain()",
             "nothing reads what the Worker wrote"

      assert on_start =~ "Kati.Background.Periodic.ensure()",
             "the periodic work is never enqueued"

      # At start, not only on did_become_active: a cold launch never sends
      # that message, and a cold launch is exactly when the inbox is full.
      assert on_start =~ "Ecto.Migrator.run",
             "the scan is not reading the real on_start"
    end
  end

  describe "the Kotlin end of the same protocol" do
    test "names the same file and the same directory" do
      kotlin = File.read!(@worker)

      assert kotlin =~ ~s(WATCHLIST = "kati_watchlist.json"),
             "the two ends must name the same file or the watchlist is written where " <>
               "nothing reads it"

      assert kotlin =~ ~s(INBOX_DIR = "kati_inbox")
    end

    test "writes the same keys drain/1 reads" do
      kotlin = File.read!(@worker)

      for key <- ~w(schema run at outcome checked items) do
        assert kotlin =~ ~s(put("#{key}"),
               "KatiRefreshWorker no longer writes \"#{key}\"; drain/1 reads it and would " <>
                 "quietly treat every run as unreadable"
      end
    end

    test "the Kotlin write is temp-then-rename too" do
      kotlin = worker_code()

      assert kotlin =~ ".tmp"
      assert kotlin =~ "renameTo("

      refute kotlin =~ "kati_episode_inbox.json",
             "the single-appended-file protocol was replaced by one file per run precisely " <>
               "so two live processes never read-modify-write the same file"
    end

    test "the worker holds no domain rule" do
      # #58's acceptance criterion, asserted rather than hoped for. A rule that
      # appears here exists in two languages, and two implementations of one
      # rule disagree eventually.
      #
      # Against the CODE: this file's comments name the rules it is NOT allowed
      # to hold, so a raw-text scan would fail on the prose that exists to
      # forbid them.
      kotlin = worker_code()

      for forbidden <- ~w(Shamsi Jalali Persian quietHours budget) do
        refute kotlin =~ forbidden,
               "#{forbidden} in the Worker means a domain decision has left Elixir"
      end
    end

    test "the cadence is the one that was argued for, not the 15-minute floor" do
      kotlin = worker_code()

      assert kotlin =~ "ExistingPeriodicWorkPolicy.KEEP",
             "REPLACE restarts the interval clock on every enqueue, so a user who opens " <>
               "Kati daily would never reach the 6h mark and the worker would never run"

      assert kotlin =~ "NetworkType.CONNECTED"
      assert kotlin =~ "setRequiresBatteryNotLow(true)"
      assert kotlin =~ "BackoffPolicy.EXPONENTIAL"

      refute kotlin =~ "setExpedited",
             "the expedited quota is 30 min per 24 h even in the Active bucket"

      # 6 h with a 2 h flex, expressed as minutes so both numbers are one
      # place. The floor is 15 and this is 24 times it.
      assert kotlin =~ "DEFAULT_INTERVAL_MINUTES = 6L * 60"
      assert kotlin =~ "DEFAULT_FLEX_MINUTES = 2L * 60"
    end
  end

  # Kotlin with comments removed. Every "the worker must not do X" assertion
  # has to be made against the code, because the argument for not doing X is
  # written in the comments right next to it.
  defp worker_code do
    code =
      @worker
      |> File.read!()
      |> String.replace(~r{/\*(?s).*?\*/}, "")
      |> String.replace(~r{//.*$}m, "")

    assert code =~ "class KatiRefreshWorker",
           "comment stripping removed the implementation — this scan proves nothing"

    code
  end
end
