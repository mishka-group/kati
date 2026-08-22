defmodule Kati.Screens.WhatFits do
  @moduledoc """
  Screen 13 — What fits?, pushed under Library.

  Built to `.scratch/design/screens/13.html`: a cream card carrying the window
  of time you actually have, then the episodes that fit inside it, then the
  nearest thing that does not.

  Cream is doing the same job here as on Home and on screen 08 — it marks the
  one block that is *yours* rather than the library's. The window is an input,
  not a statistic, so its buttons sit on `rgba(255,255,255,.6)` wells inside the
  cream instead of on cards of their own.

  The last section is the honest half of the feature: the design labels it
  `Nothing else fits — nearest film is 1h 46m` under a **grey** dash, and draws
  the row flat on `#F4F1EC` with a `Tomorrow` button. Telling the user what was
  excluded, and offering to move it rather than hiding it, is why the screen is
  worth having; a filter that silently drops things is just a shorter list.

  The four mood chips hug their labels, which is what a chip is, so they are
  `Kati.Components.MishkaChip`.

  The five window buttons are `flex:1` in the drawing, so each is a
  `Box weight={1.0}` around a `fill_width` box, and they stay hand-rolled.
  They are chips by behaviour — one of them is selected — but `MishkaChip`
  hardcodes `fill_width={false}` on its root and offers no way to override it:
  its only sizing escape hatch is an exact `width`, which a `flex:1` row does
  not know. A `fill_width` prop on the chip, defaulting to `false` so no
  existing chip moves, is what this needs. `MishkaPill` has exactly that prop
  and would draw them, but its own docs send anything with a checked state to
  the chip, and a selected/unselected pair is precisely what these are.

  ## Why this screen still reads `Kati.Screens.WhatFits.Sample`

  **This section used to say `Kati.Media` has no episode, and that is no longer
  true.** `20260821231241_media_seasons_and_episodes` built
  `Kati.Media.CachedEpisode` with `title`, `runtime_minutes`, `season_number`,
  `episode_number` and `air_at`, and `for_title/2` and `for_season/3` to read
  them — which is what took `Kati.Screens.Series` and `Kati.Screens.Inbox` off
  their Sample modules. Three of the four things listed below were blocked on
  exactly that resource and are now expressible:

    * **`41m`, `43m`, `44m`** — a per-episode runtime. Available:
      `CachedEpisode.runtime_minutes`, which is the per-episode number this
      screen sorts on rather than `Kati.Media.CachedTitle.runtime_minutes`, the
      title's nominal length that a three-episode window could never be measured
      against.
    * **`S3 · E2`** — an unwatched episode's place in its series. Available:
      `for_title/2` is the inventory `Kati.Media.TrackedTitle.progress_season`
      and `progress_episode` could not be, and those two remain the bookmark
      that says where to start reading it.
    * **`3 episodes fit`** — the count follows the list.

  One thing is still genuinely absent, and it is an axis rather than a value:

    * **`Light`, `Tense`, `Long-form`** — a mood. `CachedTitle.genres` is a
      genre, which is a different claim about a title, and `Kati.Media.Watch.tags`
      is per-watch and written after the fact. Nothing on the new episode
      resource speaks to it either.

  So what keeps this screen on its Sample module is now a decision about scope
  rather than a fact about the schema: the list is derivable and the three chips
  above it are not, and a page whose rows are real while its only filter is
  invented would be the same kind of half-truth the paragraph below objects to.
  Recorded plainly so the next pass weighs that rather than re-deriving a
  blocker that has already been cleared.

  Two things here *are* expressible and are deliberately not split out. The
  over-budget row is one — `Quiet Harbour` at `1H 46M · 61 MIN OVER` is a
  `kind: :movie` tracked row's `runtime_minutes` measured against the chosen
  window — and `Sunday, 21:40` is the other, a wall clock `Kati.Time` would
  answer (and which the audit frame pins to the drawing's own evening). A
  screen whose *nothing else fits* row is the user's real film while the three
  episodes above it are invented would be making its most specific claim about
  data it does not have. Both land on the round the list above them does.
  """
  use Kati.Screens.Pushed, back: "Library"

  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaChip
  alias Kati.Components.MishkaPill
  alias Kati.Screens.WhatFits.Sample
  alias Kati.Theme.Palette
  alias Kati.UI

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :tonight, Sample.tonight())

  @doc false
  def content(assigns) do
    t = assigns.tonight

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {Kati.Screens.WhatFits.more_row()}
        {Kati.Screens.WhatFits.header(t)}
        {Kati.Screens.WhatFits.window(t)}
        {UI.eyebrow(t.fits_label)}
        {Kati.Screens.WhatFits.fits(t)}
        {Kati.UI.Eyebrow.quiet(t.over_label)}
        {Kati.Screens.WhatFits.over(t)}
      </Column>
    </Scroll>
    """
  end

  # The back pill is Kati.Screens.Pushed's, floating at the left. This row
  # reserves its height and carries the overflow disc opposite it.
  @doc false
  def more_row do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} height={44} align="center">
        <Spacer weight={1.0} />
        {Kati.Screens.WhatFits.more_disc()}
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  The overflow disc — Mishka's Action Icon, now that it can float.

  A floating disc is defined by its shadow. `action_icon/2` painted a fill and
  stopped there, which reads as a flat patch of card colour rather than as a
  control sitting above the paper, so this disc stayed hand-rolled; `shadow`
  takes the design's `Kati.Theme.shadow_button()` string untouched and closes
  that gap.

  Same pixels. `shape: :circle` is an exact `size / 2`, so 44 rounds at 22 as
  the literal did; the fill, the shadow and the centring pass straight
  through; and the glyph is the same `Kati.UI.symbol/2` Text, now inside a Row
  that hugs it — a hugging Row centred in a Box puts its one child where the
  bare Text sat.
  """
  @spec more_disc() :: map()
  def more_disc do
    MishkaActionIcon.action_icon(
      [
        size: 44,
        shape: :circle,
        variant: :filled,
        background: Palette.card(),
        shadow: Kati.Theme.shadow_button()
      ],
      [Kati.UI.symbol("more_horiz", size: 21)]
    )
  end

  @doc false
  def header(t) do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text="What fits?"
        text_size={28}
        max_font_scale={1.6}
        font_weight="bold"
        letter_spacing={-0.03}
        text_color={:on_surface}
      />
      <Spacer size={5} />
      <Text
        text={t.now}
        font_family="mono"
        text_size={11}
        text_color={Palette.muted()}
        max_lines={1}
      />
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def window(t) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.cream()}
        corner_radius={24}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={19}
      >
        <Text
          text={String.upcase("Time you have")}
          font_family="mono"
          text_size={10.5}
          letter_spacing={0.16}
          text_color={Palette.cream_meta()}
        />
        <Spacer size={8} />
        <Text
          text={t.window}
          text_size={40}
          font_weight="extrabold"
          letter_spacing={-0.04}
          text_color={:on_surface}
        />
        <Spacer size={16} />
        <Row fill_width={true} align="center">
          {t.lengths
           |> Enum.map(&Kati.Screens.WhatFits.length_button/1)
           |> Enum.intersperse(Kati.Screens.WhatFits.gap())}
        </Row>
        <Spacer size={10} />
        <Row fill_width={true} align="center">
          {t.moods
           |> Enum.map(&Kati.Screens.WhatFits.mood_chip/1)
           |> Enum.intersperse(Kati.Screens.WhatFits.gap())}
        </Row>
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def gap, do: ~MOB"<Spacer size={6} />"

  @doc false
  def length_button(l) do
    bg = if l.selected, do: Palette.ink_fill(), else: Palette.cream_raise()
    fg = if l.selected, do: Palette.on_ink(), else: Palette.cream_sub()

    ~MOB"""
    <Box weight={1.0}>
      <Box fill_width={true} height={36} corner_radius={12} background={bg} align="center">
        <Text text={l.label} text_size={12.5} font_weight="semibold" text_color={fg} max_lines={1} />
      </Box>
    </Box>
    """
  end

  @doc """
  One mood chip — Mishka's Chip.

  A mood is picked, not pressed, so this is a chip and not a button: `checked`
  is the state and the four colours below are the two states' fills and inks.
  It could only become one now that the component takes the *unchecked* pair as
  props — a chip whose unselected state was a theme token could not draw
  `rgba(255,255,255,.6)` on cream, which is this screen's whole idea of a well.

  The chosen mood is `rgba(232,130,60,.18)` with a bronze label rather than
  solid ink: a mood is a preference, not a commitment, so the design gives it a
  tint where it gives the runtime a fill.

  Nothing moves. `padding_x: 11, padding_y: 0` is the Row's own 11/0, and the
  bridge pads before it sizes, so `height: 28` stays 28. The chip is a hugging
  `Box` around a hugging `Row` where this was one `Row`, which places a single
  centred Text at the identical offset.
  """
  @spec mood_chip(map()) :: map()
  def mood_chip(m) do
    MishkaChip.chip(
      label: m.label,
      checked: m.selected,
      color: Palette.accent_wash(),
      text_color: Palette.gold_text(),
      unchecked_color: Palette.cream_raise(),
      unchecked_text_color: Palette.cream_sub(),
      height: 28,
      corner_radius: 14,
      padding_x: 11,
      padding_y: 0,
      text_size: 11.5,
      font_weight: :semibold,
      max_lines: 1
    )
  end

  @doc false
  def fits(t) do
    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(t.fits, fn row -> Kati.Screens.WhatFits.fit_row(row) end)}
      <Spacer size={13} />
    </Column>
    """
  end

  @doc false
  def fit_row(row) do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.card()}
        corner_radius={18}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={13}
        padding_right={13}
        padding_top={10}
        padding_bottom={10}
        align="center"
      >
        {Kati.Screens.WhatFits.thumb(row.seed)}
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text
            text={row.title}
            text_size={13.5}
            font_weight="bold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={4} />
          <Text
            text={row.meta}
            font_family="mono"
            text_size={10.5}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
        <Spacer size={12} />
        <Text
          text={row.run}
          font_family="mono"
          text_size={12}
          font_weight="medium"
          text_color={:on_surface}
          max_lines={1}
        />
      </Row>
      <Spacer size={9} />
    </Column>
    """
  end

  @doc false
  def over(t) do
    row = t.over

    ~MOB"""
    <Row
      fill_width={true}
      background={Palette.card_settled()}
      corner_radius={18}
      padding_left={13}
      padding_right={13}
      padding_top={10}
      padding_bottom={10}
      align="center"
    >
      {Kati.Screens.WhatFits.thumb(row.seed)}
      <Spacer size={12} />
      <Column weight={1.0}>
        <Text
          text={row.title}
          text_size={13.5}
          font_weight="semibold"
          text_color={Palette.ink_soft()}
          max_lines={1}
        />
        <Spacer size={4} />
        <Text
          text={row.meta}
          font_family="mono"
          text_size={10.5}
          text_color={Palette.tertiary()}
          max_lines={1}
        />
      </Column>
      <Spacer size={12} />
      {Kati.Screens.WhatFits.defer_pill(row.action)}
    </Row>
    """
  end

  @doc """
  The `Tomorrow` affordance on the over-budget row — Mishka's Pill.

  A pill, not a chip: it carries no selected state, it is the row's one offer.
  It reads as a label on a tinted lozenge, which is what a pill is.

  The pixels are the Row's. `padding: 0` with `padding_left`/`padding_right`
  at 12 gives the bridge exactly the 12/0 edges it had, and since padding is
  applied before height, `height: 30` measures 30 as it did. The pill is a
  hugging `Box` (its root passes `fill_width={false}`) wrapping a `Row` that
  holds the label and an empty `Row` where the ✕ would go; both hug, the empty
  one is zero-wide, and `align: :center` puts the pair where the Row's own
  `align="center"` put the Text. `max_lines: 1` is the pill's own default and
  is what this Text already carried.
  """
  @spec defer_pill(String.t()) :: map()
  def defer_pill(label) do
    MishkaPill.pill(
      label: label,
      background: Palette.placeholder(),
      color: Palette.ink_soft(),
      corner_radius: 15,
      height: 30,
      padding: 0,
      padding_left: 12,
      padding_right: 12,
      align: :center,
      text_size: 11.5,
      font_weight: :semibold
    )
  end

  @doc false
  def thumb(seed) do
    case Sample.poster(seed) do
      nil ->
        ~MOB"<Box width={40} height={56} corner_radius={8} background={Palette.placeholder()} />"

      src ->
        ~MOB"""
        <Image src={src} width={40} height={56} corner_radius={8} content_mode="fill" />
        """
    end
  end
end
