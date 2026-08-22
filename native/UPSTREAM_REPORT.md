# Upstream defect report — mob / mob_new

Prepared for #76. **Not yet filed.** Filing means opening issues on a
third-party project, which is the owner's call and needs the owner's account —
this file is the report, ready to paste.

Defects 1-3 were found by landing #28. Defects 4-8 were found by #75 (pruning
dependencies) and #77 (the AGP 9 / Kotlin 2 migration). All are reproducible on
a **stock** `mix mob.new` project. `mix mob.doctor` reports a clean environment throughout,
which is part of the problem: none of these announce themselves.

Environment, from `native/UPSTREAM`:

    mob_new 0.4.20 · mob 0.7.20 · mob_dev 0.6.23
    NDK 27.2.12479018 · zig 0.15.2 · erts 17.0

Minimal reproduction for 1-3 and 6-8: `mix mob.new`, then
`mix mob.deploy --native --android`. For 4-5, additionally set AGP to 9.x and
Gradle to 9.x.

---

## 1. `beam_jni.c` calls `mob_deliver_location`, which no longer exists

Removed from core **and** from `mob_beam.h` when Location moved to the
`mob_location` plugin, but still emitted by the `mob_new` template. Under
NDK 27 / clang 18 an implicit function declaration is an **error**, so a stock
project does not compile at all:

    beam_jni.c:117:5: error: call to undeclared function 'mob_deliver_location';
    ISO C99 and later do not support implicit function declarations

Worth flagging to the maintainer: the CHANGELOG for that extraction states
*"The same location surface was removed from the `mob_new` generated-app
templates"* — it was not. So the release notes assert the fix that is missing,
which is why this survived.

Kati's fence: `K-01 drop-location-stub`.

## 2. 33 JNI stubs reference symbols removed from core but still declared in `mob_beam.h`

`mob_deliver_camera_frame` plus 32 `mob_deliver_bt_*`. These **compile and
link** — the header still declares them — and then `dlopen` resolves eagerly at
load, so the app dies before a line of Elixir runs:

    java.lang.UnsatisfiedLinkError: dlopen failed: cannot locate symbol
    "mob_deliver_camera_frame" referenced by "libkati.so"

The failure is at process start with no Elixir stack, which makes it read like a
broken install rather than a template desync.

Suggested fix: the header should drop the declarations in the same change core
drops the definitions, and the template should stop emitting the stubs.

Kati's fence: `K-01 drop-plugin-stubs`.

## 3. `mob_new`'s `MobBridge.kt` does not define `torch`, which `nif_load` requires

`mob_nif.zig:3764` resolves it with `cacheRequired`, so the missing method makes
`nif_load` return −1 and kill the BEAM thread:

    java.lang.NoSuchMethodError: no static method
    "Lcom/example/kati/MobBridge;.torch(Ljava/lang/String;)V"

Either the template generates it or core downgrades it to `cacheOptional`. The
second looks right from outside: torch is a capability, and a device without one
should not prevent the runtime from loading.

Kati's fence: `K-01 torch-method`.

---

## 4. `mob_new` applies `id 'kotlin-android'`, which AGP 9 refuses

AGP 9.0 builds Kotlin itself and rejects the plugin outright. This is a hard
error at configuration time, so **no generated app configures on AGP 9**:

    Failed to apply plugin 'kotlin-android'.
    > The 'org.jetbrains.kotlin.android' plugin is no longer required for
      Kotlin support since AGP 9.0

Fix: drop the line from the template when AGP >= 9. Kati's fence:
`K-32 agp9-builtin-kotlin`.

---

## 5. The generated manifest sets `android:extractNativeLibs`, which AGP 9 rejects

AGP 9 fails `packageDebug` when the attribute is present in the manifest:

    android:extractNativeLibs is set to "true" in AndroidManifest.xml.
    Avoid setting android:extractNativeLibs="true" explicitly in
    AndroidManifest.xml, and instead set
    android.packagingOptions.jniLibs.useLegacyPackaging to true in the build
    script.

This one deserves a note beyond "move it", because the setting is **load
bearing for mob specifically**: `mob_start_beam` re-`dlopen`s `libkati.so` by
absolute path out of the native lib dir (`mob_beam.zig`), which only exists
when the `.so` is extracted rather than mapped from the APK. A template that
moves this to `packaging { jniLibs { useLegacyPackaging = true } }` keeps the
behaviour; one that simply deletes it will produce apps that fail to start the
BEAM on a device, with no obvious connection to the change.

Kati's fences: `K-32 agp9-extract-native-libs`, `K-32 agp9-legacy-jnilibs`.

Together, 4 and 5 mean a stock `mix mob.new` project cannot move to AGP 9 at
all. Kotlin 2.4.10 itself was clean — zero K2 errors against ~4,800 lines of
generated `MobBridge.kt`.

---

## 6. The template emits four whole subsystems that core has removed or never wires

`mob_new` 0.4.20 generates Location, Camera capture, Camera preview + live
frame stream, and QR scanner surfaces into `MobBridge.kt`, plus their
`MobScannerActivity.kt` / `MobFirebaseService.kt` files and their Gradle
dependencies. None is reachable:

| Surface | Why it cannot be called |
|---|---|
| `location_get_once` / `_start` / `_stop` | Location was extracted to `mob_location`; the 0.7.20 CHANGELOG says core "no longer provides any location surface and there is intentionally no compatibility shim". `:mob_nif.location_get_once/0` raises. |
| `camera_capture_*`, `camera_*_preview`, `camera_*_frame_stream` | No `cacheRequired`/`cacheOptional` entry in `mob_nif.zig`; name appears nowhere in `deps/mob`. |
| `scanner_scan` | Same. |
| `biometric_authenticate` | Same. |
| `notify_register_push` | Same — and `:mob_nif` has no notify entry at all in 0.7.20. |

The cost is not cosmetic. Removing them from Kati took the APK from **80.3 MB
to 62.7 MB** — a 21.9% reduction, measured with `./gradlew clean assembleDebug`
at three commits. ML Kit alone contributes a ~10 MB native barcode library
(`libbarhopper_v3.so`) for a feature the app never had. Every generated app
also declares camera and location capability to anyone reading its manifest,
including Play's data-safety form.

Suggestion: gate these behind `mix mob.enable`, the way file sharing already
is, rather than emitting them by default.

Kati's fences: `K-30 drop-location`, `K-30 drop-push`, `K-31
drop-camera-scanner-biometric`.

---

## 7. Every Mob app targeting API 31+ draws its launch logo twice, at two sizes

Not a crash — a visible defect in every generated app on Android 12+.

The Android 12 system splash scales the adaptive launcher icon into a **288dp**
canvas. `AppTheme`'s `android:windowBackground` then takes over and draws the
**same** `ic_launcher_foreground` bitmap at its natural **108dp**. The mark
occupies the same fraction of the canvas either way, so it visibly shrinks to
~37% of its size partway through boot and stays small until the BEAM has a
tree to draw. Measured on a Pixel 9a: 184x294px, then 69x110px.

It is worse for Mob than for a typical app because Mob's boot is long — the
small logo sat on screen for ~3.4s of a ~5.4s cold start.

The obvious fix, deferring the first frame until the BEAM has drawn (what
`androidx.core:core-splashscreen` does), is **wrong here** and worth writing
down: `mob_start_beam` polls `Activity.hasWindowFocus()` before `erl_start()`,
and `hasWindowFocus()` only goes true once the window has drawn. Holding the
frame starves that poll — measured, it burned the full 3000 ms timeout instead
of the usual 600 ms and then started the BEAM anyway, which is exactly the
hwui/ERTS pthread race the wait exists to prevent.

So the fix belongs in the template's `drawable/splash.xml`: draw the mark at
the size the system splash gives it. A first-frame signal on the bridge would
let apps do better, and would be the more useful thing to expose.

---

## 8. `nodeModifier` has no way to express a minimum size, or to cap text growth

Two missing primitives, both of which surface the moment a user raises the
system font size. Text sizes cross the wire in `sp` (`sizeProp`), so every
label scales; the containers measured to fit them do not.

* **No `min_width` / `min_height`.** `width` is a cap, so a
  `<Column width={44}>` time gutter still measures 44dp while `"08:00"` needs
  ~78 at 235% Dynamic Type, and renders `0…`. Nothing is logged — a fixed width
  is not an error, only too small. Kati added `widthIn(min=)` / `heightIn(min=)`
  as `K-28 min-size`.

* **No way to bound how far a subtree's text grows.** A 28sp display title
  becomes 66sp at 235% and wraps mid-word — one word over three lines. Kati
  added `max_font_scale` (`K-29`), applied by providing a `LocalDensity` whose
  `fontScale` is clamped while `density` passes through untouched, so dp does
  not move.

Both are a few lines in `nodeModifier` and both are needed by any Mob app that
wants to pass an accessibility review.

---

## 9. `Mob.Permissions` can request a permission and cannot read one

`Mob.Permissions.request/2` raises the dialog and delivers
`{:permission, capability, :granted | :denied}`. There is no matching read —
nothing in Mob answers *is `:calendar` granted right now*.

Any screen that draws a permission row therefore draws a guess. Kati's screen
40 lists what the app is allowed to do, and its own moduledoc had to record
that its switches were pictures: *"a switch position is a read, not a request"*.
Worse than the gap being missing is that a remembered answer is wrong exactly
when it matters — a permission can be changed in system settings while the app
is backgrounded, which is the normal way permissions get revoked, so any
app-local copy is stale precisely at the moment the user looks.

Kati added `K-33 permission-status`. Three answers rather than two, because
Android's are not symmetric:

* `granted` — `checkSelfPermission` says so.
* `denied:true` — refused once; `shouldShowRequestPermissionRationale` is true,
  so requesting again shows the dialog.
* `denied:false` — **never asked, or refused permanently.** Android reports both
  identically, so the caller has to disambiguate with its own record of having
  asked.

That third case is the one that matters on screen: once permanently denied,
`request/2` will not re-prompt, so the row must offer a deep link to system
settings rather than an Allow button that silently does nothing. Mob already
documents that behaviour — *"Once denied, `request/2` won't re-prompt; `:denied`
still fires so you can deep-link to Settings"* — which is precisely the case an
app cannot detect without this read.

A `Mob.Permissions.status/1` returning that trio would retire the whole fence.
The mapping from capability to Android permission already exists in
`request_permission`; Kati had to extract it so a read and a request could not
disagree about what `:calendar` means.

---

## 10. Not a Mob bug — a `mishka_chelekom` / `igniter` one, recorded here because it stopped work

`mix mishka.ui.gen.mob` hung: ~90% CPU, no output, no component, indefinitely.
The task listed **its own name** in `composes:`, and
`Igniter.Util.Info.recursively_compose_schema/4` walks that list with no
visited set. Each level merges a keyword list one entry longer than the last,
which is why a stack sample showed binary and list building rather than IO.

Fixed in mishka_chelekom by removing the self-reference — 23 minutes of not
terminating became 4.4 seconds. But a self-reference in `composes:` is an easy
authoring mistake and Igniter answers it with an unkillable spin rather than an
error. **A visited set in `recursively_compose_schema/4` would make it a clear
message.** Worth filing against `igniter` rather than `mob`.

---

## Smaller, same root cause

* **`build.zig` from mob_new 0.4.20 has no x86_64 arm**, yet
  `native_build.ex:359` tells you to "regenerate from mob_new >= 0.4.5 to add
  x86_64". `mob_dev` fetches the x86_64 runtime and threads it through, then
  silently skips the ABI — so a stock project has **no emulator support on an
  Intel host**, and the diagnostic points at a version that already shipped.
  Kati's fence: `K-01 abi-x86-64`.
* **`zig` is required for the native build**, but neither `mix mob.install` nor
  `mix mob.doctor` checks for it. It fails mid-build instead of at doctor time,
  which is the one place designed to catch it.
* **`mob.doctor.ex:174` says "device runtime is OTP 28"**; the tarball ships
  `erts-17.0`, which is OTP 29.

---

## Why this is worth the maintainer's time

Each one is a few lines. Together they are the difference between a stock
`mix mob.new` project building on a current NDK and not building at all; between
one moving to AGP 9 and not moving at all; and between every generated app
shipping ~18 MB of unreachable subsystems and shipping none. They are also the
difference between Kati carrying permanent local patches and carrying none. All of Kati's
patches are fenced as `KATI-BEGIN(K-01 …)` and can be retired the moment these
land upstream; the fences will be updated to cite the issue numbers once filed.
