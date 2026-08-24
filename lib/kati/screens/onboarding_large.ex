defmodule Kati.Screens.OnboardingLarge do
  @moduledoc """
  Screen 138 — onboarding's notification step at 235% Dynamic Type, a
  reference sheet for `Kati.Screens.Onboarding.telling/1` (screen 38's middle
  third, itself step 3 of the first-run sequence `Kati.Screens.PickSections`
  begins).

  138 re-types a smaller slice of that step at the largest size Android
  offers, the same job screen 91 does for search and screen 133 does for
  backup, so the claim *nothing here clips* can be checked by looking rather
  than asserted.

  ## The row becomes a stack, exactly as the board's own caption says

  Board 138 carries a caption Claude Design does not render into the frame —
  read it, it is not decoration:

  > "The hard case named in the brief. Option rows become stacked cards —
  > glyph and tick on their own line, title and description below — and 26's
  > six tiles would go one per row by the same rule. The step rule holds its
  > 4px height: it is chrome whose size carries structure, so it caps rather
  > than growing."

  `Kati.Screens.Onboarding.option/1` is a `Row`: glyph, then a weighted
  `Column` holding the title and its sub-line, then (for the chosen option)
  a tick — with `max_lines={1}` on both text nodes. At 235% that row does not
  survive, so `option_card/1` stacks instead: the glyph and the tick share a
  header line of their own, the title sits under it, the sub-line under that
  — and neither carries `max_lines`. The card grows downward and the `Scroll`
  absorbs it, the same trade screen 91 makes for a search result.

  ## What 138 draws that 38 does not, and the reverse

  138 is not 38 zoomed in.

    * **138 draws two of the telling step's three options.**
      `Kati.Onboarding.Sample.telling/0` has a third card, *Weekly digest* —
      real copy, not a stand-in — and this board leaves it out the way board
      133 leaves out 128's third backup format: a smaller specimen by design,
      not the board running out of frame. The two drawn here are typed rather
      than read off `Sample.telling/0`, for the same reason 133's status card
      is typed rather than read off a live ledger: a specimen has to freeze
      one scenario and render exactly that scenario every time it opens.
    * **138 draws an assurance card 38 does not.** *"Kati won't ask for
      notification permission. Everything arrives in your inbox."* is new
      copy — screen 40's *"Not yet asked"* is the same claim from the other
      side of the OS permission, and this is where the app first tells the
      user so.
    * **138's title is 32pt where 38's is 26pt**, with 38's own welcome-step
      tracking (`-0.03em`, not welcome's `-0.035em`) and a shallower
      `line-height: 1.2`. Typed as drawn rather than reconciled — a specimen
      answers "what does the board say," not "which of the app's two title
      recipes is this closest to."

  ## The step meter disagrees with the shipped screen, and this file does not resolve it

  `Kati.Screens.Onboarding.steps/1` and `Kati.Screens.PickSections.steps/0`
  both draw a four-bar meter — telling is step 3 of 4 there, and `steps(3)`
  is the call that draws it. Board 138 draws **five** bars with **four**
  filled. That is not this specimen's arithmetic to fix: `steps/0` below
  types the drawing's own 4-of-5 rather than calling `Onboarding.step_bar/1`
  over `1..4`, and the gap between what ships and what this board draws is
  named here rather than quietly split the difference on.

  ## No back pill, because 38 draws none either

  Screens 91 and 133 are pushed under Settings with
  `Kati.Screens.Pushed`'s floating pill — their drawings say so, spelling
  `Home` and `Settings` out over `arrow_back_ios_new`. Board 138 spells
  neither: there is no pill-shaped anything in the first several hundred
  pixels, and the only back-reading glyph on the whole board is a bare
  `arrow_back` beside the words *"Back to sections"*, sitting in the
  content's own flow after **Continue** rather than floating over it. That is
  `Kati.Screens.Onboarding`'s own chrome — "no back pill and no dock,
  each step carries its own way out" — carried into this specimen of one of
  its steps. So this file `use`s `Mob.Screen` directly, the way
  `Kati.Screens.Onboarding` and `Kati.Screens.PickSections` do, and not
  `Kati.Screens.Pushed`.

  ## What K-29 caps here, and the one place the caption's own claim does not hold

  `max_font_scale` (fence K-29, `MobBridge.kt`) hands a subtree a
  `LocalDensity` whose `fontScale` is clamped, leaving `density` untouched —
  a capped label keeps its own padding and corner radii, only its `sp` stops
  growing. The rule is `Kati.Screens.Calendar.day_strip/1`'s and every other
  Large screen's: **content grows, chrome whose size carries structure caps
  instead.**

    * **Capped:** each option card's header row (a 26pt glyph beside a 26pt
      tick disc holding a 16pt check — `Kati.Screens.Onboarding.tick/3`'s own
      shape, at this board's own numbers) and the 64pt **Continue** stadium
      holding one line at 19pt. Both are fixed-size chrome a bigger `sp`
      would overflow rather than improve.
    * **Not capped, and the caption's own line about it does not actually
      apply:** the step bar. The caption calls it "chrome whose size carries
      structure, so it caps rather than growing," which is the right rule for
      a 64pt button — but `step_bar/1` draws a flat `Box`, no `Text` inside
      it, and `max_font_scale` clamps `LocalDensity.fontScale`, which only
      the `sp` on a `Text` node reads. There is nothing under a bar drawn in
      `dp` for a font-scale ceiling to protect, so `steps/0` carries no
      `max_font_scale` and loses nothing by it — the 4px height the caption
      is defending was never at risk from text growth in the first place.
    * **Uncapped, because it is content:** the title, both option cards'
      title and sub-line, the assurance card's paragraph, and the *"Back to
      sections"* line — none sits inside a container whose height is fixed,
      so none needs protecting from a real device's own 235%.

  `cap/0` is **1.0** — every `sp` here is already the board's 235% size,
  typed out, so 1.0 reads as "do not scale this twice," not "do not scale
  this." At an ordinary system scale it costs nothing: K-29 overrides
  `LocalDensity` only where `density.fontScale > cap`.

  ## What is reused, and the one colour that stays a raw literal

  `Kati.Screens.Onboarding.tick/3` builds the selected card's disc —
  `tick(26, 13, 16)` is this board's own numbers, a third call site for a
  function already parameterised by three arguments rather than a third copy
  of the `Box` it draws. `Kati.Theme.shadow_card_soft/0` is the card lift on
  the unselected option and the assurance card, matching the drawing's own
  `0 1px 2px rgba(26,25,23,.04), 0 12px 24px -18px rgba(26,25,23,.7)` exactly.
  The selected card's `0 12 24 -14 #E61A1917` and the button's
  `0 14 28 -12 #801A1917` are literals rather than a `Kati.Theme` call because
  `Kati.Screens.Onboarding.option/1` and `Kati.Screens.BackupLarge.save_button/0`
  already write those same two strings for the same two shapes — one more
  named helper for a shadow already spelled out twice would be the third
  spelling, not the first shared one.

  The selected card's sub-line is `rgba(251,250,248,.62)` — 62% of
  `#FBFAF8` — and no `Kati.Theme.Palette` token names that alpha:
  `on_ink_count` is 60%, `on_ink_count_soft` is 65%, and 62% sits on neither.
  `0x9EFBFAF8` stays a raw literal rather than borrowing the nearer of the
  two, the way the tick's own `0xFFFBFAF8` stays literal in
  `Kati.Screens.Onboarding.tick/3` — a value with no name in the table is not
  quietly rounded to one that almost fits.

  ## Nothing here taps

  **Continue** and *"Back to sections"* are drawn, not wired — the same
  choice screens 91 and 133 make for `Open` and the save button. Wiring
  **Continue** would mean deciding what step 138 is a specimen *of* actually
  finishes, and this file is not step 3 of a live flow, it is a frozen
  picture of it. Wiring *"Back to sections"* is worse than doing nothing:
  `Mob.Socket.pop_screen/1` would return to whatever screen pushed this
  specimen — a gallery or a dynamic-type test list — not to
  `Kati.Screens.PickSections`, so a tap that read *Back to sections* and
  landed somewhere else would be a lie the drawing does not tell. `Mob.Screen`
  defines no `handle_tap/2` to forget, and this file draws no `on_tap` for it
  to answer, so the sweep finds nothing dead here.
  """

  use Mob.Screen
  import Mob.Sigil

  alias Kati.Theme.Palette
  alias Kati.UI

  # Screen 38's own words for step 3 — `Kati.Onboarding.Sample.telling/0`
  # carries the identical title, so this stays typed rather than a second
  # source that could drift from it.
  @title "How should we tell you?"

  # The two of `Sample.telling/0`'s three options this board draws — see the
  # moduledoc on why *Weekly digest* is missing on purpose and why these are
  # typed rather than read off the shared sample.
  @options [
    %{
      icon: "inbox",
      title: "Quietly",
      sub: "A card on home. Nothing buzzes.",
      selected?: true
    },
    %{
      icon: "notifications",
      title: "Notify me",
      sub: "A push when something lands.",
      selected?: false
    }
  ]

  @continue_label "Continue"
  @back_label "Back to sections"

  # The drawing's own step meter — 4 of 5, not the shipped 3-of-4. See the
  # moduledoc's "step meter disagrees" section.
  @step_total 5
  @step_done 4

  def mount(_params, _session, socket) do
    Mob.Theme.set(Kati.Theme.current())
    {:ok, socket}
  end

  @doc """
  The sheet, top to bottom: step meter, title, two options, an assurance
  card, Continue, then the way back — 38's own order for step 3, plus the
  assurance card 38 does not draw.
  """
  def render(_assigns) do
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
          <Column fill_width={true} padding_top={20}>
            {Kati.Screens.OnboardingLarge.steps()}
            {Kati.Screens.OnboardingLarge.title()}
            {Kati.Screens.OnboardingLarge.options()}
            {Kati.Screens.OnboardingLarge.assurance()}
            {Kati.Screens.OnboardingLarge.continue()}
            {Kati.Screens.OnboardingLarge.back()}
          </Column>
        </Column>
      </Scroll>
    </Box>
    """
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  @doc """
  The ceiling on how far this screen's structural chrome may grow, as a
  `fontScale`.

  1.0, because every `sp` here is already the drawing's 235% size, typed out
  — see the moduledoc. It reads as "do not scale this twice" rather than "do
  not scale this," and it is inert on a device at ordinary size: fence K-29
  overrides `LocalDensity` only where `density.fontScale > cap`.
  """
  @spec cap() :: float()
  def cap, do: 1.0

  @doc """
  The step meter: `@step_total` bars, `@step_done` of them filled.

  Not `Kati.Screens.Onboarding.step_bar/1` over `1..4` — this board's own
  count is five bars, four filled, and typing it here rather than reusing the
  shipped four-bar meter is the point; see the moduledoc. Carries no
  `max_font_scale`: a `Box` with no `Text` inside it has no `sp` for K-29 to
  clamp.
  """
  @spec steps() :: map()
  def steps do
    bars =
      1..@step_total
      |> Enum.map(fn i -> Kati.Screens.OnboardingLarge.step_bar(i <= @step_done) end)
      |> Enum.intersperse(~MOB"<Spacer size={5} />")

    ~MOB"""
    <Row fill_width={true} align="center">
      {bars}
    </Row>
    """
  end

  @doc false
  def step_bar(done?) do
    color = if done?, do: Palette.ink(), else: Palette.track_off()
    ~MOB"<Box weight={1.0} height={4} corner_radius={2} background={color} />"
  end

  @doc """
  The 32pt title, carrying the drawing's own `22px 0 20px` margin as the
  spacers either side of it rather than the step meter's.
  """
  @spec title() :: map()
  def title do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={22} />
      <Text
        text={Kati.Screens.OnboardingLarge.headline()}
        text_size={32}
        font_weight="extrabold"
        letter_spacing={-0.03}
        line_height={1.2}
        text_color={:on_surface}
      />
      <Spacer size={20} />
    </Column>
    """
  end

  @doc "Step 3's own words. Typed — see the moduledoc on why against `Sample.telling/0`."
  @spec headline() :: String.t()
  def headline, do: @title

  @doc "The two option cards, at the drawing's own 12pt gap and 20pt trailing margin."
  @spec options() :: map()
  def options do
    cards =
      @options
      |> Enum.map(&Kati.Screens.OnboardingLarge.option_card/1)
      |> Enum.intersperse(~MOB"<Spacer size={12} />")

    ~MOB"""
    <Column fill_width={true}>
      {cards}
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  One option as a stacked card: a header line (glyph, then a tick for the
  chosen one), the title, the sub-line.

  Neither text node carries `max_lines` — that is the whole trade the
  moduledoc's "row becomes a stack" section describes, applied to the one
  card that has a tick to make room for.
  """
  @spec option_card(map()) :: map()
  def option_card(%{selected?: true} = option) do
    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.ink_fill()}
      corner_radius={22}
      shadow="0 12 24 -14 #E61A1917"
      padding={18}
    >
      <Row fill_width={true} align="center" max_font_scale={Kati.Screens.OnboardingLarge.cap()}>
        {UI.symbol(option.icon, size: 26, color: Palette.on_ink())}
        <Spacer weight={1.0} />
        {Kati.Screens.Onboarding.tick(26, 13, 16)}
      </Row>
      <Spacer size={14} />
      <Text
        text={option.title}
        text_size={21}
        font_weight="bold"
        line_height={1.3}
        text_color={Palette.on_ink()}
      />
      <Spacer size={9} />
      <Text text={option.sub} text_size={17} line_height={1.5} text_color={Palette.scrim_soft()} />
    </Column>
    """
  end

  def option_card(option) do
    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={22}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={18}
    >
      <Row fill_width={true} align="center" max_font_scale={Kati.Screens.OnboardingLarge.cap()}>
        {UI.symbol(option.icon, size: 26, color: Palette.sub())}
      </Row>
      <Spacer size={14} />
      <Text
        text={option.title}
        text_size={21}
        font_weight="bold"
        line_height={1.3}
        text_color={:on_surface}
      />
      <Spacer size={9} />
      <Text text={option.sub} text_size={17} line_height={1.5} text_color={Palette.sub()} />
    </Column>
    """
  end

  @doc """
  The card 38 does not draw: `check_circle`, then the promise the notification
  decision is answering *before* the OS is asked.

  `won't ask` is the one bold run — `Kati.UI.rich_text/1` concatenates the
  three and sets the longest run's own style, which is the trailing clause
  here, so the emphasis does not survive at the run boundary either. Same
  trade `Kati.Screens.BackupLarge.footnote/0` makes for its own bold clause.
  """
  @spec assurance() :: map()
  def assurance do
    body = [text_size: 17, line_height: 1.55, text_color: Palette.ink_soft()]

    strong = [
      font_weight: "semibold",
      text_color: Palette.ink(),
      text_size: 17,
      line_height: 1.55
    ]

    paragraph =
      UI.rich_text([
        {"Kati ", body},
        {"won’t ask", strong},
        {" for notification permission. Everything arrives in your inbox.", body}
      ])

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={18}
      >
        {UI.symbol("check_circle", size: 24, color: Palette.green(), fill: true)}
        <Spacer size={12} />
        {paragraph}
      </Column>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  The 64pt Continue stadium, at the drawing's own 19pt bold — the same shape
  and the same shadow string `Kati.Screens.BackupLarge.save_button/0` already
  writes for its own button. Capped: a single-line label in a fixed-height
  stadium is exactly the chrome `cap/0` exists for. Drawn, not wired — see
  the moduledoc's "nothing here taps".
  """
  @spec continue() :: map()
  def continue do
    ~MOB"""
    <Column fill_width={true} max_font_scale={Kati.Screens.OnboardingLarge.cap()}>
      <Box
        fill_width={true}
        height={64}
        corner_radius={32}
        background={Palette.ink_fill()}
        shadow="0 14 28 -12 #801A1917"
        align="center"
      >
        <Text
          text={Kati.Screens.OnboardingLarge.continue_label()}
          text_size={19}
          font_weight="bold"
          text_color={Palette.on_ink()}
          max_lines={1}
        />
      </Box>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc "Continue's own word. Typed, matching `Sample.welcome/0`'s sibling CTAs."
  @spec continue_label() :: String.t()
  def continue_label, do: @continue_label

  @doc """
  The way out the drawing gives this step instead of a floating back pill:
  a bare `arrow_back` beside the words, hugging its own width rather than
  spanning the row. Drawn, not wired — see the moduledoc's "no back pill"
  and "nothing here taps" sections.
  """
  @spec back() :: map()
  def back do
    ~MOB"""
    <Row align="center">
      {UI.symbol("arrow_back", size: 21, color: Palette.sub())}
      <Spacer size={9} />
      <Text
        text={Kati.Screens.OnboardingLarge.back_label()}
        text_size={17}
        font_weight="semibold"
        text_color={Palette.sub()}
      />
    </Row>
    """
  end

  @doc "The words beside the arrow. Typed — this screen names where 38's step 3 leads back to."
  @spec back_label() :: String.t()
  def back_label, do: @back_label
end
