# Zybo FPGA Video Processing

Realtime video processing with Prewitt and Sobel Filters targeting Zybo-Z7-20 FPGA.

## Table of Contents
- [Introduction](#introduction)
- [Features](#features)
- [What is in the repository](#what-is-in-the-repository)
- [Getting Started](#getting-started)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Known limitations](#known-limitations)
- [Verification without hardware](#verification-without-hardware)
- [Regenerating the utilisation and timing reports](#regenerating-the-utilisation-and-timing-reports)
- [Demonstration](#demonstration)
- [Contributing](#contributing)
- [License](#license)

## Introduction
This project applies Prewitt and Sobel edge-detection filters to live camera video on the Zybo-Z7-20 FPGA. A Digilent Pcam 5C camera (OV5640, MIPI CSI-2) feeds Digilent's capture chain into DDR memory; frames are read back in display timing, pass through the hand-written Verilog filter `video_processing`, and leave over HDMI.

## Features
- Edge detection on the live HDMI output stream, one pixel per clock (148.5 MHz pixel clock at 1080p60)
- Prewitt and Sobel filters, as two separate Vivado projects (`prewitt/`, `sobel/`)
- Modes: Y gradient, X gradient, gradient magnitude, and a greyscale bypass
- Filter footprint (Vivado out-of-context synthesis, April 2023 reports): 4,845-4,872 LUTs, 2,436 of them LUT RAM for the line buffers; 246-250 registers, 16 of them latches; no block RAM and no DSP slices. Details are in [RESULTS.md](RESULTS.md).

## What is in the repository
Two complete Vivado 2019.1 projects built on Digilent's Zybo Z7-20 Pcam 5C demo. The hand-written filter is four Verilog files, 410 lines in total:
`prewitt/prewitt.srcs/sources_1/new/{vid_proc.v,sqrt.v}` and `sobel/sobel.srcs/sources_1/new/{vid_proc.v,sqrt.v}`.
Everything else is Digilent or Xilinx IP, Digilent's demo application, or Vivado/SDK output. The VHDL files are all vendor or generated code. [SOURCES.md](SOURCES.md) has the full inventory and how it was checked.

## Getting Started
Follow these instructions to set up and run the project on your Zybo-Z7-20 FPGA board.

### Prerequisites
- Zybo-Z7-20 FPGA board
- Digilent Pcam 5C camera module, on the board's camera (MIPI CSI-2) connector
- HDMI display, on the board's HDMI TX port
- Vivado Design Suite 2019.1 and Xilinx SDK 2019.1 (the version the projects and reports were made with)

### Installation
1. Clone the repository:
    ```sh
    git clone https://github.com/jideoyelayo1/Zybo-FPGA-Video-Processing.git
    ```
2. Open the project in Vivado: `File > Project > Open`, then `sobel/sobel.xpr` or `prewitt/prewitt.xpr`. Do not create a new project; both are complete.
3. Generate the bitstream (`Flow Navigator > Generate Bitstream`) and export the hardware (`File > Export > Export Hardware`, include bitstream).
4. Launch the SDK (`File > Launch SDK`). The workspace `<variant>/<variant>.sdk` already holds the `pcam_vdma_hdmi` C++ application (Digilent's demo, unmodified) and its board support package.
5. Program the FPGA and run `pcam_vdma_hdmi` from the SDK.

## Usage
1. Connect the Pcam 5C and an HDMI display, then power on the board and run the application from the SDK.
2. The output starts at 1920x1080, 60 Hz, with the camera at 1080p30. The application's UART menu can change the resolution (1280x720 or 1920x1080), focus, gamma and white balance.
3. Controls, all in `vid_proc.v`:

    | Control | Effect |
    |---|---|
    | BTN0 / BTN1 | next / previous mode |
    | BTN2 | mode 0 |
    | BTN3 | mode 8 (white screen), Prewitt build only |
    | SW3 | greyscale bypass, overrides the mode |
    | LD0-LD3 | current mode number in binary |

    Modes: 0 = Y gradient, 1 = X gradient, 2 = magnitude sqrt(X²+Y²), 3-15 = white. SW0-SW2 are not used.

## Known limitations
Found by reading the RTL and simulating it; the evidence and the commands are in [RESULTS.md](RESULTS.md). None of these have been checked on the board.
- **Timing is not met.** The routed reports committed in `*/*.runs/impl_1/` show a pixel-clock worst negative slack of -92.2 ns (Prewitt) and -90.3 ns (Sobel) against a 6.7 ns period. The worst paths run through the combinational divider in `sqrt.v` (magnitude mode) and through the line-buffer reads used by every gradient mode.
- The line-buffer write pointer advances every pixel instead of every line, so the filter does not see a 3x3 neighbourhood. Its impulse response spans four lines.
- Gradients are truncated to 8 bits: negative edges wrap around instead of showing their absolute value.
- `sqrt.v` infers a latch inside a combinational loop, so the magnitude mode has no defined cycle behaviour in hardware.
- At 1080p the rightmost 310 columns are white in the gradient modes; at 720p every second line is white.

## Verification without hardware
A frame-file testbench, a bit-accurate Python model of the filter and a textbook reference filter are in `verify/`. They need Python 3.8+; `compare.py` also needs [Icarus Verilog](https://steveicarus.github.io/iverilog/) (`iverilog`, `vvp`).
```sh
python3 -m unittest discover -s verify -v   # model checks, seconds, no simulator
python3 verify/compare.py                   # RTL vs model on 62 cases, about a minute
python3 verify/reports.py                   # figures from the committed Vivado reports
```
The same testbench runs in Vivado's simulator. `python3 verify/compare.py --model-only` writes the stimulus, the expected outputs and each case's plusargs (`verify/build/cases.txt`) without needing Icarus. Then, for example:
```sh
xvlog verify/tb_video_processing.v sobel/sobel.srcs/sources_1/new/vid_proc.v sobel/sobel.srcs/sources_1/new/sqrt.v
xelab tb_video_processing -s tb
xsim tb -R -testplusarg in=verify/build/frame_noise_1920x32.hex -testplusarg out=xsim_out.hex -testplusarg mode=0 -testplusarg vact=32 -testplusarg frames=2
```
Compare `xsim_out.hex` with `verify/build/model_sobel_1080p60_noise_32_Y.hex` (`diff`, or `fc` on Windows). For the Prewitt files, add `-d PREWITT` to `xvlog`. This xsim route has not been run yet.

## Regenerating the utilisation and timing reports
This needs Vivado 2019.1 and has not been run since April 2023. The steps below are untested.
1. Open `sobel/sobel.xpr` (then repeat for `prewitt/prewitt.xpr`).
2. If Vivado says the IP repository is missing or IP is locked: the `.xpr` points at `../../FPGA/Zybo-Z7-20-pcam-5c-2019.1/...`, outside this repository. Clone Digilent's [Zybo-Z7-20-pcam-5c](https://github.com/Digilent/Zybo-Z7-20-pcam-5c) at tag `v2019.1-1` with `--recursive`, add its `repo` folder under `Tools > Settings > IP > Repository`, then run `Reports > Report IP Status`.
3. `vid_proc.v` has changed since the last build (instance name and one non-blocking assignment; the logic is the same). Open the block design and click `Refresh Changed Modules`, or run `update_module_reference system_video_processing_0_0` in the Tcl console.
4. Run the build and write the extra reports from the Tcl console:
    ```tcl
    reset_run synth_1
    launch_runs impl_1 -to_step write_bitstream -jobs 4
    wait_on_run impl_1
    open_run impl_1
    set out [file normalize [get_property DIRECTORY [current_project]]/../reports]
    file mkdir $out
    report_utilization -hierarchical -file $out/sobel_utilization_hierarchical.rpt
    report_timing_summary -max_paths 10 -file $out/sobel_timing_summary_routed.rpt
    ```
5. Vivado rewrites its own reports at the paths `verify/reports.py` reads:
    - `<variant>/<variant>.runs/impl_1/system_wrapper_utilization_placed.rpt`
    - `<variant>/<variant>.runs/impl_1/system_wrapper_timing_summary_routed.rpt`
    - `<variant>/<variant>.runs/system_video_processing_0_0_synth_1/system_video_processing_0_0_utilization_synth.rpt`

    Commit those, the new `reports/*.rpt` files and the new `*.runs/impl_1/system_wrapper.bit`. Then run `python3 verify/reports.py > verify/results/reports.txt` and update section 1 of [RESULTS.md](RESULTS.md).

## Demonstration
Watch the demonstration video on YouTube:
- [Prewitt Filter Demonstration](https://www.youtube.com/watch?v=vdC7v7xRRTg)
- [Sobel Filter Demonstration](https://www.youtube.com/watch?v=ISVAD1BXLU4)

## Contributing
Contributions are welcome! Please fork the repository and create a pull request with your changes.

## License
This project is licensed under the Apache-2.0 License. See the [LICENSE](LICENSE) file for details.
