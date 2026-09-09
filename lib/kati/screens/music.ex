defmodule Kati.Screens.Music do
  @moduledoc """
  Screen 21 — the Library root with the **Music** segment selected.

  Built to `test/design/screens/21.html`. Not a pushed screen and not a
  fifth root: the drawing carries the four-tab dock with `grid_view` lit, which
  is the Library root, so this is the same root wearing a different shelf. It
  therefore `use`s `Kati.Screens.Root, root: :library` and tapping **Screen**
  swaps back to `Kati.Screens.Library` the same way a root switch does.

  The drawing's note is the reason the layout is so familiar: *"third shelf,
  same skeleton"*. Header, segmented control on its `#E4E0D9` trough, then
  sections. What differs is what a shelf of music needs and a shelf of film
  does not — square artwork instead of 2:3 posters, and a listening-time card
  where the film shelf has quick tiles.

  Three literal details worth naming, because each was a decision:

    * **The selected segment carries a shadow here.** Screen 03's does not.
      `0 1px 2px rgba(26,25,23,.06), 0 6px 12px -8px rgba(26,25,23,.4)` is a
      lighter recipe than any token in `Kati.Theme`, so it is written out.
    * **`41 PLAYS` is orange.** Plays this week are "now", which is the one
      thing accent is allowed to mean.
    * **"New from artists you follow" gets the grey dash** — the records are
      not out yet, so the section is not new. `Kati.UI.Eyebrow.quiet/1`.

  Album tiles take an equal share of the row, which is what the export actually
  writes: `flex:1` with `aspect-ratio:1`. The 112 that `112*3 + 12*2 = 360`
  produces is the arithmetic of the drawing's own 402pt frame, and a real
  411dp device leaves 369dp between the 21pt gutters, so a fixed 112 leaves
  the rail 9dp short. The width has always been a weight; the *height* is now
  `aspect_ratio={1.0}` rather than a declared 112, because a capture measured
  the covers 115 wide and 112 tall — the drawing's squares, drawn oblong. The
  modifier chain is weight → aspect_ratio, so the square is taken off the width
  the Row actually granted, at any frame. A rail of fewer than three is padded
  to three with empty weighted columns, because *equal share* is only the
  drawing's arrangement while there are three of them: one album alone took the
  whole 369dp and drew a square the height of the page.

  ## Where the data comes from

  `Kati.Music`, through `page/0` — one entry point for the whole screen,
  because the three tiles, the listening card, the release band and the
  header's count are four views of one shelf, and four entry points could show
  four different shelves. `Kati.Screens.Books.page/0` is the same arrangement
  one shelf over and for the reason written there.

  This file used to argue at length that the move had to wait on `Kati.Media`
  growing a byline column and a play history. Both exist, and not on
  `Kati.Media`: `Kati.Music.Album` is the record, `Kati.Music.Artist` is the
  person the band follows, `Kati.Music.Track.plays` is the count the tile
  prints and `Kati.Music.Listen` is the sittings the card totals. So the three
  values that paragraph called blocked — the artist under a tile, `41 PLAYS`,
  and the listening card entire — are read now.

  Read through the screens that already read them wherever one exists.
  `Kati.Screens.AlbumDetail.play_count/1` is this tile's number *and* screen
  74's `41 plays`; `Kati.Screens.ArtistDetail.unheard_albums/1` is this band's
  rows *and* screen 77's own unheard card. Two implementations of either would
  be two chances for one journey to print two different figures about one
  record — the defect `Kati.Screens.Books.rail/2` exists for, one domain over.

  ## The drawing is the floor, not a stage this screen has passed

  With nothing shelved the screen draws `Kati.Music.Sample` exactly — the three
  tiles, `9h 12m` over its twenty bars, both release rows and
  `418 albums · 61h this year` — which is the values
  `test/design/screens/21.html` was captured from. FIDELITY's rule: missing
  data is not a reason for a blank screen.

  A shelf holding one album shows **one** album. The `418` that
  `Kati.Music.Sample.subtitle/0` keeps as a literal is kept for the *drawing* —
  a shelf is a window onto a library of 418 — and stops being a defence the
  moment there is a real shelf to count. So `page/0` branches once, on the
  shelf, and every value on the screen goes with it: a rail of the user's own
  covers under the drawing's listening total would be a worse lie than a screen
  that is stand-in throughout.

  ## Which three albums are *on repeat this week*

  An album with a `Kati.Music.Listen` in the last seven days comes first, and
  the shelf's own order — `read :shelf`, most recently touched — orders the
  rest and fills the row when nothing was played this week. That last part is a
  stretch of the eyebrow and it is the smaller of the two available stretches:
  the alternative is the drawing's three, records the user does not own, over a
  header counting the ones they do.

  Three, and the cap is the layout's rather than the design's taste: the band is
  one `<Row>` of weighted tiles and Mob has no wrapping primitive, so a fourth
  album would not wrap onto a second line — it would narrow the other three.
  """
  use Kati.Screens.Root, root: :library

  alias Kati.Components.MishkaActionIcon
  alias Kati.Music.Album
  alias Kati.Music.Artist
  alias Kati.Music.Listen
  alias Kati.Music.Sample
  alias Kati.Theme.Palette
  alias Kati.UI

  # The row is one `<Row>` of weighted tiles — see the moduledoc.
  @tiles 3

  # The drawing's field is twenty bars wide, and the width is the window: a
  # twenty-first bar would not fit the 40pt field's arithmetic and a nineteenth
  # would leave a gap where the drawing has none.
  @days 20

  # `On repeat this WEEK`. Seven days back from today, inclusive.
  @week 7

  @impl true
  # The page is read once, here, and carried on the socket. `handle_tap/2` reads
  # it back to resolve a tapped tile to its row — see `open_album/2` — and a
  # second query at tap time could answer with a shelf that had moved under the
  # tile the person actually pressed.
  def load(socket), do: Mob.Socket.assign(socket, :page, page())

  @doc """
  Everything this screen reads, in one map: the three tiles, the listening
  card, the release band and the header's subtitle.

  One branch and not four, which is `Kati.Screens.Books.page/0`'s arrangement
  and the moduledoc's reason: either every value on the page is this reader's
  or every value is the drawing's. A real rail of covers under the drawing's
  `9h 12m` is a worse screen than an honest fixture.
  """
  @spec page() :: map()
  def page do
    case shelved() do
      [] ->
        drawn_page()

      albums ->
        listens = listens()

        %{
          albums: Kati.Screens.Music.on_repeat(albums, listens),
          listening: Kati.Screens.Music.listening(listens),
          releases: Kati.Screens.Music.new_releases(),
          subtitle: Kati.Screens.Music.subtitle(albums, listens)
        }
    end
  end

  @doc """
  The drawing's values, unconditionally — the fixture, not a fallback path.

  `test/design/screens/21.html` was captured from exactly this map, and
  `Kati.ScreenEmptyDatabaseTest` compares it with what `page/0` answers when
  nothing is shelved.
  """
  @spec drawn_page() :: map()
  def drawn_page do
    %{
      albums: Sample.albums(),
      listening: Sample.listening(),
      releases: Sample.releases(),
      subtitle: Sample.subtitle()
    }
  end

  # The shelf, most recently touched first — `Kati.Music.Album`'s own `:shelf`,
  # which its custom index names as screen 21's order.
  #
  # Same degradation `Kati.Screens.Books.shelved/0` makes: a screen that cannot
  # reach its store answers `[]` and draws the drawing, rather than taking the
  # activity down.
  defp shelved do
    case Ash.read(Album, action: :shelf) do
      {:ok, albums} -> albums
      _other -> []
    end
  rescue
    _error -> []
  end

  # Every sitting, in one read rather than one per album. The card totals a
  # month, the header totals a year and the bars split twenty days, and those
  # are three questions about one list — `Kati.Screens.Film`'s rule that a band
  # is not a query, applied to a screen with four of them.
  defp listens do
    case Ash.read(Listen) do
      {:ok, listens} -> listens
      _other -> []
    end
  rescue
    _error -> []
  end

  # Every artist, by id, in one read. The tiles print a name and the band
  # follows a person, so both want the same map.
  defp artists do
    case Ash.read(Artist) do
      {:ok, artists} -> Map.new(artists, &{&1.id, &1})
      _other -> %{}
    end
  rescue
    _error -> %{}
  end

  @doc """
  The three tiles: played this week first, the shelf's own order after.

  See the moduledoc for why the second half is a stretch and why it is the
  smaller one. `Enum.sort_by/2` is stable, so within each of the two groups the
  shelf's order survives untouched.
  """
  @spec on_repeat([Album.t()], [Listen.t()]) :: [map()]
  def on_repeat(albums, listens) do
    played = played_this_week(listens)
    names = artists()

    albums
    |> Enum.sort_by(&if(MapSet.member?(played, &1.id), do: 0, else: 1))
    |> Enum.take(@tiles)
    |> Enum.map(&Kati.Screens.Music.shaped(&1, names))
  end

  defp played_this_week(listens) do
    since = Date.add(Kati.Time.today(), -(@week - 1))

    for %Listen{album_id: id, listened_on: on} <- listens,
        Date.compare(on, since) != :lt,
        into: MapSet.new(),
        do: id
  end

  @doc """
  One album in the shape the tile draws.

  `id` is the row's own and it is the only field here that is an identity
  rather than a caption — it is what a tapped tile carries to screen 74.
  `Kati.Music.Sample.albums/0`'s three rows do not pass through here and so do
  not have one, which is how `album_tag/1` tells a shelf tile from a drawn one.

  `plays` goes through `Kati.Screens.AlbumDetail.play_count/1` — screen 74's
  own — because that screen prints `41 plays` under the record this tile prints
  `41 PLAYS` over, and one tap is all that separates them. Two counts would be
  one journey saying two things about one album.

  The word is upper-cased here rather than in the render because the export
  writes `41 PLAYS` into the markup, where `This month` beside it is
  `text-transform:uppercase` — `Kati.Music.Sample`'s own note.
  """
  @spec shaped(Album.t(), %{optional(String.t()) => Artist.t()}) :: map()
  def shaped(%Album{} = album, artists) do
    artist = Map.get(artists, album.artist_id)

    %{
      id: album.id,
      seed: album.art_seed,
      title: album.title,
      # The empty string and not a stand-in name: `artist_id` is nullable, a
      # record typed by hand may credit nobody, and `Kati.Books.Book.author`
      # degrades the same way one shelf over.
      artist: (artist && artist.name) || "",
      plays: Kati.Screens.Music.plays_label(Kati.Screens.AlbumDetail.play_count(album))
    }
  end

  @doc """
  The tile's third line, in the drawing's own capitals.

      iex> Kati.Screens.Music.plays_label(41)
      "41 PLAYS"

      iex> Kati.Screens.Music.plays_label(1)
      "1 PLAY"
  """
  @spec plays_label(non_neg_integer()) :: String.t()
  def plays_label(1), do: "1 PLAY"
  def plays_label(count), do: "#{count} PLAYS"

  @doc """
  The header's mono line: `418 albums · 61h this year`.

  Counted, where `Kati.Music.Sample.subtitle/0` is a literal — see the
  moduledoc on why the drawing's `418` is not arithmetic and a real shelf's
  count is. `Kati.Screens.Books.subtitle/1` is the same line one shelf over,
  and keeps the plural for a shelf of one for the same reason: the drawing
  writes one word there and a screen is not the place to grow a second.

      iex> Kati.Screens.Music.subtitle([%{}, %{}], [])
      "2 albums · 0h this year"
  """
  @spec subtitle([Album.t()], [Listen.t()]) :: String.t()
  def subtitle(albums, listens) do
    year = Kati.Time.today().year
    minutes = listens |> Enum.filter(&(&1.listened_on.year == year)) |> Listen.total_minutes()

    "#{length(albums)} albums · #{Listen.hours_label(minutes)} this year"
  end

  @doc """
  The listening card: its label, this month's total, the window and the bars.

  `label` is copy — the drawing's own word for what the card counts — and the
  three values under it are `Kati.Music.Listen`'s arithmetic over the same one
  read the rest of the page uses.
  """
  @spec listening([Listen.t()]) :: map()
  def listening(listens) do
    today = Kati.Time.today()
    # `Kati.Music.Listen.in_month/2` and not a filter written here: screens 73
    # and 74 count the same sittings through `this_month/2`, which is this
    # list's length, so where a month begins is one rule rather than two.
    month = Listen.in_month(listens, today)

    %{
      label: "This month",
      total: Kati.Screens.Music.clock(Listen.total_minutes(month)),
      # The month's sittings and not every sitting ever: the card says *This
      # month* over both figures, and a window averaged over three years under
      # a total that is thirty days long would be two different periods in one
      # card. The bars below are the third period on it — twenty days — and
      # that one is the drawing's own, which is why it is not this one.
      window: Kati.Screens.Music.window(month),
      bars: Kati.Screens.Music.field(listens, today)
    }
  end

  @doc """
  `9h 12m`, from minutes.

  Both halves always, including the zeroes: the card's 30pt slot is the one
  number on the screen and a bare `0m` in it reads as a missing value rather
  than as a quiet month. `Kati.Music.Listen.hours_label/1` is the header's
  coarser form of the same figure and stays where it is — the header says
  `61h` and this says `9h 12m`, which is the drawing's own asymmetry.

      iex> Kati.Screens.Music.clock(552)
      "9h 12m"

      iex> Kati.Screens.Music.clock(0)
      "0h 0m"
  """
  @spec clock(non_neg_integer()) :: String.t()
  def clock(minutes), do: "#{div(minutes, 60)}h #{rem(minutes, 60)}m"

  @doc """
  `mostly 21:00–23:00` — the two hours most listening starts in.

  The modal start hour and the two hours after it, which is the shape the
  drawing writes. Ties go to the earlier hour so one list has one answer.

  **The empty string when nothing has a start time**, and that is the honest
  answer rather than a gap: `Kati.Music.Listen.started_at` is nullable, a
  sitting logged from screen 73 without touching the clock row has none, and a
  window computed from no clocks would be this file inventing the one value on
  the card nobody could check. The slot is drawn either way, and empty it
  measures nothing.

  The hour is the stored instant's. `started_at` is a `:utc_datetime` and the
  app stores no zone beside it, so a device east of UTC reads its own evenings
  an hour or two early — written down in the round's `left_undone` rather than
  papered over with the host's clock, which is not the device's either.

      iex> Kati.Screens.Music.window([])
      ""
  """
  @spec window([Listen.t()]) :: String.t()
  def window(listens) do
    listens
    |> Enum.map(& &1.started_at)
    |> Enum.reject(&is_nil/1)
    |> Enum.map(& &1.hour)
    |> case do
      [] ->
        ""

      hours ->
        hour =
          hours
          |> Enum.frequencies()
          |> Enum.min_by(fn {hour, count} -> {-count, hour} end)
          |> elem(0)

        "mostly #{Kati.Screens.Music.oclock(hour)}–#{Kati.Screens.Music.oclock(rem(hour + 2, 24))}"
    end
  end

  @doc """
  `21:00`, zero-padded, from an hour.

      iex> Kati.Screens.Music.oclock(9)
      "09:00"
  """
  @spec oclock(0..23) :: String.t()
  def oclock(hour), do: String.pad_leading(Integer.to_string(hour), 2, "0") <> ":00"

  @doc """
  Twenty days of listening, as `{height, tone}` in the 40pt field.

  The heights are a share of the tallest day rather than of a declared ceiling,
  because the field has no axis and no number on it: what it shows is which
  evenings were the big ones, and scaling to a fixed ceiling would flatten a
  quiet fortnight into twenty stubs that all look like nothing.

  The tone is the drawing's own rule, in `Kati.Music.Sample.listening/0`'s
  words: *the darker bronze marks the days above the run of ordinary ones*. So
  a day above the mean of the days that had any listening at all is strong and
  the rest are soft, and the two colours are `Kati.Music.Sample.tone/1`'s 1 and
  3 rather than a second pair of literals — the fixture and the read draw the
  same two bronzes or the card changes colour the day a row is written.

  A day with nothing is 0.0 and draws nothing, which is what a day with nothing
  is. `Kati.Music.Sample`'s own field has no zero in it, and inventing a floor
  so the empty days showed a stub would be drawing data that does not exist.
  """
  @spec field([Listen.t()], Date.t()) :: [{float(), non_neg_integer()}]
  def field(listens, today) do
    minutes =
      for offset <- (@days - 1)..0//-1 do
        day = Date.add(today, -offset)

        listens
        |> Enum.filter(&(Date.compare(&1.listened_on, day) == :eq))
        |> Listen.total_minutes()
      end

    peak = Enum.max(minutes)
    ordinary = minutes |> Enum.reject(&(&1 == 0)) |> average()

    Enum.map(minutes, fn m -> {height(m, peak), tone(m, ordinary)} end)
  end

  defp average([]), do: 0.0
  defp average(numbers), do: Enum.sum(numbers) / length(numbers)

  defp height(_minutes, 0), do: 0.0
  defp height(minutes, peak), do: Float.round(40 * minutes / peak, 1)

  defp tone(minutes, ordinary) when minutes > ordinary, do: Sample.tone(3)
  defp tone(_minutes, _ordinary), do: Sample.tone(1)

  @doc """
  The band: every record from an artist you follow that you have not heard.

  *New* is *unheard* and not *recent*, because a release date is the one thing
  this domain does not store — see `left_undone` for the round, and
  `Kati.Music.Album`'s own columns. What the band can say truthfully is which
  records by the people you follow have never been played, which is what the
  card on screen 77 already says about one artist.

  So it says it through **that screen's own reader**:
  `Kati.Screens.ArtistDetail.unheard_albums/1`. A second definition of *unheard*
  here — no listens rather than no track plays, say — would put a record in
  this band and leave it off the artist page it opens, in one journey.

  Uncapped, where the tiles are three: the band is a `<Column>` of rows and a
  fourth row wraps by existing. Ordered by `read :followed`'s name and then by
  `read :for_artist`'s newest release, so two runs draw one order.
  """
  @spec new_releases() :: [map()]
  def new_releases do
    for %Artist{} = artist <- followed(),
        row <- Kati.Screens.ArtistDetail.unheard_albums(artist) do
      %{
        # The ALBUM's id, which is what makes two unheard records by one artist
        # two addressable rows — see `artist_tag/1`.
        id: row.id,
        # And the ARTIST's own, spelled as `Kati.Screens.ArtistDetail.params_for/1`
        # reads it, because the row opens a person rather than a record. One
        # uuid under the key its destination names, rather than a second key
        # here holding the same value.
        artist_id: artist.id,
        seed: row.seed,
        artist: artist.name,
        line: "#{row.title} · #{Kati.Screens.ArtistDetail.unheard_line()}"
      }
    end
  end

  defp followed do
    case Ash.read(Artist, action: :followed) do
      {:ok, artists} -> artists
      _other -> []
    end
  rescue
    _error -> []
  end

  @doc false
  def content(assigns) do
    page = assigns.page

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={132}
      >
        {Kati.Screens.Music.header(page.subtitle)}
        {Kati.Screens.Music.segments()}
        {UI.eyebrow("On repeat this week")}
        {Kati.Screens.Music.tiles(page.albums)}
        {UI.eyebrow("Listening time")}
        {Kati.Screens.Music.listening_card(page.listening)}
        {Kati.UI.Eyebrow.quiet("New from artists you follow")}
        {Kati.Screens.Music.releases(page.releases)}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def header(subtitle) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column weight={1.0}>
          <Text
            text="Library"
            text_size={28}
            max_font_scale={1.6}
            font_weight="bold"
            letter_spacing={-0.03}
            text_color={:on_surface}
          />
          <Spacer size={5} />
          <Text
            text={subtitle}
            font_family="mono"
            text_size={11}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
        {Kati.Screens.Music.disc("search", :open_search)}
        <Spacer size={9} />
        {Kati.Screens.Music.disc("sort", :open_sort)}
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  A 44pt round tap target holding one glyph — `Kati.Components.MishkaActionIcon`.

  The shelf's header disc, identical to screens 15 and 20 and adopted for the
  same reason: the port grew a `shadow` prop this round, and a disc floating
  over paper is defined by that shadow rather than by its fill.

  **The pixels are the same node**: `<Box width={44} height={44}
  align={:center} corner_radius={22.0} background shadow on_tap>` — `shape:
  :circle` is `size / 2`, which is the 22 the markup declared. The `<Row>` the
  port puts around its children hugs the one glyph and is centred by the same
  Box.
  """
  def disc(icon, tag) do
    MishkaActionIcon.action_icon(
      [
        size: 44,
        shape: :circle,
        variant: :filled,
        background: Palette.card(),
        shadow: Kati.Theme.shadow_button(),
        on_tap: {self(), tag}
      ],
      [UI.symbol(icon, size: 21)]
    )
  end

  @doc false
  def segments do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.placeholder()}
        corner_radius={18}
        padding={4}
        align="center"
      >
        {Kati.Screens.Music.segment("movie", "Screen", false, :segment_screen)}
        <Spacer size={4} />
        {Kati.Screens.Music.segment("menu_book", "Books", false, :segment_books)}
        <Spacer size={4} />
        {Kati.Screens.Music.segment("graphic_eq", "Music", true, :segment_music)}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  # The selected slab is a lifted card in a trough, not a tinted rectangle:
  # `0 1px 2px rgba(26,25,23,.06), 0 6px 12px -8px rgba(26,25,23,.4)`. Written
  # out rather than borrowed from Kati.Theme because no token is this light,
  # and rounding it to shadow_card_soft would make the control look pressed.
  @doc false
  def segment(icon, label, true, tag) do
    fg = Palette.ink()
    tap = {self(), tag}

    ~MOB"""
    <Box weight={1.0}>
      <Row
        fill_width={true}
        height={38}
        corner_radius={14}
        background={Palette.card()}
        shadow="0 1 2 0 #0F1A1917 | 0 6 12 -8 #661A1917"
        align="center"
        on_tap={tap}
      >
        <Spacer weight={1.0} />
        {Kati.UI.symbol(icon, size: 17, color: fg)}
        <Spacer size={6} />
        <Text text={label} text_size={13} font_weight="bold" text_color={fg} max_lines={1} />
        <Spacer weight={1.0} />
      </Row>
    </Box>
    """
  end

  def segment(icon, label, false, tag) do
    fg = Palette.segment_idle()
    tap = {self(), tag}

    ~MOB"""
    <Box weight={1.0}>
      <Row
        fill_width={true}
        height={38}
        corner_radius={14}
        background={Palette.transparent()}
        align="center"
        on_tap={tap}
      >
        <Spacer weight={1.0} />
        {Kati.UI.symbol(icon, size: 17, color: fg)}
        <Spacer size={6} />
        <Text text={label} text_size={13} font_weight="semibold" text_color={fg} max_lines={1} />
        <Spacer weight={1.0} />
      </Row>
    </Box>
    """
  end

  # A short rail must still be padded to three. The tiles are weighted, so
  # weights divide whatever is there and a rail holding one album gives it the
  # whole width — a 369dp square where the drawing has a 112 one, which is what
  # a shelf of one album looked like on a device the first time anybody could
  # put one album on it. `Kati.Screens.Books.grid_row/1` pads for this reason
  # and with the same nothing, and screen 03's does too.
  #
  # The drawing's three fill the rail exactly, so nothing is padded on the
  # fallback and its tree is unchanged.
  @doc false
  def tiles(albums) do
    tiles =
      albums
      |> Kernel.++(List.duplicate(nil, max(0, @tiles - length(albums))))
      |> Enum.map(&album/1)
      |> Enum.intersperse(album_gap())

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {tiles}
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def album_gap, do: ~MOB"<Spacer size={12} />"

  # Weighted rather than 112 wide — the export's own `flex:1`. See the moduledoc.
  @doc """
  One album tile's tag: the album's id, or — for a drawn row — its seed.

  Three tiles sharing `:open_album` gave three nodes one `accessibility_id`,
  and `onNodeWithTag` throws on the second match (#97).

  **The id first, because it is the only field that is one.** `art_seed` is
  nullable and nothing stops two records sharing one — a reissue and its
  original, two pressings cached from the same artwork — so a shelf tagged by
  seed puts #97 back the day somebody types two albums by hand.
  `Kati.Music.Sample.albums/0`'s rows have no id and their seeds *are* unique
  per row, which is why the seed stays as the second answer rather than being
  dropped: it keeps the drawing's three tags exactly what they were.

  Not the title, for #97's first trap: two records can share a name, and a name
  that is not unique is not an identity.

      iex> Kati.Screens.Music.album_tag(%{id: "3f2a", seed: "albm1"})
      :open_album_3f2a

      iex> Kati.Screens.Music.album_tag(%{seed: "albm2"})
      :open_album_albm2

      iex> Kati.Screens.Music.album_tag(%{})
      :open_album
  """
  @spec album_tag(map()) :: atom()
  def album_tag(item) do
    identity = Map.get(item, :id) || Map.get(item, :seed, "")

    case identity |> to_string() |> String.trim() do
      "" -> :open_album
      key -> String.to_atom("open_album_" <> key)
    end
  end

  @doc """
  One release row's tag: the record's id, or — for a drawn row — its seed.

  The same rule as `album_tag/1` for the *New from artists you follow* rows,
  which shared `:open_artist`. The two prefixes differ, so an album's tag and a
  release's cannot collide with each other even when both are the same uuid.

  **The ALBUM's id, on a row that opens an ARTIST.** That is deliberate and it
  is the distinction `Kati.Screens.ArtistDetail.album_tag/1` draws in the other
  direction: a tag is an accessibility identity, and this band can hold two
  unheard records by one person, which as two nodes tagged by the artist would
  be #97 again. What the row carries to screen 77 is `:artist_id`, which
  `Kati.Screens.ArtistDetail.params_for/1` reads — the tag addresses the node,
  the params name the subject, and they are not the same fact.

      iex> Kati.Screens.Music.artist_tag(%{id: "9c1b", seed: nil})
      :open_artist_9c1b

      iex> Kati.Screens.Music.artist_tag(%{seed: "albm4"})
      :open_artist_albm4

      iex> Kati.Screens.Music.artist_tag(%{})
      :open_artist
  """
  @spec artist_tag(map()) :: atom()
  def artist_tag(row) do
    identity = Map.get(row, :id) || Map.get(row, :seed, "")

    case identity |> to_string() |> String.trim() do
      "" -> :open_artist
      key -> String.to_atom("open_artist_" <> key)
    end
  end

  @doc false
  def album(nil), do: ~MOB"<Column weight={1.0} />"

  def album(item) do
    ~MOB"""
    <Column weight={1.0} on_tap={{self(), Kati.Screens.Music.album_tag(item)}}>
      {Kati.Screens.Music.cover(item)}
      <Spacer size={9} />
      <Text
        text={item.title}
        text_size={12.5}
        font_weight="bold"
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer size={2} />
      <Text text={item.artist} text_size={11} text_color={Palette.sub()} max_lines={1} />
      <Spacer size={3} />
      <Text
        text={item.plays}
        font_family="mono"
        text_size={10}
        text_color={Palette.accent()}
        max_lines={1}
      />
    </Column>
    """
  end

  @doc false
  def cover(item) do
    case Kati.Design.Images.poster(item.seed) do
      nil ->
        ~MOB"""
        <Box
          fill_width={true}
          aspect_ratio={1.0}
          corner_radius={12}
          background={Palette.placeholder()}
          shadow={Kati.Theme.shadow_card_soft()}
        />
        """

      src ->
        ~MOB"""
        <Box
          fill_width={true}
          aspect_ratio={1.0}
          corner_radius={12}
          background={Palette.placeholder()}
          shadow={Kati.Theme.shadow_card_soft()}
        >
          <Image src={src} fill_width={true} aspect_ratio={1.0} corner_radius={12} content_mode="fill" />
        </Box>
        """
    end
  end

  @doc false
  def listening_card(l) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.cream()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={18}
      >
        <Row fill_width={true} align="bottom">
          <Column weight={1.0}>
            <Text
              text={String.upcase(l.label)}
              font_family="mono"
              text_size={10}
              letter_spacing={0.14}
              text_color={Palette.cream_meta()}
            />
            <Spacer size={6} />
            <Text
              text={l.total}
              text_size={30}
              font_weight="extrabold"
              letter_spacing={-0.04}
              text_color={:on_surface}
            />
          </Column>
          <Spacer size={12} />
          <Text
            text={l.window}
            font_family="mono"
            text_size={11}
            text_color={Palette.cream_meta()}
            max_lines={1}
          />
        </Row>
        <Spacer size={16} />
        {Kati.Screens.Music.bars(l.bars)}
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  # Twenty bars sharing the width by weight, each with a declared height inside
  # a 40pt field. `align="bottom"` is the whole trick — without it every bar
  # hangs from the top and the shape inverts.
  @doc false
  def bars(list) do
    children =
      list
      |> Enum.map(fn {height, tone} -> bar(height, tone) end)
      |> Enum.intersperse(bar_gap())

    ~MOB"""
    <Row fill_width={true} height={40} align="bottom">
      {children}
    </Row>
    """
  end

  @doc false
  def bar_gap, do: ~MOB"<Spacer size={3} />"

  @doc false
  def bar(height, tone) do
    ~MOB"""
    <Box weight={1.0} height={height} corner_radius={3} background={tone} />
    """
  end

  @doc false
  def releases(releases) do
    rows =
      releases
      |> Enum.map(&release_row/1)
      |> Enum.intersperse(release_gap())

    ~MOB"""
    <Column fill_width={true}>
      {rows}
    </Column>
    """
  end

  @doc false
  def release_gap, do: ~MOB"<Spacer size={9} />"

  # The 8pt dot is orange and stays orange even for the Friday record: the
  # drawing marks both rows, and both are the watcher saying *this is new*.
  @doc false
  def release_row(row) do
    ~MOB"""
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
      on_tap={{self(), Kati.Screens.Music.artist_tag(row)}}
    >
      {Kati.Screens.Music.release_art(row)}
      <Spacer size={12} />
      <Column weight={1.0}>
        <Text
          text={row.artist}
          text_size={13.5}
          font_weight="bold"
          text_color={:on_surface}
          max_lines={1}
        />
        <Spacer size={4} />
        <Text text={row.line} text_size={11.5} text_color={Palette.sub()} max_lines={1} />
      </Column>
      <Spacer size={12} />
      <Box width={8} height={8} corner_radius={4} background={Palette.accent()} />
    </Row>
    """
  end

  @doc false
  def release_art(row) do
    case Kati.Design.Images.poster(row.seed) do
      nil ->
        ~MOB"<Box width={44} height={44} corner_radius={10} background={Palette.placeholder()} />"

      src ->
        ~MOB"""
        <Image src={src} width={44} height={44} corner_radius={10} content_mode="fill" />
        """
    end
  end

  # A row with neither an id nor a seed — no tile the shelf or the drawing can
  # produce has one, and the clause is kept because `album_tag/1` and
  # `artist_tag/1` both have an answer for it. Resolved through the same two
  # functions the prefixed tags are, so the empty case is spelled once.
  @impl true
  def handle_tap(:open_album, socket),
    do: {:noreply, Kati.Screens.Music.open_album(socket, :open_album)}

  def handle_tap(:open_artist, socket),
    do: {:noreply, Kati.Screens.Music.open_artist(socket, :open_artist)}

  def handle_tap(:segment_screen, socket) do
    {:noreply, Mob.Socket.reset_to(socket, Kati.Screens.Library)}
  end

  @doc """
  The other two shelves, and the search disc beside them.

  Same as `Kati.Screens.Books`: the three shelves are one control drawn three
  times, and only 03 answered all of it. From here **Books** did nothing, so
  Screen → Music → Books was not a journey a reader could make.

  Push, while `:segment_screen` above resets: `Kati.Screens.Library` is a dock
  root and this screen is pushed from it, so returning to Screen has to reset
  the stack while crossing to Books pushes — which is what 03's own
  `shelf_Books` does.
  """
  def handle_tap(:segment_books, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Books)}

  def handle_tap(:segment_music, socket), do: {:noreply, socket}

  # The disc says which page it is: one control drawn three times, so it names
  # itself three times rather than leaving 19 to guess for all three. The empty
  # query is said out loud because a disc has nothing typed behind it, and
  # silence is what lets 19 open on whatever was last handed over.
  def handle_tap(:open_search, socket),
    do:
      {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Search, %{query: "", back: "Music"})}

  # The sort disc, and the sheet it was drawn for. Board 145 is titled **Sort &
  # filter** and its caption is explicit: *one sheet for screens 03, 20 and 21 —
  # three sheets would end the "identical parts" claim within a release.* This
  # screen is 21, and the trailing header disc beside search is the door that
  # caption describes. `Kati.Screens.ShelfFilters` is finished, registered at
  # `gallery.ex:184` as `:push`, and `Kati.Screens.Library` already pushes it
  # (`library.ex:1246-1251`) — from a ⋯ menu row, which 03 grew only because no
  # shelf had claimed its disc yet.
  #
  # **Bare, and that is the sheet's limit rather than a forgotten argument.**
  # 145's caption ends *only the section-specific sort label changes: Runtime,
  # Pages, Length*, and Length is this screen's — but
  # `Kati.Screens.ShelfFilters.mount/3` matches `_params` and its five sort rows
  # come from `Kati.Library.ShelfFiltersSample.sort_options/0`, where `Runtime`
  # is a literal. There is no key to name a shelf in, and writing one the sheet
  # does not read is an argument nobody can check. When 145 learns which shelf
  # opened it, this push gains its third argument and
  # `Kati.ScreenParamsSweepTest` starts holding it to it.
  def handle_tap(:open_sort, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.ShelfFilters)}

  # Every album tile and every release row, by its own identity — see
  # `album_tag/1` and `artist_tag/1`. The tag is used for routing now and not
  # only for being addressable: each is resolved back to the row the render
  # drew, and that row names its record to the screen it opens.
  #
  # Below the named clauses, above the catch-all: a prefix match placed before
  # them makes every one of them unreachable, silently.
  def handle_tap(tag, socket) when is_atom(tag) do
    name = Atom.to_string(tag)

    cond do
      String.starts_with?(name, "open_album_") ->
        {:noreply, Kati.Screens.Music.open_album(socket, tag)}

      String.starts_with?(name, "open_artist_") ->
        {:noreply, Kati.Screens.Music.open_artist(socket, tag)}

      true ->
        {:noreply, socket}
    end
  end

  def handle_tap(_tag, socket), do: {:noreply, socket}

  @doc """
  Open screen 74 on the tile that carries `tag`.

  The tag is resolved back to its row by running `album_tag/1` over the very
  list the band was built from, rather than by reversing the string —
  `Kati.Screens.Books.open_book/2` gives the reason and it is the same one
  here: a seed is not a key anything can be looked up by, so the string would
  have to be trusted rather than matched.

  Read off `socket.assigns.page` and not off a fresh query. The shelf sorts on
  `updated_at` and *played this week* moves with the clock, so a read at tap
  time can answer with an order the person never saw — and "the tile they
  pressed" is a fact about the render.

  A row with no id — `Kati.Music.Sample.albums/0`'s three, and a tag matching
  nothing — pushes with **no params at all** rather than with `%{album_id: nil}`,
  through the destination's own builder so the empty answer is spelled once.
  """
  @spec open_album(Mob.Socket.t(), atom()) :: Mob.Socket.t()
  def open_album(socket, tag) do
    row = Enum.find(socket.assigns.page.albums, &(Kati.Screens.Music.album_tag(&1) == tag))

    Mob.Socket.push_screen(
      socket,
      Kati.Screens.AlbumDetail,
      Kati.Screens.AlbumDetail.params_for(row)
    )
  end

  @doc """
  Open screen 77 on the release row that carries `tag`.

  `open_album/2`'s rule for the band below it, with one difference worth
  saying out loud: the row is found by the ALBUM's id and what travels is the
  ARTIST's, because the row is about a record and the page it opens is about a
  person. `Kati.Screens.ArtistDetail.params_for/1` reads `:artist_id` off the
  row and answers `%{}` for a drawing that has neither key.
  """
  @spec open_artist(Mob.Socket.t(), atom()) :: Mob.Socket.t()
  def open_artist(socket, tag) do
    row = Enum.find(socket.assigns.page.releases, &(Kati.Screens.Music.artist_tag(&1) == tag))

    Mob.Socket.push_screen(
      socket,
      Kati.Screens.ArtistDetail,
      Kati.Screens.ArtistDetail.params_for(row)
    )
  end

  @doc """
  The state of the add sheet this shelf's `+` opens: board 179, with **Albums**
  lit.

  `Kati.Screens.Root` gives every shelf `Kati.Screens.AddTitle` and marks this
  overridable; this is the one shelf that overrides it. `D-39` is explicit that
  the music door is a STATE of the sheet screen 06 already draws rather than a
  new control — a second add control on this screen would be a second door to a
  sheet that already has one.
  """
  @spec add_sheet() :: module()
  def add_sheet, do: Kati.Screens.AddTitleMusic
end
