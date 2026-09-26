package com.example.kati

import android.graphics.Bitmap
import android.util.Log
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.semantics.SemanticsNode
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.semantics.getOrNull
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performImeAction
import androidx.compose.ui.test.performTextClearance
import androidx.compose.ui.test.performTextInput
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Assume.assumeTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File

/**
 * Film, series and anime — the one section Kati is shipping first — walked end
 * to end on a phone, so that *it works* is a run and not a claim.
 *
 * One journey rather than eight tests, because the steps ARE the journey: the
 * film logged in step five is the one added in step three, and the airing the
 * calendar draws in step seven exists only because the series was added. The
 * orchestrator gives each `@Test` a fresh process and `KatiRule` wipes the
 * store, so eight tests would mean eight first runs and eight catalogue
 * round-trips for no extra claim.
 *
 * Every step is named in the failure it raises and logged as it passes
 * (`adb logcat -s FilmSeriesFlow`), and a failing step dumps every tag and
 * string on screen before it throws; a passing step dumps the same at DEBUG.
 * A red run should say which screen was wrong and what it was showing without
 * anybody re-running it by hand.
 *
 * ## The catalogue is real
 *
 * Steps two to eight need TMDB, and no build carries a key: the only one the
 * app sends is the reader's own, saved on screen 80. So step two does what a
 * reader does — pastes a read token into the Data sources field and taps
 * Save. The token reaches this test as the `tmdbToken` instrumentation
 * argument and from nowhere else; it is never written into the source, never
 * logged, and scrubbed from any failure or screen dump:
 *
 * ```
 * mix kati.e2e.stage && cd android && ./gradlew connectedE2eAndroidTest \
 *   -Pandroid.testInstrumentationRunnerArguments.class=com.example.kati.FilmSeriesFlowTest \
 *   -Pandroid.testInstrumentationRunnerArguments.tmdbToken="$(grep -o 'eyJ[^"]*' ~/.config/kati/tmdb.env)"
 * ```
 *
 * Without the argument the TMDB half of this journey is skipped with that
 * assumption named rather than failed — a missing token is a fact about the
 * run, not about the app.
 *
 * The emulator must resolve `api.themoviedb.org` truthfully: the owner's home
 * router sinkholes it, and Kati then says *This network is blocking TMDB*,
 * which this test reports as the step-three failure it is.
 *
 * ## Invented content is asserted absent everywhere
 *
 * Every screen visited is checked for the strings the Sample modules and the
 * boards drew before the screens were wired to the store. The receipt for
 * every state change is still the store, read through `KatiRule`.
 */
@RunWith(AndroidJUnit4::class)
class FilmSeriesFlowTest {

    @get:Rule
    val kati = KatiRule()

    private val context get() = InstrumentationRegistry.getInstrumentation().targetContext

    private val film = "Arrival"
    private val filmYear = "2016"
    private val series = "The Bear"
    private val seriesYear = "2022"

    /** The token this run was given, held only so it can be scrubbed from output. */
    private var secret: String? = null

    private val invented = listOf(
        "Standup", "Plumber", "The Long Hollow", "Ashfall", "Marram",
        "Nightbirds", "Design review", "hollow71", "14 items"
    )

    @Test
    fun a_film_and_a_series_from_first_run_to_calendar() {
        assertTrue(
            "less than 200MB free on /data — a failed install would present as a failed test",
            kati.freeMegabytes() > 200
        )

        kati.launch()

        step(1, "first run to an empty Library") { firstRunToEmptyLibrary() }

        val token = tmdbToken()
        assumeTrue(
            "ASSUMPTION: no TMDB read token was passed to this run, and no build carries " +
                "one. Pass it as the `tmdbToken` instrumentation argument — " +
                "-Pandroid.testInstrumentationRunnerArguments.tmdbToken=\"<read token>\" " +
                "(the class KDoc has the full command). Steps 2–8 need the catalogue " +
                "and are skipped.",
            token != null
        )
        secret = token

        step(2, "the reader's own token saved from Home's TMDB block") { saveOwnToken(token!!) }

        step(3, "add $film and $series from the + button") { addBoth() }
        step(4, "Library shows both, with posters") { libraryShowsBoth() }
        step(5, "log a watch and a rewatch of $film") { logWatchAndRewatch() }
        step(6, "tick an episode of $series") { tickFirstEpisode() }
        step(7, "the June airing on the month grid") { calendarAiring() }
        step(8, "Search finds a title on the shelf") { searchFindsIt() }
    }

    // ── 1 ───────────────────────────────────────────────────────────────────

    private fun firstRunToEmptyLibrary() {
        kati.toSections()
        noInvented("the sections step")
        kati.tap("continue")
        kati.systemDialog("Allow", "While using the app", "Allow all the time")

        kati.awaitScreen("onboarding_loudness")
        kati.tapAny("choose_quiet")
        kati.device.waitForIdle()
        kati.tap("next")

        kati.awaitScreen("onboarding_first_title")
        assertTrue(
            "the first-title step drew no search field — step five is meant to be " +
                "screen 06's search, not a picture of one",
            kati.present("title_query")
        )
        noInvented("the first-title step (the old poster wall)")

        kati.tap("skip")
        kati.awaitScreen("home")
        noInvented("Home after the first run")

        assertEquals(
            "Skip on the first-title step left something on the shelf",
            0L,
            kati.count("tracked_titles")
        )

        kati.tap("root_library")
        kati.awaitScreen("library")
        kati.compose.waitUntil(20_000) { textPresent("No titles yet") }
        noInvented("the empty Library")
    }

    // ── 2 ───────────────────────────────────────────────────────────────────

    /**
     * The `tmdbToken` instrumentation argument, or null when the run was given
     * none. Read from the arguments only — never from a file on the device.
     */
    private fun tmdbToken(): String? =
        InstrumentationRegistry.getArguments().getString("tmdbToken")
            ?.trim()
            ?.takeIf { it.isNotEmpty() }

    /**
     * Pastes [token] into screen 80's field and saves it, then waits for Home's
     * TMDB block to go — the reader's own token being the only key there is.
     */
    private fun saveOwnToken(token: String) {
        kati.tap("root_home")
        kati.awaitScreen("home")
        kati.compose.waitUntil(20_000) { kati.present("add_tmdb_token") }

        kati.tap("add_tmdb_token")
        kati.awaitScreen("data_sources")
        noInvented("Data sources")
        assertTrue("screen 80 still offers a key of Kati's own", !kati.present("key_kati"))

        kati.compose.waitUntil(10_000) { kati.present("tmdb_token") }
        withoutTheToken {
            kati.compose.onNodeWithTag("tmdb_token", useUnmergedTree = true)
                .performTextInput(token)
            kati.device.waitForIdle()
            kati.tap("save_token")
            kati.compose.waitUntil(10_000) { kati.present("replace_token") }
        }
        assertTrue("screen 80 still draws the token field after Save", !kati.present("tmdb_token"))

        kati.tap("back")
        kati.awaitScreen("home")
        kati.compose.waitUntil(20_000) { !kati.present("add_tmdb_token") }
        noInvented("Home with a key")
    }

    /**
     * Runs [body] so that nothing it throws can carry the token: a Compose
     * failure describes the node it acted on, and the field's node holds the
     * token once it is typed. The message is scrubbed and the cause dropped.
     */
    private fun withoutTheToken(body: () -> Unit) {
        try {
            body()
        } catch (failure: Throwable) {
            throw AssertionError(scrub(failure.message ?: failure.javaClass.simpleName))
        }
    }

    /** [text] with the token, if one is in play, replaced. */
    private fun scrub(text: String): String =
        secret?.let { text.replace(it, "<tmdbToken>") } ?: text

    // ── 3 ───────────────────────────────────────────────────────────────────

    private fun addBoth() {
        kati.tap("fab")
        kati.awaitScreen("add_title")
        noInvented("screen 06 before a query")

        addFromCatalogue(film, filmYear, "FILM")
        assertNotNull(
            "$film was tapped and no film row carries it",
            kati.scalar(
                "select t.id from tracked_titles t join cached_titles c " +
                    "on c.source_id = t.source_id where t.kind = 'movie' and c.title = '$film'"
            )
        )

        kati.compose.onNodeWithTag("title_query", useUnmergedTree = true).performTextClearance()
        kati.device.waitForIdle()

        addFromCatalogue(series, seriesYear, "SERIES")
        assertNotNull(
            "$series was tapped and no series row carries it",
            kati.scalar(
                "select t.id from tracked_titles t join cached_titles c " +
                    "on c.source_id = t.source_id where t.kind = 'tv' and c.title = '$series'"
            )
        )
        noInvented("screen 06 after two adds")

        assertEquals("two adds, but the shelf does not hold two", 2L, kati.count("tracked_titles"))
        kati.popToRoot()
    }

    private fun addFromCatalogue(title: String, year: String, kind: String) {
        val before = kati.count("tracked_titles")

        kati.compose.onNodeWithTag("title_query", useUnmergedTree = true).performTextInput(title)
        kati.device.waitForIdle()

        val found = waitFor(45_000) { resultRow(title, year, kind) != null || providerRefused() }
        val tag = resultRow(title, year, kind)
        assertTrue(
            "searching \"$title\" found no \"$title\" row meta'd \"$year · $kind\" in 45s" +
                (if (providerRefused()) " — the provider refused: ${refusal()}" else "") +
                (if (!found) " — nothing answered at all" else ""),
            tag != null
        )

        kati.tap(tag!!)
        kati.compose.waitUntil(30_000) { kati.count("tracked_titles") > before }
    }

    // ── 4 ───────────────────────────────────────────────────────────────────

    private fun libraryShowsBoth() {
        kati.tap("root_library")
        kati.awaitScreen("library")

        kati.compose.waitUntil(20_000) { textPresent("2 titles") }
        assertTrue("the Library does not draw $film", textPresent(film))
        assertTrue("the Library does not draw $series", textPresent(series))
        noInvented("the Library with two titles")

        val filmTile = "open_film_${filmId()}"
        val seriesTile = "open_series_${seriesId()}"
        assertTrue("no tile tagged $filmTile", kati.present(filmTile))
        assertTrue("no tile tagged $seriesTile", kati.present(seriesTile))

        for ((title, id) in listOf(film to filmId(), series to seriesId())) {
            val poster = kati.scalar(
                "select c.poster_path from cached_titles c join tracked_titles t " +
                    "on c.source_id = t.source_id where t.id = '$id'"
            )
            assertNotNull("$title has no poster_path in cached_titles", poster)
            kati.compose.waitUntil(30_000) { artworkFor(poster!!) != null }
        }

        for (tile in listOf(filmTile, seriesTile)) {
            kati.compose.waitUntil(20_000) { looksLikeAPicture(tile) }
        }
    }

    // ── 5 ───────────────────────────────────────────────────────────────────

    private fun logWatchAndRewatch() {
        val id = filmId()
        kati.tap("open_film_$id")
        kati.awaitScreen("film")
        noInvented("$film's page")

        kati.tap("rate")
        kati.awaitScreen("rating")
        kati.compose.waitUntil(10_000) { textPresent("Log a watch") }
        noInvented("the Log a watch sheet")
        kati.tap("star_8")
        kati.device.waitForIdle()
        kati.tap("save")

        kati.awaitScreen("film")
        kati.compose.waitUntil(20_000) { watchesOf(id) == 1L }
        kati.compose.waitUntil(20_000) { textPresent("1 time") }
        assertEquals(
            "the watch saved without the rating tapped",
            "8",
            kati.scalar("select rating from media_watches where tracked_title_id = '$id'")
        )

        kati.tap("toggle_menu")
        kati.compose.waitUntil(10_000) { kati.present("log_watch") }
        assertTrue("the ⋯ menu does not offer Log rewatch", textPresent("Log rewatch"))
        kati.tap("log_watch")

        kati.awaitScreen("rating")
        kati.compose.waitUntil(10_000) { textPresent("1st rewatch") }
        kati.tap("save")

        kati.awaitScreen("film")
        kati.compose.waitUntil(20_000) { watchesOf(id) == 2L }
        kati.compose.waitUntil(20_000) { textPresent("2 times") }
        noInvented("$film's page after a rewatch")

        kati.popToRoot()
    }

    // ── 6 ───────────────────────────────────────────────────────────────────

    private fun tickFirstEpisode() {
        val id = seriesId()
        kati.tap("root_library")
        kati.awaitScreen("library")
        kati.tap("open_series_$id")
        kati.awaitScreen("series")
        noInvented("$series's page")

        kati.compose.waitUntil(45_000) { kati.tagStartingWith("season_") != null }
        kati.compose.waitUntil(45_000) { kati.present("episode_1") }

        val before = episodeTicksOf(id)
        kati.tap("episode_1")
        kati.compose.waitUntil(20_000) { episodeTicksOf(id) == before + 1 }
        kati.compose.waitUntil(20_000) { textMatching(Regex("^1 of \\d+ watched$")) != null }
        noInvented("$series's page after a tick")

        kati.popToRoot()
    }

    // ── 7 ───────────────────────────────────────────────────────────────────

    /**
     * Screen 16 is waited for by its own chevron rather than by its stamp: it
     * renders through `Kati.Shell` as a `root: :calendar` screen, so what it
     * stamps is `screen:calendar`, the same as the Schedule it is pushed over.
     */
    private fun calendarAiring() {
        kati.tap("root_calendar")
        kati.awaitScreen("calendar")
        noInvented("the Calendar")

        kati.tap("open_month")
        kati.compose.waitUntil(20_000) { kati.present("month_previous") }

        repeat(12) {
            if (textPresent("June 2026")) return@repeat
            kati.tap("month_previous")
            kati.device.waitForIdle()
            waitFor(3_000) { textPresent("June 2026") }
        }
        kati.compose.waitUntil(10_000) { textPresent("June 2026") }
        noInvented("the month grid, June 2026")

        kati.tap("day_2026-06-25")
        val row = "row_series_${seriesId()}"
        kati.compose.waitUntil(20_000) { kati.present(row) }
        assertTrue("25 June lists no \"$series\"", textPresent(series))
        assertTrue("25 June's $series row does not say S5 · E1", textPresent("S5 · E1"))
        noInvented("25 June")

        kati.tap(row)
        kati.awaitScreen("series")
        kati.compose.waitUntil(10_000) { backPill() != null }
        assertEquals(
            "$series's page, opened from the Calendar, names another page on its back pill",
            "Calendar",
            backPill()
        )
        noInvented("$series's page from the Calendar")

        kati.tap("back")
        kati.compose.waitUntil(20_000) { kati.present("month_previous") }
    }

    // ── 8 ───────────────────────────────────────────────────────────────────

    private fun searchFindsIt() {
        kati.tap("root_home")
        kati.awaitScreen("home")
        kati.tap("open_search")
        kati.awaitScreen("search_idle")
        kati.compose.waitUntil(20_000) { kati.present("search_query") }
        noInvented("the idle Search page")

        kati.compose.onNodeWithTag("search_query", useUnmergedTree = true).performTextInput("arriv")
        kati.device.waitForIdle()
        kati.compose.onNodeWithTag("search_query", useUnmergedTree = true).performImeAction()

        kati.awaitScreen("search")
        kati.compose.waitUntil(20_000) { textPresent(film) }
        assertTrue(
            "a search for \"arriv\" drew $series, which it does not match",
            !textPresent(series)
        )
        noInvented("Search results")
    }

    // ── The store ───────────────────────────────────────────────────────────

    private fun filmId(): String = trackedId("movie", film)

    private fun seriesId(): String = trackedId("tv", series)

    private fun trackedId(kind: String, title: String): String =
        kati.scalar(
            "select t.id from tracked_titles t join cached_titles c " +
                "on c.source_id = t.source_id where t.kind = '$kind' and c.title = '$title'"
        ) ?: throw AssertionError("no tracked $kind row for \"$title\"")

    private fun watchesOf(id: String): Long =
        kati.scalar(
            "select count(*) from media_watches where tracked_title_id = '$id' " +
                "and episode_number is null"
        )?.toLong() ?: 0L

    private fun episodeTicksOf(id: String): Long =
        kati.scalar(
            "select count(*) from media_watches where tracked_title_id = '$id' " +
                "and episode_number is not null"
        )?.toLong() ?: 0L

    /**
     * The file `Kati.Media.Artwork` downloaded for a TMDB poster path, or null.
     *
     * Its files are `<width>_<name>` under `files/artwork`, so the path's last
     * segment is what names them.
     */
    private fun artworkFor(posterPath: String): File? {
        val name = posterPath.substringAfterLast('/')
        val dir = File(context.filesDir, "artwork")
        return dir.listFiles()?.firstOrNull { it.name.endsWith("_$name") && it.length() > 0 }
    }

    // ── The screen ──────────────────────────────────────────────────────────

    private fun textPresent(text: String): Boolean =
        try {
            kati.compose
                .onAllNodesWithText(text, substring = true, useUnmergedTree = true)
                .fetchSemanticsNodes()
                .isNotEmpty()
        } catch (_: Throwable) {
            false
        }

    private fun allNodes(): List<SemanticsNode> =
        try {
            kati.compose
                .onAllNodes(SemanticsMatcher("any") { true }, useUnmergedTree = true)
                .fetchSemanticsNodes()
        } catch (_: Throwable) {
            emptyList()
        }

    private fun textsOf(node: SemanticsNode): List<String> =
        node.config.getOrNull(SemanticsProperties.Text)?.map { it.text } ?: emptyList()

    private fun tagOf(node: SemanticsNode): String? =
        node.config.getOrNull(SemanticsProperties.TestTag)

    /**
     * The word on a pushed page's back pill: the text drawn inside the `back`
     * node. Its chevron is a Material Symbol, a private-use code point with no
     * letter in it, which is how the glyph is told from the word.
     */
    private fun backPill(): String? {
        val nodes = allNodes()
        val pill = nodes.firstOrNull { tagOf(it) == "back" }?.boundsInRoot ?: return null
        return nodes
            .filter { pill.contains(it.boundsInRoot.center) }
            .flatMap { textsOf(it) }
            .firstOrNull { text -> text.any { it.isLetter() } }
    }

    private fun textMatching(pattern: Regex): String? =
        allNodes().flatMap { textsOf(it) }.firstOrNull { pattern.matches(it.trim()) }

    /**
     * The `add_<position>` disc on the row whose title is exactly [title] and
     * whose meta line is `<year> · <kind>`.
     *
     * `Kati.Screens.AddTitle` tags a result by its position, which is the
     * catalogue's order and not this test's business, so the row is found by
     * what it SAYS: a disc, and a title and a meta line whose centres sit
     * within one row's height of it.
     */
    private fun resultRow(title: String, year: String, kind: String): String? {
        val nodes = allNodes()
        val rowHalf = 50 * context.resources.displayMetrics.density

        val discs = nodes.filter { n ->
            tagOf(n)?.let { Regex("^add_\\d+$").matches(it) } == true
        }
        val titles = nodes.filter { n -> textsOf(n).any { it.trim() == title } }
        val metas = nodes.filter { n ->
            textsOf(n).any { it.startsWith(year) && it.contains(kind) }
        }

        return discs.firstOrNull { disc ->
            val y = disc.boundsInRoot.center.y
            titles.any { kotlin.math.abs(it.boundsInRoot.center.y - y) < rowHalf } &&
                metas.any { kotlin.math.abs(it.boundsInRoot.center.y - y) < rowHalf }
        }?.let { tagOf(it) }
    }

    private val refusals = listOf(
        "Could not look", "No TMDB token", "did not answer", "too many", "blocking TMDB"
    )

    private fun providerRefused(): Boolean = refusals.any { textPresent(it) }

    private fun refusal(): String =
        allNodes().flatMap { textsOf(it) }.firstOrNull { t -> refusals.any { t.contains(it) } }
            ?: "(no sentence)"

    /**
     * Whether the tile under [tag] is drawing a picture rather than a flat
     * placeholder.
     *
     * `MobImage` is Coil's `AsyncImage` with no content description, so a
     * poster puts no node in the semantics tree for a test to find. What it
     * does put there is pixels: a placeholder is one colour and a poster is
     * not, so the tile is captured and its colours counted — over the 158pt
     * poster box `Kati.Screens.Library.poster/1` draws, and not the title
     * under it, whose antialiasing would count as colour on a blank tile.
     */
    private fun looksLikeAPicture(tag: String): Boolean =
        try {
            val bitmap = kati.compose.onNodeWithTag(tag, useUnmergedTree = true)
                .captureToImage().asAndroidBitmap()
            val poster = (158 * context.resources.displayMetrics.density).toInt()
            val colours = distinctColours(bitmap, minOf(poster, bitmap.height))
            Log.i(TAG, "$tag: ${bitmap.width}x${bitmap.height}, $colours colours")
            colours > 64
        } catch (_: Throwable) {
            false
        }

    private fun distinctColours(bitmap: Bitmap, height: Int): Int {
        val seen = HashSet<Int>()
        val stepX = maxOf(1, bitmap.width / 24)
        val stepY = maxOf(1, height / 36)
        for (x in 0 until bitmap.width step stepX) {
            for (y in 0 until height step stepY) {
                seen.add(bitmap.getPixel(x, y) and 0x00F0F0F0)
            }
        }
        return seen.size
    }

    private fun noInvented(where: String) {
        val found = invented.filter { textPresent(it) }
        assertTrue(
            "$where drew invented content: $found — a Sample module or a board's " +
                "fixture reached a screen that should be drawing the store",
            found.isEmpty()
        )
    }

    private fun waitFor(timeoutMs: Long, condition: () -> Boolean): Boolean =
        try {
            kati.compose.waitUntil(timeoutMs) { condition() }
            true
        } catch (_: Throwable) {
            false
        }

    /**
     * Runs one numbered step, logs it as passed, or dumps the screen and
     * rethrows with the step's name on the front of the message.
     */
    private fun <T> step(n: Int, name: String, body: () -> T): T {
        Log.i(TAG, "STEP $n START $name")
        try {
            val result = body()
            Log.i(TAG, "STEP $n PASS $name")
            dump("the end of step $n", Log.DEBUG)
            return result
        } catch (failure: Throwable) {
            val message = scrub(failure.message ?: "")
            Log.e(TAG, "STEP $n FAIL $name: $message")
            dump("step $n", Log.ERROR)
            throw AssertionError("step $n ($name) failed: $message", failure)
        }
    }

    private fun dump(label: String, priority: Int) {
        val nodes = allNodes()
        Log.println(priority, TAG, "── screen at $label: ${nodes.size} nodes ──")
        for (node in nodes) {
            val tag = tagOf(node)
            val texts = if (tag == "tmdb_token") listOf("(withheld)") else textsOf(node).map(::scrub)
            if (tag == null && texts.isEmpty()) continue
            val b: Rect = node.boundsInRoot
            Log.println(priority, TAG, "  [${tag ?: ""}] ${texts.joinToString(" | ")} @${b.top.toInt()}")
        }
    }

    private companion object {
        const val TAG = "FilmSeriesFlow"
    }
}
