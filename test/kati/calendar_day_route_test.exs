defmodule Kati.CalendarDayRouteTest do
  @moduledoc """
  The route from screen 02 (Schedule) to screen 09 (a heavy day), and back.

  ## What was missing

  Screen 09 is drawn as a pushed screen under this root — its back pill reads
  `‹ Calendar` — and nothing on 02 opened it. The other calendar views reach
  it through `Kati.Screens.ViewSwitcher`; the Schedule root draws no switcher,
  so the drawing's own back pill pointed at a screen that could not be got to.

  `Kati.Screens.Calendar` now gives the gesture to the day cell that is
  **already selected**: the first tap on a cell selects that date, a second tap
  on the same cell opens it. The argument for that control over the `Today`
  pill lives beside the code, in `handle_tap/2`.

  ## Why these tests are shaped the way they are

  Two failures are possible here and only one of them is obvious.

    * **The obvious one** — the open gesture does not push. Caught by
      `handle_tap/2` returning a socket with no nav action.

    * **The one that would matter more** — the open gesture eats the
      *selection*. One tag now carries two meanings, so a branch on the wrong
      side of the `==` turns every day cell into a push and the week strip
      stops selecting anything at all, while the screen's resting pixels stay
      exactly as they were. Every test below that taps a day therefore asserts
      on BOTH halves: what the assigns became AND what the screen navigated
      to, because either one alone passes while the other is broken.

  The last test drives the real `Mob.Screen` navigation stack rather than a
  socket, because "back returns to the Schedule root" is a claim about that
  stack: `apply_nav_action/3` saves `{module, socket}` on push and restores
  that exact pair on pop (`mob/lib/mob/screen.ex:554-580`). Asserting
  `pop_screen/1` was *requested* would prove nothing about where it lands, or
  that the day the user had selected survives the trip.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Screens.Calendar
  alias Kati.Screens.Day
  alias Kati.Theme

  # `day_strip/1` draws the Monday-to-Sunday week around the selected date.
  # Asserted as a number, not as "more than zero": a strip that resolved to a
  # single cell would satisfy every other test in this file, since the one cell
  # left would be the selected one.
  @strip_cells 7

  describe "the week strip" do
    test "draws one tappable cell per day of the week around the selected date" do
      view = mount_screen(Calendar)
      cells = day_cells(view)

      assert length(cells) == @strip_cells,
             "the strip drew #{length(cells)} tappable day cells, not #{@strip_cells}: " <>
               inspect(Enum.map(cells, &elem(&1, 1)))

      dates = cells |> Enum.map(&elem(&1, 1)) |> Enum.sort(Date)

      assert Date.day_of_week(hd(dates)) == 1, "the strip does not start on a Monday"
      assert Date.diff(List.last(dates), hd(dates)) == @strip_cells - 1
      assert assigns(view).date in dates, "the selected date is not one of the cells drawn"
    end

    test "paints exactly one cell as selected, and it is the assigned date" do
      view = mount_screen(Calendar)
      date = assigns(view).date

      selected = for {tag, d} <- day_cells(view), cell_fill(view, tag) == Theme.ink(), do: d

      assert selected == [date],
             "the ink cell must be the selected date and nothing else, got #{inspect(selected)}"

      for {tag, d} <- day_cells(view), d != date do
        assert cell_fill(view, tag) == Theme.card(:light),
               "#{d} is not selected but is not drawn on card white"
      end
    end
  end

  describe "selecting a different day" do
    test "changes the date and reloads that day's rows without navigating" do
      view = mount_screen(Calendar)
      %{date: was, rows: drawn} = assigns(view)

      # The screen opens on today, which falls back to the five rows the
      # drawing shows — so there is something for the reload to change FROM.
      assert length(drawn) == 5,
             "expected the drawn day's five rows on mount, got #{length(drawn)}"

      {tag, date} = other_day(view)
      view = tapped(view, tag)

      assert navigated_to(view) == nil, "selecting a day must not leave the Schedule"
      assert assigns(view).date == date
      assert assigns(view).rows == Calendar.day_rows(date)

      refute assigns(view).rows == drawn,
             "the rows were not reloaded — the strip changed the date and nothing else"

      assert assigns(view).date != was
    end

    test "moves the ink cell and redraws the timeline for the day tapped" do
      view = mount_screen(Calendar)
      was = assigns(view).date
      {tag, date} = other_day(view)

      view = tapped(view, tag)

      assert cell_fill(view, tag) == Theme.ink()
      assert cell_fill(view, day_tag(was)) == Theme.card(:light)

      # A day with no mirrored events shows its real emptiness, and that empty
      # card is the proof the reload reached the render rather than stopping at
      # the assigns.
      assert text(view) =~ "Nothing scheduled today"
      assert text(view) =~ "#{date.day} #{Kati.Time.month_name(date.month)}"
    end

    test "every unselected cell selects, and none of them navigates" do
      view = mount_screen(Calendar)
      date = assigns(view).date

      for {tag, d} <- day_cells(view), d != date do
        stepped = tapped(view, tag)

        assert navigated_to(stepped) == nil, "#{d} navigated instead of selecting"
        assert assigns(stepped).date == d
      end
    end
  end

  describe "opening the selected day" do
    test "a second tap on the selected cell pushes screen 09" do
      view = mount_screen(Calendar)
      date = assigns(view).date

      opened = tapped(view, day_tag(date))

      assert navigated_to(opened) == Day
    end

    test "the push names the day that was open, not the clock" do
      view = mount_screen(Calendar)
      {tag, date} = other_day(view)

      # Select first, then open — so the date the route carries is provably the
      # SELECTED day and not `Kati.Time.today()` arriving by coincidence.
      opened = view |> tapped(tag) |> tapped(tag)

      assert date != Kati.Time.today()
      assert navigated_to(opened) == Day
      assert opened.socket.__mob__.nav_action == {:push, Day, %{date: date}}
    end

    test "opening leaves the Schedule's own state exactly as it was" do
      view = mount_screen(Calendar)
      before = assigns(view)

      opened = tapped(view, day_tag(before.date))

      # The socket the nav stack saves on push is this one, so anything the
      # open gesture changed here is what the user would find on the way back.
      assert assigns(opened).date == before.date
      assert assigns(opened).rows == before.rows
      assert assigns(opened).filter == before.filter
    end
  end

  describe "the way back from screen 09" do
    test "the back pill is drawn, tagged :back, and labelled for this root" do
      view = mount_screen(Day)
      label = Enum.find(Kati.Shell.roots(), &(&1.id == :calendar)).label

      pill = find(view, :row, on_tap: {self(), :back})
      assert pill, "screen 09 draws no control tagged :back"

      # Matched as its own Text node rather than against `text(pill)`, which
      # also picks up the `arrow_back_ios_new` glyph the pill draws beside the
      # word — `Kati.UI.symbol/2` renders a Material Symbol as a Text carrying
      # the private-use codepoint, so the joined string is " Calendar".
      assert find(pill, :text, text: label),
             "the back pill reads #{inspect(text(pill))}; the root it returns to is " <>
               "#{inspect(label)}, and the drawing gives the pill that root's name"

      assert Kati.Shell.screen_for(:calendar) == Calendar
      assert navigated_to(tapped(view, :back)) == {:pop}
    end

    test "back off screen 09 lands on the Schedule root with the day still selected" do
      pid = screen_process(Calendar)
      {tag, date} = other_day(Calendar.render(socket(pid).assigns))

      # Move the selection off today first: what comes back has to be provably
      # the screen we left, not a freshly mounted Schedule that happens to look
      # the same because it also opens on today.
      send(pid, {:tap, tag})
      assert Mob.Screen.get_current_module(pid) == Calendar
      assert socket(pid).assigns.date == date

      send(pid, {:tap, tag})
      assert Mob.Screen.get_current_module(pid) == Day
      assert length(Mob.Screen.get_nav_history(pid)) == 1

      send(pid, {:tap, :back})

      assert Mob.Screen.get_current_module(pid) == Calendar
      assert Mob.Screen.get_nav_history(pid) == [], "the pop left something on the stack"

      back = socket(pid)
      assert back.assigns.root == :calendar
      assert back.assigns.date == date
      assert back.assigns.rows == Calendar.day_rows(date)
    end
  end

  # ── helpers ────────────────────────────────────────────────────────────────

  defp tapped(view, tag), do: render_info(view, {:tap, tag})

  defp day_tag(date), do: String.to_atom("day_" <> Date.to_iso8601(date))

  # `{tag, date}` for every day cell the tree draws, read off `on_tap` rather
  # than recomputed from the date — a helper that rebuilt the week here would
  # agree with a broken `day_strip/1` about which days exist.
  defp day_cells(view_or_tree) do
    view_or_tree
    |> flatten()
    |> Enum.flat_map(fn node ->
      case Map.get(Map.get(node, :props) || %{}, :on_tap) do
        {pid, tag} when is_pid(pid) -> day_pair(tag)
        _ -> []
      end
    end)
    |> Enum.uniq()
  end

  defp day_pair(tag) do
    case Atom.to_string(tag) do
      "day_" <> iso -> [{tag, Date.from_iso8601!(iso)}]
      _ -> []
    end
  end

  defp other_day(view_or_tree) do
    selected = day_cells(view_or_tree) |> Enum.map(&elem(&1, 1))

    # The selected date is the one drawn in ink, but this helper is also used
    # against a bare tree where the assigns are not to hand — so pick the first
    # cell that is not today, which is the day the screen opens on.
    Enum.find(day_cells(view_or_tree), fn {_tag, d} -> d != Kati.Time.today() end) ||
      flunk("the strip drew no day other than today: #{inspect(selected)}")
  end

  # The fill of the `Column` inside one day cell — `day_cell/2` paints the
  # selected one in ink and the rest on card white, and that is the only thing
  # on this screen that says which day the next tap will open.
  defp cell_fill(view_or_tree, tag) do
    cell = find(view_or_tree, :box, on_tap: {self(), tag})
    assert cell, "no day cell is tagged #{inspect(tag)}"

    column = find(cell, :column)
    assert column, "the cell tagged #{inspect(tag)} holds no Column to be filled"

    column.props[:background]
  end

  # A real screen process in `:no_render` mode: mounts and dispatches through
  # `Mob.Screen`'s own navigation stack, and touches no NIF.
  defp screen_process(module) do
    start_supervised!(%{
      id: {Mob.Screen, module},
      start: {Mob.Screen, :start_link, [module, %{}]}
    })
  end

  defp socket(pid), do: Mob.Screen.get_socket(pid)
end
