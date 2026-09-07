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
  instead, the values `test/design/screens/08.html` was captured from.
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
  # The three pills under the rating card. Each carries the tag it sends, or
  # `nil` for the two that have nowhere to go yet — they were ALL `nil` and
  # none of them said so: `action/2` drew a `<Box>` with no `on_tap`, so the
  # row was three pictures of buttons. A control that sends nothing is
  # invisible to `Kati.ScreenTapSweepTest`, which walks the tags a tree draws,
  # so nothing in the suite could report them either. Found by pressing *Log
  # rewatch* on a Pixel 9a and watching the page not move.
  #
  # All three go somewhere now, and the two that did not were each waiting on
  # something that has since landed (MOVIES-AND-TV.md #84).
  #
  # `Schedule` wanted a date sheet this app did not have. It has one: screen 18
  # takes a sentence and writes a calendar event, so *Schedule* opens it with
  # the film's own name already typed. One field, and the reader adds the when.
  #
  # `Share` wanted the Android share intent, and the note here said it was a
  # fence nobody had written. `Mob.Share.text/2` is Mob's own — `ACTION_SEND`
  # through `Intent.createChooser` — and has been there all along.
  @actions [
    {"replay", "Log rewatch", :log_watch},
    {"event", "Schedule", :schedule_watch},
    {"ios_share", "Share", :share_film}
  ]

  @doc """
  What the first pill says, which depends on whether you have seen it.

  It read **Log rewatch** on a film whose own card said `SEEN never` — the
  label was a constant. A rewatch is a second watch; there is no such thing
  until there has been a first.

      iex> Kati.Screens.Film.action_label("Log rewatch", :log_watch, 0)
      "Log a watch"

      iex> Kati.Screens.Film.action_label("Log rewatch", :log_watch, 2)
      "Log rewatch"

      iex> Kati.Screens.Film.action_label("Schedule", nil, 0)
      "Schedule"
  """
  @spec action_label(String.t(), atom() | nil, non_neg_integer()) :: String.t()
  def action_label(_drawn, :log_watch, seen) when is_integer(seen) and seen > 0, do: "Log rewatch"
  def action_label(_drawn, :log_watch, _never), do: "Log a watch"
  def action_label(drawn, _other, _seen), do: drawn

  # `use Mob.Screen` and not `Kati.Screens.Root`, so this screen's own `mount/3`
  # takes the push's params directly where a pushed screen reads them off
  # `assigns.params`. `Map.get/2` and not a pattern match on the key, so a bare
  # push — the gallery's, every sweep's — still takes the drawing's branch.
  def mount(params, _session, socket) do
    Mob.Theme.set(Kati.Theme.current())

    {:ok,
     socket
     |> Mob.Socket.assign(:film, film(Map.get(params || %{}, :id)))
     |> Mob.Socket.assign(:back, Kati.Screens.Pushed.back_label(params, "Library"))
     |> Mob.Socket.assign(:menu?, false)}
  end

  @doc """
  The film this screen draws: the user's, or the drawing's.

  The gate is the whole screen rather than each card, for the reason
  `Kati.Screens.Series` gives for not moving half of itself: a page whose title
  is a real film and whose note is somebody else's evening reads as entirely
  real. Either every value is this user's or every value is the drawing's.

  `id` names the shelf row the caller meant. Without one — the gallery's door,
  and every arrival before there was anything to name — it is the top of the
  film shelf, which is what this screen has always drawn.
  """
  @spec film(String.t() | nil) :: map()
  def film(id \\ nil) do
    tracked_film(id) || drawn_film()
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

  An id that names no shelf row answers `nil` as well, rather than the top of
  the shelf. That is `Kati.Screens.BookDetail.shelved_book/1`'s rule and its
  reason: a row archived or deleted under the user is not the same fact as an
  empty shelf, and substituting a different film is the swap the argument exists
  to prevent.
  """
  @spec tracked_film(String.t() | nil) :: map() | nil
  def tracked_film(id \\ nil) do
    case film_record(id) do
      nil -> nil
      tracked -> shaped(tracked, cached_for(tracked), watches_of(tracked))
    end
  rescue
    _ -> nil
  end

  # The film the caller named, or — given no id — the top of the shelf, which is
  # what every arrival at this screen used to get and what a bare push still
  # gets. Read THROUGH `:shelf` rather than with `Ash.get/2` for the reason
  # `newest_film/0` states below: `:shelf` is where *keeps history, hides from
  # shelf* is enforced, so an id fetched around it would open a title the user
  # archived.
  defp film_record(nil), do: newest_film()

  # ACROSS the Screen kinds, not `:movie` alone. `:anime` is a kind something
  # writes now (MOVIES-AND-TV.md #104), and a film marked as anime keeps its
  # `:movie` cache row and opens this screen — `Kati.Media.Anime.film?/2` is
  # what routes it. Read against `:movie` only, this answered `nil` for exactly
  # that title and the page fell back to the DRAWING: the reader tapped their
  # own film and got somebody else's. Found on the Pixel_9a, one tap after
  # marking one as anime.
  #
  # Still through `:shelf`, which is where *keeps history, hides from shelf* is
  # enforced, and `Kati.Screens.Series.series_record/1` reads its two kinds the
  # same way for the same reason.
  defp film_record(title_id) do
    [:movie, :tv, :anime]
    |> Enum.flat_map(fn kind ->
      TrackedTitle
      |> Ash.Query.for_read(:shelf, %{kind: kind})
      |> Ash.read!()
    end)
    |> Enum.find(&(&1.id == title_id))
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

    where_rows = Kati.Screens.SeriesMeta.where_rows(cached)

    %{
      # The row a log is written against. Carried for the same reason
      # `Kati.Screens.Series` carries `tracked_id`: the film on screen and the
      # film a sheet's own query returns first are two different facts, and
      # `:log_watch` is the tap that has to know which.
      tracked_id: tracked.id,
      title: title_of(cached),
      seed: seed_of(tracked, cached),
      meta: meta_line(cached),
      watched: watched_label(tracked, dated, zone),
      # The rating comes off the newest WATCH, not off the tracked row.
      # `Kati.Media.TrackedTitle.rating` has no writer anywhere in the app —
      # screen 33's Save writes `Kati.Media.Watch.rating`, which is the rating
      # OF a viewing and is what a person actually gives — so reading the
      # tracked column meant this card drew five empty stars however many times
      # somebody rated the film. Found on a device: rate Arrival four stars,
      # save, reopen, and the card is blank.
      stars: star_count(newest_rating(watches) || tracked.rating),
      seen: seen_line(watches),
      # The COUNT as well as the sentence: `action_label/2` needs to know
      # whether a rewatch is even a thing yet, and `seen_line/1` answers in
      # words rather than in a number.
      seen_count: length(watches),
      note_date: noted && note_date(noted, zone),
      note: noted && noted.review,
      # Where this film can be watched — the same band screen 14 draws and the
      # same column it reads. It was `[]` on both, for want of an offers
      # resource; `Kati.Media.CachedTitle.providers` is that resource now
      # (MOVIES-AND-TV.md #77). `price` is `nil` on every row because TMDB
      # says where and never how much, and the row draws it as nothing.
      where: where_rows,
      where_line: Kati.Screens.Film.where_line(where_rows),
      # Kept off a shared card, and off nothing else — see the migration for
      # `Kati.Media.TrackedTitle.private`.
      private?: tracked.private,
      # Board 152's rule 1, read back: which state the ⋯ row offers to leave.
      anime?: tracked.kind == :anime,
      # Film or series, for the row that corrects it (#113). `:anime` reads as
      # whichever the cache says it is, so *This is a film* on an anime series
      # still means the right thing.
      media_kind: if(Kati.Media.Anime.film?(tracked.kind, cached), do: :movie, else: :tv),
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
  # The rating on the most recent watch that carries one. Watches arrive newest
  # first, and a rewatch logged without a rating does not erase the rating of
  # the viewing before it — *unrated* is a thing a log can be, and it is not a
  # statement about the film.
  defp newest_rating(watches) when is_list(watches) do
    Enum.find_value(watches, fn w -> w.rating end)
  end

  defp newest_rating(_other), do: nil

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
      accessibility_id={Kati.Screens.Identity.of(__MODULE__)}
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
      {Kati.Screens.Film.chrome(assigns.menu?, Map.get(assigns, :back, "Library"), f)}
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
  def chrome(menu?, label \\ "Library", f \\ %{}) do
    back = {self(), :back}
    fill = Palette.chrome_disc()
    # `box-shadow:0 6px 16px -8px rgba(26,25,23,.6)` — this screen floats its
    # chrome over a photograph, so both controls carry the same lift. Neither
    # had one, which is why they read as flat stickers on the still.
    lift = "0 6 16 -8 #991A1917"

    ~MOB"""
    <Box fill_width={true} fill_height={true} align="top">
      <Row fill_width={true} padding_left={21} padding_right={21} padding_top={60} align="center">
        {Kati.Screens.Film.back_pill(back, fill, lift, label)}
        <Spacer weight={1.0} />
        {Kati.Screens.Film.more_disc(fill, lift, menu?, f)}
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
  @spec back_pill(term(), non_neg_integer(), String.t(), String.t()) :: map()
  def back_pill(back, fill, lift, label \\ "Library") do
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
      Kati.Screens.Film.back_content(label)
    )
  end

  @doc false
  def back_content(label \\ "Library") do
    assigns = %{back: label}

    [
      Kati.UI.symbol("arrow_back_ios_new", size: 17),
      ~MOB"<Spacer size={6} />",
      ~MOB"""
      <Text
        text={@back}
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
  def more_disc(fill, lift, menu?, f \\ %{}) do
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
      [
        Kati.UI.Menu.item("star", "Log a watch", :log_watch),
        # The one control that can set `Kati.Media.TrackedTitle.private`, and
        # therefore the one thing that makes screen 98's *Hide titles I marked
        # private* a switch about anything (MOVIES-AND-TV.md #103). A decision
        # about one title belongs on that title's own page.
        Kati.UI.Menu.item(
          Kati.Screens.Film.private_icon(f),
          Kati.Screens.Film.private_label(f),
          :toggle_private
        ),
        # MOVIES-AND-TV.md #110: a film could not be dropped, abandoned or
        # DNF'd anywhere in the app. Screen 149 is the sheet for it — it is
        # series-shaped in exactly two places, its header and its position
        # card, and both are answered by the title's own kind now rather than
        # assumed.
        Kati.Screens.Film.drop_item(f),
        Kati.Screens.Film.anime_item(f),
        Kati.Screens.Film.kind_item(f)
      ]
      |> Enum.reject(&(&1 == [])),
      dismiss: :close_menu
    )
  end

  @doc """
  *Drop this film*, or nothing at all when there is no film to drop.

  MOVIES-AND-TV.md #110 gives the row and the app's own rule takes it away
  again over the drawing: screen 08 renders a fixture when nothing is tracked,
  and a Drop row there would open the sheet on whatever the newest gone-cold
  title happens to be — the exact swap `Kati.Screens.DropSheet.sheet/1`'s
  argument exists to prevent. Dropped rather than drawn dead, which is what
  `rating_card/1` already does with its own tap on the same page.
  """
  @spec drop_item(map()) :: map() | []
  def drop_item(f) do
    if Map.get(f, :tracked_id) do
      Kati.UI.Menu.item("do_not_disturb_on", "Drop this film", :open_drop_sheet)
    else
      []
    end
  end

  # Two hugging children with a weighted Spacer between them, not a weighted
  # column beside a plain one. The previous version put a width-less Box in the
  # trailing Column: a Box fills width unless `width` is a NUMBER, so it took
  # everything and starved the weight={1.0} column to zero — the card rendered
  # 333dp tall against the drawing's 84 and the stars did not appear at all.
  @doc false
  def rating_card(f) do
    # The card is the door to the sheet that sets a rating — MOVIES-AND-TV.md
    # #85. It was painted, so a reader looking at their own four stars had no
    # way to change them from the page that shows them; screen 33 is where a
    # rating is written, and this is the only thing on 08 that is about one.
    #
    # `:rate` rather than `:log_watch`, though it opens the same sheet. Three
    # controls on this page carried `:log_watch` and two of them are drawn at
    # once, so `ui.sh ids` on the Pixel_9a listed the tag twice — and two nodes
    # may not share an `accessibility_id`: `onNodeWithTag` throws on the second
    # match. One action, three doors, three names.
    tap = if Map.get(f, :tracked_id), do: {self(), :rate}

    ~MOB"""
    <Row
      fill_width={true}
      background={Palette.card()}
      corner_radius={22}
      shadow={Kati.Theme.shadow_card()}
      padding={17}
      align="center"
      on_tap={tap}
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
          {Kati.Screens.Film.note_pencil(f)}
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
          text={Map.get(row, :line) || Map.get(row, :price) || ""}
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
  The pencil on the note card: the sheet the note was written in.

  Screen 33 holds the review — it is the one field in this app that writes
  `Kati.Media.Watch.review` — so *edit this note* is *open the log this note
  belongs to*. MOVIES-AND-TV.md #85; it was a painted glyph.

  A drawn film has no row to edit and gets a picture, which is what board 08's
  own state is.
  """
  @spec note_pencil(map()) :: map()
  def note_pencil(f) do
    # `:edit_note`, not `:log_watch` — see `rating_card/1` on why each door
    # onto screen 33 carries its own tag.
    assigns = %{tap: if(Map.get(f, :tracked_id), do: {self(), :edit_note})}

    ~MOB"""
    <Box on_tap={@tap} fill_width={false}>
      {Kati.UI.symbol("edit", size: 17, color: Palette.gold_icon())}
    </Box>
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
        {f.actions |> Enum.map(fn {icon, label, tag} -> Kati.Screens.Film.action(icon, label, tag, Map.get(f, :seen_count, 0)) end) |> Enum.intersperse(Kati.Screens.Film.action_gap())}
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
  def action(icon, drawn_label, tag, seen \\ 0) do
    label = Kati.Screens.Film.action_label(drawn_label, tag, seen)
    # `nil` for the two pills with nowhere to go — a `<Box>` with a nil
    # `on_tap` draws no tap at all, which is what they did before and is the
    # honest state until each has a destination.
    tap = if tag, do: {self(), tag}

    ~MOB"""
    <Box weight={1.0} on_tap={tap}>
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

  def handle_info({:tap, :back}, socket), do: {:noreply, Kati.Screens.Resume.pop(socket)}

  def handle_info({:tap, :toggle_menu}, socket),
    do: {:noreply, Mob.Socket.assign(socket, :menu?, not socket.assigns.menu?)}

  def handle_info({:tap, :close_menu}, socket),
    do: {:noreply, Mob.Socket.assign(socket, :menu?, false)}

  # The sheet is about a watch OF this film, so it is told which. Bare, "Log a
  # watch" on one film opened whatever the newest logged watch in the whole
  # library happened to be.
  # Three doors onto screen 33 — the action pill, the rating card and the note
  # pencil — and one behaviour. Three tags because two nodes may not share an
  # `accessibility_id`; one clause because it is one action.
  def handle_info({:tap, tag}, socket) when tag in [:log_watch, :rate, :edit_note] do
    {:noreply,
     socket
     |> Mob.Socket.assign(:menu?, false)
     |> Mob.Socket.push_screen(
       Kati.Screens.Rating,
       Kati.Screens.Rating.params_for(socket.assigns.film)
     )}
  end

  # Drop this film: screen 149, over the title this page is drawing.
  #
  # MOVIES-AND-TV.md #110. The sheet was reachable only from a series, so a
  # film had no way to be dropped, abandoned or DNF'd at all.
  #
  # Named, exactly as screen 04's row is and for the same reason its comment
  # gives: bare, the sheet opens on the newest gone-cold title in the store,
  # which is not the film in front of the reader and may be nothing to do with
  # it — a Drop that dropped somebody else's title.
  #
  # A comment rather than a `@doc`, because these are clauses of one
  # `handle_info/2` and a second doc on it discards the first.
  def handle_info({:tap, :open_drop_sheet}, socket) do
    {:noreply,
     socket
     |> Mob.Socket.assign(:menu?, false)
     |> Mob.Socket.push_screen(
       Kati.Screens.DropSheet,
       Kati.Screens.DropSheet.params_for(socket.assigns.film)
     )}
  end

  @doc """
  Put this film on the calendar: screen 18, with its name already typed.

  A film you mean to watch is a thing that is going to happen, and screen 18
  is the one field in this app that takes *a thing that is going to happen*.
  It is pre-filled with `Watch <title>` rather than the bare title, because
  the sentence a reader completes is *watch Dune tomorrow 8pm* and the verb is
  the part they should not have to type.
  """
  def handle_info({:tap, :schedule_watch}, socket) do
    {:noreply,
     socket
     |> Mob.Socket.assign(:menu?, false)
     |> Mob.Socket.push_screen(Kati.Screens.QuickAdd, %{
       sentence: "Watch " <> socket.assigns.film.title
     })}
  end

  @doc """
  Hand the film to the system share sheet.

  `Mob.Share.text/2`, which is Mob's own and needed no fence: `ACTION_SEND`
  through `Intent.createChooser` on Android, `UIActivityViewController` on
  iOS. The comment beside `@actions` said this was waiting on something
  nobody had written; it was there all along.

  Fire-and-forget by construction — nothing comes back into the BEAM — so
  there is nothing to report and nothing to draw. The socket is unchanged,
  which `Mob.Share.text/2` documents in as many words.
  """
  @doc """
  Mark this film private, or unmark it — the one write behind screen 98's
  *Hide titles I marked private*, which was a switch with nothing to mark.

  It hides the title from that CARD and from nowhere else. The shelf, Up next
  and the year's own numbers are unchanged, because a private title is still a
  title you watched.
  """
  def handle_info({:tap, :toggle_private}, socket) do
    f = socket.assigns.film

    with id when is_binary(id) <- Map.get(f, :tracked_id),
         {:ok, tracked} <- Ash.get(Kati.Media.TrackedTitle, id),
         {:ok, updated} <-
           tracked
           |> Ash.Changeset.for_update(:update, %{private: not tracked.private})
           |> Ash.update() do
      {:noreply,
       socket
       |> Mob.Socket.assign(:menu?, false)
       |> Mob.Socket.assign(:film, %{f | private?: updated.private})}
    else
      _refused -> {:noreply, Mob.Socket.assign(socket, :menu?, false)}
    end
  end

  # Board 152's rule 1, written. `anime_override` is three-valued and this only
  # ever sets it to `true` or `false` — a reader who has pressed the row HAS
  # said, and `nil` is the state of never having been asked (#104).
  def handle_info({:tap, :toggle_anime}, socket) do
    f = socket.assigns.film

    with id when is_binary(id) <- Map.get(f, :tracked_id),
         {:ok, tracked} <- Ash.get(Kati.Media.TrackedTitle, id),
         now? <- tracked.kind == :anime,
         {:ok, updated} <-
           tracked
           |> Ash.Changeset.for_update(:update, %{
             anime_override: not now?,
             kind: Kati.Media.Anime.kind_for(tracked.kind, nil, not now?)
           })
           |> Ash.update() do
      {:noreply,
       socket
       |> Mob.Socket.assign(:menu?, false)
       |> Mob.Socket.assign(:film, Map.put(f, :anime?, updated.kind == :anime))}
    else
      _refused -> {:noreply, Mob.Socket.assign(socket, :menu?, false)}
    end
  end

  # Kind, corrected. MOVIES-AND-TV.md #113: a hand-typed title takes its Kind
  # from a two-chip answer on 154 and nothing could change it afterwards — a
  # show picked as a film sat on the wrong screen forever, and the add path
  # refused to let you type it again because the name was taken.
  #
  # `Kati.Screens.Resume.pop/1` rather than a push: the title has moved to the
  # other screen, and the page the reader is on is now about a kind this title
  # is not. Popping puts them back where they came from, and the tile there
  # opens the right screen.
  def handle_info({:tap, :swap_kind}, socket) do
    f = socket.assigns.film

    with id when is_binary(id) <- Map.get(f, :tracked_id),
         {:ok, tracked} <- Ash.get(Kati.Media.TrackedTitle, id),
         swapped <- Kati.Screens.Film.swapped(Map.get(f, :media_kind, :movie)),
         {:ok, _updated} <- Kati.Screens.Film.rekind(tracked, swapped) do
      {:noreply, socket |> Mob.Socket.assign(:menu?, false) |> Kati.Screens.Resume.pop()}
    else
      _refused -> {:noreply, Mob.Socket.assign(socket, :menu?, false)}
    end
  end

  def handle_info({:tap, :share_film}, socket) do
    {:noreply, Mob.Share.text(socket, Kati.Screens.Film.share_line(socket.assigns.film))}
  end

  @doc """
  Where this film can be watched, as one line, or `nil`.

  The FIRST row of the band, which is the first way it is offered — what the
  reader pays for, then free, then rent, then buy, in `Kati.Screens.SeriesMeta.
  where_rows/1`'s own order.

  Not `Kati.Media.Availability.line/3`, and the difference matters here: that
  one answers *what can YOU watch*, which is the right question for hiding a
  title and the wrong one for telling somebody else about it. A film on
  Kanopy is on Kanopy whether or not the person sharing it subscribes.

  `nil` for a film nobody has looked up, which keeps *Dune* out of a share
  that would otherwise claim it was available nowhere.

      iex> Kati.Screens.Film.where_line([])
      nil

      iex> Kati.Screens.Film.where_line([%{name: "Kanopy", line: "included"}])
      "On Kanopy"

      iex> Kati.Screens.Film.where_line([%{name: "Apple TV", line: "rent"}])
      "Rent from Apple TV"
  """
  @spec where_line([map()]) :: String.t() | nil
  def where_line([]), do: nil
  def where_line([%{name: name, line: "rent"} | _rest]), do: "Rent from " <> name
  def where_line([%{name: name, line: "buy"} | _rest]), do: "Buy from " <> name
  def where_line([%{name: name} | _rest]), do: "On " <> name

  @doc """
  The ⋯ row that marks a title private, and what it says.

  Two labels rather than a switch, because an overflow row is a verb: *Keep off
  shared cards* is what pressing it does, and *Show on shared cards* is what
  pressing it does when it is already off one.
  """
  @spec private_label(map()) :: String.t()
  def private_label(%{private?: true}), do: "Show on shared cards"
  def private_label(_film), do: "Keep off shared cards"

  @doc """
  The glyph beside it.

  `visibility_off` both ways, and `lock` is not the alternative it looks like:
  Kati's icon subset carries exactly two of this family — `Kati.Icons.glyph!/1`
  raises on anything else, which is how a `visibility` here took the film
  screen down on the Pixel_9a and sent the app back to Home. The row's WORD
  carries the state; the glyph names the subject.
  """
  @spec private_icon(map()) :: String.t()
  def private_icon(_film), do: "visibility_off"

  @doc """
  Board 152's first rule, as a row: *Your own tag — always wins, you know.*

  MOVIES-AND-TV.md #104. The reader's own answer is rule 1 and there was
  nowhere in the app to give it. This is that place, on the same ⋯ that carries
  *Keep off shared cards* and for its reason: a decision about one title
  belongs on that title's own page.

  The word says what pressing it does, which is why it is not *Anime* with a
  tick. A title Kati already files as anime offers to stop; one it does not
  offers to start.

      iex> Kati.Screens.Film.anime_label(%{anime?: true})
      "Not anime"

      iex> Kati.Screens.Film.anime_label(%{anime?: false})
      "Mark as anime"
  """
  @spec anime_label(map()) :: String.t()
  def anime_label(%{anime?: true}), do: "Not anime"
  def anime_label(_title), do: "Mark as anime"

  @doc """
  The row, or nothing at all when there is no title behind it.

  Dropped rather than drawn dead over the drawing, which is `drop_item/1`'s
  rule on this page and the app's everywhere.
  """
  @spec anime_item(map()) :: map() | []
  def anime_item(f) do
    if Map.get(f, :tracked_id) do
      Kati.UI.Menu.item("auto_awesome", Kati.Screens.Film.anime_label(f), :toggle_anime)
    else
      []
    end
  end

  @doc """
  *This is a series* / *This is a film* — the one row that corrects a Kind.

  MOVIES-AND-TV.md #113. A hand-typed title takes its Kind from a two-chip
  answer on screen 154, and no screen in the app could change it afterwards:
  picking Film for a show meant a title on the wrong screen forever, with the
  add path refusing to let you type it again because the name was taken.

  It is a menu row rather than a control on the page, for `private`'s reason
  and `anime`'s: a decision about one title belongs on that title's own page,
  and the ⋯ is where the decisions that are not about watching live.

      iex> Kati.Screens.Film.kind_label(:movie)
      "This is a series"

      iex> Kati.Screens.Film.kind_label(:tv)
      "This is a film"
  """
  @spec kind_label(atom()) :: String.t()
  def kind_label(:movie), do: "This is a series"
  def kind_label(_series), do: "This is a film"

  @doc false
  @spec kind_item(map()) :: map() | []
  def kind_item(f) do
    if Map.get(f, :tracked_id) do
      Kati.UI.Menu.item(
        "swap_horiz",
        Kati.Screens.Film.kind_label(Map.get(f, :media_kind, :movie)),
        :swap_kind
      )
    else
      []
    end
  end

  @doc """
  The other kind.

      iex> Kati.Screens.Film.swapped(:movie)
      :tv

      iex> Kati.Screens.Film.swapped(:tv)
      :movie
  """
  @spec swapped(atom()) :: atom()
  def swapped(:movie), do: :tv
  def swapped(_series), do: :movie

  @doc """
  Write the corrected kind to BOTH rows, because both hold one.

  `Kati.Media.TrackedTitle.kind` is what the shelf queries and
  `Kati.Media.CachedTitle.kind` is what decides which screen a tile opens
  (`Kati.Media.Anime.film?/2`), so correcting one and not the other would put
  the title on the right shelf behind the wrong door.

  An anime keeps being an anime: the tracked row's `:anime` is the flag, and
  the cache is where film-or-series lives — see `Kati.Media.Anime`.
  """
  @spec rekind(term(), atom()) :: {:ok, term()} | {:error, term()}
  def rekind(tracked, kind) do
    Kati.Media.CachedTitle
    |> Ash.Query.filter(source == ^tracked.source and source_id == ^tracked.source_id)
    |> Ash.read!()
    |> Enum.each(&(&1 |> Ash.Changeset.for_update(:update, %{kind: kind}) |> Ash.update!()))

    tracked
    |> Ash.Changeset.for_update(:update, %{
      kind: if(tracked.kind == :anime, do: :anime, else: kind)
    })
    |> Ash.update()
  rescue
    error -> {:error, error}
  end

  @doc """
  What gets shared: the title, the year, and where it can be watched.

  The last part is the one worth sending. `Kati.Media.Availability` knows it
  now, and *Dune (2021) — On Netflix* is a message somebody can act on where
  *Dune* is a message they have to look up.

      iex> Kati.Screens.Film.share_line(%{title: "Dune", meta: "2021 · SCI-FI", where_line: nil})
      "Dune (2021)"

      iex> Kati.Screens.Film.share_line(%{title: "Dune", meta: nil, where_line: "On Netflix"})
      "Dune — On Netflix"
  """
  @spec share_line(map()) :: String.t()
  def share_line(film) do
    [
      film.title <> year_suffix(Map.get(film, :meta)),
      Map.get(film, :where_line)
    ]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(" — ")
  end

  defp year_suffix(meta) when is_binary(meta) do
    case Regex.run(~r/\b(\d{4})\b/, meta) do
      [_all, year] -> " (" <> year <> ")"
      _no_year -> ""
    end
  end

  defp year_suffix(_none), do: ""

  # Coming back from the log sheet, or from anything else pushed over this
  # page. See `Kati.Screens.Resume`: a popped-to screen restores its saved
  # socket, so *Log a watch* → Save → back left the stars empty, `SEEN never`
  # and the first pill still reading *Log a watch* — the write had landed and
  # the page in front of the reader said it had not.
  #
  # This screen is hand-rolled rather than `Kati.Screens.Pushed`, so nothing
  # routes `{:kati, …}` to a `handle_kati/3` for it; the clause is the routing.
  # The id is re-read off the film on screen so the refresh describes the same
  # title the arrival did.
  def handle_info({:kati, :resumed, _payload}, socket) do
    {:noreply, Mob.Socket.assign(socket, :film, film(Map.get(socket.assigns.film, :tracked_id)))}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}
end
