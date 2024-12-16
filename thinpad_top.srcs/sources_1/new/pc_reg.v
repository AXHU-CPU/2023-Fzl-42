`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//-- FILE NAME	: pc_reg.v
//-- DESCRIPTION  : 本模块为 指令的地址寄存器 模块
//------------------------------------------------------------------------------
//-- Date         : 2023/6/5		  
//-- Coding_by	  : AXHU 范紫骝
//////////////////////////////////////////////////////////////////////////////////


module pc_reg(
    input   wire    clk,
    input   wire    rst,
    
    input   wire    stall,
    input   wire    [4:0]  j_inst_sign_i,
    input   wire    [31:0] branch_address_temp_i,
    input   wire    [31:0] j_address_temp_i,
    input   wire    [31:0] id_reg1_data_i,
    input   wire    [31:0] id_reg2_data_i,
    
    output  reg     [31:0]  pc,     // 指令地址
    output  reg     ce              // 取值标志
    );
  
  wire [2:0] branch_base;
  assign branch_base[0] = (id_reg1_data_i == id_reg2_data_i);
  assign branch_base[1] = (id_reg1_data_i != id_reg2_data_i);
  assign branch_base[2] = (id_reg1_data_i[31] == 1'b0) ? ((id_reg1_data_i != 32'h0) ? 1'b1 : 1'b0) : 1'b0;
  
  always @ (posedge clk)
    begin
      if(!ce)                   // PC使能 无效
        pc <= 32'h8000_0000;                //大赛题目要求 ，复位时返回0x80000000地址
      /* PC使能 有效情况下 */
      else if(!stall)           // 暂停流水线 无效， CPU正常取值 情况
        begin 
          if(j_inst_sign_i[0])                          // j, jal
            pc <= j_address_temp_i;
          else if(j_inst_sign_i[1])                     // jr, jalr
            pc <= id_reg1_data_i;            
          else if(j_inst_sign_i[2] && branch_base[0])   // beq
            pc <= branch_address_temp_i;
          else if(j_inst_sign_i[3] && branch_base[1])   // bne
            pc <= branch_address_temp_i;
          else if(j_inst_sign_i[4] && branch_base[2])   // bgtz
            pc <= branch_address_temp_i;
          else
            pc <= pc + 4;
        end
     /* 其余情况PC保持不变 */
    end
  
  
  
  
  always @ (posedge clk)
    begin
      if(rst)
        ce <= 0;
      else
        ce <= 1;
    end
endmodule
