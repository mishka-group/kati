defmodule Kati.Screens.PickSections do
  @moduledoc """
  Screen 26 — *What should Kati keep?*, the second of four onboarding steps.

  Built to `.scratch/design/screens/26.html`: a four-bar step meter with two
  filled, a 32pt two-line question, six section tiles in a 2-across grid, a
  54pt commit button, and a quiet way out to a backup import.

  ## The argument the screen is making

  The app asks what you keep **before** it shows you anything, and it
  pre-selects two so the fast path is already taken. Choosing less is not the
  limited option here — the blurb says every section drops into the same
  calendar and the same home page, so the answer changes what Kati contains,
  not what Kati can do.

  That is why the tiles are a real selection rather than a picture of one:
  chosen tiles invert to ink with an orange `check`, unchosen ones sit on
  card, and the button counts what you have. Drawing a static *Continue with
  2* would have made the screen a slide.

  ## No back, no dock

  Step 2 of 4 has neither a tab bar nor a back pill in the drawing — the step
  meter is the only navigation — so this uses `Mob.Screen` directly and the
  frame ends at 40, not 132.

  Steps 1, 3 and 4 are screen 38, in `Kati.Screens.Onboarding`; this is the
  only one the design gives a page of its own, because it is the only one that
  asks a question.

  ## The check badge

  The drawing positions it absolutely at `top:14; right:14`, inside the tile's
  16pt padding. There is no fill-height reference frame inside a wrap-height
  tile to align an overlay against, so the badge rides in the icon's row
  instead — laid out at the tile's own 16pt inset — and is then nudged the
  remaining 2pt up and out with `offset_x` / `offset_y`. `MobBridge.RenderNode`
  turns those into a `Modifier.offset`, which moves what is drawn without
  moving what was measured, so the icon opposite it and the title below do not
  shift: the badge lands at 14/14 and nothing else on the tile moves.
  """
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Screens.PickSections.Sample
  alias Kati.Theme.Palette

  def mount(_params, _session, socket) do
    # The resolved mode, not a hardcoded `light()`. `Kati.Theme.current/0` is
    # the stored Auto/Light/Dark choice resolved against the device, and every
    # `Palette` token below reads the theme this installs.
    Mob.Theme.set(Kati.Theme.current())
    {:ok, Mob.Socket.assign(socket, :chosen, Sample.chosen())}
  end

  def render(assigns) do
    chosen = assigns.chosen

    ~MOB"""
    <Box
      fill_width={true}
      fill_height={true}
      background={:background}
      layout_direction={Kati.Locale.direction_prop()}
    >
      <Scroll>
        <Column
          fill_width={true}
          padding_left={21}
          padding_right={21}
          padding_top={64}
          padding_bottom={40}
        >
          {Kati.Screens.PickSections.intro()}
          {Kati.Screens.PickSections.grid(chosen)}
          {Kati.Screens.PickSections.commit(chosen)}
        </Column>
      </Scroll>
    </Box>
    """
  end

  def handle_info({:tap, tag}, socket) do
    case Atom.to_string(tag) do
      "section_" <> id -> {:noreply, Mob.Socket.update(socket, :chosen, &toggle(&1, id))}
      _ -> {:noreply, socket}
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  defp toggle(chosen, id) do
    if MapSet.member?(chosen, id), do: MapSet.delete(chosen, id), else: MapSet.put(chosen, id)
  end

  @doc false
  def intro do
    ~MOB"""
    <Column fill_width={true} padding_top={26}>
      {Kati.Screens.PickSections.steps()}
      {Enum.map(Kati.Screens.PickSections.Sample.heading(), fn line -> Kati.Screens.PickSections.heading_line(line) end)}
      <Spacer size={14} />
      <Text
        text={Kati.Screens.PickSections.Sample.blurb()}
        text_size={14.5}
        line_height={1.6}
        text_color={Palette.ink_soft()}
      />
      <Spacer size={30} />
    </Column>
    """
  end

  @doc false
  def heading_line(line) do
    ~MOB"""
    <Text
      text={line}
      text_size={32}
      font_weight="extrabold"
      letter_spacing={-0.035}
      line_height={1.12}
      text_color={:on_surface}
    />
    """
  end

  @doc false
  def steps do
    {total, done} = Sample.steps()

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {1..total
         |> Enum.map(fn i -> Kati.Screens.PickSections.step(i <= done) end)
         |> Enum.intersperse(Kati.Screens.PickSections.step_gap())}
      </Row>
      <Spacer size={26} />
    </Column>
    """
  end

  @doc false
  def step_gap, do: ~MOB"<Spacer size={5} />"

  @doc false
  def step(done?) do
    # A bar, not a control: the filled step is `ink` — the mark meaning of
    # `0xFF1A1917` — and the unreached one is the token whose own words are
    # "a step in a dotline not yet reached".
    color = if done?, do: Palette.ink(), else: Palette.track_off()

    ~MOB"""
    <Box weight={1.0} height={4} corner_radius={2} background={color} />
    """
  end

  @doc false
  def grid(chosen) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.PickSections.Sample.sections()
       |> Enum.chunk_every(2)
       |> Enum.map(fn pair -> Kati.Screens.PickSections.grid_row(pair, chosen) end)
       |> Enum.intersperse(Kati.Screens.PickSections.tile_gap())}
      <Spacer size={30} />
    </Column>
    """
  end

  @doc false
  def tile_gap, do: ~MOB"<Spacer size={12} />"

  @doc false
  def grid_row(pair, chosen) do
    ~MOB"""
    <Row fill_width={true} align="top">
      {pair
       |> Enum.map(fn section -> Kati.Screens.PickSections.tile(section, MapSet.member?(chosen, section.id)) end)
       |> Enum.intersperse(Kati.Screens.PickSections.tile_gap())}
    </Row>
    """
  end

  # A chosen tile inverts rather than gaining a ring: ink ground, paper text,
  # and the orange check. Orange still means new/now — here it means "this one
  # is coming with you".
  @doc false
  def tile(section, chosen?) do
    tap = {self(), String.to_atom("section_" <> section.id)}
    # A chosen tile is an ink-FILLED control, so its ground is `ink_fill` — the
    # fill meaning of `0xFF1A1917` — and everything on it takes the `on_ink`
    # family, which inverts with the mode instead of following it. An unchosen
    # tile is an ordinary card with ordinary ink on it.
    #
    # `on_ink_count` is right by value and narrow by name: it is the only token
    # carrying `0x99FBFAF8`, and its dark twin `0x991A1917` is exactly what a
    # 60%-alpha label on an inverted fill wants. The name says "a count inside a
    # selected chip"; this is the sub line inside a selected tile.
    background = if chosen?, do: Palette.ink_fill(), else: Palette.card()
    shadow = if chosen?, do: "0 12 24 -14 #E61A1917", else: Kati.Theme.shadow_card_soft()
    ink = if chosen?, do: Palette.on_ink(), else: Palette.ink()
    sub = if chosen?, do: Palette.on_ink_count(), else: Palette.muted()

    ~MOB"""
    <Box weight={1.0}>
      <Column
        fill_width={true}
        background={background}
        corner_radius={20}
        shadow={shadow}
        padding={16}
        on_tap={tap}
      >
        <Row fill_width={true} align="top">
          {Kati.UI.symbol(section.icon, size: 24, color: ink)}
          <Spacer weight={1.0} />
          {Kati.Screens.PickSections.badge(chosen?)}
        </Row>
        <Spacer size={14} />
        <Text
          text={section.label}
          text_size={15}
          font_weight="bold"
          letter_spacing={-0.02}
          text_color={ink}
          max_lines={1}
        />
        <Spacer size={4} />
        <Text text={section.sub} text_size={11.5} text_color={sub} max_lines={1} />
      </Column>
    </Box>
    """
  end

  @doc """
  The 22pt orange check on a chosen tile.

  Not `Kati.Components.MishkaActionIcon`, though it is otherwise exactly what
  that component is — a round box holding one glyph, and the port now takes the
  `size`, `shape: :circle`, `variant: :filled` and `background` this needs.

  What it cannot carry is `offset_x` / `offset_y`. The moduledoc above explains
  why they are load-bearing: the drawing positions the badge absolutely at
  `top:14; right:14`, there is no fill-height reference frame inside a
  wrap-height tile to align an overlay against, so the badge rides in the icon's
  row and is nudged the last 2pt out with an offset that moves what is drawn
  without moving what was measured. `MobBridge.RenderNode` reads those two props
  off the node itself, and the port emits no key it was not given, so a badge
  built by the component lands 2pt in and 2pt down from where the design puts it
  and the tile's whole top row shifts with it.

  `offset_x` / `offset_y` are ordinary Mob box props — they are in the 0.4.20
  baseline under `native/baseline/`, not a Kati fence — so this is the same
  shape of gap `shadow` and `border_color` were, and the same one-line fix:
  another pair of keys in the component's `container/2`, put only when given, so
  that no existing icon's node changes.
  """
  def badge(false), do: ~MOB"<Spacer size={0} />"

  def badge(true) do
    # `0xFFFBFAF8` LEFT AS A LITERAL. `Kati.Theme.Palette` names four meanings
    # for it — the card, a label on an ink fill, the FAB's plus, and a title
    # over artwork — and this is none of them: it is a glyph on a HUE. Orange is
    # `:hue` and does not move with the mode, so a check that followed the mode
    # would turn to ink on a badge that never darkened. The two tokens that keep
    # this value in dark are scoped to a photographic ground (`on_media`) or to
    # the FAB, so neither is honestly this. Left, and reported: the table has no
    # "on a hue fill" row.
    ~MOB"""
    <Box
      width={22}
      height={22}
      offset_x={2}
      offset_y={-2}
      corner_radius={11}
      background={Palette.accent()}
      align="center"
    >
      {Kati.UI.symbol("check", size: 14, color: 0xFFFBFAF8)}
    </Box>
    """
  end

  # The count is computed, not typed: the drawing says "Continue with 2"
  # because two tiles are lit, and tapping a third has to say three or the
  # button is lying about what it will do.
  #
  # The pill is `ink_fill` and its two marks are `on_ink`: a call-to-action
  # filled with ink in light is filled with paper in dark, and what sits on it
  # crosses to the other side of the ramp with it.
  @doc false
  def commit(chosen) do
    label = "Continue with #{MapSet.size(chosen)}"

    ~MOB"""
    <Column fill_width={true}>
      <Box
        fill_width={true}
        height={54}
        corner_radius={27}
        background={Palette.ink_fill()}
        shadow="0 14 28 -12 #D91A1917"
        align="center"
      >
        <Row align="center">
          <Text
            text={label}
            text_size={14.5}
            font_weight="bold"
            text_color={Palette.on_ink()}
            max_lines={1}
          />
          <Spacer size={9} />
          {Kati.UI.symbol("arrow_forward", size: 19, color: Palette.on_ink())}
        </Row>
      </Box>
      <Spacer size={14} />
      <Row fill_width={true} align="center">
        <Spacer weight={1.0} />
        <Text
          text="Import from a backup instead"
          text_size={13}
          font_weight="semibold"
          text_color={Palette.sub()}
          max_lines={1}
        />
        <Spacer weight={1.0} />
      </Row>
    </Column>
    """
  end
end
