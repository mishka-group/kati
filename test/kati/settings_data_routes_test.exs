Code.require_file("../support/screen_sweep.exs", __DIR__)

defmodule Kati.SettingsDataRoutesTest do
  @moduledoc """
  The two Data rows on screens 24 and 62 that reach the backup and sync
  engines.

  ## The defect this exists for

  `Kati.Backup` and `Kati.Sync` are finished and exercised against the running
  app over Erlang distribution — an 8736-byte export, a restore that refuses a
  non-empty database by table and count, `:merge`, an encrypted export, a wrong
  passphrase, an outbox with retries, a rejection log. **Nothing called any of
  it.** No screen in the app pushed to a backup screen or a sync screen, so a
  user could not back up, could not restore, and could not see a conflict, and
  every engine test was green the whole time.

  A screen nothing opens is exactly as useful as no screen, which is why this
  file asserts the wire from both ends — the half `Kati.ScreenTapSweepTest`
  structurally cannot ask. That sweep asks *"does something answer every tag a
  screen draws"*; it cannot ask *"does anything draw the tag this handler
  answers"*, and a destination with no door passes it in silence.
  `Kati.MealsRoutesTest` was written after that shape cost three screens.

  ## Why the two screens key their destinations differently

  Screen 24 keys `@destinations` on the row's English title, which is what it
  already did for Import and Text size. Screen 62 keys on the row's **glyph**,
  because its titles are Persian: a tag is an atom that crosses into Kotlin and
  back, `برون‌ریزی همه‌چیز` carries a zero-width non-joiner, and the rest of that
  screen's tags are ASCII and positional for the same reason.

  So the tags differ by design and the *destinations* may not. `both screens
  name the same two destinations` is the assertion that keeps the mirror a
  mirror.

  ## What is deliberately not asserted

  That `Kati.Screens.Backup` and `Kati.Screens.Sync` compile. They are being
  built alongside this wiring and may not exist in a given tree;
  `Mob.Socket.push_screen/3` records `{:push, module, params}` without touching
  the module, so the route is checkable before the destination lands and stays
  checkable after. `Kati.ScreenDesignLiteralTest`'s registry test is what will
  have an opinion about them once they do.
  """
  use Mob.ScreenCase, async: false

  alias Kati.ScreenSweep
  alias Kati.Screens.Settings
  alias Kati.Screens.SettingsFa

  # `{screen, tag, destination, which row in the drawing}`. Both locales, in one
  # table, because the point of the pair is that they arrive at the same place.
  @routes [
    {Settings, :"go_Export everything", Kati.Screens.Backup, "24's Data group, upload row"},
    {Settings, :go_Sync, Kati.Screens.Sync, "24's Data group, sync row"},
    {SettingsFa, :go_upload, Kati.Screens.Backup, "62's داده‌ها group, upload row"},
    {SettingsFa, :go_sync, Kati.Screens.Sync, "62's داده‌ها group, sync row"}
  ]

  test "the route table names four distinct controls" do
    # The guard on every table-driven test below: a `for` over an empty list
    # asserts nothing and passes.
    assert length(@routes) == 4

    tags = for {from, tag, _to, _why} <- @routes, do: {from, tag}
    assert Enum.uniq(tags) == tags, "two rows claim the same control"
  end

  test "every route's tag is actually drawn by the screen it belongs to" do
    # Read off the rendered tree, so this is the control a user can see rather
    # than an entry in a map. A handler for a tag nothing draws is a destination
    # with no door — the failure this file's moduledoc is about.
    for {from, tag, _to, why} <- @routes do
      tags = drawn(from)

      assert tag in tags,
             "#{inspect(from)} answers #{inspect(tag)} (#{why}) but draws no control that " <>
               "sends it; it drew #{inspect(tags)}"
    end
  end

  test "every route pushes the screen it names" do
    # Dispatched through `handle_info/2`, which is the device path byte for
    # byte: a tap sends `{:tap, tag}` to the screen process, for a macro screen
    # and a hand-rolled Persian mirror alike.
    for {from, tag, to, why} <- @routes do
      assert push_target(from, tag) == to,
             "#{inspect(from)} #{inspect(tag)} (#{why}) did not push #{inspect(to)}"
    end
  end

  test "both screens reach both engines, and 62's extra rows are 24's in Persian" do
    both = MapSet.new([Kati.Screens.Backup, Kati.Screens.Sync])

    assert MapSet.subset?(both, MapSet.new(Map.values(Settings.destinations()))),
           "screen 24 no longer reaches both engines"

    assert MapSet.subset?(both, MapSet.new(Map.values(SettingsFa.destinations()))),
           "screen 62 no longer reaches both engines"

    # This used to be an equality, because 62's Data group named exactly the two
    # engines and nothing else. It stopped being one when screens 82, 85 and 97
    # landed: the Persian settings page gained the same two rows the English one
    # gained for 80 and 83, and a mirror that did NOT gain them would be the
    # defect — a Persian reader who could not reach Data sources at all.
    #
    # So the assertion moved from "these and no others" to the two things that
    # are actually true: both engines are reachable from both screens, and every
    # extra destination 62 names is one 24 names too. A route that existed only
    # in Persian would fail here, which is what the equality was protecting.
    fa = MapSet.new(Map.values(SettingsFa.destinations()))
    en = MapSet.new(Map.values(Settings.destinations()))

    persian_only =
      fa
      |> MapSet.difference(en)
      |> MapSet.difference(
        MapSet.new([
          Kati.Screens.MyServicesFa,
          Kati.Screens.DataSourcesFa,
          Kati.Screens.AttributionFa
        ])
      )

    assert MapSet.to_list(persian_only) == [],
           "screen 62 reaches something screen 24 does not, and it is not one of the two " <>
             "Persian mirrors: " <> inspect(MapSet.to_list(persian_only))
  end

  test "the two rows are the ones the drawings put the upload and sync glyphs on" do
    # The destination is keyed by title on 24 and by glyph on 62, so the two
    # tables can only agree while the titles and the glyphs sit on the same
    # rows. Read from the samples, which is where the copy lives.
    en = Map.new(Kati.Settings.Sample.data(), &{&1.title, &1.icon})

    assert en["Export everything"] == "upload"
    assert en["Sync"] == "sync"

    fa = for section <- Kati.Fa.SampleSettings.sections(), row <- section.rows, do: row[:icon]

    assert "upload" in fa
    assert "sync" in fa
  end

  test "no row is both a switch and a destination" do
    # Screen 24 builds its tags as `switch_<title>` and `go_<title>` off the
    # same string, and its moduledoc claims the two prefixes cannot collide. A
    # title that was both would draw one tag and answer the other.
    switches =
      for rows <- [Kati.Settings.Sample.appearance(), Kati.Settings.Sample.sections()],
          %{control: {:switch, _}, title: title} <- rows,
          do: title

    assert switches != []
    assert Enum.filter(switches, &Map.has_key?(Settings.destinations(), &1)) == []
  end

  test "a tag naming a destination the screen does not have changes nothing" do
    # Both screens parse the tag rather than matching it, so a malformed one has
    # to return the screen instead of raising into `handle_info/2` — 62 in
    # particular is a bare `Mob.Screen` with no rescue around its taps.
    for {module, tag} <- [{Settings, :go_Nowhere}, {SettingsFa, :go_thermostat}] do
      {socket, _tags} = mounted(module)
      {:noreply, updated} = module.handle_info({:tap, tag}, socket)

      assert Map.get(updated.__mob__, :nav_action) == nil
      assert updated.assigns == socket.assigns
    end
  end

  # ── Reading the routes out of the rendered screens ──────────────────────────

  # 24 is drawn in English and 62 in Persian, which is how each is read.
  defp locale(SettingsFa), do: :fa
  defp locale(_module), do: :en

  defp mounted(module) do
    ScreenSweep.drawn_taps(locale(module)) |> Map.fetch!(module)
  end

  defp drawn(module) do
    {_socket, tags} = mounted(module)
    tags
  end

  defp push_target(module, tag) do
    {socket, _tags} = mounted(module)

    case module.handle_info({:tap, tag}, socket) do
      {:noreply, %Mob.Socket{} = updated} ->
        case Map.get(updated.__mob__, :nav_action) do
          {:push, dest, _params} -> dest
          other -> other
        end

      other ->
        other
    end
  end
end
