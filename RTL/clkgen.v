/*************************************************************************
 * FILE:        clkgen.v
 * Written By:  Michael J. Kelley
 * Written On:  March 4, 1996
 * Updated By:  Michael J. Kelley
 * Updated On:  March 4, 1996
 *
 * Description:
 *
 * This modules is used to generate a one-phase clock to be used with
 * the system.v module.  This clock governs the timing on the entire
 * DLX processor.
 *************************************************************************
 */
`timescale 1ns/1ps

`include "./dlx.defines"
module clkgen (
        clk
);

output clk;
reg    clk;

initial
begin
        clk = 0;
end

always
begin
        #(`ClockPeriod / 2) clk = 1;
        #(`ClockPeriod / 2) clk = 0;
end

endmodule
