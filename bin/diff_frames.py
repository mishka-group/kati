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
"""
import pathlib
import sys

from PIL import Image, ImageChops

STATUS_BAR = 90      # clock, battery, wifi — changes between runs by design
NAV_BAR = 130        # the three-button bar at the bottom
TOLERANCE = 12       # per-channel; JPEG-ish poster resampling is not a change


def compare(a_path, b_path):
    a = Image.open(a_path).convert("RGB")
    b = Image.open(b_path).convert("RGB")
    if a.size != b.size:
        return f"size {a.size} -> {b.size}", None

    w, h = a.size
    box = (0, STATUS_BAR, w, h - NAV_BAR)
    a, b = a.crop(box), b.crop(box)

    diff = ImageChops.difference(a, b)
    # Any channel over the tolerance counts; `point` then `convert` gives a
    # mask whose bbox is the region that actually moved.
    mask = diff.convert("L").point(lambda v: 255 if v > TOLERANCE else 0)
    bbox = mask.getbbox()
    if bbox is None:
        return None, None

    changed = sum(1 for p in mask.getdata() if p)
    pct = 100.0 * changed / (mask.width * mask.height)
    x0, y0, x1, y1 = bbox
    return f"{pct:5.2f}% changed  bbox=({x0},{y0 + STATUS_BAR})-({x1},{y1 + STATUS_BAR})", pct


def main():
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


if __name__ == "__main__":
    main()
