package com.example.kati

import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performTextInput
import androidx.test.ext.junit.runners.AndroidJUnit4
import java.time.LocalDate
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * A day with an all-day item and a timed one: the timed row sits clear of the
 * all-day band rather than touching it, and the all-day row says All day.
 */
@RunWith(AndroidJUnit4::class)
class DayPageTest {

    @get:Rule
    val kati = KatiRule()

    private val tomorrow = LocalDate.now().plusDays(1)

    private fun quickAdd(sentence: String, hour: String?) {
        kati.tap("fab")
        kati.awaitScreen("quick_add")
        kati.compose.onNodeWithTag("quick_add_sentence", useUnmergedTree = true)
            .performTextInput(sentence)
        kati.device.waitForIdle()
        kati.compose.waitUntil(10_000) { kati.present("pick_day_$tomorrow") }
        kati.tap("pick_day_$tomorrow")
        kati.device.waitForIdle()
        if (hour != null) {
            kati.compose.waitUntil(10_000) { kati.present("pick_time_$hour") }
            kati.tap("pick_time_$hour")
            kati.device.waitForIdle()
        }
        kati.compose.waitUntil(10_000) { kati.present("commit") }
        Thread.sleep(1_000)
        kati.tap("commit")
        kati.systemDialog("Allow")
        kati.awaitScreen("calendar")
    }

    private fun top(text: String): Float =
        kati.compose.onAllNodesWithText(text, useUnmergedTree = true)
            .fetchSemanticsNodes().first().boundsInRoot.top

    private fun bottom(text: String): Float =
        kati.compose.onAllNodesWithText(text, useUnmergedTree = true)
            .fetchSemanticsNodes().first().boundsInRoot.bottom

    @Test
    fun a_a_timed_row_sits_clear_of_the_all_day_band() {
        kati.launch()
        kati.firstRun()
        kati.tap("root_calendar")
        kati.awaitScreen("calendar")

        quickAdd("Lunch with Sara", null)
        quickAdd("Dentist", "1500")

        kati.tap("day_$tomorrow")
        kati.device.waitForIdle()
        kati.tap("day_$tomorrow")
        kati.awaitScreen("day")
        kati.compose.waitUntil(10_000) { ByHand.shown(kati, "Dentist") && ByHand.shown(kati, "Lunch with Sara") }

        val dp = androidx.test.platform.app.InstrumentationRegistry.getInstrumentation().targetContext.resources.displayMetrics.density
        val gap = (top("Dentist") - bottom("Lunch with Sara")) / dp
        android.util.Log.i("KATI_DAY", "READY gap=$gap")
        Thread.sleep(15_000)

        assertTrue("the timed row is only ${gap}dp below the all-day row", gap >= 40f)
        assertTrue("an all-day row reads All day, not a clock", ByHand.shown(kati, "All day"))
        assertTrue("the whole day has an All chip", kati.present("filter_All"))
        assertTrue("an all-day row shows a midnight it does not have", !ByHand.shown(kati, "00:00"))
    }
}
