# Back up everything, and Restore from a backup

> **Two full screens + one states sheet** · issue [#25](https://github.com/mishka-group/kati/issues/25) · ticket `D-22`

Three screens in the app already promise a backup and none of them leads anywhere. Draw the two screens that make the promise true, and the states sheet that says what happens when it cannot be kept.

## Why this one matters more than its size suggests

Kati has **no server, by locked decision**. Everything is on one phone. That makes the backup screen the only thing standing between a user and losing four years of reading, watching, meals and habits when a phone dies — and it makes the honest note at the bottom of Screen A the most important sentence on either screen. This is not a settings page; it is the app's answer to *what happens when the phone is gone*.

## Where they are reached from

Both are pushed under **Settings → Data**, back pill `‹ Settings`. Screen B is additionally **chromeless** when it appears in the first-run chain — see `D-23`, which draws that flow.

Five existing screens currently promise one of these and route nowhere. Each needs its row pointed at the right one of the two:

| Screen | Row | Goes to |
|---|---|---|
| 24 Settings | Data → **Export** | Screen A |
| 24 Settings | Data → **Import** | Screen B — *and* screen 37 for third-party files |
| 26 Sections | "Import from a backup instead" | Screen B |
| 27 States | "or import a backup" | Screen B |
| 40 This device | Last backup · Move to a new phone | Screen A |
| 50 Share a plan | its meal-plan export | stays; gains a line pointing at Screen A |

**Screen 24's two import paths must look different.** *Your own Kati backup* and *someone else's export* are not the same act and must not read as one row with two meanings.

---

# Screen A — Back up everything

## Bands, top to bottom

1. **Title block** — "Back up everything", DM Mono kicker beneath.

2. **Status card.** `Last backup: 14 Aug · 2 weeks ago · 214 MB` — figures in DM Mono. The empty value is the word **"Never"**, and it is drawn as a *gentle warning* (cream ground, bronze mark) rather than as an error in red. Never having backed up is the default state of every user who has not yet; it is not a fault. This same card appears on screen 40.

3. **What travels with it.** Screen 50's list idiom exactly, scoped to the whole library: every section, ratings, reviews, notes, sessions, habits, meals, plans, the calendar events Kati owns, settings.

   Then, in the same list and visibly separated, **what does not travel**:
   - cached provider metadata — re-fetchable, and capped at six months by TMDB's terms anyway
   - connected tokens — revocable, and meant to be re-entered on the new device

   Saying what is missing is the point of the block. A restore that silently lacks artwork is worse than one that said it would.

4. **Format** — a segmented control or a row set, three values:
   - **Everything (JSON)** — the restorable one
   - **Per-section CSV** — the portable one, for a spreadsheet or another app
   - **Calendar (.ics)** — because Kati owns a calendar and `.ics` is what a calendar is

5. **Primary action** — one ink button, "Save a backup". It opens the system file picker.

6. **The honest note** — an info footnote. Kati has no server, so a backup is a file you keep. Say where to keep it: a cloud drive, a computer, anywhere that is not only this phone.

---

# Screen B — Restore from a backup

Two entrances, one screen. Pushed from Settings it wears the back pill; in the first-run chain it is chromeless.

## Bands, top to bottom

1. **Choose a file** — the system picker, plus a **QR scan** path drawn to match screen 50's QR card, for moving a settings profile or a plan between two phones in the same room.

2. **A pre-write summary** — screen 37's exact idiom, *before anything is written*:

   > **384 New** · **28 Merged** · **6 Conflicts**

   On an empty device the three numbers collapse to one count and the screen says so plainly: *"This device has no data. Everything will be restored."*

3. **A conflict resolver** — **Keep mine / Take file / Keep both**, with `1 of 6 · apply to all`. Reuse screen 37's verbatim. Do not redesign it.

4. **A destructive alternative**, clearly separated from everything above — **"Replace everything on this device"** in `#B4553C`, with its own confirmation. The merge path and the replace path must not be two buttons of equal weight side by side.

---

# Screen C — the states sheet

Eight states, in screen 27's manner — one board, banded, each with its eyebrow.

| State | What it says |
|---|---|
| **Never backed up** | the warning treatment; the default for every user |
| **Backed up recently** | the neutral case |
| **Backup stale** | more than N weeks — *state N on the board* |
| **Export not available yet** | the honest state if the native file-write path has not landed. Explain it, and offer the per-section text export that a text-only share *can* do |
| **Restoring** | progress, and what is safe to do while it runs |
| **Newer-version refusal** | a backup written by a later Kati. Refuse **clearly and wholly** — never half-import |
| **Corrupt or partial file** | the error idiom with Retry |
| **Restore finished** | what came back, in numbers |

## Reuse, do not invent

Screen 50's "what travels" list and its QR card · screen 37's pre-write summary and conflict resolver · screen 24's Data group rows · screen 27's banded states board and its empty-state geometry · the standard list row, info footnote, segmented control, primary ink button and `#B4553C` destructive treatment.

## Left open — decide and note which way you went

- Whether **Everything (JSON)** and **Per-section CSV** are one control with three values or two separate rows with their own actions. The ticket names both formats and not the control.
- Whether the QR path on Screen B carries a whole backup or only a settings profile. A QR code's payload is small; a library is not. If it is profile-only, say so on the board.
- Where the stale threshold sits. Pick a number and write it.

---

## House style — Kati

Draw into `Kati.dc.html` as new `IOSDevice` artboards, **402×874**.

**Numbering.** The app now runs **01–127**. Nothing may be inserted below 127; these take the next free numbers upward.

**Type.** `Plus Jakarta Sans` for everything, `DM Mono` for data, counts, times, sizes, IDs and eyebrows, `Vazirmatn` for Persian. Material Symbols Rounded for glyphs.

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
| red | `#B4553C` | destructive, and only destructive |

Dark ground is `#121110`, card `#1E1D1B`, ink `#F5F2EE`.

**Recipes already in the app** — reuse rather than invent:

- **Pushed screen** — scroller `padding: 64px 21px 40px`, floating back pill (44pt, radius 22, `#FBFAF8`, `arrow_back_ios_new` + parent name), no dock, frame closes at 40.
- **Chromeless screen** — no pill and no dock; a visible way backwards must still exist.
- **Eyebrow** — a 13×2 rounded `#E8823C` rule, then DM Mono 10.5px, `.16em` tracking, uppercase, `#A0998F`. A quiet eyebrow swaps the rule to `#C4BDB3`.
- **Card** — `#FBFAF8`, radius 22, `box-shadow: 0 1px 2px rgba(26,25,23,.04), 0 12px 24px -18px rgba(26,25,23,.7)`.
- **List row** — 30×30 paper tile (radius 9, `#EFECE7`, glyph 17px `#5C574F`), 13.5px/600 title, 11.5px `#8A8479` second line, trailing chevron `#C4BDB3`. A chevron means *leads elsewhere* — never use one for a row that does not push a screen.
- **Chip** — height 32, radius 16, padding-x 15, 12.5px/600. Selected is `#1A1917` with `#FBFAF8` text.
- **Pill button** — height 30, radius 15, `#EFECE7`, 11.5px/600.
- **Primary button** — height 54, radius 27, ink fill, 14.5px/700 in `#FBFAF8`. **One per screen.**
- **Info footnote** — a bordered block with an `info` glyph, `#5C574F` body at 1.65 leading.

**RTL.** The container gets `dir="rtl"`; the whole grid mirrors. Artwork and star glyphs never mirror. The back pill's glyph becomes `arrow_forward_ios`, chevrons become `chevron_left`. Dates go Shamsi and digits Persian, both in DM Mono so columns still align. **Persian carries no letter-spacing** — tracking pulls Arabic-script joins apart — and takes a taller line-height, 1.7–1.9 for a paragraph.

**Dynamic Type.** Content grows with the system font size. Chrome whose size carries structure caps instead. Draw both screens at 235% with nothing truncated.

**Both variants of both screens.** Light and dark, English and Persian. Four boards per screen if that is what it takes.
