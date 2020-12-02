`include "./dlx.defines"
`timescale 1ns/1ps

module DAP (clk, MRST, s1,s2, DB1, DB2, DCP, SEL);
input clk;
input MRST;
input [31:0] DB1, DB2;
input s1, s2;
output reg[31:0] DCP;
output reg[1:0] SEL;

always @(posedge clk)
begin

if (MRST == 1'b0)
begin
DCP <= 32'b0;
SEL <= 2'b00;
end
else if ((s2 == 1'b1) && (s1 == 1'b0))
begin
DCP <= DB2;
SEL <= 2'b10;
end

else if ((s1 == 1'b1) && (s2 == 1'b1))
begin
DCP <= DB1;
SEL <= 2'b11;
end


end

endmodule



