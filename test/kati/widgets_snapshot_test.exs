defmodule Kati.Widgets.SnapshotTest do
  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedEpisode
  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Widgets.Refresher
  alias Kati.Widgets.Snapshot

  @moduletag :tmp_dir

  doctest Kati.Widgets.Launch

  setup do
    empty_the_tables!()
    on_exit(&empty_the_tables!/0)
    :ok
  end

  defp empty_the_tables! do
    Kati.Repo.query!("DELETE FROM media_watches", [])
    Kati.Repo.query!("DELETE FROM tracked_titles", [])
    Kati.Repo.query!("DELETE FROM cached_episodes", [])
    Kati.Repo.query!("DELETE FROM cached_titles", [])
  end

  defp snapshot(dir), do: JSON.decode!(File.read!(Snapshot.path(dir: dir)))

  # Where `Kati.Media.Artwork.cache/1` would have written the poster for
  # `cdn_path` — the file the widget draws, put there without a network.
  defp downloaded_poster!(cdn_path) do
    dir = Path.join(Mob.data_dir(), "artwork")
    File.mkdir_p!(dir)
    file = Path.join(dir, "w342_" <> String.trim_leading(cdn_path, "/"))
    File.write!(file, "not really a jpeg")
    on_exit(fn -> File.rm(file) end)
    file
  end

  test "drops the hero key entirely when nothing is on the go", %{tmp_dir: dir} do
    :ok = Snapshot.put(nil, dir: dir)

    body = File.read!(Snapshot.path(dir: dir))
    refute Map.has_key?(JSON.decode!(body), "hero")
  end

  test "writes the real hero, atomically", %{tmp_dir: dir} do
    hero = %{title: "The Long Hollow", meta: "S2 · E6 · 18m left"}
    :ok = Snapshot.put(hero, dir: dir)

    body = File.read!(Snapshot.path(dir: dir))

    assert %{"hero" => %{"title" => "The Long Hollow", "meta" => "S2 · E6 · 18m left"}} =
             JSON.decode!(body)

    refute File.exists?(Snapshot.path(dir: dir) <> ".tmp")
  end

  test "refresh/1 reads the real shelf and drops hero when it is empty", %{tmp_dir: dir} do
    :ok = Snapshot.refresh(dir: dir)

    body = File.read!(Snapshot.path(dir: dir))
    refute Map.has_key?(JSON.decode!(body), "hero")
  end

  test "refresh/1 writes the real title once one is watching", %{tmp_dir: dir} do
    source_id = "widget-snapshot-test"

    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: source_id,
      kind: :tv,
      title: "Ashfall",
      fetched_at: DateTime.utc_now()
    })

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: source_id,
      kind: :tv,
      status: :watching,
      progress_season: 1,
      progress_episode: 2
    })

    :ok = Snapshot.refresh(dir: dir)

    body = File.read!(Snapshot.path(dir: dir))
    assert %{"hero" => %{"title" => "Ashfall"}} = JSON.decode!(body)
  end

  describe "a title with no bookmark and no runtime" do
    # W6. The A55 wrote `{"meta":"","title":"Marram"}` — a hand-added series
    # with nothing to say on the second line, so the widget drew a blank one.

    defp hand_added!(title, kind, year) do
      Ash.create!(CachedTitle, %{
        source: :manual,
        source_id: title,
        kind: kind,
        title: title,
        first_release_year: year,
        fetched_at: Kati.Time.now()
      })

      Ash.create!(TrackedTitle, %{
        source: :manual,
        source_id: title,
        kind: kind,
        status: :watching
      })
    end

    test "says what it is, rather than nothing", %{tmp_dir: dir} do
      hand_added!("Marram", :tv, nil)

      :ok = Snapshot.refresh(dir: dir)

      assert %{"hero" => %{"title" => "Marram", "meta" => "SERIES"}} =
               JSON.decode!(File.read!(Snapshot.path(dir: dir)))
    end

    test "and when it came out, when that is known", %{tmp_dir: dir} do
      hand_added!("Estuary", :movie, 2024)

      :ok = Snapshot.refresh(dir: dir)

      assert %{"hero" => %{"meta" => "FILM · 2024"}} =
               JSON.decode!(File.read!(Snapshot.path(dir: dir)))
    end
  end

  describe "W1: the poster" do
    test "is the downloaded file's path when this device has it", %{tmp_dir: dir} do
      cdn = "/widget-poster-#{System.unique_integer([:positive])}.jpg"
      file = downloaded_poster!(cdn)

      :ok = Snapshot.put(%{title: "Ashfall", meta: "S1 · E3", seed: cdn}, dir: dir)

      assert %{"hero" => %{"poster" => ^file}} = snapshot(dir)
    end

    test "is absent, not null and not a stand-in, when nothing was downloaded", %{tmp_dir: dir} do
      :ok = Snapshot.put(%{title: "Ashfall", meta: "", seed: "/never-downloaded.jpg"}, dir: dir)

      refute Map.has_key?(snapshot(dir)["hero"], "poster")
      refute File.read!(Snapshot.path(dir: dir)) =~ "nil"
    end

    test "is never one of the design's own photographs", %{tmp_dir: dir} do
      seed = hd(Kati.Design.Images.seeds())
      assert Kati.Design.Images.poster(seed), "the seed has a sample photograph to refuse"

      :ok = Snapshot.put(%{title: "The Long Hollow", meta: "", seed: seed}, dir: dir)

      refute Map.has_key?(snapshot(dir)["hero"], "poster")
    end

    test "refresh/1 carries the real title's downloaded poster", %{tmp_dir: dir} do
      cdn = "/widget-refresh-#{System.unique_integer([:positive])}.jpg"
      file = downloaded_poster!(cdn)
      watching!("Ashfall", :tv, poster_path: cdn)

      :ok = Snapshot.refresh(dir: dir)

      assert %{"hero" => %{"title" => "Ashfall", "poster" => ^file}} = snapshot(dir)
    end
  end

  describe "W2 and W5: what a tap needs, and where it lands" do
    test "the hero carries the id and kind a tap opens", %{tmp_dir: dir} do
      tracked = watching!("Estuary", :movie)

      :ok = Snapshot.refresh(dir: dir)

      assert %{"hero" => %{"id" => id, "kind" => "movie"}} = snapshot(dir)
      assert id == tracked.id
    end

    test "the empty state's words are written, in the reader's language", %{tmp_dir: dir} do
      :ok = Snapshot.refresh(dir: dir)

      assert %{"empty" => %{"title" => "Nothing queued", "action" => "Add a title"}} =
               snapshot(dir)

      Kati.Locale.as(:fa, fn -> :ok = Snapshot.put(nil, dir: dir) end)

      assert %{"empty" => %{"title" => "چیزی در صف نیست", "action" => "افزودن عنوان"}} =
               snapshot(dir)
    end

    test "the widget's payload opens the title, from a root and from anywhere" do
      film = %{data: %{kati_open: "title", id: "abc", kind: "movie"}}

      assert {:noreply, socket} =
               Kati.Screens.Home.handle_info(
                 {:notification, film},
                 Mob.Socket.new(Kati.Screens.Home)
               )

      assert {:push, Kati.Screens.Film, %{id: "abc"}} = socket.__mob__.nav_action

      series = %{data: %{kati_open: "title", id: "def", kind: "tv"}}
      socket = Kati.Widgets.Launch.open(Mob.Socket.new(Kati.Screens.Library), series)
      assert {:push, Kati.Screens.Series, %{id: "def"}} = socket.__mob__.nav_action
    end

    test "the empty state's payload opens the add sheet" do
      assert {:noreply, socket} =
               Kati.Screens.Home.handle_info(
                 {:notification, %{data: %{kati_open: "add"}}},
                 Mob.Socket.new(Kati.Screens.Home)
               )

      assert {:push, Kati.Screens.AddTitle, _params} = socket.__mob__.nav_action
    end

    test "a notification that is not the widget's navigates nowhere" do
      socket = Mob.Socket.new(Kati.Screens.Home)

      assert {:noreply, ^socket} =
               Kati.Screens.Home.handle_info({:notification, %{data: %{}}}, socket)
    end

    test "a tap on a running app is forwarded to the router untouched" do
      start_supervised!({Kati.Native.TapRelay, to: self(), name: :widget_test_relay})
      json = ~s({"id":"kati_widget","data":{"kati_open":"add"}})

      send(:widget_test_relay, {:mob_launch_notification, json})

      assert_receive {:mob_launch_notification, ^json}
    end
  end

  describe "W3: the writes that move the hero refresh it" do
    setup %{tmp_dir: dir} do
      start_supervised!({Refresher, dir: dir, delay: 60_000})
      assert :ok = Refresher.flush()
      assert :idle = Refresher.flush()
      :ok
    end

    test "ticking an episode", %{tmp_dir: dir} do
      series = watching!("Ashfall", :tv, episode_count: 3)
      episodes!(series, [{1, 1}, {1, 2}, {1, 3}])
      assert :ok = Refresher.flush()
      assert snapshot(dir)["hero"]["meta"] =~ "S1 · E1"

      assert :ok =
               Kati.Screens.Series.tick_result(series.id, %{
                 source_id: ep_id(series, 1, 1),
                 watched: false,
                 season: 1,
                 n: 1
               })

      assert :ok = Refresher.flush()
      assert snapshot(dir)["hero"]["meta"] =~ "S1 · E2"
    end

    test "logging a film watch finishes it and takes it off the widget", %{tmp_dir: dir} do
      film = watching!("Estuary", :movie, runtime_minutes: 116)
      assert :ok = Refresher.flush()
      assert snapshot(dir)["hero"]["title"] == "Estuary"

      assert {:ok, _watch} =
               Kati.Screens.Rating.save_watch(%{
                 watch_id: nil,
                 tracked_title_id: film.id,
                 watch: %{rating: 4.0, review: nil}
               })

      assert :ok = Refresher.flush()
      refute Map.has_key?(snapshot(dir), "hero")
    end

    for status <- [:paused, :dropped, :finished] do
      test "a status change to #{status}", %{tmp_dir: dir} do
        tracked = watching!("Marram", :tv)
        assert :ok = Refresher.flush()
        assert snapshot(dir)["hero"]["title"] == "Marram"

        tracked
        |> Ash.Changeset.for_update(:update, %{status: unquote(status)})
        |> Ash.update!()

        assert :ok = Refresher.flush()
        refute snapshot(dir)["hero"]["title"] == "Marram"
      end
    end

    test "adding a title", %{tmp_dir: dir} do
      refute Map.has_key?(snapshot(dir), "hero")

      # `:watching`, screen 163's add: a title added from 06 is not started
      # (N52-C) and has no business in the hero, so only an add that says the
      # reader is watching it can move one.
      assert {:ok, _tracked} =
               Kati.Screens.AddTitle.track("Widget Added", %{kind: :tv}, :watching)

      assert :ok = Refresher.flush()
      assert snapshot(dir)["hero"]["title"] == "Widget Added"
    end

    test "removing a title", %{tmp_dir: dir} do
      tracked = watching!("Marram", :tv)
      assert :ok = Refresher.flush()

      assert :ok = Kati.Screens.Series.remove(%{tracked_id: tracked.id})

      assert :ok = Refresher.flush()
      refute Map.has_key?(snapshot(dir), "hero")
    end

    test "a burst of writes is one refresh" do
      for n <- 1..5, do: watching!("Burst #{n}", :tv)

      assert :ok = Refresher.flush()
      assert :idle = Refresher.flush()
    end
  end

  defp watching!(title, kind, cached \\ []) do
    source_id = "widget-#{System.unique_integer([:positive])}"

    Ash.create!(
      CachedTitle,
      Map.merge(
        %{
          source: :manual,
          source_id: source_id,
          kind: kind,
          title: title,
          fetched_at: DateTime.utc_now() |> DateTime.truncate(:second)
        },
        Map.new(cached)
      )
    )

    Ash.create!(TrackedTitle, %{
      source: :manual,
      source_id: source_id,
      kind: kind,
      status: :watching
    })
  end

  defp ep_id(tracked, season, number), do: "#{tracked.source_id}-s#{season}e#{number}"

  defp episodes!(tracked, pairs) do
    for {season, number} <- pairs do
      Ash.create!(CachedEpisode, %{
        source: tracked.source,
        source_id: ep_id(tracked, season, number),
        title_source_id: tracked.source_id,
        season_number: season,
        episode_number: number,
        title: "S#{season}E#{number}",
        fetched_at: DateTime.utc_now() |> DateTime.truncate(:second)
      })
    end
  end
end
