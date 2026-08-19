#!/usr/bin/env python3
"""Every literal the design draws, checked against the built screen.

    python3 bin/check_screen.py 03 lib/kati/screens/library.ex

Lists the text and the Material Symbols the drawing contains that do not
appear in the source. Eyeballing a comparison catches layout; it does not
catch a missing word, a dropped icon or a chip nobody noticed. This does.

Templated values (`{{ x }}`) are skipped — those come from data, not markup —
and so are pure numbers, which appear in styles as often as in copy.
"""
import html as H
import pathlib
import re
import sys

N = sys.argv[1].zfill(2)
SOURCES = [pathlib.Path(p) for p in sys.argv[2:]]

design = pathlib.Path(f".scratch/design/screens/{N}.html").read_text(encoding="utf-8")
source = "\n".join(p.read_text(encoding="utf-8") for p in SOURCES)

icons = set(re.findall(r"Material Symbols Rounded[^>]*>([a-z0-9_]+)</span>", design))

text = re.sub(r"<span[^>]*Material Symbols Rounded.*?</span>", " ", design, flags=re.S)
text = re.sub(r"<[^>]+>", "\n", text)
words = set()
for line in H.unescape(text).split("\n"):
    line = line.strip()
    if not line or "{{" in line or line.startswith("!--"):
        continue
    if re.fullmatch(r"[\d\s.,:%·—–-]+", line):
        continue
    # The export puts an explanatory caption after each frame, and the next
    # screen's own "NN — Name" header. Neither is part of the screen.
    if re.match(r"^\d\d\s+—", line) or len(line) > 90:
        continue
    words.add(line)

missing_text = sorted(w for w in words if w not in source)
missing_icons = sorted(i for i in icons if f'"{i}"' not in source)

print(f"── screen {N} vs {', '.join(str(p) for p in SOURCES)} ──")
print(f"text: {len(words) - len(missing_text)}/{len(words)}   icons: {len(icons) - len(missing_icons)}/{len(icons)}")

for label, items in (("MISSING TEXT", missing_text), ("MISSING ICONS", missing_icons)):
    if items:
        print(f"\n{label}")
        for i in items:
            print(f"  · {i}")

sys.exit(1 if (missing_text or missing_icons) else 0)
