# Data sources

> **Settings page** · issue [#7](https://github.com/mishka-group/kati/issues/7) · ticket `D-04`

Shows which metadata providers Kati uses, lets the user swap in their own API keys or connect an account, and states plainly where those tokens are stored.

## Where it is reached from

Screen 24 (Settings) — a new list row in the Data group; ticket's suggested placement is directly above the About group (confirmed: 24.html has Data = Import / Export everything / Sync / Clear watch history, then About = Version / Privacy).

## Bands, top to bottom

1. Back pill `‹ Settings`
2. Large title "Data sources" + 13.5px #A9A29A subtitle: "Where Kati's posters, covers and facts come from."
3. Mono label + orange rule: WORKING OUT OF THE BOX
4. Three keyless provider rows — "TV & film · TVmaze", "Books · Open Library", "Music · MusicBrainz": 40×40 icon tile, provider name, 11.5px sub-line naming what it supplies, status dot (green #4E9A73 = reachable), last-checked timestamp in DM Mono
5. Mono label + orange rule: BETTER ARTWORK AND METADATA
6. TMDB card with segmented control — "Use Kati's key" (default) / "Use my own key"
7. Tinted info footnote under TMDB saying three things plainly: Kati's key is public because the app is open source; that costs the user nothing because TMDB rate-limits by IP address not by key; a personal key means personal limits (exact wording not given by the ticket)
8. "Use my own key" revealed state — paste field + Verify action (draw collapsed on this artboard; success/failure go on the states sheet)
9. Mono label + orange rule: CONNECT AN ACCOUNT
10. Disconnected Tier-2 rows — candidates named by the ticket: ListenBrainz (personal token), Hardcover (token), TheTVDB (subscriber key), Google Books (key); Trakt/Simkl/Last.fm only if the owner accepts pasting a client_secret. Final list is NOT fixed by the ticket
11. One Tier-2 row expanded: short "why this needs your own credentials" explanation, then either a paste field or a device-code pairing card — 6-character code in DM Mono at hero numeral size + a URL, styled like screen 50's QR card
12. The same Tier-2 row drawn again in its connected variant (ticket requires both variants of one row)
13. Mono label + orange rule: WHERE YOUR TOKENS LIVE
14. Tinted info card in Kati's voice: tokens are stored unencrypted on this device because the platform provides no secure storage yet; Kati never sends them anywhere except to the service they belong to; Kati never asks for a password, only for tokens you can revoke from the provider's own site (exact wording not given)
15. Destructive row "Disconnect everything and wipe tokens" in #B4553C
16. Mono label + orange rule: CACHED METADATA
17. Cache row "34 MB · oldest entry 2 months" in DM Mono, with Refresh and Clear actions
18. One-line footnote naming the six-month ceiling as a rule Kati keeps rather than a limitation it suffers (exact wording not given)

## States to draw

- all good (default: three green dots, TMDB on Kati's key, nothing connected)
- one Tier-2 row connected (drawn alongside its disconnected twin on the same artboard)

## Reuse, do not invent

Pushed scroller (padding 64px 21px 40px), back pill `‹ Settings` (as on 25/27/32/36/37/39/40/41/54), large title header + 13.5px #A9A29A subtitle, mono section label with 13×2px orange rule (design-index:183), list row 40×40 icon tile + 13.5px/600 title + 11.5px sub (design-index:184), elevated card #FBFAF8, segmented control track #E4E0D9 (design-index:186), info footnote in tinted card (design-index:203), screen 50's QR/pairing card treatment for the device code (design-index:147), palette dots green #4E9A73 / hairline #C4BDB3 / red #B4553C.

## Left open — decide and note which way you went

Blocked by K-29 and K-30 — the ticket says draw after they land, or draw both variants and mark them. (1) K-29: whether Kati ships TMDB's key in-repo at all, and therefore whether the Use Kati's key / Use my own key segmented control exists. (2) K-29 attached: which Tier-2 providers appear at all; do NOT draw Trakt as a first-class connected service until the owner decides (its free tier was cut to 2 lists of 100 items / 100-item watchlist in Feb 2025). (3) K-30: what the cache row's size and oldest-entry numbers actually measure. (4) Where "Data sources" sits in screen 24's list — ticket says decide and record; natural place is directly above About. (5) Exact copy for the TMDB footnote, the token-storage disclosure and the cache footnote is described but not written. (6) Screen number: "63 upward", not fixed. (7) Optional and conditional: if a diagnostic/debug view of outbound requests is drawn, the User-Agent must read exactly `Kati/0.1.0 ( https://github.com/<owner>/kati )`.

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
