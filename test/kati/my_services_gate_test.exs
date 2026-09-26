Code.require_file("../support/drawn_boards.exs", __DIR__)

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
    test "the page shows nothing, because there is nothing" do
      refute MyServices.set_up?()

      assert MyServices.subscribed() == []
      assert MyServices.free() == []
    end

    test "and Home says the same thing one tap away" do
      # This WAS #75: Home refuses to draw the drawing on an empty device
      # (#91) and 92 drew it, so a reader was told *No subscriptions yet* and
      # then shown three subscriptions one tap later. The assertion is now the
      # agreement rather than the disagreement.
      assert Kati.Services.subscribed_count() == 0
      assert Kati.Screens.Home.services_line(%{count: 0}) == "No subscriptions yet"
      assert MyServices.subscribed() == []
    end

    test "the eyebrow says none yet, in board 93's own words" do
      assert MyServices.subscribed_label(MyServices.listed()) == "Subscribed · none yet"
    end

    test "the drawing is still there, for the board to be compared against" do
      # The other half of the #91 rule this file exists for: a page that
      # answers empty must not have answered by losing the values its board was
      # captured from. `drawn_page/0` is the arrival board 92 is a drawing OF,
      # and `Kati.ScreenDesignLiteralTest.drawn_state/0` installs it.
      assert Kati.Test.DrawnBoards.services_page().subscribed == Sample.subscribed()
      assert Kati.Test.DrawnBoards.services_page().free == Sample.free()
      assert Kati.Test.DrawnBoards.services_page().set_up?
    end

    test "Settings says none yet too, where its board froze three" do
      assert Kati.Settings.Sample.services_line() =~ "none yet"
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
