# Sorting, filtering and multi-select for the three shelves

> **One sheet + one mode, applied to three screens** · issue [#19](https://github.com/mishka-group/kati/issues/19) · ticket `D-26`

Four filter tabs are correct for a shelf of forty and useless for a shelf of four hundred. Add the escalation without losing the thing that works.

**Applies identically to screens 03, 20 and 21.** The design's own claim is that the second and third shelves are built *"from identical parts"* — three different filter sheets would end that, and the parts would drift within a release.

## 1 · The filter sheet

A trailing circular icon button in each shelf header — 40–44pt, `#FBFAF8`, small floating shadow — opens a bottom sheet:

- **Sort** — a list with a selected state: Recently added · Release date · Your rating · Title · **Runtime** (Screen) / **Pages** (Books) / **Length** (Music), each with an ascending/descending toggle.
- **Ranges** — year and rating.
- **Chips** — genre, service, language, format, status. Standard chip recipe **with count badges**, because a filter that leads to zero results should say so before it is tapped.
- **A live count line** — `showing 41 of 418`, DM Mono, updating as chips are toggled.
- **Reset** — a text action returning to the four default tabs.

**The four tabs stay as the default surface.** The sheet is the escalation, not the replacement. Draw the shelf with the tabs and the new button, so it is visible that nothing was taken away.

## 2 · Selection mode

**Long press on a poster tile** enters it:

- Selected tiles take the **selection ring**.
- A header bar replaces the shelf header: a count (`4 selected`), a close, and the actions.
- Actions: add to list · change status · remove. Destructive in `#B4553C`, and only that one.
- **Undo**, via screen 27's dark pill, because the activity log is append-only and doubles as the undo trail.

> **The gesture collides with `D-25` and the collision must be decided.** That brief gives long press on an **episode row** the meaning *rate this*. Here long press on a **shelf tile** means *select this*. Record the rule on both boards rather than letting each surface discover it.

## States to draw

| State | What it says |
|---|---|
| **Shelf, tabs only** | the default — unchanged except the new button |
| **Sheet open, nothing set** | every control at rest, count line at the full total |
| **Sheet with three chips set** | the count line down, Reset now meaningful |
| **A filter with no results** | say which chip emptied it, and offer to drop that one |
| **Selection mode, one selected** | the header bar, single-item wording |
| **Selection mode, many selected** | plural wording, and what happens above N |
| **Selection mode at 235%** | the header bar is the hard case; the count must not truncate |

## Reuse, do not invent

The bottom sheet from screens 106/124 · the chip recipe and its count badge · the selection ring · screen 27's undo pill and its empty-state geometry · the shelf header's existing search and sort discs.

## Left open — decide and note which way you went

- **The range mechanism.** Year and rating want a slider and the design has no slider component in its 38-row table. Either introduce one — with its accessibility story — or express ranges as chip buckets (`2020s`, `4★ and up`). Prefer the second unless the first earns itself.
- **Whether sort survives leaving the shelf.** A sort that resets on every visit is annoying; one that persists silently is confusing. Say which, and if it persists, show it on the resting header.
- **What happens to selection when a filter changes.** Selecting four, then filtering them away, has to do something.

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
