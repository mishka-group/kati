defmodule Kati.GoalsMoneyTest do
  @moduledoc """
  Goals and Money — screens 104, 106, 122, 124 and 125.

  ## The two things worth pinning hardest

    * **The projection.** Screen 104's whole design is that it states where you
      land and never how you feel about it. That is arithmetic, and arithmetic
      that quietly went wrong would still read as a sentence.
    * **That changing currency touches nothing.** Screen 125 promises `£8.99
      becomes €8.99, not €10.42`, and the promise is only as good as there
      being no code path that rewrites an amount. Asserted directly.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Goals.Goal
  alias Kati.Money
  alias Kati.Money.Expense
  alias Kati.Screens.Currency
  alias Kati.Screens.Goals
  alias Kati.Screens.Money, as: MoneyScreen
  alias Kati.Screens.NewGoal
  alias Kati.Screens.QuickAddExpense

  setup do
    on_exit(fn ->
      Kati.Repo.query!("DELETE FROM goals", [])
      Kati.Repo.query!("DELETE FROM expenses", [])
    end)

    :ok
  end

  defp a_goal!(attrs \\ %{}) do
    Ash.create!(
      Goal,
      Map.merge(
        %{
          kind: :books,
          target: 52,
          progress: 38,
          period: :year,
          starts_on: ~D[2026-01-01],
          ends_on: ~D[2026-12-31]
        },
        attrs
      )
    )
  end

  describe "the projection" do
    # Half way through the year, 38 of 52 read. 38 × 365 / 182 is 76, capped at
    # the target.
    @mid ~D[2026-07-01]

    test "it extrapolates the rate so far across the whole period" do
      goal = %Goal{
        kind: :films,
        target: 120,
        progress: 60,
        starts_on: ~D[2026-01-01],
        ends_on: ~D[2026-12-31]
      }

      assert Goal.project(goal, @mid) == 120
      assert Goal.project(%Goal{goal | progress: 30}, @mid) == 60
    end

    test "it never projects past the target" do
      # `on pace to finish 140 of 120` is not something a goal card should say.
      goal = %Goal{target: 120, progress: 110, starts_on: ~D[2026-01-01], ends_on: ~D[2026-12-31]}

      assert Goal.project(goal, @mid) == 120
    end

    test "one day of data is not a projection" do
      # Extrapolating a single day over a year is a multiplication, and
      # presenting it as a forecast would be the screen's one dishonest number.
      goal = %Goal{target: 120, progress: 3, starts_on: ~D[2026-01-01], ends_on: ~D[2026-12-31]}

      assert Goal.project(goal, ~D[2026-01-01]) == nil
      assert Goal.project(goal, ~D[2026-01-02]) != nil
    end
  end

  describe "pace" do
    @mid ~D[2026-07-01]

    test "the middle band is wide enough not to report noise as news" do
      # Half way through a 120 goal, the even line is ~60. Everything within
      # five per cent of it is on pace, so the card does not flip daily.
      for progress <- [58, 60, 62] do
        goal = %Goal{
          target: 120,
          progress: progress,
          starts_on: ~D[2026-01-01],
          ends_on: ~D[2026-12-31]
        }

        assert Goal.pace(goal, @mid) == :on_pace
      end
    end

    test "well clear of the line reads as ahead or behind" do
      base = %Goal{target: 120, starts_on: ~D[2026-01-01], ends_on: ~D[2026-12-31]}

      assert Goal.pace(%Goal{base | progress: 90}, @mid) == :ahead
      assert Goal.pace(%Goal{base | progress: 30}, @mid) == :behind
    end

    test "no percentage is offered beside on pace" do
      goal = %Goal{target: 120, progress: 60, starts_on: ~D[2026-01-01], ends_on: ~D[2026-12-31]}

      shown = Goals.shaped(goal, @mid)

      assert shown.pace_label == "On pace"
      # A number attached to `On pace` invites reading the band as a failure,
      # which is the one reading this page is written to avoid.
      assert shown.drift == nil
    end

    test "the drift is a whole percentage off the even line" do
      goal = %Goal{target: 120, progress: 90, starts_on: ~D[2026-01-01], ends_on: ~D[2026-12-31]}

      assert Goals.shaped(goal, @mid).drift == "50%"
    end
  end

  describe "what counts" do
    test "every kind carries the sentence that says what it counts" do
      # The D-14 question made visible rather than deferred. A kind cannot
      # arrive without one, because the sentence lives beside the kind.
      for {kind, _section, _unit, counts} <- Goal.kinds() do
        assert is_binary(counts) and counts != ""
        assert Goal.counts(kind) == counts
      end
    end

    test "the books sentence is the one the drawing prints" do
      assert Goal.counts(:books) ==
               "Counts finished books only. A book you did not finish counts its pages " <>
                 "toward the pages goal, not this one."
    end

    test "the ten kinds fall into four sections" do
      assert Goal.sections() == ["Screen", "Books", "Music", "Health"]
      assert length(Goal.kinds()) == 10
    end
  end

  describe "screen 104" do
    test "the page reads stored goals rather than the drawing" do
      a_goal!(%{kind: :films, target: 120, progress: 84})

      assert [shown] = Goals.goals()
      assert shown.title == "120 films this year"
      assert shown.target == 120
    end

    test "the subtitle counts what is actually live" do
      a_goal!()
      a_goal!(%{kind: :films, target: 120})

      assert Goals.subtitle() =~ "2 ACTIVE"
    end

    test "a goal whose period has closed is not on the page" do
      a_goal!(%{starts_on: ~D[2020-01-01], ends_on: ~D[2020-12-31]})

      assert Goals.goals() == Goals.drawn_goals()
    end

    test "repeat writes through to every live goal" do
      goal = a_goal!(%{repeat: true})

      view = mount_screen(Goals)
      assert assigns(view).repeat == true

      toggled = render_info(view, {:tap, :toggle_repeat})

      assert assigns(toggled).repeat == false
      assert Ash.get!(Goal, goal.id).repeat == false
    end

    test "with nothing stored the drawing renders, whole" do
      assert Goals.goals() == Goals.drawn_goals()
    end
  end

  describe "screen 106" do
    test "the window follows the period and today, and is stored" do
      # A goal set in March runs to 31 December. Deriving the window at read
      # time would silently move the deadline of every goal set mid-period.
      assert NewGoal.window(:period_year, ~D[2026-03-14]) == {~D[2026-01-01], ~D[2026-12-31]}
      assert NewGoal.window(:period_month, ~D[2026-03-14]) == {~D[2026-03-01], ~D[2026-03-31]}
      assert NewGoal.window(:period_week, ~D[2026-03-14]) == {~D[2026-03-09], ~D[2026-03-15]}
    end

    test "saving writes a goal with the chosen type, target and window" do
      view = mount_screen(NewGoal)

      built =
        view
        |> render_info({:tap, :kind_books})
        |> render_info({:tap, :step_up})
        |> render_info({:tap, :period_month})

      assert assigns(built).kind == :books
      assert assigns(built).target == 121

      render_info(built, {:tap, :save})

      assert [goal] = Ash.read!(Goal)
      assert goal.kind == :books
      assert goal.target == 121
      assert goal.period == :month
      assert goal.starts_on == Date.beginning_of_month(Kati.Time.today())
    end

    test "the target cannot go below one" do
      view = mount_screen(NewGoal)
      floored = Enum.reduce(1..200, view, fn _i, v -> render_info(v, {:tap, :step_down}) end)

      assert assigns(floored).target == 1
    end

    test "the repeat line names the day the next period starts" do
      # A switch that only said `Repeat` would be one the user has to test.
      assert NewGoal.restart_line(:period_year) == "Restarts 1 January"
      assert NewGoal.restart_line(:period_month) == "Restarts on the 1st"
      assert NewGoal.restart_line(:period_week) == "Restarts every Monday"
    end

    test "closing writes nothing" do
      closed =
        mount_screen(NewGoal) |> render_info({:tap, :step_up}) |> render_info({:tap, :close})

      assert navigated_to(closed) == {:pop}
      assert Ash.read!(Goal) == []
    end
  end

  describe "money" do
    test "an amount is minor units all the way through" do
      assert Money.format(899, "GBP") =~ "8.99"
      assert Money.format(900, "GBP") =~ "9.00"
      assert Money.format(0, "GBP") =~ "0.00"
    end

    test "cost per hour is an em dash for a service nothing was watched on" do
      # Undefined, not zero and not infinity. Printing anything numeric there
      # would be inventing a figure.
      assert Money.per_hour(1399, 0) == "—"
      assert Money.per_hour(1399, 6) =~ "2.33"
    end

    test "an expense with no amount is still an expense" do
      # Screen 124's whole subject.
      expense = %Expense{description: "Blue Hour", amount_pence: nil, spent_on: ~D[2026-08-16]}

      assert Expense.amount(expense) == nil
      assert Expense.meta(%Expense{expense | section: :screen}) == "16 AUG · SCREEN"
    end

    test "months group newest first, and an unpriced row totals nothing" do
      expenses = [
        %Expense{description: "a", amount_pence: 349, spent_on: ~D[2026-08-16], section: :screen},
        %Expense{description: "b", amount_pence: nil, spent_on: ~D[2026-08-12], section: :books},
        %Expense{description: "c", amount_pence: 2800, spent_on: ~D[2026-07-28], section: :music}
      ]

      assert [{"August", 349, august}, {"July", 2800, _july}] = Expense.by_month(expenses)
      assert length(august) == 2
    end
  end

  describe "screen 122" do
    test "the page reads stored expenses rather than the drawing" do
      Ash.create!(Expense, %{
        description: "Cinema — Vellum",
        amount_pence: 1400,
        spent_on: Kati.Time.today(),
        section: :screen
      })

      assert [%{rows: [row]}] = MoneyScreen.months()
      assert row.name == "Cinema — Vellum"
    end

    test "the subtitle counts this calendar month" do
      Ash.create!(Expense, %{
        description: "x",
        amount_pence: 100,
        spent_on: Kati.Time.today(),
        section: :other
      })

      assert MoneyScreen.subtitle() =~ "1 EXPENSE THIS MONTH"
    end

    test "dismissing the suggestion takes it off the page and writes nothing" do
      view = mount_screen(MoneyScreen)
      assert MoneyScreen.suggestion(false) != []

      dismissed = render_info(view, {:tap, :dismiss})

      assert assigns(dismissed).dismissed? == true
      assert MoneyScreen.suggestion(true) == []
    end

    test "with nothing stored the drawing renders, whole" do
      assert MoneyScreen.months() == MoneyScreen.drawn_months()
    end
  end

  describe "screen 124" do
    test "saving writes an expense, amount or no amount" do
      view = mount_screen(QuickAddExpense)

      assert assigns(view).draft.amount == nil

      render_info(view, {:tap, :add})

      assert [expense] = Ash.read!(Expense)
      assert expense.description == "The Salt Almanac"
      assert expense.amount_pence == nil
      assert expense.section == :books
      assert expense.currency == Money.currency()
    end

    test "the field says saving without an amount is allowed" do
      tree = tree(mount_screen(QuickAddExpense))

      assert find(tree, :text, text: "no amount found") != nil

      # One `Text` rather than three, because `Kati.UI.rich_text/1` merges its
      # runs — the emphasis is real and the node is one.
      assert find(tree, :text,
               text:
                 "Type it, or save without — an expense with no amount still counts as a " <>
                   "thing that happened."
             ) != nil
    end

    test "screen 18's Expense chip is what reaches this screen" do
      pushed = render_info(mount_screen(Kati.Screens.QuickAdd), {:tap, :file_as_expense})

      assert navigated_to(pushed) == QuickAddExpense
    end
  end

  describe "screen 125" do
    test "picking does not switch — it asks" do
      # A currency that switched on a tap would be exactly the silent change the
      # confirmation exists to prevent.
      view = mount_screen(Currency)
      asked = render_info(view, {:tap, :pick_USD})

      assert assigns(asked).confirming == "USD"
      assert Money.currency() == "GBP"
    end

    test "switching stores it and clears the confirmation" do
      switched =
        mount_screen(Currency) |> render_info({:tap, :pick_USD}) |> render_info({:tap, :switch})

      assert Money.currency() == "USD"
      assert assigns(switched).confirming == nil
    end

    test "keeping clears the confirmation and changes nothing" do
      kept =
        mount_screen(Currency) |> render_info({:tap, :pick_USD}) |> render_info({:tap, :keep})

      assert assigns(kept).confirming == nil
      assert Money.currency() == "GBP"
    end

    test "changing the currency does not touch a stored figure" do
      # The promise the confirmation makes, asserted directly: £8.99 becomes
      # €8.99, not €10.42.
      expense =
        Ash.create!(Expense, %{
          description: "The Salt Almanac",
          amount_pence: 899,
          currency: "GBP",
          spent_on: Kati.Time.today(),
          section: :books
        })

      Money.put_currency("EUR")

      stored = Ash.get!(Expense, expense.id)
      assert stored.amount_pence == 899
      assert stored.currency == "GBP"
      assert Expense.amount(stored) =~ "8.99"
    end

    test "the confirmation is drawn before anything is picked" do
      # The list is five rows; the screen exists for the sentence underneath it,
      # and a page that hid its own subject until you tapped something would be
      # a page whose subject most people never read.
      view = mount_screen(Currency)

      assert assigns(view).confirming == "EUR"
      assert find(tree(view), :text, text: "Switch to EUR?") != nil
    end

    test "Persian formatting comes from CLDR, word after the figure" do
      example = Currency.formatted_example("GBP", "fa")

      # Arabext digits, U+066C group, U+066B decimal, and the currency NAME
      # trailing — which is the block's whole claim.
      assert example =~ "۱٬۲۳۴٫۵۶"
      assert example =~ "پوند"
      refute String.starts_with?(example, "£")
    end

    test "English formatting leads with the symbol" do
      assert Currency.formatted_example("GBP", "en") =~ "£1,234.56"
    end
  end

  describe "the five screens render" do
    test "each one draws a tree the native layer can take" do
      for module <- [Goals, NewGoal, MoneyScreen, QuickAddExpense, Currency] do
        assert_renderable(mount_screen(module))
      end
    end
  end
end
