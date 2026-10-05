package com.example.kati

import androidx.compose.ui.test.isDisplayed
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.swipeLeft
import androidx.compose.ui.test.swipeRight
import androidx.test.ext.junit.runners.AndroidJUnit4
import java.time.LocalDate
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * The rows a reader slides with a finger: the Schedule's week strip, Home's
 * Continue watching, and the day and service chips on Log a watch. Each one
 * is checked by what is on screen after the slide, and the chip a slide
 * reaches is tapped and saved to kati.db.
 */
@RunWith(AndroidJUnit4::class)
class SlidersTest {

    @get:Rule
    val kati = KatiRule()

    private val stamp = System.currentTimeMillis()
    private val today = LocalDate.now()

    private fun onScreen(tag: String): Boolean =
        try {
            kati.compose.onNodeWithTag(tag, useUnmergedTree = true).isDisplayed()
        } catch (_: Throwable) {
            false
        }

    private fun slide(tag: String, left: Boolean) {
        kati.compose.onNodeWithTag(tag, useUnmergedTree = true)
            .performTouchInput { if (left) swipeLeft() else swipeRight() }
        kati.device.waitForIdle()
    }

    @Test
    fun a_the_week_strip_turns_a_week_under_the_finger() {
        kati.launch()
        kati.firstRun()
        kati.tap("root_calendar")
        kati.awaitScreen("calendar")
        kati.compose.waitUntil(10_000) { onScreen("day_$today") }
        assertFalse("next week is on screen before any slide", onScreen("day_${today.plusDays(7)}"))

        slide("week_strip", left = true)
        kati.compose.waitUntil(10_000) { onScreen("day_${today.plusDays(7)}") }
        kati.compose.waitUntil(10_000) { !onScreen("day_$today") }

        slide("week_strip", left = false)
        kati.compose.waitUntil(10_000) { onScreen("day_$today") }

        slide("week_strip", left = false)
        kati.compose.waitUntil(10_000) { onScreen("day_${today.minusDays(7)}") }
    }

    @Test
    fun b_continue_watching_slides_two_cards_at_a_time() {
        kati.launch()
        kati.firstRun()
        val shows = (1..3).map { "Slide Show $it $stamp" }
        for (show in shows) {
            ByHand.add(kati, show, "kind_tv", "status_watching")
        }
        val cards = shows.map { show ->
            "open_series_" + (kati.scalar("select id from tracked_titles where source_id = '$show'") ?: "")
        }
        ByHand.toTabs(kati)
        kati.tap("root_home")
        kati.awaitScreen("home")
        kati.compose.waitUntil(20_000) { kati.present("continue_cards") }
        kati.compose.waitUntil(20_000) { cards.all { kati.present(it) } }

        val atRest = cards.filter { onScreen(it) }.toSet()
        assertFalse("three cards side by side on one page", atRest.size > 2)

        slide("continue_cards", left = true)
        kati.compose.waitUntil(10_000) { cards.any { it !in atRest && onScreen(it) } }

        slide("continue_cards", left = false)
        kati.compose.waitUntil(10_000) { cards.filter { onScreen(it) }.toSet() == atRest }
    }

    @Test
    fun c_a_day_two_weeks_back_is_slid_to_and_saved() {
        val film = "Slide Film $stamp"
        kati.launch()
        kati.firstRun()
        ByHand.add(kati, film, "kind_movie")
        val id = kati.scalar("select id from tracked_titles where source_id = '$film'") ?: ""
        kati.awaitScreen("film")

        kati.tap("rate")
        kati.awaitScreen("rating")
        kati.tap("open_where")
        kati.compose.waitUntil(10_000) { kati.present("where_chips") }
        kati.tap("open_watched_on")
        kati.compose.waitUntil(10_000) { kati.present("day_chips") }

        val back = today.minusDays(12)
        assertFalse("a day twelve back fits without sliding", onScreen("day_$back"))
        slide("day_chips", left = true)
        slide("day_chips", left = true)
        kati.compose.waitUntil(10_000) { onScreen("day_$back") }
        kati.tap("day_$back")
        kati.device.waitForIdle()
        kati.tap("save")

        kati.awaitScreen("film")
        kati.compose.waitUntil(20_000) {
            kati.scalar("select watched_on from media_watches where tracked_title_id = '$id'") != null
        }
        assertEquals(
            back.toString(),
            kati.scalar("select watched_on from media_watches where tracked_title_id = '$id'")
        )
    }
}
