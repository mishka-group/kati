defmodule Kati.AvailabilityTest do
  @moduledoc """
  The three availability rules, doing what their sentences say.

  The audit's finding: *"All three availability rules are stored and consumed
  by nothing. `Hide titles I can't watch` prints 'Removes them from Discover,
  Up next and What fits tonight' — all three of those screens are fixtures
  that never call `Kati.Services.rules/0`."*

  Nothing consumed them because nothing knew where a title streams. TMDB does,
  and folds it into the detail response Kati already fetches, so the answer
  arrives with the poster.

  The rule this file exists to hold is the third answer: **`:unknown` is not
  `false`.** A title nobody has fetched providers for is not one the reader
  cannot watch, and hiding it would empty a shelf for a reason they have no
  way to discover.
  """

  use ExUnit.Case, async: true

  alias Kati.Media.Availability
  alias Kati.Media.Tmdb

  doctest Availability
  doctest Tmdb, only: [providers: 1]

  @strict %{rentals: false, purchases: false, hide_unavailable: true}
  @lenient %{rentals: true, purchases: true, hide_unavailable: true}
  @off %{rentals: false, purchases: false, hide_unavailable: false}

  describe "what TMDB sends back" do
    test "becomes names by region and monetisation" do
      body = %{
        "watch/providers" => %{
          "results" => %{
            "GB" => %{
              "link" => "https://www.themoviedb.org/…",
              "flatrate" => [%{"provider_name" => "Netflix"}, %{"provider_name" => "Now"}],
              "rent" => [%{"provider_name" => "Apple TV"}],
              "buy" => []
            },
            "IE" => %{"flatrate" => [%{"provider_name" => "Netflix"}]}
          }
        }
      }

      assert Tmdb.providers(body) == %{
               "GB" => %{"flatrate" => ["Netflix", "Now"], "rent" => ["Apple TV"]},
               "IE" => %{"flatrate" => ["Netflix"]}
             }
    end

    test "and a response with no block at all answers nil, so a failed fetch overwrites nothing" do
      assert Tmdb.providers(%{"title" => "Dune"}) == nil
      assert Tmdb.providers(%{"watch/providers" => %{"results" => %{}}}) == nil
    end
  end

  describe "a title on a service you pay for" do
    setup do
      %{offers: %{"flatrate" => ["Netflix"], "rent" => ["Apple TV"]}}
    end

    test "is available, whatever the rules say", %{offers: offers} do
      assert Availability.state(offers, ["Netflix"], @strict) == :available
      refute Availability.hide?(offers, ["Netflix"], @strict)
    end

    test "matches the name however it was typed", %{offers: offers} do
      assert Availability.state(offers, ["  netflix "], @strict) == :available
    end

    test "and says where", %{offers: offers} do
      assert Availability.line(offers, ["Netflix"], @strict) == "On Netflix"
    end
  end

  describe "a title only for rent" do
    setup do
      %{offers: %{"rent" => ["Apple TV"], "buy" => ["Amazon"]}}
    end

    test "is unavailable until the rentals rule is on", %{offers: offers} do
      assert Availability.state(offers, ["Netflix"], @strict) == :unavailable
      assert Availability.state(offers, ["Netflix"], @lenient) == :available
    end

    test "is hidden only while the switch is on", %{offers: offers} do
      assert Availability.hide?(offers, [], @strict)
      refute Availability.hide?(offers, [], @off)
      refute Availability.hide?(offers, [], @lenient)
    end

    test "and says nothing it is not entitled to say", %{offers: offers} do
      assert Availability.line(offers, [], @strict) == nil
      assert Availability.line(offers, [], @lenient) == "Rent from Apple TV"
    end
  end

  describe "free" do
    test "needs no rule, because there is nothing to opt into" do
      offers = %{"free" => ["Channel 4"]}

      assert Availability.state(offers, [], @strict) == :available
      assert Availability.line(offers, [], @strict) == "Free on Channel 4"
    end

    test "with ads counts too" do
      assert Availability.state(%{"ads" => ["ITVX"]}, [], @strict) == :available
    end
  end

  describe "a title nobody has looked up" do
    test "is unknown, and unknown is never hidden" do
      assert Availability.state(nil, ["Netflix"], @strict) == :unknown
      refute Availability.hide?(nil, ["Netflix"], @strict)
      assert Availability.line(nil, ["Netflix"], @strict) == nil
    end

    test "and neither is a title in a region JustWatch does not cover" do
      providers = %{"GB" => %{"flatrate" => ["Netflix"]}}

      assert Availability.offers(providers, "IR") == nil
      refute Availability.hide?(Availability.offers(providers, "IR"), [], @strict)
    end
  end

  describe "a title available nowhere at all" do
    test "is unavailable, which is a different fact from unknown" do
      assert Availability.state(%{}, ["Netflix"], @strict) == :unavailable
      assert Availability.hide?(%{}, ["Netflix"], @strict)
    end
  end

  describe "the line" do
    test "names two, and counts the rest" do
      three = %{"flatrate" => ["Netflix", "Now", "Disney+"]}

      assert Availability.line(three, ["Netflix", "Now", "Disney+"], @strict) ==
               "Netflix, Now and 1 more" |> then(&("On " <> &1))
    end

    test "prefers what you pay for over what you could rent" do
      offers = %{"flatrate" => ["Netflix"], "rent" => ["Apple TV"]}

      assert Availability.line(offers, ["Netflix"], @lenient) == "On Netflix"
    end
  end

  describe "what Kati can suggest" do
    test "is the services the reader's own titles are on, commonest first" do
      titles = [
        %Kati.Media.CachedTitle{providers: %{"GB" => %{"flatrate" => ["Netflix"]}}},
        %Kati.Media.CachedTitle{providers: %{"GB" => %{"flatrate" => ["Netflix", "Now"]}}},
        %Kati.Media.CachedTitle{providers: nil}
      ]

      assert Availability.suggestions(titles, "GB") == [{"Netflix", 2}, {"Now", 1}]
    end
  end
end
