`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//-- FILE NAME	: extram.v
//-- DESCRIPTION  : ��ģ��Ϊ ExtRAM�Ĵ���ģ��
//------------------------------------------------------------------------------
//-- Date         : 2023/6/10	  
//-- Coding_by	  : AXHU ������
//////////////////////////////////////////////////////////////////////////////////


module extram(
    input   wire    [2:0]   ext_ram_state,
    
    input   wire    [31:0]  ram_addr_i,
    input   wire    [31:0]  ram_data_i,
    input   wire    [3:0]   ram_sel_i,
    
    inout   wire    [31:0]  ext_ram_data,           //ExtRAM����
    output  wire    [19:0]  ext_ram_addr,           //ExtRAM��ַ
    output  wire    [3:0]   ext_ram_be_n,           //ExtRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
    output  wire    ext_ram_ce_n,                   //ExtRAMƬѡ������Ч
    output  wire    ext_ram_oe_n,                   //ExtRAM��ʹ�ܣ�����Ч
    output  wire    ext_ram_we_n,                   //ExtRAMдʹ�ܣ�����Ч
    
    output  wire    [31:0]  ext_ram_o
    );
  
  
  
  /// ����ExtRam                       /// store ָ��
 assign ext_ram_data = ext_ram_state[2] ? ram_data_i : 32'hzzzzzzzz;
 assign ext_ram_o = ext_ram_data;
 
  // ext_ram_state
 // [0] : rst               ��λ �� ������д״̬ 
 // [1] : is_ext_ram && ram_we_n        ������ 
 // [2] : is_ext_ram && !ram_we_n       д����
 
 assign ext_ram_addr = ext_ram_state[0] ? 20'h00000 : ram_addr_i[21:2];
 
 assign ext_ram_be_n = ext_ram_state[0] ? 4'b0000   : ram_sel_i;
 
 assign ext_ram_ce_n = ext_ram_state[0] ? 1'b1      : 1'b0;
 
 assign ext_ram_oe_n = ext_ram_state[1] ? 1'b0      : 1'b1;
 
 assign ext_ram_we_n = ext_ram_state[2] ? 1'b0      : 1'b1;
   
    
endmodule
