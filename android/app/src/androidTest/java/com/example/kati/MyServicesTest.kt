package com.example.kati

import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performTextClearance
import androidx.compose.ui.test.performTextInput
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * My services, every control on it: the add card (name, paid or free, price,
 * Add), a service's own tap (edit, Save, Delete, Cancel), its Mine switch, and
 * Not mine's Add back. Every step ends in `kati.db`.
 */
@RunWith(AndroidJUnit4::class)
class MyServicesTest {

    @get:Rule
    val kati = KatiRule()

    private val name = "kati-svc-${System.currentTimeMillis()}"

    private fun column(column: String): String? =
        kati.scalar("select $column from services where name = '$name'")

    private fun id(): String = column("id") ?: ""

    private fun open() {
        kati.launch()
        kati.firstRun()
        kati.tap("open_services")
        kati.compose.waitUntil(20_000) { kati.present("service_name") }
    }

    private fun type(tag: String, text: String) {
        val field = kati.compose.onNodeWithTag(tag, useUnmergedTree = true)
        field.performTextClearance()
        field.performTextInput(text)
        kati.device.waitForIdle()
    }

    @Test
    fun a_a_service_is_added_with_its_price_corrected_and_deleted() {
        open()
        assertTrue("the page says what it is for", ByHand.shown(kati, "The streaming services you have"))
        assertFalse("no invented service", ByHand.shown(kati, "Lumen+"))

        // Add with no name refuses beside the button.
        kati.tap("add_service")
        kati.compose.waitUntil(10_000) { ByHand.shown(kati, "Type the service’s name first.") }

        type("service_name", name)
        type("service_price", "9.99")
        kati.tap("add_service")
        kati.compose.waitUntil(20_000) { column("tier") != null }
        assertEquals("subscribed", column("tier"))
        assertEquals("999", column("monthly_pence"))
        kati.compose.waitUntil(10_000) { ByHand.shown(kati, "Added $name.") }

        // Tapping the row opens its editor under it; Save changes the price in place.
        kati.tap("edit_service_${id()}")
        kati.compose.waitUntil(10_000) { kati.present("delete_service") }
        type("service_price", "12.50")
        kati.tap("add_service")
        kati.compose.waitUntil(20_000) { column("monthly_pence") == "1250" }
        kati.compose.waitUntil(10_000) { ByHand.shown(kati, "Saved $name.") }
        assertEquals("1", kati.scalar("select count(*) from services where name = '$name'"))

        // Delete from the card.
        kati.tap("edit_service_${id()}")
        kati.compose.waitUntil(10_000) { kati.present("delete_service") }
        kati.tap("delete_service")
        kati.compose.waitUntil(20_000) { column("id") == null }
        assertNull(column("id"))
    }

    @Test
    fun b_free_with_ads_has_no_price_and_a_service_goes_to_not_mine_and_back() {
        open()

        kati.tap("kind_free")
        kati.compose.waitUntil(10_000) { !kati.present("service_price") }
        type("service_name", name)
        kati.tap("add_service")
        kati.compose.waitUntil(20_000) { column("tier") == "free_with_ads" }
        assertNull(column("monthly_pence"))

        kati.compose.waitUntil(20_000) { kati.present("drop_service_${id()}") }
        kati.tap("drop_service_${id()}")
        kati.compose.waitUntil(20_000) { column("tier") == "not_mine" }
        kati.compose.waitUntil(20_000) { kati.present("restore_service_${id()}") }

        kati.tap("restore_service_${id()}")
        kati.compose.waitUntil(20_000) { column("tier") == "subscribed" }
    }
}
