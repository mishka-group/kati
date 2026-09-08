Code.require_file("../support/screen_sweep.exs", __DIR__)

defmodule Kati.DiscoverFiltersTest do
  @moduledoc """
  Board 169's sheet, and the request it becomes.

  Three things this file is here to hold, and only the first is ordinary.

  **What the sheet draws.** `Kati.ScreenDesignLiteralTest` cannot compare this
  page against board 169, because six of the board's eleven controls cannot be
  answered by any TMDB field — so the page draws less than the board and is on
  `@undesigned` with the reason. This is what covers it instead.

  **That every control moves the choice.** Nine of them, pressed one at a time
  against a fresh socket. `Kati.ScreenTapSweepTest` carries `:sort_popular` and
  `:reset` on `@inert_taps` because the sheet OPENS on the resting choice and
  those two set what is already set — so those two are pressed here from a
  moved state, where they are anything but inert.

  **That no plausible number reaches the screen.** The count in the footer is
  TMDB's `total_results` for the choice that produced it, and the whole reason
  it is passed in as a param rather than computed is that it must vanish the
  moment a chip moves. That is asserted directly rather than described.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Discover.Filters
  alias Kati.ScreenSweep
  alias Kati.Screens.DiscoverFilters

  setup do
    Filters.clear()
    on_exit(fn -> Filters.clear() end)
    :ok
  end

  describe "the request board 169 becomes" do
    test "every param TMDB is sent is one TMDB has" do
      # The whole sheet, every combination, checked against the set of
      # parameters `/discover/movie` and `/discover/tv` actually document. A
      # parameter TMDB does not have is not an error it returns — it is
      # silently ignored, so a filter that does nothing looks exactly like a
      # filter that works.
      known =
        MapSet.new([
          :include_adult,
          :page,
          :sort_by,
          :"primary_release_date.lte",
          :"first_air_date.lte",
          :"vote_average.gte",
          :"vote_count.gte"
        ])

      for sort <- Filters.sorts(),
          rating <- [nil | Filters.ratings()],
          kind <- [nil | Filters.kinds()] do
        choice = %{kind: kind, sort: sort, rating: rating}
        endpoint = Filters.endpoint(choice)

        for {key, value} <- Filters.params(choice, endpoint, ~D[2026-09-08]) do
          assert MapSet.member?(known, key), "#{key} is not a TMDB /discover parameter"
          assert is_binary(value), "#{key} must be sent as a string, got #{inspect(value)}"
        end
      end
    end

    test "the date ceiling matches the endpoint, both ways round" do
      # `primary_release_date` is the film field and `first_air_date` the
      # series one. Sending the wrong one is the silent-ignore case above: a
      # series browse would quietly include shows announced and not aired.
      film = Filters.params(%{kind: nil, sort: :newest, rating: nil}, :movie, ~D[2026-09-08])
      series = Filters.params(%{kind: :tv, sort: :newest, rating: nil}, :tv, ~D[2026-09-08])

      assert film[:"primary_release_date.lte"] == "2026-09-08"
      refute Keyword.has_key?(film, :"first_air_date.lte")
      assert series[:"first_air_date.lte"] == "2026-09-08"
      refute Keyword.has_key?(series, :"primary_release_date.lte")

      assert film[:sort_by] == "primary_release_date.desc"
      assert series[:sort_by] == "first_air_date.desc"
    end

    test "a rating floor and a rating sort both bring the vote floor with them" do
      # `vote_average` without `vote_count` is a list of titles with one
      # ten-out-of-ten vote — which is a top-rated list nobody would recognise,
      # and a `8.0 and up` filter that is mostly films nobody has seen.
      sorted = Filters.params(%{kind: nil, sort: :top_rated, rating: nil}, :movie, ~D[2026-09-08])
      filtered = Filters.params(%{kind: nil, sort: :popular, rating: :r8}, :movie, ~D[2026-09-08])
      neither = Filters.params(Filters.resting(), :movie, ~D[2026-09-08])

      assert sorted[:"vote_count.gte"] == "200"
      assert filtered[:"vote_count.gte"] == "200"
      assert filtered[:"vote_average.gte"] == "8"
      refute Keyword.has_key?(neither, :"vote_count.gte")
    end

    test "and adult titles are excluded on every request, because Kati has no age gate" do
      for sort <- Filters.sorts() do
        params = Filters.params(%{kind: nil, sort: sort, rating: nil}, :movie, ~D[2026-09-08])
        assert params[:include_adult] == "false"
      end
    end
  end

  describe "the nine controls" do
    test "each one moves the choice, and stores it" do
      # Nine presses, each from the state that makes it a change. The sheet has
      # no Apply, so *stores it* is half the assertion: what is on screen and
      # what screen 11 re-reads on resume must not be able to differ.
      cases = [
        {:sort_newest, Filters.resting(), %{kind: nil, sort: :newest, rating: nil}},
        {:sort_top_rated, Filters.resting(), %{kind: nil, sort: :top_rated, rating: nil}},
        {:sort_popular, %{kind: nil, sort: :newest, rating: nil}, Filters.resting()},
        {:rate_r6, Filters.resting(), %{kind: nil, sort: :popular, rating: :r6}},
        {:rate_r7, Filters.resting(), %{kind: nil, sort: :popular, rating: :r7}},
        {:rate_r8, Filters.resting(), %{kind: nil, sort: :popular, rating: :r8}},
        {:kind_movie, Filters.resting(), %{kind: :movie, sort: :popular, rating: nil}},
        {:kind_tv, Filters.resting(), %{kind: :tv, sort: :popular, rating: nil}},
        {:reset, %{kind: :tv, sort: :newest, rating: :r8}, Filters.resting()}
      ]

      for {tag, from, expected} <- cases do
        Filters.put(from)
        view = mount_screen(DiscoverFilters)

        assert view.socket.assigns.choice == from,
               "#{tag}: the sheet did not open on the stored choice"

        {:noreply, socket} = DiscoverFilters.handle_info({:tap, tag}, view.socket)

        assert socket.assigns.choice == expected, "#{tag} did not move the choice"
        assert Filters.current() == expected, "#{tag} moved the screen and not the store"
      end
    end

    test "a chip already lit turns itself off, which is how a filter is removed" do
      # There is no second control for *no kind* and *no rating floor*, and
      # board 169 draws none. Pressing the lit chip is the way back.
      Filters.put(%{kind: :tv, sort: :popular, rating: :r8})
      view = mount_screen(DiscoverFilters)

      {:noreply, socket} = DiscoverFilters.handle_info({:tap, :kind_tv}, view.socket)
      assert socket.assigns.choice.kind == nil

      {:noreply, socket} = DiscoverFilters.handle_info({:tap, :rate_r8}, socket)
      assert socket.assigns.choice.rating == nil
    end

    test "but a sort cannot be turned off, because something has to order the list" do
      Filters.put(%{kind: nil, sort: :newest, rating: nil})
      view = mount_screen(DiscoverFilters)

      {:noreply, socket} = DiscoverFilters.handle_info({:tap, :sort_newest}, view.socket)
      assert socket.assigns.choice.sort == :newest
    end

    test "a tag the sheet never drew leaves the choice alone" do
      # A tap handler on a pushed screen that raises is a dead process and a
      # bounce to Home, so `key/1` answers `nil` rather than minting an atom.
      view = mount_screen(DiscoverFilters)

      {:noreply, socket} = DiscoverFilters.handle_info({:tap, :rate_r99}, view.socket)
      assert socket.assigns.choice == Filters.resting()

      assert DiscoverFilters.key("nothing-has-ever-been-called-this") == nil
    end
  end

  describe "the footer's count" do
    test "is drawn for the choice that produced it and dropped the moment one moves" do
      view = mount_screen(DiscoverFilters, %{total: 4213})

      assert Enum.any?(texts(DiscoverFilters.body(view.socket.assigns)), &(&1 == "4,213 titles"))

      {:noreply, moved} = DiscoverFilters.handle_info({:tap, :kind_tv}, view.socket)

      refute Enum.any?(texts(DiscoverFilters.body(moved.assigns)), &String.contains?(&1, "4,213")),
             "the count survived a chip moving, so it now describes a query nobody ran"
    end

    test "and there is none at all before screen 11 has ever answered" do
      view = mount_screen(DiscoverFilters)
      assert DiscoverFilters.count_line(view.socket.assigns.choice, view.socket.assigns) == nil
    end
  end

  describe "what the sheet draws" do
    test "the buildable half of board 169, and nothing that needs a recommender" do
      drawn = drawn_text()

      for present <- [
            "SORT",
            "Most popular",
            "Newest",
            "Highest rated",
            "RANGES",
            "6.0 and up",
            "7.0 and up",
            "8.0 and up",
            "FILTERS",
            "Film",
            "Series",
            "Reset"
          ] do
        assert Enum.any?(drawn, &String.contains?(&1, present)),
               "the sheet does not draw #{inspect(present)}"
      end

      # And the six the board draws that no TMDB field answers. Each is its own
      # assertion rather than one loop, so a failure names the control that came
      # back.
      refute_drawn(drawn, "Best match", "there is no recommender, so nothing can be a match")
      refute_drawn(drawn, "90% and up", "a crowd average out of ten is not a percentage fit")
      refute_drawn(drawn, "80% and up", "same")
      refute_drawn(drawn, "Leaving soonest", "TMDB has no leaving date anywhere")
      refute_drawn(drawn, "Unscored", "there is no parameter for the absence of a rating")
      refute_drawn(drawn, "Lumen+", "with_watch_providers needs ids Kati.Media.Tmdb throws away")
      refute_drawn(drawn, "Orbit", "same")
      refute_drawn(drawn, "Only with news", "there is no people table and no follow list")
      refute_drawn(drawn, "showing 4 of 8", "board 169 says that number is the sample's")
    end

    test "and no chip carries a count, because a per-chip count is a request per chip" do
      # Every string the sheet draws, with the ones that are allowed to hold a
      # digit removed. Anything left carrying one is a figure nobody computed.
      allowed = [
        "6.0 and up",
        "7.0 and up",
        "8.0 and up",
        "200+ votes, so one perfect score cannot win",
        DiscoverFilters.rating_note()
      ]

      stray =
        drawn_text()
        |> Enum.reject(&(&1 in allowed))
        |> Enum.filter(&String.match?(&1, ~r/[0-9]/))

      assert stray == [],
             "these carry a number the sheet cannot source: #{inspect(stray)}"
    end

    test "the rating group says whose number it is, in the units it is in" do
      note = DiscoverFilters.rating_note()

      assert note =~ "out of ten"
      assert note =~ "TMDB"
      refute note =~ "%"
    end
  end

  describe "screen 11 under a filter" do
    test "browses TMDB instead of asking what is like your last title" do
      # The point of the sheet on a device that has tracked nothing: screen 11
      # had exactly one honest thing to draw for that reader, and it was the
      # drawing.
      choice = %{kind: :tv, sort: :newest, rating: :r7}
      feed = Kati.Screens.Discover.feed(choice)

      assert feed.picks == []
      assert feed.asked?
      assert feed.seed_id == nil
      assert feed.because == "Newest series, 7.0 and up"
    end

    test "and the rail's heading is the question asked, never a premise nobody has" do
      # `Because you watched X` over a browse would be a claim about a title
      # that had nothing to do with the request.
      for choice <- [
            %{kind: nil, sort: :popular, rating: nil},
            %{kind: :movie, sort: :top_rated, rating: :r8},
            %{kind: :tv, sort: :newest, rating: nil}
          ] do
        refute Kati.Screens.Discover.asked_line(choice) =~ "Because"
      end
    end

    test "the total the footer gets is TMDB's own, never a count of the page" do
      # One page is twenty rows. A `length(picks)` here would print `20 titles`
      # for a corpus of four thousand.
      answer = {:ok, %{picks: List.duplicate(%{title: "x"}, 20), total: 4213}}

      assert Kati.Screens.Discover.total_of(answer) == 4213
      assert Kati.Screens.Discover.total_of({:error, :rate_limited}) == nil
      assert Kati.Screens.Discover.total_of({:ok, %{picks: [], total: 0}}) == nil
    end

    test "an answer for a choice the reader has moved off is dropped" do
      # The same rule the seed comparison follows one clause up: a rail drawn
      # under the wrong filter is the same defect as one drawn under the wrong
      # premise.
      Filters.put(%{kind: :tv, sort: :newest, rating: nil})
      view = mount_screen(Kati.Screens.Discover)

      stale = %{kind: :movie, sort: :popular, rating: nil}
      answer = {:ok, %{picks: [%{title: "Vellum"}], total: 99}}

      {:noreply, socket} =
        Kati.Screens.Discover.handle_info({:discover, stale, answer}, view.socket)

      assert socket.assigns.feed.picks == []
      assert socket.assigns.total == nil
    end

    test "and one for the live choice fills the rail and the count together" do
      Filters.put(%{kind: :tv, sort: :newest, rating: nil})
      view = mount_screen(Kati.Screens.Discover)
      live = view.socket.assigns.filters

      answer = {:ok, %{picks: [%{title: "Vellum"}], total: 4213}}

      {:noreply, socket} =
        Kati.Screens.Discover.handle_info({:discover, live, answer}, view.socket)

      assert length(socket.assigns.feed.picks) == 1
      assert socket.assigns.total == 4213
      refute socket.assigns.feed.asked?
    end

    test "coming back from the sheet re-reads the choice rather than being told it" do
      # The sheet writes through on every tap and has no Apply, so the resume
      # message carries no payload and must not need to.
      view = mount_screen(Kati.Screens.Discover)
      assert view.socket.assigns.filters == Filters.resting()

      Filters.put(%{kind: :tv, sort: :top_rated, rating: :r8})

      {:noreply, socket} =
        Kati.Screens.Discover.handle_kati(Kati.Screens.Resume.topic(), nil, view.socket)

      assert socket.assigns.filters == %{kind: :tv, sort: :top_rated, rating: :r8}
      assert socket.assigns.feed.because == "Highest rated series, 8.0 and up"
      assert socket.assigns.total == nil
    end

    test "the sort disc is lit only while something is narrowing the feed" do
      resting = inspect(Kati.Screens.Discover.filter_disc(Filters.resting()), limit: :infinity)
      narrowed = inspect(Kati.Screens.Discover.filter_disc(%{kind: :tv, sort: :popular, rating: nil}), limit: :infinity)

      refute resting == narrowed

      # And over a drawing there is no live choice, so there is no disc.
      assert Kati.Screens.Discover.filter_disc(nil) == %{type: :spacer, children: [], props: %{size: 0}}
    end
  end

  describe "both locales" do
    test "the sheet renders in Persian without a mirror module" do
      # mishka-group/kati#103's rule: a Persian page is the English page with
      # `Kati.Locale.direction_prop/0` and translated strings, not a second
      # module. This one is new, so it must never acquire one.
      for locale <- [:en, :fa] do
        ScreenSweep.with_locale(locale, fn ->
          assert {:ok, _socket, tree} = ScreenSweep.render(DiscoverFilters)
          assert is_map(tree)
        end)
      end
    end
  end

  # Every string the sheet actually puts on screen. `inspect/2` cannot be used
  # for this: it escapes every non-ASCII code point, so the em dash in
  # "Ranges — buckets, not sliders" never matches a literal written normally.
  defp drawn_text, do: texts(DiscoverFilters.body(mount_screen(DiscoverFilters).socket.assigns))

  defp texts(node) when is_map(node) do
    own =
      node
      |> Map.get(:props, %{})
      |> Map.take([:text, :placeholder, :label])
      |> Map.values()
      |> Enum.filter(&is_binary/1)

    own ++ texts(Map.get(node, :children, []))
  end

  defp texts(nodes) when is_list(nodes), do: Enum.flat_map(nodes, &texts/1)
  defp texts(_other), do: []

  defp refute_drawn(drawn, literal, why) do
    refute Enum.any?(drawn, &String.contains?(&1, literal)),
           "the sheet drew #{inspect(literal)} — #{why}"
  end
end
