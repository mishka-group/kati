# Working on Kati

Read this before touching `lib/`. Every rule here exists because the device
proved it, not because it sounded tidy.

## Screens subscribe to nothing

A screen is **transient**. Mob keeps exactly one screen process alive and it dies
on every root switch. So a screen must never hold anything that outlives it:

- no PubSub or Ash notifier subscription
- no `Process.send_after/3` or `:timer.send_interval/3` past one render
- no `Registry.register/3`, no `Process.register/2`
- no PIDs or large collections in `assigns` — one heap, repeatedly scanned

Long-lived work goes under **`Kati.Supervisor`**. A supervised process pushes to
the UI with `send(:mob_screen, {:kati, topic, payload})`, addressed **by topic**:
every screen implements `handle_kati/3` for topics it cares about and the
catch-all drops the rest, so a message arriving after navigation is discarded
rather than landing on the wrong module.

`Kati.SupervisionRuleTest` fails the build if a screen breaks this.

## Mob does not supervise anything

`Mob.Screen`'s moduledoc and Mob's architecture guide both claim a supervisor
restarts a crashed screen. There is none — `start_root/3` is a bare
`GenServer.start_link`. An unsupervised screen that crashes stays dead and the
app simply looks frozen. Kati starts the root screen under its own supervisor;
verified on device by killing `:mob_screen` and watching it come back.

## Layout rules that are not obvious

- A **`Box` always fills its parent's width** unless it has an explicit `width`
  (`MobBridge.kt:2662`). `fill_width: false` does **not** opt out. Mob's README
  says otherwise and is wrong for Box on Android.
- `Row` and `Column` hug their content. Use them for anything content-sized.
- Overlays need **`fill_height: true`**, or `align:` has no viewport to align
  against.
- **Nothing wraps** and no geometry is reported back to `render/1`. Grids are
  chunked by a **declared** column count; bar widths are declared, never
  measured.
- Inside `~MOB`, `@name` means an **assign**, not a module attribute. Bind module
  attributes to a local first.

## Deploying

- **`mix mob.deploy` does not sync `priv/`.** A migration change deployed by the
  fast path never reaches the device; the app runs a stale schema and logs
  "Migrations already up". Migrations require **`--native`**.
- **`mix mob.deploy` hot-loads over distribution and does not write BEAMs to
  disk** while the app is running (`✓ (dist, no restart)`). The change is live
  until the app is killed, then silently reverts to the last `--native` deploy.
  Force-stop first if you need it persisted.
- If the screen goes **black** after a rebuild, force-stop and relaunch before
  debugging your code. The Elixir side is usually healthy; it is a surface issue.
- **Never `adb install` by hand.** It wipes `filesDir`, which is where the OTP
  runtime lives. A subsequent `mix mob.deploy` then pushes BEAMs to a device with
  no runtime, and the BEAM starts and dies before the first Elixir step **with no
  error in logcat**. Only `--native` pushes the runtime back.
- Use **`bin/deploy_native.sh`** instead of `mix mob.deploy --native` — it reclaims
  disk first. The emulator fills up. When `/data` is short of space the APK install fails
  **silently**, the deploy reports "not installed (ABI mismatch…)", and the app
  disappears. `adb shell df /data` first; `pm trim-caches` reclaims some.

- **A `--native` deploy can overwrite the BEAMs it just built.** The pass
  re-pushes the whole OTP tree, and that tree carries its own older
  `kati/*.beam`. Verified by pulling `Elixir.Kati.App.beam` off the device and
  finding a function compiled minutes earlier had gone. Always follow with a
  plain `mix mob.deploy --android`; `bin/deploy_native.sh` now does both.
- **`mix mob.release --android` leaves a 43MB `android/app/src/main/assets/otp.zip`
  behind, and it poisons every later debug build.** Gradle packs the asset into
  the debug APK too, and `MobBridge.extractOtpIfNeeded()` unpacks it over
  `<filesDir>/otp` on the next clean install — replacing freshly deployed BEAMs
  with whatever was compiled when the release ran. MobBridge's own doc comment
  says debug builds have no such asset; running a release makes that false. The
  symptom is code that does not take effect, with a correct source tree.
  Gitignored, and `bin/deploy_native.sh` deletes it.
- **Verify the binary, not the deploy output.** Every trap above reports success.
  `adb shell "run-as com.example.kati cat files/otp/kati/Elixir.Kati.App.beam"`
  piped into `beam_lib:chunks(…, [exports])` says what is actually on the device.

## Starting applications on device

- **Never `Application.ensure_all_started(:ash)`.** `ash.app` names `:igniter` —
  a compile-time codegen tool — in its runtime `applications`, and igniter needs
  `:inets`, which the Android OTP runtime does not ship (20 libs, none of them
  inets). A **fresh install** dies with
  `step 5 => {error,{badmatch,{error,{inets,{"no such file or directory","inets.app"}}}}}`
  and never draws a screen. It hides on any device deployed to before, because
  the older OTP tree survives; only wiping app data reproduces it, which is
  exactly what a user's first install does. `Kati.App.start_ash!/0` walks the
  closure and starts only what has a supervision tree.
- **`:reactor` cannot be started at all** — its own dependency list reaches
  igniter, so `application_controller` refuses it. `Kati.Supervisor` starts
  upstream's `Reactor.Application.start/2` directly instead, so the processes
  exist even though the bookkeeping entry does not.
- **Prefer `Ecto.Migrator.run/4` to `with_repo/2`.** The helper starts
  `:ecto_sql`, the adapter's apps and a second pool, all of which Kati has
  already done, against a repo deliberately at `pool_size: 1`.

## Dates in screens

- **`Kati.Time.now/0` and `Kati.Time.today/0`, never `DateTime.utc_now/0`.** For
  the first two hours of every Amsterdam day a UTC-derived date names yesterday.
  Found by opening the app at 00:01 and reading "Tuesday 18". Enforced by
  `Kati.ScreenDateTest`.

## Vendored native code

`android/` and `ios/` are third-party. Do not edit outside `KATI-BEGIN`/`KATI-END`
fences, and add a row to `native/LEDGER.md` for every fence — a test enforces
both. Prefer, in order: Elixir → a Mob plugin → `Mob.Component` → a bridge edit.
See `native/README.md`.

## Configuration

`config/*.exs` is **host-only**; the device never reads it. Anything read at
runtime belongs in `Kati.Runtime`, which is the only module allowed to call
`Application.put_env/3`.
