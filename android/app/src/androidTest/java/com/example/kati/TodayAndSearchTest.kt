package com.example.kati

import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performTextInput
import androidx.test.ext.junit.runners.AndroidJUnit4
import java.time.LocalDate
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * The Library's shelves switch as tabs, something added for today shows on
 * Home's Rest of today, and Home's search finds it.
 */
@RunWith(AndroidJUnit4::class)
class TodayAndSearchTest {

    @get:Rule
    val kati = KatiRule()

    private val today = LocalDate.now()

    private fun mark(what: String) {
        android.util.Log.i("KATI_SHOT", "READY $what")
        Thread.sleep(6_000)
    }

    @Test
    fun a_shelves_switch_today_shows_on_home_and_search_finds_it() {
        kati.launch()
        kati.firstRun()

        // The shelves are tabs: Screen, Books and back to Screen.
        kati.tap("root_library")
        kati.awaitScreen("library")
        kati.compose.waitUntil(20_000) { kati.present("shelf_books") }
        kati.tap("shelf_books")
        kati.compose.waitUntil(20_000) { kati.present("open_screen") }
        kati.tap("open_screen")
        kati.compose.waitUntil(20_000) { kati.present("shelf_books") }

        // Something on today, from the calendar's +.
        kati.tap("root_calendar")
        kati.awaitScreen("calendar")
        kati.tap("fab")
        kati.awaitScreen("quick_add")
        kati.compose.onNodeWithTag("quick_add_sentence", useUnmergedTree = true)
            .performTextInput("Team call")
        kati.device.waitForIdle()
        kati.compose.waitUntil(10_000) { kati.present("pick_day_$today") }
        kati.tap("pick_day_$today")
        kati.device.waitForIdle()
        kati.compose.waitUntil(10_000) { kati.present("pick_time_2100") }
        kati.tap("pick_time_2100")
        kati.compose.waitUntil(10_000) { kati.present("commit") }
        Thread.sleep(1_000)
        kati.tap("commit")
        kati.systemDialog("Allow")
        kati.awaitScreen("calendar")

        kati.tap("root_home")
        kati.awaitScreen("home")
        kati.compose.waitUntil(20_000) { ByHand.shown(kati, "Team call") }
        mark("home")

        kati.tap("open_search")
        kati.awaitScreen("search")
        kati.compose.onNodeWithTag("search_query", useUnmergedTree = true).performTextInput("team")
        kati.device.waitForIdle()
        kati.compose.waitUntil(20_000) { ByHand.shown(kati, "Team call") }
        mark("search")
    }
}
