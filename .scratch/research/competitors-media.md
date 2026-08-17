# Kati vs. the incumbents — media tracking feature gaps & data sources

Research date: **2026-08-17**. Scope: film/TV, books, music tracking products, and the metadata
APIs a **device-only, open-source, no-server** app can legally and practically ship against.

Baseline for "what Kati already covers" is
`/Users/shahryar/Documents/Programming/Elixir/kati/.scratch/research/design-index.md`
(441 lines, the 62-screen design). Every "Kati covers this" claim below cites a line in that file.
Platform constraints come from
`/Users/shahryar/Documents/Programming/Elixir/kati/.scratch/research/mob-framework.md`.

Where I could not verify something from a primary source I say **UNKNOWN** rather than guess.

---

## 0. Executive summary

1. **Kati's film/TV design is at or above the state of the art.** Screens 34 (numbering schemes),
   36 (scrobble disambiguation), 13 (runtime budget), 23 (cost per watched hour) and 09 (calendar
   density) each solve a problem *no* shipping competitor solves well.
2. **Books and music are one-screen stubs.** Screen has a shelf (03), a series tracker (04), a film
   detail (08) and a full-metadata screen (14). Books have *only* a shelf (20). Music has *only* a
   shelf (21). There is **no book detail screen, no album/artist screen, no reading-session logger
   and no listen history** anywhere in the 62. This is the single biggest gap.
3. **The design has no surface for the thing that will actually block shipping**: which metadata
   provider is in use, its attribution, and where the user's own API credentials live. TMDB's terms
   make the attribution a *legal requirement*, and Mob has **no keychain/keystore and no encrypted
   storage** (`mob-framework.md:1384-1388`), so credential handling has to be designed, not assumed.
4. **The data-source answer that makes an open-source, device-only app work is a keyless base tier**
   — TVmaze + Open Library + MusicBrainz/Cover Art Archive — with TMDB shipped the way Jellyfin
   ships it, and Trakt/Last.fm/TVDB as strictly opt-in, user-supplied credentials. Trakt in
   particular **cannot** be shipped: its device-code token exchange requires `client_secret`.
5. **Screen 40 assumes iOS** ("Signed in with Apple · relay address", `design-index.md:136`) while
   the owner's locked decision is Android-first. That screen needs rewriting regardless of anything
   in this document.

---

## 1. Feature gap table

Legend for **Kati**: ✅ covered · 🟡 partial / one media type only · ❌ absent.

### 1.1 Film & TV

| # | Capability | Who does it well | Kati | Suggested screen / flow |
|---|---|---|---|---|
| F1 | Episode-level check-off with season progress | Trakt, TV Time, Simkl, SeriesGuide | ✅ 04 (`design-index.md:89`) | — |
| F2 | Aired / absolute / DVD numbering, specials, multi-part merge | Simkl (anime-native), Sofa; Trakt is weak here | ✅ 34 (`:128`) — best-in-class as drawn | — |
| F3 | Per-title status Watching/Paused/Dropped as an explicit choice | Simkl; Trakt uses implicit state | ✅ 35 (`:129`), and `:440` states it is deliberately *not* a swipe action | — |
| F4 | Global "up next" queue across all shows | Trakt VIP, SeriesGuide, Reelgood "Track Series" | ✅ 10 (`:96`) | — |
| F5 | Stale-queue hygiene ("gone cold", drop suggestion) | **Nobody** | ✅ 10 (`:96`, `:239`) | protect this |
| F6 | Runtime-budget picker ("what fits in 45 min") | **Nobody** (Sofa has moods, not time) | ✅ 13 (`:99`) | protect this |
| F7 | Release calendar of upcoming episodes | Trakt, Simkl, TV Time, Sofa | ✅ 02/05/16/25 (`:87`, `:90`, `:104`, `:116`) | — |
| F8 | "Leaving soon" from your services | Reelgood ("leaving" menu), JustWatch | ✅ 11 (`:97`) | — |
| F9 | Where-to-watch by provider | JustWatch, Reelgood, Plex Discover, TMDB `/watch/providers` | 🟡 08/14 show provider rows (`:93`, `:101`) but there is **no screen where the user declares which services they subscribe to, in which region**; 35 references "My services 3 of 12" and "Region UK" as *per-show* settings (`:129`) | New: **Settings → My services & region** — country picker, service multi-select, "free with ads / rental counts as available" toggles; feeds 08, 11, 13, 14, 23 |
| F10 | Deep link straight into the streaming app | Reelgood, JustWatch, Watchmode (paid tiers) | ❌ | Add a "Play on ⟨service⟩" primary action to 08/14, with an honest fallback: **TMDB's provider endpoint returns no deep links** (see §3.2) |
| F11 | Automatic scrobbling from a player | Trakt (Plex/Kodi/Emby plugins), Simkl | ✅ 36 (`:131`) — including a **disambiguation card**, which real scrobblers get silently wrong | protect this |
| F12 | Diary / dated log of every watch, incl. rewatches | Letterboxd (the diary *is* the product), Serializd | ✅ 15 (`:102`), 08 "Log rewatch" (`:93`) | — |
| F13 | Reviews with half stars, spoiler toggle | Letterboxd, Serializd (half-star per *episode*) | ✅ 33 (`:127`) | — |
| F14 | **Per-episode** rating & review | **Serializd** — this is its whole differentiator | 🟡 33 is drawn as a title/rewatch log; 04's episode rows are tick-only (`:89`) | Extend 04: long-press an episode row → 33 in "episode" mode; add a per-episode star column |
| F15 | Ratings histogram / your rating distribution | Letterboxd, StoryGraph, Serializd | ❌ 07 has genre bars only (`:92`) | Add a band to 07 or a row under "More numbers" → new **Ratings** screen |
| F16 | Year-in-review as a **shareable image** | Letterboxd Year in Review, Spotify Wrapped, Apple Music Replay | ❌ 07 exists (`:92`) but produces no card; the only share surface in the app is 50, and it is for *meal plans* (`:147`) | New: **Stats → Your year → Share** — 3–4 poster-collage cards rendered locally to PNG, no account, no upload |
| F17 | Social feed / friends / following | Letterboxd, Serializd, Trakt, Plex (2026 social update) | 🟡 11 lists "followed people" (`:97`), 12 has shared-list badges (`:98`) | Mostly a **deliberate non-goal** (no server). But wire the *offline* version: import a friend's list from a QR/file exactly as 50 does for meal plans |
| F18 | Household / shared watchlist | Trakt VIP, Plex | ❌ | Low priority; same QR/file mechanism as F17 |
| F19 | Franchise / collection viewing order | Trakt lists, Plex collections | 🟡 12 is manual lists only (`:98`) | Add a "Part of ⟨collection⟩ · 3 of 7" row to 08/14 driven by TMDB `belongs_to_collection` |
| F20 | Anime as a first-class type (seasons ≠ TMDB seasons, MAL/AniList import) | **Simkl** (built for it), Sofa | ❌ | Add an "Anime" filter to 03 and a MAL/AniList CSV importer to 37 (`:132`) |
| F21 | Cost per watched hour per service | **Nobody** | ✅ 23 (`:113`) | protect this — see §5 |

### 1.2 Books

| # | Capability | Who does it well | Kati | Suggested screen / flow |
|---|---|---|---|---|
| B1 | **Book detail screen** | Everyone (Goodreads, StoryGraph, Hardcover, Bookwyrm, Libib) | ❌ **Absent.** Group C "Depth on a title" contains only 14, and 14 is a *series* metadata screen (`:100-102`) | New: **Book detail** — the exact sibling of 08. Cover, author, page/duration, progress, rating, notes, series position, editions |
| B2 | Log a reading session (pages / % / minutes) | StoryGraph, Bookwyrm, Fable | ❌ 20 *displays* "p. 214 / 380 · 23 min/day pace" (`:109`) but nothing writes it | New: **Log progress** modal — page / % / timer, "finished" shortcut, feeds the pace figure |
| B3 | DNF with pages-read still counted | **StoryGraph** (explicit feature) | 🟡 "Abandoned 3" list exists (`:98`); 15 logs "Dropped … after S1E3" (`:239`) — TV-shaped only | Add DNF state + "got to p. N / N%" + reason to B1 and to the status control |
| B4 | Editions & formats (paperback / ebook / audiobook, page count vs runtime) | StoryGraph, Hardcover, Libib; **Goodreads is famously bad at it** | ❌ | Add an **Edition** row to B1: format chips, page count / duration, ISBN, "this is the edition I own" |
| B5 | Reading goal / challenge | Goodreads (books/yr), StoryGraph (books, pages, custom prompts) | 🟡 22 Habits could host it (`:112`) but no goal object exists | New band on 07, or a **Goals** screen under Stats: books, pages, minutes, per-year and per-month |
| B6 | Mood & pace tagging, mood-driven recommendation | **StoryGraph** — its single biggest differentiator | 🟡 13 has *transient* mood chips for picking tonight (`:99`); nothing is recorded | Add mood + pace + character/plot-driven chips to 33, and a mood pie to 07 |
| B7 | Content warnings | **StoryGraph** (author-approved + user-submitted) | ❌ | Add a collapsible "Content warnings" block to B1 and a **Settings → Content I'd rather avoid** list that flags matches in 11/19 |
| B8 | ISBN / barcode scan to add | **Libib** (its core loop), Bookwyrm, most catalogue apps | ❌ 06 is search-to-add only (`:91`); a QR scanner already exists on 50 (`:147`) | Add a **scan** button to 06 — reuse 50's camera path, hit Open Library `/isbn/{isbn}.json` |
| B9 | Physical shelf / ownership / lending | Libib, LibraryThing, CLZ | 🟡 12 has "Owned on disc 22" for discs (`:98`); 14 lists "own Blu-ray shelf" (`:101`) | Extend the same idea to books: Owned / Borrowed / Lent to ⟨name⟩ + due date on B1 |
| B10 | Series position ("#3 of 7") and next-in-series | StoryGraph, Hardcover | ❌ | Same row as F19, driven by Open Library / Hardcover series data |
| B11 | Notes, quotes, highlights with page refs | Bookwyrm (quotes are a post type), Hardcover | 🟡 the cream note card exists on 08 (`:93`, `:182`) | Reuse the cream card on B1; add page-anchored quotes |
| B12 | Import from Goodreads / StoryGraph CSV | StoryGraph's importer is the #1 reason people can switch | 🟡 37 is a **generic** column mapper (`:132`) | Add named presets to 37: Goodreads CSV, StoryGraph CSV, Letterboxd CSV, Trakt JSON, Libib CSV, MAL XML — pre-fill the mapping |
| B13 | Book release calendar (pub dates for followed authors) | Goodreads (weakly), StoryGraph | ❌ 05/25 are drawn around episodes (`:90`, `:116`) | Extend 25's alert types to "New book by a followed author"; the inbox 05 already generalises |

### 1.3 Music

| # | Capability | Who does it well | Kati | Suggested screen / flow |
|---|---|---|---|---|
| M1 | **Album / artist detail screen** | Last.fm, MusicBrainz front-ends, Sofa | ❌ Absent — 21 is a shelf only (`:110`) | New: **Album detail** (tracklist, plays, first/last listened, rating) and **Artist** (albums, play counts, "new from" state) |
| M2 | Listen history / scrobble log | Last.fm, ListenBrainz, Pano Scrobbler | ❌ 15's verbs are watch-shaped: Watched, Rated, Added, Rewatched, Finished, Dropped, Imported (`:102`) | Add a **Listens** scope to 15, or a per-album history band on M1 |
| M3 | Automatic scrobbling from the phone | Pano Scrobbler (Android), Last.fm app | 🟡 36 says "This phone — detects audio from any app" (`:131`) but the screen is drawn entirely around episodes | Add a music mode to 36. On Android this is genuinely reachable — Pano Scrobbler does it with `NotificationListenerService` + `MediaSessionManager` (<https://deepwiki.com/kawaiiDango/pano-scrobbler>), no server, no vendor SDK |
| M4 | Listening clock / time-of-day, weekday patterns | Last.fm listening reports, ListenBrainz | ❌ 21 has a "Listening-time card" (`:110`) | Reuse the pixel field (`:193`) and add an hour-of-day band on 07 |
| M5 | Year-end wrapped, shareable | Spotify Wrapped, Apple Music Replay (Replay updates *weekly*, Wrapped is annual) | ❌ | Same card generator as F16 |
| M6 | Music release calendar for followed artists | Last.fm event/release feeds, Spotify | 🟡 21 has "New from artists you follow" (`:110`), but 25's alert types are TV-shaped (`:116`) | Extend 25 |
| M7 | Play counts / on-repeat | Last.fm, Apple Music Replay | ✅ 21 (`:110`) | — |

### 1.4 Cross-cutting / system

| # | Capability | Who does it well | Kati | Suggested screen / flow |
|---|---|---|---|---|
| X1 | **Metadata source disclosure + legally required attribution** | Jellyfin, SeriesGuide, Moviebase all carry an attribution screen | ❌ 24's About row exists (`:115`); no attribution surface | **New screen, mandatory** — see §3.6 |
| X2 | **User-supplied API credentials** | SeriesGuide (Trakt connect), Jellyfin (per-provider key fields) | ❌ | **New screen: Settings → Data sources** — see §4.4 |
| X3 | Export everything | StoryGraph, Letterboxd, Goodreads, Trakt (VIP), Libib | 🟡 24 has a Data → Export row (`:115`); 50's Export JSON is **meal-plan-scoped** (`:147`) | Promote 50's export mechanics to a whole-library **Export** screen (JSON + per-section CSV) |
| X4 | Named importers, not a raw column mapper | StoryGraph's Goodreads importer | 🟡 37 (`:132`) | See B12 |
| X5 | Offline metadata cache with a stated policy | Jellyfin (local metadata), Plex | 🟡 27 has an offline badge (`:224`) | TMDB forbids caching **longer than 6 months** (§3.1) — this is a data-model requirement and deserves a "Cached metadata · refresh · clear" row on X2 |
| X6 | Bulk edit / multi-select on a shelf | Libib, Goodreads (weakly) | ❌ 03's controls are filter tabs only (`:88`) | Long-press → selection mode on 03/20/21 |
| X7 | Rich sort & filter (year, runtime, rating, unwatched-only) | Reelgood (genre/year/IMDb/RT/service), Libib | 🟡 03 has All / Watching / Finished / Wishlist (`:88`) | Add a filter sheet to 03/20/21 |
| X8 | Duplicate / merge resolution in the library | Goodreads' duplicate-edition problem is its most cited flaw | 🟡 37 resolves conflicts **at import time only** (`:236`) | Add "Merge with…" to the title detail overflow |
| X9 | Account model that matches Android-first | — | ❌ 40 is written as "Signed in with Apple · relay address" (`:136`) | Rewrite 40 as **local-only, no account**; move device sync to file/QR |

---

## 2. Ranked gaps worth adding — paste-ready briefs

Ranked by (impact on the product's credibility) × (cheapness given the existing component set).
Each brief is written to be pasted straight into Claude Design.

**1. Book detail screen (the missing sibling of 08).**
Kati has three levels of depth for film and TV — a shelf, a tracker, and a full-metadata screen — and
exactly one for books: a shelf. Design a book detail screen that is the direct sibling of screen 08
"Film detail", reusing the same elevated card, cream note card, star rating, tag chips and action row.
Above the fold: cover, title, author, and a progress bar showing page 214 of 380 with a "23 min/day
pace" caption in DM Mono. Then the three-rating row from screen 14 (Yours / Community / — books have
no critic score, so drop to two and keep the alignment). Then a status control with the four states
Reading / Finished / Paused / **Did not finish**, where choosing DNF reveals a "got to p. ___" field.
Then an Edition row — format chips (Paperback · Ebook · Audiobook), page count or duration, ISBN, and
a "this is the edition I own" toggle — because the single most-cited Goodreads failure is silently
mixing editions with different page counts. Then a collapsible Content warnings block, then the cream
note card for quotes with page anchors, then a "#3 of 7 in ⟨series⟩" row with next-in-series. Actions:
Log progress · Finish · Rate & review · Add to list.

**2. Log progress modal (reading sessions and listens).**
Screen 20 already *shows* "p. 214 / 380 · 23 min/day pace" but nothing in the 62 screens writes that
number. Design a modal, styled like screen 18 Quick add (centred title, leading close glyph), that
logs one reading session: a segmented control for Page / Percent / Minutes, a big numeric field in DM
Mono with a stepper, an optional "started at" time, and a running "that's 46 pages in 38 minutes ·
your fastest this week" confirmation line above the primary button. Include a start/stop timer mode
for people who read with the phone beside them, and a "Finished the book" shortcut that hands straight
off to screen 33 Rating & review. The same modal in a second variant logs a manual listen for an album
so the music shelf has a write path too.

**3. Settings → Data sources (the API-key screen).**
Kati is open-source and device-only, so it cannot hide a secret, and Mob provides no keychain or
encrypted storage. Design a settings screen that makes this honest and usable. Top section "Working
out of the box" lists the keyless providers Kati ships with — TV & film · TVmaze, Books · Open
Library, Music · MusicBrainz — each a list row with a status dot and a last-checked timestamp.
Second section "Better artwork and metadata" shows TMDB with a segmented control: **Use Kati's key**
(default) / **Use my own key**, and a note explaining that Kati's key is public because the app is
open-source, that it costs the user nothing, and that a personal key means personal rate limits.
Third section "Connect an account" lists Trakt, Last.fm, ListenBrainz and TheTVDB as disconnected
rows, each expanding into a short "why this needs your own credentials" explanation and a paste field
or a device-code pairing card (a 6-character code in DM Mono plus a URL, styled like screen 50's QR
card). Fourth section is the honest part: an info footnote in a tinted card stating that tokens are
stored unencrypted on this device because the platform provides no secure storage yet, that Kati
never sends them anywhere but the service itself, and a destructive "Disconnect everything and wipe
tokens" row. Fifth: "Cached metadata · 34 MB · oldest entry 2 months" with Refresh and Clear.

**4. Attribution & credits screen.**
This is a licence obligation, not a nicety: TMDB requires its logo plus the exact sentence "This
product uses the TMDB API but is not endorsed or certified by TMDB"; watch-provider data must be
attributed to JustWatch; TVmaze is CC BY-SA and must be credited with a link back; Open Library and
MusicBrainz both ask for attribution. Design a pushed screen from Settings → About that renders each
source as a card: provider logo, one line describing what Kati uses it for, the required notice
verbatim in body text, and a link row. Keep it in the app's own voice — this is the screen that
tells the user where their posters come from, and it should read like a colophon rather than a legal
notice. Include a final card for the open-source licences.

**5. Album and artist detail screens.**
Screen 21 promises "418 albums · 61h this year" and then has nowhere to go. Design an album screen
with a square art hero, artist and year, a tracklist where each row shows play count in DM Mono, a
"first heard 3 Mar 2024 · last played yesterday" pair, a star rating, the cream note card, and a
listen-history band using the pixel field. Design an artist screen with a rail of albums, a
play-count bar chart reusing screen 07's genre bars, and a "New from this artist" state that ties
into the release watcher on screen 25. Both screens must work with a blank art slot, because
MusicBrainz supplies metadata but Cover Art Archive coverage is patchy.

**6. My services & region.**
Every "Where to watch" row in the design (screens 08, 14) and every "Leaving Lumen+ in 7 days" card
(screen 11) presupposes that Kati knows which services the user pays for and in which country — but
no screen ever asks. Screen 35 buries it as a per-show setting reading "My services 3 of 12" and
"Region UK", which is the wrong altitude. Design a settings screen with a country picker at the top
(one row, flag plus name, because availability data is per-country and wrong data is worse than
none), then a searchable list of streaming services as toggle rows grouped into Subscribed / Free
with ads / Not mine, then three rules: "count rentals as available", "count purchases as available",
"hide titles I can't watch". Wire it to screen 23 Subscriptions so a service the user pays for
appears in both places with one source of truth.

**7. Your year → shareable cards.**
Screen 07 produces the numbers; Spotify Wrapped, Apple Music Replay and Letterboxd's Year in Review
prove that the *card* is the product. Design a share flow off screen 07: a horizontally paged set of
four cards — Hours, Top titles (poster collage), Genres (the bar chart), and the pixel field — each
in Kati's paper-and-ink palette rather than a borrowed neon aesthetic, each with the year set in the
28 px hero numeral style. Below, a segmented control for square / story aspect ratios, a "hide
titles I marked private" toggle, and a single ink "Save image" button. Everything renders on device;
nothing uploads. Add Persian variants where the numerals are Persian, the layout mirrors, and the
pixel field starts top-right, matching screen 61.

**8. Per-episode rating & review.**
Serializd's entire following exists because it lets people rate and review individual episodes on a
half-star scale and read that back on a rewatch; Trakt and TV Time treat an episode as a checkbox.
Kati's screen 04 already renders tappable episode rows and screen 33 already has half-star input and
a spoiler toggle. Extend rather than add: give each episode row on 04 an optional trailing half-star
value in DM Mono, and make a long press open screen 33 in an "episode" variant whose header reads
"S2 E6 · The Undertow" and whose context rows are Watched on / Where / With. On a rewatch, surface
the previous rating and review inline above the input as a cream card, so the user is arguing with
their past self.

**9. Named importers on screen 37.**
Screen 37 is a well-designed *generic* column mapper, but nobody switches trackers by hand-mapping
nine columns. Add a step 0: a grid of source tiles — Goodreads, StoryGraph, Letterboxd, Trakt,
Simkl, TV Time, Libib, MyAnimeList, Last.fm — each of which pre-fills the mapping and the unit
conversions that already exist on the screen ("converts 10pt → 5★"). Keep the manual mapper as the
"Something else" tile. Keep the pre-write summary and the conflict resolver exactly as drawn; they
are better than anything the incumbents ship.

**10. Mood, pace and content warnings as recorded metadata.**
StoryGraph took a meaningful share of Goodreads' users on one idea: after you finish a book, you tag
it by mood, pace and whether it is character- or plot-driven, and those tags become both a personal
chart and the recommendation engine. Kati already uses mood chips on screen 13 but throws them away.
Add a mood row (14 chips: adventurous, challenging, dark, emotional, funny, hopeful, informative,
inspiring, lighthearted, mysterious, reflective, relaxing, sad, tense), a three-way pace control
(slow / medium / fast) and a character-vs-plot slider to screen 33, applying to films and shows as
well as books. Add a mood distribution card to screen 07 and let screen 11 Discover filter by mood.

**11. DNF, drop and abandon as one honest state machine.**
Kati handles abandonment better than most for TV — "Gone cold · 3" on screen 10, the Drop action, the
Abandoned list on 12, "Dropped The Quiet Ones after S1E3" on 15 — but books have none of it, and the
states are scattered. Draw one reference band, in the style of screen 27's states sheet, showing
the same five states rendered for a show, a book and an album: Active · Paused · Gone cold ·
Dropped with a stated stopping point · Finished. Every drop carries a captured position (S1E3,
p. 148, track 4) and an optional one-tap reason chip, and every drop is undoable via the existing
undo bar.

**12. Goals.**
Goodreads' one genuinely sticky feature is the annual reading challenge; StoryGraph beat it by
allowing page goals and custom prompts. Kati has habits and streaks (screen 22) but no goal object.
Add a Goals screen under Stats: a card per goal showing target, current, a progress bar and a
projected finish date ("on pace to finish 48 of 52 by 31 December"), a creation flow that accepts
books, pages, minutes, films, episodes or hours over a year, month or week, and the honest empty
state Kati does so well — "No goals. Kati will still count everything."

**13. Rich shelf filtering and bulk edit.**
Screen 03's four filter tabs are the right *default*, not the whole story: Reelgood filters by genre,
year, IMDb and Rotten Tomatoes score and service, and Libib users routinely bulk-edit thousands of
rows. Add a filter icon to the header of 03/20/21 that opens a sheet with sort (added, released,
rated, title, runtime/pages), range sliders for year and rating, and chips for genre, service,
language and format — plus a persistent count line ("showing 41 of 418"). Add long-press-to-select
with a bottom action bar (add to list, change status, tag, remove) styled like the undo bar on 27.

**14. Music scrobbling on Android.**
Screen 36 lists "This phone — detects audio from any app" as a source but draws the whole screen
around a TV episode. On Android this is the one auto-detection path that is genuinely achievable
without a server or a vendor SDK — Pano Scrobbler does it with `NotificationListenerService` plus
`MediaSessionManager`. Draw a music variant of 36: a now-playing card with artwork, artist, track
and a progress bar that says "scrobbles at 50% or 4 minutes", an app allow-list (Spotify, YouTube
Music, Poweramp, Apple Music) as toggle rows with per-app icons, and the same "Needs a decision"
disambiguation card for a mistagged track. Include the permission row exactly as screen 40 phrases
permissions — stating its purpose before asking.

**15. Anime as a filter, not a fork.**
Simkl's advantage over Trakt is that anime was a first-class pillar from day one rather than a
retrofit, and the pain is entirely in numbering — which Kati's screen 34 *already solves* with
aired/absolute/DVD schemes, specials inclusion and multi-part merging. Add an Anime chip to screen
03's filter row, an "Anime" tile to screen 26's onboarding sections, a MyAnimeList/AniList tile to
the importer, and a per-show default on 35 that pre-selects absolute numbering. This is the cheapest
high-value gap in the list because the hard screen already exists.

---

## 3. Data sources — what a device-only, open-source app can actually use

### 3.1 TMDB

| Property | Finding | Source |
|---|---|---|
| Cost | "Our API is free to use for non-commercial purposes as long as you attribute TMDB as the source of the data and/or images." | <https://developer.themoviedb.org/docs/faq> |
| Commercial test | "Your project is considered commercial if the primary purpose is to create revenue for the benefit of the owner." | same |
| Rate limit | The 40-req/10s limit "was disabled as of December 16, 2019"; an undocumented upper limit sits "somewhere in the 40 requests per second range" and "could change at any time" — honour HTTP 429 | <https://developer.themoviedb.org/docs/rate-limiting> |
| Attribution | "You must use the TMDB logo to identify Your use of TMDB, the TMDB APIs, or TMDB Content" plus the notice that the app "is not endorsed, certified, or otherwise approved by TMDB" | <https://www.themoviedb.org/api-terms-of-use> |
| Cache cap | Prohibited to "Cache, for longer than 6 months, any information obtained through or from TMDB or the TMDB APIs" | same |
| Key transfer | Licence is "non-transferable, non-sublicensable"; prohibited to "Sell, lease, or sublicense the TMDB APIs, access to the TMDB APIs, or TMDB Content" | same |
| Open source | **No carve-out exists.** The terms are silent on shipping a key inside an open-source binary | same |
| AI | Prohibited "in connection with … a machine learning (ML) or artificial intelligence (AI) based Application" | same |

**Read:** Kati as a free, ad-free, IAP-free open-source app is non-commercial, so the free tier
applies. Shipping the key is a *grey area*, not an explicit violation — the terms forbid
sublicensing API **access**, and the closest staff comment on record ("That's fine, not much of a
difference to us either way", Travis Bell, on a proposal to host a public proxy —
<https://www.themoviedb.org/talk/512403ec760ee37257037fdb>) is about proxying, not key shipping.
Precedent is strong though: see §4.2.

### 3.2 TMDB watch providers = JustWatch, with strings attached

`/watch/providers` is powered by TMDB's JustWatch partnership. Attribution to **JustWatch**
specifically is required, and TMDB states it will revoke API access for non-compliance. The endpoint
returns **enough to display availability but no deep links** — you are expected to link to the TMDB
watch page. Sources: <https://developer.themoviedb.org/reference/movie-watch-providers>,
<https://www.themoviedb.org/talk/60355e30a284eb003da676f2>.

### 3.3 The rest

| Source | Key? | Auth | Rate limit | Cost / licence | Verdict for Kati |
|---|---|---|---|---|---|
| **TVmaze** | **No** | none for the public API | "at least 20 calls every 10 seconds per IP address" | Free; **CC BY-SA**, credit TVmaze with a link back (<https://www.tvmaze.com/api>) | **Ship as the default TV source.** The ShareAlike clause applies to redistributing the data, not to displaying it |
| **Trakt** | Yes | OAuth 2.0 authorization-code or **device code**; `POST /oauth/device/token` **requires `client_id`, `client_secret` and `code`** (<https://docs.trakt.tv/reference/postoauthdevicetoken>) | 1000 GET calls / 5 min; 1 POST-PUT-DELETE / sec (<https://forums.trakt.tv/t/has-the-trakt-api-rate-limit-changed/40054>) | API free; **product** heavily paywalled — Feb 2025: free tier cut to 2 lists of 100 items and 100-item watchlist/collection, VIP raised $30 → $60/yr (<https://alternativeto.net/news/2025/2/trakt-tv-has-set-stricter-limits-for-free-users-and-raised-vip-subscription-prices-by-100-/>) | **Cannot be shipped** — the required `client_secret` makes it a user-supplied credential. Offer it as an optional sync target only |
| **TheTVDB** | Yes | API key; two models — "negotiated license model … [and] a user-subscription model" | UNKNOWN | Free under $50k revenue **with attribution**; direct end-user access needs "a subscriber-supported API key that requires that each of your users has a $12/year TheTVDB subscription" (<https://github.com/thetvdb/v4-api>, <https://thetvdb.com/api-information>) | **Skip by default.** Optional for users who already subscribe. Note: I could not confirm the `pin` parameter from a primary source — **UNKNOWN** |
| **OMDb** | Yes | key in query string | Free-tier daily cap **not stated on the site** — UNKNOWN (commonly cited as 1,000/day, unverified) | **CC BY-NC 4.0** (<https://www.omdbapi.com/>) | Skip. IMDb ratings only; NC licence and an unclear cap |
| **Watchmode** | Yes | key | Developer plan 2,500 requests/month | Free tier is **non-commercial, 3 countries, attribution required**; Startup $349/mo, Business $599/mo (<https://api.watchmode.com/>) | Skip for shipping; 2,500/mo cannot cover a user base. Optional user key |
| **JustWatch** | — | — | — | **No public API and none planned**; partner-only via data-partner@justwatch.com (<https://apis.justwatch.com/docs/api/>, <https://partners.justwatch.com/>) | Unusable directly. Get JustWatch data *through* TMDB (§3.2) |
| **Simkl** | Yes | client_id / client_secret, OAuth | UNKNOWN | Free tier is generous (unlimited tracking, imports, calendar) vs Trakt (<https://simkl.com/vip/>) | Same shape as Trakt — user-supplied only. Docs at simkl.docs.apiary.io returned no machine-readable detail; auth specifics **UNKNOWN** |
| **Letterboxd** | Yes | OAuth2 client-credentials + authorization-code | UNKNOWN | **Request-only, effectively closed**: "Access to the Letterboxd API is available by request only … we are unable to individually reply, or to guarantee access" (<https://letterboxd.com/api-beta/>) | Do not design around it. Support Letterboxd **CSV export** as an importer instead |
| **Goodreads** | — | — | — | **Dead.** New developer keys stopped 8 Dec 2020 and the API was retired (<https://goodereader.com/blog/digital-publishing/goodreads-disables-their-api-program>) | Importer only, via the CSV export Goodreads still offers |
| **Open Library** | **No** | none; optional UA + email | 1 req/s anonymous, **3 req/s if identified** with a User-Agent and email; Covers API "only 100 requests/IP … for every 5 minutes" for non-CoverID/OLID lookups, 403 above that; "do not crawl our cover API" | Open licence; explicitly "not intended to serve as a bulk data backend" (<https://openlibrary.org/developers/api>, <https://openlibrary.org/dev/docs/api/covers>) | **Ship as the default book source.** ISBN lookup makes the barcode scanner (B8) trivial |
| **Google Books** | Yes | API key or OAuth — "Requests to the Books API for public data must be accompanied by an identifier, which can be an API key or an access token" | not stated in the guide — UNKNOWN | Free tier; terms at developers.google.com/books/terms (<https://developers.google.com/books/docs/v1/using>) | Optional fallback for titles Open Library lacks. Needs a key, so it belongs in the user-supplied tier |
| **Hardcover** | Yes | GraphQL, token | UNKNOWN | Free to use; covers library status (Want to Read / Currently Reading / Read / Paused / **Did Not Finish**), search across Books, Authors, Series, Characters, Lists (<https://docs.hardcover.app/api/getting-started/>) | Interesting as an *optional* sync target and as a **series data** source; its DNF/status model is worth copying |
| **MusicBrainz** | **No** | none | **1 request/second per IP**; a meaningful `User-Agent` is mandatory — "Application name/⟨version⟩ ( contact-url )" — and "If you program your application this way and it impacts our service, we will block your application" | CC0 core data (<https://musicbrainz.org/doc/MusicBrainz_API/Rate_Limiting>) | **Ship as the default music source**, with Cover Art Archive for art. The 1 req/s ceiling means a client-side token bucket is not optional |
| **ListenBrainz** | Yes (user's own) | "private API keys called user tokens", header `Authorization: Token {token}`; token comes from the user's own account settings | dynamic, via `X-RateLimit-*` headers; 429 on exceed | Free, open (<https://listenbrainz.readthedocs.io/en/latest/users/api/index.html>) | **The right music-scrobble target for an open-source app** — the credential is the *user's*, so nothing has to be embedded |
| **Last.fm** | Yes | API key + shared secret; session key for scrobbling; batches capped at 50 scrobbles/request | ~5 req/s per IP (guidance) | Free for non-commercial; commercial needs partners@last.fm; "powered by AudioScrobbler" attribution (<https://www.last.fm/api/tos>, <https://www.last.fm/api/scrobbling>) | Optional, user-supplied — the **shared secret** is the blocker, same as Trakt |

### 3.4 Verdict

**Default, keyless, ships with zero secrets and works on first launch:**
TVmaze (TV) · TMDB (film + artwork, see §4) · Open Library (books + covers + ISBN) ·
MusicBrainz + Cover Art Archive (music).

**Optional, user-supplied credentials, never in the repo:**
Trakt · Simkl · Last.fm · ListenBrainz · TheTVDB · Google Books · Watchmode · Hardcover.

**Importer-only (no live API):** Goodreads CSV · Letterboxd CSV · StoryGraph CSV · Libib CSV ·
MyAnimeList XML.

**Do not design around:** JustWatch direct · Letterboxd API.

---

## 4. The API-key problem, solved concretely

### 4.1 The constraint stack

- The repo is public, so **anything in it is public**. This is not fixable by obfuscation.
- Mob provides **no secure storage**: "**Encryption at rest: none.** No SQLCipher, no
  keychain/keystore, no encrypted storage anywhere in Mob. Surface matrix confirms 'Missing:
  keychain/keystore, encrypted storage'. `Mob.State`'s DETS file and the SQLite DB are plaintext in
  the app sandbox. For a movie tracker that's probably fine; for a stored Trakt OAuth token it is
  not — you would need a native extension." (`mob-framework.md:1384-1388`)
- There is **no server**, so the standard escape hatch — proxy every call through a backend that
  holds the key — is off the table by the owner's own locked decision.
- Distribution is Play Store + App Store + **APK on GitHub**, and F-Droid is the natural fourth
  channel. F-Droid's rule: apps "with closed-source components or API keys cannot be setup for
  reproducible builds"; such apps must ship from the developer's own binary repo
  (<https://f-droid.org/docs/Reproducible_Builds/>).

### 4.2 How comparable open-source apps handle it — two live precedents

**Jellyfin: ship the key in the source, publicly.** `MediaBrowser.Providers/Plugins/Tmdb/TmdbUtils.cs`
contains, verbatim:

```csharp
/// <summary>
/// API key to use when performing an API call.
/// </summary>
public const string ApiKey = "4219e299c89411838049ab0dab19ebd5";
```

(<https://github.com/jellyfin/jellyfin/blob/master/MediaBrowser.Providers/Plugins/Tmdb/TmdbUtils.cs>)
Jellyfin has done this for years across millions of installs without TMDB revoking it.

**SeriesGuide: build-time injection.** Keys live in a `secret.properties` file next to
`settings.gradle`, outside version control, holding `SG_TMDB_API_KEY`, `SG_TRAKT_CLIENT_ID` and
`SG_TRAKT_CLIENT_SECRET`; contributors supply their own for debug builds
(<https://github.com/UweTrottmann/SeriesGuide/blob/dev/CONTRIBUTING.md>). The repo has no secret; the
shipped binary does — which is why it is *not* reproducible-buildable on F-Droid.

### 4.3 The recommendation for Kati

**A three-tier model.**

**Tier 0 — keyless by default.** TVmaze, Open Library, MusicBrainz and Cover Art Archive need no
credential at all. Kati must be fully functional on Tier 0 alone, on first launch, forever. This is
the design decision that makes everything else optional. It also happens to make the F-Droid
reproducible-build path viable for a build that omits Tier 1.

**Tier 1 — TMDB, shipped Jellyfin-style, in the repo.** Put the TMDB **v3 API key** in the source as
a plain module attribute, with a comment saying exactly why. Rationale, in order of weight:
(a) TMDB rate-limits per **IP**, not per key (§3.1), so a public key imposes no cost on other users
and creates no quota to steal; (b) Jellyfin's precedent is public, large-scale and long-lived;
(c) build-time injection buys nothing here — the key is trivially extractable from the APK either
way, and it *costs* reproducibility; (d) it keeps contributor onboarding to `mix deps.get`. Accept
the residual risk (TMDB may revoke) and mitigate it with Tier 2's escape hatch and with Tier 0 as
the fallback path, so a revoked key degrades artwork quality rather than bricking the app.

**Tier 2 — user-supplied, never in the repo.** Trakt, Simkl, Last.fm and TheTVDB each require a
`client_secret` or a paid subscription, so shipping them is either impossible or dishonest. The user
creates their own application on the provider's site and pastes `client_id` / `client_secret`, or
pastes a personal token (ListenBrainz, Hardcover). Prefer **device-code flow** where offered (Trakt
supports it) because it needs no custom URL scheme and no redirect-URI registration, and it renders
beautifully as the 6-character-code card described in brief #3.

**Storage, given that Mob has no keystore.** Three rules:
1. Store Tier 2 credentials in the app's SQLite DB in a dedicated `credentials` table, one row per
   provider, and **say so on screen** (brief #3). Do not pretend to encrypt.
2. Never store a user's *password* for any service — only OAuth tokens and personal access tokens,
   both of which are revocable from the provider's own site. This is the property that makes
   plaintext storage tolerable rather than negligent.
3. Ship a "Disconnect everything and wipe tokens" destructive action, and file a native-extension
   task to move credentials to Android Keystore / iOS Keychain when Mob grows the capability — the
   surface matrix already lists it as missing (`mob-framework.md:842`).

**Rate limiting is a first-class module, not a retry loop.** MusicBrainz is 1 req/s per IP with a
mandatory contact-bearing User-Agent and an explicit threat to block misbehaving applications; Open
Library is 1–3 req/s and explicitly asks you not to crawl the covers endpoint. With no server there
is no shared cache, so every device must throttle itself. Implement one `Kati.Fetch` GenServer per
provider holding a token bucket and a `User-Agent` of the form
`Kati/0.1.0 ( https://github.com/<owner>/kati )`, and route every call through it.

**Caching has a hard legal ceiling.** TMDB forbids caching its data for **longer than 6 months**.
That is a schema requirement: every cached metadata row needs a `fetched_at` and the app needs a
sweep that re-fetches or evicts past that horizon. Surface it as the "Cached metadata · refresh ·
clear" row in brief #3.

**Non-commercial must stay true.** TMDB and Last.fm are free only for non-commercial use, where
commercial means "the primary purpose is to create revenue for the benefit of the owner". Kati is
free and open-source, so this holds — but adding ads, a paid tier or IAP to the Play listing would
break it and require a licence from sales@themoviedb.org.

### 4.4 Two screens this creates

- **Settings → Data sources** (brief #3) — the tier model made visible, plus the honest storage note.
- **Settings → About → Attribution** (brief #4) — TMDB logo + exact notice, JustWatch credit for
  provider data, TVmaze link-back, Open Library and MusicBrainz credits, open-source licences.

Both are pushed screens under Settings, so they slot into the existing back-pill chain
(`design-index.md:62`) without disturbing the four-root navigation model.

---

## 5. What Kati already does better than the incumbents — protect these

1. **Cost per watched hour (screen 23, `design-index.md:113`).** "Lumen+ £0.21/h, Orbit £2.33/h"
   with a "Worth a look" advice card. JustWatch and Reelgood tell you *where* something is; Trakt
   tells you *what* you watched; **nothing on the market joins your subscription spend to your own
   watch hours.** This is the app's strongest single idea and the only one that needs both the money
   section and the media section to exist. Do not let it get diluted into a generic spend chart.

2. **"What fits tonight" (13, `:99`).** A runtime budget — 20m/30m/45m/1h/2h+ — matched against real
   episode lengths, *including* an explicit over-budget failure state ("Nothing else fits — nearest
   film is 1h 46m · 61 MIN OVER"). Sofa has moods, Reelgood has filters; nobody treats the evening as
   a time budget. The honest "nothing fits" card is the part most teams would cut.

3. **The calendar as the spine (02, 09, 16, 17, 30, 52).** Trakt, Simkl and TV Time all have a
   calendar *of releases*. Kati's calendar merges air dates, appointments, habits, renewals and meals
   into one time surface, with real density rules: lane splitting capped at two columns, a `+1 MORE`
   overflow tile, 3+-same-kind collapse into a grouped poster-stack card, all-day bands and merged
   money events (`:94`). No tracker in this survey has drawn that problem at all, let alone solved it.

4. **Clash handling before the fact (18 and 31, `:106`, `:124`).** A natural-language quick-add that
   warns about a collision *before* saving, and an event editor offering three one-tap fixes
   ("Shift 15m later / Shorten to 45m / Keep both"). Calendar apps warn after; trackers do not warn
   at all.

5. **A whole localisation pass, not a translation file (53–62, `:150-160`).** RTL as a container
   attribute rather than a fork, Shamsi dates, Persian digits kept in DM Mono so numeric columns
   still align, week reordered to start Saturday (not merely mirrored), charts whose time axis reads
   right-to-left, and a pixel field that starts its year top-right. Trakt, Letterboxd, Serializd,
   StoryGraph and Hardcover are all English-first with no meaningful RTL story. **This is an
   uncontested market**, and screen 60's observation — that mirroring a day-column matrix "would put
   Monday on the right and still be wrong" — is the kind of detail that no competitor has ever had to
   think about.

6. **Notification manners (25, 38, 51, `:116`, `:133`, `:148`).** Push **off by default**, an inbox
   badge instead, quiet hours 23:00–08:00, a weekly digest option, "stop after 2 skips", and — the
   good bit — the loudness choice is made on the onboarding screen *before* the OS permission prompt
   is raised. TV Time's most common complaint is notification spam; Kati has designed the opposite
   and should say so in the store listing.

7. **Scrobble disambiguation (36, `:131`).** The "Needs a decision" card — "'Marram E3' or 'Marram
   Grass'? Played 43m on Orbit, 21:10" → The series / The film / Neither. Every real scrobbler
   (Trakt plugins, Pano Scrobbler) mismatches titles constantly and resolves it silently or not at
   all. Making ambiguity a first-class UI state is genuinely novel.

8. **Import with a pre-write summary and a conflict resolver (37, `:132`).** "384 New / 28 Merged /
   6 Conflicts" shown *before* anything is written, then "Keep mine / Take file / Keep both — 1 of 6
   · apply to all", with a skipped column noted as "(empty in 402 rows)". Goodreads→StoryGraph
   imports are the canonical lossy migration in this space; this design is strictly better than any
   of them.

9. **Episode-order machinery (34, `:128`).** Aired/absolute/DVD schemes, "Include specials", and
   "Merge multi-part (treat E7 & E8 as one 2h finale)". This is the exact terrain where Trakt users
   defect to Simkl, and Kati has drawn it before writing a line of code.

10. **Spoiler safety (35 spoiler-safe names, 33 spoiler toggle, `:129`, `:127`).** TV Time and Trakt
    both leak future episode titles into notifications and lists. `spoilerSafe` swapping titles for
    "Episode N" (`:246`) is a small mechanism with outsized value.

11. **Undo on every destructive action, backed by an append-only log (15 and 27, `:102`, `:226`).**
    The activity log explicitly "doubles as the undo trail". No competitor offers undo at all.

12. **Accessibility drawn, not promised (41, `:137`).** The densest card re-laid at 235% Dynamic
    Type with the rule "nothing truncates — cards get taller instead", plus a literal VoiceOver
    transcript for an episode row. Nothing in this competitive set has an accessibility story of any
    kind.

13. **Status as a first-class choice rather than a swipe (35, `:440`).** Deliberate, stated, and
    correct — swipe actions are the reason people accidentally drop shows in every other tracker.

14. **The states sheet (27, `:220-228`).** Empty, skeleton-not-spinner, offline badge that promises
    "ticks are saved and will sync later", error with Retry, undo bar — designed as a deliverable
    rather than discovered in QA.

---

## 6. Open questions / UNKNOWN

- **Simkl API auth model and rate limits** — apiary docs returned no machine-readable detail. UNKNOWN.
- **TheTVDB v4 `pin` parameter** — widely used in the wild for subscriber-supported keys, but I could
  not confirm it from thetvdb.com or the v4-api README, and `api4.thetvdb.com/v4/swagger.json`
  returned 401. UNKNOWN.
- **OMDb free-tier daily request cap** — not stated anywhere on omdbapi.com. UNKNOWN.
- **Google Books quota** — the "Using the API" guide does not state a daily limit. UNKNOWN.
- **Whether TMDB would object to Kati shipping a key in-repo** — no written policy either way; the
  only evidence is Jellyfin's unchallenged precedent. Recommend emailing
  <mailto:travis@themoviedb.org> / support before the first store release rather than assuming.
- **Whether Mob can run `NotificationListenerService` on Android** for music scrobbling (brief #14) —
  `mob-framework.md` does not cover it. Needs a separate spike.
- **ListenBrainz data licence** — the API docs page fetched did not state it; MetaBrainz licences
  vary per dataset. UNKNOWN.

---

## Sources

TMDB: <https://developer.themoviedb.org/docs/rate-limiting> · <https://developer.themoviedb.org/docs/faq> ·
<https://www.themoviedb.org/api-terms-of-use> · <https://developer.themoviedb.org/reference/movie-watch-providers> ·
<https://www.themoviedb.org/talk/512403ec760ee37257037fdb> · <https://www.themoviedb.org/talk/60355e30a284eb003da676f2>
Trakt: <https://docs.trakt.tv/docs/authentication-oauth> · <https://docs.trakt.tv/reference/postoauthdevicetoken> ·
<https://docs.trakt.tv/docs/create-an-app> · <https://forums.trakt.tv/t/has-the-trakt-api-rate-limit-changed/40054> ·
<https://alternativeto.net/news/2025/2/trakt-tv-has-set-stricter-limits-for-free-users-and-raised-vip-subscription-prices-by-100-/>
TVmaze <https://www.tvmaze.com/api> · TVDB <https://thetvdb.com/api-information>, <https://github.com/thetvdb/v4-api> ·
OMDb <https://www.omdbapi.com/> · Watchmode <https://api.watchmode.com/> ·
JustWatch <https://apis.justwatch.com/docs/api/>, <https://partners.justwatch.com/> ·
Simkl <https://simkl.com/vip/> · Letterboxd <https://letterboxd.com/api-beta/> ·
Serializd <https://www.serializd.com/about> · Reelgood <https://www.techhive.com/article/1428635/reelgood-vs-justwatch-vs-plex-battle-of-the-streaming-guides.html> ·
Plex <https://support.plex.tv/articles/universal-watchlist/>, <https://www.plex.tv/blog/plex-introduces-a-social-platform-for-entertainment-discovery-across-streaming-services/> ·
Sofa <https://www.sofahq.com/>
Open Library <https://openlibrary.org/developers/api>, <https://openlibrary.org/dev/docs/api/covers> ·
Google Books <https://developers.google.com/books/docs/v1/using> · Hardcover <https://docs.hardcover.app/api/getting-started/> ·
Bookwyrm <https://github.com/bookwyrm-social/bookwyrm> · Libib <https://www.libib.com/> ·
Goodreads API retirement <https://goodereader.com/blog/digital-publishing/goodreads-disables-their-api-program> ·
StoryGraph <https://roadmap.thestorygraph.com/features/posts/a-user-can-specify-the-types-of-content-they-want-to-avoid-in-th>, <https://roadmap.thestorygraph.com/features/posts/pages-read-for-a-book-that-is-set-to-dnf-still-count-towards-a-p>
MusicBrainz <https://musicbrainz.org/doc/MusicBrainz_API/Rate_Limiting> · ListenBrainz <https://listenbrainz.readthedocs.io/en/latest/users/api/index.html> ·
Last.fm <https://www.last.fm/api/scrobbling>, <https://www.last.fm/api/tos> ·
Pano Scrobbler <https://github.com/kawaiiDango/pano-scrobbler>, <https://deepwiki.com/kawaiiDango/pano-scrobbler>
Key handling: <https://github.com/jellyfin/jellyfin/blob/master/MediaBrowser.Providers/Plugins/Tmdb/TmdbUtils.cs> ·
<https://github.com/UweTrottmann/SeriesGuide/blob/dev/CONTRIBUTING.md> · <https://f-droid.org/docs/Reproducible_Builds/>
