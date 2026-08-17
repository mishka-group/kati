# Kati — Charting Brief

Input: `design-index.md`, `mob-framework.md`, `mishka-mob-index.md`, and the eight research
streams (`ash-on-mob`, `background-work`, `calendar-and-sync`, `competitors-media`,
`i18n-l10n`, `mob-plugins-navigation`, `opensource-release`, `overlay-components`).

This brief does three jobs: it **closes** the questions research has already decided, it
**opens** the ones that still need a human, and it **orders** them. Everything in §2 is a
candidate GitHub issue. Nothing in §1 should ever be discussed again unless new evidence
appears.

**Working frame.** Kati is a 62-screen, 7-domain, 2-language, Android-first personal app
built solo on a pre-1.0 framework with one maintainer. The research says the app is
buildable. It also says roughly a third of the drawn design does not have a rendering path
yet, and that nobody has counted which third. §5 is about that.

---

## 1. SETTLED — decided by the facts, not by preference

One line each. Do not re-litigate these; re-open only with contradicting evidence.

### Data layer

| # | Settled | Evidence |
|---|---|---|
| S-01 | **Do not use `mob_ash`.** Ash is used directly. | 6 modules / ~390 LOC; list/detail/create only, **no update action**; forms limited to 4 scalar types; `Ash.read!` with no filter/sort/paging; the docs describe `MobAsh.Generated.*` + native `AshForm`/`AshList` that **do not exist**; CHANGELOG cites a `mix mob_ash.gen` absent from the package. |
| S-02 | **`ash` + `ash_sqlite` run on-device, unmodified.** exqlite's C is cross-compiled per-ABI by Mob itself. | `mob_ash/mix.exs:42-43` "`:ash` is a REAL runtime dep — it runs ON DEVICE"; `build.zig.eex:376-425` compiles `sqlite3_nif.c` + `sqlite3.c` with zig cc per ABI; iOS links it statically (`driver_tab_ios.zig:69-146`). |
| S-03 | **`config/*.exs` never reaches the device.** Every runtime config must be `Application.put_env/3` in `on_start/0`. | `mob_dev/adopt/patcher.ex:365`; no `-config` in argv; `start_clean` boot; empty `.app` env. Affects Ash, AshSqlite, `ex_cldr`, `Mob.ScreenState`, tz. |
| S-04 | **AshSqlite has `can?(:transact) == false`, no resource aggregates, no `distinct`.** Actions are not atomic. | `ash_sqlite-0.2.17/lib/data_layer.ex:444-514`; `documentation/topics/about-ash-sqlite/transactions.md`. |
| S-05 | **AshOban is not viable.** Hard-requires `postgrex`, zero SQLite mentions. Roll a ~150-line Ash-resource + GenServer scheduler instead. | `ash_oban-0.8.12/mix.exs` (postgrex non-optional). `Oban.Engines.Lite` is real but AshOban never reaches it. |
| S-06 | **`:ash` starts `:mnesia` on the phone** (`extra_applications: [:mnesia]`) — configure its dir or it fails at boot. | compiled `ash.app`. |
| S-07 | **Ash costs +6.5–7.5 MB APK, measured**, not estimated. 1299 modules → 7.6 MB stripped → 4.53 MB zipped; ~5.8 MB compressed with reactor/ecto/spark. | measured against ash 3.29.3. |
| S-08 | **Extensions:** ✅ `ash_sqlite`, `ash_state_machine`, `ash_archival`. ❌ `ash_phoenix`, `ash_graphql`, `ash_json_api`, `ash_authentication` (bcrypt = uncompiled NIF), `ash_oban`. ⚠️ `ash_paper_trail` (doubles writes), `ash_cloak` (no keystore = theatre). | per-package dep sets, Hex API. |
| S-09 | **Migrations run at boot via `Ecto.Migrator` with the `MOB_BEAMS_DIR` workaround**, and the failure mode is silent ("Migrations already up", tables never created, screen appears frozen). | `mob_new/.../app.ex.eex:25-29,71-95`. |
| S-10 | **The domain layer stays free of `Mob.*`** so ~90% of the suite runs in plain `mix test`. This is the whole reason Ash earns its size. | `Mob.data_dir/0` falls back to `$HOME`/cwd when `MOB_DATA_DIR` is unset. |

### Background work & notifications

| # | Settled | Evidence |
|---|---|---|
| S-11 | **You cannot boot a headless BEAM from a Worker.** `erl_start` never returns; ERTS is a per-process singleton; `mob_start_beam` polls `Activity.hasWindowFocus()` for 3 s guarding a documented SIGABRT race; JNI symbols are name-bound to `MainActivity`; every plugin bridge early-returns on a null `WeakReference<Activity>`. | `mob_beam.zig:707-712`, `:432-509`, `:278`; `beam_jni.c.eex:21-29`. |
| S-12 | **The architecture is: fetch in Kotlin, write JSON to `filesDir`, notify natively, ingest on next foreground.** `MOB_DATA_DIR == context.filesDir` is a verified bidirectional channel. (`Mob.State` is `:dets` — Kotlin cannot write it.) | `mob_beam.zig:278`. |
| S-13 | **`MobNotify.schedule/2` arms a real OS alarm that fires while the app is dead**, on both platforms, with zero BEAM involvement. | `MobNotifyBridge.kt:147-163` (`setExactAndAllowWhileIdle(RTC_WAKEUP)`) → host `BroadcastReceiver` at `MobBridge.kt.eex:3602-3635`. |
| S-14 | **`mob_background` is disqualified.** Its own docs prescribe `foregroundServiceType="dataSync"` (capped 6h/24h at targetSdk 35, `onTimeout` ANR, can't start from BOOT_COMPLETED); `BeamForegroundService.kt:44` passes no type and implements no `onTimeout`. Measured cost 54–143 mAh/hr vs ~0 for a Kotlin worker. | `why_beam.md:137-143`. |
| S-15 | **WorkManager cadence is 6 h with 2 h flex. Never the 15-minute floor** — 96 wakeups/day is indefensible and shows in Android Vitals. | — |
| S-16 | **iOS cannot do background discovery without a server.** Zero `BGTaskScheduler`/`BGAppRefreshTask`/`BGProcessingTask` in mob's 10 iOS files or mob_new's 5; no `didReceiveRemoteNotification:fetchCompletionHandler:`, so silent push cannot wake the BEAM. Android-first is correct on this axis too. | grep, both repos. |
| S-17 | **`GET /3/tv/changes` collapses N followed shows into 1 request.** TMDB's 40/10s limit was disabled 2019-12-16. | <https://developer.themoviedb.org/docs/rate-limiting>. |
| S-18 | **The notification budget needs one central owner across all six domains.** iOS silently keeps only the soonest-firing 64; Android throws at 500 alarms/UID. | deprecated `UILocalNotification` reference (the only surviving statement of 64); notifee#349. |
| S-19 | **`MobNotifyBootReceiver` is not declared in the generated manifest** → every scheduled notification in every domain is silently lost on reboot. One-line fix. | `AndroidManifest.xml.eex:83-85` declares only `.NotificationReceiver`. |

### i18n / RTL / calendar system

| # | Settled | Evidence |
|---|---|---|
| S-20 | **Use `ex_cldr`, not Localize 1.0.** All three of Localize's runtime-data assumptions are false on Mob: `Application.app_dir` raises (flat beam dir, no dep `priv/`); its supervisor never boots (only compiler/elixir/logger start); `config :localize` is a no-op (S-03). | reproduced `ArgumentError` on OTP 28; Mob's own generated `app.ex:47-52` says so verbatim. |
| S-21 | **`ash_localize` is out.** Not on Hex (404), 4 stars, README says "early development", translated attributes explicitly not built — and Kati never translates user content anyway. | design-index: *"Your own words … are never translated."* |
| S-22 | **Jalali = `ex_cldr_calendars_persian`'s algorithm, precomputed.** The library is correct (observational, Tehran meridian) but **476 µs/conversion** → a month grid is 7.9 ms before formatting. A **101-integer Nowruz table reproduces it with 0 mismatches over 1826 days at 1.26 µs/op (~380× faster)**. Keep the library as `only: :dev` to generate the table. | measured. |
| S-23 | **Persian week functions do not exist in either library family** — `Interval.week`, `week_of_year`, `week_of_month` return `{:error, :not_defined}`. Write your own (4 lines; `first_day IR = 6` comes free from CLDR `weeks.json`). | — |
| S-24 | **Persian digits are automatic** — `fa`'s default number system is `arabext`. Two gotchas: the CLDR group separator is U+066C (not the design mock's ASCII comma), and `number_system: :latn` is **rejected** for `fa`. Add `precompile_transliterations: [{:latn, :arabext}]` or every call logs a slow-path warning. | verified `۱٬۴۸۰`, `۸٫۹۹`, `۱۸٪`. |
| S-25 | **Mob has zero RTL support on either platform** — no `layoutDirection`/`LocalLayoutDirection`/`rtl` anywhere; `android:supportsRtl` absent (Android defaults to false). It is ~1 day of native work, and the Compose bridge already uses `start`/`end`/`CenterStart`, so most of it mirrors free. | grep across mob 0.7.20, the 3,635-line bridge, MobRootView.swift. |
| S-26 | **Do not detect device locale in v1.** `Mob.Device` has no locale NIF; screen 53 is already an explicit chooser. And `Cldr.put_locale/1` is per-process — always pass `locale:` explicitly. | — |
| S-27 | **i18n size cost: 2.49 MB gzipped**, measured (29.24 MB unstripped → 2.61 MB stripped). `data_dir:` keeps 1.2 MB of compile-time JSON out of `priv/`. | Mob's Android release runs `beam_lib:strip_release/1`. |
| S-28 | **`format: :full` gives the wrong string** ("۱۴۰۵ مرداد ۲۵، یکشنبه"). Pass `"EEEE d MMMM y"` for the design's form. | — |

### Framework mechanics

| # | Settled | Evidence |
|---|---|---|
| S-29 | **There is exactly ONE screen process.** One `Mob.Screen` GenServer registered `:mob_screen`; the back stack is a list of `{module, socket}` tuples on that one heap. The docs' *"that screen's process is still running"* is false. | `screen.ex:232`, `:554-615`. |
| S-30 | Consequences of S-29, all undocumented: **`handle_info` always routes to the current module** and is silently swallowed by the catch-all; **`terminate/2` never fires on pop**; the 30 s persistence timer stops permanently if you navigate to a non-persisting screen; a crash in `handle_event` takes the whole UI. | `screen.ex:113`, `:501-508`, `:545-548`. |
| S-31 | **`tab_bar/1` and `drawer/1` render nothing** — `navigation/1`'s only consumer is `Nav.Registry.populate/1`. **`switch_tab/2` is an explicit no-op.** The `<TabBar>` *node* is real and separate. | `screen.ex:611-613`; `nav/registry.ex:84-102`. |
| S-32 | **Screens are not supervised**, despite `Mob.Screen`'s own moduledoc. `start_root/3` is a bare `GenServer.start_link` with no child spec. | `screen.ex:200-203`; no supervisor in `mob/lib/mob/`. |
| S-33 | **A plugin cannot add a renderable node type.** The Android dispatch is a closed 22-case `when` with **no `else`**; unknown types render nothing on Android and as a Column on iOS (enum default 0). `ui_components.android.composable` is read by nothing. | `MobBridge.kt.eex:2186-2258`; `ios/MobNode.h:21-43`; `scaffold.ex:508-513`. |
| S-34 | **`:anchored` is inert in a fresh app** — an anchored node renders **nothing at all, trigger included**, on Android; a stacked accordion on iOS. It works in exactly one place on earth: Mishka's showcase. `Anchored.closed/2` still emits the node, so a *closed* popover vanishes too. | `MobBridge.kt.eex:2175/2188/2255-2258`; `mob_nif.m:604-648`; `mishka_popover.ex:310`. |
| S-35 | **Only 3 components actually emit `:anchored`** — `popover`, `tooltip`, `preview_card`. The 10 other catalogs claiming `kit: ["anchored"]` are false positives from a moduledoc string-match. **14 of 17 overlay components are fresh-OK with zero native work.** | `generators/mob.ex:40-42`, `:163-171`. |
| S-36 | **Mob has no modal presentation API at all** (`socket.ex:129-186` is push/pop/reset/switch_tab). The bottom sheet is `drawer` with `side: :bottom`, `header: false`, `corner_radius: 26` — device-verified on a Samsung A55. | — |
| S-37 | **Animation: exactly one feature exists** — the nav transition, hardcoded in *your* `MainActivity.kt`. No per-widget animation props of any kind; the only transform is `offset_x`/`offset_y`. **The design declares zero motion, so this costs nothing.** | `design-index.md:351-353`. |
| S-38 | **Hard cap: 256 event handles per frame.** Over it, `register_tap` badargs and the screen dies. `Mob.List` adds one `on_tap` per row. | `mob_nif.zig:940`; `mob_nif.m:63`; `list.ex:110-116`. |
| S-39 | **`:lazy_list` is not lazy BEAM-side** — every item is built and JSON-encoded on every render. There is **no BEAM-side diff at all**: full tree → JSON → `set_root` on every event. | `renderer.ex:221-244`; `screen.ex:722-738`. |
| S-40 | **`mix mob.upgrade` does not exist.** Mob ships zero host-app Kotlin/Swift; every app's `MobBridge` is a fork with no upstream path. 46 mix tasks, none of them a resync. | `mob/PLAN.md:2383-2420`; `troubleshooting.md:481-487`. |
| S-41 | **`Mob.Certs` is not wired into generated projects** → Android crashes on the first HTTPS request with an opaque `FunctionClauseError`. This is issue #1 for the whole project. | grep of `mob_new/priv/templates/` for `Certs`/`cacerts`/`castore`: zero hits. |
| S-42 | **Mishka Chelekom cannot be a hex dep** — `priv/mob` is excluded from the package. Use a path or git dep, dev-only. Generated files are **vendored into Kati and overwritten on regeneration** → generate once with `--module-prefix kati_`, then own them. | `mix.exs:117-119`; `mishka.ui.gen.mob.ex:232-240`. |

### Calendar

| # | Settled | Evidence |
|---|---|---|
| S-43 | **`CalendarContract` first, and it is strictly better on 8 of 11 axes** — no OAuth, no secrets, no review, no credential storage; covers Google + Exchange + every CalDAV server via DAVx⁵; the OS keeps it fresh with the app closed; `Instances` expands recurrence for free and gives `START_MINUTE`/`END_MINUTE` — exactly the lane-algorithm inputs. | Etar's README: *"a Caldav client isn't included in Etar."* |
| S-44 | **Direct Google Calendar OAuth is near-dead.** *"Custom URI schemes are no longer supported due to the risk of app impersonation"*; loopback `[DEPRECATED]` on mobile; the only sanctioned path is `AuthorizationClient` from `play-services-auth` (a GMS binary — excludes exactly the FOSS audience); Calendar scopes are *sensitive* so an unverified project has a **100-new-user lifetime cap that cannot be reset**; push needs an HTTPS webhook with a CA-signed cert → polling only. Google's CalDAV endpoint rejects Basic auth and needs the same OAuth. | Google's own native-app + sensitive-scope docs. |
| S-45 | **There is no usable Elixir RRULE engine.** `cocktail`'s frequency type has **no `:yearly`** (so: no birthdays), no `BYSETPOS`, no ordinal `BYDAY` (no "last Friday"), no `WKST`, and its roadmap lists *"investigate and fix DST bugs"*. `Kati.Recurrence` is on the critical path. | — |
| S-46 | **A recurring event cannot be one row with an rrule string.** RFC 5545 makes it master + `RECURRENCE-ID` overrides sharing a `UID`; and `raw_icalendar` must be **retained and patched, never regenerated**, or you silently destroy `X-APPLE-STRUCTURED-LOCATION` and friends. | RFC 5545. |
| S-47 | **Day-view lanes are solvable in pure Mob.** The algorithm emits *ratios*; `Row` honours per-child `weight` natively, and the generated bridge already handles `offset_x`/`offset_y`. Use `Canvas` for the week lane chart and pixel fields, **not** for the day view (it carries text that must reflow at 235%). | `MobBridge.kt:2195-2200`, `:2162-2172`. |
| S-48 | **`offset_x`/`offset_y` are undocumented app-owned bridge behaviour** — zero hits across `mob/lib|guides|priv`. Load-bearing, therefore must be pinned deliberately with a regression test. | — |

### Media & data sources

| # | Settled | Evidence |
|---|---|---|
| S-49 | **Trakt cannot be shipped.** `POST /oauth/device/token` requires `client_id`, `client_secret` **and** `code` — all mandatory. Same for Last.fm and Simkl. Trakt also gutted its free tier in Feb 2025 (2 lists × 100 items, VIP $30→$60). | docs.trakt.tv. |
| S-50 | **Tier 0 must be fully functional alone, forever**: TVmaze (CC BY-SA, 20/10s), Open Library (1–3 req/s), MusicBrainz (1 req/s, mandatory contact-bearing UA, explicit block threat). | — |
| S-51 | **TMDB ships in-repo, Jellyfin-style.** TMDB rate-limits per **IP not per key**, so a public key steals no quota; Jellyfin has `public const string ApiKey = "4219e2…"` in master; build-time injection buys nothing and costs F-Droid reproducibility. | — |
| S-52 | **TMDB forbids caching its data longer than 6 months.** That is a schema requirement (`fetched_at` + eviction sweep), not a settings toggle. | TMDB API terms. |
| S-53 | **JustWatch has no public API and none planned.** Availability reaches Kati only via TMDB `/watch/providers`, which returns no deep links and requires attributing *JustWatch* specifically. | — |
| S-54 | **Tokens sit plaintext in SQLite.** Mob has no keychain/keystore and no encrypted storage anywhere. Mitigate by storing **only revocable OAuth/PAT tokens, never passwords**, and saying so on screen. | surface matrix; every keystore hit in all three packages is build-time signing. |
| S-55 | **Film/TV is at or above state of the art; books and music are one-screen stubs.** No book detail, no album/artist screen, no reading-session logger, no listen history in the 62. Group C "Depth on a title" contains only screen 14, which is a *series* screen. | `design-index.md:100-102`. |

### Release

| # | Settled | Evidence |
|---|---|---|
| S-56 | **Licence = MIT.** Matches Mob; GPL is incompatible with the declared App Store target. Apache-2.0 §4 obligations apply to Mishka's generated components; no NOTICE file exists upstream. | — |
| S-57 | **Distribution is left on in Android release builds** — `Mob.Dist.ensure_started(… cookie: :mob_secret)` unconditionally, iOS guards it with `MOB_RELEASE`, nothing sets that on Android. `libepmd.so` ships in release AABs. Any app that binds `127.0.0.1:4369` gets RCE inside Kati's sandbox with a cookie published in your own repo. | `app.ex.eex:34`; `mob/ios/mob_beam.m:401-423`. |
| S-58 | **Ship arm64-only.** `abiFilters` declares 3 ABIs; `release_android.ex:37` stages only `arm64-v8a` OTP into a non-split `assets/otp.zip` — the other two splits cannot boot. | — |
| S-59 | **Guideline 2.5.2 is not a threat.** The prohibited verbs are download/install/execute code that *changes functionality*; a bundled `.beam` is structurally identical to a `.pyc` in a Kivy bundle, and iOS runs `beam.emu` (interpreter, no JIT/W^X). Obligations: never ship a code-download feature, never ship a debug build. | `mob_dev/.../release/otp.ex:27`; `mob_beam.m:22-27`. |
| S-60 | **`UIBackgroundModes: [audio]` → guideline 2.5.4 rejection**, and **no `PrivacyInfo.xcprivacy` exists anywhere in Mob** → ITMS-91053 at upload (the BEAM calls `stat`/`fstat`/`mach_absolute_time`). | `Info.plist.eex:33-36`. |
| S-61 | **F-Droid is not feasible with today's Mob** — the prebuilt OTP tarball comes from GitHub releases (not an allowed prebuilt source), Zig isn't an allowed compiler, and `mob_notify` pulls Firebase. Ship signed APKs + checksums, or self-host a repo. | `otp_downloader.ex:10`. |
| S-62 | **Export is a Mob capability gap, and `allowBackup="false"` makes export/restore a product requirement.** `Mob.Files.pick/2` imports fine; `Mob.Share` is text-only; `mix mob.enable file_sharing` has *"(no Elixir surface)"*. You will patch `MobBridge.kt` for `ACTION_CREATE_DOCUMENT`. | — |
| S-63 | **Google's OAuth "secret" is not a secret** (*"installed apps cannot keep secrets"* — PKCE solves it). The real cost is sensitive-scope verification: domain, published homepage, privacy policy, YouTube demo video. TMDB/Trakt keys genuinely are secrets. | — |

---

## 2. OPEN — candidate wayfinder tickets

39 candidates. Each: the precise question · why it isn't settled · what kind of work
resolves it · what it depends on.

**Work types:** `research` (find out from primary sources) · `prototype` (build a throwaway
to learn something only a device can tell you) · `grilling` (an owner decision, no amount of
research resolves it) · `task` (the answer is known; the work is doing it).

### Wave 0 — Phase-0 unblock

**K-01 · Host-app hardening pass**
*Question:* Which of the seven known defects in a stock `mix mob.new` app must be fixed
before the first line of Kati is written, and can they land as one commit?
*Not settled because:* each is individually settled (S-19, S-41, S-57, S-58) but nobody has
established the order, whether they conflict, or whether the app still boots afterwards.
Candidates: wire `Mob.Certs.load_cacerts!/1` + bundle castore PEM · declare
`MobNotifyBootReceiver` · gate `Mob.Dist.ensure_started` behind `Mix.env()` and strip
`:mob_secret` · `abiFilters 'arm64-v8a'` only · delete `RECORD_AUDIO` and the unused
CameraX/Media3 deps · confirm the `MOB_BEAMS_DIR` migrations helper is present · remove
`UIBackgroundModes: [audio]`.
*Work:* task.
*Depends on:* nothing. **Everything depends on this.**

**K-02 · targetSdk 36 migration**
*Question:* What breaks in Kati's shell when `targetSdk` goes 35 → 36, and specifically does
predictive back destroy Mob's nav stack?
*Not settled because:* Play requires API 36 for all new apps and updates from **2026-08-31**
— days away. The bump forces mandatory edge-to-edge, predictive back (which kills
`onBackPressed`, and Mob's system-back handling is `handle_info({:mob, :back}, …)` intercepted
in `screen.ex:444-466` — untested against predictive back), ignored portrait lock on ≥600dp,
and `elegantTextHeight` deprecation that **changes Arabic-script line metrics** — i.e. it
touches Kati's Persian screens directly.
*Work:* prototype, then task.
*Depends on:* K-01.

**K-03 · The Ash-on-device spike**
*Question:* Does an `ash` + `ash_sqlite` Mob app actually boot, migrate, round-trip and
survive a kill on a real Android device?
*Not settled because:* **Kati would be the first public user of AshSqlite on a device BEAM.**
`mob_ash` has 176 downloads and 0 stars; Mob's 34 guides contain zero Ash mentions; the forum
thread has none. Every claim about versions and code paths is verified; nothing about runtime
behaviour on a phone is. Five acceptance criteria, in order: (1) the app boots with `:ash`
started and `:mnesia` behaving; (2) `Ecto.Migrator` really creates AshSqlite's tables;
(3) one `Ash.create!` + `Ash.read!` round-trips a `:decimal` and a `:utc_datetime_usec`;
(4) data survives an app kill *and* an app update; (5) `mix mob.verify_strip` is clean.
*Work:* prototype.
*Depends on:* K-01.

**K-04 · Where runtime configuration lives**
*Question:* Given S-03, what is Kati's single mechanism for device runtime config, and how do
we prevent "works on my Mac" from meaning nothing?
*Not settled because:* the fix is mechanical but the *discipline* isn't designed. Ash,
AshSqlite, `ex_cldr` (`:default_backend`), the tz database, and `Mob.ScreenState`'s repo all
read Application env at runtime. Mob's own generated `config/config.exs` sets
`config :mob, :repo, …` that the device will never see. Wants: one `Kati.Runtime.configure/0`
called first in `on_start/0`, plus a boot assertion that fails loudly rather than silently.
*Work:* task, preceded by a one-line on-device probe (`Application.get_env(:mob, :repo)`).
*Depends on:* K-03.

**K-05 · The bridge fork ledger**
*Question:* How does Kati track `MobBridge.kt` / `MobRootView.swift` / `AndroidManifest.xml`
drift against upstream, given there is no `mix mob.upgrade` (S-40)?
*Not settled because:* Kati is going to edit the bridge for RTL (K-12), icons (K-07),
`on_long_press` (K-17), `ACTION_CREATE_DOCUMENT` (K-37), possibly shadows/blur (K-06) and
possibly `MobAnchored` — and each edit is permanent merge cost. Wants: `android/` and `ios/`
committed and treated as vendored third-party code with a generated-from header; a script that
`mix mob.new`s a throwaway app into `/tmp` and three-way-diffs; every Kati edit inside fenced
comment markers. **This is the single highest-leverage piece of project infrastructure.**
*Work:* task.
*Depends on:* K-01. **Blocks every native ticket.**

### Wave 1 — Foundations

**K-06 · Can Mob render Kati's surface language at all?**
*Question:* Does Mob have any elevation/shadow primitive, any blur, and any way to express
the dark-mode "hairline instead of shadow" rule — and if not, what replaces them?
*Not settled because:* **this is the largest unexamined gap in the whole project.** The
elevated card recipe (`0 1px 2px … , 0 12px 24px -18px …`) has **262 uses** — the single most
repeated recipe in the design — and there are **47 distinct shadow strings**, every one a warm
ink shadow. `Mob.Theme`'s struct has colours, spacing, type scale and radii and **no shadow
token at all**. Separately, there are **23 `backdrop-filter` declarations** (`blur(14/20/22px)`)
on the tab bar of every root screen and all four lock-screen widgets, and Mob has no blur.
If shadows aren't expressible, either the bridge grows a `shadow` prop (K-05 cost) or Kati's
visual identity changes.
*Work:* research (read `renderer.ex`'s prop tables + the bridge's `Modifier` chain), then
prototype on device, then a **grilling** with the owner about what the design becomes.
*Depends on:* K-05.

**K-07 · Material Symbols coverage**
*Question:* How does Kati get the ~40+ distinct Material Symbols Rounded glyphs the design
uses, including the `FILL 1` variation for active tabs?
*Not settled because:* the design has **673 icon spans** and uses `font-variation-settings:'FILL' 1`
for the active tab state; the generated bridge's `materialIconForLogical/1` maps **10 icons**
(`MobBridge.kt:3500-3513`). Options: extend the map (bounded, ugly, permanent merge cost),
bundle the Material Symbols variable font and render icons as `Text` (gets FILL for free, but
depends on K-14's variable-font unknown), or ship SVG/PNG assets. Also entangled with
`Icons.AutoMirrored.*` for RTL (K-12).
*Work:* prototype.
*Depends on:* K-05, K-14.

**K-08 · The four-root shell**
*Question:* How are the four fixed roots, the floating pill tab bar and the detached FAB
actually built, given `tab_bar/1` renders nothing and `switch_tab/2` is a no-op (S-31)?
*Not settled because:* the design's tab bar is **not** a Material `NavigationBar` — it is a
floating pill (`border-radius:32px`, `rgba(251,250,248,.9)`, `backdrop-filter:blur(20px)`)
with a separate 64×64 ink FAB beside it and a 120 pt `pointer-events:none` gradient scrim
layered between content and chrome. Mob's `<TabBar>` node gives you a Scaffold + M3
NavigationBar and renders only `children[activeIdx]` — and serialises the rest (S-39 note 4).
So: hand-roll the pill as a `:box` overlay in each root screen's tree, or use `<TabBar>` and
accept Material chrome. This decision shapes all 14 tabbed screens.
*Work:* prototype.
*Depends on:* K-06 (blur), K-05.

**K-09 · App skeleton & supervision**
*Question:* Given exactly one screen process with no supervision (S-29, S-32), where do
long-lived subscriptions, the sync engine, the fetch throttles and the notification scheduler
live — and what is the rule that stops screens from subscribing to anything?
*Not settled because:* with 62 screens you *will* be tempted to subscribe screens to Ash
notifications or PubSub, and any message arriving after navigation lands on the **wrong
module** and is silently swallowed. Wants: a `Kati.Supervisor` started in `on_start/0`; a
stated rule that only that tree holds subscriptions and it may `send(:mob_screen, …)` only
when the relevant screen is current; a decision on whether Kati adds its own supervisor for
the screen process itself (the docs promise restart; the source doesn't deliver it).
*Work:* task, with a short grilling on the "no cross-screen messaging" rule.
*Depends on:* K-03, K-04.

**K-10 · Cold-start budget**
*Question:* What is Kati's cold start, and what has to come off the boot path to hit a target?
*Not settled because:* the widely-cited "~0.5 s BEAM boot" is **not in mob 0.7.20's README or
`why_beam.md`** — it was grepped for and is absent. Ash adds 1299 modules; `on_start/0` runs
DNS config, `ensure_all_started`, `Repo.start_link`, **`Ecto.Migrator.run` synchronously**,
CLDR setup and `start_root` before the first paint. Candidates: gate migrations on
`migrations_pending?`, `start_root` first and start everything else from a Task, keep
`HomeScreen.mount/3` query-free with a `send(self(), :load)`.
*Work:* prototype (`adb logcat | grep MobBeam` gives phase logs).
*Depends on:* K-03, K-09.

**K-11 · Render & list performance budget**
*Question:* What is Kati's rule for lists, given the 256-tap-handle cap (S-38), a non-lazy
`:lazy_list` (S-39), and a full tree re-serialise on every event?
*Not settled because:* the design's poster grids and rails are everywhere (130 image slots),
screen 15 has 1,204 log entries, screen 20 has 64 books and screen 21 has 418 albums. A
250-row `Mob.List` alone nearly exhausts the tap table and **kills the screen process** when
it overflows. Wants: a measured page size, a custom row renderer that omits `on_tap` on
non-interactive rows, `on_end_reached` paging, and `%{type: :column, children: []}`
placeholders for inactive `<TabBar>` branches. Also: nav transitions clear Compose's scroll
caches, so **popping back loses scroll position** — decide whether that's acceptable.
*Work:* prototype (build screen 03's 418-item shelf and measure).
*Depends on:* K-03, K-08.

**K-12 · The RTL native pass**
*Question:* Land `android:supportsRtl` + `CompositionLocalProvider(LocalLayoutDirection)` at
the root driven by a Mob prop + per-node override + absolute `text_align` values +
`Icons.AutoMirrored.*` — and verify the three things the research could not.
*Not settled because:* the work is ~1 day and well specified (S-25), but three behaviours are
explicitly **unverified**: does M3 `LinearProgressIndicator` mirror under `LayoutDirection.Rtl`
(the design needs progress bars filling from the right on 57/59)? does `Modifier.offset(x:)`
mirror in the poster-stack path? does `TextField` caret behave with Arabic digits (CMP-2772)?
Also gates all of group N (screens 53–62), which S-55's competitive read calls Kati's
**uncontested market**.
*Work:* task + prototype.
*Depends on:* K-05, K-02 (edge-to-edge interacts).

**K-13 · The i18n stack and `Kati.Calendar.Shamsi`**
*Question:* Stand up ex_cldr 2.47 + numbers + dates_times + calendars + messages + gettext,
generate the Nowruz table, and write `Kati.Calendar.Shamsi`.
*Not settled because:* the stack is settled (S-20…S-28) but two pieces are genuinely new
code: the table generator (with `ex_cldr_calendars_persian` as `only: :dev`) and the
week/month grid helpers Persian doesn't ship. **P0 attached: a golden-file test of ~20 known
نوروز dates against a published Iranian calendar table.** `ex_cldr_calendars_persian` has
1,808 lifetime downloads; two checked data points is not a test suite, and a wrong Nowruz is
the highest-visibility possible bug for the fa locale.
*Work:* task + research (source the golden table).
*Depends on:* K-04 (`ex_cldr` default backend is Application env).

**K-14 · Fonts**
*Question:* Can Kati ship Plus Jakarta Sans (5 weights), DM Mono (2) and Vazirmatn (5) through
Mob's font path, and what carries Persian digits in numeric columns?
*Not settled because:* Mob's path is `FontFamily(Typeface)` = **one file per family**, so you
ship static instances and address per weight — 12 files, uncompressed in `res/font/`. Two
unknowns: **variable-axis support through Mob's path is UNKNOWN** (which also gates K-07's
FILL axis), and **DM Mono almost certainly has no U+06F0–U+06F9** — so the design's rule
*"times, counts and episode numbers keep DM Mono in both languages"* may be literally
unsatisfiable. Vazirmatn tabular figures is the likely answer, and that's a design change.
*Work:* prototype + grilling.
*Depends on:* K-01.

**K-15 · Timezone database on device**
*Question:* Is there a working tz database in a Mob app, and what is the update policy?
*Not settled because:* **no tz package appears in Mob's dependency tree** and `Mob.Device` has
no timezone API. Every "convert a user-picked Shamsi date back to UTC", every recurrence
expansion in the event's own zone, and every air-date alarm depends on it. `tz` vs `tzdata`
(the latter downloads at runtime, which a device-first app should refuse). Also: Iran
abolished DST in 2022, so `Asia/Tehran` is a fixed +03:30 — but a Persian user travelling
is not.
*Work:* research + prototype.
*Depends on:* K-03, K-04. **Blocks K-20.**

**K-16 · Mishka generation policy**
*Question:* Which components does Kati generate, with what prefix, and what stops a
regeneration from silently reverting Kati's edits?
*Not settled because:* the mechanics are settled (S-42) but the list and the guardrails
aren't. Recommended generate set: `drawer` `dialog` `alert_dialog` `menu` `select` `combobox`
`toast` `loading_overlay`. **`popover.ex` and `anchored.ex` will land anyway** — `menu`'s
catalog declares `necessary: ["popover"]` and `generate_necessary/1` does not ask. That's
fine as dead code, so wants: a CI lint asserting `grep -rn "Anchored\.\(anchor\|closed\)" lib/`
returns nothing, plus `mix mob.routes --strict` wired into CI from day one.
*Work:* task.
*Depends on:* K-01.

**K-17 · Kati's component gap list — build here or contribute upstream?**
*Question:* Of the components Kati needs that Mishka's Mob layer does not have, which get
built in `lib/kati/components/` and which get contributed to Mishka Chelekom?
*Not settled because:* the gap is large and the ownership question is genuinely open (the
owner maintains Mishka). Missing, in rough value order: **month grid / date picker** (~400–600
LOC, highest-value single addition, headless has one and Mob does not), **time-gutter
timeline** (screens 02/09/30/43/52/56/59), **poster tile / rail**, **pixel field** (07/22/47/61),
**bar chart** (canvas), **star rating with half-star by touch position** (33), **day strip**,
**search field**, **badge**, **week lane chart** (17), **matrix grid** (44/60). Also
`on_long_press` is missing from the fresh Android template (registered by the renderer, live
on iOS) — ~35 LoC of `combinedClickable` — which kills `context_menu`'s long press and
brief #8's per-episode rating gesture.
*Work:* grilling (ownership) then task.
*Depends on:* K-16, K-06 (they all need the surface language), K-05 (`on_long_press` is a
bridge edit).

**K-18 · Modal presentation: sheet or screen?**
*Question:* Are Kati's five modals (06, 18, 31, 33, 46) partial-height sheets or full-screen
covers?
*Not settled because:* **the design specifies chrome, not presentation.** Centred title,
leading `close`, no tab bar, no back pill — that is a chrome contract. The only hint is the
`26px` "sheet" radius, tied to no screen. The research's practical read: 31 and 33 are dense
and form-shaped (push a screen, `pop_screen/1` from the ✕); 18 is a single input with a
preview card (classic partial sheet); 06 and 46 could be either. Attached hardware check:
put a `side: :bottom` drawer in a throwaway app and confirm (1) it draws over the page,
(2) backdrop dismisses, (3) the drag handle's `:canvas` reports drags — step 3 is the one that
depends on canvas touch-coordinate scaling, a known cross-version drift point.
*Work:* grilling + prototype.
*Depends on:* K-16.

**K-19 · Accessibility and Dynamic Type — what is actually achievable?**
*Question:* Does Mob honour the OS font scale at all, and what fraction of screen 41 can Kati
deliver?
*Not settled because:* screen 41 *draws the spec* — the densest card re-laid at **235%**
Dynamic Type with "nothing truncates, cards get taller instead", six a11y rows, and a literal
VoiceOver transcript for an episode row. Against that: Mob's accessibility is documented as
partial with "no uniform coverage, no focus management, no reduce-motion, no screen-reader
announcements", and **`Image`'s `description` prop is the single accessibility hook in the
entire bridge**. Nobody has established whether Compose's own text scaling reaches through
Mob's `text_size` (numbers vs sp tokens), or whether `Modifier.semantics` could be threaded as
a generic prop. This is a promise the design makes on Kati's behalf.
*Work:* research + prototype, then grilling about what the app promises.
*Depends on:* K-05, K-06.

### Wave 2 — Calendar

**K-20 · `Kati.Recurrence`**
*Question:* Build an RRULE expander that implements RFC 5545's expand/limit table.
*Not settled because:* there is nothing to adopt (S-45). Requirements the research pins:
expand in **wall-clock terms in the event's own timezone**, then convert to UTC; drop invalid
dates and nonexistent local times; handle `{:gap, …}` (pick `after`) and `{:ambiguous, …}`
(pick `first`); write `WKST` explicitly on every `INTERVAL > 1` weekly rule; RFC 5545 §3.8.5.3
examples as the golden suite. Recommendation is pure Elixir over a libical NIF (static-linking
plus iOS silent-`dlopen`-failure).
*Work:* task (large).
*Depends on:* K-15. **Blocks everything calendar.**

**K-21 · The event data model, in migration 1**
*Question:* What is the event schema, and does it round-trip an external calendar without loss?
*Not settled because:* S-46 forces shape decisions that are painful to retrofit over user
data. Must be in the **first** migration: `event_occurrence_override` (master +
`RECURRENCE-ID` sharing a `UID`), `raw_icalendar`, `unknown_props`, `origin`
(`:kati | :mirror`), `local_rev`/`synced_rev`. Plus: prefer `DURATION` over `DTEND`; all-day
events stored as `Date`, never midnight instants; floating time (no TZID) for habits and meals;
`events_in_range(from_utc, to_utc)` as the sole query entry point. Interacts with S-04 — a
multi-row calendar import is not atomic, so it needs a hand-rolled `Kati.Repo.transaction/1`.
*Work:* task + grilling (the shape is a commitment).
*Depends on:* K-03, K-20.

**K-22 · What does "follows travel" mean?**
*Question:* Screen 31 says *"Europe/London · follows travel"*. Fixed zone, floating time, or a
per-grid override?
*Not settled because:* the design states it and nothing defines it. The three readings produce
three different storage shapes and three different alarm behaviours, and the choice interacts
with S-46 and with air-date alarms (absolute epoch, so a Tehran→London flight does *not* shift
them — which may be right or wrong per alarm kind).
*Work:* grilling.
*Depends on:* K-21 (or rather, blocks it — resolve early).

**K-23 · Lane assignment and the density rules**
*Question:* Implement `Kati.Calendar.Layout` and prove it on a device.
*Not settled because:* the algorithm is specified (three-phase interval-graph colouring,
`max_cols`, span expansion, `+n MORE` cap) and the Mob mechanism is identified (S-47), but two
things are unproven on hardware: whether `Row` weight distribution reads correctly at Kati's
densities, and whether the **collapse-by-kind pre-pass runs before lane assignment** without
allocating columns to events about to be hidden. Screen 09 is the reference: 14 items,
2 clashes, lanes capped at 2 columns, a `+1 MORE` tile, 3+ same-kind grouped with poster
stacks, an all-day band, merged money events.
*Work:* task + prototype.
*Depends on:* K-20, K-21, K-11, and the K-05 pin on `offset_x`/`offset_y`.

**K-24 · Shamsi grids that reorder rather than mirror**
*Question:* Build the month grid and the 5×7 week matrix in Jalali terms with a Saturday week
start.
*Not settled because:* screen 60 calls this *"the hardest case in the whole pass: a matrix
whose columns are days. Mirroring alone would put Monday on the right and still be wrong — the
sequence itself has to restart at شنبه."* The week-numbering primitives don't exist (S-23), so
the leading-blank-cell and header-row logic is Kati's. Also Persian digit folding
(U+06F0–U+06F9) in the quick-add parser.
*Work:* task.
*Depends on:* K-13, K-12.

**K-25 · The sync transport decision**
*Question:* Does Kati ever build direct Google Calendar sync, or is `CalendarContract` the
whole answer on Android?
*Not settled because:* the *engineering* answer is settled (S-43, S-44) but the **business
decision is not**: direct Google requires completing and maintaining sensitive-scope
verification (domain, published homepage, privacy policy, YouTube demo video) or accepting a
**100-user lifetime cap that cannot be reset**. And `AuthorizationClient` is a GMS binary that
excludes de-Googled devices — exactly the audience an open-source APK-on-GitHub app attracts.
The owner should decide *now* whether Phase 6 exists, because "we'll add it later" quietly
shapes the credential-storage and outbox designs.
*Work:* grilling.
*Depends on:* nothing. Resolve early.

**K-26 · `CalendarContract` read plugin**
*Question:* Build the native plugin that lists calendars and reads `Instances` / `Events` /
`Reminders` / `Attendees`.
*Not settled because:* it's a native Kotlin plugin nobody has written, and the plugin manifest
route for `<provider>`-adjacent work is only newly possible (see K-31's snippet finding).
Includes the runtime permission flow with screen 40's "state the purpose" treatment, and
screen 32 rendered over provider accounts with Live/Stale badges. Also needs defensive reads
for OEM provider divergence (Samsung/Xiaomi).
*Work:* task (native).
*Depends on:* K-05, K-21, K-25.

**K-27 · The sync engine**
*Question:* Build outbox + tombstones + ownership + conflict detection before a single write
leaves the device.
*Not settled because:* every prerequisite is enumerated and none is built: outbox with
idempotency keys, `depends_on` chains, backoff and poison quarantine · `origin` enforced
end-to-end in both the editor and the engine · tombstones with 90-day retention, never GC'd
while an outbox entry exists · conflict detection via `local_rev`/`synced_rev` +
`_SYNC_ID`/`DIRTY` · three-way property merge against the base `raw_icalendar` · a
patch-don't-regenerate write path · per-calendar `writeback_policy` defaulting to "only events
Kati created". Conflict UI reuses screen 37's resolver — one of the design's best assets.
*Work:* task (large).
*Depends on:* K-21, K-26.

**K-28 · Encrypted credential storage**
*Question:* Build a native Keystore/Keychain extension for tokens.
*Not settled because:* Mob has none (S-54) and it **blocks every direct transport** — CalDAV
(Phase 4), Google direct (Phase 6), and any Tier-2 media credential the owner wants to treat
as more than plaintext. Encrypt the *tokens*, not the database (no SQLCipher path exists).
Scope question inside it: is this a Kati plugin or an upstream `mob_secure_store` contribution?
*Work:* task (native) + grilling on where it lives.
*Depends on:* K-05, K-25 (if Phase 6 is cancelled, this drops in priority but does not vanish —
CalDAV still needs it).

### Wave 2 — Media & background

**K-29 · The API-key tier model**
*Question:* Ship TMDB's key in-repo, and confirm with TMDB first?
*Not settled because:* the reasoning is strong (S-51) but **there is no written TMDB policy
either way** — the only evidence is Jellyfin's unchallenged precedent. The research recommends
emailing TMDB support before the first store release rather than assuming. Attached decisions:
which Tier-2 providers Kati offers at all given S-49, and whether "Use Kati's key / Use my own
key" appears as a segmented control on the Data sources screen.
*Work:* research (email TMDB) + grilling.
*Depends on:* nothing. Resolve early — it shapes K-34.

**K-30 · Cache TTL as a schema constraint**
*Question:* What is Kati's metadata cache model, given a hard 6-month legal ceiling?
*Not settled because:* S-52 is a **schema requirement decided before Ash resources are
written**: every cached metadata row needs `fetched_at`, and the app needs an eviction sweep
plus a user-visible "Cached metadata · 34 MB · oldest entry 2 months" row. Retrofitting a
timestamp column across a media schema over user data is exactly the migration you don't want.
*Work:* task.
*Depends on:* K-03. **Must land before the media resources.**

**K-31 · `mob_periodic` — the WorkManager plugin**
*Question:* Build the Kotlin periodic-fetch plugin, and first verify the undocumented manifest
splice works against a 0.7.20 host.
*Not settled because:* the design is sketched and the enabling mechanism is real but **new and
undocumented** — `mob_dev` 0.6.19 added `android.manifest_application_snippets`
(`CHANGELOG.md:91-104`, `merge.ex:53-59`, `native_build.ex:4567,5296-5332`), and
`MOB_PLUGINS.md:669-676` in mob 0.7.20 still omits it, with `mob_notify`/`mob_screencast`/
`mob_nfc` all carrying now-stale "a plugin can't do this" comments. **`mob_dev` has no 0.7.x
release**, so the splice against a 0.7.20 host is untested. Also unverified: cross-package
access to `MobNotifySchedules` from `io.mob.periodic`.
*Work:* prototype (throwaway app, verify the splice) then task.
*Depends on:* K-01, K-05, K-02.

**K-32 · `Kati.Notifications.Scheduler`**
*Question:* Build the single central budget owner across all six domains — **before** any
individual reminder feature.
*Not settled because:* it is architecture, not a feature, and it is the kind of thing that
gets discovered too late. Owns: the entire pending set; reconcile-cancel-schedule on every
foreground; ≤50 pending on iOS (silent truncation at 64) and ≤120 TV alarms on Android (500/UID
cap shared with habits, calendar, money, health); digest-over-per-item preference; re-arm on
`TIME_SET`/`TIMEZONE_CHANGED`/`MY_PACKAGE_REPLACED`; and a debug screen showing
`pending_count / 64`. Attached: the "Why am I not getting notifications?" diagnostic screen
(permission state, `canScheduleExactAlarms()`, battery-optimisation state, last successful
Worker run) — because OEM survival rates are unknowable and Kati should self-check rather than
guess.
*Work:* task.
*Depends on:* K-01 (S-19 fix), K-31.

**K-33 · Books and music depth — what ships in v1?**
*Question:* Does Kati ship books and music as designed (one shelf each), or does the design
grow the missing 13 book screens and 7 music screens first?
*Not settled because:* **this is the biggest product gap found** (S-55). Screen 20 already
*shows* "p. 214 / 380 · 23 min/day pace" and **nothing in the 62 screens writes that number**.
There is no book detail, no reading-session logger, no album or artist screen, no listen
history. Ranked briefs exist and are paste-ready (book detail, log-progress modal, album/artist,
DNF state machine, goals, mood/pace tags, rich filtering + bulk edit, anime-as-a-filter). The
alternative is honest scoping: ship Screen only in v1 and grey out Books/Music, which the
design **already draws** (03/57 show them greyed until built).
*Work:* grilling.
*Depends on:* nothing. Resolve early — it sets v1's size.

**K-34 · Data sources + Attribution screens**
*Question:* Design and build the two screens the research says are missing and blocking.
*Not settled because:* the Attribution screen is a **licence obligation, not a nicety** —
TMDB requires its logo plus an exact notice verbatim, JustWatch must be credited by name for
provider data, TVmaze is CC BY-SA with link-back, Open Library and MusicBrainz both ask for
attribution. Neither screen exists in the 62. The Data sources screen also carries the honest
storage note (S-54) and the cache row (K-30).
*Work:* task (design first, then build).
*Depends on:* K-29, K-30.

**K-35 · Scrobbling feasibility**
*Question:* Can a Mob app host a `NotificationListenerService` + `MediaSessionManager` on
Android?
*Not settled because:* screen 36 is a full designed screen (now-playing card, "ticks at 90%",
sources, the "Needs a decision" disambiguation card that the research calls **genuinely novel**)
and `mob-framework.md` does not cover whether Mob can host that service class at all. Pano
Scrobbler proves it's possible in a normal Android app. This is a spike, and its answer decides
whether screen 36 ships, ships music-only, or gets cut.
*Work:* research + prototype.
*Depends on:* K-05, K-31 (same manifest-snippet mechanism).

**K-36 · Rewrite screen 40**
*Question:* What replaces *"Signed in with Apple · relay address · no email shared"* on an
Android-first, no-server, no-account app?
*Not settled because:* the design contradicts three locked decisions at once. Screen 40 is
otherwise excellent — permission rows that each state their purpose, before asking — and that
part should survive. The rest (device list, per-device sync timestamps, iCloud sync) has no
implementation path.
*Work:* grilling (owner redesigns).
*Depends on:* nothing.

### Wave 3 — Release

**K-37 · Export, restore, and the backup gap**
*Question:* Build file export, given `Mob.Share` is text-only and `allowBackup="false"`.
*Not settled because:* S-62 makes export/restore a **product requirement**, not a feature —
with `allowBackup="false"` and no server, a user who loses their phone loses everything. Needs
an `ACTION_CREATE_DOCUMENT` patch in `MobBridge.kt` (permanent merge cost, K-05), a chosen
format (JSON + `.ics` + CSV), and a **CI round-trip test** that exports, wipes and restores.
Screen 50's "Export JSON" and "Print the week (PDF)" both sit on this.
*Work:* task (native + Elixir).
*Depends on:* K-05, K-21.

**K-38 · Release engineering & distribution**
*Question:* What is the release pipeline, and where does Kati distribute?
*Not settled because:* the pieces are individually settled but the pipeline isn't built.
Includes: MIT `LICENSE` + `THIRD_PARTY_NOTICES.md` + OFL for fonts + the exact TMDB wording;
`secrets.exs.example` + CI injection + Settings-paste (three tiers); CI with `erlef/setup-beam`,
pinned NDK `27.2.12479018`, pinned Zig, cached `~/.mob/cache`, `mix mob.release
--security-gate`, `ERL_COMPILER_OPTIONS=deterministic`, **no releases from fork PRs**; the
Play data-safety form (everything local); `-Wl,-z,common-page-size=16384` for the 16 KB page
requirement; and a buy-a-domain + publish-privacy-policy task the owner must do personally.
Open decision inside it: **self-hosted F-Droid repo, or signed APKs + checksums only?** (S-61).
*Work:* task + grilling (the F-Droid call).
*Depends on:* K-01, K-02, K-37.

**K-39 · The iOS probe (deferred, but not indefinitely)**
*Question:* Does an Erlang/Elixir app pass App Review?
*Not settled because:* **no Erlang app is known to have passed review** — S-59's conclusion is
a reading of the guideline plus analogy to Python/Lua bundles, not precedent. The
recommendation is a deliberately early throwaway TestFlight build purely to test the
hypothesis, before iOS work is sunk. Bundled with it: `PrivacyInfo.xcprivacy`,
`ITSAppUsesNonExemptEncryption`, deleting `UIBackgroundModes`/`NSMicrophoneUsageDescription`,
and confirming `mix mob.release --ios` really defines `MOB_RELEASE`. Also flagged: **how Kati
does HTTPS on iOS at all**, given OTP there is built `--without-ssl`.
*Work:* prototype + research.
*Depends on:* K-38. Deferred by the Android-first decision — but the *answer* is cheap and the
*consequence* is a whole platform.

---

## 3. Dependency order

### The critical path, stated once

```
K-01 host hardening
  └─ K-03 Ash device spike ──┬─ K-04 runtime config ─ K-13 i18n ─ K-24 Shamsi grids
                             ├─ K-15 tz db ─ K-20 Recurrence ─ K-21 event model ─┬─ K-23 lanes
                             │                                                    ├─ K-26 CalendarContract
                             │                                                    │     └─ K-27 sync engine
                             │                                                    └─ K-37 export
                             └─ K-30 cache TTL ─ K-34 attribution/sources
  └─ K-05 bridge ledger ──┬─ K-06 surface language ─┬─ K-08 shell ─ K-11 perf
                          │                          ├─ K-17 components
                          │                          └─ K-19 accessibility
                          ├─ K-12 RTL
                          ├─ K-07 icons (also needs K-14)
                          ├─ K-28 credential storage
                          ├─ K-31 mob_periodic ─ K-32 scheduler
                          └─ K-35 scrobbling
  └─ K-02 targetSdk 36 (parallel; touches K-12's edge-to-edge and K-31's manifest)
```

### Specific blocking claims

1. **K-01 blocks literally everything.** Without `Mob.Certs`, the first TMDB call crashes the
   app on Android. Without the boot receiver, every notification feature in six domains is a
   lie after the first reboot.
2. **K-05 blocks every native ticket** — K-06, K-07, K-12, K-17 (`on_long_press`), K-26, K-28,
   K-31, K-35, K-37 all edit the bridge. Landing them without a drift ledger means the first
   Mob bump is a rewrite.
3. **K-03 blocks all data work.** If the Ash spike fails, K-21, K-30 and every resource in
   seven domains change shape. Do it in week one, not month three.
4. **K-04 blocks K-13** (`ex_cldr`'s `:default_backend` is Application env) **and K-15** (the
   tz database is configured the same way) **and K-20** (recurrence expands in a timezone).
5. **K-15 blocks K-20 blocks K-21 blocks K-23/K-26/K-27/K-37.** The timezone database is the
   quiet root of the entire calendar tree. Nobody would guess it.
6. **K-06 blocks K-08, K-17 and K-19.** You cannot build a component library, a tab bar or an
   accessibility story against a surface language you haven't proven renders.
7. **K-30 must land before the media resources are written**, not after. Same class of
   mistake as K-21's migration-1 columns.
8. **K-32 must precede every individual reminder feature** — TV, habits, calendar, money,
   health, meals. Built after, it becomes six retrofits.
9. **K-22 and K-25 should be resolved before K-21 and K-26 respectively**, because both change
   storage shape rather than behaviour.
10. **K-33 and K-29 gate scope, not code.** Resolve them in the first week; they decide how
    big v1 is and what the About screen says.
11. **K-02 is calendar-driven, not dependency-driven.** Play's API-36 deadline is 2026-08-31.
    It is the only ticket with an external clock.

### Suggested first five

K-01 → K-03 → K-05 → K-06 → K-15. The first three unblock; K-06 tells you whether the design
is buildable as drawn; K-15 unblocks the calendar, which is the spine.

---

## 4. The fog

Things that clearly matter, that no stream has phrased as a question yet.

**F-a · Health and money have had zero research.** Screens 42–52 are eleven screens — a meal
planner with a repeating week, a portion multiplier that live-rescales six macro figures and
five ingredient rows, a shopping list grouped by aisle/meal, plan profiles with "switch takes
effect next Monday", QR plan sharing and "Print the week (PDF, fridge-sized)". Screen 23 is a
subscription ledger denominated in £ with cost-per-watched-hour — the app's **strongest single
idea**, per the competitive read. Nothing has been researched: no nutrition data source, no
recipe model, no currency handling, no PDF path (Mob has none). These are ~20% of the app.

**F-b · Search (screen 19) has no mechanism.** One query across Screen, Calendar and Notes with
the match highlighted and scope counts. That is FTS5 territory, and nothing establishes whether
AshSqlite/ecto_sqlite3 can reach SQLite's FTS5 virtual tables, or whether Kati hand-rolls it.

**F-c · The relationship between Kati and Mishka Chelekom is undefined.** Kati is a consumer of
a library the owner also maintains, whose Mob layer is `0.0.10-alpha.6`, isn't in the hex
package, has 13 undocumented components, and whose `:anchored` story is broken for every
consumer. K-17 asks a piece of this; the whole is bigger — does Kati drive Mishka's Mob
roadmap, fork it, or vendor once and walk away?

**F-d · How Kati proves anything on a device in CI.** `Mob.Test` runs over Erlang distribution
— which K-01 strips from release builds. Mishka's answer is 52 Compose UI tests via
`androidTest`. Kati's tiers 1 and 2 (`Mob.ScreenCase`, `assert_renderable`) run on the host and
**structurally cannot see** the `:anchored` class of bug. There is no stated testing strategy
for the layer where the bugs actually live.

**F-e · Velocity.** 62 screens × 7 domains × 2 languages × 2 platforms, solo, with an RRULE
engine, a sync engine, a native RTL pass, a component library and a Kotlin plugin all on the
critical path. No stream has costed the whole. The right first move is probably not a plan but
a **vertical slice** — one domain, end to end, both languages, on a real phone — measured, and
then multiplied.

**F-f · What happens when the platform says no.** `design-index.md` §7 lists 25 things that are
hard or impossible for a declarative toolkit. Twelve are marked "almost certainly out of reach
without native escape hatches" — widgets, lock screen, Siri, share extension, scrobbling,
background sync, two-way calendar sync, camera/photos, mic, PDF, Sign in with Apple, glass.
**None has been costed, and there is no process for retiring a drawn screen.** K-06, K-19, K-35
and K-36 each poke at one corner. The missing thing is the owner-side ritual: how does a screen
get downgraded from "designed" to "not in v1" without the design losing coherence?

**F-g · Onboarding and first-run as a product flow.** Screens 26, 38, 53 and 37 are drawn but
the sequencing is implied, not specified — language choice before section choice, notification
loudness chosen *before* the OS prompt (a genuinely good idea), "import from a backup instead"
as an alternative first path, and a CSV importer with named sources that doesn't exist yet.

**F-h · Whether the design's warmth survives Material 3.** Everything Mob renders on Android
goes through Compose's Material components — `LinearProgressIndicator`, `NavigationBar`,
`Scaffold`, the ripple, the default typography. Kati's identity is paper, warm ink shadows,
cream cards, and *"ink is the only button colour"*. K-06 asks about shadows specifically; the
broader question — how much Material leaks through, and does it read as Kati — has no owner.

---

## 5. The three biggest risks

### Risk 1 — The forked native shell, with no upgrade path, on a fast-moving upstream

Kati's plan requires editing `MobBridge.kt` for **at least six** independent reasons: RTL
(K-12), Material Symbols coverage (K-07), `on_long_press` (K-17), `ACTION_CREATE_DOCUMENT`
(K-37), quite possibly shadows and blur (K-06), and possibly `MobAnchored`. Each is permanent.

The evidence that this compounds:

- *"Mob ships zero host-app Kotlin / Swift today; every app's `MobBridge` is its own diverged
  copy"* — Mob's own troubleshooting guide, `troubleshooting.md:481-487`.
- `mob/PLAN.md:2383-2420`: *"When Mob adds a feature that needs Kotlin support … every app has
  to be patched independently. When a Kotlin-side bug is fixed in one app … the fix doesn't
  propagate. This is sustainable while there are ~2 Mob apps. **It will become a real problem
  at ~10.**"* Three candidate fixes are listed; **none is implemented.**
- **There is no `mix mob.upgrade`** — all 46 `mob_dev` mix tasks enumerated, no resync, no
  bridge diff. `mix mob.deploy --native` rebuilds but does not re-render templates.
- Upstream cadence: **62 releases in ~3 months**, a patch every 1–3 days, and **v0.7.0 was a
  hard breaking change with no compat shims** (Camera, Location, Notifications, Photos,
  Biometric, Scanner, Bluetooth and themes all moved out of core; v0.7.3 removed
  `Mob.Background`).
- The failure mode is silent, not loud: a widget added in Mob 0.8 has no arm in a 0.7-era
  bridge, and the dispatch `when` has **no `else`** — the node is simply dropped
  (`MobBridge.kt.eex:2255-2258`). The Canvas coordinate-scaling drift is the shipped example:
  correct-looking code, wrong output, no error.

**Mitigation is K-05 and it is cheap relative to the exposure**: commit `android/`+`ios/` as
vendored code with a generated-from header, fence every Kati edit with comment markers, script
the three-way diff against a freshly generated throwaway app, and pin `{:mob, "== 0.7.x"}`
rather than `~> 0.7`.

### Risk 2 — The design was drawn against a platform that cannot render parts of it, and nobody has counted which parts

This is the risk most likely to be discovered late and to hurt most when it is.

- **Shadows.** The elevated card recipe has **262 uses** — the most repeated recipe in 825 KB —
  and there are **47 distinct shadow strings**. `Mob.Theme`'s struct carries colours, spacing,
  type scale, radii and `glass: false`. **No shadow token.** If the bridge has no elevation
  prop, the design's core surface treatment has no rendering path.
- **Blur.** **23 `backdrop-filter` declarations** at `blur(14/20/22px)` — on the tab bar of
  every root screen and all four lock-screen widgets. Mob has no blur. `design-index.md:407`
  already flags it: *"This is real backdrop sampling, not a translucent fill."*
- **Icons.** **673 icon spans**, with the active-tab state expressed as
  `font-variation-settings:'FILL' 1`. The bridge maps **10 icons**.
- **Accessibility.** Screen 41 renders the densest card at **235% Dynamic Type** with "nothing
  truncates" and quotes a literal VoiceOver utterance. Mob's accessibility is "partial … no
  uniform coverage, no focus management, no reduce-motion, no screen-reader announcements", and
  **`Image`'s `description` prop is the only a11y hook in the entire bridge**.
- **Whole surfaces are out of scope by Mob's own admission** — home-screen widgets (screens 29,
  39) and share extensions are listed as explicitly out of scope on both platforms; shimmer
  (screen 27) is structurally impossible (*"the host provides no time uniform … a full render
  plus a NIF call at 60 Hz, per placeholder"*).
- `design-index.md` §7 lists **25 hard-or-impossible items**. **Zero have been costed.**

The design is excellent, and its excellence is the risk: it is specific enough that shipping
something visibly less specific will read as failure. K-06 and K-19 are the probes; the real
mitigation is F-f — a ritual for retiring a drawn screen deliberately rather than by attrition.

### Risk 3 — Kati is first-in-the-world on its data layer, three levels deep into pre-1.0, single-maintainer dependencies

Every layer under Kati is early and thinly used, and the layers compound.

- **Mob:** *"Status: Early development"*, *"not yet ready for production use"*, 181 stars,
  ~52 downloads/week, **one maintainer**, and the author's own forum words: *"probably lots
  wrong"*, *"an awful lot of surface area that needs fleshed out."*
- **The data layer:** **no public evidence anyone has run AshSqlite on a device BEAM.**
  `mob_ash` has 176 downloads and 0 stars; Mob's 34 guides contain **zero Ash mentions**,
  including `data.html`; the announcement forum thread has none. Every version and code path in
  the research is verified; **nothing about runtime behaviour on a phone is.**
- **The component layer:** `mishka_chelekom` Mob is `0.0.10-alpha.6`, **`priv/mob` isn't in the
  hex package at all** (so no consumer can generate components from hex today), master carries
  two path deps that break git resolution, 13 components ship with no docs, and its
  `:anchored` node type — used by the entire dropdown family — **exists only in the demo app's
  own Kotlin** and renders nothing for any consumer.
- **The calendar layer:** `ex_cldr_calendars_persian` has **1,808 lifetime downloads**, and the
  research explicitly says *"treat every output as suspect until checked against a published
  Iranian calendar table"* — two verified data points is not a test suite. And there is **no
  RRULE engine at all** to depend on.
- **The docs actively mislead in ways that would change your architecture.** Three examples the
  research caught: *"navigation is process-based… that screen's process is still running"*
  (false — one process, S-29); *"the supervisor restarts it"* (false — no supervisor, S-32);
  `tab_bar/1` *"renders as a bottom NavigationBar"* (false — renders nothing, S-31). Mob's own
  agentic-coding guide admits the docs *"go stale fast."*

**The consequence is not that any single dependency fails. It is that every bug is Kati's to
diagnose, with no Stack Overflow answer, no second user to compare against, and — for the data
layer — no prior art at all.** The honest mitigations are the ones already in the plan: the
K-03 spike in week one with explicit abort criteria; keeping `lib/kati/**` free of `Mob.*` so
~90% of the suite runs on the host; pinning exact versions; and F-e's vertical slice, measured,
before committing to 62 screens.

---

*Written 2026-08-17 against: mob 0.7.20 · mob_new 0.4.20 · mob_dev 0.6.23 · mob_ash 0.1.1 ·
ash 3.31.3 · ash_sqlite 0.2.17 · mishka_chelekom 0.0.10-alpha.6 · ex_cldr 2.47.*
