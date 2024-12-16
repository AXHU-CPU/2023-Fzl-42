`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//-- FILE NAME	: pc_reg.v
//-- DESCRIPTION  : ��ģ��Ϊ ָ��ĵ�ַ�Ĵ��� ģ��
//------------------------------------------------------------------------------
//-- Date         : 2023/6/5		  
//-- Coding_by	  : AXHU ������
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
    
    output  reg     [31:0]  pc,     // ָ���ַ
    output  reg     ce              // ȡֵ��־
    );
  
  wire [2:0] branch_base;
  assign branch_base[0] = (id_reg1_data_i == id_reg2_data_i);
  assign branch_base[1] = (id_reg1_data_i != id_reg2_data_i);
  assign branch_base[2] = (id_reg1_data_i[31] == 1'b0) ? ((id_reg1_data_i != 32'h0) ? 1'b1 : 1'b0) : 1'b0;
  
  always @ (posedge clk)
    begin
      if(!ce)                   // PCʹ�� ��Ч
        pc <= 32'h8000_0000;                //������ĿҪ�� ����λʱ����0x80000000��ַ
      /* PCʹ�� ��Ч����� */
      else if(!stall)           // ��ͣ��ˮ�� ��Ч�� CPU����ȡֵ ���
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
     /* �������PC���ֲ��� */
    end
  
  
  
  
  always @ (posedge clk)
    begin
      if(rst)
        ce <= 0;
      else
        ce <= 1;
    end
endmodule
