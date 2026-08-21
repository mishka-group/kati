defmodule Kati.I18n.Digits do
  @moduledoc """
  Numeral folding at the **input** boundary.

  Output needs nothing: `fa`'s default number system is `arabext`
  (`"number_systems": {"default": "arabext", "native": "arabext"}`), so
  `Cldr.Number.to_string/2` already emits ۰–۹ for a Persian locale, and
  `Kati.Cldr` precompiles `{:latn, :arabext}` so it does so without the runtime
  transliteration path. Input is the asymmetric half: a user typing `۲۵` hands
  every downstream consumer — `Integer.parse/1`, a date parser, an FTS5 MATCH —
  a string none of them recognise as a number.

  ## What folds

    * **U+06F0–U+06F9** — Extended Arabic-Indic, the Persian set. This is what
      an Iranian keyboard produces and what `fa` renders.
    * **U+0660–U+0669** — Arabic-Indic. Kati does not ship `ar`, but the two
      sets are visually near-identical for four of ten digits and a user
      pasting from an Arabic source will mix them inside one string.
    * **U+066A ٪ percent**, **U+066B ٫ decimal separator**, **U+066C ٬ group
      separator** — folded to `%`, `.` and `,`.

  The group separator is the one worth naming: CLDR's Persian grouping
  character is **U+066C**, not the ASCII comma a mock tends to show. A folder
  that handles only the digits turns `۱٬۲۳۴` into `1٬234`, and
  `Integer.parse/1` then answers `{1, "٬234"}` — a wrong number, silently,
  rather than an error. `parse_integer/1` exists so no caller has to remember
  to strip grouping itself.

  ## What does not fold

  Direction. A folded string is still displayed inside an RTL container and
  still renders its digits through `arabext`; folding is about what the parser
  sees, never about what the screen shows. Nothing here reverses anything.
  """

  # Ranges are module attributes so the guards below read as their Unicode
  # blocks rather than as magic numbers.
  @persian 0x06F0..0x06F9
  @arabic 0x0660..0x0669

  @persian_zero 0x06F0
  @arabic_zero 0x0660

  @percent 0x066A
  @decimal 0x066B
  @group 0x066C

  @doc """
  Fold Persian and Arabic-Indic digits and separators down to ASCII.

  Everything else — letters, spaces, ZWNJ, ASCII — passes through unchanged, so
  this is safe to run over a whole quick-add line rather than over a substring
  someone has already decided is numeric.

      iex> Kati.I18n.Digits.fold("۲۵ مرداد")
      "25 مرداد"

  """
  @spec fold(String.t()) :: String.t()
  def fold(text) when is_binary(text) do
    for <<cp::utf8 <- text>>, into: "", do: fold_codepoint(cp)
  end

  defp fold_codepoint(cp) when cp in @persian, do: <<?0 + cp - @persian_zero>>
  defp fold_codepoint(cp) when cp in @arabic, do: <<?0 + cp - @arabic_zero>>
  defp fold_codepoint(@percent), do: "%"
  defp fold_codepoint(@decimal), do: "."
  defp fold_codepoint(@group), do: ","
  defp fold_codepoint(cp), do: <<cp::utf8>>

  @doc """
  Render ASCII digits as Persian (Extended Arabic-Indic) ones.

  The inverse of `fold/1` for the digit range only: separators are left alone,
  because which separator a number wants is a *formatting* decision that belongs
  to `Cldr.Number`, not to a character map.
  """
  @spec to_persian(integer() | String.t()) :: String.t()
  def to_persian(n) when is_integer(n), do: n |> Integer.to_string() |> to_persian()

  def to_persian(text) when is_binary(text) do
    for <<cp::utf8 <- text>>, into: "", do: persian_codepoint(cp)
  end

  defp persian_codepoint(cp) when cp in ?0..?9, do: <<@persian_zero + cp - ?0::utf8>>
  defp persian_codepoint(cp), do: <<cp::utf8>>

  @doc "True when the string contains at least one non-ASCII digit or separator."
  @spec folds?(String.t()) :: boolean()
  def folds?(text) when is_binary(text), do: fold(text) != text

  @doc """
  Parse an integer from text that may carry Persian digits and grouping.

  Folds first, then removes grouping — both the ASCII comma and the U+066C that
  folded into one — so `"۱٬۴۰۵"`, `"1,405"` and `"1405"` all answer `{1405, ""}`.
  """
  @spec parse_integer(String.t()) :: {integer(), String.t()} | :error
  def parse_integer(text) when is_binary(text) do
    text |> fold() |> String.replace(",", "") |> Integer.parse()
  end

  @doc """
  Parse a float from text that may carry Persian digits, grouping and U+066B.

  `"۸٫۹۹"` answers `{8.99, ""}`. Grouping is removed before parsing for the same
  reason as `parse_integer/1`.
  """
  @spec parse_float(String.t()) :: {float(), String.t()} | :error
  def parse_float(text) when is_binary(text) do
    text |> fold() |> String.replace(",", "") |> Float.parse()
  end
end
