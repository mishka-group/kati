defmodule Kati.ImportStepLabelTest do
  @moduledoc """
  A real import's step meter speaks the reader's language.

  `Kati.Import.Sample.recognised/0` built the kicker through `pgettext/2` and
  `Kati.Locale.number/1`. `Kati.Import.Job.recognised/1` — the function every
  REAL import goes through — hardcoded the bare string `"STEP 1 OF 4"`. So the
  fixture spoke Persian and the reader's own file did not, which is the one
  arrangement that guarantees nobody notices: the board renders correctly in
  every screenshot.

  The bar meter disagreeing with the caption — five bars, three filled, over
  `STEP 1 OF 4` — is the drawing's own inconsistency and is left alone.
  `Kati.Screens.ImportRecognised.steps/1` says so at length, and reproducing a
  board faithfully includes reproducing what it got wrong.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Import.Sample
  alias Kati.UI.ImportChrome

  test "the fixture and a real job build the same kicker" do
    assert Sample.recognised().step_label == ImportChrome.step_label(1, 4)
  end

  test "and it is the catalogue's, not a literal" do
    label = ImportChrome.step_label(1, 4)

    assert label =~ Kati.Locale.number(1)
    assert label =~ Kati.Locale.number(4)
  end

  test "and so do the other three lines the same function builds" do
    # Found by walking the flow in Persian, which is the only way to see this
    # class of defect: in English the fixed line and the broken one render
    # identically. `Job.read/2` hardcoded all four.
    Kati.Locale.put(:fa)

    pill = ImportChrome.action_label(2)
    shape = ImportChrome.shape_label(2, 9)
    subtitle = ImportChrome.subtitle_label("goodreads_library_export.csv", 3, 4)

    Kati.Locale.put(:en)

    refute pill =~ "Import 2",
           "the ink action pill was `Import #{2}`, in English, on every real file"

    refute shape =~ "ROWS", "the mono line was `2 ROWS · 9 COLUMNS`, in English"
    refute subtitle =~ "step 3 of 4"

    # And the file name stays Latin inside the Persian sentence, wrapped in an
    # isolate so bidi does not reorder its dots and underscores.
    assert subtitle =~ "goodreads_library_export.csv"
  end

  test "so a Persian reader gets Persian numerals" do
    # Restored inside the test rather than in `on_exit`: `Mob.State` is already
    # down by the time that runs, so the restore exits with `no process` and
    # takes the test with it. Same trap as `Kati.LibrarySegmentsTest`.
    Kati.Locale.put(:fa)

    persian = ImportChrome.step_label(1, 4)

    Kati.Locale.put(:en)

    assert persian =~ "۱",
           "the kicker is mono beside a meter — a Latin digit is exactly where it would show"

    refute persian =~ "STEP 1 OF 4"
  end
end
