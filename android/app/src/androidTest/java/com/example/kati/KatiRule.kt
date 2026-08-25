package com.example.kati

import android.app.Instrumentation
import androidx.compose.ui.test.junit4.ComposeTestRule
import androidx.compose.ui.test.junit4.createEmptyComposeRule
import androidx.compose.ui.test.onAllNodesWithTag
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performClick
import androidx.test.core.app.ActivityScenario
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.uiautomator.UiDevice
import org.junit.rules.RuleChain
import org.junit.rules.TestRule
import org.junit.runner.Description
import org.junit.runners.model.Statement
import java.io.File

/**
 * The only class an e2e author touches.
 *
 * Kati's screens are drawn by the BEAM and handed to Compose over JNI, which
 * makes two ordinary assumptions false and this class is mostly about those
 * two.
 *
 * The first is that `waitForIdle()` means the screen is ready. It does not:
 * it synchronises on recomposition, and the first render arrives
 * asynchronously from Elixir long after Compose has gone quiet against an
 * empty tree. So the single sync point here is [awaitScreen], which waits for
 * a screen to say its own name.
 *
 * The second is that clearing state between tests means clearing the data
 * directory. It does not: `files/otp/` is the extracted Erlang runtime, 51MB
 * of it, and deleting it makes every test pay the extraction again. [wipe]
 * removes the store files by name and nothing else — which is also why
 * `testOptions` in `build.gradle` sets no `clearPackageData`.
 */
class KatiRule : TestRule {

    val compose: ComposeTestRule = createEmptyComposeRule()

    private val instrumentation: Instrumentation
        get() = InstrumentationRegistry.getInstrumentation()

    val device: UiDevice
        get() = UiDevice.getInstance(instrumentation)

    private val filesDir: File
        get() = instrumentation.targetContext.filesDir

    private var scenario: ActivityScenario<MainActivity>? = null

    override fun apply(base: Statement, description: Description): Statement =
        RuleChain
            .outerRule(WipeRule())
            .around(compose)
            .apply(base, description)

    private inner class WipeRule : TestRule {
        override fun apply(base: Statement, description: Description) =
            object : Statement() {
                override fun evaluate() {
                    wipe()
                    try {
                        base.evaluate()
                    } finally {
                        scenario?.close()
                        scenario = null
                    }
                }
            }
    }

    /**
     * Deletes the store BY NAME. Never the directory — see the class doc.
     */
    fun wipe() {
        listOf("kati.db", "kati.db-wal", "kati.db-shm", "mob_state.dets")
            .map { File(filesDir, it) }
            .filter { it.exists() }
            .forEach { it.delete() }
    }

    /** Launches the real activity. */
    fun launch() {
        scenario = ActivityScenario.launch(MainActivity::class.java)
    }

    /**
     * The one sync point. Waits until the named screen has stamped itself,
     * rather than until Compose is idle — the tree can be idle and empty while
     * the BEAM is still booting.
     */
    fun awaitScreen(name: String, timeoutMs: Long = 30_000) {
        compose.waitUntil(timeoutMs) { present("screen:$name") }
    }

    /** Taps a control by the tag its Elixir side already gave it. */
    fun tap(tag: String) {
        compose.onNodeWithTag(tag, useUnmergedTree = true).performClick()
    }

    /**
     * Opens the app's SQLite store read-only and counts a table.
     *
     * This is the receipt. A screen that redrew its Sample module looks exactly
     * like a screen that redrew a row, so no assertion about state may be made
     * against the screen alone.
     */
    fun count(table: String): Long {
        val db = android.database.sqlite.SQLiteDatabase.openDatabase(
            File(filesDir, "kati.db").absolutePath,
            null,
            android.database.sqlite.SQLiteDatabase.OPEN_READONLY
        )
        db.use {
            it.rawQuery("select count(*) from $table", null).use { c ->
                c.moveToFirst()
                return c.getLong(0)
            }
        }
    }

    fun dbExists(): Boolean = File(filesDir, "kati.db").exists()

    /**
     * Whether any node currently carries [tag].
     *
     * `fetchSemanticsNodes()` throws rather than returning empty while the
     * tree is still being built, which is the normal state during a BEAM boot.
     * `waitUntil` needs a predicate, not an exception.
     */
    fun present(tag: String): Boolean =
        try {
            compose.onAllNodesWithTag(tag, useUnmergedTree = true)
                .fetchSemanticsNodes().isNotEmpty()
        } catch (_: Throwable) {
            false
        }
}
