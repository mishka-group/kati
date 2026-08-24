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

  ## Why this screen still reads `Kati.SeriesSettings.Sample`

  This is the screen in the Screen subtree with the strongest claim to a
  migration and it did not get one, so the reasons are written out rather than
  left to be re-derived. The top of it is `Kati.Media.TrackedTitle` almost
  literally: `status` is the three tiles, and `auto_add_new_seasons`,
  `notify_new_episodes`, `add_air_dates_to_calendar` and
  `hide_unwatched_titles` are the four switches of the season-pass card in the
  order the drawing lists them, with the resource's own defaults —
  `true, true, true, false` — already matching the drawing's four positions.
  That resource's moduledoc names this screen three separate times, and **those
  four columns have no other reader anywhere in the app**. That is the cost of
  not moving, and it is a real one.

  Three things stop it, and only the first is a matter of taste:

    * **The `Region & availability` group is not per-show, and has no store at
      all.** `Region · United Kingdom`, `My services · Lumen+, Orbit, Kino · 3 of
      12`, `Watch for price drops` and `Preferred quality · 4K HDR where offered`
      are app-level preferences and a subscription list. There is no settings
      resource in `Kati.Media` or anywhere else — `lib/kati/settings/` is Sample
      modules — and no offers resource for "available" to mean anything against.
      Four of this screen's eleven rows would stay frozen beside four that had
      become the user's own, which is the arrangement `Kati.Screens.Series`
      rejects: half real reads as fully real.
    * **Two sub-lines are per-show claims that need the episode tables.** `S4
      will appear when announced` is `Kati.Media.CachedSeason.count/1` plus one
      and `Currently 5 of 7 in S2` is
      `Kati.Media.CachedEpisode.watched_of/2` against the tracked row's
      `progress_season`. Both resources exist and, since
      `20260821231241_media_seasons_and_episodes`, so do their tables — so this
      is now a matter of nothing writing a season or an episode row rather than
      of nowhere to put one. Frozen, the two lines are sentences about a season
      this show may not have and a position the user is not at.
    * ~~**The referent cannot be picked safely yet.**~~ **Resolved.** This said
      that `Kati.Notifications.Sources.MediaTest` created real `:tv` tracked
      rows and never removed them, so a shared-file sweep like
      `Kati.ScreenDesignLiteralTest` would find a tracked series or not
      depending on where `--seed` put the two modules — a coin flip rather than
      a flake. That module now carries the `on_exit` the entry asked for, so
      the referent could be picked the way `Kati.Screens.Film` picks its own:
      the newest tracked series. Kept rather than deleted because it is the one
      of the three that a reader would otherwise re-derive from scratch.

  So one blocker stands, and it is the one that decides the screen. Blocker two
  has also softened — the season and episode tables exist since
  `20260821231241_media_seasons_and_episodes`, so its two sub-lines want a
  writer rather than a schema. What has not moved is the first: half of this
  screen would become the user's own and half would stay a picture, and
  `Kati.Screens.Series` rejects exactly that arrangement because half real
  reads as fully real.

  That is also why the controls here carry no `on_tap` at all. A switch that
  flips and forgets is not a smaller version of a switch that works — it is a
  screen that lies about having saved something, which is worse than one that
  visibly does nothing.
  """
  use Kati.Screens.Pushed, back: "Series"

  alias Kati.Components.MishkaThemeIcon
  alias Kati.SeriesSettings.Sample
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :show, Sample.show())

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
        {SettingsList.chrome("more_horiz", 44)}
        {SettingsList.title(show.title, show.subtitle, nil, :meta_tight)}
        {UI.eyebrow(show.status_label)}
        {Kati.Screens.SeriesSettings.statuses()}
        {UI.eyebrow(show.season_pass_label)}
        {Kati.Screens.SeriesSettings.group(Kati.SeriesSettings.Sample.season_pass())}
        {UI.eyebrow(show.region_label)}
        {Kati.Screens.SeriesSettings.group(Kati.SeriesSettings.Sample.region())}
        {SettingsList.eyebrow_muted(show.this_show_label)}
        {Kati.Screens.SeriesSettings.last_group(Kati.SeriesSettings.Sample.this_show())}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def statuses do
    tiles =
      Sample.statuses()
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
    ~MOB"""
    <Box weight={1.0}>
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
    ~MOB"""
    <Box weight={1.0}>
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
      rule: rule?
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
