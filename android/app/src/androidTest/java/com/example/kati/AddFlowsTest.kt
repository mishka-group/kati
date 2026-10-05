package com.example.kati

import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performTextInput
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertFalse
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Every `+` opens the search on its own section, Quick add writes what was
 * typed, and Your year has no `+` at all.
 */
@RunWith(AndroidJUnit4::class)
class AddFlowsTest {

    @get:Rule
    val kati = KatiRule()

    @Test
    fun a_music_plus_opens_the_search_on_music_and_its_panel_opens_the_album_form() {
        kati.launch()
        // Music is offered only to a reader who picked it at first run.
        kati.toSections()
        kati.tapAny("section_music")
        kati.device.waitForIdle()
        kati.finishRun()
        kati.tap("root_home")
        kati.awaitScreen("home")
        kati.compose.waitUntil(20_000) { kati.present("open_music") }
        kati.tap("open_music")
        kati.compose.waitUntil(20_000) { !kati.present("open_music") && kati.present("fab") }
        kati.device.waitForIdle()
        kati.tap("fab")
        kati.awaitScreen("search")
        kati.compose.waitUntil(20_000) { kati.present("add_album") }
        kati.tap("add_album")
        kati.awaitScreen("add_by_hand_record")
    }

    @Test
    fun b_the_calendar_plus_writes_the_typed_sentence() {
        kati.launch()
        kati.firstRun()
        val before = kati.count("events")
        kati.tap("root_calendar")
        kati.awaitScreen("calendar")
        kati.tap("fab")
        kati.awaitScreen("quick_add")
        kati.compose.waitUntil(10_000) { kati.present("quick_add_sentence") }
        kati.compose.onNodeWithTag("quick_add_sentence", useUnmergedTree = true)
            .performTextInput("dentist tomorrow 3pm")
        kati.device.waitForIdle()
        kati.compose.waitUntil(20_000) { kati.present("commit") }
        Thread.sleep(2_000)
        kati.device.waitForIdle()
        kati.tap("commit")
        kati.compose.waitUntil(20_000) { kati.count("events") > before }
    }

    @Test
    fun c_your_year_has_no_plus() {
        kati.launch()
        kati.firstRun()
        kati.tap("root_stats")
        kati.awaitScreen("stats")
        kati.device.waitForIdle()
        assertFalse("Your year still draws a +", kati.present("fab"))
    }
}
