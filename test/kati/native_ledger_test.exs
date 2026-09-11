defmodule Kati.NativeLedgerTest do
  @moduledoc """
  Keeps the drift ledger honest.

  The vendored native shell is generated once and never updated by any Mob
  tooling, so Kati's edits to it are permanent merge cost. These tests make an
  undocumented edit fail the build rather than be discovered during an upgrade,
  months later, by someone reading a 3,600-line Kotlin diff.
  """
  use ExUnit.Case, async: true

  @root Path.expand("../..", __DIR__)
  @ledger Path.join(@root, "native/LEDGER.md")
  @tracked Path.join(@root, "native/TRACKED")
  @upstream Path.join(@root, "native/UPSTREAM")

  defp tracked_files do
    @tracked
    |> File.read!()
    |> String.split("\n", trim: true)
    |> Enum.reject(&(String.starts_with?(String.trim(&1), "#") or String.trim(&1) == ""))
  end

  defp fences_in(path) do
    body = File.read!(path)

    begins =
      Regex.scan(~r/KATI-BEGIN\(([^)]+)\)/, body)
      |> Enum.map(&List.last/1)
      |> Enum.map(&String.trim/1)

    ends =
      Regex.scan(~r/KATI-END\(([^)]+)\)/, body)
      |> Enum.map(&List.last/1)
      |> Enum.map(&String.trim/1)

    {begins, ends}
  end

  defp all_fences do
    tracked_files()
    |> Enum.map(&Path.join(@root, &1))
    |> Enum.filter(&File.exists?/1)
    |> Enum.flat_map(fn p -> p |> fences_in() |> elem(0) end)
    |> Enum.uniq()
  end

  test "every tracked file exists and has a captured baseline" do
    pin = Regex.run(~r/^mob_new=(.+)$/m, File.read!(@upstream)) |> List.last()

    for f <- tracked_files() do
      assert File.exists?(Path.join(@root, f)), "tracked but missing from the tree: #{f}"

      assert File.exists?(Path.join([@root, "native/baseline", pin, f])),
             "no baseline for #{f} — a three-way merge is impossible without one"
    end
  end

  test "baseline files match the checksums recorded in native/UPSTREAM" do
    pin = Regex.run(~r/^mob_new=(.+)$/m, File.read!(@upstream)) |> List.last()

    checksums =
      ~r/^([0-9a-f]{64})\s\s(.+)$/m
      |> Regex.scan(File.read!(@upstream))
      |> Enum.map(fn [_, sum, file] -> {file, sum} end)

    assert length(checksums) > 0, "native/UPSTREAM records no checksums"

    for {file, expected} <- checksums do
      path = Path.join([@root, "native/baseline", pin, file])

      actual =
        :crypto.hash(:sha256, File.read!(path)) |> Base.encode16(case: :lower)

      assert actual == expected,
             "baseline #{file} was modified — every three-way merge against it is now wrong"
    end
  end

  test "every fence is balanced" do
    for f <- tracked_files(), path = Path.join(@root, f), File.exists?(path) do
      {begins, ends} = fences_in(path)

      assert Enum.sort(begins) == Enum.sort(ends),
             "unbalanced fences in #{f}\n  begin: #{inspect(begins)}\n  end:   #{inspect(ends)}"
    end
  end

  test "every fence is documented in the ledger" do
    ledger = File.read!(@ledger)

    for label <- all_fences() do
      assert ledger =~ "`#{label}`",
             "fence #{inspect(label)} is not in native/LEDGER.md — an undocumented edit to " <>
               "vendored code is exactly what makes a Mob upgrade unmergeable"
    end
  end

  test "every ledger row corresponds to a real fence" do
    # Only the ACTIVE table. A retired row is a row whose fence is gone on
    # purpose — that is what retiring one means — so scanning the whole file
    # made the first retirement fail this test with its own remedy ("move its
    # row to Retired") already carried out. The Retired table is asserted
    # separately below, on the opposite condition.
    documented =
      ~r/^\| `([^`]+)` \|/m
      |> Regex.scan(active_section())
      |> Enum.map(&List.last/1)

    live = all_fences()

    for label <- documented do
      assert label in live,
             "LEDGER.md documents #{inspect(label)} but no such fence exists — if the patch was " <>
               "removed, move its row to Retired"
    end
  end

  test "no retired row still has a fence in the tree" do
    # The mirror of the test above. A row moved to Retired while its fence is
    # still in the file is the more dangerous half of the same mistake: the
    # ledger then says an edit is gone from vendored code that is in fact
    # still there, and the next merge takes upstream's version over it without
    # anyone being asked.
    retired =
      ~r/^\| `([^`]+)` \|/m
      |> Regex.scan(retired_section())
      |> Enum.map(&List.last/1)

    live = all_fences()

    for label <- retired do
      refute label in live,
             "LEDGER.md retires #{inspect(label)}, but the fence is still in the tree"
    end
  end

  defp active_section do
    [_, body] = String.split(File.read!(@ledger), "## Active patches", parts: 2)
    body |> String.split("## Retired patches", parts: 2) |> hd()
  end

  defp retired_section do
    [_, body] = String.split(File.read!(@ledger), "## Retired patches", parts: 2)
    body |> String.split("## Files with no Kati edits", parts: 2) |> hd()
  end

  test "fence labels name the ticket and the mob_new version they were written against" do
    for f <- tracked_files(), path = Path.join(@root, f), File.exists?(path) do
      body = File.read!(path)

      for [full, label] <- Regex.scan(~r/KATI-BEGIN\(([^)]+)\)/, body) do
        assert label =~ ~r/^K-\d+ [a-z0-9-]+$/,
               "malformed fence label #{inspect(label)} in #{f} — expected \"K-nn slug\""

        idx = :binary.match(body, full) |> elem(0)
        rest = binary_part(body, idx, min(200, byte_size(body) - idx))

        assert rest =~ "mob_new=",
               "fence #{inspect(label)} in #{f} does not record the mob_new version"
      end
    end
  end
end
