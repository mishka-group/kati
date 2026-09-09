# The rows behind the log sheet's chevrons

> **Mixed — three new boards, two edits** · ticket `D-36`

Someone finishes a film, opens screen 33 to log it, and wants to record the three facts
the board's own caption says the sheet exists for — *"where you were and who you were
with"*. Board 33 draws all three as list rows with a `chevron_right` on each: **Watched
on**, **Where**, **With**. It draws a fourth control, a dashed `+ tag` ring, beside three
attached tags. Tapping any of the four does nothing, and it cannot do anything, because
**none of the four destinations is drawn anywhere in 01–166**. The rating and the review
on the same sheet both commit — `Kati.Screens.Rating.save_watch/1` updates a real
`Kati.Media.Watch` and `Kati.RatingWriteTest` pins it to one row — so the write path these
four would use already exists and is already tested. What is missing is the drawing.

## Why this is one brief and not four

The four are the same problem wearing four labels. They are the same row recipe, in the
same `SettingsList` card, and they are the context half of one sheet. And they need **one
decision made before any of them can be drawn**, which is why splitting them across four
tickets would produce four incompatible answers:

**Do these rows push, or do they open in place?** Board 33 says push — three chevrons.
Board **144**, which is the same sheet scoped to an episode, draws *the identical three
rows in the identical card* — `#FBFAF8`, radius 20, `4px 15px`, rows at `13px 0`, the same
`event` / `tv` / `group` tiles, the same second lines — **with no chevron on any of them**,
and a mono `now` on the date row instead. So the two boards currently disagree in print,
and `D-34`'s rule forces the issue rather than letting them coexist:

> a chevron means *leads elsewhere* — never use one for a row that does not push a screen.

That is why 144 is in this ticket as an edit. Whichever way the decision goes, both boards
must end up saying the same thing about the same three rows.

Two of the four have precedent to reuse rather than invent. **94** is a picker in this
app's own idiom — a modal sheet, a search field, rows with a `check` on the current one.
**36**'s Rules group shows the settled shape for a value row that opens a small choice
(`percent` · *Tick at* · `90% watched` · `chevron_right`). `+ tag` is the fourth and the
least specified; it is also already carried as inert at
`test/kati/screen_tap_sweep_test.exs:714` — `{Kati.Screens.Rating, :add_tag}`.

The code is waiting rather than blocking. `lib/kati/screens/rating.ex:143-147`:

> `contains_spoilers`, the three context rows and `:add_tag` are still drawn and still
> inert; each needs a control this screen does not draw (a switch, a date picker, a place
> picker, a tag field) rather than a write path, and the write path they would use is the
> one that now exists.

## What to draw

| Board | What it is | What it carries |
|---|---|---|
| **169** — Watched on | new, modal sheet | a month grid with steppers, an hour row, a `now` pill, and an **I don't remember** pill. Writes `Kati.Media.Watch.watched_on` and `watched_at` — two columns, never one |
| **170** — Where | new, modal sheet, **two sections** | a searchable list of `Kati.Services.Service` with a `check` on the current one, then a free-text **Place** field with previously-used places as chips. Writes `service` and `place` separately |
| **171** — With, and + tag | new, one board, **the same free-text recipe drawn twice** | a field, the values already attached as removable chips, and what has been typed before. Writes `companions` and `tags` — both comma-separated columns of the same shape |
| **33** — edit | the context card and the tag row, restated | whichever trailing mark the sheet/inline decision picks, on all three rows. Plus: say whether the `visibility_off` · *Spoilers hidden* line becomes a switch or stays a label |
| **144** — edit | the same context card | must end up agreeing with 33. If 33 keeps chevrons, 144 gains them and keeps `now` beside one; if 33 loses them, 144 is already right and 33 changes |

Three boards for four destinations, and the pairing is not an economy. `companions` and
`tags` are the *same column shape* — `Kati.Media.Watch` describes both as values "as
typed, comma-separated", `Kati.Screens.Rating.tag_list/1` and `presence/1` parse both the
same way — so drawing them as one recipe twice is the honest drawing. Two boards would
invite two shapes for one thing.

## Every element

### 169 — Watched on

| Element | What it is for | Glyph |
|---|---|---|
| Close disc | leave without changing the date; the sheet is a decision you come back from | `close` |
| Sheet title *Watched on* | the row's own words, so the sheet names where you came from | — |
| Month header + steppers | move a month at a time; 16's own header | `chevron_left` / `chevron_right` |
| The 6×7 grid | the selected day, today, and the days outside the month | — |
| Hour row | `21:40`; the *hour* half, which only `watched_at` has | `schedule` |
| `now` pill | back to the clock after changing the time — 111's own control, and the word 144 already prints | — (mono word, no glyph) |
| **I don't remember** pill | clears both columns without recording *never* | — (the `now` pill's twin, same recipe) |
| Footnote | that the date is the night you watched, not the night you logged it | `info` |

### 170 — Where

| Element | What it is for | Glyph |
|---|---|---|
| Close disc | as 94 | `close` |
| Search field | 94's field verbatim; the service list is long once a library is real | `search` |
| Service row | the letter tile is `Kati.Services.Service.badge/1` — `L` for Lumen+, as on 14 and 126 | — (a letter, not a glyph) |
| Current service mark | a tick, not a radio — 94's argument, "matching how 35 marks per-show state" | `check` |
| **Not on a service** row | a disc, a cinema, a plane. `service` is nullable and this is what nulls it | `do_not_disturb_on` |
| Place field | `living room` — free text, because it is a room in a house | `place` |
| Places used before | chips, so the second time is a tap | — |
| Footnote | that the two halves are stored apart and print as one line | `info` |

### 171 — With, and `+ tag`

| Element | What it is for | Glyph |
|---|---|---|
| Close disc | as above | `close` |
| **With** field | a name as typed. Kati has no contacts | `group` |
| **Tag** field | the same field, one section down | `label` — 14's own glyph for this idea |
| Attached values | 33's tag chip exactly: height 30, radius 15, card fill, soft card shadow | — |
| Remove, on an attached chip | takes one out; `MishkaPill`'s `with_remove` slot already exists | `close` |
| Used before | what has been typed on other watches, offered as chips | `history` |
| Footnote | that a comma is the delimiter and cannot be part of a value | `info` |

## States

Four, and one of them is load-bearing in a way it is not on most boards.

**Resting.** Each sheet over a real value: 169 on `Sun 16 Aug · 21:40`, 170 on
`Lumen+ · living room`, 171 on `Jo` and on `slow burn`, `coastal`, `rewatchable`. These are
`Kati.Rating.Sample`'s values, which is what 33 was captured from.

**Active.** The selected day; the ticked service; a chip mid-remove; a field with a caret
and one character in it. `Kati.Screens.Rating` records what the caret costs on this bridge
— `MobTextField` is `singleLine = true` — so draw one line of text, not a paragraph.

**Empty — draw it, or it will not exist.** `Kati.ScreenEmptyDatabaseTest` reads the same
literals with nothing stored, and on a fresh install every one of these is empty: no
services (that is screen 93's whole subject), no place typed before, no companion, no tag.
So 170's list has nothing in it but its search field, and 171 has two fields and no chips
at all. Kati's convention for this is not a separate artboard — 144 hangs its variants as
labelled panels under `Kati.UI.SettingsList.eyebrow_muted/1` inside its own frame, and
`Kati.Screens.RateEpisode` renders them because `Kati.ScreenDesignLiteralTest` "refuses copy
that is in a drawing and nowhere in a tree". Do the same: one empty swatch per board,
inside the board.

**Error.** There is exactly one, and it is real rather than defensive. `companions` and
`tags` are comma-separated, so **a comma typed into either field is a second value, not a
character**. Type `Jo, Sam` into With and you have logged two people; type `sci-fi, noir`
as one tag and you have two tags. 171 must draw what happens — split on the comma and show
two chips, or refuse the comma and say so. Do not leave it to the parser.

Two things that look like errors and are not, so do not draw them as warnings: a date with
no hour (`watched_on` set, `watched_at` null — a legal, common log), and a watch with no
date at all. `Kati.Media.Watch` is explicit that the second one must stay sayable.

## RTL

Yes for one of the three, no for the other two, and the difference is not stylistic.

**169 needs a Persian drawing.** A month grid is the case mirroring alone gets wrong.
`Kati.Calendar.Grid`:

> the hardest case in the whole pass: a matrix whose columns are days. Mirroring alone
> would put Monday on the right and still be wrong — the sequence itself has to restart at
> شنبه.

So the Shamsi grid starts on شنبه, in Shamsi months, with Persian digits in DM Mono — a
different grid, not a flipped one. Draw it as a second labelled panel on 169 rather than
asking for a fourth number.

**170 and 171 mirror mechanically** and need no separate artboard: the container gets
`dir="rtl"`, the grid mirrors, chevrons become `chevron_left`, and that is all. What does
not mirror: the vertical order of the sections never reverses; a service's letter tile is
artwork and stays as drawn; `close` is symmetrical; and on 33 and 144 the back/close
glyph rule is the house rule, `arrow_back_ios_new` → `arrow_forward_ios`.

## Dark

**No dark artboards, and the reason is that every colour these boards use already has a
dark value with a test behind it.** These are paper, card, ink, hairline and one accent —
no artwork, no photograph, no gradient over a still, which is what forced dark boards for
01, 102 and 131. `Kati.Theme.PaletteTest` writes the light column out by hand and
`Kati.ThemeModeTest` asserts `Kati.Theme.light/0` byte for byte, so a token drawn here is a
token that already resolves in both modes.

Two things to check rather than redraw. The `+ tag` ring is `1.5pt` of
`rgba(26,25,23,.18)` in the drawing and `Palette.border_strong()` in the code, which is
`0x2E1A1917` light and `0x2EF5F2EE` dark — it already inverts. And a light card lifts with
a shadow while a dark card lifts with an inset hairline, so 170's rows and 171's chips
separate differently in the two modes by design, not by accident.

## Reuse, do not invent

Every part of all three boards is already in the app.

- **The sheet.** `Kati.UI.Sheet.sheet/3`, which `Kati.Screens.CountryPicker` calls with one
  line. Scrim `rgba(26,25,23,.42)`, drawer `border-radius: 26px 26px 0 0`, padding
  `18px 21px 34px`, a 36pt close disc with a 19pt glyph, a centred 15px/700 title, and a
  36pt empty hole opposite it. No commit bar unless you ask for one.
- **The search field.** 94's: height 46, radius 23, card fill, card shadow, a 19px
  `search` in `#A9A29A`, placeholder 14px `#A9A29A`.
- **The list.** `Kati.UI.SettingsList` — card radius 20, `4px 15px`, hairline between rows,
  a paper tile at 30×30 (33's rows) or 40×40 (94's).
- **The tick.** 94's `check` at 19px in ink. Not a radio, not a checkbox.
- **The month grid.** 16's — weekday header, six rows of seven, `chevron_left` /
  `chevron_right` steppers on the month name. Behind it, `Kati.Calendar.Grid` already
  returns the matrix with the week start as a parameter, and `Kati.Calendar.Shamsi` says in
  its own moduledoc that it converts "for rendering and for parsing a date the user picked".
- **The `now` pill.** 111's, exactly: height 28, radius 14, paper fill, 11.5px/600 in
  ink-soft. 144 prints the same word.
- **The chips.** 33's own tag pill and its dashed ring, both already `MishkaPill`.
- **The value row that opens a small choice.** 36's Rules group.

## What it must NOT do

Nine decisions the codebase has already made. None of them is negotiable in a drawing.

**1. `With` is not a contacts picker.** `Kati.Media.Watch`:

> Names as typed, comma-separated. Kati has no people table and no contacts permission, and
> inventing either to hold the word "Jo" would be a larger privacy decision than the
> feature is asking for.

**2. `Where` is not one field.** Same moduledoc:

> `service` and `place` are stored apart even though screen 33 draws them as one line
> ("Lumen+ · living room"), because one of them is a thing stats can group by and the other
> is a room in a house.

So 170 has two sections with different shapes — a list and a field — and only the printed
line joins them.

**3. The date cannot be compulsory.** Same moduledoc:

> Both are nullable: "I have seen this, I do not remember when" is a real answer and must
> not be recorded as never.

That is what the **I don't remember** pill is for, and why 169 has no primary button that
demands a value.

**4. Date and hour are two columns.** Same moduledoc:

> `watched_on` is a date and `watched_at` is an instant, and they are separate for the
> reason `Kati.Calendars.Event` keeps `dtstart_date` apart from `dtstart_utc`: "watched on
> 12 August" is date-valued, and storing it as midnight moves it a day the moment the user
> flies.

A single combined date-and-time control that always produces both is the bug this column
split exists to prevent.

**5. It cannot be the OS date picker.** `Kati.ScreenTapSweepTest`, on screen 111's `now`:

> With no time picker behind it — Mob has no date input, which is #45 — there is nothing to
> come back from yet.

169 must be drawn entirely in Kati's own nodes. Nothing may assume a system picker appears.

**6. `+ tag` here is the *watch's* tags, not the title's.** Board 14 draws a control that
looks identical, under *Your tags*, and it is a different column that does not exist.
`Kati.Screens.SeriesMeta`:

> `Kati.Media.Watch.tags` is comma-separated tags on *one night's watch*; these are tags on
> the title. Nothing stores a tag against a `Kati.Media.TrackedTitle`, and reading a title's
> tags out of its watches would make a tag vanish when the watch it happened to be typed on
> was deleted.

171 serves 33. It does not serve 14, and the board must not claim to.

**7. No tag taxonomy, no tag manager, no join table.** `Kati.Media.Watch`:

> Flat on purpose until something filters by them: a join table nothing queries is a
> migration with no reader.

A "used before" strip reads the existing rows. A tag editor with counts, renames and merges
would be designing a table that does not exist.

**8. `nil` on 144's rows currently means *nothing to disclose*, not *not yet wired*.**
`Kati.Screens.RateEpisode`:

> `Kati.Screens.Rating.context_card/1` always trails a chevron because every row there opens
> a picker eventually. This board draws none — three plain rows, the first alone carrying a
> mono `now` when the watched date is today's. `SettingsList.row/4`'s `trailing` is `nil` on
> the other two, which is the row with nothing to disclose, not a picker not yet wired.

The 144 edit is what makes that sentence true or false. Decide, then let the moduledoc be
corrected to match — do not leave the boards disagreeing and the comment asserting one side.

**9. The `5★`/`10pt` toggle and `HALF STARS ON` are not part of this.** `Kati.Screens.Rating`:

> Both are display preferences — which scale the user reads ratings on — and no resource
> holds one. `Kati.Media.Watch.rating` is the ten-point integer either way, and screen 35's
> settings are where a scale preference would live.

A scale picker drawn on one of these three sheets would put a global preference inside one
night's log. If it is wanted, it is an edit to 35.

## Left open — decide and note which way you went

- **Sheet or inline. This one first, because everything else follows it.** *Sheet*: the
  rows keep `chevron_right`, tap pushes 169/170/171, and 144 gains the chevrons it lacks.
  *Inline*: the card grows the grid or the field under the tapped row, 33 loses all three
  chevrons, 144 is already correct, and 169–171 become drawn expansions of 33's card rather
  than sheets. Both have precedent — seven screens use `Kati.UI.Sheet`, and 144's own
  rewatch card and 126's merged renewals both expand in place under `expand_more`.
- **Which board moves.** If it is *inline*, 33 is the one that changes; if it is *sheet*,
  144 is. Say which, in the board's caption, so the next reader does not re-litigate it.
- **What `+ tag` is.** Free text, a list of what you have typed before, or both. Both is
  the answer that costs the most drawing and the least typing.
- **What a comma does** in the With and tag fields — split, or refuse.
- **How a picker commits.** 94 commits on tap and has no button. A sheet with a free-text
  field cannot: it needs a Done, or it has to commit on close. Pick one rule for all three
  rather than one per sheet.
- **Whether `Where` stays one row on 33** or becomes two, one per column. Two rows would
  match the storage exactly and make the card four rows deep; one row is what is drawn.
- **The date sheet's shape.** A month grid is the general answer; *Today / Yesterday / Pick
  a date* is the fast one, and most logs are the same evening — 144 prints `Tonight` for
  exactly that reason.
- **The spoiler line on 33.** It is drawn as a `visibility_off` glyph and the words
  *Spoilers hidden*, and `spoiler_toggle/1` draws nothing at all when a review carries none.
  A switch is a different control from a label that disappears. Say which it is.
- **Whether 14's `+ tag` gets this sheet** the day a title-level tag column exists. Not
  this ticket, but the drawing should be shaped so the answer can be yes.

## Acceptance

The drawing is complete enough to build from when:

1. For each of the four rows, a reader can say **what a tap does and which column it
   writes** — `watched_on`/`watched_at`, `service`, `place`, `companions`, `tags`.
2. **33 and 144 print the same trailing mark** as each other on all three context rows, and
   one of the two captions says why.
3. Each of 169, 170 and 171 carries its **empty swatch inside its own frame**, under an
   `eyebrow_muted` label, in the 144 manner — because `Kati.ScreenEmptyDatabaseTest` reads
   these literals with nothing stored and an undrawn empty state is an untested one.
4. **169 carries the Persian grid** as a second swatch, starting on شنبه, in Shamsi months.
5. **171 shows what a comma does.**
6. Every literal appears **once** on the boards. `Kati.ScreenDesignLiteralTest` asserts each
   against the rendered tree, and copy in a drawing and nowhere in a tree fails the sweep.
7. Every subtitle's `font-size`, family and `margin-top` are drawn as numbers, because
   `Kati.ScreenTitleSubtitleTest` measures exactly those three.
8. Every glyph named is one of `close`, `chevron_left`, `chevron_right`, `schedule`,
   `search`, `check`, `do_not_disturb_on`, `place`, `group`, `label`, `history`, `info` —
   **all twelve are already in `Kati.Icons`' map**, so no `mix kati.gen.icons` run and no
   pyftsubset step is needed. If a thirteenth is wanted, name it here: `Kati.Icons.glyph!/1`
   raises for a name the font does not carry, which is the `star_half` story again.

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
