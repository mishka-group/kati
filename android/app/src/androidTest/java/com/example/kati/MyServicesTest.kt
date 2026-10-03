package com.example.kati

import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performTextInput
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * #127 — My services says what it is for, and a service's whole life works:
 * added with its price, turned to *not mine*, listed under Not mine, and
 * brought back. Every step ends in `kati.db`.
 */
@RunWith(AndroidJUnit4::class)
class MyServicesTest {

    @get:Rule
    val kati = KatiRule()

    private val name = "kati-svc-${System.currentTimeMillis()}"

    private fun tier(): String? = kati.scalar("select tier from services where name = '$name'")

    private fun id(): String = kati.scalar("select id from services where name = '$name'") ?: ""

    @Test
    fun a_a_service_is_added_set_aside_and_brought_back() {
        kati.launch()
        kati.firstRun()
        kati.tap("open_services")
        kati.compose.waitUntil(20_000) { kati.present("service_query") }

        assertTrue("the page says what it is for", ByHand.shown(kati, "Tell Kati what you pay for"))
        assertFalse("no invented service", ByHand.shown(kati, "Lumen+"))

        kati.compose.onNodeWithTag("service_query", useUnmergedTree = true)
            .performTextInput("$name 9.99")
        kati.device.waitForIdle()
        Thread.sleep(1_500)
        kati.tap("add_service")
        kati.compose.waitUntil(20_000) { tier() != null }
        assertEquals("subscribed", tier())
        assertEquals("999", kati.scalar("select monthly_pence from services where name = '$name'"))

        // Not mine: off the subscribed list, onto Not mine with Add back.
        try {
            kati.compose.waitUntil(20_000) { kati.present("drop_service_${id()}") }
        } catch (e: Throwable) {
            throw AssertionError("drop controls on screen: " + kati.tagStartingWith("drop_service"), e)
        }
        kati.tap("drop_service_${id()}")
        kati.compose.waitUntil(20_000) { tier() == "not_mine" }
        kati.compose.waitUntil(20_000) { kati.present("restore_service_${id()}") }

        kati.tap("restore_service_${id()}")
        kati.compose.waitUntil(20_000) { tier() == "subscribed" }
        assertEquals("subscribed", tier())
    }
}
