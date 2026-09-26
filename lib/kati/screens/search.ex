defmodule Kati.Screens.Search do
  @moduledoc """
  Screen 19 — Search everything, pushed under Home.

  Built to `test/design/screens/19.html`: the `64px 21px 40px` frame with
  no dock, a focused field carrying its 2px ink ring and orange caret, four
  counted filter chips, and then the hits **grouped by where they live** —
  Screen, Calendar, Notes — with a recent-searches shelf underneath.

  ## Why the groups look different from each other

  Three sections, three shapes, on purpose. A title is a card with its poster
  and a chevron, because it is somewhere to go. Calendar hits are rows inside
  one card, because they are a schedule and the dates are the spine. Note hits
  are on cream and quote themselves with the match highlighted in place,
  because they are the user's own words. Flattening these into one list of identical rows
  would lose the only thing the screen is claiming: one query, four kinds of
  answer.

  ## The eyebrow dash is not always orange

  The first group's dash is `#E8823C`; every group after it is `#C4BDB3`. That
  is the design telling you where the strongest match is rather than
  decorating each heading equally, so `Kati.UI.eyebrow/2` is used for the
  first and `section/2` here draws the muted ones. Orange still means
  new/now — here, *this is the hit*.

  ## What the chips do

  The four counted chips narrow the page to one group — Screen, Calendar or
  Notes — and "All" puts all three back. The recent shelf is not narrowed with
  them: it is a shortcut into a new search, not a result, and hiding the user's
  own history because they filtered to Calendar would be an odd punishment.

  A recent chip fills to show it is picked **and runs**. It did neither for a
  while, and the reason it gave was conditional rather than permanent: writing
  the word into the field would have left six hits for `hollow` sitting under a
  query that said `dentist`, because until an index existed the screen could
  not answer the new question. `Kati.Search.Query.run/1` is that index and this
  screen already re-runs it on every keystroke, so the field and the hits move
  together — which is the whole of what the old reasoning was protecting.

  ## Not `Kati.Screens.Pushed`

  The drawing puts the back pill **in the flow**, at the top of the scroll,
  with its own `#FBFAF8` fill and button shadow — not floating over the
  content at 54pt like the shared pushed chrome. Using the shared chrome would
  draw a second, differently styled pill on top of the search field, so this
  screen owns its frame and its dismissal, the way screens 06 and 08 do. It
  owns the pill's *label* too, and that one is the push's. It read `Home` from
  every door, and only one of the doors is Home — screen 28. Home's own search
  bar opens board 86, so the pill named the one screen it could not have been
  reached from. `Home` is still what a push naming nothing gets, because it is
  the word board 19 draws.

  ## Where every hit comes from

  `Kati.Search.Query.run/1` — the store, read on every keystroke: titles and
  episodes from `Kati.Media`, events from `Kati.Calendars`, books from
  `Kati.Books` and notes from `Kati.Media.Watch.review`. The chip counts are
  counts of that result set (`Kati.Search.Query.chip_counts/1`), and the
  recent shelf is `Kati.Search.Recent`, the reader's own queries. Nothing
  typed is the idle page; a query that matched nothing in the library says so
  in one quiet line.

  ## TMDB, under the library

  Under the library's hits, and under the Screen and All chips only, sits an
  *On TMDB* section (`on_tmdb/4`, state in `Kati.Search.OnTmdb`): the same
  query, sent to `Kati.Media.Tmdb.search/1` once the typing stops
  (`Kati.Media.SearchDebounce`), in a task, with skeleton rows while it is out.
  A title already listed above is not listed again, a row the reader keeps
  opens its own page, a row they do not opens that page as a preview with
  *Add to library* on it (`Kati.Screens.TitlePreview`), and the add disc adds
  from where the row is. The
  chip counts stay counts of the library: TMDB's rows are not the reader's,
  and a chip saying 20 over a shelf of 2 would be the catalogue talking.

  Only when TMDB also finds nothing does the page offer the hand-typed form.

  ## What the recent shelf remembers

  A query the reader committed — the keyboard's search key, a result opened
  or added, a recent line tapped — and never a keystroke. See
  `Kati.Search.Recent.remember/1`.

  `drawn_results/0` and `drawn_recent/0` are board 19's transcription, and
  only `Kati.ScreenDesignLiteralTest` installs them.
  """
  use Mob.Screen
  use Gettext, backend: Kati.Gettext
  import Mob.Sigil

  alias Kati.Components.MishkaChip
  alias Kati.Components.MishkaSeparator
  alias Kati.Search.OnTmdb
  alias Kati.Theme.Palette
  alias Kati.UI

  # The label the drawing's back pill carries, and the answer for a push that
  # names no other. Board 19 draws `Home`, so a bare push still draws `Home`.
  # `Kati.Screens.Pushed.back_vocabulary/0` carries this word and thirty-two
  # others as literal `gettext/1` calls, which is what keeps them extractable;
  # this is a default rather than a second copy of one.

  # `recent` is nil because that is the state the drawing is in: no recent
  # search picked out of the shelf. `query` and `filter` were the drawing's too
  # and are now the push's, defaulting to exactly what they were — see
  # `opening_query/1` and `Kati.Search.narrowable/1`. A push that says nothing
  # is the gallery's and the sweeps', and it takes the same three values it
  # always took.
  def mount(params, _session, socket) do
    Mob.Theme.set(Kati.Theme.current())
    # Resolves the stored locale into THIS process. `Gettext.put_locale/2`
    # snapshots into the calling process exactly as `Mob.Theme.set/1` does,
    # and a screen is its own process — see `Kati.Locale.activate/0`.
    Kati.Locale.activate()
    params = params || %{}
    query = Kati.Screens.Search.opening_query(params)
    results = Kati.Search.Query.run(query)
    tmdb_ready = Kati.Media.Tmdb.usable?()
    tmdb = OnTmdb.begin(query, tmdb_ready)
    if tmdb.status == :pending, do: Kati.Media.SearchDebounce.ask(self(), tmdb.query)

    {:ok,
     Mob.Socket.assign(socket,
       query: query,
       results: results,
       filter: Kati.Search.narrowable(Map.get(params, :scope, :all)),
       recent: nil,
       # Screen 06's counter, for the reason `handle_info({:tap, :clear}, …)`
       # gives. It starts at 1 when a push HANDED a query, so the field draws
       # it: the bridge remembers the last epoch per field, and a mount is not
       # itself a replacement, so a value handed to a field it has already
       # drawn is otherwise ignored.
       query_epoch: if(query == "", do: 0, else: 1),
       back: Map.get(params, :back, gettext("Home")),
       history: Kati.Search.Recent.all(),
       tmdb: tmdb,
       tmdb_epoch: 0,
       tmdb_ready: tmdb_ready
     )}
  end

  @doc """
  The query screen 86 last put in `Mob.State`, or `""`.

  It was the seam between the two boards — 86 is idle, 19 is results — and it is
  now the answer for a push that names no query of its own; `opening_query/1` is
  the seam. Reached with nothing, this page opens idle, which is a state the
  screen draws rather than a reason to substitute a drawing.

  `Kati.Search.handed_over/0` is where the key itself lives, and that is
  load-bearing rather than tidy: see `Kati.Search.hand_over/1`.
  """
  @spec handed_over() :: String.t()
  defdelegate handed_over(), to: Kati.Search

  @doc """
  The query this page opens on: the push's, or the one `Mob.State` still holds.

  A push that names a query wins, and every door into this screen now names
  one. That is the whole of the defect it closes: `Kati.Search.hand_over/1`
  writes `:kati_search_query` and nothing ever clears it — `Mob.State` is DETS,
  so the key outlives the launch — while every header search disc in the app
  pushed here bare. A disc has nothing typed behind it, so opening one showed
  results for a word somebody typed on screen 86 yesterday, under a field that
  agreed with them.

  A disc therefore names `""` rather than staying silent: silence is what lets
  the stale key answer. Silence is still a real answer for a door that has no
  query to name — `Kati.Screens.Gallery`, and any push made before 86 has run —
  and for those the key is exactly what it always was.
  """
  @spec opening_query(map()) :: String.t()
  def opening_query(params) do
    case Map.get(params, :query) do
      query when is_binary(query) -> query
      _unnamed -> handed_over()
    end
  end

  @doc """
  The result set board 19 was captured with — one query, `hollow`, matched four
  ways.

  Kept on the screen rather than in a fixture module, for the reason
  `Kati.Screens.Home.drawn_hero/0` is: it is the transcription the drawing was
  read from, and `Kati.ScreenDesignLiteralTest` installs it to compare the
  drawing against the drawing. What a device shows is
  `Kati.Search.Query.run/1`, and `Kati.ScreenEmptyDatabaseTest` is what says so
  — that a store with nothing in it answers with empty groups and not with
  this.

  The split is the whole point of the screen: a title, an episode, two calendar
  entries and a note about the same word are four different shapes, and the
  design keeps them four different shapes rather than flattening them into one
  list.

  Dates are typed as the drawing types them — `20 AUG`, with a leading zero on
  the second — because the column is 44pt wide and a ragged `6 AUG` would not
  line up under it. `inline_words` is how many words of the note's tail share
  the first line with the highlight: the browser wraps that paragraph and a
  `Row` does not, so the break is declared where the drawing breaks.
  """
  @spec drawn_results() :: map()
  def drawn_results do
    %{
      query: gettext("hollow"),
      idle?: false,
      titles: [
        %{
          title: gettext("The Long Hollow"),
          sub:
            gettext("Series · S%{n} · %{status}",
              n: Kati.Locale.number(2),
              status: Kati.Screens.Series.status_label(:watching)
            ),
          seed: "hollow71"
        },
        %{
          title: gettext("Hollow Season"),
          sub:
            gettext("Episode · S%{s}E%{e} · watched %{date}",
              s: Kati.Locale.number(2),
              e: Kati.Locale.number(5),
              date: Kati.Locale.date(~D[2026-08-12], :short)
            ),
          seed: "hollow71"
        }
      ],
      calendar: [
        %{
          date: Kati.UI.eyebrow_label(Kati.Locale.date(~D[2026-08-20], :short_padded)),
          title:
            gettext("%{title} S%{s}E%{e} airs",
              title: gettext("The Long Hollow"),
              s: Kati.Locale.number(2),
              e: Kati.Locale.number(6)
            ),
          time: Kati.Locale.time(~T[20:00:00])
        },
        %{
          date: Kati.UI.eyebrow_label(Kati.Locale.date(~D[2026-08-06], :short_padded)),
          title: gettext("%{title} — watched", title: gettext("Hollow Season")),
          time: Kati.Locale.time(~T[21:12:00])
        }
      ],
      # A list of one. The board draws one note because its query matched one,
      # not because the group holds one — the same thing its two Screen rows
      # say about `:titles`.
      notes: [
        %{
          eyebrow:
            Kati.UI.eyebrow_label(
              gettext("Note · %{date} · %{title}",
                date: Kati.Locale.date(~D[2026-08-06], :short),
                title: gettext("The Long Hollow")
              )
            ),
          lead: gettext("…the"),
          match: gettext("hollow"),
          tail: gettext("is a character, not a place. Watch E1 again before S3."),
          inline_words: 6
        }
      ],
      recent: Kati.Screens.Search.drawn_recent()
    }
  end

  @doc """
  The recent shelf board 19 draws, pre-chunked into the rows its `flex-wrap`
  produces.

  Three then one, which is what 402pt gives at these widths — and worth
  keeping, because it is what says the field remembers more than fits.
  `chunk/1` is what a device's own history goes through.

  ## Picked, not translated — the board says so

  Board 90's caption: *"Recent chips are the user's own words and are never
  translated."* Screen 86's own shelf carries the same sentence. So this is
  `Kati.Locale.pick/2` over two readers' histories rather than `gettext/1` over
  one reader's: board 19 was captured from somebody who had looked up a
  dentist, a leaving-soon shelf and a person; board 90 from somebody who had
  looked up a dentist, a leaving-soon shelf and a miso salmon. The first two
  agree by coincidence and the third does not, which is exactly what a
  translation of a search history would have hidden.

  The Persian shelf is three where the English one is four, because that is
  what its board draws — `chunk/1` wraps a real history at three either way.
  """
  @spec drawn_recent() :: [[String.t()]]
  def drawn_recent do
    Kati.Locale.pick(
      [
        ["dentist", "leaving soon", "ines karvel"],
        ["4 stars"]
      ],
      [["دندان‌پزشک", "به‌زودی حذف", "سالمون میسو"]]
    )
  end

  @doc "This reader's own history, in the rows the drawing wraps it into."
  @spec chunk([String.t()]) :: [[String.t()]]
  def chunk(queries), do: Enum.chunk_every(queries, 3)

  def render(assigns) do
    results = assigns.results
    filter = assigns.filter
    recent = assigns.recent
    query = Map.get(assigns, :query, results.query)
    history = Map.get(assigns, :history, [])
    # `Map.get` and not `assigns.back`, for the reason the two lines above are
    # written that way: `Kati.SearchRunTest` builds this map by hand and holds
    # five keys, so a required sixth would be a `KeyError` raised in a file that
    # has nothing to do with back pills.
    back = Map.get(assigns, :back, gettext("Home"))
    tmdb = Map.get(assigns, :tmdb, OnTmdb.idle())
    save_error = Map.get(assigns, :save_error)

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
          {Kati.Screens.Search.back(back)}
          {Kati.Screens.Search.field(query, true, Map.get(assigns, :query_epoch, 0))}
          {Kati.Screens.Search.chips(filter, results)}
          {Kati.Screens.Search.state_or_groups(results, filter, history)}
          {Kati.Screens.Search.on_tmdb(results, filter, tmdb, save_error)}
          {Kati.Screens.Search.recent_shelf(results, history, recent)}
        </Column>
      </Scroll>
    </Box>
    """
  end

  def handle_info({:tap, :back}, socket), do: {:noreply, Kati.Screens.Resume.pop(socket)}

  @doc """
  Every keystroke, run against the library — and TMDB asked once it settles.

  No debounce for the library, and `Kati.Search.debounce_ms/0` is not being
  ignored: this reads SQLite on the device and `Kati.Search.Query.run/1`
  narrows in Elixir, so a keystroke costs a scan of a personal library. TMDB is
  a request, so it waits for `Kati.Media.SearchDebounce` and goes out in a task
  (`Kati.Search.OnTmdb.fetch/3`); `:tmdb_epoch` moves on every keystroke, so an
  answer to a query the reader has typed past is dropped when it lands.

  Nothing is remembered here. A keystroke is a word on the way to a query, not
  a query — see `Kati.Search.Recent.remember/1`.
  """
  def handle_info({:change, :query, typed}, socket) when is_binary(typed) do
    {:noreply,
     socket
     |> Mob.Socket.assign(:query, typed)
     |> Mob.Socket.assign(:results, Kati.Search.Query.run(typed))
     |> Kati.Screens.Search.ask_tmdb(typed, :debounced)}
  end

  # The keyboard's search key: the query is committed, and TMDB is asked now
  # rather than after the pause.
  def handle_info({:submit, :commit}, socket) do
    query = Map.get(socket.assigns, :query, "")

    {:noreply,
     socket
     |> Kati.Screens.Search.commit()
     |> Kati.Screens.Search.ask_tmdb(query, :now)}
  end

  # The pause after the typing. Asked only if it is still the query in the
  # field and the section is still waiting on it; one request per epoch.
  def handle_info({:search_ready, query}, socket) when is_binary(query) do
    tmdb = Map.get(socket.assigns, :tmdb, OnTmdb.idle())
    epoch = Map.get(socket.assigns, :tmdb_epoch, 0)
    current = socket.assigns |> Map.get(:query, "") |> String.trim()

    if query == current and tmdb.status == :pending and tmdb.requested != epoch do
      OnTmdb.fetch(self(), epoch, query)
      {:noreply, Mob.Socket.assign(socket, :tmdb, %{tmdb | requested: epoch})}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:tmdb_answer, epoch, query, result}, socket) do
    tmdb = Map.get(socket.assigns, :tmdb, OnTmdb.idle())

    if epoch == Map.get(socket.assigns, :tmdb_epoch, 0) and tmdb.query == query do
      {:noreply, Mob.Socket.assign(socket, :tmdb, OnTmdb.answered(tmdb, result))}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:tap, :add_tmdb_token}, socket),
    do: {:noreply, Kati.UI.TmdbPrompt.open(socket, "Search")}

  def handle_info({:tap, :clear_recent}, socket) do
    Kati.Search.Recent.forget!()

    {:noreply,
     socket
     |> Mob.Socket.assign(:history, [])
     |> Mob.Socket.assign(:recent, nil)}
  end

  # The query goes with it. The push was bare, so a reader who searched for
  # *Estuary*, was told nothing matched, and pressed *or add it by hand* landed
  # on an empty title field and typed the word the app had just shown them.
  #
  # Through 154's own ONE-SHOT key rather than either obvious alternative.
  # `Kati.Search.hand_over/1`, which *Look it up* uses one clause up, writes a
  # DETS key nothing clears — screens 03 and 20 both carry a comment about what
  # that cost, the Library's disc opening *"somebody's last search, from a
  # previous launch"*. And a nav param makes 154 a params reader to
  # `Kati.ScreenParamsSweepTest`, whose every question assumes the key NAMES A
  # ROW: that an id matching nothing draws what a bare push draws, and that a
  # control must not write while the row it was named is gone. A prefill is
  # neither, and 154 resolves nothing — it creates.
  #
  # `prefill/1` is `hand_over/1`'s shape one file over: `take_prefill/0`
  # deletes as it reads, so it fills this one arrival and no other.
  def handle_info({:tap, :add_by_hand}, socket) do
    Kati.Screens.AddByHand.prefill(socket.assigns.query)

    {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.AddByHand.for_locale())}
  end

  def handle_info({:tap, :clear}, socket) do
    {:noreply,
     socket
     |> Mob.Socket.assign(:query, "")
     # The bump is what makes the FIELD empty as well as the assign, and
     # without it this control HALF worked: the counts went to zero and the
     # word the reader had typed stayed sitting in the box, so the page read as
     # "no results for hollow" over a query it had just thrown away. The bridge
     # remembers the last epoch it saw per field and ignores a `value` for a
     # field it has already drawn — `K-46` in `native/LEDGER.md`, and screen 06
     # has carried the same counter since it was found there.
     #
     # The audit called this control inert on the strength of
     # `Kati.ScreenTapSweepTest`'s own note — the sweep reaches 19 with an empty
     # field, where clearing is correctly a no-op. Pressed over a real query on
     # the device it was not inert; it was wrong.
     |> Mob.Socket.assign(:query_epoch, (socket.assigns[:query_epoch] || 0) + 1)
     |> Mob.Socket.assign(:results, Kati.Search.Query.run(""))
     |> Kati.Screens.Search.ask_tmdb("", :now)
     |> Mob.Socket.assign(:history, Kati.Search.Recent.all())}
  end

  # One clause per PREFIX rather than per control: the tag carries the label,
  # the event or the title, so a fifth filter, a fifth recent search or a
  # seventh hit is a change to the result set and not to this case.
  def handle_info({:tap, tag}, socket) do
    case Atom.to_string(tag) do
      # The chip, and the cross-scope row that offers the same move (#117). Two
      # prefixes because two nodes cannot share one tag, one clause because it
      # is one action.
      "filter_" <> key ->
        {:noreply, Mob.Socket.assign(socket, :filter, String.to_existing_atom(key))}

      "go_" <> key ->
        {:noreply, Mob.Socket.assign(socket, :filter, String.to_existing_atom(key))}

      # A Calendar hit, by its own event. Screen 31 answers an id that names
      # nothing with its own drawing rather than a crash, which is what makes
      # a row deleted on another device a page instead of a dead letter.
      "event_" <> id ->
        {:noreply,
         socket
         |> Kati.Screens.Search.commit()
         |> Mob.Socket.push_screen(Kati.Screens.EventDetail, %{id: id})}

      # A Screen hit, by its own title — `hit_tag/1`, resolved against the very
      # list the group was drawn from, which is `Kati.Screens.Library`'s rule
      # for the identical two prefixes.
      "open_film_" <> _title ->
        {:noreply,
         socket
         |> Kati.Screens.Search.commit()
         |> Kati.Screens.Search.open_hit(tag, Kati.Screens.Film)}

      "open_series_" <> _title ->
        {:noreply,
         socket
         |> Kati.Screens.Search.commit()
         |> Kati.Screens.Search.open_hit(tag, Kati.Screens.Series)}

      # An episode hit opens the SERIES it belongs to, because that is where an
      # episode lives — screen 04's list is the running order, and Kati has no
      # episode page. `open_hit/2` needs no change: it re-runs `hit_tag/1` over
      # `results.titles`, which is the list episodes now live in, and the row's
      # `:id` is already the tracked title's.
      "open_episode_" <> _source_id ->
        {:noreply,
         socket
         |> Kati.Screens.Search.commit()
         |> Kati.Screens.Search.open_hit(tag, Kati.Screens.Series)}

      # The shelf is a shortcut INTO a query: the field takes the line, the
      # library and TMDB are asked for it, and it counts as committed.
      "recent_" <> label ->
        {:noreply,
         socket
         |> Kati.Screens.Search.run_committed(label)
         |> Mob.Socket.assign(:recent, label)}

      # The idle page's shelf — `Kati.Screens.SearchIdle.recent/1`'s rows, by
      # the line they were drawn from.
      "repeat_query_" <> line ->
        query = Kati.Screens.SearchIdle.resolve(line, Map.get(socket.assigns, :history, []))
        {:noreply, Kati.Screens.Search.run_committed(socket, query)}

      "add_" <> position ->
        {:noreply, Kati.Screens.Search.add_from_tmdb(socket, position)}

      "tmdb_open_" <> position ->
        {:noreply, Kati.Screens.Search.open_tmdb(socket, position)}

      _other ->
        {:noreply, socket}
    end
  end

  # Coming back to this page after something above it was written. A
  # popped-to screen restores its saved socket (`Kati.Screens.Resume`), so the
  # results were the ones computed before the reader left: search *quiet*,
  # open the hand-added film it found, remove it, press back — and the removed
  # film was still listed, counted, and a tap away from a page about a title
  # that no longer exists.
  #
  # So the query is run again and the history re-read. The query, the chip and
  # the picked recent are the reader's and stay as they were; the field's epoch
  # does not move, because the words in it have not changed. This screen is
  # `use Mob.Screen` rather than `Kati.Screens.Pushed`, so the clause is the
  # routing, as it is on screens 04 and 08.
  def handle_info({:kati, :resumed, _payload}, socket) do
    query = Map.get(socket.assigns, :query, "")

    {:noreply,
     socket
     |> Mob.Socket.assign(:results, Kati.Search.Query.run(query))
     |> Mob.Socket.assign(:history, Kati.Search.Recent.all())
     |> Kati.Screens.Search.refresh_tmdb(query)}
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  @doc """
  Move the TMDB section onto `query`: a new epoch, and the request either
  waited for (`:debounced`, a keystroke) or sent now (`:now`, a committed
  query). Under the minimum, or with no token, nothing is sent.
  """
  @spec ask_tmdb(Mob.Socket.t(), String.t(), :debounced | :now) :: Mob.Socket.t()
  def ask_tmdb(socket, query, how) do
    epoch = Map.get(socket.assigns, :tmdb_epoch, 0) + 1
    tmdb = OnTmdb.begin(query, Map.get(socket.assigns, :tmdb_ready, false))

    tmdb =
      case {tmdb.status, how} do
        {:pending, :debounced} ->
          Kati.Media.SearchDebounce.ask(self(), tmdb.query)
          tmdb

        {:pending, :now} ->
          OnTmdb.fetch(self(), epoch, tmdb.query)
          %{tmdb | requested: epoch}

        _nothing_to_send ->
          tmdb
      end

    socket
    |> Mob.Socket.assign(:tmdb_epoch, epoch)
    |> Mob.Socket.assign(:tmdb, tmdb)
    |> Mob.Socket.assign(:save_error, nil)
  end

  @doc """
  The TMDB section on a return to this page: the rows re-marked against the
  shelf, which a title page above may have changed — or, when the section was
  the missing-token door and a token now exists, the query asked again.
  """
  @spec refresh_tmdb(Mob.Socket.t(), String.t()) :: Mob.Socket.t()
  def refresh_tmdb(socket, query) do
    socket = Mob.Socket.assign(socket, :tmdb_ready, Kati.Media.Tmdb.usable?())

    case Map.get(socket.assigns, :tmdb, OnTmdb.idle()) do
      %{status: :error, reason: :no_api_key} ->
        if socket.assigns.tmdb_ready,
          do: Kati.Screens.Search.ask_tmdb(socket, query, :now),
          else: socket

      tmdb ->
        Mob.Socket.assign(socket, :tmdb, %{tmdb | rows: OnTmdb.mark(tmdb.rows)})
    end
  end

  @doc "Remember the query in the field, because the reader has committed to it."
  @spec commit(Mob.Socket.t()) :: Mob.Socket.t()
  def commit(socket) do
    Kati.Search.Recent.remember(Map.get(socket.assigns, :query, ""))
    Mob.Socket.assign(socket, :history, Kati.Search.Recent.all())
  end

  @doc """
  Put `query` in the field as a committed query: the field redrawn with it,
  the library searched, TMDB asked at once, and the shelf told.
  """
  @spec run_committed(Mob.Socket.t(), String.t()) :: Mob.Socket.t()
  def run_committed(socket, query) do
    socket
    |> Mob.Socket.assign(:query, query)
    |> Mob.Socket.assign(:query_epoch, (socket.assigns[:query_epoch] || 0) + 1)
    |> Mob.Socket.assign(:results, Kati.Search.Query.run(query))
    |> Kati.Screens.Search.commit()
    |> Kati.Screens.Search.ask_tmdb(query, :now)
  end

  @doc """
  The add disc on a TMDB row.

  A row the reader does not keep is tracked through
  `Kati.Screens.AddTitle.track/3` — screen 06's own write — and the page is
  re-read, so the title now answers as a library hit and opens its page. A row
  already kept is not taken back off the shelf from here: its disc opens it,
  as the row does, because removing a title with a history behind it is the
  title page's decision and not a search result's.
  """
  @spec add_from_tmdb(Mob.Socket.t(), String.t()) :: Mob.Socket.t()
  def add_from_tmdb(socket, position) do
    tmdb = Map.get(socket.assigns, :tmdb, OnTmdb.idle())

    case OnTmdb.at(tmdb, position) do
      nil ->
        socket

      %{id: id} = row when is_binary(id) ->
        Kati.Screens.Search.open_kept(socket, row)

      row ->
        Kati.Screens.Search.track_row(Kati.Screens.Search.commit(socket), tmdb, row)
    end
  end

  @doc false
  @spec track_row(Mob.Socket.t(), OnTmdb.t(), map()) :: Mob.Socket.t()
  def track_row(socket, tmdb, row) do
    case Kati.Screens.AddTitle.track(row.title, row, :not_started) do
      {:ok, _tracked} ->
        socket
        |> Mob.Socket.assign(:tmdb, %{tmdb | rows: OnTmdb.mark(tmdb.rows)})
        |> Mob.Socket.assign(:results, Kati.Search.Query.run(socket.assigns.query))
        |> Mob.Socket.assign(:save_error, nil)

      {:error, _reason} = error ->
        Mob.Socket.assign(socket, :save_error, Kati.Write.message(error))
    end
  end

  @doc """
  A TMDB row's body: its own page when the reader keeps it, and its preview
  otherwise — `Kati.Screens.TitlePreview`, the same page with *Add to library*
  where the reader's own history would be.
  """
  @spec open_tmdb(Mob.Socket.t(), String.t()) :: Mob.Socket.t()
  def open_tmdb(socket, position) do
    case OnTmdb.at(Map.get(socket.assigns, :tmdb, OnTmdb.idle()), position) do
      %{id: id} = row when is_binary(id) ->
        Kati.Screens.Search.open_kept(socket, row)

      %{source: :tmdb} = row ->
        socket
        |> Kati.Screens.Search.commit()
        |> Kati.Screens.TitlePreview.push(row, "Search")

      nil ->
        socket
    end
  end

  @doc false
  @spec open_kept(Mob.Socket.t(), map()) :: Mob.Socket.t()
  def open_kept(socket, row) do
    socket
    |> Kati.Screens.Search.commit()
    |> Mob.Socket.push_screen(OnTmdb.destination(row), %{id: row.id, back: "Search"})
  end

  @doc """
  Open `module` on the hit that carries `tag`.

  `Kati.Screens.Library.open_tile/3`'s rule again, over this screen's own
  group: the tag is resolved by re-running `hit_tag/1` over `results.titles`
  rather than by reversing the string, and a hit with no id pushes **nothing**.
  A cached title nobody keeps is a real hit — it matched — but there is no
  shelf row for it to open, and a destination handed no id draws its own
  fixture branch rather than the title that was tapped.

  The push names `back: "Search"`, because that is where the pill returns to.
  Screens 04 and 08 default theirs to `Library` — the door almost every push
  onto them comes through — so a hit opened from here read *Library* over a
  back that landed on this page. The English word is the catalogue key:
  `Kati.Screens.Pushed.back_label/2` translates it on the far side.
  """
  @spec open_hit(Mob.Socket.t(), atom(), module()) :: Mob.Socket.t()
  def open_hit(socket, tag, module) do
    row = Enum.find(socket.assigns.results.titles, &(Kati.Screens.Search.hit_tag(&1) == tag))

    case row && Map.get(row, :id) do
      # A hit with no tracked row is a title somebody looked up on the add
      # sheet and never shelved — `cached_for/2` reads the whole cache. Pushing
      # bare drew the FIXTURE branch of screen 04 or 08, so a chevron on
      # `Emergence` opened a page about The Long Hollow.
      #
      # It carries no tap at all now: `hit_tag/1` refuses a row with no id, so
      # the card is a card and not a door. The *On TMDB* section under the
      # library is where a title nobody keeps is added from.
      nil -> socket
      id -> Mob.Socket.push_screen(socket, module, %{id: id, back: "Search"})
    end
  end

  # A Row, not a Box: the pill hugs its label and the drawing's asymmetric
  # `padding:0 16px 0 12px` keeps the chevron optically centred against text
  # that has no left bearing.
  #
  # The label is the caller's because back goes wherever this screen was pushed
  # from, and `Home` was the one screen that could not push it — home.ex sends
  # its own search bar to `Kati.Screens.SearchIdle`. The default keeps board
  # 19's word for a push that names no other.
  @doc false
  def back(label \\ gettext("Home")) do
    tap = {self(), :back}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Row
          height={44}
          corner_radius={22}
          background={Palette.card()}
          shadow={Kati.Theme.shadow_button()}
          padding_left={12}
          padding_right={16}
          align="center"
          on_tap={tap}
        >
          {Kati.UI.symbol(Kati.Screens.Pushed.back_glyph(), size: 17)}
          <Spacer size={6} />
          <Text
            text={label}
            text_size={13.5}
            font_weight="semibold"
            letter_spacing={-0.01}
            text_color={:on_surface}
            max_lines={1}
          />
        </Row>
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  # `0 0 0 2px #1A1917` is a ring, so it is a border; the drawing's remaining
  # `0 8px 18px -14px rgba(26,25,23,.6)` is a single layer and darker than
  # `Kati.Theme.shadow_search/0`, so it is written out rather than borrowed.
  #
  # The clear disc says `fill_width={false}` and has to. A box with no numeric
  # width is force-filled — upstream Mob's behaviour, which `K-17
  # box-hugs-when-told` in `native/LEDGER.md` exists to give an opt-out from —
  # so the disc took 774 of the row's 876 pixels and the weighted field beside
  # it measured 63. Weighted children are laid out after unweighted ones, so
  # the field got whatever the disc left. Nothing caught it: the design sweeps
  # compare a tree against the board and neither has a width, and the field was
  # always empty on open, so an invisible value and an invisible placeholder
  # looked the same. It showed the moment screen 19 started opening on the
  # query it was pushed with.
  @doc false
  def field(query, live? \\ true, epoch \\ 0) do
    # `live?: false` is board 89, which draws this field four times over — once
    # per edge state. Four live fields on one page means four nodes called
    # `search_query` and four called `clear`, and `onNodeWithTag` throws on the
    # second match: a device test could address none of them. A reference sheet
    # draws a picture of a control, so the picture carries no name and no tap.
    assigns =
      if live? do
        %{
          query: query,
          id: "search_query",
          on_change: {self(), :query},
          on_submit: {self(), :commit},
          clear: {self(), :clear},
          epoch: epoch
        }
      else
        %{query: query, id: nil, on_change: nil, on_submit: nil, clear: nil, epoch: epoch}
      end

    # `min_height`, not `height`. `Kati.DynamicTypeTest` states the rule: a
    # fixed height is a SHAPE, and a number measured from a line of text is a
    # floor. 52 is the second — one line of 13.5pt plus the drawing's padding —
    # and as a cap it clipped the reader's own query at 235%, descenders first,
    # which is the one thing a search field may not do. Board 91 draws this
    # field at 235% holding `the long hollow estuary` in full.
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        min_height={52}
        corner_radius={26}
        background={Palette.card()}
        border_width={2}
        border_color={Palette.ink()}
        shadow="0 8 18 -14 #991A1917"
        padding_left={18}
        padding_right={18}
        padding_top={6}
        padding_bottom={6}
        align="center"
      >
        {Kati.UI.symbol("search", size: 20)}
        <Spacer size={11} />
        <TextField
          value={@query}
          value_epoch={@epoch}
          placeholder={Kati.Search.placeholder()}
          return_key="search"
          weight={1.0}
          accessibility_id={@id}
          on_change={@on_change}
          on_submit={@on_submit}
        />
        <Spacer size={8} />
        <Box on_tap={@clear} fill_width={false}>
          {Kati.UI.symbol("cancel", size: 19, color: Palette.rail_idle(), fill: true)}
        </Box>
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc """
  The four counted chips, counting the result set.

  Which is what screen 88 specifies them as and what they have always claimed
  to be — `Kati.Search.Query.chip_counts/1` derives them from the rows rather
  than from a typed list, so a chip saying 4 over a list of 3 is now
  impossible rather than merely discouraged.

  Selection comes from the assign, so one place knows which chip is lit. It
  starts on `All`, which is the chip the drawing fills.
  """
  @spec chips(String.t(), map()) :: map()
  def chips(active, results) do
    # Board 312: **the chips stay, their counts go.** 86 already rules counts
    # are withheld while the query is empty — *"eight zeroes read as an empty
    # app"* — and the active chip stays active, so the scope the reader chose is
    # not silently reset under them.
    counts =
      if Map.get(results, :idle?, false) do
        Enum.map(Kati.Search.Query.chip_counts(results), fn {key, label, _zero} ->
          {key, label, nil}
        end)
      else
        Kati.Search.Query.chip_counts(results)
      end

    rail =
      counts
      |> Kati.Screens.Search.chip_rows()
      |> Enum.map(fn line ->
        Kati.Screens.Search.chip_line(
          line
          |> Enum.map(fn {key, label, count} ->
            Kati.Screens.Search.chip(key, label, count, key == active)
          end)
          |> Enum.intersperse(Kati.Screens.Search.gap())
        )
      end)
      |> Kati.Screens.Search.chip_stack()

    assigns = %{rail: rail}

    ~MOB"""
    <Column fill_width={true}>
      {@rail}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc "The drawing's 7pt flex gap, between chips and between chip rows."
  def gap, do: ~MOB"<Spacer size={7} />"

  @doc """
  The scope chips, on one scrolling line — board 313's ruling.

  ## Two boards disagreed, and 313 settled it

  Board 91 said the chips must WRAP: *"a horizontal scroll at this size hides
  half the scopes behind a gesture."* That objection is right and this row was
  built on it — three per line, balanced rather than greedy, so four chips came
  out two and two rather than three and a widow.

  Board 313 revisits it at 235% with both drawings side by side and picks the
  other one, for two reasons the wrapped version cannot answer:

    * **The bridge has no `FlowRow`** — filed as
      [mishka-group/kati#98](https://github.com/mishka-group/kati/issues/98) —
      so a real wrap is not buildable at all; what was here was a wrap decided
      by count, which holds only while the count does.
    * **Three lines is the results off-screen.** *"Better to read, and three
      lines tall — on a 235% page where the field alone is 62pt, that is the
      results pushed off-screen."*

  And it answers 91's objection rather than ignoring it: the scroll carries a
  **leading chevron**, *"because a horizontal scroll with no affordance hides
  half the scopes behind a gesture nobody knows is there."* See `chip_line/1`.

  277's rule — that at the largest size rows become columns — is about rows of
  CONTENT. A scope chip row is chrome, and 313 draws the distinction on its own
  face: the see-all row does become a column, because it is content.

      iex> Kati.Screens.Search.chip_rows([:a, :b, :c, :d, :e, :f])
      [[:a, :b, :c, :d, :e, :f]]

      iex> Kati.Screens.Search.chip_rows([])
      []
  """
  def chip_rows([]), do: []

  # ONE line, since board 313. This wrapped into up to three, and 313 makes the
  # trade explicitly: *"The bridge has no FlowRow — filed as
  # mishka-group/kati#98. A drawing that wraps needs that; a drawing that
  # scrolls does not."*
  #
  # And the wrapped version is the one it rejects on its own merits as well as
  # on the bridge's: *"Better to read, and three lines tall — on a 235% page
  # where the field alone is 62pt, that is the results pushed off-screen."*
  # 277's rule that rows become columns is about rows of CONTENT; a scope chip
  # row is chrome, and chrome may scroll.
  def chip_rows(chips), do: [chips]

  @doc """
  The chip row, scrolling, with the affordance board 313 requires.

  *"Both drawn, because a horizontal scroll with no affordance hides half the
  scopes behind a gesture nobody knows is there."* The chevron is the mark; it
  is not a control, because the row it points along is already draggable and a
  second way to move it would be two answers to one question.

  ## The mark needed `weight={1.0}` on the scroll, and the phone is what said so

  313's affordance was written and never appeared. A `Scroll` with no width and
  no weight force-fills — upstream Mob's behaviour, the same K-17
  box-hugs-when-told case `field/2`'s clear disc is written against — so the
  scroll took the whole row and pushed the chevron past its right edge. The
  host sweeps could not see it: they compare a tree against a board and neither
  has a width, and the symbol was in the tree throughout.

  It points the reading direction, not a fixed way: `chevron_right` in English
  and `chevron_left` in Persian, which is `Kati.Locale.forward_chevron/0`. On
  board 90 the row runs right to left and a chevron pointing right would have
  been an affordance for a gesture the page does not make.
  """
  @spec chip_line([map()]) :: map()
  def chip_line(chips) do
    assigns = %{chips: chips}

    ~MOB"""
    <Row fill_width={true} align="center">
      <Scroll axis="horizontal" weight={1.0}>
        <Row align="center">
          {@chips}
        </Row>
      </Scroll>
      <Spacer size={7} />
      {Kati.UI.symbol(Kati.Locale.forward_chevron(), size: 17, color: Kati.Theme.Palette.tertiary())}
    </Row>
    """
  end

  @doc false
  def chip_stack(lines) do
    assigns = %{lines: Enum.intersperse(lines, Kati.Screens.Search.gap())}

    ~MOB"""
    <Column fill_width={true}>
      {@lines}
    </Column>
    """
  end

  @doc """
  One counted filter chip — `Kati.Components.MishkaChip`, count in the
  **trailing slot**.

  The count is the label's own colour at .6 alpha, not a second token — the
  design tints it down rather than colouring it differently, so a chip reads
  as one object with a quiet number after it. That is also why the count goes
  in as a *node* rather than as a string: `trailing` renders a string in the
  chip's own ink and size, and this one is mono at 10.5 in a colour of its
  own.

  Two of the port's props are new this round and both are load-bearing here.
  `trailing`/`trailing_gap` is the slot itself — before it a chip was a Box
  around exactly one Text, so a chip with a number after its name could not be
  built at all. The rest (`height`, `padding_x`/`padding_y`, `corner_radius`,
  `text_size`, `font_weight`, `max_lines`, `unchecked_color`,
  `unchecked_text_color`) are what let it be 32 tall on Kati's greys instead of
  the port's old hardcoded look.

  **Why the pixels do not move.** The chip was a `Row` holding label, gap and
  count; the port builds a `Box` holding a `Row` holding label, gap and count.
  The outer node hugs either way — a `Row` by nature, the `Box` by
  `fill_width={false}`, which the bridge reads since fence K-17 — and both run
  background → rounded clip → `padding(0, 14, 0, 14)` → `height(32)`, so the
  chip is 32 tall and `14 + label + 6 + count + 14` wide in both trees.

  The extra `Row` does not move the two runs either. Before, each Text was
  centred in the 32pt Row, putting both centres at 16. Now the inner `Row`
  centres the 10.5 count against the 12.5 label — this bridge's default
  vertical alignment for a `Row` is `CenterVertically`, so the port omitting
  `align` on it changes nothing — and the `Box` centres that group in the 32:
  `(32 - h) / 2 + h / 2` is 16 again.
  """
  def chip(key, label, count, on?) do
    # The tag carries the label, so one handler serves every chip.
    count_color = if on?, do: Palette.on_ink_count(), else: Palette.count_idle()

    MishkaChip.chip(
      label: label,
      checked: on?,
      # The KEY and not the label — see `Kati.Search.built?/1`.
      on_toggle: {self(), String.to_atom("filter_" <> Atom.to_string(key))},
      color: Palette.ink_fill(),
      text_color: Palette.on_ink(),
      unchecked_color: Palette.card(),
      unchecked_text_color: Palette.ink_soft(),
      height: 32,
      padding_x: 14,
      padding_y: 0,
      corner_radius: 16,
      text_size: 12.5,
      font_weight: :semibold,
      max_lines: 1,
      trailing: Kati.Screens.Search.chip_count(count, count_color),
      trailing_gap: 6
    )
  end

  # `nil` draws no trailing at all, which is board 312's *the chips stay, their
  # counts go* — and `to_string(nil)` would draw an empty mono node in the gap
  # rather than close it.
  @doc false
  def chip_count(nil, _color), do: nil

  def chip_count(count, color) do
    ~MOB"""
    <Text
      text={Kati.Locale.number(count)}
      font_family={Kati.Locale.mono_face(Kati.Locale.number(count))}
      text_size={10.5}
      text_color={color}
      max_lines={1}
    />
    """
  end

  @doc """
  The results, or the state that stands in for them.

  Three answers, and the screen has to tell them apart because a person can:

    * **nothing typed** — the field is waiting. Board 86 is the whole page for
      this, so here it is one line rather than a second idle screen.
    * **typed, matched nothing** — the app has looked. This is the one a
      results page must never draw as plain emptiness, because an empty list
      under a query reads as a search that broke.
    * **hits** — the drawing.

  `Kati.Search.Query.run/1` carries `:idle?` for exactly this: a query under
  `Kati.Search.minimum/1` is the screen waiting, and a long-enough one that
  matched nothing is the screen having looked.
  """
  @spec state_or_groups(map(), atom(), [String.t()]) :: map()
  def state_or_groups(results, filter, history) do
    cond do
      Map.get(results, :idle?, false) ->
        Kati.Screens.Search.waiting(history)

      Kati.Screens.Search.visible_groups(results, filter) != [] ->
        Kati.Screens.Search.groups(results, filter)

      # *Nothing in this scope* and *nothing anywhere*
      # are two different things and this page drew the second sentence for
      # both — narrow to Calendar over a query that found three films and the
      # page said **Nothing here**, which is the exact misreading board 89's
      # third band was drawn to prevent. The page already knows where the
      # answer is; withholding it is the defect.
      elsewhere = Kati.Screens.Search.elsewhere(results, filter) ->
        Kati.Screens.Search.cross_scope(filter, elsewhere)

      true ->
        Kati.Screens.Search.not_in_library()
    end
  end

  @doc """
  The scope holding the most hits, when the lit one holds none — or `nil`.

  `All` can never be the answer: it is every group at once, so a search with
  hits and an empty `All` is not a state. The largest rather than the first,
  because the offer is *where the answer is* and the answer is where most of
  it is; ties fall to `Kati.Search`'s own chip order, which is what
  `visible_groups/2` walks.

      iex> Kati.Screens.Search.elsewhere(%{titles: [1, 2], books: [], calendar: [], notes: []}, :calendar)
      {:screen, 2}

      iex> Kati.Screens.Search.elsewhere(%{titles: [], books: [], calendar: [], notes: []}, :calendar)
      nil
  """
  @spec elsewhere(map(), atom()) :: {atom(), pos_integer()} | nil
  def elsewhere(results, filter) do
    results
    |> Kati.Screens.Search.visible_groups(:all)
    |> Enum.reject(fn {scope, _key} -> scope == filter end)
    |> Enum.map(fn {scope, key} -> {scope, Kati.Screens.Search.count_of(results, key)} end)
    |> Enum.max_by(fn {_scope, n} -> n end, fn -> nil end)
  end

  @doc false
  @spec count_of(map(), atom()) :: non_neg_integer()
  def count_of(results, key), do: length(Map.get(results, key) || [])

  @doc """
  Board 89's third band, over a real result set: where the answer actually is.

  One row rather than an empty state, and the board's own argument for it is
  that the page already knows. `swap_horiz` leads because the offer is a change
  of scope rather than a new query, and `arrow_forward` closes it because
  tapping moves you rather than expanding anything in place.

  Its own `go_` tag rather than the chip's `filter_` one, though it does the
  same thing. Two nodes may not share an `accessibility_id`: `onNodeWithTag`
  throws on the second match, so a page drawing `filter_Screen` twice is a page
  no device test can touch — which is what this drew first, and what reading
  `ui.sh ids` on the Pixel_9a caught.
  """
  @spec cross_scope(atom(), {atom(), pos_integer()}) :: map()
  def cross_scope(filter, {scope, count}) do
    assigns = %{
      lead: gettext("Nothing in %{scope}. ", scope: Kati.Search.scope_label(filter)),
      over:
        ngettext("%{n} match in %{scope}", "%{n} matches in %{scope}", count,
          n: Kati.Locale.number(count),
          scope: Kati.Search.scope_label(scope)
        ),
      tap: {self(), String.to_atom("go_" <> Atom.to_string(scope))}
    }

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Kati.Theme.Palette.card()}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={15}
        align="center"
        on_tap={@tap}
      >
        {Kati.UI.symbol("swap_horiz", size: 19, color: Kati.Theme.Palette.ink_soft())}
        <Spacer size={12} />
        <Column weight={1.0}>
          {Kati.UI.rich_text([
            {@lead, [text_size: 13, text_color: :on_surface, base: true]},
            {@over, :bold}
          ])}
        </Column>
        <Spacer size={12} />
        {Kati.UI.symbol("arrow_forward", size: 17)}
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The groups a filter leaves that have anything in them.

  Both halves matter and the second one was missing. Board 19 is drawn with a
  hit in all three groups, so the screen drew all three unconditionally — and
  `note_lines/1` raised `BadMapError` on the `nil` note the moment a real query
  matched a title and nothing else. Which is the FIRST query anybody runs: a
  title added by hand has no note about it yet.

  The whole page went down, so it never stamped its name, so the device test
  timed out waiting for a screen rather than failing on a missing row — a
  render crash reads exactly like a navigation that did not happen.

  Empty groups are omitted rather than worded, which is screen 96's rule and
  the one `Kati.Screens.Home` follows for its own sections: a heading over
  nothing reads as something that failed to load.
  """
  @spec visible_groups(map(), atom()) :: [{atom(), atom()}]
  def visible_groups(results, filter) do
    [{:screen, :titles}, {:books, :books}, {:calendar, :calendar}, {:notes, :notes}]
    |> Enum.filter(fn {scope, _key} -> filter == :all or filter == scope end)
    |> Enum.reject(fn {_scope, key} -> Kati.Screens.Search.blank?(results, key) end)
  end

  @doc false
  @spec blank?(map(), atom()) :: boolean()
  def blank?(results, key), do: (Map.get(results, key) || []) == []

  @doc "Whether a result set matched nothing at all."
  @spec empty?(map()) :: boolean()
  def empty?(results) do
    (results.titles || []) == [] and (Map.get(results, :books) || []) == [] and
      (results.calendar || []) == [] and (Map.get(results, :notes) || []) == []
  end

  @doc """
  The page with nothing typed in the field.

  Board 19 is drawn mid-query and no board draws it empty, because until the
  field was real the design never put a person here without one. A person can
  now clear it, so the state exists and has to say something.

  Board 312: **it becomes 86, not 87** — 86's Recent group
  (`Kati.Screens.SearchIdle.recent/1`), the shortcut back into a query, over
  `Kati.Search.local_note/0`. With no history there is no Recent section at
  all: the owner's ruling, since an eyebrow over *Nothing searched yet* was a
  heading over nothing.
  """
  @spec waiting([String.t()]) :: map()
  def waiting(history) do
    assigns = %{recent: Kati.Screens.SearchIdle.recent(history)}

    ~MOB"""
    <Column fill_width={true}>
      {@recent}
      <Spacer size={18} />
      {Kati.UI.SettingsList.note("search", Kati.Search.local_note())}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  What a query that matched nothing in the library says: one quiet line.

  Not a card and not a way out. TMDB is asked in the section under it
  (`on_tmdb/4`), so the next answer is already on the page; a card offering to
  go and look somewhere else would offer what the page is doing.
  """
  @spec not_in_library() :: map()
  def not_in_library do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        {Kati.UI.symbol("info", size: 17, color: Palette.muted())}
        <Spacer size={8} />
        <Text
          text={gettext("Not in your library")}
          text_size={12.5}
          text_color={Palette.sub()}
          weight={1.0}
        />
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  The *On TMDB* section, under the library's groups — or nothing.

  Drawn under the All and Screen chips, because TMDB answers for films and
  series and nothing else; under Calendar or Notes it would be an answer to a
  question the reader narrowed away. Its heading takes the accent dash when the
  library drew nothing above it, by the positional rule `groups/2` follows.
  """
  @spec on_tmdb(map(), atom(), OnTmdb.t(), String.t() | nil) :: map() | []
  def on_tmdb(results, filter, tmdb, save_error \\ nil) do
    if Map.get(results, :idle?, false) or filter not in [:all, :screen] or tmdb.status == :idle do
      []
    else
      Kati.Screens.Search.tmdb_section(results, filter, tmdb, save_error)
    end
  end

  @doc false
  def tmdb_section(results, filter, tmdb, save_error) do
    label = gettext("On TMDB")

    heading =
      if Kati.Screens.Search.visible_groups(results, filter) == [],
        do: UI.eyebrow(label),
        else: Kati.Screens.Search.section(label)

    assigns = %{
      heading: heading,
      notice: Kati.Screens.AddTitle.save_notice(save_error),
      body:
        Kati.Screens.Search.tmdb_body(
          tmdb,
          Map.get(results, :titles) || [],
          Kati.Screens.Search.empty?(results)
        )
    }

    ~MOB"""
    <Column fill_width={true}>
      {@heading}
      {@notice}
      {@body}
    </Column>
    """
  end

  @doc false
  def tmdb_body(%{status: :pending}, _local, _nothing_local?),
    do: Kati.Screens.AddTitle.skeletons()

  def tmdb_body(%{status: :error, reason: :no_api_key}, _local, _nothing_local?),
    do: Kati.UI.TmdbPrompt.block(false)

  def tmdb_body(%{status: :error, reason: reason}, _local, _nothing_local?) do
    assigns = %{notice: Kati.UI.notice(Kati.Media.Tmdb.message(reason))}

    ~MOB"""
    <Column fill_width={true}>
      {@notice}
      <Spacer size={22} />
    </Column>
    """
  end

  def tmdb_body(%{status: :ready, rows: rows, query: query}, local, nothing_local?) do
    case {OnTmdb.shown(rows, local), rows} do
      {[], []} ->
        Kati.Screens.Search.nothing_on_tmdb(query, nothing_local?)

      {[], _all_above} ->
        Kati.Screens.Search.tmdb_line(gettext("TMDB found nothing beyond what you already keep."))

      {shown, _rows} ->
        Kati.Screens.Search.tmdb_rows(shown)
    end
  end

  def tmdb_body(_state, _local, _nothing_local?), do: []

  @doc """
  TMDB found nothing either. Said with the query in it, and — only when the
  library was empty too — the one way left: typing the title by hand.
  """
  @spec nothing_on_tmdb(String.t(), boolean()) :: map()
  def nothing_on_tmdb(query, nothing_local?) do
    by_hand =
      if nothing_local?,
        do:
          Kati.Screens.AddTitle.by_hand_row(
            gettext("Add \u201C%{query}\u201D by hand?", query: query)
          ),
        else: []

    assigns = %{
      line:
        Kati.Screens.Search.tmdb_line(
          gettext("Nothing on TMDB for \u201C%{query}\u201D", query: query)
        ),
      by_hand: by_hand
    }

    ~MOB"""
    <Column fill_width={true}>
      {@line}
      {@by_hand}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def tmdb_line(text) do
    assigns = %{text: text}

    ~MOB"""
    <Column fill_width={true} padding_left={2} padding_right={2}>
      <Text text={@text} text_size={12.5} text_color={Palette.sub()} />
      <Spacer size={14} />
    </Column>
    """
  end

  @doc false
  def tmdb_rows(rows) do
    ~MOB"""
    <Column fill_width={true}>
      {rows
       |> Enum.map(fn row -> Kati.Screens.Search.tmdb_row(row) end)
       |> Enum.intersperse(Kati.Screens.AddTitle.row_gap())}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  One TMDB row: screen 06's result row, with a body that opens the title — its
  own page when the reader keeps it, and its preview when they do not
  (`open_tmdb/2`). The disc still adds from the row.
  """
  def tmdb_row(row) do
    tap = {self(), String.to_atom("tmdb_open_" <> Integer.to_string(row.position))}

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
      on_tap={tap}
    >
      {Kati.Screens.AddTitle.thumb(row)}
      <Spacer size={13} />
      <Column weight={1.0}>
        <Text
          text={row.title}
          text_size={14}
          font_weight="bold"
          letter_spacing={Kati.Locale.tracking(-0.015)}
          text_color={:on_surface}
          max_lines={2}
        />
        <Spacer size={5} />
        <Text
          text={row.meta}
          font_family={Kati.Locale.mono_face(row.meta)}
          text_size={10.5}
          text_color={Palette.muted()}
          max_lines={1}
        />
      </Column>
      <Spacer size={13} />
      {Kati.Screens.AddTitle.add_button(row.added, row.position)}
    </Row>
    """
  end

  @doc """
  The result groups a filter leaves standing, in the drawing's order.

  "All" is every group, which is the page as drawn; any other chip is the one
  group it names. The recent shelf is not in here — it is a shortcut, not a
  result, and narrowing to Calendar should not hide the user's own history.

  The accent dash goes to whichever group is **first**, not to Screen
  specifically: the moduledoc's rule is positional, and orange means "this is
  the hit". Filtering to Notes makes Notes the hit.
  """
  @spec groups(map(), atom()) :: term()
  def groups(results, filter) do
    visible = results |> Kati.Screens.Search.visible_groups(filter) |> Enum.with_index()

    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(visible, fn {{scope, key}, i} ->
        Kati.Screens.Search.group(results, Kati.Search.scope_label(scope), key, i == 0)
      end)}
    </Column>
    """
  end

  @doc false
  def group(results, label, key, first?) do
    heading = if first?, do: UI.eyebrow(label), else: Kati.Screens.Search.section(label)
    body = Kati.Screens.Search.body(results, key)

    ~MOB"""
    <Column fill_width={true}>
      {heading}
      {body}
    </Column>
    """
  end

  @doc false
  def body(results, :titles), do: Kati.Screens.Search.titles(results)
  def body(results, :books), do: Kati.Screens.Search.books(results)
  def body(results, :calendar), do: Kati.Screens.Search.calendar(results)
  def body(results, :notes), do: Kati.Screens.Search.notes(results)

  # `Kati.UI.eyebrow/2` with the accent dash marks the first, strongest group;
  # every group after it takes the drawing's muted #C4BDB3 dash.
  @doc false
  def section(label) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        <Box width={13} height={2} corner_radius={1} background={Palette.rail_idle()} />
        <Spacer size={9} />
        <Text
          text={Kati.UI.eyebrow_label(label)}
          font_family={Kati.Locale.mono_face()}
          text_size={10.5}
          letter_spacing={Kati.Locale.tracking(0.16)}
          text_color={Palette.eyebrow()}
        />
      </Row>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc false
  def titles(results) do
    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(results.titles, fn row -> Kati.Screens.Search.title_row(row) end)}
      <Spacer size={13} />
    </Column>
    """
  end

  @doc """
  The Books group, which used to be four rows of the Screen one.

  Same card, its own heading and its own chip. A book still has nowhere to go —
  `Kati.Screens.BookDetail.load/1` discards the push's params — so `hit_tag/1`
  answers `nil` for it and the row draws no chevron, which is the honest shape
  for a hit with no door and is what it drew before. What changed is that it is
  no longer drawn under a heading that says SCREEN and counted by a chip that
  says films.
  """
  def books(results) do
    assigns = %{rows: Map.get(results, :books) || []}

    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(@rows, fn row -> Kati.Screens.Search.title_row(row) end)}
      <Spacer size={13} />
    </Column>
    """
  end

  @doc """
  One hit's tag, or `nil` for a hit with nowhere to go.

  The title, because a hit IS its title on this card and two nodes cannot share
  an `accessibility_id` — the same identity `Kati.Screens.Library.poster_tag/1`
  picks, and refused for the same reason: reversing the string is a guess, so
  the tag is resolved by re-running this function over the list the group was
  built from.

  `nil` for a book and for the drawing's own rows. A book has no destination
  that reads an id (`Kati.Screens.BookDetail.load/1` discards params), and
  `nil` is what `Kati.ScreenTapSweepTest` documents as "not tappable" rather
  than "broken".

      iex> Kati.Screens.Search.hit_tag(%{kind: :series, title: "The Long Hollow"})
      :open_series_The_Long_Hollow

      iex> Kati.Screens.Search.hit_tag(%{kind: :book, title: "Estuary"})
      nil
  """
  @spec hit_tag(map()) :: atom() | nil
  def hit_tag(row) do
    # An id as well as a kind. A cache-only hit — looked up on the add sheet,
    # never shelved — has a kind and no row to open, and drawing it with a
    # chevron meant a tap onto the fixture branch of screen 04 or 08: a
    # chevron on one title that opened a page about another.
    case {Map.get(row, :kind), Map.get(row, :id)} do
      # An episode's `:id` is the id of the TITLE it belongs to — screen 04 is
      # where an episode lives and Kati has no episode page — so the tag has to
      # come from somewhere else, or this row and its series row would share
      # one `accessibility_id` and `onNodeWithTag` would throw on the second
      # match. `:episode_id` is `Kati.Media.CachedEpisode.source_id`, unique by
      # that resource's own identity.
      {:episode, id} when is_binary(id) ->
        case Map.get(row, :episode_id) do
          episode_id when is_binary(episode_id) and episode_id != "" ->
            String.to_atom("open_episode_" <> episode_id)

          _unnamed ->
            nil
        end

      {kind, id} when kind in [:film, :series] and is_binary(id) ->
        Kati.Screens.Library.poster_tag(row)

      _no_door ->
        nil
    end
  end

  @doc false
  def title_row(row) do
    tag = Kati.Screens.Search.hit_tag(row)
    tap = tag && {self(), tag}

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.card()}
        corner_radius={18}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={13}
        padding_right={13}
        padding_top={10}
        padding_bottom={10}
        align="center"
        on_tap={tap}
      >
        {Kati.Screens.Search.thumb(row)}
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text
            text={row.title}
            text_size={13.5}
            font_weight="bold"
            text_color={:on_surface}
            max_lines={3}
          />
          <Spacer size={4} />
          <Text text={row.sub} text_size={11.5} text_color={Palette.sub()} max_lines={2} />
        </Column>
        <Spacer size={12} />
        {Kati.UI.symbol(Kati.Locale.forward_chevron(), size: 18, color: Palette.rail_idle())}
      </Row>
      <Spacer size={9} />
    </Column>
    """
  end

  @doc false
  def thumb(row) do
    case Kati.Design.Images.poster(row.seed) do
      nil ->
        ~MOB"<Box width={36} height={51} corner_radius={7} background={Palette.placeholder()} />"

      src ->
        ~MOB"""
        <Image src={src} width={36} height={51} corner_radius={7} content_mode="fill" />
        """
    end
  end

  @doc false
  def calendar(results) do
    last = length(results.calendar) - 1

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={15}
        padding_right={15}
        padding_top={4}
        padding_bottom={4}
      >
        {results.calendar
         |> Enum.with_index()
         |> Enum.map(fn {row, i} -> Kati.Screens.Search.calendar_row(row, i < last) end)}
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def calendar_row(row, rule?) do
    # `event_<id>` rather than `row_<kind>_<id>`: every hit in this group is a
    # `Kati.Calendars.Event` and there is no kind to route on — screen 19 draws
    # one Calendar group, not screen 02's four. A row with no id is the
    # drawing's and carries no tap.
    tap = Map.get(row, :id) && {self(), String.to_atom("event_" <> to_string(row.id))}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={13} padding_bottom={13} on_tap={tap}>
        <Column width={44}>
          <Text
            text={row.date}
            font_family={Kati.Locale.mono_face(row.date)}
            text_size={10}
            letter_spacing={Kati.Locale.tracking(0.06)}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
        <Spacer size={13} />
        <Text
          text={row.title}
          text_size={12.5}
          font_weight="semibold"
          text_color={:on_surface}
          weight={1.0}
          max_lines={1}
        />
        <Spacer size={13} />
        <Text
          text={row.time}
          font_family={Kati.Locale.mono_face(row.time)}
          text_size={11}
          text_color={Palette.muted()}
          max_lines={1}
        />
      </Row>
      {Kati.Screens.Search.hairline(rule?)}
    </Column>
    """
  end

  @doc false
  def hairline(false), do: ~MOB"<Spacer size={0} />"
  # `MishkaSeparator` rather than a hand-rolled Box, and `render: :box` rather
  # than the component's `:divider` default.
  #
  # `:divider` is NOT the Box this used to be. The comment that stood here said
  # it was — that Compose's `HorizontalDivider` is
  # `Box(fillMaxWidth().height(t).background(color))` — and that is wrong:
  # Material3 draws it as `Canvas { drawLine(strokeWidth = t.toPx()) }`, an
  # ANTIALIASED stroke. At this device's 2.6875x a 1dp rule gets a 3px canvas
  # and a 2.6875px stroke centred in it, so the bottom pixel row lands at ~69%
  # coverage — a full-width row 4-5/255 lighter than the two above it. The
  # adoption softened the hairline by one pixel row and nothing said so.
  #
  # `render: :box` is the component's filled-rect primitive: `<Box fill_width
  # height={thickness} background={color}>`, which is the node that was written
  # here by hand before the adoption, so the rule goes back to three full-colour
  # rows. (Its `<Spacer size={1} />` child is an iOS height workaround — on
  # Android the Box's own `height` pins it and the background covers it.)
  #
  # `color` is passed rather than left to the component's `:border` default:
  # Kati's border token is 0x14000000 and the drawing's rule is 0x121A1917.
  def hairline(true),
    do: MishkaSeparator.separator(color: Palette.hairline(), thickness: 1, render: :box)

  # The note cards carry no shadow in the drawing — cream is the ground for the
  # user's own words, and lifting them would make them compete with the hits.
  #
  # A LIST, not a card. Board 19 draws one note because its query matched one;
  # the same board draws two Screen rows and two Calendar rows and neither of
  # those groups is capped to what it drew. `Kati.Search.Query` ranked the
  # whole list and took the head, so the second-best note about the estuary had
  # nowhere on this page to be.
  @doc false
  def notes(results) do
    assigns = %{cards: Map.get(results, :notes) || []}

    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(@cards, fn card -> Kati.Screens.Search.note_card(card) end)}
      <Spacer size={15} />
    </Column>
    """
  end

  @doc false
  def note_card(note) do
    {inline, rest} = note_lines(note)

    ~MOB"""
    <Column fill_width={true}>
      <Column fill_width={true} background={Palette.cream()} corner_radius={20} padding={16}>
        <Text
          text={note.eyebrow}
          font_family={Kati.Locale.mono_face(note.eyebrow)}
          text_size={10}
          letter_spacing={Kati.Locale.tracking(0.14)}
          text_color={Palette.cream_meta()}
          max_lines={1}
        />
        <Spacer size={8} />
        <Row fill_width={true} align="center">
          <Text
            text={note.lead}
            text_size={13}
            line_height={1.55}
            text_color={Palette.cream_body()}
            max_lines={1}
          />
          <Spacer size={4} />
          <Row background={Palette.accent_fill()} align="center">
            <Text
              text={note.match}
              text_size={13}
              line_height={1.55}
              text_color={Palette.cream_body()}
              max_lines={1}
            />
          </Row>
          <Spacer size={4} />
          <Text
            text={inline}
            text_size={13}
            line_height={1.55}
            text_color={Palette.cream_body()}
            max_lines={1}
          />
        </Row>
        {Kati.Screens.Search.note_leading()}
        <Text text={rest} text_size={13} line_height={1.55} text_color={Palette.cream_body()} />
      </Column>
      {Kati.Screens.Search.note_gap()}
    </Column>
    """
  end

  # 9 between cards and 15 after the last, which is the 24 the single card
  # carried — `titles/1` does the identical arithmetic for the Screen group,
  # and board 19's own `gap:9px; margin-bottom` is where both numbers come
  # from. Splitting them is what lets a second note sit under the first at the
  # board's own rhythm instead of 24 away from it.
  @doc false
  def note_gap, do: ~MOB"<Spacer size={9} />"

  @doc """
  The half-leading `line_height` cannot supply, because it is trimmed away.

  `line_height={1.55}` on 13pt text asks for a 20.15pt line box, and the bridge
  does set it — but Compose's default `LineHeightStyle` trims the leading off
  the top of the first line and the bottom of the last, so on a Text that holds
  **one** line it changes nothing. The drawing's paragraph is one wrapping
  block and gets its 20.15 between the lines; ours is a `Row` of runs and then
  a `Text`, two separate one-line boxes, and a capture measured them 16.3
  apart. This is the 3.9 that trimming removed, so the break sits where the
  export puts it.

  A second `Text` run inside the first line — the highlight — is why the two
  cannot be one node: there is no inline span on this bridge.
  """
  def note_leading, do: ~MOB"<Box fill_width={true} height={4} />"

  @doc """
  Splits the quoted sentence where the drawing breaks it.

  The highlight has to share a line with the words either side of it, and a
  `Row` does not wrap — so the sentence is kept whole in the sample and cut
  here, at a declared word count, rather than stored pre-broken.
  """
  @spec note_lines(map()) :: {String.t(), String.t()}
  def note_lines(note) do
    {inline, rest} = note.tail |> String.split(" ") |> Enum.split(note.inline_words)
    {Enum.join(inline, " "), Enum.join(rest, " ")}
  end

  @doc """
  The *Recent* eyebrow and chip rows under the results, or nothing at all.

  Nothing on the idle page, because that page already draws this history:
  `waiting/1` puts screen 86's *Recent · last 8* card at the top, which is
  board 312's *it becomes 86*. With this shelf drawn underneath as well, a
  field opened empty — Activity's search disc, a cleared query — showed every
  recent query twice, the card above the note and the chips below it. The
  chips belong to the results page, where they are the way back to a query
  from the middle of another one.
  """
  @spec recent_shelf(map(), [String.t()], String.t() | nil) :: [map()]
  def recent_shelf(results, history, picked) do
    if Map.get(results, :idle?, false) or
         (history == [] and Map.get(results, :recent, []) == []) do
      []
    else
      [
        Kati.Screens.Search.section(gettext("Recent")),
        Kati.Screens.Search.recent(results, history, picked)
      ]
    end
  end

  @doc false
  def recent(results, history, picked) do
    # The drawing's shelf arrives on `results.recent` — it is what
    # `drawn_results/0` carries and what `Kati.ScreenDesignLiteralTest`
    # installs. A device's results carry none, so the shelf is this reader's
    # own history, chunked into the rows the drawing wraps it into.
    rows =
      case results.recent do
        [] -> Kati.Screens.Search.chunk(history)
        drawn -> drawn
      end

    ~MOB"""
    <Column fill_width={true}>
      {rows
       |> Enum.map(fn row -> Kati.Screens.Search.recent_row(row, picked) end)
       |> Enum.intersperse(Kati.Screens.Search.gap())}
    </Column>
    """
  end

  @doc false
  def recent_row(row, picked) do
    ~MOB"""
    <Row fill_width={true} align="center">
      {row
       |> Enum.map(fn label -> Kati.Screens.Search.recent_chip(label, label == picked) end)
       |> Enum.intersperse(Kati.Screens.Search.gap())}
    </Row>
    """
  end

  # Picking a recent search fills the chip the way the filter chips fill —
  # ink, paper text, the clock at .6 of it. It now rewrites the query and
  # re-runs it: the objection this comment used to carry — that the hits below
  # still describe "hollow" and a field saying "dentist" over them would be the
  # screen lying about its own results — is answered by moving both, which is
  # what `handle_info({:tap, "recent_" <> label})` does.
  @doc false
  def recent_chip(label, on?) do
    tap = {self(), String.to_atom("recent_" <> label)}
    background = if on?, do: Palette.ink_fill(), else: Palette.card_settled()
    color = if on?, do: Palette.on_ink(), else: Palette.ink_soft()
    icon = if on?, do: Palette.on_ink_count(), else: Palette.muted()

    ~MOB"""
    <Row
      height={30}
      corner_radius={15}
      background={background}
      padding_left={12}
      padding_right={12}
      align="center"
      on_tap={tap}
    >
      {Kati.UI.symbol("history", size: 14, color: icon)}
      <Spacer size={6} />
      <Text text={label} text_size={12} text_color={color} max_lines={1} />
    </Row>
    """
  end
end
