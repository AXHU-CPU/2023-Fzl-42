`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//-- FILE NAME	: id_ex.v
//-- DESCRIPTION  : 本模块为 id译码阶段 向 ex执行阶段 的过渡模块
//------------------------------------------------------------------------------
//-- Date         : 2023/6/5		  
//-- Coding_by	  : AXHU 范紫骝
//////////////////////////////////////////////////////////////////////////////////



module id_ex(
    input   wire    clk,
    input   wire    rst,
    
    input   wire    stall,
    
    input   wire    [31:0]  id_inst,
    input   wire    [31:0]  id_pc, 
    input   wire    [2:0]   id_aluop,
    input   wire    [2:0]   id_alusel,
    input   wire    id_reg_wen,
    input   wire    [4:0]   id_waddr,
    input   wire    [31:0]  id_reg1_data,
    input   wire    [31:0]  id_reg2_data,
    input   wire    [31:0]  id_link_addr,
    
    output  reg     [31:0]  ex_inst,
    output  reg     [31:0]  ex_pc,
    output  reg     [2:0]   ex_aluop,
    output  reg     [2:0]   ex_alusel,
    output  reg     ex_reg_wen,
    output  reg     [4:0]   ex_waddr,
    output  reg     [31:0]  ex_reg1_data,
    output  reg     [31:0]  ex_reg2_data,
    output  reg     [31:0]  ex_link_addr
    );
  
  always @ (posedge clk)
    begin
      if(rst) 
        begin
          ex_aluop <= 3'b000;
          ex_alusel <= 3'b000;
          ex_reg1_data <= 32'h0000_0000;
          ex_reg2_data <= 32'h0000_0000;
          ex_waddr <= 5'b00000;
          ex_reg_wen <= 1'b0;
          ex_link_addr <= 32'h0000_0000;
          ex_inst <= 32'h0000_0000;
          ex_pc <= 32'h0000_0000;
        end
      else if(stall)
        begin
          ex_aluop <= 3'b000;
          ex_alusel <= 3'b000;
          ex_reg1_data <= 32'h0000_0000;
          ex_reg2_data <= 32'h0000_0000;
          ex_waddr <= 5'b00000;
          ex_reg_wen <= 1'b0;
          ex_link_addr <= 32'h0000_0000;
          ex_inst <= 32'h0000_0000;
          ex_pc <= 32'h0000_0000;
        end
      else
        begin
          ex_aluop <= id_aluop;
          ex_alusel <= id_alusel;
          ex_reg1_data <= id_reg1_data;
          ex_reg2_data <= id_reg2_data;
          ex_waddr <= id_waddr;
          ex_reg_wen <= id_reg_wen;
          ex_link_addr <= id_link_addr;
          ex_inst <= id_inst;
          ex_pc <= id_pc;
        end
    end

endmodule
