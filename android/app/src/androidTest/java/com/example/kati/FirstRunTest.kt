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
 * #91 — a clean install hands over an app you can use.
 *
 * The ticket exists because of one sentence from the person whose app this is,
 * after installing it on his own phone: *"you all show dummy data and it is not
 * connected to database"*. That was literally true. Every root screen answered
 * an empty store with a Sample module, so the first thing anybody saw on a new
 * phone was nine films they had never added, drawn in the shape and colour of
 * their own shelf.
 *
 * These assertions are therefore two-sided everywhere it matters: the empty
 * state's own words must be PRESENT **and** the invented content must be
 * ABSENT. Checking only the first would pass on a screen still full of samples
 * sitting under a new heading.
 *
 * ## What this file cannot test, and where that is covered
 *
 * "The run resumes at the step it was killed on" wants a dead process. An
 * instrumentation test shares the app's process, so `am force-stop` would take
 * the test with it. What is asserted here is the reachable half — the run does
 * not restart from the beginning when the Activity is recreated. The other
 * half, that `Mob.State` carries the step across a real restart, is asserted
 * on the host in `test/kati/onboarding_resume_test.exs`.
 */
@RunWith(AndroidJUnit4::class)
class FirstRunTest {

    @get:Rule
    val kati = KatiRule()

    private fun textPresent(text: String): Boolean =
        kati.compose
            .onAllNodesWithText(text, substring = true, useUnmergedTree = true)
            .fetchSemanticsNodes()
            .isNotEmpty()

    /** Every invented title `Kati.Library.Sample` holds. None may reach a screen. */
    private val invented = listOf("The Long Hollow", "Salt & Iron", "Blue Hour", "Ashfall")

    private fun assertNothingInvented(where: String) {
        for (title in invented) {
            assertTrue(
                "$where drew \"$title\" — a film out of Kati.Library.Sample that nobody " +
                    "added. This is the defect #91 reports, back again.",
                !textPresent(title)
            )
        }
    }

    @Test
    fun a_a_clean_install_hands_over_a_usable_app() {
        assertTrue(
            "less than 200MB free on /data — a failed install would present as a failed test",
            kati.freeMegabytes() > 200
        )

        kati.launch()
        kati.firstRun()

        // The receipt for "usable": not that a screen drew, but that the app
        // took something and kept it. A shelf is the app's own subject.
        val before = kati.count("tracked_titles")

        kati.tap("root_library")
        kati.compose.waitUntil(20_000) { textPresent("No titles yet") }

        assertNothingInvented("the Library, straight after the first run,")

        kati.tap("add_title")
        kati.compose.waitUntil(20_000) { kati.present("title_query") }

        val title = "kati-e2e-${System.currentTimeMillis()}"
        kati.compose.onNodeWithTag("title_query", useUnmergedTree = true)
            .performTextInput(title)
        kati.device.waitForIdle()

        // The add control on the first result row carries the title in its tag —
        // the shape `Kati.Screens.AddTitle` already used before this ticket.
        val added = kati.tapAny("add_$title", "add_result_0", "save", "add")

        assertTrue(
            "nothing on the results list offered a way to add \"$title\", so the first " +
                "run hands over an app that cannot take its first title",
            added != null
        )

        kati.compose.waitUntil(20_000) { kati.count("tracked_titles") > before }

        assertEquals(
            "the first run completed but the app could not keep a title — that is not a " +
                "usable app, it is a walkthrough",
            before + 1,
            kati.count("tracked_titles")
        )
    }

    @Test
    fun b_every_root_draws_its_own_emptiness() {
        kati.launch()
        kati.firstRun()

        // Library — screen 27's card: glyph tile, sentence, one ink action.
        kati.tap("root_library")
        kati.compose.waitUntil(20_000) { textPresent("No titles yet") }
        assertNothingInvented("the Library")

        // Stats — a year counted from nothing is not a year of zeroes.
        kati.tap("root_stats")
        kati.compose.waitUntil(20_000) { textPresent("Not much to show yet") }
        assertNothingInvented("Stats")

        // Calendar — the two states are DIFFERENT facts and a person has to be
        // able to tell them apart: nothing on today, versus Kati not being
        // allowed to look. The permission is not granted in this run, so it is
        // the second one that must be drawn. Accepting either would let a
        // permission failure hide behind a normal-looking empty day.
        kati.tap("root_calendar")
        kati.compose.waitUntil(20_000) {
            textPresent("Kati cannot see your calendar") || textPresent("Nothing scheduled")
        }

        assertTrue(
            "the Calendar said \"Nothing scheduled\" while Kati had never been allowed to " +
                "read the calendar — that reports an empty day for a permission problem",
            textPresent("Kati cannot see your calendar")
        )

        kati.tap("root_home")
        kati.device.waitForIdle()
        assertNothingInvented("Home")
    }

    @Test
    fun c_the_run_does_not_restart_from_the_beginning() {
        kati.launch()
        kati.compose.waitUntil(60_000) { kati.present("choose_en") }

        // Answer step one and move on, so there is something to lose.
        kati.tap("continue")
        kati.compose.waitUntil(20_000) { !kati.present("choose_en") }
        kati.systemDialog("Allow", "While using the app", "Allow all the time")

        // Recreating the Activity re-reads `Kati.Onboarding.first_screen/0`,
        // which is the decision this ticket changed.
        kati.launch()
        kati.device.waitForIdle()
        kati.compose.waitUntil(30_000) { !kati.present("choose_en") || kati.present("fab") }

        assertTrue(
            "the run reopened on the language step and asked a question already " +
                "answered — the first thing this person told Kati did not count",
            !kati.present("choose_en")
        )
    }

    @Test
    fun d_a_backup_can_be_restored_during_the_first_run() {
        kati.launch()
        kati.compose.waitUntil(60_000) { kati.present("choose_en") }

        kati.tap("continue")
        kati.compose.waitUntil(20_000) { !kati.present("choose_en") }
        kati.systemDialog("Allow", "While using the app", "Allow all the time")

        // A person moving to a second phone should not have to walk a setup
        // that builds a fresh library when they already have one.
        kati.compose.waitUntil(20_000) {
            kati.present("restore") || kati.present("restore_backup") || textPresent("restore")
        }

        assertTrue(
            "nothing during the first run offers a restore, so a person with a backup " +
                "has to finish a setup they did not want before they can use it",
            kati.present("restore") || kati.present("restore_backup") || textPresent("restore")
        )
    }
}
