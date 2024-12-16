`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//-- FILE NAME	: id.v
//-- DESCRIPTION  : ��ģ��Ϊ ����ģ��
//------------------------------------------------------------------------------
//-- Date         : 2023/6/5		  
//-- Coding_by	  : AXHU ������
//////////////////////////////////////////////////////////////////////////////////



module id(
    input   wire    [31:0]  pc_i,  
    output  wire    [31:0]  pc_o,     
    input   wire    [31:0]  inst_i,
    output  wire    [31:0]  inst_o,
        
    /* ִ�н׶�EXд�Ĵ�������Ϣ�� ���ڽ��������� */
    input   wire    ex_reg_wen_i,           // дʹ��
    input   wire    [4:0]   ex_waddr_i,     // д��ַ
    input   wire    [31:0]  ex_wdata_i,     // д����
    
    /* �͵�ִ�н׶�EX����Ϣ */
    output  reg     [2:0]   aluop_o,        // ����������ͣ�׼ȷ���ͣ�
    output  wire    [2:0]   alusel_o,       // ��������ͣ������߼�����������λ
    output  wire    [31:0]  reg1_data_o,    // Դ������1
    output  wire    [31:0]  reg2_data_o,    // Դ������2
    output  wire    reg_wen_o,              // дʹ�ܣ��ܷ�д��Ŀ�ļĴ���
    output  wire    [4:0]   waddr_o,        // д��ַ
    
    
    /* �ô�׶�MEMд�Ĵ�������Ϣ�� ���ڽ��������� */
    input   wire    mem_reg_wen_i,          // дʹ��
    input   wire    [4:0]   mem_waddr_i,    // д��ַ
    input   wire    [31:0]  mem_wdata_i,    // д����
    
    /* �Ĵ���regfile��������Ϣ�� ���ڽ��������� */
    input   wire    [31:0]  reg1_data_i,
    input   wire    [31:0]  reg2_data_i,
    
    /* α��cache��������Ϣ�� ���ڽ��������� */
    input   wire    hit_dcache_i,
    input   wire    [31:0]  hit_extram_data_i,
    
    input   wire    ex_inst_is_load_i,      //EX�׶� �Ƿ�ִ��loadָ��
    input   wire    [31:0]  ex_memory_Load_AND_Store_addr_i, 
    input   wire    [31:0]  mem_last_memorystore_addr_i,  
    input   wire    [31:0]  mem_last_memorystore_data_i,   
        
    
    /* �͵��Ĵ���regfile����Ϣ */
    output  wire    reg1_ren_o,             // ��ʹ��
    output  wire    reg2_ren_o,
    output  wire    [4:0]   reg1_addr_o,    // ����ַ
    output  wire    [4:0]   reg2_addr_o,
    
    /*�͵�ȡֵ�׶�IF����Ϣ*/
    output  wire    [4:0]   j_inst_sign_o,
    output  wire    [31:0]  j_address_temp_o,
    output  wire    [31:0]  branch_address_temp_o,
    
    output  reg     [31:0]  link_addr_o,        // �Ĵ� jal, jalr ָ��ר��д�Ĵ�����ֵ
    
    output  wire    stallreq_from_id         //IDģ�����load������أ���Ҫ������ˮ����ͣ�ź� 
    );
    
    
  /* ��ָ��inst���ֶν��зָ� */
  wire  [5:0]   op  = inst_i[31:26];
  wire  [4:0]   rs_code = inst_i[25:21];
  wire  [4:0]   rt_code = inst_i[20:16];
  wire  [4:0]   rd_code = inst_i[15:11];
  wire  [4:0]   shamt = inst_i[10:6];
  wire  [5:0]   func = inst_i[5:0];
  
  wire  [31:0]  pc_plus_4;      // ����j��jal��  beq��ben��bgtz ָ����ת��ַ��һ����
  wire  [31:0]  pc_plus_8;      // ��jal�� jalrд�Ĵ�����ֵ����ǰPC��
  assign pc_plus_4 = pc_i + 4;  
  assign pc_plus_8 = pc_i + 8;  
  
  
  assign branch_address_temp_o = {{14{inst_i[15]}}, inst_i[15:0], 2'b00} + pc_plus_4;   // ��ָ֧���(���������ת)ת�Ƶ�ַ
  assign j_address_temp_o = {pc_plus_4[31:28], inst_i[25:0], 2'b00};            // ��תָ���ת�Ƶ�ַ
  
  assign inst_o = inst_i;       // ���� EX�׶Σ�����load����ָ������ȡmemory���ݵĵ�ַ
  assign pc_o = pc_i;           // ������ID�׶�ʱ������ۿ���ʱָ���pc���裬������EX�׶�
  
  
  /*******************************  ָ�����ʶ��  ********************************/
  wire [31:0]  imm;    // ������
  wire imm_sign1;        // ������1��ȡ�������ı�־
  wire imm_sign2;        // ������2��ȡ�������ı�־
  wire op_is_zero;
  wire rs_is_zero;
  wire rt_is_zero;
  wire shamt_is_zero;
  assign op_is_zero = (op == 6'b000_000);
  assign rs_is_zero = (rs_code == 5'b00000);
  assign rt_is_zero = (rt_code == 5'b00000);
  assign shamt_is_zero = (shamt == 5'b00000);
  
  wire logic;      // �߼�ָ�� : and, andi, or, ori, lui, xor, xori
  wire shift;      // ��λָ�� : sll, srl, sra
  wire arithmetic; // ����ָ�� : addu, addiu, slt
  wire mul;        // �˷�ָ�� : mul
  wire jump;       // ת��ָ�� : j, jal, jr, jalr, beq, bne, bgtz
  wire load_and_store;//�ô�ָ�� : lb, lw, sb, sw
  wire inst_valid;                  //ָ���Ƿ���Ч
  
  assign logic = op_is_zero ? 
                            (shamt_is_zero ? 
                                            ((func == 6'b100_100) ? 1'b1 :                  // and
                                             (func == 6'b100_101) ? 1'b1 :                  // or
                                             (func == 6'b100_110) ? 1'b1 : 1'b0) : 1'b0) :  // xor
                (op == 6'b001_100) ? 1'b1 :         // andi
                (op == 6'b001_101) ? 1'b1 :         // ori
                (op == 6'b001_110) ? 1'b1 :         // xori
                (op == 6'b001_111) ? 1'b1 : 1'b0;   // lui
  
  assign shift = op_is_zero ? 
                            (rs_is_zero ? 
                                        ((func == 6'b000_000) ? 1'b1 :                          // sll 
                                         (func == 6'b000_010) ? 1'b1 :                          // srl
                                         (func == 6'b000_011) ? 1'b1 : 1'b0) : 1'b0) : 1'b0 ;   // sra
  
  assign arithmetic = op_is_zero ? 
                                (shamt_is_zero ? 
                                                ((func == 6'b100_001) ? 1'b1 :                  // addu
                                                 (func == 6'b101_010) ? 1'b1 : 1'b0) : 1'b0) :  // slt
                      (op == 6'b001_001) ? 1'b1 : 1'b0;         // addiu
  
  assign mul = (op == 6'b011_100) ? 
                                  (shamt_is_zero ? 
                                                 ((func == 6'b000_010) ? 1'b1 : 1'b0) : 1'b0) : 1'b0;   //mul
  
  assign jump = op_is_zero ? 
                           ((inst_i[20:0] == 21'b00000_00000_00000_001000) ? 1'b1 :                                              // jr
                            (rt_is_zero ?                                                                                       
                                        (shamt_is_zero ?                                                                        
                                                        ((func == 6'b001_001) ? 1'b1 : 1'b0) : 1'b0) :1'b0)) :    // jalr
                (op == 6'b000_010) ? 1'b1 :         // j
                (op == 6'b000_011) ? 1'b1 :         // jal
                (op == 6'b000_100) ? 1'b1 :         // beq
                (op == 6'b000_101) ? 1'b1 :         // bne
                (op == 6'b000_111) ? 
                                    (rt_is_zero ? 1'b1 : 1'b0) : 1'b0;   // bgtz
  
  assign load_and_store = (op == 6'b100_000) ? 1'b1 :           // lb
                          (op == 6'b100_011) ? 1'b1 :           // lw
                          (op == 6'b101_000) ? 1'b1 :           // sb
                          (op == 6'b101_011) ? 1'b1 : 1'b0;     // sw
  
  
  
  // NOP��ָ� alusel_o = 3'b000 
  assign alusel_o = logic ? 3'b001 : shift ? 3'b010 : arithmetic ? 3'b100 : 
                    mul ? 3'b101 : jump ? 3'b110 : load_and_store ? 3'b111 : 3'b000;
  
  assign inst_valid = (alusel_o != 3'b000);
  
  
  /************************* �������޸� *****************************/
  assign imm = logic ? 
                    ((op == 6'b001_111) ? {inst_i[15:0], 16'h0} :               // lui
                    (op_is_zero == 1'b0) ? {16'h0, inst_i[15:0]} : 32'h0) :     // andi, ori, xori
               shift ? {27'h0, shamt} :                                         // sll, srl, sra
               (op == 6'b001_001) ? {{16{inst_i[15]}}, inst_i[15:0]} : 32'h0;   // addiu
  
  assign imm_sign1 = shift ? 1'b1 : 1'b0;   //sll, srl, sra
  
  assign imm_sign2 = logic ? 
                            ((op_is_zero == 1'b0) ? 1'b1 : 1'b0) :      // andi, ori, xori
                    (op == 6'b001_001) ? 1'b1 : 1'b0;                   // addiu

  
 /********************  JAL��JALR��תָ��д�Ĵ�����ֵ�޸�  **********************/
  always @ (*)
    begin
      if( (op == 6'b000_011)                                                         // jal
        || (op_is_zero && rt_is_zero && shamt_is_zero && (func == 6'b001_001)) )    // jalr
        link_addr_o = pc_plus_8;   
      else
        link_addr_o = 32'h0000_0000;
    end
  
    /****************************** ��תָ���־ *****************************/
  
  assign j_inst_sign_o = jump ? 
                            ((op == 6'b000_010) ? 5'b00001 :            // j
                             (op == 6'b000_011) ? 5'b00001 :            // jal
                             op_is_zero ?  5'b00010 :                   // jr, jalr
                             (op == 6'b000_100) ? 5'b00100 :            // beq
                             (op == 6'b000_101) ? 5'b01000 :            // bne
                             (op == 6'b000_111) ? 5'b10000 : 5'b00000) : 5'b00000;  // bgtz      
  
  
  /*****************************************************************************/
  
  assign reg_wen_o = inst_valid ? 
                                (jump ? 
                                       ((op == 6'b000_011) ? 1'b1 :           // ת��ָ�� ��jal��jalrд�Ĵ���
                                        op_is_zero ? 
                                                    ((func == 6'b001_001) ? 1'b1 : 1'b0) : 1'b0) :  
                                (op == 6'b101_000) ? 1'b0 :                   // �ô�ָ�� ��sb��sw��д�Ĵ���
                                (op == 6'b101_011) ? 1'b0 : 1'b1) : 1'b0;       // ����ָ���д�Ĵ���
  
  assign waddr_o = (op == 6'b000_011) ? 5'd31 :     // д31�żĴ���: jal
                    op_is_zero ? rd_code : 
                        //дRd�żĴ���: and, or, xor // sll, srl, sra // addu, slt // jr(��д),jalr
                    mul ? rd_code : rt_code;        //дRd�żĴ���: mul
                        // �����дRt�żĴ���
  
  assign reg1_addr_o = inst_i[25:21];
  assign reg2_addr_o = inst_i[20:16];
  
  assign reg1_ren_o = shift ? 1'b0 :                        // sll, srl, sra
                      (op == 6'b000_010) ? 1'b0 :           // j
                      (op == 6'b000_011) ? 1'b0 :           // jal
                      (inst_valid == 1'b0) ? 1'b0 : 1'b1;
  
  assign reg2_ren_o = logic ?           
                            (op_is_zero ? 1'b1 : 1'b0) :    // and, or, xor
                      shift ? 1'b1:                         // sll, srl, sra
                      arithmetic ? 
                            (op_is_zero ? 1'b1 : 1'b0) :    // addu, slt
                      mul ? 1'b1 :                          // mul
                      (op == 6'b000_100) ? 1'b1 :           // beq
                      (op == 6'b000_101) ? 1'b1 :           // bne
                      (op == 6'b101_000) ? 1'b1 :           // sb
                      (op == 6'b101_011) ? 1'b1 : 1'b0;     // sw

  always @ (*)
    begin     
          aluop_o <= 3'b000;    //  ALU ÿ���������Ͷ�Ӧ�������ͣ� {alusel_o�� aluop_o}��ΪALU׼ȷ��������          
     
      if(op_is_zero && rs_is_zero)
        begin
          if(func == 6'b000_010)         // srl
              aluop_o <= 3'b001;
          else if(func == 6'b000_011)         // sra
              aluop_o <= 3'b010;
        end
        
      if((op == 6'b001_111) && rs_is_zero)  // lui     
          aluop_o <= 3'b001;     
           
      if((op == 6'b011_100) && shamt_is_zero && (func == 6'b000_010))   // mul
          aluop_o <= 3'b000;
          
          case(op)
            6'b000_000:
                begin
                  case(shamt)
                    5'b00000:
                            begin
                              case(func)
                                6'b100_101:     // or
                                      aluop_o <= 3'b001;
                                6'b100_110:     // xor
                                      aluop_o <= 3'b010;
                                6'b101_010:     // slt
                                      aluop_o <= 3'b001;
                              endcase
                            end
                  endcase
                end
            6'b001_101:     // ori
                  aluop_o <= 3'b001;
            6'b001_110:     // xori
                  aluop_o <= 3'b010;
            6'b100_011:     // lw
                  aluop_o <= 3'b001;
            6'b101_000:     // sb
                  aluop_o <= 3'b010;
            6'b101_011:     // sw
                  aluop_o <= 3'b011;
          endcase//endcase(op)
        end



assign reg1_data_o = reg1_ren_o ? 
                        ((ex_inst_is_load_i && (ex_waddr_i == reg1_addr_o)) ? 
                            ((ex_memory_Load_AND_Store_addr_i == mem_last_memorystore_addr_i) ? mem_last_memorystore_data_i :
                            //����һ��ָ���EX �׶�ִ�У�loadָ��  
                            //����һ��ָ�EX�׶�_loadд�Ĵ�����ַ = ������ִ��ָ�ID�׶�_��������ַ��������ȷ����ȡ��
                            // EX�׶�_load���洢����ַ = MEM�׶�_���һ��storeд�洢����ַ
                            // ��������С�Ż�
                            hit_dcache_i ? hit_extram_data_i : 32'h0000_0000) :
                         (ex_reg_wen_i && (ex_waddr_i == reg1_addr_o)) ? ex_wdata_i :
                            // ����һ��ָ��ͬдһ���Ĵ�����ַ
                         (mem_reg_wen_i && (mem_waddr_i == reg1_addr_o)) ? mem_wdata_i : reg1_data_i) :
                            // ������һ��ָ��ͬдһ���Ĵ�����ַ         //������ֵ����Ҫ��������1����ֵ�Ĵ����������1
                      imm_sign1 ? imm : 32'h0000_0000;
                      //������ֵ����Ҫ������������ֵ������չ������������������
                      
assign reg2_data_o = reg2_ren_o ? 
                        ((ex_inst_is_load_i && (ex_waddr_i == reg2_addr_o)) ? 
                            ((ex_memory_Load_AND_Store_addr_i == mem_last_memorystore_addr_i) ? mem_last_memorystore_data_i :
                            hit_dcache_i ? hit_extram_data_i : 32'h0000_0000) :
                         (ex_reg_wen_i && (ex_waddr_i == reg2_addr_o)) ? ex_wdata_i :
                         (mem_reg_wen_i && (mem_waddr_i == reg2_addr_o)) ? mem_wdata_i : reg2_data_i) :
                      imm_sign2 ? imm : 32'h0000_0000;                   
                         

 
  
// ID������� ���������� EX�׶�ִ�м���ָ�lw��lb��, EX�׶�д��ַ = ID�׶εĶ���������ַ�� ID�׶ζ���ַʹ����Ч
wire stallreq_for_reg1_loadrelate;
assign stallreq_for_reg1_loadrelate  = 
        (reg1_ren_o && ex_inst_is_load_i && (ex_waddr_i == reg1_addr_o)) ? 
        ((ex_memory_Load_AND_Store_addr_i == mem_last_memorystore_addr_i) ? 1'b0 : 
          hit_dcache_i ? 1'b0 : 1'b1) : 1'b0;  
        // ��EX�׶�_load���洢����ַ = MEM�׶�_���һ��storeд�洢����ַ�� �����д洢�����һ��storeд�洢��������
        // ��ʱ��ˮ����������

wire stallreq_for_reg2_loadrelate; 
assign stallreq_for_reg2_loadrelate  = 
        (reg2_ren_o && ex_inst_is_load_i && (ex_waddr_i == reg2_addr_o)) ? 
        ((ex_memory_Load_AND_Store_addr_i == mem_last_memorystore_addr_i) ? 1'b0 : 
         hit_dcache_i ? 1'b0 : 1'b1) : 1'b0;  

// ��IDģ��������أ���Ҫ��ͣ��ˮ��
assign stallreq_from_id = stallreq_for_reg1_loadrelate | stallreq_for_reg2_loadrelate;

  
endmodule
