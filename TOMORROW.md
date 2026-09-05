# Where this is, and what to pick up

Written 5 September 2026, at the end of the session. Branch `dev`, working tree
clean, **nothing pushed** — 14 commits sit ahead of `origin`.

    mix test          # 2478 passed, 1 excluded
    mix format --check-formatted    # clean
    MIX_ENV=test mix compile        # zero warnings

---

## Start here

**The `D-62` boards are waiting in `/Users/shahryar/Downloads/Personal app with
media library/`.** I did not open them — the session ended first. That export
has the same shape as the last one: `Kati.dc.html` (3.4 MB, 259 caption blocks)
and an `uploads/` folder of 59 briefs.

First job tomorrow, in this order:

1. **Diff the export against `test/design/incoming/`.** The last export's 91
   boards went in there and 8 have been built since; whatever is new goes in
   beside them. `test/design/incoming/README.md` has the rule and both export
   hazards written down — read it before moving anything.
2. **The export's boards carry no `max-width:380px` caption block.**
   `Kati.ScreenDesignLiteralTest` asserts exactly one per registered screen, so
   a caption div gets appended after `</x-import>` when a board moves into
   `test/design/screens/`. This caught all three agents last time.
3. **`assert length(on_disk) == 173`** in `test/kati/screen_design_literal_test.exs`
   moves with the count. It is the one line every parallel worker touches.

`D-62` asked for **two boards and one card state**:

| Wanted | Unblocks |
|---|---|
| **One service** — name, price, renewal, shared-with, destructive remove at the foot | 7 rows on screens 92 and 93 |
| **Lending** — who has the book, since when, due when, the *returned* action | the ownership chevron on 66, 68, 69 |
| Screen 43's card in its **prepped** state | `done_prepping` and 5 neighbours |

The export mentions *lending* / *lent to* / *one service* fourteen times, so at
least some of this is probably in there. Check before assuming.

**Not needed:** the series chevron. Its destination is screen 20 filtered by
series, which already exists — a decision, not a drawing.

---

## The one decision that blocks work

**What is a prep, and what does *done* mean?**

`Kati.Meals.Recipe` stores a method, a duration and an oven temperature, and
nothing anywhere records that a prep was done — which is why screen 43's
**Done prepping** and five neighbours are inert.

Per recipe, per day, or per meal-plan slot? A recipe prepped on Sunday for
Wednesday's dinner is prepped for a **slot**, not for itself, so `prepped_at`
on `Kati.Meals.Recipe` answers the easy version and the wrong one, and
`Kati.Meals.MealPlanSlot` is where it belongs. Decide, then the column, then
the card's second state.

---

## What landed today

Fourteen commits. The through-line is one sentence: **a control must not be
drawn as a live affordance while doing nothing, and a page must not state a
fact nobody gave it.**

### Three native capabilities, each with a ledger row

| Fence | What it does | Verified |
|---|---|---|
| `K-43 open-url` | one `http`/`https` URL into `ACTION_VIEW` | tapped the TMDB card on screen 85 → `topResumedActivity=com.android.chrome` |
| `K-44 open-settings` | a **closed set** of Kati words — `battery`, `notification_listener`, `app` | both destinations resolve on the emulator; its own screen is on `@no_route`, so host tests pin the wiring |
| `K-45 capture-screen` | `view.draw` into a PNG in `cacheDir`, dirty NIF | screen 121's *Save image* works |

All three refuse a caller-supplied action or scheme. `startActivity` with an
arbitrary string is a way to launch anything on the device, and the strings in
this app come from screens.

### The API was dead on every device ever built

`Kati.Media.Tmdb.key/0` read `System.get_env/1` — read on the machine the code
RUNS on, which is a phone with no environment. The token is now also captured
at compile time and travels in the pushed BEAM; `Mix.env() == :test` captures
nothing, so no test binary carries credentials and the *no key* test keeps its
coverage. **Type `matrix` on the phone → 17 real results.**

It also failed **silently**: screen 06 had composed *"No TMDB key yet. Add one
in Settings → Data sources."* since it was written and never drawn it. That is
the defect that recurs in this codebase — a failure put on the socket and never
rendered — and it is now fixed on screens 06, 83, 85, 112, 121 and 151.

### `D-59` — two pages that stated facts nobody gave them

* **Screen 112.** `Kati.Health.Dose` had `create: :*` and **no caller
  anywhere**, so today's doses gated on a table nothing could fill while the
  schedules gated on one that had just been filled. Doses now DERIVE from each
  medication's `times` — the way the reminder already arms — and a row is
  written the first time you tick one. The whole page asks one question. On a
  device: add a medication → `SATURDAY 5 SEPTEMBER · 1 DOSE`, your own
  medication at 08:00, your own reminder card. Tick it, leave, come back →
  byte-identical screenshot.
* **Screen 69.** `books_fa.ex` matched `"open_book_" <> _key` and **threw the id
  away**; `mount/3` took no params. Tapping the second cover opened the first
  book — twenty wrong facts once `own/3` carried the row — and then تمام شد
  wrote against it. Both halves wired; all four write-bearing controls go
  through `target/1`.

### Your two reports, both real

* **The music tab opened the library.** موسیقی pushed screen 76 — ONE album's
  detail page, back pill saying کتابخانه. It opens the music shelf now. It is
  in English because no board draws a Persian one — that is `D-61`.
* **Dummy data over real rows.** Screen 76 showed your album with the fixture's
  *last played yesterday*, *first heard 13 Esfand 1402*, *4 albums · 610
  hours*. It carries the row's ids now and draws nothing where it cannot word
  the truth.

### The text field was wedging

Typing `matrix` one character at a time, two seconds apart, gave `mamrtriix`
and then the field **stopped accepting input entirely**, clear disc included.
`K-42` took any value it did not recognise as its own echo, and a host
re-rendering one keystroke behind sends exactly that. An unrecognised value now
wins only when nothing is in flight.

---

## The dead-tap backlog: 179 → 153

Read `design-briefs/D-62-…md` for the argument. In short:

* **33** were always on states/dark boards — pictures of controls.
* **~74** are the settled member of a live family: a lit chip is the filter
  already showing, a lit segment is the shelf you are on.
* **~47** write into `Mob.State` or against an empty store, which that sweep's
  heuristic structurally cannot see.
* **12** were struck today by building the three fences.
* **12** were **fiction** — entries naming controls that no longer exist. There
  was no stale check on `@inert_taps`; there is one now
  (`the inert list names no tag that is not drawn`, both locales).
* The rest is `D-62`.

**Unfinished when I stopped:** `/tmp/classify.exs` — a script that would prove
the split above rather than assert it, by checking that every "settled" entry
has a live sibling in the same tag family. It fails with *could not lookup Ecto
repo Kati.Repo* because `mix run` does not start the repo the way the test
harness does. Either move it into a test file or start the repo in the script.
It is worth finishing: it would turn a hand-written classification into a
machine-checked one, and the number left over would be the real backlog.

---

## Rules that cost time when forgotten

* Deploy with `mix kati.e2e.stage && ./bin/deploy_native.sh`. Never `adb
  install`, never raw Gradle. Source `~/.config/kati/tmdb.env` first or the
  build ships without a TMDB key.
* `deploy_native.sh` runs `pm clear` when `/data` is short — that wipes the app
  database and revokes permissions. Test data does not survive it.
* `~MOB` is an **uppercase sigil**: no interpolation, no escapes. It also needs
  exactly one root element — a bare `{expr}` will not compile.
* `text={nil}` prints the word **nil** on a device. `Kati.ScreenNilTextTest`
  sweeps both locales for it.
* `%__MODULE__{}` cannot be expanded inside an Ash resource's own body — Ash
  defines the struct in a `@before_compile` hook. Use `struct/2`.
* Calling into a module that reads Ash pulls the caller into
  `Kati.ScreenEmptyDatabaseTest`'s closure. That false edge has cost two rounds
  now (`Root` → `AddTitle`, `Attribution` → `Medication`). Pure helpers live in
  `Kati.UI`.
* **Green is not the bar.** Round one of `D-59` passed 2406 tests and six
  adversarial reviewers then found 30 real defects in it. The device and the
  review passes are what find things.

## Open, not forgotten

* **`D-60`** — no Persian screen in this app can say a save failed. Every one
  sets `:save_error` and draws nothing, because `Kati.Write.message/1` answers
  in English and no board writes the sentence. One band, one rule.
* **`D-61`** — the Persian music shelf.
* **`D-62`** — above.
* **Pop staleness** — a popped-to screen never re-reads;
  `deps/mob/lib/mob/screen.ex:571` restores the saved socket. Three options are
  written into `MISSING-CONNECTIONS.md` and the choice is yours. It is why the
  shelf looked stale after adding a book today.
* **Ten published commits** lack Conventional Commits prefixes. Relabelling
  needs a force-push; I have not done it.
