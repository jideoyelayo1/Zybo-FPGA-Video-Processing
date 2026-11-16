"""Checks on model.py that need no HDL simulator.

    python3 -m unittest discover -s verify -v

The model itself is checked against the RTL by compare.py; these tests pin the
figures quoted in RESULTS.md so they cannot drift silently.
"""
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import model  # noqa: E402

W, H = 1920, 8
T1080 = model.TIMINGS["1080p60"]


def second_frame(variant, mode, gray, frame, w=W, h=H, timing=T1080):
    out = model.run(variant, mode, gray, frame, w, h, timing, frames=2)
    return [o & 255 for o in out[w * h:]]


def impulse(w=W, h=H, r=4, c=960):
    f = [0] * (w * h)
    f[r * w + c] = 0xFFFFFF
    return f, r, c


class Luma(unittest.TestCase):
    def test_channel_weights(self):
        # words are packed {R,B,G}, as the vendor chain delivers them
        self.assertEqual(model.luma(0xFF0000), 73)   # R: 1/4 + 1/32 + 1/64
        self.assertEqual(model.luma(0x0000FF), 149)  # G: 1/2 + 1/16 + 1/32
        self.assertEqual(model.luma(0x00FF00), 31)   # B: 1/8
        self.assertEqual(model.luma(0xFFFFFF), 253)  # each shift truncates, so white is not 255
        self.assertEqual(model.luma(0), 0)


class Pipeline(unittest.TestCase):
    def nonzero(self, img, r0, c0, w=W, h=H, cols=1500):
        return [(r - r0, c - c0, img[r * w + c]) for r in range(h) for c in range(cols) if img[r * w + c]]

    def test_gray_bypass_drawn_two_pixels_right(self):
        f, r0, c0 = impulse()
        self.assertEqual(self.nonzero(second_frame("sobel", 0, True, f), r0, c0), [(0, 2, 253)])

    def test_sobel_y_impulse_response_is_not_a_3x3_window(self):
        # same taps at three pixel phases (the write pointer cycles mod 3), so the
        # RTL is a fixed filter: six taps over four lines, signs mixed. A correct
        # 3x3 Sobel Y would put +1,+2,+1 on one line and -1,-2,-1 two lines later.
        for r0, c0 in ((2, 960), (3, 961), (4, 962)):
            f, _, _ = impulse(r=r0, c=c0)
            got = [(dl, dc, next(k for k in range(-4, 5) if (k * 253) & 255 == v))
                   for dl, dc, v in self.nonzero(second_frame("sobel", 0, False, f), r0, c0)]
            self.assertEqual(got, [(0, 4, 1), (1, 2, -1), (1, 3, 2), (2, 2, 1), (2, 4, -1), (3, 3, -2)])

    def test_negative_gradients_wrap_instead_of_abs(self):
        f, r0, c0 = impulse()
        values = {v for _, _, v in self.nonzero(second_frame("sobel", 0, False, f), r0, c0)}
        self.assertIn(3, values)  # -253 mod 256: a strong negative gradient is drawn almost black

    def test_white_band_1080p(self):
        img = second_frame("sobel", 0, False, [0] * (W * H))
        for r in range(H):
            white = [c for c in range(W) if img[r * W + c] == 255]
            self.assertEqual((len(white), white[0]), (310, 1610))

    def test_every_other_line_white_720p(self):
        w = 1280
        img = second_frame("sobel", 1, False, [0] * (w * H), w=w, timing=model.TIMINGS["720p60"])
        full = [all(img[r * w + c] == 255 for c in range(w)) for r in range(H)]
        self.assertEqual(sum(full), H // 2)
        self.assertTrue(all(a != b for a, b in zip(full, full[1:])))


class SqrtSimulationSemantics(unittest.TestCase):
    def test_one_newton_step_per_input_change(self):
        d = model.VideoProcessing("sobel", 2)
        d.prod = 100
        d.sqrt_step()
        self.assertEqual(d.sqrt_y, 50)   # (1 + 100/1) / 2, not 10
        d.sqrt_step()
        self.assertEqual(d.sqrt_y, 50)   # unchanged input: no further iteration
        d.prod = 101
        d.sqrt_step()
        self.assertEqual(d.sqrt_y, 26)   # (50 + 101/50) / 2

    def test_products_from_32768_read_as_negative(self):
        d = model.VideoProcessing("sobel", 2)
        d.prod = 255 * 255 + 255 * 255   # 17 bits; low 16 bits have bit 15 set
        d.sqrt_step()
        self.assertEqual(d.sqrt_y, 0)


class Reference(unittest.TestCase):
    def test_vertical_step(self):
        w, h = 6, 5
        g = [0, 0, 0, 100, 100, 100] * h
        self.assertEqual(model.reference_filter("sobel", 1, g, w, h)[2 * w + 2], 255)   # 400 saturates
        self.assertEqual(model.reference_filter("prewitt", 1, g, w, h)[2 * w + 2], 255)  # 300 saturates
        self.assertEqual(model.reference_filter("sobel", 0, g, w, h)[2 * w + 2], 0)
        g = [0, 0, 0, 20, 20, 20] * h
        self.assertEqual(model.reference_filter("sobel", 2, g, w, h)[2 * w + 3], 80)


if __name__ == "__main__":
    unittest.main()
