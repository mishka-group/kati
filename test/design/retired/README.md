# Boards whose screen was deleted

`Kati.ScreenDesignLiteralTest` asserts *every drawing has a screen*, and
`test/design/incoming/` exists for the other direction — a board delivered
before its screen was built. This is the third case: a board whose screen was
**deleted on purpose**, because building it turned out to have been the wrong
reading of the board.

A file here is design history and is kept. It is not in `screens/` because
nothing renders it, and a board in `screens/` with no module behind it turns
the whole suite red.

## 102 — Your year, shared, dark

MOVIES-AND-TV.md #3. Read as a dark colourway of screen 98 and built as a
second screen, and it is not one: `Kati.Theme.Palette.mode/0` reads the theme
at render time, so 98 already draws dark on a dark device and always did. What
102 actually held was **two card faces 98 never previewed** — the contribution
field and the genre bars — which made those two faces unreachable in light
mode, which is the reverse of what a colourway board is for.

Both faces are on screen 98 now, and out of the reader's own year rather than
`Kati.Stats.Sample`'s: the grid is `Kati.Screens.Stats`'s own 26 weeks and the
bars are the reader's own genres (#45). The board is here so the two faces can
be checked against what they were drawn as.
