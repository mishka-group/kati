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
  alias Kati.UI

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, suggestion: true, reminded: false)

  @doc false
  def content(assigns) do
    shown? = assigns.suggestion
    reminded? = assigns.reminded

    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={40}>
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
    tap = {self(), :open_menu}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Spacer weight={1.0} />
        <Box
          width={44}
          height={44}
          background={Kati.Theme.card(:light)}
          corner_radius={22}
          shadow={Kati.Theme.shadow_button()}
          align="center"
          on_tap={tap}
        >
          {Kati.UI.symbol("more_horiz", size: 21)}
        </Box>
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc false
  def title do
    ~MOB"""
    <Column fill_width={true}>
      <Text text="Subscriptions" text_size={28} font_weight="bold" letter_spacing={-0.03} text_color={:on_surface} />
      <Spacer size={5} />
      <Text text={Kati.Subscriptions.Sample.active_line()} font_family="mono" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
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
        background={0xFFFBF1DE}
        corner_radius={24}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={19}
      >
        <Text text={String.upcase(m.label)} font_family="mono" text_size={10.5} letter_spacing={0.16} text_color={0xFFB09A72} />
        <Spacer size={7} />
        <Text text={m.total} text_size={36} font_weight="extrabold" letter_spacing={-0.04} text_color={:on_surface} />
        <Spacer size={12} />
        <Row fill_width={true} align="center">
          {Kati.UI.symbol("trending_up", size: 15, color: 0xFFB4553C)}
          <Spacer size={7} />
          <Text text={m.change_lead} text_size={12.5} text_color={0xFF8A7B60} max_lines={1} />
          <Spacer size={4} />
          <Text text={m.change_amount} text_size={12.5} font_weight="semibold" text_color={:on_surface} max_lines={1} />
          <Spacer size={4} />
          <Text text={m.change_rest} text_size={12.5} text_color={0xFF8A7B60} max_lines={1} />
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
        background={Kati.Theme.card(:light)}
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
    name_color = if paused?, do: 0xFF8A8479, else: Kati.Theme.ink()
    line_color = if paused?, do: 0xFFB3ACA2, else: 0xFF8A8479

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={14} padding_bottom={14}>
        {Kati.Screens.Subscriptions.badge(row.badge)}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text text={row.name} text_size={13.5} font_weight="semibold" text_color={name_color} max_lines={1} />
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
      [size: 32, shape: :rounded, background: 0xFFEFECE7],
      [glyph]
    )
  end

  # A paused service has one value on the right, not two: it has no rate,
  # because £5.00 buying nothing is not a price per hour. Two clauses rather
  # than a nil-rate branch, so the shapes stay honestly different.
  @doc false
  def money(row, true) do
    ~MOB"""
    <Text text={row.price} font_family="mono" text_size={12} text_color={0xFFB3ACA2} max_lines={1} />
    """
  end

  # 46 wide, not hugging. `text_align="right"` makes a Text fillMaxWidth on
  # this bridge — the defect that flattened screen 08's rating card — so it
  # only behaves inside a column of declared width. 46 clears the widest value
  # the drawing carries (`£13.99` at mono 12).
  def money(row, false) do
    ~MOB"""
    <Column width={46}>
      <Text text={row.price} font_family="mono" text_size={12} font_weight="medium" text_color={:on_surface} text_align="right" max_lines={1} />
      <Spacer size={3} />
      <Text text={row.rate} font_family="mono" text_size={10} text_color={row.rate_tone} text_align="right" max_lines={1} />
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
      background={Kati.Theme.card(:light)}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={17}
    >
      <Row fill_width={true} align="top">
        {Kati.UI.symbol("lightbulb", size: 19, color: 0xFFE8823C)}
        <Spacer size={11} />
        <Text text={s.body} text_size={13} line_height={1.55} text_color={0xFF4A4238} weight={1.0} />
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
  @doc false
  def confirm(label, false), do: confirm_button(label, Kati.Theme.ink(), 0xFFFBFAF8)
  def confirm(label, true), do: confirm_button(label, 0xFFEFECE7, 0xFF5C574F)

  @doc false
  def confirm_button(label, background, foreground) do
    tap = {self(), :remind}

    ~MOB"""
    <Box weight={1.0}>
      <Row fill_width={true} height={40} corner_radius={20} background={background} align="center" on_tap={tap}>
        <Spacer weight={1.0} />
        <Text text={label} text_size={12.5} font_weight="semibold" text_color={foreground} max_lines={1} />
        <Spacer weight={1.0} />
      </Row>
    </Box>
    """
  end

  @doc false
  def dismiss(label) do
    tap = {self(), :dismiss}

    ~MOB"""
    <Row height={40} corner_radius={20} background={0xFFEFECE7} padding_left={15} padding_right={15} align="center" on_tap={tap}>
      <Text text={label} text_size={12.5} font_weight="semibold" text_color={0xFF5C574F} max_lines={1} />
    </Row>
    """
  end

  @doc """
  The `rgba(26,25,23,.07)` rule between two services, absent after the last.

  ## Not `Kati.Components.MishkaSeparator`, and the reason is one row of pixels

  A rule between rows is exactly what a separator is, and the port's API fits —
  `separator(color: 0x121A1917)` at its default `thickness: 1` is this line.
  What does not fit is what it draws. The port renders `<Divider>`, which
  `MobBridge` hands to Material 3's `HorizontalDivider`, and in 1.2.0 that
  composable is not a filled box:

      Canvas(modifier.fillMaxWidth().height(thickness)) {
        drawLine(color, strokeWidth = thickness.toPx(), …)
      }

  `height(1.dp)` **rounds** to whole device pixels while `thickness.toPx()`
  does not, and the capture device runs at 2.6875x. So the node is 3px tall and
  the antialiased stroke covers 2.6875 of them: the last row lands at 69%
  coverage instead of 100%. `Box` + `background` fills all three. On this
  screen's `#FBFAF8` card that is about five levels of grey along the bottom
  edge of every rule — under `bin/diff_frames.py`'s tolerance of 12, and still
  a difference, and a difference is not what this rule is.

  It vanishes at any density where 1dp is a whole number of pixels, which is
  why it is invisible in a unit test and would have shipped.

  Upstream, a separator drawn as `Box(fill_width, height: thickness,
  background: color)` is pixel-exact at every density, and is also the fix for
  the iOS breakage the port's own moduledoc records, since `SwiftUI.Divider`
  draws along its container's axis and comes out vertical there.
  """
  def hairline(false), do: ~MOB"<Spacer size={0} />"
  def hairline(true), do: ~MOB"<Box fill_width={true} height={1} background={0x121A1917} />"

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
