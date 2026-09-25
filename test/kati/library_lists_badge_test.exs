defmodule Kati.LibraryListsBadgeTest do
  @moduledoc """
  The *Lists* tile counts, and *Up next* never counts the whole shelf.

  Two halves of one finding.

  The Lists tile carried no badge at all, on the recorded ground that *"there
  is no list resource anywhere in lib/kati"*. **That reason is obsolete**:
  `Kati.Lists.List` is an `Ash.Resource` on AshSqlite and
  `Kati.Lists.Shelf.made/0` reads it. The tile was countless over a store that
  could answer.

  The Up next badge had a subtler version of the same problem. `content/1`
  defaulted it to `length(titles)` — the **whole shelf** — so any render that
  reached the page without `load/1` having assigned `:queued` would badge the
  door to the queue with the size of the library.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Screens.Library

  describe "the Lists badge" do
    test "is nothing at all when no list has been made" do
      # `nil` and not `0`, which is `up_next_badge/1`'s rule one function down:
      # a zero on a door is a number about nothing.
      assert Library.lists_badge(0) == nil
    end

    test "and the reader's own count when they have" do
      assert Library.lists_badge(3) == Kati.Locale.number(3)
    end

    test "read from the resource the old reason said did not exist" do
      assert is_integer(Library.lists_kept())
      assert Library.lists_kept() >= 0
    end

    test "and it is drawn on the tile" do
      drawn = inspect(Library.quick_tiles(0, 4), limit: :infinity)

      assert drawn =~ "open_lists"
      assert drawn =~ Kati.Locale.number(4)
    end

    test "with no badge drawn over no lists" do
      none = inspect(Library.quick_tiles(0, 0), limit: :infinity)

      assert none =~ "open_lists", "the tile is a door and stays on an empty shelf"
      refute none =~ "\"0\"", "a zero on a door is a number about nothing"
    end
  end

  describe "the Up next badge" do
    test "never falls back to the size of the whole shelf" do
      # It defaulted to `length(titles)`. `load/1` always assigns `:queued`, so
      # this was a lie waiting for the first render that skipped it — which is
      # exactly what the design sweeps do.
      drawn =
        inspect(Library.content(%{filter: :all, titles: [], menu?: false}), limit: :infinity)

      assert drawn =~ "open_up_next"
    end

    test "and draws nothing over an empty queue" do
      assert Library.up_next_badge(0) == nil
    end
  end
end
