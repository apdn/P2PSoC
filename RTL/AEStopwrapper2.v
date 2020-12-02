`timescale 1ns/1ps

module AEStopwrapper(MASRST, clk, mode, rst, kld, ld, done, key, text_in, text_out, Pause, WSI, WRSTN, SelectWIR, ShiftWR, CaptureWR, WSO, DWR, DO, DAD, SPCREQ, SPCDIS, MRST, DBus, Sel, TP1, TPE1);

input clk, rst, mode, ld, kld, MASRST;
output done;

input SPCREQ;
input SPCDIS;

input	[127:0]	key;
input	[127:0]	text_in;
output	[127:0]	text_out;
input Pause; // my input

input WSI, WRSTN, SelectWIR, ShiftWR, CaptureWR;
output WSO;

input MRST;
input [31:0] DBus;
input [1:0] Sel;
output [31:0] TP1;
output TPE1;


// only functional inputs/outputs are in wrapper boundary 

wire [127:0] text_out1;

wire [127:0] text_inA;
wire [127:0] keyA;
wire [127:0] text_outA;
wire Scan_en, Hold_en_incell, Hold_en_outcell;
wire test_din, test_dout;
wire Bypass_d, Bypass_q;
wire WIR_din, WIR_2_q, WIR_1_q, WIR_dout;

wire [382:0] CTI; // first input, key, and finally output

wire CK; // scan clock here equal to functional clock

// first method of replicating

// Debug - SPC interface and storage
wire [7:0] EV;
wire [31:0] Val;
reg [31:0] tempbuff[0:3];
reg [1:0] cru;

always @(posedge clk)
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

reg [7:0] EV2;

always @(posedge clk)
begin
EV2 <= EV;
end


// SPCREQ is SPC asking for info and SPCDIS is disabling the AES fully
// first the design
// generating EN inside




reg EN;
reg cert;



wire [31:0] w01, w02, w03, w04;

assign text_outA = EN? text_out1:128'b0;
aes_encoder_decoder AES(.clk(clk && Pause && cert), .mode(mode),.rst(rst && SPCDIS), .kld(kld),.ld(ld), .done(done), .key(keyA), .text_in(text_inA),
.text_out(text_out1), .w01(w01), .w02(w02), .w03(w03), .w04(w04));

debug_AES A0 (clk, MRST, mode, ld, Pause, done, keyA, text_inA, text_out1, DBus, Sel, EV, Val, TP1, TPE1, w01, w02, w03, w04);


////added signals to interface with security policy controller THE SECURITY
//WRAPPER
///**********************************************************///
output reg DWR;
output reg [31:0]DO, DAD;

reg ld1;
reg rst1;
reg Pause1;



reg resultcheck;


// logic for writing new info into the SPC Controller data cache
always @(posedge clk)
begin
ld1 <= ld;
rst1 <= rst;
Pause1 <= Pause;
end

reg [3:0] counter2;
reg [3:0] state;
reg [127:0] buff[0:3];



always @(posedge clk)
begin
 if (((ld1 == 1'b1) && (ld == 1'b0) && (rst == 1'b1)&& (Pause == 1'b1) && (cert == 1'b1))||(counter2 == 4'd11))
begin
	counter2 <= 4'd0;
end

else if ((counter2 < 4'd12) && (Pause == 1'b1) && (cert == 1'b1) && (rst && SPCDIS == 1'b1) && (ld == 1'b0))  // from the loading of b in the counter field
begin
	counter2 <= counter2 + 4'd1;
end

end

/// the certification
always @(posedge clk)
begin
	if (MASRST == 1'b1)
	begin
		cert <= 1'b1;
	end
	else if ((ld1 == 1'b1) && (ld == 1'b0) && (rst == 1'b1)&& (Pause == 1'b1))
	begin
		cert <= 1'b0;
	end
	else if (resultcheck == 1'b1) // verifying if the key meets randomness criteria (local implementation , doesnot have to send to SPC) 
	begin
		cert <= 1'b1;
	end
end
// random result check logic (very simple now)
//
always @(posedge clk)
begin
	if (cert == 1'b0)
	begin
//	if ((keyA[127:64] == keyA[63:0]) && !((buff[2*(pastcount-1)] == keyA))) // verify the multiplication
	if (!(keyA[127:64] == keyA[63:0]))
	begin
        resultcheck = 1'b1;
end
else
begin
	resultcheck = 1'b0;
end
end

end

/// The past values storage

reg [1:0] pastcount;
always @(*)
begin
if ((ld1 == 1'b1) && (ld == 1'b0) && (rst == 1'b1)&& (Pause == 1'b1))
begin
pastcount = pastcount + 2'd1;
end
else if (MASRST == 1'b1)
begin
	pastcount = 2'd0;
end
end // need to incorporate a MASTER RESET signifying boot FROM SYTEM CONTROLLER
 

// what about the buffer

always @(pastcount) // should ideally be always @(pastcount)
//begin
//if  ((ld1 == 1'b1) && (ld == 1'b0) && (rst == 1'b1)&& (Pause == 1'b1)) // start of operation
begin
	if (pastcount > 2'd0)
begin
buff[2*pastcount-1] <= text_inA;
buff[2*pastcount] <= keyA;
end
//end
end // need to incorporate a MASTER RESET FROM SYTEM CONTROLLER



// the enable control

always @(posedge clk)
	begin
if ((WRSTN == 1'b1) && (ShiftWR == 1'b0)) // normal mode (can be in other terms as well)
begin
if (done == 1'b1)
begin
	EN <= 1'b1;
end
else
begin
	EN <= 1'b0;
end

end
else
begin
	EN <= 1'b1;  // test modes where every text_out needs to be seen
end

end


// now the control state machine
//
always @(posedge clk)
begin
		if (MASRST == 1'b1)
	begin
         state <= 4'd0;
        end

else if ((WRSTN == 1'b1) && (ShiftWR == 1'b0)) // normal mode (CHECK THIS)
begin

if ((ld1 == 1'b1) && (ld == 1'b0) && (rst == 1'b1)&& (Pause == 1'b1))
begin
	state <= 4'd1; 
end
else if (counter2 == 4'd1)
begin
	state <= 4'd2; // perhaps telling if key and/or plaintext is same as last time (to prevent any chance of replay attack (NONCE)) as well as sending result of certofocation
end
//else if ((counter2 == 4'd11) // end of operation
else if (done == 1'b1) 
begin
	state <= 4'd3;
end
else if ((Pause1 == 1'b1) && (Pause == 1'b0))
begin
	state <= 4'd4;
end
else if ((Pause1 == 1'b0) && (Pause == 1'b1))
begin
	state <= 4'd5;
end
else if (SPCREQ == 1'b1) // need to add this
begin
	state <= 4'd14;
end
else if (EV > 8'd0)
begin
	state <= 4'd7;
end
else 
begin
	state <= 4'd6;
end

end

else                 //////// TEST MODE
begin
state <= 4'd0;

//	if ((ld1 == 1'b1) && (ld == 1'b0) && (rst == 1'b1)&& (Pause == 1'b1))
//begin
//	state <= 4'd7; 
//end
//else if (counter2 == 4'd1)
//begin
//	state <= 4'd8; // perhaps telling if key and/or plaintext is same as last time (to prevent any chance of replay attack (NONCE)) as well as sending result of certofocation
//end
////else if ((counter2 == 4'd11) // end of operation
//else if (done == 1'b1) 
//begin
//	state <= 4'd9;
//end
//else if ((Pause1 == 1'b1) && (Pause == 1'b0))
//begin
//	state <= 4'd10;
//end
//else if ((Pause1 == 1'b0) && (Pause == 1'b1))
//begin
//	state <= 4'd11;
//end
//else if (SPCREQ == 1'b1) // need to add this
//begin
//	state <= 4'd12;
//end
//else 
//begin
//	state <= 4'd13;
//end

end

end

always @(state)
begin

//if ((SPCDIS && cert) == 1'b1) // an addition (CAN REMOVE THE DWR ADDITIONS LATER)
//begin
	case(state)
4'd0:	begin
		DWR = 1'b0;
		DAD = 32'd0;
                DO = 32'd0;
	end
4'd1:	begin
		DWR = 1'b1;
		DAD = 32'd80;
                DO = {mode, 27'b0, state};
	end
4'd2:	begin
		DWR = (1'b1 && cert && SPCDIS);
		DAD = DAD + 32'd1;
                DO = {resultcheck, 27'b0, state};
	end
4'd3:	begin
		DWR = (1'b1 && cert && SPCDIS);
		DAD = DAD + 32'd1;
                DO = {28'b0, state};
	end
4'd4:	begin
		DWR = (1'b1 && cert && SPCDIS);
		DAD = DAD + 32'd1;
                DO = {counter2, 24'd0, state};
	end
4'd5:	begin
		DWR = (1'b1 && cert && SPCDIS);
		DAD = DAD + 32'd1;
                DO = {28'd0, state};
	end
4'd6:	begin
		DWR = 1'b0;
		DAD = DAD;
                DO = 32'd0;
	end
4'd7:	begin
		DWR = (1'b1 && cert && SPCDIS);
		DAD = DAD + 32'd1;
                DO = {counter2, 16'd0, EV2, state};
	end
//4'd8:	begin
//		DWR = (1'b1 && cert && SPCDIS);
//		DAD = DAD + 32'd1;
//                DO = {resultcheck, 27'b0, state};
//	end
//4'd9:	begin
//		DWR = (1'b1 && cert && SPCDIS);
//		DAD = DAD + 32'd1;
//                DO = {28'b0, state};
//	end
//4'd10:	begin
//		DWR = (1'b1 && cert && SPCDIS);
//		DAD = DAD + 32'd1;
//                DO = {counter2, 24'd0, state};
//	end
//4'd11:	begin
//		DWR = (1'b1 && cert && SPCDIS);
//		DAD = DAD + 32'd1;
//                DO = {28'd0, state};
//	end
//4'd12:	begin
//		DWR = (1'b1 && cert && SPCDIS);
//		DAD = DAD + 32'd1;
//                DO = {text_out1[15:0], counter2, 8'b0, state};
//	end
//4'd13:	begin
//		DWR = 1'b0;
//		DAD = DAD;
//                DO = 32'd0;
//	end
4'd14:	begin
		DWR = (1'b1 && cert && SPCDIS);
		DAD = DAD + 32'd1;
                DO = {text_out1[15:0], counter2, 8'b0, state};
	end
// fill in the rest of the stuff	
endcase

//end

end


///**********************************************************///

// all the boundary scan stuff

assign CK = (clk && Pause && SPCDIS);
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

//Input Wrapper Boundary Register
WBC WBC_I1(.clk(CK), .CTI(test_din), .CFI(text_in[0]), .Scan_en(Scan_en), .Hold_en(Hold_en_incell), .CTO(CTI[0]), .CFO(text_inA[0]));


// second method of replicating

genvar i;
generate
for (i = 0; i<127; i=i+1)
begin
WBC WBC_I(.clk(CK), .CTI(CTI[i]), .CFI(text_in[i+1]), .Scan_en(Scan_en), .Hold_en(Hold_en_incell), .CTO(CTI[i+1]), .CFO(text_inA[i+1]));
end
endgenerate

//genvar i;
generate
for (i = 0; i<128; i=i+1)
begin
WBC WBC_K(.clk(CK), .CTI(CTI[i+127]), .CFI(key[i]), .Scan_en(Scan_en), .Hold_en(Hold_en_incell), .CTO(CTI[i+1+127]), .CFO(keyA[i]));
end
endgenerate

//genvar i;
generate
for (i = 0; i<127; i=i+1)
begin
WBC WBC_O(.clk(CK), .CTI(CTI[i +255]), .CFI(text_outA[i]), .Scan_en(Scan_en), .Hold_en(Hold_en_outcell), .CTO(CTI[i+1 +255]), .CFO(text_out[i]));
end
endgenerate


WBC WBC_O1(.clk(CK), .CTI(CTI[382]), .CFI(text_outA[127]), .Scan_en(Scan_en), .Hold_en(Hold_en_outcell), .CTO(test_dout), .CFO(text_out[127]));

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


