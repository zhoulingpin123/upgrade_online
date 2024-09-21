`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/04 14:00:59
// Design Name: 
// Module Name: state_ctrl
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


module state_ctrl(
	input	wire 		sclk,
	input	wire 		rst,
	output	reg  		cs_n,
	output	reg 		sck,
	output	reg 		sdi,
	input	wire 		sdo,
	/*************uart rx****************************/
	input	wire 		rx_flag,
	input	wire [7:0]	rx_data,
	/************uart tx ***************************/
	output	wire 		tx_flag,
	output	wire [7:0]	tx_data,
	/************flash se interface*******************/
	output	wire 		se_flag,
	output	wire [23:0]	se_addr,
	input	wire 		se_sck,
	input	wire 		se_cs_n,
	input	wire 		se_sdi,
	/************flash pp interface******************/
	output	wire 		pp_flag,
	output	wire [23:0]	pp_addr,
	output	wire 		wr_en,
	output	wire [7:0]	wr_data,
	input	wire 		pp_sck,
	input	wire 		pp_cs_n,
	input	wire 		pp_sdi,
	/************flash rd interface******************/
	output	wire 		rd_flag,
	output	wire [23:0]	rd_addr,
	output	wire [12:0]	rd_len,
	input	wire 		rd_ready,
	output	wire		rd_en,
	input	wire [7:0]	rd_data,
	input	wire 		rd_sck,
	input	wire 		rd_cs_n,
	output	wire 		rd_sdo,
	input	wire 		rd_sdi
	);
parameter 	IDLE =4'b0001;
parameter	WRITE =4'b0010;
parameter	SERASE=4'b0100;
parameter	READ  =4'b1000;

parameter	DIV_CNT_END = 4340;//52082;

reg [3:0]	state;
reg 		write_end,serase_end,read_end;
reg [15:0]	byte_cnt;
reg [23:0]	flash_addr_shift;
reg 		wr_fifo_en;
reg [7:0]	wr_fifo_data;
reg [15:0]	rd_len_shift;
reg 		rd_flash_req;//rd_flag
reg [15:0]	div_cnt;
reg 		rd_fifo_en;
reg [15:0]	tx_d_cnt;

//根据串口指令判断是擦除(ee),写（cc）,还是读（dd）
always @(posedge sclk or posedge rst) begin
	if (rst == 1'b1) begin
		state <= IDLE;
	end
	else case(state)
		IDLE : if(rx_flag == 1'b1 && rx_data == 8'hcc)begin
			         state <= WRITE;
		       end
		       else if(rx_flag == 1'b1 && rx_data == 8'hee) begin
			         state <= SERASE;
		       end
		       else if (rx_flag == 1'b1 && rx_data == 8'hdd) begin
			         state <= READ;
		       end
		WRITE : if (write_end == 1'b1 ) begin
			         state <= IDLE;
		        end
		SERASE : if (serase_end == 1'b1 ) begin
			         state <= IDLE;
		         end
		READ : if (read_end == 1'b1) begin
			         state <= IDLE;
		       end
		default : state <= IDLE;
	endcase
end
//计数接收的字节数
//write state and flash pp
always @(posedge sclk or posedge rst) begin
	if (rst == 1'b1) begin
		byte_cnt <= 'd0;
	end
	else if (state == IDLE) begin
		byte_cnt <='d0;
	end
	else if (state != IDLE && rx_flag == 1'b1) begin
		byte_cnt <= byte_cnt + 1'b1;
	end
end

//寄存24bit地址
always @(posedge sclk or posedge rst) begin
	if (rst == 1'b1) begin
		flash_addr_shift <= 'd0;
	end
	else if (state != IDLE && byte_cnt < 3 && rx_flag == 1'b1  ) begin
		flash_addr_shift <= {flash_addr_shift[15:0],rx_data};
	end
end
//写状态时控制fifo写使能，将数据写入fifo
always @(posedge sclk or posedge rst) begin
	if (rst == 1'b1) begin
		wr_fifo_en <= 1'b0;
	end
	else if (state == WRITE && byte_cnt >2 && rx_flag == 1'b1) begin
		wr_fifo_en <= 1'b1;
	end
	else begin
		wr_fifo_en <= 1'b0;
	end
end
//写状态时将串口接收到的数据寄存
always @(posedge sclk or posedge rst) begin
	if (rst == 1'b1) begin
		wr_fifo_data <= 'd0;
	end
	else if (state == WRITE) begin
		wr_fifo_data <= rx_data;
	end
end
//当写完256B数据时，写结束
always @(posedge sclk or posedge rst) begin
	if (rst == 1'b1) begin
		write_end <=1'b1;
	end
	else if (state == WRITE && byte_cnt == 'd258 && rx_flag == 1'b1) begin
		write_end <= 1'b1;
	end
	else begin
		write_end <= 1'b0;
	end
end
//写结束标识，同时也是页写标识，将fifo的数据写入flash
assign pp_flag = write_end;
assign pp_addr = flash_addr_shift;
assign wr_en = wr_fifo_en;
assign wr_data = wr_fifo_data;
//write state end
//serase state start
always @(posedge sclk or posedge rst) begin
	if (rst == 1'b1) begin
		serase_end <= 1'b0;
	end
	else if (state == SERASE && rx_flag == 1'b1 && byte_cnt == 2) begin
		serase_end <= 1'b1;
	end
	else begin
		serase_end <= 1'b0;
	end
end
assign se_flag = serase_end;
assign se_addr = flash_addr_shift;
//serase state end
//read state start

//寄存读取长度
always @(posedge sclk or posedge rst) begin
	if (rst == 1'b1) begin
		rd_len_shift <='d0;
	end
	else if (state == READ && (byte_cnt == 3 || byte_cnt == 4) && rx_flag == 1'b1 ) begin
		rd_len_shift <= {rd_len_shift[7:0],rx_data};
	end
end
//开始读flash标志
always @(posedge sclk or posedge rst) begin
	if (rst == 1'b1) begin
		rd_flash_req<= 1'b0;
	end
	else if (state == READ && byte_cnt == 4 && rx_flag == 1'b1 ) begin
		rd_flash_req <= 1'b1;
	end
	else begin
		rd_flash_req <= 1'b0;
	end
end

always @(posedge sclk or posedge rst) begin
	if (rst == 1'b1) begin
		div_cnt <='d0;
	end
	else if(state == READ && rd_ready == 1'b1 && div_cnt == DIV_CNT_END)begin
		div_cnt <= 'd0;
	end
	else if (state == READ && rd_ready == 1) begin
		div_cnt <= div_cnt + 1'b1;
	end
	else if (rd_ready == 1'b0) begin
		div_cnt <='d0;
	end
end

always @(posedge sclk or posedge rst) begin
	if (rst == 1'b1) begin
		rd_fifo_en <= 1'b0;
	end
	else if (state == READ && rd_ready == 1'b1 && div_cnt ==0) begin
		rd_fifo_en <= 1'b1;
	end
	else begin
		rd_fifo_en <= 1'b0;
	end
end

always @(posedge sclk or posedge rst) begin
	if (rst == 1'b1) begin
		tx_d_cnt <='d0;
	end
	else if (state == READ && rd_fifo_en == 1'b1 ) begin
		tx_d_cnt <= tx_d_cnt + 1'b1;
	end
	else if(state != READ) begin
		tx_d_cnt <='d0;
	end
end

always @(posedge sclk or posedge rst) begin
	if (rst == 1'b1) begin
		read_end <= 1'b0;
	end
	else if (state == READ && tx_d_cnt == (rd_len_shift-1)&&rd_fifo_en == 1'b1 ) begin
		read_end <= 1'b1;
	end
	else begin
		read_end <= 1'b0;
	end
end
reg             rd_fifo_en_d;
always @(posedge sclk or posedge rst) begin
    if (rst == 1'b1) begin
		rd_fifo_en_d <= 1'b0;
	end
	else   rd_fifo_en_d <= rd_fifo_en;
end

assign rd_flag = rd_flash_req;
assign rd_addr = flash_addr_shift;
assign rd_len = rd_len_shift[12:0];
assign rd_en = rd_fifo_en;

assign tx_flag = rd_fifo_en_d;
assign tx_data = rd_data;

//read state  end
//flash spi signal route

always @* begin
	if(state == READ) begin
		sdi <= rd_sdi;
		cs_n <= rd_cs_n;
		sck <= rd_sck;
	end
	else begin
		sdi <= se_sdi | pp_sdi;
		sck <= se_sck | pp_sck;
		cs_n <= se_cs_n & pp_cs_n;
	end
end

assign rd_sdo =sdo ;

//wire [35:0] CONTROL0;
wire [39:0]	TRIG0;

assign TRIG0 = {
	rd_fifo_en,
	rd_data,
	rd_ready,
	rd_flash_req,
	byte_cnt,
	state,
	rx_data,
	rx_flag
};
//cs_icon cs_icon_inst (
//    .CONTROL0(CONTROL0) // INOUT BUS [35:0]
//);

//cs_ila cs_ila_inst (
//    .CONTROL(CONTROL0), // INOUT BUS [35:0]
//    .CLK(sclk), // IN
//    .TRIG0(TRIG0) // IN BUS [39:0]
//);



//ila_1 ila_1 (
//	.clk(sclk), // input wire clk


//	.probe0(tx_d_cnt), // input wire [15:0]  probe0  
//	.probe1(div_cnt), // input wire [15:0]  probe1 
//	.probe2(rd_ready), // input wire [0:0]  probe2 
//	.probe3(TRIG0), // input wire [39:0]  probe3
//	.probe4(rd_len), // input wire [10:0]  probe4 
//	.probe5(rd_addr) // input wire [23:0]  probe5
//);

endmodule 
