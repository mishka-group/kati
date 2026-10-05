package com.example.kati

import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performTextClearance
import androidx.compose.ui.test.performTextInput

/**
 * Shared steps for journeys that need a title on the shelf without the
 * network: the by-hand form, as a person fills it, and the way back to a tab.
 */
object ByHand {

    /**
     * Back to a tab. A by-hand add REPLACES the stack with the new title's page
     * (`Mob.Socket.reset_to`), so the system back has no root under it; the
     * page's own back pill is the way out, then back as usual.
     */
    fun toTabs(kati: KatiRule) {
        repeat(5) {
            if (kati.present("root_library")) return
            // The pill can go between seeing it and tapping it, when the page
            // under it finishes loading; the next round looks again.
            if (kati.present("back")) {
                try {
                    kati.tap("back")
                } catch (_: AssertionError) {
                }
            } else {
                kati.device.pressBack()
            }
            kati.device.waitForIdle()
            kati.compose.waitUntil(5_000) { true }
        }
        kati.compose.waitUntil(20_000) { kati.present("root_library") }
    }

    /** Adds `title` as `kind` (`kind_tv` or `kind_movie`) and lands on its page. */
    fun add(kati: KatiRule, title: String, kind: String, status: String? = null) {
        val before = kati.count("tracked_titles")
        toTabs(kati)
        kati.tap("fab")
        kati.awaitScreen("search")
        kati.compose.onNodeWithTag("search_query", useUnmergedTree = true).performTextInput(title)
        kati.device.waitForIdle()
        kati.compose.waitUntil(20_000) { kati.present("add_by_hand") }
        kati.tap("add_by_hand")
        kati.awaitScreen("add_by_hand")
        kati.tap(kind)
        kati.device.waitForIdle()
        if (status != null) {
            kati.tap(status)
            kati.device.waitForIdle()
        }
        kati.compose.onNodeWithTag("title", useUnmergedTree = true).performTextClearance()
        kati.compose.onNodeWithTag("title", useUnmergedTree = true).performTextInput(title)
        kati.device.waitForIdle()
        kati.tap("add")
        kati.compose.waitUntil(20_000) { kati.count("tracked_titles") > before }
    }

    fun shown(kati: KatiRule, text: String): Boolean =
        try {
            kati.compose.onAllNodesWithText(text, substring = true, useUnmergedTree = true)
                .fetchSemanticsNodes().isNotEmpty()
        } catch (_: Throwable) {
            false
        }
}
