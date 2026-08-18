defmodule Kati.Calendar.Layout do
  @moduledoc """
  Lane assignment for a day column: interval-graph colouring, pure.

  No geometry in, no geometry out. Input is occurrences carrying
  `{id, start_min, end_min, kind}` in minutes from midnight in the display
  zone; output is `{col, span, n_cols}` per occurrence — *fractions of a
  row*, never pixels.

  That split is forced rather than chosen. `render/1` cannot know how wide
  the screen is: `Mob.Device` exposes battery, thermal, network,
  orientation, model and OS version and **no screen size or density**
  (`mob/lib/mob/device.ex:128-336`), and the only geometry feedback in the
  stack — `Modifier.onGloballyPositioned` — reaches Elixir solely through
  `:rpc` from a dev machine (`mob/lib/mob/test.ex:1118-1119`). So a layout
  needing absolute widths is impossible here, and one needing only
  proportions is free: the Compose bridge honours a per-child `weight`
  float (`MobBridge.kt:2195-2200`) and resolves widths at native layout
  time, at the real density.

  ## The phases

  Overlap layout is interval-graph colouring. Interval graphs are perfect,
  so the minimum number of columns equals the largest clique — the most
  events concurrent at any one instant — and a greedy left-to-right sweep
  reaches that optimum. Hence:

    0. **Collapse by kind.** Three or more occurrences of one kind inside a
       prospective cluster fold into one synthetic occurrence. This runs
       **first**, or phases 1–3 allocate columns to events that are then
       never drawn.
    1. **Cluster.** Sweep the sorted list, extending the current cluster
       while `start < cluster_max_end`. Clusters are independent.
    2. **Assign columns.** Place each occurrence in the lowest-indexed
       column whose last occupant ends at or before its start; open a new
       column when none is free.
    3. **Expand.** An occurrence with no overlapping neighbour to its right
       widens into the gap, so a short event does not leave dead space.

  ## Decisions this module makes

  **Zero-length occurrences get a floor**, `min_render_minutes/0`, which is
  fifteen. `overlaps?/2` is strict on both sides, so a
  0-minute occurrence overlaps nothing, collides with nothing, and would
  render as an invisible sliver. The floor applies to **layout only**: the
  stored `dtstart`/`dtend` are untouched, because a calendar that silently
  lengthens a user's event is worse than one that draws a thin one.

  **Order is total.** Sorted by `{start_min, -end_min, id}`, id last and
  load-bearing. There is no BEAM-side diff — every change ships the whole
  tree and calls `set_root` — so two occurrences that sort equally would
  swap lanes on an unrelated tap. `lanes/2` is a pure function of the input
  *set*: shuffling the input cannot change the output.

  **All-day occurrences never arrive here.** They belong to the band above
  the gutter. The caller filters them; this module has no concept of them.
  """

  # Layout-only floor for a zero-length occurrence. Fifteen minutes is the
  # smallest slot the design's time gutter draws legibly.
  @min_render_minutes 15

  # Phase 0 fires at three, matching the design's "3+ same-kind grouped
  # cards" rule (design-index.md:94) and screen 52's meal collapse (:149).
  @collapse_at 3

  # ...but only for kinds where a group reads better than its members.
  #
  # Found against real device data: `Kati.Calendars.DeviceImport` stamps
  # every mirrored row `kind: :event`, so a kind-only rule folded three
  # clashing meetings into one "3 event events" card and destroyed exactly
  # the clash the day view exists to show. The design's rule is about
  # repetition — five meals, three episodes, two renewals — where the group
  # is the useful unit. A meeting is not repetition; each one is its own
  # commitment and hiding it is a missed appointment.
  @collapsible_kinds [:meal, :air_date, :episode, :money, :habit]

  @type occurrence :: %{
          required(:id) => term(),
          required(:start_min) => integer(),
          required(:end_min) => integer(),
          optional(:kind) => atom()
        }

  @type placement :: %{
          event: occurrence(),
          role: :event | :overflow,
          col: non_neg_integer(),
          span: pos_integer(),
          n_cols: pos_integer()
        }

  @doc """
  Lay out one day's timed occurrences.

  Options:

    * `:max_cols` — hard cap on lanes, default 2, which is screen 09's
      "capped at two columns". A cluster needing more keeps its
      highest-ranked `max_cols` occurrences and emits one overflow tile.
    * `:collapse?` — run phase 0, default `true`.
    * `:collapse_kinds` — which kinds may fold, default
      `#{inspect(@collapsible_kinds)}`. Generic calendar events are
      deliberately absent; see the note on `@collapsible_kinds`.
  """
  @spec lanes([occurrence()], keyword()) :: [placement()]
  def lanes(occurrences, opts \\ []) do
    occurrences |> clusters(opts) |> Enum.flat_map(& &1.placements)
  end

  @doc """
  The same layout, grouped into the clusters it was computed from.

  This is what a renderer wants: one `Row` per cluster, its children
  carrying `weight = span`. Reconstructing the grouping from `lanes/2` by
  eye does not work — clustering is a sweep over running maximum end, not
  a property of any single occurrence — and getting it wrong renders every
  event on its own row with the lanes silently never splitting.

  Each cluster carries its `:overflow` tile separately, because that tile
  is a footer beneath the row rather than a lane inside it.
  """
  @spec clusters([occurrence()], keyword()) :: [
          %{
            start_min: integer(),
            end_min: integer(),
            n_cols: pos_integer(),
            placements: [placement()],
            overflow: placement() | nil
          }
        ]
  def clusters(occurrences, opts \\ []) do
    max_cols = Keyword.get(opts, :max_cols, 2)
    collapse? = Keyword.get(opts, :collapse?, true)
    kinds = Keyword.get(opts, :collapse_kinds, @collapsible_kinds)

    occurrences
    |> Enum.map(&floor_duration/1)
    |> sort()
    |> cluster()
    |> Enum.map(fn group ->
      placements =
        group
        |> maybe_collapse(collapse?, kinds)
        |> sort()
        |> layout_cluster(max_cols)

      {tiles, cards} = Enum.split_with(placements, &(&1.role == :overflow))

      %{
        start_min: group |> Enum.map(& &1.start_min) |> Enum.min(),
        end_min: group |> Enum.map(& &1.end_min) |> Enum.max(),
        n_cols: cards |> Enum.map(& &1.n_cols) |> Enum.max(fn -> 1 end),
        placements: cards ++ tiles,
        overflow: List.first(tiles)
      }
    end)
  end

  @doc "The layout-only minimum duration, exposed so tests state the number once."
  @spec min_render_minutes() :: pos_integer()
  def min_render_minutes, do: @min_render_minutes

  @doc "How many same-kind occurrences trigger phase 0."
  @spec collapse_at() :: pos_integer()
  def collapse_at, do: @collapse_at

  @doc "Kinds that may fold. See the note on why `:event` is not one of them."
  @spec collapsible_kinds() :: [atom()]
  def collapsible_kinds, do: @collapsible_kinds

  # ── Phase 0 ─────────────────────────────────────────────────────────────

  defp maybe_collapse(group, false, _kinds), do: group

  defp maybe_collapse(group, true, kinds) do
    {collapsible, rest} =
      group
      |> Enum.group_by(&Map.get(&1, :kind))
      |> Enum.split_with(fn {kind, members} ->
        kind in kinds and length(members) >= @collapse_at
      end)

    collapsed = Enum.map(collapsible, fn {kind, members} -> collapse(kind, members) end)
    Enum.flat_map(rest, fn {_kind, members} -> members end) ++ collapsed
  end

  defp collapse(kind, members) do
    sorted = sort(members)

    %{
      id: {:collapsed, kind, Enum.map(sorted, & &1.id)},
      start_min: sorted |> Enum.map(& &1.start_min) |> Enum.min(),
      end_min: sorted |> Enum.map(& &1.end_min) |> Enum.max(),
      kind: kind,
      collapsed: sorted
    }
  end

  # ── Phase 1 ─────────────────────────────────────────────────────────────

  # `<` not `<=`: an occurrence starting exactly when the cluster ends does
  # not overlap it and belongs to the next one.
  defp cluster(sorted) do
    sorted
    |> Enum.reduce([], fn ev, acc ->
      case acc do
        [{group, max_end} | rest] when ev.start_min < max_end ->
          [{[ev | group], max(max_end, ev.end_min)} | rest]

        _ ->
          [{[ev], ev.end_min} | acc]
      end
    end)
    |> Enum.map(fn {group, _} -> Enum.reverse(group) end)
    |> Enum.reverse()
  end

  # ── Phases 2 and 3 ──────────────────────────────────────────────────────

  defp layout_cluster(group, max_cols) do
    {placed, cols} = assign_columns(group)
    n = length(cols)

    if n <= max_cols do
      Enum.map(placed, fn {ev, col} ->
        %{event: ev, role: :event, col: col, span: span_right(ev, col, placed, n), n_cols: n}
      end)
    else
      overflow(group, max_cols)
    end
  end

  defp assign_columns(group) do
    {placed, cols} =
      Enum.reduce(group, {[], []}, fn ev, {placed, cols} ->
        case Enum.find_index(cols, &(&1 <= ev.start_min)) do
          nil -> {[{ev, length(cols)} | placed], cols ++ [ev.end_min]}
          i -> {[{ev, i} | placed], List.replace_at(cols, i, ev.end_min)}
        end
      end)

    {Enum.reverse(placed), cols}
  end

  defp span_right(ev, col, placed, n) do
    placed
    |> Enum.filter(fn {o, c} -> c > col and overlaps?(o, ev) end)
    |> Enum.map(fn {_, c} -> c end)
    |> Enum.min(fn -> n end)
    |> Kernel.-(col)
  end

  defp overlaps?(a, b), do: a.start_min < b.end_min and b.start_min < a.end_min

  # ── Overflow ────────────────────────────────────────────────────────────

  # Screen 09 shows a cluster of three as two lanes AND a `+1 MORE`, which
  # settles what the tile is: if it consumed a lane, three events capped at
  # two columns would read "+2 MORE" over a single card. So `max_cols`
  # occurrences are kept, and the tile is a **footer** spanning the whole
  # cluster rather than a lane — `role: :overflow`, `col: 0`, `span: n_cols`.
  #
  # A property test over 200 generated days asserts no two `:event`
  # placements share a column and a minute; the footer is excluded because
  # it is not in the lane grid, and the renderer reserves its height beneath
  # the cluster.
  #
  # Ranked by start then longer-first — the two most "primary" events — with
  # the id tiebreak carried through so the choice cannot flicker.
  defp overflow(group, max_cols) do
    {kept, hidden} = group |> sort() |> Enum.split(max_cols)

    placements =
      kept
      |> assign_columns()
      |> then(fn {placed, cols} ->
        n = length(cols)

        Enum.map(placed, fn {ev, col} ->
          %{event: ev, role: :event, col: col, span: 1, n_cols: max(n, 1)}
        end)
      end)

    placements ++ [overflow_tile(hidden, max_cols)]
  end

  defp overflow_tile(hidden, max_cols) do
    %{
      event: %{
        id: {:overflow, Enum.map(hidden, & &1.id)},
        start_min: hidden |> Enum.map(& &1.start_min) |> Enum.min(),
        end_min: hidden |> Enum.map(& &1.end_min) |> Enum.max(),
        overflow: hidden
      },
      role: :overflow,
      col: 0,
      span: max_cols,
      n_cols: max_cols
    }
  end

  # ── Shared ──────────────────────────────────────────────────────────────

  defp sort(occurrences), do: Enum.sort_by(occurrences, &{&1.start_min, -&1.end_min, &1.id})

  defp floor_duration(%{start_min: s, end_min: e} = occ) when e - s < @min_render_minutes,
    do: %{occ | end_min: s + @min_render_minutes}

  defp floor_duration(occ), do: occ
end
