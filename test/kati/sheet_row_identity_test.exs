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
end
