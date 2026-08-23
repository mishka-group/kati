# Where are you coming from — named source tiles for the importer

> **One new step on screen 37 + its states** · issue [#12](https://github.com/mishka-group/kati/issues/12) · ticket `D-24`

Screen 37 asks a first-time user to map nine columns by hand before they have seen a single row of their own data arrive. Give it a step 0 that recognises where the file came from and does the mapping for them.

## Why this one is worth its size

Import is the **only** moment a switcher meets Kati with nothing in it. A nine-column mapping table is a wall in front of the one screen that has to feel like an easy yes, and every product they are switching from — Goodreads, Letterboxd, Trakt — exports a file whose shape is already known. The mapping is not a question that needs asking; it is a question that has an answer.

## Step 0 — "Where are you coming from?"

A grid of source tiles. Each is a small elevated card carrying a wordmark or a letter tile, the source's name, and an 11.5px sub-line naming the **file it expects** — because the commonest failure here is bringing the wrong file, and the tile can prevent it before the picker opens.

| Tile | Expects |
|---|---|
| Goodreads | `goodreads_library_export.csv` — the highest-volume case |
| StoryGraph | CSV export — carries moods and pace |
| Letterboxd | ZIP, or `diary.csv` / `watched.csv` / `ratings.csv` |
| Trakt | JSON export |
| Simkl | CSV / JSON |
| TV Time | CSV |
| Libib | CSV |
| MyAnimeList | XML — **absolute numbering**, see `D-29` |
| AniList | export |
| Last.fm | CSV via third-party exporters |
| **Kati backup** | `.json` — routes to `D-22`'s restore path instead |
| **Something else** | any CSV — the existing manual mapper, unchanged |

Choosing a tile **pre-fills the column mapping and the unit conversions** screen 37 already performs — it advertises *"converts 10pt → 5★"* — and jumps straight to the pre-write summary. The mapping stays inspectable behind a **"Check the mapping"** row for anyone who wants it; it is skipped, not hidden.

**Kati backup and Something else are the two tiles that do not behave like the others** and must not look like they do. One leaves screen 37 entirely. The other is the old path. Set them apart from the grid.

## Steps 1–4

- **Step 1 — the file.** Keep the existing file card (*"418 rows · 9 columns"*), and add the detected source name plus **"Not ⟨source⟩? Change"** for a wrong guess. A guess that cannot be corrected is worse than no guess.
- **Step 2 — the mapping.** Unchanged for *Something else*. For a named source, **collapsed by default** with a one-line summary of what was matched, expandable.
- **Steps 3–4 — the pre-write summary and the conflict resolver.** Untouched. Do not redraw them.

## States to draw

| State | What it says |
|---|---|
| **Source picker, nothing chosen** | the default entry — the grid |
| **Recognised** | tile chosen, mapping pre-filled, summary line |
| **Wrong guess** | the "Not ⟨source⟩? Change" path taken, back at the grid |
| **Mapping expanded** | the preset shown as a table, still editable |
| **Unrecognised file for a named tile** | Goodreads chosen, a Letterboxd file given — say which it looks like and offer that tile |
| **Partial columns** | the source is right but the export is old and lacks a column. Name the column and say what will be missing |

## Reuse, do not invent

Screen 37's file card, mapping table, pre-write summary and conflict resolver · the small elevated card · the standard list row and chip · screen 27's error idiom for the wrong-file case.

## Left open — decide and note which way you went

- **Grid or list for the tiles.** Eleven tiles is a lot of grid on a 402pt board. A two-column grid of the six commonest with a "More" row may read better than eleven equal cards.
- **Whether the sub-line names the file or the format.** `goodreads_library_export.csv` is precise and long; "CSV export" is short and less useful. Pick one rule and apply it to all eleven.
- **Where the Kati-backup tile sits.** In the grid with different treatment, or above it as its own row.

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
