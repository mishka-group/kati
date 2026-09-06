defmodule Kati.DiscoverFeedTest do
  @moduledoc """
  Screen 11 stops making claims about a reader it has never met.

  Discover was `Kati.Screens.Discover.Sample.feed()` end to end — no
  `Kati.Media` read anywhere in the file — and six of its lines were specific
  claims about the person holding the phone: *Tuned to 128 titles* on a shelf
  of six, *Because you watched The Long Hollow* for somebody who never had,
  `94% match` / `89% match` / `81% match` on three films nothing had scored,
  three people the app has never heard of, and *Leaving Lumen+ in 7 days* for a
  service that may not be on the account. MOVIES-AND-TV.md ranks it #50 and
  calls it the app's most confident lie.

  One of its three sections can be true and now is. The other two need a person
  resource and an offers resource, neither of which exists — so on a real
  device they are empty, and their headings and their chips go with them rather
  than being filled from the fixture.

  What this file does NOT test is the network. `Kati.Media.Recommendations.ask/2`
  and `picks_for/1` are the TMDB call, and a test that made one would be
  testing TMDB. What is tested is the shape either answer lands in, and that
  every failure lands in the same one.
  """

  use Mob.ScreenCase, async: false

  doctest Kati.Media.Recommendations, only: [because: 1]
  doctest Kati.Screens.Discover, only: [pick_tag: 1, mark: 2]

  alias Kati.Media.CachedTitle
  alias Kati.Media.Recommendations
  alias Kati.Media.TrackedTitle
  alias Kati.Screens.Discover

  @prefix "discover-feed-"

  setup do
    on_exit(fn ->
      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
    end)

    :ok
  end

  describe "the seed the picks are drawn from" do
    test "is the newest title the reader touched" do
      _older = tracked!("arrival", "Arrival", :movie)
      newest = tracked!("severance", "Severance", :tv)

      assert {tracked, cached} = Recommendations.seed()
      assert cached.title == "Severance"
      assert tracked.id == newest.id
    end

    test "is nothing when the shelf is empty" do
      assert Recommendations.seed() == nil
    end

    test "skips a title whose cache row has been evicted" do
      Ash.create!(TrackedTitle, %{
        source: :tmdb,
        source_id: @prefix <> "orphan",
        kind: :tv,
        status: :watching
      })

      assert Recommendations.seed() == nil
    end
  end

  describe "the feed a real library gets" do
    setup do
      tracked!("severance", "Severance", :tv)
      %{feed: Discover.feed()}
    end

    test "names the title the picks came from", %{feed: feed} do
      assert feed.because == "Because you watched Severance"
      refute feed.because =~ "The Long Hollow"
    end

    test "claims no corpus size", %{feed: feed} do
      assert feed.subtitle == nil
    end

    test "has no people and nothing leaving", %{feed: feed} do
      assert feed.people == []
      assert feed.leaving == []
      assert feed.leaving_label == nil
    end

    test "offers only the chip it has a section for", %{feed: feed} do
      assert Enum.map(feed.chips, & &1.label) == ["For you"]
    end

    test "and the render draws none of the fixture's claims", %{feed: feed} do
      drawn = drawn(feed)

      for gone <- [
            "Tuned to 128 titles",
            "The Long Hollow",
            "94% match",
            "Ines Karvel",
            "PEOPLE YOU FOLLOW",
            "Leaving Lumen+ in 7 days",
            "Nightbirds"
          ] do
        refute drawn =~ gone, "screen 11 still draws #{inspect(gone)} on a real library"
      end

      assert drawn =~ "BECAUSE YOU WATCHED SEVERANCE"
    end
  end

  describe "while the request is out, and after it answers nothing" do
    setup do
      tracked!("severance", "Severance", :tv)
      %{feed: Discover.feed()}
    end

    test "asking and having nothing are drawn apart", %{feed: feed} do
      assert drawn(feed) =~ "Looking for something"

      answered = Discover.answered(feed, {:ok, []})
      assert drawn(answered) =~ "Nothing to suggest yet"
      refute drawn(answered) =~ "Looking for something"
    end

    test "picks that arrive replace both", %{feed: feed} do
      arrived = Discover.answered(feed, {:ok, [%{title: "Dark", seed: "/dark.jpg", match: nil}]})

      drawn = drawn(arrived)

      assert drawn =~ "Dark"
      refute drawn =~ "Nothing to suggest yet"
      refute drawn =~ "Looking for something"
    end

    test "and carry no match percentage, because nothing scored them", %{feed: feed} do
      arrived = Discover.answered(feed, {:ok, [%{title: "Dark", seed: nil, match: nil}]})

      refute drawn(arrived) =~ "match"
    end

    test "a device with no token is told where to put one", %{feed: feed} do
      drawn = drawn(Discover.answered(feed, {:error, :no_api_key}))

      assert drawn =~ "No TMDB token yet"
      assert drawn =~ Kati.Media.Tmdb.message(:no_api_key)
      refute drawn =~ "Nothing to suggest yet"
    end

    test "a device that could not reach TMDB is told to try again", %{feed: feed} do
      drawn = drawn(Discover.answered(feed, {:error, :rate_limited}))

      assert drawn =~ "Could not look just now"
      assert drawn =~ Kati.Media.Tmdb.message(:rate_limited)
      refute drawn =~ "No TMDB token yet"
      refute drawn =~ "Nothing to suggest yet"
    end

    test "and a later success clears the failure", %{feed: feed} do
      recovered =
        feed
        |> Discover.answered({:error, :rate_limited})
        |> Discover.answered({:ok, [%{title: "Dark", seed: nil, match: nil}]})

      assert recovered.picks_error == nil
      refute drawn(recovered) =~ "Could not look just now"
    end
  end

  describe "an answer about a title this page is not on" do
    setup do
      tracked!("severance", "Severance", :tv)
      {:ok, socket} = Discover.mount(%{}, %{}, Mob.Socket.new(Discover))
      %{socket: socket}
    end

    test "is taken when it names the seed", %{socket: socket} do
      picks = [%{title: "Dark", seed: nil, match: nil}]

      {:noreply, moved} =
        Discover.handle_info({:recommendations, @prefix <> "severance", {:ok, picks}}, socket)

      assert moved.assigns.feed.picks == picks
      refute moved.assigns.feed.asked?
    end

    test "and dropped when it does not", %{socket: socket} do
      {:noreply, same} =
        Discover.handle_info(
          {:recommendations, "some-other-title",
           {:ok, [%{title: "Dark", seed: nil, match: nil}]}},
          socket
        )

      assert same.assigns.feed.picks == []
      assert same.assigns.feed.asked?
    end
  end

  describe "a pick you can act on" do
    setup do
      tracked!("severance", "Severance", :tv)
      feed = Discover.feed()

      picks = [
        %{
          title: "Emergence",
          seed: "/emergence.jpg",
          match: nil,
          source_id: "82708",
          kind: :tv,
          added: false
        }
      ]

      %{feed: Discover.answered(feed, {:ok, picks})}
    end

    test "carries a tap naming its provider id", %{feed: feed} do
      assert drawn(feed) =~ "add_82708"
    end

    test "and the board's picks carry none" do
      # Which is what keeps board 11 the node it always was, and why
      # `Kati.ScreenTapSweepTest` — which runs against an empty store, and so
      # renders the board — cannot see this tap at all.
      for pick <- Discover.Sample.feed().picks do
        assert Discover.pick_tag(pick) == nil
      end
    end

    test "ticking one marks it and leaves the others", %{feed: feed} do
      marked = Discover.mark(feed.picks ++ [%{source_id: "999", added: false}], "82708")

      assert [%{source_id: "82708", added: true}, %{source_id: "999", added: false}] = marked
    end

    test "a tap naming nothing on the rail changes nothing", %{feed: feed} do
      socket =
        Discover
        |> Mob.Socket.new()
        |> Mob.Socket.assign(feed: feed, chip: "For you", scheduled: [], add_error: nil)

      assert Discover.add(socket, "not-in-the-rail").assigns.feed == feed
    end

    test "and one already added is not added twice", %{feed: feed} do
      added = %{feed | picks: Discover.mark(feed.picks, "82708")}

      socket =
        Discover
        |> Mob.Socket.new()
        |> Mob.Socket.assign(feed: added, chip: "For you", scheduled: [], add_error: nil)

      assert Discover.add(socket, "82708").assigns.feed == added
      assert Ash.read!(TrackedTitle) |> Enum.map(& &1.source_id) |> Enum.member?("82708") == false
    end

    test "a refused add is said out loud rather than swallowed", %{feed: feed} do
      # `Kati.Screens.AddTitle.track/2` fetches from TMDB first, and this suite
      # has no key — so this is the refusal path, exercised for the thing that
      # matters about it: that the screen SAYS so. Screen 06 sets the same
      # assign and draws it nowhere, which is `D-60`'s defect in English.
      socket =
        Discover
        |> Mob.Socket.new()
        |> Mob.Socket.assign(feed: feed, chip: "For you", scheduled: [], add_error: nil)

      after_tap = Discover.add(socket, "82708")

      assert is_binary(after_tap.assigns.add_error)
      assert drawn_with(after_tap.assigns) =~ after_tap.assigns.add_error
    end
  end

  describe "with nothing stored" do
    test "the board is drawn whole" do
      assert Discover.feed() == Discover.Sample.feed()
    end

    test "and every claim on it is still a claim the board makes" do
      drawn = drawn(Discover.feed())

      for kept <- ["Tuned to 128 titles", "Ines Karvel", "Nightbirds", "94% match"] do
        assert drawn =~ kept, "the board lost #{inspect(kept)}"
      end
    end
  end

  defp drawn(feed) do
    drawn_with(%{feed: feed, chip: Discover.default_chip(feed), scheduled: [], add_error: nil})
  end

  defp drawn_with(assigns) do
    inspect(Discover.content(assigns), limit: :infinity, printable_limit: :infinity)
  end

  defp tracked!(slug, title, kind) do
    source_id = @prefix <> slug

    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: source_id,
      kind: kind,
      title: title,
      fetched_at: Kati.Time.now()
    })

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: source_id,
      kind: kind,
      status: :watching
    })
  end
end
