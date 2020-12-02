`timescale 1 ns / 1 ps
`include "FFT128_CONFIG.inc"

module FFT128wrapper(MASRST, CLK, RSTT, ED, START, SHIFT, DR, DI, RDY, OVF1, OVF2, ADDR, DOR, DOI, WSI, WRSTN, SelectWIR, ShiftWR, CaptureWR, WSO, DWR, DO, DAD, SPCREQ, SPCDIS, MRST, DBus, Sel, TP1, TPE1);

	`FFT128paramnb		  	 		//nb is the data bit width

	output RDY ;   			// in the next cycle after RDY=1 the 0-th result is present 
	wire RDY ;
	output OVF1 ;			// 1 signals that an overflow occured in the 1-st stage 
	wire OVF1 ;
	output OVF2 ;			// 1 signals that an overflow occured in the 2-nd stage 
	wire OVF2 ;
	output [6:0] ADDR ;	//result data address/number
	wire [6:0] ADDR ;
	output [nb+3:0] DOR ;//Real part of the output data, 
	wire [nb+3:0] DOR ;	 // the bit width is nb+4, can be decreased when instantiating the core 
	output [nb+3:0] DOI ;//Imaginary part of the output data
	wire [nb+3:0] DOI ;
	
	input CLK ; 	//Clock signal is less than 300 MHz for the Xilinx Virtex5 FPGA  

        input MASRST;	
	wire CLK ;
	input RSTT ;				//Reset signal, is the synchronous one with respect to CLK
	wire RSTT ;
	input ED ;					//=1 enables the operation (eneabling CLK)
	wire ED ;
	input START ;  			// its falling edge starts the transform or the serie of transforms  
	wire START ;			 	// and resets the overflow detectors
	input [3:0] SHIFT ;		// bits 1,0 -shift left code in the 1-st stage
	wire [3:0] SHIFT ;	   	// bits 3,2 -shift left code in the 2-nd stage
	input [nb-1:0] DR ;		// Real part of the input data,  0-th data goes just after 
	wire [nb-1:0] DR ;	    // the START signal or after 255-th data of the previous transform
	input [nb-1:0] DI ;		//Imaginary part of the input data
	wire [nb-1:0] DI ;

	input SPCREQ, SPCDIS;

input MRST;
input [31:0] DBus;
input [1:0] Sel;
output [31:0] TP1;
output TPE1;

wire [7:0] EV;
wire [31:0] Val;


// the boundary scan signals
input WSI, WRSTN, SelectWIR, ShiftWR, CaptureWR;
output WSO;

 wire RST;

assign RST = (RSTT||SPCDIS);

//assign RST = (RSTT);
////added signals to interface with security policy controller
///**********************************************************///

///// SECURITY WRAPPER ////

///// here pause is the ED (was already there to halt the operation)
output reg DWR;
output reg [31:0]DO, DAD;
reg [31:0] DO1, DAD1; // stores the data to be sent to SPC 
reg DWR1 ; //stores write to SPC status for next cycle
//wire [31:0] DO2;
reg [9:0] counter;
reg [3:0] state;
reg [nb+3:0] DOII;
reg [31:0] buff[0:3]; // basically stores the past 5 data i/p
//reg [2:0] fincoun;


//assign DO1[31:16] = DR;  // start of computation
//assign DO1[15:0] = 16'b0;

//assign DO2[31:16] = DOR; // end of computation
//assign DO2[15:0] = 16'b1;

// logic for writing new info into the SPC Controller data cache
reg RST1, START1; // STARTF  go down in next cycle after RSTF
reg RST2, START2; 
reg RDY1;
reg ED1; // ED is basically for clock gating and stuff 

// time stamp
always @(posedge CLK)
begin
if ((((RST2 == 1'b1)&&(RST == 1'b0))&&((START2 == 1'b1)&&(START == 1'b0))&& (ED == 1'b1))||(counter == 10'd450))
begin
counter <= 10'd0;
end
else if ((ED == 1'b1)&& (RST == 1'b0))
begin
counter <= counter + 10'd1; // 10-20 extra cycles for safety!!
end
//else if (MASRST == 1'b1) // not really sure if we needed this
//begin
//counter <= 10'd0;
//end
end

/////// EV stuff
reg [7:0] EV2;

always @(posedge CLK)
begin
EV2 <= EV;
end

// Debug - SPC interface and storage

reg [31:0] tempbuff;
//reg [1:0] cru;

always @(posedge CLK)
begin
if (MASRST == 1'b1)
begin
tempbuff <= 'd0;
end
else if ((EV[7:0] > 'd0))
begin
tempbuff <= Val;
end
else
tempbuff <= tempbuff; // has to store
end

// needs to store tempbuff to wait for SPCREQ

//end

//end





always @(posedge CLK)
begin
RST1 <= RST;
RST2 <= RST1;
START1 <= START;
START2 <= START1;
RDY1 <= RDY;
ED1 <= ED;
if (counter == 10'd441)
begin
DOII <= DOI;
end
else if (MASRST == 1'b1)
begin
DOII <= 20'd0;
end
end



// always assuming that EDF would be ON in general
//  For normal mode WRSTN is 1'b1 and ShiftWR = 0 (scan =0, hold //= 0);
// combinational security wrapper logic


reg [2:0] pastcount;
always @(*)
begin
if (((RST2 == 1'b1)&&(RST == 1'b0))&&((START2 == 1'b1)&&(START == 1'b0))&& (ED == 1'b1))
begin
pastcount = pastcount + 3'd1;
end
else if (MASRST == 1'b1)
begin
	pastcount = 3'd0;
end
end // need to incorporate a MASTER RESET signifying boot FROM SYTEM CONTROLLER
 

// what about the buffer

//always @(posedge CLK)
//begin
//if (((RST2 == 1'b1)&&(RST == 1'b0))&&((START2 == 1'b1)&&(START == 1'b0))&& (ED == 1'b1)) // start of operation
//begin
//buff[pastcount] <= {DR, DI};
//end
//end // need to incorporate a MASTER RESET FROM SYTEM CONTROLLER

// what about the buffer

always @(pastcount)
begin
//if (((RST2 == 1'b1)&&(RST == 1'b0))&&((START2 == 1'b1)&&(START == 1'b0))&& (ED == 1'b1)) // start of operation
//begin
buff[pastcount] <= {DR, DI};
//end
end // need to incorporate a MASTER RESET FROM SYTEM CONTROLLER



// external interface to SPC

//always @(posedge CLK)
//begin
//if ((counter == 10'd442)) // done as the address jumps from 4 to 6 at this instant (manual decrease)
//begin
//DAD <= DAD1 - 32'd1;
//end
//else
//begin
//DAD <= DAD1;
//end
//DO <= DO1;
//DWR <= DWR1;
//end

// THINKING in terms of a state machine /////////////////////////////////////
//
always @(posedge CLK)
begin
	if (MASRST == 1'b1)
	begin
         state <= 4'd0;
        end

else if ((WRSTN == 1'b1) && (ShiftWR == 1'b0)) // normal mode
begin

if (((RST2 == 1'b1)&&(RST == 1'b0))&&((START2 == 1'b1)&&(START == 1'b0))&& (ED == 1'b1))
begin
state <= 4'd1;
end
else if (counter == 10'b1) // send the imaginary i/p in next cycle
begin
state <= 4'd2;
end
else if ((RDY1 == 1'b0)&&(RDY == 1'b1)) // end of operation
begin
	state <= 4'd3;
end
else if (counter == 10'd442)
begin
	state <= 4'd4;
end
else if ((ED1 == 1'b1) && (ED == 1'b0))
begin
	state <= 4'd5;
end
else if ((ED1 == 1'b0) && (ED == 1'b1))
begin
	state <= 4'd6;
end
else if (SPCREQ == 1'b1)
begin
	state <= 4'd15;
end
else if (EV > 'd0)
begin
state <= 4'd8;
end
else
begin
	state <= 4'd7;
end

end

else //// test and other modes

begin

state <= 4'd0;
//if (((RST2 == 1'b1)&&(RST == 1'b0))&&((START2 == 1'b1)&&(START == 1'b0))&& (ED == 1'b1))
//begin
//state <= 4'd8;
//end
//else if (counter == 10'b1) // send the imaginary i/p in next cycle
//begin
//state <= 4'd9;
//end
//else if ((RDY1 == 1'b0)&&(RDY == 1'b1)) // end of operation
//begin
//	state <= 4'd10;
//end
//else if (counter == 10'd442)
//begin
//	state <= 4'd11;
//end
//else if ((ED1 == 1'b1) && (ED == 1'b0))
//begin
//	state <= 4'd12;
//end
//else if ((ED1 == 1'b0) && (ED == 1'b1))
//begin
//	state <= 4'd13;
//end
//else
//begin
//	state <= 4'd14;
//end
//
end

end


//// SPCDIS anded to DWR just to maintaintain concistency with other IPs...NOT REQUIRED HERE AS RST LOGIC IS DONE IN A DIFFERENT WAY HERE (RSTT || SPCDIS)
always @(state)
begin

if (SPCDIS == 1'b0) // an addition (CAN REMOVE THE DWR ADDITIONS LATER)
begin


	case(state)
4'd0:	begin
		DWR = 1'b0;
		DAD = 32'd0;
                DO = 32'd0;
	end
       
4'd1:	        begin
		DWR = 1'b1; // maintain consistency with other IPs i.e. NOT 1 && SPCDIS here
		DAD =32'd48;
		DO = {DR, SHIFT, 8'd0, state}; // initial data
	end
4'd2:
	begin
		DWR = (1'b1 && (!SPCDIS));
		DAD = DAD + 32'd1;
		DO = {DI, SHIFT, 8'd0, state}; // initial data
	end
4'd3:	
	begin
		DWR = (1'b1 && (!SPCDIS));
		DAD = DAD + 32'd1;
		DO = {DOR, OVF2, 7'b0, state}; // end of operation and sending real
	end
4'd4:	
	begin
		DWR = (1'b1 && (!SPCDIS));
		DAD = DAD + 32'd1;
		DO = {DOII, 8'b0, state}; // end of operation and sending real
	end
4'd5:	
	begin
		DWR = (1'b1 && (!SPCDIS));
		DAD = DAD + 32'd1;
		DO = {counter, 18'b0, state}; // pause cycle
	end
4'd6:	
	begin
		DWR = (1'b1 && (!SPCDIS));
		DAD = DAD + 32'd1;
		DO = {28'b0, state}; // end of pause cycle
	end
4'd7:
	begin
		DWR = 1'b0;
		DAD = DAD ;
		DO = 32'd0;
	end
4'd8:
	begin
		DWR = (1'b1 && (!SPCDIS));
		DAD = DAD + 32'd1;
		DO = {10'd0, 10'd0, EV2, state}; // end of pause cycle
	end
	
       
//4'd8:	        begin
//		DWR = 1'b1;
//		DAD =32'd48;
//		DO = {DR, SHIFT, 8'd0, state}; // initial data
//	end
//4'd9:
//	begin
//		DWR = (1'b1 && (!SPCDIS));
//		DAD = DAD + 32'd1;
//		DO = {DI, SHIFT, 8'd0, state}; // initial data
//	end
//4'd10:	
//	begin
//		DWR = (1'b1 && (!SPCDIS));
//		DAD = DAD + 32'd1;
//		DO = {DOR, OVF2, 7'b0, state}; // end of operation and sending real
//	end
//4'd11:	
//	begin
//		DWR = (1'b1 && (!SPCDIS));
//		DAD = DAD + 32'd1;
//		DO = {DOII, 8'b0, state}; // end of operation and sending real
//	end
//4'd12:	
//	begin
//		DWR = (1'b1 && (!SPCDIS));
//		DAD = DAD + 32'd1;
//		DO = {counter, 18'b0, state}; // pause cycle
//	end
//4'd13:	
//	begin
//		DWR = (1'b1 && (!SPCDIS));
//		DAD = DAD + 32'd1;
//		DO = {28'b0, state}; // end of pause cycle
//	end
//4'd14:
//	begin
//		DWR = 1'b0;
//		DAD = DAD ;
//		DO = 32'd0;
//	end
4'd15:
	begin
		DWR = (1'b1 && (!SPCDIS));
		DAD = DAD + 32'd1;
		DO = {ADDR, 21'd0, state} ;
	end
endcase

end

end








///**********************************************************///


// DOI, DOR, ADDR at output (no READY) and SHIFT, DR, DI at input

// added signals

wire [nb-1:0] DIA;
wire [nb-1:0] DRA;
wire [3:0] SHIFTA;
 
wire [nb+3:0] DOIA;
wire [nb+3:0] DORA;
wire [6:0] ADDRA;

// boundary scan signals

wire Scan_en, Hold_en_incell, Hold_en_outcell;
wire test_din, test_dout;
wire Bypass_d, Bypass_q;
wire WIR_din, WIR_2_q, WIR_1_q, WIR_dout;

wire [81:0] CTI; // first DR, DI, SHIFT, ADDR, DOI, DOR

wire CK; 



// design
FFT128 U1(CLK, RST, ED, START, SHIFTA, DRA, DIA, RDY, OVF1, OVF2, ADDRA, DORA, DOIA); 

debug_FFT F1(CLK, MRST, START, SHIFT, DR, DI, RDY, OVF1, OVF2, ADDR, DOR, DOI, DBus, Sel, EV, Val, TP1, TPE1);

// no need of CLK to be anded with ED (like pause) as ED is an input to the block itself from beginning



// all the boundary scan stuff

assign CK = ((CLK && ED) || SPCDIS);
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

// connecting the wrapper boundary registers

WBC WBC_I1(.clk(CK), .CTI(test_din), .CFI(DR[0]), .Scan_en(Scan_en), .Hold_en(Hold_en_incell), .CTO(CTI[0]), .CFO(DRA[0]));

genvar i;
generate
for (i = 0; i<15; i=i+1)
begin
WBC WBC_DR(.clk(CK), .CTI(CTI[i]), .CFI(DR[i+1]), .Scan_en(Scan_en), .Hold_en(Hold_en_incell), .CTO(CTI[i+1]), .CFO(DRA[i+1]));
end
endgenerate

generate
for (i = 0; i<16; i=i+1)
begin
WBC WBC_DI(.clk(CK), .CTI(CTI[i+15]), .CFI(DI[i]), .Scan_en(Scan_en), .Hold_en(Hold_en_incell), .CTO(CTI[i+1+15]), .CFO(DIA[i]));
end
endgenerate

generate
for (i = 0; i<4; i=i+1)
begin
WBC WBC_SHIFT(.clk(CK), .CTI(CTI[i+31]), .CFI(SHIFT[i]), .Scan_en(Scan_en), .Hold_en(Hold_en_incell), .CTO(CTI[i+1+31]), .CFO(SHIFTA[i]));
end
endgenerate

generate
for (i = 0; i<7; i=i+1)
begin
WBC WBC_ADDR(.clk(CK), .CTI(CTI[i+35]), .CFI(ADDRA[i]), .Scan_en(Scan_en), .Hold_en(Hold_en_outcell), .CTO(CTI[i+1+35]), .CFO(ADDR[i]));
end
endgenerate

generate
for (i = 0; i<20; i=i+1)
begin
WBC WBC_DOI(.clk(CK), .CTI(CTI[i+42]), .CFI(DOIA[i]), .Scan_en(Scan_en), .Hold_en(Hold_en_outcell), .CTO(CTI[i+1+42]), .CFO(DOI[i]));
end
endgenerate

generate
for (i = 0; i<19; i=i+1)
begin
WBC WBC_DOR(.clk(CK), .CTI(CTI[i+62]), .CFI(DORA[i]), .Scan_en(Scan_en), .Hold_en(Hold_en_outcell), .CTO(CTI[i+1+62]), .CFO(DOR[i]));
end
endgenerate

WBC WBC_O1(.clk(CK), .CTI(CTI[81]), .CFI(DORA[19]), .Scan_en(Scan_en), .Hold_en(Hold_en_outcell), .CTO(test_dout), .CFO(DOR[19]));

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




 







