defmodule Kati.I18n.DigitsTest do
  @moduledoc """
  Numeral folding, asserted across the whole of each Unicode block.

  Spot-checking one or two digits is the failure mode here: the Persian and
  Arabic-Indic sets share four glyph shapes (٤ ٥ ٦ against ۴ ۵ ۶) and differ in
  the other six, so a folder tested only on ۱۲۳ can be wrong for half the digits
  and still look right. Every codepoint of both ranges is checked below, and the
  separators — which are the part a digits-only folder silently drops — get
  their own cases.
  """
  use ExUnit.Case, async: true

  doctest Kati.I18n.Digits

  alias Kati.Calendar.Shamsi
  alias Kati.I18n.Digits

  # Named by escape, because five of the six are either invisible or too close
  # to their ASCII counterparts to read in source.
  @persian_digits "۰۱۲۳۴۵۶۷۸۹"
  @arabic_digits "٠١٢٣٤٥٦٧٨٩"
  @percent "٪"
  @decimal "٫"
  @group "٬"

  describe "fold/1 — digits" do
    test "every Extended Arabic-Indic digit folds to its ASCII counterpart" do
      assert Digits.fold(@persian_digits) == "0123456789"

      for n <- 0..9 do
        assert Digits.fold(<<0x06F0 + n::utf8>>) == Integer.to_string(n)
      end
    end

    test "every Arabic-Indic digit folds too" do
      assert Digits.fold(@arabic_digits) == "0123456789"

      for n <- 0..9 do
        assert Digits.fold(<<0x0660 + n::utf8>>) == Integer.to_string(n)
      end
    end

    test "the two sets fold to the same ASCII, mixed inside one string" do
      # A paste from an Arabic source into a Persian field produces exactly this.
      mixed = "۱٢۳٤"
      assert Digits.fold(mixed) == "1234"
    end

    test "ASCII, letters and spacing pass through untouched" do
      for text <- ["1405", "August 12", "مرداد", "a-b_c/d", "", "  ", "‌"] do
        assert Digits.fold(text) == text
      end
    end

    test "folding is idempotent" do
      folded = Digits.fold("۱۴۰۵")
      assert Digits.fold(folded) == folded
    end
  end

  describe "fold/1 — separators" do
    test "the three separators fold to their ASCII counterparts" do
      assert Digits.fold(@percent) == "%"
      assert Digits.fold(@decimal) == "."
      assert Digits.fold(@group) == ","
    end

    test "a grouped Persian number folds whole" do
      # ۱٬۴۰۵ — one thousand four hundred and five, CLDR grouping.
      assert Digits.fold("۱٬۴۰۵") == "1,405"
    end

    test "a Persian decimal folds whole" do
      # ۸٫۹۹
      assert Digits.fold("۸٫۹۹") == "8.99"
    end

    test "a percentage folds whole" do
      # ۲۵٪
      assert Digits.fold("۲۵٪") == "25%"
    end

    test "the group separator is U+066C, not an ASCII comma" do
      # The design mock shows a comma; CLDR's fa grouping character is U+066C.
      # A folder that handled only the digits would leave it in place, and
      # Integer.parse would then answer {1, "٬405"} — a wrong number, silently.
      refute @group == ","
      assert Integer.parse("1" <> @group <> "405") == {1, @group <> "405"}
      assert Digits.parse_integer("۱٬۴۰۵") == {1405, ""}
    end
  end

  describe "to_persian/1" do
    test "renders ASCII digits in the Persian set" do
      assert Digits.to_persian("0123456789") == @persian_digits
      assert Digits.to_persian(1405) == "۱۴۰۵"
      assert Digits.to_persian(0) == "۰"
    end

    test "leaves separators and letters alone — formatting is Cldr.Number's job" do
      assert Digits.to_persian("8.99") == "۸.۹۹"
      assert Digits.to_persian("مرداد") == "مرداد"
    end
  end

  describe "round trips" do
    test "every integer survives rendering and folding back" do
      for n <- [0, 5, 9, 10, 42, 1405, 1_000_000, 987_654_321] do
        assert n |> Digits.to_persian() |> Digits.fold() |> String.to_integer() == n
      end
    end

    test "negative numbers keep their sign" do
      assert Digits.to_persian(-42) == "-۴۲"
      assert Digits.fold("-۴۲") == "-42"
      assert Digits.parse_integer("-۴۲") == {-42, ""}
    end

    test "a whole sentence survives a round trip through the digits only" do
      original = "25 مرداد 1405"
      rendered = Digits.to_persian(original)

      assert rendered == "۲۵ مرداد ۱۴۰۵"
      assert Digits.fold(rendered) == original
    end
  end

  describe "folds?/1" do
    test "true only when something would change" do
      assert Digits.folds?("۱")
      assert Digits.folds?("١")
      assert Digits.folds?(@group)
      refute Digits.folds?("1405")
      refute Digits.folds?("مرداد")
      refute Digits.folds?("")
    end
  end

  describe "parsing" do
    test "parse_integer accepts Persian, Arabic, grouped and plain forms" do
      for text <- [
            "1405",
            "1,405",
            "۱۴۰۵",
            "۱٬۴۰۵",
            "١٤٠٥"
          ] do
        assert Digits.parse_integer(text) == {1405, ""},
               "#{inspect(text)} should parse to 1405"
      end
    end

    test "parse_integer keeps the trailing remainder, like Integer.parse" do
      assert Digits.parse_integer("۲۵ مرداد") == {25, " مرداد"}
      assert Digits.parse_integer("مرداد") == :error
      assert Digits.parse_integer("") == :error
    end

    test "parse_float handles the Persian decimal separator" do
      assert Digits.parse_float("۸٫۹۹") == {8.99, ""}
      assert Digits.parse_float("8.99") == {8.99, ""}
      assert Digits.parse_float("۱٬۲۳۴٫۵") == {1234.5, ""}
    end

    test "the Persian and ASCII forms of one quantity parse identically" do
      # The acceptance criterion behind the quick-add parser: a Persian input
      # and its Latin equivalent must produce the same value, not merely both
      # produce something.
      pairs = [
        {"۱۱", "11"},
        {"۲۵", "25"},
        {"۱٬۴۰۵", "1,405"}
      ]

      for {persian, ascii} <- pairs do
        assert Digits.parse_integer(persian) == Digits.parse_integer(ascii)
        assert Digits.fold(persian) == Digits.fold(ascii)
      end
    end
  end

  describe "the boundary this module sits on" do
    test "Shamsi's digit helpers route through here rather than duplicating it" do
      # Two folders would drift, and the one on the calendar side is the one
      # that would silently stop handling separators.
      assert Shamsi.from_persian_digits("۱٬۴۰۵") == Digits.fold("۱٬۴۰۵")

      assert Shamsi.to_persian_digits("1405") == Digits.to_persian("1405")
    end

    test "folding never changes direction, only characters" do
      # A folded string is still displayed inside an RTL container. Nothing here
      # reverses anything: the folded text is character-for-character in the
      # same order as the input.
      input = "۲۵ مرداد"
      folded = Digits.fold(input)

      assert String.length(folded) == String.length(input)
      assert String.last(folded) == String.last(input)
      assert String.first(folded) == "2"
    end
  end
end
