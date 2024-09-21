`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/04 13:58:23
// Design Name: 
// Module Name: uart_tx
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


module uart_tx(
	input	wire 			sclk,
	input	wire 			rst_n,
	input	wire 			pi_flag,
	input	wire 	[7:0]	pi_data,
	output	reg 			tx
	);
parameter CNT_BAUD_MAX = 433;//5207;
//sim
//parameter CNT_BAUD_MAX = 28;
reg 	[7:0]	data_reg;
reg 			tx_flag;
reg 	[12:0]	cnt_baud;
reg 			bit_flag;
reg 	[3:0]	bit_cnt;


always @(posedge sclk or negedge  rst_n) begin
	if (rst_n == 1'b0) begin
		data_reg <='d0;
	end
	else if (pi_flag == 1'b1) begin
		data_reg <= pi_data;
	end
end

always @(posedge sclk or negedge rst_n) begin
	if (rst_n == 1'b0) begin
		tx_flag <= 1'b0;
	end
	else if(bit_flag == 1'b1 && bit_cnt == 4'd8) begin
		tx_flag <= 1'b0;
	end
	else if (pi_flag == 1'b1) begin
		tx_flag <= 1'b1;
	end
end

always @(posedge sclk or negedge rst_n) begin
	if (rst_n == 1'b0) begin
		cnt_baud <= 'd0;
	end
	else if(tx_flag == 1'b0)begin
		cnt_baud <='d0;
	end
	else if (tx_flag == 1'b1 && cnt_baud == CNT_BAUD_MAX) begin
		cnt_baud <= 'd0;
	end
	else if (tx_flag == 1'b1) begin
		cnt_baud <= cnt_baud + 1'b1;
	end
end

always @(posedge sclk or negedge rst_n) begin
	if (rst_n == 1'b0) begin
		bit_flag <= 1'b0;
	end
	else if (cnt_baud == CNT_BAUD_MAX -1  && tx_flag == 1'b1) begin
		bit_flag <= 1'b1;
	end
	else begin
		bit_flag <= 1'b0;
	end
end


always @(posedge sclk or negedge rst_n) begin
	if (rst_n == 1'b0) begin
		bit_cnt <= 'd0;
	end
	else if(bit_flag == 1'b1 &&  bit_cnt == 4'd8) begin
		bit_cnt <= 'd0;
	end
	else if (bit_flag == 1'b1) begin
		bit_cnt <= bit_cnt + 1'b1;
	end
end

always @(posedge sclk or negedge rst_n) begin
	if (rst_n == 1'b0) begin
		tx <= 1'b1;
	end
	else if (pi_flag == 1'b1) begin
		tx <= 1'b0;
	end
	else if (bit_cnt<=7 && bit_flag == 1'b1) begin
		tx <= data_reg[bit_cnt];
	end
	else if (bit_flag == 1'b1 && bit_cnt == 4'd8) begin
		tx <= 1'b1;
	end
end


//ila_4 ila_4 (
//	.clk(sclk), // input wire clk


//	.probe0(pi_flag), // input wire [0:0]  probe0  
//	.probe1(pi_data), // input wire [7:0]  probe1 
//	.probe2(tx), // input wire [0:0]  probe2 
//	.probe3(data_reg) // input wire [7:0]  probe3
//);
endmodule 
