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

  import Kati.Search, only: [long_enough?: 1, tier: 3]

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
        # Books had no group of their own: `titles_for/1` concatenated them
        # into `:titles`, so a book was drawn under the heading SCREEN, counted
        # by the Screen chip, and given a chevron that opened nothing —
        # `hit_tag/1` answers `nil` for anything that is not a film or a
        # series. MOVIES-AND-TV.md #61.
        books: books_for(query),
        calendar: calendar_for(query),
        note: note_for(query),
        recent: []
      }
    else
      %{query: query, idle?: true, titles: [], books: [], calendar: [], note: nil, recent: []}
    end
  end

  @doc """
  How many results each scope chip stands for, `All` first.

  Derived from the rows themselves rather than counted separately: a chip that
  says 4 over a list of 3 is the drawing lying about the store, which is the
  whole reason screen 88 specifies the chips as counts of the result set.
  """
  @spec chip_counts(map()) :: [{String.t(), non_neg_integer()}]
  def chip_counts(%{titles: titles, calendar: calendar, note: note} = results) do
    titles = titles || []
    books = Map.get(results, :books) || []
    calendar = calendar || []
    notes = if note, do: 1, else: 0

    [
      {"All", length(titles) + length(books) + length(calendar) + notes},
      {"Screen", length(titles)},
      {"Books", length(books)},
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
  # No `Enum.take/2`. Every group used to end `|> Enum.take(rows_per_group())`
  # BEFORE `chip_counts/1` counted it, so ten matching films rendered three,
  # the chip said `3`, and the other seven were unreachable from this screen —
  # `Kati.Search.rows_per_group/0`'s own doc promises a `See all N →` row and
  # `grep` finds no such row anywhere. MOVIES-AND-TV.md #62.
  #
  # Drawing all of them is the simpler true thing: the groups are inside a
  # `Scroll`, and a search that found ten answers with ten. `rows_per_group/0`
  # stays as what BOARD 19 draws, which is what `Kati.Screens.SearchSpec` is
  # about.
  # MOVIES-AND-TV.md #129: the tie-break board 88 renders is *tier, then
  # recency*, `Kati.Search.rank/1` implements exactly that, and nothing called
  # it — every group tied alphabetically instead, so a title you watched last
  # night sorted under one you looked up in March because A comes before S.
  # `rank/1` is the sort now, in all four groups, and the title is only the
  # last resort inside it.
  defp titles_for(query) do
    query
    |> cached_for(tracked_ids())
    |> Kati.Search.rank()
  end

  # Which cache rows this person actually KEEPS, keyed by the pair the durable
  # row references the cache by.
  #
  # One read, before the take, because a hit is not a door on its own: screens
  # 04 and 08 open a `Kati.Media.TrackedTitle`, and the cache holds rows for
  # every title anybody has ever looked up as well as the ones on the shelf. A
  # hit with no tracked row is still drawn — it matched — and carries no id, so
  # its card carries no tap rather than a tap onto somebody else's title.
  #
  # Read through `:shelf` and not `Ash.read!/1`, for the reason
  # `Kati.Screens.Film.film_record/1` gives: `:shelf` is where *keeps history,
  # hides from shelf* is enforced, so an id taken around it would open a title
  # the user archived.
  defp tracked_ids do
    [:movie, :tv, :anime]
    |> Enum.flat_map(fn kind ->
      Kati.Media.TrackedTitle
      |> Ash.Query.for_read(:shelf, %{kind: kind})
      |> Ash.read!()
    end)
    # The whole row, not just its id: `title_row/2` needs the id and the sort
    # needs `last_touched_at`, and reading the shelf twice for the two halves
    # of one row is how the two would drift.
    |> Map.new(&{{&1.source, &1.source_id}, &1})
  rescue
    _error -> %{}
  end

  # Each read rescues on its own, so an unreadable cache still answers with the
  # shelf and the other way round — one rescue around both would let either
  # failure empty the whole group.
  defp cached_for(query, tracked) do
    yours = yours_by_tracked_id()
    aliases = aliases_by_tracked_id()

    Kati.Media.CachedTitle
    |> Ash.read!()
    |> Enum.map(fn row ->
      mine = Map.get(tracked, {row.source, row.source_id})
      id = mine && mine.id

      {best_tier(
         query,
         Kati.Media.CachedTitle.names(row) ++ Map.get(aliases, id, []),
         [row.overview | Map.get(yours, id, [])]
       ), mine, row}
    end)
    |> Enum.reject(fn {tier, _mine, _row} -> is_nil(tier) end)
    |> Enum.map(fn {tier, mine, row} ->
      {tier, recency_of(mine, row), title_row(row, tracked)}
    end)
  rescue
    _error -> []
  end

  # MOVIES-AND-TV.md #114. `Kati.Search`'s Screen scope declares six fields and
  # screen 88 prints the list verbatim; this searched two of them. The other
  # four are all on the device and were simply never read — `title_original` is
  # a column of the same row, `Kati.Media.TitleAlias` is the table auto-detect
  # writes when you connect a name to a title, and `review` and `tags` are the
  # words the reader typed themselves on screen 24.
  #
  # Cast is the one the app cannot keep: nothing in `Kati.Media.CachedTitle`
  # holds a person, TMDB's credits are not fetched, and there is nowhere to put
  # them. So it comes off `@scopes` rather than staying as a promise, which is
  # the same call #74 made at scope level.
  #
  # The BEST tier across every name, because a tier is about how well the query
  # matched and an alt title matching exactly is an exact match. All of the
  # reader's own words are body, tier 4: finding a film because you wrote its
  # name in a review is right, and ranking it above the film itself is not.
  defp best_tier(query, names, bodies) do
    body = bodies |> Enum.reject(&is_nil/1) |> Enum.join(" ")

    # `[""]` when a cache row has no title at all: it can still match on the
    # reader's own words, at tier 4, and dropping it would lose the hit.
    if(names == [], do: [""], else: names)
    |> Enum.map(&tier(query, &1 || "", body))
    |> Enum.reject(&is_nil/1)
    |> Enum.min(fn -> nil end)
  end

  # Every review and tag list the reader has written, by the title it is about.
  # One read for the whole search rather than one per row.
  defp yours_by_tracked_id do
    Kati.Media.Watch
    |> Ash.read!()
    |> Enum.group_by(& &1.tracked_title_id, &[&1.review, &1.tags])
    |> Map.new(fn {id, pairs} -> {id, pairs |> List.flatten() |> Enum.reject(&is_nil/1)} end)
  rescue
    _error -> %{}
  end

  # The names auto-detect learned: `Kati.Media.TitleAlias.all/0` is keyed by the
  # heard name because that is what a session hands it, and this needs the
  # other direction.
  defp aliases_by_tracked_id do
    Kati.Media.TitleAlias.all()
    |> Enum.group_by(fn {_heard, id} -> id end, fn {heard, _id} -> heard end)
  rescue
    _error -> %{}
  end

  # When this title last mattered to the reader: the shelf's own
  # `last_touched_at` for something they keep, and the cache's `fetched_at` for
  # something they merely looked up. A cache row nobody has touched is not
  # newer than a shelf row somebody watched yesterday, which is what the shelf
  # being read first says.
  defp recency_of(nil, cached), do: Map.get(cached, :fetched_at)

  defp recency_of(tracked, cached),
    do: Map.get(tracked, :last_touched_at) || recency_of(nil, cached)

  # The author is the secondary field, where a cached title's is its overview.
  # Searching `Karvel` and finding nothing is the half of this a reader notices
  # first, and a book is the one kind here whose second line is a person.
  defp books_for(query) do
    written = notes_by_book_id()

    Kati.Books.Book
    |> Ash.read!()
    |> Enum.map(
      &{tier(
         query,
         &1.title || "",
         join_body([&1.author, &1.isbn | Map.get(written, &1.id, [])])
       ), &1}
    )
    |> Enum.reject(fn {tier, _row} -> is_nil(tier) end)
    |> Enum.map(fn {tier, row} -> {tier, Map.get(row, :updated_at), book_row(row)} end)
    |> Kati.Search.rank()
  rescue
    _error -> []
  end

  # Every note and quote, by the book it is about. The Books scope has always
  # listed *your notes* and *your quotes* and searched neither — the Notes group
  # draws the note itself, which is a different answer to a different question:
  # *which book is that in?* is what this makes findable.
  defp notes_by_book_id do
    Kati.Books.Note
    |> Ash.read!()
    |> Enum.group_by(& &1.book_id, & &1.body)
  rescue
    _error -> %{}
  end

  # One body string out of several fields, blanks dropped. Joined with a space
  # so a query cannot match across the seam between two of them.
  defp join_body(parts) do
    parts
    |> Enum.reject(&(is_nil(&1) or &1 == ""))
    |> Enum.join(" ")
  end

  defp book_row(row) do
    %{
      title: row.title,
      sub: kind_label(:book) <> book_suffix(row),
      seed: row.cover_seed,
      # Named, and deliberately not yet a door — see
      # `Kati.Screens.Search.hit_tag/1`. `Kati.Screens.BookDetail.load/1` calls
      # `book/0`, which discards the push's params, so a book hit has nowhere
      # to go that is about this book. The id is carried anyway because it is
      # true and because the day 66 reads its params is the day this becomes
      # one line.
      kind: :book,
      id: row.id
    }
  end

  # The author when there is one, because that is what tells two books with the
  # same title apart — the job the episode count does for a series.
  defp book_suffix(%{author: author}) when is_binary(author) and author != "",
    do: " · " <> author

  defp book_suffix(_row), do: ""

  defp title_row(row, tracked) do
    %{
      title: row.title,
      # Which kind it is, in the words screen 19 already draws — the second
      # criterion is that each result says which it is.
      sub: row.kind |> kind_label() |> then(&(&1 <> status_suffix(row))),
      seed: row.poster_path,
      # Which of the two screens the chevron opens, and the row it opens them
      # on. `Kati.Screens.Library.shaped/3` collapses the same way: a film is
      # its own screen and everything else is the series screen.
      kind: if(row.kind == :movie, do: :film, else: :series),
      id: tracked |> Map.get({row.source, row.source_id}) |> then(&(&1 && &1.id))
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
    # `location` is the field #74 named at the end: the Calendar scope has always
    # listed it and the search has never read it, so *Barbican* found nothing
    # though it is written on four events. It is body rather than a name — an
    # event is not called by where it is — and joins `description` there.
    |> Enum.map(
      &{tier(query, &1.summary || "", [&1.description, &1.location] |> join_body()), &1}
    )
    |> Enum.reject(fn {tier, _row} -> is_nil(tier) end)
    # `dtstart_utc`, which is the board's own word for an event's recency, and
    # the one field of these four that a reader can see on the row.
    |> Enum.map(fn {tier, row} -> {tier, row.dtstart_utc, event_row(row)} end)
    |> Kati.Search.rank()
  rescue
    _error -> []
  end

  defp event_row(row) do
    %{
      # The handle, not a rendering — `Kati.Calendars.Today.row/2` says it in
      # as many words: a row that cannot name its own event is a row a screen
      # can draw and cannot open. This function held the whole
      # `%Kati.Calendars.Event{}` and dropped the one field screen 31 reads.
      id: row.id,
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
    # MOVIES-AND-TV.md #114: a review you wrote about a film was not findable
    # anywhere, though the Notes group and the Screen scope both said it was.
    # A review IS a note — the same paragraph in the reader's own words about
    # one thing on their shelf — so it is one of these rather than a group of
    # its own, and `note_eyebrow/1` already draws the date and what it is about.
    (book_notes() ++ review_notes())
    |> Enum.map(&{tier(query, &1.body || "", &1.body || ""), &1})
    |> Enum.reject(fn {tier, _row} -> is_nil(tier) end)
    # The tie-break board 88 renders, here too (#129): two notes at the same
    # tier are ordered newest first, not alphabetically by their own paragraph.
    |> Enum.map(fn {tier, row} -> {tier, Map.get(row, :inserted_at), row} end)
    |> Kati.Search.rank()
    |> List.first()
    |> note_card(query)
  rescue
    _error -> nil
  end

  defp book_notes do
    Kati.Books.Note
    |> Ash.Query.load(:book)
    |> Ash.read!()
  rescue
    _error -> []
  end

  # Every review with words in it, shaped the way `note_card/2` and
  # `note_eyebrow/1` read a note. `watched_at` is when it was written as far as
  # a reader is concerned, and the title it is about comes off the cache the
  # tracked row references.
  defp review_notes do
    cached =
      Kati.Media.CachedTitle
      |> Ash.read!()
      |> Map.new(&{{&1.source, &1.source_id}, &1})

    tracked =
      Kati.Media.TrackedTitle
      |> Ash.read!()
      |> Map.new(&{&1.id, Map.get(cached, {&1.source, &1.source_id})})

    Kati.Media.Watch
    |> Ash.read!()
    |> Enum.filter(&(is_binary(&1.review) and String.trim(&1.review) != ""))
    |> Enum.map(fn watch ->
      %{
        body: watch.review,
        inserted_at: watch.watched_at || watch.inserted_at,
        about: Map.get(tracked, watch.tracked_title_id)
      }
    end)
  rescue
    _error -> []
  end

  defp note_card(nil, _query), do: nil

  defp note_card(note, query) do
    body = note.body || ""

    case Kati.Search.locate(body, query) do
      {at, len} ->
        %{
          eyebrow: note_eyebrow(note),
          lead: body |> binary_part(0, at) |> String.trim_leading(),
          match: binary_part(body, at, len),
          tail: binary_part(body, at + len, byte_size(body) - at - len),
          inline_words: 6
        }

      # The note matched — `tier/3` said so, which is why this row is here at
      # all — and the words cannot be pointed at in the raw body. `می‌رود`
      # found by typing `می رود` is the shape of it: the two are one word once
      # normalised and no substring of the body is that word with a space in
      # it. So the card is drawn whole, unhighlighted, rather than dropped:
      # a result you can read is worth more than an emphasis you cannot have,
      # and dropping it is what the old code did by accident.
      :nomatch ->
        %{eyebrow: note_eyebrow(note), lead: "", match: "", tail: body, inline_words: 6}
    end
  end

  @doc """
  `NOTE · 6 AUG · THE LONG HOLLOW` — the three-part eyebrow board 19 draws.

  It was the bare word `NOTE`, so a note hit said nothing about WHOSE note it
  was or when it was written, and the reader was left with a paragraph and no
  way to place it. MOVIES-AND-TV.md #64. Both missing parts are on the row:
  `inserted_at` is when it was written and `:book` is what it is about.

  Each part is dropped rather than invented when it is absent — a note whose
  book has been deleted is `NOTE · 6 AUG`, and one with neither is the bare
  word it was.

      iex> Kati.Search.Query.note_eyebrow(%{inserted_at: ~U[2026-08-06 09:00:00Z], book: %{title: "The Long Hollow"}})
      "NOTE · 6 AUG · THE LONG HOLLOW"

      iex> Kati.Search.Query.note_eyebrow(%{inserted_at: ~U[2026-08-06 09:00:00Z], book: nil})
      "NOTE · 6 AUG"

      iex> Kati.Search.Query.note_eyebrow(%{})
      "NOTE"
  """
  @spec note_eyebrow(map()) :: String.t()
  def note_eyebrow(note) do
    # `:about` is a review's subject and `:book` is a book note's — the same
    # slot, named for what it is on each row (#114).
    subject = Map.get(note, :about) || Map.get(note, :book)

    ["NOTE", note_date(Map.get(note, :inserted_at)), note_book(subject)]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" · ")
  end

  defp note_date(%DateTime{} = at),
    do: "#{at.day} #{at.month |> Kati.Time.month_name() |> String.upcase() |> String.slice(0, 3)}"

  defp note_date(_absent), do: nil

  defp note_book(%{title: title}) when is_binary(title) and title != "",
    do: String.upcase(title)

  defp note_book(_absent), do: nil
end
