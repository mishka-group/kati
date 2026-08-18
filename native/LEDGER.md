# Drift ledger

Every Kati edit to a vendored native file. One row per fence label.
`test/kati/native_ledger_test.exs` fails the build if a fence exists that is not listed here, or a
row here has no matching fence — so this file cannot silently rot.

**Upstream status** is what lets a patch eventually be retired: once a defect is fixed upstream and
the baseline is refreshed, the fence goes and the row moves to *Retired*.

## Active patches

| Label | File | What and why | Upstream status |
|---|---|---|---|
| `K-01 abi-x86-64` | `android/app/src/main/jni/build.zig` | Adds an `x86_64` arm to `abi_to_target` and `ndk_arch_triple` (2 regions). `mob_dev` downloads the x86_64 Android OTP runtime and threads it through, but probes the app-owned `build.zig` for the ABI string and silently skips the ABI when absent — so the APK has no x86_64 lib and cannot run on an emulator on an Intel host. | Reported — #76. `native_build.ex:359` claims mob_new ≥ 0.4.5 adds this; the file came from 0.4.20 and does not. |
| `K-01 drop-location-stub` | `android/app/src/main/jni/beam_jni.c` | Removes the `nativeDeliverLocation` JNI stub. `mob_deliver_location` was removed from core **and** from `mob_beam.h` when Location moved to the `mob_location` plugin. Under NDK 27 / clang 18 an implicit declaration is an error, so a stock project does not compile. | Reported — #76. The extraction CHANGELOG claims the templates were updated; they were not. |
| `K-01 drop-plugin-stubs` | `android/app/src/main/jni/beam_jni.c` | Removes 33 JNI stubs (camera frames + 32 Bluetooth) whose core symbols were deleted but whose declarations remain in `mob_beam.h`. They link, then `dlopen` resolves eagerly and the app dies in `MainActivity.<clinit>` before any Elixir runs. | Reported — #76. |
| `K-01 torch-method` | `android/app/src/main/java/com/example/kati/MobBridge.kt` | Adds `torch(String)`, which `nif_load` resolves with `cacheRequired` (`mob_nif.zig:3764`); without it `nif_load` returns −1 and the BEAM thread dies with `NoSuchMethodError`. Implemented via `CameraManager.setTorchMode`, which needs no CAMERA permission. | Reported — #76. Either the template should emit it or core should use `cacheOptional`. |
| `K-01 notify-persist` | `android/app/src/main/java/com/example/kati/MobBridge.kt` | `notify_schedule` delegates to `KatiNotificationStore` so the alarm is recorded. Stock armed `AlarmManager` directly and kept no record, so every scheduled reminder was lost on reboot with no error. Also degrades to an inexact alarm rather than throwing `SecurityException` when `SCHEDULE_EXACT_ALARM` is ungranted — the default on Android 13+. | Kati-specific design; not an upstream bug. Likely permanent. |
| `K-01 notify-cancel` | `android/app/src/main/java/com/example/kati/MobBridge.kt` | `notify_cancel` clears the persisted record as well as the alarm. | Pairs with `notify-persist`. Permanent. |
| `K-01 notify-forget` | `android/app/src/main/java/com/example/kati/MobBridge.kt` | `NotificationReceiver` drops the stored record once an alarm fires, so a one-shot is not restored at next boot. | Pairs with `notify-persist`. Permanent. |
| `K-01 permission-trim` | `android/app/src/main/AndroidManifest.xml` | Removes 12 permissions and 4 `<uses-feature>` entries the template requests and Kati never uses (camera, microphone, location, media library, Bluetooth, USB, foreground service). The deleted lines are recorded inside the fence. | Kati-specific. Permanent — the template is generic by design. |
| `K-01 boot-receiver` | `android/app/src/main/AndroidManifest.xml` | Declares `KatiBootReceiver` for `BOOT_COMPLETED`, `MY_PACKAGE_REPLACED`, `TIME_SET`, `TIMEZONE_CHANGED`. The template requests `RECEIVE_BOOT_COMPLETED` but declares no receiver to use it. | Partly upstream-shaped: `mob_notify` documents a boot receiver the template never wires. Kati's version restores its own store, so it stays regardless. |
| `K-01 abi-filters` | `android/app/build.gradle` | `arm64-v8a` + `x86_64`, dropping `armeabi-v7a`. 32-bit doubles the OTP payload for a dead install base; x86_64 is needed for the emulator on an Intel host. | Kati-specific. Permanent. |
| `K-01 no-audio-background` | `ios/Info.plist` | Removes `UIBackgroundModes: [audio]`. Kati plays no audio, and declaring an unused background mode risks rejection under App Review 2.5.4. | Reported — #76. Arguably an upstream template bug for any non-audio app. |
| `K-05 vendored-header` | every tracked file | A provenance header naming the generator version and pointing at the upgrade procedure, so nobody edits a vendored file believing it is Kati's. | Kati-specific. Permanent. |
| `K-40 sqlite-feature-flags` | `android/app/src/main/jni/build.zig` | Mirrors exqlite's SQLite feature flags, which Mob's build drops by compiling the amalgamation with only `-DSQLITE_THREADSAFE=1`. Without them the device gets a feature-stripped SQLite while host tests get the full one — `fts5` is absent, and `MATH_FUNCTIONS`/`STAT4` change results and planning. | Reported — #76. Arguably an upstream bug: Mob should honour the flags of the NIF it is compiling. |

## Retired patches

_None yet._ When an upstream fix lands and the baseline is refreshed, delete the fence, move its
row here, and note the version that fixed it.

## Files with no Kati edits

Tracked, baseline-captured, and currently untouched — listed so a future edit is a deliberate act:
`MainActivity.kt`, `MobNode.kt`, `MobScannerActivity.kt`, `MobFirebaseService.kt`,
`BeamForegroundService.kt`, `android/build.gradle`, `android/settings.gradle`,
`android/gradle.properties`, `android/app/src/main/jni/CMakeLists.txt`, `ios/beam_main.m`,
`ios/AppDelegate.m`, `ios/build.zig`, `ios/build_device.zig`.
