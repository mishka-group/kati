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
- The emulator fills up. When `/data` is short of space the APK install fails
  **silently**, the deploy reports "not installed (ABI mismatch…)", and the app
  disappears. `adb shell df /data` first; `pm trim-caches` reclaims some.

## Vendored native code

`android/` and `ios/` are third-party. Do not edit outside `KATI-BEGIN`/`KATI-END`
fences, and add a row to `native/LEDGER.md` for every fence — a test enforces
both. Prefer, in order: Elixir → a Mob plugin → `Mob.Component` → a bridge edit.
See `native/README.md`.

## Configuration

`config/*.exs` is **host-only**; the device never reads it. Anything read at
runtime belongs in `Kati.Runtime`, which is the only module allowed to call
`Application.put_env/3`.
