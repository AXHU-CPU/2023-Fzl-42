`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//-- FILE NAME	: mem_wb.v
//-- DESCRIPTION  : 本模块为 mem访存阶段 向 wb写回阶段 的过渡模块
//------------------------------------------------------------------------------
//-- Date         : 2023/6/5		  
//-- Coding_by	  : AXHU 范紫骝
//////////////////////////////////////////////////////////////////////////////////


module mem_wb(
    input   wire    clk,
    input   wire    rst,
    
    input   wire    [31:0]  mem_pc,
    input   wire    mem_reg_wen,
    input   wire    [4:0]   mem_reg_waddr,
    input   wire    [31:0]  mem_reg_wdata,
    
    output  reg     [31:0]  wb_pc,
    output  reg     wb_reg_wen,
    output  reg     [4:0]   wb_reg_waddr,
    output  reg     [31:0]  wb_reg_wdata
    );
  
  always @ (posedge clk)
    begin
      if(rst)
        begin
          wb_pc <= 32'h0000_0000;
          wb_reg_wen <= 1'b0;
          wb_reg_waddr <= 5'b00000;
          wb_reg_wdata <= 32'h0000_0000;
        end
      else
        begin
          wb_pc <= mem_pc;
          wb_reg_wen <= mem_reg_wen;
          wb_reg_waddr <= mem_reg_waddr;
          wb_reg_wdata <= mem_reg_wdata;
        end
    end  

endmodule