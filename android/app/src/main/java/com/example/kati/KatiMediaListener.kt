// KATI-BEGIN(K-46 media-session-listener) mob_new=0.7.24
package com.example.kati

import android.content.ComponentName
import android.content.Context
import android.media.session.MediaController
import android.media.session.MediaSessionManager
import android.media.session.PlaybackState
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
 */
class KatiMediaListener : NotificationListenerService() {

    companion object {
        private const val TAG = "KatiMedia"

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
