defmodule Kati.SheetRowIdentityTest do
  @moduledoc """
  Three sheets act on the row that opened them — screens 70, 73 and 118.

  ## The defect, and why every other test in this repo was blind to it

  `Mob.Socket.push_screen/3` has taken params since the pinned Mob and hands
  them to `mount/3`. Three sheets took none: `Kati.Screens.LogProgress`,
  `Kati.Screens.LogListen` and `Kati.Screens.MealEdit` each re-read their table
  and took the head of the list. Tap the third meal, edit the first. Open the
  third album, credit the play to the first.

  Nothing caught it because there is nothing to catch **while the table holds
  one row**, and one row is the state every other suite here puts it in: the
  design-literal sweep needs the tables empty so the drawings show, the
  empty-database sweep empties them on purpose, and the domain suites insert
  one book, one album, one recipe. The head of a one-row list is also its
  second row, its third, and the row you tapped. So every assertion in the app
  was true of the wrong reader.

  So this file is about **two** rows, and asks the only question a second row
  makes askable: given the second, does the sheet load, draw and write the
  second. `Enum.at(1)` is taken off the very list each screen reads, never
  assumed from insert order — `:shelf` sorts on `updated_at` and two inserts in
  one millisecond can tie, which would make this file pass or fail on the
  clock.

  ## Both halves, and the seam between them

  Each screen is asked twice over, because "the sheet can load a row by id" and
  "the caller names one" are separately true and separately useless:

    * the **push** carries the id of the row the page was drawing, driven
      through the caller's own real `handle_tap/2` rather than asserted about
      it, and
    * the **sheet**, mounted with exactly those params, draws that row *and
      writes to it* — the half a screenshot cannot show, and the worse half of
      the defect: a sheet that loaded the right row and wrote to the shelf's
      head would name one record on screen and move another one's numbers.

  The write assertions are therefore always a pair — the second row changed,
  **and the first row did not**. Only the second half can fail on the bug this
  file exists for.

  ## And the fallback, which must survive all of it

  The drawings carry no id, so a sheet opened over `Kati.Books.Sample` and
  friends is handed `%{}` and answers with the shelf's first and then the
  drawing. That is what `Kati.ScreenEmptyDatabaseTest` renders, and breaking it
  would blank every capture. Pinned here from the caller's side (`params_for/1`
  over a drawn row is `%{}`) and from the sheet's (an id whose row has been
  deleted draws the drawing, not some other row).

  ## Why every row is prefixed and deleted

  The hazard `Kati.BooksTest` and `Kati.MusicTest` both record: screens 66, 70,
  73, 74 and 118 fall back to their drawings only while their tables are empty,
  and `Kati.ScreenDesignLiteralTest` renders them against this same shared
  database file. A row left behind here fails a file this one never touched,
  for the seeds that order the two modules the wrong way round.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Books.Book
  alias Kati.Books.ReadingSession
  alias Kati.Meals.Recipe
  alias Kati.Music.Album
  alias Kati.Music.Artist
  alias Kati.Music.Listen
  alias Kati.Music.Track
  alias Kati.Screens.AlbumDetail
  alias Kati.Screens.BookDetail
  alias Kati.Screens.LogListen
  alias Kati.Screens.LogProgress
  alias Kati.Screens.MealEdit
  alias Kati.Screens.MealLibrary

  @prefix "row-identity-test-"

  setup do
    on_exit(&delete_rows!/0)
    :ok
  end

  # Children first: the foreign keys refuse the parent delete otherwise. Raw
  # SQL because this runs from `on_exit`, after the test process is gone.
  defp delete_rows! do
    for table <- ~w(book_notes book_reading_sessions) do
      Kati.Repo.query!(
        "DELETE FROM #{table} WHERE book_id IN (SELECT id FROM books WHERE title LIKE ?1)",
        [@prefix <> "%"]
      )
    end

    Kati.Repo.query!("DELETE FROM books WHERE title LIKE ?1", [@prefix <> "%"])

    for table <- ~w(music_tracks music_listens) do
      Kati.Repo.query!(
        "DELETE FROM #{table} WHERE album_id IN " <>
          "(SELECT id FROM music_albums WHERE title LIKE ?1)",
        [@prefix <> "%"]
      )
    end

    Kati.Repo.query!("DELETE FROM music_albums WHERE title LIKE ?1", [@prefix <> "%"])
    Kati.Repo.query!("DELETE FROM music_artists WHERE name LIKE ?1", [@prefix <> "%"])

    Kati.Repo.query!(
      "DELETE FROM recipe_ingredients WHERE recipe_id IN " <>
        "(SELECT id FROM recipes WHERE title LIKE ?1)",
      [@prefix <> "%"]
    )

    Kati.Repo.query!("DELETE FROM recipes WHERE title LIKE ?1", [@prefix <> "%"])
  end

  # ── screen 118, the one that is literally a list ───────────────────────────

  describe "screen 118 acts on the meal you tapped" do
    test "the second tile pushes the second meal, and the editor loads it" do
      a_recipe!(%{title: @prefix <> "A first", slot_name: "Breakfast"})
      a_recipe!(%{title: @prefix <> "B second", slot_name: "Dinner"})

      {first, second} = two_meals()

      view =
        MealLibrary
        |> mount_screen()
        |> render_info({:tap, MealLibrary.tag(1)})

      assert {:push, MealEdit, %{meal_id: id}} = pushed(view)
      assert id == second.id

      sheet = mount_screen(MealEdit, %{meal_id: id})

      assert assigns(sheet).meal.title == second.title
      refute assigns(sheet).meal.title == first.title
      refute assigns(sheet).meal.title == MealEdit.drawn_meal().title

      # The slot chips open on the row's own slot, not on the head's — the one
      # control on this screen that writes, pre-set from the wrong row, would
      # save the wrong value on the first press.
      assert assigns(sheet).slot == second.slot_name
    end

    test "Save writes the slot onto the second meal and leaves the first alone" do
      a_recipe!(%{title: @prefix <> "A first", slot_name: "Breakfast"})
      a_recipe!(%{title: @prefix <> "B second", slot_name: "Dinner"})

      {first, second} = two_meals()

      MealEdit
      |> mount_screen(%{meal_id: second.id})
      |> render_info({:tap, :slot_Lunch})
      |> render_info({:tap, :save})

      assert Ash.get!(Recipe, second.id).slot_name == "Lunch"
      assert Ash.get!(Recipe, first.id).slot_name == "Breakfast"
    end

    test "the whole page is the second meal, not just its title" do
      # Every band came off one read, so the old defect was internally
      # consistent and externally about somebody else's dinner. The figures and
      # the ingredient count are the two that would not move.
      a_recipe!(%{title: @prefix <> "A first"})
      a_recipe!(%{title: @prefix <> "B second"})

      {first, second} = two_meals()

      totals!(first, %{total_protein_mg: 11_000})
      totals!(second, %{total_fat_mg: 22_000})

      assert Map.new(MealEdit.macros(second.id))["Fat"] == "22 g"
      assert Map.new(MealEdit.macros(second.id))["Protein"] == "—"
      assert Map.new(MealEdit.macros(first.id))["Protein"] == "11 g"

      an_ingredient!(second, %{name: "Miso", amount_mg: 30_000, kcal: 60})

      assert MealEdit.ingredients_label(second.id) == "Ingredients · 1"
      assert MealEdit.ingredients_label(first.id) == "Ingredients · 0"
    end

    test "a tile with no id pushes no id, and the editor draws the drawing" do
      # The drawing's six carry no id, so the grid on a fresh install pushes
      # `%{}` and screen 118 answers with `Kati.Meals.SampleLibrary` — which is
      # what every capture of it was taken from.
      assert MealEdit.params_for(hd(MealLibrary.drawn_meals())) == %{}
      assert MealEdit.params_for(nil) == %{}

      a_recipe!(%{title: @prefix <> "A first"})
      dead = a_recipe!(%{title: @prefix <> "B second"})
      Ash.destroy!(dead)

      # An id whose row is gone is not the same fact as an empty library, so it
      # draws the drawing rather than silently editing whatever is left.
      assert mount_screen(MealEdit, %{meal_id: dead.id}) |> assigns() |> Map.fetch!(:meal) ==
               MealEdit.drawn_meal()
    end
  end

  # ── screen 70 ──────────────────────────────────────────────────────────────

  describe "screen 70 logs against the book that opened it" do
    test "a page drawing the second book pushes its id, and the sheet loads it" do
      a_book!(%{title: @prefix <> "The Salt Almanac", current_page: 214, page_count: 380})
      a_book!(%{title: @prefix <> "Marram Grass", current_page: 40, page_count: 120})

      {first, second} = two_books()

      view = tap_on_page(BookDetail, :book, BookDetail.shelved_book(second.id), :log_progress)

      assert {:push, LogProgress, %{book_id: id}} = pushed(view)
      assert id == second.id

      sheet = mount_screen(LogProgress, %{book_id: id})

      assert assigns(sheet).book.title == second.title
      refute assigns(sheet).book.title == first.title
      refute assigns(sheet).book.title == BookDetail.drawn_book().title

      # The stepper opens on the handed book's position. Opening on the head's
      # would offer page 214 of a 120-page book.
      assert assigns(sheet).page == second.current_page
    end

    test "Save writes the session and moves the position on the second book only" do
      a_book!(%{title: @prefix <> "The Salt Almanac", current_page: 214, page_count: 380})
      a_book!(%{title: @prefix <> "Marram Grass", current_page: 40, page_count: 120})

      {first, second} = two_books()

      view =
        LogProgress
        |> mount_screen(%{book_id: second.id})
        |> render_info({:tap, :step_up})
        |> render_info({:tap, :save})

      assert pushed(view) == {:pop}, "a landed save closes the sheet"

      assert [%ReadingSession{to_page: to_page}] = sessions_of(second)
      assert to_page == second.current_page + 1
      assert sessions_of(first) == []

      assert Ash.get!(Book, second.id).current_page == second.current_page + 1
      assert Ash.get!(Book, first.id).current_page == first.current_page
    end

    test "Finished the book finishes the second book, not the shelf's first" do
      a_book!(%{title: @prefix <> "The Salt Almanac", status: :reading})
      a_book!(%{title: @prefix <> "Marram Grass", status: :reading})

      {first, second} = two_books()

      LogProgress
      |> mount_screen(%{book_id: second.id})
      |> render_info({:tap, :finish})

      assert Ash.get!(Book, second.id).status == :finished
      assert Ash.get!(Book, first.id).status == :reading
    end

    test "no id is still the shelf's first, and an id with no row is the drawing" do
      a_book!(%{title: @prefix <> "The Salt Almanac"})
      a_book!(%{title: @prefix <> "Marram Grass"})

      {first, _second} = two_books()

      # The standing answer, which is what a sheet opened from a screen with no
      # row to name still gets — and what the empty-database sweep exercises one
      # step further, with nothing shelved at all.
      assert mount_screen(LogProgress) |> assigns() |> Map.fetch!(:book) == LogProgress.book()
      assert LogProgress.book().title == first.title
      assert LogProgress.params_for(BookDetail.drawn_book()) == %{}

      dead = a_book!(%{title: @prefix <> "Low Water"})
      Ash.destroy!(dead)

      assert mount_screen(LogProgress, %{book_id: dead.id}) |> assigns() |> Map.fetch!(:book) ==
               BookDetail.drawn_book()
    end
  end

  # ── screen 73 ──────────────────────────────────────────────────────────────

  describe "screen 73 credits the album that opened it" do
    test "a page drawing the second album pushes its id, and the sheet loads it" do
      artist = an_artist!()
      one = an_album!(artist, %{title: @prefix <> "Tidal Works"})
      two = an_album!(artist, %{title: @prefix <> "Low Country"})

      # The tracks are hung on the rows *after* the shelf has been read, never
      # on the insert that happens to be second: `:shelf` sorts on `updated_at`,
      # so which album is second is the shelf's answer and not this test's.
      {first, second} = two_albums(one, two)
      tracks!(first, [{1, "On the shelf's first album", 252, 3}])
      tracks!(second, [{1, "On the second album", 190, 0}, {2, "Also the second", 200, 0}])

      view = tap_on_page(AlbumDetail, :album, AlbumDetail.shelved_album(second.id), :log_listen)

      assert {:push, LogListen, %{album_id: id}} = pushed(view)
      assert id == second.id

      sheet = mount_screen(LogListen, %{album_id: id})

      assert assigns(sheet).album.title == second.title
      refute assigns(sheet).album.title == first.title
      refute assigns(sheet).album.title == AlbumDetail.drawn_album().title

      # The tracklist is the sheet's other referent and moves with the album:
      # the ticks are per-position, so another record's tracks under this
      # record's title would tick rows that are not on it.
      assert Enum.map(assigns(sheet).tracks, & &1.title) == [
               "On the second album",
               "Also the second"
             ]
    end

    test "Save credits the listen and the play counts to the second album only" do
      artist = an_artist!()
      one = an_album!(artist, %{title: @prefix <> "Tidal Works"})
      two = an_album!(artist, %{title: @prefix <> "Low Country"})

      {first, second} = two_albums(one, two)
      tracks!(first, [{1, "On the shelf's first album", 252, 3}])
      tracks!(second, [{1, "On the second album", 190, 0}])

      view =
        LogListen
        |> mount_screen(%{album_id: second.id})
        |> render_info({:tap, :track_1})
        |> render_info({:tap, :save})

      assert pushed(view) == {:pop}, "a landed save closes the sheet"

      assert [%Listen{}] = listens_of(second)
      assert listens_of(first) == []

      assert [%Track{plays: 1}] = tracks_of(second)
      assert [%Track{plays: 3}] = tracks_of(first)

      assert Ash.get!(Album, second.id).last_played_on == Kati.Time.today()
    end

    test "no id is still the shelf's first, and an id with no row is the drawing" do
      artist = an_artist!()
      one = an_album!(artist, %{title: @prefix <> "Tidal Works"})
      two = an_album!(artist, %{title: @prefix <> "Low Country"})

      {first, _second} = two_albums(one, two)

      assert mount_screen(LogListen) |> assigns() |> Map.fetch!(:album) == LogListen.album()
      assert LogListen.album().title == first.title
      assert LogListen.params_for(AlbumDetail.drawn_album()) == %{}

      dead = an_album!(artist, %{title: @prefix <> "Gone"})
      Ash.destroy!(dead)

      assert mount_screen(LogListen, %{album_id: dead.id}) |> assigns() |> Map.fetch!(:album) ==
               AlbumDetail.drawn_album()
    end
  end

  # ── screen 45, which is not a sheet but has the same defect ────────────────

  describe "screen 43's timeline opens the card that was tapped" do
    # No rows are written here on purpose. Screen 43's timeline is already a
    # list of shaped maps by the time a tap reaches `open_meal/2`, and the
    # question this file asks — does the push name the row that was tapped —
    # is answerable from the list alone. Writing meal plans instead would leave
    # slots behind in the one SQLite file the whole suite shares, on a table
    # `Kati.ScreenDesignLiteralTest` needs empty to see screen 43's drawing.
    @rows [
      %{slot: "Breakfast", time: "08:00", slot_id: "row-identity-slot-one"},
      %{slot: "Lunch", time: "13:00", slot_id: "row-identity-slot-two"},
      # A logged row: `log_row/1` sets `slot_id: nil` because there is nothing
      # left for **Mark eaten** to write, and a card with no slot has no id to
      # carry either.
      %{slot: "Snack", time: "16:00", slot_id: nil}
    ]

    test "each card pushes its own slot, and a card with none pushes nothing" do
      socket =
        Mob.Socket.assign(Mob.Socket.new(Kati.Screens.MealsToday), :day, %{meals: @rows})

      pushed =
        for row <- @rows do
          tag = Kati.Screens.MealsToday.meal_tag(row)
          Kati.Screens.MealsToday.open_meal(socket, tag).__mob__.nav_action
        end

      assert pushed == [
               {:push, Kati.Screens.Meal, %{slot_id: "row-identity-slot-one"}},
               {:push, Kati.Screens.Meal, %{slot_id: "row-identity-slot-two"}},
               {:push, Kati.Screens.Meal, %{}}
             ],
             "the timeline's cards no longer push one meal each: #{inspect(pushed)}"
    end

    test "the drawing's cards carry no slot, so the push is the bare one" do
      # The state every capture of screens 43 and 45 was taken in, and the one
      # the gallery and the empty-database sweep render.
      for meal <- Kati.Screens.MealsToday.drawn_day().meals do
        assert Kati.Screens.Meal.params_for(meal) == %{}
      end

      assert Kati.Screens.Meal.params_for(nil) == %{}
      assert Kati.Screens.Meal.params_for(Kati.Screens.Meal.drawn_meal()) == %{}
    end

    test "a slot id that names no row is the no-id answer, not a blank screen" do
      today = Kati.Time.today()

      assert Kati.Screens.Meal.meal(today, %{slot_id: Ecto.UUID.generate()}) ==
               Kati.Screens.Meal.meal(today)

      assert Kati.Screens.Meal.meal(today, %{}) == Kati.Screens.Meal.meal(today)
      assert Kati.Screens.Meal.meal(today, nil) == Kati.Screens.Meal.meal(today)
    end

    test "screen 45's swap disc hands 46 the meal that is on screen" do
      drawn = Kati.Screens.Meal.drawn_meal()
      socket = Mob.Socket.assign(Mob.Socket.new(Kati.Screens.Meal), :meal, drawn)

      {:noreply, bare} = Kati.Screens.Meal.handle_info({:tap, :swap}, socket)

      assert bare.__mob__.nav_action == {:push, Kati.Screens.MealSwap, %{}},
             "a swap of the drawing named a slot it does not have"

      named = Mob.Socket.assign(socket, :meal, Map.put(drawn, :slot_id, "row-identity-slot-one"))
      {:noreply, carried} = Kati.Screens.Meal.handle_info({:tap, :swap}, named)

      assert carried.__mob__.nav_action ==
               {:push, Kati.Screens.MealSwap, %{slot_id: "row-identity-slot-one"}},
             "screen 46 was pushed with nothing, so it opens on whatever Mob.State held"
    end
  end

  # ── driving, and the two rows ──────────────────────────────────────────────

  # The nav action the last dispatch left on the socket — `{:push, module,
  # params}`. `Mob.ScreenCase.navigated_to/1` drops the params, and the params
  # are the whole subject of this file.
  defp pushed(view), do: view.socket.__mob__.nav_action

  # One tap, on a page that is drawing `row`.
  #
  # The real `handle_tap/2`, over the real socket, with the one assign the
  # handler reads set to the row this test is about. Screens 66 and 74 open on
  # the shelf's first by their own design, so this is how a page showing the
  # second is reached without asserting about `handle_tap/2` from the outside
  # rather than through it.
  defp tap_on_page(module, key, row, tag) do
    view = mount_screen(module)

    %{view | socket: Mob.Socket.assign(view.socket, key, row)}
    |> render_info({:tap, tag})
  end

  # The first two rows of the list the screen itself reads, in the order it
  # reads them. Never insert order: `:shelf` sorts on `updated_at`, and two
  # inserts inside one millisecond tie.
  defp two_books do
    [first, second | _rest] = Ash.read!(Book, action: :shelf)
    {first, second}
  end

  # Screen 116's own order — `title: :asc` — and an exact two-element match, so
  # a row another suite left behind fails here loudly instead of quietly moving
  # which tile index 1 is.
  defp two_meals do
    [first, second] = Recipe |> Ash.Query.sort(title: :asc) |> Ash.read!()
    {first, second}
  end

  # The albums, matched back to the two this test created — the shelf can hold
  # rows another suite left behind, and `Enum.at(1)` of a list with a stranger
  # in it is not the second album of this test.
  defp two_albums(one, two) do
    ids = [one.id, two.id]

    [first, second] =
      Album
      |> Ash.read!(action: :shelf)
      |> Enum.filter(&(&1.id in ids))

    {first, second}
  end

  defp sessions_of(book) do
    ReadingSession |> Ash.Query.for_read(:for_book, %{book_id: book.id}) |> Ash.read!()
  end

  defp listens_of(album) do
    Listen |> Ash.Query.for_read(:for_album, %{album_id: album.id}) |> Ash.read!()
  end

  defp tracks_of(album) do
    Track |> Ash.Query.for_read(:for_album, %{album_id: album.id}) |> Ash.read!()
  end

  defp a_book!(attrs) do
    Ash.create!(
      Book,
      Map.merge(
        %{
          title: @prefix <> "A book",
          author: "Ines Karvel",
          page_count: 380,
          current_page: 100,
          status: :reading,
          format: :paperback
        },
        attrs
      )
    )
  end

  defp a_recipe!(attrs) do
    Ash.create!(Recipe, Map.merge(%{title: @prefix <> "A meal", serves: 2}, attrs))
  end

  # The cached macro figures are `Kati.Meals.Totals`' to write, and `:create`
  # does not accept them on purpose — an ordinary edit must not be able to
  # rewrite one. `:store_totals` is the action that may.
  defp totals!(recipe, attrs), do: Ash.update!(recipe, attrs, action: :store_totals)

  defp an_ingredient!(recipe, attrs) do
    Ash.create!(
      Kati.Meals.RecipeIngredient,
      Map.merge(%{recipe_id: recipe.id, name: "Something", aisle: :cupboard, position: 0}, attrs)
    )
  end

  defp an_artist!, do: Ash.create!(Artist, %{name: @prefix <> "Kell Ostrand"})

  defp an_album!(artist, attrs) do
    Ash.create!(
      Album,
      Map.merge(%{title: @prefix <> "An album", artist_id: artist.id, released_year: 2025}, attrs)
    )
  end

  defp tracks!(album, specs) do
    for {position, title, seconds, plays} <- specs do
      Ash.create!(Track, %{
        album_id: album.id,
        position: position,
        title: title,
        seconds: seconds,
        plays: plays
      })
    end
  end

  # ── screen 114, the same defect over a grid rather than over a table ───────

  # No rows and nothing to clean up: screen 42's grid is the drawing's six
  # tiles, drawn unconditionally, so this block asks the database nothing. It
  # belongs in this file all the same, because it is this file's defect wearing
  # a different hat — a sheet that took no parameter and answered about
  # whichever subject it happened to be drawn for. `Kati.Screens.RetiredTile`
  # was drawn for Sleep, so pressing **Workouts** was answered with *Sleep
  # isn't in this version*: right for one tile by accident, wrong for the other
  # with nothing on the screen to say which you were looking at. The head of a
  # one-row list again, only here the list is a two-tile grid.
  describe "screen 114 is about the tile you pressed" do
    test "each dashed tile pushes its own section" do
      for name <- ["Sleep", "Workouts"] do
        {_pid, tag} = Kati.Screens.Health.tile_tap(name)

        view = Kati.Screens.Health |> mount_screen() |> render_info({:tap, tag})

        assert {:push, Kati.Screens.RetiredTile, %{section: ^name}} = pushed(view)
      end
    end

    test "the sheet mounted with those params is that section, glyph and all" do
      # The glyph matters as much as the name: the sheet's own doc says it must
      # not describe a section using a tile the grid does not draw for it.
      subject = assigns(mount_screen(Kati.Screens.RetiredTile, %{section: "Workouts"})).subject

      assert subject.name == "Workouts"
      assert subject.icon == "fitness_center"
      assert subject.headline =~ "Workouts"
      refute subject.headline =~ "Sleep"
    end

    test "no section is still the subject the design drew" do
      drawn = assigns(mount_screen(Kati.Screens.RetiredTile)).subject

      assert drawn.name == "Sleep"
      assert drawn == assigns(mount_screen(Kati.Screens.RetiredTile, %{section: "Sleep"})).subject
    end

    test "a tag that names no retired tile is still a quiet no-op" do
      # The clause reads every atom the board can send it, so the half that
      # must not move is the half worth pinning: `:open_filters` is screen 42's
      # deliberately inert disc and it must stay on the screen it was pressed
      # on.
      assert Kati.Screens.Health.retired_section(:open_filters) == nil

      view = Kati.Screens.Health |> mount_screen() |> render_info({:tap, :open_filters})

      assert pushed(view) == nil
    end
  end

  # ── screens 74 and 77, page to page rather than page to sheet ─────────────

  # The pair above the sheet this file was opened for. Screen 74 knew which
  # album it was drawing and told screen 77 nothing, so the artist page derived
  # its subject from `Ash.read(Album, action: :shelf)`'s head and an album
  # detail opened on the second record credited the first record's musician.
  # Screen 77's rail had the mirror of it: four rows, four pushes, one
  # destination that took no argument, so tapping *Estuary Tapes — Unheard*
  # opened a page reading `41 plays · 4 this month`.
  #
  # Two artists, not one, and two albums under different names — the whole
  # question is whether the second is reachable, and a fixture where both
  # albums hang off one artist cannot ask it.
  describe "screen 74's artist row opens the artist of the album on screen" do
    test "the second album's page names its own artist, and 77 loads them" do
      one = an_artist!(@prefix <> "Kell Ostrand")
      two = an_artist!(@prefix <> "Ines Karvel")

      a = an_album!(one, %{title: @prefix <> "Tidal Works", released_year: 2025})
      b = an_album!(two, %{title: @prefix <> "Low Country", released_year: 2023})

      {first, second} = two_albums(a, b)

      view =
        tap_on_page(AlbumDetail, :album, AlbumDetail.shelved_album(second.id), :open_artist)

      assert {:push, Kati.Screens.ArtistDetail, %{artist_id: id}} = pushed(view)
      assert id == second.artist_id
      refute id == first.artist_id

      page = mount_screen(Kati.Screens.ArtistDetail, %{artist_id: id})

      assert assigns(page).artist.name == Ash.get!(Artist, second.artist_id).name
      refute assigns(page).artist.name == Ash.get!(Artist, first.artist_id).name
      refute assigns(page).artist.name == Kati.Screens.ArtistDetail.drawn_artist().name
    end

    test "the whole of 77 follows the id, not only the name over it" do
      # The half that would not have moved. The rail, the chart's caption and
      # the cream card are three more reads of the same subject, and a page
      # that took the id for its hero and the shelf's head for its
      # discography would draw one musician's name over another's records.
      one = an_artist!(@prefix <> "Kell Ostrand")
      two = an_artist!(@prefix <> "Ines Karvel")

      an_album!(one, %{title: @prefix <> "Tidal Works", released_year: 2025})
      an_album!(two, %{title: @prefix <> "Low Country", released_year: 2023})
      an_album!(two, %{title: @prefix <> "Nine Rooms", released_year: 2021})

      assert Kati.Screens.ArtistDetail.albums_label(two.id) == "Albums · 2"
      assert Kati.Screens.ArtistDetail.albums_label(one.id) == "Albums · 1"

      titles = Enum.map(Kati.Screens.ArtistDetail.albums(two.id), & &1.title)

      assert (@prefix <> "Low Country") in titles
      refute (@prefix <> "Tidal Works") in titles
    end

    test "an album with no artist names none, and 77 answers with the drawing" do
      # The fallback both sweeps render. `Kati.Music.Sample.album/0` carries
      # neither key, and an id that names no artist is not the same fact as an
      # empty shelf — it is the drawing, never somebody else.
      assert Kati.Screens.ArtistDetail.params_for(AlbumDetail.drawn_album()) == %{}
      assert Kati.Screens.ArtistDetail.params_for(nil) == %{}

      gone = an_artist!(@prefix <> "Deleted")
      id = gone.id
      Ash.destroy!(gone)

      assert Kati.Screens.ArtistDetail.artist(id) ==
               Kati.Screens.ArtistDetail.drawn_artist()

      assert Kati.Screens.ArtistDetail.stored_artist(id) == nil
    end
  end

  describe "screen 77's rail opens the album the row is drawing" do
    test "the second row pushes the second album, and 74 loads it" do
      artist = an_artist!(@prefix <> "Kell Ostrand")

      a = an_album!(artist, %{title: @prefix <> "Tidal Works", released_year: 2025})
      b = an_album!(artist, %{title: @prefix <> "Low Country", released_year: 2023})

      tracks!(a, [{1, "On the first album", 252, 3}])
      tracks!(b, [{1, "On the second album", 190, 0}, {2, "Also the second", 200, 0}])

      # The row off the list the page itself drew, found by its title rather
      # than by position: `:for_artist`'s order is the screen's, not this
      # test's, and an index would pass or fail on it.
      row =
        artist.id
        |> Kati.Screens.ArtistDetail.albums()
        |> Enum.find(&(&1.title == b.title))

      tag = Kati.Screens.ArtistDetail.album_tag(row)

      view = tap_on_page(Kati.Screens.ArtistDetail, :artist_id, artist.id, tag)

      assert {:push, AlbumDetail, %{album_id: id}} = pushed(view)
      assert id == b.id
      refute id == a.id

      page = mount_screen(AlbumDetail, %{album_id: id})

      assert assigns(page).album.title == b.title
      assert assigns(page).album_id == id

      # The eyebrow counts the rows under it, so it is the second reader that
      # would have stayed on the shelf's head.
      assert AlbumDetail.tracklist_label(b.id) == "Tracklist · 2 tracks"
      assert AlbumDetail.tracklist_label(a.id) == "Tracklist · 1 track"
    end

    test "a rail row with no id pushes none, and 74 is the shelf's first" do
      # Every row of `Kati.Music.Sample.artist_albums/0` is a title and a year
      # and no identity, which is the state screen 77 is drawn in. The push
      # still happens — the rail must not go dead on a fresh install — and it
      # carries `%{}`, which is what a bare `push_screen/2` sends.
      drawn = hd(Kati.Music.Sample.artist_albums())

      assert AlbumDetail.params_for(drawn) == %{}
      assert AlbumDetail.params_for(nil) == %{}

      artist = an_artist!(@prefix <> "Kell Ostrand")
      an_album!(artist, %{title: @prefix <> "Tidal Works", released_year: 2025})

      view =
        tap_on_page(
          Kati.Screens.ArtistDetail,
          :artist_id,
          artist.id,
          :open_album_nothing_named_this
        )

      assert pushed(view) == {:push, AlbumDetail, %{}}
    end
  end

  describe "screen 76 credits and opens the record it is drawing" do
    test "the Persian page carries both ids and hands each one on" do
      # The mirror's two bare pushes, and the first of them WRITES: ثبت یک
      # شنیدن opened a sheet that re-read the shelf, so the page said one title
      # and the play landed on another. Driven over a socket rather than
      # through a render, because what is being asked is which row travelled.
      artist = an_artist!(@prefix <> "Kell Ostrand")
      album = an_album!(artist, %{title: @prefix <> "Tidal Works", released_year: 2025})

      shelved = Kati.Screens.AlbumDetailFa.album()

      assert shelved.id == album.id
      assert shelved.artist_id == artist.id

      socket =
        Mob.Socket.assign(Mob.Socket.new(Kati.Screens.AlbumDetailFa), :album, shelved)

      {:noreply, listen} =
        Kati.Screens.AlbumDetailFa.handle_info({:tap, :log_listen}, socket)

      assert listen.__mob__.nav_action == {:push, LogListen, %{album_id: album.id}}

      {:noreply, open} =
        Kati.Screens.AlbumDetailFa.handle_info({:tap, :open_artist}, socket)

      assert open.__mob__.nav_action ==
               {:push, Kati.Screens.ArtistDetailFa, %{artist_id: artist.id}}
    end

    test "the drawing carries neither, so both pushes are the ones 76 draws" do
      # `album/0`'s `nil` branch is `drawn/0` under `own/1` and nothing else —
      # no `:id`, no `:artist_id` — which is the state
      # `test/design/screens/76.html` was captured in and the one every sweep
      # mounts. Both builders answer `%{}` for it.
      drawn =
        Map.merge(
          Kati.Screens.AlbumDetailFa.drawn(),
          Kati.Screens.AlbumDetailFa.own(AlbumDetail.drawn_album())
        )

      refute Map.has_key?(drawn, :id)
      refute Map.has_key?(drawn, :artist_id)

      assert LogListen.params_for(drawn) == %{}
      assert Kati.Screens.ArtistDetail.params_for(drawn) == %{}
    end
  end

  # An artist by name, so a test that needs two can tell them apart. The
  # arity-0 form above is every other block's one artist and is left alone.
  defp an_artist!(name), do: Ash.create!(Artist, %{name: name})

  # ── screens 03 and 57: the poster, and the title it opens ──────────────────

  describe "the shelf grid opens the title that was tapped" do
    # No rows are written in this block. The one assign each handler reads is
    # set directly — screen 45's swap disc above is the precedent — because
    # what is measured here is the tap and not the query behind it, and a
    # `Kati.Media.TrackedTitle` left in this file's shared database would take
    # `Kati.ScreenDesignLiteralTest` down with it.

    test "a tile with an id carries it, and a drawn tile carries nothing" do
      rows = [
        %{id: "row-identity-title-one", kind: :series, title: "First Show"},
        %{kind: :series, title: "Second Show"},
        %{id: "row-identity-title-two", kind: :film, title: "Low Water"}
      ]

      socket = Mob.Socket.assign(Mob.Socket.new(Kati.Screens.Library), :titles, rows)

      {:noreply, named} = Kati.Screens.Library.handle_tap(:open_series_First_Show, socket)

      assert named.__mob__.nav_action ==
               {:push, Kati.Screens.Series, %{id: "row-identity-title-one"}},
             "every poster pushed screen 04 with nothing, so all of them opened whatever " <>
               "the top of the shelf happened to be"

      {:noreply, film} = Kati.Screens.Library.handle_tap(:open_film_Low_Water, socket)

      assert film.__mob__.nav_action ==
               {:push, Kati.Screens.Film, %{id: "row-identity-title-two"}}

      # A row with no id is `Kati.Library.Sample`'s, and it must push exactly
      # what it pushed before — not `%{id: nil}`, which a destination matching
      # on the key would take for an answer.
      {:noreply, drawn} = Kati.Screens.Library.handle_tap(:open_series_Second_Show, socket)
      assert drawn.__mob__.nav_action == {:push, Kati.Screens.Series, %{}}

      {:noreply, unknown} = Kati.Screens.Library.handle_tap(:open_series_Nobody, socket)
      assert unknown.__mob__.nav_action == {:push, Kati.Screens.Series, %{}}
    end

    test "screen 57's Persian grid names the same row" do
      row = %{id: "row-identity-title-three", title: "گودال بلند"}
      socket = Mob.Socket.assign(Mob.Socket.new(Kati.Screens.LibraryFa), :titles, [row])

      {:noreply, moved} =
        Kati.Screens.LibraryFa.handle_info(
          {:tap, Kati.Screens.LibraryFa.poster_tag(row)},
          socket
        )

      assert moved.__mob__.nav_action ==
               {:push, Kati.Screens.SeriesFa, %{id: "row-identity-title-three"}}

      # The untitled tile is one tile like any other: `poster_tag/1` falls back
      # to `:open_series` for a row whose cache row lost its name, and a tag
      # that matches nothing still pushes bare.
      bare = Mob.Socket.assign(Mob.Socket.new(Kati.Screens.LibraryFa), :titles, [])
      {:noreply, nothing} = Kati.Screens.LibraryFa.handle_info({:tap, :open_series}, bare)

      assert nothing.__mob__.nav_action == {:push, Kati.Screens.SeriesFa, %{}}
    end

    test "the drawn shelf names nothing, which is what every capture was taken from" do
      for row <- Kati.Screens.LibraryFa.drawn_titles() do
        assert Kati.Screens.Series.params_for(row) == %{}
      end

      assert Kati.Screens.Series.params_for(nil) == %{}

      assert Kati.Screens.LibraryFa.tapped(
               :open_series_nobody,
               Kati.Screens.LibraryFa.drawn_titles()
             ) == nil
    end

    test "the two ⋯ rows name their subject, and the drawing's name nothing" do
      assert Kati.Screens.Rating.params_for(Kati.Screens.Film.drawn_film()) == %{}
      assert Kati.Screens.Rating.params_for(nil) == %{}
      assert Kati.Screens.Rating.params_for(%{tracked_id: "t1"}) == %{tracked_title_id: "t1"}

      assert Kati.Screens.Season.params_for(Kati.Screens.Series.drawn_series()) == %{}
      assert Kati.Screens.Season.params_for(nil) == %{}

      assert Kati.Screens.Season.params_for(%{tracked_id: "t1", current_season: "S2"}) ==
               %{title_id: "t1", season: 2}

      # A label this screen cannot read as a number is the title alone, which
      # falls back to the bookmark rather than to a season nobody named.
      assert Kati.Screens.Season.params_for(%{tracked_id: "t1", current_season: "Specials"}) ==
               %{title_id: "t1"}
    end

    test "screen 08's Log a watch names the film that is on screen" do
      drawn = Kati.Screens.Film.drawn_film()
      socket = Mob.Socket.assign(Mob.Socket.new(Kati.Screens.Film), :film, drawn)

      {:noreply, bare} = Kati.Screens.Film.handle_info({:tap, :log_watch}, socket)
      assert bare.__mob__.nav_action == {:push, Kati.Screens.Rating, %{}}

      named = Mob.Socket.assign(socket, :film, Map.put(drawn, :tracked_id, "t1"))
      {:noreply, moved} = Kati.Screens.Film.handle_info({:tap, :log_watch}, named)

      assert moved.__mob__.nav_action ==
               {:push, Kati.Screens.Rating, %{tracked_title_id: "t1"}},
             "the sheet opened on the newest log in the whole library, whatever film the " <>
               "menu was opened over"
    end

    test "screen 04's Episode order names the series and the lit pill" do
      drawn = Kati.Screens.Series.drawn_series()
      socket = Mob.Socket.assign(Mob.Socket.new(Kati.Screens.Series), :series, drawn)

      {:noreply, bare} = Kati.Screens.Series.handle_info({:tap, :episode_order}, socket)
      assert bare.__mob__.nav_action == {:push, Kati.Screens.Season, %{}}

      named =
        Mob.Socket.assign(
          socket,
          :series,
          drawn |> Map.put(:tracked_id, "t1") |> Map.put(:current_season, "S3")
        )

      {:noreply, moved} = Kati.Screens.Series.handle_info({:tap, :episode_order}, named)

      assert moved.__mob__.nav_action ==
               {:push, Kati.Screens.Season, %{title_id: "t1", season: 3}}
    end

    test "an id that names no shelf row draws the drawing, not the shelf's head" do
      # `Kati.Screens.BookDetail.shelved_book/1`'s rule, held by the four
      # readers this round gave an argument to: a row archived or deleted under
      # the user is not the same fact as an empty shelf, and quietly
      # substituting a different title is the swap the argument prevents.
      gone = Ecto.UUID.generate()

      assert Kati.Screens.Film.film(gone) == Kati.Screens.Film.drawn_film()
      assert Kati.Screens.Series.series(gone) == Kati.Screens.Series.drawn_series()
      assert Kati.Screens.SeriesFa.series(gone) == Kati.Screens.SeriesFa.drawn_series()

      assert Kati.Screens.Season.season(%{title_id: gone}) ==
               Kati.Screens.Season.drawn_season()

      # And the no-id question is unchanged, which is the half every sweep
      # mounts.
      assert Kati.Screens.Film.film(nil) == Kati.Screens.Film.film()
      assert Kati.Screens.Series.series(nil) == Kati.Screens.Series.series()
      assert Kati.Screens.Season.season(%{}) == Kati.Screens.Season.season()
      assert Kati.Screens.Season.season(nil) == Kati.Screens.Season.season()
    end
  end

  # ── screens 66 and 68, where the control writes instead of pushing ─────────

  describe "Finish marks the book the page is drawing" do
    test "screen 66 finishes the second book and leaves the first alone" do
      a_book!(%{title: @prefix <> "The Salt Almanac", status: :reading})
      a_book!(%{title: @prefix <> "Marram Grass", status: :reading})

      {first, second} = two_books()

      tap_on_page(BookDetail, :book, BookDetail.shelved_book(second.id), :finish)

      assert Ash.get!(Book, second.id).status == :finished

      # The half that can fail on the defect. `finish_book/1` defaults to the
      # shelf's head, so a page opened on the second book used to finish the
      # first and then hand the reader to screen 33 to rate it.
      assert Ash.get!(Book, first.id).status == :reading
    end

    test "screen 68 is the same control under a different theme, and names the same book" do
      # `Kati.Screens.BookDetailDark.load/1` installs the dark palette, and
      # `Mob.Theme.set/1` is one global for the whole node — see
      # `Kati.ScreenSweep`'s own note. Put back what was installed, so this test
      # cannot decide what colour a later file renders in.
      installed = Mob.Theme.current()
      on_exit(fn -> Mob.Theme.set(installed) end)

      a_book!(%{title: @prefix <> "The Salt Almanac", status: :reading})
      a_book!(%{title: @prefix <> "Marram Grass", status: :reading})

      {first, second} = two_books()

      tap_on_page(
        Kati.Screens.BookDetailDark,
        :book,
        BookDetail.shelved_book(second.id),
        :finish
      )

      assert Ash.get!(Book, second.id).status == :finished
      assert Ash.get!(Book, first.id).status == :reading
    end

    test "the drawing carries no id, so a page with nothing shelved still finishes nothing" do
      # The fallback, pinned where it is actually read: both screens do
      # `book[:id]`, and the sample answers `nil` by absence rather than by
      # holding a `nil`. That is what makes the call literally `finish_book(nil)`
      # — today's path, and the one the empty-database sweep renders.
      refute Map.has_key?(BookDetail.drawn_book(), :id)
      assert BookDetail.drawn_book()[:id] == nil
    end
  end

  # ── screens 69 and 72, the Persian pair ────────────────────────────────────

  describe "screen 72 logs against the book that opened it" do
    test "the Persian page pushes its book's id, and the Persian sheet loads it" do
      a_book!(%{title: @prefix <> "The Salt Almanac", current_page: 214, page_count: 380})
      a_book!(%{title: @prefix <> "Marram Grass", current_page: 40, page_count: 120})

      {first, second} = two_books()

      # What `Kati.Screens.BookDetailFa.book/0` builds for a shelved row is the
      # fixture with the row's own fields over it, and the id is one of them.
      page = Map.put(Kati.Screens.BookDetailFa.drawn_book(), :id, second.id)

      view = tap_on_page(Kati.Screens.BookDetailFa, :book, page, :log_progress)

      assert {:push, Kati.Screens.LogProgressFa, %{book_id: id}} = pushed(view)
      assert id == second.id

      sheet = mount_screen(Kati.Screens.LogProgressFa, %{book_id: id})

      assert assigns(sheet).sheet.book == second.title
      refute assigns(sheet).sheet.book == first.title
      refute assigns(sheet).sheet.book == Kati.Screens.LogProgressFa.sheet(nil).book
    end

    test "no id is the drawing, and an id with no row is the drawing too" do
      a_book!(%{title: @prefix <> "The Salt Almanac"})

      # The whole of today's behaviour, and what every sweep mounts: screen 72
      # is pushed with no params and draws `Kati.Books.SampleFa.sheet/0`
      # untouched — the shelf's head is NOT substituted for a sheet nobody
      # handed anything to, because this board is a fixture rather than a page.
      assert mount_screen(Kati.Screens.LogProgressFa) |> assigns() |> Map.fetch!(:sheet) ==
               Kati.Screens.LogProgressFa.sheet(nil)

      assert Kati.Screens.LogProgressFa.sheet(nil) == Kati.Books.SampleFa.sheet()

      dead = a_book!(%{title: @prefix <> "Low Water"})
      Ash.destroy!(dead)

      assert Kati.Screens.LogProgressFa.sheet(dead.id) == Kati.Books.SampleFa.sheet()

      # And the caller's half: a drawn page names no book, so the push is bare.
      assert LogProgress.params_for(Kati.Screens.BookDetailFa.drawn_book()) == %{}
    end
  end
end
