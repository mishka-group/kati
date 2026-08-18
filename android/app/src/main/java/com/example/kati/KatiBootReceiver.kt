package com.example.kati

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Restores scheduled notifications after events that clear `AlarmManager`.
 *
 * The stock manifest requests `RECEIVE_BOOT_COMPLETED` but declares no
 * receiver, so every scheduled notification was lost on the first reboot with
 * no error anywhere.
 *
 * `ACTION_BOOT_COMPLETED` and `ACTION_MY_PACKAGE_REPLACED` clear pending
 * alarms outright. `ACTION_TIME_CHANGED` and `ACTION_TIMEZONE_CHANGED` do not,
 * but they move the wall clock under alarms that were armed against it, so
 * re-arming from the stored absolute timestamps is the cheapest way to stay
 * correct across a flight or a manual clock change.
 *
 * All four are on Android's implicit-broadcast exception list, so a
 * manifest-declared receiver still runs on API 26+.
 */
class KatiBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED -> {
                Log.i("KatiNotify", "re-arming alarms after ${intent.action}")
                KatiNotificationStore.rearmAll(context)
            }
        }
    }
}
