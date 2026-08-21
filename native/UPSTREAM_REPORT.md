# Upstream defect report — mob / mob_new

Prepared for #76. **Not yet filed.** Filing means opening issues on a
third-party project, which is the owner's call and needs the owner's account —
this file is the report, ready to paste.

Every defect below was found by landing #28 and is reproducible on a **stock**
`mix mob.new` project. `mix mob.doctor` reports a clean environment throughout,
which is part of the problem: none of these announce themselves.

Environment, from `native/UPSTREAM`:

    mob_new 0.4.20 · mob 0.7.20 · mob_dev 0.6.23
    NDK 27.2.12479018 · zig 0.15.2 · erts 17.0

Minimal reproduction for all three: `mix mob.new`, then
`mix mob.deploy --native --android`.

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
`mix mob.new` project building on a current NDK and not building at all — and
between Kati carrying permanent local patches and carrying none. All of Kati's
patches are fenced as `KATI-BEGIN(K-01 …)` and can be retired the moment these
land upstream; the fences will be updated to cite the issue numbers once filed.
