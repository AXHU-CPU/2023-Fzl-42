`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//-- FILE NAME	: ex.v
//-- DESCRIPTION  : ��ģ��Ϊ ִ��ģ��
//------------------------------------------------------------------------------
//-- Date         : 2023/6/5		  
//-- Coding_by	  : AXHU ������
//////////////////////////////////////////////////////////////////////////////////



module ex(
    input   wire    [31:0]  inst_i,     //���ڼ���loadָ���ַ
    input   wire    [31:0]  pc_i,
    output  wire    [31:0]  pc_o,
    
    
    input   wire    [2:0]   alusel_i, 
    input   wire    [2:0]   aluop_i,
    output  wire    [3:0]   Load_and_Store_op_o,  //����MEM�׶Σ���ʶ��Ϊ����ָ��ʹ洢ָ������� 
    output  wire    ex_inst_is_load_o,  //����IDģ�飬��load���ݳ�ͻ�ж�һ���֣�EX�׶��Ƿ�ִ��load��ָ��
    output  wire    [31:0]  ex_memory_Load_AND_Store_addr_o,
    output  wire    [31:0]  reg2_data_o,
    
    input   wire    reg_wen_i,
    output  wire    reg_wen_o,             
    input   wire    [4:0]   waddr_i,
    output  wire    [4:0]   waddr_o,
            
    input   wire    [31:0]  reg1_data_i,
    input   wire    [31:0]  reg2_data_i,
    
    input   wire    [31:0]  link_address_i,     // �Ĵ� jal, jalr ָ��ר��д�Ĵ�����ֵ
    output  reg     [31:0]  wdata_o,
    
    output  wire    ex_memory_wen_o,
    output  wire    ex_is_base_ram_o,
    output  wire    ex_is_ext_ram_o,
    output  wire    ex_is_SerialDate_o,
    output  wire    ex_is_SerialStat_o     
    );
    
  assign pc_o = pc_i;       // ������EX�׶�ʱ������ۿ���ʱָ���pc���裬������MEM�׶�
  
  
  wire [5:0] aluselop;
  assign aluselop = {alusel_i, aluop_i};        //ALU׼ȷ��������
  assign Load_and_Store_op_o = {(alusel_i==3'b111), aluop_i};   //����MEM�׶Σ���ʶ��Ϊ����ָ��ʹ洢ָ�������
  
  assign ex_inst_is_load_o = (aluselop == 6'b111_000) ? 1'b1 :
                             (aluselop == 6'b111_001) ? 1'b1 : 1'b0;  
            //����IDģ�飬�� EX�׶� �Ƿ�ִ��load��ָ���IDģ��load����ð�գ�������أ������ж�
  assign ex_memory_Load_AND_Store_addr_o = 
                (alusel_i==3'b111) ? reg1_data_i + {{16{inst_i[15]}}, inst_i[15:0]} : 32'h0;
            // ���� ����ָ��Ӵ洢���������ݵ�ַ ������ �洢ָ��д��洢���ĵ�ַ
  assign reg2_data_o = reg2_data_i;
            // ����MEM�׶Σ����洢ָ��д��洢������
  
  
  wire [31:0] reg1_lt_reg2;         // sltָ�� ���ݴ�С�ж�
  assign reg1_lt_reg2 = (($signed(reg1_data_i)) < ($signed(reg2_data_i))) ? 32'd1 : 32'd0;    //sltָ��
  
  wire [31:0] mulres = reg1_data_i * reg2_data_i;
  
  wire [31:0] wdata_temp;
  assign wdata_temp = (aluselop == 6'b001_000) ? reg1_data_i & reg2_data_i :   // and, andi
                   (aluselop == 6'b001_001) ? reg1_data_i | reg2_data_i :   // or,  ori, lui
                   (aluselop == 6'b001_010) ? reg1_data_i ^ reg2_data_i :   // xor, xori
                   (aluselop == 6'b010_000) ? reg2_data_i << reg1_data_i[4:0] :             // sll
                   (aluselop == 6'b010_001) ? reg2_data_i >> reg1_data_i[4:0] :             // srl
                   (aluselop == 6'b010_010) ? //($signed(reg2_data_i)) >>> reg1_data_i[4:0] : // sra
                        (({32{reg2_data_i[31]}} << (6'd32-{1'b0, reg1_data_i[4:0]})) | reg2_data_i >> reg1_data_i[4:0]) :
                   (aluselop == 6'b100_000) ? reg1_data_i + reg2_data_i :   // addu, addiu
                   (aluselop == 6'b100_001) ? reg1_lt_reg2 :                // slt
                   //(aluselop == 6'b101_000) ? reg1_data_i * reg2_data_i :   // mul
                   (aluselop == 6'b110_000) ? link_address_i :
                                               32'h0;
    always @ (*)
      begin
        if(alusel_i == 3'b101)
          wdata_o = mulres;
        else
          wdata_o = wdata_temp;
      end
    
    assign waddr_o = waddr_i;
    assign reg_wen_o = reg_wen_i;
  
  
  
  
  
  // EX�׶� ��ǰ �жϷô� д״̬��������MEM����ʱ�ӳٿ�ʼ�ô�ʱ��
            // ע�⣺���� ex_memory_wen_o �ǵ͵�ƽ��Ч
  assign ex_memory_wen_o = (aluselop == 6'b111_010) ? 1'b0 :
                           (aluselop == 6'b111_011) ? 1'b0 : 1'b1;
  
  /// EX�׶� ��ǰ �����ȡ����д������ݷ�Χ�����㴫�� MEM�׶� ʱ�� �ô�״̬�ı�
  assign ex_is_base_ram_o = 
        (ex_memory_Load_AND_Store_addr_o >= 32'h80000000) && (ex_memory_Load_AND_Store_addr_o < 32'h80400000);
        // load �� storeָ�� �ô� BaseRAM
  assign ex_is_ext_ram_o =  
        (ex_memory_Load_AND_Store_addr_o >= 32'h80400000) && (ex_memory_Load_AND_Store_addr_o < 32'h80800000);
        // load �� storeָ�� �ô� ExtRAM
  assign ex_is_SerialStat_o = (ex_memory_Load_AND_Store_addr_o == 32'hBFD003FC);     
  assign ex_is_SerialDate_o = (ex_memory_Load_AND_Store_addr_o == 32'hBFD003F8);

endmodule
