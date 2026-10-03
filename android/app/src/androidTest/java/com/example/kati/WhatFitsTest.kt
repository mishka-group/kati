package com.example.kati

import androidx.compose.ui.test.onAllNodesWithText
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * #121 — *What fits?* is the reader's own evening, and says so honestly.
 *
 * The window the reader picks is kept for next time, an empty shelf is an
 * empty card that says how to fill it, and the services band no longer claims
 * `0 you can watch` over a shelf it has nothing to say about.
 */
@RunWith(AndroidJUnit4::class)
class WhatFitsTest {

    @get:Rule
    val kati = KatiRule()

    private fun shown(text: String): Boolean =
        try {
            kati.compose.onAllNodesWithText(text, substring = true, useUnmergedTree = true)
                .fetchSemanticsNodes().isNotEmpty()
        } catch (_: Throwable) {
            false
        }

    private fun openWhatFits() {
        kati.popToRoot()
        kati.tap("root_library")
        kati.awaitScreen("library")
        kati.tap("toggle_menu")
        kati.compose.waitUntil(10_000) { kati.present("open_what_fits") }
        kati.tap("open_what_fits")
        kati.awaitScreen("what_fits")
    }

    @Test
    fun a_the_window_chosen_is_the_window_it_opens_on_next_time() {
        kati.launch()
        kati.firstRun()
        openWhatFits()

        kati.compose.waitUntil(10_000) { shown("45 min") }
        kati.tap("window_1h")
        kati.compose.waitUntil(10_000) { shown("1 hr") }

        kati.device.pressBack()
        kati.awaitScreen("library")
        kati.tap("toggle_menu")
        kati.compose.waitUntil(10_000) { kati.present("open_what_fits") }
        kati.tap("open_what_fits")
        kati.awaitScreen("what_fits")

        kati.compose.waitUntil(10_000) { shown("1 hr") }
        assertTrue("the page forgot the window the reader chose", shown("1 hr"))
    }

    @Test
    fun b_an_empty_shelf_is_an_empty_card_and_no_services_prompt() {
        kati.launch()
        kati.firstRun()
        openWhatFits()

        kati.compose.waitUntil(10_000) { shown("Nothing on your shelf to measure yet") }
        assertTrue(shown("Add a film or a series"))
        assertFalse(
            "with nothing to filter, the page should not ask about services",
            kati.present("my_services_what_fits")
        )
        assertFalse(shown("you can watch"))
    }
}
