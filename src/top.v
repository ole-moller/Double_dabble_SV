/*
 * Copyright (c) 2026 Ole Henrik Møller
 * SPDX-License-Identifier: Apache-2.0
 */

`define default_netname none

module tt_um_ole_moller_double_dabble_SV ( 
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // Unused utility and user inputs (avoid warnings)

  wire _unused = &{ena, uio_in};

  // All output pins must be assigned. If not used, assign to 0.

  assign uio_oe  = 1;
  
  double_dabble_SV u1 ( 
    .bin(           ui_in[7:0]),
    .segments(      uo_out[6:0]),
    .separator(     uo_out[7]),
    .bcd_dd(        uio_out[7:0]),
    .rst_n(         rst_n),
    .clk(           clk)
    );

endmodule
