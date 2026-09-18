`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.07.2026 11:18:54
// Design Name: 
// Module Name: BHT
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module BHT(
    input clk,
    input [3:0] rd_addr,              // this will be connected to XOR_result or BHT_wr_addr
    input BHT_write_control,          // this is connected to output of branching unit
    input [3:0] ID_EX_BHT_wr_addr,    // this is connected to the XOR result
    input BHT_write_data,              // this is connected to the zero status of the ALU
    input rst,
    output BHT_rd_data                 // select line for mux 1
);

    // 16 one-bit BHT entries represented as a packed vector
    reg [15:0] BHT;

    assign BHT_rd_data = BHT[rd_addr];

    always @ (posedge clk or posedge rst)
    begin
        if (rst)
        begin
            BHT <= 16'b0;
        end
        else if (BHT_write_control)
        begin
            BHT[ID_EX_BHT_wr_addr] <= BHT_write_data;
        end
    end

endmodule