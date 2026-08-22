#!/usr/bin/env bash
# Full native deploy, with the emulator disk handled first.
#
# A --native deploy needs room for a ~79MB APK AND a ~332MB OTP runtime. When
# /data is short, the APK install fails SILENTLY: `mix mob.deploy` reports
# "not installed (ABI mismatch…)", skips the BEAM push, and the app disappears.
# That failure mode cost real time, so this reclaims first and says what it did.
set -euo pipefail

ADB="${ADB:-$HOME/Library/Android/sdk/platform-tools/adb}"
PKG="com.example.kati"
NEED_MB=520

free_mb() { "$ADB" shell df /data 2>/dev/null | tail -1 | awk '{print int($4/1024)}'; }

before="$(free_mb)"
echo "── /data free: ${before} MB (need ~${NEED_MB} MB) ──"

if [ "$before" -lt "$NEED_MB" ]; then
  echo "   reclaiming…"
  "$ADB" shell pm trim-caches 4000M >/dev/null 2>&1 || true
  # The app's own OTP runtime is the biggest single consumer and is re-pushed
  # by every --native deploy, so clearing it costs nothing but the push.
  "$ADB" shell pm clear "$PKG" >/dev/null 2>&1 || true
  echo "   /data free: $(free_mb) MB after clearing $PKG data + caches"

  # `pm clear` also REVOKES runtime permissions, and the calendar screens then
  # show "0 items" for a reason that has nothing to do with the calendar code.
  # That has been misdiagnosed more than once, so put it back here rather than
  # remembering to do it every time.
  # POST_NOTIFICATIONS is Android 13+. Without it the notification backend
  # reports `permitted: false` and arms nothing — silently, since that is the
  # correct answer to "may I post?" rather than an error. Every deploy would
  # otherwise turn notifications off and look like a scheduler bug.
  for perm in android.permission.READ_CALENDAR android.permission.WRITE_CALENDAR \
              android.permission.POST_NOTIFICATIONS; do
    "$ADB" shell pm grant "$PKG" "$perm" >/dev/null 2>&1 || true
  done
  echo "   re-granted calendar permissions (pm clear revokes them)"
fi

# `mix mob.release --android` stages the OTP tree at
# android/app/src/main/assets/otp.zip for gradle to bundle, and leaves it
# there. Gradle then packs it into the DEBUG apk too, and
# MobBridge.extractOtpIfNeeded() unpacks it over <filesDir>/otp on the next
# clean install — overwriting the BEAMs this script just pushed with
# whatever was compiled when the release ran. The app then runs old code
# with a current source tree, which is indistinguishable from a bug in it.
# The dev path pushes the runtime over adb and never needs this asset.
STRAY_OTP="android/app/src/main/assets/otp.zip"
if [ -f "$STRAY_OTP" ]; then
  echo "── removing $STRAY_OTP (a release leftover that would shadow this deploy) ──"
  rm -f "$STRAY_OTP"
fi

# Stop the app before pushing. A running app with distribution up makes
# `mix mob.deploy` HOT-LOAD the new modules into the live BEAM and skip
# writing them to disk, so the next launch runs the old code and every
# symptom you are chasing is a stale binary.
"$ADB" shell am force-stop "$PKG" >/dev/null 2>&1 || true

mix mob.deploy --native --android "$@"

# Then push the BEAMs again, alone.
#
# The --native pass re-pushes the whole OTP tree, and the copy it pushes
# carries its own older `kati/*.beam` — so a --native deploy can REPLACE the
# app modules it just built with stale ones. Verified by pulling
# Elixir.Kati.App.beam off the device and finding a function that had been
# compiled in minutes earlier was missing again.
echo "── re-pushing BEAMs (a --native push can overwrite them with stale copies) ──"
"$ADB" shell am force-stop "$PKG" >/dev/null 2>&1 || true
exec mix mob.deploy --android
