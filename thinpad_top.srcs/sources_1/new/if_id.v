`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//-- FILE NAME	: if_id.v
//-- DESCRIPTION  : 本模块为 if取指阶段 向 id译码阶段 的过渡模块
//------------------------------------------------------------------------------
//-- Date         : 2023/6/5		  
//-- Coding_by	  : AXHU 范紫骝
//////////////////////////////////////////////////////////////////////////////////


module if_id(
    input   wire    clk,
    input   wire    rst,
    
    input   wire    stall,
    input   wire    [31:0]  if_pc,
    input   wire    [31:0]  if_inst,
    output  reg     [31:0]  id_pc,
    output  reg     [31:0]  id_inst
    );
  
  always @ (posedge clk)
    begin
      if(rst)
        begin
          id_pc <= 32'h0000_0000;   //这里注意复位为 0x00000000，不是大赛规定if_pc复位为0x80000000
          id_inst <= 32'h0000_0000;
        end
      else if(!stall)
        begin
          id_pc <= if_pc;
          id_inst <= if_inst;
        end
    end

endmodule
