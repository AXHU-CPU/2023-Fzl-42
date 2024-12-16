`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//-- FILE NAME	: cache.v
//-- DESCRIPTION  : 本模块为 伪·cache（历史数据记录堆），采用了LRU算法的替换策略
//------------------------------------------------------------------------------
//-- Date         : 2023/6/29		  
//-- Coding_by	  : AXHU 范紫骝
//////////////////////////////////////////////////////////////////////////////////


module cache(
    input   wire    clk,
    input   wire    rst,
    /*写数据*/
    input   wire    we,
    input   wire    [31:0]  ram_waddr_i,
    input   wire    [31:0]  ram_wdata_i,
    /*读数据*/
    input   wire    is_ext_ram_i,
    input   wire    hit_ren_i,
    input   wire    [31:0]  memory_addr_i,
    output  wire     hit_cache_sign_o,
    output  wire    [31:0]  hit_cache_data_o
    );
  
  reg [52:0] cache_file [3:0];
  // cache_file[52]    ： 数据所在寄存器的使能（数据是否可以使用）
  // cache_file[51:32] ： 数据在SRAM里的地址
  // cache_file[31:0]  ： 数据
  
  reg [19:0] cache_file_addr_part [3:0];    // 存入的地址（方便写入或读取时操作）
  reg [31:0] cache_file_data_part [3:0];    // 存入的数据
  wire [3:0] regfile_valid;         // 每一位代表对应寄存器是否可以使用
  wire [3:0] cacheaddr_is_memaddr;          //传入数据的地址 是否命中 伪·cache中所存储的地址
  
  integer i, j, k, m;
  always @ (*)
    begin
      for(i=0; i<=3; i=i+1)
        begin
          cache_file_addr_part[i] = cache_file[i][51:32];
          cache_file_data_part[i] = cache_file[i][31:0];
        end
    end
    
  assign regfile_valid = {cache_file[3][52],  cache_file[2][52],  cache_file[1][52],  cache_file[0][52]};
  
  assign cacheaddr_is_memaddr = {(cache_file_addr_part[3] == ram_waddr_i[21:2]),  (cache_file_addr_part[2] == ram_waddr_i[21:2]),
                                 (cache_file_addr_part[1] == ram_waddr_i[21:2]),  (cache_file_addr_part[0] == ram_waddr_i[21:2]) };
                                 
  reg [1:0] cnt [3:0];      //  由于使用了LRU（最近最少使用）算法，给每个寄存器搭配一个计数器
                        // 当伪·cache数据块存满后，再次写入数据，替换至计数器最大所在的寄存器数据块

  wire [1:0] max_cnt_index;
  assign max_cnt_index = rst ? 2'd0 : 
                         regfile_valid[3] ? 
                            ((cnt[0] == 2'd3) ? 2'd0 :
                             (cnt[1] == 2'd3) ? 2'd1 :
                             (cnt[2] == 2'd3) ? 2'd2 :
                             (cnt[3] == 2'd3) ? 2'd3 : 2'd0) : 2'd0;
/*******************       伪·cache 写入数据部分      ******************/
  
  wire [1:0] reg_waddr;    // 保存写入数据的写入寄存器地址（即寄存器号）
  assign reg_waddr = rst ? 2'd0 : 
                     regfile_valid[3] ? 
                       (cacheaddr_is_memaddr[0] ? 2'd0 : 
                        cacheaddr_is_memaddr[1] ? 2'd1 : 
                        cacheaddr_is_memaddr[2] ? 2'd2 : 
                        cacheaddr_is_memaddr[3] ? 2'd3 : max_cnt_index) :
                     regfile_valid[2] ? 
                       (cacheaddr_is_memaddr[0] ? 2'd0 : 
                        cacheaddr_is_memaddr[1] ? 2'd1 : 
                        cacheaddr_is_memaddr[2] ? 2'd2 : 2'd3) :
                     regfile_valid[1] ? 
                       (cacheaddr_is_memaddr[0] ? 2'd0 : 
                        cacheaddr_is_memaddr[1] ? 2'd1 : 2'd2) :
                     regfile_valid[0] ? 
                       (cacheaddr_is_memaddr[0] ? 2'd0 : 2'd1) : 2'd0;
                          
  
  
  always @ (posedge clk)                    /* 时钟上升沿 写入数据 */
    begin
      if(rst)
        for(j=0; j<=3; j=j+1)
          cache_file[j] <= 53'h0;
      else if(we)
          cache_file[reg_waddr] <= {1'b1, ram_waddr_i[21:2], ram_wdata_i};
    end
    
    
  wire [1:0] hit_reg_addr;
  
  wire [3:0] cnt_reset;
  assign cnt_reset[0] = !cache_file[0][52] ? 1'b1 : 
                        (hit_cache_sign_o && (hit_reg_addr == 0)) ? 1'b1 : 
                        (we && (reg_waddr == 0)) ? 1'b1 : 1'b0;
  assign cnt_reset[1] = !cache_file[1][52] ? 1'b1 : 
                        (hit_cache_sign_o && (hit_reg_addr == 1)) ? 1'b1 : 
                        (we && (reg_waddr == 1)) ? 1'b1 : 1'b0;
  assign cnt_reset[2] = !cache_file[2][52] ? 1'b1 : 
                        (hit_cache_sign_o && (hit_reg_addr == 2)) ? 1'b1 : 
                        (we && (reg_waddr == 2)) ? 1'b1 : 1'b0;
  assign cnt_reset[3] = !cache_file[3][52] ? 1'b1 : 
                        (hit_cache_sign_o && (hit_reg_addr == 3)) ? 1'b1 : 
                        (we && (reg_waddr == 3)) ? 1'b1 : 1'b0;
   

  always @ (posedge clk)                    /* 写入数据的同时，修改计数器 */
    begin
      if(rst)
        for(m=0; m<=3; m=m+1)
          cnt[m] <= 2'd0;
      else
        for(m=0; m<=3; m=m+1)
          if(cnt_reset[m])
            cnt[m] <= 2'd0;
          else if(we)
            cnt[m] <= cnt[m] + 2'd1;    // 其余情况，每写入一次，未命中寄存器的计数器 +1          
    end
   

     
/*******************       伪·cache 读取数据部分     ******************/

  wire [20:0] hit_addr ={1'b1, memory_addr_i[21:2]}; // 能满足命中的数据块，其寄存器使能应满足为1，即有效 
  
  assign hit_cache_sign_o = rst ? 1'b0 : 
                            (hit_ren_i  && is_ext_ram_i) ? 
                                ((hit_addr == cache_file[0][52:32]) ? 1'b1 :
                                 (hit_addr == cache_file[1][52:32]) ? 1'b1 :
                                 (hit_addr == cache_file[2][52:32]) ? 1'b1 :
                                 (hit_addr == cache_file[3][52:32]) ? 1'b1 : 1'b0 ) : 1'b0;
  
  assign hit_reg_addr = rst ? 2'd0 : 
                        (hit_ren_i  && is_ext_ram_i) ? 
                            ((hit_addr == cache_file[0][52:32]) ? 2'd0 :
                             (hit_addr == cache_file[1][52:32]) ? 2'd1 :
                             (hit_addr == cache_file[2][52:32]) ? 2'd2 :
                             (hit_addr == cache_file[3][52:32]) ? 2'd3 : 2'd0 ) : 2'd0;
  
  assign hit_cache_data_o = rst ? 32'h0 : 
                            (hit_ren_i  && is_ext_ram_i) ?  
                                ((hit_addr == cache_file[0][52:32]) ? cache_file_data_part[0] :
                                 (hit_addr == cache_file[1][52:32]) ? cache_file_data_part[1] :
                                 (hit_addr == cache_file[2][52:32]) ? cache_file_data_part[2] :
                                 (hit_addr == cache_file[3][52:32]) ? cache_file_data_part[3] : 32'h0 ) : 32'h0;

  
endmodule
