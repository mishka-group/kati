package com.example.kati

import androidx.compose.ui.test.longClick
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performTextClearance
import androidx.compose.ui.test.performTextInput
import androidx.compose.ui.test.performTouchInput
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * #120 — selecting titles on the shelf, and every action on the selection.
 *
 * The route is the one a person walks: a long press on a Library poster, the
 * door the board always drew and nothing built. Every assertion about a write
 * ends in `kati.db`, because a tile that lights and a status that changed look
 * the same until the store is asked.
 */
@RunWith(AndroidJUnit4::class)
class ShelfSelectionTest {

    @get:Rule
    val kati = KatiRule()

    private val stamp = System.currentTimeMillis()
    private val show = "Selection Show $stamp"
    private val film = "Selection Film $stamp"

    private fun idOf(title: String): String =
        kati.scalar("select id from tracked_titles where source_id = '$title'") ?: ""

    private fun column(title: String, column: String): String? =
        kati.scalar("select $column from tracked_titles where source_id = '$title'")

    private fun addByHand(title: String, kind: String) {
        val before = kati.count("tracked_titles")
        toTabs()
        kati.tap("fab")
        kati.awaitScreen("add_title")
        kati.compose.onNodeWithTag("title_query", useUnmergedTree = true).performTextInput(title)
        kati.device.waitForIdle()
        kati.compose.waitUntil(20_000) { kati.present("add_by_hand") }
        kati.tap("add_by_hand")
        kati.awaitScreen("add_by_hand")
        kati.tap(kind)
        kati.device.waitForIdle()
        kati.compose.onNodeWithTag("title", useUnmergedTree = true).performTextClearance()
        kati.compose.onNodeWithTag("title", useUnmergedTree = true).performTextInput(title)
        kati.device.waitForIdle()
        kati.tap("add")
        kati.compose.waitUntil(20_000) { kati.count("tracked_titles") > before }
    }

    /**
     * Back to a tab. A by-hand add REPLACES the stack with the new title's page
     * (`Mob.Socket.reset_to`), so the system back has no root under it; the
     * page's own back pill is the way out, then back as usual.
     */
    private fun toTabs() {
        repeat(5) {
            if (kati.present("root_library")) return
            if (kati.present("back")) kati.tap("back") else kati.device.pressBack()
            kati.device.waitForIdle()
            kati.compose.waitUntil(5_000) { true }
        }
        kati.compose.waitUntil(20_000) { kati.present("root_library") }
    }

    private fun shown(text: String): Boolean =
        try {
            kati.compose.onAllNodesWithText(text, substring = true, useUnmergedTree = true)
                .fetchSemanticsNodes().isNotEmpty()
        } catch (_: Throwable) {
            false
        }

    private fun openSelectionByLongPress(title: String) {
        toTabs()
        kati.tap("root_library")
        kati.awaitScreen("library")
        val tag = "open_series_" + idOf(title)
        kati.compose.waitUntil(20_000) { kati.present(tag) }
        kati.compose.onNodeWithTag(tag, useUnmergedTree = true).performTouchInput { longClick() }
        kati.awaitScreen("shelf_selection")
    }

    @Test
    fun a_a_long_press_selects_and_status_and_remove_and_undo_write_the_store() {
        kati.launch()
        kati.firstRun()
        addByHand(show, "kind_tv")
        addByHand(film, "kind_movie")

        val showId = idOf(show)
        val filmId = idOf(film)
        assertTrue("both titles should be on the shelf", showId != "" && filmId != "")

        openSelectionByLongPress(show)
        kati.compose.waitUntil(10_000) { shown("1 selected") }

        // Select the film too, then give both one status.
        kati.tap("open_film_$filmId")
        kati.compose.waitUntil(10_000) { shown("2 selected") }
        kati.tap("change_status")
        kati.compose.waitUntil(10_000) { kati.present("set_status_paused") }
        kati.tap("set_status_paused")
        kati.compose.waitUntil(20_000) {
            column(show, "status") == "paused" && column(film, "status") == "paused"
        }
        assertEquals("paused", column(show, "status"))
        assertEquals("paused", column(film, "status"))

        // The status row closes once the write lands; the bar under it moves.
        kati.compose.waitUntil(10_000) { !kati.present("set_status_paused") }
        kati.device.waitForIdle()

        // Remove both: off the shelf at once, the rows kept until the window ends.
        kati.tap("remove_selected")
        kati.compose.waitUntil(10_000) { kati.present("undo") }
        assertEquals("1", column(show, "archived"))

        // Undo: back, with the status they had.
        kati.tap("undo")
        kati.compose.waitUntil(10_000) { column(show, "archived") == "0" }
        assertEquals("0", column(film, "archived"))
        assertEquals("paused", column(show, "status"))
        kati.compose.waitUntil(10_000) { shown("2 selected") }
    }

    @Test
    fun b_remove_is_final_once_the_selection_is_closed() {
        kati.launch()
        kati.firstRun()
        addByHand(show, "kind_tv")

        openSelectionByLongPress(show)
        kati.tap("remove_selected")
        kati.compose.waitUntil(10_000) { kati.present("undo") }

        kati.tap("close")
        kati.awaitScreen("library")
        kati.compose.waitUntil(20_000) { idOf(show) == "" }
        assertEquals("the row should be gone once the undo window closed", "", idOf(show))
    }

    @Test
    fun c_add_to_list_carries_the_selection() {
        kati.launch()
        kati.firstRun()
        addByHand(show, "kind_tv")

        openSelectionByLongPress(show)
        kati.tap("add_to_list")
        kati.awaitScreen("add_to_list")
    }
}
