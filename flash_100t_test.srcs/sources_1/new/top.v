`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/02 15:45:40
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top(
input                             sys_clk   ,
//input                             rst       ,
output	 		                  cs_n      ,
input	 		                  rx        ,
output	 		                  tx        ,
//output	 		                  sck        ,
input	 		                  sdo       ,
output	 		                  sdi
    );
wire                            rd_ready;     
reg                             rst;     
wire        [7:0]               rd_data;     
wire        [7:0]               rx_data;     
wire        [7:0]               wr_data;     
wire        [7:0]               tx_data;     
wire        [23:0]              se_addr;     
wire        [23:0]              pp_addr;     
wire        [23:0]              rd_addr;     
wire            	 		    sck     ;    
wire            	 		    rx_flag     ;    
wire            	 		    tx_flag     ;    
wire            	 		    rst_n     ;    
wire            	 		    se_flag     ;    
wire            	 		    se_sck     ;    
wire            	 		    se_cs_n     ;    
wire            	 		    se_sdi     ;    
wire            	 		    pp_flag     ;    
wire            	 		    wr_en     ;    
wire            	 		    pp_sck     ;    
wire            	 		    pp_cs_n     ;    
wire            	 		    pp_sdi     ;    
wire            	 		    rd_flag     ;    
wire        [12:0]    	 		rd_len     ;    
wire            	 		    rd_en     ;    
wire            	 		    rd_sck     ;    
wire            	 		    rd_cs_n     ;    
wire            	 		    rd_sdo     ;    
wire            	 		    rd_sdi     ;    
wire                            icap_flag  ;
assign      rst_n  = ~rst;
reg [26:0] cnt = 27'b0;
always @(posedge sys_clk)
begin
    if(cnt < 27'd9450)      
        cnt <= cnt + 1'd1;
    else                           
        cnt <= cnt;
end
always @(posedge sys_clk)
begin
    if((cnt >= 27'd9440) && (cnt <= 27'd9445))     
        rst <= 1'b1;
    else rst <= 0;
end

//reg         rd_flag;
//always @(posedge sys_clk)
//begin
//    if(cnt == 27'd9450)     
//        rd_flag <= 1;
//    else rd_flag <= 0;
//end

//reg                 rd_en;
//reg  [15:0]         rd_cnt;
//always @(posedge sys_clk)
//begin
//    if(rd_ready)     
//        rd_en <= 1;
//    else if(rd_cnt == 255)
//        rd_en <= 0;
//    else rd_en <= rd_en;
//end

//always @(posedge sys_clk)
//begin
//    if(rst)     
//        rd_cnt <= 0;
//    else if(rd_cnt == 255)
//        rd_cnt <= 0;
//    else if(rd_en)
//        rd_cnt <= rd_cnt + 1'b1;
//end


   STARTUPE2 #(
      .PROG_USR("FALSE"),  // Activate program event security feature. Requires encrypted bitstreams.
      .SIM_CCLK_FREQ(0.0)  // Set the Configuration Clock Frequency(ns) for simulation.
   )
   STARTUPE2_inst (
      .CFGCLK(),       // 1-bit output: Configuration main clock output
      .CFGMCLK(),     // 1-bit output: Configuration internal oscillator clock output
      .EOS(),             // 1-bit output: Active high output signal indicating the End Of Startup.
      .PREQ(),           // 1-bit output: PROGRAM request to fabric output
      .CLK(0),             // 1-bit input: User start-up clock input
      .GSR(0),             // 1-bit input: Global Set/Reset input (GSR cannot be used for the port name)
      .GTS(0),             // 1-bit input: Global 3-state input (GTS cannot be used for the port name)
      .KEYCLEARB(1), // 1-bit input: Clear AES Decrypter Key input from Battery-Backed RAM (BBRAM)
      .PACK(1),           // 1-bit input: PROGRAM acknowledge input
      .USRCCLKO(sck),   // 1-bit input: User CCLK input
                             // For Zynq-7000 devices, this input must be tied to GND
      .USRCCLKTS(0), // 1-bit input: User CCLK 3-state enable input
                             // For Zynq-7000 devices, this input must be tied to VCC
      .USRDONEO(1),   // 1-bit input: User DONE pin output control
      .USRDONETS(1)  // 1-bit input: User DONE 3-state enable output
   );

state_ctrl inst_state_ctrl (
			.sclk     (sys_clk),
			.rst      (rst),
			.cs_n     (cs_n),
			.sck      (sck),
			.sdi      (sdi),
			.sdo      (sdo),
			.rx_flag  (rx_flag),
			.rx_data  (rx_data),
			.tx_flag  (tx_flag),
			.tx_data  (tx_data),
			.se_flag  (se_flag),
			.se_addr  (se_addr),
			.se_sck   (se_sck),
			.se_cs_n  (se_cs_n),
			.se_sdi   (se_sdi),
			.pp_flag  (pp_flag),
			.pp_addr  (pp_addr),
			.wr_en    (wr_en),
			.wr_data  (wr_data),
			.pp_sck   (pp_sck),
			.pp_cs_n  (pp_cs_n),
			.pp_sdi   (pp_sdi),
			.rd_flag  (rd_flag),
			.rd_addr  (rd_addr),
			.rd_len   (rd_len),
			.rd_ready (rd_ready),
			.rd_en    (rd_en),
			.rd_data  (rd_data),
			.rd_sck   (rd_sck),
			.rd_cs_n  (rd_cs_n),
			.rd_sdo   (rd_sdo),
			.rd_sdi   (rd_sdi)
		);

uart_rx inst_uart_rx (
			.sclk    (sys_clk),
			.rst_n   (rst_n),
			.rx      (rx),
			.po_data (rx_data),
			.po_flag (rx_flag)
		);
uart_tx inst_uart_tx (
			.sclk    (sys_clk),
			.rst_n   (rst_n),
			.pi_flag (tx_flag),
			.pi_data (tx_data),
			.tx      (tx)
		);

		
flash_pp inst_flash_pp (
			.sclk    (sys_clk),
			.rst     (rst),
			.pp_flag (pp_flag),
			.pp_addr (pp_addr),
			.wr_en   (wr_en),
			.wr_data (wr_data),
			.sck     (pp_sck),
			.cs_n    (pp_cs_n),
			.sdi     (pp_sdi)
		);
	flash_rd inst_flash_rd (
			.sclk     (sys_clk),
			.rst      (rst),
			.rd_flag  (rd_flag),
			.rd_addr  (rd_addr),
			.rd_len   (rd_len),
			.rd_ready (rd_ready),
			.rd_en    (rd_en),
			.rd_data  (rd_data),
			.sck      (rd_sck),
			.cs_n     (rd_cs_n),
			.sdo      (rd_sdo),
			.sdi      (rd_sdi)
		);
	flash_se inst_flash_se (
			.sclk    (sys_clk),
			.rst     (rst),
			.se_flag (se_flag),
			.se_addr (se_addr),
			.sck     (se_sck),
			.cs_n    (se_cs_n),
			.sdi     (se_sdi)
		);
icap_delay inst_icap_delay (
			.sclk      (sys_clk),
			.rst       (rst),
			.icap_flag (icap_flag),
			.rx_flag   (rx_flag),
			.rx_data   (rx_data)
		);
		
icap icap(
. clk        (sys_clk      )       ,
. rst        (rst_n      )       ,  
. icap_flag  (icap_flag)
    );



//ila_0 ila_0 (
//	.clk(sys_clk), // input wire clk


//	.probe0(tx_data), // input wire [7:0]  probe0  
//	.probe1(tx_flag) // input wire [0:0]  probe1
//);
endmodule
