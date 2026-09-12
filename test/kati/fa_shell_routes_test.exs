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

  mishka-group/kati#103 removes the possibility rather than the instance. There
  is one table now — `Kati.Shell.screen_for/1` — and the four screens it names
  take their script from `Kati.Locale`, so a dock tap cannot change the app's
  language because there is nothing on the other side of it to change to.
  """
  use ExUnit.Case, async: true

  # The four roots, which are four SCREENS and no longer four modules per
  # language. mishka-group/kati#103 folded `Kati.Screens.HomeFa`, `ScheduleFa`,
  # `LibraryFa` and `StatsFa` away and deleted `Kati.Screens.Fa.roots/0` with
  # the last of them, so what this file asks about is one table read in two
  # languages.
  @roots [
    {:home, Kati.Screens.Home},
    {:calendar, Kati.Screens.Calendar},
    {:library, Kati.Screens.Library},
    {:stats, Kati.Screens.Stats}
  ]

  describe "the dock is one table in both languages" do
    test "every tab resolves to the same screen in either script" do
      # The defect this file was written against was a dock that meant four
      # OTHER screens depending on the language, and the fold's whole claim is
      # that there is one set. Asserted in both locales rather than once,
      # because `Kati.Shell.screen_for/1` read a second table until the last
      # mirror went and a stale clause there is exactly what would not show in
      # a screenshot: the bar draws identically either way.
      for {id, screen} <- @roots, locale <- [:en, :fa] do
        assert Kati.Locale.as(locale, fn -> Kati.Shell.screen_for(id) end) == screen,
               "the #{id} tab means something else under #{locale}"
      end
    end

    test "the four tabs are distinct screens" do
      assert length(Enum.uniq(Enum.map(@roots, &elem(&1, 1)))) == 4
    end

    test "no module named for a language is left on the dock" do
      # The ratchet `Kati.PersianScreensRatchetTest` keeps over every screen,
      # asked here of the four that matter most: a root is the page an install
      # opens on, so a mirror surviving here would be a whole app in a second
      # language rather than one page.
      for {_id, screen} <- @roots do
        refute screen |> Module.split() |> List.last() |> String.match?(~r/Fa($|[A-Z])/),
               "#{inspect(screen)} is a mirror, and the dock is where a mirror costs most"
      end
    end
  end

  describe "a dock tap from a Persian root stays Persian" do
    setup do
      # reset_to/2 only records the target; no Mob runtime is needed for that.
      {:ok, socket: %Mob.Socket{assigns: %{}}}
    end

    for {tag, expected} <- [
          {:root_home, Kati.Screens.Home},
          {:root_calendar, Kati.Screens.Calendar},
          {:root_library, Kati.Screens.Library}
        ] do
      test "#{tag} from آمار lands on #{inspect(expected)}", %{socket: socket} do
        # Board 61 under `:fa` — `Kati.Screens.Root`'s shared `root_*` clause
        # asking `Kati.Shell.screen_for/1`. Before the fold this was
        # `Kati.Screens.StatsFa.handle_info/2` answering the same question in a
        # module of its own, against a table of its own.
        moved =
          Kati.Locale.as(:fa, fn ->
            {:noreply, moved} = Kati.Screens.Stats.handle_info({:tap, unquote(tag)}, socket)
            moved
          end)

        assert target_of(moved) == unquote(expected)
      end
    end

    test "and in English the same tap lands on the same root", %{socket: socket} do
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
