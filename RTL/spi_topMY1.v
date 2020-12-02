//////////////////////////////////////////////////////////////////////
////                                                              ////
////  spi_top.v                                                   ////
////                                                              ////
////  This file is part of the SPI IP core project                ////
////  http://www.opencores.org/projects/spi/                      ////
////                                                              ////
////  Author(s):                                                  ////
////      - Simon Srot (simons@opencores.org)                     ////
////                                                              ////
////  All additional information is avaliable in the Readme.txt   ////
////  file.                                                       ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2002 Authors                                   ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////


`include "spi_defines.v"
`include "timescale.v"

//// BRING OUT TIP (Transfer in Progress)

module spi_top
(MASRST, 
  // Wishbone signals
  wb_clk_i, wb_rst_i, wb_adr_i, wb_dat_i, wb_dat_o,  wb_we_i, go, divider, spi_tx_sel, wb_stb_i, wb_cyc_i, wb_ack_o, wb_err_o, wb_int_o,

  // SPI signals
  ss_pad_o, sclk_pad_o, mosi_pad_o, miso_pad_i, DWR, DO, DAD, Pause, SPCREQ, SPCDIS, MRST, DBus, Sel, TP1, TPE1
);

// maybe go would have sufficied for pause, but still adding an extra signal for surety!!!
  parameter Tp = 1;

input MASRST;
  // Wishbone signals
  input                            wb_clk_i;         // master clock input
  input                            wb_rst_i;         // synchronous active high reset
  input                      [4:0] wb_adr_i;         // lower address bits
  input                   [32-1:0] wb_dat_i;         // databus input
 output                  [32-1:0] wb_dat_o;         // databus output
  //input                      [3:0] wb_sel_i;         // byte select inputs
  input                            wb_we_i;          // write enable input
  input go ; // start enable
  input                            wb_stb_i;         // stobe/core select signal
 input                            wb_cyc_i;         // valid bus cycle input
  output                           wb_ack_o;         // bus cycle acknowledge output
  output                           wb_err_o;         // termination w/ error
  output                           wb_int_o;         // interrupt request signal output
input [`SPI_DIVIDER_LEN-1:0] divider;   

input  [3:0] spi_tx_sel;

input Pause, SPCREQ, SPCDIS;

output reg DWR;
output reg [31:0]DO, DAD;

output [31:0] TP1, TPE1;
input MRST;
input MRST;
input [31:0] DBus;
input [1:0] Sel;

wire [7:0] EV;
wire [31:0] Val;
                                                     
  // SPI signals                                     
  output          [`SPI_SS_NB-1:0] ss_pad_o;         // slave select
  output                           sclk_pad_o;       // serial clock
  output                           mosi_pad_o;       // master out slave in
  input                            miso_pad_i;       // master in slave out
                                                     
  reg                     [32-1:0] wb_dat_o;
  reg                              wb_ack_o;
  reg                              wb_int_o;
                                               
  // Internal signals
  //reg       [`SPI_DIVIDER_LEN-1:0] divider;          // Divider register
  reg       [`SPI_CTRL_BIT_NB-1:0] ctrl;             // Control and status register
  reg             [`SPI_SS_NB-1:0] ss;               // Slave select register
  reg                     [32-1:0] wb_dat;           // wb data out
  wire         [`SPI_MAX_CHAR-1:0] rx;               // Rx register
  wire                             rx_negedge;       // miso is sampled on negative edge
  wire                             tx_negedge;       // mosi is driven on negative edge
  wire    [`SPI_CHAR_LEN_BITS-1:0] char_len;         // char len
  wire                             go;               // go
  wire                             lsb;              // lsb first on line
  wire                             ie;               // interrupt enable
  wire                             ass;              // automatic slave select
  wire                             spi_divider_sel;  // divider register select
  wire                             spi_ctrl_sel;     // ctrl register select
  //wire                       [3:0] spi_tx_sel;       // tx_l register select
  wire                             spi_ss_sel;       // ss register select
  wire                             tip;              // transfer in progress
  wire                             pos_edge;         // recognize posedge of sclk
  wire                             neg_edge;         // recognize negedge of sclk
  wire                             last_bit;         // marks last character bit

wire [3:0] wb_sel_i; // new one here


  

  


  
  // Wb acknowledge
  always @(posedge wb_clk_i or posedge wb_rst_i)
  begin
    if (wb_rst_i)
      wb_ack_o <= #Tp 1'b0;
    else
      wb_ack_o <= #Tp wb_cyc_i & wb_stb_i & ~wb_ack_o;
  end
  
  // Wb error
  assign wb_err_o = 1'b0;
  
  // Interrupt
  always @(posedge wb_clk_i or posedge wb_rst_i)
  begin
    if (wb_rst_i)
      wb_int_o <= #Tp 1'b0;
    else if (ie && tip && last_bit && pos_edge)
      wb_int_o <= #Tp 1'b1;
    else if (wb_ack_o)
      wb_int_o <= #Tp 1'b0;
  end
  

  

  
  assign rx_negedge = 1'b1;
  assign tx_negedge = 1'b1;
  assign char_len   = 7'b1111111;
  assign lsb        = 1'b1;
  assign ie         = 1'b1;
  assign wb_sel_i = 4'b1111;
  // What about go????????????????????????? (put it at input)

  
  assign ss_pad_o = 8'b00000001;

reg EN;
  
  spi_clgen clgen (.clk_in((wb_clk_i) && (Pause)), .rst((wb_rst_i) || (SPCDIS)), .go(go), .enable(tip), .last_clk(last_bit),
                   .divider(divider), .clk_out(sclk_pad_o), .pos_edge(pos_edge), 
                   .neg_edge(neg_edge));
  
  spi_shift shift (.clk((wb_clk_i) && (Pause)), .rst((wb_rst_i) || (SPCDIS)), .len(char_len[`SPI_CHAR_LEN_BITS-1:0]),
                   .latch(spi_tx_sel[3:0] & {4{(wb_we_i)||(EN)}}), .byte_sel(wb_sel_i), .lsb(lsb), 
                   .go(go), .pos_edge(pos_edge), .neg_edge(neg_edge), 
                   .rx_negedge(rx_negedge), .tx_negedge(tx_negedge),
                   .tip(tip), .last(last_bit), 
                   .p_in(wb_dat_i), .p_out(rx), 
                   .s_clk(sclk_pad_o), .s_in(miso_pad_i), .s_out(mosi_pad_o));

debug_SPI SPY(wb_clk_i, MRST, go, last_bit, wb_dat_i, wb_we_i, spi_tx_sel, wb_err_o, divider, mosi_pad_o, DBus, Sel, EV, Val, TP1, TPE1);

////// security wrapper ///////

reg [9:0] counter;
reg [3:0] state;
reg [127:0] buff[0:3];

reg wb_rst_i1;
reg go1;
reg Pause1;
reg wb_int_o1;

always @(posedge wb_clk_i)
begin
wb_rst_i1 <= wb_rst_i;
Pause1 <= Pause;
go1 <= go;
wb_int_o1 <= wb_int_o;
end

always @(posedge wb_clk_i)
begin
 if (((wb_rst_i == 1'b0) && (go1 == 1'b0) && (go == 1'b1) && (Pause == 1'b1)) || ((wb_int_o1 == 1'b0) && (wb_int_o == 1'b1)))
begin
	counter <= 10'd0;
end

else if ((wb_rst_i == 1'b0) && (go == 1'b1) && (Pause == 1'b1) && (SPCDIS == 1'b0))
begin
	counter <= counter + 10'd1;
end

end

//////////////////////////////////////////////////////////////////
reg [2:0] pastcount;
always @(*)
begin
if ((go1 == 1'b0)&&(go == 1'b1)) 
begin
pastcount = pastcount + 3'd1;
end
else if (MASRST == 1'b1)
begin
	pastcount = 3'd0;
end
end // need to incorporate a MASTER RESET signifying boot FROM SYTEM CONTROLLER
 

// what about the buffer

always @(pastcount)
begin
//if ((go1 == 1'b0)&&(go == 1'b1))  //// please check on this //////////////////////////////////////
//begin
buff[pastcount] = wb_dat_i; // 
//end
end // need to incorporate a MASTER RESET FROM SYTEM CONTROLLER

always @(posedge wb_clk_i)

begin
if (go == 1'b1)
begin
EN = 1'b1; // suppose wb_e cannot be zero during operation
end
else
begin
EN = 1'b0;
end
end

always @(posedge wb_clk_i)
begin

	if (MASRST == 1'b1)
	begin
         state <= 4'd0;
        end
else if ((wb_rst_i == 1'b0) && (go1 == 1'b0) && (go == 1'b1) && (Pause == 1'b1))
    	begin
	state <= 4'd1;
	end
else if ((Pause1 == 1'b1) && (Pause == 1'b0))
begin
state <= 4'd2;
end
else if ((Pause1 == 1'b0) && (Pause == 1'b1))
begin
state <= 4'd3;
end
else if ((wb_int_o1 == 1'b0) && (wb_int_o == 1'b1))
begin
state <= 4'd4;
end
else if (SPCREQ == 1'b1)
begin
state <= 4'd5;
end
else
begin
state <= 4'd6;
end

end


always @(state)
begin

if (SPCDIS == 1'b0) // an addition (CAN REMOVE THE DWR ADDITIONS LATER)
begin

	case(state)
4'd0:	begin
		DWR = 1'b0;
		DAD = 32'd0;
                DO = 32'd0;
	end
4'd1:	begin
		DWR = (1'b1); 
		DAD = 32'd96;
                DO = {spi_tx_sel, divider, 8'd0, state}; 
	end
4'd2:	begin
		DWR = (1'b1 && (!SPCDIS)); 
		DAD = DAD + 32'd1;
                DO = {counter, 18'd0, state}; 
	end
4'd3:	begin
		DWR = (1'b1 && (!SPCDIS)); 
		DAD = DAD + 32'd1;
                DO = {28'd0, state};
	end
4'd4:	begin
		DWR = (1'b1 && (!SPCDIS)); 
		DAD = DAD + 32'd1;
                DO = {tip, 27'd0, state}; 
	end
4'd5:	begin
		DWR = (1'b1 && (!SPCDIS));
		DAD = DAD + 32'd1;
                DO = {divider, counter, 2'd0, state}; 
	end
4'd6:	begin
		DWR = 1'b0;
		DAD = DAD;
                DO = 32'd0; 
	end
endcase

end
end

endmodule
  
