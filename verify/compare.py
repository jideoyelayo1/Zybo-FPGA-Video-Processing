"""Simulate the hand-written RTL with Icarus Verilog and check it bit for bit
against model.py, then derive latency, effective kernels, white band and
agreement with the textbook filter from the RTL outputs.

    python3 verify/compare.py               # needs iverilog and vvp on PATH
    python3 verify/compare.py --model-only  # no simulator: stimulus + expected outputs only

Writes verify/results/compare.txt. Stimulus, RTL output and model output for
every case, and each case's testbench plusargs (cases.txt), are left in
verify/build/ (git-ignored) so another simulator's output, e.g. Vivado xsim, can
be checked with a plain file diff. Exits non-zero if any case differs.
"""
import os
import platform
import random
import subprocess
import sys
from concurrent.futures import ProcessPoolExecutor

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
BUILD = os.path.join(HERE, "build")
sys.path.insert(0, HERE)
import model  # noqa: E402

SEED = 1
SHORT = 32  # active lines in the short frames; the RTL has no line counter
WHITE = 0xFFFFFF
IMPULSE_AT = 16  # row of the single white pixel; column = width // 2
MODES = [(0, False, "Y"), (1, False, "X"), (2, False, "mag"), (3, False, "white"), (0, True, "gray")]


def frames(w, h):
    rnd = random.Random(SEED)
    noise = [rnd.getrandbits(24) for _ in range(w * h)]
    squares = [0xC0C0C0 if ((r // 8) + (c // 8)) % 2 else 0x202020 for r in range(h) for c in range(w)]
    impulse = [0] * (w * h)
    impulse[IMPULSE_AT * w + w // 2] = WHITE
    return {"noise": noise, "squares": squares, "impulse": impulse}


def cases():
    out = []
    for timing in ("1080p60", "720p60"):
        w = model.TIMINGS[timing][0]
        for fname in ("noise", "squares", "impulse"):
            for variant in ("prewitt", "sobel"):
                for mode, gray, tag in MODES:
                    out.append((variant, timing, fname, w, SHORT, 2, mode, gray, tag))
    # one full-height 1080p frame per variant
    out.append(("sobel", "1080p60", "noise", 1920, 1080, 1, 1, False, "X"))
    out.append(("prewitt", "1080p60", "noise", 1920, 1080, 1, 0, False, "Y"))
    return out


def build(variant):
    src = os.path.join(ROOT, variant, f"{variant}.srcs", "sources_1", "new")
    vvp = os.path.join(BUILD, f"{variant}.vvp")
    cmd = ["iverilog", "-g2005", "-o", vvp, os.path.join(HERE, "tb_video_processing.v"),
           os.path.join(src, "vid_proc.v"), os.path.join(src, "sqrt.v")]
    if variant == "prewitt":
        cmd.insert(1, "-DPREWITT")
    subprocess.run(cmd, check=True, capture_output=True)
    return vvp


def case_name(case):
    variant, timing, fname, w, h, nfr, mode, gray, tag = case
    return f"{variant}_{timing}_{fname}_{h}_{tag}"


def plusargs(case, out):
    """Testbench plusargs for a case (Icarus vvp form; xsim takes -testplusarg each)."""
    variant, timing, fname, w, h, nfr, mode, gray, tag = case
    t = model.TIMINGS[timing]
    return [f"+in={os.path.join(BUILD, f'frame_{fname}_{w}x{h}.hex')}", f"+out={out}", f"+mode={mode}",
            f"+gray={int(gray)}", f"+frames={nfr}", f"+hact={t[0]}", f"+hfp={t[1]}", f"+hsync={t[2]}",
            f"+hbp={t[3]}", f"+vact={h}", f"+vfp={t[5]}", f"+vsync={t[6]}", f"+vbp={t[7]}"]


def run_case(case, model_only=False):
    variant, timing, fname, w, h, nfr, mode, gray, tag = case
    name = case_name(case)
    want = model.run(variant, mode, gray, frames(w, h)[fname], w, h, model.TIMINGS[timing], nfr)
    model.write_hex(os.path.join(BUILD, f"model_{name}.hex"), want)
    if model_only:
        return None
    rtl_hex = os.path.join(BUILD, f"rtl_{name}.hex")
    subprocess.run(["vvp", "-n", os.path.join(BUILD, f"{variant}.vvp")] + plusargs(case, rtl_hex),
                   check=True, capture_output=True)
    with open(rtl_hex) as f:
        rtl = f.read().split()
    bad = sum(1 for a, b in zip(want, rtl) if "x" in b.lower() or int(b, 16) != a)
    bad += abs(len(want) - len(rtl))
    rtl_last = [int(b, 16) & 255 for b in rtl[-w * h:]] if not bad else None
    return case, len(want), len(rtl), bad, rtl_last


def decode_weight(v):
    """Kernel weight k with (k * luma(white)) mod 256 == v."""
    lw = model.luma(WHITE)
    return next(k for k in range(-8, 9) if (k * lw) & 255 == v)


def best_alignment(out, ref, w, h):
    """Highest exact-match rate of out shifted by (dy, dx) against ref, fixed region."""
    region = [(r, c) for r in range(4, h - 5) for c in range(8, 1590)]
    best = (0.0, 0, 0)
    for dy in range(5):
        for dx in range(7):
            eq = sum(out[(r + dy) * w + c + dx] == ref[r * w + c] for r, c in region)
            best = max(best, (eq / len(region), dy, dx))
    return best, len(region)


def main():
    os.makedirs(BUILD, exist_ok=True)
    for w in (1920, 1280):
        for fname, fr in frames(w, SHORT).items():
            model.write_hex(os.path.join(BUILD, f"frame_{fname}_{w}x{SHORT}.hex"), fr)
    model.write_hex(os.path.join(BUILD, "frame_noise_1920x1080.hex"), frames(1920, 1080)["noise"])
    with open(os.path.join(BUILD, "cases.txt"), "w") as f:
        for c in cases():
            f.write(f"model_{case_name(c)}.hex  {' '.join(plusargs(c, '<your_output>.hex'))}\n")
    if "--model-only" in sys.argv:
        with ProcessPoolExecutor() as ex:
            list(ex.map(run_case, cases(), [True] * len(cases())))
        print(f"stimulus, expected outputs and plusargs (cases.txt) written to {BUILD}")
        return
    for v in ("prewitt", "sobel"):
        build(v)
    with ProcessPoolExecutor() as ex:
        results = list(ex.map(run_case, cases()))

    iverilog = subprocess.run(["iverilog", "-V"], capture_output=True, text=True).stdout.splitlines()[0]
    lines = [
        "# RTL (Icarus) vs bit-accurate model, and figures derived from the RTL outputs",
        f"# host: {platform.machine()} {platform.system()} {platform.release()}; {iverilog}; "
        f"Python {platform.python_version()}",
        f"# stimulus seed {SEED}; short frames {SHORT} active lines x 2 frames; "
        "comparison over every displayed (o_vid_VDE=1) output word",
        "",
        "variant  timing   frame    lines frames mode   pixels_model pixels_rtl mismatches",
    ]
    failed = 0
    last = {}
    for case, n_model, n_rtl, bad, rtl_last in results:
        variant, timing, fname, w, h, nfr, mode, gray, tag = case
        failed += bad != 0
        last[(variant, timing, fname, h, tag)] = rtl_last
        lines.append(f"{variant:8} {timing:8} {fname:8} {h:5} {nfr:6} {tag:6} {n_model:12} {n_rtl:10} {bad:10}")
    lines.append(f"\ncases: {len(results)}, output words compared: {sum(r[1] for r in results)}, "
                 f"cases with any mismatch: {failed}")

    if not failed:
        lines += derived(last)
    report = "\n".join(lines) + "\n"
    os.makedirs(os.path.join(HERE, "results"), exist_ok=True)
    with open(os.path.join(HERE, "results", "compare.txt"), "w") as f:
        f.write(report)
    print(report)
    sys.exit(1 if failed else 0)


def derived(last):
    lines = ["", "## Derived from the RTL outputs (second frame of each short run)"]
    w, h, r0 = 1920, SHORT, IMPULSE_AT
    c0 = w // 2
    for variant in ("prewitt", "sobel"):
        g = last[(variant, "1080p60", "impulse", h, "gray")]
        pts = [(r - r0, c - c0, g[r * w + c]) for r in range(h) for c in range(w) if g[r * w + c]]
        lines.append(f"{variant} greyscale bypass: impulse (row {r0}, col {c0}) displayed at "
                     f"(d_line, d_col, value) = {pts}")
        for tag in ("Y", "X"):
            o = last[(variant, "1080p60", "impulse", h, tag)]
            taps = [(r - r0, c - c0, decode_weight(o[r * w + c]))
                    for r in range(h) for c in range(1500) if o[r * w + c]]
            lines.append(f"{variant} {tag} gradient impulse response (d_line, d_col, weight): {taps}")
    for timing in ("1080p60", "720p60"):
        tw = model.TIMINGS[timing][0]
        o = last[("sobel", timing, "impulse", h, "Y")]
        band = []
        for r in range(h):
            white = [c for c in range(tw) if o[r * tw + c] == 255]
            band.append((len(white), white[0] if white else None))
        lines.append(f"{timing} Y mode, black frame: (white columns, first white column) per line: "
                     f"{sorted(set(band), key=str)} over {h} lines; lines fully white: "
                     f"{sum(n == tw for n, _ in band)}")
    lines.append("")
    lines.append("Agreement with the textbook filter on the noise frame, 1080p timing, best of 35 "
                 "alignments (d_line 0..4, d_col 0..6):")
    noise = frames(w, h)["noise"]
    gray = [model.luma(p) for p in noise]
    for variant in ("prewitt", "sobel"):
        for mode, tag in ((0, "Y"), (1, "X"), (2, "mag")):
            o = last[(variant, "1080p60", "noise", h, tag)]
            ref = model.reference_filter(variant, mode, gray, w, h)
            (rate, dy, dx), n = best_alignment(o, ref, w, h)
            lines.append(f"  {variant} {tag:3} vs |G| saturated: {100 * rate:.2f}% of {n} px "
                         f"(best at d_line {dy}, d_col {dx})")
            if mode < 2:
                k = model.KERNELS[variant][tag]
                wrap = [0] * (w * h)
                for r in range(1, h - 1):
                    for c in range(1, w - 1):
                        m = [[gray[(r + i) * w + c + j] for j in (-1, 0, 1)] for i in (-1, 0, 1)]
                        wrap[r * w + c] = model.apply_kernel(k, m) & 255
                (rate, dy, dx), n = best_alignment(o, wrap, w, h)
                lines.append(f"  {variant} {tag:3} vs G mod 256 (RTL's own wrap): {100 * rate:.2f}% of {n} px "
                             f"(best at d_line {dy}, d_col {dx})")
    lines.append("  (two independent uniform 8-bit values agree 1/256 = 0.39% of the time; noise makes G mod 256 near uniform)")
    return lines


if __name__ == "__main__":
    main()
