package com.example.kati

import androidx.compose.ui.test.onAllNodesWithContentDescription
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithText
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertEquals
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

    private fun openAccessibility() {
        openSettings()
        kati.tap("go_text_size")
        kati.awaitScreen("accessibility")
    }

    private fun shown(text: String): Boolean =
        try {
            kati.compose.onAllNodesWithText(text, substring = true, useUnmergedTree = true)
                .fetchSemanticsNodes().isNotEmpty()
        } catch (_: Throwable) {
            false
        }

    /** The drawn height of the page title, in pixels: what a text size changes. */
    private fun titleHeight(): Int =
        kati.compose.onNodeWithText("Accessibility", useUnmergedTree = true)
            .fetchSemanticsNode().size.height

    @Test
    fun c_a_text_size_is_stored_and_every_page_is_drawn_larger() {
        kati.launch()
        kati.firstRun()
        openAccessibility()

        awaitHeard("Phone text, chosen")
        val before = titleHeight()

        kati.tap("text_size_larger")
        awaitHeard("Larger text, chosen")
        kati.compose.waitUntil(10_000) { titleHeight() > before }
        assertTrue(
            "the title is ${titleHeight()}px after Larger and was ${before}px — K-72's density " +
                "did not reach the tree",
            titleHeight() > before
        )

        // Screen 24's row names the size, and a fresh screen 41 opens on it.
        kati.device.pressBack()
        kati.awaitScreen("settings")
        kati.compose.waitUntil(10_000) { shown("Larger · 130%") }
        kati.tap("go_text_size")
        kati.awaitScreen("accessibility")
        awaitHeard("Larger text, chosen")

        kati.tap("text_size_system")
        awaitHeard("Phone text, chosen")
        kati.compose.waitUntil(10_000) { titleHeight() == before }
        assertEquals("back on the phone's size, the title should be its old height", before, titleHeight())
    }

    @Test
    fun d_increase_contrast_is_stored_and_reduce_motion_is_the_same_switch_as_settings() {
        kati.launch()
        kati.firstRun()
        openAccessibility()

        awaitHeard("Increase contrast: off")
        kati.tap("toggle_contrast")
        awaitHeard("Increase contrast: on")

        kati.tap("toggle_motion")
        awaitHeard("Reduce motion: on")

        kati.device.pressBack()
        kati.awaitScreen("settings")
        awaitHeard("Reduce motion: on")

        kati.tap("go_text_size")
        kati.awaitScreen("accessibility")
        awaitHeard("Increase contrast: on")
        awaitHeard("Reduce motion: on")
    }

    @Test
    fun e_the_system_row_opens_android_accessibility_settings() {
        kati.launch()
        kati.firstRun()
        openAccessibility()

        kati.tap("open_system")
        kati.device.wait(
            androidx.test.uiautomator.Until.hasObject(
                androidx.test.uiautomator.By.pkg("com.android.settings").depth(0)
            ),
            10_000
        )
        assertEquals(
            "the row should hand over to Android's own settings",
            "com.android.settings",
            kati.device.currentPackageName
        )

        kati.device.pressBack()
        kati.awaitScreen("accessibility")
    }
}
