# Boards delivered, screens not built yet

**Ninety-one artboards from Claude Design, 5 September 2026** — every one of the
twenty-four briefs `D-35`–`D-58`, plus one more for `D-33`. They are here rather
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
renumbered as it drew: 167–208 and 248–301, with 170–171, 205–207 and 209–247
never used. The table below is the mapping that actually shipped, and it is the
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

## How they were extracted

Each `data-screen-label="NN"` and the `<x-import>` block that follows it,
counting nested opens so a frame is not cut at the first close. The method was
checked against three boards already in `screens/` before being trusted — which
is how the re-render difference above was found.

## What arrived, by brief

| Board | Drawing | Brief |
|---|---|---|
| 167 | Up next — sort & filter | `D-35` |
| 168 | Up next — filtered & empty | `D-35` |
| 169 | Discover — sort & filter | `D-35` |
| 172 | Next in series | `D-37` |
| 173 | Lending | `D-37` |
| 174 | Content warnings | `D-37` |
| 175 | Log a read | `D-37` |
| 176 | کتاب‌ها — the Persian Books shelf | `D-38` |
| 177 | Add by hand — Book | `D-38` |
| 178 | Add by hand — a record | `D-39` |
| 179 | Add a title — the music state | `D-39` |
| 180 | Rate an album | `D-39` |
| 181 | List detail | `D-40` |
| 182 | Add to list | `D-40` |
| 183 | Plan editor | `D-41` |
| 184 | When the switch takes effect | `D-41` |
| 185 | Meal overflow | `D-42` |
| 186 | Meal overflow — states | `D-42` |
| 187 | Edit an ingredient | `D-42` |
| 188 | Add a medication | `D-43` |
| 189 | One medication | `D-43` |
| 190 | Medication — empty and annotated | `D-43` |
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
| 202 | Where | `D-36` |
| 203 | With, and + tag | `D-36` |
| 204 | 33 and 144, reconciled | `D-36` |
| 208 | Reference: the settings header | `D-52` |
| 248 | Series — a title with no episodes | `D-58` |
| 249 | سریال بدون قسمت — no episodes, RTL | `D-58` |
| 250 | The moment it fills | `D-58` |
| 251 | Doors for the stranded screens | `D-33` |
| 252 | One service | `D-46` |
| 253 | One expense | `D-46` |
| 254 | The service catalogue, and the five edits | `D-46` |
| 255 | Add an account | `D-49` |
| 256 | A calendar account | `D-49` |
| 257 | Account states | `D-49` |
| 258 | Notifications, at rest | `D-50` |
| 259 | Notifications, nothing waiting | `D-50` |
| 260 | New releases, nothing followed | `D-50` |
| 261 | See all, and one group in full | `D-51` |
| 262 | The four kinds quick add never filed | `D-51` |
| 263 | An override, worked through on Calendar | `D-53` |
| 264 | The other four overrides | `D-53` |
| 265 | Reorder sections | `D-53` |
| 266 | Reorder sections — states | `D-53` |
| 267 | Clear watch history | `D-53` |
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
| 301 | کشور — Your country, RTL | `D-57` |

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
