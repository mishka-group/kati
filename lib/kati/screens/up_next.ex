defmodule Kati.Screens.UpNext do
  @moduledoc """
  Screen 10 — Up next, pushed under Library.

  Built to `test/design/screens/10.html`. One landscape hero card for the
  thing you are closest to finishing, then a plain list of everything else that
  is ready, then a third section for the shows that have gone quiet.

  Three details from the drawing carry the whole idea and are therefore exact:

    * The hero's progress bar is **burnt into the bottom edge** of the still at
      3pt, not floated under it, so "62% through" is a property of the picture
      rather than a widget beside it.
    * The cold section's eyebrow dash is `#C4BDB3`, not `#E8823C`. Orange means
      new or now; a thread you dropped four months ago is the opposite, so
      `Kati.UI.Eyebrow.quiet/1` draws it grey.
    * The cold row sits on `#F4F1EC` with **no shadow** and offers `Drop`. It is
      the same row as the ready ones, unlifted — the design's way of saying this
      is still yours but is no longer being pushed at you.

  The frame ends at 40pt rather than 132: this screen is pushed, so there is no
  dock to clear.

  The back pill is `Kati.Screens.Pushed`'s, floating at the top left; the `tune`
  disc opposite it is this screen's own, which is the same split screen 05 uses
  for its `Mark all` button.

  ## Where the queue comes from

  `Kati.Media`, not `Kati.Screens.UpNext.Sample`. Every line the drawing puts on
  this screen is a column on one of two resources and nothing here is invented:

    * the sections are `Kati.Media.TrackedTitle.status` — `:watching` is ready,
      `:paused` is gone cold. Those are the resource's own words for "still
      going" and "stopped", and `archived` rows are excluded because that flag's
      whole meaning is *hides from shelf*.
    * the order is `last_touched_at` descending, which is the order the `:shelf`
      action itself defines. The hero is the first ready row rather than a
      separate query, so "what you are closest to" cannot disagree with the list
      under it.
    * `S2 · E6` is `progress_season` / `progress_episode`, the bookmark
      `Kati.Media.TrackedTitle` stores for exactly this — **two numbers, and
      deliberately no name**. `Kati.Media.CachedEpisode` could now supply one:
      the bookmark is a `{season, episode}` pair and `for_season/3` would find
      the row it names. `test/design/screens/10.html` does not draw one.
      Every mono line on the screen is numbers and a duration — `S2 · E6 · 18M
      LEFT`, `S3 · E2 · 48m`, `S1 · E3 · 4 MONTHS AGO` — and adding a name here
      would widen a `max_lines={1}` line that is already close to the play disc,
      pushing the title's ellipsis in on a card whose whole job is to be
      glanceable. So this stays a pair of numbers, and the episode name is
      screen 04's, where the drawing does ask for it.
    * `18M LEFT` and the burnt-in bar are the one arithmetic on the screen, and
      both halves come from the same two numbers: `progress_seconds` on the
      durable row and `runtime_minutes` on the cached one. `Kati.Media.CachedTitle`'s
      moduledoc names this screen as the reason that ×60 is done where the units
      are visible instead of behind a `denominator/1` that would be dividing a
      second by a minute.
    * `4 MONTHS AGO` is `last_touched_at` against today.
    * `4 airing soon` is `Kati.Media.Release.resolve/2` answering `:exact` or
      `:day` for a moment still ahead. No window in days is chosen here: "soon"
      is *a date Kati is sure enough of to name*, which is the distinction that
      module already exists to make, and a title whose date is a bare year is
      not counted rather than being counted as if it were the first of January.

  The poster is `Kati.Media.CachedTitle.poster_path`, which `Kati.Seeds` fills
  with the design's own seed — its comment says so outright: *"the sample
  artwork is resolved by seed through `Kati.Design.Images.poster/1`, and the seed
  is what a renderer needs"*. So `thumb/1` and `cold_thumb/1` are unchanged; they
  are handed the seed from the cache row instead of from the sample module.

  A cache row can be evicted, and then there is no title to draw — the durable
  row holds the status, the position and the rating, and deliberately not the
  name. That row renders as `Untitled` rather than being dropped, which is the
  same answer `Kati.Calendars.Today` gives a summary-less event.

  ## An empty database still draws the drawing

  With no `:watching` row there is no hero, and a hero card is the whole top of
  this screen — so `queue/0` falls back to `Sample.queue/0` whole, exactly as
  `Kati.Screens.Home.rest_of_today/1` and `Kati.Screens.Calendar.day_rows/1`
  fall back to their drawn rows. This screen is also the reference for frame 10,
  and a fresh install has nothing tracked. The fallback is all-or-nothing on
  purpose: a real hero over the drawing's ready list would be four titles the
  user does not have.
  """
  use Kati.Screens.Pushed, back: "Library"

  require Ash.Query

  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaPill
  alias Kati.Media.CachedTitle
  alias Kati.Media.Release
  alias Kati.Media.TrackedTitle
  alias Kati.Screens.UpNext.Sample
  alias Kati.Theme.Palette
  alias Kati.UI

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :queue, queue())

  @doc """
  Coming back to the queue after something was ticked above it.

  See `Kati.Screens.Resume`. The one assign is the read, so this is `load/1` —
  and this screen is where a stale socket showed worst: the whole point of
  *Up next* is what to watch NEXT, and marking an episode watched on screen 04
  left the same episode at the top of it.
  """
  @impl true
  def handle_kati(:resumed, _payload, socket), do: {:noreply, load(socket)}

  @doc """
  Every control this screen draws, and it drew none until 6 September.

  MOVIES-AND-TV.md #86. The play discs open the title, the `tune` disc opens
  the shelf's own filter sheet, and a cold row's `Drop` pill opens the drop
  sheet over that show. A drawn row carries no id and therefore no tag, so
  the board's discs stay pictures.
  """
  @impl true
  def handle_tap(:open_filters, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.ShelfFilters)}

  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "open_" <> _id ->
        {:noreply, Kati.Screens.UpNext.open(socket, tag)}

      "drop_" <> id ->
        {:noreply,
         Mob.Socket.push_screen(socket, Kati.Screens.DropSheet, %{
           tracked_id: id,
           back: "Up next"
         })}

      _other ->
        {:noreply, socket}
    end
  end

  @doc """
  The queue as `content/1` draws it: a hero, the rest of the ready list, and
  the cold one.

  Read from `Kati.Media`; the drawing's own when the library holds nothing to
  watch. See the moduledoc for which column is which line.
  """
  @spec queue() :: map()
  def queue do
    watching = tracked(:watching)

    # Gone cold is DERIVED, not stored. Both bands used to read
    # `status == :paused` — a value nothing in the app ever wrote — so the cold
    # band was empty on every device that has ever existed, and a title nobody
    # had touched in four months sat at the top of *Ready to watch*.
    # MOVIES-AND-TV.md #55 and #56; `Kati.Media.Staleness` carries the
    # argument, including why a stored status would have been the wrong answer.
    #
    # `:paused` is still read alongside it, because a reader who pauses a show
    # once something can write that has said so and Kati should not argue.
    cold = Kati.Media.Staleness.cold(watching) ++ tracked(:paused)

    # *Hide titles I can't watch* — screen 92's third switch, which prints the
    # three pages it empties and this is one of them. It removes only what is
    # KNOWN to be unavailable in the reader's country: a title nobody has
    # fetched providers for is not one they cannot watch, and a shelf emptied
    # by data they cannot see is a shelf they cannot understand.
    # MOVIES-AND-TV.md #77; `Kati.Media.Availability` carries the argument.
    ready =
      watching
      |> Kati.Media.Staleness.warm()
      |> Kati.Screens.UpNext.watchable()

    case {ready, cold} do
      {[], []} -> Sample.queue()
      {[], cold} -> nothing_ready(cold)
      {[hero | rest], cold} -> assemble(hero, rest, cold)
    end
  end

  @doc """
  The titles screen 92's *Hide titles I can't watch* leaves on this shelf.

  The whole list when the switch is off, which is its default and the state
  every device is in until somebody turns it on.

  One read of the reader — region, services, rules — for the whole list, and
  one read of the cache: `Kati.Services.availability/0` and a single
  `cache_for/1` rather than a pair per row.
  """
  @spec watchable([TrackedTitle.t()]) :: [TrackedTitle.t()]
  def watchable([]), do: []

  def watchable(tracked) do
    reader = Kati.Services.availability()

    if reader.rules[:hide_unavailable] do
      cache = cache_for(tracked)

      Enum.reject(tracked, fn row ->
        Kati.Media.Availability.hide?(
          Kati.Media.Availability.offers(Map.get(cache, {row.source, row.source_id}), reader.region),
          reader.subscribed,
          reader.rules
        )
      end)
    else
      tracked
    end
  end

  # The two numbers count different things on purpose, and each counts its own
  # thing exactly: the subtitle is everything ready — the hero included — and
  # the eyebrow labels the section under the hero, which is the rows it is
  # sitting on. Board 10's `12 ready` over `Ready to watch · 12` over four rows
  # is a drawing showing a slice of a longer list, and is not a semantics a
  # page that draws the whole list can copy.
  defp assemble(hero, rest, cold) do
    cache = cache_for([hero | rest] ++ cold)

    %{
      subtitle: "#{length(rest) + 1} ready · #{airing_soon([hero | rest], cache)} airing soon",
      ready_label: "Ready to watch · #{length(rest)}",
      cold_label: "Gone cold · #{length(cold)}",
      hero: hero_row(hero, cache),
      ready: Enum.map(rest, &ready_data(&1, cache)),
      cold: Enum.map(cold, &cold_data(&1, cache))
    }
  end

  @doc """
  A library whose shows are all paused.

  `queue/0` used to fall back to `Kati.Screens.UpNext.Sample` on
  `tracked(:watching) == []` alone, so a reader who had paused everything was
  shown four invented titles and none of their own — and `tracked(:paused)`,
  the read that would have found theirs, was only reached on the other branch.
  The board is for a library with nothing in it, not for one with nothing
  ready.

  There is no hero, because a hero is *the next thing to watch* and there is
  not one. `hero/1` draws the reason instead, and the ready section is dropped
  entirely rather than drawn as an eyebrow over nothing.
  """
  @spec nothing_ready([term()]) :: map()
  def nothing_ready(cold) do
    cache = cache_for(cold)

    %{
      subtitle: "Nothing ready · #{length(cold)} gone cold",
      ready_label: nil,
      cold_label: "Gone cold · #{length(cold)}",
      hero: nil,
      ready: [],
      cold: Enum.map(cold, &cold_data(&1, cache))
    }
  end

  # `archived` is excluded here rather than by the caller for the reason the
  # column exists: "keeps history, hides from shelf".
  defp tracked(wanted) do
    TrackedTitle
    |> Ash.Query.filter(archived == false and status == ^wanted)
    |> Ash.Query.sort(last_touched_at: :desc)
    |> Ash.read!()
  rescue
    _ -> []
  end

  # One query for every poster and every runtime on the screen, keyed by the
  # {source, source_id} pair the durable rows reference the cache by — a value,
  # never a foreign key, which is what lets the cache be wiped underneath them.
  #
  # Only ever called with the hero in the list, so `ids` cannot be empty and
  # there is no `IN ()` to guard against.
  defp cache_for(rows) do
    ids = rows |> Enum.map(& &1.source_id) |> Enum.uniq()

    CachedTitle
    |> Ash.Query.filter(source_id in ^ids)
    |> Ash.read!()
    |> Map.new(&{{&1.source, &1.source_id}, &1})
  rescue
    _ -> %{}
  end

  defp cached(row, cache), do: Map.get(cache, {row.source, row.source_id})

  defp hero_row(row, cache) do
    c = cached(row, cache)

    %{
      title: title_of(c),
      seed: seed_of(c),
      meta: join(episode(row) ++ hero_tail(row, c)),
      progress: fraction(row, c),
      # The row a tap opens. Carried on the shape rather than looked up again
      # in the handler, for `Kati.Screens.Series`' reason: the title the reader
      # pressed and the title a second query happens to return first are two
      # different facts. `nil` on the drawing, which is what makes its discs
      # pictures rather than dead controls (MOVIES-AND-TV.md #86).
      id: row.id,
      kind: row.kind
    }
  end

  defp ready_data(row, cache) do
    c = cached(row, cache)

    %{
      title: title_of(c),
      seed: seed_of(c),
      meta: join(episode(row) ++ runtime(c)),
      id: row.id,
      kind: row.kind
    }
  end

  # `action` is the offer this screen makes on a thread that has gone quiet, not
  # a stored value — the design gives every cold row the same one.
  defp cold_data(row, cache) do
    c = cached(row, cache)

    %{
      id: row.id,
      kind: row.kind,
      title: title_of(c),
      seed: seed_of(c),
      meta: join(episode(row) ++ [age(row.last_touched_at)]),
      action: "Drop"
    }
  end

  defp title_of(nil), do: "Untitled"
  defp title_of(%CachedTitle{title: nil}), do: "Untitled"
  defp title_of(%CachedTitle{title: title}), do: title

  defp seed_of(nil), do: nil
  defp seed_of(%CachedTitle{poster_path: path}), do: path

  defp join(parts), do: Enum.join(parts, " · ")

  defp episode(row) do
    Enum.reject(
      [label("S", row.progress_season), label("E", row.progress_episode)],
      &is_nil/1
    )
  end

  defp label(_prefix, nil), do: nil
  defp label(prefix, n) when is_integer(n), do: prefix <> Integer.to_string(n)
  defp label(_prefix, _other), do: nil

  # The hero says how much is LEFT, which is the resume point; every other row
  # says how long the thing is. Both are the same two numbers read differently,
  # and when there is no resume point the hero says the length as well rather
  # than inventing a position.
  defp hero_tail(row, cached) do
    case seconds_left(row, cached) do
      nil -> Enum.map(runtime(cached), &String.upcase/1)
      left -> ["#{div(left, 60)}M LEFT"]
    end
  end

  defp runtime(nil), do: []

  defp runtime(%CachedTitle{runtime_minutes: minutes}) when is_integer(minutes) and minutes > 0 do
    case {div(minutes, 60), rem(minutes, 60)} do
      {0, m} -> ["#{m}m"]
      {h, m} -> ["#{h}h #{m}m"]
    end
  end

  defp runtime(%CachedTitle{}), do: []

  defp seconds_left(row, cached) do
    with total when is_integer(total) <- total_seconds(cached),
         done when is_integer(done) and done > 0 <- row.progress_seconds,
         left when left > 0 <- total - done do
      left
    else
      _ -> nil
    end
  end

  defp total_seconds(%CachedTitle{runtime_minutes: m}) when is_integer(m) and m > 0, do: m * 60
  defp total_seconds(_cached), do: nil

  defp fraction(row, cached) do
    with total when is_integer(total) <- total_seconds(cached),
         done when is_integer(done) and done > 0 <- row.progress_seconds do
      min(done / total, 1.0)
    else
      _ -> nil
    end
  end

  @doc """
  How long ago a title was last touched, in the drawing's own words.

  The cold section's whole argument — `4 MONTHS AGO` is why the design gives a
  paused thread a grey dash and a flat row instead of a lifted card. Coarse on
  purpose: a series you stopped in April is not more interesting for having
  been stopped on the 12th, and the row has one mono line to say it in.

  Public because it is the one string on this screen that no column contains —
  `last_touched_at` is an instant and this is the sentence about it — so it is
  the piece a test has to pin directly rather than through a fixture whose
  timestamp `Kati.Media.Changes.Touch` forces to now.
  """
  @spec age(DateTime.t() | nil) :: String.t()
  def age(nil), do: "NOT STARTED"

  def age(at) do
    case Date.diff(Kati.Time.today(), DateTime.to_date(at)) do
      d when d <= 0 -> "TODAY"
      1 -> "YESTERDAY"
      d when d < 7 -> "#{d} DAYS AGO"
      d when d < 14 -> "1 WEEK AGO"
      d when d < 30 -> "#{div(d, 7)} WEEKS AGO"
      d when d < 60 -> "1 MONTH AGO"
      d when d < 365 -> "#{div(d, 30)} MONTHS AGO"
      d when d < 730 -> "1 YEAR AGO"
      d -> "#{div(d, 365)} YEARS AGO"
    end
  end

  # "Soon" is a date `Kati.Media.Release` is willing to name — `:exact` or
  # `:day`. An `:approximate` answer carries a period and no day at all, which
  # is that module's way of making "out sometime in 2026" impossible to count as
  # this week, and this counter honours it rather than re-deciding.
  defp airing_soon(rows, cache) do
    Enum.count(rows, fn row -> ahead?(Release.resolve(row, cached(row, cache))) end)
  end

  # `Kati.Time.now/0` rather than `DateTime.utc_now/0`: a screen reads the
  # device's clock through `Kati.Time`, and `Kati.ScreenDateTest` fails the build
  # over it. The two are the same instant in different zones and `DateTime.compare/2`
  # normalises, so the comparison is unchanged — the rule is about where a screen
  # is allowed to learn what time it is.
  defp ahead?({:exact, at, _origin}), do: DateTime.compare(at, Kati.Time.now()) == :gt
  defp ahead?({:day, date, _origin}), do: Date.compare(date, Kati.Time.today()) != :lt
  defp ahead?(_resolution), do: false

  @doc false
  def content(assigns) do
    q = assigns.queue

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {Kati.Screens.UpNext.tune_row()}
        {Kati.Screens.UpNext.header(q)}
        {Kati.Screens.UpNext.hero(q)}
        {Kati.Screens.UpNext.ready_section(q)}
        {Kati.UI.Eyebrow.quiet(q.cold_label)}
        {Kati.Screens.UpNext.cold(q)}
      </Column>
    </Scroll>
    """
  end

  # The back pill is drawn floating by Kati.Screens.Pushed. This row reserves
  # the height the drawing gives that pill and carries the tune disc opposite
  # it, exactly as screen 05 does with Mark all.
  @doc false
  def tune_row do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} height={44} align="center">
        <Spacer weight={1.0} />
        {Kati.Screens.UpNext.tune_disc()}
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  The `tune` disc — Mishka's Action Icon, now that a disc can float.

  This is the same component the two play discs below already use; what kept
  it out of this one was the shadow. `action_icon/2` painted a fill and
  stopped, and a filled circle with no lift reads as a patch of card colour on
  paper rather than as a control above it — so the one disc on this screen the
  design floats was the one that had to be drawn by hand. `shadow` takes the
  design's `Kati.Theme.shadow_button()` string untouched.

  Nothing moves: `shape: :circle` is an exact `size / 2`, so 44 rounds at 22
  as the literal did, the fill and the shadow pass through, and the glyph is
  the same `Kati.UI.symbol/2` Text inside a Row that hugs it and is centred in
  a Box of the declared size — where a hugging Row's only child lands exactly
  where a bare centred Text did.
  """
  @spec tune_disc() :: map()
  # The same sheet screen 03's own `tune` opens — `Kati.Screens.ShelfFilters`,
  # the sort and filter this reader last chose. Up next narrows the same shelf,
  # so a second sheet would be a second set of choices able to disagree with
  # the first.
  def tune_disc do
    MishkaActionIcon.action_icon(
      [
        size: 44,
        shape: :circle,
        variant: :filled,
        background: Palette.card(),
        shadow: Kati.Theme.shadow_button(),
        on_tap: {self(), :open_filters}
      ],
      [Kati.UI.symbol("tune", size: 21)]
    )
  end

  @doc false
  def header(q) do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text="Up next"
        text_size={28}
        max_font_scale={1.6}
        font_weight="bold"
        letter_spacing={-0.03}
        text_color={:on_surface}
      />
      <Spacer size={5} />
      <Text
        text={q.subtitle}
        font_family="mono"
        text_size={11}
        text_color={Palette.muted()}
        max_lines={1}
      />
      <Spacer size={20} />
    </Column>
    """
  end

  # A 12pt white mount around a 170pt still. The three overlays are separate
  # full-height Boxes rather than one: each needs its own bottom alignment, and
  # a Box stacks its children, so the gradient, the caption row and the progress
  # bar can all sit at the bottom edge without fighting for the same slot.
  @doc false
  def hero(%{hero: nil}) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={15}
      >
        <Spacer size={4} />
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          <Box width={44} height={44} corner_radius={14} background={Palette.paper()} align="center">
            {UI.symbol("pause_circle", size: 21, color: Palette.rail_idle())}
          </Box>
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={12} />
        <Text
          text="Nothing ready to watch"
          text_size={13.5}
          font_weight="bold"
          text_color={:on_surface}
          text_align="center"
        />
        <Spacer size={6} />
        <Text
          text="Everything on your shelf is paused. Picking one up puts it here."
          text_size={12}
          line_height={1.55}
          text_color={Palette.sub()}
          text_align="center"
        />
        <Spacer size={4} />
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  def hero(q) do
    h = q.hero

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={12}
      >
        <Box fill_width={true} height={170} corner_radius={15} background={Palette.placeholder()}>
          {Kati.Screens.UpNext.hero_art(h.seed)}
          <Box fill_width={true} fill_height={true} align="bottom">
            <Box fill_width={true} height={70} gradient="to_top #C7141210 #00141210" />
          </Box>
          <Box fill_width={true} fill_height={true} align="bottom">
            <Row
              fill_width={true}
              align="bottom"
              padding_left={14}
              padding_right={12}
              padding_bottom={12}
            >
              <Column weight={1.0}>
                <Text
                  text={h.title}
                  text_size={16}
                  font_weight="bold"
                  letter_spacing={-0.02}
                  text_color={Palette.on_media()}
                  max_lines={1}
                />
                <Spacer size={4} />
                <Text
                  text={h.meta}
                  font_family="mono"
                  text_size={10.5}
                  text_color={Palette.on_media_meta()}
                  max_lines={1}
                />
              </Column>
              <Spacer size={8} />
              {Kati.Screens.UpNext.play_disc(44, 24, Palette.on_media(), Palette.ink(:light), Kati.Screens.UpNext.open_tap(q.hero))}
            </Row>
          </Box>
          <Box fill_width={true} fill_height={true} align="bottom">
            {Kati.Screens.UpNext.progress(h.progress)}
          </Box>
        </Box>
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The hero still, at the 700x400 crop the drawing asks for.

  The seed rather than `Sample.hero_art/0`, so the card shows the title the
  queue actually put in the hero — `Sample.hero_art/0` is `hollow71` at this
  same size, so the drawn frame is byte for byte the picture it was.

  Deliberately not `Kati.Design.Images.hero/1`: that one answers with the
  900x740 crop, which is a portrait photograph of the same title, and this card
  is landscape.
  """
  @spec hero_art(String.t() | nil) :: map()
  def hero_art(seed) do
    case seed && Kati.Design.Images.path(seed, {700, 400}) do
      nil ->
        ~MOB"<Spacer size={0} />"

      src ->
        ~MOB"""
        <Image src={src} fill_width={true} height={170} content_mode="fill" />
        """
    end
  end

  @doc """
  The bar burnt into the still's bottom edge.

  Three clauses rather than one, and the two extra ones are not decoration:
  `<Box weight={f}>` beside `<Spacer weight={1.0 - f}>` hands Compose a literal
  `0.0` weight at either end of the range, which throws and takes the activity
  down — the same trap `Kati.Screens.Home.watch_bar/1` documents and the reason
  that card uses Chelekom's Progress instead of two weighted Boxes.

  A title with no resume point gets no bar at all rather than an empty one:
  `progress_seconds` is the only thing that can say how far in the user is, and
  a 0% rail burnt into the picture would be claiming they had started.

  The drawing's own 0.62 takes the middle clause, so frame 10 is unchanged.
  """
  @spec progress(float() | nil) :: map()
  def progress(nil), do: ~MOB"<Spacer size={0} />"

  def progress(fraction) when fraction >= 1.0 do
    ~MOB"""
    <Box fill_width={true} height={3} background={Palette.accent()} />
    """
  end

  def progress(fraction) when fraction <= 0.0, do: ~MOB"<Spacer size={0} />"

  def progress(fraction) do
    ~MOB"""
    <Box fill_width={true} height={3} background={Palette.on_media_track()}>
      <Row fill_width={true}>
        <Box weight={fraction} height={3} background={Palette.accent()} />
        <Spacer weight={1.0 - fraction} />
      </Row>
    </Box>
    """
  end

  @doc false
  def ready_section(%{ready_label: nil}), do: ~MOB"<Spacer size={0} />"

  def ready_section(q) do
    assigns = %{eyebrow: UI.eyebrow(q.ready_label), rows: ready(q)}

    ~MOB"""
    <Column fill_width={true}>
      {@eyebrow}
      {@rows}
    </Column>
    """
  end

  @doc false
  def ready(q) do
    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(q.ready, fn row -> Kati.Screens.UpNext.ready_row(row) end)}
      <Spacer size={13} />
    </Column>
    """
  end

  @doc false
  def ready_row(row) do
    ~MOB"""
    <Column fill_width={true}>
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
      >
        {Kati.Screens.UpNext.thumb(row)}
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text
            text={row.title}
            text_size={13.5}
            font_weight="bold"
            letter_spacing={-0.015}
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={4} />
          <Text
            text={row.meta}
            font_family="mono"
            text_size={10.5}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
        <Spacer size={12} />
        {Kati.Screens.UpNext.play_disc(34, 19, Palette.paper(), Palette.ink(), Kati.Screens.UpNext.open_tap(row))}
      </Row>
      <Spacer size={9} />
    </Column>
    """
  end

  @doc """
  The filled play disc — Mishka's Action Icon, which is what a round icon
  button is.

  Both play discs are shadowless; the lifted `tune` disc above is the same
  component with a `shadow`, which it did not have when these two adopted it.

  Nothing moves. `shape: :circle` is an exact `size / 2` radius — 22 at 44,
  17 at 34, the drawing's own numbers — the fill is passed straight through,
  and the glyph is the same `Kati.UI.symbol/2` Text as before, wrapped in a
  Row that hugs it (a Compose Row takes its content's size unless told to
  fill), centred in a Box of the same declared size.

  ## The two grounds are not the same ground

  The hero's disc is handed `Palette.on_media/0` and the ready row's is handed
  `Palette.paper/0`, and only one of them moves with the mode: the hero disc
  sits on a **photograph**, which does not get darker when the app does, so it
  stays `#FBFAF8` in dark; the ready row's sits on a card, so it sinks to the
  page colour.

  So the glyph cannot be one value either, and it is the argument this
  function was missing.

  `Kati.UI.symbol/2`'s default colour used to be `Kati.Theme.ink/0` — `#1A1917`
  forever — and this docstring said that fixing it belonged there, with a note
  that when it moved, the hero's glyph would need pinning back. It has moved:
  the default is `Palette.ink/0` now, which is `#F5F2EE` in dark. That is the
  right answer for the ready row, whose disc sank to `#121110` alongside it,
  and the wrong one for the hero, whose disc stayed `#FBFAF8` because a
  photograph does not invert — near-white on near-white, an invisible play
  button on the one control the screen exists for.

  Hence `ink`, defaulted to the mode-following value the ready row wants, and
  passed `Palette.ink(:light)` at the hero. Light mode is untouched: the two
  are the same `#1A1917` there, which is what the drawing has.
  """
  @doc """
  The tap that opens a row's title, or `nil` for one with nothing behind it.

  MOVIES-AND-TV.md #86: this screen drew no tappable control at all — the
  hero's play disc, four ready-row discs, the tune disc and every Drop pill
  were built without one, and `Kati.ScreenTapSweepTest` is blind to that by
  construction, because it collects the tags a screen DOES draw and a screen
  with none passes every check in the file.

  `nil` for a drawn row, which is what `Kati.Library.Sample.queue/0` is: not
  tappable rather than broken, the value that sweep's own docs name for a
  control with nowhere to go. Every real row carries the id it was read from.

      iex> Kati.Screens.UpNext.open_tag(%{id: nil})
      nil
  """
  @spec open_tap(map()) :: {pid(), atom()} | nil
  def open_tap(row) do
    case open_tag(row) do
      nil -> nil
      tag -> {self(), tag}
    end
  end

  @doc false
  @spec open_tag(map()) :: atom() | nil
  def open_tag(%{id: id}) when is_binary(id), do: String.to_atom("open_" <> id)
  def open_tag(_drawn), do: nil

  @doc """
  Open the title a tap named — the series screen for a series, the film screen
  for a film, which is what the design draws them as.

  `:back` says *Up next*, because that is where the reader is; see
  `Kati.Screens.Pushed.back_label/2` for what a pill that names the wrong
  screen does to somebody's sense of where they are.
  """
  @spec open(Mob.Socket.t(), atom()) :: Mob.Socket.t()
  def open(socket, tag) do
    q = socket.assigns.queue
    rows = [q.hero | q.ready ++ q.cold] |> Enum.reject(&is_nil/1)

    case Enum.find(rows, &(Kati.Screens.UpNext.open_tag(&1) == tag)) do
      nil ->
        socket

      row ->
        module = if row.kind == :movie, do: Kati.Screens.Film, else: Kati.Screens.Series
        Mob.Socket.push_screen(socket, module, %{id: row.id, back: "Up next"})
    end
  end

  @spec play_disc(number(), number(), non_neg_integer(), non_neg_integer(), term()) :: map()
  def play_disc(size, glyph, background, ink \\ Palette.ink(), tap \\ nil) do
    MishkaActionIcon.action_icon(
      [size: size, shape: :circle, variant: :filled, background: background, on_tap: tap],
      [Kati.UI.symbol("play_arrow", size: glyph, fill: true, color: ink)]
    )
  end

  @doc false
  def thumb(row) do
    case Sample.poster(row.seed) do
      nil ->
        ~MOB"<Box width={40} height={56} corner_radius={8} background={Palette.placeholder()} />"

      src ->
        ~MOB"""
        <Image src={src} width={40} height={56} corner_radius={8} content_mode="fill" />
        """
    end
  end

  # Flat paper, not an elevated card. The drawing drops the shadow here and
  # tones the poster back; the row is still legible, it just stops asking.
  @doc false
  def cold(q) do
    ~MOB"""
    <Column fill_width={true}>
      {q.cold |> Enum.map(fn row -> Kati.Screens.UpNext.cold_row(row) end) |> Enum.intersperse(Kati.Screens.UpNext.cold_gap())}
    </Column>
    """
  end

  @doc false
  def cold_gap, do: ~MOB"<Box fill_width={true} height={9} />"

  @doc false
  def cold_row(row) do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.card_settled()}
        corner_radius={18}
        padding_left={13}
        padding_right={13}
        padding_top={10}
        padding_bottom={10}
        align="center"
      >
        {Kati.Screens.UpNext.cold_thumb(row)}
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text
            text={row.title}
            text_size={13.5}
            font_weight="semibold"
            text_color={Palette.sub()}
            max_lines={1}
          />
          <Spacer size={4} />
          <Text
            text={row.meta}
            font_family="mono"
            text_size={10.5}
            text_color={Palette.tertiary()}
            max_lines={1}
          />
        </Column>
        <Spacer size={12} />
        {Kati.Screens.UpNext.drop_pill(row.action, Kati.Screens.UpNext.drop_tap(row))}
      </Row>
    </Column>
    """
  end

  @doc """
  The `Drop` affordance on a cold row — Mishka's Pill.

  A pill, not a chip: there is no selected state here, only the one offer the
  design makes on a thread that has gone quiet. A label on a tinted lozenge is
  what a pill is.

  The pixels are the Row's. `padding: 0` with `padding_left`/`padding_right`
  at 12 hands the bridge the same 12/0 edges, and padding is applied before
  size, so `height: 30` still measures 30. The pill's root is a `Box` that
  passes `fill_width={false}` — so it hugs (K-17) exactly as the Row did —
  wrapping a `Row` that holds the label beside an empty `Row` standing in for
  the absent ✕; both hug, the empty one is zero-wide, and `align: :center`
  centres the pair where `align="center"` centred the Text. `max_lines: 1` is
  the pill's own default and is what this Text already carried.
  """
  @spec drop_pill(String.t()) :: map()
  def drop_pill(label, tap \\ nil) do
    MishkaPill.pill(
      label: label,
      background: Palette.placeholder(),
      color: Palette.ink_soft(),
      corner_radius: 15,
      height: 30,
      padding: 0,
      padding_left: 12,
      padding_right: 12,
      align: :center,
      text_size: 11.5,
      font_weight: :semibold,
      on_tap: tap
    )
  end

  @doc """
  The tap on a cold row's `Drop` pill — the drop sheet, over that title.

  `Kati.Screens.DropSheet` is screen 149, and its own moduledoc says the row
  must name which show: pushed bare it opens on the newest paused title in the
  store, which is not the one the reader pressed.
  """
  @spec drop_tap(map()) :: {pid(), atom()} | nil
  def drop_tap(%{id: id}) when is_binary(id), do: {self(), String.to_atom("drop_" <> id)}
  def drop_tap(_drawn), do: nil

  # The drawing tones the cold poster back with `opacity:.6`. There is no
  # opacity prop on an Image node, so the same result is composited: 40% of the
  # row's own paper (#F4F1EC) laid over the picture is, to the pixel, the
  # picture at 60% against that paper.
  #
  # `on_media_ghost` is the only token whose light value is that 40% veil, and
  # it is a `:media` colour — it does not move in dark. So in dark the veil is
  # still 40% of the LIGHT paper while the row underneath it has sunk to
  # `card_settled` (#161514), and the poster is toned toward white rather than
  # toward the row. Right in light, approximate in dark; the exact answer would
  # be a 0x66161514 the palette does not name.
  @doc false
  def cold_thumb(row) do
    case Sample.poster(row.seed) do
      nil ->
        ~MOB"<Box width={40} height={56} corner_radius={8} background={Palette.placeholder()} />"

      src ->
        ~MOB"""
        <Box width={40} height={56} corner_radius={8} background={Palette.placeholder()}>
          <Image src={src} width={40} height={56} corner_radius={8} content_mode="fill" />
          <Box width={40} height={56} corner_radius={8} background={Palette.on_media_ghost()} />
        </Box>
        """
    end
  end
end
