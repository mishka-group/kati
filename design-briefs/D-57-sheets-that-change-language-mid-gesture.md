# The sheets that change language mid-gesture

> **Modal sheet · seven new artboards, no board edits** · ticket `D-57`

A person is reading board **69** in Persian and taps `star امتیاز` to rate the book. A person
is on board **76** and taps `ثبت شنیدن` to record the album they just played. A person is on
board **79** and taps `یادآوری کن` on the release card, on **108** the `add` disc to set a
goal, on **115** the `add` disc to record a weight, on **97** the `کشور` row to say where they
live, and on **127** any of the three ledger rows to see what a service costs. Seven gestures,
all of them begun inside a right-to-left Persian page, and **all seven end in English laid out
left to right** — over a page the reader has not left, with a `close` disc that has moved to the
other edge and a commit button whose label they did not ask to change language. One of the seven
does not even get that far: `Kati.Screens.SubscriptionsFa` is pushed at
`lib/kati/screens/money_fa.ex:1068` and **defined nowhere in the repo** — `grep -rn
'SubscriptionsFa' lib/ test/` returns that one line and nothing else — so every ledger row on
board 127 raises rather than opening anything. `Mob.Socket.push_screen/3` only records
`{:push, dest, params}` (`deps/mob/lib/mob/socket.ex:142-144`); it never checks the module
exists, which is exactly why `Kati.ScreenTapSweepTest` sees a socket that changed and passes,
and the failure lands on the device instead.

These are one brief because the modules say so in nearly the same sentence, six times over:
`album_detail_fa.ex:880-886`, `book_detail_fa.ex:645-646`, `artist_detail_fa.ex:810-815`,
`goals_fa.ex:906-913`, `health_fa.ex:1029-1033`, `my_services_fa.ex:125-133`. And they share one
design decision that has to be made once or it will be made seven inconsistent times. A modal
sheet is the **one surface where `Kati.Screens.Fa.pushed_frame/2` gives you nothing** — read it
at `lib/kati/screens/fa.ex:157-176`: *"A pushed mirror draws its own dismissal — 58 floats a back
pill over its artwork — so unlike `Kati.Screens.Pushed` this adds nothing but the root node."* It
returns a `Box` with `layout_direction="rtl"` and the caller's content. No scrim, no header, no
close disc, no back pill. So each of the seven has to draw its own way out, and the set needs one
recipe for it. Board **72** is the only Persian sheet that exists and it is the proof this works
— but it hand-built its header (`log_progress_fa.ex:106-121`) because
`Kati.UI.Sheet.sheet/3` takes its direction from `Kati.Locale.direction_prop()`, the app
*setting*, which is the one thing a Persian mirror must not trust. Seven more sheets each
inventing that header is how the Persian half of the app acquires seven different close buttons.

## Exactly what to draw

Five of the seven are sheets. **Two are not**, and that is a fact about the English boards
rather than a choice: board **23** and board **25** both open with `arrow_back_ios_new` + a
parent name + a `more_horiz` disc — pushed pages, not sheets — so 241 and 244 take the Persian
**back pill** (`arrow_forward_ios`, the recipe 69, 76, 79 and 127 already draw) and the other
five take the Persian **sheet header**. The brief is still one brief: the failure is identical
and the dismissal recipe is the thing being settled, in both of its two forms.

| Artboard | What it is | What it carries |
|---|---|---|
| **241** — new | **اشتراک‌ها — Subscriptions, RTL.** The mirror of **23**, and the only board in this set that stops a live crash. Pushed from 127's three ledger rows and from 97's مالی row | Persian back pill + `more_horiz`; title اشتراک‌ها with `۵ فعال`; the `هر ماه ۴۶٫۴۷ پوند` hero **with the currency word after the figure**, as 127 draws it and 23 does not; the four service rows with the per-hour rate coloured by its own verdict; and **the paused Aria Audio row, which 127 refuses to draw and this board must supply** |
| **242** — new | **ثبت شنیدن — Log a listen, RTL.** The mirror of **73**, and the asymmetry that proves the whole ticket: 72 was mirrored as `LogProgressFa` and 73 was not, so the same gesture stays Persian for a book and leaves Persian for an album | Persian sheet header; the album row for کارهای جزر و مد; three reversed segments; the five-track tick list in **76's own Persian track names**, already-counted rows in the watched fill; `شروع در` row; the cream confirmation line; one commit |
| **243** — new | **امتیاز — the rating sheet, RTL.** The mirror of **33**, pushed from both 69 and 76 | Persian sheet header with the trailing **ذخیره** pill (33 is the one sheet in the set that commits from the header, not the foot); the title card with the rewatch pill; the star row and the `۵★` / `۱۰pt` scale toggle; the review field with its spoiler toggle and character count; 33's three context rows, mirrored; the tag row |
| **244** — new | **پایش انتشار — Release watcher, RTL.** The mirror of **25**. Pushed from 79's `یادآوری کن` and 127's reminder pill | Persian back pill + `more_horiz`; the cream watcher banner; the six *چه چیزی را بگو* rows with their switches; the four cadence segments, reversed; the four *چقدر بلند* rows; the dashed `info` footnote that says push is off by default |
| **245** — new | **هدف تازه — New goal, RTL.** The mirror of **106**, behind 108's `add` disc — the only control on that board besides back | Persian sheet header; ten type chips in four labelled groups; the ±stepper with a Persian numeral and a Persian unit word; the four **Shamsi** period segments; the repeat row whose second line must read **۱ فروردین**, not 1 January; the ink commit at the foot |
| **246** — new | **ثبت وزن — Log weight, RTL.** The mirror of **111**, behind 115's `add` disc | Persian sheet header; the `۷۶٫۰ کیلوگرم` hero with the unit inside the numeral and the `۰٫۱` step; the three unit segments reversed; the date row with its `اکنون` pill; the optional note row; the `arrow_downward` comparison line; one commit |
| **247** — new | **کشور — Your country, RTL.** The mirror of **94**, behind 97's کشور row | Persian sheet header; the search field placeholder counting **۱۹۰** countries; the seven-country card with the tick **on ایران, not on بریتانیا**; the cream `info` footnote saying what changing this cannot touch |

**No existing board is edited.** 23, 25, 33, 69, 73, 76, 79, 94, 97, 106, 108, 111, 115 and 127
all stay exactly as they are.

## Every element, and the glyph it takes

Every symbol named below was checked against `Kati.Icons`' inlined map before it was written
here. That is a hard constraint rather than tidiness:
`test/design/material_symbols.codepoints` is not in the repo and never was, `mix kati.gen.icons`
wants it, and per `docs/DESIGN-ASSETS.md` *"the icon map it generates is already inlined in
`Kati.Icons`, so nothing is blocked until a new symbol is needed"* — so a glyph invented on these
boards is the thing that blocks the build. Three names a designer will reach for on 243 and 246
are **not** in the map: `star_half`, `arrow_upward` and `scale`. 33 has already settled the first
of them; see *What it must NOT do*.

Every Persian string below is a **proposal**, in the manner boards 72, 76, 97 and 127 all state
in their own captions and `Kati.Screens.MoneyFa` enforces by keeping its copy in one `@copy` map
so *"a native reader corrects each one once"*.

### Artboard 241 — اشتراک‌ها

| Element | Purpose | Glyph |
|---|---|---|
| Floating back pill, 44pt, Vazirmatn label | `Kati.Screens.BookDetailFa.chrome/0`'s pill, not `Kati.Screens.Pushed.back_pill/1` — 76's moduledoc gives both reasons: the shared pill takes its direction from the app setting, and it builds an unstyled `Text`, so *"the label would be a row of empty boxes pointing the wrong way"*. The label is the open question below | `arrow_forward_ios` |
| Overflow disc, 44pt, sharing the pill's row | `Kati.Screens.Fa.disc/2`. 23's own note: the disc sets that row to 44 tall rather than 42. Draw it; do not draw what it opens | `more_horiz` |
| Title **اشتراک‌ها** + mono subtitle `۵ فعال` | 127's title recipe: Vazirmatn at the design's mono size, because `kati_mono.ttf` carries none of U+06F0–U+06F9 | — |
| Hero: eyebrow **هر ماه**, then `۴۶٫۴۷ پوند` | `@copy.every_month` is already `"هر ماه"` in `money_fa.ex:214`. The currency **word follows the figure** per CLDR — 127's caption pins it, *"matching 56's precedent"* — where 23 draws a leading `£` | — |
| The change line, `از اسفند ۴٫۰۰ پوند بیشتر شده — اوربیت قیمتش را بالا برد` | Verbatim from `@copy.change_lead` / `change_rest`. It is already written and already correct | `trending_up` |
| Eyebrow **سرویس‌ها** | House eyebrow, accent rule | — |
| Three service rows — badge tile, trade name in Vazirmatn, Persian renewal line, price over per-hour rate | 127 draws all three already: `L / Lumen+ / تمدید ۲۷ مرداد · ۴۱ ساعت / ۸٫۹۹ پوند / ۰٫۲۱/ساعت` and its two siblings, from `@services` at `money_fa.ex:238-242`. Trade names stay Latin — 97's caption: *"they are trade names, not copy"* | letters, not glyphs |
| The rate's colour, per row | `green_text` when the service earns its money, `red` when it does not, `tertiary` for an em dash. 23's moduledoc is blunt about why: *"an hour of television costing more than a cinema ticket is a fault, not a statistic"* | — |
| **The paused row — the one thing on this board that exists nowhere yet** | 23 draws `A · Aria Audio · paused until October · £5.00`, no rate, both lines greyed, *"the one row where the right-hand column is a single value"*. `money_fa.ex:231-237` says exactly why 127 omits it: *"a service with no Persian line here is not drawn at all… An English renewal line inside a Persian card would be worse than a missing row, and inventing a Persian one for a row the drawing never showed would be worse than both."* This board is what supplies it | letter tile |
| Quiet eyebrow over the suggestion | `Kati.UI.Eyebrow.quiet/1` — 23's rule: *"a suggestion the app is offering is not new and not now"* | — |
| The suggestion card and its two buttons | Already Persian in `@copy` at `money_fa.ex:222-228`, sentence and both labels: `این ماه ۶ ساعت در اوربیت تماشا کرده‌اید و ۱ عنوان در صف مانده…`, `۱ شهریور یادم بیاور`, `بی‌خیال`. Reuse them; do not retranslate | `lightbulb` |

### Artboard 242 — ثبت شنیدن

| Element | Purpose | Glyph |
|---|---|---|
| Sheet header: close disc at the **leading (right)** edge, centred Vazirmatn title, 36pt hole | 72's `header/1` exactly — `Kati.UI.Sheet.close_disc()` first in an `rtl` `Row`, the title rebuilt as a Persian `Text`, and the trailing empty 36pt `Box` that `Kati.UI.Sheet`'s moduledoc insists on: *"The title is centred **in the sheet**, not in the space left over beside the close button"* | `close` |
| Album row — 56pt art tile, title, artist · year | 76's album, its art **unmirrored**: `AlbumDetailFa`'s first rule is that the square is 74's square *"unchanged down to the letter in it: `T` for Tidal Works, and the Latin word `Art` under it"* | — |
| Three segments, reversed: `دقیقه` · `آهنگ‌های انتخابی` · `کل آلبوم` | 72's `segments/2` geometry — hand-rolled, because `Kati.UI.Segmented.plain/2` paints its own label and a Persian label through that door is a row of boxes. **`آهنگ‌های انتخابی` is the raised one**, per 73's reasoning that opening on the whole album *"would hide the fact that four of these five tracks are already counted"* | — |
| Five track rows: index, title, duration, tick | 76's own five — `آب کم ۴:۱۲` · `برداشت ۳:۴۸` · `سیاه‌خار ۵:۰۲` · `فصل گودال ۴:۳۱` · `آنچه جزر باقی گذاشت ۶:۰۸`. 73 draws four; the Persian album page draws five, and the sheet belongs to the album | `check` |
| Already-counted rows in the watched fill | 73 reuses 04's episode-row recipe so *"a second tick is visibly a second tick"* | `check` |
| The `info` line under the list | 73's *"Ticked rows are already counted this month"*. Proposal: `ردیف‌های تیک‌خورده این ماه شمرده شده‌اند.` | `info` |
| Started-at row | 72 already writes this phrase: `schedule شروع در ۲۱:۰۲`. 73 keeps the row *"for parity with 70"* even though nothing computes with it | `schedule` |
| Cream confirmation line | 73's *"That's 11 tracks · 47 minutes · 4th time this month"*, in Persian digits with a Persian ordinal | `lightbulb` |
| One ink commit at the foot, full width | **One primary button per screen.** 73 has one commit and 70 has two, because *"an album has no equivalent of closing a book"* — so there is no تمام شد here and there must not be | — |

### Artboard 243 — امتیاز

| Element | Purpose | Glyph |
|---|---|---|
| Sheet header with a **trailing ذخیره pill** | 33 is the one sheet in this set that commits from the header rather than the foot, and its moduledoc says why the header is not a back pill: *"it is a sheet you either commit or abandon, and a back arrow says neither."* Under `rtl` the close disc goes right and the pill goes left | `close` |
| Title card: film title, `۲۰۲۵ · ۱ ساعت و ۵۲ دقیقه`, rewatch pill | 33's `2nd rewatch` becomes a Persian ordinal. Poster/art, if drawn, **never mirrors** | `replay` |
| Star row — four filled, one outlined, then `۴٫۵` | Every star is the Material `star` glyph, never the character `★`: 33's moduledoc — *"Plus Jakarta Sans carries no U+2605, so on the device those render as nothing at all."* The half star is the same glyph at **FILL 0** | `star` |
| Scale toggle `۵★` / `۱۰pt` | Two segments 3pt apart. `MishkaSegmentedControl` cannot draw it — no gap prop, and a segment's content is a string, so the glyph would typeset in a face that lacks it | `star` |
| The caption under the stars | 33 prints `HALF STARS ON · TAP LEFT OR RIGHT OF CENTRE`. In Persian this is an eyebrow in Vazirmatn 11/600 with **no tracking**, per `Kati.Screens.Fa`: the Persian eyebrow *"is that recipe, not `Kati.UI.eyebrow/2` with a translated label"* | — |
| Review card: label, spoiler toggle, body field, character count, format row | The body is a real `<TextField>`. Two costs are already recorded and apply here: `MobTextField` is `singleLine = true`, and the count is Latin-digit today | `visibility_off` · `format_bold` · `format_italic` · `link` |
| Three context rows: تماشا شده / کجا / با | 33's `event` / `tv` / `group` tiles and second lines, mirrored. **Their chevrons flip and nothing behind them is this ticket's** — see *What it must NOT do* | `event` · `tv` · `group` · `chevron_left` |
| Tag row: three attached tags and the dashed `+ tag` ring | Each tag is a lifted card, not a `MishkaChip` — it has no `shadow` and no `border_width`, and the ring is a border with no fill. The `+` is a literal in the label, not a glyph | — |

### Artboard 244 — پایش انتشار

| Element | Purpose | Glyph |
|---|---|---|
| Persian back pill + `more_horiz`, one row | `SettingsList.chrome("more_horiz")` is what 25 uses; the Persian equivalent is 127's `chrome/0` — pill at one end, `Fa.disc("more_horiz")` at the other | `arrow_forward_ios` · `more_horiz` |
| Title **پایش انتشار** + `آخرین بررسی ۱۸:۰۲` | Persian digits in the design's mono size, set in `fa` | — |
| Cream banner: switch, `۲۴ عنوان زیر نظر`, `۳ مورد این هفته` | The same card 05 puts at the top of the inbox, *"so the thing the watcher does and the thing you configure look like one object seen from two sides"* | `auto_awesome` |
| Eyebrow **چه چیزی را بگو** + six switch rows | 25's six, each a 30×30 tile + title + consequence line + switch: قسمت‌های تازه · نخستین‌ها · به‌زودی تمام می‌شود (`۷ روز` notice) · کسانی که دنبال می‌کنید · کاهش قیمت · تمدیدها (`۲ روز` before) | `live_tv` · `celebration` · `timer` · `person` · `sell` · `payments` |
| Eyebrow **هر چند وقت** + four segments, reversed | `ساعتی` · `هر ۶ ساعت` · `روزانه` · `دستی` — hand-rolled at 72's geometry, for 72's reason | — |
| Eyebrow **چقدر بلند** + four rows | اعلان فشاری (**off**) · نشان صندوق · ساعات سکوت `۲۳:۰۰ – ۰۸:۰۰` · خلاصه هفتگی. The last row's default day is an open question below | `notifications_off` · `inbox` · `bedtime` · `mail` |
| The dashed footnote | 25's whole argument, and it is the reason the screen exists: *"Push is off by default. The app is designed to be checked, not to interrupt."* | `info` |

### Artboard 245 — هدف تازه

| Element | Purpose | Glyph |
|---|---|---|
| Sheet header, title **هدف تازه** | 72's header | `close` |
| Eyebrow **چه چیزی** | — | — |
| Four labelled groups of chips, ten chips total | 106's grouping is `Kati.Goals.Goal.kinds/0`'s, *"so a new kind arrives in the right group without anyone editing a layout"*. Group labels: نمایش · کتاب · موسیقی · سلامت. Chips: فیلم / قسمت / ساعت تماشا · کتاب / صفحه / دقیقه مطالعه · آلبوم / دقیقه شنیدن · وعده پخته / روز عادت — all proposals | — |
| Eyebrow **چه‌قدر** + stepper | The `−` and `+` discs stay where they are: the stepper column **does not mirror**, so the numeral still sits under itself when it grows a digit. 72 states this and 108's three hero figures depend on the same alignment | `remove` · `add` |
| The unit word beside the value (`فیلم`) | 108 already writes goal titles this way: `۱۲۰ فیلم در این سال` | — |
| Eyebrow **تا کِی** + four segments, reversed | `دلخواه` · `سال` · `ماه` · `هفته`. These are **Shamsi periods** | — |
| Repeat row: title, second line, switch | 106's second line reads *Restarts 1 January*. In Persian it must read **۱ فروردین**. 108's own cream card is on the board precisely to say `یک هدف «سالانه» در پایان اسفند تمام می‌شود، نه ۳۱ دسامبر` | `repeat` |
| Ink commit at the foot, full width | 106's caption: *"the sheet is long enough that a top-right Save would scroll out of reach, and a commit you have to scroll back to is a commit people abandon"* | — |

### Artboard 246 — ثبت وزن

| Element | Purpose | Glyph |
|---|---|---|
| Sheet header, title **ثبت وزن** | 72's header | `close` |
| Stepper hero: `−` · `۷۶٫۰ کیلوگرم` · `+`, with `گام ۰٫۱` under it | The unit sits **inside** the numeral, *"so the hero reads as one value"*. The decimal separator is U+066B, which is what 115's own annotation says holds the entries column aligned | `remove` · `add` |
| Three unit segments, reversed | `kg` · `lb` · `st` in Persian words is an open question below | — |
| Date row: `امروز ۲۵ مرداد، ۰۷:۴۲` with an `اکنون` pill | Shamsi date, Persian digits. 115 already dates itself `یکشنبه ۲۵ مرداد` | `event` |
| Note row, optional, with a chevron | 111's *"Optional — after a run, before breakfast…"*. The chevron flips | `sticky_note_2` · `chevron_left` |
| The comparison line | 111's *"0.4 kg down from your last reading, three days ago"* — a comparison with the last reading and **never with a goal**: `Kati.Health` is not a medical device and records what it was told. The arrow does not mirror; direction of change is not direction of reading | `arrow_downward` |
| Ink commit at the foot | — | — |

### Artboard 247 — کشور

| Element | Purpose | Glyph |
|---|---|---|
| Sheet header. Title: کشور, or کشور شما — 97's row says کشور and 94's sheet says *Your country* | A sheet and not a pushed page, for 94's stated reason: *"picking a country is one decision you come back from, not a place you navigate to"* | `close` |
| Search field, 46–48pt, radius 23/24 | Placeholder `جست‌وجو در ۱۹۰ کشور` — **۱۹۰**, not ۷. `country_picker.ex:63-66`: *"a placeholder that said `Search 7 countries` would be telling the truth about the wrong thing"* | `search` |
| Seven rows: 40pt flag tile at radius 12, name, tick on the current one | `Kati.Services.countries/0`'s seven, in its order: بریتانیا · **ایران** · ایالات متحده · آلمان · فرانسه · هلند · استرالیا | flag emoji, not glyphs |
| **The tick is on ایران** | Not on بریتانیا. `my_services_fa.ex` substitutes `"IR"` for the English default and says why: *"Screen 97 was captured in Iran, and a Persian mirror that answers *available* for the United Kingdom before anyone has chosen is answering for the wrong country"* | `check` |
| The cream footnote | 94's, repeated on purpose: availability is per country, and *"it never touches your library, ratings or history"* — because *"a country picker in a media app is a frightening control until somebody says what it cannot do"* | `info` |

## States to draw

`Kati.ScreenEmptyDatabaseTest` renders every screen against an empty store and asserts the
board's literals against the rendered tree. An empty state that is not drawn is therefore not
merely undesigned; it is **untested**, and on four of these seven the empty state is where the
money is.

- **Resting.** All seven. This is the state every one of them is missing entirely today.
- **Active.** Three matter and the rest do not. On **242**, a track row mid-tick — the ticks
  arrive populated, so tapping one is *removing* a count, and that has to be legible. On
  **243**, a star under the finger: each star carries two tap targets, left half and right
  half, and nothing else on the board says so. On **247**, the row being chosen, since the
  tick is *a mark, not a radio* and the transition is the only thing that says the whole card
  is one control.
- **Empty.** Two are real and one is a trap. **242** with an album that has never been played:
  no ticks, and the *nth time this month* line has nothing to count — that page must not
  borrow 76's five play counts. **241** with nothing subscribed: `Kati.Services.count/0`'s
  doc already fixes the answer — *"Zero is a real answer… Screen 96 draws the empty ledger as
  No subscriptions yet — an empty ledger, not £0.00 a month — there is nothing here to be
  zero"* — so 241 at zero is a sentence, not `۰٫۰۰ پوند`. The trap is **245** and **246**: a
  compose sheet is *supposed* to open with nothing in it, and that is the resting state
  already, not a second one.
- **Error.** Four of these seven sheets stay open on a failed write and say so, and **not one
  of the English boards draws it**. `Kati.Screens.LogWeight`: *"the sheet stays where it is,
  with your grams still in the stepper, and says so in red above the button you just pressed."*
  `Kati.Screens.LogListen`: *"the sheet stays open on the error with the reason drawn over the
  commit button… the ticks you set are still ticked."* `Kati.Screens.NewGoal` and
  `Kati.Screens.Rating` say the same. Do not invent a treatment: board **155** already
  specifies it — `error` glyph, the sentence that *names what is missing and then says nothing
  was written*, a red inset ring on the field that keeps its caret, and **the button is never
  disabled, because a dead button explains nothing**. Draw that refusal once, as an inset on
  **246**, and let the other three cite it. What is genuinely new is that the sentence must be
  Persian and must wrap in Vazirmatn's taller line-height — 97's caption warns that consequence
  lines run deeper in Persian than in the English original.

## RTL

**Every one of these seven artboards is the Persian mirror.** There is no LTR pair to draw and
none should be drawn: the English originals are 23, 25, 33, 73, 94, 106 and 111 and they are
already in the set. What follows is what the mirror does to each of them.

**Mirrors.** The root box carries `layout_direction="rtl"` and every `Row` under it lays out
start-to-end, so the whole grid turns for free. The sheet's close disc moves to the **right**
edge and 243's ذخیره pill to the left. The back pill's glyph becomes `arrow_forward_ios` on 241
and 244. Every `chevron_right` becomes `chevron_left` — 243's three context rows, 246's note
row. Each list row's icon tile and label swap sides and the trailing value moves to the leading
edge. The eyebrow's 13×2 rule moves to the right of its label. Segment order reverses on 242,
244, 245 and 246, by the same mechanism and never by reversing a list by hand.

**Does not mirror.** The **vertical order** on all seven: what runs top to bottom in English
runs top to bottom in Persian. Artwork never mirrors — 242's album square is 74's square, `T`
and the Latin word `Art` included, per `AlbumDetailFa`'s first rule. **Stars never mirror**:
69's rule is that *"a five-star row read right to left puts the filled stars at the wrong end
of the scale, and a rating is a quantity rather than a sentence."* The **stepper column** on
245 and 246 stays symmetrical, so the numeral still aligns under itself as it grows a digit.
Times do not mirror — 72 settled it: *"the direction of time is not the direction of reading."*
246's `arrow_downward` keeps pointing down. Trade names stay Latin on 241, and country names on
247 keep their own scripts where the app has no Persian for them.

**The font rules, which are not optional.** Every Persian string takes `font_family="fa"`:
`kati_sans_400.ttf` carries **zero** code points in U+0600–U+06FF, and `Kati.PersianFontTest`
exists because the failure is invisible — Android substitutes its own Arabic face and the
sentence renders, *"Kati's Persian quietly set in somebody else's typeface, one paragraph at a
time."* And every numeral these boards set in DM Mono is set in Vazirmatn at the design's mono
size instead: `kati_mono.ttf` has none of U+06F0–U+06F9. Digits are Persian, dates are Shamsi,
the decimal separator is **U+066B** and the group separator **U+066C** — 127's caption: *"No
ASCII comma or dot anywhere."*

## Dark colourway

**No separate dark artboards, and the reason is checkable.** The scrim behind all five sheets is
`Kati.UI.Sheet.scrim/0` = `0x6B1A1917`, and its doc pins it: *"The same value in both modes. A
scrim is not a surface — it is the absence of one."* Everything else on these boards is
`Palette.paper()`, `card()`, `sub()`, `tertiary()` and `cream()`, all of which carry a real dark
column and swap with the mode on their own — `cream` moves `#FBF1DE` → `#2A2622`.

**One exception, and it is on 241.** `Kati.Theme.Palette` stores `:red` as
`{:red, 0xFFB4553C, 0xFFB4553C, :theme, …}` — byte-identical in both columns — while
`:green_text` beside it **steps**, `#3E8460` → `#4E9A73`. So the two rate colours in the same
price column move differently when the ground does: the green lightens and the red does not.
Draw that column once on dark ground as an inset on **241** and either confirm `#B4553C` holds
against `#121110` or name what replaces it. No new artboard number for it.

## Reuse, do not invent

- **The sheet frame** on 242, 243, 245, 246 and 247 is **72**'s: `0x6B1A1917` scrim, the 40pt
  paper strip behind the sheet's lowest edge (there is one `corner_radius` on the bridge, so
  the strip is what stops two wedges of scrim showing at the bottom), the paper sheet at radius
  26, `18px 21px 34px` padding, and the header row of *close disc · centred title · 36pt hole*.
- **The close disc** is `Kati.UI.Sheet.close_disc()`, unchanged — 72 reuses it directly.
- **The pushed frame** on 241 and 244 is `Kati.Screens.Fa.pushed_frame/2` plus
  `Kati.Screens.BookDetailFa.chrome/0`'s pill and `Kati.Screens.Fa.disc/2`'s 44pt disc, exactly
  as 127 draws them.
- **The segmented control** on 242, 244, 245 and 246 is 72's hand-rolled trough — same
  geometry, own `Text` — because the shared control paints its own label.
- **The stepper** on 245 and 246 is 72's field geometry; 111 already describes itself as *"70's
  field geometry adapted for a decimal."*
- **The list row** is `Kati.UI.SettingsList.row/4` at the house recipe, and a chevron still
  means *leads elsewhere*.
- **The service row, price and rate** on 241 are `Kati.Screens.MoneyFa.service_row/2` and
  `rate/2` as built, addressed by `Kati.Screens.Money.subscription_tag/1` — the mirror addresses
  its rows by the same names 122 does.
- **The suggestion card and its two buttons** on 241 are 127's, copy included.
- **The switch row and cadence group** on 244 are `Kati.Screens.SettingsFa`'s row rhythm, which
  already carries Persian consequence lines at Vazirmatn's line-height.
- **The star row** on 243 is `Kati.Screens.Rating`'s: `Kati.UI.symbol/2` per star, same size and
  family, sharing one line box.
- **The refusal** on all four writing sheets is **155**'s, and **71** is the precedent for
  drawing sheet states as one board rather than four.
- **The flag tile** on 247 is `Kati.Screens.MyServices.flag_tile/1` at 40pt radius 12, fed by
  `Kati.Services.flag/1`, which derives the emoji from the ISO code.

## What it must NOT do

- **It must not send a Persian reader to an English screen to finish a Persian gesture.** That
  is the whole ticket, and the codebase has already named the cost in six places.
  `Kati.Screens.AlbumDetailFa`: *"a push that changes the app's language out from under the
  reader, and RTL with it."* `Kati.Screens.Fa` records the same failure for the آمار tab's
  stand-in, and `Kati.FaShellRoutesTest` exists because *"a single tap on the dock changed the
  app's language and its direction, with no way back except Settings."*
- **It must not send them somewhere else instead.** `Kati.Screens.AlbumDetailFa`'s handler
  block is explicit: *"The four destinations are `Kati.Screens.AlbumDetail.handle_tap/2`'s,
  exactly — a mirror that navigated somewhere else would be a second app rather than the same
  one in another language."* `GoalsFa` says the same of screen 106: *"It is still the right
  destination — a mirror that made a goal somewhere else would be a second app."* So 241–247
  mirror their originals; they do not improve on them.
- **It must not draw a second rating sheet for books.** One `Kati.Screens.Rating` serves the
  film page, the book page and the album page today — `book_detail_fa.ex:646` and
  `album_detail_fa.ex:895` both push it, and so do their English twins. **243 is one board.**
  What 33's film-shaped context rows say when the parent is a book is a real question, and it
  is 33's inherited question, not a licence to draw two sheets.
- **It must not draw what the `more_horiz` discs open.** 23's own handler comment: *"23.html
  contains exactly one `more_horiz` and no menu, sheet or popover anywhere in the export, so
  there is nothing to open that would not be invented."* `Kati.UI.Menu` covers this for the
  whole app — *"Five of the 62 drawings put a `more_horiz` or a `density_medium` in a header
  and none of them draws what it opens"* — and it is not this ticket.
- **It must not decide what 243's three context rows and its `+ tag` ring open.** `D-36` owns
  all four, and its first open decision — push, or open in place — changes whether those rows
  carry chevrons at all. If D-36 has landed, follow it. If not, mirror 33 as drawn and note the
  dependency on the board.
- **It must not invent a `star_half`.** `Kati.Screens.Rating`: *"Kati's icon subset carries
  `star` and nothing called `star_half`, and `Kati.Icons.glyph!/1` raises for a name the font
  does not have."* The half slot is the same `star` at FILL 0, because *"a fifth filled star
  would read as five, and rounding a rating up silently is the one thing a screen that exists
  to record ratings must not do."*
- **It must not make 245's Shamsi arithmetic true by drawing it.** `Kati.Screens.GoalsFa`:
  *"Saying it is all a screen can do. Making it true means a Shamsi `period_phrase/1` and a
  Shamsi roll-forward for `repeat`, and both belong in `Kati.Goals` beside the dates they
  shape."* 245 draws `۱ فروردین` and the Shamsi period words; it does not pretend the periods
  already roll that way.
- **It must not draw a tick on بریتانیا on 247 as though picking it worked.**
  `Kati.Screens.MyServicesFa` states the cost of its own substitution: *"a Persian reader who
  deliberately picks the United Kingdom is shown ایران, because `Kati.Services` cannot
  currently tell a stored `"GB"` from an unset one. The upstream ask is one function — a
  `region_chosen?/0`, or a default that reads `Kati.Locale`."* The board records that; it does
  not paper over it.
- **It must not copy board 94's flag.** 94's Netherlands row is drawn with `&#127472;&#127469;`
  — U+1F1F0 U+1F1E9, **KH, Cambodia**. `Kati.Services.countries/0` holds `{"NL",
  "Netherlands"}` and `flag/1` derives the emoji from the code, so the app is right and the
  board is wrong. 247 draws 🇳🇱.
- **It must not claim 244 schedules anything.** `Kati.Screens.ReleaseWatcher`: *"Everything it
  draws is a preference, and Kati has no preferences resource… every control here edits one
  socket assign and forgets it on pop."* And 23's reminder button is the same:
  *"`Kati.Notifications.Scheduler` is a planned child of `Kati.Supervisor` (#59) and is not
  built, so `:remind` records that you asked and nothing more."*
- **It must not put a live figure beside an invented one on 244's banner.** 25 already refused
  this: `Watching 24 titles` *could* be real today, and is not taken, because *"counting it
  while the ten switches, the cadence and the `3 FOUND THIS WEEK` beside it stayed invented
  would make the card look live and be half made up."*
- **It must not give any of these seven a route argument.** Most detail screens in this app open
  generically. That is a code defect with its own history and no board fixes it. (**73 is one
  of the seven screens that does** take one — `mount/3` takes `%{album_id: id}` and every read
  on the sheet uses it — so 242 draws a sheet that is visibly *about* کارهای جزر و مد, which is
  a fact to honour, not a gap to file.)
- **It must not fold فهرست into this brief.** `album_detail_fa.ex:898` pushes
  `Kati.Screens.Lists` and 69 has the same button. That gap belongs to the Persian roots brief
  in this batch, which covers 57's three dead tiles and the same فهرست destination; drawing it
  twice is how two boards end up disagreeing.

## Left open — decide and note which way you went

- **What 241's and 244's back pills say.** Each is pushed from two places: 241 from 127 (پول)
  and from 97 (سرویس‌های من); 244 from 79 (هنرمند) and 127. The English boards each name one
  parent — 23 says *Stats*, 25 says *Settings* — and the label is static. 69 has a precedent for
  choosing under exactly this pressure: *"There is no Persian Books shelf in the 127, so the
  back pill names the shelf that exists."* Pick one word for each and say why on the board.
- **What 243's sheet says when the thing being rated is a book or an album.** 33 is titled *Log
  a watch* and carries a rewatch pill, a `tv Where` row and a `group With` row.
  `Kati.Media.Watch` models it column for column. None of that is a book. The English side has
  the same problem and has never had to look at it, because 33 is only ever *drawn* from a film.
  243 is drawn from 69 and 76 and cannot avoid it. Three roads: one sheet whose context rows
  vary by medium, one sheet that drops them for books and albums, or a title that stops saying
  *watch*. This is the largest decision in the ticket.
- **The paused row's date on 241.** 23 says *paused until October*. Shamsi October is مهر into
  آبان, and which one depends on the day nobody drew. Pick a Shamsi month, or reword the line
  as a duration.
- **244's weekly digest day.** 25 defaults to *Sundays at 18:00*. The Persian settings board
  (62) draws a **شروع هفته** row reading شنبه, so a Persian install whose week starts on
  Saturday and whose digest lands on Sunday is arguably shipping a UK default as a translation.
  Change it, keep it, or say why it is not a locale question.
- **246's unit words.** `kg` · `lb` · `st`. 115 writes کیلوگرم in full. Three full Persian words
  will not fit the segment trough at 34pt; three abbreviations have no settled Persian form; and
  **st** — stone — is a British unit a Persian reader may have no use for at all. Decide whether
  the Persian sheet carries two segments or three.
- **245's ten chip labels and 244's six row titles**, as Persian copy. Every one is a proposal
  and none has a Persian precedent in the built screens the way 108's goal titles do.
- **Whether 247's search field is drawn as a live filter or as a placeholder.**
  `MyServicesFa`'s moduledoc: *"The search field is drawn as a placeholder on both sheets and
  filters this list rather than opening a screen; the filtering is not built, so nothing is
  wired to it."* Seven rows do not need a filter; 190 do. Say which list the board is drawing.
- **Whether 241 keeps 23's `more_horiz` and 244 keeps 25's.** Both are inert in English —
  `{Kati.Screens.Subscriptions, :open_menu}` is on `Kati.ScreenTapSweepTest`'s Backlog at
  `test/kati/screen_tap_sweep_test.exs:716`. Mirroring them faithfully adds two more Backlog
  lines. Mirroring them away means two Persian boards that differ from their originals for a
  reason a reader cannot see.
- **Where 243's ذخیره pill goes under `rtl`.** The close disc takes the leading right edge, so
  the commit lands top-left — the position that is *back* on every other pushed Persian screen
  in the app. That collision is worth one sentence on the board either way.

## Acceptance — how we know it is complete enough to build from

1. **The crash is gone.** `grep -rn 'SubscriptionsFa' lib/ test/` returns a module definition
   and a `Kati.Screens.Gallery` entry — `{"241", "اشتراک‌ها", Kati.Screens.SubscriptionsFa,
   :push}` — not one dangling push at `money_fa.ex:1068`.
2. **`Kati.Screens.MoneyFa`'s moduledoc is true again.** It currently reads *"Three
   destinations, and only one of them leaves Persian… the service rows go to screen 97 rather
   than to 122's own `Kati.Screens.Subscriptions`"*, and the ledger rows have not gone to 97
   since they were given per-service tags — `:open_services` is now drawn by nothing
   (`money_fa.ex:556` and `:1053` are its only two mentions). 241 is what lets that paragraph be
   rewritten as fact rather than deleted as fiction.
3. **127 gains its fourth row.** `@services` at `money_fa.ex:238-242` gains an `"A"` key, and
   the paused Aria Audio row appears on 127 as well as on 241 — because the reason it is absent
   is that no drawing has ever shown it in Persian.
4. **Six moduledoc debts can be struck out**, by line: `album_detail_fa.ex:880-886` and `:894`,
   `book_detail_fa.ex:645-646`, `artist_detail_fa.ex:810-815`, `goals_fa.ex:906-913`,
   `health_fa.ex:1029-1033`, `my_services_fa.ex:125-133`. Each names a push that leaves Persian;
   each stops being true when its board lands. A reviewer can check all six with `grep`.
5. **Nine drawn controls stop being dead ends.** 69's `star امتیاز`; 76's `ثبت شنیدن` and `star
   امتیاز`; 79's `یادآوری کن`; 108's `add`; 115's `add`; 97's `کشور` row and its `payments`
   مالی row (both drawn with a `chevron_left` and no `on_tap` today, per `settings_fa.ex:446`'s
   rule that *"a row that lights up and goes nowhere is a worse promise than a row that does
   nothing"*); and 127's three ledger rows plus its reminder pill.
6. **`Kati.FaShellRoutesTest` can be widened from four screens to a rule.** It asserts today
   that the Persian dock's four roots are Persian; when these land it can assert that **no
   Persian screen pushes a module outside the Persian set**, which is the invariant this brief
   is really about.
7. **Each of the five sheets draws its own dismissal, and all five draw the same one** — close
   disc at the leading right edge, centred Vazirmatn title, 36pt hole — so `Kati.UI.Sheet` gains
   a Persian sibling rather than five hand-rolled headers.
8. **Every numeral on all seven boards is Persian, in Vazirmatn at the design's mono size**,
   with U+066B and U+066C and no ASCII separator anywhere — checkable by eye and, once built, by
   `Kati.PersianFontTest`, which is the test that caught four built screens still asking mono
   for glyphs it does not have.
9. **The refusal state is drawn once and cited three times**, in 155's shape, with a Persian
   sentence that wraps at Vazirmatn's line-height.
10. **242 is visibly about a named album**, with 76's five tracks and their play counts, not
    73's four — so the sheet a Persian reader opens from 76 is a sheet about the record they
    were looking at.
11. **247 ticks ایران and draws 🇳🇱**, and carries a note about what a deliberate pick of
    بریتانیا does today.
12. **Each *Left open* decision is recorded on the artboard it belongs to**, in the drawing's
    own annotation column, so the next reader does not re-derive it.

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
