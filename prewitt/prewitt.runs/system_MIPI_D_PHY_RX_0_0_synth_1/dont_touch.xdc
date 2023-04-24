# This file is automatically generated.
# It contains project source information necessary for synthesis and implementation.

# IP: c:/Zybo-Z7-20-pcam-5c/proj/Zybo-Z7-20-pcam-5c.srcs/sources_1/bd/system/ip/system_MIPI_D_PHY_RX_0_0/system_MIPI_D_PHY_RX_0_0.xci
# IP: The module: 'system_MIPI_D_PHY_RX_0_0' is the root of the design. Do not add the DONT_TOUCH constraint.

# IP: c:/Zybo-Z7-20-pcam-5c/proj/Zybo-Z7-20-pcam-5c.srcs/sources_1/bd/system/ip/system_MIPI_D_PHY_RX_0_0/hdl/ila_sfen_rxclk/ila_sfen_rxclk.xci
set_property DONT_TOUCH TRUE [get_cells -hier -filter {REF_NAME==ila_sfen_rxclk || ORIG_REF_NAME==ila_sfen_rxclk} -quiet] -quiet

# IP: c:/Zybo-Z7-20-pcam-5c/proj/Zybo-Z7-20-pcam-5c.srcs/sources_1/bd/system/ip/system_MIPI_D_PHY_RX_0_0/hdl/ila_sfen_refclk/ila_sfen_refclk.xci
set_property DONT_TOUCH TRUE [get_cells -hier -filter {REF_NAME==ila_sfen_refclk || ORIG_REF_NAME==ila_sfen_refclk} -quiet] -quiet

# IP: c:/Zybo-Z7-20-pcam-5c/proj/Zybo-Z7-20-pcam-5c.srcs/sources_1/bd/system/ip/system_MIPI_D_PHY_RX_0_0/hdl/ila_scnn_refclk/ila_scnn_refclk.xci
set_property DONT_TOUCH TRUE [get_cells -hier -filter {REF_NAME==ila_scnn_refclk || ORIG_REF_NAME==ila_scnn_refclk} -quiet] -quiet

# XDC: c:/Zybo-Z7-20-pcam-5c/proj/Zybo-Z7-20-pcam-5c.srcs/sources_1/bd/system/ip/system_MIPI_D_PHY_RX_0_0/hdl/MIPI_DPHY_Receiver.xdc
# XDC: The top module name and the constraint reference have the same name: 'system_MIPI_D_PHY_RX_0_0'. Do not add the DONT_TOUCH constraint.
set_property DONT_TOUCH TRUE [get_cells U0 -quiet] -quiet

# XDC: c:/Zybo-Z7-20-pcam-5c/proj/Zybo-Z7-20-pcam-5c.srcs/sources_1/bd/system/ip/system_MIPI_D_PHY_RX_0_0/hdl/MIPI_DPHY_Receiver_clocks.xdc
# XDC: The top module name and the constraint reference have the same name: 'system_MIPI_D_PHY_RX_0_0'. Do not add the DONT_TOUCH constraint.
#dup# set_property DONT_TOUCH TRUE [get_cells U0 -quiet] -quiet

# XDC: c:/Zybo-Z7-20-pcam-5c/proj/Zybo-Z7-20-pcam-5c.srcs/sources_1/bd/system/ip/system_MIPI_D_PHY_RX_0_0/hdl/MIPI_DPHY_Receiver_ooc.xdc
# XDC: The top module name and the constraint reference have the same name: 'system_MIPI_D_PHY_RX_0_0'. Do not add the DONT_TOUCH constraint.
#dup# set_property DONT_TOUCH TRUE [get_cells U0 -quiet] -quiet

# XDC: c:/Zybo-Z7-20-pcam-5c/proj/Zybo-Z7-20-pcam-5c.srcs/sources_1/bd/system/ip/system_MIPI_D_PHY_RX_0_0/hdl/ila_sfen_rxclk/ila_v6_2/constraints/ila.xdc
set_property DONT_TOUCH TRUE [get_cells [split [join [get_cells -hier -filter {REF_NAME==ila_sfen_rxclk || ORIG_REF_NAME==ila_sfen_rxclk} -quiet] {/U0 } ]/U0 ] -quiet] -quiet

# XDC: c:/Zybo-Z7-20-pcam-5c/proj/Zybo-Z7-20-pcam-5c.srcs/sources_1/bd/system/ip/system_MIPI_D_PHY_RX_0_0/hdl/ila_sfen_rxclk/ila_sfen_rxclk_ooc.xdc

# XDC: c:/Zybo-Z7-20-pcam-5c/proj/Zybo-Z7-20-pcam-5c.srcs/sources_1/bd/system/ip/system_MIPI_D_PHY_RX_0_0/hdl/ila_sfen_refclk/ila_v6_2/constraints/ila.xdc
set_property DONT_TOUCH TRUE [get_cells [split [join [get_cells -hier -filter {REF_NAME==ila_sfen_refclk || ORIG_REF_NAME==ila_sfen_refclk} -quiet] {/U0 } ]/U0 ] -quiet] -quiet

# XDC: c:/Zybo-Z7-20-pcam-5c/proj/Zybo-Z7-20-pcam-5c.srcs/sources_1/bd/system/ip/system_MIPI_D_PHY_RX_0_0/hdl/ila_sfen_refclk/ila_sfen_refclk_ooc.xdc

# XDC: c:/Zybo-Z7-20-pcam-5c/proj/Zybo-Z7-20-pcam-5c.srcs/sources_1/bd/system/ip/system_MIPI_D_PHY_RX_0_0/hdl/ila_scnn_refclk/ila_v6_2/constraints/ila.xdc
set_property DONT_TOUCH TRUE [get_cells [split [join [get_cells -hier -filter {REF_NAME==ila_scnn_refclk || ORIG_REF_NAME==ila_scnn_refclk} -quiet] {/U0 } ]/U0 ] -quiet] -quiet

# XDC: c:/Zybo-Z7-20-pcam-5c/proj/Zybo-Z7-20-pcam-5c.srcs/sources_1/bd/system/ip/system_MIPI_D_PHY_RX_0_0/hdl/ila_scnn_refclk/ila_scnn_refclk_ooc.xdc

# IP: c:/Zybo-Z7-20-pcam-5c/proj/Zybo-Z7-20-pcam-5c.srcs/sources_1/bd/system/ip/system_MIPI_D_PHY_RX_0_0/system_MIPI_D_PHY_RX_0_0.xci
# IP: The module: 'system_MIPI_D_PHY_RX_0_0' is the root of the design. Do not add the DONT_TOUCH constraint.

# IP: c:/Zybo-Z7-20-pcam-5c/proj/Zybo-Z7-20-pcam-5c.srcs/sources_1/bd/system/ip/system_MIPI_D_PHY_RX_0_0/hdl/ila_sfen_rxclk/ila_sfen_rxclk.xci
#dup# set_property DONT_TOUCH TRUE [get_cells -hier -filter {REF_NAME==ila_sfen_rxclk || ORIG_REF_NAME==ila_sfen_rxclk} -quiet] -quiet

# IP: c:/Zybo-Z7-20-pcam-5c/proj/Zybo-Z7-20-pcam-5c.srcs/sources_1/bd/system/ip/system_MIPI_D_PHY_RX_0_0/hdl/ila_sfen_refclk/ila_sfen_refclk.xci
#dup# set_property DONT_TOUCH TRUE [get_cells -hier -filter {REF_NAME==ila_sfen_refclk || ORIG_REF_NAME==ila_sfen_refclk} -quiet] -quiet

# IP: c:/Zybo-Z7-20-pcam-5c/proj/Zybo-Z7-20-pcam-5c.srcs/sources_1/bd/system/ip/system_MIPI_D_PHY_RX_0_0/hdl/ila_scnn_refclk/ila_scnn_refclk.xci
#dup# set_property DONT_TOUCH TRUE [get_cells -hier -filter {REF_NAME==ila_scnn_refclk || ORIG_REF_NAME==ila_scnn_refclk} -quiet] -quiet

# XDC: c:/Zybo-Z7-20-pcam-5c/proj/Zybo-Z7-20-pcam-5c.srcs/sources_1/bd/system/ip/system_MIPI_D_PHY_RX_0_0/hdl/MIPI_DPHY_Receiver.xdc
# XDC: The top module name and the constraint reference have the same name: 'system_MIPI_D_PHY_RX_0_0'. Do not add the DONT_TOUCH constraint.
#dup# set_property DONT_TOUCH TRUE [get_cells U0 -quiet] -quiet

# XDC: c:/Zybo-Z7-20-pcam-5c/proj/Zybo-Z7-20-pcam-5c.srcs/sources_1/bd/system/ip/system_MIPI_D_PHY_RX_0_0/hdl/MIPI_DPHY_Receiver_clocks.xdc
# XDC: The top module name and the constraint reference have the same name: 'system_MIPI_D_PHY_RX_0_0'. Do not add the DONT_TOUCH constraint.
#dup# set_property DONT_TOUCH TRUE [get_cells U0 -quiet] -quiet

# XDC: c:/Zybo-Z7-20-pcam-5c/proj/Zybo-Z7-20-pcam-5c.srcs/sources_1/bd/system/ip/system_MIPI_D_PHY_RX_0_0/hdl/MIPI_DPHY_Receiver_ooc.xdc
# XDC: The top module name and the constraint reference have the same name: 'system_MIPI_D_PHY_RX_0_0'. Do not add the DONT_TOUCH constraint.
#dup# set_property DONT_TOUCH TRUE [get_cells U0 -quiet] -quiet

# XDC: c:/Zybo-Z7-20-pcam-5c/proj/Zybo-Z7-20-pcam-5c.srcs/sources_1/bd/system/ip/system_MIPI_D_PHY_RX_0_0/hdl/ila_sfen_rxclk/ila_v6_2/constraints/ila.xdc
#dup# set_property DONT_TOUCH TRUE [get_cells [split [join [get_cells -hier -filter {REF_NAME==ila_sfen_rxclk || ORIG_REF_NAME==ila_sfen_rxclk} -quiet] {/U0 } ]/U0 ] -quiet] -quiet

# XDC: c:/Zybo-Z7-20-pcam-5c/proj/Zybo-Z7-20-pcam-5c.srcs/sources_1/bd/system/ip/system_MIPI_D_PHY_RX_0_0/hdl/ila_sfen_rxclk/ila_sfen_rxclk_ooc.xdc

# XDC: c:/Zybo-Z7-20-pcam-5c/proj/Zybo-Z7-20-pcam-5c.srcs/sources_1/bd/system/ip/system_MIPI_D_PHY_RX_0_0/hdl/ila_sfen_refclk/ila_v6_2/constraints/ila.xdc
#dup# set_property DONT_TOUCH TRUE [get_cells [split [join [get_cells -hier -filter {REF_NAME==ila_sfen_refclk || ORIG_REF_NAME==ila_sfen_refclk} -quiet] {/U0 } ]/U0 ] -quiet] -quiet

# XDC: c:/Zybo-Z7-20-pcam-5c/proj/Zybo-Z7-20-pcam-5c.srcs/sources_1/bd/system/ip/system_MIPI_D_PHY_RX_0_0/hdl/ila_sfen_refclk/ila_sfen_refclk_ooc.xdc

# XDC: c:/Zybo-Z7-20-pcam-5c/proj/Zybo-Z7-20-pcam-5c.srcs/sources_1/bd/system/ip/system_MIPI_D_PHY_RX_0_0/hdl/ila_scnn_refclk/ila_v6_2/constraints/ila.xdc
#dup# set_property DONT_TOUCH TRUE [get_cells [split [join [get_cells -hier -filter {REF_NAME==ila_scnn_refclk || ORIG_REF_NAME==ila_scnn_refclk} -quiet] {/U0 } ]/U0 ] -quiet] -quiet

# XDC: c:/Zybo-Z7-20-pcam-5c/proj/Zybo-Z7-20-pcam-5c.srcs/sources_1/bd/system/ip/system_MIPI_D_PHY_RX_0_0/hdl/ila_scnn_refclk/ila_scnn_refclk_ooc.xdc