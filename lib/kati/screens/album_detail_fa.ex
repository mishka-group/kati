defmodule Kati.Screens.AlbumDetailFa do
  @moduledoc """
  Screen 76 — آلبوم, the Persian album page, pushed under کتابخانه.

  Screen 74 in the mirror. The caption pins three things, and all three are
  about what refuses to turn round.

  ## Three things that do not mirror, and one that does

    * **The album art never mirrors.** The square is 74's square, unchanged
      down to the letter in it: `T` for *Tidal Works*, and the Latin word
      `Art` under it. `Kati.Screens.AlbumDetailFa.own/1` therefore takes
      `initial` from the album rather than from the Persian copy — a cover is
      not translated, and a placeholder standing in for a cover is not
      translated either. That is why `initial` and `art_seed` come through
      `Kati.Screens.AlbumDetail`'s own reader and never appear in `drawn/0`.

    * **Neither do the stars.** `Kati.Screens.BookDetail.stars/1` unchanged,
      for the reason screen 69 records: a five-star row read right to left puts
      the filled stars at the wrong end of the scale, and a rating is a
      quantity rather than a sentence.

    * **The tracklist keeps index, duration and play count in Persian digits so
      all three columns still align** — the rule screen 58 set for episode
      numbers. `Kati.Screens.Fa`'s moduledoc has the finding behind it:
      `kati_mono.ttf` carries none of U+06F0–U+06F9 and Vazirmatn carries all
      ten, so anything the design sets in mono is set here in `fa` at the
      design's size and colour. The face is wrong and the glyphs are right.

    * **The pixel field does mirror, and for free.** The caption asks for the
      year to start in the *top-right* corner, as screen 61 specifies. A `Row`
      lays out start-to-end and `Kati.Screens.Fa.pushed_frame/1` declares `rtl`
      on the root, so `Kati.Screens.AlbumDetail.field_rows/0` — ninety-one
      cells and not one string — is reused verbatim and lands the first day of
      the year at the right. Nothing here reverses a list by hand.

  ## Why the frame is `Kati.Screens.Fa.pushed_frame/1` and not `Kati.Screens.Pushed`

  `Kati.Screens.Pushed.chrome/2` takes its direction from
  `Kati.Locale.direction_prop/0` — the app *setting* — and the bridge reads
  `layout_direction` from the root node only. A Persian mirror rendered while
  the app is still set to English would draw Persian copy in a left-to-right
  grid, which is the one thing these drawings exist to disprove. Its
  `back_pill/1` is unusable here for a second reason on top of that: it points
  `arrow_back_ios_new` and builds an unstyled `Text`, so the label would be a
  row of empty boxes pointing the wrong way. `Kati.Screens.BookDetailFa.chrome/0`
  is the pill 76 draws — `arrow_forward_ios`, because back is the way the
  reader came from and in Persian that is the right edge — and its label is
  already کتابخانه, so it is reused rather than re-typed.

  ## Where this file disagrees with `Kati.Screens.AlbumDetail`

  Reuse is the rule: `album/0`, `tracks/0`, `field_rows/0` and `stars/1` are
  74's, so the two pages cannot disagree about the record. But in six places
  74's *module* and 76's *frame* draw different things, and each time the frame
  wins — because the frame is the thing being reproduced, and every number
  below is also in `.scratch/design/screens/74.html`, which is 74's own
  capture. The drift is 74's to settle; the mirror is not inventing a second
  album page.

    * **The art.** 74 draws an 86pt tile beside the title. Both frames draw a
      full-bleed square above it, at `aspect_ratio` 1 with a 2pt card-white
      border and the initial at 64.
    * **The rating.** 74 puts it in a third stat tile. Both frames give it its
      own eyebrow — امتیاز شما — and its own 20-radius card.
    * **The actions.** 74 draws 44pt discs with the label beneath. Both frames
      draw two 54pt cards at radius 20 with the glyph over the label.
    * **The artist tile.** 74 uses `Kati.UI.SettingsList.icon_tile/1`, which is
      30pt at radius 9. Both frames draw 40 at radius 12 with a 19pt glyph, so
      the tile here is `Kati.Components.MishkaThemeIcon` at the frame's size —
      the same component `icon_tile/1` is, given the drawing's numbers.
    * **The dot.** 74 puts it in the trailing group at 5pt. Both frames put it
      between the index and the title at 7pt, which is also where it belongs:
      it qualifies the track, not the count.
    * **The `info` gloss.** 74's frame carries a line explaining the dot; 76's
      does not, and 76 draws exactly five Material Symbols with `info` not
      among them. So `Kati.Screens.AlbumDetail.dot_note/0` is deliberately not
      called and the dot goes unglossed in Persian. That is a real gap rather
      than a decision, and it is named here instead of being papered over with
      a sixth glyph the drawing does not have.

  ## The one artboard literal this screen does not reproduce

  Both frames dot track **۳**, سیاه‌خار. `Kati.Music.Sample` dots track **۱**,
  آب کم. This file takes the fixture's answer, because the dot means *played
  today* about an album both pages are showing: a mirror that disagreed with
  its original about which track played today would be a bug in the mirror, not
  a translation of it. Moving the dot is `Kati.Music.Sample`'s to move.

  ## The copy is a proposal, and the six unnamed tracks doubly so

  Screen 72's caption states the rule for all Persian copy on these mirrors:
  *these strings are proposals*. Five track titles are the drawing's own; the
  other six are named here because `Kati.Music.Sample` is explicit that a
  tracklist with holes in it is not a tracklist, and those six have never been
  drawn in Persian at all. A native reader correcting one corrects it once, in
  `titles/0`.
  """

  use Mob.Screen
  import Mob.Sigil

  alias Kati.I18n.Digits
  alias Kati.Screens.AlbumDetail
  alias Kati.Screens.Fa
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  # Everything the drawing prints that is a WORD rather than a fact about the
  # record. Facts — the initial, the artwork seed, the ten-point rating — come
  # from `Kati.Screens.AlbumDetail` so the two pages read one album; see
  # `own/1`.
  @drawn %{
    title: "کارهای جزر و مد",
    byline: "کل اوستراند · ۲۰۲۵",
    artist: "کل اوستراند",
    artist_line: "۴ آلبوم · ۶۱ ساعت",
    first_heard: "۱۳ اسفند ۱۴۰۲",
    last_played: "دیروز",
    month: "اردیبهشت",
    plays_line: "۴۱ پخش",
    note: "سه‌شنبه بارانی در استودیو پیدایش کردم. آهنگ سوم را بی‌وقفه تکرار کردم.",
    note_on: "۱۳ اسفند ۱۴۰۲"
  }

  @labels %{
    first_heard: "اولین شنیدن",
    last_played: "آخرین پخش",
    rating: "امتیاز شما",
    history: "تاریخچه شنیدن · ۱۳ هفته",
    note: "یادداشت شما",
    primary: "ثبت شنیدن",
    rate: "امتیاز",
    list: "فهرست"
  }

  # Keyed by position rather than listed, because the position is what survives
  # a shelved album replacing the fixture: `translated/1` looks a title up and
  # leaves the row alone when it finds nothing.
  @titles %{
    1 => "آب کم",
    2 => "برداشت",
    3 => "سیاه‌خار",
    4 => "فصل گودال",
    5 => "آنچه جزر باقی گذاشت",
    6 => "شوره‌زار",
    7 => "خط جلبک",
    8 => "خلیجک",
    9 => "بازه بلند",
    10 => "کشند بزرگ",
    11 => "دفتر کل"
  }

  # The Persian decimal separator is U+066B, not the ASCII dot.
  # `Kati.I18n.Digits.to_persian/1` deliberately leaves separators alone — its
  # own moduledoc says which separator a number wants is a formatting decision
  # and not a character map's business — so the screen makes it, once.
  @decimal "٫"

  def mount(_params, _session, socket) do
    Kati.Theme.activate()
    {:ok, Mob.Socket.assign(socket, :album, album())}
  end

  def render(assigns), do: Fa.pushed_frame(content(assigns))

  @doc """
  The album this screen is about: the shelf's, in Persian chrome, or the
  drawing's.

  `Kati.Screens.BookDetailFa`'s doctrine, applied to a record: one album, read
  once, presented twice. `Kati.Screens.AlbumDetail` does the reading — four Ash
  queries it already owns — and what this screen supplies is the Persian half:
  the eyebrows, the row labels, the Shamsi dates. What it does **not** supply
  is a translation. A shelved album keeps its own title, its own artist and its
  own note, because those are the user's and nothing in `Kati.Music` translates
  anything.
  """
  @spec album() :: map()
  def album do
    case AlbumDetail.shelved_album() do
      nil -> Map.merge(drawn(), own(AlbumDetail.drawn_album()))
      shelved -> Map.merge(drawn(), Map.merge(own(shelved), words(shelved)))
    end
  end

  @doc "The drawing's Persian copy, unconditionally."
  @spec drawn() :: map()
  def drawn, do: @drawn

  @doc """
  The parts of an album that are not words, and so are the same in both
  languages.

  Three of them. `initial` and `art_seed` are the square, which never mirrors —
  see the moduledoc. `rating` is a number out of ten that
  `Kati.Screens.BookDetail.stars/1` turns into glyphs, and `rating_label` is
  that number spelled out, so it is *derived* here rather than frozen into
  `drawn/0`: `4.5` folds to `۴٫۵`, which is exactly what the frame prints, and
  it goes on being right for an album the frame never saw.
  """
  @spec own(map()) :: map()
  def own(album) do
    %{
      initial: album.initial,
      art_seed: album.art_seed,
      rating: album.rating,
      rating_label: persian_decimal(album.rating_label)
    }
  end

  @doc """
  The parts of a shelved album that are the user's rather than the chrome's.

  Deliberately short, and shorter than `Kati.Screens.BookDetailFa.own/1` by one
  kind of field: the dates are not here. A shelved album's `first_heard` and
  `last_played` arrive as `Date` structs wanting a Shamsi rendering, and
  shaping a date belongs in `Kati.Music` next to the Gregorian shaping
  `Kati.Screens.AlbumDetail.shaped/4` already does — not on a screen. Until it
  moves there, the two dates are the drawing's.
  """
  @spec words(map()) :: map()
  def words(shelved) do
    %{
      title: shelved.title,
      byline: shelved.byline,
      artist: shelved.artist,
      note: shelved.note
    }
  end

  @doc "The row labels, the two eyebrows that are not built from a count, and the three button captions."
  @spec labels() :: %{atom() => String.t()}
  def labels, do: @labels

  @doc "The Persian names for the eleven tracks, by position. Proposals — see the moduledoc."
  @spec titles() :: %{pos_integer() => String.t()}
  def titles, do: @titles

  @doc """
  The tracklist, in running order, with Persian titles only when the fixture is
  the album.

  `Kati.Screens.AlbumDetail.tracks/0` answers with position, duration, plays
  and the today-dot; those are facts about the record and are taken as they
  come. The title is the one field that is a word, and a real album's titles
  are the user's — nothing translates them. So the swap happens only in the
  branch where there is nothing shelved and the album on the page is the one
  the frame was captured from.
  """
  @spec tracks() :: [map()]
  def tracks do
    case AlbumDetail.shelved_album() do
      nil -> Enum.map(AlbumDetail.tracks(), &Kati.Screens.AlbumDetailFa.translated/1)
      _shelved -> AlbumDetail.tracks()
    end
  end

  @doc "One track row with its drawn Persian title, or untouched when there is no name for that position."
  @spec translated(map()) :: map()
  def translated(track), do: %{track | title: Map.get(@titles, track.position, track.title)}

  @doc """
  The tracklist eyebrow, which carries the real count.

  `فهرست آهنگ‌ها · ۱۱ آهنگ`, and unlike
  `Kati.Screens.AlbumDetail.tracklist_label/0` there is no singular branch to
  write: a Persian noun after a number does not inflect, so `۱ آهنگ` and
  `۱۱ آهنگ` take the same word. The count still has to follow the tracklist,
  which is why this is built rather than frozen.
  """
  @spec tracklist_label() :: String.t()
  def tracklist_label do
    "فهرست آهنگ‌ها · " <> Digits.to_persian(length(tracks())) <> " آهنگ"
  end

  # `4.5` → `۴٫۵`. Nil passes through so an unrated album draws the em dash the
  # rating card falls back to rather than the string "nil".
  defp persian_decimal(nil), do: nil

  defp persian_decimal(label) when is_binary(label),
    do: label |> Digits.to_persian() |> String.replace(".", @decimal)

  @doc "The page, in the order 76 stacks it."
  @spec content(map()) :: map()
  def content(assigns) do
    a = assigns.album
    l = labels()

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {Kati.Screens.BookDetailFa.chrome()}
        {Kati.Screens.AlbumDetailFa.art(a)}
        {Kati.Screens.BookDetailFa.title(%{title: a.title, author: a.byline})}
        {Kati.Screens.AlbumDetailFa.artist_row(a)}
        {Kati.Screens.AlbumDetailFa.dates(a)}
        {Kati.Screens.AlbumDetailFa.eyebrow(l.rating, :accent)}
        {Kati.Screens.AlbumDetailFa.rating(a)}
        {Kati.Screens.AlbumDetailFa.eyebrow(Kati.Screens.AlbumDetailFa.tracklist_label(), :accent)}
        {Kati.Screens.AlbumDetailFa.tracklist()}
        {Kati.Screens.AlbumDetailFa.eyebrow(l.history, :grey)}
        {Kati.Screens.AlbumDetailFa.history(a)}
        {Kati.Screens.AlbumDetailFa.note(a)}
        {Kati.Screens.AlbumDetailFa.actions()}
      </Column>
    </Scroll>
    """
  end

  @doc """
  A Persian eyebrow whose dash is not always the accent.

  76 draws four and colours two of them `#C4BDB3`: orange means new or now in
  this design, and neither the thirteen-week history nor a note the reader
  wrote themselves is either. `Kati.UI.eyebrow/2` has taken a `:dash` option
  since three Latin screens needed exactly this, and
  `Kati.Screens.Fa.eyebrow/1` has not — so the accent case delegates to it
  unchanged and only the grey case is spelled out here. That is the whole
  difference between the two clauses: same 13x2 dash, same Vazirmatn 11 at 600
  with no tracking, because the Arabic script has no case to upper.
  """
  @spec eyebrow(String.t(), :accent | :grey) :: map()
  def eyebrow(label, :accent), do: Fa.eyebrow(label)

  def eyebrow(label, :grey) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        <Box width={13} height={2} corner_radius={1} background={Palette.rail_idle()} />
        <Spacer size={9} />
        <Text
          text={label}
          font_family="fa"
          font_weight="semibold"
          text_size={11}
          text_color={Palette.eyebrow()}
        />
      </Row>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc """
  The full-bleed album square, drawn with no artwork on purpose.

  Screen 74's caption is the authority and it applies unchanged: *drawn in its
  default state — no art, since Cover Art Archive coverage is patchy — a paper
  square carrying the album initial and the "Art" placeholder rather than a
  broken image.* So the placeholder is the default rendering and not an error
  path.

  `aspect_ratio={1.0}` under `fill_width`, which is the drawing's own
  `aspect-ratio:1` rather than a height guessed from a 402pt frame — the idiom
  `Kati.Screens.MealsMatrixFa` already uses for its cells. The 2pt border is
  card white, so the square reads as a print laid on the page rather than as a
  hole cut in it.
  """
  @spec art(map()) :: map()
  def art(a) do
    ~MOB"""
    <Column fill_width={true}>
      <Box
        fill_width={true}
        aspect_ratio={1.0}
        corner_radius={14}
        background={Palette.placeholder()}
        border_color={Palette.card()}
        border_width={2}
        shadow={Kati.Theme.shadow_poster()}
      >
        {Kati.Screens.AlbumDetailFa.art_face(a)}
      </Box>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc """
  What sits inside the square: a letter and a caption, or a cover.

  Two aligned `Box` layers rather than one `Column`, because the drawing pins
  the caption to the bottom edge and centres the letter in the whole square —
  a column would centre the pair and leave the letter riding high. Both stay
  Latin: `T` is the album's initial and `Art` is the placeholder's own word,
  and the caption's first clause is that album art never mirrors.
  """
  @spec art_face(map()) :: map()
  def art_face(%{art_seed: nil} = a) do
    assigns = %{initial: a.initial}

    ~MOB"""
    <Box fill_width={true} fill_height={true}>
      <Box fill_width={true} fill_height={true} align="center">
        <Text
          text={@initial}
          font_family="mono"
          text_size={64}
          font_weight="medium"
          text_color={Palette.rail_idle()}
          max_lines={1}
        />
      </Box>
      <Box fill_width={true} fill_height={true} align="bottom" padding_bottom={12}>
        <Text
          text="Art"
          font_family="mono"
          text_size={9.5}
          letter_spacing={0.14}
          text_align="center"
          text_color={Palette.tertiary()}
        />
      </Box>
    </Box>
    """
  end

  def art_face(a) do
    case Kati.Design.Images.poster(a.art_seed) do
      nil ->
        art_face(%{a | art_seed: nil})

      src ->
        ~MOB"""
        <Image src={src} fill_width={true} fill_height={true} content_mode="fill" />
        """
    end
  end

  @doc """
  The artist row, which pushes screen 77, or nothing when the album has no
  artist.

  `chevron_left` and not `chevron_right`: a row that opens something opens it
  in the reading direction, and in Persian that is leftward. The same reasoning
  as the back pill's chevron, in the other direction —
  `Kati.Screens.BookDetailFa.series/1` records it for screen 69.
  """
  @spec artist_row(map()) :: map() | []
  def artist_row(%{artist: nil}), do: []

  def artist_row(a) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card([
        Kati.UI.SettingsList.row(
          Kati.Screens.AlbumDetailFa.artist_tile(),
          Kati.Screens.AlbumDetailFa.artist_body(a),
          Kati.UI.SettingsList.trailing(
            Kati.UI.symbol("chevron_left", size: 18, color: Palette.rail_idle())
          ),
          padding: 11,
          rule: false,
          on_tap: {self(), :open_artist}
        )
      ])}
      <Spacer size={11} />
    </Column>
    """
  end

  @doc """
  The 40pt person tile, which is `Kati.UI.SettingsList.icon_tile/1` at the
  drawing's size.

  Not a call to that function, because it is 30 at radius 9 with a 17pt glyph
  and both frames draw 40 at radius 12 with 19 — see the moduledoc. It is the
  same component underneath and for the same reason: `MishkaThemeIcon` is "a
  themed container around exactly one icon", and the glyph goes in as a child
  so `Kati.UI.symbol/2` keeps the symbols face and `Kati.Icons.glyph!/1` keeps
  its raise for a name outside the shipped subset.
  """
  @spec artist_tile() :: map()
  def artist_tile do
    Kati.Components.MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Palette.paper(), size: 40, radius: 12},
      [UI.symbol("person", size: 19, color: Palette.ink_soft())]
    )
  end

  @doc "The artist's name over the two totals the row exists to carry."
  @spec artist_body(map()) :: map()
  def artist_body(a) do
    assigns = %{a: a}

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.BookDetailFa.fa(@a.artist, 13, :on_surface, weight: "semibold")}
      <Spacer size={3} />
      {Kati.Screens.BookDetailFa.fa(@a.artist_line, 11.5, Palette.sub())}
    </Column>
    """
  end

  @doc """
  Two dates side by side, in screen 07's stat-trio typography with two tiles.

  Two and not three: the rating that 74's module puts in a third tile has its
  own eyebrow and its own card in both frames, which is what
  `Kati.Screens.AlbumDetailFa.rating/1` draws. The alignment the trio
  typography exists for survives, because the two tiles that remain are still
  a weighted pair splitting the same width.
  """
  @spec dates(map()) :: map()
  def dates(a) do
    l = labels()

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column weight={1.0}>
          {Kati.Screens.AlbumDetailFa.stat_tile(l.first_heard, a.first_heard)}
        </Column>
        <Spacer size={12} />
        <Column weight={1.0}>
          {Kati.Screens.AlbumDetailFa.stat_tile(l.last_played, a.last_played)}
        </Column>
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  One labelled fact.

  The label is Vazirmatn 10.5 at 600 where the Latin tile sets DM Mono 9.5
  uppercase at .1em tracking, and the value is Vazirmatn 14 at 500 where the
  Latin sets mono: both are `Kati.Screens.Fa`'s standing trade, taken because
  the mono subset has no Persian digits and because the Arabic script has no
  case to upper.
  """
  @spec stat_tile(String.t(), String.t() | nil) :: map()
  def stat_tile(label, value) do
    assigns = %{label: label, value: value || "—"}

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={18}
      padding={14}
      shadow={Kati.Theme.shadow_card_soft()}
    >
      {Kati.Screens.BookDetailFa.fa(@label, 10.5, Palette.muted(), weight: "semibold")}
      <Spacer size={7} />
      {Kati.Screens.BookDetailFa.fa(@value, 14, :on_surface, weight: "medium")}
    </Column>
    """
  end

  @doc """
  Four stars and a half, and the row holds its direction.

  `Kati.Screens.BookDetail.stars/1` unchanged, which draws whole stars from a
  ten-point scale: `۹` is four solid glyphs, and the `۴٫۵` beside them is where
  the half is said. Reading the row right to left would put the filled end of
  the scale on the wrong side of it.
  """
  @spec rating(map()) :: map()
  def rating(a) do
    assigns = %{a: a}

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        padding={15}
        shadow={Kati.Theme.shadow_card_soft()}
      >
        <Row fill_width={true} align="center">
          {Kati.Screens.BookDetail.stars(@a.rating)}
          <Spacer size={12} />
          {Kati.Screens.BookDetailFa.fa(@a.rating_label || "—", 14, :on_surface)}
        </Row>
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc "The tracklist, in running order, with no hairline under the last row."
  @spec tracklist() :: map()
  def tracklist do
    all = tracks()
    last = length(all)

    rows =
      all
      |> Enum.with_index(1)
      |> Enum.map(fn {track, index} ->
        Kati.Screens.AlbumDetailFa.track_row(track, index == last)
      end)

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card(rows)}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  One track: number, dot, title, duration, plays.

  `Kati.UI.SettingsList.row/4` supplies the geometry and the hairline, and the
  dot rides in the **leading** group rather than the trailing one — beside the
  index, where both frames put it. That is also where it means what it says:
  the dot qualifies the track, not the play count it would otherwise sit
  against.
  """
  @spec track_row(map(), boolean()) :: map()
  def track_row(track, last?) do
    SettingsList.row(
      Kati.Screens.AlbumDetailFa.track_index(track),
      Kati.Screens.AlbumDetailFa.track_body(track),
      SettingsList.trailing(Kati.Screens.AlbumDetailFa.track_plays(track)),
      padding: 12,
      rule: not last?
    )
  end

  @doc """
  The running number, and the dot when the track played today.

  One of the two `Text` nodes on this screen that does not go through
  `Kati.Screens.BookDetailFa.fa/4`, because it carries a fixed `width` that
  helper does not take — and the width is the whole point. The caption asks for
  index, duration and play count to stay aligned as columns, and a number
  column only aligns if every cell is the same width whether it holds ۱ or ۱۱.
  """
  @spec track_index(map()) :: map()
  def track_index(track) do
    assigns = %{position: Digits.to_persian(track.position), today?: track.today?}

    ~MOB"""
    <Row align="center">
      <Text
        text={@position}
        font_family="fa"
        text_size={11.5}
        text_color={Palette.tertiary()}
        width={16}
        max_lines={1}
      />
      {Kati.Screens.AlbumDetailFa.dot(@today?)}
    </Row>
    """
  end

  @doc "The today-dot, or nothing at all — `Spacer size={0}`, as screen 74 spells absence."
  @spec dot(boolean()) :: map()
  def dot(false), do: ~MOB"<Spacer size={0} />"

  def dot(true) do
    ~MOB"""
    <Row align="center">
      <Spacer size={12} />
      <Box width={7} height={7} corner_radius={4} background={Palette.accent()} />
    </Row>
    """
  end

  @doc """
  The title, which takes the width, and the duration, which does not.

  The title is wrapped in a weighted `Column` rather than given the weight
  itself, because `Kati.Screens.BookDetailFa.fa/4` sets the face, the size and
  the colour and takes no layout weight — and the face is the one thing a
  Persian title cannot be drawn without.
  """
  @spec track_body(map()) :: map()
  def track_body(track) do
    assigns = %{title: track.title, duration: Digits.to_persian(track.duration || "")}

    ~MOB"""
    <Row fill_width={true} align="center">
      <Column weight={1.0}>
        {Kati.Screens.BookDetailFa.fa(@title, 13, :on_surface, weight: "semibold")}
      </Column>
      <Spacer size={12} />
      {Kati.Screens.BookDetailFa.fa(@duration, 11, Palette.tertiary())}
    </Row>
    """
  end

  @doc """
  The play count, right-aligned in a 22pt column.

  `text_align="end"` rather than `"right"`: the bridge maps both to
  `TextAlign.End`, but only one of them says what is meant here, which is *the
  far side of the column, whichever side that is*. In Persian that is the left
  edge, which is exactly where the drawing puts it.

  A zero takes the rail grey where every other count takes ink, because zero is
  not a count — it is the absence of one, and the drawing greys it to say so.
  """
  @spec track_plays(map()) :: map()
  def track_plays(track) do
    colour = if track.plays == 0, do: Palette.rail_idle(), else: Palette.ink_soft()
    assigns = %{plays: Digits.to_persian(track.plays), colour: colour}

    ~MOB"""
    <Text
      text={@plays}
      font_family="fa"
      text_size={11}
      text_color={@colour}
      width={22}
      text_align="end"
      max_lines={1}
    />
    """
  end

  @doc """
  The thirteen-week pixel field, reused whole from screen 74.

  `Kati.Screens.AlbumDetail.field_rows/0` contains no text at all, which is the
  only reason a Persian screen can adopt it unchanged — the font rule that
  keeps this file away from most of `Kati.Components` never bites on a grid of
  coloured boxes. It chunks ninety-one cells at 27 to the row, and under the
  `rtl` root each `Row` starts at the right, so the year begins in the
  top-right corner as screen 61 specifies.

  The footer sits 8 below the field and not the drawing's 12, because
  `field_rows/0`'s last row already ends in a 4pt spacer of its own.
  """
  @spec history(map()) :: map()
  def history(a) do
    assigns = %{a: a}

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        padding={15}
        shadow={Kati.Theme.shadow_card_soft()}
      >
        {Kati.Screens.AlbumDetail.field_rows()}
        <Spacer size={8} />
        <Row fill_width={true} align="center">
          {Kati.Screens.BookDetailFa.fa(@a.month, 10, Palette.tertiary())}
          <Spacer weight={1.0} />
          {Kati.Screens.BookDetailFa.fa(@a.plays_line, 10, Palette.tertiary())}
        </Row>
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  The cream card, its eyebrow, or neither.

  Same rule as screens 08, 66 and 74: cream marks the user's own words, so an
  album nobody has written about has no warm rectangle waiting for one — and
  the eyebrow is drawn inside this function so it leaves with the card rather
  than being orphaned above nothing.

  The body is the third `Text` here that does not go through
  `Kati.Screens.BookDetailFa.fa/4`, and the reason is leading: that helper
  fixes `line_height` at 1.4 and the drawing sets this paragraph at **1.9**.
  Persian sets tall — Vazirmatn's descenders run under the line and the
  diacritics run over it — so a Persian paragraph at a Latin paragraph's
  leading collides with itself. The Latin card is drawn at 1.65.
  """
  @spec note(map()) :: map() | []
  def note(%{note: nil}), do: []

  def note(a) do
    assigns = %{a: a}

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.AlbumDetailFa.eyebrow(Kati.Screens.AlbumDetailFa.labels().note, :grey)}
      <Column fill_width={true} background={Palette.cream()} corner_radius={22} padding={17}>
        <Text
          text={@a.note}
          font_family="fa"
          text_size={13.5}
          line_height={1.9}
          text_color={Palette.cream_body()}
        />
        <Spacer size={10} />
        {Kati.Screens.BookDetailFa.fa(@a.note_on || "", 10.5, Palette.meta())}
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  One ink button and two card seconds.

  The seconds are 54pt cards at radius 20 with the glyph over the label, which
  is what both frames draw and not the 44pt discs
  `Kati.Screens.BookDetail.second/3` builds — see the moduledoc. The two glyphs
  do not mirror and do not need to: `star` and `bookmarks` are symbols, not
  sentences.
  """
  @spec actions() :: map()
  def actions do
    l = labels()

    seconds =
      [{"star", l.rate, :rate}, {"bookmarks", l.list, :add_to_list}]
      |> Enum.map(fn {icon, label, tag} ->
        Kati.Screens.AlbumDetailFa.second(icon, label, tag)
      end)
      |> Enum.intersperse(~MOB"<Spacer size={10} />")

    assigns = %{primary: l.primary, seconds: seconds}

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        height={54}
        corner_radius={27}
        background={Palette.ink_fill()}
        align="center"
        on_tap={{self(), :log_listen}}
      >
        <Spacer weight={1.0} />
        {Kati.Screens.BookDetailFa.fa(@primary, 14, Palette.on_ink(), weight: "bold")}
        <Spacer weight={1.0} />
      </Row>
      <Spacer size={11} />
      <Row fill_width={true}>
        {@seconds}
      </Row>
    </Column>
    """
  end

  @doc "One secondary action: a 54pt card holding a glyph over its Persian caption."
  @spec second(String.t(), String.t(), atom()) :: map()
  def second(icon, label, tag) do
    assigns = %{icon: icon, label: label, tap: {self(), tag}}

    ~MOB"""
    <Column
      weight={1.0}
      height={54}
      corner_radius={20}
      background={Palette.card()}
      shadow={Kati.Theme.shadow_card_soft()}
      align="center"
      on_tap={@tap}
    >
      <Spacer weight={1.0} />
      {Kati.UI.symbol(@icon, size: 19)}
      <Spacer size={3} />
      {Kati.Screens.BookDetailFa.fa(@label, 10.5, Palette.ink_soft(),
        weight: "semibold",
        align: "center"
      )}
      <Spacer weight={1.0} />
    </Column>
    """
  end

  def handle_info({:tap, :back}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}

  # The four destinations are `Kati.Screens.AlbumDetail.handle_tap/2`'s, exactly
  # — a mirror that navigated somewhere else would be a second app rather than
  # the same one in another language. Three of them are English screens, which
  # is the debt `Kati.Screens.BookDetailFa` already carries against
  # `Kati.Screens.Rating`, and `Kati.Screens.Fa`'s moduledoc names the cost: a
  # push that changes the app's language out from under the reader, and RTL with
  # it. Screen 77's Persian mirror pays down the artist row's share of it.
  def handle_info({:tap, :log_listen}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.LogListen)}

  # The Persian artist page, not the English one. A mirror that pushed its
  # LTR sibling would change the app's language out from under the reader —
  # the same failure `Kati.Screens.Fa` records for the آمار tab's stand-in.
  def handle_info({:tap, :open_artist}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.ArtistDetailFa)}

  def handle_info({:tap, :rate}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Rating)}

  def handle_info({:tap, :add_to_list}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Lists)}

  def handle_info({:tap, _tag}, socket), do: {:noreply, socket}
  def handle_info(_message, socket), do: {:noreply, socket}
end
