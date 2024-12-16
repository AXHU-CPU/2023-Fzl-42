`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//-- FILE NAME	: mem.v
//-- DESCRIPTION  : ��ģ��Ϊ �ô�ģ��
//------------------------------------------------------------------------------
//-- Date         : 2023/6/5		  
//-- Coding_by	  : AXHU ������
//////////////////////////////////////////////////////////////////////////////////


module mem(    
    input   wire    [31:0]  ram_data_i,
    
    input   wire    mem_reg_wen_i,
    input   wire    [4:0]   mem_waddr_i,
    input   wire    [31:0]  mem_wdata_i,
    
    input   wire    [3:0]   mem_Load_and_Store_op_i,  // ֻ��load���store��ָ�������ݴ���
    
    input   wire    [31:0]  memory_Load_AND_Store_addr_i,   // load��ָ����洢���ĵ�ַ �� store��ָ��д�洢���ĵ�ַ
    input   wire    [31:0]  reg2_data_i,            // store��ָ��д�洢�������ݣ����ݾ���ָ���һ������
    
    input   wire    [31:0]  pc_i,
    output  wire    [31:0]  pc_o,
    
    output  wire    mem_reg_wen_o,
    output  wire    [4:0]   mem_reg_waddr_o,
    output  reg     [31:0]  mem_reg_wdata_o,
    
    output  wire    [3:0]   mem_sel_o,      // ����д �洢�����ֽ�ѡȡ��  ע�⣺���Ҫ��͵�ƽ��Ч
    output  wire    [31:0]  memory_Load_AND_Store_addr_o,
    output  wire    [31:0]  mem_memory_wdata_o,
        
    output  wire    stallreq_from_mem,
    
    input   wire    rst,
    input   wire    rom_ce,
    input   wire    mem_memory_wen,     // ע�⣺����͵�ƽ��Ч
    input   wire    mem_is_base_ram_i,
    input   wire    mem_is_ext_ram_i,
    input   wire    mem_is_SerialDate_i,
    input   wire    mem_is_SerialStat_i,
    
    output  wire    [3:0]   base_ram_state,
    output  wire    [2:0]   ext_ram_state,
    output  wire    [3:0]   Serial_state
    );
  
  assign pc_o = pc_i;       // ������MEM�׶�ʱ������ۿ���ʱָ���pc���裬������WB�׶�
    
  // �����BaseRam�ṹð�գ�Ϊ1ȷ����ʱMEM�׶�ִ�е�ָ����Ҫ����BaseRAM�ṹ����ʱIFȡֵ�׶�ͬʱҲ��Ҫ����BaseRam��ȡֵ������
  // stallreq_from_memΪ1��
  //ͬʱ��Ҫ��ͣIF��pc_reg��ģ��PC�ı�ĺ�IF/IDģ��inst�ı䣨�˿�IF�׶�pc���ֲ��䣬instΪ0x00000000����
  //�Ա���BaseRam��ɽṹ��ͻ
  assign stallreq_from_mem =  mem_is_base_ram_i;


  assign mem_reg_wen_o = mem_reg_wen_i;
  assign mem_reg_waddr_o = mem_waddr_i;
  
  always @ (*)
    begin
      if(mem_Load_and_Store_op_i == 4'b1_000) // lb
        mem_reg_wdata_o <= ram_data_i;
      else if(mem_Load_and_Store_op_i == 4'b1_001) // lw
        mem_reg_wdata_o <= ram_data_i;
      else
        mem_reg_wdata_o <= mem_wdata_i;
    end
  
  
/***********************      �ô�RAM(��������)״̬     **************************/
  assign base_ram_state = rst ? 4'b0001 :
                          mem_is_base_ram_i ? (mem_memory_wen ? 4'b0100 : 4'b1000) : 
                          rom_ce ? 4'b0010 : 4'b0001; 
  // base_ram_state // [3]: (RAM)д���� ��[2]: (RAM)������ ��[1]: (ROM)��ָ�[0]: ��λ �� ������д״̬
  
  assign ext_ram_state = rst ? 3'b001 :
                         mem_is_ext_ram_i ? (mem_memory_wen ? 3'b010 : 3'b100) : 3'b001;
  // ext_ram_state // [2]: д���ݣ�[1]: �����ݣ�[0]: ��λ �� ������д״̬ 
  
  assign Serial_state = rst ? 4'b0001 :
                        mem_is_SerialDate_i ? (mem_memory_wen ? 4'b0010 : 4'b0100) :
                        mem_is_SerialStat_i ? 4'b1000 : 4'b0001;
  // Serial_state // [3]: (��ʾ��ʱ����״̬) ��[2]: д����(��������) ��[1]: ������(��������)��[0]: ��λ �� ������д״̬

/*************************    �ô洫��RAM������    ***************************/                             
  assign memory_Load_AND_Store_addr_o = mem_Load_and_Store_op_i[3] ? memory_Load_AND_Store_addr_i : 32'h0;
  
  assign mem_memory_wdata_o = (mem_Load_and_Store_op_i == 4'b1_010) ? {3'd4{reg2_data_i[7:0]}} :
                              (mem_Load_and_Store_op_i == 4'b1_011) ? reg2_data_i : 32'h0;
  
  assign mem_sel_o = (mem_Load_and_Store_op_i == 4'b1_000) ? 
                                                            ((memory_Load_AND_Store_addr_i[1:0] == 2'b00) ? 4'b1110 :
                                                             (memory_Load_AND_Store_addr_i[1:0] == 2'b01) ? 4'b1101 :
                                                             (memory_Load_AND_Store_addr_i[1:0] == 2'b10) ? 4'b1011 :
                                                             (memory_Load_AND_Store_addr_i[1:0] == 2'b11) ? 4'b0111 : 4'b1111) :
                     (mem_Load_and_Store_op_i == 4'b1_001) ? 4'b0000 :
                     (mem_Load_and_Store_op_i == 4'b1_010) ? 
                                                            ((memory_Load_AND_Store_addr_i[1:0] == 2'b00) ? 4'b1110 :
                                                             (memory_Load_AND_Store_addr_i[1:0] == 2'b01) ? 4'b1101 :
                                                             (memory_Load_AND_Store_addr_i[1:0] == 2'b10) ? 4'b1011 :
                                                             (memory_Load_AND_Store_addr_i[1:0] == 2'b11) ? 4'b0111 : 4'b1111) :
                     (mem_Load_and_Store_op_i == 4'b1_011) ? 4'b0000 : 4'b1111;
  

endmodule
