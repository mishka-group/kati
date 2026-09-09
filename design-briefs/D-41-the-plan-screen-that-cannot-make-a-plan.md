# Board 49 makes three promises it has no surface for

> **Two new artboards and three redraws** · ticket `D-41`

Board 49 ends on a bordered footnote that states the whole of Kati's profile mechanism in
one sentence — *"A plan owns its meals, targets and reminder times. Switching swaps all
three at once."* Someone reads that, believes it, and then finds that **not one of the
three is editable from anywhere in the drawn set**. The `add` disc in 49's header opens
nothing, because no board in 01–166 draws a plan editor. The *Switch takes effect ›*
chevron opens nothing, though `Kati.Meals.MealPlan.activates_on` has been sitting there
waiting for the date since the schema was written. And reminder times — the third thing 49
claims to own — live on screen 51, the one Meals screen the design gives no door at all,
which is why the code went and invented a `more_horiz` disc in 43's header that `43.html`
does not draw. Three promises, one card, nowhere to keep any of them.

## Why this is one brief and not three

It is one board and one problem, three times. Splitting it would send the same owner back
to the same artboard three times over, and — worse — it would let the reminders door be
decided in isolation from the screen that claims to own reminders. The reminders question
is *"is this a row in 49's Switching group or a fifth-and-a-half tile on 43?"*, and that is
not answerable without looking at what else 49's card list is about to gain. Screen 51's
own title says the same thing: it reads **Reminders** over **Cutting v3** — a plan's name,
not a section's — so the door belongs wherever the plan does.

## What to draw

| # | Artboard or edit | What it carries |
|---|---|---|
| **183** | **NEW — Plan editor** | Name, photo, the five targets, the duration rule, and the five-slot × seven-day matrix a recipe attaches to. Reached from 49's `add` disc for a new plan, and from 44's `edit` disc for the plan you are looking at. |
| **184** | **NEW — When the switch takes effect** | The small screen behind 49's *Switch takes effect ›* chevron. Stores one `:date` and nothing else. |
| **49** | **redraw** | The reminders door; the third Switching row, which currently draws a concept the schema retired; the deletion of the import card the code invented at the foot of this screen; and the first honest empty state — no plans at all. |
| **43** | **redraw, if the reminders door lands here** | A sixth destination on a five-across tile row. If it lands on 49 instead, 43 is untouched and the invented header disc is deleted from the code. |
| **44** | **annotation, no new ink** | The `edit` disc is already drawn; it currently opens 49, the *list*. Say on the board that it opens **183** with this plan loaded. |
| **51** | **conditional edit** | Its back pill reads `‹ Meals`. If the reminders door lands on 49, that pill has to become `‹ Plans` or the journey lies about where it came from. |

## 183 — the plan editor, element by element

Header and identity:

| Element | Purpose | Glyph |
|---|---|---|
| Back pill `‹ Plans` | 183 is pushed from 49 | `arrow_back_ios_new` |
| **Save** pill, ink, 38pt high, radius 19 | 118's exact header pair — a pushed editor with a committing action opposite the back pill, not a 54pt primary button at the foot | — |
| Title, editable — *New plan* / the plan's name | `name` is the one `allow_nil?: false` column on `Kati.Meals.MealPlan`. Draw the refusal when it is blank | — |
| Photo slot | 49's saved rows lead with a 44pt photograph (`photo_seed`). **Draw the no-photo case**: `Kati.Screens.Plans.thumb/1` already falls back to a plain `Palette.placeholder()` box and no board anywhere shows it. 118's empty photo slot is the recipe — a 26px glyph in `#B3ACA2` over *Add a meal photo* | `add` |

Targets — **exactly five fields, no more**:

| Element | Purpose | Glyph |
|---|---|---|
| Calories | `target_kcal` | `local_fire_department` |
| Protein / Carbs / Fat | `target_protein_mg`, `target_carbs_mg`, `target_fat_mg`. Shown in grams, DM Mono | `nutrition` on the group tile |
| Fibre | `target_fibre_mg` — the fifth target the schema holds and 49's `2,100 kcal · 168P 210C 70F` line does not print | — |
| Tolerance note or field | `tolerance_permille` defaults to 950, and that 95% is the tick screen 47 draws on every bar. Either expose it or say in the footnote that it is fixed | `straighten` |

The rule — 44's repeat card, in its editable form:

| Element | Purpose | Glyph |
|---|---|---|
| **Repeats · Every week** | `repeat` is a single-valued enum. Draw it as a stated fact with no picker behind it, or as a disabled row — **not** as a chevron promising choices | `repeat` |
| **Started** — a date | `starts_on` | `event_available` |
| **Runs for** — N weeks, or *indefinitely* | `weeks_total`, where nil means indefinitely and 12 gives 49's *Week 6 of 12* | `date_range` |

The slots — the part that has never been drawn anywhere:

| Element | Purpose | Glyph |
|---|---|---|
| Day selector, `M T W T F S S` | Monday is 1, matching `day_of_week` and 44's own column heads | — |
| Slot row: name + time | `slot_name` (free text — *Breakfast*, *Snack*, *Snack* twice is legal, they differ by `position`) and `slot_time`, a **floating** time | `schedule` |
| Slot state, three ways | `:planned` / `:free` / `:open`. Reuse 44's Planned / Free / not-in-plan cell legend so the editor and the matrix agree | `radio_button_checked` |
| **Attach a meal** on a slot | The one thing the whole area is missing. Opens screen **116**, the Meal library, as a picker and returns a `recipe_id` | `restaurant` |
| Attached meal row, with a way off | Clearing a slot sets `recipe_id` to nil and leaves the slot standing | `close` |
| Portion stepper `− 1.0× +` | `portion_milli`, 1000 = 1.0×. Screen 45's component, not a second one | `remove` / `add` |
| Reorder handle within a day | `position` orders two snacks that share a name | `drag_indicator` |

The foot:

| Element | Purpose | Glyph |
|---|---|---|
| Cream card — *this plan is active* | 118's precedent, word for word in shape: *"Changes take effect next Monday · This week's plan keeps the meal as it was"*. Editing the live plan mid-week is exactly the failure 49's scheduling exists to prevent | `event_upcoming` |
| **Archive this plan** | `status` has a third value, `:archived`, and nothing draws it | `inventory_2` |
| **Delete**, with a confirmation | `MealPlanSlot`'s reference is `on_delete: :delete` — deleting a plan takes its 35 slots with it. Draw the sentence that says so | `delete` |

## 184 — when the switch takes effect, element by element

| Element | Purpose | Glyph |
|---|---|---|
| Back pill `‹ Plans` | — | `arrow_back_ios_new` |
| Title *Takes effect* + the plan's name underneath, `:name` style | Screen 51's subtitle does the same thing: the plan, not the section | — |
| **Next Monday** — the pre-selected shortcut | 49's drawn value, and the reason the row's sub-line says *keeps this week intact* | `event_upcoming` |
| **The first of next month** | The second natural boundary. Optional; say if you drop it | `calendar_month` |
| **Pick a day** — a month grid | Screen **16** is the month grid and already exists. Do not draw a second calendar | `calendar_month` |
| The consequence line | One sentence naming which week keeps its old targets. `keep_history` is a separate switch on 49 and this screen must not restate it as a choice | `history` |
| Confirm | A `Save`-style header pill, matching 183, so the two new boards agree with each other | `check` |

## The three redraws, stated exactly

**49 — the reminders door.** A row or a tile that opens 51. Its glyph is `notifications`,
which nothing else in Meals uses: 51's own moduledoc checks all seven sibling boards glyph
by glyph and finds *"none of them a bell"*.

**49 — the third Switching row.** The board draws `auto_mode` · *Auto-switch · Travel week
when a trip is on the calendar* with a toggle. That is retired — there is no trip in Kati —
and the app ships `event_upcoming` · *Switch on a date · Travel week takes effect next
Monday* with a chevron in its place. The redraw makes the board say what the app does. That
row is a second door into **184**.

**49 — delete the import card.** `Kati.Screens.Plans.import_row/0` builds a whole
`SettingsList` card (`download`, *"Import a plan · From a link or a code somebody sent
you"*) that `49.html` does not draw — `grep -c Import test/design/screens/49.html` returns
0. Board **50** already draws the real transfer group, and *Import a shared plan* is its own
brief. Take the invented card out of the redraw and let 50 own the journey.

**43 — only if the door lands here.** The tile row is five across —
`grid_view` Library, `calendar_view_week` Week, `shopping_cart` Shop, `monitoring`
Nutrition, `tune` Plan. A sixth does not fit that rhythm, which is the whole difficulty.

## States to draw

Kati's sweeps compare an empty state against a board, so an undrawn empty state becomes an
untested one — `Kati.ScreenEmptyDatabaseTest` is explicit that a screen either falls back to
its own drawing, has an empty board, or is listed as having none.

- **Resting.** 183 with a plan loaded and its week filled; 184 with *Next Monday* selected.
- **Active.** 183's live-plan case: the cream *this plan is active* card present, and the
  Save that schedules rather than applies. This is the state that distinguishes editing the
  plan you are eating from editing one on the shelf.
- **Empty — three of them, and all three are load-bearing.**
  1. **183 with nothing in it** — a new plan: no name, no photo, no targets, 35 empty slots.
  2. **183's slot picker with no meals to pick** — screen **117** is *Meal library — empty*
     and already exists; say whether 183 routes there or draws its own line.
  3. **49 with no plans at all.** `Kati.Screens.Plans.load/1` assigns
     `SampleProfiles.plans()` unconditionally, so 49 has never once been drawn or rendered
     empty. The moment a plan can be created, a plan can also be the *first* plan, and the
     screen before it has no picture.
- **Error.** Two real ones, both from the schema rather than invented: **Save with no name**
  (`name` is `allow_nil?: false`), and **the second active plan** — a partial unique index
  named `meal_plans_single_active_index` with the message *"another plan is already
  active"*. Draw where that sentence lands.

## RTL — does this need a Persian mirror?

**Yes, and the matrix is the reason.** 183 is the first editor in the app to draw a
seven-column week grid *and* editable fields together, and getting the day columns to run
right-to-left while the mono times stay column-aligned is not something a build can be
trusted to infer. Draw 183 in Persian; 184 can be described rather than drawn, because it is
a list of three rows and a month grid that screen 16 has already mirrored.

What mirrors: the whole grid, the back pill's position, the row layout, the day columns
(Monday still first, now on the right). Dates go Shamsi and digits Persian, both in DM Mono.
What does **not** mirror: the meal photographs, and the **vertical order never reverses** —
name still above targets, targets still above slots. The back pill's glyph flips to
`arrow_forward_ios`; chevrons become `chevron_left`. The `− 1.0× +` stepper keeps minus on
the leading edge, which in RTL is the right.

## Dark colourway

**Not needed for either board.** Neither 183 nor 184 introduces a surface the dark palette
has not already answered: 183 is card, paper tile, chip and cream on `#121110` / `#1E1D1B`,
and 184 is a settings list plus screen 16's grid. The one thing worth a note rather than a
drawing is 49's **active card, which is drawn on ink in light mode** — `Palette.ink_fill/0`,
the one card in the app inverted that way — so if the 49 redraw moves anything onto or off
that card, say what the dark side of it is.

## Reuse, do not invent

- **183's header** is 118's header: floating back pill plus a 38pt ink `Save` pill. 118 is
  screen 45 switched to an editable mode; 183 should be 44 switched to one, the same way.
- **183's matrix** is 44's matrix — 37pt cells, three states, names listed underneath. 44's
  moduledoc has the arithmetic for why the cell is 37 and not 35.
- **The portion stepper** is screen 45's, and 118 already reuses it. There must not be a
  third implementation.
- **The targets card** is 47's figures in a settings card, not a new chart.
- **The cream active-plan card** is 118's, glyph and sentence shape included.
- **184's month grid** is screen **16**.
- **The meal picker** is screen **116**, entered as a picker rather than as a shelf.
- **Every row** is the standard list row — 30×30 paper tile, 13.5 title, 11.5 sub — and
  **a chevron means *leads elsewhere***. 183's *Repeats · Every week* row must therefore not
  carry one.
- **The bordered footnote** is 49's own: solid `1.5px`, `rgba(26,25,23,.16)`, 15pt padding,
  17pt `info` glyph. It is redrawn rather than borrowed from `SettingsList.note/2` because
  that one pads 16 and sets its glyph at 18.

## What it must NOT do

Every line here is a decision the codebase has already made.

**Do not draw an auto-switch toggle.** `Kati.Meals.MealPlan`:

> **"Auto-switch · Travel week when a trip is on the calendar"** is **retired**. There is no
> trip in Kati — no travel entity, no location state … A boolean pointing at a concept the
> schema cannot express is a column that can only ever be false.

**Do not make switching instant, and do not put an "apply now" default on 184.**
`Kati.Screens.Plans`:

> Switching is **scheduled**, not instant. "Next Monday · keeps this week intact" is the
> design's answer to the obvious bug of flipping targets half-way through a logged week, and
> it is drawn as a disclosure rather than a switch because it opens a date rather than
> toggling a behaviour.

**Do not draw a date that persists after the switch.** `Kati.Meals.Changes.RecordUse`:

> `activates_on` is cleared because it is a **scheduled** switch … A date that survives the
> switch it asked for would fire again on the next read.

So 184 has no *repeat this switch* and no *every Monday*.

**Do not let the editor produce a second active plan.** The index is real, not a convention:

> "Exactly one active" is a partial unique index, not a convention. A second active plan
> makes every "what am I eating" query ambiguous.

An *Active* switch on 183 is therefore the wrong control; activation stays on 49's Activate
pills, where the app already stands the old plan down first.

**Do not draw more than one week.** `Kati.Meals.MealPlanSlot` holds 35 rows and 44's caption
is the rule: *"The plan is a rule, not 52 copies."* No *copy to next week*, no month view.

**Do not put a `:today` state in the editor's matrix.** `Kati.Meals.MealPlanSlot`:

> The drawing lists a fourth — `:today`, inked with an accent pip — and it is **not** here:
> today is a fact about the calendar, not about the plan. Storing it would mean 35 rows to
> rewrite at midnight and a plan that is wrong for anyone it is shared with.

**Do not attach a timezone to a slot time.**

> `07:30` means half past seven **wherever you are**. Storing it as an instant makes
> breakfast arrive at 04:30 the morning after a flight to Tehran.

**Do not require a meal in every slot.** A `:planned` slot with a nil `recipe_id` is a
legitimate state — *"the slot existing with nothing decided for it yet"* — and different
from `:free`. The editor must be saveable with slots still undecided.

**Do not draw a recipe editor inside 183.** Creating a meal is `Kati.Meals.Recipe`'s own
gap, covered by `D-20-create-edit-a-meal` and board 118. 183 attaches an existing recipe to
a slot and stops there.

**Do not draw notification action buttons on any reminders door or preview.**

> There is no `notification_actions` column. Mob supports no notification actions on either
> platform … so screen 51's inline Eaten/Skip/Snooze is retired.

**Do not add ink to 43 to solve the reminders problem without redrawing 43.** That is the
mistake already in the tree, and the code admits it in the docstring of
`Kati.Screens.MealsToday.menu/1`:

> Added to screen 43's header, which the drawing does not draw. The ⋯ that IS drawn on 43
> belongs to the next meal's card … so wiring it here would make a per-meal control do
> something section-wide.

Screen 51's own moduledoc says the same from the other side — *"the entry point is missing
from the **design**, not from the code, and the honest state is to leave it"*. This brief is
what unblocks both.

**Do not treat 50's *Reminder times* row as the door.** It is a toggle on the export —
*"Recipient can change them"* — under *What travels with it*, not a way in.

## Left open — decide and note which way you went

- **Where the reminders door goes.** A row in 49's Switching group — which then needs its
  own eyebrow, because reminder times are not switching — or a sixth destination on 43's
  five-across tile row. Whichever you pick, say whether 51's back pill stays `‹ Meals` or
  becomes `‹ Plans`.
- **Whether 184 is a pushed screen or a modal.** Every Meals board so far is pushed, and 184
  is a three-row list; a sheet would also be defensible. The back pill versus a grabber is
  the whole of the difference and it has to be drawn one way.
- **Whether 183 is a new screen or 44 switched to an editable mode**, the way 118 is 45
  switched to one. If it is a mode, 44 gets a second state on its own board and 183 becomes
  that state's artboard rather than a separate destination.
- **Whether *the first of next month* survives** as a shortcut on 184, or whether it is
  *Next Monday* plus a grid and nothing else.
- **Whether the tolerance band (95%) is editable** on 183 or stated as fixed.
- **Whether 49's empty state is a band on 49 or its own board**, the way 117 is 116's.
- **Where the second-active-plan refusal appears** — on 183's Save, on 49's Activate pill,
  or both.
- **Whether 120's back pill is redrawn.** It reads `‹ Plans`, which is why the import card
  got invented on 49 in the first place. Deleting that card leaves 120 pointing at a parent
  that no longer draws its door; whether 120 becomes `‹ Share` belongs with
  `D-20-import-a-shared-plan`, but it cannot be left unnoticed by this redraw.

## Acceptance — how we know the drawing is complete enough to build from

1. Every control on 183 and 184 has a destination or a stored column named on the board.
   `Kati.Meals.MealPlan` and `Kati.Meals.MealPlanSlot` between them hold every value these
   two boards write; a field on the board with no column behind it is a defect in the
   drawing, not a migration to write.
2. **Five** target fields on 183, not four and not seven. Fibre is in, sugar and sodium are
   out — those are `Kati.Meals.Recipe`'s figures, not a plan's.
3. 49's redraw contains a `notifications` glyph, contains no `auto_mode`, and contains no
   `download` import card. `grep` on the exported board should confirm all three.
4. Three empty states are drawn or explicitly delegated: 183 blank, 183's picker with no
   meals, and 49 with no plans.
5. Both refusals are drawn with their sentence: the nameless save, and *another plan is
   already active*.
6. The Persian 183 exists, its day columns run right-to-left, its mono times still align in
   a column, and its vertical order is unchanged from the LTR board.
7. 44's board says what its `edit` disc opens, and 51's board says what pushed it.
8. The reminders decision is recorded on the board it landed on — so that
   `Kati.Screens.MealsToday.menu/1` can be deleted or kept on the strength of a drawing
   rather than on the strength of a comment apologising for itself.

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
