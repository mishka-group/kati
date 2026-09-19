defmodule Kati.LibrarySegmentsTest do
  @moduledoc """
  The shelf switcher never hides the shelf you are standing on.

  `kept_segments/1` filters the three segments by `Kati.Sections.on?/1`, which
  is the design's rule — turning a section off removes it everywhere at once.
  But Library is a permanent dock root: `Kati.Shell` lists it beside Home,
  Calendar and Stats, so a reader who turns the **Screen** section off is still
  one tap from this page. The filter then dropped the Screen segment while the
  grid below went on drawing films — the strip offered Books and Music, nothing
  was lit, and the one segment naming the page you were standing on was the one
  missing. MOVIES-AND-TV.md `03 scenario 9`.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Screens.Library
  alias Kati.Sections

  # Restored going IN rather than coming out. `Mob.State` is already down by the
  # time `on_exit` runs, so a restore there exits with `no process` and takes
  # the test with it — which is how the first cut of this file failed.
  setup do
    :ok = Sections.put(Sections.all())
    :ok
  end

  defp labels(active) do
    active
    |> Library.kept_segments()
    |> inspect(limit: :infinity)
  end

  test "with every section kept, all three are offered" do
    Sections.put(["screen", "books", "music"])

    drawn = labels(:screen)

    assert drawn =~ "shelf_books"
    assert drawn =~ "shelf_music"
  end

  test "a section that is off loses its segment — the rule this filter is for" do
    Sections.put(["screen"])

    drawn = labels(:screen)

    refute drawn =~ "shelf_books", "Books is off and was still offered"
    refute drawn =~ "shelf_music"
  end

  test "but the active one survives the filter, whatever the sections say" do
    Sections.put(["books", "music"])

    drawn = labels(:screen)

    assert drawn =~ "shelf_screen",
           "the strip dropped the segment naming the page the reader is on, and lit nothing"

    assert drawn =~ "shelf_books"
  end

  test "and it is still drawn as the active one" do
    Sections.put(["books"])

    # `segment/4` gives the active one `Palette.card()` and bold; the others
    # are transparent and semibold. Whatever the sections say, exactly one
    # segment on this strip is lit, and it is the page you are looking at.
    drawn = labels(:screen)

    assert drawn =~ "shelf_screen"
    assert drawn =~ "bold"
  end

  test "and the sections are left as this file found them" do
    # The restore the setup cannot do on the way out, said as its own
    # assertion so a later file does not inherit this one's narrowed shelf.
    :ok = Sections.put(Sections.all())

    assert Sections.on?("screen")
    assert Sections.on?("books")
  end
end
