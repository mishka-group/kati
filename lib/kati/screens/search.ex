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

  ## Why this screen still reads `Kati.Screens.Search.Sample`

  Screen 03 moved onto `Kati.Media` (see `Kati.Screens.Library.shelf/0`), and
  more of this screen could follow it than of any other still on a sample —
  which is exactly why it has not. Its whole claim is **one query, four kinds
  of answer**, and it has no way to ask the question.

  The obvious blocker until this round was the one `Kati.Screens.Series` names
  — `Kati.Media` had no episode, so the drawing's second Screen hit
  (`Hollow Season · Episode · S2E5 · watched 12 Aug`) named a record nothing
  stored. `Kati.Media.Watch` came close and still comes up short on its own:
  `season_number` and `episode_number` are a label snapshot written at tick
  time, so `S2E5` survives a cache wipe, and `watched_on` is the date, but no
  row held the episode's **name**. That was never merely a blank in the row —
  a search cannot *match* `hollow` against a name stored nowhere, so the hit
  was unfindable rather than untitled, and `Kati.Screens.UpNext`'s `Untitled`
  degradation had nothing to degrade from. `Kati.Media.CachedEpisode` lands
  that name this round.

  It is worth being exact about what that does and does not settle. It makes
  the episode row **drawable**; it does not make it **findable**, and this is
  a search screen. What no resource expresses is the search itself:

    * **`hollow` in the field** — the query. Nothing stores one and no action
      takes one. There is no index and no read action anywhere that matches a
      title, an episode, an event or a review by substring; every existing
      read is an equality filter on an id, a kind or a status. The screen is
      drawn mid-query against a query nothing can run.
    * **the chip counts `6 / 3 / 2 / 1`** — counts of what the query matched
      across the whole result set, not of what each group has room to draw.
      `Kati.Screens.Search.Sample.chips/0` is explicit that deriving them from
      the drawn rows turns the drawing's 6 and 3 into 5 and 2. Without a
      matched set there is nothing to count.
    * **the recent shelf** — `dentist`, `leaving soon`, `ines karvel`,
      `4 stars`. Query history is stored nowhere.

  Every **field** each group draws does exist, and that is the shape of the
  gap: the columns are all there and nothing can select the rows.

    * **the Screen group** — `Series · S2 · watching` is
      `Kati.Media.CachedTitle.kind`, `Kati.Media.TrackedTitle.progress_season`
      and `status`; the episode row's name, runtime and air date are
      `Kati.Media.CachedEpisode`.
    * **the Calendar group** — `Kati.Calendars.Event.summary`, with
      `dtstart_utc` giving both `20 AUG` and `20:00`.
    * **the Notes group** — `Kati.Media.Watch.review` is the user's own note
      about a title, `watched_on` is the `6 AUG` in its eyebrow, and the cache
      row supplies `THE LONG HOLLOW`. Splitting the quoted line at the match is
      what `note_lines/1` already does.

  So this screen is not waiting on a column, the way screen 06 waits on a
  release year. It is waiting on the one thing it is named after, and building
  a half of it — Screen and Calendar answered for real, Notes and the recent
  shelf still drawn — would be worse than waiting: a page whose six hits are
  three real and three frozen reads as six real, which is the argument
  `Kati.Screens.Series` makes about its own half-real card. It moves whole,
  when there is an index to move it onto.
  """
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Components.MishkaChip
  alias Kati.Components.MishkaSeparator
  alias Kati.Theme.Palette
  alias Kati.UI

  # The label the drawing's back pill carries, and the answer for a push that
  # names no other. Board 19 draws `Home`, so a bare push still draws `Home`.
  @drawn_back "Home"

  # `recent` is nil because that is the state the drawing is in: no recent
  # search picked out of the shelf. `query` and `filter` were the drawing's too
  # and are now the push's, defaulting to exactly what they were — see
  # `opening_query/1` and `Kati.Search.narrowable/1`. A push that says nothing
  # is the gallery's and the sweeps', and it takes the same three values it
  # always took.
  def mount(params, _session, socket) do
    Mob.Theme.set(Kati.Theme.current())
    params = params || %{}
    query = Kati.Screens.Search.opening_query(params)
    results = Kati.Search.Query.run(query)

    {:ok,
     Mob.Socket.assign(socket,
       query: query,
       results: results,
       filter: Kati.Search.narrowable(Map.get(params, :scope, "All")),
       recent: nil,
       # Screen 06's counter, for the reason `handle_info({:tap, :clear}, …)`
       # gives. It starts at 1 when a push HANDED a query, so the field draws
       # it: the bridge remembers the last epoch per field, and a mount is not
       # itself a replacement, so a value handed to a field it has already
       # drawn is otherwise ignored.
       query_epoch: if(query == "", do: 0, else: 1),
       back: Map.get(params, :back, @drawn_back),
       history: Kati.Search.Recent.all()
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
      query: "hollow",
      idle?: false,
      titles: [
        %{title: "The Long Hollow", sub: "Series · S2 · watching", seed: "hollow71"},
        %{title: "Hollow Season", sub: "Episode · S2E5 · watched 12 Aug", seed: "hollow71"}
      ],
      calendar: [
        %{date: "20 AUG", title: "The Long Hollow S2E6 airs", time: "20:00"},
        %{date: "06 AUG", title: "Hollow Season — watched", time: "21:12"}
      ],
      # A list of one. The board draws one note because its query matched one,
      # not because the group holds one — the same thing its two Screen rows
      # say about `:titles`.
      notes: [
        %{
          eyebrow: "NOTE · 6 AUG · THE LONG HOLLOW",
          lead: "…the",
          match: "hollow",
          tail: "is a character, not a place. Watch E1 again before S3.",
          inline_words: 6
        }
      ],
      recent: Kati.Screens.Search.drawn_recent()
    }
  end

  @doc """
  The chip counts board 19 types: `6 / 3 / 2 / 1`.

  The drawing means them. It prints **Screen 3** over two drawn rows, the same
  way the shelf on screen 20 says *64 books* over six covers — a chip counts
  what the query matched, and the group under it shows the ones that fit above
  the fold. Deriving them from `drawn_results/0` turns the drawing's 6 and 3
  into 5 and 2, which is a literal on the screen not matching its frame.

  A device does derive them, from the matched set, which is what they already
  claim to be: `Kati.Search.Query.chip_counts/1`.
  """
  @spec drawn_chips() :: [{String.t(), non_neg_integer()}]
  def drawn_chips, do: [{"All", 6}, {"Screen", 3}, {"Calendar", 2}, {"Notes", 1}]

  @doc """
  The recent shelf board 19 draws, pre-chunked into the rows its `flex-wrap`
  produces.

  Three then one, which is what 402pt gives at these widths — and worth
  keeping, because it is what says the field remembers more than fits.
  `chunk/1` is what a device's own history goes through.
  """
  @spec drawn_recent() :: [[String.t()]]
  def drawn_recent, do: [["dentist", "leaving soon", "ines karvel"], ["4 stars"]]

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
    back = Map.get(assigns, :back, @drawn_back)

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
          {Kati.Screens.Search.section("Recent")}
          {Kati.Screens.Search.recent(results, history, recent)}
        </Column>
      </Scroll>
    </Box>
    """
  end

  def handle_info({:tap, :back}, socket), do: {:noreply, Kati.Screens.Resume.pop(socket)}

  @doc """
  Every keystroke, run.

  No debounce, and `Kati.Search.debounce_ms/0` is not being ignored: the 180ms
  it specifies is the interval between *counted* queries, which is a statement
  about a network-backed index. This one reads SQLite on the device and
  `Kati.Search.Query.run/1` narrows in Elixir, so the cost of a keystroke is a
  scan of a personal library — a debounce would buy latency rather than spend
  it. It goes in the day a query costs a request.

  The history is written here rather than on submit, because there is no
  submit. A field that only remembered what you pressed Enter on would
  remember almost nothing: the results arrive while you type, and you stop
  typing when you can see them.
  """
  def handle_info({:change, :query, typed}, socket) when is_binary(typed) do
    Kati.Search.Recent.remember(typed)

    {:noreply,
     socket
     |> Mob.Socket.assign(:query, typed)
     |> Mob.Socket.assign(:results, Kati.Search.Query.run(typed))
     |> Mob.Socket.assign(:history, Kati.Search.Recent.all())}
  end

  # Both ways out of a query that found nothing. The lookup carries what was
  # typed, so screen 06 opens already searching for it rather than asking
  # again — retyping a word the app has just shown you is what makes a dead
  # end feel like one.
  def handle_info({:tap, :look_up}, socket) do
    Kati.Search.hand_over(socket.assigns.query)
    {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.AddTitle)}
  end

  def handle_info({:tap, :add_by_hand}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.AddByHand.for_locale())}

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
     # MOVIES-AND-TV.md #94 called this control inert on the strength of
     # `Kati.ScreenTapSweepTest`'s own note — the sweep reaches 19 with an empty
     # field, where clearing is correctly a no-op. Pressed over a real query on
     # the device it was not inert; it was wrong.
     |> Mob.Socket.assign(:query_epoch, (socket.assigns[:query_epoch] || 0) + 1)
     |> Mob.Socket.assign(:results, Kati.Search.Query.run(""))
     # Board 312's *Recent, now carrying what you just cleared*. The store has
     # remembered it since the first keystroke; this is what puts it on the page
     # in the same breath as emptying the field.
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
      "filter_" <> label ->
        {:noreply, Mob.Socket.assign(socket, :filter, label)}

      "go_" <> label ->
        {:noreply, Mob.Socket.assign(socket, :filter, label)}

      # A Calendar hit, by its own event. Screen 31 answers an id that names
      # nothing with its own drawing rather than a crash, which is what makes
      # a row deleted on another device a page instead of a dead letter.
      "event_" <> id ->
        {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.EventDetail, %{id: id})}

      # A Screen hit, by its own title — `hit_tag/1`, resolved against the very
      # list the group was drawn from, which is `Kati.Screens.Library`'s rule
      # for the identical two prefixes.
      "open_film_" <> _title ->
        {:noreply, Kati.Screens.Search.open_hit(socket, tag, Kati.Screens.Film)}

      "open_series_" <> _title ->
        {:noreply, Kati.Screens.Search.open_hit(socket, tag, Kati.Screens.Series)}

      # An episode hit opens the SERIES it belongs to, because that is where an
      # episode lives — screen 04's list is the running order, and Kati has no
      # episode page. `open_hit/2` needs no change: it re-runs `hit_tag/1` over
      # `results.titles`, which is the list episodes now live in, and the row's
      # `:id` is already the tracked title's.
      "open_episode_" <> _source_id ->
        {:noreply, Kati.Screens.Search.open_hit(socket, tag, Kati.Screens.Series)}

      # The shelf is a shortcut INTO a query, which is what screen 86's own
      # recent rows are — `Kati.Screens.SearchIdle.open/2` opens this page on
      # the line that was tapped. Here the page is already open, so the query
      # is re-run in place.
      #
      # This used to fill the chip and stop, and the comment by `recent_chip/2`
      # said why: "until an index exists the screen cannot answer the new
      # question". `Kati.Search.Query.run/1` is that index, and
      # `handle_info({:change, :query, …})` above already re-runs it on every
      # keystroke — so the field and the hits move together, which is the exact
      # thing that reasoning was protecting.
      #
      # Remembered as well as run, for the reason typing is: the shelf is the
      # last eight queries you actually made, and one you reached for by name
      # is one of them.
      "recent_" <> label ->
        Kati.Search.Recent.remember(label)

        {:noreply,
         socket
         |> Mob.Socket.assign(:query, label)
         |> Mob.Socket.assign(:results, Kati.Search.Query.run(label))
         |> Mob.Socket.assign(:recent, label)
         |> Mob.Socket.assign(:history, Kati.Search.Recent.all())}

      _other ->
        {:noreply, socket}
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  @doc """
  Open `module` on the hit that carries `tag`.

  `Kati.Screens.Library.open_tile/3`'s rule again, over this screen's own
  group: the tag is resolved by re-running `hit_tag/1` over `results.titles`
  rather than by reversing the string, and a hit with no id pushes with **no
  params at all**. A cached title nobody keeps is a real hit — it matched —
  and there is no shelf row for it to open, so the destination draws its own
  branch rather than being handed a `nil` to take for an answer.
  """
  @spec open_hit(Mob.Socket.t(), atom(), module()) :: Mob.Socket.t()
  def open_hit(socket, tag, module) do
    row = Enum.find(socket.assigns.results.titles, &(Kati.Screens.Search.hit_tag(&1) == tag))

    case row && Map.get(row, :id) do
      # A hit with no tracked row is a title somebody looked up on the add
      # sheet and never shelved — `cached_for/2` reads the whole cache. Pushing
      # bare drew the FIXTURE branch of screen 04 or 08, so a chevron on
      # `Emergence` opened a page about The Long Hollow. MOVIES-AND-TV.md #65.
      #
      # It carries no tap at all now: `hit_tag/1` refuses a row with no id, so
      # the card is a card and not a door. Adding it from here would be a
      # second add flow on a screen whose subject is finding things — screen 06
      # is one tap away and is where a title is added.
      nil -> socket
      id -> Mob.Socket.push_screen(socket, module, %{id: id})
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
  def back(label \\ @drawn_back) do
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
          {Kati.UI.symbol("arrow_back_ios_new", size: 17)}
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
          clear: {self(), :clear},
          epoch: epoch
        }
      else
        %{query: query, id: nil, on_change: nil, clear: nil, epoch: epoch}
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
        Enum.map(Kati.Search.Query.chip_counts(results), fn {label, _zero} -> {label, nil} end)
      else
        Kati.Search.Query.chip_counts(results)
      end

    rail =
      counts
      |> Kati.Screens.Search.chip_rows()
      |> Enum.map(fn line ->
        Kati.Screens.Search.chip_line(
          line
          |> Enum.map(fn {label, count} ->
            Kati.Screens.Search.chip(label, count, label == active)
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
  """
  @spec chip_line([map()]) :: map()
  def chip_line(chips) do
    assigns = %{chips: chips}

    ~MOB"""
    <Row fill_width={true} align="center">
      <Scroll axis="horizontal">
        <Row align="center">
          {@chips}
        </Row>
      </Scroll>
      <Spacer size={7} />
      {Kati.UI.symbol("chevron_right", size: 17, color: Kati.Theme.Palette.tertiary())}
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
  def chip(label, count, on?) do
    # The tag carries the label, so one handler serves every chip.
    count_color = if on?, do: Palette.on_ink_count(), else: Palette.count_idle()

    MishkaChip.chip(
      label: label,
      checked: on?,
      on_toggle: {self(), String.to_atom("filter_" <> label)},
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
      text={to_string(count)}
      font_family="mono"
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
  @spec state_or_groups(map(), String.t(), [String.t()]) :: map()
  def state_or_groups(results, filter, history) do
    cond do
      Map.get(results, :idle?, false) ->
        Kati.Screens.Search.waiting(history)

      Kati.Screens.Search.visible_groups(results, filter) != [] ->
        Kati.Screens.Search.groups(results, filter)

      # MOVIES-AND-TV.md #117. *Nothing in this scope* and *nothing anywhere*
      # are two different things and this page drew the second sentence for
      # both — narrow to Calendar over a query that found three films and the
      # page said **Nothing here**, which is the exact misreading board 89's
      # third band was drawn to prevent. The page already knows where the
      # answer is; withholding it is the defect.
      elsewhere = Kati.Screens.Search.elsewhere(results, filter) ->
        Kati.Screens.Search.cross_scope(filter, elsewhere)

      true ->
        Kati.Screens.Search.no_matches(results.query)
    end
  end

  @doc """
  The scope holding the most hits, when the lit one holds none — or `nil`.

  `All` can never be the answer: it is every group at once, so a search with
  hits and an empty `All` is not a state. The largest rather than the first,
  because the offer is *where the answer is* and the answer is where most of
  it is; ties fall to `Kati.Search`'s own chip order, which is what
  `visible_groups/2` walks.

      iex> Kati.Screens.Search.elsewhere(%{titles: [1, 2], books: [], calendar: [], notes: []}, "Calendar")
      {"Screen", 2}

      iex> Kati.Screens.Search.elsewhere(%{titles: [], books: [], calendar: [], notes: []}, "Calendar")
      nil
  """
  @spec elsewhere(map(), String.t()) :: {String.t(), pos_integer()} | nil
  def elsewhere(results, filter) do
    results
    |> Kati.Screens.Search.visible_groups("All")
    |> Enum.reject(fn {label, _key} -> label == filter end)
    |> Enum.map(fn {label, key} -> {label, Kati.Screens.Search.count_of(results, key)} end)
    |> Enum.max_by(fn {_label, n} -> n end, fn -> nil end)
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
  @spec cross_scope(String.t(), {String.t(), pos_integer()}) :: map()
  def cross_scope(filter, {label, count}) do
    assigns = %{
      lead: "Nothing in #{filter}. ",
      over: "#{count} #{if count == 1, do: "match", else: "matches"} in #{label}",
      tap: {self(), String.to_atom("go_" <> label)}
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
  @spec visible_groups(map(), String.t()) :: [{String.t(), atom()}]
  def visible_groups(results, filter) do
    [{"Screen", :titles}, {"Books", :books}, {"Calendar", :calendar}, {"Notes", :notes}]
    |> Enum.filter(fn {label, _key} -> filter == "All" or filter == label end)
    |> Enum.reject(fn {_label, key} -> Kati.Screens.Search.blank?(results, key) end)
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

  What it says is the two sentences the idle boards already own —
  `Kati.Screens.SearchTyping.nothing_yet/0` is board 87's *Nothing searched
  yet* card and `Kati.Search.counts_note/0` is board 88's paragraph about why
  the chips carry no counts. Neither is invented here; a third wording of the
  same idea is how two screens end up disagreeing about what an empty search
  means.

  With a history, the card gives way to the shelf below it, which is the
  shortcut back into a query rather than an explanation of why there is none.
  """
  @spec waiting([String.t()]) :: map()
  def waiting(history) do
    # Board 312: **it becomes 86, not 87.** 87's idle page is the first open —
    # no recents, nothing searched. Clearing a field is a later moment, and
    # what belongs there is 86's Recent group, *"now populated by the query
    # just cleared."*
    #
    # `Kati.Screens.SearchIdle.recent/1` already handles both halves and states
    # its own reason for the empty one: the eyebrow stays and the card under it
    # explains itself, so the shape of the screen does not change under the
    # reader on a first run.
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
  What a query that matched nothing says — board 89's own card, wired.

  Not a card of this screen's own. `Kati.Screens.SearchResultStates.nothing/2`
  is the drawing of exactly this state, down to naming the query back inside
  its quotation marks, and 89's caption carries the reasoning: `Kati.Search`'s
  scopes are all things you keep, so an empty result is not a failure to find
  — it is a correct report that you do not have it, and the sentence says so
  before offering the lookup.

  What 89 could not have is the two destinations, and both exist now. The add
  pill goes outward to `Kati.Screens.AddTitle`, which searches TMDB for real
  since `Kati.Media.Tmdb` landed; the line under it goes to
  `Kati.Screens.AddByHand`, board 154, which is the path that works without a
  catalogue at all. In that order, because a title Kati has never heard of is
  likelier to be findable than to be worth typing out.
  """
  @spec no_matches(String.t()) :: map()
  def no_matches(query) do
    Kati.Screens.SearchResultStates.nothing(query,
      lookup: {self(), :look_up},
      by_hand: {self(), :add_by_hand}
    )
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
  @spec groups(map(), String.t()) :: term()
  def groups(results, filter) do
    visible = results |> Kati.Screens.Search.visible_groups(filter) |> Enum.with_index()

    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(visible, fn {{label, key}, i} ->
        Kati.Screens.Search.group(results, label, key, i == 0)
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
          text={String.upcase(label)}
          font_family="mono"
          text_size={10.5}
          letter_spacing={0.16}
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
  says films. MOVIES-AND-TV.md #61.
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
    # MOVIES-AND-TV.md #65.
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
        {Kati.UI.symbol("chevron_right", size: 18, color: Palette.rail_idle())}
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
            font_family="mono"
            text_size={10}
            letter_spacing={0.06}
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
          font_family="mono"
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
  # nowhere on this page to be. MOVIES-AND-TV.md #139.
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
          font_family="mono"
          text_size={10}
          letter_spacing={0.14}
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
