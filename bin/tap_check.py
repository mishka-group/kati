#!/usr/bin/env python3
"""Open a screen, tap a control by its label, and photograph the result.

    python3 bin/tap_check.py 03 "Watching" after.png
    python3 bin/tap_check.py 04 "S1" s1.png --before before.png

A control that changes nothing is a lie told in pixels, and the only way to
know it changed is to press it and look. This reuses the capture harness's
gallery navigation so the screen is reached the same proven way.
"""
import argparse
import pathlib
import sys
import time

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import capture_all as cap


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("number")
    ap.add_argument("label", help="text of the control to tap")
    ap.add_argument("out")
    ap.add_argument("--before", help="also save the untapped screen here")
    ap.add_argument("--nth", type=int, default=0, help="which match, when the label repeats")
    args = ap.parse_args()

    rows = {n: (label, title, kind) for n, label, title, kind in cap.screens()}
    row_label, _title, _kind = rows[args.number]

    if not cap.open_gallery():
        sys.exit("never reached the gallery")

    point = cap.find_row(row_label)
    if point is None:
        sys.exit(f"row {row_label!r} never appeared")

    cap.adb("shell", "input", "tap", str(point[0]), str(point[1]))
    time.sleep(3)

    if args.before:
        pathlib.Path(args.before).write_bytes(cap.adb("exec-out", "screencap", "-p", binary=True))

    matches = [(t, x, y) for t, x, y in cap.dump() if t.casefold() == args.label.casefold()]
    if not matches:
        loose = [(t, x, y) for t, x, y in cap.dump() if args.label.casefold() in t.casefold()]
        if not loose:
            print("labels on screen:", sorted({t for t, _, _ in cap.dump()}))
            sys.exit(f"no control labelled {args.label!r}")
        matches = loose

    if args.nth >= len(matches):
        sys.exit(f"only {len(matches)} match(es) for {args.label!r}")

    text, x, y = matches[args.nth]
    print(f"tapping {text!r} at ({x},{y})")
    cap.adb("shell", "input", "tap", str(x), str(y))
    time.sleep(2)

    pathlib.Path(args.out).write_bytes(cap.adb("exec-out", "screencap", "-p", binary=True))
    print("saved", args.out)


if __name__ == "__main__":
    main()
