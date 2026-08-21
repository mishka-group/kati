#!/usr/bin/env python3
"""Everything about the dark-mode capture path that can be proved without a device.

    python3 bin/test_capture_dark.py

There is no emulator in these tests. `adb` is replaced by a fake device that
remembers its night setting, so the questions that can be answered here are
answered here: does --dark ask for the right setting, does the setting come
back when the run explodes, does the run refuse to file frames under a mode
the device never entered, and does the light-vs-dark report shout when a
screen is identical instead of passing quietly.

What still needs a real device is listed at the bottom of this file, and in
the summary that runs with it.

Every assertion here is on a COUNT or on CONTENT. `assertRaises` on its own,
or "it did not crash", would pass just as happily against a script that
touched nothing at all — which is the failure this harness exists to catch.
"""
import contextlib
import io
import json
import pathlib
import struct
import sys
import unittest
import zlib
from unittest import mock

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

import capture_all  # noqa: E402
import frame_image as FI  # noqa: E402
import light_vs_dark as LVD  # noqa: E402


# ---------------------------------------------------------------------------
# A device that is not there
# ---------------------------------------------------------------------------

class FakeDevice:
    """Answers the handful of adb calls the settings path makes.

    `stuck` models the real case the code has to survive: a device whose night
    mode is driven by a schedule, where `cmd uimode night yes` returns without
    error and changes nothing.
    """

    def __init__(self, night="no", zen="0", stuck=False, uimode_silent=False):
        self.night = night
        self.zen = zen
        self.stuck = stuck
        self.uimode_silent = uimode_silent
        self.calls = []
        self.night_history = [night]

    def adb(self, *args, binary=False, timeout=120):
        self.calls.append(args)

        if args[:4] == ("shell", "cmd", "uimode", "night"):
            if len(args) > 4 and not self.stuck:
                self.night = args[4]
                self.night_history.append(self.night)
            if self.uimode_silent:
                return ""
            return f"Night mode: {self.night}\n"

        if args[:5] == ("shell", "settings", "get", "secure", "ui_night_mode"):
            code = {"auto": "0", "no": "1", "yes": "2",
                    "custom_schedule": "3"}.get(self.night, "1")
            return code + "\n"

        if args[:5] == ("shell", "settings", "get", "global", "zen_mode"):
            return self.zen + "\n"

        if args[:5] == ("shell", "settings", "put", "global", "zen_mode"):
            self.zen = args[5]
            return ""

        return b"" if binary else ""

    def night_sets(self):
        return [a[4] for a in self.calls
                if a[:4] == ("shell", "cmd", "uimode", "night") and len(a) > 4]


@contextlib.contextmanager
def fake_device(device):
    """Swap adb, kill the sleeps, and keep the test runner's signal handlers."""
    with mock.patch.object(capture_all, "adb", device.adb), \
         mock.patch.object(capture_all.time, "sleep", lambda *_: None), \
         mock.patch.object(capture_all.signal, "signal", lambda *a: None):
        yield device


# ---------------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------------

class TestArguments(unittest.TestCase):

    def test_bare_run_is_the_old_behaviour(self):
        a = capture_all.parse_args([])
        self.assertEqual((a.lo, a.hi), (1, 62))
        self.assertEqual(a.mode, "as-is")
        self.assertIsNone(a.night, "a bare run must not touch the device setting")
        self.assertEqual(a.out, capture_all.OUT)

    def test_positional_range_still_works(self):
        # `python3 bin/capture_all.py 10 25` is in the module docstring and in
        # people's shell history. argparse must not have taken it away.
        a = capture_all.parse_args(["10", "25"])
        self.assertEqual((a.lo, a.hi), (10, 25))

    def test_dark_selects_a_separate_directory(self):
        a = capture_all.parse_args(["--dark"])
        self.assertEqual(a.mode, "dark")
        self.assertEqual(a.night, "yes")
        self.assertEqual(a.out.name, "audit_dark")
        self.assertNotEqual(a.out, capture_all.OUT,
                            "a dark run must never write over the light baseline")

    def test_light_forces_night_off_but_keeps_the_baseline_directory(self):
        a = capture_all.parse_args(["--light"])
        self.assertEqual(a.night, "no")
        self.assertEqual(a.out, capture_all.OUT)

    def test_dark_with_range_and_explicit_out(self):
        a = capture_all.parse_args(["--dark", "--out", "/tmp/x", "10", "25"])
        self.assertEqual((a.lo, a.hi), (10, 25))
        self.assertEqual(a.out, pathlib.Path("/tmp/x"))
        self.assertEqual(a.night, "yes")

    def test_dark_and_light_together_are_refused(self):
        with self.assertRaises(SystemExit), contextlib.redirect_stderr(io.StringIO()):
            capture_all.parse_args(["--dark", "--light"])

    def test_restore_only_takes_nothing_else(self):
        for extra in (["--dark"], ["--light"], ["--out", "/tmp/x"], ["10", "25"]):
            with self.subTest(extra=extra):
                with self.assertRaises(SystemExit), \
                     contextlib.redirect_stderr(io.StringIO()):
                    capture_all.parse_args(["--restore-only", *extra])

    def test_restore_only_alone_is_accepted(self):
        a = capture_all.parse_args(["--restore-only"])
        self.assertTrue(a.restore_only)

    def test_backwards_range_is_refused_rather_than_capturing_nothing(self):
        with self.assertRaises(SystemExit), contextlib.redirect_stderr(io.StringIO()):
            capture_all.parse_args(["30", "10"])


# ---------------------------------------------------------------------------
# Reading and writing the setting
# ---------------------------------------------------------------------------

class TestNightMode(unittest.TestCase):

    def test_reads_what_cmd_uimode_prints(self):
        with fake_device(FakeDevice(night="yes")):
            self.assertEqual(capture_all.read_night(), "yes")

    def test_falls_back_to_the_secure_setting_when_uimode_says_nothing(self):
        # Older images answer `cmd uimode night` with an empty string. Reading
        # None there and then "restoring" a guess is how an emulator gets left
        # dark, so the fallback is not decoration.
        dev = FakeDevice(night="custom_schedule", uimode_silent=True)
        with fake_device(dev):
            self.assertEqual(capture_all.read_night(), "custom_schedule")

    def test_unreadable_setting_reads_as_None_not_as_no(self):
        dev = FakeDevice(uimode_silent=True)
        dev.adb = lambda *a, **k: ""  # says nothing to anything
        with mock.patch.object(capture_all, "adb", dev.adb):
            self.assertIsNone(capture_all.read_night())

    def test_set_night_reports_the_device_not_the_request(self):
        dev = FakeDevice(night="custom_schedule", stuck=True)
        with fake_device(dev):
            landed = capture_all.set_night("yes")
        self.assertEqual(landed, "custom_schedule",
                         "a stuck device must not be reported as dark")

    def test_set_night_rejects_a_value_the_device_would_ignore(self):
        with fake_device(FakeDevice()):
            with self.assertRaises(ValueError):
                capture_all.set_night("dark")


# ---------------------------------------------------------------------------
# DeviceState: the restore path
# ---------------------------------------------------------------------------

class TestDeviceState(unittest.TestCase):

    def setUp(self):
        self.tmp = pathlib.Path(__import__("tempfile").mkdtemp())
        self.stash = self.tmp / "state.json"
        self.log = []

    def state(self):
        return capture_all.DeviceState(stash=self.stash, log=self.log.append)

    def test_stash_is_written_before_the_change_and_holds_the_old_value(self):
        dev = FakeDevice(night="auto", zen="0")
        with fake_device(dev):
            st = self.state()
            st.capture_and_change(night="yes", zen="1")

            saved = json.loads(self.stash.read_text())
            self.assertEqual(saved["night"], "auto")
            self.assertEqual(saved["zen"], "0")
            self.assertEqual(dev.night, "yes")
            self.assertEqual(dev.zen, "1")

    def test_restore_puts_back_the_exact_previous_value(self):
        dev = FakeDevice(night="custom_schedule", zen="2")
        with fake_device(dev):
            st = self.state()
            st.capture_and_change(night="yes", zen="1")
            st.restore()

        self.assertEqual(dev.night, "custom_schedule",
                         "restoring must not flatten `custom_schedule` to `no`")
        self.assertEqual(dev.zen, "2")
        self.assertFalse(self.stash.exists())

    def test_restore_is_idempotent(self):
        # `finally` and an atexit hook can both reach it; a second restore must
        # not re-issue the settings write.
        dev = FakeDevice(night="no")
        with fake_device(dev):
            st = self.state()
            st.capture_and_change(night="yes")
            st.restore()
            before = len(dev.night_sets())
            st.restore()
            st.restore()
            self.assertEqual(len(dev.night_sets()), before,
                             "restore ran more than once")

    def test_recover_repairs_a_device_a_killed_run_left_dark(self):
        self.stash.write_text(json.dumps({"night": "auto", "zen": "0"}))
        dev = FakeDevice(night="yes")  # left dark by the run that died
        with fake_device(dev):
            saved = self.state().recover()

        self.assertEqual(saved["night"], "auto")
        self.assertEqual(dev.night, "auto")
        self.assertFalse(self.stash.exists())
        self.assertTrue(any("did not finish" in m for m in self.log),
                        f"recovery must announce itself; log was {self.log}")

    def test_recover_with_no_stash_touches_nothing(self):
        dev = FakeDevice(night="yes")
        with fake_device(dev):
            self.assertIsNone(self.state().recover())
        self.assertEqual(dev.night_sets(), [])

    def test_unreadable_stash_forces_night_off_and_says_so(self):
        self.stash.write_text("{not json")
        dev = FakeDevice(night="yes")
        with fake_device(dev):
            self.state().recover()
        self.assertEqual(dev.night, "no",
                         "an unreadable stash must still not leave it dark")
        self.assertTrue(any("unreadable" in m for m in self.log))

    def test_unknown_previous_value_falls_back_to_no_loudly(self):
        dev = FakeDevice(night="yes")
        with fake_device(dev):
            st = self.state()
            st.saved = {"night": None, "zen": "0"}
            st.restore()
        self.assertEqual(dev.night, "no")
        self.assertTrue(any("falling back to" in m for m in self.log))


# ---------------------------------------------------------------------------
# main(): restore-on-failure, and the manifest
# ---------------------------------------------------------------------------

class TestRun(unittest.TestCase):

    def setUp(self):
        self.tmp = pathlib.Path(__import__("tempfile").mkdtemp())
        self.out = self.tmp / "audit_dark"
        self.stash = self.tmp / "state.json"

    @contextlib.contextmanager
    def run_with(self, dev, capture):
        with fake_device(dev), \
             mock.patch.object(capture_all, "STASH", self.stash), \
             mock.patch.object(capture_all, "capture_range", capture), \
             contextlib.redirect_stdout(io.StringIO()) as out:
            yield out

    def test_dark_run_is_dark_while_capturing_and_light_after(self):
        dev = FakeDevice(night="auto")
        seen = {}

        def capture(lo, hi, out_dir, captured, holes):
            seen["night"] = dev.night
            seen["dir"] = out_dir
            out_dir.mkdir(parents=True, exist_ok=True)
            for n in ("01", "02"):
                (out_dir / f"{n}.png").write_bytes(b"x")
                captured.append(n)

        with self.run_with(dev, capture):
            rc = capture_all.main(["--dark", "--out", str(self.out)])

        self.assertEqual(rc, 0)
        self.assertEqual(seen["night"], "yes", "capture ran in the wrong mode")
        self.assertEqual(seen["dir"], self.out)
        self.assertEqual(dev.night, "auto", "the previous setting was not restored")
        self.assertFalse(self.stash.exists())

        man = json.loads((self.out / "RUN.json").read_text())
        self.assertEqual(man["mode"], "dark")
        self.assertEqual(man["night_mode"], "yes")
        self.assertEqual(man["night_mode_before"], "auto")
        self.assertEqual(man["captured"], ["01", "02"])

    def test_the_setting_comes_back_when_the_run_explodes(self):
        dev = FakeDevice(night="no")

        def capture(*_a, **_k):
            raise RuntimeError("adb fell over")

        with self.run_with(dev, capture):
            with self.assertRaises(RuntimeError):
                capture_all.main(["--dark", "--out", str(self.out)])

        self.assertEqual(dev.night, "no",
                         "a crashed run left the emulator dark")
        self.assertFalse(self.stash.exists(),
                         "a completed restore must clear the stash")

    def test_the_setting_comes_back_on_ctrl_c(self):
        # The signal handlers turn SIGINT/SIGTERM into this, so this is the
        # shape a killed run actually takes.
        dev = FakeDevice(night="auto")

        def capture(*_a, **_k):
            raise KeyboardInterrupt("signal 2")

        with self.run_with(dev, capture):
            with self.assertRaises(KeyboardInterrupt):
                capture_all.main(["--dark", "--out", str(self.out)])

        self.assertEqual(dev.night, "auto")
        self.assertFalse(self.stash.exists())

    def test_an_interrupted_run_still_records_what_it_captured(self):
        dev = FakeDevice(night="no")

        def capture(lo, hi, out_dir, captured, holes):
            out_dir.mkdir(parents=True, exist_ok=True)
            (out_dir / "01.png").write_bytes(b"x")
            captured.append("01")
            holes.append(("02", "row never appeared"))
            raise KeyboardInterrupt("signal 2")

        with self.run_with(dev, capture):
            with self.assertRaises(KeyboardInterrupt):
                capture_all.main(["--dark", "--out", str(self.out)])

        man = json.loads((self.out / "RUN.json").read_text())
        self.assertEqual(man["captured"], ["01"],
                         "a partial run must not claim it captured nothing")
        self.assertEqual(man["holes"], [["02", "row never appeared"]])

    def test_a_run_that_starts_after_a_killed_one_repairs_the_device_first(self):
        self.stash.write_text(json.dumps({"night": "auto", "zen": "0"}))
        dev = FakeDevice(night="yes")  # still dark from the run that died
        seen = {}

        def capture(lo, hi, out_dir, captured, holes):
            seen["night"] = dev.night
            out_dir.mkdir(parents=True, exist_ok=True)

        with self.run_with(dev, capture) as out:
            capture_all.main(["--out", str(self.out)])

        self.assertIn("did not finish", out.getvalue())
        self.assertEqual(seen["night"], "auto",
                         "a light run began on a device the last run left dark")
        self.assertEqual(dev.night, "auto")

    def test_a_bare_run_on_a_dark_device_says_the_frames_are_not_a_baseline(self):
        dev = FakeDevice(night="yes")

        def capture(lo, hi, out_dir, captured, holes):
            out_dir.mkdir(parents=True, exist_ok=True)

        with self.run_with(dev, capture) as out:
            capture_all.main(["--out", str(self.out)])

        text = out.getvalue()
        self.assertIn("not a light baseline", text)

    def test_a_device_that_refuses_to_go_dark_stops_the_run(self):
        dev = FakeDevice(night="custom_schedule", stuck=True)
        called = []

        def capture(*_a, **_k):
            called.append(1)

        with self.run_with(dev, capture) as out:
            rc = capture_all.main(["--dark", "--out", str(self.out)])

        self.assertEqual(rc, 2)
        self.assertEqual(called, [],
                         "frames must not be captured under a mode the device "
                         "never entered")
        self.assertIn("stopping rather than filing", out.getvalue())
        self.assertEqual(dev.night, "custom_schedule")

    def test_an_aborted_run_does_not_overwrite_a_good_manifest(self):
        self.out.mkdir(parents=True)
        good = {"mode": "dark", "night_mode": "yes", "captured": ["01"]}
        (self.out / "RUN.json").write_text(json.dumps(good))

        dev = FakeDevice(night="custom_schedule", stuck=True)
        with self.run_with(dev, lambda *a, **k: None):
            capture_all.main(["--dark", "--out", str(self.out)])

        self.assertEqual(json.loads((self.out / "RUN.json").read_text()), good)

    def test_restore_only_cashes_in_the_stash(self):
        self.stash.write_text(json.dumps({"night": "no", "zen": "0"}))
        dev = FakeDevice(night="yes")
        with self.run_with(dev, lambda *a, **k: None):
            rc = capture_all.main(["--restore-only"])
        self.assertEqual(rc, 0)
        self.assertEqual(dev.night, "no")
        self.assertFalse(self.stash.exists())

    def test_restore_only_with_nothing_stashed_says_so(self):
        dev = FakeDevice(night="yes")
        with self.run_with(dev, lambda *a, **k: None) as out:
            capture_all.main(["--restore-only"])
        self.assertIn("nothing stashed", out.getvalue())
        self.assertEqual(dev.night, "yes", "it must not invent a setting")

    def test_signal_handlers_are_installed_for_the_signals_that_can_be_caught(self):
        dev = FakeDevice()
        installed = []

        with mock.patch.object(capture_all, "adb", dev.adb), \
             mock.patch.object(capture_all.time, "sleep", lambda *_: None), \
             mock.patch.object(capture_all, "STASH", self.stash), \
             mock.patch.object(capture_all, "capture_range", lambda *a, **k: None), \
             mock.patch.object(capture_all.signal, "signal",
                               lambda s, h: installed.append(s)), \
             contextlib.redirect_stdout(io.StringIO()):
            capture_all.main(["--out", str(self.out)])

        for name in ("SIGINT", "SIGTERM"):
            self.assertIn(getattr(capture_all.signal, name), installed,
                          f"{name} would kill the run without restoring")


# ---------------------------------------------------------------------------
# Reading frames
# ---------------------------------------------------------------------------

def write_png(path, width, height, pixel):
    """A flat PNG of `pixel`, written with nothing but zlib and struct."""
    row = bytes(pixel) * width
    raw = b"".join(b"\x00" + row for _ in range(height))

    def chunk(kind, data):
        return (struct.pack(">I", len(data)) + kind + data
                + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF))

    pathlib.Path(path).write_bytes(
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(raw, 6))
        + chunk(b"IEND", b""))


class TestFrameImage(unittest.TestCase):

    def setUp(self):
        self.tmp = pathlib.Path(__import__("tempfile").mkdtemp())
        if FI.backend() is None:
            self.skipTest("no image backend on this machine")

    def test_pixels_survive_the_round_trip(self):
        # The sips backend goes through a BMP, which stores B,G,R. A swapped
        # channel would still decode into a plausible image and quietly change
        # every luma reading, so the actual bytes are checked.
        p = self.tmp / "known.png"
        write_png(p, 4, 3, (10, 120, 200))
        f = FI.load(p)
        self.assertEqual(f.size, (4, 3))
        self.assertEqual(len(f.data), 4 * 3 * 3)
        self.assertEqual(set(zip(f.data[0::3], f.data[1::3], f.data[2::3])),
                         {(10, 120, 200)})

    def test_identical_frames_report_no_change(self):
        a, b = self.tmp / "a.png", self.tmp / "b.png"
        write_png(a, 8, 8, (30, 30, 30))
        write_png(b, 8, 8, (30, 30, 30))
        changed, total, bbox = FI.difference(FI.load(a), FI.load(b), 12)
        self.assertEqual((changed, total, bbox), (0, 64, None))

    def test_a_change_under_the_tolerance_is_not_a_change(self):
        a, b = self.tmp / "a.png", self.tmp / "b.png"
        write_png(a, 8, 8, (100, 100, 100))
        write_png(b, 8, 8, (108, 100, 100))  # 8 < tolerance 12
        self.assertEqual(FI.difference(FI.load(a), FI.load(b), 12)[0], 0)
        self.assertEqual(FI.difference(FI.load(a), FI.load(b), 4)[0], 64)

    def test_cropping_more_than_exists_raises_instead_of_emptying_the_frame(self):
        # A zero-height frame compares equal to every other zero-height frame,
        # so "nothing changed" would be reported for every screen.
        p = self.tmp / "small.png"
        write_png(p, 8, 100, (0, 0, 0))
        with self.assertRaises(FI.FrameError):
            FI.load(p).crop_rows(90, 130)

    def test_cropping_a_frame_down_to_exactly_nothing_raises_too(self):
        # The dangerous case is the EXACT boundary, not the overshoot. An
        # overshoot slices short and the Frame constructor rejects the length;
        # 90 + 130 against a 220px frame leaves a legal, empty, zero-height
        # image that every comparison agrees with. This is the guard that has
        # to be in crop_rows itself.
        p = self.tmp / "exact.png"
        write_png(p, 8, 90 + 130, (0, 0, 0))
        with self.assertRaises(FI.FrameError):
            FI.load(p).crop_rows(90, 130)

    def test_a_crop_that_leaves_one_row_is_allowed(self):
        p = self.tmp / "one.png"
        write_png(p, 8, 221, (5, 6, 7))
        cropped = FI.load(p).crop_rows(90, 130)
        self.assertEqual(cropped.size, (8, 1))
        self.assertEqual(len(cropped.data), 24)

    def test_luma_separates_a_light_frame_from_a_dark_one(self):
        light, dark = self.tmp / "l.png", self.tmp / "d.png"
        write_png(light, 8, 8, (239, 236, 231))
        write_png(dark, 8, 8, (26, 24, 22))
        self.assertGreater(FI.mean_luma(FI.load(light)), 200)
        self.assertLess(FI.mean_luma(FI.load(dark)), 40)


# ---------------------------------------------------------------------------
# The light-vs-dark report
# ---------------------------------------------------------------------------

class TestLightVsDark(unittest.TestCase):

    def setUp(self):
        if FI.backend() is None:
            self.skipTest("no image backend on this machine")
        self.tmp = pathlib.Path(__import__("tempfile").mkdtemp())
        self.light = self.tmp / "audit"
        self.dark = self.tmp / "audit_dark"
        self.light.mkdir()
        self.dark.mkdir()

    def manifests(self, light_night="no", dark_night="yes"):
        (self.light / "RUN.json").write_text(
            json.dumps({"mode": "light", "night_mode": light_night}))
        (self.dark / "RUN.json").write_text(
            json.dumps({"mode": "dark", "night_mode": dark_night}))

    def frame(self, where, n, colour):
        write_png(where / f"{n}.png", 40, 400, colour)

    def report(self, *argv):
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf), \
             mock.patch.object(LVD, "labels", lambda: {}):
            rc = LVD.main([str(self.light), str(self.dark), *argv])
        return rc, buf.getvalue()

    def test_a_screen_identical_in_both_modes_is_reported_loudly(self):
        self.manifests()
        for n in ("01", "02", "03"):
            self.frame(self.light, n, (240, 237, 232))
            self.frame(self.dark, n, (240, 237, 232))

        rc, text = self.report()
        self.assertEqual(rc, 1, "an ignored theme must not exit 0")
        self.assertIn("IGNORES THE THEME", text)
        self.assertIn("3/3", text)
        for n in ("01", "02", "03"):
            self.assertIn(f"  {n}  ", text)
        self.assertIn("3 of 3 screens did not follow the system theme", text)

    def test_screens_that_darken_are_counted_as_working(self):
        self.manifests()
        for n in ("01", "02"):
            self.frame(self.light, n, (240, 237, 232))
            self.frame(self.dark, n, (26, 24, 22))

        rc, text = self.report()
        self.assertEqual(rc, 0)
        self.assertIn("responded to dark mode: 2/2", text)
        self.assertIn("all 2 screens followed the system theme", text)
        self.assertNotIn("IGNORES THE THEME", text)

    def test_a_mixed_run_separates_the_two(self):
        self.manifests()
        self.frame(self.light, "01", (240, 237, 232))
        self.frame(self.dark, "01", (26, 24, 22))     # works
        self.frame(self.light, "02", (240, 237, 232))
        self.frame(self.dark, "02", (240, 237, 232))  # ignored
        self.frame(self.light, "03", (240, 237, 232))
        self.frame(self.dark, "03", (238, 235, 230))  # repainted, same palette

        rc, text = self.report()
        self.assertEqual(rc, 1)
        self.assertIn("IGNORES THE THEME", text)
        self.assertIn("responded to dark mode: 1/3", text)
        self.assertIn("2 of 3 screens did not follow the system theme", text)

    def test_a_screen_the_design_draws_dark_is_annotated_not_hidden(self):
        # 28 (Home, dark) and 29 (Lock screen) are dark drawings. They will not
        # change much, and that is not the same defect — but they still get
        # listed, with the reason.
        self.manifests()
        self.frame(self.light, "28", (26, 24, 22))
        self.frame(self.dark, "28", (26, 24, 22))

        rc, text = self.report()
        self.assertEqual(rc, 1)
        self.assertIn("  28  ", text)
        self.assertIn("already dark in the light run", text)

    def test_two_runs_captured_the_same_way_are_refused(self):
        # This is the trap the whole script exists around: if the dark run was
        # actually light, every screen compares identical and the report reads
        # like a complete finding.
        self.manifests(light_night="no", dark_night="no")
        self.frame(self.light, "01", (240, 237, 232))
        self.frame(self.dark, "01", (240, 237, 232))

        rc, text = self.report()
        self.assertEqual(rc, 2)
        self.assertIn("BOTH runs record night='no'", text)
        self.assertNotIn("IGNORES THE THEME", text,
                         "a meaningless comparison must not print a verdict")

    def test_force_overrides_the_refusal(self):
        self.manifests(light_night="no", dark_night="no")
        self.frame(self.light, "01", (240, 237, 232))
        self.frame(self.dark, "01", (240, 237, 232))

        rc, text = self.report("--force")
        self.assertEqual(rc, 1)
        self.assertIn("IGNORES THE THEME", text)

    def test_a_missing_manifest_is_called_out_but_does_not_block(self):
        self.frame(self.light, "01", (240, 237, 232))
        self.frame(self.dark, "01", (26, 24, 22))

        rc, text = self.report()
        self.assertEqual(rc, 0)
        self.assertIn("no RUN.json", text)
        self.assertIn("mode UNVERIFIED", text)

    def test_frames_missing_from_the_dark_run_are_listed(self):
        self.manifests()
        self.frame(self.light, "01", (240, 237, 232))
        self.frame(self.dark, "01", (26, 24, 22))
        self.frame(self.light, "02", (240, 237, 232))

        rc, text = self.report()
        self.assertIn("missing from the dark run (1): 02", text)

    def test_nothing_to_compare_is_an_error_not_a_pass(self):
        self.manifests()
        rc, text = self.report()
        self.assertEqual(rc, 3)
        self.assertIn("nothing was compared", text)

    def test_check_modes_accepts_a_real_pairing(self):
        said = []
        self.assertTrue(LVD.check_modes({"night_mode": "no"},
                                        {"night_mode": "yes"}, said.append))
        self.assertEqual(said, [])


class TestGalleryLabels(unittest.TestCase):

    def test_every_screen_gets_a_name(self):
        # Asserting the SIZE, because a regex that silently matches zero rows
        # is how a registry resolved to nothing in this repo once already. An
        # empty mapping would still render a perfectly readable report.
        names = LVD.labels()
        self.assertEqual(len(names), 62, f"got {len(names)} gallery rows")
        self.assertTrue(all(v for v in names.values()),
                        "a screen with an empty label")
        self.assertIn("28", names)


NEEDS_A_DEVICE = """
Still unproven without an emulator attached:

  * that `adb shell cmd uimode night yes` actually darkens THIS system image,
    and that read_night() parses THIS image's reply. The parser is tested
    against the documented "Night mode: yes" form and against a silent
    `cmd uimode` falling through to `settings get secure ui_night_mode`; a
    third wording would read as None and restore to `no`, loudly.
  * that the Mob activity survives the configuration change, or is restarted
    cleanly by the force-stop in open_gallery().
  * the 4s settle after the switch. If the system animates the transition
    longer than that, the first frame or two could be captured mid-crossfade.
  * that the gallery's uiautomator text is unchanged in dark mode, so
    find_row() and the fingerprint check still identify screens.
  * SIGKILL recovery end to end: kill -9 a real run, then confirm the next run
    prints "a previous run did not finish" and repairs the setting.
"""

if __name__ == "__main__":
    print(NEEDS_A_DEVICE)
    unittest.main(verbosity=2)
