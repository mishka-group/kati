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
fi

exec mix mob.deploy --native --android "$@"
