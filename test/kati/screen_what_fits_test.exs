defmodule Kati.ScreenWhatFitsTest do
  @moduledoc """
  Screen 13, whose caption promised a filter it did not have.

  *Set the window you actually have and the library filters itself* — and a
  grep for `on_tap` across 424 lines returned nothing. Five window buttons,
  four mood chips, a defer pill and an overflow disc, all pictures, over a
  fixture that could not have been filtered anyway. MOVIES-AND-TV.md #88.

  Three of the four things the screen's own moduledoc listed as blocked
  stopped being blocked when `Kati.Media.CachedEpisode` was built. What it
  asserts here is the shape that follows:

    * **The list is the window.** Unwatched aired episodes that fit, longest
      first, because the point of a window is to fill it.
    * **The over-budget row is the nearest film that does NOT fit**, and there
      is no row at all when everything the reader has fits. *Nothing else fits*
      is a sentence about a particular film.
    * **The mood chips are dropped**, not drawn dead. `Kati.Media.Watch.moods`
      is a real column that none of its five writers sets, so it is `[]` on
      every device and a chip over it narrows nothing; the board keeps all
      four.
    * **Everything is the board's when nothing is stored**, which is what the
      gallery and every sweep render.
  """

  use Mob.ScreenCase, async: false

  doctest Kati.Screens.WhatFits, only: [window_label: 1, hours: 1, row_tap: 2]

  alias Kati.Media.CachedEpisode
  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Screens.WhatFits

  require Ash.Query

  @prefix "what-fits-"
  @day 24 * 60 * 60

  # `Kati.Services`'s own `@rules_key`. Not exported, and deliberately not made
  # so for a test: the key is an implementation detail of where a preference is
  # kept, and naming it here costs one line if it ever moves.
  @rules_key :kati_availability_rules

  setup do
    on_exit(&wipe!/0)
    wipe!()
    :ok
  end

  describe "with nothing stored" do
    test "the page is its own empty window, not board 13 whole" do
      assert WhatFits.tonight() == WhatFits.empty_tonight(),
             "a reader with nothing on their shelf was handed four films to pick between"

      refute WhatFits.tonight() == WhatFits.drawn_tonight()
    end

    test "and its five buttons are pictures on the card screen 93 borrows" do
      card = inspect(WhatFits.window(WhatFits.drawn_tonight()), limit: :infinity)

      refute card =~ "window_45m"

      assert inspect(WhatFits.window(WhatFits.drawn_tonight(), true), limit: :infinity) =~
               "window_45m"
    end

    test "and the board keeps its four moods" do
      assert length(WhatFits.drawn_tonight().moods) == 4
      assert inspect(WhatFits.mood_row(WhatFits.drawn_tonight().moods)) =~ "Light"
      assert WhatFits.mood_row([]) == %{type: :spacer, children: [], props: %{size: 0}}
    end
  end

  describe "a shelf with something on it" do
    setup :seed_shelf

    test "lists the unwatched aired episodes that fit, longest first" do
      t = WhatFits.tonight(45)

      assert Enum.map(t.fits, & &1.run) == ["44m", "43m", "41m"]
      assert t.fits_label == "3 episodes fit"
      assert t.window == "45 min"
    end

    test "and a shorter window drops what no longer fits" do
      t = WhatFits.tonight(30)

      assert Enum.map(t.fits, & &1.run) == ["22m"]
      assert t.fits_label == "1 episode fits"
    end

    test "and never an episode that has not gone out" do
      refute Enum.any?(WhatFits.tonight(600).fits, &(&1.title =~ "Unaired"))
    end

    test "and never one already ticked" do
      refute Enum.any?(WhatFits.tonight(600).fits, &(&1.run == "40m"))
    end

    test "names the episode's place in the show" do
      assert %{meta: "S2 · E4"} = Enum.find(WhatFits.tonight(45).fits, &(&1.run == "44m"))
    end

    test "the over-budget row is the nearest film that does not fit" do
      over = WhatFits.tonight(45).over

      assert over.title == "Quiet Harbour"
      assert over.meta == "1H 46M · 61 MIN OVER"
      assert WhatFits.tonight(45).over_label == "Nothing else fits — nearest film is 1h 46m"
    end

    test "and there is no row at all once everything fits" do
      t = WhatFits.tonight(600)

      assert t.over == nil
      assert t.over_label == nil
      assert WhatFits.over(t) == %{type: :spacer, children: [], props: %{size: 0}}
    end

    test "and it carries no Tomorrow pill, because nothing records a deferral" do
      assert WhatFits.tonight(45).over.action == nil
      assert WhatFits.defer_pill(nil) == %{type: :spacer, children: [], props: %{size: 0}}
    end

    test "the mood chips are dropped, and the row with them" do
      assert WhatFits.tonight(45).moods == []
      refute inspect(WhatFits.window(WhatFits.tonight(45), true), limit: :infinity) =~ "Light"
    end

    test "and the overflow disc goes with them, having nothing left to hold" do
      # The moods were the one thing an overflow on this page could have held,
      # and they have no VALUES either — `Kati.Media.Watch.moods` exists and
      # nothing writes it — so a disc here would be a second promise of the
      # same missing axis. The row stays: it reserves the back pill's
      # space, which `Kati.Screens.Pushed` floats.
      glyph = Kati.Icons.glyph!("more_horiz")

      refute inspect(WhatFits.more_row(false), limit: :infinity) =~ glyph
      assert inspect(WhatFits.more_row(true), limit: :infinity) =~ glyph
    end
  end

  describe "board 310 — Hide titles I can’t watch reaches this page too" do
    setup :seed_shelf

    test "off, which is every device's default, and the whole shelf is here" do
      assert Enum.map(WhatFits.tonight(45).fits, & &1.run) == ["44m", "43m", "41m"]
      assert WhatFits.tonight(45).over.title == "Quiet Harbour"
    end

    test "on, and a title known to be unavailable leaves both halves of the page" do
      offer!("hollow", %{"rent" => ["Apple TV"]})
      offer!("harbour", %{"rent" => ["Apple TV"]})
      hide!()

      t = WhatFits.tonight(45)

      assert t.fits == [], "the series is rent-only and rentals are off, so no episode fits"

      # Not `nil`. `Quiet Harbour` at 1h 46m was the nearest film over the
      # window and is hidden; `The Long One` at 3h has no provider block at
      # all, which is `:unknown` and stays. So the row moves rather than going
      # — which is the whole of `hide?/3`'s third answer, seen from a screen.
      assert t.over.title == "The Long One"
    end

    test "on, and a title on a service the reader pays for stays" do
      a_service!("Aria")
      offer!("hollow", %{"flatrate" => [@prefix <> "Aria"]})
      hide!()

      assert Enum.map(WhatFits.tonight(45).fits, & &1.run) == ["44m", "43m", "41m"]
    end

    test "on, and a title nobody has looked up stays — unknown is not unavailable" do
      hide!()

      assert Enum.map(WhatFits.tonight(45).fits, & &1.run) == ["44m", "43m", "41m"],
             "hiding a title with no provider data would empty the page for a reason " <>
               "the reader has no way to discover"
    end

    test "on, with rentals counted, and the rent-only title comes back" do
      offer!("hollow", %{"rent" => ["Apple TV"]})
      rules!(%{rentals: true, purchases: false, hide_unavailable: true})

      assert Enum.map(WhatFits.tonight(45).fits, & &1.run) == ["44m", "43m", "41m"]
    end
  end

  describe "pressing a window" do
    setup :seed_shelf

    test "re-reads the list, the count and the over-budget row together" do
      socket = mount_screen(WhatFits).socket

      {:noreply, shorter} = WhatFits.handle_tap(:window_30m, socket)

      assert shorter.assigns.window == 30
      assert shorter.assigns.tonight.window == "30 min"
      assert Enum.map(shorter.assigns.tonight.fits, & &1.run) == ["22m"]
      assert shorter.assigns.tonight.over.meta =~ "76 MIN OVER"
    end

    test "and the one already chosen re-reads the same page rather than going dead" do
      socket = mount_screen(WhatFits).socket

      {:noreply, again} = WhatFits.handle_tap(:window_45m, socket)

      assert again.assigns.tonight.fits == socket.assigns.tonight.fits
    end

    test "a label no window answers to leaves the screen alone" do
      socket = mount_screen(WhatFits).socket

      {:noreply, after_tap} = WhatFits.handle_tap(:window_90m, socket)

      assert after_tap.assigns.window == socket.assigns.window
    end
  end

  describe "pressing a row" do
    setup :seed_shelf

    test "opens the show it names" do
      socket = mount_screen(WhatFits).socket
      row = hd(socket.assigns.tonight.fits)

      {:noreply, pushed} = WhatFits.handle_tap(:open_0, socket)

      assert {:push, Kati.Screens.Series, %{tracked_id: id, back: "What fits?"}} =
               Map.get(pushed.__mob__, :nav_action)

      assert id == row.tracked_id
    end

    test "and the over-budget row opens its film" do
      socket = mount_screen(WhatFits).socket

      {:noreply, pushed} = WhatFits.handle_tap(:open_over, socket)

      assert {:push, Kati.Screens.Film, %{back: "What fits?"}} =
               Map.get(pushed.__mob__, :nav_action)
    end

    test "and a row on the board opens nothing, having no title behind it" do
      assert Enum.all?(WhatFits.drawn_tonight().fits, &(WhatFits.row_tap(&1, 0) == nil))
      assert WhatFits.row_tap(WhatFits.drawn_tonight().over, :over) == nil

      # And a tag naming a row this page does not have changes nothing.
      socket = mount_screen(WhatFits).socket
      {:noreply, after_tap} = WhatFits.handle_tap(:open_9, socket)
      assert Map.get(after_tap.__mob__, :nav_action) == nil
    end
  end

  defp seed_shelf(_context) do
    series = track!("hollow", "The Long Hollow", :tv)

    episode!(series, %{n: 2, runtime: 41, days: -9})
    episode!(series, %{n: 3, runtime: 43, days: -6})
    episode!(series, %{n: 4, runtime: 44, days: -3})
    episode!(series, %{n: 5, runtime: 22, days: -2})
    episode!(series, %{n: 6, runtime: 90, days: -1, title: "Unaired"})
    ticked = episode!(series, %{n: 7, runtime: 40, days: -12})
    episode!(series, %{n: 8, runtime: 55, days: 5, title: "Unaired"})

    tick!(series, ticked)

    film!("harbour", "Quiet Harbour", 106)
    film!("longer", "The Long One", 180)

    :ok
  end

  defp track!(suffix, title, kind, runtime \\ nil) do
    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: @prefix <> suffix,
      kind: kind,
      title: title,
      runtime_minutes: runtime,
      fetched_at: Kati.Time.now()
    })

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: @prefix <> suffix,
      kind: kind,
      status: :watching
    })
  end

  defp film!(suffix, title, runtime), do: track!(suffix, title, :movie, runtime)

  defp episode!(tracked, attrs) do
    source_id = @prefix <> "ep-#{System.unique_integer([:positive])}"

    Ash.create!(CachedEpisode, %{
      source: :tmdb,
      source_id: source_id,
      title_source_id: tracked.source_id,
      season_number: 2,
      episode_number: attrs.n,
      title: attrs[:title] || "Episode #{attrs.n}",
      runtime_minutes: attrs.runtime,
      air_at: DateTime.add(Kati.Time.now(), attrs.days * @day, :second),
      date_confidence: :exact,
      fetched_at: Kati.Time.now()
    })

    source_id
  end

  defp tick!(tracked, episode_source_id) do
    Ash.create!(Watch, %{
      tracked_title_id: tracked.id,
      episode_source_id: episode_source_id,
      watched_at: DateTime.truncate(Kati.Time.now(), :second),
      watched_on: Kati.Time.today()
    })
  end

  # The reader's answer to screen 92's three switches. `Kati.Services` has no
  # setter — the screen flips one rule at a time through `toggle_rule/1` — and
  # a test that tapped its way to a state would be testing screen 92 rather
  # than this page, so the map goes in under the key `Kati.Services.rules/0`
  # reads. `@rules_key` is that key, named once here.
  defp rules!(rules), do: Mob.State.put(@rules_key, rules)

  defp hide!, do: rules!(%{rentals: false, purchases: false, hide_unavailable: true})

  defp offer!(suffix, offers) do
    Kati.Media.CachedTitle
    |> Ash.Query.filter(source_id == ^(@prefix <> suffix))
    |> Ash.read!()
    |> Elixir.List.first()
    |> Ash.update!(%{providers: %{Kati.Services.region() => offers}})
  end

  defp a_service!(name) do
    Ash.create!(Kati.Services.Service, %{name: @prefix <> name, tier: :subscribed})
  end

  defp wipe! do
    Kati.Repo.query!(
      "DELETE FROM media_watches WHERE tracked_title_id IN " <>
        "(SELECT id FROM tracked_titles WHERE source_id LIKE ?1)",
      [@prefix <> "%"]
    )

    Kati.Repo.query!("DELETE FROM cached_episodes WHERE source_id LIKE ?1", [@prefix <> "%"])
    Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
    Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
    Kati.Repo.query!("DELETE FROM services WHERE name LIKE ?1", [@prefix <> "%"])
  end
end
