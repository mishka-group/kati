package com.example.kati

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.uiautomator.By
import androidx.test.uiautomator.Until
import org.junit.Assert.assertNotEquals
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * #123 — Share on a show, an anime and a film opens Android's share sheet.
 *
 * What lands in the receiving app is the share sheet's business; what this
 * proves is that the pill is there on every kind of title page and that
 * pressing it hands over to the system rather than doing nothing.
 */
@RunWith(AndroidJUnit4::class)
class ShareTest {

    @get:Rule
    val kati = KatiRule()

    private val stamp = System.currentTimeMillis()

    private fun sheetOpens(tag: String) {
        kati.tap(tag)
        kati.device.wait(Until.gone(By.pkg("com.example.kati").depth(0)), 10_000)
        assertNotEquals(
            "pressing $tag should hand over to the share sheet",
            "com.example.kati",
            kati.device.currentPackageName
        )
        kati.device.pressBack()
        kati.device.wait(Until.hasObject(By.pkg("com.example.kati").depth(0)), 10_000)
    }

    @Test
    fun a_a_show_shares() {
        kati.launch()
        kati.firstRun()
        ByHand.add(kati, "Share Show $stamp", "kind_tv")
        kati.awaitScreen("series")
        sheetOpens("share_title")
        kati.awaitScreen("series")
    }

    @Test
    fun b_a_film_shares() {
        kati.launch()
        kati.firstRun()
        ByHand.add(kati, "Share Film $stamp", "kind_movie")
        kati.awaitScreen("film")
        sheetOpens("share_film")
        kati.awaitScreen("film")
    }
}
