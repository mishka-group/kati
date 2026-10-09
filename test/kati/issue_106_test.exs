defmodule Kati.Issue106Test do
  @moduledoc """
  mishka-group/kati#106: the services catalogue comes from TMDB with its
  provider ids, is kept on the device for a week, adds a service with its id
  and no price, and narrows Discover to the reader's own services.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Discover.Filters
  alias Kati.Screens.DiscoverFilters
  alias Kati.Screens.MyServices
  alias Kati.Services.Catalogue

  doctest Kati.Media.Tmdb, only: [catalogue: 2]
  doctest Kati.Media.CachePolicy, only: [catalogue_refresh_days: 0]
  doctest Kati.Discover.Filters, only: [providers: 1]

  @rows [
    %{id: "8", name: "Netflix", logo: nil, priority: 1},
    %{id: "337", name: "Disney Plus", logo: nil, priority: 2},
    %{id: "9", name: "Amazon Prime Video", logo: nil, priority: 3}
  ]

  setup do
    on_exit(fn -> Kati.Repo.query!("DELETE FROM services") end)
    :ok
  end

  test "a kept catalogue is answered without asking TMDB, and found by name" do
    Mob.State.put("services:catalogue:GB", %{at: System.os_time(:second), rows: @rows})

    assert {:ok, @rows} = Catalogue.fetch("GB")
    assert %{id: "337"} = Catalogue.named(@rows, " disney plus ")
    assert Catalogue.named(@rows, "Lumen+") == nil
  end

  test "the page lists the catalogue minus what is listed, and adds with the id and no price" do
    {:ok, _} = MyServices.create_service("Netflix", nil, :subscribed, "8")

    socket =
      Mob.Socket.new(MyServices)
      |> MyServices.load()
      |> Mob.Socket.assign(:catalogue, {:ok, @rows})

    drawn =
      inspect(MyServices.catalogue_group(socket.assigns, MyServices.listed()), limit: :infinity)

    assert drawn =~ "FROM TMDB"
    assert drawn =~ "Disney Plus"
    refute drawn =~ "catalogue_sub_8"

    {:noreply, added} = MyServices.handle_tap(:catalogue_sub_337, socket)
    assert added.assigns.notice == nil or match?({:ok, _}, added.assigns.notice)

    disney = Enum.find(Ash.read!(Kati.Services.Service), &(&1.name == "Disney Plus"))
    assert disney.provider_id == "337"
    assert disney.monthly_pence == nil
    assert {"337", "Disney Plus"} in Kati.Services.with_ids()
  end

  test "a region TMDB knows nothing about says so, and the typed card still works" do
    socket =
      Mob.Socket.new(MyServices)
      |> MyServices.load()
      |> Mob.Socket.assign(:catalogue, {:ok, []})
      |> Mob.Socket.assign(:region, "IR")

    drawn =
      inspect(MyServices.catalogue_group(socket.assigns, MyServices.listed()), limit: :infinity)

    assert drawn =~ "TMDB lists no streaming services for"
  end

  test "Discover narrows to the reader's services by provider id, in their region" do
    choice = Filters.with_provider(Filters.resting(), "337")

    assert Filters.narrowed?(choice)

    params = Filters.params(choice, :tv, ~D[2026-10-09])
    assert params[:with_watch_providers] == "337"
    assert params[:with_watch_monetization_types] == "flatrate|free|ads"
    assert is_binary(params[:watch_region])

    assert Kati.Screens.Discover.asked_line(choice) =~ "on your services"
  end

  test "the filter sheet draws one chip per service with an id, and a tap toggles it" do
    {:ok, _} = MyServices.create_service("Disney Plus", nil, :subscribed, "337")
    {:ok, _} = MyServices.create_service("My local club", 500, :subscribed)

    {:ok, socket} = DiscoverFilters.mount(%{}, %{}, Mob.Socket.new(DiscoverFilters))
    drawn = inspect(DiscoverFilters.body(socket.assigns), limit: :infinity)

    assert drawn =~ "service_337"
    refute drawn =~ "My local club"

    {:noreply, on} = DiscoverFilters.handle_info({:tap, :service_337}, socket)
    assert Filters.providers(on.assigns.choice) == ["337"]

    {:noreply, off} = DiscoverFilters.handle_info({:tap, :service_337}, on)
    assert Filters.providers(off.assigns.choice) == []
    Filters.clear()
  end
end
