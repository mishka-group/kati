# Per-episode rating and review

> **Two edits, no new screen** · issue [#15](https://github.com/mishka-group/kati/issues/15) · ticket `D-25`

Screen 33 rates a title. A series is not a title — it is forty of them — and the one episode somebody wants to say something about is currently unreachable.

## Edit 1 — screen 04's episode rows

Add an optional **trailing rating value** to each row: DM Mono, mono-caption `#6E6860`, rendered as **a numeral plus one star glyph** — `4.5 ★` — not five glyphs.

Two reasons, and both matter:

- Five glyphs at row height is a handle-count problem: nobody reads five small stars, they read a shape.
- A numeral column **aligns**, which is the whole reason DM Mono exists in this app — *"everything that measures — times, counts, episode numbers, dates"*.

**An unrated watched episode shows nothing at all.** Not five hollow stars. The column stays clean and the ratings are the thing that stands out in it.

**A long press on a row opens screen 33 in its episode variant.** The design has no other long-press interaction, so it has to be taught — draw the affordance hint once, on first use.

> **This collides with `D-26` and the collision must be decided, not discovered.** That brief introduces long press on a shelf tile for multi-select. Two different meanings for one gesture is fine *if* the surfaces are unmistakably different and the decision is written down: long press on a **shelf tile** selects; long press on an **episode row** rates. Draw both hints and record the rule.

## Edit 2 — screen 33's episode variant

Same modal, same chrome — centred title, leading `close`, trailing **Save**. Three changes:

1. **Header** reads `S2 E6 · The Undertow`, series name as the subtitle. In **spoiler-safe** mode the episode title becomes `Episode 6`, which the app already does elsewhere. **Draw both.**
2. **Context rows** stay Watched on / Where / With, scoped to the episode.
3. **The rewatch case.** When this episode has been rated before, surface the previous rating and review **inline above the input**, on a cream card — the ground this app reserves for *anything personal you wrote*. The point is that the user reads their own past verdict while writing the new one.

## States to draw

| State | What it says |
|---|---|
| **Episode list, some rated** | the mixed column — the normal case |
| **Episode list, none rated** | no column at all; nothing to align |
| **Rating modal, first time** | empty, series subtitle, episode title shown |
| **Rating modal, spoiler-safe** | `Episode 6` instead of the title |
| **Rating modal, rewatch** | the cream card carrying the previous verdict |
| **Long-press hint** | shown once, and how it is dismissed |

## Reuse, do not invent

Screen 33's modal chrome, star control, review input and context rows · screen 04's episode row · the cream card · the DM Mono value column from screen 04's runtime figures.

## Left open — decide and note which way you went

- **Whether a rating implies watched.** Rating an unwatched episode is either impossible, or it ticks it. Pick one and say so on the board.
- **Where the half-star lands.** `4.5 ★` implies half-steps; screen 33's control has to support them or the numeral is lying.
- **Whether the rewatch card is dismissible.** A long review from two years ago could fill the sheet before the input is reached.

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
