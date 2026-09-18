defmodule Kati.NothingSetUpBandsTest do
  @moduledoc """
  Board 96's four bands, on the four screens they are drawings OF.

  MOVIES-AND-TV.md #120. Screen 96 is a reference sheet of what four screens
  look like on day one, and its own moduledoc recorded that none of the four
  could ever enter these states:

  > the predicate cannot answer `false` today: 92 falls back to
  > `Kati.Services.Sample` when the store is empty, so the four screens that
  > would ask this question need that fallback to become conditional before any
  > of them can put these bands on screen.

  #75 made it conditional. This file is the four bands, asked of the four
  screens rather than of the sheet.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Services.Service

  @prefix "bands-"

  setup do
    on_exit(fn ->
      Kati.Repo.query!("DELETE FROM services WHERE name LIKE ?1", [@prefix <> "%"])
    end)

    :ok
  end

  describe "the predicate the four bands turn on" do
    test "can answer false at last, which is the whole of what they waited for" do
      Kati.Repo.query!("DELETE FROM services", [])
      refute Kati.Screens.NothingSetUpKnockOn.set_up?()

      Ash.create!(Service, %{name: @prefix <> "Mubi", tier: :subscribed})
      assert Kati.Screens.NothingSetUpKnockOn.set_up?()
    end

    test "and a free service counts, because the reader has still set the page up" do
      Kati.Repo.query!("DELETE FROM services", [])
      Ash.create!(Service, %{name: @prefix <> "Aria", tier: :free_with_ads})

      assert Kati.Screens.NothingSetUpKnockOn.set_up?()
    end

    test "but one turned off does not" do
      Kati.Repo.query!("DELETE FROM services", [])
      Ash.create!(Service, %{name: @prefix <> "Gone", tier: :not_mine})

      refute Kati.Screens.NothingSetUpKnockOn.set_up?()
    end
  end

  describe "band 08 — Film detail, Where to watch" do
    test "replaces the section rather than leaving it blank" do
      film = %{where: []}

      unset = inspect(Kati.Screens.Film.where_section(film, false), limit: :infinity)

      # The eyebrow upper-cases its label, so the heading is asked of the
      # rendered word rather than of the one passed in.
      assert unset =~ "WHERE TO WATCH", "the heading goes with the band, not without it"
      assert unset =~ "Set up your services to see where this is streaming"
      assert unset =~ "my_services_where_to_watch"

      # And once a service exists, a film on none of them heads nothing: that
      # is a fact about the film and not one the reader can fix.
      assert Kati.Screens.Film.where_section(film, true) == []
    end
  end

  describe "band 11 — Discover, Leaving soon" do
    test "replaces the rail when nothing is subscribed" do
      Kati.Repo.query!("DELETE FROM services", [])

      unset =
        inspect(
          Kati.Screens.Discover.leaving_section(%{leaving: []}, "For you", []),
          limit: :infinity
        )

      assert unset =~ "Nothing to leave yet"
      assert unset =~ "nothing to count down from"
      assert unset =~ "my_services_leaving_soon"

      Ash.create!(Service, %{name: @prefix <> "Mubi", tier: :subscribed})

      set =
        inspect(
          Kati.Screens.Discover.leaving_section(%{leaving: []}, "For you", []),
          limit: :infinity
        )

      refute set =~ "Nothing to leave yet"
    end

    test "and stays behind the chip, like the section it replaces" do
      Kati.Repo.query!("DELETE FROM services", [])

      narrowed =
        inspect(
          Kati.Screens.Discover.leaving_section(%{leaving: []}, "Because you watched", []),
          limit: :infinity
        )

      refute narrowed =~ "Nothing to leave yet",
             "a reader who narrowed to another chip is not asking about leaving-soon"
    end
  end

  describe "band 13 — What fits tonight" do
    test "says the count is by time, above the list rather than instead of it" do
      Kati.Repo.query!("DELETE FROM services", [])
      # `tonight/1` takes MINUTES. This passed `%{}`, which raised inside
      # `real_tonight/1` and was swallowed by its `rescue` into the drawing — so
      # the band under test was board 13's, not this reader's, and the type
      # error was invisible for as long as a fixture stood behind it.
      tonight = Kati.Screens.WhatFits.tonight()

      unset = inspect(Kati.Screens.WhatFits.unfiltered(tonight), limit: :infinity)

      # `Nothing fits that window` and not `0 you can watch`: with nothing on the
      # shelf there is no count to give, and the band says the truer of the two.
      # The point this test is making is unchanged — the band sits ABOVE the
      # list with its own call to action, rather than replacing it.
      assert unset =~ "Nothing fits that window"
      assert unset =~ "size the gap but not fill it"
      assert unset =~ "my_services_what_fits"

      Ash.create!(Service, %{name: @prefix <> "Mubi", tier: :subscribed})

      refute inspect(Kati.Screens.WhatFits.unfiltered(tonight), limit: :infinity) =~
               "size the gap but not fill it"
    end
  end

  describe "band 23 — Subscriptions, an empty ledger" do
    test "keeps the page's header and replaces the ledger under it" do
      ledger = Kati.Screens.Subscriptions.drawn_ledger()

      unset =
        inspect(Kati.Screens.Subscriptions.body(ledger, true, false, false), limit: :infinity)

      assert unset =~ "Subscriptions", "the page keeps its own header — 23 still has a page"
      assert unset =~ "No subscriptions yet"
      assert unset =~ "there is nothing here to be zero"
      assert unset =~ "my_services_ledger"

      # And the three things the band's own note says it takes away with it.
      refute unset =~ "46.47"
      refute unset =~ "Every month"
      refute unset =~ "Worth a look"
    end

    test "and draws the whole ledger once there is one" do
      ledger = Kati.Screens.Subscriptions.drawn_ledger()

      set = inspect(Kati.Screens.Subscriptions.body(ledger, true, false, true), limit: :infinity)

      assert set =~ "46.47"
      refute set =~ "No subscriptions yet"
    end
  end

  describe "all four buttons" do
    test "lead to one place, which is the sheet's own line" do
      for {module, tag, assigns} <- [
            {Kati.Screens.Film, :my_services_where_to_watch, %{film: %{}, menu?: false}},
            {Kati.Screens.Discover, :my_services_leaving_soon, %{}},
            {Kati.Screens.WhatFits, :my_services_what_fits, %{}},
            {Kati.Screens.Subscriptions, :my_services_ledger, %{}}
          ] do
        socket =
          Enum.reduce(assigns, Mob.Socket.new(module), fn {k, v}, acc ->
            Mob.Socket.assign(acc, k, v)
          end)

        {:noreply, pushed} = press(module, tag, socket)

        assert {:push, Kati.Screens.MyServices, _params} = Map.get(pushed.__mob__, :nav_action),
               "#{inspect(module)}'s #{tag} does not lead to My services"
      end
    end

    test "and the sheet's OWN four taps lead there too" do
      # The block above presses Film, Discover, WhatFits and Subscriptions —
      # the four screens a real band lives on. It never presses
      # `Kati.Screens.NothingSetUpKnockOn` itself, which is the one module
      # that actually owns `handle_tap/2`'s shared clause for all four tags
      # (screen 96, reached from the gallery board index rather than from any
      # of the four). `mix mob.routes` is what caught the gap this closes: the
      # clause pushed a bare `MyServices` — no `Kati.Screens.` prefix — which
      # resolves to nothing and would have crashed the moment a developer
      # tapped any of the four buttons while walking the gallery.
      for tag <- ~w(my_services_where_to_watch my_services_leaving_soon
                    my_services_what_fits my_services_ledger)a do
        {:noreply, pushed} =
          press(
            Kati.Screens.NothingSetUpKnockOn,
            tag,
            Mob.Socket.new(Kati.Screens.NothingSetUpKnockOn)
          )

        assert {:push, Kati.Screens.MyServices, _params} = Map.get(pushed.__mob__, :nav_action),
               "Kati.Screens.NothingSetUpKnockOn's #{tag} does not lead to My services"
      end
    end
  end

  # Screens differ on which callback carries a tap; both reach the same clause.
  defp press(module, tag, socket) do
    if function_exported?(module, :handle_tap, 2) do
      module.handle_tap(tag, socket)
    else
      module.handle_info({:tap, tag}, socket)
    end
  end
end
