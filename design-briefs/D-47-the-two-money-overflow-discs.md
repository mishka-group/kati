# What the two money ⋯ discs open

> **Overflow menu — one new artboard carrying both menus, and two boards annotated** · ticket `D-47`

Somebody is looking at **£46.47 a month** on screen 122 and wants to do the obvious thing
with it: put in the book they bought this morning, or go and fix a price that is wrong.
There is exactly one control in that header that could take them anywhere — a 44pt
`more_horiz` disc — and on 122 it is not a control at all. `Kati.Screens.Money` builds it
with `SettingsList.chrome("more_horiz", 44)` (`money.ex:105`), and
`Kati.UI.SettingsList.disc/1` passes no `on_tap` (`settings_list.ex:135-149`) even though
`Kati.Components.MishkaThemeIcon` has accepted one since it gained a shadow
(`mishka_theme_icon.ex:218`). It does not press, it does not open, and because every sweep
in this repo finds a control by its **tag**, no test in the app can report it: an untagged
disc is not a control any of them can see. Screen 23's disc is one step better and no more
useful — it carries `:open_menu` (`subscriptions.ex:189`), so it presses, falls through the
catch-all, and has a line of its own on the tap sweep's Backlog
(`screen_tap_sweep_test.exs:716`). Both are stuck on the same thing, and it is a drawing:
neither `122.html` nor `23.html` contains a menu, a sheet or a popover anywhere in the
export, so there is nothing behind either disc that would not be invented. Meanwhile the
only way to record an expense is Schedule → ⋯ → **Quick add** → the **Expense** chip
(`calendar.ex:303` → `quick_add.ex:133-134`): four taps, in another root, on a page that is
not about money.

## Why this is one brief and not two

Because the two menus can only be decided against each other. Screen 122 **is** screen 23
widened — `Kati.Screens.Money`'s first line says so — and the two boards draw the same
`£46.47` cream hero, the same four service rows and the same *Worth a look* card. What 122
has that 23 does not is the expense half. So every candidate row has to be placed by asking
the same question twice: *is this about the ledger, or about the services?* Answer it on one
board alone and the other inherits a menu by accident.

The area has **four** dead discs, not two, which is how little the code can do about this on
its own:

| Board | What the code does with its disc | State |
|---|---|---|
| **122** — Money | `chrome("more_horiz", 44)`, no tag | drawn, dead, invisible to every sweep |
| **23** — Subscriptions | `:open_menu` → the catch-all | drawn, inert, on the Backlog |
| **92, 93** — My services | `chrome(nil, 44)` (`my_services.ex:160`, `my_services_empty.ex:119`) | **drawn on the board and not built at all** |
| **127** — پول | `Fa.disc("more_horiz")` with no tag, deliberately | drawn, dead, and argued for in the moduledoc |

This brief settles 122 and 23. The other two follow from the same recipe and are named here
so the designer knows the drawing is being asked for four discs' worth of answer, not two.

## The recipe exists in code, and no board has ever approved it

**No board in 01–166 draws an overflow menu.** Twenty-eight of them draw a `more_horiz`
(twenty-nine discs — 02 draws two). The code got tired of waiting and built one:
`Kati.UI.Menu` is a real component, shipping on five screens — **02** Schedule
(`calendar.ex:298-306`), **03** Library (`library.ex:579-586`), **04** Series detail
(`series.ex:695-714`), **08** Film detail (`film.ex:574-577`) and **43** Meals today
(`meals_today.ex:433-436`) — and its own moduledoc admits what it is:

> Five of the 62 drawings put a `more_horiz` or a `density_medium` in a header and none of
> them draws what it opens. Seven screens were stranded behind that gap … So the menu is
> **new**, and it is built out of the app's own parts rather than invented.

That count was five of 62; it is now five of 166, and the ink has never been ratified by a
drawing. **196 is the board that ratifies or overrules it**, and whichever way it goes, the
five screens already shipping it follow this board afterwards.

The two candidates, with the numbers each already has:

- **The anchored panel** — `Kati.UI.Menu`: 250 wide, radius 18, `Palette.card()` under
  `Theme.shadow_card()`, 6pt of padding top and bottom, rows 46 high with 12 of padding, an
  18px glyph in `ink_soft` then a 14px/600 label, a hairline rule between groups, and
  `destructive: true` colouring both in `Palette.red()`. It hangs from the trigger with
  `side: :bottom, align: :end, side_offset: 8`, in its own window
  (`Kati.Components.Anchored`, `K-18` in `native/LEDGER.md`), which is the only way a panel
  survives a `Scroll` and a rounded `Box` on this platform.
- **The bottom sheet** — `Kati.UI.Sheet`, and this one **is** drawn: twelve boards carry it,
  nine of them to the pixel (70, 72, 73, 94, 106, 111, 114, 119, 124) — a
  `rgba(26,25,23,.42)` scrim, paper, `border-radius: 26px 26px 0 0`, `18px 21px 34px` of
  padding, and a header of *36pt `close` disc · centred 15px/700 title · a 36pt hole*. The
  three from the later wave (144, 145, 149) keep everything but round to 22, which is drift
  worth knowing about before a tenth sheet is drawn.

**The recommendation is the panel**, for one reason: a sheet in this app is a *task* — Log a
listen, New goal, Your country, Quick add — with a title and a close button, and it is what
124 already is. A menu is a short list of doors. If money's ⋯ rises as a sheet while
Schedule's ⋯ drops a panel, the same glyph means two different things depending on which
root you are standing in. Overrule that if you like, but overrule it for all five screens,
not for these two.

## What to draw

| # | Artboard or edit | What it carries |
|---|---|---|
| **196** | **NEW — The overflow menu**, five bands in 27's manner | Band 1 *In place*: 122's header row with the panel hanging under the disc, so the 8pt offset and the right-edge alignment are drawn rather than described. Band 2 *122 — the ledger's menu*, four rows and a rule. Band 3 *23 — the services menu*, two rows. Band 4 *An empty ledger*, the same four rows over 123's *Nothing set up — not £0.00* header. Band 5 *فارسی*, the panel alone, mirrored, for 127. |
| **122** | **annotation, no new ink** | The disc is already drawn. Say on the board that it carries `:toggle_menu`, that a tap outside it dismisses, and which four rows it opens. |
| **23** | **annotation, or a deletion** | Same, for two rows — **or** the board says the disc is removed. A two-row menu is defensible; a one-row menu is not, and this is the fork that decides it (see *Left open*). |

Nothing on 122 or 23 moves. Both discs are drawn where they are, at 44pt, sharing the back
pill's row, and this brief adds no ink to either page.

## Every element on 196

**The panel itself** — band 1 is where these are measured, and every other band reuses them.

| Element | Purpose | Glyph |
|---|---|---|
| Panel | 250 wide, radius 18, `#FBFAF8`, card shadow, 6pt padding top and bottom. It hugs its rows; nothing declares a height | — |
| Row | 46 high, 12 of padding each side, 18px glyph in `#5C574F`, 12pt gap, 14px/600 label in ink, one line | — |
| **No chevron on any row** | `Kati.UI.Menu`'s own rule: *a menu item performs an action rather than promising a screen with more of the same on it*. In this app a chevron means *leads elsewhere* — and three of these rows do lead elsewhere, which is exactly why the rule has to be stated on the board rather than left to instinct | — |
| Rule | A hairline `rgba(26,25,23,.07)` inset 12, with 5pt above and below. It separates *what this page can do* from *where its figures are owned* | — |
| Position | Under the disc, right edges flush, 8pt below it | — |
| The disc while open | Draw whether it changes. The build changes nothing today | `more_horiz` |
| Dismissal | A tap anywhere outside the panel closes it. Draw nothing for this — but say it on the board, because without it the only way out is to pick something | — |

**Band 2 — 122's menu.** Four rows, one rule. Every glyph below is already in `Kati.Icons`
and already means this thing somewhere else in the app, so the shipped font subset needs
nothing new.

| Row | Opens | Why it is on the ledger's menu | Glyph |
|---|---|---|---|
| **Add an expense** | **124**, the Quick add — expense sheet, with the Expense chip already selected | The only row that writes. Today this costs four taps in another root; 122 is titled *Money*, counts `7 EXPENSES THIS MONTH` in its own subtitle, and cannot add one. `bolt` because that is the glyph 124's own header draws and the row 02's menu uses for the same machinery | `bolt` |
| **Money on the calendar** | **126** | The day view of the same ledger — renewals and expenses on one date. It exists, it is finished, and its only door today is Schedule's ⋯ (`calendar.ex:306`) | `calendar_month` |
| — rule — | | | |
| **My services** | **92** | 122's own `info` line already says *"Prices are owned by 92"* and gives the reader nowhere to tap. This is the row that turns a sentence into a door. `subscriptions` is the app's glyph for this destination on Settings and on Home | `subscriptions` |
| **Currency** | **125** | Every figure on the page is a `£`. 125 is built, and its glyph on screen 54's own row is `payments` | `payments` |

**A glyph collision to resolve rather than fudge:** `payments` is currently doing three
jobs — 54's Currency row, 124's Expense chip, and 02's *Money on the calendar* row. Two of
those want to be in this one menu. The table above gives Currency the `payments` it already
has on 54 and moves the calendar row to `calendar_month`; if you prefer it the other way,
say so on the board, but two `payments` rows in one 250pt panel is not a choice.

**Band 3 — 23's menu.** The second group only.

| Row | Opens | Glyph |
|---|---|---|
| **My services** | **92** | `subscriptions` |
| **Currency** | **125** | `payments` |

**Band 4 — the empty ledger.** The same four rows as band 2, unchanged, over 123's
*Nothing set up — not £0.00* state. Drawn because it is the state that needs the menu most:
on a fresh install *Add an expense* and *My services* are the only two ways out of the empty
page, and a menu that shrinks when the page is empty removes the exit at the moment it is
needed.

**Band 5 — فارسی.** The panel alone, mirrored. See *RTL* below.

## The adjudication — why each row is on one menu and not the other

This is the table the ticket asks for, and it is worth putting on the board itself, because
the next person to add a row to either menu needs the rule and not just the result.

| Row | 122 | 23 | Why |
|---|---|---|---|
| Add an expense | **yes** | no | 23 draws no expense anywhere. Its caption is about services: *"cost per watched hour is the one subscription number no finance app can compute for you."* |
| Money on the calendar | **yes** | no | 126 is the ledger's day — half its cards are expenses. Same reason. |
| My services | **yes** | **yes** | Both pages print the same `£46.47` and neither can change a price. 122 already names 92 in prose; 23's own moduledoc spends four paragraphs on the missing figure. |
| Currency | **yes** | **yes** | Both pages are entirely money. If this is cut, cut it from both. |
| New subscription | **no** | **no** | The only writer in the app is 92's *Something else* (`my_services.ex:693-695`), and it writes a name with no price. See below. |
| Pause · Cancel | **no** | **no** | Per-service verbs. A page-wide menu cannot name which service it means. |
| Set a budget · Categories · Export | **no** | **no** | Forbidden by 122's caption. See *What it must NOT do*. |

**New subscription, settled.** It is not a row on either menu. `Kati.Screens.MyServices`
already has the door — the *Something else* row — and `Kati.Screens.Subscriptions` explains
in its own words why a second one here would be worse than none:

> `Something else` writes a name and no price … A service created today is a row with
> `monthly_pence: nil`, which screen 92 renders honestly as a name with a blank right-hand
> column and this screen could only render as `£0.00` or as a hole. Neither is one of the
> four rows the drawing has.
>
> And there is no control on **this** screen to fix that with … so a *New subscription*
> sheet here would be a screen invented rather than built.

So both menus route to 92, and creating a service stays where the price editor is going to
land. The service catalogue keeps *Show all 47*; it does not gain a second creator either.

**Pause and cancel, settled.** They belong on the page for one service, which is the sibling
gap in this batch (`service-detail`). Two facts make that more than a preference. First,
`Kati.Services.Service.paused` is a real boolean column with a default of `false` and
**nothing anywhere in `lib/` writes it** — the first row that pauses anything will be the
column's first writer, and it needs a service to name. Second, board **123** already draws
the state cancellation produces — `history` · *"Dispatch — cancelled 2 Jun · Out of the
active list and out of the monthly figure. Its 31 hours still count toward 07, because you
did watch them"* — and there is no `cancelled` value and no cancellation date anywhere in
the schema. `tier` has `:not_mine`, which is the honest home for *out of the active list
without deleting the past*; the **2 Jun** in that drawn sentence has no column at all. Do
not let a page-wide menu be where that gets decided.

## States to draw

Kati's sweeps compare an empty state against a board, so an undrawn empty state becomes an
untested one — `Kati.ScreenEmptyDatabaseTest` is explicit that a screen either falls back to
its own drawing, has an empty board, or is listed as having none.

- **Resting.** The disc closed, exactly as 122 and 23 draw it now. Nothing changes; say so,
  so nobody adds a dot or a tint to advertise the menu.
- **Active — the menu open.** Bands 1–3. This is the state the whole brief exists for, and
  it needs one thing beyond the panel: what happens to the page underneath. The panel draws
  in its own window with **no scrim**, and `Kati.Components.Anchored` has no scrim prop, so a
  dimmed page here is native work rather than a fill. Draw it one way and mean it.
- **Empty.** Band 4, and it is load-bearing twice over: 122 has no empty branch in code at
  all today, and the menu is how somebody leaves the empty page. The four rows do not change.
- **Error.** A menu cannot fail; the row behind it can. The only real one is *Add an
  expense* → 124's refusal, which `Kati.Screens.QuickAddExpense` already owns —
  *"A save that did not land does not close the sheet"* — so the menu is closed by then and
  the sentence belongs to 124, not here. Say that on the board so nobody draws an error row
  in a panel.
- **The scroll question, which is a state whether or not it is drawn.** 122's header is
  *inside* the `Scroll` (`money.ex:97-105`), so the disc scrolls away with the page. An open
  panel anchored to a trigger that is leaving the screen has to either close or follow. Pick
  one on the board; the build has no opinion and will inherit whatever ships first.

## RTL — does this need a Persian mirror?

**Yes, once, and it is band 5.** Screen **127** is the Persian Money page, it draws the same
44pt `more_horiz` beside its `آمار` pill, and `Kati.Screens.MoneyFa` argues its deadness on
purpose:

> The disc is `Kati.Screens.Fa.disc/2` with **no tag**, which is what screens 59 through 62
> draw beside their pills: **127 gives it no menu, and a disc that lights up and opens
> nothing is a worse promise than one that does nothing.**

That sentence is the whole reason the Persian panel has to be drawn in this brief and not
deferred: the moment 122's disc opens something, 127's disc is a broken promise rather than
a considered silence.

What mirrors: the panel hangs from the **left** edge of the frame, under a disc that has
moved to the left; each row's glyph leads on the right and the label follows. The build
already does the positioning half — `K-18 anchored-node` in `native/LEDGER.md` records
that the popup's placement is *"mirrored once up front (Kati runs RTL for real)"* — so what
the drawing is deciding is the row's internals and the Persian labels, not the geometry.

What does **not** mirror: the `more_horiz` glyph (symmetric, and artwork never mirrors
anyway), and the **vertical order never reverses** — *Add an expense* stays at the top,
Currency stays at the bottom, the rule stays between them.

There is **no Persian twin of 23** in the app — the Persian money screens are 127 (پول) and
97 (سرویس‌های من) — so 23's two-row menu needs no Persian board. If 97's disc is wired in
the same pass, its menu is 92's, and 92's menu is not this ticket.

## Dark colourway

**Not a full dark board, but one swatch is needed.** Every ingredient is already answered:
the panel is `Palette.card()` — `#1E1D1B` on a `#121110` ground — under
`Theme.shadow_card()`, and rows are ink and `ink_soft`. The one thing dark does not answer
is **separation**. In light, the panel floats because a shadow reads against paper; on a
dark ground a card-coloured panel eight points below a card-coloured disc separates by
almost nothing, and unlike a sheet there is no scrim behind it to help. So draw the panel
once in dark and say whether it gains a hairline border, a heavier shadow, or neither. If
you choose a scrim instead, dark is already settled — `Kati.UI.Sheet.scrim/0` is the same
42% ink in both modes, and screen 68's dark sheet family keeps it deliberately.

## Reuse, do not invent

- **The panel** is `Kati.UI.Menu`, to the number: 250 × radius 18, `#FBFAF8`, card shadow,
  46pt rows, 12pt side padding, 18px glyph, 14px/600 label, hairline rule inset 12. Draw
  those values or draw different ones on purpose — do not draw a third set by eye.
- **The disc** is `Kati.UI.SettingsList.disc/1`: 44 × radius 22, `#FBFAF8`, button shadow,
  21px glyph. It is already on both boards and does not change.
- **The four destinations are all built screens**: 92 (My services), 124 (Quick add —
  expense), 125 (Currency), 126 (Money on the calendar). Nothing new is being asked for
  behind any row.
- **The two rows that already exist in another menu** are 02's: `bolt` *Quick add* and
  `payments` *Money on the calendar* (`calendar.ex:303-306`). Keep the labels close enough
  that a reader recognises them.
- **The bands** are 27's and 123's: the 13×2 accent rule, DM Mono 10.5 uppercase eyebrow,
  one state per band, a caption under the frame.
- **If anything destructive ever lands in a menu**, the confirmation is not invented either
  — 27 draws the undo bar (`#1A1917`, radius 20, `undo` glyph, accent *Undo*) and that is
  the app's answer to every destructive action.
- **The sheet**, if the fork goes that way, is `Kati.UI.Sheet` unchanged: scrim `.42`, paper,
  `26px 26px 0 0`, `18px 21px 34px`, close disc · centred title · 36pt hole.

## What it must NOT do

Every line here is a decision the codebase has already made.

**Do not put a budget, a category or a chart in either menu.** `Kati.Screens.Money`:

> Screen 23 widened to hold quick-add's expenses **without becoming a budgeting app**. The
> caption is explicit about what that means: no categories, no budget, no chart. Each expense
> names the section it belongs to, and that is the only classification there is.

`Kati.Money.Expense` says the same from the schema side — *"No categories, and that is the
design"* — so *Filter by category*, *Set a monthly budget* and *Export as CSV* are all out.
Note what the caption does **not** forbid: a way in. A door to 124 is not a budgeting
feature, and this is the answer to the open question the ticket raises.

**Do not draw a Cancel row that implies Kati cancels anything.** `Kati.Screens.Money`:

> The suggestion is the only advice this app gives … it offers to *remind* rather than to
> act. **Nothing here cancels anything.**

Kati has no account with Orbit. The most a control here could ever do is record that *you*
cancelled.

**Do not draw a New subscription sheet on 23.** Quoted in full above, from
`Kati.Screens.Subscriptions` — a service with no price is a row this screen cannot render.

**Do not give 127 a disc without a menu, and do not wire 122 without 127.**
`Kati.Screens.MoneyFa`, quoted above: *a disc that lights up and opens nothing is a worse
promise than one that does nothing.*

**Do not promise conversion on the Currency row.** `Kati.Screens.Currency`:

> **Changes:** the symbol and the number formatting, everywhere. **Does not change:** any
> amount you have already recorded. There is no code path in `Kati.Money` that rewrites a
> stored figure, which is what makes the second half true rather than aspirational.

A menu row labelled *Convert to €* would be the app's first lie about money.

**Do not put a chevron on a menu row.** `Kati.UI.Menu` again: a row here *performs an action
rather than promising a screen with more of the same on it*, and in this app a chevron means
*leads elsewhere*.

**Do not draw a per-service action in a page-wide menu.** `Kati.Screens.MyServices` already
holds the shape of that mistake — every service row is addressable and every one of them
does nothing, because *"there is no edit sheet to push"* (`my_services.ex:573-580`). Adding
*Pause* to a menu that cannot name a service would make the same promise from further away.

**Do not treat the disc as the place to fix a price.** `Kati.Screens.Subscriptions` is
unambiguous that the missing figure is a domain problem and not a control problem: a service
needs *"a price and a cadence, a link from a tracked title to the service that carries it,
and a duration on a watch"*, and only the first has landed.

## Left open — decide and note which way you went

- **Panel or sheet**, first, and for all five existing menus rather than for money alone. If
  it is a sheet, `Kati.UI.Menu` is deleted and 02/03/04/08/43 are redrawn behind it; that is
  a bigger bill than this ticket, and the board is where it gets priced.
- **Whether the page dims behind an open panel.** No scrim today, and none available without
  native work. A drawn answer either way is fine; an undrawn one means it ships as whatever
  the Kotlin happens to do.
- **Whether 23 keeps a disc at all.** Two rows is a thin menu. The three honest outcomes are:
  the two-row menu as drawn; the disc opening 92 directly with no panel (and then the ⋯ glyph
  is wrong and should become `subscriptions`); or the disc deleted from 23 in the redraw and
  the ledger keeping the only menu in the area.
- **Whether *Currency* belongs on a content page at all**, or stays a Settings row under
  Language. If it lands here, note that 125's back pill reads `‹ Language` and will be lying
  to everybody who arrives from money — the same problem 126 has, whose pill reads
  `‹ Calendar`. Either the pills become dynamic or the board names the parent it keeps.
- **`bolt` or `add` for the expense row.** `bolt` ties it to Quick add's machinery, which is
  literally what it opens; `add` says plainly what it does.
- **Whether the panel closes when 122's header scrolls away.**
- **Whether the disc shows that a menu is open.**
- **Whether 92, 93 and 97 adopt this in the same pass.** Their discs are drawn on the boards
  and not built at all, which is the one variety of this bug that leaves the drawing and the
  build disagreeing in silence.
- **Where a cancelled service is listed once cancelling exists.** 123 draws the state and no
  board draws the list. That is the service-detail ticket's to answer, but this brief is the
  last place it can be noticed before the menus are frozen.

## Acceptance — how we know the drawing is complete enough to build from

1. Every row on both menus names a destination that already exists — 92, 124, 125, 126 — or
   is marked NEW on the board. There are no NEW ones in the recommendation above, and a row
   that acquires one is a defect in the drawing rather than a screen to go and build.
2. The two menus differ **only** in the two rows the adjudication table justifies, and that
   table is on the board.
3. No row on either menu is a per-service verb. `grep -i "pause\|cancel"` over the exported
   196 returns nothing outside the prose that explains why.
4. One panel recipe, drawn once and reused in every band, with its width, radius, row height
   and paddings labelled. If it disagrees with `Kati.UI.Menu`'s numbers, the board wins and
   the disagreement is deliberate.
5. Four states are drawn: closed, open, open-on-an-empty-ledger, and the Persian panel.
6. Every glyph is one of `bolt`, `calendar_month`, `subscriptions`, `payments`, `more_horiz`
   — all five already in `Kati.Icons`, so `mix kati.gen.icons` needs no new codepoint. Any
   sixth glyph is listed explicitly as new.
7. Boards 122 and 23 say which tag their disc carries, so `Kati.Screens.Money` can wire
   `:toggle_menu` / `:close_menu` and `{Kati.Screens.Subscriptions, :open_menu}` can be
   struck off the Backlog in `test/kati/screen_tap_sweep_test.exs` — which is what that
   list's own header asks each new wiring to do.
8. The board says what the page underneath does while the menu is open, and what an open menu
   does when the header scrolls. Both are behaviours the build will otherwise decide by
   accident.

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
