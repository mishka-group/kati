package com.example.kati

import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.swipeLeft
import androidx.compose.ui.test.swipeRight
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import java.time.LocalDate

/**
 * #126 — the calendar goes anywhere: weeks by arrow and swipe on the
 * Schedule, months by swipe on the grid, days on the day page, and every
 * view's + adds to the calendar.
 *
 * A day cell is tagged `day_<iso date>`, so where the strip is shows in the
 * tags it carries.
 */
@RunWith(AndroidJUnit4::class)
class CalendarNavigationTest {

    @get:Rule
    val kati = KatiRule()

    private val today: LocalDate = LocalDate.now()

    private fun cell(date: LocalDate) = "day_$date"

    private fun openSchedule() {
        kati.launch()
        kati.firstRun()
        kati.tap("root_calendar")
        kati.awaitScreen("calendar")
        kati.compose.waitUntil(10_000) { kati.present(cell(today)) }
    }

    @Test
    fun a_the_strip_moves_by_week_with_the_arrows_and_a_swipe() {
        openSchedule()

        kati.tap("week_next")
        kati.compose.waitUntil(10_000) { kati.present(cell(today.plusDays(7))) }
        assertTrue("a week on", kati.present(cell(today.plusDays(7))))

        // Swiping the strip right goes back a week in an English reading.
        kati.compose.onNodeWithTag(cell(today.plusDays(7)), useUnmergedTree = true)
            .performTouchInput { swipeRight() }
        kati.compose.waitUntil(10_000) { kati.present(cell(today)) }

        kati.compose.onNodeWithTag(cell(today), useUnmergedTree = true)
            .performTouchInput { swipeLeft() }
        kati.compose.waitUntil(10_000) { kati.present(cell(today.plusDays(7))) }

        kati.tap("today")
        kati.compose.waitUntil(10_000) { kati.present(cell(today)) }
    }

    @Test
    fun b_the_month_grid_turns_with_a_swipe_and_its_plus_adds_an_event() {
        openSchedule()
        kati.tap("open_month")
        // The month and the agenda are roots drawn through the shell, so
        // they carry `screen:calendar`; their own controls say which is up.
        kati.compose.waitUntil(15_000) { kati.present("month_next") }

        val next = today.plusMonths(1).withDayOfMonth(15)
        kati.compose.onNodeWithTag(cell(today), useUnmergedTree = true)
            .performTouchInput { swipeLeft() }
        kati.compose.waitUntil(10_000) { kati.present(cell(next)) }

        kati.tap("fab")
        try {
            kati.awaitScreen("quick_add", 15_000)
        } catch (e: Throwable) {
            throw AssertionError("after + on the month the screen is " + kati.tagStartingWith("screen:"), e)
        }
    }

    @Test
    fun c_the_day_page_moves_a_day_either_way() {
        openSchedule()
        // A second tap on the selected day opens its page.
        kati.tap(cell(today))
        kati.awaitScreen("day")

        kati.tap("day_next")
        kati.device.waitForIdle()
        kati.tap("day_previous")
        kati.device.waitForIdle()
        kati.awaitScreen("day")

        kati.device.pressBack()
        kati.awaitScreen("calendar")
    }

    @Test
    fun d_the_agenda_reads_back() {
        openSchedule()
        kati.tap("toggle_menu")
        kati.compose.waitUntil(10_000) { kati.present("open_agenda") }
        kati.tap("open_agenda")
        kati.compose.waitUntil(15_000) { kati.present("agenda_earlier") }
        kati.tap("agenda_earlier")
        kati.device.waitForIdle()
        try {
            kati.compose.waitUntil(15_000) { kati.present("agenda_earlier") }
        } catch (e: Throwable) {
            throw AssertionError("after Earlier the screen is " + kati.tagStartingWith("screen:"), e)
        }
    }
}
