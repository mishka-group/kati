# The menus Meals draws and never opens

> **Modal sheet** · ticket `D-42`

Someone looks at tonight's dinner and wants to say one of five things: *this line is wrong*,
*take this line off*, *I'm not eating this one*, *take this meal out of the plan*, *that log
was a mistake*. Every one of those has a control already drawn for it, and not one of them
opens anything. Screen **43** gives the next meal a `more_horiz` disc beside **Mark eaten** and
**Swap**, and `Kati.Screens.MealsToday.overflow/0` renders it with no handler at all — *"It
carries no handler, and passing no `on_tap` wires none."* Screen **45** gives the whole meal a
44pt `more_horiz` in the header; that one carries `:more`, falls through to the screen's
catch-all, and sits in `Kati.ScreenTapSweepTest`'s Backlog as `{Kati.Screens.Meal, :more}`.
Screen **118** gives all four ingredient rows a `chevron_right`, and all four push screen
119 — *Add an ingredient* — a sheet whose header says so and whose bottom half previews the
**new** row it is about to append. Three affordances, one hole. The cost is legible two screens
away: screen 47 prints `Skipped` as a red figure and computes adherence as
`eaten / (eaten + skipped)`, and because nothing anywhere in `lib/` writes `state: :skipped`,
that figure is permanently `0` and that percentage permanently `100%`. Board 43 proves the same
hole from the other side — it draws a SKIPPED card, in its own photograph-less outlined
treatment, that no control in the app can produce.

## Exactly what to draw

| Board | What it is | What it carries |
|---|---|---|
| **185** — new | **Meal overflow**, a bottom sheet in `Kati.UI.Sheet`'s frame | the identity row naming which meal, then five actions in three scope groups: today, always, the record. It is the one door for 43's per-meal ⋯ and 45's header ⋯ |
| **186** — new | **Edit an ingredient**, screen 119's sheet retitled, prefilled and given a Remove | the same four bands as 119 (name/quantity/unit, aisle chips, nutrition paths, preview) with this line's stored values in them, and an outlined red **Remove** below a rule |
| **43** — edit | Meals today, redrawn | the per-meal ⋯ shown as a control that opens 185; **the SKIPPED card labelled as 185's output**; and a decision drawn, not assumed, about whether the eaten and skipped cards get a ⋯ of their own |
| **45** — edit | Meal, redrawn | the header ⋯ opening 185, and the sheet drawn over this screen so the scrim and the 250pt-panel question are settled on one board |
| **118** — edit | Create / edit a meal, redrawn | the four ingredient chevrons annotated with their real destination — 186, not 119 — and the `Add an ingredient` row kept visibly distinct from them |

Two sheets, because 45 *is* one meal and 43's card *is* one meal: the same sheet, titled by the
slot and opened with the meal's own identity row, answers both without a second drawing.

## Every element, and the glyph it takes

Every symbol below is already in `Kati.Icons`' inlined map. That is a hard constraint here rather
than tidiness: `test/design/material_symbols.codepoints` is not in the repo, `mix kati.gen.icons`
wants it, and per `docs/DESIGN-ASSETS.md` *"nothing is blocked until a new symbol is needed"* — so
a glyph invented on these boards is the thing that blocks the build.

### Artboard 185 — Meal overflow

| Element | Purpose | Glyph |
|---|---|---|
| Close disc, 36pt, leading | The only way out that is not a decision | `close` |
| Centred title — the slot, e.g. *Dinner* | Says what kind of thing the sheet is about; `Kati.UI.Sheet` centres it between two equal 36pt edges | — |
| **Identity row** — 52×52 photo at radius 13, eyebrow `19:30 · TODAY` in DM Mono, name at 15/700, `620 kcal` in DM Mono | Says *which* meal. It is the left half of 43's next-meal card, moved, so the sheet and the card cannot disagree about what a meal looks like | — |
| **Skip this meal** | Writes the `:skipped` log 43 already knows how to draw and 47 already counts | `do_not_disturb_on` |
| **Swap just today** | The pill 43 already has and 45 has nowhere; opens screen 46 | `swap_horiz` |
| — hairline rule — | Separates *today* from *always*. `Kati.UI.Menu.rule/0` is the same divider one surface up | — |
| **Edit this meal** | Opens 118 on this meal. Today 118 is reachable only from the 116 grid | `edit` |
| **Take out of the plan** | Removes the slot from the plan. Destructive ink | `event_busy` |
| — hairline rule — | Separates the plan from the record | — |
| **Delete this log** | Destroys one `Kati.Meals.MealLog` row. Destructive ink. **Present only when this meal has been logged** | `delete` |
| Cream consequence card with a leading glyph | One sentence saying that a plan change takes effect next Monday and that past days keep their numbers. Screen 49's discipline, printed rather than assumed | `info` |

The three-group shape is screen 04's menu order argued in `Kati.Screens.Series.menu/1` — *"what
this show IS, then how its episodes are numbered, then what Kati does about it"* — read for a
meal as **today · always · the record**.

#### The three decorative ⋯ — screens 48, 50 and 51

Boards 48 (Shopping), 50 (Share a plan) and 51 (Meal reminders) each draw the same 44pt header
`more_horiz`, and all three are built as `Kati.UI.SettingsList.chrome("more_horiz")`, whose
`disc/1` takes **no `on_tap` at all**. They are ink, not buttons. Whatever 185 turns out to
contain, say on this brief which of the two these three are:

- **the same menu**, in which case 185's row set has to make sense on a shopping list and on a
  reminder screen, which *Skip this meal* plainly does not; or
- **ink to drop**, in which case say so and the three boards lose a glyph.

There is a third reading already in the code and it should not survive: board **49** draws a
`more_horiz` too, and `Kati.Screens.Plans` wires it straight to screen 50. Across Meals the same
glyph currently means four different things — a per-meal menu, a screen menu, a one-destination
shortcut, and decoration. This brief is where that stops being true.

### Artboard 186 — Edit an ingredient

Screen 119, changed in four places and in no others. Drawing it as a near-copy is the point: the
sheet a person reaches by tapping an existing line should be the sheet they already know.

| Element | Purpose | Glyph |
|---|---|---|
| Close disc, 36pt, leading | Leaves the line as it was | `close` |
| Centred title — **Edit an ingredient** | The one word that separates this from 119. 119's own header is the reason all four chevrons are currently a lie | — |
| **State glyph tile** on the identity line — green check / bronze query / ink pencil | Says which of the three states this line is in, the way 118's rows do. `Kati.Screens.MealEdit.state_glyph/1` already draws all three | `check` · `help` · `edit` |
| Name row, **prefilled** — *Curry leaves* | The value 119 leaves as a draft placeholder | — |
| Quantity + Unit, **prefilled** — *a few* / *free* | Same; the unit keeps its trailing chooser | `unfold_more` |
| Aisle chips, with **this line's stored aisle selected** | 119 opens on `Uncategorised` because a new line has no aisle. An edit opens on the one the line already has | — |
| Nutrition per 100 g — three rows, two badged `NOT IN V1` | Unchanged from 119, including both refusal sentences | `edit` · `qr_code_scanner` · `search` |
| Preview card + note | The row as it will read **after** this change, not as a new row. The note's sentence changes with it | `info` |
| Commit pill, 54pt ink — **Save changes** | `Kati.UI.Sheet.commit/3`'s rule: the label is the sentence the sheet completes | — |
| — full-width rule, then a quiet eyebrow — | Puts the destructive action below the safe path rather than beside it | — |
| **Remove this ingredient** — 48pt outlined bar, `red_ring` border 1.5, no fill, label 13/700 in `#B4553C` | The one genuinely new control in this brief that can be built the day it is drawn: `Kati.Meals.Totals.remove_ingredient/1` exists and no screen calls it | `delete` |

## Where each action's write already exists

None of these five needs a new write path, which is why this is a design gap and not a code one.
Draw them knowing the machinery is standing by.

| Action on the board | What it already calls |
|---|---|
| Skip this meal | `MealLog`'s `create :log_recipe` with `state: :skipped` — already in the attribute's `one_of` — or `update :mark`, whose accept list is exactly `[:state, :note, :rating]` |
| Delete this log | `MealLog`'s `defaults [:read, :destroy]` |
| Correct an ingredient | `Kati.Meals.Totals.update_ingredient/2` — called today only from `meals_test.exs` |
| Remove an ingredient | `Kati.Meals.Totals.remove_ingredient/1` — called today only from `meals_test.exs` |
| Take out of the plan | `Kati.Meals.MealPlanSlot`, on screen 49's next-Monday terms |

## States to draw

`Kati.ScreenEmptyDatabaseTest` renders every screen with nothing stored and asserts the board's
literals against it, so a state left undrawn here is a state left untested. Four matter:

- **Resting.** 185 over 43 and 186 over 118, both with a full meal behind them.
- **Active.** A row under the finger, and — on 186 — a different aisle chip selected than the one
  the sheet opened on, so the chips read as controls rather than as a label.
- **Empty.** This is the one that bites. With nothing stored there is no active plan, so
  `Kati.Screens.MealsToday` falls back to `Kati.Meals.SampleToday` and `Kati.Screens.AddIngredient`
  to `Kati.Meals.SampleLibrary`'s draft — the sheets still open, over sample data, with **no log
  row behind them**. So draw 185 without its *Delete this log* row and say whether the row is
  absent or present-and-refusing, because the sweep will compare the board against a tree that has
  one or the other.
- **Error — the refusal, in words, with the sheet still open.** Both parents already do this and
  the sheets must match: `Kati.Screens.AddIngredient` prints `Nothing to save yet.` **above** the
  commit pill in `Palette.red()`, for the stated reason that the frame's 34pt bottom padding would
  swallow a notice under it; `Kati.Screens.MealEdit` prints its failure **under** the Save pill.
  186 needs the same sentence for Save and a second one for Remove. 185 needs the two refusals it
  can actually hit: skipping a meal already marked eaten, and deleting a log that is already gone.

## RTL

Yes, and cheaply — both sheets are rows of glyph · label, which mirror mechanically. Say on the
boards what mirrors and what does not:

- **Mirrors:** the whole grid under `dir="rtl"`; the close disc moves to the trailing edge; each
  row's glyph and label swap sides; 118's back pill glyph becomes `arrow_forward_ios` and its four
  ingredient chevrons become `chevron_left`; the identity row's photo moves to the right.
- **Does not mirror:** the photograph itself; the **vertical order** — *today · always · the
  record* runs top to bottom in both directions, and the destructive row stays last; the aisle
  chips' reading order within their scroller.
- Digits and times go Persian and Shamsi, both in DM Mono so the `620 kcal` column still aligns.

**One thing to know before deciding 43.** Board **59** — امروز, `Kati.Screens.TodayFa` — draws a
skipped meal card of its own and draws **no ⋯ anywhere**. Whatever 43 gains, 59 is a second board
with the same hole and no affordance at all; it needs its own ticket rather than a mirror of this
one, and 43's decision should be taken knowing it exists.

## Dark colourway

Not as separate artboards. Everything here is `Palette.card()`, `Palette.paper()` and
`Palette.ink_soft()`, which swap with the mode on their own.

**One exception, and it is checkable.** `Kati.Theme.Palette` stores red as
`{:red, 0xFFB4553C, 0xFFB4553C, …}` — byte-identical in the light and dark columns, as are
`red_wash` and `red_ring`. So `#B4553C` that reads as a warning on `#FBFAF8` is the same ink on a
`#1E1D1B` card, at a fraction of the contrast. Draw the destructive group — *Take out of the
plan*, *Delete this log*, and 186's *Remove* — once on dark ground as an inset on 185, and either
confirm the red holds or name the treatment that replaces it. No new artboard number for it.

## Reuse, do not invent

- **The sheet frame** is `Kati.UI.Sheet`: scrim `rgba(26,25,23,.42)`, paper ground, 26pt radius on
  the top two corners only, `18px 21px 34px` of padding, and a header of *close disc · centred
  title · a 36pt hole the same width as the disc*. The hole is real markup — the title is centred
  in the sheet, not in the space left beside the button.
- **The commit pill** is `Kati.UI.Sheet.commit/3` — 54pt, radius 27, ink fill, 14.5/700.
- **The row group** is `Kati.UI.SettingsList.card/1` with `Kati.UI.Menu`'s rhythm: 46pt rows, no
  chevron, because a menu row performs an action rather than promising another screen. The hairline
  between groups is `Kati.UI.Menu.rule/0`.
- **The destructive row** is `Kati.UI.Menu.item/4`'s `destructive: true` — the glyph and the label
  both in red, and nothing else about the row different.
- **The outlined destructive bar** on 186 is screen 31's *Delete event*: 48pt, radius 24,
  `red_ring` border at 1.5, no fill, `delete` at 18px beside a 13/700 label.
- **The identity row** is the left half of 43's own next-meal card.
- **The state glyph tile, the aisle chips, the nutrition rows, the `NOT IN V1` badge and the
  preview card** are 118's and 119's, unchanged.
- **The cream consequence card** is 43's own prep card ground, `#FBF1DE` at radius 20.

## What it must NOT do

- **It must not offer to edit a logged meal's figures.** `Kati.Meals.MealLog` is explicit:
  *"The snapshot is written once… **No update action accepts a snapshot column**… Re-logging is a
  destroy and a create, which is honest: it is a new claim about the past, not an amendment to an
  old one."* So 185's answer to a wrong log is *Delete this log* and log it again — never *Edit
  these numbers*.
- **It must not imply a plan edit changes history.** `Kati.Screens.MealEdit` states the rule the
  boards already carry: *"changes take effect next Monday, and past days keep the old numbers —
  nothing is recalculated."* *Take out of the plan* removes future slots and leaves every logged
  day alone, and the sheet says so before it is tapped.
- **It must not put text entry on 186's critical path.** `Kati.Screens.AddIngredient` is blunt
  about its own fields: *"`:edit_name`, `:edit_quantity` and `:edit_unit` are drawn rows that open
  nothing"* — Mob has no text input (#45). The name, quantity and unit on 186 are **drawn values**;
  the only controls that can be built on the day the board lands are the aisle chips, the commit
  and the Remove. Draw it so it is honest with three inert rows on it.
- **It must not make a destructive row louder than the rest.** `Kati.UI.Menu.item/4`:
  *"a red row that is also bigger or set apart reads as a different kind of control rather than the
  same control with a warning on it."*
- **It must not sit the destructive action beside the safe one.** `Kati.Screens.Restore`:
  *"the destructive action is reachable, never beside the recommended one"* — hence the rule above
  186's Remove. And `Kati.Screens.SearchIdle`: *"a destructive control below eight rows is a control
  you reach by scrolling past the thing it destroys"*, which is why *Delete this log* is the last
  row of a short sheet and not the last row of a long one.
- **It must not label the commit `Done`.** `Kati.UI.Sheet.commit/3`: *"the label is the sentence the
  sheet completes… Never `Done`, which says the sheet is finished rather than what it did."*
- **It must not let a per-meal control do something section-wide.** `Kati.Screens.MealsToday.menu/1`
  says why a header menu had to be added in code rather than borrowed from the card: *"The ⋯ that IS
  drawn on 43 belongs to the next meal's card — it sits beside that meal's title and calorie
  count — so wiring it here would make a per-meal control do something section-wide."* 185 is the
  card's menu. If 43's header also needs one, that is a second control and a second row set.
- **It must not treat the 118 chevrons as a naming problem.** `Kati.Screens.MealEdit.ingredient_tag/1`
  already gives every line its own tag and says what that did and did not buy: *"Naming them does not
  invent an edit screen."* The code can already say which line was tapped. What is missing is the
  screen to open with it.
- **It must not reorder the ingredient write.** `Kati.Meals.Totals` owns *bump the rev, write the
  line, store the totals*, and 186's Save and Remove both go through it. Nothing on the board may
  imply a line can be changed without the meal's totals moving with it.

## Left open — decide and note which way you went

- **Sheet or anchored panel.** This brief draws sheets, on the ticket's own reading. But
  `Kati.UI.Menu.overflow/4` already exists — a 250pt panel at radius 18, anchored below its trigger,
  dismissed by a tap outside. Five screens already use it — 02, 03, 04, 08 and 43's own *header* —
  and **not one of those menus is drawn on any board**; its moduledoc says so in the first
  paragraph. Either 185 replaces that panel for meals, or the two coexist and the boards say which
  ⋯ gets which. Do not leave it implied.
- **Does an eaten or skipped card get a ⋯?** 43 draws action pills only on the lifted *next* card;
  the eaten and skipped cards carry nothing. But *Delete this log* is only meaningful once a meal
  **has** been logged, which is exactly the two cards with no control on them. Either those cards
  gain a ⋯ or the delete lives somewhere else entirely.
- **Whether Skip belongs in an overflow at all.** Board 51 already draws the notification a person
  answers from the lock screen, and its three buttons are **Eaten / Skip / Snooze** — Skip sits one
  tap from the thumb there and three taps deep in the app. Screen 112's Medication took the other
  road for the same shape of decision, *"`Taken` and `Skip`, side by side rather than as a swipe: a
  dose is a thing you decide about once a day and a gesture with no affordance is not a control."*
  A third pill beside **Mark eaten** and **Swap** on 43 is a real alternative to a menu row.
- **What the skip does to the plan.** A skipped meal is one day's answer; a meal taken out of the
  plan is every week's. Two skips in a row are a question the board could ask and currently does not.
- **48, 50 and 51's ⋯** — same menu, or ink to drop. See above.
- **The exact destructive copy**, all of it: the row labels, the confirm (or the deliberate absence
  of one — screen 81's precedent is that *"the wipe confirmation is **inline**, not a modal: it says
  what survives before it asks"*), and whether an undo pill follows a delete the way screen 27's does.
- **Aisle vocabulary on 186.** 119's chips read `Dairy` and `Uncategorised`; screen 48's shopping
  list prints `Dairy & eggs` and `Other` for the same buckets, and `aisle_value/1` maps between them.
  An editor that opens on a line's *stored* aisle makes that mismatch visible in a way the add sheet
  never did. Decide which vocabulary 186 shows.

## Acceptance — how we know it is complete enough to build from

1. **Every affordance in this brief opens something named.** 43's per-meal ⋯, 45's header ⋯ and
   118's four chevrons each point at a numbered board on the drawing.
2. **185 lists its rows in order, with a glyph per row and the destructive ones in red**, and every
   glyph name appears in `Kati.Icons`' existing map.
3. **43's SKIPPED card is drawn as the output of a control on the same board**, so a reader can
   trace the state to the tap that makes it. Today the card exists and the tap does not.
4. **186 differs from 119 in exactly the four places named** — title, prefilled values, selected
   aisle, Remove — and is otherwise the same sheet, so the diff is reviewable.
5. **The empty state is on the board**: 185 with no log behind it, showing whether *Delete this log*
   is absent or refusing. `Kati.ScreenEmptyDatabaseTest` will compare against whichever is drawn.
6. **Both refusal sentences are written out**, in `#B4553C`, positioned where each parent already
   puts one — above the commit on a sheet, under the Save on 118.
7. **The dark inset of the destructive group exists** and either confirms `#B4553C` on `#1E1D1B` or
   replaces it.
8. **Three lines become deletable when this ships**: `{Kati.Screens.Meal, :more}` leaves
   `Kati.ScreenTapSweepTest`'s Backlog, `Kati.Screens.MealsToday.overflow/0` gains an `on_tap`, and
   `Kati.Screens.MealEdit`'s comment — *"the design draws no edit-an-ingredient screen"* — stops
   being true.

## House style — Kati

Draw into `examples/ui_design/Kati.dc.html` as a new `IOSDevice` artboard, 402×874.

**Numbering.** The app runs **01–166** and nothing may be inserted below 167. These boards take
the numbers reserved above.

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
