`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/02 17:51:39
// Design Name: 
// Module Name: flash_rd
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


module flash_rd(
	input	wire 		sclk,
	input	wire 		rst,
	input	wire 		rd_flag,
	input	wire [23:0]	rd_addr,
	input	wire [12:0]	rd_len,
	output	wire 		rd_ready,
	input	wire		rd_en,
	output	wire [7:0]	rd_data,
	output	wire 		sck,
	output	wire 		cs_n,
	input	wire 		sdo,
	output	wire 		sdi
	);

parameter	DIV_END_NUM = 3;
parameter	READ_P = 8'h03;

reg	[15:0]	bit_cnt_end;
reg 		cs_n_r,sdi_r,sck_r;
reg [7:0]	div_cnt;
reg [15:0]	bit_cnt;
reg [31:0]	rd_inst_shift;
reg 		shift_flag;
reg 		wr_en;
reg [7:0]	sdo_data_shift;
reg 		flash_read_end;
wire 		full;
wire        empty;


assign sdi = sdi_r;
assign sck = sck_r;
assign cs_n = cs_n_r;
//总的bit计数，共计2080bit = 32 + 256*8
always @(posedge sclk or posedge rst) begin
	if (rst == 1'b1) begin
		bit_cnt_end <='d0;
	end
	else if (rd_flag == 1'b1) begin
		bit_cnt_end <= 32 + (rd_len<<3);
	end
end
//读标志拉高cs拉低
always @(posedge sclk or posedge rst) begin
	if (rst == 1'b1) begin
		cs_n_r <= 1'b1;
	end
	else if (div_cnt == DIV_END_NUM && bit_cnt == bit_cnt_end) begin
		cs_n_r <= 1'b1;
	end
	else if (rd_flag == 1'b1) begin
		cs_n_r <= 1'b0;
	end
end
//cs为低 0-3计数
always @(posedge sclk or posedge rst) begin
	if (rst == 1'b1) begin
		div_cnt <='d0;
	end
	else if(div_cnt == DIV_END_NUM) begin
		div_cnt <= 'd0;
	end
	else if (cs_n_r == 1'b0) begin
		div_cnt <= div_cnt + 1'b1;
	end
end
//bit计数 0-2080
always @(posedge sclk or posedge rst) begin
	if (rst == 1'b1) begin
		bit_cnt <='d0;
	end
	else if (cs_n_r == 1'b0 && div_cnt == DIV_END_NUM && bit_cnt == bit_cnt_end) begin
		bit_cnt <= 'd0;
	end
	else if (cs_n_r == 1'b0 && div_cnt == DIV_END_NUM) begin
		bit_cnt <= bit_cnt + 1'b1;
	end
end
//控制sck 01 为低电平 23 为高 
always @(posedge sclk or posedge rst) begin
	if (rst == 1'b1) begin
		sck_r <= 1'b0;
	end
	else if (cs_n_r == 1'b0 && div_cnt == (DIV_END_NUM>>1) && bit_cnt != bit_cnt_end) begin
		sck_r <= 1'b1;
	end
	else if (cs_n_r == 1'b0 && div_cnt == DIV_END_NUM && bit_cnt != bit_cnt_end) begin
		sck_r <= 1'b0;
	end
end
//移位寄存读指令和读地址
always @(posedge sclk or posedge rst) begin
	if (rst == 1'b1) begin
		rd_inst_shift <='d0;
	end
	else if (rd_flag == 1'b1 && cs_n_r == 1'b1) begin
		rd_inst_shift <= {READ_P,rd_addr};
	end
	else if (cs_n_r == 1'b0 && bit_cnt < 31 && div_cnt== DIV_END_NUM) begin
		rd_inst_shift <= {rd_inst_shift[30:0],1'b0};
	end
end

always @*
	sdi_r <= rd_inst_shift[31];
//移位寄存标志。在数据中间采样
always @(posedge sclk or posedge rst) begin
	if (rst == 1'b1) begin
		shift_flag <= 1'b0;
	end
	else if (bit_cnt >31 && bit_cnt != bit_cnt_end && div_cnt == (DIV_END_NUM>>1)) begin
		shift_flag <= 1'b1;
	end
	else begin
		shift_flag <= 1'b0;
	end
end
//每计数8bit写入一次fifo
always @(posedge sclk or posedge rst) begin
	if (rst == 1'b1) begin
		wr_en <= 1'b0;
	end
	else if (bit_cnt > 31 && bit_cnt != bit_cnt_end && div_cnt == ((DIV_END_NUM >>1)+1) && bit_cnt[2:0] == 3'b111) begin
		wr_en <= 1'b1;
	end
	else begin
		wr_en <= 1'b0;
	end

end

//移位寄存
always @(posedge sclk or posedge rst) begin
	if (rst == 1'b1) begin
		sdo_data_shift <= 'd0;
	end
	else if (shift_flag == 1'b1) begin
		sdo_data_shift <= {sdo_data_shift[6:0],sdo};
	end
end

//flash读结束标志
always @(posedge sclk or posedge rst) begin
	if (rst == 1'b1) begin
		flash_read_end <= 1'b0;
	end
	else if(flash_read_end == 1'b1 && empty == 1'b1)begin
		flash_read_end <= 1'b0;
	end
	else if (cs_n_r == 1'b0 && bit_cnt == bit_cnt_end && div_cnt == DIV_END_NUM) begin
		flash_read_end <= 1'b1;
	end
end
//读准备 flash读结束且fifo非空
assign  rd_ready = flash_read_end & (~empty);



fifo_rd fifo_rd (
  .clk(sclk),      // input wire clk
  .rst(rst),      // input wire rst
  .din(sdo_data_shift),      // input wire [7 : 0] din
  .wr_en(wr_en),  // input wire wr_en
  .rd_en(rd_en),  // input wire rd_en
  .dout(rd_data),    // output wire [7 : 0] dout
  .full(full),    // output wire full
  .empty(empty)  // output wire empty
);

//ila_2 ila_2 (
//	.clk(sclk), // input wire clk


//	.probe0(flash_read_end), // input wire [0:0]  probe0  
//	.probe1(rd_ready), // input wire [0:0]  probe1 
//	.probe2(empty), // input wire [0:0]  probe2 
//	.probe3(cs_n_r), // input wire [0:0]  probe3 
//	.probe4(bit_cnt), // input wire [15:0]  probe4 
//	.probe5(div_cnt), // input wire [7:0]  probe5 
//	.probe6(sck_r), // input wire [0:0]  probe6
//	.probe7(rd_flag), // input wire [0:0]  probe6
//	.probe8(bit_cnt_end), // input wire [15:0]  probe6
//	.probe9(rd_len), // input wire [15:0]  probe6
//	.probe10(full), // input wire [0:0]  probe10 
//	.probe11(wr_en), // input wire [0:0]  probe11 
//	.probe12(rd_en), // input wire [0:0]  probe12 
//	.probe13(sdo_data_shift), // input wire [7:0]  probe13 
//	.probe14(rd_data), // input wire [7:0]  probe14
//	.probe15(sdi_r), // input wire [0:0]  probe14
//	.probe16(sdo) // input wire [0:0]  probe14
//);
endmodule 
