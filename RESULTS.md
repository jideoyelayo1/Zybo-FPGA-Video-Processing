# Results

Three kinds of figure appear here, and each is labelled:

- **Tool output**: read from the Vivado 2019.1 reports committed in `*/*.runs/` in
  April 2023. Not re-run; Vivado was not available for this work.
- **RTL simulation**: the hand-written Verilog run in Icarus Verilog with
  `verify/tb_video_processing.v`, checked bit for bit against the software model in
  `verify/model.py`.
- **Derived from code**: read from the RTL and confirmed by the simulation above.
  Not measured on the board.

Nothing here was measured on a Zybo board. The simulations are deterministic, so
results are exact counts, not samples. There is no spread to report.

Reproduce:

```sh
python3 verify/reports.py                   # report figures   -> verify/results/reports.txt
python3 -m unittest discover -s verify -v   # model checks, no simulator needed
python3 verify/compare.py                   # RTL vs model     -> verify/results/compare.txt
```

`compare.py` needs `iverilog` and `vvp` on `PATH`. The recorded run used an Apple M1
Pro (arm64, macOS, Darwin 27.0.0), Icarus Verilog 13.0 (stable), Python 3.15.0 and
stimulus seed 1. Two runs took 49.6 s and 52.5 s wall-clock on 10 cores.

## 1. Utilisation and timing (tool output)

Part `xc7z020clg400-1` (Zybo Z7-20), Vivado v2019.1 build 2552052. Report dates
are 24 April 2023.

| | Prewitt | Sobel |
|---|---:|---:|
| **Whole design, placed** (`impl_1/system_wrapper_utilization_placed.rpt`) | | |
| Slice LUTs | 12,616 (23.71%) | 12,592 (23.67%) |
| of which LUT as distributed RAM | 2,482 | 2,482 |
| Slice registers | 10,951 (10.29%) | 10,947 (10.29%) |
| of which latches | 16 | 16 |
| Block RAM tiles | 10.5 (7.50%) | 10.5 (7.50%) |
| DSP slices | 0 | 0 |
| **Filter only, `video_processing`, synthesised out of context** (`system_video_processing_0_0_synth_1/..._utilization_synth.rpt`) | | |
| Slice LUTs | 4,872 (9.16%) | 4,845 (9.11%) |
| LUT as logic / LUT as distributed RAM | 2,436 / 2,436 | 2,409 / 2,436 |
| Slice registers (flip-flops + latches) | 250 (234 + 16) | 246 (230 + 16) |
| Block RAM tiles, DSP slices | 0, 0 | 0, 0 |
| **Timing, routed** (`impl_1/system_wrapper_timing_summary_routed.rpt`) | | |
| Pixel clock constraint (`pixel_dynclk`, `timing.xdc`) | 6.734 ns (148.5 MHz) | 6.734 ns (148.5 MHz) |
| Pixel clock WNS / TNS | −92.154 ns / −10,627.920 ns | −90.287 ns / −13,909.632 ns |
| Pixel clock failing setup endpoints | 3,950 of 25,904 | 3,880 of 25,896 |
| Design WNS / TNS | −92.154 ns / −10,632.780 ns | −90.287 ns / −13,914.494 ns |
| Design WHS / THS (hold) | −1.038 ns / −2.033 ns, 2 endpoints | −1.038 ns / −2.033 ns, 2 endpoints |
| Report verdict | "Timing constraints are not met." | "Timing constraints are not met." |

**The design does not meet timing, and the committed bitstreams were written from
these failing implementations.** All ten worst pixel-clock paths listed in each
report start and end inside `video_processing_0`. They fall into two groups:

1. **Magnitude path.** `PrewittProd_reg`/`sobelProd_reg` → `sqrt_fn` → `out_reg`:
   96.1–98.8 ns of logic and routing over 328–330 logic levels, 293–295 of them
   `CARRY4`. The cause is the combinational 16-bit divide inside `sqrt_fn`. At
   constraint minus WNS, the worst path needs about 98.9 ns (Prewitt) and 97.0 ns
   (Sobel), roughly 10 MHz against the 148.5 MHz pixel clock. That figure is
   arithmetic on the report, not a separate run.
2. **Line-buffer read.** `XPtr_reg` → LUT RAM → `outMatrix`/`out`: 17.8–20.4 ns,
   slack −11.1 ns (Sobel) and −13.7 ns (Prewitt). This path is used in every
   gradient mode, not only the magnitude.

The methodology report adds `TIMING-20 Non-clocked latch` ×16: the `xn` latch in
`sqrt_fn`, from synthesis warning `Synth 8-327`.

The two D-PHY input paths (`dphy_hs_clock_p`, −2.450 ns setup and −1.038 ns hold)
are in Digilent's MIPI receiver, not in the owner's code. Whether the unmodified
Digilent demo shows the same violation was not checked.

The 10.5 block RAM tiles belong to the vendor IP. The filter's three 1,800-entry
line buffers are LUT RAM (2,436 LUTs).

## 2. RTL against the bit-accurate model (RTL simulation)

`verify/model.py` models `vid_proc.v` and `sqrt.v` cycle by cycle, register for
register, with non-blocking semantics. It reproduces the bugs listed in section 4.
`compare.py` drives both the RTL and the model with the same stream and compares
every displayed output word (`o_vid_VDE = 1`).

The stream is shaped from the vendor code rather than assumed:

- Line and frame order follow the VTC generator. Polarity and porches come from
  `VideoOutput.h`.
- vsync is aligned to the hsync start, as `xvtc.c` sets it.
- During blanking the data holds the last active pixel, because
  `v_axi4s_vid_out` in master mode loads data only during active video.
- Registers and LUT RAM start at 0, as on the FPGA after configuration.

Cases:

- Short runs: {Prewitt, Sobel} × {1080p60, 720p60 timing} × {uniform noise
  (seed 1), 8×8 squares, single white pixel} × {Y, X, magnitude, white, greyscale
  bypass}. Each run is 2 frames of 32 active lines; the RTL has no line counter, so
  the frame height does not change its behaviour.
- Two full 1920×1080 frames: Sobel X and Prewitt Y.

**Result: 62 of 62 cases bit-identical, 10,291,200 output words, 0 mismatches**
(`verify/results/compare.txt`).

Two edits to the RTL were needed for a simulator to give the hardware's answer.
Neither changes the synthesised logic:

- **Unnamed instance.** `sqrt_fn (` had no instance name. That is illegal Verilog:
  Vivado accepts it and calls the instance `nolabel_line174` (Prewitt) or
  `nolabel_line169` (Sobel), but Icarus and Verilator reject the file. It is now
  `sqrt_fn sqrt_inst (`.
- **Blocking assignment.** `gray = ...` was a blocking assignment in a clocked
  block, read by two other clocked blocks. Synthesis builds a register either way.
  Simulation, however, races. With the original line, Icarus disagreed with register
  semantics on 100,903 of 122,880 output words (Sobel, mode Y, noise). It is now
  `gray <= ...`.

The magnitude mode matches only under simulation semantics, and only because the
testbench re-applies `sqrt.v`'s own `initial xn = 1` after time 0. Without that,
Icarus holds `xn` at X for the whole run. On the FPGA, `sqrt_fn` is a latch inside
an asynchronous loop and its cycle behaviour is not defined. Treat magnitude-mode
simulation output as a description of the simulator, not of the board.

## 3. Frame format and latency (derived from code, checked in RTL simulation)

**Frame format the RTL assumes:**

- **Pixels.** 24-bit `{R,B,G}` pixels at one per clock. The order was checked
  through the vendor chain: `AXI_BayerToRGB` packs R,B,G, gamma correction keeps the
  order, and `rgb2dvi` reads R=[23:16], B=[15:8], G=[7:0]. So `{red, blu, gre} =
  i_vid_data` is correct.
- **Greyscale.** Luma ≈ 0.297 R + 0.594 G + 0.125 B, computed with shifts. Each
  shift truncates, so white maps to 253, not 255.
- **Horizontal position.** Active-high hsync. `XPtr` counts from the start of hsync
  and saturates at 1,800, so the line period must exceed 1,800 clocks.
- **1080p60** (2,200 clocks per line): active video starts 192 clocks after the
  hsync start. Active columns 0–1609 are filtered and **columns 1610–1919, the
  rightmost 310, are always white** in the three gradient modes.
- **720p60** (1,650 clocks per line): `XPtr` has not saturated when the next hsync
  arrives, and the hsync reset is overridden by the increment (section 4). It
  therefore resets every second line, and **every second line is entirely white** in
  the gradient modes (16 of 32 lines in the test).

**Latency.** The data path has more registers than the sync path, so the picture
is also displaced against the syncs:

| Mode | Registers on the data path | Latency | Displayed offset |
|---|---|---|---|
| Greyscale bypass (`sw[3]`) | `gray`, `out`, `o_vid_data`; syncs have 1 | 3 clocks | 2 pixels right |
| Y or X gradient | `gray`, line buffer, `outMatrix`, `out`, `o_vid_data` | window centre to display: 2 lines + 4 clocks = **4,404 clocks = 29.66 µs** at 1080p60 (148.5 MHz). Newest pixel used to display: 5 clocks | 2 lines down, 3 pixels right |
| Magnitude | as Y/X plus `sobelX/Y`, `sobelProd` | Y/X + 2 clocks (read from code) | 2 lines, 5 pixels |

The window-centre figure is the time from the input pixel the window is nominally
centred on (line r−2) to the display of the output. This is the filter alone. The
camera-to-HDMI latency also includes the VDMA frame buffer in DDR, which this work
does not cover.

**Throughput.** One pixel per clock with no back-pressure, so the filter runs at the
output pixel rate: 148.5 MHz at 1080p60, blanking included. That holds by
construction, provided timing is met, and here it is not. By default the camera runs
at 1080p30 (`main.cc`) and the HDMI output at 60 Hz, so each camera frame passes
through the filter twice.

## 4. Behaviour against the textbook filter (software reference)

`model.reference_filter` is the textbook 3×3 Prewitt/Sobel on the same greyscale
image, giving |G| saturated to 0–255, or sqrt(Gx²+Gy²) for the magnitude.

**Impulse response** (RTL simulation, one white pixel, values decoded to kernel
weights, offsets in lines and pixels):

| | RTL taps (d_line, d_col: weight) | Textbook |
|---|---|---|
| Sobel Y | (0,4:+1) (1,2:−1) (1,3:+2) (2,2:+1) (2,4:−1) (3,3:−2) | +1 +2 +1 on one line, −1 −2 −1 two lines later |
| Sobel X | (0,4:−1) (1,2:+1) (1,4:−2) (2,2:+1) (2,4:−1) (3,2:+2) | −1/+1, −2/+2, −1/+1 down three lines, two columns apart |
| Prewitt Y | (0,4:+1) (1,2:−1) (1,3:+1) (2,2:+1) (2,4:−1) (3,3:−1) | +1 +1 +1, then −1 −1 −1 two lines later |
| Prewitt X | (0,4:−1) (1,2:+1) (1,4:−1) (2,2:+1) (2,4:−1) (3,2:+1) | −1/+1 down three lines |

The same six taps appear at three different pixel phases, so the RTL is still a
fixed linear filter (mod 256). It spans four lines, though, and its taps are not a
3×3 window. The taps sum to zero, so flat regions give 0 and the output is non-zero
only near intensity changes. It is an edge-like map, but not the Prewitt or Sobel
gradient.

**Agreement on uniform noise**, 1080p timing, 36,386 pixels, best of 35 alignments:

| | vs abs-saturated |G| | vs the RTL's own G mod 256 |
|---|---:|---:|
| Prewitt Y / X / magnitude | 0.46% / 0.50% / 0.32% | 0.46% / 0.56% / – |
| Sobel Y / X / magnitude | 0.44% / 0.41% / 0.23% | 0.44% / 0.45% / – |

Two independent uniform 8-bit values agree 0.39% of the time. Even judged by its own
wrap-around convention, the RTL agrees with the textbook filter only at chance
level. The window bug alone accounts for that.

### Bugs found (in `vid_proc.v`; line numbers are the Sobel copy, Prewitt is +1 to +5)

1. **The write pointer advances every pixel, not every line** (lines 68–92). The
   `wtPtr <= ...` assignments sit inside the per-pixel `case`, so the three line
   buffers are interleaved column by column. This causes the four-line, non-3×3
   impulse response above. The likely fix is to advance `wtPtr` once per line, at
   the hsync.
2. **The hsync reset of `XPtr` is overridden** (line 66 against line 93). The later
   `XPtr <= XPtr + 1` wins whenever `XPtr < 1800`. `XPtr` therefore counts from the
   hsync start, not from active video: the result is the 310-column white band at
   1080p and every second line white at 720p. Fix: reset on the start of active
   video (`i_vid_VDE` rising), or make the reset an `else` branch.
3. **Gradients are truncated to 8 bits** (lines 141–155). Negative values wrap, so
   a strong negative edge is drawn almost black (−253 → 3), and values over 255 wrap
   too. Fix: take the absolute value and saturate.
4. **The magnitude is computed from wrapped inputs.** The 17-bit
   `sobelProd`/`PrewittProd` drives a 16-bit signed port, so any sum of squares of
   32,768 or more reads as negative and outputs 0. The 16-bit result is cut to 8
   bits. These are Vivado warnings `Synth 8-689` ×2.
5. **`sqrt_fn` is not a square root in hardware** (`sqrt.v`). It is a combinational
   block that feeds its own output back: Vivado infers a 16-bit latch (`Synth
   8-327`, `TIMING-20`) around a 16-bit divider. This is the −92 ns path. In
   simulation it performs one Newton step per input change, from an X start unless
   initialised. Fix: a pipelined integer square root, a lookup table, or the
   |Gx|+|Gy| approximation.
6. **Syncs and data are misaligned.** The syncs are delayed one clock; the data is
   delayed 3 clocks (greyscale), 4 (Y/X) or 6 (magnitude), plus two lines in the
   gradient modes. The picture is shifted 2, 3 or 5 pixels right against the syncs,
   and differently per mode.
7. **The buttons are neither synchronised nor debounced.** A bouncing press could
   step more than one mode. This was not checked on the board.
8. Unused: `HDMI_DEPTH`, `DATA_SIZE`, `tmpR/tmpG/tmpB` (Prewitt), `sw[0..2]`.

Bugs 1–6 change what the hardware computes. Fixing them needs Vivado
re-implementation and checking on the board, so they are **not** fixed here; the
committed bitstreams, reports and demonstration videos all correspond to the
current logic. The two edits in section 2 do not change the netlist; they only make
the RTL legal and give simulation the same semantics.

## 5. Not measured here (owner-only: needs Vivado or the board)

- Re-running synthesis and implementation after this change, to confirm the netlist
  and reports are unchanged apart from the instance name (`nolabel_line174` or
  `nolabel_line169` → `sqrt_inst`). Steps are in the README.
- A hierarchical utilisation report (`report_utilization -hierarchical`) for the
  in-context filter. The figures above are out-of-context synthesis.
- Running `verify/tb_video_processing.v` in Vivado xsim and diffing against
  `verify/build/model_*.hex`.
- Whether the board output matches the RTL simulation, given the failing timing,
  especially the line-buffer path that every gradient mode uses.
- End-to-end camera-to-HDMI latency, which includes VDMA frame buffering in DDR.
- Power: `impl_1/system_wrapper_power_routed.rpt` exists but is not quoted here.
- Speed against a software filter on the Zynq's Arm cores. Software speed on this
  Mac would not be comparable.
