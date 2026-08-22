defmodule Kati.Screens.Library do
  @moduledoc """
  Screen 03 — Library.

  Built to `.scratch/design/screens/03.html`: a segmented control on a
  `#E4E0D9` trough, three quick tiles carrying mono counts, chips with counts
  at .65 opacity, and a three-across grid of 158-tall posters each with a
  progress bar burnt into its bottom edge.

  **Books and Music are drawn inactive**, and that is the design's own
  decision, not a shortcut: #60 settled that v1 ships one media domain —
  Screen — because a solo maintainer with a calendar and a sync engine on the
  critical path should not open two crowded markets. The design already greys
  them, so matching it and honouring the decision are the same act.

  Mob has no wrap primitive, so the grid is chunked into rows of three, and the
  three posters share the row by weight rather than measuring 112 each. The
  design's 112*3 + 12*2 = 360 is the arithmetic of its own 402pt frame; a real
  411dp device leaves ~370dp between the 21pt gutters, so fixed tiles stop
  ~9dp short and the right edge goes ragged.

  ## Real data versus the drawing

  The shelf is `Kati.Media` — `Kati.Media.TrackedTitle` for what the user
  decided, `Kati.Media.CachedTitle` for what a provider said, and
  `Kati.Media.Watch` for the ticks the episode counter is derived from. See
  `shelf/0` for the query and `shaped/3` for the one row shape the header, the
  chips and the grid all read.

  A database with no library falls back to `drawn_titles/0`, the nine titles
  `Kati.Library.Sample` holds — the same move `Kati.Screens.Home.drawn_rows/0`
  and `Kati.Screens.Calendar.drawn_rows/0` make, and for the same reason: this
  screen is also the design reference, and a fresh install has no rows. The
  Sample module stays exactly where it is; it is the fallback and the fixture,
  not a stage this screen has passed through.
  """
  use Kati.Screens.Root, root: :library

  require Ash.Query

  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaChip
  alias Kati.Components.MishkaProgress
  alias Kati.Library.Sample
  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Theme
  alias Kati.Theme.Palette

  # What the Screen shelf is made of. Books and Music are drawn inactive (see
  # the moduledoc), so `:book` and `:album` are deliberately absent rather than
  # queried and thrown away.
  @screen_kinds [:movie, :tv, :anime]

  @impl true
  def load(socket),
    do: Mob.Socket.assign(socket, filter: "All", shelf: "Screen", titles: titles(), menu?: false)

  @doc """
  The shelf the screen renders: the user's library, or the drawing's.

  `shelf/0` answers with nothing on a fresh install, and a Library rendered
  empty cannot be compared with `.scratch/design/audit/03.png` at all — nine
  posters, three chip counts and a `9 titles · 4 in progress` subtitle would
  all go unexercised. FIDELITY's rule applies here exactly as it does on Home:
  *missing data is not a reason for a blank screen*.
  """
  @spec titles() :: [map()]
  def titles do
    case shelf() do
      [] -> drawn_titles()
      rows -> rows
    end
  end

  @doc """
  The Screen shelf, straight from `Kati.Media`.

  A fixed number of reads rather than an N+1: the tracked rows, then one query
  for every cache row they name and one for every tick logged against them. The
  cache is reached by `{source, source_id}` because that is what
  `Kati.Media.TrackedTitle` holds — a value pair, not a foreign key — so an
  evicted poster cannot take a tracked row down with it.

  **A row with no cached title is dropped.** The grid draws a name and a mono
  line under every poster, and a tile captioned `nil` is worse than a tile that
  is not there: the title is the one thing eviction takes and nothing durable
  can replace, so the honest answer is to say nothing rather than to draw an
  anonymous rectangle. The tracked row is untouched and reappears the moment
  its cache row is re-fetched.

  `Kati.Media.TrackedTitle`'s own `:shelf` action does the reading, once per
  kind, rather than a filter written out here: it is the action that resource
  names for "screens 03, 20 and 21", and it is where "keeps history, hides from
  shelf" is enforced. Excluding archived rows in the caller would put that rule
  in as many places as there are shelves, and the first one to forget it would
  show a row the user hid.

  Three reads are then re-sorted as one, because each answers `last_touched_at`
  descending within its own kind and this grid is one shelf, not three.
  """
  @spec shelf() :: [map()]
  def shelf do
    tracked =
      @screen_kinds
      |> Enum.flat_map(fn kind ->
        TrackedTitle
        |> Ash.Query.for_read(:shelf, %{kind: kind})
        |> Ash.read!()
      end)
      |> Enum.sort_by(& &1.last_touched_at, {:desc, DateTime})

    cached = cached_by_reference(tracked)
    ticks = ticks_by_title(tracked)

    tracked
    |> Enum.map(&shaped(&1, Map.get(cached, {&1.source, &1.source_id}), Map.get(ticks, &1.id, 0)))
    |> Enum.reject(&is_nil(&1.title))
  rescue
    # Same degradation `Kati.Calendars.Today` makes: a screen that cannot reach
    # its store draws the drawing rather than taking the activity down.
    _ -> []
  end

  # One query for every cache row the shelf names, keyed the way the tracked
  # rows reference it.
  defp cached_by_reference([]), do: %{}

  defp cached_by_reference(tracked) do
    ids = tracked |> Enum.map(& &1.source_id) |> Enum.uniq()

    CachedTitle
    |> Ash.Query.filter(source_id in ^ids)
    |> Ash.read!()
    |> Map.new(&{{&1.source, &1.source_id}, &1})
  end

  # The episode counter is DERIVED — `Kati.Media.TrackedTitle` is explicit that
  # `progress_episode` is a bookmark inside a season and the authority on how
  # much is watched is the set of ticks. Counted by distinct episode, so a
  # rewatch does not push a season past its own total.
  defp ticks_by_title([]), do: %{}

  defp ticks_by_title(tracked) do
    ids = Enum.map(tracked, & &1.id)

    Watch
    |> Ash.Query.filter(tracked_title_id in ^ids and not is_nil(episode_source_id))
    |> Ash.read!()
    |> Enum.group_by(& &1.tracked_title_id, & &1.episode_source_id)
    |> Map.new(fn {id, episodes} -> {id, episodes |> Enum.uniq() |> length()} end)
  end

  @doc """
  One tracked title in the shape the grid, the chips and the subtitle all read.

  `cached` may be `nil` and `ticks` may be zero; both are ordinary states and
  neither is allowed to invent a number:

    * `title` is the cache's, and `nil` when there is no cache row — `shelf/0`
      drops those rather than drawing them.
    * `seed` is `poster_path`, which for a seeded sample title is the design's
      own picsum seed (`Kati.Seeds` writes it that way) and for a real one is a
      provider path `Kati.Design.Images.poster/1` will not find. Both degrade
      to the placeholder rectangle `artwork/1` already draws.
    * `progress` is a fraction or `nil`. For a series it is the tick count over
      `episode_count`, through `Kati.Media.CachedTitle.progress/2` so an
      unknown denominator answers `{:position, n}` and `ratio/1` answers `nil`
      rather than dividing by something that is not there. For a film there is
      no ring at all — `denominator/1` says so outright — so it is the resume
      point over the runtime, which is the ×60 screen 10 does in the open.
    * `status` is the user's own, and it is what the chips filter on:
      `Kati.Media.TrackedTitle` names `:not_started` and `:finished` as this
      screen's shelf filters.
  """
  @spec shaped(TrackedTitle.t(), CachedTitle.t() | nil, non_neg_integer()) :: map()
  def shaped(tracked, cached, ticks) do
    %{
      title: cached && cached.title,
      seed: cached && cached.poster_path,
      kind: if(tracked.kind == :movie, do: :film, else: :series),
      status: tracked.status,
      progress: fraction_for(tracked, cached, ticks)
    }
  end

  # A series divides ticks by the episode total; a film divides its resume point
  # by its runtime. Anything either half cannot answer is nil, never a guess.
  defp fraction_for(%TrackedTitle{kind: :movie} = tracked, cached, _ticks) do
    seconds = tracked.progress_seconds
    minutes = cached && cached.runtime_minutes

    if is_integer(seconds) and seconds > 0 and is_integer(minutes) and minutes > 0 do
      min(seconds / (minutes * 60), 1.0)
    end
  end

  defp fraction_for(%TrackedTitle{}, cached, ticks) do
    cached |> CachedTitle.progress(ticks) |> CachedTitle.ratio()
  end

  @doc """
  The nine titles `.scratch/design/screens/03.html` draws, in its own order.

  Stand-in data, and marked as such — `Kati.Library.Sample`'s moduledoc says so
  at length. What is NOT stand-in is the set of states: three titles not
  started, four part-watched and two finished, which is every chip the design
  draws and every branch of `tile_meta/1`.

  Each row is given the `status` a real one carries, so `visible/3`,
  `chip_counts/1` and `subtitle/1` ask one question of both kinds of row and
  cannot answer it two different ways.
  """
  @spec drawn_titles() :: [map()]
  def drawn_titles, do: Enum.map(Sample.titles(), &with_status/1)

  # The Sample rows predate `Kati.Media.TrackedTitle` and carry a fraction where
  # a real row carries a status. The mapping is the one the chips used to make
  # inline — 0 is not started, 1 is finished, anything between is watching — so
  # the counts and the filtered grid are unchanged to the pixel.
  defp with_status(%{progress: progress} = row) do
    status =
      cond do
        progress <= 0.0 -> :not_started
        progress >= 1.0 -> :finished
        true -> :watching
      end

    Map.put(row, :status, status)
  end

  @doc false
  def content(assigns) do
    filter = assigns.filter
    shelf = assigns.shelf
    titles = assigns.titles

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={132}
      >
        {Kati.Screens.Library.header(titles, assigns.menu?)}
        {Kati.Screens.Library.segments(shelf)}
        {Kati.Screens.Library.quick_tiles()}
        {Kati.Screens.Library.chips(filter, titles)}
        {Kati.Screens.Library.grid(filter, shelf, titles)}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The header's mono subtitle: `9 titles · 4 in progress`.

  Counted off the shelf rather than off `Kati.Library.Sample`, so the line and
  the grid under it can never disagree about how many titles there are.
  """
  @spec subtitle([map()]) :: String.t()
  def subtitle(titles) do
    "#{length(titles)} titles · #{Enum.count(titles, &(&1.status == :watching))} in progress"
  end

  @doc false
  def header(titles, menu?) do
    subtitle = Kati.Screens.Library.subtitle(titles)

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Column weight={1.0}>
          <Text
            text="Library"
            text_size={28}
            max_font_scale={1.6}
            font_weight="bold"
            letter_spacing={-0.03}
            text_color={:on_surface}
          />
          <Spacer size={5} />
          <Text
            text={subtitle}
            font_family="mono"
            text_size={11}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
        {Kati.Screens.Library.disc("search", :open_search)}
        <Spacer size={9} />
        {Kati.Screens.Library.disc("sort", :open_sort)}
        <Spacer size={9} />
        {Kati.Screens.Library.menu(menu?)}
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  # Chelekom's headless Action Icon. See screen 02's `disc/2` for why `shadow`
  # is the prop that unblocked this: a filled disc with no lift is a flat patch
  # of card white on paper, and the drawing's whole affordance is that it floats.
  #
  # `shape: :circle` gives `44 / 2` = 22.0 where the Box said 22 — `floatProp`
  # reads both as 22.0f. The glyph is a child so `Kati.UI.symbol/2` keeps
  # supplying the Material Symbol at 21; the component's `<Row>` wrapper hugs
  # that single `<Text>` and is centred by the same `Alignment.Center`.
  @doc """
  The ⋯ disc, and the only thing behind it.

  A third disc beside search and sort, which screen 03's drawing does not
  draw — the one addition to a resting screen in this change, and it is here
  because screen 13's own back pill reads `‹ Library` and no control on 03
  could open it. The alternative was leaving a finished screen unreachable
  forever, or hanging it off `sort`, which promises an ordering and would
  deliver a recommender.

  One item, so the panel is small on purpose. It grows when 03 grows.
  """
  def menu(open?) do
    Kati.UI.Menu.overflow(
      Kati.Screens.Library.disc("more_horiz", :toggle_menu),
      open?,
      [Kati.UI.Menu.item("schedule", "What fits?", :open_what_fits)],
      dismiss: :close_menu
    )
  end

  @doc false
  def disc(icon, tag) do
    MishkaActionIcon.action_icon(
      [
        size: 44,
        shape: :circle,
        variant: :filled,
        background: Palette.card(),
        shadow: Theme.shadow_button(),
        on_tap: tag
      ],
      [Kati.UI.symbol(icon, size: 21)]
    )
  end

  @doc false
  def segments(active) do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.placeholder()}
        corner_radius={18}
        padding={4}
        align="center"
      >
        {Kati.Screens.Library.segment("movie", "Screen", active == "Screen")}
        <Spacer size={4} />
        {Kati.Screens.Library.segment("menu_book", "Books", active == "Books")}
        <Spacer size={4} />
        {Kati.Screens.Library.segment("graphic_eq", "Music", active == "Music")}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  # NOT Chelekom's Segmented Control, and it is worth writing down why so the
  # next pass does not re-derive it. The component is otherwise a close fit —
  # `track_padding`, `segment_height`, `segment_radius`, `font_weight` +
  # `selected_weight`, `segment_weight` for the `flex:1` cells, even a
  # `selected_shadow` — but two things the drawing does are not expressible:
  #
  #   1. **Each segment carries an icon.** `option/3` builds
  #      `%{props: %{id:, label:, disabled:}}` and `segment/3` renders it as a
  #      Box holding one `<Text>` the control paints itself. The drawing puts a
  #      17px Material Symbol before each 13px label with a 6px gap
  #      (`03.html:16-28`). There is no leading slot, and the label is a prop
  #      rather than children precisely because the control owns that Text.
  #   2. **`gap:4px` between segments.** `track/3` emits `<Row>{segments}</Row>`
  #      with nothing interspersed and there is no `segment_gap` prop; the
  #      segments would abut. Nor can the gap be smuggled in as a child —
  #      `segmented_control/2` filters children to
  #      `match?(%{type: :mishka_segmented_control_option}, &1)` and drops the
  #      rest, so an interspersed `<Spacer>` is discarded rather than laid out.
  #
  # Either alone would move pixels, so the strip stays hand-rolled. Both are
  # upstream asks: a leading slot on an option, and a gap between segments.
  @doc false
  def segment(icon, label, on?) do
    tap = {self(), String.to_atom("shelf_" <> label)}
    bg = if on?, do: Palette.card(), else: Palette.transparent()
    fg = if on?, do: Palette.ink(), else: Palette.segment_idle()
    weight = if on?, do: "bold", else: "semibold"

    ~MOB"""
    <Box weight={1.0}>
      <Row
        fill_width={true}
        height={38}
        corner_radius={14}
        background={bg}
        align="center"
        on_tap={tap}
      >
        <Spacer weight={1.0} />
        {Kati.UI.symbol(icon, size: 17, color: fg)}
        <Spacer size={6} />
        <Text text={label} text_size={13} font_weight={weight} text_color={fg} max_lines={1} />
        <Spacer weight={1.0} />
      </Row>
    </Box>
    """
  end

  @doc false
  def quick_tiles do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {Kati.Screens.Library.quick_tile("playlist_play", "Up next", "12", :open_up_next)}
        <Spacer size={9} />
        {Kati.Screens.Library.quick_tile("explore", "Discover", nil, :open_discover)}
        <Spacer size={9} />
        {Kati.Screens.Library.quick_tile("bookmarks", "Lists", "7", :open_lists)}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc false
  def quick_tile(icon, label, count, tag) do
    tap = {self(), tag}

    ~MOB"""
    <Box weight={1.0} on_tap={tap}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={16}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={11}
        padding_right={11}
        padding_top={12}
        padding_bottom={12}
      >
        <Row fill_width={true} align="center">
          {Kati.UI.symbol(icon, size: 19)}
          <Spacer weight={1.0} />
          {Kati.Screens.Library.tile_count(count)}
        </Row>
        <Spacer size={10} />
        <Text
          text={label}
          text_size={12.5}
          font_weight="bold"
          letter_spacing={-0.01}
          text_color={:on_surface}
          max_lines={1}
        />
      </Column>
    </Box>
    """
  end

  @doc false
  def tile_count(nil), do: ~MOB"<Spacer size={0} />"

  def tile_count(count) do
    ~MOB"""
    <Text
      text={count}
      font_family="mono"
      text_size={10}
      text_color={Palette.rail_idle()}
      max_lines={1}
    />
    """
  end

  @doc """
  The four filter chips with their counts, in the drawing's order.

  The counts are of the shelf, and they read `status` rather than a fraction:
  `Kati.Media.TrackedTitle` names `:not_started` and `:finished` as this
  screen's shelf filters, and `:watching` is the status the design's `4 in
  progress` is counting. A shelf holding `:paused` or `:dropped` rows therefore
  has sub-counts that do not add up to `All`, which is the truth — those rows
  are in the library and in none of the three named states.
  """
  @spec chip_counts([map()]) :: [{String.t(), non_neg_integer()}]
  def chip_counts(titles) do
    [
      {"All", length(titles)},
      {"Watching", Enum.count(titles, &(&1.status == :watching))},
      {"Not started", Enum.count(titles, &(&1.status == :not_started))},
      {"Finished", Enum.count(titles, &(&1.status == :finished))}
    ]
  end

  @doc false
  def chips(active, titles) do
    ~MOB"""
    <Column fill_width={true}>
      <Scroll axis="horizontal">
        <Row>
          {Kati.Screens.Library.chip_counts(titles)
           |> Enum.map(fn {label, count} ->
             Kati.Screens.Library.chip(label, count, label == active)
           end)
           |> Enum.intersperse(Kati.Screens.Library.chip_gap())}
        </Row>
      </Scroll>
      <Spacer size={20} />
    </Column>
    """
  end

  # Chelekom's headless Chip, count and all. The count is what made this chip
  # need the component's `trailing` SLOT rather than its `trailing` string: the
  # drawing sets it in DM Mono at 10.5, and the component paints a string
  # trailing in the chip's own family and size. A slot takes a node as readily
  # as a glyph, so `chip_count/2` supplies the exact `<Text>` this screen drew.
  #
  # The tree gains one level and loses nothing:
  #
  #   was  <Row height={32} corner_radius={16} background padding_left={14}
  #             padding_right={14} align="center" on_tap>
  #          <Text label 12.5 semibold /> <Spacer size={6} /> <Text count mono />
  #        </Row>
  #
  #   now  <Box fill_width={false} height={32} … align="center" on_tap>
  #          <Row align="center">
  #            <Text label 12.5 semibold /> <Spacer size={6} /> <Text count mono />
  #          </Row>
  #        </Box>
  #
  # Width: the Box hugs (K-17 reads `fill_width={false}` now), so it measures
  # 14 + Row + 14, and the Row hugs to label + 6 + count — the same total the
  # padded Row measured on its own.
  #
  # Height: centring composes. The inner Row carries no height, so it hugs to
  # its tallest child and centres both Texts on ITS midline; the Box then
  # centres that Row inside the declared 32. Each label's box therefore lands
  # on the same midline it landed on when the Row itself was 32 tall with
  # `CenterVertically` — the intermediate container is transparent to the
  # arithmetic precisely because it hugs.
  #
  # `align="center"` on the inner Row is also what the bridge would have done
  # unasked: `rowAlignProp` DEFAULTS to `CenterVertically`, and only "top" and
  # "bottom" move it.
  @doc false
  def chip(label, count, on?) do
    # The design puts the count at .65 opacity of the label colour rather than
    # a separate token, so it stays legible on both chip states.
    count_fg = if on?, do: Palette.on_ink_count_soft(), else: Palette.count_idle_soft()

    MishkaChip.chip(
      label: label,
      checked: on?,
      # The tag carries the label, so one handler serves every chip and adding
      # a filter needs no new clause.
      on_toggle: String.to_atom("filter_" <> label),
      trailing: Kati.Screens.Library.chip_count(count, count_fg),
      trailing_gap: 6,
      height: 32,
      padding_x: 14,
      padding_y: 0,
      corner_radius: 16,
      text_size: 12.5,
      font_weight: :semibold,
      max_lines: 1,
      color: Palette.ink_fill(),
      text_color: Palette.on_ink(),
      unchecked_color: Palette.card(),
      unchecked_text_color: Palette.ink_soft()
    )
  end

  # The count, as its own node rather than as the chip's `trailing` string: a
  # string would inherit the chip's `text_size` and its sans family, and the
  # drawing sets this line in DM Mono at 10.5.
  @doc false
  def chip_count(count, color) do
    ~MOB"""
    <Text text={"#{count}"} font_family="mono" text_size={10.5} text_color={color} max_lines={1} />
    """
  end

  # The drawing's `gap:7px` sits BETWEEN chips. It used to be a trailing Spacer
  # inside each chip, which is not the same thing twice over: every chip
  # measured 7 wider than the design's `padding:0 14px`, and the row had no gap
  # at all — the chips only looked separated because their own right padding
  # had grown to 21.
  @doc false
  def chip_gap, do: ~MOB"<Spacer size={7} />"

  # Three across, because that is the design's wrap. The width each tile gets is
  # left to the weights in poster/1 — see the moduledoc.
  @doc false
  def grid(filter, shelf, titles) do
    rows = titles |> Kati.Screens.Library.visible(filter, shelf) |> Enum.chunk_every(3)

    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(rows, fn row -> Kati.Screens.Library.grid_row(row) end)}
    </Column>
    """
  end

  @doc """
  The titles a filter and a shelf leave visible.

  Books and Music are drawn but empty: #60 settled that v1 ships one media
  domain, and the design greys them. Selecting them shows that emptiness
  honestly rather than pretending the shelf is full of films. `shelf/0` never
  asks for `:book` or `:album` for the same reason.

  The chips read `status`, not a fraction — see `chip_counts/1`.
  """
  @spec visible([map()], String.t(), String.t()) :: [map()]
  def visible(_titles, _filter, shelf) when shelf != "Screen", do: []

  def visible(titles, filter, _shelf) do
    case filter do
      "Watching" -> Enum.filter(titles, &(&1.status == :watching))
      "Not started" -> Enum.filter(titles, &(&1.status == :not_started))
      "Finished" -> Enum.filter(titles, &(&1.status == :finished))
      _all -> titles
    end
  end

  # A short last row must still be padded to three. Weights divide whatever is
  # there, so a row holding one poster gives it the full width and the grid
  # ends with one enormous tile — which is what "4 titles" looked like.
  @doc false
  def grid_row(row) do
    row = row ++ List.duplicate(nil, 3 - length(row))

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {row |> Enum.map(&Kati.Screens.Library.poster/1) |> Enum.intersperse(Kati.Screens.Library.grid_gap())}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc false
  def grid_gap, do: ~MOB"<Spacer size={12} />"

  @doc false
  def poster(nil), do: ~MOB"<Box weight={1.0} />"

  def poster(item) do
    # A film opens the film screen and a series the series screen — the design
    # draws them as two different screens, so the grid has to know which.
    tap = {self(), if(item.kind == :film, do: :open_film, else: :open_series)}

    # Weighted rather than 112 wide: three equal shares of the real content
    # width fill the row on any device, where a fixed 112 only fills the
    # drawing's frame.
    ~MOB"""
    <Column weight={1.0} on_tap={tap}>
      <Box
        fill_width={true}
        height={158}
        corner_radius={13}
        background={Palette.placeholder()}
        shadow={Kati.Theme.shadow_card_soft()}
      >
        {Kati.Screens.Library.artwork(item)}
        <Box fill_width={true} fill_height={true} align="bottom">
          {Kati.Screens.Library.progress(Kati.Screens.Library.fraction(item))}
        </Box>
      </Box>
      <Spacer size={9} />
      <Text
        text={item.title}
        text_size={12.5}
        font_weight="bold"
        letter_spacing={-0.01}
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer size={3} />
      <Text
        text={Kati.Screens.Library.tile_meta(item)}
        font_family="mono"
        text_size={10.5}
        text_color={Palette.muted()}
        max_lines={1}
      />
    </Column>
    """
  end

  @doc """
  The mono line under a grid title.

  The drawing carries one — `{{ it.meta }}`, DM Mono 10.5 in `#A9A29A`, 3
  under the title — and the grid was drawing the title and then stopping, so
  every cell sat ~16pt short of the frame and the rows closed up.

  The design templates the copy, so the wording is DERIVED from the two facts
  the shelf actually knows — the status the user set and how far in they are —
  rather than invented from nothing.

  Status comes first because it is an assertion and the fraction is an
  inference: a title the user marked finished says `finished` even when the
  cache row that would divide its ticks has been evicted. The last clause is
  the case a fraction cannot describe — `Kati.Media.CachedTitle.ratio/1`
  answered `nil` because nobody knows how many episodes there are — and it
  names the status instead of printing a percentage of an unknown total.
  """
  @spec tile_meta(map()) :: String.t()
  def tile_meta(%{status: :not_started}), do: "not started"
  def tile_meta(%{status: :finished}), do: "finished"
  def tile_meta(%{progress: p}) when is_float(p) and p > 0.0, do: "#{round(p * 100)}% watched"
  def tile_meta(%{status: :paused}), do: "paused"
  def tile_meta(%{status: :dropped}), do: "dropped"
  def tile_meta(_item), do: "watching"

  @doc """
  The `0.0..1.0` the rail burnt into a poster's bottom edge sweeps.

  `Kati.Media.CachedTitle.ratio/1` answers `nil` when there is no total to be a
  fraction of, and this screen has to draw *something* into a fixed 4pt rail —
  so an unknown fraction is drawn empty, and a title the user marked finished
  is drawn full even when its denominator was evicted. Nothing here invents a
  percentage: `tile_meta/1` above says `watching` rather than a number in
  exactly the case this returns `0.0`.
  """
  @spec fraction(map()) :: float()
  def fraction(%{progress: p}) when is_float(p), do: p
  def fraction(%{status: :finished}), do: 1.0
  def fraction(_item), do: 0.0

  # Real artwork, not a grey rectangle. `content_mode="fill"` crops to the
  # frame the way a poster does; without it Coil letterboxes and the card
  # develops margins the design does not have.
  #
  # `Kati.Design.Images.poster/1` rather than `Kati.Library.Sample.poster/1`
  # — the Sample function is a one-line delegation to it, and the shelf's own
  # seeds now arrive on `Kati.Media.CachedTitle.poster_path` (see `shaped/3`),
  # so routing a real row's artwork through the fixture module would be a lie
  # about where the value came from.
  @doc false
  def artwork(item) do
    case Kati.Design.Images.poster(item[:seed]) do
      nil ->
        ~MOB"<Spacer size={0} />"

      src ->
        ~MOB"""
        <Image src={src} fill_width={true} height={158} corner_radius={13} content_mode="fill" />
        """
    end
  end

  @doc """
  Burnt into the poster's bottom edge, not floated under it: a 4pt square track
  at 22% ink with an `#E8823C` fill. Orange here is "how far in you are", which
  is the design's one non-status use of it.

  Chelekom's headless Progress in `render: :box`. The native mode is Material's
  `LinearProgressIndicator`, and the two things this rail is made of are the
  two it does not expose: the track colour is `ProgressIndicatorDefaults`'
  `linearTrackColor` with no prop to reach it, and the caps belong to whichever
  material3 is pinned. So the shelf hand-rolled the two Boxes; `render: :box`
  draws exactly those, with the fraction arithmetic in one place.

  Both ends are ordinary on this grid — `tile_meta/1` has clauses for
  `not started` and `finished`, and the sample shelf reaches both (three tiles
  at 0.0, two at 1.0). The hand-rolled version needed a whole extra clause for the
  first and a guarded `progress_rest/1` for the second, because `1.0 -
  fraction` is a zero `weight` at 100% and Compose throws on it. The component
  omits whichever node would carry the zero, which draws the same nothing.
  """
  @spec progress(float()) :: map()
  def progress(fraction) do
    MishkaProgress.progress(
      render: :box,
      value: fraction,
      max: 1,
      height: 4,
      color: Palette.accent(),
      track_color: Palette.track_ink()
    )
  end

  @impl true
  def handle_tap(:open_search, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Search)}

  def handle_tap(:open_up_next, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.UpNext)}

  def handle_tap(:open_discover, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Discover)}

  def handle_tap(:open_lists, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Lists)}

  def handle_tap(:open_series, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Series)}

  def handle_tap(:open_film, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Film)}

  # One clause for every chip and every segment: the tag carries the label, so
  # a new filter is a data change rather than a code change.
  def handle_tap(:toggle_menu, socket),
    do: {:noreply, Mob.Socket.assign(socket, :menu?, not socket.assigns.menu?)}

  def handle_tap(:close_menu, socket),
    do: {:noreply, Mob.Socket.assign(socket, :menu?, false)}

  def handle_tap(:open_what_fits, socket) do
    {:noreply,
     socket
     |> Mob.Socket.assign(:menu?, false)
     |> Mob.Socket.push_screen(Kati.Screens.WhatFits)}
  end

  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "filter_" <> label -> {:noreply, Mob.Socket.assign(socket, :filter, label)}
      "shelf_" <> label -> {:noreply, Mob.Socket.assign(socket, :shelf, label)}
      _ -> {:noreply, socket}
    end
  end
end
