defmodule Kati.Screens.Season do
  @moduledoc """
  Screen 34 — a season's order and its specials, pushed under Series.

  Built to `test/design/screens/34.html`. Three numbering schemes across
  the top, two switches that decide what counts as an episode, then the list
  those choices produce. The dashed footnote at the bottom is the screen's
  whole argument: **your ticks follow the episode, not the number**, so
  switching from Aired to Absolute renumbers the list without losing a thing.

  Three row states are drawn and all three are exercised:

    * **watched** — `#F4F1EC`, muted title, an ink disc with a white check
    * **aired, not watched** — a lifted `#FBFAF8` card, ink title, empty ring
    * **a special** — the same as watched, but its number is bronze and it
      carries a `SPECIAL` badge, because it is in the order without being in
      the count

  E6 and E7 draw the same empty ring. The export gives E6 a `check` glyph at
  zero alpha and E7 none at all, which is the same picture by two routes; one
  ring, drawn once, is the honest version of it.

  No dock — this is a pushed screen — so the frame closes at 40, not 132.

  ## Components, and the strip that cannot be one

    * `check/1` — `Kati.Components.MishkaThemeIcon`, `:filled` for the ink tick
      and `:subtle` for the empty ring. `:subtle` paints nothing and takes the
      drawing's hairline through `border_color` / `border_width`, both new this
      round.
    * `badge_pill/3` — `Kati.Components.MishkaPill`, which is exactly a compact
      label in a coloured token.

  **The order strip stays hand-rolled.** `Kati.Components.MishkaSegmentedControl`
  now takes every colour, radius, height and shadow this drawing asks for —
  including `selected_shadow`, which is the whole difference between the chosen
  tile and its two neighbours — and still cannot draw it, for one reason:
  **the drawing sets its three tiles 4pt apart** and the component lays its
  segments in a bare `Row` with nothing between them and no spacing prop. Three
  flush tiles are different pixels.

  There is a second thing worth recording even though the gap above settles it:
  the component's equal-width answer is `segment_weight`, which it merges onto
  the *same* `Box` that carries `fill_width: false`. Since fence K-17 that
  `false` makes the box hug, so a weight and a hug would be arguing on one node.
  `order/2` keeps the two on separate boxes — an outer `Box weight={1.0}` around
  an inner `Box fill_width={true}` — which is why it has a wrapper that looks
  redundant and is not.

  ## Where the list comes from

  `Kati.Media`, through `season/0` — **the episode list, the header and every
  tick in it**. The rest of the screen is still the drawing's, and which half is
  which is set out below rather than left to be inferred.

  This screen used to say `Kati.Media` had no episode at all — a
  `Kati.Media.Watch` carried an `episode_source_id` and nothing anywhere held
  the record it named, so nothing could answer *what is E5 called*, *how long is
  it* or *when did it air*, which is every row of this list. That is no longer
  true, and it stopped being true naming this screen:
  `Kati.Media.CachedEpisode.for_season/3` is *"one season's episodes, in aired
  order"*, `in_order/2` quotes this drawing's own footnote, and `special` is
  stored rather than derived because *"screen 34 draws it as a bronze number and
  a SPECIAL badge: in the order, out of the count"*.

  Five reads, never one per row: the two series shelves, the season, its
  episodes, and that title's episode ticks. The cache is reached by value —
  `{source, source_id}` for a title and `{source, title_source_id,
  season_number}` for a season — because that is what the durable row holds, so
  an eviction cannot orphan a tick.

  **Which season.** Nothing hands this screen one: `Kati.Screens.Series` pushes
  it with no title and no number attached, exactly as `Kati.Screens.Library`
  pushes `Kati.Screens.Film`. So the referent is the season the user is
  bookmarked in — `Kati.Media.TrackedTitle.progress_season` on the most recently
  touched series, which is the bookmark `Kati.Media.CachedSeason` was built to
  give an inventory to. A tracked row with no `progress_season`, or a season
  with nothing cached in it, is not a season this screen can draw, and both fall
  back rather than drawing an empty running order.

  With nothing tracked there is no such season and `Kati.Season.Sample` is drawn
  instead, the values `test/design/screens/34.html` was captured from.
  FIDELITY's rule: *missing data is not a reason for a blank screen*. The Sample
  module stays exactly where it is; it is the fallback and the fixture, not a
  stage this screen has passed through.

  ### What each row is made of

    * `E1` / `S1` is `episode_number` read through
      `Kati.Media.CachedEpisode.number_in/2` at `:aired`, with the prefix chosen
      by the stored `special` flag rather than by `season_number == 0` — that
      equivalence is TMDB's and TVmaze does not share it. An episode a source
      left unnumbered draws no label at all, because a number this screen
      invented is precisely the renumbering the footnote warns about.
    * `Low Water` is `title`, and `Untitled` where a provider has announced an
      episode without naming it — the answer `Kati.Screens.Film` and
      `Kati.Screens.UpNext` already give a name that is missing, rather than the
      `TBA` `Kati.Media.CachedEpisode` calls *"a string a provider invented"*.
    * `54m · 9 Jul` is `runtime_minutes` and the air date, and the air date is
      `Kati.Media.Release.air/1` and nothing else — the one date path. `airs`
      is prepended for anything `Kati.Media.Release.airing/2` does not call
      `:aired`, which is what makes E6 and E7 read `airs 20 Aug` while E1 reads
      `9 Jul`. A date coarser than a day carries no day at all, so the runtime
      is drawn alone rather than under a month pretending to be the first of it.
    * The tick is a `Kati.Media.Watch` row, keyed on `episode_source_id` through
      `Kati.Media.CachedEpisode.ticked?/2` — **never** on `{season, episode}`.
      That is the whole of the footnote: *your ticks follow the episode, not the
      number*, and keying on the label is the bug it warns about.
    * The bronze number and the `SPECIAL` badge are one stored `special`, drawn
      as the two marks the design gives it.

  ## What stays the drawing's, and why

  The order strip, the two switches, the `PARTS 1–2` badge and the footnote's
  first sentence. Each is a resource or a column rather than a query, so none of
  them moves when the list under it does:

    * **The `DVD` tile.** `Kati.Media.CachedEpisode.orders/0` answers
      `[:aired, :absolute]` and says why at length: no source Kati fetches from
      provides per-episode DVD numbering. The drawing offers three tiles and the
      data can fill two, and *"a segmented control whose third option changes
      nothing is a lie told in pixels"* is that resource's own sentence. So the
      strip is drawn with the three tiles the design has and `Aired` is the
      order the list is actually built in — `in_order/2` at `:aired` — rather
      than a label over an arbitrary sort.
    * **`Include specials`.** Honoured. `specials/2` reads season 0 — which is
      where every provider files them — and merges it into the list, sorted by
      air date, which is exactly what the sub-line promises. It was drawn ON
      above a list that contained none, because `for_season/3` reads one season
      number and 0 is never it (MOVIES-AND-TV.md #69).
    * **`Merge multi-part`.** Not honoured, and it cannot be yet: merging a
      two-part finale into one entry needs a column that marks an episode as
      merged and pairs it with its other half, and `Kati.Media.CachedEpisode`
      is a cache — the one place a user's choice must never live. The switch is
      drawn in its design state and changes nothing, which is written down
      here rather than left to be discovered.
    * **The `PARTS 1–2` badge.** Merging a two-part finale into one entry is a
      transformation of the order with nothing to record that it happened — no
      column marks an episode as merged and none pairs it with its other half.
      A real row never carries it; the drawn one still does.
    * **The footnote's first sentence.** `Absolute order renumbers this season
      27–35 and drops the special` is a specific renumbering of a specific
      season, and it would be a claim about a season nobody made it about. A
      real season keeps only the general half — *your ticks follow the episode,
      not the number* — which is true of every season and is the sentence the
      tick keying above actually honours.

  The subtitle `order & specials` stays too, and is a label rather than data:
  the same class of literal as screen 08's action row. `assemble/4` says it
  itself rather than inheriting the fixture's copy of it — the same words, and
  a msgid the reader's own script can reach. Nothing about it became data.

  ## Persian

  mishka-group/kati#103. Everything this screen writes is a msgid; three things
  it writes are not words at all and are worth naming:

    * **The order strip's labels are STATE.** `:orders` and `:current_order`
      hold `Aired` and `Absolute`, `order_tap/2` builds `:order_Aired` out of
      one and `order_from/1` parses it back. Translating them would have made
      every tile on a Persian page dead. `order_title/1` is the word; the label
      is the identity, and it stays English. `DVD` is a format's name and stays
      Latin in both scripts.
    * **The list's two mono lines ask the STRING what face it needs**, because
      `kati_mono.ttf` carries no Persian glyph and a runtime line is a sentence
      here (`۵۵ دقیقه · پخش ۲۹ مرداد`), not a figure.
    * **An air date is a calendar, not a format.** `Kati.Locale.date/2` at
      `:short`, which is `20 Aug` in Latin and ۲۹ مرداد in Persian — the one
      thing a catalogue cannot do.

  """
  use Kati.Screens.Pushed, back: "Series"
  use Gettext, backend: Kati.Gettext

  alias Kati.Components.MishkaPill
  alias Kati.Components.MishkaThemeIcon
  alias Kati.Media.CachedEpisode
  alias Kati.Media.CachedSeason
  alias Kati.Media.Release
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Season.Sample
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  # The kinds a season can belong to. `:movie` is absent because a film has no
  # seasons — this is `Kati.Screens.Library`'s `@screen_kinds` less the one that
  # cannot be here — and `:book` and `:album` are absent for that screen's own
  # reason: #60 settled that v1 ships one media domain.
  @series_kinds [:tv, :anime]

  # The half of the drawing's footnote that is true of every season. See the
  # moduledoc: the other half renumbers one particular season.
  #
  # A function and not the `@general_note` attribute it was, for
  # mishka-group/kati#103's own trap: `gettext/1` inside a module attribute is
  # evaluated at COMPILE time and freezes in whichever locale the compiler was
  # in, so the sentence would have shipped in one script whatever the reader
  # chose. One call site, and it reads the same.
  defp general_note, do: gettext("Your ticks follow the episode, not the number.")

  # No `require Ash.Query`, for the reason `Kati.Screens.Series` states beside
  # its own aliases: every read here is an action by name, and `series_record/1`
  # narrows with `Enum.find` rather than a `filter` expression so it stays that
  # way.

  # `Kati.Screens.Pushed` puts the push's params on `:params`, and this is the
  # screen reading them — the two lines `Kati.Screens.Day` and
  # `Kati.Screens.MealEdit` are built on. A bare push assigns `%{}`, which
  # `season/1` reads as the question this screen was always asked.
  @impl true
  def load(socket) do
    socket
    |> Mob.Socket.assign(:season, season(socket.assigns.params))
    |> Mob.Socket.assign(:save_error, nil)
    |> Mob.Socket.assign(:menu?, false)
  end

  # Screen 34's first tag. `Kati.Screens.Pushed` deliberately defines no
  # `handle_tap/2` — its moduledoc says why — so this screen had none, because
  # until now it drew no control at all: the order strip and the two switches
  # are pictures (see the moduledoc), and the episode rows were pictures of
  # screen 04's rows.
  @impl true
  # The `help` disc beside the order strip, onto screen 153 — the board that
  # explains the choice this strip offers, and which nothing pushed
  # (MOVIES-AND-TV.md #9). Before the prefix clauses below, which would
  # otherwise hand it to `menu_tap/2`.
  def handle_tap(:explain_numbering, socket),
    do:
      {:noreply,
       Mob.Socket.push_screen(socket, Kati.Screens.NumberingScheme, %{back: "Episodes"})}

  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "episode_" <> index -> {:noreply, Kati.Screens.Season.tick(socket, index)}
      "rate_" <> index -> {:noreply, Kati.Screens.Season.rate(socket, index)}
      "order_" <> label -> {:noreply, Kati.Screens.Season.reorder(socket, label)}
      _menu_or_nothing -> {:noreply, Kati.Screens.Season.menu_tap(socket, tag)}
    end
  end

  @doc """
  The trailing rating column, and the door onto screen 144.

  `Kati.Screens.Series.rating_column/1`'s twin, one screen over, and the same
  three states for the same reasons — a rated episode prints its numeral and
  star, an aired unrated one draws the hollow star that is the affordance, and
  an episode that has not aired draws nothing because there is no opinion to
  have. The two screens draw the same episode rows and must offer the same
  door.
  """
  @spec rating_column(map()) :: map() | []
  def rating_column(ep) do
    case {Map.get(ep, :aired, true), Map.get(ep, :source_id), Map.get(ep, :index)} do
      {true, id, i} when is_binary(id) and is_integer(i) ->
        Kati.Screens.Season.rating_door(ep, i)

      _no_door ->
        Kati.Screens.EpisodeRatings.rating_node(Map.get(ep, :rating))
    end
  end

  @doc false
  def rating_door(ep, index) do
    assigns = %{
      tap: {self(), String.to_atom("rate_#{index}")},
      body: Kati.Screens.Series.rating_face(Map.get(ep, :rating))
    }

    ~MOB"""
    <Row align="center" padding_left={13} padding_right={4} on_tap={@tap}>
      {@body}
    </Row>
    """
  end

  @doc """
  Open the rating sheet over one episode of this season.

  `Kati.Screens.Series.rate/2`'s twin, and the same gate: the pair, never the
  position, and a drawn season opens nothing because there is no episode
  behind `Kati.Season.Sample` to rate.
  """
  @spec rate(Mob.Socket.t(), String.t()) :: Mob.Socket.t()
  def rate(socket, index) do
    s = socket.assigns.season
    episode = Enum.at(s.episodes, String.to_integer(index))
    tracked_id = Map.get(s, :tracked_id)
    source_id = episode && Map.get(episode, :source_id)

    if is_binary(tracked_id) and is_binary(source_id) do
      Mob.Socket.push_screen(socket, Kati.Screens.RateEpisode, %{
        tracked_id: tracked_id,
        episode_source_id: source_id
      })
    else
      socket
    end
  end

  @doc """
  Tick or untick one episode of the season on screen, and write it.

  `Kati.Screens.Series.write_tick/2` and not a second writer: what a tick IS —
  a `Kati.Media.Watch` row that exists, destroyed rather than contradicted on
  the way back — is `Kati.Media.Watch`'s own rule, and two screens holding two
  copies of it is how they come to disagree. This screen and screen 04 tick the
  same episodes; they must tick them the same way.

  The screen follows the store rather than leading it: the assign flips only
  after the write answers `:ok`, so a refused write leaves the ring where it
  was instead of showing a state the database does not hold.

  A season with no `:tracked_id` — the drawing's, which is what a fresh install
  and every sweep renders — writes nothing and says so. That is the same
  all-or-nothing gate `season/1` already applies to the list itself: there is no
  episode row behind `Kati.Season.Sample`, so there is nothing to tick.
  """
  @spec tick(Mob.Socket.t(), String.t()) :: Mob.Socket.t()
  def tick(socket, index) do
    s = socket.assigns.season
    position = String.to_integer(index)
    episode = Enum.at(s.episodes, position)

    case Kati.Screens.Series.write_tick(Map.get(s, :tracked_id), episode) do
      :ok ->
        flip = fn ep -> %{ep | watched: not ep.watched} end

        socket
        |> Mob.Socket.assign(
          :season,
          %{s | episodes: List.update_at(s.episodes, position, flip)}
        )
        |> Mob.Socket.assign(:save_error, nil)

      {:error, reason} ->
        Mob.Socket.assign(socket, :save_error, Kati.Write.message({:error, reason}))
    end
  end

  @doc """
  Answer the ⋯ disc: open the menu, close it, or open a sibling page.

  Everything the disc offers lives in `Kati.Screens.ShowPages` — MOVIES-AND-TV.md
  #98 — because 35 draws the same disc and the two menus must not be able to
  offer different sets. A tag it does not own leaves the screen alone, which is
  what `handle_tap/2` did for every unrecognised tag before this.

  `back: "Episode order"` rather than the screen's own back label: the pill
  says where back GOES, and from a page opened here that is this page.
  """
  @spec menu_tap(Mob.Socket.t(), atom()) :: Mob.Socket.t()
  def menu_tap(socket, tag) do
    id = Map.get(socket.assigns.season, :tracked_id)

    case Kati.Screens.ShowPages.handle(socket, tag, id, "Episode order") do
      {:handled, moved} -> moved
      :unknown -> socket
    end
  end

  @doc """
  Redraw the list in the order the tile names.

  Re-read rather than re-sorted in place, and that is the point of the
  footnote this screen carries: *your ticks follow the episode, not the
  number*. Absolute order does not permute the season, it drops the episodes
  it cannot place and counts from the first episode of the SHOW, so the row
  list, the numbers and the count are all different answers rather than the
  same answer rearranged. Re-reading is also what keeps a tick made in one
  order visible in the other.

  A label no order answers to — the board's **DVD** — never reaches here, and
  a season whose cache cannot support the order the tag names falls back to
  Aired inside `assemble/4` rather than drawing an empty list.
  """
  @spec reorder(Mob.Socket.t(), String.t()) :: Mob.Socket.t()
  def reorder(socket, label) do
    case Kati.Screens.Season.order_from(label) do
      nil ->
        socket

      order ->
        socket
        |> Mob.Socket.assign(:season, season(socket.assigns.params, order))
        |> Mob.Socket.assign(:save_error, nil)
    end
  end

  @doc """
  The season this screen draws: the user's, or the drawing's.

  The gate is the list rather than the page, because the page is not all one
  kind of fact — the order strip and the two switches have no store at all (see
  the moduledoc) and are the design's in both branches. What moves together is
  the header, the count and the rows, and those are one season or they are the
  drawing's.

  `params` is the push's, taken whole rather than as two positional arguments,
  because both keys are optional and either can be absent on its own: a caller
  may know the series and not which season, and `%{}` knows neither.
  """
  @spec season(map() | nil) :: map()
  def season(params \\ %{}, order \\ :aired),
    do: tracked_season(params, order) || empty_season(order)

  @doc """
  The season with no episodes in it.

  `Kati.Season.Sample.season/0`'s eight keys carrying nothing. It was that
  fixture — *Season 2*, nine episodes over eight rows, a note about specials —
  and `tracked_season/2` answers nil for a season nobody named as readily as for
  an empty shelf, so a push that lost its params described somebody else's
  running order.

  The order strip keeps its three labels and the chosen one: those are the
  app's own vocabulary for how a season can be counted, not a claim about any
  season. The switches go with the episodes, because both act on rows.
  """
  @spec empty_season(atom()) :: map()
  def empty_season(order \\ :aired) do
    %{
      title: "",
      subtitle: gettext("order & specials"),
      orders: ["Aired", "Absolute", "DVD"],
      current_order: order_label(order),
      options: [],
      eyebrow: gettext("Episodes · %{n} in this order", n: Kati.Locale.number(0)),
      episodes: [],
      note: ""
    }
  end

  @doc """
  Screen 34 exactly as it is drawn, from `Kati.Season.Sample`.

  Kept in the fixture rather than inlined here, for the reason
  `Kati.Screens.Film.drawn_film/0` gives: it is the frame's specification and
  the value a test compares a real render against, and two copies of the
  drawing's copy is exactly how the two drift apart.
  """
  @spec drawn_season() :: map()
  def drawn_season, do: Sample.season()

  @doc """
  The params that name a season — the series, and which of its seasons.

  Here rather than at screen 04 so the two keys are spelled once, the way
  `Kati.Screens.MealEdit` spells `:meal_id` once for its doors. This is more
  than a bare id, which is exactly when a builder earns its place: a season is
  a title AND a number, and screen 04 holds the number as the strip's label
  (`S2`) where this screen counts in integers.

  `:title_id` and not `:id`, because `:id` beside `:season` would read as the
  season's own id and no such row exists — `Kati.Media.CachedSeason` is keyed by
  `{source, title_source_id, season_number}`. Naming the noun is what
  `:meal_id`, `:book_id` and `:album_id` already do everywhere an id is not the
  destination's own subject.

  A series with no tracked row — the drawing's — yields `%{}`, and a label that
  is not `S<integer>` yields the title alone, which falls back to the bookmark.

      iex> Kati.Screens.Season.params_for(%{tracked_id: "abc", current_season: "S2"})
      %{title_id: "abc", season: 2}

      iex> Kati.Screens.Season.params_for(%{current_season: "S2"})
      %{}
  """
  @spec params_for(map() | nil) :: map()
  def params_for(%{tracked_id: id, current_season: label})
      when is_binary(id) and is_binary(label) do
    case Integer.parse(String.trim_leading(label, "S")) do
      {number, ""} -> %{title_id: id, season: number}
      _other -> %{title_id: id}
    end
  end

  def params_for(%{tracked_id: id}) when is_binary(id), do: %{title_id: id}
  def params_for(_series), do: %{}

  @doc """
  The season the user is bookmarked in, shaped for the markup, or `nil`.

  `nil` is the ordinary answer three times over — nothing tracked, no
  `progress_season` on the row that is, or a season whose episodes have not been
  fetched — and it is the answer `season/0` reads as *draw the drawing*. A
  database that cannot be read at all answers `nil` too: `Ash.read!` on a device
  mid-migration raises, and a screen that dies is strictly worse than a screen
  showing the values it was drawn from — the same degradation
  `Kati.Screens.Library.shelf/0` and `Kati.Calendars.Today` make.

  Both halves of the referent are the caller's when it names them: `:title_id`
  is which show, `:season` is which of its seasons. Neither named is the
  question this screen was always asked — the most recently touched series, at
  its own bookmark.
  """
  @spec tracked_season(map() | nil, CachedEpisode.order()) :: map() | nil
  def tracked_season(params \\ %{}, order \\ :aired) do
    asked = params || %{}

    case series_record(Map.get(asked, :title_id)) do
      %TrackedTitle{} = tracked ->
        case season_number(tracked, Map.get(asked, :season)) do
          nil -> nil
          number -> episodes(tracked, number, order)
        end

      _none ->
        nil
    end
  rescue
    _ -> nil
  end

  # The season the caller named, or the bookmark. Both `nil` answers mean what
  # the old `when is_integer(number)` guard meant when it failed: not a season
  # this screen can draw, so `season/1` falls back whole rather than drawing a
  # heading with no running order under it.
  defp season_number(_tracked, number) when is_integer(number), do: number

  defp season_number(%TrackedTitle{progress_season: number}, _asked) when is_integer(number),
    do: number

  defp season_number(_tracked, _asked), do: nil

  # The series the caller named, or — given no id — the most recently touched
  # one, which is what a bare push still gets. `Enum.find` over the same
  # `:shelf` reads rather than an `Ash.Query.filter` expression: see the note
  # above `load/1`. Reading through `:shelf` is also what keeps the season of a
  # show the user hid unreachable by id. The per-kind `limit(1)` is gone from
  # this direction on purpose — the named row need not be the newest of its
  # kind — and `newest_series/0`, which does need it, is left alone below.
  defp series_record(nil), do: newest_series()

  defp series_record(title_id) do
    @series_kinds
    |> Enum.flat_map(fn kind ->
      TrackedTitle
      |> Ash.Query.for_read(:shelf, %{kind: kind})
      |> Ash.read!()
    end)
    |> Enum.find(&(&1.id == title_id))
  end

  # The most recently touched series, across both kinds that have seasons.
  # `:shelf` rather than a filter written out here: it is the action
  # `Kati.Media.TrackedTitle` names for "screens 03, 20 and 21" and it is where
  # *keeps history, hides from shelf* is enforced, so a shelf that forgot the
  # flag would open the season of a show the user hid. `limit(1)` per kind
  # because each answers `last_touched_at` descending on its own, and the two
  # are then compared as one shelf rather than as two.
  defp newest_series do
    @series_kinds
    |> Enum.flat_map(fn kind ->
      TrackedTitle
      |> Ash.Query.for_read(:shelf, %{kind: kind})
      |> Ash.Query.limit(1)
      |> Ash.read!()
    end)
    |> Enum.max_by(& &1.last_touched_at, DateTime, fn -> nil end)
  end

  # A season with nothing cached in it is not a season this screen can draw. The
  # list IS the screen — an order strip and two switches over an empty card says
  # less than the drawing does — so it falls back whole rather than rendering a
  # heading with no running order under it.
  defp episodes(tracked, number, order) do
    case CachedEpisode.for_season(tracked.source, tracked.source_id, number) do
      [] -> nil
      episodes -> assemble(tracked, number, episodes ++ specials(tracked), order)
    end
  end

  @doc """
  Season 0, which is where every provider files the specials.

  *Include specials · Shown inline, at air date* was drawn switched ON above a
  list that contained none, because `for_season/3` reads one season number and
  0 is never it. A reader was shown a switch in its on position and a list that
  did not honour it. MOVIES-AND-TV.md #69.

  Inline and at air date is what the sub-line promises and what
  `Kati.Media.CachedEpisode.in_order/2` at `:aired` already does: it sorts by
  `{season_number, episode_number}`, so a special sorts ahead of the season
  rather than at its own air date — which is why these are merged into one list
  and re-sorted by air date below rather than concatenated.

  A provider that files no specials answers `[]`, and the switch then sits over
  a list that is complete without them, which is true.
  """
  @spec specials(TrackedTitle.t()) :: [CachedEpisode.t()]
  def specials(%TrackedTitle{} = tracked) do
    CachedEpisode.for_season(tracked.source, tracked.source_id, 0)
  rescue
    _error -> []
  end

  # The three parts of the drawing a season can actually fill, laid over the
  # drawn one. Everything not named here is the design's own and stays that way
  # — see the moduledoc for the list and for why each is on it.
  defp assemble(tracked, number, episodes, asked) do
    watches = ticks(tracked)
    ticked = CachedEpisode.ticked_ids(watches)
    # The same rows the ticks come from — see `Kati.Screens.Series.
    # ratings_by_episode/1`, which is where this screen's twin reads them and
    # therefore where both screens agree on what a rating is.
    ratings = Kati.Screens.Series.ratings_by_episode(watches)
    absolute = absolute_numbers(tracked)
    offered = Kati.Screens.Season.offered_orders(absolute)
    order = if asked in offered, do: asked, else: :aired

    rows =
      episodes
      |> ordered(order, absolute)
      |> Enum.map(&row(&1, ticked, ratings, order, absolute))

    drawn = drawn_season()

    %{
      drawn
      | title: heading(cached_season(tracked, number), number),
        # The page's own subtitle, over the drawing's copy of it. It is the
        # same label in the same words — see the moduledoc, it is a label
        # rather than data — and the only thing that changes is that a Persian
        # reader now gets it in Persian instead of the fixture's English.
        # `Kati.Season.Sample` keeps the literal it always had; this screen
        # does not edit the fixture, it says the label itself.
        subtitle: gettext("order & specials"),
        eyebrow: gettext("Episodes · %{n} in this order", n: Kati.Locale.number(length(rows))),
        episodes: rows,
        options: real_options(episodes),
        orders: Enum.map(offered, &Kati.Screens.Season.order_label/1),
        current_order: Kati.Screens.Season.order_label(order),
        note: general_note()
    }
    |> Map.put(:tracked_id, tracked.id)
    |> Map.put(:order, order)
  end

  # The whole series, not this season, and that is the entire point: absolute
  # order counts from the first episode of the show. `Kati.Media.CachedEpisode.
  # derived_absolute/1` answers `%{}` for a cache that cannot support the claim,
  # which is what keeps the Absolute tile off a half-fetched series.
  defp absolute_numbers(%TrackedTitle{} = tracked) do
    tracked.source
    |> CachedEpisode.for_title(tracked.source_id)
    |> CachedEpisode.derived_absolute()
  rescue
    _error -> %{}
  end

  # `in_order/2` reads the COLUMN, which no source Kati fetches from fills, so
  # at `:absolute` it would drop every episode and answer `[]`. The derived map
  # is the numbering this screen actually offers, so the sort and the drop go
  # through it too — one answer to "what is this episode's absolute number",
  # used to place the row and to label it.
  defp ordered(episodes, :aired, _absolute), do: CachedEpisode.in_order(episodes, :aired)

  defp ordered(episodes, :absolute, absolute) do
    episodes
    |> Enum.filter(&Map.has_key?(absolute, &1.source_id))
    |> Enum.sort_by(&Map.fetch!(absolute, &1.source_id))
  end

  @doc """
  The order tiles a real season can honour, which is at most two of three.

  MOVIES-AND-TV.md #97. The strip was the screen's central control and drew
  three tiles, none of them tappable. Making all three live would have been
  worse than leaving them dead: **DVD** has no numbers anywhere —
  `Kati.Media.CachedEpisode.orders/0` names two and its moduledoc says why —
  and **Absolute** had none either until `derived_absolute/1`, so a live
  Absolute tile over the column alone would have emptied the list.

  So the rule screen 35 keeps for a group with no schema, one control smaller:
  a tile with no numbers behind it is dropped rather than drawn dead. DVD
  always goes; Absolute goes whenever the cache cannot support the claim — a
  single-season show, a series with a season missing, a season with a gap in
  it. What is left is the tiles that renumber something.

  A strip of one is not a control, so `strip/1` draws nothing at all rather
  than one tile with nowhere to go. The board keeps its three: it is a drawing
  of a season this app cannot yet hold.

      iex> Kati.Screens.Season.offered_orders(%{})
      [:aired]

      iex> Kati.Screens.Season.offered_orders(%{"a" => 1})
      [:aired, :absolute]
  """
  @spec offered_orders(map()) :: [Kati.Media.CachedEpisode.order()]
  def offered_orders(absolute) when map_size(absolute) == 0, do: [:aired]
  def offered_orders(_absolute), do: CachedEpisode.orders()

  @doc """
  A tile's label, and the atom behind one.

  The drawing writes the labels and `Kati.Media.CachedEpisode` writes the
  atoms, so the two are paired here once rather than at each end — a strip that
  lights *Absolute* and a list sorted `:aired` is the disagreement the whole
  finding is about.

      iex> Kati.Screens.Season.order_label(:absolute)
      "Absolute"

      iex> Kati.Screens.Season.order_from("Aired")
      :aired

      iex> Kati.Screens.Season.order_from("DVD")
      nil
  """
  @spec order_label(Kati.Media.CachedEpisode.order()) :: String.t()
  def order_label(:aired), do: "Aired"
  def order_label(:absolute), do: "Absolute"

  @doc false
  @spec order_from(String.t()) :: Kati.Media.CachedEpisode.order() | nil
  def order_from("Aired"), do: :aired
  def order_from("Absolute"), do: :absolute
  def order_from(_dvd), do: nil

  @doc """
  What a tile READS, which is not what a tile IS.

  mishka-group/kati#103. `order_label/1` is this screen's identity for an
  order and it has to stay English: it is what `:orders` and `:current_order`
  hold, what `order_tap/2` builds `:order_Aired` out of, and what
  `order_from/1` parses back on the way in. Translating it would have made the
  tag `:order_پخش` and `order_from/1` answer `nil` for it, so every tile on a
  Persian page would have gone dead — the label is state here, and state is
  not copy.

  So the word the reader sees is asked for separately, at the moment it is
  drawn. `DVD` falls through untranslated on purpose: it is only ever the
  board's tile (see `offered_orders/1`), and it is a format's name rather than
  a word — board 127 leaves `Lumen+` in Latin on a Persian page for the same
  reason.

      iex> Kati.Screens.Season.order_title("DVD")
      "DVD"
  """
  @spec order_title(String.t()) :: String.t()
  def order_title("Aired"), do: pgettext("episode order", "Aired")
  def order_title("Absolute"), do: pgettext("episode order", "Absolute")
  def order_title(other), do: other

  @doc """
  The switches a real season can honour, which is one of the drawing's two.

  *Include specials* is wired and drawn in the state the list is actually in:
  on when a special is in it, off when the provider filed none. *Merge
  multi-part* is dropped, and the moduledoc says why — merging a two-part
  finale is a transformation of the order with nothing to record that it
  happened, and no column marks an episode as merged or pairs it with its other
  half. A switch that cannot be honoured is not offered.

  The board keeps both: it is a drawing of a season this app cannot yet hold.
  """
  @spec real_options([CachedEpisode.t()]) :: [map()]
  def real_options(episodes) do
    any? = Enum.any?(episodes, & &1.special)

    [
      %{
        icon: "star",
        title: gettext("Include specials"),
        # NOT *Shown inline, at air date*, which is the board's wording and is
        # what `in_order(:aired)` cannot deliver: it sorts by `{season_number,
        # episode_number}` and every season-0 special therefore sorts ahead of
        # the whole season. Re-sorting by `air_at` was tried and reverted —
        # `Kati.Media.CachedEpisode.in_order/2` argues at length that its
        # `{season, episode}` sort IS broadcast order for every source Kati
        # fetches from, and a screen that quietly used a different one would be
        # the renumbering its own footnote warns about.
        #
        # So the sub-line says where they are. A special a provider filed
        # INSIDE the season keeps its own place, which is why this says
        # `first` rather than `at the top`.
        sub:
          if(any?,
            do: gettext("Listed first, before the season"),
            else: gettext("None filed for this season")
          ),
        on: any?
      }
    ]
  end

  # One read, by the triple `Kati.Media.CachedSeason` is keyed on. `nil` is the
  # evicted case and is ordinary: `heading/2` answers from the number instead.
  defp cached_season(%TrackedTitle{} = tracked, number) do
    CachedSeason.by_reference(tracked.source, tracked.source_id, number)
  end

  # `:episode_ticks` rather than every watch: this screen asks one question of
  # the history — is this episode ticked — and a whole-title watch carries no
  # episode id to answer it with.
  defp ticks(%TrackedTitle{id: id}) do
    Watch
    |> Ash.Query.for_read(:episode_ticks, %{tracked_title_id: id})
    |> Ash.read!()
  end

  # The provider's own name for the season where it gave one — "Season 2", but
  # also "Specials", "Miniseries", "Part 1". `Kati.Media.CachedSeason` declines
  # to invent one and says why: *"a screen that wants 'Season 2' out of a bare
  # number is the thing that knows what its own heading should read"*. This is
  # that screen, and 0 is the specials shelf every source files them on.
  #
  # The provider's own name is left exactly as the provider wrote it — it is
  # fetched data, and no msgid reaches it — so a Persian page can head itself
  # `Season 2` where TMDB said so. The two Kati writes itself are translated,
  # and `Season %{n}` is `Kati.Screens.Series`' own msgid rather than a second
  # spelling of it.
  defp heading(%CachedSeason{name: name}, _number) when is_binary(name) and name != "", do: name
  defp heading(_season, 0), do: gettext("Specials")
  defp heading(_season, number), do: gettext("Season %{n}", n: Kati.Locale.number(number))

  # One episode in the shape `episode/1` reads. `special` is stored, so both
  # marks the design gives it — the bronze number and the badge — come off the
  # one column rather than being decided twice.
  defp row(%CachedEpisode{} = episode, ticked, ratings, order, absolute) do
    %{
      # Your verdict on this episode, for the trailing column board 143 draws
      # and the door onto the sheet that writes it.
      rating: Map.get(ratings, episode.source_id),
      # What a tick is written against. `Kati.Media.Watch` names an episode by
      # `episode_source_id` and nothing else, and this row carried the NUMBER —
      # which is the one thing this screen's own footnote says a tick must not
      # follow.
      source_id: episode.source_id,
      # The two `Kati.Media.Watch` columns a tick fills, and they are NOT the
      # label above. `number` is a string — `E6`, `S1`, or `""` for an episode
      # a source never placed — and `episode_number` is an integer column, so
      # `write_tick/2`'s `Map.get(episode, :n) || Map.get(episode, :number)`
      # was handing Ash `"E6"` and every tick made on this screen came back
      # `Is invalid.`. Screen 04's rows have carried `:n` and `:season` since
      # #46; this screen's never did, and its tick had never been pressed on a
      # real season.
      #
      # Off the COLUMNS and never off the chosen order: the tick is a fact
      # about which episode, and screen 07 draws `S2 E5` whichever numbering
      # the reader happened to be looking at. That is the footnote — your ticks
      # follow the episode, not the number.
      season: episode.season_number,
      n: episode.episode_number,
      number: number_label(episode, order, absolute),
      title: title_of(episode),
      sub: sub_line(episode),
      watched: CachedEpisode.ticked?(episode, ticked),
      special: episode.special,
      # `airing != :upcoming`, which is `Kati.Screens.Series.episode_row/2`'s
      # rule and its comment: `Kati.Media.Release.airing/2`'s `:unknown` is
      # grouped with `:aired`, because withholding the tick is a claim the user
      # has not seen it, and the thing Kati does not know is when it went out.
      # `air_phrase/2` has already resolved this episode once; resolving it a
      # second time here rather than threading the value through keeps the two
      # readings of `Release` beside the two things they decide.
      aired: Release.airing(Release.air(episode), Kati.Time.now()) != :upcoming,
      badge: badge_for(episode)
    }
  end

  # `pgettext/2` for a one-word badge: `mix gettext.merge` fuzzy-matches a short
  # msgid against any sentence that happens to contain it, and `SPECIAL` is a
  # word half this screen's copy uses. The context is what keeps the badge's
  # own word its own.
  defp badge_for(%CachedEpisode{special: true}),
    do: %{label: pgettext("episode badge", "SPECIAL"), tone: :cream}

  defp badge_for(%CachedEpisode{}), do: nil

  # `E6`, and `S1` for a special. The number is what the CHOSEN order calls this
  # episode and never what the row happens to carry, which is why the order is
  # an argument: the two must not be able to disagree about which scheme is on
  # screen. At `:absolute` the answer comes from the same derived map the sort
  # used, so a row cannot be placed by one numbering and labelled by another.
  #
  # An unnumbered episode draws nothing rather than a bare prefix. TVmaze gives
  # some specials no placement at all, and `S` alone is a label for a position
  # nobody asserted.
  defp number_label(%CachedEpisode{} = episode, :aired, _absolute) do
    case CachedEpisode.number_in(episode, :aired) do
      nil -> ""
      n -> numbered(episode.special, n)
    end
  end

  # No `S` prefix at absolute: `ordered/3` has already dropped every special,
  # so there is no special left to prefix, and an episode this order cannot
  # place is not in the list to be labelled.
  defp number_label(%CachedEpisode{} = episode, :absolute, absolute) do
    case Map.get(absolute, episode.source_id) do
      nil -> ""
      n -> numbered(false, n)
    end
  end

  # `E6` and `S1`, in the reader's own letters and digits: `ق۶`, `و۱`. The
  # prefix is an abbreviation of a word — قسمت for an episode, ویژه for a
  # special — so it is translated rather than kept as a Latin initial, and the
  # episode one is the msgid `Kati.Screens.Inbox` already spells with the same
  # `episode number` context rather than a second entry saying the same thing.
  # The special takes its own context: `S` in this app already means فصل, a
  # SEASON, in `Kati.Screens.Library`'s `S%{s} · E%{e}` — one msgid cannot be
  # both, and a special numbered `ف۱` on the specials shelf would be a claim
  # about season 1.
  #
  # The digits convert because the face does: `episode_body/3` asks
  # `Kati.Locale.mono_face/1` about this very string, and a label with a
  # Persian letter in it is set in Vazirmatn, which has ۰–۹. `kati_mono.ttf`
  # never sees them.
  defp numbered(true, n), do: pgettext("special number", "S%{n}", n: Kati.Locale.number(n))
  defp numbered(_ordinary, n), do: pgettext("episode number", "E%{e}", e: Kati.Locale.number(n))

  defp title_of(%CachedEpisode{title: title}) when is_binary(title) and title != "", do: title
  defp title_of(%CachedEpisode{}), do: gettext("Untitled")

  # `54m · 9 Jul`, and either half may be missing — a provider can decline a
  # runtime and an unannounced episode has no date. An absent half is left out
  # rather than spelled as a dash, the way `Kati.Screens.Film.meta_line/1` does.
  defp sub_line(%CachedEpisode{} = episode) do
    [runtime_label(episode), air_label(episode)]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" · ")
  end

  # `Kati.Screens.SeriesMeta`'s own msgid, which is `54m` in Latin and
  # `۵۴ دقیقه` in Persian: the minute's abbreviation is a Latin convention and
  # Persian writes the word out.
  defp runtime_label(%CachedEpisode{runtime_minutes: m}) when is_integer(m) and m > 0,
    do: gettext("%{n}m", n: Kati.Locale.number(m))

  defp runtime_label(%CachedEpisode{}), do: nil

  # `9 Jul` for something that has gone out, `airs 20 Aug` for something that
  # has not — the two states the drawing distinguishes, and it reads both off
  # `Kati.Media.Release` rather than comparing `air_at` here. That module is the
  # one date path (#74): an episode a source described as "some time in March"
  # resolves to a period with no day in it, and this line then draws the runtime
  # alone rather than the first of the month wearing a date's clothes.
  #
  # `Kati.Locale.date/2` at `:short` rather than `Calendar.strftime/2`, and
  # that is a CALENDAR and not a format: 20 Aug 2026 is ۲۹ مرداد ۱۴۰۵, and
  # neither is a spelling of the other.
  defp air_label(%CachedEpisode{} = episode) do
    resolution = Release.air(episode)

    case air_date(resolution) do
      nil -> nil
      date -> air_phrase(resolution, Kati.Locale.date(date, :short))
    end
  end

  defp air_date({:exact, at, _origin}) do
    at |> Kati.Time.in_zone(Kati.Time.device_zone()) |> DateTime.to_date()
  end

  defp air_date({:day, date, _origin}), do: date
  defp air_date(_resolution), do: nil

  # `Kati.Media.Release.airing/2`'s third answer is `:unknown` — day precision
  # on today itself, which is precisely not knowing the hour — and it takes the
  # `airs` prefix along with `:upcoming`. An episode that goes out at 20:00 has
  # not gone out at 09:00, and the empty ring beside it is an affordance the
  # user should not be offered for something nobody has seen.
  #
  # The whole phrase and not a prefix glued to a date. `airs ` alone is not a
  # translatable unit: Persian puts the verb where the sentence wants it, and a
  # bare prefix has nowhere to move to. `pgettext/2` because two words is
  # exactly the length `mix gettext.merge` fuzzy-matches onto a longer
  # sentence, and the app already has an `Airs %{date}` of its own that this
  # must not be merged into — that one heads a card and this one sits inside a
  # `55m · airs 20 Aug` line, which is why it is lowercase.
  defp air_phrase(resolution, date) do
    if Release.airing(resolution, Kati.Time.now()) == :aired,
      do: date,
      else: pgettext("episode sub-line", "airs %{date}", date: date)
  end

  @doc false
  def content(assigns) do
    s = assigns.season

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {Kati.Screens.ShowPages.chrome(
          Kati.Screens.Season,
          Map.get(s, :tracked_id),
          Map.get(assigns, :menu?, false)
        )}
        {SettingsList.title(s.title, s.subtitle, nil, :meta_tight)}
        {Kati.Screens.Season.orders(s)}
        {Kati.Screens.Season.options(s)}
        {Kati.Screens.Season.refusal(Map.get(assigns, :save_error))}
        {UI.eyebrow(s.eyebrow)}
        {Kati.Screens.Season.episodes(s)}
        {Kati.Screens.Season.note(s)}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The order strip, or nothing when there is nothing to choose between.

  A segmented control with one segment is not a control — it is a label that
  looks pressable — so a season whose cache can only support Aired draws no
  strip at all. See `offered_orders/1`.
  """
  @spec orders(map()) :: map()
  def orders(%{orders: [_only_one]}), do: ~MOB"<Spacer size={0} />"

  def orders(s) do
    tiles =
      s.orders
      |> Enum.map(fn label ->
        Kati.Screens.Season.order(label, label == s.current_order, Map.get(s, :order))
      end)
      |> Enum.intersperse(Kati.Screens.Season.order_gap())

    assigns = %{tiles: tiles, help: {self(), :explain_numbering}}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Row
          weight={1.0}
          background={Palette.placeholder()}
          corner_radius={16}
          padding={4}
          align="center"
        >
          {@tiles}
        </Row>
        <Spacer size={9} />
        {Kati.Screens.Season.explain_disc(@help)}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc """
  The `help` disc beside the order strip, which opens screen 153.

  MOVIES-AND-TV.md #9: 153 explains the Aired/Absolute/DVD choice and nothing
  pushed it — including this screen, which draws that choice as a three-tile
  strip a reader will want explained. The finding's own fix, in its own words:
  *push it from screen 34 — a note row or an info glyph beside the order
  strip*.

  A disc rather than a note row, because the strip is a row and a note under it
  would read as a caption on the season rather than on the choice. It is drawn
  only where the strip is: a season that can offer one order has no choice to
  explain.
  """
  @spec explain_disc(term()) :: map()
  def explain_disc(tap) do
    Kati.Components.MishkaActionIcon.action_icon(
      [
        size: 34,
        shape: :circle,
        variant: :filled,
        background: Palette.placeholder(),
        on_tap: tap
      ],
      [Kati.UI.symbol("help", size: 17, color: Palette.ink_soft())]
    )
  end

  @doc """
  A tile's tap, or `nil` when pressing it could not change anything.

  Two ways to be `nil`, and they are different facts:

    * **DVD**, which only the board draws. No source Kati fetches from carries
      per-episode DVD numbering — `Kati.Media.CachedEpisode`'s moduledoc gives
      the whole reason — so the tile cannot renumber anything on any season.
    * **Every tile on the board.** `season/2` answers the drawing when there is
      no tracked season to read, and the drawing is the same list whichever
      order is asked for, so a live tile there would redraw itself and call it
      a change. A real season carries `:order`; the drawing does not, which is
      what `current` distinguishes.

  The second is the rule screen 35's status tiles keep, one screen over: a
  control that exists only over data is not drawn over the picture of it.

      iex> Kati.Screens.Season.order_tap("DVD", :aired)
      nil

      iex> Kati.Screens.Season.order_tap("Absolute", nil)
      nil
  """
  @spec order_tap(String.t(), Kati.Media.CachedEpisode.order() | nil) ::
          {pid(), atom()} | nil
  def order_tap(_label, nil), do: nil

  def order_tap(label, _current) do
    if Kati.Screens.Season.order_from(label), do: {self(), String.to_atom("order_" <> label)}
  end

  @doc false
  def order_gap, do: ~MOB"<Spacer size={4} />"

  # The chosen tile keeps its tap for screen 35's reason: pressing *Aired* on a
  # list already in aired order is how somebody checks which order they are in,
  # and a tile that goes dead once chosen stops answering exactly when it is
  # pressed to be sure. It re-reads and re-renders the same list.
  @doc false
  def order(label, true, current) do
    assigns = %{
      tap: Kati.Screens.Season.order_tap(label, current),
      # The tile's WORD, asked for at the moment it is drawn. `label` stays the
      # English identity the tag and `order_from/1` are built on — see
      # `order_title/1`.
      title: Kati.Screens.Season.order_title(label)
    }

    ~MOB"""
    <Box weight={1.0} on_tap={@tap}>
      <Box
        fill_width={true}
        height={34}
        corner_radius={12}
        background={Palette.card()}
        shadow="0 1 2 0 #0F1A1917 | 0 6 12 -8 #661A1917"
        align="center"
      >
        <Text
          text={@title}
          text_size={12.5}
          font_weight="bold"
          text_color={:on_surface}
          max_lines={1}
        />
      </Box>
    </Box>
    """
  end

  def order(label, false, current) do
    assigns = %{
      tap: Kati.Screens.Season.order_tap(label, current),
      title: Kati.Screens.Season.order_title(label)
    }

    ~MOB"""
    <Box weight={1.0} on_tap={@tap}>
      <Box fill_width={true} height={34} corner_radius={12} align="center">
        <Text
          text={@title}
          text_size={12.5}
          font_weight="semibold"
          text_color={Palette.segment_idle()}
          max_lines={1}
        />
      </Box>
    </Box>
    """
  end

  @doc false
  def options(s) do
    rows = s.options
    last = length(rows) - 1

    body =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, i} ->
        SettingsList.row(
          SettingsList.icon_tile(row.icon),
          SettingsList.body(row.title, row.sub),
          SettingsList.switch(row.on),
          padding: 13,
          rule: i < last
        )
      end)

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(body)}
      <Spacer size={20} />
    </Column>
    """
  end

  # The tag carries the row's POSITION in the list, not its number — the same
  # move, for the same reason, as `Kati.Screens.Series.episodes/1`: this screen
  # renumbers the same episodes under three schemes and `number_label/1` answers
  # `""` for a special a source never placed, so the number is a label and never
  # an identity. `:index` goes onto the row rather than into a second argument
  # so `episode/1` keeps the arity it has.
  @doc """
  A tick the store refused, said out loud.

  The mirror of `Kati.Screens.Series.refusal/1`, and open for the same reason:
  `:save_error` has been assigned here since the tick could fail and was drawn
  nowhere, so a refused tick left the row unfilled and the page silent.
  MOVIES-AND-TV.md #39 names both screens.

  Above the episode list, because the list is the thing that failed to change.
  """
  @spec refusal(String.t() | nil) :: map()
  def refusal(nil), do: ~MOB"<Spacer size={0} />"

  def refusal(message) do
    assigns = %{message: message}

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.note("error", @message)}
      <Spacer size={14} />
    </Column>
    """
  end

  @doc false
  def episodes(s) do
    rows = s.episodes |> Enum.with_index() |> Enum.map(fn {ep, i} -> Map.put(ep, :index, i) end)

    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(rows, fn ep -> Kati.Screens.Season.episode(ep) end)}
    </Column>
    """
  end

  @doc false
  def episode(ep) do
    watched? = ep.watched
    bg = if watched?, do: Palette.card_settled(), else: Palette.card()
    title_color = if watched?, do: Palette.settled_ink(), else: Palette.ink()

    number_color =
      if Map.get(ep, :special, false), do: Palette.gold_icon(), else: Palette.tertiary()

    # An episode that has not aired cannot be marked watched, so it gets no tap
    # at all rather than a tap that silently does nothing — the rule
    # `Kati.Screens.Series.episode/1` keeps one screen over. A row that reached
    # here without going through `episodes/1` has no position to name and gets
    # none either. The check disc is unchanged in both cases: board 34 draws two
    # ring states and not three, and E6 and E7 are drawn the same, so this
    # screen does not gain a visual distinction the drawing declines to make.
    tap =
      case {Map.get(ep, :aired, true), Map.get(ep, :index)} do
        {true, i} when is_integer(i) -> {self(), String.to_atom("episode_#{i}")}
        _unaired_or_unplaced -> nil
      end

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.Season.episode_row(ep, bg, title_color, number_color, watched?, tap)}
      <Spacer size={8} />
    </Column>
    """
  end

  # Two clauses rather than one with a conditional `shadow`, because a watched
  # row sits flat in the paper and an unaired one is lifted off it — that is
  # the difference the drawing uses to say "there is still something to do
  # here", and a nil shadow prop would quietly flatten both.
  #
  # The tap goes on the whole Row and not on the check disc: a card whose ring
  # is tappable and whose title is not reads as two controls.
  # `Kati.Screens.Series.episode/1` puts it in the same place, and
  # `nil` is the legal "not tappable" value `Kati.ScreenSweep.tap_tags/1`
  # documents. The sixth argument is defaulted so `episode_row/5` still answers.
  @doc false
  def episode_row(ep, bg, title_color, number_color, watched?, tap \\ nil)

  def episode_row(ep, bg, title_color, number_color, true, tap) do
    ~MOB"""
    <Row
      fill_width={true}
      on_tap={tap}
      background={bg}
      corner_radius={17}
      padding_left={15}
      padding_right={15}
      padding_top={13}
      padding_bottom={13}
      align="center"
    >
      {Kati.Screens.Season.episode_body(ep, title_color, number_color)}
      {Kati.Screens.Season.rating_column(ep)}
      {Kati.Screens.Season.check(true)}
    </Row>
    """
  end

  def episode_row(ep, bg, title_color, number_color, false, tap) do
    ~MOB"""
    <Row
      fill_width={true}
      on_tap={tap}
      background={bg}
      corner_radius={17}
      shadow={Kati.Theme.shadow_card_soft()}
      padding_left={15}
      padding_right={15}
      padding_top={13}
      padding_bottom={13}
      align="center"
    >
      {Kati.Screens.Season.episode_body(ep, title_color, number_color)}
      {Kati.Screens.Season.rating_column(ep)}
      {Kati.Screens.Season.check(false)}
    </Row>
    """
  end

  # `weight`, not `fill_width`: this Row is a sibling of the watched tick inside
  # the episode row, and a sibling that fills the width leaves the tick nothing
  # to sit in — the disc was being measured past the right edge of every card.
  # A weight takes what is left once the 27pt disc has had its share.
  #
  # Both mono lines ask `Kati.Locale.mono_face/1` about their own string rather
  # than naming `"mono"`. `kati_mono.ttf` carries no Persian glyph, so a line
  # that reads `ق۶` or `۵۵ دقیقه · پخش ۲۹ مرداد` in DM Mono is a row of empty
  # boxes — and asking the STRING rather than the reader is what keeps a
  # provider's Latin runtime line in the drawing's own face on a Persian page.
  @doc false
  def episode_body(ep, title_color, number_color) do
    ~MOB"""
    <Row weight={1.0} align="center">
      <Column width={22}>
        <Text
          text={ep.number}
          font_family={Kati.Locale.mono_face(ep.number)}
          text_size={12}
          text_color={number_color}
          max_lines={1}
        />
      </Column>
      <Spacer size={13} />
      <Column weight={1.0}>
        <Row fill_width={true} align="center">
          <Text
            text={ep.title}
            text_size={14}
            font_weight="semibold"
            text_color={title_color}
            max_lines={1}
          />
          {Kati.Screens.Season.badge(Map.get(ep, :badge))}
        </Row>
        <Spacer size={4} />
        <Text
          text={ep.sub}
          font_family={Kati.Locale.mono_face(ep.sub)}
          text_size={10.5}
          text_color={Palette.tertiary()}
          max_lines={1}
        />
      </Column>
      <Spacer size={13} />
    </Row>
    """
  end

  @doc false
  def badge(nil), do: ~MOB"<Spacer size={0} />"

  def badge(badge) do
    {bg, fg} =
      case badge.tone do
        :cream -> {Palette.cream(), Palette.gold_text()}
        _ -> {Palette.paper(), Palette.ink_soft()}
      end

    ~MOB"""
    <Row align="center">
      <Spacer size={7} />
      {Kati.Screens.Season.badge_pill(badge.label, bg, fg)}
    </Row>
    """
  end

  @doc """
  The `SPECIAL` tag itself: `Kati.Components.MishkaPill`.

  A pill is a compact label in a coloured token, which is the whole of what this
  is — no state, nothing to remove, so none of `MishkaChip`'s `checked` and none
  of the pill's own `with_remove`.

  `padding: 0` is load-bearing. A pill always writes a `padding` key defaulting
  to `:space_sm`, and `MobBridge.kt` resolves an unspecified edge against that
  uniform (`pad(v) = (v ?: uniform ?: 0)`), so `padding_left`/`padding_right`
  alone would leave the drawing's 18pt badge padded top and bottom as well.
  """
  def badge_pill(label, background, color) do
    MishkaPill.pill(
      label: label,
      background: background,
      color: color,
      height: 18,
      corner_radius: 9,
      padding: 0,
      padding_left: 7,
      padding_right: 7,
      text_size: 9.5,
      font_weight: :bold,
      align: :center
    )
  end

  @doc """
  The watched tick and the empty ring, both `Kati.Components.MishkaThemeIcon` —
  "a themed container around exactly one icon", and in the ring's case around
  none.

  `variant: :filled` with an explicit `color` paints the ink disc; `:subtle`
  paints nothing at all (its skin's `background` is `nil`, which the component
  leaves off the node rather than sending as a null) and takes the drawing's
  ring through `border_color` / `border_width`. `border_width` is read with
  `floatProp`, so the 1.5 survives.

  ## The tick inverts, it does not follow

  The disc is an ink-filled control, so it takes the pair the design draws for
  one: `Palette.ink_fill/0` under `Palette.on_ink/0` — `#1A1917` + `#FBFAF8` in
  light, `#F7EFE4` + `#1A1917` in dark, the fill swapping sides of the ramp
  rather than darkening with the page. Screen 12's identical 27pt tick is
  already written that way. `Kati.Theme.ink/0` was the fill before and takes no
  mode, so in dark the disc and its check would both have been near-black.

  ## Why the pixels do not move

  `check(true)` returns `Box{width: 27, height: 27, align: :center,
  corner_radius: 14, background: ink_fill}` around the glyph — node for node what
  was written by hand. `check(false)` adds one prop the hand-rolled version did
  not carry, `align: :center`, on a box with no children: there is nothing to
  align.
  """
  def check(true) do
    MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Palette.ink_fill(), size: 27, radius: 14},
      [Kati.UI.symbol("check", size: 16, color: Palette.on_ink())]
    )
  end

  def check(false) do
    MishkaThemeIcon.theme_icon(%{
      variant: :subtle,
      size: 27,
      radius: 14,
      border_color: Palette.border(),
      border_width: 1.5
    })
  end

  # Solid, not dashed: `Modifier.border` takes a width and a colour and no
  # PathEffect. The 1.5pt weight, the alpha and this drawing's own 15pt padding
  # are literal; the stitching is what does not survive.
  #
  # The leading is the one number here that is not literal. Vazirmatn's
  # ascenders and its descenders are taller than Plus Jakarta's, so the
  # drawing's 1.55 sets the footnote's two Persian lines almost touching —
  # `Kati.Locale.leading/1` is where that correction is kept, and this is a
  # paragraph rather than a label, which is exactly what it is for.
  @doc false
  def note(s) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={8} />
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
        <Text
          text={s.note}
          text_size={12.5}
          line_height={Kati.Locale.leading(1.55)}
          text_color={Palette.ink_soft()}
          weight={1.0}
        />
      </Row>
    </Column>
    """
  end
end
