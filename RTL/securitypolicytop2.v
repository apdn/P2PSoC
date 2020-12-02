`include "./dlx.defines"
`timescale 1ns/1ps

module securitypolicy(
	PHI1, MASRST,                            // One-Phase clock for DLX 
	DAddr, DAddrE1, DAddrE2, DAddrE3, DAddrE4, DAddrE5, DRead, DWrite, DWriteE1, DWriteE2, DWriteE3, DWriteE4, DWriteE5,  DOut, DOutE1, DOutE2, DOutE3, DOutE4, DOutE5, DIn,  // Data Cache interface
	IAddr, IAddrE, IRead, IIn, IInE,               // Instruction Cache interface
	MRST, TCE, TMS, TDI, TDO,         // Test Controls
WSI, WRSTN, SelectWIR, ShiftWR, CaptureWR, WSO, STATE, SPCDISF, SPCDISD, SPCDISA, SPCDISS, SPCREQF, SPCREQD, SPCREQA, SPCREQS
);

input MASRST;
input PHI1;
input MRST;
input [`WordSize] DAddrE1, DOutE1, DAddrE2, DOutE2, DAddrE3, DOutE3, DAddrE4, DOutE4, DAddrE5, DOutE5;
input DWriteE1, DWriteE2, DWriteE3, DWriteE4, DWriteE5;
input [`WordSize] IAddrE, IInE; // added external //signals
output [`WordSize] DAddr, DOut, DIn;
output DRead, DWrite;
output [`WordSize]	IAddr;          // Instruction Cache read address
output					IRead;          // Instruction Cache read enable
output [`WordSize]	IIn;            // Instruction from (change) Instruction Cache
input						MRST;           // Master Reset
input						TCE;            // Test Clock Enable
input						TMS;		// Test Mode Select
input						TDI;		// Test Data In
output					TDO;		// Test Data Out

// the actual security involved signals
output reg[3:0] STATE;
output reg SPCDISF, SPCREQF, SPCDISD, SPCREQD, SPCDISA, SPCREQA, SPCDISS, SPCREQS;


// boundary scan signals
input WSI, WRSTN, SelectWIR, ShiftWR, CaptureWR;
output WSO;

/// flags to indicate freshly written values
reg F1, F2, F3, F4, F5;

//// addresses to indicate the last read address of the security info of IPs by SPC
reg [31:0] add1, add2, add3, add4, add5;


wire [`WordSize] DAddr1, DOut1, DIn1;
wire DRead1, DWrite1;

wire [`WordSize] IAddr1;
wire IRead1, TDO1;
wire [`WordSize] IIn1;

wire [`WordSize] DInE;
reg [`WordSize] DAddrE;
reg DReadE;

// as of now, DOutE, DAddrE inserted into boundary scan and on //output side DOut, DAddr (can be extended to include IIn, IAddr.)

// boundary scan extra signals

wire [`WordSize] DOutE1A, DAddrE1A; // doing it just for first IP
wire [`WordSize] DOutA, DAddrA;

wire Scan_en, Hold_en_incell, Hold_en_outcell;
wire test_din, test_dout;
wire Bypass_d, Bypass_q;
wire WIR_din, WIR_2_q, WIR_1_q, WIR_dout;

wire [126:0] CTI; // first DR, DI, SHIFT, ADDR, DOI, DOR

wire CK; 

wire DIS1, DIS2, DIS3, DIS4, REQ1, REQ2, REQ3, REQ4;
wire [3:0] state;

IcacheSP IC111 (.PHI1(PHI1), .IAddr(IAddr1), .MRST(MRST), .IIn(IIn1), .IInE(IInE), .IAddrE(IAddrE), .IWriteE(`LogicZero));

// debug try
//Icache IC1 (.PHI1(PHI1), .IAddr(IAddr1), .MRST(MRST), .IIn(IIn1), .IInE(32'b0), .IAddrE(32'b0), .IWriteE(`LogicZero));

dlx DLX11 (
.PHI1	(PHI1),
	.DIn	(DIn1),
	.IIn	(IIn1),
	.MRST	(MRST),
	.TCE	(`LogicZero),
	.TMS	(`LogicZero),
	.TDI	(`LogicZero),
	.DAddr	(DAddr1),
	.DRead	(DRead1),
	.DWrite	(DWrite1),
	.DOut	(DOut1),
	.IAddr	(IAddr1),
	.IRead	(IRead1),
	.TDO	(TDO1)
);

wire [31:0]yy;
reg [31:0] xx;
reg ww;
//assign yy = {27'b0, F5, F4, F3, F2, F1};
assign yy = {28'b0, F4, F3, F2, F1};

always @(yy)
begin

xx = 32'd1;
ww = 1'b1;

end

//reg [31:0] yy1, xx1;
//reg ww1;

//always @(posedge PHI1)
//begin
//if (MASRST == 1'b1)
//begin
//yy1 <= 32'b0;
//xx1 <= 32'b0;
//ww1 <= 1'b0;
//end
//else 


Dcache DC111 (.state(state), .DWRR(ww), .DORR(yy), .DARR(xx), .DOut(DOut1), .DOutE1(DOutE1), .DOutE2(DOutE2), .DOutE3(DOutE3), .DOutE4(DOutE4), .DOutE5(DOutE5), .DAddr(DAddr1), .DAddrE1(DAddrE1), .DAddrE2(DAddrE2), .DAddrE3(DAddrE3), .DAddrE4(DAddrE4), .DAddrE5(DAddrE5),.DRead(DRead1), .DReadE(DReadE), .DWrite(DWrite1), .DWriteE1(DWriteE1), .DWriteE2(DWriteE2), .DWriteE3(DWriteE3), .DWriteE4(DWriteE4), .DWriteE5(DWriteE5), .DIn(DIn1), .DAddrE(DAddrE), .DInE(DInE), .DIS1(DIS1),.DIS2(DIS2),.DIS3(DIS3),.DIS4(DIS4), .REQ1(REQ1),.REQ2(REQ2),.REQ3(REQ3),.REQ4(REQ4)  );

assign DOutA = DOut1;
assign DRead = DRead1;
assign DIn = DIn1;
assign DAddrA = DAddr1;
assign DWrite = DWrite1;
assign IAddr = IAddr1;
assign IIn = IIn1;
assign IRead = IRead1;
assign TDO = TDO1;

////// the security interfaces of the SPC outside what is inside the DLX and the trace buffer

//// if the address changes, that means a new write has been made by the IP to the SPC
//always @(DAddrE1, DAddrE2, DAddrE3, DAddrE4, DAddrE5)
always @(posedge PHI1)
begin

if (MASRST == 1'b1)
begin
F1 <= 1'b0;
F2 <= 1'b0;
F3 <= 1'b0;
F4 <= 1'b0;
F5 <= 1'b0;
end
//if ((DAddrE1 > add1) && (DWriteE1 == 1'b1)) // ****** will have to update if the address rolls over 
if ((DAddrE1 > add1)) // why only assign during the write condition ??? DAddr cannot be less than add
begin
F1 <= 1'b1;
end
 //else if (add1 == DAddrE1) // dont mix if and else if together
if (add1 >= DAddrE1) // this is mutually exclusive as compared to prev
begin
F1 <= 1'b0;
end

//if ((DAddrE2 > add2) && (DWriteE2 == 1'b1))
if ((DAddrE2 > add2))
begin
F2 <= 1'b1;
end
if (add2 >= DAddrE2) // this is mutually exclusive as compared to prev (greater for the initial case)
begin
F2 <= 1'b0;
end

//if ((DAddrE3 > add3) && (DWriteE3 == 1'b1))
if ((DAddrE3 > add3))
begin
F3 <= 1'b1;
end
if (add3 >= DAddrE3) // this is mutually exclusive as compared to prev
begin
F3 <= 1'b0;
end

if ((DAddrE4 > add4))
begin
F4 <= 1'b1;
end
if (add4 >= DAddrE4) // this is mutually exclusive as compared to prev
begin
F4 <= 1'b0;
end

if ((DAddrE5 > add5))
begin
F5 <= 1'b1;
end
if (add5 >= DAddrE5) // this is mutually exclusive as compared to prev
begin
F5 <= 1'b0;
end

end

///// NOW logic for add 1, 2 ,3 i.e. reading of the cntents of diff IPs by SPC 
// reset them initially

always @(posedge PHI1)
begin

if (MASRST == 1'b1)
begin
add1 <= 32'd48;
add2 <= 32'd64;
add3 <= 32'd80;
add4 <= 32'd96;
add5 <= 32'd112;
end


if (((DAddr1 >= 32'd48) && (DAddr1 < 32'd64)) && (DRead1 == 1'b1))
begin
if (add1 < 32'd63)
begin
add1 <= add1 + 32'b1;
end
else
begin
add1 <= 32'd48;
end
end

if (((DAddr1 >= 32'd64) && (DAddr1 < 32'd80)) && (DRead1 == 1'b1))
begin
if (add2 < 32'd79)
begin
add2 <= add2 + 32'b1;
end
else
begin
add2 <= 32'd64;
end
end

if (((DAddr1 >= 32'd80) && (DAddr1 < 32'd96)) && (DRead1 == 1'b1))
begin
if (add3 < 32'd95)
begin
add3 <= add3 + 32'b1;
end
else
begin
add3 <= 32'd80;
end
end

if (((DAddr1 >= 32'd96) && (DAddr1 < 32'd112)) && (DRead1 == 1'b1))
begin
if (add4 < 32'd111)
begin
add4 <= add4 + 32'b1;
end
else
begin
add4 <= 32'd96;
end
end

if (((DAddr1 >= 32'd112) && (DAddr1 < 32'd128)) && (DRead1 == 1'b1))
begin
if (add5 < 32'd127)
begin
add5 <= add5 + 32'b1;
end
else
begin
add5 <= 32'd112;
end
end

end


always @(posedge PHI1)
begin
if (MASRST == 1'b1)
begin
STATE <= 4'd0;
SPCDISF <= 1'b0;
SPCREQF <= 1'b0;
SPCDISD <= 1'b1;
SPCREQD <= 1'b0;
SPCDISA <= 1'b1;
SPCREQA <= 1'b0;
SPCDISS <= 1'b0;
SPCREQS <= 1'b0;
end
else
begin
STATE <= state;
SPCDISF <= DIS1;
SPCREQF <= REQ1;
SPCDISD <= DIS2;
SPCREQD <= REQ2;
SPCDISA <= DIS3;
SPCREQA <= REQ3;
SPCDISS <= DIS4;
SPCREQS <= REQ4;
end

end





//////// Now as there is no direct system for interrupt (for F == 1, 2 etc.), we have to store the Fs and the adds in the memory
//and make the processor read it in all/intermediate periodic cycles to gauge/monitor what to do  


// all the boundary scan stuff

assign CK = PHI1;
assign Scan_en = (WRSTN==1'b1) ? ShiftWR : 1'b0;
assign Hold_en_incell = (WRSTN==1'b1) ? 1'b0 : (({WIR_2_q, WIR_1_q, WIR_dout}==3'b010) ? (~CaptureWR) : 1);  //WIR==3'b010 EXTEST
assign Hold_en_outcell = (WRSTN==1'b1) ? 1'b0 : (({WIR_2_q, WIR_1_q, WIR_dout}==3'b100) ? 1 : (~CaptureWR));  //WIR==3'b100 INTEST
assign test_din = (WRSTN==1'b1 && Scan_en==1'b1 && SelectWIR==1'b0 && {WIR_2_q, WIR_1_q, WIR_dout}!=3'b001) ? WSI : 1'b0;
assign Bypass_d = (WRSTN==1'b1 && Scan_en==1'b1 && SelectWIR==1'b0 && {WIR_2_q, WIR_1_q, WIR_dout}==3'b001) ? WSI : 1'b0;  //WIR==3'b001 BYPASS
assign WIR_din = (WRSTN==1'b1 && Scan_en==1'b1 && SelectWIR==1'b1) ? WSI : 1'b0;  //WIR==3'b001 BYPASS
assign WSO = (~WRSTN) ? 1'b0 : (SelectWIR ? WIR_dout : (({WIR_2_q, WIR_1_q, WIR_dout}==3'b001) ? Bypass_q : test_dout));

//Bypass Register
dff dff_bypass(.CK(CK), .Q(Bypass_q), .D(Bypass_d));

//WIR
dff dff_WIR_2(.CK(CK), .Q(WIR_2_q), .D(WIR_din));
dff dff_WIR_1(.CK(CK), .Q(WIR_1_q), .D(WIR_2_q));
dff dff_WIR_0(.CK(CK), .Q(WIR_dout), .D(WIR_1_q));

// connecting the wrapper boundary registers

WBC WBC_I1(.clk(CK), .CTI(test_din), .CFI(DAddrE1[0]), .Scan_en(Scan_en), .Hold_en(Hold_en_incell), .CTO(CTI[0]), .CFO(DAddrE1A[0]));

genvar i;
generate
for (i = 0; i<31; i=i+1)
begin
WBC WBC_DAddrE(.clk(CK), .CTI(CTI[i]), .CFI(DAddrE1[i+1]), .Scan_en(Scan_en), .Hold_en(Hold_en_incell), .CTO(CTI[i+1]), .CFO(DAddrE1A[i+1]));
end
endgenerate


generate
for (i = 0; i<32; i=i+1)
begin
WBC WBC_DOutE(.clk(CK), .CTI(CTI[i+31]), .CFI(DOutE1[i]), .Scan_en(Scan_en), .Hold_en(Hold_en_incell), .CTO(CTI[i+1+31]), .CFO(DOutE1A[i]));
end
endgenerate


generate
for (i = 0; i<32; i=i+1)
begin
WBC WBC_DOut(.clk(CK), .CTI(CTI[i+63]), .CFI(DOutA[i]), .Scan_en(Scan_en), .Hold_en(Hold_en_outcell), .CTO(CTI[i+1+63]), .CFO(DOut[i]));
end
endgenerate


generate
for (i = 0; i<31; i=i+1)
begin
WBC WBC_DAddr(.clk(CK), .CTI(CTI[i+95]), .CFI(DAddrA[i]), .Scan_en(Scan_en), .Hold_en(Hold_en_outcell), .CTO(CTI[i+1+95]), .CFO(DAddr[i]));
end
endgenerate

WBC WBC_O1(.clk(CK), .CTI(CTI[126]), .CFI(DAddrA[31]), .Scan_en(Scan_en), .Hold_en(Hold_en_outcell), .CTO(test_dout), .CFO(DAddr[31]));

endmodule


// D flip-flop
module dff (CK,Q,D);
input CK,D;
output Q;
reg Q ;

always @(posedge CK)
	Q <=D;

endmodule

// 2:1 MUX
module MUX (sel, in0, in1, out);
input sel, in0, in1;
output out;

assign out = sel? in1 : in0;
endmodule

// Wrapper boundary cell
module WBC (clk, CTI, CFI, Scan_en, Hold_en, CTO, CFO);

input clk, CTI, CFI, Scan_en, Hold_en;
output CTO, CFO;
wire DIN;

MUX MUX_in(.sel(Scan_en), .in0(CFO), .in1(CTI), .out(DIN));
MUX MUX_out(.sel(Hold_en), .in0(CFI), .in1(CTO), .out(CFO));
dff dff_1(.CK(clk), .Q(CTO), .D(DIN));
endmodule




