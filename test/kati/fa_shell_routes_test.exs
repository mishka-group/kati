defmodule Kati.FaShellRoutesTest do
  @moduledoc """
  The Persian shell must stay Persian.

  Screen 61 (آمار) shipped, but `Kati.Screens.Fa.roots/0` kept pointing its
  stats tab at `Kati.Screens.Stats` — the English root that stood in while 61
  was unbuilt. In the other direction `Kati.Screens.StatsFa` answered its own
  dock taps against `Kati.Shell.screen_for/1`, which names the English four.

  Either way a single tap on the dock changed the app's language and its
  direction, with no way back except Settings. Neither is visible in a
  screenshot of a resting screen, which is why it survived a full 62-screen
  capture: the bar draws identically, it just means four other screens.
  """
  use ExUnit.Case, async: true

  # The mirrors still standing. `Kati.Screens.StatsFa` left this list on
  # mishka-group/kati#103's stats fold: board 61 is `Kati.Screens.Stats` read
  # under `:fa`, so the آمار tab names an English MODULE and a Persian PAGE, and
  # the two are no longer the same question. The list shrinks by one per fold
  # and the last fold empties it.
  @persian_roots [Kati.Screens.HomeFa]

  # A folded root: still on the Persian dock, and Persian because
  # `Kati.Locale` says so rather than because the module's name ends in `Fa`.
  @folded_roots [Kati.Screens.Stats, Kati.Screens.Calendar, Kati.Screens.Library]

  describe "the Persian dock names Persian screens" do
    test "every root in Kati.Screens.Fa.roots/0 is a Persian screen" do
      strays =
        Kati.Screens.Fa.roots()
        |> Enum.reject(&(&1.screen in (@persian_roots ++ @folded_roots)))
        |> Enum.map(&"#{&1.id} -> #{inspect(&1.screen)}")

      assert strays == [],
             "Persian dock tabs pointing at English screens: " <> Enum.join(strays, ", ")
    end

    test "the four tabs are distinct screens" do
      screens = Enum.map(Kati.Screens.Fa.roots(), & &1.screen)
      assert length(Enum.uniq(screens)) == 4
    end

    test "the stats tab is board 61, which is screen 07 read in Persian" do
      stats = Enum.find(Kati.Screens.Fa.roots(), &(&1.id == :stats))
      assert stats.screen == Kati.Screens.Stats
    end
  end

  describe "a dock tap from a Persian root stays Persian" do
    setup do
      # reset_to/2 only records the target; no Mob runtime is needed for that.
      {:ok, socket: %Mob.Socket{assigns: %{}}}
    end

    for {tag, expected} <- [
          {:root_home, Kati.Screens.HomeFa},
          {:root_calendar, Kati.Screens.Calendar},
          {:root_library, Kati.Screens.Library}
        ] do
      test "#{tag} from آمار lands on #{inspect(expected)}", %{socket: socket} do
        # Screen 07 under `:fa` — `Kati.Screens.Root`'s shared `root_*` clause
        # asking `Kati.Shell.screen_for/1`, which reads the Persian table first
        # while that table still names anything of its own. Before the fold this
        # was `Kati.Screens.StatsFa.handle_info/2` answering the same question
        # in a module of its own.
        moved =
          Kati.Locale.as(:fa, fn ->
            {:noreply, moved} = Kati.Screens.Stats.handle_info({:tap, unquote(tag)}, socket)
            moved
          end)

        assert target_of(moved) == unquote(expected)
      end
    end

    test "and in English the same tap lands on the English root", %{socket: socket} do
      # The other half, and the reason `screen_for/1` asks the locale rather
      # than the module: one screen, two docks.
      moved =
        Kati.Locale.as(:en, fn ->
          {:noreply, moved} = Kati.Screens.Stats.handle_info({:tap, :root_home}, socket)
          moved
        end)

      assert target_of(moved) == Kati.Screens.Home
    end

    test "root_stats from آمار is inert", %{socket: socket} do
      moved =
        Kati.Locale.as(:fa, fn ->
          {:noreply, moved} = Kati.Screens.Stats.handle_info({:tap, :root_stats}, socket)
          moved
        end)

      assert target_of(moved) == nil
    end
  end

  describe "the way out of Persian" do
    test "board 62's Language row opens the language screen" do
      # The only one. Board 62 draws no other language control and the Persian
      # dock's four tabs are all Persian, so while this was inert a reader who
      # chose فارسی on screen 53 could not get back to English by any route.
      #
      # `Kati.Screens.SettingsFa` answered this until mishka-group/kati#103
      # folded it into screen 24. Board 62 is that screen under `:fa`, so the
      # tag is screen 24's `go_language` — which is also the point: the way out
      # of Persian is the same row a reader in English uses, rather than a
      # second control on a second module that could be forgotten.
      #
      # A bare socket, not a mounted one: `mount/3` installs the theme, which
      # reads `Mob.State`'s DETS, and this file is async with no such table.
      # The push needs no assigns.
      {:noreply, moved} =
        Kati.Screens.Settings.handle_info({:tap, :go_language}, %Mob.Socket{})

      assert moved.__mob__.nav_action == {:push, Kati.Screens.Language, %{}}
    end

    test "the language row actually carries that tag" do
      # The other half: a handler nothing dispatches to is the same as no
      # handler. The row is named by its `id`, which is the field a translation
      # does not reach — the mirror's own clause keyed on `badge:` because its
      # title was Persian, and that whole problem is what an id removes.
      row = %{id: "language", icon: "translate", title: "Language", control: :chevron}
      assert {_pid, :go_language} = Kati.Screens.Settings.tap_for(row)
    end
  end

  # `Mob.Socket.reset_to/3` records `{:reset, destination, params}` in
  # `__mob__.nav_action`; the destination is the whole assertion here.
  defp target_of(%Mob.Socket{__mob__: %{nav_action: reset}}) when elem(reset, 0) == :reset,
    do: elem(reset, 1)

  defp target_of(%Mob.Socket{}), do: nil
end
