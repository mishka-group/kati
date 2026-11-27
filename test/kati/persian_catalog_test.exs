defmodule Kati.PersianCatalogTest do
  @moduledoc """
  The Persian catalog is complete: no fuzzy line, no empty answer.

  `mix gettext.extract --merge` writes a new msgid with `msgstr ""` and marks a
  reworded one *fuzzy* with a guess at its translation. Both fall back to the
  English msgid at runtime, and neither fails a build — so the phone shows one
  English line in the middle of a Persian page, which is exactly how the Goals
  sheet's `watched this year` and the whole Habits empty state were found on the
  device. This test is the check that was missing.

  The header block (`msgid ""`) is the only one allowed to be empty: it holds
  the catalog metadata, not a message.
  """

  use ExUnit.Case, async: true

  @catalog Path.expand("../../priv/gettext/fa/LC_MESSAGES/default.po", __DIR__)

  test "no message in the Persian catalog is fuzzy" do
    fuzzy =
      @catalog
      |> File.read!()
      |> blocks()
      |> Enum.filter(&(&1 =~ ~r/^#,.*\bfuzzy\b/m))
      |> Enum.map(&msgid/1)

    assert fuzzy == [], "fuzzy (English until fixed): #{inspect(fuzzy)}"
  end

  test "every message in the Persian catalog has an answer" do
    empty =
      @catalog
      |> File.read!()
      |> blocks()
      |> Enum.reject(&(&1 =~ ~r/^msgid ""$/m))
      |> Enum.filter(fn block -> block =~ ~r/^msgstr(\[\d+\])? ""$/m end)
      |> Enum.map(&msgid/1)

    assert empty == [], "no Persian translation: #{inspect(empty)}"
  end

  test "the plural messages answer both forms" do
    half =
      @catalog
      |> File.read!()
      |> blocks()
      |> Enum.filter(&(&1 =~ ~r/^msgid_plural /m))
      |> Enum.reject(&(&1 =~ ~r/^msgstr\[1\] ".+"$/m))
      |> Enum.map(&msgid/1)

    assert half == [], "plural with no second form: #{inspect(half)}"
  end

  defp blocks(text), do: String.split(text, "\n\n")
  defp msgid(block), do: block |> String.split("\n") |> Enum.find(&(&1 =~ ~r/^msgid /))
end
