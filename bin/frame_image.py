#!/usr/bin/env python3
"""Load a captured frame as RGB bytes, and say where two frames differ.

`bin/diff_frames.py` was written against Pillow. Pillow is not installed for
any python3 on this machine, so that script has been raising
ModuleNotFoundError on line one — a comparison tool that never compared
anything. The fix is not to demand an install before anyone can check a
capture; it is to make the loader work with what is actually here.

Two backends, in order:

  1. Pillow, if it imports. Portable, and what the original used.
  2. `sips`, the image converter macOS ships. PNG -> uncompressed BMP in
     about 0.1s a frame, and a BMP is a header and a block of pixels.

A pure-python PNG decoder was the third option and is not here. Android's
screencap PNGs use Paeth and Average filters on 90% of their rows, and those
unfilter one byte at a time along the row: about four seconds a frame in
python, ten minutes for a 62-screen pair. sips does it in a tenth of a second.

If neither backend exists this module RAISES. It does not return an empty
image, or zero differences, or None. A comparison tool that reports "nothing
changed" because it could not read the files is the exact failure this
repository keeps finding.
"""
import pathlib
import shutil
import struct
import subprocess
import tempfile

try:  # pragma: no cover - depends on the host
    from PIL import Image as _PILImage
except ImportError:  # pragma: no cover
    _PILImage = None

try:  # pragma: no cover - depends on the host
    import numpy as _np
except ImportError:  # pragma: no cover
    _np = None


class FrameError(RuntimeError):
    """Something about a frame file could not be read, and we will not guess."""


class Frame:
    """width, height, and `data`: height*width*3 bytes, RGB, top row first."""

    __slots__ = ("width", "height", "data")

    def __init__(self, width, height, data):
        expected = width * height * 3
        if len(data) != expected:
            raise FrameError(
                f"{width}x{height} needs {expected} bytes of RGB, got {len(data)}"
            )
        self.width = width
        self.height = height
        self.data = data

    @property
    def size(self):
        return (self.width, self.height)

    def crop_rows(self, top, bottom):
        """Drop `top` rows from the top and `bottom` from the bottom.

        Guarded, because the callers' constants are sized for a 2424px phone
        and a test image is not. Cropping more than exists would otherwise
        produce a zero-height frame that compares equal to everything.
        """
        if top < 0 or bottom < 0:
            raise FrameError(f"negative crop ({top}, {bottom})")
        if top + bottom >= self.height:
            raise FrameError(
                f"crop of {top}+{bottom} rows leaves nothing of a "
                f"{self.height}px frame"
            )
        stride = self.width * 3
        keep = self.height - top - bottom
        return Frame(self.width, keep, self.data[top * stride:(top + keep) * stride])


def backend():
    """Which loader will be used — printed by the tools so it is on the record."""
    if _PILImage is not None:
        return "pillow"
    if shutil.which("sips"):
        return "sips"
    return None


def load(path):
    """Read a PNG (or anything the backend groks) into a Frame."""
    path = pathlib.Path(path)
    if not path.exists():
        raise FrameError(f"no such frame: {path}")

    if _PILImage is not None:
        img = _PILImage.open(path).convert("RGB")
        return Frame(img.width, img.height, img.tobytes())

    if shutil.which("sips"):
        return _load_via_sips(path)

    raise FrameError(
        "no way to read an image: Pillow is not installed and `sips` is not on "
        "PATH. Install one (`python3 -m pip install pillow`) — do not skip the "
        "comparison."
    )


def _load_via_sips(path):
    with tempfile.TemporaryDirectory() as tmp:
        bmp = pathlib.Path(tmp) / "frame.bmp"
        proc = subprocess.run(
            ["sips", "-s", "format", "bmp", "--out", str(bmp), str(path)],
            capture_output=True,
        )
        if not bmp.exists() or bmp.stat().st_size == 0:
            err = proc.stderr.decode("utf-8", "replace").strip()
            raise FrameError(f"sips could not convert {path}: {err or 'no output'}")
        return _read_bmp(bmp.read_bytes())


def _read_bmp(blob):
    """Parse the uncompressed BMP sips writes.

    Every field that could silently transpose the channels is checked rather
    than assumed. A BMP read with the wrong masks still decodes — into an
    image whose red and blue are swapped, which would make every screen look
    like it changed between light and dark for reasons that have nothing to
    do with the theme.
    """
    if blob[:2] != b"BM":
        raise FrameError("not a BMP (sips wrote something unexpected)")

    pixel_offset = struct.unpack_from("<I", blob, 10)[0]
    header_size = struct.unpack_from("<I", blob, 14)[0]
    if header_size < 40:
        raise FrameError(f"BMP header of {header_size} bytes is too old to parse")

    width, height, planes, bpp, compression = struct.unpack_from("<iiHHI", blob, 18)
    if planes != 1:
        raise FrameError(f"BMP with {planes} planes")
    if bpp not in (24, 32):
        raise FrameError(f"BMP at {bpp} bits per pixel; expected 24 or 32")
    if compression not in (0, 3):
        raise FrameError(f"compressed BMP (compression={compression})")

    top_down = height < 0
    height = abs(height)

    # BI_BITFIELDS (3) carries explicit channel masks. Require the ordinary
    # little-endian B,G,R,(A) byte order rather than shuffling for arbitrary
    # masks — anything else means the assumption below is wrong and should say
    # so out loud.
    if compression == 3:
        red, green, blue = struct.unpack_from("<III", blob, 14 + 40)
        if (red, green, blue) != (0x00FF0000, 0x0000FF00, 0x000000FF):
            raise FrameError(
                f"BMP channel masks R={red:#010x} G={green:#010x} B={blue:#010x} "
                "are not the B,G,R byte order this reader assumes"
            )

    sample = bpp // 8
    stride = ((width * bpp + 31) // 32) * 4  # rows pad to a 4-byte boundary
    need = pixel_offset + stride * height
    if len(blob) < need:
        raise FrameError(f"BMP is {len(blob)} bytes, needs {need}")

    # Gather the rows top-first and unpadded, then swizzle the whole block in
    # one pass. Doing it per pixel is 2.6 million python iterations a frame;
    # extended slice assignment is the same work at C speed.
    packed = bytearray(width * sample * height)
    row_bytes = width * sample
    for y in range(height):
        src = y if top_down else (height - 1 - y)
        start = pixel_offset + src * stride
        packed[y * row_bytes:(y + 1) * row_bytes] = blob[start:start + row_bytes]

    out = bytearray(width * height * 3)
    out[0::3] = packed[2::sample]  # BGR(A) little-endian -> R
    out[1::3] = packed[1::sample]  # -> G
    out[2::3] = packed[0::sample]  # -> B
    return Frame(width, height, bytes(out))


def difference(a, b, tolerance):
    """Compare two same-sized Frames.

    Returns (changed_pixels, total_pixels, bbox) where bbox is
    (x0, y0, x1, y1) in the frames' own coordinates, exclusive on x1/y1, or
    None when nothing exceeded the tolerance. A pixel counts as changed when
    ANY channel differs by more than `tolerance`.
    """
    if a.size != b.size:
        raise FrameError(f"size {a.size} != {b.size}")

    total = a.width * a.height
    if a.data == b.data:
        return 0, total, None

    if _np is not None:
        return _difference_numpy(a, b, tolerance, total)
    return _difference_python(a, b, tolerance, total)


def _difference_numpy(a, b, tolerance, total):
    shape = (a.height, a.width, 3)
    left = _np.frombuffer(a.data, dtype=_np.uint8).reshape(shape).astype(_np.int16)
    right = _np.frombuffer(b.data, dtype=_np.uint8).reshape(shape).astype(_np.int16)
    mask = (_np.abs(left - right) > tolerance).any(axis=2)

    changed = int(mask.sum())
    if changed == 0:
        return 0, total, None

    ys = _np.flatnonzero(mask.any(axis=1))
    xs = _np.flatnonzero(mask.any(axis=0))
    bbox = (int(xs[0]), int(ys[0]), int(xs[-1]) + 1, int(ys[-1]) + 1)
    return changed, total, bbox


def _difference_python(a, b, tolerance, total):
    stride = a.width * 3
    changed = 0
    x0, y0, x1, y1 = a.width, a.height, 0, 0

    for y in range(a.height):
        base = y * stride
        row_a = a.data[base:base + stride]
        row_b = b.data[base:base + stride]
        if row_a == row_b:
            continue
        for x in range(a.width):
            i = x * 3
            if (abs(row_a[i] - row_b[i]) > tolerance
                    or abs(row_a[i + 1] - row_b[i + 1]) > tolerance
                    or abs(row_a[i + 2] - row_b[i + 2]) > tolerance):
                changed += 1
                if x < x0:
                    x0 = x
                if x >= x1:
                    x1 = x + 1
                if y < y0:
                    y0 = y
                if y >= y1:
                    y1 = y + 1

    if changed == 0:
        return 0, total, None
    return changed, total, (x0, y0, x1, y1)


def mean_luma(frame):
    """Average brightness, 0-255. A dark screen sits well below a light one.

    Used to sanity-check that a run labelled dark actually looks dark, rather
    than trusting the directory it was written into.
    """
    if _np is not None:
        px = _np.frombuffer(frame.data, dtype=_np.uint8).reshape(-1, 3).astype(_np.float32)
        return float((px[:, 0] * 0.299 + px[:, 1] * 0.587 + px[:, 2] * 0.114).mean())

    total = 0
    data = frame.data
    for i in range(0, len(data), 3):
        total += 0.299 * data[i] + 0.587 * data[i + 1] + 0.114 * data[i + 2]
    return total / (len(data) / 3)
