`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//-- FILE NAME	: baseram.v
//-- DESCRIPTION  : ��ģ��Ϊ BaseRAM�Ĵ���ģ��
//------------------------------------------------------------------------------
//-- Date         : 2023/6/10		  
//-- Coding_by	  : AXHU ������
//////////////////////////////////////////////////////////////////////////////////


module baseram(
    input   wire    [3:0]   base_ram_state,
    
    input   wire    [31:0]  rom_addr_i,
    output  reg     [31:0]  rom_data_o,
    
    input   wire    [31:0]  ram_addr_i,
    input   wire    [31:0]  ram_data_i,
    input   wire    [3:0]   ram_sel_i,   
    
    inout   wire    [31:0]  base_ram_data,          //BaseRAM���ݣ���8λ��CPLD���ڿ���������
    output  wire    [19:0]  base_ram_addr,          //BaseRAM��ַ
    output  wire    [3:0]   base_ram_be_n,          //BaseRAM �ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
    output  wire    base_ram_ce_n,                  //BaseRAM Ƭѡ������Ч
    output  wire    base_ram_oe_n,                  //BaseRAM ��ʹ�ܣ�����Ч
    output  wire    base_ram_we_n,                  //BaseRAM дʹ�ܣ�����Ч
    
    output  wire    [31:0]  base_ram_o
    
    );
  
  
   /// BaseRam ����ָ��������ݵĴ�ȡ   
    /// �ڷô�BaseRam�Ļ����ϣ�ִ�е���store ָ���²��ܸ� CPU��������ݣ�
    /// ��������£����� inout ˫��˿� ����̬�ţ��ڸ�����ֵ����£�ʵ�ʿ�ȡ �ⲿ�ļ���� ָ��
 assign base_ram_data = base_ram_state[3] ? ram_data_i : 32'hzzzzzzzz;
 assign base_ram_o = base_ram_data;      /// �ڶ�ȡģʽ�£���ȡ����BaseRam����
  
  
  
  /// ����BaseRam
 /// ����Ҫ��BaseRam�л�ȡ����д�����ݵ�ʱ��������ΪCPU����ͣ��ˮ�ߣ�1��ʱ�����ڣ�
 
 // base_ram_state
 // [0] : rst                   ��λ �� ������д״̬
 // [1] : rom_ce_i                      (ROM)��ָ��
 // [2] : is_base_ram && ram_we_n       (RAM)������ 
 // [3] : is_base_ram && !ram_we_n      (RAM)д���� 

 
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
     else if(base_ram_state[1]) /// ���漰��BaseRam��������ݲ������� IF�׶� ��Ҫ��BaseRam�� ����ȡָ��
       rom_data_o <= base_ram_o;
     else                      
       rom_data_o <= 32'h0000_0000;
   end


  
endmodule
