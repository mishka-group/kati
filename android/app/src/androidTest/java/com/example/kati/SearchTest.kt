package com.example.kati

import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performTextClearance
import androidx.compose.ui.test.performTextInput
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * #92 — a search box that takes what you type and finds it.
 *
 * Screen 19's field was a `<Text>` node with an orange box drawn to look like
 * a caret, and the query was the hardcoded string `hollow`. Nothing anywhere
 * matched a title, an episode, an event or a note by substring, so the page
 * drew six hits for a query it could not run.
 *
 * ## The receipt is the row, not the screen
 *
 * A search page redrawing its sample is indistinguishable from one redrawing a
 * result, which is why this test writes the row it then looks for: it adds a
 * title through the app's own by-hand form, searches for a word out of that
 * title, and asserts the title comes back — and that a word which is in no row
 * at all comes back with the no-match card instead.
 *
 * Both halves matter. A field that returned everything would pass the first
 * assertion and fail the second; a field that returned nothing would pass the
 * second and fail the first. Neither alone says the query ran.
 */
@RunWith(AndroidJUnit4::class)
class SearchTest {

    @get:Rule
    val kati = KatiRule()

    private val title = "Estuary Nights"

    private fun textPresent(text: String): Boolean =
        kati.compose
            .onAllNodesWithText(text, substring = true, useUnmergedTree = true)
            .fetchSemanticsNodes()
            .isNotEmpty()

    /** Puts one real row in the store, through the form a person would use. */
    private fun addTitleByHand() {
        kati.tap("root_library")
        kati.awaitScreen("library")
        kati.tap("add_title")
        kati.compose.waitUntil(20_000) { kati.present("add_by_hand") }
        kati.tap("add_by_hand")
        kati.awaitScreen("add_by_hand")

        kati.compose.onNodeWithTag("title", useUnmergedTree = true).performTextClearance()
        kati.compose.onNodeWithTag("title", useUnmergedTree = true).performTextInput(title)
        kati.device.waitForIdle()

        kati.tap("add")
        kati.compose.waitUntil(20_000) { kati.count("tracked_titles") > 0 }
    }

    @Test
    fun a_typing_returns_what_matches_and_not_what_does_not() {
        kati.launch()
        kati.firstRun()

        addTitleByHand()

        kati.tap("root_home")
        kati.awaitScreen("home")
        kati.tap("search")
        kati.compose.waitUntil(20_000) { kati.present("search_query") }

        // A word out of the title that was just written, not the whole title:
        // a field that only matched a query equal to a row would pass on the
        // full string and be no use to anybody.
        kati.compose.onNodeWithTag("search_query", useUnmergedTree = true)
            .performTextInput("estuary")
        kati.device.waitForIdle()

        kati.compose.waitUntil(20_000) { textPresent(title) }

        assertTrue(
            "typing a word out of a stored title found nothing, so the field is still a " +
                "drawing of a search box",
            textPresent(title)
        )
    }

    @Test
    fun b_a_word_in_no_row_says_so_rather_than_drawing_nothing() {
        kati.launch()
        kati.firstRun()

        addTitleByHand()

        kati.tap("root_home")
        kati.awaitScreen("home")
        kati.tap("search")
        kati.compose.waitUntil(20_000) { kati.present("search_query") }

        kati.compose.onNodeWithTag("search_query", useUnmergedTree = true)
            .performTextInput("vellichor")
        kati.device.waitForIdle()

        // Board 89's card, and it names the query back. An empty list under a
        // query reads as a search that broke; this reads as a correct report
        // that you do not have it.
        kati.compose.waitUntil(20_000) { textPresent("Nothing here for") }

        assertTrue(
            "a query that matched nothing drew no state of its own, which reads as a " +
                "search that failed rather than as a library that does not have it",
            textPresent("Nothing here for")
        )

        assertTrue(
            "the no-match card offers no way out — a dead end with no next move is the " +
                "state this card exists to avoid",
            kati.present("look_up") || kati.present("add_by_hand")
        )

        assertTrue(
            "a title that does not match the query was drawn anyway, so the field returns " +
                "rows it did not find",
            !textPresent(title)
        )
    }
}
