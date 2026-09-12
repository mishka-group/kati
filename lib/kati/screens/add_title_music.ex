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
  use Gettext, backend: Kati.Gettext
  import Mob.Sigil

  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaChip
  alias Kati.Lists.Shelf
  alias Kati.Screens.AddByHandRecord
  alias Kati.Theme
  alias Kati.Theme.Palette
  alias Kati.UI

  # Five chips is the most any chip row in Kati carries, and the board says
  # which two are pinned when it scrolls: `Everything` and the lit one.
  #
  # These five are KEYS and not words. `visible/2` narrows on them, the socket
  # holds one, `chip/2` builds `filter_Albums` out of one and
  # `Kati.ScreenTapSweepTest` names that tag — so they stay English in every
  # locale and `scope_label/1` is the only part the reader sees. Screen 06's
  # `filters/0` carries the long version of the argument, and
  # `Kati.Screens.Books.chip_counts/1` records what happens without it: the
  # Persian filter was «همه», every clause of that screen's `visible/2` fell
  # through, and the chips drew correctly while tapping any of them showed
  # everything.
  @scopes ["Everything", "Films", "Series", "Albums", "Artists"]

  # The scope this sheet opens in, because this is the sheet screen 21's FAB
  # opens and screen 21 is the Music shelf.
  @scope "Albums"

  # Screen 06's floor, and the same number for the same reason: below it a
  # person is still typing.
  @min_query 3

  def mount(_params, _session, socket) do
    Kati.Theme.activate()
    Kati.Locale.activate()

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

  ## `key` is what names a row, and `title` is what it says

  They were one string. Translating the title alone would have translated the
  tap tag with it — `add_Tidal Works` becomes `:"add_کارهای جزر و مد"`, and
  `add/2` then looks a row up in a list it stopped matching the moment the
  words moved. That is the chip defect `Kati.Screens.AddTitle.filter_label/1`
  documents, one control over and with the same shape.

  So `key` is the English title, which is the name
  `Kati.MusicAddByHandTest` taps these rows by, and `title` is the word the
  reader sees. The words are not new: `Kati.Music.Sample` already names all
  three of these records and their musician, so screen 21's shelf and this
  sheet call one album one thing.

  `year` and `tracks` are DATA and keep their Latin digits. Nothing renders
  them — `meta_line/2` draws their Persian — and they travel into
  `Kati.Screens.AddByHandRecord.write/3`, which parses both.
  """
  @spec drawn_results() :: [map()]
  def drawn_results do
    # Bound once rather than written three times: these are the same musician
    # and the same genre on every row the board draws, and a msgid repeated at
    # three call sites is three places to mistype it.
    ostrand = gettext("Kell Ostrand")
    genre = gettext("Post-classical")

    [
      %{
        key: "Tidal Works",
        title: gettext("Tidal Works"),
        artist: ostrand,
        note: Kati.Screens.AddTitleMusic.note_line(ostrand, genre),
        meta: Kati.Screens.AddTitleMusic.meta_line(2025, 11),
        year: "2025",
        tracks: "11",
        added: false
      },
      %{
        key: "Estuary Tapes",
        title: gettext("Estuary Tapes"),
        artist: ostrand,
        note: Kati.Screens.AddTitleMusic.note_line(ostrand, genre),
        meta: Kati.Screens.AddTitleMusic.meta_line(2026, 8),
        year: "2026",
        tracks: "8",
        added: false
      },
      %{
        key: "Nine Rooms",
        title: gettext("Nine Rooms"),
        artist: ostrand,
        note: Kati.Screens.AddTitleMusic.note_line(ostrand, nil),
        meta: Kati.Screens.AddTitleMusic.meta_line(2021, 9),
        year: "2021",
        tracks: "9",
        added: true
      }
    ]
  end

  @doc """
  A result's mono line: the year, the kind, and the size of the running order.

  Composed rather than held in a msgid of its own, which is
  `Kati.Screens.AddTitle.meta_line/1`'s choice on the sheet beside this one and
  made for its reason: `·` is a bidi NEUTRAL between a number and a word, so it
  takes the paragraph's direction and `۲۰۲۵ · آلبوم · ۱۱ آهنگ` lays itself out
  right-to-left in the order it was written. There is nothing here for a
  translator to reorder, and a msgid that is three interpolations and two
  separators is exactly what `mix gettext.merge` fuzzy-matches against every
  other `·` line in the catalogue.

  None of the three is a new word. `ALBUM` is `Kati.Lists.Shelf.kind_word/1` —
  the tag the shelf prints under this record once it is on it — and the count is
  `Kati.Screens.AlbumDetail`'s own `%{n} track`, so a record reads *۱۱ آهنگ*
  here and *۱۱ آهنگ* on its own page.

  `Kati.Locale.year/1` and not `number/1`: a release year is a fact printed on
  the record, so its digits change and its calendar does not.
  `Kati.UI.eyebrow_label/1` carries the upper case, because upper case is a
  LATIN effect — `String.upcase/1` on `آهنگ` is a no-op that reads as one.

      iex> Kati.Locale.as(:en, fn -> Kati.Screens.AddTitleMusic.meta_line(2025, 11) end)
      "2025 · ALBUM · 11 TRACKS"
  """
  @spec meta_line(integer(), integer()) :: String.t()
  def meta_line(year, tracks) do
    counted = ngettext("%{n} track", "%{n} tracks", tracks, n: Kati.Locale.number(tracks))

    Kati.Locale.year(year) <>
      " · " <> Shelf.kind_word(:album) <> " · " <> UI.eyebrow_label(counted)
  end

  @doc """
  A result's third line: who made the record, and what it is.

  Joined rather than given a `%{artist} · %{genre}` entry, for `meta_line/2`'s
  reason — and because the third row has no genre at all, which one msgid would
  have made a translator's problem instead of a clause's.

      iex> Kati.Locale.as(:en, fn -> Kati.Screens.AddTitleMusic.note_line("Kell Ostrand", nil) end)
      "Kell Ostrand"
  """
  @spec note_line(String.t(), String.t() | nil) :: String.t()
  def note_line(artist, nil), do: artist
  def note_line(artist, genre), do: artist <> " · " <> genre

  @doc """
  The query the board is drawn mid-typing, and what the specimen card names.

  A SPECIMEN and therefore copy, which is `Kati.Screens.AddTitle.field/2`'s
  ruling on its own `quiet`: the board is drawn mid-query on this word and the
  resting field shows it greyed. It is the surname the three rows are by —
  `اوستراند` once `Kell Ostrand` is `کل اوستراند` — so a page that left it Latin
  would be quoting a search nobody on it could have typed.

  `pgettext/2` because a bare seven-letter msgid is what `mix gettext.merge`'s
  fuzzy matcher takes for a near-miss of some other short string.
  """
  @spec drawn_query() :: String.t()
  def drawn_query, do: pgettext("board 179 specimen query", "ostrand")

  @doc false
  @spec scope_list() :: [String.t()]
  def scope_list, do: @scopes

  @doc """
  The word a scope chip shows for the value it carries.

  A literal per clause, because a msgid has to be a literal at the call site —
  `gettext(value)` does not compile — and five chips are five decisions rather
  than one table.

  `pgettext/2` with **screen 06's own context**, and three of the five entries
  are already in the catalogue under it: this row is that row plus two, and a
  context of its own would hand a translator `Everything` a second time and let
  the two sheets drift apart on the word for it. Only `Albums` and `Artists` are
  new. Both are plural where `Kati.Screens.ArtistDetail`'s totals tile is
  singular, which is the difference between a chip that names a set and a tile
  that counts one.
  """
  @spec scope_label(String.t()) :: String.t()
  def scope_label("Everything"), do: pgettext("add-title filter", "Everything")
  def scope_label("Films"), do: pgettext("add-title filter", "Films")
  def scope_label("Series"), do: pgettext("add-title filter", "Series")
  def scope_label("Albums"), do: pgettext("add-title filter", "Albums")
  def scope_label("Artists"), do: pgettext("add-title filter", "Artists")
  def scope_label(other), do: other

  def render(assigns) do
    shown = Kati.Screens.AddTitleMusic.visible(assigns.results, assigns.filter)
    found = length(shown)

    # Screen 06's eyebrow and screen 06's msgid. Two sheets counting the same
    # thing must not need two entries to say so, and `Kati.UI.eyebrow/2` raises
    # the Latin side through `Kati.UI.eyebrow_label/1` — so the drawing's
    # `3 RESULTS` still comes out of a sentence-case entry, and Persian, which
    # has no case, is left as it is written.
    count = ngettext("%{n} result", "%{n} results", found, n: Kati.Locale.number(found))

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

  Matched on the five English keys and never on what a chip says, which is the
  whole of why `scope_label/1` is a separate function — see `@scopes`.
  """
  @spec visible([map()], String.t()) :: [map()]
  def visible(_results, "Artists"), do: []
  def visible(results, _filter), do: results

  @doc false
  def header do
    # Screen 06's heading, and the same three decisions it records for it.
    # `Add a title` is the catalogue's existing entry — this sheet is a STATE of
    # that one, so it says the same words. `Kati.Locale.tracking/1` carries the
    # drawing's -0.03: negative tracking pulls Arabic letters apart at the
    # joins, so the kerning the design wants is the thing that breaks the word.
    # And `max_lines={1}` arrives with it, because a display heading that wraps
    # pushes the close disc down the page and the disc is this sheet's only
    # dismissal.
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
    # The placeholder is `drawn_query/0` rather than a second copy of the same
    # word. The board draws one query in two places — greyed in the field, named
    # by the empty card below it — and two literals is how they come to show
    # different words the first time either is reworded.
    assigns = %{
      query: query,
      placeholder: Kati.Screens.AddTitleMusic.drawn_query(),
      on_change: {self(), :album_query}
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
          placeholder={@placeholder}
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
      |> Enum.map(fn value -> Kati.Screens.AddTitleMusic.chip(value, value == active) end)
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
  def chip(value, on?) do
    # The tag carries the VALUE and the chip shows the LABEL — see `@scopes`.
    # `MishkaChip` takes its label as a string and discards children, so the
    # word cannot carry a `font_family` of its own; `Kati.Locale.face_prop/0` on
    # the root node is what sets it, which is the half a component cannot reach
    # and the reason that prop is drawn where it is.
    MishkaChip.chip(
      label: Kati.Screens.AddTitleMusic.scope_label(value),
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
    # Two of this row's three lines can now hold Arabic script, and screen 06's
    # own row records both fixes.
    #
    # The TITLE takes `Kati.Locale.tracking/1`, because -0.015 on `کارهای جزر و
    # مد` pulls the letters apart at the joins rather than tightening them.
    #
    # The META was a hardcoded `font_family="mono"` and `kati_mono.ttf` carries
    # no Persian glyph at all, so `۲۰۲۵ · آلبوم · ۱۱ آهنگ` fell through to
    # whatever face Android substitutes — legible, in a typeface that is not
    # Kati's, beside rows that are. `Kati.Locale.mono_face/1` asks the STRING's
    # script rather than the reader's, which is the finer question and leaves an
    # all-ASCII line in DM Mono on a Persian page.
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
      <Spacer size={12} />
      {Kati.Screens.AddTitleMusic.add_button(r.added, r.key)}
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
    initial = Kati.Music.Album.initial(%Kati.Music.Album{title: title})

    # The letter asks its OWN script and not the reader's, which is the finer
    # question for a slot holding one character off a record's name: `T` stays
    # in DM Mono on a Persian page, exactly as board 179 draws it, and `ک` —
    # what `Kati.Music.Album.initial/1` answers for کارهای جزر و مد — takes
    # Vazirmatn instead of the face Android substitutes for a glyph
    # `kati_mono.ttf` does not carry. `Kati.Music.Sample.album/0` makes the same
    # point about the same letter for screen 74's tile.
    assigns = %{initial: initial, face: Kati.Locale.mono_face(initial)}

    ~MOB"""
    <Box width={52} height={52} corner_radius={11} background={Palette.placeholder()} align="center">
      <Text
        text={@initial}
        font_family={@face}
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

  The argument is the row's `key` and not its title: the tag has to read
  `add_Tidal Works` in every locale, which is the name
  `Kati.MusicAddByHandTest` taps it by and the only reason `String.to_atom/1`
  here is safe. See `drawn_results/0`.
  """
  @spec add_button(boolean(), String.t()) :: map()
  def add_button(true, _key) do
    MishkaActionIcon.action_icon(
      [size: 34, shape: :circle, variant: :filled, background: Palette.paper()],
      [UI.symbol("check", size: 19, color: Palette.sub())]
    )
  end

  def add_button(false, key) do
    MishkaActionIcon.action_icon(
      [
        size: 34,
        shape: :circle,
        variant: :filled,
        background: Palette.ink_fill(),
        on_tap: String.to_atom("add_" <> key)
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
          text={gettext("Can’t find it? Add it by hand")}
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
    # `pgettext/2` on a two-word eyebrow: `mix gettext.merge` fuzzy-matches a
    # short new msgid onto any longer sentence that resembles it, and the
    # catalogue already carries *Nothing here for “…”* and *Nothing to save
    # yet.* for it to find. The context names the band.
    #
    # `Kati.UI.Eyebrow.quiet/1` raises the Latin side itself and asks the
    # label's own script for its face, so `چیزی پیدا نشد` arrives in Vazirmatn
    # and `NOTHING FOUND` in DM Mono, out of one sentence-case entry.
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.Eyebrow.quiet(pgettext("board 179 band", "Nothing found"))}
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
    # One msgid for the whole headline, quotation marks included, rather than a
    # stem with two marks concatenated around the query.
    # `Kati.Screens.AddTitle.found_nothing/1` quotes this sentence character for
    # character on the sheet beside this one and its own comment says why: one
    # entry is what keeps the two sheets saying one thing, and a Persian
    # translator swaps `“…”` for the guillemets `«…»` in the same edit that
    # writes the words — which a split stem could not express.
    #
    # `query` is deliberately NOT wrapped in `Kati.Locale.ltr/1`. It is the
    # reader's own text and can be in either script; isolating a Persian query
    # as a left-to-right run would be the exact defect that helper exists to
    # fix, and a Latin one is bounded by the sentence's own quotation marks on
    # both sides, so it strands no neutral at the wrong edge.
    assigns = %{headline: gettext("Nothing here for “%{query}”", query: query)}

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
        text={gettext("Kati has no music catalogue to look in. Type it and it is yours.")}
        text_size={12.5}
        line_height={Kati.Locale.leading(1.55)}
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
          text={gettext("Add it by hand")}
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

  @doc """
  The board's dashed annotation, in the runs it is drawn in.

  Seven runs and not one paragraph, for `Kati.Screens.AddByHandBook.annotation/0`'s
  reason: the board writes its emphasis as its own run, and
  `Kati.ScreenDesignLiteralTest` compares a drawing's lines against the tree's,
  so a joined sentence would no longer be the same shape.

  Six of the seven are msgids, and two of those are short enough to take
  `pgettext/2` — *square* and *21's FAB opens* are a board's shorthand rather
  than labels, and a one-word msgid is what `mix gettext.merge` fuzzy-matches
  onto any longer sentence containing the word. The context names the board,
  because a run is only a fragment in the company of the other six.

  **The fourth run is not a msgid at all.** It NAMES the chip beside it, so it
  asks `scope_label/1` for the word that chip is drawn with — an annotation and
  the control it describes cannot be allowed to disagree, which is what two
  entries for one word eventually produce.

  The board numbers stay inside the sentences: they are part of a sentence a
  translator rewrites whole, and the Persian catalogue already writes them in
  its own digits where the sentence puts them. The aspect RATIO is bound
  instead, which is `Kati.Screens.AddByHandRecord.decision_note/0`'s split for
  its own `4:12` — a figure is numerals a Persian reader reads in their own
  digits, and not a word a translator should have to retype correctly.
  """
  @spec note() :: map()
  def note do
    # Built out here rather than inside the sigil: `@name` in `~MOB` is an
    # ASSIGN, so a binding read through one cannot also be an argument to the
    # call that consumes it.
    assigns = %{
      shape:
        gettext(
          ", and the paper placeholder carries its initial rather than a %{ratio} poster. Five chips is the most any chip row in Kati carries;",
          ratio: Kati.Locale.number("2:3")
        ),
      everything: Kati.Screens.AddTitleMusic.scope_label("Everything")
    }

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
          text={gettext("The one row-shape difference from 06: an album is a")}
          text_size={12.5}
          line_height={1.65}
          text_color={Palette.ink_soft()}
        />
        <Text
          text={pgettext("board 179 annotation", "square")}
          text_size={12.5}
          line_height={1.65}
          font_weight="semibold"
          text_color={Palette.ink()}
        />
        <Text text={@shape} text_size={12.5} line_height={1.65} text_color={Palette.ink_soft()} />
        <Text
          text={@everything}
          text_size={12.5}
          line_height={1.65}
          font_weight="semibold"
          text_color={Palette.ink()}
        />
        <Text
          text={gettext("and the lit chip are pinned when it scrolls. This is the state")}
          text_size={12.5}
          line_height={1.65}
          text_color={Palette.ink_soft()}
        />
        <Text
          text={pgettext("board 179 annotation", "21’s FAB opens")}
          text_size={12.5}
          line_height={1.65}
          font_weight="semibold"
          text_color={Palette.ink()}
        />
        <Text
          text={gettext("— not a second add control on the shelf, which would be a second door to a sheet that already has one.")}
          text_size={12.5}
          line_height={1.65}
          text_color={Palette.ink_soft()}
        />
      </Column>
    </Row>
    """
  end

  def handle_info({:tap, :back}, socket), do: {:noreply, Kati.Screens.Resume.pop(socket)}

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

      # The row's KEY, which is what `add_button/2` put in the tag — never the
      # title the row draws. See `drawn_results/0`.
      "add_" <> key ->
        {:noreply, Kati.Screens.AddTitleMusic.add(socket, key)}

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

  Found by `key` and not by `title`, which is what makes the lookup survive the
  reader's language: the tag `add_button/2` drew is the English name of the row
  and the row still carries it, where the title beside it is the word the page
  is set in. `drawn_results/0` carries the argument.
  """
  @spec add(Mob.Socket.t(), String.t()) :: Mob.Socket.t()
  def add(socket, key) do
    case Enum.find(socket.assigns.results, &(&1.key == key and not &1.added)) do
      nil ->
        socket

      row ->
        case Kati.Screens.AddTitleMusic.shelve(row) do
          {:ok, _album} ->
            socket
            |> Mob.Socket.assign(
              :results,
              Kati.Screens.AddTitleMusic.mark(socket.assigns.results, key)
            )
            |> Mob.Socket.assign(:save_error, nil)

          error ->
            Mob.Socket.assign(socket, :save_error, Kati.Write.message(error))
        end
    end
  end

  @doc """
  The write, with the row's own four values.

  `title` and `artist` and not `key`: what goes on the shelf is the record as
  this page named it, so a Persian reader who taps the disc under
  *کارهای جزر و مد* gets *کارهای جزر و مد* on screen 21 rather than a row in a
  language they were not reading. The key is this sheet's private handle for a
  row and belongs nowhere near the store.

  `released` and `tracks` are the untouched Latin figures `drawn_results/0`
  carries, and `Kati.Screens.AddByHandRecord.write/3` parses both through
  `Kati.I18n.Digits.parse_integer/1` — which reads either script, so nothing
  here depends on which one they are in.
  """
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
  def mark(results, key) do
    Enum.map(results, fn r -> if r.key == key, do: %{r | added: true}, else: r end)
  end
end
