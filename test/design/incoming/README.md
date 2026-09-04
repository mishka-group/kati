# Boards delivered, screens not built yet

Thirteen artboards from Claude Design, 4 September 2026, against briefs
`D-31`–`D-34`. They are here rather than in `screens/` because
`Kati.ScreenDesignLiteralTest` asserts *every drawing has a screen* — a board
in `screens/` with no module behind it turns the whole suite red, and a red
suite is a worse record of "these arrived" than this directory is.

**Move each file into `screens/` in the same commit that builds its screen**
and registers it in `Kati.Screens.Gallery`. The count assertion in that test
moves with it.

| # | Board | Brief | Unblocks |
|---|---|---|---|
| 154 | Add a title by hand | `D-31` | #91 |
| 155 | Add by hand — resting & refused | `D-31` | #91 |
| 156 | افزودن دستی — Add by hand, RTL | `D-31` | #91 |
| 157 | Add by hand — dark | `D-31` | #91 |
| 158 | خانه — nothing stored, RTL | `D-32` | #91 |
| 159 | خانه — nothing stored, dark RTL | `D-32` | #91 |
| 160 | The two empty sections — omitted, decided | `D-32` | #91 |
| 161 | Welcome — step 2 of 5 | `D-33` | #91 |
| 162 | Loudness — step 4 of 5 | `D-33` | #91, `LoudnessPrompt` |
| 163 | First title — step 5 of 5 | `D-33` | #91 |
| 164 | خوش‌آمد — welcome, RTL | `D-33` | #91 |
| 165 | اعلان‌ها — loudness, RTL | `D-33` | #91 |
| 166 | اولین عنوان — first title, RTL | `D-33` | #91 |

## Start with 154

The canvas caption says it plainly: *"until the catalogue lands, everything a
search finds is invented — so this form is the only path from a fresh install
to a library with anything in it. 89's hand-add row finally has a
destination."* Screen 89 draws that row today with **no `on_tap` at all**,
because nothing existed to open.

## 160 answers a question `D-32` left open

The brief asked whether an empty *تازه‌های این هفته* and an empty
*ادامه تماشا* should be worded or omitted. Board 160 is titled *"The two empty
sections — omitted, decided"*, so the answer is omission — and the app already
omits them, by accident rather than by decision. That is now a decision.

## 161–166 renumber the first run to five steps

`Kati.Onboarding.screen_for_step/1` is deliberately not locale-aware and its
comment explains why: artboard 137 is screen 26 in Persian, not 38. These six
boards are what let that comment be deleted rather than worked around, and
`LoudnessPrompt`'s entry — `38·3` routing forward — is board 162.

## Where they came from

`Kati.dc.html` in the Claude Design export, extracted by matching each
`data-screen-label="NN"` and taking the `<x-import>` block that follows it,
counting nested opens so the frame is not cut at the first close. Board 153 is
in that export too and is **not** taken from it: the canvas copy is 9.5KB
against the repo's 24.8KB, so it is a condensed re-render and importing it
would drop content the literal sweep checks.
