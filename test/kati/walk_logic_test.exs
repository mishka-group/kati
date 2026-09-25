defmodule Kati.WalkLogicTest do
  @moduledoc """
  The logic half of the device-walk items in `fake_hardcoded.md` — V15–V17,
  V21, V22, V29, V30, V32, V33 and V36 — each one a claim the walk list makes
  about a screen, asked of the store and the socket rather than of a phone.

  The visual half of each (where a line sits on a real screen, what the stars
  look like at 26sp) is walked on the emulator; what is here is everything a
  host can settle, so the walk only has to look.

  V26, V30's keystroke half and V31 are not repeated: `Kati.SearchRunTest`'s
  *the history the field keeps* and `Kati.ServiceWriteTest`'s *a save that
  cannot land* and *the row that changed* already pin them.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Screens.AddByHand
  alias Kati.Screens.CountryPicker
  alias Kati.Screens.MyServices
  alias Kati.Screens.Rating
  alias Kati.Screens.Search, as: SearchScreen
  alias Kati.Screens.SearchIdle
  alias Kati.Search
  alias Kati.Services
  alias Kati.Services.Service
  alias Kati.Theme.Palette

  @prefix "walklogic-"

  # Child first: a watch carries the foreign key.
  @tables ~w(media_watches media_content_warnings cached_episodes tracked_titles cached_titles)

  setup do
    wipe!()
    on_exit(&wipe!/0)
    :ok
  end

  defp wipe! do
    for table <- @tables, do: Kati.Repo.query!("DELETE FROM " <> table, [])
    Kati.Repo.query!("DELETE FROM services WHERE name LIKE ?1", [@prefix <> "%"])
    :ok
  end

  describe "V15–V17 — screen 19's field and the minimum" do
    setup do
      Search.Recent.forget!()
      Search.Recent.remember("estuary")
      :ok
    end

    test "V15: one Latin character holds the idle state, not a nothing-found" do
      view = mount_screen(SearchScreen, %{query: ""}) |> render_info({:change, :query, "d"})

      assert assigns(view).results.idle?, "one Latin letter ran a query"
      refute :look_up in tap_tags(view), "one Latin letter drew the nothing-found card"
      refute :add_by_hand in tap_tags(view)

      assert Search.Recent.all() == ["estuary"], "a query too short to run was remembered"

      assert SearchIdle.query_tag("repeat_query", "estuary") in tap_tags(view),
             "the idle page lost the recent shelf"
    end

    test "V16: one Persian character runs the query, and finds a title by it" do
      title!("walk-fa", "کتاب خانه")

      view = mount_screen(SearchScreen, %{query: ""}) |> render_info({:change, :query, "ک"})

      refute assigns(view).results.idle?, "one Persian letter was held as idle"
      assert Enum.map(assigns(view).results.titles, & &1.title) == ["کتاب خانه"]
    end

    test "V16: the Arabic kaf, typed alone, is the same query as the Persian one" do
      title!("walk-fa", "کتاب خانه")

      view = mount_screen(SearchScreen, %{query: ""}) |> render_info({:change, :query, "ك"})

      assert Enum.map(assigns(view).results.titles, & &1.title) == ["کتاب خانه"]
    end

    test "V16: one Persian character that matches nothing is a search that looked" do
      view = mount_screen(SearchScreen, %{query: ""}) |> render_info({:change, :query, "ژ"})

      refute assigns(view).results.idle?
      assert :look_up in tap_tags(view), "a Persian query that ran drew no nothing-found card"
    end

    test "V17: the clear disc returns to idle with the recent shelf under it" do
      title!("walk-hollow", "Hollow Season")

      view =
        mount_screen(SearchScreen, %{query: ""})
        |> render_info({:change, :query, "hollow"})

      refute assigns(view).results.idle?

      cleared = render_info(view, {:tap, :clear})

      assert assigns(cleared).query == ""
      assert assigns(cleared).results.idle?
      assert assigns(cleared).history == ["hollow", "estuary"]

      tags = tap_tags(cleared)
      assert SearchIdle.query_tag("repeat_query", "hollow") in tags
      assert SearchIdle.query_tag("repeat_query", "estuary") in tags
      assert :clear_recent in tags
      refute :look_up in tags
    end

    test "V17: backspacing the field to nothing is the same idle page" do
      view =
        mount_screen(SearchScreen, %{query: ""})
        |> render_info({:change, :query, "hollow"})
        |> render_info({:change, :query, ""})

      assert assigns(view).results.idle?
      assert SearchIdle.query_tag("repeat_query", "hollow") in tap_tags(view)
      refute :look_up in tap_tags(view)
    end
  end

  describe "V21 — screen 33's half-star targets" do
    setup do
      Kati.Rating.Scale.put(:stars)
      :ok
    end

    test "star_6 is three stars, prints 3, and Save writes six points" do
      logged_watch!()
      assert Rating.point_of(:star_6) == 6

      view = mount_rating() |> render_info({:tap, :star_6})

      assert assigns(view).watch.rating == 3.0

      card = Rating.rating_card(assigns(view).watch)
      assert find(card, :text, text: "3") != nil, "the label beside the stars is not 3"
      assert find(card, :text, text: "3.0") == nil, "a whole rating printed a .0"

      saved = render_info(view, {:tap, :save})

      assert [%{rating: 6}] = Ash.read!(Watch)
      assert navigated_to(saved) == {:pop}
    end

    test "the star is the full chain: the tag the sheet draws is the one that writes" do
      logged_watch!()
      view = mount_rating()

      assert :star_6 in tap_tags(view), "no drawn control carries :star_6"

      view |> render_info({:tap, :star_6}) |> render_info({:tap, :save})

      assert [%{rating: 6}] = Ash.read!(Watch)
    end
  end

  describe "V22 — screen 33 refused" do
    test "the red line sits under the header, and the draft is still drawn" do
      Kati.Rating.Scale.put(:stars)
      logged_watch!()

      view =
        mount_rating()
        |> render_info({:tap, :star_7})
        |> render_info({:change, :review, "Still typed."})

      Enum.each(Ash.read!(Watch), &Ash.destroy!/1)

      view = render_info(view, {:tap, :save})
      error = assigns(view).save_error

      assert navigated_to(view) == nil
      assert is_binary(error)

      texts = texts(view)
      header = Enum.find_index(texts, &(&1.props.text == "Log a watch"))
      notice = Enum.find_index(texts, &(&1.props.text == error))
      title = Enum.find_index(texts, &(&1.props.text == "Estuary"))

      assert header < notice and notice < title,
             "the refusal is not between the header and the title card"

      assert Enum.at(texts, notice).props.text_color == Palette.red()

      assert find(view, :text, text: "3.5") != nil, "the tapped stars are gone from the sheet"

      assert %{props: %{value: "Still typed."}} =
               find(view, :text_field, accessibility_id: "review")
    end
  end

  describe "V29 — `Kati.Search.normalise/1`, row by row, and `tier/3` on both sides" do
    test "ي U+064A folds to ی U+06CC" do
      assert Search.normalise("ي") == "ی"
      assert Search.tier("ياد", "یاد") == 1
      assert Search.tier("یاد", "ياد") == 1
      assert Search.tier("ياد", "Ashfall", "یاد") == 4
    end

    test "ك U+0643 folds to ک U+06A9" do
      assert Search.normalise("ك") == "ک"
      assert Search.tier("كتاب", "کتاب") == 1
      assert Search.tier("کتاب", "كتاب") == 1
    end

    test "ZWNJ U+200C is folded away" do
      assert Search.normalise("می‌رود") == "میرود"
      assert Search.tier("میرود", "می‌رود") == 1
      assert Search.tier("می‌رود", "میرود") == 1
      assert Search.tier("می‌ر", "میرود") == 2
    end

    test "every harakat U+064B–U+0652 is stripped, and nothing either side of the range" do
      for cp <- 0x064B..0x0652 do
        assert Search.normalise("ک" <> <<cp::utf8>> <> "تاب") == "کتاب",
               "U+#{Integer.to_string(cp, 16)} survived"
      end

      assert Search.normalise("ي") != "", "the range swallowed the yeh just below it"
      assert Search.normalise("ٓ") == "ٓ"

      assert Search.tier("کتاب", "کِتابُ") == 1
      assert Search.tier("کِتاب", "کتاب") == 1
    end

    test "Arabic-Indic and Persian digits fold to ASCII, all ten of each" do
      assert Search.normalise("٠١٢٣٤٥٦٧٨٩") == "0123456789"
      assert Search.normalise("۰۱۲۳۴۵۶۷۸۹") == "0123456789"

      assert Search.tier("۴", "4") == 1
      assert Search.tier("٤", "۴") == 1
      assert Search.tier("4", "٤") == 1
      assert Search.tier("۱۹۸۴", "1984 Revisited") == 2
    end

    test "case folds, on both sides" do
      assert Search.normalise("HoLLow") == "hollow"
      assert Search.tier("HOLLOW", "hollow") == 1
      assert Search.tier("hollow", "HOLLOW") == 1
      assert Search.tier("HOLLOW", "Ashfall", "a note about hollow") == 4
    end

    test "whitespace collapses and trims, on both sides" do
      assert Search.normalise("  the \t long\n\nhollow  ") == "the long hollow"
      assert Search.tier("long  hollow", "The Long Hollow") == 3
      assert Search.tier("long hollow", "The  Long\tHollow") == 3
    end

    test "every row screen 88 prints is one the tests above exercise" do
      codes = Enum.map(Search.normalisation_table(), &elem(&1, 1))

      assert codes == ["U+064A", "U+0643", "U+200C", "U+064B–0652", "Arabic-Indic"],
             "the printed table grew or changed a row this file does not assert"
    end

    test "all of it at once: a Persian title with every variant finds its plain form" do
      assert Search.tier("  ميرود ٤  ", "می‌رود ۴") == 1
      assert Search.tier("كِتاب", "The Big کتاب") == 3
    end
  end

  describe "V30 — the refusal under Something else" do
    test "is red, and sits under the row that refused" do
      view = mount_screen(MyServices) |> render_info({:tap, :add_service})
      error = assigns(view).save_error

      assert error == "Nothing to save yet."

      texts = texts(view)
      row = Enum.find_index(texts, &(&1.props.text == "Something else"))
      notice = Enum.find_index(texts, &(&1.props.text == error))

      assert row != nil and notice != nil
      assert row < notice, "the notice is drawn above the row it is about"
      assert Enum.at(texts, notice).props.text_color == Palette.red()
    end
  end

  describe "V32 — screen 94's ✕" do
    test "closes without writing a region when none was set" do
      Mob.State.delete(:kati_region)
      before = snapshot()

      view =
        mount_screen(CountryPicker)
        |> render_info({:change, :country_query, "neth"})
        |> render_info({:tap, :close})

      assert navigated_to(view) == {:pop}
      assert Services.chosen_region() == nil, "closing the picker chose a country"
      assert snapshot() == before
    end

    test "and leaves a chosen region as it was" do
      Services.put_region("IR")

      view = mount_screen(CountryPicker) |> render_info({:tap, :close})

      assert navigated_to(view) == {:pop}
      assert Services.region() == "IR"
    end
  end

  describe "V33 — changing country" do
    test "writes the region and not one row of the library, ratings, services or history" do
      Services.put_region("GB")
      Search.Recent.forget!()
      Search.Recent.remember("estuary")

      tracked = title!("walk-country", "Estuary")

      Ash.create!(Watch, %{
        tracked_title_id: tracked.id,
        watched_on: ~D[2026-08-02],
        watched_at: ~U[2026-08-02 20:30:00.000000Z],
        rating: 7,
        review: "Kept."
      })

      Ash.create!(Service, %{name: @prefix <> "Mubi", monthly_pence: 1099})

      before = snapshot()

      view = mount_screen(CountryPicker) |> render_info({:tap, :pick_NL})

      assert navigated_to(view) == {:pop}
      assert Services.region() == "NL"
      assert snapshot() == before, "picking a country changed a row in kati.db"
      assert Search.Recent.all() == ["estuary"]
    end
  end

  describe "V36 — backing out of a part-filled add-by-hand form" do
    test "pops, and writes nothing" do
      before = snapshot()

      view =
        mount_screen(AddByHand)
        |> render_info({:change, :title, "Estuary Nights"})
        |> render_info({:change, :year, "2024"})
        |> render_info({:tap, :kind_tv})
        |> render_info({:change, :episodes, "8"})
        |> render_info({:tap, :status_watching})

      assert assigns(view).title == "Estuary Nights"
      assert assigns(view).kind == :tv

      backed = render_info(view, {:tap, :back})

      assert navigated_to(backed) == {:pop}
      assert assigns(backed).save_error == nil
      assert snapshot() == before, "backing out of the form wrote to the store"
    end
  end

  # Every row of every table in kati.db, so "touched nothing" is asked of the
  # whole store rather than of the tables a test thought to name.
  defp snapshot do
    %{rows: tables} =
      Kati.Repo.query!(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
        []
      )

    Map.new(tables, fn [table] ->
      {table, Enum.sort(Kati.Repo.query!(~s(SELECT * FROM "#{table}"), []).rows)}
    end)
  end

  defp title!(source_id, title) do
    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: source_id,
      kind: :movie,
      title: title,
      fetched_at: DateTime.utc_now()
    })

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: source_id,
      kind: :movie,
      status: :finished
    })
  end

  defp logged_watch! do
    CachedTitle
    |> Ash.Changeset.for_create(:create, %{
      source: :tmdb,
      source_id: "walk-estuary",
      kind: :movie,
      title: "Estuary",
      runtime_minutes: 96,
      fetched_at: DateTime.utc_now()
    })
    |> Ash.create!()

    tracked =
      TrackedTitle
      |> Ash.Changeset.for_create(:create, %{
        source: :tmdb,
        source_id: "walk-estuary",
        kind: :movie,
        status: :finished
      })
      |> Ash.create!()

    Ash.create!(Watch, %{
      tracked_title_id: tracked.id,
      watched_on: ~D[2026-08-02],
      watched_at: ~U[2026-08-02 20:30:00.000000Z],
      review: "Placeholder."
    })
  end

  defp mount_rating do
    [tracked] = Ash.read!(TrackedTitle)
    mount_screen(Rating, %{tracked_title_id: tracked.id})
  end

  defp tap_tags(view) do
    for node <- flatten(view),
        {_pid, tag} <- [Map.get(node.props || %{}, :on_tap)],
        is_atom(tag),
        do: tag
  end

  defp texts(view) do
    view
    |> flatten()
    |> Enum.filter(&(&1.type == :text and is_binary(Map.get(&1.props || %{}, :text))))
  end
end
