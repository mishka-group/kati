defmodule Kati.Screens.Library do
  @moduledoc """
  Screen 03 — Library.

  Built to `test/design/screens/03.html`: a segmented control on a
  `#E4E0D9` trough, three quick tiles carrying mono counts, chips with counts
  at .65 opacity, and a three-across grid of 158-tall posters each with a
  progress bar burnt into its bottom edge.

  **Books and Music push their shelves**, and did not always. #60 settled that
  v1 ships one media domain — Screen — because a solo maintainer with a
  calendar and a sync engine on the critical path should not open two crowded
  markets, and both segments were inert on that reasoning.

  The reasoning expired when the design did. Screens 66-72 draw a book in full
  — detail, states, dark, RTL, and a reading-session logger that writes — and
  73-79 do the same for an album and an artist. Fourteen drawn screens behind a
  segment that goes nowhere is not restraint, it is fourteen screens nobody can
  reach. `Kati.Books` is a real domain with a real backup entry, so the segment
  now does what it looks like it does.

  Nothing on this screen changes shape. `#AFA89E` is `Palette.segment_idle/0`,
  the ordinary unselected segment colour, and the drawing never gave either
  segment a disabled treatment — they were unselected, and the app read that as
  unavailable. So the frame is identical and only the tap is different.

  Mob has no wrap primitive, so the grid is chunked into rows of three, and the
  three posters share the row by weight rather than measuring 112 each. The
  design's 112*3 + 12*2 = 360 is the arithmetic of its own 402pt frame; a real
  411dp device leaves ~370dp between the 21pt gutters, so fixed tiles stop
  ~9dp short and the right edge goes ragged.

  ## Real data versus the drawing

  The shelf is `Kati.Media` — `Kati.Media.TrackedTitle` for what the user
  decided, `Kati.Media.CachedTitle` for what a provider said, and
  `Kati.Media.Watch` for the ticks the episode counter is derived from. See
  `shelf/0` for the query and `shaped/3` for the one row shape the header, the
  chips and the grid all read.

  ## A database with no library draws the emptiness, not nine invented films

  This screen used to answer an empty shelf with `drawn_titles/0` — the nine
  titles `Kati.Library.Sample` holds — on the argument that *missing data is
  not a reason for a blank screen* and that a Library rendered empty could not
  be compared with the drawing. Both halves were wrong in the way that matters
  to a person rather than to a capture:

    * the first sight of the app on a fresh phone was nine films nobody had
      added, in the shape and colour of the user's own shelf. #91's report of
      it is one sentence — *"you all show dummy data and it is not connected to
      database"* — and it is the correct reading of what the screen drew;

    * an empty Library is not a blank screen. **The design draws this state.**
      `test/design/screens/27.html`, *Empty, loading, offline*, opens with the
      band `Empty — nothing added yet` and it is this screen's own emptiness it
      draws: a `movie` glyph on a paper square, *No titles yet*, *Add one thing
      you are watching and the calendar starts filling itself.*, one ink pill
      reading *Add a title*, and *or import a backup* under it. Screen 139
      names that geometry as the house recipe — *"glyph tile, sentence, one ink
      action, one quiet alternative"* — and screen 96 states the rule the nine
      films broke: *"an empty state should say what is missing and offer the
      one thing that fixes it — never render a plausible-looking zero."*

  So `titles/0` is the shelf and nothing else, and `shelf_body/3` puts screen
  27's card where the chips and the grid go. `drawn_titles/0` and
  `Kati.Library.Sample` are untouched and are no longer reachable from a
  render: they are what screen 03's own drawing was captured from, and the
  fixture the shelf tests build their "rows present" half against.

  ### What the empty branch keeps, and why

  Screen 139's caption is explicit that an empty board *"states which parts
  still work, because an empty Home that looks broken sends a new user back
  out"*. The header, the Screen/Books/Music switcher and the three quick tiles
  are all still live with an empty Screen shelf — Books and Music are separate
  domains with their own rows, and Discover and Lists do not need a shelf — so
  they stay exactly as screen 03 draws them.

  What goes is the row of filter chips. They would read `All 0 · Watching 0 ·
  Not started 0 · Finished 0` directly above a card whose whole job is to say
  there is nothing here, and screen 96 draws that decision for the empty ledger
  in as many words — *"hides the delta badge, the per-service rows and the
  Worth-a-look card entirely — a 'down 0%' chip would be noise"*. The board
  templates the chips (`{{ t.label }}`, `{{ t.count }}`), so no drawn value is
  dropped with them, and nothing is invented in their place.

  The mono subtitle stays and reads `0 titles · 0 in progress`. It was
  withheld for the same reason as the chips for one round, and the drawing said
  otherwise: `03.html` puts an 11pt mono line 5pt under the title and
  `Kati.ScreenTitleSubtitleTest` reads that off the board as the spec. See
  `subtitle_line/1`, which records what withholding it actually rendered.
  """
  use Kati.Screens.Root, root: :library

  require Ash.Query

  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaChip
  alias Kati.Components.MishkaProgress
  alias Kati.Library.Sample
  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Theme
  alias Kati.Theme.Palette

  # What the Screen shelf is made of. Books and Music are drawn inactive (see
  # the moduledoc), so `:book` and `:album` are deliberately absent rather than
  # queried and thrown away.
  @screen_kinds [:movie, :tv, :anime]

  @impl true
  def load(socket) do
    Mob.Socket.assign(socket,
      filter: "All",
      titles: titles(),
      # The WHOLE shelf's watching count, not the narrowed one. The badge
      # labels a door onto screen 10, and screen 10 shows the queue whole — a
      # genre filter that made the tile read `4` over a page of eight would be
      # the tile disagreeing with the screen it opens.
      queued: queued(),
      menu?: false
    )
  end

  @doc """
  Coming back to the shelf after something was written above it.

  See `Kati.Screens.Resume`: a popped-to screen restores its saved socket, so
  a title added on screen 06 or 11 was not on the shelf until the dock
  re-mounted the page. Added *Emergence* from Discover, pressed back, and the
  header still read `6 titles · 5 in progress` over six posters — found on a
  Pixel 9a, which is the only place it shows.

  The reads only. `load/1` also sets `filter`, `shelf` and `menu?`, and those
  are the reader's: somebody who narrows to *Finished*, opens a title and comes
  back has not asked for the chip to go back to *All*, and re-running `load/1`
  wholesale would do exactly that. Screen 01 has no such state and reloads
  whole.
  """
  @impl true
  def handle_kati(:resumed, _payload, socket),
    do: {:noreply, Mob.Socket.assign(socket, titles: titles(), queued: queued())}

  @doc """
  The shelf the screen renders: the user's library, and only ever that.

  A delegation rather than a branch, and deliberately so — this is the function
  that used to answer `[]` with `drawn_titles/0`, and the whole of #91 is that
  it must not. `shelf/0` answers with nothing on a fresh install; `content/1`
  reads that nothing and draws screen 27's empty card, which is the state the
  design gives this screen rather than the absence of one.
  """
  @spec titles() :: [map()]
  def titles, do: shelf()

  @doc """
  How many titles are on the whole shelf, unfiltered, and being watched.

  What the *Up next* tile's badge counts. Read apart from `titles/0` because
  that one is narrowed by whatever screen 145 last stored, and this labels a
  door onto a screen that is not.
  """
  @spec queued() :: non_neg_integer()
  def queued do
    Kati.Library.ShelfFilters.resting()
    |> shelf()
    |> Enum.count(&(&1.status == :watching))
  end

  @doc """
  The Screen shelf, straight from `Kati.Media`.

  A fixed number of reads rather than an N+1: the tracked rows, then one query
  for every cache row they name and one for every tick logged against them. The
  cache is reached by `{source, source_id}` because that is what
  `Kati.Media.TrackedTitle` holds — a value pair, not a foreign key — so an
  evicted poster cannot take a tracked row down with it.

  **A row with no cached title reads `Untitled`, and this used to drop it.**
  The old rule was *a tile captioned `nil` is worse than a tile that is not
  there*, and it is right about `nil` and wrong about the alternative: `nil` is
  not the only answer an evicted cache has. `Untitled` is the one every other
  screen in this app already gives — `Kati.Screens.Inbox.show_title/1`,
  `Kati.Screens.Rating.title_of/1`, `Kati.Screens.SeriesSettings.title_of/1`,
  each with the same sentence about a cache wipe not orphaning the row that
  holds the user's own words.

  Dropping was found on a device the day screen 80's **Clear** pill was wired
  (MOVIES-AND-TV.md #102): clearing the cache — which that card promises Kati
  does on its own to anything older than six months — left three tracked
  titles, two watches, and a Library reading `0 titles · 0 in progress` over
  *No titles yet · Add one thing you are watching*. Every fact was intact and
  the one screen that shows them said the shelf was empty.

  A tile with no name is a poor tile. A library that says you have nothing is
  a lie, and it is the lie that tells somebody to add a title they already
  have.

  `Kati.Media.TrackedTitle`'s own `:shelf` action does the reading, once per
  kind, rather than a filter written out here: it is the action that resource
  names for "screens 03, 20 and 21", and it is where "keeps history, hides from
  shelf" is enforced. Excluding archived rows in the caller would put that rule
  in as many places as there are shelves, and the first one to forget it would
  show a row the user hid.

  Three reads are then re-sorted as one, because each answers `last_touched_at`
  descending within its own kind and this grid is one shelf, not three.
  """
  @spec shelf() :: [map()]
  def shelf(choice \\ Kati.Library.ShelfFilters.current()) do
    tracked =
      @screen_kinds
      |> Enum.flat_map(fn kind ->
        TrackedTitle
        |> Ash.Query.for_read(:shelf, %{kind: kind})
        |> Ash.read!()
      end)
      |> Enum.sort_by(& &1.last_touched_at, {:desc, DateTime})

    cached = cached_by_reference(tracked)
    ticks = ticks_by_title(tracked)
    seen = watches_by_title(tracked)
    rated = ratings_by_title(tracked)

    tracked
    |> Enum.map(
      &shaped(
        &1,
        Map.get(cached, {&1.source, &1.source_id}),
        Map.get(ticks, &1.id, 0),
        Map.get(seen, &1.id, 0),
        Map.get(rated, &1.id)
      )
    )
    |> Kati.Library.ShelfFilters.apply(choice)
  rescue
    # Same degradation `Kati.Calendars.Today` makes: a screen that cannot reach
    # its store draws the drawing rather than taking the activity down.
    _ -> []
  end

  # One query for every cache row the shelf names, keyed the way the tracked
  # rows reference it.
  defp cached_by_reference([]), do: %{}

  defp cached_by_reference(tracked) do
    ids = tracked |> Enum.map(& &1.source_id) |> Enum.uniq()

    CachedTitle
    |> Ash.Query.filter(source_id in ^ids)
    |> Ash.read!()
    |> Map.new(&{{&1.source, &1.source_id}, &1})
  end

  # The episode counter is DERIVED — `Kati.Media.TrackedTitle` is explicit that
  # `progress_episode` is a bookmark inside a season and the authority on how
  # much is watched is the set of ticks. Counted by distinct episode, so a
  # rewatch does not push a season past its own total.
  # The TITLE-level watches, which `ticks_by_title/1` deliberately excludes:
  # its filter is `not is_nil(episode_source_id)`, because an episode tick is
  # what makes a series' progress. A film has no episodes and its watch carries
  # no `episode_source_id`, so it was invisible to the shelf — a film you had
  # watched drew an empty rail and `0%` forever.
  defp watches_by_title([]), do: %{}

  defp watches_by_title(tracked) do
    ids = Enum.map(tracked, & &1.id)

    Watch
    |> Ash.Query.filter(tracked_title_id in ^ids and is_nil(episode_source_id))
    |> Ash.read!()
    |> Enum.group_by(& &1.tracked_title_id)
    |> Map.new(fn {id, watches} -> {id, length(watches)} end)
  rescue
    _error -> %{}
  end

  # `%{tracked_title_id => rating}` off the newest rated watch of each title.
  # Only title-level watches — an episode's rating is a rating of that episode.
  defp ratings_by_title([]), do: %{}

  defp ratings_by_title(tracked) do
    ids = Enum.map(tracked, & &1.id)

    Watch
    |> Ash.Query.filter(
      tracked_title_id in ^ids and is_nil(episode_source_id) and not is_nil(rating)
    )
    |> Ash.read!()
    |> Enum.group_by(& &1.tracked_title_id)
    |> Map.new(fn {id, watches} ->
      newest = Enum.max_by(watches, &(&1.watched_at || &1.inserted_at), DateTime)
      {id, newest.rating}
    end)
  rescue
    _error -> %{}
  end

  defp ticks_by_title([]), do: %{}

  defp ticks_by_title(tracked) do
    ids = Enum.map(tracked, & &1.id)

    Watch
    |> Ash.Query.filter(tracked_title_id in ^ids and not is_nil(episode_source_id))
    |> Ash.read!()
    |> Enum.group_by(& &1.tracked_title_id, & &1.episode_source_id)
    |> Map.new(fn {id, episodes} -> {id, episodes |> Enum.uniq() |> length()} end)
  end

  @doc """
  One tracked title in the shape the grid, the chips and the subtitle all read.

  `id` is the tracked row's own, and it is the only field here that is an
  identity rather than a caption: it is what a tapped tile carries to the screen
  it opens. `Kati.Library.Sample`'s rows do not pass through here and so do not
  have one, which is how `open_tile/3` tells a shelf tile from a drawn one.

  `cached` may be `nil` and `ticks` may be zero; both are ordinary states and
  neither is allowed to invent a number:

    * `title` is the cache's, and `nil` when there is no cache row — `shelf/0`
      drops those rather than drawing them.
    * `seed` is `poster_path`, which for a seeded sample title is the design's
      own picsum seed (`Kati.Seeds` writes it that way) and for a real one is a
      provider path `Kati.Design.Images.poster/1` will not find. Both degrade
      to the placeholder rectangle `artwork/1` already draws.
    * `progress` is a fraction or `nil`. For a series it is the tick count over
      `episode_count`, through `Kati.Media.CachedTitle.progress/2` so an
      unknown denominator answers `{:position, n}` and `ratio/1` answers `nil`
      rather than dividing by something that is not there. For a film there is
      no ring at all — `denominator/1` says so outright — so it is the resume
      point over the runtime, which is the ×60 screen 10 does in the open.
    * `status` is the user's own, and it is what the chips filter on:
      `Kati.Media.TrackedTitle` names `:not_started` and `:finished` as this
      screen's shelf filters.
  """
  @doc """
  A title's name, or what an evicted cache leaves behind.

  `Untitled` and not `nil`: see `shelf/1`. The rest of the row survives —
  the kind, the status, the ticks and the rating are all the tracked row's or
  the watches' — so the tile is a real title with a name Kati cannot currently
  say, which is what it is.

      iex> Kati.Screens.Library.name_of(nil)
      "Untitled"

      iex> Kati.Screens.Library.name_of(%{title: "Severance"})
      "Severance"
  """
  @spec name_of(map() | nil) :: String.t()
  def name_of(%{title: title}) when is_binary(title) and title != "", do: title
  def name_of(_evicted), do: "Untitled"

  @spec shaped(TrackedTitle.t(), CachedTitle.t() | nil, non_neg_integer(), non_neg_integer()) ::
          map()
  def shaped(tracked, cached, ticks, seen \\ 0, rating \\ nil) do
    %{
      # The row a tile opens. Carried on the shape rather than looked up again
      # in the tap handler, for the reason `Kati.Screens.Series` gives for
      # `tracked_id`: the title the user tapped and the title a second query
      # happens to return first are two different facts.
      id: tracked.id,
      title: Kati.Screens.Library.name_of(cached),
      seed: cached && cached.poster_path,
      # MOVIES-AND-TV.md #104's latent half. This asked `kind == :movie`, so an
      # anime FILM — which can exist now that something writes `:anime` —
      # would have opened the series screen and asked for its seasons. A film
      # is a film whatever else it is, and the cached row is what knows.
      kind: if(Kati.Media.Anime.film?(tracked.kind, cached), do: :film, else: :series),
      # WHICH kind, beside which SCREEN it opens. `:kind` above is the second
      # of those and has been since this screen was written — it answers
      # `:film` or `:series`, which is a route and not a fact about the title.
      # The Anime chip needs the fact (#8).
      media_kind: tracked.kind,
      status: tracked.status,
      progress: fraction_for(tracked, cached, ticks, seen),
      meta: meta_for(tracked, cached, ticks, seen),
      # Not for drawing. `Kati.Library.ShelfFilters` sorts and narrows on these
      # two, and screen 145 could do neither while a row carried only what the
      # tile needed — MOVIES-AND-TV.md #26.
      genres: cached && cached.genres,
      year: cached && cached.first_release_year,
      # The rating that STANDS, off the newest watch — `Kati.Media.TrackedTitle.rating`
      # has no writer anywhere in the app and screen 08 documents that at
      # length, so sorting the shelf by it would have sorted by zero.
      rating: rating || tracked.rating,
      runtime: cached && cached.runtime_minutes
    }
  end

  @doc """
  The line under a title on Home: `S2 · E6 · 18m left`, or as much of it as is
  true.

  Board 01 draws it under every *Continue watching* card and
  `Kati.Screens.Home.continue_watching_rows/0` hard-coded `meta: nil`, so the
  line could not appear however much a person watched — the card was a poster
  and a title over an empty gap. Built here rather than there because this is
  where the tracked row, the cached title and the ticks are already in hand,
  and a second gather on Home would be a second set of numbers able to
  disagree with the progress bar drawn beside it.

  **Every part is dropped when it is not known**, rather than guessed at:

    * A series says how far in you are — `S2 · E6` — from the ticks, which
      `Kati.Media.TrackedTitle` names as the authority. A series with nothing
      ticked says `S1 · E1`, because that is where you are about to be, and a
      series with no episodes cached says nothing at all.
    * A film says what is left of it, from `progress_seconds` against the
      cached runtime. With no resume point it says the runtime instead — `1h
      48m` is what a film you have not started has to tell you.
    * A title with neither answers `nil`, and `Kati.Screens.Home` draws no
      line, which is the state every card was stuck in before this.
  """
  @spec meta_for(TrackedTitle.t(), term(), non_neg_integer(), non_neg_integer()) ::
          String.t() | nil
  def meta_for(tracked, cached, ticks, seen \\ 0)

  def meta_for(%TrackedTitle{kind: :movie} = tracked, cached, _ticks, seen) do
    minutes = cached && cached.runtime_minutes
    seconds = tracked.progress_seconds

    cond do
      is_integer(minutes) and minutes > 0 and is_integer(seconds) and seconds > 0 ->
        left = max(minutes - div(seconds, 60), 0)
        "#{left}m left"

      seen > 0 and is_integer(minutes) and minutes > 0 ->
        "Watched · " <> Kati.Screens.Library.runtime_line(minutes)

      is_integer(minutes) and minutes > 0 ->
        Kati.Screens.Library.runtime_line(minutes)

      true ->
        nil
    end
  end

  def meta_for(%TrackedTitle{}, cached, ticks, _seen) do
    total = cached && cached.episode_count

    if is_integer(total) and total > 0 do
      done = min(ticks, total)
      "S1 · E#{min(done + 1, total)}"
    end
  end

  @doc """
  `1h 48m`, or `48m` for anything under the hour.

      iex> Kati.Screens.Library.runtime_line(108)
      "1h 48m"

      iex> Kati.Screens.Library.runtime_line(48)
      "48m"

      iex> Kati.Screens.Library.runtime_line(120)
      "2h"
  """
  @spec runtime_line(pos_integer()) :: String.t()
  def runtime_line(minutes) when minutes >= 60 do
    case rem(minutes, 60) do
      0 -> "#{div(minutes, 60)}h"
      rest -> "#{div(minutes, 60)}h #{rest}m"
    end
  end

  def runtime_line(minutes), do: "#{minutes}m"

  # A series divides ticks by the episode total; a film divides its resume point
  # by its runtime. Anything either half cannot answer is nil, never a guess.
  defp fraction_for(%TrackedTitle{kind: :movie} = tracked, cached, _ticks, seen) do
    seconds = tracked.progress_seconds
    minutes = cached && cached.runtime_minutes

    cond do
      # A resume point, when there is one. Nothing in the app writes
      # `progress_seconds` yet — there is no scrubber and no player — so this
      # is the branch a future one lands in rather than the branch that runs.
      is_integer(seconds) and seconds > 0 and is_integer(minutes) and minutes > 0 ->
        min(seconds / (minutes * 60), 1.0)

      # A film you have watched is a film you are through, and its rail says
      # so. It drew empty however many times somebody logged it, because the
      # only fraction a film had was a resume point nothing sets.
      seen > 0 ->
        1.0

      true ->
        nil
    end
  end

  defp fraction_for(%TrackedTitle{}, cached, ticks, _seen) do
    cached |> CachedTitle.progress(ticks) |> CachedTitle.ratio()
  end

  @doc """
  The nine titles `test/design/screens/03.html` draws, in its own order.

  **No longer reachable from a render.** It was `titles/0`'s empty-shelf
  answer until #91; it is now what the drawing was captured from and the
  fixture the shelf tests build a full grid out of, and nothing on a device
  reaches it. See the moduledoc for why an empty shelf draws screen 27's card
  instead.

  Stand-in data, and marked as such — `Kati.Library.Sample`'s moduledoc says so
  at length. What is NOT stand-in is the set of states: three titles not
  started, four part-watched and two finished, which is every chip the design
  draws and every branch of `tile_meta/1`.

  Each row is given the `status` a real one carries, so `visible/3`,
  `chip_counts/1` and `subtitle/1` ask one question of both kinds of row and
  cannot answer it two different ways.
  """
  @spec drawn_titles() :: [map()]
  def drawn_titles, do: Enum.map(Sample.titles(), &with_status/1)

  # The Sample rows predate `Kati.Media.TrackedTitle` and carry a fraction where
  # a real row carries a status. The mapping is the one the chips used to make
  # inline — 0 is not started, 1 is finished, anything between is watching — so
  # the counts and the filtered grid are unchanged to the pixel.
  defp with_status(%{progress: progress} = row) do
    status =
      cond do
        progress <= 0.0 -> :not_started
        progress >= 1.0 -> :finished
        true -> :watching
      end

    Map.put(row, :status, status)
  end

  @doc false
  def content(assigns) do
    filter = assigns.filter
    titles = assigns.titles

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={132}
      >
        {Kati.Screens.Library.header(titles, assigns.menu?)}
        {Kati.Screens.Library.segments("Screen")}
        {Kati.Screens.Library.quick_tiles(Map.get(assigns, :queued, length(titles)))}
        {Kati.Screens.Library.shelf_body(filter, titles)}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The shelf half of the page: the chips over the grid, or screen 27's card.

  The branch is on the shelf being empty and not on the *filter* leaving
  nothing visible. A filter that matches none of a real shelf draws an empty
  grid under live chips, exactly as it did before — the design draws no state
  for it, `visible/3` already answers `[]`, and the four counts beside the
  chips say which one to tap next. Putting *No titles yet* under a shelf that
  holds nine would be a second lie in place of the first.
  """
  @spec shelf_body(String.t(), [map()]) :: map() | [map()]
  def shelf_body(_filter, []), do: Kati.Screens.Library.empty_state()

  def shelf_body(filter, titles) do
    [
      Kati.Screens.Library.chips(filter, titles),
      Kati.Screens.Library.grid(filter, titles)
    ]
  end

  @doc """
  Screen 27's `Empty — nothing added yet` card, which is this screen's own.

  Built to `test/design/screens/27.html`, band one: a 64pt paper square
  holding `movie` at `Kati.Theme.Palette.rail_idle/0`, the 17pt sentence, the
  13pt paragraph at `line_height: 1.55`, a 44pt ink pill carrying `add` and a
  13pt label, and a 12.5pt semibold line under it. Every number here is that
  band's, not screen 105's or 139's — those two draw the same *recipe* at 17pt
  of padding around a 54pt pill with no glyph, and `Kati.Screens.HomeEmpty`
  and `Kati.Screens.GoalsEmpty` each write their own card out for exactly that
  reason. This one is written out for the opposite reason: the numbers are
  `Kati.Screens.States.empty/1`'s to the point, and the one thing that differs
  is the one thing that matters here.

  **The difference is the taps.** Screen 27 is a reference sheet and its own
  moduledoc is explicit that each card is *a picture of a state, not a report
  that the app is in it*; a specimen that navigated would be a specimen that
  left the sheet. Here the card is the state, and screen 96 says what a state
  in it owes the person looking at it — *"say what is missing and offer the
  one thing that fixes it"*. A drawn pill that answered nothing would be the
  half of this fix that shipped as decoration, so both lines are wired:
  `Add a title` opens `Kati.Screens.AddTitle`, the sheet that writes a
  `Kati.Media.CachedTitle` and a `Kati.Media.TrackedTitle` and is therefore
  the one control on the page that can end this state.

  `or import a backup` carries a tap for the reason
  `Kati.Screens.HomeEmpty.restore_link/0` gives for its own near-identical
  line: it names a screen this board does not draw, and screen 139's caption
  calls the pair *"one ink action, one quiet alternative"* — two actions, not
  one action and a footnote. It pushes `Kati.Screens.Restore`, and inherits
  that screen's `‹ Settings` back pill, the papercut `Kati.Screens.HomeEmpty`
  records rather than solving with a third copy of the screen.
  """
  @spec empty_state() :: map()
  def empty_state do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Theme.shadow_card_soft()}
        padding_left={22}
        padding_right={22}
        padding_top={30}
        padding_bottom={30}
      >
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          <Box width={64} height={64} corner_radius={20} background={Palette.paper()} align="center">
            {Kati.UI.symbol("movie", size: 28, color: Palette.rail_idle())}
          </Box>
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={18} />
        <Text
          text="No titles yet"
          text_size={17}
          font_weight="bold"
          letter_spacing={-0.02}
          text_align="center"
          text_color={:on_surface}
        />
        <Spacer size={8} />
        <Text
          text="Add one thing you are watching and the calendar starts filling itself."
          text_size={13}
          line_height={1.55}
          text_align="center"
          text_color={Palette.sub()}
        />
        <Spacer size={18} />
        {Kati.Screens.Library.add_a_title()}
        <Spacer size={14} />
        {Kati.Screens.Library.import_link()}
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  The ink pill: 44 tall, radius 22, `add` at 18 then the label at 13 bold.

  A `<Row>` rather than a `<Box>` with one child, because the drawing puts a
  glyph before the label with a 7pt gap and a Box is a Z-stack — the glyph
  would paint over the words rather than sit beside them.
  """
  @spec add_a_title() :: map()
  def add_a_title do
    ~MOB"""
    <Row
      fill_width={true}
      height={44}
      corner_radius={22}
      background={Palette.ink_fill()}
      align="center"
      on_tap={{self(), :add_title}}
    >
      <Spacer weight={1.0} />
      {Kati.UI.symbol("add", size: 18, color: Palette.on_ink())}
      <Spacer size={7} />
      <Text
        text="Add a title"
        text_size={13}
        font_weight="bold"
        text_color={Palette.on_ink()}
        max_lines={1}
      />
      <Spacer weight={1.0} />
    </Row>
    """
  end

  @doc "The quiet alternative under the pill. See `empty_state/0` for why it taps."
  @spec import_link() :: map()
  def import_link do
    ~MOB"""
    <Column fill_width={true} on_tap={{self(), :import_backup}}>
      <Text
        text="or import a backup"
        text_size={12.5}
        font_weight="semibold"
        text_align="center"
        text_color={Palette.sub()}
      />
    </Column>
    """
  end

  @doc """
  The header's mono subtitle: `9 titles · 4 in progress`.

  Counted off the shelf rather than off `Kati.Library.Sample`, so the line and
  the grid under it can never disagree about how many titles there are.
  """
  @spec subtitle([map()]) :: String.t()
  def subtitle(titles) do
    "#{length(titles)} titles · #{Enum.count(titles, &(&1.status == :watching))} in progress"
  end

  @doc """
  The mono line under *Library*, drawn on every shelf including no shelf.

  It reads `0 titles · 0 in progress` on a fresh install, and it was withheld
  there for one round on screen 96's rule — *"never render a plausible-looking
  zero"*. That was an inference and the drawing outranks it: `03.html` puts an
  11pt mono line 5pt under the 28pt title, and `Kati.ScreenTitleSubtitleTest`
  reads that pair off the board as a specification rather than a suggestion.
  Withholding it does not leave a gap either — the parser walks the flattened
  tree, so the next `Text` is the `search` disc's glyph and the screen reports
  a 21pt symbol where the board asks for an 11pt mono. Measured, not guessed.

  The four filter chips are a different case and stay withheld on an empty
  shelf: the board templates them (`{{ t.label }}`, `{{ t.count }}`), so no
  drawn value is being dropped, and four counts of zero over a card that says
  there is nothing here is exactly what screen 96 draws hiding.
  """
  @spec subtitle_line([map()]) :: [map()]
  def subtitle_line(titles) do
    subtitle = Kati.Screens.Library.subtitle(titles)

    [
      ~MOB"<Spacer size={5} />",
      ~MOB"""
      <Text
        text={subtitle}
        font_family="mono"
        text_size={11}
        text_color={Palette.muted()}
        max_lines={1}
      />
      """
    ]
  end

  @doc false
  def header(titles, menu?) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Column weight={1.0}>
          <Text
            text="Library"
            text_size={28}
            max_font_scale={1.6}
            font_weight="bold"
            letter_spacing={-0.03}
            text_color={:on_surface}
          />
          {Kati.Screens.Library.subtitle_line(titles)}
        </Column>
        {Kati.Screens.Library.disc("search", :open_search)}
        <Spacer size={9} />
        {Kati.Screens.Library.disc("sort", :open_sort)}
        <Spacer size={9} />
        {Kati.Screens.Library.menu(menu?)}
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  # Chelekom's headless Action Icon. See screen 02's `disc/2` for why `shadow`
  # is the prop that unblocked this: a filled disc with no lift is a flat patch
  # of card white on paper, and the drawing's whole affordance is that it floats.
  #
  # `shape: :circle` gives `44 / 2` = 22.0 where the Box said 22 — `floatProp`
  # reads both as 22.0f. The glyph is a child so `Kati.UI.symbol/2` keeps
  # supplying the Material Symbol at 21; the component's `<Row>` wrapper hugs
  # that single `<Text>` and is centred by the same `Alignment.Center`.
  @doc """
  The ⋯ disc, and the only thing behind it.

  A third disc beside search and sort, which screen 03's drawing does not
  draw — the one addition to a resting screen in this change, and it is here
  because screen 13's own back pill reads `‹ Library` and no control on 03
  could open it. The alternative was leaving a finished screen unreachable
  forever, or hanging it off `sort`, which promises an ordering and would
  deliver a recommender.

  One item, so the panel is small on purpose. It grows when 03 grows, and it
  has: the two below are #94's doing.

  ## The one that joined it, and what it is waiting for

  `Kati.Screens.ShelfSelection` is a finished screen whose drawn entry does not
  exist: 146's is a **long press** on a poster tile, and 04 uses that gesture
  for something else without either board drawing it. It is here for the reason
  the ⋯ disc itself is here, in the paragraph above — the alternative was
  leaving a finished screen unreachable forever. #94 asked for the developer
  gallery to be deleted, and deleting it without this row would have made a
  working screen dead code.

  **It is a placeholder for a drawing.** When a long press on a tile is drawn,
  `ShelfSelection` moves to it and comes out of this menu. Until then a menu row
  is the honest door — it is reachable, it is named, and it does not pretend to
  be the gesture the design intends.

  ## `Filter shelf` left, and the sort disc is why — MOVIES-AND-TV.md #109

  145's caption names *"a trailing filter disc in the header of screens 03, 20
  and 21"*, and this module used to record that none of the three boards has
  one. Board 03 has the next thing to it: a `sort` disc, in that header,
  trailing the title, which has opened `Kati.Screens.ShelfFilters` since the
  shelf could be sorted at all. The board draws exactly two discs — `search`
  and `sort` — and a *filter* disc beside a *sort* disc opening the same sheet
  would be two doors into one room from one wall.

  So the finding's second option is the one taken: the sort disc is the
  permanent entry, and the duplicate menu row is gone. One door, and it is the
  one the board draws.
  """
  def menu(open?) do
    Kati.UI.Menu.overflow(
      Kati.Screens.Library.disc("more_horiz", :toggle_menu),
      open?,
      [
        Kati.UI.Menu.item("schedule", "What fits?", :open_what_fits),
        Kati.UI.Menu.item("checklist", "Select titles", :open_shelf_selection)
      ],
      dismiss: :close_menu
    )
  end

  @doc false
  def disc(icon, tag) do
    MishkaActionIcon.action_icon(
      [
        size: 44,
        shape: :circle,
        variant: :filled,
        background: Palette.card(),
        shadow: Theme.shadow_button(),
        on_tap: tag
      ],
      [Kati.UI.symbol(icon, size: 21)]
    )
  end

  @doc false
  def segments(active) do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.placeholder()}
        corner_radius={18}
        padding={4}
        align="center"
      >
        {Kati.Screens.Library.kept_segments(active)}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  # NOT Chelekom's Segmented Control, and it is worth writing down why so the
  # next pass does not re-derive it. The component is otherwise a close fit —
  # `track_padding`, `segment_height`, `segment_radius`, `font_weight` +
  # `selected_weight`, `segment_weight` for the `flex:1` cells, even a
  # `selected_shadow` — but two things the drawing does are not expressible:
  #
  #   1. **Each segment carries an icon.** `option/3` builds
  #      `%{props: %{id:, label:, disabled:}}` and `segment/3` renders it as a
  #      Box holding one `<Text>` the control paints itself. The drawing puts a
  #      17px Material Symbol before each 13px label with a 6px gap
  #      (`03.html:16-28`). There is no leading slot, and the label is a prop
  #      rather than children precisely because the control owns that Text.
  #   2. **`gap:4px` between segments.** `track/3` emits `<Row>{segments}</Row>`
  #      with nothing interspersed and there is no `segment_gap` prop; the
  #      segments would abut. Nor can the gap be smuggled in as a child —
  #      `segmented_control/2` filters children to
  #      `match?(%{type: :mishka_segmented_control_option}, &1)` and drops the
  #      rest, so an interspersed `<Spacer>` is discarded rather than laid out.
  #
  # Either alone would move pixels, so the strip stays hand-rolled. Both are
  # upstream asks: a leading slot on an option, and a gap between segments.
  @doc """
  One segment per section you kept.

  The design's rule is that turning a section off removes it everywhere at
  once — the home card, the calendar feed and the shelf together — so a shelf
  switcher that always offered three tabs was the shelf half of that rule going
  unenforced. Someone who kept only Screen was still offered Books and Music,
  both leading to a shelf that could never hold anything.

  The separators are interspersed rather than written between fixed segments,
  because with one section kept there is no gap to draw and with three there
  are two.
  """
  @spec kept_segments(String.t()) :: [map()]
  def kept_segments(active) do
    [
      {"screen", "movie", "Screen"},
      {"books", "menu_book", "Books"},
      {"music", "graphic_eq", "Music"}
    ]
    |> Enum.filter(fn {id, _icon, _label} -> Kati.Sections.on?(id) end)
    |> Enum.map(fn {_id, icon, label} ->
      Kati.Screens.Library.segment(icon, label, active == label)
    end)
    |> Enum.intersperse(Kati.Screens.Library.segment_gap())
  end

  @doc false
  def segment_gap, do: ~MOB"<Spacer size={4} />"

  @doc false
  def segment(icon, label, on?) do
    tap = {self(), String.to_atom("shelf_" <> label)}
    bg = if on?, do: Palette.card(), else: Palette.transparent()
    fg = if on?, do: Palette.ink(), else: Palette.segment_idle()
    weight = if on?, do: "bold", else: "semibold"

    ~MOB"""
    <Box weight={1.0}>
      <Row
        fill_width={true}
        height={38}
        corner_radius={14}
        background={bg}
        align="center"
        on_tap={tap}
      >
        <Spacer weight={1.0} />
        {Kati.UI.symbol(icon, size: 17, color: fg)}
        <Spacer size={6} />
        <Text text={label} text_size={13} font_weight={weight} text_color={fg} max_lines={1} />
        <Spacer weight={1.0} />
      </Row>
    </Box>
    """
  end

  @doc false
  def quick_tiles(queued) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {Kati.Screens.Library.quick_tile("playlist_play", "Up next", Kati.Screens.Library.up_next_badge(queued), :open_up_next)}
        <Spacer size={9} />
        {Kati.Screens.Library.quick_tile("explore", "Discover", nil, :open_discover)}
        <Spacer size={9} />
        {Kati.Screens.Library.quick_tile("bookmarks", "Lists", nil, :open_lists)}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc """
  The count on the *Up next* tile, or `nil` when there is nothing next.

  The tiles stay on an empty shelf and this moduledoc argues why. What could
  not stay is their **counts**: `12` and `7` were the board's own numbers,
  written out, so a phone that had tracked nothing announced twelve things to
  watch and seven lists above a card whose whole job is to say the shelf is
  empty. That is the same lie #91 took the nine invented films off this screen
  for, in two smaller numbers, and it is what the owner saw first on a real
  install.

  The filter chips two paragraphs down were withheld for a weaker version of
  the same reason — `All 0 · Watching 0` would be noise — and that argument
  ends *"nothing is invented in their place"*. The counts above them were.

  `nil` rather than `0`: the tile draws no badge for `nil`, which is what
  Discover has always passed, so an empty shelf gets the drawing's own
  no-count tile rather than a zero the board never draws.

  **Lists gets `nil` unconditionally.** There is no list resource anywhere in
  `lib/kati` — `Kati.Screens.Lists` assigns `Sample.lists/0` outright — so
  there is no number to be right. A count invented for a feature with no store
  behind it cannot become true by being recomputed.

      iex> Kati.Screens.Library.up_next_badge([])
      nil

      iex> Kati.Screens.Library.up_next_badge([%{status: :watching}, %{status: :finished}])
      "1"
  """
  @spec up_next_badge([map()]) :: String.t() | nil
  def up_next_badge(queued) when is_integer(queued) do
    if queued == 0, do: nil, else: Integer.to_string(queued)
  end

  def up_next_badge(titles) when is_list(titles),
    do: up_next_badge(Enum.count(titles, &(&1.status == :watching)))

  @doc false
  def quick_tile(icon, label, count, tag) do
    tap = {self(), tag}

    ~MOB"""
    <Box weight={1.0} on_tap={tap}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={16}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={11}
        padding_right={11}
        padding_top={12}
        padding_bottom={12}
      >
        <Row fill_width={true} align="center">
          {Kati.UI.symbol(icon, size: 19)}
          <Spacer weight={1.0} />
          {Kati.Screens.Library.tile_count(count)}
        </Row>
        <Spacer size={10} />
        <Text
          text={label}
          text_size={12.5}
          font_weight="bold"
          letter_spacing={-0.01}
          text_color={:on_surface}
          max_lines={1}
        />
      </Column>
    </Box>
    """
  end

  @doc false
  def tile_count(nil), do: ~MOB"<Spacer size={0} />"

  def tile_count(count) do
    ~MOB"""
    <Text
      text={count}
      font_family="mono"
      text_size={10}
      text_color={Palette.rail_idle()}
      max_lines={1}
    />
    """
  end

  @doc """
  The four filter chips with their counts, in the drawing's order.

  The counts are of the shelf, and they read `status` rather than a fraction:
  `Kati.Media.TrackedTitle` names `:not_started` and `:finished` as this
  screen's shelf filters, and `:watching` is the status the design's `4 in
  progress` is counting. A shelf holding `:paused` or `:dropped` rows therefore
  has sub-counts that do not add up to `All`, which is the truth — those rows
  are in the library and in none of the three named states.
  """
  @spec chip_counts([map()]) :: [{String.t(), non_neg_integer()}]
  def chip_counts(titles) do
    anime = Enum.count(titles, &(Map.get(&1, :media_kind) == :anime))

    [
      {"All", length(titles)},
      {"Watching", Enum.count(titles, &(&1.status == :watching))},
      {"Not started", Enum.count(titles, &(&1.status == :not_started))},
      {"Finished", Enum.count(titles, &(&1.status == :finished))}
    ] ++ Kati.Screens.Library.anime_chip(anime)
  end

  @doc """
  A fifth chip, once there is enough anime on the shelf to want one.

  Board 152's own rule, in the board's own words: *the tab-row chip appears at
  10 or more anime titles*. `Kati.Media.AnimeSample.promote_threshold/0` is
  where the number lives and this reads it rather than typing a second copy,
  so moving it moves both.

  MOVIES-AND-TV.md #8 asked for the argument to become the feature, and this
  is the feature half: 152 draws a chip appearing on a shelf; this is the
  shelf. The other half is #104 — something that writes `:anime` at all, which
  is `Kati.Media.Anime`'s three rules.

  Below the threshold it is dropped rather than drawn empty, which is why the
  rule exists: a `0` chip on a shelf with no anime on it is a section nobody
  asked for.

      iex> Kati.Screens.Library.anime_chip(12)
      [{"Anime", 12}]

      iex> Kati.Screens.Library.anime_chip(3)
      []
  """
  @spec anime_chip(non_neg_integer()) :: [{String.t(), non_neg_integer()}]
  def anime_chip(count) do
    if count >= Kati.Media.AnimeSample.promote_threshold(), do: [{"Anime", count}], else: []
  end

  @doc false
  def chips(active, titles) do
    ~MOB"""
    <Column fill_width={true}>
      <Scroll axis="horizontal">
        <Row>
          {Kati.Screens.Library.chip_counts(titles)
           |> Enum.map(fn {label, count} ->
             Kati.Screens.Library.chip(label, count, label == active)
           end)
           |> Enum.intersperse(Kati.Screens.Library.chip_gap())}
        </Row>
      </Scroll>
      <Spacer size={20} />
    </Column>
    """
  end

  # Chelekom's headless Chip, count and all. The count is what made this chip
  # need the component's `trailing` SLOT rather than its `trailing` string: the
  # drawing sets it in DM Mono at 10.5, and the component paints a string
  # trailing in the chip's own family and size. A slot takes a node as readily
  # as a glyph, so `chip_count/2` supplies the exact `<Text>` this screen drew.
  #
  # The tree gains one level and loses nothing:
  #
  #   was  <Row height={32} corner_radius={16} background padding_left={14}
  #             padding_right={14} align="center" on_tap>
  #          <Text label 12.5 semibold /> <Spacer size={6} /> <Text count mono />
  #        </Row>
  #
  #   now  <Box fill_width={false} height={32} … align="center" on_tap>
  #          <Row align="center">
  #            <Text label 12.5 semibold /> <Spacer size={6} /> <Text count mono />
  #          </Row>
  #        </Box>
  #
  # Width: the Box hugs (K-17 reads `fill_width={false}` now), so it measures
  # 14 + Row + 14, and the Row hugs to label + 6 + count — the same total the
  # padded Row measured on its own.
  #
  # Height: centring composes. The inner Row carries no height, so it hugs to
  # its tallest child and centres both Texts on ITS midline; the Box then
  # centres that Row inside the declared 32. Each label's box therefore lands
  # on the same midline it landed on when the Row itself was 32 tall with
  # `CenterVertically` — the intermediate container is transparent to the
  # arithmetic precisely because it hugs.
  #
  # `align="center"` on the inner Row is also what the bridge would have done
  # unasked: `rowAlignProp` DEFAULTS to `CenterVertically`, and only "top" and
  # "bottom" move it.
  @doc false
  def chip(label, count, on?) do
    # The design puts the count at .65 opacity of the label colour rather than
    # a separate token, so it stays legible on both chip states.
    count_fg = if on?, do: Palette.on_ink_count_soft(), else: Palette.count_idle_soft()

    MishkaChip.chip(
      label: label,
      checked: on?,
      # The tag carries the label, so one handler serves every chip and adding
      # a filter needs no new clause.
      on_toggle: String.to_atom("filter_" <> label),
      trailing: Kati.Screens.Library.chip_count(count, count_fg),
      trailing_gap: 6,
      height: 32,
      padding_x: 14,
      padding_y: 0,
      corner_radius: 16,
      text_size: 12.5,
      font_weight: :semibold,
      max_lines: 1,
      color: Palette.ink_fill(),
      text_color: Palette.on_ink(),
      unchecked_color: Palette.card(),
      unchecked_text_color: Palette.ink_soft()
    )
  end

  # The count, as its own node rather than as the chip's `trailing` string: a
  # string would inherit the chip's `text_size` and its sans family, and the
  # drawing sets this line in DM Mono at 10.5.
  @doc false
  def chip_count(count, color) do
    ~MOB"""
    <Text text={"#{count}"} font_family="mono" text_size={10.5} text_color={color} max_lines={1} />
    """
  end

  # The drawing's `gap:7px` sits BETWEEN chips. It used to be a trailing Spacer
  # inside each chip, which is not the same thing twice over: every chip
  # measured 7 wider than the design's `padding:0 14px`, and the row had no gap
  # at all — the chips only looked separated because their own right padding
  # had grown to 21.
  @doc false
  def chip_gap, do: ~MOB"<Spacer size={7} />"

  # Three across, because that is the design's wrap. The width each tile gets is
  # left to the weights in poster/1 — see the moduledoc.
  @doc false
  def grid(filter, titles) do
    case Kati.Screens.Library.visible(titles, filter) do
      [] -> Kati.Screens.Library.nothing_here(filter)
      shown -> Kati.Screens.Library.tiles(Enum.chunk_every(shown, 3))
    end
  end

  @doc false
  def tiles(rows) do
    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(rows, fn row -> Kati.Screens.Library.grid_row(row) end)}
    </Column>
    """
  end

  @doc """
  A chip that leaves nothing, saying so.

  `grid/3` rendered an empty `Column` for an empty list, so tapping a chip that
  matched nothing left a blank space under live chips with no card and no
  explanation — and until something in the app could set a status, *Not
  started* and *Finished* matched nothing on every device, so that blank was
  what every reader got from either. MOVIES-AND-TV.md #37.

  ## There was a fifth wording, for a state this screen cannot be in

  A `shelf != "Screen"` clause said *Kati holds films and shows for now. Books
  comes later.* — MOVIES-AND-TV.md #122 found it unreachable, and it is: the
  Books and Music segments PUSH screens 20 and 21, so the `:shelf` assign the
  clause guarded on could only ever hold `"Screen"`. The assign, its writer and
  the two clauses that read it are gone rather than kept as a state nothing can
  produce; screens 20 and 21 are where a reader who presses Books lands, and
  what to say to them there is their own screens' business.
  """
  # A sentence per chip rather than the chip's own label in a frame. `Nothing
  # not started` reads as a double negative and `No title on your shelf is not
  # started right now` is worse; each of the three says its own thing, and the
  # second line says what would put a title there.
  @spec nothing_here(String.t()) :: map()
  def nothing_here("Watching"),
    do:
      nothing_card(
        "Nothing on the go",
        "Log a watch or tick an episode and the title moves here."
      )

  def nothing_here("Not started"),
    do:
      nothing_card(
        "Everything here is started",
        "A title you add and have not watched yet waits in this one."
      )

  def nothing_here("Finished"),
    do:
      nothing_card(
        "Nothing finished yet",
        "A film you log a watch of, or a series whose last episode you tick, lands here."
      )

  def nothing_here("Anime"),
    do:
      nothing_card(
        "No anime on the shelf",
        "Kati flags one from its genre and origin, or from a MAL or AniList import — " <>
          "and you can say so yourself from a title's ⋯ menu."
      )

  def nothing_here("Anime"),
    do:
      nothing_card(
        "No anime on the shelf",
        "Kati flags one from its genre and origin, or from a MAL or AniList import — " <>
          "and you can say so yourself from a title's \u22EF menu."
      )

  def nothing_here(filter),
    do: nothing_card("Nothing #{String.downcase(filter)}", "No title on your shelf matches.")

  @doc false
  def nothing_card(title, body) do
    assigns = %{title: title, body: body}

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        padding={15}
        shadow={Kati.Theme.shadow_card_soft()}
      >
        <Spacer size={4} />
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          <Box width={44} height={44} corner_radius={14} background={Palette.paper()} align="center">
            {Kati.UI.symbol("movie", size: 21, color: Palette.rail_idle())}
          </Box>
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={12} />
        <Text
          text={@title}
          text_size={13.5}
          font_weight="bold"
          text_color={:on_surface}
          text_align="center"
        />
        <Spacer size={6} />
        <Text
          text={@body}
          text_size={12}
          line_height={1.55}
          text_color={Palette.sub()}
          text_align="center"
        />
        <Spacer size={4} />
      </Column>
    </Column>
    """
  end

  @doc """
  The titles a filter leaves visible.

  It used to take a shelf as well, and answer `[]` for anything but `Screen` —
  a branch nothing could reach, because Books and Music push their own screens
  rather than swapping this grid (MOVIES-AND-TV.md #122). `shelf/0` never asks
  for `:book` or `:album` for the same reason: #60 settled that v1 ships one
  media domain.

  The chips read `status`, not a fraction — see `chip_counts/1`.
  """
  @spec visible([map()], String.t()) :: [map()]
  def visible(titles, filter) do
    case filter do
      "Watching" -> Enum.filter(titles, &(&1.status == :watching))
      "Not started" -> Enum.filter(titles, &(&1.status == :not_started))
      "Finished" -> Enum.filter(titles, &(&1.status == :finished))
      # Board 152's chip, over rows that can carry the flag at last (#8, #104).
      "Anime" -> Enum.filter(titles, &(Map.get(&1, :media_kind) == :anime))
      _all -> titles
    end
  end

  # A short last row must still be padded to three. Weights divide whatever is
  # there, so a row holding one poster gives it the full width and the grid
  # ends with one enormous tile — which is what "4 titles" looked like.
  @doc false
  def grid_row(row) do
    row = row ++ List.duplicate(nil, 3 - length(row))

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {row |> Enum.map(&Kati.Screens.Library.poster/1) |> Enum.intersperse(Kati.Screens.Library.grid_gap())}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc """
  One grid tile's tag: which screen it opens, and which title it is.

  `:open_film` and `:open_series` alone were a kind, not an identity — every
  film on the shelf drew the same tag, so `Mob.Renderer` gave every film tile
  the same `accessibility_id` and `onNodeWithTag` throws on the second match.
  #97 quotes this screen's own comment predicting it would collide "as soon as
  a shelf holds two of a kind", and it has since it was written.

  It survived the ratchet because the shelf is empty in every test: with no
  rows there are no tiles, and a collision that needs two tiles cannot be seen.
  Nothing about that made it not happen on a phone with two films on it.

  ## The id, where there is one — MOVIES-AND-TV.md #121

  The title was the identity and it is not one. `String.replace(" ", "_")`
  makes *Low Water* and *Low_Water* one tag, so a shelf holding both collapsed
  them onto one tap target and the first match won — the same collision class
  #97 fixed one level up, one level down. And `String.to_atom/1` on a
  provider-supplied title mints an atom per distinct title, none of which the
  VM ever reclaims.

  The tracked row's id is unique by construction and bounded by the shelf, so
  it is the identity now. The title stays as the fallback for a row that has
  no id — `Kati.Library.Sample`'s nine, and every drawing that reuses this —
  because a tile still has to be nameable when the store is not behind it.

      iex> Kati.Screens.Library.poster_tag(%{kind: :film, title: "Low Water"})
      :open_film_Low_Water

      iex> Kati.Screens.Library.poster_tag(%{kind: :series, title: "The Long Hollow"})
      :open_series_The_Long_Hollow

      iex> Kati.Screens.Library.poster_tag(%{kind: :film, title: "", id: "abc-123"})
      :"open_film_abc-123"

      iex> Kati.Screens.Library.poster_tag(%{kind: :film, title: ""})
      :open_film
  """
  @spec poster_tag(map()) :: atom()
  def poster_tag(item) do
    base = if Map.get(item, :kind) == :film, do: "open_film", else: "open_series"

    case Kati.Screens.Library.tile_key(item) do
      "" -> String.to_atom(base)
      key -> String.to_atom(base <> "_" <> key)
    end
  end

  @doc """
  What names a tile: its id, or its title when it has none.

      iex> Kati.Screens.Library.tile_key(%{id: "abc", title: "Low Water"})
      "abc"

      iex> Kati.Screens.Library.tile_key(%{title: "Low Water"})
      "Low_Water"
  """
  @spec tile_key(map()) :: String.t()
  def tile_key(item) do
    case Map.get(item, :id) do
      id when is_binary(id) and id != "" ->
        id

      _none ->
        item
        |> Map.get(:title, "")
        |> to_string()
        |> String.trim()
        |> String.replace(" ", "_")
    end
  end

  @doc """
  Open `module` on the tile that carries `tag`.

  The tag is resolved back to its row by running `poster_tag/1` over the very
  list the grid was built from, rather than by reversing the string. That was
  first because the string could not be reversed — `poster_tag/1` replaced
  spaces with underscores — and it stays so now that it cannot either: a row
  with an id is named by the id and a row without one by its title, and the
  list is what knows which.

  A row with no id — `Kati.Library.Sample`'s nine, and a tag that matches
  nothing — pushes with **no params at all** rather than with `%{id: nil}`.
  That is `Kati.Screens.Calendar`'s rule for its own rows and its reason: a
  destination that pattern-matches on the key would otherwise take a `nil` for
  an answer, and the drawing's fallback is the branch that has to survive.
  """
  @spec open_tile(Mob.Socket.t(), atom(), module()) :: Mob.Socket.t()
  def open_tile(socket, tag, module) do
    row = Enum.find(socket.assigns.titles, &(Kati.Screens.Library.poster_tag(&1) == tag))

    # `:back` names the screen the reader is ON, so the pill on the page that
    # opens says where they came from rather than where that page assumes.
    # See `Kati.Screens.Pushed.back_label/2`: a film opened from here used to
    # offer to take somebody back to the Library.
    case row && Map.get(row, :id) do
      nil -> Mob.Socket.push_screen(socket, module, %{back: "Library"})
      id -> Mob.Socket.push_screen(socket, module, %{id: id, back: "Library"})
    end
  end

  @doc false
  def grid_gap, do: ~MOB"<Spacer size={12} />"

  @doc false
  def poster(nil), do: ~MOB"<Box weight={1.0} />"

  def poster(item) do
    # A film opens the film screen and a series the series screen — the design
    # draws them as two different screens, so the grid has to know which. The
    # title comes with it because two films are two nodes: see `poster_tag/1`.
    tap = {self(), Kati.Screens.Library.poster_tag(item)}

    # Weighted rather than 112 wide: three equal shares of the real content
    # width fill the row on any device, where a fixed 112 only fills the
    # drawing's frame.
    ~MOB"""
    <Column weight={1.0} on_tap={tap}>
      <Box
        fill_width={true}
        height={158}
        corner_radius={13}
        background={Palette.placeholder()}
        shadow={Kati.Theme.shadow_card_soft()}
      >
        {Kati.Screens.Library.artwork(item)}
        <Box fill_width={true} fill_height={true} align="bottom">
          {Kati.Screens.Library.progress(Kati.Screens.Library.fraction(item))}
        </Box>
      </Box>
      <Spacer size={9} />
      <Text
        text={item.title}
        text_size={12.5}
        font_weight="bold"
        letter_spacing={-0.01}
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer size={3} />
      <Text
        text={Kati.Screens.Library.tile_meta(item)}
        font_family="mono"
        text_size={10.5}
        text_color={Palette.muted()}
        max_lines={1}
      />
    </Column>
    """
  end

  @doc """
  The mono line under a grid title.

  The drawing carries one — `{{ it.meta }}`, DM Mono 10.5 in `#A9A29A`, 3
  under the title — and the grid was drawing the title and then stopping, so
  every cell sat ~16pt short of the frame and the rows closed up.

  The design templates the copy, so the wording is DERIVED from the two facts
  the shelf actually knows — the status the user set and how far in they are —
  rather than invented from nothing.

  Status comes first because it is an assertion and the fraction is an
  inference: a title the user marked finished says `finished` even when the
  cache row that would divide its ticks has been evicted. The last clause is
  the case a fraction cannot describe — `Kati.Media.CachedTitle.ratio/1`
  answered `nil` because nobody knows how many episodes there are — and it
  names the status instead of printing a percentage of an unknown total.
  """
  @spec tile_meta(map()) :: String.t()
  def tile_meta(%{status: :not_started}), do: "not started"
  def tile_meta(%{status: :finished}), do: "finished"
  def tile_meta(%{progress: p}) when is_float(p) and p > 0.0, do: "#{round(p * 100)}% watched"
  def tile_meta(%{status: :paused}), do: "paused"
  def tile_meta(%{status: :dropped}), do: "dropped"
  def tile_meta(_item), do: "watching"

  @doc """
  The `0.0..1.0` the rail burnt into a poster's bottom edge sweeps.

  `Kati.Media.CachedTitle.ratio/1` answers `nil` when there is no total to be a
  fraction of, and this screen has to draw *something* into a fixed 4pt rail —
  so an unknown fraction is drawn empty, and a title the user marked finished
  is drawn full even when its denominator was evicted. Nothing here invents a
  percentage: `tile_meta/1` above says `watching` rather than a number in
  exactly the case this returns `0.0`.
  """
  @spec fraction(map()) :: float()
  def fraction(%{progress: p}) when is_float(p), do: p
  def fraction(%{status: :finished}), do: 1.0
  def fraction(_item), do: 0.0

  # Real artwork, not a grey rectangle. `content_mode="fill"` crops to the
  # frame the way a poster does; without it Coil letterboxes and the card
  # develops margins the design does not have.
  #
  # `Kati.Design.Images.poster/1` rather than `Kati.Library.Sample.poster/1`
  # — the Sample function is a one-line delegation to it, and the shelf's own
  # seeds now arrive on `Kati.Media.CachedTitle.poster_path` (see `shaped/3`),
  # so routing a real row's artwork through the fixture module would be a lie
  # about where the value came from.
  @doc false
  def artwork(item) do
    case Kati.Design.Images.poster(item[:seed]) do
      nil ->
        ~MOB"<Spacer size={0} />"

      src ->
        ~MOB"""
        <Image src={src} fill_width={true} height={158} corner_radius={13} content_mode="fill" />
        """
    end
  end

  @doc """
  Burnt into the poster's bottom edge, not floated under it: a 4pt square track
  at 22% ink with an `#E8823C` fill. Orange here is "how far in you are", which
  is the design's one non-status use of it.

  Chelekom's headless Progress in `render: :box`. The native mode is Material's
  `LinearProgressIndicator`, and the two things this rail is made of are the
  two it does not expose: the track colour is `ProgressIndicatorDefaults`'
  `linearTrackColor` with no prop to reach it, and the caps belong to whichever
  material3 is pinned. So the shelf hand-rolled the two Boxes; `render: :box`
  draws exactly those, with the fraction arithmetic in one place.

  Both ends are ordinary on this grid — `tile_meta/1` has clauses for
  `not started` and `finished`, and the sample shelf reaches both (three tiles
  at 0.0, two at 1.0). The hand-rolled version needed a whole extra clause for the
  first and a guarded `progress_rest/1` for the second, because `1.0 -
  fraction` is a zero `weight` at 100% and Compose throws on it. The component
  omits whichever node would carry the zero, which draws the same nothing.
  """
  @spec progress(float()) :: map()
  def progress(fraction) do
    MishkaProgress.progress(
      render: :box,
      value: fraction,
      max: 1,
      height: 4,
      color: Palette.accent(),
      track_color: Palette.track_ink()
    )
  end

  @impl true
  # `query: ""` is the disc saying what it has, which is nothing typed. Bare,
  # the push said nothing at all and screen 19 fell through to
  # `Kati.Search.handed_over/0` — a DETS key nothing clears — so the Library's
  # disc opened somebody's last search, from a previous launch. `back:` because
  # 19's pill read `Home`, and Home is the one screen that does not open it.
  def handle_tap(:open_search, socket),
    do:
      {:noreply,
       Mob.Socket.push_screen(socket, Kati.Screens.Search, %{query: "", back: "Library"})}

  def handle_tap(:open_up_next, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.UpNext)}

  def handle_tap(:open_discover, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Discover)}

  def handle_tap(:open_lists, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Lists)}

  def handle_tap(:open_series, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Series)}

  def handle_tap(:open_film, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Film)}

  # The two controls on screen 27's empty card. Both only exist while the shelf
  # is empty, which is the only time either has anything to do.
  def handle_tap(:add_title, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.AddTitle)}

  def handle_tap(:import_backup, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Restore)}

  # One clause for every chip and every segment: the tag carries the label, so
  # a new filter is a data change rather than a code change.
  def handle_tap(:toggle_menu, socket),
    do: {:noreply, Mob.Socket.assign(socket, :menu?, not socket.assigns.menu?)}

  def handle_tap(:close_menu, socket),
    do: {:noreply, Mob.Socket.assign(socket, :menu?, false)}

  def handle_tap(:open_what_fits, socket) do
    {:noreply,
     socket
     |> Mob.Socket.assign(:menu?, false)
     |> Mob.Socket.push_screen(Kati.Screens.WhatFits)}
  end

  # The row #94 added. See `menu/1` for why it is a menu row rather than the
  # gesture the design intends, and for what takes it out of here.
  #
  # Its sibling `:open_shelf_filters` is gone: the sort disc in this screen's
  # own header has opened `Kati.Screens.ShelfFilters` all along, and a menu row
  # beside it was a second door into one sheet from one wall (#109).
  def handle_tap(:open_shelf_selection, socket) do
    {:noreply,
     socket
     |> Mob.Socket.assign(:menu?, false)
     |> Mob.Socket.push_screen(Kati.Screens.ShelfSelection)}
  end

  # Books and Music push their own shelves; Screen is the shelf you are already
  # on and only moves the assign. See the moduledoc for why the first two
  # stopped being inert.
  # The sort disc, which board 145 has drawn a destination for since the shelf
  # wave landed. Bare, like screens 20 and 21's: `shelf_filters.ex:79` is
  # `def mount(_params, _session, socket)` and its five sort rows come from
  # `Kati.Library.ShelfFiltersSample.sort_options/0`, where `Runtime` is a
  # literal — there is no key to name a shelf in, and writing one the sheet
  # does not read is an argument nobody can check. When 145 learns which shelf
  # opened it, all four pushes gain a third argument together.
  #
  # 145's caption names *screens 03, 20 and 21*, 03 first, so this disc and
  # 57's are the two that make the sheet what its own board says it is — and
  # since #109 this is the ONLY door on 03: the ⋯ menu's `Filter shelf` row
  # was a second one into the same sheet from the same header.
  def handle_tap(:open_sort, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.ShelfFilters)}

  def handle_tap(:shelf_Books, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Books)}

  def handle_tap(:shelf_Music, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Music)}

  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "filter_" <> label ->
        {:noreply, Mob.Socket.assign(socket, :filter, label)}

      # `shelf_Screen`, and only ever that: the other two segments have clauses
      # of their own that push. Pressing the segment you are on is how you
      # check you are on it, so it keeps its tap and changes nothing (#122).
      "shelf_" <> _screen ->
        {:noreply, socket}

      # Every grid tile, by its own title — see `poster_tag/1`. The two bare
      # tags above still have their own clauses because the drawing's own
      # single-tile states use them; these are the shelf's many.
      #
      # Answered here rather than in a clause of its own, which is where the
      # first attempt put it — above `:open_film` and `:add_title`, silently
      # making both unreachable. This screen's grid and its empty card are
      # never on screen together, so nothing would have shown it.
      "open_film_" <> _title ->
        {:noreply, Kati.Screens.Library.open_tile(socket, tag, Kati.Screens.Film)}

      "open_series_" <> _title ->
        {:noreply, Kati.Screens.Library.open_tile(socket, tag, Kati.Screens.Series)}

      _ ->
        {:noreply, socket}
    end
  end
end
