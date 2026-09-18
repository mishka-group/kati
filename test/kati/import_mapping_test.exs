defmodule Kati.ImportMappingTest do
  @moduledoc """
  *Check the mapping* opens the mapping of the file it just counted.

  MOVIES-AND-TV.md #53. Screen 141 reads a Goodreads export — 418 rows, nine
  columns, seven matched, two skipped — and its summary row promised those
  nine behind a `chevron_right`. It pushed screen 37 bare, and screen 37 drew
  `trakt-backup.csv` and five columns of a film export. One chevron apart,
  every number on the page the reader had just left was contradicted by the
  page it opened.

  The same shape as #40's two Season 2s, and the same fix: the caller names
  its subject, and the sample module answers with it.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Import.Sample
  alias Kati.Screens.Import
  alias Kati.Screens.ImportRecognised

  doctest ImportRecognised, only: [source: 0]

  describe "the two jobs" do
    test "describe two different files, and say so" do
      assert Sample.job(:trakt).file == "trakt-backup.csv"
      assert Sample.job(:goodreads).file == "goodreads_library_export.csv"
    end

    test "and an unknown source falls back to the board screen 37 was drawn from" do
      assert Sample.job(:letterboxd) == Sample.job(:trakt)
      assert Sample.job() == Sample.job(:trakt)
    end
  end

  describe "the Goodreads job" do
    test "carries the nine columns screen 141 counted, in its order" do
      assert Enum.map(Sample.job(:goodreads).columns, & &1.column) ==
               Enum.map(Sample.recognised_columns(), & &1.column)
    end

    test "and gives each one the sampled value screen 37's board is about" do
      columns = Sample.job(:goodreads).columns

      assert Enum.all?(columns, &is_binary(&1.sample))
      assert Enum.find(columns, &(&1.column == "My Rating")).sample == "8"
    end

    test "keeping the notes 141 drew, so the conversion is not re-explained differently" do
      rating = Enum.find(Sample.job(:goodreads).columns, &(&1.column == "My Rating"))

      assert rating.note == "converts 10pt → 5★"
    end
  end

  describe "the tap" do
    test "names the file screen 141 is about" do
      socket = Mob.Socket.new(Kati.Screens.ImportRecognised)
      {:noreply, pushed} = ImportRecognised.handle_tap(:check_mapping, socket)

      assert {:push, Kati.Screens.Import, %{source: :goodreads}} =
               Map.get(pushed.__mob__, :nav_action)
    end

    test "so screen 37 draws that file, not the other one" do
      # The push carries `:path` and `:name` (see the tap above), and those are
      # what #53 is about. A `:source` with no path names no file at all, and
      # what settles #53 now is that NEITHER screen invents one: 37 opens on
      # its own empty job rather than on the other export's five columns.
      {:ok, socket} =
        Import.mount(%{source: :goodreads}, %{}, Mob.Socket.new(Kati.Screens.Import))

      words =
        socket.assigns |> Import.render() |> inspect(limit: :infinity, printable_limit: :infinity)

      refute words =~ "trakt-backup.csv"
      refute words =~ "goodreads_library_export.csv"
      refute words =~ "Bookshelves"
    end

    test "and a bare push draws no file at all" do
      # It drew `trakt-backup.csv` — five columns of somebody else's film
      # export under a plan promising 384 new records — and *Something else* on
      # screen 140 is a routed tap that lands here with exactly this push.
      {:ok, socket} = Import.mount(%{}, %{}, Mob.Socket.new(Kati.Screens.Import))

      words =
        socket.assigns |> Import.render() |> inspect(limit: :infinity, printable_limit: :infinity)

      refute words =~ "trakt-backup.csv"
      assert words =~ "No file chosen"
      refute Import.live?(Import.job_for(%{}))
    end
  end
end
