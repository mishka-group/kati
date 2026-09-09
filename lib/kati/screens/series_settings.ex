defmodule Kati.Screens.SeriesSettings do
  @moduledoc """
  Screen 35 — per-show settings, pushed under Series.

  Built to `test/design/screens/35.html`. Three grouped lists in the usual
  card rhythm, over one thing that is not a list: the **Status** row, where
  watching / paused / dropped are three tiles of equal weight with one filled
  ink. The design's caption is explicit that this is the point — state as "a
  first-class choice rather than a swipe action" — so it is drawn as a choice
  and not as a switch with a hidden third value.

  The last eyebrow's dash is grey rather than accent. Orange means new or now,
  and **This show** is a set of things you do *to* the show — reset, archive,
  remove — rather than a peer of the two groups above it, so it takes
  `Kati.UI.SettingsList.eyebrow_muted/1`.

  The final row is the only one in the Settings subtree drawn in `#B4553C`:
  a red tile, a red label and no second line. It gets its own leading and body
  here rather than a `danger:` flag threaded through the shared helper, which
  would put a colour decision inside a component that has no opinion about
  meaning.

  No dock — this is a pushed screen — so the frame closes at 40, not 132.

  ## Components, and the Status row that is not one

  `danger_tile/1` is `Kati.Components.MishkaThemeIcon` — the same component
  `Kati.UI.SettingsList.icon_tile/1` gives every other row here, differing only
  in the colour it is handed, which is the point: the red is a decision this
  file makes, and the container has no opinion about meaning.

  **The three Status tiles stay hand-rolled**, and no vendored component is
  close. They are not segments of a strip: each is a `Column` with a 21pt glyph
  *above* a label, each carries its own shadow (the chosen one a heavier, tighter
  `0 12px 24px -14px` than its two neighbours), and each takes `weight: 1.0` so
  the three split the row. `MishkaSegmentedControl` lays a single `Text` per
  segment with no icon slot and no vertical stack; `MishkaChip` and `MishkaPill`
  both put their content in a `Row`, which would set the glyph *beside* the
  label rather than over it, and neither takes a per-item layout weight. What
  they would need is a content slot that is a `Column` — which is a different
  component, not a prop.

  ## What this screen reads, and the two groups it drops

  MOVIES-AND-TV.md #99: every control here was inert, including four switches
  whose columns already existed on `Kati.Media.TrackedTitle` with matching
  defaults and no other reader or writer anywhere in the app, and three Status
  tiles that map onto `Kati.Media.TrackedTitle.status` exactly.

  The moduledoc that stood here argued they had to stay that way, and its
  reason was a good one: *half of this screen would become the user's own and
  half would stay a picture*, which is the arrangement `Kati.Screens.Series`
  rejects because half real reads as fully real. It named the wrong unit. The
  half with no schema is not scattered rows — it is two whole GROUPS:

    * **Region & availability** — `Region · United Kingdom`, `My services ·
      Lumen+, Orbit, Kino · 3 of 12`, `Watch for price drops` and `Preferred
      quality · 4K HDR where offered`. App-level preferences and a subscription
      list, none of them per-show and none of them stored.
    * **This show** — reset, archive, remove. Things you do *to* a show, and
      the three of them want writers this screen is not the place to add.

  A group with nothing behind it is dropped rather than drawn dead, which is
  the rule screen 14's `band/4` settled when its cast, offers and tags bands
  started falling away one at a time, and the one screen 92's `free_band/1`
  keeps. So over a real show this page is the Status tiles and the Season pass,
  both of them entirely the reader's, and nothing else — see `show/1` and
  `region_band/1`. Over no show — the gallery, every sweep, a push that named
  nothing — it is board 35 whole, groups included.

  Two sub-lines the board draws are still the board's on both branches: `S4
  will appear when announced` and `Currently 5 of 7 in S2`. They belong to
  rows whose switches now write, and they say what the switch DOES rather than
  where this show is, so they are copy rather than a frozen claim.

  A switch that flips and forgets would still be worse than one that visibly
  does nothing — that part of the old argument holds, and it is why `write/2`
  moves the control only after the store answers.
  """
  use Kati.Screens.Pushed, back: "Series"

  alias Kati.Components.MishkaThemeIcon
  alias Kati.SeriesSettings.Sample
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @impl true
  def load(socket) do
    socket
    |> Mob.Socket.assign(:show, Kati.Screens.SeriesSettings.show(socket.assigns.params))
    |> Mob.Socket.assign(:menu?, false)
  end

  @doc """
  The push screen 04's ⋯ sends: which show its *Show settings* row was over.

  The same shape `Kati.Screens.DropSheet.params_for/1` takes and for the same
  reason — this page WRITES, so a bare push is a settings page that saves onto
  whichever row `show/1` happened to find rather than the one the user opened
  the menu on.

      iex> Kati.Screens.SeriesSettings.params_for(%{tracked_id: "abc"})
      %{tracked_id: "abc", back: "Series"}

      iex> Kati.Screens.SeriesSettings.params_for(%{})
      %{}
  """
  @spec params_for(map()) :: map()
  def params_for(%{tracked_id: id}) when is_binary(id), do: %{tracked_id: id, back: "Series"}
  def params_for(_row), do: %{}

  @doc """
  The show this page is about: the reader's, or the drawing's.

  MOVIES-AND-TV.md #99. The moduledoc below argued that every control here had
  to stay inert because *half of this screen would become the user's own and
  half would stay a picture*. That is the right rule and it named the wrong
  unit: the half that has no schema is two whole GROUPS — *Region &
  availability* and *This show* — and a group with nothing behind it is
  dropped rather than drawn dead. Screen 14 settled that shape when its bands
  started falling away one at a time, and screen 92 kept it for its own *Free
  with ads* band.

  So over a real show this page is the Status tiles and the Season pass, both
  of them entirely the reader's, and nothing else. Over no show it is board 35
  whole, which is what the gallery and every sweep render.
  """
  @spec show(map() | nil) :: map()
  def show(params) do
    case Kati.Screens.SeriesSettings.tracked(Map.get(params || %{}, :tracked_id)) do
      nil -> Map.put(Sample.show(), :tracked, nil)
      tracked -> Kati.Screens.SeriesSettings.shaped(tracked)
    end
  end

  @doc false
  @spec tracked(String.t() | nil) :: struct() | nil
  def tracked(id) when is_binary(id) do
    case Ash.get(Kati.Media.TrackedTitle, id) do
      {:ok, tracked} -> tracked
      _gone -> nil
    end
  rescue
    _error -> nil
  end

  def tracked(_none), do: nil

  @doc false
  def shaped(tracked) do
    %{
      title: Kati.Screens.SeriesSettings.title_of(tracked),
      subtitle: "show settings",
      status_label: "Status",
      season_pass_label: "Season pass",
      region_label: nil,
      this_show_label: nil,
      tracked: tracked
    }
  end

  @doc false
  def title_of(tracked) do
    # `Kati.Media.Release.cached_for/1` rather than a second copy of the query.
    # The durable half references the cache by a VALUE PAIR and not a foreign
    # key — see `Kati.Media.TrackedTitle` — and that function is the one place
    # that stands in for the join, so it is also the one place that has to be
    # right about it.
    case Kati.Media.Release.cached_for(tracked) do
      %{title: title} when is_binary(title) and title != "" -> title
      # A tracked row whose cache entry has been evicted still has settings
      # worth changing, so the page opens with a name it can stand behind
      # rather than refusing to open at all.
      _evicted -> "Untitled"
    end
  rescue
    _error -> "Untitled"
  end

  # The four columns of the season pass, in the order the drawing lists their
  # rows. One list rather than two: `season_pass/1` reads it to light the
  # switches and `change_for/2` reads it to decide whether a tag names a column
  # at all, so the two cannot drift into flipping different things.
  @pass_columns [
    :auto_add_new_seasons,
    :notify_new_episodes,
    :add_air_dates_to_calendar,
    :hide_unwatched_titles
  ]

  @doc """
  The four switches of the season pass, live over a real show.

  Every one of them is a column `Kati.Media.TrackedTitle` has carried since it
  was written, with a matching default and — until this — no reader and no
  writer anywhere in the app. The board's own sub-lines are kept: they say what
  each one DOES, which does not change with whose show it is.
  """
  @spec season_pass(map()) :: [map()]
  def season_pass(%{tracked: nil}), do: Sample.season_pass()

  def season_pass(%{tracked: t}) do
    Sample.season_pass()
    |> Enum.zip(Enum.map(@pass_columns, &{&1, Map.fetch!(t, &1)}))
    |> Enum.map(fn {row, {field, on?}} ->
      # The tap goes on the ROW and the control stays a picture, which is the
      # shape screen 25 settled: `Kati.UI.SettingsList.row/4` takes the
      # `on_tap`, so the whole 44pt line is the target rather than a 46x28
      # switch somebody has to hit.
      row
      |> Map.put(:control, {:switch, on?})
      |> Map.put(:tap, {self(), String.to_atom("pass_" <> Atom.to_string(field))})
    end)
  end

  @doc """
  The three status tiles, lit from the row rather than from the fixture.

  `Kati.Media.TrackedTitle.status` maps onto them exactly, which is what made
  this the easiest half of the screen to believe was hard.
  """
  @spec status_tiles(map()) :: [map()]
  def status_tiles(%{tracked: nil}), do: Sample.statuses()

  def status_tiles(%{tracked: t}) do
    Enum.map(Sample.statuses(), fn tile ->
      tile
      |> Map.put(:on, tile.status == t.status)
      |> Map.put(:tracked, t)
    end)
  end

  @doc false
  def content(assigns) do
    show = assigns.show

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
          Kati.Screens.SeriesSettings,
          Kati.Screens.SeriesSettings.id_of(show),
          Map.get(assigns, :menu?, false)
        )}
        {SettingsList.title(show.title, show.subtitle, nil, :meta_tight)}
        {UI.eyebrow(show.status_label)}
        {Kati.Screens.SeriesSettings.statuses(Kati.Screens.SeriesSettings.status_tiles(show))}
        {UI.eyebrow(show.season_pass_label)}
        {Kati.Screens.SeriesSettings.group(Kati.Screens.SeriesSettings.season_pass(show))}
        {Kati.Screens.SeriesSettings.region_band(show)}
        {Kati.Screens.SeriesSettings.this_show_band(show)}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The tap on a status tile, or `nil` on the drawing.

  The already-lit tile keeps its tap: pressing *Watching* on a show that is
  already watching writes the same value, which is the ordinary way somebody
  checks a state rather than changes it, and a tile that went dead once chosen
  would be a control that stops answering exactly when you press it to be sure.

  `Kati.ScreenTapSweepTest` never sees any of these, and not because they are
  exempt: it renders against an empty store, where there is no tracked row, so
  every tile answers `nil` and the sweep has no tag to sweep. That is the blind
  spot the sweep's own moduledoc names — a screen whose controls only exist
  over data draws none of them for it — and it is why `Kati.SeriesSettingsTest`
  writes a real row and presses the tiles itself.
  """
  @spec status_tap(map()) :: {pid(), atom()} | nil
  def status_tap(%{tracked: %{}, status: status}),
    do: {self(), Kati.Screens.AddByHand.tag("status_", status)}

  def status_tap(_drawn), do: nil

  @doc """
  Flip one season-pass switch, or set the status — the whole of what this
  screen can write, and it could write none of it.

  Every column named here is one `Kati.Media.TrackedTitle` has carried since it
  was written, with no other reader or writer in the app: MOVIES-AND-TV.md #99
  is that four switches and three tiles sat over columns matching them by name
  and did nothing.

  The screen follows the store — the switch moves after the write answers —
  which is the rule screen 34's ticks keep for the same reason: a control that
  moves first is showing a state the database does not hold.
  """
  @spec write(Mob.Socket.t(), atom()) :: Mob.Socket.t()
  def write(socket, tag) do
    show = socket.assigns.show

    with %{} = tracked <- Map.get(show, :tracked),
         {:ok, fresh} <- Ash.get(Kati.Media.TrackedTitle, tracked.id),
         {:ok, changes} <- Kati.Screens.SeriesSettings.change_for(tag, fresh),
         {:ok, updated} <- fresh |> Ash.Changeset.for_update(:update, changes) |> Ash.update() do
      Mob.Socket.assign(socket, :show, %{show | tracked: updated})
    else
      _refused -> socket
    end
  end

  @doc """
  What one tag changes, or `:error` for a tag this screen does not own.

      iex> Kati.Screens.SeriesSettings.change_for(:status_Paused, %{})
      {:ok, %{status: :paused}}

      iex> Kati.Screens.SeriesSettings.change_for(:something_else, %{})
      :error
  """
  @spec change_for(atom(), map()) :: {:ok, map()} | :error
  def change_for(tag, tracked) do
    case Atom.to_string(tag) do
      "pass_" <> field ->
        # `@pass_columns` rather than `String.to_existing_atom/1`: every atom
        # in the app already exists, so that call would happily turn a typo
        # into a key and `Map.fetch!/2` would raise inside a tap handler —
        # which on a pushed screen is a dead process and a bounce to Home.
        case Enum.find(@pass_columns, &(Atom.to_string(&1) == field)) do
          nil -> :error
          key -> {:ok, %{key => not Map.fetch!(tracked, key)}}
        end

      "status_" <> key ->
        case Enum.find(Kati.SeriesSettings.Sample.statuses(), &(Atom.to_string(&1.status) == key)) do
          nil -> :error
          tile -> {:ok, %{status: tile.status}}
        end

      _other ->
        :error
    end
  end

  @impl true
  def handle_tap(tag, socket) do
    case Kati.Screens.ShowPages.handle(
           socket,
           tag,
           Kati.Screens.SeriesSettings.tracked_id(socket),
           "Show settings"
         ) do
      {:handled, moved} -> {:noreply, moved}
      :unknown -> {:noreply, Kati.Screens.SeriesSettings.write(socket, tag)}
    end
  end

  @doc false
  @spec id_of(map()) :: String.t() | nil
  def id_of(%{tracked: %{id: id}}), do: id
  def id_of(_drawn), do: nil

  @doc false
  @spec tracked_id(Mob.Socket.t()) :: String.t() | nil
  def tracked_id(socket) do
    case Map.get(socket.assigns.show, :tracked) do
      %{id: id} -> id
      _drawn -> nil
    end
  end

  @doc """
  *Region & availability* and *This show*, or nothing at all.

  Nothing at all over a real show, and that is the finding's own argument
  turned into a rule rather than a reason to stop: a group with no schema
  behind it is dropped, the way screen 14 drops a band and screen 92 drops its
  *Free with ads*. What is left is two groups that are entirely the reader's.
  """
  @spec region_band(map()) :: map()
  def region_band(%{tracked: nil}) do
    assigns = %{
      eyebrow: UI.eyebrow("Region & availability"),
      group: Kati.Screens.SeriesSettings.group(Sample.region())
    }

    ~MOB"""
    <Column fill_width={true}>
      {@eyebrow}
      {@group}
    </Column>
    """
  end

  def region_band(_show), do: ~MOB"<Spacer size={0} />"

  @doc false
  def this_show_band(%{tracked: nil}) do
    assigns = %{
      eyebrow: SettingsList.eyebrow_muted("This show"),
      group: Kati.Screens.SeriesSettings.last_group(Sample.this_show())
    }

    ~MOB"""
    <Column fill_width={true}>
      {@eyebrow}
      {@group}
    </Column>
    """
  end

  def this_show_band(_show), do: ~MOB"<Spacer size={0} />"

  @doc false
  def statuses(tiles_source) when is_list(tiles_source) do
    tiles =
      tiles_source
      |> Enum.map(&Kati.Screens.SeriesSettings.status/1)
      |> Enum.intersperse(Kati.Screens.SeriesSettings.status_gap())

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {tiles}
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def status_gap, do: ~MOB"<Spacer size={8} />"

  # The chosen tile carries a heavier, tighter shadow than the card recipe —
  # `0 12px 24px -14px rgba(26,25,23,.9)` — so it reads as pressed into the
  # paper rather than floating over it like its two neighbours.
  #
  # It is an ink-filled control, so it takes the pair the design draws for one:
  # `Palette.ink_fill/0` under `Palette.on_ink/0`. Screen 28 draws that pair —
  # `#1A1917` + `#FBFAF8` becomes `#F7EFE4` + `#1A1917`, the fill inverting
  # rather than following the ground. `Kati.Theme.ink/0` was the fill before and
  # takes no mode, so in dark the tile, its glyph and its label would all three
  # have been near-black.
  @doc false
  def status(%{on: true} = s) do
    assigns = %{tap: Kati.Screens.SeriesSettings.status_tap(s)}

    ~MOB"""
    <Box weight={1.0} on_tap={@tap}>
      <Column
        fill_width={true}
        corner_radius={18}
        background={Palette.ink_fill()}
        shadow="0 12 24 -14 #E61A1917"
        padding_left={10}
        padding_right={10}
        padding_top={14}
        padding_bottom={14}
      >
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          {Kati.UI.symbol(s.icon, size: 21, color: Palette.on_ink())}
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={8} />
        <Text
          text={s.label}
          text_size={12}
          font_weight="bold"
          text_color={Palette.on_ink()}
          text_align="center"
          max_lines={1}
        />
      </Column>
    </Box>
    """
  end

  def status(s) do
    assigns = %{tap: Kati.Screens.SeriesSettings.status_tap(s)}

    ~MOB"""
    <Box weight={1.0} on_tap={@tap}>
      <Column
        fill_width={true}
        corner_radius={18}
        background={Palette.card()}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={10}
        padding_right={10}
        padding_top={14}
        padding_bottom={14}
      >
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          {Kati.UI.symbol(s.icon, size: 21, color: Palette.sub())}
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={8} />
        <Text
          text={s.label}
          text_size={12}
          font_weight="bold"
          text_color={Palette.ink_soft()}
          text_align="center"
          max_lines={1}
        />
      </Column>
    </Box>
    """
  end

  @doc false
  def group(rows) do
    last = length(rows) - 1

    body =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, i} -> Kati.Screens.SeriesSettings.row(row, i < last) end)

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(body)}
      <Spacer size={22} />
    </Column>
    """
  end

  # The last group closes the frame, so it carries no trailing gap.
  @doc false
  def last_group(rows) do
    last = length(rows) - 1

    body =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, i} -> Kati.Screens.SeriesSettings.row(row, i < last) end)

    SettingsList.card(body)
  end

  @doc false
  def row(%{danger: true} = row, rule?) do
    SettingsList.row(
      Kati.Screens.SeriesSettings.danger_tile(row.icon),
      Kati.Screens.SeriesSettings.danger_body(row.title),
      SettingsList.chevron(),
      padding: 13,
      rule: rule?
    )
  end

  def row(row, rule?) do
    SettingsList.row(
      SettingsList.icon_tile(row.icon),
      SettingsList.body(row.title, row.sub),
      Kati.Screens.SeriesSettings.control(row.control),
      padding: 13,
      rule: rule?,
      # `Map.get`, not `row.tap`: the board's own rows carry no tap and must
      # not gain one. `nil` is the answer `Kati.UI.SettingsList.row/4` already
      # takes for "not tappable".
      on_tap: Map.get(row, :tap)
    )
  end

  @doc false
  def control(:chevron), do: SettingsList.chevron()
  def control({:switch, on?}), do: SettingsList.switch(on?)

  @doc """
  The 30x30 tile at 10% red — the one destructive affordance on the screen.

  `Kati.Components.MishkaThemeIcon`, the same component `Kati.UI.SettingsList`
  gives every other row on this screen, differing only in the colour it is
  handed. `variant: :filled` with an explicit ARGB, not `variant: :light`: the
  light variant computes its own 19% tint from an opaque colour, and the design
  says 10%, so the alpha is stated rather than derived.

  The glyph is a child rather than the `icon:` shorthand, whose `Text` carries
  no `font_family` — a Material Symbols ligature would be typeset as the word,
  and `Kati.UI.symbol/2` also keeps `Kati.Icons.glyph!/1`'s raise for a name
  outside the shipped subset.

  With children and no `id` the component returns
  `%{type: :box, props: %{width: 30, height: 30, align: :center,
  corner_radius: 9, background: Palette.red_wash()}, children: [glyph]}` — node
  for node what this wrote by hand. `red_wash/0` is that stated 10%, and red is a
  hue: `Kati.Theme.dark/0` keeps `error: @red`, so neither the tint nor the glyph
  moves with the mode.
  """
  def danger_tile(name) do
    MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Palette.red_wash(), size: 30, radius: 9},
      [Kati.UI.symbol(name, size: 17, color: Palette.red())]
    )
  end

  @doc false
  def danger_body(title) do
    ~MOB"""
    <Text
      text={title}
      text_size={13.5}
      font_weight="semibold"
      text_color={Palette.red()}
      max_lines={1}
    />
    """
  end
end
