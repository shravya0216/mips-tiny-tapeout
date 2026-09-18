`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: tt_um_yourname   (rename to your actual TT project name)
//
// Tiny Tapeout's fixed harness wrapper. This is the ONLY new file needed --
// it maps TT's fixed pin contract onto your existing, unmodified `top`
// module. No pipeline logic lives here; this is pure pin plumbing.
//
// Pin mapping (adjust bit positions if you'd rather group them differently):
//   ui_in[0]   -> scl
//   uio[0]     -> sda (bidirectional, open-drain)
//   uo_out[0]  -> led
//   rst_n      -> inverted into this design's active-high rst
//   ena        -> currently unused; outputs already default safely via the
//                 uio_oe/uo_out assignments below regardless of ena's state
//////////////////////////////////////////////////////////////////////////////////

module TT_processor_chip (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire        ena,
    input  wire        clk,
    input  wire        rst_n
);

    wire rst = ~rst_n;          // this design uses active-high reset internally
    wire scl = ui_in[0];
    wire led_internal;

    wire sda_in  = uio_in[0];
    wire sda_out;
    wire sda_oe_internal;

    top top_inst (
        .clk(clk),
        .rst(rst),
        .scl(scl),
        .sda_in(sda_in),
        .sda_out(sda_out),
        .sda_oe(sda_oe_internal),
        .led(led_internal)
    );

    // Bidirectional pin 0 = sda. Every other uio pin stays a safe, inactive input.
    assign uio_out[0]   = sda_out;
    assign uio_oe[0]    = sda_oe_internal;
    assign uio_out[7:1] = 7'b0;
    assign uio_oe[7:1]  = 7'b0;

    // Dedicated output pin 0 = led. Rest held at 0.
    assign uo_out[0]   = led_internal;
    assign uo_out[7:1] = 7'b0;

    // ena is intentionally unused for now -- outputs are already driven to
    // safe, defined values above regardless of tile-select state.
    wire _unused_ena = ena;

endmodule