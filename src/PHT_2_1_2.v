`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.07.2026 10:30:47
// Design Name: PHT
// Module Name: PHT
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

module PHT(
    input clk,
    input [3:0] rd_addr,              // connected to PC_out[5:2]
    input PHT_write_control,          // connected to branching unit output
    input [3:0] ID_EX_PHT_wr_addr,    // connected to PC[5:2] in execution stage
    input PHT_write_data,             // connected to zero status of ALU
    input rst,
    output [3:0] PHT_rd_data          // used as input in Xor module
);

    // 16 entries × 4 bits = 64 bits total
    reg [63:0] PHT;

    // Read one 4-bit entry
    assign PHT_rd_data = PHT[rd_addr * 4 +: 4];

    always @ (posedge clk or posedge rst)
    begin
        if (rst)
        begin
            PHT <= 64'b0;
        end
        else if (PHT_write_control)
        begin
            // Preserve original behavior:
            // shift the 4-bit counter and insert new outcome as LSB
            PHT[ID_EX_PHT_wr_addr * 4 +: 4] <= {
                PHT[ID_EX_PHT_wr_addr * 4 + 2],
                PHT[ID_EX_PHT_wr_addr * 4 + 1],
                PHT[ID_EX_PHT_wr_addr * 4 + 0],
                PHT_write_data
            };
        end
    end

endmodule