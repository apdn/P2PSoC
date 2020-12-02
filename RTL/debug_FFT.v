`timescale 1 ns / 1 ps
`include "FFT128_CONFIG.inc"

module debug_FFT (clk, MRST, START, SHIFT, DR, DI, RDY, OVF1, OVF2, ADDR, DOR, DOI, DCP, Sel, EV, Val, TP, TPE);
	`FFT128paramnb		  	 //nb is the data bit width

input clk;
input MRST;
input START;
input [3:0] SHIFT;
input [nb-1:0] DR, DI ;
input RDY, OVF1, OVF2;
input [6:0] ADDR;
input [nb+3:0] DOR, DOI;
output reg [7:0] EV;
output reg [31:0] Val;
output reg [31:0] TP;
output reg TPE;
input [31:0] DCP;
input [1:0] Sel;

// starting from configuration register 16 onwards
//0-15 - DLX
// configuring the debug registers via DPB
reg [7:0] CFGNO;
reg tag;
reg [1:0] sel1;
reg [31:0] CFR[0:7];


always @ (posedge clk)
begin

if (MRST == 1'b0)
begin
CFGNO <= 8'd255;
tag <= 1'b0;
sel1 <= 2'b0;
end
else if (DCP[31] == 1'b1)
begin
CFGNO <= DCP[7:0];
tag <=  1'b1;
sel1 <= Sel;
end
else
begin
tag <= 1'b0;
end

end

always @(posedge clk)
begin

if (MRST == 1'b0)
begin
CFR[0] <= 0;
CFR[1] <= 0;
CFR[2] <= 0;
CFR[3] <= 0;
CFR[4] <= 0;
CFR[5] <= 0;
CFR[6] <= 0;
CFR[7] <= 0;
end

else if ((tag == 1'b1) && (CFGNO >= 8'd16) && (CFGNO <= 8'd31)) 
begin
CFR[CFGNO - 8'd16] <= DCP;
end
end

// info to the wrapper
reg [7:0] ev1;

always @(posedge clk)
begin
if (MRST == 1'b0)
begin
EV <= 8'b0;
Val <= 32'b0;
end

else if ((CFR[0] > 32'd0)) // no datatigg
begin
if (sel1 == 2'b11) // SPC requiring access
begin
EV <= ev1;
if (ev1 > 8'd0)
begin
Val <= {DI, DR};
end
end
end

else
EV <= 8'd0;

end

// CFR 0 being 1 means only the performance counter
reg [31:0] perfcoun; // full program performance counter
reg active;
reg active1;
reg START1;
always @(posedge clk)
begin

if (MRST == 1'b0)
begin
perfcoun <= 32'd0;
active <= 1'b0;
end
else if (((START1 == 1'b1) && (START == 1'b0)) || ((active == 1'b1) && (RDY == 1'b0)))
begin
perfcoun <= perfcoun + 32'b1;
active <= 1'b1;
end
else if (RDY == 1'b1)
begin
active <= 1'b0;
end
else
begin
perfcoun <= 32'd0;
end

end

// don't need to store perfcoun again

always @(posedge clk)
begin
active1 <= active;
end

always @(posedge clk)
begin
START1 <= START;
end


reg [nb+3:0] DOR1;
reg [nb+3:0] DOI1;
//reg [nb+3:0] DOI2;
//
always @(posedge clk)
begin
if (MRST == 1'b0)
begin
DOR1 <= 20'd0;
DOI1 <= 20'd0;
end
else if (RDY == 1'b1)
begin
DOR1 <= DOR;
DOI1 <= DOI;
end
else
begin
DOR1 <= DOR;
DOI1 <= DOI;
end
end

reg [5:0] overflowcoun;

always @(posedge clk)
begin
if (MRST == 1'b0)
begin
overflowcoun <= 6'd0;
end
else if (OVF1 == 1'b1)
begin
overflowcoun <= overflowcoun + 6'd1;
end
else if (RDY == 1'b1)
begin
overflowcoun <= 6'd0;
end

end




always @(*)
begin

casex({CFR[0][31:8], CFR[0][7:0]})

{24'bx, 8'b00000001}: 
begin

if (RDY == 1'b1)
begin
ev1 = 8'd1;
end
else
ev1 = 8'd0;
end

{24'bx, 8'b00000010}: 
begin

if ((START1 == 1'b1) && (START == 1'b0))
begin
ev1 = 8'd2;
end
else
ev1 = 8'd0;
end

{24'bx, 8'b00000011}: 
begin

if (RDY == 1'b1)
begin
ev1 = 8'd3;
end
else
ev1 = 8'd0;
end

{24'bx, 8'b00000100}: 
begin

if (RDY == 1'b1)
begin
ev1 = 8'd4;
end
else
ev1 = 8'd0;
end

{24'bx, 8'b00000101}: 
begin

if ((OVF1 == 1'b1) && (OVF2 == 1'b1))
begin
ev1 = 8'd5;
end
else
ev1 = 8'd0;
end

{24'bx, 8'b00000110}: 
begin

if (overflowcoun > 6'd32)
begin
ev1 = 8'd6;
end
else
ev1 = 8'd0;
end

default:
begin
ev1 = 8'd0;
end

endcase
end


reg [1:0] coun;
reg [2:0] coun1;
always @(posedge clk)
begin
if (MRST == 1'b0)
begin
TPE <= 1'b0;
TP <= 32'h0;
coun <= 2'd0;
coun1 <= 3'b0;
end

else if (ev1 == 8'b1)
begin
TPE <= 1'b1;
TP <= perfcoun;
end

else if (ev1 == 8'd2)
begin
TPE <= 1'b1;
TP <= {DI, DR};
end

else if ((ev1 == 8'd3) || ((coun > 2'd0) && (coun <= 2'd3)))
begin
TPE <= 1'b1;
coun <= coun + 2'b1;
if (coun == 2'b0)
TP <= {perfcoun};
else if (coun == 2'b1)
TP <= {12'b0, DOR};
else if (coun == 2'd2)
TP <= {12'b0, DOI1};
else if (coun == 2'd3)
TP <= {25'b0, ADDR};
end

else if ((ev1 == 8'd4) || ((coun1 > 3'd0) && (coun1 < 3'd6)))
begin
TPE <= 1'b1;
coun1 <= coun1 + 3'd1;
TP <= ADDR;
end

else if (ev1 == 8'd5)
begin
TPE <= 1'b1;
TP <= 32'hFFFFFFFF;
end

else if (ev1 == 8'd6)
begin
TPE <= 1'b1;
TP <= ADDR;
end

else
begin
TPE <= 1'b0;
TP <= 32'h0;
coun <= 2'b0;
end

end


endmodule




	