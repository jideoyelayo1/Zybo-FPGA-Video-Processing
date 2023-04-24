-- (c) Copyright 1995-2023 Xilinx, Inc. All rights reserved.
-- 
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
-- 
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
-- 
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
-- 
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
-- 
-- DO NOT MODIFY THIS FILE.

-- IP VLNV: xilinx.com:module_ref:video_processing:1.0
-- IP Revision: 1

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY system_video_processing_0_0 IS
  PORT (
    clk : IN STD_LOGIC;
    n_rst : IN STD_LOGIC;
    i_vid_data : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
    i_vid_hsync : IN STD_LOGIC;
    i_vid_vsync : IN STD_LOGIC;
    i_vid_VDE : IN STD_LOGIC;
    o_vid_data : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
    o_vid_hsync : OUT STD_LOGIC;
    o_vid_vsync : OUT STD_LOGIC;
    o_vid_VDE : OUT STD_LOGIC;
    btn : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    sw : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    led : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
  );
END system_video_processing_0_0;

ARCHITECTURE system_video_processing_0_0_arch OF system_video_processing_0_0 IS
  ATTRIBUTE DowngradeIPIdentifiedWarnings : STRING;
  ATTRIBUTE DowngradeIPIdentifiedWarnings OF system_video_processing_0_0_arch: ARCHITECTURE IS "yes";
  COMPONENT video_processing IS
    GENERIC (
      DATA_WIDTH : INTEGER
    );
    PORT (
      clk : IN STD_LOGIC;
      n_rst : IN STD_LOGIC;
      i_vid_data : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
      i_vid_hsync : IN STD_LOGIC;
      i_vid_vsync : IN STD_LOGIC;
      i_vid_VDE : IN STD_LOGIC;
      o_vid_data : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
      o_vid_hsync : OUT STD_LOGIC;
      o_vid_vsync : OUT STD_LOGIC;
      o_vid_VDE : OUT STD_LOGIC;
      btn : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      sw : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      led : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
  END COMPONENT video_processing;
  ATTRIBUTE X_CORE_INFO : STRING;
  ATTRIBUTE X_CORE_INFO OF system_video_processing_0_0_arch: ARCHITECTURE IS "video_processing,Vivado 2019.1";
  ATTRIBUTE CHECK_LICENSE_TYPE : STRING;
  ATTRIBUTE CHECK_LICENSE_TYPE OF system_video_processing_0_0_arch : ARCHITECTURE IS "system_video_processing_0_0,video_processing,{}";
  ATTRIBUTE CORE_GENERATION_INFO : STRING;
  ATTRIBUTE CORE_GENERATION_INFO OF system_video_processing_0_0_arch: ARCHITECTURE IS "system_video_processing_0_0,video_processing,{x_ipProduct=Vivado 2019.1,x_ipVendor=xilinx.com,x_ipLibrary=module_ref,x_ipName=video_processing,x_ipVersion=1.0,x_ipCoreRevision=1,x_ipLanguage=VHDL,x_ipSimLanguage=MIXED,DATA_WIDTH=24}";
  ATTRIBUTE IP_DEFINITION_SOURCE : STRING;
  ATTRIBUTE IP_DEFINITION_SOURCE OF system_video_processing_0_0_arch: ARCHITECTURE IS "module_ref";
  ATTRIBUTE X_INTERFACE_INFO : STRING;
  ATTRIBUTE X_INTERFACE_PARAMETER : STRING;
  ATTRIBUTE X_INTERFACE_PARAMETER OF n_rst: SIGNAL IS "XIL_INTERFACENAME n_rst, POLARITY ACTIVE_LOW, INSERT_VIP 0";
  ATTRIBUTE X_INTERFACE_INFO OF n_rst: SIGNAL IS "xilinx.com:signal:reset:1.0 n_rst RST";
  ATTRIBUTE X_INTERFACE_PARAMETER OF clk: SIGNAL IS "XIL_INTERFACENAME clk, FREQ_HZ 100000000, PHASE 0.000, INSERT_VIP 0";
  ATTRIBUTE X_INTERFACE_INFO OF clk: SIGNAL IS "xilinx.com:signal:clock:1.0 clk CLK";
BEGIN
  U0 : video_processing
    GENERIC MAP (
      DATA_WIDTH => 24
    )
    PORT MAP (
      clk => clk,
      n_rst => n_rst,
      i_vid_data => i_vid_data,
      i_vid_hsync => i_vid_hsync,
      i_vid_vsync => i_vid_vsync,
      i_vid_VDE => i_vid_VDE,
      o_vid_data => o_vid_data,
      o_vid_hsync => o_vid_hsync,
      o_vid_vsync => o_vid_vsync,
      o_vid_VDE => o_vid_VDE,
      btn => btn,
      sw => sw,
      led => led
    );
END system_video_processing_0_0_arch;
