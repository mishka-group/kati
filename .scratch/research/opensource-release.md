# Kati — Open-source release, store compliance, secrets, licensing, release engineering

Research date: **2026-08-17**. Everything below was checked against primary sources
(Google/Apple/F-Droid/TMDB docs, and the actual Mob source on this machine) on that date.
Store policy dates move; re-verify anything with a deadline before you act on it.

**Source provenance for Mob file citations.** Mob ships only on Hex, so "the source" means
the extracted Hex tarballs. I extracted:

| Tarball | Extracted to | Cited as |
|---|---|---|
| `~/.hex/packages/hexpm/mob-0.7.20.tar` | `…/scratchpad/mob720/` | `mob/…` |
| `~/.hex/packages/hexpm/mob_dev-0.6.23.tar` | `…/scratchpad/mobdev/` | `mob_dev/…` |
| `~/.hex/packages/hexpm/mob_new-0.4.20.tar` (`VERSION` = 3) | `…/scratchpad/mob_new/` | `mob_new/…` |

(`…/scratchpad` = `/private/tmp/claude-501/-Volumes-Fast-Arise-Resource-AI-book/c5718512-beef-4e2f-bbc9-14f1d94a1350/scratchpad`.
That directory is session-scoped and will disappear; re-extract with
`tar xf ~/.hex/packages/hexpm/mob-0.7.20.tar -C dir && tar xzf dir/contents.tar.gz -C dir`.)

Read alongside `mob-framework.md` (Mob internals), `design-index.md` (the 62 screens),
`mishka-mob-index.md`. This document does **not** repeat those; it cites them.

---

## 0. The five things that will actually stop the release

Ranked by "how close is this to killing a submission", not by section order.

| # | Finding | Severity | Where |
|---|---|---|---|
| 1 | Generated `build.gradle` pins `targetSdk 35`. Google Play requires **API 36 for all new apps and updates from 2026-08-31** — 14 days from today. | **Blocking, imminent** | §1.1 |
| 2 | Generated app calls `Mob.Dist.ensure_started(… cookie: :mob_secret)` unconditionally, and **nothing sets `MOB_RELEASE` on Android**, so an Android release build still tries to start Erlang distribution with a public cookie. iOS is correctly guarded; Android is not. | **Blocking (security), also a 2.5.2 risk if ever ported to iOS unguarded** | §1.7, §2.3 |
| 3 | `mix mob.release --android` stages **only `arm64-v8a`** OTP, but `build.gradle` declares three ABIs. Play will generate `armeabi-v7a` and `x86_64` splits that cannot boot. | **Blocking** | §1.4 |
| 4 | `UIBackgroundModes: [audio]` ships in every generated `Info.plist`. Apple rejects under 2.5.4 when no audible background content exists. | **Blocking on iOS** | §2.2 |
| 5 | Mob emits **no `PrivacyInfo.xcprivacy`** anywhere. The BEAM calls `stat`/`fstat`/`mach_absolute_time`; App Store Connect returns ITMS-91053 on upload. | **Blocking on iOS** | §2.4 |

And the one that is *not* blocking but is the answer to the question you flagged as existential:

> **An embedded BEAM running bundled `.beam` files does not violate guideline 2.5.2.**
> Hot code loading *from the network* does. Mob already compiles the distribution/EPMD
> surface out of iOS release builds. See §2.3 for the full argument and the caveats.

---

## 1. Google Play — requirements for a BEAM-on-device app

### 1.1 Target API level — the immediate problem

Play Console Help, *Target API level requirements for Google Play apps*
(<https://support.google.com/googleplay/android-developer/answer/11926878>):

- **2025-08-31**: app updates must target Android 15 (API 35) or higher.
- **2026-08-31**: "New apps and updates … must target Android 16 (API level 36) or higher",
  except Wear OS / Automotive (API 35) and Android TV / XR (API 34).
- Extension available on request to **2026-11-01**.
- Existing apps below the bar "become unavailable to new users on newer Android devices" —
  they are not removed, they stop appearing in search/install for those users.

Mob generates:

```groovy
# mob_new/priv/templates/mob.new/android/app/build.gradle.eex:31
    compileSdk 35
# :42-43
        minSdk 28
        targetSdk 35
```

So a fresh `mix mob.new` app is **one API level short as of 2026-08-31**. This is app-owned
file territory (the whole `android/` tree is copied at generation, per
`mob_new/decisions/2026-06-17-android-16kb-page-size.md` — "The `build.zig` is app-owned
(copied at generation), so **existing** apps need the flag added to their own …"), so you
bump it yourself; you do not wait for a Mob release.

**What bumping to 36 costs you** (from <https://developer.android.com/about/versions/16/behavior-changes-16>):

| Change at targetSdk 36 | Impact on Kati |
|---|---|
| Edge-to-edge is mandatory: "`R.attr#windowOptOutEdgeToEdgeEnforcement` is deprecated and disabled, and your app can't opt-out" | Must verify Mob's Compose host handles insets. `design-index.md` §7 already lists this class of problem. **Verify on a device before you ship.** |
| Predictive back on by default; "`onBackPressed` is not called and `KeyEvent.KEYCODE_BACK` is not dispatched anymore" | Mob's nav stack (`mob/lib/mob/nav/`) intercepts back. If it uses `onBackPressed`, back navigation silently dies. **This is the highest-risk item in the bump.** Temporary escape: `android:enableOnBackInvokedCallback="false"`. |
| Orientation/resizability/aspect-ratio restrictions ignored on displays ≥600dp | Kati's design is portrait-phone. On tablets/foldables it will be stretched. Temporary opt-out property `android.window.PROPERTY_COMPAT_ALLOW_RESTRICTED_RESIZABILITY` — but "won't apply when targeting API level 37+". |
| `elegantTextHeight` deprecated and ignored — affects **Arabic** and other complex scripts | Persian (Arabic script) line metrics change. Given `design-index.md:298-322` says Persian "rides a taller line-height (`1.4` observed vs `1.5`/`1.55`)", **re-measure the Vazirmatn RTL screens after the bump**. |
| Local network permission (`NEARBY_WIFI_DEVICES`) — currently opt-in, "will be enforced between 25Q2 and 26Q2" | Directly relevant to §5.3 device-to-device transfer over LAN. Plan for it. |

The `minSdk 28` (Android 9) default is fine and generous; nothing forces it up.

### 1.2 64-bit

Required since **2019-08-01** for new apps and updates; since **2021-08-01** Play does not
serve 32-bit-only native apps
(<https://android-developers.googleblog.com/2019/01/get-your-apps-ready-for-64-bit.html>).

Mob is compliant by construction — `abiFilters 'arm64-v8a', 'armeabi-v7a', 'x86_64'`
(`build.gradle.eex:47`) includes two 64-bit ABIs. See §1.4 for why that list is
nonetheless wrong for Kati.

### 1.3 AAB, Play App Signing, size

- **AAB mandatory** for new apps since **2021-08**
  (<https://android-developers.googleblog.com/2020/11/new-android-app-bundle-and-target-api.html>).
  APK upload is grandfathered only for apps created before then. Kati is new → AAB only.
- AAB implies **Play App Signing** — you upload signed with an *upload key*, Google
  re-signs with the *app signing key*. Mob's tooling assumes exactly this:
  `mob_new/priv/templates/mob.new/android/app/build.gradle.eex:12-18` —
  *"Upload-key signing for Play release builds. Loaded from android/keystore.properties
  (gitignored, holds the passphrases; generated by `mix mob.setup.google_play`)."*
- **Size ceiling: 200 MB compressed download per device** from an app bundle
  (<https://support.google.com/googleplay/android-developer/answer/9859152>).
  This is the number to watch: `mix mob.release --android` prints
  `"#{info.zipped_files} files, …MB → …MB"` for `assets/otp.zip`
  (`mob_dev/lib/mob_dev/release_android.ex:44-47`). **UNKNOWN**: Mob's docs give no
  baseline app size. Measure it on the first real release build. `mix mob.enable pythonx`
  (+~70 MB) and `mlx` (+~30 MB) are the two things that would blow the budget; Kati needs
  neither.

Note that Mob deliberately fights AAB's default packaging:

```groovy
// mob_new/…/android/app/build.gradle.eex:91-101
    packagingOptions {
        jniLibs {
            // The BEAM dlopens the app's lib<app>.so by absolute path and execs
            // inet_gethost/erl_child_setup/epmd as real processes — they must be
            // extracted to the filesystem. AGP defaults release App Bundles to
            // extractNativeLibs=false (libs stay packed in the APK), which makes
            // the BEAM's dlopen fail with "library not found" on a Play-installed
            // split. useLegacyPackaging=true forces extraction.
            useLegacyPackaging true
        }
    }
```

This is correct and necessary for the BEAM, but it is the *opposite* of what Google
recommends for install size and for 16 KB alignment checking (`zipalign -P 16` only
applies to uncompressed libs). Don't "fix" it. See §1.5.

### 1.4 ABI mismatch — a real bug in the release path

`build.gradle.eex:47` declares three ABIs. But the Android release pipeline stages **one**:

```elixir
# mob_dev/lib/mob_dev/release_android.ex:37
         {:ok, otp_arm64} <- MobDev.OtpDownloader.ensure_android("arm64-v8a"),
```

and `MobDev.OtpAssetBundle` builds a single `assets/otp.zip` from that arm64 tree
(`mob_dev/lib/mob_dev/otp_asset_bundle.ex:1-13`). `assets/` is not ABI-split, so the
`armeabi-v7a` and `x86_64` splits Play generates would ship arm64 BEAM files against a
32-bit/x86 ERTS.

**Recommendation:** set `ndk { abiFilters 'arm64-v8a' }` for release. arm64-only excludes
essentially nothing on Play in 2026 (32-bit-only Android devices are effectively gone; Play
has not required 32-bit since 2019), and it halves the bundle. If you later want x86_64 for
ChromeOS, the `otp.zip` staging has to become per-ABI first. Note also
`mob_new/lib/mob_new/ndk_version.ex:22` pins `@recommended "27.2.12479018"` and the comment
at `build.gradle.eex:33-38` explains why you cannot casually bump it (libc++ inline-namespace
ABI: NDK 27/clang 18 → `ne180000` vs NDK 25/clang 14 → `ne140000`; "Bumping this requires
rebuilding the OTP tarballs").

### 1.5 The 16 KB page-size requirement

Current official text
(<https://developer.android.com/guide/practices/page-sizes>):

> "Starting February 1, 2027, if your app updates don't support 16 KB memory page sizes,
> you won't be able to release these updates."

applying to apps targeting **Android 15 (API 35) and higher on 64-bit devices**. (Earlier
communications said 2025-11-01 and were extended; the Feb 2027 date is what the doc says
today. Play Console will warn well before it blocks.)

**Mob has already solved this, and documented it.** `mob_new/decisions/2026-06-17-android-16kb-page-size.md`:

> "Google Play now requires apps targeting Android 15+ to support 16 KB memory page sizes:
> every native `.so` LOAD segment must align to 16 KB (0x4000) … Io (livebook_mob) was
> approved on Play but flagged 'app does not support 16 KB memory page sizes'.
>
> Diagnosis (NDK `llvm-readelf -l <so>`, the LOAD `align` field): the prebuilt ERTS binaries
> shipped as `lib*.so` (beam_smp, epmd, inet_gethost, …) were already 0x4000 from the OTP
> NDK build. Only the two libs the app's `build.zig` links itself — `lib<app>.so` and
> `libsqlite3_nif.so` — were at 0x1000.
>
> **Decision:** Add `-Wl,-z,max-page-size=16384` to both NDK-clang `-shared` link steps…"

Verified present in the template:

```
mob_new/priv/templates/mob.new/android/app/src/main/jni/build.zig.eex:605
mob_new/priv/templates/mob.new/android/app/src/main/jni/build.zig.eex:753
    run.addArg("-Wl,-z,max-page-size=16384");
```

Two caveats:

1. **Mob sets only `max-page-size`. Google's doc, for "NDK r27 and lower", says to pass
   both**: `-Wl,-z,max-page-size=16384 -Wl,-z,common-page-size=16384`. Mob pins NDK
   `27.2.12479018` — r27. In practice `max-page-size` is what governs LOAD-segment
   alignment and Mob's own verification (`llvm-readelf -l <so> | awk '/LOAD/{print $NF; exit}'`
   → `0x4000`) passes, so this is probably cosmetic. **I could not confirm from a primary
   source that omitting `common-page-size` is safe — treat as UNKNOWN and just add it.**
2. The decision doc's own warning applies to Kati directly:

   > "Third-party prebuilt `.so` (e.g. androidx.camera's `libimage_processing_util_jni`,
   > ML Kit's `libbarhopper_v3`) can't be relinked — they must be removed (drop the dep) or
   > bumped to a 16 KB-aligned version."

   The template already pulls in CameraX (`build.gradle.eex:131-133`) and Media3 ExoPlayer
   (`:138-139`) that Kati does not need. **Delete the deps Kati doesn't use** — it removes
   both a 16 KB risk and a chunk of the 200 MB budget.

Verify before every release:
```bash
llvm-readelf -l lib<app>.so | awk '/LOAD/{print $NF; exit}'   # expect 0x4000
zipalign -c -P 16 -v 4 app.apk                                 # only meaningful if uncompressed
```

### 1.6 Permissions — what Kati must declare, and what Play will ask about

Generated manifest (`mob_new/priv/templates/mob.new/android/app/src/main/AndroidManifest.xml.eex`):

| Line | Permission | Kati verdict |
|---|---|---|
| 6 | `INTERNET` | Keep (TMDB/Trakt/Google). |
| 9 | `ACCESS_NETWORK_STATE` | Keep — normal, install-time. |
| 13 | `RECORD_AUDIO` | **Delete.** Kati records no audio. A dangerous permission with no feature behind it invites review questions and hurts the data-safety story. |
| 19 | `<uses-feature android.hardware.usb.host required=false>` | Delete. |
| 24 | `<uses-feature android.hardware.camera.flash required=false>` | Delete (unless the barcode-scan-a-book flow needs torch). |
| 34 | `RECEIVE_BOOT_COMPLETED` | **Keep — mandatory.** Per `mob-framework.md:1167` and the `MobBridge.kt` source header: *"AlarmManager alarms are wiped on reboot, so scheduled notifications silently vanish."* `MobNotifyBootReceiver` re-arms from `SharedPreferences`. Without it every Kati reminder dies at reboot. Normal permission, no user prompt, no Play declaration. |
| 35-36 | `SCHEDULE_EXACT_ALARM` (`minSdkVersion="31"`) | **Replace with `USE_EXACT_ALARM` — see below.** |
| 39 | `VIBRATE` | Keep if haptics are used. |

`POST_NOTIFICATIONS` is **not** in the host manifest — the comment at line 31 says it
"moved to the mob_notify plugin manifest", merged at build. Android 13+ requires it and it
is a *runtime* permission: `Mob.Permissions.request(socket, :notifications)`. The
`mob_notify` README warning quoted in `mob-framework.md:1199` — *"An unauthorized iOS app
drops scheduled notifications silently — request `:notifications` before scheduling"* —
applies equally in spirit on Android 13+.

#### `SCHEDULE_EXACT_ALARM` vs `USE_EXACT_ALARM` — Kati qualifies for the better one

<https://developer.android.com/develop/background-work/services/alarms/schedule>:

| | `USE_EXACT_ALARM` | `SCHEDULE_EXACT_ALARM` |
|---|---|---|
| Grant | automatic at install | user grants via a Settings screen |
| Revocable | no | yes, by user and by system |
| Play policy | restricted to specific use cases | broader |

And Android 13+: `SCHEDULE_EXACT_ALARM` "is **not** pre-granted to fresh installs"; on
Android 14 a backup-and-restore transfer leaves it **denied**.

Play's own eligibility text for `USE_EXACT_ALARM`
(<https://support.google.com/googleplay/android-developer/answer/16558241>):

> "The app is an alarm or timer app. The app is a calendar app that shows event
> notifications."

**Kati is a calendar app that shows event notifications** (`design-index.md` screens 02, 09,
31, 52 — the calendar is a fixed nav root). It qualifies. Switch to `USE_EXACT_ALARM` and
complete the Play Console declaration. Payoff: no Settings deep-link dance, no silent
degradation to inexact alarms, survives restore.

This matters concretely because of what Mob does when the permission is missing
(`mob-framework.md:1140-1152`):

```kotlin
when {
  canExact && SDK_INT >= 23 -> am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMs, pi)
  canExact                  -> am.setExact(AlarmManager.RTC_WAKEUP, triggerAtMs, pi)
  SDK_INT >= 23             -> am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMs, pi)
  else                      -> am.set(AlarmManager.RTC_WAKEUP, triggerAtMs, pi)
}
```

— it falls back to inexact **silently**. "Your show starts now" drifts by minutes.

Keep declaring `SCHEDULE_EXACT_ALARM` too, guarded to `maxSdkVersion="32"`, so Android 12
devices still get exact alarms (`USE_EXACT_ALARM` only exists from API 33).

#### Battery-optimisation exemption — don't

`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` / `ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`.
Google's own guidance (<https://developer.android.com/training/monitoring-device-state/doze-standby>)
is that Play policy prohibits requesting direct Doze/App-Standby exemption "unless the core
function of the app is adversely affected", and misuse risks suspension. Kati does not need
it: exact alarms already use `setExactAndAllowWhileIdle`, which fires through Doze. **Do not
add it.** If you ever do, expect to justify it in review.

#### Foreground service types

Android 14+ requires `android:foregroundServiceType` on every foreground service; missing
type → `MissingForegroundServiceTypeException` at `startForeground()`, missing matching
`FOREGROUND_SERVICE_*` permission → `SecurityException`
(<https://developer.android.com/about/versions/14/changes/fgs-types-required>).
Play additionally requires a declaration in Console → Policy → App content, with
"a link to a video demonstrating each foreground service feature"
(<https://support.google.com/googleplay/android-developer/answer/13392821>).

Kati's position: **it should have no foreground service at all.** The only path to one is
`MobBackground.keep_alive/0`, which `mob-framework.md:1055-1070` documents as mapping to an
Android foreground service with a permanent notification. `mob_background` is an opt-in
plugin removed from core in v0.7.3 — just don't add it. Scheduled notifications go through
`AlarmManager` + `NotificationReceiver`, which needs no service. If two-way Google Calendar
sync later needs periodic work, the type would be `dataSync` +
`FOREGROUND_SERVICE_DATA_SYNC`, and Android 15 imposes a 6h/24h budget on `dataSync` —
another reason to sync on app open instead.

#### Calendar permissions

`READ_CALENDAR` / `WRITE_CALENDAR` are runtime "dangerous" permissions in the Calendar
group. **Kati owns its own calendar** (locked decision) and syncs with Google via the
**Google Calendar REST API over OAuth**, not the on-device `CalendarContract` provider.
That is the right call and it means **Kati never declares `READ_CALENDAR`/`WRITE_CALENDAR`**
— which keeps it out of the Calendar-permission policy surface and out of the "Calendar"
data-safety category (§6.1). If you ever switch to the local provider to pick up *all*
device calendars, you take on the runtime permission, the data-safety Calendar disclosure,
and an in-app prominent-disclosure requirement. Note `Mob.Permissions` has **no `:calendar`
atom** (`mob-framework.md:661-665` lists `:camera, :microphone, :photo_library, :location,
:notifications` only) — so the local-provider route would need a native extension anyway.

#### Full-screen intents

<https://support.google.com/googleplay/android-developer/answer/13392821>:
"starting January 22, 2025, for apps targeting Android 14+, only apps that have calling or
alarm functionalities will have this permission enabled by default." Kati's alarm
functionality plausibly qualifies, but Mob has no full-screen-intent API and Kati's design
(`design-index.md`) has no full-screen alarm screen. **Don't declare `USE_FULL_SCREEN_INTENT`.**

### 1.7 Distribution left on in Android release builds — security bug

`mix mob.new` generates, in the app's `start/0`:

```elixir
# mob_new/priv/templates/mob.new/lib/app_name/app.ex.eex:34
    Mob.Dist.ensure_started(node: :"<%= app_name %>_android@127.0.0.1", cookie: :mob_secret)
```

`Mob.Dist.ensure_started/1` short-circuits only when `MOB_RELEASE=1` is in the environment
(`mob/lib/mob/dist.ex:61-68`, `:108-110`). On iOS that env var is set by the C launcher in
release builds:

```c
// mob/ios/mob_beam.m:414-419  (#else branch of  #ifndef MOB_RELEASE)
    // Mark MOB_RELEASE in env so Mob.Dist.ensure_started/1 short-circuits
    setenv("MOB_RELEASE", "1", 1);
```

**On Android, nothing sets it.** `grep -rn "MOB_RELEASE" mob720/android/ mob_new/priv/templates/mob.new/android/`
returns nothing. So a `bundleRelease` AAB still enters the `:android` branch
(`mob/lib/mob/dist.ex:73-105`) and spawns a process that, after 3 s, waits for EPMD.

What saves you today is `start_after/4` (`mob/lib/mob/dist.ex:178-220`):

```elixir
    case wait_for_epmd(10_000) do
      :ready -> … :application.set_env(:kernel, :start_epmd, false) …
                  Node.start(node, :longnames); Node.set_cookie(cookie)
      :timeout -> :mob_nif.log("Mob.Dist: no EPMD on port 4369 after 10s -- skipping dist …")
```

With no `adb reverse tcp:4369`, EPMD never appears and distribution is skipped. **But the
door is unlocked, not closed:** any other app on the same device can bind `127.0.0.1:4369`,
at which point Kati's BEAM starts distribution on port 9100 with the **hardcoded, public,
open-source cookie `:mob_secret`** — full remote code execution inside Kati's sandbox and
therefore full access to the SQLite database and any stored OAuth tokens. Note also that
`epmd` is shipped into release AABs as `jniLibs/<abi>/libepmd.so`
(`mob_dev/lib/mob_dev/otp_asset_bundle.ex:36-39`: *"The few that Mob actually executes
(`erl_child_setup`, `inet_gethost`, `epmd`) are packaged separately in `jniLibs/<abi>/` as
`lib<name>.so`"*).

**Fix, in Kati's own code, before first release:**

```elixir
# lib/kati/app.ex
if Mix.env() != :prod, do: Mob.Dist.ensure_started(node: …, cookie: dev_cookie())
```

or gate on a runtime flag you set yourself. Also delete `libepmd.so` from the release
`jniLibs` if nothing else needs it. **Do not** ship `:mob_secret` in a public repo's
release path — an open-source app makes this cookie a published credential.

Report this upstream; it is a framework-level defect, not a Kati one.

### 1.8 A note on `allowBackup="false"`

`AndroidManifest.xml.eex:64` sets `android:allowBackup="false"`. Good for privacy (Kati's
SQLite DB never lands in Google's cloud backup), bad for users (a phone upgrade loses
everything). This makes §5 — a working export/backup — a **product requirement, not a nice
to have.** Say so in the store listing.

---

## 2. Apple — the iOS questions

### 2.1 What Mob's iOS build actually is

`mob_dev/lib/mob_dev/release/otp.ex:23-28` gives the cross-compile matrix:

| Target | xcomp-conf | SSL |
|---|---|---|
| android_arm64 | `xcomp/erl-xcomp-arm64-android.conf` | `--with-ssl=<prefix> --disable-dynamic-ssl-lib` |
| ios_sim | `xcomp/erl-xcomp-arm64-iossimulator.conf` | `--without-ssl` (the conf sets `--enable-static-nifs`; "OTP doesn't propagate `--with-ssl` to **beam.emu**'s link in that mode") |
| ios_device | `xcomp/erl-xcomp-arm64-ios.conf` | same |

Two facts fall out of that table and they are the load-bearing facts for the whole iOS story:

1. **iOS runs `beam.emu` — the bytecode interpreter, not BeamAsm.** OTP's own docs say the
   JIT is disabled either "by passing `--disable-jit` to configure" or by building
   `FLAVOR=emu` (<https://www.erlang.org/doc/apps/erts/beamasm.html>). iOS forbids
   third-party JIT: generating executable pages with an invalid code signature "is usually
   prohibited on iOS for third-party apps", requiring the `dynamic-codesigning` entitlement
   Apple grants only to system processes (<https://saagarjha.com/blog/2020/02/23/jailed-just-in-time-compilation-on-ios/>).
   A JIT-enabled BEAM would simply crash on device. Mob's use of `beam.emu` removes the
   problem — and removes an entire category of App Review argument.
   **Caveat: I found no explicit `--disable-jit` flag in `mob_dev`.** The `beam.emu` name in
   the docstring is strong but indirect evidence. `grep -rn "jit" mob720/ mobdev/ mob_new/`
   returns nothing. **Verify** on your first device build (`erl -emu_flavor` / check the
   linked binary) before you rely on it.
2. **NIFs are static.** `mob-framework.md:492-495`: *"Static linking is mandatory, not a
   preference: 'iOS App Store rejects bundled `.dylib`; Android `RTLD_LOCAL` hides the
   parent's `enif_*` symbols.' On physical iOS, `dlopen` of `.so` files fails **silently**."*
   Nothing is loaded from outside the signed bundle at runtime.

### 2.2 `UIBackgroundModes: [audio]` — remove it

```xml
<!-- mob_new/priv/templates/mob.new/ios/Info.plist.eex:33-36 -->
    <key>UIBackgroundModes</key>
    <array>
        <string>audio</string>
    </array>
```

Apple rejects this under **2.5.4 (Multitasking)** — "Multitasking apps may only use
background services for their intended purposes: VoIP, audio playback, location, task
completion, local notifications, etc." (<https://developer.apple.com/app-store/review/guidelines/>).
The rejection wording seen in the wild is that the app "declares support for audio in the
`UIBackgroundModes` key … but does not play audible content while in the background"
(e.g. <https://github.com/ryanheise/audio_service/issues/975>,
<https://developer.apple.com/forums/thread/95216>). Remedy per Apple: play real background
audio, or remove the key.

Mob's own guide already warns about this (`mob-framework.md:1047-1051`) and notes
`MobBackground.keep_alive/0` on iOS "works **only via the audio background mode**", with
Apple's expectation that "the declared background mode … match a user-visible app
capability."

**Kati action, in the app's own `ios/Info.plist`:**
- delete the `UIBackgroundModes` array entirely (:33-36);
- delete `NSMicrophoneUsageDescription` (:37-38) — no microphone feature;
- never call `MobBackground.keep_alive/0` on iOS.

Consequence you must design around: on iOS the app has **no** background execution.
Everything Kati needs while backgrounded must go through `UNUserNotificationCenter` local
notifications, which the OS owns once scheduled and which fire with the app dead
(`mob-framework.md:1175-1195`). Which surfaces three limits Mob does not document and which
hit a calendar/tracking app hard:

- Mob uses `UNTimeIntervalNotificationTrigger`, **not** `UNCalendarNotificationTrigger` —
  the delay is computed once at schedule time. Cross a timezone or change the clock and
  every reminder drifts off wall-clock.
- iOS caps **64 pending local notifications per app**, silently dropping the rest.
- `repeats: NO` always — no recurring notifications.

For Kati that means: no "pre-arm the year", re-arm on every foreground, and treat a native
extension for `UNCalendarNotificationTrigger` as a known iOS work item.

### 2.3 Guideline 2.5.2 — does an embedded BEAM with hot code loading risk rejection?

**Short answer: no for the BEAM; yes for hot code loading over the network. Mob already
disables the latter on iOS. Keep it that way and do not add it back.**

The guideline, verbatim (<https://developer.apple.com/app-store/review/guidelines/>):

> **2.5.2** Apps should be self-contained in their bundles, and may not read or write data
> outside the designated container area, nor may they **download, install, or execute code
> which introduces or changes features or functionality of the app**, including other apps.
> Educational apps designed to teach, develop, or allow students to test executable code
> may, in limited circumstances, download code provided that such code is not used for other
> purposes. Such apps must make the source code provided by the app completely viewable and
> editable by the user.

Read it precisely. The prohibited verbs are **download, install, execute code which
introduces or changes features**. The operative harm is *post-review mutation of app
behaviour*. Three consequences:

**(a) Interpreting bundled bytecode is not the prohibited thing.** Every Python, Lua, JS,
Ruby and .NET-interpreted app on the App Store executes bytecode that was not produced by
Xcode. `.beam` files inside a signed `.app` are reviewed, signed, immutable, and shipped —
functionally identical to `.pyc` in a Kivy/BeeWare bundle or `.lua` in a Corona game. There
is no reading of 2.5.2 under which a bundled `.beam` is "downloaded" or "installed". Apple's
actual rejection language is behavioural — *"During review, your app installed or launched
executable code, which is not permitted on the App Store"*
(<https://github.com/beeware/briefcase/issues/1655>) — i.e. the reviewer must *observe* the
app fetching or installing code. In that BeeWare case the trigger was an `itms-services:`
URL that installed another app, not the embedded Python interpreter.

**(b) The dangerous surface is Erlang distribution + `mix mob.push` / `nl/1` / `Code.eval_*`.**
`mix mob.push` "pushes changed `.beam` files, no restart" and `mix mob.connect` gives "a live
IEx attached to the on-device BEAM" (`mob-framework.md:700-712`). That is, exactly, downloading
and executing code that changes app functionality. If that channel were live in a shipped
build it would be a genuine 2.5.2 violation and, independently, a remote-code-execution hole.

**Mob's authors clearly understood this.** From the header of `mob/ios/mob_beam.m:22-27`:

> `MOB_RELEASE`: App Store builds (`mix mob.release`) drop EPMD entirely so the shipped
> binary has no distribution surface — Apple is unhappy with apps that listen on arbitrary
> network ports for remote-code-execution-shaped traffic, and TestFlight review may flag it.
> The BEAM still boots, the NIF still works, but the app is networkless from a distribution
> POV.

and the implementation:

```c
// mob/ios/mob_beam.m:401-413
#ifndef MOB_RELEASE
    // Distribution flags. Omitted for App Store builds — see MOB_RELEASE
    // notes at the top of this file.
    args[ac++] = "-name";        args[ac++] = node_name;
    args[ac++] = "-setcookie";   args[ac++] = "mob_secret";
    args[ac++] = "-kernel"; args[ac++] = "inet_dist_listen_min"; args[ac++] = dist_port_min;
    args[ac++] = "-kernel"; args[ac++] = "inet_dist_listen_max"; args[ac++] = dist_port_max;
#else
```

plus `#if defined(MOB_BUNDLE_OTP) && !defined(MOB_RELEASE)` around the whole EPMD thread
(`mob/ios/mob_beam.m:27-34`), and the debug/test-harness NIFs compiled out under
`#if !MOB_RELEASE` (`mob/ios/mob_nif.m:3442-3458`, `:5411`, `:5572`, `:6277`).
`mob_dev` is `only: :dev, runtime: false` in the generated `mix.exs`
(`mob_new/lib/mob_new/project_generator.ex:1133`), so the push/watch/connect tooling is not
even compiled into the app.

**(c) Kati's own obligations, to keep the argument airtight:**

1. Never ship a code-download feature. No fetching `.beam` from a server, no `Mob.Dist` OTA
   update session (`mob/lib/mob/dist.ex:148-166` documents exactly such a pattern — do not
   use it in a shipped build), no `Code.eval_string/2` or `:erlang.load_binary/3` on any
   network-derived input.
2. Ship `mix mob.release --ios`, never a debug build, so `MOB_RELEASE` is actually defined.
   Verify: `otool -L`/`strings` the shipped binary for `epmd`, and confirm no listener.
3. If you ever add a scripting/plugin feature, you have crossed the line. Don't.
4. Kati is not "an app that lets users write code", so the educational carve-out and the
   4.7 mini-app carve-out (HTML5/JS mini apps, plug-ins) are both irrelevant — you don't
   need them and shouldn't invoke them.

**Residual risk, stated honestly.** No public precedent exists of an Erlang/BEAM app being
approved or rejected on the App Store. `mob-framework.md` cites Io (livebook_mob) as
approved on **Play**, not the App Store. The nearest analogues (embedded CPython via
BeeWare/Kivy/Pythonista, Lua game engines) are approved routinely, and the structural
argument in (a) is strong. But **treat "an Elixir app has passed App Review" as UNVERIFIED**.
Mitigation: submit an early, deliberately boring TestFlight build and let review chew on it
before you have sunk months into iOS polish. Given "Android is the priority", this is cheap
insurance and it de-risks the existential question empirically.

### 2.4 Privacy manifest — a hard blocker Mob does not handle

`grep -rn -i "xcprivacy|PrivacyInfo|NSPrivacy" mob720/ mobdev/ mob_new/` → **zero matches.**

Since **2024-05-01**, uploading a new app or update requires an `NSPrivacyAccessedAPITypes`
array in a `PrivacyInfo.xcprivacy` giving approved reasons for "required reason" APIs
(<https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api>;
error codes ITMS-91053 / ITMS-91055,
<https://developer.apple.com/forums/thread/749940>).

The BEAM is guaranteed to trip at least these categories:

| Category | Triggered by | Reason code |
|---|---|---|
| `NSPrivacyAccessedAPICategoryFileTimestamp` | `stat`/`fstat` — used constantly by `:file`, code loading, SQLite | `C617.1` (app's own files) / `0A2A.1` |
| `NSPrivacyAccessedAPICategorySystemBootTime` | `mach_absolute_time` — OTP's monotonic clock | `35F9.1` |
| `NSPrivacyAccessedAPICategoryDiskSpace` | `statfs`/`statvfs` if reached | — |
| `NSPrivacyAccessedAPICategoryUserDefaults` | any `NSUserDefaults` in Mob's Swift/ObjC layer | — |

**Action:** hand-write `ios/PrivacyInfo.xcprivacy` for Kati, add it to the bundle, and set
`NSPrivacyTracking=false`, `NSPrivacyTrackingDomains=[]`, `NSPrivacyCollectedDataTypes=[]`
(local-only app). Also declare export compliance —
`ITSAppUsesNonExemptEncryption` in `Info.plist`. Note that iOS builds are `--without-ssl`
(§2.1), so Kati's own HTTPS on iOS goes through whatever Mob's networking layer uses; work
out which before answering the encryption question. **UNKNOWN / to verify.**

Report the missing privacy manifest upstream too — it affects every Mob app.

---

## 3. The open-source secrets problem

### 3.1 State the problem correctly first

There are **two different kinds of "credential"** in Kati's list and conflating them
produces bad advice.

| Kind | Examples | Is it actually secret? |
|---|---|---|
| **Shared API key** — identifies *your app* to a service, carries *your* quota | TMDB API key/read token; Trakt `client_id`; Trakt `client_secret` | Yes. Whoever holds it spends your rate limit and can get *you* banned. |
| **OAuth public-client identifier** — identifies the app during a user-consented flow; the user's token is the real credential | Google OAuth client ID (+ "secret") for an installed app | **No.** Google: *"Installed apps are distributed to individual devices, and it is assumed that these apps cannot keep secrets"* (<https://developers.google.com/identity/protocols/oauth2/native-app>). RFC 8252 classes native apps as public clients; PKCE is the security mechanism, not the secret. |

So for **Google Calendar**, stop worrying: ship the client ID, use **PKCE**, use a custom
URI scheme redirect (`com.example.kati:/oauth2redirect`) — Google explicitly deprecates the
loopback redirect on mobile. Nothing is leaked because nothing was secret. The real Google
problem is not the secret, it's **verification** (§3.4).

For **TMDB and Trakt**, the key is genuinely a shared secret and the APK is genuinely
decompilable (jadx/apktool; automated extractors exist —
<https://github.com/alessandrodd/apk_api_key_extractor>). There is no client-side
obfuscation that survives a determined attacker; every "hide your keys in Android" article
concludes the same thing.

### 3.2 What real open-source apps do

**SeriesGuide** (Uwe Trottmann) is the closest possible precedent: an open-source Android
TV/movie tracker on the Play Store built on **TMDB + Trakt**. Its
`CONTRIBUTING.md` (<https://github.com/UweTrottmann/SeriesGuide/blob/dev/CONTRIBUTING.md>):

> "To add shows or movies you need to create an API key for TMDB and OAuth credentials for
> Trakt."

placed in a gitignored `secret.properties` beside `settings.gradle`:

```
SG_TMDB_API_KEY=<your api key>
SG_TRAKT_CLIENT_ID=<your trakt client id>
SG_TRAKT_CLIENT_SECRET=<your trakt client secret>
```

i.e. **keys are never committed; contributors bring their own; the maintainer's keys live
only in his release environment.** (SeriesGuide also documents `google-services.json` for
Crashlytics and split-across-four-properties IAP keys — precisely the choices that keep it
off F-Droid; see §5.5.)

That pattern — build-time injection from an uncommitted properties file / CI secret — is the
overwhelmingly common answer across FOSS Android apps that need third-party keys. The
alternatives seen in the wild:

- **BYO key** (user pastes their own key in Settings). Used by many self-hosted/media tools.
  Zero risk to you; miserable onboarding for "everybody who wants to use it".
- **Backend proxy**. Correct, but you have locked "device-first with NO server".
- **Attestation-gated runtime secret delivery** (Approov and similar). Requires a server and
  money; out of scope.
- **No key at all** (NewPipe-style scraping). Violates Trakt's rule
  (<https://docs.trakt.tv/docs/create-an-app>): *"Use only documented API methods and please
  don't scrape the website for information."*

### 3.3 Recommendation for Kati

A three-tier arrangement. It is the only one that satisfies *open source*, *no server*, and
*works out of the box for a normal user* simultaneously.

**Tier 1 — official builds (Play, App Store, GitHub release APK): baked-in keys, injected at build time.**
- Keys live only in GitHub Actions repository secrets (`TMDB_API_KEY`, `TRAKT_CLIENT_ID`,
  `TRAKT_CLIENT_SECRET`, `GOOGLE_OAUTH_CLIENT_ID`).
- Injected into an uncommitted `config/secrets.exs` (or `System.get_env/1` read at compile
  time by a `Kati.Secrets` module) during the CI build; `.gitignore` the file.
- **Accept that these are extractable.** Design for it: separate keys per distribution
  channel so one bad actor doesn't burn all of them; monitor TMDB/Trakt dashboards; be ready
  to rotate. Do **not** obfuscate and call it security — obfuscation only buys time, and
  saying so in the README is more honest than a `StringCare`-style theatre that
  `DeStringCare` reverses in a minute.
- Document loudly in `CONTRIBUTING.md` that abusing the shipped keys gets the app banned for
  everyone.

**Tier 2 — contributor / from-source builds: BYO key, exactly SeriesGuide's model.**
- `config/secrets.exs.example` committed; real file gitignored.
- Build fails with a clear message naming the file and the signup URLs when a key is absent.

**Tier 3 — Settings → Advanced → "Use my own API keys".**
- Lets power users, F-Droid users, and anyone whose build has no keys paste their own.
- Persisted in the encrypted store from §6.3, not in plaintext SQLite.
- **This tier is what makes an F-Droid build possible at all** (§5.5) and what makes the
  "sharing in the network for other version" story defensible.

**Explicitly for Google:** ship the client ID in the clear, use PKCE + custom scheme, never
pretend the "client secret" is secret, and never use a *Web* OAuth client type (whose secret
*is* meant to be confidential) on device.

### 3.4 The Google OAuth landmine nobody mentions

Getting a Google Calendar client ID is easy. Getting it **verified** is the real cost.
`https://www.googleapis.com/auth/calendar` is a **sensitive** scope, so before Kati can go
past the 100-user unverified cap it must pass OAuth app verification
(<https://developers.google.com/identity/protocols/oauth2/production-readiness/sensitive-scope-verification>):

- **Brand verification** first — verified domain ownership, published branding, homepage;
  2–3 business days (<https://developers.google.com/identity/protocols/oauth2/production-readiness/brand-verification>).
- A **privacy policy prominently available from the app's homepage**, disclosing exactly how
  Kati accesses/uses/stores/shares Google user data.
- A **YouTube video (unlisted)** demonstrating how a user initiates and grants each scope
  and how each granted scope is used.
- Review against Google's API Services User Data Policy.

Practical consequences for an open-source, one-maintainer, no-server project:
- **You need a real domain and a real published homepage.** A GitHub repo alone is thin.
- **Request the narrowest scope.** `calendar.events` (or even `calendar.events.readonly` for
  a first release) rather than full `calendar`. Fewer scopes → shorter review.
- **Restricted scopes** (Gmail/Drive) additionally need an annual **third-party security
  assessment** by a Google-empanelled assessor. Calendar is *sensitive*, not *restricted*, so
  you avoid that — **do not** let scope creep drag you into Drive-for-backup, which would.
- Ship v1 **without** Google Calendar sync. Kati's calendar is its own (locked decision).
  Add the sync in v1.x once the app exists, the homepage exists, and the video can be
  recorded from a real build. This is the single biggest scheduling risk in the whole
  integration list and it is entirely front-loadable.

---

## 4. Licensing

### 4.1 What you're building on

| Component | Licence | Evidence |
|---|---|---|
| **Mob** 0.7.20 | **MIT** | `mob720/metadata.config:7` → `{<<"licenses">>,[<<"MIT">>]}`; `mob720/LICENSE` line 1 = "MIT License"; repo <https://github.com/genericjam/mob> |
| **Mishka Chelekom** 0.0.10-alpha.6 | **Apache-2.0** | `/Users/shahryar/Documents/Programming/Elixir/mishka_chelekom/mix.exs:120` → `licenses: ["Apache-2.0"]`; `mix.exs:4` version. Root `LICENSE` is the Apache text. **No `NOTICE` file exists.** |
| Elixir / Erlang-OTP | Apache-2.0 | upstream |
| exqlite / ecto_sqlite3 | MIT; SQLite itself is public domain | — |

### 4.2 Recommendation: **MIT**

Reasoning, in order of weight:

1. **Compatibility is not the constraint.** MIT and Apache-2.0 are both permissive and both
   inbound-compatible with either choice. Apache-2.0 code can be included in an MIT-licensed
   work provided the Apache terms are honoured for those files.
2. **Mob is MIT**, and Kati is structurally a Mob application. Matching the framework
   minimises friction for anyone reading the tree.
3. **MIT is the shortest thing a solo maintainer can correctly comply with.** Apache-2.0
   would give you an explicit patent grant and an explicit trademark clause — genuinely nicer
   for contributors — but it also imposes §4(b)/(c) obligations you'd have to actually
   perform on every derivative.
4. **Copyleft (GPL-3.0/AGPL) is a bad fit here**, for a reason specific to this project:
   GPLv3 and the App Store's DRM/usage-restriction terms are widely held to be incompatible,
   and Apple has pulled GPLv3 apps (VLC, GNU Go). You have declared the App Store a target.
   Choosing GPL means choosing to fight that. If protecting against proprietary forks matters
   more than iOS, **GPL-3.0-or-later** is the alternative — but say so explicitly and drop
   the App Store target.

**Choose MIT.** If you want the patent grant, choose **Apache-2.0** and then do §4.3
properly — but you cannot have Apache-2.0 *and* an easy life, and MIT costs you nothing that
matters for this project.

### 4.3 The attribution work you actually have to do

Ship a single in-app screen (`design-index.md` already has a Settings tree; add
"About → Licences and attribution") **and** a `THIRD_PARTY_NOTICES.md` in the repo, containing:

**Code**
- Mob — MIT, © its authors. Full MIT text.
- Mishka Chelekom — Apache-2.0. The generated component files are Derivative Works you
  distribute, so Apache §4(a)–(c) apply: include a copy of the Apache-2.0 licence, retain
  any copyright/attribution notices, and **state that you modified the files** (you will —
  they generate unstyled and you style them). §4(d) does not bite because upstream ships no
  `NOTICE` file (verified: no `NOTICE` in the repo root). Add a short header to each
  generated component noting origin and modification; it is one line and it removes all
  doubt.
- Elixir, Erlang/OTP, exqlite, ecto_sqlite3 — standard notices.

**Data — TMDB.** Mandatory and specific
(<https://www.themoviedb.org/api-terms-of-use>, <https://www.themoviedb.org/about/logos-attribution>):

> "This [website, program, service, application, product] uses TMDB and the TMDB APIs but is
> not endorsed, certified, or otherwise approved by TMDB."

placed "within your application's 'About' or 'Credits' type section", with an **official,
unmodified** TMDB logo (no colour change, no aspect-ratio change, no flip/rotate) that is
"less prominent than the logos or marks that primarily describe or identify Your Application."

Three TMDB terms that constrain Kati's *architecture*, not just its credits screen, and that
you should decide about now:

1. **You may not "cache, for longer than 6 months, any information obtained through or from
   TMDB or the TMDB APIs."** A tracking app naturally hoards metadata forever. Kati must
   either re-fetch/expire TMDB-derived fields on a ≤6-month TTL, or store only IDs +
   user-generated data (watched dates, ratings, notes) durably and treat titles/posters/
   synopses as a refreshable cache. **This is a schema decision — make it before the Ash
   resources are written, not after.** (It also interacts with offline-first: design for
   "stale metadata renders, but is marked stale", not "metadata is gone".)
2. **Non-commercial only** on the free tier; commercial use "requires a separate written
   agreement". Kati as a free open-source app is fine. Adding IAP, a paid tier, or ads would
   not be.
3. **No training AI/ML systems on TMDB content.** Rules out any "local model over your
   library" feature that ingests TMDB text.

**Data — Trakt.** <https://docs.trakt.tv/docs/create-an-app>: "All branding requirements must
be followed"; "Use only documented API methods and please don't scrape the website for
information"; "Trakt data cannot be used in apps or websites that promote copyright
infringement or piracy" — relevant because Kati's Library screens sit next to nothing of the
sort, but the design must never link to streams. Rate limiting has been enforced since
2020-10-27 and is **per user**; the app must handle HTTP 429 plus its headers. The branding
page (<https://trakt.tv/branding>) returned **403 to automated fetch — read it manually
before you design the Trakt-connected screens.** *(UNVERIFIED: exact logo/wording rules.)*

**Fonts.** All four are OFL/Apache and all four are safely embeddable in an app; none
requires a visible in-app credit, but list them anyway:

| Font | Licence | Note |
|---|---|---|
| **Vazirmatn** | **SIL OFL 1.1** — <https://github.com/rastikerdar/vazirmatn> ("This Font Software is licensed under the SIL Open Font License, Version 1.1") | OFL permits bundling/embedding/selling *with* software; forbids selling the font by itself. If you *modify* it (subsetting is fine; renaming glyphs is not), OFL §3/§5 Reserved Font Name rules apply — **rename any modified derivative.** |
| **Plus Jakarta Sans** | **SIL OFL 1.1** — <https://github.com/tokotype/PlusJakartaSans> | same |
| **DM Mono** | SIL OFL 1.1 (Google Fonts / Colophon Foundry) | `design-index.md:298-303` shows 811 uses — this is a **fourth** family, easy to forget in the notices |
| **Material Symbols Rounded** | **Apache-2.0** | Apache §4 obligations: include the licence text. |

Practical OFL requirement people miss: **ship `OFL.txt` alongside the embedded fonts** (in
`priv/`, and referenced from the About screen). OFL §2 requires the copyright + licence
notice to travel with the font files.

**Subsetting note (not a licence issue, a size issue):** at 4 families × up to 5 weights,
plus a variable icon font, the font payload is a meaningful slice of the 200 MB / install
size. `design-index.md:298-322` says weights 500/600/700/800 are used and 400 is inherited.
Subset to the used weights and to Latin + Arabic/Persian ranges + the actually-used Material
Symbols codepoints.

---

## 5. Release engineering

### 5.1 What Mob gives you, and what it doesn't

`mob_dev` 0.6.23 ships a surprisingly complete release toolchain
(`mob_dev/lib/mix/tasks/`):

| Task | Does |
|---|---|
| `mix mob.release --android` | Ensures cached Android OTP → stages OTP + app BEAMs + exqlite → `MobDev.OtpAssetBundle.build/2` → `assets/otp.zip` → `./gradlew bundleRelease`. Output `android/app/build/outputs/bundle/release/app-release.aab` (`mob.release.ex:36-38`, `:50-63`). |
| `mix mob.release --ios` | `_build/mob_release/<App>.ipa`. Needs a paid Apple Developer account, an Apple Distribution certificate, and an App Store provisioning profile (`mob.release.ex:40-49`). |
| `mix mob.release --security-gate` | Runs `MobDev.SecurityScan` first; **aborts the release on any critical/high/medium finding — nothing is built, nothing is signed** (`mob.release.ex:14-31`, `:86-113`). Scans Hex/Gradle/Swift dep CVEs, bundled-runtime drift, and C/Kotlin/Swift static analysis. **Use this in CI unconditionally.** |
| `mix mob.setup.google_play` | Interactive wizard: picks a GCP project, enables the Android Publisher API, creates a `play-publisher` service account, writes a JSON key to `~/.google_play/`, grants Release Manager access, **generates `android/upload_jks.keystore`**, prints the `mob.exs` block (`mob.setup.google_play.ex:17-35`). Has `--dry-run`. |
| `mix mob.publish --android` | Uploads to Play. |
| `mix mob.provision [--distribution]` | Downloads iOS provisioning profiles. |
| `mix mob.verify_strip` | Connects to a running device and force-loads **every** `.beam` in the bundle, catching "module X depends on stripped module Y" from the slim build (`mob.verify_strip.ex:24-40`). **Explicitly does not check app-specific code paths** — "If your app calls `:public_key.something` when the user opens a particular screen, this verifier won't find it unless the screen is opened." |
| `mix mob.audit_otp`, `mix mob.security_scan`, `mix mob.doctor` | supporting |

What it does **not** give you: reproducible builds, changelog generation, version bumping,
crash reporting, or any CI configuration.

### 5.2 Versioning and changelogs

Keep three numbers in lockstep and derive them from one source of truth:

- `mix.exs` `version:` — semver, human-facing (`mob_new/priv/templates/mob.new/mix.exs.eex:7`
  starts at `"0.1.0"`).
- `android/app/build.gradle` `versionName` / `versionCode` (`build.gradle.eex:44-45`,
  currently hardcoded `1` / `"1.0"`). **`versionCode` must strictly increase for every Play
  upload, forever, and can never be reused.** Use the CI run number or a monotonic
  `YYYYMMDDNN`.
- iOS `CFBundleShortVersionString` / `CFBundleVersion` (`Info.plist.eex:12-15`, both `1.0`).

Write a tiny `mix kati.version` task that stamps all three from `mix.exs`. Doing this by
hand across three files in two languages is how you end up unable to upload on a Friday.

Changelogs: **Keep a Changelog** format + Conventional Commits, generated at tag time. For an
open-source app the changelog is also the Play "What's new" text (500 char limit) and the
App Store release notes — write it for users, not for `git log`.

### 5.3 CI on GitHub Actions

Use `erlef/setup-beam` (<https://github.com/erlef/setup-beam>) — supports Ubuntu 22.04/24.04/26.04,
macOS 14/15/26, Windows 2022/2025; on macOS it covers OTP 25–29 only. Note self-hosted
runners need `ImageOS` set manually.

Shape:

```
jobs:
  test:      ubuntu-latest  — setup-beam, mix deps.get, mix test, mix credo, mix mob.security_scan
  android:   ubuntu-latest  — setup-beam + setup-java + Android SDK/NDK 27.2.12479018
                              write secrets.exs + keystore.properties from secrets
                              mix mob.release --android --security-gate
                              upload app-release.aab + a universal APK artifact
  ios:       macos-latest   — only on tag; needs certs in a temporary keychain
```

Concrete gotchas for this specific stack:

1. **The NDK must match `mob_new/lib/mob_new/ndk_version.ex:22` exactly** (`27.2.12479018`).
   `sdkmanager "ndk;27.2.12479018"`. A mismatch produces undefined `__cxa_*` symbols at link
   (`build.gradle.eex:33-38`).
2. **Zig is required**, not optional. `CMakeLists.txt.eex:22-33` shows `build.zig` owns the
   native build and CMake is only a fallback for Android Studio sync. Install a pinned Zig in
   CI.
3. **The Android OTP runtime is downloaded, not built**:
   `mob_dev/lib/mob_dev/otp_downloader.ex:10` →
   `@base_url "https://github.com/GenericJam/mob/releases/download/#{@release_tag}"`.
   Cache `~/.mob/cache/` between runs or every build pulls tens of MB. **This is also the
   fact that decides F-Droid** (§5.5).
4. **Signing keys.** `mix mob.setup.google_play` generates `android/upload_jks.keystore` and
   `android/keystore.properties`. Keep **both** out of git (the template comment at
   `build.gradle.eex:12-18` says `keystore.properties` is gitignored; make sure the `.keystore`
   is too). In CI: store the keystore base64-encoded in a repository secret, decode to a temp
   path in the job, write `keystore.properties` from four more secrets, and `rm` in an
   `always()` step. Store the raw upload key **offline** as well — losing it means asking
   Google to reset the upload key (recoverable, because Play App Signing holds the real key;
   this is a genuine argument *for* Play App Signing rather than against it).
5. **Never build releases on a fork PR.** Guard the release jobs with
   `if: github.event_name == 'push' && github.repository == 'you/kati'`; secrets must not be
   reachable from PR workflows.

### 5.4 Reproducible builds

Worth doing, and mostly achievable — with one hard blocker.

**BEAM side.** Erlang's compiler has a `deterministic` option that "omits the options and
source tuples in the list returned by `Module:module_info(compile)`, and reduces the paths in
stack traces to the module name alone" (<https://erlang.org/doc/man/compile>), and a later fix
made files "compiled in a different directory but otherwise identical" match. Elixir has no
first-class setting (elixir-lang/elixir#8986, closed), but honours
`ERL_COMPILER_OPTIONS=deterministic`. Set it in CI and locally.
Note `mob_new/priv/templates/mob.new/mix.exs.eex:13` sets `erlc_options: [:debug_info]` for
the `src/` Erlang — keep `debug_info` (Mob's hot-load/diag paths want it) and add
`:deterministic` alongside.

**APK side.** From AGP 2.2.2 onward, zip-header timestamps are zeroed. F-Droid's method:
build from source, then compare against the developer's APK; "The only differences should be
the signature files." Note that v2/v3 signatures "cover all other bytes in the APK", so the
APKs must be byte-identical *apart from the signature block*
(<https://f-droid.org/docs/Reproducible_Builds/>).

**The blocker:** `assets/otp.zip` is a **zip built at release time** by
`MobDev.OtpAssetBundle` (`mob_dev/lib/mob_dev/otp_asset_bundle.ex`). Zips embed mtimes and
depend on entry ordering. Unless that builder normalises timestamps and sorts entries,
`otp.zip` differs run to run and the whole AAB is unreproducible. **UNKNOWN — I did not read
the zip-writing code.** Check `MobDev.OtpAssetBundle.build/2` for `:zip.create/3` options and,
if needed, patch or post-process (`strip-nondeterminism`-style) before this matters.

Second blocker: the ERTS `.so` files come from a **prebuilt GitHub release tarball**
(`otp_downloader.ex:10`). Byte-for-byte reproducibility of *those* requires reproducing
Mob's own OTP cross-compile, which `mix mob.release.otp` can do (`mob.release.otp.ex:10-45`,
5–10 min per target) but which nobody will verify casually.

**Pragmatic target:** publish SHA-256 sums of the release APK/AAB in the GitHub release,
document the exact toolchain versions (Elixir, OTP, NDK, Zig, AGP, Gradle), and treat full
bit-for-bit reproducibility as a v2 goal.

### 5.5 F-Droid — can an Elixir/OTP app qualify?

**Verdict: not with today's Mob, and not without work. Realistically: no for v1.**

F-Droid's Inclusion Policy (<https://f-droid.org/en/docs/Inclusion_Policy/>) requires
everything be FLOSS **and built from source on F-Droid's servers with a 100% FLOSS toolchain**;
"The use of proprietary build tools are strictly forbidden." Prebuilt binaries are allowed
only from an enumerated set of sources:

> "Debian '[main]' package archive" · trusted Maven repos (Maven Central, Google Maven, OSS
> Sonatype, OSS JFrog, JitPack.io, Clojars) · "The Android SDK, Flutter SDK and Hermes have
> permission to use official prebuilt binaries" · PyPI Wheels, Nix cache, Rust/Rustup,
> Golang, and Node.js compilers.

Four problems, in descending order of severity:

1. **The prebuilt OTP runtime.** `https://github.com/GenericJam/mob/releases/download/…` is
   a GitHub release, on none of those lists. F-Droid would have to cross-compile
   Erlang/OTP for `arm64-v8a` themselves. `mix mob.release.otp android_arm64` exists, but it
   needs an OTP source checkout, a prebuilt OpenSSL prefix, and the NDK, and takes 5–10 min
   per target. **This is the disqualifier.** Not impossible — F-Droid builds Rust and Go —
   but it would require F-Droid-side toolchain support that does not exist.
2. **Zig.** Not on the allowed-compiler list (Rust, Go, Node are; Zig isn't). Mob's Android
   native build is `build.zig`-owned.
3. **Firebase.** `mob_notify`'s manifest requirements include
   `com.google.firebase:firebase-messaging:24.0.0` (`mob-framework.md:1167`). F-Droid:
   "proprietary tracking or advertising libraries and analytics tools such as Google Play
   Services and Firebase and Crashlytics … are strictly forbidden." Kati doesn't need FCM
   (no server), so this one is fixable — but it means auditing what `mob_notify` actually
   pulls in and stripping the FCM dependency.
4. **API keys.** An F-Droid build cannot contain your TMDB/Trakt keys. Only Tier 3 from §3.3
   (user-supplied keys) makes an F-Droid build functional at all — and F-Droid would likely
   still flag `NonFreeNet` as an Anti-Feature for depending on non-free network services.

**Recommendation:** ship APK-on-GitHub-releases as the F-Droid substitute for v1, with
published checksums and a documented signing key. Optionally publish your own F-Droid
**repository** (`fdroid` supports third-party repos with your own signed binaries) — that
gives F-Droid users update-in-place without needing F-Droid's build farm. Revisit official
inclusion only if Mob ever ships a build-from-source OTP path.

### 5.6 Crash reporting that respects privacy

Two layers, and the interesting one is the layer nobody's tooling covers.

**Layer 1 — Elixir crashes.** Kati's actual failure mode is a screen GenServer crashing.
`mob-framework.md:1591-1596`: *"Each screen runs as a **supervised** GenServer … a buggy
`handle_event` crashes its own screen"*, and supervision restarts it. **Java/Kotlin crash
reporters like ACRA see none of this** — from the JVM's point of view nothing happened.

So the useful thing is an **Elixir `Logger` handler / `:error_logger` report handler** that
writes structured crash reports to a local ring-buffered file. Then:

- **Never send automatically.** No network on crash. This is the entire privacy story.
- Surface a "Something went wrong — send a report?" affordance that shows the user the exact
  text, lets them edit it, and shares it via the OS share sheet or attaches it to a
  pre-filled GitHub issue. User-initiated, contents-visible, zero background telemetry.
- **Scrub before display**: strip file paths containing the user's name, strip anything from
  the OAuth token store, strip search queries, truncate `assigns` (Kati's assigns contain the
  user's watch history).

**Layer 2 — native crashes** (BEAM SIGSEGV, NIF faults). Google Play Console gives you
**Android vitals** crash/ANR stack traces for free, with no SDK, no library, and no data
leaving the user's device to *you* — the OS reports to Google, gated by the user's own
"share usage data" setting. For an open-source privacy-first app this is strictly better
than embedding Crashlytics. Same on Apple's side: App Store Connect Organizer crash reports,
opt-in per user, no SDK.

**Do not use**: Firebase Crashlytics (F-Droid-disqualifying, Google-analytics-shaped, and
would force a data-safety "Crash logs: collected" disclosure). If you later want aggregation,
**self-hosted GlitchTip/Sentry** with an explicit opt-in toggle, default **off**, is the only
form that survives the privacy posture in §6.

---

## 6. Import / export / sharing

### 6.1 Formats to support

**Priority order for a v1 that people will actually migrate to.** Import matters far more
than export for adoption; export matters far more for trust.

| Domain | Import | Export | Notes |
|---|---|---|---|
| **Film/TV** | **Letterboxd CSV** (their import format), **Trakt** via API, IMDb CSV | Letterboxd-compatible CSV | Letterboxd's export zip contains `diary.csv` with "the date logged on the website, film title, release year, Letterboxd URI, rating, a rewatch flag, and tags" (<https://letterboxd.com/importing-data/>). Its *import* format is UTF-8 CSV with named column titles in any order, extra columns ignored. **The docs page 403s to automated fetch — open it in a browser and copy the exact column list before implementing.** Letterboxd also accepts IMDb CSV, Delicious Library XML, ICheckMovies. |
| **Books** | **Goodreads CSV** (`goodreads_library_export.csv`) | Goodreads-compatible CSV | Columns: `Book Id, Title, Author, Author l-f, Additional Authors, ISBN, ISBN13, My Rating, Average Rating, Publisher, Binding, Number of Pages, Year Published, Original Publication Year, Date Read, Date Added, Bookshelves, Bookshelves with positions, Exclusive Shelf, My Review, Spoiler, Private Notes, Read Count, Owned Copies`. `Exclusive Shelf` ∈ {`read`, `currently-reading`, `to-read`} — maps cleanly onto Kati's Finished/Reading/Wishlist tabs (`design-index.md` screen 20). ISBNs come wrapped as `="0439023483"` — strip the Excel armour. Some columns were removed mid-2022; **parse by header name, never by position.** |
| **Music** | Last.fm scrobble export, Spotify GDPR export JSON | CSV | Lower priority; screen 21 is play-count driven. |
| **Calendar** | **`.ics` (RFC 5545)** | `.ics` | The universal interchange. Support `VEVENT` + `RRULE` + `VALARM` on import; export at minimum `VEVENT`. This is also the **fallback for calendar sync while Google OAuth verification is pending** (§3.4) — "export my Kati calendar as .ics, subscribe in Google" ships in a week and needs no OAuth at all. **Strongly consider shipping this in v1 instead of the API sync.** |
| **Everything** | **Kati JSON backup** | **Kati JSON backup** | The lossless one. See §6.4. |

Two Kati-specific rules that fall out of the locked decisions:

- **Dates in every interchange format are Gregorian/ISO-8601 UTC.** Shamsi/Jalali is a
  *display* transform (locked decision; `design-index.md` §6). A `.ics` or CSV containing
  Persian digits or Jalali dates is broken for every other tool. Convert at the render
  boundary only.
- **Persian text must be UTF-8 without BOM**, and CSV import must tolerate a BOM because
  Excel adds one. Also tolerate Persian/Arabic-Indic digits in *user* fields on import
  (someone's Goodreads review), normalising to ASCII digits for numerics.

### 6.2 The export capability gap in Mob

This is the part that will bite.

- **Import works.** `Mob.Files.pick/2` opens the system document picker (iOS
  `UIDocumentPickerViewController`, Android `OpenMultipleDocuments`), needs no permission,
  and returns `%{path:, name:, mime:, size:}` (`mob/lib/mob/files.ex:1-18`). It supports
  extension / MIME / semantic-atom / UTI filtering (`:22-38`).
- **Export does not.** `Mob.Share` is **text only** — `Mob.Share.text/2` → `:mob_nif.share_text/1`
  (`mob/lib/mob/share.ex:17-24`). There is no `Mob.Share.file/2`. `mob-framework.md:690-692`
  says the same: *"`Mob.Share` (**text only** — sharing files/images is missing)"*.
- `mix mob.enable file_sharing` only sets Info.plist keys and adds an Android FileProvider —
  and the enable table says explicitly `| file_sharing | yes | (no Elixir surface) |`
  (`mob_dev/lib/mob_dev/enable/igniter.ex:19`, `:74-80`):

```elixir
  def enable_file_sharing(igniter, _app_name) do
    igniter
    |> add_ios_plist_key("UIFileSharingEnabled", "true", type: :bool)
    |> add_ios_plist_key("LSSupportsOpeningDocumentsInPlace", "true", type: :bool)
    |> add_android_file_provider()
  end
```

So on **iOS**, `UIFileSharingEnabled` + `LSSupportsOpeningDocumentsInPlace` make the app's
Documents directory visible in the Files app — write `kati-backup.json` there and the user can
retrieve it. Clunky but functional, zero code.
On **Android** there is no equivalent user-visible directory; a FileProvider alone gives you
nothing without an `Intent`.

**Concrete work item:** patch `MobBridge.kt` (which *is* app-owned — generated from
`mob_new/priv/templates/mob.new/android/app/src/main/java/MobBridge.kt.eex`) to add two NIF
entry points: `ACTION_CREATE_DOCUMENT` (Save As…) and `ACTION_SEND` with a FileProvider URI
(Share…). The manifest already declares the provider at
`AndroidManifest.xml.eex:88-96` with authority `${applicationId}.fileprovider`. On iOS the
equivalent lives in `mob/ios/mob_nif.m`, which is **not** app-owned — so either upstream a
`Mob.Share.file/2` PR or live with the Files-app route on iOS. Note `mob-framework.md:1571`
already warns you'll be three-way-diffing `MobBridge.kt` across Mob upgrades.

### 6.3 Device-to-device transfer with no server

Ranked by "actually works".

1. **File hand-off (recommended default).** Export to an encrypted `.katibackup`, let the user
   move it however they like (AirDrop, Nearby Share, Telegram to self, USB, SD card), import
   on the new device via `Mob.Files.pick/2`. **Zero new code beyond §6.2, zero network
   permissions, works across platforms, works when both devices are never online at once.**
   It is also the only mechanism that doubles as a backup.
2. **QR code — for pairing/small payloads only.** `mob_scanner` exists (`mob-framework.md:684`)
   and `mob_dev` has a `qr.ex`. But a QR code's theoretical maximum is ~2,953 bytes (version
   40, byte mode, L) and realistically far less on a phone screen. Kati's library is orders of
   magnitude bigger. **Use QR to exchange a key or a LAN address, not the data.** Note
   `design-index.md` already draws QR modules (2px radii, 493 uses) — so a QR screen is in the
   design.
3. **Local network transfer.** Technically the nicest UX; the most work and the most fragile.
   - Android 16 introduces a **local network permission**: apps using "raw sockets on local
     network addresses (e.g. mDNS or SSDP)" or `NsdManager` need `NEARBY_WIFI_DEVICES`. It is
     opt-in today, "will be enforced between 25Q2 and 26Q2"
     (<https://developer.android.com/about/versions/16/behavior-changes-16>). Since you must
     target API 36 anyway (§1.1), plan for it.
   - iOS requires `NSLocalNetworkUsageDescription` + `NSBonjourServices`, and Mob generates
     neither.
   - **Do not use Erlang distribution for this**, however tempting `Mob.Dist` +
     `Node.connect/1` looks. See §1.7: it means shipping EPMD, a listener, and a shared
     cookie in a public codebase. If you build LAN transfer, build a small purpose-made TLS
     socket protocol with a QR-exchanged one-time key.

**Recommendation: ship (1) in v1, (2) as the pairing mechanism if and when you build (3).**

### 6.4 Making backup/restore trustworthy

Trust is a product feature here, because `allowBackup="false"` (§1.8) means Kati's export is
the *only* thing standing between a user and total data loss.

- **Format: plain JSON inside a zip**, not a raw SQLite file. A `.db` is opaque, version-
  coupled, and can't be inspected. JSON is diffable, greppable, and repairable by hand.
  Include a `manifest.json` with `schema_version`, `app_version`, `exported_at` (UTC),
  `record_counts` per resource, and a SHA-256 of each payload file.
- **Completeness assertion.** Restore must verify counts and hashes before touching the
  database, and refuse rather than half-import. Show the user the counts *before* they
  confirm: "This backup contains 412 films, 64 books, 1,203 calendar events."
- **Round-trip test in CI.** Property-based: generate a random Ash dataset → export → wipe →
  import → assert deep equality. This is the single highest-value test in the project and it
  is cheap with Ash + StreamData.
- **Forward compatibility.** Every export carries `schema_version`; importers must handle
  every older version, and must fail loudly (not silently drop fields) on a *newer* one.
- **Never overwrite blind.** Restore offers "replace everything" vs "merge", and "replace"
  auto-exports the current state first.
- **Encryption is opt-in with a user passphrase**, not a device-bound key — a device-bound key
  makes the backup useless on the new phone, which defeats the purpose. Use a passphrase +
  Argon2id/PBKDF2 + AES-GCM. **But**: OAuth refresh tokens must be *excluded* from exports by
  default (re-authenticate on the new device instead) — see §6.3 below.
- **Publish the format.** A documented JSON schema in the repo is what makes "open source"
  mean something: it lets anyone write a converter, and it guarantees the data outlives the
  app.

---

## 7. Privacy and data

### 7.1 What the Play Data safety form would say

The governing rule (<https://support.google.com/googleplay/android-developer/answer/10787469>):

> "User data accessed by your app that is only processed locally on the user's device and not
> sent off device does **not** need to be disclosed."

with **Collection** = "Transmitting data from your app off a user's device" and **Sharing** =
"Transferring user data collected from your app to a third party", explicitly including
"on-device transfers to other apps".

Kati is device-first with no server. So:

| Data type | Collected? | Shared? | Reasoning |
|---|---|---|---|
| Health and fitness (kcal, macros, weight, sleep, medication — screens 42–52) | **No** | No | Local only. This is the category that would otherwise be most damaging; the local-only architecture erases it. |
| Financial info (screens with Money lanes/renewals) | **No** | No | Local only. |
| Calendar | **No** | No | Kati owns its calendar; it does **not** read `CalendarContract` (§1.6). *Changes to Yes/Yes if Google Calendar sync ships.* |
| App activity (search queries, watch history) | **No** | **Yes, conditionally** | The moment the user connects Trakt, watch history is transmitted to a third party **at the user's direction**. Declare it, scoped to the optional integration, and mark it optional. |
| Personal info (name/email) | Only if Google/Trakt account is connected | Yes | Same. |
| App info and performance / Crash logs | **No** | No | §5.6: no SDK, local-only crash log, user-initiated sharing. |
| Device or other IDs | **No** | No | Ship no advertising ID; **do not** add `com.google.android.gms.permission.AD_ID`. |

Also declare, honestly:
- **Encryption in transit: yes** (all API calls HTTPS).
- **Users can request data deletion: yes** — via in-app "delete all data", which for a
  local-only app is genuinely complete.
- **Data is not shared with third parties** except the integrations the user explicitly
  connects.
- Do **not** claim the "Independent security review" (OWASP MASVS) badge unless you've paid
  for one.

Two hazards specific to Kati's manifest: `RECORD_AUDIO` (`AndroidManifest.xml.eex:13`) with
no feature behind it will make reviewers ask what audio you collect. Delete it (§1.6). Same
for CameraX/Media3 deps you don't use — Play's scanners look at what's in the bundle, not
just at what you declare.

### 7.2 Apple's side

- **Privacy nutrition labels** in App Store Connect: same analysis, same answers. "Data Not
  Collected" is available and Kati qualifies for it in the base configuration.
- **`PrivacyInfo.xcprivacy`** — mandatory, missing from Mob, see §2.4. Set
  `NSPrivacyTracking = false`, empty `NSPrivacyTrackingDomains`, empty
  `NSPrivacyCollectedDataTypes`.
- **5.1.1(i)** requires a privacy policy link "in the App Store Connect metadata field **and
  within the app** in an easily accessible manner", clearly identifying what data is
  collected, how, and all uses; confirming third-party protections; and explaining retention/
  deletion and how to revoke consent. A one-page policy on the project's domain covers it —
  and you need that domain anyway for Google OAuth verification (§3.4). **One artefact, three
  requirements: write it once, early.**

### 7.3 GDPR posture

Not legal advice; this is the shape of the argument.

- **For local-only data, you are almost certainly not a controller.** GDPR Art. 4(7) defines
  a controller as whoever "determines the purposes and means of the processing" of personal
  data. Data that never leaves the user's device, that you never receive, and that you have
  no technical means to access is not personal data *you* process. The user's own use is
  covered by the household exemption (Art. 2(2)(c)) — which protects the *user*, not you, but
  the point is there is no controller-processor relationship to document.
- **For the optional integrations, the analysis changes.** When Kati calls TMDB/Trakt/Google,
  the user's IP address, search terms, and account identifiers go to a third party because
  *you* wrote the code that sends them. Safest posture: treat the user as initiating each
  transfer, gate every integration behind explicit in-app consent, name the recipient and
  what is sent at the moment of connection, and link the third party's own policy.
- **What to actually do**, in ascending cost:
  1. Publish a plain-language privacy policy. Say "Kati stores everything on your device. We
     have no servers and receive none of your data." Then list every outbound connection
     Kati can make and what triggers it.
  2. Ship a **connections screen** listing each integration, its status, what it sends, and a
     one-tap disconnect that deletes the stored token.
  3. Make "Export all my data" and "Delete all my data" real, in-app, and one screen deep.
     For a local app these satisfy Art. 15/17/20 trivially — and they're the same features
     from §6 that users want anyway.
  4. **No analytics.** Not "anonymised" analytics. None. It is the only claim that costs
     nothing to make and nothing to defend.
- **Iran/Persian users:** GDPR is territorial (EU/EEA data subjects) but the posture above is
  jurisdiction-agnostic and strictly stronger. No extra work.

### 7.4 The encryption-at-rest gap — confirmed, and it matters more now

Prior research flagged this. I re-verified it across all three packages:

```
grep -rn -i "keychain|Keystore|EncryptedShared|SQLCipher" mob720/ mobdev/ mob_new/
```

Every hit is about **build-time signing keystores** (`upload_jks.keystore`,
`keystore.properties`, `MobDev.Plugin.PrivateKeyStore`, Xcode keychain lookups in
`mob_dev/lib/mix/tasks/mob.provision.ex`). **There is no runtime secure-storage binding in
Mob at all**: no iOS Keychain, no Android Keystore / `EncryptedSharedPreferences`, no
SQLCipher, no `Mob.SecureStore`. `mob/lib/mob/` contains `state.ex` and `storage/` — both
plaintext.

Why this is worse for Kati than for a generic app:

1. Kati will hold **OAuth refresh tokens** for Trakt and (later) Google Calendar. A refresh
   token is a long-lived credential to a user's *account*, not just to Kati.
2. `mob-framework.md:633` describes `Mob.State` as *"Capacity O(dozens) of keys — themes,
   onboarding flags, cached IDs"* — a `SharedPreferences`/plist-shaped store. Putting a
   refresh token there means plaintext on disk.
3. §1.7's distribution hole is an **RCE path into that same sandbox**. Two medium problems
   compose into one serious one.

**Recommendation, in order:**

1. **Do not store a Google refresh token at all in v1.** Ship `.ics` export instead of API
   sync (§6.1). Removes the highest-value secret from the device entirely.
2. **For Trakt, encrypt at rest with a key held by the platform keystore.** Requires a native
   extension: Android → `MasterKey` + `EncryptedSharedPreferences` (or a Keystore-wrapped AES
   key + `Mob.State` for the ciphertext); iOS → Keychain with
   `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`. This is ~100 lines of Kotlin/ObjC
   behind two NIFs. `mob_biometric` already exists (`mob-framework.md:684`) and proves the
   pattern of a small native plugin.
3. **Failing that, an app-level envelope**: derive a key from a device-random secret stored in
   `Mob.State`, AES-GCM the token. Weaker (the key is on the same disk), but it defeats casual
   `adb backup`/file-browser extraction and it is pure Elixir. **Not** a substitute for (2).
4. **Never export tokens.** §6.4: exclude credentials from backups by default; make the new
   device re-authenticate.
5. Consider **SQLCipher** for the whole database only if you also solve key management — a
   passphrase the user types on every launch is unacceptable UX for a habit tracker, and a
   keystore-derived key means the DB is unreadable after a restore-to-new-device. Given
   §1.8/`allowBackup="false"` the DB never leaves the sandbox anyway. **Encrypt the tokens,
   not the database.**

---

## 8. Consolidated action list

**Before the first Play upload**
1. `targetSdk`/`compileSdk` → 36; test edge-to-edge, predictive back, Persian line metrics. (§1.1)
2. `abiFilters 'arm64-v8a'` only. (§1.4)
3. Remove `Mob.Dist.ensure_started` from the release path; strip `libepmd.so`; never ship
   `:mob_secret`. Report upstream. (§1.7)
4. Delete `RECORD_AUDIO`, the USB/flash `uses-feature`s, and the unused CameraX/Media3 deps. (§1.6, §1.5)
5. `USE_EXACT_ALARM` (API 33+) + `SCHEDULE_EXACT_ALARM maxSdkVersion="32"`; complete the Play
   Console exact-alarm declaration. Keep `RECEIVE_BOOT_COMPLETED`. (§1.6)
6. Add `-Wl,-z,common-page-size=16384` beside the existing `max-page-size`; verify `0x4000`. (§1.5)
7. Data safety form: everything local; declare only the optional integrations. (§7.1)
8. Working export + restore, with the CI round-trip test. `allowBackup="false"` makes this
   non-optional. (§6.2, §6.4)

**Before the first App Store upload**
9. Delete `UIBackgroundModes` and `NSMicrophoneUsageDescription` from `Info.plist`. (§2.2)
10. Write `PrivacyInfo.xcprivacy`; set `ITSAppUsesNonExemptEncryption`. (§2.4)
11. Confirm `mix mob.release --ios` really defines `MOB_RELEASE`; verify no EPMD, no listener,
    no `beam.emu` JIT, in the shipped binary. (§2.1, §2.3)
12. Submit an early throwaway TestFlight build purely to test the 2.5.2 hypothesis. (§2.3)

**Project setup**
13. `LICENSE` = MIT; `THIRD_PARTY_NOTICES.md`; About screen with the exact TMDB wording and
    logo; ship `OFL.txt`; add the DM Mono attribution you'd otherwise forget. (§4)
14. Decide the TMDB **6-month cache TTL** before writing Ash resources. (§4.3)
15. `secrets.exs.example` + CI secret injection + Settings → BYO keys. (§3.3)
16. Buy a domain, publish the privacy policy and homepage — needed for App Store 5.1.1 *and*
    Google OAuth brand verification. (§3.4, §7.2)
17. CI: `erlef/setup-beam`, NDK pinned to `27.2.12479018`, Zig pinned, `~/.mob/cache` cached,
    `mix mob.release --security-gate`, `ERL_COMPILER_OPTIONS=deterministic`, no releases from
    fork PRs. (§5.3, §5.4)
18. Encrypt OAuth tokens via a small native keystore/Keychain plugin. (§7.4)

**Deferred**
19. Google Calendar API sync → v1.x, after OAuth verification. `.ics` in v1. (§3.4, §6.1)
20. F-Droid → not feasible with today's Mob; publish signed APKs + checksums, consider a
    self-hosted F-Droid repo. (§5.5)
21. LAN device-to-device transfer → after file hand-off works; needs `NEARBY_WIFI_DEVICES`
    and `NSLocalNetworkUsageDescription`. (§6.3)

---

## 9. Explicitly UNKNOWN / unverified

Listed so they are not mistaken for findings.

1. **Whether Mob's iOS OTP is built with `--disable-jit`.** Strong indirect evidence
   (`beam.emu` in `mob_dev/lib/mob_dev/release/otp.ex:27`, `:36-37`), but no flag found.
2. **Whether any Erlang/Elixir app has passed Apple App Review.** No public precedent found.
   §2.3's conclusion is a reading of the guideline plus analogy to Python/Lua apps.
3. **Whether `MobDev.OtpAssetBundle` produces a deterministic `otp.zip`.** Not read.
4. **Baseline Mob app size on Android.** No figure in Mob's docs; measure it.
5. **Whether omitting `-Wl,-z,common-page-size=16384` on NDK r27 causes a Play rejection.**
   Google says pass both; Mob passes one and reports passing.
6. **Trakt's exact branding requirements** — <https://trakt.tv/branding> returned HTTP 403.
7. **Letterboxd's exact import column names** — <https://letterboxd.com/about/importing-data/>
   returned HTTP 403.
8. **How Kati does HTTPS on iOS**, given OTP there is built `--without-ssl`
   (`mob_dev/lib/mob_dev/release/otp.ex:27`). Relevant to the export-compliance answer.
   Note `mob-framework.md:1410`, `:1429` already flags a TLS crash on **Android** on the
   first request — that is a separate, prior finding, unresolved here.
9. **What `mob_notify` pulls in beyond `firebase-messaging`** — matters for §5.5 and for the
   data-safety form.

---

## Sources

Google Play / Android
- Target API level requirements — <https://support.google.com/googleplay/android-developer/answer/11926878>
- Behavior changes: apps targeting Android 16 — <https://developer.android.com/about/versions/16/behavior-changes-16>
- Support 16 KB page sizes — <https://developer.android.com/guide/practices/page-sizes>
- Prepare your apps for the 16 KB requirement — <https://android-developers.googleblog.com/2025/05/prepare-play-apps-for-devices-with-16kb-page-size.html>
- Schedule alarms / `USE_EXACT_ALARM` — <https://developer.android.com/develop/background-work/services/alarms/schedule>
- Exact alarms denied by default (Android 14) — <https://developer.android.com/about/versions/14/changes/schedule-exact-alarms>
- Foreground service types required (Android 14) — <https://developer.android.com/about/versions/14/changes/fgs-types-required>
- Foreground service & full-screen intent declarations — <https://support.google.com/googleplay/android-developer/answer/13392821>
- Permissions and APIs that access sensitive information — <https://support.google.com/googleplay/android-developer/answer/16558241>
- Data safety form — <https://support.google.com/googleplay/android-developer/answer/10787469>
- App bundle / signing / size limits — <https://support.google.com/googleplay/android-developer/answer/9859152>
- 64-bit requirement — <https://android-developers.googleblog.com/2019/01/get-your-apps-ready-for-64-bit.html>
- AAB requirement — <https://android-developers.googleblog.com/2020/11/new-android-app-bundle-and-target-api.html>
- Doze / App Standby & battery exemptions — <https://developer.android.com/training/monitoring-device-state/doze-standby>

Apple
- App Review Guidelines (2.5.1, 2.5.2, 2.5.4, 4.7, 5.1.1) — <https://developer.apple.com/app-store/review/guidelines/>
- Describing use of required reason API — <https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api>
- ITMS-91055 / privacy manifest thread — <https://developer.apple.com/forums/thread/749940>
- `UIBackgroundModes` audio rejection reports — <https://github.com/ryanheise/audio_service/issues/975>, <https://developer.apple.com/forums/thread/95216>
- Briefcase App Store rejection (2.5.2, embedded Python) — <https://github.com/beeware/briefcase/issues/1655>
- JIT on iOS — <https://saagarjha.com/blog/2020/02/23/jailed-just-in-time-compilation-on-ios/>

BEAM
- BeamAsm / `--disable-jit` / `FLAVOR=emu` — <https://www.erlang.org/doc/apps/erts/beamasm.html>
- `compile` `deterministic` option — <https://erlang.org/doc/man/compile>
- elixir-lang/elixir#8986 (deterministic compile) — <https://github.com/elixir-lang/elixir/issues/8986>
- `erlef/setup-beam` — <https://github.com/erlef/setup-beam>

Data sources / secrets / licensing
- TMDB API Terms of Use — <https://www.themoviedb.org/api-terms-of-use>
- TMDB Logos & Attribution — <https://www.themoviedb.org/about/logos-attribution>
- Trakt — Create an App — <https://docs.trakt.tv/docs/create-an-app>
- Google OAuth for installed apps — <https://developers.google.com/identity/protocols/oauth2/native-app>
- Sensitive scope verification — <https://developers.google.com/identity/protocols/oauth2/production-readiness/sensitive-scope-verification>
- Brand verification — <https://developers.google.com/identity/protocols/oauth2/production-readiness/brand-verification>
- SeriesGuide CONTRIBUTING (TMDB/Trakt key handling) — <https://github.com/UweTrottmann/SeriesGuide/blob/dev/CONTRIBUTING.md>
- API key extraction from APKs — <https://github.com/alessandrodd/apk_api_key_extractor>
- Vazirmatn (OFL 1.1) — <https://github.com/rastikerdar/vazirmatn>
- Plus Jakarta Sans (OFL 1.1) — <https://github.com/tokotype/PlusJakartaSans>

F-Droid / release engineering / crash reporting
- Inclusion Policy — <https://f-droid.org/en/docs/Inclusion_Policy/>
- Reproducible Builds — <https://f-droid.org/docs/Reproducible_Builds/>
- ACRA — <https://github.com/ACRA/acra>; Acrarium — <https://github.com/F43nd1r/Acrarium>

Import/export
- Letterboxd importing data — <https://letterboxd.com/importing-data/> (403 to automated fetch)
- Goodreads export format discussion — <https://www.goodreads.com/topic/show/22566592-what-s-in-an-export-file>
