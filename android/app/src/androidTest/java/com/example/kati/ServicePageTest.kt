package com.example.kati

import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performTextClearance
import androidx.compose.ui.test.performTextInput
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * One service's page, reached the way a person reaches it — My services, the
 * Money row, the service's row on Subscriptions — and every control on it:
 * the price changed under its row, the renewal day picked from the grid, and
 * a title from the library placed on the service. Every step ends in kati.db.
 */
@RunWith(AndroidJUnit4::class)
class ServicePageTest {

    @get:Rule
    val kati = KatiRule()

    private val stamp = System.currentTimeMillis()
    private val name = "kati-page-$stamp"
    private val show = "Page Show $stamp"

    private fun column(column: String): String? =
        kati.scalar("select $column from services where name = '$name'")

    private fun type(tag: String, text: String) {
        val field = kati.compose.onNodeWithTag(tag, useUnmergedTree = true)
        field.performTextClearance()
        field.performTextInput(text)
        kati.device.waitForIdle()
    }

    @Test
    fun a_price_renewal_day_and_a_title_watched_here_are_all_set_on_the_page() {
        kati.launch()
        kati.firstRun()
        ByHand.add(kati, show, "kind_tv")
        val showId = kati.scalar("select id from tracked_titles where source_id = '$show'") ?: ""
        ByHand.toTabs(kati)
        kati.tap("root_home")
        kati.awaitScreen("home")

        kati.tap("open_services")
        kati.compose.waitUntil(20_000) { kati.present("service_name") }
        type("service_name", name)
        type("service_price", "9.99")
        kati.tap("add_service")
        kati.compose.waitUntil(20_000) { column("monthly_pence") == "999" }
        kati.compose.waitUntil(10_000) { ByHand.shown(kati, "Added $name.") }

        kati.tap("open_subscriptions")
        val row = "open_service_" + name.replace(" ", "_")
        kati.compose.waitUntil(20_000) { kati.present(row) }
        kati.tap(row)
        kati.compose.waitUntil(20_000) { kati.present("edit_price") }

        // The price, changed under its own row.
        kati.tap("edit_price")
        kati.compose.waitUntil(10_000) { kati.present("save_price") }
        type("service_price", "12.50")
        kati.tap("save_price")
        kati.compose.waitUntil(20_000) { column("monthly_pence") == "1250" }
        kati.compose.waitUntil(10_000) { !kati.present("save_price") }

        // The renewal day, picked from the grid.
        kati.tap("pick_day")
        kati.compose.waitUntil(10_000) { kati.present("day_15") }
        kati.tap("day_15")
        kati.compose.waitUntil(20_000) { (column("renews_on") ?: "").endsWith("-15") }
        kati.compose.waitUntil(10_000) { !kati.present("day_15") }

        // A title from the library, placed on this service.
        kati.tap("pick_title")
        kati.compose.waitUntil(10_000) { kati.present("place_$showId") }
        kati.tap("place_$showId")
        kati.compose.waitUntil(20_000) {
            kati.scalar("select watch_on from tracked_titles where id = '$showId'") == name
        }
        kati.compose.waitUntil(10_000) { kati.present("unplace_$showId") }
        assertEquals(name, kati.scalar("select watch_on from tracked_titles where id = '$showId'"))
    }
}
