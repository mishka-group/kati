defmodule Kati.ImportTest do
  @moduledoc """
  The importer, which screens 140, 141 and 37 were three drawings of.

  MOVIES-AND-TV.md #101: screen 37 had zero controls — the **Import 412**
  commit pill, the step meter and the three conflict answers were all pictures,
  and because none carried a tag the tap sweep could not see the screen at all.
  There was nothing behind them either: no parser, no mapping, no plan.

  What is asserted here is the whole path, in the order a reader walks it: a
  file is read, its columns are matched by their headers, its rows are counted
  against the shelf as *new*, *merged* or *conflict*, and only then is anything
  written. The last of those is the one worth holding down hardest — an import
  that guesses at a disagreement is an import that quietly destroys a rating,
  which is what the conflict card exists to prevent.
  """

  use Mob.ScreenCase, async: false

  doctest Kati.Import.Csv, only: [read: 1, rows: 1]

  doctest Kati.Import.Mapping, only: [field_for: 1, key: 1, value: 3, ten_point: 2, date: 1]

  doctest Kati.Import.Job, only: [name_key: 1, stars: 1]

  doctest Kati.Import.Commit, only: [watch?: 1]

  doctest Kati.Screens.Import, only: [result_line: 1, answer_tag: 2, live?: 1]

  doctest Kati.Screens.ImportRecognised, only: [live?: 1, source_name: 1]

  alias Kati.Import.Commit
  alias Kati.Import.Job
  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Screens.Import, as: Screen
  alias Kati.Screens.ImportRecognised, as: Recognised

  @prefix "import-test-"

  setup do
    on_exit(&wipe!/0)
    wipe!()
    :ok
  end

  describe "reading a file" do
    test "maps the columns it knows and skips the ones it does not" do
      {:ok, job} = read(letterboxd())

      by_column = Map.new(job.columns, &{&1.column, &1})

      assert by_column["Name"].field == "Title"
      assert by_column["Watched Date"].field == "Watched on"
      assert by_column["Rating"].field == "Rating"
      assert by_column["Letterboxd URI"].skipped?
      assert by_column["Letterboxd URI"].field == "Skipped"
    end

    test "and samples the first data row beside each" do
      {:ok, job} = read(letterboxd())

      assert Enum.find(job.columns, &(&1.column == "Name")).sample == "Arrival"
    end

    test "counts the file the way both boards print it" do
      {:ok, job} = read(letterboxd())

      assert job.shape == "3 ROWS · 4 COLUMNS"
      assert job.file == "watched.csv"
    end

    test "refuses a file whose headers name nothing Kati can use" do
      assert {:error, :unrecognised} = read("Publisher,Binding\nSaltmarsh,Paperback\n")
    end

    test "refuses an empty file, and one it cannot open" do
      assert {:error, :empty} = read("")
      assert {:error, :unreadable} = Job.read("/no/such/file.csv", "gone.csv")
    end

    test "reads a review with a newline in it, which is where a splitter fails" do
      csv = ~s(Name,Review\n"Dune","Two lines\nof it"\n)

      {:ok, job} = read(csv)

      assert [%{review: "Two lines\nof it"}] = job.records
    end
  end

  describe "the plan, before anything is written" do
    test "counts a shelf it has never seen as all new" do
      {:ok, job} = read(letterboxd())

      assert length(job.plan.new) == 3
      assert job.plan.merged == []
      assert job.plan.conflicts == []
      assert job.action == "Import 3"
    end

    test "counts a title already on the shelf as merged" do
      shelve!("Arrival", :movie)

      {:ok, job} = read(letterboxd())

      assert Enum.map(job.plan.merged, & &1.title) == ["Arrival"]
      assert length(job.plan.new) == 2
    end

    test "matches by name, case and whitespace aside" do
      shelve!("arrival ", :movie)

      {:ok, job} = read(letterboxd())

      assert length(job.plan.merged) == 1
    end

    test "merges an export that names a show by its original title" do
      # The same widening detection got: one show has two names, and an export
      # that used the other one would otherwise create a second copy of a title
      # the reader already has.
      Ash.create!(CachedTitle, %{
        source: :manual,
        source_id: @prefix <> "frieren",
        kind: :anime,
        title: "Frieren: Beyond Journey's End",
        title_original: "Sousou no Frieren",
        fetched_at: Kati.Time.now()
      })

      Ash.create!(TrackedTitle, %{
        source: :manual,
        source_id: @prefix <> "frieren",
        kind: :anime,
        status: :watching
      })

      {:ok, job} = read("Name,Rating\nSousou no Frieren,4\n")

      assert Enum.map(job.plan.merged, & &1.title) == ["Sousou no Frieren"]
      assert job.plan.new == []
    end

    test "and writes nothing while it counts" do
      shelve!("Arrival", :movie)
      before = length(Ash.read!(Watch))

      {:ok, _job} = read(letterboxd())

      assert length(Ash.read!(Watch)) == before
    end
  end

  describe "a conflict" do
    setup do
      tracked = shelve!("Arrival", :movie)
      watch!(tracked, ~D[2026-08-12], 8)
      %{tracked: tracked}
    end

    test "is one rating disagreeing with another about one day" do
      {:ok, job} = read(letterboxd())

      assert [clash] = job.plan.conflicts
      assert clash.title == "Arrival"
      assert clash.mine == 8
      assert clash.theirs == 9
      assert job.plan.merged == []
    end

    test "and the card says both, in stars" do
      {:ok, job} = read(letterboxd())

      assert job.conflict.title == "Arrival"
      assert job.conflict.line =~ "yours ★4"
      assert job.conflict.line =~ "file ★4.5"
      assert job.conflict.progress == "1 of 1 · apply to all"
    end

    test "nothing is lit until the reader answers" do
      {:ok, job} = read(letterboxd())

      assert Enum.all?(job.conflict.choices, fn {_label, on?} -> not on? end)
    end

    test "the same rating on the same day is not a conflict", %{tracked: tracked} do
      Ash.read!(Watch) |> Enum.each(&Ash.destroy!/1)
      watch!(tracked, ~D[2026-08-12], 9)

      {:ok, job} = read(letterboxd())

      assert job.plan.conflicts == []
      assert length(job.plan.merged) == 1
    end

    test "and a different day is two watches rather than a disagreement", %{tracked: tracked} do
      Ash.read!(Watch) |> Enum.each(&Ash.destroy!/1)
      watch!(tracked, ~D[2020-01-01], 4)

      {:ok, job} = read(letterboxd())

      assert job.plan.conflicts == []
    end
  end

  describe "committing" do
    test "creates the titles it called new, and logs their watches" do
      {:ok, job} = read(letterboxd())

      assert {:ok, tally} = Commit.run(job)
      assert tally.new == 3
      assert tally.failed == 0

      names = Ash.read!(CachedTitle) |> Enum.map(& &1.title) |> Enum.sort()
      assert names == ["Arrival", "Dune", "Severance"]

      assert Enum.all?(Ash.read!(TrackedTitle), &(&1.source == :import))
    end

    test "and a row that is only a title writes no watch" do
      {:ok, job} = read("Name\nWatchlisted\n")

      {:ok, _tally} = Commit.run(job)

      assert Ash.read!(Watch) == []
      assert [%{title: "Watchlisted"}] = Ash.read!(CachedTitle)
    end

    test "merges into a title already on the shelf without re-describing it" do
      tracked = shelve!("Arrival", :movie)

      {:ok, job} = read(letterboxd())
      {:ok, tally} = Commit.run(job)

      assert tally.merged == 1
      assert [watch] = Ash.read!(Watch) |> Enum.filter(&(&1.tracked_title_id == tracked.id))
      assert watch.rating == 9
      assert watch.watched_on == ~D[2026-08-12]
      assert length(Ash.read!(TrackedTitle)) == 3, "two new plus the one already there"
    end

    test "Keep mine changes nothing" do
      tracked = shelve!("Arrival", :movie)
      watch!(tracked, ~D[2026-08-12], 8)

      {:ok, job} = read(letterboxd())
      clash = hd(job.plan.conflicts)

      {:ok, _tally} = Commit.run(job, %{clash.watch_id => :keep_mine})

      assert Ash.get!(Watch, clash.watch_id).rating == 8
    end

    test "and so does saying nothing at all" do
      tracked = shelve!("Arrival", :movie)
      watch!(tracked, ~D[2026-08-12], 8)

      {:ok, job} = read(letterboxd())
      clash = hd(job.plan.conflicts)

      {:ok, _tally} = Commit.run(job, %{})

      assert Ash.get!(Watch, clash.watch_id).rating == 8
    end

    test "Take file replaces the rating on the watch that was there" do
      tracked = shelve!("Arrival", :movie)
      watch!(tracked, ~D[2026-08-12], 8)

      {:ok, job} = read(letterboxd())
      clash = hd(job.plan.conflicts)

      {:ok, tally} = Commit.run(job, %{clash.watch_id => :take_file})

      assert tally.resolved == 1
      assert Ash.get!(Watch, clash.watch_id).rating == 9
    end

    test "Keep both leaves the first and writes the second" do
      tracked = shelve!("Arrival", :movie)
      watch!(tracked, ~D[2026-08-12], 8)

      {:ok, job} = read(letterboxd())
      clash = hd(job.plan.conflicts)

      {:ok, _tally} = Commit.run(job, %{clash.watch_id => :keep_both})

      mine = Ash.read!(Watch) |> Enum.filter(&(&1.tracked_title_id == tracked.id))

      assert Enum.map(mine, & &1.rating) |> Enum.sort() == [8, 9]
    end
  end

  describe "screen 141's own Import pill" do
    test "commits a file that disagrees with nothing, in one press" do
      socket = recognised(letterboxd())

      assert Recognised.live?(socket.assigns.job)

      {:noreply, done} = Recognised.handle_tap(:commit, socket)

      assert done.assigns.result == "3 added."
      assert length(Ash.read!(TrackedTitle)) == 3
    end

    test "and hands the reader to 37 when there is a queue to answer" do
      tracked = shelve!("Arrival", :movie)
      watch!(tracked, ~D[2026-08-12], 8)

      socket = recognised(letterboxd())

      {:noreply, moved} = Recognised.handle_tap(:commit, socket)

      assert {:push, Screen, %{back: "Recognised"}} = Map.get(moved.__mob__, :nav_action)
      # Nothing written: silence reads as "keep mine", and that is not a
      # decision to make on somebody's behalf without showing them.
      assert Ash.read!(Watch) |> length() == 1, "only the watch the fixture made"
    end

    test "and the board's pill is a picture, as 37's is" do
      drawn = Recognised.job_for(%{})

      refute Recognised.live?(drawn)
      refute inspect(Recognised.header(drawn), limit: :infinity) =~ "commit"

      assert inspect(Recognised.header(Recognised.job_for(file(letterboxd()))), limit: :infinity) =~
               "commit"
    end

    test "and pressing it on the board writes nothing" do
      socket =
        Recognised
        |> Mob.Socket.new()
        |> Mob.Socket.assign(:job, Recognised.job_for(%{}))
        |> Mob.Socket.assign(:file, {nil, nil})
        |> Mob.Socket.assign(:result, nil)

      {:noreply, after_tap} = Recognised.handle_tap(:commit, socket)

      assert Ash.read!(TrackedTitle) == []
      assert Map.get(after_tap.__mob__, :nav_action) == nil
    end
  end

  describe "screen 37" do
    test "draws the board when the push named no file" do
      assert Screen.job_for(%{}) == Kati.Import.Sample.job(:trakt)
      refute Screen.live?(Screen.job_for(%{}))
    end

    test "and the board's Import pill is not a control" do
      refute inspect(Screen.header(Screen.job_for(%{})), limit: :infinity) =~ "commit"
    end

    test "draws the file when the push named one" do
      path = write!(letterboxd())
      job = Screen.job_for(%{path: path, name: "watched.csv"})

      assert Screen.live?(job)
      assert job.action == "Import 3"
      assert inspect(Screen.header(job), limit: :infinity) =~ "commit"
    end

    test "falls back to the board and says why when the file cannot be read" do
      job = Screen.job_for(%{path: "/no/such.csv", name: "no-such.csv"})

      refute Screen.live?(job)
      assert job.refusal == :unreadable
    end

    test "answering a conflict lights it and advances the queue" do
      tracked = shelve!("Arrival", :movie)
      watch!(tracked, ~D[2026-08-12], 8)

      socket = sheet(letterboxd())

      {:noreply, answered} = Screen.handle_tap(:answer_take_file, socket)

      assert map_size(answered.assigns.answers) == 1
      assert answered.assigns.at == 1
      # One conflict, so answering it closes the card.
      assert answered.assigns.job.conflict == nil
    end

    test "apply to all answers the whole queue with what was just chosen" do
      one = shelve!("Arrival", :movie)
      two = shelve!("Dune", :movie)
      watch!(one, ~D[2026-08-12], 8)
      watch!(two, ~D[2026-07-01], 4)

      socket = sheet(letterboxd())
      assert length(socket.assigns.job.conflicts) == 2

      {:noreply, chosen} = Screen.handle_tap(:answer_take_file, socket)
      {:noreply, all} = Screen.handle_tap(:all_take_file, chosen)

      assert map_size(all.assigns.answers) == 2
      assert Enum.all?(Map.values(all.assigns.answers), &(&1 == :take_file))
      assert all.assigns.job.conflict == nil
    end

    test "and apply to all is not offered before an answer is given" do
      tracked = shelve!("Arrival", :movie)
      watch!(tracked, ~D[2026-08-12], 8)

      socket = sheet(letterboxd())
      card = socket.assigns.job.conflict

      refute inspect(Screen.apply_to_all(card, true), limit: :infinity) =~ "all_"

      {:noreply, answered} = Screen.handle_tap(:answer_keep_both, socket)
      _ = answered
    end

    test "renders a file that conflicts with nothing, which is the ordinary case" do
      # `conflict/1` drew `job.conflict` unconditionally and
      # `conflict_poster/1` raised a `BadMapError` on `nil`, which took the
      # screen process with it and threw the reader back to Home. Every test
      # that rendered 37 used the fixture, which always has a conflict, and
      # every test that read a file stopped at the plan.
      path = write!(letterboxd())
      job = Screen.job_for(%{path: path, name: "watched.csv"})

      assert job.conflict == nil
      assert Screen.conflicts_band(job) == %{type: :spacer, children: [], props: %{size: 0}}
      assert %{type: :scroll} = Screen.content(%{job: job, result: nil})
    end

    test "and draws the band when there is something to answer" do
      tracked = shelve!("Arrival", :movie)
      watch!(tracked, ~D[2026-08-12], 8)

      socket = sheet(letterboxd())

      assert inspect(Screen.conflicts_band(socket.assigns.job), limit: :infinity) =~
               "KEEP WHICH?"
    end

    test "the commit pill writes, and says what it did" do
      socket = sheet(letterboxd())

      {:noreply, done} = Screen.handle_tap(:commit, socket)

      assert done.assigns.result == "3 added."
      assert length(Ash.read!(TrackedTitle)) == 3
    end

    test "and refuses on the board rather than filing the drawing's 412 titles" do
      socket =
        Screen
        |> Mob.Socket.new()
        |> Mob.Socket.assign(:job, Screen.job_for(%{}))
        |> Mob.Socket.assign(:answers, %{})
        |> Mob.Socket.assign(:at, 0)
        |> Mob.Socket.assign(:result, nil)

      {:noreply, refused} = Screen.handle_tap(:commit, socket)

      assert refused.assigns.result =~ "Nothing to save"
      assert Ash.read!(TrackedTitle) == []
    end
  end

  defp sheet(csv) do
    path = write!(csv)

    Screen
    |> Mob.Socket.new()
    |> Mob.Socket.assign(:job, Screen.job_for(%{path: path, name: "watched.csv"}))
    |> Mob.Socket.assign(:answers, %{})
    |> Mob.Socket.assign(:at, 0)
    |> Mob.Socket.assign(:result, nil)
  end

  defp read(csv), do: Job.read(write!(csv), "watched.csv")

  defp file(csv), do: %{path: write!(csv), name: "watched.csv"}

  defp recognised(csv) do
    Recognised
    |> Mob.Socket.new()
    |> Mob.Socket.assign(:job, Recognised.job_for(file(csv)))
    |> Mob.Socket.assign(:file, {nil, nil})
    |> Mob.Socket.assign(:result, nil)
  end

  defp write!(csv) do
    path = Path.join(System.tmp_dir!(), "#{@prefix}#{System.unique_integer([:positive])}.csv")
    File.write!(path, csv)
    on_exit(fn -> File.rm(path) end)
    path
  end

  # Letterboxd's own header, less the columns nothing reads.
  defp letterboxd do
    """
    Name,Watched Date,Rating,Letterboxd URI
    Arrival,2026-08-12,4.5,https://letterboxd.com/x
    Dune,2026-07-01,5,https://letterboxd.com/y
    Severance,,,https://letterboxd.com/z
    """
  end

  defp shelve!(title, kind) do
    Ash.create!(CachedTitle, %{
      source: :manual,
      source_id: @prefix <> title,
      kind: kind,
      title: String.trim(title),
      fetched_at: Kati.Time.now()
    })

    Ash.create!(TrackedTitle, %{
      source: :manual,
      source_id: @prefix <> title,
      kind: kind,
      status: :watching
    })
  end

  defp watch!(tracked, day, rating) do
    Ash.create!(Watch, %{
      tracked_title_id: tracked.id,
      rating: rating,
      watched_on: day,
      watched_at: DateTime.truncate(Kati.Time.now(), :second)
    })
  end

  defp wipe! do
    Kati.Repo.query!("DELETE FROM media_watches")
    Kati.Repo.query!("DELETE FROM tracked_titles")
    Kati.Repo.query!("DELETE FROM cached_titles")
  end
end
