# The first-run sequence — one flow map, and the screens it is missing

> **One flow-map artboard + missing states** · issue [#11](https://github.com/mishka-group/kati/issues/11) · ticket `D-23`

Four onboarding screens exist and none of them knows about the others. Draw the sequence as a sequence, then draw the states the sequence needs and does not have.

## Why a map and not four more frames

Screen 38 is drawn as four numbered steps and the numbering does not match the order the app runs them in. Nobody can tell from the artboards which screen is step 1, where a skip goes, or where the app resumes if it is killed halfway. Those are not four separate questions — they are one flow that has never been drawn as one thing.

## The canonical sequence, to be drawn as a numbered map

```
53 Language ──► 38·1 Welcome ──► 26 Sections ──┬─► 38·3 Notification loudness ──► 38·4 First title ──► 01 Home
                                               │
                                               └─► [NEW] Restore from a backup ──► 37 Import ──► 01 Home
```

**Every arrow needs a drawn state and every screen needs its skip path drawn.** The map artboard is the deliverable: one board, the six screens as thumbnails or labelled nodes, arrows, skip paths, and the restore branch — plus the step numbers, so screen 38's own numbering can be corrected against it.

## Screen by screen

**53 Language.** Keep exactly as drawn — it is the strongest screen in the pass, stating three consequences per language *in that language's own script*. One addition: the choice takes effect **immediately**, so 38·1 already renders in the chosen language and direction. Note on the map that Kati does **not** detect the device locale — 53 is an explicit chooser with no auto-detect fallback.

**38·1 Welcome.** Add the quieter second path here, not only on 26: *"Already have a Kati backup? Restore it."* A returning user should not have to choose sections before being offered their own data back.

**26 Sections.** Keep the six tiles and "pick two to start". Two additions: an **Anime** tile if that lands, and a clearer statement that sections can be added later from screen 24.

**38·3 Notification loudness.** Keep Quietly / Notify me / Weekly digest, and draw what each one *does next* — this is the band that is missing entirely:

- **Quietly** → **the OS prompt is never raised.** One line confirms it: *"Kati won't ask for notification permission. Everything arrives in your inbox."* The inbox badge is already designed.
- **Notify me** / **Weekly digest** → the OS prompt is raised **on the next screen**, preceded by a one-sentence purpose card in the voice of screen 40's permission rows. Draw the pre-prompt card.
- **Denied** → draw it explicitly. Kati falls back to the inbox badge, says so **once**, and does not nag. Android will not re-prompt after a denial, so the only route back is system settings and the screen must say that rather than offering a button that silently does nothing.

**38·4 First title.** Keep, plus *"Skip — I'll add things later"* leading to the **empty Home**, which is not drawn anywhere. Screen 27's first band gives the vocabulary; Home's own empty state does not exist.

**[NEW] Restore from a backup.** The chromeless variant of `D-22`'s Screen B. From here it needs: a file-picker affordance, a QR scan matching screen 50's card, a pre-write summary in screen 37's *"384 New / 28 Merged / 6 Conflicts"* style, and a plain statement of what will be replaced. Draw it as part of this flow **and** hand the pushed variant to `D-22`.

## The states the flow needs and does not have

| State | What must be drawn |
|---|---|
| **First launch, no data** | the canonical path — the map's spine |
| **Relaunch mid-onboarding** | the app is killed after screen 26. **Where does it resume?** State it on the board; do not leave it to the build |
| **Backup from a newer Kati** | refuse clearly and wholly. Never half-import |
| **Corrupt or partial backup** | the error idiom with Retry |
| **Language changed after onboarding** | screen 54 owns this — draw the confirmation that direction, calendar, digits, week start and time format all follow, each still overridable |
| **Onboarding skipped entirely** | Home with zero sections chosen. Draw it; do not assume it cannot happen |

## Persian, and it is not optional here

Screen 53 makes the language choice **first**, so every screen after it can be Persian from the very first frame. Draw the Persian variant of **every** onboarding screen: RTL container, week starting Saturday, Shamsi dates, Persian digits.

This is the one flow where a missing Persian variant is not a gap in coverage but a broken first impression — a reader who chooses فارسی on screen 53 and lands on an English welcome has been told the choice did not work.

## Accessibility

Onboarding is chromeless and therefore has **no back pill**. Every screen still needs a visible way backwards — draw it. And draw each screen at **235% Dynamic Type** with nothing truncated; 26's six tiles and 38·3's three option rows are the hard cases.

## Reuse, do not invent

Screen 53's language cards · screen 26's tile grid and its "pick two" counter · screen 38's step-progress rule · screen 40's permission-row voice for the pre-prompt card · screen 37's pre-write summary · screen 27's empty-state geometry and error idiom · screen 50's QR card.

## Left open — decide and note which way you went

- **Where a killed app resumes.** The ticket asks for the answer, not for options. Pick one — the last completed step, or the beginning — and write it on the map.
- **Whether the map is one artboard or a spread.** Six nodes with arrows and skip paths may not fit 402×874 legibly. If it needs a wider board, take one; it is a map, not a screen.
- **Whether 38's four steps get renumbered.** They currently do not match the run order. Either renumber the artboards or draw the correspondence on the map explicitly.

---

## House style — Kati

Draw into `Kati.dc.html` as new `IOSDevice` artboards, **402×874** — except the flow map, which may take whatever width it needs to stay legible.

**Numbering.** The app now runs **01–127**. Nothing may be inserted below 127; these take the next free numbers upward.

**Type.** `Plus Jakarta Sans` for everything, `DM Mono` for data, counts, times, IDs and eyebrows, `Vazirmatn` for Persian. Material Symbols Rounded for glyphs.

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

- **Chromeless screen** — no back pill and no dock. Onboarding is chromeless; a visible way backwards must still exist.
- **Pushed screen** — scroller `padding: 64px 21px 40px`, floating back pill (44pt, radius 22, `#FBFAF8`, `arrow_back_ios_new` + parent name), frame closes at 40.
- **Root screen** — same, but the dock is drawn and the frame closes at 132.
- **Eyebrow** — a 13×2 rounded `#E8823C` rule, then DM Mono 10.5px, `.16em` tracking, uppercase, `#A0998F`. A quiet eyebrow swaps the rule to `#C4BDB3`.
- **Card** — `#FBFAF8`, radius 22, `box-shadow: 0 1px 2px rgba(26,25,23,.04), 0 12px 24px -18px rgba(26,25,23,.7)`.
- **List row** — 30×30 paper tile (radius 9, `#EFECE7`, glyph 17px `#5C574F`), 13.5px/600 title, 11.5px `#8A8479` second line, trailing chevron `#C4BDB3`. A chevron means *leads elsewhere*.
- **Chip** — height 32, radius 16, padding-x 15, 12.5px/600. Selected is `#1A1917` with `#FBFAF8` text.
- **Primary button** — height 54, radius 27, ink fill, 14.5px/700 in `#FBFAF8`. **One per screen.**
- **Step progress** — the four-segment rule screen 38 already draws.
- **Info footnote** — a bordered block with an `info` glyph, `#5C574F` body at 1.65 leading.

**RTL.** The container gets `dir="rtl"`; the whole grid mirrors. Artwork and star glyphs never mirror. The back pill's glyph becomes `arrow_forward_ios`, chevrons become `chevron_left`. Dates go Shamsi and digits Persian, both in DM Mono so columns still align. **Persian carries no letter-spacing** — tracking pulls Arabic-script joins apart — and takes a taller line-height, 1.7–1.9 for a paragraph. The week starts **Saturday**, and mirroring alone does not achieve that: the sequence restarts at شنبه.

**Dynamic Type.** Content grows with the system font size. Chrome whose size carries structure caps instead.
