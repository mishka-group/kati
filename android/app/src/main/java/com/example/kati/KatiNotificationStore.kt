package com.example.kati

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import org.json.JSONObject

/**
 * Durable store + scheduler for Kati's local notifications.
 *
 * ## Why this exists
 *
 * The generated bridge arms `AlarmManager` directly and keeps no record of
 * what it armed. `AlarmManager` drops every pending alarm when the device
 * reboots or the app is reinstalled, so without a persisted copy there is
 * nothing to restore — the user simply stops being told about the things
 * they asked to be told about, silently, and only after a reboot.
 *
 * The stock manifest already requests `RECEIVE_BOOT_COMPLETED` but declares
 * no receiver to use it, which is what made the gap easy to miss.
 *
 * ## Why scheduling lives here rather than in MobBridge
 *
 * `MobBridge.notify_schedule` reads `activityRef`, so it only works while an
 * Activity is alive. Re-arming happens in a `BroadcastReceiver` at boot,
 * where there is no Activity and never will be — only a `Context`. Keeping
 * one `Context`-based implementation means the alarm armed at boot is
 * identical to the one armed by a running screen, rather than a second code
 * path that drifts.
 */
object KatiNotificationStore {

    private const val PREFS = "kati_scheduled_notifications"
    private const val TAG = "KatiNotify"

    /**
     * Arms an OS alarm and records it, so it can be restored after a reboot.
     *
     * Exactness degrades rather than failing. `SCHEDULE_EXACT_ALARM` is not
     * granted by default on Android 13+, and `setExactAndAllowWhileIdle`
     * throws `SecurityException` without it — which the stock bridge swallows
     * into a log line, leaving the caller believing a notification is armed
     * when none is. An inexact alarm that fires a few minutes late is a far
     * better outcome for an episode reminder than one that never fires.
     */
    fun schedule(
        ctx: Context,
        id: String,
        title: String,
        body: String,
        data: String,
        triggerAtMs: Long
    ) {
        record(ctx, id, title, body, data, triggerAtMs)
        arm(ctx, id, title, body, data, triggerAtMs)
    }

    fun cancel(ctx: Context, id: String) {
        forget(ctx, id)
        val pi = pendingIntent(ctx, id, null, null, null, PendingIntent.FLAG_NO_CREATE)
        pi?.let { alarmManager(ctx).cancel(it) }
    }

    /**
     * Re-arms every stored alarm that is still in the future and forgets the
     * rest. Called from [KatiBootReceiver].
     *
     * Alarms whose time passed while the device was off are dropped, not
     * fired late: "this aired three days ago" is noise, and firing a burst of
     * stale notifications at boot is how users disable notifications entirely.
     */
    fun rearmAll(ctx: Context) {
        val now = System.currentTimeMillis()
        val prefs = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        var restored = 0
        var dropped = 0

        for ((id, raw) in prefs.all) {
            val json = runCatching { JSONObject(raw as String) }.getOrNull()
            if (json == null) {
                forget(ctx, id); dropped++; continue
            }
            val triggerAt = json.optLong("trigger_at", 0L)
            if (triggerAt <= now) {
                forget(ctx, id); dropped++; continue
            }
            arm(
                ctx, id,
                json.optString("title"),
                json.optString("body"),
                json.optString("data", "{}"),
                triggerAt
            )
            restored++
        }
        Log.i(TAG, "rearmAll: restored=$restored dropped=$dropped")
    }

    /** Removes a fired alarm's record. Called by the receiver after posting. */
    fun forget(ctx: Context, id: String) {
        ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().remove(id).apply()
    }

    fun pendingCount(ctx: Context): Int =
        ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).all.size

    // ── internals ──────────────────────────────────────────────────────────

    private fun record(
        ctx: Context, id: String, title: String, body: String,
        data: String, triggerAtMs: Long
    ) {
        val json = JSONObject()
            .put("id", id)
            .put("title", title)
            .put("body", body)
            .put("data", data)
            .put("trigger_at", triggerAtMs)
        ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putString(id, json.toString()).apply()
    }

    private fun arm(
        ctx: Context, id: String, title: String, body: String,
        data: String, triggerAtMs: Long
    ) {
        val pi = pendingIntent(
            ctx, id, title, body, data,
            PendingIntent.FLAG_UPDATE_CURRENT
        ) ?: return
        val am = alarmManager(ctx)

        val exact = Build.VERSION.SDK_INT < 31 || am.canScheduleExactAlarms()
        try {
            if (exact) {
                am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMs, pi)
            } else {
                am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMs, pi)
                Log.w(TAG, "no exact-alarm permission; armed inexact for id=$id")
            }
        } catch (e: SecurityException) {
            am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMs, pi)
            Log.w(TAG, "exact alarm refused for id=$id: ${e.message}")
        }
    }

    private fun pendingIntent(
        ctx: Context, id: String, title: String?, body: String?,
        data: String?, flags: Int
    ): PendingIntent? {
        val intent = Intent(ctx, NotificationReceiver::class.java).apply {
            putExtra("id", id)
            title?.let { putExtra("title", it) }
            body?.let { putExtra("body", it) }
            data?.let { putExtra("data", it) }
        }
        return PendingIntent.getBroadcast(
            ctx, id.hashCode(), intent, flags or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun alarmManager(ctx: Context): AlarmManager =
        ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
}
