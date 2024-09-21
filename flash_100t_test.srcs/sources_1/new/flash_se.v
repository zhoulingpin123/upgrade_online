`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/02 17:51:26
// Design Name: 
// Module Name: flash_se
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


module  flash_se(
	input	wire 		sclk,
	input	wire 		rst,
	input	wire 		se_flag,
	input	wire [23:0]	se_addr,
	output	wire 		sck,
	output	wire 		cs_n,
	output	wire 		sdi
	);

parameter	IDLE 	= 4'b0001;
parameter	WE 		= 4'b0010;
parameter	DELAY	= 4'b0100;
parameter	SE 		= 4'b1000;

parameter	DIV_END_NUM = 3;
parameter 	DELAY_END =15;
parameter	WRITE_EN =8'h06;
parameter   SECTOR_E =8'h20;

reg 	[3:0]	state;
reg 	[7:0]	div_cnt;
reg 	[7:0]	bit_cnt;
reg 	[7:0]	delay_cnt;
reg 			cs_n_r;
reg 			sck_r;
reg 			sdi_r;
reg 	[7:0]	we_inst_shift;
reg 	[31:0]	se_inst_shift;

assign sck = sck_r;
assign cs_n = cs_n_r;
assign sdi = sdi_r;
always @(posedge sclk or posedge rst) begin
	if (rst == 1'b1) begin
		state <= IDLE;
	end
	else case (state)
		IDLE : if(se_flag == 1'b1 )
				state <= WE;
		WE 	 : if(div_cnt == DIV_END_NUM && bit_cnt == 'd8)
				state <= DELAY;
		DELAY: if (delay_cnt == DELAY_END)
				state <= SE;
		SE   : if(div_cnt == DIV_END_NUM && bit_cnt == 'd32)
				state <= IDLE;
		default : state <= IDLE;
		endcase
end

always @(posedge sclk or posedge rst) begin
	if (rst == 1'b1) begin
		div_cnt <= 'd0;
	end
	else if(div_cnt == DIV_END_NUM) begin
		div_cnt <='d0;
	end
	else if (state == WE || state == SE) begin
		div_cnt <= div_cnt + 1'b1;
	end
end

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
	else if (state == SE && bit_cnt == 'd32 && div_cnt == DIV_END_NUM) begin
		bit_cnt <='d0;
	end
	else if (state == SE && div_cnt == DIV_END_NUM) begin
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
	else if (state == IDLE && se_flag == 1'b1) begin
		cs_n_r <= 1'b0;
	end
	else if(state == SE && div_cnt == DIV_END_NUM && bit_cnt == 'd32) begin
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
	else if (state == SE && div_cnt == (DIV_END_NUM >>1) && bit_cnt != 'd32) begin
		sck_r <= 1'b1;
	end
	else if (state == SE && div_cnt == (DIV_END_NUM ) && bit_cnt != 'd32) begin
		sck_r <= 1'b0;
	end
end


always @(posedge sclk or posedge rst) begin
	if (rst == 1'b1) begin
		we_inst_shift <= 'd0;
	end
	else if (se_flag == 1'b1) begin
		we_inst_shift <= WRITE_EN;
	end
	else if(state == WE && div_cnt == DIV_END_NUM) begin
		we_inst_shift <= {we_inst_shift[6:0],1'b0};
	end
end


always @(posedge sclk or posedge rst) begin
	if (rst == 1'b1) begin
		se_inst_shift <= 'd0;
	end
	else if (se_flag == 1'b1 && state == IDLE) begin
		se_inst_shift <= {SECTOR_E,se_addr};
	end
	else if (state == SE && div_cnt == DIV_END_NUM) begin
		se_inst_shift <= {se_inst_shift[30:0],1'b0};
	end
end

always @*  begin
	if (state == WE) begin
		sdi_r <= we_inst_shift[7];
	end
	else if(state == SE) begin
		sdi_r <= se_inst_shift[31];
	end
	else begin
		sdi_r <= 1'b0;
	end
end


endmodule
