defmodule Kati.Screens.Accessibility do
  @moduledoc """
  Screen 41 — Accessibility, pushed under Settings.

  Built to `test/design/screens/41.html`. The design's caption calls it
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
  `:spec`, so the thumb moves and the track swaps between ink and `#DCD7CF`.
  It **snaps** rather than slides — a node tree is a still frame and Mob has no
  animation primitive, so the thumb is at one offset in this render and the
  other in the next. That was true of the hand-drawn switch this screen used to
  carry and it is true of `Kati.Components.MishkaSwitch`'s drawn mode; only the
  native Material `Switch` tweens, and it does so at metrics this drawing does
  not use. The resting state is the sample's own, so the resting screen is
  unchanged — five on, **Increase contrast** off.

  **Increase contrast** is the one that does more than flip itself, because it
  is the only row whose subtitle names a visible effect: *"Hairlines darken,
  shadows drop"*. Turning it on darkens this screen's rules and takes the lift
  off its cards, which is the row keeping its own promise. Nothing else here
  claims a consequence this screen can show — **Dynamic Type** in particular
  is deliberately inert, see `toggle/1`.

  ## Audited: drawn copy, with no stored state anywhere behind it

  **Every string on this screen is `Kati.Accessibility.Sample`, and no resource
  in the app holds any of it.** The design's caption is the reason and not an
  excuse — this is *the spec drawn rather than described*, so the six rows are
  claims Kati makes about itself, not settings a user keeps:

    * The **Up next card** is a specimen, deliberately frozen even though
      `Kati.Screens.UpNext` reads a real one from `Kati.Media`. Its whole job is
      to render one known card at 235% so `.scratch/design/audit/41.png` can be
      compared, and the **VoiceOver reads** quotation below it spells that same
      episode out — *"Episode 6, The Undertow. 55 minutes. Airs 20 August."* — as
      fixed prose. Swapping the card for the user's own title would leave the
      quotation naming a different episode, and a screen that contradicts itself
      is a worse accessibility spec than a frozen one.
    * The **six switches** are guarantees, not preferences. *Touch targets ·
      Nothing under 44×44* and *Colour is never alone* are properties of every
      other screen in the app; there is nothing for a stored boolean to change.
      **Reduce motion** is the one that reads like a setting and still is not:
      Mob has no animation primitive — a node tree is a still frame, as the
      section above says — so there are no cross-fades to ask for. The device's
      own accessibility settings own these, and reading them needs a platform
      bridge (`Mob.Device`) rather than a resource.

  So a flip here is honestly local: it moves a thumb, and **Increase contrast**
  additionally darkens this screen's own rules. Nothing is stored because
  nothing would read it, and there is no resource to name.

  ## Under `:fa` the sample is a set of KEYS, and `spec_text/1` is the seam

  mishka-group/kati#103 folded the 33 Persian mirrors away, so this module is
  now the Persian screen as well as the English one. The sample did not move
  with it: `Kati.Accessibility.Sample` still holds `test/design/screens/41.html`'s
  own English, and `spec_text/1` — one clause per string, at the leaf — is the
  only place a guarantee becomes a word somebody reads. That split is not
  tidiness. `contrast?/1` matches a row by its title, so the sample's
  `"Increase contrast"` is a key as much as a label, and a sample that
  translated itself would leave the switch flipping and the hairlines no
  longer following it.

  The numbers and the one date go the same way and are the part a catalogue
  cannot do: `235%` is ۲۳۵٪, `44×44` is ۴۴×۴۴, and *Airs 20 August* is
  *پخش ۲۹ مرداد* — the same day, counted in the calendar the reader keeps.
  `voiceover_line/0` is where the quotation is rebuilt, and its own doc says
  why a frozen quotation is still not a Latin one.
  """
  use Kati.Screens.Pushed, back: "Settings"
  use Gettext, backend: Kati.Gettext

  alias Kati.Accessibility.Sample
  alias Kati.Components.MishkaSeparator
  alias Kati.Components.MishkaSwitch
  alias Kati.Components.MishkaThemeIcon
  alias Kati.Theme.Palette
  alias Kati.UI

  # The air date the VoiceOver quotation names, as a DATE rather than as the
  # two words `20 August`. It is `Kati.Library.Sample`'s own episode 6 —
  # `aired_episode(6, gettext("The Undertow"), 55, ~D[2026-08-20])` — which is
  # the episode this screen's specimen card is drawing, so the two cannot
  # disagree about which day it is. A Persian reader keeps a different
  # calendar, and `20 August` is a Gregorian instruction: `voiceover_line/0`
  # asks `Kati.Locale` for the day and the month instead, so the same instant
  # reads `20 August` in Latin and ۲۹ مرداد in Persian.
  #
  # A module attribute is safe here where one holding `gettext/1` would not
  # be: a `Date` is not a translation and freezes nothing in the compiler's
  # locale.
  @airs ~D[2026-08-20]

  # The two strings from `Kati.Accessibility.Sample` too long to read inside a
  # function head, written out here so `spec_text/1` has a literal to match on.
  # Both hold the sample's ENGLISH, which is a key rather than a translation —
  # so the compile-time freeze that makes `gettext/1` in a module attribute a
  # bug does not apply here: nothing in either is locale-dependent, and the
  # words that are come off `spec_text/1` at render.
  @note "At the largest sizes, rows become stacks and icon-only buttons grow " <>
          "labels. Nothing truncates — cards get taller instead."

  @reads "“Episode 6, The Undertow. 55 minutes. Airs 20 August. Not watched. " <>
           "Double-tap to mark watched.”"

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :spec, Sample.spec())

  @doc false
  def content(assigns) do
    spec = assigns.spec
    contrast? = Kati.Screens.Accessibility.contrast?(spec)

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {Kati.Screens.Accessibility.header(contrast?)}
        {Kati.Screens.Accessibility.title(spec)}
        {Kati.Screens.Accessibility.up_next(spec, contrast?)}
        {Kati.Screens.Accessibility.note(spec)}
        {UI.eyebrow(gettext("Built in"))}
        {Kati.Screens.Accessibility.built_in(spec, contrast?)}
        {Kati.Screens.Accessibility.quiet_eyebrow(gettext("VoiceOver reads"))}
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

  ## The title compared here is a KEY, and stays English

  `Kati.Accessibility.Sample` is the BOARD written out, in the board's own
  English, and it stays that way: `spec_text/1` is the only place a guarantee
  becomes a word the reader can read, and it runs at the leaf. So this
  comparison is against `"Increase contrast"` in both scripts, which is what
  keeps the contrast row's consequence attached to the contrast row under
  `:fa`.

  `Kati.Screens.Library.chip_counts/1` carries the long version of the
  argument, because the shelf already paid for it: its four filters were one
  string doing both jobs, so the Persian shelf's filter was «همه» and every
  clause of `matching/2` fell through. Translating the sample would break this
  function the same way, and just as quietly — the switch would still flip,
  and only the hairlines would stop following it.
  """
  @spec contrast?(map()) :: boolean()
  def contrast?(spec) do
    Enum.any?(spec.built_in, fn row -> row.title == "Increase contrast" and row.toggle end)
  end

  @doc """
  The reader's own word for a string `Kati.Accessibility.Sample` hands over.

  The sample is the BOARD written out — `test/design/screens/41.html`'s own
  copy, in the board's own English — and it stays that way, for the reason
  `contrast?/1` gives: what travels out of it is a KEY as well as a word, and
  a key that translated itself would move this screen's one consequence off
  the row that promises it. `Kati.Screens.AnimeFilter.sample_text/1` is the
  same split one board over, and carries the long version of the argument.

  So the sample keeps the English and this is the only place that turns one
  into a sentence. Five of these clauses do more than look a word up, because
  five of the board's strings carry a number or a date a Persian reader counts
  differently:

    * the sub-line and the **Dynamic Type** row both state `235%`, and both
      take `Kati.Locale.number/1` — ۲۳۵٪, with U+066A, which is what
      *Follows system · up to 235%* already draws one screen up in
      `Kati.Settings.Sample`.
    * **Touch targets** states `44×44`. That is a measurement, so it is a
      number the reader reads rather than a figure the design sets.
    * the Up next card's meta block is `Season 2, episode 6` over
      `18 minutes left` — two sentences in one `Text`. They are two msgids
      joined by the newline rather than one msgid containing it, because a
      `\\n` inside a msgid is the first thing a translation loses.
    * the VoiceOver quotation names an air date; `voiceover_line/0` owns it.

  A string with no clause of its own comes back untouched. A seventh guarantee
  added to the sample tomorrow then draws in English rather than raising,
  which is the right failure for a design fixture to have: `mix gettext.extract`
  reads literal call sites and could not have a msgid for it either way.
  """
  @spec spec_text(String.t()) :: String.t()
  def spec_text("Dynamic Type at 235%"),
    do: gettext("Dynamic Type at %{n}%", n: Kati.Locale.number(235))

  # The eyebrow on the specimen card is the shelf's own word for the same
  # section, so it takes the shelf's own msgid rather than a second one:
  # `Kati.Screens.Library` already draws *Up next*, and one word written twice
  # is one word that can be translated two ways. Same for the show's name,
  # which `Kati.Library.Sample` has carried in Persian since it was folded —
  # the specimen must be the same title the rest of the app spells.
  def spec_text("Up next"), do: gettext("Up next")
  def spec_text("The Long Hollow"), do: gettext("The Long Hollow")

  def spec_text("Season 2, episode 6\n18 minutes left") do
    gettext("Season %{s}, episode %{e}", s: Kati.Locale.number(2), e: Kati.Locale.number(6)) <>
      "\n" <> gettext("%{n} minutes left", n: Kati.Locale.number(18))
  end

  # `pgettext/2` for the two buttons, and both times because of a near
  # neighbour rather than an ambiguity in the word itself. `mix gettext.merge`
  # fuzzy-matches a new msgid against the catalogue: `Resume` sits two edits
  # from `Remove` and `Rename`, and `Mark watched` sits one word from
  # `Mark next watched`, `Mark all` and `Mark eaten` — so it would arrive here
  # carrying «قسمت بعدی را دیده‌ام», marked fuzzy, on the button that marks
  # this one.
  def spec_text("Resume"), do: pgettext("the Up next card’s primary button", "Resume")

  def spec_text("Mark watched"),
    do: pgettext("the Up next card’s secondary button", "Mark watched")

  def spec_text(@note),
    do:
      gettext(
        "At the largest sizes, rows become stacks and icon-only buttons grow labels. Nothing truncates — cards get taller instead."
      )

  # The six guarantees, in the sample's order. `Reduce motion` is deliberately
  # a plain `gettext/1` and not a context: `Kati.Settings.Sample` declares that
  # exact msgid for the switch one screen up, and this row is a claim about the
  # same behaviour. The other five sit beside it in one list, so they take the
  # same plain form — contexting half a list is how one list comes back in two
  # voices.
  def spec_text("VoiceOver"), do: gettext("VoiceOver")

  def spec_text("Every control labelled · posters described"),
    do: gettext("Every control labelled · posters described")

  def spec_text("Dynamic Type"), do: gettext("Dynamic Type")

  def spec_text("Up to 235% · no truncation"),
    do: gettext("Up to %{n}% · no truncation", n: Kati.Locale.number(235))

  def spec_text("Reduce motion"), do: gettext("Reduce motion")

  def spec_text("Cross-fades instead of slides"), do: gettext("Cross-fades instead of slides")

  def spec_text("Increase contrast"), do: gettext("Increase contrast")

  def spec_text("Hairlines darken, shadows drop"), do: gettext("Hairlines darken, shadows drop")

  def spec_text("Touch targets"), do: gettext("Touch targets")

  def spec_text("Nothing under 44×44"),
    do: gettext("Nothing under %{w}×%{h}", w: Kati.Locale.number(44), h: Kati.Locale.number(44))

  def spec_text("Colour is never alone"), do: gettext("Colour is never alone")

  def spec_text("Every dot has a label or icon"), do: gettext("Every dot has a label or icon")

  # The sample writes this one uppercase because the drawing does. The msgid is
  # the words in their own case and `Kati.UI.eyebrow_label/1` — in `voiceover/1`,
  # where the other eyebrow label gets it too — does the upcasing, so the
  # catalogue holds a phrase a translator can read and Persian is spared a
  # transformation that does nothing to it.
  #
  # `pgettext/2` because `Episode row` is one edit from `Episode order`, which
  # is already in the catalogue as a back-pill label.
  def spec_text("EPISODE ROW"), do: pgettext("the VoiceOver quotation’s label", "Episode row")

  def spec_text(@reads), do: Kati.Screens.Accessibility.voiceover_line()

  def spec_text(other), do: other

  @doc """
  The sentence VoiceOver speaks, with its numbers and its date rebuilt.

  The sample writes it as fixed prose and the moduledoc says why: the card
  above quotes one known episode, and a quotation naming a different one is a
  worse accessibility spec than a frozen one. Frozen is not the same as Latin,
  though — every figure in it is read aloud to a person, so every figure is
  the reader's own. `Episode 6` and `55 minutes` take `Kati.Locale.number/1`,
  the episode's name takes `Kati.Library.Sample`'s own msgid, and `20 August`
  is asked for as a day and a month rather than written, so a Persian reader
  gets ۲۹ مرداد — the same day, counted in the calendar they keep.

  `Kati.Locale.quoted/1` rather than the sample's own `“…”`: Persian meets the
  Latin marks as foreign, and writes a quotation in guillemets. The whole
  sentence is a quotation, which is exactly what that function is for.

  ## One msgid, not five

  The parts are interpolated into a single sentence rather than concatenated,
  because the order of them is not the same in the two scripts and a
  translator needs to be able to move the date inside the sentence. `%{day}`
  and `%{month}` are separate for the same reason — `Kati.Locale.date/2` has
  no style that gives a full month name and no weekday, which is the shape
  this sentence wants, so `Kati.Screens.LogWeight.taken_line/0`'s composition
  is the one followed here.
  """
  @spec voiceover_line() :: String.t()
  def voiceover_line do
    Kati.Locale.quoted(
      gettext(
        "Episode %{n}, %{title}. %{minutes} minutes. Airs %{day} %{month}. Not watched. Double-tap to mark watched.",
        n: Kati.Locale.number(6),
        title: gettext("The Undertow"),
        minutes: Kati.Locale.number(55),
        day: Kati.Locale.day_of_month(@airs),
        month: Kati.Locale.month_name(@airs)
      )
    )
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
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} height={44} align="center">
        <Spacer weight={1.0} />
        {Kati.Screens.Accessibility.disc("more_horiz", contrast?)}
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  The 44pt floating disc opposite the back pill, lifted unless contrast is on.

  `Kati.Components.MishkaThemeIcon` — "a themed container around exactly one
  icon", which is what a disc is. It could not be one until the container took a
  `shadow`, and on this screen that prop earns its place twice over: a disc is
  *defined* by floating, **and** the lift is one of the two things **Increase
  contrast** switches off, so the shadow has to be a value this function can
  compute rather than a constant baked into a component.

  ## The `nil` shadow stays absent, which is what `lift/2` wants

  `lift/2` returns `nil` rather than a zeroed shadow string, and `theme_icon/2`
  routes `shadow` through `put_some/3`, whose first clause drops a `nil`. So a
  contrast-on disc carries **no `shadow` key at all**, where the hand-rolled
  `<Box shadow={nil}>` carried the key with a nil value. Both draw nothing: the
  bridge's `shadowLayers/1` opens with `props["shadow"] as? String ?: return
  null`, and even when the serialised `"nil"` string reaches it, the split on
  `|` yields one field where five are required, `mapNotNull` drops it and
  `layers.ifEmpty { null }` returns null. The component's form is the cleaner of
  the two and paints the same nothing.

  ## Why the pixels do not move

  With children and no `id`, `theme_icon/2` returns

      %{type: :box,
        props: %{width: 44, height: 44, align: :center, corner_radius: 22,
                 background: Palette.card(), shadow: Kati.Theme.shadow_button()},
        children: [glyph]}

  — key for key what the `<Box>` above it carried (`Palette.card/0` is
  `0xFFFBFAF8` in light, which is what that `<Box>` wrote), minus the `shadow`
  key in the contrast-on case as described. `align: :center` and `align="center"` reach the
  bridge as the same string: `align` is in none of the renderer's token
  whitelists, and `:json.encode/1` writes an atom as its own name.

  Nothing else in the component runs: `:filled` has no gradient layer,
  `skin(:filled, …)` proposes no border so both border keys are omitted rather
  than nil, and the id markers are skipped without an `id`. The glyph is a child
  rather than the `icon` prop because that shorthand builds a `Text` with no
  `font_family`, and the ligature `"more_horiz"` would be typeset as the word.
  """
  def disc(icon, contrast?) do
    MishkaThemeIcon.theme_icon(
      %{
        variant: :filled,
        # `card`, not `on_ink` / `fab_glyph` / `on_media` — the other three
        # meanings `Kati.Theme.Palette` gives `0xFFFBFAF8`. A disc is a surface
        # floating above the page, so it follows the ground into `#1E1D1B`.
        color: Palette.card(),
        size: 44,
        radius: 22,
        shadow: Kati.Screens.Accessibility.lift(Kati.Theme.shadow_button(), contrast?)
      },
      [Kati.UI.symbol(icon, size: 21)]
    )
  end

  @doc false
  def title(spec) do
    # The mono sub-line is `Dynamic Type at 235%` and it is the reader's own
    # script once `spec_text/1` has it, so the face is asked for rather than
    # named: `kati_mono.ttf` carries no Persian glyph and none of U+06F0–U+06F9,
    # so `font_family="mono"` here would hand the whole line to Android's own
    # substitute face — legible, correctly shaped, and in a typeface that is
    # not Kati's, which is the failure `Kati.PersianFontTest` exists to catch.
    # `mono_face/1` rather than `mono_face/0` so a sub-line that is still Latin
    # — an untranslated locale falling back to the msgid — keeps DM Mono.
    subtitle = Kati.Screens.Accessibility.spec_text(spec.subtitle)

    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={gettext("Accessibility")}
        text_size={28}
        max_font_scale={1.6}
        font_weight="bold"
        letter_spacing={Kati.Locale.tracking(-0.03)}
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer size={5} />
      <Text
        text={subtitle}
        font_family={Kati.Locale.mono_face(subtitle)}
        text_size={11}
        text_color={Palette.muted()}
        max_lines={1}
      />
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  The muted eyebrow: the design's `#C4BDB3` dash instead of the accent.

  Everything except that dash is now `Kati.UI.eyebrow/2`'s, value for value,
  and deliberately so — the two sit eleven points apart on this screen, and an
  eyebrow that was 11pt semibold in Vazirmatn above the switch list while its
  twin below was 10.5pt in DM Mono would read as two different section marks
  rather than one, loud and one quiet. `Kati.UI.eyebrow/2` cannot simply be
  called: it always draws the accent dash, which is the one thing this variant
  exists to change.

  The four things the fold changed here, all of them that function's answers:

    * `Kati.UI.eyebrow_label/1` rather than `String.upcase/1`. Persian has no
      case, so upcasing it is a no-op that reads as one.
    * `Kati.Locale.mono_face/1` rather than `"mono"`. `kati_mono.ttf` carries
      no Persian glyph at all, so Android substitutes its own face for the one
      label — `Kati.PersianFontTest`'s moduledoc is where that failure is
      written down.
    * `Kati.Locale.tracking/1` rather than a bare `0.16`. Letter spacing pulls
      Arabic-script letters apart at the joins, which is a different word.
    * the size and weight, which Vazirmatn needs a step of at this size.
  """
  def quiet_eyebrow(label) do
    drawn = Kati.UI.eyebrow_label(label)

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        <Box width={13} height={2} corner_radius={1} background={Palette.rail_idle()} />
        <Spacer size={9} />
        <Text
          text={drawn}
          font_family={Kati.Locale.mono_face(drawn)}
          text_size={Kati.Locale.pick(10.5, 11)}
          font_weight={Kati.Locale.pick("normal", "semibold")}
          letter_spacing={Kati.Locale.tracking(0.16)}
          text_color={Palette.eyebrow()}
          max_lines={1}
        />
      </Row>
      <Spacer size={11} />
    </Column>
    """
  end

  # No max_lines anywhere in this card: the whole demonstration is that text
  # wraps and the card grows rather than the words being cut. That is also why
  # the screen's own 28pt heading took a `max_lines={1}` in this round and this
  # card's 30pt one did not — they are opposite claims about the same font
  # scale, and only one of them is this card's.
  #
  # The two-line meta block takes `Kati.Locale.leading/1` and the 30pt title
  # does not. The title's `1.2` is already `Kati.Theme.fa_line_height/0` — the
  # value that constant declares for Persian — so it needs nothing; the meta
  # block's `1.35` at 22pt is a Latin measurement, and Vazirmatn's descenders
  # at that size meet the line under them. Opening the block is the correct
  # consequence on the one card whose promise is that it grows instead of
  # cutting.
  @doc false
  def up_next(spec, contrast?) do
    u = spec.up_next
    shadow = Kati.Screens.Accessibility.lift(Kati.Theme.shadow_card_soft(), contrast?)

    label = Kati.UI.eyebrow_label(Kati.Screens.Accessibility.spec_text(u.label))
    lines = Kati.Screens.Accessibility.spec_text(u.lines)

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={shadow}
        padding={18}
      >
        <Text
          text={label}
          font_family={Kati.Locale.mono_face(label)}
          text_size={12}
          letter_spacing={Kati.Locale.tracking(0.16)}
          text_color={Palette.eyebrow()}
        />
        <Spacer size={12} />
        <Text
          text={Kati.Screens.Accessibility.spec_text(u.title)}
          text_size={30}
          font_weight="bold"
          letter_spacing={Kati.Locale.tracking(-0.02)}
          line_height={1.2}
          text_color={:on_surface}
        />
        <Spacer size={10} />
        <Text
          text={lines}
          text_size={22}
          line_height={Kati.Locale.leading(1.35)}
          text_color={Palette.ink_soft()}
        />
        <Spacer size={18} />
        <Box
          fill_width={true}
          height={60}
          corner_radius={30}
          background={Palette.ink_fill()}
          align="center"
        >
          <Row align="center">
            {Kati.UI.symbol("play_arrow", size: 26, color: Palette.on_ink(), fill: true)}
            <Spacer size={10} />
            <Text
              text={Kati.Screens.Accessibility.spec_text(u.resume)}
              text_size={19}
              font_weight="bold"
              text_color={Palette.on_ink()}
            />
          </Row>
        </Box>
        <Spacer size={10} />
        <Box
          fill_width={true}
          height={60}
          corner_radius={30}
          background={Palette.paper()}
          align="center"
        >
          <Row align="center">
            {Kati.UI.symbol("check", size: 24)}
            <Spacer size={10} />
            <Text
              text={Kati.Screens.Accessibility.spec_text(u.mark)}
              text_size={19}
              font_weight="bold"
              text_color={:on_surface}
            />
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
      <Row fill_width={true} background={Palette.cream()} corner_radius={18} padding={15} align="top">
        {Kati.UI.symbol("info", size: 18, color: Palette.gold_icon())}
        <Spacer size={11} />
        <Text
          text={Kati.Screens.Accessibility.spec_text(spec.note)}
          text_size={12.5}
          line_height={Kati.Locale.leading(1.55)}
          text_color={Palette.cream_body()}
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
        background={Palette.card()}
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
          <Text
            text={Kati.Screens.Accessibility.spec_text(row.title)}
            text_size={13.5}
            font_weight="semibold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={3} />
          <Text
            text={Kati.Screens.Accessibility.spec_text(row.sub)}
            text_size={11.5}
            text_color={Palette.sub()}
            max_lines={1}
          />
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
  corner_radius: 9, background: Palette.paper()}, children: [glyph]}` — node for
  node what this row wrote by hand, so nothing moves. `align: :center` and
  `align="center"` reach the bridge as the same string.
  """
  def icon_tile(name) do
    MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Palette.paper(), size: 30, radius: 9},
      [Kati.UI.symbol(name, size: 17, color: Palette.ink_soft())]
    )
  end

  @doc """
  The design's own switch, as `Kati.Components.MishkaSwitch` in `render: :box`.

  46x28 with a 22pt thumb and a 3pt inset — the drawing's numbers, passed
  rather than rebuilt. `thumb_offset/4` owns the placement and resolves to
  -9 off and +9 on, which is the 3..25 / 21..43 span the 40pt inner Row and
  its weighted Spacers used to produce.

  This doc used to say the component "cannot be used", because it wrapped
  Mob's `Toggle` — Compose's Material `Switch`, fixed at 52x32 with a handle
  that grows from 16 to 24. That is still true of `render: :toggle`, and it is
  why the default stays there; it stopped being true of this screen when
  `render: :box` landed, and the claim is retracted rather than left standing.

  ### The one thing the drawn mode costs, on the screen that can least afford it

  A native `Switch` carries a role, an on/off state and a toggle action into
  TalkBack. A pair of boxes carries none of it, and this is the accessibility
  screen. The trade is taken anyway, and narrowly: the row — not the switch —
  is what `row/4` makes tappable, and the row is a `Column` holding the
  guarantee's title and subtitle as real `Text` nodes, so what a screen reader
  lands on and announces is unchanged either way. What is lost is the *state*
  announcement, which the drawn track cannot carry and which the native switch
  could only have carried at 52x32 — a different drawing.

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
    MishkaSwitch.switch(
      render: :box,
      checked: on?,
      track_width: 46,
      track_height: 28,
      track_radius: 14,
      thumb_size: 22,
      thumb_radius: 11,
      thumb_inset: 3,
      # The whole control inverts rather than following the ground — `ink_fill`
      # under `on_ink`, the pair screen 28 draws for the hero's CTA pill. Both
      # thumb colours stay ONE token, because the drawing's thumb does not
      # change colour, only the track does, and that stays true in dark.
      track_on_color: Palette.ink_fill(),
      track_off_color: Palette.track_off(),
      thumb_on_color: Palette.on_ink(),
      thumb_off_color: Palette.on_ink(),
      thumb_shadow: "0 1 3 0 #4D1A1917"
    )
  end

  @doc """
  The sentence VoiceOver speaks, printed on ink.

  This card is the screen's one inverted surface, and in dark it inverts back:
  `ink_fill` is `#F7EFE4` there and `on_ink_glyph` — the palette's own name for
  a mark on an ink card "where the ground is already inverted" — is `#1A1917`.
  So a dark quotation on a light card becomes a light quotation on a dark one,
  which is what screen 28 does with the hero's CTA pill.

  `0xFF6A6560` is **left as a literal**; see the comment on it below.
  """
  def voiceover(spec) do
    v = spec.voiceover

    # `0xFF6A6560` LEFT AS A LITERAL. It is in `Kati.Theme.Palette` three times
    # and every one of them is a DARK value — `muted`, `segment_idle` and
    # `tertiary` all land on it — so no token resolves to it in light, and any
    # token that names this meaning (`on_ink_meta` is the closest, "the mono
    # meta step on an ink fill") carries a different light value and would move
    # the baseline. This screen draws a dark card inside a light drawing and
    # reaches for a dark-mode neutral to label it; the table has no light row to
    # answer with. Left as it is, and reported. On the inverted `#F7EFE4` card
    # this still reads at about 4.8:1, so the unchanged value is not a hole.
    meta = 0xFF6A6560

    label = Kati.UI.eyebrow_label(Kati.Screens.Accessibility.spec_text(v.label))

    ~MOB"""
    <Column fill_width={true} background={Palette.ink_fill()} corner_radius={20} padding={17}>
      <Text
        text={label}
        font_family={Kati.Locale.mono_face(label)}
        text_size={10}
        letter_spacing={Kati.Locale.tracking(0.14)}
        text_color={meta}
        max_lines={1}
      />
      <Spacer size={10} />
      <Text
        text={Kati.Screens.Accessibility.spec_text(v.reads)}
        text_size={13.5}
        line_height={Kati.Locale.leading(1.6)}
        text_color={Palette.on_ink_glyph()}
      />
    </Column>
    """
  end

  @doc """
  The rule between two guarantee rows, darkened once contrast is on.

  `0x12` is the drawing's 7% rule. `0x38` is the darkened one the **Increase
  contrast** row promises — the same ink, roughly tripled in weight, rather than
  a second colour.

  The rule itself is `Kati.Components.MishkaSeparator`, which is what a 1px
  hairline between rows IS, and `render: :box` is what makes it draw one.

  ## Why `render: :box`, and why it matters more on this screen than anywhere

  The component's default `:divider` maps to Material3's `HorizontalDivider`,
  which is **not** `Box(fillMaxWidth().height(t).background(c))` as this file
  previously claimed but an antialiased `drawLine`. At this device's 2.6875x a
  1dp rule is handed a 3px canvas and a 2.6875px stroke centred in it, so its
  last pixel row lands at ~69% coverage: one full-width row 4-5/255 lighter than
  the two above it.

  On a screen whose fourth guarantee is about contrast, a hairline that quietly
  loses a third of its weight on one row is the wrong bug to ship. `render:
  :box` swaps the stroke for a filled rect, every pixel row of which carries the
  whole colour:

      <Box fill_width={true} height={1} background={0x121A1917}>
        <Spacer size={1} />
      </Box>

  — the same three modifiers this file wrote by hand before it adopted the
  component. The `Spacer` is an iOS workaround for `MobBox` dropping a Box's
  `height` when it has no `width`; on Android the Box's own `height` pins the
  rule and `MobSpacer` is a bare sized `Spacer` with no background.

  Both colours are passed as ARGB ints, so the drawing's own alphas survive:
  `color` is in the renderer's `@color_props` whitelist and an integer is handed
  to `colorProp` untouched.
  """
  def hairline(false, _contrast?), do: ~MOB"<Spacer size={0} />"

  def hairline(true, contrast?) do
    # `track_ink` is the 22% step of the ink-tint ladder — right by value, and
    # the name is the one part of it that is wrong: the palette calls `0x38`
    # a track because that is where the design's other 22% ink appears. What
    # matters here is that it is the same ladder `hairline` sits on, so it takes
    # the same alpha-swap in dark (`0x38F5F2EE`) and the darkened rule stays a
    # rule. Left as `0x381A1917` it would be 22% BLACK on a `#1E1D1B` card in
    # dark — the row that promises darker hairlines drawing none at all.
    color = if contrast?, do: Palette.track_ink(), else: Palette.hairline()

    MishkaSeparator.separator(color: color, thickness: 1, render: :box)
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
