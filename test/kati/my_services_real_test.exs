defmodule Kati.MyServicesRealTest do
  @moduledoc """
  My services says what it is for and every part of it works (#127).

  The page asked for names it gave no way to know, its country note talked
  about a service called Lumen+ that does not exist, *Free with ads* had no
  way in, and *Not mine* listed nothing that was not yours.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Screens.MyServices
  alias Kati.Services.Service

  @prefix "my-services-real-"

  setup do
    on_exit(fn ->
      Kati.Repo.query!("DELETE FROM services WHERE name LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
    end)
  end

  defp shelve!(suffix, flatrate) do
    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: @prefix <> suffix,
      kind: :movie,
      title: suffix,
      providers: %{Kati.Services.region() => %{"flatrate" => flatrate}},
      fetched_at: Kati.Time.now()
    })

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: @prefix <> suffix,
      kind: :movie,
      status: :watching
    })
  end

  defp tags(view) do
    for %{props: %{on_tap: {_pid, tag}}} <- flatten(view), is_atom(tag), do: tag
  end

  defp tier(name), do: Enum.find(Ash.read!(Service), &(&1.name == name)).tier

  test "the page says what it is for, and there is no invented service on it" do
    words = text(mount_screen(MyServices))

    assert words =~ "Tell Kati what you pay for"
    refute words =~ "Lumen+"
  end

  test "the services the reader's own titles are on are offered, most titles first" do
    shelve!("one", [@prefix <> "Mubi", @prefix <> "Max"])
    shelve!("two", [@prefix <> "Mubi"])

    suggestions = Enum.filter(MyServices.suggestions(), fn {n, _} -> String.starts_with?(n, @prefix) end)
    assert suggestions == [{@prefix <> "Mubi", 2}, {@prefix <> "Max", 1}]

    view = mount_screen(MyServices)
    assert text(view) =~ "On 2 of your titles"
  end

  test "I pay adds it as a subscription, Free as free with ads, and both leave the list" do
    shelve!("one", [@prefix <> "Mubi", @prefix <> "Max"])
    view = mount_screen(MyServices)

    index = fn view, name ->
      Enum.find_index(assigns(view).suggestions, fn {n, _} -> n == name end)
    end

    i = index.(view, @prefix <> "Mubi")
    view = render_info(view, {:tap, String.to_atom("suggest_sub_#{i}")})
    assert tier(@prefix <> "Mubi") == :subscribed
    refute index.(view, @prefix <> "Mubi")

    i = index.(view, @prefix <> "Max")
    view = render_info(view, {:tap, String.to_atom("suggest_free_#{i}")})
    assert tier(@prefix <> "Max") == :free_with_ads
    assert text(view) =~ @prefix <> "Max"
  end

  test "a service marked not mine is listed under Not mine, and comes back with Add back" do
    service = Ash.create!(Service, %{name: @prefix <> "Kino", tier: :not_mine})
    view = mount_screen(MyServices)

    tag = String.to_atom("restore_service_" <> service.id)
    assert tag in tags(view)
    assert text(view) =~ "You said this is not yours"

    view = render_info(view, {:tap, tag})
    assert tier(@prefix <> "Kino") == :subscribed
    refute tag in tags(view)
  end

  test "turning a service off lists it under Not mine without leaving the page" do
    service = Ash.create!(Service, %{name: @prefix <> "Plex", tier: :subscribed})
    view = mount_screen(MyServices)
    tag = String.to_atom("restore_service_" <> service.id)
    refute tag in tags(view)

    view = render_info(view, {:tap, String.to_atom("drop_service_" <> service.id)})
    assert tier(@prefix <> "Plex") == :not_mine
    assert tag in tags(view)
  end

  test "a name the reader already has is not offered again" do
    shelve!("one", [@prefix <> "Mubi"])
    Ash.create!(Service, %{name: @prefix <> "MUBI", tier: :subscribed})

    refute Enum.any?(MyServices.suggestions(), fn {n, _} -> n == @prefix <> "Mubi" end)
  end
end
