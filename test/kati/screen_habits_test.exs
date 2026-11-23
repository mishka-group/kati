Code.require_file("../support/screen_sweep.exs", __DIR__)
Code.require_file("../support/design_literals.exs", __DIR__)

defmodule Kati.ScreenHabitsTest do
  @moduledoc """
  Screen 22 reads and writes its own store: empty is a sentence, Add writes a
  habit, and a square writes a tick.

  ## Why every row is prefixed and deleted

  This suite shares one SQLite file, and `Kati.ScreenEmptyDatabaseTest`,
  `Kati.ScreenDesignLiteralTest` and `Kati.ScreenSampleOnlyTest` render this
  screen against the same database. A habit left behind here turns the empty
  page into a page with a card on it, and the file that fails is one this one
  never touched. So the rows go before the test as well as after it: an
  interrupted run leaves the table dirty and the next run's `setup` clears it.
  """
  use Mob.ScreenCase, async: false

  alias Kati.DesignLiterals
  alias Kati.Habits
  alias Kati.ScreenSweep
  alias Kati.Screens.Habits, as: Screen

  @prefix "screen-22-test-"

  setup do
    delete_rows!()
    on_exit(&delete_rows!/0)
    :ok
  end

  describe "with nothing stored" do
    test "the page is a sentence and a button, not four invented habits" do
      assert {:ok, _socket, tree} = ScreenSweep.render(Screen)
      texts = DesignLiterals.rendered(tree)

      assert "no habits yet" in texts
      assert "morning run" not in texts, "a fresh install drew the drawing's own habits"
      assert "12-day best" not in texts
    end

    test "the read answers nothing, and the drawing is only a fixture" do
      assert Screen.habits() == []
      assert length(Screen.drawn_habits()) == 4
    end
  end

  describe "adding a habit" do
    test "the form opens, takes a name, and the page lists what was written" do
      view = mount_screen(Screen)

      assert assigns(render_info(view, {:tap, :new_habit})).adding? == true

      view =
        view
        |> render_info({:tap, :new_habit})
        |> render_info({:change, :habit_name, @prefix <> "Read"})
        |> render_info({:tap, :save_habit})

      assert assigns(view).adding? == false

      assert [%{name: name, streak: 0, today: false}] = assigns(view).habits
      assert name == @prefix <> "Read"

      assert [stored] = Habits.list()
      assert stored.name == @prefix <> "Read"
    end

    test "a blank name keeps the form open and says so" do
      view =
        mount_screen(Screen)
        |> render_info({:tap, :new_habit})
        |> render_info({:change, :habit_name, "   "})
        |> render_info({:tap, :save_habit})

      assert assigns(view).adding? == true
      assert assigns(view).save_error
      assert Habits.list() == []
    end

    test "cancel writes nothing" do
      view =
        mount_screen(Screen)
        |> render_info({:tap, :new_habit})
        |> render_info({:change, :habit_name, @prefix <> "Unwritten"})
        |> render_info({:tap, :cancel_habit})

      assert assigns(view).adding? == false
      assert Habits.list() == []
    end
  end

  describe "ticking" do
    setup do
      {:ok, habit} = Habits.add(@prefix <> "Water")
      %{habit: habit}
    end

    test "today's button writes a tick, and the streak moves with it", %{habit: habit} do
      view = mount_screen(Screen)

      assert [%{streak: 0, today: false}] = assigns(view).habits

      view = render_info(view, {:tap, {:toggle_today, habit.id}})

      assert [%{streak: 1, today: true}] = assigns(view).habits

      assert Map.has_key?(
               Habits.ticks(Kati.Time.today(), Kati.Time.today()),
               {habit.id, Kati.Time.today()}
             )
    end

    test "tapping again removes it, and the streak goes back", %{habit: habit} do
      view = mount_screen(Screen) |> render_info({:tap, {:toggle_today, habit.id}})
      view = render_info(view, {:tap, {:toggle_today, habit.id}})

      assert [%{streak: 0, today: false}] = assigns(view).habits
      assert Habits.ticks(Kati.Time.today(), Kati.Time.today()) == %{}
    end

    test "a square for yesterday writes that day", %{habit: habit} do
      yesterday = Date.add(Kati.Time.today(), -1)
      view = mount_screen(Screen)

      view = render_info(view, {:tap, {:toggle_day, habit.id, Date.to_iso8601(yesterday)}})

      assert [%{streak: 1}] = assigns(view).habits
      assert Map.has_key?(Habits.ticks(yesterday, yesterday), {habit.id, yesterday})
    end

    test "a field cell fills the whole day, and empties it again", %{habit: habit} do
      yesterday = Date.add(Kati.Time.today(), -1)
      iso = Date.to_iso8601(yesterday)
      view = mount_screen(Screen)

      view = render_info(view, {:tap, {:toggle_day_all, iso}})

      # Yesterday is Sunday, so it is in LAST week's strip — the field is the
      # only place it shows, which is exactly why it is the field that gets the
      # tap. The streak is the visible answer.
      assert [%{streak: 1}] = assigns(view).habits
      assert Map.has_key?(Habits.ticks(yesterday, yesterday), {habit.id, yesterday})

      view = render_info(view, {:tap, {:toggle_day_all, iso}})
      assert [%{streak: 0}] = assigns(view).habits
      assert Habits.ticks(yesterday, yesterday) == %{}
      _ = habit
    end

    test "the week strip marks today's square as kept", %{habit: habit} do
      view = mount_screen(Screen) |> render_info({:tap, {:toggle_today, habit.id}})

      assert [%{week: week}] = assigns(view).habits
      assert {Kati.Time.today(), :done} in week
    end
  end

  describe "deleting a habit" do
    setup do
      {:ok, habit} = Habits.add(@prefix <> "Old")
      {:ok, _kept} = Habits.toggle(habit.id, Kati.Time.today())
      %{habit: habit}
    end

    test "holding a card asks first, and Cancel destroys nothing", %{habit: habit} do
      view = mount_screen(Screen)

      assert assigns(view).confirming == nil

      view = render_info(view, {:long_press, {:confirm_delete, habit.id}})
      assert assigns(view).confirming == habit.id
      assert length(Habits.list()) == 1

      view = render_info(view, {:tap, :cancel_delete})
      assert assigns(view).confirming == nil
      assert length(Habits.list()) == 1
    end

    test "a confirmed Delete removes the habit and its ticks", %{habit: habit} do
      view =
        mount_screen(Screen)
        |> render_info({:long_press, {:confirm_delete, habit.id}})
        |> render_info({:tap, :confirm_delete})

      assert assigns(view).habits == []
      assert assigns(view).confirming == nil
      assert Habits.list() == []

      assert Habits.ticks(Kati.Time.today(), Kati.Time.today()) == %{},
             "the ticks were left behind, pointing at a habit that is gone"
    end

    test "the board's fixture cards have no hold" do
      # The drawing's cards name no row, so nothing on them can be held into a
      # Delete that cannot delete.
      for card <- Screen.drawn_habits() do
        refute Map.has_key?(Screen.card(card).props, :on_long_press)
      end
    end
  end

  describe "the field and the header" do
    test "one habit kept today is a one-day best and a full cell" do
      {:ok, habit} = Habits.add(@prefix <> "One")
      view = mount_screen(Screen) |> render_info({:tap, {:toggle_today, habit.id}})

      assert Screen.subtitle(assigns(view).habits) =~ "1 active · 1-day best"
      assert List.last(assigns(view).field) == :full
    end

    test "a broken streak says broken, not zero days" do
      assert Screen.streak_line(0) == "broken"
      assert Screen.streak_line(1) =~ "1 day"
      assert Screen.streak_line(12) =~ "12 days"
    end
  end

  defp delete_rows! do
    Kati.Repo.query!(
      "DELETE FROM habit_ticks WHERE habit_id IN (SELECT id FROM habits WHERE name LIKE ?1)",
      [@prefix <> "%"]
    )

    Kati.Repo.query!("DELETE FROM habits WHERE name LIKE ?1", [@prefix <> "%"])
  end
end
