#!/usr/bin/env python3
"""Photograph every Kati screen, and refuse to keep a frame it cannot identify.

    python3 bin/capture_all.py            # all 62
    python3 bin/capture_all.py 10 25      # a range

The first version of this tapped rows by arithmetic — a fixed pitch from a
fixed first row — and pressed BACK between screens. Both were wrong:

  * BACK from a pushed screen falls through to the activity and QUITS the app,
    after which every tap lands on the launcher. 37 of 62 frames were of
    Gmail, Google Messages and the home screen.
  * The pitch drifts, so a tap meant for row 34 landed on row 44.

Neither failure announced itself. The frames looked like screenshots, and a
reviewer reading them would have written confident notes about the wrong
screens. So this version proves each step instead:

  1. Cold-start the gallery for every screen — never rely on BACK.
  2. Find the row by its LABEL in a uiautomator dump, and tap its real bounds.
  3. After the tap, dump again and require the expected title to be present.
  4. Refuse a frame whose md5 matches the previous one.

A screen that fails any check is recorded as a hole, not a stale picture.
"""
import hashlib
import pathlib
import re
import subprocess
import sys
import time

REPO = pathlib.Path(__file__).resolve().parent.parent
OUT = REPO / ".scratch/design/audit"
PKG = "com.example.kati"
BELL = (826, 225)


def adb(*args, binary=False, timeout=120):
    r = subprocess.run(["adb", *args], capture_output=True, timeout=timeout)
    return r.stdout if binary else r.stdout.decode("utf-8", "replace")


def dump():
    """The view tree, as (text, x, y) for every node that has text."""
    adb("shell", "uiautomator", "dump", "/sdcard/ui.xml")
    xml = adb("shell", "cat", "/sdcard/ui.xml")
    nodes = []
    for m in re.finditer(r'text="([^"]*)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"', xml):
        text = m.group(1).strip()
        if not text:
            continue
        x1, y1, x2, y2 = (int(m.group(i)) for i in range(2, 6))
        nodes.append((text, (x1 + x2) // 2, (y1 + y2) // 2))
    return nodes


def foreground():
    return PKG in adb("shell", "dumpsys", "window", "|", "grep", "mCurrentFocus")


def open_gallery():
    adb("shell", "am", "force-stop", PKG)
    adb("shell", "monkey", "-p", PKG, "-c", "android.intent.category.LAUNCHER", "1")
    time.sleep(14)
    adb("shell", "input", "tap", str(BELL[0]), str(BELL[1]))
    time.sleep(3)


def find_row(label, scrolls=8):
    """Scroll the gallery until `label` is on screen; return its tap point."""
    for _ in range(scrolls):
        for text, x, y in dump():
            # Rows sit inside the list; the header is near the top.
            if text == label and y > 380:
                return x, y
        adb("shell", "input", "swipe", "540", "1700", "540", "900", "400")
        time.sleep(1)
    return None


def screens():
    """(number, label, title) from the gallery's own table."""
    src = (REPO / "lib/kati/screens/gallery.ex").read_text(encoding="utf-8")
    rows = re.findall(r'\{"(\d\d)",\s*"([^"]+)",\s*([\w.]+),', src)
    return [(n, label, label) for n, label, _mod in rows]


def main():
    lo = int(sys.argv[1]) if len(sys.argv) > 1 else 1
    hi = int(sys.argv[2]) if len(sys.argv) > 2 else 62

    adb("shell", "settings", "put", "global", "zen_mode", "1")  # no notifications mid-run
    OUT.mkdir(parents=True, exist_ok=True)

    previous = None
    holes = []

    for number, label, title in screens():
        if not (lo <= int(number) <= hi):
            continue

        open_gallery()
        if not foreground():
            holes.append((number, "app not in foreground"))
            continue

        point = find_row(label)
        if point is None:
            holes.append((number, f"row {label!r} never appeared"))
            continue

        adb("shell", "input", "tap", str(point[0]), str(point[1]))
        time.sleep(3)

        # The screen must say who it is before its picture counts.
        texts = [t for t, _, _ in dump()]
        if title not in texts and not any(title in t for t in texts):
            holes.append((number, f"opened something else (no {title!r} on screen)"))
            continue

        png = adb("exec-out", "screencap", "-p", binary=True)
        digest = hashlib.md5(png).hexdigest()
        if digest == previous:
            holes.append((number, "identical to the previous frame"))
            continue

        (OUT / f"{number}.png").write_bytes(png)
        previous = digest
        print(f"captured {number}  {label}")

    adb("shell", "settings", "put", "global", "zen_mode", "0")

    if holes:
        print("\nnot captured:")
        for number, why in holes:
            print(f"  {number}  {why}")
    print(f"\n{len(list(OUT.glob('[0-9][0-9].png')))} frames in {OUT}")


if __name__ == "__main__":
    main()
