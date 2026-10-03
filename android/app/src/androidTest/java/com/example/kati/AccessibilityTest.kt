package com.example.kati

import androidx.compose.ui.test.onAllNodesWithContentDescription
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * #118 and #119 — the display choices are stored, and a page arrives the way
 * they say.
 *
 * *Reduce motion* on screen 24 used to move its thumb and store nothing: the
 * next mount drew it off again, and no page ever arrived differently. Every
 * switch here is read through what TalkBack hears (*Reduce motion: on*),
 * because a drawn switch is boxes and its colour is the only other sign of its
 * state — and that is exactly what a screen reader cannot see.
 */
@RunWith(AndroidJUnit4::class)
class AccessibilityTest {

    @get:Rule
    val kati = KatiRule()

    private fun heard(description: String): Boolean =
        try {
            kati.compose.onAllNodesWithContentDescription(description, useUnmergedTree = true)
                .fetchSemanticsNodes().isNotEmpty()
        } catch (_: Throwable) {
            false
        }

    private fun awaitHeard(description: String) {
        try {
            kati.compose.waitUntil(20_000) { heard(description) }
        } catch (_: Throwable) {
            // The assertion that follows names what was missing.
        }
        assertTrue("TalkBack would not hear \"$description\"", heard(description))
    }

    private fun openSettings() {
        kati.popToRoot()
        kati.tap("root_home")
        kati.awaitScreen("home")
        kati.tap("open_settings")
        kati.awaitScreen("settings")
    }

    @Test
    fun a_reduce_motion_is_stored_and_a_fresh_settings_screen_reads_it_back() {
        kati.launch()
        kati.firstRun()
        openSettings()

        awaitHeard("Reduce motion: off")

        kati.tap("switch_reduce_motion")
        awaitHeard("Reduce motion: on")

        // The half one tap cannot prove: a switch that only moved its own
        // thumb looks right until the screen that drew it is thrown away.
        kati.device.pressBack()
        kati.device.waitForIdle()
        openSettings()
        awaitHeard("Reduce motion: on")
    }

    @Test
    fun b_with_motion_reduced_every_push_and_pop_still_lands() {
        kati.launch()
        kati.firstRun()
        openSettings()
        kati.tap("switch_reduce_motion")
        awaitHeard("Reduce motion: on")

        // A fade that never finished would leave the page at alpha 0: present
        // in the tree, invisible to a person. A tap on a control of the
        // arrived page is the proof it is there to be used.
        kati.tap("go_language")
        kati.awaitScreen("language")
        kati.device.pressBack()
        kati.awaitScreen("settings")
        kati.tap("go_text_size")
        kati.awaitScreen("accessibility")
        kati.device.pressBack()
        kati.awaitScreen("settings")

        kati.tap("switch_reduce_motion")
        awaitHeard("Reduce motion: off")
    }
}
