# Handoff

Branch `dev`, five commits ahead of the last handoff point. Nothing pushed; no PR opened.

Read the commit messages before the code — they carry the reasoning, and this document
deliberately does not repeat it.

```
c82807c  the Persian and dark homes stop drawing invented data too
96d4d6b  walk the first run on a device, and stop the calendar test leaking
c893072  every root screen reads the database instead of drawing samples
7be3eb9  resume a first run where it was interrupted
caf7e74  give meals, services and medication a way in     (closes #95)
```

**Green as of handoff:** host `mix test` → 2035 passing. Device
`./gradlew connectedE2eAndroidTest` on **Pixel_9a** → 13 tests, 0 failures.

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

Closed this stretch: **#95**. Filed: **#97**.

| # | State |
|---|---|
| **#91** | 4 of 5 criteria done — see below. Not closeable yet. |
| **#97** | 22 screens repeat a tap tag. Register is in `screen_tap_sweep_test.exs` `@known_collisions`, enforced in both directions; **may only shrink**. |
| #92 | Search. Blocked in practice by #89 — see "AddTitle" below. |
| #93 / #94 | Blocked on design briefs. |
| #89 / #90 | **Blocked on the owner**: needs a TMDB API key he must register. |
| #80 | **Blocked on the owner**: Apple/iCloud decision, deferred to next version. |

### #91, criterion by criterion

| Criterion | State |
|---|---|
| Every root shows a real empty state | ✅ verified on device |
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
allow-list, which is capped at 30 and holds exactly 30. Raising that bound is a decision to
check less. 28 is gallery-only, so it is named rather than fixed.

---

## Traps this codebase has actually sprung (all cost real time)

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
