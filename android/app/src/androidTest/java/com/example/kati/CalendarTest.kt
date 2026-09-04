package com.example.kati

import android.content.ContentUris
import android.content.ContentValues
import android.provider.CalendarContract
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.rule.GrantPermissionRule
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.After
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

        // No revoke here any more, and `KatiRule.revoke/1` is gone with it. Its
        // own comment described the trap and the code walked into it: `pm
        // revoke` on a HELD permission force-stops the package, instrumentation
        // runs in that package, and the run reports "Test instrumentation
        // process crashed" with nothing to read. It was a harmless no-op while
        // the permission was denied and fatal in exactly the case it existed
        // for — so it passed for weeks and then died the first time a walk
        // through the app by hand left READ_CALENDAR granted. Which is how it
        // died.
        //
        // The premise it was arranging is arranged below instead, and more
        // precisely: rather than "the events table is empty", the claim is
        // "the event this test just planted is not in the store yet". That is
        // true whatever else a previous run ingested, and it is the row the
        // assertions at the foot actually care about.
        val eventId = plantEvent()
        assertNotNull("could not write to CalendarContract", eventId)

        kati.launch()

        // Walk the first run to the step that asks. The ask is deliberately not
        // at launch: a permission dialog before the app has explained itself is
        // the one people refuse. Since `D-33` renumbered the run that is step
        // three rather than step two, which is why this goes through
        // `toSections` rather than pressing Continue twice — the second press
        // used to land on the sections step and now lands on the welcome, whose
        // primary is not called `continue` at all.
        kati.toSections()

        // The planted event is not in the store yet. This is what makes the
        // assertion below mean something: without it, a row ingested by an
        // earlier run would pass.
        assertNull(
            "the planted event was already in the store before the calendar was granted",
            kati.scalar("select summary from events where summary = '$title'")
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

    /**
     * Take the planted events back out of the DEVICE's calendar.
     *
     * This test writes to `CalendarContract` — the real provider every other
     * app on the phone shares — and without this it never took them out again.
     * They accumulated one per run: seventeen `kati-e2e-…` events were sitting
     * on the emulator's calendar when this was found, all of them imported
     * into Kati and drawn on the Schedule, which is why
     * `FirstRunTest.b_every_root_draws_its_own_emptiness` could not find an
     * empty day to assert against.
     *
     * A test that leaves rows in a shared store is not isolated; it is just
     * slow to fail. Deleting by the `kati-e2e-` prefix rather than by the id
     * this run planted, because the leak has a history and the earlier ones
     * have no id anybody still holds.
     */
    @After
    fun removePlantedEvents() {
        try {
            instrumentation.targetContext.contentResolver.delete(
                CalendarContract.Events.CONTENT_URI,
                "${CalendarContract.Events.TITLE} LIKE ?",
                arrayOf("kati-e2e-%")
            )
        } catch (_: Throwable) {
            // WRITE_CALENDAR can be absent when the run failed before the rule
            // granted it. A cleanup that throws would mask the real failure.
        }
    }

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
