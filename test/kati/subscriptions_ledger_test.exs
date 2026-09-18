defmodule Kati.SubscriptionsLedgerTest do
  @moduledoc """
  Screen 23 counts the reader's own money, and their own hours.

  MOVIES-AND-TV.md #66: the page quoted Lumen+, Orbit, Kino and £46.47 a month
  on every device, and its only route in is screen 92's Money row — so a
  reader who had told Kati about one service, at a price they typed, was shown
  four they had not and a total that was none of their money. Its back pill
  read *Stats*.

  The hours are the interesting half. `Kati.Media.Watch.service` — where you
  watched it — has no writer anywhere in the app, and asking somebody to name
  a service every time they tick an episode would be a worse app. So they are
  derived: a title is on the services `Kati.Media.CachedTitle.providers` says
  it is on, and a watch of that title is an hour spent on one of them.

  One service per watch, never two — a film on Netflix and Now would otherwise
  make both look better value than they are.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Services.Service
  alias Kati.Subscriptions

  doctest Subscriptions, only: [active_line: 1, billed_to: 3, rate: 2]

  @prefix "sub-ledger-"

  setup do
    on_exit(fn ->
      Kati.Repo.query!(
        "DELETE FROM media_watches WHERE tracked_title_id IN " <>
          "(SELECT id FROM tracked_titles WHERE source_id LIKE ?1)",
        [@prefix <> "%"]
      )

      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM services WHERE name LIKE ?1", ["Ledger %"])
    end)

    :ok
  end

  describe "with nothing subscribed" do
    test "there is no ledger, and the page says so rather than drawing a bill" do
      assert Subscriptions.ledger() == nil

      assert Kati.Screens.Subscriptions.ledger() == Kati.Screens.Subscriptions.empty_ledger(),
             "a reader who pays for nothing was shown `5 active`, `£46.47` and four " <>
               "services — on a page about money"

      refute Kati.Screens.Subscriptions.ledger() == Kati.Screens.Subscriptions.drawn_ledger()
    end
  end

  describe "with the reader's own services" do
    setup do
      Ash.create!(Service, %{name: "Ledger Netflix", tier: :subscribed, monthly_pence: 1099})
      Ash.create!(Service, %{name: "Ledger Now", tier: :subscribed, monthly_pence: 999})
      :ok
    end

    test "the count and the total are theirs" do
      ledger = Subscriptions.ledger()

      assert ledger.active_line == "2 active"
      assert ledger.monthly.total == "£20.98"
    end

    test "and no change line, because nothing records what a price used to be" do
      assert Subscriptions.ledger().monthly.change_amount == nil
    end

    test "the rows are theirs, in the order the account holds them" do
      names = Subscriptions.ledger().services |> Enum.map(& &1.name) |> Enum.sort()

      assert names == ["Ledger Netflix", "Ledger Now"]
      refute Enum.any?(Subscriptions.ledger().services, &(&1.name == "Lumen+"))
    end
  end

  describe "the hours" do
    setup do
      Ash.create!(Service, %{name: "Ledger Netflix", tier: :subscribed, monthly_pence: 1099})
      :ok
    end

    test "come from where the title streams, not from a column nobody writes" do
      tracked = shelve!("Dune", %{"GB" => %{"flatrate" => ["Ledger Netflix"]}}, 155)
      watch!(tracked)

      assert Subscriptions.hours_by_service() == %{"ledger netflix" => 155}
    end

    test "so a row says how many and what that costs an hour" do
      tracked = shelve!("Dune", %{"GB" => %{"flatrate" => ["Ledger Netflix"]}}, 600)
      watch!(tracked)

      row = Subscriptions.ledger().services |> Enum.find(&(&1.name == "Ledger Netflix"))

      assert row.line == "10h watched"
      assert row.rate == "£1.10/h"
    end

    test "a title on a service nobody pays for is nobody's hour" do
      tracked = shelve!("Dune", %{"GB" => %{"flatrate" => ["Apple TV"]}}, 155)
      watch!(tracked)

      assert Subscriptions.hours_by_service() == %{}
    end

    test "and a title nobody has looked up is nobody's hour either" do
      tracked = shelve!("Dune", nil, 155)
      watch!(tracked)

      assert Subscriptions.hours_by_service() == %{}
    end

    test "a title on two services you pay for counts once" do
      Ash.create!(Service, %{name: "Ledger Now", tier: :subscribed, monthly_pence: 999})

      tracked =
        shelve!("Dune", %{"GB" => %{"flatrate" => ["Ledger Now", "Ledger Netflix"]}}, 100)

      watch!(tracked)

      hours = Subscriptions.hours_by_service()

      assert map_size(hours) == 1
      assert hours == %{"ledger netflix" => 100}
    end
  end

  describe "the page itself" do
    test "draws no `nil` anywhere, whatever the account is missing" do
      # Found on the device in the first minute of looking at this page: a
      # service with no price and no renewal date put the four letters `nil`
      # on screen five times. A `Text` whose value is `nil` renders it.
      Ash.create!(Service, %{name: "Ledger Bare", tier: :subscribed})

      words = Kati.Screens.Subscriptions.content(%{suggestion: true, reminded: false})

      refute inspect(words, limit: :infinity, printable_limit: :infinity) =~ "\"nil\""
    end

    test "and its back pill names where the reader came from" do
      assert Kati.Screens.Subscriptions.__info__(:attributes)

      {:ok, socket} =
        Kati.Screens.Subscriptions.mount(%{}, %{}, Mob.Socket.new(Kati.Screens.Subscriptions))

      words =
        socket.assigns
        |> Kati.Screens.Subscriptions.render()
        |> inspect(limit: :infinity, printable_limit: :infinity)

      assert words =~ "My services"
      refute words =~ "Stats"
    end
  end

  describe "the card at the foot" do
    setup do
      Ash.create!(Service, %{name: "Ledger Netflix", tier: :subscribed, monthly_pence: 1099})
      :ok
    end

    test "names the service being paid for and not used" do
      advice = Subscriptions.ledger().suggestion

      assert advice.body =~ "Ledger Netflix"
      assert advice.body =~ "£10.99"
    end

    test "and says nothing at all when every service is being used" do
      tracked = shelve!("Dune", %{"GB" => %{"flatrate" => ["Ledger Netflix"]}}, 600)
      watch!(tracked)

      assert Subscriptions.ledger().suggestion == nil
    end
  end

  defp shelve!(title, providers, runtime) do
    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: @prefix <> title,
      kind: :movie,
      title: title,
      providers: providers,
      runtime_minutes: runtime,
      fetched_at: Kati.Time.now()
    })

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: @prefix <> title,
      kind: :movie,
      status: :finished
    })
  end

  defp watch!(tracked) do
    Ash.create!(Watch, %{
      tracked_title_id: tracked.id,
      watched_on: Kati.Time.today(),
      watched_at: Kati.Time.now() |> DateTime.truncate(:second)
    })
  end
end
