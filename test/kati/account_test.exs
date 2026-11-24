defmodule Kati.AccountTest do
  @moduledoc """
  The two controls on screen 40 that did nothing.

  *Move to a new phone* carried a chevron and no tap; *Delete everything* was
  wired to `flip/2`, which turned a picture of a switch over and wrote
  nothing. This file holds what each does now. The wipe itself is not run here
  — the suite shares one SQLite file and a test that emptied it would delete
  every other test's fixtures — so what is checked is the confirmation, the
  tables it would delete and their order. `Kati.Account.wipe!/0` is one
  transaction over that list.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Account
  alias Kati.Screens.Account, as: Screen

  test "the table list is the backup catalogue, child first" do
    tables = Account.tables()

    assert tables == Enum.reverse(Kati.Backup.Catalog.tables())
    assert length(tables) == length(Kati.Backup.Catalog.tables())

    for table <- ~w(tracked_titles media_watches book_notes habit_ticks habits services) do
      assert table in tables, "#{table} is stored but not deleted"
    end

    # A child before its parent, which is the whole point of the order: SQLite
    # refuses the other way round.
    assert Enum.find_index(tables, &(&1 == "habit_ticks")) <
             Enum.find_index(tables, &(&1 == "habits"))
  end

  test "Delete everything asks first, and Cancel changes nothing" do
    view = mount_screen(Screen)

    assert assigns(view).confirming_wipe == false

    view = render_info(view, {:tap, :data_0})
    assert assigns(view).confirming_wipe == true

    view = render_info(view, {:tap, :cancel_wipe})
    assert assigns(view).confirming_wipe == false
    assert assigns(view).wipe_error == nil
  end

  test "Move to a new phone opens the backup screen" do
    view = mount_screen(Screen) |> render_info({:tap, :storage_2})

    assert {:push, Kati.Screens.Backup, _params} = view.socket.__mob__.nav_action
  end
end
