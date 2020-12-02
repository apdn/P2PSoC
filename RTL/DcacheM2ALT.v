`include "./dlx.defines"
`timescale 1ns/1ps

// assuming external read and write through memory as well (here just external) highlighted by E

// DInE won't be inserted into test boundary chain

// DOUT and DIN are reverse with respect to that of Dcache

module Dcache (DOutE1, DOutE2, DOutE3, DOutE4, DOutE5, DOut, DAddrE1, DAddrE2, DAddrE3, DAddrE4, DAddrE5, DAddrE, DAddr, DReadE, DRead, DWriteE1, DWriteE2, DWriteE3, DWriteE4, DWriteE5, DWrite, DInE, DIn, DWRR, DARR, DORR, DIS1, DIS2, DIS3, DIS4, REQ1, REQ2, REQ3, REQ4, state);

parameter N = 32;
parameter WORDS = 128; //Suppose first 48 for SC, and16 words/IP
input [`WordSize] DOut, DAddr, DOutE1, DAddrE1, DOutE2, DAddrE2, DOutE3, DAddrE3, DOutE4, DAddrE4, DOutE5, DAddrE5, DARR, DORR;
input DRead, DReadE;
input DWrite, DWriteE1, DWriteE2, DWriteE3, DWriteE4, DWriteE5, DWRR ;
output reg[`WordSize] DIn;

output DIS1, DIS2, DIS3, DIS4, REQ1, REQ2, REQ3, REQ4;

output [3:0] state;

input [`WordSize] DAddrE; 
//input DReadE, DWriteE;
output reg[`WordSize] DInE;

reg [(N - 1):0] mem_array[(WORDS - 1):0];

wire [31:0] outvector;

// basically next the functioning of the memory controller for // single ported memory

always @(*)
begin

// by the Secuirty policy controller

if ((DRead == `LogicZero)&& (DWrite == `LogicOne))
begin
mem_array[DAddr] = DOut;
end
else if ((DRead == `LogicOne)&& (DWrite == `LogicZero))
begin
DIn = mem_array[DAddr];
end



else if ((DReadE == `LogicOne)) // just kept for external access
begin
DInE = mem_array[DAddrE];
end

end


always @(*)
begin

// address segmentation is present via inputs
if ((DWriteE1 == `LogicOne))
begin
mem_array[DAddrE1] = DOutE1;
end

if ((DWriteE2 == `LogicOne))
begin
mem_array[DAddrE2] = DOutE2;
end

if ((DWriteE3 == `LogicOne))
begin
mem_array[DAddrE3] = DOutE3;
end

if ((DWriteE4 == `LogicOne))
begin
mem_array[DAddrE4] = DOutE4;
end

if ((DWriteE5 == `LogicOne))
begin
mem_array[DAddrE5] = DOutE5;
end

if ((DWRR == 1'b1)) // for the write of the F values of the buffer
begin
mem_array[DARR] = DORR;
end

end

// the DIS and REQ outputs

assign outvector = mem_array[32'd20];
assign DIS1 = outvector[15];
assign DIS2 = outvector[14];
assign DIS3 = outvector[13];
assign DIS4 = outvector[12];
assign REQ1 = outvector[11];
assign REQ2 = outvector[10];
assign REQ3 = outvector[9];
assign REQ4 = outvector[8];
assign state = outvector[3:0];

endmodule
