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

        // No revoke, and there cannot be one. Android restarts the app process
        // on ANY runtime permission revoke — `pm revoke` through a shell
        // command and `UiAutomation.revokeRuntimePermission/2` alike, because
        // it is the platform's behaviour and not the command's. Instrumentation
        // runs inside that process, so either one reports "Test instrumentation
        // process crashed" with a logcat that ends at `run started`. Both were
        // tried here; both died the same way.
        //
        // Which changes what this test can claim. Its subject used to be
        // `K-37 republish-on-grant` — that a GRANT re-ingests without a cold
        // start — and that needs the permission ungranted, which it no longer
        // is by the time this class runs: every other class walks the first run
        // and answers the calendar dialog with Allow, and a grant persists for
        // the package. Asserting it would need this to be the first test in the
        // run, which is a fact about alphabetical ordering rather than
        // something to rely on.
        //
        // So the claim is the one in the test's own name, and it is still worth
        // making: an event written to CalendarContract reaches `kati.db`. The
        // event is planted AFTER the app has already booted and ingested, so it
        // cannot have arrived with the boot — `Kati.Calendars.DeviceImport.run/0`
        // has to see it on the re-publish, which is the pipe this exercises end
        // to end.
        kati.launch()

        // Walk the first run to the step that asks. The ask is deliberately not
        // at launch: a permission dialog before the app has explained itself is
        // the one people refuse. Since `D-33` renumbered the run that is step
        // three rather than step two, which is why this goes through
        // `toSections` rather than pressing Continue twice — the second press
        // used to land on the sections step and now lands on the welcome, whose
        // primary is not called `continue` at all.
        kati.toSections()
        kati.tap("continue")
        kati.systemDialog("Allow", "While using the app", "Allow all the time")

        // Planted only NOW, after the app has booted and ingested whatever the
        // emulator's calendar already held. That ordering is the premise: the
        // row cannot have arrived with the boot, so if it turns up it turned up
        // through the pipe.
        val eventId = plantEvent()
        assertNotNull("could not write to CalendarContract", eventId)

        assertNull(
            "the planted event was in kati.db before Kati had a chance to read it, which " +
                "means this test proves nothing about the pipe",
            kati.scalar("select summary from events where summary = '$title'")
        )

        // Recreating the Activity re-runs `onCreate`, and `publish/1` runs
        // there — the same path `Kati.RecreateTest` exercises for the BEAM.
        // `KatiCalendarReader.publish/1` writes the JSON,
        // `Kati.Calendars.DeviceImport.run/0` ingests it, and this is the
        // whole of the device-calendar pipe end to end.
        //
        // The receipt is the store, never the screen: a calendar screen
        // redrawing its sample is indistinguishable from one redrawing a row.
        kati.launch()
        kati.compose.waitUntil(30_000) {
            kati.scalar("select summary from events where summary = '$title'") != null
        }

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
