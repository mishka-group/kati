package com.example.kati

import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performTextReplacement
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * #124 — Schedule on a show (and a film): the watch is saved against the
 * title, it carries a reminder, the reminder is armed on the phone, and the
 * page then says when and opens the event to change it.
 *
 * Every claim ends in `kati.db`: the event row, its title and its reminder,
 * and the `notification_pending` row that is Kati's record of an alarm armed
 * with Android.
 */
@RunWith(AndroidJUnit4::class)
class ScheduleTest {

    @get:Rule
    val kati = KatiRule()

    private val stamp = System.currentTimeMillis()

    private fun idOf(title: String): String =
        kati.scalar("select id from tracked_titles where source_id = '$title'") ?: ""

    private fun eventColumn(trackedId: String, column: String): String? =
        kati.scalar(
            "select $column from events where tracked_title_id = '$trackedId' " +
                "and deleted_at is null order by inserted_at desc limit 1"
        )

    private var typed: String? = null

    private fun schedule(tag: String, screen: String) {
        kati.tap(tag)
        kati.awaitScreen("quick_add")
        // The page opens with "Watch <title> " already typed; a test's text
        // input lands at the cursor, which is not where a finger would put
        // it, so the sentence is completed as a whole.
        kati.compose.waitUntil(10_000) { (kati.textOf("quick_add_sentence") ?: "").startsWith("Watch") }
        val opened = kati.textOf("quick_add_sentence") ?: ""
        kati.compose.onNodeWithTag("quick_add_sentence", useUnmergedTree = true)
            .performTextReplacement(opened.trim() + " tomorrow 8pm")
        kati.device.waitForIdle()
        // The app hears the typing a character at a time; Save must not be
        // pressed before the time has arrived, or the watch is saved all-day.
        kati.compose.waitUntil(10_000) { kati.present("commit") }
        Thread.sleep(2_000)
        kati.device.waitForIdle()
        typed = kati.textOf("quick_add_sentence")
        kati.tap("commit")
        // A reminder asks for the notification permission the first time.
        kati.systemDialog("Allow")
        kati.awaitScreen(screen)
    }

    @Test
    fun a_a_show_schedules_a_watch_with_a_reminder_that_is_armed_and_managed() {
        val show = "Schedule Show $stamp"
        kati.launch()
        kati.firstRun()
        ByHand.add(kati, show, "kind_tv")
        kati.awaitScreen("series")
        val id = idOf(show)

        schedule("schedule_watch", "series")

        kati.compose.waitUntil(20_000) { eventColumn(id, "id") != null }
        assertEquals(
            "a scheduled watch reminds at its start — saved [" + eventColumn(id, "summary") +
                "] all-day " + eventColumn(id, "is_all_day") + " at " + eventColumn(id, "dtstart_utc") +
                " typed [" + typed + "]",
            "0",
            eventColumn(id, "alarm_minutes")
        )
        assertTrue(
            "the summary should name the show",
            (eventColumn(id, "summary") ?: "").contains(show)
        )

        // Armed with Android: Kati's own record of the alarm.
        kati.compose.waitUntil(20_000) {
            (kati.scalar("select count(*) from notification_pending where id like 'rem:%'") ?: "0") != "0"
        }

        // The page now says when, and that opens the event.
        kati.compose.waitUntil(20_000) { kati.present("open_schedule") }
        kati.tap("open_schedule")
        kati.awaitScreen("event_detail")

        kati.tap("cycle_reminder")
        kati.compose.waitUntil(20_000) { eventColumn(id, "alarm_minutes") == "10" }
        assertEquals("10", eventColumn(id, "alarm_minutes"))

        kati.tap("open_title")
        kati.awaitScreen("series")
    }

    @Test
    fun b_a_film_schedules_too_and_deleting_the_event_frees_the_pill() {
        val film = "Schedule Film $stamp"
        kati.launch()
        kati.firstRun()
        ByHand.add(kati, film, "kind_movie")
        kati.awaitScreen("film")
        val id = idOf(film)

        schedule("schedule_watch", "film")
        kati.compose.waitUntil(20_000) { eventColumn(id, "id") != null }

        kati.compose.waitUntil(20_000) { kati.present("open_schedule") }
        kati.tap("open_schedule")
        kati.awaitScreen("event_detail")
        kati.tap("delete_event")
        kati.awaitScreen("film")

        kati.compose.waitUntil(20_000) { kati.present("schedule_watch") }
        assertEquals(null, eventColumn(id, "id"))
    }

    @Test
    fun c_a_day_and_an_hour_picked_from_the_chips_schedule_without_typing() {
        val show = "Chips Show $stamp"
        kati.launch()
        kati.firstRun()
        ByHand.add(kati, show, "kind_tv")
        kati.awaitScreen("series")
        val id = idOf(show)

        kati.tap("schedule_watch")
        kati.awaitScreen("quick_add")
        kati.compose.waitUntil(10_000) { kati.present("when_days") }

        val tomorrow = java.time.LocalDate.now().plusDays(1)
        kati.tap("pick_day_$tomorrow")
        kati.compose.waitUntil(10_000) { kati.present("pick_time_2000") }
        kati.tap("pick_time_2000")
        kati.compose.waitUntil(10_000) { kati.present("commit") }
        Thread.sleep(1_000)
        kati.device.waitForIdle()
        kati.tap("commit")
        kati.systemDialog("Allow")
        kati.awaitScreen("series")

        kati.compose.waitUntil(20_000) { eventColumn(id, "id") != null }
        assertEquals(tomorrow.toString(), eventColumn(id, "dtstart_date"))
        assertEquals("0", eventColumn(id, "is_all_day"))
        assertEquals("0", eventColumn(id, "alarm_minutes"))
    }
}
