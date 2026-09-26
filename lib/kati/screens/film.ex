defmodule Kati.Screens.Film do
  @moduledoc """
  Screen 08 — a film, pushed under Library.

  Shares screen 04's shape — 330pt artwork, chrome floating at 60pt, the title
  on the gradient — and diverges where a film differs from a series: a watched
  pill above the title instead of a season card, a rating, and a note.

  The note sits on cream. The design's own caption says that is deliberate:
  it is "the one place the palette warms up", the same treatment the hero card
  gets on Home, and it marks the user's own words as different from metadata.

  ## Where the data comes from

  `Kati.Media`, through `film/0`. This screen is the durable half of that
  domain drawn as a page: `Kati.Media.Watch`'s own moduledoc names it twice —
  *"screen 08 does not [know the hour]"* is why `watched_on` is a date beside
  `watched_at`, and the `[:tracked_title_id, :watched_at]` index is annotated
  *"screen 08's 'seen 2 times'"*. The rating, the note, the watch date and the
  count are all rows the user made, so they are read rather than frozen.

  Three reads, never one per row: the film shelf (`Kati.Media.TrackedTitle`'s
  own `:shelf` action, which is where *keeps history, hides from shelf* is
  enforced), the one cache row it names, and that title's watches. The cache is
  reached by `{source, source_id}` because that is what a tracked row holds —
  a value pair, not a foreign key — so an evicted poster cannot take the user's
  memory of the film down with it.

  **Which film.** The push names it: `Kati.Screens.Library`, What fits, Up
  next, Activity and a list all push `%{id: tracked_id}`. A bare push — the
  gallery's door — draws the top of the film shelf, which `:shelf` decides.

  With no film on the shelf the page is `none/2`'s sentence and a way back,
  and an id the shelf no longer holds is `gone/2`'s. No reader path draws a
  value the reader did not make: board 08's own film is a test fixture
  (`Kati.Test.ShowBoards.film/0`) and never ships.

  ## Where to watch, and the meta line

  **The `Where to watch` card** is `Kati.Media.CachedTitle.providers` through
  `Kati.Screens.SeriesMeta.where_rows/1`, the same band screen 14 draws. TMDB
  says where and never how much, so a row carries no price. A film nobody has
  looked up has no rows and the band is not drawn — or, while the reader has
  set up no services, board 96's prompt stands in its place.

  **The meta line** is `2025 · 1H 52M · DRAMA` out of `first_release_year`,
  `runtime_minutes` and `genres`, each left out when the provider gave none.

  Three smaller ones are derived rather than dropped, and each states what it is
  derived from: `seen` counts watches against the user's own `rewatch_number`
  the way `Kati.Screens.Activity` does, the stars are `rating` on the ten-point
  scale halved, and the watched pill is the latest watch's date.
  """
  use Mob.Screen
  use Gettext, backend: Kati.Gettext
  import Mob.Sigil

  require Ash.Query

  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaPill
  alias Kati.Components.MishkaSeparator
  alias Kati.Components.MishkaThemeIcon
  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Theme.Palette
  alias Kati.UI

  # The row of affordances under the card stack. Labels, not data — the same
  # class of literal as screen 03's `Up next` tile — so they live in the screen
  # beside the markup that draws them rather than being read back out of the
  # fixture, which would be a lie about where a real render's copy came from.
  # The three pills under the rating card. Each carries the tag it sends, or
  # `nil` for the two that have nowhere to go yet — they were ALL `nil` and
  # none of them said so: `action/2` drew a `<Box>` with no `on_tap`, so the
  # row was three pictures of buttons. A control that sends nothing is
  # invisible to `Kati.ScreenTapSweepTest`, which walks the tags a tree draws,
  # so nothing in the suite could report them either. Found by pressing *Log
  # rewatch* on a Pixel 9a and watching the page not move.
  #
  # All three go somewhere now, and the two that did not were each waiting on
  # something that has since landed.
  #
  # `Schedule` wanted a date sheet this app did not have. It has one: screen 18
  # takes a sentence and writes a calendar event, so *Schedule* opens it with
  # the film's own name already typed. One field, and the reader adds the when.
  #
  # `Share` wanted the Android share intent, and the note here said it was a
  # fence nobody had written. `Mob.Share.text/2` is Mob's own — `ACTION_SEND`
  # through `Intent.createChooser` — and has been there all along.
  #
  # Board 334 put **Add to list** in the first slot and moved *Log rewatch* out
  # of the row into the ink button it always deserved: both 181's empty card and
  # 182's sheet promise *"open a film, book or album and tap Add to list"*, and
  # until 7 September no film page had one. The `:log_watch` tap is unchanged —
  # `menu/1` and `rating_card/1` still carry it, and `action_label/3` still
  # answers *Log a watch* for a film nobody has seen.
  #
  # A function and no longer an `@actions` module attribute, for
  # `Kati.Screens.BookDetail.secondary/0`'s reason: `gettext/1` inside an
  # attribute is evaluated at COMPILE time, so all three labels would freeze in
  # whichever locale the compiler happened to be in and a Persian reader would
  # get whatever `mix compile` was set to. Read once per `shaped/3`, which is
  # once per arrival at the screen.
  #
  # *Schedule* takes a context rather than the bare msgid. `Kati.Screens.
  # Calendar` already holds one — the NOUN, the list of appointments, **برنامه**
  # — and `Kati.Screens.MedicationDetail` holds a third under a context of its
  # own. This one is the VERB: pressing it schedules a watch, and Persian does
  # not say the two with one word. One word, three jobs, three entries.
  defp action_row do
    [
      {"bookmarks", gettext("Add to list"), :add_to_list},
      {"event", pgettext("film action pill", "Schedule"), :schedule_watch},
      {"ios_share", gettext("Share"), :share_film}
    ]
  end

  @doc """
  What the first pill says, which depends on whether you have seen it.

  It read **Log rewatch** on a film whose own card said `SEEN never` — the
  label was a constant. A rewatch is a second watch; there is no such thing
  until there has been a first.

      iex> Kati.Screens.Film.action_label("Log rewatch", :log_watch, 0)
      "Log a watch"

      iex> Kati.Screens.Film.action_label("Log rewatch", :log_watch, 2)
      "Log rewatch"

      iex> Kati.Screens.Film.action_label("Schedule", nil, 0)
      "Schedule"

  The third clause hands back the label it was given. That one is already in
  the reader's language when it came off `action_row/0`, and is the drawing's
  own Latin when it came off board 08's test fixture — a lookup table mapping
  its English back to a msgid here would be this screen translating a
  drawing's literals.
  """
  @spec action_label(String.t(), atom() | nil, non_neg_integer()) :: String.t()
  def action_label(_drawn, :log_watch, seen) when is_integer(seen) and seen > 0,
    do: gettext("Log rewatch")

  def action_label(_drawn, :log_watch, _never), do: gettext("Log a watch")
  def action_label(drawn, _other, _seen), do: drawn

  # `use Mob.Screen` and not `Kati.Screens.Root`, so this screen's own `mount/3`
  # takes the push's params directly where a pushed screen reads them off
  # `assigns.params`. `Map.get/2` and not a pattern match on the key, so a bare
  # push — the gallery's, every sweep's — still takes the top-of-shelf branch.
  #
  # `Kati.Screens.Resume.watch/0`, which `Kati.Screens.Pushed`'s macro calls
  # and a hand-rolled screen has to call itself: it is what tells the page
  # underneath to re-read however this one is left, the system back gesture
  # included. Screen 19 listed a film removed from here until it did.
  # `:id` is the push's own, kept for `handle_info({:kati, :resumed, …})`.
  def mount(params, _session, socket) do
    Mob.Theme.set(Kati.Theme.current())
    # Resolves the stored locale into THIS process. `Gettext.put_locale/2`
    # snapshots into the calling process exactly as `Mob.Theme.set/1` does,
    # and a screen is its own process — see `Kati.Locale.activate/0`.
    Kati.Locale.activate()

    Kati.Screens.Resume.watch()
    id = Map.get(params || %{}, :id)

    {:ok,
     socket
     |> Mob.Socket.assign(:film, film(id))
     |> Mob.Socket.assign(:id, id)
     # `"Library"` stays an English literal and is not wrapped in `gettext/1`:
     # it is the catalogue KEY, not the drawn word. `Kati.Screens.Pushed.
     # back_label/2` translates whatever it is handed at runtime — the pusher's
     # `%{back: …}` or this default — against `back_vocabulary/0`, which is
     # where the msgid for every back pill in the app is declared. Handing it
     # the Persian would be handing it a string the catalogue has no entry for.
     |> Mob.Socket.assign(:back, Kati.Screens.Pushed.back_label(params, "Library"))
     |> Mob.Socket.assign(:menu?, false)
     |> Mob.Socket.assign(:confirm_remove?, false)
     |> Mob.Socket.assign(:remove_error, nil)}
  end

  @doc """
  The film this screen draws: the user's, or `empty_film/0`.

  The gate is the whole screen rather than each card, for the reason
  `Kati.Screens.Series` gives for not moving half of itself: a page whose title
  is a real film and whose note is somebody else's evening reads as entirely
  real. Either every value is this user's or there are none.

  `id` names the shelf row the caller meant. Without one — the gallery's door,
  and every arrival before there was anything to name — it is the top of the
  film shelf, which is what this screen has always drawn.

  An id the shelf no longer holds answers `empty_film/0` marked `gone?: true`,
  which `render/1` draws as `gone/2`'s sentence rather than as the frame.
  """
  @spec film(String.t() | nil) :: map()
  def film(id \\ nil) do
    case tracked_film(id) do
      nil when is_binary(id) -> Map.put(empty_film(), :gone?, true)
      nil -> empty_film()
      film -> film
    end
  end

  @doc """
  The page with no film on it.

  `shaped/3`'s keys, all of them carrying nothing, marked `none?: true` so
  `render/1` draws `none/2`'s sentence — *No films in your library yet* —
  rather than an empty frame with five hollow stars and a `SEEN` over nothing.
  The same move `Kati.Screens.Series.empty_series/0` makes for screen 04. A
  push that named a row which has gone gets this map marked `gone?: true` — see
  `film/1` — and `gone/2`'s page.

  Empty strings and not `nil` wherever the value reaches a `Text`: the
  typesetting helpers take a run and ask what script it is in, so a missing one
  has no clause and a nil arrives on a device as the word `nil`. `note_date`,
  `note` and `seed` stay nil because the real path already answers nil for them
  and the render already has the clause.

  `actions` is `[]`, and that is the point rather than an omission: every row on
  it acts on a film — log a watch, rate it, share it, add it to a list — and
  there is no film here to act on. Drawing them would be four controls that
  cannot do anything, which is the state `@inert_taps` exists to keep out of the
  app. The eyebrows around them stay: **WHERE TO WATCH** is the frame's own word
  for a band, the way board 248 keeps **EPISODES** over an empty list.
  """
  @spec empty_film() :: map()
  def empty_film do
    %{
      tracked_id: nil,
      none?: true,
      title: "",
      seed: nil,
      meta: "",
      year: nil,
      watched: "",
      stars: 0,
      seen: "",
      seen_count: 0,
      note_date: nil,
      note: nil,
      where: [],
      where_line: "",
      private?: false,
      anime?: false,
      media_kind: :movie,
      actions: []
    }
  end

  @doc """
  The user's own film, shaped for the markup, or `nil` when there is not one.

  `nil` is the ordinary answer on a fresh install and the one `film/1` reads as
  `empty_film/0`. A database that cannot be read at all answers `nil` too:
  `Ash.read!` on a device mid-migration raises, and a screen that dies is
  strictly worse than an empty one — the same degradation
  `Kati.Screens.Library.shelf/0` and `Kati.Calendars.Today` make.

  An id that names no shelf row answers `nil` as well, rather than the top of
  the shelf. That is `Kati.Screens.BookDetail.shelved_book/1`'s rule and its
  reason: a row archived or deleted under the user is not the same fact as an
  empty shelf, and substituting a different film is the swap the argument exists
  to prevent.
  """
  @spec tracked_film(String.t() | nil) :: map() | nil
  def tracked_film(id \\ nil) do
    case film_record(id) do
      nil -> nil
      tracked -> shaped(tracked, cached_for(tracked), watches_of(tracked))
    end
  rescue
    _ -> nil
  end

  # The film the caller named, or — given no id — the top of the shelf, which is
  # what every arrival at this screen used to get and what a bare push still
  # gets. Read THROUGH `:shelf` rather than with `Ash.get/2` for the reason
  # `newest_film/0` states below: `:shelf` is where *keeps history, hides from
  # shelf* is enforced, so an id fetched around it would open a title the user
  # archived.
  defp film_record(nil), do: newest_film()

  # ACROSS the Screen kinds, not `:movie` alone. `:anime` is a kind something
  # writes now, and a film marked as anime keeps its
  # `:movie` cache row and opens this screen — `Kati.Media.Anime.film?/2` is
  # what routes it. Read against `:movie` only, this answered `nil` for exactly
  # that title and the page fell back to the DRAWING: the reader tapped their
  # own film and got somebody else's. Found on the Pixel_9a, one tap after
  # marking one as anime.
  #
  # Still through `:shelf`, which is where *keeps history, hides from shelf* is
  # enforced, and `Kati.Screens.Series.series_record/1` reads its two kinds the
  # same way for the same reason.
  defp film_record(title_id) do
    [:movie, :tv, :anime]
    |> Enum.flat_map(fn kind ->
      TrackedTitle
      |> Ash.Query.for_read(:shelf, %{kind: kind})
      |> Ash.read!()
    end)
    |> Enum.find(&(&1.id == title_id))
  end

  # The top of the film shelf. `:shelf` rather than a filter written out here:
  # it is the action `Kati.Media.TrackedTitle` names for "screens 03, 20 and 21"
  # and it is where archived rows are excluded, so a shelf that forgot the flag
  # would show a title the user hid. `limit(1)` because this screen draws one
  # film and the sort is the action's own.
  defp newest_film do
    TrackedTitle
    |> Ash.Query.for_read(:shelf, %{kind: :movie})
    |> Ash.Query.limit(1)
    |> Ash.read!()
    |> List.first()
  end

  # One read, by the VALUE PAIR the durable half references the cache by. A
  # missing row is the evicted case and is ordinary — see `shaped/3`.
  defp cached_for(%TrackedTitle{source: source, source_id: source_id}) do
    CachedTitle
    |> Ash.Query.filter(source == ^source and source_id == ^source_id)
    |> Ash.read_one!()
  end

  defp watches_of(%TrackedTitle{id: id}) do
    Watch
    |> Ash.Query.for_read(:for_title, %{tracked_title_id: id})
    |> Ash.read!()
  end

  @doc """
  One tracked film in the shape the markup reads, whatever is missing.

  `cached` may be `nil` and `watches` may be empty; both are ordinary states and
  neither is allowed to invent a value.

    * `title` is the cache's, and `Untitled` when the cache row has gone. The
      same answer `Kati.Screens.Activity` gives, and for its reason: the memory
      survived the wipe and the poster did not, so the page says so rather than
      handing the user somebody else's film. (Screen 03 drops such a row instead,
      because there a nameless tile among nine named ones says nothing; here it
      is the whole page and the user's own rating and note are on it.)
    * `seed` is `poster_path`, which for a seeded sample title is the design's
      own picsum seed and for a real one is a provider path
      `Kati.Design.Images.poster/1` will not find. Both degrade to the
      `track_off` rectangle `hero_art/1` already leaves behind.
    * `watched`, `note` and `note_date` are `nil` when nothing was logged, and
      each draws nothing at all rather than an empty pill or a blank cream card.
    * `where` is the cache row's providers, `[]` for a film nobody has looked
      up — see the moduledoc.
  """
  @spec shaped(TrackedTitle.t(), CachedTitle.t() | nil, [Watch.t()]) :: map()
  def shaped(tracked, cached, watches) do
    zone = Kati.Time.device_zone()
    dated = Enum.sort_by(watches, &sort_key(&1, zone), {:desc, Date})
    noted = Enum.find(dated, &noted?/1)

    where_rows = Kati.Screens.SeriesMeta.where_rows(cached)

    %{
      # The row a log is written against. Carried for the same reason
      # `Kati.Screens.Series` carries `tracked_id`: the film on screen and the
      # film a sheet's own query returns first are two different facts, and
      # `:log_watch` is the tap that has to know which.
      tracked_id: tracked.id,
      title: title_of(cached),
      original: Kati.Locale.original_title(cached),
      seed: seed_of(tracked, cached),
      meta: meta_line(cached),
      year: cached && cached.first_release_year,
      watched: watched_label(tracked, dated, zone),
      # The rating comes off the newest WATCH, not off the tracked row.
      # `Kati.Media.TrackedTitle.rating` has no writer anywhere in the app —
      # screen 33's Save writes `Kati.Media.Watch.rating`, which is the rating
      # OF a viewing and is what a person actually gives — so reading the
      # tracked column meant this card drew five empty stars however many times
      # somebody rated the film. Found on a device: rate Arrival four stars,
      # save, reopen, and the card is blank.
      stars: star_value(newest_rating(watches) || tracked.rating),
      seen: seen_line(watches),
      # The COUNT as well as the sentence: `action_label/2` needs to know
      # whether a rewatch is even a thing yet, and `seen_line/1` answers in
      # words rather than in a number.
      seen_count: length(watches),
      note_date: noted && note_date(noted, zone),
      note: noted && noted.review,
      # Where this film can be watched — the same band screen 14 draws and the
      # same column it reads. It was `[]` on both, for want of an offers
      # resource; `Kati.Media.CachedTitle.providers` is that resource now.
      # `price` is `nil` on every row because TMDB
      # says where and never how much, and the row draws it as nothing.
      where: where_rows,
      where_line: Kati.Screens.Film.where_line(where_rows),
      # Kept off a shared card, and off nothing else — see the migration for
      # `Kati.Media.TrackedTitle.private`.
      private?: tracked.private,
      # Board 152's rule 1, read back: which state the ⋯ row offers to leave.
      anime?: tracked.kind == :anime,
      # Film or series, for the row that corrects it (#113). `:anime` reads as
      # whichever the cache says it is, so *This is a film* on an anime series
      # still means the right thing.
      media_kind: if(Kati.Media.Anime.film?(tracked.kind, cached), do: :movie, else: :tv),
      actions: action_row()
    }
  end

  defp title_of(%CachedTitle{title: title}) when is_binary(title) and title != "", do: title

  # The one title on this page that is Kati's own word rather than a provider's,
  # so it is the one that translates — `Kati.Screens.Series` and
  # `Kati.Screens.SeriesMeta` answer the same msgid for the same state.
  defp title_of(_cached), do: gettext("Untitled")

  # The cache row's poster path, or `nil` once the cache row is gone — the
  # renderer draws its placeholder for a `nil`.
  defp seed_of(_tracked, %CachedTitle{poster_path: path}) when is_binary(path) and path != "",
    do: path

  defp seed_of(_tracked, _cached), do: nil

  # `2025 · 1H 52M · DRAMA`: `first_release_year`, `runtime_minutes` and
  # `genres`. Every part is nullable — a provider can decline any — and an
  # absent part is left out rather than spelled as a dash.
  defp meta_line(cached) do
    [year_label(cached), runtime_label(cached), genre_label(cached)]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" · ")
  end

  # The three shapes a runtime takes, each through the msgid the rest of the app
  # already uses for a duration — `Kati.Screens.SeriesMeta.runtime_label/1`,
  # screen 13 and screen 61 all draw `%{n}h` and `%{n}m`, and a film's runtime
  # is the same fact as an episode's.
  #
  # `Kati.UI.eyebrow_label/1` and not `String.upcase/1` on the result: the upper
  # case is the drawing's Latin typography, and Persian has no case — `۱ ساعت
  # ۵۲ دقیقه` upcased is the same string, which is a no-op that still reads as
  # a decision. `Kati.Locale.number/1` for the figures, because these are
  # numerals inside a phrase rather than a column of mono digits.
  defp runtime_label(%CachedTitle{runtime_minutes: m}) when is_integer(m) and m > 0 do
    case {div(m, 60), rem(m, 60)} do
      {0, minutes} ->
        UI.eyebrow_label(gettext("%{n}m", n: Kati.Locale.number(minutes)))

      {hours, 0} ->
        UI.eyebrow_label(gettext("%{n}h", n: Kati.Locale.number(hours)))

      {hours, minutes} ->
        UI.eyebrow_label(
          gettext("%{h}h %{m}m", h: Kati.Locale.number(hours), m: Kati.Locale.number(minutes))
        )
    end
  end

  defp runtime_label(_cached), do: nil

  defp year_label(%CachedTitle{first_release_year: y}) when is_integer(y), do: Kati.Locale.year(y)
  defp year_label(_cached), do: nil

  # The genres are the provider's own words and no msgid reaches them, so this
  # raises their case and nothing else — through `Kati.UI.eyebrow_label/1` for
  # the reason above, which is also the reason a genre that arrives in Persian
  # is left exactly as it came.
  defp genre_label(%CachedTitle{genres: g}) when is_binary(g) and g != "", do: UI.eyebrow_label(g)

  defp genre_label(_cached), do: nil

  # The green pill is an assertion that the film has been seen, so it needs
  # something that asserts it. A dated watch gives the drawing's own
  # `Watched 12 Aug`; a watch with no date is the "I have seen this, I do not
  # remember when" `Kati.Media.Watch` describes, and says so without one; a
  # title the user marked finished with nothing logged is the same statement
  # made on the shelf. Anything else has not been watched and gets no pill.
  #
  # `Kati.Locale.date/2` rather than `Calendar.strftime/2`: the date is one the
  # reader logged about their own evening, so under `:fa` it is a Shamsi date
  # rather than a Gregorian one spelled in Persian — `12 Aug` is `۲۱ مرداد`,
  # and neither is a formatting of the other.
  #
  # The bare word takes a context. It is one word, `mix gettext.merge` fuzzy
  # matches a msgid that short against any sentence containing it, and the
  # catalogue already holds two *Watched*s that are not this one —
  # `Kati.Screens.Activity`'s filter chip and its log verb.
  defp watched_label(tracked, dated, zone) do
    cond do
      date = dated |> Enum.find_value(&watch_date(&1, zone)) ->
        gettext("Watched %{date}", date: Kati.Locale.date(date, :short))

      dated != [] ->
        pgettext("the watched pill over a film's artwork", "Watched")

      tracked.status == :finished ->
        pgettext("the watched pill over a film's artwork", "Watched")

      true ->
        nil
    end
  end

  # The rating on the most recent watch that carries one. Watches arrive newest
  # first, and a rewatch logged without a rating does not erase the rating of
  # the viewing before it — *unrated* is a thing a log can be, and it is not a
  # statement about the film.
  defp newest_rating(watches) when is_list(watches) do
    Enum.find_value(watches, fn w -> w.rating end)
  end

  defp newest_rating(_other), do: nil

  # Ten-point scale to the five-star row, halved and KEPT: `7` is `3.5`, which
  # `stars/1` draws as three stars and a half, the row screen 33 drew when the
  # rating was saved. This was `div(rating, 2)`, whole glyphs only, so a 3.5
  # saved on 33 came back to this card as three. An unrated film is `0`, five
  # empty stars, which is what "you have not rated this" looks like — the card
  # is the user's own rating and is never hidden.
  defp star_value(rating) when is_integer(rating), do: rating / 2
  defp star_value(_rating), do: 0

  # `2 times`. Rows counted against the user's own `rewatch_number`, which
  # `Kati.Media.Watch` says exists precisely for the history that predates Kati:
  # someone who saw a film twice before installing and once since has one row
  # claiming "3rd", and counting rows alone would print 1. Same arithmetic as
  # screen 15's rewatch card, and deliberately the same, because the two numbers
  # are the same fact and must not disagree.
  defp seen_line(watches) do
    claimed =
      watches
      |> Enum.map(& &1.rewatch_number)
      |> Enum.filter(&is_integer/1)
      |> Enum.max(fn -> 0 end)

    # `ngettext/4` for the count, because English inflects the noun after a
    # numeral and Persian does not — both plural forms of `%{n} بار` are the
    # same words, which is what a catalogue with one plural form is for.
    #
    # `never` is one word and takes a context: `mix gettext.merge` would fuzzy
    # match it against any sentence containing it, and the catalogue already
    # holds a *never* that is `Kati.Screens.Sync`'s — the last time a calendar
    # synced, which is a different never and could want a different word.
    case max(length(watches), claimed) do
      0 -> pgettext("how many times a film has been seen", "never")
      n -> ngettext("%{n} time", "%{n} times", n, n: Kati.Locale.number(n))
    end
  end

  # A watch with something written in it. The drawing's cream card is the user's
  # own words; a watch with a rating and no review has nothing to put in it.
  defp noted?(%Watch{review: review}), do: is_binary(review) and String.trim(review) != ""

  # `Note · 12 Aug`, and `Note` alone for a review the user never dated.
  #
  # Both msgids are the app's own already — `Kati.Search.Query` heads a found
  # note with the identical pair, and one word for one thing is the whole point
  # of a catalogue. `Note` stays a plain `gettext/1` rather than taking a
  # context despite being one word: it is a common label with an entry three
  # modules already share, and a context here would fork it into a second
  # Persian word for the same noun.
  #
  # The whole clause is ONE msgid rather than a translated head with a date
  # concatenated on: a language that puts the date first changes this string,
  # not this function. `Kati.Locale.date/2` because a note's date is the
  # reader's own day — Shamsi under `:fa`.
  defp note_date(watch, zone) do
    case watch_date(watch, zone) do
      nil -> gettext("Note")
      date -> gettext("Note · %{date}", date: Kati.Locale.date(date, :short))
    end
  end

  # `watched_on` first: it is the date-valued half, and `Kati.Media.Watch` keeps
  # the two apart because storing "watched on 12 August" as midnight moves it a
  # day the moment the user flies.
  #
  # `nil` for a watch that carries neither, and that `nil` is the whole reason
  # this is separate from `sort_key/2`: "I have seen this, I do not remember
  # when" is a real answer, and a sentinel date substituted for it would come
  # back out of `watched_label/3` as a film watched on the first of January.
  defp watch_date(%Watch{watched_on: %Date{} = date}, _zone), do: date

  defp watch_date(%Watch{watched_at: %DateTime{} = at}, zone) do
    at |> Kati.Time.in_zone(zone) |> DateTime.to_date()
  end

  defp watch_date(%Watch{}, _zone), do: nil

  # Newest first, undated last. Only ever compared, never printed.
  defp sort_key(watch, zone), do: watch_date(watch, zone) || ~D[0000-01-01]

  def render(assigns) do
    f = assigns.film
    back = Map.get(assigns, :back, gettext("Library"))

    cond do
      Kati.Screens.Film.gone?(f) -> Kati.Screens.Film.gone(__MODULE__, back)
      Map.get(f, :none?, false) -> Kati.Screens.Film.none(back)
      true -> Kati.Screens.Film.page(f, assigns)
    end
  end

  @doc """
  The page for a push that named no film over a shelf that has none: one
  sentence and the back pill, in `gone/2`'s layout.

  It drew the film frame with nothing in it — no title, five hollow stars that
  could not be pressed, `SEEN` over an empty line — which is a page about a
  film that does not exist. Screen 04 answers the same push with
  `Kati.Screens.Series.none/2`.
  """
  @spec none(String.t()) :: map()
  def none(back) do
    assigns = %{identity: Kati.Screens.Identity.of(__MODULE__), back: back}

    ~MOB"""
    <Box
      fill_width={true}
      fill_height={true}
      background={:background}
      layout_direction={Kati.Locale.direction_prop()}
      font_family={Kati.Locale.face_prop()}
      accessibility_id={@identity}
    >
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={140}>
        {Kati.UI.symbol("movie", size: 28, color: Palette.sub())}
        <Spacer size={14} />
        <Text
          text={gettext("No films in your library yet")}
          text_size={22}
          font_weight="bold"
          line_height={1.25}
          text_color={:on_surface}
        />
      </Column>
      <Box fill_width={true} fill_height={true} align="top">
        <Row fill_width={true} padding_left={21} padding_right={21} padding_top={60} align="center">
          {Kati.Screens.Film.back_control(@back)}
        </Row>
      </Box>
    </Box>
    """
  end

  @doc """
  Whether `f` is the answer for a push that named a row which has gone.

  `film/1` and `Kati.Screens.Series.series/1` mark it: an id was named and the
  shelf no longer holds it — removed, archived, deleted on another device. A
  push that named nothing is a different fact, the gallery's door onto an
  empty store, and keeps the empty frame.
  """
  @spec gone?(map()) :: boolean()
  def gone?(f), do: Map.get(f, :gone?, false) == true

  @doc """
  A page's fresh read, put on the socket under `key` — screen 08's `:film`,
  screen 04's `:series`.

  N37. Both pages re-read on `:resumed`, and a title removed while one sat
  under a sheet has to come back as `gone/2`'s page and nothing of the page it
  was: an open ⋯, a remove question or a refusal left standing would be
  controls about a row that is not there. So a fresh read that is `gone?/1`
  closes all three, and one that is not leaves them as the reader left them.
  """
  @spec resumed(Mob.Socket.t(), atom(), map()) :: Mob.Socket.t()
  def resumed(socket, key, fresh) do
    socket = Mob.Socket.assign(socket, key, fresh)

    if gone?(fresh) do
      socket
      |> Mob.Socket.assign(:menu?, false)
      |> Mob.Socket.assign(:confirm_remove?, false)
      |> Mob.Socket.assign(:remove_error, nil)
    else
      socket
    end
  end

  @doc """
  The page for a title that is not on the shelf: one sentence and a way back.

  It drew the detail frame with nothing in it — no title, a green *Watched*
  pill holding only its tick, an empty `SEEN`, five hollow stars — which reads
  as a page that failed to load rather than as a title that is gone. Reached by
  opening a row that was removed underneath the list that showed it, and by a
  pop back onto a page whose title was removed from above it.

  Nothing on it acts on a title, because there is none: only the back pill, in
  the same place and with the same label as the page it stands in for.
  `module` is the screen drawing it, so the root carries that screen's
  identity — screen 04 draws this too.
  """
  @spec gone(module(), String.t()) :: map()
  def gone(module, back) do
    assigns = %{identity: Kati.Screens.Identity.of(module), back: back}

    ~MOB"""
    <Box
      fill_width={true}
      fill_height={true}
      background={:background}
      layout_direction={Kati.Locale.direction_prop()}
      font_family={Kati.Locale.face_prop()}
      accessibility_id={@identity}
    >
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={140}>
        {Kati.UI.symbol("info", size: 28, color: Palette.sub())}
        <Spacer size={14} />
        <Text
          text={gettext("This title is no longer in your library")}
          text_size={22}
          font_weight="bold"
          line_height={1.25}
          text_color={:on_surface}
        />
      </Column>
      <Box fill_width={true} fill_height={true} align="top">
        <Row fill_width={true} padding_left={21} padding_right={21} padding_top={60} align="center">
          {Kati.Screens.Film.back_control(@back)}
        </Row>
      </Box>
    </Box>
    """
  end

  @doc false
  def page(f, assigns) do
    ~MOB"""
    <Box
      fill_width={true}
      fill_height={true}
      background={:background}
      layout_direction={Kati.Locale.direction_prop()}
      font_family={Kati.Locale.face_prop()}
      accessibility_id={Kati.Screens.Identity.of(__MODULE__)}
    >
      <Scroll>
        <Column fill_width={true}>
          {Kati.Screens.Film.artwork(f)}
          <Column
            fill_width={true}
            padding_left={21}
            padding_right={21}
            padding_top={16}
            padding_bottom={40}
          >
            {Kati.Screens.Film.remove_confirm(
              f,
              Map.get(assigns, :confirm_remove?, false),
              Map.get(assigns, :remove_error)
            )}
            {Kati.Screens.Film.rating_card(f)}
            {Kati.Screens.Film.note(f)}
            {Kati.Screens.Film.where_section(f)}
            {Kati.Screens.Film.actions(f)}
          </Column>
        </Column>
      </Scroll>
      {Kati.Screens.Film.chrome(assigns.menu?, Map.get(assigns, :back, gettext("Library")), f)}
    </Box>
    """
  end

  # Two locale notes on the two `Text`s below, since neither fits inside the
  # sigil (a `#` at the top level of a ~MOB is not a comment), and both are
  # `Kati.Screens.SeriesMeta.artwork/1`'s notes on the same two nodes:
  #
  #   * The 30pt title keeps `line_height={1.05}` and takes NO `max_lines`. It
  #     holds `CachedTitle.title` — a provider's words, routinely longer than
  #     the board's two — and the tight leading is there precisely because it
  #     is expected to wrap, so clamping it would truncate the one thing the
  #     page is about. Only the TRACKING goes: `letter_spacing` prises apart
  #     the joins between Arabic-script letters, and the fallback title IS
  #     translated copy (*بی‌عنوان*).
  #
  #   * The meta line is drawn in mono, and `kati_mono.ttf` carries no Persian
  #     glyph and none of U+06F0–U+06F9 either. `meta_line/1` now answers
  #     `۱ ساعت ۵۲ دقیقه · DRAMA`, so the face has to follow the STRING rather
  #     than the reader — a line that is still pure ASCII stays in DM Mono in
  #     both scripts, which is what `Kati.Locale.mono_face/1` is for.
  #
  #     `max_lines={2}` where the board has one line and this had `1`: the
  #     Persian runtime is four words where the Latin one is two characters,
  #     and screen 14 found the same line truncating on a device
  #     (`Kati.Screens.SeriesMeta.meta_line/1` says so). Wrapping loses
  #     nothing; truncating always lost the last fact, which here is the genre.
  @doc false
  def artwork(f) do
    ~MOB"""
    <Box fill_width={true} height={330} background={Palette.track_off()}>
      {Kati.Screens.Film.hero_art(f)}
      <Box fill_width={true} fill_height={true} align="bottom">
        {Kati.UI.paper_fade(190)}
      </Box>
      <Box fill_width={true} fill_height={true} align="bottom">
        <Column fill_width={true} padding_left={21} padding_right={21} padding_bottom={6}>
          {Kati.Screens.Film.watched(f.watched)}
          <Text
            text={f.title}
            text_size={30}
            font_weight="extrabold"
            letter_spacing={Kati.Locale.tracking(-0.035)}
            line_height={1.05}
            text_color={:on_surface}
          />
          {Kati.UI.original_title(Map.get(f, :original))}
          <Spacer size={9} />
          <Text
            text={f.meta}
            font_family={Kati.Locale.mono_face(f.meta)}
            text_size={11.5}
            text_color={Palette.meta()}
            max_lines={2}
          />
        </Column>
      </Box>
    </Box>
    """
  end

  @doc """
  The watched pill and the 11pt of air under it, or neither.

  A list rather than a wrapper `Column`, because the sigil flattens an
  interpolated list into its parent: the drawn film gets the same two nodes in
  the same place it already had them, and a film nobody has watched leaves no
  node behind at all rather than an empty lozenge or a stray gap above the
  title. Same move as `Kati.Screens.Activity.group/5`, and for the same reason.

  A blank label is nothing too. `empty_film/0` carries `""` here, because a
  value that reaches a `Text` is a string, and only `nil` had a clause — so the
  empty frame drew a green lozenge holding a tick and no words.

      iex> Kati.Screens.Film.watched("")
      []
      iex> Kati.Screens.Film.watched(nil)
      []
  """
  @spec watched(String.t() | nil) :: [map()]
  def watched(nil), do: []

  def watched(label) when is_binary(label) do
    if String.trim(label) == "", do: [], else: watched_row(label)
  end

  defp watched_row(label) do
    [Kati.Screens.Film.watched_pill(label), ~MOB"<Spacer size={11} />"]
  end

  @doc """
  The watched pill over the artwork — Mishka's Pill.

  A pill and not a chip: nothing here is selected or selectable, it is a
  statement about the film, which is exactly the label-on-a-lozenge a pill is.
  The tick and the label ride in as `content`, because a pill's `label` prop
  builds its own Text and this one needs a glyph beside it.

  The pixels are the Row's. `padding: 0` with `padding_left`/`padding_right` at
  11 gives the bridge the same 11/0 edges, and padding is applied before size,
  so `height: 26` measures 26 as it did. The pill's root is a `Box` that passes
  `fill_width={false}` and so hugs (K-17) where the Row hugged; inside it a
  `Row` holds the content — itself wrapped in a hugging `Row` — beside the
  empty, zero-wide `Row` that stands in for the absent ✕. Every one of those
  hugs and every one centres vertically by default, so the tick, the 6pt gap
  and the label land at the offsets they already had.
  """
  @spec watched_pill(String.t()) :: map()
  def watched_pill(label) do
    MishkaPill.pill(
      [
        background: Palette.green_wash(),
        corner_radius: 13,
        height: 26,
        padding: 0,
        padding_left: 11,
        padding_right: 11,
        align: :center
      ],
      Kati.Screens.Film.watched_content(label)
    )
  end

  @doc false
  def watched_content(label) do
    [
      Kati.UI.symbol("check_circle", size: 15, color: Palette.green_text(), fill: true),
      ~MOB"<Spacer size={6} />",
      ~MOB"""
      <Text
        text={label}
        text_size={11.5}
        font_weight="semibold"
        text_color={Palette.green_text()}
        max_lines={1}
      />
      """
    ]
  end

  # `Kati.Design.Images.poster/1` over `Kati.Media.CachedTitle.poster_path`
  # (see `shaped/3`); a film with no poster draws the bare band.
  @doc false
  def hero_art(f) do
    case Kati.Design.Images.poster(f.seed) do
      nil ->
        ~MOB"<Spacer size={0} />"

      src ->
        ~MOB"""
        <Image src={src} fill_width={true} height={330} content_mode="fill" />
        """
    end
  end

  # The default is a `gettext/1` call and not the bare word, at all three of the
  # call sites below: `mount/3` hands `Kati.Screens.Pushed.back_label/2`'s
  # answer down, which is already the reader's own word, and the default is
  # what a render with no `:back` assign draws — a test's, the gallery's — so
  # an English literal there is a Persian page under a Latin pill.
  @doc false
  def chrome(menu?, label \\ gettext("Library"), f \\ %{}) do
    ~MOB"""
    <Box fill_width={true} fill_height={true} align="top">
      <Row fill_width={true} padding_left={21} padding_right={21} padding_top={60} align="center">
        {Kati.Screens.Film.back_control(label)}
        <Spacer weight={1.0} />
        {Kati.Screens.Film.more_disc(Palette.chrome_disc(), Kati.Screens.Film.lift(), menu?, f)}
      </Row>
    </Box>
    """
  end

  @doc "The floating back pill as the chrome draws it: this page's fill, lift and tap."
  @spec back_control(String.t()) :: map()
  def back_control(label) do
    Kati.Screens.Film.back_pill({self(), :back}, Palette.chrome_disc(), lift(), label)
  end

  # `box-shadow:0 6px 16px -8px rgba(26,25,23,.6)` — this screen floats its
  # chrome over a photograph, so both controls carry the same lift. Neither
  # had one, which is why they read as flat stickers on the still.
  @doc false
  def lift, do: "0 6 16 -8 #991A1917"

  @doc """
  The floating back pill — Mishka's Pill.

  Icon plus label on a lifted lozenge is a pill with `content`; the tap is the
  pill's own `on_tap`, which takes the already-wired `{pid, tag}` untouched.

  Same pixels. `padding: 0` alongside `padding_left: 12` and
  `padding_right: 16` reproduces the Row's asymmetric 12/16 with 0 top and
  bottom — the bridge resolves an unstated edge against the uniform, and the
  uniform is 0 — and because it pads before it sizes, `height: 42` is still 42.
  `shadow` rides the root Box, which is the node that carries the fill, the
  radius and the tap, so the lift is cast around the same 21pt silhouette. The
  three extra `Row`s the pill builds (its body, the content wrapper, and the
  empty one where a ✕ would sit) all hug and all centre vertically by default,
  so the chevron, the 6pt gap and `Library` sit where they sat.
  """
  @spec back_pill(term(), non_neg_integer(), String.t(), String.t()) :: map()
  def back_pill(back, fill, lift, label \\ gettext("Library")) do
    MishkaPill.pill(
      [
        background: fill,
        shadow: lift,
        corner_radius: 21,
        height: 42,
        padding: 0,
        padding_left: 12,
        padding_right: 16,
        align: :center,
        on_tap: back
      ],
      Kati.Screens.Film.back_content(label)
    )
  end

  @doc false
  def back_content(label \\ gettext("Library")) do
    assigns = %{back: label}

    [
      Kati.UI.symbol(Kati.Screens.Pushed.back_glyph(), size: 17),
      ~MOB"<Spacer size={6} />",
      ~MOB"""
      <Text
        text={@back}
        text_size={13.5}
        font_weight="semibold"
        letter_spacing={Kati.Locale.tracking(-0.01)}
        text_color={:on_surface}
      />
      """
    ]
  end

  @doc """
  The floating overflow disc — Mishka's Action Icon, now that a disc can float.

  This screen's chrome sits over a photograph, so both controls carry the
  design's `box-shadow:0 6px 16px -8px rgba(26,25,23,.6)`; without it the disc
  reads as a flat sticker on the still. `action_icon/2` had no shadow prop and
  so could not draw it, which is the only reason this was a bare Box.

  Nothing moves: `shape: :circle` is an exact `size / 2`, so 42 rounds at 21 as
  the literal did, the fill and the shadow pass straight through, and the glyph
  is the same `Kati.UI.symbol/2` Text inside a Row that hugs it — a hugging
  Row's only child, centred in a Box of the declared size, lands where the bare
  centred Text did.
  """
  @spec more_disc(non_neg_integer(), String.t(), boolean()) :: map()
  def more_disc(fill, lift, menu?, f \\ %{}) do
    trigger =
      MishkaActionIcon.action_icon(
        [
          size: 42,
          shape: :circle,
          variant: :filled,
          background: fill,
          shadow: lift,
          on_tap: :toggle_menu
        ],
        [Kati.UI.symbol("more_horiz", size: 21)]
      )

    # This disc carried no tag at all — a ⋯ drawn on the still that answered
    # nothing. Screen 33 is the write path for the rating screen 08 displays,
    # and it was reachable only from the gallery.
    Kati.UI.Menu.overflow(
      trigger,
      menu?,
      [
        Kati.Screens.Film.log_item(f),
        # The one control that can set `Kati.Media.TrackedTitle.private`, and
        # therefore the one thing that makes screen 98's *Hide titles I marked
        # private* a switch about anything. A decision
        # about one title belongs on that title's own page.
        Kati.UI.Menu.item(
          Kati.Screens.Film.private_icon(f),
          Kati.Screens.Film.private_label(f),
          :toggle_private
        ),
        # A film could not be dropped, abandoned or
        # DNF'd anywhere in the app. Screen 149 is the sheet for it — it is
        # series-shaped in exactly two places, its header and its position
        # card, and both are answered by the title's own kind now rather than
        # assumed.
        Kati.Screens.Film.drop_item(f),
        Kati.Screens.Film.anime_item(f),
        Kati.Screens.Film.kind_item(f),
        Kati.Screens.Film.remove_item(f)
      ]
      |> Enum.reject(&(&1 == [])),
      dismiss: :close_menu
    )
  end

  @doc """
  *Log a watch* — or *Log rewatch* once the film has been seen — or nothing
  at all when there is no film to log.

  The label is `action_label/3` over the page's own `seen_count`, and the row
  opens screen 33 BLANK (`Kati.Screens.Rating.params_for/2` with `:new`), so
  Save adds a viewing rather than editing the last one. The rating card and the
  note pencil are the doors that edit.
  """
  @spec log_item(map()) :: map() | []
  def log_item(f) do
    if Map.get(f, :tracked_id) do
      Kati.UI.Menu.item(
        "star",
        Kati.Screens.Film.action_label("", :log_watch, Map.get(f, :seen_count, 0)),
        :log_watch
      )
    else
      []
    end
  end

  @doc """
  *Drop this film*, or nothing at all when there is no film to drop.

  A film can be dropped, which gives the row, and the app's own rule takes it away
  again over an empty page: with nothing tracked there is no id to name, and a
  Drop row there would open the sheet on nothing — the swap `Kati.Screens.DropSheet.sheet/1`'s
  argument exists to prevent. Dropped rather than drawn dead, which is what
  `rating_card/1` already does with its own tap on the same page.
  """
  @spec drop_item(map()) :: map() | []
  def drop_item(f) do
    if Map.get(f, :tracked_id) do
      # The same msgid `Kati.Screens.DropSheet` heads its own sheet with, which
      # is the row and the page it opens saying one word.
      Kati.UI.Menu.item("do_not_disturb_on", gettext("Drop this film"), :open_drop_sheet)
    else
      []
    end
  end

  # Two hugging children with a weighted Spacer between them, not a weighted
  # column beside a plain one. The previous version put a width-less Box in the
  # trailing Column: a Box fills width unless `width` is a NUMBER, so it took
  # everything and starved the weight={1.0} column to zero — the card rendered
  # 333dp tall against the drawing's 84 and the stars did not appear at all.
  @doc false
  def rating_card(f) do
    # The card is the door to the sheet that sets a rating.
    # It was painted, so a reader looking at their own four stars had no
    # way to change them from the page that shows them; screen 33 is where a
    # rating is written, and this is the only thing on 08 that is about one.
    #
    # `:rate` rather than `:log_watch`, though it opens the same sheet. Three
    # controls on this page carried `:log_watch` and two of them are drawn at
    # once, so `ui.sh ids` on the Pixel_9a listed the tag twice — and two nodes
    # may not share an `accessibility_id`: `onNodeWithTag` throws on the second
    # match. One action, three doors, three names.
    tap = if Map.get(f, :tracked_id), do: {self(), :rate}

    # Both eyebrows are the app's own words rather than data, so all three
    # locale moves apply to each: `Kati.UI.eyebrow_label/1` in place of
    # `String.upcase/1` (Persian has no case and upcasing it is a no-op that
    # reads as a decision), `Kati.Locale.mono_face/0` in place of the literal
    # `mono` (`kati_mono.ttf` has no Arabic-script glyph, so Android would
    # substitute a face that is not Kati's), and `Kati.Locale.tracking/1` on
    # the 0.16 (letter spacing prises apart the joins between Persian letters).
    #
    # `mono_face/0` and not `mono_face/1`: these two strings are always the
    # reader's own script, where the badge in `where_mark/1` is always a
    # provider's initial and has to be asked.
    ~MOB"""
    <Row
      fill_width={true}
      background={Palette.card()}
      corner_radius={22}
      shadow={Kati.Theme.shadow_card()}
      padding={17}
      align="center"
      on_tap={tap}
    >
      <Column weight={1.0}>
        <Text
          text={Kati.UI.eyebrow_label(gettext("Your rating"))}
          font_family={Kati.Locale.mono_face()}
          text_size={10.5}
          letter_spacing={Kati.Locale.tracking(0.16)}
          text_color={Palette.eyebrow()}
        />
        <Spacer size={7} />
        {Kati.Screens.Film.stars(f.stars)}
      </Column>
      <Column weight={1.0}>
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          <Text
            text={Kati.UI.eyebrow_label(pgettext("the rating card's count eyebrow", "Seen"))}
            font_family={Kati.Locale.mono_face()}
            text_size={10.5}
            letter_spacing={Kati.Locale.tracking(0.16)}
            text_color={Palette.eyebrow()}
            max_lines={1}
          />
        </Row>
        <Spacer size={8} />
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          <Text
            text={f.seen}
            text_size={16}
            font_weight="bold"
            text_color={:on_surface}
            max_lines={1}
          />
        </Row>
      </Column>
    </Row>
    """
  end

  # Material Symbols, not U+2605. Plus Jakarta Sans has no star glyph, so the
  # text version rendered as nothing at all — an empty card rather than a
  # missing-glyph box, which is why it read as a layout bug.
  @doc """
  The five-star row for a rating on the five-star scale, halves included.

  `Kati.Screens.Rating.stars/2`'s slot rule: whole stars up to the integer
  part, a half star when the remainder is at least a half, empty stars after.
  So `3.5` — 7 points of `Kati.Media.Watch.rating` — is three, a half and one
  empty, which is what screen 33 drew when it was saved.
  """
  @spec stars(number()) :: map()
  def stars(value) do
    full = trunc(value)
    half? = value - full >= 0.5

    cells =
      1..5
      |> Enum.map(fn i ->
        cond do
          i <= full -> Kati.Screens.Film.star(:full)
          i == full + 1 and half? -> Kati.Screens.Film.star(:half)
          true -> Kati.Screens.Film.star(:empty)
        end
      end)
      |> Enum.intersperse(Kati.Screens.Film.star_gap())

    ~MOB"""
    <Row align="center">
      {cells}
    </Row>
    """
  end

  # The drawing sets the star line at 22px with `letter-spacing:.1em` — 2.2pt
  # of air after each glyph. Material Symbols carry no tracking of their own.
  @doc false
  def star_gap, do: ~MOB"<Box width={2} height={1} />"

  @doc """
  One star of the row: `:full`, `:empty`, or `:half`.

  The half is `Kati.Screens.Rating.star/1`'s construction at this row's size
  and in this row's pair of glyphs: the empty (outlined) star, with the filled
  one over it clipped to its leading half by `clip_width` (fence `K-16`), which
  clips the draw and leaves measurement alone, so the pair sits in one star's
  line box beside its neighbours.
  """
  @spec star(:full | :empty | :half) :: map()
  def star(:full), do: Kati.UI.symbol("star", size: 22, color: Palette.accent(), fill: true)
  def star(:empty), do: Kati.UI.symbol("star", size: 22, color: Palette.accent())

  def star(:half) do
    ~MOB"""
    <Box width={22} height={22}>
      {Kati.UI.symbol("star", size: 22, color: Palette.accent())}
      <Box width={22} height={22} clip_width={0.5}>
        {Kati.UI.symbol("star", size: 22, color: Palette.accent(), fill: true)}
      </Box>
    </Box>
    """
  end

  @doc """
  The cream note card, or nothing.

  The card is the user's own words — the design's caption calls cream *"the one
  place the palette warms up"* precisely to mark them as not metadata — so a
  film with no review has no card, rather than a warm rectangle with an empty
  paragraph in it. The `12` above and the `26` below go with it, which is why
  they are inside the card's own `Column` and not in `render/1`.
  """
  @spec note(map()) :: map() | []
  def note(%{note: nil}), do: []

  def note(f) do
    # The eyebrow is `note_date/2`'s clause — *یادداشت · ۲۱ مرداد* under
    # `:fa` — so the face is asked of the STRING, not of the reader: the drawn
    # film's `Note · 12 Aug` is pure ASCII and stays in DM Mono in both scripts,
    # which is what the board draws, and the Persian one goes to Vazirmatn
    # rather than to Android's substitute face.
    #
    # The body is the reader's own words in whatever script they wrote them, and
    # `Kati.Locale.leading/1` is about the READER: Vazirmatn's metrics are not
    # Plus Jakarta's, so the design's 1.55 sets Persian too tight.
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={12} />
      <Column fill_width={true} background={Palette.cream()} corner_radius={22} padding={17}>
        <Row fill_width={true} align="center">
          <Text
            text={Kati.UI.eyebrow_label(f.note_date)}
            font_family={Kati.Locale.mono_face(f.note_date)}
            text_size={10.5}
            letter_spacing={Kati.Locale.tracking(0.16)}
            text_color={Palette.cream_meta()}
          />
          <Spacer weight={1.0} />
          {Kati.Screens.Film.note_pencil(f)}
        </Row>
        <Spacer size={9} />
        <Text
          text={f.note}
          text_size={14}
          line_height={Kati.Locale.leading(1.55)}
          text_color={Palette.cream_body()}
        />
      </Column>
      <Spacer size={26} />
    </Column>
    """
  end

  @doc """
  The `Where to watch` eyebrow and its card, or neither.

  The rows are `Kati.Media.CachedTitle.providers` (see the moduledoc). A film
  with none has no card, because an eyebrow over an empty card is the shape
  `Kati.Screens.Activity` already rejects — *"a headed card with no rows inside
  it is a worse answer than no card"* — unless the reader has set up no
  services, when board 96's prompt says what would fill it.

  A list, so the flattened result is the two nodes `render/1` used to name
  itself and the drawn film is unchanged to the node.
  """
  @spec where_section(map(), boolean() | nil) :: [map()]
  # Board 96's first band — *Set up your services to see
  # where this is streaming* — is a section screen 08 replaces, and 08 drew
  # nothing at all instead. The two absences are different and only one of them
  # is the reader's to fix: *nothing you pay for carries this film* is a fact
  # about the film, and *you have not told Kati what you pay for* is a fact
  # about the account, with a button on it.
  #
  # `set_up?/0` could not answer `false` until #75 took the fixture fallback
  # off `Kati.Screens.MyServices.listed/0`; screen 96's own moduledoc named
  # that as the change these four bands were waiting on.
  def where_section(film, set_up? \\ nil)

  def where_section(%{where: []}, set_up?) do
    # The gate as an argument, defaulting to the live one. A caller that already
    # knows — a captured frame, a test about one branch — says so rather than
    # writing a service into a store the rest of the suite shares.
    gate = if is_nil(set_up?), do: Kati.Screens.NothingSetUpKnockOn.set_up?(), else: set_up?

    if gate do
      []
    else
      # One literal each rather than the `<>` pair the body used to be:
      # `gettext/1` extracts a msgid from a LITERAL at the call site, and a
      # sentence split across two of them is a sentence a translator cannot
      # join. Both are the msgids screen 96 already draws — it is the reference
      # board for this very band, and the copy is the same copy.
      #
      # The card is `Kati.Screens.NothingSetUpKnockOn`'s and its own chrome is
      # that module's to translate; these two strings are arguments this screen
      # passes, so they are this screen's.
      [
        UI.eyebrow(gettext("Where to watch")),
        Kati.Screens.NothingSetUpKnockOn.prompt(
          gettext("Set up your services to see where this is streaming"),
          gettext(
            "Kati knows this film exists. It cannot say whether you can watch it tonight until it knows what you pay for."
          ),
          :my_services_where_to_watch
        )
      ]
    end
  end

  def where_section(f, _set_up?),
    do: [UI.eyebrow(gettext("Where to watch")), Kati.Screens.Film.where(f)]

  @doc false
  def where(f) do
    last = length(f.where) - 1

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card()}
      padding_left={15}
      padding_right={15}
      padding_top={4}
      padding_bottom={4}
    >
      {f.where |> Enum.with_index() |> Enum.map(fn {row, i} -> Kati.Screens.Film.where_row(row, i < last) end)}
    </Column>
    """
  end

  # `row.name` is a service's own name — `Lumen+`, `Kino store`, and whatever
  # TMDB answers for a real title — so it is Latin on a Persian page for the
  # reason `Kati.Screens.SeriesMeta.where_rows/1` gives: no msgid reaches a
  # provider, and a transliteration here would spell one service two ways
  # across the app. Board 127 draws `Lumen+` in Latin on a Persian page.
  @doc false
  def where_row(row, rule?) do
    {value, face} = where_value(row)

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={13} padding_bottom={13}>
        {Kati.Screens.Film.where_badge(row.badge)}
        <Spacer size={13} />
        <Text
          text={row.name}
          text_size={13.5}
          font_weight="semibold"
          text_color={:on_surface}
          weight={1.0}
          max_lines={1}
        />
        <Text
          text={value}
          font_family={face}
          text_size={11}
          text_color={Palette.muted()}
          max_lines={1}
        />
      </Row>
      {Kati.Screens.Film.hairline(rule?)}
    </Column>
    """
  end

  # The trailing cell holds one of two different things, and they want opposite
  # typesetting.
  #
  # `line` is the row's own WORD and `Kati.Screens.SeriesMeta.where_rows/1`
  # translates it — under `:fa` it is `با اشتراک`, and `kati_mono.ttf` has no
  # glyph for a letter of it, so a hardcoded `mono` hands the cell to Android's
  # substitute face. `Kati.Locale.mono_face/1` asks the string: a word that is
  # still pure ASCII stays in DM Mono, which is what the board draws.
  #
  # `price` is a FIGURE with a currency mark, and the same question answered
  # about it gives the wrong answer: `£` is U+00A3, so a perfectly Latin price
  # would test as non-ASCII and go to Vazirmatn, where DM Mono has the sterling
  # sign and the drawing sets this cell in it. `Kati.Screens.SeriesMeta.price/1`
  # says the same thing about its own cell. So the face follows WHICH value the
  # row carries rather than what the string is made of.
  #
  # `Kati.Locale.ltr/1` on the price and never on the word: a currency mark is a
  # bidi neutral, so on an RTL page the algorithm resolves it against the PAGE
  # and lays `£9.99` out as `9.99£`. The isolate makes the run resolve against
  # itself; wrapping the Persian word would do the reverse to it.
  defp where_value(row) do
    line = Map.get(row, :line)
    price = Map.get(row, :price)

    cond do
      is_binary(line) and line != "" -> {line, Kati.Locale.mono_face(line)}
      is_binary(price) and price != "" -> {Kati.Locale.ltr(price), "mono"}
      true -> {"", "mono"}
    end
  end

  @doc """
  The pencil on the note card: the sheet the note was written in.

  Screen 33 holds the review — it is the one field in this app that writes
  `Kati.Media.Watch.review` — so *edit this note* is *open the log this note
  belongs to*. It was a painted glyph.

  A drawn film has no row to edit and gets a picture, which is what board 08's
  own state is.
  """
  @spec note_pencil(map()) :: map()
  def note_pencil(f) do
    # `:edit_note`, not `:log_watch` — see `rating_card/1` on why each door
    # onto screen 33 carries its own tag.
    assigns = %{tap: if(Map.get(f, :tracked_id), do: {self(), :edit_note})}

    ~MOB"""
    <Box on_tap={@tap} fill_width={false}>
      {Kati.UI.symbol("edit", size: 17, color: Palette.gold_icon())}
    </Box>
    """
  end

  @doc """
  A service's two-letter badge — Mishka's Theme Icon.

  "A themed container around exactly one icon" is the whole of what this Box
  was, so the component is a rename rather than a rewrite. With no `id` to tag
  and the mark passed as a child, `theme_icon/2` emits one Box whose props map
  is the hand-rolled one key for key — `width: 32, height: 32, align: :center,
  corner_radius: 10, background: #EFECE7` — around the same mono Text.
  `variant: :filled` with a raw `color` puts the design's own value in the fill
  rather than a theme token, and the Text keeps the colour and weight it was
  written with, because a caller-supplied icon always does.
  """
  @spec where_badge(String.t()) :: map()
  def where_badge(badge) do
    MishkaThemeIcon.theme_icon(
      [variant: :filled, color: Palette.paper(), size: 32, radius: 10],
      [Kati.Screens.Film.where_mark(badge)]
    )
  end

  # The badge is a service's own initial, so it is Latin on a Persian page for
  # the reason the name beside it is. `Kati.Locale.mono_face/1` asks the STRING
  # and answers `mono` for it — the call is here so that a provider whose name
  # is not ASCII gets Vazirmatn rather than the empty box DM Mono draws for
  # every glyph it has not got. `Kati.Screens.SeriesMeta.where_mark/1` is the
  # same node on screen 14 and reads the same way.
  @doc false
  def where_mark(badge) do
    ~MOB"""
    <Text
      text={badge}
      font_family={Kati.Locale.mono_face(badge)}
      text_size={13}
      font_weight="medium"
      text_color={:on_surface}
    />
    """
  end

  @doc """
  The rule between two `where` rows — Mishka's Separator at the design's own
  colour and thickness, drawn as a **box**.

  `render: :box` is load-bearing, and it was missing. This comment used to
  claim a `<Divider>` is `Box(fillMaxWidth().height(t).background(c))`; it is
  not. `MobDivider` is Material 3's `HorizontalDivider`, which is a `Canvas`
  that `drawLine`s an **antialiased stroke**. At this device's 2.6875x a 1dp
  rule is handed a 3px-tall canvas and a 2.6875px stroke centred in it, so the
  bottom pixel row lands at ~69% coverage: one full-width row 4-5/255 lighter
  than the `1px solid rgba(26,25,23,.07)` the drawing asks for, and no
  combination of `color` and `thickness` can fix it because the softness is in
  the primitive.

  `render: :box` puts back the primitive the hand-rolled markup used —
  `<Box fill_width={true} height={1} background={…}>`, a filled rect with no
  antialiased edge, so every pixel row carries the full colour. It carries a
  1dp `<Spacer>` that is an iOS height workaround rather than a design: on
  Android the Box's own `height` pins the rule and the background covers the
  Spacer, so the node draws exactly the rectangle this screen drew before it
  adopted the component.
  """
  @spec hairline(boolean()) :: map()
  def hairline(false), do: ~MOB"<Spacer size={0} />"

  def hairline(true),
    do: MishkaSeparator.separator(color: Palette.hairline(), thickness: 1, render: :box)

  @doc false
  def actions(f) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={14} />
      <Row fill_width={true} align="top">
        {f.actions |> Enum.map(fn {icon, label, tag} -> Kati.Screens.Film.action(icon, label, tag, Map.get(f, :seen_count, 0)) end) |> Enum.intersperse(Kati.Screens.Film.action_gap())}
      </Row>
    </Column>
    """
  end

  @doc false
  def action_gap, do: ~MOB"<Spacer size={10} />"

  # A Box for the frame and a Column for the stack, not a Column doing both.
  # `Column` takes no horizontal alignment in this bridge, so its children pin
  # to the left edge — the icons and labels sat against the button's left side.
  # A Box centres its content in both axes when given `align`.
  @doc false
  def action(icon, drawn_label, tag, seen \\ 0) do
    label = Kati.Screens.Film.action_label(drawn_label, tag, seen)
    # `nil` for the two pills with nowhere to go — a `<Box>` with a nil
    # `on_tap` draws no tap at all, which is what they did before and is the
    # honest state until each has a destination.
    tap = if tag, do: {self(), tag}

    ~MOB"""
    <Box weight={1.0} on_tap={tap}>
      <Box
        fill_width={true}
        height={52}
        corner_radius={20}
        background={Palette.card()}
        shadow={Kati.Theme.shadow_card_soft()}
        align="center"
      >
        <Column>
          <Row align="center">
            <Spacer weight={1.0} />
            {Kati.UI.symbol(icon, size: 19)}
            <Spacer weight={1.0} />
          </Row>
          <Spacer size={3} />
          <Text
            text={label}
            text_size={10.5}
            font_weight="semibold"
            text_color={Palette.ink_soft()}
            max_lines={1}
            text_align="center"
          />
        </Column>
      </Box>
    </Box>
    """
  end

  def handle_info({:tap, :back}, socket), do: {:noreply, Kati.Screens.Resume.pop(socket)}

  def handle_info({:tap, :toggle_menu}, socket),
    do: {:noreply, Mob.Socket.assign(socket, :menu?, not socket.assigns.menu?)}

  def handle_info({:tap, :close_menu}, socket),
    do: {:noreply, Mob.Socket.assign(socket, :menu?, false)}

  # The sheet is about a watch OF this film, so it is told which. Bare, "Log a
  # watch" on one film opened whatever the newest logged watch in the whole
  # library happened to be.
  # Three doors onto screen 33 and two behaviours. The ⋯ row logs ANOTHER
  # viewing, so it opens the sheet blank and Save creates a watch; the rating
  # card and the note pencil are about the viewing already logged, so they
  # reopen it and Save edits it. See `log_item/1`.
  def handle_info({:tap, :log_watch}, socket) do
    {:noreply,
     socket
     |> Mob.Socket.assign(:menu?, false)
     |> Mob.Socket.push_screen(
       Kati.Screens.Rating,
       Kati.Screens.Rating.params_for(socket.assigns.film, :new)
     )}
  end

  def handle_info({:tap, tag}, socket) when tag in [:rate, :edit_note] do
    {:noreply,
     socket
     |> Mob.Socket.assign(:menu?, false)
     |> Mob.Socket.push_screen(
       Kati.Screens.Rating,
       Kati.Screens.Rating.params_for(socket.assigns.film)
     )}
  end

  # Drop this film: screen 149, over the title this page is drawing.
  #
  # The sheet was reachable only from a series, so a
  # film had no way to be dropped, abandoned or DNF'd at all.
  #
  # Named, exactly as screen 04's row is and for the same reason its comment
  # gives: bare, the sheet opens on the newest gone-cold title in the store,
  # which is not the film in front of the reader and may be nothing to do with
  # it — a Drop that dropped somebody else's title.
  #
  # A comment rather than a `@doc`, because these are clauses of one
  # `handle_info/2` and a second doc on it discards the first.
  def handle_info({:tap, :open_drop_sheet}, socket) do
    {:noreply,
     socket
     |> Mob.Socket.assign(:menu?, false)
     |> Mob.Socket.push_screen(
       Kati.Screens.DropSheet,
       Kati.Screens.DropSheet.params_for(socket.assigns.film)
     )}
  end

  # N36: the ⋯ row asks first — `remove_confirm/3` — and only the card's own
  # button removes. `Kati.Screens.Series.remove/1` is the one removal, and a
  # removal that landed pops, because the page is about a row that no longer
  # exists; `Kati.Screens.Resume` makes whatever is underneath re-read.
  def handle_info({:tap, :confirm_remove}, socket) do
    {:noreply,
     socket
     |> Mob.Socket.assign(:menu?, false)
     |> Mob.Socket.assign(:confirm_remove?, true)
     |> Mob.Socket.assign(:remove_error, nil)}
  end

  def handle_info({:tap, :keep_title}, socket) do
    {:noreply,
     socket
     |> Mob.Socket.assign(:confirm_remove?, false)
     |> Mob.Socket.assign(:remove_error, nil)}
  end

  def handle_info({:tap, :remove_title}, socket) do
    case Kati.Screens.Series.remove(socket.assigns.film) do
      :ok ->
        {:noreply,
         socket |> Mob.Socket.assign(:confirm_remove?, false) |> Kati.Screens.Resume.pop()}

      {:error, reason} ->
        {:noreply, Mob.Socket.assign(socket, :remove_error, Kati.Write.message({:error, reason}))}
    end
  end

  @doc """
  Put this film on the calendar: screen 18, with its name already typed.

  A film you mean to watch is a thing that is going to happen, and screen 18
  is the one field in this app that takes *a thing that is going to happen*.
  It is pre-filled with `Watch <title>` rather than the bare title, because
  the sentence a reader completes is *watch Dune tomorrow 8pm* and the verb is
  the part they should not have to type.

  The VERB translates and the title does not: the title is a provider's, and
  what a Persian reader should find in the field is *تماشای Dune* — their own
  word for the thing they are about to do, in front of the name the film has.
  The whole clause is one msgid so that a language which puts the verb last can
  put it last.

  No `Kati.Locale.ltr/1` around the title, deliberately, and this is the one
  place on the screen that goes the other way: the isolates are invisible
  characters, and this string lands in an editable `TextField` that the reader
  then types into and that `Kati.QuickAdd.Parse` reads back — two of them
  buried in a field somebody has to edit is worse than a name that leans the
  wrong way for a moment.
  """
  def handle_info({:tap, :schedule_watch}, socket) do
    {:noreply,
     socket
     |> Mob.Socket.assign(:menu?, false)
     |> Mob.Socket.push_screen(Kati.Screens.QuickAdd, %{
       sentence: gettext("Watch %{title}", title: socket.assigns.film.title)
     })}
  end

  # Mark this film private, or unmark it — the one write behind screen 98's
  # *Hide titles I marked private*, which was a switch with nothing to mark.
  #
  # It hides the title from that CARD and from nowhere else. The shelf, Up next
  # and the year's own numbers are unchanged, because a private title is still a
  # title you watched.
  def handle_info({:tap, :toggle_private}, socket) do
    f = socket.assigns.film

    with id when is_binary(id) <- Map.get(f, :tracked_id),
         {:ok, tracked} <- Ash.get(Kati.Media.TrackedTitle, id),
         {:ok, updated} <-
           tracked
           |> Ash.Changeset.for_update(:update, %{private: not tracked.private})
           |> Ash.update() do
      {:noreply,
       socket
       |> Mob.Socket.assign(:menu?, false)
       |> Mob.Socket.assign(:film, %{f | private?: updated.private})}
    else
      _refused -> {:noreply, Mob.Socket.assign(socket, :menu?, false)}
    end
  end

  # Board 152's rule 1, written. `anime_override` is three-valued and this only
  # ever sets it to `true` or `false` — a reader who has pressed the row HAS
  # said, and `nil` is the state of never having been asked (#104).
  def handle_info({:tap, :toggle_anime}, socket) do
    f = socket.assigns.film

    with id when is_binary(id) <- Map.get(f, :tracked_id),
         {:ok, tracked} <- Ash.get(Kati.Media.TrackedTitle, id),
         now? <- tracked.kind == :anime,
         {:ok, updated} <-
           tracked
           |> Ash.Changeset.for_update(:update, %{
             anime_override: not now?,
             kind: Kati.Media.Anime.kind_for(tracked.kind, nil, not now?)
           })
           |> Ash.update() do
      {:noreply,
       socket
       |> Mob.Socket.assign(:menu?, false)
       |> Mob.Socket.assign(:film, Map.put(f, :anime?, updated.kind == :anime))}
    else
      _refused -> {:noreply, Mob.Socket.assign(socket, :menu?, false)}
    end
  end

  # Kind, corrected. A hand-typed title takes its Kind
  # from a two-chip answer on 154 and nothing could change it afterwards — a
  # show picked as a film sat on the wrong screen forever, and the add path
  # refused to let you type it again because the name was taken.
  #
  # `Kati.Screens.Resume.pop/1` rather than a push: the title has moved to the
  # other screen, and the page the reader is on is now about a kind this title
  # is not. Popping puts them back where they came from, and the tile there
  # opens the right screen.
  def handle_info({:tap, :swap_kind}, socket) do
    f = socket.assigns.film

    with id when is_binary(id) <- Map.get(f, :tracked_id),
         {:ok, tracked} <- Ash.get(Kati.Media.TrackedTitle, id),
         swapped <- Kati.Screens.Film.swapped(Map.get(f, :media_kind, :movie)),
         {:ok, _updated} <- Kati.Screens.Film.rekind(tracked, swapped) do
      {:noreply, socket |> Mob.Socket.assign(:menu?, false) |> Kati.Screens.Resume.pop()}
    else
      _refused -> {:noreply, Mob.Socket.assign(socket, :menu?, false)}
    end
  end

  # Board 96's button, on the band above. One clause, because the sheet's whole
  # point is that one screen answers all four (#120).
  def handle_info({:tap, :my_services_where_to_watch}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.MyServices)}

  # Hand the film to the system share sheet.
  #
  # `Mob.Share.text/2`, which is Mob's own and needed no fence: `ACTION_SEND`
  # through `Intent.createChooser` on Android, `UIActivityViewController` on
  # iOS. The comment beside `action_row/0` said this was waiting on something
  # nobody had written; it was there all along.
  #
  # Fire-and-forget by construction — nothing comes back into the BEAM — so
  # there is nothing to report and nothing to draw. The socket is unchanged,
  # which `Mob.Share.text/2` documents in as many words.
  # Board 334's door, over this page and carrying this film.
  def handle_info({:tap, :add_to_list}, socket) do
    film = socket.assigns.film || %{}

    {:noreply,
     Kati.Lists.Door.open(socket, Kati.Lists.Door.title_member(film), Map.get(film, :title))}
  end

  def handle_info({:tap, :share_film}, socket) do
    {:noreply, Mob.Share.text(socket, Kati.Screens.Film.share_line(socket.assigns.film))}
  end

  # Coming back from the log sheet, or from anything else pushed over this
  # page. See `Kati.Screens.Resume`: a popped-to screen restores its saved
  # socket, so *Log a watch* → Save → back left the stars empty, `SEEN never`
  # and the first pill still reading *Log a watch* — the write had landed and
  # the page in front of the reader said it had not.
  #
  # This screen is hand-rolled rather than `Kati.Screens.Pushed`, so nothing
  # routes `{:kati, …}` to a `handle_kati/3` for it; the clause is the routing.
  # The id is re-read off the film on screen so the refresh describes the same
  # title the arrival did — or, when the page is already the one that says the
  # title has gone, off the push, since that page carries no id of its own and
  # a `nil` here would open the top of the shelf in its place.
  #
  # N37: `resumed/3` is the whole refresh, shared with screen 04, so a title
  # removed while this page sat under a sheet turns into `gone/2`'s page on the
  # way back, and its ⋯ and its remove question go with it.
  def handle_info({:kati, :resumed, _payload}, socket) do
    id = Map.get(socket.assigns.film, :tracked_id) || Map.get(socket.assigns, :id)
    {:noreply, Kati.Screens.Film.resumed(socket, :film, film(id))}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  @doc """
  Where this film can be watched, as one line, or `nil`.

  The FIRST row of the band, which is the first way it is offered — what the
  reader pays for, then free, then rent, then buy, in `Kati.Screens.SeriesMeta.
  where_rows/1`'s own order.

  Not `Kati.Media.Availability.line/3`, and the difference matters here: that
  one answers *what can YOU watch*, which is the right question for hiding a
  title and the wrong one for telling somebody else about it. A film on
  Kanopy is on Kanopy whether or not the person sharing it subscribes.

  `nil` for a film nobody has looked up, which keeps *Dune* out of a share
  that would otherwise claim it was available nowhere.

      iex> Kati.Screens.Film.where_line([])
      nil

      iex> Kati.Screens.Film.where_line([%{name: "Kanopy", line: "included"}])
      "On Kanopy"

      iex> Kati.Screens.Film.where_line([%{name: "Apple TV", line: "rent"}])
      "Rent from Apple TV"

  ## The two clauses that matched on a label

  `line` is the row's own WORD, and since mishka-group/kati#103 it is a
  translated one — `Kati.Screens.SeriesMeta.where_rows/1` builds it with
  `pgettext("where to watch", "rent")`, so on a Persian page it is `کرایه`.
  Matched against the literal `"rent"` in a head, both of those clauses simply
  stopped firing under `:fa` and every offer fell through to the last one: a
  rental shared as *On Apple TV*, which says the reader can watch it and they
  cannot. A label carrying state is the defect; the state is the provider's
  KIND, which `where_rows/1` has and does not pass on.

  Compared against the same `pgettext/2` call rather than a literal, so the two
  strings are the same catalogue entry read in the same process. The durable
  fix is a `kind` on the row — that is `Kati.Screens.SeriesMeta`'s to add, and
  when it lands these three lines read it instead.

  The three msgids take a context. *On %{name}* is one word and a placeholder,
  and `mix gettext.merge` fuzzy-matches a msgid that short against anything.
  """
  @spec where_line([map()]) :: String.t() | nil
  def where_line([]), do: nil

  def where_line([row | _rest]) do
    name = Map.get(row, :name)
    line = Map.get(row, :line)

    # `cond` and not a `case` with guards: `pgettext/3` expands to a function
    # call, and a function call is not allowed in a guard.
    cond do
      line == pgettext("where to watch", "rent") ->
        pgettext("how a shared film can be watched", "Rent from %{name}", name: name)

      line == pgettext("where to watch", "buy") ->
        pgettext("how a shared film can be watched", "Buy from %{name}", name: name)

      true ->
        pgettext("how a shared film can be watched", "On %{name}", name: name)
    end
  end

  @doc """
  The ⋯ row that marks a title private, and what it says.

  Two labels rather than a switch, because an overflow row is a verb: *Keep off
  shared cards* is what pressing it does, and *Show on shared cards* is what
  pressing it does when it is already off one.
  """
  @spec private_label(map()) :: String.t()
  def private_label(%{private?: true}), do: gettext("Show on shared cards")
  def private_label(_film), do: gettext("Keep off shared cards")

  @doc """
  The glyph beside it.

  `visibility_off` both ways, and `lock` is not the alternative it looks like:
  Kati's icon subset carries exactly two of this family — `Kati.Icons.glyph!/1`
  raises on anything else, which is how a `visibility` here took the film
  screen down on the Pixel_9a and sent the app back to Home. The row's WORD
  carries the state; the glyph names the subject.
  """
  @spec private_icon(map()) :: String.t()
  def private_icon(_film), do: "visibility_off"

  @doc """
  Board 152's first rule, as a row: *Your own tag — always wins, you know.*

  The reader's own answer is rule 1 and there was
  nowhere in the app to give it. This is that place, on the same ⋯ that carries
  *Keep off shared cards* and for its reason: a decision about one title
  belongs on that title's own page.

  The word says what pressing it does, which is why it is not *Anime* with a
  tick. A title Kati already files as anime offers to stop; one it does not
  offers to start.

      iex> Kati.Screens.Film.anime_label(%{anime?: true})
      "Not anime"

      iex> Kati.Screens.Film.anime_label(%{anime?: false})
      "Mark as anime"

  Both take the same context. *Not anime* is two words, `mix gettext.merge`
  fuzzy-matches a msgid that short, and the catalogue already holds a *Not
  anime* that is screen 152's override pill rather than this row — one is a
  statement about a guess and this is a thing you press. The pair shares a
  context so a translator meets them as the pair they are.
  """
  @spec anime_label(map()) :: String.t()
  def anime_label(%{anime?: true}),
    do: pgettext("the ⋯ row that tags a title as anime", "Not anime")

  def anime_label(_title), do: pgettext("the ⋯ row that tags a title as anime", "Mark as anime")

  @doc """
  The row, or nothing at all when there is no title behind it.

  Dropped rather than drawn dead over an empty page, which is `drop_item/1`'s
  rule on this page and the app's everywhere.
  """
  @spec anime_item(map()) :: map() | []
  def anime_item(f) do
    if Map.get(f, :tracked_id) do
      Kati.UI.Menu.item("auto_awesome", Kati.Screens.Film.anime_label(f), :toggle_anime)
    else
      []
    end
  end

  @doc """
  *This is a series* / *This is a film* — the one row that corrects a Kind.

  A hand-typed title takes its Kind from a two-chip
  answer on screen 154, and no screen in the app could change it afterwards:
  picking Film for a show meant a title on the wrong screen forever, with the
  add path refusing to let you type it again because the name was taken.

  It is a menu row rather than a control on the page, for `private`'s reason
  and `anime`'s: a decision about one title belongs on that title's own page,
  and the ⋯ is where the decisions that are not about watching live.

      iex> Kati.Screens.Film.kind_label(:movie)
      "This is a series"

      iex> Kati.Screens.Film.kind_label(:tv)
      "This is a film"

  Two whole sentences and so a plain `gettext/1` each, where the anime pair
  beside them needs a context: four words about one subject are not what `mix
  gettext.merge` fuzzy-matches, and `Kati.Screens.Series` draws these same two
  rows from here — one msgid, two screens, one Persian word for one row.
  """
  @spec kind_label(atom()) :: String.t()
  def kind_label(:movie), do: gettext("This is a series")
  def kind_label(_series), do: gettext("This is a film")

  @doc false
  @spec kind_item(map()) :: map() | []
  def kind_item(f) do
    if Map.get(f, :tracked_id) do
      Kati.UI.Menu.item(
        "swap_horiz",
        Kati.Screens.Film.kind_label(Map.get(f, :media_kind, :movie)),
        :swap_kind
      )
    else
      []
    end
  end

  @doc """
  The other kind.

      iex> Kati.Screens.Film.swapped(:movie)
      :tv

      iex> Kati.Screens.Film.swapped(:tv)
      :movie
  """
  @spec swapped(atom()) :: atom()
  def swapped(:movie), do: :tv
  def swapped(_series), do: :movie

  @doc """
  Write the corrected kind to BOTH rows, because both hold one.

  `Kati.Media.TrackedTitle.kind` is what the shelf queries and
  `Kati.Media.CachedTitle.kind` is what decides which screen a tile opens
  (`Kati.Media.Anime.film?/2`), so correcting one and not the other would put
  the title on the right shelf behind the wrong door.

  An anime keeps being an anime: the tracked row's `:anime` is the flag, and
  the cache is where film-or-series lives — see `Kati.Media.Anime`.
  """
  @spec rekind(term(), atom()) :: {:ok, term()} | {:error, term()}
  def rekind(tracked, kind) do
    Kati.Media.CachedTitle
    |> Ash.Query.filter(source == ^tracked.source and source_id == ^tracked.source_id)
    |> Ash.read!()
    |> Enum.each(&(&1 |> Ash.Changeset.for_update(:update, %{kind: kind}) |> Ash.update!()))

    tracked
    |> Ash.Changeset.for_update(:update, %{
      kind: if(tracked.kind == :anime, do: :anime, else: kind)
    })
    |> Ash.update()
  rescue
    error -> {:error, error}
  end

  @doc """
  *Remove from library*, or nothing at all when there is no title to remove.

  N36: a title could be removed from the shelf's selection mode and from board
  248's no-episode card, and from nowhere on its own page — screen 08's ⋯ had
  no such row and neither had screen 04's. The row opens `remove_confirm/3`
  rather than removing, because `Kati.Screens.Series.remove/1` takes the
  title's watches, ratings and notes with it (N11) and that is not a thing one
  mis-tap should do.

  Shared by screens 08 and 04, and dropped over an empty page for `drop_item/1`'s
  reason: there is no row behind it.
  """
  @spec remove_item(map()) :: map() | []
  def remove_item(f) do
    if Map.get(f, :tracked_id) do
      Kati.UI.Menu.item("delete", gettext("Remove from library"), :confirm_remove)
    else
      []
    end
  end

  @doc """
  The question `remove_item/1` asks before anything is written.

  `Kati.UI.Destructive.confirm/1`, the recipe `Kati.Screens.ListDetail` asks a
  list deletion with, leading with what goes and then with what does not.
  What goes is what `Kati.Screens.Series.remove/1`'s cascade takes; what stays
  is the provider's description of the title, which is why adding it again
  brings the page back and not the history.

  `error` is the refusal of a remove that was confirmed and did not land, drawn
  under the card so the reader is still on the page they tried to clear.
  Nothing at all while nobody is being asked.
  """
  @spec remove_confirm(map(), boolean(), String.t() | nil) :: map()
  def remove_confirm(f, true, error) do
    assigns = %{
      confirm:
        Kati.UI.Destructive.confirm(
          eyebrow: gettext("Removing it"),
          title: gettext("Remove %{title} from your library?", title: Map.get(f, :title, "")),
          changes:
            gettext(
              "the title leaves your shelf, with every watch, rating and note you logged for it, and its places on your lists."
            ),
          keeps:
            gettext(
              "your other titles and your lists. Adding it again brings back its details, not its history."
            ),
          confirm: {gettext("Remove it"), :remove_title},
          keep: {gettext("Keep it"), :keep_title}
        ),
      error: error
    }

    ~MOB"""
    <Column fill_width={true}>
      {@confirm}
      {Kati.Screens.Series.refusal(@error)}
      <Spacer size={16} />
    </Column>
    """
  end

  def remove_confirm(_f, _asking?, _error), do: ~MOB"<Spacer size={0} />"

  @doc """
  What gets shared: the title, the year, and where it can be watched.

  The year is the film's stored `first_release_year` when the page carries it,
  in Latin digits whatever the reader's script, because the message goes to
  somebody else; a page without one reads a four-digit year off the meta line.

  The last part is the one worth sending. `Kati.Media.Availability` knows it
  now, and *Dune (2021) — On Netflix* is a message somebody can act on where
  *Dune* is a message they have to look up.

      iex> Kati.Screens.Film.share_line(%{title: "Dune", meta: "2021 · SCI-FI", where_line: nil})
      "Dune (2021)"

      iex> Kati.Screens.Film.share_line(%{title: "Dune", meta: nil, where_line: "On Netflix"})
      "Dune — On Netflix"
  """
  @spec share_line(map()) :: String.t()
  def share_line(film) do
    [
      film.title <> year_suffix(Map.get(film, :year), Map.get(film, :meta)),
      Map.get(film, :where_line)
    ]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(" — ")
  end

  defp year_suffix(year, _meta) when is_integer(year), do: " (" <> Integer.to_string(year) <> ")"
  defp year_suffix(_none, meta), do: year_suffix(meta)

  defp year_suffix(meta) when is_binary(meta) do
    case Regex.run(~r/\b(\d{4})\b/, meta) do
      [_all, year] -> " (" <> year <> ")"
      _no_year -> ""
    end
  end

  defp year_suffix(_none), do: ""
end
