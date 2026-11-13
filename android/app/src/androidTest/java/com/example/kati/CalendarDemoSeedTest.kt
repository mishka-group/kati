package com.example.kati

import android.content.ContentUris
import android.content.ContentValues
import android.provider.CalendarContract
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.rule.GrantPermissionRule
import java.util.Calendar
import java.util.TimeZone
import org.junit.Assert.assertNotNull
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Plants a month of demo events in the emulator's calendar provider.
 *
 * The events are meant to stay: this is the fixture behind a walk through
 * Day, Week, Month and Agenda, so every seat in those views has something on
 * it — overlapping timed events (a cluster), an all-day event, events on
 * neighbouring days, one in the past and a weekly repeat.
 *
 * Cleanup is by account, not by title: `kati-demo` is a single local
 * calendar, and removing it takes every event with it.
 */
@RunWith(AndroidJUnit4::class)
class CalendarDemoSeedTest {

    @get:Rule(order = 0)
    val grant: GrantPermissionRule =
        GrantPermissionRule.grant(android.Manifest.permission.WRITE_CALENDAR)

    private val context get() = InstrumentationRegistry.getInstrumentation().targetContext

    @Test
    fun seed_a_month_of_events() {
        val resolver = context.contentResolver
        val calendarId = ensureCalendar()
        assertNotNull("the demo calendar could not be created", calendarId)

        val midnight = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }

        fun at(dayOffset: Int, hour: Int, minute: Int = 0): Long {
            val c = midnight.clone() as Calendar
            c.add(Calendar.DAY_OF_YEAR, dayOffset)
            c.set(Calendar.HOUR_OF_DAY, hour)
            c.set(Calendar.MINUTE, minute)
            return c.timeInMillis
        }

        fun plant(title: String, start: Long, end: Long, rule: String? = null) {
            val values = ContentValues().apply {
                put(CalendarContract.Events.CALENDAR_ID, calendarId)
                put(CalendarContract.Events.TITLE, title)
                put(CalendarContract.Events.DTSTART, start)
                put(CalendarContract.Events.DTEND, end)
                put(CalendarContract.Events.EVENT_TIMEZONE, TimeZone.getDefault().id)
                if (rule != null) put(CalendarContract.Events.RRULE, rule)
            }
            resolver.insert(CalendarContract.Events.CONTENT_URI, values)
        }

        // Today: two overlapping events (a cluster), a long afternoon and an
        // all-day note.
        plant("Morning stand-up", at(0, 9), at(0, 10))
        plant("Overlapping review", at(0, 9, 30), at(0, 10, 30))
        plant("Lunch with Ada", at(0, 13), at(0, 14))
        plant("Studio session", at(0, 16), at(0, 18))

        // Around the week: one in the past, one tomorrow, one at the weekend.
        plant("Earlier planning", at(-2, 11), at(-2, 12))
        plant("Dentist", at(1, 10), at(1, 11))
        plant("Dinner reservation", at(2, 18, 30), at(2, 20))
        plant("Flight to Lisbon", at(4, 7), at(4, 12))
        plant("Bookshop", at(6, 15), at(6, 16))

        // A repeat, so the month has a pattern rather than single dots.
        plant(
            "Weekly planning",
            at(3, 8),
            at(3, 9),
            rule = "FREQ=WEEKLY;BYDAY=SA"
        )
    }

    private fun ensureCalendar(): Long? {
        val resolver = context.contentResolver

        // One demo calendar and no duplicates: delete it as the sync adapter
        // first, which takes its events with it.
        try {
            resolver.delete(
                asSyncAdapter(CalendarContract.Calendars.CONTENT_URI),
                "${CalendarContract.Calendars.ACCOUNT_NAME} = ? AND " +
                    "${CalendarContract.Calendars.ACCOUNT_TYPE} = ?",
                arrayOf(ACCOUNT, CalendarContract.ACCOUNT_TYPE_LOCAL)
            )
        } catch (_: Throwable) {
            // Nothing planted yet.
        }

        val values = ContentValues().apply {
            put(CalendarContract.Calendars.ACCOUNT_NAME, ACCOUNT)
            put(CalendarContract.Calendars.ACCOUNT_TYPE, CalendarContract.ACCOUNT_TYPE_LOCAL)
            put(CalendarContract.Calendars.NAME, ACCOUNT)
            put(CalendarContract.Calendars.CALENDAR_DISPLAY_NAME, ACCOUNT)
            put(CalendarContract.Calendars.CALENDAR_COLOR, 0xE8823C)
            put(
                CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL,
                CalendarContract.Calendars.CAL_ACCESS_OWNER
            )
            put(CalendarContract.Calendars.OWNER_ACCOUNT, ACCOUNT)
            put(CalendarContract.Calendars.SYNC_EVENTS, 1)
            put(CalendarContract.Calendars.VISIBLE, 1)
        }

        return resolver.insert(asSyncAdapter(CalendarContract.Calendars.CONTENT_URI), values)
            ?.let { ContentUris.parseId(it) }
    }

    private fun asSyncAdapter(base: android.net.Uri): android.net.Uri =
        base.buildUpon()
            .appendQueryParameter(CalendarContract.CALLER_IS_SYNCADAPTER, "true")
            .appendQueryParameter(CalendarContract.Calendars.ACCOUNT_NAME, ACCOUNT)
            .appendQueryParameter(
                CalendarContract.Calendars.ACCOUNT_TYPE,
                CalendarContract.ACCOUNT_TYPE_LOCAL
            )
            .build()

    private companion object {
        const val ACCOUNT = "kati-demo"
    }
}
