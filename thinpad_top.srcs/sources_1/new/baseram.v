`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//-- FILE NAME	: baseram.v
//-- DESCRIPTION  : 本模块为 BaseRAM的处理模块
//------------------------------------------------------------------------------
//-- Date         : 2023/6/10		  
//-- Coding_by	  : AXHU 范紫骝
//////////////////////////////////////////////////////////////////////////////////


module baseram(
    input   wire    [3:0]   base_ram_state,
    
    input   wire    [31:0]  rom_addr_i,
    output  reg     [31:0]  rom_data_o,
    
    input   wire    [31:0]  ram_addr_i,
    input   wire    [31:0]  ram_data_i,
    input   wire    [3:0]   ram_sel_i,   
    
    inout   wire    [31:0]  base_ram_data,          //BaseRAM数据，低8位与CPLD串口控制器共享
    output  wire    [19:0]  base_ram_addr,          //BaseRAM地址
    output  wire    [3:0]   base_ram_be_n,          //BaseRAM 字节使能，低有效。如果不使用字节使能，请保持为0
    output  wire    base_ram_ce_n,                  //BaseRAM 片选，低有效
    output  wire    base_ram_oe_n,                  //BaseRAM 读使能，低有效
    output  wire    base_ram_we_n,                  //BaseRAM 写使能，低有效
    
    output  wire    [31:0]  base_ram_o
    
    );
  
  
   /// BaseRam 管理指令或者数据的存取   
    /// 在访存BaseRam的基础上，执行的是store 指令下才能赋 CPU计算的数据，
    /// 其他情况下，根据 inout 双向端口 的三态门，在赋高阻值情况下，实际可取 外部文件里的 指令
 assign base_ram_data = base_ram_state[3] ? ram_data_i : 32'hzzzzzzzz;
 assign base_ram_o = base_ram_data;      /// 在读取模式下，读取到的BaseRam数据
  
  
  
  /// 处理BaseRam
 /// 在需要从BaseRam中获取或者写入数据的时候，往往认为CPU会暂停流水线（1个时钟周期）
 
 // base_ram_state
 // [0] : rst                   复位 或 不读不写状态
 // [1] : rom_ce_i                      (ROM)读指令
 // [2] : is_base_ram && ram_we_n       (RAM)读数据 
 // [3] : is_base_ram && !ram_we_n      (RAM)写数据 

 
 assign base_ram_addr = base_ram_state[0] ? 20'h00000 : 
                        base_ram_state[1] ? rom_addr_i[21:2] : ram_addr_i[21:2]; 
                        
 assign base_ram_be_n = base_ram_state[0] ? 4'b0000 : 
                        base_ram_state[1] ? 4'b0000 : ram_sel_i;
 
 assign base_ram_ce_n = base_ram_state[0] ? 1'b1 : 1'b0;

 assign base_ram_oe_n = base_ram_state[0] ? 1'b1 : 
                        base_ram_state[3] ? 1'b1 : 1'b0;
 
 assign base_ram_we_n = base_ram_state[3] ? 1'b0 : 1'b1;

 always @ (*)
   begin
     if(base_ram_state[0])
       rom_data_o <= 32'h0000_0000;
     else if(base_ram_state[1]) /// 不涉及到BaseRam的相关数据操作，仅 IF阶段 需要从BaseRam上 继续取指令
       rom_data_o <= base_ram_o;
     else                      
       rom_data_o <= 32'h0000_0000;
   end


  
endmodule
