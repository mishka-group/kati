# The settings header controls that open nothing

> **Edits to existing boards — four header edits, and the one board behind them** · ticket `D-52`

Somebody opens **Settings**. The most prominent thing on the page is a 44pt white disc
floating beside the word *Settings*, and it carries a question mark. They tap it. Nothing
happens. They scroll down, tap into **Widgets**, and there is another disc at the top of
that page — `more_horiz` this time, in the same 44pt circle, in the same corner. Nothing
happens. Back out, into **Accessibility**: same disc, same corner, same nothing. They
switch the app to Persian, open **تنظیمات**, and the question mark is there again, moved
to the other end of a different row, still doing nothing. **Four taps on four screens in
the same family, two glyphs, and not one of them is a control** — and no sweep in this
repo can tell them so, because a control with no `on_tap` draws no tag, and
`Kati.ScreenTapSweepTest` taps tags.

## Why this is one brief and not four

This is `D-34`'s problem in the header row. `D-34` was eight built screens with no door;
this is four doors with no room — and, unlike `D-46`'s rows, these four are not even
mute. A row that leads nowhere at least admits it by having no chevron. These are drawn
*as buttons*, floating on `Kati.Theme.shadow_button/0`, at the top of the page, and they
are the one shape in Kati's whole vocabulary that means **press me**.

They must be decided together because they are one question asked four times — *what does
a settings screen's header control do?* — and the codebase has already shown what happens
when it is answered separately. `Kati.UI.Menu` exists because five other headers asked it:

> Five of the 62 drawings put a `more_horiz` or a `density_medium` in a header and none of
> them draws what it opens. Seven screens were stranded behind that gap … So the menu is
> new, and it is built out of the app's own parts rather than invented.

That menu was designed in code, with no artboard, and it worked — `Kati.AppReachabilityTest`
records the result in one line: *"This list was twelve. Seven came off it when the overflow
menu was designed."* But it left the panel itself undrawn, so the next four headers have
nothing to be drawn against, and four separate tickets would produce four separate answers.

**The defect is in the emitter, and that is why it is uniform.** Kati has two kinds of
disc helper. Most take a tag — `def disc(icon, tag)` on Home, Library, Books, Music,
Health, Activity, Habits, Calendar and Meal, and on the dark and Persian variants. Five
take an icon and nothing else: `Kati.UI.SettingsList.disc/1`, `Kati.Screens.Widgets.disc/1`,
`Kati.Screens.Accessibility.disc/2` (whose second argument is a contrast flag, not a tag),
`Kati.Screens.Agenda.disc/1` and `Kati.Screens.Account.disc/1`. `Kati.Screens.Fa.disc/2`
takes one and is called without.
A disc that cannot be handed a tag cannot be a control, and `Kati.Screens.Fa` says so in
its own doc without flinching:

> `tag` defaults to `nil`, and `Kati.Components.Event.handler/1` maps `nil` to no handler
> at all rather than to a registered `{pid, nil}` — so `disc/1` is the same disc with
> nothing wired, which is what screens 59, 60, 61 and 62 draw beside their back pills.

So every disc drawn through the settings family is decoration by construction: 24 and 62's
`help`, 39 and 41's `more_horiz`, and — the same node, from the same two helpers — 25 and
36's `more_horiz` and 49's `add`.

## The settlement, stated before anything is drawn

**A settings-family header disc is a door, and a door is drawn only where the board names
the room.** No board in 01–166 names a room behind any of these four, and nothing in the
app is waiting behind them: `Kati.AppReachabilityTest`'s *drawn, built, and waiting on an
entry point* section holds exactly two screens today — `NotificationAccess` (waiting on
150) and `NumberingScheme` (waiting on 35) — and neither belongs to Settings, Widgets or
Accessibility. There is nothing to put in these menus.

So the four discs come off, and **208 is the board that lets one come back**: the settings
header drawn in its two legal shapes, with the panel recipe pinned for the first time, so
that the day a settings screen earns a disc the designer is not inventing `Kati.UI.Menu`
a second time from a moduledoc.

**`help` in particular is not a door and never was.** Seven other boards draw the glyph —
116, 117, 118, 120, 142, 147 and 148 — and on every one of them it is an **inline note
marker**: the 17px glyph beside a sentence that explains the thing next to it (*~380 kcal ·
APPROX*, *You picked Goodreads and that file is not one*). 36 uses it a third way, as a
row tile on *Ask before ticking*. A 44pt floating disc that pushes a screen would give one
glyph a fourth meaning and the only one that is a navigation promise.

## What to draw

| # | Artboard or edit | What it carries |
|---|---|---|
| **208** | **NEW — reference: the settings header** | The header row in its two legal shapes; the disc at both of its appearances; `Kati.UI.Menu`'s panel, drawn for the first time; the dismiss; and the rule printed on the board with the six screens it applies to. |
| **24** | edit | The `help` disc comes off the title row. The title block goes full width. |
| **62** | edit | The same, mirrored — the `help` disc comes off the back-pill row, leaving the pill alone. |
| **39** | edit | The `more_horiz` disc comes off. The 44pt row that reserved it goes with it. |
| **41** | edit | The same, in both of 41's header appearances — lifted, and flat under **Increase contrast**. |

**The four edits are deletions, and they are the whole of the code change.** `24.html` holds
one `help` and `62.html` holds one; `39.html` and `41.html` hold one `more_horiz` each. Take
each out and `Kati.UI.SettingsList.title/4` falls to its no-disc clause and
`Kati.UI.SettingsList.chrome/2` falls to `chrome(nil, …)` — both clauses already exist and
are already what most of the family calls.

**25 and 36 draw the identical inert disc and are not on this ticket's edit list.** They are
the same one-line change (`release_watcher.ex:75` and `auto_detect.ex:80`, both
`SettingsList.chrome("more_horiz")`) and the rule strips them for the same reason. Either
they move in this pass or they are explicitly held for their own tickets — but they must not
be left as the two boards where the rule silently does not apply. Flag this back rather than
let it be found later. **49's `add` disc is the same emitter and is not covered**: it names a
different verb (create, on Plans) and belongs with whatever ticket owns the plan-creation path.

## Every element on 208, and the glyph it takes

Every symbol below is already in `Kati.Icons`' map, so this board costs no
`mix kati.gen.icons` run — which matters more than usual here, because
`test/design/material_symbols.codepoints` "is not in the repo and never was" and the
generator "wants it and has wanted it for some time". A new glyph on this board is a
blocked build, not a small chore.

| Element | Purpose | Glyph |
|---|---|---|
| **Shape one — the pill alone** | The legal header for a settings screen with no second destination. Back pill: radius 21, `#FBFAF8`, `shadow_button`, glyph 17px, label 13.5px/600. This is what 24, 39, 41 and 62 look like after the edits | `arrow_back_ios_new` |
| **Shape two — the pill and one disc** | The only other legal header. The disc is 44×44, radius 22, `Kati.Theme.card/1`, `shadow_button`, glyph 21px `#1A1917`. Drawn **with a leader line to a named destination** — that annotation is the rule made visible | `more_horiz` |
| **The pill height, decided once** | 24 draws the pill at **42** and 39, 41, 25, 36 and 62 draw it at **44**. `Kati.UI.SettingsList.chrome/2` takes the height as an argument precisely because the boards disagree. 208 picks one and the four edits follow it | — |
| **The 13pt drop, stated as a number** | `chrome/2`'s own doc records it: the pill floats at `padding_top: 54` and the content row starts at the frame's 64, "so the disc's centre lands about 13pt below the pill's", and the fix "belongs in `Kati.Screens.Pushed` — one number, once". 208 is where the intended baseline gets written down | — |
| **The disc, lifted** | Resting appearance, `shadow_button` | `more_horiz` |
| **The disc, flat** | 41's second appearance. `Kati.Screens.Accessibility.lift/2` returns `nil` rather than a zeroed shadow when **Increase contrast** is on, so the disc sits on the paper with no lift at all. A disc "is *defined* by floating"; the contrast state is the one place it does not, and no board has ever drawn it | `more_horiz` |
| **The panel** | `Kati.UI.Menu`'s, prop for prop: **250 wide**, radius 18, `Palette.card()`, `Theme.shadow_card()`, 6pt padding top and bottom. Anchored `side: :bottom`, `align: :end`, `side_offset: 8` — the panel's trailing edge meets the trigger's, because a centred panel would hang off the margin | — |
| **A menu row** | 46 high, 12pt inset both sides, glyph 18px in `ink_soft`, label 14px/600 in `on_surface`, no chevron. The Menu doc's own reason: "a menu item performs an action rather than promising a screen with more of the same on it" | `info` · `checklist` |
| **The rule between groups** | 1px `Palette.hairline()`, 5pt above and below, inset 12 | — |
| **A destructive row** | Same row, both glyph and label in `Palette.red()` and nothing else changed — "a red row that is also bigger or set apart reads as a different kind of control rather than the same control with a warning on it" | `delete` |
| **The dismiss** | A tap **outside** the panel closes it, and it is the only way out. Draw the target. This is not a nicety: measured on device, without `on_dismiss` "the menu opened and stayed open through every tap outside it" | `close` |
| **The closed state** | The trigger alone — no panel, no window. Draw it beside the open one so the pair is unambiguous | — |
| **The verdict table** | Printed on the board: 24, 62, 39, 41 — disc removed, nothing behind it. 25, 36 — same disc, same verdict, waiting on their own tickets. The drawing is the only place this claim can live | — |

## States to draw

`Kati.ScreenEmptyDatabaseTest` renders both settings boards against a database that is
empty for certain — `{"24", Kati.Screens.Settings}` and `{"62", Kati.Screens.SettingsFa}`
are on its list — and compares them with these drawings. **An empty state nobody drew is
an empty state nobody tests**, and that is exactly what a header edit risks: the row's
height and its title block change when the disc leaves.

**Resting.** 208's two header shapes, side by side, at the same scale. And the four edited
boards at rest with the disc gone: on 24 the title column now spans the full width, on 62
the pill sits alone in its row, and on 39 and 41 **nothing above the title moves at all** —
the 44pt row stays, because `Kati.Screens.Pushed` draws the back pill as an overlay and the
content has to reserve its height. `chrome(nil, 44)` is that clause and it already exists.
Say so on both boards, or the next reader closes the gap and pushes the title up by 60.

**Active.** The panel open under a disc, at the exact anchor offset. The pressed disc.
And 41's contrast-on header, because that screen's `Increase contrast` row is the one row
in the app whose subtitle names a visible effect — *"Hairlines darken, shadows drop"* —
and the disc keeping that promise is a state the board has never shown.

**Empty.** The header with its subtitle and the header without one. 24 sets `:meta_tight`
(mono 11 over a 5pt gap) and the default is `:meta` (mono 11.5 over 6), and
`Kati.ScreenTitleSubtitleTest` "pins each screen's choice against its own board, so a wrong
style is a failure rather than a thing someone notices in a screenshot a month later". A
title row redrawn without the disc must state which of the three it is, or the redraw
silently changes a pinned value.

**Error.** A header has no error state, and saying so is part of the brief. The failure
mode this board actually has to prevent is the undismissable panel above — draw the outside
tap, and draw the closed state, and there is nothing else here to get wrong.

## RTL — does this need a Persian mirror?

**Yes, on 208 itself, and it is the most valuable thing on the board — because the two
locales do not currently agree about where this control lives.** 24 puts the `help` disc in
the **title row**, opposite a 28px *Settings*, and `Kati.UI.SettingsList.title/4`'s doc
records it as the exception: *"Screen 24 is the one that hangs a disc off this row instead of
off the back pill's."* 62 puts the identical glyph in the **back-pill row**, opposite a 44pt
pill reading خانه. Same control, same app, two rows. Whatever 208 decides, both boards
follow it — that single agreement is what turns today's divergence into something a reader
can see.

**No new Persian artboard is reserved**, and none is needed: 208 carries the mirrored header
as a band rather than as a second board.

**What mirrors.** The container takes `dir="rtl"` and the whole row mirrors: the pill moves
to the right edge and its glyph becomes `arrow_forward_ios` — `Kati.Screens.SettingsFa`'s own
doc is emphatic that half a mirror is worse than none, since "a screen that flips one and not
the other sends the reader in both directions at once". A disc, where one is earned, moves to
the left end. `align: :end` still means *the panel's trailing edge meets the trigger's*, which
under RTL is its left edge. The mono subtitle takes Persian digits, still in DM Mono.

**What does not.** The vertical order never reverses — pill row, then title row, then the
first card, in Persian exactly as in English. `more_horiz` and `help` are symmetrical glyphs
and do not flip. The panel's own internal order — glyph, gap, label — mirrors as a row, but
the item **sequence** does not reverse.

## Dark colourway

**Not a second board, and the reason is that every surface here already has a dark answer
recorded.** Annotate 208 rather than redrawing it.

- The **disc** follows the ground, not the ink. `SettingsList.disc/1` says so where it picks
  its token: the card token, "not `on_ink`/`fab_glyph`/`on_media` — the other three meanings
  of `0xFFFBFAF8`. A disc is a surface that floats above the page, so it follows the ground:
  `#1E1D1B` in dark, like every card."
- The **panel** is a card, so board 28's rule applies unchanged: cards lift on a hairline,
  not a shadow.
- The **destructive row** needs no decision at all. `Palette`'s `:red` is `0xFFB4553C` in
  **both** columns — it is the same ink in either theme by construction.

None of the four edited boards has a dark sibling, so a dark 208 would be the only dark
header in the settings family and would have nothing to be compared against.

## Reuse, do not invent

- **The back pill** is `Kati.Screens.Pushed`'s, unchanged: radius 21, `#FBFAF8`,
  `shadow_button`, `arrow_back_ios_new` at 17px, the parent's name at 13.5px/600.
- **The disc** is `Kati.UI.SettingsList.disc/1`'s node, key for key — 44, radius 22, the card
  token, `shadow_button`, one 21px glyph as a child.
- **The flat disc** is `Kati.Screens.Accessibility.lift/2`'s, which is the same node with the
  shadow prop absent rather than zeroed.
- **The panel** is `Kati.UI.Menu`'s, prop for prop. Do not redesign it. It was built out of
  the app's own parts on purpose — the card every other floating surface is, and "a row is
  the settings row's rhythm without its chevron".
- **The rule between menu groups** is `Palette.hairline()`, the same 1px rule the settings
  card divides rows with.
- **The destructive tint** is `Palette.red()`. There is no `danger` token and one must not be
  invented "for a single row in a file whose whole point is that every colour is accounted
  for".
- **A chevron means *leads elsewhere*** — which is why a menu row does not have one, and why
  removing a disc from a header is a smaller claim than removing a chevron from a row.

## What it must NOT do

Every line here is a decision the codebase has already made.

**Do not draw a help article, an FAQ, or a support page.** The app has taken a position on
this in writing. `Kati.Screens.NotificationsHelp` is the only page in Kati that answers a
*why is this not working* question, and its moduledoc says what shape that answer has to be:

> An app that is deliberately quiet has to prove it is quiet on purpose … That is the whole
> reason this screen exists rather than a FAQ entry.

A help surface in Kati is a **diagnostic** — *what Kati decided* beside *what the phone
decided*, every row a state with a plain sentence and, where there is one, a way to fix it.
That page is #26's, it is already undrawn and already on the gallery's undrawn list, and it
is reached from rows. It is not this ticket's, and it is not what a disc opens.

**Do not give `help` a second meaning.** On 116, 117, 118, 120, 142, 147 and 148 it marks an
inline note; on 36 it is a row tile. Seven boards to one is not a tie.

**Do not fill a menu to justify keeping a disc.** A menu whose items are already rows on the
page below it is a second front door to rows that are one scroll away — and 24's About group
is already where the questions a help page would answer are asked: *Version*, *Privacy ·
Nothing leaves the device*, and *Where this comes from · Sources and licences*. The last of
those routes, to board 83's attribution page. The first two draw chevrons and open nothing —
which is a real gap, and it is **the About rows' gap, not the header's**. Fixing it by
hanging a menu off the disc would answer a question about three rows from inside a ticket
about a disc.

**Do not wire a tag and leave the destination for later.** Both screens end their dispatch
with a catch-all — `_ -> {:noreply, socket}` in `Kati.Screens.Widgets.handle_tap/2` and in
`Kati.Screens.Accessibility.handle_tap/2` — and `Kati.ScreenTapSweepTest` says exactly what
that costs: "A catch-all is a real hole in the coverage." A tag added without a handler would
be as invisible as the disc is now, and it would look wired.

**Do not answer board 40's `more_horiz` here.** That is the opposite defect and its own gap:
`grep -c more_horiz test/design/screens/40.html` is **0** and `grep -c arrow_back_ios_new`
is **0**, yet `Kati.Screens.Account` draws both. That is a control invented in code with no
board asking for it, which is a question about what board 40 should carry — not about what a
drawn control opens.

**Do not add the Notifications row to 24 while you are in its header.** It is a real gap and
it is a different one: it is about the Data or Sources group, it decides where the
notifications inbox and #26's diagnostic are reached from, and annexing it here would settle
two board-wide questions from inside a brief about a header row.

**Do not put a route argument on anything this board opens.** Only 7 of 62 screens read one
and most detail screens open generically — that is a **code** defect with its own fix, not a
gap in a drawing. The board's job is to draw the door.

**Do not change 41's six switch rows to make room.** They are not preferences:

> The **six switches** are guarantees, not preferences. *Touch targets · Nothing under 44×44*
> and *Colour is never alone* are properties of every other screen in the app; there is
> nothing for a stored boolean to change.

That is also the reason 41 has no menu to draw: a page that is *the spec drawn rather than
described* has no second destination to hide behind a disc.

## Left open — decide and note which way you went

- **Whether the owner wants a help surface at all.** This brief settles that no drawn one
  exists and that `help` is not the glyph for it; it cannot settle whether one should be
  commissioned. If the answer is yes, it is #26's diagnostic drawn first and reached from a
  **row** — and it is a new board, a route, an empty state and a Persian mirror, none of
  which 208 is.
- **Which row a disc lives in when a screen earns one** — 24's title row or 62's pill row.
  Both are drawn today and they disagree. 208 has to pick, and 24 or 62 will move.
- **Whether the back pill is 42 or 44.** 24 draws 42; the rest of the family draws 44.
  `chrome/2` takes the height as an argument only because of this.
- **Whether the 13pt drop is fixed by moving the pill or by moving the content row.**
  `chrome/2`'s doc says the fix belongs in `Kati.Screens.Pushed` — "one number, once" — but
  it does not say which number, and 208 is the drawing that would.
- **Whether 25 and 36 are edited in this pass** or held. They are not on this ticket's list
  and the rule covers them either way.
- **Whether the dismiss is drawn as a scrim or as nothing.** `Anchored` gives the panel its
  own window and the tap outside is already handled; whether the page behind it dims is a
  drawing decision nothing in the code forces.
- **Whether a menu row caps at 46pt under Dynamic Type or grows.** `@row_height` is a
  constant today. The house rule says chrome whose size carries structure caps — but a menu
  row is content in a chrome-shaped container, and this is the first one Kati has had.

## Acceptance — how we know the drawing is complete enough to build from

1. `grep -c help test/design/screens/24.html test/design/screens/62.html` returns **0** for
   both, and `grep -c more_horiz test/design/screens/39.html test/design/screens/41.html`
   returns **0** for both. The four edits are checkable by grep or they did not happen.
2. 24's title row is redrawn full width and names its subtitle style, and 62's pill row is
   redrawn with the pill alone. Both are on `Kati.ScreenEmptyDatabaseTest`'s list, so the
   redrawn row is what a fresh install is compared against.
3. 39's and 41's boards keep the empty 44pt row above the title and say in words that it is
   reserved for the floating back pill, not left over from the deleted disc. A drawing that
   closes that gap moves every band on two screens by 60pt.
4. 208 states **one** pill height and **one** row for the disc, and 24 and 62 agree with it.
   Today they agree about neither.
5. 208 draws the panel with every one of `Kati.UI.Menu`'s numbers on it — 250, 18, 6, 46, 12,
   18px, 14px/600, `side_offset: 8`, `align: :end` — so the next menu is drawn from a board
   rather than from a moduledoc.
6. 208 draws the panel **closed** as well as open, and draws the outside tap that dismisses
   it. A menu with no drawn way out is the one failure this component has already had on a
   real device.
7. 208 draws the disc lifted **and** flat, and says which of 41's two states each belongs to.
8. Every glyph on 208 is already in `Kati.Icons`' map. A new symbol is a blocked build.
9. 208 says, in words, that a settings-family header disc is drawn only where the board names
   its destination, and lists the six screens the rule applies to. That claim has nowhere else
   to live: there is no test that can fail for a control nobody wired, which is how four of
   them survived this long.

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
