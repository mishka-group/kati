Code.require_file("../support/screen_sweep.exs", __DIR__)

defmodule Kati.MealsRoutesTest do
  @moduledoc """
  The Meals section's navigation, checked from both ends of every wire.

  ## The defect this exists for

  `Kati.ScreenTapSweepTest` asks "does something answer every tag a screen
  draws". It cannot ask the mirror question — "does anything *draw* the tag
  this handler answers" — and that half went wrong on screen 43 in a way
  nothing could see. `Kati.Screens.MealsToday` carried

      def handle_tap(:open_plan, socket), do: push_screen(socket, MealPlan)
      def handle_tap(:open_shopping, socket), do: push_screen(socket, Shopping)
      def handle_tap(:open_nutrition, socket), do: push_screen(socket, Nutrition)

  and `tile/2` — the function that draws the four quick tiles those clauses
  name — passed no `on_tap` at all. Three correct destinations, three tiles
  that looked exactly right and did nothing, and three screens (44, 47, 48)
  reachable only from `Kati.Screens.Gallery`. Every existing test passed: the
  screens render, the drawn tags are all answered, and a `Box` with no
  `on_tap` is drawn identically to one that has it.

  So each route below is asserted in two halves that fail separately:

    * the tag is in the tags the screen actually **drew**, read off the
      rendered tree by `Kati.ScreenSweep.tap_tags/1`; and
    * dispatching it down that screen's real `handle_info/2` asks for a push
      to the module named here.

  ## And one question neither sweep asks

  `every Meals screen is reachable without the gallery` walks the whole app's
  push graph from the four shell roots. `Kati.Screens.Gallery` is excluded
  from the walk on purpose — it reaches all 62 screens by construction, so
  leaving it in makes the reachability question unanswerable.
  """
  use Mob.ScreenCase, async: false

  alias Kati.ScreenSweep
  alias Kati.Screens

  # The resting-appearance assertions in this file are the DRAWING's numbers,
  # and the drawing is light. That used to be a fact about the markup — screen
  # 43 wrote `Kati.Theme.card(:light)`, which is one colour whoever asks. It is
  # now a fact about the installed palette: the screen writes
  # `Kati.Theme.Palette.card/0`, which resolves against `Mob.Theme.current/0`.
  # So a file that asserts a light literal has to say that it means light.
  #
  # Without it the file passed or failed on the ExUnit seed. `push_graph/1`,
  # two tests above, dispatches every tag every screen drew — including screen
  # 24's Dark tile, which stores the choice and calls `Kati.Theme.activate/0`
  # exactly as a real tap does — and the palette that leaves behind is
  # application environment, one global for the whole run.
  # `Kati.ScreenSweep.with_theme/1` now closes that at the source; this states
  # the premise anyway, because a test asserting a colour should not depend on
  # what some other pass left installed.
  setup do
    installed = Mob.Theme.current()
    Mob.Theme.set(Kati.Theme.light())
    on_exit(fn -> Mob.Theme.set(installed) end)
    :ok
  end

  # The route table, in the order a user walks it. Each row is
  # `{from, tag, to, why}` — `why` names the control in the drawing, so a
  # failure says which pixels it was supposed to belong to.
  @routes [
    {Screens.MealsToday, {:prefix, "meal_"}, Screens.Meal, "43's meal card → 45"},
    {Screens.MealsToday, :open_week, Screens.MealPlan, "43's Week tile → 44"},
    {Screens.MealsToday, :open_shopping, Screens.Shopping, "43's Shop tile → 48"},
    {Screens.MealsToday, :open_nutrition, Screens.Nutrition, "43's Nutrition tile → 47"},
    {Screens.MealsToday, :open_plan, Screens.Plans, "43's Plan tile → 49"},
    {Screens.MealsToday, :switch_plan, Screens.Plans, "43's Cutting v3 pill → 49"},
    {Screens.Meal, :swap, Screens.MealSwap, "45's swap_horiz button → 46"},
    {Screens.MealPlan, :edit_plan, Screens.Plans, "44's edit disc → 49"},
    {Screens.Plans, :share_plan, Screens.PlanShare, "49's active-card more_horiz → 50"}
  ]

  # Screens 43–50. Screen 51 is deliberately absent: no drawing in the set
  # gives it a control, which `Kati.Screens.MealReminders`' moduledoc sets out
  # glyph by glyph. It is the one Meals screen the gallery still has to reach,
  # and `screen 51 is the only Meals screen with no way in` is what keeps that
  # statement honest — the day the design grows the control and someone wires
  # it, that test fails and this list gains a line.
  @meals_screens [
    Screens.MealsToday,
    Screens.MealPlan,
    Screens.Meal,
    Screens.MealSwap,
    Screens.Nutrition,
    Screens.Shopping,
    Screens.Plans,
    Screens.PlanShare
  ]

  @roots Enum.map(Kati.Shell.roots(), & &1.screen)

  test "the route table is not empty and names distinct controls" do
    # The guard on every table-driven test below. A `for` over an empty list
    # asserts nothing and passes, and this file would then be nine tests of
    # silence.
    assert length(@routes) == 9

    tags = Enum.map(@routes, fn {from, tag, _to, _why} -> {from, tag} end)
    assert Enum.uniq(tags) == tags, "two rows claim the same control"
  end

  test "every quick tile on screen 43 carries a tap" do
    taps = Screens.MealsToday.tile_taps()
    icons = Enum.map(Kati.Meals.SampleToday.tiles(), fn {icon, _label} -> icon end)

    assert length(icons) == 5, "the drawing gives Meals five tiles, not #{length(icons)}"
    assert map_size(taps) == 5

    missing = icons -- Map.keys(taps)

    assert missing == [],
           "these tiles are drawn with no destination, so they are painted " <>
             "buttons: #{inspect(missing)}"

    # `tile/2` uses `Map.fetch!`, so an unmapped icon raises rather than
    # yielding `on_tap={nil}` — the shape the bridge drops in silence. Proven
    # here rather than assumed, because the whole point of the fetch! is that
    # it is loud.
    assert_raise KeyError, fn -> Screens.MealsToday.tile("no_such_glyph", "Nope") end
  end

  test "wiring the two new controls added a handler and no ink" do
    # THE RULE for this repo is that a screen's resting appearance must not
    # change unless the drawing says it should, and the two controls wired here
    # were already drawn — the tiles on 43 and the disc on 49's active card.
    # `on_tap` is merged onto the node the component already built
    # (`Kati.Components.MishkaActionIcon.container/2`), so the check is that
    # every OTHER prop is still the drawing's number.
    [_weight_box, tile | _] = Mob.ScreenCase.flatten(Screens.MealsToday.tile("tune", "Plan"))

    assert tile.type == :box
    assert {_pid, :open_plan} = tile.props.on_tap

    assert Map.delete(tile.props, :on_tap) == %{
             fill_width: true,
             align: "center",
             background: Kati.Theme.card(:light),
             shadow: Kati.Theme.shadow_card_soft(),
             corner_radius: 16,
             padding_left: 8,
             padding_right: 8,
             padding_top: 11,
             padding_bottom: 11
           }

    [disc | _] = Mob.ScreenCase.flatten(Screens.Plans.overflow())

    assert disc.type == :box
    assert {_pid, :share_plan} = disc.props.on_tap

    # `rgba(245,242,238,.12)` — a white-ish veil ON the ink card, which is why
    # it is an ARGB literal in the screen and stays one here.
    assert Map.delete(disc.props, :on_tap) == %{
             width: 36,
             height: 36,
             align: :center,
             corner_radius: 18.0,
             background: 0x1FF5F2EE
           }
  end

  test "every route's tag is actually drawn by the screen it belongs to" do
    # The half `Kati.ScreenTapSweepTest` structurally cannot ask. A handler for
    # a tag nothing draws is a destination with no door.
    drawn = ScreenSweep.drawn_taps(:en)

    assert map_size(drawn) >= length(@meals_screens),
           "the render pass produced #{map_size(drawn)} screens, so this test " <>
             "is checking almost nothing"

    orphans =
      for {from, tag, _to, why} <- @routes,
          {_socket, tags} = Map.fetch!(drawn, from),
          resolve_tag(tag, tags) == nil do
        "  #{inspect(from)} answers #{inspect(tag)} (#{why}) but draws no control that sends it"
      end

    assert orphans == [], "\n" <> Enum.join(orphans, "\n")
  end

  test "every route pushes the screen its drawing names" do
    drawn = ScreenSweep.drawn_taps(:en)

    wrong =
      for {from, tag, to, why} <- @routes,
          {socket, tags} = Map.fetch!(drawn, from),
          resolved = resolve_tag(tag, tags),
          landed = resolved && push_target(from, socket, resolved),
          landed != to do
        "  #{inspect(from)} #{inspect(tag)} (#{why}) went to #{inspect(landed)}, not #{inspect(to)}"
      end

    assert wrong == [], "\n" <> Enum.join(wrong, "\n")
  end

  test "every Meals screen is reachable without the gallery" do
    graph = push_graph(:en)

    # Not a formality. `Kati.Screens.Gallery` is excluded below, and if the
    # exclusion ever took the whole graph with it every screen would be
    # "unreachable" and this test would fail loudly — but the opposite mistake,
    # a graph that reaches everything because the exclusion silently missed,
    # passes in silence. Both roots and edges are asserted to exist.
    assert length(@roots) == 4
    assert map_size(graph) > 20, "only #{map_size(graph)} screens draw any push at all"

    reached = reachable(graph, @roots)

    assert MapSet.size(reached) > 20,
           "the walk reached #{MapSet.size(reached)} screens, which is too few to " <>
             "have walked anything"

    unreachable = Enum.reject(@meals_screens, &MapSet.member?(reached, &1))

    assert unreachable == [],
           "these Meals screens have no path from any of the four shell roots, so " <>
             "only Kati.Screens.Gallery can open them:\n" <>
             Enum.map_join(unreachable, "\n", &("  " <> inspect(&1)))
  end

  test "screen 51 is the only Meals screen with no way in" do
    # An inventory, not an aspiration. If someone wires
    # `Kati.Screens.MealReminders` this fails and the fix is one line in
    # `@meals_screens` plus deleting the "Nothing in the design opens this
    # screen" section from its moduledoc. If someone breaks another Meals
    # route, the test above fails first and this one stays quiet — the two
    # failures do not overlap.
    reached = reachable(push_graph(:en), @roots)

    refute MapSet.member?(reached, Screens.MealReminders),
           "Kati.Screens.MealReminders is reachable now. Delete the 'Nothing in " <>
             "the design opens this screen' section from its moduledoc, add it to " <>
             "@meals_screens here, and add its route to @routes."

    assert Screens.MealReminders in Enum.map(Screens.Gallery.screens(), fn {_, _, m, _} -> m end),
           "the gallery is the only way into screen 51 and it no longer lists it"
  end

  test "Plans answers every tag it draws and supplies no catch-all" do
    # `Kati.Screens.Pushed` reports a tag nothing answers as a DEAD TAP, and a
    # `_tag ->` clause on this screen would answer every future control with
    # silence. Asserted directly: the real tag returns a push, and a tag the
    # screen does not draw raises rather than being absorbed.
    {socket, tags} = Map.fetch!(ScreenSweep.drawn_taps(:en), Screens.Plans)

    # `:back` belongs to `Kati.Screens.Pushed`'s chrome and is answered there,
    # never reaching `handle_tap/2` — so it is dropped here for the same reason
    # `Kati.ScreenTapSweepTest` drops it.
    own = Enum.reject(tags, &ScreenSweep.shell_tag?/1)

    # Two now: `import_plan` joined when screen 120 landed. The assertion is
    # still "every tag Plans draws has its own clause and there is no
    # catch-all", which is what this test is for — the list is the fact it
    # checks against, not the fact it asserts.
    assert Enum.sort(own) == [:import_plan, :share_plan],
           "screen 49 now draws #{inspect(own)}; every one of them needs a clause"

    assert push_target(Screens.Plans, socket, :share_plan) == Screens.PlanShare

    # Built at runtime rather than written as a literal. Elixir's type checker
    # can see that a literal `:__not_a_control__` matches no clause and warns
    # about the call it is the whole point of this assertion to make.
    absent = String.to_atom("__not_a_control__")

    assert_raise FunctionClauseError, fn -> Screens.Plans.handle_tap(absent, socket) end
  end

  # ── walking the graph ──────────────────────────────────────────────────────

  # The module a tap asked to push, or nil if it asked for anything else.
  defp push_target(module, socket, tag) do
    case module.handle_info({:tap, tag}, socket) do
      {:noreply, %Mob.Socket{} = updated} ->
        case Map.get(updated.__mob__, :nav_action) do
          {:push, dest, _params} -> dest
          {:reset, dest, _params} -> dest
          _ -> nil
        end

      _ ->
        nil
    end
  end

  # `%{screen => [screen]}` for every screen except the gallery: dispatch each
  # tag the screen drew and keep the ones that navigate somewhere.
  # Rolled back, because a few of the tags this dispatches are commits — see
  # `Kati.ScreenSweep.rolled_back/1` for the defect that made it necessary.
  defp push_graph(locale) do
    ScreenSweep.rolled_back(fn ->
      ScreenSweep.with_locale(locale, fn ->
        for {module, {socket, tags}} <- ScreenSweep.drawn_taps(locale),
            module != Screens.Gallery,
            into: %{} do
          targets =
            for tag <- tags,
                {:ok, dest} <- [ScreenSweep.safely(fn -> push_target(module, socket, tag) end)],
                is_atom(dest),
                dest != nil,
                uniq: true,
                do: dest

          {module, targets}
        end
      end)
    end)
  end

  defp reachable(graph, from) do
    walk(graph, from, MapSet.new())
  end

  defp walk(_graph, [], seen), do: seen

  defp walk(graph, [module | rest], seen) do
    if MapSet.member?(seen, module) do
      walk(graph, rest, seen)
    else
      walk(graph, Map.get(graph, module, []) ++ rest, MapSet.put(seen, module))
    end
  end

  # A route names either one tag or a FAMILY of them.
  #
  # `Kati.Screens.MealsToday` draws a tag per card — `meal_Breakfast_08:00` —
  # because every card sharing `:open_meal` gave every card the same
  # `accessibility_id`, and `onNodeWithTag` throws on the second match rather
  # than picking one. The route is still one route; what changed is that the
  # door has a name per card rather than one name for all of them.
  #
  # Resolving to the FIRST match rather than asserting on a literal keeps this
  # test pointed at the route instead of at the sample data: renaming a meal in
  # `Kati.Meals.Sample` must not turn a routing test red.
  defp resolve_tag({:prefix, prefix}, drawn) do
    Enum.find(drawn, fn tag ->
      is_atom(tag) and String.starts_with?(Atom.to_string(tag), prefix)
    end)
  end

  defp resolve_tag(tag, drawn), do: if(tag in drawn, do: tag)
end
