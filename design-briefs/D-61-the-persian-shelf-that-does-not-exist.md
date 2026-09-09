# The Persian shelf that does not exist

> **Full screen — one artboard** · ticket `D-61`

Screen 57 is the Persian Library and it has three segments: نمایش, کتاب‌ها,
موسیقی. Two of them now open shelves. The third opens screen 21, in English.

That is an improvement on what it did — until 5 September موسیقی pushed screen
76, one album's detail page, so pressing *Music* landed you on a single record
with a back pill reading کتابخانه and no way to reach any other. It was
reported from a device in exactly those words: *when I click on the music tab
the library tab opens.* The reporter was right about the symptom.

`D-38` had already fixed the identical mistake on کتاب‌ها, which used to drop a
reader into one fixture book. It drew board 176 and the segment opens it. This
is the same brief for the third segment.

## What to draw

| Board | What it is |
|---|---|
| **new** | Screen 21 in Persian — the music shelf, RTL, with موسیقی lit |

Board 176's relationship to screen 20 exactly, one noun over: the same page,
right to left, with the copy in Persian and the reader's own records in it.

Screen 21's bands, in order: the three-across album rail under **ON REPEAT
THIS WEEK** (padded to three when the shelf holds fewer — a rail of one took
the whole width and squared it, which board 176's grid also had to be taught),
the listening-time card, the release band under **NEW FROM ARTISTS YOU FOLLOW**,
and the shelf's `+`, which opens board 179's *Albums* state.

## What is already true and must not be redrawn

`Kati.Screens.Music` reads everything through `page/0` and every value on this
page has a real reader behind it. Board 179 and board 178 create records, board
180 rates them, screen 74 opens one and screen 77 its artist. The Persian
mirror needs the words and the direction, not a second set of readers —
`Kati.Screens.BooksFa` is the model and it composes screen 20's own readers
rather than repeating them.

Three copy questions the board settles, and they are the whole of what is
blocked:

  1. **ON REPEAT THIS WEEK**, **LISTENING TIME**, **NEW FROM ARTISTS YOU
     FOLLOW** — three eyebrows with no Persian yet.
  2. **PLAYS 0** and **0h 0m this month** — the count lines. Board 76 words
     its own more briefly than screen 74 does (`۴۱ پخش` against *41 plays · 6
     this month*), so this board should say which convention the shelf follows.
  3. The header's `1 albums · 0h this year`, which is also where the English
     one is ungrammatical at one and should be fixed in both.

## Acceptance

  * موسیقی opens a Persian music shelf, and `Kati.Screens.LibraryFa`'s
    `shelf_2` clause loses the paragraph explaining why it opens an English
    one.
  * With nothing shelved the page is its own drawing, whole, and
    `Kati.ScreenDesignLiteralTest` compares it in `fa`.
  * With one album shelved the rail draws one tile at a third of the width,
    not one square the height of the page.
