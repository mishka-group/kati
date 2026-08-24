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

## The capture tooling is gone

`bin/` held ten Python and shell scripts that drove a device over adb,
photographed every screen, framed the PNGs and diffed one run against another.
They are deleted, for two reasons.

**Three were superseded by Elixir.** `check_screen.py` grepped a screen's
*source* for the drawing's literals; `Kati.ScreenDesignLiteralTest` asserts them
against the *rendered tree*, which is the stronger claim and needs no device.
`tap_check.py` tapped a control and photographed the result;
`Kati.ScreenTapSweepTest` proves every drawn tag reaches a handler that changes
something, for every screen in both locales, in nine seconds. `measure_boot.py`
was replaced by `mix kati.boot`.

**Seven needed a device** — `capture_all.py`, `capture_all.sh`,
`compare_screen.py`, `diff_frames.py`, `frame_image.py`, `light_vs_dark.py` and
`test_capture_dark.py`. They were also what filled `.scratch/` with 273MB. If
device capture comes back it should come back as a mix task, not as a second
language sitting beside the one the app is written in.

`bin/deploy_native.sh` and `bin/mob_bridge_diff.sh` stay. Both are native-shell
maintenance with no Elixir equivalent, and both are documented where they are
used — `AGENTS.md` for the deploy, `native/README.md` for the three-way bridge
diff that keeps `native/LEDGER.md`'s fences honest.

## The light baseline outlived its screenshots

Several moduledocs say light mode is pinned by *62 captured frames*. Those
frames lived under `.scratch/design/audit_v7/` and went with the rest, and
nothing was lost: the frames established the numbers, they never enforced them.

`Kati.Theme.PaletteTest` writes the entire light column out by hand as a second,
independent copy of `Kati.Theme.Palette` — move a light value in the module and
that test fails by token name. `Kati.ThemeModeTest` holds the light palette as
literals and asserts `Kati.Theme.light/0` is byte-identical to them. A
screenshot cannot fail a build; a duplicated literal can, and these do.

References to *the audit_v7 capture* are therefore kept as what they are — the
vintage of the numbers, not a file to go and open.

`test/design/material_symbols.codepoints` is not in the repo and never was;
`mix kati.gen.icons` wants it and has wanted it for some time. The icon map it
generates is already inlined in `Kati.Icons`, so nothing is blocked until a new
symbol is needed.
