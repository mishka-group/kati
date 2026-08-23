# Anime as a filter across four screens, not a section of its own

> **Four edits, drawn together** · issue [#21](https://github.com/mishka-group/kati/issues/21) · ticket `D-29`

Anime is a **type**, not a status and not a section. The four edits below are what that sentence costs, and they only work if they land as one change.

**Why it is not a seventh section.** The app's own rule is that *sections add shelves and feeds, never tabs*. A seventh tile would create a shelf and split a user's watching between two places for a distinction that is a property of a title, not a home for it.

## 1 · Screen 03 — an Anime filter chip

The shelf's tabs read `All 9 / Watching 4 / Finished 3 / Wishlist 2`. Anime is not a status, so it does not belong in that row.

Put it in **`D-26`'s filter sheet** alongside genre, service, language and format — *and*, when the user has a meaningful number of anime titles, surface it as a chip in the tab row too.

**Draw both placements and record which one wins**, including what "a meaningful number" is as a number.

## 2 · Screen 26 — where the choice is made during onboarding

Onboarding offers *"six section tiles, pick two to start"*. A seventh tile is the wrong shape.

Two options:

- **A sub-choice revealed when Screen is picked** — *"Do you watch anime? Kati will default those to absolute numbering."*
- A seventh tile that switches on the anime defaults rather than creating a shelf.

**Prefer the sub-choice.** It keeps the sections rule intact. Draw it **inside `D-23`'s first-run flow** so the flow map stays true.

## 3 · The importer — MyAnimeList and AniList tiles

`D-24` adds named source tiles to screen 37; two of them are these.

**MAL exports are absolute-numbered**, so the tile's preset must set the **numbering scheme**, not only the columns. State on the tile what comes across and what does not — MyAnimeList XML is importer-only, so this is the sole integration those users will ever get and the tile is the whole of their onboarding.

## 4 · Screen 35 — a per-show numbering default that explains itself

Screen 35 already carries per-show settings. Add a numbering row showing the **effective scheme and where it came from**:

> **Absolute** — because this is anime · *Override*

That phrasing is the point. An inherited default that announces its own reason is the difference between a helpful guess and a confusing one, and numbering is the single most common thing anime trackers get wrong.

## States to draw

| State | What it says |
|---|---|
| **Shelf, anime chip in the sheet** | placement A |
| **Shelf, anime chip in the tab row** | placement B, with the threshold met |
| **Onboarding sub-choice** | revealed under Screen, both answers |
| **Importer tile, MyAnimeList** | what comes across, what does not, numbering set |
| **Screen 35 numbering row, inherited** | *Absolute — because this is anime* |
| **Screen 35 numbering row, overridden** | how an override announces itself |
| **A title where the guess is wrong** | live-action with an anime tag, or the reverse |

## Reuse, do not invent

The chip recipe and its count badge · screen 26's tile grid · screen 37's source tiles from `D-24` · screen 35's settings rows · the standard list row with a trailing value.

## Left open — decide and note which way you went

- **What sets the anime flag.** A provider genre, a user tag, or the import source. Say which wins when they disagree — this is the decision the other three edits inherit.
- **The threshold for promoting the chip to the tab row**, as a number.
- **Whether absolute numbering changes what is displayed or only what is stored.** `S2 E6` and `E32` are the same episode; showing both is clutter and showing the wrong one is a bug.

---

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
