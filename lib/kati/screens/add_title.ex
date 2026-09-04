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
  import Mob.Sigil

  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaChip
  alias Kati.Library.Sample
  alias Kati.Theme
  alias Kati.Theme.Palette
  alias Kati.UI

  # `results` is the whole answer to the query and never shrinks — the chip
  # narrows the VIEW, so a title added under `Films` is still added when the
  # user goes back to `Everything`.
  def mount(_params, _session, socket) do
    Mob.Theme.set(Kati.Theme.current())

    {:ok,
     Mob.Socket.assign(socket,
       results: Sample.search_results(),
       filter: "Everything",
       query: "",
       save_error: nil,
       search_error: nil
     )}
  end

  def render(assigns) do
    filter = assigns.filter
    shown = visible(assigns.results, filter)
    count = "#{length(shown)} results"

    ~MOB"""
    <Box
      fill_width={true}
      fill_height={true}
      background={:background}
      layout_direction={Kati.Locale.direction_prop()}
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
          {Kati.Screens.AddTitle.field(assigns.query)}
          {Kati.Screens.AddTitle.chips(filter)}
          {UI.eyebrow(count)}
          {Kati.Screens.AddTitle.results(shown)}
          {Kati.Screens.AddTitle.by_hand()}
        </Column>
      </Scroll>
    </Box>
    """
  end

  def handle_info({:tap, :back}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}

  # The escape hatch, finally wired. This row has been drawn on artboard 89
  # since the screen was written and rendered with no `on_tap` at all, because
  # no board drew what it would open — the moduledoc has carried that apology
  # for as long. Board 154 is that form, and #91's "a clean install hands over
  # a usable app" is what it answers: until the catalogue lands, every title
  # this screen can find is invented, and this is the only way to put a real
  # one in the library.
  def handle_info({:tap, :add_by_hand}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.AddByHand)}

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
  @min_query 3

  def handle_info({:change, :title_query, typed}, socket) when is_binary(typed) do
    socket = Mob.Socket.assign(socket, :query, typed)
    query = String.trim(typed)

    if String.length(query) < @min_query do
      # Back to the drawing, not to nothing. Board 06 is drawn mid-query and no
      # board draws this screen before anyone has typed — the rule
      # `Kati.Screens.Library` moved off its Sample under is that the design
      # must draw the emptiness first, and here it does not. `D-31` is the
      # brief that would settle it.
      {:noreply,
       socket
       |> Mob.Socket.assign(:results, Sample.search_results())
       |> Mob.Socket.assign(:search_error, nil)}
    else
      {:noreply, Kati.Screens.AddTitle.searched(socket, query)}
    end
  end

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

  `seed` stays nil. A seed is `Kati.Library.Sample`'s key for a drawing's
  photograph, and a TMDB `poster_path` is a URL on someone else's CDN —
  `thumb/1` already draws the paper placeholder for a row it has no picture
  for, which is the honest answer until posters are fetched.

  `source_id` and `kind` ride along because `track/2` needs them: a row added
  from TMDB is tracked under its TMDB id, not under its title.
  """
  @spec row(map()) :: map()
  def row(result) do
    %{
      title: result.title,
      seed: nil,
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
    kind = if result.kind == :movie, do: "FILM", else: "SERIES"

    case result.year do
      nil -> kind
      year -> year <> " · " <> kind
    end
  end

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

  def handle_info(_msg, socket), do: {:noreply, socket}

  @doc """
  The results a chip leaves visible.

  Read off the result's own `meta` — `2019 · FILM · 1h 48m` — rather than a
  second `:kind` field, so the row and the chip are answering one question
  from one source. The design's note says the type is inferred from what you
  searched, and this is that inference in the one place it exists.
  """
  @spec visible([map()], String.t()) :: [map()]
  def visible(results, "Films"), do: Enum.filter(results, &String.contains?(&1.meta, "FILM"))
  def visible(results, "Series"), do: Enum.filter(results, &String.contains?(&1.meta, "SERIES"))
  def visible(results, _filter), do: results

  @doc false
  def header do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Text
          text="Add a title"
          text_size={26}
          font_weight="bold"
          letter_spacing={-0.03}
          text_color={:on_surface}
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
  def field(query) do
    assigns = %{query: query, on_change: {self(), :title_query}}

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
          placeholder="quiet"
          return_key="search"
          weight={1.0}
          accessibility_id="title_query"
          on_change={@on_change}
        />
        {Kati.UI.symbol("cancel", size: 19, color: Palette.rail_idle(), fill: true)}
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
  def add(socket, title) do
    row = Enum.find(socket.assigns.results, &(&1.title == title))
    tracked? = row && row.added

    result =
      if tracked? do
        Kati.Screens.AddTitle.untrack(title)
      else
        Kati.Screens.AddTitle.track(title, row)
      end

    case result do
      {:ok, _record} ->
        socket
        |> Mob.Socket.assign(:results, Kati.Screens.AddTitle.mark(socket.assigns.results, title))
        |> Mob.Socket.assign(:save_error, nil)

      {:error, _reason} = error ->
        Mob.Socket.assign(socket, :save_error, Kati.Write.message(error))
    end
  end

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
    with {:ok, _filled} <- Kati.Media.Tmdb.fetch(source_id, tmdb_kind(kind)),
         {:ok, tracked} <-
           Ash.create(Kati.Media.TrackedTitle, %{
             source: :tmdb,
             source_id: source_id,
             kind: kind,
             status: :watching
           }) do
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
      {:ok, tracked}
    end
    |> Kati.Write.note("track #{title}")
  end

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
  def cache(title, kind) do
    existing =
      case Ash.read(Kati.Media.CachedTitle) do
        {:ok, rows} -> Enum.find(rows, &(&1.source == :manual and &1.source_id == title))
        _error -> nil
      end

    if existing, do: {:ok, existing}, else: Kati.Screens.AddTitle.create_cache(title, kind)
  end

  @doc false
  def create_cache(title, kind) do
    Ash.create(Kati.Media.CachedTitle, %{
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
    })
  end

  @doc false
  @spec untrack(String.t()) :: {:ok, term()} | {:error, term()}
  def untrack(title) do
    case Ash.read(Kati.Media.TrackedTitle) do
      {:ok, rows} ->
        rows
        |> Enum.find(&(&1.source == :manual and &1.source_id == title))
        |> case do
          nil -> {:ok, :already_gone}
          row -> Ash.destroy(row) |> then(fn r -> if r == :ok, do: {:ok, :removed}, else: r end)
        end

      error ->
        error
    end
    |> Kati.Write.note("untrack #{title}")
  end

  @doc """
  What a result row is, read off the `meta` line the drawing writes.

  `"2019 · FILM · 1h 48m"` is a film; `"2023 · SERIES · 2 SEASONS"` is tv.
  Parsed rather than stored because the sample rows carry no kind of their own,
  and a title typed by hand carries none either — a guess that reads the words
  already on screen is better than a default nobody chose.
  """
  @spec kind_of(map() | nil) :: :movie | :tv
  def kind_of(%{meta: meta}) when is_binary(meta) do
    if String.contains?(String.upcase(meta), "SERIES"), do: :tv, else: :movie
  end

  def kind_of(_row), do: :movie

  @doc false
  def mark(results, title) do
    Enum.map(results, fn r ->
      if r.title == title, do: %{r | added: not r.added}, else: r
    end)
  end

  @doc false
  def chips(active) do
    children =
      ["Everything", "Films", "Series"]
      |> Enum.map(fn label -> Kati.Screens.AddTitle.chip(label, label == active) end)
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
  def chip(label, on?) do
    # The tag carries the label, so the day the sheet grows a Books chip is a
    # change to one list and `visible/2`, not to the handler.
    MishkaChip.chip(
      label: label,
      checked: on?,
      on_toggle: String.to_atom("filter_" <> label),
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
            letter_spacing={-0.015}
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={5} />
          <Text
            text={r.meta}
            font_family="mono"
            text_size={10.5}
            text_color={Palette.muted()}
            max_lines={1}
          />
          <Spacer size={5} />
          <Text text={r.note} text_size={11.5} text_color={Palette.sub()} max_lines={1} />
        </Column>
        <Spacer size={13} />
        {Kati.Screens.AddTitle.add_button(r.added, r.title)}
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
  def add_button(added?, title) do
    # Keyed on the title, not the row's position: the chips reorder nothing but
    # they do renumber, and `add_1` would mean a different film under `Films`.
    tap = {self(), String.to_atom("add_" <> title)}
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
  @doc false
  def by_hand do
    ~MOB"""
    <Row
      fill_width={true}
      corner_radius={18}
      border_width={1.5}
      border_color={Palette.border()}
      padding_top={14}
      padding_bottom={14}
      align="center"
      on_tap={{self(), :add_by_hand}}
    >
      <Spacer weight={1.0} />
      {Kati.UI.symbol("edit_note", size: 18, color: Palette.sub())}
      <Spacer size={7} />
      <Text
        text="Can’t find it? Add it by hand"
        text_size={13}
        font_weight="semibold"
        text_color={Palette.ink_soft()}
        max_lines={1}
      />
      <Spacer weight={1.0} />
    </Row>
    """
  end
end
