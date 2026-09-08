# Boards delivered, screens not built yet

**Ninety-five artboards from Claude Design, 5 September 2026**, and **thirty-two
more on 7 September** answering `D-65` in full.

The 5 September wave covered the twenty-four briefs `D-35`–`D-58`, plus `D-34`,
`D-42`'s open question and two answers `D-62` asked for. The 7 September wave is
306–337: one board per ask in `design-briefs/D-65-boards-wanted-7-september.md`,
including all eight Lists amendments and both Persian mirrors.

**118 are here**; eight are built and in `screens/`; one — 251 — is a receipt and
lives in `reference/`. They are here rather
than in `screens/` because `Kati.ScreenDesignLiteralTest` asserts *every drawing
has a screen*: a board in `screens/` with no module behind it turns the whole
suite red, and a red suite is a worse record of "these arrived" than this
directory is.

**Move each file into `screens/` in the same commit that builds its screen** and
registers it in `Kati.Screens.Gallery`. The count assertion in that test moves
with it.

## Two things about this export, both of which cost the last one time

**The numbers are not the ones the briefs reserved.** `MISSING-CONNECTIONS.md`
allocated 167–247 across `D-35`–`D-57` and 248–249 to `D-58`. The canvas
renumbered as it drew: 167–208 and 248–305, with 170–171, 205–207 and 209–247
never used. The 7 September wave carried straight on at 306–337 and needs no
mapping — its labels name their own subject. The table below is the mapping that actually shipped, and it is the
one to trust. Nothing was lost — every brief has its boards.

**The export's copies of boards 01–166 are NOT the repo's.** Extracting 154, 163
and 145 from it and diffing against `screens/` gives three different answers, in
both directions: 154 comes out 2.4KB larger, 163 and 145 smaller. They are
re-renders, and importing one would move a drawing the literal sweep is pinned
to. **Only the boards below were taken.** The previous delivery's README recorded
the same hazard about board 153; it is not a one-off.

Board **134** is in the export too and was NOT taken: it is `D-23b`'s first-run
flow map, 1720px wide, and it already lives in `test/design/reference/134.html`
with its own README saying why it is not a screen.

## How they were extracted — and the three ways it has failed

Each `data-screen-label="NN"` and the `<x-import>` block that follows it,
counting nested opens so a frame is not cut at the first close. The method was
checked against three boards already in `screens/` before being trusted — which
is how the re-render difference above was found.

**It was not enough, and it silently lied rather than reporting a miss.**
Corrected 7 September:

* **251 was a duplicate of 248.** 251 is a 1180px receipt of plain `div`s with
  no `<x-import>` frame — the same shape as 134, which the *previous* export's
  README already recorded as invisible to a frame-based splitter. So the walk
  ran past 251 and captured the next frame it found, which was 248's:
  `251.html` and `248.html` were byte-identical (`6d597c5c…`). The board is
  `D-34`'s and now lives in `reference/251.html`.
* **302–305 were never taken at all.** The 5 September pass stopped at 301.
  They are `D-62`'s three asks — *One service*, *Lending*, and screen 43's
  prepped card, which arrived as **304 What a prep is** — plus **305**, which
  answers `D-62` §2 and §4 by declining to draw them.

The splitter now slices on the labelled element itself, so a board with no phone
frame is captured whole. Counting that tag's own opens and closes is **not**
enough on its own: two boards in the 7 September wave (309 and 311) close early
under a naive `<div>` count and come out truncated — 311 at 3,748 bytes of a
real 10,508. The boundary that holds is **the start of the next labelled
element**, trimmed back to the last balanced close; the tag count is then a
check rather than the method.

Three checks now hold, and all three are cheap:

* no two files in `incoming/` share an md5 — this is what caught 251;
* every `data-screen-label` in the export is on disk here, in `screens/`, in
  `reference/` or in `retired/` — this is what caught 302–305;
* every extracted board balances its own `<div>`s — this is what caught the
  truncation.

## The 7 September wave — `D-65`, answered in full

Thirty-two boards, one per ask. The left column is the screen the board is
about; the right is the section of `D-65` it answers.

| Board | Drawing | Answers |
|---|---|---|
| 306 | 02 — no calendar permission | `D-65` 02 | — **built 8 Sep**, kept here: it is a state of 02 drawn beside three notes, not a frame of one page |
| 307 | 05 + 25 — releases beyond television | `D-65` 05+25 | — **partly built 8 Sep**: 25's three shelves and 66's Follow row are real; 05's glyph-tile recipe waits on a producer for a second shelf (MOVIES-AND-TV.md #133) |
| 308 | 06 — before, during, and found nothing | `D-65` 06 | — **built 7 Sep**, kept here: a state catalogue needs a specimen screen before the literal sweep can hold it |
| 309 | 07 — a year with nothing counted | `D-65` 07 | — **built 7 Sep**, kept here: a state catalogue needs a specimen screen before the literal sweep can hold it |
| 310 | 13 + 92 + 97 — one sentence, one count | `D-65` 13+92+97 | — **built 8 Sep**, kept here: it is a comparison of three screens rather than a frame of one |
| 311 | 14 — at rest, with its own empty band | `D-65` 14 | — **built 7 Sep**, kept here: a state catalogue needs a specimen screen before the literal sweep can hold it |
| 312 | 19 — the field cleared | `D-65` 19 | — **built 7 Sep**, kept here: a state catalogue needs a specimen screen before the literal sweep can hold it |
| 313 | 19 + 91 + 261 — chip rows at 235% | `D-65` 19+91 | — **built 7 Sep**, kept here: three screens at one zoom in one frame |
| 314 | 25 — two literals | `D-65` 25 | — **built 7 Sep**, kept here: a state catalogue needs a specimen screen before the literal sweep can hold it |
| 315 | 28 — dark, with nothing kept | `D-65` 28 | — **built 8 Sep**, kept here: it is 139 crossed into dark plus a token table, not a frame of one page |
| 316 | 50 + 120 — what the code encodes | `D-65` 50+120 | — **built 8 Sep**, kept here: two screens in one frame with the arithmetic between them |
| 317 | 55 — the gate on the Persian empty | `D-65` 55 | — **built 8 Sep**, kept here: it is a ruling about which board 55 shows, not a frame of one |
| 318 | 80 — the token card, three states | `D-65` 80 (1) | — **built 7 Sep**, kept here: a state catalogue needs a specimen screen before the literal sweep can hold it |
| 319 | 80 — the pairing card, four states of one row | `D-65` 80 (2) | — **built 7 Sep**, kept here: a state catalogue needs a specimen screen before the literal sweep can hold it |
| 320 | 80 + 82 — one retirement, mirrored | `D-65` 80 (3) | — **built 7 Sep**, kept here: a state catalogue needs a specimen screen before the literal sweep can hold it |
| 321 | 86 — nothing to suggest from | `D-65` 86 | — **built 7 Sep**, kept here: a state catalogue needs a specimen screen before the literal sweep can hold it |
| 322 | 88 — deferred, withdrawn, and one pill | `D-65` 88 | — **built 7 Sep**, kept here: a state catalogue needs a specimen screen before the literal sweep can hold it |
| 323 | 93 — live, or a specimen | `D-65` 93 | — **built 8 Sep**, kept here: it is a ruling about one group rather than a frame of a screen |
| 324 | ۹۷ — فارسی، هیچ‌چیز تنظیم نشده | `D-65` 97 | — **built 8 Sep**, kept here: 97's board is the full page, and this is a state of it |
| 325 | Year card · the field face, 4:5 at size | `D-65` 98+100 | — **built 7 Sep**, kept here: a state catalogue needs a specimen screen before the literal sweep can hold it |
| 326 | Year card · the genres face + the heading | `D-65` 98+100 | — **built 7 Sep**, kept here: a state catalogue needs a specimen screen before the literal sweep can hold it |
| 327 | 112 — medications, nothing due today | `D-65` 112 | — **partly built 8 Sep**: the card is drawn; its sentence and the true-empty frame wait on MOVIES-AND-TV.md #136 |
| 328 | 140 — four more sources, and the door | `D-65` 140 | — **built 7 Sep**, kept here: a state catalogue needs a specimen screen before the literal sweep can hold it |
| 329 | 141 — the recognition line, six shapes | `D-65` 141 | — **built 7 Sep**, kept here: six states of one card in one frame |
| 330 | L1 — removing, deleting, renaming | `D-65` L1 | — **built 7 Sep**, kept here: a state catalogue needs a specimen screen before the literal sweep can hold it |
| 331 | L2 — the six states 181 did not draw | `D-65` L2 | — **built 7 Sep**, kept here: a state catalogue needs a specimen screen before the literal sweep can hold it |
| 332 | L3 — three artworks, one baseline | `D-65` L3 | — **built 7 Sep**, kept here: a state catalogue needs a specimen screen before the literal sweep can hold it |
| 333 | L4 — the sheet as one screen, and empty | `D-65` L4 | — **built 7 Sep**, kept here: a state catalogue needs a specimen screen before the literal sweep can hold it |
| 334 | L5 — the door, on a film and a series | `D-65` L5 | — **built 7 Sep**, kept here: a state catalogue needs a specimen screen before the literal sweep can hold it |
| 335 | L6 — one naming grammar, one failure rule | `D-65` L6 | — **built 7 Sep**, kept here: a state catalogue needs a specimen screen before the literal sweep can hold it |
| 336 | L7 — جزئیات فهرست، فارسی | `D-65` L7 | — **built 7 Sep**, kept here: a state catalogue needs a specimen screen before the literal sweep can hold it |
| 337 | L8 — انتخابگر فهرست، فارسی | `D-65` L8 | — **built 7 Sep**, kept here: a state catalogue needs a specimen screen before the literal sweep can hold it |

## What is built, and why the files stay here

**Twenty-one of the thirty-two are built and device-verified**: 308, 309, 311,
312, 314, 318, 319, 320, 321, 322, 325, 326, 328 and the whole Lists eight,
330–337. Board **320** also needed screen **114** built, which had never
existed — `Kati.Screens.RetiredReason`, now behind three surfaces that had drawn
*tap to see why* with nothing under it since they were written. Their files stay in this
directory rather than moving to `screens/`, and that is not an oversight — the
rule at the top of this file says a board moves when its screen renders every
literal on it, and **most of the 7 September wave are state catalogues**. 330
stacks a resting page, an open menu, a confirmation and an undo bar in one
frame; 333 is 1249pt of states in an 806pt sheet; 328 draws a row in two locales
beside the screen behind it and the defect it replaces. No screen is ever in
those states at once.

The repo's answer to that shape is a specimen screen per states board — 155 is
154's, 95 is 92's — and those are not built. Until they are, the screens are on
`Kati.Screens.Gallery`'s undrawn list and on `@undesigned`, which skips the
literal comparison and keeps the render. Each entry says so where it sits.

**325 and 326 carry no phone frame** — a year card is 402×502 and is not a
screen, so they are drawn at their real size the way `D-65` asked. They amend
98 and 100 rather than becoming screens of their own, which is the same category
as 208 and 250 in the wave above.

**330 rules `rename` in.** `D-65` L1 asked, and the board answers: the list gets
a ⋯ disc carrying Rename / Share / Delete, because *"181 ruled no overflow disc
with nothing decided; it is decided now"* — and rename reuses the index's own
48px field rather than inventing a second naming grammar, which is 335's subject.

## What arrived, by brief — the 5 September wave

| Board | Drawing | Brief |
|---|---|---|
| 167 | Up next — sort & filter | `D-35` |
| 168 | Up next — filtered & empty | `D-35` |
| 169 | Discover — sort & filter | `D-35` — **not built**, and MOVIES-AND-TV.md #153 counts why: ten of its eleven controls have nothing on a real device to act on, because a pick carries no score, no date and no service, and a real feed has no people. The board says so itself — *"every count on this sheet comes from Discover's own sample… so the build is not asked to infer a recommender from a chip"*. Its sibling 167 IS built, because a queue has all four of its keys. |
| 172 | Next in series | `D-37` |
| 173 | Lending | `D-37` |
| 174 | Content warnings | `D-37` |
| 175 | Log a read | `D-37` |
| 176 | کتاب‌ها — the Persian Books shelf | `D-38` |
| 177 | Add by hand — Book | `D-38` |
| 178 | Add by hand — a record | `D-39` — built, moved to `screens/` |
| 179 | Add a title — the music state | `D-39` — built, moved to `screens/` |
| 180 | Rate an album | `D-39` — built, moved to `screens/` |
| 181 | List detail | `D-40` |
| 182 | Add to list | `D-40` |
| 183 | Plan editor | `D-41` |
| 184 | When the switch takes effect | `D-41` |
| 185 | Meal overflow | `D-42` |
| 186 | Meal overflow — states | `D-42` |
| 187 | Edit an ingredient | `D-42` |
| 188 | Add a medication | `D-43` — built, moved to `screens/` |
| 189 | One medication | `D-43` — built, moved to `screens/` |
| 190 | Medication — empty and annotated | `D-43` — built, moved to `screens/` |
| 191 | One weight reading | `D-44` |
| 192 | One goal | `D-44` |
| 193 | The affordance, the window, the empties | `D-44` |
| 194 | ثبت وزن — log weight, RTL | `D-45` |
| 195 | هدف جدید — new goal, RTL | `D-45` |
| 196 | The overflow menu | `D-47` |
| 197 | Repeats | `D-48` |
| 198 | Alerts | `D-48` |
| 199 | Location | `D-48` |
| 200 | Event detail — the field card, twice | `D-48` |
| 201 | Watched on | `D-36` |
| 202 | Where | `D-36` — **partly built 8 Sep**. Its substance is in: `Kati.Media.Watch.place` was read by `where_label/1` and written by nothing, so `Lumen+ · living room` could only print half of itself; `Kati.Screens.Rating.place_editor/1` is the section that writes it, and `Not on a service` joins the service row. What is not built is the SHEET — MOVIES-AND-TV.md #95 settled that screen 33's context rows disclose in place rather than push, and board 204 is the reconciliation. MOVIES-AND-TV.md #154. |
| 203 | With, and + tag | `D-36` |
| 204 | 33 and 144, reconciled | `D-36` — **a decision, not a build**. The board rules three chevrons that push; MOVIES-AND-TV.md #95 built three rows that disclose in place, with the reasoning on file. The substance of 201, 202 and 203 is built either way — see #154 for 202's half — so this is a change of shape rather than of capability, and it is the owner's. MOVIES-AND-TV.md #155. |
| 208 | Reference: the settings header | `D-52` |
| 248 | Series — a title with no episodes | `D-58` — **built 8 Sep**, kept here: it draws a specimen frame AND an annotated variant (*Watching — the same board, chip lit*), so the literal sweep cannot compare it against one render. `Kati.Screens.Series.episodes/1` draws the card, the *What still works* group and the footnote; `Kati.ScreenSeriesTest` asserts the copy, the three taps and the empty primary slot. MOVIES-AND-TV.md #149. |
| 249 | سریال بدون قسمت — no episodes, RTL | `D-58` — **built 8 Sep**, kept here for 248's reason: it draws a specimen frame and an annotated variant in one file. `Kati.Screens.SeriesFa.episodes/1`'s empty clause is the first thing in that module built out of the SHARED components rather than a Persian copy of them, which `K-48 locale-face` is what made possible. `Kati.SeriesFaTickTest` asserts the copy, the mirrored chevrons and the three taps. |
| 250 | The moment it fills | `D-58` — **moved to `reference/`** on 8 Sep. It is a before/after of one page rather than a page: 248's state beside screen 04 proper. It is the spec 248's build was checked against, and `test/design/reference/README.md` records the claim it makes. |
| 251 | Doors for the stranded screens | `D-34` — a receipt, moved to `reference/` |
| 252 | One service | `D-46` — **partly built 8 Sep** as `Kati.Screens.Service`, reached from screen 23's rows. Built: the price (displayed, not owned — the board says so), the renewal day, the pause switch, what was watched here, and Remove. Dropped rather than drawn dead: cost per watched hour and hours watched, which board 252 argues away itself, and *Shared with*, which needs a people table Kati does not have. MOVIES-AND-TV.md #156. |
| 253 | One expense | `D-46` |
| 254 | The service catalogue, and the five edits | `D-46` |
| 255 | Add an account | `D-49` |
| 256 | A calendar account | `D-49` |
| 257 | Account states | `D-49` |
| 258 | Notifications, at rest | `D-50` |
| 259 | Notifications, nothing waiting | `D-50` |
| 260 | New releases, nothing followed | `D-50` — **built 8 Sep**, kept here: two frames and a page of notes. `Kati.Screens.Inbox.nothing_followed/0` is the state, and it replaces a fallback that drew `Kati.Library.Sample`'s releases to a reader who follows nothing. `Kati.ScreenInboxEmptyTest` holds the copy and both doors. MOVIES-AND-TV.md #151. |
| 261 | See all, and one group in full | `D-51` |
| 262 | The four kinds quick add never filed | `D-51` |
| 263 | An override, worked through on Calendar | `D-53` |
| 264 | The other four overrides | `D-53` |
| 265 | Reorder sections | `D-53` |
| 266 | Reorder sections — states | `D-53` |
| 267 | Clear watch history | `D-53` — **built 8 Sep**, kept here: it draws the page AND its confirmation in one frame, plus an edit to screen 24's row. `Kati.Screens.ClearHistory` is the screen and `Kati.Media.History` the domain; `Kati.ScreenClearHistoryTest` holds the three rules the board makes about numbers. MOVIES-AND-TV.md #152. |
| 268 | Delete everything | `D-53` |
| 269 | The destructive confirmation — states | `D-53` |
| 270 | Sync | `D-54` |
| 271 | Notifications | `D-54` |
| 272 | Why am I not getting these? | `D-54` |
| 273 | زبان — Language, RTL | `D-55` |
| 274 | تقویم — Calendar, RTL | `D-55` |
| 275 | اعداد — Numerals, RTL | `D-55` |
| 276 | شروع هفته — Week start, RTL | `D-55` |
| 277 | اندازه متن — Accessibility, RTL | `D-55` |
| 278 | درون‌ریزی — Import, RTL | `D-55` |
| 279 | برون‌ریزی همه‌چیز — Back up, RTL | `D-55` |
| 280 | افزودن عنوان — add a title, RTL | `D-56` |
| 281 | تازه‌ها — new releases, RTL | `D-56` |
| 282 | عادت‌ها — habits, RTL | `D-56` |
| 283 | روز — a heavy day, RTL | `D-56` |
| 284 | رویداد — an event, RTL | `D-56` |
| 285 | کتاب‌ها — Books shelf, RTL | `D-56` |
| 286 | موسیقی — Music shelf, RTL | `D-56` |
| 287 | بعدی — up next, RTL | `D-56` |
| 288 | کشف — discover, RTL | `D-56` |
| 289 | فهرست‌ها — lists, RTL | `D-56` |
| 290 | فیلم — film detail, RTL | `D-56` |
| 291 | وعده — a meal, RTL | `D-56` |
| 292 | خرید — shopping, RTL | `D-56` |
| 293 | تغذیه — nutrition, RTL | `D-56` |
| 294 | برنامه‌ها — plans, RTL | `D-56` |
| 295 | اشتراک‌ها — Subscriptions, RTL | `D-57` |
| 296 | ثبت شنیدن — Log a listen, RTL | `D-57` |
| 297 | امتیاز — the rating sheet, RTL | `D-57` |
| 298 | پایش انتشار — Release watcher, RTL | `D-57` |
| 299 | هدف تازه — New goal, RTL | `D-57` |
| 300 | ثبت وزن — Log weight, RTL | `D-57` |
| 301 | کشور — Your country, RTL | `D-57` | — **built 8 Sep**, kept here: the frame is a sheet drawn beside three notes about what 94 and 97 got wrong |
| 302 | One service | `D-62` — **partly built 8 Sep** as `Kati.Screens.Service`, reached from screen 23's rows. Built: the price (displayed, not owned — the board says so), the renewal day, the pause switch, what was watched here, and Remove. Dropped rather than drawn dead: cost per watched hour and hours watched, which board 252 argues away itself, and *Shared with*, which needs a people table Kati does not have. MOVIES-AND-TV.md #156. |
| 303 | Lending | `D-62` |
| 304 | What a prep is | `D-42` §3 |
| 305 | §2 and §4 — decided, not drawn | `D-62` |

## Where to start

`D-58`'s three (248, 249, 250) close the one defect a person can see today: add a
series by hand, tap it on the shelf, and screen 04 draws *The Long Hollow*,
because `facts/1` answers `nil` for a title with no cached episodes. 250 — *the
moment it fills* — is the reference sheet that brief asked for and did not
require.

After that, `D-38`'s 176–177 and `D-39`'s 178–180 are worth more than their size
suggests: they are the only way to put a book or a record into the app by hand,
and until they exist the Books and Music shelves can only be verified against
their fixtures on a device. Phase 3 has moved both onto their tables; nothing can
reach that code from the UI yet.

**Within Movies & TV — the scope the app is being finished in — these are the
boards that answer an open defect**, and none of them needs anything drawn
first: 248/249/250 (04 with no episodes), 167/168 (10's sort, filter and empty),
169 (11's), 181/182 (the whole Lists feature, which shipped with no board and
disagrees with both), 201/202/203/204 (33 and 144 reconciled), 252/254 and 302
(92, 93 and one service), 258/259/260 (05 and the two notification pages),
261/262 (19's see-all), 270/271/272 (Sync and why nothing arrives), and the RTL
set 280/281/287/288/289/290/295/297/298.
