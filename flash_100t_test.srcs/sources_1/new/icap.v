`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/12 15:57:07
// Design Name: 
// Module Name: icap
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


module icap(
input           clk ,
input           rst ,  
input           icap_flag
    );
    
parameter	DUMMY_WORD	= 32'hffff_ffff;	//伪指令，不进行操作，实际上为等待状态
parameter	SYNC_WORD	= 32'haa99_5566;	//跳转指令同步字
parameter	T1WBS		= 32'h3002_0001;	//type1 写入跳转空间的字节
parameter	WBSA		= 32'h0040_0000;	//跳转空间地址，可以根据bit大小修改
parameter	T1CMD		= 32'h3000_8001;	//type1 写入的控制指令字
parameter	IPROG		= 32'h0000_000f;	//跳转到下一个程序的控制指令
parameter	T1NOOP		= 32'h2000_0000;	//中断指令


//状态
parameter	S_DUM_WORD	=	8'h001;
parameter	S_SYNC_WORD	=	8'h002;
parameter	S_T1WBS	=	8'h004;
parameter	S_WBSA	=	8'h008;
parameter	S_T1CMD	=	8'h010;
parameter	S_IPROG	=	8'h020;
parameter	S_T1NOOP	=	8'h040;
parameter	S_T1NOOP_2	=	8'h080;

//实现指令的跳转可以使用计数器或状态机，以计数器为例
reg             [31:0]      I_reg;
reg             [7:0]	    state	;
always@(posedge clk or negedge rst)
begin
if(!rst)
	state<=S_DUM_WORD;//初始状态下为等待状态
else case(state)
    S_DUM_WORD:
        if(icap_flag==1'b1)
           state<=S_SYNC_WORD;
    S_SYNC_WORD:state<=S_T1NOOP;
    S_T1NOOP:state<=S_T1WBS;
    S_T1WBS:state<=S_WBSA;
    S_WBSA:state<=S_T1CMD;
    S_T1CMD:state<=S_IPROG;
    S_IPROG:state<=S_T1NOOP_2;
    S_T1NOOP_2:state<=S_DUM_WORD;
    default:state<=S_DUM_WORD;
    endcase
end

reg                 CSIB;
reg                 RDWRB;
always@(posedge clk or negedge rst)begin
    if(!rst)
        CSIB <= 1;
    else if(state == S_SYNC_WORD)
        CSIB <= 0;
    else if(state == S_DUM_WORD)
        CSIB <= 1;
end
   
always@(posedge clk or negedge rst)begin
    if(!rst)
        RDWRB <= 1;
    else if(state == S_SYNC_WORD)
        RDWRB <= 0;
    else if(state == S_DUM_WORD)
        RDWRB <= 1;
end

always@(posedge	clk	or	negedge	rst)begin
	if(!rst)	
		I_reg	<=	DUMMY_WORD;
	else case(state)
	S_DUM_WORD:
		I_reg	<=	DUMMY_WORD;
	S_SYNC_WORD:
		I_reg	<=	SYNC_WORD;
	S_T1NOOP:
		I_reg	<=	T1NOOP;    
	S_T1WBS:                           
		I_reg	<=	T1WBS;     
	S_WBSA:                            
		I_reg	<=	WBSA;      
	S_T1CMD:                           
		I_reg	<=	T1CMD; 
	S_IPROG:                           
		I_reg	<=	IPROG; 
	S_T1NOOP_2:                           
		I_reg	<=	T1NOOP;     
	default:I_reg	<=	DUMMY_WORD;
	endcase
end
wire       [31:0]         I;
assign	I={	I_reg[24],I_reg[25],I_reg[26],I_reg[27],I_reg[28],I_reg[29],
			I_reg[30],I_reg[31],I_reg[16],I_reg[17],I_reg[18],I_reg[19],
            I_reg[20],I_reg[21],I_reg[22],I_reg[23],I_reg[08],I_reg[09],
            I_reg[10],I_reg[11],I_reg[12],I_reg[13],I_reg[14],I_reg[15],
            I_reg[00],I_reg[01],I_reg[02],I_reg[03],I_reg[04],I_reg[05],
            I_reg[06],I_reg[07]};





    
   wire        [31:0]       O;      
   ICAPE2 #(
      .DEVICE_ID(32'h3631093),     // Specifies the pre-programmed Device ID value to be used for simulation
                                  // purposes.
      .ICAP_WIDTH("X32"),         // Specifies the input and output data width.
      .SIM_CFG_FILE_NAME("NONE")  // Specifies the Raw Bitstream (RBT) file to be parsed by the simulation
                                  // model.
   )
   ICAPE2_inst (
      .O(O),         // 32-bit output: Configuration data output bus
      .CLK(clk),     // 1-bit input: Clock Input
      .CSIB(CSIB),   // 1-bit input: Active-Low ICAP Enable
      .I(I),         // 32-bit input: Configuration data input bus
      .RDWRB(RDWRB)  // 1-bit input: Read/Write Select input
   );
   
endmodule
