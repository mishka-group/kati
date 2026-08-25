defmodule Kati.Screens.ArtistDetailFa do
  @moduledoc """
  Screen 79 — هنرمند, the Persian artist page, pushed under آلبوم.

  Screen 77's page in the mirror. The caption is unusually narrow about what it
  is for:

  > The play-count chart is the point of this board: its axis reads
  > right-to-left and every bar fills **from the right**, with values
  > right-aligned in the mirrored sense — the rule 61 sets for the stats screen,
  > now applied to 07's four-tone genre ramp. Album art holds its direction; the
  > rail scrolls right-to-left.

  ## The chart is the board, and none of it is mirroring logic

  Three things move and all three are the same decision — the root declares
  `rtl` and a sequence starts where the reader starts:

    * **The bar fills from the right.** `bar/3` builds its rail with the same
      `Kati.Components.MishkaProgress.progress/1` call screen 77 uses, and that
      call renders a **Row**: the fill is the track's first child, so it grows
      from the leading edge, which under `rtl` is the right. That is the
      drawing's `float:right`, and it needs no branch. It is also why the call
      is reused rather than replaced — a hand-built `Box` positioned from the
      left would have to be un-positioned here, and the two charts would then be
      two different charts.
    * **The label gutter leads at the right and the count trails at the left.**
      The row is written in one order — label, rail, count — and the `Row` puts
      the first child at the start. Nothing is reversed.
    * **The count is `absolute_left`**, which is screen 61's own choice for the
      same column. Under `rtl` the direction-relative `end` lands in the same
      place, but the drawing writes `text-align:left` inside a `dir="rtl"`
      container, so the absolute value is the literal reading and it says out
      loud that this column has been thought about.

  ## The four tones, and why one of them is eighteen units off

  Screen 77's light chart gives every bar one neutral. This board takes 07's
  genre ramp instead, so rank is carried by value as well as by width, and the
  four literals it draws are `#1A1917`, `#4A443B`, `#7C766D`, `#B3ACA2`.

  Three are palette tokens exactly — `ink`, `bar_ink`, `tertiary`. The second is
  not: the nearest step on the neutral ladder is `ink_soft` at `#5C574F`, and
  the only token that carries `#4A443B`'s value is `cream_body` (`#4A4238`),
  which is *text on a warm card*. Taking it for a bar would bind this bar to the
  cream ladder in dark, where `cream_body` is `#E4DBCE` — one shade off `ink`'s
  `#F5F2EE` — and the top two bars would collapse into each other on the exact
  screen where the ramp is doing the ranking. So the ladder wins and this
  paragraph carries the eighteen units. `Kati.Screens.ArtistDetailStates`
  records the same trade for the same chart in dark.

  ## Album art holds its direction; only the order mirrors

  A photograph does not flip, so the tiles are drawn in the order screen 77's
  own list gives them and the `Row` seats the first one at the right. That is
  the whole of "the rail scrolls right-to-left" — the sequence starts where the
  reader starts and each picture is untouched. Three of four tiles are drawn,
  which is the same rail-scrolls/chart-truncates split screen 77's caption sets
  out: the rail shows what fits and the chart carries all four with a count for
  anything past the cap.

  ## What comes from screen 77, and the one thing that could not

  Every number on this page is screen 77's. `Kati.Screens.ArtistDetail.artist/0`
  answers who the artist is, `albums/0` applies the four-album cap, `truncated/0`
  says what the cap left out, and `unheard_release/0` derives the release the
  cream card is about. The `Following` write is 77's `handle_tap/2` called
  directly, so following somebody from the mirror and from the English page are
  the same write — two toggles that disagreed about a shelf would be worse than
  either being wrong.

  What could not be reused is every `Text`. Plus Jakarta Sans carries no
  Arabic-script glyphs at all, so a Persian label handed to a builder that makes
  its own `Text` is a row of empty boxes rather than a fallback —
  `Kati.Screens.Fa`'s moduledoc checked the font. So `Kati.UI.eyebrow/2`,
  `Kati.Screens.AlbumDetail.stat_tile/2` and `Kati.Screens.ArtistDetail.bar/2`
  are all unavailable here, and each is replaced by the same geometry with a
  `Kati.Screens.BookDetailFa.fa/4` inside it. The mono numerals go the same way,
  for the same reason one level down: `kati_mono.ttf` carries none of
  U+06F0–U+06F9, so everything the drawing sets in DM Mono is set here in `fa`
  at the drawing's size and colour. The face is wrong and the glyphs are right.

  Two shared builders survive intact because they draw no text at all —
  `Kati.UI.SettingsList.icon_tile/1` and `Kati.UI.SettingsList.switch/1` — and
  the row around them is `Kati.UI.SettingsList.row/4` with only its two labels
  replaced. The tile is the shared 30pt one rather than the drawing's 40pt
  square, which is the size screen 77 already draws that row at; a mirror that
  fixed the tile size on one side only would make the two pages disagree about a
  control that is meant to be the same control.

  ## The one number whose calendar depends on where it came from

  The drawing writes the first-heard year as **۱۴۰۲**, which is the Shamsi year
  of the fixture's own date — `Kati.Calendar.Shamsi.from_gregorian/1` answers
  `{1402, 12, 13}` for 3 March 2024 — so `first_heard/1` derives it rather than
  typing it out.

  For a **stored** artist it cannot. `Kati.Screens.ArtistDetail.shaped/2` keeps
  the Gregorian *year* and drops the date, and a Gregorian year straddles two
  Shamsi years because the Persian year turns at Nowruz in late March. The
  drawing's own date proves it: 3 March 2024 is inside the ~80-day window where
  the obvious `year - 621` is wrong by one. So a stored artist's year is shown
  as the Gregorian one in Persian digits, and the fix is one field on
  `shaped/2` — keep `first_heard_on`, not its year — rather than a guess here.

  ## The copy is a proposal, and one line is not in the drawing

  All Persian copy on this board was open, as it was on 72. It lives in
  `drawn/0` and in the label arguments below, so a native reader corrects each
  string once. The one string with no counterpart in the artboard is
  `truncation/1`'s *و ۱ آلبوم دیگر*: the drawing has exactly four albums and so
  never draws it, but the cap is real and a chart that silently claimed four was
  everything would be the mirror lying where the English page does not.
  """

  use Mob.Screen
  import Mob.Sigil

  alias Kati.Calendar.Shamsi
  alias Kati.Screens.ArtistDetail
  alias Kati.Screens.BookDetailFa
  alias Kati.Screens.Fa
  alias Kati.Screens.StatsFa
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  # (402 - 21 - 21 - 12 - 12) / 3 — the drawing's frame, less its page padding
  # and the two gutters, divided three ways. Only the HEIGHT is pinned to it;
  # the width still comes from `Kati.UI.even_row/2`'s weight, so the square
  # divides whatever width the device actually has. `aspect-ratio` cannot be
  # expressed — no geometry comes back from `render/1` — so the number is
  # declared, exactly as `Kati.Screens.ArtistDetailStates` declares it.
  @tile 112

  # How many tiles the rail shows. The chart carries all four; see the moduledoc.
  @tiles 3

  # The date `Kati.Music.Sample.album/0` prints as `3 Mar 2024`, kept as a date
  # so the drawing's ۱۴۰۲ is converted rather than transcribed.
  @first_heard_on ~D[2024-03-03]

  def mount(_params, _session, socket) do
    Kati.Theme.activate()

    {:ok,
     socket
     |> Mob.Socket.assign(:artist, artist())
     |> Mob.Socket.assign(:albums, albums())
     |> Mob.Socket.assign(:release, unheard_release())
     |> Mob.Socket.assign(:dismissed?, false)}
  end

  def render(assigns), do: Fa.pushed_frame(content(assigns), Kati.Screens.Identity.of(__MODULE__))

  @doc """
  Everything the drawing says and nothing it computes.

  Only words live here. The figures — hours, album count, play counts — are read
  back out of screen 77 and converted, so the two pages cannot come to different
  totals for the same artist.
  """
  @spec drawn() :: map()
  def drawn do
    %{
      name: "کل اوستراند",
      subtitle: "آهنگساز · ایسلند",
      following_note: "به نوار تازه‌ها و هشدارها خبر می‌دهد",
      albums_label: "آلبوم‌ها",
      chart_label: "پخش بر اساس آلبوم",
      unheard_label: "نشنیده",
      unheard_badge: "تازه از این هنرمند",
      unheard_line: "جمعه منتشر می‌شود · هنوز نشنیده‌اید",
      remind: "یادآوری کن",
      dismiss: "رد کن",
      totals_label: "مجموع",
      hours_unit: "ساعت",
      first_unit: "اولین",
      albums_unit: "آلبوم",
      back: "آلبوم"
    }
  end

  @doc """
  The artist this screen is about: the shelf album's, in Persian chrome, or the
  drawing's.

  `Kati.Screens.BookDetailFa`'s doctrine, applied to a musician: one artist,
  read once, presented twice. The name, the photograph and the role line are the
  **record's own** and are never translated — a role and a country arrive from
  MusicBrainz in the language MusicBrainz wrote them in, and nothing in
  `Kati.Music` translates anything. The sub-line under the toggle, the eyebrows
  and the tile labels are Kati's copy and stay in the language this screen is
  drawn in.

  With nothing shelved the whole page is `drawn/0`, whose artist *is* Persian
  because a Persian fixture's artist is a Persian artist.
  """
  @spec artist() :: map()
  def artist do
    stored = ArtistDetail.stored_artist()
    base = stored || ArtistDetail.drawn_artist()
    d = drawn()

    %{
      name: if(stored, do: base.name, else: d.name),
      subtitle: if(stored, do: base.subtitle || "", else: d.subtitle),
      photo_seed: base.photo_seed,
      following: base.following,
      following_note: d.following_note,
      hours: hours(base.hours),
      first_heard: first_heard(stored && base.first_heard),
      album_count: Shamsi.to_persian_digits(base.album_count)
    }
  end

  @doc """
  The albums, capped at four — screen 77's list, or the drawing's.

  The cap, the ordering and the play counts are all
  `Kati.Screens.ArtistDetail.albums/0`'s, so the two pages truncate at the same
  place. Only the untouched case is this file's, and there the titles are
  Persian for the same reason the artist's name is.
  """
  @spec albums() :: [map()]
  def albums do
    case ArtistDetail.stored_artist() do
      nil -> drawn_albums()
      _stored -> ArtistDetail.albums()
    end
  end

  @doc """
  The four albums as the drawing writes them: title, year, plays, art.

  The three seeds are the drawing's own — `albm1`, `albm2`, `albm3` — and the
  files ship, so the rail draws real sleeves. `Kati.Music.Sample.artist_albums/0`
  leaves every seed `nil` because screen 77 draws that section as a list of
  40pt initial tiles rather than as artwork, and a paper square with a letter in
  it is the right default for a record whose cover art was never found. Here it
  would be the wrong one: this board's whole claim about artwork is that it does
  **not** mirror, and a row of blank squares cannot show that.

  The fourth album has no slot in the drawing and gets none here. It is the one
  the rail cuts off, and the chart below is where it appears.
  """
  @spec drawn_albums() :: [map()]
  def drawn_albums do
    [
      %{title: "کارهای جزر و مد", year: 2025, plays: 41, seed: "albm1"},
      %{title: "سرزمین پست", year: 2023, plays: 28, seed: "albm2"},
      %{title: "نه اتاق", year: 2021, plays: 19, seed: "albm3"},
      %{title: "نوارهای خور", year: nil, plays: 0, seed: nil}
    ]
  end

  @doc """
  The release the cream card is about, with its own title and Kati's sentence.

  The derivation is screen 77's — the first album with no plays, which is a fact
  about a play count rather than a state anybody sets — and only the line under
  the title is written here.
  """
  @spec unheard_release() :: map() | nil
  def unheard_release do
    case ArtistDetail.stored_artist() do
      nil ->
        %{title: "نوارهای خور", line: drawn().unheard_line}

      _stored ->
        case ArtistDetail.unheard_release() do
          nil -> nil
          release -> %{title: release.title, line: drawn().unheard_line}
        end
    end
  end

  @doc false
  def content(assigns) do
    a = assigns.artist
    albums = assigns.albums
    d = drawn()

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {Kati.Screens.ArtistDetailFa.chrome()}
        {Kati.Screens.ArtistDetailFa.hero(a)}
        {Kati.Screens.ArtistDetailFa.following_row(a)}
        {Fa.eyebrow(Kati.Screens.ArtistDetailFa.albums_label(albums))}
        {Kati.Screens.ArtistDetailFa.rail(albums)}
        {StatsFa.quiet_eyebrow(d.chart_label)}
        {Kati.Screens.ArtistDetailFa.chart(albums)}
        {Kati.Screens.ArtistDetailFa.unheard(assigns.release, assigns.dismissed?)}
        {StatsFa.quiet_eyebrow(d.totals_label)}
        {Kati.Screens.ArtistDetailFa.totals(a)}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The back pill, with the chevron pointing the way the reader came from.

  `arrow_forward_ios`, because back is the right edge in Persian — the commonest
  RTL bug there is, and `Kati.Screens.BookDetailFa` records the same decision
  for screen 69. `Kati.Screens.Pushed.back_pill/1` could not be used for two
  independent reasons: it takes its direction from `Kati.Locale`, which answers
  for the app rather than for this screen, and its label is an unstyled `Text`,
  which would draw آلبوم as four empty boxes.

  The parent named on the pill is the album page, which has no Persian mirror in
  the 127. That is 69's situation exactly — its own parent was inferred — and it
  costs nothing here, because the pill pops the stack rather than routing: it
  returns to whatever pushed this screen.
  """
  @spec chrome() :: map()
  def chrome do
    assigns = %{label: drawn().back}

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
          on_tap={{self(), :back}}
        >
          {UI.symbol("arrow_forward_ios", size: 17)}
          <Spacer size={6} />
          {Kati.Screens.BookDetailFa.fa(@label, 13.5, :on_surface, weight: "semibold")}
        </Row>
        <Spacer weight={1.0} />
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  The photograph, the name, and the one line under it.

  66pt at radius 33, which is what both artboards ask for — screen 77's own
  `photo/1` draws 76 and this mirror follows the drawing, as
  `Kati.Screens.ArtistDetailStates.dark_hero/1` already does.

  No `letter_spacing` on the name. Screen 77 tracks it to -0.03; Persian is a
  joined script and tracking it apart breaks the joins, which is why every
  Persian line in the drawing carries `letter-spacing:0`.
  """
  @spec hero(map()) :: map()
  def hero(a) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {Kati.Screens.ArtistDetailFa.photo(a)}
        <Spacer size={14} />
        <Column weight={1.0}>
          {Kati.Screens.BookDetailFa.fa(a.name, 22, :on_surface, weight: "bold", lines: 2)}
          <Spacer size={4} />
          {Kati.Screens.BookDetailFa.fa(a.subtitle, 12, Palette.muted())}
        </Column>
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc "The artist's photograph, or the paper disc that stands in for one."
  @spec photo(map()) :: map()
  def photo(a) do
    case Kati.Design.Images.poster(a.photo_seed) do
      nil ->
        ~MOB"""
        <Box width={66} height={66} corner_radius={33} background={Palette.placeholder()} />
        """

      src ->
        ~MOB"""
        <Image src={src} width={66} height={66} corner_radius={33} content_mode="fill" />
        """
    end
  end

  @doc """
  The one control on the page, with the sentence that says what it turns on.

  `Kati.Screens.BookDetailFa.row/5` draws this row everywhere else in the
  mirror and is not used here for one reason: it pins a sub-line at one line,
  and this one runs to two on the device — which is why screen 77 passes
  `lines: 2` to `Kati.UI.SettingsList.body/3` for the same sentence. Everything
  that carries no text is still the shared control: the card, the row, the paper
  tile and the switch.

  The sub-line is not decoration. A switch whose consequence is invisible has to
  be tested to be understood, and the thing being tested is a notification.
  """
  @spec following_row(map()) :: map()
  def following_row(a) do
    body =
      body_column(
        BookDetailFa.fa("پیگیری می‌کنم", 13, :on_surface, weight: "semibold"),
        BookDetailFa.fa(a.following_note, 11.5, Palette.sub(), lines: 2)
      )

    row =
      SettingsList.row(
        SettingsList.icon_tile("notifications"),
        body,
        SettingsList.trailing(SettingsList.switch(a.following)),
        on_tap: {self(), :toggle_following}
      )

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card([row])}
      <Spacer size={24} />
    </Column>
    """
  end

  # A title over a sub-line, in the geometry `Kati.UI.SettingsList.body/3` uses
  # — 3dp between them — with both `Text` nodes supplied by the caller so they
  # can carry Vazirmatn.
  defp body_column(title, sub) do
    assigns = %{title: title, sub: sub}

    ~MOB"""
    <Column fill_width={true}>
      {@title}
      <Spacer size={3} />
      {@sub}
    </Column>
    """
  end

  @doc """
  The albums eyebrow, carrying the untruncated count.

  Recomposed from the two functions screen 77 makes it out of — what the cap
  kept plus what it dropped — because `Kati.Screens.ArtistDetail.albums_label/0`
  hands back a finished English string and a mirror that parsed a number out of
  a sentence would break the first time the sentence changed.
  """
  @spec albums_label([map()]) :: String.t()
  def albums_label(albums) do
    total = length(albums) + ArtistDetail.truncated()

    drawn().albums_label <> " · " <> Shamsi.fa(total)
  end

  @doc """
  The album rail: art, title, and the year and play count under it.

  Three cells laid out by `Kati.UI.even_row/2`, so the width divides whatever
  the device has rather than the drawing's 402. A `Row` does not wrap, so the
  column count is declared; the fourth album is the one the frame cuts off, and
  the chart below carries it.
  """
  @spec rail([map()]) :: map()
  def rail(albums) do
    grid =
      albums
      |> Enum.take(@tiles)
      |> Enum.map(&tile/1)
      |> UI.even_row(columns: @tiles, gap: 12)

    ~MOB"""
    <Column fill_width={true}>
      {grid}
      <Spacer size={24} />
    </Column>
    """
  end

  # One tile. The artwork is drawn in the order the list gives it and is not
  # mirrored in itself — a photograph has no reading direction — so all that
  # moves is which end of the row it starts from.
  defp tile(album) do
    assigns = %{
      art: tile_art(album),
      title: BookDetailFa.fa(album.title, 12, :on_surface, weight: "bold"),
      line: BookDetailFa.fa(tile_line(album), 10, Palette.muted())
    }

    ~MOB"""
    <Column fill_width={true}>
      {@art}
      <Spacer size={9} />
      {@title}
      <Spacer size={3} />
      {@line}
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
          shadow={Kati.Theme.shadow_card()}
        />
        """

      src ->
        ~MOB"""
        <Image src={src} fill_width={true} height={side} corner_radius={12} content_mode="fill" />
        """
    end
  end

  # `۲۰۲۵ · ۴۱`. The drawing drops the word screen 77's own line carries —
  # `41 plays` becomes ۴۱ — because the tile is 112 wide and a Persian noun
  # after the numeral would ellipsise the numeral with it.
  defp tile_line(%{year: nil, plays: plays}), do: Shamsi.fa(plays)
  defp tile_line(%{year: year, plays: plays}), do: "#{Shamsi.fa(year)} · #{Shamsi.fa(plays)}"

  @doc """
  Plays by album, as bars that fill from the right.

  Scaled against the loudest album rather than a round number, which is
  `Kati.Screens.ArtistDetail.chart/0`'s decision and has to stay the same one:
  the question a chart like this answers is *which of these did I actually
  play*, and two drawings of one chart that disagreed about their axis would not
  be one chart.
  """
  @spec chart([map()]) :: map()
  def chart(albums) do
    top = albums |> Enum.map(& &1.plays) |> Enum.max(fn -> 0 end)

    bars =
      albums
      |> Enum.with_index()
      |> Enum.map(fn {album, rank} -> bar(album, top, rank) end)
      |> Enum.intersperse(~MOB"<Spacer size={13} />")

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        padding={17}
        shadow={Kati.Theme.shadow_card()}
      >
        {bars}
        {Kati.Screens.ArtistDetailFa.truncation(Kati.Screens.ArtistDetail.truncated())}
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  # One row: an 88pt label gutter, the rail, and the count in a 22pt column.
  # Both ends are columns of declared width because a `Text` carrying a
  # `text_align` is stretched to its parent's width by the bridge, so a gutter
  # that measured its own content would collapse the row it sits in.
  defp bar(album, top, rank) do
    fraction = if top > 0, do: album.plays / top, else: 0.0

    rail =
      Kati.Components.MishkaProgress.progress(
        render: :box,
        value: fraction,
        max: 1,
        height: 8,
        corner_radius: 4,
        color: tone(rank),
        track_color: Palette.paper()
      )

    assigns = %{
      title: BookDetailFa.fa(album.title, 11.5, :on_surface, weight: "semibold"),
      value: BookDetailFa.fa(Shamsi.fa(album.plays), 11, Palette.muted(), align: "absolute_left"),
      rail: rail
    }

    ~MOB"""
    <Row fill_width={true} align="center">
      <Column width={88}>
        {@title}
      </Column>
      <Spacer size={12} />
      <Column weight={1.0}>
        {@rail}
      </Column>
      <Spacer size={12} />
      <Column width={22}>
        {@value}
      </Column>
    </Row>
    """
  end

  # Screen 07's genre ramp, tokenised. `ink_soft` stands where the drawing
  # writes `#4A443B` — see the moduledoc for the eighteen units and why
  # `cream_body`, which carries the value exactly, would be the worse answer.
  defp tone(0), do: Palette.ink()
  defp tone(1), do: Palette.ink_soft()
  defp tone(2), do: Palette.bar_ink()
  defp tone(_rank), do: Palette.tertiary()

  @doc """
  The line that says a chart is not the whole story, or nothing.

  Drawn only when the cap actually dropped something. A chart captioned *and 0
  more* is worse than an uncaptioned one, which is screen 77's own rule for the
  same line.
  """
  @spec truncation(non_neg_integer()) :: map() | []
  def truncation(0), do: []

  def truncation(more) do
    label = "و " <> Shamsi.fa(more) <> " " <> drawn().albums_unit <> " دیگر"
    assigns = %{label: BookDetailFa.fa(label, 10.5, Palette.tertiary())}

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={11} />
      {@label}
    </Column>
    """
  end

  @doc """
  The unheard-release card — the one orange thing on the page.

  Orange appears exactly once here, as it does on screen 77, and it is doing
  real work rather than decorating: this card is the only thing on the page that
  is *new*. It gets the accent dash on its eyebrow and the accent dot inside it,
  and every other section on the board takes the grey dash.

  Two controls of different weight, as the drawing ranks them: یادآوری کن arms
  something and takes the ink; رد کن takes the card away and sits on the lifted
  white patch the cream card gives a secondary control.
  """
  @spec unheard(map() | nil, boolean()) :: map() | []
  def unheard(_release, true), do: []
  def unheard(nil, _dismissed?), do: []

  def unheard(release, false) do
    d = drawn()

    assigns = %{
      eyebrow: Fa.eyebrow(d.unheard_label),
      badge: BookDetailFa.fa(d.unheard_badge, 10.5, Palette.cream_meta(), weight: "semibold"),
      title: BookDetailFa.fa(release.title, 16, Palette.cream_ink(), weight: "bold"),
      line: BookDetailFa.fa(release.line, 12, Palette.cream_sub()),
      remind: pill(d.remind, Palette.ink_fill(), Palette.on_ink(), :remind_me),
      dismiss: pill(d.dismiss, Palette.cream_raise(), Palette.cream_sub(), :dismiss_release)
    }

    ~MOB"""
    <Column fill_width={true}>
      {@eyebrow}
      <Column fill_width={true} background={Palette.cream()} corner_radius={22} padding={17}>
        <Row fill_width={true} align="center">
          <Box width={7} height={7} corner_radius={4} background={Palette.accent()} />
          <Spacer size={12} />
          {@badge}
        </Row>
        <Spacer size={11} />
        {@title}
        <Spacer size={5} />
        {@line}
        <Spacer size={14} />
        <Row fill_width={true} align="center">
          {@remind}
          <Spacer size={8} />
          {@dismiss}
          <Spacer weight={1.0} />
        </Row>
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  # A 34pt pill. `Kati.UI.chip/2` draws this shape and cannot draw it here:
  # `MishkaChip` takes its label as a prop and paints it in the chip's own
  # family, and `expand/3` discards children, so a Persian label through that
  # door is a row of boxes. `Kati.Screens.Fa`'s moduledoc names a content slot on
  # those three components as the single upstream ask; until it lands this is
  # the same geometry with its own `Text`, as screens 69 and 72 do.
  defp pill(label, background, colour, tag) do
    assigns = %{
      background: background,
      label: BookDetailFa.fa(label, 11.5, colour, weight: "semibold"),
      tap: {self(), tag}
    }

    ~MOB"""
    <Row
      height={34}
      corner_radius={17}
      background={@background}
      padding_left={14}
      padding_right={14}
      align="center"
      on_tap={@tap}
    >
      {@label}
    </Row>
    """
  end

  @doc """
  Three figures, with the unit moved out of the number and into the label.

  Screen 77 sets these as `61h` over `LISTENED`; the drawing sets ۶۱ over ساعت,
  which is the better shape in a script with no case to letter-space and is why
  `Kati.Screens.AlbumDetail.stat_tile/2` — mono, uppercased, label first — is not
  called. `Kati.Screens.StatsFa.count_card/2` is the same tile at the stats
  screen's own sizes; this one keeps the artboard's 22 over 10.5 in an 18pt card.
  """
  @spec totals(map()) :: map()
  def totals(a) do
    d = drawn()

    grid =
      [
        stat_tile(a.hours, d.hours_unit),
        stat_tile(a.first_heard, d.first_unit),
        stat_tile(a.album_count, d.albums_unit)
      ]
      |> UI.even_row(columns: 3, gap: 12)

    assigns = %{grid: grid}

    ~MOB"""
    <Column fill_width={true}>
      {@grid}
    </Column>
    """
  end

  # The drawing tracks the figure to -.03em and this does not. Persian digits
  # are absent from the mono face and render through a fallback; tracking
  # mis-measures that fallback run, far enough that `max_lines={1}` has been seen
  # to ellipsise the number itself. Screen 61 carries the same note.
  defp stat_tile(value, label) do
    assigns = %{
      value: BookDetailFa.fa(value, 22, :on_surface, weight: "medium"),
      label: BookDetailFa.fa(label, 10.5, Palette.muted(), weight: "semibold")
    }

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={18}
      padding={14}
      shadow={Kati.Theme.shadow_card()}
    >
      {@value}
      <Spacer size={5} />
      {@label}
    </Column>
    """
  end

  # `61h` carries its unit inside the string, and this tile wants the two apart.
  # The number is taken back out of screen 77's label rather than recomputed,
  # because recomputing needs the minutes and `Kati.Screens.ArtistDetail`'s own
  # `shape_album/1` leaves that field at zero — a second sum here would quietly
  # disagree with the English page.
  defp hours(nil), do: "—"
  defp hours(label), do: label |> String.trim_trailing("h") |> Shamsi.to_persian_digits()

  # The drawing's year, converted; a stored year, only digited. See the
  # moduledoc — a Gregorian year alone straddles two Shamsi years.
  defp first_heard(nil) do
    @first_heard_on |> Shamsi.from_gregorian() |> elem(0) |> Shamsi.fa()
  end

  defp first_heard(year), do: Shamsi.to_persian_digits(year)

  def handle_info({:tap, :back}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}

  # The write is screen 77's, called rather than copied. `handle_tap/2` flips the
  # assign it is given and writes the artist through when there is one to write
  # to, so following somebody from the mirror and from the English page are the
  # same act — and the toggle still moves on a device with nothing shelved,
  # which is where a control that looked broken would be least explicable.
  def handle_info({:tap, :toggle_following}, socket),
    do: ArtistDetail.handle_tap(:toggle_following, socket)

  # A push, not a `reset_to`. Screen 61 records what the second kind costs — the
  # dock's tabs replaced the root and carried the reader out of Persian with no
  # way back — and a push is the recoverable kind: the Persian screen stays on
  # the stack and the back pill returns to it. Screen 69 pushes the English
  # rating sheet on the same reasoning, there being no mirror of it either.
  def handle_info({:tap, :remind_me}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.ReleaseWatcher)}

  # `رد کن` takes the card off this render and writes nothing. *Unheard* is
  # derived from a play count, so there is nothing to set; a dismissal that
  # outlived the session would need a column of its own, and one release
  # dismissed on one page does not earn one. The card comes back next time,
  # which is correct — the record is still unheard.
  def handle_info({:tap, :dismiss_release}, socket),
    do: {:noreply, Mob.Socket.assign(socket, :dismissed?, true)}

  def handle_info({:tap, _tag}, socket), do: {:noreply, socket}
  def handle_info(_message, socket), do: {:noreply, socket}
end
