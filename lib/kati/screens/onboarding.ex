defmodule Kati.Screens.Onboarding do
  @moduledoc """
  Screen 38 — Onboarding, steps 1, 3 and 4.

  Built to `test/design/screens/38.html`, which draws all three steps in
  one frame separated by hairlines rather than three frames side by side. This
  screen renders exactly that: one scroll, three sections, a divider between
  them. It is the drawing, so it is what gets built — the flow that shows one
  step at a time is a later job for whatever pushes this screen, and splitting
  it now would mean nothing could be compared against the export.

  There is no back pill and no dock: the drawing has neither, and each step
  carries its own way out (**Get started**, **Finish setup**, **Skip**). The
  frame's bottom inset is therefore 40, not 132.

  ## The selection ring is drawn inside its tile

  The design outlines the chosen poster with `outline: 2.5px solid #1A1917;
  outline-offset: 2px` — an outline, which in CSS costs no layout and simply
  overhangs the tile. Compose has no such thing: a border is part of the box.
  Two tiles and an 11pt gap already use the whole width between the gutters, so
  a ring drawn *outside* would push the row past the content width and squeeze
  both columns. It is therefore drawn on the tile's own edge with the artwork
  inset 4pt inside it, which reads as the same selection ring and keeps the
  grid on its arithmetic.

  The cell itself is a weight, not the drawing's 174: the export's own width is
  `calc(50% - 6px)`, and half of the 411dp device's content is 179, so a fixed
  174 would leave the second column 10pt short of the right gutter. The height
  is the export's own `aspect-ratio:2/3` rather than a number, so the tile
  stays 2:3 at whatever width the weight grants.

  ## Audited: drawn copy with no stored state

  **Every string is `Kati.Onboarding.Sample` and no resource in the app holds
  any of it**, which is what an onboarding screen is: three steps of sentences,
  drawn before the app contains anything. Nothing here taps — not the three
  notification options, not the four posters, not **Get started**, **Finish
  setup** or **Skip** — so the `selected?` flags are the drawing's state rather
  than a choice being forgotten, and the flow that would move them is the later
  job the section above describes.

  Two of the three steps would still have nothing to read once it exists. The
  **four starter posters** are a curated set for a device with an empty
  `Kati.Media.CachedTitle` — that is the point of step 4, so they cannot come
  from the cache. The **notification decision** is the one answer that ought to
  outlive the screen, and it has nowhere to go: `Kati.Notifications` is a
  scheduling library — `Plan`, `Budget`, `Digest`, `QuietHours` are all pure
  functions over candidates — and holds no per-user delivery preference. What it
  needs is a stored delivery style (`:quiet | :push | :digest`, plus the digest's
  weekday and hour) on `Mob.State` in the shape of `Kati.Theme.Mode`, read by
  `Kati.Notifications.Scheduler`. It is also, as screen 40 says, the answer that
  lets *"Not yet asked"* stay true — the decision is made here and the OS
  permission is requested later.

  ## The copy arrives in English and is spelled here

  `Kati.Onboarding.Sample` holds every sentence on this page as a plain
  literal, and it is not this screen's file to change: `Kati.Screens.
  LoudnessPrompt` reads the same `Sample.telling/0` and draws it through
  `option/1` below. `gettext/1` will not take a variable, so the words cannot be
  translated where they are used — they are keyed on their English spelling by
  `translated/1`, one clause each.

  **No msgid on this page is new.** Screens 161, 162 and 163 are this drawing's
  three panels renumbered by `D-33`, and they have carried these sentences
  through the catalogue since mishka-group/kati#103 folded their mirrors away.
  38 asks for the same msgids, so one sentence cannot end up in the catalogue
  twice under two spellings and drift.

  The right home for the calls is `Sample` itself —
  `Kati.Screens.PickSections.Sample` calls `gettext/1` from inside the sample
  module, which is what leaves nothing for a screen to look up — and moving them
  there would empty `translated/1`. That is an edit to a file this screen does
  not own.
  """
  use Mob.Screen
  use Gettext, backend: Kati.Gettext
  import Mob.Sigil

  alias Kati.Components.MishkaSeparator
  alias Kati.Components.MishkaThemeIcon
  alias Kati.Onboarding.Sample
  alias Kati.Theme.Palette

  # Records no step. This screen left the first run when `D-33`'s boards split
  # its three panels into screens 161, 162 and 163 — it is the original
  # drawing, kept because `Kati.Screens.Gallery` is the app's number → drawing
  # register and 38 is still a drawing. `Kati.Onboarding.reached!/1` would now
  # raise on the `:finish` it used to write, which is the right shape: a step
  # that no longer exists should not be quietly accepted.
  def mount(_params, _session, socket) do
    Mob.Theme.set(Kati.Theme.current())
    # Resolves the stored locale into THIS process. `Gettext.put_locale/2`
    # snapshots into the calling process exactly as `Mob.Theme.set/1` does,
    # and a screen is its own process — see `Kati.Locale.activate/0`.
    Kati.Locale.activate()
    {:ok, Mob.Socket.assign(socket, :flow, Sample.flow())}
  end

  def render(assigns) do
    flow = assigns.flow

    ~MOB"""
    <Box
      fill_width={true}
      fill_height={true}
      background={:background}
      layout_direction={Kati.Locale.direction_prop()}
      font_family={Kati.Locale.face_prop()}
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
          {Kati.Screens.Onboarding.welcome(flow.welcome)}
          {Kati.Screens.Onboarding.divider()}
          {Kati.Screens.Onboarding.telling(flow.telling)}
          {Kati.Screens.Onboarding.divider()}
          {Kati.Screens.Onboarding.first_title(flow.first_title)}
        </Column>
      </Scroll>
    </Box>
    """
  end

  @doc """
  One of `Kati.Onboarding.Sample`'s sentences, in the reader's script.

      iex> Kati.Screens.Onboarding.translated("Marram")
      "Marram"

  The moduledoc's *"The copy arrives in English and is spelled here"* is the
  why. In short: the words are literals in a module this screen does not own and
  `gettext/1` will not take a variable, so each is a clause keyed on its English
  spelling.

  Every msgid below already exists. 161, 162 and 163 are this drawing's three
  panels renumbered by `D-33` and they have carried these sentences since
  mishka-group/kati#103; asking for the same msgids is what keeps one sentence
  from reaching the catalogue twice under two spellings.

  An unknown string comes back unchanged rather than raising: copy added to
  `Sample` and not added here ships in Latin, which is wrong on a page rather
  than a crash in the middle of a first run — a `FunctionClauseError` here would be a blank device on the one screen a
  new install cannot get past.
  """
  # Step 1. The drawing breaks the title inside one `Text`, and 161 — the same
  # panel renumbered — draws the two halves as two `Text`s off two msgids.
  # Those two joined by the break, rather than a third msgid holding both: the
  # Persian is the two lines 164 drew, یک جا برای over هر چه نگه می‌دارید, and
  # one sentence entered in the catalogue twice is one that drifts.
  def translated("One place for\nwhat you keep"),
    do: gettext("One place for") <> "\n" <> gettext("what you keep")

  def translated(
        "Films, shows, books, habits — each one is a shelf, and all of them feed a single calendar. Start with one and add the rest whenever."
      ) do
    gettext(
      "Films, shows, books, habits — each one is a shelf, and all of them feed a single calendar. Start with one and add the rest whenever."
    )
  end

  def translated("Get started"), do: gettext("Get started")

  # Step 3. 162 draws this question broken after *should* and keeps the break in
  # the msgid — `"How should we\ntell you?"`, whose Persian does its own
  # typesetting and comes back as a single line. 38 draws it unbroken at 26pt
  # and lets the `Text` wrap, so the break comes out here rather than the same
  # question entering the catalogue a second time at a different width.
  # `Kati.Screens.LanguagePick` flattens a heading the same way.
  def translated("How should we tell you?"),
    do: String.replace(gettext("How should we\ntell you?"), "\n", " ")

  def translated(
        "Kati checks for new episodes on its own. You choose how loudly it mentions them."
      ) do
    gettext("Kati checks for new episodes on its own. You choose how loudly it mentions them.")
  end

  def translated("Quietly"), do: gettext("Quietly")
  def translated("Notify me"), do: gettext("Notify me")
  def translated("Weekly digest"), do: gettext("Weekly digest")

  def translated("A card on home. Nothing buzzes."),
    do: gettext("A card on home. Nothing buzzes.")

  def translated("A push when something lands."), do: gettext("A push when something lands.")

  # The digest's day and its hour are inside the msgid, so the translation moves
  # them rather than this screen formatting them: the Persian reads جمعه‌ها
  # ساعت ۱۸:۰۰ — Friday, the quiet end of an Iranian week, in Persian digits.
  # `Kati.Locale.time/1` wants a `Time` and there is none here; the sentence is
  # a promise about a schedule, not a clock this page reads.
  def translated("One summary, Sundays at 18:00."), do: gettext("One summary, Sundays at 18:00.")

  # Step 4.
  def translated("Add your first title"), do: gettext("Add your first title")

  def translated("Pick something you are watching now — the calendar fills itself from there.") do
    gettext("Pick something you are watching now — the calendar fills itself from there.")
  end

  def translated("Finish setup"), do: gettext("Finish setup")
  def translated("Skip — I’ll add things later"), do: gettext("Skip — I’ll add things later")

  # The four starter posters are invented films, not a provider's name, so they
  # translate. Only this drawing still draws them: screen 163, the same panel
  # renumbered, searches TMDB instead, because a first run that shelved one of
  # these put a film nobody can look up in the library (N46).
  def translated("The Long Hollow"), do: gettext("The Long Hollow")
  def translated("Ashfall"), do: gettext("Ashfall")
  def translated("Marram"), do: gettext("Marram")
  def translated("Nightbirds"), do: gettext("Nightbirds")

  def translated(other), do: other

  # The three display headings on this screen all take the same two locale
  # numbers, and the welcome one is where the reason is easiest to see.
  #
  # `Kati.Locale.tracking/1` because the drawing's -0.035em is a Latin habit:
  # Arabic script joins its letters and tracking prises the joins apart, so the
  # mirrors dropped `letter_spacing` rather than mirroring it.
  #
  # `Kati.Locale.pick(1.12, 1.4)` and not `Kati.Locale.leading/1`, which answers
  # 1.95 — a paragraph's leading, far too open for a 32pt heading. 1.4 is the
  # number board 53 settled on for exactly this Text: `Kati.Screens.
  # LanguagePick`'s own 32pt extrabold lead carries `pick(1.12, 1.4)` with the
  # measurement written beside it — *Vazirmatn's ascenders need the second: a
  # 32pt Persian question at 1.12 closes on the line above it*. This title is
  # two lines by construction, so it is the one that would close first.
  #
  # No `max_lines={1}`: the title carries its own break, so capping it at one
  # line would cut *what you keep* off the bottom of the drawing.
  @doc false
  def welcome(w) do
    title = Kati.Screens.Onboarding.translated(w.title)
    body = Kati.Screens.Onboarding.translated(w.body)
    cta = Kati.Screens.Onboarding.translated(w.cta)

    ~MOB"""
    <Column fill_width={true} padding_top={26}>
      {Kati.Screens.Onboarding.steps(1)}
      <Box width={56} height={56} corner_radius={18} background={Palette.ink()} align="center">
        <Box width={13} height={13} corner_radius={7} background={Kati.Theme.accent()} />
      </Box>
      <Spacer size={20} />
      <Text
        text={title}
        text_size={32}
        font_weight="extrabold"
        letter_spacing={Kati.Locale.tracking(-0.035)}
        line_height={Kati.Locale.pick(1.12, 1.4)}
        text_color={:on_surface}
      />
      <Spacer size={14} />
      <Text
        text={body}
        text_size={14.5}
        line_height={Kati.Locale.leading(1.6)}
        text_color={Palette.ink_soft()}
      />
      <Spacer size={24} />
      <Box
        on_tap={{self(), :get_started}}
        fill_width={true}
        height={54}
        corner_radius={27}
        background={Palette.ink_fill()}
        align="center"
      >
        <Text
          text={cta}
          text_size={14.5}
          font_weight="bold"
          text_color={Palette.on_ink()}
          max_lines={1}
        />
      </Box>
    </Column>
    """
  end

  # Four segments, `done` of them filled. The bar says which step you are on
  # without a "3 of 4" anyone has to read.
  @doc false
  def steps(done) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {1..4
         |> Enum.map(fn i -> Kati.Screens.Onboarding.step_bar(i <= done) end)
         |> Enum.intersperse(Kati.Screens.Onboarding.step_gap())}
      </Row>
      <Spacer size={24} />
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
  The rule between two steps, 30pt of air on either side of it.

  This is the one thing on the screen that is literally a separator — a
  thematic break between groups of content — so it is drawn by
  `Kati.Components.MishkaSeparator` rather than by one more `Box`.

  ## `render: :box`, because a stroke is not a hairline

  The component's default is `:divider`, and the bridge maps that to Material3's
  `HorizontalDivider` — which is **not** the
  `Box(fillMaxWidth().height(t).background(c))` this file previously claimed,
  but an antialiased `drawLine`. At this device's 2.6875x a 1dp rule gets a 3px
  canvas and a 2.6875px stroke centred in it, so the last pixel row lands at
  ~69% coverage: one full-width row 4-5/255 lighter than the rest of the rule.
  The drawing specifies a flat 1px line at 10% ink, and no `color` or
  `thickness` reaches it, because the softness lives in the primitive.

  `render: :box` swaps in a filled rect, whose every pixel row carries the whole
  colour:

      <Box fill_width={true} height={1} background={Palette.hairline_strong()}>
        <Spacer size={1} />
      </Box>

  — which is exactly `Box(fillMaxWidth().height(1.dp).background(colour))`, the
  three modifiers this screen wrote by hand before the component existed. The
  `Spacer` is an iOS height workaround; on Android the Box's own `height` pins
  the rule and `MobSpacer` paints nothing.

  The drawing's `rgba(26,25,23,.10)` survives because the colour goes in as an
  ARGB int: `color` is in the renderer's `@color_props` whitelist, so an
  integer passes through `resolve_token/3` untouched and reaches the bridge's
  `colorProp` as a number.

  No `label` — the labelled variant centres text between two weighted lines,
  and this break carries none.
  """
  def divider do
    rule = MishkaSeparator.separator(color: Palette.hairline_strong(), thickness: 1, render: :box)

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={30} />
      {rule}
      <Spacer size={30} />
    </Column>
    """
  end

  # Same two locale numbers as `welcome/1`, whose comment carries the reason.
  # 26pt rather than 32, and the Persian question is short enough to sit on one
  # line, but a reader who has scaled their type up gets the second line and
  # 1.15 would close it on the first.
  @doc false
  def telling(t) do
    title = Kati.Screens.Onboarding.translated(t.title)
    body = Kati.Screens.Onboarding.translated(t.body)

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.Onboarding.steps(3)}
      <Text
        text={title}
        text_size={26}
        font_weight="extrabold"
        letter_spacing={Kati.Locale.tracking(-0.035)}
        line_height={Kati.Locale.pick(1.15, 1.4)}
        text_color={:on_surface}
      />
      <Spacer size={10} />
      <Text
        text={body}
        text_size={13.5}
        line_height={Kati.Locale.leading(1.55)}
        text_color={Palette.ink_soft()}
      />
      <Spacer size={18} />
      {t.options
       |> Enum.map(fn option -> Kati.Screens.Onboarding.option(option) end)
       |> Enum.intersperse(Kati.Screens.Onboarding.option_gap())}
    </Column>
    """
  end

  @doc false
  def option_gap, do: ~MOB"<Spacer size={10} />"

  # The chosen option inverts to ink and carries an accent tick, so the answer
  # is legible without comparing three cards' backgrounds.
  #
  # Both clauses spell their two lines through `translated/1` rather than
  # drawing `option.title` as it arrives, which is what puts the three cards
  # into Persian on `Kati.Screens.LoudnessPrompt` too — that screen reads the
  # same `Kati.Onboarding.Sample.telling/0` and calls this function to draw it,
  # so translating here translates both boards from one place.
  @doc false
  def option(%{selected?: true} = option) do
    title = Kati.Screens.Onboarding.translated(option.title)
    sub = Kati.Screens.Onboarding.translated(option.sub)

    ~MOB"""
    <Row
      fill_width={true}
      background={Palette.ink_fill()}
      corner_radius={20}
      shadow="0 12 24 -14 #E61A1917"
      padding={15}
      align="center"
    >
      {Kati.UI.symbol(option.icon, size: 21, color: Palette.on_ink())}
      <Spacer size={13} />
      <Column weight={1.0}>
        <Text
          text={title}
          text_size={14}
          font_weight="bold"
          text_color={Palette.on_ink()}
          max_lines={1}
        />
        <Spacer size={3} />
        <Text text={sub} text_size={11.5} text_color={Palette.on_ink_count()} max_lines={1} />
      </Column>
      <Spacer size={13} />
      {Kati.Screens.Onboarding.tick(22, 11, 14)}
    </Row>
    """
  end

  def option(option) do
    title = Kati.Screens.Onboarding.translated(option.title)
    sub = Kati.Screens.Onboarding.translated(option.sub)

    ~MOB"""
    <Row
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={15}
      align="center"
    >
      {Kati.UI.symbol(option.icon, size: 21, color: Palette.sub())}
      <Spacer size={13} />
      <Column weight={1.0}>
        <Text text={title} text_size={14} font_weight="bold" text_color={:on_surface} max_lines={1} />
        <Spacer size={3} />
        <Text text={sub} text_size={11.5} text_color={Palette.sub()} max_lines={1} />
      </Column>
    </Row>
    """
  end

  @doc """
  The accent tick that marks a chosen option or a chosen poster.

  `Kati.Components.MishkaThemeIcon` is documented as "a themed container around
  exactly one icon", and that is the whole of what this is: an accent disc with
  a `check` glyph centred in it. The two callers differ only in their numbers —
  22/11 with a 14pt tick beside a selected option, 24/12 with a 15pt tick over a
  selected poster — so they are one function with three arguments rather than
  two copies of one `Box`.

  ## Why the pixels do not move

  With children and no `id`, `theme_icon/2` returns

      %{type: :box,
        props: %{width: size, height: size, align: :center,
                 corner_radius: radius, background: Kati.Theme.accent()},
        children: [glyph]}

  — node for node, key for key, what both call sites wrote by hand.
  `align: :center` and `align="center"` reach the bridge as the same string:
  `align` is in none of the renderer's token whitelists, so an unrecognised atom
  passes through `resolve_token/3` and `:json.encode/1` writes an atom as its
  own name.

  Nothing else in the component runs. `:filled` contributes no gradient layer;
  `skin(:filled, …)` proposes no border, so `put_some/3` leaves `border_color`
  and `border_width` off the node rather than writing nils; no `shadow` and no
  `id` were passed, so neither the shadow key nor the two id markers appear.

  `variant: :filled` with an explicit `color` — the accent — and the glyph is
  passed as a **child** rather than through the `icon` prop for two reasons: the
  shorthand builds a `Text` with no `font_family`, so the Material Symbols
  ligature `"check"` would be typeset as the word, and it sizes the glyph at
  `round(size * 0.55)`, which is 12 on a 22pt disc and 13 on a 24pt one where
  the drawing asks for 14 and 15.

  ## The one colour on this screen that stays a literal

  The tick itself is still `0xFFFBFAF8` rather than a `Kati.Theme.Palette`
  token, and deliberately. Its ground is the **accent**, which is a hue: screen
  28 keeps `#E8823C` at full strength on near-black, so this disc is the same
  orange in both modes. A mark on a ground that does not move must not move
  either — and none of the four tokens that carry `0xFFFBFAF8` says that. `card`
  (`#1E1D1B`), `on_ink` (`#1A1917`) and `fab_glyph` (`#16150F`) would all turn
  the tick near-black over an unchanged orange disc; `on_media` does hold at
  `#FBFAF8`, but it is named and documented for a ground that is a
  **photograph**, and this one is not.

  So the literal stays until the palette has a name for *a mark on a hue*.
  Leaving it is exactly what `on_media` would have painted, in both modes —
  the difference is only that the call site does not claim a meaning the table
  has not agreed to.
  """
  def tick(size, radius, glyph) do
    MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Kati.Theme.accent(), size: size, radius: radius},
      # Not a Palette token: the ground is the accent, a hue that is identical
      # in both modes. See the section above.
      [Kati.UI.symbol("check", size: glyph, color: 0xFFFBFAF8)]
    )
  end

  # Two across, each cell a weight, with an 11pt gap — the design's own
  # `calc(50% - 6px)`.
  #
  # This comment used to call `174 * 2 + 11 = 359` *the content width between
  # the 21pt gutters*, which is the arithmetic the moduledoc and `poster/1`
  # both exist to correct: 359 is what two fixed 174s come to, and the content
  # width on the 411dp device is 369, so that grid stops 10pt short of the
  # right gutter. The 174 was never in the code — `poster/1` has taken a weight
  # all along — so this was a stale sentence over correct code, sitting where a
  # reader would trust it over the two places that did the measuring.
  #
  # Headings: the two locale numbers `welcome/1`'s comment explains.
  @doc false
  def first_title(f) do
    rows = Enum.chunk_every(f.posters, 2)
    title = Kati.Screens.Onboarding.translated(f.title)
    body = Kati.Screens.Onboarding.translated(f.body)
    cta = Kati.Screens.Onboarding.translated(f.cta)
    skip = Kati.Screens.Onboarding.translated(f.skip)

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.Onboarding.steps(4)}
      <Text
        text={title}
        text_size={26}
        font_weight="extrabold"
        letter_spacing={Kati.Locale.tracking(-0.035)}
        line_height={Kati.Locale.pick(1.15, 1.4)}
        text_color={:on_surface}
      />
      <Spacer size={10} />
      <Text
        text={body}
        text_size={13.5}
        line_height={Kati.Locale.leading(1.55)}
        text_color={Palette.ink_soft()}
      />
      <Spacer size={18} />
      {Enum.map(rows, fn row -> Kati.Screens.Onboarding.poster_row(row) end)}
      <Spacer size={9} />
      <Box
        on_tap={{self(), :finish}}
        fill_width={true}
        height={52}
        corner_radius={26}
        background={Palette.ink_fill()}
        align="center"
      >
        <Text
          text={cta}
          text_size={14}
          font_weight="bold"
          text_color={Palette.on_ink()}
          max_lines={1}
        />
      </Box>
      <Spacer size={14} />
      <Box fill_width={true} on_tap={{self(), :finish_skip}}>
        <Text
          text={skip}
          text_size={13}
          font_weight="semibold"
          text_color={Palette.sub()}
          text_align="center"
        />
      </Box>
    </Column>
    """
  end

  @doc false
  def poster_row(row) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {row
         |> Enum.map(fn poster -> Kati.Screens.Onboarding.poster(poster) end)
         |> Enum.intersperse(Kati.Screens.Onboarding.poster_gap())}
      </Row>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc false
  def poster_gap, do: ~MOB"<Spacer size={11} />"

  # The cell takes a weight, not a width. 174 was the drawing's own number at
  # 402pt; on the 411dp device the same two tiles plus the 11pt gap come to 359
  # of the 369 between the gutters and the grid stops short of the right one.
  # The tile's height is `aspect_ratio` — the export's own `aspect-ratio:2/3` —
  # so it follows whatever width the weight hands out, at any frame width.
  #
  # The caption is spelled through `translated/1` and the artwork is not: a
  # poster is a photograph, and `p.seed` is what fetches it, so the picture is
  # the same in both scripts while the name under it is the reader's. Board 166
  # is where that rule is written down — *a Persian run should not put an
  # English name on a Persian shelf* — and `Kati.Screens.OnboardingFirstTitle`
  # keys its own seeds off both spellings for the same reason.
  @doc false
  def poster(p) do
    title = Kati.Screens.Onboarding.translated(p.title)

    ~MOB"""
    <Column weight={1.0}>
      {Kati.Screens.Onboarding.poster_art(p)}
      <Spacer size={8} />
      <Text text={title} text_size={12.5} font_weight="bold" text_color={:on_surface} max_lines={1} />
    </Column>
    """
  end

  @doc false
  def poster_art(%{selected?: true} = p) do
    ~MOB"""
    <Box
      fill_width={true}
      aspect_ratio={0.6667}
      corner_radius={17}
      border_color={Palette.ink()}
      border_width={2.5}
    >
      <Column fill_width={true} fill_height={true} padding={4}>
        <Box
          fill_width={true}
          fill_height={true}
          corner_radius={13}
          background={Palette.placeholder()}
          shadow={Kati.Theme.shadow_card_soft()}
        >
          {Kati.Screens.Onboarding.art(p)}
          <Box fill_width={true} fill_height={true} align="top_trailing">
            <Column padding={9}>
              {Kati.Screens.Onboarding.tick(24, 12, 15)}
            </Column>
          </Box>
        </Box>
      </Column>
    </Box>
    """
  end

  def poster_art(p) do
    ~MOB"""
    <Box
      fill_width={true}
      aspect_ratio={0.6667}
      corner_radius={13}
      background={Palette.placeholder()}
      shadow={Kati.Theme.shadow_card_soft()}
    >
      {Kati.Screens.Onboarding.art(p)}
    </Box>
    """
  end

  @doc false
  def art(p) do
    case Kati.Design.Images.poster(p.seed) do
      nil ->
        ~MOB"<Spacer size={0} />"

      src ->
        ~MOB"""
        <Image src={src} fill_width={true} fill_height={true} corner_radius={13} content_mode="fill" />
        """
    end
  end

  # The last step of the first run, so this is where the flag is written.
  #
  # All three exits finish. The drawing gives this screen **Get started**,
  # **Finish setup** and **Skip — I'll add things later**, and because it draws
  # its three steps stacked rather than one at a time, they are three ways out
  # of the same screen rather than three stages. Skip finishes too: the drawing
  # offers it as a way past adding a title, not a way to abandon setup, and a
  # user who takes it has still chosen a language and their sections.
  #
  # `reset_to/2`, not `push_screen/2`: Home must be the bottom of the stack
  # afterwards. Pushing would leave the whole first run underneath it, and the
  # back gesture from Home would walk the user back into onboarding they have
  # just completed.
  #
  # The root follows the locale chosen on screen 53, so a user who picked
  # فارسی lands on screen 55 and not on an English home page.
  def handle_info({:tap, tag}, socket) when tag in [:get_started, :finish, :finish_skip] do
    Kati.Onboarding.complete!()
    {:noreply, Mob.Socket.reset_to(socket, Kati.Onboarding.first_screen())}
  end

  def handle_info(_message, socket), do: {:noreply, socket}
end
