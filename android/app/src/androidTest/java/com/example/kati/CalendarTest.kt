package com.example.kati

import android.content.ContentUris
import android.content.ContentValues
import android.provider.CalendarContract
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.rule.GrantPermissionRule
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import java.util.TimeZone

/**
 * #82 — the calendar you already have, on screen.
 *
 * Every part of this pipe was built and switched off for want of one
 * `Mob.Permissions.request/2` call: the manifest declares `READ_CALENDAR`,
 * `MobBridge` maps the capability both ways, `KatiCalendarReader.publish/1`
 * writes the JSON and `Kati.Calendars.DeviceImport.run/0` ingests it at boot.
 * Nothing asked, so the reader published nothing and every calendar surface
 * drew a sample.
 *
 * The event this plants is written to `CalendarContract` — the real OS
 * provider, the same one any other app writes to — with a title generated per
 * run. A fixture could not prove what this proves: that Kati read the device.
 */
@RunWith(AndroidJUnit4::class)
class CalendarTest {

    /**
     * WRITE_CALENDAR, for the test's own hand — not the app's.
     *
     * Declaring a dangerous permission in the e2e manifest does not grant it;
     * planting an event fails with a `SecurityException` from
     * `CalendarProvider2` without this. Deliberately NOT `READ_CALENDAR`: that
     * is the permission the app has to ask for, and pre-granting it would skip
     * the dialog these tests exist to drive.
     */
    @get:Rule(order = 0)
    val grant: GrantPermissionRule =
        GrantPermissionRule.grant(android.Manifest.permission.WRITE_CALENDAR)

    @get:Rule(order = 1)
    val kati = KatiRule()

    private val instrumentation get() = InstrumentationRegistry.getInstrumentation()

    /** Unique per run, so a stale row from a previous run cannot pass this. */
    private val title = "kati-e2e-${System.currentTimeMillis()}"

    @Test
    fun a_the_device_calendar_reaches_the_store() {
        assertTrue(
            "less than 200MB free on /data — a failed install would present as a failed test",
            kati.freeMegabytes() > 200
        )

        kati.revoke(android.Manifest.permission.READ_CALENDAR)

        val eventId = plantEvent()
        assertNotNull("could not write to CalendarContract", eventId)

        kati.launch()
        kati.compose.waitUntil(60_000) { kati.present("choose_en") }

        // Walk the first run to the step that asks. The ask is deliberately not
        // at launch: a permission dialog before the app has explained itself is
        // the one people refuse.
        kati.tap("continue")
        kati.compose.waitUntil(20_000) { !kati.present("choose_en") }

        // Nothing has been granted yet, so nothing can have been ingested. This
        // is what makes the assertion below mean something: without it, a row
        // that had been in the store all along would pass.
        assertEquals(
            "events existed before the calendar was ever granted",
            0L,
            kati.count("events")
        )

        kati.tap("continue")
        kati.systemDialog("Allow", "While using the app", "Allow all the time")

        // No relaunch between the grant and the assertion. `publish/1` runs in
        // `onCreate` and writes an EMPTY array without the permission, so the
        // files on disk are the empty ones written seconds ago; only
        // `K-37 republish-on-grant` and the Elixir re-ingest beside it make
        // this pass without a cold start.
        //
        // The receipt is the store, never the screen: a calendar screen
        // redrawing its sample is indistinguishable from one redrawing a row.
        kati.compose.waitUntil(30_000) { kati.count("events") > 0 }

        assertTrue(
            "kati.db holds no events after the calendar was granted — the reader " +
                "published nothing, or DeviceImport did not ingest it",
            kati.count("events") > 0
        )

        assertEquals(
            "the event in the store is not the one this test planted in CalendarContract",
            title,
            kati.scalar("select summary from events where summary = '$title'")
        )
    }

    // ── Planting a real event ──────────────────────────────────────────────

    private fun plantEvent(): Long? {
        val resolver = instrumentation.targetContext.contentResolver
        val calendarId = ensureCalendar() ?: return null
        val start = System.currentTimeMillis() + 3_600_000

        val values = ContentValues().apply {
            put(CalendarContract.Events.CALENDAR_ID, calendarId)
            put(CalendarContract.Events.TITLE, title)
            put(CalendarContract.Events.DTSTART, start)
            put(CalendarContract.Events.DTEND, start + 1_800_000)
            put(CalendarContract.Events.EVENT_TIMEZONE, TimeZone.getDefault().id)
        }

        val uri = resolver.insert(CalendarContract.Events.CONTENT_URI, values) ?: return null
        return ContentUris.parseId(uri)
    }

    /**
     * A local calendar to hang the event on, created without ever reading.
     *
     * The obvious version queries for an existing calendar first and fails:
     * reading `content://com.android.calendar/calendars` needs READ_CALENDAR,
     * which this test deliberately does not hold — that is the permission the
     * app must ask for, and pre-granting it would skip the dialog.
     *
     * Inserting as a sync adapter needs only WRITE_CALENDAR. A duplicate local
     * calendar across runs is harmless; the event title is what identifies the
     * row, and it is unique per run.
     */
    private fun ensureCalendar(): Long? {
        val resolver = instrumentation.targetContext.contentResolver
        val name = "kati-e2e"

        val uri = CalendarContract.Calendars.CONTENT_URI.buildUpon()
            .appendQueryParameter(CalendarContract.CALLER_IS_SYNCADAPTER, "true")
            .appendQueryParameter(CalendarContract.Calendars.ACCOUNT_NAME, name)
            .appendQueryParameter(
                CalendarContract.Calendars.ACCOUNT_TYPE,
                CalendarContract.ACCOUNT_TYPE_LOCAL
            )
            .build()

        val values = ContentValues().apply {
            put(CalendarContract.Calendars.ACCOUNT_NAME, name)
            put(CalendarContract.Calendars.ACCOUNT_TYPE, CalendarContract.ACCOUNT_TYPE_LOCAL)
            put(CalendarContract.Calendars.NAME, name)
            put(CalendarContract.Calendars.CALENDAR_DISPLAY_NAME, name)
            put(CalendarContract.Calendars.CALENDAR_COLOR, 0x4E9A73)
            put(
                CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL,
                CalendarContract.Calendars.CAL_ACCESS_OWNER
            )
            put(CalendarContract.Calendars.OWNER_ACCOUNT, name)
            put(CalendarContract.Calendars.SYNC_EVENTS, 1)
            put(CalendarContract.Calendars.VISIBLE, 1)
        }

        return resolver.insert(uri, values)?.let { ContentUris.parseId(it) }
    }
}
