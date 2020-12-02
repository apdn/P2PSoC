`include "./dlx.defines"
`timescale 1ns/1ps

// extending it for memory operations (here external represented by E)
module IcacheSP (
PHI1,
MRST,
IAddr,
IIn,
IAddrE,
IInE,
IWriteE
);

parameter WORDS = 128;
input PHI1;
input MRST;
input [`WordSize] IAddr;
output reg[`WordSize] IIn;
input [`WordSize] IAddrE;
input IWriteE;
input [`WordSize] IInE; // IIn and IInE  by opposite conventions


//reg [31:0] mem_array[(WORDS - 1):0] = {32'b`//00100000001000010000000000000110,
 //32'b`00000000000000000000000000000000,
 //32'b`00000000000000000000000000000000,
 //32'b`00000000000000000000000000000000,
 //32'b`11001100011000010000000000000101};

reg [31:0] mem_array[(WORDS - 1):0];

initial
begin
$readmemb("test11BRANCH3.dat", mem_array);
//$readmemb("test11onlystoreandload.dat", mem_array);
//$readmemb("testSPCinteraction.dat", mem_array);
//$readmemb("testSPCFFT.dat", mem_array);
//$readmemb("testSPCDLX.dat", mem_array);
//$readmemb("testSPCAES.dat", mem_array);

//$readmemb("testSPCinteraction.dat", mem_array);
//$readmemb("testSPCREAD.dat", mem_array);

end

always @(negedge PHI1)
begin	
if (MRST == 1'b1)
begin
IIn <= mem_array[IAddr/4];
end
else if (IWriteE == 1'b1)
begin
mem_array[IAddrE] <= IInE;
end
end

endmodule


