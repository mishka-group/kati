# Missing connections

> A plan and a todo for the pages Kati has not joined up, and the pages it has
> not drawn. Written 5 September 2026 against `dev` at boards 01–166.

Kati has **165 drawings**, registered board-by-board in `Kati.Screens.Gallery`,
and 174 modules in `lib/kati/screens/` — 11 of them roots and 106 pushed
screens. 42 drawings have no in-app route at all (`@no_route`), and
`Kati.AppReachabilityTest` asserts the other 123 do. Almost all of them exist,
render, and are covered by the sweeps. What is missing is not screens — it is **the
lines between them**, and a person using the app hits those gaps constantly:
tapping a film opens *a* film page rather than *that* film, tapping a sort disc
does nothing at all, and a control the design drew is wired to a screen the
design never drew.

Ten read-only agents surveyed every area of the app against the boards, the
screen modules and the three ratchets that already record known gaps
(`@inert_taps`, `@no_route`, `@on_sample`). They produced **411 connection
findings**. A second, adversarial pass re-checked all 133 claims that the
design was missing something, defaulting to *not missing*, and kept 74. Those
74 are grouped into **23 design briefs, `D-35`–`D-57`**, in `design-briefs/`.

## The one number

```
213  Mob.Socket.push_screen/2,3 calls in lib/kati/screens
  7  of them pass a third argument
```

`Mob.Socket.push_screen/3` has always taken params — `deps/mob/lib/mob/socket.ex:142`.
`Kati.Screens.Pushed` already threads them onto the socket for every pushed
screen — `lib/kati/screens/pushed.ex:48-57` assigns `:params`. The plumbing is
finished. **Two screen modules read it**: `day.ex:158` and `meal_edit.ex:92`.

That is why 97 of the 411 findings are *generic*: the tap fires, the screen is
pushed, and it opens showing whatever `newest()` or `first()` returns. It is
the same defect 97 times, and it is one line at each end:

```elixir
# calendar.ex:1333 already has the shape to copy
defp open_row(socket, module, id), do: Mob.Socket.push_screen(socket, module, %{id: id})
```

One caveat that is architectural rather than clerical: **`Kati.Screens.Root`
discards its params** — `root.ex:106` is `def mount(_params, _session, socket)`.
The 11 root screens therefore cannot receive an argument at all, so anything
that needs to open a root *about* something (Week, Month and Agenda on screen 09)
is blocked on changing that macro, not on wiring a call site.

## The four kinds of gap

**What the connection does** — this axis sums to 411:

| | Count | Meaning |
|---|---|---|
| **Wired** | 100 | it works, and was checked |
| **Generic** | 97 | it arrives, but not *about* anything |
| **Dead** | 214 | the tap reaches a catch-all and nothing happens |

**What stops it** — the same 411 read the other way:

| | Count | What it needs |
|---|---|---|
| **Nothing** | 204 | code that already exists (125 of them dead or generic) |
| **A drawing** | 139 | the design briefs below |
| **A column** | 41 | schema work — the app cannot record it |
| **A capability** | 27 | the platform cannot do it; not this version |

A connection can be dead **and** blocked on a drawing, so a row in the first
table is not a row in the second.

**125 of the 411 need nothing but code that exists today.** That is Phases 1
and 2, and it is where this plan starts.


---

## Phase 1 — carry the argument

**50 connections. No design work, no schema work.**

Every row below already pushes the right screen. It just pushes it blind. The
work is the same three edits each time:

1. the source passes `%{id: id}` (or `%{date: date}`, `%{book_id: id}`) as
   `push_screen/3`'s third argument;
2. the destination reads `socket.assigns.params` in its `load/1` instead of
   falling through to `newest()`/`first()`;
3. a test asserts the destination opens on the row that was tapped, not on the
   head of the list.

`Kati.Screens.Day` is the worked example to copy — `day.ex:158` reads
`socket.assigns.params`, and its moduledoc at `day.ex:185` records the same bug
being fixed once already. `Kati.Screens.MealEdit.params_for/1`
(`meal_library.ex:458`) is the pattern for a params *builder* when the argument
is more than an id.

Do this phase first. It is the largest single improvement a person will feel,
it can be verified without a device, and Phase 3 cannot start without it — a
screen cannot show the right row until it is told which row it is about.


#### Films and television (7)

| From | Control | Should reach | Carries | Proof |
|---|---|---|---|---|
| Library (03) poster grid tile | on_tap :open_film_<Title> on each poster Column | Film (08) | nothing — the title is matched and discarded | `lib/kati/screens/library.ex:1238-1239` |
| Library (03) poster grid tile | on_tap :open_series_<Title> | Series (04) | nothing — the title is matched and discarded | `lib/kati/screens/library.ex:1241-1242` |
| Series (04) ⋯ overflow menu row "Show details" | on_tap :show_details | SeriesMeta (14) | nothing | `lib/kati/screens/series.ex:1067-1068` |
| Series (04) ⋯ menu row "Episode order" | on_tap :episode_order | Season (34) | nothing — no title id, no season number | `lib/kati/screens/series.ex:1070-1071` |
| Series (04) ⋯ menu row "Show settings" | on_tap :open_settings | SeriesSettings (35) | nothing | `lib/kati/screens/series.ex:1073-1074` |
| Film (08) ⋯ overflow menu row "Log a watch" | on_tap :log_watch | Rating (33) | nothing — no film, no watch id | `lib/kati/screens/film.ex:880-885` |
| Library (03) ⋯ menu row "Filter shelf" | on_tap :open_shelf_filters | ShelfFilters (145) | nothing, and returns nothing | `lib/kati/screens/library.ex:1199-1204` |
#### Books (9)

| From | Control | Should reach | Carries | Proof |
|---|---|---|---|---|
| Books shelf (20), grid tile — Kati.Screens.Books | any of the six covers, tag :open_book_<seed> (books.ex:528-532) | Kati.Screens.BookDetail (66) | should carry the book id; carries nothing | `lib/kati/screens/books.ex:664-670` |
| Books shelf (20), Reading-now hero cover | hero cover Box, tag :open_book (books.ex:247) | Kati.Screens.BookDetail (66) | nothing | `lib/kati/screens/books.ex:619-620` |
| Books shelf (20), Reading-now hero | "Log progress" ink pill, tag :log_progress (books.ex:312) | Kati.Screens.LogProgress (70) | should carry %{book_id: id}; carries nothing | `lib/kati/screens/books.ex:613-614` |
| Books shelf (20), Reading-now hero | timer disc, tag :start_timer (books.ex:331) | Kati.Screens.LogProgress (70) with the timer running | a "timer running" flag; carries nothing | `lib/kati/screens/books.ex:616-617` |
| Books shelf (20), header | search disc, tag :open_search (books.ex:124) | Kati.Screens.Search (19) | none | `lib/kati/screens/books.ex:651-652` |
| BookDetail (66), action row | "Finish" circular second, tag :finish | write + Kati.Screens.Rating (33) | the id of the book on screen; carries nothing | `lib/kati/screens/book_detail.ex:1027-1029` |
| LogProgress (70), timing card | "Time it instead" Start/Stop pill, tag :start_timer | a running timer whose elapsed minutes reach the session | elapsed time | `lib/kati/screens/log_progress.ex:627-628` |
| LogProgress (70), cream insight card | n/a — a claim, not a control | n/a | n/a | `lib/kati/screens/log_progress.ex:540-542` |
| BookDetailFa (69) | ثبت پیشرفت ink button, tag :log_progress | Kati.Screens.LogProgressFa (72) | nothing | `lib/kati/screens/book_detail_fa.ex:643` |
#### Music (8)

| From | Control | Should reach | Carries | Proof |
|---|---|---|---|---|
| Kati.Screens.Music (21) | album tile, tags :open_album_albm1 / _albm2 / _albm3 (Tidal Works, Low Country, Nine Rooms) | Kati.Screens.AlbumDetail (74) | should carry an album id; carries nothing | `lib/kati/screens/music.ex:546-547` |
| Kati.Screens.Music (21) | "New from artists you follow" release row, tags :open_artist_albm4 (Kell Ostrand) and :open_artist_albm5 (Ves… | Kati.Screens.ArtistDetail (77) | should carry an artist id; carries nothing | `lib/kati/screens/music.ex:549-550` |
| Kati.Screens.AlbumDetail (74) | the artist row (person tile + chevron, :open_artist) | Kati.Screens.ArtistDetail (77) | should carry the artist id; carries nothing | `lib/kati/screens/album_detail.ex:794-795` |
| Kati.Screens.ArtistDetail (77) | discography rail rows, tags :"open_album_Tidal_Works_2025", :"open_album_Low_Country_2023", :"open_album_Nine… | Kati.Screens.AlbumDetail (74) | should carry an album id; carries nothing | `lib/kati/screens/artist_detail.ex:618-621` |
| Kati.Screens.ArtistDetail (77) | the "Following" switch row (:toggle_following) | writes Kati.Music.Artist.following; nothing reads it | none | `lib/kati/screens/artist_detail.ex:585-593` |
| Kati.Screens.AlbumDetailFa (76) | "ثبت یک شنیدن" (:log_listen) | Kati.Screens.LogListen (73) | nothing | `lib/kati/screens/album_detail_fa.ex:885-886` |
| Kati.Screens.NotificationAccess (151) | "Log by hand" (:log_by_hand) | Kati.Screens.LogListen (73) | nothing | `lib/kati/screens/notification_access.ex:478-480` |
| Kati.Screens.YearShare (98) | the Aspect segments Square / Story (:aspect_square, :aspect_story) | sets :aspect; the preview does not re-scale | none | `lib/kati/screens/year_share.ex:331-332` |
#### Meals (5)

| From | Control | Should reach | Carries | Proof |
|---|---|---|---|---|
| Kati.Screens.MealsToday (43) | any meal card in the timeline (tag meal_<Slot>_<HH:MM>) | Kati.Screens.Meal (45) | nothing — every card pushes the same argument-less screen | `lib/kati/screens/meals_today.ex:846` |
| Kati.Screens.MealsToday (43) | prep card primary "See tomorrow" | Kati.Screens.MealsDay (52) | nothing — no date travels | `lib/kati/screens/meals_today.ex:1233` |
| Kati.Screens.Meal (45) | swap_horiz disc | Kati.Screens.MealSwap (46) | nothing — unlike 43 it does NOT call MealSwap.hand_over/1 | `lib/kati/screens/meal.ex:1079-1080` |
| Kati.Screens.Plans (49) | active card's more_horiz disc | Kati.Screens.PlanShare (50) | none — 50 draws Kati.Meals.SampleShare whatever plan the card names | `lib/kati/screens/plans.ex:209-220` |
| Kati.Screens.MonthGrid (16) / Kati.Screens.Agenda (30) | the Day/Week/Month/Agenda switcher's "Week" segment | Kati.Screens.Week (17) | none — 17 draws a fixed sample week | `lib/kati/screens/month_grid.ex:94` |
#### Health (3)

| From | Control | Should reach | Carries | Proof |
|---|---|---|---|---|
| Health hub (42), Sections grid, Workouts tile | tile tap, tag :open_retired_Workouts | RetiredTile (114) — opens the SLEEP sheet | nothing; should carry %{section: "Workouts"} | `lib/kati/screens/health.ex:1106-1109` |
| Health hub (42), Sections grid, Sleep tile | tile tap, tag :open_retired_Sleep | RetiredTile (114) | nothing (right answer by accident — Sleep is the default subject) | `lib/kati/screens/health.ex:1080-1081` |
| Weight (109), range segmented control | Week / Month / All, tags :range_week :range_month :range_all | itself — relights the chip and nothing narrows | the tag, into an assign nothing reads | `lib/kati/screens/weight.ex:382-383` |
#### Money (1)

| From | Control | Should reach | Carries | Proof |
|---|---|---|---|---|
| Schedule (02, root) — a money row in the day spine | :row_money_<uuid> (tag built at calendar.ex:1136-1137) | MoneyDay (126), Kati.Screens.MoneyDay | %{id: event_id} — and it is dropped on the floor | `lib/kati/screens/calendar.ex:1245-1247` |
#### Calendar (6)

| From | Control | Should reach | Carries | Proof |
|---|---|---|---|---|
| Kati.Screens.Calendar (02) | timeline meal card (`row_meals_<uuid>`) | Kati.Screens.MealsDay (52) | %{id: event_id} — thrown away; what 52 needs is a date | `lib/kati/screens/calendar.ex:1196` |
| Kati.Screens.Calendar (02) | timeline money card (`row_money_<uuid>`) | Kati.Screens.MoneyDay (126) | %{id: event_id} — thrown away | `lib/kati/screens/calendar.ex:1200` |
| Kati.Screens.Calendar (02) | month name + `unfold_more` | Kati.Screens.MonthGrid (16) | nothing — should carry the month on screen | `lib/kati/screens/calendar.ex:1220-1221` |
| Kati.Screens.Calendar (02) | ⋯ overflow menu — Agenda / Quick add / Meals on the calendar / Money on the calendar | Agenda (30), QuickAdd (18), MealsDay (52), MoneyDay (126) | nothing — none carries the selected date | `lib/kati/screens/calendar.ex:1229-1235` |
| Kati.Screens.Week (17), Kati.Screens.MonthGrid (16), Kati.Screens.Agenda (30) | the switcher's Day / Week / Month / Agenda segment | the named calendar view | nothing — no date, no week, no month | `lib/kati/screens/view_switcher.ex:145-155` |
| Kati.Screens.MealsToday (43) | the `calendar_view_week` control | Kati.Screens.MealsDay (52) | nothing — no date | `lib/kati/screens/meals_today.ex:1321` |
#### Home and search (6)

| From | Control | Should reach | Carries | Proof |
|---|---|---|---|---|
| Kati.Screens.HomeEmpty (139) | "Nothing scheduled — add anything with +" / the FAB it names | Kati.Screens.QuickAdd (18) | none | `lib/kati/screens/home.ex:1163` |
| Kati.Screens.Library (03) / Books (20) / Music (21) / Calendar (02) / Activity (15) | search disc / "Search" menu row | Kati.Screens.Search (19) | a query | `lib/kati/screens/library.ex:1157` |
| Kati.Screens.Search (19) | back pill | Home | none | `lib/kati/screens/search.ex:328-358` |
| Kati.Screens.SearchIdle (86) | one of the eight scope chips | Kati.Screens.Search (19), narrowed to that scope | the chosen scope | `lib/kati/screens/search_idle.ex:142` |
| Kati.Screens.InboxNotifications (undrawn) | any reminder row | the thing the reminder is about | the candidate id | `lib/kati/screens/inbox_notifications.ex:224` |
| Kati.Screens.InboxNotifications (undrawn) | a calendar reminder row | Kati.Screens.EventDetail (31) | event id | `lib/kati/screens/event_detail.ex:133` |
#### The Persian side (5)

| From | Control | Should reach | Carries | Proof |
|---|---|---|---|---|
| LibraryFa (board 57) poster grid | poster tile, tag open_series_<title> | SeriesFa (58) | the title is in the tag and is thrown away; no id, no kind | `lib/kati/screens/library_fa.ex:738-743` |
| SearchFa (90) results | a result row (hit_<index>) | SeriesFa (58) | the index is matched and discarded | `lib/kati/screens/search_fa.ex:975-976` |
| BookDetailFa (69) | ثبت پیشرفت (log_progress) | LogProgressFa (72) | nothing - no book_id | `lib/kati/screens/book_detail_fa.ex:642-643` |
| AlbumDetailFa (76) | ثبت شنیدن (log_listen) | LogListen (73) | nothing - no album_id | `lib/kati/screens/album_detail_fa.ex:885-886` |
| AlbumDetailFa (76) | هنرمند row (open_artist) | ArtistDetailFa (79) | nothing | `lib/kati/screens/album_detail_fa.ex:891-892` |


---

## What the device said, once Phase 1 landed

Four defects that no host sweep can see, found by using the app on Pixel_9a.
Three are fixed in `27ce0b8`; the fourth is the largest thing in this document
and is not fixed.

**A popped-to screen never re-reads.** `deps/mob/lib/mob/screen.ex:571-578`
answers `{:pop}` by restoring the *saved socket* — the one the screen had when
it was pushed away from. `load/1` does not run again. So:

    add a title  →  press back  →  the Library still says "1 titles"
    switch roots →  it says 3

Every write that ends in `pop_screen/1` is invisible until you leave the stack:
*Mark eaten*, *Log a watch*, a saved rating, an added expense, a logged weight.
It is the reason Phase 1's own fix looks broken the first time you try it, and
it is **not** Phase 1's doing — it has always been true and nothing wrote enough
to notice.

It cannot be fixed in this repo the way the other three were. Mob has no resume
hook — no `on_resume`, no message to the restored screen — and `deps/mob` is a
dependency rather than a vendored file, so there is no fence to put a patch in.
The three ways out, in the order they should be considered:

  1. **Ask upstream for a resume callback.** One optional callback invoked on the
     restored screen before `do_render/3`. It is what every navigation library
     that keeps a stack ends up with.
  2. **Re-mount instead of restoring**, for screens that declare they read the
     store. `Kati.ScreenEmptyDatabaseTest`'s `@migrated` is already that list.
  3. **Vendor `mob/screen.ex`.** The last resort, and a large one — the drift
     ledger exists so that decisions like this are made deliberately.

The three that are fixed, kept here because each says something about where the
sweeps stop:

  * **Screen 19's search field was 63 pixels wide.** A `Box` with no numeric
    width is force-filled, so the clear disc took 774 of the row's 876 pixels
    and the weighted field beside it got what was left. Neither the rendered
    tree nor the board has a width, so no sweep could ever have caught it.
  * **The text field lost and reordered keystrokes.** `Marram` arrived as
    `Mamr`. The bridge reset its local value on every host echo, and Kati's echo
    is a NIF round trip. No host sweep has a keyboard.
  * **Recents filled with abandoned prefixes.** One search for *Ashfall* held
    five of the eight slots. Visible only after typing a whole word on a device.

### And one Phase 2 found, which is a drawing rather than a defect

**A hand-added series opens the drawing.** Add *Nightbirds* by hand, tap it on
the shelf, and screen 04 draws *The Long Hollow*. The door is correct — the tile
carries the id and `series/1` reads it — but `facts/1` answers `nil` when a
title has no cached seasons or episodes (`series.ex:299`), and a hand-added
title has neither. So the screen takes its no-argument branch, which is the
drawing.

The gate itself is right: a series page whose whole spine is a season bar and an
episode list cannot draw a title that has no episodes. What is missing is the
state in between — **screen 04 with a title and nothing under it**, saying so.
No board draws it, so it is a design gap and not a wiring one, and it is the
same shape as the thing screen 154's caption already admits: *a hand-typed title
carries no poster and no episode list*. Until that board exists, the substitution
stands and it is the one place in the app where Phase 1's promise still reads as
broken to a person.


---

## Phase 2 — wire the dead controls that need nothing

**75 connections. The design drew the control and the destination exists.**

These are taps that reach a catch-all clause. `Kati.ScreenTapSweepTest` already
knows about most of them: `@inert_taps` carries 176 entries, and its **Backlog**
section names 15 controls that do nothing at all, each with a written reason.
Several of those reasons are now stale — `books.ex:641-643` still says *"no
board in the 165 draws a sort sheet for any shelf"*, but board 145 is captioned
*"One sheet for screens 03, 20 and 21"* and has been in `test/design/screens/`
since the shelf wave landed.

Rule for this phase: **strike an entry off `@inert_taps` in the same commit that
wires it.** The ratchet is only worth having if it shrinks.


#### Films and television (8)

| From | Control | Should reach | Carries | Proof |
|---|---|---|---|---|
| Series (04) progress card | "Mark next watched" — the board's one ink primary button | should tick the next episode | n/a | `lib/kati/screens/series.ex:839-869` |
| Film (08) action row | "Log rewatch", "Schedule", "Share" — three 52pt cards | nothing | n/a | `lib/kati/screens/film.ex:821-869` |
| Up next (10) cold row | "Drop" pill | DropSheet (149) | the cold title | `lib/kati/screens/up_next.ex:700-716` |
| Discover (11) "Because you watched" rail | three poster picks (Vellum, Quietus, Quiet Harbour) | Film (08) / Series (04) / AddTitle (06) | the picked title | `lib/kati/screens/discover.ex:366-390` |
| Season (34) episode list | nine rows with check discs | should tick an episode | n/a | `lib/kati/screens/season.ex:520-546` |
| Add a title (06) search field | the `cancel` clear disc inside the field | should clear the query | n/a | `lib/kati/screens/add_title.ex:397` |
| Rate an episode (144) rating card | the five stars / ten half-star targets | should set the episode rating | n/a | `lib/kati/screens/rate_episode.ex:640` |
| Activity (15) log rows | the seven history rows | Film (08) / Series (04) / Rating (33) | the watch | `lib/kati/screens/activity.ex` |
#### Books (4)

| From | Control | Should reach | Carries | Proof |
|---|---|---|---|---|
| Books shelf (20), header | sort disc, tag :open_sort (books.ex:126) | Kati.Screens.ShelfFilters (145), the Sort & filter sheet | which shelf is asking (Pages vs Runtime vs Length) | `lib/kati/screens/books.ex` |
| Books shelf (20), chip rail | the four filter chips — All 64 / Reading 2 / Finished / To read | nothing at all | n/a | `lib/kati/screens/books.ex:434-456` |
| BookDetail (66), Edition band | "This is the edition I own" switch | a write to Kati.Books.Book.owned | the new value | `lib/kati/screens/book_detail.ex:681-689` |
| LogProgressFa (72) | ذخیره و توقف ink button, tag :save (log_progress_fa.ex:365) | a ReadingSession row | page + book_id | `lib/kati/screens/log_progress_fa.ex:375` |
#### Music (1)

| From | Control | Should reach | Carries | Proof |
|---|---|---|---|---|
| Kati.Screens.Music (21) | the header "sort" disc | nothing — the tap is swallowed | none | `lib/kati/screens/music.ex:127` |
#### Meals (16)

| From | Control | Should reach | Carries | Proof |
|---|---|---|---|---|
| Kati.Screens.MealsToday (43) | the seven week-strip day cells (Mon 10 … Sun 16, with pips) | nowhere | none | `lib/kati/screens/meals_today.ex:540-595` |
| Kati.Screens.MealPlan (44) | Week / Day / Shop segmented strip | nowhere | none | `lib/kati/screens/meal_plan.ex:356-360` |
| Kati.Screens.MealPlan (44) | any of the 35 matrix cells | nowhere | none | `lib/kati/screens/meal_plan.ex:491-509` |
| Kati.Screens.MealPlan (44) | the day list under the matrix (Brunch 10:00 / Snack 16:00 / Dinner 19:30) | nowhere — should reach Kati.Screens.Meal (45) | none | `lib/kati/screens/meal_plan.ex:617-639` |
| Kati.Screens.Meal (45) | the five ingredient rows | nowhere — board says they tick off into the shopping list | none | `lib/kati/screens/meal.ex:856-900` |
| Kati.Screens.MealSwap (46) | the three candidate cards (Cod / Tofu poke / Steak) | nowhere — should set :picked | none | `lib/kati/screens/meal_swap.ex:418-470` |
| Kati.Screens.Shopping (48) | every control on the board — 9 tick boxes, the By aisle / By meal / Missing only chips, "Send list", the add… | nowhere | none | `lib/kati/screens/shopping.ex` |
| Kati.Screens.Plans (49) | the three "Activate" pills on the saved plans | nowhere | none | `lib/kati/screens/plans.ex:291-324` |
| Kati.Screens.PlanShare (50) | "Copy link" and "Share" pills under the QR | nowhere | none | `lib/kati/screens/plan_share.ex` |
| Kati.Screens.PlanShare (50) | "Export this plan" (download) row | nowhere | none | `lib/kati/screens/plan_share.ex:265-267` |
| Kati.Screens.MealReminders (51) | every switch on the board — "List what needs prep", "Flag missing ingredients", Quiet hours, Skip when busy,… | nowhere | none | `lib/kati/screens/meal_reminders.ex` |
| Kati.Screens.MealsDay (52) | any of the eleven spine rows (meals, the run, the dentist, the episode) | nowhere — should reach 45 and 31 | none | `lib/kati/screens/meals_day.ex:309-380` |
| Kati.Screens.MealLibrary (116) | "Search your meals" field | nowhere | none | `lib/kati/screens/meal_library.ex:176-198` |
| Kati.Screens.MealEdit (118) | the meal title, the Method block, and the two "in an active plan" rows (event_upcoming, Keep the history swit… | nowhere | none | `lib/kati/screens/meal_edit.ex:876-880` |
| Kati.Screens.AddIngredient (119) | Name / Quantity / Unit rows and "Type it in" | nowhere | none | `lib/kati/screens/add_ingredient.ex:191-215` |
| Kati.Screens.Week (17) | any of the seven lanes; the chevron_left / chevron_right week arrows | nowhere | none | `lib/kati/screens/week.ex` |
#### Health (2)

| From | Control | Should reach | Carries | Proof |
|---|---|---|---|---|
| anywhere in the app | no control exists | GoalsEmpty (105) | n/a | `test/kati/app_reachability_test.ex` |
| anywhere in the app | no control exists | HealthEmptyStates (113) and its "Nothing in Health set up" state | n/a | `test/kati/app_reachability_test.ex` |
#### Money (1)

| From | Control | Should reach | Carries | Proof |
|---|---|---|---|---|
| MoneyFa (127, the Persian picture of 122) — every service row | :open_subscriptions_<Name> (money_fa.ex:566, reusing Kati.Screens.Money.subscription_tag/1) | Kati.Screens.SubscriptionsFa — a module that does not exist | nothing | `lib/kati/screens/money_fa.ex:1066-1068` |
#### Calendar (15)

| From | Control | Should reach | Carries | Proof |
|---|---|---|---|---|
| Kati.Screens.Calendar (02) | the `Today` pill in the month row | should put the day strip back on today | none | `lib/kati/screens/calendar.ex:365-380` |
| Kati.Screens.Calendar (02), permission-denied empty card | the sentence "Allow Calendars in Settings, under This device." | Kati.Screens.Account (40) | none | `lib/kati/screens/calendar.ex:638` |
| Kati.Screens.Day (09) | any timeline event card | Kati.Screens.EventDetail (31) | the occurrence's id | `lib/kati/screens/day.ex:956-1009` |
| Kati.Screens.Week (17), MonthGrid (16), Agenda (30) | the dock's `calendar_month` Calendar tab | Kati.Screens.Calendar (02) | none | `lib/kati/screens/root.ex:219-221` |
| Kati.Screens.Week (17) | a day lane | the named-day card underneath it | which lane | `test/design/screens/17.html` |
| Kati.Screens.Week (17) | the header's `chevron_left` / `chevron_right` | the previous / next week | a week start date | `test/design/screens/17.html` |
| Kati.Screens.Week (17) | an event row in the day card | Kati.Screens.EventDetail (31) | the event id | `lib/kati/screens/week.ex:253-286` |
| Kati.Screens.EventDetail (31) | the ink `Save` pill | a write to Kati.Calendars.Event | the edited event | `lib/kati/screens/event_detail.ex:360-378` |
| Kati.Screens.EventDetail (31) | the outlined `Delete event` bar | a tombstone / destroy | the event id | `lib/kati/screens/event_detail.ex:860-884` |
| Kati.Screens.Calendars (32) | each calendar's visibility switch (Personal / Work / Family / Birthdays) | Kati.Calendars.Calendar.visible, and thence screens 02 and 09 | the calendar id and the new boolean | `lib/kati/screens/calendars.ex:317-325` |
| Kati.Screens.MealsDay (52) | any spine row (five meals plus six other items) | Kati.Screens.Meal (45) or Kati.Screens.EventDetail (31) | the meal / event id | `lib/kati/screens/meals_day.ex:309-360` |
| Kati.Screens.MealsDay (52) | an unlogged meal's hollow ring | a Kati.Meals.MealLog write | the meal id | `lib/kati/screens/meals_day.ex:381-388` |
| Kati.Screens.Account (40), "What Kati is allowed to do" | the Calendars row's `Allow` pill | the OS calendar dialog | the :calendar capability | `lib/kati/screens/account.ex:658-670` |
| Kati.Screens.Home (01) | the "Rest of today" timeline rows | Kati.Screens.EventDetail (31) | the event id | `lib/kati/screens/home.ex:192` |
| Kati.Screens.ScheduleFa (56, the Persian Schedule root) | any of the seven day cells, or any of the five timeline rows | a selected day / Kati.Screens.EventDetail (31) | the date / the event id | `lib/kati/screens/schedule_fa.ex` |
#### Home and search (15)

| From | Control | Should reach | Carries | Proof |
|---|---|---|---|---|
| Kati.Screens.Home (01) | "Continue watching" card (either of the two) | Kati.Screens.Series (04) / Kati.Screens.Film (08) | the tracked title's id and kind | `lib/kati/screens/home.ex:864` |
| Kati.Screens.Home (01) | "Rest of today" timeline row | Kati.Screens.EventDetail (31) | event id | `lib/kati/screens/home.ex:1196` |
| Kati.Screens.Home (01) | "See all" beside the Rest of today eyebrow | Kati.Screens.Calendar (02) or Kati.Screens.Agenda (30) | today's date | `lib/kati/screens/home.ex:295` |
| Kati.Screens.Search (19) | title result card (chevron_right drawn on it) | Kati.Screens.Film (08) / Kati.Screens.Series (04) | the cached title's {source, source_id} and kind | `lib/kati/screens/search.ex:706-737` |
| Kati.Screens.Search (19) | Calendar group row | Kati.Screens.EventDetail (31) | event id | `lib/kati/screens/search.ex:780-814` |
| Kati.Screens.Search (19) | Notes group cream card | the book/watch the note belongs to | note id or Kati.Books.Note.book_id | `lib/kati/screens/search.ex:845-890` |
| Kati.Screens.Search (19) | recent-search chip | a re-run of that query on this page | the query string | `lib/kati/screens/search.ex:963-989` |
| Kati.Screens.SearchIdle (86) | Books / Music / Meals / Money scope chips | results in those scopes | the query | `lib/kati/search/query.ex:52-64` |
| Kati.Screens.SearchIdle (86) | "Clear" on the Recent eyebrow | forget the search history | none | `lib/kati/screens/search_idle.ex:223` |
| Kati.Screens.Search (19) | narrowing to a scope that has nothing while another scope has hits | board 89's cross-scope card ("Nothing in Calendar. 3 matches in Screen →") | the scope that does have hits | `lib/kati/screens/search.ex:531-538` |
| Kati.Screens.Search (19) | the offline condition | board 89's "Offline — still searching" card | none | `lib/kati/screens/search_result_states.ex:576-605` |
| Kati.Screens.Inbox (05) | the settings cog on the watcher card | Kati.Screens.ReleaseWatcher (25) | none | `lib/kati/screens/inbox.ex:624` |
| Kati.Screens.Inbox (05) | the "Mark all" pill | tick every Out now episode | the out_now set | `lib/kati/screens/inbox.ex:502-528` |
| Kati.Screens.Inbox (05) | an Out now or Coming up row | Kati.Screens.Series (04) / Season (34) / Film (08) | the title's {source, source_id} | `lib/kati/screens/inbox.ex:644-703` |
| Kati.Screens.WhatFits (13) | the five window buttons (20m / 30m / 45m / 1h / 2h+) | a re-filtered list on this same page | the chosen minutes | `lib/kati/screens/what_fits.ex:231-241` |
#### Settings, import and backup (9)

| From | Control | Should reach | Carries | Proof |
|---|---|---|---|---|
| Settings (24), Sections group — five switches (Screen, Books, Music, Habits, Money) | row taps switch_<title> | a local assign only — nothing is persisted | none | `lib/kati/screens/settings.ex:800-801` |
| Accessibility (41), the 235% Up next specimen card | the two 60pt buttons `Resume` and `Mark watched` | nowhere — both are plain Boxes | none | `lib/kati/screens/accessibility.ex:286-314` |
| Data sources (80), TMDB card | the two chips `Use Kati's key` / `Use my own key` | nowhere — Kati.UI.chip/2 is called without :on_toggle, so no on_tap is emitted at all | none | `lib/kati/screens/data_sources.ex:173` |
| Data sources (80), Cached metadata card | the `Refresh` and `Clear` action pills | nowhere — SettingsList.action_pill/1 emits no on_tap | none | `lib/kati/screens/data_sources.ex:438` |
| Data sources (80), a connected tier-2 row (its trailing control reads `Disconnect`) | row tap connect_<id> | the same screen with :expanded toggled — it does not disconnect anything | the source id | `lib/kati/screens/data_sources.ex:219` |
| Your year (07), "Recently watched" cards | the three poster cards | nowhere — recent_row/1 emits no on_tap, and the @destinations entry for "Recently watched" is unreachable bec… | none | `lib/kati/screens/stats.ex:775-800` |
| تنظیمات (62), داده‌ها group درون‌ریزی (Import) row | row with a drawn chevron_left | nowhere — "download" is not a key in SettingsFa's glyph-keyed @destinations | none | `lib/kati/fa/sample_settings.ex:104-110` |
| تنظیمات (62), ظاهر group اندازه متن (Text size) row | row with a drawn chevron_left | nowhere | none | `lib/kati/fa/sample_settings.ex:71` |
| Settings (24) @destinations | three map keys with no row behind them: "Accessibility", "Account", "States" | Accessibility, Account, Kati.Screens.States | none | `lib/kati/screens/settings.ex:653` |
#### The Persian side (4)

| From | Control | Should reach | Carries | Proof |
|---|---|---|---|---|
| ScheduleFa (56) filter chips | همه / نمایش / شخصی / مالی | the same page, filtered | the chip index | `lib/kati/screens/schedule_fa.ex:410` |
| BookDetailFa (69) action row | تمام کردم (finish) | the store, then Rating | the book | `lib/kati/screens/book_detail_fa.ex:587` |
| MoneyFa (127) ledger | a service row (open_subscriptions_<Name>) | MyServicesFa (97), per this module's own moduledoc | the service name is in the tag and discarded | `lib/kati/screens/money_fa.ex:566` |
| HomeFaEmpty (158) Today card | the تقویم همچنان کار می‌کند card (open_calendar) | ScheduleFa (56) | none | `lib/kati/screens/home_fa_empty.ex:309-310` |


---

## Phase 3 — real data where the screens still invent it

**77 `*Sample` modules, 630 call sites in `lib/`.**

`Kati.ScreenSampleOnlyTest`'s `@on_sample` names only five screens — 06, 11, 18,
22 and 23 — because it ratchets screens whose *entire* content is invented. The
survey counted every call site, which is the larger and more honest number:

```
79  Kati.Library.Sample       33  Kati.Money.Sample      25  Kati.Settings.Sample
58  Kati.Music.Sample         33  Kati.Health.Sample     24  Kati.Stats.Sample
53  Kati.Stats.ShareSample    29  Kati.Services.Sample   23  Kati.Meals.SampleLibrary
38  Kati.Books.Sample         27  Kati.Meals.SamplePlan  23  Kati.Health.WeightSample
                              27  Kati.Import.Sample     23  Kati.Calendar.SampleDay
```

Two of these cannot be retired by wiring alone and should not be attempted in
this phase: `Kati.Screens.AddTitle` and `Kati.Screens.Discover` invent their
results because **there is no catalogue** — until a real source lands, every
search result is fiction, which is exactly why screen 154's *Add by hand* form
exists.

Phase 3 depends on Phase 1: a screen cannot show the right row until it is told
which row it is about.

### The 35 doors that are already wired and still name nothing

`Kati.ScreenParamsSweepTest`'s `@empty_builders` is this phase's work as a list,
and it is a list nobody has to keep by hand. Each entry is a door that **is**
wired — the tap resolves the row it was drawn from and hands it to the
destination's `params_for/1` — where the row is the screen's own fixture and
carries no id, so the builder answers `%{}` and the reader is handed nothing.

    MealLibrary        6 tiles → MealEdit          Kati.Meals.SampleLibrary has no :id
    MealsToday         5 cards → Meal              Kati.Meals.SampleToday has no :slot_id
    MealEdit           6 rows  → AddIngredient     borrowed: the editor itself opened on %{}
    LibraryFa          6 tiles → SeriesFa          six literals with an artwork seed
    ArtistDetail       4 rows  → AlbumDetail       Kati.Music.Sample.artist_albums/0
    AlbumDetail(+Fa)   4 doors → LogListen/Artist  Kati.Music.Sample.album/0
    BookDetail ×3      3 doors → LogProgress       Kati.Books.Sample.detail/0
    Meal               1 door  → MealSwap          a drawn meal has no :slot_id

**No edit to any push can shorten this list.** It ends one domain at a time, as
each shelf stops drawing a fixture and starts reading its table — which is
exactly what this phase is. `{Kati.Screens.Books, :log_progress, LogProgress}`
sits in the *other* inventory, `@bare_pushes`, and the pair is the clearest
statement in the codebase of what the two lists mean: same hero, same missing
id, one door that never tried to name it and three that tried and got `%{}`.
Both end on the day screen 20's shelf moves onto `Kati.Books.Book`.


---

## Phase 4 — blocked on a drawing

**139 of the 411 connections wait on a surface nobody has drawn.**

Behind them the survey named **133 things it believed the design had never
drawn**. A second, adversarial pass re-checked every one against the board HTML,
defaulting to *not missing*. A claim survived only if a person cannot do a real
thing today **and** the reason is that nobody has drawn the surface. Three tests
killed the rest:

- **it is drawn** — the control is in the board after all;
- **it is drawn on a sibling** — drawn on the music board and not the TV one is
  *unimplemented*, not undrawn, and asking for it again wastes a drawing;
- **it is not a design problem** — a missing route argument, a missing column or
  a missing capability wearing a design problem's clothes.

What survived is grouped into the briefs below, following `D-34`'s example: one
brief per design *problem*, not per control. `D-34` covers eight boards in one
file because it was the same problem eight times.

Each brief is self-contained and carries the house style — hand one file to
Claude Design and it can draw from it without reading this repository.

### What the second pass threw out

**133 claims went in. 74 survived. 59 died**, and the way they died is the most
useful thing in this document — most of what looked like missing design was
missing code:

| Why it died | Count | Meaning |
|---|---|---|
| **It is a code ticket wearing a design problem's clothes** | 32 | route argument, missing handler, a screen drawn and unwired end to end |
| **It is drawn — on the board, or on a sibling** | 10 | e.g. the `tune` disc on 03 is drawn on 146; the auto-detect mode switch is drawn on 150 |
| **It is already filed** | 3 | `D-34` already asks for the numbering row on 35 and the long-press hint on 04 |
| **The platform cannot do it** | 2 | the OS share sheet is not a board anyone can draw |
| **Other — column, decided-against, out of scope** | 12 | |

Two examples worth keeping, because they are the shape of the mistake:

- *"a poster tile that opens the title it shows"* — `03` draws the tiles and
  `04`/`08`/`14`/`34`/`35` draw the pages. **Nothing is undrawn.**
  `film.ex:29-33` says it plainly: Library *"taps a poster and pushes
  `Kati.Screens.Film` with no title attached"*. That is Phase 1, not a drawing.
- *"screen 34 has no live controls"* — `34.html` draws the Aired/Absolute/DVD
  strip, both switches, the ⋯ disc and nine episode rows.
  `grep -c on_tap lib/kati/screens/season.ex` returns **0**. The board is
  complete; the screen is inert. That is Phase 2.

### The briefs

| Brief | Area | Asks for | What a person cannot do today |
|---|---|---|---|
| [`D-35-the-tune-disc-with-no-sheet.md`](design-briefs/D-35-the-tune-disc-with-no-sheet.md) | Films & TV | 167–168, plus edits to 10 and 11 | The `tune` disc drawn on Up next and Discover has no destination, because board 145's caption names only screens 03, 20… |
| [`D-36-the-rows-behind-the-log-sheets-chevrons.md`](design-briefs/D-36-the-rows-behind-the-log-sheets-chevrons.md) | Films & TV | 169-171, plus edits to 33 and 144 | Three sheets and two edits for board 33's four undrawn destinations — Watched on, Where, With and `+ tag` — settling fi… |
| [`D-37-doors-off-the-book-page.md`](design-briefs/D-37-doors-off-the-book-page.md) | Books | 172–175 (Next in series, Lending, Content war… | Board 66 draws five controls — series, lending, content warnings, page count and Rate & review — whose destinations are… |
| [`D-38-a-book-onto-the-shelf.md`](design-briefs/D-38-a-book-onto-the-shelf.md) | Books | 176–177, plus edits to 06, 20, 89, 154, 155,… | Two new boards — the Persian Books shelf (176) and the Book state of the add-by-hand form (177) — plus six edits, closi… |
| [`D-39-the-read-only-music-shelf.md`](design-briefs/D-39-the-read-only-music-shelf.md) | Music | 178–180 new, plus edits to 06, 21, 154, 155 a… | The music domain is fully built and fully readable with no write surface drawn anywhere — three new boards (an add-a-re… |
| [`D-40-lists-that-open-and-accept.md`](design-briefs/D-40-lists-that-open-and-accept.md) | Music | 181-182 new, plus edits to 12, 66, 68, 74 and… | The list-detail screen screen 12's chevrons point at, drawn holding a film, a book and an album so the row shape is set… |
| [`D-41-the-plan-screen-that-cannot-make-a-plan.md`](design-briefs/D-41-the-plan-screen-that-cannot-make-a-plan.md) | Meals | 183–184 new, plus redraws of 49, 43 and 44 (a… | One brief for the three things board 49 claims a plan owns — its meals, its targets and its reminder times — none of wh… |
| [`D-42-what-a-meals-dots-and-chevrons-open.md`](design-briefs/D-42-what-a-meals-dots-and-chevrons-open.md) | Meals | 185–186, plus edits to 43, 45 and 118 | Two sheets — a meal overflow and an ingredient editor — for the three Meals affordances that open nothing: 43's per-mea… |
| [`D-43-medication-you-can-own.md`](design-briefs/D-43-medication-you-can-own.md) | Health | 187–188 new, plus an edit to 112 | Screen 112 draws a complete medication page whose every ownership control opens nothing — so this brief draws the add s… |
| [`D-44-nothing-recorded-can-be-changed.md`](design-briefs/D-44-nothing-recorded-can-be-changed.md) | Health | 189–190, plus edits to 104, 106 and 109 | Both of Health's hand-made record types — a weight reading and a goal — can be created and never opened, corrected or d… |
| [`D-45-the-persian-write-path.md`](design-briefs/D-45-the-persian-write-path.md) | Health | 191–192, plus annotations to 115 and 108 | Persian mirrors of the log-weight and new-goal sheets, so 115's and 108's `add` discs stop pushing English, LTR screens… |
| [`D-46-the-rows-that-lead-nowhere.md`](design-briefs/D-46-the-rows-that-lead-nowhere.md) | Money | 193–195, plus edits to 122, 23, 92, 93 and 12… | Three new artboards — one service, one expense, the 47-service catalogue — and five board edits that give the money sec… |
| [`D-47-the-two-money-overflow-discs.md`](design-briefs/D-47-the-two-money-overflow-discs.md) | Money | 196 (new, five bands in 27's manner), plus an… | One artboard drawing the panel behind the two money `more_horiz` discs — four rows on 122 (Add an expense, Money on the… |
| [`D-48-three-chevrons-that-open-nothing.md`](design-briefs/D-48-three-chevrons-that-open-nothing.md) | Calendar | 197–199 new, plus an edit to 31 | Board 31's `Repeats`, `Alerts` and `Location` rows each end in a chevron with no destination drawn anywhere in 01–166;… |
| [`D-49-nothing-behind-32s-accounts.md`](design-briefs/D-49-nothing-behind-32s-accounts.md) | Calendar | 200–202, plus an edit to 32 | The whole accounts group on board 32 is drawn and leads nowhere — no connect flow, no account page, and a Stale account… |
| [`D-50-the-two-inboxes-behind-homes-header.md`](design-briefs/D-50-the-two-inboxes-behind-homes-header.md) | Home & search | 203–205 (three new artboards), no edits to ex… | Home's header opens two inboxes and neither has the drawing it needs: screen 05 falls back to Kati.Library.Sample's thr… |
| [`D-51-promises-with-no-page-behind-them.md`](design-briefs/D-51-promises-with-no-page-behind-them.md) | Home & search | 206–207, plus an edit to 19 | Board 88's "See all 12 →" row and the one-group list it opens, plus the four quick-add kinds whose chips board 18 draws… |
| [`D-52-header-controls-that-open-nothing.md`](design-briefs/D-52-header-controls-that-open-nothing.md) | Settings | 208, plus edits to 24, 62, 39 and 41 | Settles what a settings-family header disc does: the four inert discs on 24, 62, 39 and 41 come off, and new board 208… |
| [`D-53-chevrons-with-no-room.md`](design-briefs/D-53-chevrons-with-no-room.md) | Settings | 209-215 (seven new artboards), plus annotatio… | Eight rows on boards 24, 40 and 54 draw a chevron with nothing behind it: one brief for the five locale-override picker… |
| [`D-54-surfaces-the-record-never-covered.md`](design-briefs/D-54-surfaces-the-record-never-covered.md) | Settings | 216, 217, 218, plus one edit to 150 | Draws the three screens the gallery still carries on @undrawn — Sync, the notifications inbox and its diagnostic — and… |
| [`D-55-settings-a-persian-install-has.md`](design-briefs/D-55-settings-a-persian-install-has.md) | Persian | 219-225 (زبان, تقویم, اعداد, شروع هفته, انداز… | Board 62 draws nine chevrons and only two of them open a Persian page — this brief draws the three Persian-only pickers… |
| [`D-56-the-dead-tiles-on-every-persian-root.md`](design-briefs/D-56-the-dead-tiles-on-every-persian-root.md) | Persian | 226–240 (fifteen new artboards), plus edits t… | Fourteen drawn-but-dead controls across all six Persian roots — the FAB, 55's عادت‌ها tile, 56's day cells and event ro… |
| [`D-57-sheets-that-change-language-mid-gesture.md`](design-briefs/D-57-sheets-that-change-language-mid-gesture.md) | Persian | 241–247 (seven new artboards), no board edits | The seven sheets and pickers a Persian detail board pushes mid-gesture — rating, log a listen, release watcher, new goa… |


---

## Phase 5 — blocked on a column

**41 connections. The app cannot record the thing the control would change.**

These are not design problems and not wiring problems. Each needs a migration
and an Ash resource change before its control can mean anything. They are listed
so that nobody wires them by inventing a place to put the value.

The recurring ones, and what they need:

| Missing | Where it bites | Note |
|---|---|---|
| `{source, source_id}` on `Kati.Calendars.Event` | an `:air_date` row cannot reach the `CachedEpisode` that produced it | stated at `lib/kati/screens/day.ex:87-95` |
| an alerts column on `Kati.Calendars.Event` | screen 31's Alerts row | *"alerts have no column at all"* — `event_detail.ex:107-109` |
| an attendee table | screen 31's attendees | `event_detail.ex:105-108` |
| a section column on `Kati.Calendars.Event` | screen 31's section row | `event_detail.ex:96-100` |
| a reminders table / `remind_on` on `Kati.Services.Service` | *"Remind me"* on 77 and 23 | the scheduler only plans from the six collectors in `lib/kati/notifications/sources/` |
| `writeback_policy` is per calendar | screen 32 needs it per account | *"the wrong axis"* — `calendars.ex:68-75` |


#### Films and television (13)

| From | Control | Should reach | Carries | Proof |
|---|---|---|---|---|
| Series (04) progress card | bookmark disc and star disc | nothing | n/a | `lib/kati/screens/series.ex:884-893` |
| Discover (11) "People you follow" card | three person rows | no person screen exists | the person | `lib/kati/screens/discover.ex:437-467` |
| Season (34) order strip | Aired / Absolute / DVD, three 34pt tiles | should renumber the list | n/a | `lib/kati/screens/season.ex:397-460` |
| Season (34) options card | "Include specials" and "Merge multi-part" switches | should change the running order | n/a | `lib/kati/screens/season.ex:464-479` |
| Series settings (35) | Status tiles (Watching/Paused/Dropped), the four season-pass switches, Region/My services/Preferred quality r… | should write Kati.Media.TrackedTitle | n/a | `lib/kati/screens/series_settings.ex:95-98` |
| Series metadata (14) | "Trailer" play button, bookmark disc, label disc, four cast rows, three Where-to-watch rows, `+ tag`, the syn… | nothing | n/a | `lib/kati/screens/series_meta.ex:393-425` |
| Rating (33) tags row | `+ tag` pill, on_tap :add_tag | nothing | n/a | `lib/kati/screens/rating.ex:1350-1364` |
| Auto-detect (36) | the "Detect what you play" master switch, four source switches (Apple TV / Chromecast / Browser extension / T… | should store a detection preference / resolve the match | n/a | `lib/kati/screens/auto_detect.ex` |
| Auto-detect — music (150) | the four app switches (Spotify, YouTube Music, Poweramp, Everything else) and the three release-disambiguatio… | should store an allow-list | n/a | `lib/kati/screens/auto_detect_music.ex:67-72` |
| Numbering (153) | the "Override" and "Reset" pills | should set a per-show numbering scheme | n/a | `lib/kati/screens/numbering_scheme.ex:28-42` |
| Anime — a type, not a section (152) | no route in at all | n/a | n/a | `test/kati/app_reachability_test.ex` |
| Release watcher (25) | the master switch, ten kind/loudness rows, four cadence segments | should store watcher preferences | n/a | `lib/kati/screens/release_watcher.ex:256-280` |
| Dropping — the sheet and after (149) | the six reason chips (Lost interest, Too slow, Not for me, Too long, Bad time for it, Might come back) | should be stored with the drop | the reason | `lib/kati/screens/drop_sheet.ex:743-747` |
#### Books (2)

| From | Control | Should reach | Carries | Proof |
|---|---|---|---|---|
| BookDetail (66), action row | "Add to list" circular second, tag :add_to_list | Kati.Screens.Lists (12) | the book to add | `lib/kati/screens/book_detail.ex:1015-1016` |
| BookDetail (66), Content warnings band | "Warnings 3 / expand_more" row | the expanded warnings list | the book | `lib/kati/screens/book_detail.ex:699-712` |
#### Music (4)

| From | Control | Should reach | Carries | Proof |
|---|---|---|---|---|
| Kati.Screens.AlbumDetail (74) | the circular "Add to list" second (bookmarks, :add_to_list) | Kati.Screens.Lists (12) | should carry the album; carries nothing | `lib/kati/screens/album_detail.ex:800-801` |
| Kati.Screens.ArtistDetail (77) | "Remind me" on the unheard-release card (:remind_me) | Kati.Screens.ReleaseWatcher (25) | should carry the release (Estuary Tapes); carries nothing | `lib/kati/screens/artist_detail.ex:601-602` |
| Kati.Screens.ArtistDetail (77) | "Dismiss" on the unheard-release card (:dismiss_release) | hides the card for this render only | none | `lib/kati/screens/artist_detail.ex:604-610` |
| Kati.Screens.YearShare (98) | the "Hide titles I marked private" switch (:toggle_private) | sets :hide_private; nothing consumes it, and nothing can mark a title private | none | `lib/kati/screens/year_share.ex:328-329` |
#### Meals (5)

| From | Control | Should reach | Carries | Proof |
|---|---|---|---|---|
| Kati.Screens.MealsToday (43) | prep card secondary "Done prepping" | nowhere | none | `lib/kati/screens/meals_today.ex:1252-1268` |
| Kati.Screens.MealSwap (46) | filter chips "Closest macros / Faster / In my fridge" | nowhere | none | `lib/kati/screens/meal_swap.ex:340-402` |
| Kati.Screens.Plans (49) | Switching group — "Switch takes effect ›", "Keep the history" switch, "Auto-switch" switch | nowhere | none | `lib/kati/screens/plans.ex:340-367` |
| Kati.Screens.PlanShare (50) | "What travels with it" switches and the "Shared with" people rows | nowhere | none | `lib/kati/screens/plan_share.ex:241-256` |
| Kati.Screens.PlanImport (120) | every control — the "Import 35" pill, the three conflict pills (Keep mine / Take file / Keep both), "1 of 2 ·… | nowhere | none | `lib/kati/screens/plan_import.ex:113-116` |
#### Health (1)

| From | Control | Should reach | Carries | Proof |
|---|---|---|---|---|
| NewGoal (106) | Save goal, tag :save | a Kati.Goals.Goal row, then pop back to 104 | kind, target, period, window, repeat — but never progress | `lib/kati/screens/new_goal.ex:288-297` |
#### Money (2)

| From | Control | Should reach | Carries | Proof |
|---|---|---|---|---|
| Money (122) — suggestion card | :remind_me ("Remind me 23 Aug", money.ex:425) | ReleaseWatcher (25), Kati.Screens.ReleaseWatcher | nothing | `lib/kati/screens/money.ex:453-454` |
| Subscriptions (23) — "Remind me 23 Aug" | :remind (subscriptions.ex:507) | same screen, button changes weight | n/a | `lib/kati/screens/subscriptions.ex:629-631` |
#### Calendar (5)

| From | Control | Should reach | Carries | Proof |
|---|---|---|---|---|
| Kati.Screens.Calendar (02) | air-date / "3 titles airing" card | Kati.Screens.Film (08) | should carry an episode or title id; carries nothing | `lib/kati/screens/calendar.ex:1194` |
| Kati.Screens.Day (09) | a todo's leading ring (`todo_<id>`) | a persisted tick | the occurrence id | `lib/kati/screens/day.ex:1550-1558` |
| Kati.Screens.EventDetail (31) | the dashed `Add someone` ring | an attendee picker | the event id | `lib/kati/screens/event_detail.ex:824-840` |
| Kati.Screens.EventDetail (31) | the `Personal` / `Work` section chips | a stored section on the event | the chosen section | `lib/kati/screens/event_detail.ex:890-900` |
| Kati.Screens.Calendars (32) | the three `Write back` switches — Air dates / Habits / Renewals | a per-category push preference | the category and the boolean | `lib/kati/screens/calendars.ex:358-366` |
#### Home and search (3)

| From | Control | Should reach | Carries | Proof |
|---|---|---|---|---|
| Kati.Screens.SearchIdle (86) | either "Try" suggestion row | Kati.Screens.Search (19) with matches | the suggestion as a query | `lib/kati/screens/search_idle.ex:248-256` |
| Kati.Screens.WhatFits (13) | the four mood chips (Any mood / Light / Tense / Long-form) | a mood-filtered list | the mood | `lib/kati/screens/what_fits.ex:263-279` |
| Kati.Screens.WhatFits (13) | the "Tomorrow" pill on the over-budget row | deferring that title to tomorrow | the title and a date | `lib/kati/screens/what_fits.ex:396-409` |
#### Settings, import and backup (5)

| From | Control | Should reach | Carries | Proof |
|---|---|---|---|---|
| Language (54), Content group "Units" row and "Title language" switch | chevron row / switch, neither carrying an on_tap | nowhere | none | `lib/kati/language/sample.ex:99-106` |
| Import — where are you coming from (140), the six source tiles (Goodreads, StoryGraph, Letterboxd, Trakt, MyA… | tile taps source_goodreads … source_anilist | Kati.Screens.ImportRecognised (141), pushed with no argument | nothing — the source id is parsed off the tag and thrown away | `lib/kati/screens/import_sources.ex:128-135` |
| Import — recognised (141), "Check the mapping" summary row | tap :check_mapping | Kati.Screens.Import (37) | none — 37 always draws the fixed Trakt fixture | `lib/kati/screens/import_recognised.ex:582-584` |
| Import (37) — the whole screen | the three conflict pills (Keep mine / Take file / Keep both), the step meter, the header's `Import 412` pill,… | nowhere — the file contains zero on_tap props | none | `lib/kati/screens/import.ex` |
| Restore (129), "Conflicts · keep which?" card | the three pills Keep mine / Take file / Keep both, and the '1 of 6 · apply to all' meter | nowhere — Kati.Screens.Import.choice/1 builds a MishkaToggle with no tap | none | `lib/kati/screens/restore.ex:841-878` |
#### The Persian side (1)

| From | Control | Should reach | Carries | Proof |
|---|---|---|---|---|
| RestoreFa (132) | the file row, the scan card, the three conflict pills (مال من / فایل / هر دو), Merge and Replace | the restore engine | the picked file and the answered conflict | `lib/kati/screens/restore_fa.ex:783-785` |


---

## Phase 6 — blocked on a capability

**27 connections. Not this version.**

The platform, or the app's own decisions, cannot do these yet. They are recorded
so the boards that draw them are not read as bugs:

- **No natural-language parser anywhere in `lib/`.** Screen 18's *QuickAdd*
  sentence — "watch Dune on Friday" — has nothing to parse it.
  `test/kati/screen_sample_only_test.exs:19` records this.
- **No dictation.** The microphone on the search and quick-add fields has no
  destination; there is no dictation fence in `native/LEDGER.md`.
- **Root screens cannot take a route argument** (`root.ex:106`), so Week, Month
  and Agenda on screen 09 cannot be opened *about* a date until that macro
  changes. Day can, and does.
- **No catalogue.** Everything a search finds is invented. See Phase 3.


#### Films and television (3)

| From | Control | Should reach | Carries | Proof |
|---|---|---|---|---|
| Up next (10) hero card and four ready rows | five `play_arrow` discs | nothing | n/a | `lib/kati/screens/up_next.ex:609-616` |
| Library (03) poster tile | long press | ShelfSelection (146) | the tile | `test/design/screens/03.html` |
| Series (04) episode row | long press | RateEpisode (144) | the episode | `test/design/screens/04.html` |
#### Music (3)

| From | Control | Should reach | Carries | Proof |
|---|---|---|---|---|
| Kati.Screens.YearShare (98) | the ink "Save image" button (:save_image) | Kati.Screens.YearCards (100) | should carry the chosen scope and aspect; carries nothing | `lib/kati/screens/year_share.ex:334-335` |
| Kati.Screens.YearShare (98) | the "Share…" affordance with its WHEN FILE SHARING LANDS pill | nothing — it carries no on_tap at all | none | `lib/kati/screens/year_share.ex:290-311` |
| Kati.Screens.YearShareBooks (99) | "Save image", the aspect segments and the privacy switch (@borrowed) | Kati.Screens.YearShare.handle_tap/2, verbatim | none | `lib/kati/screens/year_share_books.ex:133` |
#### Meals (4)

| From | Control | Should reach | Carries | Proof |
|---|---|---|---|---|
| Kati.Screens.PlanShare (50) | "Scan a plan" (qr_code_scanner) and "Import a file" (upload_file) rows | nowhere — the design's own doors into 120 | none | `lib/kati/screens/plan_share.ex:265-267` |
| Kati.Screens.MealEdit (118) | "Add a meal photo" row | nowhere | none | `lib/kati/screens/meal_edit.ex:429-458` |
| Kati.Screens.AddIngredient (119) | "Scan a barcode" and "Search a food database" rows | nowhere (drawn with a NOT IN V1 badge, no tap at all) | none | `lib/kati/screens/add_ingredient.ex:287` |
| Kati.Screens.WeekImage (121) | "Save image" | nowhere | none | `lib/kati/screens/week_image.ex:1055-1059` |
#### Health (3)

| From | Control | Should reach | Carries | Proof |
|---|---|---|---|---|
| LogWeight (111), the Note row | the row with `sticky_note_2` and a chevron | nothing — no tap tag is emitted | n/a | `lib/kati/screens/log_weight.ex:262-278` |
| LogWeight (111), the Today row | `now` pill, tag :now | nothing | n/a | `lib/kati/screens/log_weight.ex:445` |
| NewGoal (106), By when segmented control | Custom chip, tag :period_custom | a silently invented 30-day window | nothing the user chose | `lib/kati/screens/new_goal.ex:313` |
#### Money (2)

| From | Control | Should reach | Carries | Proof |
|---|---|---|---|---|
| QuickAdd (18) — "Or file it as" chip row, Expense chip | :file_as_expense (quick_add.ex:130 kind_tap/1) | QuickAddExpense (124), Kati.Screens.QuickAddExpense | nothing — and there is nothing to carry | `lib/kati/screens/quick_add.ex:134-135` |
| QuickAddExpense (124) — microphone disc beside the commit button | none — drawn with no on_tap | nowhere | n/a | `lib/kati/screens/quick_add.ex:556` |
#### Calendar (1)

| From | Control | Should reach | Carries | Proof |
|---|---|---|---|---|
| Kati.Screens.Account (40) | the `Settings` pill a :blocked permission earns | the Android app-settings screen | none | `lib/kati/permissions.ex:112` |
#### Home and search (3)

| From | Control | Should reach | Carries | Proof |
|---|---|---|---|---|
| Kati.Screens.QuickAdd (18) | "Add to Thursday" commit button | a created Kati.Calendars.Event | the parsed draft | `lib/kati/screens/quick_add.ex:533-534` |
| Kati.Screens.QuickAdd (18) | the sentence field itself | a typed query | keystrokes | `lib/kati/screens/quick_add.ex:195-215` |
| Kati.Screens.QuickAdd (18) | the 52pt microphone | dictation | audio | `lib/kati/screens/quick_add.ex:579-590` |
#### Settings, import and backup (6)

| From | Control | Should reach | Carries | Proof |
|---|---|---|---|---|
| Widgets (39), Shortcuts group "Automations" row | row with a drawn chevron_right | nowhere — shortcut_tap/2 returns nil for a row with no :toggle key | none | `lib/kati/widgets/sample.ex:64-68` |
| Attribution (83), the five source cards and the "Full notice list" row | taps :open_tmdb, :open_justwatch, :open_tvmaze, :open_open_library, :open_musicbrainz, :open_notices | nowhere — the screen's only handler is a catch-all | none | `lib/kati/screens/attribution.ex:337` |
| Restore (129), "Scan from another phone" cream card | the card itself, drawn on the board as an offer | nowhere — scan_card/0 emits no on_tap | none | `lib/kati/screens/restore.ex:446-472` |
| Backup (128), Format group — `Per-section CSV` and `Calendar (.ics)` rows | row taps that really do move the selection mark | Save a backup then answers '<format> is not built yet' | the chosen format | `lib/kati/screens/backup.ex:1199-1214` |
| Notifications help (undrawn), the battery row | tap :open_battery | nowhere — the screen's last clause is a catch-all | none | `lib/kati/screens/notifications_help.ex:205` |
| Notification access (151), both `Open system settings` pills | taps :open_settings and :open_settings_revoked | nowhere | none | `lib/kati/screens/notification_access.ex:262` |
#### The Persian side (2)

| From | Control | Should reach | Carries | Proof |
|---|---|---|---|---|
| YearShareFa (103) | هم‌رسانی… (share) | the OS share sheet | the rendered card | `lib/kati/screens/year_share_fa.ex:713-720` |
| AttributionFa (85) | the four source rows | the platform browser | a URL | `test/kati/screen_tap_sweep_test.ex` |


---

## The todo, in order

- [x] **1.** Give `push_screen/3` its third argument at the 50 Phase 1 call
      sites, and make each destination read `socket.assigns.params`.
      Done in `156410a`, verified on Pixel_9a: three posters, three films.
- [x] **2.** Assert it: `test/kati/screen_params_sweep_test.exs` ratchets every
      door into a params reader that names nothing, and locks the fallback —
      an id that names no row must render what naming nothing renders.
- [ ] **2a.** **Make a popped-to screen re-read.** The largest item in this
      document; see *What the device said* above. Nothing else in Phase 2 or 3
      is worth much until a write is visible when you press back.
- [ ] **3.** Wire the 75 Phase 2 controls, striking each off `@inert_taps` in the
      same commit. Start with the 15 in the Backlog section, whose reasons are
      already written down.
- [ ] **4.** Re-read every stale reason left in `@inert_taps` and `@no_route`.
      Board 145 landing made `books.ex:642` untrue — it still says
      *"no board in the 165 draws a sort sheet for any shelf"* while 145 is
      captioned *"One sheet for screens 03, 20 and 21"*. `@no_route`'s
      header comment still says 47 entries and 105 reachable when the file has
      42 and the sweep reaches 123.
- [ ] **5.** Retire the sample modules a real source can now replace (Phase 3),
      largest first: `Kati.Library.Sample` at 79 call sites.
- [ ] **6.** Hand each brief in `design-briefs/D-35`…`D-57` to Claude Design, one
      at a time. Land the boards in `test/design/incoming/` and move them to
      `screens/` in the commit that builds each screen.
- [ ] **7.** Write the migrations for Phase 5, one resource at a time, and only
      once a board draws the control that needs the column.
- [ ] **8.** Leave Phase 6 alone.

## One note for whoever runs this on a device

`bin/deploy_native.sh` fails the gradle build after every Elixir change, with
`src/e2e/assets/otp.zip is older than _build/dev/lib/kati/ebin`. The guard is
right — an e2e APK shipping stale BEAMs would test code nobody wrote — but the
fix is a second command the script does not run:

```bash
mix kati.e2e.stage && ./bin/deploy_native.sh
```

## What this document is not

It is not a list of bugs in the sweeps. Every number here was read out of the
repo, and the four host sweeps that guard reachability, taps, samples and design
literals all pass at the commit this was written against. The gaps below are
gaps in the *app*, faithfully recorded by tests that were built to record them.
