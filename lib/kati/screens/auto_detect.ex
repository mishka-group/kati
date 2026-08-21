defmodule Kati.Screens.AutoDetect do
  @moduledoc """
  Screen 36 — Auto-detect, pushed under Settings.

  Built to `.scratch/design/screens/36.html`. Manual ticking stays the
  default; this is the opt-in that removes it, and the screen is arranged as
  the argument for trusting it: the cream banner says how many episodes it has
  already ticked, Now playing shows the rule being applied live, and the last
  card is the one ambiguous match it refused to guess at.

  Rules carries the grey dash rather than the orange one — it qualifies the
  sources above it rather than announcing anything new.

  The "Needs a decision" card is the design's real point. An unsure match
  becomes a question instead of a tick, because a wrong tick pollutes a watch
  history nobody audits.

  No dock — pushed screen — so the frame closes at 40, not 132.
  """
  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.Components.MishkaProgress
  alias Kati.Components.MishkaToggle
  alias Kati.Settings.DetectSample, as: Sample
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @impl true
  def load(socket) do
    Mob.Socket.assign(socket, :detect, %{
      sources_line: Sample.sources_line(),
      banner: Sample.banner(),
      now_playing: Sample.now_playing(),
      sources: Sample.sources(),
      rules: Sample.rules(),
      decision: Sample.decision()
    })
  end

  @doc false
  def content(assigns) do
    d = assigns.detect

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {SettingsList.chrome("more_horiz")}
        {SettingsList.title("Auto-detect", d.sources_line)}
        {Kati.Screens.AutoDetect.banner(d.banner)}
        {UI.eyebrow("Now playing")}
        {Kati.Screens.AutoDetect.now_playing(d.now_playing)}
        {UI.eyebrow("Sources")}
        {Kati.Screens.AutoDetect.group(d.sources)}
        {SettingsList.eyebrow_muted("Rules")}
        {Kati.Screens.AutoDetect.group(d.rules)}
        {UI.eyebrow("Needs a decision")}
        {Kati.Screens.AutoDetect.decision(d.decision)}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def banner(b) do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.cream()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={18}
        align="center"
      >
        {Kati.UI.symbol("sensors", size: 24, color: Palette.gold_icon())}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text
            text={b.title}
            text_size={14.5}
            font_weight="bold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={4} />
          <Text
            text={b.meta}
            font_family="mono"
            text_size={10.5}
            text_color={Palette.cream_meta()}
            max_lines={1}
          />
        </Column>
        <Spacer size={12} />
        {SettingsList.switch(b.on)}
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The Now playing card, with the elapsed bar drawn by
  `Kati.Components.MishkaProgress` in its `render={:box}` mode.

  The three things this bar needs were all things `<Progress>` has no prop for
  — a `#E7E3DC` track (`MobProgress` passes `color` and nothing else, so the
  groove stays whatever `ProgressIndicatorDefaults.linearTrackColor` resolves
  to), a 5pt thickness on the track *and* the fill, and a 3pt radius on both.
  `render={:box}` draws the same two weighted cells this file used to write by
  hand, from the same numbers, so the component is now the one that owns them.

  ## Why the pixels do not move

  Serialising both trees and diffing them key by key, every node and every prop
  matches — the track `Box` (`fill_width`, `height: 5`, `corner_radius: 3`,
  `background:` the track token, `0xFFE7E3DC` in light), the `fill_width` `Row`
  inside it, the fill `Box`
  (`weight: 0.74`, `height: 5`, `corner_radius: 3`, `background:` ink) and the
  remainder `<Spacer weight={0.26} />`. One node differs: the component appends
  a `<Spacer size={5} />` as a second child of the track. It is the iOS
  workaround its moduledoc documents — `MobBox` drops a childless Box's height
  — and on this bridge it is a 4-prop-less, background-less 5x5 Spacer laid at
  the track's `Alignment.TopStart` inside a Box that already carries
  `fillMaxWidth().height(5.dp)`, so it paints nothing and cannot resize
  anything.

  `max: 1` rather than `value: progress * 100`: `fraction/1` is then
  `(v - 0) / 1`, which returns the identical float. Scaling by 100 and back
  does not — `0.62 * 100 / 100` is `0.6200000000000001`.

  ## Both ends were checked

  The hand-rolled version was one sample value away from killing the activity:
  at `progress: 0.0` it emitted `<Box weight={0.0}>` and at `1.0` a
  `<Spacer weight={0.0} />`, and Compose throws on either — *"invalid weight
  0.0; must be greater than zero"*. The component omits the node instead: at
  `0.0` there is no fill and the remainder carries `weight: 1.0`; at `1.0`
  there is no remainder and the fill carries `weight: 1.0`. Neither end emits a
  zero. Today's sample is `0.74`, so this is a latent crash removed rather than
  a live one fixed.
  """
  def now_playing(n) do
    bar =
      MishkaProgress.progress(
        value: n.progress,
        max: 1,
        render: :box,
        height: 5,
        corner_radius: 3,
        track_color: Palette.track(),
        color: Palette.ink()
      )

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={15}
      >
        <Row fill_width={true} align="center">
          {Kati.Screens.AutoDetect.poster(n.seed, 44, 62, 9)}
          <Spacer size={13} />
          <Column weight={1.0}>
            <Text
              text={n.title}
              text_size={14}
              font_weight="bold"
              text_color={:on_surface}
              max_lines={1}
            />
            <Spacer size={4} />
            <Text
              text={n.meta}
              font_family="mono"
              text_size={10.5}
              text_color={Palette.muted()}
              max_lines={1}
            />
          </Column>
          <Spacer size={12} />
          {SettingsList.status_pill(n.status, Palette.green_text(), Palette.green_wash())}
        </Row>
        <Spacer size={14} />
        {bar}
        <Spacer size={9} />
        <Row fill_width={true} align="center">
          <Text
            text={n.elapsed}
            font_family="mono"
            text_size={10.5}
            text_color={Palette.muted()}
            max_lines={1}
          />
          <Spacer weight={1.0} />
          <Text
            text={n.rule}
            font_family="mono"
            text_size={10.5}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Row>
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def poster(seed, w, h, radius) do
    case Kati.Design.Images.poster(seed) do
      nil ->
        ~MOB"""
        <Box width={w} height={h} corner_radius={radius} background={Palette.placeholder()} />
        """

      src ->
        ~MOB"""
        <Image src={src} width={w} height={h} corner_radius={radius} content_mode="fill" />
        """
    end
  end

  @doc false
  def group(rows) do
    last = length(rows) - 1

    body =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, i} -> Kati.Screens.AutoDetect.row(row, i < last) end)

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(body)}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def row(row, rule?) do
    SettingsList.row(
      SettingsList.icon_tile(row.icon),
      SettingsList.body(row.title, row.sub),
      Kati.Screens.AutoDetect.control(row.control),
      padding: 13,
      rule: rule?
    )
  end

  @doc false
  def control(:chevron), do: SettingsList.chevron()
  def control({:switch, on?}), do: SettingsList.switch(on?)
  def control({:pill, label}), do: SettingsList.action_pill(label)

  @doc false
  def decision(d) do
    buttons =
      d.options
      |> Enum.map(fn o -> Kati.Screens.AutoDetect.choice(o, o == d.chosen) end)
      |> Enum.intersperse(Kati.Screens.AutoDetect.choice_gap())

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={15}
    >
      <Row fill_width={true} align="center">
        {Kati.Screens.AutoDetect.poster(d.seed, 36, 51, 7)}
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text text={d.question} text_size={13} font_weight="bold" text_color={:on_surface} />
          <Spacer size={4} />
          <Text text={d.sub} text_size={11.5} text_color={Palette.sub()} max_lines={1} />
        </Column>
      </Row>
      <Spacer size={13} />
      <Row fill_width={true} align="center">
        {buttons}
      </Row>
    </Column>
    """
  end

  @doc false
  def choice_gap, do: ~MOB"<Spacer size={8} />"

  @doc """
  One answer to the ambiguous match: a 34pt pill, ink when it is the chosen one.

  `Kati.Components.MishkaToggle` — "a square-cornered button that looks pushed
  in", except that every dimension it draws is a prop, so the corners are as
  round as the drawing says. It is the component's own documented use: the
  moduledoc's showcase builds a segmented bar out of nothing but these props,
  and three mutually exclusive answers drawn as three separate pressed pills is
  that bar.

  ## Why not the chip, and why not the segmented control

  `Kati.Components.MishkaChip` is the closer name — the sample is a radio set,
  one of `["The series", "The film", "Neither"]` chosen, and the chip's docs
  spell out the radio case. It cannot be used: the chip's root `Box` hardcodes
  `fill_width={false}` with no prop to override it, so a chip always hugs its
  label. These three split the card's width by weight, and a hugging chip leaves
  the row three short pills and a gap.

  `Kati.Components.MishkaSegmentedControl` is the wrong shape. It draws one
  continuous track with the segments inside it, and the drawing has no track at
  all: three separate pills with 8pt of card showing between them. The control
  has `track_padding` but no inter-segment gap, so its segments butt together —
  there is no combination of props that opens 8pt between them.

  ## The numbers

  Padding is applied before height, and the toggle's `padding` default is
  `:space_sm`, so `height: 34` alone would measure 34 plus two paddings.
  `padding: 0` pins the outer 34. `border_width: 0` removes the component's
  default hairline: the bridge draws a border only when `borderColor != null &&
  borderWidth > 0f`, so the `border_color: :border` the component still writes
  paints nothing.

  ## Why the pixels do not move

  The `<Box weight={1.0}>` wrapper is untouched — the toggle exposes no `weight`
  and this is the node that splits the row — so only its child changes, from a
  `Row` to the toggle's `Box`:

      <Box fill_width={true} height={34} corner_radius={17}
           background={bg} align={:center} padding={0}
           border_color={:border} border_width={0}>
        <Text text={label} text_size={11.5} font_weight={:semibold}
              text_color={fg} max_lines={1} />
      </Box>

  against the `<Row fill_width={true} height={34} corner_radius={17}
  background={bg} align="center">` it replaces. Five props are the same five
  values; the three extra ones are the no-ops above.

  `nodeModifier` is one function for every node type, so the background, the
  radius and the height are applied by the same chain either way, and both
  containers fill the weighted slot: the `Row` because `fill_width={true}`, the
  `Box` because fence K-17's `hugs = boolProp(props, "fill_width") == false` is
  false when the prop is true, leaving `m.fillMaxWidth()`.

  What changes is how the label is centred. The `Row` did it with two
  `weight={1.0}` `Spacer`s horizontally and `align="center"` vertically; the
  `Box` does both with `contentAlignment`, since `align: :center` and
  `align="center"` reach the bridge as the same string — `align` is in none of
  the renderer's token whitelists, so an unrecognised atom passes through and
  `:json.encode/1` writes an atom as its own name. A single child centred in a
  box of the same width lands where two equal weights put it.

  The three colour props map one for one onto what the two branches computed:
  `color` and `text_color` are the pressed pair — `Palette.ink_fill/0` under
  `Palette.on_ink/0`, `#1A1917` / `#FBFAF8` in light, the pair screen 28 draws
  for the hero's CTA pill — `background` and `label_color` the idle pair
  (`Palette.paper/0` / `Palette.ink_soft/0`, `#EFECE7` / `#5C574F`), and
  `pressed` picks between them exactly as the `if` did.
  """
  def choice(label, on?) do
    button =
      MishkaToggle.toggle(
        label: label,
        pressed: on?,
        color: Palette.ink_fill(),
        text_color: Palette.on_ink(),
        background: Palette.paper(),
        label_color: Palette.ink_soft(),
        corner_radius: 17,
        height: 34,
        padding: 0,
        border_width: 0,
        fill_width: true,
        align: :center,
        text_size: 11.5,
        font_weight: :semibold,
        max_lines: 1
      )

    ~MOB"""
    <Box weight={1.0}>
      {button}
    </Box>
    """
  end
end
