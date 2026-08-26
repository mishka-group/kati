package com.example.kati

import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * #96 — Kati survives its Activity being recreated.
 *
 * `onCreate` runs again whenever Android recreates the Activity inside a live
 * process, and the vendored `MainActivity` started a second `beam-main` thread
 * every time. Two BEAMs in one process take SIGABRT — no Elixir exception,
 * because it is not an Elixir error — and the process dies with a
 * `crash_dump helper` message naming nothing useful.
 *
 * `android:configChanges` absorbs rotation, `fontScale` and `uiMode`, which is
 * why ordinary use never showed this. It does **not** absorb Android restoring
 * a task from recents, a locale change, or any recreation the manifest does not
 * list — each a real thing that happens to a real phone.
 *
 * This is the test that found it: two launches in one process. Before
 * `K-38 one-beam-per-process` the second one killed the process.
 */
@RunWith(AndroidJUnit4::class)
class RecreateTest {

    @get:Rule
    val kati = KatiRule()

    @Test
    fun a_a_second_launch_in_one_process_does_not_kill_it() {
        kati.launch()
        kati.compose.waitUntil(60_000) { kati.present("choose_en") }

        assertTrue("the app did not draw on its first launch", kati.present("continue"))

        // The whole point. Before the guard, this line took the process with it.
        kati.launch()

        kati.compose.waitUntil(60_000) { kati.present("choose_en") }

        assertTrue(
            "the app did not draw after its Activity was recreated — if this run ended in " +
                "SIGABRT rather than a failed assertion, the guard is gone",
            kati.present("continue")
        )

        // Still usable, not merely alive: a control that responds proves the
        // re-attached Activity is wired to the running BEAM, which is what
        // `nativeSetActivity` outside the guard is for.
        kati.tap("continue")
        kati.compose.waitUntil(20_000) { !kati.present("choose_en") }

        assertTrue(
            "the app drew after recreation but no longer answered a tap, so the new " +
                "Activity is not attached to the BEAM that is running",
            !kati.present("choose_en")
        )
    }
}
