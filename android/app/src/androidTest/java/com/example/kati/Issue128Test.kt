package com.example.kati

import android.graphics.BitmapFactory
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performTextInput
import androidx.test.ext.junit.runners.AndroidJUnit4
import java.io.File
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * mishka-group/kati#128 on a device: the share card is the card alone, with
 * its shadow, Your year's round slot shares, Up next rows open their
 * title with no empty Gone cold band, and a film kept in a list says so.
 */
@RunWith(AndroidJUnit4::class)
class Issue128Test {

    @get:Rule
    val kati = KatiRule()

    private fun capture(): File =
        File(
            androidx.test.platform.app.InstrumentationRegistry.getInstrumentation().targetContext.cacheDir,
            "kati-year-${java.time.LocalDate.now().year}.png"
        )

    /** A tap on a control that may sit below the fold of a sheet. */
    private fun reach(tag: String) {
        repeat(4) {
            try {
                kati.tap(tag)
                return
            } catch (_: AssertionError) {
                val d = kati.device
                d.swipe(d.displayWidth / 2, d.displayHeight * 3 / 4, d.displayWidth / 2, d.displayHeight / 4, 20)
                d.waitForIdle()
            }
        }
        kati.tap(tag)
    }

    private fun mark(what: String) {
        android.util.Log.i("KATI_SHOT", "READY $what")
        Thread.sleep(6_000)
    }

    @Test
    fun a_the_share_card_is_the_card_in_its_shape() {
        kati.launch()
        kati.firstRun()

        kati.tap("root_stats")
        kati.awaitScreen("stats")
        kati.compose.waitUntil(20_000) { kati.present("share_fab") }
        mark("stats_dock")
        kati.tap("share_fab")
        kati.compose.waitUntil(20_000) { kati.present("save_image") }
        assertFalse("the scope rail is gone", kati.present("scope_books"))

        capture().delete()
        kati.tap("save_image")
        kati.compose.waitUntil(10_000) { capture().exists() }
        val square = BitmapFactory.decodeFile(capture().path)
        val screen = kati.device.displayHeight
        assertTrue("the card, not the screen", square.height < screen)
        kati.device.pressBack()
        kati.device.waitForIdle()

        kati.compose.waitUntil(20_000) { kati.present("aspect_story") }
        kati.tap("aspect_story")
        capture().delete()
        kati.tap("share_image")
        kati.compose.waitUntil(10_000) { capture().exists() }
        val story = BitmapFactory.decodeFile(capture().path)
        assertTrue("Story sets the card's type larger", story.height > square.height)
        mark("share_sheet")
        kati.device.pressBack()
        kati.device.waitForIdle()
    }

    @Test
    fun b_up_next_rows_open_and_no_empty_cold_band() {
        kati.launch()
        kati.firstRun()
        // Two shows: the first is Up next's hero, the second a row under it.
        ByHand.add(kati, "Radio Star", "kind_tv", "status_watching")
        ByHand.add(kati, "Silo", "kind_tv", "status_watching")
        ByHand.toTabs(kati)

        kati.tap("root_library")
        kati.awaitScreen("library")
        kati.compose.waitUntil(20_000) { kati.present("open_up_next") }
        kati.tap("open_up_next")
        kati.awaitScreen("up_next")
        kati.compose.waitUntil(20_000) { kati.tagStartingWith("row_") != null }
        assertFalse("no Gone cold band over nothing", ByHand.shown(kati, "GONE COLD"))
        mark("up_next")

        kati.tap(kati.tagStartingWith("row_")!!)
        kati.awaitScreen("series")
    }

    @Test
    fun c_a_film_in_a_list_says_so() {
        kati.launch()
        kati.firstRun()
        ByHand.add(kati, "Rogue Nation", "kind_movie")

        kati.compose.waitUntil(20_000) { kati.present("add_to_list") }
        kati.systemDialog("Allow")
        kati.device.waitForIdle()
        Thread.sleep(1_500)
        assertTrue(ByHand.shown(kati, "Add to list"))
        kati.tap("add_to_list")
        kati.awaitScreen("add_to_list")
        reach("new_list")
        kati.compose.waitUntil(10_000) { kati.present("list_name") }
        kati.compose.onNodeWithTag("list_name", useUnmergedTree = true).performTextInput("Weekend")
        kati.device.waitForIdle()
        reach("save_list")
        kati.device.waitForIdle()
        kati.compose.waitUntil(10_000) { kati.count("list_memberships") > 0 }

        kati.device.pressBack()
        kati.compose.waitUntil(20_000) { ByHand.shown(kati, "In a list") }
        mark("film_in_list")
    }
}
