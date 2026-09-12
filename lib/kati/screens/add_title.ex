defmodule Kati.Screens.AddTitle do
  @moduledoc """
  Screen 06 — Add a title, reached from the `+` button.

  Built to `test/design/screens/06.html`, drawn mid-query on "quiet": the
  field carries a 2px ink ring and an orange caret, because the design shows
  the focused state rather than the resting one, and a screen that only draws
  its resting state is untested where it matters.

  The design's note says this is one sheet that will later add a book, an
  album or an event — "the type is inferred from what you pick". So the search
  and the result row are the parts to keep general; the chips are the part
  that will grow.

  Two controls, and the drawing settles the default state of both:
  `Everything` is the chip in ink and all four results are drawn under it, so
  `filter: "Everything"` reproduces the frame exactly while `Films` and
  `Series` narrow the list *and* the `4 RESULTS` eyebrow above it. The third
  result is drawn already added — a grey check where the others carry an ink
  `+` — so `added` is per-result state that the disc toggles both ways.

  **This should eventually be a native bottom sheet**, not a pushed screen:
  #45 settled that screens 06, 18 and 46 become Android sheets via a new
  `:sheet` node type. Until that lands it pushes, which is the same
  information in a different container.

  ## Why this screen still reads `Kati.Library.Sample`

  Screen 03 moved onto `Kati.Media` (see `Kati.Screens.Library.shelf/0`) and
  this one did not, for the reason `Kati.Screens.Series` states about its own
  list: the gap is a *source*, not a column. This sheet searches titles the
  user does **not** have, and Kati has nothing that can answer such a query.

  `Kati.Media.CachedTitle` is not that thing and must not be pressed into
  being it. It is a cache of titles something already fetched — its own
  moduledoc opens with "entirely evictable", `Kati.Seeds` fills it from the
  nine titles already on the shelf, and it carries no read action that matches
  on `title`. Searching it would answer with the library, which is the one set
  of titles this sheet exists to look outside of, and on the seeded database
  "quiet" matches none of the nine, so the screen would query, find nothing and
  fall back every time. A query that is ceremony reads as a query that works.

  Precisely what this screen draws and no resource can currently express:

    * **the results themselves** — nothing in `lib/` turns `quiet` into
      candidates. There is no provider search client, and no read action
      anywhere matches a title by name.
    * **`2019` / `2023`** in the meta line — a first-release year.
      `Kati.Media.CachedTitle` stores `next_release_at`, which is the NEXT
      release; this is the same missing column `Kati.Screens.Series` names for
      its own `2024`.
    * **`2 SEASONS` / `1 SEASON`** — a season count, and the one of these that
      is closing. `CachedTitle` holds `episode_count` and no season inventory,
      and `Kati.Media.TrackedTitle.progress_season` is a bookmark rather than a
      total, so neither can enumerate the seasons that exist;
      `Kati.Media.CachedSeason`, added this round, answers it with `count/1`.
      That changes nothing about whether this sheet can move, because a season
      count is a fact about a title already cached and these four are titles
      the cache has never seen.
    * **`Lumen+` / `Cinema` / `Northlight`** in the note line — availability.
      `Kati.Media.Watch.service` is where the *user* watched something, which
      is a different fact, recorded per watch and only after the fact — a
      search result has no watch yet.

  Three things here *are* expressible today and are deliberately not split
  out, because a row whose four values are half real and half frozen reads as
  fully real: `FILM` / `SERIES` is `Kati.Media.CachedTitle.kind`, `1h 48m` is
  `runtime_minutes`, and `Drama` / `Thriller` is `genres`.

  So is `added`, and it is the sharpest of the four.
  `Kati.Media.TrackedTitle`'s `:by_reference` action names *this screen* in its
  own comment — "screen 06 asks 'is this already in the library?' of a search
  result that only carries provider ids" — and it stays unused here for want of
  the ids. A result carries no `{source, source_id}` until a search client
  produces one, so the lookup has nothing to look up, and wiring it anyway
  would draw four ink `+` discs where the drawing draws three and a muted
  `check`. It lands with the search client, which is what will hand it a
  reference.
  """
  # Not `Kati.Screens.Pushed`: this screen has its own close button in the
  # header, and the pushed chrome would draw a second back affordance over the
  # title. The drawing has one dismissal, so the build has one.
  use Mob.Screen
  use Gettext, backend: Kati.Gettext
  import Mob.Sigil

  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaChip
  alias Kati.Theme
  alias Kati.Theme.Palette
  alias Kati.UI

  # `results` is the whole answer to the query and never shrinks — the chip
  # narrows the VIEW, so a title added under `Films` is still added when the
  # user goes back to `Everything`.
  def mount(params, _session, socket) do
    Mob.Theme.set(Kati.Theme.current())
    # Resolves the stored locale into THIS process. `Gettext.put_locale/2`
    # snapshots into the calling process exactly as `Mob.Theme.set/1` does,
    # and a screen is its own process — see `Kati.Locale.activate/0`.
    Kati.Locale.activate()
    # What the caller wanted looked up, if it named one. MOVIES-AND-TV.md #93:
    # screen 18's *Title* chip is a door onto this sheet, and a sheet that
    # opened blank after the reader had already typed the film's name is an
    # invitation to type it a second time.
    #
    # `query_epoch` starts at 1 rather than 0 when there is one, and that is
    # the whole of what makes the text appear: the bridge remembers the last
    # epoch it saw per field, so a `value` handed to a field it has already
    # drawn is ignored unless the epoch moves. See `K-46` in `native/LEDGER.md`.
    handed = Kati.Screens.AddTitle.opening_query(params)

    if handed != "", do: Kati.Media.SearchDebounce.ask(self(), handed)

    {:ok,
     Mob.Socket.assign(socket,
       # EMPTY, not the drawing's four. Board 06 is drawn mid-query and its
       # four results belong to that query; opening the sheet on them meant a
       # reader who had typed nothing was shown four invented films with real
       # poster images, a `4 results` caption, fabricated availability lines,
       # and one of them ticked as already in their library.
       # MOVIES-AND-TV.md #43. `resting_card/2` is what a sheet nobody has
       # typed into draws instead.
       results: [],
       filter: "Everything",
       query: handed,
       # Bumped when this screen REPLACES the field rather than echoing it —
       # see `clear_disc/0` and the `K-46 text-field-epoch` fence. It starts at
       # zero and the bridge remembers the last one it saw, so a mount is not
       # itself a replacement.
       query_epoch: if(handed == "", do: 0, else: 1),
       # Board 308's second band, from the first frame: a sheet handed a query
       # by screen 19's *Look it up* has a request in flight before it draws, so
       # it opens on the skeletons rather than on the empty card and then them.
       searching?: handed != "",
       save_error: nil,
       search_error: nil
     )}
  end

  @doc """
  The query a push named, trimmed, or `""`.

  Under the minimum it is still put in the field and simply not searched —
  the same floor `handle_info({:change, :title_query, …})` keeps. Two letters
  the reader typed are two letters they should not have to type again.

      iex> Kati.Screens.AddTitle.opening_query(%{query: "  Arrival "})
      "Arrival"

      iex> Kati.Screens.AddTitle.opening_query(%{})
      ""
  """
  @spec opening_query(map() | nil) :: String.t()
  def opening_query(params) do
    case Map.get(params || %{}, :query) do
      typed when is_binary(typed) -> String.trim(typed)
      _none -> ""
    end
  end

  def render(assigns) do
    filter = assigns.filter
    shown = visible(assigns.results, filter)
    # Board 308's first band draws no count before a keystroke: `0 results` over
    # a sheet nobody has asked anything of is a report on a search that has not
    # happened. `Kati.Search.long_enough?/1` is the same seam the search itself
    # gates on, so the eyebrow and the query cannot disagree.
    count =
      if Kati.Search.long_enough?(assigns.query) do
        found = length(shown)
        ngettext("%{n} result", "%{n} results", found, n: Kati.Locale.number(found))
      else
        # Sentence case, and the drawing's `SEARCH` still comes out of it:
        # `Kati.UI.eyebrow/2` upcases through `Kati.UI.eyebrow_label/1`, which
        # upcases in Latin and leaves Persian alone because Persian has no
        # case. The msgid is therefore the word the catalogue already carries —
        # `Kati.Screens.Pushed`'s back-pill table is the other caller — rather
        # than a shouted second copy of it needing an entry of its own.
        gettext("Search")
      end

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
        <Column
          fill_width={true}
          padding_left={21}
          padding_right={21}
          padding_top={64}
          padding_bottom={40}
        >
          {Kati.Screens.AddTitle.header()}
          {Kati.Screens.AddTitle.field(assigns.query, assigns[:query_epoch] || 0)}
          {Kati.Screens.AddTitle.chips(filter)}
          {Kati.Screens.AddTitle.search_notice(assigns[:search_error])}
          {Kati.Screens.AddTitle.save_notice(assigns[:save_error])}
          {UI.eyebrow(count)}
          {Kati.Screens.AddTitle.body(shown, assigns)}
          {Kati.Screens.AddTitle.by_hand(assigns.query)}
        </Column>
      </Scroll>
    </Box>
    """
  end

  @doc """
  Why the search came back with nothing, when there is a reason to give.

  `search/1` has assigned `:search_error` since it was written and **nothing
  drew it**, which was found on a device: typing `matrix` on a phone answers
  `RESULTS 0` and says nothing at all, because a release carries no
  `TMDB_READ_TOKEN` and `Kati.Media.Tmdb.key/0` answers `{:error,
  :no_api_key}`. The sentence that would have explained it — *No TMDB key
  yet. Add one in Settings → Data sources.* — was composed on line 254,
  put on the socket, and thrown away by a render that never read the key.

  A search that fails silently is indistinguishable from a catalogue with
  nothing in it, and the difference is the whole of what a person needs to
  know: one is fixed in Settings and the other is not fixable at all.

  Above the count rather than below it, because the count is `0 results` and
  the reason has to reach the reader before they believe it.
  `Kati.Screens.Medication.save_notice/1` is the same band on the same
  argument — a failure reported into a tree with nowhere to render it is a
  silence — and this borrows its type rather than restating it.
  """
  @spec search_notice(String.t() | nil) :: map() | []
  def search_notice(nil), do: []

  def search_notice(message), do: Kati.UI.notice(message)

  @doc """
  Why the add — or the remove — did not happen.

  `:save_error` has been assigned in three places on this screen since it could
  write, and drawn in none of them. So adding a title that is already in the
  library was a tap into total nothing: the check did not fill, no row
  appeared, and the page said no more than it would have if the finger had
  missed. MOVIES-AND-TV.md #42, and it is `D-60`'s defect in English on the one
  screen a new install is most likely to be on.

  `Kati.UI.notice/1` and not a second band of its own: the search failure two
  lines above already uses it, and two shapes for *this did not work* on one
  page is how a person learns to read neither.
  """
  @spec save_notice(String.t() | nil) :: term()
  def save_notice(nil), do: []

  def save_notice(message), do: Kati.UI.notice(message)

  def handle_info({:tap, :back}, socket), do: {:noreply, Kati.Screens.Resume.pop(socket)}

  # The escape hatch, finally wired. This row has been drawn on artboard 89
  # since the screen was written and rendered with no `on_tap` at all, because
  # no board drew what it would open — the moduledoc has carried that apology
  # for as long. Board 154 is that form, and #91's "a clean install hands over
  # a usable app" is what it answers: until the catalogue lands, every title
  # this screen can find is invented, and this is the only way to put a real
  # one in the library.
  # The locale's own form, not the English one. A Persian reader who taps this
  # row and lands on an English page has been dropped out of the mirror
  # mid-journey — `Kati.Onboarding.shell_root/1` answers the same question the
  # same way for where a first run lands.
  # Screen 154, unconditionally. Branching on the locale here was the obvious
  # thing and it is wrong for a reason worth recording: `Kati.AppReachabilityTest`
  # builds its graph by dispatching real taps and MEMOISES it in
  # `:persistent_term`, so a locale-dependent edge makes the graph answer
  # differently depending on which test file built it first — 156 reachable in
  # one run and stranded in the next, from the same code.
  #
  # 156 is therefore on that file's inventory, which is where every other
  # Persian mirror already sat: `Kati.Screens.RestoreFa` and
  # `Kati.Screens.OnboardingFa` are stranded in exactly the same way and for
  # exactly the same reason. Routing the mirrors properly is #93's third
  # criterion — "Persian screens are reachable after onboarding, not only
  # during it" — and it wants one answer for all of them rather than a
  # different `if` on each row that opens one.
  def handle_info({:tap, :add_by_hand}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.AddByHand.for_locale())}

  @doc """
  What was typed into the search field, and the search it eventually runs.

  **Not debounced, and deliberately not.** The obvious shape is a timer —
  bump a counter, `Process.send_after` a `{:search, n}`, run only the newest —
  and `Kati.SupervisionRuleTest` forbids it in as many words: a screen is
  transient, Mob keeps one alive at a time and it dies on every root switch, so
  a timer a screen sets outlives the screen that set it. Written that way
  first; the lint is what caught it.

  So the search runs in the change handler, under a three-character floor. Two
  consequences worth naming rather than discovering:

    * one request per keystroke past the floor, where a debounce would make one
      per pause;
    * the handler blocks while the request is in flight, so the field lags by
      the round trip.

  Both are fixed by the same thing — a supervised worker that owns the
  debounce and hands answers back — and neither is fixed by a timer here.
  `handle_info/2` is sequential, so at least the answers cannot arrive out of
  order and overwrite a newer list with an older one.
  """

  # Board 308: *"Two characters to start — one in فارسی, العربية, 中文, 日本語."*
  # It was a flat three, which asked a Persian reader for three characters where
  # one is a word. `Kati.Search.long_enough?/1` is the rule screen 86 already
  # states in its own note, and this sheet now uses the same one rather than a
  # second number that could drift from it.

  def handle_info({:change, :title_query, typed}, socket) when is_binary(typed) do
    socket = Mob.Socket.assign(socket, :query, typed)
    query = String.trim(typed)

    if not Kati.Search.long_enough?(query) do
      # Back to the drawing, not to nothing. Board 06 is drawn mid-query and no
      # board draws this screen before anyone has typed — the rule
      # `Kati.Screens.Library` moved off its Sample under is that the design
      # must draw the emptiness first, and here it does not. `D-31` is the
      # brief that would settle it.
      # And emptied, not restored to the drawing's four. Typing `Up` used to
      # answer with four films nobody had searched for — MOVIES-AND-TV.md #44,
      # and the same defect as the resting sheet one keystroke along.
      {:noreply,
       socket
       |> Mob.Socket.assign(:results, [])
       |> Mob.Socket.assign(:searching?, false)
       |> Mob.Socket.assign(:search_error, nil)}
    else
      # NOT searched here. This handler runs on every keystroke, so searching
      # from it made one TMDB request per letter — nine for `severance`, eight
      # of them thrown away by the ninth. `Kati.Media.SearchDebounce` waits for
      # the typing to stop and sends `{:search_ready, query}` back; the clause
      # below decides whether that answer is still the one wanted.
      Kati.Media.SearchDebounce.ask(self(), query)

      # Board 308's second band. Set here rather than when the request goes out,
      # because from the reader's side the wait starts at the keystroke — the
      # debounce is part of it — and a sheet that shows nothing for 300ms and
      # then skeletons has two waits in it.
      {:noreply, Mob.Socket.assign(socket, :searching?, true)}
    end
  end

  # The × at the end of the field. Back to the state the sheet mounts in —
  # the query empty, the board's rows, and no refusal left standing from a
  # search that is no longer on screen. Not `searched/2` with an empty string:
  # an empty field is under the floor and must not reach the network.
  def handle_info({:tap, :clear_query}, socket) do
    {:noreply,
     socket
     |> Mob.Socket.assign(:query, "")
     # The bump is what makes the FIELD empty as well as the assign. Without
     # it the results reset and the typed text stayed — see `K-46` in
     # `native/LEDGER.md`, found doing exactly this on a device.
     |> Mob.Socket.assign(:query_epoch, (socket.assigns[:query_epoch] || 0) + 1)
     |> Mob.Socket.assign(:searching?, false)
     # Back to the state the sheet mounts in, which is empty — clearing the
     # field used to put the drawing's four results back under it.
     |> Mob.Socket.assign(:results, [])
     |> Mob.Socket.assign(:search_error, nil)
     |> Mob.Socket.assign(:save_error, nil)}
  end

  @doc false
  # A door for a test to put result rows on the socket without a network call.
  # The sheet opens empty and the only other way in is `{:search_ready, …}`,
  # which makes a TMDB request — `Kati.AddTitleWriteTest` is about the WRITE
  # behind a row and has no business making one.
  def handle_info({:results_for_test, rows}, socket) when is_list(rows),
    do: {:noreply, Mob.Socket.assign(socket, :results, rows)}

  def handle_info({:tap, tag}, socket) do
    case Atom.to_string(tag) do
      "filter_" <> label ->
        {:noreply, Mob.Socket.assign(socket, :filter, label)}

      # The toggle runs over the FULL list, not the filtered one: the row the
      # user tapped is identified by its title, so which chip was on when they
      # tapped it cannot matter.
      "add_" <> title ->
        {:noreply, Kati.Screens.AddTitle.add(socket, title)}

      _ ->
        {:noreply, socket}
    end
  end

  # The debounce coming back. The query is searched only if it is still what
  # the person has typed — see `Kati.Media.SearchDebounce` for why that
  # comparison is the whole mechanism and needs no sequence number.
  #
  # Re-checked against the floor as well: `sev` can arrive after the field has
  # been cleared back to `se`, and a request for a query the screen would now
  # refuse to make is a request it should not make late either.
  def handle_info({:search_ready, query}, socket) when is_binary(query) do
    current = socket.assigns |> Map.get(:query, "") |> String.trim()

    if query == current and Kati.Search.long_enough?(query) do
      {:noreply, Kati.Screens.AddTitle.searched(socket, query)}
    else
      # A stale answer, for a query the reader has typed past. The rows are not
      # touched — a newer request is already out — but the flag is, because this
      # one is no longer the thing being waited for.
      {:noreply, socket}
    end
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  @doc """
  Run one search and put its answer on the socket.

  A failure is **shown**, not swallowed: #89's fourth criterion is that a
  failed or rate-limited request is visible to the user, and
  `Kati.Media.Tmdb.message/1` is where the wording lives. The results already
  on screen are cleared with it — a stale list under an error message reads as
  though the error were about something else.
  """
  @spec searched(Mob.Socket.t(), String.t()) :: Mob.Socket.t()
  def searched(socket, query) do
    socket = Mob.Socket.assign(socket, :searching?, false)

    case Kati.Media.Tmdb.search(query) do
      {:ok, rows} ->
        socket
        |> Mob.Socket.assign(:results, Enum.map(rows, &Kati.Screens.AddTitle.row/1))
        |> Mob.Socket.assign(:search_error, nil)

      {:error, reason} ->
        socket
        |> Mob.Socket.assign(:results, [])
        |> Mob.Socket.assign(:search_error, Kati.Media.Tmdb.message(reason))
        |> Mob.Socket.assign(:save_error, nil)
    end
  end

  @doc """
  One TMDB result in the shape this screen draws.

  `seed` carries the CDN path. It was `nil` with the note *the honest answer
  until posters are fetched* — they are fetched now, by `Kati.Media.Artwork`,
  and `Kati.Design.Images` resolves a path like `/kBf3g9....jpg` to the file
  on this device. A row already added therefore shows its own poster, and a
  row not yet added shows `thumb/1`'s paper placeholder, because nothing is
  downloaded until somebody asks for the title.

  `source_id` and `kind` ride along because `track/2` needs them: a row added
  from TMDB is tracked under its TMDB id, not under its title.
  """
  @spec row(map()) :: map()
  def row(result) do
    %{
      title: result.title,
      # The CDN path, not `nil`. `Kati.Design.Images` resolves one of these to
      # the file `Kati.Media.Artwork` downloaded, so a result the person has
      # already added shows its own poster here instead of the placeholder —
      # and a result they have not shows the placeholder exactly as before,
      # because nothing is fetched until a title is added. See `thumb/1`.
      seed: result.poster_path,
      meta: Kati.Screens.AddTitle.meta_line(result),
      note: result.overview,
      added: false,
      source: :tmdb,
      source_id: result.source_id,
      kind: result.kind
    }
  end

  @doc false
  @spec meta_line(map()) :: String.t()
  def meta_line(result) do
    # `FILM` and `SERIES` are `Kati.Lists.Shelf`'s own two msgids, reused rather
    # than restated. The shelf tag and this meta line name one thing, and a
    # second pair of entries is how one thing ends up with two Persian words
    # for it — which is the whole failure mishka-group/kati#103 folded the
    # mirrors away to stop.
    kind = if result.kind == :movie, do: gettext("FILM"), else: gettext("SERIES")

    case result.year do
      nil ->
        kind

      year ->
        # `Kati.Locale.number/1` and not `Kati.Locale.year/1`, for a reason that
        # is about types rather than about calendars: a TMDB `year` is the four
        # CHARACTERS `Kati.Media.Tmdb.year_of/1` slices off a release date, and
        # `year/1` takes an integer. Both end at the same place — `year/1` is
        # `number/1` — and the rule they share still holds: a release year is a
        # fact printed on the film, so the digits change and the calendar does
        # not.
        #
        # Concatenated, with no msgid of its own. `·` is a bidi NEUTRAL sitting
        # between a number and a word, so it takes the paragraph's direction
        # and `۲۰۱۶ · فیلم` lays out right-to-left in the order it was written.
        # There is nothing here for a translator to reorder, and a msgid that
        # is two interpolations and a separator is the kind of thing
        # `mix gettext.merge` fuzzy-matches against every other `·` line in the
        # catalogue.
        Kati.Locale.number(year) <> " · " <> kind
    end
  end

  @doc """
  The results a chip leaves visible.

  Asked of `kind_of/1`, which reads the row's own `:kind` and falls back to the
  `meta` line only for a row that has none. It matched on `meta` alone until
  this round — `String.contains?(meta, "FILM")` — and `meta_line/1` is written
  in the reader's language now: `۲۰۱۶ · فیلم` contains neither `FILM` nor
  `SERIES`, so a Persian reader who tapped **Films** over a page of films got
  an empty list from a chip that works perfectly in English. A chip that
  silently filters everything away is the worst shape this defect could take,
  because it reads as *there are none* rather than as *this is broken*.

  The design's note still holds — the type is inferred from what you searched —
  and what it is inferred FROM is now a field instead of a sentence, because a
  sentence changes with the locale and a field does not.
  """
  @spec visible([map()], String.t()) :: [map()]
  def visible(results, "Films"),
    do: Enum.filter(results, &(Kati.Screens.AddTitle.kind_of(&1) == :movie))

  def visible(results, "Series"),
    do: Enum.filter(results, &(Kati.Screens.AddTitle.kind_of(&1) == :tv))

  def visible(results, _filter), do: results

  @doc false
  def header do
    # `Kati.Locale.tracking/1` rather than the drawing's flat `-0.03`: the
    # design tightens its 26pt heading by a fraction of an em, and negative
    # tracking on Arabic script pulls the letters apart at the joins — the
    # kerning the design wants is the thing that breaks the word. Zero under
    # `:fa`, the drawing's own number under `:en`.
    #
    # `max_lines={1}` with it. `افزودن عنوان` is two words where `Add a title`
    # is three, but a display heading that wraps pushes the close disc down the
    # page, and the disc is this sheet's only dismissal.
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Text
          text={gettext("Add a title")}
          text_size={26}
          font_weight="bold"
          letter_spacing={Kati.Locale.tracking(-0.03)}
          text_color={:on_surface}
          max_lines={1}
        />
        <Spacer weight={1.0} />
        {Kati.Screens.AddTitle.close_disc()}
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  # The sheet's one dismissal, as Chelekom's headless Action Icon — the same
  # component `add_button/2` already uses on this screen, now that `shadow`
  # exists to carry `shadow_button()`. Without the lift a filled disc is card
  # white on paper, and the drawing's close button reads as floating over the
  # sheet rather than printed on it.
  #
  # `shape: :circle` resolves `44 / 2` = 22.0 against the Box's stated 22, which
  # `floatProp` reads identically, and the glyph stays a CHILD so
  # `Kati.UI.symbol/2` supplies the Material Symbol at the drawn 21.
  @doc false
  def close_disc do
    MishkaActionIcon.action_icon(
      [
        size: 44,
        shape: :circle,
        variant: :filled,
        background: Palette.card(),
        shadow: Theme.shadow_button(),
        on_tap: :back
      ],
      [UI.symbol("close", size: 21)]
    )
  end

  # The focused field. `0 0 0 2px #1A1917` in the drawing is a ring, not a
  # shadow, so it is a 2px border here — a shadow at zero blur and zero offset
  # would be invisible under the card's own elevation.
  @doc """
  The search field, which is now a field.

  It was a `<Text>` reading "quiet" beside a 2×19 orange `<Box>` drawn to look
  like a caret — a picture of a focused input. The moduledoc above still
  describes the ring and the caret, and both are real; what was missing was
  anything to type into.

  Nine screens carry a comment saying Mob has no text input. It does:
  `<TextField>` is in the pinned Mob and `Kati.Screens.Backup` has used it for
  the passphrase all along. The belief cost more than the feature — every
  search box in the app is a drawing because of it.
  """
  @spec field(String.t()) :: map()
  def field(query, epoch \\ 0) do
    # The placeholder is a SPECIMEN QUERY — board 06 is drawn mid-query on
    # "quiet" and the resting field shows the same word greyed — so it is copy
    # and it translates. `pgettext/2` and not `gettext/1` because a bare
    # five-letter msgid is exactly what `mix gettext.merge`'s fuzzy matcher
    # takes for a near-miss of some other short string; the context says which
    # slot it belongs to and cannot be matched against an entry that has none.
    assigns = %{
      query: query,
      epoch: epoch,
      placeholder: pgettext("search field placeholder", "quiet"),
      on_change: {self(), :title_query}
    }

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        height={52}
        corner_radius={26}
        background={Palette.card()}
        border_width={2}
        border_color={Palette.ink()}
        shadow={Kati.Theme.shadow_search()}
        padding_left={18}
        padding_right={18}
        align="center"
      >
        {Kati.UI.symbol("search", size: 20)}
        <Spacer size={11} />
        <TextField
          value={@query}
          value_epoch={@epoch}
          placeholder={@placeholder}
          return_key="search"
          weight={1.0}
          accessibility_id="title_query"
          on_change={@on_change}
        />
        {Kati.Screens.AddTitle.clear_disc()}
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  Track a title, for real.

  Until now this toggled a boolean on a socket and the row died with the
  screen. #60 decided v1 ships film and TV, and film and TV was the one domain
  in the app with no write path at all: nine screens queried `Kati.Media`
  correctly and every one of them queried a table that could not hold a row.

  Two rows, not one. `CachedTitle` is what a provider would have said about
  this title and `TrackedTitle` is what you decided about it — the split is why
  a provider can be reconciled in later without touching your rating or your
  history, which `Kati.Media.TrackedTitle`'s own moduledoc argues at length.
  Typing a title by hand is simply the first writer of both.

  The source is `:manual` and the id is the title itself. There is no provider
  to ask for a stable id, and inventing one would make the row unreconcilable
  later — a `:manual` row is honest about being unlookupable.

  Untracking deletes the `TrackedTitle` and leaves the `CachedTitle`: what you
  decided is yours to undo, what a title IS is not a decision.
  """
  @spec add(Mob.Socket.t(), String.t()) :: Mob.Socket.t()
  def add(socket, key) do
    row = Enum.find(socket.assigns.results, &(Kati.Screens.AddTitle.row_key(&1) == key))
    title = row && row.title
    tracked? = row && row.added

    result =
      if tracked? do
        Kati.Screens.AddTitle.untrack(title, row)
      else
        Kati.Screens.AddTitle.track(title, row)
      end

    case result do
      {:ok, _record} ->
        socket
        |> Mob.Socket.assign(:results, Kati.Screens.AddTitle.mark(socket.assigns.results, key))
        |> Mob.Socket.assign(:save_error, nil)

      {:error, _reason} = error ->
        Mob.Socket.assign(socket, :save_error, Kati.Write.message(error))
    end
  end

  @doc """
  What names a row among the rows beside it.

  The title was the key, and two results with the same title made the second
  one unusable: TMDB answers `arrival` with **Arrival (2016)** and **Arrival
  (1986)**, both rows drew the tag `add_Arrival`, `Mob.Renderer` gave one
  `accessibility_id` to two nodes, and `add/2`'s `Enum.find/2` matched the
  first — so tapping the 1986 film added the 2016 one and ticked both discs.
  Reproduced on a Pixel 9a with that exact query.

  A TMDB row is named by its own id, which is what the store keys on anyway;
  the design's four fixture rows have none and keep their titles, so board 06's
  tags — `add_The Quiet Coast` and the rest — are unchanged and every sweep
  that names them still names them.

      iex> Kati.Screens.AddTitle.row_key(%{title: "Arrival", source_id: "329865"})
      "329865"

      iex> Kati.Screens.AddTitle.row_key(%{title: "The Quiet Coast"})
      "The Quiet Coast"
  """
  @spec row_key(map()) :: String.t()
  def row_key(%{source_id: id}) when is_binary(id) and id != "", do: id
  def row_key(%{title: title}), do: title

  @doc false
  @spec track(String.t(), map() | nil) :: {:ok, term()} | {:error, term()}
  def track(title, %{source: :tmdb, source_id: source_id, kind: kind}) do
    # The detail call, and the only place it is made. It fills
    # `Kati.Media.CachedTitle`, `CachedSeason` and `CachedEpisode` — the
    # episodes are the point, because nothing can be ticked before they exist,
    # and a series tracked without them is a row with no progress possible.
    #
    # A tracked row under the TMDB id rather than under the title: the cached
    # episodes reference `title_source_id`, so a `:manual` row keyed on a
    # string would sit beside its own episode list and never join to it.
    with {:ok, filled} <- Kati.Media.Tmdb.fetch(source_id, tmdb_kind(kind)),
         {:ok, tracked} <-
           Ash.create(Kati.Media.TrackedTitle, %{
             source: :tmdb,
             source_id: source_id,
             # Board 152's third rule, asked of the row the fetch just wrote:
             # TMDB's Animation + Japanese origin. `:anime` was a kind every
             # reader in the app knew and nothing ever wrote — MOVIES-AND-TV.md
             # #104 — and this is the writer.
             kind: Kati.Media.Anime.kind_for(kind, Map.get(filled, :title), nil),
             status: :watching
           }) do
      # The picture, fetched once, here, because this is the only moment the
      # app knows a title is wanted and is allowed to be slow. `poster_path` is
      # a path on TMDB's CDN and every screen resolves artwork through
      # `Kati.Design.Images`, which can only answer for a file already on the
      # device — so without this line every title a user added drew a grey
      # placeholder on Home, on the shelf, on Up next and on its own page.
      #
      # The result is deliberately dropped. A poster that did not download is a
      # grey card, which is what the app drew before; refusing to add the title
      # would let the network decide what is on somebody's shelf.
      _artwork = Kati.Media.Artwork.cache(Kati.Screens.AddTitle.poster_of(filled))

      # MOVIES-AND-TV.md #112: screen 15's `Added` chip could never match a row,
      # because nothing recorded that a title arrived. `from_status` is nil on
      # an add — there was no before.
      Kati.Media.Log.write(tracked, :added, %{from_status: nil})

      {:ok, tracked}
    end
    |> Kati.Write.note("track #{title}")
  end

  def track(title, row) do
    kind = Kati.Screens.AddTitle.kind_of(row)

    with {:ok, _cached} <- Kati.Screens.AddTitle.cache(title, kind),
         {:ok, tracked} <-
           Ash.create(Kati.Media.TrackedTitle, %{
             source: :manual,
             source_id: title,
             kind: kind,
             status: :watching
           }) do
      Kati.Media.Log.write(tracked, :added, %{from_status: nil})

      {:ok, tracked}
    end
    |> Kati.Write.note("track #{title}")
  end

  @doc """
  The CDN path on the row `Kati.Media.Tmdb.fetch/2` just wrote, or `nil`.

  `fetch/2` answers `%{title: %Kati.Media.CachedTitle{}, seasons: n, episodes:
  n}` — the counts are what the caller usually wants and the row is what this
  wants. Written as a function with a nil clause rather than a chain of
  `Map.get/2` so a shape change here is a compile-time surprise in one place
  instead of a silently absent poster on every screen.
  """
  @spec poster_of(term()) :: String.t() | nil
  def poster_of(%{title: %{poster_path: path}}) when is_binary(path), do: path
  def poster_of(_other), do: nil

  # `Kati.Media.TrackedTitle` calls a show `:tv` and so does TMDB; anime and
  # books are Kati's own kinds and have no TMDB endpoint, so they fetch as
  # films — the detail call still answers, and the episode walk is what a
  # series gets that they do not.
  defp tmdb_kind(:tv), do: :tv
  defp tmdb_kind(_other), do: :movie

  @doc """
  The cached row for a title, creating it only if it is not already there.

  Idempotent on purpose, and the reason is `untrack/1`: removing a title
  deletes what you DECIDED and keeps what the title IS, so the cached row
  outlives the tracking row. Re-adding a title you had removed would otherwise
  violate the `[:source, :source_id]` unique index, fail, and — before this —
  report "that did not save" for a title that saves perfectly well.

  Found by the test that adds, removes and adds again. It is the ordinary way
  someone changes their mind.
  """
  @spec cache(String.t(), :movie | :tv) :: {:ok, term()} | {:error, term()}
  def cache(title, kind, extra \\ %{}) do
    existing =
      case Ash.read(Kati.Media.CachedTitle) do
        {:ok, rows} -> Enum.find(rows, &(&1.source == :manual and &1.source_id == title))
        _error -> nil
      end

    if existing, do: {:ok, existing}, else: Kati.Screens.AddTitle.create_cache(title, kind, extra)
  end

  @doc false
  def create_cache(title, kind, extra \\ %{}) do
    Ash.create(
      Kati.Media.CachedTitle,
      Map.merge(
        %{
          source: :manual,
          source_id: title,
          kind: kind,
          title: title,
          # `Kati.Time.now/0`, not `DateTime.utc_now/0` — `Kati.ScreenDateTest`
          # forbids the latter in a screen, because a screen that reads the wall
          # clock directly cannot be tested against a fixed day.
          #
          # `allow_nil?: false`, because the resource's own moduledoc says a row
          # with no age cannot be evicted and would quietly break TMDB's six-month
          # ceiling. A `:manual` row is never evicted — see
          # `Kati.Media.CachePolicy`'s `manual: {:never, :never}` — but it still
          # carries an honest timestamp rather than a placeholder, because "when
          # did this enter Kati" is a real question with a real answer.
          fetched_at: Kati.Time.now() |> DateTime.truncate(:second)
        },
        # What screen 154's form collected and nothing wrote. `episode_count`
        # is the denominator every progress bar in the app divides by, and the
        # note under that field promised it — MOVIES-AND-TV.md #59.
        extra
      )
    )
  end

  @doc false
  @spec untrack(String.t()) :: {:ok, term()} | {:error, term()}
  def untrack(title, row \\ nil) do
    {source, source_id} = tracked_key(title, row)

    case Ash.read(Kati.Media.TrackedTitle) do
      {:ok, rows} ->
        rows
        |> Enum.find(&(&1.source == source and &1.source_id == source_id))
        |> case do
          nil ->
            {:ok, :already_gone}

          found ->
            Ash.destroy(found) |> then(fn r -> if r == :ok, do: {:ok, :removed}, else: r end)
        end

      error ->
        error
    end
    |> Kati.Write.note("untrack #{title}")
  end

  @doc """
  The `{source, source_id}` pair a tracked row is actually keyed on.

  This function is MOVIES-AND-TV.md #41 in one line. `untrack/1` looked for
  `source == :manual and source_id == title`, which is the pair a HAND-TYPED
  title is stored under — and `track/2` stores a TMDB title under `{:tmdb,
  "329865"}`, deliberately, because the cached episodes reference the provider
  id. So removing something added from TMDB found nothing, answered
  `{:ok, :already_gone}`, and reported success: the check flipped back to a `+`
  and the title stayed in the library forever.

  The row is the caller's, and it is the row the same tap added — `row/1` puts
  `source` and `source_id` on it for exactly this reason. Without one, the
  title is the key, which is the drawing's four fixtures and every hand-typed
  title.

      iex> Kati.Screens.AddTitle.tracked_key("Arrival", %{source: :tmdb, source_id: "329865"})
      {:tmdb, "329865"}

      iex> Kati.Screens.AddTitle.tracked_key("The Quiet Coast", nil)
      {:manual, "The Quiet Coast"}

      iex> Kati.Screens.AddTitle.tracked_key("Typed by hand", %{title: "Typed by hand"})
      {:manual, "Typed by hand"}
  """
  @spec tracked_key(String.t(), map() | nil) :: {:tmdb | :manual, String.t()}
  def tracked_key(_title, %{source: :tmdb, source_id: id}) when is_binary(id) and id != "",
    do: {:tmdb, id}

  def tracked_key(title, _row), do: {:manual, title}

  @doc """
  What a result row is: its own `:kind` first, and the `meta` line after.

  `"2019 · FILM · 1h 48m"` is a film; `"2023 · SERIES · 2 SEASONS"` is tv. The
  parse was the whole answer and is now the fallback, because `meta_line/1`
  writes that sentence in the reader's language and `فیلم` is not `FILM` and
  never will be. `row/1` has carried `:kind` straight off TMDB since the write
  path landed, so the question already had a locale-proof answer sitting on the
  row — reading the words back out of a rendered line was only ever right while
  there was one language to render it in.

  The fallback stays, and stays English, because the rows that reach it are
  English: board 06's four fixtures come from `Kati.Library.Sample`, which
  writes their `meta` in Latin under both scripts, and a title typed by hand
  carries no kind of its own either. A guess that reads the words already on
  screen is still better than a default nobody chose.
  """
  @spec kind_of(map() | nil) :: :movie | :tv
  def kind_of(%{kind: :tv}), do: :tv
  def kind_of(%{kind: :movie}), do: :movie

  def kind_of(%{meta: meta}) when is_binary(meta) do
    if String.contains?(String.upcase(meta), "SERIES"), do: :tv, else: :movie
  end

  def kind_of(_row), do: :movie

  @doc false
  def mark(results, key) do
    Enum.map(results, fn r ->
      if Kati.Screens.AddTitle.row_key(r) == key, do: %{r | added: not r.added}, else: r
    end)
  end

  @doc """
  The three filter VALUES, which are not the three labels.

  They were one string until this round: the list below was the label list,
  `filter: "Everything"` put that label on the socket, `visible/2` matched on
  it and `chip/2` built `filter_Films` out of it. Translating the chip would
  have translated all four at once — the socket would hold `فیلم`, the tap
  would arrive as `:"filter_فیلم"`, and `handle_info/2`'s `"filter_" <> label`
  clause would set a filter that `visible/2` has no clause for, so every chip
  but **Everything** would empty the list.

  That is not a hypothetical. `Kati.Screens.Books.chip_counts/1` records it
  happening on the shelf, in its own words: the Persian filter was «همه», every
  clause of that screen's `visible/2` fell through to `_all`, and the chips drew
  correctly while tapping any of the four showed everything.

  So the value is English and stays English — it is a key, and a key the
  `Kati.ScreenTapSweepTest` inventory names as `:filter_Everything` — and
  `filter_label/1` is the only part in the reader's language. Strings rather
  than the atoms `chip_counts/1` uses, because `visible/2` and the socket's
  `:filter` already speak in these three words and `Kati.AddTitleRemoveTest`
  assigns `filter: "Everything"` by hand.
  """
  @spec filters() :: [String.t()]
  def filters, do: ["Everything", "Films", "Series"]

  @doc """
  The word a filter chip shows for the value it carries.

  A literal per clause, because a msgid has to be a literal at the call site —
  `gettext(value)` does not compile — and because three chips are three
  decisions rather than one table.

  `pgettext/2` on all three, which is `Kati.Screens.Books.chip_counts/1`'s own
  choice for the same control and made for the same reason: a chip is a surface
  and its word can differ from the same word elsewhere. `Everything` needs the
  context outright — the catalogue already holds *Everything else* and
  *Everything here is started*, and a bare one-word msgid beside two long
  sentences that open on that word is exactly what `mix gettext.merge`'s fuzzy
  matcher gets wrong. `Films` and `Series` take it too, because a row of three
  chips keyed three different ways is a row somebody edits half of.

  The WORDS are not new even though the entries are: `فیلم` and `سریال` are
  what `Kati.Lists.Shelf`'s `FILM` / `SERIES` tags and `Kati.Screens.Stats`'
  categories already say, so the chip agrees with the meta line under it.
  """
  @spec filter_label(String.t()) :: String.t()
  def filter_label("Everything"), do: pgettext("add-title filter", "Everything")
  def filter_label("Films"), do: pgettext("add-title filter", "Films")
  def filter_label("Series"), do: pgettext("add-title filter", "Series")
  def filter_label(other), do: other

  @doc false
  def chips(active) do
    children =
      Kati.Screens.AddTitle.filters()
      |> Enum.map(fn value -> Kati.Screens.AddTitle.chip(value, value == active) end)
      |> Enum.intersperse(Kati.Screens.AddTitle.chip_gap())

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true}>
        {children}
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  # Chelekom's headless Chip, which is what these are: three filter chips of
  # which exactly one is checked. Everything the drawing specifies is passed in
  # — the component's own defaults are theme tokens and would draw a different
  # chip, which is why this could not be built out of it before this round.
  #
  # Identical to screen 02's filter chips down to the number, which is the
  # design's own doing: both are `height:32 / radius:16 / padding:0 15 /
  # 12.5 semibold`, ink when on and card white when off. The two screens still
  # state it separately because they are separate drawings that happen to
  # agree, not one control shared between them.
  #
  # The node swaps a `<Row>` for a `<Box fill_width={false}>` and gains an
  # explicit `padding_top`/`padding_bottom` of 0. Neither moves a pixel:
  # `boxAlignProp("center")` is `Alignment.Center` where `rowAlignProp` was
  # `CenterVertically`, and the second axis is inert because K-17 lets the box
  # hug — it is 15 + label + 15 wide, with no slack to centre in. The zero
  # edges are what `nodeModifier`'s `pad(v) = v ?: uniform ?: 0` already
  # substituted for the Row's absent ones.
  @doc false
  def chip(value, on?) do
    # The tag carries the VALUE and the chip shows the LABEL, so the day the
    # sheet grows a Books chip is a change to `filters/0`, `filter_label/1` and
    # `visible/2`, not to the handler — and the tag stays `filter_Films` in
    # every locale, which is the name `Kati.ScreenTapSweepTest` knows it by and
    # the only reason `String.to_atom/1` here is safe.
    MishkaChip.chip(
      label: Kati.Screens.AddTitle.filter_label(value),
      checked: on?,
      on_toggle: String.to_atom("filter_" <> value),
      height: 32,
      padding_x: 15,
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

  # `gap:7px` in the drawing is the space BETWEEN chips. Carried inside the
  # chip it made every chip 7 wider than the drawn `padding:0 15px` and left
  # the row with no gap of its own.
  @doc false
  def chip_gap, do: ~MOB"<Spacer size={7} />"

  @doc false
  def results(results) do
    ~MOB"""
    <Column fill_width={true}>
      {results
       |> Enum.map(fn r -> Kati.Screens.AddTitle.result_row(r) end)
       |> Enum.intersperse(Kati.Screens.AddTitle.row_gap())}
      <Spacer size={26} />
    </Column>
    """
  end

  @doc false
  def result_row(r) do
    # Two of this row's three lines can hold Arabic script, and neither could
    # say so before.
    #
    # The TITLE is a provider's. TMDB answers `فروشنده` for the Farhadi film as
    # readily as it answers `Arrival`, so the drawing's -0.015 goes through
    # `Kati.Locale.tracking/1`: negative tracking pulls Arabic letters apart at
    # the joins, which breaks the word rather than tightening it. The helper
    # asks the READER's direction and not this string's, which is the coarser
    # answer and the right one — a Persian page with one Latin title on it
    # should set that title like the page, not like the board it came from.
    #
    # The META is this screen's own sentence and `meta_line/1` translates it
    # now, so the hardcoded `font_family="mono"` had to go: `kati_mono.ttf`
    # carries no Persian glyph at all, and `فیلم` set in it falls through to
    # whatever face Android substitutes — legible, and in a typeface that is
    # not Kati's, beside rows that are.
    #
    # `Kati.Locale.mono_face/1` asks the STRING here rather than the reader,
    # which is the finer question and the right one for a slot that holds a
    # provider's words. Note where it lands: the `·` is already outside ASCII,
    # so under `:fa` the whole line takes Vazirmatn whether its words are
    # Persian or the fixtures' Latin `2023 · SERIES · 2 SEASONS`. That is the
    # safe direction of the two — Vazirmatn has every glyph the fixture needs
    # and DM Mono has none of the ones `فیلم` needs.
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.card()}
        corner_radius={18}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={13}
        padding_right={13}
        padding_top={11}
        padding_bottom={11}
        align="center"
      >
        {Kati.Screens.AddTitle.thumb(r)}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text
            text={r.title}
            text_size={14}
            font_weight="bold"
            letter_spacing={Kati.Locale.tracking(-0.015)}
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={5} />
          <Text
            text={r.meta}
            font_family={Kati.Locale.mono_face(r.meta)}
            text_size={10.5}
            text_color={Palette.muted()}
            max_lines={1}
          />
          <Spacer size={5} />
          <Text text={r.note} text_size={11.5} text_color={Palette.sub()} max_lines={1} />
        </Column>
        <Spacer size={13} />
        {Kati.Screens.AddTitle.add_button(r.added, Kati.Screens.AddTitle.row_key(r))}
      </Row>
    </Column>
    """
  end

  @doc false
  def row_gap, do: ~MOB"<Spacer size={9} />"

  @doc false
  def thumb(r) do
    case Kati.Library.Sample.poster(r[:seed]) do
      nil ->
        ~MOB"<Box width={44} height={62} corner_radius={9} background={Palette.placeholder()} />"

      src ->
        ~MOB"""
        <Image src={src} width={44} height={62} corner_radius={9} content_mode="fill" />
        """
    end
  end

  # Added is muted, not celebratory: the design keeps ink for the action still
  # available and greys the one already taken.
  #
  # One clause rather than two, because the two states are one button and it
  # has to go both ways — an add that cannot be undone is a trap on a list of
  # near-identical search results, three of which are called "Quiet".
  #
  # Chelekom's headless Action Icon draws it: this is exactly what that
  # component is for — a compact icon-only button — and the design's 34pt disc,
  # its fill and its glyph are all passed in, which is what headless means.
  #
  # The geometry is unchanged. `shape: :circle` computes `size / 2` = 17.0,
  # which is the 17 the Box stated; `variant: :filled` is what lets the fill be
  # the design's rather than the theme's; and the glyph goes in as a CHILD, so
  # `Kati.UI.symbol/2` still supplies the Material Symbol at the drawn 19 in the
  # drawn colour instead of the component's own `:lg` text glyph. The only
  # structural difference is the `<Row>` the component wraps children in, which
  # hugs its single Text and is centred by the same Box — no measurement moves.
  @doc false
  def add_button(added?, key) do
    # Keyed on the row's own identity, not its position: the chips reorder
    # nothing but they do renumber, and `add_1` would mean a different film
    # under `Films`. See `row_key/1` for why it is not the title either.
    tap = {self(), String.to_atom("add_" <> key)}
    bg = if added?, do: Palette.placeholder(), else: Palette.ink_fill()
    icon = if added?, do: "check", else: "add"
    ink = if added?, do: Palette.sub(), else: Palette.on_ink()

    MishkaActionIcon.action_icon(
      [size: 34, shape: :circle, variant: :filled, background: bg, on_tap: tap],
      [UI.symbol(icon, size: 19, color: ink)]
    )
  end

  # `1.5px dashed rgba(26,25,23,.16)` in the drawing. The bridge draws only
  # solid borders, so the dash is the one thing here that is not the design;
  # the COLOUR is now the design's own 16% ink rather than the opaque
  # #D8D2C8 that stood in for it, which read a shade light on paper.
  @doc """
  *Nothing here for “…”* — a search that ran and found nothing, said out loud.

  A query with no matches drew the eyebrow `0 results` and then a blank page:
  the sheet looked broken rather than answered, and the only thing under the
  hole was a by-hand row that gave no reason for being the last resort. Found
  by typing a query TMDB has nothing for, on a device.

  The sentence is **not new**. `Kati.Screens.AddTitleMusic.nothing_card/1`
  words this exact state on the sheet built beside this one, and its headline
  is quoted here character for character. Its body is not: that one says *Kati
  has no music catalogue to look in*, which is true of music and false here —
  this search did look. So there is no body at all, and the row below is the
  action, because a second *Add it by hand* button over the one this screen
  already draws would be the same offer twice.

  Drawn only when a search has actually run and come back empty. Three states
  are deliberately not this one:

    * **Under the floor.** Fewer than three characters is not a search that
      found nothing, it is a search that has not been made, and the sheet is
      showing the board's rows.
    * **A refusal.** `search_notice/1` is already above with the reason — no
      key, no network — and a card saying *nothing here* under a line saying
      *could not look* would be the app contradicting itself.
    * **A filter with nothing under it.** `Films` over a page of series is a
      chip the user can undo, and the count above already says `0 results`.
  """
  @spec nothing_card([map()], String.t(), String.t() | nil) :: map() | []
  def nothing_card(shown, query, error)

  def nothing_card(_shown, _query, error) when not is_nil(error), do: []

  def nothing_card([], query, _error) do
    typed = String.trim(query)

    cond do
      typed == "" ->
        card(
          "search",
          gettext("Search for something to add"),
          gettext("Type a film or a show and Kati looks it up.")
        )

      not Kati.Search.long_enough?(typed) ->
        # The msgid keeps the four script names it already carried — they are
        # the specimen, and a Persian reader needs `العربية` and `日本語` to
        # stay themselves as much as an English one does. What changes is the
        # sentence around them, and `Kati.Search`'s own two notes are where its
        # Persian comes from: *جست‌وجو از ۲ نویسه آغاز می‌شود* is already in the
        # catalogue, so the floor is described in one vocabulary rather than
        # two.
        card(
          "search",
          gettext("Keep typing"),
          gettext(
            "Two characters to start — one in فارسی, العربية, 中文, 日本語, where one is a word."
          )
        )

      true ->
        found_nothing(typed)
    end
  end

  def nothing_card(_shown, _query, _error), do: []

  @doc false
  def found_nothing(typed) do
    # The quotation marks stay INSIDE the msgid rather than going out through
    # `Kati.Locale.quoted/1`. The sentence is quoted character for character
    # from `Kati.Screens.AddTitleMusic.nothing_card/1` \u2014 the moduledoc above
    # says so \u2014 and one msgid is what keeps the two sheets saying one thing;
    # splitting the marks off would leave them with a shared stem and two
    # different punctuations. A Persian translator swaps `\u201C\u2026\u201D` for the
    # guillemets `\u00AB\u2026\u00BB` in the same edit that writes the words, which is where
    # that decision belongs.
    #
    # `typed` is deliberately NOT wrapped in `Kati.Locale.ltr/1`. It is the
    # reader's own text and can be in either script, and isolating a Persian
    # query as a left-to-right run would mirror the exact defect that helper
    # exists to fix. A Latin query needs no isolate here anyway: it is bounded
    # by the sentence's own quotation marks on both sides, so it has no
    # trailing neutral to strand at the wrong edge.
    card("search", gettext("Nothing here for \u201C%{query}\u201D", query: typed), nil)
  end

  # Board 87's card at this screen's size, which is what board 06's own
  # `nothing` state would be if one had been drawn — see `D-31`. One shape for
  # the three empty answers, because they differ in what they say and not in
  # how they look.
  @doc false
  def card(icon, headline, body) do
    assigns = %{icon: icon, headline: headline, body: body}

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={17}
        align="center"
      >
        <Box width={48} height={48} corner_radius={15} background={Palette.paper()} align="center">
          {Kati.UI.symbol(@icon, size: 22, color: Palette.rail_idle())}
        </Box>
        <Spacer size={13} />
        <Text text={@headline} text_size={14} font_weight="bold" text_color={:on_surface} />
        {Kati.Screens.AddTitle.card_body(@body)}
      </Column>
      <Spacer size={14} />
    </Column>
    """
  end

  @doc false
  def card_body(nil), do: ~MOB"<Spacer size={0} />"

  def card_body(body) do
    assigns = %{body: body}

    # `Kati.Locale.leading/1` and not the drawing's flat 1.55. Vazirmatn's
    # metrics are not Plus Jakarta's — its ascenders carry the marks Arabic
    # script sets above the line — so a paragraph measured against the Latin
    # board sets its Persian twin solid. `Kati.Theme.fa_line_height/0` is the
    # constant and this is it applied per paragraph, with the design's own
    # number still visible at the call site.
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={6} />
      <Text
        text={@body}
        text_size={12}
        line_height={Kati.Locale.leading(1.55)}
        text_color={Palette.sub()}
        text_align="center"
      />
    </Column>
    """
  end

  @doc """
  The × at the end of the field, which is a control and was a picture.

  It was drawn as a bare `Kati.UI.symbol("cancel", …)` with no `on_tap`, so a
  tap on it fell through to the `<TextField>` underneath — the keyboard opened
  and the next thing typed was APPENDED to the query the person was trying to
  get rid of. Found on a device: clearing `zzqwx` and typing `severance` gave
  `zzqwxseverance` and no results.

  A `<Box>` around the glyph rather than an `on_tap` on the symbol itself,
  because the glyph is 19pt and a 19pt target is under every guideline there
  is; the box is 40 and centres it. Nothing else about the row moves — the
  glyph keeps its size, colour and fill.
  """
  @spec clear_disc() :: map()
  def clear_disc do
    ~MOB"""
    <Box width={40} height={40} align="center" on_tap={{self(), :clear_query}}>
      {Kati.UI.symbol("cancel", size: 19, color: Kati.Theme.Palette.rail_idle(), fill: true)}
    </Box>
    """
  end

  @doc """
  The escape hatch — absent before a keystroke, and naming the query after one.

  Board 308: *"The add-by-hand row is absent before a keystroke — it names the
  query, and there is none"*, and *"present from the first keystroke: the query
  exists, so the escape hatch can name it."*

  Naming it is the whole difference. `Can't find it? Add it by hand` asks the
  reader to retype what they have just typed; `Add "vellichor" by hand` is the
  same control having read the field.

      iex> Kati.Locale.as(:en, fn -> Kati.Screens.AddTitle.by_hand_label("") end)
      nil

      iex> Kati.Locale.as(:en, fn -> Kati.Screens.AddTitle.by_hand_label("vellichor") end)
      "Add “vellichor” by hand"

  The examples name their language now, which `Kati.Screens.Medication`'s own
  doctests already do: the sentence comes out of `Kati.Gettext`, and an example
  that did not say which locale it expected would be asserting the English copy
  while quietly depending on nothing having set a locale in that process first.
  """
  @spec by_hand_label(String.t()) :: String.t() | nil
  def by_hand_label(query) do
    case String.trim(query) do
      "" ->
        nil

      # One msgid for the whole label rather than a stem with two marks glued
      # around the query. Persian puts the verb first and its object after \u2014
      # \u00AB\u0627\u0641\u0632\u0648\u062F\u0646 \u062F\u0633\u062A\u06CC \u00ABvellichor\u00BB\u00BB \u2014 so the query does not sit where `<>` leaves
      # it, and a sentence handed to a translator in three pieces is a sentence
      # they cannot reorder.
      typed ->
        gettext("Add \u201C%{query}\u201D by hand", query: typed)
    end
  end

  @doc false
  def by_hand(query \\ "") do
    case Kati.Screens.AddTitle.by_hand_label(query) do
      nil -> ~MOB"<Spacer size={0} />"
      label -> Kati.Screens.AddTitle.by_hand_row(label)
    end
  end

  @doc false
  def by_hand_row(label) do
    assigns = %{label: label}

    ~MOB"""
    <Row
      fill_width={true}
      corner_radius={18}
      border_width={1.5}
      border_color={Palette.border()}
      padding_top={14}
      padding_bottom={14}
      padding_left={13}
      padding_right={13}
      align="center"
      on_tap={{self(), :add_by_hand}}
    >
      <Spacer weight={1.0} />
      {Kati.UI.symbol("edit_note", size: 18, color: Palette.sub())}
      <Spacer size={7} />
      <Text
        text={@label}
        text_size={13}
        font_weight="semibold"
        text_color={Palette.ink_soft()}
        max_lines={1}
      />
      <Spacer weight={1.0} />
    </Row>
    """
  end

  @doc """
  The list, the skeletons, or the card — board 308's three states.

  In flight is `:searching?`, which the debounce sets on the keystroke and the
  answer clears. Before that the sheet has nothing to say and says the shortest
  true thing; after it, either rows or 89's card.
  """
  @spec body([map()], map()) :: term()
  def body(shown, assigns) do
    cond do
      Map.get(assigns, :searching?, false) and shown == [] ->
        Kati.Screens.AddTitle.skeletons()

      shown != [] ->
        Kati.Screens.AddTitle.results(shown)

      true ->
        Kati.Screens.AddTitle.nothing_card(shown, assigns.query, assigns[:search_error])
    end
  end

  @doc """
  Three skeleton rows in the result row's own shape, while a query is in flight.

  Board 308: *"never a spinner — 87's rule, and this sheet is the same list."*
  A spinner says *something is happening*; a skeleton says *what is coming and
  how much of it*, which is the honest claim for a list.
  """
  @spec skeletons() :: map()
  def skeletons do
    ~MOB"""
    <Column fill_width={true}>
      {[1, 2, 3]
       |> Enum.map(fn _row -> Kati.Screens.AddTitle.skeleton_row() end)
       |> Enum.intersperse(Kati.Screens.AddTitle.row_gap())}
      <Spacer size={26} />
    </Column>
    """
  end

  @doc false
  def skeleton_row do
    ~MOB"""
    <Row
      fill_width={true}
      background={Palette.card()}
      corner_radius={18}
      shadow={Kati.Theme.shadow_card_soft()}
      padding_left={13}
      padding_right={13}
      padding_top={11}
      padding_bottom={11}
      align="center"
    >
      <Box width={44} height={62} corner_radius={10} background={Palette.placeholder()} />
      <Spacer size={13} />
      <Column weight={1.0}>
        <Box width={150} height={13} corner_radius={6} background={Palette.placeholder()} />
        <Spacer size={9} />
        <Box width={92} height={10} corner_radius={5} background={Palette.placeholder()} />
        <Spacer size={9} />
        <Box width={120} height={10} corner_radius={5} background={Palette.placeholder()} />
      </Column>
    </Row>
    """
  end
end
