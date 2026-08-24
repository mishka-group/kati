#!/usr/bin/env bash
# Walk Kati.Screens.Gallery and photograph every screen.
#
# It re-opens the gallery from a cold start before EVERY tap, rather than
# pressing BACK between screens. That is slower and it is the only thing that
# works: a pushed screen that does not handle the hardware back button lets it
# fall through to the activity, which EXITS THE APP — after which every
# subsequent tap lands on the launcher and the captures are of other people's
# apps. 37 of 62 were photographed that way before this was noticed.
set -u
ADB="${ADB:-adb}"
PKG=com.example.kati
OUT=.captures/audit
FIRST_Y=518      # centre of row 1, device px
PITCH=161        # row to row
PER_PAGE=11      # rows fully on screen before a scroll is needed

mkdir -p "$OUT"

open_gallery() {
  "$ADB" shell am force-stop $PKG
  "$ADB" shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
  sleep 14
  "$ADB" shell input tap 826 225   # the bell
  sleep 3
}

for i in $(seq "${FROM:-10}" "${TO:-62}"); do
  idx=$((i - 1))
  want_page=$((idx / PER_PAGE))
  slot=$((idx % PER_PAGE))

  open_gallery
  for _ in $(seq 1 "$want_page"); do
    "$ADB" shell input swipe 540 1700 540 $((1700 - PER_PAGE * PITCH)) 500
    sleep 1
  done

  y=$((FIRST_Y + slot * PITCH))
  "$ADB" shell input tap 500 "$y"
  sleep 3
  printf -v n "%02d" "$i"
  "$ADB" exec-out screencap -p > "$OUT/$n.png"
  echo "captured $n"
done
