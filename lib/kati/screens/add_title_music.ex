defmodule Kati.Screens.AddTitleMusic do
  @moduledoc """
  Screen 179 — Add a title, the music state. Screen 06's sheet with **Albums**
  lit, which is what screen 21's `+` opens.

  Built to `test/design/screens/179.html`. Board 06's own caption promised this:
  *later the same sheet adds a book, an album or an event — the type is inferred
  from what you searched*. `D-39` settles where the promise lands — not on a new
  control on the Music shelf, which would be a second door to a sheet that
  already has one, but on a **state** of the sheet that door already opens.

  `Kati.Screens.AddTitle.for_shelf/1` is the fork, and it is one function
  because `Kati.Screens.Root`'s FAB handler is written once for every root:
  *the FAB opens the add sheet from every root, so it belongs here rather than
  in four copies*. Adding an `if` to that clause would have been a fifth copy in
  disguise.

  ## The one row-shape difference from 06

  An album is a **square**. Screen 06's result rows carry a 44×62 poster; these
  carry a 52×52 paper square with the record's initial, which is
  `Kati.Screens.AlbumDetail`'s rule stated at result-row size: *the square is the
  default rendering and not a fallback, and `Kati.Music.Album.initial/1` fills
  it.* Everything else — the close disc, the focused field, the chip row, the DM
  Mono result eyebrow, the bordered *Add it by hand* row — is board 06 entire.

  ## What typing does, and the sentence that is the whole reason

  Screen 06 runs `Kati.Media.Tmdb.search/1` past a three-character floor. There
  is no music equivalent: Kati has no MusicBrainz client, no music catalogue and
  no read action anywhere that matches an album by name. So the board draws the
  answer in its own empty card — *Kati has no music catalogue to look in. Type
  it and it is yours* — and this screen tells that truth rather than performing
  a query.

  Below the floor the sheet draws the board's own rows, which is exactly what
  screen 06 does below its floor and for the reason written there. At or above
  it the answer is honestly nothing, and the card that says so carries the one
  thing that fixes it: screen 178.

  ## Why the added disc is a state and not a control

  Board 179 draws two ink `add` discs and one muted `check`, as 06 does. On 06
  the check is a control — tapping it untracks — because removing a title
  deletes what you DECIDED and leaves the cached row alone. There is no such
  split here: an album IS the row, its tracks and its listens hang off it by
  foreign key, and a muted disc that silently destroyed all three would be the
  most destructive control in the app drawn as the quietest.

  So the check carries no `on_tap`, which `Kati.ScreenSweep.tap_tags/1` documents
  as the one value a control can hold that means *not tappable* rather than
  *broken*. Removing a record is the shelf's business, not this sheet's.
  """
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaChip
  alias Kati.Screens.AddByHandRecord
  alias Kati.Theme
  alias Kati.Theme.Palette
  alias Kati.UI

  # Five chips is the most any chip row in Kati carries, and the board says
  # which two are pinned when it scrolls: `Everything` and the lit one.
  @scopes ["Everything", "Films", "Series", "Albums", "Artists"]

  # The scope this sheet opens in, because this is the sheet screen 21's FAB
  # opens and screen 21 is the Music shelf.
  @scope "Albums"

  # Screen 06's floor, and the same number for the same reason: below it a
  # person is still typing.
  @min_query 3

  def mount(_params, _session, socket) do
    Kati.Theme.activate()

    {:ok,
     Mob.Socket.assign(socket,
       results: Kati.Screens.AddTitleMusic.drawn_results(),
       filter: @scope,
       query: "",
       save_error: nil
     )}
  end

  @doc """
  The board's three rows.

  A transcription rather than a read, and the board's own caption is the
  argument: these are records the reader does **not** have, and the one set of
  rows Kati can answer for is the shelf — which is the set this sheet exists to
  look outside of. `Kati.Screens.AddTitle`'s moduledoc makes the same case at
  length for films.

  `added` is the third row's, drawn as 06 draws it: one result already on the
  shelf, so the two states of the trailing disc are both on the board.
  """
  @spec drawn_results() :: [map()]
  def drawn_results do
    [
      %{
        title: "Tidal Works",
        artist: "Kell Ostrand",
        note: "Kell Ostrand · Post-classical",
        meta: "2025 · ALBUM · 11 TRACKS",
        year: "2025",
        tracks: "11",
        added: false
      },
      %{
        title: "Estuary Tapes",
        artist: "Kell Ostrand",
        note: "Kell Ostrand · Post-classical",
        meta: "2026 · ALBUM · 8 TRACKS",
        year: "2026",
        tracks: "8",
        added: false
      },
      %{
        title: "Nine Rooms",
        artist: "Kell Ostrand",
        note: "Kell Ostrand",
        meta: "2021 · ALBUM · 9 TRACKS",
        year: "2021",
        tracks: "9",
        added: true
      }
    ]
  end

  @doc "The query the board is drawn mid-typing, and what the specimen card names."
  @spec drawn_query() :: String.t()
  def drawn_query, do: "ostrand"

  @doc false
  @spec scope_list() :: [String.t()]
  def scope_list, do: @scopes

  def render(assigns) do
    shown = Kati.Screens.AddTitleMusic.visible(assigns.results, assigns.filter)
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
          {Kati.Screens.AddTitleMusic.header()}
          {Kati.Screens.AddTitleMusic.field(assigns.query)}
          {Kati.Screens.AddTitleMusic.chips(assigns.filter)}
          {UI.eyebrow(count)}
          {Kati.Screens.AddTitleMusic.results(shown)}
          {Kati.Screens.AddTitleMusic.error(assigns.save_error)}
          {Kati.Screens.AddTitleMusic.by_hand()}
          {Kati.Screens.AddTitleMusic.nothing_band(shown, assigns.query)}
          {Kati.Screens.AddTitleMusic.note()}
        </Column>
      </Scroll>
    </Box>
    """
  end

  @doc """
  The rows a chip leaves visible.

  `Albums` and `Artists` narrow this sheet; the other three are screen 06's
  scopes and their chips open it — see `handle_info/2`. Nothing here is
  filtered by the artist scope yet, and the empty card says why in the board's
  own words rather than drawing an empty list under a count of nothing.
  """
  @spec visible([map()], String.t()) :: [map()]
  def visible(_results, "Artists"), do: []
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
        {Kati.Screens.AddTitleMusic.close_disc()}
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

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

  @doc "Board 06's focused field: a 2px ink ring, an orange caret, and a clear glyph."
  @spec field(String.t()) :: map()
  def field(query) do
    assigns = %{query: query, on_change: {self(), :album_query}}

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
          placeholder="ostrand"
          return_key="search"
          weight={1.0}
          accessibility_id="album_query"
          on_change={@on_change}
        />
        {Kati.UI.symbol("cancel", size: 19, color: Palette.rail_idle(), fill: true)}
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc false
  def chips(active) do
    children =
      Kati.Screens.AddTitleMusic.scope_list()
      |> Enum.map(fn label -> Kati.Screens.AddTitleMusic.chip(label, label == active) end)
      |> Enum.intersperse(Kati.Screens.AddTitleMusic.chip_gap())

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true}>
        {children}
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def chip(label, on?) do
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

  @doc false
  def chip_gap, do: ~MOB"<Spacer size={7} />"

  @doc false
  def results(rows) do
    ~MOB"""
    <Column fill_width={true}>
      {rows
       |> Enum.map(fn r -> Kati.Screens.AddTitleMusic.result_row(r) end)
       |> Enum.intersperse(Kati.Screens.AddTitleMusic.row_gap())}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def row_gap, do: ~MOB"<Spacer size={9} />"

  @doc false
  def result_row(r) do
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
      {Kati.Screens.AddTitleMusic.art(r.title)}
      <Spacer size={12} />
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
      <Spacer size={12} />
      {Kati.Screens.AddTitleMusic.add_button(r.added, r.title)}
    </Row>
    """
  end

  @doc """
  The square, carrying the record's initial.

  `Kati.Music.Album.initial/1` is the same function screen 74's art square uses,
  called on a struct that exists only to be asked — the row here is a
  transcription and has no album behind it, and duplicating the `?`-for-an-
  uncased-first-letter rule would be a second answer to a question that has one.
  """
  @spec art(String.t()) :: map()
  def art(title) do
    assigns = %{initial: Kati.Music.Album.initial(%Kati.Music.Album{title: title})}

    ~MOB"""
    <Box width={52} height={52} corner_radius={11} background={Palette.placeholder()} align="center">
      <Text
        text={@initial}
        font_family="mono"
        text_size={20}
        text_color={Palette.tertiary()}
        max_lines={1}
      />
    </Box>
    """
  end

  @doc """
  The trailing disc: ink `add` for a record not on the shelf, muted `check` for
  one already there.

  The muted one carries no tap — see the moduledoc.
  """
  @spec add_button(boolean(), String.t()) :: map()
  def add_button(true, _title) do
    MishkaActionIcon.action_icon(
      [size: 34, shape: :circle, variant: :filled, background: Palette.paper()],
      [UI.symbol("check", size: 19, color: Palette.sub())]
    )
  end

  def add_button(false, title) do
    MishkaActionIcon.action_icon(
      [
        size: 34,
        shape: :circle,
        variant: :filled,
        background: Palette.ink_fill(),
        on_tap: String.to_atom("add_" <> title)
      ],
      [UI.symbol("add", size: 19, color: Palette.on_ink())]
    )
  end

  @doc false
  def error(nil), do: ~MOB"<Spacer size={0} />"

  def error(message) do
    assigns = %{message: message}

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.note("error", @message)}
      <Spacer size={16} />
    </Column>
    """
  end

  @doc "Board 06's bordered row, which now has a destination."
  @spec by_hand() :: map()
  def by_hand do
    ~MOB"""
    <Column fill_width={true}>
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
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  *Nothing found* — as the state the sheet is in, or as the state it is not.

  One card, two ways of arriving at it. A search that matches no record draws it
  live, under the query that was typed. A sheet with rows on it draws it under
  the board's own eyebrow and the board's own query, because 179 draws both
  states at once and this is the second of them — the same arrangement screen
  178's *Artist chosen* inset uses, and for the same reason: the specimen is the
  state you are not in, and it disappears the moment you are in it.
  """
  @spec nothing_band([map()], String.t()) :: map()
  def nothing_band([], query) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.AddTitleMusic.nothing_card(Kati.Screens.AddTitleMusic.named(query))}
      <Spacer size={14} />
    </Column>
    """
  end

  def nothing_band(_rows, _query) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.Eyebrow.quiet("Nothing found")}
      {Kati.Screens.AddTitleMusic.nothing_card(Kati.Screens.AddTitleMusic.drawn_query())}
      <Spacer size={14} />
    </Column>
    """
  end

  @doc "The query a card names: what was typed, or the board's own when nothing was."
  @spec named(String.t()) :: String.t()
  def named(query) do
    case String.trim(query) do
      "" -> Kati.Screens.AddTitleMusic.drawn_query()
      typed -> typed
    end
  end

  @doc false
  def nothing_card(query) do
    assigns = %{headline: "Nothing here for “" <> query <> "”"}

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={22}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={17}
      align="center"
    >
      <Box width={48} height={48} corner_radius={15} background={Palette.paper()} align="center">
        {Kati.UI.symbol("search", size: 22, color: Palette.rail_idle())}
      </Box>
      <Spacer size={13} />
      <Text text={@headline} text_size={14} font_weight="bold" text_color={:on_surface} />
      <Spacer size={7} />
      <Text
        text="Kati has no music catalogue to look in. Type it and it is yours."
        text_size={12.5}
        line_height={1.55}
        text_align="center"
        text_color={Palette.sub()}
      />
      <Spacer size={15} />
      <Row
        fill_width={true}
        height={44}
        corner_radius={22}
        background={Palette.ink_fill()}
        align="center"
        on_tap={{self(), :add_by_hand_empty}}
      >
        <Spacer weight={1.0} />
        <Text
          text="Add it by hand"
          text_size={13}
          font_weight="bold"
          text_color={Palette.on_ink()}
          max_lines={1}
        />
        <Spacer weight={1.0} />
      </Row>
    </Column>
    """
  end

  @doc "The board's dashed annotation, in the runs it is drawn in."
  @spec note() :: map()
  def note do
    ~MOB"""
    <Row
      fill_width={true}
      corner_radius={18}
      border_width={1.5}
      border_color={Palette.border()}
      padding={15}
      align="top"
    >
      {Kati.UI.symbol("info", size: 17, color: Palette.sub())}
      <Spacer size={11} />
      <Column weight={1.0}>
        <Text
          text="The one row-shape difference from 06: an album is a"
          text_size={12.5}
          line_height={1.65}
          text_color={Palette.ink_soft()}
        />
        <Text
          text="square"
          text_size={12.5}
          line_height={1.65}
          font_weight="semibold"
          text_color={Palette.ink()}
        />
        <Text
          text=", and the paper placeholder carries its initial rather than a 2:3 poster. Five chips is the most any chip row in Kati carries;"
          text_size={12.5}
          line_height={1.65}
          text_color={Palette.ink_soft()}
        />
        <Text
          text="Everything"
          text_size={12.5}
          line_height={1.65}
          font_weight="semibold"
          text_color={Palette.ink()}
        />
        <Text
          text="and the lit chip are pinned when it scrolls. This is the state"
          text_size={12.5}
          line_height={1.65}
          text_color={Palette.ink_soft()}
        />
        <Text
          text="21’s FAB opens"
          text_size={12.5}
          line_height={1.65}
          font_weight="semibold"
          text_color={Palette.ink()}
        />
        <Text
          text="— not a second add control on the shelf, which would be a second door to a sheet that already has one."
          text_size={12.5}
          line_height={1.65}
          text_color={Palette.ink_soft()}
        />
      </Column>
    </Row>
    """
  end

  def handle_info({:tap, :back}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}

  # Both doors into screen 178, and they are two tags rather than one because
  # `Mob.Renderer` derives an `accessibility_id` from every atom tag — a tag
  # drawn twice is an id drawn twice, and `onNodeWithTag` throws on the second
  # match rather than picking one.
  def handle_info({:tap, tag}, socket) when tag in [:add_by_hand, :add_by_hand_empty],
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.AddByHandRecord)}

  @doc """
  What was typed, and what this sheet can honestly answer with.

  Not debounced, for the reason `Kati.Screens.AddTitle`'s own change handler
  gives: `Kati.SupervisionRuleTest` forbids a screen setting a timer, because a
  screen is transient and a timer outlives the screen that set it.

  There is no request to debounce here in any case — see the moduledoc. Past the
  floor the answer is `[]`, which is the state the board's own empty card is
  drawn for.
  """
  def handle_info({:change, :album_query, typed}, socket) when is_binary(typed) do
    socket = Mob.Socket.assign(socket, :query, typed)

    if String.length(String.trim(typed)) < @min_query do
      {:noreply, Mob.Socket.assign(socket, :results, Kati.Screens.AddTitleMusic.drawn_results())}
    else
      {:noreply, Mob.Socket.assign(socket, :results, [])}
    end
  end

  def handle_info({:tap, tag}, socket) do
    case Atom.to_string(tag) do
      # Albums and Artists are scopes of THIS sheet. Everything, Films and
      # Series are screen 06's, and its chips are where they narrow — a music
      # sheet drawing an empty film list would be answering a question it has
      # no rows for.
      "filter_" <> label when label in ["Albums", "Artists"] ->
        {:noreply, Mob.Socket.assign(socket, :filter, label)}

      "filter_" <> _label ->
        {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.AddTitle)}

      "add_" <> title ->
        {:noreply, Kati.Screens.AddTitleMusic.add(socket, title)}

      _other ->
        {:noreply, socket}
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  @doc """
  Shelve the record this row is about.

  **The row is found in the list the page drew**, not re-derived from the tag's
  string, and everything written comes off that row — which is the branch rule 2
  takes here: a tap on the third result must not be able to file the first.
  `Kati.Screens.Music.open_album/2` resolves a tile the same way and its own
  comment gives the reason.

  The write is `Kati.Screens.AddByHandRecord.write/3`, not a second one. Two
  writers for one shape is how the sheet and the form come to disagree about
  what a hand-added album is — the artist reuse, the `:manual` source, the
  tracks — and `Kati.Screens.LogListen.params_for/1` is the same rule one screen
  over: spell it once, on the module that owns it.
  """
  @spec add(Mob.Socket.t(), String.t()) :: Mob.Socket.t()
  def add(socket, title) do
    case Enum.find(socket.assigns.results, &(&1.title == title and not &1.added)) do
      nil ->
        socket

      row ->
        case Kati.Screens.AddTitleMusic.shelve(row) do
          {:ok, _album} ->
            socket
            |> Mob.Socket.assign(
              :results,
              Kati.Screens.AddTitleMusic.mark(socket.assigns.results, title)
            )
            |> Mob.Socket.assign(:save_error, nil)

          error ->
            Mob.Socket.assign(socket, :save_error, Kati.Write.message(error))
        end
    end
  end

  @doc false
  @spec shelve(map()) :: {:ok, struct()} | {:error, term()}
  def shelve(row) do
    AddByHandRecord.write(:album, row.title, %{
      artist: row.artist,
      released: row.year,
      tracks: row.tracks,
      first_heard: ""
    })
  end

  @doc false
  @spec mark([map()], String.t()) :: [map()]
  def mark(results, title) do
    Enum.map(results, fn r -> if r.title == title, do: %{r | added: true}, else: r end)
  end
end
