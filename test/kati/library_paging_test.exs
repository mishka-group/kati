defmodule Kati.LibraryPagingTest do
  @moduledoc """
  The Library reads its shelf a page at a time and draws the next page when
  the grid's end is reached, so a shelf of hundreds opens as fast as one of ten.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Media.TrackedTitle
  alias Kati.Screens.Library

  @tables ~w(media_watches media_content_warnings tracked_titles cached_titles)

  setup do
    empty_the_tables!()
    Mob.State.put("library:shelf_filters", nil)
    on_exit(&empty_the_tables!/0)
    :ok
  end

  defp empty_the_tables! do
    for table <- @tables, do: Ecto.Adapters.SQL.query!(Kati.Repo, "delete from #{table}", [])
    :ok
  end

  defp shelve!(n, status) do
    for i <- 1..n do
      TrackedTitle
      |> Ash.Changeset.for_create(:create, %{
        source: :manual,
        source_id: "page-#{status}-#{i}",
        kind: :tv,
        status: status
      })
      |> Ash.create!()
    end
  end

  test "the grid opens on one page and the end of the list brings the next" do
    shelve!(40, :watching)
    shelve!(5, :finished)

    view = mount_screen(Library)
    assert length(assigns(view).titles) == 30
    assert assigns(view).more?
    assert assigns(view).counts.all == 45
    assert assigns(view).counts.watching == 40

    scroll = Enum.find(flatten(view), &(&1.type == :scroll and &1.props[:lazy] == true))
    assert {_pid, :more_titles} = scroll.props.on_end_reached

    view = render_info(view, {:tap, :more_titles})
    assert length(assigns(view).titles) == 45
    refute assigns(view).more?
    assert assigns(view).titles |> Enum.map(& &1.id) |> Enum.uniq() |> length() == 45

    view = render_info(view, {:tap, :more_titles})
    assert length(assigns(view).titles) == 45
  end

  test "a chip pages its own titles from the store" do
    shelve!(40, :watching)
    shelve!(5, :finished)

    view = mount_screen(Library) |> render_info({:tap, :filter_finished})
    assert assigns(view).filter == :finished
    assert length(assigns(view).titles) == 5
    refute assigns(view).more?
    assert Enum.all?(assigns(view).titles, &(&1.status == :finished))
  end

  test "coming back keeps every page that was drawn" do
    shelve!(40, :watching)

    view = mount_screen(Library) |> render_info({:tap, :more_titles})
    assert length(assigns(view).titles) == 40

    view = render_info(view, {:kati, :resumed, %{}})
    assert length(assigns(view).titles) == 40
  end

  test "a sort the store cannot page still draws a page at a time" do
    shelve!(35, :watching)
    choice = %{Kati.Library.ShelfFilters.resting() | sort: :title, direction: :asc}

    {rows, more?} = Library.page(choice, :all, 0)
    assert length(rows) == 30
    assert more?

    {rest, more?} = Library.page(choice, :all, 30)
    assert length(rest) == 5
    refute more?
  end
end
