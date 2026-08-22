# Scrobbling — stage 0: verify the claims before building anything

Research date: **2026-08-22**. Answers the four questions #62 stage 0 asks, each with a primary
source. **No prototype was built** — #62 says not to, and says stage 0 exists because a policy
stop costs nothing to check first and would make the engineering moot.

Scope is #62's: **"this phone"** only. Apple TV, Chromecast and the browser extension are three
other problems and are out of scope.

---

## Q1 · Does `getActiveSessions` require an enabled notification listener? — **VERIFIED, yes**

The ticket marked this UNVERIFIED. It is correct, and the wording matters more than the claim.

From the framework source javadoc for `MediaSessionManager.getActiveSessions(ComponentName)`:

> "Get a list of controllers for all ongoing sessions. […] This requires the
> `android.Manifest.permission.MEDIA_CONTENT_CONTROL` permission be held by the calling app. You
> may also retrieve this list if your app is an enabled notification listener using the
> `NotificationListenerService` APIs, in which case you must pass the `ComponentName` of your
> enabled listener."
>
> `@param notificationListener The enabled notification listener component. May be null.`

`addOnActiveSessionsChangedListener` carries the identical sentence, which matters: the **push**
path has the same gate as the **poll** path, so there is no cheaper way in.

`MEDIA_CONTENT_CONTROL` is `signature|privileged` and unavailable to a third-party app, so for Kati
the notification-listener grant is not one of two options — it is the only one.

Source: [MediaSessionManager.java, AOSP](https://android.googlesource.com/platform/prebuilts/fullsdk/sources/android-30/+/refs/heads/androidx-main-release/android/media/session/MediaSessionManager.java)

**Consequence for the design.** Screen 36's "this phone" source cannot be switched on by a runtime
dialog. It requires the user to leave Kati, find Kati in a system Settings list of every app that
wants to read notifications, and grant it there. That is a materially worse affordance than the
screen currently implies, and it is a design fact, not an implementation detail.

---

## Q2 · What does Play policy require? — **PARTIALLY ANSWERED, and the news is better than expected**

`BIND_NOTIFICATION_LISTENER_SERVICE` is **not** on Play's *Permissions and APIs that Access
Sensitive Information* list. That page enumerates the permissions with a declaration form and an
approved-use table — SMS and Call Log, location, accessibility, VPN, body sensors, Health Connect,
all-files access — and notification listener is absent from it.

Source: [Permissions and APIs that Access Sensitive Information](https://support.google.com/googleplay/android-developer/answer/16558241)

So there is **no evidence of a notification-access declaration form**, which is what the ticket
feared. What does apply is the general rule on the same page:

> "Request permissions and APIs that access sensitive information to access data in context (via
> incremental requests), so that users understand why your app is requesting the permission."

and the core-functionality test: a sensitive capability must be necessary for a feature that is
"prominently documented and promoted in the app's description".

**Confidence: medium, and this is the one to re-check before shipping.** Absence from one policy
page is weaker evidence than a policy that names the use case and permits it. A Play Console
account can see the actual declaration flow for a draft app in minutes; that check belongs to the
owner and costs nothing.

---

## Q3 · What must the Data safety form disclose? — **NOT ANSWERED**

Not established from primary sources. The Data safety guidance fetched does not name notification
access or media sessions, and inferring which data types apply — *Messages*, *App activity*,
*Music and audio*, *Other in-app actions* — would be a guess presented as a finding.

What is certain and worth stating anyway: an app that can read notifications can read every
notification, whether or not it looks at them, and the form asks what the app *can* access rather
than what it chooses to. Kati's whole pitch is that nothing leaves the device, so the disclosure
would be "collected: no, accessed: yes" — which is defensible and still needs writing down
honestly.

**This one needs a Play Console session, not more searching.**

---

## Q4 · Does the listener rebind reliably? — **PARTIALLY, and the documentation is thinner than the ticket assumes**

`requestRebind` is narrower than its name suggests. From the framework source:

> `requestRebind(ComponentName)` — "Request that the listener be rebound, after a previous call to
> `requestUnbind`." … "This method will fail for listeners that have not been granted the
> permission by the user."
>
> `onListenerDisconnected()` — "Implement this method to learn about when the listener is
> disconnected from the notification manager. You will not receive any events after this call, and
> may only call `requestRebind(ComponentName)` at this time."

So `requestRebind` is the recovery path for a listener that unbound **itself**. The framework
source does **not** document automatic rebinding after force-stop, app update or reboot — the
behaviour the ticket needs. That is not evidence it fails; it is evidence it is unspecified, which
for a background feature is worse, because it means the answer is per-OEM and per-version and can
only come from measurement.

Source: [NotificationListenerService.java, AOSP](https://android.googlesource.com/platform/frameworks/base/+/refs/heads/main/core/java/android/service/notification/NotificationListenerService.java)

**Must be measured, not read.** Swipe the app away, play music for an hour, reboot, play again.

---

## A finding the ticket did not ask for: Android 15 hardened notification listeners

Android 15 redacts one-time passcodes from notifications before untrusted listeners see them:

> "Android will stop untrusted apps that implement a `NotificationListenerService` from reading
> unredacted content from notifications where an OTP has been detected. Trusted apps such as
> companion device manager associations are exempt."

Source: [Behavior changes: all apps, Android 15](https://developer.android.com/about/versions/15/behavior-changes-all)

**This does not affect scrobbling** — it redacts OTP text, and Kati would read
`MediaSessionManager`, not notification bodies. It is recorded for two reasons: it is the direction
of travel for this API surface, and it establishes that "untrusted app implementing a
NotificationListenerService" is a category Android now actively narrows. A capability being
narrowed twice is a capability to plan an exit from.

---

## Where this leaves #62

Nothing here is a stop. The one hard gate — Play forbidding the use case — did **not** appear, and
that was the cheapest thing to check and the most likely to end the ticket.

What changed is the shape of the risk. It is no longer "can this be built" but three softer facts:

1. **The grant is a system Settings trip**, not a dialog. Screen 36 should draw that honestly.
2. **Rebind behaviour is unspecified**, so reliability is an empirical question per device.
3. **The API surface is being narrowed**, so this is a feature to be able to lose.

Stages 1–6 remain blocked on K-31's manifest-snippet prototype, exactly as #62 says. Nothing above
requires that prototype, and nothing above was worth deferring until it exists.
