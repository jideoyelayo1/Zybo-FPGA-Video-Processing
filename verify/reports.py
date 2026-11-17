"""Print utilisation and timing figures from the Vivado reports committed in
<project>/<project>.runs/. Reads the tool's own report text; computes nothing
except the period the worst pixel-clock path would need (constraint - WNS).

    python3 verify/reports.py
"""
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def read(*parts):
    with open(os.path.join(ROOT, *parts), encoding="utf-8", errors="replace") as f:
        return f.read()


def row(text, label):
    """Used and Util% columns of a '| label | used | fixed | avail | util% |' row."""
    m = re.search(r"^\|\s*" + re.escape(label) + r"\s*\|\s*([\d.]+)\s*\|\s*\d+\s*\|\s*(\d*)\s*\|\s*([\d.]*)\s*\|", text, re.M)
    return f"{m.group(1)} ({m.group(3)}%)" if m.group(3) else m.group(1)


def header(text):
    return {k: re.search(r"\| " + k + r"\s*: (.*)", text).group(1).strip()
            for k in ("Tool Version", "Date", "Device")}


def main():
    for p in ("prewitt", "sobel"):
        runs = (p, f"{p}.runs")
        placed = read(*runs, "impl_1", "system_wrapper_utilization_placed.rpt")
        ooc = read(*runs, "system_video_processing_0_0_synth_1", "system_video_processing_0_0_utilization_synth.rpt")
        timing = read(*runs, "impl_1", "system_wrapper_timing_summary_routed.rpt")
        part = re.search(r'<Option Name="Part" Val="([^"]+)"', read(p, f"{p}.xpr")).group(1)
        print(f"## {p}  (project part {part})")
        for name, rpt, path in (("whole design, placed", placed, "impl_1/system_wrapper_utilization_placed.rpt"),
                                ("video_processing only, synthesised out of context", ooc,
                                 "system_video_processing_0_0_synth_1/system_video_processing_0_0_utilization_synth.rpt")):
            h = header(rpt)
            print(f"- {name}: {p}/{p}.runs/{path} ({h['Tool Version']}; {h['Date']}; {h['Device']})")
            luts = "Slice LUTs*" if "Slice LUTs*" in rpt else "Slice LUTs"
            for label in (luts, "LUT as Logic", "LUT as Distributed RAM", "Slice Registers",
                          "Register as Flip Flop", "Register as Latch", "Block RAM Tile", "DSPs"):
                print(f"    {label.rstrip('*'):24} {row(rpt, label)}")
        h = header(timing)
        print(f"- timing: {p}/{p}.runs/impl_1/system_wrapper_timing_summary_routed.rpt ({h['Date']})")
        s = re.search(r"Design Timing Summary.*?\n\s*-+.*?\n\s*(-?[\d.]+)\s+(-?[\d.]+)\s+(\d+)\s+(\d+)\s+(-?[\d.]+)\s+(-?[\d.]+)\s+(\d+)\s+(\d+)",
                      timing, re.S)
        print(f"    design WNS {s.group(1)} ns, TNS {s.group(2)} ns, {s.group(3)} of {s.group(4)} setup endpoints failing; "
              f"WHS {s.group(5)} ns, THS {s.group(6)} ns, {s.group(7)} of {s.group(8)} hold endpoints failing")
        print("    " + ("met" if "All user specified timing constraints are met" in timing else
                        "report says: Timing constraints are not met."))
        intra = timing.split("| Intra Clock Table")[1]
        for clk in ("pixel_dynclk", "dphy_hs_clock_p"):
            period = re.search(r"^" + clk + r"\s+\{[^}]*\}\s+([\d.]+)\s+([\d.]+)", timing, re.M)
            r = re.search(r"^" + clk + r"\s+(-?[\d.]+)\s+(-?[\d.]+)\s+(\d+)\s+(\d+)", intra, re.M)
            line = (f"    {clk}: period {period.group(1)} ns ({period.group(2)} MHz); WNS {r.group(1)} ns, "
                    f"TNS {r.group(2)} ns, {r.group(3)} of {r.group(4)} endpoints failing")
            if clk == "pixel_dynclk":
                line += f"; worst path needs about {float(period.group(1)) - float(r.group(1)):.3f} ns"
            print(line)
        sect = timing.split("From Clock:  pixel_dynclk\n  To Clock:  pixel_dynclk")[1]
        for path in re.findall(r"Slack \(VIOLATED\) :\s+(-[\d.]+)ns.*?Source:\s+(\S+).*?Destination:\s+(\S+)"
                               r".*?Data Path Delay:\s+([\d.]+)ns.*?Logic Levels:\s+(\d+)", sect, re.S)[:10]:
            sl, src, dst, dly, lv = path
            print(f"    path slack {sl} ns, {dly} ns over {lv} levels: "
                  f"{src.replace('system_i/', '')} -> {dst.replace('system_i/', '')}")
        print()


if __name__ == "__main__":
    main()
