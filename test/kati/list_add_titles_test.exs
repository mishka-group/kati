defmodule Kati.ListAddTitlesTest do
  @moduledoc """
  Filling a list from the list's own page (#114): its `+` opens the Library's
  shelf in a drawer, and a tap on a poster puts that title in the list or takes
  it back out.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Lists.Shelf
  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Screens.ListAddTitles
  alias Kati.Screens.ListDetail

  @tables ~w(list_memberships lists tracked_titles cached_titles)

  setup do
    Kati.Locale.put(:en)
    Kati.Library.ShelfFilters.clear()
    wipe!()
    on_exit(&wipe!/0)

    {:ok, list} = Shelf.create("Rainy Sunday")
    arrival = shelve!("arrival", "Arrival", :movie)
    dark = shelve!("dark", "Dark", :tv)

    %{list: list, arrival: arrival, dark: dark}
  end

  test "the list's page offers the door, and it opens the drawer on that list", %{list: list} do
    page = mount_screen(ListDetail, %{id: list.id})
    assert :add_titles in tap_tags(page)

    {:noreply, socket} = ListDetail.handle_tap(:add_titles, socket_of(page))

    assert {:push, ListAddTitles, %{id: id}} = socket.__mob__.nav_action
    assert id == list.id
  end

  test "the drawer is the shelf, every title marked not in the list yet", %{list: list} do
    drawer = mount_screen(ListAddTitles, %{id: list.id})

    assert "Add to Rainy Sunday" in texts(drawer)

    assert Enum.map(assigns(drawer).titles, &{&1.title, &1.in_list}) |> Enum.sort() ==
             [{"Arrival", false}, {"Dark", false}]
  end

  test "a tap puts the title in the list, and a second tap takes it out", %{
    list: list,
    arrival: arrival
  } do
    drawer = mount_screen(ListAddTitles, %{id: list.id})
    tag = String.to_atom("open_film_" <> arrival.id)

    drawer = render_info(drawer, {:tap, tag})
    assert ListAddTitles.held(list.id) == MapSet.new([arrival.id])
    assert Enum.find(assigns(drawer).titles, &(&1.id == arrival.id)).in_list

    drawer = render_info(drawer, {:tap, tag})
    assert ListAddTitles.held(list.id) == MapSet.new()
    refute Enum.find(assigns(drawer).titles, &(&1.id == arrival.id)).in_list
  end

  test "a series goes in the same way", %{list: list, dark: dark} do
    mount_screen(ListAddTitles, %{id: list.id})
    |> render_info({:tap, String.to_atom("open_series_" <> dark.id)})

    assert [%{title: "Dark"}] = Shelf.detail(list.id).titles
  end

  test "the shelf's own chips filter the drawer", %{list: list} do
    drawer =
      mount_screen(ListAddTitles, %{id: list.id})
      |> render_info({:tap, :filter_finished})

    assert assigns(drawer).filter == :finished
  end

  test "the ✕ and the scrim both close, so the list behind re-reads", %{list: list} do
    for tag <- [:close, :close_scrim] do
      drawer = mount_screen(ListAddTitles, %{id: list.id}) |> render_info({:tap, tag})
      assert socket_of(drawer).__mob__.nav_action == {:pop}
    end
  end

  test "an id that names no list draws the generic heading" do
    assert "Add titles" in texts(mount_screen(ListAddTitles, %{id: Ecto.UUID.generate()}))
  end

  defp shelve!(slug, title, kind) do
    source_id = "list-add-" <> slug

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
      status: :not_started
    })
  end

  defp wipe! do
    for table <- @tables, do: Kati.Repo.query!("DELETE FROM " <> table, [])
    :ok
  end

  defp socket_of(view), do: view.socket

  defp tap_tags(view) do
    for node <- flatten(view),
        {_pid, tag} <- [Map.get(Map.get(node, :props) || %{}, :on_tap)],
        is_atom(tag),
        do: tag
  end

  defp texts(view) do
    view
    |> flatten()
    |> Enum.flat_map(fn node ->
      case Map.get(node, :props) || %{} do
        %{text: text} when is_binary(text) -> [text]
        _other -> []
      end
    end)
  end
end
