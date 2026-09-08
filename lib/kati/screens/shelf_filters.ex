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
    do: Sheet.sheet("Sort & filter", body(assigns), Kati.Screens.Identity.of(__MODULE__))

  @doc false
  def body(assigns) do
    ~MOB"""
    <Column fill_width={true}>
      {UI.eyebrow("Sort")}
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
        Kati.Screens.ShelfFilters.sort_row(key, label, selected, direction, i != last)
      end)

    SettingsList.card(rows)
  end

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
    assigns = %{
      label: if(desc?, do: "DESC", else: "ASC"),
      rotate: if(desc?, do: 0.0, else: 180.0)
    }

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
        font_family="mono"
        text_size={10.5}
        text_color={Palette.ink_soft()}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc false
  def decade_row(selected) do
    Kati.Screens.ShelfFilters.chip_row(Sample.decades(), fn key -> key == selected end)
  end

  @doc false
  def rating_row(selected) do
    Kati.Screens.ShelfFilters.chip_row(Sample.ratings(), fn key -> key == selected end)
  end

  @doc false
  def genre_row(selected) do
    Kati.Screens.ShelfFilters.chip_row(Sample.genres(), fn key ->
      MapSet.member?(selected, key)
    end)
  end

  @doc false
  def service_row(selected) do
    Kati.Screens.ShelfFilters.chip_row(Sample.services(), fn key ->
      MapSet.member?(selected, key)
    end)
  end

  # One non-wrapping Row per literal chip line — the board never puts more
  # chips on a row than fit, so there is nothing here for `Row` to wrap and
  # nothing gained by pretending it can.
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
      {chips}
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
      trailing: UI.chip_count(Integer.to_string(count), count_color)
    )
  end

  @doc "The `showing N of 418` line and the Reset tap, in their own card."
  @spec count_card(non_neg_integer(), pos_integer()) :: map()
  def count_card(showing, total) do
    assigns = %{text: "showing #{showing} of #{total}"}

    ~MOB"""
    <Box
      fill_width={true}
      background={Kati.Theme.card(Palette.mode())}
      corner_radius={20}
      padding={15}
      shadow={Kati.Theme.shadow_card_soft()}
    >
      <Row fill_width={true} align="center">
        <Text text={@text} font_family="mono" text_size={13} text_color={:on_surface} max_lines={1} />
        <Spacer weight={1.0} />
        <Row align="center" on_tap={{self(), :reset}}>
          <Text
            text="Reset"
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
      {SettingsList.eyebrow_muted("Ranges — buckets, not sliders")}
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
      {SettingsList.eyebrow_muted("Ranges — buckets, not sliders")}
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
    chips = Enum.map(decades, fn {decade, n} -> {decade_tag(decade), "#{decade}s", n} end)

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
      {SettingsList.eyebrow_muted("Filters")}
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
      {SettingsList.eyebrow_muted("Filters")}
      {Kati.Screens.ShelfFilters.facet_row(assigns.facets, assigns.genres)}
      <Spacer size={16} />
    </Column>
    """
  end

  @doc "One chip per genre the shelf holds, with how many titles carry it."
  @spec facet_row([{String.t(), non_neg_integer()}], MapSet.t()) :: map()
  def facet_row(facets, selected) do
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
    "Ranges are chip buckets, not sliders — the app has no slider in its component table, and a bucket carries a count while a slider cannot. Count badges exist so a chip that would empty the shelf says so before it is tapped: Comedy reads 0 in hairline grey."
  end

  def note_text(_facets) do
    "Genres and release years come from the provider, so these are the ones your own shelf carries. Streaming service is not offered: nothing in Kati holds a catalogue."
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
      restated(Kati.Screens.ShelfFilters.put_sort(socket, sort, direction), stored)
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
