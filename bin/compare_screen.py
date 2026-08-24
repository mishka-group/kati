#!/usr/bin/env python3
"""Build a side-by-side page: the design frame next to the live device.

    python3 bin/compare_screen.py 01 [screenshot.png]

Writes .captures/compare/NN.html. Open it (or screenshot it) to see the
drawing and the build at the same scale, on the same baseline, so a difference
is visible rather than remembered.

The design frame is 402x874 CSS px. The device shot is 1080x2424 at 2.6875x,
so it is scaled to the same 402pt width and the two sit on a shared grid.
"""
import base64, pathlib, re, subprocess, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
N = sys.argv[1].zfill(2)
SHOT = pathlib.Path(sys.argv[2]) if len(sys.argv) > 2 else None

design = (ROOT / f"test/design/screens/{N}.html").read_text(encoding="utf-8")
# The frame's own markup, minus the x-import wrapper the export uses.
inner = re.sub(r"^<x-import[^>]*>", "", design.strip())
inner = re.sub(r"</x-import>\s*$", "", inner)

if SHOT is None:
    SHOT = ROOT / ".captures/compare" / f"{N}-device.png"
    subprocess.run(["adb", "shell", "screencap", "-p", "/sdcard/cmp.png"], check=True)
    subprocess.run(["adb", "pull", "-a", "/sdcard/cmp.png", str(SHOT)],
                   check=True, stdout=subprocess.DEVNULL)

shot_b64 = base64.b64encode(SHOT.read_bytes()).decode()

out = ROOT / f".captures/compare/{N}.html"
out.write_text(f"""<!doctype html>
<meta charset="utf-8">
<title>Kati {N} — design vs build</title>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=DM+Mono:wght@400;500&family=Vazirmatn:wght@400;500;600;700;800&family=Material+Symbols+Rounded:opsz,wght,FILL,GRAD@20..48,300..700,0..1,0&display=swap" rel="stylesheet">
<style>
  body {{ margin:0; background:#2A2723; color:#EFECE7;
         font:13px 'Plus Jakarta Sans',system-ui,sans-serif; }}
  * {{ box-sizing:border-box; }}
  .wrap {{ display:flex; gap:28px; padding:26px; align-items:flex-start; }}
  .pane {{ display:flex; flex-direction:column; gap:9px; }}
  h2 {{ margin:0; font-size:11px; letter-spacing:.16em; text-transform:uppercase;
        color:#A0998F; font-family:'DM Mono',monospace; font-weight:400; }}
  .frame {{ width:402px; height:874px; overflow:hidden; border-radius:22px;
            background:#EFECE7; position:relative;
            box-shadow:0 20px 50px -20px rgba(0,0,0,.8); }}
  /* The device is 1080 wide at 2.6875x = 402pt. Same width, same scale. */
  .frame img {{ width:402px; display:block; margin-top:-41px; }}
  .rule {{ position:absolute; left:0; right:0; height:1px;
           background:rgba(232,130,60,.55); pointer-events:none; }}
  .legend {{ padding:0 26px 26px; color:#A0998F; line-height:1.6; }}
  code {{ color:#E8823C; }}
</style>
<div class="wrap">
  <div class="pane">
    <h2>{N} — design</h2>
    <div class="frame">{inner}{"".join(f'<div class="rule" style="top:{y}px"></div>' for y in range(0, 874, 100))}</div>
  </div>
  <div class="pane">
    <h2>{N} — build</h2>
    <div class="frame"><img src="data:image/png;base64,{shot_b64}">
      {"".join(f'<div class="rule" style="top:{y}px"></div>' for y in range(0, 874, 100))}
    </div>
  </div>
</div>
<div class="legend">
  Orange rules every 100pt. The device shot is offset by the status bar so the
  two frames share a baseline — a block that sits between different rules on
  the two sides is off by that much.
</div>
""", encoding="utf-8")
print(out)
