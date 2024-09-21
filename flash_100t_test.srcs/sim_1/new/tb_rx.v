`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/05 13:27:36
// Design Name: 
// Module Name: tb_rx
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


module tb_rx();
reg         sclk;
reg         rst_n;
reg         rx;

reg  [7:0]  mem_a [3:0];
initial  begin
    sclk = 0;
    forever #(10) sclk = ~sclk;
end

initial begin
    rst_n = 0;
    rx = 1;
    #100
    rst_n = 1;
    #100
    tx_byte();
end

initial  $readmemh ("D:/2024/01/Upgrade_online/flash_100t_test/flash_100t_test.srcs/sim_1/new/tx_data.txt",mem_a);

task tx_byte();
     integer i;
     for(i=0;i<4;i=i+1)begin
        tx_bit(mem_a[i]);
     end   
endtask


task tx_bit(
               input  [7:0] data
            );
      integer i;
      for(i=0;i<10;i=i+1)begin
        case(i)
                0: rx <= 1'b0;
                1: rx <= data[0];
                2: rx <= data[1];
                3: rx <= data[2];
                4: rx <= data[3];
                5: rx <= data[4];
                6: rx <= data[5];
                7: rx <= data[6];
                8: rx <= data[7];
                9: rx <= 1'b1;
         endcase  
         #560;     
      end
 endtask
reg         [7:0]  a = 0;


always @(posedge sclk) begin
        a <= a+1;
end

integer save_file;
initial begin
    save_file = $fopen("D:/2024/01/Upgrade_online/flash_100t_test/flash_100t_test.srcs/sim_1/new/test.txt","w");    //打开所创建的文件；若找不到该文件，则会自动创建该文件。
end

always @(posedge sclk) begin
        $fdisplay(save_file,"%d",a);    //在使能信号为高时，每当时钟的上升沿到来时将数据写入到所创建的.txt文件中
end


uart_rx uart_rx(
	.sclk      (sclk   )        ,
	.rst_n     (rst_n  )        ,
	.rx        (rx     )        ,
	.po_data   ()               ,
	.po_flag   ()
	);
endmodule
