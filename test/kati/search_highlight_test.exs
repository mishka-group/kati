defmodule Kati.SearchHighlightTest do
  @moduledoc """
  The words screen 19 puts in bold are the words that matched.

  The card was built like this:

      case :binary.match(normalise(body), normalise(query)) do
        {at, len} -> binary_part(body, at, len)

  Offsets out of the NORMALISED string, sliced out of the RAW one. They agree
  only while normalisation happens to preserve byte lengths, which it does for
  plain lowercase ASCII with single spaces and for nothing else: it strips
  ZWNJ and harakat, folds two-byte Persian digits to one-byte ASCII, collapses
  whitespace runs, and trims.

  Two failures, and the second is the worse one. The card highlighted the
  wrong characters — an off-by-a-few that reads as a bug in the search rather
  than in the drawing. And when normalisation shortened the body enough that
  `at + len` ran off the end, `binary_part/3` raised, `notes_for/1`'s rescue
  caught it, and the whole Notes group disappeared for the query that matched
  it best.

  `Kati.Search.locate/2` searches in raw coordinates instead, using
  `normalise/1` as its oracle rather than reimplementing the folding rules —
  so there is no second copy to drift, and a rule added to `normalise/1` is
  honoured here the day it lands.
  """

  use ExUnit.Case, async: true

  doctest Kati.Search, only: [locate: 2]
  doctest Kati.Screens.Search, only: [chip_rows: 1]

  alias Kati.Search

  describe "the located slice" do
    test "is the query's own words, in plain text" do
      body = "The estuary scenes land differently"

      assert {at, len} = Search.locate(body, "estuary scenes")
      assert binary_part(body, at, len) == "estuary scenes"
    end

    test "survives a doubled space" do
      body = "The  estuary  scenes land differently"

      assert {at, len} = Search.locate(body, "estuary scenes")
      assert binary_part(body, at, len) == "estuary  scenes"
    end

    test "survives a leading newline, which used to shift every offset" do
      body = "\n\n  the estuary"

      assert {at, len} = Search.locate(body, "estuary")
      assert binary_part(body, at, len) == "estuary"
    end

    test "survives a ZWNJ earlier in the body" do
      body = "می‌رود به خانه"

      assert {at, len} = Search.locate(body, "خانه")
      assert binary_part(body, at, len) == "خانه"
    end

    test "survives harakat earlier in the body" do
      body = "كِتَاب و film"

      assert {at, len} = Search.locate(body, "film")
      assert binary_part(body, at, len) == "film"
    end

    test "survives Persian digits earlier in the body, which fold two bytes to one" do
      body = "فصل ۲ قسمت ۶ — Hollow"

      assert {at, len} = Search.locate(body, "hollow")
      assert binary_part(body, at, len) == "Hollow"
    end

    test "matches case-insensitively and gives back the body's own casing" do
      body = "The Long Hollow"

      assert {at, len} = Search.locate(body, "long hollow")
      assert binary_part(body, at, len) == "Long Hollow"
    end

    test "starts on a word, not on the space before it" do
      body = "a    estuary"

      assert {at, _len} = Search.locate(body, "estuary")
      assert binary_part(body, at, 1) == "e"
    end

    test "answers :nomatch rather than guessing" do
      assert Search.locate("The Long Hollow", "estuary") == :nomatch
      assert Search.locate("", "estuary") == :nomatch
      assert Search.locate("The Long Hollow", "") == :nomatch
    end

    test "never returns a slice that runs off the end" do
      # The failure mode that took the Notes group out: the raw body is longer
      # than its normalised form by six bytes, so normalised offsets near the
      # end were past the raw end and `binary_part/3` raised.
      body = "می‌رود می‌رود می‌رود estuary"

      assert {at, len} = Search.locate(body, "estuary")
      assert at + len <= byte_size(body)
      assert binary_part(body, at, len) == "estuary"
    end
  end

  describe "every located slice normalises back to the query" do
    for {body, query} <- [
          {"The  Long  Hollow", "long hollow"},
          {"\n the estuary", "estuary"},
          {"می‌رود به خانه", "خانه"},
          {"فصل ۲ قسمت ۶", "2"},
          {"كِتَاب", "کتاب"}
        ] do
      test "#{inspect(body)} against #{inspect(query)}" do
        body = unquote(body)
        query = unquote(query)

        assert {at, len} = Search.locate(body, query)
        assert Search.normalise(binary_part(body, at, len)) == Search.normalise(query)
      end
    end
  end

  describe "the clear disc" do
    test "empties the field as well as the results, which it did not" do
      # `Kati.ScreenTapSweepTest` books this tag inert
      # with its own reason — it reaches 19 with an empty field, where clearing
      # is correctly a no-op — so nothing in the suite had ever pressed it over
      # a query. Pressed on the device it was not inert; it was HALF right:
      # the counts went to zero and the typed word stayed in the box, so the
      # page read as "no results for hollow" over a query it had just thrown
      # away.
      #
      # The bump is what empties the field. The bridge remembers the last epoch
      # it saw per field and ignores a `value` for one it has already drawn —
      # `K-46` in `native/LEDGER.md`, and screen 06 has carried this counter
      # since it was found there.
      socket =
        Kati.Screens.Search
        |> Mob.Socket.new()
        |> Mob.Socket.assign(:query, "hollow")
        |> Mob.Socket.assign(:query_epoch, 1)
        |> Mob.Socket.assign(:results, Kati.Search.Query.run("hollow"))

      {:noreply, cleared} = Kati.Screens.Search.handle_info({:tap, :clear}, socket)

      assert cleared.assigns.query == ""
      assert cleared.assigns.query_epoch > socket.assigns.query_epoch
    end

    test "and the field is handed the counter rather than reading it itself" do
      # `field/3` is what a board calls too — 91, 141 and 88 all draw it — so
      # the counter is an argument. A board passing none draws epoch 0, which
      # is a picture of a field and never a replacement of one.
      drawn = inspect(Kati.Screens.Search.field("hollow", true, 4), limit: :infinity)

      assert drawn =~ "value_epoch: 4"
      assert inspect(Kati.Screens.Search.field("hollow"), limit: :infinity) =~ "value_epoch: 0"
    end
  end
end
