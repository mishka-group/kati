package com.example.kati

import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performTextInput
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * #91 — the escape hatch is a control, and it puts a real row in the library.
 *
 * Screen 89 has drawn "Can't find it? Add it by hand" since it was written and
 * rendered it with **no `on_tap` at all**, because no board drew what it would
 * open. Board 154 is that form. Until the catalogue lands, everything a search
 * finds is invented — so this is the only path from a fresh install to a
 * library with anything in it, and a journey nobody can walk is not a path.
 *
 * Asserted against `kati.db`, never the screen. A form redrawing what was typed
 * is indistinguishable from a form that wrote it.
 */
@RunWith(AndroidJUnit4::class)
class AddByHandTest {

    @get:Rule
    val kati = KatiRule()

    @Test
    fun a_a_title_typed_by_hand_reaches_the_library() {
        assertTrue("less than 200MB free on /data", kati.freeMegabytes() > 200)

        kati.launch()
        kati.firstRun()

        // The receipt's baseline. Without it a store that already held rows
        // would make the assertion below pass on somebody else's data.
        val before = kati.count("tracked_titles")

        // Reached the way a person reaches it: the + button opens screen 89,
        // and the row under its results opens 154. Not through the developer
        // gallery, which #94 deletes.
        kati.compose.waitUntil(30_000) { kati.present("fab") }
        kati.tap("fab")

        kati.compose.waitUntil(20_000) { kati.present("add_by_hand") }
        kati.tap("add_by_hand")

        kati.compose.waitUntil(20_000) { kati.present("title") }

        val typed = "the salt almanac"
        kati.compose.onNodeWithTag("title", useUnmergedTree = true).performTextInput(typed)
        kati.compose.waitUntil(10_000) { kati.textOf("title")?.contains(typed) == true }

        kati.tap("add")

        // The store, not the screen. `source_id` is the typed title for a
        // manual row, which is the shape Kati.Screens.AddByHand.save/1 writes.
        kati.compose.waitUntil(20_000) { kati.count("tracked_titles") == before + 1L }

        assertEquals(
            "adding by hand did not write a tracked_titles row",
            before + 1L,
            kati.count("tracked_titles")
        )
    }

    /**
     * The save that refuses.
     *
     * Pressing Add with nothing typed writes nothing and says so. The contract
     * is `Kati.Write`'s and `Kati.WriteContractTest` holds it on the host; what
     * a device adds is that the sheet stays open with a message rather than
     * closing over a row that was never written.
     */
    @Test
    fun b_saving_with_no_title_writes_nothing() {
        kati.launch()
        kati.firstRun()

        val before = kati.count("tracked_titles")

        kati.compose.waitUntil(30_000) { kati.present("fab") }
        kati.tap("fab")
        kati.compose.waitUntil(20_000) { kati.present("add_by_hand") }
        kati.tap("add_by_hand")
        kati.compose.waitUntil(20_000) { kati.present("add") }

        kati.tap("add")

        // Still on the form, and nothing written. A screen that popped here
        // would be the app reporting a success it did not have.
        kati.compose.waitUntil(10_000) { kati.present("title") }

        assertEquals(
            "an empty save wrote a row",
            before,
            kati.count("tracked_titles")
        )
    }
}
