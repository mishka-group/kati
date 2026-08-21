defmodule Kati.ScreenCalendarsTest do
  @moduledoc """
  Screen 32's middle group, against `Kati.Calendars` and against an empty
  database.

  ## Why this is not covered by the sweeps

  `Kati.ScreenRenderSweepTest` mounts the screen and asserts it renders;
  `Kati.ScreenTapSweepTest` taps what that render drew. Neither reads the copy,
  so a group that queried the wrong table or dropped every row would pass both.
  `Kati.ScreenDesignLiteralTest` does read the copy — but it only asks whether
  a literal is *somewhere* in the tree, and the four calendar names are also in
  `Kati.Settings.CalendarsSample`, which this screen still falls back to. A
  query that answered nothing would therefore keep passing it, exactly the
  blind spot `Kati.ScreenEmptyDatabaseTest` was written for in the other
  direction.

  So each assertion below is a count or an exact value, both ways round:

    * **empty database** — the drawing's four calendars, in its order, with the
      four swatch colours and the one greyed title. This is what keeps the
      screen comparable with `.scratch/design/audit/32.png` on a device that
      has never connected an account.
    * **rows present** — the device's own calendars and *none* of the drawn
      four. A fallback that fires when it should not is exactly as wrong as one
      that never fires.

  ## The wipe in `setup`

  The suite shares one SQLite file (see `test/test_helper.exs`), so "an empty
  database" has to be made rather than assumed — and what this module writes is
  not inert: a calendar left behind is a fifth row on this screen the moment
  another module mounts it. Same reasoning, and the same `on_exit`, as
  `Kati.SeedsTest`, whose own teardown empties these same tables for the same
  reason.
  """
  use Mob.ScreenCase, async: false

  # Deliberately aliased away from `Calendar`, which is Elixir's own module.
  alias Kati.Calendars.Calendar, as: CalendarRow
  alias Kati.Screens.Calendars
  alias Kati.Settings.CalendarsSample, as: Sample
  alias Kati.Theme.Palette

  # Child tables first: events and overrides carry the foreign keys.
  @tables ~w(event_occurrence_overrides events calendars calendar_accounts)

  setup do
    empty_the_tables!()
    on_exit(&empty_the_tables!/0)
    :ok
  end

  defp empty_the_tables! do
    for table <- @tables, do: Ecto.Adapters.SQL.query!(Kati.Repo, "delete from #{table}", [])
    :ok
  end

  defp calendar!(attrs) do
    CalendarRow
    |> Ash.Changeset.for_create(:create, Map.merge(%{kind: :provider}, attrs))
    |> Ash.create!()
  end

  # Four calendars in a deliberate order, covering every branch of
  # `swatch_colour/1`: a named slot, another named slot, a slot the palette has
  # never heard of, and no slot at all — which is what every calendar
  # `Kati.Calendars.DeviceImport` writes looks like.
  defp device_calendars! do
    calendar!(%{remote_id: "dev-1", display_name: "Studio", colour_token: :green, visible: true})

    calendar!(%{
      remote_id: "dev-2",
      display_name: "Rowing",
      colour_token: :bronze,
      visible: false
    })

    calendar!(%{remote_id: "dev-3", display_name: "Term dates", colour_token: :not_a_token})
    calendar!(%{remote_id: "dev-4", display_name: "Imported"})
  end

  # The 12pt fills the group leads each row with, in the order they are drawn.
  defp swatches(tree) do
    tree
    |> find_all(:box, width: 12, height: 12)
    |> Enum.map(& &1.props.background)
  end

  # A row's title, greyed or not, is what says whether the calendar is drawn —
  # `calendar_title/1` picks `body_muted/1` for one that is switched off.
  defp muted?(tree, title), do: find(tree, :text, text: title, text_color: Palette.sub()) != nil

  describe "an empty database" do
    test "the query is empty and the screen still draws the drawing's four" do
      assert Calendars.stored_calendars() == [],
             "the query answered rows against an empty database, so nothing below " <>
               "is measuring the fallback"

      assert Calendars.calendar_list() == Sample.calendars()
    end

    test "every one of them reaches the tree, once each, in the drawing's order" do
      tree = tree(mount_screen(Calendars))

      for %{title: title} <- Sample.calendars() do
        assert length(find_all(tree, :text, text: title)) == 1,
               "#{inspect(title)} is drawn #{length(find_all(tree, :text, text: title))} " <>
                 "times, not once"
      end

      assert swatches(tree) == Enum.map(Sample.calendars(), & &1.color)
    end

    test "the one calendar the drawing does not draw is the one greyed title" do
      tree = tree(mount_screen(Calendars))

      assert muted?(tree, "Birthdays")

      for %{title: title} <- Enum.filter(Sample.calendars(), & &1.on) do
        refute muted?(tree, title), "#{inspect(title)} is switched on and drawn as off"
      end
    end

    test "renders a tree the native layer can draw" do
      assert_renderable(mount_screen(Calendars))
    end
  end

  describe "calendars in the database" do
    setup do
      device_calendars!()
      :ok
    end

    test "the group draws the device's calendars and none of the drawing's" do
      tree = tree(mount_screen(Calendars))

      for title <- ["Studio", "Rowing", "Term dates", "Imported"] do
        assert length(find_all(tree, :text, text: title)) == 1,
               "#{inspect(title)} is in the database and not on the screen"
      end

      for %{title: drawn} <- Sample.calendars() do
        assert find(tree, :text, text: drawn) == nil,
               "the fallback fired over a table that has rows: #{inspect(drawn)} is drawn"
      end
    end

    test "the order is the order they arrived in" do
      assert Enum.map(Calendars.stored_calendars(), & &1.title) == [
               "Studio",
               "Rowing",
               "Term dates",
               "Imported"
             ]
    end

    test "the swatch is the calendar's palette slot, and grey when it has none" do
      assert swatches(tree(mount_screen(Calendars))) == [
               Palette.green(),
               Palette.bronze(),
               # A slot the table has never heard of, and no slot at all. Both
               # are the design's "exists, no colour of its own" grey rather
               # than a colour chosen here — see `swatch_colour/1`.
               Palette.rail_idle(),
               Palette.rail_idle()
             ]
    end

    test "visible is the switch, and an invisible calendar is greyed" do
      tree = tree(mount_screen(Calendars))

      assert muted?(tree, "Rowing")
      refute muted?(tree, "Studio")

      assert Enum.map(Calendars.stored_calendars(), & &1.on) == [true, false, true, true]
    end

    test "a calendar with no name is dropped rather than drawn as a nameless switch" do
      calendar!(%{remote_id: "dev-5", display_name: nil})

      assert length(Ash.read!(CalendarRow)) == 5
      assert length(Calendars.stored_calendars()) == 4
      assert Enum.all?(Calendars.stored_calendars(), &(&1.title != nil))
    end

    test "the two groups that are still the drawing's are still the drawing's" do
      # Stated as a test rather than only in the moduledoc: the accounts group
      # cannot be derived (`Kati.Calendars.Account.provider` collapses iCloud
      # and Fastmail into one `:caldav`, so `cloud` and `dns` are the same
      # value) and nothing stores a per-category write-back preference. If
      # either is ever moved, this fails and says which.
      drawn = text(tree(mount_screen(Calendars)))

      for %{title: title, status: status} <- Sample.accounts() do
        assert drawn =~ title
        assert drawn =~ status
      end

      for %{title: title} <- Sample.write_back(), do: assert(drawn =~ title)
      assert drawn =~ Sample.connected()
      assert drawn =~ Sample.add_account()
    end

    test "renders a tree the native layer can draw" do
      assert_renderable(mount_screen(Calendars))
    end
  end
end
