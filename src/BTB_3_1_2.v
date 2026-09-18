`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.07.2026 13:42:33
// Design Name: BTB
// Module Name: BTB
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

module BTB(
    input clk,
    input [3:0] rd_addr,                 // connected to PC_out[5:2]
    input BTB_write_control,             // connected to branching unit output
    input [3:0] ID_EX_PHT_wr_addr,       // connected to ID/EX PC_out[5:2]
    input [31:0] BTB_write_data,         // connected to PC_calculated
    input rst,
    output [31:0] BTB_rd_data            // used as input in MUX-1
);

    // 16 entries × 32 bits = 512 bits total
    reg [511:0] BTB;

    // Read one 32-bit entry
    assign BTB_rd_data = BTB[rd_addr * 32 +: 32];

    always @ (posedge clk or posedge rst)
    begin
        if (rst)
        begin
            BTB <= 512'b0;
        end
        else if (BTB_write_control)
        begin
            // Write one 32-bit entry
            BTB[ID_EX_PHT_wr_addr * 32 +: 32] <= BTB_write_data;
        end
    end

endmodule