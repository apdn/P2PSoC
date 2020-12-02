// FFT active signal - RSTF from 1-0, STARTF from 1-0 (time is 880+10 clock cycles OR above signals back to 1)
// DLX processor (also ICache) - MRSTD from 0-1 (have to be MRSTD back to 1 as progs are of var length) 
// Memory (DCache) - DReadED and DWriteED must be low (practice should be followed although functionally it might be OK without following it) as well as not (MRSTD from 0-1 i.e. DLX not active)
// AES - rstA from 0-1 and then ldA from 1 to 0 (time is 30 cycles OR above signals back to initial values)
//SPI - rstS from 1-0 and also goS is 1 

//outputs (coarse grained now as one per module and low or high)
// PF, PD, PM, PA, PS 

// res is a boot up signal so that PF,.....etc have initial values 

module PMC(MASRST, clk, res, RSTF, STARTF, MRSTD, DReadED, DWriteED, rstA, ldA, rstS, goS, PF,PD,PM,PA,PS);

input MASRST;

input clk, res, RSTF, STARTF, MRSTD, DReadED, DWriteED, rstA, ldA, rstS, goS;

output PF,PD,PM,PA,PS;

// temporary signals

reg [9:0] FFTcoun;
reg [4:0] AEScoun1;
reg [2:0] AEScoun2;
reg RSTF1, STARTF1; // STARTF  go down in next cycle after RSTF
reg RSTF2, STARTF2; // safe guard band as RSTF abd RSTF1 can change at CLK 
reg C;
reg MRSTD1, MRSTD2;
reg CD;
reg CM, CM1;
reg rstA1, ldA1;
reg rstA2, ldA2; // restrictions on time of ld after rst - relaxed to 8 cycles atleast to avoid any lag or synchronicity probs???
reg CA1;
reg CA2;

reg CS;
reg rstS1, rstS2;


//FFT (when is it active or about to be active????)

always @(posedge clk)
begin
if (((RSTF2 == 1'b1)&&(RSTF == 1'b0))&&((STARTF2 == 1'b1)&&(STARTF == 1'b0))) //*** STARTF has to go down #2 after RSTF
begin
FFTcoun <= 10'b0;
C <= 1'b1;
end
else
begin
FFTcoun <= FFTcoun + 10'b1;
if ((FFTcoun < 10'd900))
begin
C <= C;
end
else
begin
C <= 1'b0;
end
end
end

always @(posedge clk)
begin
RSTF1 <= RSTF;
RSTF2 <= RSTF1;
STARTF1 <= STARTF;
STARTF2 <= STARTF1;
end

// assume VDD power gated by NMOS ....PF = 0 means unconnected)
assign PF = (C == 1'b1);


// DLX (activity monitor)

always @(posedge clk)
begin
MRSTD1 <= MRSTD;
MRSTD2 <= MRSTD1;
end 

always @(posedge clk)
begin
if (res == 1'b1)
begin
CD <= 1'b0;
end
else if ((MRSTD2 == 1'b0)&&(MRSTD == 1'b1))
begin
CD <= 1'b1;
end
else if ((MRSTD2 == 1'b1)&&(MRSTD == 1'b0))
begin
CD <= 1'b0;
end
else
begin
CD <= CD;
end
end

assign PD = (CD == 1'b1);

// Data Memory (activity monitor)

// processor and external DMA mode access

always @(posedge clk)
begin
if (res == 1'b1)
begin
CM <= 1'b0;
end
else if (((MRSTD2 == 1'b0)&&(MRSTD == 1'b1)))
begin
CM <= 1'b1;
end
else if (((MRSTD2 == 1'b1)&&(MRSTD == 1'b0)))
begin
CM <= 1'b0;
end
else
begin
CM <= CM;
end

if ((DReadED || DWriteED) == 1'b1)
begin
CM1 <= 1'b1;
end
else 
begin
CM1 <= 1'b0;
end

end 


assign PM = ((CM == 1'b1)||(CM1 == 1'b1));

// AES (activity monitor)

always @(posedge clk)
begin

if ((rstA2 == 1'b0)&&(rstA == 1'b1))
begin
AEScoun2 <= 3'b0;
CA1 <= 1'b1;
end
else
begin
AEScoun2 <= AEScoun2 + 3'b1;
if ((AEScoun2 < 3'b111))
begin
CA1 <= CA1;
end
else
begin
CA1 <= 1'b0;
end
end

if ((ldA2 == 1'b1)&&(ldA == 1'b0))
begin
AEScoun1 <= 5'b0;
CA2 <= 1'b1;
end
else
begin
AEScoun1 <= AEScoun1 + 5'b1;
if ((AEScoun1 < 5'd30))
begin
CA2 <= CA2;
end
else
begin
CA2 <= 1'b0;
end
end

end

assign PA = ((CA1 == 1'b1)||(CA2 == 1'b1));

always @(posedge clk)
begin
rstA1 <= rstA;
rstA2 <= rstA1;
ldA1 <= ldA;
ldA2 <= ldA1;
end

// SPI (activity monitor)
// based on reset or go

always @(posedge clk)
begin
rstS1 <= rstS;
rstS2 <= rstS1;

end

always @(posedge clk)
begin
if (((rstS2 == 1'b1)&&(rstS == 1'b0)))
begin
CS <= 1'b1;
end
else if ((rstS2 == 1'b0)&&(rstS == 1'b1))
begin
CS <= 1'b0;
end
else if (goS == 1'b1)
begin
CS <= 1'b1;
end
else if (goS == 1'b0)
begin
CS <= 1'b0;
end
end

assign PS = (CS == 1'b1);


endmodule




