"""Bit-accurate software model of video_processing (vid_proc.v + sqrt.v).

Two parts:
  * VideoProcessing: a cycle-by-cycle model of the RTL exactly as written,
    register for register, with non-blocking-assignment semantics. It is what the
    hardware computes, bugs included, and is checked bit for bit against the RTL
    by compare.py.
  * reference_filter: the textbook 3x3 Prewitt/Sobel on the same greyscale image,
    i.e. what the design was meant to compute. Used to measure how far the RTL is
    from the intended filter.

Pure standard library, Python 3.8+.
"""

L = 1800  # HDMI_LENGTH in vid_proc.v: line-buffer depth and XPtr saturation

TIMINGS = {
    # name: (hact, hfp, hsync, hbp, vact, vfp, vsync, vbp), from VideoOutput.h
    "1080p60": (1920, 88, 44, 148, 1080, 4, 5, 36),
    "720p60": (1280, 110, 40, 220, 720, 5, 5, 20),
}

# Kernels as written in vid_proc.v. Rows are outMatrix[0..2]; columns are the
# [23:16], [15:8], [7:0] fields, i.e. line-buffer index XPtr-1, XPtr, XPtr+1.
KERNELS = {
    "prewitt": {"Y": ((-1, -1, -1), (0, 0, 0), (1, 1, 1)),
                "X": ((-1, 0, 1), (-1, 0, 1), (-1, 0, 1))},
    "sobel": {"Y": ((-1, -2, -1), (0, 0, 0), (1, 2, 1)),
              "X": ((-1, 0, 1), (-2, 0, 2), (-1, 0, 1))},
}


def luma(word):
    """gray from vid_proc.v: shift-and-add luma on the {R,B,G}-packed word."""
    r, b, g = (word >> 16) & 255, (word >> 8) & 255, word & 255
    return ((r >> 2) + (r >> 5) + (r >> 6) + (g >> 1) + (g >> 4) + (g >> 5) + (b >> 3)) & 255


def apply_kernel(k, m):
    return sum(k[i][j] * m[i][j] for i in range(3) for j in range(3))


class VideoProcessing:
    """One video_processing instance, from the all-zero power-up state.

    mode is the cnt register (0 = Y gradient, 1 = X gradient, 2 = magnitude,
    other = white); gray_sw is sw[3] (greyscale bypass). n_rst is held high.
    """

    def __init__(self, variant, mode, gray_sw=False):
        self.k = KERNELS[variant]
        self.mode, self.gray_sw = mode, gray_sw
        self.buf = [[0] * L for _ in range(3)]
        self.xptr = self.wtptr = self.gray = self.out = 0
        self.m = [(0, 0, 0)] * 3          # outMatrix rows (left, centre, right)
        self.gx = self.gy = self.prod = 0  # sobelX/sobelY/sobelProd (PrewittX/...)
        # sqrt_fn state. Simulation semantics only, see sqrt_step.
        self.xn, self.sqrt_y, self.sqrt_x = 1, 0, 0
        self.o = (0, 0, 0, 0)              # o_vid_data, hsync, vsync, VDE

    def sqrt_step(self):
        """sqrt_fn as an event-driven simulator runs it.

        sqrt.v is a combinational always block that feeds xn back into itself;
        Vivado infers a 16-bit latch for xn (Synth 8-327) and the result is an
        asynchronous loop with no defined cycle behaviour on the FPGA. In
        simulation the block runs once per change of its input x, doing one
        Newton step from the previous xn, which is what this reproduces. It
        predicts the simulator, not the board.
        """
        x = self.prod & 0xFFFF            # 17-bit product into a 16-bit port
        if x == self.sqrt_x:
            return
        self.sqrt_x = x
        if x >= 0x8000 or x == 0:         # signed [15:0] x <= 0
            self.sqrt_y = 0
        else:
            self.xn = ((self.xn + x // self.xn) // 2) & 0xFFFF
            self.sqrt_y = self.xn

    def step(self, data, hs, vs, de):
        """One rising clock edge. Returns (o_vid_data, o_hsync, o_vsync, o_VDE)."""
        xptr, wt, m = self.xptr, self.wtptr, self.m

        # line-buffer block (later non-blocking assignments win)
        n_xptr = 0 if hs else xptr
        n_wt = 0 if vs else wt
        n_m = m
        if 0 < xptr < L - 1:
            order = ((0, 1, 2), (1, 2, 0), (2, 0, 1))[wt]
            n_m = [tuple(self.buf[b][xptr + d] for d in (-1, 0, 1)) for b in order]
            self.buf[wt][xptr] = self.gray        # reads above see the old value
            n_wt = (wt + 1) % 3
        if xptr < L:
            n_xptr = xptr + 1

        # output block
        n_out, n_gx, n_gy, n_prod = self.out, self.gx, self.gy, self.prod
        if self.gray_sw:
            n_out = self.gray
        elif xptr >= L:
            n_out = 255
        elif self.mode == 0:
            n_out = apply_kernel(self.k["Y"], m) & 255
        elif self.mode == 1:
            n_out = apply_kernel(self.k["X"], m) & 255
        elif self.mode == 2:
            n_gy = apply_kernel(self.k["Y"], m) & 255
            n_gx = apply_kernel(self.k["X"], m) & 255
            n_prod = self.gx * self.gx + self.gy * self.gy
            n_out = self.sqrt_y & 255             # 16-bit result into 8-bit wire
        else:
            n_out = 255
        self.o = (self.out * 0x010101, hs, vs, de)

        # commit
        self.gray = luma(data)
        self.xptr, self.wtptr, self.m = n_xptr, n_wt, n_m
        self.out, self.gx, self.gy, self.prod = n_out, n_gx, n_gy, n_prod
        self.sqrt_step()
        return self.o


def stream(frame, hact, vact, timing, frames=1):
    """Yield (data, hsync, vsync, de) per clock, matching tb_video_processing.v."""
    _, hfp, hsw, hbp, _, vfp, vsw, vbp = timing
    htot, vtot = hact + hfp + hsw + hbp, vact + vfp + vsw + vbp
    vs_start = (vact + vfp) * htot + hact + hfp
    vs_end = vs_start + vsw * htot
    data = 0
    for _ in range(frames):
        for v in range(vtot):
            for h in range(htot):
                de = v < vact and h < hact
                if de:
                    data = frame[v * hact + h]
                pos = v * htot + h
                yield (data, hact + hfp <= h < hact + hfp + hsw, vs_start <= pos < vs_end, de)


def run(variant, mode, gray_sw, frame, hact, vact, timing, frames=1):
    """Displayed output words (o_vid_data while o_vid_VDE=1), in order."""
    dut = VideoProcessing(variant, mode, gray_sw)
    out = []
    for s in stream(frame, hact, vact, timing, frames):
        o = dut.step(*s)
        if o[3]:
            out.append(o[0])
    return out


def reference_filter(variant, mode, gray_img, w, h):
    """Textbook 3x3 filter on a greyscale image (row-major list), same luma.

    Output per pixel: Y or X gradient (mode 0/1) or sqrt(X^2+Y^2) (mode 2),
    absolute value saturated to 0..255. Border pixels are 0.
    """
    from math import isqrt
    k = KERNELS[variant]
    out = [0] * (w * h)
    for r in range(1, h - 1):
        for c in range(1, w - 1):
            m = [[gray_img[(r + i) * w + c + j] for j in (-1, 0, 1)] for i in (-1, 0, 1)]
            gy, gx = apply_kernel(k["Y"], m), apply_kernel(k["X"], m)
            v = {0: abs(gy), 1: abs(gx), 2: isqrt(gx * gx + gy * gy)}[mode]
            out[r * w + c] = min(v, 255)
    return out


def write_hex(path, words):
    with open(path, "w") as f:
        f.writelines(f"{w:06x}\n" for w in words)


def read_hex(path):
    with open(path) as f:
        return [int(line, 16) for line in f if line.strip()]
