defmodule Kati.Search.Query do
  @moduledoc """
  The half of search that reads the store.

  `Kati.Search` is the specification — scopes, tiers, the minimum query, the
  folding — and it is used by five screens, four of which are reference sheets
  that draw the spec rather than run it. This is deliberately a **separate
  module** for that reason: `Kati.ScreenEmptyDatabaseTest` derives which
  screens reach the database from the compiled import table, so a query
  executor living in `Kati.Search` makes every screen that mentions the spec
  a database reader, including boards 86, 88, 89 and 91 which read nothing.

  Found by putting it there first and watching three reference sheets get
  pulled into the empty-database migration.
  """

  import Kati.Search, only: [long_enough?: 1, normalise: 1, rows_per_group: 0, tier: 3]

  @doc """
  Run one query against the store and answer what screen 19 draws.

  `%{query:, titles:, calendar:, note:, recent:}` — the same shape
  `Kati.Screens.Search.Sample.results/0` held, built from `Kati.Media`,
  `Kati.Calendars` and `Kati.Books` instead of from a drawing.

  ## Why the filtering is in Elixir and not in the query

  `tier/3` is the ranking this module already specifies — exact, prefix,
  substring, body — and it is case- and diacritic-folded through
  `normalise/1`. SQLite's `LIKE` is none of those things, so a `WHERE` clause
  that pre-filtered would answer a different question from the one that then
  ranks the answers, and the two would disagree on exactly the rows a Persian
  or accented title makes interesting.

  The read is therefore the whole of each table and the narrowing is here.
  That is honest at Kati's scale — a personal library, a personal calendar —
  and it is the reason `rows_per_group/0` exists rather than a LIMIT.

  ## Nothing typed, and nothing found, are different answers

  Both carry empty groups, and `:idle?` is what tells them apart — a query
  under `minimum/1` is the screen waiting, a long-enough one that matched
  nothing is the screen having looked. Screen 19 draws two different things
  for those.

  The groups are **always lists**, never `nil`. The render maps over them, so
  a `nil` group is a crash rather than a state — which is what the first
  version of this function shipped to `Kati.ScreenRenderSweepTest` and was
  told about immediately.
  """
  @spec run(String.t()) :: map()
  def run(query) when is_binary(query) do
    if long_enough?(query) do
      %{
        query: query,
        idle?: false,
        titles: titles_for(query),
        calendar: calendar_for(query),
        note: note_for(query),
        recent: []
      }
    else
      %{query: query, idle?: true, titles: [], calendar: [], note: nil, recent: []}
    end
  end

  @doc """
  How many results each scope chip stands for, `All` first.

  Derived from the rows themselves rather than counted separately: a chip that
  says 4 over a list of 3 is the drawing lying about the store, which is the
  whole reason screen 88 specifies the chips as counts of the result set.
  """
  @spec chip_counts(map()) :: [{String.t(), non_neg_integer()}]
  def chip_counts(%{titles: titles, calendar: calendar, note: note}) do
    titles = titles || []
    calendar = calendar || []
    notes = if note, do: 1, else: 0

    [
      {"All", length(titles) + length(calendar) + notes},
      {"Screen", length(titles)},
      {"Calendar", length(calendar)},
      {"Notes", notes}
    ]
  end

  # Everything in the media cache AND on the book shelf whose title matches,
  # best tier first, then alphabetically so an equal tier is not ordered by
  # insertion accident.
  #
  # Books were unfindable until now, and silently: `kind_label/1` has had a
  # `:book` arm since this module was written and nothing ever reached it,
  # because `Kati.Books.Book` is its own resource and never lands in
  # `Kati.Media.CachedTitle`. So a title on your shelf, and the author who wrote
  # it, matched nothing, and only a note body did — which is what screen 20's
  # search disc opens onto.
  #
  # Merged BEFORE the take rather than concatenated after it: two lists each cut
  # to `rows_per_group/0` and then joined would put a substring-tier book above
  # an exact-tier film.
  defp titles_for(query) do
    (cached_for(query) ++ books_for(query))
    |> Enum.sort_by(fn {tier, title, _row} -> {tier, title} end)
    |> Enum.take(rows_per_group())
    |> Enum.map(fn {_tier, _title, row} -> row end)
  end

  # Each read rescues on its own, so an unreadable cache still answers with the
  # shelf and the other way round — one rescue around both would let either
  # failure empty the whole group.
  defp cached_for(query) do
    Kati.Media.CachedTitle
    |> Ash.read!()
    |> Enum.map(&{tier(query, &1.title || "", &1.overview || ""), &1.title, &1})
    |> Enum.reject(fn {tier, _title, _row} -> is_nil(tier) end)
    |> Enum.map(fn {tier, title, row} -> {tier, title, title_row(row)} end)
  rescue
    _error -> []
  end

  # The author is the secondary field, where a cached title's is its overview.
  # Searching `Karvel` and finding nothing is the half of this a reader notices
  # first, and a book is the one kind here whose second line is a person.
  defp books_for(query) do
    Kati.Books.Book
    |> Ash.read!()
    |> Enum.map(&{tier(query, &1.title || "", &1.author || ""), &1.title, &1})
    |> Enum.reject(fn {tier, _title, _row} -> is_nil(tier) end)
    |> Enum.map(fn {tier, title, row} -> {tier, title, book_row(row)} end)
  rescue
    _error -> []
  end

  defp book_row(row) do
    %{
      title: row.title,
      sub: kind_label(:book) <> book_suffix(row),
      seed: row.cover_seed
    }
  end

  # The author when there is one, because that is what tells two books with the
  # same title apart — the job the episode count does for a series.
  defp book_suffix(%{author: author}) when is_binary(author) and author != "",
    do: " · " <> author

  defp book_suffix(_row), do: ""

  defp title_row(row) do
    %{
      title: row.title,
      # Which kind it is, in the words screen 19 already draws — the second
      # criterion is that each result says which it is.
      sub: row.kind |> kind_label() |> then(&(&1 <> status_suffix(row))),
      seed: row.poster_path
    }
  end

  defp kind_label(:movie), do: "Film"
  defp kind_label(:tv), do: "Series"
  defp kind_label(:book), do: "Book"
  defp kind_label(:album), do: "Album"
  defp kind_label(other), do: other |> to_string() |> String.capitalize()

  defp status_suffix(%{episode_count: n}) when is_integer(n) and n > 0,
    do: " · #{n} episodes"

  defp status_suffix(_row), do: ""

  defp calendar_for(query) do
    Kati.Calendars.Event
    |> Ash.read!()
    |> Enum.map(&{tier(query, &1.summary || "", &1.description || ""), &1})
    |> Enum.reject(fn {tier, _row} -> is_nil(tier) end)
    |> Enum.sort_by(fn {tier, row} -> {tier, row.summary} end)
    |> Enum.take(rows_per_group())
    |> Enum.map(fn {_tier, row} -> event_row(row) end)
  rescue
    _error -> []
  end

  defp event_row(row) do
    %{
      date: day_label(row.dtstart_utc),
      title: row.summary,
      time: time_label(row.dtstart_utc)
    }
  end

  defp day_label(nil), do: ""

  defp day_label(at),
    do: at |> DateTime.to_date() |> Calendar.strftime("%d %b") |> String.upcase()

  defp time_label(nil), do: ""
  defp time_label(at), do: Calendar.strftime(at, "%H:%M")

  # One note, because screen 19 draws one card and not a list. The best match
  # wins, and the card is built around where the query actually fell in the
  # body — a highlight that pointed at the start of every note would be
  # decoration rather than a result.
  defp note_for(query) do
    Kati.Books.Note
    |> Ash.read!()
    |> Enum.map(&{tier(query, &1.body || "", &1.body || ""), &1})
    |> Enum.reject(fn {tier, _row} -> is_nil(tier) end)
    |> Enum.sort_by(fn {tier, row} -> {tier, row.body} end)
    |> List.first()
    |> note_card(query)
  rescue
    _error -> nil
  end

  defp note_card(nil, _query), do: nil

  defp note_card({_tier, note}, query) do
    body = note.body || ""

    case :binary.match(normalise(body), normalise(query)) do
      {at, len} ->
        %{
          eyebrow: "NOTE",
          lead: body |> binary_part(0, at) |> String.trim_leading(),
          match: binary_part(body, at, len),
          tail: binary_part(body, at + len, byte_size(body) - at - len),
          inline_words: 6
        }

      :nomatch ->
        nil
    end
  end
end
