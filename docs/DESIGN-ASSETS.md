# Where the design lives

The 152 artboards Claude Design drew are the specification Kati is built
against, and four things read them:

| Reader | What it takes |
|---|---|
| `Kati.ScreenDesignLiteralTest` | every text literal and Material Symbol, asserted against the rendered tree |
| `Kati.ScreenTitleSubtitleTest` | each title's subtitle `font-size`, family and `margin-top` |
| `Kati.ScreenEmptyDatabaseTest` | the same literals again, with nothing stored |
| `mix kati.gen.icons` | the symbol names, to build the shipped font subset |

    test/design/screens/NN.html     the board for screen NN, 01 through 153
    test/design/reference/          drawings that are not screens

They live under `test/` because that is what they are: fixtures. Four sweeps
read them and nothing at runtime does — `Kati.Icons` carries its glyph map
inlined, so the app ships without them. A top-level `design/` would have
implied the app needed them to run.

`test/design/reference/134.html` is the first-run flow map — a 1720px diagram with
no phone to fit on and no route that reaches it. It is #11's design record, and
`Kati.Screens.Gallery` says so where #11's screens are registered. Its README
also carries the argument for why screen 40's redraw is **not** built, which
#80 turns on.

`mix kati.gen.icons` also reads them, which is the one caller that is not a
test. That is the right trade: the generator exists to turn the drawings into a
font subset, so it follows the drawings rather than the drawings following it.

## `.scratch/` was removed on 24 August 2026

It had grown to 275MB, and 273MB of that was eleven near-identical directories
of audit screenshots. The boards moved here; everything else went.

**Moduledocs still cite `.scratch/…` paths in about thirty places.** Those are
not broken links to fix — they record where a piece of evidence was when a
decision was made, which is a different claim from "this file is here now". The
captures are in git history if one is ever needed again.

Two things went that git never tracked:

  * `.scratch/tickets/K-*.md` — the wayfinder's own work tickets. Not a loss:
    the old `.gitignore` excluded them precisely because *"those bodies were
    published as GitHub issues, which are canonical"*, and the native fences
    they covered are ledgered in `native/LEDGER.md` with a paragraph of
    reasoning each rather than a pointer.
  * `.scratch/fonts/` — a `KatiNumFa` experiment referenced by nothing, in
    Elixir, Kotlin, Gradle or prose. This one is genuinely gone rather than
    canonical elsewhere, which is the right weight for two `.ttf` files and two
    Python scripts nothing imported. The fonts Kati ships are in
    `android/app/src/main/res/font/`.

## Captures go to `.captures/`, which is not tracked

`bin/capture_all.py`, `compare_screen.py`, `check_screen.py`,
`light_vs_dark.py` and `diff_frames.py` read the boards out of `test/design/screens/`
and write everything they produce — device screenshots, comparison pages, the
stashed device state — under `.captures/`.

That split is the point. `.scratch/` held both, and its ignore rules ended in
`!.scratch/design/`, so eleven rounds of device screenshots were committed
alongside the specification and the tree reached 275MB. The boards are source
and are tracked; captures are output and are not.

`test/design/material_symbols.codepoints` is not in the repo and never was;
`mix kati.gen.icons` wants it and has wanted it for some time. The icon map it
generates is already inlined in `Kati.Icons`, so nothing is blocked until a new
symbol is needed.
