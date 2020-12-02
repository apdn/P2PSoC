`include "./dlx.defines"
`timescale 1ns/1ps

module debug_mem (clk, MRST, din, dout, daddr, dread, dwrite, din1, dout1, daddr1, dread1, dwrite1, din2, dout2, daddr2, dread2, dwrite2, din3, dout3, daddr3, dread3, dwrite3, DCP, Sel,  EV, Val, TP, TPE);
input clk, MRST;
input [31:0] din, din1, din2, din3, dout, dout1, dout2, dout3, daddr, daddr1, daddr2, daddr3;
input dread, dwrite, dread1, dwrite1, dread2, dwrite2, dread3, dwrite3 ;
input [31:0] DCP;
input [1:0] Sel;
output reg [31:0] Val, TP;
output reg TPE;
output reg [7:0] EV;

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

else if ((tag == 1'b1) && (CFGNO >= 8'd48) && (CFGNO <= 8'd64)) 
begin
CFR[CFGNO - 8'd48] <= DCP;
end
end

// info to the wrapper
reg [7:0] ev1;
reg [7:0] ev2;

always @(posedge clk)
begin
if (MRST == 1'b0)
begin
EV <= 8'b0;
Val <= 32'd0;
end

else if ((CFR[0] > 32'd0)) // no datatigg
begin
if (sel1 == 2'b11) // SPI requiring access
begin
EV <= ev2;
if (ev2 > 'd0)
Val <= TP;

end

end

else

begin
EV <= 8'd0;
Val <= 'd0;
end

end


always @(posedge clk)
begin
ev2 <= ev1;
end

always @(*)
begin

casex({CFR[0][31:8], CFR[0][7:0]})

{24'bx, 8'b00000001}: 
begin

if ((dread == 1'b1) && (daddr > CFR[1]) && (daddr < CFR[2]))
begin
ev1 = 8'd1;
end
else
ev1 = 8'd0;
end

{24'bx, 8'b00000010}: 
begin

if ((dwrite == 1'b1) && (daddr > CFR[1]) && (daddr < CFR[2]))
begin
ev1 = 8'd2;
end
else
ev1 = 8'd0;
end

{24'bx, 8'b00000011}: 
begin

if ((dread1 == 1'b1) && (daddr1 > CFR[1]) && (daddr1 < CFR[2]))
begin
ev1 = 8'd3;
end
else
ev1 = 8'd0;
end

{24'bx, 8'b00000100}: 
begin

if ((dwrite1 == 1'b1) && (daddr1 > CFR[1]) && (daddr1 < CFR[2]))
begin
ev1 = 8'd4;
end
else
ev1 = 8'd0;
end

{24'bx, 8'b00000101}: 
begin

if ((dread2 == 1'b1) && (daddr2 > CFR[1]) && (daddr2 < CFR[2]))
begin
ev1 = 8'd5;
end
else
ev1 = 8'd0;
end

{24'bx, 8'b00000110}: 
begin

if ((dwrite2 == 1'b1) && (daddr2 > CFR[1]) && (daddr2 < CFR[2]))
begin
ev1 = 8'd6;
end
else
ev1 = 8'd0;
end

{24'bx, 8'b00000111}: 
begin

if ((dread3 == 1'b1) && (daddr3 > CFR[1]) && (daddr3 < CFR[2]))
begin
ev1 = 8'd7;
end
else
ev1 = 8'd0;
end

{24'bx, 8'b00001000}: 
begin

if ((dwrite3 == 1'b1) && (daddr3 > CFR[1]) && (daddr3 < CFR[2]))
begin
ev1 = 8'd8;
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

// trace packet generation

always @(posedge clk)
begin
if (MRST == 1'b0)
begin
TPE <= 1'b0;
TP <= 32'h0;
end

else if (ev1 == 8'b1)
begin
TPE <= 1'b1;
TP <= din;
end

else if (ev1 == 8'd2)
begin
TPE <= 1'b1;
TP <= dout;
end

else if (ev1 == 8'd3)
begin
TPE <= 1'b1;
TP <= din1;
end

else if (ev1 == 8'd4)
begin
TPE <= 1'b1;
TP <= dout1;
end

else if (ev1 == 8'd5)
begin
TPE <= 1'b1;
TP <= din2;
end

else if (ev1 == 8'd6)
begin
TPE <= 1'b1;
TP <= dout2;
end

else if (ev1 == 8'd7)
begin
TPE <= 1'b1;
TP <= din3;
end

else if (ev1 == 8'd8)
begin
TPE <= 1'b1;
TP <= dout3;
end

else
begin
TPE <= 1'b0;
TP <= 'd0;
end

end

endmodule






