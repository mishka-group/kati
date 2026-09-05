# The settings a Persian install has and an English one does not

> **Mixed — seven new artboards and one edit to 62** · ticket `D-55`

A Persian reader taps the settings row on خانه — `Kati.Screens.HomeFa` answers `:open_settings`
by pushing `Kati.Screens.SettingsFa` (`home_fa.ex:1063`) — and lands on board 62, whose first
group is the one the board's own caption calls the one every other setting depends on:
*"The Language group sits first, because in a bilingual app it is the setting every other one
depends on."* Four rows. زبان says فارسی · راست به چپ with a **تغییر** button; تقویم says شمسی,
اعداد says فارسی ۱۲۳۴, شروع هفته says شنبه, and each of those three carries a `chevron_left`.
The house rule is that **a chevron means *leads elsewhere***. None of the three leads anywhere:
`Kati.Screens.SettingsFa.tap_for/3` matches a toggle, then a glyph in `@destinations`, then a
badge row, and falls through to `def tap_for(_row, _si, _ri), do: nil` (`settings_fa.ex:554`) —
`calendar_month`, `pin` and `event` are in none of those clauses, so the rows render with no
`on_tap` at all. اندازه متن and درون‌ریزی are in exactly the same condition. Board 62 draws nine
chevrons; **five of them open nothing, and only two of the remaining four open a Persian page**
(سرویس‌های من → `MyServicesFa`, منابع داده → `DataSourcesFa`). برون‌ریزی opens the English 128,
همگام‌سازی opens `Kati.Screens.Sync` — which `Kati.Screens.Gallery` lists under `@undrawn`
because no artboard in any language draws it — and زبان's تغییر pushes the English 54.

So the one control on 62 that works as promised is also the one that takes the reader out of
Persian, and it is the only such control in the app.

## Why this is one brief and not seven

It is one board's promise broken seven times, and the promise is 62's first group.

But the reason it cannot be split is the middle three. **تقویم, اعداد and شروع هفته exist on no
other settings board in the set.** Board 24's glyph sweep is `arrow_back_ios_new help cloud_done
contrast format_size chevron_right motion_blur subscriptions … dns sync delete info shield info`
— no `calendar_month`, no `pin`, no `event`, and no زبان و منطقه group at all. They are the three
settings a Persian install obviously has and an English one does not, and each is a genuine
decision rather than a translation: whether the picker *stores* anything, what it offers, and
what it does to every dated surface in the app once it can. All three land on the same two
modules — `Kati.Calendar.Shamsi` and `Kati.Calendar.NowruzTable` — and on the same absent
column, so answering one answers the shape of the other two and answering none leaves all three
drawn and dead.

زبان belongs with them and belongs first, because it is the door the other three sit next to
and it is a trapdoor. `tap_for(%{badge: _badge}, …)` gives it `:go_language`
(`settings_fa.ex:552`) and `tapped("go_language", …)` pushes `Kati.Screens.Language`
(`settings_fa.ex:923-924`) — screen 54, English and left-to-right. Screen 54's own moduledoc has
been arguing this for two rounds:

> Pushed, not `reset_to/2`, and that is a judgement rather than the obvious reading. A language
> change really does relaunch an interface at its root, which argues for a reset; but there is
> no Persian language picker (no `LanguageFa`, and nothing pushes `Kati.Screens.SettingsFa` from
> anywhere), so a reset would clear the only stack that still contains this screen and strand
> the user in Persian with no drawn way back. Pushing keeps 54 underneath, where the hardware
> back button reaches it. **The strand still arrives one tap later** — the Persian dock switches
> roots with `reset_to/2`, which empties the history — and closing that needs a route into this
> screen from the Persian side, which is not this file's to add.

Half of that premise has since moved and the conclusion has not: `Kati.Screens.HomeFa` *does*
push `SettingsFa` now, so the route in exists — and there is still no `LanguageFa`, so the route
*out of English and back into Persian* is a row that board 24 does not draw (it is in
`Kati.Settings.Sample.appearance/0` at line 49, `translate` / *Language* / *English · فارسی*,
rendered but never drawn). And `Kati.Screens.Fa.dock_tap/3` still ends `reset_to` on every root
switch (`fa.ex:458`), so one tab tap after a wrong turn empties the stack the back button was
holding. Even the Persian search page points at 54: `Kati.Screens.SearchFa` draws
*«نمایش عنوان اصلی» در 54* on board 90, which is a Persian screen naming an English one.

اندازه متن, درون‌ریزی and برون‌ریزی are here for the smaller reason and are the smaller half of
the work: they are pure mirrors of 41, 140 and 128, and they are in this ticket only because
they are rows on this same board and the board is being redrawn anyway. One of them carries a
finding worth the trip: **129's Persian mirror already shipped as board 132
(`Kati.Screens.RestoreFa`), its back pill reads تنظیمات, and nothing on 62 opens it.** It is
reached only from `OnboardingWelcomeFa` and `HomeFaEmpty`. 128's mirror was never drawn at all.

## What to draw

| # | Artboard or edit | What it carries |
|---|---|---|
| **219** | **NEW — زبان** | Pushed from 62's زبان row. The Persian 54: the two installed languages as option cards, each stating its own consequences in its own script, and the sentence that says what a change does to the pages underneath. |
| **220** | **NEW — تقویم** | Pushed from 62's تقویم row. Which calendar dates are *shown* in, the options, and the card that says storage does not move. |
| **221** | **NEW — اعداد** | Pushed from 62's اعداد row. Which numeral set digits are shown in, with the mono caveat drawn rather than described. |
| **222** | **NEW — شروع هفته** | Pushed from 62's شروع هفته row. Which day a week begins on, with the seven-cell preview and the two screens it governs named. |
| **223** | **NEW — اندازه متن** | Pushed from 62's اندازه متن row. Board 41 in Persian: the spec drawn rather than described, at 235%, right to left. |
| **224** | **NEW — درون‌ریزی** | Pushed from 62's درون‌ریزی row. Board 140 in Persian: step 0, the named-file grid, the Kati-backup row above it and Something else below the rule. |
| **225** | **NEW — برون‌ریزی همه‌چیز** | Pushed from 62's برون‌ریزی row. Board 128 in Persian: the status card, what travels and what does not, three formats, one button. |
| **62** | **edit** | Every chevron accounted for: the five that now lead somewhere, the two the code draws and the board does not, and the row 132 has been waiting for. |

Seven boards for seven rows, which is the numbering this ticket reserves. If 220, 221 and 222
collapse into one منطقه board — see *Left open* — 221 and 222 go back unspent rather than being
filled with something else.

## 219 — زبان, element by element

| Element | Purpose | Glyph |
|---|---|---|
| Back pill `تنظیمات ›` | Pushed from 62; 62's own pill still reads خانه | `arrow_forward_ios` |
| Title زبان + a Vazirmatn sub-line | 62's title recipe: 27px/700 heading, 11.5px `#A9A29A` under it. Not DM Mono — `Kati.Screens.Fa` forbids the mono face on Persian glyphs | — |
| Eyebrow — the interface-language label | `Kati.Screens.Fa.eyebrow/1`: Vazirmatn 11/600, **no tracking**, accent rule. Not `Kati.UI.eyebrow/2` with a translated string | — |
| **فا / فارسی / ایران** — the selected card | Screen 54's picker card exactly: 38pt tile, name, region, an inset **2pt ink ring**, and a 24pt ink disc with a tick. `Kati.Screens.Language.language/2`'s selected clause carries **no `on_tap`** — *"choosing the language you are already in is not a choice"* — so this card is not a control on this board | `check` |
| **En / English / United Kingdom** — the one live option | The unselected clause: same card, no ring, an empty 24pt mark. This is the only tappable thing on the board | `radio_button_unchecked` |
| A consequences line under each name | Screen 53's move, and the one worth stealing: `RIGHT TO LEFT · 1234 · GREGORIAN` and `RIGHT TO LEFT · ۱۲۳۴ · SHAMSI`, each **in its own script**, so the row is legible to someone who cannot read the other one. On this board the English row's line is the one that has to be legible to a Persian reader | — |
| Cream card — what a change does to the stack | The sentence 54 does not have and this board must: choosing English changes the app's locale and opens the English home, and the Persian pages underneath **stay Persian** — `Kati.Screens.Fa` hard-codes `layout_direction="rtl"` because *"the screen is the Persian one, whatever the setting says"*. Backing out of a language change therefore walks back through Persian pages in an English app | `info` |
| The dashed **افزودن زبان** row — draw it or drop it | 54 draws *Add a language · Arabic, Turkish, German…* and `{Kati.Screens.Language, :add_language}` is on `Kati.ScreenTapSweepTest`'s **Backlog** as doing nothing. Copying an inert control into a second locale doubles a known dead control. Decide on the board | `add` |

## 220 — تقویم, element by element

| Element | Purpose | Glyph |
|---|---|---|
| Back pill `تنظیمات ›`, title تقویم | As 219 | `arrow_forward_ios` |
| **شمسی** — the selected option | The value 62's row already prints. A settings-list row with the tick, not a chip: three options at unequal lengths in a trough is the case `Kati.Screens.SettingsFa` already rejected for its own theme control | `check` |
| **میلادی** — the second option | The Gregorian row. **This word is not in the repo** — see *Left open* | `radio_button_unchecked` |
| A live sample under each option | The same date said both ways, so the choice is shown rather than named. `Kati.Calendar.Shamsi.format/2` at `:short` is `۱۴ مرداد`, which is the form 62's own برون‌ریزی sub-line draws | `calendar_today` |
| Cream card — **stored data does not move** | `Kati.Calendar.Shamsi` is explicit and the card must not contradict it: *"**Display only.** Stored data stays Gregorian/UTC — this module converts at the edge, for rendering and for parsing a date the user picked."* A calendar picker that reads as a data migration is the one wrong idea this board can plant | `shield` |
| Bordered footnote — the range | `Kati.Calendar.NowruzTable` covers **1300–1600 SH** and returns `nil` outside it, which `to_gregorian/3` turns into `{:error, {:year_out_of_range, year}}`. A calendar the user can pick is a calendar that can be handed a date it cannot convert | `history` |
| A line naming what this governs | Every dated surface: 55's greeting line, 56's week, 58's air times, 60's matrix, 115's readings, 132's file name. The board should say so rather than leave a reader guessing whether one screen or all of them change | `event_repeat` |

## 221 — اعداد, element by element

| Element | Purpose | Glyph |
|---|---|---|
| Back pill, title اعداد | — | `arrow_forward_ios` |
| **فارسی ۱۲۳۴** — the selected option | 62's own value, verbatim | `check` |
| **لاتین 1234** — the second option | لاتین is already in the set — `Kati.Screens.SearchFa`'s transliteration note on board 90 uses it | `radio_button_unchecked` |
| A sample row per option, showing real app values | A count, a time and a date, because those are the three shapes `Kati.I18n.Digits` and `Shamsi.fa/1` actually produce | `pin` |
| Cream card — **the mono caveat, drawn** | Board 62's own annotation already claims *"Numerals stay mono … with Persian digits substituted, so every column still aligns"*, and `Kati.Screens.Fa` says that claim cannot be kept: *"`kati_mono.ttf` contains **zero** of U+06F0–U+06F9; Vazirmatn carries all ten. So anything numeric that the design sets in mono is set here in `fa` at the design's size and colour."* This board is where that trade stops being a comment in a moduledoc | `text_fields` |
| Bordered footnote — what a numeral choice does **not** touch | Input folding is not a setting: `Kati.I18n.Digits` folds ۰–۹ and ٠–٩ and CLDR's U+066C group separator down to ASCII on the way *in*, whatever this row says. The footnote is what stops a build wiring this picker into the parser | `edit_note` |

## 222 — شروع هفته, element by element

| Element | Purpose | Glyph |
|---|---|---|
| Back pill, title شروع هفته | — | `arrow_forward_ios` |
| **شنبه** — the selected option | 62's own value. The names come from `Kati.Calendar.Shamsi.weekday_name/1`, which is the app's list and not a new one | `check` |
| **دوشنبه** — the second option | Monday, for a Persian install that keeps a Monday work week. Whether it is offered at all is *Left open* | `radio_button_unchecked` |
| A seven-cell preview strip under the options | Seven `flex:1` cells at radius 16 with a 2pt gap — screen 56's own day strip — redrawn with each start day, so the reader sees the sequence restart rather than reading about it. Short names come from `weekday_short/1`: ش ی د س چ پ ج | `calendar_view_week` |
| Cream card — **this is not mirroring** | The two screens it governs both say so in their own moduledocs. `Kati.Screens.ScheduleFa`: *"**The week restarts.** شنبه is the first column, not Monday moved to the right."* `Kati.Screens.MealsMatrixFa`: *"Flipping the container puts Monday on the right and leaves the week starting on the wrong day; the *sequence* has to restart at شنبه … Get one without the other and the table is confidently wrong rather than obviously wrong."* | `info` |
| Bordered footnote — where the order comes from today | `Kati.Calendar.Shamsi.month_grid/2` *"returns weeks already ordered شنبه → جمعه, so a renderer never has to reorder"*, and 60 reads `Kati.Fa.SampleWeek.days/0`. A settable start day is a second source of that order, and the board has to say which one wins | `lock` |

## 223 — اندازه متن, element by element

Board 41, right to left. `Kati.Screens.RestoreFa` is the precedent for how much of an English
screen a Persian mirror keeps: *"Font is the only test … a node that draws no `Text` cannot draw
the wrong one."*

| Element | Purpose | Glyph |
|---|---|---|
| Back pill `تنظیمات ›` and a header disc opposite it | 41 draws `more_horiz`. Kati has five of those with nothing behind them — see *What it must NOT do* | `arrow_forward_ios` |
| The **بعدی** card at 235% | 41's whole argument: the densest card in the app at the largest type, so *"nothing truncates — cards get taller instead"* can be checked by looking. In Persian this is a harder claim, not an easier one: Vazirmatn rides a taller line-height and carries no tracking | `play_arrow` |
| Six switch rows — the guarantees | 41's own six: VoiceOver, Dynamic Type, Reduce motion, Increase contrast, Touch targets, Colour is never alone. Five on, **Increase contrast off**, which is the resting state | `record_voice_over` `format_size` `motion_blur` `contrast` `touch_app` `colorize` |
| The **VoiceOver reads** band, quiet eyebrow | 41's grey `#C4BDB3` dash rather than the accent one, *"because it is a quotation rather than a section you act on"*. The Persian question this board has to answer: what a screen reader says on a Persian episode row, and in which language | — |
| The سطر پیمایشگر quotation on ink | 41 prints it on ink. Persian inside an ink block at 12.5px is a legibility case worth drawing rather than assuming | — |

## 224 — درون‌ریزی, element by element

Board 140, right to left. Step 0 only.

| Element | Purpose | Glyph |
|---|---|---|
| Back pill, title, mono-style step line | 140's is `STEP 0 OF 4 · PICK ONE AND KATI DOES THE MAPPING`. Persian digits, Vazirmatn, no tracking | `arrow_forward_ios` |
| **پشتیبان کاتی** — its own row *above* the grid | 140's single-row card with the sub-line that says *goes to Restore instead*. In Persian that row is the one place on 62's side of the app where **بازگردانی** can be named, and 132 exists to receive it | `cloud_done` |
| The six commonest sources, two-across | Letter tiles G/S/L/T/M/A and a file name each. **The file names stay Latin and read left-to-right inside the mirrored grid** — `goodreads_library_export.csv` is a name, not a quantity, which is `Kati.Screens.SearchFa`'s own rule for the `54` on board 90 | — |
| **پنج منبع دیگر** — the summary row | 140's eleven-into-six-plus-one decision, unchanged | `more_horiz` |
| Muted eyebrow and **چیز دیگری** below a full rule | 140's footnote-to-the-grid shape: a real path with no recognition step. It leads to the manual mapper, which has no Persian board — say so on the board rather than drawing a chevron into English | `edit_note` |
| Cream card — the sub-line names **the file** | 140's own argument, and it survives translation unchanged: *"CSV export" is short and useless*; the exact file name is what stops the commonest failure at this step | `info` |

## 225 — برون‌ریزی همه‌چیز, element by element

Board 128, right to left.

| Element | Purpose | Glyph |
|---|---|---|
| Back pill, title, eyebrow | 128's is *ONE FILE, KEPT WHEREVER YOU LIKE* | `arrow_forward_ios` |
| The status card — **آخرین پشتیبان** | The one live read on this board. `Kati.Screens.SettingsFa.backup_line/1` already writes the Persian for it and both halves must be drawn: `آخرین پشتیبان ۱۴ مرداد` and `هنوز پشتیبانی گرفته نشده` | `cloud_done` |
| **چه همراه می‌آید** — six ticked rows | 128's list. One of its six is *Settings — Language, units, sections*; see *What it must NOT do* before translating that line | `check` |
| **همراه نمی‌آید** — two blocked rows | Cached provider metadata and connected tokens, with 128's reasons: re-fetchable, revocable | `block` |
| Three format rows, one selected | 128 settled this deliberately: *three rows with one selection* rather than a segmented control, *"the three are not peers — only JSON restores — and a row can carry the sentence that says so"*. Which is also why it cannot become a Persian trough | `description` `upload_file` `calendar_month` |
| **ذخیرهٔ پشتیبان** — the one primary button | One per screen | — |
| Cream card — a backup is a file you keep | 128's closing footnote, whose whole point is that Kati has no server. Nothing in it is locale-specific and all of it has to be said in Persian | `info` |

## 62 — the edit, chevron by chevron

Nothing on the board moves; what changes is which chevrons are honest and which rows exist.

| Row | Change |
|---|---|
| زبان (`فا` badge, **تغییر**) | Unchanged. It is already the only live control in the group, and 219 is what it should open |
| تقویم / اعداد / شروع هفته | Keep the `chevron_left`; they now open 220, 221, 222 |
| اندازه متن | Keeps its chevron; opens 223 |
| درون‌ریزی | Keeps its chevron; opens 224 |
| برون‌ریزی همه‌چیز | Keeps its chevron; **repoints from the English 128 to 225** |
| **بازگردانی — new row** | Board 132 exists, its back pill reads تنظیمات, and no row anywhere opens it. 24 draws the same pair — *Back up everything* then *Restore a Kati backup* — and 62 draws only one of them. Add the row or state on the board why the Persian side keeps restore inside onboarding | `upload_file` |
| **منابع — a row the code draws and the board does not** | `Kati.Fa.SampleSettings.sections/0` ends داده‌ها with `info` / منابع / پروانه‌ها و اعتبارها → `AttributionFa`. It renders on device and is on no artboard. `Kati.ScreenDesignLiteralTest` reads board → tree, so an extra row passes every sweep silently |
| **The داده‌ها order** | The board draws درون‌ریزی, برون‌ریزی, سرویس‌های من, منابع داده, همگام‌سازی. The code draws درون‌ریزی, برون‌ریزی, همگام‌سازی, سرویس‌های من, منابع داده, منابع. Decide which is right and say so; one of the two is going to be edited |
| همگام‌سازی | **Unchanged and out of scope.** It keeps its chevron and its English destination until #25/#54 draws `Kati.Screens.Sync` in any language |
| The `help` disc | **Unchanged and out of scope.** It is undrawn on English 24 too |

## States to draw

Kati's sweeps compare an empty state against a board, so an **undrawn empty state becomes an
untested one** — `Kati.ScreenEmptyDatabaseTest` asserts each board's literals with nothing
stored, and 62 is already on its list.

- **Resting.** Each picker with the value 62 already prints selected: شمسی, فارسی ۱۲۳۴, شنبه,
  فارسی on 219. An untouched Persian install must draw exactly the board and nothing else.
- **Active.** The state that is not the resting one, and it is the whole reason three of these
  boards exist: **میلادی selected on 220, لاتین on 221, دوشنبه on 222.** Each needs its preview
  redrawn, not just its tick moved — 222's seven-cell strip is a different strip, 220's sample
  date is a different date, 221's sample row is different glyphs. A picker drawn only in its
  default state is a picker whose second option has never been looked at.
- **Empty — two, both already reachable.**
  1. **225's status card with no backup.** `Kati.Screens.Settings.last_backup/0` is `nil` until
     a Save As completes, and `Mob.State` is empty on a fresh install, so
     `backup_line/1` answers `هنوز پشتیبانی گرفته نشده`. `Kati.ScreenEmptyDatabaseTest` already
     pins the pair for 62 (`~r/^(آخرین پشتیبان \p{N}+ …|هنوز پشتیبانی گرفته نشده)$/u`) and for
     128 in English; 225 is where the Persian sentence gets a board. **This is the default state
     of every user**, which is what 128 calls *a warning, not an error*.
  2. **62's own empty group.** The سرویس‌های من sub-line (`ایران · ۳ سرویس`) falls back through
     `Kati.Screens.MyServices.listed/0`, so the group under داده‌ها is already drawn twice in the
     test suite and once on the board.
- **Error — two, and neither is invented.**
  1. **A date outside the Nowruz table.** `NowruzTable.nowruz/1` answers `nil` for a year outside
     1300–1600 SH and `Shamsi.to_gregorian/3` returns `{:error, {:year_out_of_range, year}}`.
     220 is the only board that can say what a reader sees when that happens.
  2. **A language change with pages underneath.** Not a failure but a state nothing has drawn:
     the moment after English is chosen on 219, when the stack still holds 62 and 55, both of
     which hard-code `rtl`. Either 219 says what happens to them or a build decides it.
- **235%.** Not a separate board. 223 *is* the 235% board, and it is the only one of the seven
  where the size case is the subject rather than a risk.

## RTL — what mirrors and what does not

All seven boards **are** the Persian mirror; the question inverts. What has to be settled on
them is the part mirroring alone gets wrong, and board 62 already carries the rule in its own
*What flips, what holds* panel: eight things flip (layout, navigation direction, back chevron,
row chevrons, progress and macro bars, chart time axis, poster overlap, sheet edges) and six
hold (artwork, play/pause/skip, clock faces, checkmarks, the brand mark, star ratings). The
board's sentence is the test: *anything that means direction of reading flips; anything that
means direction of time or motion does not.*

- **The vertical order never reverses.** Options stay above previews, previews above the cream
  card, the cream card above the footnote — on every one of the seven.
- **The back pill's glyph is `arrow_forward_ios` and every chevron is `chevron_left`.**
  `Kati.Screens.SettingsFa`'s moduledoc is the reason both flip together: *"A screen that flips
  one and not the other sends the reader in both directions at once."*
- **Latin values do not mirror and do not translate.** 224's file names
  (`goodreads_library_export.csv`), 219's `En`, 221's `1234` sample, and any board number printed
  in copy. `Kati.Screens.SearchFa` settles the principle for the `54` on board 90: *"it is a
  name, not a quantity, and names are not translated."*
- **Nothing in `Kati.Components` may draw a Persian label.** `Kati.Screens.Fa`: *"not one of the
  77 components in `Kati.Components` accepts [`font_family`] … a Persian label handed to a
  Chelekom component is not degraded, it is absent."* The four with a content slot —
  `MishkaThemeIcon`, `MishkaActionIcon`, `MishkaPill`, `MishkaToggle` — are the doors, and 219's
  فا badge tile is the existing example.
- **222 is the case where mirroring is not enough**, per the two moduledocs quoted above. Draw the
  strip, do not describe it.
- **Does anything here need an English twin?** 220, 221 and 222 close an identical gap on **54**,
  whose *Calendar*, *Numerals* and *Week starts* rows carry `chevron_right` and no `on_tap`
  either — `Kati.Screens.Language` says so: *"None of the eight carries an `on_tap` … Each names
  a preference the app does not keep."* The recommendation is that these three boards serve both
  locales un-mirrored rather than becoming six artboards, and that the board says so, because
  otherwise 54's three rows stay dead after this ticket ships.

## Dark colourway

**No new dark boards, and one note.** Six dark boards exist and one of them is Persian —
159 (`HomeFaEmptyDark`) — and 128 already has its dark twin at **131**, which is the only one of
these seven whose surfaces are not already answered. Everything on 219–224 is a card, a paper
tile, an ink ring, a cream card and a chevron on `#121110` / `#1E1D1B`, all of which resolve
through `Kati.Theme.Palette` rather than a literal.

The one thing worth a written note rather than a drawing is **219's selected card**. Its ring is
`Palette.ink()` and its tick disc is `Palette.ink_fill()`, and `Kati.Screens.Language` is explicit
that the two behave differently in dark — the ring is *"a mark drawn ON the card"* and stays on
the ink ramp, while the disc *"inverts the way screen 28's CTA pill does — paper fill, ink tick —
rather than becoming a near-white disc with a near-white tick on it."* Two ink tokens on one card
that diverge in dark is exactly the pair a build guesses wrong.

## Reuse, do not invent

- **219's option card** is `Kati.Screens.Language.language/2` — 38pt tile from
  `Kati.Screens.Language.tile/1`, name, region, inset 2pt ink ring on the selected one, 24pt mark
  on both. Its **consequences line** is screen 53's, which already prints
  `RIGHT TO LEFT · ۱۲۳۴ · SHAMSI` in Persian and its counterpart in English.
- **220, 221 and 222's option rows** are `Kati.Screens.SettingsFa.row/4` — the 30pt paper tile
  from `leading/1`, 13.5px/600 title, 11.5px `#8A8479` sub — with the trailing chevron replaced by
  a tick. Not a new list style, and **not a segmented control**: `SettingsFa`'s own trough is
  hand-rolled because `MishkaSegmentedControl` *"says in as many words that 'the label is a prop
  rather than the slot's children because the control paints it'"*, and these labels are Persian.
- **Every eyebrow** is `Kati.Screens.Fa.eyebrow/1` — Vazirmatn 11/600, no tracking — with the
  muted grey rule from `SettingsFa.eyebrow/2` for a footnote band, the same call
  `MyServicesFa` and `DataSourcesFa` already make.
- **Every header disc** is `Kati.Screens.Fa.disc/2` at 44pt, `MishkaActionIcon` with the button
  shadow.
- **222's preview strip** is screen 56's day strip: seven `flex:1` cells, radius 16, 2pt gap.
- **223** is board 41 node for node, and **224** is 140 and **225** is 128. `Kati.Screens.RestoreFa`
  is the worked example of how much survives translation: text-free nodes are reused from the
  English module outright, and *"everything else … builds its own `Text` and leaves `font_family`
  off, which is every unstyled `Text` in the app and therefore a row of empty boxes for Persian"*
  and is rebuilt.
- **225's status card and its two sentences** are `SettingsFa.backup_line/1`, already written.
- **Prefer glyphs the app already ships.** Every glyph named in this brief is in `Kati.Icons`'s
  inlined map, checked; `test/design/material_symbols.codepoints` is not in the repo, so a new
  symbol blocks `mix kati.gen.icons`. `calendar_month`, `pin` and `event` are the three rows' own
  glyphs on both 62 and 54 — do not swap them for something more literal.

## What it must NOT do

Every line here is a decision the codebase has already made.

**Do not draw تقویم as anything that moves stored data.** `Kati.Calendar.Shamsi`:

> **Display only.** Stored data stays Gregorian/UTC — this module converts at the edge, for
> rendering and for parsing a date the user picked. Storing Shamsi would make every range query
> and every sync comparison a conversion.

So 220 changes what is *shown*. No migration copy, no progress bar, no "converting your data".

**Do not offer a calendar Kati cannot convert.** There is one converter in `lib/kati/calendar/`
and it is Solar Hijri. Board 62's own locale table lists `ar · Hijri · ١٢٣٤ · Saturday · IBM Plex
Sans Arabic · ready` — *ready*, not shipped, and there is no lunar Hijri anywhere in `lib/`. A
قمری row on 220 would be the first control in the app to promise a calendar that does not exist.

**Do not invent a settings domain for these three.** `Kati.Screens.Language` has already ruled on
where they live:

> They belong on `Kati.Locale` as stored overrides — the row's own word is *overridable*, and
> `Kati.Theme.Mode` is the shape one takes — rather than in a domain: they are preferences, not
> rows.

`Kati.Locale` today stores exactly one thing, in `Mob.State`, and derives direction from it. Three
new pickers are three new keys on that module, not three tables.

**Do not draw اعداد as an input setting.** `Kati.I18n.Digits`:

> Direction. A folded string is still displayed inside an RTL container and still renders its
> digits through `arabext`; folding is about what the parser sees, never about what the screen
> shows. Nothing here reverses anything.

Folding ۰–۹, ٠–٩, ٪, ٫ and ٬ to ASCII happens on every input regardless of this row. 221 governs
output only.

**Do not draw شروع هفته as a free choice without saying what it costs.**
`Kati.Calendar.Shamsi.month_grid/2` *"returns weeks already ordered شنبه → جمعه, so a renderer
never has to reorder"*, and `Kati.Fa.SampleWeek.days/0` holds 60's order for the same reason. A
settable start day means one of those two stops being the source of truth, and 56 and 60 are the
screens that break if it is done by mirroring instead of by resequencing.

**Do not draw اندازه متن as a size slider.** Its English destination is not a text-size picker.
`Kati.Screens.Accessibility`:

> **Every string on this screen is `Kati.Accessibility.Sample`, and no resource in the app holds
> any of it.** The design's caption is the reason and not an excuse — this is *the spec drawn
> rather than described*, so the six rows are claims Kati makes about itself, not settings a user
> keeps.

Dynamic Type on 41 is *"deliberately inert"*; the size comes from the OS. 223 is the same spec in
Persian, and a slider on it would be the app promising a setting it does not have.

**Do not translate 128's *Settings — Language, units, sections* line without checking it.** A
`.katibackup` is `data/<table>.json`, one file per backed-up table, and
`docs/backup-format.md`'s *In the backup* list has **no settings or preferences table in it**.
The locale is not in a table at all — `Kati.Locale` keeps it in `Mob.State`, a DETS store
`Kati.Backup` never touches. If 220–222 become stored overrides they land in the same place, so
either the claim on 225 is narrower than 128's or something has to carry them.

**Do not put a restore flow on 225.** `Kati.Screens.Backup`:

> Nothing here reaches into that half: this screen writes a file, and reading one back is not a
> thing it can do.

بازگردانی is board 132 and it already exists. 225 names it and stops.

**Do not draw the manual column mapper behind 224.** 140 is step 0; `Kati.Screens.Import` is
screen 37, the mapper, and it has no Persian board. *چیز دیگری* leads there, and this ticket does
not draw it.

**Do not give 62's `help` disc a destination, and do not draw what 223's `more_horiz` opens.**
`Kati.UI.Menu` states the standing gap: *"Five of the 62 drawings put a `more_horiz` in a header
and none of them draws what it opens."* The help disc is undrawn on English 24 as well, is drawn
with `Fa.disc("help")` and **no tag at all** — which is why it is not even on
`ScreenTapSweepTest`'s Backlog: a control with no tag is invisible to the sweep. Both are real
gaps and neither is this ticket's.

**Do not draw a destination for همگام‌سازی.** `Kati.Screens.Gallery` lists
`{:open_undrawn_sync, "Sync", Kati.Screens.Sync}` under `@undrawn`, and no artboard in any
language draws it.

**Do not add a third language to 219.** `Kati.Locale`: *"Every locale Kati ships. Machinery
supports more; translations do not."* `supported/0` returns `[:en, :fa]`, 53 draws two options and
54 draws two rows. The locale table on 62 marks `ar` and `tr` as *ready*, which is a claim about
the machinery, not about a shipped translation.

**Do not put a second language control on 62.** The زبان row is the whole picker's door, and it
is `tap_for`'s only badge clause. A second entry point would be two controls for one setting on
one board.

## Left open — decide and note which way you went

- **Derived or stored — the decision this whole brief turns on.** Board 62's locale table already
  fixes fa as *Shamsi · ۱۲۳۴ · Saturday*, which reads as *derived from the language*. If that is
  the answer, then تقویم, اعداد and شروع هفته should not be chevron rows at all — they should be
  value rows, the way 54 prints `auto` on *Writing direction* precisely *"because it is not a
  choice — it is derived"* — and this ticket becomes an edit to 62 that removes three chevrons
  instead of three boards that honour them. If they are overridable, they are three keys on
  `Kati.Locale` and 219 has to say what choosing English does to an override the reader set by
  hand. **Both are defensible; the drawing has to pick, because the row's chevron is currently
  claiming the second answer and the locale table the first.**
- **Three boards or one.** 220, 221 and 222 are three short option lists reached from three
  adjacent rows. One منطقه board with three groups would be fewer taps and one drawing; three
  boards match 62's three chevrons and 54's three rows. If it collapses, say which numbers go
  back.
- **میلادی.** The word is not in the repo — `grep` finds no میلادی, no قمری, no گرگوری. Whatever
  220 calls the Gregorian option becomes the app's first use of it, so it is copy this board is
  writing rather than mirroring, and the same is true of the sample dates beside it.
- **Whether دوشنبه is offered at all.** A Persian install that starts its week on Monday is a real
  configuration and an unusual one, and every consequence of it lands on 56 and 60.
- **What 219 does after the choice.** 53 writes the locale and moves forward with no back to press
  (*"on a first run it is the stack root, so there is no back to press and nothing to be stranded
  from"*). 54 pushes and keeps itself underneath. 219 is neither: it sits on a Persian stack that
  `Fa.dock_tap/3` will empty at the next tab tap. Push, reset, or a confirmation first — and what
  the pages underneath show either way.
- **Whether 62 gains a بازگردانی row**, or the Persian side deliberately keeps restore inside
  onboarding and 132's تنظیمات back pill is the thing that is wrong.
- **The داده‌ها order and the منابع row** — board or code. One of the two is being edited.
- **What 220's out-of-range state says.** `{:error, {:year_out_of_range, year}}` is the shape;
  the sentence is not written anywhere.
- **Whether 219 keeps 54's dashed *افزودن زبان* row**, given it is already on the Backlog as
  inert.
- **Whether 223 draws 41's `more_horiz` disc at all.** Mirroring it faithfully copies a control
  with nothing behind it into a second locale.

## Acceptance — how we know the drawing is complete enough to build from

1. **Board 62's export contains nine chevrons and every one of them names a destination on the
   drawing** — 220, 221, 222, 223, 224, 225, `MyServicesFa`, `DataSourcesFa`, and همگام‌سازی
   marked explicitly as out of scope. A chevron with no named destination is a defect in the
   drawing.
2. Every control on 219–225 has either a destination or a **named key it writes**. `Kati.Locale`
   stores one value today; a picker on these boards that writes something outside
   `{locale, calendar, numerals, week_start}` is a drawing defect, not a migration to write.
3. **Each of 220, 221 and 222 is drawn twice** — once with 62's value selected and once with the
   other option selected, previews redrawn rather than ticks moved.
4. 225 draws the status card **both ways**, and its no-backup sentence is
   `هنوز پشتیبانی گرفته نشده` — the string `SettingsFa.backup_line/1` already returns, not a new
   one.
5. Nothing numeric on any of the seven is set in DM Mono. `Kati.PersianFontTest` exists because
   four screens broke this rule after their own moduledocs stated it.
6. 219 carries one sentence about what happens to the Persian pages left on the stack after a
   language change, and 222 carries one about which of `Shamsi.month_grid/2` and
   `SampleWeek.days/0` supplies the week order.
7. 220 carries the *display only* sentence, and no copy anywhere on it implies data is converted,
   migrated or rewritten.
8. 224's Latin file names read left-to-right inside the mirrored grid, and 221's Latin sample does
   too; neither is translated and neither is set in Persian digits.
9. The three pickers are drawn once and serve 54's identical rows, or the board says why 54 needs
   its own — either way 54's *Calendar*, *Numerals* and *Week starts* rows are not left in the
   same state this ticket found 62's in.
10. Every glyph on the seven boards is in `Kati.Icons`'s inlined map, or the board names the new
    symbol explicitly so someone can decide whether it is worth unblocking `mix kati.gen.icons`
    for.

## House style — Kati

Draw into `examples/ui_design/Kati.dc.html` as a new `IOSDevice` artboard, 402×874.

**Numbering.** The app runs **01–166** and nothing may be inserted below 167. This screen takes the
next free number.

**Type.** `Plus Jakarta Sans` for everything, `DM Mono` for data, counts, times, IDs and eyebrows,
`Vazirmatn` for Persian. Material Symbols Rounded for glyphs.

**Palette.**

| Token | Light | Meaning |
|---|---|---|
| paper | `#EFECE7` | page ground |
| card | `#FBFAF8` | any raised surface |
| cream | `#FBF1DE` | a card that carries a claim or a warning |
| ink | `#1A1917` | primary text, filled buttons |
| ink soft | `#5C574F` | body copy on a card |
| sub | `#8A8479` | a row's second line |
| tertiary | `#A9A29A` | mono captions, chevrons |
| accent | `#E8823C` | one thing per screen, never two |
| bronze | `#C98A3E` | money, meals, a gentle warning |
| green | `#4E9A73` | done, allowed |

Dark ground is `#121110`, card `#1E1D1B`, ink `#F5F2EE`.

**Recipes already in the app** — reuse rather than invent:

- **Pushed screen** — scroller `padding: 64px 21px 40px`, floating back pill (44pt, radius 22,
  `#FBFAF8`, `arrow_back_ios_new` + parent name), no dock, frame closes at 40.
- **Root screen** — same but the dock is drawn and the frame closes at 132.
- **Eyebrow** — a 13×2 rounded `#E8823C` rule, then DM Mono 10.5px, `.16em` tracking, uppercase,
  `#A0998F`. A quiet eyebrow swaps the rule to `#C4BDB3`.
- **Card** — `#FBFAF8`, radius 22, `box-shadow: 0 1px 2px rgba(26,25,23,.04), 0 12px 24px -18px rgba(26,25,23,.7)`.
- **List row** — 30×30 paper tile (radius 9, `#EFECE7`, glyph 17px `#5C574F`), 13.5px/600 title,
  11.5px `#8A8479` second line, trailing chevron `#C4BDB3`. A chevron means *leads elsewhere* —
  never use one for a row that does not push a screen.
- **Chip** — height 32, radius 16, padding-x 15, 12.5px/600. Selected is `#1A1917` on ink with
  `#FBFAF8` text.
- **Pill button** — height 30, radius 15, `#EFECE7`, 11.5px/600.
- **Primary button** — height 54, radius 27, ink fill, 14.5px/700 in `#FBFAF8`. **One per screen.**
- **Progress bar** — 2px, track `#C4BDB3`, fill `#E8823C`.

**RTL.** The container gets `dir="rtl"`; the whole grid mirrors. Artwork and star glyphs never
mirror. The back pill's glyph becomes `arrow_forward_ios`, chevrons become `chevron_left`. Dates go
Shamsi and digits Persian, both in DM Mono so columns still align.

**Dynamic Type.** Content grows with the system font size. Chrome whose size carries structure —
a seven-across week strip, a fixed-height pill — caps instead. A heading sharing a row with a
control yields to the control.
