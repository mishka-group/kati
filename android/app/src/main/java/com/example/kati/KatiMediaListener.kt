// KATI-BEGIN(K-46 media-session-listener) mob_new=0.7.24
package com.example.kati

import android.content.ComponentName
import android.content.Context
import android.media.MediaMetadata
import android.media.session.MediaController
import android.media.session.MediaSessionManager
import android.media.session.PlaybackState
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.service.notification.NotificationListenerService
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject

/**
 * What is playing on this device, for Kati's auto-detect.
 *
 * ## Why a NotificationListenerService that listens to no notifications
 *
 * `MediaSessionManager.getActiveSessions` is the only API that answers *what
 * is this phone playing right now*, and it takes the `ComponentName` of an
 * **enabled notification listener** as proof that the user allowed it. So the
 * service exists to be enabled, not to receive anything: every callback it
 * could override is left alone. That is Android's design, not a trick — media
 * controls live in the notification shade, so the permission that reads the
 * shade is the permission that reads them.
 *
 * The user grants it in system settings and nowhere else. There is no runtime
 * dialog for `BIND_NOTIFICATION_LISTENER_SERVICE`; `ACTION_NOTIFICATION_LISTENER_SETTINGS`
 * is the whole of what an app may do, which is why screen 36 offers a row that
 * opens that page rather than a switch that asks.
 *
 * ## What it reports, and what it deliberately does not
 *
 * One entry per active session: the package that owns it, the title and
 * subtitle its metadata carries, the position and duration in milliseconds,
 * and whether it is playing. That is what a *90% watched* threshold needs and
 * nothing more.
 *
 * It reports no artwork, no queue, no session token and no notification
 * content. A listener with this permission can read every notification on the
 * device; this one reads active media sessions and stops, because the thing
 * Kati is asking for is *did I finish that episode* and everything past it is
 * somebody else's business. `onNotificationPosted` is not overridden at all.
 *
 * ## Why it RECORDS rather than only answering
 *
 * The first version only answered `getActiveSessions` when Elixir asked, and
 * that cannot work: you finish an episode, close Netflix, and the session is
 * gone. By the time Kati is next opened there is nothing to see, so the one
 * case the whole feature exists for — *I watched it, tick it for me* — was the
 * one case it could never catch.
 *
 * So the listener watches while it is bound, which is whenever the user has
 * enabled it, and keeps the **high-water mark** of every session it hears: the
 * furthest position reached, against the duration. Elixir drains that on the
 * next launch and applies its own threshold and its own matching.
 *
 * This is the shape `KatiRefreshWorker` and `Kati.Background.Handoff` already
 * use for the same reason — work happens while the BEAM is dead, and what it
 * found is read back when the BEAM is next up.
 *
 * The store holds at most [MAX_SEEN] entries and nothing but what a tick needs.
 * It is cleared as it is drained, so it is a queue rather than a history.
 */
class KatiMediaListener : NotificationListenerService() {

    /**
     * Bound. Start watching.
     *
     * `onListenerConnected` rather than `onCreate`: the service object exists
     * before the OS has granted it anything, and `getActiveSessions` throws
     * `SecurityException` until the bind completes.
     */
    override fun onListenerConnected() {
        super.onListenerConnected()
        watch(this)
    }

    override fun onListenerDisconnected() {
        unwatch()
        super.onListenerDisconnected()
    }

    companion object {
        private const val TAG = "KatiMedia"
        private const val SEEN = "kati_media_seen"
        private const val MAX_SEEN = 40

        // The MAIN looper, explicitly, for both registrations below.
        //
        // `addOnActiveSessionsChangedListener(listener, component)` and
        // `registerCallback(callback)` build a Handler on the CALLING thread,
        // and one of the two callers here is a BEAM scheduler thread — which
        // has no Looper, so the call threw
        // `Can't create handler inside thread ... that has not called
        // Looper.prepare()` and the watcher silently never registered. Found on
        // a device: everything reported granted, nothing was ever recorded.
        private val main = Handler(Looper.getMainLooper())

        private var manager: MediaSessionManager? = null
        private var sessionsListener: MediaSessionManager.OnActiveSessionsChangedListener? = null
        private val watched = mutableMapOf<MediaController, MediaController.Callback>()

        /**
         * Whether the user has enabled Kati as a notification listener.
         *
         * Read off `Settings.Secure.enabled_notification_listeners`, which is
         * the flat colon-separated list the OS keeps. There is no API that
         * answers this for your own package — `isNotificationListenerAccessGranted`
         * is `NotificationManager`'s and needs API 27 plus the component, and
         * this reads the same setting one layer down and works everywhere.
         */
        fun granted(ctx: Context): Boolean {
            val listeners =
                Settings.Secure.getString(
                    ctx.contentResolver,
                    "enabled_notification_listeners"
                ) ?: return false

            val us = ComponentName(ctx, KatiMediaListener::class.java).flattenToString()
            val usShort = ComponentName(ctx, KatiMediaListener::class.java).flattenToShortString()

            return listeners.split(":").any { it == us || it == usShort }
        }

        /**
         * Every active media session, as JSON. `[]` when access has not been
         * granted, which is a true statement and not an error: nothing is
         * being reported because nothing may be.
         */
        fun nowPlaying(ctx: Context): String {
            if (!granted(ctx)) return "[]"

            return try {
                val manager =
                    ctx.getSystemService(Context.MEDIA_SESSION_SERVICE) as MediaSessionManager
                val component = ComponentName(ctx, KatiMediaListener::class.java)
                val out = JSONArray()

                for (controller in manager.getActiveSessions(component)) {
                    describe(controller)?.let { out.put(it) }
                }

                out.toString()
            } catch (e: SecurityException) {
                // The listener is enabled in settings but not yet bound, which
                // is the window right after the user flips the switch. `[]` is
                // right for it: nothing is known yet, and the next poll knows.
                Log.i(TAG, "media sessions not readable yet: ${e.message}")
                "[]"
            } catch (e: Exception) {
                Log.w(TAG, "media sessions failed", e)
                "[]"
            }
        }

        /**
         * Start following every media session, and every one that appears.
         *
         * Idempotent: called on each bind, and Android binds again after a
         * reboot or an app update.
         */
        @Synchronized
        fun watch(ctx: Context) {
            if (!granted(ctx)) return

            try {
                val mgr = ctx.getSystemService(Context.MEDIA_SESSION_SERVICE) as MediaSessionManager
                val component = ComponentName(ctx, KatiMediaListener::class.java)

                unwatch()
                manager = mgr

                val listener =
                    MediaSessionManager.OnActiveSessionsChangedListener { controllers ->
                        follow(ctx, controllers ?: emptyList())
                    }

                sessionsListener = listener
                mgr.addOnActiveSessionsChangedListener(listener, component, main)
                follow(ctx, mgr.getActiveSessions(component))
            } catch (e: Exception) {
                Log.w(TAG, "could not watch media sessions", e)
            }
        }

        @Synchronized
        fun unwatch() {
            sessionsListener?.let { l ->
                try {
                    manager?.removeOnActiveSessionsChangedListener(l)
                } catch (e: Exception) {
                    Log.i(TAG, "listener already gone: ${e.message}")
                }
            }

            for ((controller, callback) in watched) {
                try {
                    controller.unregisterCallback(callback)
                } catch (e: Exception) {
                    Log.i(TAG, "callback already gone: ${e.message}")
                }
            }

            watched.clear()
            sessionsListener = null
            manager = null
        }

        /**
         * Register a callback on each live controller, and drop the ones that
         * have gone. Every state change is recorded, because the LAST state
         * before a session disappears is the one that says how far you got.
         */
        @Synchronized
        private fun follow(ctx: Context, controllers: List<MediaController>) {
            for ((controller, callback) in watched.toList()) {
                if (!controllers.contains(controller)) {
                    try {
                        controller.unregisterCallback(callback)
                    } catch (e: Exception) {
                        Log.i(TAG, "stale callback: ${e.message}")
                    }
                    watched.remove(controller)
                }
            }

            for (controller in controllers) {
                if (watched.containsKey(controller)) continue

                val callback =
                    object : MediaController.Callback() {
                        override fun onPlaybackStateChanged(state: PlaybackState?) {
                            record(ctx, controller)
                        }

                        override fun onMetadataChanged(metadata: MediaMetadata?) {
                            record(ctx, controller)
                        }

                        override fun onSessionDestroyed() {
                            record(ctx, controller)
                        }
                    }

                try {
                    controller.registerCallback(callback, main)
                    watched[controller] = callback
                    record(ctx, controller)
                } catch (e: Exception) {
                    Log.i(TAG, "could not follow ${controller.packageName}: ${e.message}")
                }
            }
        }

        /**
         * Keep the furthest point this session has reached.
         *
         * The high-water mark and not the current position, because the
         * position at the moment a session is destroyed is often 0 — a player
         * resets before it lets go. What Kati needs is *how far did this get*,
         * which only ever grows.
         */
        @Synchronized
        private fun record(ctx: Context, controller: MediaController) {
            val entry = describe(controller) ?: return
            val key = entry.optString("app") + "|" + entry.optString("title") +
                "|" + entry.optString("subtitle")

            try {
                val prefs = ctx.getSharedPreferences(SEEN, Context.MODE_PRIVATE)
                val previous = prefs.getString(key, null)?.let { JSONObject(it) }
                val best = maxOf(
                    entry.optLong("position_ms"),
                    previous?.optLong("position_ms") ?: 0L
                )

                if (previous == null && prefs.all.size >= MAX_SEEN) return

                entry.put("position_ms", best)
                entry.put("seen_at", System.currentTimeMillis())
                prefs.edit().putString(key, entry.toString()).apply()
            } catch (e: Exception) {
                Log.w(TAG, "could not record session", e)
            }
        }

        /**
         * Everything recorded since the last drain, and clear it.
         *
         * Cleared as it is read: this is a queue of *things that happened while
         * you were not looking*, and a second drain of the same play would be
         * a second tick of one evening. Elixir's own `:already` guard would
         * catch that, and depending on two guards for one rule is how they
         * come to disagree.
         */
        @Synchronized
        fun drain(ctx: Context): String {
            return try {
                val prefs = ctx.getSharedPreferences(SEEN, Context.MODE_PRIVATE)
                val out = JSONArray()

                for (value in prefs.all.values) {
                    (value as? String)?.let { out.put(JSONObject(it)) }
                }

                prefs.edit().clear().apply()
                out.toString()
            } catch (e: Exception) {
                Log.w(TAG, "could not drain sessions", e)
                "[]"
            }
        }

        private fun describe(controller: MediaController): JSONObject? {
            val metadata = controller.metadata ?: return null
            val state = controller.playbackState

            val title =
                metadata.getString(android.media.MediaMetadata.METADATA_KEY_TITLE)
                    ?: metadata.getString(android.media.MediaMetadata.METADATA_KEY_DISPLAY_TITLE)
                    ?: return null

            val subtitle =
                metadata.getString(android.media.MediaMetadata.METADATA_KEY_ARTIST)
                    ?: metadata.getString(android.media.MediaMetadata.METADATA_KEY_DISPLAY_SUBTITLE)
                    ?: ""

            return JSONObject().apply {
                put("app", controller.packageName ?: "")
                put("title", title)
                put("subtitle", subtitle)
                put("duration_ms", metadata.getLong(android.media.MediaMetadata.METADATA_KEY_DURATION))
                put("position_ms", state?.position ?: 0L)
                put("playing", state?.state == PlaybackState.STATE_PLAYING)
            }
        }
    }
}
// KATI-END(K-46 media-session-listener)
