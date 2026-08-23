# The music variant of Auto-detect

> **A mode on screen 36, not a second screen** · issue [#20](https://github.com/mishka-group/kati/issues/20) · ticket `D-28`

Screen 36 detects what you watch. Draw what it looks like detecting what you listen to.

**Prefer a mode switch at the top of screen 36 over a duplicate board.** The sources, rules and disambiguation card are shared, and two boards will drift within one release.

> **Read this before drawing the permission row.** The "this phone" source on screen 36 has been **retired** — see #62. Google Play Protect blocks installation of sideloaded APKs that declare `NOTIFICATION_LISTENER`, and Kati is installed directly rather than through a store. So the permission row below is drawn as part of the *design record*, and its live state on the shipped app is the retired-tile treatment from #22: it keeps its place, reads `Not set up`, and tapping it opens the sheet that says why. **Draw both** — the row as it would be if the permission were available, and the retired state that actually ships.

## 1 · Now playing card

The same live geometry as the TV version — progress bar, live position — with **square album art**, artist, track and album. The threshold line changes from *"ticks at 90%"* to the scrobbling convention: **"scrobbles at 50% or 4 minutes"**.

**Draw the no-art variant.** Artwork here comes from the playing app's media session and is frequently absent — this is the common case, not the edge one.

## 2 · App allow-list

Toggle rows with per-app icons: Spotify, YouTube Music, Poweramp, Apple Music, and an **Everything else** catch-all. Group under a mono section label. Each row's sub-line states **what Kati does with that app's notifications**, in the purpose-before-asking voice screen 40 uses for permissions.

## 3 · The permission row, drawn very carefully

This permission is unlike every other one in the app and the row has to say so.

`NotificationListenerService` is **special access granted in system settings, not a runtime dialog**, and granting it lets an app read **every notification on the device — messages included**. Four things on the row, in this order:

1. **The purpose sentence** — what Kati wants it for.
2. **The scope sentence** — *"Kati reads only media notifications and never stores anything else."*
3. **An "Open system settings" action** — not an Allow button, because there is no dialog to raise.
4. **The revoked state** — what the row says after the user turns it off again.

**It must not be folded into the ordinary Notifications row on screen 40.** A permission that can read every message in a person's life does not belong in a list next to "show me notifications".

## 4 · Rules

Reuse the TV version's rules band with music-appropriate entries: minimum track length · whether repeats within a session count · whether to scrobble while headphones are disconnected · what happens to a track skipped at 45%.

## States to draw

| State | What it says |
|---|---|
| **Music mode, playing, with art** | the full card |
| **Music mode, playing, no art** | the common case |
| **Music mode, nothing playing** | what the card says at rest |
| **Permission not granted** | the purpose and scope sentences, and the settings action |
| **Permission revoked after being granted** | different wording from never-granted |
| **Retired** | the `Not set up` treatment that actually ships |
| **Mode switch** | TV and music side by side, so the switch is legible |

## Reuse, do not invent

Screen 36's now-playing card, sources list, rules band and disambiguation card · screen 40's permission-row voice · the toggle row · #22's retired-tile treatment and its explainer sheet.

## Left open — decide and note which way you went

- **Where the mode switch sits** — a segmented control under the title, or two chips in the header.
- **Whether the allow-list is per-app or a single switch** with an exceptions list. Five toggle rows for five apps does not scale to a phone with twelve music apps.
- **What the disambiguation card looks like for music.** The TV version resolves *"'Marram E3' or 'Marram Grass'?"*. Music's ambiguity is different — a live version, a remaster, a compilation appearance — and the card's three answers have to be the right three.

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
