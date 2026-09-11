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

  ## The two boards are one screen, and the tags are ids

  Screen 24 keyed `@destinations` on the row's English TITLE and screen 62 on
  the row's **glyph**, because its titles are Persian — a tag is an atom that
  crosses into Kotlin and back, and `برون‌ریزی همه‌چیز` carries a zero-width
  non-joiner. Both are gone: every row carries an `id`, which is the one field
  on it that is neither drawn nor translated, and mishka-group/kati#103 then
  folded `Kati.Screens.SettingsFa` into screen 24 outright. Board 62 is that
  screen under `:fa`.

  So the pairs below are one module rendered twice. They are still pairs,
  because the thing worth asserting did not change: a Persian reader reaches
  both engines, through the same tag, at the same row.

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

  # `{locale, tag, destination, which row in the drawing}`. Both scripts, in one
  # table, because the point of the pair is that they arrive at the same place.
  @routes [
    {:en, :go_export, Kati.Screens.Backup, "24's Data group, upload row"},
    {:en, :go_sync, Kati.Screens.Sync, "24's Data group, sync row"},
    {:fa, :go_export, Kati.Screens.Backup, "62's داده‌ها group, upload row"},
    {:fa, :go_sync, Kati.Screens.Sync, "62's داده‌ها group, sync row"}
  ]

  test "the route table names four distinct controls" do
    # The guard on every table-driven test below: a `for` over an empty list
    # asserts nothing and passes.
    assert length(@routes) == 4

    tags = for {locale, tag, _to, _why} <- @routes, do: {locale, tag}
    assert Enum.uniq(tags) == tags, "two rows claim the same control"
  end

  test "every route's tag is actually drawn by the screen it belongs to" do
    # Read off the rendered tree, so this is the control a user can see rather
    # than an entry in a map. A handler for a tag nothing draws is a destination
    # with no door — the failure this file's moduledoc is about.
    for {locale, tag, _to, why} <- @routes do
      tags = drawn(locale)

      assert tag in tags,
             "screen 24 in #{locale} answers #{inspect(tag)} (#{why}) but draws no control " <>
               "that sends it; it drew #{inspect(tags)}"
    end
  end

  test "every route pushes the screen it names" do
    # Dispatched through `handle_info/2`, which is the device path byte for
    # byte: a tap sends `{:tap, tag}` to the screen process.
    for {locale, tag, to, why} <- @routes do
      assert push_target(locale, tag) == to,
             "screen 24 in #{locale} #{inspect(tag)} (#{why}) did not push #{inspect(to)}"
    end
  end

  test "both boards reach both engines, through the same two ids" do
    both = MapSet.new([Kati.Screens.Backup, Kati.Screens.Sync])

    assert MapSet.subset?(both, MapSet.new(Map.values(Settings.destinations()))),
           "screen 24 no longer reaches both engines"

    # One table, so there is nothing left for a Persian reader to be missing.
    # It was two: `Kati.Screens.SettingsFa.destinations/0` was a second map,
    # keyed by glyph, and this test's older form compared the two sets and
    # exempted the mirrors 62 pointed at. mishka-group/kati#103 folded that
    # screen into this one; what remains worth asserting is that the two rows
    # are DRAWN in Persian, which the route table above checks against the
    # rendered tree, and that the engines are still named here.
    assert Settings.destinations()["export"] == Kati.Screens.Backup
    assert Settings.destinations()["sync"] == Kati.Screens.Sync
  end

  test "the two rows are one row, named by an id in both scripts" do
    # This used to read *the destination is keyed by title on 24 and by glyph
    # on 62, so the two tables can only agree while the titles and the glyphs
    # sit on the same rows* — and that sentence was the defect. There is one
    # table now, keyed on the row's **id**.
    rows = Map.new(Kati.Settings.Sample.data(), &{&1.id, &1.icon})

    assert rows["export"] == "upload"
    assert rows["sync"] == "sync"

    # And the same two ids are on the rows a Persian reader sees, which is the
    # half the mirror used to answer for.
    fa =
      Kati.Locale.as(:fa, fn ->
        for row <- Kati.Settings.Sample.data(), do: row.id
      end)

    assert "export" in fa
    assert "sync" in fa
  end

  test "no row is both a switch and a destination" do
    # Screen 24 builds its tags as `switch_<id>` and `go_<id>` off the same
    # string, and its moduledoc claims the two prefixes cannot collide. An id
    # that was both would draw one tag and answer the other.
    switches =
      for rows <- [Kati.Settings.Sample.appearance(), Kati.Settings.Sample.sections()],
          %{control: {:switch, _}, id: id} <- rows,
          do: id

    assert switches != []
    assert Enum.filter(switches, &Map.has_key?(Settings.destinations(), &1)) == []
  end

  test "every row carries an id, and no two rows in one screen share one" do
    # The whole of why the tags above are ids. `Kati.Settings.Sample`'s
    # moduledoc names the two candidates that are NOT identity: the title,
    # which the fold translates, and the glyph, which `info` and `grid_view`
    # each wear on more than one row.
    rows =
      for group <- [
            Kati.Settings.Sample.appearance(),
            Kati.Settings.Sample.watching(),
            Kati.Settings.Sample.sections(),
            Kati.Settings.Sample.data(),
            Kati.Settings.Sample.about()
          ],
          row <- group,
          do: row

    assert rows != []

    missing = for row <- rows, not is_binary(row[:id]), do: row[:title]
    assert missing == [], "these rows have no id: #{inspect(missing)}"

    ids = Enum.map(rows, & &1.id)
    assert Enum.uniq(ids) == ids, "two rows share an id: #{inspect(ids -- Enum.uniq(ids))}"

    # And the glyph would not have done. Left as a live assertion rather than a
    # comment so the next person to reach for it is stopped by a red test.
    glyphs = Enum.map(rows, & &1.icon)
    assert Enum.uniq(glyphs) != glyphs, "glyphs are unique after all — re-read the id decision"
  end

  test "a tag naming a destination the screen does not have changes nothing" do
    # The screen parses the tag rather than matching it, so a malformed one has
    # to return the screen instead of raising into `handle_info/2`.
    for locale <- [:en, :fa] do
      {socket, _tags} = mounted(locale)
      {:noreply, updated} = Settings.handle_info({:tap, :go_nowhere}, socket)

      assert Map.get(updated.__mob__, :nav_action) == nil
      assert updated.assigns == socket.assigns
    end
  end

  # ── Reading the routes out of the rendered screens ──────────────────────────

  # Board 24 is drawn in English and board 62 in Persian, which is how each is
  # read — one module, two locales, since #103 folded the mirror away.
  defp mounted(locale) do
    ScreenSweep.drawn_taps(locale) |> Map.fetch!(Settings)
  end

  defp drawn(locale) do
    {_socket, tags} = mounted(locale)
    tags
  end

  defp push_target(locale, tag) do
    {socket, _tags} = mounted(locale)

    case Settings.handle_info({:tap, tag}, socket) do
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
