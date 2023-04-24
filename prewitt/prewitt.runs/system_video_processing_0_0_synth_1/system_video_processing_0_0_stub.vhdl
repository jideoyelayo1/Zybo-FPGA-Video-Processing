-- Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2019.1 (win64) Build 2552052 Fri May 24 14:49:42 MDT 2019
-- Date        : Mon Apr 24 20:55:51 2023
-- Host        : TrimlessPC running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub -rename_top decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix -prefix
--               decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_ system_video_processing_0_0_stub.vhdl
-- Design      : system_video_processing_0_0
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7z020clg400-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix is
  Port ( 
    clk : in STD_LOGIC;
    n_rst : in STD_LOGIC;
    i_vid_data : in STD_LOGIC_VECTOR ( 23 downto 0 );
    i_vid_hsync : in STD_LOGIC;
    i_vid_vsync : in STD_LOGIC;
    i_vid_VDE : in STD_LOGIC;
    o_vid_data : out STD_LOGIC_VECTOR ( 23 downto 0 );
    o_vid_hsync : out STD_LOGIC;
    o_vid_vsync : out STD_LOGIC;
    o_vid_VDE : out STD_LOGIC;
    btn : in STD_LOGIC_VECTOR ( 3 downto 0 );
    sw : in STD_LOGIC_VECTOR ( 3 downto 0 );
    led : out STD_LOGIC_VECTOR ( 3 downto 0 )
  );

end decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix;

architecture stub of decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clk,n_rst,i_vid_data[23:0],i_vid_hsync,i_vid_vsync,i_vid_VDE,o_vid_data[23:0],o_vid_hsync,o_vid_vsync,o_vid_VDE,btn[3:0],sw[3:0],led[3:0]";
attribute x_core_info : string;
attribute x_core_info of stub : architecture is "video_processing,Vivado 2019.1";
begin
end;
