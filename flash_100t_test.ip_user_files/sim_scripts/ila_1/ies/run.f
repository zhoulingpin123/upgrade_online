-makelib ies_lib/xil_defaultlib -sv \
  "D:/Xilinx/Vivado/2018.3/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
  "D:/Xilinx/Vivado/2018.3/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \
-endlib
-makelib ies_lib/xpm \
  "D:/Xilinx/Vivado/2018.3/data/ip/xpm/xpm_VCOMP.vhd" \
-endlib
-makelib ies_lib/xil_defaultlib \
  "../../../../flash_100t_test.srcs/sources_1/ip/ila_1/sim/ila_1.v" \
-endlib
-makelib ies_lib/xil_defaultlib \
  glbl.v
-endlib

