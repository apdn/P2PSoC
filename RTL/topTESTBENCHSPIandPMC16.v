`timescale 1 ns / 1 ps
`include "FFT128_CONFIG.inc"
`include "./dlx.defines"
`include "spi_defines.v"
`include "timescale.v"


module test;
	`FFT128paramnb	
// FFT signals
reg MASRST;
reg CLKF, RSTF, EDF, STARTF;
reg [3:0] SHIFTF;
reg [nb-1:0] DRF;
reg [nb-1:0] DIF;
wire RDYF;
wire [nb+3:0] DOIF;
wire [nb+3:0] DORF;
reg WSIF, WRSTNF, SelectWIRF, ShiftWRF, CaptureWRF;
reg SPCREQF, SPCDISF; // now keeping it as external signal

// DLX signals (2 - FFT, E - AES)
reg MRSTD, DReadED, DWriteED, DReadE2D, DWriteE2D, DReadE3D, DWriteE3D;
reg [`WordSize] DAddrED, DAddrE2D, DAddrE3D;
wire [`WordSize] DAddrD, DOutD, DInD, IAddrD, IInD;
reg WRSTND, SelectWIRD, ShiftWRD, CaptureWRD;
reg [4:0] 		i;
reg [`WordSize] IInED, IAddrED;
reg IWriteED;
//reg [3:0] STATE1; // just for a small test

reg PauseD;
reg SPCDISD, SPCREQD;

reg LDSD, LDFD;

reg MACcalcD, MACactualD;

//AES
reg rstA, modeA, ldA, kldA;
reg [127:0] keyA;
wire doneA;
wire [127:0] text_outA;
wire [127:0] text_inA1;
reg PauseA;
reg SPCREQA, SPCDISA; // now keeping it as external signal
reg WRSTNA, SelectWIRA, ShiftWRA, CaptureWRA;
wire WSOA;

// SPI

reg rstS, weS, goS, misoS;
reg [3:0] tx_selS;
wire intS, ssS, sclkS, mosiS;
reg PauseS;
reg SPCDISS, SPCREQS;

// PMC

wire PF, PD, PM, PA, PS;
reg resPMC;

// Security Policy Controller

reg MRSTSP;
wire [`WordSize] DAddrSP, DOutSP, DInSP, IInSP, WSOSP;
reg WRSTNSP, SelectWIRSP, ShiftWRSP, CaptureWRSP;

// DAP

reg MRSTDAP, s1,s2;
reg [31:0] DB1, DB2;
reg MRST11;
reg stop;

//wire [31:0] TP2;
//wire TPE2;

//wire [31:0] TP3;
//wire TPE3;
reg MRST12;

//wire [31:0] TP4;
//wire TPE4;

wire [31:0] TP11;
wire TPE11;
// module instantiation
TOPmost TM0(MASRST, CLKF, RSTF, EDF, STARTF, SHIFTF, DRF, DIF, RDYF, DORF, DOIF, WSIF, WRSTNF, SelectWIRF, ShiftWRF, CaptureWRF, MRSTD, DAddrED, DReadED, DWriteED, DAddrE2D, DReadE2D, DWriteE2D, DAddrE3D, DReadE3D, DWriteE3D, DAddrD, DOutD, DInD, IAddrD, IInD, IAddrED, IInED, IWriteED, WRSTND, SelectWIRD, ShiftWRD, CaptureWRD, PauseD, LDSD, LDFD, MACcalcD, MACactualD, modeA, rstA, kldA, ldA, doneA, keyA, text_inA1, text_outA, PauseA, WRSTNA, SelectWIRA, ShiftWRA, CaptureWRA,WSOA, rstS, weS, tx_selS, goS, intS, ssS, sclkS, mosiS, misoS, PauseS, resPMC, PF, PD, PM, PA, PS, DAddrSP, DOutSP, DInSP, IInSP, MRSTSP, WRSTNSP, SelectWIRSP, ShiftWRSP, CaptureWRSP, WSOSP, MRSTDAP, DB1, DB2, s1, s2, MRST11, stop, MRST12, TP11, TPE11);


initial
begin
CLKF = 1'b0;
forever
begin
#1 CLKF = !CLKF;
end
end




// monitor mode (atleast initially)
initial
begin
// signal values given (normal functional mode)
// initialization
// FFT
MASRST = 1'b1;

//STATE = 4'd3;

//STATE1 = 4'd0;


RSTF = 1'b1;
STARTF = 1'b1;
EDF = 1'b1;
SHIFTF = 4'b1010;
DRF = 16'b1000111000001111;
DIF = 16'b1111000001011010;
WRSTNF = 1'b1;
ShiftWRF = 1'b0; // CGHANGED IN THIS VERSION IN ALL
CaptureWRF = 1'b1;
SelectWIRF = 1'b1;
WSIF = 1'b1;
#2 WSIF = 1'b1;
#2 WSIF = 1'b1;
#8 SelectWIRF = 1'b0;
SPCREQF = 1'b0;
SPCDISF = 1'b0; // the logic level is reverse as compared to AES and DLX

// DLX

	 force TM0.T0.DLX.part2_ID.RegFile.WE = 0 ;
	 for (i = 0; i < 24; i = i+1) 
	    begin
	       force TM0.T0.DLX.part2_ID.RegFile.W = i ;
	       force TM0.T0.DLX.part2_ID.RegFile.IN0 = 0 ;
	       #2 force TM0.T0.DLX.part2_ID.RegFile.WE = 1 ;  
	       #2 force TM0.T0.DLX.part2_ID.RegFile.WE = 0 ;  
	       
	    end
	 
	 #4 release TM0.T0.DLX.part2_ID.RegFile.W;
	 release TM0.T0.DLX.part2_ID.RegFile.IN0;
	 release TM0.T0.DLX.part2_ID.RegFile.WE;
	 $display("Starting simulation.");
MRSTD = `LogicZero;
DAddrED = 32'd2;
DAddrE2D = 32'd1;
DReadED = `LogicZero;
DWriteED = `LogicZero;
DReadE2D = `LogicZero;
DWriteE2D = `LogicZero;
WRSTND = 1'b1;
ShiftWRD = 1'b0;
CaptureWRD = 1'b1;
SelectWIRD = 1'b1;
#8 SelectWIRD = 1'b0;

IAddrED = 32'd0;
IInED =  32'd0;
IWriteED = 1'b0;

PauseD = 1'b1;
LDSD = 1'b0;
LDFD = 1'b0;
SPCDISD = 1'b1;
SPCREQD = 1'b0;
MACcalcD = 1'b1;
MACactualD = 1'b1;

// AES
rstA = 1'b0;
modeA = 1'b1;
//ENA = 1'b1;
PauseA = 1'b1;
SPCREQA = 1'b0;
SPCDISA = 1'b1;
keyA = 128'd39851273900764;
ldA = 1'b0;
WRSTNA = 1'b1;
ShiftWRA = 1'b0;
CaptureWRA = 1'b1;
SelectWIRA = 1'b1;
#8 SelectWIRA = 1'b0;

// SPI
rstS = 1'b1;
weS = 1'b1;
goS = 1'b0;
tx_selS = 4'b0001;
PauseS = 1'b1;
SPCREQS = 1'b0;
SPCDISS = 1'b0;


// security policy controller

 force TM0.SP0.DLX11.part2_ID.RegFile.WE = 0 ;
	 for (i = 0; i < 24; i = i+1) 
	    begin
	       force TM0.SP0.DLX11.part2_ID.RegFile.W = i ;
	       force TM0.SP0.DLX11.part2_ID.RegFile.IN0 = 0 ;
	       #2 force TM0.SP0.DLX11.part2_ID.RegFile.WE = 1 ;  
	       #2 force TM0.SP0.DLX11.part2_ID.RegFile.WE = 0 ;  
	       
	    end
	 
	 #4 release TM0.SP0.DLX11.part2_ID.RegFile.W;
	 release TM0.SP0.DLX11.part2_ID.RegFile.IN0;
	 release TM0.SP0.DLX11.part2_ID.RegFile.WE;  
	 
MRSTSP = `LogicZero;                                                                                                                                                    
	 
WRSTNSP = 1'b1;
ShiftWRSP = 1'b0;
CaptureWRSP = 1'b1;
SelectWIRSP = 1'b1;
#8 SelectWIRSP = 1'b0;

// DAP
MRSTDAP = 1'b0;
DB1 = 32'b0;
DB2 = 32'b0;
s1 = 1'b1;
s2 = 1'b1;
#40 MRSTDAP = 1'b1;
MRST11 = 1'b0;
MRST12 = 1'b0;
stop = 1'b0;
//s2 = 1'b1; 
//s1 = 1'b1;
#20 MRST11 = 1'b1;
//#20 MRST12 = 1'b1;
MRST12 = 1'b1;


//#20 DB2 = 32'b10000000000000000000000001000000; // SPI
//#20 DB2 = 32'b00000000000000000000000000000010;
//#20 DB2 = 32'b10000000000000000000000001000001;
//#20 DB2 = 32'b00000000000000000000000000001000;

#20 DB1 = 32'b10000000000000000000000000100000; // AES
#20 DB1 = 32'b00000000000000000000000000001011;
#20 DB1 = 32'b10000000000000000000000000100001;
#20 DB1 = 32'b00000000000000000000000000000100;

#20 DB1 = 32'b10000000000000000000000000000000; // DLX
#20 DB1 = 32'b00000000000000000000000000100011;
#60 DB1 = 32'b10000000000000000000000000000001;
#20 DB1 = 32'b00000000000000000000000000010000;
#60 DB1 = 32'b10000000000000000000000000000010;
#20 DB1 = 32'b00000000000000000000000000011000;

#20 DB1 = 32'b10000000000000000000000000010000; // FFT
#20 DB1 = 32'b00000000000000000000000000000011;

#20 DB1 = 32'b10000000000000000000000000110000; // mem
#20 DB1 = 32'b00000000000000000000000000000001;
#20 DB1 = 32'b10000000000000000000000000110001;
#20 DB1 = 32'b00000000000000000000000000010000;
#20 DB1 = 32'b10000000000000000000000000110010;
#20 DB1 = 32'b00000000000000000000000000100000;


//#20 DB2 = 32'b10000000000000000000000000010000;
//#20 DB2 = 32'b00000000000000000000000000000100;
//#20 DB2 = 32'b10000000000000000000000000000000;
//#20 DB2 = 32'b00000000000000000000000011000001;
//#60 DB2 = 32'b10000000000000000000000000000001;
//#20 DB2 = 32'b00000000000000000000000000011000;



//#20 DB2 = 32'b10000000000000000000000000000000;
//#20 DB2 = 32'b00000000000000000000000000000100;
//#60 DB2 = 32'b10000000000000000000000000000001;
//#20 DB2 = 32'b00000000000000000000000000000100;
//#40 DB2 = 32'b10000000000000000000000000000010;
//#20 DB2 = 32'b00000000000000000000000000100000;

//#20 DB2 = 32'b10000000000000000000000000000011;
//#20 DB2 = 32'b00000000000000000000000000001100;
//#60 DB2 = 32'b10000000000000000000000000000100;
//#20 DB2 = 32'b00000000000000000000000000000010;




//PMC

resPMC = 1'b1;

#2 resPMC = 1'b0;

MASRST = 1'b0;



//#60 MRSTSP = `LogicOne; // NEW POSITION

// MRSTSP = `LogicOne; // causing error while revisiting

// enable logic
//#2 RSTF = 1'b0;
#300 RSTF = 1'b0;
#2 STARTF = 1'b0;

//#4 STARTF = 1'b1;
//#3 RSTF = 1'b1;

//#300 SPCDISF = 1'b1;

//#120 SPCDISF = 1'b0; // changing SPCDISF starts the thing from beginning, but RDY is still asserted, but no DOI and DOR!!!!! need for STARTF to go from 1 to 0 again to start

#400 SPCREQF = 1'b1;
#20 SPCREQF = 1'b0;


//#200 EDF = 1'b0;
//#40 EDF = 1'b1;

//#2 STARTF = 1'b1;
//#2 STARTF = 1'b0;


MRSTSP = `LogicOne; // NEW POSITION


#200 LDSD = 1'b1;
////// load the instruction cache of the normal DLX processor with instructions

//LDSD = 1'b1;

IInED = 32'b10101100010000010000000000000000;
IWriteED = 1'b1;
#20 IWriteED = 1'b0;
#1 IAddrED = 32'd1;
IInED = 32'b00000000000000000000000000000000;
IWriteED = 1'b1;
#20 IWriteED = 1'b0;
#1 IAddrED = 32'd2;
IInED = 32'b00000000000000000000000000000000;
IWriteED = 1'b1;
#20 IWriteED = 1'b0;
#1 IAddrED = 32'd3;
IInED = 32'b00000000000000000000000000000000;
IWriteED = 1'b1;
#20 IWriteED = 1'b0;
#1 IAddrED = 32'd4;
IInED = 32'b00100000001000010000000000000110;
IWriteED = 1'b1;
#20 IWriteED = 1'b0;
#1 IAddrED = 32'd5;
IInED = 32'b00000000000000000000000000000000;
IWriteED = 1'b1;
#20 IWriteED = 1'b0;
#1 IAddrED = 32'd6;
IInED = 32'b00000000000000000000000000000000;
IWriteED = 1'b1;
#20 IWriteED = 1'b0;
#1 IAddrED = 32'd7;
IInED = 32'b00000000000000000000000000000000;
IWriteED = 1'b1;
#20 IWriteED = 1'b0;
#1 IAddrED = 32'd8;
IInED = 32'b11001100100000010000000000000010;
IWriteED = 1'b1;
#20 IWriteED = 1'b0;
#1 IAddrED = 32'd9;
IInED = 32'b00000000000000000000000000000000;
IWriteED = 1'b1;
#20 IWriteED = 1'b0;
#1 IAddrED = 32'd10;
IInED = 32'b00000000000000000000000000000000;
IWriteED = 1'b1;
#20 IWriteED = 1'b0;
#1 IAddrED = 32'd11;
IInED = 32'b00000000000000000000000000000000;
IWriteED = 1'b1;
#20 IWriteED = 1'b0;
//#40 SPCDISF = 1'b0;

LDFD = 1'b1;
#2 LDSD = 1'b0;

// DLX clock domain = 10X 
//#280 DWriteE2D = `LogicOne; //**** time??? 

//#30 DWriteE2D = `LogicOne; //**** time??? 

#10 DWriteE2D = `LogicOne; //**** time??? 

//#574 EDF = 1'b0; // stop the FFT engine to avoid spurious writes
#14 EDF = 1'b0; // stop the FFT engine to avoid spurious writes

// for simultaneous writes to the SPC data memory
//RSTF = 1'b1;
//STARTF = 1'b1;
// simulataneosu operation suppose with DLX (hence after MRSTD)

//#12 DWriteE2D = `LogicZero; // *** time??
#16 DWriteE2D = `LogicZero; // *** time??
#2 MRSTD = `LogicOne; // ***** time for MRST???

// simulatneous operation starts here???
//RSTF = 1'b0;
//#2 STARTF = 1'b0;
//#2 EDF = 1'b1;

#85 PauseD = 1'b0;
#38 PauseD = 1'b1;

//stop = 1'b1;

//#2 SPCDISD = 1'b0;
//#28 SPCDISD = 1'b1;

//#240 MRSTD = 1'b0;
#155 MRSTD = 1'b0;

//stop = 1'b1;
// DAddrED = 32'd2;
#20 DReadED = `LogicOne; // ** time??

#10 rstA = 1'b1;  // ** check times
//#2 rstA = 1'b0;
#1 ldA = 1'b1; 
#6 ldA = 1'b0;
//#4 ldA = 1'b1;

#8 SPCREQA = 1'b1;

#6 SPCREQA = 1'b0;

//SPCDISA = 1'b0;
#5 PauseA = 1'b0;
#5 PauseA = 1'b1;

//#16 PauseA = 1'b0; // could be reset as well

#8 PauseA = 1'b0; // could be reset as well
// SPI
#8 rstS = 1'b0;


//#14 MRSTSP = `LogicOne;
//MRSTSP = `LogicOne;


#2 tx_selS = 4'b0010;
#2 tx_selS = 4'b0100;
#2 tx_selS = 4'b1000;
#2 goS = 1'b1;

//#28 PauseS = 1'b0;
//#20 PauseS = 1'b1;

//#40 SPCDISS = 1'b1;
//#20 SPCDISS = 1'b0;

#2 MRSTSP = `LogicZero;
//#600 MRSTSP = `LogicZero;

end
 
initial
begin
$monitor($time, "FFT, AES SPI engine finish signal %b", RDYF, doneA, intS);
//$monitor($time, "values are %b", TM0.SP0.DLX11.part2_ID.RegFile.IN0);
//$monitor($time, "buffer %b", TM0.ST0.buff[1]);
end

endmodule
