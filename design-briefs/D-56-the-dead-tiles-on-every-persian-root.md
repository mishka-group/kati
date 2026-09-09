# The dead tiles on every Persian root

> **Mixed** · ticket `D-56`

One brief for six boards, because it is the same problem fourteen times, and `D-34` is the
model: **a control is drawn, it looks exactly like a working one, and there is nothing on
the other side of it.** Every Persian root is affected — 55, 56, 57, 59, 60 and 61 — and
the FAB is on all of them.

## The problem it solves, stated plainly

A Persian reader lands on خانه after their first run (`Kati.Onboarding.shell_root/1`
answers `Kati.Screens.HomeFa` for `:fa`) and starts touching things. The عادت‌ها tile does
nothing — `tag: nil` at `home_fa.ex:319`, left inert on purpose. On تقویم the seven day
cells do nothing, so only today can ever be seen, and none of the five event rows opens
anything: `grep 'tap' lib/kati/screens/schedule_fa.ex` returns four lines and `event_row/1`
at `:447` is not one of them. On کتابخانه the two shelf segments push a single book page
and a single album page instead of shelves, and the three quick tiles — one of them drawing
a **live ۱۲** read off the real shelf — have no `on_tap` at all (`quick_tile/1`,
`library_fa.ex:520-545`). On وعده‌ها the three meal cards and four quick tiles are dead
(`quick_tile(icon, label)` at `today_fa.ex:209` does not even take a tag), 60's edit disc is
`Fa.disc("edit")` with no tag, and 61 is missing the سلامت row `StatsFa` already renders.
And the one control that *is* wired on all six — the FAB — pushes
`Kati.Screens.AddTitle`, an English LTR page (`fa.ex:446-447`). Nothing about any of these
looks broken. They look finished, which is the whole complaint.

## Why this is one brief and not fourteen

Grouping them is not tidiness. They share **one decision the drawings have to make once**:
*what does an inert control on a Persian root look like while its mirror is pending?* And
this codebase has already rejected the obvious alternative, in writing, twice:

> عادت‌ها stays inert deliberately. There is no Persian habits screen in the 62, and
> pointing it at `Kati.Screens.Habits` is precisely the bug fixed in the آمار tab: one tap
> and the reader is in English, LTR, with no way back. An inert tile is visibly unfinished;
> a tile that changes the app's language is not.
>
> — `lib/kati/screens/home_fa.ex:313-317`

> A chevron row whose destination is not built stays inert — a row that lights up and goes
> nowhere is a worse promise than a row that does nothing.
>
> — `lib/kati/screens/settings_fa.ex:446-448`, and `my_services_fa.ex:125-133` follows it

So the answer is never *wire it to the English screen*. The answer is *draw the Persian
page*, fifteen times, and until then the control stays visibly unfinished. That decision is
made once here, in one place, rather than argued fifteen times in fifteen tickets.

**Two entries in the table are unlike the other twelve and are marked as such.**

## What to draw

Fifteen new artboards, **226–240**, and six edits to boards that already exist.

| # | Artboard | Carries | Reached from |
|---|---|---|---|
| **226** | **افزودن عنوان** — add a title, RTL | Mirror of 06. Search field, Everything/Films/Series segments, results list, and the *پیدایش نکردید؟ دستی اضافه کنید* row | **The FAB, on all six roots.** `Kati.Screens.Fa.dock_tap(:fab, …)` |
| **227** | **تازه‌ها** — new releases, RTL | Mirror of 05. Watcher card, *همین حالا* group, *به‌زودی* group with date chips | 55's `notifications` disc and its hero button باز کردن صندوق |
| **228** | **عادت‌ها** — habits, RTL | Mirror of 22. Streak rows with a seven-day tick strip and the consistency field | 55's third بخش‌ها tile (`bolt` / عادت‌ها) |
| **229** ✻ | **روز** — a heavy day, RTL | Mirror of 09. One Shamsi day, density rules, all-day band, clash lanes | **56's seven day cells** |
| **230** ✻ | **رویداد** — an event, RTL | Mirror of 31. Title, time, repeat rule, alerts, location, clash resolution | **56's five event rows** |
| **231** | **کتاب‌ها** — the Books shelf, RTL | Mirror of 20. Reading-now hero, count chips, pages-not-episodes progress | 57's کتاب‌ها segment (index 1) |
| **232** | **موسیقی** — the Music shelf, RTL | Mirror of 21. On-repeat row, listening time, new-from-artists | 57's موسیقی segment (index 2) |
| **233** | **بعدی** — up next, RTL | Mirror of 10. The queue, ordered by what is most finishable, plus گونه سرد | 57's `playlist_play` tile — **the one drawing a live count** |
| **234** | **کشف** — discover, RTL | Mirror of 11. For-you rows, people you follow, leaving-soon | 57's `explore` tile |
| **235** | **فهرست‌ها** — lists, RTL | Mirror of 12. Hand-made lists above app-kept ones | 57's `bookmarks` tile — **and** 69's and 76's `add_to_list` buttons |
| **236** | **فیلم** — film detail, RTL | Mirror of 08. Watched stamp, rating, cream note card, where-to-watch | 57's grid, for any tile whose kind is a film |
| **237** | **وعده** — a meal, RTL | Mirror of 45. Portion multiplier, macros, ingredients, method, history | 59's three meal cards |
| **238** | **خرید** — shopping, RTL | Mirror of 48. By-aisle grouping, basket ticks, per-line "which meals asked for it" | 59's `shopping_cart` tile |
| **239** | **تغذیه** — nutrition, RTL | Mirror of 47. Adherence first, macros vs target, consistency field | 59's `monitoring` tile |
| **240** | **برنامه‌ها** — plans, RTL | Mirror of 49. Active plan card, saved plans, scheduled switching | 59's `tune` tile **and 60's edit disc** — both land here |

✻ **229 and 230 are not translations.** They carry Shamsi dates and a Saturday-first week,
which is a calendar decision and not a mirroring one, and both depend on the answer given
in the settings brief — the one covering 62's تقویم / اعداد / شروع هفته rows. Draw them
after that decision, not before.

### The six edits

| Board | Edit | Why |
|---|---|---|
| **55** | Nothing new is drawn. Redraw as the record that عادت‌ها now leads somewhere | Only the destination was missing; the tile is already correct |
| **56** | Nothing new is drawn. Same — day cells and event rows now lead somewhere | The strip and the rows are already drawn correctly |
| **57** | Nothing new is drawn. The two segments now open shelves, the three tiles open pages | The tiles already carry their counts |
| **59** | Nothing new is drawn. Three meal cards and three of four quick tiles now lead somewhere. **The fourth, هفته, already has a Persian destination — board 60** | 60 exists; only the wire is missing, which is a code fix, not a design one |
| **60** | Nothing new is drawn. The edit disc opens 240, exactly as 44's edit disc opens 49 | `meal_plan.ex:822-823` pushes `Kati.Screens.Plans` from the same control |
| **61** ✻✻ | **Add one row under اعداد بیشتر**: `monitor_weight` / **سلامت** / ۷۶٫۰ کیلوگرم / `chevron_left` | **No new board.** Screen 115 is built and drawn; only its door is missing |

✻✻ **61 is the D-34 case exactly** — a built, drawn Persian page with no control that
opens it. `Kati.Screens.StatsFa.more_numbers/0` (`stats_fa.ex:80-97`) already renders three
rows; the extracted text of `test/design/screens/61.html` under اعداد بیشتر is exactly
`checklist اهداف ۳ هدف فعال chevron_left payments پول ۴۶٫۴۷ پوند در ماه chevron_left`. The
board is one row behind the screen. And the row has to stay: the four Persian roots are
خانه, تقویم, کتابخانه and آمار — `Kati.Screens.Fa.roots/0` — and **not one of them is a
health hub**, so this row is the only Persian route to health that exists.

## Every element, and the glyph it takes

Material Symbols Rounded throughout, and every name below is one the app already ships
through `mix kati.gen.icons`.

**226 افزودن عنوان** — sheet chrome: `close` at the trailing edge, not a back pill (06 is a
sheet). Search field with `search`; a `cancel` clear when it has text. Segments
همه / فیلم‌ها / سریال‌ها on the `#E4E0D9` trough. Result rows, each with an `add` disc.
Under the list, the bordered row `edit_note` + **پیدایش نکردید؟ دستی اضافه کنید**. That row
is the point of the board: `Kati.Screens.AddByHand.for_locale/0` already answers
`AddByHandFa` for `:fa`, so **screen 156 is Persian and reachable only through an English
page** — and 156's own back pill reads «افزودن عنوان» (`add_by_hand_fa.ex:116`), naming a
parent that does not exist. 226 is that parent.

**227 تازه‌ها** — back pill به خانه; a *همه را خوانده‌ام* pill. Watcher card with
`auto_awesome`, its own `settings` disc. **همین حالا** group: poster row per release with a
تماشا pill. **به‌زودی** group: a two-line date chip (Shamsi month abbreviation over a
Persian day number), title, service, and a bell that is `notifications_active` when armed
and `notifications` when not.

**228 عادت‌ها** — back pill به آمار, an `add` disc. One card per habit: name, streak count,
a seven-across tick strip of `check` marks under **ش ی د س چ پ ج**, and a broken habit
drawn with its strip short rather than with a red mark. Consistency card reuses 61's pixel
field.

**229 روز** — back pill به تقویم; `density_medium` for the density control. Header: Shamsi
weekday and date, item count, clash count. Filter chips نمایش / شخصی / مالی with counts.
A **تمام‌روز** band for untimed releases. Then the timeline: 44pt time gutter at the
*right*, `check_circle` for a kept habit, `radio_button_unchecked` for a reminder,
`payments` behind a 26pt glyph tile for money, `call_split` above a split lane, `expand_more`
on a grouped card, `+n` on the overflow tile.

**230 رویداد** — sheet chrome: `close`, and a ذخیره commit. Fields, each with its glyph:
`label` for the category, `schedule` for the time, `public` for the timezone, `repeat` for
the recurrence, `notifications` for alerts, `place` for the location, `chevron_left` on
every row that pushes. Clash card with `call_split` and three one-tap resolutions. Invitees
with `check_circle` / `schedule` per reply and an `add` row. `delete` at the foot.

**231 کتاب‌ها / 232 موسیقی** — both are 57's page with its own hero. Header discs `search`
and `sort`; segments `movie` نمایش / `menu_book` کتاب‌ها / `graphic_eq` موسیقی, with the
current shelf lit. 231's hero: current book, `p. ۲۱۴ / ۳۸۰`, a ثبت پیشرفت pill and a
`timer` shortcut. 232's hero: on-repeat rows with play counts. Both then take the count
chips and the three-across poster grid unchanged.

**233 بعدی** — back pill به کتابخانه, a `tune` disc. Hero: next episode, a *آماده تماشا*
group of rows each with `play_arrow`, and a **گونه سرد** group whose rows offer رها کردن
rather than sitting in the queue.

**234 کشف** — back pill به کتابخانه, `tune` disc. Segments برای شما / افراد / در حال حذف /
جوایز. Match rows with a percentage; people rows with a `check` when nothing is new;
leaving rows with a برنامه‌ریزی pill.

**235 فهرست‌ها** — back pill به کتابخانه, an `add` disc. Hand-made lists first with
`chevron_left`; then **به‌طور خودکار نگه‌داشته‌شده**: `bookmark` آرزو, `replay` بازتماشا,
`do_not_disturb_on` رهاشده, `inventory_2` مالکیت فیزیکی — each with a Persian count and
`chevron_left`.

**236 فیلم** — back pill به کتابخانه, `more_horiz`. `check_circle` + دیده شده stamp, title,
year, runtime, genre eyebrow. Rating stars. **Note on cream** with an `edit` affordance —
cream is the one place the palette warms up. کجا ببینیم rows. Action row: `replay` ثبت
بازتماشا, `event` برنامه‌ریزی, `ios_share` هم‌رسانی.

**237 وعده** — back pill به وعده‌ها, `more_horiz`. Slot, time, name. Portion stepper
`remove` / ۱.۰× / `add` that rescales every figure on the page. Macro bar and figures.
`check` خوردم, `swap_horiz` جایگزین, `bookmark`. Ingredients, each with weight and calories.
Method with `schedule`, `local_fire_department`, `restaurant`. History rows: `event_repeat`,
`star`, `sticky_note_2`, each with `chevron_left`.

**238 خرید** — back pill به وعده‌ها, `more_horiz`. Segments بر اساس راهرو / بر اساس وعده /
فقط کمبودها. Aisle headings, then rows with a `check` box, the item, *which* meals asked for
it, and the quantity. Foot: `ios_share` ارسال فهرست and an `add`.

**239 تغذیه** — back pill به وعده‌ها, `ios_share`. Segments هفته / ماه / همه. Daily average
against target. Seven-across day strip. **پایبندی leads**, not calories. Macros-vs-target
bars each with a target line. Consistency pixel field. A cream `lightbulb` card for what the
data says.

**240 برنامه‌ها** — back pill به وعده‌ها, an `add` disc. Active plan card with `more_horiz`.
Saved plans, each with a فعال‌سازی pill. Switching card: `event_upcoming`, `history`,
`auto_mode`, and an `info` note.

**61's new row** — `monitor_weight` in the 30×30 paper tile, **سلامت**, second line
۷۶٫۰ کیلوگرم, trailing `chevron_left`. `monitor_weight` is the glyph 110's board already
uses for this page.

## States to draw

Kati's sweeps compare an empty state against a board, so **an undrawn empty state becomes an
untested one** — `Kati.ScreenEmptyDatabaseTest` reads these files with nothing stored.

- **Resting** — all fifteen, light, RTL. This is the baseline `Kati.ScreenDesignLiteralTest`
  asserts every literal and every symbol against.
- **Active** — only where a control changes the page: 231/232's lit segment, 234's and
  238's and 239's selected segment, 229's selected day, 237's stepper at a value other than
  ۱.۰×. Draw the resting member of each family too: `screen_tap_sweep_test.exs` already
  carries `{Kati.Screens.LibraryFa, :shelf_0}` and `{Kati.Screens.MealsMatrixFa, :view_0}`
  as *inert because already selected*, and a new segmented control adds one more such line.
- **Empty** — the four that can genuinely be empty on a fresh install, and they must each be
  drawn: **233** (nothing part-watched), **235** (no hand-made lists, but the four
  auto-kept ones still present at zero), **238** (no plan, so no list to sum) and **227**
  (the watcher running and nothing out yet). 231/232/234/236/237/239/240 fall back to their
  drawing rather than branching — that is `LibraryFa`'s rule, *"missing data is not a reason
  for a blank screen"*, and it is why 57 has no empty twin either.
- **Error** — one only, and it is real: **230**'s clash card. It is the sole surface in this
  set where the app tells the reader something is wrong rather than absent. There is no
  network error state to draw; nothing in this set fetches.

## RTL

Every one of the fifteen **is** the Persian mirror — that is what the ticket is — so the
question is not *does it need one*, it is *what does not come free*.

- **Free**: the whole grid. A `Row` lays out start-to-end, so the time gutter lands at the
  right, the dock's home tab is rightmost, the FAB is at the left, and progress fills from
  the right. Nothing is reversed by hand anywhere in the Persian screens and nothing should
  be drawn as if it were.
- **Never mirrors**: **artwork**. A poster is a photograph and a mirrored photograph is a
  different picture — `library_fa.ex`'s moduledoc says so, and 57's own caption repeats it.
  Star glyphs on 236 do not mirror either.
- **Never reverses**: the **vertical order**. Bands run top to bottom in the same sequence as
  the English board. 229's timeline still runs earliest at the top.
- **Flips**: the back pill's glyph, `arrow_back_ios_new` → **`arrow_forward_ios`**, on all
  thirteen pushed boards. Chevrons become `chevron_left`. 226 and 230 are sheets and take
  `close` instead, which does not flip.
- **Restarts rather than mirrors**: the week. 229's day strip begins at **شنبه** and 228's
  tick strip runs **ش ی د س چ پ ج**. `ScheduleFa`'s moduledoc: *"شنبه is the first column,
  not Monday moved to the right."* Mirroring a Monday-first strip gives a table that is
  confidently wrong rather than obviously wrong.
- **Not mirroring at all, but calendar**: dates on 227, 229, 230, 237, 238 and 239 are
  Shamsi, and digits are Persian.

## Dark colourway

**Not needed for these fifteen, and drawing them would be the wrong work.** Kati's dark
mode is a token swap, not a second design: ground `#121110`, card `#1E1D1B`, ink `#F5F2EE`,
and `Kati.Theme.PaletteTest` and `Kati.ThemeModeTest` hold both columns as literals so a
moved value fails by token name. No board in this set introduces a colour that is not
already in the table below. The two exceptions worth a designer's eye are **236's cream note
card** and **239's cream lightbulb card** — cream is the one warm surface in the palette,
and if it needs a dark counterpart that is one decision about the token, not fifteen
drawings. Note the answer in the brief rather than producing dark twins.

## Reuse, do not invent

Not one of these fifteen is a new visual language. Each is an existing English board redrawn
in a Persian frame, plus the recipes already listed at the foot of this file.

- **The frame** — `Kati.Screens.Fa.frame/3`. Root boards (none here) close at 132; all
  fifteen of these are pushed or sheets and close at **40**.
- **The back pill** — 58's, 59's and 60's, not `Kati.Screens.Pushed`'s: it is the first item
  in the scrolling column with its chevron already pointing right.
- **The header disc** — `Kati.Screens.Fa.disc/2`, the 44pt card-white circle with
  `Kati.Theme.shadow_button/0`. Note that `disc/1` *with no tag* is a real, drawn, dead disc
  and four screens use it today; do not draw a new one.
- **The segmented trough** — 57's `#E4E0D9`, for 231, 232, 234, 238, 239.
- **The quick tile** — 57's and 59's, for 233/234/235 and 238/239/240 alike.
- **The meal card's three states** — 59 already draws next / skipped / settled; 237 is what
  one of them opens and takes its geometry from the card that opened it.
- **The tick strip and the pixel field** — 22's and 61's are the same field. 228 and 239
  both reuse it; a good week must look the same everywhere.
- **The settings row** — `Kati.UI.SettingsList.row/2` with `icon_tile/1`, which is what 61's
  new سلامت row already renders through.
- **The eyebrow** — Persian takes `Kati.Screens.Fa.eyebrow/1`: Vazirmatn 11/600, **no
  tracking**, not `Kati.UI.eyebrow/2` with a translated label. Persian has no case to raise.

## What it must NOT do

Each of these is a decision the codebase has already made, in a moduledoc, against the
obvious alternative.

**Do not route any of these controls to an English screen instead of drawing the board.**
This is the whole ticket, and it has been argued and settled three times — `home_fa.ex:313-317`
and `settings_fa.ex:446-448` quoted above, plus:

> A row here that pushed an English screen would change the app's language out from under
> the reader — `Kati.Screens.Fa`'s moduledoc records that failure for the آمار tab's own
> stand-in — so Activity, Habits, Nutrition and Recently watched are absent rather than
> linked, and they arrive the day their mirrors do.
>
> — `lib/kati/screens/stats_fa.ex:80-97`

So **61's edit adds exactly one row**, سلامت, and not four. عادت‌ها and تغذیه become
candidates for that list the day 228 and 239 are drawn, and not before.

**Do not set any Persian numeral in DM Mono.** The house-style block at the foot of this
file is reproduced verbatim and its RTL line says dates and digits go "both in DM Mono so
columns still align". That line is now overruled by the font that actually ships:

> `kati_mono.ttf` contains **zero** of U+06F0–U+06F9; Vazirmatn carries all ten. So anything
> numeric that the design sets in mono is set here in `fa` at the design's size and colour.
>
> — `lib/kati/screens/fa.ex` moduledoc, enforced by `Kati.PersianFontTest`

Draw the mono if you like — 115's caption does — but **nothing on these boards may depend on
monospaced Persian digits for its alignment**: not 229's time gutter, not 237's ingredient
calorie column, not 238's quantities, not 239's macro figures. Give each a declared column
width instead.

**Do not draw a dashed rule.** `Modifier.border` through this bridge takes a width and a
colour and no dash pattern, which is why 59's skipped meal and 60's open cell are both drawn
solid. 238's unticked rows and 240's inactive plans must not ask for one.

**Do not put a "mark done" control on 230.** An event cannot be ticked:

> `Kati.Calendars.Override.kind` is `:modified | :cancelled` — an occurrence can be called
> off and cannot be ticked … A row that is not imminent therefore settles onto the flat card
> with a hollow ring, which asserts nothing about whether it happened.
>
> — `lib/kati/screens/schedule_fa.ex` moduledoc

Modify and cancel are the two verbs. 229 must likewise never draw a day it has no events
for as though it had them: *"no other day may be dressed up with events that are not there."*

**Do not give 229 or 230 a poster.** `Kati.Calendars.Today` carries a time, a summary and a
composed meta line and nothing else, so the feature card with its poster and cream pill
belongs to 56's drawn day only. A real air date on 229 draws as an ordinary row with the
accent rule — *"the same fact, minus artwork nothing can supply."*

**Do not put فصل ۲ · ۵ از ۷ under a poster on 231, 232 or 236.**

> no season and no episode total reach this shelf shape, so the drawing's own second line
> stays what it always was, copy on `Sample`, and a real row says شروع نشده, تمام‌شده or
> ۳۷ درصد دیده شده instead.
>
> — `lib/kati/screens/library_fa.ex` moduledoc

231's unit is **pages**, not episodes, and 232's shelf has no progress at all.

**Do not invent Persian copy a designer never wrote for a control that only narrows a view.**

> **No new copy.** A mirror screen exists to be compared against its drawing, so a segment
> may only re-read `Kati.Fa.SampleWeek` — it may not invent Persian a designer never wrote.
>
> — `lib/kati/screens/meals_matrix_fa.ex` moduledoc

**Do not key any of these new controls on their Persian label.** The English twin already
paid for this lesson: *"Keying on the label would wire four live controls in English and four
dead ones in every other locale, and the failure would be invisible — an unknown key yields
no `on_tap`, and a Box with no `on_tap` is drawn exactly like one that has it"*
(`meals_today.ex:632-635`). The Persian screens hold segments and chips as an **index**, and
posters as `open_film_` / `open_series_` plus the title. Draw controls whose identity is
ordinal or an untranslated icon name, never a right-to-left string.

**Do not file "most detail screens open generically" here.** Only 7 of 62 screens read a
route argument, so 236 opened from any tile will show one film. That is a code defect and
belongs in code; it is not a reason to draw fifteen boards differently.

## Left open — decide and note which way you went

- **229 and 230 wait on the settings brief.** Whether the day strip is Shamsi-only or
  follows 62's تقویم row, whether numerals follow 62's اعداد row, and whether شنبه is fixed
  or follows شروع هفته. All three change what these two boards draw. If the settings brief
  answers *the calendar is a setting*, then 229 needs a second state and 230 needs a Shamsi
  and a Gregorian date row.
- **Does 236 replace 57's series destination or join it?** `LibraryFa.shaped/1` drops
  `:kind` (`library_fa.ex:166-174`) where `Library.shaped/3` keeps it
  (`library.ex:229-237`), so today every tile — films included — opens 58. Whether the
  Persian grid grows a kind marker the way the English one does, or films are simply routed
  by the data already on the row, is a design call about what a tile shows.
- **Whether 61 grows more rows later.** Once 228 and 239 exist, عادت‌ها and تغذیه qualify
  for اعداد بیشتر by `StatsFa`'s own rule. Four rows may be one too many for the card. Say
  which three you would keep.
- **Whether 235 is one board or two.** 12's caption says *"the same shell will hold book and
  album lists"*, and 235 is pointed at by 69's and 76's `add_to_list` as well as 57's tile.
  One shell with a kind, or a کتاب shelf-specific variant.
- **The empty state for 233.** A queue with nothing in it is either the app's saddest screen
  or its most honest onboarding surface. 10 does not draw one.
- **240's relationship to 60.** Both the تغذیه-neighbour tile on 59 and the edit disc on 60
  land here. If 240 should open in an *editing* state when reached from 60's disc and a
  *browsing* state when reached from 59's tile, that is two drawings, not one.
- **Whether 226 keeps 06's sheet chrome or becomes a pushed screen.** It is reached from the
  FAB on six roots, and 156 — already built — pops back to it with a **back pill**, not a
  close button. One of the two has to give.

## Acceptance — how we know it is complete enough to build from

1. **Fifteen artboards numbered 226–240 exist**, each 402×874, each `dir="rtl"`, each with
   the same caption line the Persian boards carry naming what mirroring did *not* do.
2. **Every string on every board is Persian**, including every numeral. A Latin digit
   anywhere in the set is a bug `Kati.PersianFontTest` will not catch because it checks the
   face, not the glyph.
3. **Every glyph on every board is a Material Symbols Rounded name that already appears in
   `test/design/screens/`**, or is listed separately as a new symbol so
   `mix kati.gen.icons` can be run against it. A new symbol that nobody flags is a blank
   square on the device.
4. **Board 61 is redrawn with three rows under اعداد بیشتر**, and the third reads
   `monitor_weight` · سلامت · ۷۶٫۰ کیلوگرم · `chevron_left`. This one is checkable by
   diffing the board's extracted text against `Kati.Screens.StatsFa.more_numbers/0`.
5. **Boards 55, 56, 57, 59 and 60 are redrawn with no new ink** — the edit is the record
   that their controls now lead somewhere, so a diff of extracted text against the current
   files should be empty. If it is not, the redraw changed something it was not asked to.
6. **The four empty states named above are drawn**, because `Kati.ScreenEmptyDatabaseTest`
   will assert against them whether or not they exist.
7. **229 and 230 are either drawn against a settled calendar decision, or held back and
   said to be held back.** Half-drawing them is worse than not drawing them.
8. Every board can answer: *which control on which existing board opens me, and what does
   my back pill say?* If a board cannot, it is a screen with no door, which is the exact
   thing `D-34` exists to stop.

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
