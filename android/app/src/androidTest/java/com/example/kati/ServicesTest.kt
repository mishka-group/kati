package com.example.kati

import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performTextInput
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * #95 — a service you name is a service Kati keeps.
 *
 * `Kati.Services.Service` shipped with `create: :*` and no caller anywhere in
 * `lib/`, so screen 92's "add a service Kati has never heard of" row drew,
 * answered a tap, and wrote nothing. On a fresh install the screen redraws its
 * sample either way, so a lost write and a completed one are pixel-identical —
 * which is why every assertion here that matters is a row count read out of
 * `kati.db` rather than anything read off the screen.
 *
 * The journey is the real one: the home shell's own Services card, not the
 * gallery. A test that reaches a screen by a route no person uses proves the
 * screen works and leaves the route untested.
 */
@RunWith(AndroidJUnit4::class)
class ServicesTest {

    @get:Rule
    val kati = KatiRule()

    /** Unique per run, so a row left by a previous run cannot pass this. */
    private val name = "kati-e2e-${System.currentTimeMillis()}"

    private fun textPresent(text: String): Boolean =
        kati.compose
            .onAllNodesWithText(text, substring = true, useUnmergedTree = true)
            .fetchSemanticsNodes()
            .isNotEmpty()

    @Test
    fun a_a_named_service_reaches_the_database() {
        assertTrue(
            "less than 200MB free on /data — a failed install would present as a failed test",
            kati.freeMegabytes() > 200
        )

        kati.launch()
        kati.firstRun()

        // The receipt's baseline. Without it, a store that already held rows
        // would make the assertion below pass on someone else's data.
        val before = kati.count("services")

        kati.tap("open_services")
        kati.compose.waitUntil(20_000) { kati.present("service_query") }

        // #95's fix, on the device. Save with nothing typed refuses in words:
        // this is the app admitting a failure it used to swallow.
        kati.tap("add_service")
        kati.device.waitForIdle()
        kati.compose.waitUntil(10_000) { textPresent("Nothing to save yet") }

        // Not decoration, and not the row count. A tap that never reaches the
        // BEAM at all ALSO leaves the count unchanged, so asserting the count
        // here would pass without a single message crossing the bridge — the
        // same vacuous shape this whole ticket is about. The refusal sentence
        // can only appear if `handle_tap(:add_service, _)` actually ran.
        assertTrue(
            "Save with an empty field showed no refusal, so the tap never reached the " +
                "BEAM — nothing below this line would mean anything",
            textPresent("Nothing to save yet")
        )

        assertEquals("an empty save wrote a row", before, kati.count("services"))

        // The bug the review caught: the refusal outlived the field it was
        // about. Typing a name left "Nothing to save yet." sitting under a
        // field that now held one, because the change handler assigned :query
        // without clearing :save_error.
        kati.compose.onNodeWithTag("service_query", useUnmergedTree = true)
            .performTextInput(name)
        kati.device.waitForIdle()

        val fieldHolds = kati.textOf("service_query")

        kati.tap("add_service")
        kati.device.waitForIdle()
        try {
            kati.compose.waitUntil(20_000) { kati.count("services") > before }
        } catch (_: Throwable) {
            // Swallowed on purpose: the assertion below says far more than a
            // bare timeout does, and a timeout here IS the failure.
        }

        val addStillThere = kati.present("add_service")
        val rows = kati.count("services")
        // A successful save assigns :query to "" — so a cleared field is the
        // BEAM telling us it took the {:ok, _} branch and wrote nothing.
        val fieldAfter = kati.textOf("service_query")

        // THE discriminator. `localValue` in MobTextField is Compose-local, so
        // text on screen proves only that Compose has it — never that the BEAM
        // does. The two failures are told apart by which sentence the screen
        // shows: "Nothing to save yet." means `assigns[:query]` was empty when
        // Save ran, so the change never crossed the bridge; the generic
        // "did not save" sentence means it crossed and the write itself failed.
        val saysNothingToSave = textPresent("Nothing to save yet")
        val saysDidNotSave = textPresent("did not save")

        assertEquals(
            "the name was typed and Save was tapped, but no row arrived. " +
                "field held: [" + fieldHolds + "] typed: [" + name + "] " +
                "add_service present: " + addStillThere + " / rows: " + rows +
                " / says-nothing-to-save: " + saysNothingToSave +
                " / says-did-not-save: " + saysDidNotSave +
                " / field after save: [" + fieldAfter + "]",
            before + 1,
            rows
        )

        assertEquals(
            "a row arrived but under the wrong name, so the write did not carry what " +
                "was typed",
            name,
            kati.scalar("select name from services where name = '$name'")
        )

        // Same name again. `save_service/1` answers {:ok, existing} rather than
        // writing a second row, and the count is the only place that shows.
        kati.tap("add_service")
        kati.device.waitForIdle()
        kati.compose.waitUntil(5_000) { true }

        assertEquals(
            "the same name was saved twice and made two rows",
            before + 1,
            kati.count("services")
        )
    }
}
