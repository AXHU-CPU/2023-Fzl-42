`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//-- FILE NAME	: extram_cache.v
//-- DESCRIPTION  : 本模块为 伪·Data cache（历史数据记录堆），记录ExtRAM历史数据
//------------------------------------------------------------------------------
//-- Date         : 2023/6/29		  
//-- Coding_by	  : AXHU 范紫骝
//////////////////////////////////////////////////////////////////////////////////


module extram_cache(
    input   wire    clk,
    input   wire    rst,
    
    input   wire    [2:0]   ext_ram_state,
    /*  写入数据  */
    input   wire    [31:0]  ram_addr_i,
    input   wire    [31:0]  ram_wdata_i,
    
    /*  读取数据  */
    input   wire    is_ext_ram_i,
    input   wire    hit_ren_i,
    input   wire    [31:0]  hit_extram_addr, 
    output  wire    [31:0]  hit_extram_data,
    output  wire    hit_dcache
    );
  
  
  wire extram_we;               // 对伪·cache的写入使能
  wire [31:0] extram_waddr;     // 对伪·cache的写入地址
  wire [31:0] extram_wdata;     // 对伪·cache的写入数据
  assign extram_we = ext_ram_state[0] ? 1'b0 : ext_ram_state[2] ? 1'b1 : 1'b0;
  assign extram_waddr = ext_ram_state[0] ? 32'h0 : ext_ram_state[2] ? ram_addr_i : 32'h0;
  assign extram_wdata = ext_ram_state[0] ? 32'h0 : ext_ram_state[2] ? ram_wdata_i : 32'h0;
  
  wire [31:0] hit_ram_addr;     // 查找地址，cache未使用时为0
  assign hit_ram_addr = hit_ren_i  ? hit_extram_addr : 32'h0;
  
  wire hit_cache;       // 命中标志，命中为1，没有命中为0
  wire [31:0] hit_data; // 命中数据
  cache    data_cache(
            .clk                (clk),
            .rst                (rst),
            
            .we                 (extram_we),
            .ram_waddr_i        (extram_waddr),
            .ram_wdata_i        (extram_wdata),
            
            .is_ext_ram_i       (is_ext_ram_i),
            //加入is_ext_ram_i ，避免其他ram地址[21:2]命中cache中数据，导致对应计数器重置为0
            
            .hit_ren_i          (hit_ren_i),
            .memory_addr_i      (hit_ram_addr),
            .hit_cache_sign_o   (hit_cache),
            .hit_cache_data_o   (hit_data)
            );
  
  assign hit_extram_data = hit_cache ? hit_data : 32'h0;
  
  reg hit_en_n;                 // cache 可读取使能（低电平有效）， 确保在写入第一个数据后才能使用读取命中功能
  reg [31:0] last_ext_addr;     // 用于保存上一个写入cache的地址
  wire hit_en_sign = (last_ext_addr == 32'h8040_0000) ? 
                        ((ram_addr_i != 32'h8040_0000) ? 1'b1 : 1'b0) : 1'b0;
  
  always @ (negedge clk)
    begin
      if(rst)
        last_ext_addr <= 32'h0000_0000;
      else if(ext_ram_state[2])
        last_ext_addr <= ram_addr_i;
    end
    
  always @ (negedge clk, posedge rst)
    begin
      if(rst)
        hit_en_n <= 1'b1;
      else if(hit_en_n)
        begin
          if(hit_en_sign)
            hit_en_n <= 1'b0;               // 注：这里hit_en_n 是0有效，仅作者设置，与大赛要求无关
        end
    end
    
  assign hit_dcache = (hit_en_n == 1'b0) ? hit_cache : 1'b0;
  
endmodule
