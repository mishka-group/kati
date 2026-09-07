defmodule Kati.MediaDetectTest do
  @moduledoc """
  Auto-detect, which screen 36 was the argument for and nothing behind.

  MOVIES-AND-TV.md #100: ten of twelve controls carried no `on_tap`, including
  the master switch for the whole feature, and the screen's own moduledoc
  agreed with the finding and explained it — *detection is a feature that has
  not been built, not a screen that has not been wired*. The reader asked for
  it built.

  What the phone can tell Kati is a **title and a subtitle** — Netflix reports
  `Severance` / `Half Loop`, a file player usually the reverse — plus a
  position and a duration. Everything asserted here follows from that being all
  there is:

    * nothing is ticked that is not already on the shelf;
    * nothing is ticked that was matched loosely;
    * nothing without a duration is ever ticked, because live television and a
      browser tab are both that;
    * a name Kati cannot place becomes a question, not a guess;
    * and a session that sits above the threshold for ten minutes writes one
      watch, not forty.

  The bridge is absent on a host, so `sessions/0` answers `[]` and `access/0`
  answers `:unavailable` — which is not `:denied`, because nobody has refused
  anything. The verdicts are therefore asserted against sessions built here,
  which is the same shape `KatiMediaListener` sends.
  """

  use Mob.ScreenCase, async: false

  doctest Kati.Media.Detect, only: [progress: 1, clamp: 1, candidates: 1]

  doctest Kati.Media.Detect.Near, only: [tokens: 1, score: 2]

  doctest Kati.Media.Detect.Notice, only: [id: 1]

  doctest Kati.Screens.AutoDetect,
    only: [
      ticked_line: 1,
      app_name: 1,
      clock: 1,
      access_line: 1,
      sources_line: 1,
      live?: 1,
      answer_tag: 1
    ]

  alias Kati.Media.CachedEpisode
  alias Kati.Media.CachedTitle
  alias Kati.Media.Detect
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Screens.AutoDetect

  @prefix "detect-test-"

  setup do
    on_exit(&wipe!/0)
    wipe!()
    Detect.put(true)
    Detect.put_threshold(90)
    %{tracked: shelve!("Severance", :tv)}
  end

  describe "the master switch" do
    test "is off until somebody says otherwise" do
      Mob.State.delete(:detect_enabled)

      refute Detect.on?()
    end

    test "and survives being read back, which is what makes it a switch" do
      Detect.put(false)
      refute Detect.on?()

      Detect.put(true)
      assert Detect.on?()
    end

    test "off means nothing is looked at at all" do
      Detect.put(false)

      assert Detect.sweep() == []
    end
  end

  describe "the threshold" do
    test "is board 36's ninety by default" do
      Mob.State.delete(:detect_threshold)

      assert Detect.threshold() == 90
    end

    test "and is clamped to something a person could mean" do
      Detect.put_threshold(5)
      assert Detect.threshold() == 50

      Detect.put_threshold(100)
      assert Detect.threshold() == 99
    end

    test "the row steps through the three values anybody picks" do
      socket = screen()

      {:noreply, one} = AutoDetect.handle_tap(:cycle_threshold, socket)
      assert Detect.threshold() == 95

      {:noreply, two} = AutoDetect.handle_tap(:cycle_threshold, one)
      assert Detect.threshold() == 80

      {:noreply, _three} = AutoDetect.handle_tap(:cycle_threshold, two)
      assert Detect.threshold() == 90
    end
  end

  describe "what counts as watched" do
    test "past the threshold, on the shelf, and playing", %{tracked: tracked} do
      assert {:tick, matched, nil} = Detect.verdict(session("Severance", 95))
      assert matched.id == tracked.id
    end

    test "short of it is nothing" do
      assert Detect.verdict(session("Severance", 40)) == :ignore
    end

    test "paused is nothing, however far through" do
      assert Detect.verdict(%{session("Severance", 99) | playing?: false}) == :ignore
    end

    test "and something with no end cannot be near the end of it" do
      live = %{
        app: "com.example.browser",
        title: "Severance",
        subtitle: "",
        duration_ms: 0,
        position_ms: 9_000_000,
        playing?: true
      }

      assert Detect.verdict(live) == :ignore
    end
  end

  describe "matching" do
    test "is by name against the shelf, case and whitespace aside", %{tracked: tracked} do
      assert {:tick, matched, nil} = Detect.verdict(session("  severance ", 95))
      assert matched.id == tracked.id
    end

    test "and never loosely" do
      assert {:ask, "Severance Season One"} = Detect.verdict(session("Severance Season One", 95))
    end

    test "reads the show off either half, because players disagree about which" do
      # Netflix: title is the series, subtitle the episode. A file player is
      # usually the reverse, and both have to work.
      netflix = %{session("Severance", 95) | subtitle: "Half Loop"}
      player = %{session("Half Loop", 95) | subtitle: "Severance"}

      assert {:tick, _t, _e} = Detect.verdict(netflix)
      assert {:tick, _t2, _e2} = Detect.verdict(player)
    end

    test "and names the episode when the cache holds one", %{tracked: tracked} do
      episode!(tracked, "Half Loop")

      assert {:tick, _t, id} = Detect.verdict(%{session("Severance", 95) | subtitle: "Half Loop"})
      assert id == @prefix <> "ep-Half Loop"
    end

    test "finds an anime by the name its player announces, not only TMDB's" do
      # The case the reader asked about. Their shelf holds TMDB's English name;
      # Crunchyroll announces the romaji one. Same show, and `title_original`
      # has been stored since the ingest was written with nothing reading it.
      anime!("Frieren: Beyond Journey's End", "Sousou no Frieren")

      assert {:tick, matched, _e} = Detect.verdict(session("Sousou no Frieren", 95))
      assert matched.source_id == @prefix <> "Frieren: Beyond Journey's End"

      # And still by the English name, which is what the shelf draws.
      assert {:tick, _t, _e2} = Detect.verdict(session("Frieren: Beyond Journey's End", 95))
    end

    test "and by the filename a local player announces" do
      # VLC playing a file reports the file. Cleaned and then matched EXACTLY —
      # this is a second spelling of one string, not fuzzy matching.
      anime!("Frieren: Beyond Journey's End", "Sousou no Frieren")
      shelve!("Blade Runner 2049", :movie)

      assert {:tick, _a, _e} = Detect.verdict(session("Sousou.no.Frieren.S01E05.1080p.mkv", 95))
      assert {:tick, _b, _e2} = Detect.verdict(session("Blade_Runner_2049.mp4", 95))
    end

    test "and a cleaned name that still matches nothing is still a question" do
      assert {:ask, _} = Detect.verdict(session("Some.Other.Film.S02E01.mkv", 95))
    end

    test "a title nobody keeps becomes a question rather than a title" do
      assert {:ask, "Some Film"} = Detect.verdict(session("Some Film", 95))

      Detect.apply(session("Some Film", 95))

      assert "Some Film" in Detect.unsure()
      assert Ash.read!(TrackedTitle) |> length() == 1, "nothing was added to the shelf"
    end
  end

  describe "writing" do
    test "ticks once, and says it was Kati that did it", %{tracked: tracked} do
      assert {:ok, :ticked} = Detect.apply(session("Severance", 95))

      assert [watch] = Ash.read!(Watch)
      assert watch.tracked_title_id == tracked.id
      assert watch.detected
    end

    test "and again a minute later writes nothing, which is the whole evening" do
      assert {:ok, :ticked} = Detect.apply(session("Severance", 95))
      assert {:ok, :already} = Detect.apply(session("Severance", 96))
      assert {:ok, :already} = Detect.apply(session("Severance", 99))

      assert length(Ash.read!(Watch)) == 1
    end

    test "an episode is ticked per episode, not per day", %{tracked: tracked} do
      episode!(tracked, "Half Loop")
      episode!(tracked, "Good News About Hell")

      assert {:ok, :ticked} =
               Detect.apply(%{session("Severance", 95) | subtitle: "Half Loop"})

      assert {:ok, :ticked} =
               Detect.apply(%{session("Severance", 95) | subtitle: "Good News About Hell"})

      assert length(Ash.read!(Watch)) == 2
    end

    test "and the banner counts what Kati ticked, not what you did", %{tracked: tracked} do
      # A watch you made yourself, on the title you made it about.
      Ash.create!(Watch, %{
        tracked_title_id: tracked.id,
        watched_on: Kati.Time.today(),
        watched_at: DateTime.truncate(Kati.Time.now(), :second)
      })

      assert Detect.detected_count() == 0
      assert AutoDetect.ticked_line(0) == "NOTHING TICKED FOR YOU YET"

      # And one Kati made, about a different film — the same title again today
      # is `:already`, which is the point of that clause and not of this test.
      shelve!("Arrival", :movie)
      {:ok, :ticked} = Detect.apply(session("Arrival", 95))

      assert Detect.detected_count() == 1
      assert AutoDetect.ticked_line(1) == "1 EPISODE TICKED FOR YOU"
      assert length(Ash.read!(Watch)) == 2
    end
  end

  describe "the unplaced queue" do
    test "keeps the last few names and no more" do
      for n <- 1..8, do: Detect.ask("Film #{n}")

      assert length(Detect.unsure()) == 5
      assert hd(Detect.unsure()) == "Film 8"
    end

    test "and answering one forgets it" do
      Detect.ask("Some Film")
      Detect.resolve("Some Film")

      assert Detect.unsure() == []
    end

    test "Add it opens the add sheet already searching for what was heard" do
      Detect.ask("Some Film")

      {:noreply, pushed} = AutoDetect.handle_tap(:answer_add_it, screen())

      assert {:push, Kati.Screens.AddTitle, %{query: "Some Film"}} =
               Map.get(pushed.__mob__, :nav_action)

      assert Detect.unsure() == []
    end

    test "and the pills carry the taps, which is what a queue you can answer means" do
      card = %{
        seed: nil,
        question: "“Some Film” — is that something you keep?",
        sub: "Kati heard it play and found nothing on your shelf",
        options: ["Add it", "Not mine"],
        chosen: nil
      }

      assert inspect(AutoDetect.decision(card, true), limit: :infinity) =~ "answer_not_mine"
      refute inspect(AutoDetect.decision(card, false), limit: :infinity) =~ "answer_"
    end

    test "Not mine forgets it and redraws" do
      Detect.ask("Some Film")

      {:noreply, after_tap} = AutoDetect.handle_tap(:answer_not_mine, screen())

      assert Detect.unsure() == []
      # The screen redraws. On a host with no bridge it redraws board 36, whose
      # decision is the drawing's — `real_decision/0` is what answers `nil`,
      # and it is asserted where it can be reached.
      assert AutoDetect.real_decision() == nil
      assert Map.has_key?(after_tap.assigns, :detect)
    end
  end

  describe "draining what was recorded while Kati was not running" do
    test "is the half that catches the case the feature exists for" do
      # `sessions/0` answers what is playing AT THIS MOMENT, and that moment is
      # one Kati is not running for: you finish an episode, close the app, and
      # the session is gone before Kati is next opened. `KatiMediaListener`
      # records instead. There is no bridge on a host, so what is asserted here
      # is the shape and the gate — the write path itself is `apply/1`, which is
      # pressed above.
      assert Detect.recorded() == []
      assert Detect.drain() == []
    end

    test "and drains nothing at all when detection is off" do
      Detect.put(false)

      assert Detect.drain() == []
    end
  end

  describe "suggesting what it might have been" do
    setup do
      anime!("Frieren: Beyond Journey's End", "Sousou no Frieren")
      shelve!("The Crown", :tv)
      :ok
    end

    test "offers the near ones as something to tap, rather than a shrug" do
      titles = Detect.suggestions_for("Frieren S1") |> Enum.map(& &1.title)

      assert "Frieren: Beyond Journey's End" in titles
    end

    test "and finds the show behind a fansub filename" do
      titles =
        Detect.suggestions_for("[SubsPlease] Sousou no Frieren - 05 (1080p).mkv")
        |> Enum.map(& &1.title)

      assert "Frieren: Beyond Journey's End" in titles
    end

    test "suggests nothing for a name that is nothing like anything" do
      assert Detect.suggestions_for("Zzzz Qqqq Wwww") == []
    end

    test "and never suggests on a shared stopword alone" do
      # `The Bear` against `The Crown` scored 0.45 before stopwords were
      # dropped — two unrelated shows offered for each other, which is exactly
      # the noise a card of guesses must not contain.
      assert Detect.suggestions_for("The Bear") == []
    end

    test "a suggestion is a suggestion — it never ticks by itself" do
      assert {:ask, _} = Detect.verdict(session("Frieren S1", 99))
      assert Ash.read!(Watch) == []
    end
  end

  describe "connecting a heard name to a title" do
    setup do
      %{tracked: shelve!("The Crown", :tv)}
    end

    test "teaches Kati the name, and ticks what was watched", %{tracked: tracked} do
      Detect.ask("Korona S02E01")

      assert {:ok, :ticked} = Detect.connect("Korona S02E01", tracked.id)

      assert [watch] = Ash.read!(Watch)
      assert watch.tracked_title_id == tracked.id
      assert watch.detected
      assert Detect.unsure() == []
    end

    test "and the same name is never asked about again", %{tracked: tracked} do
      {:ok, _} = Detect.connect("Korona", tracked.id)

      assert {:tick, matched, _e} = Detect.verdict(session("Korona", 95))
      assert matched.id == tracked.id
    end

    test "the taught name survives a cleaned filename too", %{tracked: tracked} do
      {:ok, _} = Detect.connect("Korona", tracked.id)

      assert {:tick, _t, _e} = Detect.verdict(session("Korona.S02E01.1080p.mkv", 95))
    end

    test "teaching a new answer replaces the old one", %{tracked: tracked} do
      other = shelve!("Slow Horses", :tv)

      {:ok, _} = Detect.connect("Korona", tracked.id)
      {:ok, _} = Detect.connect("Korona", other.id)

      assert length(Ash.read!(Kati.Media.TitleAlias)) == 1
      assert {:tick, matched, _e} = Detect.verdict(session("Korona", 95))
      assert matched.id == other.id
    end

    test "an alias for a title the reader has hidden is not used", %{tracked: tracked} do
      # Archiving is what "off my shelf" means here — `:shelf` is the read every
      # list in this app goes through, and `on_shelf/1` keeps the alias honest
      # to it. A taught name must not resurrect a title somebody hid.
      {:ok, _} = Detect.connect("Korona", tracked.id)

      tracked
      |> Ash.Changeset.for_update(:update, %{archived: true})
      |> Ash.update!()

      assert {:ask, "Korona"} = Detect.verdict(session("Korona", 95))
    end

    test "and connecting to a title that is gone refuses rather than half-writing" do
      assert {:error, _why} = Detect.connect("Korona", Ecto.UUID.generate())
    end
  end

  describe "the screen on a device that cannot look" do
    test "draws board 36 whole, because unavailable is not denied" do
      assert Detect.access() == :unavailable
      assert AutoDetect.detect() == AutoDetect.drawn_detect()
      refute AutoDetect.live?(AutoDetect.detect())
    end

    test "and its master switch is a picture there" do
      drawn = AutoDetect.drawn_detect()

      refute inspect(AutoDetect.banner(drawn.banner, false), limit: :infinity) =~ "toggle_detect"
      assert inspect(AutoDetect.banner(drawn.banner, true), limit: :infinity) =~ "toggle_detect"
    end

    test "the Now playing card and the decision are dropped when there are none" do
      spacer = %{type: :spacer, children: [], props: %{size: 0}}

      assert AutoDetect.playing_band(%{now_playing: nil}) == spacer
      assert AutoDetect.decision_band(%{decision: nil}) == spacer
    end
  end

  defp screen do
    AutoDetect
    |> Mob.Socket.new()
    |> Mob.Socket.assign(:detect, AutoDetect.detect())
  end

  defp session(title, percent) do
    %{
      app: "com.netflix.mediaclient",
      title: title,
      subtitle: "",
      duration_ms: 3_000_000,
      position_ms: div(3_000_000 * percent, 100),
      playing?: true
    }
  end

  defp anime!(title, original) do
    Ash.create!(CachedTitle, %{
      source: :manual,
      source_id: @prefix <> title,
      kind: :anime,
      title: title,
      title_original: original,
      fetched_at: Kati.Time.now()
    })

    Ash.create!(TrackedTitle, %{
      source: :manual,
      source_id: @prefix <> title,
      kind: :anime,
      status: :watching
    })
  end

  defp shelve!(title, kind) do
    Ash.create!(CachedTitle, %{
      source: :manual,
      source_id: @prefix <> title,
      kind: kind,
      title: title,
      fetched_at: Kati.Time.now()
    })

    Ash.create!(TrackedTitle, %{
      source: :manual,
      source_id: @prefix <> title,
      kind: kind,
      status: :watching
    })
  end

  defp episode!(tracked, title) do
    Ash.create!(CachedEpisode, %{
      source: tracked.source,
      source_id: @prefix <> "ep-" <> title,
      title_source_id: tracked.source_id,
      season_number: 1,
      episode_number: 1,
      title: title,
      fetched_at: Kati.Time.now()
    })
  end

  defp wipe! do
    Kati.Repo.query!("DELETE FROM media_watches")
    Kati.Repo.query!("DELETE FROM cached_episodes")
    Kati.Repo.query!("DELETE FROM tracked_titles")
    Kati.Repo.query!("DELETE FROM cached_titles")
  end
end
