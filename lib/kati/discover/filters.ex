defmodule Kati.Discover.Filters do
  use Gettext, backend: Kati.Gettext

  @moduledoc """
  Board 169's choice, and the TMDB request it becomes.

  ## What the board asks for, and what a device can answer

  Board 169 draws eleven controls. Its own note says where their numbers come
  from: *"Every count on this sheet comes from Discover's own sample, as every
  number on 11 does — said here so the build is not asked to infer a
  recommender from a chip."* That note is the whole reason this module can
  exist honestly, and it is what decided each control:

    * **Sort — Best match.** There is no recommender, and `/discover` has no
      `sort_by` about *this reader*. It ships as **Most popular**
      (`popularity.desc`), which is TMDB's own default ordering and says what
      it is. The word *match* is gone with the percentage it implied.
    * **Sort — Newest.** Real: `primary_release_date.desc` on film,
      `first_air_date.desc` on series.
    * **Sort — Leaving soonest.** Not built. `/discover` carries no leaving
      date and `/watch/providers` is a snapshot with no window — there is no
      field anywhere in TMDB that says when something leaves a service.
    * **Ranges — 90% and up / 80% and up.** The parameter exists
      (`vote_average.gte`) but it is a **crowd score out of ten**, not a fit
      against a history — so the percentages go and the buckets are stated in
      TMDB's own units. `Kati.Discover.Filters.rating_label/1` is the wording,
      and the sheet's section note says whose number it is.
    * **Ranges — Unscored.** Not built. It is the inverse of a number Kati
      does not have, and TMDB has no parameter for *no rating*.
    * **Filters — Film / Series.** Real, and they are the endpoint itself:
      `/discover/movie` or `/discover/tv`.
    * **Filters — Lumen+ / Orbit.** Not built, twice over. `with_watch_providers`
      needs numeric JustWatch ids, and `Kati.Media.Tmdb.providers/1` keeps only
      names. And the two names are not even Discover's own fixture — they are
      `Kati.Library.ShelfFiltersSample`'s, board 145's vocabulary.
    * **Filters — Only with news.** Not built. There is no people table and no
      follow list; `Kati.Screens.Discover`'s moduledoc records that absence as
      a decision rather than a gap.

  Eight of the board's chips carry a count badge. None is drawn here, and not
  as an omission: a per-chip count is one request per chip, and TMDB's
  `total_results` is a corpus size rather than a page. The footer prints that
  one figure, once, after an answer carries it — see `Kati.Screens.DiscoverFilters`.

  ## The vote floor

  `vote_average.desc` on its own returns films with a single ten-out-of-ten
  vote, which is a top-rated list nobody would recognise. `@vote_floor` is the
  companion `vote_count.gte` that makes the sort mean what it says, and it is
  applied to the rating buckets for the same reason. It is TMDB's own
  documented remedy, not Kati's invention.

  ## Why `params/3` takes the day

  `Newest` has to exclude what is not out yet, which needs today's date — and
  a function that reads the wall clock cannot be doctested. `Kati.ScreenDateTest`
  forbids `DateTime.utc_now/0` in a screen for the same reason. The caller
  passes `Kati.Time.today/0`; the doctests pass a fixed day.
  """

  @key "discover:filters"

  @sorts [:popular, :newest, :top_rated]
  @ratings [:r6, :r7, :r8]
  @kinds [:movie, :tv]

  # TMDB's own guidance for a `vote_average` sort or filter that is not
  # dominated by titles with a handful of votes.
  @vote_floor "200"

  @doc """
  Nothing narrowed, most popular first — the state the sheet opens in.

      iex> Kati.Discover.Filters.resting()
      %{kind: nil, sort: :popular, rating: nil}

  Not board 169's preselection (*Best match*, checked, with `90% and up` and
  `Film` lit). That is a drawing of the sheet in use, and `Kati.Library.ShelfFilters`
  made the same call for board 145: a sheet that opened already filtered hides
  part of the answer the first time somebody touches it.
  """
  @spec resting() :: map()
  def resting, do: %{kind: nil, sort: :popular, rating: nil}

  @doc "The three sort keys, in the sheet's order."
  @spec sorts() :: [atom()]
  def sorts, do: @sorts

  @doc "The three rating buckets, lowest first."
  @spec ratings() :: [atom()]
  def ratings, do: @ratings

  @doc "The two kinds, which are the two endpoints."
  @spec kinds() :: [atom()]
  def kinds, do: @kinds

  @doc "The choice this device has stored, falling back to `resting/0`."
  @spec current() :: map()
  def current do
    case Mob.State.get(@key) do
      %{sort: sort} = stored when sort in @sorts ->
        %{
          kind: sanitise(Map.get(stored, :kind), @kinds),
          sort: sort,
          rating: sanitise(Map.get(stored, :rating), @ratings)
        }

      _absent ->
        resting()
    end
  rescue
    # `Mob.State` is DETS and raises when its table is not open — a bare
    # `mix run`, a test that has not started the app. A view preference is not
    # worth a crash. `Kati.Library.ShelfFilters` carries the same pair.
    _error -> resting()
  catch
    :exit, _reason -> resting()
  end

  @doc "Store a choice. Answers it back, so a caller can pipe."
  @spec put(map()) :: map()
  def put(choice) do
    Mob.State.put(@key, choice)
    choice
  rescue
    _error -> choice
  catch
    :exit, _reason -> choice
  end

  @doc "Forget the choice, which is what *Reset* does."
  @spec clear() :: :ok
  def clear do
    Mob.State.put(@key, resting())
    :ok
  rescue
    _error -> :ok
  catch
    :exit, _reason -> :ok
  end

  @doc """
  Whether anything on the sheet is narrowing the feed.

      iex> Kati.Discover.Filters.narrowed?(Kati.Discover.Filters.resting())
      false

      iex> Kati.Discover.Filters.narrowed?(%{kind: :tv, sort: :popular, rating: nil})
      true
  """
  @spec narrowed?(map()) :: boolean()
  def narrowed?(choice), do: choice != resting()

  @doc """
  Which endpoint a choice asks: the kind it names, or film when it names none.

      iex> Kati.Discover.Filters.endpoint(%{kind: :tv, sort: :popular, rating: nil})
      :tv

      iex> Kati.Discover.Filters.endpoint(Kati.Discover.Filters.resting())
      :movie

  `/discover` is one kind per request, so *no kind chosen* has to resolve to
  one. Film, because that is the chip board 169 draws lit and the larger of the
  two corpora — and the sheet says which it is asking rather than implying it
  asked both.
  """
  @spec endpoint(map()) :: :movie | :tv
  def endpoint(%{kind: :tv}), do: :tv
  def endpoint(_film_or_none), do: :movie

  @doc """
  The choice as TMDB query parameters.

      iex> Kati.Discover.Filters.params(Kati.Discover.Filters.resting(), :movie, ~D[2026-09-08])
      [
        include_adult: "false",
        page: "1",
        sort_by: "popularity.desc",
        "primary_release_date.lte": "2026-09-08"
      ]

      iex> Kati.Discover.Filters.params(%{kind: :tv, sort: :newest, rating: nil}, :tv, ~D[2026-09-08])
      [
        include_adult: "false",
        page: "1",
        sort_by: "first_air_date.desc",
        "first_air_date.lte": "2026-09-08"
      ]

      iex> Kati.Discover.Filters.params(%{kind: nil, sort: :top_rated, rating: :r8}, :movie, ~D[2026-09-08])
      [
        include_adult: "false",
        page: "1",
        sort_by: "vote_average.desc",
        "primary_release_date.lte": "2026-09-08",
        "vote_count.gte": "200",
        "vote_average.gte": "8"
      ]

  `include_adult: "false"` is not a preference and is not on the sheet. Kati
  has no age gate, and a browse surface that can return pornography to a reader
  who asked for *most popular* is a defect rather than a setting.

  The date ceiling is on every request, not only on *Newest*: `popularity.desc`
  otherwise floats films that are announced and not out, which read as
  available and are not.
  """
  @spec params(map(), :movie | :tv, Date.t()) :: keyword()
  def params(choice, kind, today) do
    date_key = if kind == :movie, do: :"primary_release_date.lte", else: :"first_air_date.lte"

    [include_adult: "false", page: "1", sort_by: sort_by(Map.get(choice, :sort), kind)] ++
      [{date_key, Date.to_iso8601(today)}] ++
      vote_floor(Map.get(choice, :sort), Map.get(choice, :rating)) ++
      rating_param(Map.get(choice, :rating))
  end

  @doc """
  The `sort_by` a sort key means, on one endpoint.

      iex> Kati.Discover.Filters.sort_by(:newest, :movie)
      "primary_release_date.desc"

      iex> Kati.Discover.Filters.sort_by(:newest, :tv)
      "first_air_date.desc"

      iex> Kati.Discover.Filters.sort_by(:top_rated, :tv)
      "vote_average.desc"

  A sort Kati never stored falls back to the resting one rather than raising
  inside a request builder.
  """
  @spec sort_by(atom(), :movie | :tv) :: String.t()
  def sort_by(:newest, :movie), do: "primary_release_date.desc"
  def sort_by(:newest, :tv), do: "first_air_date.desc"
  def sort_by(:top_rated, _kind), do: "vote_average.desc"
  def sort_by(_popular, _kind), do: "popularity.desc"

  @doc """
  What a sort row says, and the line under it.

      iex> Kati.Discover.Filters.sort_label(:popular)
      {"Most popular", "TMDB's own ordering"}

      iex> Kati.Discover.Filters.sort_label(:top_rated)
      {"Highest rated", "200+ votes, so one perfect score cannot win"}

  ## Why the label has to stand twice

  It is drawn in two places and reads in both: as a row on board 169's sheet,
  and as the FIRST WORD of `Kati.Screens.Discover.asked_line/1`'s rail heading,
  whose template is `%{sort} %{noun}` over *films* or *series*. English gets
  that for free. Persian only gets it if each label is a superlative that can
  both stand alone and qualify a noun — `جدیدترین` is *Newest* on the sheet and
  *newest …* in the heading, and `محبوب‌ترین فیلم‌ها` is the same construction
  the heading's own catalogue entry already assumes.

  `pgettext/2` on all six strings, for the reason
  `Kati.Screens.ShelfFilters.sort_label/2` gives about its own sort keys: three
  of them are one or two words, and `TMDB's own ordering` opens on the same
  three characters as `Kati.Screens.DiscoverFilters.rating_note/0`'s sentence
  one card below it — which is exactly the pair a fuzzy `mix gettext.merge`
  reaches for. The context also puts a row and its line next to each other in
  the catalogue, which is how a translator needs to read them.

  The vote floor is INTERPOLATED rather than written into the line, so a
  Persian reader is told ۲۰۰ and not 200 — the same call `rating_note/0` makes
  for the same figure, and the reason `@vote_floor` is reached for here rather
  than a second `200` typed into a sentence.
  """
  @spec sort_label(atom()) :: {String.t(), String.t()}
  def sort_label(:newest) do
    {pgettext("a discover sort key", "Newest"),
     pgettext("a discover sort key's line", "Out already, most recent first")}
  end

  def sort_label(:top_rated) do
    {pgettext("a discover sort key", "Highest rated"),
     pgettext("a discover sort key's line", "%{n}+ votes, so one perfect score cannot win",
       n: Kati.Locale.number(@vote_floor)
     )}
  end

  def sort_label(_popular) do
    # `TMDB` stays Latin inside the Persian line. It is a service's name for
    # itself — `Kati.Services.Service` never translates one — and the catalogue
    # already writes it that way in ten other Persian strings. No `ltr/1`
    # around it either: it ends the phrase and carries no punctuation of its
    # own, so there is nothing for the bidi algorithm to move to the wrong edge.
    {pgettext("a discover sort key", "Most popular"),
     pgettext("a discover sort key's line", "TMDB's own ordering")}
  end

  @doc """
  What a rating bucket says. **Out of ten, and it says so.**

      iex> Kati.Discover.Filters.rating_label(:r8)
      "8.0 and up"

      iex> Kati.Discover.Filters.rating_label(:r6)
      "6.0 and up"

  Board 169 draws `90% and up`. A percentage is a claim about fit — how well
  this suits *you* — and the number underneath is nothing of the kind: it is
  everybody's average out of ten. So the units are TMDB's, and the sheet's
  section note names whose average it is.

  The figure goes through `Kati.Locale.number/1`, which converts the separator
  as well as the digits: Persian writes this as `۸٫۰` with U+066B, not `۸.۰`,
  and board 115 draws it that way. The bucket is a chip and a heading fragment,
  never a mono figure, so there is no `mono_face/1` question here —
  `Kati.Screens.DiscoverFilters.chip/3` sets no `font_family` at all.
  """
  @spec rating_label(atom()) :: String.t()
  def rating_label(:r8), do: bucket_label("8.0")
  def rating_label(:r7), do: bucket_label("7.0")
  def rating_label(_six), do: bucket_label("6.0")

  @doc """
  What a Kind chip says.

      iex> Kati.Discover.Filters.kind_label(:tv)
      "Series"

  Plain `gettext/1` and not `pgettext/2`, which is the opposite call from
  `sort_label/1`'s three rows: the app already names these two kinds in a
  dozen places — screen 07's meta line, the add-by-hand picker, the stats
  totals — and the catalogue has carried `Film` → `فیلم` and `Series` →
  `سریال` since long before board 169. A context here would mint a second
  Persian word for *film*, which is the drift the fold was for.
  """
  @spec kind_label(atom()) :: String.t()
  def kind_label(:tv), do: gettext("Series")
  def kind_label(_movie), do: gettext("Film")

  # ── The three toggles, each of which turns itself off when pressed twice ──

  @doc """
  Choose a sort. Unlike the other two this has no off state: something has to
  order the list.

      iex> Kati.Discover.Filters.with_sort(Kati.Discover.Filters.resting(), :newest)
      %{kind: nil, sort: :newest, rating: nil}
  """
  @spec with_sort(map(), atom()) :: map()
  def with_sort(choice, sort) when sort in @sorts, do: %{choice | sort: sort}
  def with_sort(choice, _unknown), do: choice

  @doc """
  Choose a kind, or clear it by choosing the one already lit.

      iex> Kati.Discover.Filters.with_kind(Kati.Discover.Filters.resting(), :tv)
      %{kind: :tv, sort: :popular, rating: nil}

      iex> Kati.Discover.Filters.with_kind(%{kind: :tv, sort: :popular, rating: nil}, :tv)
      %{kind: nil, sort: :popular, rating: nil}
  """
  @spec with_kind(map(), atom()) :: map()
  def with_kind(%{kind: kind} = choice, kind), do: %{choice | kind: nil}
  def with_kind(choice, kind) when kind in @kinds, do: %{choice | kind: kind}
  def with_kind(choice, _unknown), do: choice

  @doc """
  Choose a rating floor, or clear it by choosing the one already lit.

      iex> Kati.Discover.Filters.with_rating(Kati.Discover.Filters.resting(), :r7)
      %{kind: nil, sort: :popular, rating: :r7}

      iex> Kati.Discover.Filters.with_rating(%{kind: nil, sort: :popular, rating: :r7}, :r7)
      %{kind: nil, sort: :popular, rating: nil}
  """
  @spec with_rating(map(), atom()) :: map()
  def with_rating(%{rating: rating} = choice, rating), do: %{choice | rating: nil}
  def with_rating(choice, rating) when rating in @ratings, do: %{choice | rating: rating}
  def with_rating(choice, _unknown), do: choice

  # ── Private ──────────────────────────────────────────────────────────────

  defp sanitise(value, allowed), do: if(value in allowed, do: value, else: nil)

  # ONE msgid with the figure as a binding rather than three literals, for the
  # reason `Kati.Screens.ShelfFilters.rating_label/1` gives on board 145's own
  # buckets: `8.0 and up` and `7.0 and up` are one character apart, which is
  # the pair a fuzzy `mix gettext.merge` matches against each other the moment
  # one of them changes.
  #
  # Its OWN context, and deliberately not that board's `a rating bucket`. The
  # library's bucket is `%{n}★ and up` — stars out of five, the reader's own
  # rating — and this one is TMDB's crowd average out of ten with no star in
  # it. Two entries a character apart under one context is the same fuzzy trap
  # again, and a translator handed both needs to see which is which.
  defp bucket_label(figure),
    do: pgettext("a rating bucket, out of ten", "%{n} and up", n: Kati.Locale.number(figure))

  defp rating_param(:r8), do: [{:"vote_average.gte", "8"}]
  defp rating_param(:r7), do: [{:"vote_average.gte", "7"}]
  defp rating_param(:r6), do: [{:"vote_average.gte", "6"}]
  defp rating_param(_none), do: []

  # The floor belongs to any request whose ORDER or NARROWING is the average:
  # `vote_average.desc` without it is a list of one-vote tens, and
  # `vote_average.gte=8` without it is the same list filtered.
  defp vote_floor(:top_rated, _rating), do: [{:"vote_count.gte", @vote_floor}]
  defp vote_floor(_sort, nil), do: []
  defp vote_floor(_sort, _rating), do: [{:"vote_count.gte", @vote_floor}]
end
