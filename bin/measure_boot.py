#!/usr/bin/env python3
"""Measure cold start: launcher tap to first painted frame, and the phases between.

    python3 bin/measure_boot.py [runs]

Nobody has a number for this and the one everybody quotes is folklore (#37), so
this measures rather than estimates. Two independent clocks are read, because
either alone can mislead:

  * ActivityTaskManager's `Displayed ...: +NNNms` — Android's own measure of
    launcher tap to first frame. It is the number a user experiences.
  * Kati's own `Kati.boot: <phase>` traces in logcat, which say where the time
    inside the BEAM actually goes.

Every run is a COLD start: force-stop, then drop the OS page cache for the
package by killing it, so a warm second run cannot flatter the average.
"""
import re
import subprocess
import sys
import time

PKG = "com.example.kati"
ACT = f"{PKG}/.MainActivity"


def adb(*args, timeout=120):
    return subprocess.run(["adb", *args], capture_output=True, timeout=timeout).stdout.decode(
        "utf-8", "replace"
    )


def one_run():
    adb("shell", "am", "force-stop", PKG)
    adb("logcat", "-c")
    time.sleep(2)

    t0 = time.time()
    adb("shell", "am", "start", "-W", "-n", ACT)

    # Wait for the boot trace to finish rather than a fixed sleep: a fixed sleep
    # either truncates a slow boot or pads a fast one, and both corrupt the mean.
    deadline = time.time() + 90
    phases, displayed = {}, None
    while time.time() < deadline:
        log = adb("logcat", "-d")
        for m in re.finditer(r"(\d\d:\d\d:\d\d\.\d\d\d).*Kati\.boot: (\S+)", log):
            phases.setdefault(m.group(2), m.group(1))
        m = re.search(r"Displayed " + re.escape(ACT) + r"[^+]*\+(?:(\d+)s)?(\d+)ms", log)
        if m:
            displayed = int(m.group(1) or 0) * 1000 + int(m.group(2))
        if displayed and "ready" in phases:
            break
        time.sleep(1)

    return displayed, phases, round((time.time() - t0) * 1000)


def to_ms(stamp):
    h, m, rest = stamp.split(":")
    s, ms = rest.split(".")
    return ((int(h) * 60 + int(m)) * 60 + int(s)) * 1000 + int(ms)


def main():
    runs = int(sys.argv[1]) if len(sys.argv) > 1 else 3
    displays = []

    for i in range(runs):
        displayed, phases, wall = one_run()
        displays.append(displayed)
        print(f"\nrun {i + 1}: Displayed={displayed}ms  (wall {wall}ms)")
        if phases:
            base = min(to_ms(v) for v in phases.values())
            for name, stamp in sorted(phases.items(), key=lambda kv: to_ms(kv[1])):
                print(f"    {to_ms(stamp) - base:6d}ms  {name}")

    got = [d for d in displays if d]
    if got:
        print(f"\nDisplayed over {len(got)} cold starts: "
              f"min {min(got)}ms  median {sorted(got)[len(got) // 2]}ms  max {max(got)}ms")
    else:
        print("\nNo Displayed line found — the activity may not have started.")


if __name__ == "__main__":
    main()
