defmodule Kati.Screens.ShelfFilters do
  @moduledoc """
  Board 145 — Sort & filter, a sheet over the shelf.

  ## One sheet, three screens

  The board's own caption: *one sheet for screens 03, 20 and 21 — three
  sheets would end the "identical parts" claim within a release.* The four
  tabs on `Kati.Screens.Library` (and Books, and Music) stay the default
  surface; this is the escalation those tabs cannot reach — a second sort
  axis, decade and rating ranges, and a genre/service filter, all in one
  place. Board 145 draws the Library instance specifically — Runtime is the
  fifth sort row, where Books would print Pages and Music would print Length
  — so `Kati.Library.ShelfFiltersSample` is this file's data, not a shared
  one three screens reach into.

  ## Ranges are chip buckets, not sliders

  Reproduced on screen, in the dashed note at the foot, in the board's own
  words: the component table has no slider, and a bucket carries a count
  while a slider cannot. That is also why decade and rating are chips rather
  than a two-handle range control — `Kati.UI.chip/2` already exists and a
  slider does not.

  ## The fourth chip colour

  `chip/2`'s count badge has three colours — disabled, selected, and the
  ordinary dim default — because until this board nothing needed a fourth.
  Comedy is drawn selectable and unfiltered, at `0`, in `rail_idle`'s
  hairline grey rather than the usual dim `eyebrow` — the badge says "this
  chip empties the shelf" *before* it is tapped, not after. `facet_chip/4`
  restates `chip/2`'s other six colours unchanged and adds that one branch,
  built directly against `Kati.Components.MishkaChip` the way `chip/2` itself
  is, rather than reaching for a prop that does not exist.

  ## Sort has one arrow and turns it

  `arrow_downward` is in `Kati.Icons`; `arrow_upward` is not, and the hard
  rule is to grep before reaching for a glyph, not to add one so a spec reads
  cleaner. `Kati.Screens.Calendar.chevron/1` already answers this exact
  problem for `expand_more`/`expand_less` — fence K-16 gave the bridge a
  `rotate` prop for precisely a glyph that is another glyph upside down — so
  `direction_pill/1` wraps the one arrow in a 180° `Box` for ASC rather than
  drawing a second glyph that does not exist.

  ## Why 41 stops being load-bearing after the first tap

  The board opens with 2020s, 4★-and-up and Anime selected and prints
  `showing 41 of 418` beside them — and 41 is not the size of any one of
  those three buckets (24, 31, 12), nor of their overlap by any formula this
  file can justify; it is the drawing's own illustrative number for the
  state as drawn. Inventing a formula that reverse-engineers 41 would state a
  false premise about how the numbers relate. So `mount/3` writes 41
  literally, matching the board on first paint, and `recompute/1` — the
  narrowest of the currently selected buckets, treating two chips picked in
  the same row as an OR and taking the smaller side of an AND across rows —
  takes over from the next tap on, real from then on even though it does not
  reproduce 41 a second time.

  ## Reset clears everything, which is not what mount/3 draws

  The board's opening frame is already filtered — three buckets picked, 41 of
  418 showing. `Reset` does not restore that frame; it clears every bucket
  and the sort back to Recently added / DESC, because a reset that put you
  back in a *different* filtered state would not be a reset. `showing`
  answers 418 once nothing is selected, which `recompute/1` already does for
  free.
  """

  use Mob.Screen
  use Gettext, backend: Kati.Gettext
  import Mob.Sigil

  alias Kati.Library.ShelfFiltersSample, as: Sample
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.Sheet
  alias Kati.UI.SettingsList

  def mount(_params, _session, socket) do
    Kati.Theme.activate()
    Kati.Locale.activate()

    {:ok, Mob.Socket.assign(socket, Kati.Screens.ShelfFilters.opening())}
  end

  @doc """
  What the sheet opens on.

  Two things this used to do, and both were MOVIES-AND-TV.md #54. It opened
  **already filtered** — 2020s, 4★ and up, Anime — which hides part of the
  reader's own library the first time they touch the disc; and it announced
  `showing 41 of 418` on a phone that might hold two, because both numbers
  were board 145's literals.

  It opens on the choice this device has stored (`Kati.Library.ShelfFilters`),
  which on a first tap is nothing selected and newest first, and both counts
  are the reader's own shelf.

  On a device with nothing on it, `shelf/0` answers `[]` and the sheet falls
  back to the board whole — the same gate screens 03, 04 and 11 use, and what
  keeps board 145 comparable.
  """
  @spec opening() :: keyword()
  def opening do
    # The shelf as it stands, and the shelf with nothing selected. Both are
    # asked for, because a `showing N of M` where M was inferred from N would
    # be the same guess this is here to remove — and the narrowed list cannot
    # produce the unnarrowed one.
    case Kati.Screens.Library.shelf(Kati.Library.ShelfFilters.resting()) do
      [] -> drawn_opening()
      all -> real_opening(all)
    end
  end

  @doc """
  The board's opening state, for the gate that asserts an empty shelf gets it.

  `Kati.ScreenEmptyDatabaseTest` compares `opening/0` against this, which is
  what makes *an empty device draws board 145* a claim a run settles rather
  than one this moduledoc asserts.
  """
  @spec drawn_opening_for_test() :: keyword()
  def drawn_opening_for_test, do: drawn_opening()

  defp drawn_opening do
    [
      sort: :recently_added,
      direction: :desc,
      decade: :decade_2020s,
      rating: :rating_4,
      genres: MapSet.new([:genre_anime]),
      services: MapSet.new(),
      # The board's own literals, on the one device state the board is a
      # drawing of: a library this app does not hold yet.
      showing: 41,
      total: Sample.total(),
      facets: nil,
      decades: nil
    ]
  end

  defp real_opening(all) do
    chosen = Kati.Library.ShelfFilters.current()

    [
      sort: chosen.sort,
      direction: chosen.direction,
      decade: Map.get(chosen, :decade),
      rating: nil,
      genres: MapSet.new(chosen.genres),
      services: MapSet.new(),
      showing: length(Kati.Library.ShelfFilters.apply(all, chosen)),
      total: length(all),
      facets: Kati.Library.ShelfFilters.facets(all),
      decades: Kati.Library.ShelfFilters.decades(all)
    ]
  end

  def render(assigns),
    do: Sheet.sheet(gettext("Sort & filter"), body(assigns), Kati.Screens.Identity.of(__MODULE__))

  @doc false
  def body(assigns) do
    # `pgettext/2` on the two one-word section eyebrows — `Sort` here and
    # `Filters` below. `Kati.Screens.NewGoal.body/1` carries the argument for
    # the same three-word rule on its own eyebrows: `mix gettext.merge` fuzzy-
    # matches a msgid this short against any entry near it, and a bare `Sort`
    # sitting one edit away from `Sort & filter` — the title of this very sheet
    # — is exactly the pair that would arrive translated to the wrong one and
    # marked fuzzy. The Ranges eyebrow is a whole clause and needs no context.
    ~MOB"""
    <Column fill_width={true}>
      {UI.eyebrow(pgettext("sort & filter sheet section", "Sort"))}
      {Kati.Screens.ShelfFilters.sort_card(assigns.sort, assigns.direction)}
      <Spacer size={16} />
      {Kati.Screens.ShelfFilters.ranges(assigns)}
      {Kati.Screens.ShelfFilters.filters(assigns)}
      {Kati.Screens.ShelfFilters.count_card(assigns.showing, assigns.total)}
      <Spacer size={14} />
      {SettingsList.note("info", Kati.Screens.ShelfFilters.note_text(assigns.facets))}
    </Column>
    """
  end

  @doc "The five sort rows in their card; the active one carries a check and a direction pill."
  @spec sort_card(atom(), atom()) :: map()
  def sort_card(selected, direction) do
    options = Sample.sort_options()
    last = length(options) - 1

    rows =
      options
      |> Enum.with_index()
      |> Enum.map(fn {{key, label}, i} ->
        Kati.Screens.ShelfFilters.sort_row(
          key,
          Kati.Screens.ShelfFilters.sort_label(key, label),
          selected,
          direction,
          i != last
        )
      end)

    SettingsList.card(rows)
  end

  @doc """
  The reader's own word for a sort row `Kati.Library.ShelfFiltersSample` names.

  The sample is board 145 written out and it stays in the board's English,
  because what travels out of it is a **key**: `:your_rating` is what
  `sort_row/5` compares against `selected` to decide which row carries the
  check, what `handle_info/2` matches in `sort_keys/0`, and what
  `stored_sort/1` turns into `Kati.Library.ShelfFilters`' own name for it. A
  key that translated itself would break all three the moment the reader chose
  Persian, and would break them silently — the rows would still draw.

  `Kati.Screens.AnimeFilter.sample_text/1` is the same split one module further
  out and carries the long version of the argument; `Kati.Screens.NewGoal`'s
  `period_label/1` is the same shape over `Kati.Goals.Goal.kinds/0`, which is
  the tuple shape this sample was built to match.

  A key with no clause of its own comes back with the sample's own label, so a
  sixth sort row added tomorrow draws in English rather than raising — the
  right failure for a design fixture, since `mix gettext.extract` reads literal
  call sites and could not have a msgid for it either way.
  """
  @spec sort_label(atom(), String.t()) :: String.t()
  # `pgettext/2` on the first two: `Recently added` is one word from
  # `Recently watched`, which the catalogue already holds, and `Release date`
  # is close to both `Release watcher` and `Released`. A fuzzy merge would
  # hand either of them somebody else's Persian.
  def sort_label(:recently_added, _label), do: pgettext("a shelf sort key", "Recently added")
  def sort_label(:release_date, _label), do: pgettext("a shelf sort key", "Release date")

  # These two are already in the catalogue as bare msgids — `عنوان` and
  # `امتیاز شما` — and reusing them is what keeps one sort key from being
  # spelled two ways across the app.
  def sort_label(:your_rating, _label), do: gettext("Your rating")
  def sort_label(:title, _label), do: gettext("Title")

  # `Runtime` is one word and new, so it takes a context for the same reason
  # the eyebrows do. Board 145 draws the Library instance, where this row is a
  # film's length; Books would print Pages and Music Length in its place, and
  # `Length` is already in the catalogue meaning a track's.
  def sort_label(:runtime, _label), do: pgettext("a shelf sort key", "Runtime")

  def sort_label(_key, label), do: label

  @doc false
  def sort_row(key, label, selected, direction, rule?) do
    selected? = key == selected

    leading =
      if selected? do
        Kati.Screens.ShelfFilters.sort_icon_tile("check", Palette.ink())
      else
        Kati.Screens.ShelfFilters.sort_icon_tile("sort", Palette.ink_soft())
      end

    body =
      if selected?,
        do: Kati.Screens.ShelfFilters.sort_title(label),
        else: SettingsList.body(label)

    trailing = if selected?, do: Kati.Screens.ShelfFilters.direction_pill(direction == :desc)

    SettingsList.row(leading, body, trailing, rule: rule?, on_tap: {self(), key})
  end

  # `icon_tile/1` always draws its glyph in `ink_soft` — right for the four
  # unselected rows, wrong for the active row's `check`, which the board
  # draws in full `ink`. Restated with the colour as an argument rather than
  # widening the shared tile for one caller.
  @doc false
  def sort_icon_tile(icon, color) do
    Kati.Components.MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Kati.Theme.paper(Palette.mode()), size: 30, radius: 9},
      [UI.symbol(icon, size: 17, color: color)]
    )
  end

  # `SettingsList.body/1` is semibold; the board draws the active sort row's
  # title bold, so this restates the same Text at the one weight that differs.
  @doc false
  def sort_title(text) do
    ~MOB"""
    <Text text={text} text_size={13.5} font_weight="bold" text_color={:on_surface} max_lines={1} />
    """
  end

  @doc "The DESC/ASC pill beside the active sort row. See the moduledoc for the turned arrow."
  @spec direction_pill(boolean()) :: map()
  def direction_pill(desc?) do
    # `DESC`/`ASC` are words on a pill, not values — the direction itself is
    # the `:desc`/`:asc` atom the caller hands in, and it stays that way. Both
    # take a context: two four-letter runs one edit apart from each other are
    # exactly what `mix gettext.merge` fuzzy-matches, and the pair must not be
    # allowed to collapse into one word.
    label =
      if desc?,
        do: pgettext("sort direction", "DESC"),
        else: pgettext("sort direction", "ASC")

    assigns = %{label: label, rotate: if(desc?, do: 0.0, else: 180.0)}

    ~MOB"""
    <Row
      height={28}
      corner_radius={14}
      background={Kati.Theme.paper(Palette.mode())}
      align="center"
      padding_left={11}
      padding_right={11}
    >
      <Box width={15} height={15} rotate={@rotate} align="center">
        {UI.symbol("arrow_downward", size: 15, color: Palette.ink())}
      </Box>
      <Spacer size={5} />
      <Text
        text={@label}
        font_family={Kati.Locale.mono_face()}
        text_size={10.5}
        text_color={Palette.ink_soft()}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc false
  def decade_row(selected) do
    Sample.decades()
    |> Kati.Screens.ShelfFilters.read_facets()
    |> Kati.Screens.ShelfFilters.chip_row(fn key -> key == selected end)
  end

  @doc false
  def rating_row(selected) do
    Sample.ratings()
    |> Kati.Screens.ShelfFilters.read_facets()
    |> Kati.Screens.ShelfFilters.chip_row(fn key -> key == selected end)
  end

  @doc false
  def genre_row(selected) do
    Sample.genres()
    |> Kati.Screens.ShelfFilters.read_facets()
    |> Kati.Screens.ShelfFilters.chip_row(fn key ->
      MapSet.member?(selected, key)
    end)
  end

  @doc false
  def service_row(selected) do
    Sample.services()
    |> Kati.Screens.ShelfFilters.read_facets()
    |> Kati.Screens.ShelfFilters.chip_row(fn key ->
      MapSet.member?(selected, key)
    end)
  end

  @doc """
  The board's `{key, label, count}` triples with the labels read out loud.

  The sample keeps its English, because the first element of every triple is a
  **key** — it is what `chip_row/2`'s `selected?` closure tests, what
  `handle_info/2` matches against `decade_keys/0` and the three lists beside
  it, and what `facet_count/2` filters on. Only the second element is a word,
  and this is the one place one becomes the reader's own. See `sort_label/2`
  for the long version of the same split.
  """
  @spec read_facets([{atom(), String.t(), non_neg_integer()}]) ::
          [{atom(), String.t(), non_neg_integer()}]
  def read_facets(facets) do
    Enum.map(facets, fn {key, label, count} ->
      {key, Kati.Screens.ShelfFilters.facet_label(key, label), count}
    end)
  end

  @doc """
  The reader's own word for one of board 145's chips.

  Four of the genres are already in the catalogue as bare msgids — `درام`,
  `انیمه`, `مستند`, `کمدی` — and `Dropped` is already there under the
  `shelf status` context that `Kati.Screens.Series` writes it in, which is the
  same thing this chip means: not *where* a title is, but *what happened to
  it*. `Gone cold` joins that context rather than starting a second one, so
  the pair that the sample's own doc groups together stays grouped.
  """
  @spec facet_label(atom(), String.t()) :: String.t()
  def facet_label(:decade_2020s, _label), do: Kati.Screens.ShelfFilters.decade_label(2020)
  def facet_label(:decade_2010s, _label), do: Kati.Screens.ShelfFilters.decade_label(2010)
  def facet_label(:decade_2000s, _label), do: Kati.Screens.ShelfFilters.decade_label(2000)

  def facet_label(:decade_older, _label),
    do: pgettext("a decade bucket — everything before the ones named", "Older")

  def facet_label(:rating_4, _label), do: Kati.Screens.ShelfFilters.rating_label(4)
  def facet_label(:rating_3, _label), do: Kati.Screens.ShelfFilters.rating_label(3)
  def facet_label(:rating_unrated, _label), do: pgettext("a rating bucket", "Unrated")

  def facet_label(:genre_drama, _label), do: gettext("Drama")
  def facet_label(:genre_anime, _label), do: gettext("Anime")
  def facet_label(:genre_documentary, _label), do: gettext("Documentary")
  def facet_label(:genre_comedy, _label), do: gettext("Comedy")

  def facet_label(:status_dropped, _label), do: pgettext("shelf status", "Dropped")
  def facet_label(:status_gone_cold, _label), do: pgettext("shelf status", "Gone cold")

  # NO CLAUSE FOR `:service_lumen` OR `:service_orbit`, and that is the point.
  #
  # `Lumen+` and `Orbit` are the names services call themselves. A real one
  # comes off `Kati.Services.Service` and no msgid can reach it, so a fixture
  # that transliterated would spell one service two ways depending on whether
  # the reader happened to be looking at the board or at their own shelf.
  # Board 127 draws `Lumen+` in Latin on a Persian page for exactly this
  # reason, and the catalogue already carries both names translated to
  # themselves for `Kati.Money.Sample`.
  #
  # The same fallthrough is what a sixth chip added to the sample tomorrow
  # gets: the board's own English, drawn rather than raised.
  def facet_label(_key, label), do: label

  @doc """
  A decade as the reader writes it — `2020s`, `دههٔ ۲۰۲۰`.

  Latin builds the word out of the number with an `s`; Persian puts the noun
  in front and inflects nothing, so this cannot be `Kati.Locale.number/1`
  followed by a literal suffix. One msgid, used by both the board's four
  frozen buckets and `decade_facets/2`'s real ones, so the two rows cannot
  drift apart.
  """
  @spec decade_label(integer()) :: String.t()
  def decade_label(decade),
    do: pgettext("a decade bucket", "%{decade}s", decade: Kati.Locale.number(decade))

  @doc """
  A rating bucket as the reader writes it — `4★ and up`, `★۴ و بالاتر`.

  One msgid with the stars as a binding rather than two literals: `4★ and up`
  and `3★ and up` are a single character apart, which is the pair a fuzzy
  `mix gettext.merge` would match against each other the moment one of them
  changed. The star's side of the numeral is the catalogue's own — `Yours
  ★%{mine} · file says ★%{theirs}` already puts it there in both scripts.
  """
  @spec rating_label(pos_integer()) :: String.t()
  def rating_label(stars),
    do: pgettext("a rating bucket", "%{n}★ and up", n: Kati.Locale.number(stars))

  # A SCROLLING Row, not a plain one — this line was written for the board's
  # four fixed decades/ratings/services, which always fit, and stayed a plain
  # `<Row>` the day `facet_row/2` started calling it for the shelf's OWN
  # genres. Those are not four; they are as many as the reader's titles carry
  # — six on a shelf of three tracked titles here, `Crime` and `Animation`
  # among them — and a Row with no width and no weight force-fills and then
  # clips at the screen edge, the exact K-17 `chip_line/1` in
  # `Kati.Screens.Search` already names: the boundary chip's label truncates
  # mid-word and its trailing count is squeezed away with it, and every chip
  # past the edge is not merely hidden, it is unreachable — no scroll offers
  # it back. `<Scroll axis="horizontal" weight={1.0}>` costs nothing on the
  # four-chip rows this was written for, since a scroll around content that
  # already fits behaves exactly like the plain Row did.
  @doc false
  def chip_row(facets, selected?) do
    chips =
      facets
      |> Enum.map(fn {key, label, count} ->
        Kati.Screens.ShelfFilters.facet_chip(label, count, selected?.(key), key)
      end)
      |> Enum.intersperse(~MOB"<Spacer size={7} />")

    ~MOB"""
    <Row fill_width={true}>
      <Scroll axis="horizontal" weight={1.0}>
        <Row>
          {chips}
        </Row>
      </Scroll>
    </Row>
    """
  end

  @doc """
  A range/filter chip, built directly against `MishkaChip` rather than through
  `Kati.UI.chip/2`.

  `chip/2`'s count colour has three branches — disabled, selected, default —
  and none of them is the drawing's fourth: an *unselected* chip whose count
  is zero, drawn in `rail_idle`'s hairline grey rather than the ordinary dim
  `eyebrow`, so a chip that would empty the shelf says so before it is
  tapped. The other six colours below are `chip/2`'s own, unchanged.
  """
  @spec facet_chip(String.t(), non_neg_integer(), boolean(), atom()) :: map()
  def facet_chip(label, count, selected?, tag) do
    count_color =
      cond do
        selected? -> Palette.on_ink_muted()
        count == 0 -> Palette.rail_idle()
        true -> Palette.eyebrow()
      end

    Kati.Components.MishkaChip.chip(
      label: label,
      checked: selected?,
      disabled: false,
      on_toggle: tag,
      color: Palette.ink_fill(),
      text_color: Palette.on_ink(),
      unchecked_color: Kati.Theme.card(Palette.mode()),
      unchecked_text_color: Palette.ink_soft(),
      disabled_color: Palette.transparent(),
      disabled_text_color: Palette.chip_text_disabled(),
      corner_radius: 16,
      height: 32,
      padding_x: 15,
      padding_y: 0,
      text_size: 12,
      max_lines: 1,
      # `Kati.Locale.number/1` rather than `Integer.to_string/1`: the badge is
      # set in the sheet's own face — `chip_count/2` declares no `font_family`
      # and inherits the reader's — so a Persian reader gets `۰` and the
      # `rail_idle` branch above still says what it is there to say.
      trailing: UI.chip_count(Kati.Locale.number(count), count_color)
    )
  end

  @doc "The `showing N of 418` line and the Reset tap, in their own card."
  @spec count_card(non_neg_integer(), pos_integer()) :: map()
  def count_card(showing, total) do
    # Both numerals go through `Kati.Locale.number/1` and the line drops out of
    # DM Mono with them. `Kati.Locale.mono_face/0`'s own doc states the rule
    # this obeys: `kati_mono.ttf` carries no Persian glyph and none of
    # U+06F0–U+06F9 either, so a Persian `نمایش ۴۱ از ۴۱۸` left in `mono` would
    # be handed to Android's substitute face whole. The whole line is the
    # reader's script here — it is a sentence, not a bare figure — so this is
    # `mono_face/0` rather than `mono_face/1`.
    assigns = %{
      text:
        gettext("showing %{showing} of %{total}",
          showing: Kati.Locale.number(showing),
          total: Kati.Locale.number(total)
        )
    }

    ~MOB"""
    <Box
      fill_width={true}
      background={Kati.Theme.card(Palette.mode())}
      corner_radius={20}
      padding={15}
      shadow={Kati.Theme.shadow_card_soft()}
    >
      <Row fill_width={true} align="center">
        <Text
          text={@text}
          font_family={Kati.Locale.mono_face()}
          text_size={13}
          text_color={:on_surface}
          max_lines={1}
        />
        <Spacer weight={1.0} />
        <Row align="center" on_tap={{self(), :reset}}>
          <Text
            text={pgettext("clears every filter on the sheet", "Reset")}
            text_size={12.5}
            font_weight="semibold"
            text_color={Palette.sub()}
            max_lines={1}
          />
        </Row>
      </Row>
    </Box>
    """
  end

  @doc """
  The Ranges group — decades and rating buckets — on the one device it is true
  on.

  Neither can be answered. A decade needs a first-air year and
  `Kati.Media.CachedTitle` holds `next_release_at`, which is the NEXT release —
  screen 14's meta line drops the year for the same reason. The rating buckets
  could be answered, but `4★ and up` over a shelf that has no decade filter
  beside it is half a group; the two are drawn as one row pair and are dropped
  as one.

  `facets: nil` is the board, and only the board.
  """
  def ranges(%{facets: nil} = assigns) do
    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.eyebrow_muted(gettext("Ranges — buckets, not sliders"))}
      {Kati.Screens.ShelfFilters.decade_row(assigns.decade)}
      <Spacer size={11} />
      {Kati.Screens.ShelfFilters.rating_row(assigns.rating)}
      <Spacer size={16} />
    </Column>
    """
  end

  def ranges(%{decades: []}), do: ~MOB"<Spacer size={0} />"

  def ranges(assigns) do
    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.eyebrow_muted(gettext("Ranges — buckets, not sliders"))}
      {Kati.Screens.ShelfFilters.decade_facets(assigns.decades, assigns.decade)}
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  One chip per decade this shelf holds, newest first.

  Board 145 draws four frozen buckets and until 6 September
  `Kati.Media.CachedTitle` had no year column at all, so none of them could be
  answered — which is why this group was dropped on a device. It has one now
  (see `20260906120000_add_cached_title_first_release_year`), so these are the
  reader's own decades with their own counts. A shelf whose titles are all
  undated gets no Ranges group rather than four empty buckets.

  The rating buckets the board draws beside these are still not offered: `4★
  and up` is a bucket over `Kati.Media.Watch.rating`, which is a rating of one
  NIGHT, and averaging a title's nights into a bucket is a judgement no board
  states.
  """
  @spec decade_facets([{integer(), non_neg_integer()}], integer() | nil) :: map()
  def decade_facets(decades, chosen) do
    # `decade_label/1` and not `"#{decade}s"`: the decade is a NUMBER the sheet
    # prints, so it takes the reader's own numerals, and Persian names a decade
    # with a noun in front rather than a suffix behind. The board's four frozen
    # buckets go through the same call from `facet_label/2`, so a device's real
    # decades and the drawing's cannot be worded two different ways.
    chips = Enum.map(decades, fn {decade, n} -> {decade_tag(decade), decade_label(decade), n} end)

    Kati.Screens.ShelfFilters.chip_row(chips, fn key -> decade_of(key) == chosen end)
  end

  @doc """
  The tap tag for a decade chip, and back again.

      iex> Kati.Screens.ShelfFilters.decade_tag(2020)
      :decade_2020

      iex> Kati.Screens.ShelfFilters.decade_of(:decade_2020)
      2020
  """
  @spec decade_tag(integer()) :: atom()
  def decade_tag(decade), do: String.to_atom("decade_#{decade}")

  @doc false
  @spec decade_of(atom()) :: integer() | nil
  def decade_of(tag) do
    case tag |> Atom.to_string() |> String.replace_prefix("decade_", "") |> Integer.parse() do
      {decade, ""} -> decade
      _other -> nil
    end
  end

  @doc """
  The Filters group: the genres this shelf actually holds, or the board's four.

  `Kati.Media.CachedTitle.genres` is real and `", "`-separated — screen 07's
  hour bars read the same column — so a device offers its own genres with
  their own counts, commonest first. Services are dropped: there is no service
  resource, and `Kati.Media.Watch.service` is where ONE night was watched
  rather than a catalogue.

  A shelf whose titles name no genre at all gets no Filters group, rather than
  an eyebrow over an empty row.
  """
  def filters(%{facets: nil} = assigns) do
    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.eyebrow_muted(pgettext("sort & filter sheet section", "Filters"))}
      {Kati.Screens.ShelfFilters.genre_row(assigns.genres)}
      <Spacer size={11} />
      {Kati.Screens.ShelfFilters.service_row(assigns.services)}
      <Spacer size={16} />
    </Column>
    """
  end

  def filters(%{facets: []}), do: ~MOB"<Spacer size={0} />"

  def filters(assigns) do
    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.eyebrow_muted(pgettext("sort & filter sheet section", "Filters"))}
      {Kati.Screens.ShelfFilters.facet_row(assigns.facets, assigns.genres)}
      <Spacer size={16} />
    </Column>
    """
  end

  @doc "One chip per genre the shelf holds, with how many titles carry it."
  @spec facet_row([{String.t(), non_neg_integer()}], MapSet.t()) :: map()
  def facet_row(facets, selected) do
    # NO `facet_label/2` HERE. These genres are not the board's four — they are
    # whatever `Kati.Media.CachedTitle.genres` holds for this reader's own
    # titles, which is a provider's free text arriving from TMDB. There is no
    # msgid for a string that does not exist until a title is cached, and
    # guessing one would spell `Sci-Fi & Fantasy` two ways depending on whether
    # the catalogue happened to have been asked about it. The COUNT beside it
    # is this app's own and is localised, in `facet_chip/4`.
    chips = Enum.map(facets, fn {genre, n} -> {facet_tag(genre), genre, n} end)

    Kati.Screens.ShelfFilters.chip_row(chips, fn key ->
      MapSet.member?(selected, facet_genre(key))
    end)
  end

  @doc """
  The tap tag for a genre chip, and back again.

  Tags must be atoms — `Mob.Renderer` emits an `accessibility_id` only for
  `{pid, atom}` — and a genre is a provider's free text, so the two are
  converted rather than stored as one. `String.to_atom/1` and not
  `to_existing_atom/1`: the genre came from TMDB and no atom for it has been
  created anywhere before this.

      iex> Kati.Screens.ShelfFilters.facet_tag("Sci-Fi & Fantasy")
      :"facet_Sci-Fi & Fantasy"

      iex> Kati.Screens.ShelfFilters.facet_genre(:"facet_Sci-Fi & Fantasy")
      "Sci-Fi & Fantasy"
  """
  @spec facet_tag(String.t()) :: atom()
  def facet_tag(genre), do: String.to_atom("facet_" <> genre)

  @doc false
  @spec facet_genre(atom()) :: String.t()
  def facet_genre(tag), do: tag |> Atom.to_string() |> String.replace_prefix("facet_", "")

  @doc false
  def note_text(nil) do
    gettext(
      "Ranges are chip buckets, not sliders — the app has no slider in its component table, and a bucket carries a count while a slider cannot. Count badges exist so a chip that would empty the shelf says so before it is tapped: Comedy reads 0 in hairline grey."
    )
  end

  def note_text(_facets) do
    gettext(
      "Genres and release years come from the provider, so these are the ones your own shelf carries. Streaming service is not offered: nothing in Kati holds a catalogue."
    )
  end

  def handle_info({:tap, :close}, socket), do: {:noreply, Kati.Screens.Resume.pop(socket)}

  def handle_info({:tap, :reset}, socket), do: {:noreply, Kati.Screens.ShelfFilters.reset(socket)}

  def handle_info({:tap, tag}, socket) do
    cond do
      String.starts_with?(Atom.to_string(tag), "facet_") ->
        {:noreply, Kati.Screens.ShelfFilters.toggle_facet(socket, tag)}

      socket.assigns.decades && String.starts_with?(Atom.to_string(tag), "decade_") ->
        {:noreply, Kati.Screens.ShelfFilters.toggle_decade(socket, tag)}

      tag in Kati.Screens.ShelfFilters.sort_keys() ->
        {:noreply, Kati.Screens.ShelfFilters.apply_sort(socket, tag)}

      tag in Kati.Screens.ShelfFilters.decade_keys() ->
        {:noreply,
         socket
         |> Kati.Screens.ShelfFilters.toggle_single(:decade, tag)
         |> Kati.Screens.ShelfFilters.recompute()}

      tag in Kati.Screens.ShelfFilters.rating_keys() ->
        {:noreply,
         socket
         |> Kati.Screens.ShelfFilters.toggle_single(:rating, tag)
         |> Kati.Screens.ShelfFilters.recompute()}

      tag in Kati.Screens.ShelfFilters.genre_keys() ->
        {:noreply,
         socket
         |> Kati.Screens.ShelfFilters.toggle_set(:genres, tag)
         |> Kati.Screens.ShelfFilters.recompute()}

      tag in Kati.Screens.ShelfFilters.service_keys() ->
        {:noreply,
         socket
         |> Kati.Screens.ShelfFilters.toggle_set(:services, tag)
         |> Kati.Screens.ShelfFilters.recompute()}

      true ->
        {:noreply, socket}
    end
  end

  @doc """
  A genre chip pressed: narrow by it, or stop narrowing by it.

  The choice is written to `Kati.Library.ShelfFilters` on every tap rather than
  on a Done button, because this sheet has no Done — it has a ✕, and a sheet
  whose only exit discarded the choice is exactly the defect
  MOVIES-AND-TV.md #26 describes. Screen 03 re-reads on the pop through
  `Kati.Screens.Resume`, so the shelf behind is already narrowed when it comes
  back.
  """
  @spec toggle_facet(Mob.Socket.t(), atom()) :: Mob.Socket.t()
  def toggle_facet(socket, tag) do
    genre = facet_genre(tag)
    chosen = Kati.Library.ShelfFilters.current()

    genres =
      if genre in chosen.genres,
        do: List.delete(chosen.genres, genre),
        else: [genre | chosen.genres]

    %{chosen | genres: genres}
    |> Kati.Library.ShelfFilters.put()
    |> then(fn stored -> restated(socket, stored) end)
  end

  @doc """
  A decade chip pressed: narrow to it, or stop narrowing by it.

  Single-select, which is what a bucket row is — two decades at once is a range
  and the board draws chips.
  """
  @spec toggle_decade(Mob.Socket.t(), atom()) :: Mob.Socket.t()
  def toggle_decade(socket, tag) do
    decade = decade_of(tag)
    chosen = Kati.Library.ShelfFilters.current()
    next = if Map.get(chosen, :decade) == decade, do: nil, else: decade

    %{chosen | decade: next}
    |> Kati.Library.ShelfFilters.put()
    |> then(fn stored -> restated(socket, stored) end)
  end

  @doc """
  The sheet redrawn against what is now stored.

  Both counts come off the shelf rather than off `facet_count/2`'s arithmetic
  over the board's frozen bucket sizes, so `showing N of M` is two real
  numbers about this reader's own library.
  """
  @spec restated(Mob.Socket.t(), map()) :: Mob.Socket.t()
  def restated(socket, chosen) do
    all = Kati.Screens.Library.shelf(Kati.Library.ShelfFilters.resting())

    socket
    |> Mob.Socket.assign(:sort, chosen.sort)
    |> Mob.Socket.assign(:direction, chosen.direction)
    |> Mob.Socket.assign(:genres, MapSet.new(chosen.genres))
    |> Mob.Socket.assign(:showing, length(Kati.Library.ShelfFilters.apply(all, chosen)))
    |> Mob.Socket.assign(:total, length(all))
    |> Mob.Socket.assign(:facets, Kati.Library.ShelfFilters.facets(all))
    |> Mob.Socket.assign(:decade, Map.get(chosen, :decade))
    |> Mob.Socket.assign(:decades, Kati.Library.ShelfFilters.decades(all))
  end

  @doc false
  def sort_keys, do: Enum.map(Sample.sort_options(), &elem(&1, 0))
  @doc false
  def decade_keys, do: Enum.map(Sample.decades(), &elem(&1, 0))
  @doc false
  def rating_keys, do: Enum.map(Sample.ratings(), &elem(&1, 0))
  @doc false
  def genre_keys, do: Enum.map(Sample.genres(), &elem(&1, 0))
  @doc false
  def service_keys, do: Enum.map(Sample.services(), &elem(&1, 0))

  @doc "Tapping the active sort row flips its direction; any other row becomes the new sort at DESC."
  @spec apply_sort(Mob.Socket.t(), atom()) :: Mob.Socket.t()
  def apply_sort(socket, key) do
    {sort, direction} =
      if socket.assigns.sort == key do
        {key, if(socket.assigns.direction == :desc, do: :asc, else: :desc)}
      else
        {key, :desc}
      end

    stored = %{
      Kati.Library.ShelfFilters.current()
      | sort: stored_sort(sort),
        direction: direction
    }

    if socket.assigns.facets do
      # `put_sort/3` AFTER `restated/2`, not before it.
      #
      # The two speak different vocabularies on purpose. This card draws five
      # rows keyed `:recently_added | :release_date | :your_rating | :title |
      # :runtime`, and `Kati.Library.ShelfFilters` stores four — `stored_sort/1`
      # is the bridge, and its doc says why the board can offer one the store
      # cannot answer. `restated/2` assigns `:sort` from the STORE's word, so
      # running it last wrote `:rating` into an assign that `sort_row/5`
      # compares against the five row keys: no row matched, so tapping *Your
      # rating* left the card with nothing checked and no direction pill, and
      # the next tap could not flip the direction because `assigns.sort` never
      # equalled the key that had been pressed. *Release date* had the milder
      # version — the check appeared on *Recently added*, which is not the row
      # the reader touched.
      #
      # Re-applying the screen's own key last is the whole fix. Nothing about
      # what is stored changes; `stored` is still the store's four-key word.
      socket
      |> restated(stored)
      |> Kati.Screens.ShelfFilters.put_sort(sort, direction)
    else
      Kati.Screens.ShelfFilters.put_sort(socket, sort, direction)
    end
  end

  @doc false
  def put_sort(socket, sort, direction) do
    socket
    |> Mob.Socket.assign(:sort, sort)
    |> Mob.Socket.assign(:direction, direction)
  end

  @doc """
  Board 145's sort key, as `Kati.Library.ShelfFilters` names it.

  The board draws five and the store can answer four. `Release date` needs a
  first-air year and no column holds one — the same absence that takes the
  decade buckets off a device — so choosing it stores the shelf's own order
  instead of a sort by a value that is always `nil`. `Your rating` is the
  standing rating off the newest watch, which is where every rating in this
  app actually is.

      iex> Kati.Screens.ShelfFilters.stored_sort(:your_rating)
      :rating

      iex> Kati.Screens.ShelfFilters.stored_sort(:release_date)
      :recently_added

      iex> Kati.Screens.ShelfFilters.stored_sort(:title)
      :title
  """
  @spec stored_sort(atom()) :: atom()
  def stored_sort(:your_rating), do: :rating
  def stored_sort(:release_date), do: :recently_added
  def stored_sort(key) when key in [:title, :runtime, :recently_added], do: key
  def stored_sort(_key), do: :recently_added

  @doc "A single-select bucket: tapping the selected one clears it, tapping another replaces it."
  @spec toggle_single(Mob.Socket.t(), atom(), atom()) :: Mob.Socket.t()
  def toggle_single(socket, field, key) do
    current = Map.get(socket.assigns, field)
    next = if current == key, do: nil, else: key
    Mob.Socket.assign(socket, field, next)
  end

  @doc "A multi-select bucket: tapping a chip flips its membership in the set."
  @spec toggle_set(Mob.Socket.t(), atom(), atom()) :: Mob.Socket.t()
  def toggle_set(socket, field, key) do
    set = Map.get(socket.assigns, field)
    next = if MapSet.member?(set, key), do: MapSet.delete(set, key), else: MapSet.put(set, key)
    Mob.Socket.assign(socket, field, next)
  end

  @doc """
  `showing`, recomputed for real from the buckets currently selected.

  Each row's chips are an OR — Drama or Anime keeps a title tagged with
  either — so a row's contribution is the sum of its selected chips' counts.
  Across rows the relationship is AND, and a real intersection can never
  exceed its narrowest constituent, so the four rows' contributions are
  combined with `Enum.min/1` rather than multiplied. An empty selection
  contributes nothing and is dropped rather than counted as zero, so
  clearing every bucket answers the full shelf.
  """
  @spec recompute(Mob.Socket.t()) :: Mob.Socket.t()
  def recompute(socket) do
    a = socket.assigns
    total = Sample.total()

    restrictions =
      [
        Kati.Screens.ShelfFilters.facet_count(Sample.decades(), List.wrap(a.decade)),
        Kati.Screens.ShelfFilters.facet_count(Sample.ratings(), List.wrap(a.rating)),
        Kati.Screens.ShelfFilters.facet_count(Sample.genres(), MapSet.to_list(a.genres)),
        Kati.Screens.ShelfFilters.facet_count(Sample.services(), MapSet.to_list(a.services))
      ]
      |> Enum.reject(&is_nil/1)

    showing =
      case restrictions do
        [] -> total
        counts -> counts |> Enum.min() |> min(total)
      end

    Mob.Socket.assign(socket, :showing, showing)
  end

  @doc false
  def facet_count(_facets, []), do: nil

  def facet_count(facets, keys) do
    facets
    |> Enum.filter(fn {key, _label, _count} -> key in keys end)
    |> Enum.map(&elem(&1, 2))
    |> Enum.sum()
  end

  @doc "Clears every bucket and the sort, back to Recently added / DESC. See the moduledoc for why this is not what `mount/3` draws."
  @spec reset(Mob.Socket.t()) :: Mob.Socket.t()
  def reset(socket) do
    Kati.Library.ShelfFilters.clear()

    cleared =
      socket
      |> Mob.Socket.assign(:sort, :recently_added)
      |> Mob.Socket.assign(:direction, :desc)
      |> Mob.Socket.assign(:decade, nil)
      |> Mob.Socket.assign(:rating, nil)
      |> Mob.Socket.assign(:genres, MapSet.new())
      |> Mob.Socket.assign(:services, MapSet.new())

    if socket.assigns.facets,
      do: restated(cleared, Kati.Library.ShelfFilters.resting()),
      else: Mob.Socket.assign(cleared, :showing, Sample.total())
  end
end
