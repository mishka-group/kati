# Kati — Design Index

Source: `/Users/shahryar/Documents/Personal app with media library/Kati.dc.html`
(825 KB, 3371 lines, Claude Design "screen shelf" canvas export — inline styles only, no CSS classes.)

Header text: *"Kati — Personal OS · v0.1 · Screen shelf … One warm surface for everything you keep track of. The calendar is the spine that every section feeds into — **62 screens in fourteen groups** — navigated by four fixed roots."*

Each screen is a `<div style="width:402px" data-screen-label="NN">` containing a
`<x-import component-from-global-scope="IOSDevice" from="./ios-frame.jsx" hint-size="402px,874px">` —
i.e. **402 × 874 pt iPhone frames**. Screen body is always
`<div style="position:relative;height:100%;background:#EFECE7;overflow:hidden">` wrapping a scroller
`<div style="height:100%;overflow:auto;padding:64px 21px 132px">` (64 pt top safe area, 21 pt gutters,
132 pt bottom inset for the floating tab bar; non-tabbed screens use `padding:64px 21px 40px`).

Screens are **live prototypes**, not static art: the file ends with a `class Component extends DCLogic`
block holding `state = { watched: {...}, libTab: null, added: {} }`, `toggleEp(n)`, `markNext()` and a
`renderVals()` that derives every `{{ mustache }}` binding on screens 02/03/04/06.

---

## 1. Navigation model

### The four fixed roots

Quoted from the "How you move around" map: *"Four roots that never change. Sections add shelves and
feeds, never tabs — which is why the map stays this size no matter how much you add."*

| Root | Icon (Material Symbols Rounded) | Strapline | Screens beneath it |
|---|---|---|---|
| **Home** | `home` | "Today, across every section" | 01 Dashboard*, 05 New releases inbox, 19 Search everything, 42 Health hub, 24 Settings, 28 Dark home* |
| **Calendar** | `calendar_month` | "Time, across every section" | 02 Day*, 17 Week*, 16 Month*, 30 Agenda*, 09 A heavy day, 52 Meals on the calendar, 31 Event detail (modal), 18 Quick add (modal) |
| **Library** | `grid_view` | "The shelves — one per section" | 03 Screen shelf*, 20 Books shelf*, 21 Music shelf*, 10 Up next, 11 Discover, 12 Lists, 13 What fits tonight, 04 Series, 08 Film, 14 Full metadata, 06 Add a title (modal), 33 Rating & review (modal) |
| **Stats** | `bar_chart_4_bars` | "Numbers, across every section" | 07 Your year*, 15 Activity log, 22 Habits, 47 Nutrition, 23 Subscriptions |

`*` = the map's orange dot, legend **"A view of its root"** — same root, different mode, tab bar visible.
Black dot = **"Root or pushed screen"**. Grey `#C4BDB3` dot = **"Modal — closes, never pushes"**.

Secondary clusters listed as chip rows under the map (all pushed, no tab bar):

- **Series →** 34 Episode order, 35 Show settings
- **Health →** 43 Meals today, 44 The week, 45 Meal detail, 46 Swap a meal, 48 Shopping list, 49 Plans, 50 Share a plan, 51 Reminders
- **Settings →** 25 Release watcher, 32 Connect calendars, 36 Auto-detect, 37 Import, 39 Widgets, 40 Account, 41 Accessibility, 27 States
- **Outside the app** 26 Onboarding 2, 38 Onboarding 1/3/4, 29 Lock screen

### The three stated rules (verbatim from the map footer)

1. **"Back always says where"** — *"Every pushed screen carries a labelled pill — '‹ Library', '‹ Meals' — so you never tap into the dark."* (icon `arrow_back_ios_new`, orange accent)
2. **"One title style"** — *"Large title, left-aligned, on every screen. Centred titles are reserved for modals, which close rather than go back."*
3. **"The bar means root"** — *"A screen shows the tab bar only if it is one of the four roots. If you can see the bar, you are home free."*

### Stack / modal / tab mechanics as actually drawn

- **Tab bar** (14 screens: 01, 02, 03, 07, 16, 17, 20, 21, 28, 30, and RTL 55, 56, 57, 61) is a floating
  pill, *not* a docked bar: `flex:1;height:64px;border-radius:32px;background:rgba(251,250,248,.9);
  backdrop-filter:blur(20px)` with four 46 pt icon slots, plus a **separate detached 64 × 64 ink FAB**
  (`background:#1A1917;border-radius:32px`, icon `add`) sitting beside it. The active tab is a filled
  `#EFECE7` circle with `font-variation-settings:'FILL' 1`; inactive icons are `#B3ACA2`.
  A 120 pt `linear-gradient(to top,rgba(239,236,231,1) 42%,rgba(239,236,231,0))` scrim fades content
  behind it (`pointer-events:none;z-index:20`).
- **Back pill** = `arrow_back_ios_new` + parent name. Observed labels: `‹ Home` (05, 19, 24, 42),
  `‹ Library` (04, 08, 10, 11, 12, 13, 14), `‹ Calendar` (09, 52), `‹ Stats` (15, 22, 23),
  `‹ Settings` (25, 27, 32, 36, 37, 39, 40, 41, 54), `‹ Series` (34, 35), `‹ Health` (43),
  `‹ Meals` (44, 45, 47, 48, 49, 51), `‹ Plans` (50). Nesting therefore goes up to 4 deep
  (Home → Health → Meals → Plans → Share a plan).
- **Modals** (5): 06 Add a title, 18 Quick add, 31 Event detail & edit, 33 Rating & review, 46 Swap a
  meal. All use a centred title with a leading `close` glyph; 31 and 33 add a trailing text action
  ("Save"). No modal shows a tab bar or a back pill.
- **Chromeless surfaces** (no nav at all): 26 + 38 onboarding, 29 lock screen, 53 language picker.
- **Deep links / cross-root jumps** drawn explicitly: home's *"Open inbox →"* → 05; home Sections tiles
  → Meals/Habits/Settings; 07 "More numbers" rows → 15/22/47/23; 05 gear → 25; 42 Health tiles →
  43 and the not-yet-built Sleep/Weight/Workouts/Medication; 43 toolbar chips → 44/48/47/49;
  19 search results deep-link into Screen, Calendar and Notes results in one list; 39 share sheet
  ("Save to Kati … from any app, link or screenshot") and Siri shortcuts ("Hey Siri, what's next?")
  are external entry points.
- **Back never has a hardware assumption**: RTL screens 58/59/60/62 swap the glyph to
  `arrow_forward_ios` — *"back is always 'the way you came from', which in RTL is the right edge."*

---

## 2. Screen catalogue (62)

### Group A — "The core" (*"Home, the calendar spine, the shelf, and the two detail screens everything else hangs off."*)

| # | Title | Purpose | Nav |
|---|---|---|---|
| 01 | Home | Root dashboard: greeting ("Sunday · 16 August / Good evening"), search field, the fixed hero **"New this week / 3 new episodes are waiting"**, Continue watching rail, Sections grid, "Rest of today" timeline. | Root. → 05 (Open inbox), 19 (search), 43/22/24 (Sections), 02 (See all) |
| 02 | Schedule | Calendar Day view: month header, 7-day strip, section filter chips (All/Screen/Personal/Money), time-gutter list mixing air dates, appointments, habits and renewals. | Calendar root. → 31, 09, 16/17/30 |
| 03 | Library | Shelf root: shelf switcher (Screen/Books/Music), Up next / Discover / Lists tiles, filter tabs (All 9 / Watching 4 / Finished 3 / Wishlist 2), poster grid. Filters are live. | Library root. → 04, 08, 10, 11, 12, 20, 21 |
| 04 | Series & episode tracker | Title detail with hero still, season progress bar, "Mark E6 watched" primary, season tabs S1–S3, tappable episode rows. Interactive: ticking updates bar, button label and next-up count. | ← Library. → 14, 34, 35, 33 |
| 05 | New releases inbox | Watcher results stacked: "3 out now · 3 coming up", "Watching for 24 titles · last checked 18:02 · every 6h", Out-now rows with Watch buttons, Coming-up date rows with bell toggles. | ← Home. → 25 (gear) |
| 06 | Add a title | Modal search-to-add sheet: query chip, type tabs (Everything/Films/Series), 4 results with add/check buttons, "Can't find it? Add it by hand". | Modal from FAB. Closes. |
| 07 | History & stats | Stats root "Your year": 312h 40m headline with +18% delta, 104-cell pixel field, 84/19/4.1 stat trio, genre bars, "More numbers" rows, Recently watched rail. | Stats root. → 15, 22, 47, 23 |
| 08 | Film detail | Film card: "Watched 12 Aug" badge, star rating, seen-count, cream note card, "Where to watch" provider rows, actions Log rewatch / Schedule / Share. | ← Library. → 33, 18 |
| 09 | A heavy day · density rules | Reference day (14 items, 2 clashes) demonstrating: sequential cards, `2 at once` split lanes capped at two columns with a `+1 MORE` tile, 3+ same-kind grouped cards with poster stacks, an all-day band, merged money events. | ← Calendar. → 31 |
| **B** | **"The watching loop"** | *"The four screens that turn a library into a habit."* | |
| 10 | Up next | Global queue "12 ready · 4 airing soon", hero next episode, Ready-to-watch rows with play buttons, "Gone cold · 3" section offering a **Drop** action. | ← Library. → 04 |
| 11 | Discover | Recommendations from own history: tabs For you / People / Leaving 5 / Awards; "Because you watched…" with % match; followed people; "Leaving Lumen+ in 7 days" with Schedule buttons. | ← Library. → 04/08, 18 |
| 12 | Lists & collections | "7 lists · 2 ranked": hand-made list cards with 3-poster stacks and ranked/shared badges, then "Kept automatically" (Wishlist 12, Rewatches 9, Abandoned 3, Owned on disc 22). | ← Library |
| 13 | What fits tonight | Runtime-aware picker: "Time you have 45 min" chips (20m/30m/45m/1h/2h+), mood chips, "3 episodes fit", and a "Nothing else fits — nearest film is 1h 46m" over-budget card. | ← Library. → 04 |
| **C** | **"Depth on a title"** | *"Full metadata without losing the calm."* | |
| 14 | Series — full metadata | Three ratings side by side (Yours ★4.5 / Audience 8.1 / Critics 96%), synopsis with "more", Trailer button, cast rail, "Where to watch" incl. own Blu-ray shelf, user tags + "+ tag". | ← Library |
| 15 | Activity & rewatch log | Append-only history, 1,204 entries: filter tabs All/Watched/Rated/Added, timestamped rows (Watched, Rated, Added, Rewatched, Finished, Dropped, Imported), rewatch counts. Doubles as the undo trail. | ← Stats |
| **D** | **"Calendar, properly"** | *"Month reads as a load map, week as proportional lanes, and one natural-language field files anything into any section."* | |
| 16 | Calendar — month | 6×7 grid with per-section dots, filled card on the heaviest day, view switcher Day/Week/Month/Agenda, selected day's clashes summarised beneath. | Calendar root view. → 09, 31 |
| 17 | Calendar — week | Seven nameless lanes; block height = duration, colour = section. Tapped day's names listed below; "Load this week" bar; "Thursday is carrying 9 items. Two things could move to Friday." | Calendar root view. → 09 |
| 18 | Quick add | Modal NL parser: "dentist thu 11am for 45m, remind 1h before" with tokens highlighted in place, "Kati read that as" preview card, clash warning *before* save, "Or file it as" type chips (Event/Reminder/Title/Habit/Note/Expense), mic button. | Modal. Closes. |
| **E** | **"Finding things, and more shelves"** | | |
| 19 | Search everything | One query across sections: scope tabs (All 6, Screen 3, Calendar 2, Notes 1), grouped results with the match highlighted, "Recent" history chips. | ← Home. → any detail |
| 20 | Books shelf | Second shelf from identical parts: "64 books · 2 reading", Reading-now hero with "p. 214 / 380 · 23 min/day pace", filter tabs, cover grid with page progress. | Library root view |
| 21 | Music shelf | Third shelf: "418 albums · 61h this year", On-repeat-this-week rail with play counts, Listening-time card, "New from artists you follow". | Library root view |
| **F** | **"The rest of your life"** | *"…and the one insight only this app can produce: cost per watched hour."* | |
| 22 | Habits & streaks | 4 habits with 7-day check rows and streak counts (12 days / 5 days / 2 days / **broken**), plus a 13-week consistency pixel field, "84% of days hit". | ← Stats |
| 23 | Subscriptions | "£46.47 a month", up-£4.00 delta, per-service rows with renew date, hours watched and **£/h** (Lumen+ £0.21/h, Orbit £2.33/h), a paused service, and a "Worth a look" advice card with Remind me / Dismiss. | ← Stats |
| **G** | **"System"** | *"Settings, the watcher's manners, the first run, and the states nobody designs."* | |
| 24 | Settings | Account card, Appearance (Theme Auto/Light/Dark segmented, Text size "up to 235%", Reduce motion), **Sections** list declaring which surfaces each section appears on, Reorder sections (drag), Data (Import/Export/Sync/Clear), About. | ← Home. → 25, 27, 32, 36, 37, 39, 40, 41, 54 |
| 25 | Release watcher | "Watching 24 titles · 3 found this week"; six alert-type toggles; frequency segmented (Hourly/Every 6h/Daily/Manual); "How loudly" rows — push off by default, inbox badge, quiet hours 23:00–08:00, weekly digest. | ← Settings |
| 26 | Onboarding — pick sections | "What should Kati keep?" — six section tiles, pick two to start, "Continue with 2", "Import from a backup instead". | Chromeless. → 38 |
| 27 | Empty, loading, offline | **States reference sheet**: empty state, skeleton rows, offline badge, error card with Retry, undo bar. (See §4.) | ← Settings |
| **H** | **"Dark & off-app"** | | |
| 28 | Dark — home | Screen 01 at night. *"Dark is not an inversion. Paper becomes near-black, cards lift with a hairline instead of a shadow, and the cream card warms to a lit-lamp brown."* | Home root (dark) |
| 29 | Lock screen & widgets | Wallpaper + clock 21:40, three glass widgets (UP NEXT poster, TONIGHT "6 episodes airing", TODAY · 4 LEFT list) and a THIS YEAR pixel-field widget. *"The glass treatment is the only place the app borrows from the OS."* | Off-app |
| **I** | **"Calendar, completed"** | | |
| 30 | Calendar — agenda | Fourth view mode; skips empty days entirely, date kickers only where something exists, gaps stated ("Nothing else until 12 Sep"). | Calendar root view |
| 31 | Event detail & edit | Modal editor: title, section chips, time/duration, **timezone "Europe/London · follows travel"**, recurrence "Every 2 weeks on Thursday", alerts, location, a **Clash** block with three one-tap fixes (Shift 15m later / Shorten to 45m / Keep both), invitees with reply status, Delete. | Modal from 02/09/16 |
| 32 | Connect calendars | Accounts (iCloud Live, Google Live, CalDAV **Stale** "last sync 4h ago"), which calendars show, **Write back** rules per feed, and the privacy note about never touching an event it did not create. | ← Settings |
| **J** | **"The messy reality of TV"** | | |
| 33 | Rating & review | Modal log-a-watch: "2nd rewatch" badge, 5★/10pt scale toggle, **half stars** ("tap left or right of centre"), review body with spoiler toggle + bold/italic/link, character count, context rows (Watched on / Where / With), tags. | Modal |
| 34 | Specials & episode order | Numbering schemes Aired/Absolute/DVD, "Include specials" and "Merge multi-part (treat E7 & E8 as one 2h finale)" toggles, 9-row episode list incl. a SPECIAL row and a PARTS 1–2 row. Progress stored per episode. | ← Series |
| 35 | Per-show settings | Explicit status Watching/Paused/Dropped, season pass, per-show notification + calendar routing, spoiler-safe names, Region UK, My services "3 of 12", price-drop watch, preferred quality, Reset progress / Archive / Remove. | ← Series |
| **K** | **"Automation & arrival"** | | |
| 36 | Auto-detect & scrobbling | "41 episodes ticked for you"; **Now playing** live card with a 41:02 / 55:00 progress bar and "ticks at 90%"; sources (Apple TV, Chromecast, browser extension, this phone); rules; a **"Needs a decision"** disambiguation card ("'Marram E3' or 'Marram Grass'?" → The series / The film / Neither). | ← Settings |
| 37 | Import mapping | CSV import step 3 of 4: file card "418 rows · 9 columns", column→field mapping rows with sample values and a Skip, "What will happen" counts 384 New / 28 Merged / **6 Conflicts**, conflict resolver "Keep mine / Take file / Keep both — 1 of 6 · apply to all". | ← Settings |
| 38 | Onboarding — steps 1, 3, 4 | Welcome ("One place for what you keep"), notification-loudness choice made *before* the OS permission is requested (Quietly / Notify me / Weekly digest), first-title picker, "Finish setup", "Skip — I'll add things later". | Chromeless |
| **L** | **"Off-app, account, access"** | | |
| 39 | Widgets, Shortcuts & share | Four widget sizes off one data model (UP NEXT, TONIGHT, STREAK, TODAY · WIDE), three Siri shortcuts, an Automations row, and a Share-sheet extension card. | ← Settings |
| 40 | Account & permissions | "Signed in with Apple · relay address · no email shared", device list, **permission rows each stating their purpose** (Notifications "not yet asked", Calendars read+write, Photos, Microphone, Local network), privacy statement, Share anonymous usage Off, Delete everything. | ← Settings |
| 41 | Accessibility | The spec *drawn*: the densest card re-laid at **Dynamic Type 235%** (rows become stacks, icon-only buttons grow labels, nothing truncates), six built-in rows (VoiceOver, Dynamic Type, Reduce motion → cross-fades, Increase contrast → hairlines darken/shadows drop, Touch targets ≥44×44, "Colour is never alone"), and a literal VoiceOver transcript for an episode row. | ← Settings |
| **M** | **"Health · meal plans"** | *"A section inside a section."* | |
| 42 | Health — hub | Eaten-today ring/bar "1,480 / 2,100 kcal", macro split bar "118P · 163C · 41F", next-meal row, and a tile grid where Sleep/Weight/Workouts/Medication read **"Not set up"**. | ← Home. → 43 |
| 43 | Meals — today | Day view for meals, same component as 02: plan chip "Cutting v3", 7-day strip, toolbar chips (Week/Shop/Nutrition/Plan), macro bar, five meal cards in the time gutter with **eaten / skipped / upcoming** states, next one lifted with Mark eaten / Swap, and a "Tomorrow — needs prep tonight" card. | ← Health. → 44, 45, 46, 47, 48, 49 |
| 44 | Meals — the repeating week | 5 slots × 7 days matrix, cells carry state only (Planned/Today/Free), tapped day lists underneath; repeat rule rows ("Repeats every week, indefinitely", "Started Week 6 · 6 Jul 2026", "Edit this week only"). | ← Meals |
| 45 | Meal detail | Hero photo, kcal with a **portion multiplier (− 1.0× +) that rescales every number**, six macro figures, macro bar, ingredient list with per-item grams and kcal, method with time/oven/serves chips, history rows (eaten 14×, rating, note). | ← Meals |
| 46 | Swap a meal | Modal: "Replacing" card, ranking tabs (Closest macros / Faster / In my fridge), candidates with **kcal delta** (−15, +20, +90) and a BEST badge, "Effect on today" recomputed total 2,085/2,100, then "Swap just today" vs "Every week". | Modal |
| 47 | Nutrition & adherence | Range tabs Week/Month/All, daily-average vs target, 7-bar week chart with target line, **86% adherence** leading, macro-vs-target bars, 12-week pixel field, and a "What the data says" insight ("Friday is your weak day — 4 of 5 skips happen after 16:00"). | ← Meals |
| 48 | Shopping list | 24 items, "9 of 24 in the basket · £41.20 est.", grouping tabs (By aisle / By meal / Missing only), aisle sections, each line showing which meals asked for it and the summed quantity, "Send list". | ← Meals |
| 49 | Meal plan profiles | "4 saved · 1 active": active plan card with targets and adherence, saved plans with Activate, and switching rules — "Switch takes effect **Next Monday**", "Keep the history", "Auto-switch → Travel week when a trip is on the calendar". | ← Meals. → 50 |
| 50 | Share, import & export | **QR code** "kati://plan/cutting-v3 · 35 meals", copy link / share, "What travels with it" (meals, targets, reminder times — history *never* shared), shared-with list, and Scan / Import file / Export JSON / **Print the week (PDF, fridge-sized)**. | ← Plans |
| 51 | Meal reminders | Both halves drawn as **real notification bubbles**: a 20:00 "Tomorrow: 5 meals, 2 need prep" preview, and a 19:15 "Dinner in 15 minutes" with inline **Eaten / Skip / Snooze** actions; plus manners rows (quiet hours, skip when busy, stop after 2 skips, or stay silent). | ← Meals |
| 52 | Meals on the calendar | Meals merged into the day spine with a bronze lane colour, filter chips (All / Meals 5 / Screen 2 / Personal 4), and a "Collapse meals → 5 meals · 1,960 kcal · 1 eaten · next at 10:30" row obeying the same 3+ rule as episodes. | ← Calendar |
| **N** | **"Two languages, one interface"** | *"The pass covers direction, alignment, icon mirroring, week start, calendar system and numerals."* | |
| 53 | Onboarding — choose a language | Two options each stating its three consequences in its own script: "English — LEFT TO RIGHT · 1234 · GREGORIAN" / "فارسی — RIGHT TO LEFT · ۱۲۳۴ · SHAMSI". | Chromeless. → 26 |
| 54 | Settings — language & region | Interface language list + "Add a language (Arabic, Turkish, German…)", then the five settings that **follow the language** (writing direction, calendar, numerals, week start, time format) each still overridable, plus Content (title language, units, currency) and "Your own words are never translated". | ← Settings |
| 55 | خانه — Home, RTL | Screen 01 mirrored: poster stacks overlap leftward, the primary button's arrow becomes `arrow_back`, the time gutter sits right; Shamsi date "یکشنبه ۲۵ مرداد ۱۴۰۵", Persian digits throughout. | Home root (fa) |
| 56 | تقویم — day, RTL | Screen 02 mirrored, and the **day strip reorders to start at شنبه** with an explicit note "هفته از شنبه آغاز می‌شود" — *"a change no amount of CSS mirroring would produce."* | Calendar root (fa) |
| 57 | کتابخانه — Library, RTL | Shelf mirrored. Poster art itself never mirrors, but each **progress bar fills from the right**. Foreign titles transliterated; 54 can show originals alongside. | Library root (fa) |
| 58 | سریال — episode tracker, RTL | Screen 04 mirrored; back chevron becomes `arrow_forward_ios`; **episode numbers stay in DM Mono with Persian digits so the column still aligns**. | ← کتابخانه |
| 59 | وعده‌های امروز — Meals, RTL | Screen 43 mirrored; meal times keep the mono face; the macro bar fills right-to-left, protein first. | ← سلامت |
| 60 | برنامه هفتگی — week matrix, RTL | Screen 44 mirrored — *"the hardest case in the whole pass: a matrix whose columns are days. Mirroring alone would put Monday on the right and still be wrong — the sequence itself has to restart at شنبه."* | ← وعده‌ها |
| 61 | آمار — charts, RTL | Screen 07 mirrored: **time axis reads right-to-left, bars fill from the right, and the pixel field starts its year in the top-right corner.** | Stats root (fa) |
| 62 | تنظیمات — Settings, RTL | Rows mirror wholesale — icon right, chevron flipped to `chevron_left`. The Language group is placed **first**. | ← خانه |

A trailing "The localization system" panel (not a phone screen) carries a **locale table**:

| Code | Name | Dir | Calendar | Digits | Week starts | Typeface | Status |
|---|---|---|---|---|---|---|---|
| en | English | LTR | Gregorian | 1234 | Monday | Plus Jakarta Sans | — |
| fa | فارسی | RTL | Shamsi | ۱۲۳۴ | Saturday | Vazirmatn | 1.0× |
| ar | العربية | RTL | Hijri | ١٢٣٤ | Saturday | IBM Plex Sans Arabic | ready |
| tr | Türkçe | LTR | Gregorian | 1234 | Monday | Plus Jakarta Sans | ready |

---

## 3. Recurring UI components

| Component | Where | Spec / variants implied |
|---|---|---|
| **Screen scroller** | every screen | `height:100%;overflow:auto;padding:64px 21px 132px` (tabbed) or `64px 21px 40px` (pushed). No `position:sticky` anywhere — headers scroll away; the tab bar is absolutely positioned. |
| **Large title header** | all non-modal screens | Left-aligned `font-size:22px;font-weight:700;letter-spacing:-.03em;color:#1A1917` with a `13.5px` `#A9A29A` subtitle underneath, and 0–2 trailing 40 pt circular icon buttons. Home uses `28px`. |
| **Modal header** | 06, 18, 31, 33, 46 | Centred title, leading `close`, optional trailing text action ("Save"). |
| **Back pill** | 30 pushed screens | `arrow_back_ios_new` (`arrow_forward_ios` in RTL) + parent label, `font-size:13px;font-weight:600`. |
| **Elevated card** | everywhere | `background:#FBFAF8;border-radius:18–22px;padding:14–18px;box-shadow:0 1px 2px rgba(26,25,23,.04),0 12px 24px -18px rgba(26,25,23,.7)` — 262 uses, the single most repeated recipe. Dark variant: `#1E1D1B` + `inset 0 0 0 1px rgba(245,242,238,.06)`. |
| **Cream card** | 08 note, 14 synopsis, 12, 13, 17, 18, 21–23, 25 | `#FBF1DE` / `#EFE3CB` — reserved for "anything personal you wrote". Dark equivalent `#2A2622` / text `#F7EFE4`. |
| **Mono section label** | every stack | `'DM Mono';font-size:10.5px;letter-spacing:.16em;text-transform:uppercase;color:#A0998F`, often preceded by a 13 × 2 px orange rule. |
| **List row** | settings, meals, ingredients, providers, permissions | 40 × 40 icon tile (`border-radius:13px;background:#EFECE7`) + title `13.5px/600` + sub `11.5px` `#A9A29A` + trailing `chevron_right` / toggle / value. |
| **Filter / scope chip** | 02, 03, 09, 15, 19, 30, 43, 46, 47, 48, 52 | `height:26–30px;border-radius:13–15px`, unselected `#FBFAF8`/`#5C574F`, selected `#1A1917`/`#FBFAF8`; optional count badge. |
| **Segmented control** | 16/17/30 (Day/Week/Month/Agenda), 24 theme, 25 frequency, 33 scale, 34 order, 44, 47 | Track `#E4E0D9`, thumb `#FBFAF8` with `0 1px 2px` shadow. |
| **Tag chip** | 14, 33 | Pill with `+ tag` affordance at the end. |
| **Poster tile / rail** | 01, 03, 05, 10–14, 20, 21, 57 | `<image-slot shape="rect" src="picsum…/400/600" placeholder="Poster">`; 2:3 for film/TV, near-square for books (`Cover`) and music (`Art`); `Meal photo`, `Series still`, `Wallpaper` also used. 130 slots total, 10 distinct placeholder strings. |
| **Poster stack** | 01, 09, 12 | 3 overlapping posters, `border:2px solid` paper, overlapping rightward in LTR / leftward in RTL. |
| **Progress bar** | 04, 20, 42, 43, 45, 47, 57, 59 | 2 px `border-radius:1px` track `#C4BDB3` + fill `#E8823C` (or green/bronze); fills from the right in RTL. |
| **Macro bar** | 42, 43, 45, 47, 59 | Three-segment stacked bar (P/C/F) with a legend row. |
| **Streak row** | 22 | 7 × check pills under M T W T F S S, filled green `#4E9A73` or hollow. |
| **Pixel field** | 07 (104 cells), 22 (13 weeks), 47 (12 weeks), 61 | 5-tone bronze ramp `['#EFE3CB','#E4D2B0','#D3B98A','#B08E55','#1A1917']`, 2 px radius squares. Explicitly "the shared visual for any section that accumulates over time". |
| **Bar chart** | 07 genres, 47 macros, 61 | Horizontal bars with per-series colour ramp (`#1A1917`, `#4A443B`, `#7C766D`, `#B3ACA2`) + right-aligned value; 47 adds a target line. |
| **Time-gutter timeline** | 02, 09, 30, 43, 52, 56, 59 | Left mono time column + one card per item; supports lane splitting, `+n MORE` tiles, grouped/collapsed cards, all-day bands. |
| **Calendar grid** | 16 | 6×7 numeric grid with up to 3 section dots per cell and one filled "heaviest day" card. |
| **Week lane chart** | 17 | 7 columns, block height ∝ duration, colour = section, tap-to-name. |
| **Matrix grid** | 44, 60 | 5 rows (meal slots) × 7 day columns, state-only cells. |
| **Day strip** | 02, 43, 56, 59 | 7 pills; today gets `#FBFAF8` + shadow. |
| **Stat tile trio** | 07, 47 | Big number + mono caption, three across. |
| **Delta badge** | 07, 23 | `arrow_drop_up` + percentage, green/red. |
| **Insight card** | 23, 47 | `lightbulb` icon + a sentence with bolded numbers + 1–2 text actions. |
| **Info footnote** | 09, 32, 34, 40, 42, 49, 51–54, 56, 61 | `info`/`lock` glyph + small grey explanatory paragraph inside a tinted card. |
| **Toggle row** | 25, 32, 34, 35, 36, 51 | Row + iOS-style switch; ink when on. |
| **Primary button** | 26, 27, 38, 53, 43 | `height:44–54px;border-radius:22–27px;background:#1A1917;color:#FBFAF8;font-weight:700`, optional trailing arrow, `box-shadow:0 14px 28px -12px rgba(26,25,23,.85)`. **"Ink is the only button colour."** |
| **Circular icon button** | headers | 40–44 px, `background:#FBFAF8` + shadow; notification bell carries an 8 px orange dot with a 2 px paper ring. |
| **Notification bubble** | 51 | Rendered lock-screen notification: app name + time, title, body, and inline action buttons. |
| **Widget** | 29, 39 | Four sizes (small poster, small count, small streak, wide list) on translucent white `rgba(255,255,255,0.13–0.95)` with `backdrop-filter:blur(22px)`. |
| **QR code** | 50 | Drawn as a grid of 2 px ink squares. |
| **Skeleton row** | 27 | Card with a grey `#E7E3DC` poster block and two `linear-gradient(90deg,#E7E3DC,#F1EEE9,#E7E3DC)` bars, rows at `opacity:1 / 0.75 / …` to fake a fade. |
| **Undo bar** | 27 | Dark pill: `undo` + "Dropped The Quiet Ones" + "Undo". |
| **Star rating** | 08, 14, 33, 45 | Half-star capable; alternative 10-point scale on 33. |
| **Avatar** | 11, 14, 31, 40, 50 | Circular `image-slot`. |
| **Provider badge** | 08, 14, 23 | Single-letter square (L / O / K / A / D) + name + price/status. |

---

## 4. States and edge cases actually drawn

Screen **27 — "Empty, loading, offline"** is an explicit reference sheet with five bands:

1. **"Empty — nothing added yet"** — `movie` glyph, "No titles yet / Add one thing you are watching and the calendar starts filling itself.", ink "Add a title" button, secondary "or import a backup".
2. **"Loading — skeleton, never a spinner"** — three shimmer-gradient rows at decreasing opacity.
3. **"Offline — the library still works"** — `cloud_off` badge: "Offline / Ticks are saved and will sync later".
4. **Error** — `error` glyph: "Couldn't check for releases / Last success 6h ago" + **Retry**.
5. **"Undo — every destructive action"** — "Dropped The Quiet Ones / Undo".

Summary line: *"Skeletons instead of spinners, an offline badge that promises the ticks are safe, and an undo bar on every destructive action."*

Other states drawn elsewhere:

- **Not-set-up / coming-soon** — 42 Health tiles (Sleep, Weight, Workouts, Medication all "Not set up"); 03/57 shelf switcher shows Books and Music greyed until built; 36 "Browser extension — Not installed" with a **Get** action.
- **Stale sync** — 32 CalDAV row: "last sync 4h ago" with a **Stale** badge beside two **Live** ones.
- **Permission not yet requested** — 40: "Notifications — Not yet asked — only when you turn one on" with an **Allow** button; every other permission row states its purpose. 38 makes the notification *choice* before the OS prompt.
- **Ambiguity / needs-a-decision** — 36 "'Marram E3' or 'Marram Grass'? Played 43m on Orbit, 21:10" → The series / The film / Neither.
- **Import conflicts** — 37: 6 conflicts resolved one at a time, "Keep mine / Take file / Keep both", "1 of 6 · apply to all", with a pre-write summary 384 New / 28 Merged / 6 Conflicts, and a skipped column "(empty in 402 rows)".
- **Clash / overlap** — 09 "2 at once" and "3 at once" lane splits with a `+1 MORE` overflow tile; 18 pre-save clash warning; 31 three one-tap resolutions.
- **Over-budget / no-result** — 13 "Nothing else fits — nearest film is 1h 46m · 61 MIN OVER".
- **Stale / abandoned content** — 10 "Gone cold · 3 … 4 MONTHS AGO" with a **Drop** action; 12 "Abandoned 3"; 15 "Dropped The Quiet Ones after S1E3".
- **Skipped / broken** — 43 & 59 meal marked **SKIPPED / رد شد**; 22 habit "Water the plants — **broken**".
- **Paused** — 23 "Aria Audio — paused until October"; 35 status Paused.
- **Empty gaps in agenda** — 30 "Nothing else until 12 Sep" (gaps stated, not scrolled).
- **Season complete** — bound in `renderVals()`: `nextAirPrefix: 'Season complete —'`, `nextAirDate: 'nothing left to watch'`, `markLabel: 'Season complete'`, dot flips `#E8823C → #4E9A73`.
- **Accessibility extreme** — 41 renders the densest card at 235% Dynamic Type: "rows become stacks and icon-only buttons grow labels. Nothing truncates — cards get taller instead."
- **Missing translation** — locale panel: "Missing keys fall back to English, visibly flagged in a debug build."
- **Spoiler-hidden** — `spoilerSafe` prop swaps episode titles for "Episode N"; 33 has a spoilers-hidden review toggle; 35 "Hide unwatched titles".
- **Watched-row treatment** — watched episode rows lose their shadow and drop to `#F4F1EC` with `#9C958B` text (`rowShadow: 'none'`).

---

## 5. Design tokens (measured from the inline styles)

### Light palette

| Role | Hex | Uses | Notes |
|---|---|---|---|
| Ink (text, buttons, active) | `#1A1917` | 1246 | *"Ink is the only button colour."* |
| Card / ivory | `#FBFAF8` | 654 | every raised surface |
| Body text, secondary | `#5C574F` | 381 | |
| Paper (screen background) | `#EFECE7` | 379 | also icon-tile fill |
| Hairline / track / disabled | `#C4BDB3` | 306 | |
| Tertiary text | `#8A8479` | 270 | |
| Quaternary text | `#A9A29A` | 244 | subtitles |
| **Accent orange** | `#E8823C` | 217 | *"Orange only ever means 'new / now'."* |
| Muted text | `#B3ACA2` | 216 | inactive tab icons |
| Mono label grey | `#A0998F` | 205 | |
| Segmented track | `#E4E0D9` | 147 | |
| Bronze (meals, pixel ramp top) | `#B08E55` | 109 | |
| Green (habits, done) | `#4E9A73` | 89 | deep variant `#3E8460` |
| Pixel ramp | `#EFE3CB` → `#E4D2B0` → `#D3B98A` → `#B08E55` → `#1A1917` | | five tones |
| Mono caption | `#6E6860` | 71 | |
| Cream (personal / notes) | `#FBF1DE`, `#EFE3CB` | 49 / 64 | |
| Watched-row fill | `#F4F1EC` | 36 | |
| Skeleton block / shimmer | `#E7E3DC`, `#F1EEE9`, `#DCD7CF` | | |
| Amber (stars, warn) | `#C98A3E`, `#96723C` | | |
| Red (error, delete, clash) | `#B4553C` | 13 | |
| Canvas (the shelf page itself) | `#CFCBC5` | | not an app colour |
| Link | `#C96A28`, hover `#E8823C` | | canvas chrome only |

### Dark palette (screen 28, and 29's chrome)

| Role | Hex |
|---|---|
| Paper (near-black) | `#121110` (lock-screen gradient base `#0E0D0C`) |
| Card | `#1E1D1B` |
| Card hairline (replaces shadow) | `inset 0 0 0 1px rgba(245,242,238,.06)` |
| Raised / secondary fill | `#2A2826`, `#312F2C`, `#3A342D`, `#4A453F` |
| Cream → "lit-lamp brown" | `#2A2622` with text `#F7EFE4` |
| Primary text | `#F5F2EE` |
| Secondary text | `#8A837B`, `#A89B87` |
| Tertiary text | `#6A6560`, `#7A6F5E` |
| Accent | `#E8823C` unchanged; on-accent text `#16150F` |
| Accent tint ring | `inset 0 0 0 1px rgba(232,130,60,.14)` |
| Dark shadows | `0 4px 10px -4px rgba(0,0,0,.6)`, `0 12px 26px -10px rgba(26,25,23,.8)` |

Stated rule: *"Dark is not an inversion. Paper becomes near-black, cards lift with a hairline instead of a shadow, and the cream card warms to a lit-lamp brown so 'personal' still reads as warm."*

### Type

Three families, loaded from Google Fonts:
`Plus Jakarta Sans 400;500;600;700;800`, `DM Mono 400;500`, `Vazirmatn 400;500;600;700;800`, plus
`Material Symbols Rounded opsz,wght,FILL,GRAD@20..48,300..700,0..1,0`.

- **Plus Jakarta Sans** — set once on the page root (`font-family:'Plus Jakarta Sans',system-ui,sans-serif`) and inherited; *"One tight geometric sans for everything that speaks."*
- **DM Mono** — 811 explicit uses; *"one mono for everything that measures — times, counts, episode numbers, dates."*
- **Vazirmatn** — 231 uses, group N only.
- **Material Symbols Rounded** — 673 icon spans; filled state via `font-variation-settings:'FILL' 1`.

Type scale (by frequency, px): **11.5** (315) · **13.5** (305) · **10.5** (276) · **11** (273) · **12.5** (231) · **17** (214) · 13 · 10 · 12 · 14 · 9.5 · **22** · 18 · 21 · 15 · 19 · 16 · **28** · 14.5 · 20 · 27 · 9 · 24 · 26 · 34 · 30 · 32 · 15.5 · 25 · 23 · 16.5 · 8.5 · 40 · 36 · **74** (lock-screen clock).

Practical roles: 9.5–10.5 mono micro-labels · 11–11.5 captions · 12.5–13.5 body/rows · 14.5–15 emphasis ·
17–19 card titles · 21–22 screen titles · 26–28 hero numerals/greeting · 74 clock.

Weights used: **600** (623) · **700** (299) · **500** (105) · **800** (31) · 300 (1). No 400 declared — the inherited default.

Letter-spacing: `.16em` (127) and `.14em` (95) for mono uppercase labels; `.2em` for group letters;
`-.03em` / `-.035em` for large titles; `-.02em` / `-.015em` / `-.01em` for card titles.
Persian carries **no** letter-spacing — *"tracking breaks the joins"* — and *"rides a taller line-height"* (`1.4` observed vs `1.5`/`1.55` for Latin).

Line-heights: `1.5` (66) and `1.55` (46) dominate; `1.6` for long-form; `1.05–1.2` for numerals.

### Radii

`2px` (493, pixel-field cells & QR modules) · `9px` · `1px` (progress tracks) · **`20px`** (161, standard card) ·
`14px` · **`22px`** (125, pill buttons / 44 px circles) · `16px` · `4px` · `11px` (icon tiles) · `3px` (6 px dots) ·
`13px` (chips) · `18px` (list cards) · `12px` · `5px` · `17px` · `15px` · **`32px`** (29, tab bar & FAB) · `26px` · `27px` · `999px` (4).

Rough system: dot 3 · bar 1–2 · thumbnail 8 · icon tile 11–13 · chip 13–15 · card 18–22 · sheet 26 · capsule = height/2.

### Elevation

- **Card** — `0 1px 2px rgba(26,25,23,.04), 0 12px 24px -18px rgba(26,25,23,.7)` (262×)
- **Small / floating icon button** — `0 1px 2px rgba(26,25,23,.05), 0 8px 16px -12px rgba(26,25,23,.5)` (99×)
- **Hairline on image** — `0 1px 3px rgba(26,25,23,.3)` (75×)
- **Tab bar** — `0 1px 2px rgba(26,25,23,.05), 0 14px 30px -16px rgba(26,25,23,.7)`
- **FAB** — `0 12px 26px -10px rgba(26,25,23,.8)`
- **Primary button** — `0 14px 28px -12px rgba(26,25,23,.85)`
- **Selection ring** — `0 0 0 2px #1A1917, 0 8px 18px -14px rgba(26,25,23,.6)`
- **Inset hairlines** — `inset 0 0 0 1.5px rgba(26,25,23,.1)`, `inset 0 0 0 1.5px #DCD7CF`
- 47 distinct shadow strings in all; every one is a **warm-ink** shadow, never neutral black (except the two dark-mode `rgba(0,0,0,.6)` cases).

### Spacing rhythm

Gaps cluster on **9 px** (209) and **13 px** (238); paddings on **13/14/15/16/18 px** for cards,
`4px 15px` for chips, `0 10–16px` for rows, `13px 0` for list dividers (144×).
Screen gutters 21 px; top inset 64 px; bottom inset 132 px (tabbed) / 40 px (pushed).
Touch targets: 40, 44, 46, 54, 64 px — nothing under 44 for primary controls (41 states "Nothing under 44×44").

### Motion

**Zero** `transition`, `animation`, `transform` or `filter` declarations exist in the file — the shelf is
static frames plus mustache-bound state. Motion is described in prose only: 41 "Reduce motion →
cross-fades instead of slides", 27 "skeleton, never a spinner".

---

## 6. Internationalisation (group N)

**Mechanism as drawn:** RTL is a *container attribute*, not a fork. Every fa screen is
`<div dir="rtl" style="direction:rtl;height:100%;overflow:auto;padding:64px 21px 132px">` — 8 `dir="rtl"`
attributes and 14 `direction:rtl` declarations for the whole group. *"A language is a row of data, not a
fork of the design. Adding one means adding a row — nothing in any screen is rewritten."*

**What flips** (`swap_horiz` list on the localization panel): Layout & alignment · Navigation direction ·
Back chevron · Row chevrons · Progress & macro bars · Chart time axis · Poster stack overlap ·
Drawer & sheet edges.

**What holds** (`lock` list): Poster & meal artwork · Play / pause / skip · Clock and timer faces ·
Checkmarks & ticks · Brand mark · Star ratings.

The rule: *"anything that means **direction of reading** flips. Anything that means **direction of time or
motion** — play, skip, a clock hand — does not."*

**Typography.** Vazirmatn for Persian, Plus Jakarta Sans for Latin — *"Type is per-script."*
Persian carries **no letter-spacing** ("tracking breaks the joins") and a taller line-height.
**Numerals stay mono**: *"Times, counts and episode numbers keep DM Mono in both languages, with
Persian digits substituted, so every column still aligns."* Observed: `۰۷:۳۰`, `۱,۴۸۰ از ۲,۱۰۰ کالری`,
`۸٫۹۹ پوند` (Persian decimal separator U+066B), `۱۸٪` (Persian percent U+066A).

**Calendar.** Shamsi/Jalali throughout: "یکشنبه ۲۵ مرداد ۱۴۰۵" (= Sunday 16 August 2026),
"فروردین تا مرداد ۱۴۰۵", "پخش ۲۹ مرداد", "آخرین پشتیبان ۱۴ مرداد". Weekday abbreviations
ش ی د س چ پ ج. **Week starts Saturday** and the *sequence itself* reorders — screen 60 calls this
"the hardest case in the whole pass: a matrix whose columns are days. Mirroring alone would put
Monday on the right and still be wrong."

**Charts.** 61: *"the time axis reads right-to-left, bars fill from the right, and the pixel field starts its
year in the top-right corner."* 57: progress bars fill from the right. 59: macro bar fills right-to-left.

**Strings.** Keyed by meaning: `meals.today.title` → "Today / امروز", `meals.slot.breakfast`,
`meals.remaining` → `{n} kcal left`, `series.progress` → `{done} of {total} watched`, `nav.back` → `{parent}`.
*"Counts are interpolated, never concatenated — Persian puts the number before the noun and English
after, and only a placeholder survives both."*

**Content boundary.** 54 and the panel both state it: *"Your own words — notes, list names, meal titles
— are never translated. Only the interface changes."* Titles are transliterated with an optional
"Show original titles alongside" setting.

**Adding a language** = 3 steps: add a locale row (direction, calendar, digits, week start, typeface) ·
translate one flat key file (missing keys fall back to English, flagged in debug) · *"Nothing else."*

---

## 7. Hard / impossible for a declarative cross-platform widget toolkit

**Almost certainly out of reach without native escape hatches**

1. **Glass / backdrop blur** — 23 `backdrop-filter` declarations at `blur(14px)`, `blur(20px)`, `blur(22px)`, on the tab bar of every root screen and on all four lock-screen widgets. This is real backdrop sampling, not a translucent fill.
2. **Home-screen widgets (29, 39)** — four sizes off one data model. These are WidgetKit/App Widget surfaces, out-of-process, with their own render lifecycle and refresh budget. No declarative UI toolkit renders these.
3. **Lock-screen / notification surfaces (29, 51)** — 51 draws notifications *with inline action buttons* ("Eaten / Skip / Snooze") and says *"Tick it straight from the notification — no need to open the app."* Notification content extensions + actions are platform APIs.
4. **Siri shortcuts / voice intents (39)** — "Hey Siri, what's next?", "Mark it watched", "Add to my list", plus an Automations row.
5. **Share-sheet extension (39)** — "Save to Kati from any app, link or screenshot", with title extraction from a photo of a cinema listing (OCR).
6. **Playback auto-detection / scrobbling (36)** — Apple TV + Chromecast discovery on the local network, a browser extension, and "This phone — detects audio from any app", with a **live** now-playing progress bar. Requires Local Network + Bonjour/Cast SDK + Now Playing APIs and a long-lived background process.
7. **Background sync & scheduled work** — the release watcher runs "every 6h", quiet hours 23:00–08:00, a Sunday 18:00 digest, meal reminders 5×/day plus a 20:00 day-before preview, and "auto-switch to Travel week when a trip is on the calendar".
8. **Two-way system calendar sync (32)** — iCloud / Google / CalDAV accounts, per-calendar visibility, selective write-back, and timezone-follows-travel semantics (31).
9. **Camera / photo picker (40)** — "Photos — only when you pick a poster"; 39 accepts a screenshot; 50 needs a **QR scanner** ("Scan a plan / From a QR code or link").
10. **Microphone (18, 40)** — voice quick-add mic button.
11. **PDF generation (50)** — "Print the week — one page, fridge-sized".
12. **Sign in with Apple + multi-device iCloud sync (40)** — device list with per-device sync timestamps, "no server that can read them".

**Hard but usually possible with custom painting / gesture recognisers**

13. **Charts** — genre bars (07), macro-vs-target bars with a target line (47), 7-bar week chart, the **104-cell pixel field** (07/22/47/61) with a 5-tone ramp, and all of it **mirrored** in RTL (axis right-to-left, ramp starting top-right). Most declarative chart libraries do not mirror.
14. **The calendar week lane chart (17)** — proportional block heights, colour-by-section, tap-a-lane-to-name-it.
15. **Overlap/density layout (09)** — collision detection, lane splitting capped at two columns, `+n` overflow tiles, and 3+-same-kind collapse into a grouped card with an expand/collapse toggle. This is bespoke layout maths, not a list.
16. **Drag to reorder (24)** — "Reorder sections · Drag to change home order" (`drag_indicator`).
17. **Half-star rating by touch position (33)** — "tap left or right of centre", plus a 5★/10pt scale switch.
18. **Portion multiplier (45)** — a stepper that live-rescales six macro figures, five ingredient rows and their kcal.
19. **Full RTL mirroring** — layout, chevrons, progress fill direction, poster-stack overlap, sheet edges, *and* a reordered week sequence — while keeping artwork, play glyphs, clock faces, ticks and stars unmirrored. Per-widget mirroring exemptions are the awkward part.
20. **Dynamic Type to 235% with reflow (41)** — rows become stacks, icon-only buttons grow labels, nothing truncates, cards grow taller. Needs genuine intrinsic-size-driven reflow, not fixed heights.
21. **VoiceOver semantics** — 41 quotes the exact utterance for an episode row: *"Episode 6, The Undertow. 55 minutes. Airs 20 August. Not watched. Double-tap to mark watched."* Requires composed accessibility labels + custom actions.
22. **Poster-stack overlap and image-heavy rails** — 130 remote images with 2:3, square and 16:9 ratios, rounded corners plus a 2 px paper border ring, and a `data-mini` placeholder mode.
23. **Skeleton shimmer** — a moving `linear-gradient(90deg,#E7E3DC,#F1EEE9,#E7E3DC)` sweep (drawn statically here, but the intent is animated).
24. **Scrim over a floating tab bar** — a 120 pt `pointer-events:none` gradient layered between scroll content and chrome.
25. **CSV import pipeline (37)** — column mapping UI, unit conversion ("converts 10pt → 5★"), merge/conflict resolution before write.

**Notably absent from the design (i.e. *not* a constraint)**

- No transitions, animations, transforms or filters are declared anywhere in the 825 KB file.
- No `position:sticky` — headers scroll away; only the tab bar is fixed (absolute + gradient scrim).
- No swipe-to-action anywhere: 35 explicitly makes Watching/Paused/Dropped *"a first-class choice rather than a swipe action"*.
- No video/audio playback surface is drawn — 14's "Trailer" is a button, 36 only *observes* playback elsewhere.
