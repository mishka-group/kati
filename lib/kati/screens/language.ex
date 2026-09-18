defmodule Kati.Screens.Language do
  @moduledoc """
  Screen 54 — Language, pushed under Settings.

  Built to `test/design/screens/54.html`. The design's caption states the
  idea: *"language is one switch that carries five settings with it, each still
  overridable. The row that matters most is the last one: nothing you typed
  yourself ever gets rewritten."*

  Three parts, in that order of consequence: the picker, the five settings the
  choice drags along, and then Content — which is a footnote to the language
  rather than a peer of it, so its eyebrow takes the grey dash from
  `Kati.UI.SettingsList.eyebrow_muted/1` and not the accent one.

  ## Persian rows are drawn in Vazirmatn

  `فا`, `فارسی` and `ایران` are the picker's own copy, and two rows below mix
  Persian into an English sentence. Plus Jakarta Sans carries neither Arabic
  glyphs nor Arabic-Indic digits, so those five strings take
  `font_family="fa"` — Vazirmatn, which Kati ships at 400–800 and which covers
  Latin as well, so the English half of a mixed line still reads. The rows
  carry `script: :fa` in `Kati.Language.Sample` rather than the screen
  guessing from the characters.

  The flag still says the right thing after the fold, for a reason worth
  writing down: at `:fa` those two rows are Persian *throughout* rather than
  mixed, so they want Vazirmatn twice over. The picker's Latin row wants the
  opposite and now says so — `language_body/1` pins `sans` on it, because at
  `:fa` the root's face is Vazirmatn and **English** was being set in the face
  of the language it is offered as the alternative to.

  ## The picker is the real switch, not a highlight

  `Kati.Locale` owns the active locale, so this screen sets it rather than
  duplicating it. `Kati.Locale.put/1` writes `Mob.State`, which is a named
  GenServer over a DETS table — process-independent, app-wide and synced to
  disk before the call returns — so writing it from a screen is safe and
  survives the screen dying on the next root switch. The picker therefore
  reads its selection from `Kati.Locale.current/0` and not from
  `Kati.Language.Sample`'s `on:` flag, which is now the stand-in it always
  said it was: at `:en`, the default, the two agree exactly and the resting
  frame is 54.html unchanged.

  Choosing a language then **opens the interface in it**, because setting the
  locale alone would not: `Kati.Shell.roots/0` is a static list of the English
  roots, and the eight Persian mirrors hang off `Kati.Screens.Fa.roots/0`
  instead. So `:fa` pushes `Kati.Screens.Home` under `:fa` — board 55, whose dock
  then reaches 56, 57 and 61 — and `:en` pushes `Kati.Screens.Home`.

  Pushed, not `reset_to/2`, and that is a judgement rather than the obvious
  reading. A language change really does relaunch an interface at its root,
  which argues for a reset; but there is no Persian language picker (no
  `LanguageFa`, and nothing pushes `Kati.Screens.SettingsFa` from anywhere),
  so a reset would clear the only stack that still contains this screen and
  strand the user in Persian with no drawn way back. Pushing keeps 54
  underneath, where the hardware back button reaches it. **The strand still
  arrives one tap later** — the Persian dock switches roots with `reset_to/2`,
  which empties the history — and closing that needs a route into this screen
  from the Persian side, which is not this file's to add.

  No dock — this is a pushed screen — so the frame closes at 40, not 132. The
  header is the back pill alone, with nothing opposite it, so the chrome row
  reserves the pill's height and draws no disc.

  ## What mishka-group/kati#103 translated here, and what it left alone

  Everything on this screen that is ordinary copy goes through `Kati.Gettext`
  now — the title and its subtitle, the three eyebrows, the dashed row, the
  eight settings and the closing promise. `Kati.Language.Sample` keeps the
  drawing's own English, because a literal in another file is the one thing
  `gettext/1` cannot reach — a msgid has to be at the call site, and
  `gettext(row.title)` does not compile — so `copy/1` at the bottom of this
  file is where the sample's sentences are said. `Kati.Screens.MealReminders`
  is the same arrangement over the same kind of store and argues it at length.

  **The two picker rows stay literal.** `En / English / United Kingdom` and
  `فا / فارسی / ایران` are the specimens a reader is choosing *between*, and a
  catalogue answers in the locale the reader arrived with — so a Persian
  install would have offered them *انگلیسی* and no way to tell what it was
  offering. `Kati.Screens.LanguagePick` leaves its two option rows alone for
  the same reason and carries the longer version of the argument. The Latin
  row pins `sans` as of this round for the other half of it: see
  `language_body/1`.

  **Three of the eight rows say the opposite thing in Persian**, and the
  catalogue is where that flip lives rather than a branch here. A reader at
  `:fa` is looking at a right-to-left page whose dates really are Shamsi —
  `Kati.Locale.date/2` converts — and whose numerals really are Persian, so
  *Left to right · set by English* is a sentence about somebody else's app.
  `Kati.Screens.MealPlan.week_note/0` is the precedent: one msgid, English
  naming Monday and Persian naming شنبه, because the two are different facts
  rather than one fact translated.

  ## Audited: the locale is stored; the eight rows under it are drawn copy

  The picker is the app's real setting and is read and written above.
  **Everything below it is `Kati.Language.Sample`, and no resource in the app
  holds any of it** — the five *Follows the language* rows, the three *Content*
  rows and the closing promise are the design's words about a locale's
  consequences.

  None of the eight carries an `on_tap`, including the *Title language* switch,
  and by this file's own invariant — the tags a screen draws are the choices it
  can still make — that is the screen saying so rather than a control that lost
  its handler. Each names a preference the app does not keep: `Kati.Locale`
  stores the locale and derives the writing direction from it and nothing else,
  so a calendar system, a numeral set, a week start, a time format, whether
  original titles show, units and currency have nowhere to be written. They
  belong on `Kati.Locale` as stored overrides — the row's own word is
  *overridable*, and `Kati.Theme.Mode` is the shape one takes — rather than in a
  domain: they are preferences, not rows. `Writing direction` is the exception
  that never becomes a setting, and the drawing already says so by printing
  `auto` where the other four print an arrow.
  """
  use Kati.Screens.Pushed, back: "Settings"
  use Gettext, backend: Kati.Gettext

  alias Kati.Language.Sample
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @impl true
  def load(socket) do
    Mob.Socket.assign(socket, heading: Sample.heading(), locale: Kati.Locale.current())
  end

  @doc false
  def content(assigns) do
    h = assigns.heading
    locale = assigns.locale

    # Said in the reader's own language before the sigil rather than inside it,
    # which is the arrangement `copy/1` describes: the sample's English is the
    # KEY and the drawn word is the reader's, and the two must never be mistaken
    # for each other — `tap/1` used to match on one of them.
    title = copy(h.title)
    subtitle = copy(h.subtitle)
    interface_label = copy(h.interface_label)
    follows_label = copy(h.follows_label)
    content_label = copy(h.content_label)

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {SettingsList.chrome(nil, 44)}
        {SettingsList.title(title, subtitle, nil, :meta_tight)}
        {UI.eyebrow(interface_label)}
        {Kati.Screens.Language.picker(locale)}
        {UI.eyebrow(follows_label)}
        {Kati.Screens.Language.group(Kati.Language.Sample.follows(), 24)}
        {SettingsList.eyebrow_muted(content_label)}
        {Kati.Screens.Language.group(Kati.Language.Sample.content(), 24)}
        {Kati.Screens.Language.note()}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def picker(locale) do
    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(Kati.Language.Sample.languages(), fn l ->
         Kati.Screens.Language.language(l, Kati.Screens.Language.locale_of(l) == locale)
       end)}
      {Kati.Screens.Language.add_language()}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  Which locale a picker row stands for.

  `Kati.Language.Sample` already carries `script:` — it has to, so a row can
  choose its typeface — and the two rows it draws are exactly the two locales
  `Kati.Locale.supported/0` returns, so nothing further is needed to tell them
  apart. A third installed language would need its own key on that data and a
  third locale to point it at; neither exists, and the dashed "Add a language"
  row below the picker is where that would start.
  """
  @spec locale_of(map()) :: :en | :fa
  def locale_of(%{script: :fa}), do: :fa
  def locale_of(_row), do: :en

  @doc false
  def choose_tag(row) do
    String.to_atom("choose_language_" <> Atom.to_string(Kati.Screens.Language.locale_of(row)))
  end

  # The selected card carries the drawing's inset 2pt ink ring. Two clauses
  # rather than a conditional border, because `border_width` and `border_color`
  # are opt-in as a pair in this bridge and a nil colour draws a black hairline
  # rather than nothing.
  #
  # The ring is `ink`, not `ink_fill`: it is a mark drawn ON the card, not a
  # control filled with ink, so it takes the ink ramp's dark twin rather than
  # the CTA pill's inversion. Same call `Kati.Screens.Onboarding.poster_art/1`
  # makes for its selected 2.5pt ring.
  #
  # The selected row carries no `on_tap`, which is the drawing's own decision
  # and is kept: choosing the language you are already in is not a choice. It
  # also means `:choose_language_en` can only ever be sent from a `:fa` app and
  # vice versa.
  @doc false
  def language(l, true) do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        border_width={2}
        border_color={Palette.ink()}
        padding={14}
        align="center"
      >
        {Kati.Screens.Language.code_tile(l)}
        <Spacer size={13} />
        {Kati.Screens.Language.language_body(l)}
        <Spacer size={13} />
        {Kati.Screens.Language.selected_mark()}
      </Row>
      <Spacer size={10} />
    </Column>
    """
  end

  def language(l, false) do
    # The tag carries which language it is, so one handler serves every row and
    # a new locale is a data change rather than a code change.
    tap = {self(), Kati.Screens.Language.choose_tag(l)}

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={14}
        align="center"
        on_tap={tap}
      >
        {Kati.Screens.Language.code_tile(l)}
        <Spacer size={13} />
        {Kati.Screens.Language.language_body(l)}
        <Spacer size={13} />
        {Kati.Screens.Language.unselected_mark()}
      </Row>
      <Spacer size={10} />
    </Column>
    """
  end

  @doc """
  The 38pt paper tile every picker row leads with.

  `Kati.Components.MishkaThemeIcon` — "a themed container around exactly one
  icon" — rather than a fourth hand-rolled `Box`, which is the same call
  `Kati.UI.SettingsList.icon_tile/1` makes one size down. The three rows this
  screen draws above the card all lead with this tile, so it is one function
  and the "Add a language" row shares it.

  ## Why the pixels do not move

  With children, an explicit numeric `color`, no `id` and no `on_tap`,
  `theme_icon/2` returns
  `%{type: :box, props: %{width: 38, height: 38, align: :center,
  corner_radius: 12, background: Palette.paper()}, children: [child]}` — node
  for node what this wrote by hand. `align: :center` and `align="center"` reach
  the bridge as the same string. Nothing else in the component runs: the
  `icon` shorthand is skipped when children are given, `:filled`'s gradient
  layer is empty, and the id markers need an `id`.

  The glyph is passed as a child rather than through the `icon` prop for the
  reason `SettingsList` gives — the shorthand builds a `Text` with no
  `font_family`, which would typeset a Material Symbols ligature as words and,
  here, would lose Vazirmatn on `فا` entirely.
  """
  def tile(child) do
    Kati.Components.MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Palette.paper(), size: 38, radius: 12},
      [child]
    )
  end

  @doc false
  def code_tile(%{script: :fa} = l) do
    Kati.Screens.Language.tile(~MOB"""
    <Text
      text={l.code}
      font_family="fa"
      text_size={15}
      font_weight="bold"
      text_color={:on_surface}
      max_lines={1}
    />
    """)
  end

  # `Kati.Locale.mono_face/1` rather than the literal, and deliberately the
  # arity that asks the STRING's script rather than the reader's: `En` is ASCII,
  # DM Mono has every glyph it needs, and the tile keeps DM Mono in both
  # languages — which is what 54.html draws. So nothing this clause draws today
  # moves, and the `فا` tile is the clause above's anyway.
  #
  # What it buys is the row that does not exist yet. `locale_of/1` says a third
  # installed language would start at "Add a language"; the day one arrives with
  # a code `kati_mono.ttf` has no glyph for and a `script:` this file does not
  # know, the tile asks the code itself instead of drawing boxes — the same
  # question `Kati.Screens.DataSources.body/2` asks of a provider's name.
  def code_tile(l) do
    Kati.Screens.Language.tile(~MOB"""
    <Text
      text={l.code}
      font_family={Kati.Locale.mono_face(l.code)}
      text_size={13}
      text_color={:on_surface}
      max_lines={1}
    />
    """)
  end

  @doc """
  The 24pt ink disc that marks the language you are in.

  Also `MishkaThemeIcon`: radius 12 at size 24 is an exact circle, and the
  component's own `:circle`-shaped siblings resolve theirs the same way. Its
  unfilled partner is `unselected_mark/0`, which is now the same component.

  `ink_fill`, not `ink`: this is a control *filled* with ink and carrying an
  `on_ink` glyph, so in dark it inverts the way screen 28's CTA pill does —
  paper fill, ink tick — rather than becoming a near-white disc with a
  near-white tick on it.
  """
  def selected_mark do
    Kati.Components.MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Palette.ink_fill(), size: 24, radius: 12},
      [Kati.UI.symbol("check", size: 15, color: Palette.on_ink())]
    )
  end

  @doc """
  The empty 24pt ring on a language you are **not** in.

  `MishkaThemeIcon` as of this round. 54.html draws it
  `width:24px;height:24px;border-radius:12px;border:1.5px solid
  rgba(26,25,23,.16)` — a hairline with no fill, at a fractional width — and
  the component used to reach a border only through `variant: :outline`,
  which forfeits the fill and hard-codes the width at 1. `border_color` and
  `border_width` are caller overrides on every variant now, so `:subtle`
  (which paints neither a background nor a border of its own) carries exactly
  the two the drawing specifies and nothing else.

  ## Why the pixels do not move

  `put_some/3` drops a nil, so `:subtle`'s absent background is absent from
  the node rather than a JSON `null`; with no `id`, no `icon` and no `on_tap`
  the id markers, the glyph shorthand and the handler are all skipped, and the
  gradient layer is empty for anything but `:gradient`. The node is
  `%{type: :box, props: %{width: 24, height: 24, align: :center,
  corner_radius: 12, border_color: Palette.border(), border_width: 1.5},
  children: []}` — the `Box` written here by hand, plus an `align` that a
  childless box has nothing to apply.

  The 1.5 survives because the bridge reads `border_width` through
  `floatProp`; `intProp` — which is what `padding` and `max_lines` get — would
  have truncated it to 1.
  """
  def unselected_mark do
    Kati.Components.MishkaThemeIcon.theme_icon(%{
      variant: :subtle,
      size: 24,
      radius: 12,
      border_color: Palette.border(),
      border_width: 1.5
    })
  end

  @doc false
  def language_body(%{script: :fa} = l) do
    ~MOB"""
    <Column weight={1.0}>
      <Text
        text={l.name}
        font_family="fa"
        text_size={15}
        font_weight="bold"
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer size={3} />
      <Text
        text={l.region}
        font_family="fa"
        text_size={12}
        text_color={Palette.sub()}
        max_lines={1}
      />
    </Column>
    """
  end

  # The Latin row PINS `sans` rather than inheriting the root's face, which is
  # the same prop `Kati.Screens.LanguagePick.name/2` pins and for the same
  # reason. Under `:fa` the root is Vazirmatn — `Kati.Locale.face_prop/0` — so
  # **English** and **United Kingdom** were set in the typeface of the language
  # the reader would be leaving them for: a specimen drawn in the other
  # specimen's face, on the one screen whose entire subject is which script you
  # read. An explicit prop beats the root's default, and at `:en` it names the
  # face the row already had.
  #
  # `Kati.Locale.tracking/1` deliberately does NOT appear here: the row is Latin
  # whatever the reader is, so there is no Persian in it for tracking to break.
  def language_body(l) do
    ~MOB"""
    <Column weight={1.0}>
      <Text
        text={l.name}
        font_family="sans"
        text_size={14}
        font_weight="bold"
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer size={3} />
      <Text
        text={l.region}
        font_family="sans"
        text_size={11.5}
        text_color={Palette.sub()}
        max_lines={1}
      />
    </Column>
    """
  end

  # Solid, not dashed: `Modifier.border` takes a width and a colour and no
  # PathEffect. The 1.5pt weight and the alpha are the drawing's own.
  @doc false
  def add_language do
    a = Sample.add_language()
    tap = {self(), :add_language}
    # Copy, not specimens: the row names three languages Kati does not install,
    # in the reader's own words. The two rows ABOVE it are the specimens, and
    # they stay literal — see the moduledoc.
    title = copy(a.title)
    sub = copy(a.sub)

    ~MOB"""
    <Row
      fill_width={true}
      corner_radius={20}
      border_width={1.5}
      border_color={Palette.border()}
      padding={14}
      align="center"
      on_tap={tap}
    >
      {Kati.Screens.Language.tile(Kati.UI.symbol("add", size: 18, color: Palette.sub()))}
      <Spacer size={13} />
      <Column weight={1.0}>
        <Text
          text={title}
          text_size={14}
          font_weight="bold"
          text_color={Palette.sub()}
          max_lines={1}
        />
        <Spacer size={3} />
        <Text text={sub} text_size={11.5} text_color={Palette.sub()} max_lines={1} />
      </Column>
      <Spacer size={13} />
      {Kati.UI.SettingsList.chevron()}
    </Row>
    """
  end

  @doc false
  def group(rows, gap) do
    last = length(rows) - 1

    body =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, i} -> Kati.Screens.Language.row(row, i < last) end)

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(body)}
      <Spacer size={gap} />
    </Column>
    """
  end

  # `Currency` is the one row here that leads somewhere: screen 125 is the
  # screen the moduledoc says did not exist, and it holds the only preference in
  # this list that Kati actually stores. Every other row still carries no
  # `on_tap`, for the reason given above.
  @doc false
  def row(row, rule?) do
    SettingsList.row(
      SettingsList.icon_tile(row.icon),
      Kati.Screens.Language.body(row),
      Kati.Screens.Language.control(row.control),
      padding: 13,
      rule: rule?,
      on_tap: Kati.Screens.Language.tap(row)
    )
  end

  # Routed off the row's ICON rather than off its title, as of the fold.
  #
  # The title is drawn copy now — `copy/1` says it in the reader's language —
  # and `tap("Currency")` was a label being used as state. `Kati.Settings.Sample`
  # is where that goes next: its rows already call `gettext/1` on their own
  # titles, and the day `Kati.Language.Sample` does the same, a match on the
  # English word stops matching and the one row on this screen that leads
  # anywhere goes quietly dead — nothing raises, nothing fails, the row just
  # stops opening screen 125. A Material Symbols ligature is a glyph name and is
  # never translated, so it cannot go the same way.
  @doc false
  def tap(%{icon: "payments"}), do: {self(), :open_currency}
  def tap(_row), do: nil

  # Vazirmatn for the two rows whose second line carries Persian — see the
  # moduledoc. The title stays in the body face; only the line with the glyphs
  # in it changes font.
  @doc false
  def body(%{script: :fa} = row) do
    title = copy(row.title)
    sub = copy(row.sub)

    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={title}
        text_size={13.5}
        font_weight="semibold"
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer size={3} />
      <Text text={sub} font_family="fa" text_size={11.5} text_color={Palette.sub()} max_lines={1} />
    </Column>
    """
  end

  def body(row), do: SettingsList.body(copy(row.title), copy(row.sub))

  @doc false
  def control(:chevron), do: SettingsList.chevron()
  def control({:switch, on?}), do: SettingsList.switch(on?)

  # `Kati.Locale.mono_face/1` rather than the literal `mono`. The one value this
  # screen draws is a WORD — `auto`, and خودکار in Persian — and
  # `kati_mono.ttf` carries no Persian glyph, so DM Mono would hand it to
  # Android's substitute face and print it in a typeface that is not Kati's,
  # beside a row that is. Asked of the STRING rather than of the reader, so a
  # value that stays ASCII keeps DM Mono in both languages and 54.html does not
  # move.
  def control({:value, text}) do
    value = copy(text)

    ~MOB"""
    <Text
      text={value}
      font_family={Kati.Locale.mono_face(value)}
      text_size={11}
      text_color={Palette.muted()}
      max_lines={1}
    />
    """
  end

  # `Kati.Locale.leading/1` on the one paragraph this screen sets. 1.55 is the
  # drawing's Latin leading and Vazirmatn's metrics are not Plus Jakarta's, so a
  # three-line Persian promise set at 1.55 closes on itself — the same call
  # `Kati.UI.SettingsList.note/2` makes for the pill this note is drawn by hand
  # as. A no-op at `:en`.
  @doc false
  def note do
    text = copy(Sample.note())

    ~MOB"""
    <Row
      fill_width={true}
      corner_radius={18}
      border_width={1.5}
      border_color={Palette.border()}
      padding={15}
      align="top"
    >
      {Kati.UI.symbol("info", size: 17, color: Palette.sub())}
      <Spacer size={11} />
      <Text
        text={text}
        text_size={12.5}
        line_height={Kati.Locale.leading(1.55)}
        text_color={Palette.ink_soft()}
        weight={1.0}
      />
    </Row>
    """
  end

  @impl true
  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "choose_language_" <> code ->
        {:noreply, choose(code, socket)}

      "open_currency" ->
        {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Currency)}

      # `:add_language` lands here. 53.html and 54.html between them draw two
      # installed languages and `Kati.Locale.supported/0` returns two; there is
      # no drawn screen behind "Arabic, Turkish, German…" and no third locale
      # for it to install. Left tappable but inert rather than untapped, so the
      # row keeps the press feedback the drawing's control implies — and inert
      # through the catch-all, so it no longer raises into `rescue_tap/3`.
      _ ->
        {:noreply, socket}
    end
  end

  # `String.to_existing_atom/1` would do, and would raise on a tag this screen
  # did not write. Matching against `Kati.Locale.supported/0` cannot raise and
  # cannot name a locale the app does not have, which is the same check
  # `Kati.Locale.put/1` guards on — done here so the guard is never the thing
  # that fails.
  defp choose(code, socket) do
    locale = Enum.find(Kati.Locale.supported(), &(Atom.to_string(&1) == code))

    if locale && locale != socket.assigns.locale do
      Kati.Locale.put(locale)

      # Assigned before the push: `Mob.Screen` saves *this* socket onto the nav
      # history, so backing out of the Persian shell returns to a picker that
      # already shows فارسی selected and — via `Kati.Screens.Pushed.chrome/2`,
      # which reads the direction at render — already draws right to left.
      socket
      |> Mob.Socket.assign(:locale, locale)
      |> Mob.Socket.push_screen(shell_root(locale))
    else
      socket
    end
  end

  # One root in both languages since mishka-group/kati#103: `Kati.Screens.Home`
  # reads `Kati.Locale` for its direction, its face and every word on it, so
  # the choice made here is a choice of LOCALE and not of module.
  # `Kati.Onboarding.shell_root/1` is the same answer, and this is a private
  # copy of it for the reason the function above states.
  defp shell_root(_locale), do: Kati.Screens.Home

  # ── The sample's sentences, said in the reader's own language ───────────────

  # `Kati.Language.Sample` holds every word this page draws — the heading, the
  # three eyebrows, the dashed row, the eight settings and the closing promise —
  # as English LITERALS, and a literal in another file is the one thing
  # `gettext/1` cannot reach: a msgid has to be at the call site, and
  # `gettext(row.title)` does not compile. The sample keeps the drawing's own
  # copy, which is what it is for, and this is where it is said.
  # `Kati.Screens.MealReminders.copy/1` is the same arrangement over the same
  # kind of store.
  #
  # A context on the short labels and none on the sentences: `mix gettext.merge`
  # fuzzy-matches anything under about three words onto any sentence it
  # resembles. `Calendar`, `Language`, `Units` and `Currency` are common labels
  # and take the plain msgid on purpose — `Calendar` and `Language` are already
  # in the catalogue off `Kati.Screens.Pushed.back_vocabulary/0` with exactly
  # the Persian this row wants, and a second msgid would be the app naming one
  # thing twice.
  #
  # **Four of these say the opposite thing in Persian.** The writing direction,
  # the calendar, the numerals and the week's first day are facts the app really
  # holds at `:fa` — `Kati.Locale` derives the direction, `Kati.Locale.date/2`
  # really does return Shamsi, `Kati.Locale.number/1` really does return ۰۱۲۳,
  # `Kati.Locale.week_start/0` really does answer شنبه — so a literal
  # translation of *Left to right · set by English* would be a sentence about
  # somebody else's app, arriving in the reader's own language, which is the
  # worst of the outcomes available: legible enough that nobody files it. The
  # flip lives in the catalogue rather than in a branch here, exactly as
  # `Kati.Screens.MealPlan.week_note/0` puts it — one msgid, the English naming
  # Monday and the Persian naming شنبه, because the two are different FACTS
  # rather than one fact translated.
  defp copy("Language"), do: gettext("Language")

  defp copy("Changes apply instantly"), do: gettext("Changes apply instantly")

  defp copy("Interface language"), do: pgettext("eyebrow", "Interface language")

  defp copy("Follows the language"), do: pgettext("eyebrow", "Follows the language")

  defp copy("Content"), do: pgettext("eyebrow", "Content")

  defp copy("Add a language"), do: gettext("Add a language")

  # The three are languages Kati does not install, named in the reader's own
  # words — copy, not the specimens the two rows above it are.
  defp copy("Arabic, Turkish, German…"), do: gettext("Arabic, Turkish, German…")

  defp copy("Writing direction"), do: pgettext("language setting", "Writing direction")

  defp copy("Left to right · set by English"), do: gettext("Left to right · set by English")

  # The one row of the eight that prints a value instead of a chevron, because
  # the direction is derived rather than chosen — the moduledoc's own point. A
  # `pgettext/2`: four letters would be fuzzy-matched onto any sentence that
  # resembled them.
  defp copy("auto"), do: pgettext("the derived value on the writing-direction row", "auto")

  defp copy("Calendar"), do: gettext("Calendar")

  defp copy("Gregorian · Shamsi available"), do: gettext("Gregorian · Shamsi available")

  defp copy("Numerals"), do: pgettext("language setting", "Numerals")

  # The two digit runs are the SPECIMEN and stay out of the catalogue, so a
  # translator cannot spell `1234` in the numerals it is there to contrast with.
  # `Kati.Locale.ltr/1` on the Latin one: it sits inside a Persian sentence at
  # `:fa`, and a neutral beside it — the separator — otherwise resolves against
  # the paragraph and lands at the wrong edge. A no-op at `:en`.
  defp copy("Latin 1234 · or Persian ۰۱۲۳") do
    gettext("Latin %{latin} · or Persian %{persian}",
      latin: Kati.Locale.ltr("1234"),
      persian: "۰۱۲۳"
    )
  end

  defp copy("Week starts"), do: pgettext("language setting", "Week starts")

  # The leading day comes off `Kati.Locale.week_start/0` rather than out of the
  # sentence, because it is the one half of this row the app actually answers —
  # `Kati.Screens.PickSections.follows_note/0` asks it the same way, and board
  # 137 is where both get the claim. `Monday` at `:en`, which is 54.html.
  defp copy("Monday · Saturday in فارسی") do
    gettext("%{day} · Saturday in فارسی", day: Kati.Locale.week_start())
  end

  defp copy("Time format"), do: pgettext("language setting", "Time format")

  # 24 through `Kati.Locale.number/1` rather than spelled into the Persian, so
  # the figure is ۲۴ without a translator carrying a digit — the rule
  # `Kati.Screens.MealReminders.copy/1` keeps for every number it draws.
  defp copy("24-hour") do
    pgettext("the time format a language carries", "%{n}-hour", n: Kati.Locale.number(24))
  end

  defp copy("Title language"), do: pgettext("language setting", "Title language")

  defp copy("Show original titles alongside"), do: gettext("Show original titles alongside")

  defp copy("Units"), do: gettext("Units")

  defp copy("Metric · grams and millilitres"), do: gettext("Metric · grams and millilitres")

  defp copy("Currency"), do: gettext("Currency")

  # LEFT IN LATIN. `£` and `GBP` are a currency symbol and an ISO 4217 code, and
  # a code is a name a machine gave itself — the same reading `Kati.Locale.year/1`
  # takes of a publication year and `Kati.Locale.mono_face/1` takes of a
  # provider's name. `Kati.Money` writes both, screen 125 is where they are
  # chosen, and a transliterated `GBP` would spell one thing two ways.
  #
  # Wrapped, though: at `:fa` it is a Latin run inside a right-to-left page, and
  # without the isolate the symbol resolves to the wrong side of its own code.
  # The clause that did this was `copy("£ GBP")` — a literal, on a row that taps
  # through to `Kati.Screens.Currency`, which writes the key the line now reads.
  # It is the catch-all below that wraps it now, because the line is whichever
  # currency the reader chose and there is no literal to match.
  defp copy("Your own words" <> _rest) do
    gettext(
      "Your own words — notes, list names, meal titles — are never translated. " <>
        "Only the interface changes."
    )
  end

  # A string this screen does not know, drawn as it is stored. Every clause
  # above is `Kati.Language.Sample`'s, and a row added there tomorrow must not
  # take the whole page down with a `FunctionClauseError` — the same fallback
  # `Kati.Screens.MealReminders.copy/1` keeps, for the same reason. It also
  # catches the two picker rows, which never reach here: they are specimens and
  # are drawn straight off the sample.
  defp copy(other) do
    if other == Kati.Language.Sample.currency_line() do
      Kati.Locale.ltr(other)
    else
      other
    end
  end
end
