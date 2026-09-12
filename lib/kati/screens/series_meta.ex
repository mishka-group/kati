defmodule Kati.Screens.SeriesMeta do
  @moduledoc """
  Screen 14 — a series in full, pushed under Library.

  Built to `test/design/screens/14.html`. Where screen 04 answers *what do
  I watch next*, this one answers *what is this thing* — three ratings side by
  side, the synopsis, real cast, every way to watch including the user's own
  shelf, and the user's own tags last.

  The order is the argument. Ratings from three sources come first because they
  are what a stranger wants; the user's tags come last because they are what
  the user already knows. Nothing here is a modal or a tab: it is the same card
  rhythm as every other screen, just longer.

  ## Chrome

  Its own, not `Kati.Screens.Pushed`'s. The back pill floats over a 270pt still
  at 60pt with an overflow disc opposite it, the way screens 04 and 08 do —
  the pushed chrome sits on paper and has no partner button.

  A 150pt gradient lifts the paper back over the bottom of the still so the
  title is ink on paper rather than ink on a photograph. The drawing gives it
  three stops rather than two — opaque at 4%, 70% at 44%, gone at the top —
  so it is written out here rather than reusing `Kati.UI.paper_fade/1`, which
  is the two-stop version.

  ## Two places the drawing uses something the bridge has not got

    * `&starf; 4.5` is U+2605 followed by the value. Plus Jakarta Sans has no
      U+2605, so the star is the Material Symbols `star` glyph and only `4.5`
      is text. Same mark, different font — see screen 08, where the text
      version rendered as nothing at all.
    * `+ tag` is drawn with a **dashed** 1.5pt border. The bridge's border is
      solid, so this is a solid 1.5pt hairline at the same colour. The chip
      still reads as the empty slot it is, because the fill is absent rather
      than white.

  Tags `flex-wrap` in the drawing, and now they wrap here too: `<Wrap>` arrived
  with mob 0.8.0 and its Android renderer with the mob_new 0.4.33 template, so
  `tags/1` measures instead of chunking three-then-two at one browser width.
  That is mishka-group/kati#98, and `Kati.WrapLayoutTest` holds it.

  ## Why this screen still reads `Kati.Screens.SeriesMeta.Sample`

  Screens 03 and 08 moved onto `Kati.Media`. This one stays, and the reason is
  not an episode this time — it is that most of what this page *is* has no
  resource in the app at all. `Kati.Media` holds what a provider said about a
  title, what the user did with it, and now its seasons and episodes. This
  drawing is mostly the third thing a provider says about a title, and there is
  nowhere to put it.

  Precisely what this screen draws and no resource can currently express:

    * **The cast.** Four faces, four names, four character names. There is no
      person resource, no credit resource and no column on
      `Kati.Media.CachedTitle` that could hold one — `Kati.Media.Watch.companions`
      is names as typed for *who you watched with*, and its own moduledoc says
      Kati has no people table and that inventing one *"would be a larger privacy
      decision than the feature is asking for"*. This is the whole of
      `cast/1`.
    * **Two of the three ratings.** `Audience 8.1` and `Critics 96%` are other
      people's scores; nothing caches them. Only `Yours` is expressible, from
      `Kati.Media.TrackedTitle.rating` on the ten-point scale — `4.5` is `9` —
      and one real number between two frozen ones is the worst of the three
      available answers.
    * **`Where to watch`, and its prices.** The same absent offers resource
      screen 08 names: `included · 4K HDR`, `buy season · £14.99` and
      `Blu-ray, S1–S2 · owned` are availability, pricing and physical ownership,
      and `Kati.Media.Watch.service` is per-watch and carries none of them.
    * **`Your tags`.** `Kati.Media.Watch.tags` is comma-separated tags on *one
      night's watch*; these are tags on the title. Nothing stores a tag against
      a `Kati.Media.TrackedTitle`, and reading a title's tags out of its watches
      would make a tag vanish when the watch it happened to be typed on was
      deleted.
    * **`Trailer`.** No video, no link, no column.
    * **Two thirds of the meta line.** `2024` is a first-air year and
      `Kati.Media.CachedTitle.next_release_at` is the NEXT release; `15` is a
      certification with no column. `DRAMA, MYSTERY` is `genres`, `3 SEASONS` is
      `Kati.Media.CachedSeason.count/1` and `26 EP` is
      `CachedTitle.episode_count` — so the line would land as three of its five
      parts, in a card whose ratings above it are already two thirds frozen.

  What *is* expressible today is the title, the artwork, the synopsis
  (`Kati.Media.CachedTitle.overview`) and one rating. Those four are deliberately
  not split out, for the reason `Kati.Screens.Series` gives: a page whose ratings
  are one real and two invented, and whose cast is four strangers, reads as
  entirely real. An honest gap is worth more than a screen that renders wrong.
  """
  use Mob.Screen
  use Gettext, backend: Kati.Gettext
  import Mob.Sigil

  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaPill
  alias Kati.Components.MishkaSeparator
  alias Kati.Components.MishkaThemeIcon
  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Screens.SeriesMeta.Sample
  alias Kati.Theme.Palette
  alias Kati.UI

  require Ash.Query

  # An anime is a series. `Kati.Screens.Series` reads the same two kinds, and a
  # page that read only `:tv` would describe the board over every anime the
  # reader tracks.
  @series_kinds [:tv, :anime]

  def mount(params, _session, socket) do
    Mob.Theme.set(Kati.Theme.current())
    # Resolves the stored locale into THIS process. `Gettext.put_locale/2`
    # snapshots into the calling process exactly as `Mob.Theme.set/1` does,
    # and a screen is its own process — see `Kati.Locale.activate/0`.
    Kati.Locale.activate()

    {:ok,
     socket
     |> Mob.Socket.assign(:series, series(Map.get(params || %{}, :id)))
     |> Mob.Socket.assign(:back, Kati.Screens.Pushed.back_label(params, "Series"))}
  end

  @doc """
  The series this page describes: the user's, or the drawing's.

  Screen 04's gate, on screen 14. Either every value on the page is this
  reader's or every value is the board's — the moduledoc above says why the
  halfway house is the worst of the three, and it is what this page WAS: the
  fixture, whole, over whatever show's overflow menu opened it. *Show details*
  on Severance described The Long Hollow, in four ratings, four faces and five
  tags, none of which were about the thing on the screen a second earlier.

  `id` is the tracked row the series page named. Without one — the gallery's
  door, a test's — the answer is the board, which is the state
  `test/design/screens/14.html` was captured in.
  """
  @spec series(String.t() | nil) :: map()
  def series(id \\ nil) do
    tracked_meta(id) || Sample.series()
  end

  @doc """
  The params that name a series to screen 14.

  The argument is screen 04's assembled view, whose one identity field is
  `:tracked_id` — `Kati.Screens.Series.assembled/5` carries it for exactly this
  kind of question. A map without one is `Kati.Library.Sample`'s and yields
  `%{}`: the drawing has no row to name.

      iex> Kati.Screens.SeriesMeta.params_for(%{tracked_id: "abc", title: "X"})
      %{id: "abc"}

      iex> Kati.Screens.SeriesMeta.params_for(%{title: "X"})
      %{}
  """
  @spec params_for(map() | nil) :: map()
  def params_for(%{tracked_id: id}) when is_binary(id), do: %{id: id}
  def params_for(_row), do: %{}

  # The tracked row, shaped for this page — or `nil`, which is every reason
  # there is nothing to describe: no such row, no cache behind it, an empty
  # store. `rescue` for `Kati.Screens.Film.tracked_film/1`'s reason: a screen
  # that cannot read is a screen that draws its board, not one that crashes.
  defp tracked_meta(id) do
    case series_record(id) do
      nil -> nil
      tracked -> shaped(tracked, cached_for(tracked))
    end
  rescue
    _ -> nil
  end

  # Read THROUGH `:shelf`, like every other door onto a title: it is where
  # *keeps history, hides from shelf* is enforced, so an id fetched around it
  # would describe a show the reader archived. Both kinds, because an anime is
  # a series here — `Kati.Screens.Series` reads the same two.
  defp series_record(nil), do: List.first(shelf())

  defp series_record(title_id), do: Enum.find(shelf(), &(&1.id == title_id))

  defp shelf do
    Enum.flat_map(@series_kinds, fn kind ->
      TrackedTitle
      |> Ash.Query.for_read(:shelf, %{kind: kind})
      |> Ash.read!()
    end)
  end

  defp cached_for(%TrackedTitle{source: source, source_id: source_id}) do
    CachedTitle
    |> Ash.Query.filter(source == ^source and source_id == ^source_id)
    |> Ash.read_one!()
  end

  @doc """
  One tracked series in the shape the markup reads — and nothing it cannot know.

  Four of the eleven keys have a value today. The other seven are `[]` or
  `nil`, and `render/1` drops the band rather than drawing an empty card: the
  moduledoc's list is why they are empty and this is what empty looks like.

    * `title` is the cache's, `Untitled` when the cache row has been evicted —
      `Kati.Screens.Film.shaped/3`'s answer, for its reason.
    * `seed` is `poster_path`, which `Kati.Media.Artwork` turns into a file.
    * `meta` is the three of the drawing's five parts that exist: the genres,
      the season count and the episode count. The year and the certification
      have no column, so the line is short rather than invented.
    * `synopsis` is `overview`, and `more` is `nil` — there is no expander, and
      a `more` under text that is already whole is a control that lies.
    * `ratings` is the reader's own three, per board 311. It used to be `[]`,
      because the drawing's trio is `Yours`, `Audience` and `Critics` and the
      last two are other people's scores that nothing caches. 311 replaced them
      rather than leaving the row out: *"Audience and Critics are gone, not
      blank… the trio becomes your rating, your progress, your hours — three
      things the reader's own columns already answer, at the same typography."*
    * `cast`, `where` and `tags` are `[]`, and `trailer` is `nil`, for the four
      reasons the moduledoc gives.
  """
  @spec shaped(TrackedTitle.t(), CachedTitle.t() | nil) :: map()
  def shaped(tracked, cached) do
    %{
      title: (cached && cached.title) || gettext("Untitled"),
      seed: cached && cached.poster_path,
      meta: meta_line(cached),
      ratings: Kati.Screens.SeriesMeta.yours(tracked, cached),
      synopsis: (cached && cached.overview) || "",
      more: nil,
      trailer: nil,
      cast: [],
      where: Kati.Screens.SeriesMeta.where_rows(cached),
      tags: [],
      add_tag: nil
    }
  end

  @doc """
  Every way this title can be watched, for the band board 14 draws and had
  nothing to fill.

  This was `[]` and the moduledoc said why: *the same absent offers resource*.
  It is not absent any more. TMDB folds JustWatch's per-country data into the
  detail response Kati already fetches, `Kati.Media.CachedTitle.providers`
  keeps it, and `Kati.Media.Availability` reads it — MOVIES-AND-TV.md #77.

  What is drawn is the reader's own country's answer, in the order the board
  puts it: what you pay for first, then free, then rent, then buy. The badge is
  the service's initial, the same two-letter mark screen 92 gives its rows.

  **No prices**, and the `price` slot stays `nil` on every row. TMDB says
  *where*, never *how much*: it has no price field, and JustWatch's own terms
  do not let one through this endpoint. Board 14 draws `£14.99` beside *buy
  season* and a number Kati invented there would be the most expensive kind of
  lie a page like this can tell. `line/1` says what the offer IS — *included*,
  *rent*, *buy* — which is the part that is known.

  `[]` for a title nobody has fetched, which `band/4` then drops entirely
  rather than drawing an eyebrow over nothing.
  """
  @spec where_rows(CachedTitle.t() | nil) :: [map()]
  def where_rows(nil), do: []

  def where_rows(cached) do
    reader = Kati.Services.availability()
    mine = MapSet.new(reader.subscribed, &String.downcase/1)

    case Kati.Media.Availability.offers(cached, reader.region) do
      nil ->
        []

      offers ->
        # The KIND is TMDB's key and never drawn; the line beside it is this
        # page's own word for it and is. `pgettext/2` on all five: they are one
        # and two words long, and `mix gettext.merge` fuzzy-matches a msgid that
        # short against any sentence that happens to contain it — *free* and
        # *buy* are in a dozen. The context is what keeps the availability
        # vocabulary its own.
        for {kind, line} <- [
              {"flatrate", pgettext("where to watch", "included")},
              {"free", pgettext("where to watch", "free")},
              {"ads", pgettext("where to watch", "free, with ads")},
              {"rent", pgettext("where to watch", "rent")},
              {"buy", pgettext("where to watch", "buy")}
            ],
            name <- List.wrap(Map.get(offers, kind)),
            is_binary(name) do
          %{
            # `String.upcase/1` and not `Kati.UI.eyebrow_label/1`, which is the
            # one place on this page that distinction goes the other way: this
            # is not an eyebrow whose case is a Latin typographic convention,
            # it is the first letter of a NAME being written as a capital. It
            # stays capital on a Persian page for the same reason `Lumen+` does.
            badge: String.slice(name, 0, 1) |> String.upcase(),
            name: name,
            line: Kati.Screens.SeriesMeta.where_line(kind, line, name, mine),
            price: nil
          }
        end
    end
  end

  @doc """
  What a row says under the service's name.

  *included · you pay for this* on a service the reader has told screen 92
  about, which is the one fact this page can add to TMDB's answer and the one
  a reader most wants: whether tonight costs anything.

      iex> Kati.Screens.SeriesMeta.where_line("flatrate", "included", "Netflix", MapSet.new(["netflix"]))
      "included · you pay for this"

      iex> Kati.Screens.SeriesMeta.where_line("flatrate", "included", "Now", MapSet.new(["netflix"]))
      "included"

      iex> Kati.Screens.SeriesMeta.where_line("rent", "rent", "Apple TV", MapSet.new([]))
      "rent"
  """
  @spec where_line(String.t(), String.t(), String.t(), MapSet.t()) :: String.t()
  def where_line("flatrate", line, name, mine) do
    # The whole line is one msgid rather than a translated tail concatenated
    # onto a translated head: Persian puts the possessive on the clause
    # (*هزینه‌اش را می‌پردازید*), and a language that wanted to say it BEFORE the
    # offer changes this string rather than this function.
    if MapSet.member?(mine, String.downcase(name)),
      do: gettext("%{line} · you pay for this", line: line),
      else: line
  end

  def where_line(_kind, line, _name, _mine), do: line

  # `2024 · DRAMA, MYSTERY · 3 SEASONS · 26 EP`, minus whichever part the cache
  # has not got. The interpuncts are the drawing's; the upper case is the
  # drawing's in LATIN only, which is why every part goes through
  # `Kati.UI.eyebrow_label/1` rather than `String.upcase/1` — Persian has no
  # case, and `String.upcase/1` on Persian is a no-op that still reads as a
  # decision somebody made. The `15` certification the board draws between the
  # year and the genres is still dropped rather than guessed: no column holds
  # one.
  #
  # The YEAR converts its digits and nothing else — `Kati.Locale.year/1`'s rule,
  # and board 69's: a first-air year is a fact about the broadcast calendar, so
  # `2024` is `۲۰۲۴` and never `۱۴۰۳`.
  #
  # `render/1` draws this at `max_lines={2}`, not 1. The board's own sample fits
  # on one line and still does; a real title does not. Severance carries three
  # genres and the line came out `... 3 SEASONS · 19…` on a device — so the
  # episode count is what truncation ate, every time, being last. Wrapping loses
  # nothing and truncating always lost the same fact.
  defp meta_line(nil), do: ""

  defp meta_line(%CachedTitle{} = cached) do
    seasons = Kati.Media.CachedSeason.count(seasons_of(cached))

    [
      # The year, which board 14 draws first and which had no column until
      # 6 September — see the migration. The `15` certification beside it on
      # the board still has none, so the line is four parts rather than five.
      cached.first_release_year && Kati.Locale.year(cached.first_release_year),
      cached.genres && UI.eyebrow_label(cached.genres),
      seasons > 0 && UI.eyebrow_label(seasons_label(seasons)),
      cached.episode_count && UI.eyebrow_label(episodes_label(cached.episode_count))
    ]
    |> Enum.filter(&is_binary/1)
    |> Enum.join(" · ")
  end

  # Screen 04's own msgid, deliberately — `Kati.Screens.Series.meta_line/1`
  # draws the identical clause two screens away and one word for it is the
  # whole point of a catalogue. Persian does not inflect a noun after a
  # numeral, so both plural forms are `%{n} فصل`.
  defp seasons_label(n),
    do: ngettext("%{n} season", "%{n} seasons", n, n: Kati.Locale.number(n))

  # `26 EP` is invariant on the board — no `EPS` at any count — so this is
  # `gettext/1` and not `ngettext/3`: inventing an English plural the drawing
  # does not draw would change the Latin page to make the Persian one easier.
  # `pgettext/2` because `%{n} ep` is two characters of actual text and
  # `mix gettext.merge` would fuzzy-match it against anything.
  defp episodes_label(n),
    do: pgettext("series meta line", "%{n} ep", n: Kati.Locale.number(n))

  defp seasons_of(%CachedTitle{source: source, source_id: source_id}),
    do: Kati.Media.CachedSeason.for_title(source, source_id)

  def render(assigns) do
    s = assigns.series

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
        <Column fill_width={true}>
          {Kati.Screens.SeriesMeta.artwork(s)}
          <Column
            fill_width={true}
            padding_left={21}
            padding_right={21}
            padding_top={16}
            padding_bottom={40}
          >
            {Kati.Screens.SeriesMeta.ratings(s)}
            {Kati.Screens.SeriesMeta.synopsis(s)}
            {Kati.Screens.SeriesMeta.actions(s)}
            {Kati.Screens.SeriesMeta.band(s.cast, gettext("Cast"), &Kati.Screens.SeriesMeta.cast/1, s)}
            {Kati.Screens.SeriesMeta.band(s.where, gettext("Where to watch"), &Kati.Screens.SeriesMeta.where/1, s)}
            {Kati.Screens.SeriesMeta.band(s.tags, gettext("Your tags"), &Kati.Screens.SeriesMeta.tags/1, s)}
            {Kati.Screens.SeriesMeta.claim(s)}
          </Column>
        </Column>
      </Scroll>
      {Kati.Screens.SeriesMeta.chrome(Map.get(assigns, :back, gettext("Series")))}
    </Box>
    """
  end

  @doc """
  Board 311's claim card: what is absent, and why.

  *"A page is allowed to be short. What it is not allowed to do is imply a
  missing half — 248's claim card replaces 40% of empty paper with a sentence
  naming what is absent and why."*

  Cast and the two other-people's scores need resources this app has no column
  for — a person, and a cached score — and board 203 declined to invent either.
  The card says so. It is drawn only when a band is actually missing, so a
  future release that fills them takes it off the page by filling them.

  `Your tags` is named here rather than drawn: 203 ruled the tags are the
  WATCH's and live on 04, and *"the identical-looking control on 14 was a
  different column that does not exist"*.
  """
  @spec claim(map()) :: term()
  def claim(%{cast: cast}) when cast != [], do: ~MOB"<Spacer size={0} />"

  def claim(_missing) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        padding={15}
        shadow={Kati.Theme.shadow_card_soft()}
      >
        <Spacer size={4} />
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          <Box width={44} height={44} corner_radius={14} background={Palette.paper()} align="center">
            {Kati.UI.symbol("group", size: 21, color: Kati.Theme.Palette.rail_idle())}
          </Box>
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={12} />
        <Text
          text={gettext("No cast, and no scores")}
          text_size={13.5}
          font_weight="bold"
          text_color={:on_surface}
          text_align="center"
        />
        <Spacer size={6} />
        <Text
          text={gettext("Both need a resource Kati has no column for — a person, and a cached score.")}
          text_size={12}
          line_height={Kati.Locale.leading(1.55)}
          text_color={Palette.sub()}
          text_align="center"
        />
        <Spacer size={8} />
        <Text
          text={gettext("Your tags are on the series page, which is where they are written.")}
          text_size={12}
          line_height={Kati.Locale.leading(1.55)}
          text_color={Palette.sub()}
          text_align="center"
        />
        <Spacer size={4} />
      </Column>
      <Spacer size={26} />
    </Column>
    """
  end

  @doc """
  A titled band, or nothing at all.

  Three of screen 14's six sections describe things `Kati.Media` has no
  resource for — the cast, the offers, and tags on a title rather than on one
  night's watch — so on a real series each one is `[]`. An eyebrow over an
  empty card is worse than a shorter page: it is a heading promising a section
  that never arrives, and the `Spacer` above it would leave 26pt of nothing
  where the heading used to be.

  The board still draws all three, because on the board they are full.
  """
  @spec band([term()], String.t(), (map() -> map()), map()) :: map()
  def band([], _title, _builder, _series), do: ~MOB"<Spacer size={0} />"

  def band(_rows, title, builder, series) do
    assigns = %{eyebrow: UI.eyebrow(title), content: builder.(series)}

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={26} />
      {@eyebrow}
      {@content}
    </Column>
    """
  end

  @doc false
  def artwork(s) do
    # The three-stop scrim, built out here for the two reasons `Kati.UI.paper_fade/3`
    # builds its two-stop one out: ~MOB is an uppercase sigil, so #{} inside it is
    # literal text, and the page colour is written into the string as `#AARRGGBB`
    # rather than as an `0x` literal — which is why a grep for `0x` never found it
    # and it stayed light while everything around it followed the mode.
    #
    # Every stop is the SAME rgb at a different alpha, including the invisible
    # one. Compose interpolates in straight RGBA, so fading to `#00FFFFFF` or to
    # transparent black would tint the middle of the band; only the page colour
    # at alpha 0 stays invisible along its whole length. `rem/2` rather than a
    # Bitwise import: the low 24 bits of an 0xAARRGGBB integer are the RGB.
    rgb =
      Palette.paper()
      |> rem(0x1000000)
      |> Integer.to_string(16)
      |> String.pad_leading(6, "0")

    fade = "to_top #FF#{rgb} 4% #B3#{rgb} 44% #00#{rgb}"

    # Two locale notes on the two `Text`s below, since neither fits inside the
    # sigil (a `#` at the top level of a ~MOB is not a comment):
    #
    #   * The 28pt title keeps its `line_height={1.05}` and takes NO `max_lines`.
    #     A display heading that can only ever hold translated copy gets clamped
    #     to one line so a longer Persian word cannot wrap — this one holds
    #     `CachedTitle.title`, which is a provider's title and routinely longer
    #     than the board's three words. The tight leading is there precisely
    #     because it is expected to wrap, and clamping it would truncate the one
    #     thing the page is about. Only the TRACKING goes, which is the part
    #     Persian actually breaks on: `letter_spacing` prises apart the joins
    #     between Arabic-script letters, so `Kati.Locale.tracking/1` returns 0
    #     under `:fa` — and the fallback title IS translated copy (*بی‌عنوان*).
    #
    #   * The meta line is drawn in `mono`, and `kati_mono.ttf` carries no
    #     Persian glyph and none of U+06F0–U+06F9 either. Since
    #     `meta_line/1` now answers `۲۰۲۴ · DRAMA, MYSTERY · ۳ فصل · ۲۶ قسمت`,
    #     the face has to follow the STRING rather than the reader — a line that
    #     is still pure ASCII (genres alone) stays in DM Mono in both scripts,
    #     which is what `Kati.Locale.mono_face/1` is for.
    ~MOB"""
    <Box fill_width={true} height={270} background={Palette.track_off()}>
      {Kati.Screens.SeriesMeta.hero_art(s.seed)}
      <Box fill_width={true} fill_height={true} align="bottom">
        <Box fill_width={true} height={150} gradient={fade} />
      </Box>
      <Box fill_width={true} fill_height={true} align="bottom">
        <Column fill_width={true} padding_left={21} padding_right={21} padding_bottom={4}>
          <Text
            text={s.title}
            text_size={28}
            max_font_scale={1.6}
            font_weight="extrabold"
            letter_spacing={Kati.Locale.tracking(-0.035)}
            line_height={1.05}
            text_color={:on_surface}
          />
          <Spacer size={8} />
          <Text
            text={s.meta}
            font_family={Kati.Locale.mono_face(s.meta)}
            text_size={11}
            text_color={Palette.meta()}
            max_lines={2}
          />
        </Column>
      </Box>
    </Box>
    """
  end

  @doc false
  def hero_art(seed \\ nil) do
    case art_for(seed) do
      nil ->
        ~MOB"<Spacer size={0} />"

      src ->
        ~MOB"""
        <Image src={src} fill_width={true} height={270} content_mode="fill" />
        """
    end
  end

  # The board's own still when there is no seed to look one up by, and
  # `Kati.Design.Images.path/2` otherwise — which answers a downloaded provider
  # file for a real `poster_path` and the design export for a drawing's seed,
  # in one call. 900x620 rather than screen 04's 900x740: this header is 270pt,
  # and that is the crop the export names for it.
  defp art_for(nil), do: Sample.hero_art()
  defp art_for(seed), do: Kati.Design.Images.path(seed, {900, 620})

  # The default is a `gettext/1` call and not the bare word, at all three
  # arities below. A default argument is evaluated on every call rather than
  # frozen at compile time — unlike a module attribute, which is the trap this
  # fold keeps meeting — so the pill says *سریال* on a Persian page even when
  # nothing pushed a `:back` label at all. `Kati.Screens.Pushed.back_label/2`
  # translates the assigned one at runtime, so the two halves agree.
  @doc false
  def chrome(label \\ gettext("Series")) do
    back = {self(), :back}
    fill = Palette.card()

    ~MOB"""
    <Box fill_width={true} fill_height={true} align="top">
      <Row fill_width={true} padding_left={21} padding_right={21} padding_top={60} align="center">
        {Kati.Screens.SeriesMeta.back_pill(back, fill, label)}
        <Spacer weight={1.0} />
        {Kati.Screens.SeriesMeta.more_disc(fill)}
      </Row>
    </Box>
    """
  end

  @doc """
  The floating back pill — Mishka's Pill.

  Icon plus label on a lifted lozenge is a pill with `content`; the tap is the
  pill's own `on_tap`, which takes the already-wired `{pid, tag}` untouched.

  Same pixels. `padding: 0` alongside `padding_left: 12` and
  `padding_right: 16` reproduces the Row's asymmetric 12/16 with 0 top and
  bottom — the bridge resolves an unstated edge against the uniform, and the
  uniform is 0 — and because it pads before it sizes, `height: 44` is still 44.
  `shadow` rides the root Box, the node that also carries the fill, the radius
  and the tap, so the lift is cast around the same 22pt silhouette. The three
  `Row`s the pill builds (its body, the content wrapper, and the empty one
  where a ✕ would sit) all hug and all centre vertically by default, so the
  chevron, the 6pt gap and `Library` sit exactly where they sat.
  """
  @spec back_pill(term(), non_neg_integer(), String.t()) :: map()
  def back_pill(back, fill, label \\ gettext("Series")) do
    MishkaPill.pill(
      [
        background: fill,
        shadow: Kati.Theme.shadow_button(),
        corner_radius: 22,
        height: 44,
        padding: 0,
        padding_left: 12,
        padding_right: 16,
        align: :center,
        on_tap: back
      ],
      Kati.Screens.SeriesMeta.back_content(label)
    )
  end

  @doc false
  def back_content(label \\ gettext("Series")) do
    assigns = %{back: label}

    [
      Kati.UI.symbol(Kati.Screens.Pushed.back_glyph(), size: 17),
      ~MOB"<Spacer size={6} />",
      ~MOB"""
      <Text
        text={@back}
        text_size={13.5}
        font_weight="semibold"
        letter_spacing={Kati.Locale.tracking(-0.01)}
        text_color={:on_surface}
      />
      """
    ]
  end

  @doc """
  The floating overflow disc — Mishka's Action Icon, now that a disc can float.

  A floating disc is defined by its shadow: `Kati.Theme.shadow_button()` is
  what separates this control from a flat patch of card colour on the still
  behind it, and `action_icon/2` had no way to say it until now.

  Nothing moves. `shape: :circle` is an exact `size / 2`, so 44 rounds at 22 as
  the literal did; the fill and the shadow pass straight through; and the glyph
  is the same `Kati.UI.symbol/2` Text, now inside a Row that hugs it — a
  hugging Row's only child, centred in a Box of the declared size, lands where
  the bare centred Text did.
  """
  @spec more_disc(non_neg_integer()) :: map()
  def more_disc(fill) do
    MishkaActionIcon.action_icon(
      [
        size: 44,
        shape: :circle,
        variant: :filled,
        background: fill,
        shadow: Kati.Theme.shadow_button()
      ],
      [Kati.UI.symbol("more_horiz", size: 21)]
    )
  end

  @doc """
  Board 311's trio: what the reader's own columns can answer about this show.

  `Yours` is the average of the episode ratings they left — `Kati.Media.Watch`
  is where a rating in this app is actually written, and averaging the episodes
  is the only show-level score the store holds. It draws a dash when they have
  rated none, rather than a zero, because *not rated* and *rated zero* are
  different facts.

  `Episodes` is the same numerator screen 04 draws — ticks, not
  `progress_episode`, which is a bookmark inside a season rather than a total.
  `Hours` is those ticks against the runtime the cache holds for each.

      iex> Kati.Screens.SeriesMeta.hours_label(0)
      "—"

      iex> Kati.Screens.SeriesMeta.hours_label(1080)
      "18h"
  """
  @spec yours(TrackedTitle.t() | nil, CachedTitle.t() | nil) :: [map()]
  def yours(nil, _cached), do: []

  def yours(tracked, cached) do
    watches = Kati.Screens.SeriesMeta.watches_for(tracked)
    rated = Enum.filter(watches, &is_integer(&1.rating))
    total = cached && cached.episode_count

    [
      %{
        label: gettext("Yours"),
        value:
          if(rated == [],
            do: "—",
            else:
              Kati.Rating.Scale.label(Enum.sum(Enum.map(rated, & &1.rating)) / length(rated) / 2)
          ),
        # The star is the drawing's, and board 14 tints only `Yours`. It is
        # dropped when there is no rating, because a star over a dash is a
        # rating of nothing rather than no rating.
        color: Palette.accent(),
        star?: rated != []
      },
      %{
        label: gettext("Episodes"),
        # Both halves in the reader's own digits. The slash and its two spaces
        # are the drawing's and stay: a fraction is written left to right in
        # Persian as well, and the bidi algorithm keeps `۷ / ۲۶` in that order
        # inside an RTL page because digits and a solidus resolve as one number
        # run. No msgid, because there is no WORD here to translate.
        value:
          if(is_integer(total) and total > 0,
            do: "#{Kati.Locale.number(length(watches))} / #{Kati.Locale.number(total)}",
            else: Kati.Locale.number(length(watches))
          ),
        color: Palette.ink(),
        star?: false
      },
      %{
        label: gettext("Hours"),
        value:
          Kati.Screens.SeriesMeta.hours_label(Kati.Screens.SeriesMeta.minutes(watches, cached)),
        color: Palette.ink(),
        star?: false
      }
    ]
  rescue
    _error -> []
  end

  @doc false
  @spec watches_for(TrackedTitle.t()) :: [term()]
  def watches_for(tracked) do
    Kati.Media.Watch
    |> Ash.Query.for_read(:for_title, %{tracked_title_id: tracked.id})
    |> Ash.read!()
  rescue
    _error -> []
  end

  @doc false
  @spec minutes([term()], CachedTitle.t() | nil) :: non_neg_integer()
  def minutes(watches, cached) do
    # Per EPISODE, and that is the whole subtlety. `Kati.Media.Watch` records
    # WHEN, not how long, so the runtime has to come from the cache — and
    # `CachedTitle.runtime_minutes` is a FILM's runtime and `nil` on every
    # series, which is why this first drew a dash on Severance. Each tick names
    # the episode it watched, so the runtime is that episode's; the title's is
    # the fallback for a film, and a tick with neither contributes nothing
    # rather than a guess.
    by_episode =
      Kati.Media.CachedEpisode
      |> Ash.read!()
      |> Map.new(&{&1.source_id, &1.runtime_minutes})

    fallback = cached && cached.runtime_minutes

    Enum.reduce(watches, 0, fn watch, sum ->
      each = Map.get(by_episode, watch.episode_source_id) || fallback || 0

      sum + each
    end)
  rescue
    _error -> 0
  end

  # `18h` and `45m` are the catalogue's own two msgids — `Kati.Stats.Sample`
  # and `Kati.Screens.Library` already ask for them and Persian already answers
  # `%{n} ساعت` and `%{n} دقیقه`. A suffix concatenated onto a number cannot be
  # translated at all (the unit goes in front in some scripts and takes a space
  # in this one), so the unit moves inside the msgid and the number becomes a
  # binding.
  #
  # The em dash stays a bare `—`: it is punctuation, it means *not rated* in
  # both scripts, and a one-character msgid is exactly what
  # `mix gettext.merge` fuzzy-matches against every sentence that ends in one.
  @doc false
  @spec hours_label(non_neg_integer()) :: String.t()
  def hours_label(minutes) when is_integer(minutes) and minutes >= 60,
    do: gettext("%{n}h", n: Kati.Locale.number(div(minutes, 60)))

  def hours_label(minutes) when is_integer(minutes) and minutes > 0,
    do: gettext("%{n}m", n: Kati.Locale.number(minutes))

  def hours_label(_none), do: "—"

  @doc false
  def ratings(%{ratings: []}), do: ~MOB"<Spacer size={0} />"

  def ratings(s) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {s.ratings
         |> Enum.map(&Kati.Screens.SeriesMeta.rating_card/1)
         |> Enum.intersperse(Kati.Screens.SeriesMeta.rating_gap())}
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc false
  def rating_gap, do: ~MOB"<Spacer size={9} />"

  # Centred with weighted Spacers on both sides rather than text_align, because
  # text_align makes a Text fill its row in this bridge and the card is a
  # weighted column — the two together distort the row (screen 08's defect 2).
  #
  # The VALUE is put into the reader's digits here, at the draw, rather than
  # where it is computed. The trio arrives from two owners: `yours/2` above,
  # which already localises what it builds, and `Kati.Screens.SeriesMeta.Sample`
  # for the board, whose `4.5`, `8.1` and `96%` are frozen Latin strings in a
  # module this screen does not own. One call at the one place both arrive
  # covers both, and `Kati.Locale.number/1` is idempotent — it converts digits
  # and the decimal point and leaves everything else, so running it over a
  # figure that is already `۴٫۵` changes nothing.
  @doc false
  def rating_card(r) do
    ~MOB"""
    <Box weight={1.0}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={16}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={12}
      >
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          <Text
            text={Kati.UI.eyebrow_label(r.label)}
            font_family={Kati.Locale.mono_face(r.label)}
            text_size={9.5}
            letter_spacing={Kati.Locale.tracking(0.12)}
            text_color={Palette.muted()}
            max_lines={1}
          />
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={6} />
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          {Kati.Screens.SeriesMeta.rating_star(r)}
          <Text
            text={Kati.Locale.number(r.value)}
            text_size={17}
            font_weight="bold"
            text_color={r.color}
            max_lines={1}
          />
          <Spacer weight={1.0} />
        </Row>
      </Column>
    </Box>
    """
  end

  @doc false
  def rating_star(%{star?: false}), do: ~MOB"<Spacer size={0} />"

  def rating_star(r) do
    ~MOB"""
    <Row align="center">
      {Kati.UI.symbol("star", size: 15, color: r.color, fill: true)}
      <Spacer size={4} />
    </Row>
    """
  end

  # The drawing sets `more` inline at the end of the paragraph. Mob has no
  # inline span, so it follows on its own line in the design's own muted grey.
  # Recorded rather than hidden: it is the one place this screen is not the
  # drawing.
  @doc false
  def synopsis(s) do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={s.synopsis}
        text_size={14}
        line_height={Kati.Locale.leading(1.6)}
        text_color={Palette.cream_body()}
      />
      {Kati.Screens.SeriesMeta.more_link(s.more)}
    </Column>
    """
  end

  @doc """
  The drawing's `more` under the synopsis, when there is more.

  It expands nothing — there is no expander on this screen and never was — so
  on the board it is a word under three clamped lines and on a real title,
  whose `overview` is drawn whole, it would be a control promising a rest of a
  text that is already all there. `nil` is the real title's answer.

  The argument is the PRESENCE of the word and no longer the word itself.
  mishka-group/kati#103: `more` arrives as `Kati.Screens.SeriesMeta.Sample`'s
  string `"more"`, and a msgid has to be a literal at the call site — so
  `gettext(label)` does not compile and the board's own word would have come
  out Latin on a Persian page no matter what the catalogue held. The one thing
  this value has ever been used for is *is there more*, which is a boolean
  question, so the copy is now this screen's and the fixture keeps the flag.
  """
  @spec more_link(String.t() | nil) :: map()
  def more_link(nil), do: ~MOB"<Spacer size={0} />"

  def more_link(_present) do
    # `pgettext/2`: *more* is four letters and `mix gettext.merge` fuzzy-matches
    # a msgid that short against any sentence containing it.
    assigns = %{label: pgettext("synopsis expander", "more")}

    ~MOB"""
    <Row align="center">
      <Text
        text={@label}
        text_size={14}
        line_height={Kati.Locale.leading(1.6)}
        text_color={Palette.eyebrow()}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc """
  The Trailer button and its two discs, when there is a trailer.

  No video, no link, no column — the moduledoc's fourth bullet — so on a real
  title `trailer` is `nil` and the row goes with it. The bookmark and label
  discs go too: neither has an `on_tap`, so what would be left is a play
  button that plays nothing beside two shapes that do nothing.

  `trailer` is read as the PRESENCE of one and no longer as the button's word,
  for `more_link/1`'s reason: it arrives as `Kati.Screens.SeriesMeta.Sample`'s
  string `"Trailer"`, and `gettext(a_variable)` is not a msgid. The two uses
  were always one value doing two jobs — the `nil` clause above has only ever
  asked the first — so the label is the screen's copy now and the fixture keeps
  the flag. Nothing moves in Latin: the word it held was this one.
  """
  def actions(%{trailer: nil}), do: ~MOB"<Spacer size={0} />"

  def actions(_s) do
    # `play_arrow` is NOT `Kati.Locale.forward_glyph()` and does not mirror. A
    # forward arrow points where the READER is going and so follows the page;
    # a transport control points at the direction the TAPE runs, which is the
    # same direction in every script. Material's own mirroring guidance carves
    # media playback out for exactly this reason, and every Persian player the
    # reader already has draws it pointing right.
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={16} />
      <Row fill_width={true} align="center">
        <Box weight={1.0}>
          <Row
            fill_width={true}
            height={48}
            corner_radius={20}
            background={Palette.ink_fill()}
            shadow="0 12 24 -12 #D91A1917"
            align="center"
          >
            <Spacer weight={1.0} />
            {Kati.UI.symbol("play_arrow", size: 20, color: Palette.on_ink(), fill: true)}
            <Spacer size={8} />
            <Text
              text={gettext("Trailer")}
              text_size={13.5}
              font_weight="bold"
              text_color={Palette.on_ink()}
              max_lines={1}
            />
            <Spacer weight={1.0} />
          </Row>
        </Box>
        <Spacer size={10} />
        {Kati.Screens.SeriesMeta.action_disc("bookmark")}
        <Spacer size={10} />
        {Kati.Screens.SeriesMeta.action_disc("label")}
      </Row>
    </Column>
    """
  end

  @doc false
  def action_disc(icon) do
    ~MOB"""
    <Box
      width={48}
      height={48}
      corner_radius={20}
      background={Palette.card()}
      shadow={Kati.Theme.shadow_card_soft()}
      align="center"
    >
      {Kati.UI.symbol(icon, size: 20)}
    </Box>
    """
  end

  # Four across on weights rather than four declared 81s. The drawing says
  # `flex:1`, and 81 was only ever what that resolved to on the 402dp frame it
  # was drawn at: 81*4 + 12*3 = 360, the content width inside the 21pt gutters
  # *there*. On a 411dp device the column is 369 and the same four cells still
  # measured 360, leaving a 9dp gutter on the trailing edge that belonged to
  # nothing. The 12pt gaps are fixed so they come off the top; the weights
  # divide whatever is actually left.
  @doc false
  def cast(s) do
    ~MOB"""
    <Row fill_width={true} align="top">
      {s.cast
       |> Enum.map(&Kati.Screens.SeriesMeta.cast_member/1)
       |> Enum.intersperse(Kati.Screens.SeriesMeta.cast_gap())}
    </Row>
    """
  end

  @doc false
  def cast_gap, do: ~MOB"<Spacer size={12} />"

  @doc false
  def cast_member(c) do
    ~MOB"""
    <Column weight={1.0}>
      <Box
        fill_width={true}
        aspect_ratio={1.0}
        corner_radius={999}
        background={Palette.placeholder()}
        shadow={Kati.Theme.shadow_card_soft()}
      >
        {Kati.Screens.SeriesMeta.portrait(c.seed)}
      </Box>
      <Spacer size={8} />
      <Text
        text={c.name}
        text_size={11}
        font_weight="semibold"
        line_height={1.3}
        text_color={:on_surface}
        text_align="center"
      />
      <Spacer size={2} />
      <Text
        text={c.role}
        font_family={Kati.Locale.mono_face(c.role)}
        text_size={9.5}
        text_color={Palette.muted()}
        text_align="center"
        max_lines={1}
      />
    </Column>
    """
  end

  # The portrait tracks the cell, not the old 81. A Box aligns its child
  # top-START, so an 81pt image inside a cell that now measures 83 would leave
  # the placeholder's #E4E0D9 showing as a sliver down the trailing edge.
  # `content_mode="fill"` is ContentScale.Crop, so the face is cropped to the
  # frame rather than stretched into it.
  #
  # `aspect_ratio={1.0}`, not `height={81}`: the drawing says
  # `width:100%;aspect-ratio:1`, and 81 was only that ratio's answer on the
  # 402pt frame. At 411dp the cell measures 83.25, so a fixed 81 drew an
  # ellipse — wider than it was tall — under a radius that had also been
  # hard-coded to half of the old number.
  @doc false
  def portrait(seed) do
    case Sample.face(seed) do
      nil ->
        ~MOB"<Spacer size={0} />"

      src ->
        ~MOB"""
        <Image src={src} fill_width={true} aspect_ratio={1.0} corner_radius={999} content_mode="fill" />
        """
    end
  end

  @doc false
  def where(s) do
    last = length(s.where) - 1

    ~MOB"""
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
      {s.where
       |> Enum.with_index()
       |> Enum.map(fn {row, i} -> Kati.Screens.SeriesMeta.where_row(row, i < last) end)}
    </Column>
    """
  end

  @doc false
  def where_row(row, rule?) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={13} padding_bottom={13}>
        {Kati.Screens.SeriesMeta.where_badge(row.badge)}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text
            text={row.name}
            text_size={13}
            font_weight="semibold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={2} />
          <Text text={row.line} text_size={11} text_color={Palette.sub()} max_lines={1} />
        </Column>
        <Spacer size={13} />
        {Kati.Screens.SeriesMeta.price(row.price)}
      </Row>
      {Kati.Screens.SeriesMeta.hairline(rule?)}
    </Column>
    """
  end

  @doc """
  A service's two-letter badge — Mishka's Theme Icon.

  "A themed container around exactly one icon" is the whole of what this Box
  was, so the component is a rename rather than a rewrite. With no `id` to tag
  and the mark passed as a child, `theme_icon/2` emits one Box whose props map
  is the hand-rolled one key for key — `width: 32, height: 32, align: :center,
  corner_radius: 10, background: #EFECE7` — around the same mono Text.
  `variant: :filled` with a raw `color` puts the design's own value in the fill
  rather than a theme token, and the Text keeps the colour it was written with,
  because a caller-supplied icon always does.
  """
  @spec where_badge(String.t()) :: map()
  def where_badge(badge) do
    MishkaThemeIcon.theme_icon(
      [variant: :filled, color: Palette.paper(), size: 32, radius: 10],
      [Kati.Screens.SeriesMeta.where_mark(badge)]
    )
  end

  # The badge is a service's own initial, so it is Latin on a Persian page for
  # the reason `Lumen+` is: it is a name, and `where_rows/1` takes it off a
  # provider string no msgid reaches. `mono_face/1` asks the STRING and answers
  # `mono` for it — the call is here so that a provider whose name is not ASCII
  # gets Vazirmatn rather than an empty box, which is what DM Mono draws for
  # every glyph it has not got.
  @doc false
  def where_mark(badge) do
    ~MOB"""
    <Text
      text={badge}
      font_family={Kati.Locale.mono_face(badge)}
      text_size={13}
      text_color={:on_surface}
      max_lines={1}
    />
    """
  end

  # `where_rows/1` answers `nil` here on every real row — TMDB says *where* and
  # never *how much* — so this draws only the board's `£14.99` and `owned`.
  #
  # `Kati.Locale.ltr/1` all the same, and it is not decoration: a price is a
  # Latin run whose currency mark is a bidi-neutral, so on an RTL page the
  # algorithm resolves the `£` against the PAGE and lays it out at the other
  # end — `14.99£`, the same failure screen 83's licence notices had with their
  # full stops. The isolate makes the run resolve against itself.
  #
  # The face stays the hardcoded `mono` and does NOT go through
  # `Kati.Locale.mono_face/1`, which is the one slot on this page where it
  # should not. That function decides by asking whether the string is pure
  # ASCII, which is the right question for a provider's NAME and the wrong one
  # for a figure: `£` is U+00A3, so a perfectly Latin price would test as
  # non-ASCII and be handed to Vazirmatn on a Persian page — DM Mono has the
  # sterling sign and the drawing sets this cell in it. The digits stay Latin
  # for the same reason, which is `Kati.Locale.number/1`'s own rule about
  # figures in mono.
  @doc false
  def price(nil), do: ~MOB"<Spacer size={0} />"

  def price(value) do
    ~MOB"""
    <Text
      text={Kati.Locale.ltr(value)}
      font_family="mono"
      text_size={11}
      text_color={Palette.muted()}
      max_lines={1}
    />
    """
  end

  # Mishka's Separator, at the design's own colour and thickness. `render:
  # :box` is not optional — the default `:divider` is Material 3's antialiased
  # drawLine and softens the bottom pixel row of every rule in the where-card.
  # See `Kati.Screens.Film.hairline/1` for the measurement.
  @doc false
  def hairline(false), do: ~MOB"<Spacer size={0} />"

  def hairline(true),
    do: MishkaSeparator.separator(color: Palette.hairline(), thickness: 1, render: :box)

  # Wrapped by MEASUREMENT, not by count — mishka-group/kati#98.
  #
  # This was `Enum.chunk_every(3)` and a comment saying *three then two, which
  # is where the browser breaks these five labels at a 360pt content width*.
  # That sentence is the defect: it is one browser, one width and one text
  # size, hard-coded into the data. At 235% text the fourth label does not fit
  # beside two others and the row clipped it; on a wider phone the third row
  # stood empty. #98 is the ticket for exactly this, and its own words are
  # *"a node that lays its children out and breaks when they do not fit removes
  # the count rule entirely"*.
  #
  # `<Wrap>` is that node. It arrived in mob 0.8.0 (MOB-175) with its Android
  # renderer — `FlowRow` — in the mob_new 0.4.33 template, which is why the
  # bridge had to be merged forward before this line could be written. The
  # chips measure themselves, so the break moves with the text size, the
  # device width and the tag labels, none of which this module now needs to
  # know.
  #
  # `spacing` is the gap along a run and `run_spacing` the gap between runs,
  # so the 7pt `Spacer` and the 7pt `Box` the two old helpers drew are now the
  # two props. The add-tag slot still carries its own flag rather than being
  # recognised by its label, so a user tag reading "+ tag" is still drawn as a
  # tag.
  @doc false
  def tags(s) do
    assigns = %{
      tags:
        (Enum.map(s.tags, &{&1, false}) ++ [{s.add_tag, true}])
        |> Enum.map(fn {label, add?} -> Kati.Screens.SeriesMeta.tag(label, add?) end)
    }

    ~MOB"""
    <Wrap fill_width={true} spacing={7} run_spacing={7}>
      {@tags}
    </Wrap>
    """
  end

  @doc """
  One tag — Mishka's Pill, in both of its two shapes.

  A pill, not a chip: a user tag is not selected and does not toggle, and the
  trailing slot the design gives it is nothing at all. (The web pill's ✕ is
  what a *removable* tag would use; this drawing does not draw one, so
  `with_remove` stays off and its slot stays an empty, zero-wide `Row`.)

  Both shapes are the same node with different props, which is the point of
  adopting it: the add-tag is a 1.5pt outline over nothing, the user tags are
  card fill under the design's soft card shadow, and `border_color` /
  `border_width` / `background` / `shadow` say so directly.

  Nothing moves. `padding: 0` with the two side edges set gives the bridge the
  same 12/0 and 13/0 the Rows carried — an unstated edge resolves against the
  uniform, and the uniform is 0 — and since padding is applied before size,
  `height: 30` still measures 30. The add-tag passes `background: :transparent`
  where the Row simply had no fill; a fully transparent rounded rect paints
  nothing, so the outline is still the only mark. The pill's root `Box` hugs
  (`fill_width={false}`, K-17) as the Row did, and its inner `Row`s hug and
  centre by default, so a single centred label lands where it already was.
  """
  @spec tag(String.t(), boolean()) :: map()
  def tag(label, true) do
    MishkaPill.pill(
      label: label,
      background: :transparent,
      color: Palette.eyebrow(),
      border_color: Palette.border_strong(),
      border_width: 1.5,
      corner_radius: 15,
      height: 30,
      padding: 0,
      padding_left: 12,
      padding_right: 12,
      align: :center,
      text_size: 12,
      font_weight: :semibold
    )
  end

  def tag(label, false) do
    MishkaPill.pill(
      label: label,
      background: Palette.card(),
      color: Palette.ink_soft(),
      shadow: Kati.Theme.shadow_card_soft(),
      corner_radius: 15,
      height: 30,
      padding: 0,
      padding_left: 13,
      padding_right: 13,
      align: :center,
      text_size: 12,
      font_weight: :semibold
    )
  end

  def handle_info({:tap, :back}, socket), do: {:noreply, Kati.Screens.Resume.pop(socket)}
  def handle_info(_msg, socket), do: {:noreply, socket}
end
