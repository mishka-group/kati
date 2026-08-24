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
    * **`Include specials` and `Merge multi-part`.** Two switches on a card, and
      neither has a column. `Kati.Media.TrackedTitle` carries the four per-show
      switches screen 35 draws and none of these: they are per-*season* display
      choices about how an order is built, and `Kati.Media.CachedEpisode` is a
      cache, which is the one place a user's choice must never live. Both are
      therefore drawn in their design state and neither changes what is read —
      which is why a real season lists what `for_season/3` returns for the
      bookmarked number and does not reach into season 0 for the specials the
      first switch would include.
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
  the same class of literal as screen 08's action row.

  """
  use Kati.Screens.Pushed, back: "Series"

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
  @general_note "Your ticks follow the episode, not the number."

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :season, season())

  @doc """
  The season this screen draws: the user's, or the drawing's.

  The gate is the list rather than the page, because the page is not all one
  kind of fact — the order strip and the two switches have no store at all (see
  the moduledoc) and are the design's in both branches. What moves together is
  the header, the count and the rows, and those are one season or they are the
  drawing's.
  """
  @spec season() :: map()
  def season, do: tracked_season() || drawn_season()

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
  The season the user is bookmarked in, shaped for the markup, or `nil`.

  `nil` is the ordinary answer three times over — nothing tracked, no
  `progress_season` on the row that is, or a season whose episodes have not been
  fetched — and it is the answer `season/0` reads as *draw the drawing*. A
  database that cannot be read at all answers `nil` too: `Ash.read!` on a device
  mid-migration raises, and a screen that dies is strictly worse than a screen
  showing the values it was drawn from — the same degradation
  `Kati.Screens.Library.shelf/0` and `Kati.Calendars.Today` make.
  """
  @spec tracked_season() :: map() | nil
  def tracked_season do
    case newest_series() do
      %TrackedTitle{progress_season: number} = tracked when is_integer(number) ->
        episodes(tracked, number)

      _none ->
        nil
    end
  rescue
    _ -> nil
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
  defp episodes(tracked, number) do
    case CachedEpisode.for_season(tracked.source, tracked.source_id, number) do
      [] -> nil
      episodes -> assemble(tracked, number, episodes)
    end
  end

  # The three parts of the drawing a season can actually fill, laid over the
  # drawn one. Everything not named here is the design's own and stays that way
  # — see the moduledoc for the list and for why each is on it.
  defp assemble(tracked, number, episodes) do
    ticked = tracked |> ticks() |> CachedEpisode.ticked_ids()
    rows = episodes |> CachedEpisode.in_order(:aired) |> Enum.map(&row(&1, ticked))
    drawn = drawn_season()

    %{
      drawn
      | title: heading(cached_season(tracked, number), number),
        eyebrow: "Episodes · #{length(rows)} in this order",
        episodes: rows,
        note: @general_note
    }
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
  defp heading(%CachedSeason{name: name}, _number) when is_binary(name) and name != "", do: name
  defp heading(_season, 0), do: "Specials"
  defp heading(_season, number), do: "Season #{number}"

  # One episode in the shape `episode/1` reads. `special` is stored, so both
  # marks the design gives it — the bronze number and the badge — come off the
  # one column rather than being decided twice.
  defp row(%CachedEpisode{} = episode, ticked) do
    %{
      number: number_label(episode),
      title: title_of(episode),
      sub: sub_line(episode),
      watched: CachedEpisode.ticked?(episode, ticked),
      special: episode.special,
      badge: badge_for(episode)
    }
  end

  defp badge_for(%CachedEpisode{special: true}), do: %{label: "SPECIAL", tone: :cream}
  defp badge_for(%CachedEpisode{}), do: nil

  # `E6`, and `S1` for a special. The number is what the chosen order calls this
  # episode, which is why it goes through `number_in/2` rather than being read
  # off the column: the Absolute tile would answer from `absolute_number`, and
  # the two must not be able to disagree about which scheme is being drawn.
  #
  # An unnumbered episode draws nothing rather than a bare prefix. TVmaze gives
  # some specials no placement at all, and `S` alone is a label for a position
  # nobody asserted.
  defp number_label(%CachedEpisode{} = episode) do
    case CachedEpisode.number_in(episode, :aired) do
      nil -> ""
      n -> if episode.special, do: "S#{n}", else: "E#{n}"
    end
  end

  defp title_of(%CachedEpisode{title: title}) when is_binary(title) and title != "", do: title
  defp title_of(%CachedEpisode{}), do: "Untitled"

  # `54m · 9 Jul`, and either half may be missing — a provider can decline a
  # runtime and an unannounced episode has no date. An absent half is left out
  # rather than spelled as a dash, the way `Kati.Screens.Film.meta_line/1` does.
  defp sub_line(%CachedEpisode{} = episode) do
    [runtime_label(episode), air_label(episode)]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" · ")
  end

  defp runtime_label(%CachedEpisode{runtime_minutes: m}) when is_integer(m) and m > 0, do: "#{m}m"
  defp runtime_label(%CachedEpisode{}), do: nil

  # `9 Jul` for something that has gone out, `airs 20 Aug` for something that
  # has not — the two states the drawing distinguishes, and it reads both off
  # `Kati.Media.Release` rather than comparing `air_at` here. That module is the
  # one date path (#74): an episode a source described as "some time in March"
  # resolves to a period with no day in it, and this line then draws the runtime
  # alone rather than the first of the month wearing a date's clothes.
  defp air_label(%CachedEpisode{} = episode) do
    resolution = Release.air(episode)

    case air_date(resolution) do
      nil -> nil
      date -> air_prefix(resolution) <> Calendar.strftime(date, "%-d %b")
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
  defp air_prefix(resolution) do
    if Release.airing(resolution, Kati.Time.now()) == :aired, do: "", else: "airs "
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
        {SettingsList.chrome("more_horiz", 44)}
        {SettingsList.title(s.title, s.subtitle, nil, :meta_tight)}
        {Kati.Screens.Season.orders(s)}
        {Kati.Screens.Season.options(s)}
        {UI.eyebrow(s.eyebrow)}
        {Kati.Screens.Season.episodes(s)}
        {Kati.Screens.Season.note(s)}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def orders(s) do
    tiles =
      s.orders
      |> Enum.map(fn label -> Kati.Screens.Season.order(label, label == s.current_order) end)
      |> Enum.intersperse(Kati.Screens.Season.order_gap())

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.placeholder()}
        corner_radius={16}
        padding={4}
        align="center"
      >
        {tiles}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc false
  def order_gap, do: ~MOB"<Spacer size={4} />"

  @doc false
  def order(label, true) do
    ~MOB"""
    <Box weight={1.0}>
      <Box
        fill_width={true}
        height={34}
        corner_radius={12}
        background={Palette.card()}
        shadow="0 1 2 0 #0F1A1917 | 0 6 12 -8 #661A1917"
        align="center"
      >
        <Text
          text={label}
          text_size={12.5}
          font_weight="bold"
          text_color={:on_surface}
          max_lines={1}
        />
      </Box>
    </Box>
    """
  end

  def order(label, false) do
    ~MOB"""
    <Box weight={1.0}>
      <Box fill_width={true} height={34} corner_radius={12} align="center">
        <Text
          text={label}
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

  @doc false
  def episodes(s) do
    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(s.episodes, fn ep -> Kati.Screens.Season.episode(ep) end)}
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

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.Season.episode_row(ep, bg, title_color, number_color, watched?)}
      <Spacer size={8} />
    </Column>
    """
  end

  # Two clauses rather than one with a conditional `shadow`, because a watched
  # row sits flat in the paper and an unaired one is lifted off it — that is
  # the difference the drawing uses to say "there is still something to do
  # here", and a nil shadow prop would quietly flatten both.
  @doc false
  def episode_row(ep, bg, title_color, number_color, true) do
    ~MOB"""
    <Row
      fill_width={true}
      background={bg}
      corner_radius={17}
      padding_left={15}
      padding_right={15}
      padding_top={13}
      padding_bottom={13}
      align="center"
    >
      {Kati.Screens.Season.episode_body(ep, title_color, number_color)}
      {Kati.Screens.Season.check(true)}
    </Row>
    """
  end

  def episode_row(ep, bg, title_color, number_color, false) do
    ~MOB"""
    <Row
      fill_width={true}
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
      {Kati.Screens.Season.check(false)}
    </Row>
    """
  end

  # `weight`, not `fill_width`: this Row is a sibling of the watched tick inside
  # the episode row, and a sibling that fills the width leaves the tick nothing
  # to sit in — the disc was being measured past the right edge of every card.
  # A weight takes what is left once the 27pt disc has had its share.
  @doc false
  def episode_body(ep, title_color, number_color) do
    ~MOB"""
    <Row weight={1.0} align="center">
      <Column width={22}>
        <Text
          text={ep.number}
          font_family="mono"
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
          font_family="mono"
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
          line_height={1.55}
          text_color={Palette.ink_soft()}
          weight={1.0}
        />
      </Row>
    </Column>
    """
  end
end
