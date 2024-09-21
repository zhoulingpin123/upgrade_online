`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/02 16:04:04
// Design Name: 
// Module Name: flash_pp
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


module flash_pp(	
	input	wire 		sclk,
	input	wire 		rst,
	input	wire 		pp_flag,
	input	wire [23:0]	pp_addr,
	input	wire 		wr_en,
	input	wire [7:0]	wr_data,
	output	wire 		sck,
	output	wire 		cs_n,
	output	wire 		sdi
	);

parameter	IDLE 	= 4'b0001;
parameter	WE 		= 4'b0010;
parameter	DELAY	= 4'b0100;
parameter	PP 		= 4'b1000;

parameter	DIV_END_NUM = 3;
parameter 	DELAY_END = 15;
parameter	WRITE_EN =8'h06;
parameter   PAGE_P =8'h02;

reg 	[3:0]	state;
reg 	[7:0]	div_cnt;
reg 	[11:0]	bit_cnt;
reg 	[7:0]	delay_cnt;
reg 			cs_n_r;
reg 			sck_r;
reg 			sdi_r;
reg 	[7:0]	we_inst_shift;
reg 	[31:0]	pp_inst_shift;
reg 			read_fifo_en;
reg 			pp_shift_flag;
wire 	[7:0]	read_fifo_data;
wire            full;
wire            empty;

assign sck = sck_r;
assign cs_n = cs_n_r;
assign sdi = sdi_r;
//先发写使能指令，再发页写指令
always @(posedge sclk or posedge rst) begin
	if (rst == 1'b1) begin
		state <= IDLE;
	end
	else case (state)
		IDLE : if(pp_flag == 1'b1 )
				state <= WE;
		WE 	 : if(div_cnt == DIV_END_NUM && bit_cnt == 'd8)
				state <= DELAY;
		DELAY: if (delay_cnt == DELAY_END)
				state <= PP;
		PP   : if(div_cnt == DIV_END_NUM && bit_cnt == 'd2080)
				state <= IDLE;
		default : state <= IDLE;
		endcase
end
//控制div_cnt在we和pp 0 - 3 计数
always @(posedge sclk or posedge rst) begin
	if (rst == 1'b1) begin
		div_cnt <= 'd0;
	end
	else if(div_cnt == DIV_END_NUM) begin
		div_cnt <='d0;
	end
	else if (state == WE || state == PP) begin
		div_cnt <= div_cnt + 1'b1;
	end
end
//在we和pp状态计数bit
always @(posedge sclk or posedge rst) begin
	if (rst == 1'b1) begin
		bit_cnt <= 'd0;
	end
	else if (state == WE && bit_cnt == 'd8 && div_cnt == DIV_END_NUM) begin
		bit_cnt <='d0;
	end
	else if (state == WE && div_cnt == DIV_END_NUM) begin
		bit_cnt <= bit_cnt + 1'b1;
	end
	else if (state == PP && bit_cnt == 'd2080 && div_cnt == DIV_END_NUM) begin
		bit_cnt <='d0;
	end
	else if (state == PP && div_cnt == DIV_END_NUM) begin
		bit_cnt <= bit_cnt + 1'b1;
	end
end

always @(posedge sclk or posedge rst) begin
	if (rst == 1'b1) begin
		delay_cnt <='d0;
	end
	else if (state == DELAY) begin
		delay_cnt <= delay_cnt + 1'b1;
	end
	else begin
		delay_cnt <= 'd0;
	end
end


always @(posedge sclk or posedge rst) begin
	if (rst == 1'b1) begin
		cs_n_r <= 1'b1;
	end
	else if(state == WE && div_cnt == DIV_END_NUM && bit_cnt == 'd8) begin
		cs_n_r <= 1'b1;
	end
	else if (state == IDLE && pp_flag == 1'b1) begin
		cs_n_r <= 1'b0;
	end
	else if(state == PP && div_cnt == DIV_END_NUM && bit_cnt == 'd2080) begin
		cs_n_r <= 1'b1;
	end
	else if(state == DELAY && delay_cnt == DELAY_END) begin
		cs_n_r <= 1'b0;
	end
end

always @(posedge sclk or posedge rst) begin
	if (rst == 1'b1) begin
		sck_r <= 1'b0;
	end
	else if (state == WE && div_cnt == (DIV_END_NUM >>1) && bit_cnt != 'd8) begin
		sck_r <= 1'b1;
	end
	else if (state == WE && div_cnt == (DIV_END_NUM ) && bit_cnt != 'd8) begin
		sck_r <= 1'b0;
	end
	else if (state == PP && div_cnt == (DIV_END_NUM >>1) && bit_cnt != 'd2080) begin
		sck_r <= 1'b1;
	end
	else if (state == PP && div_cnt == (DIV_END_NUM ) && bit_cnt != 'd2080) begin
		sck_r <= 1'b0;
	end
end


always @(posedge sclk or posedge rst) begin
	if (rst == 1'b1) begin
		we_inst_shift <= 'd0;
	end
	else if (pp_flag == 1'b1) begin
		we_inst_shift <= WRITE_EN;
	end
	else if(state == WE && div_cnt == DIV_END_NUM) begin
		we_inst_shift <= {we_inst_shift[6:0],1'b0};
	end
end
reg                     read_fifo_en_d;
always @(posedge sclk or posedge rst) begin
    if (rst == 1'b1) begin
		read_fifo_en_d <= 'd0;
	end
	else
        read_fifo_en_d <= read_fifo_en;
end

always @(posedge sclk or posedge rst) begin
	if (rst == 1'b1) begin
		pp_inst_shift <= 'd0;
	end
	else if (pp_flag == 1'b1 && state == IDLE) begin
		pp_inst_shift <= {PAGE_P,pp_addr};
	end
	else if (state == PP && div_cnt == DIV_END_NUM && bit_cnt < 'd31) begin
		pp_inst_shift <= {pp_inst_shift[30:0],1'b0};
	end
	else if (read_fifo_en_d == 1'b1) begin
		pp_inst_shift <= {read_fifo_data,24'd0};
	end
	else if (pp_shift_flag == 1'b1 ) begin
		pp_inst_shift <= {pp_inst_shift[30:24],25'd0};
	end
end

always @* begin
	if (bit_cnt >='d31 && bit_cnt <'d2079 && div_cnt == 'd2 && state == PP && bit_cnt[2:0]==3'b111) begin
		read_fifo_en <= 1'b1;
	end
	else begin
		read_fifo_en <= 1'b0;
	end
end

always @* begin
	if (bit_cnt >='d31 && bit_cnt <'d2079 && div_cnt == 'd3 && state == PP && bit_cnt[2:0]!=3'b111) begin
		pp_shift_flag <= 1'b1;
	end
	else begin
		pp_shift_flag <= 1'b0;
	end
end

always @*  begin
	if (state == WE) begin
		sdi_r <= we_inst_shift[7];
	end
	else if(state == PP) begin
		sdi_r <= pp_inst_shift[31];
	end
	else begin
		sdi_r <= 1'b0;
	end
end


fifo_1024x8 fifo_1024x8 (
  .clk(sclk),      // input wire clk
  .rst(rst),      // input wire rst
  .din(wr_data),      // input wire [7 : 0] din
  .wr_en(wr_en),  // input wire wr_en
  .rd_en(read_fifo_en),  // input wire rd_en
  .dout(read_fifo_data),    // output wire [7 : 0] dout
  .full(full),    // output wire full
  .empty(empty)  // output wire empty
);

//ila_3 ila_3 (
//	.clk(sclk), // input wire clk


//	.probe0(wr_en), // input wire [0:0]  probe0  
//	.probe1(read_fifo_en), // input wire [0:0]  probe1 
//	.probe2(wr_data), // input wire [7:0]  probe2 
//	.probe3(read_fifo_data), // input wire [7:0]  probe3
//	.probe4(sdi_r), // input wire [0:0]  probe3
//	.probe5(sck_r), // input wire [0:0]  probe3
//	.probe6(cs_n_r), // input wire [0:0]  probe3
//	.probe7(pp_inst_shift), // input wire [31:0]  probe3
//	.probe8(div_cnt), // input wire [7:0]  probe3
//	.probe9(bit_cnt) // input wire [11:0]  probe3
//);

endmodule 
