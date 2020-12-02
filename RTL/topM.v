
/*************************************************************************
 * FILE:        dlx.v
 * Written By:  Michael J. Kelley
 * Written On:  December 18, 1995
 * Updated By:  Michael J. Kelley
 * Updated On:  March 4, 1996
 *
 * Description:
 *
 * This file contains the hardware description of the DLX architecture
 * as specified by Hennessy and Patterson in Computer Architecture a 
 * Quantitative Approach.
 *************************************************************************
 */

//`include "/l/users/mkelley/DLX/verilog/dlx.defines"
`include "./dlx.defines"
`timescale 1ns/1ps

module dlx (
	PHI1,                             // One-Phase clock for DLX 
	DAddr, DRead, DWrite, DOut, DIn,  // Data Cache interface
	IAddr, IRead, IIn,                // Instruction Cache interface
	MRST, TCE, TMS, TDI, TDO          // Test Controls
);

/*************************************************************************
 * Parameter Declarations
 *************************************************************************
 */
					
input						PHI1;		// One-Phase clock signal used
output [`WordSize]	DAddr;          // Address for Data Cache read/write
output					DRead;          // Data Cache read enable
output					DWrite;         // Data Cache write enable
output [`WordSize]	DOut;           // Data Input to Data Cache (write)
input  [`WordSize]	DIn;            // Data Output from Data Cache (read)
output [`WordSize]	IAddr;          // Instruction Cache read address
output					IRead;          // Instruction Cache read enable
input  [`WordSize]	IIn;            // Instruction from Instruction Cache
input						MRST;           // Master Reset
input						TCE;            // Test Clock Enable
input						TMS;		// Test Mode Select
input						TDI;		// Test Data In
output					TDO;		// Test Data Out
					
wire	[`WordSize]	DAddr;
wire					DRead, MemControl_DRead;
wire					DWrite, MemControl_DWrite;
wire	[`WordSize]	DOut, DataWriteReg_Q;
wire	[`WordSize]	IAddr, IR2_Q; 
wire					IRead;
wire					TDO;
wire  [`WordSize] RegFile_OUT1, SourceMux_IN1, TargetMux_IN1, PC2_Q, PC4_D;
wire  [`WordSize] PCMux_Y, PC2_D, PC1_Q, PC3_D, IDControl_IR2, PCAdd_A; 
wire  [`WordSize] WBMux_Y, SourceReg_Q, DataWriteMux_IN0, IR3_Q, ALU_F ;
wire  [`WordSize] TargetReg_Q, DataWriteMux_IN1, PCAdd_SUM; 
wire  [`WordSize] WBMux_IN0, WBMux_IN1, WBControl_IR5, PC4_Q, IR4_Q; 
wire  [4:0] 		RegFile_W, DestinationReg_Q, DestinationMux_Y, WriteDestinationReg_Q; 
wire  [`WordSize] IR5_Q;
wire 					IFControl_Equal, WBControl_WriteEnable;
wire [`WordSize] PCFEED;
wire PCFEEDEN;

IF_stage part1_IF ( 
	PHI1, MRST, IFControl_Equal, 
	IIn, PCAdd_SUM, RegFile_OUT1,PCFEED, PCFEEDEN, 
	IAddr, PC3_D, IDControl_IR2, PCAdd_A
);

ID_stage part2_ID ( 
	PHI1, MRST, WBControl_WriteEnable,
	IDControl_IR2, WBMux_Y, PCAdd_A, PC3_D,
	WriteDestinationReg_Q,
	RegFile_OUT1, PCAdd_SUM, SourceMux_IN1, TargetMux_IN1, PC4_D, IR3_Q,
	IFControl_Equal
);

EX_stage part3_EX (
	PHI1, MRST,
	IR3_Q, IR5_Q, WBMux_Y, SourceMux_IN1, TargetMux_IN1, PCAdd_A, PC4_D,
	IR4_Q, DAddr, DOut, PC4_Q,
	DestinationReg_Q, PCFEED, PCFEEDEN
);

MEM_stage part4_MEM (
	PHI1, MRST,
	DIn, DAddr, IR4_Q, PC4_Q, 
	DestinationReg_Q,
	WBMux_IN0, WBMux_IN1, IR5_Q, 
	WriteDestinationReg_Q,
	DRead, DWrite
);

WB_stage part5_WB (
	WBMux_IN0, WBMux_IN1, IR5_Q,
	WBMux_Y,
	WBControl_WriteEnable
);

endmodule
 
/*************************************************************************
 * Instruction Fetch (IF) Stage of DLX Pipeline
 *************************************************************************
 */
module IF_stage ( 
	PHI1, MRST, IFControl_Equal, 
	IIn, PCAdd_SUM, RegFile_OUT1, PCFEED, PCFEEDEN,
	IAddr, PC3_D, IDControl_IR2, PCAdd_A
);
input [`WordSize] IIn, PCAdd_SUM, RegFile_OUT1;
input PHI1, MRST, IFControl_Equal;
output [`WordSize] IAddr, PC3_D, IDControl_IR2, PCAdd_A;
input [`WordSize] PCFEED;
input PCFEEDEN;

wire [`WordSize] PC1_Q, PCInc_SUM, PC1_D, IFControl_PCVector; 
wire [1:0] IFControl_PCMuxSelect;

reg [`WordSize] PC_D1;


IFCtrl 

	IFControl (
		.IR2		(IDControl_IR2),
		.Equal		(IFControl_Equal),
		.MRST		(MRST),
		.PCMuxSelect	(IFControl_PCMuxSelect),
		.PCVector	(IFControl_PCVector)
	);

addhsv #(32, 1, "AUTO") 
	
	PCInc (
		.A	(PC1_Q),
		.B	(`PCInc),
		.CIN	(`LogicZero),
		.SUM	(PCInc_SUM),
		.COUT	(),
		.OVF	()
	);

// addition for branch

always @(*)
begin
if (PCFEEDEN == 1'b1)
begin
PC_D1 = PCFEED;
end
else
begin
PC_D1 = PC1_D;
end
end





newmux4 #(32, 1, "AUTO") 

	PCMux (
		.S0	(IFControl_PCMuxSelect[0]),
		.S1	(IFControl_PCMuxSelect[1]),
		.IN0	(PCInc_SUM),
		.IN1	(PCAdd_SUM),
		.IN2	(IFControl_PCVector),
		.IN3	(RegFile_OUT1),
		.Y	(PC1_D)
	);

dff_cq #(32, 1, "AUTO") 
	
	PC1 (
		.CLK	(PHI1),
		.CLR	(MRST),
		.D	(PC_D1),    
		.Q	(PC1_Q),
		.QBAR	()
	),   

	PC2 (
		.CLK	(PHI1),
		.CLR	(MRST),
		.D	(PC1_Q),
		.Q	(PC3_D),
		.QBAR	()
	);

assign IAddr = PC1_Q;

dff_cq #(32, 1, "AUTO")

	IR2 (
		.CLK	(PHI1),
		.CLR	(MRST),
		.D	(IIn),
		.Q	(IDControl_IR2),
		.QBAR	()
	),

	PCIncReg  (
		.CLK	(PHI1),
		.CLR	(MRST),
		.D	(PCInc_SUM),
		.Q	(PCAdd_A),
		.QBAR	()
	);

endmodule

/*************************************************************************
 * Instruction Decode (ID) Stage of DLX Pipeline
 *************************************************************************
 */
module ID_stage ( 
	PHI1, MRST, WBControl_WriteEnable,
	IDControl_IR2, WBMux_Y, PCAdd_A, PC3_D,
	WriteDestinationReg_Q,
	RegFile_OUT1, PCAdd_SUM, SourceMux_IN1, TargetMux_IN1, PC4_D, IR3_Q,
	IFControl_Equal
);

input PHI1, MRST, WBControl_WriteEnable;
input [`WordSize] IDControl_IR2, WBMux_Y, PCAdd_A, PC3_D; 
input [4:0] WriteDestinationReg_Q;
output [`WordSize] RegFile_OUT1, PCAdd_SUM, SourceMux_IN1, TargetMux_IN1, PC4_D, IR3_Q;
output IFControl_Equal;

wire [1:0] IDControl_PCAddMuxSelect;
wire [`WordSize] TargetReg_D, PCAddMux_Y;

reg [`WordSize] PCMUX;


IDCtrl 
	IDControl (
		.IR2		(IDControl_IR2),
		.PCAddMuxSelect	(IDControl_PCAddMuxSelect)
	);

regfile2r #(32, 32, 5, "AUTO")

	RegFile (
		.W	(WriteDestinationReg_Q),
		.IN0	(WBMux_Y),
		.R1	(IDControl_IR2[`RS]),
		.R2	(IDControl_IR2[`RT]),
		.RE1	(`LogicOne),
		.RE2	(`LogicOne),
		.WE	(WBControl_WriteEnable & ~PHI1),
		.OUT1	(RegFile_OUT1),
		.OUT2	(TargetReg_D)
	);





newmux3 #(32, 1, "AUTO")

	PCAddMux (
		.S0	(IDControl_PCAddMuxSelect[0]),
		.S1	(IDControl_PCAddMuxSelect[1]),
		.IN0	({{16{IDControl_IR2[15]}}, IDControl_IR2[`Immediate]}),
		.IN1	({{6{IDControl_IR2[25]}}, IDControl_IR2[`Target]}),
		.IN2	(RegFile_OUT1),
		.Y	(PCAddMux_Y)
	);


always @(*)
begin
if (IDControl_IR2[`OP] == `BEQZ)
begin
PCMUX = `PCInc;
end
else
begin
PCMUX = PCAddMux_Y;
end
end




addhsv #(32, 1, "AUTO") 
	
	PCAdd (
		.A	(PCAdd_A),
		.B	(PCMUX),
		.CIN	(`LogicZero),
		.SUM	(PCAdd_SUM),
		.COUT	(),
		.OVF	()
	);

zero_compare #(1, "AUTO")

	Compare (
		.A				(RegFile_OUT1),
		.A_lessthan_zero		(),
		.A_lessthan_equal_zero		(),
		.A_greaterthan_equal_zero	(),
		.A_greaterthan_zero		(),
		.A_equal_zero			(IFControl_Equal),
		.A_not_equal_zero		()
	);

dff_cq #(32, 1, "AUTO")

	SourceReg (
		.CLK	(PHI1),
		.CLR	(MRST),
		.D	(RegFile_OUT1),
		.Q	(SourceMux_IN1),
		.QBAR	()
	),

	TargetReg (
		.CLK	(PHI1),
		.CLR	(MRST),
		.D	(TargetReg_D),
		.Q	(TargetMux_IN1),
		.QBAR	()
	),

	PC3 (
		.CLK	(PHI1),
		.CLR	(MRST),
		.D	(PC3_D),
		.Q	(PC4_D),
		.QBAR	()
	);

dff_cq #(32, 1, "AUTO")	

	IR3 (
		.CLK	(PHI1),
		.CLR	(MRST),
		.D	(IDControl_IR2),
		.Q	(IR3_Q),
		.QBAR	()
	);

endmodule

/*************************************************************************
 * Execute (EX) Stage of DLX Pipeline
 *************************************************************************
 */
module EX_stage (
	PHI1, MRST,
	IR3_Q, IR5_Q, WBMux_Y, SourceMux_IN1, TargetMux_IN1, PCAdd_A, PC4_D,
	IR4_Q, DAddr, DOut, PC4_Q,
	DestinationReg_Q, PCFEED, PCFEEDEN
); // additional outputs for branch
input PHI1, MRST;
input [`WordSize] IR3_Q, IR5_Q, WBMux_Y, SourceMux_IN1, TargetMux_IN1, PCAdd_A, PC4_D;
output [`WordSize] IR4_Q, DAddr, DOut, PC4_Q;
output [4:0] DestinationReg_Q;
output [`WordSize] PCFEED;
output PCFEEDEN;

wire [`WordSize] SourceMux_Y, TargetMux_Y;
wire [1:0] EXControl_DestinationMuxSelect, EXControl_ALUorShiftMuxSelect, EXControl_SourceMuxSelect, EXControl_TargetMuxSelect;
wire [1:0] EXControl_CompareMux1Select, EXControl_CompareMux2Select, EXControl_CompareResultMuxSelect;
wire DataWriteMux_S0;
wire [5:0] EXControl_ALUSelect;
wire [4:0] ShiftLeft_S, DestinationReg_D;
wire [`WordSize] DataWriteReg_D, ALU_F, Shift_Y, ALUorShiftMux_Y, CompareResultMux_Y;
wire CompareMux1_IN0, CompareMux1_IN1, CompareMux1_IN2, CompareMux2_IN0, CompareMux2_IN1, CompareMux2_IN2;
wire CompareMux1_Y, CompareMux2_Y;

// my addition
reg [`WordSize] SourceMux_Y1;
reg [`WordSize] PCFEED1;
reg PCFEEDEN1;

EXCtrl
	EXControl (
		.IR3			(IR3_Q),
		.IR4			(IR4_Q),
		.IR5			(IR5_Q),
		.ShiftAmount		(TargetMux_Y),
		.DestinationMuxSelect	(EXControl_DestinationMuxSelect),
		.DataWriteMuxSelect	(DataWriteMux_S0),
		.ALUSelect		(EXControl_ALUSelect),
		.ShiftSelect		(ShiftLeft_S),
		.ALUorShiftMuxSelect	(EXControl_ALUorShiftMuxSelect),
		.SourceMuxSelect	(EXControl_SourceMuxSelect),
		.TargetMuxSelect	(EXControl_TargetMuxSelect),
		.CompareMux1Select	(EXControl_CompareMux1Select),
		.CompareMux2Select	(EXControl_CompareMux2Select),
		.CompareResultMuxSelect	(EXControl_CompareResultMuxSelect)
	);

newmux4 #(32, 1, "AUTO") 

	SourceMux (
		.S0	(EXControl_SourceMuxSelect[0]),
		.S1	(EXControl_SourceMuxSelect[1]),
		.IN0	(WBMux_Y),
		.IN1	(SourceMux_IN1),
		.IN2	(DAddr),
		.IN3	(PCAdd_A),
		.Y	(SourceMux_Y)
	);


newmux4 #(32, 1, "AUTO")

	TargetMux (
		.S0	(EXControl_TargetMuxSelect[0]),
		.S1	(EXControl_TargetMuxSelect[1]),
		.IN0	(WBMux_Y),
		.IN1	(TargetMux_IN1),
		.IN2	({{16{IR3_Q[15]}},IR3_Q[`Immediate]}),
		.IN3	(DAddr),
		.Y	(TargetMux_Y)
	);

newmux3_5 #(5, 1, "AUTO")

	DestinationMux (
		.S0	(EXControl_DestinationMuxSelect[0]),
		.S1	(EXControl_DestinationMuxSelect[1]),
		.IN0	(IR3_Q[`RT]),
		.IN1	(IR3_Q[`RD]),
		.IN2	(5'b11111),
		.Y	(DestinationReg_D)
	);

//addition
always @(*)
begin
if (IR3_Q[`OP] == `SW)
begin
SourceMux_Y1 = TargetMux_IN1;
end
else
begin
SourceMux_Y1 = SourceMux_Y;
end
end

//addition
always @(*)
begin
if (IR3_Q[`OP] == `BEQZ)
begin
if (SourceMux_Y == 1'b0)
begin
PCFEED1 = TargetMux_Y;
PCFEEDEN1 = 1'b1;
end
else
begin
PCFEED1 = 0;
PCFEEDEN1 = 1'b0;
end
end
else
begin  
PCFEED1 = 0;
PCFEEDEN1 = 1'b0;
end
end

dff_cq #(32, 1, "AUTO")	

	PCF1 (
		.CLK	(PHI1),
		.CLR	(MRST),
		.D	(PCFEED1),
		.Q	(PCFEED),
		.QBAR	()
	);
dff_cq #(1, 1, "AUTO")	

	PCFE1 (
		.CLK	(PHI1),
		.CLR	(MRST),
		.D	(PCFEEDEN1),
		.Q	(PCFEEDEN),
		.QBAR	()
	);




newmux2 #(32, 1, "AUTO")

	DataWriteMux (
		.S0	(DataWriteMux_S0),
		.IN0	(SourceMux_Y1),
		.IN1	(TargetMux_Y),
		.Y	(DataWriteReg_D)
	);

alu #(32, 1, "AUTO")

	ALU (
		.C0	(EXControl_ALUSelect[0]),
		.A	(SourceMux_Y),
		.B	(TargetMux_Y),
		.S0	(EXControl_ALUSelect[2]),
		.S1	(EXControl_ALUSelect[3]),
		.S2	(EXControl_ALUSelect[4]),
		.S3	(EXControl_ALUSelect[5]),
		.M	(EXControl_ALUSelect[1]),
		.F	(ALU_F),
		.COUT	()
	);

shifter 
        Shifter (
                .IN0    (SourceMux_Y),
                .S      (ShiftLeft_S),
                .S2     (EXControl_ALUorShiftMuxSelect),
                .Y      (Shift_Y) 
        );

newmux2 #(32, 1, "AUTO")

	ALUorShiftMux (
		.S0	(|EXControl_ALUorShiftMuxSelect),
		.IN0	(ALU_F),
		.IN1	(Shift_Y),
		.Y	(ALUorShiftMux_Y)
	);

zero_compare #(1, "AUTO")

	Compare2 (
		.A				(ALU_F),
		.A_lessthan_zero		(CompareMux1_IN0),
		.A_lessthan_equal_zero		(CompareMux1_IN1),
		.A_greaterthan_equal_zero	(CompareMux1_IN2),
		.A_greaterthan_zero		(CompareMux2_IN0),
		.A_equal_zero			(CompareMux2_IN1),
		.A_not_equal_zero		(CompareMux2_IN2)
	);

newmux3_1 #(1, 1, "AUTO")

	CompareMux1 (
		.S0	(EXControl_CompareMux1Select[0]),
		.S1	(EXControl_CompareMux1Select[1]),
		.IN0	(CompareMux1_IN0),
		.IN1	(CompareMux1_IN1),
		.IN2	(CompareMux1_IN2),
		.Y	(CompareMux1_Y)
	),

	CompareMux2 (
		.S0	(EXControl_CompareMux2Select[0]),
		.S1	(EXControl_CompareMux2Select[1]),
		.IN0	(CompareMux2_IN0),
		.IN1	(CompareMux2_IN1),
		.IN2	(CompareMux2_IN2),
		.Y	(CompareMux2_Y)
	);

newmux4 #(32, 1, "AUTO")

	CompareResultMux (
		.S0	(EXControl_CompareResultMuxSelect[0]),
		.S1	(EXControl_CompareResultMuxSelect[1]),
		.IN0	({31'b0, CompareMux1_Y}),
		.IN1	({31'b0, CompareMux2_Y}),
		.IN2	(ALUorShiftMux_Y),
		.IN3	({IR3_Q[15:0], 16'b0}),
		.Y	(CompareResultMux_Y)
	);

dff_cq #(32, 1, "AUTO")

	ALUReg (
		.CLK	(PHI1),
		.CLR	(MRST),
		.D	(CompareResultMux_Y),
		.Q	(DAddr),
		.QBAR	()
	),

	DataWriteReg (
		.CLK	(PHI1),
		.CLR	(MRST),
		.D	(DataWriteReg_D),
		.Q	(DOut),
		.QBAR	()
	),

	PC4 (
		.CLK	(PHI1),
		.CLR	(MRST),
		.D	(PC4_D),
		.Q	(PC4_Q),
		.QBAR	()
	);

dff_cq #(32, 1, "AUTO")	

	IR4 (
		.CLK	(PHI1),
		.CLR	(MRST),
		.D	(IR3_Q),
		.Q	(IR4_Q),
		.QBAR	()
	);

dff_cq5 #(5, 1, "AUTO")

	DestinationReg (
		.CLK	(PHI1),
		.CLR	(MRST),
		.D	(DestinationReg_D),
		.Q	(DestinationReg_Q),
		.QBAR	()
	);

endmodule

/*************************************************************************
 * Memory (MEM) Stage of DLX Pipeline
 *************************************************************************
 */
module MEM_stage (
	PHI1, MRST,
	DIn, DAddr, IR4_Q, PC4_Q, 
	DestinationReg_Q,
	WBMux_IN0, WBMux_IN1, IR5_Q, 
	WriteDestinationReg_Q,
	DRead, DWrite
);
input PHI1, MRST;
input [`WordSize] DIn, DAddr, IR4_Q, PC4_Q;
input [4:0] DestinationReg_Q;
output [`WordSize] WBMux_IN0, WBMux_IN1, IR5_Q;
output [4:0] WriteDestinationReg_Q;
output DRead, DWrite;

MemCtrl 
	MemControl (
		.IR4			(IR4_Q),
		.DRead			(DRead),
		.DWrite			(DWrite)
	);

dff_cq #(32, 1, "AUTO")

	MemDataReg (
		.CLK	(PHI1),
		.CLR	(MRST),
		.D	(DIn),
		.Q	(WBMux_IN0),
		.QBAR	()
	),

	ALUDataReg (
		.CLK	(PHI1),
		.CLR	(MRST),
		.D	(DAddr),
		.Q	(WBMux_IN1),
		.QBAR	()
	),

	PC5 (
		.CLK	(PHI1),
		.CLR	(MRST),
		.D	(PC4_Q),
		.Q	(),
		.QBAR	()
	);

dff_cq #(32, 1, "AUTO") 

	IR5 (
		.CLK	(PHI1),
		.CLR	(MRST),
		.D	(IR4_Q),
		.Q	(IR5_Q),
		.QBAR	()
	);

dff_cq5 #(5, 1, "AUTO")

	WriteDestinationReg (
		.CLK	(PHI1),
		.CLR	(MRST),
		.D	(DestinationReg_Q),
		.Q	(WriteDestinationReg_Q),
		.QBAR	()
	);

endmodule

/*************************************************************************
 * Write Back (WB) Stage of DLX Pipeline
 *************************************************************************
 */
module WB_stage (
	WBMux_IN0, WBMux_IN1, IR5_Q,
	WBMux_Y,
	WBControl_WriteEnable
);

input [`WordSize] WBMux_IN0, WBMux_IN1, IR5_Q;
output [`WordSize] WBMux_Y;
output WBControl_WriteEnable;

wire WBMux_S0;

WBCtrl 
	WBControl (
		.IR5		(IR5_Q),
		.WBMuxSelect	(WBMux_S0),
		.WriteEnable	(WBControl_WriteEnable)
	);

newmux2 #(32, 1, "AUTO")
	WBMux (
		.S0	(WBMux_S0),
		.IN0	(WBMux_IN0),
		.IN1	(WBMux_IN1),
		.Y	(WBMux_Y)
	);

endmodule

//------------------------------------------------------------
// Copyright 1992, 1993 Cascade Design Automation Corporation.
//------------------------------------------------------------
module adder_generic(a,b,cin,cout,ovf,y);
  parameter n = 32;
  input [(n - 1):0] a;
  input [(n - 1):0] b;
  input  cin;
  output  cout;
  output  ovf;
  output [(n - 1):0] y;
  reg  cout;
  reg  ovf;
  reg [(n - 1):0] y;
  reg [n:0] temp;
  always
    @(a or b or cin)
      begin
      temp = ((cin + {1'b0,a}) + b);
      cout = temp[n];
      y = temp[(n - 1):0];
      ovf = (((a[(n - 1)] & b[(n - 1)]) & ( ~ temp[(n - 1)])) | ((( ~ a[(n - 1)]) & ( ~ b[(n - 1)])) & temp[(n - 1)]));
      end
endmodule
//------------------------------------------------------------
// Copyright 1992, 1993 Cascade Design Automation Corporation.
//------------------------------------------------------------
module addhsv(A,B,CIN,COUT,OVF,SUM);
  parameter N = 32;
  parameter DPFLAG = 1;
  parameter GROUP = "dpath1";
  parameter BUFFER_SIZE = "DEFAULT";
  parameter
        d_COUT_r = 1,
        d_COUT_f = 1,
        d_OVF_r = 1,
        d_OVF_f = 1,
        d_SUM = 1;
  input [(N - 1):0] A;
  input [(N - 1):0] B;
  input  CIN;
  output  COUT;
  output  OVF;
  output [(N - 1):0] SUM;
  wire  COUT_temp;
  wire  OVF_temp;
  wire [(N - 1):0] SUM_temp;
  assign #(d_COUT_r,d_COUT_f) COUT = COUT_temp;
  assign #(d_OVF_r,d_OVF_f) OVF = OVF_temp;
  assign #(d_SUM) SUM = SUM_temp;
  adder_generic #(N) inst1 (A,B,CIN,COUT_temp,OVF_temp,SUM_temp);
endmodule
//------------------------------------------------------------
// Copyright 1992, 1993 Cascade Design Automation Corporation.
//------------------------------------------------------------
module alu(A,B,C0,M,S0,S1,S2,S3,COUT,F);
  parameter N = 32;
  parameter FAST = 0;
  parameter DPFLAG = 1;
  parameter GROUP = "dpath1";
  parameter BUFFER_SIZE = "DEFAULT";
  parameter
        d_COUT_r = 1,
        d_COUT_f = 1,
        d_F = 1;
  input [(N - 1):0] A;
  input [(N - 1):0] B;
  input  C0;
  input  M;
  input  S0;
  input  S1;
  input  S2;
  input  S3;
  output  COUT;
  output [(N - 1):0] F;
  wire [(N - 1):0] A_temp;
  wire [(N - 1):0] B_temp;
  wire  COUT_temp;
  wire [(N - 1):0] F_temp;
  reg [3:0] s;
  wire  overflow;
  assign A_temp = A|A;
  assign B_temp = B|B;
  assign #(d_COUT_r,d_COUT_f) COUT = COUT_temp;
  assign #(d_F) F = F_temp;
  /*
  initial
    begin
    if((DPFLAG == 0))
      $display("(WARNING) The instance %m of type alu can't be implemented as a standard cell.");
    end
  */
  always
    @(S0 or S1 or S2 or S3)
      begin
      s[3] = S3;
      s[2] = S2;
      s[1] = S1;
      s[0] = S0;
      end
  alu_generic #(N) inst1 (A_temp,B_temp,C0,M,s,COUT_temp,F_temp,overflow);
endmodule
//------------------------------------------------------------
// Copyright 1992, 1993 Cascade Design Automation Corporation.
//------------------------------------------------------------
module alu_generic(a,b,cin,m,s,cout,out,overflow);
  parameter n = 32;
  input [(n - 1):0] a;
  input [(n - 1):0] b;
  input  cin;
  input  m;
  input [3:0] s;
  output  cout;
  output [(n - 1):0] out;
  output  overflow;
  reg  cout;
  reg [(n - 1):0] out;
  reg  overflow;
  reg [(n - 1):0] logic;
  reg [(n - 1):0] pr;
  reg [(n - 1):0] pr1;
  reg [n:0] arith;
  reg [n:0] aa;
  reg  cinbar;
  always
    @(a or b or cin or s or m)
      begin
      overflow = 1'b0;
      cinbar = ( ~ cin);
      if((s == 4'd0))
        begin
        logic = ( ~ a);
        aa = ( ~ 128'b0);
        aa[n] = 1'b0;
        arith = ({1'b0,a} + aa);
        if((cin == 1'b1))
          arith = (arith + 1'b1);
        if(((1'b0 == arith[(n - 1)]) && (a[(n - 1)] == 1'b1)))
          overflow = 1'b1;
        end
      else      if((s == 4'd1))
        begin
        logic = ( ~ (a & b));
        pr = (a & b);
        aa = ( ~ 128'b0);
        aa[n] = 1'b0;
        arith = ({1'b0,pr} + aa);
        if((cin == 1'b1))
          arith = (arith + 1'b1);
        if(((arith[(n - 1)] == 1'b0) && (pr[(n - 1)] == 1'b1)))
          overflow = 1'b1;
        end
      else      if((s == 4'd2))
        begin
        logic = (( ~ a) | b);
        pr = ( ~ logic);
        aa = ( ~ 128'b0);
        aa[n] = 1'b0;
        arith = ({1'b0,pr} + aa);
        if((cin == 1'b1))
          arith = (arith + 1'b1);
        if(((arith[(n - 1)] == 1'b0) && (pr[(n - 1)] == 1'b1)))
          overflow = 1'b1;
        end
      else      if((s == 4'd3))
        begin
        logic = ( ~ 128'b0);
        arith = ({1'b0,logic} + cin);
        end
      else      if((s == 4'd4))
        begin
        logic = ( ~ (a | b));
        pr = (a | ( ~ b));
        arith = (a + ({1'b0,pr} + cin));
        //if(((1'b0 == (pr[(n - 1)] ^ a[(n - 1)])) && (pr[(n - 1)] !== arith[(n - 1)])))
        if(((1'b0 == (pr[(n - 1)] ^ a[(n - 1)])) && (pr[(n - 1)] != arith[(n - 1)])))
          overflow = 1'b1;
        end
      else      if((s == 4'd5))
        begin
        logic = ( ~ b);
        pr = (a & b);
        pr1 = (a | ( ~ b));
        arith = (pr + ({1'b0,pr1} + cin));
        //if(((1'b0 == (pr[(n - 1)] ^ pr1[(n - 1)])) && (pr[(n - 1)] !== arith[(n - 1)])))
        if(((1'b0 == (pr[(n - 1)] ^ pr1[(n - 1)])) && (pr[(n - 1)] != arith[(n - 1)])))
          overflow = 1'b1;
        end
      else      if((s == 4'd6))
        begin
        logic = ( ~ (a ^ b));
        pr = (( ~ (b + cinbar)) + 1'b1);
        arith = ({1'b0,a} + pr);
        //if((((a[(n - 1)] ^ b[(n - 1)]) == 1'b1) && (a[(n - 1)] !== arith[(n - 1)])))
        if((((a[(n - 1)] ^ b[(n - 1)]) == 1'b1) && (a[(n - 1)] != arith[(n - 1)])))
          overflow = 1'b1;
        end
      else      if((s == 4'd7))
        begin
        logic = (a | ( ~ b));
        arith = ({1'b0,logic} + cin);
        if(((logic[(n - 1)] == 1'b0) && (arith[(n - 1)] == 1'b1)))
          overflow = 1'b1;
        end
      else      if((s == 4'd8))
        begin
        logic = (( ~ a) & b);
        pr = (a | b);
        arith = (a + ({1'b0,pr} + cin));
        //if(((1'b0 == (pr[(n - 1)] ^ a[(n - 1)])) && (pr[(n - 1)] !== arith[(n - 1)])))
        if(((1'b0 == (pr[(n - 1)] ^ a[(n - 1)])) && (pr[(n - 1)] != arith[(n - 1)])))
          overflow = 1'b1;
        end
      else      if((s == 4'd9))
        begin
        logic = (a ^ b);
        arith = (a + ({1'b0,b} + cin));
        //if(((1'b0 == (a[(n - 1)] ^ b[(n - 1)])) && (a[(n - 1)] !== arith[(n - 1)])))
        if(((1'b0 == (a[(n - 1)] ^ b[(n - 1)])) && (a[(n - 1)] != arith[(n - 1)])))
          overflow = 1'b1;
        end
      else      if((s == 4'd10))
        begin
        logic = b;
        pr = (a & ( ~ b));
        pr1 = (a | b);
        arith = (pr + ({1'b0,pr1} + cin));
        //if(((1'b0 == (pr[(n - 1)] ^ b[(n - 1)])) && (pr[(n - 1)] !== arith[(n - 1)])))
        if(((1'b0 == (pr[(n - 1)] ^ b[(n - 1)])) && (pr[(n - 1)] != arith[(n - 1)])))
          overflow = 1'b1;
        end
      else      if((s == 4'd11))
        begin
        logic = (a | b);
        arith = ({1'b0,logic} + cin);
        if(((logic[(n - 1)] == 1'b0) && (arith[(n - 1)] == 1'b1)))
          overflow = 1'b1;
        end
      else      if((s == 4'd12))
        begin
        logic = 128'b0;
        arith = (a + ({1'b0,a} + cin));
        //if((a[(n - 1)] !== arith[(n - 1)]))
        if((a[(n - 1)] != arith[(n - 1)]))
          overflow = 1'b1;
        end
      else      if((s == 4'd13))
        begin
        logic = (a & ( ~ b));
        pr = (a & b);
        arith = (pr + ({1'b0,a} + cin));
        //if(((1'b0 == (pr[(n - 1)] ^ a[(n - 1)])) && (pr[(n - 1)] !== arith[(n - 1)])))
        if(((1'b0 == (pr[(n - 1)] ^ a[(n - 1)])) && (pr[(n - 1)] != arith[(n - 1)])))
          overflow = 1'b1;
        end
      else      if((s == 4'd14))
        begin
        logic = (a & b);
        pr = (a & ( ~ b));
        arith = (pr + ({1'b0,a} + cin));
        //if(((1'b0 == (pr[(n - 1)] ^ a[(n - 1)])) && (pr[(n - 1)] !== arith[(n - 1)])))
        if(((1'b0 == (pr[(n - 1)] ^ a[(n - 1)])) && (pr[(n - 1)] != arith[(n - 1)])))
          overflow = 1'b1;
        end
      else      if((s == 4'd15))
        begin
        logic = a;
        arith = ({1'b0,a} + cin);
        if(((logic[(n - 1)] == 1'b0) && (arith[(n - 1)] == 1'b1)))
          overflow = 1'b1;
        end
      else
        begin
        logic = 128'bX;
        arith = 128'bX;
        end
      if((m == 1'b0))
        begin
        cout = 1'b0;
        out = logic;
        overflow = 1'b0;
        end
      else      if((m == 1'b1))
        begin
        cout = arith[n];
        out = arith[(n - 1):0];
        //if((arith[(n - 1)] === 1'bx))
        if((arith[(n - 1)] == 1'bx))
          begin
          overflow = 1'bx;
          cout = 1'bx;
          end
        //else        if(( ! ((( & out) === 1'b0) || (( | out) === 1'b1))))
        else        if(( ! ((( & out) == 1'b0) || (( | out) == 1'b1))))
          begin
          overflow = 1'bx;
          cout = 1'bx;
          end
        end
      else
        begin
        cout = 1'bX;
        out = 128'bX;
        end
      end
endmodule
//------------------------------------------------------------
// Copyright 1992, 1993 Cascade Design Automation Corporation.
//------------------------------------------------------------
module buff(IN0,Y);
  parameter N = 32;
  parameter DPFLAG = 1;
  parameter GROUP = "dpath1";
  parameter BUFFER_SIZE = "DEFAULT";
  parameter
        d_Y = 1;
  input [(N - 1):0] IN0;
  output [(N - 1):0] Y;
  wire [(N - 1):0] IN0_temp;
  reg [(N - 1):0] Y_temp;
  assign IN0_temp = IN0|IN0;
  assign #(d_Y) Y = Y_temp;
  always
    @(IN0_temp)
      Y_temp = IN0_temp;
endmodule
//------------------------------------------------------------
// Copyright 1992, 1993 Cascade Design Automation Corporation.
//------------------------------------------------------------
module dff_cq(CLK,CLR,D,Q,QBAR);
  parameter N = 32;
  parameter DPFLAG = 1;
  parameter GROUP = "dpath1";
  parameter BUFFER_SIZE = "DEFAULT";
  parameter
        d_Q = 1,
        d_QBAR = 1;
  input  CLK;
  input  CLR;
  input [(N - 1):0] D;
  output [(N - 1):0] Q;
  output [(N - 1):0] QBAR;
  wire [(N - 1):0] D_temp;
  wire [(N - 1):0] Q_temp;
  reg [(N - 1):0] QBAR_temp;
  supply0  GND;
  supply1  VDD;
  assign D_temp = D|D;
  assign #(d_Q) Q = Q_temp;
  assign #(d_QBAR) QBAR = QBAR_temp;
  always
    @(Q_temp)
      QBAR_temp = ( ~ Q_temp);
  dff_generic #(N) inst1 (CLK,CLR,D_temp,GND,VDD,VDD,GND,Q_temp);
  wire [127:0] D_tcheck = D;
  specify
    specparam
      t_hold_D = 0,
      t_setup_D = 0,
      t_width_CLK = 0,
      t_width_CLR = 0;
    $hold(posedge CLK , D_tcheck , t_hold_D);
    $setup(D_tcheck , posedge CLK , t_setup_D);
    $width(posedge CLK , t_width_CLK);
    $width(negedge CLR , t_width_CLR);
  endspecify
endmodule


//------------------------------------------------------------
// Copyright 1992, 1993 Cascade Design Automation Corporation.
//------------------------------------------------------------
module dff_cq5(CLK,CLR,D,Q,QBAR);
  parameter N = 5;
  parameter DPFLAG = 1;
  parameter GROUP = "dpath1";
  parameter BUFFER_SIZE = "DEFAULT";
  parameter
        d_Q = 1,
        d_QBAR = 1;
  input  CLK;
  input  CLR;
  input [(N - 1):0] D;
  output [(N - 1):0] Q;
  output [(N - 1):0] QBAR;
  wire [(N - 1):0] D_temp;
  wire [(N - 1):0] Q_temp;
  reg [(N - 1):0] QBAR_temp;
  supply0  GND;
  supply1  VDD;
  assign D_temp = D|D;
  assign #(d_Q) Q = Q_temp;
  assign #(d_QBAR) QBAR = QBAR_temp;
  always
    @(Q_temp)
      QBAR_temp = ( ~ Q_temp);
  dff_generic #(N) inst1 (CLK,CLR,D_temp,GND,VDD,VDD,GND,Q_temp);
  wire [127:0] D_tcheck = D;
  specify
    specparam
      t_hold_D = 0,
      t_setup_D = 0,
      t_width_CLK = 0,
      t_width_CLR = 0;
    $hold(posedge CLK , D_tcheck , t_hold_D);
    $setup(D_tcheck , posedge CLK , t_setup_D);
    $width(posedge CLK , t_width_CLK);
    $width(negedge CLR , t_width_CLR);
  endspecify
endmodule
//------------------------------------------------------------
// Copyright 1992, 1993 Cascade Design Automation Corporation.
//------------------------------------------------------------
module dff_generic(CLK,CLR,D,HOLD,PRE,SCANIN,TEST,Q);
  parameter N = 8;
  input  CLK;
  input  CLR;
  input [(N - 1):0] D;
  input  HOLD;
  input  PRE;
  input  SCANIN;
  input  TEST;
  output [(N - 1):0] Q;
  reg [(N - 1):0] Q;
  reg [(N - 1):0] temp;
  always
    @(posedge CLK)
      begin
      if(((CLR == 1'b0) && (PRE == 1'b1)))
        begin
        Q = 128'b0;
        end
      else      if(((PRE == 1'b0) && (CLR == 1'b1)))
        begin
        Q = ( ~ 128'b0);
        end
//      else      if(((CLR !== 1'b1) || (PRE !== 1'b1)))
//        begin
//        Q = 128'bx;
//        end
//      end
//  always
//    @(posedge CLK)
//      begin
      else      if(((PRE == 1'b1) && (CLR == 1'b1)))
        begin
        if((TEST == 1'b0))
          begin
          case(HOLD)
          1'b0 :             begin
            Q = D;
            end
          1'b1 :             begin
            end
          default:
            Q = 128'bx;
          endcase
          end
        else        if((TEST == 1'b1))
          begin
          Q = (Q << 1);
          Q[0] = SCANIN;
          end
        else
          Q = 128'bx;
        end
      end
endmodule

/*************************************************************************
 * FILE:        dlx_modules.v
 * Written By:  Michael J. Kelley
 * Written On:  December 18, 1995
 * Updated By:  Michael J. Kelley
 * Updated On:  March 4, 1996
 *
 * Description:
 
 * This file contains the hardware description of the control logic 
 * for each of the 5 stages of the DLX pipeline
 *************************************************************************
 */

//`include "/l/users/mkelley/DLX/verilog/dlx.defines"
//`include "./dlx.defines"
//*************************************************************************
//ADD THE IFCtrl AND IDCtrl MODULES HERE..............

module IFCtrl (

        IR2,                          // Instruction that is being decoded in Stage II
        Equal,                        // Result from the equal comparator in Stage II
        MRST,                         // Reset signal for CPU
        PCMuxSelect,                  // Select Signals for the PCMux in Stage I 
        PCVector                      // Exception Vectors
);

/*************************************************************************
 * Parameter Declarations
 *************************************************************************
 */

input  [`WordSize]     IR2;
input                  Equal;
input                  MRST;
output [1:0]           PCMuxSelect;
output [`WordSize]     PCVector;

reg    [1:0]           PCMuxSelect;
reg                    ifBranch;

always @(IR2 or Equal or MRST)
begin
	   PCMuxSelect <= 2'b00;
       casex({ IR2[`OP], IR2[`OPx], Equal, MRST})
             {       `J, 6'bxxxxxx,  1'bx, 1'b1}: PCMuxSelect <= 2'b01;
             {     `JAL, 6'bxxxxxx,  1'bx, 1'b1}: PCMuxSelect <= 2'b01;
             {    `BEQZ, 6'bxxxxxx,  1'b1, 1'b1}: PCMuxSelect <= 2'b01;
             {    `BNEZ, 6'bxxxxxx,  1'b0, 1'b1}: PCMuxSelect <= 2'b01;
             {     `RFE, 6'bxxxxxx,  1'bx, 1'bx}: PCMuxSelect <= 2'b10;
             {    `TRAP, 6'bxxxxxx,  1'bx, 1'bx}: PCMuxSelect <= 2'b10;
             {      `JR, 6'bxxxxxx,  1'bx, 1'b1}: PCMuxSelect <= 2'b11;
             {    `JALR, 6'bxxxxxx,  1'bx, 1'b1}: PCMuxSelect <= 2'b11;
             {6'bxxxxxx,    `TRAP2,  1'bx, 1'bx}: PCMuxSelect <= 2'b10;
             {6'bxxxxxx, 6'bxxxxxx,  1'bx, 1'b0}: PCMuxSelect <= 2'b10;
                                         default: PCMuxSelect <= 2'b00;                            
       endcase                   
end

assign PCVector[`WordSize] = 32'h00000000;

endmodule


module IDCtrl (
        IR2,                           // Instruction that is being decoded in Stage II
        PCAddMuxSelect                 // Select Signals for the PCAddMux in Stage II
);

/*************************************************************************
 * Parameter Declarations
 *************************************************************************
 */

input  [`WordSize]      IR2;
output [1:0]            PCAddMuxSelect;

reg    [1:0]            PCAddMuxSelect;

always @(IR2)
begin
	   PCAddMuxSelect <= 2'b00;
       case(IR2[`OP])
           `BEQZ     : PCAddMuxSelect <= 2'b00;
           `BNEZ     : PCAddMuxSelect <= 2'b00;
              `J     : PCAddMuxSelect <= 2'b01;
            `JAL     : PCAddMuxSelect <= 2'b01;
             `JR     : PCAddMuxSelect <= 2'b10;
           `JALR     : PCAddMuxSelect <= 2'b10;
		   default   : PCAddMuxSelect <= 2'b00;
       endcase
end

endmodule


//**********************************************************************
					
//**********************************************************************
module EXCtrl (
	IR3,				// Instruction that is being decoded in stage II
	IR4,
	IR5,
	ShiftAmount,
 	DestinationMuxSelect,
	DataWriteMuxSelect,
	ALUSelect,
	ShiftSelect,
	ALUorShiftMuxSelect,
	SourceMuxSelect,
	TargetMuxSelect,
	CompareMux1Select,
	CompareMux2Select,
	CompareResultMuxSelect
);
					
/*************************************************************************
 * Parameter Declarations
 *************************************************************************
 */
					
input  [`WordSize]	IR3;	
input  [`WordSize]	IR4;
input  [`WordSize]	IR5;
input  [`WordSize]	ShiftAmount;
output [1:0]			DestinationMuxSelect;
output					DataWriteMuxSelect;
output [5:0]			ALUSelect;
output [4:0]			ShiftSelect;
output [1:0]			ALUorShiftMuxSelect;
output [1:0]			SourceMuxSelect;
output [1:0]			TargetMuxSelect;
output [1:0]			CompareMux1Select;
output [1:0]			CompareMux2Select;
output [1:0]			CompareResultMuxSelect;	

reg    [1:0]		DestinationMuxSelect;
reg					DataWriteMuxSelect;
reg    [5:0]		ALUSelect;
reg    [4:0]		ShiftSelect;
reg    [1:0]		ALUorShiftMuxSelect;
reg    [1:0]		SourceMuxSelect;
reg    [1:0]		TargetMuxSelect;
reg    [1:0]		CompareMux1Select;
reg    [1:0]		CompareMux2Select;
reg    [1:0]		CompareResultMuxSelect;

reg    [4:0]		SourceReg;
reg    [4:0]		TargetReg;
reg    [4:0]		IR4WriteReg;
reg    [4:0]		IR5WriteReg;
reg    [1:0]		Immediate;

always @(IR3[`OP] or IR3[`OPx] or IR3[`RS] or IR3[`RT] or ShiftAmount[4:0])
begin
	casex({IR3[`OP], IR3[`OPx]})
		{`SPECIAL, `ADD}:	
		begin
			ALUSelect = 6'b100110;
			ShiftSelect = `DC5;
			ALUorShiftMuxSelect = 2'b00;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = 2'b01;
			SourceReg = IR3[`RS];
			TargetReg = IR3[`RT];
			CompareMux1Select = `DC2;
			CompareMux2Select = `DC2;
			CompareResultMuxSelect = 2'b10;
			Immediate = 2'b01;
		end
		{`SPECIAL, `ADDU}:
		begin
			ALUSelect = 6'b100110;
			ShiftSelect = `DC5;
			ALUorShiftMuxSelect = 2'b00;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = 2'b01;
			SourceReg = IR3[`RS];
			TargetReg = IR3[`RT];
			CompareMux1Select = `DC2;
			CompareMux2Select = `DC2;
			CompareResultMuxSelect = 2'b10;
			Immediate = 2'b01;
		end
		{`SPECIAL, `SUB}:
		begin
			ALUSelect = 6'b011011;
			ShiftSelect = `DC5;
			ALUorShiftMuxSelect = 2'b00;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = 2'b01;
			SourceReg = IR3[`RS];
			TargetReg = IR3[`RT];
			CompareMux1Select = `DC2;
			CompareMux2Select = `DC2;
			CompareResultMuxSelect = 2'b10;
			Immediate = 2'b01;
		end
		{`SPECIAL, `SUBU}:
		begin
			ALUSelect = 6'b011011;
			ShiftSelect = `DC5;
			ALUorShiftMuxSelect = 2'b00;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = 2'b01;
			SourceReg = IR3[`RS];
			TargetReg = IR3[`RT];
			CompareMux1Select = `DC2;
			CompareMux2Select = `DC2;
			CompareResultMuxSelect = 2'b10;
			Immediate = 2'b01;
		end
		{`SPECIAL, `AND}:
		begin
			ALUSelect = 6'b111000;
			ShiftSelect = `DC5;
			ALUorShiftMuxSelect = 2'b00;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = 2'b01;
			SourceReg = IR3[`RS];
			TargetReg = IR3[`RT];
			CompareMux1Select = `DC2;
			CompareMux2Select = `DC2;
			CompareResultMuxSelect = 2'b10;
			Immediate = 2'b01;
		end
		{`SPECIAL, `OR}:
		begin
			ALUSelect = 6'b101100;
			ShiftSelect = `DC5;
			ALUorShiftMuxSelect = 2'b00;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = 2'b01;
			SourceReg = IR3[`RS];
			TargetReg = IR3[`RT];
			CompareMux1Select = `DC2;
			CompareMux2Select = `DC2;
			CompareResultMuxSelect = 2'b10;
			Immediate = 2'b01;
		end
		{`SPECIAL, `XOR}:
		begin
			ALUSelect = 6'b100100;
			ShiftSelect = `DC5;
			ALUorShiftMuxSelect = 2'b00;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = 2'b01;
			SourceReg = IR3[`RS];
			TargetReg = IR3[`RT];
			CompareMux1Select = `DC2;
			CompareMux2Select = `DC2;
			CompareResultMuxSelect = 2'b10;
			Immediate = 2'b01;
		end
		{`SPECIAL, `SLL}:
		begin
			ALUSelect = `DC6;
			ShiftSelect = ShiftAmount[4:0];
			ALUorShiftMuxSelect = 2'b01;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = 2'b01;
			SourceReg = IR3[`RS];
			TargetReg = IR3[`RT];
			CompareMux1Select = `DC2;
			CompareMux2Select = `DC2;
			CompareResultMuxSelect = 2'b10;
			Immediate = 2'b01;
		end
		{`SPECIAL, `SRL}:
		begin
			ALUSelect = `DC6;
			ShiftSelect = ShiftAmount[4:0];
			ALUorShiftMuxSelect = 2'b10;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = 2'b01;
			SourceReg = IR3[`RS];
			TargetReg = IR3[`RT];
			CompareMux1Select = `DC2;
			CompareMux2Select = `DC2;
			CompareResultMuxSelect = 2'b10;
			Immediate = 2'b01;
		end
		{`SPECIAL, `SRA}: 
		begin
			ALUSelect = `DC6;
			ShiftSelect = ShiftAmount[4:0];
			ALUorShiftMuxSelect = 2'b11;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = 2'b01;
			SourceReg = IR3[`RS];
			TargetReg = IR3[`RT];
			CompareMux1Select = `DC2;
			CompareMux2Select = `DC2;
			CompareResultMuxSelect = 2'b10;
			Immediate = 2'b01;
		end
		{`SPECIAL, `TRAP}:
		begin
			ALUSelect = `DC6;
			ShiftSelect = `DC5;
			ALUorShiftMuxSelect = `DC2;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = `DC2;
			SourceReg = `R0;
			TargetReg = `R0;
			CompareMux1Select = `DC2;
			CompareMux2Select = `DC2;
			CompareResultMuxSelect = 2'b10;
			Immediate = 2'b01;
		end
		{`SPECIAL, `SEQ}:
		begin
			ALUSelect = 6'b011011;
			ShiftSelect = `DC5;
			ALUorShiftMuxSelect = 2'b00;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = 2'b01;
			SourceReg = IR3[`RS];
			TargetReg = IR3[`RT];
			CompareMux1Select = `DC2;
			CompareMux2Select = 2'b01;
			CompareResultMuxSelect = 2'b01;
			Immediate = 2'b01;
		end
		{`SPECIAL, `SNE}:
		begin
			ALUSelect = 6'b011011;
			ShiftSelect = `DC5;
			ALUorShiftMuxSelect = 2'b00;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = 2'b01;
			SourceReg = IR3[`RS];
			TargetReg = IR3[`RT];
			CompareMux1Select = `DC2;
			CompareMux2Select = 2'b10;
			CompareResultMuxSelect = 2'b01;
			Immediate = 2'b01;
		end
		{`SPECIAL, `SLT}:
		begin
			ALUSelect = 6'b011011;
			ShiftSelect = `DC5;
			ALUorShiftMuxSelect = 2'b00;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = 2'b01;
			SourceReg = IR3[`RS];
			TargetReg = IR3[`RT];
			CompareMux1Select = 2'b00;
			CompareMux2Select = `DC2;
			CompareResultMuxSelect = 2'b00;
			Immediate = 2'b01;
		end
		{`SPECIAL, `SGT}:
		begin
			ALUSelect = 6'b011011;
			ShiftSelect = `DC5;
			ALUorShiftMuxSelect = 2'b00;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = 2'b01;
			SourceReg = IR3[`RS];
			TargetReg = IR3[`RT];
			CompareMux1Select = `DC2;
			CompareMux2Select = 2'b00;
			CompareResultMuxSelect = 2'b01;
			Immediate = 2'b01;
		end
		{`SPECIAL, `SLE}:
		begin
			ALUSelect = 6'b011011;
			ShiftSelect = `DC5;
			ALUorShiftMuxSelect = 2'b00;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = 2'b01;
			SourceReg = IR3[`RS];
			TargetReg = IR3[`RT];
			CompareMux1Select = 2'b01;
			CompareMux2Select = `DC2;
			CompareResultMuxSelect = 2'b00;
			Immediate = 2'b01;
		end
		{`SPECIAL, `SGE}:
		begin
			ALUSelect = 6'b011011;
			ShiftSelect = `DC5;
			ALUorShiftMuxSelect = 2'b00;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = 2'b01;
			SourceReg = IR3[`RS];
			TargetReg = IR3[`RT];
			CompareMux1Select = 2'b10;
			CompareMux2Select = `DC2;
			CompareResultMuxSelect = 2'b00;
			Immediate = 2'b01;
		end
		{`J,       `DC6}:
		begin
			ALUSelect = `DC6;
			ShiftSelect = `DC5;
			ALUorShiftMuxSelect = `DC2;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = `DC2;
			SourceReg = `R0;
			TargetReg = `R0;
			CompareMux1Select = `DC2;
			CompareMux2Select = `DC2;
			CompareResultMuxSelect = 2'b10;
			Immediate = 2'b10;
		end
		{`JAL,     `DC6}:
		begin
			ALUSelect = 6'b111100;
			ShiftSelect = `DC5;
			ALUorShiftMuxSelect = 2'b00;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = 2'b10;
			SourceReg = `R0;
			TargetReg = `R0;
			CompareMux1Select = `DC2;
			CompareMux2Select = `DC2;
			CompareResultMuxSelect = 2'b10;
			Immediate = 2'b10;
		end
		{`BEQZ,	   `DC6}:
		begin
			//ALUSelect = `DC6;
			ALUSelect = 6'b000100;
			ShiftSelect = `DC5;
			ALUorShiftMuxSelect = `DC2;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = `DC2;
			SourceReg = IR3[`RS];
			TargetReg = `R0;
			CompareMux1Select = `DC2;
			CompareMux2Select = `DC2;
			CompareResultMuxSelect = 2'b10;
			Immediate = 2'b10;
		end
		{`BNEZ,    `DC6}:
		begin
			ALUSelect = `DC6;
			ShiftSelect = `DC5;
			ALUorShiftMuxSelect = `DC2;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = `DC2;
			SourceReg = IR3[`RS];
			TargetReg = `R0;
			CompareMux1Select = `DC2;
			CompareMux2Select = `DC2;
			CompareResultMuxSelect = 2'b10;
			Immediate = 2'b10;
		end
		{`ADDI,    `DC6}:
		begin
			ALUSelect = 6'b100110;
			ShiftSelect = `DC5;
			ALUorShiftMuxSelect = 2'b00;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = 2'b00;
			SourceReg = IR3[`RS];
			TargetReg = `R0;
			CompareMux1Select = `DC2;
			CompareMux2Select = `DC2;
			CompareResultMuxSelect = 2'b10;
			Immediate = 2'b10;
		end
		{`ADDUI,   `DC6}:
		begin
			ALUSelect = 6'b100110;
			ShiftSelect = `DC5;
			ALUorShiftMuxSelect = 2'b00;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = 2'b00;
			SourceReg = IR3[`RS];
			TargetReg = `R0;
			CompareMux1Select = `DC2;
			CompareMux2Select = `DC2;
			CompareResultMuxSelect = 2'b10;
			Immediate = 2'b10;
		end
		{`SUBI,    `DC6}:
		begin
			ALUSelect = 6'b011011;
			ShiftSelect = `DC5;
			ALUorShiftMuxSelect = 2'b00;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = 2'b00;
			SourceReg = IR3[`RS];
			TargetReg = `R0;
			CompareMux1Select = `DC2;
			CompareMux2Select = `DC2;
			CompareResultMuxSelect = 2'b10;
			Immediate = 2'b10;
		end
		{`SUBUI,   `DC6}:
		begin
			ALUSelect = 6'b011011;
			ShiftSelect = `DC5;
			ALUorShiftMuxSelect = 2'b00;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = 2'b00;
			SourceReg = IR3[`RS];
			TargetReg = `R0;
			CompareMux1Select = `DC2;
			CompareMux2Select = `DC2;
			CompareResultMuxSelect = 2'b10;
			Immediate = 2'b10;
		end
		{`ANDI,    `DC6}:
		begin
			ALUSelect = 6'b111000;
			ShiftSelect = `DC5;
			ALUorShiftMuxSelect = 2'b00;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = 2'b00;
			SourceReg = IR3[`RS];
			TargetReg = `R0;
			CompareMux1Select = `DC2;
			CompareMux2Select = `DC2;
			CompareResultMuxSelect = 2'b10;
			Immediate = 2'b10;
		end
		{`ORI,     `DC6}:
		begin
			ALUSelect = 6'b101100;
			ShiftSelect = `DC5;
			ALUorShiftMuxSelect = 2'b00;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = 2'b00;
			SourceReg = IR3[`RS];
			TargetReg = `R0;
			CompareMux1Select = `DC2;
			CompareMux2Select = `DC2;
			CompareResultMuxSelect = 2'b10;
			Immediate = 2'b10;
		end
		{`XORI,    `DC6}:
		begin
			ALUSelect = 6'b100100;
			ShiftSelect = `DC5;
			ALUorShiftMuxSelect = 2'b00;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = 2'b00;
			SourceReg = IR3[`RS];
			TargetReg = `R0;
			CompareMux1Select = `DC2;
			CompareMux2Select = `DC2;
			CompareResultMuxSelect = 2'b10;
			Immediate = 2'b10;
		end
		{`LHI,     `DC6}:
		begin
			ALUSelect = `DC6;
			ShiftSelect = `DC5;
			ALUorShiftMuxSelect = `DC2;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = 2'b00;
			SourceReg = `R0;
			TargetReg = `R0;
			CompareMux1Select = `DC2;
			CompareMux2Select = `DC2;
			CompareResultMuxSelect = 2'b11;
			Immediate = 2'b10;
		end
		{`RFE,     `DC6}:
		begin
			ALUSelect = `DC6;
			ShiftSelect = `DC5;
			ALUorShiftMuxSelect = `DC2;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = `DC2;
			SourceReg = `R0;
			TargetReg = `R0;
			CompareMux1Select = `DC2;
			CompareMux2Select = `DC2;
			CompareResultMuxSelect = 2'b10;
			Immediate = 2'b10;
		end
		{`TRAP,    `DC6}:
		begin
			ALUSelect = `DC6;
			ShiftSelect = `DC5;
			ALUorShiftMuxSelect = `DC2;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = `DC2;
			SourceReg = `R0;
			TargetReg = `R0;
			CompareMux1Select = `DC2;
			CompareMux2Select = `DC2;
			CompareResultMuxSelect = 2'b10;
			Immediate = 2'b01;
		end
		{`JR,      `DC6}:
		begin
			ALUSelect = `DC6;
			ShiftSelect = `DC5;
			ALUorShiftMuxSelect = `DC2;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = `DC2;
			SourceReg = IR3[`RS];
			TargetReg = `R0;
			CompareMux1Select = `DC2;
			CompareMux2Select = `DC2;
			CompareResultMuxSelect = 2'b10;
			Immediate = 2'b01;
		end
		{`JALR,	   `DC6}:
		begin
			ALUSelect = 6'b111100;
			ShiftSelect = `DC5;
			ALUorShiftMuxSelect = 2'b00;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = 2'b10;
			SourceReg = `R0;
			TargetReg = `R0;
			CompareMux1Select = `DC2;
			CompareMux2Select = `DC2;
			CompareResultMuxSelect = 2'b10;
			Immediate = 2'b10;
		end
		{`SEQI,    `DC6}:
		begin
			ALUSelect = 6'b011011;
			ShiftSelect = `DC5;
			ALUorShiftMuxSelect = 2'b00;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = 2'b00;
			SourceReg = IR3[`RS];
			TargetReg = `R0;
			CompareMux1Select = `DC2;
			CompareMux2Select = 2'b01;
			CompareResultMuxSelect = 2'b01;
			Immediate = 2'b10;
		end
		{`SNEI,    `DC6}:
		begin
			ALUSelect = 6'b011011;
			ShiftSelect = `DC5;
			ALUorShiftMuxSelect = 2'b00;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = 2'b00;
			SourceReg = IR3[`RS];
			TargetReg = `R0;
			CompareMux1Select = `DC2;
			CompareMux2Select = 2'b10;
			CompareResultMuxSelect = 2'b01;		
			Immediate = 2'b10;
		end
		{`SLTI,    `DC6}:
		begin
			ALUSelect = 6'b011011;
			ShiftSelect = `DC5;
			ALUorShiftMuxSelect = 2'b00;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = 2'b00;
			SourceReg = IR3[`RS];
			TargetReg = `R0;
			CompareMux1Select = 2'b00;
			CompareMux2Select = `DC2;
			CompareResultMuxSelect = 2'b00;		
			Immediate = 2'b10;
		end
		{`SGTI,    `DC6}:
		begin
			ALUSelect = 6'b011011;
			ShiftSelect = `DC5;
			ALUorShiftMuxSelect = 2'b00;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = 2'b00;
			SourceReg = IR3[`RS];
			TargetReg = `R0;
			CompareMux1Select = `DC2;
			CompareMux2Select = 2'b00;
			CompareResultMuxSelect = 2'b01;
			Immediate = 2'b10;
		end
		{`SLEI,    `DC6}:
		begin
			ALUSelect = 6'b011011;
			ShiftSelect = `DC5;
			ALUorShiftMuxSelect = 2'b00;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = 2'b00;
			SourceReg = IR3[`RS];
			TargetReg = `R0;
			CompareMux1Select = 2'b01;
			CompareMux2Select = `DC2;
			CompareResultMuxSelect = 2'b00;
			Immediate = 2'b10;
		end
		{`SGEI,    `DC6}:
		begin
			ALUSelect = 6'b011011;
			ShiftSelect = `DC5;
			ALUorShiftMuxSelect = 2'b00;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = 2'b00;
			SourceReg = IR3[`RS];
			TargetReg = `R0;
			CompareMux1Select = 2'b10;
			CompareMux2Select = `DC2;
			CompareResultMuxSelect = 2'b00;
			Immediate = 2'b10;
		end
		{`SLLI,     `DC6}:
		begin
			ALUSelect = `DC6;
			ShiftSelect = ShiftAmount[4:0];
			ALUorShiftMuxSelect = 2'b01;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = 2'b00;
			SourceReg = IR3[`RS];
			TargetReg = `R0;
			CompareMux1Select = `DC2;
			CompareMux2Select = `DC2;
			CompareResultMuxSelect = 2'b10;
			Immediate = 2'b10;
		end
		{`SRLI,     `DC6}:
		begin
			ALUSelect = `DC6;
			ShiftSelect = ShiftAmount[4:0];
			ALUorShiftMuxSelect = 2'b10;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = 2'b00;
			SourceReg = IR3[`RS];
			TargetReg = `R0;
			CompareMux1Select = `DC2;
			CompareMux2Select = `DC2;
			CompareResultMuxSelect = 2'b10;
			Immediate = 2'b10;
		end
		{`SRAI,	    `DC6}:
		begin
			ALUSelect = `DC6;
			ShiftSelect = ShiftAmount[4:0];
			ALUorShiftMuxSelect = 2'b11;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = 2'b00;
			SourceReg = IR3[`RS];
			TargetReg = `R0;
			CompareMux1Select = `DC2;
			CompareMux2Select = `DC2;
			CompareResultMuxSelect = 2'b10;
			Immediate = 2'b10;
		end
		{`LB,      `DC6}:
		begin
			ALUSelect = `DC6;
			ShiftSelect = `DC5;
			ALUorShiftMuxSelect = `DC2;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = 2'b00;
			SourceReg = IR3[`RS];
			TargetReg = `R0;
			CompareMux1Select = `DC2;
			CompareMux2Select = `DC2;
			CompareResultMuxSelect = 2'b10;
			Immediate = 2'b10;
		end
		{`LH,      `DC6}:
		begin
			ALUSelect = `DC6;
			ShiftSelect = `DC5;
			ALUorShiftMuxSelect = `DC2;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = 2'b00;
			SourceReg = IR3[`RS];
			TargetReg = `R0;
			CompareMux1Select = `DC2;
			CompareMux2Select = `DC2;
			CompareResultMuxSelect = 2'b10;
			Immediate = 2'b10;
		end
		{`LW,      `DC6}:
		begin
			ALUSelect = 6'b101011; // big change `DC6
			ShiftSelect = `DC5;
			ALUorShiftMuxSelect = `DC2;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = 2'b00;
			SourceReg = IR3[`RS];
			TargetReg = `R0;
			CompareMux1Select = `DC2;
			CompareMux2Select = `DC2;
			CompareResultMuxSelect = 2'b10;
			Immediate = 2'b10;
		end
		{`LBU,     `DC6}:
		begin
			ALUSelect = `DC6;
			ShiftSelect = `DC5;
			ALUorShiftMuxSelect = `DC2;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = 2'b00;
			SourceReg = IR3[`RS];
			TargetReg = `R0;
			CompareMux1Select = `DC2;
			CompareMux2Select = `DC2;
			CompareResultMuxSelect = 2'b10;
			Immediate = 2'b10;
		end
		{`LHU,     `DC6}:
		begin
			ALUSelect = `DC6;
			ShiftSelect = `DC5;
			ALUorShiftMuxSelect = `DC2;
			DataWriteMuxSelect = `DC1;
			DestinationMuxSelect = 2'b00;
			SourceReg = IR3[`RS];
			TargetReg = `R0;
			CompareMux1Select = `DC2;
			CompareMux2Select = `DC2;
			CompareResultMuxSelect = 2'b10;
			Immediate = 2'b10;
		end
		{`SB,	   `DC6}:
		begin
			ALUSelect = `DC6;
			ShiftSelect = `DC5;
			ALUorShiftMuxSelect = `DC2;
			DataWriteMuxSelect = 1'b0;
			DestinationMuxSelect = `DC2;
			SourceReg = IR3[`RS];
			TargetReg = `R0;
			CompareMux1Select = `DC2;
			CompareMux2Select = `DC2;
			CompareResultMuxSelect = 2'b10;
			Immediate = 2'b10;
		end
		{`SH,      `DC6}:
		begin
			ALUSelect = `DC6;
			ShiftSelect = `DC5;
			ALUorShiftMuxSelect = `DC2;
			DataWriteMuxSelect = 1'b0;
			DestinationMuxSelect = `DC2;
			SourceReg = IR3[`RS];
			TargetReg = `R0;
			CompareMux1Select = `DC2;
			CompareMux2Select = `DC2;
			CompareResultMuxSelect = 2'b10;
			Immediate = 2'b10;
		end
		{`SW,      `DC6}:
		begin
			ALUSelect = 6'b100110; // big change `DC6
			ShiftSelect = `DC5;
			ALUorShiftMuxSelect = `DC2;
			DataWriteMuxSelect = 1'b0; // change from 0
			DestinationMuxSelect = `DC2;
			//DestinationMuxSelect = 2'b00;
			SourceReg = IR3[`RS];
			TargetReg = `R0;
			//TargetReg = IR3[`RT];  // another big change
			CompareMux1Select = `DC2;
			CompareMux2Select = `DC2;
			CompareResultMuxSelect = 2'b10;
			Immediate = 2'b10;
		end
		default:
		begin			
			ALUSelect = `DC6;
			ShiftSelect = `DC5;
			ALUorShiftMuxSelect = `DC2;
			DataWriteMuxSelect = 1'b1;
			DestinationMuxSelect = `DC2;
			SourceReg = IR3[`RS];
			TargetReg = IR3[`RT];
			CompareMux1Select = `DC2;
			CompareMux2Select = `DC2;
			CompareResultMuxSelect = 2'b10;
			Immediate = 2'b10;
		end
	endcase
end

always @(IR4[`OP] or IR4[`OPx] or IR4[`RD] or IR4[`RT])
begin
	casex({IR4[`OP], IR4[`OPx]})
		{`SPECIAL, `ADD}:		IR4WriteReg = IR4[`RD];
		{`SPECIAL, `ADDU}:	IR4WriteReg = IR4[`RD];	
		{`SPECIAL, `SUB}:		IR4WriteReg = IR4[`RD];
		{`SPECIAL, `SUBU}:	IR4WriteReg = IR4[`RD];
		{`SPECIAL, `AND}:		IR4WriteReg = IR4[`RD];
		{`SPECIAL, `OR}:		IR4WriteReg = IR4[`RD];
		{`SPECIAL, `XOR}:		IR4WriteReg = IR4[`RD];
		{`SPECIAL, `SLL}:		IR4WriteReg = IR4[`RD];
		{`SPECIAL, `SRL}:		IR4WriteReg = IR4[`RD];
		{`SPECIAL, `SRA}:		IR4WriteReg = IR4[`RD];
		{`SPECIAL, `SEQ}:		IR4WriteReg = IR4[`RD];
		{`SPECIAL, `SNE}:		IR4WriteReg = IR4[`RD];
		{`SPECIAL, `SLT}:		IR4WriteReg = IR4[`RD];
		{`SPECIAL, `SGT}:		IR4WriteReg = IR4[`RD];
		{`SPECIAL, `SLE}:		IR4WriteReg = IR4[`RD];
		{`SPECIAL, `SGE}:		IR4WriteReg = IR4[`RD];
		{`ADDI,    `DC6}:		IR4WriteReg = IR4[`RT];
		{`ADDUI,   `DC6}:		IR4WriteReg = IR4[`RT];
		{`SUBI,    `DC6}:		IR4WriteReg = IR4[`RT];
		{`SUBUI,   `DC6}:		IR4WriteReg = IR4[`RT];
		{`ANDI,    `DC6}:		IR4WriteReg = IR4[`RT];
		{`ORI,     `DC6}:		IR4WriteReg = IR4[`RT];
		{`XORI,    `DC6}:		IR4WriteReg = IR4[`RT];
		{`LHI,     `DC6}:		IR4WriteReg = IR4[`RT];
		{`JALR,	  `DC6}:		IR4WriteReg = IR4[`RD];
		{`SEQI,    `DC6}:		IR4WriteReg = IR4[`RT];
		{`SNEI,    `DC6}:		IR4WriteReg = IR4[`RT];
		{`SLTI,    `DC6}:		IR4WriteReg = IR4[`RT];
		{`SGTI,    `DC6}:		IR4WriteReg = IR4[`RT];
		{`SLEI,    `DC6}:		IR4WriteReg = IR4[`RT];
		{`SGEI,    `DC6}:		IR4WriteReg = IR4[`RT];
		{`SLLI,    `DC6}:		IR4WriteReg = IR4[`RT];
		{`SRLI,    `DC6}:		IR4WriteReg = IR4[`RT];
		{`SRAI,    `DC6}:		IR4WriteReg = IR4[`RT];
		{`LB,      `DC6}:		IR4WriteReg = IR4[`RT];
		{`LH,      `DC6}:		IR4WriteReg = IR4[`RT];
		{`LW,      `DC6}:		IR4WriteReg = IR4[`RT];
		{`LBU,     `DC6}:		IR4WriteReg = IR4[`RT];
		{`LHU,     `DC6}:		IR4WriteReg = IR4[`RT];
					default:		IR4WriteReg = `R0;
	endcase
end

always @(IR5[`OP] or IR5[`OPx] or IR5[`RD] or IR5[`RT])
begin
	casex({IR5[`OP], IR5[`OPx]})
		{`SPECIAL, `ADD}:		IR5WriteReg = IR5[`RD];
		{`SPECIAL, `ADDU}:	IR5WriteReg = IR5[`RD];	
		{`SPECIAL, `SUB}:		IR5WriteReg = IR5[`RD];
		{`SPECIAL, `SUBU}:	IR5WriteReg = IR5[`RD];
		{`SPECIAL, `AND}:		IR5WriteReg = IR5[`RD];
		{`SPECIAL, `OR}:		IR5WriteReg = IR5[`RD];
		{`SPECIAL, `XOR}:		IR5WriteReg = IR5[`RD];
		{`SPECIAL, `SLL}:		IR5WriteReg = IR5[`RD];
		{`SPECIAL, `SRL}:		IR5WriteReg = IR5[`RD];
		{`SPECIAL, `SRA}:		IR5WriteReg = IR5[`RD];
		{`SPECIAL, `SEQ}:		IR5WriteReg = IR5[`RD];
		{`SPECIAL, `SNE}:		IR5WriteReg = IR5[`RD];
		{`SPECIAL, `SLT}:		IR5WriteReg = IR5[`RD];
		{`SPECIAL, `SGT}:		IR5WriteReg = IR5[`RD];
		{`SPECIAL, `SLE}:		IR5WriteReg = IR5[`RD];
		{`SPECIAL, `SGE}:		IR5WriteReg = IR5[`RD];
		{`ADDI,    `DC6}:		IR5WriteReg = IR5[`RT];
		{`ADDUI,   `DC6}:		IR5WriteReg = IR5[`RT];
		{`SUBI,    `DC6}:		IR5WriteReg = IR5[`RT];
		{`SUBUI,   `DC6}:		IR5WriteReg = IR5[`RT];
		{`ANDI,    `DC6}:		IR5WriteReg = IR5[`RT];
		{`ORI,     `DC6}:		IR5WriteReg = IR5[`RT];
		{`XORI,    `DC6}:		IR5WriteReg = IR5[`RT];
		{`LHI,     `DC6}:		IR5WriteReg = IR5[`RT];
		{`JALR,	  `DC6}:		IR5WriteReg = IR5[`RD];
		{`SEQI,    `DC6}:		IR5WriteReg = IR5[`RT];
		{`SNEI,    `DC6}:		IR5WriteReg = IR5[`RT];
		{`SLTI,    `DC6}:		IR5WriteReg = IR5[`RT];
		{`SGTI,    `DC6}:		IR5WriteReg = IR5[`RT];
		{`SLEI,    `DC6}:		IR5WriteReg = IR5[`RT];
		{`SGEI,    `DC6}:		IR5WriteReg = IR5[`RT];
		{`SLLI,    `DC6}:		IR5WriteReg = IR5[`RT];
		{`SRLI,    `DC6}:		IR5WriteReg = IR5[`RT];
		{`SRAI,    `DC6}:		IR5WriteReg = IR5[`RT];
		{`LB,      `DC6}:		IR5WriteReg = IR5[`RT];
		{`LH,      `DC6}:		IR5WriteReg = IR5[`RT];
		{`LW,      `DC6}:		IR5WriteReg = IR5[`RT];
		{`LBU,     `DC6}:		IR5WriteReg = IR5[`RT];
		{`LHU,     `DC6}:		IR5WriteReg = IR5[`RT];
					default:		IR5WriteReg = `R0;
	endcase
end

always @(SourceReg or TargetReg or IR4WriteReg or IR5WriteReg or Immediate)
begin
	casex({SourceReg, IR4WriteReg, IR5WriteReg})
		{`R0,			`DC5,			`DC5}:	SourceMuxSelect = 2'b11;
		{SourceReg,	SourceReg,	`DC5}:	SourceMuxSelect = 2'b10;
		{SourceReg,	`DC5,	 SourceReg}:   SourceMuxSelect = 2'b00;
									 default:   SourceMuxSelect = 2'b01;
	endcase

	casex({TargetReg, IR4WriteReg, IR5WriteReg})
		{`R0,			`DC5,			`DC5}:
// my additions

//if (IR3[`OP] == `SW)
//begin
//TargetMuxSelect = 2'b01;
//end
//else
//begin


	TargetMuxSelect = Immediate;
//end
		{TargetReg,	TargetReg,	`DC5}:   TargetMuxSelect = 2'b11;
		{TargetReg,	`DC5,	 TargetReg}:   TargetMuxSelect = 2'b00;
									 default:   TargetMuxSelect = Immediate;
	endcase
end

endmodule

module MemCtrl (
	IR4,
	DRead,
	DWrite
);
					
/*************************************************************************
 * Parameter Declarations
 *************************************************************************
 */
					
input  [`WordSize]	IR4;
output					DRead;
output					DWrite;

reg			DRead;
reg			DWrite;

always @(IR4[`OP] or IR4[`OPx])
begin
	casex({IR4[`OP], IR4[`OPx]})
		{`LB, `DC6}:
		begin
			DRead = `LogicOne;
			DWrite = `LogicZero;
		end
		{`LBU, `DC6}:
		begin
			DRead = `LogicOne;
			DWrite = `LogicZero;
		end
		{`LH, `DC6}:
		begin
			DRead = `LogicOne;
			DWrite = `LogicZero;
		end
		{`LHU, `DC6}:
		begin
			DRead = `LogicOne;
			DWrite = `LogicZero;
		end
		{`LW,  `DC6}:
		begin
			DRead = `LogicOne;
			DWrite = `LogicZero;
		end
		{`SB,  `DC6}:
		begin
			DRead = `LogicZero;
			DWrite = `LogicOne;
		end
		{`SH,  `DC6}:
		begin
			DRead = `LogicZero;
			DWrite = `LogicOne;
		end
		{`SW,  `DC6}:
		begin
			DRead = `LogicZero;
			DWrite = `LogicOne;
		end
		default:
		begin
			DRead = `LogicZero;
			DWrite = `LogicZero;
		end
	endcase
end

endmodule

module WBCtrl (
	IR5,
	WBMuxSelect,
	WriteEnable
);
					
/*************************************************************************
 * Parameter Declarations
 *************************************************************************
 */
					
input  [`WordSize]	IR5;
output			WBMuxSelect;
output			WriteEnable;

reg			WBMuxSelect;
reg			WriteEnable;

always @(IR5[`OP] or IR5[`OPx])
begin
	casex({IR5[`OP], IR5[`OPx]})
		{`LB,      `DC6}:	WBMuxSelect = 1'b0;
		{`LH,      `DC6}:	WBMuxSelect = 1'b0;
		{`LW,      `DC6}:	WBMuxSelect = 1'b0;
		{`LBU,     `DC6}:	WBMuxSelect = 1'b0;
		{`LHU,     `DC6}:	WBMuxSelect = 1'b0;
		default:		WBMuxSelect = 1'b1;
	endcase

	casex({IR5[`OP], IR5[`OPx]})
		{`SPECIAL, `ADD}:		WriteEnable = 1'b1;
		{`SPECIAL, `ADDU}:	WriteEnable = 1'b1;
		{`SPECIAL, `SUB}:		WriteEnable = 1'b1;
		{`SPECIAL, `SUBU}:	WriteEnable = 1'b1;
		{`SPECIAL, `AND}:		WriteEnable = 1'b1;
		{`SPECIAL, `OR}:		WriteEnable = 1'b1;
		{`SPECIAL, `XOR}:		WriteEnable = 1'b1;
		{`SPECIAL, `SLL}:		WriteEnable = 1'b1;
		{`SPECIAL, `SRL}:		WriteEnable = 1'b1;
		{`SPECIAL, `SRA}:		WriteEnable = 1'b1;
		{`SPECIAL, `SEQ}:		WriteEnable = 1'b1;
		{`SPECIAL, `SNE}:		WriteEnable = 1'b1;
		{`SPECIAL, `SLT}:		WriteEnable = 1'b1;
		{`SPECIAL, `SGT}:		WriteEnable = 1'b1;
		{`SPECIAL, `SLE}:		WriteEnable = 1'b1;
		{`SPECIAL, `SGE}:		WriteEnable = 1'b1;
		{`ADDI,    `DC6}:		WriteEnable = 1'b1;
		{`ADDUI,   `DC6}:		WriteEnable = 1'b1;
		{`SUBI,    `DC6}:		WriteEnable = 1'b1;
		{`SUBUI,   `DC6}:		WriteEnable = 1'b1;
		{`ANDI,    `DC6}:		WriteEnable = 1'b1;
		{`ORI,     `DC6}:		WriteEnable = 1'b1;
		{`XORI,    `DC6}:		WriteEnable = 1'b1;
		{`LHI,     `DC6}:		WriteEnable = 1'b1;
		{`JAL,	  `DC6}:		WriteEnable = 1'b1;
		{`JALR,	  `DC6}:		WriteEnable = 1'b1;
		{`SEQI,    `DC6}:		WriteEnable = 1'b1;
		{`SNEI,    `DC6}:		WriteEnable = 1'b1;
		{`SLTI,    `DC6}:		WriteEnable = 1'b1;
		{`SGTI,    `DC6}:		WriteEnable = 1'b1;
		{`SLEI,    `DC6}:		WriteEnable = 1'b1;
		{`SGEI,    `DC6}:		WriteEnable = 1'b1;
		{`SLLI,    `DC6}:		WriteEnable = 1'b1;
		{`SRLI,    `DC6}: 	WriteEnable = 1'b1;
		{`SRAI,    `DC6}:		WriteEnable = 1'b1;
		{`LB,      `DC6}:		WriteEnable = 1'b1;
		{`LH,      `DC6}:		WriteEnable = 1'b1;
		{`LW,      `DC6}:		WriteEnable = 1'b1;
		{`LBU,     `DC6}:		WriteEnable = 1'b1;
		{`LHU,     `DC6}:		WriteEnable = 1'b1;
					default:		WriteEnable = 1'b0;
	endcase
end

endmodule


//------------------------------------------------------------
// Copyright 1992, 1993 Cascade Design Automation Corporation.
//------------------------------------------------------------
module newmux2(IN0,IN1,S0,Y);
  parameter N = 32;
  parameter DPFLAG = 1;
  parameter GROUP = "dpath1";
  parameter BUFFER_SIZE = "DEFAULT";
  parameter
        d_Y = 1;
  input [(N - 1):0] IN0;
  input [(N - 1):0] IN1;
  input  S0;
  output [(N - 1):0] Y;
  wire [(N - 1):0] IN0_temp;
  wire [(N - 1):0] IN1_temp;
  reg [(N - 1):0] Y_temp;
  reg [(N - 1):0] XX;
  assign IN0_temp = IN0|IN0;
  assign IN1_temp = IN1|IN1;
  assign #(d_Y) Y = Y_temp;
  /*
  initial
    XX = 128'bx;
  */
  always
    @(IN0_temp or IN1_temp or S0)
      begin
      if((S0 == 1'b0))
        Y_temp = IN0_temp;
      else      if((S0 == 1'b1))
        Y_temp = IN1_temp;
      else
        Y_temp = (((IN0_temp ^ IN1_temp) & XX) | IN0_temp);
      end
endmodule
//------------------------------------------------------------
// Copyright 1992, 1993 Cascade Design Automation Corporation.
//------------------------------------------------------------
module newmux3(IN0,IN1,IN2,S0,S1,Y);
  parameter N = 32;
  parameter DPFLAG = 1;
  parameter GROUP = "dpath1";
  parameter BUFFER_SIZE = "DEFAULT";
  parameter
        d_Y = 1;
  input [(N - 1):0] IN0;
  input [(N - 1):0] IN1;
  input [(N - 1):0] IN2;
  input  S0;
  input  S1;
  output [(N - 1):0] Y;
  wire [(N - 1):0] IN0_temp;
  wire [(N - 1):0] IN1_temp;
  wire [(N - 1):0] IN2_temp;
  reg [(N - 1):0] Y_temp;
  reg [(N - 1):0] XX;
  assign IN0_temp = IN0|IN0;
  assign IN1_temp = IN1|IN1;
  assign IN2_temp = IN2|IN2;
  assign #(d_Y) Y = Y_temp;
  /*
  initial
    XX = 128'bx;
  */
  always
    @(IN0_temp or IN1_temp or IN2_temp or S0 or S1)
      begin
      if(((S1 == 1'b0) && (S0 == 1'b0)))
        Y_temp = IN0_temp;
      else      if(((S1 == 1'b0) && (S0 == 1'b1)))
        Y_temp = IN1_temp;
      else      if((S1 == 1'b1))
        Y_temp = IN2_temp;
      else
        Y_temp = (((((IN0_temp | IN1_temp) | IN2_temp) ^ ((IN0_temp & IN1_temp) & IN2_temp)) & XX) ^ IN0_temp);
      end
endmodule

//------------------------------------------------------------
// Copyright 1992, 1993 Cascade Design Automation Corporation.
//------------------------------------------------------------
module newmux3_1(IN0,IN1,IN2,S0,S1,Y);
  parameter N = 1;
  parameter DPFLAG = 1;
  parameter GROUP = "dpath1";
  parameter BUFFER_SIZE = "DEFAULT";
  parameter
        d_Y = 1;
  input [(N - 1):0] IN0;
  input [(N - 1):0] IN1;
  input [(N - 1):0] IN2;
  input  S0;
  input  S1;
  output [(N - 1):0] Y;
  wire [(N - 1):0] IN0_temp;
  wire [(N - 1):0] IN1_temp;
  wire [(N - 1):0] IN2_temp;
  reg [(N - 1):0] Y_temp;
  reg [(N - 1):0] XX;
  assign IN0_temp = IN0|IN0;
  assign IN1_temp = IN1|IN1;
  assign IN2_temp = IN2|IN2;
  assign #(d_Y) Y = Y_temp;
  /*
  initial
    XX = 128'bx;
  */
  always
    @(IN0_temp or IN1_temp or IN2_temp or S0 or S1)
      begin
      if(((S1 == 1'b0) && (S0 == 1'b0)))
        Y_temp = IN0_temp;
      else      if(((S1 == 1'b0) && (S0 == 1'b1)))
        Y_temp = IN1_temp;
      else      if((S1 == 1'b1))
        Y_temp = IN2_temp;
      else
        Y_temp = (((((IN0_temp | IN1_temp) | IN2_temp) ^ ((IN0_temp & IN1_temp) & IN2_temp)) & XX) ^ IN0_temp);
      end
endmodule


//------------------------------------------------------------
// Copyright 1992, 1993 Cascade Design Automation Corporation.
//------------------------------------------------------------
module newmux3_5(IN0,IN1,IN2,S0,S1,Y);
  parameter N = 5;
  parameter DPFLAG = 1;
  parameter GROUP = "dpath1";
  parameter BUFFER_SIZE = "DEFAULT";
  parameter
        d_Y = 1;
  input [(N - 1):0] IN0;
  input [(N - 1):0] IN1;
  input [(N - 1):0] IN2;
  input  S0;
  input  S1;
  output [(N - 1):0] Y;
  wire [(N - 1):0] IN0_temp;
  wire [(N - 1):0] IN1_temp;
  wire [(N - 1):0] IN2_temp;
  reg [(N - 1):0] Y_temp;
  reg [(N - 1):0] XX;
  assign IN0_temp = IN0|IN0;
  assign IN1_temp = IN1|IN1;
  assign IN2_temp = IN2|IN2;
  assign #(d_Y) Y = Y_temp;
  /*
  initial
    XX = 128'bx;
  */
  always
    @(IN0_temp or IN1_temp or IN2_temp or S0 or S1)
      begin
      if(((S1 == 1'b0) && (S0 == 1'b0)))
        Y_temp = IN0_temp;
      else      if(((S1 == 1'b0) && (S0 == 1'b1)))
        Y_temp = IN1_temp;
      else      if((S1 == 1'b1))
        Y_temp = IN2_temp;
      else
        Y_temp = (((((IN0_temp | IN1_temp) | IN2_temp) ^ ((IN0_temp & IN1_temp) & IN2_temp)) & XX) ^ IN0_temp);
      end
endmodule

//------------------------------------------------------------
// Copyright 1992, 1993 Cascade Design Automation Corporation.
//------------------------------------------------------------
module newmux4(IN0,IN1,IN2,IN3,S0,S1,Y);
  parameter N = 32;
  parameter DPFLAG = 1;
  parameter GROUP = "dpath1";
  parameter BUFFER_SIZE = "DEFAULT";
  parameter
        d_Y = 1;
  input [(N - 1):0] IN0;
  input [(N - 1):0] IN1;
  input [(N - 1):0] IN2;
  input [(N - 1):0] IN3;
  input  S0;
  input  S1;
  output [(N - 1):0] Y;
  wire [(N - 1):0] IN0_temp;
  wire [(N - 1):0] IN1_temp;
  wire [(N - 1):0] IN2_temp;
  wire [(N - 1):0] IN3_temp;
  reg [(N - 1):0] Y_temp;
  reg [(N - 1):0] XX;
  assign IN0_temp = IN0|IN0;
  assign IN1_temp = IN1|IN1;
  assign IN2_temp = IN2|IN2;
  assign IN3_temp = IN3|IN3;
  assign #(d_Y) Y = Y_temp;
  /*
  initial
    XX = 128'bx;
  */
  always
    @(IN0_temp or IN1_temp or IN2_temp or IN3_temp or S0 or S1)
      begin
      if(((S1 == 1'b0) && (S0 == 1'b0)))
        Y_temp = IN0_temp;
      else      if(((S1 == 1'b0) && (S0 == 1'b1)))
        Y_temp = IN1_temp;
      else      if(((S1 == 1'b1) && (S0 == 1'b0)))
        Y_temp = IN2_temp;
      else      if(((S1 == 1'b1) && (S0 == 1'b1)))
        Y_temp = IN3_temp;
      else
        Y_temp = ((((((IN0_temp | IN1_temp) | IN2_temp) | IN3_temp) ^ (((IN0_temp & IN1_temp) & IN2_temp) & IN3_temp)) & XX) ^ IN0_temp);
      end
endmodule

//------------------------------------------------------------
// Copyright 1992, 1993 Cascade Design Automation Corporation.
//------------------------------------------------------------
module regfile2r(IN0,R1,R2,RE1,RE2,W,WE,OUT1,OUT2);
  parameter N = 32;
  parameter WORDS = 32;
  parameter M = 5;
  parameter GROUP = "dpath1";
  parameter BUFFER_SIZE = "DEFAULT";
  parameter
        d_OUT1 = 1,
        d_OUT2 = 1;
  input [(N - 1):0] IN0;
  input [(M - 1):0] R1;
  input [(M - 1):0] R2;
  input  RE1;
  input  RE2;
  input [(M - 1):0] W;
  input  WE;
  output [(N - 1):0] OUT1;
  output [(N - 1):0] OUT2;
  reg [(N - 1):0] OUT1_temp;
  reg [(N - 1):0] OUT2_temp;
  reg  flag1;
  reg  flag2;
  reg  error_flag;
  reg [(M - 1):0] W_old;
  reg [(N - 1):0] mem_array[(WORDS - 1):0];
  integer i;


  assign #(d_OUT1) OUT1 = OUT1_temp;
  assign #(d_OUT2) OUT2 = OUT2_temp;


always @(WE or IN0 or W) 
    if (WE == 1'b1) mem_array[W] = IN0 ;

always @(RE1 or R1) 
        if (RE1 == 1'b1) OUT1_temp = mem_array[R1] ;

always @(RE2 or R2) 
        if (RE2 == 1'b1) OUT2_temp = mem_array[R2] ;

endmodule

module shifter(IN0,S,S2,Y);

  input [31:0] IN0;
  input [4:0] S;
  input [1:0] S2;
  output [31:0] Y;

  reg [31:0] Y;
  reg [31:0] mask;

  always @(IN0 or S or S2) begin

    mask = 32'hFFFFFFFF ;
    if((IN0[31] == 1) && (S2 == 2'b11)) mask = (mask >> S) ;

    case(S2)
           2'b01: Y = (IN0 << S);              // SLL, SLLI
           2'b10: Y = (IN0 >> S);              // SRL, SRLI
           2'b11: Y = ((IN0 >> S) | (~mask));  // SRA, SRAI
         default: Y = IN0 ;                    // don't care
    endcase
  end
endmodule

// File:        zero_compare
// Written By:  Michael J. Kelley
// Written On:  9/15/95
// Updated By:  Michael J. Kelley
// Updated On:  9/18/95
//
// Description:
//
// This module simply compares a 32-bit number against zero.  It will activate
// the appropriate output lines depending on the result.  The output values are
// the following:
// 	A < 0
// 	A <= 0
//	A > 0
//	A >= 0
// By testing these lines, one will be able to detect what A is with respect to
// zero.  

module zero_compare(
A, 				// 32-bit number to compare to zero
A_lessthan_zero, 		// output is one when A < 0
A_lessthan_equal_zero,		// output is one when A <= 0
A_greaterthan_equal_zero, 	// output is one when A >= 0
A_greaterthan_zero,		// output is one when A > 0
A_equal_zero,			// output is one when A == 0
A_not_equal_zero		// output is one when A != 0
);

// declaring parameters

parameter DPFLAG = 0;
parameter GROUP = "AUTO";

input [31:0] A;			
output A_lessthan_zero;			wire A_lessthan_zero;
output A_lessthan_equal_zero;		wire A_lessthan_equal_zero;
output A_greaterthan_equal_zero;	wire A_greaterthan_equal_zero;
output A_greaterthan_zero;		wire A_greaterthan_zero;
output A_equal_zero;			wire A_equal_zero;
output A_not_equal_zero;		wire A_not_equal_zero;

// A is less than zero if the most significant bit is 1.

assign A_lessthan_zero = A[31];

buff	#(1,DPFLAG,GROUP)
	buffer(.IN0(A[31]), .Y(A_lessthan_zero));

// A is less than or equal to zero if all the bits are zero or if the most
// significant bit is one.

assign A_lessthan_equal_zero = (!(A[0] | A[1] | A[2] | A[3] | A[4] | A[5] | A[6] | 
A[7] | A[8] | A[9] | A[10] | A[11] | A[12] | A[13] | A[14] | A[15] | A[16] |
A[17] | A[18] | A[19] | A[20] | A[21] | A[22] | A[23] | A[24] | A[25] | A[26] |
A[27] | A[28] | A[29] | A[30] | A[31]) | (A[31]));

// A is greater than or equal to zero whenever the most significant bit of A is
// zero.

assign A_greaterthan_equal_zero = !(A[31]);

// A is greater than zero if at least one of the bits is one (except for the most
// significant bit).

assign A_greaterthan_zero = ((A[0] | A[1] | A[2] | A[3] | A[4] | A[5] | A[6] | 
A[7] | A[8] | A[9] | A[10] | A[11] | A[12] | A[13] | A[14] | A[15] | A[16] |
A[17] | A[18] | A[19] | A[20] | A[21] | A[22] | A[23] | A[24] | A[25] | A[26] |
A[27] | A[28] | A[29] | A[30] | A[31]) & !(A[31]));

assign A_equal_zero = A_greaterthan_equal_zero && A_lessthan_equal_zero;

assign A_not_equal_zero = !A_equal_zero;

endmodule
