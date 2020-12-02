`include "./dlx.defines"
`timescale 1ns/1ps

module together (
	PHI, MASRST,                            // One-Phase clock for DLX 
	DAddr, DAddrE, DAddrE2, DAddrE3, DRead, DWrite, DReadE, DWriteE, DReadE2, DWriteE2, DReadE3, DWriteE3, DOut, DOutE, DOutE2, DOutE3, DIn, DInE, DInE2, DInE3, STATE,	IAddr, IAddrE, IRead, IIn, IInE, IWriteE,              // Instruction Cache interface
	MRST, Pause, TCE, TMS, TDI, TDO,         // Test Controls
WSI, WRSTN, SelectWIR, ShiftWR, CaptureWR, WSO, DWR, DO, DAD, SPCREQ, SPCDIS, LDS, LDF, MACcalc, MACactual, DBus, Sel, TP1, TPE1, MRST11, stop, TP2, TPE2);

//// actually the change from PHI1 to PHI was absolutely not necessary, confusing (doesn't hurt, so not reverted back)
input MASRST;
input PHI;
input MRST;
input MRST11;
input [`WordSize] DAddrE, DAddrE2, DAddrE3, DOutE, DOutE2, DOutE3, IAddrE, IInE; // added external //signals
output [`WordSize] DAddr, DOut, DIn, DInE,DInE2, DInE3;
output DRead, DWrite;
input DReadE, DWriteE;
input DReadE2, DWriteE2;
input DReadE3, DWriteE3;
output [`WordSize]	IAddr;          // Instruction Cache read address
output					IRead;          // Instruction Cache read enable
output [`WordSize]	IIn;            // Instruction from (change) Instruction Cache
input						MRST;           // Master Reset
input						TCE;            // Test Clock Enable
input						TMS;		// Test Mode Select
input						TDI;		// Test Data In
output					TDO;		// Test Data Out
input IWriteE;

input [31:0] DBus;
input [1:0] Sel;

//input [3:0] STATE1; // deciding the enable signals from security controller to system memory
input [3:0] STATE; 
input SPCREQ, SPCDIS; // coming from the SPCcontroller
input Pause;

input LDS, LDF; // coming from master controller signifying start and end of instruction load

input MACcalc, MACactual; // MACcalc coming from cryto module directly current 1 bit signal

// boundary scan signals
input WSI, WRSTN, SelectWIR, ShiftWR, CaptureWR;
output WSO;


wire [`WordSize] DAddr1, DOut1, DIn1;
wire DRead1, DWrite1;

wire [`WordSize] IAddr1;
wire IRead1, TDO1;
wire [`WordSize] IIn1;

//wire [`WordSize] DInE;

// as of now, DOutE, DAddrE inserted into boundary scan and on //output side DOut, DAddr (can be extended to include IIn, IAddr.)

// boundary scan extra signals

wire [`WordSize] DOutEA, DAddrEA;
wire [`WordSize] DOutA, DAddrA;

wire Scan_en, Hold_en_incell, Hold_en_outcell;
wire test_din, test_dout;
wire Bypass_d, Bypass_q;
wire WIR_din, WIR_2_q, WIR_1_q, WIR_dout;

wire [126:0] CTI; // first DR, DI, SHIFT, ADDR, DOI, DOR

wire CK; 

reg EN; // control the timing of writes into Icache/memory
reg cert; // enabling the integrity check of firmwire

wire [31:0] Val;
output [31:0] TP1;
output TPE1;
output [31:0] TP2;
output TPE2;
wire [9:0] EV;
wire [31:0] TP;
wire TPE;

assign TP1 = TP;
assign TPE1 = TPE;


input stop;

wire [31:0] Val1;
wire [7:0] EV1;




Icache IC1 (.PHI1(PHI && Pause && cert), .IAddr(IAddr1), .MRST(MRST && SPCDIS), .IIn(IIn1), .IInE(IInE), .IAddrE(IAddrE), .IWriteE(IWriteE && EN));

// debug try
//Icache IC1 (.PHI1(PHI1), .IAddr(IAddr1), .MRST(MRST), .IIn(IIn1), .IInE(32'b0), .IAddrE(32'b0), .IWriteE(`LogicZero));

// can put the SPCDIS in RST as well
dlx DLX (
.PHI1	(PHI && Pause && cert),
	.DIn	(DIn1),
	.IIn	(IIn1),
	.MRST	(MRST && SPCDIS),
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


reg r0, r1, r2, r3;
reg w0, w1, w2, w3;
// DLX, AES, FFT, SPI (in order of terminology used)
always @(STATE)
begin
case(STATE)

4'd0: begin
r0 = 1'b1; r1 = 1'b1; r2 = 1'b1; r3 = 1'b1;
w0 = 1'b1; w1 = 1'b1; w2 = 1'b1; w3 = 1'b1;
end

4'd1: begin // suppose AES working 
r0 = 1'b0; r1 = 1'b1; r2 = 1'b0; r3 = 1'b0;
w0 = 1'b0; w1 = 1'b1; w2 = 1'b0; w3 = 1'b0;

end

4'd2: begin // suppose DLXworking just after AES (information flow case)
r0 = 1'b1; r1 = 1'b1; r2 = 1'b0; r3 = 1'b0;
w0 = 1'b1; w1 = 1'b1; w2 = 1'b0; w3 = 1'b0;

end

4'd3: begin // external operations through SPI 
r0 = 1'b1; r1 = 1'b0; r2 = 1'b1; r3 = 1'b1;
w0 = 1'b1; w1 = 1'b0; w2 = 1'b1; w3 = 1'b1;
end

default: begin
r0 = 1'b1; r1 = 1'b1; r2 = 1'b1; r3 = 1'b1;
w0 = 1'b1; w1 = 1'b1; w2 = 1'b1; w3 = 1'b1;
end

endcase

end

// state based 
//Dcache DC1 (.DOut(DOut1), .DAddr(DAddr1), .DRead(DRead1), //.DWrite(DWrite1), .DIn(DIn1), .DOutE(DOutEA), .DAddrE(DAddrEA), //.DInE(DInE), .DReadE(`LogicZero), .DWriteE(`LogicZero));

//SystemMem SM1 (.DOut(DOut1), .DAddr(DAddr1), .DRead(DRead1), .DWrite(DWrite1), .DIn(DIn1), .DOutE1(DOutEA), .DAddrE1(DAddrEA), .DInE1(DInE), .DReadE1(DReadE), .DWriteE1(DWriteE), .DOutE2(DOutE2), .DAddrE2(DAddrE2), .DInE2(DInE2), .DReadE2(DReadE2), .DWriteE2(DWriteE2), .DOutE3(DOutE3), .DAddrE3(DAddrE3), .DInE3(DInE3), .DReadE3(DReadE3), .DWriteE3(DWriteE3));

SystemMem SM1 (.DOut(DOut1), .DAddr(DAddr1), .DRead(DRead1 && r0), .DWrite(DWrite1 && w0), .DIn(DIn1), .DOutE1(DOutEA), .DAddrE1(DAddrEA), .DInE1(DInE), .DReadE1(DReadE && r1), .DWriteE1(DWriteE && w1), .DOutE2(DOutE2), .DAddrE2(DAddrE2), .DInE2(DInE2), .DReadE2(DReadE2 && r2), .DWriteE2(DWriteE2 && w2), .DOutE3(DOutE3), .DAddrE3(DAddrE3), .DInE3(DInE3), .DReadE3(DReadE3 && r3), .DWriteE3(DWriteE3 && w3));


assign DOutA = DOut1;
assign DRead = DRead1;
assign DIn = DIn1;
assign DAddrA = DAddr1;
assign DWrite = DWrite1;
assign IAddr = IAddr1;
assign IIn = IIn1;
assign IRead = IRead1;
assign TDO = TDO1;

debug_DLX1 ETM(PHI, MRST11, MRST, stop, Pause, IIn1, IAddr1, DIn1, DOut1, DAddr1, DRead1, DWrite1, 32'b1, 32'd2,DBus, Sel, TP, TPE, EV, Val); 


// debug logic needed for system memory

debug_mem MEMI(PHI, MRST11, DIn1, DOut1, DAddr1, (DRead1&&r0), (DWrite1 && w0),  DInE, DOutEA, DAddrEA, (DReadE&&r1), (DWriteE && w1),  DInE2, DOutE2, DAddrE2, (DReadE2&&r2), (DWriteE2 && w2), DInE3, DOutE3, DAddrE3, (DReadE3&&r3), (DWriteE3 && w3), DBus, Sel, EV1, Val1, TP2, TPE2);



// Debug - SPC interface and storage

reg [31:0] tempbuff[0:3];
reg [1:0] cru;
reg [31:0] tempbuff1;

always @(posedge PHI)
begin
if (MASRST == 1'b1)
begin
tempbuff[0] <= 'd0;
tempbuff[1] <= 'd0;
tempbuff[2] <= 'd0;
tempbuff[3] <= 'd0;
cru <= 'd0;
end
else if ((EV[7:0] > 'd0) || (cru > 2'b0))
begin
cru <= cru + 2'b1;
tempbuff[3] <= tempbuff[2];
tempbuff[2] <= tempbuff[1];
tempbuff[1] <= tempbuff[0];
tempbuff[0] <= Val;

end
else
begin
cru <= 2'b0;

// needs to store tempbuff to wait for SPCREQ

end

end

reg [9:0] EV2;
reg [7:0] EV3;

always @(posedge PHI)
begin
EV2 <= EV;
end



always @(posedge PHI)
begin
if (MASRST == 1'b1)
begin
tempbuff1 <= 'd0;
end
else if ((EV1[7:0] > 'd0))
begin
tempbuff1 <= Val1;

end


// needs to store tempbuff to wait for SPCREQ



end


always @(posedge PHI)
begin
EV3 <= EV1;
end


////added signals to interface with security policy controller
///**********************************************************///

///////////////////////////////// security wrapper ///////////////////
output reg DWR;
output reg [31:0]DO, DAD;

reg [9:0] counter;
reg [4:0] state;
reg [31:0] buff[0:3];

//reg resultcheck;


reg MRST1;
reg Pause1;
reg LDS1;
reg LDF1;



always @(posedge PHI)
begin
MRST1 <= MRST;
Pause1 <= Pause;
LDS1 <= LDS;
LDF1 <= LDF;
end




//// logic for counter

///// assuming same counter for both instruction load as well as DLX processing

// time stamp

always @(posedge PHI)
begin
 if (((MRST1 == 1'b0)&&(MRST == 1'b1)&& (Pause == 1'b1)) || ((LDS1 == 1'b0)&&(LDS == 1'b1)&& (Pause == 1'b1))) 
begin
	counter <= 10'd0;
end

else if ((((LDS == 1'b1)&& (cert == 1'b1))||((MRST == 1'b1) && (cert == 1'b1)))&& (Pause == 1'b1) && (SPCDIS == 1'b1)) // no mention of load finish req
begin
	counter <= counter + 10'd1;
end

end

reg [9:0] totalcount;
// assign totalcount = ((LDF1 == 1'b0)&& (LDF == 1'b1))? counter:10'b0; // just when loading instruction finishes
// has to be register form

always @(posedge PHI)
begin
if (MASRST == 1'b1)
begin
totalcount <= 10'd0;
end
else if ((LDF1 == 1'b0)&& (LDF == 1'b1))
begin
totalcount <= counter;
end
end 

//////////////////////////////////////////////////////////////////
reg [2:0] pastcount;
always @(*)
begin
if ((MRST1 == 1'b0)&&(MRST == 1'b1)) 
begin
pastcount = pastcount + 3'd1;
end
else if (MASRST == 1'b1)
begin
	pastcount = 3'd0;
end
end // need to incorporate a MASTER RESET signifying boot FROM SYTEM CONTROLLER
 

// what about the buffer

always @(pastcount)
//begin
//if (((MRST1 == 1'b0)&&(MRST == 1'b1))) 
begin
buff[pastcount] = totalcount; // 
//end
end // need to incorporate a MASTER RESET FROM SYTEM CONTROLLER


// EN signal to prevent instruction memory write during the time of execution

always @(posedge PHI)
begin
if ((WRSTN == 1'b1) && (ShiftWR == 1'b0)) // normal mode (can be in other terms as well)
begin
if (MRST == 1'b1)
begin
EN = 1'b0;
end
else
begin
EN = 1'b1;
end
end
else
begin
EN = 1'b1; // during TEST mode
end

end



/// the certification
always @(posedge PHI)
begin
	if (MASRST == 1'b1)
	begin
		cert <= 1'b1;
	end
	else if ((LDS1 == 1'b0) && (LDS == 1'b1) && (Pause == 1'b1))
	begin
		cert <= 1'b0;
	end
	else if (MACactual == MACcalc) // verifying if the key meets randomness criteria (local implementation , doesnot have to send to SPC) 
	begin
		cert <= 1'b1;
	end
end
// any firmwire integrity check or so???
// do something like this as if the integrity check is successful then start execution


///////////NOW FOR THE STATES

///// states for instruction load start, finish (total inst), pause; execution start, finish, pause
/// data memory access??????
//// think about how a TOCTOU policy might be implemented......from that regard, what info???

always @(posedge PHI)
begin

	if (MASRST == 1'b1)
	begin
         state <= 5'd0;
        end

else if ((WRSTN == 1'b1) && (ShiftWR == 1'b0)) // normal mode
begin
if ((LDS1 == 1'b0) && (LDS == 1'b1) && (Pause == 1'b1))
begin
state <= 5'd1;
end
else if ((LDS == 1'b1) && (counter == 10'b1))
begin
state <= 5'd2; // passed the integrity check test
end
else if ((LDF1 == 1'b0) && (LDF == 1'b1) && (Pause == 1'b1))
begin
state <= 5'd3;
end
else if ((LDS == 1'b1) && (Pause1 == 1'b1) && (Pause == 1'b0) )
begin
state <= 5'd4;
end
else if ((LDS == 1'b1) && (Pause1 == 1'b0) && (Pause == 1'b1) )
begin
state <= 5'd5;
end
// now starts the instruction execution stuff
else if ((MRST1 == 1'b0)&&(MRST == 1'b1) && (Pause == 1'b1)) 
begin
state <= 5'd6;
end
else if ((IAddr1/4 == totalcount) && (MRST == 1'b1) && (Pause == 1'b1)) // last instruction start execution
begin
state <= 5'd7;
end
else if ((MRST1 == 1'b1)&&(MRST == 1'b0) && (Pause == 1'b1))
begin
state <= 5'd8; //actual end
end
else if ((MRST == 1'b1) && (Pause1 == 1'b1) && (Pause == 1'b0) )
begin
state <= 5'd9;
end
else if ((MRST == 1'b1) && (Pause1 == 1'b0) && (Pause == 1'b1) )
begin
state <= 5'd10;
end
else if (SPCREQ == 1'b1)
begin
state <= 5'd11;
end
else if (EV[7:0] > 'd0)
begin
state <= 5'd12;
end
else if (EV1[7:0] > 'd0)
begin
state <= 5'd14;
end
else
begin
state <= 5'd13;
end

end

else  // test mode   
begin
state <= 'd0;
//if ((LDS1 == 1'b0) && (LDS == 1'b1) && (Pause == 1'b1))
//begin
//state <= 5'd13;
//end
//else if ((LDS == 1'b1) && (counter == 10'b1))
//begin
//state <= 5'd14; // passed the integrity check test
//end
//else if ((LDF1 == 1'b0) && (LDF == 1'b1) && (Pause == 1'b1))
//begin
//state <= 5'd15;
//end
//else if ((LDS == 1'b1) && (Pause1 == 1'b1) && (Pause == 1'b0) )
//begin
//state <= 5'd16;
//end
//else if ((LDS == 1'b1) && (Pause1 == 1'b0) && (Pause == 1'b1) )
//begin
//state <= 5'd17;
//end
//// now starts the instruction execution stuff
//else if ((MRST1 == 1'b0)&&(MRST == 1'b1) && (Pause == 1'b1)) 
//begin
//state <= 5'd18;
//end
//else if ((IAddr1/4 == totalcount) && (MRST == 1'b1) && (Pause == 1'b1)) // last instruction start execution
//begin
//state <= 5'd19;
//end
//else if ((MRST1 == 1'b1)&&(MRST == 1'b0) && (Pause == 1'b1))
//begin
//state <= 5'd20; //actual end
//end
//else if ((MRST == 1'b1) && (Pause1 == 1'b1) && (Pause == 1'b0) )
//begin
//state <= 5'd21;
//end
//else if ((MRST == 1'b1) && (Pause1 == 1'b0) && (Pause == 1'b1) )
//begin
//state <= 5'd22;
//end
//else if (SPCREQ == 1'b1)
//begin
//state <= 5'd23;
//end
//else
//begin
//state <= 5'd24;
//end
 

end


end

///**********************************************************///
//// outputs at different stages // has 32 different addresses to write too as an asumption

always @(state)
begin

//if ((SPCDIS && cert) == 1'b1) // an addition (CAN REMOVE THE DWR ADDITIONS LATER)
//begin

	case(state)
5'd0:	begin
		DWR = 1'b0;
		DAD = 32'd0;
                DO = 32'd0;
	end
5'd1:	begin
		DWR = 1'b1; // could be 1 && SPCDIS to prevent any write if SPCDIS = 0 from apriori (will depend on SPC logic implementation)
		DAD = 32'd64;
                DO = {totalcount, 17'd0, state}; // actually the previous one's this data
	end
5'd2:	begin
		DWR = (1'b1 && cert && SPCDIS);
		DAD = DAD + 32'd1;
                DO = {cert, 26'b0, state};
	end
5'd3:	begin
		DWR = (1'b1 && cert && SPCDIS);
		DAD = DAD + 32'd1;
                DO = {counter, 17'd0, state};
	end
5'd4:	begin
		DWR = (1'b1 && cert && SPCDIS);
		DAD = DAD + 32'd1;
                DO = {counter, 17'd0, state};
	end
5'd5:	begin
		DWR = (1'b1 && cert && SPCDIS);
		DAD = DAD + 32'd1;
                DO = {27'd0, state};
	end
5'd6:	begin
		DWR = (1'b1 && cert && SPCDIS);
		DAD = DAD + 32'd1;
		DO = {totalcount, 17'd0, state};
               
	end
5'd7:	begin
		DWR = (1'b1 && cert && SPCDIS);
		DAD = DAD + 32'd1;
                DO = {27'd0, state};
	end
5'd8:	begin
		DWR = (1'b1 && cert && SPCDIS);
		DAD = DAD + 32'd1;
                DO = {counter, 17'd0, state};
	end
5'd9:	begin
		DWR = (1'b1 && cert && SPCDIS);
		DAD = DAD + 32'd1;
                DO = {counter, 17'd0, state};
	end
5'd10:	begin
		DWR = (1'b1 && cert && SPCDIS);
		DAD = DAD + 32'd1;
                DO = {27'd0, state};
	end
5'd11:	begin
		DWR = (1'b1 && cert && SPCDIS);
		DAD = DAD + 32'd1;
                DO = {tempbuff[0][15:0], 11'd0, state};
		//DO = {IAddr1[15:0], 11'd0, state};
	end
5'd12: begin
		DWR = (1'b1 && cert && SPCDIS);
		DAD = DAD + 32'd1;
		DO = {counter, 7'd0, EV2, state};
	end
5'd13:	begin
		DWR = 1'b0;
		DAD = DAD;
                DO = 32'd0;
	end
5'd14: begin
		DWR = (1'b1 && cert && SPCDIS);
		DAD = DAD + 32'd1;
		DO = {12'd0, 7'd0, EV3, state};
	end
//5'd13:	begin
//		DWR = 1'b1;
//		DAD = 32'd64;
//                DO = {totalcount, 17'd0, state};
//	end
//5'd14:	begin
//		DWR = (1'b1 && cert && SPCDIS);
//		DAD = DAD + 32'd1;
//                DO = {cert, 26'd0, state};
//	end
//5'd15:	begin
//		DWR = (1'b1 && cert && SPCDIS);
//		DAD = DAD + 32'd1;
//                DO = {counter, 17'd0, state};
//	end
//5'd16:	begin
//		DWR = (1'b1 && cert && SPCDIS);
//		DAD = DAD + 32'd1;
//                DO = {counter, 17'd0, state};
//	end
//5'd17:	begin
//		DWR = (1'b1 && cert && SPCDIS);
//		DAD = DAD + 32'd1;
//                DO = {27'd0, state};
//	end
//5'd18:	begin
//		DWR = (1'b1 && cert && SPCDIS);
//		DAD = DAD + 32'd1;
//		DO = {totalcount, 17'd0, state};
//               
//	end
//5'd19:	begin
//		DWR = (1'b1 && cert && SPCDIS);
//		DAD = DAD + 32'd1;
//                DO = {27'd0, state};
//	end
//5'd20:	begin
//		DWR = (1'b1 && cert && SPCDIS);
//		DAD = DAD + 32'd1;
//                DO = {counter, 17'd0, state};
//	end
//5'd21:	begin
//		DWR = (1'b1 && cert && SPCDIS);
//		DAD = DAD + 32'd1;
//                DO = {counter, 17'd0, state};
//	end
//5'd22:	begin
//		DWR = (1'b1 && cert && SPCDIS);
//		DAD = DAD + 32'd1;
//                DO = {27'd0, state};
//	end
//5'd23:	begin
//		DWR = (1'b1 && cert && SPCDIS);
//		DAD = DAD + 32'd1;
//                DO = {IAddr1[15:0], 11'd0, state};
//	end
//5'd24:	begin
//		DWR = 1'b0;
//		DAD = DAD;
//                DO = 32'd0;
//	end
// fill in the rest of the stuff	
endcase

//end

end



// all the boundary scan stuff

assign CK = (PHI && Pause && SPCDIS) ; // diffeerent here as SPCDIS is also included
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

WBC WBC_I1(.clk(CK), .CTI(test_din), .CFI(DAddrE[0]), .Scan_en(Scan_en), .Hold_en(Hold_en_incell), .CTO(CTI[0]), .CFO(DAddrEA[0]));

genvar i;
generate
for (i = 0; i<31; i=i+1)
begin
WBC WBC_DAddrE(.clk(CK), .CTI(CTI[i]), .CFI(DAddrE[i+1]), .Scan_en(Scan_en), .Hold_en(Hold_en_incell), .CTO(CTI[i+1]), .CFO(DAddrEA[i+1]));
end
endgenerate


generate
for (i = 0; i<32; i=i+1)
begin
WBC WBC_DOutE(.clk(CK), .CTI(CTI[i+31]), .CFI(DOutE[i]), .Scan_en(Scan_en), .Hold_en(Hold_en_incell), .CTO(CTI[i+1+31]), .CFO(DOutEA[i]));
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




