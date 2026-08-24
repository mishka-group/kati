# Releases beyond television — the watcher and the inbox for books and music

> **Two screen edits plus the follow surface they rest on** · issue [#27](https://github.com/mishka-group/kati/issues/27) · ticket `D-30`

Screen 25 (Release watcher) and screen 05 (New releases inbox) are drawn entirely around episodes. Books have publication dates and artists release albums, and screen 21 already draws a **"New from artists you follow"** band — a promise the watcher currently cannot keep.

**Read the constraints section before drawing.** Two things already on screen 25 are not deliverable, and the redraw has to correct them rather than reproduce them.

## 1 · Screen 25 — alert types that are not all television

The board draws *"Watching 24 titles · 3 found this week"*, six alert-type toggles, a frequency segmented control, and *How loudly* rows.

**The six alert types are TV-shaped.** Draw the set that covers all three media, grouped so it is obvious which apply to what — for example a **Television** group, a **Books** group (*New book by an author you follow*, *A book you want comes to your library*), and a **Music** group (*New album from an artist you follow*, *A single or EP*). Decide whether a group with nothing followed is hidden, or drawn dimmed with the reason.

**The count line has to say what it is counting.** *"Watching 24 titles"* is unambiguous when everything is a show and ambiguous the moment it is not. Draw what it says when someone follows 24 shows, 6 authors and 11 artists.

## 2 · Screen 25 — the frequency control is wrong and must change

**Delete `Hourly`.** Everything here happens in Kotlin while the app is closed, and WorkManager's cadence is settled at **6 hours with 2 hours flex**. Hourly is not something Kati can do, and a control offering it is a promise the app breaks silently.

**Cadence is per media, not one number.** Draw the control saying so. The honest shape is something like *Television every 6 hours · Books and music daily*, with one line explaining why — see the constraints below for the reason, in the user's words rather than the API's.

## 3 · Screen 05 — the inbox carrying three media

The board draws *"3 out now · 3 coming up"*, a status line *"Watching for 24 titles · last checked 18:02 · every 6h"*, out-now rows with **Watch** buttons, and coming-up date rows with bell toggles.

**Every row shape needs a book and an album version.** A book's out-now action is not *Watch*; an album's is not either. Draw what the trailing control says for each, and what the row's artwork is — cover, poster, sleeve.

**Draw the mixed list, not three separate lists.** The interesting board is one inbox holding an episode, a book and an album at once, because that is where a shared row shape either works or does not.

**The status line's `every 6h` is now per-media.** Redraw it for the split cadence.

## 4 · The follow surface this rests on

Nothing in Kati lets someone follow an **author**. `D-03` adds a Following toggle on the artist screen; there is no equivalent for a book's author, and screen 25's book alerts have nothing to populate them without one.

Draw **where following an author happens** — the natural home is the author line on screen 66 Book detail, the mirror of `D-03`'s artist toggle. One row, one state, and what it looks like already followed.

## States to draw

- **Nothing followed at all** — the watcher before anyone has followed anything. This is a first-run state and currently has no drawing.
- **Followed shows only** — books and music groups present but empty, which is what most users will actually see.
- **All three populated** — the mixed inbox described above.
- **Checked recently vs never checked** — the status line's two branches.

## Constraints — these are facts, not preferences

- **WorkManager: 6 hours, 2 hours flex.** Not configurable downward. No hourly, no *check now* that is instant.
- **MusicBrainz allows 1 request per second per IP**, and states that misbehaving applications are blocked. Checking 200 followed artists is a three-and-a-half-minute crawl, not a request.
- **There is no bulk-changes endpoint outside TMDB.** `GET /3/tv/changes` collapses every followed show into one request; Open Library and MusicBrainz have no equivalent. This is why television can be checked often and the other two cannot.
- **The work happens in Kotlin while the app is closed** — fetch, write JSON, notify natively, ingest on next foreground. Nothing on these screens can imply a live check.

## Left open — decide and note which way you went

- Whether an empty media group is **hidden or dimmed**.
- Whether the cadence split is **stated on the control** or in a footnote under it.
- Whether *coming up* for a book means the **publication date** or the date it becomes borrowable, when those differ.
- Whether following an author is drawn on **screen 66's author line** or somewhere else.

## House style — Kati

Draw into `Kati.dc.html` as new `IOSDevice` artboards, **402×874**.

**Numbering.** The app now runs **01–139**. Nothing may be inserted below 139; new boards take the next free numbers upward. An *edit* to an existing screen is redrawn as a new board rather than changed in place, so the before and after can be compared.

**Type.** `Plus Jakarta Sans` for everything, `DM Mono` for data, counts, times, IDs and eyebrows, `Vazirmatn` for Persian. Material Symbols Rounded for glyphs.

**Palette.**

| Token | Light | Meaning |
|---|---|---|
| paper | `#EFECE7` | page ground |
| card | `#FBFAF8` | any raised surface |
| cream | `#FBF1DE` | a card carrying a claim, a warning, or anything the user wrote |
| ink | `#1A1917` | primary text, filled buttons |
| ink soft | `#5C574F` | body copy on a card |
| sub | `#8A8479` | a row's second line |
| tertiary | `#A9A29A` | mono captions, chevrons |
| mono caption | `#6E6860` | DM Mono values in a row |
| accent | `#E8823C` | one thing per screen, never two |
| bronze | `#C98A3E` | money, meals, a gentle warning |
| green | `#4E9A73` | done, allowed |
| red | `#B4553C` | destructive, and only destructive |

Dark ground is `#121110`, card `#1E1D1B`, ink `#F5F2EE`.

**Recipes already in the app** — reuse rather than invent:

- **Pushed screen** — scroller `padding: 64px 21px 40px`, floating back pill (44pt, radius 22, `#FBFAF8`, `arrow_back_ios_new` + parent name), no dock, frame closes at 40.
- **Root screen** — same but the dock is drawn and the frame closes at 132.
- **Modal / bottom sheet** — centred title, leading `close` disc, scrim `rgba(26,25,23,.42)`, sheet ground `#EFECE7` with the top corners rounded at 22.
- **Eyebrow** — a 13×2 rounded `#E8823C` rule, then DM Mono 10.5px, `.16em` tracking, uppercase, `#A0998F`. A quiet eyebrow swaps the rule to `#C4BDB3`.
- **Card** — `#FBFAF8`, radius 22, `box-shadow: 0 1px 2px rgba(26,25,23,.04), 0 12px 24px -18px rgba(26,25,23,.7)`.
- **List row** — 30×30 paper tile (radius 9, `#EFECE7`, glyph 17px `#5C574F`), 13.5px/600 title, 11.5px `#8A8479` second line, trailing chevron `#C4BDB3`. A chevron means *leads elsewhere* — never use one for a row that does not push a screen.
- **Chip** — height 32, radius 16, padding-x 15, 12.5px/600. Selected is `#1A1917` with `#FBFAF8` text.
- **Pill button** — height 30, radius 15, `#EFECE7`, 11.5px/600.
- **Primary button** — height 54, radius 27, ink fill, 14.5px/700 in `#FBFAF8`. **One per screen.**
- **Selection ring** — `0 0 0 2px #1A1917, 0 8px 18px -14px rgba(26,25,23,.7)`.
- **Undo pill** — the dark pill from screen 27: ink ground, white label, `#E8823C` action word.
- **Info footnote** — a bordered block with an `info` glyph, `#5C574F` body at 1.65 leading.

**RTL.** The container gets `dir="rtl"`; the whole grid mirrors. Artwork and star glyphs never mirror. The back pill's glyph becomes `arrow_forward_ios`, chevrons become `chevron_left`. Dates go Shamsi and digits Persian, both in DM Mono so columns still align. **Persian carries no letter-spacing** — tracking pulls Arabic-script joins apart — and takes a taller line-height, 1.7–1.9 for a paragraph. The week starts **Saturday**, and mirroring alone does not achieve that: the sequence restarts at شنبه.

**Dynamic Type.** Content grows with the system font size. Chrome whose size carries structure — a seven-across week strip, a fixed-height pill — caps instead. A heading sharing a row with a control yields to the control.
