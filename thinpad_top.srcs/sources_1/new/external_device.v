`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//-- FILE NAME	: external_device.v
//-- DESCRIPTION  : ��ģ��Ϊ �ⲿ�洢�� ����ģ�飨������SRAM�����ڵĴ���
//------------------------------------------------------------------------------
//-- Date         : 2023/6/10		  
//-- Coding_by	  : AXHU ������
//////////////////////////////////////////////////////////////////////////////////


module external_device(
    input   wire    clk,           //50MHz ʱ������
    input   wire    rst,
    
    input   wire    [3:0]   base_ram_state,
    input   wire    [2:0]   ext_ram_state,
    input   wire    [3:0]   Serial_state,
     
    // ȡָ��
    input   wire    [31:0]  rom_addr_i,     /// ��ȡָ��ĵ�ַ
    output  wire    [31:0]  rom_data_o,     /// ��ȡ����ָ��

    // ����
    input   wire    [31:0]  ram_addr_i,         // ����д �洢���ĵ�ַ
    input   wire    [3:0]   ram_sel_i,          // ����д �洢�����ֽ�ѡȡ���͵�ƽ��Ч��
    input   wire    [31:0]  ram_data_i,         // д����
    output  wire    [31:0]  ram_data_o,         // ������ 

    //ֱ�������ź�
    input     wire       rxd,  //ֱ�����ڽ��ն�
    output    wire       txd,  //ֱ�����ڷ��Ͷ�
        
    //BaseRAM�ź�
    inout   wire    [31:0]  base_ram_data,          //BaseRAM���ݣ���8λ��CPLD���ڿ���������
    output  wire    [19:0]  base_ram_addr,          //BaseRAM��ַ
    output  wire    [3:0]   base_ram_be_n,          //BaseRAM �ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
    output  wire    base_ram_ce_n,                  //BaseRAM Ƭѡ������Ч
    output  wire    base_ram_oe_n,                  //BaseRAM ��ʹ�ܣ�����Ч
    output  wire    base_ram_we_n,                  //BaseRAM дʹ�ܣ�����Ч

    //ExtRAM�ź�
    inout   wire    [31:0]  ext_ram_data,           //ExtRAM����
    output  wire    [19:0]  ext_ram_addr,           //ExtRAM��ַ
    output  wire    [3:0]   ext_ram_be_n,           //ExtRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
    output  wire    ext_ram_ce_n,                   //ExtRAMƬѡ������Ч
    output  wire    ext_ram_oe_n,                   //ExtRAM��ʹ�ܣ�����Ч
    output  wire    ext_ram_we_n                    //ExtRAMдʹ�ܣ�����Ч
    );
  
  wire [31:0] serial_o;
  wire [31:0] base_ram_o;
  wire [31:0] ext_ram_o;
  
  external_device_ctrl  IO_CTRL(
                .rst            (rst),
                                    
                .base_ram_state (base_ram_state),
                .ext_ram_state  (ext_ram_state),
                .Serial_state   (Serial_state),
                
                .ram_sel_i      (ram_sel_i),
                .serial_i       (serial_o),
                .base_ram_i     (base_ram_o),
                .ext_ram_i      (ext_ram_o),
                .ram_data_o     (ram_data_o)
                );
  
  
  baseram   BaseRAM(
                .base_ram_state (base_ram_state),
                .rom_addr_i     (rom_addr_i),
                .rom_data_o     (rom_data_o),
                
                .ram_addr_i     (ram_addr_i),
                .ram_data_i     (ram_data_i),
                .ram_sel_i      (ram_sel_i),   
                
                .base_ram_data  (base_ram_data),
                .base_ram_addr  (base_ram_addr),
                .base_ram_be_n  (base_ram_be_n),
                .base_ram_ce_n  (base_ram_ce_n),
                .base_ram_oe_n  (base_ram_oe_n),
                .base_ram_we_n  (base_ram_we_n),
                
                .base_ram_o     (base_ram_o)              
                );
  
  
  extram    ExtRAM(
                .ext_ram_state  (ext_ram_state),
                .ram_addr_i     (ram_addr_i),
                .ram_data_i     (ram_data_i),
                .ram_sel_i      (ram_sel_i),
        
                .ext_ram_data   (ext_ram_data),
                .ext_ram_addr   (ext_ram_addr),
                .ext_ram_be_n   (ext_ram_be_n),
                .ext_ram_ce_n   (ext_ram_ce_n),
                .ext_ram_oe_n   (ext_ram_oe_n),
                .ext_ram_we_n   (ext_ram_we_n),
                
                .ext_ram_o      (ext_ram_o)
                );
  
  
  serial    UART(
                .clk            (clk),
                .rst            (rst),
                
                .rxd            (rxd),
                .txd            (txd),
                                
                .Serial_state   (Serial_state),
                .ram_data_i     (ram_data_i),
                
                .serial_o       (serial_o)
                );
  

endmodule
