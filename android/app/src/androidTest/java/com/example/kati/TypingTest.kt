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
 * #83 — the app can be typed into.
 *
 * Nine screens carried a comment saying Mob has no text input, and every search
 * box and amount field in the app was drawn because of it: a `<Text>` beside a
 * 2×19 orange `<Box>` shaped like a caret. The claim was never true —
 * `<TextField>` is in the pinned Mob and `Kati.Screens.Backup` has used it for
 * the passphrase all along.
 *
 * A host test cannot settle this. It can assert a `<TextField>` node is in the
 * tree, which is the same category of claim as asserting a `<Text>` node is:
 * present, and not necessarily connected to anything. Only a device can raise
 * a keyboard, put characters through it, and show them coming back.
 */
@RunWith(AndroidJUnit4::class)
class TypingTest {

    @get:Rule
    val kati = KatiRule()

    /**
     * Type into the Add-a-title field and see it hold what was typed.
     *
     * Reached through the FAB, which is how a person reaches it — screen 06's
     * own note calls it "one sheet reached from the + button". Not through the
     * developer gallery: a journey that only works from a surface #94 deletes
     * is not a journey.
     */
    @Test
    fun a_a_field_holds_what_you_type() {
        assertTrue("less than 200MB free on /data", kati.freeMegabytes() > 200)

        kati.launch()

        // Out of the first run and into the app proper. A fresh install always
        // starts at the language step, so every journey that is not about
        // onboarding has to walk it first.
        kati.firstRun()

        kati.compose.waitUntil(30_000) { kati.present("fab") }
        kati.tap("fab")

        kati.compose.waitUntil(20_000) { kati.present("title_query") }

        val typed = "the long hollow"
        kati.compose.onNodeWithTag("title_query", useUnmergedTree = true)
            .performTextInput(typed)

        // The field must show what went into it. Before this ticket the field
        // was a picture and this input had nowhere to land at all.
        kati.compose.waitUntil(10_000) { kati.textOf("title_query")?.contains(typed) == true }

        assertTrue(
            "the field did not hold what was typed — it read " +
                "'${kati.textOf("title_query")}'",
            kati.textOf("title_query")?.contains(typed) == true
        )
    }

    /**
     * #87 — a title added by hand is still there after the BEAM dies.
     *
     * Issue #60 decided v1 ships film and TV, and film and TV was the one
     * domain with no write path at all: nine screens queried `Kati.Media`
     * correctly and every one queried a table that could not hold a row.
     * Adding a title toggled a boolean on a socket and the row died with the
     * screen.
     *
     * Asserted against `kati.db`, never the screen — a shelf redrawing its
     * Sample module looks exactly like a shelf redrawing a row.
     */
    @Test
    fun b_a_title_added_by_hand_reaches_the_store() {
        kati.launch()
        kati.firstRun()

        assertEquals("titles were tracked before anything was added", 0L, kati.count("tracked_titles"))

        kati.compose.waitUntil(30_000) { kati.present("fab") }
        kati.tap("fab")
        kati.compose.waitUntil(20_000) { kati.present("title_query") }

        // The add control on the first result row. Its tag carries the title,
        // because the chips renumber the list and `add_1` would mean a
        // different film under a different filter.
        val added = kati.tapAny(
            "add_The Quiet Coast",
            "add_Quiet Earth"
        )
        assertTrue("no add control on any result row", added != null)

        kati.compose.waitUntil(20_000) { kati.count("tracked_titles") > 0 }

        assertEquals(
            "adding a title wrote no tracked row — the film and TV spine still cannot hold one",
            1L,
            kati.count("tracked_titles")
        )
        assertEquals(
            "no cached row for the title that was added",
            1L,
            kati.count("cached_titles")
        )
        assertEquals(
            "a hand-typed title claimed a provider it does not have",
            "manual",
            kati.scalar("select source from tracked_titles limit 1")
        )
    }
}
