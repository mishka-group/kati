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
  at `0` in board 145's hairline grey before it is tapped. On a device with
  nothing on the go there is nothing to count, and the board's own fifteen are
  drawn, which is the state board 167 is a drawing of.

  ## Reset clears the filters and not the sort

  Board 168 rules it, and it is the one place this sheet deliberately parts
  company with 145's, whose `Reset` clears both. Sort is the persisted thing;
  filters last a session. `Kati.Library.UpNextFilters.clear_filters/1` is the
  half that runs.
  """

  use Mob.Screen
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
    pool = Kati.Screens.UpNext.pool()

    case pool.ready ++ pool.cold do
      [] -> board_state(choice)
      _queue -> device_state(pool, choice)
    end
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

  defp device_state(pool, choice) do
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
    do: Sheet.sheet("Sort & filter", body(assigns), Kati.Screens.Identity.of(__MODULE__))

  @doc false
  def body(assigns) do
    ~MOB"""
    <Column fill_width={true}>
      {UI.eyebrow("Sort")}
      {Kati.Screens.UpNextFilters.sort_card(assigns.sort, assigns.direction)}
      <Spacer size={16} />
      {SettingsList.eyebrow_muted("Ranges — buckets, not sliders")}
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
        ShelfFilters.sort_row(key, label, selected, direction, i != last)
      end)

    SettingsList.card(rows)
  end

  @doc "The runtime rail — four buckets, counts included, zeroes drawn."
  @spec runtime_row(map()) :: map()
  def runtime_row(assigns),
    do: rail(assigns.runtime_counts, assigns.runtimes)

  @doc "The band rail — ready, airing soon and gone cold."
  @spec band_row(map()) :: map()
  def band_row(assigns), do: rail(assigns.band_counts, assigns.bands)

  defp rail(counts, chosen) do
    counts
    |> Enum.map(fn {key, n} -> {key, Sample.label(key), n} end)
    |> ShelfFilters.chip_row(fn key -> key in chosen end)
  end

  @doc "The dashed footnote. `Kati.Library.UpNextFiltersSample` holds the words."
  @spec note_text() :: String.t()
  def note_text, do: Sample.note()

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
  defect MOVIES-AND-TV.md #26 describes. Screen 10 re-reads on the pop through
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
