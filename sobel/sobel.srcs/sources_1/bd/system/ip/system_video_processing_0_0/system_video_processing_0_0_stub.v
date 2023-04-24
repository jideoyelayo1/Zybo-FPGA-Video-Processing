// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.1 (win64) Build 2552052 Fri May 24 14:49:42 MDT 2019
// Date        : Mon Apr 24 20:50:12 2023
// Host        : TrimlessPC running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               C:/Users/JideO/Documents/Programing_Projects/Zybo-FPGA-Video-Processing/sobel/sobel.srcs/sources_1/bd/system/ip/system_video_processing_0_0/system_video_processing_0_0_stub.v
// Design      : system_video_processing_0_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7z020clg400-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "video_processing,Vivado 2019.1" *)
module system_video_processing_0_0(clk, n_rst, i_vid_data, i_vid_hsync, i_vid_vsync, 
  i_vid_VDE, o_vid_data, o_vid_hsync, o_vid_vsync, o_vid_VDE, btn, sw, led)
/* synthesis syn_black_box black_box_pad_pin="clk,n_rst,i_vid_data[23:0],i_vid_hsync,i_vid_vsync,i_vid_VDE,o_vid_data[23:0],o_vid_hsync,o_vid_vsync,o_vid_VDE,btn[3:0],sw[3:0],led[3:0]" */;
  input clk;
  input n_rst;
  input [23:0]i_vid_data;
  input i_vid_hsync;
  input i_vid_vsync;
  input i_vid_VDE;
  output [23:0]o_vid_data;
  output o_vid_hsync;
  output o_vid_vsync;
  output o_vid_VDE;
  input [3:0]btn;
  input [3:0]sw;
  output [3:0]led;
endmodule
