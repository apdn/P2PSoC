`include "./dlx.defines"
`timescale 1ns/1ps

// assuming external read and write through memory as well (here just external) highlighted by E

// DInE won't be inserted into test boundary chain

// DOUT and DIN are reverse with respect to that of Dcache

module SystemMem (DOutE1, DOutE2, DOutE3, DOut, DAddrE1, DAddrE2, DAddrE3, DAddr, DReadE1, DReadE2, DReadE3, DRead, DWriteE1, DWriteE2, DWriteE3, DWrite, DInE1, DInE2, DInE3, DIn);

parameter N = 32;
parameter WORDS = 128;
input [`WordSize] DOut, DAddr;
input DRead, DWrite;
output reg[`WordSize] DIn;

input [`WordSize] DOutE1, DAddrE1, DOutE2, DAddrE2, DOutE3, DAddrE3;
input DReadE1, DWriteE1, DReadE2, DWriteE2, DReadE3, DWriteE3 ;
output reg[`WordSize] DInE1, DInE2, DInE3;

reg [(N - 1):0] mem_array[(WORDS - 1):0];

// prioirity of processor first, then AES and then FFT..(if simultaneous) and Read over Write

// ACTUALLY SINGLE PORTED

always @(*)
begin
// Read Operation
// For a particular IP, both cannot read and write
if ((DRead == `LogicOne)&& (DWrite == `LogicZero))
begin
DIn = mem_array[DAddr];
end
else if ((DReadE1 == `LogicOne)&& (DWriteE1 == `LogicZero))
begin
DInE1 = mem_array[DAddrE1];
end
else if ((DReadE2 == `LogicOne)&& (DWriteE2 == `LogicZero))
begin
DInE2 = mem_array[DAddrE2];
end
else if ((DReadE3 == `LogicOne)&& (DWriteE3 == `LogicZero))
begin
DInE3 = mem_array[DAddrE3];
end

end


always @(*)
begin
if ((DRead == `LogicZero)&& (DWrite == `LogicOne))
begin
mem_array[DAddr] = DOut;
end
else if ((DReadE1 == `LogicZero)&& (DWriteE1 == `LogicOne))
begin
mem_array[DAddrE1] = DOutE1;
end
else if ((DReadE2 == `LogicZero)&& (DWriteE2 == `LogicOne))
begin
mem_array[DAddrE2] = DOutE2;
end
else if ((DReadE3 == `LogicZero)&& (DWriteE3 == `LogicOne))
begin
mem_array[DAddrE3] = DOutE3;
end

end

endmodule
