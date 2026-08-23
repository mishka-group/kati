defmodule Kati.SearchTest do
  @moduledoc """
  The search contract screen 88 draws.

  That board calls itself *a contract the build reads, not a caption*, so the
  assertions here are against the contract rather than against the picture: the
  fixed group order, the four tiers, the two-or-one minimum, and the Persian
  folding table row by row.
  """
  use ExUnit.Case, async: true

  alias Kati.Search

  describe "group order" do
    test "is fixed, and Notes is last" do
      # A user learns where to look; relevance-sorted groups move the target
      # every keystroke.
      assert Enum.map(Search.scopes(), &elem(&1, 0)) ==
               [:screen, :books, :music, :calendar, :meals, :money, :notes]
    end

    test "the chip row puts All in front of the seven" do
      assert Search.chip_labels() ==
               ["All", "Screen", "Books", "Music", "Calendar", "Meals", "Money", "Notes"]
    end
  end

  describe "the fields each scope searches" do
    test "Calendar excludes invitee names by name" do
      # Searching your calendar should not turn into searching your contacts.
      fields = Search.fields(:calendar)

      assert "event title" in fields
      assert "location" in fields
      assert Enum.any?(fields, &(&1 =~ "never invitee names"))
    end

    test "every scope names at least one field" do
      for {scope, _label, _fields} <- Search.scopes() do
        assert Search.fields(scope) != []
      end
    end
  end

  describe "the minimum" do
    test "is two characters in Latin" do
      refute Search.long_enough?("h")
      assert Search.long_enough?("ho")
    end

    test "is one where one character is a word" do
      # Persian, Arabic, Chinese, Japanese — measured on the QUERY, because
      # somebody reading Kati in English can still type a Persian title.
      assert Search.minimum("ک") == 1
      assert Search.long_enough?("ک")
      assert Search.long_enough?("本")
      assert Search.minimum("hollow") == 2
    end

    test "whitespace does not count towards it" do
      refute Search.long_enough?(" h ")
    end
  end

  describe "Persian normalisation" do
    test "typing the Arabic yeh finds the Persian one" do
      # Screen 88's own example: ي U+064A → ی U+06CC.
      assert Search.normalise("ياد") == Search.normalise("یاد")
    end

    test "the Arabic kaf folds to the Persian one" do
      assert Search.normalise("كتاب") == Search.normalise("کتاب")
    end

    test "a zero-width non-joiner is folded away" do
      # `می‌رود` and `میرود` are one word.
      assert Search.normalise("می‌رود") == Search.normalise("میرود")
    end

    test "harakat are stripped rather than compared" do
      # Optional in writing and almost never typed, so an indexed word carrying
      # them would be unreachable.
      assert Search.normalise("كِتاب") == Search.normalise("کتاب")
    end

    test "both digit sets fold to ASCII" do
      assert Search.normalise("٤") == "4"
      assert Search.normalise("۴") == "4"
    end

    test "case and runs of whitespace fold too" do
      assert Search.normalise("  The   Long  Hollow ") == "the long hollow"
    end

    test "the table the board prints is this module's own" do
      # Read from `Kati.Search` rather than typed into the screen, so the board
      # and the behaviour cannot drift.
      rows = Search.normalisation_table()

      assert length(rows) == 5
      assert {"ي", "U+064A", "ی", "U+06CC"} in rows
    end
  end

  describe "the four tiers" do
    test "each one is what its example says" do
      assert Search.tier("hollow", "Hollow") == 1
      assert Search.tier("hollow", "Hollow Season") == 2
      assert Search.tier("hollow", "The Long Hollow") == 3
      assert Search.tier("hollow", "Ashfall", "a note mentioning hollow") == 4
    end

    test "no match anywhere is nil, not a fifth tier" do
      assert Search.tier("vellichor", "Ashfall", "nothing about it") == nil
    end

    test "an empty query matches nothing rather than everything" do
      assert Search.tier("", "Hollow") == nil
      assert Search.tier("   ", "Hollow") == nil
    end

    test "a title match beats a body match however exact the body is" do
      # Tier 4 is weaker than 1-3 by construction: a query found in a note is a
      # weaker match than the same query found in a title.
      assert Search.tier("hollow", "The Long Hollow", "hollow") == 3
    end

    test "matching is done on the normalised forms, both sides" do
      assert Search.tier("كتاب", "کتاب") == 1
    end
  end

  describe "ranking" do
    test "orders by tier first" do
      ranked =
        Search.rank([
          {3, ~D[2026-08-16], "substring"},
          {1, ~D[2020-01-01], "exact"},
          {2, ~D[2026-08-16], "prefix"}
        ])

      assert ranked == ["exact", "prefix", "substring"]
    end

    test "ties break by recency, newest first" do
      ranked =
        Search.rank([
          {2, ~D[2024-01-01], "older"},
          {2, ~D[2026-08-16], "newer"}
        ])

      assert ranked == ["newer", "older"]
    end

    test "something with no date sorts last, not first" do
      # An undated thing is not the newest thing.
      ranked = Search.rank([{2, nil, "undated"}, {2, ~D[2020-01-01], "old"}])

      assert ranked == ["old", "undated"]
    end
  end

  describe "the two numbers the field's calm rests on" do
    test "debounce is 180 ms and a group shows three rows" do
      # Six keystrokes collapse into one fire. Every fire costs seven counted
      # queries — one per scope — so an undebounced field would run forty-two
      # for the word "hollow".
      assert Search.debounce_ms() == 180
      assert Search.rows_per_group() == 3
      assert Search.recent_kept() == 8
    end
  end
end
