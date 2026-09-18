`timescale 1ns / 1ps

// 1-KB byte-addressed instruction memory.
// CPU fetch keeps the original byte-addressed PC convention.
// Programming writes one 32-bit instruction at a time, MSB first.
module instruction_memory(
    input        rst,
    input        clk,
    input [31:0] PC_out,
    output [31:0] instruction_code,
    input        prog_we,
    input [7:0]  prog_addr,
    input [31:0] prog_wdata,
    output [31:0] prog_rdata
);
    integer i;
    reg [7:0] IM [1023:0];

    assign instruction_code = {IM[PC_out[9:0]], IM[PC_out[9:0]+10'd1],
                               IM[PC_out[9:0]+10'd2], IM[PC_out[9:0]+10'd3]};

    // I2C readback: the word at prog_addr, MSB first (same layout as writes).
    assign prog_rdata = {IM[{prog_addr,2'b00}], IM[{prog_addr,2'b00}+10'd1],
                         IM[{prog_addr,2'b00}+10'd2], IM[{prog_addr,2'b00}+10'd3]};

    always @(posedge clk) begin
        if (prog_we) begin
            IM[{prog_addr,2'b00}]     <= prog_wdata[31:24];
            IM[{prog_addr,2'b00}+10'd1] <= prog_wdata[23:16];
            IM[{prog_addr,2'b00}+10'd2] <= prog_wdata[15:8];
            IM[{prog_addr,2'b00}+10'd3] <= prog_wdata[7:0];
        end
    end
endmodule
