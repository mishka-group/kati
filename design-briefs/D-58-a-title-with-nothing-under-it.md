# A title with nothing under it

> **Full screen — one new artboard, one Persian mirror** · ticket `D-58`

You add a show by hand, because Kati could not find it. It goes on the shelf,
with its name and the poster placeholder screen 154 promised. You tap it. And
you are looking at *The Long Hollow* — a show you have never heard of, with a
season bar, seven episodes and a next-episode date.

That is happening today, on every device, and the code is not confused about it.
`Kati.Screens.Library.shaped/3` carries the tapped row's id, screen 04 reads it,
finds the right tracked row — and then `facts/1` (`series.ex:294-303`) answers
`nil`, because a hand-typed title has no `Kati.Media.CachedSeason` and no
`Kati.Media.CachedEpisode` behind it. With no seasons, screen 04 has no spine,
so it falls back to the branch it takes when nobody named a title at all: the
drawing.

**The gate is right and must stay.** A page whose whole structure is a season
bar and an episode list cannot draw a title that has no episodes. What is
missing is the state in between, and nothing in 01–166 draws it.

Screen 154's own caption already admits the situation exists — *a hand-typed
title carries no poster and no episode list. If Kati finds it later both arrive,
and nothing you typed is overwritten.* This brief is the consequence of that
sentence, drawn.

## What to draw

| Board | What it is |
|---|---|
| **248** | Screen 04 for a title with no episodes — the English one |
| **249** | The same in Persian, the mirror of 58 |

Not a new screen: **248 is screen 04 in a state**, the way 139 is screen 01 in a
state. It keeps 04's frame, its back pill and its ⋯ disc, and replaces the
season bar and the episode list with what this title can honestly say.

## What is on it

Above the fold, unchanged from 04 and drawn from the row the user typed:

- **The poster placeholder.** The same empty plate the shelf tile draws — no
  artwork exists and inventing one would be a picture of a show nobody has.
- **The title**, at 04's 28pt heading size, and **the year** if one was typed.
  Both are `Kati.Media.CachedTitle` fields written by the hand-add form.
- **The status chip** — *Watching*, *Not started* or *Finished*, which the form
  collects and the shelf already draws under the tile.

Where the season bar sits on 04, a **cream claim card** (`#FBF1DE`) with:

- Glyph `menu_book` for a book, `movie` for a film, `live_tv` for a series —
  the same three the hand-add form's Kind row uses.
- A line that says what is true: **"No episode list yet."**
- A second line saying why, in the voice screen 154 uses: *You added this by
  hand, so Kati has no seasons or episodes for it. If a source finds it later,
  they arrive here and nothing you typed changes.*

Then the actions that still work, as 04's own action row rather than as new
controls:

- **Log a watch** — `replay`. Screen 33 needs only a
  `Kati.Media.TrackedTitle`, which this title has, so this one is live.
- **Drop this show** — the ⋯ row 04 already draws, opening the drop sheet
  (149). Dropping something you added by hand is an ordinary thing to want.
- **Remove from library** — also in ⋯, as on 04.

**What must NOT be drawn:** a *Mark next watched* button. There is no next
episode to mark, and a primary button that refuses is worse than no button. 04's
one primary slot stays empty on this state — which is why this is a state of 04
and not a page of its own.

## The states it must cover

1. **Resting** — the above, with a status of *Not started*.
2. **Watching** — the same with the status chip lit, because a hand-added show
   can be one you are part-way through even with no episode list.
3. **The moment it fills** — optional, and the most useful thing you could draw:
   the same title after a source found it, so the difference between this state
   and 04 proper is visible in one place. If you draw it, draw it as a reference
   sheet in 27's manner rather than as a fourth artboard.

Kati's sweeps compare a screen's empty state against a board, so a state nobody
draws is a state nothing tests. That is why 1 and 2 are not optional.

## RTL

**249 mirrors, and the artwork does not.** The grid flips, the back pill's glyph
becomes `arrow_forward_ios`, the ⋯ disc moves to the leading edge. The poster
placeholder does not mirror — a plate is a plate, and
`Kati.Screens.LibraryFa` records the same rule for the shelf.

The claim card's text is Persian and the title is whatever the person typed:
`Kati.Media.CachedTitle.title` is what is drawn, so a Persian install that typed
a Persian name shows a Persian name, and one that typed a Latin name shows that.
Do not draw a transliteration.

## Dark colourway

**Not needed.** 04 has no dark board and this is a state of 04; adding one here
would be the first, and it would sit in `@no_route` as a picture rather than a
place. The palette's dark tokens cover it — `cream` has no dark twin and the
claim card should take `card` on `#121110` instead, which is a token swap rather
than a drawing.

## Reuse, do not invent

The claim card is screen 154's own cream note, at the same radius and padding.
The status chip is the shelf's. The action row is 04's. The poster placeholder
is the shelf tile's, scaled. Nothing here is a new component, and it should not
look like one.

## What it must NOT contradict

`Kati.Screens.Series`'s moduledoc gates the whole screen on having seasons, and
that gate is load-bearing — `test/kati/screen_empty_database_test.exs` pins
screen 04's fallback as the branch that answers with the drawing when nothing is
stored. **This board is a third branch, not a replacement for that one.** A
title that names no tracked row at all still draws the drawing; a title that
names one with no episodes draws this.

And screen 154's promise: *nothing you typed is overwritten*. Whatever this
board says about a source arriving later must not imply the typed title is
provisional.

## Left open — decide and note which way you went

- Whether the claim card carries a **Look it up** action that re-runs the search
  for this title against a source. It is the obvious next thing a person wants
  and there is no catalogue behind it yet, so drawing it makes a promise the app
  cannot keep this version.
- Whether *Watching* is even offerable without episodes, or whether the status
  chip should read *Added by hand* and drop the three-way status entirely on
  this state.
- Whether a hand-added **film** gets this board too. A film has no episode list
  by nature, so screen 08 may already be complete for it — check 08 before
  drawing a second thing.

## Acceptance

The drawing is complete enough to build from when: a person can tell, from the
board alone, what the app knows about this title and what it does not; the two
required states are drawn; the Persian mirror shows which parts flipped and
which did not; and every element on it is traceable to a field the hand-add form
actually collects. If an element needs a value screen 154 does not ask for, it
is not buildable and should come off.

## House style — Kati

**Numbering.** The app runs **01–166** and nothing may be inserted below 167. Boards 167–247 are
reserved by `D-35`–`D-57`; this brief takes **248** and **249**.

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
