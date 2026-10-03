package com.example.kati

import android.Manifest
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import androidx.compose.ui.test.onAllNodesWithContentDescription
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * #125 — notifications that work without the app: the background check posts
 * one notification per show, grouped under a summary; a tap opens the title;
 * the settings that shape them are switches that hold.
 */
@RunWith(AndroidJUnit4::class)
class NotificationsTest {

    @get:Rule
    val kati = KatiRule()

    private val ctx: Context
        get() = InstrumentationRegistry.getInstrumentation().targetContext

    private fun heard(description: String): Boolean =
        try {
            kati.compose.onAllNodesWithContentDescription(description, useUnmergedTree = true)
                .fetchSemanticsNodes().isNotEmpty()
        } catch (_: Throwable) {
            false
        }

    private fun grantNotifications() {
        InstrumentationRegistry.getInstrumentation().uiAutomation
            .grantRuntimePermission(ctx.packageName, Manifest.permission.POST_NOTIFICATIONS)
    }

    @Test
    fun a_the_background_check_posts_one_notification_per_show_under_a_summary() {
        grantNotifications()
        val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.cancelAll()

        val found = JSONArray()
            .put(JSONObject().put("tracked_id", "t-dark").put("kind", "tv").put("title", "Dark")
                .put("body", "2 new episodes · S2E6–7"))
            .put(JSONObject().put("tracked_id", "t-frieren").put("kind", "tv").put("title", "Frieren")
                .put("body", "New episode · S1E28"))
        val strings = JSONObject().put("summary", "New episodes of {shows} shows").put("digits", "0123456789")

        KatiReleaseCheck.post(ctx, found, strings)

        // The manager enqueues a post; it is listed a moment later.
        fun posted() = nm.activeNotifications.filter { it.notification.group == KatiReleaseCheck.CHANNEL }
        val deadline = System.currentTimeMillis() + 10_000
        while (posted().size < 3 && System.currentTimeMillis() < deadline) Thread.sleep(200)

        val posted = posted()
        val titles = posted.mapNotNull { it.notification.extras.getString("android.title") }
        assertTrue("one per show: $titles", titles.containsAll(listOf("Dark", "Frieren")))
        assertTrue(
            "a summary groups them",
            posted.any { it.notification.flags and android.app.Notification.FLAG_GROUP_SUMMARY != 0 }
        )
        nm.cancelAll()
    }

    @Test
    fun b_quiet_hours_and_an_unreachable_source_post_nothing() {
        val night = java.util.Calendar.getInstance().apply {
            set(java.util.Calendar.HOUR_OF_DAY, 23); set(java.util.Calendar.MINUTE, 30)
        }
        val window = JSONObject().put("from", 23 * 60).put("to", 8 * 60)
        assertTrue(KatiReleaseCheck.quiet(window, night))
        night.set(java.util.Calendar.HOUR_OF_DAY, 12)
        assertFalse(KatiReleaseCheck.quiet(window, night))

        val watchlist = JSONObject()
            .put("items", JSONArray().put(
                JSONObject().put("source", "nowhere").put("source_id", "1").put("tracked_id", "x")
                    .put("last_season", 1).put("last_episode", 1)
            ))
            .put("settings", JSONObject().put("push", true))
        assertEquals(0, KatiReleaseCheck.run(ctx, watchlist).length())
    }

    @Test
    fun c_a_notification_tap_opens_its_title() {
        val show = "Notify Show ${System.currentTimeMillis()}"
        kati.launch()
        kati.firstRun()
        ByHand.add(kati, show, "kind_tv")
        val id = kati.scalar("select id from tracked_titles where source_id = '$show'") ?: ""
        ByHand.toTabs(kati)
        kati.tap("root_home")
        kati.awaitScreen("home")

        val envelope = JSONObject()
            .put("id", "kati_ep_$id").put("title", show).put("body", "New episode")
            .put("source", "local").put("presentation", "tap").put("action", "default")
            .put("data", JSONObject().put("kati_open", "title").put("id", id).put("kind", "tv"))
            .toString()
        // The tap as Android delivers it to a running Kati: the activity is
        // singleTop, so the envelope arrives through `onNewIntent`, and the
        // BEAM routes it to the screen showing, which opens the title.
        // The scenario finds its activity by the intent it launched, which
        // `onNewIntent` replaces, so the launch intent is put back after.
        kati.onActivity { activity ->
            val launched = activity.intent
            InstrumentationRegistry.getInstrumentation().callActivityOnNewIntent(
                activity,
                Intent(activity, MainActivity::class.java).putExtra("mob_notification_json", envelope)
            )
            activity.intent = launched
        }

        kati.awaitScreen("series")
    }

    @Test
    fun d_the_reminder_switches_hold_and_the_sections_open() {
        kati.launch()
        kati.firstRun()
        kati.tap("root_home")
        kati.awaitScreen("home")
        kati.tap("notifications")
        kati.awaitScreen("inbox_notifications")

        kati.tap("open_tv")
        kati.awaitScreen("release_watcher")
        kati.compose.waitUntil(10_000) { heard("Rewatch suggestions: on") }
        kati.tap("remind_rewatch")
        kati.compose.waitUntil(10_000) { heard("Rewatch suggestions: off") }

        kati.device.pressBack()
        kati.awaitScreen("inbox_notifications")
        kati.tap("open_tv")
        kati.awaitScreen("release_watcher")
        kati.compose.waitUntil(10_000) { heard("Rewatch suggestions: off") }
        assertTrue(heard("Scheduled watches: on"))
    }
}
