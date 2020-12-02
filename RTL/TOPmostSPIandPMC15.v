 `timescale 1 ns / 1 ps
`include "FFT128_CONFIG.inc"
`include "./dlx.defines"
`include "spi_defines.v"
`include "timescale.v"

// connection FFT - DLX - AES - (probably USB)-external (F - D - A)
// same clocks for all modules

// adding the securitypolicycontroller
// needs to modify the DAAddrESP to other types (FFT-DLX-AES etc)

module TOPmost(MASRST, CLKF, RSTF, EDF, STARTF, SHIFTF, DRF, DIF, RDYF, DORF, DOIF, WSIF, WRSTNF, SelectWIRF, ShiftWRF, CaptureWRF, MRSTD, DAddrED, DReadED, DWriteED, DAddrE2D, DReadE2D, DWriteE2D, DAddrE3D, DReadE3D, DWriteE3D, DAddrD, DOutD, DInD, IAddrD, IInD, IAddrED, IInED, IWriteED, WRSTND, SelectWIRD, ShiftWRD, CaptureWRD, PauseD, LDSD, LDFD, MACcalcD, MACactualD, modeA, rstA, kldA, ldA, doneA, keyA, text_inA1, text_outA, PauseA, WRSTNA, SelectWIRA, ShiftWRA, CaptureWRA,WSOA,rstS, weS, tx_selS, goS, intS, ssS, sclkS, mosiS, misoS, PauseS, resPMC, PF, PD, PM, PA, PS, DAddrSP, DOutSP, DInSP, IInSP, MRSTSP, WRSTNSP, SelectWIRSP, ShiftWRSP, CaptureWRSP, WSOSP, MRSTDAP, DB1, DB2, s1, s2, MRST11, stop, MRST12, TP11, TPE11);

`FFT128paramnb

//input [3:0] STATE1;
// for FFT
input CLKF, RSTF, EDF, STARTF, MASRST;
input [3:0] SHIFTF ;	
input [nb-1:0] DRF ;	
input [nb-1:0] DIF ;
output RDYF;
output [nb+3:0] DORF;
output [nb+3:0] DOIF;
input WSIF, WRSTNF, SelectWIRF, ShiftWRF, CaptureWRF;
wire SPCREQF, SPCDISF;
input MRST12;


// for DLX
input MRSTD, DReadED, DWriteED, DReadE2D, DWriteE2D, DReadE3D, DWriteE3D ;
input [`WordSize] DAddrED, DAddrE2D, DAddrE3D;
output [`WordSize] DAddrD, DOutD, DInD, IAddrD, IInD;
input WRSTND, SelectWIRD, ShiftWRD, CaptureWRD;
input MRST11;
input stop;

input [`WordSize] IInED, IAddrED;
input IWriteED;

input MACcalcD; //ideally from crypto core (MAC or simething)
input MACactualD; // actual MAC for firmwire

input PauseD;
wire SPCREQD, SPCDISD; // SPC stuff will not be inputs to module in future

input LDFD, LDSD;


// for AES
input rstA, modeA, ldA, kldA;
input [127:0] keyA;
output doneA;
output [127:0] text_outA;
output [127:0] text_inA1;
input PauseA; 
wire SPCREQA, SPCDISA; // SPC stuff will not be inputs to module in future
input WRSTNA, SelectWIRA, ShiftWRA, CaptureWRA;
output WSOA;

// for the security policy controller
input MRSTSP;
output [`WordSize] DAddrSP, DOutSP, DInSP, IInSP;
input WRSTNSP, SelectWIRSP, ShiftWRSP, CaptureWRSP;
output WSOSP;
 

// for SPI
input rstS, weS;
input [3:0] tx_selS;
input goS;
output intS;
output ssS, sclkS, mosiS;
input misoS;

input PauseS;
wire SPCREQS, SPCDISS;

// for PMC

input resPMC;
output PF,PD,PM,PA,PS;


wire [3:0] STATE;
// other module signal definitions
// for FFT
wire OVF1F, OVF2F, WSOF;
wire [6:0] ADDRF;
wire [`WordSize] DAD1, DO1;
wire DWR1;
//DLX
// DOutED and WSID comes from FFT module

//wire [`WordSize] IAddrED, IInED; // changed this one
wire [`WordSize] DOutED1, DInED, DInE2D, DInE3D;
reg [`WordSize] DOutED, DOutE2D, DOutE3D; //** after doing simulations **//
wire DReadD, DWriteD;
wire WSID, WSOD;
wire PH; // separate clock domain for DLX
wire [`WordSize] DAD2, DO2;
wire DWR2;

// AES

wire [127:0] text_inA;
wire WSIA;
wire [`WordSize] DAD3, DO3;
wire DWR3;

// SPI

reg [31:0] dati;
wire [`SPI_DIVIDER_LEN-1:0] divider;
reg [127:0]CS;
wire [`WordSize] DAD4, DO4;
wire DWR4;

// Security Policy Controller

wire [`WordSize] DAddrESP, DOutESP,  IAddrSP, IAddrESP, IInESP ;
wire DReadSP, DWriteSP, IReadSP, WSISP, PH11;

// connections between involving DAddrED, DOutD (introduce DReadED....) [done]

// DAP Port
input MRSTDAP, s1, s2;
input [31:0] DB1, DB2;

wire [31:0] DBus;
wire [1:0] Sel;
wire [31:0] TP;
wire TPE;

output reg [63:0] TP11;
output reg TPE11;

wire [31:0] TP2;
wire TPE2;

wire [31:0] TP3;
wire TPE3;

wire [31:0] TP4;
wire TPE4;

wire [31:0] TP5;
wire TPE5;

wire [31:0] TP6;
wire TPE6;




assign TP2 = TP;
assign TPE2 = TPE;

// module instantiations
FFT128wrapper F0(MASRST, CLKF, RSTF, EDF, STARTF, SHIFTF, DRF, DIF, RDYF, OVF1F, OVF2F, ADDRF, DORF, DOIF, WSIF, WRSTNF, SelectWIRF, ShiftWRF, CaptureWRF, WSOF, DWR1, DO1, DAD1, SPCREQF, SPCDISF, MRST12, DBus, Sel, TP3, TPE3);

//assign DOutED = ([DORF[15:0] DOIF[15:0]]); // check this
// **** a work around ***************** //

always @(*)
begin
if (!(DORF == 20'b0))
begin
DOutE2D[31:16]  = DORF[15:0];
DOutE2D[15:0] = DOIF[15:0];
end
end


assign DOutED1[31:16] = DORF[15:0];
assign DOutED1[15:0] = DOIF[15:0];
assign WSID = WSOF;

clkgen CLKGEN(
	.clk  (PH)
);
together T0(
	PH,  MASRST, DAddrD, DAddrED, DAddrE2D, DAddrE3D, DReadD, DWriteD, DReadED, DWriteED, DReadE2D, DWriteE2D, DReadE3D, DWriteE3D, DOutD, DOutED, DOutE2D, DOutE3D, DInD, DInED, DInE2D, DInE3D, STATE, IAddrD, IAddrED, , IInD, IInED, IWriteED,             	MRSTD, PauseD, `LogicZero, `LogicZero, `LogicZero, , WSID, WRSTND, SelectWIRD, ShiftWRD, CaptureWRD, WSOD, DWR2, DO2, DAD2, SPCREQD, SPCDISD, LDSD, LDFD, MACcalcD, MACactualD, DBus, Sel, TP, TPE, MRST11, stop, TP5, TPE5);

//assign text_inA = ([DInED DInED DInED DInED]);
assign text_inA[127:96] = DInED;
assign text_inA[31:0] = DInED;
assign text_inA[63:32] = DInED;
assign text_inA[95:64] = DInED;
//assign text_inA[127:96] = DInED;
//assign text_inA[31:0] = 32'b1;
//assign text_inA[63:32] = 32'b1;
//assign text_inA[95:64] = 32'b1;
//assign text_inA[127:96] = 32'b1;
assign WSIA = WSOD;
assign text_inA1 = text_inA;

AEStopwrapper A0(MASRST, CLKF, modeA, rstA, kldA, ldA, doneA, keyA, text_inA, text_outA, PauseA, WSIA, WRSTNA, SelectWIRA, ShiftWRA, CaptureWRA, WSOA, DWR3, DO3, DAD3, SPCREQA, SPCDISA, MRST11, DBus, Sel, TP4, TPE4);

assign divider = 16'b1; // SCLK is 1/4 th that of CLK

always @(*)
begin
if (doneA == 1'b1)
CS = text_outA;
end

always @(*)
begin
if (tx_selS == 4'b0001)
begin
dati = CS[31:0];
end
else if (tx_selS == 4'b0010)
begin
dati = CS[63:32];
end
else if (tx_selS == 4'b0100)
begin
dati = CS[95:64];
end
else if (tx_selS == 4'b1000)
begin
dati = CS[127:96];
end
end



//spi_top ST0(MASRST, CLKF, rstS, , dati, , weS, goS, divider, tx_selS, , ,ack, , intS, ssS, sclkS, mosiS, misoS); 

spi_top ST0(MASRST, CLKF, rstS, , dati, , weS, goS, divider, tx_selS, , ,ack, , intS, ssS, sclkS, mosiS, misoS, DWR4, DO4, DAD4, PauseS, SPCREQS, SPCDISS, MRST11, DBus, Sel, TP6, TPE6); 

PMC PM0(MASRST, CLKF, resPMC, RSTF, STARTF, MRSTD, DReadED, DWriteED, rstA, ldA, rstS, goS, PF,PD,PM,PA,PS);

// security policy controller

assign WSISP = WSOA;
clkgen CLKGEN1(
	.clk  (PH11)
);

securitypolicy SP0(
	PH11, MASRST, DAddrSP, DAD1, DAD2, DAD3, DAD4, , DReadSP, DWriteSP, DWR1, DWR2, DWR3, DWR4 , ,DOutSP, DO1, DO2, DO3, DO4 , ,  DInSP, IAddrSP, IAddrESP, IReadSP, IInSP, IInESP, MRSTSP, , , , ,WSISP, WRSTSP, SelectWIRSP, ShiftWRSP, CaptureWRSP, WSOSP, 
STATE, SPCDISF, SPCDISD, SPCDISA, SPCDISS, SPCREQF, SPCREQD, SPCREQA, SPCREQS);


// Debug Access Port

DAP D1 (CLKF, MRSTDAP, s1, s2, DB1, DB2, DBus, Sel);

reg [27:0] globalcounter;

always @(posedge CLKF)
begin
if (MASRST == 1'b1)
begin
globalcounter <= 28'd0;
end

else
begin
globalcounter <= globalcounter + 28'b1;
end
end

// trace port configurations

//reg [31:0] tracebuffer [0:15];

always @(posedge CLKF)
begin
if (MASRST == 1'b1)
begin
TP11 <= 64'd0;
TPE11 <= 1'b0;
end

else if (TPE2 == 1'b1)
begin
TPE11 <= 1'b1;
TP11 <= {TP2, globalcounter, 4'b0001};
end

else if (TPE5 == 1'b1) 
// assuming data memory and proc events of ineterst do not //overlap 
begin
TPE11 <= 1'b1;
TP11 <= {TP5, globalcounter, 4'b0010};
end


else if (TPE3 == 1'b1)
begin
TPE11 <= 1'b1;
//TP11 <= {TP3, (globalcounter - 28'b1), 4'b0011};
TP11 <= {TP3, (globalcounter), 4'b0011};
end

else if (TPE4 == 1'b1)
begin
TPE11 <= 1'b1;
//TP11 <= {TP4, (globalcounter - 28'b1), 4'b0100};
TP11 <= {TP4, (globalcounter), 4'b0100};
end

else
begin
TP11 <= 64'd0;
TPE11 <= 1'b0;
end

end 




endmodule
