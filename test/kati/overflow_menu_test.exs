Code.require_file("../support/screen_sweep.exs", __DIR__)

defmodule Kati.OverflowMenuTest do
  @moduledoc """
  The overflow menu, and the seven screens that hang off it.

  ## The defect this exists for

  Five drawings put a `more_horiz` or a `density_medium` in a header and none
  of them draws what it opens. Seven finished screens sat behind that gap,
  reachable only from `Kati.Screens.Gallery`. Screen 04's ⋯ was worse than
  inert — it went straight to screen 35, which made the control look wired
  while hiding two destinations behind the one it had.

  ## What is easy to get wrong here

  A closed menu must render its trigger and nothing else. `Kati.UI.Menu` is
  built on `:anchored`, whose panel gets its own window on Android; a panel
  that exists while closed is a window the bridge positions for nothing, and
  on the stock iOS renderer it is an accordion sitting open in the page.

  And every menu needs a dismiss handler, or the only way out is to pick
  something. `on_dismiss` reaches the wire as `on_tap` — see
  `Kati.Components.Anchored` — which is why the bridge excludes `anchored`
  from its generic tap wrapper.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Components.Anchored
  alias Kati.Screens
  alias Kati.UI.Menu

  # {screen, the tag that opens it, [{item tag, destination}]}
  @menus [
    {Screens.Series, :toggle_menu,
     [
       {:show_details, Screens.SeriesMeta},
       {:episode_order, Screens.Season},
       {:open_settings, Screens.SeriesSettings}
     ]},
    {Screens.Calendar, :toggle_menu,
     [
       {:open_agenda, Screens.Agenda},
       {:open_quick_add, Screens.QuickAdd},
       {:open_meals_day, Screens.MealsDay}
     ]},
    {Screens.Film, :toggle_menu, [{:log_watch, Screens.Rating}]},
    {Screens.Library, :toggle_menu, [{:open_what_fits, Screens.WhatFits}]},
    {Screens.MealsToday, :toggle_menu, [{:open_reminders, Screens.MealReminders}]}
  ]

  describe "the panel exists only when open" do
    for {module, open_tag, _items} <- @menus do
      test "#{inspect(module)} draws one child closed and two open" do
        closed = node_of(mount_screen(unquote(module)))

        assert length(closed.children) == 1,
               "a closed menu must be the trigger alone — a panel drawn while " <>
                 "closed is a window positioned for nothing"

        opened = node_of(render_after(unquote(module), unquote(open_tag)))
        assert length(opened.children) == 2
      end
    end
  end

  describe "every menu can be dismissed" do
    for {module, open_tag, _items} <- @menus do
      test "#{inspect(module)} wires on_dismiss" do
        opened = node_of(render_after(unquote(module), unquote(open_tag)))

        assert Anchored.dismissible?(opened),
               "without a dismiss handler the only way out of this menu is to " <>
                 "pick something"

        # And the SHAPE, not just the presence. `Anchored` passes `on_dismiss`
        # through as `on_tap`, and Mob.Renderer registers a handle only for
        # `{pid, tag}` — a bare atom encodes as itself, the bridge finds no
        # handle, and the panel is undismissable with nothing logged. That is
        # what shipped the first time, and only the device showed it.
        assert {pid, tag} = opened.props[:on_tap]
        assert is_pid(pid)
        assert is_atom(tag)
      end
    end
  end

  describe "every item reaches its screen" do
    for {module, open_tag, items} <- @menus, {tag, dest} <- items do
      test "#{inspect(module)} #{tag} opens #{inspect(dest)}" do
        socket = socket_after(unquote(module), unquote(open_tag))
        {:noreply, moved} = unquote(module).handle_info({:tap, unquote(tag)}, socket)

        # The expected params are per-destination now: Calendar's two
        # calendar-day items name the day the strip is on, and everything else
        # still pushes bare. Written as a function beside the helpers rather
        # than as a literal here, so a menu item that starts carrying an
        # argument declares it in one place instead of loosening this assertion
        # for every menu in the app.
        assert moved.__mob__.nav_action ==
                 {:push, unquote(dest), expected_params(unquote(module), unquote(tag), socket)}
      end
    end

    for {module, open_tag, items} <- @menus, {tag, _dest} <- items do
      test "#{inspect(module)} closes the menu on the way to #{tag}" do
        # The socket a screen hands back is what `Mob.Screen` saves onto the nav
        # history, so a menu left open is a menu that reopens itself every time
        # the user comes back from what it opened.
        socket = socket_after(unquote(module), unquote(open_tag))
        {:noreply, moved} = unquote(module).handle_info({:tap, unquote(tag)}, socket)

        refute moved.assigns.menu?
      end
    end
  end

  describe "the component itself" do
    test "a closed menu builds no panel" do
      trigger = %{type: :box, props: %{}, children: []}
      node = Menu.overflow(trigger, false, [Menu.item("star", "x", :x)], dismiss: :close)

      assert node.type == :anchored
      assert node.children == [trigger]
    end

    test "an open menu without a dismiss tag is a compile-time mistake, not a runtime one" do
      # `Keyword.fetch!/2` rather than a default: a menu that silently cannot be
      # dismissed is the failure this whole file is about.
      trigger = %{type: :box, props: %{}, children: []}

      assert_raise KeyError, fn ->
        Menu.overflow(trigger, true, [Menu.item("star", "x", :x)], [])
      end
    end

    test "a rule is drawn as a hairline, not as an item" do
      rule = Menu.entry(Menu.rule())
      refute Enum.any?(flatten(rule), &Map.has_key?(&1.props, :on_tap))
    end
  end

  # What each item is expected to hand its destination. Screens 52 and 126 are
  # about a DAY, and the one thing the menu knows that they cannot ask for is
  # which day the strip it was opened from is on.
  defp expected_params(Screens.Calendar, tag, socket)
       when tag in [:open_meals_day, :open_money_day],
       do: %{date: socket.assigns.date}

  defp expected_params(_module, _tag, _socket), do: %{}

  defp render_after(module, tag), do: module.render(socket_after(module, tag).assigns)

  defp socket_after(module, tag) do
    {:ok, socket} = mount(module)
    {:noreply, moved} = module.handle_info({:tap, tag}, socket)
    moved
  end

  defp mount(module) do
    Kati.Theme.activate()
    module.mount(%{}, %{}, %Mob.Socket{})
  end

  # The one `:anchored` node in the tree. Asserted to be unique rather than
  # taken with `hd/1`: a second one would mean this file has been silently
  # reading the wrong menu.
  defp node_of(tree) do
    case Enum.filter(flatten(tree), &(&1.type == :anchored)) do
      [node] -> node
      other -> flunk("expected exactly one :anchored node, found #{length(other)}")
    end
  end
end
