`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/05 09:57:38
// Design Name: 
// Module Name: tb_top
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


module tb_top();
reg         sys_clk;
reg         rst;
reg         rx;
reg         sdo;
wire        sck;
reg [7:0] mem_a [6:0];

initial begin
   sys_clk = 0;
   forever #(10)  sys_clk =~sys_clk;
    
end

initial $readmemh("D:/2024/01/Upgrade_online/flash_100t_test/flash_100t_test.srcs/sim_1/new/tx_data.txt", mem_a);

initial begin
    rst = 0;
    rx = 1;
    #20
    repeat (5) @(posedge sys_clk);
    rst = 1;
    repeat (10) @(posedge sys_clk);
    rst = 0;
    #100
    tx_byte();
    $display("This is a test.");
end

//initial begin
//    rx = 1;
//    @(posedge rst);
//    @(negedge rst);
//    repeat (5) @(posedge sys_clk);
//    tx_byte();
//end


task    tx_byte();
        integer i;
        for(i=0; i<7; i=i+1) begin
                tx_bit(mem_a[i]);
        end
endtask

task    tx_bit(
                input   [ 7:0]  data
                );
        integer i;
        for(i=0; i<10; i=i+1) begin
                case(i)
                        0:      rx        <=      1'b0;
                        1:      rx        <=      data[0];
                        2:      rx        <=      data[1];
                        3:      rx        <=      data[2];
                        4:      rx        <=      data[3];
                        5:      rx        <=      data[4];
                        6:      rx        <=      data[5];
                        7:      rx        <=      data[6];
                        8:      rx        <=      data[7];
                        9:      rx        <=      1'b1;
                endcase
                #560;		//发送一个Byte所需时间，例如发送1Byte需要28个时钟周期，时钟是50M，那么需要28*20ns = 560ns
        end
endtask


task flash_sdo;
	integer i,j;
	begin
		repeat (32) @(posedge sck);
		for(i=0;i<256;i=i+1)begin
			for(j=0;j<8;j=j+1)begin
				@(negedge sck);
				sdo	= i[7-j];
			end

		end
	end
endtask


top top(
. sys_clk (sys_clk)  ,
. rst     (rst)  ,
. cs_n    ()  ,
. sck    (sck)  ,
. rx      (rx)  ,
. tx      ()  ,
. sdo     (sdo)  ,
. sdi     ()
    );
endmodule
