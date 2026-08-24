defmodule Kati.Screens.ArtistDetailStates do
  @moduledoc """
  Screen 78 — the seven conditions screen 77 can be in, on one sheet.

  Built in screen 27's manner, and under 27's rule: every card here is a
  *picture* of a state rather than a report that the app is in it. All seven are
  drawn at once and unconditionally — nothing-new, metadata-only, partially
  filled, loading, error, offline, dark — so gating any of them on the device's
  actual condition would show six states on one phone and three on another,
  which is the opposite of what a reference sheet is for.

  ## Nothing new is a sentence, not a blank

  The design's caption names the first decision: *nothing-new gets a green check
  and a date rather than an absence — 30's "nothing else until" manner*. Screen
  77's page is built around the one orange card that says a record is out, and
  the obvious translation of "no such record" is to draw nothing. That is wrong
  twice over: an absence is indistinguishable from a fetch that has not
  finished, and it leaves the user to work out whether Kati looked. A tick and a
  date answer both — `You have heard everything`, and the release the answer was
  measured against. It is the same move screen 30 makes with *nothing else
  until*: state the boundary, so silence reads as a finding.

  The eyebrow above it keeps the orange dash while every other section on the
  sheet takes the grey one. Orange means new or now, and on screen 77 it appears
  exactly once — on the unheard-release card. This is that card's other outcome,
  so the accent stays where the two pages already agree it lives.

  ## Progressive fill is counted, and never a spinner

  The second decision, and the caption is explicit about all of it: *a quiet
  counted note with a bronze arc, never a spinner: the rail renders local rows
  immediately and unresolved tiles hold their geometry with a skeleton title, so
  nothing reflows as metadata trickles in at one a second*.

  MusicBrainz allows one request a second, so a four-album discography takes four
  seconds to resolve and the user is looking at the page for all four of them. A
  spinner over the rail would hide the rows Kati already has — the play counts
  and ratings are local and were never waiting on anything — so the rail draws
  immediately and the *count* carries the waiting: `Filling in 2 of 4`, with the
  rate stated beside it in mono because a rate is a fact about the service
  rather than about this artist.

  Each unresolved tile holds its square and puts a skeleton bar where its title
  will be. That is what stops the reflow: the tiles are laid out by
  `Kati.UI.even_row/2`, which top-aligns its cells, so a tile whose second line
  arrives grows downward on its own and no neighbour and nothing above it moves.
  A tile that drew nothing until its metadata landed would shove the whole grid
  three times over the four seconds.

  The grid shows the first three of the four albums and the note counts all
  four — the second resolved one is the tile the frame cuts off, which is the
  same rail-scrolls/chart-truncates split screen 77's own caption sets out.

  ## What this reuses from screen 77, and the one thing it could not

  The albums come from `Kati.Screens.ArtistDetail.albums/0` and the artist from
  `Kati.Screens.ArtistDetail.artist/0`, so the partially-filled grid and the dark
  chart are screen 77's own two lists under a different condition rather than a
  second copy of them that could drift. The dark chart also scales against the
  loudest album exactly as `Kati.Screens.ArtistDetail.chart/0` does, for the same
  reason its doc gives.

  `Kati.Screens.ArtistDetail.bar/2` itself could not be called, and the reason is
  worth stating because it is not a layout quibble: it resolves its two colours
  through `Kati.Theme.Palette.mode/0`, which on this sheet answers `:light`,
  because the sheet *is* light and only one card on it is dark. So the dark chart
  states its four tones and its track explicitly, in `:dark`, which is what
  `Palette`'s one-argument form is for.

  ## What is read and what is drawn

  Four lines look like data and are not, and each is left as copy for a reason:

    * **`Nothing announced since Nine Rooms, 2021`** is a claim about what
      MusicBrainz has published. Nothing in the app records when a discography
      was last checked against the service, so the date could only be invented,
      and inventing it here would read as a live report.
    * **`Filling in 2 of 4`** counts a fetch that is not running. The four is the
      artist's real album count; the two is the picture.
    * **`Last success 6h ago`** could be read —
      `Kati.Calendars.Account.last_sync_at` holds exactly that instant — and is
      not, for screen 27's reason: the card above it is drawn whether or not
      anything failed, and dating a real success against an invented failure is
      worse than the drawing.
    * **`Offline`** is a condition of the device, which no resource stores and
      which this sheet draws with the radio on.

  ## What the bridge cannot draw, recorded rather than approximated silently

    * **A horizontal shimmer.** The skeleton bars are
      `linear-gradient(90deg,#E7E3DC,#F1EEE9,#E7E3DC)` in the drawing. The
      bridge's gradient parser is vertical only, so they are the flat colour the
      gradient starts and ends on — `Kati.Theme.Palette.track/0`. Screen 27
      carries the same note about the same bars.
    * **The bronze arc.** The drawing's progress ring is a 22pt circle with a
      grey inset ring and `border-top: 2px solid #B08E55`, which paints the top
      arc bronze. `Modifier.border` takes one colour for all four edges and
      Compose has no partial-stroke prop, so the ring is drawn grey and the
      bronze is a 10x2 chord laid along its top edge. The reading is the same —
      a quarter of the way round — and it is a declared shape rather than an arc.
    * **`aspect-ratio`.** The album tiles are `width:100%;aspect-ratio:1`. No
      geometry comes back from `render/1`, so the square's height is declared
      while its width still follows the cell's weight; see `@tile`.

  One deviation is this file's own choice rather than the bridge's:
  `Kati.UI.SettingsList.title/2` sets its sub-line in mono at 11 and this
  drawing sets `seven states` in sans at 13.5. The shared title is used anyway,
  because 78 is 27's sibling and two reference sheets that disagree about their
  own heading would be the more visible mistake.

  Nothing here is tappable and there is no `handle_tap/2`, deliberately: the
  `Retry` pill is a picture of a control, and `Kati.Screens.Pushed` defines no
  catch-all so a control that ever does become live is reported rather than
  silently dead.
  """

  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.Screens.ArtistDetail
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  # (402 - 21 - 21 - 12 - 12) / 3 — the drawing's frame, less its page padding
  # and the two gutters, divided three ways. Only the HEIGHT is pinned to it:
  # the width comes from `Kati.UI.even_row/2`'s weight and so still divides
  # whatever width the device actually has. A square that measured itself would
  # need geometry back from `render/1`, and none comes.
  @tile 112

  # How many of the three visible tiles have their metadata back. The note above
  # counts all four albums; see the moduledoc.
  @filled 1

  @impl true
  def load(socket) do
    socket
    |> Mob.Socket.assign(:artist, ArtistDetail.artist())
    |> Mob.Socket.assign(:albums, ArtistDetail.albums())
  end

  @doc false
  def content(assigns) do
    artist = assigns.artist
    albums = assigns.albums

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {SettingsList.chrome(nil, 44)}
        {SettingsList.title("Artist detail", "seven states", nil, :name)}
        {UI.eyebrow("Nothing new — says so plainly")}
        {Kati.Screens.ArtistDetailStates.nothing_new()}
        {SettingsList.eyebrow_muted("Metadata-only — known by name, no albums resolved")}
        {Kati.Screens.ArtistDetailStates.no_albums()}
        {SettingsList.eyebrow_muted("Partially filled — MusicBrainz allows 1 request a second")}
        {Kati.Screens.ArtistDetailStates.partial_grid(albums)}
        {Kati.Screens.ArtistDetailStates.filling_note()}
        {SettingsList.eyebrow_muted("Loading · error · offline")}
        {Kati.Screens.ArtistDetailStates.loading()}
        {Kati.Screens.ArtistDetailStates.error()}
        {Kati.Screens.ArtistDetailStates.offline()}
        {SettingsList.eyebrow_muted("Dark")}
        {Kati.Screens.ArtistDetailStates.dark(artist, albums)}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The nothing-new card: a green tick, a claim, and the record it is measured
  against.

  The tick is the design's one filled glyph on this sheet — `FILL 1` in the
  drawing — because a half-drawn check reads as a checkbox rather than as an
  answer.
  """
  @spec nothing_new() :: map()
  def nothing_new do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={15}
        align="center"
      >
        {UI.symbol("check_circle", size: 19, color: Palette.green(), fill: true)}
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text
            text="You have heard everything"
            text_size={13.5}
            font_weight="bold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={3} />
          <Text
            text="Nothing announced since Nine Rooms, 2021"
            text_size={11.5}
            text_color={Palette.sub()}
            max_lines={2}
          />
        </Column>
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  The metadata-only card: an artist Kati has a name for and nothing else.

  It invites rather than apologises — screen 27's rule for an empty state — but
  it carries no button, because the action that fills a discography is logging a
  listen and that does not happen on this screen. The sentence names it instead.
  """
  @spec no_albums() :: map()
  def no_albums do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={15}
      >
        <Spacer size={8} />
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          <Box width={52} height={52} corner_radius={16} background={Palette.paper()} align="center">
            {UI.symbol("graphic_eq", size: 24, color: Palette.rail_idle())}
          </Box>
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={14} />
        <Text
          text="No albums yet"
          text_size={14.5}
          font_weight="bold"
          letter_spacing={-0.02}
          text_color={:on_surface}
          text_align="center"
        />
        <Spacer size={7} />
        <Text
          text="Kati knows this artist by name only. Log a listen and the discography fills in."
          text_size={12.5}
          line_height={1.55}
          text_color={Palette.sub()}
          text_align="center"
        />
        <Spacer size={8} />
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  The album grid, mid-fill: one tile resolved and two holding their geometry.

  Three tiles, chunked by a declared column count because a `Row` does not wrap,
  and handed to `Kati.UI.even_row/2` so the width divides whatever the device
  has rather than the drawing's 402.
  """
  @spec partial_grid([map()]) :: map()
  def partial_grid(albums) do
    {resolved, pending} = albums |> Enum.take(3) |> Enum.split(@filled)
    cells = Enum.map(resolved, &tile/1) ++ Enum.map(pending, fn _album -> pending_tile() end)
    grid = UI.even_row(cells, columns: 3, gap: 12)

    ~MOB"""
    <Column fill_width={true}>
      {grid}
      <Spacer size={11} />
    </Column>
    """
  end

  # A resolved tile: artwork, title, and the line that says whether you have
  # heard it — `album.line` is screen 77's own, so `Unheard` still reads as a
  # fact rather than as `0 plays`.
  defp tile(album) do
    ~MOB"""
    <Column fill_width={true}>
      {tile_art(album)}
      <Spacer size={9} />
      <Text
        text={album.title}
        text_size={12.5}
        font_weight="bold"
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer size={3} />
      <Text
        text={album.line}
        font_family="mono"
        text_size={10}
        text_color={Palette.muted()}
        max_lines={1}
      />
    </Column>
    """
  end

  # The same square, with a skeleton where the title will be and nothing where
  # the mono meta will be. The square is what holds the grid still; the two text
  # lines settle inside a top-aligned cell and move nothing but themselves.
  defp pending_tile do
    ~MOB"""
    <Column fill_width={true}>
      {tile_art(%{seed: nil})}
      <Spacer size={9} />
      <Row fill_width={true}>
        <Box weight={0.7} height={11} corner_radius={6} background={Palette.track()} />
        <Spacer weight={0.3} />
      </Row>
    </Column>
    """
  end

  # `side` is bound out here rather than written as `@tile` inside the markup:
  # the sigil rewrites `@foo` to `assigns.foo`, so a module attribute inside
  # `{...}` is read as an assign that does not exist.
  defp tile_art(album) do
    side = @tile

    case album.seed && Kati.Design.Images.poster(album.seed) do
      nil ->
        ~MOB"""
        <Box
          fill_width={true}
          height={side}
          corner_radius={12}
          background={Palette.placeholder()}
          shadow={Kati.Theme.shadow_card_soft()}
        />
        """

      src ->
        ~MOB"""
        <Image src={src} fill_width={true} height={side} corner_radius={12} content_mode="fill" />
        """
    end
  end

  @doc """
  The counted note under the grid, with the rate stated beside the count.

  Two `Text` nodes rather than `Kati.UI.rich_text/1`, which is the opposite of
  what that helper is for and is right here: `rich_text/1` flattens its runs to
  one style, and the whole point of `1 a second` is that it is set in mono —
  it is a fact about the service, not about this artist. The line is short
  enough that a `Row` not wrapping costs nothing.
  """
  @spec filling_note() :: map()
  def filling_note do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={15}
        align="center"
      >
        {Kati.Screens.ArtistDetailStates.filling_ring()}
        <Spacer size={11} />
        <Row weight={1.0} align="center">
          <Text
            text="Filling in 2 of 4 ·"
            text_size={12.5}
            text_color={Palette.ink_soft()}
            max_lines={1}
          />
          <Spacer size={5} />
          <Text
            text="1 a second"
            font_family="mono"
            text_size={11.5}
            text_color={Palette.sub()}
            max_lines={1}
          />
          <Spacer weight={1.0} />
        </Row>
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  The ring: a grey circle with a bronze chord along its top edge.

  The drawing asks for `border-top` on a 22pt circle, which paints the top arc
  and leaves the rest of the ring grey. `Modifier.border` colours all four edges
  or none, so the ring is drawn grey once and the bronze is laid over its top as
  a 10x2 bar. It is not an arc; it is at the same place, the same weight and the
  same fraction of the way round, and it does not animate — which is the point
  the caption makes about not using a spinner.
  """
  @spec filling_ring() :: map()
  def filling_ring do
    ~MOB"""
    <Box
      width={22}
      height={22}
      corner_radius={11}
      border_width={2}
      border_color={Palette.placeholder()}
      align="top"
    >
      <Row fill_width={true} align="center">
        <Spacer weight={1.0} />
        <Box width={10} height={2} corner_radius={1} background={Palette.bronze()} />
        <Spacer weight={1.0} />
      </Row>
    </Box>
    """
  end

  @doc """
  The loading card: the hero's shape, before the hero.

  A skeleton and never a spinner — screen 27's rule, and the reason is the same
  one the caption gives for the grid: a skeleton says how tall the thing will be,
  so the page does not jump when it arrives.
  """
  @spec loading() :: map()
  def loading do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={15}
        align="center"
      >
        <Box width={52} height={52} corner_radius={26} background={Palette.track()} />
        <Spacer size={13} />
        <Column weight={1.0}>
          <Box fill_width={true} height={12} corner_radius={6} background={Palette.track()} />
          <Spacer size={9} />
          <Row fill_width={true}>
            <Box weight={0.52} height={10} corner_radius={6} background={Palette.track()} />
            <Spacer weight={0.48} />
          </Row>
        </Column>
      </Row>
      <Spacer size={10} />
    </Column>
    """
  end

  @doc """
  The error card, with the one control on the sheet that would do something.

  It dates the last success rather than the failure, because the question a
  failed artist page raises is not *when did this break* but *how stale is what
  I am looking at* — the play counts below it are local and still true.
  """
  @spec error() :: map()
  def error do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={15}
        align="center"
      >
        {UI.symbol("error", size: 20, color: Palette.red())}
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text
            text="Couldn’t load this artist"
            text_size={13}
            font_weight="bold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={3} />
          <Text
            text="Last success 6h ago"
            text_size={11.5}
            text_color={Palette.sub()}
            max_lines={1}
          />
        </Column>
        <Spacer size={12} />
        {SettingsList.action_pill("Retry")}
      </Row>
      <Spacer size={10} />
    </Column>
    """
  end

  @doc """
  The offline card: cream, and flat.

  No shadow, which is screen 27's distinction and worth keeping — offline is a
  condition the app is in rather than an object lifted off the paper. The
  sentence promises the half of screen 77 that never needed the network: plays
  and ratings are counted locally and render whatever the radio is doing.
  """
  @spec offline() :: map()
  def offline do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.cream()}
        corner_radius={20}
        padding={15}
        align="center"
      >
        {UI.symbol("cloud_off", size: 20, color: Palette.gold_icon())}
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text
            text="Offline"
            text_size={13}
            font_weight="bold"
            text_color={Palette.cream_ink()}
            max_lines={1}
          />
          <Spacer size={3} />
          <Text
            text="Local play counts and ratings still render"
            text_size={11.5}
            text_color={Palette.cream_sub()}
            max_lines={1}
          />
        </Column>
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  Screen 77's top and its chart, in dark, inside the light sheet.

  Every colour is asked for in `:dark` explicitly rather than resolved through
  `Kati.Theme.Palette.mode/0`, because the sheet around it is light and the mode
  would answer for the sheet. That one-argument form exists for exactly this —
  a panel that is deliberately one mode, the way screen 29's lock preview is.

  The card lifts with an inset hairline instead of a shadow, which is screen
  28's rule: a drop shadow on a near-black ground is invisible, so depth is
  drawn as an outline.
  """
  @spec dark(map(), [map()]) :: map()
  def dark(artist, albums) do
    top = albums |> Enum.map(& &1.plays) |> Enum.max(fn -> 0 end)

    bars =
      albums
      |> Enum.with_index()
      |> Enum.map(fn {album, rank} -> dark_bar(album, top, rank) end)
      |> Enum.intersperse(~MOB"<Spacer size={13} />")

    ~MOB"""
    <Column fill_width={true} background={Palette.paper(:dark)} corner_radius={22} padding={16}>
      {Kati.Screens.ArtistDetailStates.dark_hero(artist)}
      <Spacer size={16} />
      <Column
        fill_width={true}
        background={Palette.card(:dark)}
        corner_radius={20}
        border_width={1}
        border_color={Palette.card_hairline(:dark)}
        padding={17}
      >
        {bars}
      </Column>
    </Column>
    """
  end

  @doc """
  The dark twin of screen 77's hero.

  The photograph is a disc carrying the artist's initial, which is how
  `Kati.Screens.ArtistDetail.rail_art/1` already stands in for missing album art
  — the same idea one size up. The letter is set at the faintest step this
  palette has on a near-black card, so the disc reads as a place a photograph
  goes rather than as a monogram somebody chose.
  """
  @spec dark_hero(map()) :: map()
  def dark_hero(artist) do
    initial = artist.name |> String.first() |> String.upcase()

    ~MOB"""
    <Row fill_width={true} align="center">
      <Box
        width={66}
        height={66}
        corner_radius={33}
        background={Palette.placeholder(:dark)}
        align="center"
      >
        <Text
          text={initial}
          font_family="mono"
          text_size={26}
          text_color={Palette.track_off(:dark)}
          max_lines={1}
        />
      </Box>
      <Spacer size={14} />
      <Column weight={1.0}>
        <Text
          text={artist.name}
          text_size={24}
          font_weight="bold"
          letter_spacing={-0.03}
          text_color={Palette.ink(:dark)}
          max_lines={1}
        />
        <Spacer size={4} />
        <Text
          text={artist.subtitle || ""}
          text_size={12.5}
          text_color={Palette.sub(:dark)}
          max_lines={1}
        />
      </Column>
    </Row>
    """
  end

  # One chart row: an 84pt label gutter, the bar, and the count right-aligned in
  # a 22pt column. `text_align="right"` makes a Text fill its parent's width on
  # this bridge, so both ends have to be columns of declared width or the row
  # collapses — the defect screen 08's rating card was flattened by.
  #
  # Scaled against the loudest album rather than a round number, which is
  # `Kati.Screens.ArtistDetail.chart/0`'s decision and has to stay the same one:
  # two drawings of the same chart that disagreed about their axis would not be
  # the same chart.
  defp dark_bar(album, top, rank) do
    fraction = if top > 0, do: album.plays / top, else: 0.0

    rail =
      Kati.Components.MishkaProgress.progress(
        render: :box,
        value: fraction,
        max: 1,
        height: 8,
        corner_radius: 4,
        color: dark_bar_tone(rank),
        track_color: Palette.placeholder(:dark)
      )

    ~MOB"""
    <Row fill_width={true} align="center">
      <Column width={84}>
        <Text
          text={album.title}
          text_size={12}
          font_weight="semibold"
          text_color={Palette.ink(:dark)}
          max_lines={1}
        />
      </Column>
      <Spacer size={12} />
      <Column weight={1.0}>
        {rail}
      </Column>
      <Spacer size={12} />
      <Column width={22}>
        <Text
          text={Integer.to_string(album.plays)}
          font_family="mono"
          text_size={11}
          text_color={Palette.muted(:dark)}
          text_align="right"
          max_lines={1}
        />
      </Column>
    </Row>
    """
  end

  # The dark chart gives each bar its own step down the neutral ladder, where
  # screen 77's light chart gives them all one tone. That is the drawing's
  # decision and it is a sound one on near-black: four bars of one colour at four
  # lengths read as four lengths, and on a dark ground the shortest of them is
  # barely a mark, so the rank has to be carried by value as well as by width.
  #
  # ink -> meta -> settled_ink -> rail_idle, all in `:dark`. Two of the four are
  # within three units of the literal the drawing writes rather than on it —
  # `#B6B1AB` for `#B8B2A8` and `#79736D` for `#7C766D` — because the palette is
  # named for the sixty-two drawings that came before this one and has no step at
  # either value. A token two units out is a colour; a hex literal here would be
  # a colour nothing else in the app could follow into a future mode.
  defp dark_bar_tone(0), do: Palette.ink(:dark)
  defp dark_bar_tone(1), do: Palette.meta(:dark)
  defp dark_bar_tone(2), do: Palette.settled_ink(:dark)
  defp dark_bar_tone(_rank), do: Palette.rail_idle(:dark)
end
