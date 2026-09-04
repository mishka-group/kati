# Handoff

Branch `dev`, nine commits ahead of the last handoff point. Nothing pushed; no PR opened.

Read the commit messages before the code — they carry the reasoning, and this document
deliberately does not repeat it.

```
f9f7f48  the last three boards name their controls, closing the register
8147e99  the day sheet, the search idle page and the Persian ledger name their rows
f2c25d5  the Health hub and its reference sheet name each tile once
4440c43  the shelves, the day sheet and the knock-on sheet name each control
cb449d0  the ledger, the schedules and the two settings pills name themselves
a89736f  the Library's quick tiles count the shelf instead of the drawing
ab81e7b  the Schedule's month title is the device's, not the drawing's
670b569  the shelves and the service rows name each control once   (closes #97)
f96aac8  pin zig to the version that links on this macOS
c82807c  the Persian and dark homes stop drawing invented data too
96d4d6b  walk the first run on a device, and stop the calendar test leaking
c893072  every root screen reads the database instead of drawing samples
7be3eb9  resume a first run where it was interrupted
caf7e74  give meals, services and medication a way in     (closes #95)
```

**Green as of handoff:** host `mix test` → 2035 passing. Device
`./gradlew connectedE2eAndroidTest` on **Pixel_9a** → 13 tests, 0 failures.

## Setting this repo up on a new Mac costs a day if you do not read this

Everything below was found the slow way on a fresh machine.

- **`mob.exs` is gitignored, and it holds `:static_nifs`.** Recreate it from
  the generator's defaults and you lose `kati_secure_store` and `kati_bridge`:
  the next build regenerates `priv/generated/driver_tab_android.zig` without
  them, the app still builds and launches, and every credential operation
  reports the store absent. Caught by `git diff`, not by a test.
- **zig 0.15.2 cannot run on macOS 26.** `zig build` on an EMPTY build.zig
  fails to link its own build runner. `SDKROOT` is not a way out — see
  `.tool-versions`, which now pins 0.16.0 and says why.
- **`../igniter_js` and `../igniter_css` are at ash-project, not mishka-group**
  (`mix.exs`'s comment says otherwise). They build their NIFs from source, and
  their own `.tool-versions` pin rust 1.97.1.
- **A dev `--native` deploy and `connectedE2eAndroidTest` cannot share an
  install.** The e2e install reassigns the app UID and orphans the pushed OTP
  tree; all 13 tests then fail in `MobBridge.extractOtpIfNeeded` with an EACCES
  that looks nothing like a UID conflict. `mix mob.uninstall` first — it
  reports `DELETE_FAILED_INTERNAL_ERROR` while succeeding.
- **`adb` and `java` must be on PATH** for `mix mob.doctor` and
  `mix kati.e2e.stage`; both resolve them by name.

---

## What this stretch was actually about

The owner installed Kati on his own phone and reported one sentence:

> "you all show dummy data and it is not connected to database"

It was literally true. Every root screen answered an empty store by falling back to a
`Sample` module, so a fresh install showed invented films drawn in the shape and colour of
the user's own data. `c893072` and `c82807c` are the fix, across all three homes plus
Library, Calendar and Stats.

**The lesson worth carrying forward:** none of this was catchable from the test suite. It
was found by installing the app and looking at it. Two of the sharpest findings came from
screenshots, not assertions.

---

## Standing constraints (from the owner, non-negotiable)

- **Commit titles are public.** This repo is open source and read by strangers — a title
  says what was fixed or added, never "25 screens" or similar.
- **Always the Pixel_9a emulator** for device work. Never another AVD.
- **Everything added must be verified by e2e on the device**, driven like a real user.
- **Never claim a UI fix works without opening the screenshot.**
- **Be brief and organised.** Short, listed, no repetition.
- Kill and retry anything taking longer than expected rather than waiting on it.
- Don't file issues on third-party repos (e.g. `genericjam/mob`) without being told.

---

## Issue state

Closed this stretch: **#97**. Previously: **#95**.

| # | State |
|---|---|
| **#91** | 3 of 5 criteria done — see below. Not closeable yet. Criterion 2 regressed and was refixed: the Library drew `Up next 12` and `Lists 7` on an empty shelf. |
| #92 | Search. Blocked in practice by #89 — see "AddTitle" below. |
| #93 | Actionable set is **empty** — the analysis is a comment on the issue. Needs one design brief covering the affordances on boards 03, 04, 20, 21, 35, 36, 66 and 74, plus #91 for `LoudnessPrompt`. |
| #94 | Blocked by #93, in its own text. |
| #89 / #90 | **Blocked on the owner**: needs a TMDB API key he must register. |
| #80 | **Blocked on the owner**: Apple/iCloud decision, deferred to next version. |

### #91, criterion by criterion

| Criterion | State |
|---|---|
| Every root shows a real empty state | ✅ verified on device — *after* `a89736f`. It was recorded ✅ once before while the Library still drew `Up next 12` and `Lists 7`; `Kati.DesignLiterals` drops numeric-only lines, so no test compared them. |
| Resumes at the step it was killed on | ✅ `7be3eb9` |
| Restore reachable during first run | ✅ `:import_backup`, seen on device |
| Persian carries through | ⚠️ lands on `HomeFa` correctly and it no longer fabricates, but steps 2–3 are walked on the **English** drawings |
| Clean install hands over a usable app | ⚠️ partly — see next section |

---

## Open problems, with the honest shape of each

**1. The catalogue you search is fabricated.** `Kati.Screens.AddTitle` searches sample data —
`TypingTest` passes by typing *"the long hollow"*, an invented film. Adding one writes a real
`tracked_titles` row, so the journey works; what you can *find* does not. The real catalogue
needs the TMDB key (#89). **Do not paper over this** by seeding a fake catalogue.

**2. "Can't find it? Add it by hand" is a dead control.** Drawn on artboard 89 and rendered by
`add_title.ex` as a `<Row>` with **no `on_tap`**, and **no artboard anywhere draws the form it
would open**. This is the escape hatch that would make a fresh install usable without TMDB.
Needs a design brief before it can be built.

**3. No Persian mirror of board 139.** All 46 Persian artboards were grepped — none words an
empty day. `c82807c` writes exactly one Persian sentence rather than translating a board,
following `Kati.Screens.SettingsFa.backup_line/1`'s precedent. **Ask Claude Design for:** a
Persian screen 55 with nothing stored, plus wording for an empty day, an empty
تازه‌های این هفته and an empty ادامه تماشا. The last two are answered by omission today
because no board words them in either language.

**4. No Persian artboards for onboarding steps 2 and 3.** `Kati.Onboarding.screen_for_step/1`
is deliberately **not** locale-aware and its comment explains why — artboard 137 is screen 26
in Persian, not 38, and routing the finish step there would strand a Persian run.

**5. `HomeDark`'s header is still pinned to `Sample.moment/0`** — the one render-reachable
Sample call left. Unpinning needs two more entries in `ScreenDesignLiteralTest`'s device-values
allow-list, which is capped at **31** and holds exactly 31. Raising that bound is a decision to
check less. 28 is gallery-only, so it is named rather than fixed.

The cap moved from 30 to 31 in `ab81e7b`, for screen 02's month title rather than for 28: the
board froze `August 2026` and the screen draws the device's month, so the suite went red on
1 September and stayed red. That entry pins this month and this year, which is stricter than
the frozen literal it replaced — a test that rots on a date nobody set is the one kind of
allow-list growth that checks *more*.

---

## Traps this codebase has actually sprung (all cost real time)

- **A guard can be defeated by an empty fixture, not only by a bad assertion.** Screen 03 left
  `@known_collisions` because the sweep saw no collision, and the sweep saw none because the
  shelf is empty in every test — no rows, no tiles, nothing to collide. `Kati.Screens.Library`
  then carried one tag per *kind* on a real phone's shelf for months. An empty register proves
  nothing unless the screen was drawn with two of a kind on it.
- **A prefix clause above a named one makes it unreachable, and compiles.** Hit three times in
  one afternoon — in 03 above `:open_film` and `:add_title`, in 57 above the search disc and
  every chip, in 86 above `:try_suggestion` and every scope. Each would have shipped a screen
  whose other controls silently stopped working. Put the prefix branch inside the existing
  catch-all, and grep for named clauses below it before believing the diff.
- **`String.to_atom` on a nil field collapses every row onto one tag.** Keying the discography
  rail on `seed` looked obvious; every row of `Kati.Music.Sample.artist_albums/0` carries
  `seed: nil`, so all four fell back to `:open_album` and the collision survived the fix.
- **A test that cannot fail.** The duplicate-`accessibility_id` check read `props[:accessibility_id]`,
  but `Mob.Renderer` *derives* that id from `on_tap` at serialization — so it was vacuous for the
  life of the project while 24 screens collided. Before trusting any guard, mutate the code and
  watch the specific assertion go red.
- **Presence-only assertions pass on a screen full of samples.** Every empty-state test must
  assert the invented strings are **absent by name**, and that the Sample module still holds them
  (so an emptied fixture can't fake a pass).
- **Grepping English literals against a Persian screen** returns clean and means nothing. Read the
  literals off the Sample module programmatically.
- **`performClick` injects a touch at the node's centre.** Mob's `<Scroll>` is a plain
  `Column(verticalScroll)`, not lazy, so a control below the fold is *findable but untappable*.
  `KatiRule.tap()` scrolls first — keep it that way.
- **Wait on a screen's `screen:` stamp, not its copy.** Waiting on text conflates "hasn't arrived"
  with "says the wrong thing", and the first reads exactly like the second.
- **`pm revoke` on a granted permission force-stops the package**, taking the instrumentation with it.
- **`mix kati.e2e.stage` after any Elixir change**, or the staleness guard fails the build (correctly).
- Inside `~MOB`, `@name` is an **assign**, not a module attribute. Tap tags must be **atoms**.
  `Ash.create/2` returns tuples, never raises. `Box` is a **z-stack**.
- Elixir clause ordering: a prefix-matching catch-all placed before named clauses silently makes
  them unreachable. Made this mistake twice in `meals_today.ex` and `meal_edit.ex`.

---

## If you pick up #91 to finish it

The remaining work is **not** code — it is two design asks (items 2 and 3 above) and one API key
(#89). Everything mechanically completable has been done and verified. Resist closing #91 by
weakening its acceptance criteria; say what is blocked and on whom.

## Suggested skills

- **`mattpocock-skills:diagnosing-bugs`** — for anything reported as broken on device. The pattern
  that worked here: install the app, walk it, screenshot, then instrument a single decisive
  discriminator rather than guessing between hypotheses.
- **`mattpocock-skills:research`** — before touching #89/#90 (TMDB), to pin the API surface against
  primary docs rather than memory.
- **`mattpocock-skills:code-review`** — reviews the branch against the originating issue as well as
  standards; useful before opening the PR from `dev`.
- **`design`** — for the Persian 139 mirror and the by-hand add form, if the owner wants them drafted
  rather than commissioned from Claude Design.
- **`mattpocock-skills:tdd`** — for the by-hand add form once a board exists; the empty-state work
  here shows why the absence assertion has to be written first.

Do **not** reach for `/loop` or scheduled tasks; this work is interactive and device-bound.
