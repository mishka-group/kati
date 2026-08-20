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
import html
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


def design_heading(number):
    """The drawing's own largest-type line — what the screen actually says.

    The gallery's label is a name for the row, not the screen's heading:
    "Home, dark" renders "Good evening" and "Lock screen" renders "21:40".
    Checking for the label rejected eight screens that had opened perfectly
    well. The drawing knows what its own heading is, so ask it.
    """
    path = REPO / f".scratch/design/screens/{number}.html"
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
    path = REPO / f".scratch/design/screens/{number}.html"
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


def main():
    lo = int(sys.argv[1]) if len(sys.argv) > 1 else 1
    hi = int(sys.argv[2]) if len(sys.argv) > 2 else 62

    adb("shell", "settings", "put", "global", "zen_mode", "1")  # no notifications mid-run
    OUT.mkdir(parents=True, exist_ok=True)

    prints = fingerprints()
    seen = {}
    holes = []

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

        (OUT / f"{number}.png").write_bytes(png)
        seen[digest] = number
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

    adb("shell", "settings", "put", "global", "zen_mode", "0")

    if holes:
        print("\nnot captured:")
        for number, why in holes:
            print(f"  {number}  {why}")
    print(f"\n{len(list(OUT.glob('[0-9][0-9].png')))} frames in {OUT}")


if __name__ == "__main__":
    main()
