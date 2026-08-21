#!/usr/bin/env python3
"""Per screen: did anything change at all between the light run and the dark one?

    python3 bin/light_vs_dark.py
    python3 bin/light_vs_dark.py .scratch/design/audit_v7 .scratch/design/audit_dark

`bin/diff_frames.py` answers "did this screen stay the same when it was
supposed to", and its good news is a clean report. This script asks the
opposite question, so its good news is the opposite too: a screen that is
IDENTICAL in light and dark is a screen that ignored the theme, and that is a
defect, not a pass.

The distinction matters because the two failures print the same sentence. If
the dark run was actually captured in light mode — an emulator someone left
alone, a `--dark` flag forgotten, a killed run that never restored the setting
— then every screen compares identical, and "62 screens ignore the theme"
looks exactly like a thorough finding. So this refuses to compare two runs
that RUN.json says were captured the same way, and says why.

What is measured, and why it is not an md5:

  * The status bar carries a clock and the nav bar carries a gesture pill, and
    both differ between any two runs. Cropped, as in diff_frames.py.
  * A screen is then compared pixel by pixel with a tolerance, and reported by
    how MUCH of it moved and by how far its brightness fell. A screen whose
    theme works drops tens of luma points. A screen where only a ripple or a
    focus ring moved shows a fraction of a percent and no luma change at all,
    which is a different defect wearing the same clothes as a pass.
"""
import argparse
import json
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

import frame_image as FI  # noqa: E402

REPO = pathlib.Path(__file__).resolve().parent.parent
LIGHT = REPO / ".scratch/design/audit_v7"
DARK = REPO / ".scratch/design/audit_dark"

STATUS_BAR = 90   # clock, battery, wifi — differ between runs by design
NAV_BAR = 130     # the three-button bar at the bottom
TOLERANCE = 12    # per-channel; poster resampling is not a change

# Below this share of pixels, a screen did not repaint — something small
# twitched. Reported separately from a clean pass, because "0.3% changed" and
# "the theme works" are not the same claim.
MIN_PCT = 1.0
# A screen that really went dark loses this much average brightness or more.
MIN_LUMA_DROP = 20.0
# A screen already this dark in the LIGHT run was drawn dark on purpose — 28
# (Home, dark) and 29 (Lock screen) are the design's own dark drawings — so
# "did not change" means something different for them and the report says so
# rather than filing them with the rest.
ALREADY_DARK = 90.0


def labels():
    """Gallery number -> row label, so the report names screens, not files."""
    try:
        import capture_all
        return {n: label for n, label, _t, _k in capture_all.screens()}
    except Exception:  # the report is still useful without names
        return {}


def manifest(path):
    f = path / "RUN.json"
    if not f.exists():
        return None
    try:
        return json.loads(f.read_text(encoding="utf-8"))
    except (ValueError, OSError):
        return None


def describe(path, man):
    frames = len(list(path.glob("[0-9][0-9].png")))
    if man is None:
        return f"{path}  {frames} frames  (no RUN.json — mode UNVERIFIED)"
    return (f"{path}  {frames} frames  mode={man.get('mode')!r} "
            f"night={man.get('night_mode')!r}")


def check_modes(light_man, dark_man, out=print):
    """Refuse a comparison that cannot mean anything. Returns True to proceed."""
    if light_man is None or dark_man is None:
        out("!! at least one run has no RUN.json, so nothing here proves the "
            "two were captured in different modes. Re-capture with "
            "bin/capture_all.py --light and --dark to get one.")
        return True

    ln, dn = light_man.get("night_mode"), dark_man.get("night_mode")
    if ln == dn:
        out(f"!! BOTH runs record night={ln!r}. Comparing them proves nothing: "
            "every screen would read as identical whether or not dark mode "
            "works. Re-capture the dark run with `bin/capture_all.py --dark`.")
        return False
    if dn != "yes":
        out(f"!! the run given as dark records night={dn!r}, not 'yes'.")
        return False
    return True


def compare_one(light_png, dark_png, tolerance):
    """(pct_changed, bbox, luma_light, luma_dark) or a string explaining why not."""
    a = FI.load(light_png)
    b = FI.load(dark_png)
    if a.size != b.size:
        return f"size {a.size} vs {b.size}"

    try:
        a = a.crop_rows(STATUS_BAR, NAV_BAR)
        b = b.crop_rows(STATUS_BAR, NAV_BAR)
    except FI.FrameError as exc:
        return str(exc)

    changed, total, bbox = FI.difference(a, b, tolerance)
    pct = 100.0 * changed / total
    return pct, bbox, FI.mean_luma(a), FI.mean_luma(b)


def main(argv=None):
    p = argparse.ArgumentParser(
        prog="light_vs_dark.py",
        description="Report, per screen, whether it changed at all between a "
                    "light capture and a dark one.")
    p.add_argument("light", nargs="?", type=pathlib.Path, default=LIGHT,
                   help=f"the light run (default {LIGHT.name}/, the 62-frame "
                        "baseline). A fresh `capture_all.py --light` writes to "
                        "audit/ instead — name it explicitly.")
    p.add_argument("dark", nargs="?", type=pathlib.Path, default=DARK,
                   help=f"the dark run (default {DARK.name}/)")
    p.add_argument("--tolerance", type=int, default=TOLERANCE,
                   help=f"per-channel difference that counts (default {TOLERANCE})")
    p.add_argument("--min-pct", type=float, default=MIN_PCT,
                   help=f"below this %% of pixels a screen only twitched "
                        f"(default {MIN_PCT})")
    p.add_argument("--force", action="store_true",
                   help="compare even when RUN.json says the two runs were "
                        "captured the same way")
    args = p.parse_args(sys.argv[1:] if argv is None else argv)

    if FI.backend() is None:
        print("!! no image backend: install Pillow, or run on a machine with "
              "`sips`. Refusing to report a comparison that did not happen.")
        return 3

    for d in (args.light, args.dark):
        if not d.is_dir():
            print(f"!! no such directory: {d}")
            return 3

    light_man, dark_man = manifest(args.light), manifest(args.dark)
    print(f"backend: {FI.backend()}")
    print(f"light: {describe(args.light, light_man)}")
    print(f"dark : {describe(args.dark, dark_man)}")
    print()

    if not check_modes(light_man, dark_man, print) and not args.force:
        print("\n(pass --force to compare anyway)")
        return 2

    names = labels()
    identical, twitched, responded, broken, missing = [], [], [], [], []

    for light_png in sorted(args.light.glob("[0-9][0-9].png")):
        n = light_png.stem
        dark_png = args.dark / light_png.name
        if not dark_png.exists():
            missing.append(n)
            continue

        result = compare_one(light_png, dark_png, args.tolerance)
        if isinstance(result, str):
            broken.append((n, result))
            continue

        pct, bbox, luma_l, luma_d = result
        row = (n, names.get(n, ""), pct, bbox, luma_l, luma_d)
        if pct == 0.0:
            identical.append(row)
        elif pct < args.min_pct:
            twitched.append(row)
        else:
            responded.append(row)

    def line(row):
        n, name, pct, _bbox, luma_l, luma_d = row
        note = ""
        if luma_l < ALREADY_DARK:
            note = "  (already dark in the light run — drawn that way by design)"
        elif pct > 0.0 and luma_l - luma_d < MIN_LUMA_DROP:
            # Only meaningful for a screen that actually repainted. Saying
            # "repainted but did not darken" about a pixel-identical frame is
            # a contradiction, and a report that contradicts itself is one a
            # reader stops trusting.
            note = f"  (repainted but did not darken: {luma_l - luma_d:+.1f} luma)"
        return (f"  {n}  {name[:26]:<26} {pct:6.2f}% changed   "
                f"luma {luma_l:5.1f} -> {luma_d:5.1f}{note}")

    total = len(identical) + len(twitched) + len(responded)

    if identical:
        print(f"IGNORES THE THEME — pixel-identical in light and dark "
              f"({len(identical)}/{total}):")
        for row in sorted(identical, key=lambda r: r[0]):
            print(line(row))
        print()

    if twitched:
        print(f"BARELY MOVED — under {args.min_pct}% of pixels, so the screen "
              f"did not repaint ({len(twitched)}/{total}):")
        for row in sorted(twitched, key=lambda r: r[2]):
            print(line(row))
        print()

    stubborn = [r for r in responded if r[4] >= ALREADY_DARK
                and r[4] - r[5] < MIN_LUMA_DROP]
    if stubborn:
        print(f"CHANGED BUT DID NOT DARKEN — something moved, the palette did "
              f"not ({len(stubborn)}/{total}):")
        for row in sorted(stubborn, key=lambda r: r[4] - r[5]):
            print(line(row))
        print()

    if broken:
        print(f"could not be compared ({len(broken)}):")
        for n, why in broken:
            print(f"  {n}  {why}")
        print()

    if missing:
        print(f"missing from the dark run ({len(missing)}): {' '.join(missing)}")
        print()

    good = len(responded) - len(stubborn)
    print(f"responded to dark mode: {good}/{total}")
    for row in sorted(responded, key=lambda r: -(r[4] - r[5])):
        if row not in stubborn:
            print(line(row))

    # A screen that never changed is the defect this whole round exists to
    # find, so the exit code says so rather than leaving it to whoever reads
    # the scrollback.
    failed = len(identical) + len(twitched) + len(stubborn)
    print()
    if failed:
        print(f"{failed} of {total} screens did not follow the system theme.")
    elif total == 0:
        print("!! nothing was compared — no frames matched in both runs.")
        return 3
    else:
        print(f"all {total} screens followed the system theme.")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
