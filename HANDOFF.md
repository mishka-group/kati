# Handoff

Branch `dev`. Nothing pushed; no PR opened.

Read the commit messages before the code — they carry the reasoning, and this document
deliberately does not repeat it.

```
f0bb00b  the idle field finally opens the results page
2f8da11  a search box that takes what you type and finds it
36d0aba  a pushed Persian page pads itself the way its board does
c12a4e6  the first run walks Persian drawings for a Persian reader
ada2109  set the app's Persian in the app's Persian face
e5307f3  the first run as five steps, drawn and built
e76cfce  the Persian empty Home in the dark, and the omission made a decision
a40a067  the Persian empty Home, worded by a board at last
577a6d2  the hand-add form in the mirror and in the dark
1e340f8  screen 155, and the defaults it corrects on 154
651d6f5  the hand-add form takes what you type
a7860a9  screen 154 writes a real row, and refuses in words when it cannot
5d47788  the hand-add form exists, and screen 89's row finally opens it
fc93b3a  thirteen boards arrive for D-31 through D-34
28a3ec7  the search field takes what you type and the results page reads it
717c34f  the half of search that reads the store
809db97  ticking an episode writes a row instead of moving a boolean
800d3ea  resolve TMDB's host through the platform, not the pure-BEAM resolver
33caf0a  start Req where every other application is started
d7150fa  the Add title field searches TMDB instead of a Sample module
```

**Green as of handoff:** host `mix test` → **2091 passing**.

---

## Two findings worth reading before anything else

Both were invisible to the whole suite and both were found by installing the app and
looking at it. That is now the third round running in which that was the only thing that
could have found the defect.

### 1. A third of the Persian in the app was set in a face with no Persian in it

`kati_sans_400.ttf` carries **zero** code points in U+0600–U+06FF and `kati_mono.ttf`
carries none of the Persian digits. `Kati.Screens.Fa` has stated both since the mirrors
were written. Thirteen screens disobeyed it, four of them the very screens whose own
moduledoc states the rule.

**It does not look broken, and that is the point.** That moduledoc predicted "a row of
empty boxes, not a fallback". Photographed on the Pixel_9a: Compose falls through a
`FontFamily` that lacks a glyph to the platform's own chain, so Android substitutes its
system Arabic face and the sentence renders — shaped, joined, perfectly readable, in
somebody else's typeface, next to sentences that are not. A blank box is a bug anyone
would file. This you can look at for a year.

`Kati.PersianFontTest` is the guard, and it re-derives the font coverage from the shipped
`cmap` tables rather than trusting the claim above.

### 2. Four Persian screens drew with no page frame at all

`Kati.Screens.Fa.pushed_frame/2` is the root `Box` and nothing else. Every Persian screen
inside it had been writing the same `Scroll` and padded `Column` by hand; four written in
one round did not, and on a device the step rail scrolled under the status bar and the
headline ran off the leading edge. Every host test passed on all four — a layout had no
assertion in any of them. `Kati.Screens.Fa.page/1` is that frame now and
`Kati.PushedFrameTest` holds it.

---

## Setting this repo up on a new Mac costs a day if you do not read this

- **`mob.exs` is gitignored, and it holds `:static_nifs`.** Recreate it from the
  generator's defaults and you lose `kati_secure_store` and `kati_bridge`: the next build
  regenerates `priv/generated/driver_tab_android.zig` without them, the app still builds
  and launches, and every credential operation reports the store absent. Caught by
  `git diff`, not by a test.
- **zig 0.15.2 cannot run on macOS 26.** `zig build` on an EMPTY build.zig fails to link
  its own build runner. `SDKROOT` is not a way out — see `.tool-versions`, which pins
  0.16.0 and says why.
- **`JAVA_HOME` is Android Studio's JBR**, and `/usr/libexec/java_home` finds nothing on
  this machine. `~/.zshrc` sets it; a shell that overrides it fails the Gradle build with
  "Unable to locate a Java Runtime" three minutes in.
- **`../igniter_js` and `../igniter_css` are at ash-project, not mishka-group**
  (`mix.exs`'s comment says otherwise). They build their NIFs from source and their own
  `.tool-versions` pin rust 1.97.1.
- **A dev `--native` deploy and `connectedE2eAndroidTest` cannot share an install.** The
  e2e install reassigns the app UID and orphans the pushed OTP tree; all tests then fail
  in `MobBridge.extractOtpIfNeeded` with an EACCES that looks nothing like a UID conflict.
  `mix mob.uninstall` first — it reports `DELETE_FAILED_INTERNAL_ERROR` while succeeding.
- **Never `adb shell pm clear com.example.kati`.** It deletes the pushed OTP tree with the
  data, and the next launch dies in `mob_start_beam` with *cannot get bootfile*. To reset
  the app's state between hand-walks, delete the four files by name instead — the same
  four `KatiRule.wipe/0` deletes:
  `adb shell run-as com.example.kati rm -f files/mob_state.dets files/kati.db files/kati.db-wal files/kati.db-shm`
- **`adb` and `java` must be on PATH** for `mix mob.doctor` and `mix kati.e2e.stage`; both
  resolve them by name.
- **`mix kati.e2e.stage` after any Elixir change**, or `preE2eBuild`'s staleness guard
  fails the Gradle build (correctly).

---

## Standing constraints (from the owner, non-negotiable)

- **Commit titles are public.** This repo is open source and read by strangers — a title
  says what was fixed or added, never "25 screens" or similar.
- **Always the Pixel_9a emulator** for device work. Never another AVD.
- **Always the Mob mix tasks** for deploying — `bin/deploy_native.sh` / `mix mob.deploy`,
  never `adb install` or raw Gradle.
- **Everything added must be verified by e2e on the device**, driven like a real user.
- **Never claim a UI fix works without opening the screenshot.**
- **Commit each finished unit of work** rather than batching.
- **Always the latest version** of anything being pinned.
- **Be brief and organised.** Short, listed, no repetition.
- Kill and retry anything taking longer than expected rather than waiting on it.
- Don't file issues on third-party repos (e.g. `genericjam/mob`) without being told.

### The TMDB credentials

`~/.config/kati/tmdb.env`, mode 600, outside the repo, and **never committed**. The key is
entered on the device through the app's own `SecureStore`. The read token passed through a
chat window when it was supplied, so rotating it at some point is advisable.

---

## Issue state

| # | State |
|---|---|
| **#91** | All five criteria met and verified on device — see below. Closeable. |
| **#92** | All five criteria met. The device half is `SearchTest`. |
| #93 | Its actionable set was empty and its blocker was named in its own analysis: `LoudnessPrompt`'s entry is 38·3 routing forward, which needed 38 renumbered. `D-33` did that and 162/165 are the step. The rest of #93 is a design ask, not code. |
| #94 | Blocked by #93, in its own text. |
| #89 / #90 | TMDB is built, keyed and verified live on device. |
| #80 | **Left open by the owner's decision** — Apple/iCloud, deferred to the next version. |

### #91, criterion by criterion

| Criterion | State |
|---|---|
| A clean install walked end to end leaves a usable app | ✅ `FirstRunTest.a` — adds a title straight after and asserts the row |
| Every root screen shows a real empty state | ✅ `FirstRunTest.b` |
| The run resumes at the step it was killed on | ✅ `OnboardingResumeTest`, plus `FirstRunTest.c` for the reachable half |
| Choosing Persian carries through the rest of the run | ✅ `PersianFirstRunTest`, four tests. Walked by hand on the Pixel_9a as well |
| Restoring from a backup during first run is reachable | ✅ `FirstRunTest.d` — now on step two AND step three |

The fourth was the one that stayed ⚠️ for three rounds, and it is worth knowing what it
actually looked like before `D-33`: choosing فارسی and pressing Continue landed on screen
26 **in English, laid out right-to-left** — `?Kati keep`, `.same home page`, punctuation on
the wrong side of every sentence — and the step after that was screen 38 with all three of
its panels stacked and three step rails on one page.

---

## What is left, and it is smaller than it has been

**1. `HomeDark`'s header is still pinned to `Sample.moment/0`** — the one render-reachable
Sample call left. Unpinning needs two more entries in `ScreenDesignLiteralTest`'s
device-values allow-list, which is capped at 37. Raising that bound is a decision to check
less. 28 is gallery-only, so it is named rather than fixed.

**2. Screen 22 (Habits) and 23 (Subscriptions) are still on their Samples**, and both for
a real reason stated in `Kati.ScreenSampleOnlyTest`: nothing records that a habit was
**kept**, and no table holds a **price**. Those are schema questions, not screen questions.

**3. The Ash stack carries security advisories and is deliberately pinned.** `mix hex.audit`
reports 16 against `ash 3.31.3` and several against `ash_sql 0.6.9` and `ash_sqlite 0.2.17`.
`mix.exs` pins all three exactly and says why: *"Kati appears to be the first public user of
AshSqlite on a device BEAM, so a silent minor bump is not something to discover on a user's
phone."* That reason still holds, so the bump was NOT taken here — it is a round of its own,
with a device walk at the end of it.

The exposure was checked rather than assumed. The two advisories that name a specific API —
`exists/2` dropped on a limited relationship with a `parent()` filter, and JSON path
injection through unescaped `get_path` segments — are against calls this app does not make:
neither `exists(` nor `get_path` appears anywhere in `lib/`. Of the sixteen against `ash`,
all but a handful are authorization, multi-tenancy, `Ash.Reactor`, vectors, `update_many/4`
or the ETS and Mnesia data layers, and Kati has none of those: it is one person's data, on
their own device, with no policies and no actor. What is left is input validation on types
whose only input is that same person's typing.

That is an argument for taking the bump deliberately, not for taking it in a hurry.

**5. `mix hex.outdated` is otherwise clean.** `req` went 0.7.3 → 0.7.4 this round (and
`mint` 1.9.3 → 1.10.0 with it). `ex_cldr_calendars` reports 2.4.4 available and will not
resolve to it — something in the CLDR tree holds it at 2.4.3, and it is a patch release with
no advisory. `mob 0.7.24 → 0.7.39` is pinned for the reason `mix.exs` gives: the native shell
is forked at generation time and `native/LEDGER.md` is the merge cost. The vendored baseline
is 0.4.20; a bump is a three-way merge across 41 fences.

**4. The Persian mirrors adopt very little of `Kati.Components`,** and the reason is one
upstream ask: `MishkaChip`, `MishkaSegmentedControl` and `MishkaNavLink` take their label
as a prop and build the `Text` themselves, so a Persian label through them cannot carry a
face. `Kati.Screens.AddByHandFa.status_chip/2` is the third hand-rolled workaround.
`Kati.Screens.Fa`'s moduledoc names the four components that DO have a content slot.

---

## Traps this codebase has actually sprung (all cost real time)

- **A prop the bridge ignores is the most expensive kind of mistake here.**
  `fontFamilyProp`'s own comment says so, and `MobTextField` was an instance of it: it read
  no font at all, so `font_family` on a text_field was accepted by the markup and dropped
  on the floor. `K-41` is the fix. Before adding a prop, grep `MobBridge.kt` for it.
- **A guard can be defeated by an empty fixture, not only by a bad assertion.** Screen 03
  left `@known_collisions` because the sweep saw no collision, and the sweep saw none
  because the shelf is empty in every test. An empty register proves nothing.
- **A test that cannot fail.** The duplicate-`accessibility_id` check read
  `props[:accessibility_id]`, but `Mob.Renderer` *derives* that id from `on_tap` at
  serialization — so it was vacuous for the life of the project while 24 screens collided.
  Mutate the code and watch the specific assertion go red before trusting any guard.
- **One tap's side effect can decide the next tap's answer.** `Kati.AppReachabilityTest`
  evaluated a screen's tags in draw order against a shared `Mob.State`, so screen 53's
  `choose_fa` wrote the locale that `continue` then read: 164 reachable, 161 stranded, from
  the one screen that offers both. Nothing said so, because 161 was on `@no_route` for an
  unrelated reason and the two errors cancelled in the count.
- **A prefix clause above a named one makes it unreachable, and compiles.** Hit three times
  in one afternoon. Put the prefix branch inside the existing catch-all and grep for named
  clauses below it before believing the diff.
- **Overriding `handle_info/2` in a `Pushed` screen replaces all four of the macro's
  clauses**, including the one that routes `{:tap, tag}` to `handle_tap/2`. That is how
  screen 88 went unreachable. Call `super/2` in the catch-all.
- **`KatiRule.revoke/1` killed the run it was written for.** `pm revoke` on a HELD
  permission force-stops the package and instrumentation runs in that package, so it was a
  no-op while the permission was denied and fatal in exactly the case it existed for. It
  passed for weeks and died the first time a walk through the app by hand left
  READ_CALENDAR granted. Deleted; `CalendarTest` arranges its premise by asserting on the
  row it planted instead.
- **`String.to_atom` on a nil field collapses every row onto one tag.**
- **Presence-only assertions pass on a screen full of samples.** Every empty-state test must
  assert the invented strings are **absent by name**.
- **Grepping English literals against a Persian screen** returns clean and means nothing.
- **`performClick` injects a touch at the node's centre.** Mob's `<Scroll>` is a plain
  `Column(verticalScroll)`, not lazy, so a control below the fold is *findable but
  untappable*. `KatiRule.tap()` scrolls first — keep it that way.
- **Wait on a screen's `screen:` stamp, not its copy.** Waiting on text conflates "hasn't
  arrived" with "says the wrong thing", and the first reads exactly like the second.
- **An atom made of Persian words is a name no device test can type.** The Persian steps key
  their tap tags on position — see `Kati.Screens.OnboardingLoudnessFa.tag/1`.
- Inside `~MOB`, `@name` is an **assign**, not a module attribute. Tap tags must be
  **atoms**. `Ash.create/2` returns tuples, never raises. `Box` is a **z-stack**. `~MOB` is
  an uppercase sigil, so `#{}` and `\n` inside it are literal text.

## Suggested skills

- **`mattpocock-skills:diagnosing-bugs`** — for anything reported as broken on device. The
  pattern that works here: install, walk, screenshot, then instrument a single decisive
  discriminator rather than guessing between hypotheses.
- **`mattpocock-skills:code-review`** — reviews the branch against the originating issue as
  well as standards; useful before opening the PR from `dev`.
- **`design`** — if the owner wants a brief drafted rather than commissioned from Claude
  Design. #93's remaining half is a design ask.
- **`mattpocock-skills:tdd`** — the empty-state work here shows why the absence assertion
  has to be written first.

Do **not** reach for `/loop` or scheduled tasks; this work is interactive and device-bound.
