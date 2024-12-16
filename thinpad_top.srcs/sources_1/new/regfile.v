`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//-- FILE NAME	: regfile.v
//-- DESCRIPTION  : 本模块为 寄存器文件（wb写回模块）
//------------------------------------------------------------------------------
//-- Date         : 2023/6/5		  
//-- Coding_by	  : AXHU 范紫骝
//////////////////////////////////////////////////////////////////////////////////


module regfile(
    input   wire    clk,
    input   wire    rst,
    
    input   wire    we,
    input   wire    [4:0]   waddr,
    input   wire    [31:0]  wdata,
    
    input   wire    re1,
    input   wire    [4:0]   raddr1,
    output  wire    [31:0]  rdata1,
    
    input   wire    re2,
    input   wire    [4:0]   raddr2,
    output  wire    [31:0]  rdata2
    );
  
  reg [31:0] reg_file [0:31];
  
  integer i;
  always @ (posedge clk)
    begin
      if(rst)
        begin
          for(i=0; i<32; i=i+1)
            reg_file[i] <= 32'h0000_0000;
        end
      else
        begin
          if(we && (waddr != 5'h0))
            reg_file[waddr] <= wdata;
        end
    end
  
  assign rdata1 = rst ? 32'h0000_0000 : 
                  re1 ? 
                    ((we && (raddr1 == waddr)) ? wdata : reg_file[raddr1]) : 32'h0000_0000;
  
  assign rdata2 = rst ? 32'h0000_0000 : 
                  re2 ? 
                    ((we && (raddr2 == waddr)) ? wdata : reg_file[raddr2]) : 32'h0000_0000;
  
  
  
endmodule
