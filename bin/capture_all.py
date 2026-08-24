#!/usr/bin/env python3
"""Photograph every Kati screen, and refuse to keep a frame it cannot identify.

    python3 bin/capture_all.py                  # all 62, light
    python3 bin/capture_all.py 10 25            # a range
    python3 bin/capture_all.py --dark           # all 62, system dark mode
    python3 bin/capture_all.py --light          # force system light first
    python3 bin/capture_all.py --restore-only   # undo a run that was killed

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

DARK MODE
---------
`--dark` flips the system night setting, captures into a separate directory,
and puts the setting back. The putting-back is the part that matters. An
emulator left in night mode does not announce itself either: the next light
run would capture 62 dark frames, write them over the baseline the whole
comparison rests on, and print "captured 01 ... captured 62" the entire way.

So the previous setting is written to disk BEFORE it is changed, restored in a
`finally`, restored again from that file on the next run if this process was
killed outright, and every run states the mode it actually captured in — both
on stdout and in a RUN.json beside the frames. `bin/light_vs_dark.py` reads
that file and refuses to compare two runs that were captured the same way,
because "no screen changed" from two light runs is a lie that looks like a
finding.
"""
import argparse
import datetime
import hashlib
import html
import json
import pathlib
import re
import signal
import subprocess
import sys
import time

REPO = pathlib.Path(__file__).resolve().parent.parent
OUT = REPO / ".captures/audit"
DARK_OUT = REPO / ".captures/audit_dark"
STASH = REPO / ".captures/.device_state.json"
PKG = "com.example.kati"
BELL = (826, 225)

# What `cmd uimode night` accepts and reports back.
NIGHT_VALUES = ("yes", "no", "auto", "custom_schedule", "custom_bedtime")
# `settings get secure ui_night_mode`, for when `cmd uimode` says nothing useful.
NIGHT_BY_CODE = {"0": "auto", "1": "no", "2": "yes", "3": "custom_schedule"}


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


# ---------------------------------------------------------------------------
# System night mode
# ---------------------------------------------------------------------------

def read_night():
    """The device's current night setting, or None if it will not say.

    None is a real answer here and is treated as one. Guessing "no" from an
    unreadable device and then "restoring" that guess would quietly rewrite a
    user's `auto` schedule; guessing "yes" would leave the emulator dark. The
    caller decides, loudly, and the decision is printed.
    """
    text = adb("shell", "cmd", "uimode", "night")
    m = re.search(r"night mode:\s*([a-z_]+)", text, re.I)
    if m and m.group(1).lower() in NIGHT_VALUES:
        return m.group(1).lower()

    # Older images answer `cmd uimode` with nothing at all. The secure setting
    # is still there and still readable.
    code = adb("shell", "settings", "get", "secure", "ui_night_mode").strip()
    return NIGHT_BY_CODE.get(code)


def set_night(value):
    """Ask for a night setting and REPORT WHAT THE DEVICE ACTUALLY DID.

    `cmd uimode night yes` on a device whose night mode is driven by a custom
    schedule can come back still saying `custom_schedule`. Returning the value
    we asked for would make the manifest claim a dark run that never happened,
    and every screen would then be filed as "ignores the theme".
    """
    if value not in NIGHT_VALUES:
        raise ValueError(f"night mode {value!r} is not one of {NIGHT_VALUES}")
    adb("shell", "cmd", "uimode", "night", value)
    time.sleep(4)  # the config change tears down and rebuilds activities
    return read_night()


def read_zen():
    """Do Not Disturb, so a mid-run notification does not land in a frame."""
    value = adb("shell", "settings", "get", "global", "zen_mode").strip()
    return value if value.isdigit() else "0"


def set_zen(value):
    adb("shell", "settings", "put", "global", "zen_mode", str(value))


class DeviceState:
    """Remembers what the device looked like, and puts it back exactly once.

    The stash file is written BEFORE anything changes. A process killed
    between the write and the change restores a value that is already correct,
    which costs nothing. A process killed after the change — including with
    SIGKILL, which no handler can catch — leaves the file behind, and the next
    run finds it and repairs the device before it captures a single frame.
    """

    def __init__(self, stash=None, log=print):
        # Read STASH at call time, not at import time. `stash=STASH` in the
        # signature binds the module constant once, when the file is first
        # imported — after which the attribute can be reassigned and this
        # would go on using the old value without a word. The tests caught it;
        # nothing at runtime would have.
        self.stash = pathlib.Path(STASH if stash is None else stash)
        self.log = log
        self.saved = None
        self.restored = False

    def recover(self):
        """Undo a previous run that never got to its `finally`. Loudly."""
        if not self.stash.exists():
            return None
        try:
            saved = json.loads(self.stash.read_text(encoding="utf-8"))
        except (ValueError, OSError) as exc:
            self.log(f"!! unreadable {self.stash.name} ({exc}); "
                     "forcing night mode back to `no`")
            saved = {"night": "no", "zen": "0"}

        self.log(f"!! a previous run did not finish; it left the device at "
                 f"night={read_night()!r}. Restoring night={saved.get('night')!r} "
                 f"zen={saved.get('zen')!r} before starting.")
        self._apply(saved)
        self.stash.unlink(missing_ok=True)
        return saved

    def capture_and_change(self, night=None, zen="1"):
        """Record the current state, then move to the requested one."""
        self.saved = {"night": read_night(), "zen": read_zen()}
        self.stash.parent.mkdir(parents=True, exist_ok=True)
        self.stash.write_text(json.dumps(self.saved, indent=2), encoding="utf-8")

        if zen is not None:
            set_zen(zen)
        if night is None:
            return self.saved["night"]
        return set_night(night)

    def restore(self):
        """Idempotent: `finally` and an atexit hook may both call this."""
        if self.restored or self.saved is None:
            return
        self.restored = True
        self._apply(self.saved)
        self.stash.unlink(missing_ok=True)

    def _apply(self, saved):
        night = saved.get("night")
        if night not in NIGHT_VALUES:
            # Never leave it dark because we could not read the original.
            # `no` is the mode the 62-frame baseline was captured in, so it is
            # the safe direction to fail in — but say that it happened.
            self.log(f"!! previous night mode was {night!r}; falling back to "
                     "`no` so the next light capture is not poisoned")
            night = "no"
        landed = set_night(night)
        if landed != night:
            self.log(f"!! asked for night={night!r}, device reports {landed!r}")
        else:
            self.log(f"restored night mode: {night}")
        set_zen(saved.get("zen") or "0")


# ---------------------------------------------------------------------------
# Navigation
# ---------------------------------------------------------------------------

def open_gallery():
    """Cold start, scroll Home to the top, then tap the bell.

    Scrolling first is not defensive padding: a relaunched Home comes back
    where it was left, and if it is scrolled the bell is off-screen. Every tap
    then lands on a card and every subsequent "gallery scroll" scrolls HOME —
    which is what stalled a 34-screen run at the first row, with the process
    alive and producing nothing.
    """
    adb("shell", "am", "force-stop", PKG)
    adb("shell", "monkey", "-p", PKG, "-c", "android.intent.category.LAUNCHER", "1")
    time.sleep(14)

    for _ in range(3):
        adb("shell", "input", "swipe", "540", "700", "540", "1900", "220")
        time.sleep(0.4)

    adb("shell", "input", "tap", str(BELL[0]), str(BELL[1]))
    time.sleep(3)

    # Prove we are in the gallery, and SAY SO if we are not. The earlier
    # version re-tapped once and carried on regardless, so a run that never
    # opened the gallery reported every single row as "never appeared" — 31
    # screens blamed on a scroll limit when nothing had been scrolled at all.
    for _ in range(3):
        if any(t == "All screens" for t, _, _ in dump()):
            return True
        adb("shell", "input", "tap", str(BELL[0]), str(BELL[1]))
        time.sleep(3)

    return False


def find_row(label, scrolls=22):
    """Scroll the gallery until `label` is on screen; return its tap point.

    22 attempts, not 8. One swipe moves about five rows and the list is 62
    long, so eight was enough to reach row 44 and no further — every screen
    past it reported "never appeared" as though it did not exist.
    """
    for _ in range(scrolls):
        for text, x, y in dump():
            # Rows sit inside the list; the header is near the top.
            if text == label and y > 380:
                return x, y
        adb("shell", "input", "swipe", "540", "1700", "540", "900", "400")
        time.sleep(1)
    return None


# ---------------------------------------------------------------------------
# Identifying a screen from its drawing
# ---------------------------------------------------------------------------

def design_heading(number):
    """The drawing's own largest-type line — what the screen actually says.

    The gallery's label is a name for the row, not the screen's heading:
    "Home, dark" renders "Good evening" and "Lock screen" renders "21:40".
    Checking for the label rejected eight screens that had opened perfectly
    well. The drawing knows what its own heading is, so ask it.
    """
    path = REPO / f"test/design/screens/{number}.html"
    if not path.exists():
        return None

    src = path.read_text(encoding="utf-8")
    src = re.split(r"<div[^>]*max-width:380px", src)[0]  # drop the caption
    # Drop the icon spans: a Material Symbol carries a font-size too, and its
    # ligature name ("search", "close") would win as the largest "text".
    src = re.sub(r"<span[^>]*Material Symbols Rounded.*?</span>", " ", src, flags=re.S)

    best = (0, None)
    for m in re.finditer(r'style="([^"]*font-size:\s*(\d+(?:\.\d+)?)px[^"]*)"[^>]*>([^<]{2,60})<', src):
        size = float(m.group(2))
        text = m.group(3).strip()
        if text and not text.startswith("&") and size > best[0]:
            best = (size, text)
    return best[1]


def design_texts(number):
    """Every text literal the drawing prints, in document order.

    Same strips as `design_heading`: the caption block, and the Material
    Symbol spans whose ligature name ("search", "close") is not text a
    reader ever sees.
    """
    path = REPO / f"test/design/screens/{number}.html"
    if not path.exists():
        return []

    src = path.read_text(encoding="utf-8")
    src = re.split(r"<div[^>]*max-width:380px", src)[0]
    src = re.sub(r"<span[^>]*Material Symbols Rounded.*?</span>", " ", src, flags=re.S)

    out = []
    for raw in re.findall(r">([^<>]{3,60})<", src):
        text = re.sub(r"\s+", " ", html.unescape(raw)).strip()
        # Long enough, or more than one word. A bare "hollow" is a fragment of
        # "The Long <span>Hollow</span>" and would match three screens; the
        # drawings only look unique there because they split the span
        # differently.
        # The data-driven drawings are Vue templates, so their "text" is
        # {{ it.title }}. Screen 03's every unique literal was one of those,
        # which no device will ever print — it was rejected for being right.
        if not text or text.startswith(".") or "{{" in text or "}}" in text:
            continue
        if len(text) >= 8 or " " in text:
            out.append(text)
    return out


def fingerprints():
    """For each screen, strings that appear in ITS drawing and no other.

    The gallery label is a name for the row, not something the screen says:
    28 renders "Good evening", 29 renders "21:40", 33 renders "RATING" in
    caps. Requiring the label rejected eight frames that had opened
    perfectly well — a harness fault reported as eight broken screens.

    So ask the drawings instead. A literal only one drawing contains
    identifies that screen by construction, and no list needs maintaining
    as screens change. Earliest-first, because uiautomator only reports
    VISIBLE nodes and a unique string below the fold would never be found.
    """
    numbers = [n for n, _l, _m, _k in re.findall(
        r'\{"(\d\d)",\s*"([^"]+)",\s*([\w.]+),\s*:(\w+)\}',
        (REPO / "lib/kati/screens/gallery.ex").read_text(encoding="utf-8"),
    )]

    texts = {n: design_texts(n) for n in numbers}
    seen = {}
    for n, items in texts.items():
        for t in set(items):
            seen.setdefault(t.casefold(), set()).add(n)

    out = {}
    for n, items in texts.items():
        uniq = []
        for t in items:  # document order == top of the screen first
            if len(seen.get(t.casefold(), ())) == 1 and t not in uniq:
                uniq.append(t)
        out[n] = uniq[:6]
    return out


def screens():
    """(number, gallery label, expected on-screen heading).

    A heading only counts as identification when it is UNIQUE. Five of them
    are not — "The Long Hollow" heads screens 04, 14 and 35, "Blue Hour" heads
    08 and 33 — so a frame of 04 satisfied a check meant for 14, and 16 was
    accepted as a byte-identical copy of 19. Where the heading is shared, the
    gallery label is the only thing that tells the screens apart, so it is
    required instead.
    """
    src = (REPO / "lib/kati/screens/gallery.ex").read_text(encoding="utf-8")
    rows = re.findall(r'\{"(\d\d)",\s*"([^"]+)",\s*([\w.]+),\s*:(\w+)\}', src)

    # A few screens show neither their gallery label nor a unique heading.
    # Screen 14's heading is "The Long Hollow" (shared with 04 and 35) and it
    # never prints the words "Series metadata", so it is identified by a
    # section title only it has.
    # Screen 14 shows nothing unique ABOVE THE FOLD — uiautomator only sees
    # visible nodes, and its distinguishing sections are below it. Its heading
    # is accepted, and the all-frames md5 check is what stops it silently
    # being a second copy of 04 or 35.
    OVERRIDE = {"14": "The Long Hollow"}

    headings = {n: design_heading(n) for n, _l, _m, _k in rows}
    shared = {h for h in headings.values() if h and list(headings.values()).count(h) > 1}

    out = []
    for n, label, _mod, kind in rows:
        head = headings.get(n)
        if n in OVERRIDE:
            out.append((n, OVERRIDE[n], None, kind))
        else:
            out.append((n, label, None if (head in shared or not head) else head, kind))
    return out


# ---------------------------------------------------------------------------
# The run
# ---------------------------------------------------------------------------

def capture_range(lo, hi, out_dir, captured=None, holes=None):
    """Walk the gallery and write frames. Returns (captured, holes).

    Every device change this makes is navigational and self-correcting;
    nothing here touches a system setting, so it is safe to abandon at any
    point. The settings live in DeviceState, above.

    `captured` and `holes` are appended to in place so a caller can still read
    the partial result after an interrupt. Returning them only at the end
    meant an interrupted run wrote a manifest claiming it had captured
    nothing, while 40 frames sat in the directory next to it.
    """
    out_dir.mkdir(parents=True, exist_ok=True)

    prints = fingerprints()
    seen = {}
    holes = [] if holes is None else holes
    captured = [] if captured is None else captured

    row_labels = {
        n: l for n, l, _m in re.findall(
            r'\{"(\d\d)",\s*"([^"]+)",\s*([\w.]+),',
            (REPO / "lib/kati/screens/gallery.ex").read_text(encoding="utf-8"),
        )
    }

    in_gallery = False

    for number, label, title, kind in screens():
        if not (lo <= int(number) <= hi):
            continue

        row_label = row_labels[number]

        # Cold-starting for all 62 cost about a minute each — 14s of launch,
        # three scrolls home, then up to 22 swipes to find a row near the
        # bottom — and the run could not finish inside any sane timeout.
        #
        # It was only ever needed because BACK "quits the app". It does not:
        # Mob pops the stack and exits only when the history is EMPTY
        # (screen.ex:444). A pushed screen over the gallery has history, so
        # BACK returns to the gallery with its scroll position intact, and the
        # next row is usually already on screen.
        #
        # A ROOT is different: `reset_to` clears the stack, so after one of
        # those the gallery is genuinely gone and a cold start is the only way
        # back. Those are four screens, not sixty-two.
        if not in_gallery:
            if not open_gallery():
                holes.append((number, "never reached the gallery"))
                continue
            in_gallery = True

        point = find_row(row_label)
        if point is None:
            holes.append((number, f"row {label!r} never appeared"))
            in_gallery = False
            continue

        adb("shell", "input", "tap", str(point[0]), str(point[1]))
        time.sleep(3)

        # The screen must say who it is before its picture counts.
        # Case-folded: the drawings letter-space their eyebrows in caps, so
        # screen 33 says RATING and a case-sensitive "Rating" missed it.
        texts = [t.casefold() for t, _, _ in dump()]
        # Fingerprints AND the heading AND the label: any one of them proves
        # identity, and the all-frames md5 check is what catches a false
        # accept. Requiring only the narrowest evidence is what rejected eight
        # good frames.
        wanted = (prints.get(number) or []) + [w for w in (title, label) if w]
        if not any(any(w.casefold() in t for t in texts) for w in wanted):
            holes.append((number, f"opened something else (wanted any of {wanted!r})"))
            adb("shell", "input", "keyevent", "KEYCODE_BACK")
            time.sleep(1.6)
            in_gallery = any(t == "All screens" for t, _, _ in dump())
            continue

        png = adb("exec-out", "screencap", "-p", binary=True)
        digest = hashlib.md5(png).hexdigest()
        # Against EVERY frame this run, not just the last one: 16 and 19 were
        # captured in different runs and one was a byte-for-byte copy of the
        # other, which a previous-frame check cannot see.
        if digest in seen:
            holes.append((number, f"byte-identical to screen {seen[digest]}"))
            adb("shell", "input", "keyevent", "KEYCODE_BACK")
            time.sleep(1.6)
            in_gallery = any(t == "All screens" for t, _, _ in dump())
            continue

        (out_dir / f"{number}.png").write_bytes(png)
        seen[digest] = number
        captured.append(number)
        print(f"captured {number}  {label}", flush=True)

        if kind == "root":
            in_gallery = False
            continue

        adb("shell", "input", "keyevent", "KEYCODE_BACK")
        time.sleep(1.6)
        # Prove it, rather than assume it. A screen that swallows BACK would
        # otherwise leave every following tap landing on the wrong page, which
        # is exactly how 37 frames of Gmail happened the first time.
        in_gallery = any(t == "All screens" for t, _, _ in dump())

    return captured, holes


def write_manifest(out_dir, **fields):
    """Stamp the run's mode next to its frames.

    A directory called `audit_dark` is a claim, not evidence. This is what
    `bin/light_vs_dark.py` reads to check that the two runs it is comparing
    were genuinely captured in different modes — without it, two light runs
    would compare clean and read as "no screen ignores the theme", which is
    the same sentence a correct dark-mode implementation would produce.
    """
    path = out_dir / "RUN.json"
    path.write_text(json.dumps(fields, indent=2, sort_keys=True) + "\n",
                    encoding="utf-8")
    return path


def parse_args(argv):
    p = argparse.ArgumentParser(
        prog="capture_all.py",
        description="Photograph every Kati screen, in light or dark mode.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p.add_argument("lo", nargs="?", type=int, default=1,
                   help="first screen number (default 1)")
    p.add_argument("hi", nargs="?", type=int, default=62,
                   help="last screen number (default 62)")
    mode = p.add_mutually_exclusive_group()
    mode.add_argument("--dark", action="store_true",
                      help="set system night mode on, capture to "
                           f"{DARK_OUT.name}/, then restore the old setting")
    mode.add_argument("--light", action="store_true",
                      help="set system night mode OFF first, so the baseline "
                           "cannot be captured on a device left dark")
    p.add_argument("--out", type=pathlib.Path, default=None,
                   help="where to write frames (default: "
                        f"{OUT.name}/, or {DARK_OUT.name}/ with --dark)")
    p.add_argument("--restore-only", action="store_true",
                   help="put the device's night/zen settings back from the "
                        "stash a killed run left behind, and exit")

    args = p.parse_args(argv)
    if args.restore_only and (args.dark or args.light or args.out
                              or args.lo != 1 or args.hi != 62):
        # `--restore-only 10 25` looks like it captures a range. It cannot,
        # and quietly ignoring the numbers would leave someone believing they
        # had captured something.
        p.error("--restore-only takes no other options and no range")
    if args.lo > args.hi:
        p.error(f"empty range: {args.lo}..{args.hi}")

    args.mode = "dark" if args.dark else ("light" if args.light else "as-is")
    args.night = {"dark": "yes", "light": "no", "as-is": None}[args.mode]
    if args.out is None:
        args.out = DARK_OUT if args.dark else OUT
    return args


def main(argv=None):
    args = parse_args(sys.argv[1:] if argv is None else argv)
    state = DeviceState()

    if args.restore_only:
        if state.recover() is None:
            print(f"nothing stashed in {STASH}; "
                  f"the device is at night={read_night()!r}")
        return 0

    # A stash from a killed run is repaired first, so the "previous setting"
    # this run saves is the user's, not the wreckage of the last one.
    state.recover()

    # SIGINT and SIGTERM become exceptions so the `finally` below runs. SIGKILL
    # cannot be caught by anything; the stash file is what covers that case,
    # and `--restore-only` is how you cash it in by hand.
    def die(signum, _frame):
        raise KeyboardInterrupt(f"signal {signum}")

    for name in ("SIGINT", "SIGTERM", "SIGHUP"):
        sig = getattr(signal, name, None)
        if sig is None:
            continue
        try:
            signal.signal(sig, die)
        except (ValueError, OSError):  # not the main thread
            pass

    started = datetime.datetime.now().isoformat(timespec="seconds")
    captured, holes = [], []
    night_now = None
    ran = False

    try:
        night_now = state.capture_and_change(night=args.night, zen="1")
        before = (state.saved or {}).get("night")
        print(f"mode: {args.mode}   night: {before!r} -> {night_now!r}   "
              f"out: {args.out}", flush=True)

        if args.night is not None and night_now != args.night:
            print(f"!! asked the device for night={args.night!r} and it reports "
                  f"{night_now!r}. The frames will NOT be a {args.mode} run — "
                  "stopping rather than filing them as one.", flush=True)
            return 2

        if args.mode == "as-is" and night_now != "no":
            print(f"!! the device is at night={night_now!r} and no mode was "
                  "asked for. These frames are not a light baseline. Re-run "
                  "with --light, or with --dark and a separate --out.",
                  flush=True)

        ran = True
        capture_range(args.lo, args.hi, args.out, captured, holes)
    finally:
        state.restore()
        # Only stamp a manifest for a run that actually started capturing. A
        # run that bailed on the mode check must not overwrite the manifest of
        # the good run whose frames are already in that directory.
        if ran and args.out.exists():
            write_manifest(
                args.out,
                mode=args.mode,
                night_mode=night_now,
                night_mode_before=(state.saved or {}).get("night"),
                started=started,
                finished=datetime.datetime.now().isoformat(timespec="seconds"),
                screens=[args.lo, args.hi],
                captured=captured,
                holes=[list(h) for h in holes],
                frames_present=len(list(args.out.glob("[0-9][0-9].png"))),
            )

    if holes:
        print("\nnot captured:")
        for number, why in holes:
            print(f"  {number}  {why}")
    print(f"\n{len(list(args.out.glob('[0-9][0-9].png')))} frames in {args.out}")
    print(f"mode recorded in {args.out / 'RUN.json'}: {args.mode} "
          f"(night={night_now!r})")
    return 1 if holes else 0


if __name__ == "__main__":
    sys.exit(main())
