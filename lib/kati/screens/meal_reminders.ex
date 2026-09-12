defmodule Kati.Screens.MealReminders do
  @moduledoc """
  Screen 51 — meal reminders, pushed under Meals.

  Built to `test/design/screens/51.html`. Both halves of the reminder are
  drawn as the notifications they actually become rather than as settings that
  describe them: a 20:00 preview that lists what to prep, and a 15-minute
  warning before each meal.

  The drawing carries **Eaten / Skip / Snooze** inside that second preview and
  #71 retired all three: Mob has no notification actions on either platform,
  so a drawn button is one that cannot be pressed, and the footnote they were
  the evidence for — *"tick it straight from the notification — no need to
  open the app"* — claimed what the platform cannot keep. What is drawn is
  what is true: tapping opens the meal, and the footnote says plainly that
  Kati cannot put buttons on a notification. `Kati.ScreenDesignLiteralTest`
  holds the ruling in full; `Kati.Meals.SampleReminders` holds the empty
  `actions` list it leaves behind, and `preview_actions/1` is where that
  emptiness is read.

  The evening card is cream and the meal card is white, and the previews inside
  them are grounded to match: `rgba(255,255,255,.6)` over cream, paper over
  card. The label colours follow, `#B09A72` on cream and `#A0998F` on paper,
  which is the palette's rule that cream warms rather than tints.

  **Manners** is the counterweight and belongs on this screen rather than in
  Settings. Meals is the one section allowed to push by default; the price is
  quiet hours, calendar awareness, a stop after two skips, and a silent mode
  that behaves like the release watcher's Home card.

  The option list nested inside the cream card and the Manners list are both
  `Kati.UI.SettingsList` — the same card and row every Settings screen uses,
  so an option under a reminder reads as an option rather than as a second kind
  of thing. Only the row padding differs, 12 inside the card and 13 outside it,
  which is the drawing's own difference.

  ## Nothing in the design opens this screen

  Every other Meals screen is reached from the tile row or the title pill on
  screen 43, and each of those destinations is identifiable because its own
  drawing opens with a `‹ Meals` back pill: 44, 45, 47, 48, 49. This screen
  carries that same pill and has no matching control anywhere. Checked, glyph
  by glyph: 43 draws `calendar_view_week`, `shopping_cart`, `monitoring`,
  `tune`, `unfold_more` and a per-meal `more_horiz` — four tiles, a plan
  picker and a meal's own actions, none of them a bell. 44 draws `edit`,
  `repeat`, `event_available` and `edit_calendar`. 47 draws `ios_share` and
  `lightbulb`. 48 draws `ios_share` and `add`. 49 draws `add`, `more_horiz`
  (screen 50) and the Switching group. 50's only reminder row is the
  *Reminder times* switch under "what travels with it", which is a toggle on
  the export, not a way in. Screen 24 Settings has no Meals row at all — its
  Sections group is Books, Music, Habits, Money — so the usual
  Settings-pushes-a-detail route is not drawn either.

  So the entry point is missing from the **design**, not from the code, and
  the honest state is to leave it: `Kati.Screens.Gallery` reaches it for
  comparison against the drawing, and inventing a row on 43 or on Settings
  would change a resting screen the drawing does not change. When the design
  grows the control, one `handle_tap/2` clause on whichever screen draws it is
  the whole fix.

  No dock, so the frame's bottom inset is 40 rather than 132.
  """
  use Kati.Screens.Pushed, back: "Meals"
  use Gettext, backend: Kati.Gettext

  alias Kati.Meals.SampleReminders
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :reminders, SampleReminders.reminders())

  @doc false
  def content(assigns) do
    r = assigns.reminders

    # The page's own two words, bound out here rather than written into the
    # markup so the `{...}` that draws them stays one readable line.
    #
    # `Reminders` takes the bare msgid rather than a context of its own: screen
    # 43's ⋯ menu offers the same word for the same destination, and two
    # Persians for one page — on two screens a reader meets a tap apart — is
    # the drift a shared msgid prevents. `Kati.Screens.ReleaseWatcher.copy/1`
    # makes the same argument about *Weekly digest*.
    title = gettext("Reminders")
    plan = copy(r.subtitle)

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
        {SettingsList.title(title, plan, nil, :meta_tight)}
        {UI.eyebrow(pgettext("eyebrow", "The day before"))}
        {Kati.Screens.MealReminders.day_before(r.day_before)}
        {UI.eyebrow(pgettext("eyebrow", "On the day"))}
        {Kati.Screens.MealReminders.on_the_day(r.on_the_day)}
        {SettingsList.eyebrow_muted(pgettext("eyebrow", "Manners"))}
        {Kati.Screens.MealReminders.manners(r.manners)}
        {Kati.Screens.MealReminders.note(r.note)}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def day_before(d) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.cream()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={18}
      >
        {Kati.Screens.MealReminders.card_head(d, Palette.gold_icon(), Palette.cream_meta())}
        <Spacer size={15} />
        {Kati.Screens.MealReminders.preview(d.notification, Palette.cream_raise(), Palette.cream_meta(), Palette.cream_sub())}
        <Spacer size={14} />
        {Kati.Screens.MealReminders.options(d.options)}
      </Column>
      <Spacer size={14} />
    </Column>
    """
  end

  @doc false
  def on_the_day(o) do
    foot = copy(o.foot)

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={18}
      >
        {Kati.Screens.MealReminders.card_head(o, Palette.ink(), Palette.muted())}
        <Spacer size={15} />
        {Kati.Screens.MealReminders.preview(o.notification, Palette.paper(), Palette.eyebrow(), Palette.sub())}
        <Spacer size={13} />
        <Row fill_width={true} align="center">
          {Kati.UI.symbol("touch_app", size: 15, color: Palette.tertiary())}
          <Spacer size={8} />
          <Text text={foot} text_size={11.5} text_color={Palette.sub()} weight={1.0} />
        </Row>
      </Column>
      <Spacer size={14} />
    </Column>
    """
  end

  # The cadence line is already upper case in the drawing's own copy — there is
  # no text-transform on it — so it is not upcased here. The capitals stay
  # inside the ENGLISH msgid for the same reason
  # `Kati.Screens.ReleaseWatcher.found_line/1` keeps its own: capitals are a
  # Latin typographic effect and `String.upcase/1` over Persian is a no-op that
  # reads as one.
  #
  # The face asks the STRING rather than being pinned to `mono`, which is what
  # screen 112's notification preview settles for the same slot:
  # `kati_mono.ttf` carries no Persian glyph at all, so `هر روز ساعت ۲۰:۰۰` set
  # in it is handed to Android's own substitute face — a line in a typeface
  # that is not Kati's, beside cards that are.
  @doc false
  def card_head(card, icon_color, cadence_color) do
    title = copy(card.title)
    cadence = copy(card.cadence)

    ~MOB"""
    <Row fill_width={true} align="center">
      {Kati.UI.symbol(card.icon, size: 23, color: icon_color)}
      <Spacer size={13} />
      <Column weight={1.0}>
        <Text
          text={title}
          text_size={14.5}
          font_weight="bold"
          text_color={:on_surface}
          max_lines={1}
        />
        <Spacer size={4} />
        <Text
          text={cadence}
          font_family={Kati.Locale.mono_face(cadence)}
          text_size={10.5}
          text_color={cadence_color}
          max_lines={1}
        />
      </Column>
      <Spacer size={13} />
      {Kati.UI.SettingsList.switch(card.on)}
    </Row>
    """
  end

  @doc """
  A notification, drawn where it will arrive.

  The app icon is the design's own mark — an ink square with an accent dot —
  rather than a bitmap, so it stays crisp at 20pt and needs no asset.

  ## The app line

  `KATI · NOW` and `KATI · 19:15` are composed rather than translated whole,
  which is what `Kati.Screens.MedicationDetail.preview/1` does for the same
  line on screen 112: **KATI** is the app's name and stays Latin in both
  scripts, and the clock beside it is converted, because it is a time the page
  states rather than a word the copy quotes. So the line changes script with
  the reader, and its face has to ask the STRING — `KATI · 19:15` is DM Mono
  and `KATI · ۱۹:۱۵` is not, `kati_mono.ttf` having none of U+06F0–U+06F9 —
  while its `.1em` goes through `Kati.Locale.tracking/1`, letter-spacing being
  a Latin effect that pulls Persian joins apart.
  """
  def preview(n, ground, label_color, body_color) do
    from = copy(n.from)
    title = copy(n.title)
    body = copy(n.body)

    ~MOB"""
    <Column fill_width={true} background={ground} corner_radius={16} padding={14}>
      <Row fill_width={true} align="center">
        {Kati.Screens.MealReminders.app_icon()}
        <Spacer size={9} />
        <Text
          text={from}
          font_family={Kati.Locale.mono_face(from)}
          text_size={9.5}
          letter_spacing={Kati.Locale.tracking(0.1)}
          text_color={label_color}
          max_lines={1}
        />
      </Row>
      <Spacer size={9} />
      <Text text={title} text_size={13.5} font_weight="bold" text_color={:on_surface} />
      <Spacer size={5} />
      <Text
        text={body}
        text_size={12.5}
        line_height={Kati.Locale.leading(1.45)}
        text_color={body_color}
      />
      {Kati.Screens.MealReminders.preview_actions(n)}
    </Column>
    """
  end

  @doc """
  The app's own mark, as a notification's 20pt icon.

  `Kati.Components.MishkaThemeIcon` — "a themed container around exactly one
  icon" — for the same reason `Kati.UI.SettingsList.icon_tile/1` uses it. The
  one icon here is the design's accent dot rather than a glyph, and children
  are explicitly "any node", so the shorthand is not involved either way.

  ## Why the pixels do not move

  With children, an explicit numeric `color`, no `id` and no `on_tap`,
  `theme_icon/2` returns
  `%{type: :box, props: %{width: 20, height: 20, align: :center,
  corner_radius: 6, background: Palette.ink()}, children: [dot]}` — node for
  node what this wrote by hand. `align: :center` and `align="center"` reach the
  bridge as the same string, the gradient layer is empty for `:filled`, and
  the id markers are skipped without an `id`.

  `Palette.ink/0`, not `ink_fill/0`: this is a MARK, the app's own square, and
  it follows the page rather than inverting like a control does. Pinning it
  light would draw a near-black square on a near-black preview — an icon that
  is simply not there. The accent dot on it is a hue and does not move.
  """
  def app_icon do
    Kati.Components.MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Palette.ink(), size: 20, radius: 6},
      [~MOB"<Box width={6} height={6} corner_radius={3} background={Kati.Theme.accent()} />"]
    )
  end

  # A notification with buttons draws them; one with an EMPTY list draws what a
  # notification with no `actions` key at all draws, which is nothing.
  #
  # The head used to be `%{actions: actions}` and matched both, so the meal
  # warning — `actions: []` since #71 retired Eaten / Skip / Snooze — drew a
  # 12pt spacer and an empty `Row` under its body: a gap held open for three
  # buttons that are never coming, and 12pt of it between the two cards that
  # sit side by side. The spacer belongs to the buttons, so it goes with them.
  @doc false
  def preview_actions(%{actions: [_first | _rest] = actions}) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={12} />
      <Row fill_width={true} align="center">
        {actions
         |> Enum.with_index()
         |> Enum.map(fn {label, i} -> Kati.Screens.MealReminders.preview_action(label, i == 0) end)
         |> Enum.intersperse(Kati.Screens.MealReminders.action_gap())}
      </Row>
    </Column>
    """
  end

  def preview_actions(_notification), do: ~MOB"<Spacer size={0} />"

  @doc false
  def action_gap, do: ~MOB"<Spacer size={7} />"

  # The label goes through `copy/1` like every other word on the page. Nothing
  # reaches here today — `Kati.Meals.SampleReminders` gives the one card that
  # has an `actions` key an empty list — and a button the sample grows back
  # would otherwise be the one control on a Persian page still in English.
  @doc false
  def preview_action(label, primary?) do
    bg = if primary?, do: Palette.ink_fill(), else: Palette.card()
    fg = if primary?, do: Palette.on_ink(), else: Palette.ink_soft()
    text = copy(label)

    ~MOB"""
    <Box weight={1.0}>
      <Box fill_width={true} height={30} corner_radius={15} background={bg} align="center">
        <Text text={text} text_size={11.5} font_weight="semibold" text_color={fg} max_lines={1} />
      </Box>
    </Box>
    """
  end

  @doc false
  def options(rows), do: SettingsList.card(Kati.Screens.MealReminders.switch_rows(rows, 12))

  @doc false
  def manners(rows) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card(Kati.Screens.MealReminders.switch_rows(rows, 13))}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def switch_rows(rows, pad) do
    last = length(rows) - 1

    rows
    |> Enum.with_index()
    |> Enum.map(fn {row, i} ->
      SettingsList.row(
        SettingsList.icon_tile(row.icon),
        SettingsList.body(copy(row.title), copy(row.sub)),
        SettingsList.switch(row.on),
        padding: pad,
        rule: i < last
      )
    end)
  end

  # Not SettingsList.note/2: that one pads 16 and sets its glyph at 18, and
  # this drawing says 15 and 17. FIDELITY's rule is that a number in the export
  # is a number here, so the frame is redrawn rather than approximated.
  @doc false
  def note(text) do
    body = copy(text)

    ~MOB"""
    <Row
      fill_width={true}
      corner_radius={18}
      border_color={Palette.border()}
      border_width={1.5}
      padding={15}
      align="top"
    >
      {Kati.UI.symbol("info", size: 17, color: Palette.sub())}
      <Spacer size={11} />
      <Text
        text={body}
        text_size={12.5}
        line_height={Kati.Locale.leading(1.55)}
        text_color={Palette.ink_soft()}
        weight={1.0}
      />
    </Row>
    """
  end

  # ── The sample's sentences, said in the reader's own language ───────────────

  # `Kati.Meals.SampleReminders` holds every word this page draws — the plan
  # name, both card titles and cadences, both notifications, the six switch
  # rows and the footnote — as English LITERALS, and a literal in another file
  # is the one thing `gettext/1` cannot reach: a msgid has to be at the call
  # site, and `gettext(row.title)` does not compile. The sample keeps the
  # drawing's own copy, which is what it is for — `test/design/screens/51.html`
  # is compared against it line by line — and this is where it is said.
  # `Kati.Screens.ReleaseWatcher.copy/1` is the same arrangement over the same
  # kind of store, and carries the argument at more length.
  #
  # A context on the short labels and none on the sentences: `mix gettext.merge`
  # fuzzy-matches anything under about three words onto any sentence it
  # resembles, and *Quiet hours* is a msgid twice over already — the medication
  # reminder's row and the release watcher's loudness group — with a different
  # Persian in each. This row is a reminder's, so it takes the reminder's word.
  #
  # Every figure goes through `Kati.Locale.number/1` or `Kati.Locale.time/1`
  # rather than being spelled into the Persian, so `20:00` is ۲۰:۰۰ without a
  # translator carrying a digit. The quiet-hours range is one msgid with two
  # holes rather than a join, because Persian puts a WORD where the drawing
  # puts an en dash, and a screen that concatenates has already decided.
  #
  # `ngettext/4` nowhere: every count here is the drawing's own frozen figure —
  # 15 minutes, 5 meals, 2 skips — and none of them is ever 1, which is the
  # reading `Kati.Screens.ReleaseWatcher.copy/1` takes of `2 days before` for
  # the same reason. Persian does not inflect a noun after a numeral anyway.
  defp copy("Cutting v3"), do: gettext("Cutting v3")

  defp copy("Evening preview"), do: gettext("Evening preview")

  defp copy("EVERY DAY AT 20:00"),
    do: gettext("EVERY DAY AT %{time}", time: Kati.Locale.time(~T[20:00:00]))

  defp copy("KATI · NOW"),
    do: "KATI · " <> pgettext("the clock on a notification that has just arrived", "NOW")

  defp copy("Tomorrow: 5 meals, 2 need prep") do
    gettext("Tomorrow: %{meals} meals, %{prep} need prep",
      meals: Kati.Locale.number(5),
      prep: Kati.Locale.number(2)
    )
  end

  defp copy("Soak the oats tonight and move the chicken to the fridge."),
    do: gettext("Soak the oats tonight and move the chicken to the fridge.")

  defp copy("List what needs prep"), do: gettext("List what needs prep")

  defp copy("Only meals with an overnight step"), do: gettext("Only meals with an overnight step")

  defp copy("Flag missing ingredients"), do: gettext("Flag missing ingredients")

  defp copy("Cross-checked with the shopping list"),
    do: gettext("Cross-checked with the shopping list")

  defp copy("At each meal"), do: pgettext("the title of the per-meal warning", "At each meal")

  defp copy("15 MIN BEFORE · 5 TIMES A DAY") do
    gettext("%{minutes} MIN BEFORE · %{times} TIMES A DAY",
      minutes: Kati.Locale.number(15),
      times: Kati.Locale.number(5)
    )
  end

  defp copy("KATI · 19:15"), do: "KATI · " <> Kati.Locale.time(~T[19:15:00])

  defp copy("Dinner in 15 minutes"),
    do: gettext("Dinner in %{minutes} minutes", minutes: Kati.Locale.number(15))

  # Both halves are msgids the catalogue already holds — board 43 draws this
  # meal and this figure in its own timeline — so the line is composed from the
  # two rather than opening a third that would have to be translated again and
  # could then disagree with them. The separator is the drawing's own, and sits
  # between two runs of the reader's script in either language.
  defp copy("Miso salmon, greens, rice · 620 kcal") do
    gettext("Miso salmon, greens, rice") <>
      " · " <> gettext("%{count} kcal", count: Kati.Locale.number(620))
  end

  defp copy("Tap it to open tonight's meal — Kati cannot put buttons on a notification"),
    do: gettext("Tap it to open tonight's meal — Kati cannot put buttons on a notification")

  defp copy("Quiet hours"), do: pgettext("the meal reminder's quiet-hours row", "Quiet hours")

  defp copy("23:00 – 06:30 · nothing fires") do
    gettext("%{from} – %{to} · nothing fires",
      from: Kati.Locale.time(~T[23:00:00]),
      to: Kati.Locale.time(~T[06:30:00])
    )
  end

  defp copy("Skip when busy"), do: gettext("Skip when busy")

  defp copy("No nudge during a calendar event"), do: gettext("No nudge during a calendar event")

  defp copy("Stop after 2 skips"), do: gettext("Stop after %{n} skips", n: Kati.Locale.number(2))

  defp copy("Stays quiet for the rest of the day"),
    do: gettext("Stays quiet for the rest of the day")

  defp copy("Or keep it silent"), do: gettext("Or keep it silent")

  defp copy("Home card only, like the release watcher"),
    do: gettext("Home card only, like the release watcher")

  # Matched on its opening clause rather than on the whole paragraph, so the
  # sample and the msgid cannot drift apart over a comma and leave the footnote
  # silently English — `Kati.Screens.ReleaseWatcher.note/1` is the same match
  # for the same reason.
  defp copy("Meals are the one section" <> _rest) do
    gettext(
      "Meals are the one section allowed to push by default — a reminder that arrives " <>
        "after dinner is worthless. Every other section stays quiet unless you ask."
    )
  end

  # A string this screen does not know, drawn as it is stored. Every clause
  # above is `Kati.Meals.SampleReminders`', and a row added there tomorrow must
  # not take the whole page down with a `FunctionClauseError` — the fallback
  # `Kati.Screens.ReleaseWatcher.copy/1` keeps, for the same reason.
  defp copy(other), do: other
end
