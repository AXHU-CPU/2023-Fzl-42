`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//-- FILE NAME	: external_device.v
//-- DESCRIPTION  : 本模块为 外部存储器 访问模块（包含对SRAM、串口的处理）
//------------------------------------------------------------------------------
//-- Date         : 2023/6/10		  
//-- Coding_by	  : AXHU 范紫骝
//////////////////////////////////////////////////////////////////////////////////


module external_device(
    input   wire    clk,           //50MHz 时钟输入
    input   wire    rst,
    
    input   wire    [3:0]   base_ram_state,
    input   wire    [2:0]   ext_ram_state,
    input   wire    [3:0]   Serial_state,
     
    // 取指令
    input   wire    [31:0]  rom_addr_i,     /// 读取指令的地址
    output  wire    [31:0]  rom_data_o,     /// 获取到的指令

    // 数据
    input   wire    [31:0]  ram_addr_i,         // 读、写 存储器的地址
    input   wire    [3:0]   ram_sel_i,          // 读、写 存储器的字节选取（低电平有效）
    input   wire    [31:0]  ram_data_i,         // 写数据
    output  wire    [31:0]  ram_data_o,         // 读数据 

    //直连串口信号
    input     wire       rxd,  //直连串口接收端
    output    wire       txd,  //直连串口发送端
        
    //BaseRAM信号
    inout   wire    [31:0]  base_ram_data,          //BaseRAM数据，低8位与CPLD串口控制器共享
    output  wire    [19:0]  base_ram_addr,          //BaseRAM地址
    output  wire    [3:0]   base_ram_be_n,          //BaseRAM 字节使能，低有效。如果不使用字节使能，请保持为0
    output  wire    base_ram_ce_n,                  //BaseRAM 片选，低有效
    output  wire    base_ram_oe_n,                  //BaseRAM 读使能，低有效
    output  wire    base_ram_we_n,                  //BaseRAM 写使能，低有效

    //ExtRAM信号
    inout   wire    [31:0]  ext_ram_data,           //ExtRAM数据
    output  wire    [19:0]  ext_ram_addr,           //ExtRAM地址
    output  wire    [3:0]   ext_ram_be_n,           //ExtRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output  wire    ext_ram_ce_n,                   //ExtRAM片选，低有效
    output  wire    ext_ram_oe_n,                   //ExtRAM读使能，低有效
    output  wire    ext_ram_we_n                    //ExtRAM写使能，低有效
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
