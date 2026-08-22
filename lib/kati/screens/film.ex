defmodule Kati.Screens.Film do
  @moduledoc """
  Screen 08 — a film, pushed under Library.

  Shares screen 04's shape — 330pt artwork, chrome floating at 60pt, the title
  on the gradient — and diverges where a film differs from a series: a watched
  pill above the title instead of a season card, a rating, and a note.

  The note sits on cream. The design's own caption says that is deliberate:
  it is "the one place the palette warms up", the same treatment the hero card
  gets on Home, and it marks the user's own words as different from metadata.

  ## Where the data comes from

  `Kati.Media`, through `film/0`. This screen is the durable half of that
  domain drawn as a page: `Kati.Media.Watch`'s own moduledoc names it twice —
  *"screen 08 does not [know the hour]"* is why `watched_on` is a date beside
  `watched_at`, and the `[:tracked_title_id, :watched_at]` index is annotated
  *"screen 08's 'seen 2 times'"*. The rating, the note, the watch date and the
  count are all rows the user made, so they are read rather than frozen.

  Three reads, never one per row: the film shelf (`Kati.Media.TrackedTitle`'s
  own `:shelf` action, which is where *keeps history, hides from shelf* is
  enforced), the one cache row it names, and that title's watches. The cache is
  reached by `{source, source_id}` because that is what a tracked row holds —
  a value pair, not a foreign key — so an evicted poster cannot take the user's
  memory of the film down with it.

  **Which film.** Nothing hands this screen an id: `Kati.Screens.Library` taps a
  poster and pushes `Kati.Screens.Film` with no title attached, exactly as
  `Kati.Screens.MealsToday` pushes `Kati.Screens.Meal`. So the referent is the
  one the shelf itself puts first — the most recently touched film — and it is
  `:shelf` that decides that, not an ordering written out here.

  With nothing tracked there is no such film and `Kati.Library.Sample` is drawn
  instead, the values `.scratch/design/screens/08.html` was captured from.
  FIDELITY's rule: *missing data is not a reason for a blank screen*. The Sample
  module stays exactly where it is; it is the fallback and the fixture, not a
  stage this screen has passed through.

  ## What no resource can express, and is therefore not drawn

  Two things on this drawing have no store anywhere in the app, and neither is
  invented for a real film. Both are drawn in full on the fallback, because
  there they are the drawing rather than a claim about a title.

    * **The whole `Where to watch` card.** `Lumen+ · included` and
      `Kino store · £9.99` are availability and pricing, and `Kati.Media` holds
      neither: `Kati.Media.Watch.service` is where the *user* watched something,
      which is a different fact, is per-watch, and carries no price.
      `Kati.Media.CachedTitle` has a poster, a runtime and a release date and no
      offers. A frozen `£9.99` beside a real film is not a placeholder, it is a
      price quoted for a film nobody priced — so `where/1` gets an empty list
      and `where_section/1` takes the eyebrow with it. What this needs is an
      offers resource per `{title, service, region}`, which screen 35's *Region
      & availability* group is the settings half of.
    * **`2025` in the meta line.** `Kati.Media.CachedTitle.next_release_at` is
      the NEXT release; a first-release year would be a new column, and reading
      the next one as the first would print next Tuesday's date as a film's
      year. The line degrades to `1H 52M · DRAMA`, which is `runtime_minutes`
      and `genres` and nothing else.

  Three smaller ones are derived rather than dropped, and each states what it is
  derived from: `seen` counts watches against the user's own `rewatch_number`
  the way `Kati.Screens.Activity` does, the stars are `rating` on the ten-point
  scale halved, and the watched pill is the latest watch's date.
  """
  use Mob.Screen
  import Mob.Sigil

  require Ash.Query

  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaPill
  alias Kati.Components.MishkaSeparator
  alias Kati.Components.MishkaThemeIcon
  alias Kati.Library.Sample
  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Theme.Palette
  alias Kati.UI

  # The row of affordances under the card stack. Labels, not data — the same
  # class of literal as screen 03's `Up next` tile — so they live in the screen
  # beside the markup that draws them rather than being read back out of the
  # fixture, which would be a lie about where a real render's copy came from.
  @actions [{"replay", "Log rewatch"}, {"event", "Schedule"}, {"ios_share", "Share"}]

  def mount(_params, _session, socket) do
    Mob.Theme.set(Kati.Theme.current())
    {:ok, socket |> Mob.Socket.assign(:film, film()) |> Mob.Socket.assign(:menu?, false)}
  end

  @doc """
  The film this screen draws: the user's, or the drawing's.

  The gate is the whole screen rather than each card, for the reason
  `Kati.Screens.Series` gives for not moving half of itself: a page whose title
  is a real film and whose note is somebody else's evening reads as entirely
  real. Either every value is this user's or every value is the drawing's.
  """
  @spec film() :: map()
  def film do
    tracked_film() || drawn_film()
  end

  @doc """
  Screen 08 exactly as it is drawn, from `Kati.Library.Sample`.

  Kept in the fixture rather than inlined here: it is the frame's specification
  and the fixture the tests compare a real render against, and two copies of the
  drawing's copy is exactly how the two drift apart.
  """
  @spec drawn_film() :: map()
  def drawn_film, do: Sample.film()

  @doc """
  The user's own film, shaped for the markup, or `nil` when there is not one.

  `nil` is the ordinary answer on a fresh install and the one `film/0` reads as
  "draw the drawing". A database that cannot be read at all answers `nil` too:
  `Ash.read!` on a device mid-migration raises, and a screen that dies is
  strictly worse than a screen showing the values it was drawn from — the same
  degradation `Kati.Screens.Library.shelf/0` and `Kati.Calendars.Today` make.
  """
  @spec tracked_film() :: map() | nil
  def tracked_film do
    case newest_film() do
      nil -> nil
      tracked -> shaped(tracked, cached_for(tracked), watches_of(tracked))
    end
  rescue
    _ -> nil
  end

  # The top of the film shelf. `:shelf` rather than a filter written out here:
  # it is the action `Kati.Media.TrackedTitle` names for "screens 03, 20 and 21"
  # and it is where archived rows are excluded, so a shelf that forgot the flag
  # would show a title the user hid. `limit(1)` because this screen draws one
  # film and the sort is the action's own.
  defp newest_film do
    TrackedTitle
    |> Ash.Query.for_read(:shelf, %{kind: :movie})
    |> Ash.Query.limit(1)
    |> Ash.read!()
    |> List.first()
  end

  # One read, by the VALUE PAIR the durable half references the cache by. A
  # missing row is the evicted case and is ordinary — see `shaped/3`.
  defp cached_for(%TrackedTitle{source: source, source_id: source_id}) do
    CachedTitle
    |> Ash.Query.filter(source == ^source and source_id == ^source_id)
    |> Ash.read_one!()
  end

  defp watches_of(%TrackedTitle{id: id}) do
    Watch
    |> Ash.Query.for_read(:for_title, %{tracked_title_id: id})
    |> Ash.read!()
  end

  @doc """
  One tracked film in the shape the markup reads, whatever is missing.

  `cached` may be `nil` and `watches` may be empty; both are ordinary states and
  neither is allowed to invent a value.

    * `title` is the cache's, and `Untitled` when the cache row has gone. The
      same answer `Kati.Screens.Activity` gives, and for its reason: the memory
      survived the wipe and the poster did not, so the page says so rather than
      handing the user somebody else's film. (Screen 03 drops such a row instead,
      because there a nameless tile among nine named ones says nothing; here it
      is the whole page and the user's own rating and note are on it.)
    * `seed` is `poster_path`, which for a seeded sample title is the design's
      own picsum seed and for a real one is a provider path
      `Kati.Design.Images.poster/1` will not find. Both degrade to the
      `track_off` rectangle `hero_art/1` already leaves behind.
    * `watched`, `note` and `note_date` are `nil` when nothing was logged, and
      each draws nothing at all rather than an empty pill or a blank cream card.
    * `where` is `[]`, always. See the moduledoc: there is no offers resource.
  """
  @spec shaped(TrackedTitle.t(), CachedTitle.t() | nil, [Watch.t()]) :: map()
  def shaped(tracked, cached, watches) do
    zone = Kati.Time.device_zone()
    dated = Enum.sort_by(watches, &sort_key(&1, zone), {:desc, Date})
    noted = Enum.find(dated, &noted?/1)

    %{
      title: title_of(cached),
      seed: seed_of(tracked, cached),
      meta: meta_line(cached),
      watched: watched_label(tracked, dated, zone),
      stars: star_count(tracked.rating),
      seen: seen_line(watches),
      note_date: noted && note_date(noted, zone),
      note: noted && noted.review,
      where: [],
      actions: @actions
    }
  end

  defp title_of(%CachedTitle{title: title}) when is_binary(title) and title != "", do: title
  defp title_of(_cached), do: "Untitled"

  # `Kati.Seeds` writes the design seed straight into `poster_path` — "not a
  # TMDB path: the sample artwork is resolved by seed" — and `sample_source_id/1`
  # is the other half of that convention, so a row whose cache has been evicted
  # can still find its picture.
  defp seed_of(tracked, cached) do
    case cached do
      %CachedTitle{poster_path: path} when is_binary(path) and path != "" -> path
      _ -> Kati.Seeds.sample_seed(tracked.source_id)
    end
  end

  # `2025 · 1H 52M · DRAMA` minus the year, which nothing stores. Both halves
  # are nullable — a provider can decline either — and an absent half is left
  # out rather than spelled as a dash, so the line is `DRAMA` alone or empty.
  defp meta_line(cached) do
    [runtime_label(cached), genre_label(cached)]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" · ")
  end

  defp runtime_label(%CachedTitle{runtime_minutes: m}) when is_integer(m) and m > 0 do
    case {div(m, 60), rem(m, 60)} do
      {0, minutes} -> "#{minutes}M"
      {hours, 0} -> "#{hours}H"
      {hours, minutes} -> "#{hours}H #{minutes}M"
    end
  end

  defp runtime_label(_cached), do: nil

  defp genre_label(%CachedTitle{genres: g}) when is_binary(g) and g != "", do: String.upcase(g)
  defp genre_label(_cached), do: nil

  # The green pill is an assertion that the film has been seen, so it needs
  # something that asserts it. A dated watch gives the drawing's own
  # `Watched 12 Aug`; a watch with no date is the "I have seen this, I do not
  # remember when" `Kati.Media.Watch` describes, and says so without one; a
  # title the user marked finished with nothing logged is the same statement
  # made on the shelf. Anything else has not been watched and gets no pill.
  defp watched_label(tracked, dated, zone) do
    cond do
      date = dated |> Enum.find_value(&watch_date(&1, zone)) ->
        "Watched " <> Calendar.strftime(date, "%-d %b")

      dated != [] ->
        "Watched"

      tracked.status == :finished ->
        "Watched"

      true ->
        nil
    end
  end

  # Ten-point scale to whole glyphs, as `Kati.Screens.Activity.star_count/1`
  # does it: `9` is four and a half stars and this row draws whole ones, so it
  # draws four. Rounding 9 up to five would claim half a star nobody gave. An
  # unrated film is five empty stars, which is what "you have not rated this"
  # looks like — the card is the user's own rating and is never hidden.
  defp star_count(rating) when is_integer(rating), do: div(rating, 2)
  defp star_count(_rating), do: 0

  # `2 times`. Rows counted against the user's own `rewatch_number`, which
  # `Kati.Media.Watch` says exists precisely for the history that predates Kati:
  # someone who saw a film twice before installing and once since has one row
  # claiming "3rd", and counting rows alone would print 1. Same arithmetic as
  # screen 15's rewatch card, and deliberately the same, because the two numbers
  # are the same fact and must not disagree.
  defp seen_line(watches) do
    claimed =
      watches
      |> Enum.map(& &1.rewatch_number)
      |> Enum.filter(&is_integer/1)
      |> Enum.max(fn -> 0 end)

    case max(length(watches), claimed) do
      0 -> "never"
      1 -> "1 time"
      n -> "#{n} times"
    end
  end

  # A watch with something written in it. The drawing's cream card is the user's
  # own words; a watch with a rating and no review has nothing to put in it.
  defp noted?(%Watch{review: review}), do: is_binary(review) and String.trim(review) != ""

  # `Note · 12 Aug`, and `Note` alone for a review the user never dated.
  defp note_date(watch, zone) do
    case watch_date(watch, zone) do
      nil -> "Note"
      date -> "Note · " <> Calendar.strftime(date, "%-d %b")
    end
  end

  # `watched_on` first: it is the date-valued half, and `Kati.Media.Watch` keeps
  # the two apart because storing "watched on 12 August" as midnight moves it a
  # day the moment the user flies.
  #
  # `nil` for a watch that carries neither, and that `nil` is the whole reason
  # this is separate from `sort_key/2`: "I have seen this, I do not remember
  # when" is a real answer, and a sentinel date substituted for it would come
  # back out of `watched_label/3` as a film watched on the first of January.
  defp watch_date(%Watch{watched_on: %Date{} = date}, _zone), do: date

  defp watch_date(%Watch{watched_at: %DateTime{} = at}, zone) do
    at |> Kati.Time.in_zone(zone) |> DateTime.to_date()
  end

  defp watch_date(%Watch{}, _zone), do: nil

  # Newest first, undated last. Only ever compared, never printed.
  defp sort_key(watch, zone), do: watch_date(watch, zone) || ~D[0000-01-01]

  def render(assigns) do
    f = assigns.film

    ~MOB"""
    <Box
      fill_width={true}
      fill_height={true}
      background={:background}
      layout_direction={Kati.Locale.direction_prop()}
    >
      <Scroll>
        <Column fill_width={true}>
          {Kati.Screens.Film.artwork(f)}
          <Column
            fill_width={true}
            padding_left={21}
            padding_right={21}
            padding_top={16}
            padding_bottom={40}
          >
            {Kati.Screens.Film.rating_card(f)}
            {Kati.Screens.Film.note(f)}
            {Kati.Screens.Film.where_section(f)}
            {Kati.Screens.Film.actions(f)}
          </Column>
        </Column>
      </Scroll>
      {Kati.Screens.Film.chrome(assigns.menu?)}
    </Box>
    """
  end

  @doc false
  def artwork(f) do
    ~MOB"""
    <Box fill_width={true} height={330} background={Palette.track_off()}>
      {Kati.Screens.Film.hero_art(f)}
      <Box fill_width={true} fill_height={true} align="bottom">
        {Kati.UI.paper_fade(190)}
      </Box>
      <Box fill_width={true} fill_height={true} align="bottom">
        <Column fill_width={true} padding_left={21} padding_right={21} padding_bottom={6}>
          {Kati.Screens.Film.watched(f.watched)}
          <Text
            text={f.title}
            text_size={30}
            font_weight="extrabold"
            letter_spacing={-0.035}
            line_height={1.05}
            text_color={:on_surface}
          />
          <Spacer size={9} />
          <Text
            text={f.meta}
            font_family="mono"
            text_size={11.5}
            text_color={Palette.meta()}
            max_lines={1}
          />
        </Column>
      </Box>
    </Box>
    """
  end

  @doc """
  The watched pill and the 11pt of air under it, or neither.

  A list rather than a wrapper `Column`, because the sigil flattens an
  interpolated list into its parent: the drawn film gets the same two nodes in
  the same place it already had them, and a film nobody has watched leaves no
  node behind at all rather than an empty lozenge or a stray gap above the
  title. Same move as `Kati.Screens.Activity.group/5`, and for the same reason.
  """
  @spec watched(String.t() | nil) :: [map()]
  def watched(nil), do: []

  def watched(label) do
    [Kati.Screens.Film.watched_pill(label), ~MOB"<Spacer size={11} />"]
  end

  @doc """
  The watched pill over the artwork — Mishka's Pill.

  A pill and not a chip: nothing here is selected or selectable, it is a
  statement about the film, which is exactly the label-on-a-lozenge a pill is.
  The tick and the label ride in as `content`, because a pill's `label` prop
  builds its own Text and this one needs a glyph beside it.

  The pixels are the Row's. `padding: 0` with `padding_left`/`padding_right` at
  11 gives the bridge the same 11/0 edges, and padding is applied before size,
  so `height: 26` measures 26 as it did. The pill's root is a `Box` that passes
  `fill_width={false}` and so hugs (K-17) where the Row hugged; inside it a
  `Row` holds the content — itself wrapped in a hugging `Row` — beside the
  empty, zero-wide `Row` that stands in for the absent ✕. Every one of those
  hugs and every one centres vertically by default, so the tick, the 6pt gap
  and the label land at the offsets they already had.
  """
  @spec watched_pill(String.t()) :: map()
  def watched_pill(label) do
    MishkaPill.pill(
      [
        background: Palette.green_wash(),
        corner_radius: 13,
        height: 26,
        padding: 0,
        padding_left: 11,
        padding_right: 11,
        align: :center
      ],
      Kati.Screens.Film.watched_content(label)
    )
  end

  @doc false
  def watched_content(label) do
    [
      Kati.UI.symbol("check_circle", size: 15, color: Palette.green_text(), fill: true),
      ~MOB"<Spacer size={6} />",
      ~MOB"""
      <Text
        text={label}
        text_size={11.5}
        font_weight="semibold"
        text_color={Palette.green_text()}
        max_lines={1}
      />
      """
    ]
  end

  # `Kati.Design.Images.poster/1` rather than `Kati.Library.Sample.poster/1` —
  # the Sample function is a one-line delegation to it, and a real film's seed
  # now arrives on `Kati.Media.CachedTitle.poster_path` (see `shaped/3`), so
  # routing it through the fixture module would be a lie about where the value
  # came from. Screen 03's `artwork/1` made the same move for the same reason.
  @doc false
  def hero_art(f) do
    case Kati.Design.Images.poster(f.seed) do
      nil ->
        ~MOB"<Spacer size={0} />"

      src ->
        ~MOB"""
        <Image src={src} fill_width={true} height={330} content_mode="fill" />
        """
    end
  end

  @doc false
  def chrome(menu?) do
    back = {self(), :back}
    fill = Palette.chrome_disc()
    # `box-shadow:0 6px 16px -8px rgba(26,25,23,.6)` — this screen floats its
    # chrome over a photograph, so both controls carry the same lift. Neither
    # had one, which is why they read as flat stickers on the still.
    lift = "0 6 16 -8 #991A1917"

    ~MOB"""
    <Box fill_width={true} fill_height={true} align="top">
      <Row fill_width={true} padding_left={21} padding_right={21} padding_top={60} align="center">
        {Kati.Screens.Film.back_pill(back, fill, lift)}
        <Spacer weight={1.0} />
        {Kati.Screens.Film.more_disc(fill, lift, menu?)}
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
  uniform is 0 — and because it pads before it sizes, `height: 42` is still 42.
  `shadow` rides the root Box, which is the node that carries the fill, the
  radius and the tap, so the lift is cast around the same 21pt silhouette. The
  three extra `Row`s the pill builds (its body, the content wrapper, and the
  empty one where a ✕ would sit) all hug and all centre vertically by default,
  so the chevron, the 6pt gap and `Library` sit where they sat.
  """
  @spec back_pill(term(), non_neg_integer(), String.t()) :: map()
  def back_pill(back, fill, lift) do
    MishkaPill.pill(
      [
        background: fill,
        shadow: lift,
        corner_radius: 21,
        height: 42,
        padding: 0,
        padding_left: 12,
        padding_right: 16,
        align: :center,
        on_tap: back
      ],
      Kati.Screens.Film.back_content()
    )
  end

  @doc false
  def back_content do
    [
      Kati.UI.symbol("arrow_back_ios_new", size: 17),
      ~MOB"<Spacer size={6} />",
      ~MOB"""
      <Text
        text="Library"
        text_size={13.5}
        font_weight="semibold"
        letter_spacing={-0.01}
        text_color={:on_surface}
      />
      """
    ]
  end

  @doc """
  The floating overflow disc — Mishka's Action Icon, now that a disc can float.

  This screen's chrome sits over a photograph, so both controls carry the
  design's `box-shadow:0 6px 16px -8px rgba(26,25,23,.6)`; without it the disc
  reads as a flat sticker on the still. `action_icon/2` had no shadow prop and
  so could not draw it, which is the only reason this was a bare Box.

  Nothing moves: `shape: :circle` is an exact `size / 2`, so 42 rounds at 21 as
  the literal did, the fill and the shadow pass straight through, and the glyph
  is the same `Kati.UI.symbol/2` Text inside a Row that hugs it — a hugging
  Row's only child, centred in a Box of the declared size, lands where the bare
  centred Text did.
  """
  @spec more_disc(non_neg_integer(), String.t(), boolean()) :: map()
  def more_disc(fill, lift, menu?) do
    trigger =
      MishkaActionIcon.action_icon(
        [
          size: 42,
          shape: :circle,
          variant: :filled,
          background: fill,
          shadow: lift,
          on_tap: :toggle_menu
        ],
        [Kati.UI.symbol("more_horiz", size: 21)]
      )

    # This disc carried no tag at all — a ⋯ drawn on the still that answered
    # nothing. Screen 33 is the write path for the rating screen 08 displays,
    # and it was reachable only from the gallery.
    Kati.UI.Menu.overflow(
      trigger,
      menu?,
      [Kati.UI.Menu.item("star", "Log a watch", :log_watch)],
      dismiss: :close_menu
    )
  end

  # Two hugging children with a weighted Spacer between them, not a weighted
  # column beside a plain one. The previous version put a width-less Box in the
  # trailing Column: a Box fills width unless `width` is a NUMBER, so it took
  # everything and starved the weight={1.0} column to zero — the card rendered
  # 333dp tall against the drawing's 84 and the stars did not appear at all.
  @doc false
  def rating_card(f) do
    ~MOB"""
    <Row
      fill_width={true}
      background={Palette.card()}
      corner_radius={22}
      shadow={Kati.Theme.shadow_card()}
      padding={17}
      align="center"
    >
      <Column weight={1.0}>
        <Text
          text={String.upcase("Your rating")}
          font_family="mono"
          text_size={10.5}
          letter_spacing={0.16}
          text_color={Palette.eyebrow()}
        />
        <Spacer size={7} />
        {Kati.Screens.Film.stars(f.stars)}
      </Column>
      <Column weight={1.0}>
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          <Text
            text={String.upcase("Seen")}
            font_family="mono"
            text_size={10.5}
            letter_spacing={0.16}
            text_color={Palette.eyebrow()}
            max_lines={1}
          />
        </Row>
        <Spacer size={8} />
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          <Text
            text={f.seen}
            text_size={16}
            font_weight="bold"
            text_color={:on_surface}
            max_lines={1}
          />
        </Row>
      </Column>
    </Row>
    """
  end

  # Material Symbols, not U+2605. Plus Jakarta Sans has no star glyph, so the
  # text version rendered as nothing at all — an empty card rather than a
  # missing-glyph box, which is why it read as a layout bug.
  @doc false
  def stars(filled) do
    ~MOB"""
    <Row align="center">
      {1..5 |> Enum.map(fn i -> Kati.Screens.Film.star(i <= filled) end) |> Enum.intersperse(Kati.Screens.Film.star_gap())}
    </Row>
    """
  end

  # The drawing sets the star line at 22px with `letter-spacing:.1em` — 2.2pt
  # of air after each glyph. Material Symbols carry no tracking of their own.
  @doc false
  def star_gap, do: ~MOB"<Box width={2} height={1} />"

  @doc false
  def star(true), do: Kati.UI.symbol("star", size: 22, color: Palette.accent(), fill: true)
  def star(false), do: Kati.UI.symbol("star", size: 22, color: Palette.accent())

  @doc """
  The cream note card, or nothing.

  The card is the user's own words — the design's caption calls cream *"the one
  place the palette warms up"* precisely to mark them as not metadata — so a
  film with no review has no card, rather than a warm rectangle with an empty
  paragraph in it. The `12` above and the `26` below go with it, which is why
  they are inside the card's own `Column` and not in `render/1`.
  """
  @spec note(map()) :: map() | []
  def note(%{note: nil}), do: []

  def note(f) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={12} />
      <Column fill_width={true} background={Palette.cream()} corner_radius={22} padding={17}>
        <Row fill_width={true} align="center">
          <Text
            text={String.upcase(f.note_date)}
            font_family="mono"
            text_size={10.5}
            letter_spacing={0.16}
            text_color={Palette.cream_meta()}
          />
          <Spacer weight={1.0} />
          {Kati.UI.symbol("edit", size: 17, color: Palette.gold_icon())}
        </Row>
        <Spacer size={9} />
        <Text text={f.note} text_size={14} line_height={1.55} text_color={Palette.cream_body()} />
      </Column>
      <Spacer size={26} />
    </Column>
    """
  end

  @doc """
  The `Where to watch` eyebrow and its card, or neither.

  See the moduledoc: nothing in `Kati.Media` can say a film is on Lumen+ for
  nothing and in the Kino store for £9.99, so a real film has no offers and the
  section is not drawn. An eyebrow over an empty card is the shape
  `Kati.Screens.Activity` already rejects — *"a headed card with no rows inside
  it is a worse answer than no card"* — and here it would be worse still,
  because the drawing's two rows quote a price.

  A list, so the flattened result is the two nodes `render/1` used to name
  itself and the drawn film is unchanged to the node.
  """
  @spec where_section(map()) :: [map()]
  def where_section(%{where: []}), do: []
  def where_section(f), do: [UI.eyebrow("Where to watch"), Kati.Screens.Film.where(f)]

  @doc false
  def where(f) do
    last = length(f.where) - 1

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card()}
      padding_left={15}
      padding_right={15}
      padding_top={4}
      padding_bottom={4}
    >
      {f.where |> Enum.with_index() |> Enum.map(fn {row, i} -> Kati.Screens.Film.where_row(row, i < last) end)}
    </Column>
    """
  end

  @doc false
  def where_row(row, rule?) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={13} padding_bottom={13}>
        {Kati.Screens.Film.where_badge(row.badge)}
        <Spacer size={13} />
        <Text
          text={row.name}
          text_size={13.5}
          font_weight="semibold"
          text_color={:on_surface}
          weight={1.0}
          max_lines={1}
        />
        <Text
          text={row.price}
          font_family="mono"
          text_size={11}
          text_color={Palette.muted()}
          max_lines={1}
        />
      </Row>
      {Kati.Screens.Film.hairline(rule?)}
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
  rather than a theme token, and the Text keeps the colour and weight it was
  written with, because a caller-supplied icon always does.
  """
  @spec where_badge(String.t()) :: map()
  def where_badge(badge) do
    MishkaThemeIcon.theme_icon(
      [variant: :filled, color: Palette.paper(), size: 32, radius: 10],
      [Kati.Screens.Film.where_mark(badge)]
    )
  end

  @doc false
  def where_mark(badge) do
    ~MOB"""
    <Text
      text={badge}
      font_family="mono"
      text_size={13}
      font_weight="medium"
      text_color={:on_surface}
    />
    """
  end

  @doc """
  The rule between two `where` rows — Mishka's Separator at the design's own
  colour and thickness, drawn as a **box**.

  `render: :box` is load-bearing, and it was missing. This comment used to
  claim a `<Divider>` is `Box(fillMaxWidth().height(t).background(c))`; it is
  not. `MobDivider` is Material 3's `HorizontalDivider`, which is a `Canvas`
  that `drawLine`s an **antialiased stroke**. At this device's 2.6875x a 1dp
  rule is handed a 3px-tall canvas and a 2.6875px stroke centred in it, so the
  bottom pixel row lands at ~69% coverage: one full-width row 4-5/255 lighter
  than the `1px solid rgba(26,25,23,.07)` the drawing asks for, and no
  combination of `color` and `thickness` can fix it because the softness is in
  the primitive.

  `render: :box` puts back the primitive the hand-rolled markup used —
  `<Box fill_width={true} height={1} background={…}>`, a filled rect with no
  antialiased edge, so every pixel row carries the full colour. It carries a
  1dp `<Spacer>` that is an iOS height workaround rather than a design: on
  Android the Box's own `height` pins the rule and the background covers the
  Spacer, so the node draws exactly the rectangle this screen drew before it
  adopted the component.
  """
  @spec hairline(boolean()) :: map()
  def hairline(false), do: ~MOB"<Spacer size={0} />"

  def hairline(true),
    do: MishkaSeparator.separator(color: Palette.hairline(), thickness: 1, render: :box)

  @doc false
  def actions(f) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={14} />
      <Row fill_width={true} align="top">
        {f.actions |> Enum.map(fn {icon, label} -> Kati.Screens.Film.action(icon, label) end) |> Enum.intersperse(Kati.Screens.Film.action_gap())}
      </Row>
    </Column>
    """
  end

  @doc false
  def action_gap, do: ~MOB"<Spacer size={10} />"

  # A Box for the frame and a Column for the stack, not a Column doing both.
  # `Column` takes no horizontal alignment in this bridge, so its children pin
  # to the left edge — the icons and labels sat against the button's left side.
  # A Box centres its content in both axes when given `align`.
  @doc false
  def action(icon, label) do
    ~MOB"""
    <Box weight={1.0}>
      <Box
        fill_width={true}
        height={52}
        corner_radius={20}
        background={Palette.card()}
        shadow={Kati.Theme.shadow_card_soft()}
        align="center"
      >
        <Column>
          <Row align="center">
            <Spacer weight={1.0} />
            {Kati.UI.symbol(icon, size: 19)}
            <Spacer weight={1.0} />
          </Row>
          <Spacer size={3} />
          <Text
            text={label}
            text_size={10.5}
            font_weight="semibold"
            text_color={Palette.ink_soft()}
            max_lines={1}
            text_align="center"
          />
        </Column>
      </Box>
    </Box>
    """
  end

  def handle_info({:tap, :back}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}

  def handle_info({:tap, :toggle_menu}, socket),
    do: {:noreply, Mob.Socket.assign(socket, :menu?, not socket.assigns.menu?)}

  def handle_info({:tap, :close_menu}, socket),
    do: {:noreply, Mob.Socket.assign(socket, :menu?, false)}

  def handle_info({:tap, :log_watch}, socket) do
    {:noreply,
     socket
     |> Mob.Socket.assign(:menu?, false)
     |> Mob.Socket.push_screen(Kati.Screens.Rating)}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}
end
