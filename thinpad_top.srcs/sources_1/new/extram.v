`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//-- FILE NAME	: extram.v
//-- DESCRIPTION  : 本模块为 ExtRAM的处理模块
//------------------------------------------------------------------------------
//-- Date         : 2023/6/10	  
//-- Coding_by	  : AXHU 范紫骝
//////////////////////////////////////////////////////////////////////////////////


module extram(
    input   wire    [2:0]   ext_ram_state,
    
    input   wire    [31:0]  ram_addr_i,
    input   wire    [31:0]  ram_data_i,
    input   wire    [3:0]   ram_sel_i,
    
    inout   wire    [31:0]  ext_ram_data,           //ExtRAM数据
    output  wire    [19:0]  ext_ram_addr,           //ExtRAM地址
    output  wire    [3:0]   ext_ram_be_n,           //ExtRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output  wire    ext_ram_ce_n,                   //ExtRAM片选，低有效
    output  wire    ext_ram_oe_n,                   //ExtRAM读使能，低有效
    output  wire    ext_ram_we_n,                   //ExtRAM写使能，低有效
    
    output  wire    [31:0]  ext_ram_o
    );
  
  
  
  /// 处理ExtRam                       /// store 指令
 assign ext_ram_data = ext_ram_state[2] ? ram_data_i : 32'hzzzzzzzz;
 assign ext_ram_o = ext_ram_data;
 
  // ext_ram_state
 // [0] : rst               复位 或 不读不写状态 
 // [1] : is_ext_ram && ram_we_n        读数据 
 // [2] : is_ext_ram && !ram_we_n       写数据
 
 assign ext_ram_addr = ext_ram_state[0] ? 20'h00000 : ram_addr_i[21:2];
 
 assign ext_ram_be_n = ext_ram_state[0] ? 4'b0000   : ram_sel_i;
 
 assign ext_ram_ce_n = ext_ram_state[0] ? 1'b1      : 1'b0;
 
 assign ext_ram_oe_n = ext_ram_state[1] ? 1'b0      : 1'b1;
 
 assign ext_ram_we_n = ext_ram_state[2] ? 1'b0      : 1'b1;
   
    
endmodule
