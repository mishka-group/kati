package com.example.kati

import android.app.Instrumentation
import androidx.compose.ui.test.junit4.ComposeTestRule
import androidx.compose.ui.test.junit4.createEmptyComposeRule
import androidx.compose.ui.semantics.getOrNull
import androidx.compose.ui.test.onAllNodesWithTag
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollTo
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

    /**
     * Takes a runtime permission back off the app under test.
     *
     * Android permissions persist per package, so a grant in one @Test is still
     * in force in the next — which quietly falsifies the premise of any test
     * whose subject is "what happens when this has not been granted". Found
     * when a mid-session-grant test saw rows in the store before it had granted
     * anything.
     */
    fun revoke(permission: String) {
        // Only when it is actually held. `pm revoke` on a GRANTED permission
        // force-stops the package, and instrumentation runs inside that same
        // package — so the revoke kills the test with the app and the run
        // reports "Test instrumentation process crashed" with nothing to read.
        //
        // This is not hypothetical and it is not deterministic, which is worse:
        // the call is a harmless no-op while the permission is denied, so a
        // suite passes for weeks and then dies the first time anything leaves
        // the permission granted — a walk through the app by hand is enough.
        // Found exactly that way.
        val ctx = instrumentation.targetContext

        if (ctx.checkSelfPermission(permission) != android.content.pm.PackageManager.PERMISSION_GRANTED) {
            return
        }

        instrumentation.uiAutomation.executeShellCommand(
            "pm revoke ${ctx.packageName} $permission"
        ).close()
        device.waitForIdle()
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

    /**
     * Taps whichever of [tags] is on screen, and says which.
     *
     * The first run does not draw one fixed set of controls — screen 38 offers
     * `get_started` or `finish` depending on where it was entered — and a
     * journey that hardcodes one of them fails on the other for no reason a
     * reader could guess.
     */
    fun tapAny(vararg tags: String): String? {
        for (tag in tags) {
            if (!present(tag)) continue

            // The check and the tap are two moments, and a screen driven by the
            // BEAM can move between them: a control present when asked about is
            // gone by the time it is pressed, and Compose throws rather than
            // no-opping. That is a race in the test, never a defect in the app,
            // so it is swallowed and the next tag tried.
            try {
                tap(tag)
                return tag
            } catch (_: Throwable) {
                device.waitForIdle()
            }
        }
        return null
    }

    /**
     * Walks the first run to the shell.
     *
     * Every journey that is not itself about onboarding needs the app past it,
     * and a fresh install always starts there. Kept here so #91's work on the
     * first run changes one place rather than every test.
     */
    fun firstRun() {
        compose.waitUntil(60_000) { present("choose_en") }
        tap("continue")
        compose.waitUntil(20_000) { !present("choose_en") }

        // The calendar dialog, if this build asks for it.
        systemDialog("Allow", "While using the app", "Allow all the time")

        finishRun()
    }

    /**
     * Walks whatever is left of the first run, from wherever it currently is.
     *
     * Split out of [firstRun] so a journey that needs to ANSWER a step — pick
     * sections, choose a language — can drive that step itself and then hand
     * the rest back. Hand-rolling the tail instead is how a test ends up
     * waiting thirty seconds for a shell it never asked the app to reach.
     */
    fun finishRun() {
        compose.waitUntil(30_000) {
            present("get_started") || present("finish") || present("continue") || present("fab")
        }

        repeat(8) {
            if (present("fab")) return
            systemDialog("Allow", "While using the app", "Allow all the time")
            tapAny("get_started", "finish", "continue")
            device.waitForIdle()
            compose.waitUntil(5_000) { true }
        }
    }

    /**
     * Taps a control by the tag its Elixir side already gave it.
     *
     * Scrolls to it first, and that is not a nicety. `Mob`'s `<Scroll>` is a
     * plain `Column(verticalScroll(...))` (`MobBridge.kt:3026`), not a lazy
     * list, so EVERY child composes whether or not it is on screen. A control
     * below the fold is therefore present in the semantics tree — `present/1`
     * says true, `onNodeWithTag` finds it — while `performClick` injects a real
     * touch at the node's centre, which is off screen and reaches nothing.
     *
     * That combination cost a full afternoon on screen 92: the row tagged
     * `add_service` sits under four groups, so `present("add_service")` was
     * true, the tap silently did nothing, the row count stayed 0, and the
     * failure looked exactly like a broken write. The assertion that was
     * supposed to catch it — "an empty save wrote no row" — passed for the same
     * reason it was wrong: a tap that never fires also writes no row.
     *
     * `performScrollTo` throws for a node in no scrollable ancestor, which is
     * ordinary for a control already in view, so that case falls through to the
     * click rather than failing.
     */
    /**
     * The first tag on screen beginning with [prefix], or null.
     *
     * For controls whose tag carries DATA rather than a fixed name —
     * `Kati.Screens.AddTitle` builds `add_<title>`, so the tag depends on what
     * the catalogue answered, and a test that hardcodes one is really
     * asserting the catalogue's contents. Discovering it keeps the test about
     * the journey: something was offered, and taking it kept a row.
     */
    fun tagStartingWith(prefix: String): String? =
        compose.onAllNodes(
            androidx.compose.ui.test.SemanticsMatcher.keyIsDefined(
                androidx.compose.ui.semantics.SemanticsProperties.TestTag
            ),
            useUnmergedTree = true
        ).fetchSemanticsNodes().firstNotNullOfOrNull { node ->
            node.config
                .getOrNull(androidx.compose.ui.semantics.SemanticsProperties.TestTag)
                ?.takeIf { it.startsWith(prefix) }
        }

    fun tap(tag: String) {
        val node = compose.onNodeWithTag(tag, useUnmergedTree = true)

        try {
            node.performScrollTo()
        } catch (_: Throwable) {
            // Not in a scrollable ancestor, or already fully visible.
        }

        node.performClick()
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
     * The text a node currently shows, or null.
     *
     * Reads `EditableText` first and falls back to `Text`: a `<TextField>`
     * reports what has been typed into it under the editable key, while a
     * plain label reports under the other. Asking for both is what lets one
     * helper assert against either.
     */
    fun textOf(tag: String): String? =
        try {
            val node = compose.onNodeWithTag(tag, useUnmergedTree = true)
                .fetchSemanticsNode()
            val editable = node.config.getOrNull(
                androidx.compose.ui.semantics.SemanticsProperties.EditableText
            )?.text
            editable ?: node.config.getOrNull(
                androidx.compose.ui.semantics.SemanticsProperties.Text
            )?.joinToString("") { it.text }
        } catch (_: Throwable) {
            null
        }

    /** One value out of the store, or null when the query finds no row. */
    fun scalar(sql: String): String? {
        val db = android.database.sqlite.SQLiteDatabase.openDatabase(
            File(filesDir, "kati.db").absolutePath,
            null,
            android.database.sqlite.SQLiteDatabase.OPEN_READONLY
        )
        db.use {
            it.rawQuery(sql, null).use { c ->
                return if (c.moveToFirst() && !c.isNull(0)) c.getString(0) else null
            }
        }
    }

    /**
     * Clicks a control in ANOTHER process's window — an OS permission dialog.
     *
     * Compose cannot see these: they belong to the permission controller, not
     * to Kati, so `onNodeWithTag` has nothing to match. UI Automator addresses
     * the whole screen instead, which is the only way a test can answer a
     * dialog the OS raised.
     */
    fun systemDialog(vararg labels: String): Boolean {
        device.waitForIdle()
        for (label in labels) {
            val byText = androidx.test.uiautomator.By.text(
                java.util.regex.Pattern.compile(label, java.util.regex.Pattern.CASE_INSENSITIVE)
            )
            val found = device.wait(
                androidx.test.uiautomator.Until.findObject(byText), 5_000
            )
            if (found != null) {
                found.click()
                device.waitForIdle()
                return true
            }
        }
        return false
    }

    /**
     * Free space on /data, in megabytes.
     *
     * The e2e APK is ~127MB because it carries its own Erlang runtime, and a
     * stock AVD runs out. When it does, Gradle's install fails and
     * `am instrument` runs the PREVIOUSLY installed APK — so the run reports a
     * test failure, with a stack trace against line numbers the current source
     * does not have. Checked here so that can never again be mistaken for a
     * defect in the app.
     */
    fun freeMegabytes(): Long {
        val stat = android.os.StatFs(filesDir.absolutePath)
        return stat.availableBytes / (1024 * 1024)
    }

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
