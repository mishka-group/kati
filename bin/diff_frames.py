#!/usr/bin/env python3
"""Compare two capture runs and report where a screen CHANGED at rest.

    python3 bin/diff_frames.py .scratch/design/audit_before .scratch/design/audit

Twenty-five screen files were edited to make their chips and toggles real. The
one rule that outranked everything was that the RESTING appearance must not
change, because each screen is compared against a design frame drawn in its
default state. This is what checks that rule instead of trusting it.

An md5 will not do: the status bar carries a clock, so every frame differs.
So the bars are cropped and the rest compared pixel by pixel, with the
bounding box of any change printed — a band at one y is a row that moved, a
box in the middle is content that changed.

For the opposite question — did a screen change ENOUGH between a light run and
a dark one — see bin/light_vs_dark.py. A clean report here is good news; a
clean report there means the theme was ignored.

This used to `from PIL import Image`, and Pillow is installed for no python3
on this machine, so it has been raising ModuleNotFoundError before printing a
line. The pixels now come from bin/frame_image.py, which uses Pillow when it
is there and macOS's `sips` when it is not.
"""
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

import frame_image as FI  # noqa: E402

STATUS_BAR = 90      # clock, battery, wifi — changes between runs by design
NAV_BAR = 130        # the three-button bar at the bottom
TOLERANCE = 12       # per-channel; JPEG-ish poster resampling is not a change


def compare(a_path, b_path):
    a = FI.load(a_path)
    b = FI.load(b_path)
    if a.size != b.size:
        return f"size {a.size} -> {b.size}", None

    a = a.crop_rows(STATUS_BAR, NAV_BAR)
    b = b.crop_rows(STATUS_BAR, NAV_BAR)

    changed, total, bbox = FI.difference(a, b, TOLERANCE)
    if bbox is None:
        return None, None

    pct = 100.0 * changed / total
    x0, y0, x1, y1 = bbox
    return f"{pct:5.2f}% changed  bbox=({x0},{y0 + STATUS_BAR})-({x1},{y1 + STATUS_BAR})", pct


def main():
    if FI.backend() is None:
        print("!! no image backend: install Pillow, or run where `sips` "
              "exists. Refusing to report a comparison that did not happen.")
        return 3

    before = pathlib.Path(sys.argv[1])
    after = pathlib.Path(sys.argv[2])

    clean, changed, missing = [], [], []
    for b in sorted(before.glob("[0-9][0-9].png")):
        a = after / b.name
        if not a.exists():
            missing.append(b.stem)
            continue
        note, pct = compare(b, a)
        if note is None:
            clean.append(b.stem)
        else:
            changed.append((b.stem, note, pct or 0.0))

    print(f"identical at rest: {len(clean)}/{len(clean) + len(changed)}")
    if missing:
        print(f"missing from the second run: {' '.join(missing)}")
    if changed:
        print("\nCHANGED — each needs a reason, or it is a regression:")
        for stem, note, _pct in sorted(changed, key=lambda c: -c[2]):
            print(f"  {stem}  {note}")
    return 1 if changed else 0


if __name__ == "__main__":
    sys.exit(main())
