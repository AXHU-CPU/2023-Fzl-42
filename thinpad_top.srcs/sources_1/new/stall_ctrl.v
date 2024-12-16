`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//-- FILE NAME	: stall_ctrl.v
//-- DESCRIPTION  : 本模块为 流水线暂停模块 
//------------------------------------------------------------------------------
//-- Date         : 2023/6/5		  
//-- Coding_by	  : AXHU 范紫骝
//////////////////////////////////////////////////////////////////////////////////


module stall_ctrl(
    input   wire    rst,
    input   wire    stallreq_from_id,
    input   wire    stallreq_from_mem,
    output  wire    stall
    );
  
  assign stall = rst ? 1'b0 : 
                 stallreq_from_mem ? 1'b1 : 
                 stallreq_from_id;
                 
  // stallreq_from_id = 1 时，需要 IF（pc_reg）模块暂停pc变化、IF/ID模块暂停取值、ID/EX模块等效复位
  // stallreq_from_mem = 1 时，仅需要 IF（pc_reg）模块暂停pc变化、IF/ID模块暂停取值、
endmodule
