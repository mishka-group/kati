package com.example.kati

import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performTextClearance
import androidx.compose.ui.test.performTextInput
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNotNull
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * MOVIES-AND-TV.md #99 — screen 35 writes, and what it writes survives.
 *
 * The three Status tiles and the four Season-pass switches sit over columns
 * `Kati.Media.TrackedTitle` has carried since it was written and that had no
 * reader and no writer anywhere in the app. `Kati.Screens.Gallery`'s `@routed`
 * list carries the claim this file exists to stop being a claim: *"Walked on
 * the device: all three Status tiles and all four season-pass switches write,
 * and the values survive a back-and-return."* A walk somebody did once is not
 * a thing that keeps being true.
 *
 * ## Every assertion here is a row, and it has to be
 *
 * Screen 35 has two faces. Over a show it does not have, it draws
 * `Kati.Screens.SeriesSettings.Sample` — the same tiles, the same four
 * switches, the same words — and `status_tap/1` answers `nil` so nothing is
 * even tappable. Over a real show it draws the reader's own row. The two are
 * pixel-identical apart from which tile is lit, so a tile that lights on tap
 * and writes nothing looks exactly like one that works. `KatiRule.scalar`
 * reads `kati.db` directly, which is the only place the difference shows.
 *
 * ## The route is the one a person walks
 *
 * Library grid tile → screen 04 → the `⋯` disc → *Show settings*. Not the
 * gallery: screen 35 was on `@routed` precisely because the menu is the door,
 * and a test that pushed the screen directly would prove the page works and
 * leave the door untested. The `⋯` panel is `Kati.Components.Anchored`
 * (K-18), its first use in Kati, and is exactly the kind of thing the host
 * suite cannot see at all.
 *
 * ## Why a series added BY HAND
 *
 * Nothing here needs a cache row, a poster or an air date — a status and four
 * booleans are columns on the tracked row itself. Adding by hand keeps the
 * test off the network, which matters: `Kati.Media.Tmdb.key/0` answers
 * `{:error, :no_api_key}` on a device nobody has given a token to, so a
 * journey through the catalogue would fail for a reason that has nothing to do
 * with screen 35.
 */
@RunWith(AndroidJUnit4::class)
class SeriesSettingsTest {

    @get:Rule
    val kati = KatiRule()

    /** Unique per run, so a row left by an earlier run cannot answer for this one. */
    private val title = "Estuary Nights ${System.currentTimeMillis()}"

    /**
     * The row the page under test is about.
     *
     * Read by `source_id` rather than picked off the shelf, and the difference
     * is a real one: step 5 of the first run shelves a series of its own
     * (`Kati.Screens.OnboardingFirstTitle.shelve/1` writes `kind: :tv`), so the
     * shelf already holds one before this test adds anything. Taking the first
     * tile would read a row the screen is not editing, and every assertion
     * below would then be about the wrong show while looking exactly right.
     *
     * `Kati.Screens.AddByHand.save/1` writes the typed title as `source_id`,
     * which is what makes the lookup exact.
     */
    private var trackedId = ""

    private fun statusInDb(): String? =
        kati.scalar("select status from tracked_titles where id = '$trackedId'")

    private fun passInDb(column: String): String? =
        kati.scalar("select $column from tracked_titles where id = '$trackedId'")

    /**
     * Adds one series through the form a person would use, and comes back to a
     * root.
     *
     * `kind_Series` and not the default: `Kati.Screens.AddByHand`'s default is
     * Film, and a film tile is tagged `open_film_…` and opens screen 08. The
     * whole journey below is about screen 04.
     *
     * The by-hand form writes `source_id` from the title, which is what makes
     * the queries above address this run's row and no other.
     */
    private fun addSeriesByHand() {
        val before = kati.count("tracked_titles")

        // The dock's `+`, not the empty shelf's `Add a title` pill: that pill
        // is on `Kati.Screens.Library.empty_state/0` and is drawn only while
        // the shelf is empty, which it is not after the first run shelves its
        // own series. The FAB is on every root in both states.
        kati.tap("root_home")
        kati.awaitScreen("home")
        kati.tap("fab")
        kati.awaitScreen("add_title")

        // Screen 06's by-hand row is `Add "<what you typed>" by hand`, and
        // `Kati.Screens.AddTitle.by_hand_label/1` answers `nil` for an empty
        // field — there is no row until something is in it. The search this
        // typing starts is expected to come back empty: `Kati.Media.Tmdb.key/0`
        // answers `{:error, :no_api_key}` on a device nobody has given a token
        // to, which is the state this test wants and the reason it adds by hand.
        kati.compose.onNodeWithTag("title_query", useUnmergedTree = true)
            .performTextInput(title)
        kati.device.waitForIdle()

        kati.compose.waitUntil(20_000) { kati.present("add_by_hand") }
        kati.tap("add_by_hand")
        kati.awaitScreen("add_by_hand")

        // `kind_Series` and not the default: `Kati.Screens.AddByHand` opens on
        // Film, and a film lands on screen 08 rather than on screen 04.
        kati.tap("kind_Series")
        kati.device.waitForIdle()

        kati.compose.onNodeWithTag("title", useUnmergedTree = true).performTextClearance()
        kati.compose.onNodeWithTag("title", useUnmergedTree = true).performTextInput(title)
        kati.device.waitForIdle()

        kati.tap("add")
        kati.compose.waitUntil(20_000) { kati.count("tracked_titles") > before }

        trackedId =
            kati.scalar("select id from tracked_titles where source_id = '$title'") ?: ""
        assertNotNull("the save reported a row but none carries the typed title", trackedId)

        // No `popToRoot` here, and that is not an omission. `save/1` ends in
        // `Mob.Socket.reset_to(detail_screen(tracked), …)` — board 155's *Add
        // to library goes to the new title's detail screen* — so the stack is
        // REPLACED rather than pushed onto, and pressing back looks for a root
        // that is no longer underneath. The app is already on screen 04, which
        // is where this test wanted to be.
        kati.awaitScreen("series")
    }

    /** Screen 04's `⋯` disc → *Show settings*. The door screen 35 was on `@routed` for. */
    private fun openShowSettings() {
        // The panel is drawn only after this tap; before it, `open_settings`
        // is in no tree and `present` is correctly false.
        kati.tap("toggle_menu")
        kati.compose.waitUntil(20_000) { kati.present("open_settings") }
        kati.tap("open_settings")
        kati.awaitScreen("series_settings")
    }

    @Test
    fun a_a_status_tile_writes_and_the_value_survives_a_back_and_return() {
        kati.launch()
        kati.firstRun()
        addSeriesByHand()
        openShowSettings()

        // Read, and only checked for the one thing the tap below needs: that it
        // is not already the value being written. Pinning the default would
        // make this test fail for a change in `Kati.Screens.AddByHand`'s Status
        // selector rather than for the thing it is about — the by-hand form
        // opens on *Not started*, which the first version of this file
        // confidently asserted was *Watching*.
        val before = statusInDb()
        assertNotNull("no tracked row for the title just added", before)
        assertNotEquals(
            "the show is already paused, so the tap below would prove nothing",
            "paused",
            before
        )

        kati.tap("status_Paused")
        try {
            kati.compose.waitUntil(20_000) { statusInDb() == "paused" }
        } catch (_: Throwable) {
            // The assertion below says more than the timeout does.
        }

        assertEquals(
            "the Paused tile was tapped and the row still says [" + statusInDb() + "] — " +
                "screen 35's tiles are drawn over Kati.Media.TrackedTitle.status and this " +
                "is the only place a write shows",
            "paused",
            statusInDb()
        )

        // The half a single tap cannot prove. `write/2` assigns the updated
        // struct into the socket, so a screen that never wrote and a screen
        // that wrote both look right until the socket is thrown away — which
        // is what a pop does.
        kati.device.pressBack()
        kati.device.waitForIdle()
        kati.awaitScreen("series")
        openShowSettings()

        assertEquals(
            "the status did not survive leaving the page and coming back",
            "paused",
            statusInDb()
        )

        // And the tile is not one-way. `status_tap/1` keeps the tap on the lit
        // tile on purpose — pressing the one you are on is how you check you
        // are on it — so this also proves that is not a no-op for the other two.
        kati.tap("status_Watching")
        try {
            kati.compose.waitUntil(20_000) { statusInDb() == "watching" }
        } catch (_: Throwable) {
        }

        assertEquals(
            "Paused wrote but Watching did not, so only one of the three tiles is live",
            "watching",
            statusInDb()
        )
    }

    @Test
    fun b_every_season_pass_switch_writes_its_own_column() {
        kati.launch()
        kati.firstRun()
        addSeriesByHand()
        openShowSettings()

        // All four, because the tap tag is BUILT from the column name
        // (`"pass_" <> Atom.to_string(field)`) and `change_for/2` looks it up
        // in `@pass_columns`. A typo in one of the four is a tag that matches
        // no column, `change_for/2` answers `:error`, and `write/2` returns the
        // socket unchanged — silently. Only a per-column read finds that.
        val columns = listOf(
            "auto_add_new_seasons",
            "notify_new_episodes",
            "add_air_dates_to_calendar",
            "hide_unwatched_titles"
        )

        for (column in columns) {
            val before = passInDb(column)
            assertNotNull("no row to read $column from", before)

            val want = if (before == "1") "0" else "1"

            kati.tap("pass_$column")
            try {
                kati.compose.waitUntil(20_000) { passInDb(column) == want }
            } catch (_: Throwable) {
            }

            assertEquals(
                "the $column switch was tapped and the column still reads [" +
                    passInDb(column) + "] — it was [" + before + "] before the tap",
                want,
                passInDb(column)
            )
        }

        // Leave and come back: four values written into one row, all of which
        // must still be there. A `for_update` that dropped the other three
        // would pass every assertion above and fail here.
        val after = columns.map { passInDb(it) }

        kati.device.pressBack()
        kati.device.waitForIdle()
        kati.awaitScreen("series")
        openShowSettings()

        assertEquals(
            "one of the four switches did not survive leaving the page and coming back",
            after,
            columns.map { passInDb(it) }
        )
    }
}
