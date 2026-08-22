# Your year, shared

> **Full screen** · issue [#14](https://github.com/mishka-group/kati/issues/14) · ticket `D-11`

Turn the numbers screen 07 already computes into a set of paged cards the user can render and save as an image on device.

## Where it is reached from

Screen 07 (Stats root, "Your year"). Its header already carries a 44 pt circular `ios_share` disc, drawn but deliberately inert (`lib/kati/screens/stats.ex:174` `share_disc/0`) — that disc is the entry point. The ticket also offers a row in 07's "More numbers" list (which today holds Activity log / Habits / Nutrition / Subscriptions) as the alternative.

## Bands, top to bottom

1. Back pill `‹ Stats` — `arrow_back_ios_new` + "Stats", matching 15, 22, 23
2. Large title, left-aligned 22 px, with a DM Mono year-range subtitle ("Jan – Aug 2026", as on 07). Ticket does not specify the title copy
3. Section switcher chip row: All · Screen · Books · Music · Meals · Habits (one selected, ink fill)
4. Horizontal card pager, four pages — Hours, Top titles, Genres, Pixel field — current card at Square (4:5), next card peeking, page dots beneath. No orange anywhere on the card
5. Aspect segmented control: Square · Story
6. Toggle row: "Hide titles I marked private"
7. Ink primary button: "Save image" — the only button colour on the screen
8. Quiet secondary text action: "Share…", drawn muted and annotated as dependent on file sharing landing (K-37; Mob.Share is text-only today)
9. Info footnote stating everything renders on this device and nothing is uploaded. Ticket requires the statement but specifies no wording

## States to draw

- default — light, LTR, Screen section selected
- non-film section selected — Books or Music, so the headline changes (pages or hours read / minutes listened)

## Reuse, do not invent

Back pill; large-title header; filter/scope chip row (section switcher); segmented control (track #E4E0D9, thumb #FBFAF8); toggle row (iOS switch, ink when on); primary button (#1A1917, 44–54 pt, radius 22–27, shadow `0 14px 28px -12px`); elevated card (#FBFAF8, radius 18–22) as the card frame; pixel field (104 cells, bronze ramp, 2 px radius); horizontal bar chart; poster stack; delta badge; mono section label; info footnote.

## Left open — decide and note which way you went

Entry point — a "More numbers" row vs. the header `ios_share` disc (07 already draws the disc, unwired). Screen title copy. The on-device/no-upload wording and which band carries it. Whether books' headline is pages read or hours read. The screen number(s) — the ticket says only "from 63 upward".

---

## House style — Kati

Draw into `examples/ui_design/Kati.dc.html` as a new `IOSDevice` artboard, 402×874.

**Numbering.** The app runs **01–62** and nothing may be inserted below 62. This screen takes the
next free number.

**Type.** `Plus Jakarta Sans` for everything, `DM Mono` for data, counts, times, IDs and eyebrows,
`Vazirmatn` for Persian. Material Symbols Rounded for glyphs.

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

Dark ground is `#121110`, card `#1E1D1B`, ink `#F5F2EE`.

**Recipes already in the app** — reuse rather than invent:

- **Pushed screen** — scroller `padding: 64px 21px 40px`, floating back pill (44pt, radius 22,
  `#FBFAF8`, `arrow_back_ios_new` + parent name), no dock, frame closes at 40.
- **Root screen** — same but the dock is drawn and the frame closes at 132.
- **Eyebrow** — a 13×2 rounded `#E8823C` rule, then DM Mono 10.5px, `.16em` tracking, uppercase,
  `#A0998F`. A quiet eyebrow swaps the rule to `#C4BDB3`.
- **Card** — `#FBFAF8`, radius 22, `box-shadow: 0 1px 2px rgba(26,25,23,.04), 0 12px 24px -18px rgba(26,25,23,.7)`.
- **List row** — 30×30 paper tile (radius 9, `#EFECE7`, glyph 17px `#5C574F`), 13.5px/600 title,
  11.5px `#8A8479` second line, trailing chevron `#C4BDB3`. A chevron means *leads elsewhere* —
  never use one for a row that does not push a screen.
- **Chip** — height 32, radius 16, padding-x 15, 12.5px/600. Selected is `#1A1917` on ink with
  `#FBFAF8` text.
- **Pill button** — height 30, radius 15, `#EFECE7`, 11.5px/600.
- **Primary button** — height 54, radius 27, ink fill, 14.5px/700 in `#FBFAF8`. **One per screen.**
- **Progress bar** — 2px, track `#C4BDB3`, fill `#E8823C`.

**RTL.** The container gets `dir="rtl"`; the whole grid mirrors. Artwork and star glyphs never
mirror. The back pill's glyph becomes `arrow_forward_ios`, chevrons become `chevron_left`. Dates go
Shamsi and digits Persian, both in DM Mono so columns still align.

**Dynamic Type.** Content grows with the system font size. Chrome whose size carries structure —
a seven-across week strip, a fixed-height pill — caps instead. A heading sharing a row with a
control yields to the control.
