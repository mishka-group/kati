package com.example.kati

import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * #122 — *New releases* says what it has, looks for news, and has no empty
 * placeholder left in it.
 */
@RunWith(AndroidJUnit4::class)
class NewReleasesTest {

    @get:Rule
    val kati = KatiRule()

    private val show = "Releases Show ${System.currentTimeMillis()}"

    private fun openNewReleases() {
        ByHand.toTabs(kati)
        kati.tap("root_library")
        kati.awaitScreen("library")
        kati.tap("toggle_menu")
        kati.compose.waitUntil(10_000) { kati.present("open_new_releases") }
        kati.tap("open_new_releases")
        kati.awaitScreen("inbox")
    }

    @Test
    fun a_followed_and_nothing_dated_says_so_and_checks_for_news() {
        kati.launch()
        kati.firstRun()
        ByHand.add(kati, show, "kind_tv")
        openNewReleases()

        kati.compose.waitUntil(10_000) { ByHand.shown(kati, "No dates yet") }
        assertTrue(ByHand.shown(kati, "Nothing new in the last week."))

        // Never checked, so the page looks as it opens. The pill comes back
        // when the sweep answers. A by-hand show and no TMDB key give it
        // nothing to ask, and the page says why and where a key goes rather
        // than staying on "never checked" in silence.
        kati.compose.waitUntil(60_000) { kati.present("check_now") }
        assertTrue(
            "a check that could not run should say why",
            ByHand.shown(kati, "No TMDB key yet")
        )
        assertTrue(kati.present("open_data_sources"))

        kati.tap("check_now")
        kati.compose.waitUntil(60_000) { kati.present("check_now") }
        kati.tap("open_data_sources")
        kati.awaitScreen("data_sources")
    }

    @Test
    fun b_the_gear_opens_the_watcher_and_back_returns() {
        kati.launch()
        kati.firstRun()
        ByHand.add(kati, show, "kind_tv")
        openNewReleases()

        kati.tap("open_watcher")
        kati.awaitScreen("release_watcher")
        kati.device.pressBack()
        kati.awaitScreen("inbox")
    }
}
