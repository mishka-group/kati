# Make it real

## 1. What you found, and what was actually true

You installed the APK and reported five things: the screens show dummy data, nothing is
connected to the database, nothing is connected to any API, search does not work, and every
screen is reachable only through Settings.

Three of those are exactly right. One is right in a narrower and worse way than it sounds.
One is wrong as stated and right in substance. `docs/STATE-OF-THE-APP.md` is the evidence,
line by line, and it also found two defects the report did not reach.

- **Dummy data.** 120 of the 152 screens call a `*Sample*` module directly; there are 75 such
  modules under `lib/`. The other 88 issue real Ash queries and every one of them keeps a
  Sample as its empty-store fallback — and the store is empty on every device, so the fallback
  is what draws (`docs/STATE-OF-THE-APP.md:19-29`). This is pinned by a test whose whole
  purpose is to assert that a migrated screen still draws its drawing when it finds nothing
  (`test/kati/screen_empty_database_test.exs:5-25`).
- **The database.** It is genuinely there — 12 domains, 37 resources, 37 migrations, and
  `Ecto.Migrator.run/4` at boot (`lib/kati/app.ex:99`). What is missing is anything to connect
  *to*: nothing in `lib/` ever writes a `CachedTitle`, a `TrackedTitle` or a `Watch`, so the
  whole film-and-TV spine queries tables that cannot hold a row, and 17 of the 37 resources
  have no production write path at all (`docs/STATE-OF-THE-APP.md:31-37,378-382`).
- **APIs.** One real HTTP client exists, the CalDAV adapter at
  `lib/kati/sync/adapter/caldav/transport.ex:71-72`, and nothing in `lib/` calls it. TMDB,
  Open Library, MusicBrainz, ListenBrainz, TVmaze, Hardcover and TheTVDB have no client module
  at all; they are entries in a display list at `lib/kati/sources.ex:47-91`. Runtime network
  egress on device today is zero (`docs/STATE-OF-THE-APP.md:39-45,485`).
- **Search.** Worse than not working: it cannot receive input. Screen 19's field is a `<Text>`
  node with a 2×19 orange `<Box>` drawn to look like a caret
  (`lib/kati/screens/search.ex:236-244`), and the query is the literal string `"hollow"`
  (`lib/kati/screens/search/sample.ex:25`). But `<TextField>` exists in the pinned Mob, Kati
  already renders one for the backup passphrase (`lib/kati/screens/backup.ex:984-991`), and the
  bridge maps it (`android/app/src/main/java/com/example/kati/MobBridge.kt:3038`). Search was
  never actually blocked (`docs/STATE-OF-THE-APP.md:537-544`).
- **Settings.** Literally wrong — 67 screens hang off Home, Calendar, Library and Stats. In
  substance right: 47 screens have no in-app route at all and are reachable only through a
  developer gallery on a Settings row labelled "Every screen"
  (`lib/kati/screens/settings.ex:664`), and the gallery's own moduledoc calls itself
  *"scaffolding, and `@doc false` so it never reads as part of the app"*
  (`lib/kati/screens/gallery.ex:19-20`). The impression it gives — that the gallery is the app —
  is a fair reading of what is on the device (`docs/STATE-OF-THE-APP.md:54-63`).

The two you did not reach are worse than any of the above. The screens that *can* write persist
hardcoded sample values into arbitrarily chosen rows — every tap of *Add* on screen 124 inserts a
row named `"The Salt Almanac"` with a null amount (`lib/kati/screens/quick_add_expense.ex:225`,
`lib/kati/screens/quick_add/sample.ex:113-120`) — and all twelve write sites swallow their own
failures, so a constraint violation, a missing table and a successful save are indistinguishable
(`docs/STATE-OF-THE-APP.md:340-360`). And ticking an episode, the single gesture the app is named
for, changes a socket assign and nothing else (`lib/kati/screens/series.ex:1061`).

This document is the work that closes all of it.

---

## 2. The rule

**Nothing is done until an e2e test on a real Android device proves it.**

`mix test` today is *1794 passed*, all green. Every finding above survived all of them, and that
is not a failure of diligence — the suite is unusually careful. It is a failure of *layer*. Those
tests assert that a screen draws its artboard, which is a different claim from the app working:
they run on the host, against a fresh empty database, with taps delivered straight into a
GenServer. Mob says so itself, in the moduledoc of the case template the whole suite is built on —
*"Neither runs the native layer, so they cannot catch a node that renders wrong or behaves wrong
on a real iOS/Android build. That needs a device test driven through `Mob.Test`"*
(`deps/mob/lib/mob/screen_case.ex:42-44`). Worse, the two tests most likely to be mistaken for
proof assert the opposite of what is needed: `test/kati/screen_empty_database_test.exs:5-25`
asserts that every screen still draws when the store is empty, and
`test/kati/screen_rating_log_test.exs:27-29` states outright *"What is deliberately NOT asserted
here: a write."* A suite that is green on an app with no data, no writes and no doors is not
lying; it is answering a different question.

So every deliverable below carries its acceptance as an assertion made on a phone. There are
**76** of them. Two rules govern all of them:

1. **Every state-changing test carries a receipt that is not the screen.** A screen that redraws
   its Sample is visually indistinguishable from a screen that redrew a row, so the screen alone
   cannot be the assertion. The receipt is `files/kati.db`, `files/mob_state.dets`, or
   `CalendarContract`. This is also the only check that sees through the twelve swallowed writes.
2. **Setup is a journey, not a fixture.** If a state cannot be produced by tapping, that is a
   finding about the app, not a reason to write a fixture.

---

## 3. One harness, and why the other two were dropped

The five source sections proposed three different harnesses, and they cannot all be built.

* An instrumented Compose/UI Automator suite under `android/app/src/androidTest/`, driven by
  `createAndroidComposeRule<MainActivity>()`.
* An ExUnit suite under `test/device/` driving `adb shell input tap` at coordinates read from
  `uiautomator dump`, asserting over Erlang distribution.
* A `Mob.Test`-over-distribution suite requiring sixteen automation statics that
  `deps/mob/android/jni/mob_nif.zig:3866-3881` caches optionally and that `MobBridge.kt` does not
  implement.

**The instrumented suite is the gate.** Three reasons, each from the material:

* It is the only one whose subject's Elixir version is a property of the build. `mix mob.deploy`
  pushes BEAMs over adb, `--native` pushes the whole OTP tree, and the two overwrite each other in
  either order — `bin/deploy_native.sh:64-73` re-pushes the BEAMs after the `--native` pass
  precisely because that pass can overwrite the modules it just built, and `AGENTS.md:57-59,66-69,75-79`
  records the rounds this has cost on device. A suite whose subject can be silently one deploy old
  is not a gate.
* `Mob.Test.tap/2` is `:rpc.call(node, Process, :send, [:mob_screen, {:tap, tag}, []])`
  (`deps/mob/lib/mob/test.ex:214-217`) — it delivers `{:tap, tag}` straight to the screen process,
  which is the same dispatch `test/kati/app_reachability_test.exs:236` and
  `test/kati/screen_tap_sweep_test.exs` already perform on the host. A device suite built on it
  re-proves the host suite over a slower wire. It also cannot see which of the bridge's three tap
  paths a node actually got: the generic `Modifier.clickable` (`MobBridge.kt:2923-2925`),
  `MobButton`'s own `onClick` (`:3470`), or `anchored`'s dismiss-report (`:2915-2921`).
  `performClick()` goes out through `nativeSendTap` (`:911`) whichever one is installed.
* Coordinates are a liability. `Mob.Test.tap_id/2` taps the centre of a frame from
  `element_frames/1` (`deps/mob/lib/mob/test.ex:1119,1155-1161`), which resolves to `not_loaded`
  against this bridge (`deps/mob/android/jni/mob_nif.zig:697,3874`) — and porting it would add a
  coordinate registry to keep wrong. `onNodeWithTag(...).performScrollTo().performClick()` needs
  no registry and works on rows scrolled off screen.

**What survives from the other two designs.** All three asked for the same one-line bridge fix,
and it is Phase 0's first deliverable. `Mob.Renderer` already emits
`{"accessibility_id", Atom.to_string(tag)}` beside every `on_tap` carrying an atom tag
(`deps/mob/lib/mob/renderer.ex:312-313`), under a comment saying it exists *"so test tooling can
locate elements by tag name without relying on screen coordinates"* (`:305-306`), and Kati
already enforces on the host that every control it draws produces one
(`test/kati/screen_tap_sweep_test.exs:619,729-742`). `MobBridge.kt` drops it — a grep of
`android/app/src/` for `accessibility_id` returns nothing. The two proposed spellings are not
alternatives: `Modifier.testTag` is what Compose finders read, `contentDescription` is what
TalkBack reads, and `testTagsAsResourceId` on the root is what puts the same string into
`uiautomator dump` as a `resource-id` so the OS permission dialog — another process's window,
invisible to Compose finders — can be driven. Apply all three.

`adb` remains the way to plant state the OS owns: `content insert` into `CalendarContract`,
`cmd uimode night yes`, `settings put system font_scale 2.35`, `pm revoke`. `Mob.Test` over
distribution stays a *debugging* aid — the e2e build is `MIX_ENV=dev`, so `Mob.Dist` is alive
(`lib/kati/app.ex:19,175-180`) and a human can attach with `mix mob.connect` and read
`Mob.Test.assigns/1` on a red run — and never an acceptance mechanism. The sixteen automation
statics are not ported. `test/device/` is not created.

**One correction to the `clearPackageData` argument, because it matters and it is cheap.** The
ban is right, but one of its two stated reasons changes on the e2e build. Because that build
carries `otp.zip` as an asset and `extractOtpIfNeeded()` re-extracts whenever the
`.installed_version` marker is missing (`MobBridge.kt:354-390`, marker at `:359-363,388`),
`pm clear` no longer bricks it; it costs a re-extract. The ban stands on the other reason: a
restart-durability pair needs the database to survive between test methods, and
`clearPackageData` deletes it. On a `bin/deploy_native.sh`-deployed debug device the original
hazard is real and unchanged — `pm clear` deletes `files/otp` and the BEAM then *"starts and dies
before the first Elixir step with no error in logcat"* (`AGENTS.md:66-69`). Which is why the e2e
loop is `assembleE2e`, never `bin/deploy_native.sh`.

Every acceptance row below runs against `./gradlew connectedE2eAndroidTest`. The instrumented
process runs with the app's own uid, so it reads `files/kati.db` and `files/mob_state.dets`
directly — no `run-as`, no root, no pull-off-device. WAL is on by default
(`deps/ecto_sqlite3/lib/ecto/adapters/sqlite3/connection.ex:23`, never overridden in
`lib/kati/repo.ex:20-40`), which is why a second reader sees committed rows while the BEAM holds
the file, and why any route that copies the database off the device must copy `kati.db`,
`kati.db-wal` and `kati.db-shm` together.

---

## 4. The work

Twelve phases. Phase 0 is the harness, because nothing else can be accepted without it. After
that the order is by dependency and by what it puts on your screen: the device calendar import is
one `Mob.Permissions.request/2` call away from showing you your own data, so it is Phase 1.

Each phase carries **Delivers**, **Touches**, and an acceptance table. Every acceptance row is an
assertion on a device, numbered so they can be counted and ticked off.

| Phase | | Criteria |
|---|---|---:|
| **0** | The harness — every control addressable, every write readable, every restart real | 9 |
| **1** | The calendar, switched on — your own events on Home, six Samples deleted | 6 |
| **2** | Every field is a field — the nine "Mob has no text input" claims deleted | 5 |
| **3** | Every screen knows which row it is looking at — pushes carry an id | 3 |
| **4** | A failed write says so — the twelve swallowed failures | 4 |
| **5** | The preferences the app already collects and throws away — `Kati.Sections` and the switches | 4 |
| **6** | The film-and-TV spine — add a title, tick an episode, and have it still be there | 11 |
| **7** | One provider, one call — seasons and episodes, so there is something to tick | 2 |
| **8** | The first run hands over a usable app — five steps, and every answer kept | 10 |
| **9** | Search — a real field over a real index | 6 |
| **10** | Every screen in its own place — 47 stranded → 0, and no gallery on a user's phone | 9 |
| **11** | The remaining origination paths, the corpus, and the guards | 7 |
| | **Total** | **76** |

---

### Phase 0 — The harness

**Delivers.** An instrumented test suite that can launch the real app on a real device, address
any control the app draws by the tag it already carries, type into a field, read the database
back, drive an OS permission dialog, and prove that a write survived the death of the BEAM.

**Touches.**

* **H1 — `accessibility_id` → `testTag`.** In `nodeModifier/1` (`MobBridge.kt:4426`), read
  `props["accessibility_id"]` and apply `Modifier.testTag(value)` plus
  `Modifier.semantics { contentDescription = value }`. Applied there rather than per-composable, it
  reaches every node type through `MobBridge.kt:2927`. On the root `RenderNode` call
  (`MainActivity.kt:304-313`) add `Modifier.semantics { testTagsAsResourceId = true }`. Fenced
  `KATI-BEGIN`/`KATI-END` with a `native/LEDGER.md` row, per `AGENTS.md:120-122`. This is the
  cheapest change in the document and the largest unlock: the Elixir half is finished and enforced
  across all 152 screens today.
* **H2 — screen identity, and tag uniqueness.** Nothing on the device says which of the 152
  screens is on top: `MobBridge.RootState` carries `(navKey, transition, node)`
  (`MobBridge.kt:277`), a counter and a string. Asserting by visible text is not a substitute — Kati
  draws the same strings in an English screen and its Persian mirror, in a live screen and its
  `— states` sheet. `Mob.Renderer`'s prop catch-all serialises any key it does not special-case
  (`deps/mob/lib/mob/renderer.ex:469-470`), so an `accessibility_id="screen:home"` written onto a
  node arrives under exactly the key H1 reads. The edit is two attributes: the `<Box>` in
  `Kati.Shell.render/1` (`lib/kati/shell.ex:99`) for the four root screens and the `<Box>` in
  `Kati.Screens.Pushed.chrome/2` (`lib/kati/screens/pushed.ex:104`) for every pushed screen, with
  the name threaded down from the two macros (`lib/kati/screens/root.ex:196-203`,
  `lib/kati/screens/pushed.ex:61-63`) and a helper for the hand-rolled `use Mob.Screen` screens
  (enumerated at `test/kati/screen_tap_sweep_test.exs:50-53`). Plus two host assertions in
  `test/kati/screen_tap_sweep_test.exs`: every screen stamps one, and no two nodes in a render
  share an `accessibility_id`. The second goes red the day it lands, on
  `lib/kati/screens/library.ex:673` — every poster in the grid is tagged with one of two constants,
  `:open_film` or `:open_series`, and the handler carries no identity either
  (`lib/kati/screens/library.ex:821-825`). That is a finding about the app, and the harness is what
  turns it into one instead of a green sweep.
* **H3 — Gradle.** `android/app/src/` has one source set and no `androidTest` anywhere;
  `android/app/build.gradle` declares no `testInstrumentationRunner` (`:47-76`), no `testOptions`,
  and no `androidTestImplementation` line of any kind (`:122-188`). Add:
  `testInstrumentationRunner "androidx.test.runner.AndroidJUnitRunner"`;
  `buildTypes { e2e { initWith debug; signingConfig signingConfigs.debug } }` at `:106`;
  **`testBuildType "e2e"`** in the `android` block — AGP creates the `androidTest` variant for
  exactly one build type and it defaults to `debug`, so without this line there is no
  `connectedE2eAndroidTest` task and the harness silently runs against the APK that gets its BEAMs
  from `mix mob.deploy`;
  `testOptions { execution 'ANDROIDX_TEST_ORCHESTRATOR'; animationsDisabled = true }` with **no**
  `clearPackageData` argument and a comment saying why (§3);
  `androidTestImplementation` on the existing `composeBom` platform (`:128`) plus
  `androidx.compose.ui:ui-test-junit4`, `androidx.test.ext:junit`, `androidx.test:runner`,
  `androidx.test:rules`, `androidx.test.uiautomator:uiautomator`;
  `e2eImplementation 'androidx.compose.ui:ui-test-manifest'`; `androidTestUtil 'androidx.test:orchestrator'`.
  Versions for the `androidx.test` artifacts are not pinned here — they are not in this repo today
  and must resolve against AGP 9.3.1 (`android/build.gradle:15`); resolve them at wire-up and record
  the reason in the gradle file's existing comment style (`android/app/build.gradle:164-187` is the
  model). The toolchain will carry them: Kotlin 2.4.10 (`android/build.gradle:26-27`), JVM 17
  (`android/app/build.gradle:100-103`), `compose-bom:2026.06.00` (`:128`), which is recent enough
  that `ui-test-junit4` takes no version of its own.
* **H4 — `android/app/src/e2e/assets/otp.zip` + `mix kati.e2e.stage`.** Built with
  `MobDev.OtpAssetBundle.build/3` (`deps/mob_dev/lib/mob_dev/otp_asset_bundle.ex:69`), the same
  function the release pipeline uses (`deps/mob_dev/lib/mob_dev/release_android.ex:30,34`), staged
  from the current `MIX_ENV=dev` compile and wired as a Gradle `preE2eBuild` dependency. It fails
  the build — not warns — when anything under `_build/dev/lib/kati/ebin/` is newer than the zip.
  Keeping the zip out of `src/main/assets/` also keeps `bin/deploy_native.sh:50-54`, which deletes
  a stray `otp.zip` on sight, working for the ordinary dev loop.
* **H5 — `android/app/src/e2e/AndroidManifest.xml`** declaring `WRITE_CALENDAR` and nothing else,
  so calendar journeys can plant a real event without widening the shipping manifest
  (`android/app/src/main/AndroidManifest.xml:45-50` declares only `READ_CALENDAR`, and the K-01
  trim comment at `:11-31` explains why the list is short). Note that
  `bin/deploy_native.sh:35-36` already tries to `pm grant` `WRITE_CALENDAR`; on the current
  manifest that grant silently does nothing, which is its own evidence that this has been assumed
  to work.
* **H6 — `KatiRule`**, in `android/app/src/androidTest/java/com/example/kati/`. The only class
  feature authors touch. A `RuleChain`: wipe → `GrantPermissionRule` → `createEmptyComposeRule()` →
  launch `MainActivity`. The wipe deletes `kati.db`, `kati.db-wal`, `kati.db-shm` and
  `mob_state.dets` **by name**, never the directory, because `files/otp/` lives beside them.
  Surface: `awaitScreen(name)` — a `waitUntil` on `screen:<name>`, the single sync point, because
  Compose's `waitForIdle()` synchronises on recomposition and the first render arrives
  asynchronously from the BEAM over JNI (`MobBridge.kt:906`, against a *"2136ms median launch"*,
  `lib/kati/app.ex:116-118`); `firstRun(locale)`, which drives the real first-run chain rather than
  setting a flag; `tap(tag)`, `type(tag, text)`, `assertText`, `assertAbsent`, `assertNoText(text)`
  for the no-dummy-data rows, which assert on strings from the `*Sample*` modules and those carry no
  tags; `db()`, opening `files/kati.db` and running `count(table)` / `scalar(sql)` — table names are
  the migration's, `media_watches`, `tracked_titles`, `cached_titles`, `health_readings`;
  `beams()`, listing the extracted runtime under `files/otp/` for module-absence assertions;
  `systemDialog(label)`, a UI Automator click on another process's window; and a failure watcher
  that dumps `logcat -d` filtered to `BEAMout` — where `Kati.App`'s per-phase boot trace lands
  (`lib/kati/app.ex:217-253`) — plus a screenshot, into the run's artifact directory.
* **H7 — a run configuration.** The gutter arrow in Android Studio with the `e2e` variant selected,
  and `./gradlew connectedE2eAndroidTest` headless. Both documented in `AGENTS.md` beside the
  deploy rules, because the one thing an author must know is that the e2e loop is `assembleE2e`.
* **H8 — the indeterminate `<Progress>` ban.** `MobProgress` renders an infinite
  `LinearProgressIndicator` whenever the `value` prop is absent (`MobBridge.kt:3612-3629`), which
  makes `waitForIdle()` block forever. Nothing reaches that branch today — every Kati call site
  passes `render: :box` (`lib/kati/screens/books.ex:382,576`, `lib/kati/screens/goals.ex:350`,
  `lib/kati/screens/year_cards.ex:284`) — but `Kati.Components.MishkaLoadingOverlay` already
  contains a bare `<Progress color={color} />` with no caller
  (`lib/kati/components/mishka_loading_overlay.ex:125`). Ban it in
  `test/kati/component_policy_test.exs`. Kati has no drawn indeterminate bar, so the ban is also
  correct design.
* **H9 — delete `Kati.Spike` and fix the boot assertion.** `Kati.Runtime.assert!(~w(schema_migrations spike_things))`
  (`lib/kati/app.ex:105`) asserts two tables, one of them a throwaway whose own moduledoc asks to be
  deleted (`lib/kati/spike.ex:5-6`) and which ships a table to every device. A phone that ran two of
  eighteen migrations passes that check; all 36 real domain tables are unasserted. Delete the domain,
  the resource and its four migrations
  (`priv/repo/migrations/20260818141939_create_spike_things.exs`, `…143349_add_note_to_spike_things.exs`,
  `…143740_add_source_to_spike_things.exs`, `…143947_add_upgrade_probe.exs`), and make the assertion
  name the tables the app actually reads. This belongs to Phase 0 because the harness's fourth claim
  is that the schema on the phone is the schema in the repo, and the assertion written to prove that
  is the one naming the spike.

**Acceptance.**

| № | Assertion on a device |
|---|---|
| **P0.1** | Launch; `onNodeWithTag("root_library", useUnmergedTree = true).assertExists().performClick()` — `root_library` is the tag `Kati.Shell.tab/3` already draws (`lib/kati/shell.ex:197`) — then `awaitScreen("library")` succeeds. The same run asserts `uiautomator dump` contains a node whose `resource-id` is `root_library`. |
| **P0.2** | (a) For each of the four shell roots and one pushed screen per root, `onAllNodesWithTag("screen:<name>")` returns exactly one node. (b) With three tracked titles in the store, `onAllNodesWithTag("open_series")` returns at most one — the on-device form of the uniqueness rule, and the assertion that fails today against `lib/kati/screens/library.ex:673`. |
| **P0.3** | `./gradlew connectedE2eAndroidTest` runs a two-method `@FixMethodOrder(NAME_ASCENDING)` class on a connected device, and method `b` observes a row method `a` wrote — proving the BEAM died and restarted between them under Orchestrator's process isolation. |
| **P0.4** | After touching one `lib/` module, `assembleE2e` + install, and an e2e asserts the new behaviour with **no** `mix mob.deploy` having run. Separately, a test reads `files/otp/.installed_version` and asserts it equals this install's `PackageInfo.lastUpdateTime` — the runtime came out of *this* APK. |
| **P0.5** | The test inserts an event with a unique generated title into `CalendarContract`, relaunches, and `db().count("events")` goes from 0 to 1 while `onNodeWithText(title)` finds it on screen 02 — proving `KatiCalendarReader.publish/1` (`KatiCalendarReader.kt:51-52`) → `DeviceImport.run/0` (`lib/kati/app.ex:133`) ingested real OS data rather than a fixture. |
| **P0.6** | A deliberately failing assertion produces a run artifact containing a screenshot **and** the `BEAMout` boot-trace lines from `lib/kati/app.ex:242-253`. A red e2e that arrives without the boot trace is unactionable, which is the failure mode `lib/kati/app.ex:101-105` was written to prevent and does not. |
| **P0.7** | The same `@Test` class passes from Android Studio's gutter arrow and from `./gradlew connectedE2eAndroidTest`, both after `./gradlew clean`. |
| **P0.8** | A journey that visits every screen reached by the journeys in this document completes under a named 30 s `awaitScreen` budget, each `screen:<name>` observed in turn. A `waitForIdle` that never returns is reported as a failure with the boot trace attached, never as a timeout to be raised. |
| **P0.9** | Fresh install: `db().scalar("select name from sqlite_master where name = 'spike_things'")` returns nothing, the app boots to Home, and logcat carries no `Kati.Runtime` failure. |

---

### Phase 1 — The calendar, switched on

This is the highest ratio of user-visible truth to lines edited in the document. Every part of the
pipe is built: the manifest declares the permission
(`android/app/src/main/AndroidManifest.xml:49`); `MobBridge.kt` maps the `"calendar"` capability to
`READ_CALENDAR` in both the status map (`:833`) and the request map (`:998-1000`, under a
`KATI-BEGIN(K-26 calendar-permission)` fence whose own comment records that the stock map lacked
it); `KatiCalendarReader.publish/1` queries `CalendarContract.Instances` — so the OS expands
recurrence — and writes `device_calendars.json` and `device_instances.json` into `filesDir`
(`android/app/src/main/java/com/example/kati/KatiCalendarReader.kt:50-71`);
`Kati.Calendars.DeviceImport.run/0` reads both and upserts real `calendars`
(`lib/kati/calendars/device_import.ex:100-110`) and real `events`
(`:116-144,183-196`); `Kati.App.on_start/0` calls it at boot (`lib/kati/app.ex:133`); and Home and
screen 02 read the result through `Kati.Calendars.Today.rows/1`
(`lib/kati/calendars/today.ex:44-61`).

**What is missing is three things, not one**, and the audit's "one call" framing would ship a
granted permission and an empty calendar:

* *Nobody asks.* `Mob.Permissions.request/2` is called in exactly two places in `lib/`, both for
  `:notifications` (`lib/kati/screens/notifications_help.ex:347`,
  `lib/kati/screens/loudness_prompt.ex:410`).
* *`publish/1` runs at `onCreate`, not on every foreground* (`MainActivity.kt:182`), so a
  permission granted mid-session does not re-publish; the JSON on disk is still the two empty
  arrays `publish/1` writes when the permission is absent (`KatiCalendarReader.kt:53-58`).
* *`DeviceImport.run/0` runs at boot only* (`lib/kati/app.ex:133`), so even after a re-publish the
  rows do not reach `kati.db` until the next cold launch.

**Delivers.** Your own calendar on Home and on screen 02, on the run in which you granted it. Six
`*Sample*` modules deleted.

**Touches.**

* **The ask goes on screen 26's Continue** (`lib/kati/screens/pick_sections.ex:131-132`). Three
  reasons from the material: 26 is the first screen that has told the user what the calendar is
  *for* — *"every section drops into the same calendar and the same home page"*
  (`lib/kati/screens/pick_sections/sample.ex:49-50`) — which is the pre-prompt sentence Android's
  dialog does not supply; 26 already exists and already commits; and the calendar is the substrate
  under every section rather than a section of its own, so it cannot hang off a tile.
* **The handler is two beats, not a push.** `Mob.Permissions.request/2` is asynchronous and the
  answer arrives as `{:permission, capability, :granted | :denied}`
  (`deps/mob/lib/mob/permissions.ex:39-47`). So `{:tap, :continue}` stores the sections, calls
  `Mob.Permissions.request(socket, :calendar)` and `Kati.Permissions.note_asked(:calendar)`
  (`lib/kati/permissions.ex:85-88`) in the idiom `Kati.Screens.NotificationsHelp.ask/1` already uses
  (`lib/kati/screens/notifications_help.ex:344-350`), and pushes nothing;
  `{:permission, :calendar, _state}` runs `Kati.Calendars.DeviceImport.run/0` and then pushes.
  **Both `:granted` and `:denied` push** — a refused calendar changes what Home says on day one and
  never stops the run. No pre-check for the already-granted case, and none should be written: Mob
  documents `request/2` as *"safe to call if the permission is already granted — the result still
  arrives via `handle_info`"* (`deps/mob/lib/mob/permissions.ex:47-48`) and the bridge delivers
  `granted` synchronously without a dialog when `checkSelfPermission` passes
  (`MobBridge.kt:1007-1008`).
* **One fenced Kotlin edit makes the mid-session grant work.** `MobBridge.onPermissionResult/1` is
  three lines (`MobBridge.kt:1014-1017`). Inside a fence in the manner of the one just above it
  (`:997-1001`): when `granted` and `pendingPermissionCap == "calendar"`, call
  `KatiCalendarReader.publish(activityRef?.get() ?: return)` **before** `nativeDeliverAtom3(…)`.
  All three names are already in scope in that object — `activityRef` (`:329`),
  `pendingPermissionPid` (`:976`), `pendingPermissionCap` (`:977`) — and `publish/1` takes a
  `Context`, which an `Activity` is (`KatiCalendarReader.kt:52`). `publish/1` is synchronous file
  I/O and never throws (`:47-71`), so by the time the atom lands in Elixir the JSON is real. The
  alternative — a new `@JvmStatic katiCalendarPublish()` beside `katiPermissionStatus`
  (`MobBridge.kt:774`), a C entry in `c_src/kati_bridge.c` and a stub in
  `lib/kati/nifs/kati_bridge.ex` — needs a NIF and I have not verified the C marshalling shape;
  the fenced edit covers both the already-granted path (published at `onCreate`) and the
  just-granted path, so take it.
* **Screen 40's Allow pill becomes real.** It is drawn (`lib/kati/account/sample.ex:88-91`, control
  chosen at `lib/kati/screens/account.ex:293-294`) and its handler only rewrites assigns — the
  `"perm_" <> i` arm calls `flip/2` and assigns the result back
  (`lib/kati/screens/account.ex:661-664`). It gets the same `request/2` + `note_asked/1` pair, so a
  phone that has finished onboarding has a second door. This is also where the general rule lands:
  **a control's resting state is read from where its tap writes** — `lib/kati/account/sample.ex:69-73`
  already states it for permissions, *"the trailing control is decided from that answer at render
  time rather than stored here — a permission changes in system settings while Kati is
  backgrounded"*.
* **Screen 32's visibility switch, and the filter it implies.**
  `Kati.Screens.Calendars` draws a per-calendar switch inside `calendar_row/2`
  (`lib/kati/screens/calendars.ex:317-321`, again at `:362`) reading the `on` key `shaped/1` builds
  at `:158`, and **the file contains no `on_tap` and no tap handler at all**. The column exists —
  `Kati.Calendars.Calendar.visible` (`lib/kati/calendars/calendar.ex:41`) with `update: :*` at
  `:67`. The switch writes it, **and** `Kati.Calendars.Today.rows/1` must filter on it, which today
  it does not: its only filter is `deleted_at` and a date range
  (`lib/kati/calendars/today.ex:59`). That single join satisfies all six of its callers — 01
  `home.ex:33`, 02 `calendar.ex:55`, `lock.ex:711`, `home_dark.ex:88`, `home_fa.ex:93`,
  `schedule_fa.ex:129`. Screens 09, 16, 17 and 30 do not call it (`day.ex:68` names
  `occurrences/1` in a moduledoc only) and are out of scope for this phase.
* **Six Sample modules deleted**: `Kati.Calendar.SampleDay` (`lib/kati/calendar/sample_day.ex:1`),
  `SampleWeek` (`sample_week.ex:1`), `SampleMonth` (`sample_month.ex:1`), `SampleAgenda`
  (`sample_agenda.ex:1`), `SampleEvent` (`sample_event.ex:1`) and `Kati.Settings.CalendarsSample`
  (`lib/kati/settings/calendars_sample.ex:1`), together with the fallbacks that select them:
  screen 02's today special case (`lib/kati/screens/calendar.ex:56`, whose five invented cards are
  at `:69`) — the screen already renders *"Nothing scheduled today"* for every other date
  (`:511`, and the `day_rows/1` doc at `:41-51` describes exactly the state being suppressed) — and
  screen 32's `[] -> drawn_calendars()` (`lib/kati/screens/calendars.ex:111`).
* **Home's timeline stops inventing an air date.** `rest_of_today([]), do: rest_of_today(drawn_rows())`
  (`lib/kati/screens/home.ex:582`, `drawn_rows/0` at `:569`) becomes 139's own row copy —
  *"Nothing scheduled — add anything with +"* (`lib/kati/screens/home_empty.ex:369`, built by
  `today_card/0` at `:365`) — when the permission is granted and there is nothing on. When it is
  **denied**, the row becomes the offer, because `Kati.Permissions.affordance(:denied)` is `:allow`
  (`lib/kati/permissions.ex:113`); when it is **blocked**, `affordance/1` answers `:settings`
  (`:114`) and the row must say so rather than draw a dead button.
* **`Kati.Calendars.Override`** follows the import; write-back stays off —
  `DeviceImport` sets `writeback_policy: :none` and takes `read_only` from the provider
  (`lib/kati/calendars/device_import.ex:89-93`), and `WRITE_CALENDAR` is not in the shipping
  manifest.

**Acceptance.**

| № | Assertion on a device |
|---|---|
| **P1.1** | Wiped install. Walk to 26, tap **Continue with 2**. The Android calendar permission dialog is on screen (`systemDialog`) before any step-4 content is drawn. |
| **P1.2** | Before launch, `content insert` a uniquely-titled **timed** event today against a `calendar_id` read back from the provider. Wiped install, Allow at 26, and then — **without any force-stop** — finish the run: the unique title is on Home's timeline and on screen 02 for today, and `db().count("events")` is non-zero. (Timed, not all-day: an all-day row stores `dtstart_date` with `dtstart_utc` nil (`lib/kati/calendars/device_import.ex:158-163`) and `Kati.Calendars.Today` filters on `dtstart_utc`, so it would never reach the timeline. Inside −90/+365 days, the reader's window at `KatiCalendarReader.kt:37-38`.) |
| **P1.3** | Same walk, tap Deny. The run proceeds to step 4 and completes, and Home's calendar row offers the permission again rather than showing an air date for *The Long Hollow*. |
| **P1.4** | On a set-up phone with `pm revoke android.permission.READ_CALENDAR`: tap the Allow row on screen 40, `systemDialog("Allow")` clicks the OS dialog, and an event planted before the tap appears on Home without a relaunch. |
| **P1.5** | With device calendars imported, tap the visibility switch for one calendar; force-stop; relaunch. That calendar's events are absent from Home, screen 02 and the lock drawing, and present again after tapping it back — one write, six surfaces. |
| **P1.6** | After P1.2, `assertNoText` on every string in the six deleted Sample modules across screens 09, 16, 17, 30, 31 and 32; and every event title rendered on screen 09 is a member of the set read independently out of `CalendarContract`. |

---

### Phase 2 — Every field is a field

The app believes it cannot take typed input, and the belief is written down in nine places:
`lib/kati/screens/quick_add_expense.ex:208-210` (*"Mob has no text input, which is why every field
in this app is drawn rather than typed into"*), `lib/kati/screens/add_ingredient.ex:70-71`,
`lib/kati/screens/search_typing.ex:62`, `lib/kati/screens/search_idle.ex:26-27`,
`lib/kati/screens/search_fa.ex:341-342` and `:950`, `lib/kati/screens/search_large.ex:107`,
`lib/kati/screens/my_services_empty.ex:401`, `lib/kati/screens/meal_edit.ex:608`. The repo's own tap
sweep carries the belief into its allow-list, excusing `:edit_amount`, `:edit_name`,
`:edit_quantity`, `:edit_unit`, `:search` and `:type_it_in` on the grounds that there is no
keyboard behind them (`test/kati/screen_tap_sweep_test.exs:226-235,272-284`).

**It is false, and has been false for the whole of the pinned Mob.** `MobTextField`
(`MobBridge.kt:3483-3546`, dispatched at `:3038`) reads `on_change`, `on_focus`, `on_blur`,
`on_submit`, `placeholder`, `secure`, `fill_width`, a `keyboard` prop mapping to
`Number`/`Decimal`/`Email`/`Phone`/`Uri` (`:3498-3505`) and a `return_key` prop mapping to
`Next`/`Go`/`Search`/`Send`/`Done` (`:3506-3512`). Kati already renders one twice
(`lib/kati/screens/backup.ex:984-991`, `lib/kati/screens/restore.ex:1184`), handled by
`handle_info({:change, tag, value}, …)` (`backup.ex:1311-1313`). Nine vendored components are built
on it — `lib/kati/components/mishka_number_field.ex:333`, `mishka_combobox.ex:339`,
`mishka_tags_input.ex:221`, `mishka_mask_input.ex:106`, `mishka_otp_field.ex:215`,
`mishka_pills_input.ex:212`, `mishka_json_input.ex:74`, `mishka_color_input.ex:81`,
`mishka_toolbar.ex:597` — and **no screen renders any of the nine**.

**Delivers.** A correction, and the input primitive every later phase depends on.

**Touches.**

* Delete the nine claims and the allow-list entries that rest on them. No `@inert_taps` entry may
  cite the absence of text input again.
* **The message shapes are fixed by the NIF, so write the clauses to match.** `on_submit` delivers
  `{:submit, tag}` and `on_focus`/`on_blur` deliver `{:focus, tag}` / `{:blur, tag}` —
  `sendEvent/2` at `deps/mob/android/jni/mob_nif.zig:1031-1041`, reached from `mob_send_submit` at
  `:1099-1100`; only `on_change` carries a third element (`sendChange/2`, `:1045-1052`). The prop
  names the renderer registers are exactly `on_change`, `on_focus`, `on_blur`, `on_submit`
  (`deps/mob/lib/mob/renderer.ex:320-328`). On a hand-rolled `use Mob.Screen` screen the existing
  `handle_info(_message, socket)` catch-all must stay *below* the new clause or the change message
  is swallowed.
* **Screen 124 stops writing "The Salt Almanac".** `save_expense/1` already performs a real
  `Ash.create(Kati.Money.Expense, …)` (`lib/kati/screens/quick_add_expense.ex:225-230`) — do not
  rewrite the write. What is fake is its input: `draft` is
  `Kati.Screens.QuickAdd.Sample.expense_draft()` (`:85`), whose title is the literal
  `"The Salt Almanac"` with `amount: nil` (`lib/kati/screens/quick_add/sample.ex:113-120,116`), and
  `:edit_amount` only flips `:saved?` (`:208-212`). Amount becomes a `<TextField keyboard="decimal">`,
  description a `<TextField>`. `Kati.Money.Sample`, `Kati.Money.DaySample` and
  `Kati.Screens.QuickAdd.Sample`'s expense half fall with it.
* **A stepper is not a substitute for typing a number.** Reaching page 312 from 0 is 312 taps.
  Screen 111's weight stepper (`lib/kati/screens/log_weight.ex:384-392`), screen 106's target
  stepper (`lib/kati/screens/new_goal.ex:196-200`), screen 70's page stepper
  (`lib/kati/screens/log_progress.ex:503-507`) and screen 45's quarter-portion stepper
  (`lib/kati/screens/meal.ex:1041-1052`) all compute correctly; each gains a
  `<TextField keyboard="number">` beside it. `MishkaNumberField` already pairs exactly that with
  two step buttons (`lib/kati/components/mishka_number_field.ex:6,333`), but adopting it is a **new**
  use, not an extension: screen 45 deliberately borrows only `step/3` and draws its own borderless
  32pt pill because the component is a bordered strip (`lib/kati/screens/meal.ex:550-555`). Check
  each drawing against the strip's hairlines before adopting it.
* **Screen 70's unit segments must mean something or come off.** `:unit_page`, `:unit_percent` and
  `:unit_minutes` move an assign (`lib/kati/screens/log_progress.ex:509-510`) while
  `save_session/1` writes `from_page`/`to_page` unconditionally (`:541-560`) and never reads the
  unit.
* **Screen 111's `now` chip is the app's only date control and it is a no-op** —
  `def handle_info({:tap, :now}, socket), do: {:noreply, socket}`
  (`lib/kati/screens/log_weight.ex:403`), drawn at `:200-215`. The sweep excuses it because *"Mob
  has no date input"* (`test/kati/screen_tap_sweep_test.exs:245-251`) and **that one is true** — the
  dispatch table has `text_field`, `toggle`, `slider`, `tab_bar` and nothing else that takes a value
  (`MobBridge.kt:3034-3057`). It is still not a reason to leave the chip dead: build the picker from
  screen 16's month grid out of nodes that exist, or spend one bridge fence on Android's
  `DatePickerDialog`. *I have not verified that `Kati.Health.Reading` carries a column for a
  user-chosen instant separate from the insertion clock; if it does not, the column is part of this
  deliverable.*
* **Screen 94's search field is drawn and dead** (`{Kati.Screens.CountryPicker, :search}` on the
  inert list, `test/kati/screen_tap_sweep_test.exs:194`). With seven countries the honest fix is to
  delete the drawn field, not to wire it. Screens 94 and 125 already write correctly —
  `Services.put_region/1` (`lib/kati/screens/country_picker.ex:125`) and `Money.put_currency/1`
  (`lib/kati/screens/currency.ex:392`) — and must not be touched otherwise.
* Selects and comboboxes have no native node either, and do not need one: `MishkaSelect` composes
  one from a trigger and a menu and reports `{:tap, {tag, option_id}}`
  (`lib/kati/components/mishka_select.ex:45,53,193`); `MishkaCombobox` adds a `TextField` beside it
  (`lib/kati/components/mishka_combobox.ex:339,352`). Both ship and neither is rendered by any
  screen.

**Acceptance.**

| № | Assertion on a device |
|---|---|
| **P2.1** | `grep` is not the assertion: on a device, drive every former "no text input" control that this phase converts and assert each produces a `{:change, …}`-driven assign change. The host half — no `@inert_taps` entry citing the absence of text input, and no such claim left in `lib/` — fails the build, not the device run. |
| **P2.2** | Wiped install. Calendar → Quick add expense, type `12.50` into the amount field and a description into the other, tap **Add**, open screen 122. The expense shows the typed description with `amount_pence: 1250`, and `db().scalar` finds **no row in any table** containing `The Salt Almanac`. |
| **P2.3** | On screen 111, type `81200` into the number field beside the stepper rather than stepping to it; Save; `db().scalar("select grams from health_readings order by rowid desc limit 1")` is `81200`. |
| **P2.4** | On screen 111, the `now` chip opens a date control, a date other than today is chosen, Save; the stored reading carries that date, and reopening the screen shows it. |
| **P2.5** | On screen 94, `assertAbsent` for the drawn search field; the seven country rows are still present and tapping one writes the region (survives a force-stop). |

---

### Phase 3 — Every screen knows which row it is looking at

`Mob.Socket.push_screen/3` has taken a params map since the pinned Mob
(`deps/mob/lib/mob/socket.ex:142-144`) and hands it to the destination's `mount/3` as its **first**
argument (`deps/mob/lib/mob/socket.ex:136`, `deps/mob/lib/mob/screen.ex:168`).
`Kati.Screens.Pushed`'s macro already assigns it — `Mob.Socket.assign(socket, :params, params)`
(`lib/kati/screens/pushed.ex:54`) — on all 100 screens that use it.

There are **169** `push_screen` call sites in `lib/kati/screens/`. **Five** pass params:
`auto_detect_music.ex:579` (an empty map), `notification_access.ex:475`, `states.ex:420`,
`auto_detect.ex:459`, `calendar.ex:1105`. **One** screen reads them, and by overriding `mount/3`
rather than through the assign (`lib/kati/screens/retired_tile.ex:226,229`). `assigns.params` is
read by no screen at all — the only match in `lib/kati/screens/` is `calendar.ex:1099`, a comment
saying nobody reads it. `lib/kati/screens/calendar.ex:1096-1105` is the clearest confession: it
passes `%{date: date}` to screen 09 with a comment saying the callee throws it away because
*"Teaching 09 to read it is a change to `day.ex`, which this screen does not own"*. Ownership is not
a reason for a route to lose its argument.

**Delivers.** The rule that makes every detail screen, sheet and editor about the thing you tapped.

**Touches.**

* **The rule.** Every push that opens a detail, a sheet or an editor carries the entity's id, and
  the callee reads `assigns.params` (on a `Kati.Screens.Pushed` screen) or its first `mount/3`
  argument (on a hand-rolled `use Mob.Screen` screen) before it reads anything else. A push with no
  id is a bug, not a fallback. The one documented exception is where the drawing is genuinely about
  *the next one* — `Kati.Screens.Medication`'s two buttons, which the file is explicit are about
  the next dose you have not decided about (`lib/kati/screens/medication.ex:391-393`).
* **Screen 31 Event detail is a picture of one fixed event.** `Kati.Screens.Calendar` pushes it by
  kind with no id (`lib/kati/screens/calendar.ex:1043`) and its `mount/3` assigns
  `Kati.Calendar.SampleEvent.event()` unconditionally (`lib/kati/screens/event_detail.ex:88`), so
  every control on it — section chips at `:690-692`, field switches at `:694` — mutates a copy of a
  sample while `DeviceImport` writes real rows next door. After Phase 1 the rows are real; this is
  the phase that opens the right one.
* **Screen 09 reads the date it was handed** (`lib/kati/screens/calendar.ex:1105` already sends it).
* **Screen 104's `toggle_repeat` writes every goal in the database.**
  `Enum.each(stored(), fn goal -> Ash.update(goal, %{repeat: now}) end)`
  (`lib/kati/screens/goals.ex:419-425`) — one switch, an unbounded update. The row must carry an id
  and the write must name it.
* **The head-of-list readers.** `current_book/0` is `Ash.read(Book, action: :shelf)` → `[book | _rest]`
  (`lib/kati/screens/log_progress.ex:99-103`); `lib/kati/screens/log_listen.ex:472-476` and
  `lib/kati/screens/meal_edit.ex:67-71` are the same shape. They take an id. Their *acceptance*
  arrives with the phase that gives their domains an origination path — a second book cannot be
  created today, so the assertion cannot be reached (Phase 11 and the deferred domains).
* **The media screens are prepared here and proved in Phase 6.** 04 `lib/kati/screens/series.ex:110`,
  08 `film.ex:68`, 14 `series_meta.ex:87`, 33 `rating.ex:175`, 144 `rate_episode.ex:226` and 149
  `drop_sheet.ex:171` all `use Mob.Screen` and discard the params argument as `_params`
  (`series.ex:134`, `film.ex:90`, `series_meta.ex:98`, `rating.ex:189`, `rate_episode.ex:242`,
  `drop_sheet.ex:210`); 34 `season.ex:150` and 35 `series_settings.ex:100` `use Kati.Screens.Pushed`
  and read `assigns.params`. Every push into those eight carries `%{tracked_title_id: id}`.
* **The two search doors stop discarding their query.** `Kati.Screens.SearchIdle`'s `:repeat_query`
  and `:try_suggestion` both push `Kati.Screens.Search` with no arguments
  (`lib/kati/screens/search_idle.ex:209-213`), so tapping *dentist* on screen 86 opens a search for
  nothing. Pass `%{query: label}`; screen 19's `mount/3` reads it instead of ignoring `_params`
  (`lib/kati/screens/search.ex:119`). Proved in Phase 9.

**Acceptance.**

| № | Assertion on a device |
|---|---|
| **P3.1** | With calendar rows imported (Phase 1), tap the **second** event on screen 02. The uid rendered on screen 31 is the second row's, read back from `db()` — not the first's and not `Kati.Calendar.SampleEvent`'s. |
| **P3.2** | With two goals stored, toggle repeat on the first. `db()` shows the first changed and the second unchanged. |
| **P3.3** | On screen 02, move to a date that is not today and tap into screen 09. The day drawn is the date that was tapped, and its events are that date's rows from `db()`. |

---

### Phase 4 — A failed write says so

Twelve write sites swallow their failures. Nine rescue to `:ok`:
`lib/kati/screens/log_progress.ex:559` and `:577`, `log_weight.ex:423`, `log_listen.ex:537`,
`new_goal.ex:248`, `quick_add_expense.ex:235`, `meal_edit.ex:620`, `book_detail.ex:965`,
`drop_sheet.ex:330`. Three rescue into a socket, and **not one of the three does what it looks like
it does**:

* `lib/kati/screens/artist_detail.ex:553` is the only genuine revert — it re-assigns
  `socket.assigns.artist` unchanged, so the follow toggle springs back.
* `lib/kati/screens/goals.ex:424` does **not** revert. `socket` inside a function-level `rescue` is
  still the *pre-tap* socket, so `not socket.assigns.repeat` is byte-for-byte the value the success
  path assigns at `:422`. A total failure across every goal leaves the switch showing the new
  position.
* `lib/kati/screens/medication.ex:401` returns `socket` un-refreshed — it skips the
  `Mob.Socket.assign(socket, :doses, doses())` at `:399`, so the list keeps the pre-tap doses rather
  than reverting anything.

**The `rescue` is the smaller half of the defect.** `Ash.create/2` and `Ash.update/2` return
`{:ok, record} | {:error, error}`; they do not raise on a validation failure, a constraint violation
or a missing row. Every one of these sites discards the return value entirely —
`lib/kati/screens/log_progress.ex:543` and `:553` are statements whose result goes nowhere, and the
function then returns a hardcoded `:ok` (`:557`). The common failure never reaches the `rescue`; it
is thrown away one line earlier. Removing the twelve `rescue` clauses without matching on the tuples
would change nothing a user could see.

**Delivers.** A failed save that is distinguishable from a successful one, everywhere.

**Touches.**

* **Every write site matches on the tuple.** `case Ash.create(…) do {:ok, row} -> …; {:error, error} -> … end`
  — no bare statement, no discarded result. A write whose result is not inspected fails the build:
  this is a lint in the manner of `test/kati/boot_path_test.exs:31-48`, which already enforces that
  any file calling `Req` also calls `Kati.Net.Tls.ensure!/0`.
* **The `rescue` narrows to what a rescue is for.** Keep exactly one blanket rescue at the screen
  process boundary — `Kati.Screens.Root.rescue_tap/3` already is that boundary
  (`lib/kati/screens/pushed.ex:71-73`) — and delete the twelve local ones. A raise from the data
  layer is a crash worth seeing in logcat through `Mob.NativeLogger`; an `{:error, _}` is a sentence
  for the user. The eleven `rescue _error -> nil` clauses that make a failed *read* look like an
  empty store go the same way, because that is how the head-of-list readers fail silently.
* **The failure becomes a value with a message.** `Kati.Backup.Error` is a
  `defexception [:reason, :message, details: %{}]` whose moduledoc states the rule to generalise:
  *"every refusal is a sentence a screen has to show a user who is standing in front of a phone"*
  (`lib/kati/backup/error.ex:1-11`). Add `Kati.WriteError` with the same three fields, and one
  `Kati.Screens.Notice` component lifted from `Kati.Screens.Restore.notice_block/1`
  (`lib/kati/screens/restore.ex:1007-1090`), which already renders `tone`, `icon`, `title`, `body`
  and a dismiss tap (`:1268`). Screen 128 already models the mapping from error to titled notice
  (`lib/kati/screens/backup.ex:1298-1300`).
* **The sheet does not close on a failed save.** Six of the nine `:ok` sites are called from a
  handler that immediately pops — `log_weight.ex:405-408`, `log_progress.ex:518-521`,
  `log_listen.ex:487-490`, `new_goal.ex:209-212`, `quick_add_expense.ex:203-206`,
  `meal_edit.ex:592-595` — so the modal dismisses whether or not anything was written. The other
  three fail differently and need the same treatment: `log_progress.ex:577` (`finish_book/0`) is
  reached from `:524-527`, `book_detail.ex:913` and `book_detail_dark.ex:595`, so a failed finish
  still navigates; `book_detail.ex:965` is followed by an assign that re-reads the book (`:935`), so
  the chip snaps back with no explanation; and `drop_sheet.ex:330` returns `:ok` into a sheet that
  keeps its own assigns (`:318-320`), so the drop appears to have happened. **This reverses a
  decision the repo took on purpose**: `lib/kati/screens/log_progress.ex:534-538` argues *"a modal
  that refuses to dismiss when the disk is full is a worse failure than a lost session"*. It is not
  — a lost session the user believes was saved is the worst outcome available, and it is the one the
  app currently produces. Overrule it in that moduledoc in the same commit, or the next reader
  restores the rescue. On `{:error, _}` the sheet stays open, the commit control returns to its
  resting state, and a notice appears above it naming what happened. On `{:ok, _}` it closes as now.
* **What the user sees, precisely.** Saving a weight with no room left leaves the sheet open with an
  amber notice reading *"That reading was not saved — there is no room left on this phone. Nothing
  was lost; try again after freeing some space."* Ticking an episode against a title deleted
  underneath leaves the tick unfilled with *"That episode is no longer in your library."* Nothing
  silently succeeds, and nothing shows a spinner it cannot end.

**How the harness makes a write fail.** Deterministically, not by filling the disk: with the app
force-stopped, `chmod 444` the three database files and `chmod 555 files`, then relaunch. SQLite
opens read-only and every write returns *attempt to write a readonly database*. The e2e build is
`initWith debug`, so `run-as` works and the test process shares the app's uid; restore the modes
afterwards.

**Acceptance.**

| № | Assertion on a device |
|---|---|
| **P4.1** | Database read-only. Attempt to save a weight on screen 111. The sheet is **still on screen**, a notice containing the words "not saved" is rendered, and `health_readings` is byte-identical to before. |
| **P4.2** | Same screen, normal conditions. The sheet is gone and `health_readings` gained exactly one row. |
| **P4.3** | Database read-only once, then drive every reachable former swallow site in one pass — 111 *Save*, 106 *Save*, 124 *Add*, 149 drop, 104 repeat toggle, 112 dose tick, plus 04's episode tick and 33's Save once Phase 6 lands — and after each assert (a) a notice naming the failure, (b) the control back in its pre-tap position, (c) the underlying table unchanged. Sites whose screens have no origination path yet (70, 73, 66, 118, 77) are **skipped visibly** in the harness output; a silently absent row is how "Books never shipped" becomes "Books shipped and nobody checked". |
| **P4.4** | The 104 case specifically: after a total write failure across every goal, the repeat switch reads as **off**. This is the one that fails today in the least obvious way — the current rescue leaves it in the new position. |

---

### Phase 5 — The preferences the app already collects and throws away

**Delivers.** One `Mob.State`-backed home for every answer a switch, chip or tile already asks for,
and readers for each. `Mob.State` is a `:dets` file at `MOB_DATA_DIR/mob_state.dets`
(`deps/mob/lib/mob/state.ex:5-7,35-37`), so it survives an app kill; it holds 25 small preferences
today and every module below is shaped like the ones already there —
`Kati.Theme.Mode.choice/0` + `put/1` (`lib/kati/theme/mode.ex:102-121`) and `Kati.Locale`
(`lib/kati/locale.ex:20-32`).

**Touches.**

* **`lib/kati/sections.ex`.** Two moduledocs already name it —
  *"What it needs is `Kati.Sections`: a preference over `Mob.State` shaped like `Kati.Theme.Mode`"*
  (`lib/kati/screens/pick_sections.ex:60-64`) and `lib/kati/screens/settings.ex:225-231` from the
  other end — and `grep -rn "Kati.Sections" lib/` returns those two comments and one in the sample
  (`lib/kati/screens/pick_sections/sample.ex:7`). `choices/0` is **26's six**
  (`lib/kati/screens/pick_sections/sample.ex:16-23`), not 24's five
  (`lib/kati/settings/sample.ex:84-102`), because 26 is the screen that asks and 24 is the screen
  that revises. `enabled/0` defaults to `nil` — unset — rather than to a set, so a screen can tell
  *never answered* from *answered with nothing*, the distinction `Kati.Onboarding.complete?/0` is
  already careful about (`lib/kati/onboarding.ex:38-46`). `put/1` persists before it returns.
  Readers, all three in the same change, because a stored preference with no reader is worse than
  none (`lib/kati/screens/settings.ex:213-218` argues this and is right): `Kati.Screens.Home.sections/0`
  (`lib/kati/screens/home.ex:480-489`) builds its grid from the enabled set instead of three
  hardcoded tiles with the invented sub-lines `"Dinner 19:30"` and `"2 left today"` (`:484`, `:486`)
  — `tile_meta/1` already renders nothing for a `nil` meta (`:540`), so they can go with no new
  drawing; `Kati.Screens.Library`'s shelf chips read it instead of the fixed
  `@screen_kinds [:movie, :tv, :anime]` (`lib/kati/screens/library.ex:62-65`); and
  `Kati.Screens.Settings`'s switches read and write the same key, so
  `lib/kati/settings/sample.ex:84-102` becomes drawn copy for labels only.
* **26 cannot continue with zero.** `commit/1` wires `on_tap={go}` unconditionally and only the
  label reads the count (`lib/kati/screens/pick_sections.ex:346-354`), so today Continue-with-0 is
  tappable and would store an empty set. It takes the count it already computes and omits `on_tap`
  at zero.
* **`lib/kati/preferences.ex`** for the switches that have no column and should not get one:
  screen 24's Appearance and Sections rows, which today flip a copy of `Kati.Settings.Sample`
  (`lib/kati/screens/settings.ex:800-801,815-826`); screen 41 Accessibility and screen 39 Widgets,
  which `List.update_at` over a Sample (`lib/kati/screens/accessibility.ex:589-597`,
  `lib/kati/screens/widgets.ex:659-667`); screen 25 Release watcher's per-kind defaults
  (`lib/kati/screens/release_watcher.ex:256-264`); the mode switches on 36, 150, 152 and 37
  (`auto_detect.ex:422`, `auto_detect_music.ex:548`, `anime_filter.ex:544-571`, `import.ex:514`) —
  152's four taps are a questionnaire whose answer decides whether Anime is a shelf filter, so it
  must survive the screen; and screen 35's four non-per-show rows, Region, My services, price drops
  and quality, which the file names as its blocker (`lib/kati/screens/series_settings.ex:57-66`).
  Accessibility's Dynamic Type row stays a stored preference with a documented no-op — the file is
  honest that it has no consequence to draw (`lib/kati/screens/accessibility.ex:457-465`) — which is
  different from a switch that forgets.
* **Do not touch screen 92.** Its three availability rules are already correct:
  `Services.toggle_rule/1` then a re-read (`lib/kati/screens/my_services.ex:418-421`), backed by
  `Mob.State` (`lib/kati/services.ex:115-127`). It is the shape every module above copies. Screen 93
  stays deliberately socket-only for a reason that holds — it is a reference board about defaults
  and *"the first tap would turn the reference into somebody's settings"*
  (`lib/kati/screens/my_services_empty.ex:419-425`) — provided it keeps its Gallery-only status,
  which Phase 10 settles.
* **Sticky or not, say which.** No screen in the app opts into `Mob.ScreenState` — `vsn:` appears
  nowhere in `lib/`, so the `mob_screen_states` table created on every device
  (`priv/repo/migrations/20260507000001_create_mob_screen_states.exs`) never receives a row
  (`deps/mob/lib/mob/screen.ex:100-101`). Screen 03's filter chips are mechanically correct
  (`lib/kati/screens/library.ex:507-514`, `visible/3` at `:637-644`) and their selection does not
  survive leaving the screen. If a filter is meant to be sticky it belongs in `Kati.Preferences`; if
  it is not, the moduledoc says so.

**Acceptance.**

| № | Assertion on a device |
|---|---|
| **P5.1** | Wiped install. Run onboarding picking **only** Music and Habits. Home's sections grid contains Music and Habits tiles and no Screen, Books, Money or Notes tile; Settings shows the same two on and the rest off. Force-stop, relaunch — unchanged, proving the DETS write rather than an assign. |
| **P5.2** | Walk to 26 and untick both pre-chosen tiles. The button reads **Continue with 0** and tapping it leaves the app on 26. |
| **P5.3** | For each switch this phase moves into `Kati.Preferences` — 24, 25, 36, 37, 39, 41, 150, 152 — flip it, force-stop, relaunch, reopen the screen: the new position is drawn. `db()` is unchanged; the receipt is `mob_state.dets`. |
| **P5.4** | The resting state is read from where the tap writes: with the app backgrounded, revoke a permission from system settings, return to screen 40 — the row shows the OS's answer, not the one the app last drew. |

---

### Phase 6 — The film-and-TV spine

Issue #60 decided that v1 ships one media domain, Screen (film and TV), and it is the one with no
write path at all (`docs/STATE-OF-THE-APP.md:681-684`). Nine reachable screens query `Kati.Media`
correctly — 03 Library, 04 Series, 05 New releases, 07 Your year, 08 Film, 10 Up next, 15 Activity,
33 Rating, 34 Season — and every one falls back to a Sample, because all three tables underneath are
empty and cannot become otherwise. Four fall back to `Kati.Library.Sample` (03, 04, 05, 08); the
other five to their own (`Kati.Stats.Sample` on 07, `Kati.Screens.UpNext.Sample` on 10,
`Kati.Activity.Sample` on 15, `Kati.Rating.Sample` on 33, `Kati.Season.Sample` on 34). Killing
`Kati.Library.Sample` alone does not finish the spine; the other five fall with `Watch`.

One distinction the audit's table does not draw and this phase turns on: **a write path is not an
origination path.** Ten of the fifteen Ash write sites in `lib/kati/screens/` are `Ash.update/2`
against a row that must already exist. `Kati.Music.Album` has a write path
(`lib/kati/screens/log_listen.ex:532`) and has never held a row. A resource with an update path and
no create path is exactly as disconnected as one with neither, and worse, because it reads as
connected in a grep.

**Delivers.** A title you added, on your shelf, with the episodes you ticked, surviving a restart.

**Touches.**

* **(a) Screen 06 becomes a real field.** Today its search box is a `<Text text="quiet">` with a
  2×19 accent `<Box>` for a caret (`lib/kati/screens/add_title.ex:220-250`), `mount/3` assigns
  `Sample.search_results()` and never replaces them (`:99`), the chips narrow that sample list by
  string-matching `meta` (`:168-170`), the `add_*` tap flips a boolean in the socket (`:144-150`) —
  that boolean is the *add* gesture for the whole spine — and *"Can't find it? Add it by hand"* is a
  `<Row>` with no `on_tap` at all (`:427-451`). The field becomes the same `<TextField>` screen 128
  ships (Phase 2), and **"Add it by hand" becomes a real control**: it creates a `CachedTitle` with
  `source: :manual` plus a `TrackedTitle`, which is what makes the spine work with no network and is
  the fallback the feature needs anyway.
* **The `:manual` enum.** `CachedTitle.source` and `TrackedTitle.source` are both constrained to
  `[:tmdb, :tvmaze, :anilist, :jikan, :openlibrary, :musicbrainz, :wikidata]`
  (`lib/kati/media/cached_title.ex:52-57`, `lib/kati/media/tracked_title.ex:81-86`) with no
  `:manual`, and `test/kati/media_release_test.exs:275-276` pins the two lists equal. Add `:manual`
  to both and to that expectation — deliberately, rather than working around the constraint with a
  fake `:tmdb` id.
* **(b) Tapping a result writes two rows, in one order.** `CachedTitle` first (`create: :*` is
  available, `lib/kati/media/cached_title.ex:134`), then `TrackedTitle.:create`
  (`lib/kati/media/tracked_title.ex:164`) with `status: :not_started`, carrying the same
  `{source, source_id}` pair — the resource is explicit that this is a value pair and not a foreign
  key, so a cache eviction cannot take the tracking row down (`lib/kati/screens/library.ex:94-96`).
  `TrackedTitle.:by_reference` (`lib/kati/media/tracked_title.ex:186`) already exists for exactly
  the "is this already in the library?" question 06 has to ask, and has never been called from a
  screen.
* **(c) The episode tick writes a `Watch`.** `lib/kati/screens/series.ex:1061` must
  `Ash.create(Kati.Media.Watch, %{tracked_title_id: …, episode_source_id: …, season_number: …,
  episode_number: …, watched_on: Kati.Time.today(), watched_at: Kati.Time.now()})` — `create: :*` is
  available (`lib/kati/media/watch.ex:152`) and `tracked_title_id` is the only required field
  (`:145-148`) — bump `TrackedTitle.progress_season`/`progress_episode`, and re-derive the counter
  from the ticks, which is what `lib/kati/screens/library.ex:150-153` already says the counter is.
  **Write both stamps, not just `watched_on`.** They are separate nullable columns
  (`lib/kati/media/watch.ex:75-76`) and the app already disagrees with itself about which to prefer:
  `lib/kati/screens/rate_episode.ex:311` sorts `watched_at: :desc, inserted_at: :desc` and
  `lib/kati/screens/activity.ex:656-661` reads the instant first, while
  `lib/kati/screens/film.ex:310-312` and `lib/kati/screens/lock.ex:791-796` take `watched_on` first.
  Untick destroys the row.
* **(d) Screen 33 Rating gets its controls.** Its own moduledoc is the spec: *"The five stars carry
  no `on_tap`, the `5★`/`10pt` toggle carries none, the three context rows are
  `Kati.UI.SettingsList` rows with a chevron and no handler, and the review body is a `Text` with a
  drawn caret rather than a `TextField`"* (`lib/kati/screens/rating.ex:121-127`), and `Save` pops
  (`:1056`). Every column exists: `rating` (1..10) and `review` (`lib/kati/media/watch.ex:80-81`),
  `contains_spoilers` (`:85`), `service`, `place`, `companions`, `tags` (`:91-101`), `moods` (`:122`).
  A tap target per star and half-star; a `<TextField>` for the review; a `MishkaSelect` behind each
  context row; `:add_tag` opening a `MishkaTagsInput`; `Save` writing the row named in
  `assigns.params`. `test/kati/screen_rating_log_test.exs:27-29`'s *"Screen 33 reads"* assertion is
  deleted as part of this work. Screen 144 Rate an episode is the same shape — `:save` pops
  (`lib/kati/screens/rate_episode.ex:1006`) and only the verdict accordion moves (`:1008-1011`).
* **(e) Screen 35's four per-show switches write.** The columns exist —
  `notify_new_episodes`, `auto_add_new_seasons`, `add_air_dates_to_calendar`,
  `hide_unwatched_titles` (`lib/kati/media/tracked_title.ex:135-145`) — and the screen has no
  `on_tap` anywhere, for a reason its moduledoc states well: *"A switch that flips and forgets is
  not a smaller version of a switch that works"* (`lib/kati/screens/series_settings.ex:95-98`). The
  other four rows on that screen unblock in Phase 5.
* **(f) Screen 149's drop, and the shelf's filters.** 149 already writes
  `Ash.update(tracked, attrs)` (`lib/kati/screens/drop_sheet.ex:327`) and is the eleventh writing
  screen with no door; its route arrives in Phase 10. Screen 145's tap dispatcher is real arithmetic
  over a typed fixture — `toggle_single/3`, `toggle_set/3` and `recompute/1`
  (`lib/kati/screens/shelf_filters.ex:332-363,418`) genuinely intersect the selected buckets — but
  every bucket and count comes from `Kati.Library.ShelfFiltersSample`, whose `total/0` is the
  drawing's `418` (`lib/kati/library/shelf_filters_sample.ex:97`) and whose genre counts are typed
  (`:70`). Every bucket and count derives from the shelf query here; the disc that opens the sheet,
  and its Apply, arrive in Phase 10. Screen 146's three bulk actions and its undo are implemented
  entirely in socket assigns with zero `Ash.` calls in the file
  (`lib/kati/screens/shelf_selection.ex:879-940`); they resolve to `Ash.bulk_update`/`bulk_destroy`
  over the selected `TrackedTitle` ids, and undo re-creates rather than re-assigns.
* **(g) The Samples that fall.** `Kati.Library.Sample` (`lib/kati/library/sample.ex:1`) is the
  acceptance condition for the whole spine: it is called by seven screens —
  `lib/kati/screens/library.ex`, `series.ex`, `inbox.ex`, `add_title.ex`, `film.ex`, `day.ex`,
  `shelf_selection.ex` — and by `Kati.Seeds.seed_media/0` (`lib/kati/seeds.ex:390`). With it go
  `ShelfFiltersSample`, `Kati.Screens.UpNext.Sample`, `Kati.Season.Sample`,
  `Kati.Screens.SeriesMeta.Sample`, `Kati.SeriesSettings.Sample`, `Kati.Rating.Sample`,
  `Kati.Screens.RateEpisode.Sample`, `Kati.Screens.DropSheet.Sample`, `Kati.Media.AnimeSample`,
  `Kati.NumberingScheme.Sample`, `Kati.Activity.Sample`, `Kati.Stats.Sample` and
  `Kati.Stats.ShareSample`, each replaced by the column named in the removal table — for the last
  two, counts over `Watch` rows. Their Persian mirrors fall the same day their English parents do; a
  mirror still holding a Sample after its parent is real is a regression, not a leftover.
* **(h) Library's own empty state.** `titles/0` falls back to `drawn_titles/0` on an empty store
  (`lib/kati/screens/library.ex:81-87`, `:83`), nine invented posters. It becomes 27's empty
  recipe — glyph tile, sentence, one ink action — the shape
  `Kati.Screens.HomeEmpty.invitation/0` already draws (`lib/kati/screens/home_empty.ex:248`), with
  the action pushing screen 06. Screen 07's `Sample.year()` with `rising?: true`
  (`lib/kati/screens/stats.ex:94-97`) becomes real zeros: the contribution grid's intensity ladder
  already has an unpainted level (`:830`), so a year with no watches is a grid of level-0 cells,
  which is what the year *is*.
* **(i) One defect that only becomes visible now.** `Kati.Backup.Catalog` classifies `CachedTitle`,
  `CachedSeason` and `CachedEpisode` as `:cache` and excludes them from every backup, on the stated
  grounds that each "re-fetches" (`lib/kati/backup/catalog.ex:168-195`; `@excluded` holds eight
  resources). Nothing re-fetches. And `lib/kati/screens/library.ex:130` —
  `|> Enum.reject(&is_nil(&1.title))`, argued at `:97-102` — drops any tracked row with no cached
  title. So restoring your own backup onto a new phone shows you an empty library. The fix is not to
  add the cache tables to the backup; it is that Phase 7's fetch must exist before the restore path
  can be called correct, and until it does, screen 129 says so rather than reporting a successful
  restore. (`Kati.Backup.Restore` *is* a real production write path the audit does not count:
  `lib/kati/screens/restore.ex:1354` → `Kati.Backup.restore_file/2`, writing the 29 tables in
  `Kati.Backup.Catalog.@entries` (`lib/kati/backup/catalog.ex:107`) through `Ash.Seed.seed!/2`
  (`lib/kati/backup/restore.ex:218,223`) in one transaction (`:152`). It is not an *origination*
  path: it replays rows a Kati install produced, and no Kati install can produce them.)
* Two more Samples fall here because their screens are finished code behind a drawn number:
  `Kati.Backup.Sample` (`lib/kati/backup/sample.ex:1`) is replaced by `Kati.Backup.export/1`
  (`lib/kati/backup.ex:91`), which screen 128 already calls at `lib/kati/screens/backup.ex:695` and
  whose `record_counts` are real; `Kati.Backup.SampleRestore` (`lib/kati/backup/sample_restore.ex:1`)
  by `Kati.Backup.inspect_file/2`, already called at `lib/kati/screens/restore.ex:1322`.

**Acceptance.**

| № | Assertion on a device |
|---|---|
| **P6.1** | Wiped install, past onboarding. Home → Add a title, tap the field, type `Hollow`. The field's semantics text is `Hollow`, not `quiet`. |
| **P6.2** | Continuing: tap the first result. `db()` gains exactly one `tracked_titles` row and one `cached_titles` row with matching `source`/`source_id`, and no `cached_titles.source_id` starts with `sample:`. |
| **P6.3** | Continuing: back out to Library. The grid contains the added title, and `assertNoText` for all nine of `Kati.Library.Sample`'s titles. |
| **P6.4** | Airplane mode, wiped install, onboarding complete. Add a title → *Add it by hand*, type a name, save. A `tracked_titles` row exists whose `cached_titles.source` is `manual`. |
| **P6.5** | With a series tracked, open 04, tap an episode row, force-stop (a new Orchestrator process), relaunch, reopen 04. The tick is still filled **and** `db().count("media_watches")` is 1, with both `watched_on` and `watched_at` non-null. |
| **P6.6** | Continuing: tap the same row again, force-stop, relaunch. `media_watches` is empty and the tick is clear. |
| **P6.7** | With two titles tracked, open the **second** from Library, then reach 33 Rating from it. The title on 33 is the second. Repeat for 04, 08, 14, 34, 35 — the Phase 3 rule, proved where the rows finally exist. |
| **P6.8** | On 33: tap the 4th star, type a review, Save; reopen. Four filled stars, the typed text, and a `Kati.Media.Watch` in `db()` with `rating: 8` and that `review`. |
| **P6.9** | Open a series' settings, tap `:switch_notify_new_episodes`, force-stop, relaunch, reopen. The switch is still off and that `TrackedTitle` row reads `notify_new_episodes: false`. |
| **P6.10** | After the journey above, for each of Library, Series, Up next, Activity and Your year: `assertNoText` on every string in that screen's `*Sample*` module, and `assertText` on a value the journey itself created. Screen 145's filter counts equal counts computed from `db()`. |
| **P6.11** | Add a title, tick an episode, log a weight. Export a backup, uninstall, reinstall, restore it. `tracked_titles`, `media_watches` and `health_readings` match row for row, screen 03 renders the restored title rather than `Kati.Library.Sample` — and until Phase 7 lands, screen 129 states in words that cached titles cannot be restored, rather than reporting an unqualified success. |

---

### Phase 7 — One provider, one call

Films work on Phase 6 alone. Series do not: nothing can be ticked before `cached_episodes` has
rows, and `Kati.Media.CachedEpisode` cannot be typed by hand at any sane cost.

**No section of this specification designs this client, and I am not going to invent one here.**
What can be stated is the contract it must meet and the ground already prepared. `mix.exs:81`
declares `{:req, "~> 0.7"}`; `mix.exs:110-131` syncs a CA bundle into `priv/` on every compile and
`lib/kati/net/tls.ex:53-61` loads it before the first request;
`test/kati/boot_path_test.exs:31-48` already enforces that any file calling `Req` also calls
`Kati.Net.Tls.ensure!/0`; the manifest requests `INTERNET`
(`test/kati/host_hardening_test.exs:110`); and issue #56 already decided the key model. On the
Android side `KatiRefreshWorker.doWork()` is a labelled hole — a comment and an empty array where
the fetch belongs (`android/app/src/main/java/com/example/kati/KatiRefreshWorker.kt:202-207`), its
own KDoc saying *"Missing: the actual metadata fetch"* (`:176`) — and the BEAM→worker half,
`Kati.Background.Handoff.put_watchlist/2` (`lib/kati/background/handoff.ex:112`), has no caller in
`lib/`, so the worker would have no watchlist to check even if the fetch were written.

**Delivers.** Seasons and episodes for a series you added, so the tick has something to tick.

**Touches.** One `/3/search/tv` behind screen 06 and one `/3/tv/{id}` after the tap, filling
`CachedTitle`, `CachedSeason` and `CachedEpisode` together. Two constraints this phase is held to,
both from the spine's requirements: **the fetch is a write into the three cache tables and nothing
else**, and **every screen keeps working with `source: :manual` rows when the fetch is
unavailable**. The durable/cached split already guarantees the second is possible. Screen 80 *Data
sources* draws a "last reached" column from `CachedTitle.fetched_at` per source
(`lib/kati/screens/data_sources.ex:135-152`) and correctly shows `—` today (`:121`); this is the
phase after which that column means something.

**Acceptance.**

| № | Assertion on a device |
|---|---|
| **P7.1** | Online. Add a series through screen 06 by tapping a search result. `db()` gains rows in `cached_seasons` and `cached_episodes` for that title; screen 34 lists the seasons the provider returned; and no other table gained a row. |
| **P7.2** | Airplane mode, same journey through *Add it by hand*. Screens 03, 04, 08, 10 and 34 all render without an error notice, the manual title is on the shelf, and screen 80's "last reached" column reads `—` for every source. |

---

### Phase 8 — The first run hands over a usable app

The first run today asks four questions and keeps one. Language is written and survives
(`lib/kati/screens/language_pick.ex:550`). The sections you pick die with the socket
(`lib/kati/screens/pick_sections.ex:129` moves a `MapSet` in assigns). The notification choice is
never asked — screen 38's three option cards carry no `on_tap`
(`lib/kati/screens/onboarding.ex:243-297`). The first title is never added — the four posters carry
no `on_tap` either (`:437-495`) — and both **Finish setup** and **Skip** are wired to the same tag,
`:finish` (`:385`, `:401`).

**The contract: seven facts that must hold when `Kati.Onboarding.complete!/0` returns.**

1. A locale is stored, **and every screen after 53 is in it**.
2. A section set is stored, read by Home, Library and Settings, so a section you did not pick is
   absent rather than drawn.
3. A notification delivery style is stored (`:quiet | :push | :digest`), and the OS notification
   permission has been requested if and only if the answer was not `:quiet`.
4. `READ_CALENDAR` has been requested exactly once, and if granted the device's calendars and
   events are already in `kati.db` before the first root mounts (Phase 1).
5. The completion flag is set on **every** path that leaves the run — including the restore branch,
   which today cannot set it at all.
6. Either one real `TrackedTitle` exists, or none does and every screen says so. No curated poster
   set, no seeded row.
7. Every root screen renders its own emptiness. Not one Sample fallback survives on a path a user
   can reach.

**Touches.**

* **Five steps, not four.** `test/design/reference/134.html` draws
  53 Language → 38·1 Welcome → 26 Sections → 38·3 Loudness → 38·4 First title → 01 Home, and says
  in as many words that 38's own "1 of 4 … 4 of 4" must be renumbered to five segments at build
  time. The code walks four and the meters already disagree out loud: 53 draws five
  (`lib/kati/screens/language_pick.ex:156-157`), 26 draws `{4, 2}`
  (`lib/kati/screens/pick_sections/sample.ex:40`), 38 hardcodes `1..4`
  (`lib/kati/screens/onboarding.ex:145`), 135 draws five with two filled
  (`lib/kati/screens/restore_first_run.ex:227-232`), and 137 already draws `{5, 3}`
  (`lib/kati/screens/onboarding_fa/sample.ex:46`, rendered at `lib/kati/screens/onboarding_fa.ex:193-201`),
  which is 134's answer exactly. `Kati.Screens.Onboarding` splits into three mounts driven by a step
  parameter — `%{step: 2}`, `%{step: 4}`, `%{step: 5}` rendering `welcome/1`, `telling/1` and
  `first_title/1` — rather than all three stacked in one scroll
  (`lib/kati/screens/onboarding.ex:87-91`). No new mechanism: `push_screen/3` carries params and
  `Onboarding.mount/3` already receives them (`lib/kati/screens/onboarding.ex:64`). `steps/1` takes
  a total as well as a done count so all four screens read one function —
  `Kati.Screens.OnboardingFa.steps/0` is already written that way and is the model.
* **This is not tidiness.** Today `:get_started` — the button at the top of the stacked screen, the
  *first* thing a user sees on 38 — calls `Kati.Onboarding.complete!/0` and resets to Home
  (`lib/kati/screens/onboarding.ex:526-529`). A user who taps the obvious button on step two has
  finished onboarding without being shown steps three, four or five. Splitting the screen removes
  that by construction.
* **The locale must survive the screen that asks for it.** 53's Continue pushes
  `Kati.Screens.PickSections` unconditionally (`lib/kati/screens/language_pick.ex:535`), so a فارسی
  run is English from step 2 onward; only the shell root after the run honours the choice
  (`lib/kati/onboarding.ex:85-86`). Every push in the chain goes through one locale-aware function
  on `Kati.Onboarding`, in the shape `shell_root/1` already has, so step 3 resolves to
  `Kati.Screens.OnboardingFa` for `:fa` and `Kati.Screens.PickSections` otherwise, and 135's branch
  resolves to `Kati.Screens.RestoreFa`. Two lines leave `@no_route`. 137 also cannot finish today:
  its `handle_info/2` answers `section_*`, `restore_backup` and `back_to_welcome` and nothing else
  (`lib/kati/screens/onboarding_fa.ex:121-135`), so it never calls `complete!/0` — wiring it without
  a commit tag is how a Persian user gets a first run with no exit.
* **Resume.** 134's headline rule is *"Killed after 26 → resumes at 26. Kati reopens at the last
  completed step with earlier answers intact."* Nothing implements it: `Mob.State` holds one boolean
  (`lib/kati/onboarding.ex:34`) and `first_screen/0` answers `LanguagePick` or the shell root with
  nothing in between (`:79-81`). Add `Kati.Onboarding.step/0` and `advance!/1` over the same store.
  The answers resume for free once Phase 5 and this phase store them instead of holding them in a
  socket.
* **Loudness.** Screen 38's option cards render `selected?` straight from
  `Kati.Onboarding.Sample.telling/0` (`lib/kati/onboarding/sample.ex:45-70`) and carry no `on_tap`
  (`lib/kati/screens/onboarding.ex:243`, `:272`); the screen's own moduledoc names the fix — *"a
  stored delivery style (`:quiet | :push | :digest`, plus the digest's weekday and hour) on
  `Mob.State` in the shape of `Kati.Theme.Mode`, read by `Kati.Notifications.Scheduler`"*
  (`:47-52`). Add `lib/kati/notifications/delivery_style.ex` with `choice/0`, `put/1` and
  `default/0` of `:quiet`. The screen that turns the answer into a permission is already built and
  stranded: `Kati.Screens.LoudnessPrompt` (136) draws a pre-prompt purpose card and raises the real
  dialog — `Mob.Permissions.request(socket, :notifications)` then
  `Kati.Permissions.note_asked(:notifications)` (`lib/kati/screens/loudness_prompt.ex:409-413`) —
  and 134 draws exactly the edge that gives it a door: *"Quietly is itself the quiet choice — no OS
  prompt → 38·4 First title."* So `:quiet` pushes step 5 directly, `:push`/`:digest` push 136, whose
  Continue raises the dialog and whose `:back_to_sections` handler (`:395`) is repointed at step 5.
  `:exact_alarms` — the third capability in `Kati.Permissions.runtime_capabilities/0`
  (`lib/kati/permissions.ex:59`) — is not asked during the run: it has no drawn board in the chain
  and a digest at 18:00 on Sundays does not need it.
* **The restore branch is a dead end, and the working restore is one screen over.** 135's three
  accept controls — `:pick_file`, `:scan_qr`, `:restore_everything` — all push `Kati.Screens.Import`
  (`lib/kati/screens/restore_first_run.ex:174-176`), which has **no** `handle_info/2` and **no**
  `handle_tap/2` at all and is `use Kati.Screens.Pushed, back: "Settings"`
  (`lib/kati/screens/import.ex:54`). So a first-run user who chooses restore lands on a screen with
  one exit, a back pill naming a screen they have never opened, and no way to finish the run —
  `complete!/0` has exactly one call site in `lib/` (`lib/kati/screens/onboarding.ex:527`), so the
  next launch starts at 53 again. 135's own moduledoc admits *"No backup is actually inspected or
  written by any tap on this screen"* (`:107-114`). Meanwhile screen 129 is complete: the system
  picker via `Kati.Native.Files.pick/2` (`lib/kati/screens/restore.ex:1296-1297`), `{:files, :picked, items}`
  decoded at `:1540` and handed to `Kati.Backup.Transport.accept/1` (`:1563-1564`), which refuses
  anything that is not a `.katibackup` (`lib/kati/backup/transport.ex:154-196`), a real `<TextField>`
  passphrase (`:1184`, `{:change, …}` at `:1519`, stored by `typed/3` at `:1545`), and **Restore
  now** calling `Kati.Backup.restore_file/2` (`:1354`). 135 stops pushing 37 and calls 129's
  functions directly. **The mode is `:into_empty`, not `:replace`** — it is what the engine
  documents for this device (*"every backed-up table must be empty"*,
  `lib/kati/backup/restore.ex:9`), what 129 draws (`lib/kati/screens/restore.ex:784-785`), already
  `blank/0`'s resting value (`:316`), and what 135's own outcome card promises in words — *"no
  merge, no replace, nothing to lose"* (`lib/kati/screens/restore_first_run.ex:36-40`). `:replace`
  cannot be used here at all without work nobody has scoped: `Kati.Backup.Restore` refuses it
  without a `:safety_sink` (`lib/kati/backup/restore.ex:62`, `:121`) and `Kati.Backup` only supplies
  one when handed a `:safety_export_path` (`lib/kati/backup.ex:246-249`) — a safety export of a
  device with nothing on it. On `{:ok, report}`: `Kati.Sections.put/1` from what the restored
  database contains (134's *"Sections come from the file"*), `complete!/0`, then
  `Mob.Socket.reset_to(socket, Kati.Onboarding.first_screen())` — the reset, not a push, for the
  reason `lib/kati/screens/onboarding.ex:519-522` gives. 134 offers 135 from **two** places, and
  only one exists in code (`lib/kati/screens/pick_sections.ex:134-135`); step 2 draws one control
  and it is **Get started** (`lib/kati/screens/onboarding.ex:99-136`). The Persian board already
  carries the missing link and is the shape to copy (`lib/kati/screens/onboarding_fa.ex:126-127`,
  drawn at `:402-426`). `:scan_qr` has no scanner — the barcode dependency was deliberately removed
  (`MobBridge.kt:1019-1029`) — and must say so rather than pretend. Screen 37 stays out of the first
  run entirely until a CSV reader exists.
* **The first title, and the decision "no dummy data" forces.** Step 5 offers four invented posters
  — *The Long Hollow*, *Ashfall*, *Marram*, *Nightbirds* (`lib/kati/onboarding/sample.ex:78-83`) —
  and 38's moduledoc already concedes they cannot come from the cache, because the cache is empty
  and that is the point of the step (`lib/kati/screens/onboarding.ex:43-46`). With Phase 6 landed,
  step 5 is a `<TextField>` and **Finish setup** writes one `CachedTitle` + one `TrackedTitle` with
  `status: :watching`; with Phase 7 landed it can be a real search. **Skip remains a first-class
  ending** — 134 routes it explicitly, *"38·4 → Skip — I'll add things later → 139 Empty Home"* —
  storing nothing and completing the run.
* **Day one is empty and every root says so in its own words.** After this phase a device that has
  just finished onboarding holds: rows in `calendars` and `events` if the permission was granted, at
  most one `CachedTitle` + `TrackedTitle`, and five keys in `Mob.State` (locale, completion flag,
  sections, delivery style, `permissions_asked`). The fallbacks that hide that are deleted across
  Phases 1, 5 and 6, plus two that belong here: Home's services card reads
  `Kati.Settings.Sample.watching/0` (`lib/kati/screens/home.ex:455-470`) and must draw its own
  nothing, with `:open_services` pushing `Kati.Screens.MyServicesEmpty` (93) rather than
  `Kati.Screens.MyServices` (`lib/kati/screens/home.ex:699-700`) on a device with no services; and a
  device with **zero sections** opens on `Kati.Screens.HomeEmpty` (139). That choice cannot live in
  `Kati.Screens.Home.load/1`, which only assigns (`lib/kati/screens/home.ex:33`) and cannot answer
  with a different module. It belongs in `Kati.Onboarding.shell_root/1`
  (`lib/kati/onboarding.ex:85-86`), which `Kati.App.on_start/0` registers as the stack root
  (`lib/kati/app.ex:49`) — **and the dock must ask the same function**, because a dock tap does
  `reset_to(Kati.Shell.screen_for(target))` (`lib/kati/screens/root.ex:223`) and `screen_for(:home)`
  is the literal `Kati.Screens.Home` (`lib/kati/shell.ex:51,59`), so without that change one
  round-trip through Calendar lands the user back on the full drawn Home.
  `use Kati.Screens.Root, root: :home` (`lib/kati/screens/home_empty.ex:127`) makes the dock
  *highlight* correct, which is not the same thing.
* **What "asked for" means, precisely.** At the end of the run `Kati.Permissions.asked/0`
  (`lib/kati/permissions.ex:92-97`) contains `:calendar` always, exactly once, at 26's Continue;
  `:notifications` if and only if step 4's answer was `:push` or `:digest`; and `:exact_alarms`
  never. Every `Mob.Permissions.request/2` in the codebase is immediately followed by
  `Kati.Permissions.note_asked/1`, because Android reports *never asked* and *permanently refused*
  identically and Kati's own record is the only disambiguator (`lib/kati/permissions.ex:26-33,128-131`).
* **`Kati.Seeds` stays unwired**, for the reasons in Phase 11.

**Two device constraints these rows are held to.** `POST_NOTIFICATIONS` exists only on API 33+;
below that the bridge answers `granted` immediately and raises no dialog (`MobBridge.kt:1002-1004`),
so every loudness row runs on API 33+ or asserts nothing. And a genuinely fresh first run needs
Android's own permission flags reset, which `KatiRule`'s file wipe does not do: revoke with
`pm revoke` per capability, and reserve `pm clear` for the case where the whole grant history must
go (safe on the e2e build, §3).

**Acceptance.**

| № | Assertion on a device |
|---|---|
| **P8.1** | Wiped install. Tap the primary control on each screen in turn: the sequence is 53 → 38·1 → 26 → 38·3 → 38·4 → Home, and after **Get started** on 38·1 the app is on 26, not on Home. Each of the five meters shows five segments, with 1, 2, 3, 4 and 5 filled respectively. |
| **P8.2** | Wiped install. On 53 pick **فارسی**, Continue. Every screen to the end of the run is Persian and right-to-left — in particular step 3 is `screen:onboarding_fa`, not the English 26 — and the restore branch opens `Kati.Screens.RestoreFa`. Re-run in English and assert the mirror image. |
| **P8.3** | API 33+. Run A: wiped install, pick **Quietly**, finish — no system permission dialog ever appeared (`dumpsys package` shows POST_NOTIFICATIONS still ungranted) and the run completed. Run B: wiped install, pick **Notify me** — screen 136 appears, Continue raises the OS dialog, Allow, and the run continues to step 5. `mob_state.dets` holds the chosen style in both runs. |
| **P8.4** | Wiped install. Step 2 carries a *Already have a Kati backup? Restore it* link that opens 135, and 26's *Restore from a backup instead* opens the same screen. |
| **P8.5** | With a known-good `.katibackup` on the device: wiped install, restore at 26, pick the file through the system picker, restore. The app lands on Home — not on 37 with a `‹ Settings` pill — Library shows titles from the file, and force-stop + relaunch opens Home rather than screen 53, proving `complete!/0` ran. |
| **P8.6** | With a truncated `.katibackup`: same walk. A refusal is drawn naming the file, `db().count("tracked_titles")` is still 0, and the user can still continue to step 4. |
| **P8.7** | Wiped install. At step 5 type a title, **Finish setup**. It appears on the Library shelf and `db()` holds exactly one `tracked_titles` row with that title. Repeat taking **Skip**: `tracked_titles` is empty and Library draws its invitation. |
| **P8.8** | Wiped install, walk to 26, pick sections, Continue, Allow, then force-stop before step 4 finishes. Relaunch: the app opens on step 4, not on 53, and the sections picked are still picked. |
| **P8.9** | Wiped install, take every skip. On Home, Calendar, Library and Stats, `assertNoText` for `The Long Hollow`, `Ashfall`, `Marram`, `Nightbirds`, `Dinner 19:30`, `2 left today` and `hollow` — the literals at `lib/kati/onboarding/sample.ex:79-82`, `lib/kati/screens/home.ex:484,486` and `lib/kati/screens/search/sample.ex:25`. |
| **P8.10** | Finish onboarding, turn every section off on screen 24, force-stop, relaunch. Home is 139 — `grid_view` tile, *Choose sections* pill, *or restore a backup* link — with the dock drawn. Then tap **Calendar** in the dock and **Home** again: still 139. This is the assertion that catches the `Kati.Shell.screen_for/1` half being skipped. |

---

### Phase 9 — Search

Screen 19 is one of six the repo already classifies as unmovable, and its stated reason is the true
one: *"**19 Search** — no index. Nothing anywhere matches a title, an episode, an event or a review
by substring"* (`test/kati/screen_sample_only_test.exs:20-21`). Half of that is now false — the
field can be a field (Phase 2) — and half is still exactly right: **no read action anywhere in
`lib/` matches by substring.** A grep of `lib/kati/*/*.ex` for `contains(`, `ilike` or `like(`
returns two hits, both inside `MishkaCombobox`'s layout helper
(`lib/kati/components/mishka_combobox.ex:295,316`). Every existing read is an equality filter on an
id, a kind or a status.

**Delivers.** Typing a word and finding your own rows.

**Touches.**

* **The field.** `lib/kati/screens/search.ex:219-251` draws a 52pt pill containing
  `Kati.UI.symbol("search")`, a `<Text>` bound to `results.query`, and the 2×19 accent `<Box>`
  (`:236-244`). It becomes the `<TextField>` screen 128 already ships, with three prop differences:
  `return_key="search"` (ImeAction.Search, `MobBridge.kt:3509`), no `secure` — backup's `secure={true}`
  is what forces `KeyboardType.Password` at `:3496-3497` and must not be copied — and an `on_submit`,
  which backup's field does not set. The clear glyph already drawn at `search.ex:246` gets
  `on_tap={{self(), :clear_query}}`; the caret `<Box>` is deleted, because Compose draws a real one.
* **The state machine already exists as a contract with no executor.** `Kati.Search` specifies every
  number: `long_enough?/1` — 2 characters, or 1 for Arabic, Persian and CJK, measured on the query
  rather than the app locale (`lib/kati/search.ex:128`, `minimum/1` at `:116`); `debounce_ms/0` —
  180 (`:98`), implemented as `Process.send_after(self(), {:run_query, value}, 180)` with the
  previous timer cancelled on each keystroke, which is exactly what screen 87 draws as six cells over
  an unfired bar (`lib/kati/screens/search_typing.ex:495-504`); `normalise/1` (`:152`) — ي→ی, ك→ک,
  ZWNJ folded, harakat stripped, digits folded through `Kati.I18n.Digits.fold/1`, applied to **both**
  query and candidate, which is the only way `٤` finds `4`; `tier/3` (`:173`) and `rank/1` (`:197`) —
  four tiers, ties broken by recency, `nil` recency last; `rows_per_group/0` (`:102`) — 3 before a
  *See all* row.
* **`Kati.Search.Query`**, new: `run(query, scope \\ :all) :: %{scope => {count, [row]}}`, one
  counted read per scope — seven, which is what `length(Kati.Search.scopes())` promises and screen 87
  prints (`lib/kati/screens/search_typing.ex:32`) — each an `Ash.Query.filter` using an `AshSqlite`
  `fragment("... LIKE ?")` over the normalised column, because AshSqlite has no built-in `contains`.
  The columns all exist: `:screen` over `CachedTitle.title`, `title_original`, `overview`, `genres`
  (`lib/kati/media/cached_title.ex:67-73`) and `CachedEpisode.title`, `overview`
  (`lib/kati/media/cached_episode.ex:138-139`); `:calendar` over `Kati.Calendars.Event.summary`,
  `location`, `description` (`lib/kati/calendars/event.ex:88-90`); `:meals` over `Recipe.title`,
  `method`, `note` (`lib/kati/meals/recipe.ex:71,80,100`); `:money` over `Service.name`
  (`lib/kati/services/service.ex:43`); `:books` and `:music` over their own, deferred with their
  domains. The `:notes` scope is not a resource — it is `Watch.review` (`lib/kati/media/watch.ex:81`)
  plus `Books.Note.body` plus `Album.note` plus `Recipe.note`, every cream card in the app, which is
  what `lib/kati/search.ex:51` says it is. Implement it as a union across those four, not a new table.
* **Two declared fields have no column to search.** `@scopes` names *cast* and *alt titles* under
  `:screen`, and `lib/kati/media/cached_title.ex:67-73` has neither, nor does any table in
  `lib/kati/media.ex:32-38`. Either drop them from `@scopes` or add the columns; do not ship a scope
  list naming two fields the query cannot reach. (`:books`' *series* does exist — `series_name` at
  `lib/kati/books/book.ex:118`.) Screen 88's one exclusion — *never invitee names* — is free rather
  than enforced: `Kati.Calendars.Event` has no attendee column at all (`:79-105`); say so in the
  module rather than writing a filter against a field that does not exist. And `:money` at
  `lib/kati/search.ex:50` says *service name*, not expense text — adding `Money.Expense.description`
  widens the contract, so widen `@scopes` in the same commit rather than silently searching a field
  screen 88 does not list.
* **The chips, and a contradiction to settle.** Screen 19 draws four chips with the counts `6/3/2/1`
  typed as literals (`lib/kati/screens/search/sample.ex:53-56`), and the sample's own doc admits that
  deriving them from the drawn rows yields 5 and 2 (`:39-42`). `Kati.Search.chip_labels/0`
  (`lib/kati/search.ex:81`) returns **eight**, and screens 86, 87 and 89 already use the eight
  (`lib/kati/screens/search_result_states.ex:146`). The contract wins. 19's chip row becomes
  `chip_labels/0` inside the horizontal `<Scroll>` screen 03 already uses for the same overflow
  problem (`lib/kati/screens/library.ex:517-529`), and each count is that scope's **whole matched
  set**, not the ≤3 rows drawn, which is what the chip has always claimed to be. On open, before a
  query, the chips carry no counts at all — `Kati.Search.Sample.counts_note/0`'s stated rule, that
  eight zeroes on open would read as an empty app (`lib/kati/search/sample.ex:30-37`).
* **The recent shelf.** Query history is stored nowhere; `recent_kept/0` says eight
  (`lib/kati/search.ex:106`) and the Sample types five (`lib/kati/search/sample.ex:13`). This is a
  device preference, not user content, and it must not travel in a backup: add `Kati.Search.Recent`
  over `Mob.State`, shaped like `Kati.Services.rules/0` and `toggle_rule/1`
  (`lib/kati/services.ex:115-127`) — `recent/0` reads, `record/1` prepends, dedupes on the
  *normalised* form and truncates. Persian queries are stored as typed and never translated
  (`lib/kati/search/sample.ex:4-8`). Tapping a recent pill fills the field and re-runs; today it
  deliberately does not (`lib/kati/screens/search.ex:167-169`) and the moduledoc argues the case
  honestly — *"until an index exists the screen cannot answer the new question — so it does not
  pretend to have been asked"* (`:34-37`). Once the index exists, that paragraph is the thing to
  delete.
* Both search Samples go: `lib/kati/screens/search/sample.ex` (whose own moduledoc asks — *"When the
  index lands, delete this"*, `:16-17`) and `lib/kati/search/sample.ex`.

**Acceptance.**

| № | Assertion on a device |
|---|---|
| **P9.1** | Navigate to search, `type("<the field's tag>", "hollow")`. The field's semantics text is `hollow`, the IME action is Search, and no node with the literal drawn caret remains. |
| **P9.2** | With a title, a device-imported event and a `Watch` review all containing the same word, type it and wait past the debounce. The `:screen`, `:calendar` and `:notes` groups are all non-empty and each row's id matches a row read from `db()`. |
| **P9.3** | On open, each of `chip_labels/0`'s eight chips shows a bare label with no digit. After typing, each chip's text ends in a number equal to that scope's **whole** matched-set count from `db()`, and tapping the Calendar chip leaves only calendar rows on screen. |
| **P9.4** | Run two searches, force-stop, relaunch, reopen search: both are listed newest first, capped at `Kati.Search.recent_kept/0`. Tapping one refills the field and re-runs it. |
| **P9.5** | On screen 86, tap a suggestion pill. The app is on screen 19 **and** the field carries the pill's text. |
| **P9.6** | After the journeys above, `assertNoText` for every literal in `lib/kati/screens/search/sample.ex` and `lib/kati/search/sample.ex` — in particular no result row appears for a query that matches nothing in `db()`. |

---

### Phase 10 — Every screen in its own place

**A correction to the audit first, because the shape of this phase depends on it.** Re-running the
exact push graph `test/kati/app_reachability_test.exs:258-268` builds, and additionally asking the
owner's actual question — *can I get there without going to Settings?* — gives:

| Bucket | Count |
|---|---:|
| Reachable from a dock root without opening Settings | 67 |
| Reachable from a dock root, but only through Settings | 34 |
| Reachable only inside the first-run chain | 4 |
| No in-app route at all — Gallery only | 47 |
| **Total** | **152** |

The 67 and the 47 agree with the audit exactly. The middle two do not, and the difference is not
about the graph: the audit's `Route` column names the first-run chain for any screen whose shortest
path starts there, without checking for a second door. There is one. Settings draws a **Language**
row (`lib/kati/settings/sample.ex:49`) mapping to `Kati.Screens.Language`
(`lib/kati/screens/settings.ex:655`), and screen 54's `choose/2` writes the locale and pushes the
Persian shell root (`lib/kati/screens/language.ex:525-533`, `shell_root(:fa)` at `:542`). So 18
Persian mirrors plus `Kati.Screens.Import` move from the first-run bucket into the Settings bucket:
23 − 19 = 4, and 34 = 15 + 19. **The honest headline is 51, not 70** — after a completed English
first run, 51 of 152 screens have no door but the gallery and 34 more need a trip to Settings. Better
than the audit says, and still unacceptable.

The four that really are first-run only are 53, 26, 38 and 135, and that is correct: a first run is
by definition a place you cannot return to. `Kati.Onboarding.first_screen/0` returns the shell root
once the flag is set (`lib/kati/onboarding.ex:79-81`) and `reset!/0` says in its own `@doc` that
*"nothing in the app calls it"* (`:60-61`) — it should stay uncalled by production code.

**Delivers.** 47 stranded screens → 0, and no developer gallery on a user's phone.

**Touches.**

**(a) Six screens, a control and a clause each — no artboard needed.**

| № | Module | Belongs on | What stands in the way |
|---|---|---|---|
| 150 | `AutoDetectMusic` | a mode segment at the top of 36 | Unwired tap only. `Kati.Screens.AutoDetect.handle_tap(:open_music, …)` already pushes it (`lib/kati/screens/auto_detect.ex:454-455`) and 150 draws the control itself (`Segmented.plain(…)`, `lib/kati/screens/auto_detect_music.ex:146`, options at `:165`). One `Segmented.plain/2` line in 36's header. |
| 145 | `ShelfFilters` | the header of 03, 20, 21 | Missing control on the parent. Board 145 shows no disc; board 146 does. Library already carries an overflow menu (`lib/kati/screens/library.ex:337-340`) — one more `Kati.UI.Menu.item/3` there, and a first menu on 20 and 21. Its Apply returns the filter state to the shelf. |
| 149 | `DropSheet` | a *Drop* action on 04, 08, 66, 74 | Missing control on the parent. Series (`lib/kati/screens/series.ex:686-693`) and Film (`lib/kati/screens/film.ex:573-576`) already have `⋯` menus with room; Book and Album detail have no menu at all and need their first. |
| 153 | `NumberingScheme` | a row on 35 | Missing control **and no handler at all** — `lib/kati/screens/series_settings.ex:100` is `use Kati.Screens.Pushed` and the file defines no `handle_tap/2` in 329 lines. |
| 151 | `NotificationAccess` | a special-access row on 150 | Second-order plus one clause: board 150 draws the row, but `lib/kati/screens/auto_detect_music.ex` answers only `:tv` and `:music` (`:578`, `:588`) and nothing pushes 151. **Caveat:** its moduledoc calls it *"a reference sheet, in the same sense screen 27 is"* (`lib/kati/screens/notification_access.ex:23-24`) and it draws four permission states stacked, because `Kati.Permissions` has no `:notification_access` status. Wire it **and** collapse it to the phone's actual state, or leave it to (d). |
| 132 | `RestoreFa` | a داده‌ها row on 62, and step 3 of the Persian first run | Missing destination key: `Kati.Screens.SettingsFa`'s glyph-keyed map has `"upload" => Kati.Screens.Backup` and no restore entry (`lib/kati/screens/settings_fa.ex:510-519`). Its other parent, `OnboardingFa`, already pushes it (`lib/kati/screens/onboarding_fa.ex:127`) and is unstranded by Phase 8. |

The load-bearing claim here is that adding a menu item is allowed. `@no_route`'s own comment says
the opposite — *"Adding it anyway would mean inventing a control on a board that does not have one,
which is the one thing the design pipeline in this repo does not allow"*
(`test/kati/app_reachability_test.exs:124-133`, the sentence at `:128-130`) — and that is not the
rule this repo follows. It has been overruled twice, deliberately and well: `Kati.UI.Menu` is itself
an invented control (*"Five of the 62 drawings put a `more_horiz` or a `density_medium` in a header
and none of them draws what it opens. Seven screens were stranded behind that gap… So the menu is
new, and it is built out of the app's own parts rather than invented"*, `lib/kati/ui/menu.ex:7-13`),
and it took `@no_route` from twelve to five (`test/kati/app_reachability_test.exs:37-40`); and the
*Year cards* settings row (*"the design names the parent and never redrew 24 to add the row… The
screen is drawn and finished; only the way in was missing"*, `lib/kati/settings/sample.ex:217-222`).
The real rule is: **a new control must be built from the app's own parts, must land where the
child's own board says its parent is, and must record why.** All six satisfy it.

**(b) Two screens blocked on a capability the bridge does not have.** 144 belongs on a long press on
an episode row in 04; 146 on a long press on a poster tile in 03, and 146's own board says "long
press" twice. `Mob.Renderer` serialises `on_long_press` (`deps/mob/lib/mob/renderer.ex:356-357`) but
`MobBridge.kt` reads only `on_tap` and wraps it in `Modifier.clickable` (`:2911`, `:2923-2925`); a
grep of `android/app/src/main/` for `on_long_press` or `combinedClickable` returns nothing. One
`KATI-BEGIN` fence swaps `clickable` for `combinedClickable` with `onLongClick`. `MobBridge.kt`
already carries 49 such fences and each owes a row in `native/LEDGER.md`, which
`test/kati/native_ledger_test.exs` enforces in both directions (`native/LEDGER.md:3-5`) — the ledger
row is part of the deliverable. Wiring these two to a tap instead would be inventing a different
interaction, not a control. `@no_route` also notes that 03 and 04 would then use the same gesture
for two meanings (`test/kati/app_reachability_test.exs:146-149`) — one decision, taken once, on both
boards.

**(c) Two blocked on first-run work**: 136 and 137, both delivered by Phase 8.

**(d) Thirty-three modules that are not screens.** 22 states catalogues (27, 67, 71, 75, 78, 81, 84,
87, 89, 95, 96, 99, 101, 107, 110, 113, 123, 130, 142, 143, 148, 152), 4 dark colourways (28, 68,
102, 131), 4 type-size boards (91, 133, 138, 147) and 3 empty-state boards (105, 117, 139). Their
`@no_route` reasons are correct — *"a picture of five situations rather than a situation the app can
be in"* (`test/kati/app_reachability_test.exs:47-49`) — and the conclusion the inventory stops short
of is the operative one: **a picture of a screen should not be a screen.** Each compiles a `mount/3`
and a `render/1`, ships in the APK, is swept by `Kati.ScreenRenderSweepTest` and
`Kati.ScreenEmptyDatabaseTest`, and its existence is precisely what lets a states board pass for the
state. The dark four are already redundant by their own stated condition: `Kati.Screens.HomeDark`'s
moduledoc says *"When dark becomes a real mode, this dock is what `Kati.Shell` should grow — and
this module should disappear into it"* (`lib/kati/screens/home_dark.ex:28-30`), and that condition
has been met twice over — `Kati.Theme.Mode.resolve/0` decides light vs dark
(`lib/kati/theme/mode.ex:8-15`), `Kati.Screens.Root` installs the resolved theme at every mount
(`lib/kati/screens/root.ex:118-121`), and the shell and dock resolve their fills from it
(`lib/kati/shell.ex:94,120,155,162,195-196`). The prescription for all 33 is one deletion with a
substitute: delete the module and its Sample; move `test/design/screens/NN.html` to
`test/design/reference/`, which `docs/DESIGN-ASSETS.md:14` already defines as *"drawings that are not
screens"*, decrementing the `152` at `test/kati/screen_design_literal_test.exs:201-202`; and replace
the module with a **device** assertion that drives the real screen into that state and compares it
against the moved board. That is strictly stronger than rendering a second module that draws five
states at once, and it is the only version of the claim that survives the rule in §2. The mechanisms
exist today: `adb shell cmd uimode night yes`, `adb shell settings put system font_scale 2.35`, an
empty database, airplane mode.

**(e) Four pictures of the world outside the app** — 29 `Lock`, 63 `MarkIos`, 64 `MarkAndroid`,
65 `LaunchScreen`. Their reasons hold (*"Nothing in an app can navigate to the lock screen"*,
`test/kati/app_reachability_test.exs:90-92`; the real launch frame is `android:windowBackground` →
`@drawable/splash`, `android/app/src/main/res/values/styles.xml:4` and `values-v31/styles.xml:13`;
there is no shipping iOS build — both static NIFs are `archs: [:android]`, `mob.exs:28-31`). Same
treatment: move the boards, delete the modules. Screen 29's *content* — Kati's notification on a
lock screen — is a real claim about the app and is proven by arming a notification and reading the
shade, not by a module that draws a photograph of one.

**This partition supersedes the removal order's Wave 4, and the arithmetic changes.** Wave 4 assumed
six of the 47 would be given routes — 29, 144, 145, 146, 148, 149 — and that exactly two Sample
modules would fall with the deletions. The partition above routes ten (150, 145, 149, 153, 151, 132,
144, 146, 136, 137) and deletes 37, including 29, 148 and 152. So **five** Sample modules fall out
with the deleted screens rather than two: `Kati.Settings.StatesSample`,
`Kati.Screens.HomeDark.Sample`, `Kati.Screens.Lock.Sample` (read by 29 and 64, both deleted),
`Kati.Settings.DropStatesSample` (148 only) and `Kati.Media.AnimeSample` (152 only). Every other
Sample the deleted screens read is also read by a screen that is staying, so this is worth doing for
requirement 3 and is not a shortcut through requirement 1.

**(f) The Persian shell is a mode, not a set of orphans — and no push may cross shells.** If a user
chooses فارسی, `first_screen/0` returns `Kati.Screens.HomeFa` (`lib/kati/onboarding.ex:79-86`) and
`Kati.Screens.Root` re-asserts it on every launch through `:kati_locale_root` — *"Someone who chose
فارسی gets screen 55 on every launch, not only on the one where they chose it"*
(`lib/kati/screens/root.ex:179-185`, message sent at `:160`) — and from `HomeFa` the Persian dock
reaches twenty mirrors (`lib/kati/screens/fa.ex:107-112`). The way back exists too
(`lib/kati/screens/settings_fa.ex:913-918`). What leaks is that **fifteen** pushes out of
`lib/kati/screens/*_fa.ex` and `fa.ex` land on English screens: `library_fa.ex:787` and
`schedule_fa.ex:658` (both → `Search`, and both have a mirror, `SearchFa`, so both are one-line
swaps); `home_fa.ex:731` → `Inbox`; `settings_fa.ex:511` → `Backup` and `:512` → `Sync`;
`fa.ex:302` → `AddTitle`; `album_detail_fa.ex:886,895,898` → `LogListen`, `Rating`, `Lists`;
`book_detail_fa.ex:646` → `Rating`; `artist_detail_fa.ex:815` and `money_fa.ex:1052` →
`ReleaseWatcher`; `goals_fa.ex:912` → `NewGoal`; `health_fa.ex:1033` → `LogWeight`; and
`settings_fa.ex:918` → `Language`, which is **deliberate** and permanent, the only way out of
Persian. So the deliverable is two swaps, twelve recorded exemptions with a named owner, and one
permanent exemption — not fifteen fixes. Screen 54 has no Persian mirror, which is why
`lib/kati/screens/language.ex:43-52` argues at length for pushing rather than resetting; once it
does, 54 should `reset_to/2` the chosen shell root, which is what a language change means.

**(g) Routing must stop being a property of sample data.** Settings' whole navigation table
(`@destinations`, `lib/kati/screens/settings.ex:633-665`) is keyed by each row's **title string**,
and 17 of its 20 keys exist only because `Kati.Settings.Sample` prints them. Deleting a Sample row
silently deletes a route and no test would say so. The drift has already happened in the other
direction: three of the 20 keys are dead — `"Account"`, `"Accessibility"` and `"States"` (`:653`,
`:654`, `:657`) are titles no row draws, so `"go_Account"` is a tag nothing can send. (Screens 40
and 41 are still reached, by `"This device"` at `:652` and `"Text size"` at `:656`.) The row list
moves into a real `Kati.Settings.Menu` beside `Kati.Screens.Settings.destinations/0`, checked
against each other at compile time — a check whose first act is to delete those three lines. Also,
the gallery row is in Settings' **About** group, not its Data group
(`lib/kati/settings/sample.ex:201,233-241`).

**(h) `Kati.Screens.Gallery`: delete the screen, keep the registry.** Not "move it behind a debug
flag". `test/kati/app_reachability_test.exs:9-13` states the defect precisely: *"a screen wired to
nothing looks finished when you open it from the gallery, and half the app was in that state without
anyone being able to say which half."* As long as a user-visible row opens all 155 pages, "is this
screen wired?" has a wrong answer available to anyone who checks — including the owner, who checked
and got it. A flag would keep the module, the 155 tappable rows, the habit, and a real hazard:
`rows/0` builds one row per registry entry eagerly (`lib/kati/screens/gallery.ex:347-359`), each
carrying one `on_tap` (`:431`). Measured with `Kati.TapHandleBudgetTest`'s own `tap_handles/1`
(`test/kati/tap_handle_budget_test.exs:38-43`) against `ScreenSweep.render(Kati.Screens.Gallery)`:
**156 tap handles in one tree**, against a maximum of **27** across all 152 measured screens. That is
87% of the 180-handle budget every other screen is held to and 61% of the 256 hard cap above which
`nif_register_tap` returns `badarg` and kills the screen process
(`test/kati/tap_handle_budget_test.exs:5-16,22-26`). And it is unmeasured, because the budget test
iterates `Kati.Screens.Gallery.screens()`, which does not contain the gallery (`:47`). The one
developer surface in the app is the one screen the safety test cannot see.

Deletion is a split, because `@screens` (`lib/kati/screens/gallery.ex:29-196`) is also the app's
number → label → module → drawing registry, read by four suites at seven call sites
(`test/kati/app_reachability_test.exs:186,210,222`; `test/kati/screen_design_literal_test.exs:99,235`;
`test/kati/screen_empty_database_test.exs:590,601`; `test/kati/tap_handle_budget_test.exs:47`), with
four further places naming the module itself (`app_reachability_test.exs:262`,
`screen_design_literal_test.exs:127` and `:236`, `screen_empty_database_test.exs:576`).
**Phase 10a, now:** extract `@screens` and `@undrawn` into `Kati.Screens.Registry`, a plain module
with no `mount/3` and no `render/1` so `Kati.ScreenSweep.screen?/1`
(`test/support/screen_sweep.exs:48-53`) excludes it from every sweep; point the seven reads at it;
delete the *"Every screen"* row from `Kati.Settings.Sample.about/0` and the
`"Every screen" => Kati.Screens.Gallery` entry at `lib/kati/screens/settings.ex:664`; update
`test/kati/notifications_inbox_test.exs:243-245` to assert the row's **absence**. Keep the module
compiling but unreachable from any tap, opened during the wiring work by
`Mob.Test.navigate(node, Kati.Screens.Gallery)` (`deps/mob/lib/mob/test.ex:258`) over the dist
connection — a strictly better debug flag than a flag, available to a developer with a laptop and to
nobody else. This has no dependency beyond Phase 0 and should land early. **Phase 10b, when the rest
of this phase is done:** delete `lib/kati/screens/gallery.ex` and the 37 companion modules, and the
four by-name references with them. The reachability test then loses its `@no_route` list entirely
and becomes what it should always have been: every drawn screen is reachable from a dock root, with
an empty exemption list.

**Acceptance.**

| № | Assertion on a device |
|---|---|
| **P10.1** | Six journeys, each from a cold launch on a phone that has finished onboarding, reaching 150, 145, 149, 153, 151 and 132 by taps alone. E.g. Library → `⋯` → *Filters* → `awaitScreen("shelf_filters")`. |
| **P10.2** | With the `combinedClickable` fence deployed: a long press on an episode row of 04 lands on `screen:rate_episode`, and on a poster tile of 03 lands on `screen:shelf_selection`. A short tap at the same coordinates still opens the season/title — asserted in the same test, so the two meanings cannot collide silently. |
| **P10.3** | For each of the 37 deleted modules: put the device in the state through the OS (`cmd uimode night yes`; `settings put system font_scale 2.35`; a wiped database for the empties), **then relaunch** — Kati snapshots the theme at mount and does not subscribe to the OS's `color_scheme_changed` event (`lib/kati/theme/mode.ex:40-50`), so a screen already on top will not repaint and the row would otherwise pass against an unchanged light frame. Open the *real* screen by tapping to it and assert every literal from the moved `test/design/reference/NN.html`. Module absence is asserted on the phone: `KatiRule.beams()` finds no `Elixir.Kati.Screens.HomeDark.beam` in the extracted runtime. |
| **P10.4** | On a device with a completed first run: open Settings by tapping, scroll to the end of About, and at every scroll position `assertNoText("Every screen")`. `screen:gallery` is never observed at any point in P10.5's walk, and after 10b `KatiRule.beams()` finds no gallery beam. |
| **P10.5** | **The gate for requirement 3.** From a cold launch on a set-up phone, one run walks the app by tapping alone and reaches **every** module in `Kati.Screens.Registry`, asserting `screen:<name>` at each arrival. The exemption list is literally empty — (e) deletes 29/63/64/65, so the registry no longer names a screen an app cannot navigate to. Two arrivals need a long press (P10.2). The run never calls `Mob.Test.tap/2` or `Mob.Test.navigate/3`. |
| **P10.6** | Persian is a mode: complete onboarding in English; Settings → Language → فارسی lands on `screen:home_fa`; force-stop and relaunch comes up on `screen:home_fa` again; each of the four Persian dock tabs reaches 55/56/57/61; تنظیمات → زبان → English returns to `screen:home`. |
| **P10.7** | Drive every tap on every Persian screen and assert the screen after each is a module whose name ends in `Fa`, or is on the exemption list carried in the test. The row passes when the failing set **equals** the recorded set exactly — two swaps done, twelve exemptions recorded, `settings_fa.ex:918` permanent — so an exemption cannot be added silently. |
| **P10.8** | Every Settings row opens a screen: tap all 17 live destinations and assert the module at each. `"go_Account"`, `"go_Accessibility"` and `"go_States"` are gone, and a compile-time check pairs the menu against `destinations/0`. |
| **P10.9** | **The gate for requirement 2.** Wiped install; complete the first run choosing two sections; then, without reinstalling and without opening a gallery, reach one screen from each of the four dock trees and each of the 17 live Settings destinations by tapping alone. In the same run: add a title, tick an episode, log a weight. Four receipts, none read off the drawn screen — `mob_state.dets` holds the onboarding flag (`lib/kati/onboarding.ex:44,53`), and `tracked_titles`, `media_watches` and `health_readings` each hold exactly one row. Any screen only reachable by re-running onboarding fails this row. |

---

### Phase 11 — The remaining origination paths, the corpus, and the guards

Thirty of the 37 resources have no create path at all. Phases 6 and 7 cover the media ones; this
phase covers what is left inside v1, and it is where the removal order's Wave 2 finishes.

**Delivers.** Meals, services and the health domain with rows a person made; a corpus that ships;
and `Kati.Seeds` where it cannot become dummy data.

**Touches.**

* **Meals.** `Kati.Meals.Recipe` — screen 118's *Save* must `Ash.create` when there is no recipe;
  today it does `Ash.update(recipe, %{slot_name: slot})` against an `Ash.read` head
  (`lib/kati/screens/meal_edit.ex:67-71,615`), one column. `Kati.Meals.RecipeIngredient` — screen
  119's *Save* must call `Kati.Meals.Totals.write_ingredient/2` (`lib/kati/meals/totals.ex:117`);
  today `handle_info({:tap, :save}, …)` pops the screen (`lib/kati/screens/add_ingredient.ex:241`)
  and name, quantity, unit, aisle and nutrition are all discarded. `Totals`' three writers —
  `write_ingredient/2` (`:117`), `update_ingredient/2` (`:130`), `remove_ingredient/1` (`:144`) —
  have **no caller in `lib/`**; only `fresh!/1` (`:77`) is reached, from `lib/kati/meals/changes.ex:37`.
  119's five drawn fields are all on the inert list
  (`test/kati/screen_tap_sweep_test.exs:269-284`): name and quantity become `<TextField>`s (quantity
  with `keyboard="decimal"`), unit and aisle become `MishkaSelect`s. Then `Kati.Meals.Food`
  (created by 119), `MealPlan` (44/49), `MealPlanSlot` (44/46), `MealLog` (43 — ticking a meal as
  eaten, whose create action freezes nutrition through `Kati.Meals.Changes.FreezeNutrition`
  (`lib/kati/meals/changes.ex:1`, snapshot at `:37`); that freeze is the whole point of the resource
  and has never run outside a test), and `ShoppingListItem` (48). Nine Sample modules fall with
  them.
* **Services and subscriptions.** `Kati.Services.Service` has `name`, `tier`, `monthly_pence`,
  `renews_on` and `paused` with full CRUD (`lib/kati/services/service.ex:43-73`) and nothing in
  `lib/` writes one. Screen 92's `subscribed/0` falls back to `Kati.Services.Sample` when `stored/1`
  is empty (`lib/kati/screens/my_services.ex:64-69`) and `stored/1`'s `Ash.read()` at `:91` is the
  only Ash call in the file. Screen 23's `:remind` flips an assign
  (`lib/kati/screens/subscriptions.ex:610-612`) — it is the missing half of 92, whose rules are
  already real.
* **Health's medication half.** `Kati.Health.Medication` needs an *Add a medication* control on 112
  — none is drawn — and without it `Dose` cannot exist either, so 112's
  `Ash.update(dose, %{state: …})` (`lib/kati/screens/medication.ex:396`) is unreachable. `Dose` is
  derived: a dose-expansion pass over `Medication` schedules, and **no such job exists anywhere in
  `lib/`**.
* **The bundled corpus.** `Kati.Meals.BundledFood` is real reference data shipped in `priv/`
  (`lib/kati/backup/catalog.ex:27-28`) and nothing loads it. That is a first-boot seed in the honest
  sense — CC0 data, identical on every install, not a pretend user.
* **`Kati.Seeds`: neither wired nor deleted.** It writes real rows into four tables through two
  groups (`groups/0`, `lib/kati/seeds.ex:141-154`): `:calendars` writes `calendar_accounts`,
  `calendars` and `events` from `Kati.Calendar.SampleDay` and `Kati.Settings.CalendarsSample`
  (`seed_calendars/0`, `:253`), and `:media` writes `cached_titles` from `Kati.Library.Sample`
  (`seed_media/0`, `:390-410`) — so the audit's *"nothing in `lib/` ever writes a `CachedTitle`"* is
  true of production and false of the module. It must **not** be wired into `Kati.App.on_start/0`:
  its stated purpose (`lib/kati/seeds.ex:6-11`) is exactly the outcome requirement 1 forbids, and
  wiring it converts drawn dummy data into *stored* dummy data, which is strictly worse — it is
  indistinguishable from the user's own rows and it survives a restart. Three of the four tables it
  writes are in `Kati.Backup.Catalog.@entries` (`lib/kati/backup/catalog.ex:107`), so seeded rows
  would be copied into every backup the user ever makes, and `groups/0`'s own docstring sketches
  `:media_tracking` over `TrackedTitle` and `Watch` and `:meals` over `MealPlan`, `MealPlanSlot` and
  `Recipe` (`lib/kati/seeds.ex:127-132`), all of which *are* backed up. It already produces one
  visible lie: screen 80's "last reached" column shows a seed timestamp as when a provider last
  answered (`lib/kati/screens/data_sources.ex:135-152`). It must **not** be deleted either, because
  its machinery is right for two jobs that are not dummy data — an e2e precondition that would take
  fifty taps to build (`Seeds.run(only: […], force: true)`, idempotent upserts at
  `lib/kati/seeds.ex:445-488`), and the bundled corpus. So: rename the sample-bearing groups
  `:demo_calendars` and `:demo_media`, put them behind a compile-time guard so they cannot be reached
  from a release build, and add a `:bundled_foods` group that **is** wired into
  `Kati.App.on_start/0` after `Ecto.Migrator.run/4` and before `Kati.Calendars.DeviceImport.run/0` —
  the ordering `lib/kati/seeds.ex:32-36` already argues for. `@sample_tag "kati:sample"` and
  `sample_source_id/1` (`lib/kati/seeds.ex:180`) stay, because a fixture that cannot be told from
  real data is a fixture that will one day be shipped. **One trap:** `Kati.Seeds.sample_seed/1`
  (`:184-185`) is a pure string helper with five production callers —
  `lib/kati/screens/film.ex:214`, `series.ex:351`, `rating.ex:316`, `activity.ex:730`,
  `lock.ex:591` — and they are the only references to `Kati.Seeds` anywhere in `lib/`. It touches no
  database and must move to a module that survives the guard, or all five screens break the release
  build the day the guard lands.
* **The README.** `README.md:30` claims *"A calendar that is actually a calendar — CalDAV sync,
  conflicts handled"*; `:33` claims *"One search for everything"*; `:42` claims tracker import with
  named services. Two of those become true in this document; the other two do not. The README stops
  claiming what is deferred. This is the one deliverable in the document with no device acceptance,
  because it is not a device claim; it is checked at review.

**Acceptance.**

| № | Assertion on a device |
|---|---|
| **P11.1** | Open 118, add an ingredient with a typed name and a typed quantity, pick a unit and an aisle, Save. `db()` holds a `recipe_ingredients` row with exactly those values, the parent `recipes.totals_rev` equals its `ingredients_rev`, and the ingredient list on screen shows the row. |
| **P11.2** | With no recipe stored, open 118, type a title, Save. `db().count("recipes")` is 1 and the meal library lists it after a force-stop and relaunch. |
| **P11.3** | On 43, tick a meal as eaten. A `meal_logs` row exists **with its nutrition columns frozen** — non-null and equal to the recipe's values at tick time — and editing the recipe afterwards does not change them. |
| **P11.4** | On 92, mark a service subscribed with a price. A `services` row carries that `monthly_pence`; force-stop, relaunch, and screen 23's monthly total equals it rather than `Kati.Subscriptions.Sample`'s. |
| **P11.5** | On 112, add a medication with a schedule. A `medications` row exists, doses appear for it without any further tap, and ticking one writes the `health_doses` row that 112's existing update targets. |
| **P11.6** | Fresh install of a `MIX_ENV=prod` beam set. Complete onboarding without granting calendar access. `cached_titles`, `calendars` and `calendar_accounts` are all empty; no row in any table has a `source_id` starting `sample:` (`lib/kati/seeds.ex:180`) or an `account_type` of `kati:sample` (`:90`, written at `:427`); and `KatiRule.beams()` shows `Elixir.Kati.Seeds.beam` either absent or exporting no `seed_media/0`. |
| **P11.7** | Same fresh install: `db().count("bundled_foods")` is greater than zero **before any user action**, and no other table has a row. |

---

## 5. What is not in this specification, and why

**The account decision (#80).** Nothing in `lib/` creates a `Kati.Calendars.Account`:
`lib/kati/calendars/device_import.ex` writes `Calendar` and `Event` only, so an account row exists
solely inside `Kati.Seeds` (`lib/kati/seeds.ex:427`). Screen 40's account rows and the account half
of `Kati.Account.Sample` (`lib/kati/account/sample.ex:1`) therefore stay drawn until there is an
originator, and there cannot be one until it is decided whether Kati has accounts at all. Issue #80
owns that decision. I have not read it and do not restate it here; Phase 1 takes screen 40's
*permission* rows, which are a different question and already have a real reader in
`Kati.Permissions.status/1`.

**Anything that needs an artboard nobody has drawn.** Five specific gaps, named so they can be
commissioned rather than guessed at:

* **Persian steps 2, 4 and 5 of the first run.** 137 is the only Persian onboarding board; 138 is
  38's middle step at 235% text size, not a translation. A فارسی run can be given a Persian step 3
  today and cannot be given a Persian step 2, 4 or 5 without either translating
  `Kati.Onboarding.Sample` in place against the existing English boards or drawing three new ones.
  Phase 8's routing is written so either choice drops in.
* **A pre-prompt board for the calendar ask.** Phase 1 uses 26's existing blurb and its existing
  *"Continue with 2"* button (`lib/kati/screens/pick_sections.ex:347`). An explicit pre-prompt in
  136's idiom would be a sixth board and a design decision.
* **A Notes surface.** Screen 26 offers **Notes** as a section (`lib/kati/screens/pick_sections/sample.ex:22`)
  and there is no Notes screen among the 152 and no Notes resource in any of the 12 domains. Under
  requirement 1, a tile that turns on a section that does not exist is dummy data. Either Notes
  leaves 26's grid or a Notes surface ships with it.
* **An *Add a book* control on 20 and an *Add an album* on 21.** Neither board draws one, which is
  why every Books and Music write in the app is unreachable.
* **A date control for screen 111's `now` chip.** The bridge has no date node
  (`MobBridge.kt:3034-3057`) and no board draws a picker.

**The deferred domains.** Each is deferred for a stated reason, not for lack of time:

* **Books and Music** — issue #60 put them outside v1 (*"v1 ships one media domain: Screen (film and
  TV). Books and music stay greyed out"*). Their three Samples — `Kati.Books.Sample`,
  `Kati.Books.SampleFa`, `Kati.Music.Sample` — feed 24 screens between them, which is why the
  deferral is large even though the module count is not. Until #60 is revisited they must be
  **visibly greyed out rather than showing a fake shelf**, and the acceptance rows that need a second
  `Kati.Books.Book` or a `Kati.Music.Album` are skipped visibly in the harness output rather than
  quietly absent.
* **Habits** — nothing records a habit being kept. `Kati.Calendars.Override.kind` is
  `:modified | :cancelled` (`test/kati/screen_sample_only_test.exs:69-73`); no column holds the fact.
* **Discover** — no recommender exists (`test/kati/screen_sample_only_test.exs:18`).
* **Lists** — no list resource exists in any of the 12 domains; `Kati.Media` holds seven and none is
  a list (`lib/kati/media.ex:32-38`). Screen 12's `+` builds a list in a socket assign
  (`lib/kati/screens/lists.ex:373-375`). Either add a resource or take the control off.
* **Import** — `lib/kati/import/` contains exactly one file, `sample.ex`, whose moduledoc reads
  *"Stand-in import data, until a real CSV reader exists"* (`lib/kati/import/sample.ex:3`). Screen 37
  defines no `handle_info`/`handle_tap` of its own — its whole body is
  `def load(socket), do: Mob.Socket.assign(socket, :job, Sample.job())`
  (`lib/kati/screens/import.ex:64`). It stays out of the first run until the reader exists.
* **The natural-language quick add** behind screens 18 and 124 — no parser exists
  (`test/kati/screen_sample_only_test.exs:19`). Phase 2 gives 124 typed fields, which is the honest
  version of the same screen; 18 keeps its drawing until a parser is decided on.
* **CalDAV sync.** `lib/kati/sync/` is ~1500 lines of finished, well-tested code with no caller:
  `Kati.Sync.Engine.sync/3` (`lib/kati/sync/engine.ex:71`) has exactly one caller in the repo and it
  is `test/kati/sync_engine_test.exs:520`, and the engine is a *comment* in the supervision tree
  (`lib/kati/supervisor.ex:48-53`). It could not authenticate if it were called —
  `Kati.SecureStore.put/2` has zero callers in `lib/`, nothing writes `credentials_ref` on
  `Kati.Calendars.Account`, and no UI collects a server URL, a username or a password, so
  `Keystore.fetch/1` (`lib/kati/sync/adapter/caldav/transport.ex:118-126`) would return
  `{:error, :no_credentials}` on every device. Issue #52 already decided that Android's
  `CalendarContract` is the intended route to every calendar server, which makes Phase 1 the
  higher-value half of this and the CalDAV client an asset in waiting rather than a gap. Either the
  engine joins the supervision tree with a credential screen in front of it, or the README stops
  claiming CalDAV sync (Phase 11). This spec takes the second and defers the first.
* **The notification runner.** The decision layer exists — `Kati.Notifications.Scheduler`
  (`lib/kati/notifications/scheduler.ex:1`) with the pure `plan/2` (`:95`) and `reconcile/2` (`:134`),
  plus `Reconcile`, `Budget`, `QuietHours`, `Digest` and `Delivery` beside it. What is missing is a
  supervised process to run it and any writer of a `Pending` row. Phase 8 stores the delivery style
  it will read; arming is not a user action and is not scoped here.
* **`:exact_alarms`.** Never asked during the first run — it has no drawn board in the chain and a
  digest at 18:00 on Sundays does not need it. Deferred to screen 40.

**Two things a green run of this suite will not prove, stated so they are not assumed.** It says
nothing about the 1720px flow diagram, the reference sheets, the colourways or the type-size boards
as *drawings* — those move to `test/design/reference/` in Phase 10 and stay the host suite's proper
subject. And the e2e suite is a dozen or two journeys, not 152 tests: if it grows toward one test
per screen, it has become the gallery in a different costume.

**Where this document does not know.** Three places, marked rather than papered over: the versions
for the `androidx.test` artifacts, which are not in this repo and must resolve against AGP 9.3.1
(Phase 0); whether `Kati.Health.Reading` already carries a column for a user-chosen instant separate
from the insertion clock (Phase 2); and the shape of the provider client itself, which no section of
this specification designs — Phase 7 states its contract and its acceptance, not its implementation.
