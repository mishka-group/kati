defmodule Kati.Screens.UpNextFilters do
  @moduledoc """
  Board 167 — Sort & filter, the sheet over *Up next*.

  ## Why this is not board 145's sheet a second time

  Screen 10's `tune` disc pushed `Kati.Screens.ShelfFilters` from the day it
  got a tap, and that was the closest thing available rather than the right
  thing: 145 sorts by *Recently added · Title · Your rating · Runtime ·
  Release date* over the whole shelf, and not one of board 167's four
  orderings is in that list. Worse, both sheets would have written the same
  stored key — so picking `Title` on screen 03 would have reordered Up next,
  and clearing the shelf's genre chips would have cleared this page's bands.

  So the store is its own (`Kati.Library.UpNextFilters`) and so is the board.
  What is **shared** is the chrome: `sort_row/5`, `chip_row/2`, `facet_chip/4`
  and `count_card/2` are `Kati.Screens.ShelfFilters`' own functions, called
  from here. The two sheets are pixel-identical by construction, which is the
  claim board 167 makes about itself — a second artboard, not a second style.

  ## The counts are screen 10's own arithmetic

  `5 + 6 + 3 + 1 = 15`, `12 ready + 3 cold = 15`, and *Airing soon 4* is a
  subset of the twelve rather than a fourth band — which is exactly what
  screen 10's header says when it prints `12 ready · 4 airing soon`. That is
  why `Kati.Library.UpNextFilters.bands_of/3` answers a LIST: a row can be
  both ready and airing, and a footer that added the three bands would print
  19 over fifteen rows.

  On a device the numbers are the reader's own — `buckets/1` counts every
  bucket including the empty ones, so a chip that would empty the page says so
  at `0` in board 145's hairline grey before it is tapped. That includes a
  queue with nothing in it: every count reads `0` rather than falling back to
  board 167's own fifteen, the same move screen 10 itself makes.
  `drawn_opening_for_test/0` still answers the board's own state, for the
  gate `Kati.ScreenEmptyDatabaseTest` and the design-literal sweep read it
  through.

  ## Reset clears the filters and not the sort

  Board 168 rules it, and it is the one place this sheet deliberately parts
  company with 145's, whose `Reset` clears both. Sort is the persisted thing;
  filters last a session. `Kati.Library.UpNextFilters.clear_filters/1` is the
  half that runs.
  """

  use Mob.Screen
  use Gettext, backend: Kati.Gettext
  import Mob.Sigil

  alias Kati.Library.UpNextFilters, as: Filters
  alias Kati.Library.UpNextFiltersSample, as: Sample
  alias Kati.Screens.ShelfFilters
  alias Kati.UI
  alias Kati.UI.SettingsList
  alias Kati.UI.Sheet

  # `_params` and not `params`: `Kati.ScreenParamsSweepTest` matches the word
  # `params` in a screen's source to decide whether it reads what pushed it,
  # and an underscore has no word boundary in front of it. This sheet is
  # pushed bare — it narrows the one Up next there is.
  def mount(_params, _session, socket) do
    Kati.Theme.activate()
    Kati.Locale.activate()

    {:ok, Mob.Socket.assign(socket, Kati.Screens.UpNextFilters.opening())}
  end

  @doc """
  What the sheet opens on: the choice this device has stored, counted against
  the queue it narrows.
  """
  @spec opening() :: keyword()
  def opening, do: state_for(Filters.current())

  @doc """
  The board's opening state, for the gate that asserts an empty queue gets it.

  `Kati.ScreenEmptyDatabaseTest` compares `opening/0` against this — the same
  pairing board 145 carries — so *a device with nothing on the go draws board
  167* is a claim a run settles rather than one this moduledoc asserts.
  """
  @spec drawn_opening_for_test() :: keyword()
  def drawn_opening_for_test, do: board_state(Filters.resting())

  defp state_for(choice) do
    device_state(Kati.Screens.UpNext.pool(), choice)
  end

  # Board 167's own fifteen. The chips still carry the reader's choice, because
  # a sheet that drew nothing selected while the store held two chips would be
  # lying about the page behind it rather than about the counts.
  defp board_state(choice) do
    [
      sort: choice.sort,
      direction: choice.direction,
      runtimes: choice.runtimes,
      bands: choice.bands,
      runtime_counts: Enum.map(Sample.runtimes(), fn {key, _label, n} -> {key, n} end),
      band_counts: Enum.map(Sample.bands(), fn {key, _label, n} -> {key, n} end),
      showing: Sample.total(),
      total: Sample.total()
    ]
  end

  @doc false
  @spec device_state(map(), map()) :: keyword()
  def device_state(pool, choice) do
    buckets = Filters.buckets(pool)
    narrowed = Filters.apply(pool, choice)

    [
      sort: choice.sort,
      direction: choice.direction,
      runtimes: choice.runtimes,
      bands: choice.bands,
      runtime_counts: buckets.runtimes,
      band_counts: buckets.bands,
      showing: length(narrowed.ready) + length(narrowed.cold),
      total: length(pool.ready) + length(pool.cold)
    ]
  end

  def render(assigns),
    do: Sheet.sheet(gettext("Sort & filter"), body(assigns), Kati.Screens.Identity.of(__MODULE__))

  @doc false
  def body(assigns) do
    # Both section labels are board 145's OWN msgids, reused rather than
    # restated — as are the title in `render/1` and `Gone cold` in
    # `chip_label/2`. The two sheets are pixel-identical by construction (see
    # the moduledoc), and a second entry for `Sort` is a second place the same
    # word gets translated, which is how one control comes to be called two
    # things on two boards that are meant to be the same board twice.
    #
    # `Sort` keeps 145's context for the reason `Kati.Screens.ShelfFilters.body/1`
    # gives: a one-word msgid one edit away from `Sort & filter` — the title of
    # this very sheet — is exactly the pair `mix gettext.merge` fuzzy-matches.
    # The Ranges eyebrow is a whole clause and needs none.
    ~MOB"""
    <Column fill_width={true}>
      {UI.eyebrow(pgettext("sort & filter sheet section", "Sort"))}
      {Kati.Screens.UpNextFilters.sort_card(assigns.sort, assigns.direction)}
      <Spacer size={16} />
      {SettingsList.eyebrow_muted(gettext("Ranges — buckets, not sliders"))}
      {Kati.Screens.UpNextFilters.runtime_row(assigns)}
      <Spacer size={11} />
      {Kati.Screens.UpNextFilters.band_row(assigns)}
      <Spacer size={16} />
      {ShelfFilters.count_card(assigns.showing, assigns.total)}
      <Spacer size={14} />
      {SettingsList.note("info", Kati.Screens.UpNextFilters.note_text())}
    </Column>
    """
  end

  @doc "The four orderings in their card; the active one carries a check and a direction pill."
  @spec sort_card(atom(), atom()) :: map()
  def sort_card(selected, direction) do
    options = Sample.sort_options()
    last = length(options) - 1

    rows =
      options
      |> Enum.with_index()
      |> Enum.map(fn {{key, label}, i} ->
        ShelfFilters.sort_row(
          key,
          Kati.Screens.UpNextFilters.sort_label(key, label),
          selected,
          direction,
          i != last
        )
      end)

    SettingsList.card(rows)
  end

  @doc """
  The reader's own word for one of board 167's four orderings.

  `Kati.Library.UpNextFiltersSample` stays in the board's English, because what
  travels out of it is a **key**: `:airing_soonest` is what `sort_row/5`
  compares against `selected` to decide which row carries the check, what
  `handle_info/2` matches against `Kati.Library.UpNextFilters.sorts/0`, and what
  `apply_sort/2` stores and `natural_direction/1` is asked about. A key that
  translated itself would break all four the moment the reader chose Persian,
  and would break them silently — the rows would still draw.
  `Kati.Screens.ShelfFilters.sort_label/2` is the same split over board 145's
  five and carries the long version of the argument.

  Public, and not a `defp`, because `Kati.Screens.UpNext` prints these same four
  words in the line a narrowed queue says about itself — see
  `Kati.Library.UpNextFilters.names/1` — and the chip and that sentence must not
  come to spell one ordering two ways.

  A key with no clause of its own comes back with the sample's own label, so a
  fifth ordering added tomorrow draws in English rather than raising — the right
  failure for a design fixture, since `mix gettext.extract` reads literal call
  sites and could not have a msgid for it either way.
  """
  @spec sort_label(atom(), String.t()) :: String.t()
  # All four take a context. `Recently touched` is one word from `Recently
  # added`, `Recently watched` and `Recently eaten`, which the catalogue already
  # holds three different Persian words for; `Time left` sits beside `%{n}m
  # left` and `%{n} left today`; and `Airing soonest` is three letters from the
  # `Airing soon` chip below, which is a different thing — an ordering, not a
  # band. Any of them would arrive fuzzy-matched to somebody else's sentence.
  def sort_label(:recently_touched, _label),
    do: pgettext("an up next sort key", "Recently touched")

  def sort_label(:closest_to_finishing, _label),
    do: pgettext("an up next sort key", "Closest to finishing")

  def sort_label(:time_left, _label), do: pgettext("an up next sort key", "Time left")
  def sort_label(:airing_soonest, _label), do: pgettext("an up next sort key", "Airing soonest")

  def sort_label(_key, label), do: label

  @doc "The runtime rail — four buckets, counts included, zeroes drawn."
  @spec runtime_row(map()) :: map()
  def runtime_row(assigns),
    do: rail(assigns.runtime_counts, assigns.runtimes)

  @doc "The band rail — ready, airing soon and gone cold."
  @spec band_row(map()) :: map()
  def band_row(assigns), do: rail(assigns.band_counts, assigns.bands)

  defp rail(counts, chosen) do
    counts
    |> Enum.map(fn {key, n} ->
      {key, Kati.Screens.UpNextFilters.chip_label(key, Sample.label(key)), n}
    end)
    |> ShelfFilters.chip_row(fn key -> key in chosen end)
  end

  @doc """
  The reader's own word for one of board 167's seven chips.

  The same split `sort_label/2` makes and for the same reason: the first element
  of every triple `rail/2` builds is a **key** — it is what `chip_row/2`'s
  `selected?` closure tests and what `handle_info/2` matches against
  `Kati.Library.UpNextFilters.runtime_keys/0` and `band_keys/0` — and only the
  second is a word. Public for the same reason too: screen 10 names these chips
  in its own sentence through `Kati.Library.UpNextFilters.names/1`.

  `Gone cold` takes `Kati.Screens.ShelfFilters.facet_label/2`'s own `shelf
  status` context rather than starting a second one. It is the same state named
  on the same kind of chip — not where a title was put, but what happened to it
  — and two contexts would let board 145 and board 167 spell one word two ways.

  **The runtime thresholds are numbers this sheet prints**, which is the half a
  Latin-letter audit cannot see: `Under 30m` and `30–60m` carry figures that a
  Persian reader reads in Persian numerals. They come in as bindings through
  `Kati.Locale.number/1`, so the msgid holds the sentence and not the arithmetic.
  `Kati.Library.UpNextFilters.runtime_bucket/2` is where 30 and 60 actually
  live; these are those two figures read out loud, and naming them once per side
  is what keeps the chip and the bucket from drifting apart.
  """
  @spec chip_label(atom(), String.t()) :: String.t()
  def chip_label(:runtime_short, _label),
    do: pgettext("a runtime bucket", "Under %{n}m", n: Kati.Locale.number(30))

  def chip_label(:runtime_medium, _label) do
    pgettext("a runtime bucket", "%{from}–%{to}m",
      from: Kati.Locale.number(30),
      to: Kati.Locale.number(60)
    )
  end

  def chip_label(:runtime_long, _label), do: pgettext("a runtime bucket", "Over an hour")
  def chip_label(:runtime_unknown, _label), do: pgettext("a runtime bucket", "No runtime")

  def chip_label(:band_ready, _label), do: pgettext("an up next band", "Ready")
  def chip_label(:band_airing, _label), do: pgettext("an up next band", "Airing soon")
  def chip_label(:band_cold, _label), do: pgettext("shelf status", "Gone cold")

  def chip_label(_key, label), do: label

  @doc """
  The dashed footnote, which is one `Text` and therefore one msgid.

  The words were `Kati.Library.UpNextFiltersSample.note/0` and are a literal
  here now: `gettext/1`'s argument has to be a literal AT THE CALL SITE or
  `mix gettext.extract` never sees it, so a sentence read out of another module
  cannot be translated from this one. `Kati.Screens.ShelfFilters.note_text/1`
  holds board 145's note the same way and for the same reason — the sample
  modules are what the boards are drawn from, not what they are read from.

  Still one msgid, which is the half of the sample's own argument that survives
  the move: `Kati.DesignLiterals.locate/2` is `String.contains?` over each node's
  own string, so every run board 167's three `<strong>`s split this sentence
  into has to land inside one node to be found at the `:node` tier.
  """
  @spec note_text() :: String.t()
  def note_text do
    gettext(
      "Airing soon is a date, not a window. A title whose release is a bare year is not in the bucket rather than counted as 1 January — “soon” is a date Kati is sure enough of to name. No runtime is not padding: an evicted cache row keeps its position and has no duration, so it needs somewhere nameable to land."
    )
  end

  def handle_info({:tap, :close}, socket), do: {:noreply, Kati.Screens.Resume.pop(socket)}

  def handle_info({:tap, :reset}, socket),
    do: {:noreply, Kati.Screens.UpNextFilters.reset(socket)}

  def handle_info({:tap, tag}, socket) do
    cond do
      tag in Filters.sorts() ->
        {:noreply, Kati.Screens.UpNextFilters.apply_sort(socket, tag)}

      tag in Filters.runtime_keys() ->
        {:noreply, Kati.Screens.UpNextFilters.toggle(socket, :runtimes, tag)}

      tag in Filters.band_keys() ->
        {:noreply, Kati.Screens.UpNextFilters.toggle(socket, :bands, tag)}

      true ->
        {:noreply, socket}
    end
  end

  @doc """
  Tapping the active sort row flips its direction; any other row becomes the
  new sort at **its own** natural direction.

  Not 145's *any other row becomes the new sort at DESC*: 145's five keys all
  read newest-or-highest first, and two of these four do not. A sort called
  *Airing soonest* opening at DESC would draw the word **soonest** over the
  latest row.
  """
  @spec apply_sort(Mob.Socket.t(), atom()) :: Mob.Socket.t()
  def apply_sort(socket, key) do
    chosen = Filters.current()

    direction =
      if chosen.sort == key,
        do: flip(chosen.direction),
        else: Filters.natural_direction(key)

    %{chosen | sort: key, direction: direction}
    |> Filters.put()
    |> then(fn stored -> restated(socket, stored) end)
  end

  defp flip(:desc), do: :asc
  defp flip(_asc), do: :desc

  @doc """
  A chip pressed: narrow by it, or stop narrowing by it.

  Written on every tap rather than on a Done button, because this sheet has no
  Done — it has a ✕, and a sheet whose only exit discarded the choice is the
  defect `Kati.Library.ShelfFilters` describes. Screen 10 re-reads on the pop through
  `Kati.Screens.Resume`, so the queue behind is already narrowed when it comes
  back.
  """
  @spec toggle(Mob.Socket.t(), :runtimes | :bands, atom()) :: Mob.Socket.t()
  def toggle(socket, field, tag) do
    chosen = Filters.current()
    lit = Map.fetch!(chosen, field)
    next = if tag in lit, do: List.delete(lit, tag), else: [tag | lit]

    chosen
    |> Map.put(field, next)
    |> Filters.put()
    |> then(fn stored -> restated(socket, stored) end)
  end

  @doc "Clears the chips and leaves the sort where it is. See the moduledoc."
  @spec reset(Mob.Socket.t()) :: Mob.Socket.t()
  def reset(socket) do
    Filters.current()
    |> Filters.clear_filters()
    |> then(fn stored -> restated(socket, stored) end)
  end

  @doc "The sheet redrawn against what is now stored, counts and all."
  @spec restated(Mob.Socket.t(), map()) :: Mob.Socket.t()
  def restated(socket, choice) do
    Enum.reduce(state_for(choice), socket, fn {key, value}, acc ->
      Mob.Socket.assign(acc, key, value)
    end)
  end
end
