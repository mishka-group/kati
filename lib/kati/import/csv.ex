defmodule Kati.Import.Csv do
  @moduledoc """
  A CSV reader, because the exports people actually have are CSV files.

  Written rather than pulled in, and the reason is the same one every other
  dependency decision in this app answers to: the parsers on hex are excellent
  and they are all NIF-backed or streaming-server shaped, and this runs on a
  phone inside one BEAM that ships every byte it uses. What an import needs is
  the RFC 4180 core — a header row, quoted fields, doubled quotes inside them,
  and newlines that may appear inside a quoted field — and that is what is
  here. Anything a spreadsheet writes, this reads.

  ## What it does not do

  No streaming. An export from Trakt, Letterboxd, IMDb or Goodreads is a few
  hundred kilobytes and the phone has already loaded it to hand it over; a
  streaming reader would be machinery for a file size nobody has.

  No type inference. Every field comes out a string and stays one until
  `Kati.Import.Mapping` says what it is. A reader that guessed would decide
  that a title of `2026` is a number, and titles like that exist.
  """

  @doc """
  Read a whole file: `{:ok, {headers, rows}}`, or why not.

  Rows are lists of strings, padded and trimmed to the header's width, so a
  short line is a row with blanks rather than a crash and a long one loses only
  the columns nothing named.

      iex> Kati.Import.Csv.read("a,b\\n1,2\\n")
      {:ok, {["a", "b"], [["1", "2"]]}}

      iex> Kati.Import.Csv.read(~s(t\\n"say ""hi\"""\\n))
      {:ok, {["t"], [[~s(say "hi")]]}}

      iex> Kati.Import.Csv.read("")
      {:error, :empty}
  """
  @spec read(String.t()) :: {:ok, {[String.t()], [[String.t()]]}} | {:error, atom()}
  def read(text) when is_binary(text) do
    case Kati.Import.Csv.rows(text) do
      [] -> {:error, :empty}
      [[""]] -> {:error, :empty}
      [headers | rows] -> {:ok, {headers, Enum.map(rows, &fit(&1, length(headers)))}}
    end
  end

  @doc """
  Every row of the text, quoting respected.

  A single pass over the graphemes rather than `String.split/2`, because a
  newline inside a quoted field is a newline in a value and splitting on it
  first is unrecoverable — which is exactly how a review with a paragraph break
  in it takes an import down.

      iex> Kati.Import.Csv.rows(~s(a,"one\\ntwo",c))
      [["a", "one\\ntwo", "c"]]
  """
  @spec rows(String.t()) :: [[String.t()]]
  def rows(text) do
    text
    |> String.replace("\r\n", "\n")
    |> String.replace("\r", "\n")
    |> String.graphemes()
    |> Enum.reduce({[], [], "", false, false}, &step/2)
    |> close()
  end

  # `{rows, fields_so_far_in_this_row, current_field, inside_quotes?,
  # just_left_a_quote?}`.
  #
  # That last flag is the whole of RFC 4180's escape rule and it cannot be done
  # without one: a `""` inside a quoted field is one quote, and a reduce cannot
  # look ahead to see the second. So the first `"` leaves the quoted state and
  # remembers that it did, and a `"` arriving immediately after that is not an
  # opening quote — it is the escape, and it emits one character and goes back
  # in. Written as a toggle first, which silently deleted every escaped quote
  # in the file.
  defp step("\"", {rows, fields, current, false, true}),
    do: {rows, fields, current <> "\"", true, false}

  defp step("\"", {rows, fields, current, false, false}), do: {rows, fields, current, true, false}

  defp step("\"", {rows, fields, current, true, _after?}),
    do: {rows, fields, current, false, true}

  defp step(",", {rows, fields, current, false, _after?}),
    do: {rows, fields ++ [current], "", false, false}

  defp step("\n", {rows, fields, current, false, _after?}),
    do: {rows ++ [fields ++ [current]], [], "", false, false}

  defp step(char, {rows, fields, current, quoted?, _after?}),
    do: {rows, fields, current <> char, quoted?, false}

  # A file that ends without a newline still has a last row, and a file that
  # ends WITH one does not have an empty one after it.
  defp close({rows, [], "", _quoted?, _after?}), do: rows
  defp close({rows, fields, current, _quoted?, _after?}), do: rows ++ [fields ++ [current]]

  defp fit(row, width) do
    row
    |> Enum.map(&String.trim/1)
    |> Enum.take(width)
    |> then(&(&1 ++ List.duplicate("", max(width - length(&1), 0))))
  end
end
