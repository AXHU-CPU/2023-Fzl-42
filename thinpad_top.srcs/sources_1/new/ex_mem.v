`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//-- FILE NAME	: ex_mem.v
//-- DESCRIPTION  : 本模块为 ex执行阶段 向 mem访存阶段 的过渡模块
//------------------------------------------------------------------------------
//-- Date         : 2023/6/5		  
//-- Coding_by	  : AXHU 范紫骝
//////////////////////////////////////////////////////////////////////////////////


module ex_mem(
    input   wire    clk,
    input   wire    rst,
    
    input   wire    [3:0]   ex_Load_and_Store_op,
    input   wire    ex_reg_wen,
    input   wire    [4:0]   ex_waddr,
    input   wire    [31:0]  ex_wdata,
    
    input   wire    [31:0]  ex_memory_Load_AND_Store_addr,
    input   wire    [31:0]  ex_reg2_data,
    
    input   wire    [31:0]  ex_pc,
    input   wire    ex_memory_wen,
    input   wire    ex_is_base_ram,
    input   wire    ex_is_ext_ram,
    input   wire    ex_is_SerialDate,
    input   wire    ex_is_SerialStat,
    
    
    
    output  reg     [3:0]   mem_Load_and_Store_op,
    output  reg     mem_reg_wen,
    output  reg     [4:0]   mem_waddr,
    output  reg     [31:0]  mem_wdata,
    
    output  reg     [31:0]  mem_memory_Load_AND_Store_addr,
    output  reg     [31:0]  mem_reg2_data,
    
    output  reg     [31:0]  mem_pc,
    
    output  reg     mem_memory_wen,
    output  reg     mem_is_base_ram,
    output  reg     mem_is_ext_ram,
    output  reg     mem_is_SerialDate,
    output  reg     mem_is_SerialStat,
    
    
    output  reg     [31:0]  mem_last_memorystore_addr,  // 用作 ID阶段 load类数据相关的 判断，优化程度小
    output  reg     [31:0]  mem_last_memorystore_data   
    );
  
  always @ (posedge clk)
    begin
      if(rst)
        begin
          mem_reg_wen <= 1'b0;
          mem_waddr <= 5'b00000;
          mem_wdata <= 32'h0000_0000;
          mem_Load_and_Store_op <= 4'b0_000;
          mem_memory_Load_AND_Store_addr <= 32'h0000_0000;
          mem_reg2_data <= 32'h0000_0000;
          mem_pc <= 32'h0;
          
          mem_memory_wen <= 1'b1;
          mem_is_base_ram <= 1'b0;
          mem_is_ext_ram <= 1'b0;
          mem_is_SerialDate <= 1'b0;
          mem_is_SerialStat <= 1'b0;
        end
      else
        begin
          mem_reg_wen <= ex_reg_wen;
          mem_waddr <= ex_waddr;
          mem_wdata <= ex_wdata;
          mem_Load_and_Store_op <= ex_Load_and_Store_op;
          mem_memory_Load_AND_Store_addr <= ex_memory_Load_AND_Store_addr;
          mem_reg2_data <= ex_reg2_data;
          mem_pc <= ex_pc;
          
          mem_memory_wen <= ex_memory_wen;
          mem_is_base_ram <= ex_is_base_ram;
          mem_is_ext_ram <= ex_is_ext_ram;
          mem_is_SerialDate <= ex_is_SerialDate;
          mem_is_SerialStat <= ex_is_SerialStat;
        end
    end
  
  
  // 由于 作者的伪cache 是延时1周期写入数据，则最近写入extram的数据将不过会立即命中
  // 故在ex_mem 记录最近写入ram的数据，优化 作者伪cache 的缺陷
  always @ (posedge clk)
    begin
      if(rst)
        begin
          mem_last_memorystore_addr <= 32'h0000_0000;
          mem_last_memorystore_data <= 32'h0000_0000;
        end
      else if(ex_Load_and_Store_op == 4'b1_010)         // sb
        begin
          mem_last_memorystore_addr <= ex_memory_Load_AND_Store_addr;
          case(ex_memory_Load_AND_Store_addr[1:0])
            2'b00: mem_last_memorystore_data <= {24'h000000, ex_reg2_data[7:0]};
            2'b01: mem_last_memorystore_data <= {16'h0000, ex_reg2_data[7:0], 8'h00};
            2'b10: mem_last_memorystore_data <= {8'h00, ex_reg2_data[7:0], 16'h0000};
            2'b11: mem_last_memorystore_data <= {ex_reg2_data[7:0], 24'h000000};   
          endcase
        end
      else if(ex_Load_and_Store_op == 4'b1_011)         // sw
        begin
          mem_last_memorystore_addr <= ex_memory_Load_AND_Store_addr;
          mem_last_memorystore_data <= ex_reg2_data;
        end
    end

endmodule
