# Lists that open, and a way to put something in one

> **Two new boards and five edits** · ticket `D-40`

Screen 12 is a finished, built, tested screen whose every row is a door with no room
behind it. Seven rows — `Best of 2026`, `Rainy Sunday`, `Recommended by Jo`, then
`Wishlist`, `Rewatches`, `Abandoned`, `Owned on disc` — and five of them draw a
`chevron_right`, which in this app is a promise: *leads elsewhere*. Nowhere is drawn, so
`Kati.Screens.Lists` renders all seven with `on_tap={nil}` and says so in its own
moduledoc. The other end is the same hole from the far side: `Add to list` is drawn as a
control on **66**, **68**, **74**, **146** and **147**, and there is no picker anywhere
in the 166 boards, so every one of those five controls pushes screen 12 — a person taps
*Add to list* on **Tidal Works**, lands on a page of three film lists, and the album is
not in any of them and never will be. Two boards close both ends: the list detail the
chevrons point at, and the sheet the `bookmarks` glyph promises.

**This brief is not about music,** which is why it is filed alone rather than folded into
the music work. It arrived through board 74's `Add to list`, and it fails identically on
66 and 68 with a book. Write it once, share it with the film and books areas, and do not
file it three times.

**A note for whoever picks it up.** The blocker underneath is a missing *resource*, not
missing wiring. `lib/kati/screens/lists.ex:38-53` is explicit: *"Not a missing column this
time — a missing **resource**… A list-to-title join is the table that does not exist."*
`Kati.Media` holds `CachedTitle`, `TrackedTitle` and `Watch` and nothing else, and a list
that must hold a film, a `Kati.Books.Book` and a `Kati.Music.Album` needs a member row
that can point at all three. So this drawing unblocks a **schema** ticket, not a wiring
one, and the drawing has to come first because the schema question — what a member *is* —
is the one the board answers.

## What to draw

| Board | What it is | What it carries |
|---|---|---|
| **181** — *List detail* | **new artboard**, pushed under Lists | Four bands on one artboard, the way 146 carries four: (a) a **made list, mixed** — `Rainy Sunday`, holding a film, a book and an album, so the row shape is settled once rather than three times; (b) the same list **empty**, `0 titles`, which is what screen 12's `add` disc produces on its very first tap; (c) a **ranked** list, with the position column and the reorder handle a `ranked` badge implies; (d) a **kept** list — `Abandoned` — which has no add, no reorder and no rename, and names the rule that fills it |
| **182** — *Add to list* | **new artboard**, a modal sheet | Four bands: (a) resting, opened from one album, nothing ticked; (b) two lists ticked; (c) the **new-list row opened** into its naming field — the step screen 12 never had; (d) the **many-titles** case 146's pill opens, `4 titles`, with a list that holds two of the four |
| **12** — Lists | edit | The rows stop being dead. Decide what a **badged row** does, because today the badge sits in the chevron's slot and a badged list still leads somewhere. Decide whether the `add` disc keeps making an unnamed `New list` or routes through 182's naming step |
| **66 / 68** — Book detail, light and dark | edit | The `bookmarks · Add to list` tile now names 182 in the caption, and gets its **second state** — the label a book already on a list shows. 68 is the dark twin and is why the dark colourway below is not optional |
| **74** — Album detail | edit | Same tile, same second state, and the mixed row on 181 takes its **album** case from this board's own no-art square |
| **146** — Shelf, selection mode | edit | `Add to list` opens 182 with the selection, not screen 12. The sheet's header says how many, and a list holding *some* of the selection needs a third tick state |

**147 needs no edit of its own.** It is 146's bar at 235%, it draws the same
`bookmarks · Add to list`, and it inherits whatever 146 decides. What it must not do is
acquire a *second* destination at large type.

## Every element, and its glyph

Every symbol named below is **already in `Kati.Icons`'s inlined map**. That matters more
here than usual: a symbol that is not in the map needs `mix kati.gen.icons`, and that task
wants `test/design/material_symbols.codepoints`, which `docs/DESIGN-ASSETS.md` records as
*not in the repo and never was*. So a new glyph is a blocked dependency, not a free
choice. `playlist_add` is the obvious one to reach for and **is not in the map**;
`bookmarks` is, and is already the glyph drawn on 66, 68, 74 and 147.

**181 — List detail, top to bottom**

1. **Back pill** — `arrow_back_ios_new` + `Lists`. `Kati.Screens.Lists` is
   `use Kati.Screens.Pushed, back: "Library"`, so this sits one further in and the pill
   names *Lists*, not Library.
2. **List name** — 28px title, the header recipe screen 12 uses for `Lists`.
3. **Mono subtitle** — `9 titles · added 3 Mar` or, for a kept list, the rule that fills
   it. Screen 12's header subtitle is DM Mono 11px `#A9A29A`; keep it.
4. **The badge**, repeated from 12 — `ranked` or `shared`, the cream pill at height 22 /
   radius 11 / 10px semibold `#96723C`. It is a fact, not a control:
   `Kati.Components.MishkaPill` with no selected state.
5. **The rows — the point of the board.** One recipe, three kinds. Leading artwork, then
   title 13.5/600, then a second line naming the kind in words: `Film · 2024`,
   `Book · Ines Karvel`, `Album · Kell Ostrand`. Board 19's result rows already name a
   kind this way (`Series · S2 · watching`), so this is that row, not a new one. Trailing
   `chevron_right`, because the row does push a detail screen. Section glyphs exist if
   you want them instead of words — `movie`, `live_tv`, `menu_book`, `graphic_eq` are the
   four the app uses everywhere, from the shelf trough to `Kati.Settings.Sample` — but
   pick one or the other, not both.
6. **The artwork slot, drawn all three ways.** A film poster is 2:3, a book cover is
   near-2:3, an album cover is square — and an album usually has *no* cover at all. Draw
   the row so the title's baseline does not move between the three. Screen 12's fanned
   tiles are 38×54 at radius 7 with a 2pt `#FBFAF8` ring; the album's square wants the
   same ring and the same slot.
7. **The no-art album** — a paper square carrying the album initial and the label `Art`.
   This is board 74's own default, not a fallback, and it will appear in most real lists.
8. **Ranked only:** a DM Mono position number in the leading column, and `drag_indicator`
   as the reorder handle — screen 24's *Reorder sections* row is the recipe, 30×30 paper
   tile, 17px glyph in `#5C574F`.
9. **The empty band's line.** A list is filled from a *title*, never from the list, so the
   empty state must say where titles come from rather than offering an add control that
   cannot exist: *open a film, book or album and tap Add to list*. Set in the bordered
   `info` note shape — `info` glyph, `1.5px dashed rgba(26,25,23,.16)`, the border
   `Kati.Screens.AddTitle`'s `by_hand/0` and `Kati.Screens.EpisodeRatings.rating_note/0`
   both carry.
10. **The kept band.** No add, no handle, no rename. It carries the rule instead —
    *everything you marked Did not finish* — and it is the one variant that could be built
    the day it is drawn, because two of the four kept lists are already real:
    `Abandoned` is `status: :dropped` on `Kati.Media.TrackedTitle` and `Rewatches` is a
    `Kati.Media.Watch` carrying a `rewatch_number`.
11. **No overflow disc unless you draw its menu.** Rename, share and delete are the three
    things a list detail wants and none of them is drawn anywhere. A `more_horiz` disc
    with an undrawn menu is not a shortcut; it is a new line in
    `Kati.ScreenTapSweepTest`'s inert-tap backlog. Draw the menu or leave the disc off.

**182 — Add to list, top to bottom**

1. **Scrim and sheet** — `rgba(26,25,23,.42)` over the page, paper sheet with 26pt on its
   **top two corners only**, `18px 21px 34px` padding. `Kati.UI.Sheet` is this exact
   shape already.
2. **Header row** — `close` disc · centred title `Add to list` · a 36pt hole the same
   width as the disc. The hole is real markup: the title is centred in the *sheet*, not
   in the space beside the button.
3. **What is being added, named.** One line under the title — `Tidal Works · Album` — so
   the sheet says what it will put where. Screen 73 names its album the same way, and it
   is the fix that stopped a sheet crediting the wrong record (#84).
4. **The made lists**, one row each: `bookmarks` in the 30×30 paper tile, name at
   13.5/600, `14 titles` as the mono second line, and a trailing `check` when this title
   is already in that list. Board 94 is the precedent for the whole row — a tick marking
   current state rather than a radio control.
5. **The ticks arrive populated**, like screen 73's tracks. You are adjusting a set, not
   building one from nothing, and a sheet that opens blank invites the duplicate the tick
   exists to prevent.
6. **The kept lists, and which of them can accept a hand-add.** Two can and two cannot,
   and the difference is already decided in code: `Wishlist` and `Owned on disc` are
   *assertions the user makes and nothing stores*, so a tick is meaningful; `Abandoned`
   and `Rewatches` are derived from status and rewatch count, so a tick would be a lie.
   Draw all four under the `Kept automatically` eyebrow with the derived pair unavailable
   and a one-line reason. Omitting them silently reads as the app forgetting them.
7. **The new-list row** — `add` glyph and `New list` in the dashed bordered row from
   board 89, drawn twice: closed, and opened into a text field. This is the only place in
   the app where a list can be *named*, and it is why the sheet is half of this ticket.
8. **The footnote** — bordered, `info`-led, on the sheet's own paper:
   `Kati.UI.SettingsList.note/2`. Board 94's is the tone to match — it says what the
   decision does *not* touch.
9. **The many-titles band.** Opened from 146 with four selected, the header line reads
   `4 titles` and a list already holding two of them needs a **third tick state** —
   neither on nor off. This is the one genuinely new mark on either board.

## States

Four, and three of them are load-bearing rather than decoration.

- **Resting** — 181 with nine mixed titles; 182 with nothing ticked.
- **Active** — 182 with two ticked and the naming field open; 181's ranked band with the
  handle showing.
- **Empty — draw it, and draw it first.** Screen 12's `add` disc already makes a list with
  `0 titles` and no artwork, so **the empty list detail is the first thing anyone ever
  sees behind that door.** It is not an edge case; it is the common case. And Kati's
  sweeps compare an empty state against a board — `Kati.ScreenEmptyDatabaseTest` asserts
  every literal again with nothing stored — so an undrawn empty state is not merely
  unspecified, it is untested. The sheet has an empty state too: no made lists at all,
  where 182 is the kept band and the new-list row and nothing else.
- **Error** — a tick whose write does not land. `Kati.Write`'s contract is that a save
  returns `{:ok, record}` or `{:error, reason}`, that the caller **keeps the sheet open**,
  and that it shows `Kati.Write.message/1`; `Kati.WriteContractTest` enforces it. So draw
  the tick going back off with the reason in words. If ticking commits immediately there
  is no Save button to hang the failure on, and that is exactly why the state has to be
  on the board.

## RTL

**Yes for 182, and sooner than the parent screen needs it.** Screen 12 has no Persian
mirror and none is asked for here — but `Kati.Screens.AlbumDetailFa` and
`Kati.Screens.BookDetailFa` both draw `Add to list` and both push `Kati.Screens.Lists`
today, so a Persian album detail already opens an English screen. The sheet inherits that
the moment it is built, which makes 182's Persian face the urgent half.

What mirrors: the container takes `dir="rtl"` and the whole grid mirrors; the back pill's
glyph becomes `arrow_forward_ios`; `chevron_right` becomes `chevron_left`; the trailing
`check` moves to the leading edge; counts stay DM Mono with Persian digits so the column
still aligns. What does **not** mirror: **artwork never mirrors** — a poster, a book cover
and the no-art square are identical in both directions, as board 166 states the rule for
its own tiles — and the **vertical order never reverses**: made lists stay above kept
ones, and a ranked list's 1, 2, 3 still run top to bottom.

A full Persian artboard for 181 is a follow-up, not this ticket: drawing the mirror of a
room before its parent screen has one would put the mirror ahead of the door.

## Dark

**Needed, and not as a nicety.** Board **68** is *Book detail — dark*, it draws
`Add to list`, and `Kati.Screens.BookDetailDark` pushes `Kati.Screens.Lists` — which has
no dark face — so a dark page today opens a light one over itself. Draw 182 on the dark
ground: `#121110`, card `#1E1D1B`, ink `#F5F2EE`. The scrim needs deciding at the same
time: `rgba(26,25,23,.42)` over an already-dark page dims almost nothing, and a sheet that
does not visibly float is a sheet whose scrim has stopped working. 68's own caption
already solved the neighbouring case — the selected chip and the ink button invert to
`#F5F2EE on #16150F` rather than vanishing into the paper. 181 can follow later; 182
cannot.

## Reuse, do not invent

- **The sheet** is `Kati.UI.Sheet` — scrim, top-only radius, close disc, centred title,
  36pt hole. Not a new modal.
- **The tick rows** are board 94's country picker, tick and all.
- **Populated ticks** are board 73's track list.
- **The row that names a kind** is board 19's search result.
- **The list row's card** is screen 12's made row: radius 20, padding 13, gap 14, title
  14/700 at `-.015em`, count DM Mono 10.5 in `#A9A29A`.
- **The badge** is `MishkaPill` at 22/11/9/10, cream on `#96723C`.
- **The artwork tile** is 12's stack tile: 38×54, radius 7, 2pt `#FBFAF8` ring.
- **The dashed create row** is `Kati.Screens.AddTitle`'s `by_hand/0`.
- **The reorder handle** is screen 24's *Reorder sections* row.
- **The no-art album** is board 74's paper square with the initial and `Art`.
- **The secondary action tile** on 66/68/74 is already drawn: 54pt, radius 20, card fill,
  19px glyph over a 10.5/600 label. Its *second state* is the only new thing about it.

## What it must NOT do

**Do not draw a chevron on a row that does not push.** The house rule, and screen 12 obeys
it at cost: *"The rows themselves are left untappable on purpose. Their chevrons point at
a list-detail screen the design never draws and the app does not have, and `on_tap={nil}`
— a row that does nothing and admits it — is better than a row that swallows a press."*
This brief is what turns those `nil`s into pushes; nothing else on 12 earns a chevron.

**Do not give a badged row a chevron without deciding what happens to the badge.** They
are the same slot, and the code says so at `lib/kati/screens/lists.ex:250-255`:

> `# No badge means the list is neither ranked nor shared, and the drawing ends`
> `# that row with a chevron instead — the badge slot and the affordance slot`
> `# are the same slot.`

So `Best of 2026` and `Recommended by Jo` lead somewhere and show no chevron today. Either
the badge moves, the row widens, or the badge is allowed to stand in for the affordance —
but pick one on board 12 rather than leaving the two badged rows to be guessed at.

**Do not make 182 a pushed screen.** `Kati.Screens.ShelfSelection`'s moduledoc names what
it settled for and why: *"`Add to list` pushes `Kati.Screens.Lists` (screen 12) — a real
destination screen 03 already opens the same way, and the closest thing to 'add to list'
this app can reach without a list-picker sheet the board does not draw."* A sheet is the
missing piece. A second full page would replace the shelf and lose the selection.

**Do not invent membership for the derived kept lists.** `Abandoned` and `Rewatches` are
computed; `Wishlist` and `Owned on disc` are *"assertions the user makes and nothing
stores"*. A sheet that lets someone tick `Rewatches` promises a write with no column
behind it.

**Do not draw an album with borrowed cover art.** Board 74: *"drawn in its default state:
no art, since Cover Art Archive coverage is patchy — a paper square carrying the album
initial and the 'Art' placeholder rather than a broken image."* The mixed row's album case
takes the square.

**Do not try to solve routing on the board.** That a list detail opened from row three
must be *told* it is row three is a code concern — the same defect #84 fixed for screen
73, which used to re-read the shelf and credit the first album. Draw one list; the id is
`params_for/1`'s job, not the drawing's.

**Do not draw a Save button on 182 and a tick on the same row.** One of them is the
commit. Choose below.

## Left open — decide and note which way you went

- **Does a tick commit immediately, or is there a Done?** Board 94 has no commit at all —
  the tick is the decision. Board 73 has `Save listen`. Membership argues for immediate,
  but immediate is what makes the error state above hard, so this is a real trade.
- **The mixed row's artwork.** One fixed slot with the square letterboxed inside it, or
  each kind at its own aspect with the text baseline held? Whichever you pick, the film,
  the book and the album must be visible in one band so the answer can be read off it.
- **What a badged row on 12 does with its chevron.**
- **Does the `add` disc on 12 keep making an unnamed `New list`,** or does it now open
  182's naming field? Today `Kati.Screens.Lists.add_list/1` makes one called `New list`
  with `0 titles` because no board has ever drawn a place to type a name.
- **The third tick state** for the many-titles case: a dash, a half-fill, or a count.
- **Whether 182 gets a search field.** Seven lists fit; seventy do not. Name the number at
  which the field appears, or say there is never one.
- **Whether 181 carries an overflow at all** — and if it does, the menu is part of this
  drawing, not a later one.
- **Kept-list detail: read-only, or removable?** A title can be un-dropped, and that
  action would live here or on the title. Say which.

## Acceptance

The drawing is complete enough to build from when:

- Board 181 shows a **film, a book and an album in the same list**, and the row recipe is
  the same recipe three times.
- Board 181 shows the **empty list**, with the sentence that explains where titles come
  from, so `Kati.ScreenEmptyDatabaseTest` has a literal to assert against.
- Board 181 shows a **kept list**, distinguishable from a made one without reading the
  title.
- Board 182 shows **ticked and unticked** rows, the **naming field open**, and the
  **many-titles** case with its third tick state.
- Board 182 exists in **dark**, because board 68 reaches it.
- Every glyph on both boards is in `Kati.Icons`'s map, or the brief says which new one is
  wanted and accepts that `mix kati.gen.icons` is blocked until the codepoints file
  exists.
- Boards 12, 66, 68, 74 and 146 have captions naming **181** and **182** by number, the
  way 74's caption names 80 and 73's names 70.
- The badge-versus-chevron decision is visible on board 12 rather than described.

## House style — Kati

Draw into `examples/ui_design/Kati.dc.html` as a new `IOSDevice` artboard, 402×874.

**Numbering.** The app runs **01–166** and nothing may be inserted below 167. This brief's two
screens take **181** and **182**, reserved above.

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
