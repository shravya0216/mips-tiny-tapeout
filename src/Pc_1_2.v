`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.07.2026 10:25:26
// Design Name: 
// Module Name: Pc
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


module Pc(
input clk,
input PC_flush,//this connection comes from output of flushing unit 
input PC_stall,//this connection comes from output of stalling unit 
input [31:0] PC_in,//this connection from output of MUX2 in instruction fetch stage 
input [31:0] PC_calculated,//this comes from execution unit 
input        hold,
input        rst,
output reg [31:0] PC_out
    );
    always @ (posedge clk or posedge rst) //making it sequential
    begin
    if(rst)
    begin
        PC_out <= 32'h00000000;
    end
    else if(hold)
    begin
        PC_out <= PC_out;
    end
    else if(PC_flush)//utmost priority to flush 
    begin
    PC_out<=PC_calculated;//giving the correct PC
    end
    else if(PC_stall)
    begin
    PC_out<=PC_out;//retaining the same intruction 
    end
    else 
    PC_out<=PC_in;//our prediction 
    end
endmodule
