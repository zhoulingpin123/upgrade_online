`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/12 15:55:35
// Design Name: 
// Module Name: icap_delay
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


module icap_delay(
	input	wire 		sclk,
	input	wire 		rst,
	output	reg 		icap_flag,
	input	wire 		rx_flag,
	input	wire [7:0]	rx_data
	);

parameter TIMER_END = 1000000000-1;
reg 	[31:0]	time_cnt;
reg				stop_flag;

always @(posedge sclk or posedge rst) begin
	if (rst == 1'b1) begin
		stop_flag <= 1'b0;
	end
	else if (rx_flag== 1'b1 && rx_data == 8'hee) begin
		stop_flag <= 1'b1;
	end
end

always @(posedge sclk or posedge rst) begin
	if (rst == 1'b1) begin
		time_cnt <= 'd0;
	end
	else if (stop_flag == 1'b1) begin
		time_cnt <= time_cnt;
	end
	else begin
		time_cnt <= time_cnt + 1'b1;
	end
end

always @(posedge sclk or posedge rst) begin
	if (rst == 1'b1) begin
		icap_flag <= 1'b0;
	end
	else if (time_cnt >= TIMER_END) begin
		icap_flag <= 1'b1;
	end
	else begin
		icap_flag <= 1'b0;
	end
end
endmodule