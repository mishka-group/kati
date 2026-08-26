package com.example.kati

import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performTextInput
import androidx.test.ext.junit.runners.AndroidJUnit4
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
}
