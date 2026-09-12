defmodule Kati.Screens.RateAlbum do
  @moduledoc """
  Screen 180 — Rate an album. Board 33's chrome in board 144's manner.

  Built to `test/design/screens/180.html`. Screen 74's **Rate** row pushed
  `Kati.Screens.Rating` until this file existed, and that sheet draws a log of
  the film *Blue Hour*: its `mount/3` reads `:tracked_title_id`, its whole path
  is a `Kati.Media.Watch` over a `Kati.Media.TrackedTitle`, and an album id put
  in that key names a row `Ash.get/2` can never find.
  `Kati.ScreenParamsSweepTest` carried that door on `@bare_pushes` with the
  reason written out: *making 33 rate a book or an album is a screen build, not
  a params fix*. This is the build for the album half.

  ## Why its own board rather than a variant of 33

  `D-39` settles it and board 73's caption settled the half of it that matters:
  *music gets no "finished" shortcut — an album has no equivalent of closing a
  book*. Music is precisely the domain whose rating sheet does not arrive from a
  progress sheet's second commit. Three of 33's bands do not survive translation
  — the rewatch pill, `Where`, `With` — and a fourth is dropped, so a "variant"
  annotation would list more removals than survivals. Board 144 is the
  precedent for exactly that: 33's chrome, a different noun, its own artboard.

  The four omissions are drawn on the board as an annotation, and this screen
  draws that annotation, because a designer coming to it later would otherwise
  assume they were forgotten.

  ## What it writes, and onto which row

  `Kati.Music.Album.rating`, `note` and `note_on` — the same note screen 74's
  cream card draws, never a second one. `Kati.Music.Album` is explicit: *one
  note per album rather than a resource — unlike a book, which is read over
  weeks and annotated at pages, an album gets the one thing you thought about
  it.* Two review fields would be two truths about one record.

  The row is the one this sheet was NAMED, pinned at mount and spent at save —
  `Kati.Screens.LogListen.mount/3`'s arrangement, and it closes the same hole:
  a sheet that re-read the shelf at save time credited whichever album had
  reached the head in between. A named id whose row has gone is `nil` from
  `Ash.get/2` and a refusal, where named-nothing is still the shelf's first and
  still correct.

  ## The rating is one column read two ways

  `Kati.Music.Album` stores `rating` as `min: 0, max: 10` and comments it
  *"Halves, as every other rating in this app is stored"*, so the `5★` / `10pt`
  toggle is a display preference over one column rather than a second store.
  It is drawn and it carries no tap, exactly as screen 33 draws it — see
  `Kati.Screens.Rating.scale/1`, whose rows have no `on_tap` either.

  The star row is `Kati.Screens.Rating.stars/2`, not a second construction. Its
  own doc gives the reason and this screen is the beneficiary: ten tap targets,
  one per point, so the half ratings a person already has stored stay
  reachable. One difference from the board is worth naming rather than
  discovering: 180's annotation says the half star is *`star` at FILL 0*, and
  the app draws a real half — fence K-16 gave the bridge `clip_width`, which
  clips the draw and leaves measurement alone, so `4.5` reads as four and a
  half rather than as five. The annotation is reproduced because it is the
  board's; `Kati.Screens.Rating`'s moduledoc carries the upgrade that overtook
  it.

  ## Two things this sheet does not own

  **Last played is read-only here.** `Kati.Screens.LogListen.save_listen/1`
  moves `last_played_on` when a play is logged, and a second writer for one
  column is two accounts of when a record was last on.

  **`104` is stored, not derived, for the drawing.** The board prints a count
  beside a body of a different length, which is a fact about the board; the
  moment a person types, the number is about them instead.
  `Kati.Rating.Sample` records the identical decision for screen 33's `184`.
  The FIGURE is what is stored and `count_label/1` words it, so the drawing's
  count is a sentence in the reader's language and digits rather than a frozen
  English one — see the attribute's own comment for why it cannot be both.
  """
  use Mob.Screen
  use Gettext, backend: Kati.Gettext
  import Mob.Sigil

  alias Kati.Components.MishkaPill
  alias Kati.Music.Album
  alias Kati.Screens.AlbumDetail
  alias Kati.Screens.Rating
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList
  alias Kati.Write

  # The board's own count, beside a body 96 characters long. See the moduledoc.
  #
  # The NUMBER is the constant and `count_label/1` does the wording, because an
  # `ngettext/4` written into a module attribute is evaluated when this module
  # is COMPILED and freezes in whichever locale the compiler happened to be in.
  # A Persian reader would then meet `104 characters` on the drawing for the
  # life of the build, on a page whose every other line had folded — which is
  # the quiet kind of failure `Kati.PersianFontTest`'s moduledoc is about.
  @drawn_characters 104

  def mount(params, _session, socket) do
    Kati.Theme.activate()
    Kati.Locale.activate()

    named = Map.get(params || %{}, :album_id)
    album = AlbumDetail.album(named)

    {:ok,
     socket
     |> Mob.Socket.assign(:album, album)
     |> Mob.Socket.assign(:album_id, named || album[:id])
     |> Mob.Socket.assign(:rating, Kati.Screens.RateAlbum.five_point(album[:rating]))
     |> Mob.Socket.assign(:note, album[:note] || "")
     |> Mob.Socket.assign(:characters, Kati.Screens.RateAlbum.characters(album))
     |> Mob.Socket.assign(:save_error, nil)}
  end

  @doc """
  The params that name an album to this sheet.

  Delegated to `Kati.Screens.AlbumDetail.params_for/1` for the reason
  `Kati.Screens.LogListen.params_for/1` delegates there: three screens now
  receive `%{album_id: id}`, and two copies of the same two clauses would be one
  rename away from a sheet writing to an album the page it opened from never
  mentioned.
  """
  @spec params_for(map() | nil) :: map()
  def params_for(album), do: AlbumDetail.params_for(album)

  @doc """
  The five-point value the star row reads, from the ten-point column.

  Halving here and doubling in `save_rating/1` keeps both conversions at the
  edges, where each is a single line, rather than letting the sheet invent a
  third scale in the middle — `Kati.Screens.Rating`'s own rule, one domain over.

      iex> Kati.Screens.RateAlbum.five_point(9)
      4.5

      iex> Kati.Screens.RateAlbum.five_point(nil)
      nil
  """
  @spec five_point(integer() | nil) :: float() | nil
  def five_point(nil), do: nil
  def five_point(rating) when is_integer(rating), do: rating / 2

  @doc """
  The ten-point integer the column stores, from the row's own five-point value.

      iex> Kati.Screens.RateAlbum.ten_point(4.5)
      9

      iex> Kati.Screens.RateAlbum.ten_point(nil)
      nil
  """
  @spec ten_point(number() | nil) :: integer() | nil
  def ten_point(nil), do: nil
  def ten_point(value), do: round(value * 2)

  @doc """
  The count under the note: the body's own for a record, the drawing's own for
  the drawing.

  Keyed on `:id` because that is the one field the drawing does not have —
  `Kati.Music.Sample.album/0` carries no `:id` and is not given a `nil` one, so
  a shaped row and a fixture are told apart by absence rather than by a flag
  somebody has to remember to set. `Kati.Screens.AlbumDetail.shaped/4` states
  the same convention from the other side.
  """
  @spec characters(map()) :: String.t()
  def characters(%{id: id, note: note}) when is_binary(id) and is_binary(note),
    do: Kati.Screens.RateAlbum.characters_label(note)

  def characters(%{id: id}) when is_binary(id),
    do: Kati.Screens.RateAlbum.count_label(0)

  def characters(_album), do: Kati.Screens.RateAlbum.count_label(@drawn_characters)

  @doc """
  The count of a body somebody typed.

      iex> Kati.Screens.RateAlbum.characters_label("hello")
      "5 characters"

      iex> Kati.Screens.RateAlbum.characters_label("x")
      "1 character"
  """
  @spec characters_label(String.t()) :: String.t()
  def characters_label(text) when is_binary(text),
    do: Kati.Screens.RateAlbum.count_label(String.length(text))

  # The count worded, and the one place this sheet says `character` at all —
  # `characters/1`'s three branches all arrive here, so the drawing's 104, an
  # empty field's 0 and a typed body's own figure are one sentence rather than
  # three.
  #
  # `ngettext/4` rather than the `1` / `n` case this had: English needs the
  # singular and Persian does not inflect a noun after a numeral — ۱ نویسه and
  # ۱۰۴ نویسه are both right — so its two forms are the same word. Screen 33's
  # own msgid, not a second one; `Kati.Screens.Rating`'s `characters_label/1`
  # is the same count under the same card and two entries for it is how two
  # sheets end up counting in different words.
  #
  # `Kati.Locale.number/1` on the figure: it sits inside a sentence rather than
  # alone in a mono slot, so the digits are the reader's own.
  @doc false
  @spec count_label(non_neg_integer()) :: String.t()
  def count_label(n) when is_integer(n) and n >= 0,
    do: ngettext("%{n} character", "%{n} characters", n, n: Kati.Locale.number(n))

  def render(assigns) do
    ~MOB"""
    <Box
      fill_width={true}
      fill_height={true}
      background={:background}
      layout_direction={Kati.Locale.direction_prop()}
      font_family={Kati.Locale.face_prop()}
      accessibility_id={Kati.Screens.Identity.of(__MODULE__)}
    >
      <Box fill_width={true} fill_height={true} background={Kati.UI.Sheet.scrim()} />
      <Box fill_width={true} fill_height={true} align="bottom">
        <Scroll>
          <Column
            fill_width={true}
            background={Palette.paper()}
            corner_radius={26}
            padding_left={21}
            padding_right={21}
            padding_top={64}
            padding_bottom={34}
          >
            {Kati.Screens.RateAlbum.header()}
            {Kati.Screens.RateAlbum.notice(assigns.save_error)}
            {Kati.Screens.RateAlbum.context(assigns.album)}
            {Kati.Screens.RateAlbum.rating_card(assigns.rating)}
            {Kati.Screens.RateAlbum.note_card(assigns)}
            {Kati.Screens.RateAlbum.dates_card(assigns.album)}
            {Kati.Screens.RateAlbum.unrated_band(assigns.rating)}
            {Kati.Screens.RateAlbum.omissions()}
          </Column>
        </Scroll>
      </Box>
    </Box>
    """
  end

  @doc "Close disc, centred title, Save pill — board 33's chrome, and not a back pill: this is a sheet you commit or abandon."
  @spec header() :: map()
  def header do
    save = {self(), :save}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {Kati.UI.Sheet.close_disc()}
        <Text
          text={gettext("Rate an album")}
          weight={1.0}
          text_size={15}
          font_weight="bold"
          text_align="center"
          text_color={:on_surface}
          max_lines={1}
        />
        {Kati.Screens.RateAlbum.save_pill(save)}
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def save_pill(tap) do
    MishkaPill.pill(
      label: gettext("Save"),
      background: Palette.ink_fill(),
      color: Palette.on_ink(),
      height: 34,
      corner_radius: 17,
      padding: 0,
      padding_left: 14,
      padding_right: 14,
      text_size: 12.5,
      font_weight: :bold,
      align: :center,
      on_tap: tap
    )
  end

  @doc """
  What a save that did not land says, directly under the pill that failed.

  `Kati.Screens.Rating.save_notice/1`'s placement argument, and it lands the
  same way here for the same reason: this sheet's commit is in the header, so
  the line adjacent to it and reachable without scrolling is the one below.
  """
  @spec notice(String.t() | nil) :: map()
  def notice(nil), do: ~MOB"<Spacer size={0} />"

  def notice(message) do
    assigns = %{message: message}

    # The sentence itself is `Kati.Write.message/1`'s and is already a msgid
    # there — this draws it. `Kati.Locale.leading/1` over the design's 1.45,
    # because Vazirmatn's metrics are not Plus Jakarta's and a refusal set on
    # Latin leading collides with its own diacritics.
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={@message}
        text_size={13}
        font_weight="semibold"
        line_height={Kati.Locale.leading(1.45)}
        text_color={Palette.red()}
      />
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  The album-shaped context strip: the square, the title, the caps line, the
  plays pill.

  An album has no runtime you watched it on, no living room, no companion and
  no rewatch count, so where 33 has a poster and a rewatch pill this has a
  square and a count of plays. The strip is board 73's, reused verbatim rather
  than redrawn — `D-39` names that as the whole reason the add form and the
  rating sheet are one brief.

  The title, the byline and the plays line are all the album's —
  `Kati.Screens.AlbumDetail.shaped/4` words them and `Kati.Music.Sample.album/0`
  is the drawing's — so none of the three is a msgid here. What this strip does
  have to answer for is the TYPE: the design tightens the title by `-0.02em`,
  and `Kati.Locale.tracking/1` drops that under `:fa`, because letter-spacing
  pulls apart joins that Persian writes joined.
  """
  @spec context(map()) :: map()
  def context(a) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {Kati.Screens.RateAlbum.art()}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text
            text={a.title}
            text_size={16}
            font_weight="bold"
            letter_spacing={Kati.Locale.tracking(-0.02)}
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={5} />
          <Text
            text={Kati.Screens.RateAlbum.caps(a[:byline])}
            font_family={Kati.Locale.mono_face()}
            text_size={10.5}
            text_color={Palette.muted()}
            max_lines={1}
          />
          <Spacer size={8} />
          {Kati.Screens.RateAlbum.plays_pill(a[:plays_line])}
        </Column>
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  `KELL OSTRAND · 2025`, or nothing at all.

  `Kati.Music.Album.byline/2` already degrades — an album with no artist and no
  year answers `nil` — and upcasing `nil` would raise on exactly the record a
  hand-typed row can be.

  `Kati.UI.eyebrow_label/1` rather than `String.upcase/1`, which is the whole
  of the difference under `:fa`: upper case is a Latin operation and the Arabic
  script has none, so upcasing `کل استرند · ۲۰۲۵` returns it unchanged and
  leaves a call in the file that reads as a no-op somebody forgot to remove.
  The board still gets `KELL OSTRAND · 2025` in English, because that is what
  `eyebrow_label/1` does there.
  """
  @spec caps(String.t() | nil) :: String.t()
  def caps(nil), do: ""
  def caps(byline), do: UI.eyebrow_label(byline)

  @doc """
  The paper square: the `graphic_eq` glyph over the mono `ART` caption.

  Not `Kati.Screens.AlbumDetail.art/1`, and the difference is the board's: 74
  draws an 86pt square carrying the album's INITIAL, and 180 draws a 64pt square
  carrying the glyph. Both say *there is no artwork and that is the default
  rendering*, which is `Kati.Screens.AlbumDetail`'s rule; only the letter
  differs, and reusing the function would put 74's letter on 180's board.

  The CAPTION is 74's, though, and deliberately. `Kati.Screens.AlbumDetail`
  raises the same `Art` through `Kati.UI.eyebrow_label/1` over its own art card,
  and this is that word for that absence one board over — so this asks the
  catalogue for the same msgid rather than adding a second entry a translator
  would have to keep in step with the first by remembering to.

  `Kati.UI.eyebrow_label/1` and `Kati.Locale.tracking/1` rather than a literal
  `"ART"` and `0.1`: the caps and the tracking are the two things the Arabic
  script cannot take, and *هنر* set 0.1em apart is three disconnected letters.
  """
  @spec art() :: map()
  def art do
    ~MOB"""
    <Column
      width={64}
      height={64}
      corner_radius={13}
      background={Palette.placeholder()}
      align="center"
    >
      <Spacer weight={1.0} />
      {UI.symbol("graphic_eq", size: 20, color: Palette.tertiary())}
      <Spacer size={4} />
      <Text
        text={UI.eyebrow_label(gettext("Art"))}
        font_family={Kati.Locale.mono_face()}
        text_size={8.5}
        letter_spacing={Kati.Locale.tracking(0.1)}
        text_align="center"
        text_color={Palette.tertiary()}
        max_lines={1}
      />
      <Spacer weight={1.0} />
    </Column>
    """
  end

  @doc "Where 33 has `replay · 2nd rewatch`: the same pill, a different glyph and noun."
  @spec plays_pill(String.t() | nil) :: map()
  def plays_pill(nil), do: ~MOB"<Spacer size={0} />"

  def plays_pill(line) do
    text = ~MOB"""
    <Text
      text={line}
      text_size={11}
      font_weight="semibold"
      text_color={Palette.ink_soft()}
      max_lines={1}
    />
    """

    gap = ~MOB"<Spacer size={5} />"

    MishkaPill.pill(
      %{
        background: Palette.paper(),
        height: 24,
        corner_radius: 12,
        padding: 0,
        padding_left: 10,
        padding_right: 10,
        align: :center
      },
      [UI.symbol("repeat", size: 13, color: Palette.sub()), gap, text]
    )
  end

  # Three decisions about script on one card, and they are screen 33's, taken
  # deliberately rather than re-argued — `Kati.Screens.Rating.rating_card/1`
  # carries the long form of each:
  #
  #   * The eyebrow is `Kati.UI.eyebrow_label/1` around a normal-case msgid
  #     rather than `String.upcase("Rating")`, and `Kati.Locale.tracking/1`
  #     drops the `.16em` with it. Upper case and letter-spacing are both Latin
  #     operations; on Persian the first does nothing and the second breaks the
  #     joins between letters. 33's own msgid and context, not a second one —
  #     three sheets now label the same card.
  #   * **The numeral keeps a hardcoded `mono`.** `Kati.Rating.Scale.label/2`
  #     answers `4.5`, `9` or `—` in both scripts, and a figure the design sets
  #     in DM Mono keeps Latin digits — `Kati.Locale.number/1`'s own doc states
  #     that rule. This asked `Kati.Locale.mono_face/0` until now, which under
  #     `:fa` set the same Latin `4.5` in Vazirmatn while screens 33 and 144
  #     set theirs in DM Mono: one numeral, two faces, on three sheets about
  #     one rating.
  #   * The note under the stars IS a sentence, so it takes
  #     `Kati.Locale.mono_face/0` — `kati_mono.ttf` carries no Persian glyph.
  @doc false
  def rating_card(rating) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={17}
      >
        <Row fill_width={true} align="center">
          <Text
            text={UI.eyebrow_label(pgettext("the rating card's own label", "Rating"))}
            font_family={Kati.Locale.mono_face()}
            text_size={10.5}
            letter_spacing={Kati.Locale.tracking(0.16)}
            text_color={Palette.eyebrow()}
            max_lines={1}
          />
          <Spacer weight={1.0} />
          {Rating.scale_toggle()}
        </Row>
        <Spacer size={13} />
        <Row fill_width={true} align="center">
          {Rating.stars(rating, true)}
          <Spacer size={10} />
          <Text
            text={Rating.rating_label(rating)}
            font_family="mono"
            text_size={14}
            text_color={:on_surface}
            max_lines={1}
          />
        </Row>
        <Spacer size={10} />
        <Text
          text={Kati.Screens.RateAlbum.rating_note()}
          font_family={Kati.Locale.mono_face()}
          text_size={10.5}
          text_color={Palette.muted()}
          max_lines={1}
        />
      </Column>
      <Spacer size={12} />
    </Column>
    """
  end

  @doc """
  The note under the star row — screen 33's own sentence, asked for by name.

  A display preference with no resource behind it, and screen 33 says so at
  length: `HALF STARS ON` and the `5★`/`10pt` toggle are both statements about
  which scale the reader reads ratings on, and no column anywhere records one.

  It was a `@rating_note` module attribute here, which is the shape a msgid
  cannot take — `gettext/1` inside a module attribute is evaluated at COMPILE
  time and freezes in whichever locale the compiler was in. Rather than write a
  second `pgettext/2` for a sentence that already has one, this asks
  `Kati.Screens.Rating.rating_note/0` for it. The sheet already borrows that
  module's star row, its scale toggle and its rating label for the reason the
  moduledoc gives, and the caption printed UNDER the star row is a statement
  about that star row: two copies could disagree about the gesture while the
  gesture stayed one function.
  """
  @spec rating_note() :: String.t()
  def rating_note, do: Rating.rating_note()

  @doc """
  The note card: the same body screen 74's cream card draws, in a field.

  A `<TextField>` rather than the board's `<Text>`, for the reason
  `Kati.Screens.Rating.review_field/1` gives: the board draws a picture of a
  focused input, and `<TextField>` is in the pinned Mob and has been since
  `Kati.Screens.Backup` typed a passphrase into one.

  `Note` takes a `pgettext/2` and not a bare msgid: it is one word, and
  `mix gettext.merge` fuzzy-matches something that short onto the first
  neighbour that half-resembles it — the catalogue already holds `Notes` twice,
  once for a section and once for a search scope. The context is worded after
  `Kati.Screens.Rating`'s *the review card's own label*, because this is that
  card with the other noun on it.

  The date beside it is `note_on`, which `Kati.Screens.AlbumDetail.shaped/4`
  has already worded and converted, so it is drawn and not translated here.
  """
  @spec note_card(map()) :: map()
  def note_card(assigns) do
    a = assigns.album
    change = {self(), :note}

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={17}
      >
        <Row fill_width={true} align="center">
          <Text
            text={UI.eyebrow_label(pgettext("the note card's own label", "Note"))}
            font_family={Kati.Locale.mono_face()}
            text_size={10.5}
            letter_spacing={Kati.Locale.tracking(0.16)}
            text_color={Palette.eyebrow()}
            max_lines={1}
          />
          <Spacer weight={1.0} />
          <Text
            text={a[:note_on] || ""}
            font_family={Kati.Locale.mono_face()}
            text_size={10.5}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Row>
        <Spacer size={9} />
        <TextField
          value={assigns.note}
          placeholder={gettext("What did you make of it?")}
          return_key="done"
          fill_width={true}
          text_size={14}
          accessibility_id="album_note"
          on_change={change}
        />
        <Spacer size={13} />
        <Box fill_width={true} height={1} background={Palette.hairline()} />
        <Spacer size={12} />
        <Row fill_width={true} align="center">
          <Text
            text={assigns.characters}
            font_family={Kati.Locale.mono_face()}
            text_size={10.5}
            text_color={Palette.muted()}
            max_lines={1}
          />
          <Spacer weight={1.0} />
          {UI.symbol("format_bold", size: 16, color: Palette.sub())}
          <Spacer size={7} />
          {UI.symbol("format_italic", size: 16, color: Palette.sub())}
          <Spacer size={7} />
          {UI.symbol("link", size: 16, color: Palette.sub())}
        </Row>
      </Column>
      <Spacer size={12} />
    </Column>
    """
  end

  @doc """
  First heard, and Last played.

  First heard carries a chevron because it is editable and Last played does not
  because it is not — screen 73's save owns that column, and the board prints
  who owns it rather than leaving a reader to wonder why one row of two does
  nothing. The chevron carries no `on_tap` yet: there is no date picker in Kati
  and drawing a control that opens nothing is what
  `Kati.ScreenTapSweepTest`'s backlog exists to refuse.

  Both titles are `Kati.Screens.AlbumDetail`'s own msgids — screen 74 names the
  same two columns in its stat tiles — so the page and the sheet that edits it
  cannot end up calling one column two things. Both VALUES arrive worded and
  converted from there too: that module puts a date through `Kati.Locale.date/2`
  at `:dated` and has its own msgid for *yesterday*, so neither is touched here.

  `SettingsList.chevron/0` already answers `Kati.Locale.forward_chevron/0`, so
  the row that opens something points leftward in Persian without this file
  asking.
  """
  @spec dates_card(map()) :: map()
  def dates_card(a) do
    rows = [
      SettingsList.row(
        SettingsList.icon_tile("event"),
        SettingsList.body(gettext("First heard"), a[:first_heard]),
        SettingsList.chevron(),
        padding: 13,
        rule: true
      ),
      SettingsList.row(
        SettingsList.icon_tile("history"),
        SettingsList.body(
          gettext("Last played"),
          Kati.Screens.RateAlbum.owned_by_73(a[:last_played])
        ),
        nil,
        padding: 13,
        rule: false
      )
    ]

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(rows)}
      <Spacer size={14} />
    </Column>
    """
  end

  @doc """
  The board's own sub-line for a value this sheet reads and does not write.

  One msgid per branch with the date INTERPOLATED, rather than the
  `value <> " — …"` this was. A sentence assembled from a translated fragment
  can only ever be assembled in English's order, and the Persian for *screen
  73's save owns it* does not put the verb where English does; handing the
  whole line to the translator is what lets them move it.

  `73` goes through `Kati.Locale.number/1` rather than being written into the
  msgid, which is `Kati.Screens.AttributionStates`'s rule for a board number a
  sheet names out loud: a translator who met `73` inside the sentence would
  have to retype it to convert it, and a retyped figure is a figure that can
  come back wrong. It is a board number the reader reads, not a citation off a
  printed object, so `Kati.Locale.year/1`'s digits-only rule does not reach it.
  """
  @spec owned_by_73(String.t() | nil) :: String.t()
  def owned_by_73(nil),
    do:
      pgettext(
        "the sub-line naming the screen that owns a date",
        "— screen %{board}’s save owns it",
        board: Kati.Locale.number(73)
      )

  def owned_by_73(value),
    do:
      pgettext(
        "the sub-line naming the screen that owns a date",
        "%{date} — screen %{board}’s save owns it",
        date: value,
        board: Kati.Locale.number(73)
      )

  @doc """
  *No rating yet* — the state this sheet is not in.

  Board 180 draws the resting sheet with a rating already set, *since a person
  usually arrives to change one*, and draws the unrated row beside it. So the
  band appears while there IS a rating and is replaced by the live star row the
  moment there is not — screen 178's *Artist chosen* inset again, and 179's
  *Nothing found* card.
  """
  @spec unrated_band(number() | nil) :: map()
  def unrated_band(nil), do: ~MOB"<Spacer size={0} />"

  def unrated_band(_rating) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.Eyebrow.quiet(gettext("No rating yet"))}
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={17}
      >
        {Rating.stars(nil)}
        <Spacer size={10} />
        <Text
          text={Kati.Screens.RateAlbum.unrated_note()}
          text_size={11.5}
          line_height={Kati.Locale.leading(1.5)}
          text_color={Palette.muted()}
        />
      </Column>
      <Spacer size={14} />
    </Column>
    """
  end

  @doc """
  What the unrated row promises: nothing is printed and the commit still works.

  Asked for by name rather than written into the sigil, the way
  `omissions_body/0` is and for its reason — the sentence is long enough that
  a `gettext/1` around it inside a `~MOB` attribute would be a multi-line
  expression in an attribute slot, and none of the 180-odd screens writes one.

  `Save` inside it is the pill in this sheet's own header, so it translates
  with the sentence rather than staying a Latin token: a Persian reader is
  being told that the button reading **ذخیره** stays live, and naming it in
  English would point at a control that is not on the page.
  """
  @spec unrated_note() :: String.t()
  def unrated_note do
    gettext("No printed figure, and Save stays live — a note with no stars is a real log.")
  end

  @doc """
  The board's annotation: the four things this sheet does not have, and why.

  Two paragraphs at the design's 1.65, raised to `Kati.Theme.fa_line_height/0`
  under `:fa` by `Kati.Locale.leading/1`. This is the longest run of copy on
  the sheet and the one where Vazirmatn's taller metrics show first — a Latin
  leading holds its descenders and clips Persian's.
  """
  @spec omissions() :: map()
  def omissions do
    ~MOB"""
    <Row
      fill_width={true}
      corner_radius={18}
      border_width={1.5}
      border_color={Palette.border()}
      padding={15}
      align="top"
    >
      {UI.symbol("info", size: 17, color: Palette.sub())}
      <Spacer size={11} />
      <Column weight={1.0}>
        <Text
          text={Kati.Screens.RateAlbum.omissions_title()}
          text_size={12.5}
          line_height={Kati.Locale.leading(1.65)}
          font_weight="semibold"
          text_color={Palette.ink()}
        />
        <Text
          text={Kati.Screens.RateAlbum.omissions_body()}
          text_size={12.5}
          line_height={Kati.Locale.leading(1.65)}
          text_color={Palette.ink_soft()}
        />
      </Column>
    </Row>
    """
  end

  @doc "The annotation's own heading, over the paragraph that answers it."
  @spec omissions_title() :: String.t()
  def omissions_title, do: gettext("Four things this sheet does not have, and why:")

  @doc """
  The note's body, as one sentence.

  Board 180 emphasises six phrases INSIDE this paragraph — `Where`, `With`,
  `No tag pills`, `star at FILL 0`, `the same note` — and it was first built
  the way the export writes it: one `<Text>` per run, stacked in the Column.
  A device showed what that is. `Mob.Renderer`'s `Text` takes a `String` and
  the bridge hands it to Compose's `Text`, which has no span list, so stacked
  runs are not a paragraph with bold in it — they are a paragraph broken at
  every bold, four words to a line, mid-clause. `Kati.Screens.MedicationEmpty`
  draws its own annotations flat for this reason and is 2 literals short of
  board 190's count because of it; that is the price and it is the right one.

  Every word the board writes is still here and in its order, so
  `Kati.ScreenDesignLiteralTest` finds each run inside this one node.

  ## One msgid, and why it is not six

  Flat is also what makes it translatable. The six emphasised runs are clauses
  of one sentence, not labels, and a paragraph assembled from six translated
  fragments can only ever be assembled in ENGLISH's order — Persian does not
  put *no Where and no With* where English does, and the fragment boundaries
  would be visible as a sentence that parses word by word and not as a whole.
  So the paragraph is one msgid, which is the trade `Kati.Screens.Rating` makes
  over two words for its *2nd rewatch* badge and states there at length.

  `Where` and `With` inside it are screen 33's row titles and are translated
  there as `کجا` and `با چه کسی`; this sentence says them again in prose rather
  than citing the msgids, because a Persian sentence that spliced in two
  separately-translated nouns would read as a list and not as a clause.

  The board numbers are interpolated through `Kati.Locale.number/1` rather than
  written into the msgid, for `owned_by_73/1`'s reason: a figure a translator
  has to retype to convert is a figure that can come back wrong.

  `star` and `FILL 0` stay Latin and are NOT wrapped in `Kati.Locale.ltr/1` —
  they cannot be, being inside one msgid rather than at a call site. They do
  not need it: both sit mid-sentence with Persian on either side, so the bidi
  algorithm resolves the neutrals around them against the words next to them.
  `Kati.Locale.ltr/1` is for a Latin run whose own punctuation ends the
  sentence, which is the case screen 83's licence notices met.
  """
  @spec omissions_body() :: String.t()
  def omissions_body do
    gettext(
      "no spoiler toggle — a record has no plot to spoil; no Where and no With — " <>
        "nothing in a listen records a service, a room or a companion; no rewatch " <>
        "count — the plays pill says it better. No tag pills either: %{tag_board}’s " <>
        "+ tag is already inert, and a brand-new board should not ship a second one. " <>
        "The half star is star at FILL 0, never a cropped glyph. The body edits the " <>
        "same note %{note_board}’s cream card draws — two review fields would be two " <>
        "truths about one record.",
      tag_board: Kati.Locale.number(33),
      note_board: Kati.Locale.number(74)
    )
  end

  def handle_info({:tap, :close}, socket), do: {:noreply, Kati.Screens.Resume.pop(socket)}

  def handle_info({:tap, :save}, socket) do
    case Kati.Screens.RateAlbum.save_rating(socket.assigns) do
      {:ok, _album} ->
        {:noreply,
         socket
         |> Mob.Socket.assign(:save_error, nil)
         |> Kati.Screens.Resume.pop()}

      error ->
        {:noreply, Mob.Socket.assign(socket, :save_error, Write.message(error))}
    end
  end

  @doc """
  What was typed into the note, held as typed.

  The count under the field moves with it, because a count under a field is a
  count of what is in the field. The board's own `104 characters` is a fact
  about the board and stops being the answer the moment a person types.
  """
  def handle_info({:change, :note, typed}, socket) when is_binary(typed) do
    {:noreply,
     socket
     |> Mob.Socket.assign(:note, typed)
     |> Mob.Socket.assign(:characters, Kati.Screens.RateAlbum.characters_label(typed))}
  end

  # A star, half a star at a time — `Kati.Screens.Rating.star_tag/1` draws ten
  # targets over five glyphs so the ten-point column is reachable at every
  # point, and `point_of/1` is the same function read back.
  def handle_info({:tap, tag}, socket) when is_atom(tag) do
    case Rating.point_of(tag) do
      nil -> {:noreply, socket}
      point -> {:noreply, Mob.Socket.assign(socket, :rating, point / 2)}
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  @doc """
  Write the draft onto the album this sheet opened on.

  `Ash.update/1`, never `Ash.create/2`: the sheet is an editor for a record that
  already exists, and a second row would be a second album with one name.

  **With no album there is nothing to update, and that is the whole answer.**
  The sheet is then drawing `Kati.Music.Sample.album/0`, which belongs to the
  drawing, and committing it would file *Tidal Works* and a note nobody wrote
  under the reader's own shelf. `{:error, :nothing_to_save}` is `Kati.Write`'s
  own term for it.

  `shelved/1` and not a fresh read of the shelf: the id was pinned at mount, so
  the row this updates is the row the page drew — which is what
  `Kati.ScreenWriteTargetTest` is asking of every write in the app.

  A blank note is stored as `nil` rather than `""`, because
  `Kati.Music.Album.note` is nullable and a note of nothing but whitespace is
  not a note. What is not blank is stored **as typed**: trimming a person's own
  words is an edit this function is not entitled to.

  `note_on` moves with the note and only with it — a rating changed on its own
  does not restamp the day somebody wrote a sentence.
  """
  @spec save_rating(map()) :: {:ok, struct()} | {:error, term()}
  def save_rating(assigns) do
    case AlbumDetail.shelved(assigns[:album_id]) do
      %Album{} = album -> update(album, assigns)
      nil -> Write.note({:error, :nothing_to_save}, "rate an album")
    end
  end

  defp update(album, assigns) do
    note = stored_note(assigns.note)

    album
    |> Ash.Changeset.for_update(:update, %{
      rating: Kati.Screens.RateAlbum.ten_point(assigns.rating),
      note: note,
      note_on: note && Kati.Time.today()
    })
    |> Ash.update()
    |> Write.note("rate an album")
  end

  defp stored_note(note) when is_binary(note) do
    case String.trim(note) do
      "" -> nil
      _kept -> note
    end
  end

  defp stored_note(_note), do: nil
end
