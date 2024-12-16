`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//-- FILE NAME	: stall_ctrl.v
//-- DESCRIPTION  : ��ģ��Ϊ ��ˮ����ͣģ�� 
//------------------------------------------------------------------------------
//-- Date         : 2023/6/5		  
//-- Coding_by	  : AXHU ������
//////////////////////////////////////////////////////////////////////////////////


module stall_ctrl(
    input   wire    rst,
    input   wire    stallreq_from_id,
    input   wire    stallreq_from_mem,
    output  wire    stall
    );
  
  assign stall = rst ? 1'b0 : 
                 stallreq_from_mem ? 1'b1 : 
                 stallreq_from_id;
                 
  // stallreq_from_id = 1 ʱ����Ҫ IF��pc_reg��ģ����ͣpc�仯��IF/IDģ����ͣȡֵ��ID/EXģ���Ч��λ
  // stallreq_from_mem = 1 ʱ������Ҫ IF��pc_reg��ģ����ͣpc�仯��IF/IDģ����ͣȡֵ��
endmodule
