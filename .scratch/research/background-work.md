# Background work on device, with no server — "did my series get a new episode?"

Research date: **2026-08-17**. Versions inspected: `mob` **0.7.20** (2026-07-11),
`mob_new` **0.4.20**, `mob_dev` **0.6.23** (2026-07-12), `mob_notify` **0.1.2**,
`mob_background` **0.1.0**, `mob_screencast` 0.1.1, `mob_nfc` 0.1.0, `mob_ash` 0.1.1.

**How to re-verify every source claim.** Hex tarballs were extracted locally. Reproduce with:

```bash
mkdir -p /tmp/mobsrc && cd /tmp/mobsrc
tar xf ~/.hex/packages/hexpm/mob-0.7.20.tar     && mkdir -p mob    && tar xzf contents.tar.gz -C mob
tar xf ~/.hex/packages/hexpm/mob_new-0.4.20.tar && mkdir -p mobnew && tar xzf contents.tar.gz -C mobnew
tar xf ~/.hex/packages/hexpm/mob_dev-0.6.23.tar && mkdir -p mobdev && tar xzf contents.tar.gz -C mobdev
curl -O https://repo.hex.pm/tarballs/mob_notify-0.1.2.tar      # not cached locally by default
curl -O https://repo.hex.pm/tarballs/mob_background-0.1.0.tar
```

Line numbers below are **inside the extracted package**, e.g.
`mob_notify-0.1.2 :: priv/native/android/MobNotifyBridge.kt:147-163`.

---

## 0. The answer, up front

**You can do this on device with no server on Android. You cannot do it reliably on iOS
without a server. Design for that asymmetry now, not later.**

The single most important structural fact I verified — and it is *not* in any Mob
document — is this:

> **`erl_start()` never returns, and it is called once, from `MainActivity.onCreate`,
> on a thread that first waits for an Activity window to gain focus.**

`mob-0.7.20 :: android/jni/mob_beam.zig:707-712`:

```zig
    // erl_start blocks forever in the normal case. If it returns at all the
    // ...
    erl_start(@intCast(ac), @ptrCast(&args));

    loge("mob_start_beam: erl_start returned (unexpected)", .{});
```

`mob_new-0.4.20 :: priv/templates/mob.new/android/app/src/main/java/MainActivity.kt.eex:246-248`:

```kotlin
        Log.i(TAG, "onCreate — handing off to BEAM")
        nativeSetActivity(this)
        Thread({ nativeStartBeam() }, "beam-main").start()
```

Therefore **"boot a headless BEAM in a WorkManager Worker, run one Elixir function, shut
down" is not a thing Mob supports, and is not a thing ERTS supports.** There is no
`erl_stop`-and-restart path; ERTS is a process-lifetime singleton. (See §2 for the full
list of blockers, including the documented SIGABRT cold-start race.)

The consequence is the whole design:

| Layer | Runs where | Wakes the BEAM? |
|---|---|---|
| **Known air date → local notification** | `AlarmManager.setExactAndAllowWhileIdle` armed by `MobNotify.schedule/2`; displayed by the host `NotificationReceiver` BroadcastReceiver | **No.** Fires while force-quit. |
| **"Is there a new episode?" periodic fetch** | **Kotlin `CoroutineWorker` under WorkManager**, HTTP in Kotlin, result written to a JSON file in `filesDir` | **No.** BEAM ingests on next launch. |
| **Everything else** | BEAM, foreground only | n/a |

Option 3 in the brief (fetch in Kotlin, hand off a file, notify natively, never start the
BEAM) is **the correct architecture**, not a fallback. §3 argues it on the merits.

---

## 1. Re-verification of the prior research's claims

All four claims from `mob-framework.md` hold. Two need refinement, and I found one
**material correction** to the plugin-system claim.

| Prior claim | Verdict | Evidence |
|---|---|---|
| The BEAM stops when the app is backgrounded | **TRUE on iOS, IMPRECISE on Android** | See below |
| iOS has no `BGTaskScheduler` binding; silent push cannot wake the BEAM | **TRUE** | `grep -rn "BGTaskScheduler\|BGAppRefreshTask\|BGProcessingTask\|performFetchWithCompletionHandler" mob-0.7.20/ios/ mob_new-0.4.20/priv/templates/mob.new/ios/` → **zero matches**. The only `UIBackgroundModes` occurrence is `mob_new-0.4.20 :: priv/templates/mob.new/ios/Info.plist.eex:33-36`, value `[audio]`. |
| Android has no WorkManager binding | **TRUE** | `grep -rn "WorkManager\|androidx.work" ` over `mob-0.7.20/`, `mob_new-0.4.20/priv/`, `mob_dev-0.6.23/` → **zero matches**. `mob_new-0.4.20 :: priv/templates/mob.new/android/app/build.gradle.eex:112-139` has no `androidx.work` dependency. The word appears exactly once in the whole ecosystem, in prose: `mob-0.7.20 :: guides/background_execution.md` — *"Use FCM for server-initiated wakeups and WorkManager-style patterns for deferred work."* Note "**patterns**". |
| `MobNotify.schedule/2` arms a real OS alarm that fires while force-quit | **TRUE** | Full code quoted in §1.1 |

### 1.1 `MobNotify.schedule/2` — verified line by line

`mob_notify-0.1.2 :: priv/native/android/MobNotifyBridge.kt:143-171`:

```kotlin
    // Arm the AlarmManager alarm with the exact-alarm guard + inexact fallback.
    // Android 12+ (API 31) gates EXACT alarms behind SCHEDULE_EXACT_ALARM special
    // access; calling setExact* without it throws SecurityException, so guard on
    // canScheduleExactAlarms() and fall back to an inexact (battery-batched) alarm.
    private fun arm(ctx: Context, triggerAtMs: Long, pi: PendingIntent) {
        val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val canExact = if (Build.VERSION.SDK_INT >= 31) am.canScheduleExactAlarms() else true
        when {
            canExact && Build.VERSION.SDK_INT >= 23 ->
                am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMs, pi)
            canExact ->
                am.setExact(AlarmManager.RTC_WAKEUP, triggerAtMs, pi)
            Build.VERSION.SDK_INT >= 23 ->
                am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMs, pi)
            else ->
                am.set(AlarmManager.RTC_WAKEUP, triggerAtMs, pi)
        }
    }

    fun schedule(ctx: Context, id: String, triggerAtMs: Long, title: String, body: String, data: String) {
        ensureChannel(ctx)
        arm(ctx, triggerAtMs, pendingIntent(ctx, id, title, body, data))
        persist(ctx, id, triggerAtMs, title, body, data)
    }
```

The `PendingIntent` targets a **host-package BroadcastReceiver**, not the Activity
(`MobNotifyBridge.kt:122-133`):

```kotlin
    private fun pendingIntent(ctx: Context, id: String, title: String, body: String, data: String): PendingIntent {
        val intent = Intent().apply {
            setClassName(ctx, ctx.packageName + ".NotificationReceiver")
            ...
        }
        return PendingIntent.getBroadcast(
            ctx, id.hashCode(), intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }
```

And that receiver **posts the notification with no BEAM involvement whatsoever** —
`mob_new-0.4.20 :: priv/templates/.../MobBridge.kt.eex:3602-3635`:

```kotlin
class NotificationReceiver : BroadcastReceiver() {
    override fun onReceive(context: android.content.Context, intent: android.content.Intent) {
        val title   = intent.getStringExtra("title") ?: ""
        ...
        val nm = context.getSystemService(android.content.Context.NOTIFICATION_SERVICE) as NotificationManager
        val notif = NotificationCompat.Builder(context, io.mob.plugin.MobNotifyHub.CHANNEL_ID)
            ...
        nm.notify(id.hashCode(), notif)
    }
}
```

**This is the proof-of-concept for the whole architecture.** A `BroadcastReceiver` in the
host package, holding only a `Context`, already runs while the BEAM is dead and posts a
notification. A `Worker` is the same shape with a longer leash.

### 1.2 Refinement — "the BEAM stops when backgrounded" is an iOS statement

Mob's own guide (`mob-0.7.20 :: guides/background_execution.md`) says:

> "iOS suspends normal apps shortly after they enter the background. When that happens,
> BEAM schedulers stop running with the rest of the process. Timers, GenServers, sockets,
> and distribution connections do not continue like they would on a server."

For Android it says only:

> "Without a foreground service, recent Android versions restrict background execution
> heavily."

On Android the process is **not** synchronously suspended on background. It becomes a
*cached* process, and Android 11+ (API 30) then **freezes** it via the Cached Apps Freezer
— "stops execution for cached processes … keeps apps in RAM while keeping them off the
CPU" (<https://source.android.com/docs/core/perf/cached-apps-freezer>). Practically:

- The BEAM keeps running for **seconds to a couple of minutes** after backgrounding, then
  is frozen (no CPU), then eventually killed on memory pressure.
- Freeze is not a clean shutdown. Any in-flight HTTP request is left half-done, and
  `:timer`/`Process.send_after` fire late in a burst on unfreeze.
- **Do not** build anything on "the BEAM might still be alive". Treat backgrounding as
  process death, exactly as `guides/background_execution.md` advises ("Design background
  flows as resumable work").

### 1.3 Correction — the boot receiver *is* missing, but a plugin *can* now ship it

Prior research said `MobNotifyBootReceiver` is missing from the template. **Confirmed.**
`mob_new-0.4.20 :: priv/templates/.../AndroidManifest.xml.eex:83-85` declares only:

```xml
        <!-- Scheduled local notification delivery -->
        <receiver android:name=".NotificationReceiver"
            android:exported="false" />
```

There is **no** `io.mob.notify.MobNotifyBootReceiver` `<receiver>`, and no
`MobFirebaseService` `<service>` either — so **push is also not wired** in a stock
`mix mob.new` app despite `mob_notify`'s `host_requirements` demanding both. The class
exists (`mob_notify-0.1.2 :: priv/native/android/MobNotifyBridge.kt:248-254`) and does
the right thing; it is simply never registered, so **every scheduled notification is
silently lost on reboot**.

`mob_notify`'s manifest says a plugin cannot fix this
(`mob_notify-0.1.2 :: priv/mob_plugin.exs:70-75`):

> "A plugin manifest can't contribute a `<receiver>` fragment (same limitation as
> mob_screencast's foreground `<service>`), so the host must add it."

**That comment is stale.** `mob_dev` **0.6.19** (released 2026-07-07) added the feature —
`mob_dev-0.6.23 :: CHANGELOG.md:91-104`:

> **Added**
> - **Plugins can contribute AndroidManifest `<application>` components and `res/`
>   files.** Two new optional `android:` manifest keys — `manifest_application_snippets`
>   (XML fragments spliced into the app's `<application>` block, idempotent per
>   `android:name`) and `res_files` … This closes the gap that forced plugins needing a
>   `<service>`/`<receiver>`/`<provider>` + resource … to make it a manual
>   `host_requirement`. (MOB-39)

Implementation: `mob_dev-0.6.23 :: lib/mob_dev/plugin/merge.ex:53-59` (gather),
`lib/mob_dev/native_build.ex:4567` + `5296-5332` (splice before `</application>`,
de-duped on `android:name`), `lib/mob_dev/plugin/manifest.ex:177-200` (schema validation),
`lib/mob_dev/plugin/validator.ex:257-261` (cross-plugin collision on the component name).

**It is undocumented.** `mob-0.7.20 :: MOB_PLUGINS.md:669-676` still lists only
`gradle_deps / permissions / bridge_kt / jni_source / min_sdk` under `:android`, and
`grep -rn "manifest_application_snippets\|res_files" mob-0.7.20/` returns **zero
matches**. So: *the capability is real and tested in mob_dev, the docs have not caught up.*
This is what makes the plugin in §5 buildable today.

---

## 2. Every Android mechanism for periodic background work

`minSdk 28`, `targetSdk 35`, `compileSdk 35` in
`mob_new-0.4.20 :: priv/templates/mob.new/android/app/build.gradle.eex:31,42-43`.
Everything below is evaluated at **targetSdk 35 (Android 15)**.

### 2.1 Comparison table

| Mechanism | Min interval | Doze | App Standby | Battery-opt exemption | OEM survival | Play policy |
|---|---|---|---|---|---|---|
| **`WorkManager` `PeriodicWorkRequest`** | **15 min** (hard floor) | **Does not run in Doze**; runs in maintenance windows | Quota-limited per bucket (§2.3) | Not required; helps | Deferred by MIUI/EMUI but generally *eventually* runs | **Unrestricted.** Google's recommended API |
| **`JobScheduler`** | 15 min (same floor) | Same — "Doesn't let `JobScheduler` run" | Same quotas | Same | Same | Unrestricted |
| **`AlarmManager` + `BroadcastReceiver`** | No floor, but `*AndAllowWhileIdle` is **max once / 9 min per app** | `setExactAndAllowWhileIdle` / `setAndAllowWhileIdle` **do** fire in Doze; plain `setExact`/`setWindow` are deferred to maintenance window; `setAlarmClock` always fires and exits Doze | Alarm quota per bucket: unlimited / 10 per hr / 2 per hr / 1 per hr / **1 per day** | Not required for `*AndAllowWhileIdle` | **Best survival of any API** — this is what `MobNotify` already uses | `SCHEDULE_EXACT_ALARM` = user-granted special access. `USE_EXACT_ALARM` = auto-granted but **Play-restricted to alarm/calendar apps** |
| **Foreground service** (`dataSync`) | Continuous | Exempt while running | Exempt while running | Not required | Killed by aggressive OEMs anyway | **6 h / 24 h cap on Android 15**, cannot start from `BOOT_COMPLETED`, must be user-justified |
| **`SyncAdapter`** | ~15 min (`ContentResolver.addPeriodicSync`) | "Doesn't let sync adapters run" | Same as jobs | — | — | Legacy; requires an `AccountManager` account + `ContentProvider`. **Do not use.** |

### 2.2 Doze — verbatim

<https://developer.android.com/training/monitoring-device-state/doze-standby>:

> In Doze mode, the system … **Suspends network access.** … **Ignores wake locks.** …
> **Defers standard `AlarmManager` alarms, including `setExact()` and `setWindow()`, to
> the next maintenance window.** … If you need to set alarms that fire while in Doze, use
> `setAndAllowWhileIdle()` or `setExactAndAllowWhileIdle()`. … Alarms set with
> `setAlarmClock()` continue to fire normally. The system exits Doze shortly before those
> alarms fire. … **Doesn't let sync adapters run.** … **Doesn't let `JobScheduler` run.
> `WorkManager` uses `JobScheduler` internally, so `WorkManager` tasks don't run.**

And crucially:

> **Note:** Neither `setAndAllowWhileIdle()` nor `setExactAndAllowWhileIdle()` can fire
> alarms more than **once per nine minutes, per app**.

> Over time, the system schedules maintenance windows less frequently, helping reduce
> battery consumption in cases of longer inactivity when the device isn't charging.

**Read that last sentence as the design constraint.** A phone on a nightstand for 10 hours
gets progressively rarer maintenance windows. A `PeriodicWorkRequest(6h)` on such a device
may run at hour 9, not hour 6. This is *fine* for "new episode" and *not* fine for
"remind me at 20:00".

### 2.3 App Standby Bucket quotas — verbatim

<https://developer.android.com/topic/performance/power/power-details>:

| Bucket | Regular jobs | Expedited jobs | Alarms | Network |
|---|---|---|---|---|
| Active | 20 min / rolling 60 min | 30 min / rolling 24 h | No execution limits | No restrictions |
| Working set | 10 min / rolling 4 h | 15 min / rolling 24 h | 10 per hour | No restrictions |
| Frequent | 10 min / rolling 12 h | 10 min / rolling 24 h | 2 per hour | No restrictions |
| Rare | 10 min / rolling 24 h | 10 min / rolling 24 h | 1 per hour | **Disabled** |
| Restricted | Once per day, up to 10 min | 5 min / rolling 24 h | **1 alarm per day** | **Disabled** |

Restricted-bucket details (<https://developer.android.com/topic/performance/appstandby>):
jobs run "once per day in a 10-minute batched session"; "restricted jobs don't run
independently; at least one other job must be running or pending simultaneously"; and the
restrictions apply **even when charging**.

**Kati's realistic bucket.** A user who opens Kati daily (calendar, habits, money) sits in
**Active/Working set** — network unrestricted, 10 min of job time per 4 h. That is
enormous compared to what a TMDB delta poll needs. A user who abandons Kati for three
weeks falls to **Rare** (network *disabled* for jobs) or **Restricted** — and for that
user the answer is honestly "we check when you next open it", which is correct behaviour.

### 2.4 Foreground services — why `keep_alive/0` is the wrong tool here

`mob_background` 0.1.0 exists and works. `mob_background-0.1.0 ::
priv/native/android/BeamForegroundService.kt:37-46`:

```kotlin
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) { stopForeground(true); stopSelf(); return START_NOT_STICKY }
        ensureChannel()
        startForeground(NOTIF_ID, buildNotification())
        return START_STICKY
    }
```

Its own moduledoc tells you to declare it as `dataSync`
(`mob_background-0.1.0 :: lib/mob_background.ex:110-112`):

```xml
      <service android:name="io.mob.background.BeamForegroundService"
          android:exported="false"
          android:foregroundServiceType="dataSync" />
```

At targetSdk 35 that is capped
(<https://developer.android.com/develop/background-work/services/fgs/timeout>):

> **6 hours in a 24-hour period** … the system calls `Service.onTimeout(int, int)` … the
> service must call `Service.stopSelf()` within a few seconds … otherwise
> `android.app.RemoteServiceException: "A foreground service of type [service type] did
> not stop within its timeout: [component name]"` … If you attempt to start a foreground
> service after exhausting the 6-hour limit:
> `ForegroundServiceStartNotAllowedException: "Time limit already exhausted for foreground
> service type dataSync"`. The timer resets when the user brings the app to the foreground.

Three separate disqualifiers for Kati:

1. `BeamForegroundService.kt` calls `startForeground(NOTIF_ID, buildNotification())` with
   **no type argument** and implements **no `onTimeout`**. At targetSdk 34+ this is a
   latent crash. (`mob_background` 0.1.0's `mob_version` is `"~> 0.1"` in its own
   moduledoc but the manifest declares `mob_version: "~> 0.6"`; it predates Android 15
   enforcement.)
2. A permanent "Kati — Running in background" notification for a TV tracker is a UX
   disaster and an obvious 1-star magnet.
3. Play policy requires the FGS type to match a real user-visible capability. "Poll TMDB
   every 6 hours" is exactly the case Google points at WorkManager for.
   Android 15 also forbids starting `dataSync` from `BOOT_COMPLETED`
   (<https://developer.android.com/develop/background-work/services/fgs/service-types>),
   killing the "restart it on boot" trick.

**Verdict: never call `MobBackground.keep_alive/0` in Kati.** Do not even add the dep.

### 2.5 WorkManager — the chosen mechanism

<https://developer.android.com/develop/background-work/background-tasks/persistent/getting-started/define-work>:

> **Note:** The minimum repeat interval that can be defined is 15 minutes (same as the
> `JobScheduler` API).

Constraints available: `NetworkType`, `BatteryNotLow`, `RequiresCharging`, `DeviceIdle`,
`StorageNotLow`. Default backoff: `EXPONENTIAL`, 30 s, min 10 s.

For Kati the right request is **not** 15 minutes. It is:

```kotlin
PeriodicWorkRequestBuilder<EpisodeCheckWorker>(6, TimeUnit.HOURS, 2, TimeUnit.HOURS)
    .setConstraints(Constraints.Builder()
        .setRequiredNetworkType(NetworkType.CONNECTED)
        .setRequiresBatteryNotLow(true)
        .build())
    .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 30, TimeUnit.MINUTES)
    .build()
```

6 h repeat with a 2 h flex window lets the OS batch the run with other apps' wakeups,
which is the single biggest battery lever available.

### 2.6 OEM killers

<https://dontkillmyapp.com/xiaomi> — MIUI/HyperOS has "non-standard background process
limitations and non-standard permissions" where "background processing simply does not
work right and apps using them will break." Required user actions on Xiaomi: enable
**Autostart** (Security app → Permissions), set battery saver to **No restrictions**,
disable **MIUI optimizations** in developer settings, **lock the app in recents** (drag
down), set power plan to **Performance** + mark app **Protected**.

Concrete facts to design around:

- `dontkillmyapp.com` **does not publish per-OEM numeric benchmark results** on that page —
  I looked; it is configuration guidance only. Anyone quoting "Xiaomi kills 90% of alarms"
  is quoting a blog, not the source. **UNKNOWN: real measured OEM kill rates for
  `setExactAndAllowWhileIdle` in 2026.**
- **Force-stop is the nuclear case and it is universal, not OEM-specific.** If the user (or
  an OEM task-killer) force-stops the package, Android puts it in the *stopped* state:
  all alarms cancelled, all `PendingIntent`s dead, all WorkManager jobs cancelled, and
  **no broadcast will reach it** — including `BOOT_COMPLETED` — until the user manually
  launches the app again. Android 15 extended this to widgets
  (<https://www.tomsguide.com/phones/android-phones/force-stopping-an-android-15-app-will-also-temporarily-kill-its-widgets>).
  Nothing you write can survive this. Do not try.
- **Practical mitigation, in priority order:**
  1. `AlarmManager.setExactAndAllowWhileIdle` for anything date-known — it is the API with
     the best OEM survival, and Mob already uses it.
  2. WorkManager for the fetch — the OEMs defer it but nearly all *eventually* run it,
     because too many mainstream apps would break otherwise.
  3. **Belt-and-braces: also re-check on every app foreground.** A user who opens Kati
     daily never notices that WorkManager was throttled.
  4. Ship a **"Notifications not arriving?"** screen (Kati already has a Settings area per
     `design-index.md`) that deep-links to
     `Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` and, on Xiaomi/Huawei/OPPO,
     shows the OEM-specific instructions. **Warning:** `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`
     is a Play-policy-restricted permission — an app must qualify for an exemption use
     case. Kati almost certainly does **not**. Use
     `ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS` (opens the list, no permission needed)
     instead of requesting the exemption directly.

---

## 3. Can a Worker talk to the BEAM? (Q2) — five hard blockers

The answer is **no, not without forking Mob**, and the reasons are worth spelling out
because they also rule out several tempting variants.

### Blocker 1 — the JNI symbol is bound to `MainActivity`

`mob_new-0.4.20 :: priv/templates/mob.new/android/app/src/main/jni/beam_jni.c.eex:21-29`:

```c
JNIEXPORT void JNICALL
Java_<%= jni_package %>_MainActivity_nativeSetActivity(JNIEnv* env, jobject thiz, jobject activity) {
    mob_init_bridge(env, activity);
}

JNIEXPORT void JNICALL
Java_<%= jni_package %>_MainActivity_nativeStartBeam(JNIEnv* env, jobject thiz) {
    mob_start_beam(APP_MODULE);
}
```

A `class EpisodeCheckWorker` declaring `external fun nativeStartBeam()` resolves to
`Java_<pkg>_EpisodeCheckWorker_nativeStartBeam`, which does not exist →
`UnsatisfiedLinkError`. You would have to add an export to `beam_jni.c`. That file *is*
host-editable ("Generated by mix mob.new. Edit the two defines below; do not touch the
rest.") so this blocker alone is surmountable — the next four are not.

### Blocker 2 — `erl_start` blocks forever; ERTS starts once per process

Quoted in §0. A `Worker` that called it would never return from `doWork()`. WorkManager
would eventually time out and the OS would kill the process. And ERTS cannot be
started twice in one process — the second call is undefined behaviour. Since the
Worker and the Activity share one process (default `android:process`), a user opening the
app while the Worker holds a BEAM would be a two-ERTS-instances crash.

### Blocker 3 — `mob_start_beam` polls `Activity.hasWindowFocus()`

`mob-0.7.20 :: android/jni/mob_beam.zig:432-509`, comment header verbatim:

```zig
    // ── Cold-start race condition fix ────────────────────────────────────────
    //
    // DO NOT REMOVE THIS BLOCK.
    //
    // Problem: on a cold start (first launch after install or after the process
    // was killed), calling erl_start() too early causes a SIGABRT deep inside
    // ERTS pthread initialisation.  The crash looks like:
    //
    //   FORTIFY: pthread_mutex_lock called on a destroyed mutex
    //     #03  erl_start
    //
    // Root cause: Android's hwui (hardware-accelerated UI renderer) creates its
    // own native thread pool during the very first layout/draw pass. …
    // Fix: poll Activity.hasWindowFocus() every 50 ms before calling erl_start().
```

and the code (`mob_beam.zig:479-496`):

```zig
    if (g_jvm) |jvm| {
        if (g_activity != null) {
            mob_set_startup_phase("Waiting for window focus…");
            ...
            const act_cls = jni.getObjectClass(env2, g_activity);
            const has_focus = jni.getMethodID(env2, act_cls, "hasWindowFocus", "()Z");
            var waited: i32 = 0;
            const max_wait: i32 = 3000; // ms — fall through if focus never arrives
            while (jni.callBooleanMethod(env2, g_activity, has_focus) == 0 and waited < max_wait) {
```

In a Worker there is no window. Two bad outcomes: pass the Worker's `Context` as
`g_activity` and `getMethodID(..., "hasWindowFocus")` returns null with a pending
`NoSuchMethodError` → `callBooleanMethod` on a null method ID → ART abort; or leave
`g_activity` null and skip the wait, in which case the documented SIGABRT race is
**unmitigated and unmeasured** in a no-window process. *UNKNOWN whether the hwui race even
exists without a window — but "probably fine" is not an answer for a crash the framework
author wrote 40 lines of comment about.*

Note `mob_init_bridge` itself would technically work with a plain `Context` — it calls
`android/content/Context` methods (`mob_beam.zig:197-219`):

```zig
    const ctx_cls = jni.findClass(env, "android/content/Context");
    const get_app_info = jni.getMethodID(env, ctx_cls, "getApplicationInfo", "()Landroid/content/pm/ApplicationInfo;");
    ...
    const get_files_dir = jni.getMethodID(env, ctx_cls, "getFilesDir", "()Ljava/io/File;");
```

That is useful (see §4) but not sufficient.

### Blocker 4 — the whole plugin bridge contract is Activity-typed

`mob_dev-0.6.23 :: lib/mob_dev/native_build.ex:5025-5029` and the generated bootstrap
(`native_build.ex:5148-5176`) produce `MobPluginBootstrap.registerAll(activity: Activity)`
which calls `(bridge as? MobActivityAware)?.setActivity(activity)`. Every plugin bridge
stores a `WeakReference<Activity>` and early-returns when it is null:

```kotlin
    @JvmStatic
    fun notify_schedule(pid: Long, optsJson: String) {
        val activity = activityRef?.get() ?: return       // MobNotifyBridge.kt:73
```

So even after booting a headless BEAM, **`MobNotify.schedule/2` from that BEAM would
silently no-op** — no Activity, no alarm. Same for every other plugin.

### Blocker 5 — cost

| Cost | Value | Source |
|---|---|---|
| Native runtime per device | **~25 MB** (OTP tarball ~80 MB compressed, sliced per-arch) | `mob-0.7.20 :: README.md:234-236` |
| First-launch OTP extraction | Unzip `assets/otp.zip` → `filesDir/otp/`, once per install **and once per app update** (keyed on `PackageInfo.lastUpdateTime`) | `mob_new-0.4.20 :: MobBridge.kt.eex:523-546` |
| BEAM boot before `erl_start` | Re-`dlopen` self `RTLD_GLOBAL`, build ~8 env paths, **symlink every ERTS executable** into `nativeLibraryDir`, symlink the exqlite NIF, optionally extract from split APKs | `mob_beam.zig:229-247, 514-700` |
| Window-focus wait | **up to 3000 ms** before `erl_start` is even called | `mob_beam.zig:491` |
| Steady-state battery, screen off, BEAM alive | **~54–56 mAh/hr** (Moto E, armv7) / **~0–143 mAh/hr** (Moto G, arm64) vs **~200 mAh/hr** no-BEAM native baseline | `mob-0.7.20 :: guides/why_beam.md:137-143` |
| TLS from the BEAM on Android | **Broken by default** — `:public_key.cacerts_load/0` finds no bundle; you must ship a CA PEM and call `Mob.Certs.load_cacerts!/1` at boot | `mob-0.7.20 :: lib/mob/certs.ex:1-30` |

**No measured Mob BEAM cold-start-to-`Application.start` figure exists.** The prior
research's "~0.5 s boot" claim is **not in `README.md` or `why_beam.md` in 0.7.20** — I
grepped both. Treat it as **UNVERIFIED**. My own estimate from the code path (3 s focus
wait + dlopen + N symlinks + ERTS init + `Application.start` + Ecto migrations, which
`app.ex.eex` runs *on every boot*) is **1.5–4 s of CPU-bound work**. Against a 10 min /
4 h job quota that is 0.7% of budget — affordable but pointless when the same fetch in
Kotlin is ~50 ms of CPU.

`why_beam.md`'s own battery numbers are worth reading as a *caution*, not reassurance:
run 1 on the Moto G measured 74 mAh in 31 minutes (~143 mAh/hr) — for a *sleeping* BEAM.
A BEAM woken 4×/day for 3 s costs nothing; a BEAM woken 96×/day (every 15 min) starts to
matter.

**Conclusion for Q2: booting a headless BEAM from a Worker is not viable in Mob 0.7.20
and should not be attempted.** If the Mob author ever ships a `mob_workmanager` plugin
with a real headless mode, revisit. Until then, §4.

---

## 4. The Kotlin-native path (Q3) — and the exact handoff seam

### 4.1 The seam: `MOB_DATA_DIR` **is** `context.filesDir`

This is the finding that makes the whole design clean.

`mob-0.7.20 :: android/jni/mob_beam.zig:209-219` sets `s_files_dir` from
`Context.getFilesDir()`. Then `mob_beam.zig:277-278`:

```zig
    _ = jni.setenv("HOME", jni.asCStr(&s_files_dir), 1);
    _ = jni.setenv("MOB_DATA_DIR", jni.asCStr(&s_files_dir), 1);
```

So from Elixir, `System.get_env("MOB_DATA_DIR")` and from Kotlin, `context.filesDir`,
name **the same directory**. A plain file there is a first-class, verified, bidirectional
channel between a `Worker` (or `BroadcastReceiver`) and the BEAM.

**What will *not* work:**

- **`Mob.State`** — backed by **`:dets`**, not SharedPreferences
  (`mob-0.7.20 :: lib/mob/state.ex:4-6`: *"Backed by `:dets` — Erlang's disk-based term
  storage"*, file at `MOB_DATA_DIR/mob_state.dets`). Kotlin cannot write Erlang External
  Term Format. **Do not try to have the Worker write `Mob.State`.**
- **SharedPreferences from Elixir** — `MobBridge.kt.eex` exposes `storage_dir`,
  `storage_external_files_dir`, `storage_save_to_media_store` (lines 1176, 1189, 1204) and
  **no** SharedPreferences accessor. There is no NIF for it.
- **The SQLite DB from Kotlin** — technically possible (`android.database.sqlite` against
  the same file), but you would be writing to Ash/Ecto-owned tables from outside the
  schema, with no migration awareness and WAL-lock risk against a live BEAM. **Rejected.**

**Chosen format:** a single append-safe JSON file the Worker writes atomically
(`File.createTempFile` → `renameTo`) and the BEAM drains-and-truncates on launch:

```
$MOB_DATA_DIR/kati_episode_inbox.json
```

```json
{"schema":1,
 "written_at":"2026-08-17T04:12:09Z",
 "items":[
   {"kind":"episode","tmdb_show_id":1396,"season":5,"episode":14,
    "air_date":"2026-08-18","title":"Ozymandias","notified":true,
    "notification_id":"ep:1396:5:14"}
 ]}
```

`notified: true` is written by the Worker *after* it posts the notification, so the BEAM
knows not to re-notify — it just reconciles its Ash rows.

### 4.2 Kotlin fetch vs. BEAM fetch — the comparison

| | Kotlin `CoroutineWorker` | Headless BEAM |
|---|---|---|
| Feasible today | **Yes** | **No** (§3) |
| CPU per run | ~50 ms + network wait | 1.5–4 s + network wait |
| TLS trust store | Android system store, free | Must bundle a CA PEM + `Mob.Certs.load_cacerts!/1` (`lib/mob/certs.ex`) |
| APK size delta | `androidx.work:work-runtime-ktx` ≈ 300 KB | 0 (already there) |
| Survives force-quit | No (nothing does) | No |
| Runs when BEAM is dead | **Yes** | n/a |
| Business logic reuse | **Duplicated** — the "is this episode new?" rule lives in Kotlin *and* Elixir | Single source of truth |
| Testability | Kotlin unit tests; not reachable from `Mob.ScreenCase` | `Mob.ScreenCase` / ExUnit |
| OTA/hot-push updatable | **No** — Kotlin changes need a Play release | Elixir is hot-pushable |
| Debuggability | logcat | `mix mob.connect`, `:observer`, `:sys.get_state` |

**The duplication is the real cost, and it is manageable if you keep the Worker dumb.**
Design rule:

> **The Worker never decides anything. It fetches, diffs against a *precomputed watchlist
> file the BEAM wrote*, posts notifications, and appends to the inbox file.**

Two files, two directions, both plain JSON in `MOB_DATA_DIR`:

- **BEAM → Worker:** `kati_watchlist.json` — written whenever the user follows/unfollows a
  show or on app background. Contains `[{tmdb_show_id, last_seen_season, last_seen_episode,
  last_air_date_checked, title, locale}]` plus an `etag`/`last_modified` per show.
- **Worker → BEAM:** `kati_episode_inbox.json` — as above.

The Worker's entire logic is then: for each entry, `GET
/3/tv/{id}?api_key=…` (or `/tv/{id}/season/{n}`), compare
`(last_episode_to_air.season_number, .episode_number)` to `last_seen_*`, and if greater,
`nm.notify(...)` + append. That is ~120 lines of Kotlin with no domain rules in it. All
the domain — what counts as "watching", Shamsi date formatting, per-show notification
preferences — stays in Elixir and is baked into the watchlist file it writes.

**Verdict: Kotlin fetch is more robust, and by a wide margin.** It is the only option
that works, it costs an order of magnitude less battery, and the duplication is bounded to
a diff-and-notify loop.

---

## 5. The Mob plugin (Q4) — `mob_periodic`

The owner wants native additions to go through the plugin system. This is buildable
**today** against `mob_dev` ≥ 0.6.19, using the undocumented
`manifest_application_snippets` key (§1.3).

### 5.1 Package layout

```
mob_periodic/
├── mix.exs
├── lib/mob_periodic.ex                     # Elixir API
├── src/mob_periodic_nif.erl                # erl stub
└── priv/
    ├── mob_plugin.exs                      # the manifest below
    └── native/
        ├── jni/mob_periodic_nif.zig        # NIF → MobPeriodicBridge
        └── android/MobPeriodicBridge.kt    # bridge + Worker + BootReceiver, ONE file
```

**Single-file Kotlin is mandatory.** `mob_dev` copies exactly the one `bridge_kt` path
(`native_build.ex:5040-5055`, dest = `android/app/src/main/java/<package as dirs>/<basename>`)
and the plugin signer signs only that path. `mob_notify` hit the same constraint and
documented it (`MobNotifyBridge.kt:27-32`): *"Kotlin allows multiple top-level declarations
per file, so all three ship together under the declared bridge_kt."* Put `object
MobPeriodicBridge`, `class EpisodeCheckWorker`, and `class MobPeriodicBootReceiver` in one
file.

### 5.2 `priv/mob_plugin.exs`

```elixir
%{
  name: :mob_periodic,
  mob_version: "~> 0.7",
  plugin_spec_version: 1,
  description:
    "Deferred periodic background work via WorkManager — runs a Kotlin worker with no " <>
      "BEAM involvement, hands results to the BEAM through a JSON file in MOB_DATA_DIR.",
  nifs: [
    # Android only. iOS gets a no-op Elixir shim (see MobPeriodic.enqueue/2).
    %{module: :mob_periodic_nif, native_dir: "priv/native/jni", lang: :zig, platform: :android}
  ],
  android: %{
    bridge_kt: "priv/native/android/MobPeriodicBridge.kt",
    bridge_class: "io.mob.periodic.MobPeriodicBridge",
    gradle_deps: ["androidx.work:work-runtime-ktx:2.9.1"],
    permissions: [
      # Re-enqueue the periodic work after reboot. WorkManager persists its own
      # queue in its Room DB and re-enqueues itself on boot via its own
      # RescheduleReceiver, but our boot receiver ALSO re-arms MobNotify's
      # AlarmManager schedules, which are NOT persisted by the OS.
      "android.permission.RECEIVE_BOOT_COMPLETED",
      "android.permission.POST_NOTIFICATIONS"
    ],
    # mob_dev >= 0.6.19 (CHANGELOG 0.6.19, MOB-39). Spliced into <application>,
    # idempotent on android:name. NOT documented in MOB_PLUGINS.md as of mob 0.7.20.
    manifest_application_snippets: [
      """
      <receiver android:name="io.mob.periodic.MobPeriodicBootReceiver"
          android:exported="true"
          android:directBootAware="false">
          <intent-filter>
              <action android:name="android.intent.action.BOOT_COMPLETED" />
              <action android:name="android.intent.action.MY_PACKAGE_REPLACED" />
              <action android:name="android.intent.action.TIME_SET" />
              <action android:name="android.intent.action.TIMEZONE_CHANGED" />
          </intent-filter>
      </receiver>
      """,
      # Fixes mob_notify 0.1.2's missing declaration (see §1.3). Safe to ship here:
      # the splice is idempotent on android:name, so a host that already declared
      # it is untouched, and cross_validate only errors if ANOTHER plugin also
      # declares the same android:name.
      """
      <receiver android:name="io.mob.notify.MobNotifyBootReceiver"
          android:exported="true">
          <intent-filter>
              <action android:name="android.intent.action.BOOT_COMPLETED" />
          </intent-filter>
      </receiver>
      """
    ]
  },
  ios: %{},
  host_requirements: [
    "iOS: MobPeriodic.enqueue/2 is a no-op. Nothing on iOS can run a periodic fetch " <>
      "for a Mob app today (no BGTaskScheduler binding). See background-work.md §6."
  ]
}
```

**Caveat to verify before shipping:** the second snippet declares a component owned by
`mob_notify`. `mob_dev`'s cross-plugin validator collides on
`manifest_application_snippets` `android:name`
(`validator.ex:257-261`) — that only fires if **two plugins** declare the same name, and
`mob_notify` 0.1.2 does not declare it at all, so today this is safe. If `mob_notify`
0.1.3+ adds it, drop the second snippet. **Better long-term: open a PR on `mob_notify`
adding it there.**

### 5.3 `MobPeriodicBridge.kt` — shape

```kotlin
package io.mob.periodic

import android.app.Activity
import android.content.*
import androidx.work.*
import java.lang.ref.WeakReference

object MobPeriodicBridge : io.mob.plugin.MobActivityAware {
    private var activityRef: WeakReference<Activity>? = null
    const val WORK_NAME = "mob_periodic_episode_check"

    @JvmStatic external fun nativeRegister()
    @JvmStatic fun register() = nativeRegister()
    override fun setActivity(activity: Activity) { activityRef = WeakReference(activity) }

    // Called from Elixir: MobPeriodic.enqueue(interval_minutes: 360, flex_minutes: 120)
    @JvmStatic
    fun periodic_enqueue(pid: Long, optsJson: String) {
        val ctx = activityRef?.get()?.applicationContext ?: return
        val opts = org.json.JSONObject(optsJson)
        enqueue(ctx, opts.optLong("interval_minutes", 360),
                     opts.optLong("flex_minutes", 120))
    }

    @JvmStatic
    fun periodic_cancel() {
        val ctx = activityRef?.get()?.applicationContext ?: return
        WorkManager.getInstance(ctx).cancelUniqueWork(WORK_NAME)
    }

    // Context-only — callable from the boot receiver too.
    fun enqueue(ctx: Context, intervalMin: Long, flexMin: Long) {
        val req = PeriodicWorkRequestBuilder<EpisodeCheckWorker>(
                intervalMin, java.util.concurrent.TimeUnit.MINUTES,
                flexMin,     java.util.concurrent.TimeUnit.MINUTES)
            .setConstraints(Constraints.Builder()
                .setRequiredNetworkType(NetworkType.CONNECTED)
                .setRequiresBatteryNotLow(true)
                .build())
            .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 30,
                java.util.concurrent.TimeUnit.MINUTES)
            .build()

        // KEEP, not REPLACE: REPLACE restarts the interval clock on every app
        // launch, so a user who opens Kati daily would never reach the 6h mark.
        WorkManager.getInstance(ctx).enqueueUniquePeriodicWork(
            WORK_NAME, ExistingPeriodicWorkPolicy.KEEP, req)
    }
}

class EpisodeCheckWorker(ctx: Context, params: WorkerParameters)
    : CoroutineWorker(ctx, params) {

    override suspend fun doWork(): Result {
        val dir = applicationContext.filesDir          // == MOB_DATA_DIR (mob_beam.zig:278)
        val watchlist = java.io.File(dir, "kati_watchlist.json")
        if (!watchlist.exists()) return Result.success()   // BEAM hasn't written one yet
        return try {
            val found = checkShows(watchlist)              // OkHttp/HttpsURLConnection
            if (found.isNotEmpty()) {
                postNotifications(found)                  // NotificationManagerCompat
                appendInbox(java.io.File(dir, "kati_episode_inbox.json"), found)
            }
            Result.success()
        } catch (e: java.io.IOException) {
            Result.retry()                                // exponential backoff
        } catch (e: Exception) {
            Result.failure()                              // don't retry a bug forever
        }
    }
}

class MobPeriodicBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED -> {
                MobPeriodicBridge.enqueue(context, 360, 120)
                io.mob.notify.MobNotifySchedules.rearmAll(context)   // §7.4
            }
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED -> {
                // Wall-clock alarms are now wrong. Write a marker the BEAM reads
                // on next launch; the BEAM owns the timezone rules (Shamsi/Jalali
                // display, Gregorian/UTC storage) so it must recompute, not Kotlin.
                java.io.File(context.filesDir, "kati_needs_alarm_rebuild").writeText(
                    System.currentTimeMillis().toString())
                io.mob.notify.MobNotifySchedules.rearmAll(context)
            }
        }
    }
}
```

Two notes on why this passes Mob's build:

- `MobNotifySchedules` is `internal`-free (a plain `object` in `io.mob.notify`,
  `MobNotifyBridge.kt:115`) and both files land in the same Gradle sourceSet, so the
  cross-package call compiles. It is not a documented API — **pin `mob_notify` to
  `~> 0.1.2` and re-check on every upgrade.**
- `MobPluginBootstrap.registerAll(activity)` will call `MobPeriodicBridge.register()` and
  `setActivity(...)` automatically (`native_build.ex:5148-5155`).

### 5.4 Elixir side

```elixir
defmodule MobPeriodic do
  @spec enqueue(keyword()) :: :ok
  def enqueue(opts \\ []) do
    json = Jason.encode!(%{
      interval_minutes: Keyword.get(opts, :interval_minutes, 360),
      flex_minutes:     Keyword.get(opts, :flex_minutes, 120)
    })
    :mob_periodic_nif.periodic_enqueue(json)
  end

  def cancel, do: :mob_periodic_nif.periodic_cancel()
end
```

Kati's own module owns the file protocol:

```elixir
defmodule Kati.Background.Handoff do
  @dir System.get_env("MOB_DATA_DIR") || "priv/repo"

  def write_watchlist!(shows), do: atomic_write!("kati_watchlist.json", shows)

  def drain_inbox! do
    path = Path.join(dir(), "kati_episode_inbox.json")
    case File.read(path) do
      {:ok, raw} ->
        items = raw |> Jason.decode!() |> Map.fetch!("items")
        # Ash bulk upsert, idempotent on {show_id, season, episode}
        File.rm(path)
        items
      {:error, :enoent} -> []
    end
  end

  defp dir, do: System.get_env("MOB_DATA_DIR") || "priv/repo"
  # tmp + File.rename/2 = atomic on the same filesystem
  defp atomic_write!(name, term) do
    tmp = Path.join(dir(), name <> ".tmp")
    File.write!(tmp, Jason.encode!(term))
    File.rename!(tmp, Path.join(dir(), name))
  end
end
```

Call `drain_inbox!/0` from `Mob.App.on_start/0` and from
`handle_info({:mob_device, :did_become_active}, ...)`; call `write_watchlist!/1` on every
follow/unfollow and on `:did_enter_background` (`mob-0.7.20 ::
lib/mob/plugins/lifecycle.ex:26-36` shows the `Mob.Device.subscribe(:app)` /
`{:mob_device, :did_enter_background}` contract).

---

## 6. iOS (Q5) — state it plainly

### 6.1 What Apple provides

- **`BGAppRefreshTask`** — *"An object representing a short task typically used to refresh
  content that's run while the app is in the background. Use app refresh tasks for
  updating your app with small bits of information, such as the latest stock values.
  Executing app refresh tasks requires setting the `fetch` capability."*
  (<https://developer.apple.com/documentation/backgroundtasks/bgapprefreshtask>)
- **`BGProcessingTask`** — *"Although processing tasks can run for minutes, the system can
  interrupt the process… **Processing tasks run only when the device is idle. The system
  terminates any background processing tasks running when the user starts using the
  device.**"* (<https://developer.apple.com/documentation/backgroundtasks/bgprocessingtask>)
- **Queue depth** — *"There can be a total of **1 refresh task and 10 processing tasks**
  scheduled at any time. Trying to schedule more tasks returns [an error]."*
  (<https://developer.apple.com/documentation/backgroundtasks/bgtaskscheduler/submit(_:)>)
- `earliestBeginDate` is a **floor, not a schedule**. iOS decides actual timing from usage
  patterns, battery, and network. There is **no documented guarantee of frequency**.
- **Force-quit kills it.** If the user swipes the app away in the app switcher, iOS does
  not relaunch it for background refresh until the user opens it again. (This is
  long-standing DTS guidance; Apple's `BackgroundTasks` reference does not state it in so
  many words — flagged **UNVERIFIED-IN-DOCS**, universally reported in practice.)

### 6.2 What Mob would need added

Nothing exists. Verified: zero occurrences of `BGTaskScheduler`, `BGAppRefreshTask`,
`BGProcessingTask`, `performFetchWithCompletionHandler` across `mob-0.7.20/ios/`
(10 files: `mob_beam.m/h`, `mob_nif.m`, `MobViewModel.swift`, `MobRootView.swift`,
`MobGpuView.swift`, `MobNode.m/h`, `driver_tab_ios.zig`, bridging header) and across
`mob_new-0.4.20/priv/templates/mob.new/ios/` (5 files).

A `mob_bgtask` plugin would need, at minimum:

1. `ios.plist_keys` for `BGTaskSchedulerPermittedIdentifiers` — **blocked**: it is an
   *array*, and `mob_nfc`'s manifest documents that *"mob_dev's plugin plist merge only
   supports scalar (string/integer) values today (see MOB-38)"*
   (`mob_nfc-0.1.0 :: priv/mob_plugin.exs`). Would ship as a `host_requirement`.
2. `UIBackgroundModes` must gain `fetch` and/or `processing`. The template currently ships
   `[audio]` only (`Info.plist.eex:33-36`) — **and that `audio` entry should be removed
   from Kati regardless**, since Kati has no audio feature and Apple rejects apps declaring
   a background mode without the matching capability (`mob_background-0.1.0 ::
   lib/mob_background.ex:80-85`).
3. `BGTaskScheduler.register(forTaskWithIdentifier:)` must be called **in
   `application(_:didFinishLaunchingWithOptions:)` before it returns** — i.e. in
   `AppDelegate.m.eex:35-45`, which is a **host template edit**, not a plugin
   contribution.
4. The handler runs on a background launch where **the BEAM is not started** (the template
   starts it from the root view). Same headless problem as Android, plus iOS's much
   shorter budget (~30 s for refresh).

### 6.3 What is impossible without a server, on iOS

**Stated plainly, as requested:**

> On iOS, an app that has been backgrounded or force-quit **cannot be relied upon to
> discover, on its own, that a new episode aired.** `BGAppRefreshTask` is opportunistic
> with no frequency guarantee, is capped at one queued refresh task, is disabled entirely
> after a user force-quit, and is disabled by Low Power Mode and by the user's global
> "Background App Refresh" toggle. Silent push (`content-available: 1`) is the only
> mechanism that reliably wakes an iOS app on an external event — **and it requires a
> server to send it.**

Consequences for Kati on iOS:

- **Known air dates work perfectly.** `UNCalendarNotificationTrigger` local notifications
  fire with no network, no server, no BEAM — same as Android. This covers the majority of
  the value: TMDB publishes air dates in advance.
- **Discovery of *newly announced* episodes/seasons does not work in the background.** It
  works when the user opens the app.
- **Honest UX:** on iOS, do the check on foreground and on `BGAppRefreshTask` if it ever
  gets built, and never promise real-time. Do not ship a settings toggle that implies
  guaranteed background checking on iOS.
- The escape hatch, if the owner ever relents on "no server": a **stateless** push relay —
  a tiny service that knows only `(device_token, [tmdb_show_id])` and sends a silent push
  when TMDB's changes API reports a delta. That is the minimum server, and it is the only
  thing that closes the iOS gap.

---

## 7. The hybrid Kati should ship (Q6)

### 7.1 Three tiers

| Tier | What | Mechanism | Wakes BEAM |
|---|---|---|---|
| **A. Known air date** | "S05E14 airs tonight at 21:00" | `MobNotify.schedule/2` → `setExactAndAllowWhileIdle` | No |
| **B. Discovery poll** | "Season 6 was just announced" / "the air date moved" | `mob_periodic` WorkManager worker (Android); foreground-only (iOS) | No |
| **C. Reconciliation** | Ash rows updated, badges, UI | BEAM on next foreground: `drain_inbox!/0` + full refresh | Yes |

Tier A is the product. Tier B is the safety net that keeps Tier A's alarms correct.
Tier C is bookkeeping.

### 7.2 Alarm budget — Android

`AlarmManager` caps at **500 concurrent alarms per UID** on API 31+
(`IllegalStateException: "Maximum limit of concurrent alarms 500 reached for uid"` —
<https://github.com/invertase/notifee/issues/349>). Kati also uses alarms for habits,
calendar events, money reminders and health — so the TV budget is a slice, not the whole
500.

**Policy: arm at most the next 2 episodes per followed show, and at most 120 TV alarms
total.** Re-top-up on every foreground and every successful Worker run. A user following
40 shows needs 80 alarms; 120 is comfortable headroom.

### 7.3 Staying under iOS's 64 (for later)

The limit is real and old. The current `UserNotifications` docs **do not restate it** —
I checked `UNUserNotificationCenter`, `add(_:withCompletionHandler:)`,
`getPendingNotificationRequests`, `UNNotificationRequest` and `UNCalendarNotificationTrigger`
JSON payloads; none mention 64. The authoritative statement survives in the deprecated
`UILocalNotification` reference
(<https://developer.apple.com/documentation/uikit/uilocalnotification>):

> "An app can have only a limited number of scheduled notifications; **the system keeps the
> soonest-firing 64 notifications** (with automatically rescheduled notifications counting
> as a single notification) **and discards the rest**."

Note the failure mode: **silent truncation**, not an error. Design:

1. **Never schedule more than ~50**, leaving ~14 for the rest of Kati (habits, calendar,
   money) — and **budget across all six domains centrally**, in one Elixir module, not
   per-feature.
2. Maintain a `Kati.Notifications.Scheduler` GenServer that owns the *entire* pending set:
   on every foreground, `getPendingNotificationRequests` → reconcile → cancel stale →
   schedule the soonest N by absolute time, N = 50.
3. Prefer **one digest notification per day** ("3 new episodes tonight") over one per
   episode. This is better UX *and* collapses 3 slots into 1.
4. Use **repeating** `UNCalendarNotificationTrigger` for genuinely recurring things
   (habits, weekly shows at a fixed slot) — Apple counts an auto-rescheduled notification
   as **one**.
5. Add a debug screen showing `pending_count / 64`. You will regret not having it.

Android's equivalent budget is the 500-alarm cap plus a soft ~50-notifications-per-package
tray limit; the same central scheduler covers both.

### 7.4 Re-arming after reboot — the concrete fix

Three independent gaps, all fixable in the plugin from §5:

1. **`MobNotifyBootReceiver` is not declared** (§1.3). Without it *every* Kati alarm — TV,
   habits, calendar — is lost on reboot. `MobNotifySchedules.rearmAll(ctx)` already does
   the right thing (`MobNotifyBridge.kt:190-203`: re-arms every entry with
   `trigger_at_ms > now`, drops past-due ones). **Ship the `<receiver>` snippet.**
2. **WorkManager re-enqueues itself.** Its own `RescheduleReceiver` handles
   `BOOT_COMPLETED` from the library's manifest — no host work needed. But **also** handle
   `ACTION_MY_PACKAGE_REPLACED`, because an app update can leave the unique work in a bad
   state, and `enqueueUniquePeriodicWork(..., KEEP, ...)` is a cheap no-op if it's fine.
3. **Belt and braces: re-arm on every foreground.** `Mob.Device.subscribe(:app)` →
   `{:mob_device, :did_become_active}` → recompute the next-N alarms and re-schedule them.
   `MobNotify.schedule/2` is an upsert (`persist/6` filters the old id out first,
   `MobNotifyBridge.kt:227-237`) and `FLAG_UPDATE_CURRENT` makes the alarm side idempotent
   too, so re-arming the same ids is free.

**Do not rely on the boot receiver alone.** A user who force-stopped the app gets no
`BOOT_COMPLETED`; only a manual launch recovers them, and (3) is what recovers them.

### 7.5 Cadence

| Trigger | Action |
|---|---|
| App foreground | `drain_inbox!/0`, full TMDB refresh for shows with stale `checked_at`, re-arm top-120 alarms, rewrite watchlist |
| WorkManager, every ~6 h (flex 2 h) | Kotlin diff + notify + append inbox. **Never** more than every 6 h — 15 min is available and would be abusive |
| App background | Rewrite `kati_watchlist.json` |
| `BOOT_COMPLETED` / `MY_PACKAGE_REPLACED` | Re-enqueue work, `rearmAll` |
| `TIME_SET` / `TIMEZONE_CHANGED` | `rearmAll` + drop `kati_needs_alarm_rebuild` marker |
| Notification tapped | Existing Mob path: `MainActivity.onNewIntent` → `{:notification, notif}` |

---

## 8. Battery, correctness and UX edge cases (Q7)

### 8.1 Time

- **Timezone change / DST.** Alarms are armed as absolute epoch ms
  (`RTC_WAKEUP`, `MobNotifyBridge.kt:152`), so a flight from Tehran to London does **not**
  shift them — an alarm set for "20:00 Tehran" fires at "16:30 London". Whether that is
  right depends on the alarm. **Rule for Kati: air-date alarms are absolute (they should
  fire at the show's air time converted to the user's *current* zone → so they DO need
  rebuilding); habit/routine alarms are wall-clock-local (also need rebuilding).**
  Both cases need rebuild → hence the `TIMEZONE_CHANGED` receiver.
- **Do not store local times.** Locked decision already: Gregorian/UTC storage, Shamsi
  only for display. Extend it: store the show's air datetime as UTC plus its
  origin-country IANA zone; render in the user's current zone. Persian users especially —
  Iran abolished DST in 2022, so an `Asia/Tehran` user is at a fixed +03:30, but a user
  travelling to a DST zone is not.
- **DST gaps.** A wall-clock alarm at 02:30 on a spring-forward night does not exist.
  Elixir's `DateTime.new/4` returns `{:gap, before, after}` — handle it explicitly, pick
  `after`. `{:ambiguous, first, second}` on fall-back — pick `first`.
- **Manual clock change.** `ACTION_TIME_CHANGED` covers user-set clock; handled above.
- **Device off at air time.** `RTC_WAKEUP` alarms **do not** fire while powered off, and
  are wiped by the reboot. `rearmAll` explicitly drops past-due entries
  (`MobNotifyBridge.kt:199-201`). So a missed alarm is *silently lost*. **Fix:** on every
  foreground, compare Ash rows against `now` and show an in-app "you missed 2" banner
  rather than a stale notification.

### 8.2 Permissions

- **`POST_NOTIFICATIONS` denied.** `MobNotify.schedule/2` still arms the alarm and the
  receiver still calls `nm.notify(...)` — it just doesn't display. **No error is
  reported.** Check `NotificationManagerCompat.from(ctx).areNotificationsEnabled()` and
  surface it in-app. Kati must degrade to an in-app badge/inbox.
- **`SCHEDULE_EXACT_ALARM` denied.** Mob already falls back to
  `setAndAllowWhileIdle` (`MobNotifyBridge.kt:157-158`) — inexact, batched, potentially
  minutes-to-an-hour late. Acceptable for "new episode", not for "your show starts now".
  Detect via `AlarmManager.canScheduleExactAlarms()` and offer the settings deep-link.
- **`USE_EXACT_ALARM` is not for Kati.** Google Play restricts it to apps "where exact
  timing is core functionality: alarm applications, calendar apps with event
  notifications" (<https://support.google.com/googleplay/android-developer/answer/13161072>).
  Kati *does* have a calendar as a first-class feature, so a case could be made — but it
  is reviewed per-app and a denial blocks the release. **Ship with `SCHEDULE_EXACT_ALARM`
  (already in the template, `AndroidManifest.xml.eex:35-36`) and don't gamble.**
- **Permission revoked later.** Android sends
  `ACTION_SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED` on *grant*; on revoke, *"Your app
  stops. All future exact alarms are canceled."*
  (<https://developer.android.com/develop/background-work/services/alarms/schedule>).
  So a revoke is indistinguishable from a force-stop — recovery is the next manual launch.

### 8.3 Network

- **Aeroplane mode / offline.** `Constraints.setRequiredNetworkType(NetworkType.CONNECTED)`
  means WorkManager simply won't run the Worker — no wasted wakeup. Catch `IOException` →
  `Result.retry()` for the transient case.
- **Captive portal.** Mob already surfaces this: `MainActivity.kt.eex:96-98` reads
  `NET_CAPABILITY_VALIDATED` — *"Android actively probes for real internet reachability —
  false on a captive portal"*. `NetworkType.CONNECTED` does **not** imply validated. Treat
  a non-2xx/timeout as retry, not failure.
- **Metered data.** Do **not** use `NetworkType.UNMETERED` — a user on cellular-only would
  never get checks. Use `CONNECTED` and keep payloads tiny (see below).

### 8.4 Rate limits

- **TMDB.** The documented 40-req/10-s limit was **disabled 2019-12-16**; current limits
  "sit somewhere in the 40 requests per second range", subject to change, `429` on breach
  (<https://developer.themoviedb.org/docs/rate-limiting>). Effectively unlimited for Kati.
  **Use `GET /3/tv/changes` (the changes endpoint) rather than N per-show requests** — one
  call returns every show ID changed in a 24 h window; intersect with the local watchlist.
  40 followed shows → **1 request**, not 40. This is the single biggest efficiency win and
  it's what the endpoint exists for.
- **Trakt.** 1000 GET / 5 min, 1 POST-PUT-DELETE / second, per user; `429` + `Retry-After`
  (<https://forums.trakt.tv/t/has-the-trakt-api-rate-limit-changed/40054>). Note Trakt's
  official docs at `trakt.docs.apiary.io` returned **502** at time of writing — these
  numbers come from Trakt staff on their own forum, not the reference. **Flag as
  secondary-source.**
- Always honour `Retry-After`; always send `If-None-Match` / `ETag` and treat `304` as
  success-with-no-change (cheapest possible poll).
- **API keys in the APK.** Kati is open-source on GitHub. A TMDB key committed to the repo
  will be scraped. Options: (a) ask each user to paste their own free TMDB key in Settings
  — most honest for an open-source personal app, and the owner's "device-first" ethos fits;
  (b) ship a key and accept it will be abused. **Recommend (a)**, with a first-run wizard.

### 8.5 Battery

Realistic budget for tier B, 6 h cadence, Kotlin worker:

- 4 wakeups/day × (radio wake ~5 s + ~50 ms CPU + ~20 KB transfer).
- WorkManager's flex window lets the OS coalesce these with other apps' jobs, so the radio
  is usually already up — the marginal cost approaches zero.
- Compare against the alternative: `mob_background`'s foreground service holding a live
  BEAM measured **54–143 mAh/hr** on real hardware (`why_beam.md:137-143`). Over 24 h
  that is **1.3–3.4 Ah** — more than most phone batteries. The Kotlin worker is roughly
  **four orders of magnitude cheaper**.
- **Do not use `PeriodicWorkRequest`'s 15-minute floor.** 96 wakeups/day for content that
  changes daily is indefensible and will get Kati flagged in Android Vitals' "excessive
  background wakeups" metric.
- **Do not use `setExpedited`** for this. Expedited quota is 30 min/24 h even in the Active
  bucket; burn it on nothing and you lose it for something that matters.

### 8.6 App never opened for weeks

The realistic decay curve:

| Days idle | Bucket | What still works |
|---|---|---|
| 0–2 | Active / Working set | Everything |
| 3–7 | Frequent | Jobs 10 min / 12 h; alarms 2/hr. Fine |
| 8–30 | Rare | **Network disabled for jobs.** Alarms 1/hr — pre-armed air-date alarms **still fire** |
| 30+ / user marks "Restricted" | Restricted | 1 alarm/day, network disabled, jobs once/day batched |

**This is why tier A matters more than tier B.** Pre-armed absolute alarms for known air
dates survive the Rare bucket; the discovery poll does not. Arm alarms **as far ahead as
TMDB gives you air dates**, within the 120-alarm budget — do not lazily arm "just the next
one", because the poll that would arm the next one may never run.

### 8.7 Correctness of the diff itself

- Key episodes on `(tmdb_show_id, season_number, episode_number)`, never on episode name
  or air date — TMDB revises both.
- **Air dates move.** The Worker must detect a *changed* `air_date` for an
  already-known episode and re-arm/cancel the corresponding alarm. Add
  `{"kind":"reschedule", ...}` to the inbox and let the BEAM decide, but also let the
  Worker cancel the stale alarm directly via `MobNotifySchedules.cancel(ctx, id)` —
  stable notification ids (`"ep:<show>:<s>:<e>"`) make this trivial.
- **Idempotency.** `guides/background_execution.md`: *"Make notification handlers
  idempotent, because a user may tap an old notification after the app has already
  synced."* The Ash upsert on the composite key gives this for free.
- **WorkManager retries.** A `Result.retry()` after the notification was already posted
  would double-notify. **Post notifications last, and record posted ids in a
  SharedPreferences set the Worker checks first.** (SharedPreferences is fine here — only
  Kotlin reads it.)

---

## 9. Open questions and explicit UNKNOWNs

1. **BEAM cold-start time on device is unmeasured.** The "~0.5 s" figure in prior research
   is **not** in `mob-0.7.20` `README.md` or `guides/why_beam.md`. Measure it before
   relying on any number: `adb logcat | grep MobBeam` gives `mob_start_beam` phase logs.
2. **`mob_dev` 0.6.23 vs `mob` 0.7.20 version skew.** `mob_dev` has not had a 0.7.x
   release. Whether `manifest_application_snippets` works end-to-end against a 0.7.20 host
   is **untested by me** — build a throwaway `mix mob.new` app and verify the splice
   before committing to the plugin design.
3. **`MobNotifySchedules` cross-package access** from `io.mob.periodic` compiles in
   principle but is not a supported API. Verify with an actual Gradle build.
4. **Whether the hwui/SIGABRT race exists in a windowless process** — irrelevant if you
   never boot a headless BEAM, which is the recommendation.
5. **Real OEM survival rates in 2026** for `setExactAndAllowWhileIdle` and WorkManager on
   MIUI/HyperOS, EMUI/HarmonyOS and One UI. `dontkillmyapp.com` publishes configuration
   guidance, not measurements. Kati should ship its own telemetry-free self-check: record
   `expected_fire_at` vs `actual_fire_at` locally and show the user a diagnostic.
6. **`mob_background` 0.1.0 is not Android-15-safe** (no `foregroundServiceType` passed to
   `startForeground`, no `onTimeout`). Not Kati's problem if you never depend on it —
   worth an upstream issue.
7. **iOS `BGTaskScheduler` plugin** — parked. Blocked on mob_dev's array-plist-key gap
   (MOB-38) and on the AppDelegate template edit. Revisit only if the owner accepts a
   minimal push relay.

---

## 10. Concrete next actions

1. **Immediately, in Kati's own host app:** add the `MobNotifyBootReceiver` `<receiver>` to
   `android/app/src/main/AndroidManifest.xml`. One-line fix for a total loss of all
   scheduled notifications on reboot.
2. **Remove `UIBackgroundModes: [audio]`** from `ios/Info.plist` before the first
   TestFlight build — Apple rejects it without an audio feature.
3. **Do not add `mob_background`.**
4. Build `mob_periodic` as sketched in §5; verify the manifest-snippet splice on a
   throwaway app first.
5. Write `Kati.Notifications.Scheduler` as a **single central budget owner** across all six
   Kati domains, capped at 50 pending (iOS) / 120 TV alarms (Android). Do this before
   building any individual reminder feature, not after.
6. Use **`GET /3/tv/changes`**, not per-show polling.
7. Ship a **"Why am I not getting notifications?"** diagnostic screen: notification
   permission state, `canScheduleExactAlarms()`, battery-optimisation state, last
   successful Worker run, pending-notification count, and OEM-specific instructions.
