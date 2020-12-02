`timescale 1ns/1ps
 module debug_AES(clk, MRST, mode, ld, pause, done, key, t_in, t_out, DCP, Sel, EV, Val, TP, TPE, w01, w02, w03, w04);
input clk, MRST, mode, ld, done, pause;
input [127:0] key, t_in, t_out;
input [31:0] DCP;
input [1:0] Sel;
input [31:0] w01, w02, w03, w04;
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

else if ((tag == 1'b1) && (CFGNO >= 8'd32) && (CFGNO <= 8'd47)) 
begin
CFR[CFGNO - 8'd32] <= DCP;
end
end

// info to the wrapper
reg [7:0] ev1;
reg [1:0] cucu;

always @(posedge clk)
begin
if (MRST == 1'b0)
begin
EV <= 8'b0;
cucu <= 'd0;
Val <= 'd0;
end

else if ((CFR[0] > 32'd0)) // no datatigg
begin
if (sel1 == 2'b11) // SPI requiring access
begin
EV <= ev1;


if ((ev1 > 'd0) || ((cucu > 'd0)))
begin
cucu <= cucu + 2'd1;

if (cucu == 2'd0)
Val <= t_out[31:0];
else if (cucu == 2'd1)
Val <= t_out[63:32];
else if (cucu == 2'd2)
Val <= t_out[95:64];
else
Val <= t_out[127:96];
end

end
end

else
begin
EV <= 8'd0;
cucu <= 'd0;
Val <= 'd0;
end
end


reg ld1;
reg done1;

always @(posedge clk)
begin
ld1 <= ld;
done1 <= done;
end

reg [31:0] perfcoun;
reg active;

always @(posedge clk)
begin

if (MRST == 1'b0)
begin
perfcoun <= 32'd0;
active <= 1'b0;
end
else if (((ld1 == 1'b0) && (ld == 1'b1)) || ((active == 1'b1) && (done == 1'b0)))
begin
perfcoun <= perfcoun + 32'b1;
active <= 1'b1;
end
else if ((done1 == 1'b0) && (done == 1'b1))
begin
active <= 1'b0;
end
else
begin
perfcoun <= 32'd0;
end

end

reg pause1;
always @(posedge clk)
begin
pause1 <= pause;
end

reg [31:0] pauscoun;
reg activa;
always @(posedge clk)
begin

if (MRST == 1'b0)
begin
pauscoun <= 32'd0;
activa <= 1'b0;
end
else if (((pause1 == 1'b1) && (pause == 1'b0)) || ((activa == 1'b1) && (pause == 1'b0) && (active == 1'b1)))
begin
pauscoun <= pauscoun + 32'b1;
activa <= 1'b1;
end
else if ((pause1 == 1'b0) && (pause == 1'b1))
begin
activa <= 1'b0;
end
else
begin
pauscoun <= 32'd0;
end

end




always @(*)
begin

casex({CFR[0][31:8], CFR[0][7:0]})

{24'bx, 8'b00000001}: 
begin

if (done == 1'b1)
begin
ev1 = 8'd1;
end
else
ev1 = 8'd0;
end

{24'bx, 8'b00000010}: 
begin

if ((ld1 == 1'b0) && (ld == 1'b1) && (mode == 1'b1)) // key
begin
ev1 = 8'd2;
end
else
ev1 = 8'd0;
end

{24'bx, 8'b00000011}: 
begin

if ((ld1 == 1'b0) && (ld == 1'b1) && (mode == 1'b0)) // key
begin
ev1 = 8'd3;
end
else
ev1 = 8'd0;
end

{24'bx, 8'b00000100}: 
begin

if ((ld1 == 1'b0) && (ld == 1'b1)) // text_in
begin
ev1 = 8'd4;
end
else
ev1 = 8'd0;
end

{24'bx, 8'b00000101}: 
begin
if (done == 1'b1) // text_out
begin
ev1 = 8'd5;
end
else
ev1 = 8'd0;
end

{24'bx, 8'b00000110}: 
begin
if ((active == 1'b1) && (pause1 == 1'b1) && (pause == 1'b0)) // pause
begin
ev1 = 8'd6;
end
else
ev1 = 8'd0;
end


{24'bx, 8'b00000111}: 
begin
if ((active == 1'b1) && (pause1 == 1'b0) && (pause == 1'b1)) // pause
begin
ev1 = 8'd7;
end
else
ev1 = 8'd0;
end

{24'bx, 8'b00001000}: 
begin
if ((active == 1'b1) && ((perfcoun - pauscoun) == CFR[1])) // text_out
begin
ev1 = 8'd8;
end
else
ev1 = 8'd0;
end

{24'bx, 8'b00001001}: 
begin
if ((active == 1'b1) && ((perfcoun - pauscoun) == CFR[1])) // key
begin
ev1 = 8'd9;
end
else
ev1 = 8'd0;
end

{24'bx, 8'b00001010}: 
begin
if ((active == 1'b1) && ((perfcoun - pauscoun) == CFR[1])) // key
begin
ev1 = 8'd10;
end
else
ev1 = 8'd0;
end

{24'bx, 8'b00001011}: 
begin
if ((active == 1'b1) && ((perfcoun - pauscoun) == CFR[1])) // key
begin
ev1 = 8'd11;
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


// distinct ev1's

reg [7:0] ev11;

always @(ev1) //latch
begin
if (ev1 > 8'd0)
ev11 = ev1;
end 

// trace packets

reg [1:0] coun;
reg [2:0] coun1;
reg t1, t2, t3, t4, t5, t6;
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

else if (((ev1 == 8'd2)||(ev1 == 8'd3)|| (ev1 == 8'd4) || (ev1 == 8'd5)) || ((coun > 2'd0))) 
begin

TPE <= 1'b1;
coun <= coun + 2'b1;
if (ev11 == 8'd2)
begin
if (coun == 2'd0)
TP <= key[31:0];
else if (coun == 2'd1)
TP <= key[63:32];
else if (coun == 2'd2)
TP <= key[95:64];
else if (coun == 2'd3)
TP <= key[127:96];
else
TP <= 0;
end

if (ev11 == 8'd3)
begin
if (coun == 2'd0)
TP <= key[31:0];
else if (coun == 2'd1)
TP <= key[63:32];
else if (coun == 2'd2)
TP <= key[95:64];
else if (coun == 2'd3)
TP <= key[127:96];
else
TP <= 0;
end

if (ev11 == 8'd4)
begin
if (coun == 2'd0)
TP <= t_in[31:0];
else if (coun == 2'd1)
TP <= t_in[63:32];
else if (coun == 2'd2)
TP <= t_in[95:64];
else if (coun == 2'd3)
TP <= t_in[127:96];
else
TP <= 0;
end

if (ev11 == 8'd5)
begin
if (coun == 2'd0)
TP <= t_out[31:0];
else if (coun == 2'd1)
TP <= t_out[63:32];
else if (coun == 2'd2)
TP <= t_out[95:64];
else if (coun == 2'd3)
TP <= t_out[127:96];
else
TP <= 0;
end

end

else if (ev1 == 8'd6)
begin
TP <= 32'hFFFFFFFF;
TPE <= 1'b1;
end

else if (ev1 == 8'd7)
begin
TP <= pauscoun;
TPE <= 1'b1;
end

else if ((ev1 == 8'd8) || (t1 == 1'b1))
begin
if (done == 1'b0)
begin
TP <= t_out[31:0]; // just a simplification
TPE <= 1'b1;
t1 <= 1'b1;
end
else
t1 <= 1'b0;
end


else if ((ev1 == 8'd9) || (t2 == 1'b1))
begin
if (done == 1'b0)
begin
TP <= w01;
TPE <= 1'b1;
t2 <= 1'b1;
end
else
t2 <= 1'b0;
end

else if ((ev1 == 8'd10) || (t3 == 1'b1))
begin
if (done == 1'b0)
begin
TP <= t_out[63:32]; // just a simplification
TPE <= 1'b1;
t3 <= 1'b1;
end
else
t3 <= 1'b0;
end

else if ((ev1 == 8'd11) || (t4 == 1'b1))
begin
if (done == 1'b0)
begin
TP <= w02;
TPE <= 1'b1;
t4 <= 1'b1;
end
else
t4 <= 1'b0;
end

else
begin
TPE <= 1'b0;
TP <= 32'b0;
end

end

endmodule


