`include "./dlx.defines"
`timescale 1ns/1ps

module debug_DLX1 (clk, MRST, MRSTproc, stop, pause, IIn, IAddr, DIn, DOut, DAddr, DRead, DWrite, SPR1, SPR2, DCP, Sel, TP, TPE, EV, Val);

// SPR - Special Purpose Register
// DCP - Debug Configuration Port
// EV - transfer of event occurence info from debug logic to security wrapper
// Val - Any metadata associated with events (if necessary)
// TP - Trace Port for debug logic

input clk;
input MRST;
input MRSTproc;
input stop, pause;

input [`WordSize] IIn, IAddr, DIn, DOut, DAddr;
input DRead, DWrite;
input [31:0] SPR1, SPR2;
input [31:0] DCP;
input [1:0] Sel;
output reg [9:0] EV;
output reg [31:0] Val;
output reg [31:0] TP;
output reg TPE; // Trace Port Enable 

// buffers for storing
reg [31:0] IA [0:7];
reg [31:0] ID [0:7];
reg [31:0] DA [0:7];
reg [31:0] DD [0:7];


always @(posedge clk)
begin
if (MRST == 1'b0)
begin
IA[0] <= 0;
IA[1] <= 0;
IA[2] <= 0;
IA[3] <= 0;
IA[4] <= 0;
IA[5] <= 0;
IA[6] <= 0;
IA[7] <= 0;

DA[0] <= 0;
DA[1] <= 0;
DA[2] <= 0;
DA[3] <= 0;
DA[4] <= 0;
DA[5] <= 0;
DA[6] <= 0;
DA[7] <= 0;

end
else
begin

IA[0] <= IAddr;
IA[1] <= IA[0];
IA[2] <= IA[1];
IA[3] <= IA[2];
IA[4] <= IA[3];
IA[5] <= IA[4];
IA[6] <= IA[5];
IA[7] <= IA[6];

DA[0] <= DAddr;
DA[1] <= DA[0];
DA[2] <= DA[1];
DA[3] <= DA[2];
DA[4] <= DA[3];
DA[5] <= DA[4];
DA[6] <= DA[5];
DA[7] <= DA[6];

end

end

always @(posedge clk)
begin
if (MRST == 1'b0)
begin
ID[0] <= 0;
ID[1] <= 0;
ID[2] <= 0;
ID[3] <= 0;
ID[4] <= 0;
ID[5] <= 0;
ID[6] <= 0;
ID[7] <= 0;

DD[0] <= 0;
DD[1] <= 0;
DD[2] <= 0;
DD[3] <= 0;
DD[4] <= 0;
DD[5] <= 0;
DD[6] <= 0;
DD[7] <= 0;

end
else
begin
ID[0] <= IIn;
ID[1] <= ID[0];
ID[2] <= ID[1];
ID[3] <= ID[2];
ID[4] <= ID[3];
ID[5] <= ID[4];
ID[6] <= ID[5];
ID[7] <= ID[6];

DD[0] <= DIn;
DD[1] <= DD[0];
DD[2] <= DD[1];
DD[3] <= DD[2];
DD[4] <= DD[3];
DD[5] <= DD[4];
DD[6] <= DD[5];
DD[7] <= DD[6];

end

end


// CFR - Configuration Register for Debug
reg [31:0] CFR[0:9];
// Instruction Compare - CFR 1-3
// Data Compare - CFR 4-6
// Special Function Register - 7-9
// Counter and Event Sequencer - 10

// configuring the debug registers via DPB
reg [7:0] CFGNO;
reg tag;
reg [1:0] sel1;

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
CFR[8] <= 0;
CFR[9] <= 0;

end
else if ((tag == 1'b1) && (CFGNO >= 8'd0) && (CFGNO <= 8'd15)) 
begin
CFR[CFGNO] <= DCP;
end
end

// the logic that instruments (trigger and trace) the DLX uP

// 1) program counter range/value comparison (with bit masking like at page/block levels only)

reg [7:0] ev1;
reg [7:0] ev2;
reg [7:0] ev3;
reg [7:0] ev4;

reg [1:0] cucu;

always @(posedge clk)
begin
if (MRST == 1'b0)
begin
EV <= 10'b0;
Val <= 'd0;
cucu <= 'd0;
end

else if ((CFR[9][7:0] != 8'd0)) // no insttrig
begin
if (sel1 == 2'b11)  // SPI req access
begin
EV <= {2'd3, ev4};

if ((ev4 > 'd0) || ((cucu > 'd0)))
begin
cucu <= cucu + 2'b1;
if (cucu == 2'd0)
Val <= IIn;
else if (cucu == 2'd1)
Val <= IAddr;
else if (cucu == 2'd2)
Val <= SPR1;
else
Val <= SPR2;
end

end
end

else if ((CFR[0][7:0] != 8'd0) && (CFR[3] == 'd0)) // no datatigg
begin
if (sel1 == 2'b11) // SPI requiring access
begin
EV <= {2'b0, ev1};

if ((ev1 > 'd0) || ((cucu > 'd0)))
begin
cucu <= cucu + 2'b1;
if (cucu == 2'd0)
Val <= IIn;
else if (cucu == 2'd1)
Val <= IAddr;
else if (cucu == 2'd2)
Val <= SPR1;
else
Val <= SPR2;
end

end
end

else if ((CFR[3][7:0] != 8'd0) && (CFR[0] == 'd0)) // no insttrig
begin
if (sel1 == 2'b11)  // SPI req access
begin
EV <= {2'b1, ev2};

if ((ev2 > 'd0) || ((cucu > 'd0)))
begin
cucu <= cucu + 2'b1;
if (cucu == 2'd0)
Val <= IIn;
else if (cucu == 2'd1)
Val <= DAddr;
else if (cucu == 2'd2)
Val <= SPR1;
else
Val <= SPR2;
end

end
end

else if ((CFR[6][7:0] != 8'd0)) // no insttrig
begin
if (sel1 == 2'b11)  // SPI req access
begin
EV <= {2'd2, ev3};

if ((ev3 > 'd0) || ((cucu > 'd0)))
begin
cucu <= cucu + 2'b1;
if (cucu == 2'd0)
Val <= IIn;
else if (cucu == 2'd1)
Val <= IAddr;
else if (cucu == 2'd2)
Val <= SPR1;
else
Val <= SPR2;
end

end
end

else
begin
EV <= 10'b0;
Val <= 'd0;
cucu <= 'd0;
end

end

reg [31:0] perfcoun; // full program performance counter
reg [31:0] perfcoun1;
reg active;
reg active1;

// based off custom logic
always @(posedge clk)
begin
if (MRSTproc == 1'b0)
begin
perfcoun <= 32'd0;
active <= 1'b0;
end
else if ((IAddr > 32'd0)&& (MRSTproc == 1'b1))
begin
perfcoun <= perfcoun + 32'd1;
active <= 1'b1;
end
else if (MRSTproc == 1'b0)
begin
active <= 1'b0;
end
else
begin
active <= 1'b0;
end

end

always @(posedge clk)
begin
active1 <= active;
end

always @(posedge clk)
begin
perfcoun1 <= perfcoun;
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


// Instruction based event trigger

reg [2:0] number;

reg [7:0] blog;

always @(IAddr or IIn) 
// what about IIn, like conditional branches, JAL, J, TRAP, RFE??
//always @(*)
begin

casex({CFR[0][31:8], CFR[0][7:0]})

{24'bx, 8'b00100001}: // exact comparison of address with CFR[1]
begin
if (IAddr == CFR[1])
begin
ev1 = 8'b1;
number = 3'b011;
end
else
ev1 = 8'b0;
end

{24'bx, 8'b01000001}: // exact comparison of address with CFR[1]
begin
if (IAddr == CFR[1])
begin
ev1 = 8'b1;
number = 3'b111;
end
else
ev1 = 8'b0;
end

{24'bx, 8'b01100001}: // exact comparison of address with CFR[1]
begin
if (IAddr == CFR[1])
begin
ev1 = 8'd2;
end
else
ev1 = 8'b0;
end

{24'bx, 8'b10000001}: // exact comparison of address with CFR[1]
begin
if (IAddr == CFR[1])
begin
ev1 = 8'd3;
number = 3'b011;
end
else
ev1 = 8'b0;
end

{24'bx, 8'b10100001}: // exact comparison of address with CFR[1] 
begin
if (IAddr == CFR[1])
begin
ev1 = 8'd3;
number = 3'b111;
end
else
ev1 = 8'b0;
end

{24'bx, 8'b11000001}: // exact comparison of address with CFR[1]
begin
if (IAddr == CFR[1])
begin
ev1 = 8'd4;
end
else
ev1 = 8'b0;
end


{24'bx, 8'b00100010}: // exact comparison of page address with CFR[1]
begin
if (IAddr[31:12] == CFR[1][31:12])
begin
ev1 = 8'd5;
number = 3'b111;
end
else
ev1 = 8'b0;
end

{24'bx, 8'b01000010}: // exact comparison of page address with CFR[1]
begin
if (IAddr[31:12] == CFR[1][31:12])
begin
ev1 = 8'd6;
end
else
ev1 = 8'b0;
end


{24'bx, 8'b00100011}: // exact comparison of address with CFR[1]
begin
if ((IAddr >= CFR[1]) && (IAddr <= CFR[2]))
begin
ev1 = 8'd7;
//number = 3'b011;
end
else
ev1 = 8'b0;
end

{24'bx, 8'b01000011}: // exact comparison of address with CFR[1]
begin
if ((IAddr >= CFR[1]) && (IAddr <= CFR[2]))
begin
ev1 = 8'd7;
//number = 3'b111;
end
else
ev1 = 8'b0;
end

{24'bx, 8'b01100011}: // exact comparison of address with CFR[1]
begin
if ((IAddr >= CFR[1]) && (IAddr <= CFR[2]))
begin
ev1 = 8'd8;
end
else
ev1 = 8'b0;
end

{24'bx, 8'b00100011}: // exact comparison of address with CFR[1]
begin
if (IIn[31:26] == 6'b010001)
begin
ev1 = 8'd9; // trace IIn till stop // TRAP
end
else
ev1 = 8'b0;
end

{24'bx, 8'b01000011}: // exact comparison of address with CFR[1]
begin
if (IIn[31:26] == 6'b010000)
begin
ev1 = 8'd10; // trace IIn till stop // RFE
end
else
ev1 = 8'b0;
end

{24'bx, 8'b01100011}: // exact comparison of address with CFR[1]
begin
if (IIn[31:26] == 6'b01001x)
begin
ev1 = 8'd11; // trace IIn till stop // JR or JAR
end
else
ev1 = 8'b0;
end

{24'bx, 8'b10000011}: // exact comparison of address with CFR[1]
begin
if (IIn[31:26] > 6'b110011) // invalid address
begin
ev1 = 8'd12; // trace address till stop
end
else
ev1 = 8'b0;
end

// performance counter

{24'bx, 8'b00000100}: // exact comparison of address with CFR[1]
begin
if ((IAddr >= CFR[1]) && (IAddr < CFR[2])) // invalid address
begin
ev1 = 8'd13; // trace address till stop
end
else if (IAddr == CFR[2])
begin
ev1 = 8'd14;
end
else
ev1 = 8'd0;
//nothing 
end

{24'bx, 8'b00000101}:
begin
if ((active == 1'b1) && (pause1 == 1'b1) && (pause == 1'b0)) // pause
begin
ev1 = 8'd15;
end
else
ev1 = 8'd0;
end

 
default:
begin
ev1 = 8'b0;
end

endcase

end


always @(posedge clk)
begin

if (MRST == 1'b0)
begin
blog <= 8'b0;
end
else if ((ev1 == 8'd13) || (ev1 == 8'd14))
begin
blog <= blog + 1'b1;
end
else
begin
blog <= 8'b0;
end

end





// Involving data values/addresses/Read/Write

always @(*) 
// what about IIn, like conditional branches, JAL, J, TRAP, RFE??
//always @(*)
begin

casex({CFR[3][31:8], CFR[3][7:0]})

{24'bx, 8'd1}: 
begin
if (DIn == CFR[4])
begin
ev2 = 8'b1;
end
else
ev2 = 8'b0;
end

{24'bx, 8'd2}: 
begin
if (DOut == CFR[4])
begin
ev2 = 8'd2;
end
else
ev2 = 8'b0;
end

{24'bx, 8'd3}: 
begin
if (DIn[0] == CFR[4][0])
begin
ev2 = 8'd3;
end
else
ev2 = 8'd0;
end

{24'bx, 8'd4}: 
begin
if (DOut[0] == CFR[4][0])
begin
ev2 = 8'd4;
end
else
ev2 = 8'd0;
end


{24'bx, 8'd5}:
begin
if (( DIn >= CFR[4]) && (DIn <= CFR[5]))
begin
ev2 = 8'h5;
end
else
ev2 = 8'b0;
end

{24'bx, 8'd6}:
begin
if (( DOut >= CFR[4]) && (DOut <= CFR[5]))
begin
ev2 = 8'h6;
end
else
ev2 = 8'b0;
end

{24'bx, 8'd7}:
begin
if (( DAddr >= CFR[4]) && (DAddr <= CFR[5]))
begin
ev2 = 8'h7;
end
else
ev2 = 8'b0;
end

{24'bx, 8'd8}:
begin
if (( DAddr[31:12] == CFR[4][31:12]))
begin
ev2 = 8'h8;
end
else
ev2 = 8'b0;
end


{24'bx, 8'd9}:
begin
if ((DIn == CFR[4]) && (DAddr == CFR[5]))
begin
ev2 = 8'h9;
end
else
ev2 = 8'b0;
end

{24'bx, 8'd10}:
begin
if (( DAddr[31:12] == CFR[4][31:12]) && (DRead == 1'b1))
begin
ev2 = 8'd10;
end
else
ev2 = 8'b0;
end

{24'bx, 8'd11}:
begin
if (( DAddr[31:12] == CFR[4][31:12]) && (DWrite == 1'b1))
begin
ev2 = 8'd11;
end
else
ev2 = 8'b0;
end

{24'bx, 8'd12}:
begin
ev2 = 8'd12;
end





 
default:
begin
ev2 = 8'b0;
end

endcase

end


// special function register



always @(*) 

begin

casex({CFR[6][31:8], CFR[6][7:0]})

{24'bx, 8'd1}: 
begin
if (SPR1[31:0] == CFR[7])
begin
ev3 = 8'b1;
end
else
ev3 = 8'b0;
end

{24'bx, 8'd2}: 
begin
if (SPR1[0] == CFR[7][0])
begin
ev3 = 8'd2;
end
else
ev3 = 8'b0;
end

{24'bx, 8'd3}: 
begin
if (SPR2 == CFR[8])
begin
ev3 = 8'd3;
end
else
ev3 = 8'b0;
end

{24'bx, 8'd4}: 
begin
if (SPR2[0] == CFR[8][0])
begin
ev3 = 8'd4;
end
else
ev3 = 8'b0;
end

default:
begin
ev3 = 8'd0;
end

endcase

end

always @(*) 

begin

casex({CFR[9][31:8], CFR[9][7:0]})

{24'bx, 8'd1}: 
begin
ev4 = 8'd1;
end

{24'bx, 8'd2}: 
begin
ev4 = 8'd2;
end

default:
begin
ev4 = 8'd0;
end

endcase
end



reg [2:0] coun;
reg [2:0] coun1;
reg [2:0] coun2;
reg [2:0] coun3;
reg [2:0] coun4;



// trace packet generator alternate
reg ind;
reg ind1;
reg ind2;
reg ind3;
reg ind4;

wire [2:0] num;
assign num = (number == 3'b011)?3'd3:3'd7;  

always @(posedge clk)
begin
if (MRST == 1'b0)
begin
TP <= 'h0;
TPE <= 'b0;
coun <= 'b0;
coun1 <= 'b0;
coun2 <= 'b0;
coun3 <= 'b0;
coun4 <= 'b0;
ind <= 1'b0;
ind1 <= 1'b0;
ind2 <= 1'b0;
ind3 <= 1'b0;
ind4 <= 1'b0;
end

//else if (sel1 == 2'b10) // external debugger
//begin

else if (((CFR[9] == 32'd1) && (ev3 == 8'd1) && (ev1 == 8'd4)) || ((coun > 0) && (coun <= 3'd7)))
begin
coun <= coun + 3'b1; // reusing this
TPE <= 1'b1;
TP <= ID[0];
end

else if (((CFR[9] == 32'd2) && (ev3 == 8'd1) && (ev1 == 8'd11)) || ((coun > 0) && (coun <= 3'd7)))
begin
coun <= coun + 3'b1; // reusing this
TPE <= 1'b1;
TP <= ID[0];
end


else if ((ev3 == 8'd1) || ((coun > 0) && (coun <= 3'd7)))
begin
coun <= coun + 3'b1; // reusing this
TPE <= 1'b1;
TP <= ID[7];
end

else if ((ev3 == 8'd2) || ((coun > 0) && (coun <= 3'd7)))
begin
coun <= coun + 3'b1; // reusing this
TPE <= 1'b1;
TP <= ID[7];
end

else if ((ev3 == 8'd3) || ((coun > 0) && (coun <= 3'd7)))
begin
coun <= coun + 3'b1; // reusing this
TPE <= 1'b1;
TP <= ID[0];
end

else if ((ev3 == 8'd4) || ((coun > 0) && (coun <= 3'd7)))
begin
coun <= coun + 3'b1; // reusing this
TPE <= 1'b1;
TP <= ID[0];
end


else if (((ev1 == 8'd1)&&(ev2 == 8'd0))|| ((coun > 0) && (coun <= number)))
begin
coun <= coun + 3'b1;
TPE <= 1'b1;
TP <= IA[number];
end


else if (((ev1 == 8'd2)&&(ev2 == 8'd0))|| (ind1 == 1'b1))
begin
TPE <= 1'b1;
TP <= IA[0];
if (stop == 1'b0)
ind1 <= 1'b1;
else
ind1 <= 1'b0;
end


else if (((ev1 == 8'd3)&&(ev2 == 8'd0))|| ((coun1 > 0) && (coun1 <= number)))
begin
coun1 <= coun1 + 3'b1;
TPE <= 1'b1;
TP <= ID[number];
end


else if (((ev1 == 8'd4)&&(ev2 == 8'd0))|| (ind == 1'b1))
begin
TPE <= 1'b1;
TP <= ID[0];
if (stop == 1'b0)
ind <= 1'b1;
else
ind <= 1'b0;
end

else if (((ev1 == 8'd5)&&(ev2 == 8'd0))|| ((coun2 > 0) && (coun2 <= number)))
begin
coun2 <= coun2 + 3'b1;
TPE <= 1'b1;
TP <= ID[number];
end

else if (((ev1 == 8'd6)&&(ev2 == 8'd0))|| (ind2 == 1'b1))
begin
TPE <= 1'b1;
TP <= ID[0];
if (stop == 1'b0)
ind2 <= 1'b1;
else
ind2 <= 1'b0;
end

else if (ev1 == 8'd7)
begin
TPE <= 1'b1;
TP <= ID[0];
end

else if (ev1 == 8'd8)
begin
TPE <= 1'b1;
TP <= IA[0];
end

else if (((ev1 == 8'd9) || (ev1 == 8'd10) || (ev1 == 8'd11) || (ev1 == 8'd12)) || (ind3 == 1'b1))
begin
TPE <= 1'b1;
TP <= ID[0];
if (stop == 1'b0)
ind3 <= 1'b1;
else
ind3 <= 1'b0;
end

else if (ev1 == 8'd14)
begin
TPE <= 1'b1;
TP <= {24'd0, blog};
end

else if (((ev2 > 8'b0) && (ev2 < 8'd11))|| (ind4 == 1'b1))
begin
TPE <= 1'b1;
TP <= ID[0];
if (stop == 1'b0)
ind4 <= 1'b1;
else
ind4 <= 1'b0;
end

else if ((ev2 == 8'd11) || ((coun4 > 3'b0) && (coun4 < 3'd7)))
begin
coun4 <= coun4 + 3'b1;
TPE <= 1'b1;
TP <= IA[7];
end

else if ((ev2 == 8'd12) && (active1 == 1'b1) && (active == 1'b0))
begin
TP <= perfcoun1;
TPE <= 1'b1;
end

else if ((ev2 == 8'd15) || (pause1 == 1'b0) && (pause == 1'b0)) // change
begin
TP <= pauscoun;
TPE <= 1'b1;
end


else
begin
TPE <= 1'b0;
TP <= 32'b0;
coun <= 3'b0;
coun1 <= 3'b0;
coun2 <= 3'b0;
coun3 <= 3'b0;
coun4 <= 3'b0;
ind <= 1'b0;
ind1 <= 1'b0;
ind2 <= 1'b0;
ind3 <= 1'b0;
ind4 <= 1'b0;

end





end






endmodule



