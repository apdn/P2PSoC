
`include "spi_defines.v"
`include "timescale.v"

module debug_SPI(clk, MRST, go, last_bit, dat_i, we_i, tx_sel, err_i, divider, s_out, DCP, Sel, EV, Val, TP, TPE);

input clk, MRST, go, last_bit, we_i, err_i;
input s_out;
input [31:0] dat_i;
input [3:0] tx_sel;
input [15:0] divider;

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

else if ((tag == 1'b1) && (CFGNO >= 8'd64) && (CFGNO <= 8'd80)) 
begin
CFR[CFGNO - 8'd64] <= DCP;
end
end

// info to the wrapper
reg [7:0] ev1;

always @(posedge clk)
begin
if (MRST == 1'b0)
begin
EV <= 8'b0;
end

else if ((CFR[0] > 32'd0)) 
begin
if (sel1 == 2'b11) // SPI requiring access
begin
EV <= ev1;
end
end

else
EV <= 8'd0;

end

reg go1;
reg active;

always @(posedge clk)
go1 <= go;

reg [15:0] perfcoun;
always @(posedge clk)
begin
if (MRST == 1'b0)
begin
perfcoun <= 16'b0;
active <= 1'b0;
end
else if (((go1 == 1'b0)&& (go == 1'b1)) || (active == 1'b1))
begin
perfcoun <= perfcoun + 16'd1;
if (last_bit == 1'b1)
active <= 1'b0;
else
active <= 1'b1;
end
else
begin
perfcoun <= 'd0;
active <= 1'b0;
end

end





always @(*)
begin

casex({CFR[0][31:8], CFR[0][7:0]})

{24'bx, 8'b00000001}: 
begin

if ((go1 == 1'b0) && (go == 1'b1))
begin
ev1 = 8'd1;
end
else
ev1 = 8'd0;
end

{24'bx, 8'b00000010}: 
begin

if (perfcoun == (CFR[1] << 2))
begin
ev1 = 8'd2;
end
else
ev1 = 8'd0;
end

{24'bx, 8'b00000011}: 
begin

if (last_bit == 1'b1)
begin
ev1 = 8'd3;
end
else
ev1 = 8'd0;
end

{24'bx, 8'b00000100}: 
begin

if (err_i == 1'b1)
begin
ev1 = 8'd4;
end
else
ev1 = 8'd0;
end

{24'bx, 8'b00000101}: 
begin

if (dat_i == (CFR[1]))
begin
ev1 = 8'd5;
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

// trace packets

reg [1:0] coun;
reg activa;
always @(posedge clk)
begin
if (MRST == 1'b0)
begin
TPE <= 1'b0;
TP <= 32'h0;
coun <= 2'd0;
activa <= 'd0;
//coun1 <= 3'b0;
end

else if ((ev1 == 8'b1) || ((coun > 2'b0) && (coun < 2'b10))) 
begin
TPE <= 1'b1;
coun <= coun + 2'b1;
if (coun == 2'b0)
TP <= dat_i;
else
TP <= {11'b0, we_i, tx_sel, divider};
end

else if ((ev1 == 8'd2) || (activa == 1'b1))
begin
TPE <= 1'b1;
TP <= {31'd0, s_out};
if (last_bit == 1'b0)
activa <= 1'b1;
else
activa <= 1'b0;
end

else if (ev1 == 8'd3)
begin
TPE <= 1'b1;
TP <= {16'd0, perfcoun};
end

else if (ev1 == 8'd4)
begin
TPE <= 1'b1;
TP <= {s_out, 15'd0, perfcoun};
end

else if (ev1 == 8'd5)
begin
TPE <= 1'b1;
TP <= 32'hFFFFFFFF;
end

else
begin
TPE <= 1'b0;
TP <= 'd0;
coun <= 2'd0;
activa <= 'd0;
end

end



endmodule









 