// Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2018.3 (win64) Build 2405991 Thu Dec  6 23:38:27 MST 2018
// Date        : Wed Jan 10 10:39:30 2024
// Host        : DESKTOP-U0PQ049 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               d:/2024/01/Upgrade_online/flash_100t_test/flash_100t_test.srcs/sources_1/ip/ila_3/ila_3_stub.v
// Design      : ila_3
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100tcsg324-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "ila,Vivado 2018.3" *)
module ila_3(clk, probe0, probe1, probe2, probe3, probe4, probe5, 
  probe6, probe7, probe8, probe9)
/* synthesis syn_black_box black_box_pad_pin="clk,probe0[0:0],probe1[0:0],probe2[7:0],probe3[7:0],probe4[0:0],probe5[0:0],probe6[0:0],probe7[31:0],probe8[7:0],probe9[11:0]" */;
  input clk;
  input [0:0]probe0;
  input [0:0]probe1;
  input [7:0]probe2;
  input [7:0]probe3;
  input [0:0]probe4;
  input [0:0]probe5;
  input [0:0]probe6;
  input [31:0]probe7;
  input [7:0]probe8;
  input [11:0]probe9;
endmodule
