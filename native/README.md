# The vendored native shell

`android/` and `ios/` are **third-party code**, generated once by `mix mob.new` and committed.
They are not Kati's to freely edit.

## Why this directory exists

Mob ships no host-app Kotlin. Every Mob app's `MobBridge.kt` is its own diverged copy, generated
at project creation and never updated again — there is no `mix mob.upgrade`, no template resync,
and no bridge diff among Mob's 46 mix tasks. Mob's own `PLAN.md` concedes the problem and lists
three candidate fixes, none implemented:

> When Mob adds a feature that needs Kotlin support … every app has to be patched independently.
> When a Kotlin-side bug is fixed in one app … the fix doesn't propagate. This is sustainable
> while there are ~2 Mob apps. It will become a real problem at ~10.

Upstream ships a release every 1–3 days, and v0.7.0 was a hard breaking change with no
compatibility shims. **The failure mode is silence, not a crash**: the Android node dispatch is a
`when` with no `else`, so a node type an older bridge does not recognise renders nothing at all.

## The standing rule

**Prefer anything over a bridge edit.** In order:

1. **Elixir** — most things belong in `lib/kati/`, which upstream never touches.
2. **A Mob plugin** — plugins carry their own Kotlin/Swift, Gradle deps and manifest entries, and
   survive upgrades intact.
3. **`Mob.Component` + a native view** — pairs an Elixir process with a registered native view,
   living in Kati's own code.
4. **A bridge edit** — last resort. Every one is permanent merge cost, forever.

If you are about to edit `MobBridge.kt`, first check whether options 1–3 can do the job.

## The fence convention

Every Kati change to a tracked file is fenced — including one-line changes, **and including
deletions**, which record what was removed so an upstream change cannot silently reinstate it.

```kotlin
// KATI-BEGIN(K-01 torch-method) mob_new=0.4.20
@JvmStatic fun torch(state: String) { … }
// KATI-END(K-01 torch-method)
```

```xml
<!-- KATI-BEGIN(K-01 permission-trim) mob_new=0.4.20
     DELETED: android.permission.CAMERA, android.permission.RECORD_AUDIO, …
-->
<!-- KATI-END(K-01 permission-trim) -->
```

The label is `(K-nn slug)` — the ticket that introduced the edit plus a stable slug — followed by
the `mob_new` version it was written against. `test/kati/native_ledger_test.exs` fails the build if
a fence is unbalanced or missing from `LEDGER.md`.

## Upgrading Mob

```bash
bin/mob_bridge_diff.sh            # what changed upstream, and where it collides
bin/mob_bridge_diff.sh --merge    # write .merge files for the collisions
bin/mob_bridge_diff.sh --refresh  # re-capture the baseline once the merge is done
```

The three-way merge needs `native/baseline/<version>/`, an unmodified copy of every tracked file
exactly as generated. Without it there is only a two-way diff, which cannot distinguish an upstream
change from a Kati edit — which is the whole problem. `native/UPSTREAM` holds the pins and a
sha256 per baseline file; the script refuses to run if the baseline has been tampered with.

After any upgrade: rebuild, run the suite, and **launch the app on a device**. Tiers 1 and 2
structurally cannot see a dropped node type.

## What is NOT here, and why

The iOS renderer — `MobRootView.swift`, `mob_nif.m` — is **not app-owned**. It lives inside the
`mob` hex package at `deps/mob/ios/`. Changing it means forking the dependency or sending an
upstream patch, which is a different mechanic with different economics: a fork must be re-based on
every release rather than merged once. Only `ios/beam_main.m`, `ios/AppDelegate.m`,
`ios/Info.plist` and the two `ios/build*.zig` files are app-owned and tracked here.
