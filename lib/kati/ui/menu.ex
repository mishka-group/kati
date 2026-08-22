defmodule Kati.UI.Menu do
  @moduledoc """
  The overflow menu — the panel behind a header's `more_horiz`.

  ## Why this had to be designed rather than found

  Five of the 62 drawings put a `more_horiz` or a `density_medium` in a header
  and none of them draws what it opens. Seven screens were stranded behind that
  gap: a reader could see the button on screens 02, 04, 08, 09 and 43, and
  nothing was on the other side of it.

  So the menu is new, and it is built out of the app's own parts rather than
  invented: the panel is the card every other floating surface here is —
  `Palette.card()` at radius 18 under `Kati.Theme.shadow_card/1` — and a row is
  the settings row's rhythm without its chevron, because a menu item performs
  an action rather than promising a screen with more of the same on it.

  ## Why `Kati.Components.Anchored` and not a Column

  A menu that takes part in layout is not a menu. Stacked under its trigger it
  would push the whole page down as it opened, and inside screen 02's `Scroll`
  or any radius-carrying `Box` a panel placed outside the parent's bounds
  measures `(0, 0, 0, 0)` — invisible and untappable. `Anchored` gives it its
  own window, which no ancestor can clip. That node is `K-18` in
  `native/LEDGER.md`; this is its first use in Kati.

  ## Dismissal

  `on_dismiss` is the report of a tap that landed OUTSIDE the panel, and every
  menu must pass one or the only way out is to pick something. It reaches the
  wire as `on_tap` — see `Kati.Components.Anchored` — which is why the bridge
  excludes `anchored` from its generic tap wrapper.

  ## Shape

      Menu.overflow(trigger, open?,
        [
          Menu.item("info", "Show details", :show_details),
          Menu.item("checklist", "Episode order", :episode_order)
        ],
        dismiss: :close_menu
      )

  A closed menu renders the trigger alone: no window, no panel, nothing to
  measure.
  """

  import Mob.Sigil

  alias Kati.Components.Anchored
  alias Kati.Theme
  alias Kati.Theme.Palette

  # Bound into locals at each call site rather than read as `@width` inside a
  # `~MOB` block: the sigil treats `@name` as an assign and raises for one it
  # cannot find in `assigns`, which a helper function does not have.
  @width 250
  @row_height 46

  @doc """
  A trigger with a menu behind it.

  `open?` decides whether the panel exists at all rather than whether it is
  visible: a hidden-but-present panel is still a window the bridge has to
  position, and a menu nobody opened should cost nothing.
  """
  @spec overflow(map(), boolean(), [map()], keyword()) :: map()
  def overflow(trigger, open?, items, opts \\ [])

  def overflow(trigger, false, _items, _opts), do: Anchored.closed(trigger)

  def overflow(trigger, true, items, opts) do
    Anchored.anchor(trigger, panel(items),
      side: :bottom,
      # `:end` so the panel's right edge meets the trigger's. A header disc
      # sits at the right margin, and a centred panel would hang off it.
      align: :end,
      side_offset: 8,
      # `{pid, tag}`, not a bare atom. `Anchored` passes this straight through
      # as `on_tap`, and Mob.Renderer only registers a handle for the tuple
      # shape — an atom encodes as itself, the bridge finds no handle, and the
      # panel becomes undismissable with nothing logged. Measured on device:
      # the menu opened and stayed open through every tap outside it.
      on_dismiss: {self(), Keyword.fetch!(opts, :dismiss)}
    )
  end

  @doc """
  One row: a glyph, a label, and the tag its screen answers.

  `destructive: true` colours both in the app's danger ink. Nothing else about
  the row changes — a red row that is also bigger or set apart reads as a
  different kind of control rather than the same control with a warning on it.
  """
  @spec item(String.t(), String.t(), atom(), keyword()) :: map()
  def item(glyph, label, tag, opts \\ []) do
    %{glyph: glyph, label: label, tag: tag, destructive: Keyword.get(opts, :destructive, false)}
  end

  @doc "A hairline between two groups of items."
  @spec rule() :: map()
  def rule, do: %{rule: true}

  defp panel(items) do
    width = @width

    ~MOB"""
    <Column
      width={width}
      background={Palette.card()}
      corner_radius={18}
      shadow={Theme.shadow_card()}
      padding_top={6}
      padding_bottom={6}
    >
      {Enum.map(items, &Kati.UI.Menu.entry/1)}
    </Column>
    """
  end

  @doc false
  def entry(%{rule: true}) do
    ~MOB"""
    <Column fill_width={true} padding_top={5} padding_bottom={5} padding_left={12} padding_right={12}>
      <Box fill_width={true} height={1} background={Palette.hairline()} />
    </Column>
    """
  end

  def entry(%{glyph: glyph, label: label, tag: tag, destructive: destructive?}) do
    # `red`, the palette's own danger ink — there is no separate `danger` token
    # and inventing one for a single row would put a 88th literal in a file
    # whose whole point is that every colour is accounted for.
    tint = if destructive?, do: Palette.red(), else: Palette.ink_soft()
    text = if destructive?, do: Palette.red(), else: :on_surface
    tap = {self(), tag}
    height = @row_height

    ~MOB"""
    <Row
      fill_width={true}
      height={height}
      padding_left={12}
      padding_right={12}
      align="center"
      on_tap={tap}
    >
      {Kati.UI.symbol(glyph, size: 18, color: tint)}
      <Spacer size={12} />
      <Text
        text={label}
        text_size={14}
        font_weight="semibold"
        text_color={text}
        max_lines={1}
        weight={1.0}
      />
    </Row>
    """
  end
end
