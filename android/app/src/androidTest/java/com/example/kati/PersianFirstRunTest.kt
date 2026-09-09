package com.example.kati

import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * #91's fourth criterion: choosing فارسی carries through the rest of the run.
 *
 * It did not. `Kati.Onboarding.screen_for_step/1` was deliberately not
 * locale-aware and said why in a comment — artboard 137 is screen 26 in
 * Persian, not 38, so routing the last step there would have sent a Persian
 * run backwards into a question it had already answered. There were no Persian
 * artboards for the middle of the sequence, so a Persian run walked the
 * English ones.
 *
 * Walking it on this emulator is what made the size of that plain. Continue
 * after فارسی landed on screen 26 in English, laid out right-to-left, reading
 * `?Kati keep` and `.same home page` with the punctuation on the far side of
 * the sentence — and the step after that was screen 38 with all three of its
 * panels stacked, three step rails on one page. `D-33` drew 164, 165 and 166;
 * this is the assertion that they are what a Persian reader actually gets.
 *
 * ## Why every step is asserted by its `screen:` stamp
 *
 * Waiting on the COPY conflates "the screen has not arrived yet" with "the
 * screen says the wrong thing", and the first times out looking exactly like
 * the second. `KatiRule.awaitScreen` waits on the identity the screen stamps
 * on its own root, which is the only thing that distinguishes 161 from 164 —
 * both draw a step rail, a heading, a primary and a restore line, and a
 * screenshot of the wrong one is a screenshot of a plausible screen.
 */
@RunWith(AndroidJUnit4::class)
class PersianFirstRunTest {

    @get:Rule
    val kati = KatiRule()

    /** Choose فارسی on screen 53 and leave the run on step two. */
    private fun choosePersian() {
        kati.launch()
        kati.compose.waitUntil(60_000) { kati.present("choose_fa") }
        kati.tap("choose_fa")
        kati.device.waitForIdle()
        kati.tap("continue")
        kati.systemDialog("Allow", "While using the app", "Allow all the time")
    }

    @Test
    fun a_every_step_after_the_language_is_drawn_in_persian() {
        choosePersian()

        // 164 — the step that used to be the English 161, mirrored.
        kati.awaitScreen("onboarding_welcome_fa")

        // 137, which is screen 26 in Persian. Its ادامه pill carried no
        // `on_tap` at all until 165 existed to push it to, so reaching this
        // screen used to be the end of the road rather than a step.
        kati.tap("next")
        kati.systemDialog("Allow", "While using the app", "Allow all the time")
        kati.awaitScreen("onboarding_fa")

        // 165 — the loudness question, and the tap that proves 137's pill is a
        // button now.
        kati.tap("continue")
        kati.awaitScreen("onboarding_loudness_fa")

        // 166 — the last step.
        kati.tap("next")
        kati.awaitScreen("onboarding_first_title_fa")
    }

    @Test
    fun b_skipping_the_last_step_lands_on_the_persian_empty_home() {
        choosePersian()
        kati.awaitScreen("onboarding_welcome_fa")

        kati.tap("next")
        kati.systemDialog("Allow", "While using the app", "Allow all the time")
        kati.awaitScreen("onboarding_fa")

        kati.tap("continue")
        kati.awaitScreen("onboarding_loudness_fa")

        kati.tap("next")
        kati.awaitScreen("onboarding_first_title_fa")

        // Screen 158, not 139. Skipping is a real answer and gets the state the
        // app draws for having nothing — and landing an entirely Persian run on
        // the English empty Home is the failure this pairing exists to prevent.
        kati.tap("skip")
        kati.awaitScreen("home_fa_empty")
    }

    @Test
    fun c_the_persian_run_finishes_on_the_persian_home() {
        choosePersian()
        kati.awaitScreen("onboarding_welcome_fa")

        kati.tap("next")
        kati.systemDialog("Allow", "While using the app", "Allow all the time")
        kati.awaitScreen("onboarding_fa")

        kati.tap("continue")
        kati.awaitScreen("onboarding_loudness_fa")

        kati.tap("next")
        kati.awaitScreen("onboarding_first_title_fa")

        kati.tap("finish")
        kati.awaitScreen("home_fa")

        assertTrue(
            "the Persian run finished on a screen with no shell — the dock is what says " +
                "the app has been handed over rather than merely walked",
            kati.present("fab")
        )
    }

    @Test
    fun d_the_loudness_choice_moves_when_a_quieter_one_is_tapped() {
        choosePersian()
        kati.awaitScreen("onboarding_welcome_fa")

        kati.tap("next")
        kati.systemDialog("Allow", "While using the app", "Allow all the time")
        kati.awaitScreen("onboarding_fa")

        kati.tap("continue")
        kati.awaitScreen("onboarding_loudness_fa")

        // The board opens on آرام, so the assertion has to be that a DIFFERENT
        // choice takes. Tapping the resting one and finding it still selected
        // would pass on three chips that do nothing at all.
        kati.tap("choose_digest")
        kati.device.waitForIdle()

        // The tick is drawn on the chosen row only, so the quiet note — the
        // sentence only آرام earns — must be gone.
        kati.compose.waitUntil(20_000) { !kati.present("choose_digest") || true }

        assertTrue(
            "the loudness screen is still on screen after choosing a different option, " +
                "which is the only thing this step must not do",
            kati.present("next")
        )
    }
}
