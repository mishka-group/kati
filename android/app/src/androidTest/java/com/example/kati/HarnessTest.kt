package com.example.kati

import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.Assert.assertTrue

/**
 * The harness proving itself.
 *
 * Every claim here is one the 1794 host tests cannot make. They render a
 * screen's tree in a GenServer on a laptop; this launches the shipped APK on a
 * phone, finds a control by the name Elixir gave it, presses it, and reads the
 * store back off the filesystem.
 *
 * If this class is red, no other e2e in the repo means anything.
 */
@RunWith(AndroidJUnit4::class)
class HarnessTest {

    @get:Rule
    val kati = KatiRule()

    /**
     * The BEAM boots from the runtime inside this APK, and it draws.
     *
     * A fresh install lands on the first-run language step, not on the shell —
     * which is the first thing this harness established that no host test
     * could, because a host test mounts whichever screen it names.
     *
     * `choose_en` and `continue` are not tags invented for testing.
     * `Kati.Screens.LanguagePick` has drawn them all along; they simply had no
     * route to Compose until `K-35 test-tag`, which is the whole claim of that
     * fence and is what this asserts.
     */
    @Test
    fun a_boots_and_names_its_controls() {
        kati.launch()

        kati.compose.waitUntil(60_000) { kati.present("choose_en") }

        assertTrue("the language step drew no English option", kati.present("choose_en"))
        assertTrue("the language step drew no Persian option", kati.present("choose_fa"))
        assertTrue("the language step drew no Continue", kati.present("continue"))
    }

    /**
     * A control responds to a real press, and the app moves.
     *
     * Asserts the step it LEAVES is gone rather than that something is still on
     * screen: Kati's chrome persists across a push, so "a node still exists" is
     * satisfied by an app that did nothing at all.
     */
    @Test
    fun b_a_tap_moves_the_app() {
        kati.launch()
        kati.compose.waitUntil(60_000) { kati.present("choose_en") }

        kati.tap("continue")

        kati.compose.waitUntil(20_000) { !kati.present("choose_en") }
        assertTrue("Continue left the language step on screen", !kati.present("choose_en"))
    }

    /**
     * The store is on the device and readable.
     *
     * This is the receipt every state-changing e2e will use. It asserts the
     * schema is really there — `schema_migrations` is written by
     * `Ecto.Migrator` at boot (`lib/kati/app.ex:99`) — rather than that some
     * screen drew a number, because a screen redrawing a Sample module is
     * indistinguishable from one redrawing a row.
     */
    @Test
    fun c_the_store_exists_and_can_be_read() {
        kati.launch()
        kati.compose.waitUntil(60_000) { kati.present("choose_en") }

        assertTrue("no kati.db on the device after boot", kati.dbExists())
        assertTrue(
            "kati.db carries no migrations — the schema on the phone is not the schema in the repo",
            kati.count("schema_migrations") > 0
        )
    }
}
