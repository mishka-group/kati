# The two write sheets Persian never got

> **Modal sheet** · ticket `D-45`

Boards 115 (سلامت) and 108 (اهداف) each draw a 44pt ink `add` disc in the header, and both
discs push an English, left-to-right screen into the middle of an RTL flow. The code says
so in its own margin — `lib/kati/screens/health_fa.ex:1029`: *"111 has no Persian mirror in
the 127, so the disc opens the English sheet rather than going nowhere."* The comment is
vintage (the set was 127 boards then, it is 166 now) and the fact it records has not moved.
A Persian reader's only route to writing down a weight, and their only route to setting a
goal, is a sheet in another language and another direction.

## What a person is trying to do, and what stops them

They have stood on a scale, or decided to read fifty-two books, and they are using Kati in
Persian. On 115 they press the one control in the header; the app pushes
`Kati.Screens.LogWeight` and the drawer that slides up is in English with its close disc on
the left. On 108 the same press pushes `Kati.Screens.NewGoal`, whose *By when* trough offers
a Year that ends on 31 December — the exact claim the cream card at the foot of 108 was
drawn to deny. Nothing is broken and nothing errors. The app simply changes language
underneath them at the one moment they are giving it something of their own, and there is no
board anywhere in 01–166 that draws either sheet in Persian: `grep -l 'ثبت وزن\|هدف جدید'
test/design/screens/*.html` returns nothing, and `lib/kati/screens/` holds thirty-four `*_fa`
modules and no `log_weight_fa` or `new_goal_fa` among them.

## Why this is its own brief

Because the repo files RTL that way. `D-15-goals-rtl`, `D-21-money-rtl` and
`D-03-album-detail-rtl` are each their own ticket rather than an appendix to the screen they
mirror, and this is a mirroring job with its own decisions rather than a new surface. The
precedent for a mirrored *sheet* is already drawn twice — board **72** is the log-progress
sheet turned round, board **156** the add-by-hand form — so this is 72's chrome applied to
111 and 156's field discipline applied to 106. The decisions it has to make are the ones 72
and 115 already answered and that these two sheets will hit again: the stepper column stays
symmetrical so the mono numeral aligns, weight keeps its Persian digits and U+066B as the
decimal separator, and a *this year* goal ends at the end of اسفند rather than 31 December.

## What to draw

| # | Artboard or edit | What it carries |
|---|---|---|
| **191** | **NEW — ثبت وزن**, the Persian log-weight sheet | Board 111 in the mirror: close disc at the leading right edge, the 0.1 stepper, the three-unit trough, the امروز / یادداشت card, the change line, the refusal, the commit. Reached from 115's `add` disc. |
| **192** | **NEW — هدف جدید**, the Persian new-goal sheet | Board 106 in the mirror: three eyebrows, ten chips in four labelled groups, the target stepper, the four-segment *By when* trough, the repeat row with its ink toggle, the refusal, the commit. Reached from 108's `add` disc. |
| **115** | **annotation, no new ink** | The `add` disc is already drawn. Say on the board that it opens **191**. Today no board says where it goes, which is how it came to open an English sheet without anyone deciding that. |
| **108** | **annotation, and one line to check** | Same for **192**. Then read 108's cream `info` card — *یک هدف «سالانه» در پایان **اسفند** تمام می‌شود، نه ۳۱ دسامبر* — against 192's *By when* trough and its repeat sub-line, and make the two agree on the board before either is built. |

Both new boards are **sheets, not pushed pages**: scrim, a paper drawer with a 26pt radius on
its top two corners only, `18px 21px 34px` of padding, a close disc and no back pill.

## 191 — ثبت وزن, element by element

| Element | Purpose | Glyph |
|---|---|---|
| Scrim + drawer | `Kati.UI.Sheet`'s exact chrome; the 40pt paper strip under the drawer is markup, not a spacer — the bridge takes one `corner_radius` for all four corners | — |
| Close disc, 36pt, at the **leading right** edge | `Kati.UI.Sheet.header/1` puts the disc first in a `Row`; the root declares `rtl` and it lands right by itself. Nothing reverses a list | `close` |
| Centred Persian title, Vazirmatn 14.5/700 | Board 72's header size, not 111's 15px — 72 is the drawn precedent for a Persian sheet title. The 36pt hole opposite the disc is real markup so the title centres in the sheet rather than in the remainder | — |
| Stepper: minus disc / hero trough / plus disc | 46pt discs, a 74pt trough, 11pt gaps. **The column stays symmetrical** — 72's caption is explicit that this is what keeps the numeral aligned when the value grows a digit | `remove` / `add` |
| Hero figure `۷۶٫۰` + unit word | Persian digits, **U+066B** as the decimal separator, at 111's 32px/500 and `-.02em`. 115 already prints `۷۶٫۰` this way and its own cream card names the separator | — |
| Step caption under the hero | 111's *0.1 steps* in Persian. `Kati.Screens.LogWeight.step/1` is a tenth of the **display** unit — 100g in kg, 45g in lb — so the caption is about what the reader sees, not about grams | — |
| Unit trough: three segments | kg / lb / st, order reversed. All three, always — see *What it must NOT do* | — |
| امروز row | 30×30 paper tile, title, and a Shamsi second line. `Kati.Calendar.Shamsi` is real and display-only, so `۲۵ مرداد، ۰۷:۴۲` is reachable where `Calendar.strftime`'s `16 August` is not | `event` |
| `اکنون` pill, 28pt, radius 14 | 111's control, mirrored to the trailing edge. It returns you to the clock from a time you changed, and there is nothing yet to change — draw it as 111 draws it and no picker behind it | — |
| Hairline, then یادداشت row | 111's second row, with the mirrored chevron | `sticky_note_2` + `chevron_left` |
| Cream change card | `Kati.UI.Sheet.insight/2` — cream ground, 18px gold glyph, rich text. Three cases and Kati draws exactly three: down, up, and no-change | `arrow_downward` / `trending_up` / `lightbulb` |
| **Refusal line**, red, directly above the commit | Undrawn on 111 and undrawn anywhere else in the 166. `save_notice/1` exists and has never had a picture | — |
| Commit, 54pt radius 27, ink fill | `Kati.UI.Sheet.commit/3` already takes a face — `commit(label, :save, "fa")` — so the Persian button needs no second implementation | — |

The neutral case takes `lightbulb` and **not** `trending_flat`: that glyph is not in Kati's
shipped icon subset and no drawing asks for it, and `mix kati.gen.icons` builds the font from
these boards. A new symbol on a board is a font rebuild.

## 192 — هدف جدید, element by element

| Element | Purpose | Glyph |
|---|---|---|
| Sheet chrome, close disc, centred Persian title | Identical to 191 so the two new boards agree with each other | `close` |
| Eyebrow «چه چیزی» — **accent** rule | 106 gives the accent dash to the first eyebrow only. One accent thing per screen | — |
| Four group labels + ten chips | The groups are `Kati.Goals.Goal.sections/0`'s — Screen, Books, Music, Health — in that order, and the ten chips are its `kinds/0`. The group label in Persian is Vazirmatn, not DM Mono | — |
| Eyebrow «چه تعداد» — **quiet** rule (`#C4BDB3`) | — | — |
| Target stepper | 106's 64pt trough, mirrored, with the kind's unit as the caption under the numeral | `remove` / `add` |
| Eyebrow «تا کی» — **quiet** rule | — | — |
| *By when* trough: four segments | هفته / ماه / سال / دلخواه, order reversed. This is the trough that has to agree with 108's cream card | — |
| Repeat row: tile, title, sub-line, ink toggle | `repeat` is a property of the goal, not a setting about goals — it is on this sheet *and* on 104's card, and 108's mirror of that card is where it is read back | `repeat` |
| Toggle, 46×28, radius 14, knob at the trailing edge | Mirrors with the row; the knob's *on* position is the leading right edge under `rtl` | — |
| **Refusal line**, red, above the commit | Same as 191, same reason, same undrawn state | — |
| Commit «ذخیره هدف» | `Sheet.commit(label, :save, "fa")` | — |

## States: which ones matter, and why

`Kati.ScreenEmptyDatabaseTest` gates 111 on `Kati.Screens.Weight.entries/0` and 106 on
`Kati.Screens.Goals.goals/0`, asserting each screen's literals again with nothing stored.
191 and 192 will be gated the same way, so **an empty state that is not drawn becomes an
empty state that is not tested**.

- **Resting.** 191 opened on the last reading with `کیلوگرم` selected; 192 with a kind and a
  period already chosen, because both sheets open with a selection rather than blank.
- **Active.** The pressed segment and the selected chip. On both sheets one segment and one
  chip are *already* the selected member — `Kati.ScreenTapSweepTest` lists
  `{Kati.Screens.NewGoal, :kind_films}`, `{…, :period_year}` and
  `{Kati.Screens.LogWeight, :unit_kg}` as inert for exactly that reason. Draw the raised
  tile and the ink chip so the mirror can be read against the same rule.
- **Empty — 191's first reading.** `Kati.Screens.LogWeight.drawn_change/0` answers *"Your
  first reading — there is nothing to compare it with yet"* when nothing is stored, and no
  board in any language draws that sentence. It is the state a Persian reader meets on their
  very first weighing, and it is the one this brief most needs a picture of.
- **Empty — 192.** The sheet reads no rows of its own; its gate is 104's list, because a
  sheet whose types disagreed with the page that opened it is the defect worth catching. Say
  on the board that 192 has no empty state distinct from resting, rather than leaving it
  silent — the sweep cannot tell an omission from a decision.
- **Error — both.** The refusal. `Kati.Write`'s contract is that a failed save keeps the
  sheet open with the value still in the stepper and says so in red above the button just
  pressed. Neither sheet's refusal has ever been drawn, in either language, and a Persian
  refusal is the one that most needs its line length checked: Vazirmatn at 12.5/1.45 wraps
  differently from Plus Jakarta Sans.

## RTL — what mirrors and what does not

This board **is** the Persian mirror; the question is what within it turns round.

**Mirrors.** The whole grid, via `dir="rtl"` on the root container — not a fork. The close
disc to the leading right edge. The segment order in both troughs. The chip flow. Every row:
tile right, value and chevron left. The chevron itself becomes `chevron_left`. The toggle's
knob. The cream card's glyph to the right of its text. Dates go Shamsi and digits Persian.

**Does not mirror.** The vertical order — امروز still above یادداشت, *What* still above *How
many* above *By when*, exactly as 111 and 106 stack them; a mirror reverses reading
direction, never band order. The stepper column stays symmetrical, which is 72's rule and the
reason the numeral still sits under itself. There is no artwork on either sheet, and artwork
would not mirror if there were. The vertical `arrow_downward` in the change line has nothing
to flip. Neither sheet has a back pill to flip a glyph on — a sheet closes, it does not go
back — so `arrow_forward_ios` belongs on 115 and 108 and on neither new board.

**The numerals are the hard part, and it is a type problem rather than a direction one.**
`Kati.Screens.Fa`'s moduledoc:

> `kati_mono.ttf` contains **zero** of U+06F0–U+06F9; Vazirmatn carries all ten. So anything
> numeric that the design sets in mono is set here in `fa` at the design's size and colour.
> The face is wrong and the glyphs are right, which is the better half of an unwinnable
> trade.

So label every numeral on 191 and 192 as *Vazirmatn at the mono size and colour*, not as DM
Mono. What the mono face was protecting — the figures lining up down the page — survives,
because that is the card's padding rather than advance width. What is lost is the tabular
tick inside a figure as the stepper counts, and it comes back when the subset is regenerated.

## Dark colourway

**Not needed for either board.** 111 and 106 have no dark board either, and neither sheet
introduces a surface the dark palette has not already answered: scrim, paper, card, cream,
ink fill and the red of a refusal are all tokens, and `#121110` / `#1E1D1B` / `#F5F2EE` cover
them. The one dark board in this area, **110**, is a states sheet reporting on 109 rather
than a sheet chrome. Two things are worth a written note instead of a drawing: the scrim is a
flat `#6B1A1917` fill rather than transparency — the sheet is drawn *over* the page, not
composited with it — and the cream card is the surface that changes most between colourways,
so if either board moves anything on or off cream, say what the dark side of it is.

## Reuse, do not invent

- **The sheet chrome** is `Kati.UI.Sheet`'s, and the mirrored version of it is board **72**,
  which has already been built: `Kati.Screens.LogProgressFa` declares `layout_direction="rtl"`
  on its own root `Box` rather than calling `Kati.Screens.Fa.pushed_frame/1`, because that
  frame draws a page and this is a drawer. 191 and 192 are the second and third of these.
- **The commit** is `Kati.UI.Sheet.commit/3`, which already accepts a face. There must not be
  a fourth ink button.
- **The eyebrow** is `Kati.Screens.Fa.eyebrow/1` — Vazirmatn 11/600 with no tracking, which
  is what all four Persian boards draw, not `Kati.UI.eyebrow/2` with a translated label. Note
  for whoever builds it: `Fa.eyebrow/1` paints the accent dash unconditionally, where
  `UI.eyebrow/2` takes a `:dash`. 106 draws two of its three eyebrows quiet, so the board is
  the authority and the Persian helper needs the option its Latin twin already has.
- **The chips** are `Kati.Screens.AddByHandFa.status_chip/2` — board 156's recipe, built by
  hand at 32pt/radius 16/padding-x 15 precisely because `Kati.Components.MishkaChip` takes its
  label as a **prop** and builds the `Text` with no face. Ten chips on 192, one recipe.
- **The segmented trough** is the same story: `Kati.UI.Segmented.plain/2` builds its own
  `Text` and has no `font_family` anywhere in the file, which is why `LogProgressFa` wrote
  `segments/2` and `segment/3`. 191 and 192 use 72's, not a third.
- **The rows** are the standard list row — 30×30 paper tile at radius 9, 13.5/600 title,
  11.5 sub — and a chevron means *leads elsewhere*.
- **The change card** is `Sheet.insight/2`, cream, and it is the same component 72's
  `lightbulb` line uses.
- **The Shamsi date** is `Kati.Calendar.Shamsi`, which already holds the twelve month names
  and starts its weeks on شنبه. Do not spell a Persian month on a board by hand.
- **The 115 and 108 discs** are drawn already. These are annotations, not redraws.

## What it must NOT do

Every line here is a decision the codebase has already made.

**Do not make the unit switch convert anything.** `Kati.Health`:

> **Units are a display choice, never a stored one.** `Kati.Health.Reading.grams` is grams,
> always … Screen 111 puts the unit switch inside the sheet as well as in Settings, and its
> caption says why: *changing it here is a correction, not a preference*.

191 draws the same switch for the same reason. It says which number you just read off a
scale; it does not rewrite the log.

**Do not drop a unit segment from the Persian trough.** All three write one device-wide key
through `Kati.Health.put_unit/1`, read back by 109, 115, this sheet and Settings. A Persian
sheet with two segments makes the third unreachable in Persian while still being the app's
current setting — and 111's `st` case is the one that prints `12st 0.4`, a format nothing
else in the app produces.

**Do not draw a target, an ideal range, or a colour that means bad.** `Kati.Health`:

> **Kati is not a medical device.** … nothing here computes a dose, warns about an
> interaction, infers a trend or advises anything. It records what it was told.

`Kati.Screens.LogWeight` says the same from the screen's side: the confirmation compares with
the last reading and *"No target, no ideal range, no colour that means bad."* The green
`arrow_downward` on 115 is a direction, not a verdict.

**Do not draw a date or time picker behind the `اکنون` pill.** That is a different gap
(`log-weight-when`) with a different blocker — Mob has no date input, which is #45 — and
answering it first in Persian would put a control on 191 that 111 does not have. Draw the
pill 111 draws.

**Do not draw what the یادداشت chevron opens.** Also a separate gap (`weight-reading-note`),
also blocked on #45. `Kati.Health.Reading.note` exists and `save_reading/1` never sets it;
111 renders the row with no `on_tap` at all. 191 mirrors the row as 111 draws it.

**Do not put a keyboard anywhere on either sheet.** Every value on both is a stepper, a chip
or a segment, and that is not a style: `Kati.ScreenTapSweepTest` records it as *"Mob has no
text input — every field in this app is drawn rather than typed into, which is #45."*

**Do not give the Persian sheets their own write.** `Kati.Screens.AddByHandFa` set the rule
for a Persian mirror of a form:

> The write. `Kati.Screens.AddByHand.save/1` is the one path a hand-typed row takes in either
> script, so the two cannot disagree about what reaches `Kati.Media.TrackedTitle`.

191 saves through `Kati.Screens.LogWeight.save_reading/1` and 192 through
`Kati.Screens.NewGoal.save_goal/1`. Anything the board asks for that those two do not write
is a defect in the drawing.

**Do not draw a Shamsi deadline as though the arithmetic produced it.**
`Kati.Screens.GoalsFa`, about the very card 192's trough has to agree with:

> Saying it is all a screen can do. Making it true means a Shamsi `period_phrase/1` and a
> Shamsi roll-forward for `repeat`, and both belong in `Kati.Goals` beside the dates they
> shape … Until that lands, the note is honest and the arithmetic underneath it is not, and
> that is named here instead of being papered over with a translated month name.

`Kati.Screens.NewGoal.window/2` writes `Date.new!(today.year, 12, 31)` for `:period_year`.
Whatever 192's repeat sub-line says, the board must say which of the two it is describing.

**Do not translate a stored goal's title on the way back.** `Kati.Screens.GoalsFa` again:

> A goal the reader actually stored keeps its English title and English projection, because
> composing a Persian one needs the unit and the period phrase in Persian and those live on
> `Kati.Goals.Goal`, not on a screen. Its figures still fold to Persian digits.

So a goal made on 192 arrives on 108 with an English sentence and Persian numerals. If the
board wants otherwise, it is asking for `Kati.Goals.Goal.unit/1` and `title/1` to gain a
Persian column — say so, rather than drawing the outcome.

**Do not reverse the vertical order**, and do not flip the change arrow. Direction of
reading is not direction of time, weight or motion — 72's caption settled that for the timer
face and it settles this.

## Left open — decide and note which way you went

- **All Persian copy.** 72's board says it outright: *all Persian copy was open; these strings
  are proposals*, and `Kati.Books.SampleFa.sheet/0` holds 72's in one place so a native
  reader corrects each once. The titles, the step caption, the two commits, the three change
  sentences, the refusal, the repeat sub-line and the ten chip units are all open here.
- **The unit labels, which are worse than they look.** 115 writes the kilogram as a word,
  `کیلوگرم`. The pound's Persian word is `پوند` — and `پوند` is already the drawn word for
  the *currency* pound on board 56 (`۸٫۹۹ پوند`, the precedent `D-21-money-rtl` cites). And
  `سنگ` for a stone names a unit with essentially no readership in Iran. Words, Latin
  abbreviations, or a mix: pick one and say why. The segment cannot be removed.
- **Whether the repeat sub-line reads `۱ فروردین` or `۱ ژانویه`.** The first agrees with
  108's cream card and runs ahead of what `window/2` writes; the second is honest about the
  stored date and contradicts the card two screens away. There is no third option and this is
  the single most consequential decision on 192.
- **Whether 192 carries 108's cream `info` card too**, so the Shamsi year rule is stated where
  the period is chosen rather than only where it is read back.
- **Whether the `اکنون` pill and the یادداشت chevron are drawn at all on 191.** Both are
  drawn on 111 and neither leads anywhere; a chevron that means *leads elsewhere* on a row
  that does not push a screen is the one place this mirror inherits a problem rather than a
  pattern. Mirror them, or mark them on the board as awaiting `log-weight-when` and
  `weight-reading-note`.
- **Whether the Shamsi date on the امروز row carries a weekday.** 115's subtitle does —
  `یکشنبه ۲۵ مرداد` — and 111's second line does not.
- **Whether the ten chip units get Persian words**, and if so whether they key by position
  against the board the way `Kati.Screens.GoalsFa.goals/0` and
  `Kati.Screens.AlbumDetailFa.tracks/0` do, or whether `Kati.Goals.Goal.kinds/0` grows a
  Persian column. The second is the better answer and it is a domain change, not a screen one.
- **Whether 115 and 108 get an annotation or a redraw.** An annotation is enough for the
  disc's destination; a redraw is needed if either board is to show the sheet open over it.

## Acceptance — how we know the drawing is complete enough to build from

1. Every control on 191 and 192 maps to a tag `Kati.Screens.LogWeight.handle_info/2` or
   `Kati.Screens.NewGoal.handle_info/2` already answers. A control on the board with no
   handler behind it is a second app, not a mirror.
2. **No numeral on either board is set in DM Mono.** Every one is Vazirmatn at the design's
   mono size and colour, per `Kati.Screens.Fa` — and `Kati.PersianFontTest` is the thing that
   will notice if a board is drawn one way and built the other.
3. Every decimal separator on 191 is **U+066B** and every group separator **U+066C**. No
   ASCII dot and no ASCII comma inside any numeral on either board.
4. The units number **three** on 191 and the kinds number **ten in four groups** on 192 — not
   two, not nine.
5. Both refusal lines are drawn, in Persian, directly above the commit.
6. 191's first-reading empty state is drawn, or the board explicitly says it delegates to
   111's sentence in translation. Silence here is a state the sweep cannot test.
7. 115 and 108 each say on the board what their `add` disc opens.
8. The band order of 191 matches 111 and 192 matches 106, band for band. The only reversals
   are horizontal.
9. 192's *By when* trough and repeat sub-line do not contradict 108's cream card, and the
   board records which of the two the arithmetic currently supports.
10. Both boards can take their place in `Kati.ScreenEmptyDatabaseTest`'s gate table the way
    111 and 106 do — 191 gated on `Kati.Screens.Weight.entries/0`, 192 on
    `Kati.Screens.Goals.goals/0`.
11. `grep -l 'ثبت وزن' test/design/screens/*.html` returns 191 and `grep -l 'هدف جدید'`
    returns 192 — the two greps that return nothing today.

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
