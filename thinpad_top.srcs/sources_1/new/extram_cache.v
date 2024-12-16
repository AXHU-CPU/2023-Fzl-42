`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//-- FILE NAME	: extram_cache.v
//-- DESCRIPTION  : ��ģ��Ϊ α��Data cache����ʷ���ݼ�¼�ѣ�����¼ExtRAM��ʷ����
//------------------------------------------------------------------------------
//-- Date         : 2023/6/29		  
//-- Coding_by	  : AXHU ������
//////////////////////////////////////////////////////////////////////////////////


module extram_cache(
    input   wire    clk,
    input   wire    rst,
    
    input   wire    [2:0]   ext_ram_state,
    /*  д������  */
    input   wire    [31:0]  ram_addr_i,
    input   wire    [31:0]  ram_wdata_i,
    
    /*  ��ȡ����  */
    input   wire    is_ext_ram_i,
    input   wire    hit_ren_i,
    input   wire    [31:0]  hit_extram_addr, 
    output  wire    [31:0]  hit_extram_data,
    output  wire    hit_dcache
    );
  
  
  wire extram_we;               // ��α��cache��д��ʹ��
  wire [31:0] extram_waddr;     // ��α��cache��д���ַ
  wire [31:0] extram_wdata;     // ��α��cache��д������
  assign extram_we = ext_ram_state[0] ? 1'b0 : ext_ram_state[2] ? 1'b1 : 1'b0;
  assign extram_waddr = ext_ram_state[0] ? 32'h0 : ext_ram_state[2] ? ram_addr_i : 32'h0;
  assign extram_wdata = ext_ram_state[0] ? 32'h0 : ext_ram_state[2] ? ram_wdata_i : 32'h0;
  
  wire [31:0] hit_ram_addr;     // ���ҵ�ַ��cacheδʹ��ʱΪ0
  assign hit_ram_addr = hit_ren_i  ? hit_extram_addr : 32'h0;
  
  wire hit_cache;       // ���б�־������Ϊ1��û������Ϊ0
  wire [31:0] hit_data; // ��������
  cache    data_cache(
            .clk                (clk),
            .rst                (rst),
            
            .we                 (extram_we),
            .ram_waddr_i        (extram_waddr),
            .ram_wdata_i        (extram_wdata),
            
            .is_ext_ram_i       (is_ext_ram_i),
            //����is_ext_ram_i ����������ram��ַ[21:2]����cache�����ݣ����¶�Ӧ����������Ϊ0
            
            .hit_ren_i          (hit_ren_i),
            .memory_addr_i      (hit_ram_addr),
            .hit_cache_sign_o   (hit_cache),
            .hit_cache_data_o   (hit_data)
            );
  
  assign hit_extram_data = hit_cache ? hit_data : 32'h0;
  
  reg hit_en_n;                 // cache �ɶ�ȡʹ�ܣ��͵�ƽ��Ч���� ȷ����д���һ�����ݺ����ʹ�ö�ȡ���й���
  reg [31:0] last_ext_addr;     // ���ڱ�����һ��д��cache�ĵ�ַ
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
            hit_en_n <= 1'b0;               // ע������hit_en_n ��0��Ч�����������ã������Ҫ���޹�
        end
    end
    
  assign hit_dcache = (hit_en_n == 1'b0) ? hit_cache : 1'b0;
  
endmodule
