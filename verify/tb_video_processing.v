`timescale 1ns / 1ps

// Frame-file testbench for video_processing (Prewitt or Sobel variant).
//
// Reads one RGB frame (HACT*VACT words of 24-bit i_vid_data, hex, one per line,
// packed {R,B,G} as the block design delivers it), streams it FRAMES times as a
// one-pixel-per-clock video signal shaped like the vendor chain's output, and
// writes every o_vid_data word with o_vid_VDE=1 to the output file, in order.
//
// Stream shape (taken from the vendor code in this repo, not guessed):
//  - line = active, front porch, sync, back porch; frame = active lines, front
//    porch, sync, back porch (Xilinx VTC generator order);
//  - hsync and vsync active high (VideoOutput.h timing table, POS);
//  - vsync starts and ends at the hsync start position (xvtc.c, V0SyncHoriStart);
//  - during blanking i_vid_data holds the last active pixel (v_axi4s_vid_out in
//    VTG master mode only loads data while active video is high).
// Registers and line buffers start at 0, as on the FPGA after configuration.
//
// Plusargs: +in=<file> +out=<file> +mode=<0..15> +gray=<0|1> +frames=<n>
//           +hact +hfp +hsync +hbp +vact +vfp +vsync +vbp  (1080p60 by default)
// Compile with -DPREWITT for the Prewitt variant (its registers are named differently).

module tb_video_processing;

integer HACT = 1920, HFP = 88, HSW = 44, HBP = 148;
integer VACT = 1080, VFP = 4, VSW = 5, VBP = 36;
integer FRAMES = 1, MODE = 0, GRAY = 0;
reg [8*512-1:0] infile, outfile;

reg         clk = 0;
reg  [23:0] vid_data = 0;
reg         hsync = 0, vsync = 0, vde = 0;
reg  [3:0]  sw = 0;
wire [23:0] o_data;
wire        o_hs, o_vs, o_de;
wire [3:0]  led;

reg [23:0] frame [0:1920*1080-1];

video_processing dut (
    .clk(clk), .n_rst(1'b1),
    .i_vid_data(vid_data), .i_vid_hsync(hsync), .i_vid_vsync(vsync), .i_vid_VDE(vde),
    .o_vid_data(o_data), .o_vid_hsync(o_hs), .o_vid_vsync(o_vs), .o_vid_VDE(o_de),
    .btn(4'b0000), .sw(sw), .led(led)
);

// 148.5 MHz; the period only matters for waveform viewing (zero-delay RTL).
// First rising edge at 3.367 ns, after the power-up initialisation at 1 ns.
always #3.367 clk = ~clk;

integer i, f, v, h, fo, htot, vtot, pos, vs_start, vs_end, n_out;

initial begin
    if (!$value$plusargs("in=%s", infile))  begin $display("need +in=<file>");  $finish; end
    if (!$value$plusargs("out=%s", outfile)) begin $display("need +out=<file>"); $finish; end
    if ($value$plusargs("mode=%d", MODE)) ;
    if ($value$plusargs("gray=%d", GRAY)) ;
    if ($value$plusargs("frames=%d", FRAMES)) ;
    if ($value$plusargs("hact=%d", HACT)) ;
    if ($value$plusargs("hfp=%d", HFP)) ;
    if ($value$plusargs("hsync=%d", HSW)) ;
    if ($value$plusargs("hbp=%d", HBP)) ;
    if ($value$plusargs("vact=%d", VACT)) ;
    if ($value$plusargs("vfp=%d", VFP)) ;
    if ($value$plusargs("vsync=%d", VSW)) ;
    if ($value$plusargs("vbp=%d", VBP)) ;
    $readmemh(infile, frame, 0, HACT*VACT-1);

    // Power-up state: FPGA registers and LUT RAM configure to 0. The mode
    // register is set directly instead of pressing btn[0] MODE times.
    #1;
    for (i = 0; i < 1800; i = i + 1) begin
        dut.lineBuf0[i] = 0; dut.lineBuf1[i] = 0; dut.lineBuf2[i] = 0;
    end
    for (i = 0; i < 3; i = i + 1) dut.outMatrix[i] = 0;
    dut.XPtr = 0; dut.wtPtr = 0; dut.gray = 0; dut.out = 0;
`ifdef PREWITT
    dut.PrewittX = 0; dut.PrewittY = 0; dut.PrewittProd = 0;
`else
    dut.sobelX = 0; dut.sobelY = 0; dut.sobelProd = 0;
`endif
    // sqrt.v's own "initial xn = 1" races its always @(*) at time 0 and can
    // leave xn at X for the whole run (it does in Icarus); re-apply it here.
    dut.sqrt_inst.xn = 1;
    dut.cnt = MODE;
    sw[3] = GRAY;

    htot = HACT + HFP + HSW + HBP;
    vtot = VACT + VFP + VSW + VBP;
    vs_start = (VACT + VFP) * htot + HACT + HFP;
    vs_end = vs_start + VSW * htot;
    fo = $fopen(outfile, "w");
    n_out = 0;
    for (f = 0; f < FRAMES; f = f + 1)
        for (v = 0; v < vtot; v = v + 1)
            for (h = 0; h < htot; h = h + 1) begin
                // set while clk is low; sampled by the next rising edge
                pos = v * htot + h;
                vde = (v < VACT) && (h < HACT);
                hsync = (h >= HACT + HFP) && (h < HACT + HFP + HSW);
                vsync = (pos >= vs_start) && (pos < vs_end);
                if (vde) vid_data = frame[v * HACT + h];
                @(posedge clk);
                @(negedge clk);
                if (o_de) begin $fwrite(fo, "%06x\n", o_data); n_out = n_out + 1; end
            end
    $fclose(fo);
    $display("tb_video_processing: wrote %0d output pixels to %0s", n_out, outfile);
    $finish;
end

endmodule
