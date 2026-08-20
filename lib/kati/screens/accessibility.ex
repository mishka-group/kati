defmodule Kati.Screens.Accessibility do
  @moduledoc """
  Screen 41 — Accessibility, pushed under Settings.

  Built to `.scratch/design/screens/41.html`. The design's caption calls it
  "the spec drawn rather than described", and that is exactly what it is: the
  Up next card rendered at 235% Dynamic Type so the claim "nothing truncates"
  can be checked by looking, the six guarantees as a switch list, and the
  sentence VoiceOver speaks on an episode row printed on ink.

  At that size the buttons are 60pt tall and carry both a glyph and a word —
  the drawing's own demonstration of "icon-only buttons grow labels".

  The **VoiceOver reads** eyebrow takes the muted `#C4BDB3` dash rather than
  the accent one, because it is a quotation rather than a section you act on;
  `Kati.UI.eyebrow/2` always draws the accent dash, so `quiet_eyebrow/1` here
  is the muted variant.

  No dock, so the frame's bottom inset is 40 rather than 132.

  ## The switches are live

  Six guarantees, six real switches: a tap on a row flips that row's state in
  `:spec`, so the thumb slides and the track swaps between ink and `#DCD7CF`.
  The drawn state is the sample's own, so the resting screen is unchanged —
  five on, **Increase contrast** off.

  **Increase contrast** is the one that does more than flip itself, because it
  is the only row whose subtitle names a visible effect: *"Hairlines darken,
  shadows drop"*. Turning it on darkens this screen's rules and takes the lift
  off its cards, which is the row keeping its own promise. Nothing else here
  claims a consequence this screen can show — **Dynamic Type** in particular
  is deliberately inert, see `toggle/1`.
  """
  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.Accessibility.Sample
  alias Kati.Components.MishkaSeparator
  alias Kati.Components.MishkaThemeIcon
  alias Kati.UI

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :spec, Sample.spec())

  @doc false
  def content(assigns) do
    spec = assigns.spec
    contrast? = Kati.Screens.Accessibility.contrast?(spec)

    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={40}>
        {Kati.Screens.Accessibility.header(contrast?)}
        {Kati.Screens.Accessibility.title(spec)}
        {Kati.Screens.Accessibility.up_next(spec, contrast?)}
        {Kati.Screens.Accessibility.note(spec)}
        {UI.eyebrow("Built in")}
        {Kati.Screens.Accessibility.built_in(spec, contrast?)}
        {Kati.Screens.Accessibility.quiet_eyebrow("VoiceOver reads")}
        {Kati.Screens.Accessibility.voiceover(spec)}
      </Column>
    </Scroll>
    """
  end

  @doc """
  Whether **Increase contrast** is currently switched on.

  Read off the row rather than kept in a second assign: the switch list is the
  state, and a copy of it would be one more thing to keep in step. The title
  is the design's own label, matched here rather than an index so reordering
  the guarantees cannot silently move the effect to another row.
  """
  @spec contrast?(map()) :: boolean()
  def contrast?(spec) do
    Enum.any?(spec.built_in, fn row -> row.title == "Increase contrast" and row.toggle end)
  end

  @doc """
  The shadow a card keeps, or none once contrast is on.

  `nil` rather than a zeroed shadow string: the bridge's `shadowLayers/1`
  reads `props["shadow"] as? String` and returns null for anything else, so a
  nil prop is an absent shadow rather than a malformed one that gets parsed
  and dropped layer by layer.
  """
  @spec lift(String.t(), boolean()) :: String.t() | nil
  def lift(shadow, false), do: shadow
  def lift(_shadow, true), do: nil

  # 44pt reserves the row the back pill floats in — the pill is drawn by
  # Kati.Screens.Pushed — so the overflow disc sits opposite it.
  @doc false
  def header(contrast?) do
    shadow = Kati.Screens.Accessibility.lift(Kati.Theme.shadow_button(), contrast?)

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} height={44} align="center">
        <Spacer weight={1.0} />
        <Box
          width={44}
          height={44}
          corner_radius={22}
          background={Kati.Theme.card(:light)}
          shadow={shadow}
          align="center"
        >
          {Kati.UI.symbol("more_horiz", size: 21)}
        </Box>
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc false
  def title(spec) do
    ~MOB"""
    <Column fill_width={true}>
      <Text text="Accessibility" text_size={28} font_weight="bold" letter_spacing={-0.03} text_color={:on_surface} />
      <Spacer size={5} />
      <Text text={spec.subtitle} font_family="mono" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
      <Spacer size={20} />
    </Column>
    """
  end

  @doc "The muted eyebrow: the design's `#C4BDB3` dash instead of the accent."
  def quiet_eyebrow(label) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        <Box width={13} height={2} corner_radius={1} background={0xFFC4BDB3} />
        <Spacer size={9} />
        <Text
          text={String.upcase(label)}
          font_family="mono"
          text_size={10.5}
          letter_spacing={0.16}
          text_color={0xFFA0998F}
          max_lines={1}
        />
      </Row>
      <Spacer size={11} />
    </Column>
    """
  end

  # No max_lines anywhere in this card: the whole demonstration is that text
  # wraps and the card grows rather than the words being cut.
  @doc false
  def up_next(spec, contrast?) do
    u = spec.up_next
    shadow = Kati.Screens.Accessibility.lift(Kati.Theme.shadow_card_soft(), contrast?)

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Kati.Theme.card(:light)}
        corner_radius={22}
        shadow={shadow}
        padding={18}
      >
        <Text
          text={String.upcase(u.label)}
          font_family="mono"
          text_size={12}
          letter_spacing={0.16}
          text_color={0xFFA0998F}
        />
        <Spacer size={12} />
        <Text
          text={u.title}
          text_size={30}
          font_weight="bold"
          letter_spacing={-0.02}
          line_height={1.2}
          text_color={:on_surface}
        />
        <Spacer size={10} />
        <Text text={u.lines} text_size={22} line_height={1.35} text_color={0xFF5C574F} />
        <Spacer size={18} />
        <Box fill_width={true} height={60} corner_radius={30} background={Kati.Theme.ink()} align="center">
          <Row align="center">
            {Kati.UI.symbol("play_arrow", size: 26, color: 0xFFFBFAF8, fill: true)}
            <Spacer size={10} />
            <Text text={u.resume} text_size={19} font_weight="bold" text_color={0xFFFBFAF8} />
          </Row>
        </Box>
        <Spacer size={10} />
        <Box fill_width={true} height={60} corner_radius={30} background={0xFFEFECE7} align="center">
          <Row align="center">
            {Kati.UI.symbol("check", size: 24)}
            <Spacer size={10} />
            <Text text={u.mark} text_size={19} font_weight="bold" text_color={:on_surface} />
          </Row>
        </Box>
      </Column>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def note(spec) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} background={0xFFFBF1DE} corner_radius={18} padding={15} align="top">
        {Kati.UI.symbol("info", size: 18, color: 0xFFC98A3E)}
        <Spacer size={11} />
        <Text
          text={spec.note}
          text_size={12.5}
          line_height={1.55}
          text_color={0xFF4A4238}
          weight={1.0}
        />
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def built_in(spec, contrast?) do
    rows = spec.built_in
    last = length(rows) - 1
    shadow = Kati.Screens.Accessibility.lift(Kati.Theme.shadow_card_soft(), contrast?)

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Kati.Theme.card(:light)}
        corner_radius={20}
        shadow={shadow}
        padding_left={15}
        padding_right={15}
        padding_top={4}
        padding_bottom={4}
      >
        {rows
         |> Enum.with_index()
         |> Enum.map(fn {r, i} -> Kati.Screens.Accessibility.row(r, i, i < last, contrast?) end)}
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  # The tap sits on the row rather than on the 46x28 switch, and that is this
  # screen keeping its own fourth promise: a switch alone is under 44x44, the
  # row is 56 tall and full width. Nothing about the resting drawing changes —
  # Compose's `clickable` paints only on press.
  #
  # The index rather than the title, following `Kati.Screens.Widgets`: the tag
  # has to survive a round trip through `String.to_atom/1`, and an index is the
  # one form that always does.
  @doc false
  def row(row, i, rule?, contrast?) do
    tap = {self(), String.to_atom("switch_" <> Integer.to_string(i))}

    ~MOB"""
    <Column fill_width={true} on_tap={tap}>
      <Row fill_width={true} align="center" padding_top={13} padding_bottom={13}>
        {Kati.Screens.Accessibility.icon_tile(row.icon)}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text text={row.title} text_size={13.5} font_weight="semibold" text_color={:on_surface} max_lines={1} />
          <Spacer size={3} />
          <Text text={row.sub} text_size={11.5} text_color={0xFF8A8479} max_lines={1} />
        </Column>
        <Spacer size={13} />
        {Kati.Screens.Accessibility.toggle(row.toggle)}
      </Row>
      {Kati.Screens.Accessibility.hairline(rule?, contrast?)}
    </Column>
    """
  end

  @doc """
  The 30x30 paper tile a guarantee row leads with.

  `Kati.Components.MishkaThemeIcon` is "a themed container around exactly one
  icon", which is what this is, so the container is its rather than one more
  hand-rolled `Box` — the same swap `Kati.UI.SettingsList.icon_tile/1` makes
  for the settings rows, for the same reason and with the same numbers: 30dp
  square, radius 9, `#EFECE7` paper, glyph at 17 in `#5C574F`.

  The glyph is a child rather than the `icon` prop because the `icon` shorthand
  builds a `Text` with no `font_family`, so the Material Symbols **ligature**
  `"volume_up"` would be typeset as the word. `Kati.UI.symbol/2` keeps the
  symbols face and keeps `Kati.Icons.glyph!/1`'s raise for a name outside the
  shipped subset.

  With children and no `id`, `theme_icon/2` returns
  `%{type: :box, props: %{width: 30, height: 30, align: :center,
  corner_radius: 9, background: 0xFFEFECE7}, children: [glyph]}` — node for
  node what this row wrote by hand, so nothing moves. `align: :center` and
  `align="center"` reach the bridge as the same string.
  """
  def icon_tile(name) do
    MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: 0xFFEFECE7, size: 30, radius: 9},
      [Kati.UI.symbol(name, size: 17, color: 0xFF5C574F)]
    )
  end

  @doc """
  The design's own switch, drawn rather than delegated.

  46x28 with a 22pt thumb and a 3pt inset. The 40pt inner row produces that
  inset without mixing `padding` and an explicit `width` on one node, which in
  this bridge inflates the node instead of insetting it.

  `Kati.Components.MishkaSwitch` is the component for this and it cannot be
  used: it wraps Mob's `Toggle`, which is Compose's Material `Switch` at
  Material's own 52x32 metrics with a thumb that grows when on. No prop
  reshapes it to 46x28 with a fixed 22pt thumb.

  The switch draws state; `row/4` carries the tap. Flipping one moves the
  thumb and swaps the track — every row's guaranteed consequence — and for
  **Increase contrast** the screen's hairlines and shadows follow as well.

  **Dynamic Type** is the one guarantee that stays a switch and nothing more.
  Its honest consequence would be re-rendering the Up next card at ordinary
  size, but the drawing gives no ordinary size to fall back to: 235% of a 30pt
  title is not the 17pt title the rest of the app uses, so any scale factor
  here would be invented rather than drawn. A switch that flips is honest; a
  card rendered at a made-up size is not.
  """
  def toggle(on?) do
    track = if on?, do: Kati.Theme.ink(), else: 0xFFDCD7CF

    ~MOB"""
    <Box width={46} height={28} corner_radius={14} background={track} align="center">
      <Row width={40} align="center">
        {Kati.Screens.Accessibility.thumb_lead(on?)}
        <Box width={22} height={22} corner_radius={11} background={0xFFFBFAF8} shadow="0 1 3 0 #4D1A1917" />
        {Kati.Screens.Accessibility.thumb_trail(on?)}
      </Row>
    </Box>
    """
  end

  @doc false
  def thumb_lead(true), do: ~MOB"<Spacer weight={1.0} />"
  def thumb_lead(false), do: ~MOB"<Spacer size={0} />"

  @doc false
  def thumb_trail(true), do: ~MOB"<Spacer size={0} />"
  def thumb_trail(false), do: ~MOB"<Spacer weight={1.0} />"

  @doc false
  def voiceover(spec) do
    v = spec.voiceover

    ~MOB"""
    <Column fill_width={true} background={Kati.Theme.ink()} corner_radius={20} padding={17}>
      <Text
        text={v.label}
        font_family="mono"
        text_size={10}
        letter_spacing={0.14}
        text_color={0xFF6A6560}
        max_lines={1}
      />
      <Spacer size={10} />
      <Text text={v.reads} text_size={13.5} line_height={1.6} text_color={0xFFF5F2EE} />
    </Column>
    """
  end

  # 0x12 is the drawing's 7% rule. 0x38 is the darkened one the Increase
  # contrast row promises — the same ink, roughly tripled in weight, rather
  # than a second colour.
  #
  # The rule itself is `Kati.Components.MishkaSeparator`, which is what a
  # 1px hairline between rows IS. Its plain variant is a `<Divider>`, and the
  # bridge's `MobDivider` renders Compose's `HorizontalDivider(thickness, color)`
  # — which is defined as `Box(modifier.fillMaxWidth().height(thickness)
  # .background(color))`, the same three modifiers this wrote by hand. Both
  # colours are passed as ARGB ints, so the drawing's own alphas survive:
  # `color` is in the renderer's `@color_props` whitelist and an integer is
  # handed to `colorProp` untouched.
  @doc false
  def hairline(false, _contrast?), do: ~MOB"<Spacer size={0} />"

  def hairline(true, contrast?) do
    color = if contrast?, do: 0x381A1917, else: 0x121A1917

    MishkaSeparator.separator(color: color, thickness: 1)
  end

  @doc """
  One clause for all six switches: the tag carries the row's index.

  A seventh guarantee would be a line in `Kati.Accessibility.Sample` and
  nothing here — the same rule `Kati.Screens.Library`'s chips follow.
  """
  @impl true
  def handle_tap(tag, socket) do
    spec = socket.assigns.spec

    case Atom.to_string(tag) do
      "switch_" <> i ->
        rows =
          List.update_at(spec.built_in, String.to_integer(i), fn row ->
            %{row | toggle: not row.toggle}
          end)

        {:noreply, Mob.Socket.assign(socket, :spec, %{spec | built_in: rows})}

      _ ->
        {:noreply, socket}
    end
  end
end
