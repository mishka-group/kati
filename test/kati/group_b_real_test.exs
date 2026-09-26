Code.require_file("../support/design_literals.exs", __DIR__)

defmodule Kati.GroupBRealTest do
  @moduledoc """
  N52-B: the six film-and-series sheets a reader can open — 33 Log a watch,
  144 Rate an episode, 149 the drop sheet, 13 What fits, 152 Anime and 36
  Auto-detect — draw the store or an honest empty state, and never a board.

  Each is asked twice: over an empty store (and a push naming a row that does
  not exist), where no word of its board may appear, and over a seeded store,
  where the seeded values must. The board words checked for are the ones the
  deleted sample modules held — a reader who met any of them was reading
  somebody else's shelf.

  V22 is here too: a refused save leaves screen 33 up, with the stars and the
  typed review intact and a red line under the header.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedEpisode
  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Screens.AnimeFilter
  alias Kati.Screens.AutoDetect
  alias Kati.Screens.DropSheet
  alias Kati.Screens.RateEpisode
  alias Kati.Screens.Rating
  alias Kati.Screens.WhatFits
  alias Kati.Theme.Palette

  @tables ~w(media_watches media_content_warnings cached_episodes tracked_titles cached_titles)

  @rating_board ["Blue Hour", "184 characters", "2nd rewatch", "Lumen+", "slow burn", "Jo"]
  @episode_board ["The Undertow", "The Long Hollow", "Tonight · 21:40", "Lumen+", "Jo"]
  @drop_board ["The Quiet Ones", "GONE COLD · 4 MONTHS"]
  @fits_board ["Ashfall", "Marram", "Salt & Iron", "Quiet Harbour", "Sunday, 21:40", "Tomorrow"]
  @anime_board ["Marram", "Tagged anime from a MAL import — it is live action"]
  @detect_board [
    "3 sources",
    "41 EPISODES TICKED FOR YOU",
    "The Long Hollow",
    "Apple TV",
    "Chromecast",
    "Browser extension",
    "Ask before ticking",
    "Marram"
  ]

  setup do
    wipe!()
    Mob.State.put(:detect_unsure, [])
    Kati.Rating.Scale.put(:stars)

    on_exit(&wipe!/0)

    :ok
  end

  describe "33 Log a watch" do
    test "a bare push over an empty store draws one sentence, no fields and no Save" do
      view = mount_screen(Rating, %{})

      assert_no_board(view, @rating_board)
      assert "There is no title here to log a watch of." in strings(view)
      refute :save in tap_tags(view)
      assert find(view, :text_field, accessibility_id: "review") == nil
      refute Enum.any?(tap_tags(view), &Rating.point_of/1)
    end

    test "a push naming a title that does not exist is the same empty sheet" do
      view = mount_screen(Rating, %{tracked_title_id: Ecto.UUID.generate()})

      assert_no_board(view, @rating_board)
      assert Rating.empty?(assigns(view).watch)
      refute :save in tap_tags(view)
    end

    test "a real title draws its own name, its stars and Save" do
      tracked = film!("Estuary", 96)

      view = mount_screen(Rating, %{tracked_title_id: tracked.id, new: true})

      assert "Estuary" in strings(view)
      assert :save in tap_tags(view)
      assert :star_9 in tap_tags(view)
      assert_no_board(view, @rating_board)
    end
  end

  describe "V22 — a refused save on screen 33" do
    setup do
      tracked = film!("Estuary", 96)

      Ash.create!(Watch, %{
        tracked_title_id: tracked.id,
        watched_on: ~D[2026-08-02],
        watched_at: ~U[2026-08-02 20:30:00.000000Z],
        review: "Placeholder."
      })

      %{tracked: tracked}
    end

    test "keeps the sheet up with the stars and the typed text, and a red line under the header",
         %{tracked: tracked} do
      view =
        mount_screen(Rating, %{tracked_title_id: tracked.id})
        |> render_info({:tap, :star_7})
        |> render_info({:change, :review, "Typed before the store said no."})

      Enum.each(Ash.read!(Watch), &Ash.destroy!/1)

      view = render_info(view, {:tap, :save})
      error = assigns(view).save_error

      assert navigated_to(view) == nil, "the sheet closed on a save that did not land"
      assert is_binary(error) and error != ""

      texts = text_nodes(view)
      header = Enum.find_index(texts, &(&1.props.text == "Log a watch"))
      notice = Enum.find_index(texts, &(&1.props.text == error))
      title = Enum.find_index(texts, &(&1.props.text == "Estuary"))

      assert header < notice and notice < title, "the refusal is not under the header"
      assert Enum.at(texts, notice).props.text_color == Palette.red()

      assert assigns(view).watch.rating == 3.5
      assert find(view, :text, text: "3.5") != nil, "the tapped stars are gone"

      assert %{props: %{value: "Typed before the store said no."}} =
               find(view, :text_field, accessibility_id: "review")

      assert Ash.read!(Watch) == []
    end

    test "and a new watch of a title removed under the sheet refuses the same way",
         %{tracked: tracked} do
      view =
        mount_screen(Rating, %{tracked_title_id: tracked.id, new: true})
        |> render_info({:tap, :star_4})
        |> render_info({:change, :review, "Still here."})

      Enum.each(Ash.read!(Watch), &Ash.destroy!/1)
      Ash.destroy!(tracked)

      view = render_info(view, {:tap, :save})

      assert navigated_to(view) == nil
      assert is_binary(assigns(view).save_error)
      assert assigns(view).watch.rating == 2.0
      assert assigns(view).watch.review == "Still here."
      assert Ash.read!(Watch) == []
    end
  end

  describe "144 Rate an episode" do
    test "a bare push over an empty store draws one sentence and no Save" do
      view = mount_screen(RateEpisode, %{})

      assert_no_board(view, @episode_board)
      assert "There is no episode here to rate." in strings(view)
      refute :save in tap_tags(view)
      refute Enum.any?(tap_tags(view), &Rating.point_of/1)
    end

    test "a pair that names nothing is the empty sheet, even with another episode logged" do
      tracked = series!()
      :ok = Kati.Screens.Series.write_tick(tracked.id, %{source_id: "grpb-ep", watched: false})

      view =
        mount_screen(RateEpisode, %{
          tracked_id: Ecto.UUID.generate(),
          episode_source_id: "grpb-ep"
        })

      assert assigns(view).sheet == RateEpisode.empty_sheet()
      refute "Trojan's Horse" in strings(view)
    end

    test "a real episode draws its own name, and Save writes the rating and the review" do
      tracked = series!()

      view =
        mount_screen(RateEpisode, %{tracked_id: tracked.id, episode_source_id: "grpb-ep"})

      assert "S2 E5 · Trojan's Horse" in strings(view)
      assert "Severance" in strings(view)
      assert_no_board(view, @episode_board)

      saved =
        view
        |> render_info({:tap, :star_8})
        |> render_info({:change, :review, "The elevator scene."})
        |> render_info({:tap, :save})

      assert navigated_to(saved) == {:pop}
      assert [%{rating: 8, review: "The elevator scene."}] = Ash.read!(Watch)
    end
  end

  describe "149 the drop sheet" do
    test "no row, or a row that does not exist, is one sentence and no controls" do
      for params <- [%{}, %{title_id: Ecto.UUID.generate()}] do
        view = mount_screen(DropSheet, params)

        assert_no_board(view, @drop_board)
        assert "There is no title here to drop." in strings(view)
        refute :drop in tap_tags(view)
      end
    end

    test "a real paused show draws its own name" do
      cached!("grpb-show", :tv, "Dark", nil)

      tracked =
        Ash.create!(TrackedTitle, %{
          source: :tmdb,
          source_id: "grpb-show",
          kind: :tv,
          status: :paused
        })

      view = mount_screen(DropSheet, %{title_id: tracked.id})

      assert "Dark" in strings(view)
      assert :drop in tap_tags(view)
      assert_no_board(view, @drop_board)
    end
  end

  describe "13 What fits" do
    test "an empty shelf says so, with the reader's own clock" do
      view = mount_screen(WhatFits, %{})

      assert_no_board(view, @fits_board)
      assert "Nothing on your shelf to measure yet" in strings(view)
      refute glyph?(view, "more_horiz")
    end

    test "a film on the shelf is measured against the window" do
      film!("Estuary", 40)
      film!("Longshore", 130)

      view = mount_screen(WhatFits, %{})

      assert "Estuary" in strings(view)
      assert "Longshore" in strings(view)
      assert_no_board(view, @fits_board)
    end
  end

  describe "152 Anime" do
    test "an empty shelf counts nothing and draws no guess" do
      view = mount_screen(AnimeFilter, %{})

      assert_no_board(view, @anime_board)
      assert assigns(view).anime.misclassified == nil
      refute :fix_misclassified in tap_tags(view)
    end

    test "a title filed as anime is the guess, under its own name and poster" do
      cached!("grpb-anime", :tv, "Frieren", "/frieren.jpg")

      tracked =
        Ash.create!(TrackedTitle, %{
          source: :tmdb,
          source_id: "grpb-anime",
          kind: :anime,
          status: :watching
        })

      view = mount_screen(AnimeFilter, %{})

      assert "Frieren" in strings(view)
      assert %{id: id, seed: "/frieren.jpg"} = assigns(view).anime.misclassified
      assert id == tracked.id
      assert_no_board(view, @anime_board)

      render_info(view, {:tap, :fix_misclassified})
      assert Ash.get!(TrackedTitle, tracked.id).anime_override == false
    end
  end

  describe "36 Auto-detect" do
    test "a phone that has detected nothing draws its own state, and no overflow disc" do
      view = mount_screen(AutoDetect, %{})

      assert_no_board(view, @detect_board)
      assert "NOTHING TICKED FOR YOU YET" in strings(view)
      refute glyph?(view, "more_horiz")
      assert Enum.all?(tap_tags(view), &(&1 != :open_retired))
    end

    test "a name Kati heard and could not place is the question, in its own words" do
      Kati.Media.Detect.ask("Some Film")

      view = mount_screen(AutoDetect, %{})

      assert Enum.any?(strings(view), &(&1 =~ "Some Film"))
      assert_no_board(view, @detect_board)
    end
  end

  defp assert_no_board(view, words) do
    drawn = strings(view)

    leaked = for word <- words, Enum.any?(drawn, &String.contains?(&1, word)), do: word

    assert leaked == [], "board words reached a reader's screen: #{inspect(leaked)}"
  end

  defp strings(view) do
    for node <- flatten(view),
        key <- [:text, :placeholder, :label, :value],
        value = Map.get(node.props || %{}, key),
        is_binary(value),
        do: value
  end

  defp text_nodes(view) do
    view
    |> flatten()
    |> Enum.filter(&(&1.type == :text and is_binary(Map.get(&1.props || %{}, :text))))
  end

  defp tap_tags(view) do
    for node <- flatten(view),
        handler <- [Map.get(node.props || %{}, :on_tap), Map.get(node.props || %{}, :on_change)],
        {_pid, tag} <- [handler],
        is_atom(tag),
        do: tag
  end

  defp glyph?(view, name) do
    glyph = Kati.Icons.glyph!(name)
    Enum.any?(strings(view), &(&1 == glyph))
  end

  defp film!(title, minutes) do
    source_id = "grpb-" <> String.downcase(title)
    cached!(source_id, :movie, title, nil, minutes)

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: source_id,
      kind: :movie,
      status: :not_started
    })
  end

  defp series! do
    cached!("grpb-series", :tv, "Severance", nil)

    Ash.create!(CachedEpisode, %{
      source: :tmdb,
      title_source_id: "grpb-series",
      source_id: "grpb-ep",
      season_number: 2,
      episode_number: 5,
      title: "Trojan's Horse",
      runtime_minutes: 47,
      fetched_at: Kati.Time.now()
    })

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: "grpb-series",
      kind: :tv,
      status: :watching
    })
  end

  defp cached!(source_id, kind, title, poster, minutes \\ nil) do
    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: source_id,
      kind: kind,
      title: title,
      poster_path: poster,
      runtime_minutes: minutes,
      fetched_at: Kati.Time.now()
    })
  end

  defp wipe! do
    for table <- @tables, do: Kati.Repo.query!("DELETE FROM " <> table, [])
    :ok
  end
end
