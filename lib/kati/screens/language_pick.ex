defmodule Kati.Screens.LanguagePick do
  @moduledoc """
  Screen 53 — the onboarding language choice.

  Built to `test/design/screens/53.html`. The first step of five, and the
  first thing the app asks: nothing else can be worded until it is answered.
  So the question is asked twice, once in each script, and each option states
  its three consequences — direction, digits, calendar — in its own script.
  `RIGHT TO LEFT · ۱۲۳۴ · SHAMSI` is legible to someone who cannot read the
  English row, which an English description of Persian would not be.

  There is no back pill and no dock: the drawing has neither, and the way out
  is **Continue**. The frame's bottom inset is therefore 40, not 132.

  ## Fonts are the content here

  The Persian strings are set in Vazirmatn (`font_family="fa"`), not in Plus
  Jakarta Sans. A Persian name in a Latin face is precisely the near-miss this
  screen exists to prevent, and the app ships the face already — see
  `Kati.Theme`'s substrate table.

  The drawing marks the Persian blocks `direction:rtl`. The container stays
  `Kati.Locale.direction_prop()`, which is still `ltr` at this point in the
  flow — the whole interface flips only once the choice is *made*, which is
  what the cream note promises. Bidi resolution puts the Arabic script the
  right way round inside an LTR paragraph on its own.

  ## The ticked row is the app's own locale

  Everything else on this screen is drawn copy — the question, the two `meta`
  specifications, the cream note — but **which row carries the tick is a
  setting the app already holds**, and until this round it was a `chosen: true`
  frozen onto English in `Kati.Onboarding.LanguageSample`. That module's own
  doc had already written the change down: *"when the choice becomes real it
  goes through `Kati.Locale.put/1` … only `chosen` moves."* So only `chosen`
  moved. `pick/0` re-answers it from `Kati.Locale.current/0` at mount, and
  `locale_of/1` is the whole mapping — the same one-line bridge
  `Kati.Screens.Language.locale_of/1` is on screen 54, off `script:` rather
  than off the displayed name, so no English word decides anything.

  Two things this buys, and they are the same thing seen from either end. The
  container already reads `Kati.Locale.direction_prop()`, so a `:fa` install
  drew this screen right-to-left **with the tick still on English** — a picker
  contradicting the interface it is drawn inside. And screen 54 has read the
  locale since it gained a write path, so the app's two language pickers can no
  longer disagree about the language it is in.

  The resting frame cannot move: `Kati.Locale.current/0` answers `:en` for a
  device that has never chosen, `:en` is English, and English is the row
  `53.html` ticks.

  ## Choosing, and why the write is safe here

  Each option writes the locale and **Continue** pushes step two, screen 26.

  This screen was a picture of a picker for as long as it had nowhere to go.
  The objection was never `Kati.Locale.put/1`, which is one call — it was that
  writing a locale from a screen with no way forward strands the reader in a
  flipped interface whose only exit is the back button, the stranding
  `Kati.Screens.Language` spends three of its own paragraphs avoiding.

  `Kati.Onboarding` is the flow that answers it, and it also removes the
  hazard: this screen has no back pill and no dock, and on a first run it is
  the stack root, so there is no back to press and nothing to be stranded
  from. Flipping the direction here is the *point* — every screen after it is
  laid out in the direction chosen on it.

  The write goes through `Kati.Locale.put/1` and then re-reads `pick/0` rather
  than assigning the option list directly, because `pick/0` derives `chosen`
  from the locale: one source of truth answers both the tick drawn here and
  the direction of everything downstream.
  """
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Onboarding.LanguageSample
  alias Kati.Theme.Palette

  def mount(_params, _session, socket) do
    Mob.Theme.set(Kati.Theme.current())
    Kati.Onboarding.reached!(:language)
    {:ok, Mob.Socket.assign(socket, :pick, Kati.Screens.LanguagePick.pick())}
  end

  @doc """
  The question as `render/1` draws it: the drawing's copy, the app's own locale.

  `Kati.Onboarding.LanguageSample` supplies every string and the option order;
  the only field this rewrites is `chosen`, which is a setting rather than copy.
  The sample is left holding `chosen: true` on English — it is the drawn state
  and the fixture the tests compare a real render against, and a second copy of
  the drawing's answer is exactly how the two drift apart.
  """
  @spec pick() :: map()
  def pick do
    drawn = LanguageSample.pick()
    locale = Kati.Locale.current()

    %{drawn | options: Enum.map(drawn.options, &Kati.Screens.LanguagePick.settle(&1, locale))}
  end

  @doc "One option, ticked or not according to `locale`."
  @spec settle(map(), :en | :fa) :: map()
  def settle(option, locale),
    do: %{option | chosen: Kati.Screens.LanguagePick.locale_of(option) == locale}

  @doc """
  Which locale an option stands for.

  Off `script:`, which the option already carries because the badge and the
  name have to pick a typeface — the same key, and the same two-clause shape,
  `Kati.Screens.Language.locale_of/1` uses on screen 54. It says `:persian`
  where that one says `:fa`, which is why this is a second function rather than
  a call to that one: two screens named the same idea differently before either
  read a locale, and unifying the atom would move a string in the sample module
  that the fixture is compared against.

  A third installed language needs a third locale to point at; `Kati.Locale`
  ships two, and this screen draws two.
  """
  @spec locale_of(map()) :: :en | :fa
  def locale_of(%{script: :persian}), do: :fa
  def locale_of(_option), do: :en

  def render(assigns) do
    pick = assigns.pick

    ~MOB"""
    <Box
      fill_width={true}
      fill_height={true}
      background={:background}
      layout_direction={Kati.Locale.direction_prop()}
      accessibility_id={Kati.Screens.Identity.of(__MODULE__)}
    >
      <Scroll>
        <Column
          fill_width={true}
          padding_left={21}
          padding_right={21}
          padding_top={64}
          padding_bottom={40}
        >
          <Column fill_width={true} padding_top={26}>
            {Kati.Screens.LanguagePick.steps(pick)}
            {Kati.Screens.LanguagePick.mark()}
            {Kati.Screens.LanguagePick.question(pick)}
            {Kati.Screens.LanguagePick.options(pick)}
            {Kati.Screens.LanguagePick.note(pick)}
            {Kati.Screens.LanguagePick.cta(pick)}
          </Column>
        </Column>
      </Scroll>
    </Box>
    """
  end

  # Five segments, `done` of them filled — the step count without a "1 of 5"
  # anyone has to read.
  @doc false
  def steps(pick) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {1..pick.steps
         |> Enum.map(fn i -> Kati.Screens.LanguagePick.step_bar(i <= pick.done) end)
         |> Enum.intersperse(Kati.Screens.LanguagePick.step_gap())}
      </Row>
      <Spacer size={26} />
    </Column>
    """
  end

  @doc false
  def step_gap, do: ~MOB"<Spacer size={5} />"

  @doc false
  def step_bar(done?) do
    color = if done?, do: Palette.ink(), else: Palette.track_off()

    ~MOB"<Box weight={1.0} height={4} corner_radius={2} background={color} />"
  end

  @doc """
  The 56pt ink mark the question hangs off.

  `Kati.Components.MishkaThemeIcon` — "a themed container around exactly one
  icon", which is the whole of what this is — for the same reason
  `Kati.UI.SettingsList.icon_tile/1` uses it, and with the same guarantee.
  Given children, an explicit numeric `color`, no `id` and no `on_tap`,
  `theme_icon/2` returns
  `%{type: :box, props: %{width: 56, height: 56, align: :center,
  corner_radius: 18, background: Palette.ink()}, children: [glyph]}` — node for
  node what this wrote by hand. `align: :center` and `align="center"` reach
  the bridge as the same string; the `icon` shorthand, the `:filled` gradient
  layer and the id markers are all skipped.

  The glyph goes in as a child rather than through the `icon` prop: that
  shorthand builds its own `Text` with no `font_family`, so the Material
  Symbols ligature `translate` would be typeset as the word.
  """
  def mark do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.LanguagePick.mark_tile()}
      <Spacer size={20} />
    </Column>
    """
  end

  # `ink`, not `ink_fill`: this is a brand mark drawn on the page, not a control
  # filled with ink — the same 56pt tile `Kati.Screens.Onboarding.welcome/1`
  # leads with, and it takes the same token.
  @doc false
  def mark_tile do
    Kati.Components.MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Palette.ink(), size: 56, radius: 18},
      [Kati.UI.symbol("translate", size: 26, color: Palette.on_ink())]
    )
  end

  @doc false
  def question(pick) do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={pick.title}
        text_size={32}
        font_weight="extrabold"
        letter_spacing={-0.035}
        line_height={1.12}
        text_color={:on_surface}
      />
      <Spacer size={10} />
      <Text
        text={pick.title_fa}
        font_family="fa"
        text_size={26}
        font_weight="bold"
        line_height={1.4}
        text_color={Palette.sub()}
      />
      <Spacer size={14} />
      <Text text={pick.body} text_size={14.5} line_height={1.6} text_color={Palette.ink_soft()} />
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def options(pick) do
    ~MOB"""
    <Column fill_width={true}>
      {pick.options
       |> Enum.map(fn option -> Kati.Screens.LanguagePick.option(option) end)
       |> Enum.intersperse(Kati.Screens.LanguagePick.option_gap())}
    </Column>
    """
  end

  @doc false
  def option_gap, do: ~MOB"<Spacer size={11} />"

  # The chosen row is drawn on ink, the same inversion screen 49 gives the
  # active plan: the choice you are living with is the dark one.
  #
  # `ink_fill` and the `on_ink` family, not `ink`: this is a control filled with
  # ink and carrying its own text, so screen 28's inversion applies — paper fill
  # with ink content in dark — and everything sitting on it swaps sides of the
  # ramp with it.
  @doc false
  def option(%{chosen: true} = option) do
    tap =
      {self(),
       String.to_atom("choose_" <> Atom.to_string(Kati.Screens.LanguagePick.locale_of(option)))}

    ~MOB"""
    <Row
      on_tap={tap}
      fill_width={true}
      height={76}
      background={Palette.ink_fill()}
      corner_radius={22}
      shadow="0 14 28 -14 #E61A1917"
      padding_left={17}
      padding_right={17}
      align="center"
    >
      {Kati.Screens.LanguagePick.badge_tile(option, Palette.on_ink_veil(), Palette.on_ink_glyph())}
      <Spacer size={14} />
      <Column weight={1.0}>
        {Kati.Screens.LanguagePick.name(option, Palette.on_ink())}
        <Spacer size={4} />
        <Text
          text={option.meta}
          font_family="mono"
          text_size={10.5}
          text_color={Palette.on_ink_meta()}
          max_lines={1}
        />
      </Column>
      <Spacer size={14} />
      {Kati.Screens.LanguagePick.chosen_mark()}
    </Row>
    """
  end

  def option(%{chosen: false} = option) do
    tap =
      {self(),
       String.to_atom("choose_" <> Atom.to_string(Kati.Screens.LanguagePick.locale_of(option)))}

    ~MOB"""
    <Row
      on_tap={tap}
      fill_width={true}
      height={76}
      background={Palette.card()}
      corner_radius={22}
      shadow={Kati.Theme.shadow_card_soft()}
      padding_left={17}
      padding_right={17}
      align="center"
    >
      {Kati.Screens.LanguagePick.badge_tile(option, Palette.paper(), Palette.ink())}
      <Spacer size={14} />
      <Column weight={1.0}>
        {Kati.Screens.LanguagePick.name(option, Palette.ink())}
        <Spacer size={4} />
        <Text
          text={option.meta}
          font_family="mono"
          text_size={10.5}
          text_color={Palette.muted()}
          max_lines={1}
        />
      </Column>
      <Spacer size={14} />
      {Kati.Screens.LanguagePick.unchosen_mark()}
    </Row>
    """
  end

  @doc """
  The 42pt tile a language option leads with, and the 24pt disc it ends with.

  Both are `Kati.Components.MishkaThemeIcon` — see `mark_tile/0` for why the
  node is unchanged. `fill` differs by state (`rgba(245,242,238,.12)` inside
  the ink row, `#EFECE7` on paper) and so does the badge's own colour, which
  is why they are two arguments rather than a `chosen` flag: the tile has no
  opinion about which row it is in.

  Both *discs* are theme icons now too — see `unchosen_mark/0`, which used to
  be the one shape on this screen the component could not draw.
  """
  def badge_tile(option, fill, color) do
    Kati.Components.MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: fill, size: 42, radius: 14},
      [Kati.Screens.LanguagePick.badge(option, color)]
    )
  end

  @doc false
  def chosen_mark do
    # `0xFFFBFAF8` LEFT AS A LITERAL. `Kati.Theme.Palette` names four meanings
    # for this value — the card, a label on an ink fill, the FAB's plus, and a
    # title over artwork — and this is none of them: it is a glyph on a HUE.
    # Orange is `:hue`, unchanged in dark, so a tick that followed the mode
    # would turn to ink on a disc that never darkened. The two tokens that keep
    # this value in dark are scoped to a photographic ground (`on_media`) or to
    # the FAB, so neither is honestly this. Left, and reported: the table has no
    # "on a hue fill" row.
    Kati.Components.MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Palette.accent(), size: 24, radius: 12},
      [Kati.UI.symbol("check", size: 15, color: 0xFFFBFAF8)]
    )
  end

  @doc """
  The empty 24pt ring an unchosen language option ends with.

  `Kati.Components.MishkaThemeIcon`, which it could not be until this round.
  53.html draws it `width:24px;height:24px;border-radius:12px;border:1.5px
  solid rgba(26,25,23,.16)` — a border with no fill and a fractional width —
  and `theme_icon/2` used to paint a border only under `variant: :outline`,
  which forfeits the fill *and* hard-codes the width at 1. `border_color` and
  `border_width` are now caller overrides on any variant, so `:subtle` (no
  background, no border of its own) plus the two overrides is the drawing.

  ## Why the pixels do not move

  `:subtle`'s skin is `%{background: nil, icon: color, border: nil}`, and
  `put_some/3` **drops** a nil rather than writing it — so no `background` key
  reaches the node at all, which is what `background:transparent` means and is
  not the same as a JSON `null` the bridge would try to read. With no `id`, no
  `icon` and no `on_tap` the id markers, the glyph shorthand and the handler
  are all skipped, and `:subtle` contributes an empty gradient layer, so the
  node is `%{type: :box, props: %{width: 24, height: 24, align: :center,
  corner_radius: 12, border_color: Palette.border(), border_width: 1.5},
  children: []}`.

  That is the `Box` this wrote by hand plus `align: :center`, which cannot
  move anything: the ring has no children to align. `border_width` rides
  `floatProp`, so the 1.5 survives — an `intProp` would have truncated it to
  1 and thinned every unchosen ring on the screen.
  """
  def unchosen_mark do
    Kati.Components.MishkaThemeIcon.theme_icon(%{
      variant: :subtle,
      size: 24,
      radius: 12,
      border_color: Palette.border(),
      border_width: 1.5
    })
  end

  # The Latin badge is DM Mono at 14 and the Persian one is Vazirmatn Bold at
  # 16 — the drawing's own sizes, chosen so two scripts of different x-height
  # look the same weight inside the same 42pt tile.
  @doc false
  def badge(%{script: :persian} = option, color) do
    ~MOB"""
    <Text
      text={option.badge}
      font_family="fa"
      text_size={16}
      font_weight="bold"
      text_color={color}
      max_lines={1}
    />
    """
  end

  def badge(option, color) do
    ~MOB"""
    <Text text={option.badge} font_family="mono" text_size={14} text_color={color} max_lines={1} />
    """
  end

  @doc false
  def name(%{script: :persian} = option, color) do
    ~MOB"""
    <Text
      text={option.name}
      font_family="fa"
      text_size={17}
      font_weight="bold"
      text_color={color}
      max_lines={1}
    />
    """
  end

  def name(option, color) do
    ~MOB"""
    <Text
      text={option.name}
      text_size={16}
      font_weight="bold"
      letter_spacing={-0.02}
      text_color={color}
      max_lines={1}
    />
    """
  end

  # Cream, and filled rather than outlined: this is the consequence of the
  # choice above it, not an aside about the screen.
  @doc false
  def note(pick) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={18} />
      <Row fill_width={true} background={Palette.cream()} corner_radius={18} padding={15} align="top">
        {Kati.UI.symbol("info", size: 17, color: Palette.gold_icon())}
        <Spacer size={11} />
        <Text
          text={pick.note}
          text_size={12.5}
          line_height={1.55}
          text_color={Palette.cream_body()}
          weight={1.0}
        />
      </Row>
    </Column>
    """
  end

  @doc false
  def cta(pick) do
    tap = {self(), :continue}

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={20} />
      <Box
        on_tap={tap}
        fill_width={true}
        height={54}
        corner_radius={27}
        background={Palette.ink_fill()}
        align="center"
      >
        <Row align="center">
          <Text
            text={pick.cta}
            text_size={14.5}
            font_weight="bold"
            text_color={Palette.on_ink()}
            max_lines={1}
          />
          <Spacer size={9} />
          {Kati.UI.symbol("arrow_forward", size: 19, color: Palette.on_ink())}
        </Row>
      </Box>
    </Column>
    """
  end

  # Tapping an option writes the locale; Continue moves to step two.
  #
  # The moduledoc below used to end "the write belongs with whatever builds the
  # flow" — this is that flow. Writing here is safe in a way it was not on
  # screen 54: this screen has no back pill and no dock, so flipping the
  # direction under the reader cannot strand them in a mirrored app whose only
  # exit is a back button. There is no back to press yet.
  #
  # `Kati.Locale.put/1` then a re-read of `pick/0`, rather than assigning the
  # option list directly: `pick/0` derives `chosen` from the locale, so one
  # source of truth answers both the tick and every later screen's direction.
  def handle_info({:tap, tag}, socket) do
    case Atom.to_string(tag) do
      "choose_" <> code ->
        {:noreply, choose(code, socket)}

      "continue" ->
        {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.PickSections)}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  defp choose(code, socket) do
    case Enum.find(Kati.Locale.supported(), &(Atom.to_string(&1) == code)) do
      nil ->
        socket

      locale ->
        Kati.Locale.put(locale)
        Mob.Socket.assign(socket, :pick, Kati.Screens.LanguagePick.pick())
    end
  end
end
