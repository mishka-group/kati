defmodule Kati.Screens.Subscriptions do
  @moduledoc """
  Screen 23 — Subscriptions, pushed under Stats.

  Built to `.scratch/design/screens/23.html`. The money section, and the
  drawing says plainly why it belongs in this app rather than a finance one:
  *"cost per watched hour is the one subscription number no finance app can
  compute for you."* The price comes from a bank; the hours come from the
  Screen shelf; only here do they meet.

  So the rate is the point of the list, and it is coloured rather than merely
  printed — green at £0.21/h, `#B4553C` at £2.33/h. That red is the same token
  `Kati.Theme.red/0` uses for an error, which is the design being blunt: an
  hour of television costing more than a cinema ticket is a fault, not a
  statistic.

  Details taken literally from the export:

    * The back pill shares its row with a `more_horiz` disc, so unlike screens
      15 and 22 that row is 44 tall rather than 42 — the disc sets the height.
    * "Worth a look" gets the grey dash (`Kati.UI.Eyebrow.quiet/1`): a
      suggestion the app is offering is not new and not now.
    * The paused row drops its rate entirely and greys both its lines. It is
      the one row where the right-hand column is a single value.

  The suggestion's body is drawn with `6 hours` and `1 title` in bold inside a
  wrapping paragraph. Mob's `Text` carries one weight, and a paragraph
  assembled from separate runs breaks at the wrong words, so it renders as one
  run — recorded here because it is a real loss against the drawing, not an
  oversight.

  No dock on a pushed screen, so the frame ends at 40 rather than 132.

  ## What the two buttons do, and what they deliberately do not

  The suggestion card is the only thing on this screen that can move, and it
  moves in exactly the two directions the drawing's own buttons name:

    * **Dismiss** retires the suggestion — the card *and* the "Worth a look"
      eyebrow above it, since an eyebrow labelling nothing is worse than no
      eyebrow. Nothing takes their place.
    * **Remind me 23 Aug** marks the offer as taken: the primary button changes
      into the card's own secondary treatment (`#EFECE7` on `#5C574F` — the
      Dismiss chip's two colours, already in this row). Tapping again cancels.

  The label does not change and no tick appears, because the drawing has no
  "reminder set" wording and inventing one would be inventing a screen. The
  weight change is therefore the whole signal, and that is a real loss against
  a drawing that never had to show this state.

  **Nothing is actually scheduled.** `Kati.Notifications.Scheduler` is a
  planned child of `Kati.Supervisor` (#59) and is not built, so `:remind`
  records that you asked and nothing more. When the scheduler lands this is
  where it gets called; until then the button must not claim otherwise.

  Both states start off, so the resting screen is the drawing exactly.
  """
  use Kati.Screens.Pushed, back: "Stats"

  alias Kati.Subscriptions.Sample
  alias Kati.Theme.Palette
  alias Kati.UI

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, suggestion: true, reminded: false)

  @doc false
  def content(assigns) do
    shown? = assigns.suggestion
    reminded? = assigns.reminded

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {Kati.Screens.Subscriptions.back_row()}
        {Kati.Screens.Subscriptions.title()}
        {Kati.Screens.Subscriptions.monthly()}
        {UI.eyebrow("Services")}
        {Kati.Screens.Subscriptions.services()}
        {Kati.Screens.Subscriptions.suggestion(shown?, reminded?)}
      </Column>
    </Scroll>
    """
  end

  # The back pill itself is drawn by Kati.Screens.Pushed as floating chrome;
  # this row reserves its height and carries the overflow disc opposite it.
  @doc false
  def back_row do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Spacer weight={1.0} />
        {Kati.Screens.Subscriptions.disc()}
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  The 44pt `more_horiz` disc that shares the back pill's row.

  `Kati.Components.MishkaActionIcon`, which is what a round tap target holding
  one glyph is. It could not be until the port grew a `shadow` prop: this disc
  floats off paper on `Kati.Theme.shadow_button()`, and a disc without its
  shadow is a flat patch rather than a control sitting above the page.

  **The pixels are the same node.** The port builds

      <Box width={44} height={44} align={:center} corner_radius={22.0}
           background=… shadow=… on_tap=…><Row>{glyph}</Row></Box>

  against the `<Box width={44} height={44} background corner_radius={22} shadow
  align="center" on_tap>` this was, prop for prop: `shape: :circle` resolves to
  an exact `size / 2` and 44 gives the drawing's 22, `variant: :filled` is what
  lets `background` through (the port paints `:transparent` on the default
  `:plain`), and `align={:center}` serialises to the same `"center"` string.
  The added `Row` carries no props, so it takes no modifier and hugs its one
  child — the glyph measures and centres exactly where it did.
  """
  def disc do
    Kati.Components.MishkaActionIcon.action_icon(
      [
        size: 44,
        shape: :circle,
        variant: :filled,
        background: Palette.card(),
        shadow: Kati.Theme.shadow_button(),
        on_tap: {self(), :open_menu}
      ],
      [Kati.UI.symbol("more_horiz", size: 21)]
    )
  end

  @doc false
  def title do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text="Subscriptions"
        text_size={28}
        font_weight="bold"
        letter_spacing={-0.03}
        text_color={:on_surface}
      />
      <Spacer size={5} />
      <Text
        text={Kati.Subscriptions.Sample.active_line()}
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
  def monthly do
    m = Sample.monthly()

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
          text={String.upcase(m.label)}
          font_family="mono"
          text_size={10.5}
          letter_spacing={0.16}
          text_color={Palette.cream_meta()}
        />
        <Spacer size={7} />
        <Text
          text={m.total}
          text_size={36}
          font_weight="extrabold"
          letter_spacing={-0.04}
          text_color={:on_surface}
        />
        <Spacer size={12} />
        <Row fill_width={true} align="center">
          {Kati.UI.symbol("trending_up", size: 15, color: Palette.red())}
          <Spacer size={7} />
          <Text
            text={m.change_lead}
            text_size={12.5}
            text_color={Palette.cream_sub()}
            max_lines={1}
          />
          <Spacer size={4} />
          <Text
            text={m.change_amount}
            text_size={12.5}
            font_weight="semibold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={4} />
          <Text
            text={m.change_rest}
            text_size={12.5}
            text_color={Palette.cream_sub()}
            max_lines={1}
          />
          <Spacer weight={1.0} />
        </Row>
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def services do
    rows = Sample.services()
    last = length(rows) - 1

    children =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, i} -> service_row(row, i < last) end)

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={15}
        padding_right={15}
        padding_top={4}
        padding_bottom={4}
      >
        {children}
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def service_row(row, rule?) do
    paused? = Map.get(row, :paused, false)
    name_color = if paused?, do: Palette.sub(), else: Palette.ink()
    line_color = if paused?, do: Palette.tertiary(), else: Palette.sub()

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={14} padding_bottom={14}>
        {Kati.Screens.Subscriptions.badge(row.badge)}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text
            text={row.name}
            text_size={13.5}
            font_weight="semibold"
            text_color={name_color}
            max_lines={1}
          />
          <Spacer size={3} />
          <Text text={row.line} text_size={11.5} text_color={line_color} max_lines={1} />
        </Column>
        <Spacer size={13} />
        {Kati.Screens.Subscriptions.money(row, paused?)}
      </Row>
      {Kati.Screens.Subscriptions.hairline(rule?)}
    </Column>
    """
  end

  @doc """
  The service's letter on its 32pt paper tile.

  `Kati.Components.MishkaAvatar` with `shape: :rounded`, which is what this is:
  an avatar whose fallback is the initial, for services that ship no logo. The
  port's `:rounded` radius is a flat 10 at any size, which is the drawing's own
  radius here — so `size: 32, shape: :rounded` reproduces the tile exactly and
  nothing is passed twice.

  The letter goes in as a **child** rather than as `initials`, and that is the
  reason the pixels are unchanged: `initials` is drawn by the component's own
  `Text`, which carries no `font_family`, and this badge is mono. A child
  replaces that `Text` wholesale, so the drawing's `font_family="mono"` at 13
  survives. An `initials_font_family` prop upstream would let this be one line
  instead of two; until there is one, the child is what keeps the mono.
  """
  def badge(letter) do
    glyph = ~MOB"""
    <Text text={letter} font_family="mono" text_size={13} text_color={:on_surface} max_lines={1} />
    """

    Kati.Components.MishkaAvatar.avatar(
      [size: 32, shape: :rounded, background: Palette.paper()],
      [glyph]
    )
  end

  # A paused service has one value on the right, not two: it has no rate,
  # because £5.00 buying nothing is not a price per hour. Two clauses rather
  # than a nil-rate branch, so the shapes stay honestly different.
  @doc false
  def money(row, true) do
    ~MOB"""
    <Text
      text={row.price}
      font_family="mono"
      text_size={12}
      text_color={Palette.tertiary()}
      max_lines={1}
    />
    """
  end

  # 46 wide, not hugging. `text_align="right"` makes a Text fillMaxWidth on
  # this bridge — the defect that flattened screen 08's rating card — so it
  # only behaves inside a column of declared width. 46 clears the widest value
  # the drawing carries (`£13.99` at mono 12).
  def money(row, false) do
    ~MOB"""
    <Column width={46}>
      <Text
        text={row.price}
        font_family="mono"
        text_size={12}
        font_weight="medium"
        text_color={:on_surface}
        text_align="right"
        max_lines={1}
      />
      <Spacer size={3} />
      <Text
        text={row.rate}
        font_family="mono"
        text_size={10}
        text_color={row.rate_tone}
        text_align="right"
        max_lines={1}
      />
    </Column>
    """
  end

  # The eyebrow lives in here rather than in `content/1` so that Dismiss takes
  # the label away with the card it labels.
  #
  # A two-element LIST, not a wrapping Column. `content/1` interpolates it into
  # the same slot the eyebrow and the card occupied separately, so the tree it
  # produces at rest is the one this screen produced before the buttons worked —
  # identical, not merely equivalent. A wrapper Column would almost certainly
  # have laid out the same; "almost certainly" is not what the frame comparison
  # is measured in.
  @doc false
  def suggestion(false, _reminded?), do: ~MOB"<Spacer size={0} />"

  def suggestion(true, reminded?) do
    [Kati.UI.Eyebrow.quiet("Worth a look"), Kati.Screens.Subscriptions.advice(reminded?)]
  end

  @doc false
  def advice(reminded?) do
    s = Sample.suggestion()

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={17}
    >
      <Row fill_width={true} align="top">
        {Kati.UI.symbol("lightbulb", size: 19, color: Palette.accent())}
        <Spacer size={11} />
        <Text
          text={s.body}
          text_size={13}
          line_height={1.55}
          text_color={Palette.cream_body()}
          weight={1.0}
        />
      </Row>
      <Spacer size={15} />
      <Row fill_width={true} align="center">
        {Kati.Screens.Subscriptions.confirm(s.confirm, reminded?)}
        <Spacer size={9} />
        {Kati.Screens.Subscriptions.dismiss(s.dismiss)}
      </Row>
    </Column>
    """
  end

  # Two clauses, not a pair of conditional colours, because these are the card's
  # two drawn button treatments and not a spectrum: ink on paper for the primary,
  # `#EFECE7` on `#5C574F` for the secondary. "Already asked for" is the primary
  # wearing the secondary's clothes — no new colour enters the card.
  #
  # The primary is `ink_fill` / `on_ink`, which is the pair screen 28 inverts:
  # ink filled with paper in light, paper filled with ink in dark. It is NOT
  # `ink` / `card`, whose light values are the same two numbers and whose dark
  # values would leave this button ink-on-ink.
  @doc false
  def confirm(label, false), do: confirm_button(label, Palette.ink_fill(), Palette.on_ink())
  def confirm(label, true), do: confirm_button(label, Palette.paper(), Palette.ink_soft())

  @doc """
  The primary button of the suggestion card, sharing its row with `dismiss/1`.

  This is the closest thing on the screen to `Kati.Components.MishkaChip`, and
  the fit is closer than it looks: the two treatments `confirm/2` chooses between
  are precisely a chip's checked and unchecked fills, and `checked: reminded?`
  with `color` / `text_color` for the armed pair and `unchecked_color` /
  `unchecked_text_color` for the loud one says exactly what the two clauses say.
  Since the chip took `height`, `padding_x` / `padding_y`, `corner_radius`,
  `text_size`, `font_weight` and `max_lines`, every number here is a prop too.

  It still cannot be one. **The chip hardcodes `fill_width={false}`** — the
  comment beside it says so, it is what makes the "content-sized" claim true —
  and offers no prop to override it, where `Kati.Components.MishkaPill` does.
  This button takes its width from the `weight={1.0}` on the Box around it, and
  a chip inside that Box would hug its label and sit at the leading edge with
  the trough of the row showing beside it. `width` is no way out either: the
  width is whatever the row has left after the Dismiss chip, which is not a
  number this screen knows.

  So: a `fill_width` prop on the chip, defaulting to `false`, is what this needs.
  """
  def confirm_button(label, background, foreground) do
    tap = {self(), :remind}

    ~MOB"""
    <Box weight={1.0}>
      <Row
        fill_width={true}
        height={40}
        corner_radius={20}
        background={background}
        align="center"
        on_tap={tap}
      >
        <Spacer weight={1.0} />
        <Text
          text={label}
          text_size={12.5}
          font_weight="semibold"
          text_color={foreground}
          max_lines={1}
        />
        <Spacer weight={1.0} />
      </Row>
    </Box>
    """
  end

  @doc """
  The secondary button beside `confirm_button/3` — `#EFECE7` on `#5C574F`.

  Left hand-rolled, and this one is not blocked by a missing prop.
  `Kati.Components.MishkaPill` would reproduce it exactly: a hugging `Box` at
  `height: 40, padding: 0, padding_left: 15, padding_right: 15,
  corner_radius: 20, align: :center` around one `Text`, with `on_tap` on the
  body, which is this node plus the two prop-less `Row`s the pill wraps content
  in. Nothing would move.

  It is not adopted because of what it would *say*. The pill port's own opening
  section exists to stop exactly this: *"a Chip is selected, a Pill is removed"* —
  a pill is a token you can take out of a set, and its remove affordance is the
  ✕ it draws, not its label. This is a one-shot action button whose whole content
  is the verb. Calling it a pill because the box matches would spend the one
  distinction that section is defending.

  What the set actually lacks is a **Button**: there is no headless button among
  the 73, only `mishka_close_button`, which is
  `Kati.Components.MishkaActionIcon` with a fixed ✕. A button taking `label`,
  `height`, `padding_x`, `corner_radius`, `background`, `color`, `text_size`,
  `font_weight` and `fill_width` would take this, `confirm_button/3` above, and
  screen 28's hero call-to-action, all three of which are currently three
  hand-rolled copies of the same rounded row.
  """
  def dismiss(label) do
    tap = {self(), :dismiss}

    ~MOB"""
    <Row
      height={40}
      corner_radius={20}
      background={Palette.paper()}
      padding_left={15}
      padding_right={15}
      align="center"
      on_tap={tap}
    >
      <Text
        text={label}
        text_size={12.5}
        font_weight="semibold"
        text_color={Palette.ink_soft()}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc """
  The `rgba(26,25,23,.07)` rule between two services, absent after the last.

  ## `Kati.Components.MishkaSeparator`, and only because of `render: :box`

  A rule between rows is exactly what a separator is, and the port's API always
  fitted — `separator(color: Palette.hairline())` at its default `thickness: 1` is this
  line. What did not fit was what it *drew*. On its default `render: :divider`
  the port emits `<Divider>`, which `MobBridge` hands to Material 3's
  `HorizontalDivider`, and in 1.2.0 that composable is not a filled box:

      Canvas(modifier.fillMaxWidth().height(thickness)) {
        drawLine(color, strokeWidth = thickness.toPx(), …)
      }

  `height(1.dp)` **rounds** to whole device pixels while `thickness.toPx()`
  does not, and the capture device runs at 2.6875x. So the node is 3px tall and
  the antialiased stroke covers 2.6875 of them: the last row lands at 69%
  coverage instead of 100%. On this screen's `#FBFAF8` card that is about five
  levels of grey along the bottom edge of every rule — under
  `bin/diff_frames.py`'s tolerance of 12, and still a difference, and a
  difference is not what this rule is. It vanishes at any density where 1dp is a
  whole number of pixels, which is why it was invisible in a unit test.

  `render: :box` is the way out, and it is why the default is not taken here:
  the port swaps the Material stroke for the background-filled `Box` it has
  always used on its vertical axis, and a filled rect has no antialiased edge,
  so all three device-pixel rows carry the full colour.

  **The pixels are the same node.** `separator(color: Palette.hairline(), render: :box)`
  builds

      <Box fill_width={true} height={1} background={Palette.hairline()}>
        <Spacer size={1} />
      </Box>

  where this was the same `Box` with no child. The `Spacer` is the port's iOS
  height workaround (`MobBox` drops a childless Box's height there); on Android
  `MobSpacer` is `Spacer(modifier.size(1.dp))` — no background, nothing drawn —
  and the Box's own `height(1.dp)` is applied after padding and pins the box, so
  a 1pt child cannot grow it. It adds an invisible node and no pixel.
  """
  def hairline(false), do: ~MOB"<Spacer size={0} />"

  def hairline(true),
    do: Kati.Components.MishkaSeparator.separator(color: Palette.hairline(), render: :box)

  # `:remind` toggles rather than latches, so the one control that arms it can
  # also cancel it. There is nowhere else on this screen to cancel from, and a
  # button that can only be pressed once is a button that lies the second time.
  @impl true
  def handle_tap(:remind, socket) do
    {:noreply, Mob.Socket.assign(socket, :reminded, not socket.assigns.reminded)}
  end

  def handle_tap(:dismiss, socket) do
    {:noreply, Mob.Socket.assign(socket, :suggestion, false)}
  end

  # `:open_menu` — the `more_horiz` disc — lands here on purpose.
  #
  # 23.html contains exactly one `more_horiz` and no menu, sheet or popover
  # anywhere in the export, so there is nothing to open that would not be
  # invented. Left tappable rather than untapped: the drawing draws a control,
  # and stripping `on_tap` would take its press feedback away too. It is inert
  # and silent — the catch-all, not a raise — until a sheet is drawn.
  def handle_tap(_tag, socket), do: {:noreply, socket}
end
