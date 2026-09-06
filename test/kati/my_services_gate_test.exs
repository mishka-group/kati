defmodule Kati.MyServicesGateTest do
  @moduledoc """
  Screen 92 answers the same question Home does.

    * **#75.** Home reads `Kati.Services.subscribed_count/0` and says *No
      subscriptions yet*; tapping it opened 92 listing Lumen+ £8.99, Orbit
      £13.99, Kino £11.49, *Subscribed · 3* and `£46.47 A MONTH`. Two screens,
      opposite answers, one tap apart. It was fixed on Home's side only, and
      92's own moduledoc said so.
    * **#76.** The two groups fell back INDEPENDENTLY, so adding one service
      through *Something else* produced a page that was half the reader's and
      half the drawing's — their one service under Subscribed, Aria Free and
      Dispatch still under Free — and the Money row read `£46.47 a month`
      beside a live count of *1 service*.
    * **#78.** Screen 94's field promised `Search 190 countries` over a list of
      seven and filtered nothing: its tap fell through to
      `handle_info(_message, …)` and the sweep had it on `@inert_taps`.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Screens.CountryPicker
  alias Kati.Screens.MyServices
  alias Kati.Services.Sample
  alias Kati.Services.Service

  doctest CountryPicker, only: [matching: 1]

  setup do
    on_exit(fn -> Kati.Repo.query!("DELETE FROM services WHERE name LIKE ?1", ["Gate %"]) end)
    :ok
  end

  describe "with nothing set up" do
    test "the board stands, WHOLE — which is the half of #75 still open" do
      refute MyServices.set_up?()

      assert MyServices.subscribed() == Sample.subscribed()
      assert MyServices.free() == Sample.free()
      assert MyServices.monthly_total() == Sample.monthly_total()
    end

    test "and Home says the opposite one tap away" do
      # This is #75, stated rather than hidden: Home refuses to draw the
      # drawing on an empty device (#91) and 92 draws it, so a reader is told
      # *No subscriptions yet* and then shown three subscriptions.
      #
      # Closing it needs 92's empty state to be board 93's — the
      # `@empty_boards` mapping this repo already has for screens 01 and 154 —
      # and 92 reads its services through function calls rather than assigns,
      # so `Kati.ScreenDesignLiteralTest.drawn_state/0` cannot put it in the
      # state its own board draws. Boards 24 and 42 quote 92's line as well.
      # It is one well-shaped piece of work and it is not this one.
      assert Kati.Services.subscribed_count() == 0
      assert Kati.Screens.Home.services_line(%{count: 0}) == "No subscriptions yet"
      assert length(MyServices.subscribed()) == 3
    end
  end

  describe "with one service added" do
    setup do
      Ash.create!(Service, %{name: "Gate One", tier: :subscribed, monthly_pence: 899})
      :ok
    end

    test "the whole page is the reader's, not half of it" do
      assert MyServices.set_up?()

      assert Enum.map(MyServices.subscribed(), & &1.name) == ["Gate One"]

      assert MyServices.free() == [],
             "the Free group still shows the drawing's two beside the reader's one"

      refute Enum.any?(MyServices.free(), &(&1.name == "Aria Free"))
    end

    test "and the total is what those services cost" do
      assert MyServices.monthly_total() == "£8.99"

      refute MyServices.monthly_total() == Sample.monthly_total(),
             "the Money row still reads £46.47 beside a live count"
    end

    test "a free service counts as set up too" do
      Ash.create!(Service, %{name: "Gate Free", tier: :free_with_ads})

      assert Enum.map(MyServices.free(), & &1.name) == ["Gate Free"]
    end

    test "and services with no price say so rather than borrowing the drawing's" do
      Kati.Repo.query!("DELETE FROM services WHERE name LIKE ?1", ["Gate %"])
      Ash.create!(Service, %{name: "Gate Unpriced", tier: :subscribed})

      assert MyServices.monthly_total() == "—"
    end
  end

  describe "screen 94's field" do
    test "filters by name and by code" do
      assert CountryPicker.matching("ger") == [{"DE", "Germany"}]
      assert CountryPicker.matching("nl") == [{"NL", "Netherlands"}]
      assert CountryPicker.matching("united") |> length() == 2
    end

    test "an empty query is every country" do
      assert CountryPicker.matching("  ") == Kati.Services.countries()
    end

    test "the placeholder counts the list it filters" do
      drawn = inspect(CountryPicker.search_field(""), limit: :infinity)

      assert drawn =~ "Search #{length(Kati.Services.countries())} countries"

      refute drawn =~ "Search 190 countries",
             "the placeholder still promises JustWatch's list over Kati's seven"
    end

    test "and the field is a field" do
      drawn = inspect(CountryPicker.search_field(""), limit: :infinity)

      assert drawn =~ "country_query", "the field is still a picture"
    end

    test "a query that matches nothing says so" do
      drawn = inspect(CountryPicker.list("GB", "zzzz"), limit: :infinity)

      assert drawn =~ "No country matches"
      refute drawn =~ "United Kingdom"
    end
  end
end
