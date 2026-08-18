// KATI-BEGIN(K-26 calendar-reader) mob_new=0.4.20
// KATI-VENDORED: Kati's own file, fenced and ledgered because it works around
// the absence of any calendar API in Mob.
//
// Reads the device's calendars through CalendarContract and writes them as JSON
// into filesDir, which Elixir ingests on the next foreground. This is S-12's
// architecture — fetch in Kotlin, write JSON, ingest later — and it is used here
// for a specific reason: there is no Elixir->Kotlin call path without adding a
// NIF, since Mob's NIF table lives in the mob package and is not app-owned.
//
// A pull model would need that call path. A publish model does not, and it also
// matches how the data behaves: the provider is kept fresh by the OS sync
// adapters whether or not Kati is running, so reading on foreground is exactly
// when the data is newest and exactly when the user can see it.
//
// Queries Instances, not Events: the provider expands recurrence for us
// (RFC 5545 included), which is a large amount of work not to have to redo.
package com.example.kati

import android.content.Context
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import android.provider.CalendarContract
import android.util.Log
import androidx.core.content.ContextCompat
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

object KatiCalendarReader {
    private const val TAG = "KatiCal"
    private const val CALENDARS_FILE = "device_calendars.json"
    private const val INSTANCES_FILE = "device_instances.json"

    /** Days either side of now to import. Matches the design's visible horizon. */
    private const val WINDOW_PAST_DAYS = 90L
    private const val WINDOW_FUTURE_DAYS = 365L

    @JvmStatic
    fun hasPermission(context: Context): Boolean =
        ContextCompat.checkSelfPermission(context, android.Manifest.permission.READ_CALENDAR) ==
            PackageManager.PERMISSION_GRANTED

    /**
     * Publishes calendars and instances into filesDir.
     *
     * Never throws: a calendar read failing must not stop the app starting, and
     * Elixir treats a missing file as "no device calendars".
     */
    @JvmStatic
    fun publish(context: Context) {
        if (!hasPermission(context)) {
            Log.i(TAG, "READ_CALENDAR not granted — skipping")
            writeIfChanged(context, CALENDARS_FILE, JSONArray().toString())
            writeIfChanged(context, INSTANCES_FILE, JSONArray().toString())
            return
        }

        try {
            val calendars = readCalendars(context)
            val instances = readInstances(context)
            writeIfChanged(context, CALENDARS_FILE, calendars.toString())
            writeIfChanged(context, INSTANCES_FILE, instances.toString())
            Log.i(TAG, "published ${calendars.length()} calendars, ${instances.length()} instances")
        } catch (e: Exception) {
            // OEM providers diverge (Samsung and Xiaomi especially) and a
            // missing column throws rather than returning null.
            Log.w(TAG, "calendar read failed: ${e.message}")
        }
    }

    private fun readCalendars(context: Context): JSONArray {
        val out = JSONArray()
        val projection = arrayOf(
            CalendarContract.Calendars._ID,
            CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,
            CalendarContract.Calendars.ACCOUNT_NAME,
            CalendarContract.Calendars.ACCOUNT_TYPE,
            CalendarContract.Calendars.CALENDAR_COLOR,
            CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL,
            CalendarContract.Calendars.VISIBLE,
            CalendarContract.Calendars.CALENDAR_TIME_ZONE
        )

        context.contentResolver.query(
            CalendarContract.Calendars.CONTENT_URI, projection, null, null, null
        )?.use { c ->
            while (c.moveToNext()) {
                out.put(
                    JSONObject()
                        .put("id", str(c, 0))
                        .put("display_name", str(c, 1))
                        .put("account_name", str(c, 2))
                        .put("account_type", str(c, 3))
                        .put("color", str(c, 4))
                        // OWNER(700) and higher may write; anything less is read-only.
                        .put("read_only", (num(c, 5) ?: 0L) < 700L)
                        .put("visible", (num(c, 6) ?: 0L) == 1L)
                        .put("timezone", str(c, 7))
                )
            }
        }
        return out
    }

    private fun readInstances(context: Context): JSONArray {
        val out = JSONArray()
        val now = System.currentTimeMillis()
        val from = now - WINDOW_PAST_DAYS * 86_400_000L
        val to = now + WINDOW_FUTURE_DAYS * 86_400_000L

        val uri: Uri = CalendarContract.Instances.CONTENT_URI.buildUpon()
            .appendPath(from.toString())
            .appendPath(to.toString())
            .build()

        val projection = arrayOf(
            CalendarContract.Instances.EVENT_ID,
            CalendarContract.Instances.CALENDAR_ID,
            CalendarContract.Instances.TITLE,
            CalendarContract.Instances.BEGIN,
            CalendarContract.Instances.END,
            CalendarContract.Instances.ALL_DAY,
            CalendarContract.Instances.EVENT_LOCATION,
            CalendarContract.Instances.DESCRIPTION,
            CalendarContract.Instances.EVENT_TIMEZONE,
            CalendarContract.Instances.RRULE,
            CalendarContract.Instances.STATUS,
            // _SYNC_ID and ORIGINAL_ID are declared on Events, not Instances —
            // Instances inherits the columns but not the constants, so the
            // Events class must be named here or Kotlin cannot resolve them.
            //
            // UID_2445 is documented but an open Google issue reports it always
            // null on some devices, so _SYNC_ID is read too and Elixir stores
            // both rather than trusting either alone (#52's objection 2).
            CalendarContract.Events._SYNC_ID,
            CalendarContract.Events.ORIGINAL_ID
        )

        context.contentResolver.query(
            uri, projection, null, null, CalendarContract.Instances.BEGIN + " ASC"
        )?.use { c ->
            while (c.moveToNext()) {
                out.put(
                    JSONObject()
                        .put("event_id", str(c, 0))
                        .put("calendar_id", str(c, 1))
                        .put("title", str(c, 2))
                        .put("begin_ms", num(c, 3))
                        .put("end_ms", num(c, 4))
                        .put("all_day", (num(c, 5) ?: 0L) == 1L)
                        .put("location", str(c, 6))
                        .put("description", str(c, 7))
                        .put("timezone", str(c, 8))
                        .put("rrule", str(c, 9))
                        .put("status", num(c, 10))
                        .put("sync_id", str(c, 11))
                        .put("original_id", str(c, 12))
                )
            }
        }
        return out
    }

    // Defensive: OEM providers omit columns, and getString on a missing one
    // throws rather than returning null.
    private fun str(c: Cursor, i: Int): String? =
        try { if (c.isNull(i)) null else c.getString(i) } catch (e: Exception) { null }

    private fun num(c: Cursor, i: Int): Long? =
        try { if (c.isNull(i)) null else c.getLong(i) } catch (e: Exception) { null }

    // Avoids rewriting an unchanged file on every foreground, which would churn
    // flash for nothing on a device that has not touched its calendar.
    private fun writeIfChanged(context: Context, name: String, body: String) {
        val f = File(context.filesDir, name)
        if (f.exists() && f.readText() == body) return
        f.writeText(body)
    }
}
// KATI-END(K-26 calendar-reader)
