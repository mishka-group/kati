#!/usr/bin/env bash
# Walk Kati.Screens.Gallery and photograph every screen.
#
# The gallery pushes, so BACK always returns to it — the loop never has to
# find its way home. Rows are a fixed pitch, and the list scrolls in whole
# rows, so a row index maps to a tap without hunting.
set -u
ADB="${ADB:-adb}"
PKG=com.example.kati
OUT=.scratch/design/audit
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

open_gallery
page=0

for i in $(seq "${FROM:-10}" "${TO:-62}"); do
  idx=$((i - 1))                    # zero-based row
  want_page=$((idx / PER_PAGE))
  slot=$((idx % PER_PAGE))

  if [ "$want_page" -ne "$page" ]; then
    # Re-open and scroll from the top: scrolling is more reliable forwards
    # than trying to track position across pushes.
    open_gallery
    for _ in $(seq 1 "$want_page"); do
      "$ADB" shell input swipe 540 1700 540 $((1700 - PER_PAGE * PITCH)) 500
      sleep 1
    done
    page=$want_page
  fi

  y=$((FIRST_Y + slot * PITCH))
  "$ADB" shell input tap 500 "$y"
  sleep 3
  printf -v n "%02d" "$i"
  "$ADB" exec-out screencap -p > "$OUT/$n.png"
  echo "captured $n"
  "$ADB" shell input keyevent KEYCODE_BACK
  sleep 2
done
